ScriptName WorkshopFramework:PersistenceManager Extends WorkshopFramework:Library:SlaveQuest
{
    One Manager to Persist them All
}
;;String Function __ScriptName() Global
;;    Return "AnnexTheCommonwealth:Quest:Persistence:Manager"
;;EndFunction
WorkshopFramework:PersistenceManager Function GetManager() Global
	Return ( Game.GetFormFromFile( 0x00006415, "WorkshopFramework.esm" ) As Quest ) As WorkshopFramework:PersistenceManager
EndFunction
String Function LogFile() Global
    Return "WSFW_PersistenceManager"
EndFunction








Import WorkshopFramework:Library:ObjectRefs
Import WorkshopFramework:Library:UtilityFunctions







;/
    ===========================================================
    
    Slave Quest event handlers
    
    MasterQuest will call these for us so we don't bog the system
    
    ===========================================================
/;


Function HandleQuestInit()
    Debug.OpenUserLog( LogFile() )
    Debug.TraceUser( LogFile(), Self + " :: HandleQuestInit()" )
    Parent.HandleQuestInit()
    __CommonInit()
EndFunction


Function HandleGameLoaded()
    Debug.OpenUserLog( LogFile() )
    Debug.TraceUser( LogFile(), Self + " :: HandleGameLoaded()" )
    Parent.HandleGameLoaded()
    __CommonInit()
EndFunction


Function __CommonInit()
    
    ;; Register for WorkshopParent events
    RegisterForCustomEvent( kQUST_WorkshopParent, "WorkshopObjectBuilt" )
    RegisterForCustomEvent( kQUST_WorkshopParent, "WorkshopObjectMoved" )
    RegisterForCustomEvent( kQUST_WorkshopParent, "WorkshopObjectDestroyed" )
    RegisterForCustomEvent( kQUST_WorkshopParent, "WorkshopActorAssignedToBed" )
    RegisterForCustomEvent( kQUST_WorkshopParent, "WorkshopActorAssignedToWork" )
    RegisterForCustomEvent( kQUST_WorkshopParent, "WorkshopActorUnassigned" )
    
    kQUST_ThreadManager.RegisterForCallbackThreads( Self )
    
    ;; Reset the FormLists and caches on load, mods should wait until the 
    kFLST_PersistReference_ActorValues.Revert()
    kFLST_PersistReference_BaseObjects.Revert()
    kFLST_PersistReference_Keywords.Revert()
    __kPersistReference_ActorValues = None
    __kPersistReference_BaseObjects = None
    
    ;; Register for events with all the Workshops
    WorkshopScript[] lkWorkshops = kQUST_WorkshopParent.Workshops
    Int liIndex = lkWorkshops.Length
    While( liIndex > 0 )
        liIndex -= 1
        
        WorkshopScript lkWorkshop = lkWorkshops[ liIndex ]
        If( lkWorkshop != None )
            
            __RegisterForWorkshopEvents( lkWorkshop )
            
        EndIf
        
    EndWhile
    
    ;; Start the cycle of cleaning deleted Objects from the Manager
    __ScheduleCleanDeadPersistentObjects()
    
EndFunction


Function __RegisterForWorkshopEvents( WorkshopScript akWorkshop )
    
    RegisterForRemoteEvent( akWorkshop, "OnWorkshopObjectPlaced" )
    RegisterForRemoteEvent( akWorkshop, "OnWorkshopObjectMoved" )
    RegisterForRemoteEvent( akWorkshop, "OnWorkshopObjectDestroyed" )
    
    __SchedulePersistentScanOnApproach( akWorkshop, abScanIfCloseEnough = False )
    
EndFunction








;/
    ===========================================================
    
    Magic numbers r teh devil!
    
    ===========================================================
/;


Int                     Property    SCHEDULE_SCHEDULED = 1                          AutoReadOnly Hidden
Int                     Property    SCHEDULE_NO_WORK = 2                            AutoReadOnly Hidden
Int                     Property    SCHEDULE_TOO_BUSY = 0                           AutoReadOnly Hidden
Int                     Property    SCHEDULE_GENERAL_ERROR = -1                     AutoReadOnly Hidden
Int                     Property    SCHEDULE_QUEUE_ERROR = -2                       AutoReadOnly Hidden








;/
    ===========================================================
    
    Editor set properties
    
    ===========================================================
/;


Group Controllers
    
    WorkshopParentScript \
                        Property    kQUST_WorkshopParent                            Auto Const Mandatory
    { The core Workshop Parent }
    
    WorkshopFramework:MainThreadManager \
                        Property    kQUST_ThreadManager                             Auto Const Mandatory
    { The WSFW Thread Manager }
    
    ActorValue          Property    kAVIF_WorkshopBusy                              Auto Const Mandatory
    { The WSFW "Workshop Busy" AV }
    
EndGroup


Group PersistenceAlias
    
    RefCollectionAlias  Property    kAlias_PersistentObjects                        Auto Const Mandatory
    { This holds and forces all the objects to persist }
    
EndGroup


Group ActiveScanning
    

    LocationAlias       Property    kAlias_Workshop                                 Auto Const Mandatory
    { Workshop Location that just got scanned }
    
    Message             Property    kMESG_PersistenceStart                          Auto Const Mandatory
    { The persistence scanning start message }
    
    Message             Property    kMESG_PersistenceComplete                       Auto Const Mandatory
    { The persistence scanning complete message }
    
    Message             Property    kMESG_CleaningStart                             Auto Const Mandatory
    { The dead object removal start message }
    
    Message             Property    kMESG_CleaningComplete                          Auto Const Mandatory
    { The dead object removal complete message }
    
    GlobalVariable      Property    kGLOB_ShowPersistenceMessages                   Auto Const Mandatory
    { Global controlling whether to show persistence messages }
    
EndGroup

Bool Function ShowPersistenceMessages()
    Return ( kGLOB_ShowPersistenceMessages.GetValueInt() != 0 )
EndFunction


Keyword                 Property    kKYWD_WorkshopItemKeyword                       Auto Const Mandatory
{ Vanilla Keyword linking all objects to the Workshop }


Group PersistenceFiltering
    
    FormList            Property    kFLST_PersistReference_ActorValues              Auto Const Mandatory
    { If an ObjectReference has any of these AVIFs, it must be persisted }
    
    FormList            Property    kFLST_PersistReference_BaseObjects              Auto Const Mandatory
    { If an ObjectReference is any one of these BaseObjects, it must be persisted }
    
    FormList            Property    kFLST_PersistReference_Keywords                 Auto Const Mandatory
    { If an ObjectReference has any of these KYWDs, it must be persisted }
    
EndGroup


Group PersistenceQueuing
    
    RefCollectionAlias[] Property   kAlias_PersistenceQueues                        Auto Const Mandatory
    { These are REFRs waiting for persistence checking, they are temporarily persisted in this Alias until they can be fully checked.
Two collections are used as a type of double-buffering.  People familiar with graphics rendering will understand this system. }
    
EndGroup








;/
    ===========================================================
    
    Cache FormLists -> Arrays
    
    ===========================================================
/;


ActorValue[]                        __kPersistReference_ActorValues = None


ActorValue[] Function Get_PersistReference_ActorValues()
    If( __kPersistReference_ActorValues == None )
        __kPersistReference_ActorValues = FormListToArray( kFLST_PersistReference_ActorValues ) As ActorValue[]
    EndIf
    Return __kPersistReference_ActorValues
EndFunction


Function Add_PersistReference_ActorValue( ActorValue akAVIF )
    kFLST_PersistReference_ActorValues.AddForm( akAVIF )
    __kPersistReference_ActorValues = None
EndFunction








Form[]                              __kPersistReference_BaseObjects = None


Form[] Function Get_PersistReference_BaseObjects()
    If( __kPersistReference_BaseObjects == None )
        __kPersistReference_BaseObjects = FormListToArray( kFLST_PersistReference_BaseObjects )
    EndIf
    Return __kPersistReference_BaseObjects
EndFunction


Function Add_PersistReference_BaseObject( Form akForm )
    kFLST_PersistReference_BaseObjects.AddForm( akForm )
    __kPersistReference_BaseObjects = None
EndFunction








Function Add_PersistReference_Keyword( Keyword akKYWD )
    kFLST_PersistReference_Keywords.AddForm( akKYWD )
EndFunction








;/
    ===========================================================
    
    Manager Events
    
    ===========================================================
/;


Event OnTimerGameTime( Int aiTimerID )
    Debug.TraceUser( LogFile(), Self + " :: OnTimerGameTime() :: Top" )
    
    If    ( aiTimerID == iFiberID_PersistenceScanQueue )
        
        Int liScheduling = __ScanPersistenceQueue()
        
        If( liScheduling != SCHEDULE_SCHEDULED )
            
            ;; Wasn't scheduled for some reason, try again
            __ScheduleQueuedPersistenceScanning()
            
        EndIf
        
        
    ElseIf( aiTimerID == iFiberID_CleanDeadPersistentObjects )
        
        Int liScheduling = CleanDeadPersistentObjects()
        
        If( liScheduling == SCHEDULE_TOO_BUSY )
            
            ;; Couldn't do it now, reschedule for 1 hour
            __ScheduleCleanDeadPersistentObjects( 1.0 )
            
        ElseIf( liScheduling != SCHEDULE_SCHEDULED )
            
            ;; Wasn't scheduled for some other reason, reschedule for it's normal interval
            __ScheduleCleanDeadPersistentObjects()
            
        EndIf
        
    EndIf
    
    Debug.TraceUser( LogFile(), Self + " :: OnTimerGameTime() :: Bottom" )
EndEvent




Event OnDistanceLessThan( ObjectReference akObj1, ObjectReference akObj2, float afDistance )
    WorkshopScript lkWorkshop = WorkshopFromReferences( akObj1, akObj2 )
    If( lkWorkshop == None )
        Return
    EndIf
    
    ;;Debug.TraceUser( LogFile(), Self + " :: OnDistanceLessThan()" \
    ;;+ "\n\tlkWorkshop = " + lkWorkshop )
    
    ;; Register for leaving the area to trigger registering for returning
    RegisterForDistanceGreaterThanEvent( PlayerRef, lkWorkshop, __fDist_ScanOnApproach_Outside )
    
    ;; Try to scan for persistence
    __TryScanPersistence( lkWorkshop )
    
EndEvent




Event OnDistanceGreaterThan( ObjectReference akObj1, ObjectReference akObj2, float afDistance )
    
    WorkshopScript lkWorkshop = WorkshopFromReferences( akObj1, akObj2 )
    If( lkWorkshop == None )
        Return
    EndIf
    
    ;;Debug.TraceUser( LogFile(), Self + " :: OnDistanceGreaterThan()" \
    ;;+ "\n\tlkWorkshop = " + lkWorkshop )
    
    ;; Register for entering the area to trigger a full scan
    RegisterForDistanceLessThanEvent( PlayerRef, lkWorkshop, __fDist_ScanOnApproach_Inside )
    
EndEvent




Event WorkshopFramework:Library:ObjectRefs:FiberController.OnFiberComplete( WorkshopFramework:Library:ObjectRefs:FiberController akSender, Var[] akArgs )
    
    String  lsCustomCallbackID  = akArgs[ 0 ] As String
    Int     liCallbackID        = akArgs[ 1 ] As Int
    Bool    lbResult            = akArgs[ 2 ] As Bool
    Int     liChanged           = akArgs[ 3 ] As Int
    Int     liTotal             = akArgs[ 4 ] As Int
    
    Int     liUserParams        = WorkshopFramework:Library:ObjectRefs:FiberController.GetUserParams( akArgs )
    
    WorkshopScript lkWorkshop   = None
    If( liUserParams > -1 )
        lkWorkshop              = akArgs[ liUserParams + 0 ] As WorkshopScript
    EndIf
    
    Message lkMessage = None
    Bool lbRequiresWorkshop = False
    
    If( lkWorkshop != None )
        ;; Release the Workshop block
        __SetWorkshopBusy( lkWorkshop, False )
    EndIf
    
    If      ( liCallbackID == iFiberID_PersistenceScanObjects )
        ;; Message to display
        lkMessage = kMESG_PersistenceComplete
        lbRequiresWorkshop = True
        
    ElseIf  ( liCallbackID == iFiberID_PersistenceScanQueue )
        ;; Message to display
        lkMessage = kMESG_PersistenceComplete
        lbRequiresWorkshop = True
        
        ;; Scan complete, clear the scan buffer
        Int liScanBuffer = ( __iQueueBufferActive + 1 ) % 2
        RefCollectionAlias lkScanBuffer = kAlias_PersistenceQueues[ liScanBuffer ]
        lkScanBuffer.RemoveAll()
        
        ;; Let the cycle continue
        __bQueueScanActived = False
        
    ElseIf  ( liCallbackID == iFiberID_CleanDeadPersistentObjects )
        ;; Message to display
        lkMessage = kMESG_CleaningComplete
        lbRequiresWorkshop = False
        
        ;; Schedule a new scan
        __ScheduleCleanDeadPersistentObjects()
        
    EndIf
    
    ;; Inform the player?
    If  ( lkMessage != None )\
    &&  ( ShowPersistenceMessages() )\
    &&( ( ! lbRequiresWorkshop )\
    ||  ( lkWorkshop != None ) )
        
        If( lbRequiresWorkshop )
            kAlias_Workshop.ForceLocationTo( lkWorkshop.myLocation )
        EndIf
        lkMessage.Show( liTotal, liChanged )
        
    EndIf
    
    Debug.TraceUser( LogFile(), Self + " :: WorkshopFramework:Library:ObjectRefs:FiberController.OnFiberComplete()" \
        + "\n\tlsCustomCallbackID = '" + lsCustomCallbackID + "'" \
        + "\n\tliCallbackID       = 0x" + IntToHex( liCallbackID, 8 ) \
        + "\n\tlbResult           = " + lbResult \
        + "\n\tliChanged          = " + liChanged \
        + "\n\tliTotal            = " + liTotal \
        + "\n\tlkWorkshop         = " + lkWorkshop \
        + "\n\tlkMessage          = " + lkMessage \
        + "\n\tTotal Persisted Objects = " + kAlias_PersistentObjects.GetCount() )
    
EndEvent








;/
    ===========================================================
    
    Workshop busy?
    
    Don't want to overload the VM, heavy hitters should respect
    the "WorkshopBusy" AV.  It's not strictly required, we're
    just trying to play nice here and not bog the players game
    down with script lag.
    
    ===========================================================
/;


Function __SetWorkshopBusy( WorkshopScript akWorkshop, Bool abBusy )
    ;;Debug.TraceUser( LogFile(), Self + " :: __SetWorkshopBusy()" \
    ;;+ "\n\takWorkshop = " + akWorkshop \
    ;;+ "\n\tabBusy     = " + abBusy )
	Float lfValue = 0.0
	If( abBusy )
		lfValue = 1.0
	EndIf
	akWorkshop.SetValue( kAVIF_WorkshopBusy, lfValue )
EndFunction

Bool Function __GetWorkshopBusy( WorkshopScript akWorkshop )
	Return ( akWorkshop.GetBaseValue( kAVIF_WorkshopBusy ) As Int ) != 0
EndFunction


Bool Function __WaitForAndSetWorkshopBusy( WorkshopScript akWorkshop, Int aiWaitCount )
    ;;Debug.TraceUser( LogFile(), Self + " :: __WaitForAndSetWorkshopBusy() :: Start" \
    ;;+ "\n\takWorkshop = " + akWorkshop )
    
    ;; Wait for...
    Int liCount = 0
    While( __GetWorkshopBusy( akWorkshop ) )&&( liCount < aiWaitCount )
        Utility.WaitMenuMode( Utility.RandomFloat( 0.125, 0.875 ) )
        liCount += 1
    EndWhile
    
    If( __GetWorkshopBusy( akWorkshop ) )
        Debug.TraceUser( LogFile(), Self + " :: __WaitForAndSetWorkshopBusy() :: Too Busy" \
        + "\n\takWorkshop = " + akWorkshop )
        Return False
    EndIf
    
    ;; ...And Set
    __SetWorkshopBusy( akWorkshop, True )
    
    ;;Debug.TraceUser( LogFile(), Self + " :: __WaitForAndSetWorkshopBusy() :: Set Busy" \
    ;;+ "\n\takWorkshop = " + akWorkshop )
    Return True
EndFunction








;/
    ===========================================================
    
    Dead Object Cleaning
    
    ===========================================================
/;


Int                     Property    iFiberID_CleanDeadPersistentObjects = 0x200     AutoReadOnly
Float                               __fTimerHours_CleanDeadObjects = 24.0           Const ;; Once every day




Function __ScheduleCleanDeadPersistentObjects( Float afDelayHours = -1.0 )
    ;;Debug.TraceUser( LogFile(), Self + " :: __ScheduleCleanDeadPersistentObjects()" )
    If( afDelayHours <= 0.0 )
        afDelayHours =  __fTimerHours_CleanDeadObjects
    EndIf
    StartTimerGameTime( afDelayHours, iFiberID_CleanDeadPersistentObjects )
EndFunction




Int Function CleanDeadPersistentObjects()
    Debug.TraceUser( LogFile(), Self + " :: CleanDeadPersistentObjects()" )
    
    Int liObjects = kAlias_PersistentObjects.GetCount()
    If( liObjects == 0 )
        ;;Debug.TraceUser( LogFile(), Self + " :: CleanDeadPersistentObjects() :: No Work" )
        Return SCHEDULE_NO_WORK
    EndIf
    
    
    FiberController lkController = \
        WorkshopFramework:ObjectRefs:Fiber_PersistenceRemoveDeletedObjects.CreateFiberController( \
            True )
    
    If( lkController == None )
        ;; CreateFiberController will write exceptions to the log
        ;;Debug.TraceUser( LogFile(), Self + " :: CleanDeadPersistentObjects() :: Cannot create FiberController" )
        Return SCHEDULE_GENERAL_ERROR
    EndIf
    
    
    If( !lkController.QueueFibers( abSync = False ) )
        Debug.TraceUser( LogFile(), Self + " :: CleanDeadPersistentObjects() :: Could not queue Fibers" )
        lkController.Delete()
        Return SCHEDULE_QUEUE_ERROR
    EndIf
    
    
    ;; Inform the player?
    If( ShowPersistenceMessages() )
        kMESG_CleaningStart.Show()
    EndIf
    
    
    ;;Debug.TraceUser( LogFile(), Self + " :: CleanDeadPersistentObjects() :: Scheduled" )
    Return SCHEDULE_SCHEDULED
EndFunction








;/
    ===========================================================
    
    Object Persistence Management
    
    ===========================================================
/;


Int                     Property    iFiberID_PersistenceScanObjects = 0x100         AutoReadOnly
Int                     Property    iFiberID_PersistenceScanQueue   = 0x101         AutoReadOnly

Float                               __fDist_ScanOnApproach_Inside = 4096.0          Const
Float                               __fDist_ScanOnApproach_Outside = 8192.0         Const

Int                                 __iQueueBufferActive = 0
Float                               __fTimerHours_ScanQueue = 1.0                   Const ;; Trigger in one game hour



;; Scan an array of objects and persist the ones that need it
Int Function PersistObjectArray(  \
    WorkshopScript      akWorkshop, \
    ObjectReference[]   akObjects, \
    Bool                abSync = False, \
    Bool                abRegisterManagerCallback = False \
    )
    
    Debug.TraceUser( LogFile(), Self + " :: PersistObjectArray()" \
    + "\n\takWorkshop = " + akWorkshop \
    + "\n\takObjects  = " + akObjects.Length \
    + "\n\tabSync     = " + abSync \
    + "\n\tabRegisterManagerCallback = " + abRegisterManagerCallback )
    
    Int liObjects = akObjects.Length
    If( liObjects == 0 )
        Return SCHEDULE_NO_WORK
    EndIf
    
    
    FiberController lkController = \
        WorkshopFramework:ObjectRefs:Fiber_PersistenceUpdateObjects.CreateFiberController( \
            akWorkshop, \
            akObjects, \
            abRegisterManagerCallback )
    
    If( lkController == None )
        ;; CreateFiberController will write exceptions to the log
        ;;Debug.TraceUser( LogFile(), Self + " :: PersistObjectArray() :: Could not create FiberController" )
        Return SCHEDULE_GENERAL_ERROR
    EndIf
    
    
    If( !lkController.QueueFibers( abSync = False ) )
        Debug.TraceUser( LogFile(), Self + " :: PersistObjectArray() :: Could not queue Fibers" )
        lkController.Delete()
        Return SCHEDULE_QUEUE_ERROR
    EndIf
    
    
    ;; Inform the player?
    If( akWorkshop != None )\
    &&( ShowPersistenceMessages() )
        kAlias_Workshop.ForceLocationTo( akWorkshop.myLocation )
        kMESG_PersistenceStart.Show()
    EndIf
    
    
    ;;Debug.TraceUser( LogFile(), Self + " :: PersistObjectArray() :: Scheduled" )
    Return SCHEDULE_SCHEDULED
EndFunction




;; Queue a single object to be scanned on the next cycle
Int Function QueueObjectPersistence( ObjectReference akObject )
    Debug.TraceUser( LogFile(), Self + " :: QueueObjectPersistence() :: akObject = " + akObject )
    
    If( akObject == None )
        ;;Debug.TraceUser( LogFile(), Self + " :: QueueObjectPersistence() :: No Work" )
        Return SCHEDULE_NO_WORK
    EndIf
    
    ;; Block the queues from swapping while we add to it
    Int liCounter = 0
    While( __bQueueBlock )&&( liCounter < 100 )
        Utility.WaitMenuMode( Utility.RandomFloat( 0.125, 0.875 ) ) ;; 1/8 - 7/8s delay to try and even out the calls
        liCounter += 1
    EndWhile
    If( __bQueueBlock )
        ;;Debug.TraceUser( LogFile(), Self + " :: QueueObjectPersistence() :: Too Busy" )
        Return SCHEDULE_TOO_BUSY
    EndIf
    __bQueueBlock = True
    
    
    ;; Add it to the active queue
    kAlias_PersistenceQueues[ __iQueueBufferActive ].AddRef( akObject )
    
    
    ;; Start the timer for the queue scan
    If( !__bQueueScanActived )
        __ScheduleQueuedPersistenceScanning()
    EndIf
    
    
    __bQueueBlock = False
    ;;Debug.TraceUser( LogFile(), Self + " :: QueueObjectPersistence() :: Scheduled" )
    Return SCHEDULE_SCHEDULED
EndFunction




Int Function __TryScanPersistence( WorkshopScript akWorkshop )
    ;; Try and wait for the local workshop change to finish
    If( !__WaitForAndSetWorkshopBusy( akWorkshop, 100 ) )
        ;; Nope, it's really, REALLY busy - just skip it for now
        ;;Debug.TraceUser( LogFile(), Self + " :: __TryScanPersistence() :: Too busy" )
        Return SCHEDULE_TOO_BUSY
    EndIf
    
    Debug.TraceUser( LogFile(), Self + " :: __TryScanPersistence()" )
    
    Int liResult = PersistObjectArray( \
        akWorkshop, \
        akWorkshop.GetLinkedRefChildren( kKYWD_WorkshopItemKeyword ), \
        abRegisterManagerCallback = True )
    If( liResult != SCHEDULE_SCHEDULED )
        akWorkshop.SetBusy( False )
        ;;Debug.TraceUser( LogFile(), Self + " :: __TryScanPersistence() :: ...and fail" )
    EndIf
    
    ;;Debug.TraceUser( LogFile(), Self + " :: __TryScanPersistence() :: ...Scheduled" )
    Return liResult
EndFunction




Function __SchedulePersistentScanOnApproach( WorkshopScript akWorkshop, Bool abScanIfCloseEnough = True )
    ;;Debug.TraceUser( LogFile(), Self + " :: __SchedulePersistentScanOnApproach()" )
    If( akWorkshop == None )
        Return
    EndIf
    
    Actor lkPlayer = PlayerRef
    
    If( lkPlayer.GetDistance( akWorkshop ) <= __fDist_ScanOnApproach_Inside )
        
        Bool liScheduling = SCHEDULE_SCHEDULED
        If( abScanIfCloseEnough )
            
            ;; Closer than trigger distance, try scan now
            liScheduling = __TryScanPersistence( akWorkshop ) 
            
        EndIf
        
        If( liScheduling != SCHEDULE_SCHEDULED )
            ;; Set the leave trigger
            RegisterForDistanceGreaterThanEvent( lkPlayer, akWorkshop, __fDist_ScanOnApproach_Outside )
            
        EndIf
        
        Return
    EndIf
    
    ;; Set the distance event trigger
    RegisterForDistanceLessThanEvent( lkPlayer, akWorkshop, __fDist_ScanOnApproach_Inside )
    
EndFunction





Function __ScheduleQueuedPersistenceScanning()
    ;;Debug.TraceUser( LogFile(), Self + " :: __ScheduleQueuedPersistenceScanning()" )
    StartTimerGameTime( __fTimerHours_ScanQueue, iFiberID_PersistenceScanQueue )
EndFunction




Bool                                __bQueueBlock = False
Bool                                __bQueueScanActived = False
Int Function __ScanPersistenceQueue()
    ;;Debug.TraceUser( LogFile(), Self + " :: __ScanPersistenceQueue()" )
    
    While( __bQueueBlock )
        Utility.WaitMenuMode( Utility.RandomFloat( 0.125, 0.875 ) ) ;; 1/8 - 7/8s delay to try and even out the calls
    EndWhile
    __bQueueBlock = True
    
    
    ;; Scan buffer is active buffer
    Int liScanBuffer = __iQueueBufferActive
    RefCollectionAlias lkScanBuffer = kAlias_PersistenceQueues[ liScanBuffer ]
    Int liBufferedCount = lkScanBuffer.GetCount()
    If( liBufferedCount == 0 )
        ;; Nothing to do
        ;;Debug.TraceUser( LogFile(), Self + " :: __ScanPersistenceQueue() :: No Work" )
        __bQueueScanActived = False
        __bQueueBlock = False
        Return SCHEDULE_NO_WORK
    EndIf
    
    Int liNewActiveBuffer = ( __iQueueBufferActive + 1 ) % 2
    
    Debug.TraceUser( LogFile(), Self + " :: __ScanPersistenceQueue()" \
        + "\n\tliScanBuffer = " + liScanBuffer \
        + "\n\tlkScanBuffer = " + lkScanBuffer \
        + "\n\tliBufferedCount = " + liBufferedCount \
        + "\n\tliNewActiveBuffer = " + liNewActiveBuffer \
        + "\n\tlkNewActiveBuffer = " + kAlias_PersistenceQueues[ liNewActiveBuffer ] )


    FiberController lkController = \
        WorkshopFramework:ObjectRefs:Fiber_PersistenceUpdateQueue.CreateFiberController( \
            None, \
            lkScanBuffer, \
            True )
    
    If( lkController == None )
        ;; CreateFiberController will write exceptions to the log
        __bQueueScanActived = False
        __bQueueBlock = False
        ;;Debug.TraceUser( LogFile(), Self + " :: __ScanPersistenceQueue() :: Unable to create FiberController" )
        Return SCHEDULE_GENERAL_ERROR
    EndIf
    
    
    If( !lkController.QueueFibers( abSync = False ) )
        Debug.TraceUser( LogFile(), Self + " :: __ScanPersistenceQueue() :: Could not queue Fibers" )
        lkController.Delete()
        __bQueueScanActived = False
        __bQueueBlock = False
        Return SCHEDULE_QUEUE_ERROR
    EndIf
    
    
    ;; Cycle the active buffer
    __iQueueBufferActive = liNewActiveBuffer
    
    __bQueueBlock = False
    ;;Debug.TraceUser( LogFile(), Self + " :: __ScanPersistenceQueue() :: Scheduled" )
    Return SCHEDULE_SCHEDULED
EndFunction







;/
    ===========================================================
    
    Object Placement Events
    
    ===========================================================
/;


Event ObjectReference.OnWorkshopObjectPlaced( ObjectReference akSender, ObjectReference akReference )
    ;;Debug.TraceUser( LogFile(), Self + " :: ObjectReference.OnWorkshopObjectPlaced()" )
    If( akReference != None )
        QueueObjectPersistence( akReference )
    EndIf
EndEvent


Event ObjectReference.OnWorkshopObjectMoved( ObjectReference akSender, ObjectReference akReference )
    ;;Debug.TraceUser( LogFile(), Self + " :: ObjectReference.OnWorkshopObjectMoved()" )
    If( akReference != None )
        QueueObjectPersistence( akReference )
    EndIf
EndEvent


Event ObjectReference.OnWorkshopObjectDestroyed( ObjectReference akSender, ObjectReference akReference )
    ;;Debug.TraceUser( LogFile(), Self + " :: ObjectReference.OnWorkshopObjectDestroyed()" )
    If( akReference != None )
        QueueObjectPersistence( akReference )
    EndIf
EndEvent


Event WorkshopParentScript.WorkshopObjectBuilt( WorkshopParentScript akSender, Var[] akArgs )
    ;;Debug.TraceUser( LogFile(), Self + " :: WorkshopParentScript.WorkshopObjectBuilt()" )
    ObjectReference lkREFR = akArgs[ 0 ] As ObjectReference
    If( lkREFR != None )
        QueueObjectPersistence( lkREFR )
    EndIf
EndEvent


Event WorkshopParentScript.WorkshopObjectMoved( WorkshopParentScript akSender, Var[] akArgs )
    ;;Debug.TraceUser( LogFile(), Self + " :: WorkshopParentScript.WorkshopObjectMoved()" )
    ObjectReference lkREFR = akArgs[ 0 ] As ObjectReference
    If( lkREFR != None )
        QueueObjectPersistence( lkREFR )
    EndIf
EndEvent


Event WorkshopParentScript.WorkshopObjectDestroyed( WorkshopParentScript akSender, Var[] akArgs )
    ;;Debug.TraceUser( LogFile(), Self + " :: WorkshopParentScript.WorkshopObjectDestroyed()" )
    ObjectReference lkREFR = akArgs[ 0 ] As ObjectReference
    If( lkREFR != None )
        QueueObjectPersistence( lkREFR )
    EndIf
EndEvent








;/
    ===========================================================
    
    Settler Assignment Events
    
    ===========================================================
/;


Event WorkshopParentScript.WorkshopActorAssignedToWork( WorkshopParentScript akSender, Var[] akArgs )
    ;;Debug.TraceUser( LogFile(), Self + " :: WorkshopParentScript.WorkshopActorAssignedToWork()" )
    ObjectReference lkREFR = akArgs[ 0 ] As ObjectReference
    If( lkREFR != None )
        QueueObjectPersistence( lkREFR )
    EndIf
EndEvent


Event WorkshopParentScript.WorkshopActorAssignedToBed( WorkshopParentScript akSender, Var[] akArgs )
    ;;Debug.TraceUser( LogFile(), Self + " :: WorkshopParentScript.WorkshopActorAssignedToBed()" )
    ObjectReference lkREFR = akArgs[ 2 ] As ObjectReference
    If( lkREFR != None )
        QueueObjectPersistence( lkREFR )
    EndIf
EndEvent


Event WorkshopParentScript.WorkshopActorUnassigned( WorkshopParentScript akSender, Var[] akArgs )
    ;;Debug.TraceUser( LogFile(), Self + " :: WorkshopParentScript.WorkshopActorUnassigned()" )
    ObjectReference lkREFR = akArgs[ 0 ] As ObjectReference
    If( lkREFR != None )
        QueueObjectPersistence( lkREFR )
    EndIf
EndEvent








;/
    ===========================================================
    
    Thread Manager Object Placement Events
    
    ===========================================================
/;


Int Function __Thread_PlaceObject_Handler( WorkshopFramework:ObjectRefs:Thread_PlaceObject akThread )
    ObjectReference lkObject = akThread.kResult
    ;;Debug.TraceUser( LogFile(), Self + " :: __Thread_PlaceObject_Handler() :: lkObject = " + lkObject )
    If( lkObject == None )
        Return SCHEDULE_NO_WORK
    EndIf
    Return QueueObjectPersistence( lkObject )
EndFunction


;; This Thread will send the core WorkshopObjectDestroyed event so it does not need special handling
;;Int Function __Thread_ScrapObject_Handler( WorkshopFramework:ObjectRefs:Thread_ScrapObject akThread )
;;    Debug.TraceUser( LogFile(), Self + " :: __Thread_ScrapObject_Handler()" )
;;    If( akThread == None )
;;        Return SCHEDULE_GENERAL_ERROR
;;    EndIf
;;    ObjectReference lkObject = akThread.kScrapMe
;;    If( lkObject == None )
;;        Return SCHEDULE_NO_WORK
;;    EndIf
;;    Return QueueObjectPersistence( lkObject )
;;EndFunction


Event WorkshopFramework:Library:ThreadRunner.OnThreadCompleted( WorkshopFramework:Library:ThreadRunner akThreadRunner, Var[] akArgs )
	;;Debug.TraceUser( LogFile(), Self + " :: WorkshopFramework:Library:ThreadRunner.OnThreadCompleted()" \
	;;+ "\n\tlsCustomCallCallbackID = '" + akargs[ 0 ] As String + "'" )
    
    
    WorkshopFramework:ObjectRefs:Thread_PlaceObject lkPlaceObject = akArgs[ 2 ] As WorkshopFramework:ObjectRefs:Thread_PlaceObject
    If( lkPlaceObject != None )
        __Thread_PlaceObject_Handler( lkPlaceObject )
    EndIf
    
    
    ;;WorkshopFramework:ObjectRefs:Thread_ScrapObject lkScrapObject = akargs[ 2 ] As WorkshopFramework:ObjectRefs:Thread_ScrapObject
    ;;If( lkScrapObject != None )
    ;;    __Thread_ScrapObject_Handler( lkScrapObject )
    ;;EndIf
    
    
EndEvent








;/
    ===========================================================
    
    Dump persisted alias contents
    
    ===========================================================
/;


Function DumpPersistedRefs()
    Int liIndex = kAlias_PersistentObjects.GetCount()
    Debug.TraceUser( LogFile(), Self + " :: DumpPersistedRefs() :: Total Persisted = " + liIndex )
    While( liIndex > 0 )
        liIndex -= 1
        ObjectReference lkObject = kAlias_PersistentObjects.GetAt( liIndex )
        ObjectReference lkWorkshop = lkObject.GetLinkedRef( kKYWD_WorkshopItemKeyword )
        Debug.TraceUser( LogFile(), Self + " :: DumpPersistedRefs() ::    " + lkObject + " at " + lkWorkshop )
    EndWhile
EndFunction







