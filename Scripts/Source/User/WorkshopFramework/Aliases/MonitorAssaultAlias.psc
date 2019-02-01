Scriptname WorkshopFramework:Aliases:MonitorAssaultAlias extends RefCollectionAlias

Struct PercentStages
	Int iPercent
	Int iStageToSet
	Int iStageRequired = -1
EndStruct


Bool Property bOnBleedout = true Auto Const
{ Monitor for bleedout as well as death }
Bool Property bDisableBleedoutRecovery = true Auto Const

PercentStages[] Property StageTriggers Auto Const
{ Trigger stages based on percentage, in whole numbers, of the NPCs that are dead or in bleedout (depending on bOnBleedout setting) }
Keyword Property BleedoutRecoveryStopped Auto Const Mandatory

Event OnDeath(ObjectReference akSenderRef, Actor akKiller)
	CheckForStageUpdate()
EndEvent


Event OnEnterBleedout(ObjectReference akSenderRef)
	CheckForStageUpdate()
	
	if(bDisableBleedoutRecovery)
		(akSenderRef as Actor).SetNoBleedoutRecovery(true)
		akSenderRef.AddKeyword(BleedoutRecoveryStopped)
	endif
EndEvent


Function CheckForStageUpdate()
	int i = 0
	int iTriggeredCount = 0
	int iTotalCount = GetCount()
	while(i < iTotalCount)
		Actor thisActor = GetAt(i) as Actor
		if(thisActor.IsDead() || (bOnBleedout && thisActor.IsBleedingOut()))
			iTriggeredCount += 1
		endif
		
		i += 1
	endWhile
	
	Quest thisQuest = GetOwningQuest()
	i = 0
	
	int iTriggeredPercent = ((iTriggeredCount as Float/iTotalCount as Float) as Float * 100) as Int
	
	while(i < StageTriggers.Length)
		if((StageTriggers[i].iStageRequired == -1 || thisQuest.GetStageDone(StageTriggers[i].iStageRequired)) && ! thisQuest.GetStageDone(StageTriggers[i].iStageToSet) && iTriggeredPercent >= StageTriggers[i].iPercent)
			thisQuest.SetStage(StageTriggers[i].iStageToSet)
		endif
		
		i += 1
	endWhile
EndFunction