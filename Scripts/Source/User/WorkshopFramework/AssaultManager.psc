; ---------------------------------------------
; WorkshopFramework:AssaultManager.psc - by kinggath
; ---------------------------------------------
; Reusage Rights ------------------------------
; You are free to use this script or portions of it in your own mods, provided you give me credit in your description and maintain this section of comments in any released source code (which includes the IMPORTED SCRIPT CREDIT section to give credit to anyone in the associated Import scripts below.
; 
; Warning !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
; Do not directly recompile this script for redistribution without first renaming it to avoid compatibility issues issues with the mod this came from.
; 
; IMPORTED SCRIPT CREDIT
; N/A
; ---------------------------------------------

Scriptname WorkshopFramework:AssaultManager extends WorkshopFramework:Library:SlaveQuest
{ 
This will handle settlement assaults. Primarily, its goal is to act as a distributor of events for what are story-node triggered quests. Though will be expanded to offer more meta-controls.
}

import WorkshopFramework:Library:DataStructures
import WorkshopFramework:Library:UtilityFunctions

CustomEvent AssaultStarted
;/
kArgs[0] = Quest
kArgs[1] = iReserveID
kArgs[2] = WorkshopScript
kArgs[3] = iCurrentAssaultType
kArgs[4] = AttackingFaction
kArgs[5] = DefendingFaction
/;

CustomEvent AssaultCompleted
;/
kArgs[0] = Quest
kArgs[1] = iReserveID
kArgs[2] = WorkshopScript
kArgs[3] = iCurrentAssaultType
kArgs[4] = AttackingFaction
kArgs[5] = DefendingFaction
kArgs[6] = bPlayerSideWon
/;

CustomEvent AssaultStopped
;/
kArgs[0] = Quest
kArgs[1] = iReserveID
/;

CustomEvent AssaultFirstBlood
;/
kArgs[0] = Quest
kArgs[1] = iReserveID
/;

CustomEvent AssaultAttackersDown
;/
kArgs[0] = Quest
kArgs[1] = iReserveID
/;

CustomEvent AssaultDefendersDown
;/
kArgs[0] = Quest
kArgs[1] = iReserveID
/;

; ---------------------------------------------
; Consts
; ---------------------------------------------


; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------
Group Controllers
	Quest[] Property DefaultAssaultQuests Auto Const Mandatory
EndGroup


Group Aliases
	ReferenceAlias Property SafeSpawnPoint Auto Const Mandatory
	ReferenceAlias Property RemainPlayerEnemy Auto Const Mandatory
	RefCollectionAlias Property RemainPlayerEnemyCollection Auto Const Mandatory
EndGroup

Group Assets
	MiscObject Property QuestVerb_Assault Auto Const Mandatory
	MiscObject Property QuestVerb_Defend Auto Const Mandatory
EndGroup

Group EventKeywords
	Keyword Property Event_PlayerInvolvedAssault Auto Const Mandatory
	Keyword Property Event_AutomatedAssault Auto Const Mandatory
EndGroup

; ---------------------------------------------
; Properties
; ---------------------------------------------

int Property iType_Attack_Wipeout = 1 autoReadOnly
int Property iType_Attack_Subdue = 2 autoReadOnly
int Property iType_Defend = 3 autoReadOnly

Int iNextReserveID = 0
Int Property NextReserveID
	Int Function Get()
		iNextReserveID += 1
		
		if(iNextReserveID > 999999)
			iNextReserveID = 1
		endif
		
		return iNextReserveID
	endFunction
EndProperty

; ---------------------------------------------
; Vars
; ---------------------------------------------

ReservedAssaultQuest[] RunningQuests

; ---------------------------------------------
; Events 
; ---------------------------------------------

Event OnQuestInit()
	HandleQuestInit()
EndEvent


Event Quest.OnReset(Quest akSenderRef)
	Utility.Wait(0.1) ; Latent action to ensure everything happens in order - without this the calls to AssaultManager looking for the quest to match the reserve IDs are never resolved
	
	if( ! RunningQuests)
		RunningQuests = new ReservedAssaultQuest[0]
	endif
	
	int iRunningIndex = RunningQuests.FindStruct("kQuestRef", akSenderRef)
	
	WorkshopFramework:AssaultSettlement asAssault = akSenderRef as WorkshopFramework:AssaultSettlement
		
	if(asAssault)
		if(iRunningIndex >= 0)
			RunningQuests[iRunningIndex].iReserveID = asAssault.GetReserveID()
		else
			ReservedAssaultQuest newAssaultQuest = new ReservedAssaultQuest
			
			newAssaultQuest.iReserveID = asAssault.GetReserveID()
			newAssaultQuest.kQuestRef = asAssault
			
			RunningQuests.Add(newAssaultQuest)
		endif
	endif
EndEvent


Event Quest.OnQuestShutdown(Quest akSenderRef)
	int iRunningIndex = RunningQuests.FindStruct("kQuestRef", akSenderRef)
	
	if(iRunningIndex >= 0)
		if( ! RunningQuests[iRunningIndex].bCompleteEventFired)
			AssaultStopped_Private(akSenderRef)
		endif
		
		RunningQuests.Remove(iRunningIndex)
	endif
EndEvent

; ---------------------------------------------
; Extended Handlers
; ---------------------------------------------

Function HandleQuestInit()
	Parent.HandleQuestInit()
	
	; init arrays
	RunningQuests = new ReservedAssaultQuest[0]
	
	RegisterForEvents()
EndFunction

Function HandleGameLoaded()
	; Normally this code would be in HandleInstallModChanges, but we haven't been recording version until 2.3.8, so have to run it once here
	Patch238() ; Must be above Parent.HandleGameLoaded as it will set iInstalledVersion
	
	Parent.HandleGameLoaded() ; Added in 2.3.8, it was mistakenly left out meaning prior to this, install version would not have been recorded
	
	RegisterForEvents()
EndFunction


Function HandleInstallModChanges()
	; Make sure we are registered for any new assault quests
	RegisterDefaultAssaultQuests()
		
	Parent.HandleInstallModChanges()
EndFunction

; ---------------------------------------------
; Overrides
; ---------------------------------------------


; ---------------------------------------------
; Functions
; ---------------------------------------------

Function Patch238()
	int iVersion238 = 104
	if(iInstalledVersion >= iVersion238)
		return
	endif
	
	int i = 0
	while(i < RunningQuests.Length)
		WorkshopFramework:AssaultSettlement asAssaultQuest = RunningQuests[i].kQuestRef as WorkshopFramework:AssaultSettlement
		
		if(asAssaultQuest.IsRunning())
			int j = asAssaultQuest.KillToComplete.GetCount()
			while(j > 0)
				j -= 1
				Actor thisActor = asAssaultQuest.KillToComplete.GetAt(j) as Actor
				if(asAssaultQuest.ShouldForceSubdue(thisActor))
					asAssaultQuest.SubdueToComplete.AddRef(thisActor)
					asAssaultQuest.KillToComplete.RemoveRef(thisActor)
				endif				
			endWhile
			
			if(asAssaultQuest.SubdueToComplete.GetCount() > 0)
				asAssaultQuest.PreventCollectionBleedoutRecovery(asAssaultQuest.SubdueToComplete)
			endif
		endif
		
		i += 1
	endWhile
EndFunction

Function RegisterForEvents() 
	RegisterDefaultAssaultQuests()
EndFunction

Function RegisterDefaultAssaultQuests()
	int i = 0
	while(i < DefaultAssaultQuests.Length)
		RegisterNewAssaultQuest(DefaultAssaultQuests[i])
		
		i += 1
	endWhile
EndFunction

; If another mod wants to create a custom quest to act as an AssaultSettlement quest, they'll need to call this to ensure the manager can correctly relay the events
Function RegisterNewAssaultQuest(Quest akQuestRef)
	RegisterForRemoteEvent(akQuestRef, "OnReset")
	RegisterForRemoteEvent(akQuestRef, "OnQuestShutdown")
EndFunction


Int Function CountAssaultsRunning()
	return RunningQuests.Length
EndFunction

Int Function SetupNewAssault(Location akTargetLocation, Int aiType, Bool abInvolvePlayer = true, ObjectReference akCustomVerb = None)
	; Generate new reserve ID
	Int iReserveID = NextReserveID
	
	if(akCustomVerb == None)
		ObjectReference SpawnAt = SafeSpawnPoint.GetRef()
		; Create object to act as the verb for this quest name
		if(aiType == iType_Defend)
			akCustomVerb = SpawnAt.PlaceAtMe(QuestVerb_Defend)
		else
			akCustomVerb = SpawnAt.PlaceAtMe(QuestVerb_Assault)
		endif
	endif
	
	if(abInvolvePlayer)
		if(Event_PlayerInvolvedAssault.SendStoryEventAndWait(akTargetLocation, akRef1 = akCustomVerb, aiValue1 = aiType, aiValue2 = iReserveID))
			int iWaitCount = 0
			int iMaxWaitCount = 10
			while( ! FindAssaultQuest(iReserveID) && iWaitCount < iMaxWaitCount)
				Utility.Wait(1.0) ; Give the quest time to start
				iWaitCount += 1
			endWhile
			
			if(iWaitCount >= iMaxWaitCount) ; Failed to retrieve quest - let's not get stuck here
				return -1 
			endif
			
			return iReserveID
		else
			return -1
		endif
	else
		Debug.MessageBox("This feature is still being developed. - kinggath")
		
		return -1
		if(Event_AutomatedAssault.SendStoryEventAndWait(akTargetLocation, aiValue1 = aiType, aiValue2 = iReserveID))
			while( ! FindAssaultQuest(iReserveID))
				Utility.Wait(1.0) ; Give the quest time to start
			endWhile
			
			return iReserveID
		else
			return -1
		endif
	endif
	
	return -1
EndFunction


Bool Function SetupComplete(Int aiReserveID)
	Quest kQuestRef = FindAssaultQuest(aiReserveID)
	
	if(kQuestRef)
		WorkshopFramework:AssaultSettlement asAssaultQuest = kQuestRef as WorkshopFramework:AssaultSettlement
		
		if(asAssaultQuest)
			asAssaultQuest.SetupAssault()
			
			return true
		endif
	endif
	
	return false
EndFunction


Function StartAssault(Int aiReserveID) ; Trigger the attack to begin
	Quest kQuestRef = FindAssaultQuest(aiReserveID)
	
	if(kQuestRef)
		WorkshopFramework:AssaultSettlement asAssaultQuest = kQuestRef as WorkshopFramework:AssaultSettlement
		
		if(asAssaultQuest)
			asAssaultQuest.StartAssault()
		endif
	endif
EndFunction


Function StopAssault(Int aiReserveID)
	Quest kQuestRef = FindAssaultQuest(aiReserveID)
	
	if(kQuestRef)
		WorkshopFramework:AssaultSettlement asAssaultQuest = kQuestRef as WorkshopFramework:AssaultSettlement
		
		if(asAssaultQuest)
			asAssaultQuest.SetStage(asAssaultQuest.iStage_Shutdown)
		endif
	endif
EndFunction


Bool Function SetupOptions(int aiReserveID, Bool abDisableFastTravel = true, Bool abSettlersAreDefenders = true, Bool abRobotsAreDefenders = true, Bool abAutoStartAssaultOnLoad = true, Bool abAutoStartAssaultWhenPlayerReachesAttackFrom = true, Bool abMoveAttackersToStartPoint = true, Bool abMoveDefendersToCenterPoint = true, Bool abAttackersDeadFailsAssault = true, Bool abAutoHandleObjectives = true, Bool abGuardsKillableEvenOnSubdue = false, Bool abAttackersKillableEvenOnSubdue = false, Bool abAlwaysSubdueUniques = true, Bool abChildrenFleeDuringAttack = true)
	return SetupOptionsV2(aiReserveID, abDisableFastTravel, abSettlersAreDefenders, abRobotsAreDefenders, abAutoStartAssaultOnLoad, abAutoStartAssaultWhenPlayerReachesAttackFrom, abMoveAttackersToStartPoint, abMoveDefendersToCenterPoint, abAttackersDeadFailsAssault, abAutoHandleObjectives, abGuardsKillableEvenOnSubdue, abAttackersKillableEvenOnSubdue, abAlwaysSubdueUniques, abChildrenFleeDuringAttack)
EndFunction


; 1.1.1 - Adding overrides to take away protected status from attackers and defenders
Bool Function SetupOptionsV2(int aiReserveID, Bool abDisableFastTravel = true, Bool abSettlersAreDefenders = true, Bool abRobotsAreDefenders = true, Bool abAutoStartAssaultOnLoad = true, Bool abAutoStartAssaultWhenPlayerReachesAttackFrom = true, Bool abMoveAttackersToStartPoint = true, Bool abMoveDefendersToCenterPoint = true, Bool abAttackersDeadFailsAssault = true, Bool abAutoHandleObjectives = true, Bool abGuardsKillableEvenOnSubdue = false, Bool abAttackersKillableEvenOnSubdue = false, Bool abAlwaysSubdueUniques = true, Bool abChildrenFleeDuringAttack = true, Bool abForceAttackersKillable = false, Bool abForceDefendersKillable = false)
	return SetupOptionsV3(aiReserveID, abDisableFastTravel, abSettlersAreDefenders, abRobotsAreDefenders, abAutoStartAssaultOnLoad, abAutoStartAssaultWhenPlayerReachesAttackFrom, abMoveAttackersToStartPoint, abMoveDefendersToCenterPoint, abAttackersDeadFailsAssault, abAutoHandleObjectives, abGuardsKillableEvenOnSubdue, abAttackersKillableEvenOnSubdue, abAlwaysSubdueUniques, abChildrenFleeDuringAttack, abForceAttackersKillable, abForceDefendersKillable, abAutoCompleteAssaultWhenOneSideIsDown = true)
EndFunction

; 2.3.4 - Added new parameter abAutoCompleteAssaultWhenOneSideIsDown which can be used to stop an assault from failing/succeeding just because one side is down. In this case, the system calling the assault will be expected to end the assault itself.
Bool Function SetupOptionsV3(int aiReserveID, Bool abDisableFastTravel = true, Bool abSettlersAreDefenders = true, Bool abRobotsAreDefenders = true, Bool abAutoStartAssaultOnLoad = true, Bool abAutoStartAssaultWhenPlayerReachesAttackFrom = true, Bool abMoveAttackersToStartPoint = true, Bool abMoveDefendersToCenterPoint = true, Bool abAttackersDeadFailsAssault = true, Bool abAutoHandleObjectives = true, Bool abGuardsKillableEvenOnSubdue = false, Bool abAttackersKillableEvenOnSubdue = false, Bool abAlwaysSubdueUniques = true, Bool abChildrenFleeDuringAttack = true, Bool abForceAttackersKillable = false, Bool abForceDefendersKillable = false, Bool abAutoCompleteAssaultWhenOneSideIsDown = true)
	Quest kQuestRef = FindAssaultQuest(aiReserveID)
	
	if( ! kQuestRef)
		return false
	endif
	
	WorkshopFramework:AssaultSettlement asAssaultQuest = kQuestRef as WorkshopFramework:AssaultSettlement
		
	if(asAssaultQuest)
		asAssaultQuest.bDisableFastTravel = abDisableFastTravel
		asAssaultQuest.bSettlersAreDefenders = abSettlersAreDefenders
		asAssaultQuest.bRobotsAreDefenders = abRobotsAreDefenders
		asAssaultQuest.bAutoStartAssaultOnLoad = abAutoStartAssaultOnLoad
		asAssaultQuest.bAutoStartAssaultWhenPlayerReachesAttackFrom = abAutoStartAssaultWhenPlayerReachesAttackFrom
		asAssaultQuest.bMoveAttackersToStartPoint = abMoveAttackersToStartPoint
		asAssaultQuest.bMoveDefendersToCenterPoint = abMoveDefendersToCenterPoint
		asAssaultQuest.bAttackersDeadFailsAssault = abAttackersDeadFailsAssault
		asAssaultQuest.bAutoHandleObjectives = abAutoHandleObjectives
		asAssaultQuest.bGuardsKillableEvenOnSubdue = abGuardsKillableEvenOnSubdue
		asAssaultQuest.bAttackersKillableEvenOnSubdue = abAttackersKillableEvenOnSubdue
		asAssaultQuest.bAlwaysSubdueUniques = abAlwaysSubdueUniques
		asAssaultQuest.bChildrenFleeDuringAttack = abChildrenFleeDuringAttack
		asAssaultQuest.bForceAttackersKillable = abForceAttackersKillable
		asAssaultQuest.bForceDefendersKillable = abForceDefendersKillable
		asAssaultQuest.bAutoCompleteAssaultWhenOneSideIsDown = abAutoCompleteAssaultWhenOneSideIsDown
	endif
	
	return true
EndFunction


Bool Function SetupAutoCompleteRules(int aiReserveID, Float afAutoEndTime = 2.0, Bool abAutoCalculateVictor = true, ActorValue aFighterStrengthAV = None, Bool abDamageDefenses = true, Bool abKillCombatants = false, Float afMaxAttackerCasualtyPercentBeforeRetreat = 1.0, Float afMaxDefenderCasualtyPercentBeforeSurrender = 1.0)
	; Options for how an assault should end
	
	Quest kQuestRef = FindAssaultQuest(aiReserveID)
	
	if( ! kQuestRef)
		return false
	endif
	
	WorkshopFramework:AssaultSettlement asAssaultQuest = kQuestRef as WorkshopFramework:AssaultSettlement
		
	if(asAssaultQuest)
		asAssaultQuest.fAutoEndTime = afAutoEndTime
		asAssaultQuest.bAutoCalculateVictor = abAutoCalculateVictor
		asAssaultQuest.FighterStrengthAV = aFighterStrengthAV
		asAssaultQuest.bDamageDefenses = abDamageDefenses
		asAssaultQuest.bKillCombatants = abKillCombatants
		asAssaultQuest.fMaxAttackerCasualtyPercentBeforeRetreat = afMaxAttackerCasualtyPercentBeforeRetreat
		asAssaultQuest.fMaxDefenderCasualtyPercentBeforeSurrender = afMaxDefenderCasualtyPercentBeforeSurrender
	else
		return false
	endif
	
	return true
EndFunction


Bool Function SetupCleanup(int aiReserveID, Bool abSurvivingSpawnedAttackersMoveIn = false, Bool abSurvivingSpawnedDefendersRemain = false, Bool abEnemySurvivorsRemainEnemyToPlayer = true)
	; Options for how an assault should end
	
	Quest kQuestRef = FindAssaultQuest(aiReserveID)
	
	if( ! kQuestRef)
		return false
	endif
	
	WorkshopFramework:AssaultSettlement asAssaultQuest = kQuestRef as WorkshopFramework:AssaultSettlement
		
	if(asAssaultQuest)
		asAssaultQuest.bSurvivingSpawnedAttackersMoveIn = abSurvivingSpawnedAttackersMoveIn
		asAssaultQuest.bSurvivingSpawnedDefendersRemain = abSurvivingSpawnedDefendersRemain
		asAssaultQuest.bEnemySurvivorsRemainEnemyToPlayer = abEnemySurvivorsRemainEnemyToPlayer
	else
		return false
	endif
	
	return true
EndFunction


Bool Function SetupCapture(int aiReserveID, FactionControl aAttackingFactionData = None, Bool abSeverEnemySupplyLines = true, Bool abRemoveEnemySettlers = true, Bool abKillEnemySettlers = false, Bool abCaptureTurrets = true, Bool abCaptureContainers = true, Bool abSettlersJoinFaction = false, Bool abTogglePlayerOwnership = false, Bool abPlayerIsEnemy = false, Int aiCreateInvadingSettlers = -1)
	Quest kQuestRef = FindAssaultQuest(aiReserveID)
	
	if( ! kQuestRef)
		return false
	endif
	
	WorkshopFramework:AssaultSettlement asAssaultQuest = kQuestRef as WorkshopFramework:AssaultSettlement
		
	if(asAssaultQuest)
		asAssaultQuest.bAutoCaptureSettlement = true
		asAssaultQuest.AttackingFactionData = aAttackingFactionData
		asAssaultQuest.bSeverEnemySupplyLines = abSeverEnemySupplyLines
		asAssaultQuest.bRemoveEnemySettlers = abRemoveEnemySettlers
		asAssaultQuest.bKillEnemySettlers = abKillEnemySettlers
		asAssaultQuest.bCaptureTurrets = abCaptureTurrets
		asAssaultQuest.bCaptureContainers = abCaptureContainers
		asAssaultQuest.bSettlersJoinFaction = abSettlersJoinFaction
		asAssaultQuest.bTogglePlayerOwnership = abTogglePlayerOwnership
		asAssaultQuest.bPlayerIsEnemy = abPlayerIsEnemy
		asAssaultQuest.iCreateInvadingSettlers = aiCreateInvadingSettlers
	else
		return false
	endif
	
	return true
EndFunction

Bool Function SetupAttackers(int aiReserveID, Faction aAttackingFaction = None, ActorBase akAttackerType = None, Int aiSpawnAttackers = 0, RefCollectionAlias aOtherAttackers = None)
	AssaultSpawnCount[] SpawnMe = new AssaultSpawnCount[0]
	if(akAttackerType != None)
		AssaultSpawnCount thisCount = new AssaultSpawnCount
		thisCount.SpawnActor = akAttackerType
		thisCount.iCount = aiSpawnAttackers
		
		SpawnMe.Add(thisCount)
	endif
	
	return SetupAttackersV2(aiReserveID, aAttackingFaction, aSpawnAttackers = SpawnMe, aOtherAttackers = aOtherAttackers)
EndFunction

Bool Function SetupAttackersV2(int aiReserveID, Faction aAttackingFaction = None, AssaultSpawnCount[] aSpawnAttackers = None, RefCollectionAlias aOtherAttackers = None)
	Quest kQuestRef = FindAssaultQuest(aiReserveID)
	
	if( ! kQuestRef)
		return false
	endif
	
	WorkshopFramework:AssaultSettlement asAssaultQuest = kQuestRef as WorkshopFramework:AssaultSettlement
		
	if(asAssaultQuest)
		if(aSpawnAttackers == None)
			asAssaultQuest.SpawnAttackerCounts = None
		else
			asAssaultQuest.SpawnAttackerCounts = (aSpawnAttackers as Var[]) as AssaultSpawnCount[]
		endif
		
		asAssaultQuest.OtherAttackers = aOtherAttackers
		asAssaultQuest.AttackingFaction = aAttackingFaction
	else
		return false
	endif
	
	return true
EndFunction

Bool Function SetupDefenders(int aiReserveID, Faction aDefendingFaction = None, ActorBase akDefenderType = None, Int aiSpawnDefenders = 0, RefCollectionAlias aOtherDefenders = None)
	AssaultSpawnCount[] SpawnMe = new AssaultSpawnCount[0]
	if(akDefenderType != None)
		AssaultSpawnCount thisCount = new AssaultSpawnCount
		thisCount.SpawnActor = akDefenderType
		thisCount.iCount = aiSpawnDefenders
		
		SpawnMe.Add(thisCount)
	endif
	
	return SetupDefendersV2(aiReserveID, aDefendingFaction = None, aSpawnDefenders = SpawnMe, aOtherDefenders = aOtherDefenders)
EndFunction

Bool Function SetupDefendersV2(int aiReserveID, Faction aDefendingFaction = None, AssaultSpawnCount[] aSpawnDefenders = None, RefCollectionAlias aOtherDefenders = None)
	Quest kQuestRef = FindAssaultQuest(aiReserveID)
	
	if( ! kQuestRef)
		return false
	endif
	
	WorkshopFramework:AssaultSettlement asAssaultQuest = kQuestRef as WorkshopFramework:AssaultSettlement
		
	if(asAssaultQuest)
		if(aSpawnDefenders == None)
			asAssaultQuest.SpawnDefenderCounts = None
		else
			asAssaultQuest.SpawnDefenderCounts = (aSpawnDefenders as Var[]) as AssaultSpawnCount[]
		endif
		
		asAssaultQuest.OtherDefenders = aOtherDefenders
		asAssaultQuest.DefendingFaction = aDefendingFaction
	else
		return false
	endif
	
	return true
EndFunction

Bool Function ForceComplete(int aiReserveID, Bool abAttackersWin = true)
	Quest kQuestRef = FindAssaultQuest(aiReserveID)
	
	if( ! kQuestRef)
		return false
	endif
	
	WorkshopFramework:AssaultSettlement asAssaultQuest = kQuestRef as WorkshopFramework:AssaultSettlement
		
	if(asAssaultQuest)
		asAssaultQuest.ForceComplete(abAttackersWin)
	else
		return false
	endif
	
	return true
EndFunction


; To be called by Assault quests themselves
Function AssaultStarted_Private(Quest akSenderRef, ObjectReference akWorkshopRef, Int aiAssaultType, Faction akAttackingFaction, Faction akDefendingFaction)
	Var[] kArgs = new Var[6]
	kArgs[0] = akSenderRef
	
	int iRunningIndex = RunningQuests.FindStruct("kQuestRef", akSenderRef)
	int iReserveID = -1
	
	if(iRunningIndex >= 0)
		iReserveID = RunningQuests[iRunningIndex].iReserveID
	endif
	
	kArgs[1] = iReserveID
	kArgs[2] = akWorkshopRef
	kArgs[3] = aiAssaultType
	kArgs[4] = akAttackingFaction
	kArgs[5] = akDefendingFaction
		
	SendCustomEvent("AssaultStarted", kArgs)
EndFunction


; To be called by Assault quests themselves
Function AssaultCompleted_Private(Quest akSenderRef, ObjectReference akWorkshopRef, Int aiAssaultType, Faction akAttackingFaction, Faction akDefendingFaction, Bool abPlayerSideWon)
	Var[] kArgs = new Var[7]
	kArgs[0] = akSenderRef
	
	int iRunningIndex = RunningQuests.FindStruct("kQuestRef", akSenderRef)
	int iReserveID = -1
	
	if(iRunningIndex >= 0)
		iReserveID = RunningQuests[iRunningIndex].iReserveID
		
		RunningQuests[iRunningIndex].bCompleteEventFired = true
	endif
	
	kArgs[1] = iReserveID
	kArgs[2] = akWorkshopRef
	kArgs[3] = aiAssaultType
	kArgs[4] = akAttackingFaction
	kArgs[5] = akDefendingFaction
	kArgs[6] = abPlayerSideWon
		
	SendCustomEvent("AssaultCompleted", kArgs)
EndFunction


; To be called by Assault quests themselves, or will be called internally if the assault is shut down without calling AssaultCompleted_Private
Function AssaultStopped_Private(Quest akSenderRef)
	Var[] kArgs = new Var[2]
	kArgs[0] = akSenderRef
	
	int iRunningIndex = RunningQuests.FindStruct("kQuestRef", akSenderRef)
	int iReserveID = -1
	
	if(iRunningIndex >= 0)
		iReserveID = RunningQuests[iRunningIndex].iReserveID
	endif
	
	kArgs[1] = iReserveID
	
	SendCustomEvent("AssaultStopped", kArgs)
EndFunction

; 2.3.5 - New event
Function AssaultFirstBlood_Private(Quest akSenderRef)
	Var[] kArgs = new Var[2]
	kArgs[0] = akSenderRef
	
	int iRunningIndex = RunningQuests.FindStruct("kQuestRef", akSenderRef)
	int iReserveID = -1
	
	if(iRunningIndex >= 0)
		iReserveID = RunningQuests[iRunningIndex].iReserveID
	endif
	
	kArgs[1] = iReserveID
	
	SendCustomEvent("AssaultFirstBlood", kArgs)
EndFunction

; 2.3.4 To be called by Assault quests themselves
Function AssaultAttackersDown_Private(Quest akSenderRef)
	Var[] kArgs = new Var[2]
	kArgs[0] = akSenderRef
	
	int iRunningIndex = RunningQuests.FindStruct("kQuestRef", akSenderRef)
	int iReserveID = -1
	
	if(iRunningIndex >= 0)
		iReserveID = RunningQuests[iRunningIndex].iReserveID
	endif
	
	kArgs[1] = iReserveID
	
	SendCustomEvent("AssaultAttackersDown", kArgs)
EndFunction

; 2.3.4 To be called by Assault quests themselves
Function AssaultDefendersDown_Private(Quest akSenderRef)
	Var[] kArgs = new Var[2]
	kArgs[0] = akSenderRef
	
	int iRunningIndex = RunningQuests.FindStruct("kQuestRef", akSenderRef)
	int iReserveID = -1
	
	if(iRunningIndex >= 0)
		iReserveID = RunningQuests[iRunningIndex].iReserveID
	endif
	
	kArgs[1] = iReserveID
	
	SendCustomEvent("AssaultDefendersDown", kArgs)
EndFunction


Quest Function FindAssaultQuest(Int aiReserveID)
	int iRunningIndex = RunningQuests.FindStruct("iReserveID", aiReserveID)
	
	if(iRunningIndex >= 0)
		return RunningQuests[iRunningIndex].kQuestRef
	endif
	
	return None
EndFunction


Bool Function IsSettlementInvolvedInAssault(WorkshopScript akWorkshopRef)
	int i = 0
	while(i < RunningQuests.Length)
		WorkshopFramework:AssaultSettlement asAssaultQuest = RunningQuests[i].kQuestRef as WorkshopFramework:AssaultSettlement
		
		if(asAssaultQuest)
			if(asAssaultQuest.WorkshopAlias.GetRef() == akWorkshopRef)
				return true
			endif
		endif
		
		i += 1
	endWhile
	
	return false
EndFunction