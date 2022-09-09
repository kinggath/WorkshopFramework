ScriptName WorkshopFramework:ObjectRefs:Fiber_PersistenceRemoveDeletedObjects Extends WorkshopFramework:Library:ObjectRefs:Fiber
{
    Clean deleted objects from the Persistence Manager
}
String Function __ScriptName() Global
    Return "WorkshopFramework:ObjectRefs:Fiber_PersistenceRemoveDeletedObjects"
EndFunction
Activator Function GetFiberBaseObject() Global
    ;; TODO:  REPLACE WITH PROPER FORMID ONCE INTEGRATED!
    ;;Return Game.GetFormFromFile( 0x00??????, "WorkshopFramework.esm" ) As Activator
    Return Game.GetFormFromFile( 0x0000173D, "WorkshopFramework_PersistenceOverhaul.esp" ) As Activator
EndFunction








;/
    ===========================================================
    
    Editor set properties
    
    ===========================================================
/;


Group PersistenceAlias

    RefCollectionAlias  Property    kAlias_PersistentObjects                        Auto Const Mandatory
    { This holds and forces all the objects to persist }
    
EndGroup








;/
    ===========================================================
    
    Abstract Functions
    
    These MUST be implemented by child classes.
    
    Change 'Datum' to the specific struct for the child class in
    the parameter lists.
    
    ===========================================================
/;


WorkshopFramework:Library:ObjectRefs:FiberController Function CreateFiberController( \
    Bool                abRegisterManagerCallback \
    ) Global
    
    
    WorkshopFramework:PersistenceManager lkManager = WorkshopFramework:PersistenceManager.GetManager()
    
    
    Int liCount = lkManager.kAlias_PersistentObjects.GetCount()
    If( liCount == 0 )
        Debug.TraceUser( WorkshopFramework:PersistenceManager.LogFile(), __ScriptName() + " :: CreateFiberController() :: No Work" )
        Return None
    EndIf
    
    
    ScriptObject lkCallbackHandler = None
    Int liCallbackID = 0
    
    If( abRegisterManagerCallback )
        lkCallbackHandler = lkManager
        liCallbackID = lkManager.iFiberID_CleanDeadPersistentObjects
    EndIf
    
    
    WorkshopFramework:Library:ObjectRefs:FiberController lkController = \
        WorkshopFramework:Library:ObjectRefs:FiberController.Create( \
            GetFiberBaseObject(), \
            liCount, \
            akOnFiberCompleteHandler = lkCallbackHandler, \
            aiCallbackID = liCallbackID, \
            abWorkBackwards = True )    ;; Work backwards through the RefCollectionAlias as we may be removing Objects
    If( lkController == None )
        Debug.TraceUser( WorkshopFramework:PersistenceManager.LogFile(), __ScriptName() + " :: CreateFiberController() :: An error occured in FiberController.Create()" )
        Return None
    EndIf
    
    
    ;; Return the Controller
    Return lkController
EndFunction








;/
    ===========================================================
    
    WSFW Fiber
    
    ===========================================================
/;


;; Batch processing
Function ProcessIndex( Int aiIndex )
    
    ObjectReference lkREFR = kAlias_PersistentObjects.GetAt( aiIndex )
    
    If( lkREFR == None )
        ;; Just exit, no error
        Return
    EndIf
        
    If( lkREFR.IsDeleted() )
        
        ;; Remove the Object to the Alias
        kAlias_PersistentObjects.RemoveRef( lkREFR )
        
        ;; Record number of changes
        Increment()
    EndIf
    
EndFunction







