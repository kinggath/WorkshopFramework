; ---------------------------------------------
; WorkshopFramework:Library:LockableQuest.psc - by E
; ---------------------------------------------
; Reusage Rights ------------------------------
; You are free to use this script or portions of it in your own mods, provided you give me credit in your description and maintain this section of comments in any released source code (which includes the IMPORTED SCRIPT CREDIT section to give credit to anyone in the associated Import scripts below).
; 
; Warning !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
; Do not directly recompile this script for redistribution without first renaming it to avoid compatibility issues with the mod this came from.
; 
; IMPORTED SCRIPT CREDITS
; N/A
; ---------------------------------------------

Scriptname WorkshopFramework:Library:LockableQuest extends WorkshopFramework:Library:ControllerQuest

; Faux global constants - copy paste this section to any object that needs to use the locks 
; this will ensure they have the appropriate constants without needing to access a central 
; quest or global for something so simple, and simultaneous avoids "magic numbers"
Struct GenericLockCacheables
    Int LOCK_INVALID = -2
    Int KEY_INVALID = -1
    Int KEY_NONE =  0
EndStruct

; -----------------------------------------
; Consts
; -----------------------------------------

Int Property GENERICLOCK_LOCK_INVALID = -2 AutoReadOnly Hidden
Int Property GENERICLOCK_KEY_INVALID = -1 AutoReadOnly Hidden
Int Property GENERICLOCK_KEY_NONE = 0 AutoReadOnly Hidden

; Keys will reset back to the first one when the last one is reached.
; The key returned is semi-unique is never generated until the lock can be aquired.
; If there are more than 1K keys being requested, You're Doing It Wrong(tm)
Int INTERNAL_GENERICLOCK_KEY_FIRST = 1024 Const
Int INTERNAL_GENERICLOCK_KEY_LAST = 2047 Const

Int DEFAULT_MAX_LOCK_WAIT_COUNT = 100 Const ; 1.0.5 - Allowing quests to self unlock to avoid cases where script termination locks out a thread from ever completing. Setting this quite high to start until we get a feel for what an effective number will be for most quests. 

Float fMinLockWaitTime = 0.1 Const
Int iMaxLockTimeRandomizer = 40 Const ; 1.0.5 - Given our formula, this will result in somewhere between 0.01 and 0.40 being added to fMinLockWaitTime


; -----------------------------------------
; Vars
; -----------------------------------------

Bool bGenericLock_Initialized = False
Int iGenericLock_CurrentKey
Int iGenericLock_NextKey
Int iGenericLock_LockCount



; -----------------------------------------
; Public API
; Anyone wanting the lock should use these functions.
; These should be thread-safe (that's the point, right?) and
; if used correctly can be used to serialize resources.
; -----------------------------------------

	; Get/Release Lock Return values:
	; <0 = Unable to [un]lock
	;  0 = Unlocked
	; 1+ = Current lock key
	
Int Function GetLock( Int aiKey = 0, Bool abWaitForLock = True )
    ; Create lock as needed
    If( ! bGenericLock_Initialized )
        INTERNAL_GenericLock_Init()
    EndIf
    
    ; Valid key to relock with?
    If(( aiKey != GENERICLOCK_KEY_NONE ) && \
		( ( aiKey < INTERNAL_GENERICLOCK_KEY_FIRST ) || ( aiKey > INTERNAL_GENERICLOCK_KEY_LAST ) ))
     
		Return GENERICLOCK_KEY_INVALID
    EndIf
    
    ; Already locked?
    If(( iGenericLock_CurrentKey != GENERICLOCK_KEY_NONE ) && \
		( iGenericLock_CurrentKey == aiKey ))
		
        ; With the proper key, it's ok
        iGenericLock_LockCount += 1
        Return aiKey
    EndIf
    
    ; Wait for lock to be unlocked
	int iWaitCount = 0 ; 1.0.5 - It's been determined that the game engine can terminate scripts, which means there's a chance for a lock to be held indefinitely. To prevent this, we're introducing an auto-unlock feature
	
	Float fWaitTime = fMinLockWaitTime + Utility.RandomInt(1, iMaxLockTimeRandomizer) as Float/100.0 ; 1.0.5 - setting each call to use a different time so we can spread some out when a burst of requests hits. The wait time based on these settings will be a random amount of time between 0.1 and 0.5 seconds
   
   While( IsLockHeld )
        
        If( ! abWaitForLock )
            ; On second thought, don't wait, just return it's already locked
            Return GENERICLOCK_KEY_INVALID
        EndIf
        
		; 1.0.5 - Ensure things can continue to run while in the pipboy or other menu screens
        Utility.WaitMenuMode( fWaitTime )
		iWaitCount += 1
		
		; 1.0.5 - Auto-unlock after a certain amount of time
		int iMaxLockWaitCount = GetMaxLockWaitCount()
		if(iWaitCount > iMaxLockWaitCount)
			ForceClearLock()
			
			; Let's log when this happens so we can start to get a picture of what an effective MAX_LOCK_WAIT_COUNT is for each function
			Debug.Trace("[WSFW] Max GetLock wait count " + iMaxLockWaitCount + " reached. ForceClearLock called on quest: " + Self)
		endif
    EndWhile
    
    ; Lock it with the new key
    iGenericLock_CurrentKey = INTERNAL_GenericLock_GetNextKey
    iGenericLock_LockCount = 1
    EXTERNAL_GenericLock_GetLock()
    
    ; Locked
    Return iGenericLock_CurrentKey
EndFunction


Int Function ReleaseLock( Int aiKey )
    ; Valid lock?
    If( ! bGenericLock_Initialized )
        INTERNAL_GenericLock_Init()
    EndIf
    
    ; Validate caller
    If( iGenericLock_CurrentKey == GENERICLOCK_KEY_NONE )
        Return GENERICLOCK_KEY_NONE
    EndIf
	
    If( aiKey != iGenericLock_CurrentKey )
        Return GENERICLOCK_KEY_INVALID
    EndIf
    
    ; Release the lock
    iGenericLock_LockCount -= 1
    If( iGenericLock_LockCount < 1 )
        EXTERNAL_GenericLock_ReleaseLock()
        iGenericLock_LockCount = 0
        iGenericLock_CurrentKey = GENERICLOCK_KEY_NONE
    EndIf
    
    ; GENERICLOCK_KEY_NONE when unlocked, key if still locked
    Return iGenericLock_CurrentKey
EndFunction


Int Function GetQueueCount()
	Debug.Trace("[WSFW] Current lock count for quest " + Self + ": " + iGenericLock_LockCount)
	return iGenericLock_LockCount
EndFunction


Function ForceClearLock()
	; 1.0.5 - We're now using this as a means of preventing locks from becoming permanently stuck	
	EXTERNAL_GenericLock_ReleaseLock()
    iGenericLock_LockCount = 0
    iGenericLock_CurrentKey = GENERICLOCK_KEY_NONE	
EndFunction


Bool Property IsLockHeld
    Bool Function Get()
        If( iGenericLock_CurrentKey != GENERICLOCK_KEY_NONE )
            Return True
        EndIf
        Return EXTERNAL_GenericLock_GetLocked()
    EndFunction
EndProperty

; Internal API
; This is not a public API - These are used internally
; ----------------------------------------


Function INTERNAL_GenericLock_Init()
    iGenericLock_CurrentKey         = 0
    iGenericLock_NextKey            = INTERNAL_GENERICLOCK_KEY_FIRST
    iGenericLock_LockCount          = 0
    bGenericLock_Initialized        = True
EndFunction


Int Property INTERNAL_GenericLock_GetNextKey
    Int Function Get()
        Int nextKey = iGenericLock_NextKey
        
        iGenericLock_NextKey += 1
        If( iGenericLock_NextKey < INTERNAL_GENERICLOCK_KEY_FIRST )||( iGenericLock_NextKey > INTERNAL_GENERICLOCK_KEY_LAST )
            iGenericLock_NextKey = INTERNAL_GENERICLOCK_KEY_FIRST
        EndIf
        
        Return nextKey
    EndFunction
EndProperty




; External API
; This is not a public API - There are used internally by ESM:GenericLock
; Inheritors need to implement these if they need additional functionality
; ----------------------------------------


Bool Function EXTERNAL_GenericLock_GetLocked()
    ; STUB:  Override this with any additional conditions
    Return False
EndFunction


Function EXTERNAL_GenericLock_GetLock()
    ; STUB:  Override this with any additional changes
EndFunction


Function EXTERNAL_GenericLock_ReleaseLock()
    ; STUB:  Override this with any additional changes
EndFunction


Int Function GetMaxLockWaitCount()
	; Override to alter the count your quest should wait
	return DEFAULT_MAX_LOCK_WAIT_COUNT
EndFunction