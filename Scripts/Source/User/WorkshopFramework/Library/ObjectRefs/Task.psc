; ---------------------------------------------
; WorkshopFramework:Library:ObjectRefs:Task.psc - by redbaron148
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

Scriptname WorkshopFramework:Library:ObjectRefs:Task extends ObjectReference

; -
; Consts
; -
int SelfDestructTimerID = 1
int TaskExecutionTimerID = 2

;
; Properties for setting before running
;
Float Property fTimerLength = 0.0 Auto Hidden
Bool Property bRealtimeTimer = true Auto Hidden
Int Property iTotalIterations = 1 Auto Hidden
Bool Property bFirstIterationImmediate = false Auto Hidden


Bool Property bAutoDestroy = true Auto Hidden ; Note: When turning off AutoDestroy - you are in charge of calling SelfDestruct on this thread when you are done
Int Property iUniqueTaskID = -1 Auto Hidden

;
; Vars used by this system
;
WorkshopFramework:Quests:TaskManager Property TaskManager Auto Hidden ; Filled by quest that creates the task
Float Property fTaskCreatedGameTime = 0.0 Auto Hidden
Float Property fLastTimerStartGameTime = 0.0 Auto Hidden
Float Property fExtendCurrentTime = 0.0 Auto Hidden
Int Property iIterations = 0 Auto Hidden

; -
; Events
; -

Event OnTimer(Int aiTimerID)
	if(aiTimerID == SelfDestructTimerID)
		if(bAutoDestroy)
			SelfDestruct()
		endif
	elseif(aiTimerID == TaskExecutionTimerID)
		if(fExtendCurrentTime > 0)
			StartTimer(fExtendCurrentTime, TaskExecutionTimerID)
			fExtendCurrentTime = 0.0
		else
			RunCode()
		endif
	endif
EndEvent

Event OnTimerGameTime(Int aiTimerID)
	if(aiTimerID == TaskExecutionTimerID)
		if(fExtendCurrentTime > 0)
			StartTimerGameTime(fExtendCurrentTime, TaskExecutionTimerID)
			fExtendCurrentTime = 0.0
		else
			RunCode()
		endif
	endif
EndEvent


; -
; Internal Functions
; -
Function StartTask()
	fTaskCreatedGameTime = Utility.GetCurrentGameTime()
	
	if(bFirstIterationImmediate)
		RunCode()
		
		if(iIterations >= iTotalIterations)
			Complete()
			
			return
		endif
	endif
	
	BeginTimer()
EndFunction

Function RunCode()
	Bool bCompleted = false
	Bool bSuccess = false
	
	if(CanExecute())
		bSuccess = HandleExecute()
		
		iIterations += 1
		
		if(iIterations >= iTotalIterations)
			Complete()
			bCompleted = true
		endif
	else
		bSuccess = HandleCannotExecute()
	endif
	
	if( ! bCompleted)
		BeginTimer()
	endif
	
	SendTaskExecutedEvent(bSuccess, bCompleted)
EndFunction

Function BeginTimer()
	fExtendCurrentTime = 0.0
	fLastTimerStartGameTime = Utility.GetCurrentGameTime()
	
	if(bRealtimeTimer)
		StartTimer(fTimerLength, TaskExecutionTimerID)
	else
		StartTimerGameTime(fTimerLength, TaskExecutionTimerID)
	endif
EndFunction

Function AlterTimer(Float afAdjustBy, Bool abAffectCurrentIterationOnly = false)
	if(afAdjustBy < 0 && ! bRealtimeTimer)
		CancelTimerGameTime(TaskExecutionTimerID)
		
		; Reduce length of timer, we have no way to do this for Realtime timers, but can for gametime
		Float fCurrentTime = Utility.GetCurrentGameTime()
		Float fTimeElapsed = fCurrentTime - fLastTimerStartGameTime
		Float fRemainingTime = fTimeElapsed - afAdjustBy
		
		if(fRemainingTime <= 0)
			RunCode()
		else
			StartTimerGameTime(fRemainingTime, TaskExecutionTimerID)
		endif
	else
		fExtendCurrentTime += afAdjustBy
	endif
	
	if( ! abAffectCurrentIterationOnly)
		fTimerLength += afAdjustBy
	endif
EndFunction

Function SendTaskExecutedEvent(Bool abExecutionSucceeded, Bool abTaskCompleted)
	Var[] kArgs = new Var[6]
	kArgs[0] = iUniqueTaskID
	kArgs[1] = Self
	kArgs[2] = GetBaseObject()
	kArgs[3] = abExecutionSucceeded
	kArgs[4] = iIterations
	kArgs[5] = abTaskCompleted
	
	TaskManager.SendCustomEvent("TaskExecuted", kArgs)
EndFunction

Function Cancel()
	CancelTimer(TaskExecutionTimerID)
	CancelTimerGameTime(TaskExecutionTimerID)
	
	Complete()
EndFunction

Function Complete()
	if(bAutoDestroy)
		if(IsBoundGameObjectAvailable())
			StartTimer(3.0, SelfDestructTimerID)
		else
			ReleaseObjectReferences()
		endif
	endif
EndFunction

Function SelfDestruct()
	TaskManager.ScheduledTasks.RemoveRef(Self)
	ReleaseObjectReferences()
	
	Disable(false)
	Delete()
EndFunction


;-----------------------------------------------------------------------------------------
;------------------------------------ Overridable Functions ------------------------------
;-----------------------------------------------------------------------------------------
Bool Function CanExecute()
	return true
EndFunction

Bool Function HandleExecute()
	return true
EndFunction

Bool Function HandleCannotExecute()
	return false
EndFunction

Function ReleaseObjectReferences()
	; Implement Me - any global variables that you stored an object reference in need to be set to none or that reference and this thread will be permanently persisted causing a memory leak!
EndFunction