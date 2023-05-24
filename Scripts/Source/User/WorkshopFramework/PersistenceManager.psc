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
    
    ;; Reset the FormLists and caches on load, mods should wait until the 
    kFLST_PersistReference_ActorValues.Revert()
    kFLST_PersistReference_BaseObjects.Revert()
    kFLST_PersistReference_Keywords.Revert()
    __kPersistReference_ActorValues = None
    __kPersistReference_BaseObjects = None
    
    ;; Take the appropriate action
    __UpdatePersistenceState()

EndFunction


Function __UpdatePersistenceState()
    
    Int liIndex

    If( IsPersistenceManagementEnabled() )

        ;; Create the shadow link holder
        If( kREFR_PersistentObjects == None )
            Static lkXMarker = Game.GetFormFromFile( 0x0000003B, "Fallout4.esm" ) As Static
            ObjectReference lkSpawnMarker = Game.GetFormFromFile( 0x00004CEA, "WorkshopFramework.esm" ) As ObjectReference
            kREFR_PersistentObjects = lkSpawnMarker.PlaceAtMe( lkXMarker, aiCount = 1, abForcePersist = True, abInitiallyDisabled = True, abDeleteWhenAble = False )
            
            ;; On an existing game, this will grab all the references in the alias and link them to the holder
            liIndex = kAlias_PersistentObjects.GetCount()
            While( liIndex > 0 )
                liIndex -= 1
                ObjectReference lkObject = kAlias_PersistentObjects.GetAt( liIndex )
                If( lkObject != None )
                    lkObject.SetLinkedRef( kREFR_PersistentObjects, kKYWD_PersistentObject )
                EndIf
            EndWhile

        EndIf

        ;; Register for WorkshopParent events
        RegisterForCustomEvent( kQUST_WorkshopParent, "WorkshopObjectBuilt" )
        RegisterForCustomEvent( kQUST_WorkshopParent, "WorkshopObjectMoved" )
        RegisterForCustomEvent( kQUST_WorkshopParent, "WorkshopObjectDestroyed" )
        RegisterForCustomEvent( kQUST_WorkshopParent, "WorkshopActorAssignedToBed" )
        RegisterForCustomEvent( kQUST_WorkshopParent, "WorkshopActorAssignedToWork" )
        RegisterForCustomEvent( kQUST_WorkshopParent, "WorkshopActorUnassigned" )
        
        kQUST_ThreadManager.RegisterForCallbackThreads( Self )
        
        ;; Register for events with all the Workshops
        WorkshopScript[] lkWorkshops = kQUST_WorkshopParent.Workshops
        liIndex = lkWorkshops.Length
        While( liIndex > 0 )
            liIndex -= 1
            
            WorkshopScript lkWorkshop = lkWorkshops[ liIndex ]
            If( lkWorkshop != None )
                
                __UpdateWorkshopEventRegistration( lkWorkshop, True )
                
            EndIf
            
        EndWhile
        
        ;; Start the cycle of cleaning deleted Objects from the Manager
        __ScheduleCleanDeadPersistentObjects()
        
    Else
        
        ;; Need to wait for any running scans to finish
        __BlockQueue( aiWaitCount = 1000, abForceThrough = True )
        While( __bQueueScanning )||( __bCleaning )
            Utility.WaitMenuMode( 5.0 )
        EndWhile

        ;; Cancel any scheduled scans
        CancelTimerGameTime( iFiberID_CleanDeadPersistentObjects )
        
        ;; Unregister for WorkshopParent events
        UnregisterForCustomEvent( kQUST_WorkshopParent, "WorkshopObjectBuilt" )
        UnregisterForCustomEvent( kQUST_WorkshopParent, "WorkshopObjectMoved" )
        UnregisterForCustomEvent( kQUST_WorkshopParent, "WorkshopObjectDestroyed" )
        UnregisterForCustomEvent( kQUST_WorkshopParent, "WorkshopActorAssignedToBed" )
        UnregisterForCustomEvent( kQUST_WorkshopParent, "WorkshopActorAssignedToWork" )
        UnregisterForCustomEvent( kQUST_WorkshopParent, "WorkshopActorUnassigned" )
        
        kQUST_ThreadManager.UnregisterForCallbackThreads( Self )
        
        ;; Unregister for events with all the Workshops
        WorkshopScript[] lkWorkshops = kQUST_WorkshopParent.Workshops
        liIndex = lkWorkshops.Length
        While( liIndex > 0 )
            liIndex -= 1
            
            WorkshopScript lkWorkshop = lkWorkshops[ liIndex ]
            If( lkWorkshop != None )
                
                __UpdateWorkshopEventRegistration( lkWorkshop, False )
                
            EndIf
            
        EndWhile
        
        ;; Delete the shadow link holder
        If( kREFR_PersistentObjects != None )
            kREFR_PersistentObjects.Delete()
            kREFR_PersistentObjects = None
        EndIf
        
        ;; Lastly, empty any and all RefCollectionAliases
        kAlias_PersistentObjects.RemoveAll()
        
        liIndex = kAlias_PersistenceQueues.Length
        While( liIndex > 0 )
            liIndex -= 1
            kAlias_PersistenceQueues[ liIndex ].RemoveAll()
        EndWhile

    EndIf

EndFunction


Function __UpdateWorkshopEventRegistration( WorkshopScript akWorkshop, Bool abRegister )
    
    If( abRegister )
        
        RegisterForRemoteEvent( akWorkshop, "OnWorkshopObjectPlaced" )
        RegisterForRemoteEvent( akWorkshop, "OnWorkshopObjectMoved" )
        RegisterForRemoteEvent( akWorkshop, "OnWorkshopObjectDestroyed" )
        
        __SchedulePersistentScanOnApproach( akWorkshop, abScanIfCloseEnough = False )
        
    Else
        
        UnregisterForRemoteEvent( akWorkshop, "OnWorkshopObjectPlaced" )
        UnregisterForRemoteEvent( akWorkshop, "OnWorkshopObjectMoved" )
        UnregisterForRemoteEvent( akWorkshop, "OnWorkshopObjectDestroyed" )
        
        UnregisterForDistanceEvents( PlayerRef, akWorkshop )

    EndIf
    
EndFunction








;/
    ===========================================================
    
    Magic numbers r teh devil!
    
    ===========================================================
/;


Int                     Property    SCHEDULE_DISABLED = 3                           AutoReadOnly Hidden
Int                     Property    SCHEDULE_NO_WORK = 2                            AutoReadOnly Hidden
Int                     Property    SCHEDULE_SCHEDULED = 1                          AutoReadOnly Hidden
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
    
    GlobalVariable      Property    kGLOB_EnablePersistenceManagement               Auto Const Mandatory
    { Depending on the platform, persistence management may need to be disabled to save memory }

EndGroup

Bool Function IsPersistenceManagementEnabled()
    Return ( kGLOB_EnablePersistenceManagement.GetValueInt() != 0 )
EndFunction

;; MCM/Terminal/MessageBox should invoke this to fully change the internal state of the Manager
Function EnablePersistenceManagement( Bool abEnable )
    If( abEnable == IsPersistenceManagementEnabled() )
        Return
    EndIf
    Float lfValue = 0.0
    String lsEndMsg
    If( abEnable )
        Debug.TraceUser( LogFile(), "Enabling Persistence Management..." )
        lsEndMsg = "...Enabled Persistence Management"
        lfValue = 1.0
    Else
        Debug.TraceUser( LogFile(), "Disabling Persistence Management..." )
        lsEndMsg = "...Disabled Persistence Management"
    EndIf
    kGLOB_EnablePersistenceManagement.SetValue( lfValue )
    __UpdatePersistenceState()
    Debug.TraceUser( LogFile(), lsEndMsg )
EndFunction


Group PersistenceAlias
    
    RefCollectionAlias  Property    kAlias_PersistentObjects                        Auto Const Mandatory
    { This holds and forces all the objects to persist }
    
    ObjectReference     Property    kREFR_PersistentObjects                         Auto Hidden
    { This shadows the above alias, it is used for rapid access as an array using GetLinkedRefChildren }
    
    Keyword             Property    kKYWD_PersistentObject                          Auto Const Mandatory
    { This is used to link the persisted objects to the linked ref holder }
    
EndGroup


ObjectReference[] Function GetPersistedObjects()
    If( kREFR_PersistentObjects == None )
        Return None
    EndIf
    Return kREFR_PersistentObjects.GetLinkedRefChildren( kKYWD_PersistentObject )
EndFunction


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


;; Mods should call this function to add their actor value that may be on an ObjectReference that should be persisted
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


;; Mods should call this function to add their base form to the type of ObjectReference that should be persisted
Function Add_PersistReference_BaseObject( Form akForm )
    kFLST_PersistReference_BaseObjects.AddForm( akForm )
    __kPersistReference_BaseObjects = None
EndFunction








;; Mods should call this function to add their keyword that may be attached to an ObjectReference that should be persisted
Function Add_PersistReference_Keyword( Keyword akKYWD )
    kFLST_PersistReference_Keywords.AddForm( akKYWD )
EndFunction


Keyword[] Function Get_PersistReference_Keywords()
    Return FormListToArray( kFLST_PersistReference_Keywords ) As Keyword[]
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
        
        If( liScheduling <= SCHEDULE_TOO_BUSY )
            ;; Too busy means we are scanning, but new objects have been queued in the back buffer
            ;; Otherwise some error occured, try again later
            __ScheduleQueuedPersistenceScanning( abForceTimer = True )
            
        EndIf
        
    ElseIf( aiTimerID == iFiberID_CleanDeadPersistentObjects )
        
        Int liScheduling = __CleanDeadPersistentObjects()
        
        If( liScheduling <  SCHEDULE_TOO_BUSY )
            ;; Too busy means we are scanning, let it finish and reschedule when it's done
            ;; That means some error occured, try again later
            __ScheduleCleanDeadPersistentObjects( abForceTimer = True )
            
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
        
        ;; Allow the next queued scan to be started
        __bQueueScanning = False
        
    ElseIf  ( liCallbackID == iFiberID_CleanDeadPersistentObjects )
        ;; Message to display
        lkMessage = kMESG_CleaningComplete
        lbRequiresWorkshop = False
        
        ;; Schedule a new cleaning scan
        __bCleaning = False
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
        + "\n\tTotal Persisted Objects = " + kAlias_PersistentObjects.GetCount() \
        + "\n\tPaste this line in the console to get a full list of persisted objects (written to the " + LogFile() + " log):" \
        + "\n\t\tcqf WSFW_PersistenceManager DumpPersistedRefs" )
    
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




Function __ScheduleCleanDeadPersistentObjects( Bool abForceTimer = False )
    If( !IsPersistenceManagementEnabled() )
        Return ;;SCHEDULE_DISABLED
    EndIf
    
    If( __bCleaning )\
    &&( !abForceTimer )
        Return ;; Don't restart the timer (unless forced)
    EndIf

    StartTimerGameTime( __fTimerHours_CleanDeadObjects, iFiberID_CleanDeadPersistentObjects )
EndFunction



Bool                                __bCleaning = False
Int Function __CleanDeadPersistentObjects()
    If( !IsPersistenceManagementEnabled() )
        Return SCHEDULE_DISABLED
    EndIf

    If( __bCleaning ) ;; Already cleaning
        Return SCHEDULE_TOO_BUSY
    EndIf
    __bCleaning = True

    Debug.TraceUser( LogFile(), Self + " :: __CleanDeadPersistentObjects()" )

    Int liObjects = kAlias_PersistentObjects.GetCount()
    If( liObjects == 0 )
        ;;Debug.TraceUser( LogFile(), Self + " :: __CleanDeadPersistentObjects() :: No Work" )
        __bCleaning = False
        Return SCHEDULE_NO_WORK
    EndIf
    
    
    FiberController lkController = \
        WorkshopFramework:ObjectRefs:Fiber_PersistenceRemoveDeletedObjects.CreateFiberController( \
            True )
    
    If( lkController == None )
        ;; CreateFiberController will write exceptions to the log
        ;;Debug.TraceUser( LogFile(), Self + " :: __CleanDeadPersistentObjects() :: Cannot create FiberController" )
        __bCleaning = False
        Return SCHEDULE_GENERAL_ERROR
    EndIf
    
    
    If( !lkController.QueueFibers( abSync = False ) )
        Debug.TraceUser( LogFile(), Self + " :: __CleanDeadPersistentObjects() :: Could not queue Fibers" )
        lkController.Delete()
        __bCleaning = False
        Return SCHEDULE_QUEUE_ERROR
    EndIf
    
    
    ;; Inform the player?
    If( ShowPersistenceMessages() )
        kMESG_CleaningStart.Show()
    EndIf
    
    
    ;;Debug.TraceUser( LogFile(), Self + " :: __CleanDeadPersistentObjects() :: Scheduled" )
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



;; Immediately scan an array of objects and persist the ones that need it
Int Function PersistObjectArray(  \
    WorkshopScript      akWorkshop, \
    ObjectReference[]   akObjects, \
    Bool                abSync = False, \
    Bool                abRegisterManagerCallback = False \
    )
    
    If( !IsPersistenceManagementEnabled() )
        Return SCHEDULE_DISABLED
    EndIf
    
    ;;Debug.TraceUser( LogFile(), Self + " :: PersistObjectArray()" \
    ;;+ "\n\takWorkshop = " + akWorkshop \
    ;;+ "\n\takObjects  = " + akObjects.Length \
    ;;+ "\n\tabSync     = " + abSync \
    ;;+ "\n\tabRegisterManagerCallback = " + abRegisterManagerCallback )
    
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




;; Queue an array of objects to be scanned in the next cycle
Int Function QueueObjectArray( ObjectReference[] akObjects )
    If( !IsPersistenceManagementEnabled() )
        Return SCHEDULE_DISABLED
    EndIf
    
    Int liObjects = akObjects.Length
    If( liObjects == 0 )
        Return SCHEDULE_NO_WORK
    EndIf
    
    Int liResult = SCHEDULE_SCHEDULED
    
    While( liObjects > 0 )
        liObjects -= 1
        Int liQueued = QueueObjectPersistence( akObjects[ liObjects ] )
        If( liQueued != SCHEDULE_SCHEDULED )
            liResult = liQueued
        EndIf
    EndWhile
    
    Return liResult
EndFunction




;; Queue a single object to be scanned in the next cycle
Int Function QueueObjectPersistence( ObjectReference akObject )
    If( !IsPersistenceManagementEnabled() )
        Return SCHEDULE_DISABLED
    EndIf
    
    ;;Debug.TraceUser( LogFile(), Self + " :: QueueObjectPersistence() :: akObject = " + akObject )
    
    If( akObject == None )
        ;;Debug.TraceUser( LogFile(), Self + " :: QueueObjectPersistence() :: No Work" )
        Return SCHEDULE_NO_WORK
    EndIf
    
    ;; Block the queues from swapping while we add to it
    If( !__BlockQueue() )
        Return SCHEDULE_TOO_BUSY
    EndIf
    

    ;; Add it to the active queue
    kAlias_PersistenceQueues[ __iQueueBufferActive ].AddRef( akObject )
    
    
    ;; Start the timer for the queue scan
    __ScheduleQueuedPersistenceScanning()
    
    
    __bQueueBlock = False
    ;;Debug.TraceUser( LogFile(), Self + " :: QueueObjectPersistence() :: Scheduled" )
    Return SCHEDULE_SCHEDULED
EndFunction




Int Function __TryScanPersistence( WorkshopScript akWorkshop )
    If( !IsPersistenceManagementEnabled() )
        Return SCHEDULE_DISABLED
    EndIf
    
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
    If( !IsPersistenceManagementEnabled() )
        Return ;;SCHEDULE_DISABLED
    EndIf
    
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





Bool                                __bQueueScheduled = False
Function __ScheduleQueuedPersistenceScanning( Bool abForceTimer = False )
    If( !IsPersistenceManagementEnabled() )
        Return ;;SCHEDULE_DISABLED
    EndIf
    
    If( __bQueueScheduled )\
    &&( !abForceTimer )
        Return ;; Don't restart the timer (unless forced), the double-buffering design is so we can queue to one buffer while scanning the other
    EndIf

    ;;Debug.TraceUser( LogFile(), Self + " :: __ScheduleQueuedPersistenceScanning()" )
    StartTimerGameTime( __fTimerHours_ScanQueue, iFiberID_PersistenceScanQueue )
    __bQueueScheduled = True
EndFunction




Bool                                __bQueueBlock = False
Bool Function __BlockQueue( Int aiWaitCount = 100, Bool abForceThrough = False )
    Int liCount = 0
    While( __bQueueBlock )&&( liCount < aiWaitCount )
        Utility.WaitMenuMode( Utility.RandomFloat( 0.125, 0.875 ) ) ;; 1/8 - 7/8s delay to try and even out the calls
        liCount += 1
    EndWhile
    If( __bQueueBlock )&&( !abForceThrough )
        Return False
    EndIf
    __bQueueBlock = True
    Return True
EndFunction


Bool                                __bQueueScanning = False
Int Function __ScanPersistenceQueue()
    If( !IsPersistenceManagementEnabled() )
        Return SCHEDULE_DISABLED
    EndIf

    ;;Debug.TraceUser( LogFile(), Self + " :: __ScanPersistenceQueue()" )
    
    If( !__BlockQueue() )
        Return SCHEDULE_TOO_BUSY
    EndIf
    
    If( __bQueueScanning )
        ;; Scan buffer still being scanned
        __bQueueBlock = False
        Return SCHEDULE_TOO_BUSY
    EndIf
    __bQueueScanning = True

    ;; Scan buffer is active buffer
    Int liScanBuffer = __iQueueBufferActive
    RefCollectionAlias lkScanBuffer = kAlias_PersistenceQueues[ liScanBuffer ]
    Int liBufferedCount = lkScanBuffer.GetCount()
    If( liBufferedCount == 0 )
        ;; Nothing to do
        ;;Debug.TraceUser( LogFile(), Self + " :: __ScanPersistenceQueue() :: No Work" )
        __bQueueScanning = False
        __bQueueScheduled = False
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
        __bQueueScanning = False
        __bQueueBlock = False
        ;;Debug.TraceUser( LogFile(), Self + " :: __ScanPersistenceQueue() :: Unable to create FiberController" )
        Return SCHEDULE_GENERAL_ERROR
    EndIf
    
    
    If( !lkController.QueueFibers( abSync = False ) )
        Debug.TraceUser( LogFile(), Self + " :: __ScanPersistenceQueue() :: Could not queue Fibers" )
        lkController.Delete()
        __bQueueScanning = False
        __bQueueBlock = False
        Return SCHEDULE_QUEUE_ERROR
    EndIf
    
    
    ;; Swap the buffers
    __iQueueBufferActive = liNewActiveBuffer

    ;; Allow the scan buffer to be queued
    __bQueueScheduled = False
    
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

    String lsLogFile = LogFile()
    
    String lsDump = Self + " :: DumpPersistedRefs() :: You asked for it..."
    Int liScanBuffer = ( __iQueueBufferActive + 1 ) % 2
    lsDump += "\n\t__iQueueBufferActive = " + __iQueueBufferActive
    lsDump += "\n\tliScanBuffer = " + liScanBuffer
    lsDump += "\n\tActive Buffer Count = " + kAlias_PersistenceQueues[ __iQueueBufferActive ].GetCount()
    lsDump += "\n\tScan Buffer Count = " + kAlias_PersistenceQueues[ liScanBuffer ].GetCount()

    Int liIndex = kAlias_PersistentObjects.GetCount()
    lsDump += "\n\tTotal Persisted = " + liIndex
    Debug.TraceUser( lsLogFile, lsDump )
    

    ActorValue[] lkActorValues  = Get_PersistReference_ActorValues()
    Form[]       lkBaseObjects  = Get_PersistReference_BaseObjects()
    Keyword[]    lkKeywords     = Get_PersistReference_Keywords()
    Keyword      lkMustPersist  = Game.GetFormFromFile( 0x0004AF68, "Fallout4.esm" ) As Keyword
    Keyword      lkDoNotPersist = Game.GetFormFromFile( 0x0010805B, "Fallout4.esm" ) As Keyword
    ObjectReference lkReference = Game.GetFormFromFile( 0x00004CEA, "WorkshopFramework.esm" ) As ObjectReference ;; The WSFW spawn marker shall be our reference object for AVIFs

    ;; This will work backwards to try and stay ahead of any cleaning that may be running at the same time
    While( liIndex > 0 )
        liIndex -= 1
        ObjectReference lkObject = kAlias_PersistentObjects.GetAt( liIndex )
        
        lsDump = Self + " :: DumpPersistedRefs() ::\n\tAlias Index = " + liIndex + "\n\tlkObject = " + lkObject
        
        If( lkObject != None )
            
            Form lkBaseObject = lkObject.GetBaseObject()
            If( lkBaseObject != None )
                lsDump += "\n\tlkBaseObject = " + lkBaseObject
            EndIf
            
            ObjectReference lkWorkshop = lkObject.GetLinkedRef( kKYWD_WorkshopItemKeyword )
            If( lkWorkshop != None )
                lsDump += "\n\tlkWorkshop = " + lkWorkshop
            EndIf
            
            lsDump = lsDump + __FindReasonForPersistence( lkObject, lkActorValues, lkBaseObjects, lkKeywords, lkMustPersist, lkDoNotPersist, lkReference )
            
        EndIf
        
        Debug.TraceUser( lsLogFile, lsDump )
    EndWhile

    ;; It is done
EndFunction




Form Function __FindPersistenceActorValue( ObjectReference akREFR, ActorValue[] akActorValues, ObjectReference akReference )
    Int liIndex = akActorValues.Length
    While( liIndex > 0 )
        liIndex -= 1
        ActorValue lkAVIF = akActorValues[ liIndex ]
        If( akREFR.GetBaseValue( lkAVIF ) != akReference.GetBaseValue( lkAVIF ) )
            Return akActorValues[ liIndex ]
        EndIf
    EndWhile
    Return None
EndFunction

Form Function __FindPersistenceKeyword( ObjectReference akREFR, Keyword[] akKeywords )
    Int liIndex = akKeywords.Length
    While( liIndex > 0 )
        liIndex -= 1
        Keyword lkKYWD = akKeywords[ liIndex ]
        If( akREFR.HasKeyword( lkKYWD ) )
            Return lkKYWD
        EndIf
    EndWhile
    Return None
EndFunction

Bool Function __BaseObjectRequiresPersistence( Form akBaseObject, Form[] akBaseObjects )
    Return( akBaseObjects.Find( akBaseObject ) >= 0 )
EndFunction

String Function __GenerateReasonString( Bool abNeedsPersistence, String asReason, ScriptObject akExtra = None )
    String lsDebug = "\n\tabNeedsPersistence = " + abNeedsPersistence + "\n\tasReason = " + asReason
    If( akExtra != None )
        lsDebug = lsDebug + "\n\takExtra = " + akExtra
    EndIf
    Return lsDebug
EndFunction

String Function __FindReasonForPersistence( \
    ObjectReference     akREFR, \
    ActorValue[]        akActorValues, \
    Form[]              akBaseObjects, \
    Keyword[]           akKeywords, \
    Keyword             akMustPersist, \
    Keyword             akDoNotPersist, \
    ObjectReference     akReference )
    ;; Do fast fails...
    
    ;; Required test (native remote call) regardless of anything else
    If  ( akREFR.IsDeleted() )
        Return __GenerateReasonString( False, "IsDeleted()" )
    EndIf

    ;; Some check are against the base object
    Form lkBaseObject = akREFR.GetBaseObject()

    ;; Engine level forced persistence
    If( lkBaseObject.HasKeyword( akMustPersist ) )\
    ||( akREFR.HasKeyword( akMustPersist ) )
        Return __GenerateReasonString( True, "MustPersist" )
    EndIf

    ;; Our override to prevent non-engine forced persistence
    If( lkBaseObject.HasKeyword( akDoNotPersist ) )\
    ||( akREFR.HasKeyword( akDoNotPersist ) )
        Return __GenerateReasonString( False, "DoNotPersist" )
    EndIf
    
    ;; Super fast test for WorkshopObjectScript
    WorkshopObjectScript lkWSObject = akREFR As WorkshopObjectScript
    If( lkWSObject != None )
        Return __GenerateReasonString( True, "WorkshopObjectScript" )
    EndIf
    
    ;; Fast test the base object being in the array
    If( __BaseObjectRequiresPersistence( lkBaseObject, akBaseObjects ) )
        Return __GenerateReasonString( True, "BaseObject" )
    EndIf
    
    ;; Quick test (one native remote call) for having one of the keywords
    Form lkExtra = __FindPersistenceKeyword( akREFR, akKeywords )
    If( lkExtra != None )
        Return __GenerateReasonString( True, "Keyword", lkExtra )
    EndIf
    
    ;; Slow test (multiple native remote calls) for having any of the Actor Values
    lkExtra = __FindPersistenceActorValue( akREFR, akActorValues, akReference )
    If( lkExtra != None )
        Return __GenerateReasonString( True, "ActorValue", lkExtra )
    EndIf
    
    ;; After all that, we don't need to be persisted
    Return __GenerateReasonString( False, "No persistence required" )
EndFunction







