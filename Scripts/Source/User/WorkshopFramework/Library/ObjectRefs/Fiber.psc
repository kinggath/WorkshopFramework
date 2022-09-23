ScriptName WorkshopFramework:Library:ObjectRefs:Fiber Extends WorkshopFramework:Library:ObjectRefs:Thread
{
    Fiber or "swarm thread" - These are not "true" Fibers; they are, indeed, Threads.
    Extend this, implement the "Abstract" section at the bottom.
    
    Note:  Fibers can be used as a separate Thread on it's own as a "one-off" but will
    be less efficient than when used for batch processing.  RunCode() will call
    ProcessFiber() or ProcessIndex() depending on whether SetFiberController() was
    called with a valid FiberController.  Regardless, the Fibers parameters must be
    set before queuing the Fiber either by FiberController.QueueFibers() or
    ThreadManager.QueueThread().
}




Import WorkshopFramework:Library:ObjectRefs








;/
    ===========================================================
    
    Internal management
    
    ===========================================================
/;


FiberController                     __kController = None


Function SetFiberController( FiberController akController )
    
    __kController = akController
    
    If( akController != None )
        ;; The FiberController will manage the Fiber and delete it
        bAutoDestroy = False
    EndIf
        
EndFunction


Int Function __NextIndex()
    If( __kController == None )\
    ||( TerminateNow() )
        Return -1
    EndIf
    Return __kController._NextIndex()
EndFunction








;/
    ===========================================================
    
    Fiber results
    
    Any Fiber that encounters an error in it's ProcessIndex()
    should call SetFiberFailed() if the error is fatal or
    otherwise should be reported to the user code.
    
    Increment() is entire optional, it all depends on if you
    care about how many items were changed.
    
    Note:
    
    These functions are only valid when a FiberController is set.
    
    ===========================================================
/;


Function Increment()
    If( __kController == None )
        Return
    EndIf
    __kController._Increment()
EndFunction



Function SetFiberFailed( Bool abCancelFibers = True )
    If( __kController == None )
        Return
    EndIf
    __kController._SetFiberFailed( abCancelFibers )
EndFunction


Function SetFiberFailedOnIndex( Int aiIndex, Bool abCancelFibers = True  )
    If( __kController == None )
        Return
    EndIf
    __kController._SetFiberFailedOnIndex( aiIndex, abCancelFibers )
EndFunction


Function SetFiberFailedOnScriptObject( ScriptObject akObject , Bool abCancelFibers = True )
    If( __kController == None )
        Return
    EndIf
    __kController._SetFiberFailedOnScriptObject( akObject, abCancelFibers )
EndFunction








;/
    ===========================================================
    
    Thread loop
    
    Do NOT override this section, see the "Abstract" section below
    
    ===========================================================
/;


Function RunCode()
    
    If( __kController == None )
        ProcessFiber()
        
    Else
        
        Int liIndex = __NextIndex()
        While( liIndex >= 0 )
            ProcessIndex( liIndex )
            liIndex = __NextIndex()
        EndWhile
        
    EndIf
    
EndFunction








;/
    ===========================================================
    
    Abstract (required) and Override (some required) Functions
    
    Override and implement these as needed and directed.

    ===========================================================
/;




;; >>>>>>>> Fiber Management <<<<<<<<




;; OVERRIDE - Object function
;; If you override this function be sure to call Parent.ReleaseObjectReferences() to release the __kController reference.
Function ReleaseObjectReferences()
    __kController       = None
    Parent.ReleaseObjectReferences()
EndFunction




;; OVERRIDE - Object function
;; __NextIndex() will call this and if it returns True, all Thread loops will be terminated and no further calls to ProcessIndex() will be made.
;; While similar, it is different from cancelling the Fibers which has to be done via the FiberController or setting an error in a Fiber.
;; This is typically used as an external control check for a global setting (such as an MCM setting).
Bool Function TerminateNow()
    Return False
EndFunction




;; OVERRIDE - Object function
;; See: FiberController OnFiberComplete custom event definition at top of file.
;; This will be called on the last Fiber to complete before SelfDestruct() is called on it.
Function AddParamsToOnFiberCompleteArgs( Var[] akParams )
EndFunction




;; >>>>>>>> Fiber Processing <<<<<<<<




;; OVERRIDE - Object function
;; Process this index item in the working data set.
;; This is the Fibers workhorse, RunCode() calls this in it's inner loop.
;;
;; Notes:
;;  aiIndex will never be invalid unless aiWorkingSetSize did not match
;;  the actual data set size when FiberController.Create() was called.
Function ProcessIndex( Int aiIndex )
    Debug.Trace( Self + " :: ProcessIndex() :: NOT IMPLEMENTED!" )
    SetFiberFailed()
EndFunction




;; OVERRIDE - Object function
;; Process this Fiber, the Fibers parameters still must be set even though the FiberController is not.
Function ProcessFiber()
    Debug.Trace( Self + " :: ProcessFiber() :: NOT IMPLEMENTED!" )
EndFunction




;; >>>>>>>> Fiber Creation <<<<<<<<




;; ABSTRACT - Static function
;; FiberController creation function used by user code to create the Swarm
;; Notes:
;;  This function will internally call FiberController.Create()
;;  which will in-turn, create the Fibers, set their FiberController
;;  and prepare them to be used.  It is up to this function to set the Fiber
;;  specific parameters for batch operation.
;/
FiberController Function CreateFiberController( ??? ) Global
    
    ;; Sanity check parameters
    
    If( ??? )
        Debug.Trace( "myFiberClass :: CreateFiberController() :: Parameter error on ???" )
        Return None
    EndIf
    
    
    ;; Create the Controller
    FiberController lkController = \
        FiberController.Create( \
            ...
        )
    If( lkController == None )
        Debug.Trace( "myFiberClass :: CreateFiberController() :: An error occured in FiberController.Create()" )
        Return None
    EndIf
    
    
    ;; Set the parameters on the Fibers
    
    myFiberClass lkFiber
    Int liFiberCount = lkController.iTotalFibers
    Int liIndex = 0
    While( liIndex < liFiberCount )
        
        lkFiber = lkController.GetFiber( liIndex ) As myFiberClass
        If( lkFiber != None )
            
            ;; Either
            lkFiber.myParameter = foo
            ...
            
            ;; Or (where "SetParameters" is a child class function with specific arguments)
            lkFiber.SetParameters( foo, ... )
            
        Else
            Debug.Trace( "myFiberClass :: CreateFiberController() :: Fibers created did not cast as the proper Fiber class!" )
            lkController.Delete() ;; <--- This will also delete the Fibers
            Return None
        EndIf
        
        liIndex += 1
    EndWhile
    
    
    ;; Return the Controller
    Return lkController
EndFunction
/;






;; ABSTRACT - Static function
;; Fiber creation function used by user code to create a single one-off Fiber
;; Notes:
;;  This function can internally call FiberController.CreateFiber() to do the
;;  grunt work.  It is up to this function to set the Fibers specific parameters
;;  for operation.
;/
myFiberClass Function CreateFiber( ??? ) Global
    
    ;; Sanity check parameters
    
    If( ??? )
        Debug.Trace( "myFiberClass :: CreateFiber() :: Parameter error on ???" )
        Return None
    EndIf
    
    
    ;; Create the Fiber
    Fiber lkFiberBase = \
        FiberController.CreateFiber( \
            ...
        )
    If( lkFiberBase == None )
        Debug.Trace( "myFiberClass :: CreateFiber() :: An error occured in FiberController.CreateFiber()" )
        Return None
    EndIf
    
    
    ;; Set the parameters on the Fibers
    
    myFiberClass lkFiber = lkFiberBase As myFiberClass
    If( lkFiber != None )
        
        ;; Either
        lkFiber.myParameter = foo
        ...
        
        ;; Or (where "SetParameters" is a child class function with specific arguments)
        lkFiber.SetParameters( foo, ... )
        
    Else
        Debug.Trace( "myFiberClass :: CreateFiber() :: Fiber created did not cast as the proper Fiber class!" )
        lkFiber.SelfDestruct()
        Return None
    EndIf
    
    
    ;; Return the Fiber
    Return lkFiber
EndFunction
/;







