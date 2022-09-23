ScriptName WorkshopFramework:ObjectRefs:Fiber_PersistenceUpdateObjects Extends WorkshopFramework:ObjectRefs:Fiber_PersistenceUpdateBase
{
    Forced persistence scanning Fiber
}
String Function __ScriptName() Global
    Return "WorkshopFramework:ObjectRefs:Fiber_PersistenceUpdateObjects"
EndFunction
Activator Function GetFiberBaseObject() Global
    ; Get the base object form this script is on
    Return Game.GetFormFromFile( 0x00006417, "WorkshopFramework.esm" ) As Activator
EndFunction








;/
    ===========================================================
    
    Fiber Parameters
    
    ===========================================================
/;


;; Working parameters
ObjectReference[]       Property    kObjects = None                                 Auto Hidden








;/
    ===========================================================
    
    Implemented Overrides and Abstracts
    
    ===========================================================
/;


WorkshopFramework:Library:ObjectRefs:FiberController Function CreateFiberController( \
    WorkshopScript      akWorkshop, \
    ObjectReference[]   akObjects, \
    Bool                abRegisterManagerCallback \
    ) Global
    
    
    Int liCount = akObjects.Length
    If( liCount == 0 )
        Debug.TraceUser( WorkshopFramework:PersistenceManager.LogFile(), __ScriptName() + " :: CreateFiberController() :: akObjects is None or Empty" )
        Return None
    EndIf
    
    
    ScriptObject    lkOnFiberCompleteHandler = None
    Int             liCallbackID = 0
    If( abRegisterManagerCallback )
        WorkshopFramework:PersistenceManager lkManager = WorkshopFramework:PersistenceManager.GetManager()
        lkOnFiberCompleteHandler = lkManager
        liCallbackID = lkManager.iFiberID_PersistenceScanObjects
    EndIf
    
    
    WorkshopFramework:Library:ObjectRefs:FiberController lkController = WorkshopFramework:ObjectRefs:Fiber_PersistenceUpdateBase._CreateFiberController( \
        GetFiberBaseObject(), \
        akWorkshop, \
        liCount, \
        akOnFiberCompleteHandler = lkOnFiberCompleteHandler, \
        aiCallbackID = liCallbackID )
    
    If( lkController != None )
        
        WorkshopFramework:ObjectRefs:Fiber_PersistenceUpdateObjects lkFiber
        Int liFiberCount = lkController.iTotalFibers
        Int liIndex = 0
        While( liIndex < liFiberCount )
            
            lkFiber = lkController.GetFiber( liIndex ) As WorkshopFramework:ObjectRefs:Fiber_PersistenceUpdateObjects
            If( lkFiber != None )
                
                lkFiber.kObjects = akObjects
                
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
    
    kObjects            = None
    
    Parent.ReleaseObjectReferences()
EndFunction








;/
    ===========================================================
    
    Get the next object from the Array
    
    ===========================================================
/;


ObjectReference Function _GetObject( Int aiIndex )
    Return kObjects[ aiIndex ]
EndFunction







