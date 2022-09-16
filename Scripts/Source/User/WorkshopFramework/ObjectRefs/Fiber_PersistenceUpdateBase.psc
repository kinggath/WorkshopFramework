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
    
    Keyword             Property    kKYWD_MustPersist                               Auto Const Mandatory
    { Core keyword on the base object forcing engine level persistence }
    
    Keyword             Property    kKYWD_DoNotPersist                              Auto Const Mandatory
    { Keyword on the base object to ignore persistence.
NOTE: If the base object has the MustPersist keyword, this is ignored }
    
EndGroup








;/
    ===========================================================
    
    Fiber Parameters
    
    ===========================================================
/;


;; Working parameters
WorkshopScript          Property    kWorkshop = None                                Auto Hidden


;; Global parameters
ActorValue[]                        kActorValues = None
Form[]                              kBaseObjects = None
FormList                            kKeywords = None

String                              sLogFile = ""




Function SetParameters( \
    WorkshopFramework:PersistenceManager \
                                    akManager, \
    WorkshopScript                  akWorkshop )
    
    ;; Working parameters
    kWorkshop                       = akWorkshop
    
    ;; Global paramaters
    kActorValues                    = akManager.Get_PersistReference_ActorValues()
    kBaseObjects                    = akManager.Get_PersistReference_BaseObjects()
    kKeywords                       = akManager.kFLST_PersistReference_Keywords
    
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
    
    kWorkshop           = None
    
    kActorValues        = None
    kBaseObjects        = None
    kKeywords           = None
    
    Parent.ReleaseObjectReferences()
EndFunction


Function AddParamsToOnFiberCompleteArgs( Var[] akParams )
    akParams.Add( kWorkshop )
EndFunction


;; Batch processing
Function ProcessIndex( Int aiIndex )
    
    ObjectReference lkREFR = GetObject( aiIndex )
    
    If( TryPersist( lkREFR ) )
        ;; Record the update
        Increment()
    EndIf
    
EndFunction


;; One-offs
Function ProcessFiber()
    TryPersist( GetObject( 0 ) )
EndFunction








;/
    ===========================================================
    
    Get the next object
    
    ===========================================================
/;


ObjectReference Function GetObject( Int aiIndex )
    Debug.TraceUser( WorkshopFramework:PersistenceManager.LogFile(), Self + " :: GetObject() :: NOT IMPLEMENTED!" )
    Return None
EndFunction








;/
    ===========================================================
    
    Try to persist the object
    
    ===========================================================
/;


Bool Function TryPersist( ObjectReference akREFR )
    
    If( akREFR == None )
        ;; Don't set an error, just ignore it
        Return False
    EndIf
    
    Bool lbIsPersisted = ( kAlias_PersistentObjects.Find( akREFR ) >= 0 )
    Bool lbNeedsPersistence = _ObjectNeedsPersistence( akREFR )
    
    Bool lbResult
    
    If( lbIsPersisted )&&( !lbNeedsPersistence )
        ;; Record change
        lbResult = True
        
        ;; Remove the Object from the Alias
        kAlias_PersistentObjects.RemoveRef( akREFR )
        
    ElseIf( !lbIsPersisted )&&( lbNeedsPersistence )
        ;; Record change
        lbResult = True
        
        ;; Add the Object to the Alias
        kAlias_PersistentObjects.AddRef( akREFR )
        
    EndIf
    
    Return lbResult
EndFunction








;/
    ===========================================================
    
    Object Persistence Criterion
    
    ===========================================================
/;


Bool Function __ObjectHasPersistenceActorValue( ObjectReference akREFR )
    
    Int liIndex = kActorValues.Length
    While( liIndex > 0 )
        liIndex -= 1
        
        If( akREFR.GetBaseValue( kActorValues[ liIndex ] ) != 0.0 )
            Return True
        EndIf
    EndWhile
    
    Return False
EndFunction


Bool Function __ObjectHasPersistenceKeyword( ObjectReference akREFR )
    Return( akREFR.HasKeywordInFormList( kKeywords ) )
EndFunction


Bool Function __BaseObjectRequiresPersistence( Form akBaseObject )
    Return( kBaseObjects.Find( akBaseObject ) >= 0 )
EndFunction




Bool Function _ObjectNeedsPersistence( ObjectReference akREFR )
    ;; Do fast fails...
    
    ;; Required slow test (native, latent) regardless of anything else
    If  ( akREFR.IsDeleted() )
        Return False
    EndIf

    Form lkBaseObject = akREFR.GetBaseObject()

    ;; Engine level forced persistence
    If( lkBaseObject.HasKeyword( kKYWD_MustPersist ) )
        Return True
    EndIf

    ;; Our override to prevent non-engine forced persistence
    If( lkBaseObject.HasKeyword( kKYWD_DoNotPersist ) )
        Return False
    EndIf
    
    ;; Super fast test for WorkshopObjectScript
    WorkshopObjectScript lkWSObject = akREFR As WorkshopObjectScript
    If( lkWSObject != None )
        Return True
    EndIf
    
    ;; "Quick" test (native) for having one of the Actor Values
    If( __ObjectHasPersistenceActorValue( akREFR ) )
        Return True
    EndIf
    
    ;; Slow test (native, latent) for having one of the keywords
    If( __ObjectHasPersistenceKeyword( akREFR ) )
        Return True
    EndIf
    
    ;; Slow test (native, latent) for being one of the Base Forms
    If( __BaseObjectRequiresPersistence( lkBaseObject ) )
        Return True
    EndIf
    
    Return False
EndFunction







