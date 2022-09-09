ScriptName WorkshopFramework:ObjectRefs:Fiber_PersistenceUpdateQueue Extends WorkshopFramework:ObjectRefs:Fiber_PersistenceUpdateBase
{
    Forced persistence scanning Fiber
}
String Function __ScriptName() Global
    Return "WorkshopFramework:ObjectRefs:Fiber_PersistenceUpdateQueue"
EndFunction
Activator Function GetFiberBaseObject() Global
    ;; TODO:  REPLACE WITH PROPER FORMID ONCE INTEGRATED!
    ;;Return Game.GetFormFromFile( 0x00??????, "WorkshopFramework.esm" ) As Activator
    Return Game.GetFormFromFile( 0x00001740, "WorkshopFramework_PersistenceOverhaul.esp" ) As Activator
EndFunction








;/
    ===========================================================
    
    Fiber Parameters
    
    ===========================================================
/;


;; Working parameters
RefCollectionAlias      Property    kQueue = None                                   Auto Hidden








;/
    ===========================================================
    
    Implemented Overrides and Abstracts
    
    ===========================================================
/;


WorkshopFramework:Library:ObjectRefs:FiberController Function CreateFiberController( \
    WorkshopScript      akWorkshop, \
    RefCollectionAlias  akQueue, \
    Bool                abRegisterManagerCallback \
    ) Global
    
    
    If( akQueue == None )
        Debug.TraceUser( WorkshopFramework:PersistenceManager.LogFile(), __ScriptName() + " :: CreateFiberController() :: akQueue is None" )
        Return None
    EndIf
    
    
    Int liCount = akQueue.GetCount()
    If( liCount == 0 )
        Debug.TraceUser( WorkshopFramework:PersistenceManager.LogFile(), __ScriptName() + " :: CreateFiberController() :: akQueue is Empty" )
        Return None
    EndIf
    
    
    ScriptObject    lkOnFiberCompleteHandler = None
    Int             liCallbackID = 0
    If( abRegisterManagerCallback )
        WorkshopFramework:PersistenceManager lkManager = WorkshopFramework:PersistenceManager.GetManager()
        lkOnFiberCompleteHandler = lkManager
        liCallbackID = lkManager.iFiberID_PersistenceScanQueue
    EndIf
    
    
    WorkshopFramework:Library:ObjectRefs:FiberController lkController = WorkshopFramework:ObjectRefs:Fiber_PersistenceUpdateBase._CreateFiberController( \
        GetFiberBaseObject(), \
        akWorkshop, \
        liCount, \
        akOnFiberCompleteHandler = lkOnFiberCompleteHandler, \
        aiCallbackID = liCallbackID )
    
    If( lkController != None )
        
        WorkshopFramework:ObjectRefs:Fiber_PersistenceUpdateQueue lkFiber
        Int liFiberCount = lkController.iTotalFibers
        Int liIndex = 0
        While( liIndex < liFiberCount )
            
            lkFiber = lkController.GetFiber( liIndex ) As WorkshopFramework:ObjectRefs:Fiber_PersistenceUpdateQueue
            If( lkFiber != None )
                
                lkFiber.kQueue = akQueue
                
            Else
                Debug.TraceUser( WorkshopFramework:PersistenceManager.LogFile(), __ScriptName() + " :: CreateFiberController() :: Fibers created did not cast as the proper Fiber class!" )
                lkController.Delete() ;; <--- This will also delete the Fibers
                Return None
            EndIf
            
            liIndex += 1
        EndWhile
        
    EndIf
    
    Return lkController
EndFunction








;/
    ===========================================================
    
    WSFW Fiber
    
    ===========================================================
/;


Function ReleaseObjectReferences()
    
    kQueue              = None
    
    Parent.ReleaseObjectReferences()
EndFunction








;/
    ===========================================================
    
    Get the next object from the Queue
    
    ===========================================================
/;


ObjectReference Function GetObject( Int aiIndex )
    Return kQueue.GetAt( aiIndex )
EndFunction







