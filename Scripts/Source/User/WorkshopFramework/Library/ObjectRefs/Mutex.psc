ScriptName WorkshopFramework:Library:ObjectRefs:Mutex Extends ObjectReference
{
    A simple spin lock.
    
    How is this different from a "built-in" spin lock?  This keeps the spinning
    off the locked object so it is not constantly interrupted while it works.
    
    The benefits of this become greater and greater the more threads that are
    spinning, waiting for the lock to release.  That is, the thread holding the
    lock is interrupted less and can process faster.
}
Activator Function GetMutexBaseObject() Global
    ;; TODO:  REPLACE WITH PROPER FORMID ONCE INTEGRATED!
    ;;Return Game.GetFormFromFile( 0x00??????, "WorkshopFramework.esm" ) As Activator
    Return Game.GetFormFromFile( 0x00000FA3, "WorkshopFramework_PersistenceOverhaul.esp" ) As Activator
EndFunction








;/
    ===========================================================
    
    Lock Properties
    
    ===========================================================
/;

Bool                                __bDeleted = False

Bool                                __bHeld  = False
Int                                 __iLockCount = 0                                ;; How many threads are spinning

Int                     Property    iMaxLockCountBeforeFlush = 100                  Auto
{ Thread limit before forcing the lock free }

Int                     Property    iMaxSpinCount = 100                             Auto
{ Max spin attempts before failing to get the lock }

Float                   Property    fMinSpinInterval = 0.125                        Auto
{ 1/8s - Minimum spin time }

Float                   Property    fMaxSpinInterval = 0.875                        Auto
{ 7/8s - Maximum spin time }

Bool                    Property    bMenuMode = True                                Auto
{ Spin while menus are displayed }








;/
    ===========================================================
    
    Dynamic Lock API
    
    ===========================================================
/;


Mutex Function Create() Global
    
    ObjectReference lkSpawnMarker = Game.GetFormFromFile( 0x00004CEA, "WorkshopFramework.esm" ) As ObjectReference
    If( lkSpawnMarker == None )
        Debug.Trace( "WorkshopFramework:Library:ObjectRefs:Mutex :: Create() :: Could not get the spawn marker for the Mutex!" )
        Return None
    EndIf
    
    ;; Persistent, Disabled, Do not delete when able
    ObjectReference lkLockRef = lkSpawnMarker.PlaceAtMe( GetMutexBaseObject(), 1, True, True, False )
    If( lkLockRef == None )
        Debug.Trace( "WorkshopFramework:Library:ObjectRefs:Mutex :: Create() :: Could not spawn a Mutex Activator!" )
        Return None
    EndIf
    
    Mutex lkLock = lkLockRef As Mutex
    
    If( lkLock == None )
        ;; This should never happen, but just in case...
        Debug.Trace( "WorkshopFramework:Library:ObjectRefs:Mutex :: Create() :: Spawned object did not cast as WorkshopFramework:Library:ObjectRefs:Mutex!" )
        lkLockRef.Delete()
        Return None
    EndIf
    
    Return lkLock
EndFunction


Function Delete()
    __bDeleted = True
    __bHeld = False
    __iLockCount = 0
    Parent.Delete()
EndFunction








;/
    ===========================================================
    
    Public API
    
    ===========================================================
/;


Bool Function IsHeld()
    Return __bHeld
EndFunction


Bool Function GetLock()
    If( __bDeleted )
        Debug.Trace( "WorkshopFramework:Library:ObjectRefs:Mutex :: GetLock() :: Cannot get lock!  Mutex has been deleted!" )
        Return False
    EndIf
    
    __iLockCount += 1
    If( __iLockCount < iMaxLockCountBeforeFlush )
        ;; Allow more threads to queue, there should never be that many!
        
        Int liSpinCount = 0
        While( !__bDeleted )&&( __bHeld )&&( liSpinCount < iMaxSpinCount )
            liSpinCount += 1
            Float lfInterval = Utility.RandomFloat( fMinSpinInterval, fMaxSpinInterval )
            If( bMenuMode )
                Utility.WaitMenuMode( lfInterval )
            Else
                Utility.Wait( lfInterval )
            EndIf
        EndWhile
        
        If( __bDeleted )
            Debug.Trace( "WorkshopFramework:Library:ObjectRefs:Mutex :: GetLock() :: Cannot get lock!  Mutex has been deleted!" )
            Return False
        EndIf
        
        ;; Lock is still held, that means we spun out
        If( __bHeld )
            __iLockCount -= 1
            Debug.Trace( "WorkshopFramework:Library:ObjectRefs:Mutex :: GetLock() :: Cannot get lock!  Mutex has been spinning for too long!" )
            Return False
        EndIf
        
    EndIf
    
    ;; Aquire lock and return true
    __bHeld = True
    Return True
EndFunction


Function ReleaseLock()
    If( __bDeleted )\
    ||( !__bHeld )
        Return
    EndIf
    
    __iLockCount -= 1
    __bHeld = False
EndFunction







