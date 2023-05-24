ScriptName WorkshopFramework:ObjectRefs:Fiber_PersistenceUpdateBase Extends WorkshopFramework:Library:ObjectRefs:Fiber
{
    Forced persistence scanning thread
}
String Function ____ScriptName() Global
    Return "WorkshopFramework:ObjectRefs:Fiber_PersistenceUpdateBase"
EndFunction








;/
    ===========================================================
    
    Editor set properties
    
    ===========================================================
/;


Group ImportantStuff

    RefCollectionAlias  Property    kAlias_PersistentObjects                        Auto Const Mandatory
    { This holds and forces all the objects to persist }
    
    ObjectReference     Property    kREFR_PersistentObjects                         Auto Hidden
    { This shadows the above alias, it is used for rapid access as an array using GetLinkedRefChildren }
    
    Keyword             Property    kKYWD_PersistentObject                          Auto Hidden
    { This is used to link the persisted objects to the linked ref holder }
    
    Keyword             Property    kKYWD_MustPersist                               Auto Const Mandatory
    { Core keyword on the base object forcing engine level persistence.
NOTE: MustPersist supercedes DoNotPersist }
    
    Keyword             Property    kKYWD_DoNotPersist                              Auto Const Mandatory
    { Keyword on the base object to ignore persistence.
NOTE: MustPersist supercedes DoNotPersist }
    
    Keyword             Property    kKYWD_WorkshopItemKeyword                       Auto Const Mandatory
    { Fallout 4 keyword linking objects to workshops }
    
    GlobalVariable      Property    kGLOB_EnablePersistenceManagement               Auto Const Mandatory
    { Depending on the platform, persistence management may need to be disabled to save memory }

EndGroup








;/
    ===========================================================
    
    Fiber Parameters
    
    ===========================================================
/;


;; Working parameters
WorkshopFramework:PersistenceManager \
                        Property    kManager = None                                 Auto Hidden

WorkshopScript          Property    kWorkshop = None                                Auto Hidden


;; Global parameters
ActorValue[]                        kActorValues = None
Form[]                              kBaseObjects = None
FormList                            kKeywords = None




Function SetParameters( \
    WorkshopFramework:PersistenceManager \
                                    akManager, \
    WorkshopScript                  akWorkshop )
    
    ;; Working parameters
    kManager                        = akManager
    kWorkshop                       = akWorkshop
    
    ;; Global paramaters
    kActorValues                    = akManager.Get_PersistReference_ActorValues()
    kBaseObjects                    = akManager.Get_PersistReference_BaseObjects()
    kKeywords                       = akManager.kFLST_PersistReference_Keywords
    
    kREFR_PersistentObjects         = akManager.kREFR_PersistentObjects
    kKYWD_PersistentObject          = akManager.kKYWD_PersistentObject
    
EndFunction








;/
    ===========================================================
    
    Implemented Overrides and Abstracts
    
    ===========================================================
/;


WorkshopFramework:Library:ObjectRefs:FiberController Function _CreateFiberController( \
    Activator           akFiberClass, \
    WorkshopScript      akWorkshop, \
    Int                 aiCount, \
    Bool                abWorkBackwards = False, \
    ScriptObject        akOnFiberCompleteHandler = None, \
    Int                 aiCallbackID = 0 \
    ) Global
    
    
    If( akFiberClass == None )
        Debug.TraceUser( WorkshopFramework:PersistenceManager.LogFile(), ____ScriptName() + " :: _CreateFiberController() :: akFiberClass is None" )
        Return None
    EndIf
    
    
    If( aiCount == 0 )
        Debug.TraceUser( WorkshopFramework:PersistenceManager.LogFile(), ____ScriptName() + " :: _CreateFiberController() :: Nothing to process" )
        Return None
    EndIf
    
    
    WorkshopFramework:Library:ObjectRefs:FiberController lkController = \
        WorkshopFramework:Library:ObjectRefs:FiberController.Create( \
            akFiberClass, \
            aiCount, \
            akOnFiberCompleteHandler = akOnFiberCompleteHandler, \
            aiCallbackID = aiCallbackID )
    If( lkController == None )
        Debug.TraceUser( WorkshopFramework:PersistenceManager.LogFile(), ____ScriptName() + " :: _CreateFiberController() :: An error occured in FiberController.Create()" )
        Return None
    EndIf
    
    
    WorkshopFramework:PersistenceManager lkManager = WorkshopFramework:PersistenceManager.GetManager()
    WorkshopFramework:ObjectRefs:Fiber_PersistenceUpdateBase lkFiber
    Int liFiberCount = lkController.iTotalFibers
    Int liIndex = 0
    While( liIndex < liFiberCount )
        
        lkFiber = lkController.GetFiber( liIndex ) As WorkshopFramework:ObjectRefs:Fiber_PersistenceUpdateBase
        If( lkFiber != None )
            
            lkFiber.SetParameters( lkManager, akWorkshop )
            
        Else
            Debug.TraceUser( WorkshopFramework:PersistenceManager.LogFile(), ____ScriptName() + " :: _CreateFiberController() :: Fibers created did not cast as the proper Fiber class!" )
            lkController.Delete() ;; <--- This will also delete the Fibers
            Return None
        EndIf
        
        liIndex += 1
    EndWhile
    
    
    ;; Return the Controller
    Return lkController
EndFunction








;/
    ===========================================================
    
    WSFW Fiber
    
    ===========================================================
/;


Function ReleaseObjectReferences()
    
    kManager                        = None
    kWorkshop                       = None
    
    kActorValues                    = None
    kBaseObjects                    = None
    kKeywords                       = None
    
    kREFR_PersistentObjects         = None
    kKYWD_PersistentObject          = None
    
    Parent.ReleaseObjectReferences()
EndFunction


Bool Function TerminateNow()
    ;; Player has turned off Persistence Management, abort the Fibers
    Return ( kGLOB_EnablePersistenceManagement.GetValueInt() == 0 )
EndFunction


Function AddParamsToOnFiberCompleteArgs( Var[] akParams )
    akParams.Add( kWorkshop )
EndFunction


;; Batch processing
Function ProcessIndex( Int aiIndex )
    
    ObjectReference lkREFR = _GetObject( aiIndex )
    
    If( _TryPersist( lkREFR ) )
        ;; Record the update
        Increment()
    EndIf
    
EndFunction


;; One-offs
Function ProcessFiber()
    _TryPersist( _GetObject( 0 ) )
EndFunction








;/
    ===========================================================
    
    Get the next object
    
    ===========================================================
/;


ObjectReference Function _GetObject( Int aiIndex )
    Debug.TraceUser( WorkshopFramework:PersistenceManager.LogFile(), Self + " :: _GetObject() :: NOT IMPLEMENTED!" )
    Return None
EndFunction








;/
    ===========================================================
    
    Try to persist the object
    
    ===========================================================
/;


Bool Function _TryPersist( ObjectReference akREFR )
    
    If( akREFR == None )
        ;; Don't set an error, just ignore it
        Return False
    EndIf
    
    ;; Current state
    Bool lbIsPersisted = ( kAlias_PersistentObjects.Find( akREFR ) >= 0 )
    
    ;; Desired state
    Bool lbNeedsPersistence = _ObjectNeedsPersistence( akREFR )
    
    ;; No change made
    Bool lbResult = False
    
    If( lbIsPersisted )&&( !lbNeedsPersistence )
        ;; Record change
        lbResult = True
        
        ;; Remove the Object from the Alias
        _UnpersistObject( akREFR, kWorkshop )
        
    ElseIf( !lbIsPersisted )&&( lbNeedsPersistence )
        ;; Record change
        lbResult = True
        
        ;; Add the Object to the Alias
        _PersistObject( akREFR, kWorkshop )
        
    EndIf
    
    Return lbResult
EndFunction


Function _PersistObject( ObjectReference akREFR, WorkshopScript akWorkshop = None )
    ;;If( akWorkshop == None )
    ;;    akWorkshop = akREFR.GetLinkedRef( kKYWD_WorkshopItemKeyword ) As WorkshopScript
    ;;EndIf
    kAlias_PersistentObjects.AddRef( akREFR )
    akREFR.SetLinkedRef( kREFR_PersistentObjects, kKYWD_PersistentObject )
EndFunction


Function _UnpersistObject( ObjectReference akREFR, WorkshopScript akWorkshop = None )
    ;;If( akWorkshop == None )
    ;;    akWorkshop = akREFR.GetLinkedRef( kKYWD_WorkshopItemKeyword ) As WorkshopScript
    ;;EndIf
    kAlias_PersistentObjects.RemoveRef( akREFR )
    akREFR.SetLinkedRef( None, kKYWD_PersistentObject )
EndFunction








;/
    ===========================================================
    
    Object Persistence Criterion
    
    ===========================================================
/;


Bool Function _ObjectHasPersistenceActorValue( ObjectReference akREFR )
    
    Int liIndex = kActorValues.Length
    While( liIndex > 0 )
        liIndex -= 1
        
        ;; Compare the value on the target REFR with the value on the Fiber
        ;; The Fiber has no AVIFs so it will return the default value
        ;; This will handle non-zero default AVIFs
        ActorValue lkAVIF = kActorValues[ liIndex ]
        If( akREFR.GetBaseValue( lkAVIF ) != Self.GetBaseValue( lkAVIF ) )
            Return True
        EndIf
    EndWhile
    
    Return False
EndFunction


Bool Function _ObjectHasPersistenceKeyword( ObjectReference akREFR )
    Return( akREFR.HasKeywordInFormList( kKeywords ) )
EndFunction


Bool Function _BaseObjectRequiresPersistence( Form akBaseObject )
    Return( kBaseObjects.Find( akBaseObject ) >= 0 )
EndFunction




;; He's not heavy, he's really heavy
Bool Function _ObjectNeedsPersistence( ObjectReference akREFR )
    ;; Do fast fails...
    
    ;; Required test (native remote call) regardless of anything else
    If  ( akREFR.IsDeleted() )
        Return False
    EndIf

    ;; Some check are against the base object
    Form lkBaseObject = akREFR.GetBaseObject()

    ;; Engine level forced persistence
    If( lkBaseObject.HasKeyword( kKYWD_MustPersist ) )\
    ||( akREFR.HasKeyword( kKYWD_MustPersist ) )
        Return True
    EndIf

    ;; Our override to prevent non-engine forced persistence
    If( lkBaseObject.HasKeyword( kKYWD_DoNotPersist ) )\
    ||( akREFR.HasKeyword( kKYWD_DoNotPersist ) )
        Return False
    EndIf
    
    ;; Super fast test for WorkshopObjectScript
    WorkshopObjectScript lkWSObject = akREFR As WorkshopObjectScript
    If( lkWSObject != None )
        Return True
    EndIf
    
    ;; Fast test the base object being in the array
    If( _BaseObjectRequiresPersistence( lkBaseObject ) )
        Return True
    EndIf
    
    ;; Quick test (one native remote call) for having one of the keywords
    If( _ObjectHasPersistenceKeyword( akREFR ) )
        Return True
    EndIf
    
    ;; Slow test (multiple native remote calls) for having any of the Actor Values
    If( _ObjectHasPersistenceActorValue( akREFR ) )
        Return True
    EndIf
    
    ;; After all that, we don't need to be persisted
    Return False
EndFunction







