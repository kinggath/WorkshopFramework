; ---------------------------------------------
; WorkshopFramework:Library:ObjectRefs:LockableWorkshopObjectScript.psc - by E
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

Scriptname WorkshopFramework:Library:ObjectRefs:LockableWorkshopObjectScript extends WorkshopObjectScript

import WorkshopFramework:Library:UtilityFunctions

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
    While( IsLockHeld )
        
        If( ! abWaitForLock )
            ; On second thought, don't wait, just return it's already locked
            Return GENERICLOCK_KEY_INVALID
        EndIf
        
        Utility.Wait( 0.1 )
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
	return iGenericLock_LockCount
EndFunction


Function ForceClearLock()
	; This should really only be used in an emergency situation - for example, after terminating scripts with the Save Editor and needing to restore the lock system to functioning again
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