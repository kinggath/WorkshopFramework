ScriptName WorkshopFramework:Library:ObjectRefs:FiberController Extends ObjectReference
{
    Script for managing a group of Fibers or "swarm threads" for parallel processing
}
String Function ____ScriptName() Global
    Return "WorkshopFramework:Library:ObjectRefs:FiberController"
EndFunction
Activator Function GetFiberControllerBaseObject() Global
    ; Get base form this script is on
    Return Game.GetFormFromFile( 0x00006419, "WorkshopFramework.esm" ) As Activator
EndFunction




Import WorkshopFramework:Library:ObjectRefs
Import WorkshopFramework:Library:UtilityFunctions








;/
    ===========================================================
    
    Custom events
    
    ===========================================================
/;


;; Sent when all the Fibers are complete
CustomEvent OnFiberComplete
;; Args:
;; 0        = sCustomCallbackID
;; 1        = iCallbackID
;; 2        = bResult
;; 3        = iChanged (Requires the Fibers to call Increment())
;; 4        = iTotalCount
;; If bResult = False
;; 5        = Failed on Index (may be -1)
;; 6        = Failed on ScriptObject (may be None)
;; After the above - Use GetUserParams() to get the first index of user code results
;; ...      = Fiber dependant results
Int Function GetUserParams( Var[] akParams ) Global
    ;;Debug.Trace( ____ScriptName() + " :: GetUserParams()" )
    ;; A return value of -1 means no user params
    Int liLength = akParams.Length
    If( liLength < 5 )
        Return -1
    EndIf
    
    If( ( akParams[ 2 ] As Bool ) == False )
        If( liLength > 7 )
            Return 7
        EndIf
        Return -1
    EndIf
    
    If( liLength > 5 )
        Return 5
    EndIf
    Return -1
EndFunction








;/
    ===========================================================
    
    The actual Fibers
    
    ===========================================================
/;


Fiber[]                             __kFibers = None




;; Fiber count
Int                     Property    iTotalFibers                                    Hidden
    Int Function Get()
        Return __kFibers.Length
    EndFunction
EndProperty




;; Get a specific Fiber, be sure to cast the returned Fiber as your specific Fiber subclass
Fiber Function GetFiber( Int aiIndex )
    If( aiIndex < 0 )\
    ||( aiIndex >= __kFibers.Length )
        Return None
    EndIf
    Return __kFibers[ aiIndex ]
EndFunction








;/
    ===========================================================
    
    ObjectReference overrides
    
    ===========================================================
/;


Function Delete()
    ;;Debug.Trace( Self + " :: Delete()" )
    
    
    ;; Unregister the OnFiberComplete handler
    If( __kOnCompleteHandler != None )
        __kOnCompleteHandler.UnregisterForCustomEvent( Self, "OnFiberComplete" )
    EndIf
    
    
    If( __bFibersQueued )
        
        ;; Need to wait for the Fibers to stop, they will delete themselves when done
        CancelFibers()
        __WaitForFibersToComplete()
        
    Else
        
        ;; Haven't even started the Fibers yet, delete them
        _EmergencyDeleteFibers()
        
    EndIf
    
    
    ;; Clear out everything
    
    __sCustomCallbackID     = ""
    __iCallbackID           = -1
    __bFibersQueued        = False
    __kFibers              = None
    
    
    ;; And, of course, let the engine handle the rest
    ;;Debug.Trace( Self + " :: Parent.Delete()" )
    Parent.Delete()
EndFunction









;/
    ===========================================================
    
    Queue the fibers for execution
    
    ===========================================================
/;


WorkshopFramework:MainThreadManager Function GetThreadManager() Global
    Return ( Game.GetFormFromFile( 0x00001736, "WorkshopFramework.esm" ) As Quest ) As WorkshopFramework:MainThreadManager
EndFunction


Bool Function QueueFibers( Bool abSync = False )
    ;;Debug.Trace( Self + " :: QueueFibers()" )
    If( __bFibersQueued )
        Debug.Trace( Self + " :: QueueFibers() :: Already Queued" )
        Return False
    EndIf
    __bFibersQueued = True
    
    WorkshopFramework:MainThreadManager lkThreadManager = GetThreadManager()
    
    ;; Force other threads to wait
    __BlockController()
    
    ;; Force the OnFiberComplete to wait for us
    __bSync = abSync
    
    Int liFiberCount = __kFibers.Length
    Int liIndex = 0
    While( liIndex < liFiberCount )
        
        If( lkThreadManager.QueueThread( __kFibers[ liIndex ] ) < 0 )
            Debug.Trace( Self + " :: QueueFibers() :: Fiber " + liIndex + " of " + liFiberCount + " :: WSFW Main Thread Manager could not queue the Fiber!" )
            __bSync = False
            __bBlocked = False
            Return False
        EndIf
        
        liIndex += 1
    EndWhile
    
    
    ;; Return that the fibers are queued
    Bool lbResult = True
    
    
    If( __bSync )
        ;; This should return synchronously with the fibers terminating
        
        ;; Wait for the last fiber to be removed from the Controller on it's ThreadRunComplete
        __WaitForFibersToComplete()
        
        ;; Return the results of fibers
        lbResult = __bResult
        If( !lbResult )
            Debug.Trace( Self + ":: QueueFibers() :: Sync: One or more Fibers encountered an error" )
        EndIf
        
        ;; Delete the Controller
        Self.Delete()
        
    EndIf
    
    
    __bBlocked = False
    
    ;; Return that the fibers are queued or their results
    ;;Debug.Trace( Self + " :: QueueFibers() :: lbResult = " + lbResult )
    Return lbResult
EndFunction








;/
    ===========================================================
    
    Fiber syncronization
    
    ===========================================================
/;

Bool                                __bBlocked = False
Bool                                __bSync = False
Float                               __fMinWaitTime = 0.0
Float                               __fMaxWaitTime = 0.0
Float                               __fWaitTimeGrowthRate = 1.05                    Const




Function __BlockController()
    __ResetSyncWaitTime()
    While( __bBlocked )
        Utility.WaitMenuMode( __GetSyncWaitTime() )
    EndWhile
    __bBlocked = True
EndFunction


Function __ResetSyncWaitTime()
    __fMinWaitTime = 0.50
    __fMaxWaitTime = 1.25
EndFunction


Float Function __GetSyncWaitTime()
    Float lfResult = Utility.RandomFloat( __fMinWaitTime, __fMaxWaitTime )
    __fMinWaitTime *= __fWaitTimeGrowthRate
    __fMaxWaitTime *= __fWaitTimeGrowthRate
    Return lfResult
EndFunction


Function __WaitForFibersToComplete( Int aiWaitCount = 100 )
    ;;Debug.Trace( Self + " :: __WaitForFibersToComplete() :: ..." )
    If( aiWaitCount < 1 )
        aiWaitCount = 100
    EndIf
    
    __ResetSyncWaitTime()
    
    Int liWaitCount = 0
    While( __kFibers.Length > 0 )&&( liWaitCount < aiWaitCount )
        Utility.WaitMenuMode( __GetSyncWaitTime() )
        liWaitCount += 1
    EndWhile
    ;;Debug.Trace( Self + " :: __WaitForFibersToComplete() :: Waited" )
EndFunction








;/
    ===========================================================
    
    Fiber Management
    
    ===========================================================
/;

Bool                                __bCancel = False
Bool                                __bSelfDestruct = True

Bool                                __bFibersQueued = False

ScriptObject                        __kOnCompleteHandler = None
String                              __sCustomCallbackID = ""
Int                                 __iCallbackID = -1

Int                                 __iWorkingSetSize = 0




Int Function GetWorkingSetSize()
    Return __iWorkingSetSize
EndFunction








;; Used in Create()
;; May also be used in Fiber classes in it's CreateFiberController() function if an error occurs
Function _EmergencyDeleteFibers()
   ;; Debug.Trace( Self + " :: _EmergencyDeleteFibers()" )
    Int liIndex = __kFibers.Length
    While( liIndex > 0 )
        liIndex -= 1
        Fiber lkFiber = __kFibers[ liIndex ]
        If( lkFiber != None )
            Self.UnregisterForCustomEvent( lkFiber, "ThreadRunComplete" )
            lkFiber.SelfDestruct()
        EndIf
    EndWhile
    __kFibers.Clear()
    __kFibers = None
EndFunction








;; Maximum threads allowed to run at once, globally
Int Function GetMaxThreads() Global
    GlobalVariable lkMaxThreads = Game.GetFormFromFile( 0x00019D49, "WorkshopFramework.esm" ) As GlobalVariable
    Return lkMaxThreads.GetValueInt()
EndFunction

;; Percentage of those Threads that can be assigned to any given swarm of Fibers (maximally)
Float Function GetMaxFibers() Global
    GlobalVariable lkMaxFibers = Game.GetFormFromFile( 0x00002675, "WorkshopFramework.esm" ) As GlobalVariable
    Return lkMaxFibers.GetValue()
EndFunction

;; Maximum Fibers per Swarm
Int Function GetMaxSwarm() Global
    Int liMaxThreads = GetMaxThreads()
    Float lfMaxFibers  = GetMaxFibers()
    Int liMaxSwarm = ( ( ( liMaxThreads As Float ) * lfMaxFibers ) + 0.5 ) As Int ;; Add +0.5 to round up
    If( liMaxSwarm > liMaxThreads )
        liMaxSwarm = liMaxThreads
    EndIf
    If( liMaxSwarm <= 1 )
        ;;Debug.Trace( Self + " :: GetMaxSwarm() :: liMaxSwarm <= 1" )
        liMaxSwarm = 1
    EndIf
    Return liMaxSwarm
EndFunction


Int Function __CalculateFiberCount( Int aiWorkingSetSize, Int aiMinChunkSize = -1, Int aiMaxChunkSize = -1 )
    
    ;; Default
    __iWorkingSetSize = aiWorkingSetSize
    Int liFiberCount = 1
    Int liChunkSize = __iWorkingSetSize
    Int liRemainder = 0
    
    If( __iWorkingSetSize <= 0 )
        Debug.Trace( Self + " :: __CalculateFiberCount() :: __iWorkingSetSize <= 0" )
        Return 0
    EndIf
    
    If( aiMinChunkSize > __iWorkingSetSize )
        Debug.Trace( Self + " :: __CalculateFiberCount() :: aiMinChunkSize > __iWorkingSetSize" )
        Return 1
    EndIf
    
    ;; Get global max threads
    ;;Int liMaxThreads = GetMaxThreads()  ;; Only for debugging, can comment if the Trace() is commented
    ;;Float lfMaxFibers  = GetMaxFibers() ;; Only for debugging, can comment if the Trace() is commented
    Int liMaxSwarm = GetMaxSwarm()
    
    Float lfRatio = 2.0 ;; Default 2:1 ratio if inputs are not provided
    If( aiMinChunkSize > 0 )&&( aiMaxChunkSize >= aiMinChunkSize )
        lfRatio = ( aiMaxChunkSize As Float ) / ( aiMinChunkSize As Float )
    EndIf
    
    If( aiMinChunkSize < 1 )
        ;; Min chunk size to use all fibers
        aiMinChunkSize = __iWorkingSetSize / liMaxSwarm
    EndIf
    
    While( aiMinChunkSize * liMaxSwarm < __iWorkingSetSize )
        ;; Enlarge the min chunkSize so it fits into max fibers instead of
        ;; being max fibers +1
        aiMinChunkSize += 1
    EndWhile
    
    If( aiMaxChunkSize < 1 )
        ;; Default max chunk size to be the whole data set
        aiMaxChunkSize = __iWorkingSetSize
    EndIf
    
    If( aiMaxChunkSize < aiMinChunkSize )
        ;; Move the max up to the min
        aiMaxChunkSize = aiMinChunkSize
    EndIf
    
    Int aiCeilingChunkSize = ( ( aiMinChunkSize As Float ) * lfRatio ) As Int
    If( aiCeilingChunkSize > __iWorkingSetSize )
        ;; Ceiling can't be higher than the total working set
        aiCeilingChunkSize = __iWorkingSetSize
    EndIf
    
    If( aiMaxChunkSize > aiCeilingChunkSize )
        ;; Scale down max size if it would be larger than the ratio
        aiMaxChunkSize = aiCeilingChunkSize
    EndIf
    
    ;; Calculate the mean chunk size
    Int liMeanChunkSize = aiMinChunkSize + ( aiMaxChunkSize - aiMinChunkSize ) / 2
    
    ;; Calculate number of fibers required for mean chunk size
    liFiberCount = __iWorkingSetSize / liMeanChunkSize
    
    ;; At least one Fiber
    If( liFiberCount < 1 )
        liFiberCount = 1
    EndIf
    ;; Never more than liMaxSwarm Fibers
    If( liFiberCount > liMaxSwarm )
        liFiberCount = liMaxSwarm
    EndIf
    
    ;; TODO:  Comment this out at some point
    ;;Debug.Trace( Self + " :: __CalculateFiberCount()" \
    ;;+ "\n\tliMaxThreads    = " + liMaxThreads \
    ;;+ "\n\tlfMaxFibers     = " + lfMaxFibers \
    ;;+ "\n\tliMaxSwarm      = " + liMaxSwarm \
    ;;+ "\n\tliFiberCount    = " + liFiberCount \
    ;;+ "\n\tliMeanChunkSize = " + liMeanChunkSize \
    ;;)
    
    Return liFiberCount
EndFunction








;/
    ===========================================================
    
    Create a FiberController and Fiber[s]
    
    ===========================================================
/;


ObjectReference Function GetSpawnMarker() Global
    Return Game.GetFormFromFile( 0x00004CEA, "WorkshopFramework.esm" ) As ObjectReference
EndFunction


;; Notes:
;;   akFiberClass must be provided and instances must cast as a Fiber
;;   If akFiberControllerClass is provided (it will default to the internal default FiberController), instances must cast as FiberController
FiberController Function Create( \
    Activator       akFiberClass, \
    Int             aiWorkingSetSize, \
    ScriptObject    akOnFiberCompleteHandler = None, \
    String          asCustomCallbackID = "", \
    Int             aiCallbackID = -1, \
    Int             aiMinChunkSize = -1, \
    Int             aiMaxChunkSize = -1, \
    Bool            abWorkBackwards = False, \
    Activator       akFiberControllerClass = None \
    ) Global
    ;;Debug.Trace( ____ScriptName() + " :: Create()" \
    ;;+ "\n\takFiberClass             = " + akFiberClass \
    ;;+ "\n\taiWorkingSetSize         = " + aiWorkingSetSize \
    ;;+ "\n\takOnFiberCompleteHandler = " + akOnFiberCompleteHandler \
    ;;+ "\n\tasCustomCallbackID       = '" + asCustomCallbackID + "'" \
    ;;+ "\n\taiCallbackID             = " + IntToHex( aiCallbackID, 8 ) \
    ;;+ "\n\taiMinChunkSize           = " + aiMinChunkSize \
    ;;+ "\n\taiMaxChunkSize           = " + aiMaxChunkSize \
    ;;+ "\n\tabWorkBackwards          = " + abWorkBackwards \
    ;;+ "\n\takFiberControllerClass   = " + akFiberControllerClass \
    ;;)
    
    
    ;; Make sure we're not insane...
    
    
    If( aiWorkingSetSize < 1 )
        Debug.Trace( ____ScriptName() + " :: Create() :: aiWorkingSetSize is invalid: " + aiWorkingSetSize )
        Return None
    EndIf
    
    If( akFiberClass == None )
        Debug.Trace( ____ScriptName() + " :: Create() :: akFiberClass is invalid: " + akFiberClass )
        Return None
    EndIf
    
    
    ;; FiberController class specified?  If not, use generic base class
    If( akFiberControllerClass == None )
        akFiberControllerClass = GetFiberControllerBaseObject()
    EndIf
    
    
    ;; Now spawn the controller and initialize it...
    ObjectReference lkSpawnMarker = GetSpawnMarker()
    
    
    ;; Persistent, Disabled, Do not delete when able (it will delete itself as well as all the associated Fibers)
    ObjectReference lkControllerRef = lkSpawnMarker.PlaceAtMe( akFiberControllerClass, 1, True, True, False )
    If( lkControllerRef == None )
        Debug.Trace( ____ScriptName() + " :: Create() :: Could not spawn the FiberController!" )
        Return None
    EndIf
    
    
    FiberController lkController = lkControllerRef As FiberController
    If( lkController == None )
        ;; This should never happen, but just in case...
        Debug.Trace( ____ScriptName() + " :: Create() :: akFiberControllerClass does not have the FiberController (or extended script) attached to it!\n\t" + akFiberControllerClass )
        lkControllerRef.Delete()
        Return None
    EndIf
    
    
    If( !lkController.__CreateFibers( \
        aiWorkingSetSize, \
        lkSpawnMarker, \
        akFiberClass, \
        akOnFiberCompleteHandler, \
        asCustomCallbackID, \
        aiCallbackID, \
        aiMinChunkSize, \
        aiMaxChunkSize, \
        abWorkBackwards \
        ) )
        lkController.Delete()
        Return None
    EndIf
    
    
    ;; If we made it this far, then all is good!
    ;;Debug.Trace( ____ScriptName() + " :: CreateFiberController() :: Complete" )
    Return lkController
EndFunction




;; Notes:
;;   akFiberClass must be provided and instances must cast as a Fiber
Fiber Function CreateFiber( \
    Activator       akFiberClass, \
    ScriptObject    akThreadRunCompleteHandler = None \
    ) Global
    ;;Debug.Trace( ____ScriptName() + " :: CreateFiber()" \
    ;;+ "\n\takFiberClass = " + akFiberClass \
    ;;+ "\n\takThreadRunCompleteHandler = " + akThreadRunCompleteHandler )
    
    ;; Make sure we're not insane...
    If( akFiberClass == None )
        Debug.Trace( ____ScriptName() + " :: CreateFiber() :: akFiberClass is None" )
        Return None
    EndIf
    
    Return __CreateFiber( \
        akFiberClass, \
        None, \
        akThreadRunCompleteHandler, \
        GetSpawnMarker() )
EndFunction




;; Everything must be vetted before entry
Bool Function __CreateFibers( \
    Int             aiWorkingSetSize, \
    ObjectReference akSpawnMarker, \
    Activator       akFiberClass, \
    ScriptObject    akOnFiberCompleteHandler, \
    String          asCustomCallbackID, \
    Int             aiCallbackID, \
    Int             aiMinChunkSize, \
    Int             aiMaxChunkSize, \
    Bool            abWorkBackwards \
    )
    ;;Debug.Trace( Self + " :: __CreateFibers()" \
    ;;+ "\n\taiWorkingSetSize         = " + aiWorkingSetSize \
    ;;+ "\n\takSpawnMarker            = " + akSpawnMarker \
    ;;+ "\n\takFiberClass             = " + akFiberClass \
    ;;+ "\n\takOnFiberCompleteHandler = " + akOnFiberCompleteHandler \
    ;;+ "\n\tasCustomCallbackID       = '" + asCustomCallbackID + "'" \
    ;;+ "\n\taiCallbackID             = " + IntToHex( aiCallbackID, 8 ) \
    ;;+ "\n\taiMinChunkSize           = " + aiMinChunkSize \
    ;;+ "\n\taiMaxChunkSize           = " + aiMaxChunkSize \
    ;;+ "\n\tabWorkBackwards          = " + abWorkBackwards \
   ;; )
    
    
    ;; Calculate the "optimal" fiber count for the parameters given
    
    
    Int liFiberCount = __CalculateFiberCount( aiWorkingSetSize, aiMinChunkSize, aiMaxChunkSize )
    
    
    Fiber lkFiber
    __kFibers = New Fiber[ 0 ]
    
    
    ;; Create all the fibers and make sure they cast properly
    
    Int liIndex = 0
    While( liIndex < liFiberCount )
        
        ;; Creation and basic init of each Fiber
        lkFiber = __CreateFiber( akFiberClass, Self, Self, akSpawnMarker )
        If( lkFiber == None )
            ;; Like, zoinks!
            Debug.Trace( Self + " :: __CreateFibers() :: Could not create Fiber!" )
            _EmergencyDeleteFibers()
            Return False
        EndIf
        
        __kFibers.Add( lkFiber )
        liIndex += 1
    EndWhile
    
    
    ;; Store all the important information
    
    __kOnCompleteHandler    = akOnFiberCompleteHandler
    __sCustomCallbackID     = asCustomCallbackID
    __iCallbackID           = aiCallbackID
    __bWorkBackwards        = abWorkBackwards
    
    
    ;; Register the callback host for the FiberController OnFiberComplete
    If( akOnFiberCompleteHandler != None )
        akOnFiberCompleteHandler.RegisterForCustomEvent( Self, "OnFiberComplete" )
    EndIf
    
    
    ;;Debug.Trace( Self + " :: __CreateFibers() :: Complete" )
    Return True
EndFunction




Fiber Function __CreateFiber( \
    Activator       akFiberClass, \
    FiberController akController, \
    ScriptObject    akThreadRunCompleteHandler, \
    ObjectReference akSpawnMarker \
    ) Global
    ;;Debug.Trace( ____ScriptName() + " :: __CreateFiber()" )
    
    ;; Persistent, Disabled, Do not delete when able (it will delete itself as well as all the associated Fibers)
    ObjectReference lkFiberRef = akSpawnMarker.PlaceAtMe( akFiberClass, 1, True, True, False )
    If( lkFiberRef == None )
        Debug.Trace( ____ScriptName() + " :: __CreateFiber() :: Could not spawn the Fiber!" )
        Return None
    EndIf
    
    
    Fiber lkFiber = lkFiberRef As Fiber
    If( lkFiber == None )
        ;; This should never happen, but just in case...
        Debug.Trace( ____ScriptName() + " :: __CreateFiber() :: akFiberClass does not have the a Fiber extension script attached to it!\n\t" + akFiberClass )
        lkFiberRef.Delete()
        Return None
    EndIf
    
    
    If( akController != None )
        lkFiber.SetFiberController( akController )
    EndIf
    
    
    If( akThreadRunCompleteHandler != None )
        akThreadRunCompleteHandler.RegisterForCustomEvent( lkFiber, "ThreadRunComplete" )
    EndIf
    
    
    ;; If we made it this far, then all is good!
    Return lkFiber
EndFunction








;/
    ===========================================================
    
    Fiber results
    
    ===========================================================
/;


Bool                                __bResult = True
;; The result of the Fibers, any Fiber that encounters an error should call one of the _SetFiberFailed() functions

Int                                 __iChanged = 0
;; Number of items changed


Function _Increment()
    __iChanged += 1
EndFunction








Int                                 __iFailedOnIndex = -1
;; Only set if _SetFailedOnIndex() is called

ScriptObject                        __kFailedOnObject = None
;; Only set if _SetFailedOnScriptObject() is called




Function _SetFiberFailed( Bool abCancelFibers = True )
    ;; This should only be called by a Fiber when an error occurs
    ;; See the related Fiber functions.
    __bResult = False
    If( abCancelFibers )
        CancelFibers()
    EndIf
EndFunction


Function _SetFiberFailedOnIndex( Int aiIndex, Bool abCancelFibers = True )
    ;; This should only be called by a Fiber when an error occurs
    ;; See the related Fiber functions.
    __iFailedOnIndex = aiIndex
    __bResult = False
    If( abCancelFibers )
        CancelFibers()
    EndIf
EndFunction


Function _SetFiberFailedOnScriptObject( ScriptObject akObject , Bool abCancelFibers = True )
    ;; This should only be called by a Fiber when an error occurs
    ;; See the related Fiber functions.
    __kFailedOnObject = akObject
    __bResult = False
    If( abCancelFibers )
        CancelFibers()
    EndIf
EndFunction







Function CancelFibers()
    __bCancel = True
EndFunction








;/
    ===========================================================
    
    Thread events
    
    ===========================================================
/;


Event WorkshopFramework:Library:ObjectRefs:Thread.ThreadRunComplete( WorkshopFramework:Library:ObjectRefs:Thread akSender, Var[] akArgs )
    ;;Debug.Trace( Self + " :: WorkshopFramework:Library:ObjectRefs:Thread.ThreadRunComplete()" )
    
    Self.UnregisterForCustomEvent( akSender, "ThreadRunComplete" )
    
    Fiber lkFiber = akSender As Fiber
    If( lkFiber == None )
        Debug.Trace( Self + " :: WorkshopFramework:Library:ObjectRefs:Thread.ThreadRunComplete() :: akSender did not cast as a Fiber!\n\t" + akSender )
        Return
    EndIf
    
    __TryFinalize( lkFiber )
    
EndEvent








;/
    ===========================================================
    
    Finalize
    
    ===========================================================
/;


Function __TryFinalize( Fiber akFiber )
    ;;Debug.Trace( Self + " :: __TryFinalize()" )
    
    
    ;; Must synchronize as we may leave this object
    __BlockController()
    
    
    ;; Remove this Fiber from the FiberController
    Int liIndex = __kFibers.Find( akFiber )
    If( liIndex < 0 )
        Debug.Trace( Self + " :: __TryFinalize() :: akFiber is not in this Controller!\n\t" + akFiber )
    Else
        __kFibers.Remove( liIndex, 1 )
    EndIf
    
    
    ;; Not all Fibers complete, keep yer knickers on
    If( __kFibers.Length > 0 )
        ;; Destroy the Fiber
        akFiber.SelfDestruct()
        __bBlocked = False
        Return
    EndIf
    
    
    ;; Send the OnFiberComplete event
    __SendOnFiberComplete( akFiber )
    
    
    ;; Destroy the Fiber
    akFiber.SelfDestruct()
    
    
    ;; Delete the FiberController
    Self.Delete()
    
    __bBlocked = False
EndFunction






Function __SendOnFiberComplete( Fiber akFiber )
    ;;Debug.Trace( Self + " :: __SendOnFiberComplete()" )
    
    
    ;; Setup the OnFiberComplete event
    Var[] lkParams = New Var[ 0 ]
    lkParams.Add( __sCustomCallbackID )
    lkParams.Add( __iCallbackID )
    lkParams.Add( __bResult )
    lkParams.Add( __iChanged )
    lkParams.Add( __iWorkingSetSize )
    
    
    If( __bResult == False )
        lkParams.Add( __iFailedOnIndex )
        lkParams.Add( __kFailedOnObject )
    EndIf
    
    
    ;; Get the additional arguments from the Fiber
    ;; Remember listeners, you should use GetUserParams() to get the first index of the UserData parameters.
    ;; This function will do all the sanity checks for you;
    ;; A return value of -1 means no valid UserData;
    ;; A >= 0 value is the first index of the UserData (will actually be a 5 or a 7 at the time of writing this)
    akFiber.AddParamsToOnFiberCompleteArgs( lkParams )
    
    
    ;; Send the OnFiberComplete event
    SendCustomEvent( "OnFiberComplete", lkParams )
    
EndFunction








;/
    ===========================================================
    
    Data indexing
    
    ===========================================================
/;


Bool                                __bFirstIndexReturned = False
Int                                 __iDataIndex = -1
Bool                                __bWorkBackwards = False


;; Get the next index to process, any result < 0 means we're done (for whatever reason)
;; This function is atomic - which means that it never leaves this object and thus is automatically threadsafe
Int Function _NextIndex()
    
    If( __bCancel )
        Return -1
    EndIf
    If( __iWorkingSetSize < 1 )
        Return -1
    EndIf
    
    If( ! __bFirstIndexReturned )
        __bFirstIndexReturned = True
        
        If( __bWorkBackwards )
            __iDataIndex = __iWorkingSetSize - 1
        Else
            __iDataIndex = 0
        EndIf
        
    ElseIf( __bWorkBackwards )
        __iDataIndex -= 1
        If( __iDataIndex < 0 )
            Return -1
        EndIf
        
    Else
        __iDataIndex += 1
        If( __iDataIndex >= __iWorkingSetSize )
            Return -1
        EndIf
        
    EndIf
    
    Return __iDataIndex
EndFunction







