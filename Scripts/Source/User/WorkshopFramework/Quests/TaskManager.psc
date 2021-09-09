; ---------------------------------------------
; WorkshopFramework:Quests:TaskManager.psc - by kinggath, based on concept by redbaron148
; ---------------------------------------------
; Reusage Rights ------------------------------
; You are free to use this script or portions of it in your own mods, provided you give me credit in your description and maintain this section of comments in any released source code (which includes the IMPORTED SCRIPT CREDIT section to give credit to anyone in the associated Import scripts below).
; 
; Warning !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
; Do not directly recompile this script for redistribution without first renaming it to avoid compatibility issues issues with the mod this came from.
; 
; IMPORTED SCRIPT CREDITS
; N/A
; ---------------------------------------------

Scriptname WorkshopFramework:Quests:TaskManager extends WorkshopFramework:Library:SlaveQuest Conditional

;-----------------------------------------------------------------------------------------
;------------------------------------ Custom Events --------------------------------------
;-----------------------------------------------------------------------------------------
CustomEvent TaskExecuted
; kArgs[0] = iUniqueTaskID - unique ID for this task
; kArgs[1] = Self - Ref to this task
; kArgs[2] = GetBaseObject() - Base CK form this task ref was created from
; kArgs[3] = abExecutionSucceeded - Whether or not the execution actually occurred
; kArgs[4] = iIterations - Latest iteration count of the task
; kArgs[5] = abTaskCompleted - If the task is now fully finished

;-----------------------------------------------------------------------------------------
;------------------------------------ ERROR Codes ----------------------------------------
;-----------------------------------------------------------------------------------------
Int Property ERC_INVALID_PARAMETER = -1 AutoReadOnly Hidden
Int Property ERC_TASK_NOT_FOUND = -2 AutoReadOnly Hidden

;-----------------------------------------------------------------------------------------
;------------------------------------ Editor Properties --------------------------------------
;-----------------------------------------------------------------------------------------
Group Aliases
	RefCollectionAlias Property ScheduledTasks Auto Const Mandatory
	ReferenceAlias Property SafeSpawnPointAlias Auto Const Mandatory
EndGroup

;-----------------------------------------------------------------------------------------
;------------------------------------ Vars --------------------------------------
;-----------------------------------------------------------------------------------------
int iNextTaskID = 0
Int Property NextTaskID Hidden
    Int Function Get()
        iNextTaskID += 1
        
        Return iNextTaskID
    EndFunction
EndProperty

;-----------------------------------------------------------------------------------------
;------------------------------------ Extended Parent Functions --------------------------
;-----------------------------------------------------------------------------------------
Function HandleQuestInit()
	Parent.HandleQuestInit()
EndFunction

Function HandleGameLoaded()
	Parent.HandleGameLoaded()
EndFunction


;-----------------------------------------------------------------------------------------
;------------------------------------ Functions --------------------------------------
;-----------------------------------------------------------------------------------------

WorkshopFramework:Library:ObjectRefs:Task Function CreateTask(Form aTaskThread, Float afTimerLength = 0.0, Bool abRealTime = true, Int aiTotalIterations = 1, Bool abFirstIterationImmediate = false)
	ObjectReference kSpawnPoint = SafeSpawnPointAlias.GetRef()
	
	WorkshopFramework:Library:ObjectRefs:Task kTaskRef = kSpawnPoint.PlaceAtMe(aTaskThread, abInitiallyDisabled = true) as WorkshopFramework:Library:ObjectRefs:Task
	
	kTaskRef.iUniqueTaskID = NextTaskID
	kTaskRef.fTimerLength = afTimerLength
	kTaskRef.bRealtimeTimer = abRealTime
	kTaskRef.iTotalIterations = aiTotalIterations
	kTaskRef.bFirstIterationImmediate = abFirstIterationImmediate
	kTaskRef.TaskManager = Self
	
	return kTaskRef
EndFunction

Int Function StartTask(WorkshopFramework:Library:ObjectRefs:Task akTaskRef)
	if(akTaskRef == None)
		return ERC_INVALID_PARAMETER
	endif
	
	ScheduledTasks.AddRef(akTaskRef)
	akTaskRef.StartTask()
	
	return 1
EndFunction

Int Function CancelTaskByID(Int aiTaskID)
	int i = ScheduledTasks.GetCount() - 1
	while(i >= 0)
		WorkshopFramework:Library:ObjectRefs:Task thisTask = ScheduledTasks.GetAt(i) as WorkshopFramework:Library:ObjectRefs:Task
		
		if( ! thisTask) ; Not a task type, remove from here
			ScheduledTasks.RemoveRef(thisTask)
		elseif(thisTask.iUniqueTaskID == aiTaskID)
			ScheduledTasks.RemoveRef(thisTask)
			thisTask.Cancel()
			return 1
		endif
		
		i -= 1
	endWhile
	
	return ERC_TASK_NOT_FOUND
EndFunction

Int Function AdjustTaskTimerByID(Int aiTaskID, Float afAdjustTimerBy, Bool abAffectCurrentIterationOnly = false)
	int i = ScheduledTasks.GetCount() - 1
	while(i >= 0)
		WorkshopFramework:Library:ObjectRefs:Task thisTask = ScheduledTasks.GetAt(i) as WorkshopFramework:Library:ObjectRefs:Task
		
		if( ! thisTask) ; Not a task type, remove from here
			ScheduledTasks.RemoveRef(thisTask)
		elseif(thisTask.iUniqueTaskID == aiTaskID)
			thisTask.AlterTimer(afAdjustTimerBy, abAffectCurrentIterationOnly)
			return 1
		endif
		
		i -= 1
	endWhile
	
	return ERC_TASK_NOT_FOUND
EndFunction

Int Function RestartTaskTimerByID(Int aiTaskID, Float afChangeTimerLength = -1.0, Bool abAffectCurrentIterationOnly = false)
	int i = ScheduledTasks.GetCount() - 1
	while(i >= 0)
		WorkshopFramework:Library:ObjectRefs:Task thisTask = ScheduledTasks.GetAt(i) as WorkshopFramework:Library:ObjectRefs:Task
		
		if( ! thisTask) ; Not a task type, remove from here
			ScheduledTasks.RemoveRef(thisTask)
		elseif(thisTask.iUniqueTaskID == aiTaskID)
			thisTask.RestartTimer(afChangeTimerLength, abAffectCurrentIterationOnly)
			return 1
		endif
		
		i -= 1
	endWhile
	
	return ERC_TASK_NOT_FOUND
EndFunction

WorkshopFramework:Library:ObjectRefs:Task Function GetTaskByID(Int aiTaskID)
	int i = 0
	while(i < ScheduledTasks.GetCount())
		WorkshopFramework:Library:ObjectRefs:Task thisTask = ScheduledTasks.GetAt(i) as WorkshopFramework:Library:ObjectRefs:Task
		
		if(thisTask && thisTask.iUniqueTaskID == aiTaskID)
			return thisTask
		endif
		
		i += 1
	endWhile
	
	return None
EndFunction