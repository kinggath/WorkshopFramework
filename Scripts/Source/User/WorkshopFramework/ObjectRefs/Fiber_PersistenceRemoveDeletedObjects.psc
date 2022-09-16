ScriptName WorkshopFramework:ObjectRefs:Fiber_PersistenceRemoveDeletedObjects Extends WorkshopFramework:ObjectRefs:Fiber_PersistenceUpdateBase
{
    Clean deleted objects from the Persistence Manager
}
String Function __ScriptName() Global
    Return "WorkshopFramework:ObjectRefs:Fiber_PersistenceRemoveDeletedObjects"
EndFunction
Activator Function GetFiberBaseObject() Global
    ; Get the base object form this script is on
    Return Game.GetFormFromFile( 0x00006416, "WorkshopFramework.esm" ) As Activator
EndFunction








;/
    ===========================================================
    
    Implemented Overrides and Abstracts
    
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
    
    
    ;; Work backwards through the RefCollectionAlias as we may be removing Objects
    WorkshopFramework:Library:ObjectRefs:FiberController lkController = WorkshopFramework:ObjectRefs:Fiber_PersistenceUpdateBase._CreateFiberController( \
        GetFiberBaseObject(), \
        None, \
        liCount, \
        abWorkBackwards = True, \
        akOnFiberCompleteHandler = lkCallbackHandler, \
        aiCallbackID = liCallbackID )
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
    
    If( !_ObjectNeedsPersistence( lkREFR ) )
        
        ;; Remove the Object from the Alias
        kAlias_PersistentObjects.RemoveRef( lkREFR )
        
        ;; Record the change
        Increment()

    EndIf
    
EndFunction







