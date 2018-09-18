Scriptname WorkshopEventsQuestScript extends Quest
{use for quests that need to complete objectives
based on workshop events}

ReferenceAlias Property Alias_Workshop Auto Const

WorkshopParentScript Property WorkshopParent Auto Const

WorkshopParentScript:WorkshopObjective[] Property WorkshopObjectives const auto
{ array of objective data }


function RegisterForWorkshopEvents(bool bRegister = true)
	debug.trace(self + " RegisterForWorkshopEvents")
	; register for build events from workshop
	WorkshopParent.RegisterForWorkshopEvents(self, bRegister)
endFunction

;Quest theQuest, WorkshopObjective[] workshopObjectives, WorkshopScript theWorkshop,
Event WorkshopParentScript.WorkshopObjectBuilt(WorkshopParentScript akSender, Var[] akArgs)
	debug.trace(self + " WorkshopObjectBuilt received")	
	;WorkshopParent.UpdateWorkshopObjectives(self, WorkshopObjectives, Alias_Workshop.GetRef() as WorkshopScript, akArgs)
	;HandleWorkshopEvent()
	;UFO4P 2.0.5 Bug #25128: repleced the previous lines with the following code:
	WorkshopScript workshopAliasRef = Alias_Workshop.GetRef() as WorkshopScript
	if WorkshopCheck (workshopAliasRef, akArgs)
		WorkshopParent.UpdateWorkshopObjectivesSpecific (self, WorkshopObjectives, workshopAliasRef)
		HandleWorkshopEvent()
	endif	
EndEvent

Event WorkshopParentScript.WorkshopObjectMoved(WorkshopParentScript akSender, Var[] akArgs)
	debug.trace(self + " WorkshopObjectMoved received")
	;WorkshopParent.UpdateWorkshopObjectives(self, WorkshopObjectives, Alias_Workshop.GetRef() as WorkshopScript, akArgs)
	;HandleWorkshopEvent()
	;UFO4P 2.0.5 Bug #25128: repleced the previous lines with the following code:
	WorkshopScript workshopAliasRef = Alias_Workshop.GetRef() as WorkshopScript
	if WorkshopCheck (workshopAliasRef, akArgs)
		WorkshopParent.UpdateWorkshopObjectivesSpecific (self, WorkshopObjectives, workshopAliasRef)
		HandleWorkshopEvent()
	endif	
EndEvent

Event WorkshopParentScript.WorkshopObjectDestroyed(WorkshopParentScript akSender, Var[] akArgs)
	debug.trace(self + " WorkshopObjectDestroyed received")
	;WorkshopParent.UpdateWorkshopObjectives(self, WorkshopObjectives, Alias_Workshop.GetRef() as WorkshopScript, akArgs)
	;HandleWorkshopEvent()
	;UFO4P 2.0.5 Bug #25128: repleced the previous lines with the following code:
	WorkshopScript workshopAliasRef = Alias_Workshop.GetRef() as WorkshopScript
	if WorkshopCheck (workshopAliasRef, akArgs)
		WorkshopParent.UpdateWorkshopObjectivesSpecific (self, WorkshopObjectives, workshopAliasRef)
		HandleWorkshopEvent()
	endif	
EndEvent

Event WorkshopParentScript.WorkshopObjectRepaired(WorkshopParentScript akSender, Var[] akArgs)
	debug.trace(self + " WorkshopObjectRepaired received")
	;WorkshopParent.UpdateWorkshopObjectives(self, WorkshopObjectives, Alias_Workshop.GetRef() as WorkshopScript, akArgs)
	;HandleWorkshopEvent()
	;UFO4P 2.0.5 Bug #25128: repleced the previous lines with the following code:
	WorkshopScript workshopAliasRef = Alias_Workshop.GetRef() as WorkshopScript
	if WorkshopCheck (workshopAliasRef, akArgs)
		WorkshopParent.UpdateWorkshopObjectivesSpecific (self, WorkshopObjectives, workshopAliasRef)
		HandleWorkshopEvent()
	endif	
EndEvent

Event WorkshopParentScript.WorkshopActorAssignedToWork(WorkshopParentScript akSender, Var[] akArgs)
	debug.trace(self + " WorkshopActorAssignedToWork received")
	;WorkshopParent.UpdateWorkshopObjectives(self, WorkshopObjectives, Alias_Workshop.GetRef() as WorkshopScript, akArgs)
	;HandleWorkshopEvent()
	;UFO4P 2.0.5 Bug #25128: repleced the previous lines with the following code:
	WorkshopScript workshopAliasRef = Alias_Workshop.GetRef() as WorkshopScript
	if WorkshopCheck (workshopAliasRef, akArgs)
		WorkshopParent.UpdateWorkshopObjectivesSpecific (self, WorkshopObjectives, workshopAliasRef)
		HandleWorkshopEvent()
	endif	
EndEvent

Event WorkshopParentScript.WorkshopActorUnassigned(WorkshopParentScript akSender, Var[] akArgs)
	debug.trace(self + " WorkshopActorUnassigned received")
	;WorkshopParent.UpdateWorkshopObjectives(self, WorkshopObjectives, Alias_Workshop.GetRef() as WorkshopScript, akArgs)
	;HandleWorkshopEvent()
	;UFO4P 2.0.5 Bug #25128: repleced the previous lines with the following code:
	WorkshopScript workshopAliasRef = Alias_Workshop.GetRef() as WorkshopScript
	if WorkshopCheck (workshopAliasRef, akArgs)
		WorkshopParent.UpdateWorkshopObjectivesSpecific (self, WorkshopObjectives, workshopAliasRef)
		HandleWorkshopEvent()
	endif	
EndEvent

Event WorkshopParentScript.WorkshopObjectDestructionStageChanged(WorkshopParentScript akSender, Var[] akArgs)
	debug.trace(self + " WorkshopObjectDestructionStageChanged received")
	;WorkshopParent.UpdateWorkshopObjectives(self, WorkshopObjectives, Alias_Workshop.GetRef() as WorkshopScript, akArgs)
	;HandleWorkshopEvent()
	;UFO4P 2.0.5 Bug #25128: repleced the previous lines with the following code:
	WorkshopScript workshopAliasRef = Alias_Workshop.GetRef() as WorkshopScript
	if WorkshopCheck (workshopAliasRef, akArgs)
		WorkshopParent.UpdateWorkshopObjectivesSpecific (self, WorkshopObjectives, workshopAliasRef)
		HandleWorkshopEvent()
	endif	
EndEvent

Event WorkshopParentScript.WorkshopObjectPowerStageChanged(WorkshopParentScript akSender, Var[] akArgs)
	debug.trace(self + " WorkshopObjectPowerStageChanged received")
	;WorkshopParent.UpdateWorkshopObjectives(self, WorkshopObjectives, Alias_Workshop.GetRef() as WorkshopScript, akArgs)
	;HandleWorkshopEvent()
	;UFO4P 2.0.5 Bug #25128: repleced the previous lines with the following code:
	WorkshopScript workshopAliasRef = Alias_Workshop.GetRef() as WorkshopScript
	if WorkshopCheck (workshopAliasRef, akArgs)
		WorkshopParent.UpdateWorkshopObjectivesSpecific (self, WorkshopObjectives, workshopAliasRef)
		HandleWorkshopEvent()
	endif	
EndEvent

Event WorkshopParentScript.WorkshopPlayerOwnershipChanged(WorkshopParentScript akSender, Var[] akArgs)
	debug.trace(self + " WorkshopPlayerOwnershipChanged received")
	if (akArgs.Length > 0)
		bool bPlayerOwned = akArgs[0] as bool
		WorkshopScript workshopRef = akArgs[1] as WorkshopScript
		if workshopRef == (Alias_Workshop.GetRef() as WorkshopScript)
			HandleWorkshopPlayerOwnershipChanged(bPlayerOwned)
			HandleWorkshopEvent()
		endif
	endif
EndEvent

function HandleWorkshopPlayerOwnershipChanged(bool bPlayerOwned)
	; empty function for child scripts to override
endFunction

function HandleWorkshopEvent()
	; empty function for child scripts to override
endFunction

;------------------------------------------
;	Added by UFO4P 2.0.3 for Bug #23306
;------------------------------------------

Event WorkshopParentScript.WorkshopEnterMenu(WorkshopParentScript akSender, Var[] akArgs)
EndEvent

;------------------------------------------
;	Added by UFO4P 2.0.5 for Bug #25128
;------------------------------------------

bool function WorkshopCheck (WorkshopScript workshopAliasRef, Var[] akArgs)
	if akArgs.Length > 0
		WorkshopScript workshopRef = akArgs[1] as WorkshopScript
		if workshopRef && workshopRef == workshopAliasRef
			return true
		endif
	endif
	return false
endFunction
