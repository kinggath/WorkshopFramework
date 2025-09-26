; ---------------------------------------------
; WorkshopFramework:AssaultSettlement.psc - by kinggath
; ---------------------------------------------
; Reusage Rights ------------------------------
; You are free to use this script or portions of it in your own mods, provided you give me credit in your description and maintain this section of comments in any released source code (which includes the IMPORTED SCRIPT CREDIT section to give credit to anyone in the associated Import scripts below.
; 
; IMPORTED SCRIPT CREDIT
; N/A
; ---------------------------------------------

Scriptname WorkshopFramework:AssaultSettlement extends Quest Conditional

import WorkshopFramework:Library:DataStructures
import WorkshopFramework:Library:UtilityFunctions
import WorkshopFramework:WorkshopFunctions

; -------------------------------------------
; Consts
; -------------------------------------------

int Property iStage_Setup = 10 autoReadOnly
int Property iStage_Ready = 20 autoReadOnly
int Property iStage_PlayerArrived = 25 autoReadOnly
int Property iStage_AttackStartedByCombat = 26 autoReadOnly
int Property iStage_Started = 30 autoReadOnly
int Property iStage_TriggerAI = 40 autoReadOnly
int Property iStage_FirstDown = 50 autoReadOnly
int Property iStage_MostEnemiesDown = 60 autoReadOnly
int Property iStage_AllEnemiesSubdued = 61 autoReadOnly
int Property iStage_AllEnemiesDead = 62 autoReadOnly
int Property iStage_MostAlliesDown = 65 autoReadOnly
int Property iStage_AllAlliesDown = 70 autoReadOnly
int Property iStage_EnemiesDown = 75 autoReadOnly

int Property iStage_AutoComplete = 80 autoReadOnly
int Property iStage_NoVictor = 85 autoReadOnly

int Property iStage_Failed = 90 autoReadOnly
int Property iStage_Success = 100 autoReadOnly

int Property iStage_Shutdown = 1000 autoReadOnly

Int Property iObjectiveSet_Defend = 1 autoReadOnly
Int Property iObjectiveSet_Wipeout = 2 autoReadOnly
Int Property iObjectiveSet_Subdue = 3 autoReadOnly

int Property iTimerID_AutoRunSetup = 100 autoReadOnly
int Property iTimerID_Shutdown = 101 autoReadOnly
int Property iTimerID_AutoComplete = 102 autoReadOnly
int Property iTimerID_FailsafeNoSetup = 103 autoReadOnly
int Property iTimerID_EnemyMonitor = 104 autoReadOnly ; Added in 1.1.10 to periodically double-check if all enemies are dealt with in case an alias death script fails to register

float Property fTimerLength_AutoRunSetup = 30.0 autoReadOnly ; If it takes longer than this, the requesting script can cancel the timer and call SetupAssault manually
float Property fTimerLength_Shutdown = 10.0 autoReadOnly ; This is just designed to give other scripts a chance to react to the results before the aliases are cleared
float Property fTimerLength_FailsafeNoSetup = 300.0 autoReadOnly ; After 5 minutes, quests are considered abandoned and shut down
float Property fTimerLength_EnemyMonitor = 45.0 autoReadOnly

String sLogName = "WSFWAssault" Const
; -------------------------------------------
; Editor Properties
; -------------------------------------------

Group Controllers
	WorkshopFramework:WorkshopControlManager Property ControlManager Auto Const Mandatory
	WorkshopFramework:AssaultManager Property AssaultManager Auto Const Mandatory
	WorkshopFramework:NPCManager Property NPCManager Auto Const Mandatory
	WorkshopFramework:WorkshopResourceManager Property ResourceManager Auto Const Mandatory
	WorkshopParentScript Property WorkshopParent Auto Const Mandatory
EndGroup


Group ActorValues
	ActorValue Property SiegeAV Auto Const Mandatory
	{ Special AV to provide attackers with a bonus against defenses during an attack }
	ActorValue Property AttackAIAV Auto Const Mandatory
EndGroup


Group Aliases
	LocationAlias Property TargetLocationAlias Auto Const Mandatory
	ReferenceAlias Property VerbAlias Auto Const Mandatory
	ReferenceAlias Property PlayerAlias Auto Const Mandatory
	ReferenceAlias Property AttackFromAlias Auto Const Mandatory
	{ Attackers will be moved to or spawned here }
	ReferenceAlias Property DefendFromAlias Auto Const Mandatory
	{ Defenders will be moved to or spawned here. }
	ReferenceAlias Property MapMarkerAlias Auto Const Mandatory
	ReferenceAlias Property WorkshopAlias Auto Const Mandatory
	ReferenceAlias Property CenterMarkerAlias Auto Const Mandatory
	
	RefCollectionAlias Property KillToComplete Auto Const Mandatory
	RefCollectionAlias Property SubdueToComplete Auto Const Mandatory
	RefCollectionAlias Property PlayerAllies Auto Const Mandatory
	RefCollectionAlias Property PlayerEnemies Auto Const Mandatory
	
	RefCollectionAlias Property StartingAttackers Auto Const Mandatory
	RefCollectionAlias Property StartingDefenders Auto Const Mandatory
	RefCollectionAlias Property ReinforcementAttackers Auto Const Mandatory
	RefCollectionAlias Property ReinforcementDefenders Auto Const Mandatory
	
	RefCollectionAlias Property Defenders Auto Const Mandatory
	{ Actually points to RemainingDefenders, which are removed as they are killed (Defenders is a bad name, but don't want to risk breaking other mods). If you need access to all defenders, including dead ones, check the PlayerEnemies or PlayerAllies aliases, depending on bPlayerIsEnemy setting. }
	RefCollectionAlias Property Attackers Auto Const Mandatory
	
	RefCollectionAlias Property SpawnedAttackersAlias Auto Const Mandatory
	RefCollectionAlias Property SpawnedDefendersAlias Auto Const Mandatory
	
	RefCollectionAlias Property AttackerFactionAlias Auto Const Mandatory
	RefCollectionAlias Property DefenderFactionAlias Auto Const Mandatory
	
	ReferenceAlias Property SettlementLeader Auto Const Mandatory
	RefCollectionAlias Property Settlers Auto Const Mandatory
	RefCollectionAlias Property Synths Auto Const Mandatory
	RefCollectionAlias Property NonSpeakingSettlers Auto Const Mandatory
	RefCollectionAlias Property Robots Auto Const Mandatory
	RefCollectionAlias Property Children Auto Const Mandatory
EndGroup

Group Factions
	Faction Property AssaultAttackersFaction Auto Const Mandatory
	Faction Property AssaultDefendersFaction Auto Const Mandatory
	Faction Property ActivateAIFaction Auto Const Mandatory
	Faction Property WorkshopCaravanFaction Auto Const Mandatory ; 1.1.3
	Faction Property WorkshopNPCFaction Auto Const Mandatory ; 1.1.3
	Faction Property CaptiveFaction Auto Const Mandatory ; 1.1.3
EndGroup

Group Keywords
	Keyword Property BleedoutRecoveryStopped Auto Const Mandatory
	Keyword Property WorkshopItemKeyword Auto Const Mandatory
	Keyword Property ProtectedStatusRemoved Auto Const Mandatory ; 1.1.1
	Keyword Property WorkshopLinkHome Auto Const Mandatory ;2.0.1
	Keyword Property WorkshopLinkSpawn Auto Const Mandatory ;2.3.11
	Keyword Property ForceSubdueDuringAssaultTagKeyword Auto Const Mandatory ;2.3.8
	
	LocationRefType Property MapMarkerRefType Auto Const Mandatory ; 2.3.4
EndGroup


Group Settings
	Bool Property bPlayerInvolved = true Auto Const
	{ If true, the player will be immediately included in the appropriate factions to be part of combat. }
EndGroup

; -------------------------------------------
; Dynamic Properties
; -------------------------------------------

Float Property fPlayerArriveDistance = 500.0 Auto Hidden

; -------------------------------------------
; Vars
; -------------------------------------------

Bool Property bDisabledMapMarker = false Auto Hidden
Int Property iReserveID = -1 Auto Hidden
Int Property iCurrentAssaultType = -1 Auto Hidden Conditional

Function UpdateCurrentAssaultType(Int aiType)
	iCurrentAssaultType = aiType
EndFunction

Int Property iObjectiveSet = 0 Auto Hidden

; Prep variables
Bool Property bAutoShutdownQuest = true Auto Hidden
Bool Property bDisableFastTravel = true Auto Hidden
Bool Property bSettlersAreDefenders = true Auto Hidden
Bool Property bRobotsAreDefenders = true Auto Hidden
Bool Property bAutoStartAssaultOnLoad = true Auto Hidden
Bool Property bAutoStartAssaultWhenPlayerReachesAttackFrom = true Auto Hidden
Bool Property bMoveAttackersToStartPoint = true Auto Hidden
Bool Property bMoveDefendersToCenterPoint = true Auto Hidden
Bool Property bAttackersDeadFailsAssault = true Auto Hidden
Bool Property bGuardsKillableEvenOnSubdue = false Auto Hidden ; Non-settler NPCs
Bool Property bAttackersKillableEvenOnSubdue = false Auto Hidden
Bool Property bAlwaysSubdueUniques = true Auto Hidden
Bool Property bAutoHandleObjectives = true Auto Hidden
Int Property iOverrideObjectiveSet = -1 Auto Hidden ; 2.3.6
Bool Property bAutoCaptureSettlement = false Auto Hidden
Bool Property bChildrenFleeDuringAttack = true Auto Hidden
Bool Property bAutoTurnTargetSettlementAgainstPlayer = true Auto Hidden ; 2.3.10
Bool Property bAutoAttemptToPreventEnemiesUnderTheWorld = true Auto Hidden ; 2.4.7

Bool Property bAutoCompleteAssaultWhenOneSideIsDown = true Auto Hidden

Bool Property bForceDefendersKillable = false Auto Hidden ; 1.1.1
Bool Property bForceAttackersKillable = false Auto Hidden ; 1.1.1

; Auto complete conditions
Float Property fAutoEndTime = 2.0 Auto Hidden
Bool Property bAutoCalculateVictor = true Auto Hidden
ActorValue Property FighterStrengthAV = None Auto Hidden
Bool Property bDamageDefenses = true Auto Hidden
Bool Property bKillCombatants = false Auto Hidden
Float Property fMaxAttackerCasualtyPercentBeforeRetreat = 1.0 Auto Hidden
Float Property fMaxDefenderCasualtyPercentBeforeSurrender = 1.0 Auto Hidden

; Capture settings if attackers win
FactionControl Property AttackingFactionData = None Auto Hidden
Bool Property bSeverEnemySupplyLines = true Auto Hidden
Bool Property bRemoveEnemySettlers = true Auto Hidden
Bool Property bKillEnemySettlers = false Auto Hidden
Bool Property bCaptureTurrets = true Auto Hidden
Bool Property bCaptureContainers = true Auto Hidden
Bool Property bSettlersJoinFaction = false Auto Hidden
Bool Property bTogglePlayerOwnership = false Auto Hidden
Bool Property bPlayerIsEnemy = false Auto Hidden
Int Property iCreateInvadingSettlers = -1 Auto Hidden

	; Attackers
AssaultSpawnCount[] Property SpawnAttackerCounts Auto Hidden ; 2.1.2 - Replacing SpawnAttackerForm and iSpawnAttackers

ActorBase Property SpawnAttackerForm Auto Hidden ; 2.1.2 - Maintaining for backward compatibility
Int Property iSpawnAttackers = 0 Auto Hidden ; 2.1.2 - Maintaining for backward compatibility This number of SpawnAttackerForm will be created
RefCollectionAlias Property OtherAttackers Auto Hidden ; collection from another quest of additional attackers
Faction Property AttackingFaction Auto Hidden

	; Defenders
AssaultSpawnCount[] Property SpawnDefenderCounts Auto Hidden ; 2.1.2 - Replacing SpawnDefenderForm and iSpawnDefenders

ActorBase Property SpawnDefenderForm Auto Hidden ; 2.1.2 - Maintaining for backward compatibility
Int Property iSpawnDefenders = 0 Auto Hidden ; 2.1.2 - Maintaining for backward compatibility  This number of SpawnDefenderForm will be created
RefCollectionAlias Property OtherDefenders Auto Hidden ; collection from another quest of additional guards
Faction Property DefendingFaction Auto Hidden

	; Cleanup
Bool Property bSurvivingSpawnedAttackersMoveIn = false Auto Hidden
Bool Property bSurvivingSpawnedDefendersRemain = false Auto Hidden
Bool Property bEnemySurvivorsRemainEnemyToPlayer = true Auto Hidden


Bool Property bFirstBloodSent = false Auto Hidden
Bool Property bReinforcementsPhase = false Auto Hidden

; TODO: Currently using just one faction for attack and one for defense means that if we ever have two opposing attacks (one with the player attacking and one with the player defending) happening simultaneously, the factions will be incorrectly matched. Likely need a different solution to this for aggression against the player.

; -------------------------------------------
; Events
; -------------------------------------------

Event OnStoryScript(Keyword akKeyword, Location akLocation, ObjectReference akRef1, ObjectReference akRef2, int aiValue1, int aiValue2)
	; akRef1 = Verb
	; aiValue1 = Type 
	; aiValue2 = ReserveID
	Debug.OpenUserLog(sLogName)
	
	iLastStageSet = -1
	fLastStageSetTimestamp = 0.0
	
	if(akRef1 != None)
		VerbAlias.ForceRefTo(akRef1)
	endif
	
	UpdateCurrentAssaultType(aiValue1)
	iReserveID = aiValue2
	
	ObjectReference kDefendFromRef = DefendFromAlias.GetRef()
	ObjectReference kWorkshopRef = WorkshopAlias.GetRef()
	
	if(kDefendFromRef == kWorkshopRef || kDefendFromRef == None)
		kDefendFromRef = GetFallbackDefendFromRef()
		DefendFromAlias.ForceRefTo(kDefendFromRef)
	endif
	
	SetStage(iStage_Setup)
	
	StartTimer(fTimerLength_AutoRunSetup, iTimerID_AutoRunSetup)
	StartTimer(fTimerLength_FailsafeNoSetup, iTimerID_FailsafeNoSetup)
EndEvent


Event OnTimer(Int aiTimerID)
	if(aiTimerID == iTimerID_EnemyMonitor)
		if( ! GetStageDone(iStage_EnemiesDown) || bReinforcementsPhase)
			if(CheckForEnemiesDown())
				if( ! GetStageDone(iStage_EnemiesDown))
					SetStage(iStage_EnemiesDown)
				else
					; Run the handling code to fire off events and objective updates again
					HandleAllEnemiesDown()
				endif
				
				if(bReinforcementsPhase) ; Keep running monitor until quest is stopped
					RunEnemyMonitor()
				endif
			else
				RunEnemyMonitor()
			endif
		endif
	elseif(aiTimerID == iTimerID_AutoRunSetup)
		SetupAssault()
	elseif(aiTimerID == iTimerID_Shutdown)
		SetStage(iStage_Shutdown)
	elseif(aiTimerID == iTimerID_FailsafeNoSetup)
		if( ! GetStageDone(iStage_Ready))
			SetStage(iStage_Shutdown)
		endif
	endif
EndEvent


Event OnTimerGameTime(Int aiTimerID)
	if(aiTimerID == iTimerID_AutoComplete)
		SetStage(iStage_AutoComplete)
	endif
EndEvent


Int iLastStageSet = -1
Float fLastStageSetTimestamp = 0.0

Event OnStageSet(Int aiStageID, Int aiItemID)
	ModTraceCustom(sLogName, Self + ".OnStageSet(" + aiStageID + ", " + aiItemID + ")")
	Float fCurrentTime = Utility.GetCurrentRealTime()
	if(aiStageID == iLastStageSet)
		if(fCurrentTime < fLastStageSetTimestamp + 2.0) ; 2 second buffer
			; This stage just triggered, let's not rapidly repeat it
			ModTraceCustom(sLogName, Self + ".OnStageSet stage " + aiStageID + " was just triggered, preventing from repeating immediately.")
			
			return
		endif
	else
		iLastStageSet = aiStageID
		fLastStageSetTimestamp = fCurrentTime
	endif
	
	if(aiStageID == iStage_Ready)
		if(fAutoEndTime > 0)
			StartTimerGameTime(fAutoEndTime, iTimerID_AutoComplete)
		endif
		
		if(bPlayerInvolved)
			Actor PlayerRef = PlayerAlias.GetActorRef()
			if(iCurrentAssaultType != AssaultManager.iType_Defend)
				ObjectReference kAttackFrom = AttackFromAlias.GetRef()
				if(kAttackFrom.HasRefType(MapMarkerRefType))
					ObjectReference kLinkedHeadingRef = kAttackFrom.GetLinkedRef()
					if(kLinkedHeadingRef != None)
						kAttackFrom = kLinkedHeadingRef
					endif
				endif
				
				if(PlayerRef.GetDistance(kAttackFrom) < fPlayerArriveDistance)
					SetStage(iStage_PlayerArrived)
				else
					RegisterForDistanceLessThanEvent(PlayerRef, kAttackFrom, fPlayerArriveDistance)
				endif
				
				AttackerFactionAlias.AddRef(PlayerRef)
			else
				DefenderFactionAlias.AddRef(PlayerRef)
			endif
			
			TriggerInitialObjectives()
		endif
	elseif(aiStageID == iStage_AttackStartedByCombat)
		; Combat started because player attacked settlement without meeting up, or the NPCs started combat before the player reached them - so we need to trigger the player arrived event and trigger the assault to start
		
		SetStage(iStage_PlayerArrived)
		StartAssault()
	elseif(aiStageID == iStage_PlayerArrived)
		if(bAutoHandleObjectives)
			TriggerPlayerInvolvedObjectives()
		endif
		
		if(bAutoStartAssaultWhenPlayerReachesAttackFrom)
			StartAssault()
		endif
	elseif(aiStageID == iStage_TriggerAI)
		StartAIPackages()
		
		; 1.1.1 - Allow clearing protected status on NPCs
		if(bForceAttackersKillable)
			ClearProtectedStatusOnRefCollection(Attackers)
		endif
		
		if(bForceDefendersKillable)
			ClearProtectedStatusOnRefCollection(Defenders)
		endif
		
		; 1.1.10 - Loop a timer to ensure enemy deaths are caught
		RunEnemyMonitor()
	elseif(aiStageID == iStage_FirstDown)
		if( ! bFirstBloodSent)
			bFirstBloodSent = true
			
			; Only send event once
			AssaultManager.AssaultFirstBlood_Private(Self)
		endif
	elseif(aiStageID == iStage_MostEnemiesDown)
		if(bAutoHandleObjectives)
			if(iObjectiveSet == iObjectiveSet_Defend)
				SetObjectiveDisplayed(17, false)
				
				if(IsObjectiveDisplayed(30))
					; Reinforcements
					SetObjectiveDisplayed(32) ; Remaining attackers
				else
					if( ! IsObjectiveDisplayed(22))
						SetObjectiveDisplayed(22) ; Remaining attackers
					endif
				endif
			elseif(iObjectiveSet == iObjectiveSet_Subdue)
				SetObjectiveDisplayed(16, false)
				
				if(IsObjectiveDisplayed(30))
					; Reinforcements
					SetObjectiveDisplayed(31) ; Remaining defenders (kill reinforcements)
				else
					if( ! IsObjectiveDisplayed(21))
						SetObjectiveDisplayed(21) ; Subdue Remaining defenders
					endif
				endif
				
				if( ! IsObjectiveDisplayed(21))
					SetObjectiveDisplayed(21)
				endif
			else
				SetObjectiveDisplayed(15, false)
				
				if(IsObjectiveDisplayed(30))
					; Reinforcements
					SetObjectiveDisplayed(31) ; Remaining defenders
				else
					if( ! IsObjectiveDisplayed(20))
						SetObjectiveDisplayed(20) ; Remaining defenders
					endif
				endif
			endif
		endif
	elseif(aiStageID == iStage_AllEnemiesSubdued)
		if(GetStageDone(iStage_AllEnemiesDead) || KillToComplete.GetCount() == 0)
			SetStage(iStage_EnemiesDown)
		endif
	elseif(aiStageID == iStage_AllEnemiesDead)
		if(GetStageDone(iStage_AllEnemiesSubdued) || SubdueToComplete.GetCount() == 0)
			SetStage(iStage_EnemiesDown)
		endif
	elseif(aiStageID == iStage_EnemiesDown)
		HandleAllEnemiesDown()
	elseif(aiStageID == iStage_AllAlliesDown)
		if(bAutoHandleObjectives)
			; Hide objective to finish handling enemies so that if reinforcements are triggered their locations aren't immediately revealed
			SetObjectiveDisplayed(20, false)
			SetObjectiveDisplayed(21, false)
			SetObjectiveDisplayed(22, false)
		endif
		
		if(iCurrentAssaultType == AssaultManager.iType_Defend)
			AssaultManager.AssaultDefendersDown_Private(Self)
			
			if(bAutoCompleteAssaultWhenOneSideIsDown)
				SetStage(iStage_Failed)
			endif
		else
			AssaultManager.AssaultAttackersDown_Private(Self)
			
			if(bAutoCompleteAssaultWhenOneSideIsDown && bAttackersDeadFailsAssault)
				SetStage(iStage_Failed)
			endif
		endif
	elseif(aiStageID == iStage_Failed)
		FailAllObjectives()
		
		AssaultManager.AssaultCompleted_Private(Self, WorkshopAlias.GetRef(), iCurrentAssaultType, AttackingFaction, DefendingFaction, false)
		
		StopAllCombat()
		ConfigureTurrets(abMakeDefenders = false)
		StopAllCombat()	
		
		if(iCurrentAssaultType == AssaultManager.iType_Defend)
			ProcessCapture()
		endif
		
		if(bAutoShutdownQuest)
			StartTimer(fTimerLength_Shutdown, iTimerID_Shutdown)
		endif
	elseif(aiStageID == iStage_Success)
		CompleteAllObjectives()		
			
		AssaultManager.AssaultCompleted_Private(Self, WorkshopAlias.GetRef(), iCurrentAssaultType, AttackingFaction, DefendingFaction, true)
		
		StopAllCombat()		
		ConfigureTurrets(abMakeDefenders = false)
		StopAllCombat()	
		
		if(iCurrentAssaultType != AssaultManager.iType_Defend)
			ProcessCapture()
		endif
		
		if(bPlayerInvolved)
			CompleteQuest()
		endif
		
		if(bAutoShutdownQuest)
			StartTimer(fTimerLength_Shutdown, iTimerID_Shutdown)
		endif
	elseif(aiStageID == iStage_NoVictor)
		; Ended without a victor
		StopAllCombat()
		ConfigureTurrets(abMakeDefenders = false)
		AssaultManager.AssaultStopped_Private(Self)
		
		if(bAutoShutdownQuest)
			StartTimer(fTimerLength_Shutdown, iTimerID_Shutdown)
		endif
	elseif(aiStageID == iStage_AutoComplete)
		TryToAutoResolveAssault()
	elseif(aiStageID == iStage_Shutdown)
		UnregisterForAllEvents()
		
		CleanupAssault() ; Need to do this before actual shutdown is called or the aliases won't be full and certain functions (such as RestoreBleedoutRecovery) won't run correctly
		
		Stop()
	endif
EndEvent


Event OnDistanceLessThan(ObjectReference akObj1, ObjectReference akObj2, float afDistance)
	SetStage(iStage_PlayerArrived)
	
	UnregisterForDistanceEvents(akObj1, akObj2) 
EndEvent


Event OnQuestShutdown()
	UnregisterForAllEvents()
	
	CleanupAssault()
	
	Reset() ; 1.1.1 - Reset quest to clear objectives from pipboy
EndEvent

Event Location.OnLocationLoaded(Location akLocationRef)
	if(bAutoStartAssaultOnLoad)
		StartAssault()
	endif
EndEvent

; ------------------------------------------- 
; Functions
; -------------------------------------------

Int Function GetReserveID()
	return iReserveID
EndFunction


Function ForceComplete(Bool abAttackersWin = true)
	ModTraceCustom(sLogName, Self + ".ForceComplete(abAttackersWin = " + abAttackersWin + ")")
	if(iCurrentAssaultType == AssaultManager.iType_Defend)
		if( ! abAttackersWin && TryToMarkSuccessful())
			return
		endif
	else
		if(abAttackersWin && TryToMarkSuccessful())
			return
		endif
	endif
	
	SetStage(iStage_Failed)
EndFunction

Function SwitchToReinforcementObjectives()
	; Turn off the kill/subdue objectives and display reinforcement
	if(iObjectiveSet == iObjectiveSet_Defend)
		SetObjectiveDisplayed(22, false)
		SetObjectiveDisplayed(30)
	elseif(iObjectiveSet == iObjectiveSet_Subdue)		
		SetObjectiveDisplayed(21, false)
		SetObjectiveDisplayed(30)
	else
		SetObjectiveDisplayed(20, false)
		SetObjectiveDisplayed(30)
	endif
	
	bReinforcementsPhase = true
	RunEnemyMonitor()
EndFunction

Function HandleAllEnemiesDown()
	ModTraceCustom(sLogName, Self + "HandleAllEnemiesDown()")
	if(bAutoHandleObjectives)
		; Hide objective to finish handling enemies so that if reinforcements are triggered their locations aren't immediately revealed
		SetObjectiveDisplayed(20, false)
		SetObjectiveDisplayed(21, false)
		SetObjectiveDisplayed(22, false)
	endif
	
	if(iCurrentAssaultType == AssaultManager.iType_Defend)
		AssaultManager.AssaultAttackersDown_Private(Self)
	else
		AssaultManager.AssaultDefendersDown_Private(Self)
	endif
	
	if(bAutoCompleteAssaultWhenOneSideIsDown)
		ModTraceCustom(sLogName, Self + " bAutoCompleteAssaultWhenOneSideIsDown = true, calling TryToMarkSuccessful")
		TryToMarkSuccessful()			
	endif
EndFunction


Bool Function TryToMarkSuccessful()
	ModTraceCustom(sLogName, Self + "TryToMarkSuccessful()")
	if(GetStageDone(iStage_Success))
		; Already succeeded
		return true
	endif
	
	if( ! GetStageDone(iStage_Failed))
		SetStage(iStage_Success)
		
		return true
	endif
	
	return false
EndFunction


Function SetupAssault()
	CancelTimer(iTimerID_AutoRunSetup)
	
	; Setup map marker and fast travel
	SetupMapMarker(true)
		
	ObjectReference kDefendFromRef = DefendFromAlias.GetRef()
	WorkshopScript kWorkshopRef = None
	int iWorkshopID = -1
	if(WorkshopAlias != None)
		WorkshopAlias.GetRef() as WorkshopScript
		
		if(kWorkshopRef != None)
			iWorkshopID = kWorkshopRef.GetWorkshopID()
		endif
	endif
	
	; Add settlers to aliases
	if(bSettlersAreDefenders)
		RemoveInvalidSettlers() ; 1.1.3
		
		Actor[] PermanentSettlers = new Actor[0]
		RefCollectionAlias PermanentActorAliases = WorkshopParent.PermanentActorAliases
		int i = 0
		while(i < PermanentActorAliases.GetCount())
			Actor thisActor = PermanentActorAliases.GetAt(i) as Actor
			if(thisActor != None && GetWorkshopID(thisActor) == iWorkshopID)
				PermanentSettlers.Add(thisActor)
			endif
			
			i += 1
		endWhile
		
		if(PermanentSettlers.Length > 0)
			Defenders.AddArray(PermanentSettlers as ObjectReference[])
			DefenderFactionAlias.AddArray(PermanentSettlers as ObjectReference[])
		endif
		
		Defenders.AddRefCollection(Settlers)
		ClearCaravanNPCsFromDefenders() ; 1.1.3
		DefenderFactionAlias.AddRefCollection(Settlers)
		Defenders.AddRefCollection(NonSpeakingSettlers)
		DefenderFactionAlias.AddRefCollection(NonSpeakingSettlers)
		Defenders.AddRefCollection(Synths)
		DefenderFactionAlias.AddRefCollection(Synths)
		
		Actor kLeaderRef = SettlementLeader.GetRef() as Actor
		
		if(kLeaderRef && kLeaderRef.IsInFaction(WorkshopNPCFaction) && ! kLeaderRef.IsInFaction(CaptiveFaction)) ; 1.1.3
			if( ! kLeaderRef.IsInFaction(WorkshopCaravanFaction)) ; 1.1.3
				; Since the caravan driver might be away, we don't want the player to have to count on them being their in order to finish the raid
				Defenders.AddRef(kLeaderRef)
			endif
		
			DefenderFactionAlias.AddRef(kLeaderRef)
		endif
		
		if(iCurrentAssaultType == AssaultManager.iType_Defend)
			; Make sure defenders stay subdued after bleeding out
			if( ! bForceDefendersKillable)
				PreventCollectionBleedoutRecovery(Defenders)
			endif
		else
			AddCollectionToCompleteAliases(Settlers, abDefenders = true)
			AddCollectionToCompleteAliases(NonSpeakingSettlers, abDefenders = true)
			AddCollectionToCompleteAliases(Synths, abDefenders = true)
			
			if(kLeaderRef && ! kLeaderRef.IsInFaction(CaptiveFaction))
				if(kLeaderRef.IsInFaction(WorkshopNPCFaction) && (ShouldForceSubdue(kLeaderRef) || iCurrentAssaultType == AssaultManager.iType_Attack_Subdue))
					SubdueToComplete.AddRef(kLeaderRef)
					KillToComplete.RemoveRef(kLeaderRef)
				else
					ClearProtectedStatus(kLeaderRef)
					KillToComplete.AddRef(kLeaderRef)
					SubdueToComplete.RemoveRef(kLeaderRef)
				endif
			endif
		endif
	endif
	
	; Add robots to aliases
	if(bRobotsAreDefenders && Robots != None)
		Defenders.AddRefCollection(Robots)
		DefenderFactionAlias.AddRefCollection(Robots)
		
		if(iCurrentAssaultType != AssaultManager.iType_Defend)
			AddCollectionToCompleteAliases(Robots, abDefenders = true)
		endif
	endif
	
	if(OtherDefenders)
		Defenders.AddRefCollection(OtherDefenders)
		DefenderFactionAlias.AddRefCollection(OtherDefenders)
		
		if(iCurrentAssaultType != AssaultManager.iType_Defend)
			
			AddCollectionToCompleteAliases(OtherDefenders, abDefenders = true, abGuardNPCs = true)
		endif
	endif	
	
	if( ! DefendingFaction && kWorkshopRef)
		; Use the faction that owns the workshop
		DefendingFaction = kWorkshopRef.ControllingFaction
	endif
	
	if( ! SpawnDefenderForm && kWorkshopRef && kWorkshopRef.FactionControlData != None)
		SpawnDefenderForm = kWorkshopRef.FactionControlData.Guards
	endif
	
	; 2.3.3 Enable any spawned defenders from external sources (they will have been already fed in to our aliases)
	SpawnedDefendersAlias.EnableAll()	
	
	; Spawn extra defenders requested during setup
	if(iSpawnDefenders > 0 && SpawnDefenderForm != None)
		SpawnDefenders(SpawnDefenderForm, iSpawnDefenders, kDefendFromRef)
	endif
	
	if(SpawnDefenderCounts != None)
		int i = 0
		while(i < SpawnDefenderCounts.Length)
			SpawnDefenders(SpawnDefenderCounts[i].SpawnActor, SpawnDefenderCounts[i].iCount, kDefendFromRef)
			
			i += 1
		endWhile
	endif
	
	; Setup attackers outside of the settlement somewhere
	ObjectReference kAttackFrom = AttackFromAlias.GetRef()
	
	; 2.3.3 Move and enable any spawned attackers from external sources (they will have been already fed in to our aliases
	int i = 0
	while(i < SpawnedAttackersAlias.GetCount())
		Actor thisActor = SpawnedAttackersAlias.GetAt(i) as Actor
		if(thisActor)
			thisActor.MoveTo(kAttackFrom)
		endif
		
		i += 1
	endWhile
	
	SpawnedAttackersAlias.EnableAll()
	
	; Spawn extra attackers	requested during setup
	if(iSpawnAttackers > 0 && SpawnAttackerForm != None)
		SpawnAttackers(SpawnAttackerForm, iSpawnAttackers, kAttackFrom)
	endif
	
	if(SpawnAttackerCounts != None)
		i = 0
		while(i < SpawnAttackerCounts.Length)
			SpawnAttackers(SpawnAttackerCounts[i].SpawnActor, SpawnAttackerCounts[i].iCount, kAttackFrom)
			
			i += 1
		endWhile
	endif
	
	
	if(OtherAttackers)
		; Clear attack AI - in case this actor was used in a previous assault
		OtherAttackers.RemoveFromFaction(ActivateAIFaction) 
		Attackers.AddRefCollection(OtherAttackers)
		AttackerFactionAlias.AddRefCollection(OtherAttackers)
		
		if(iCurrentAssaultType == AssaultManager.iType_Defend)
			AddCollectionToCompleteAliases(OtherAttackers)
		else
			i = 0
			int iCount = OtherAttackers.GetCount()
			
			while(i < iCount)
				Actor thisActor = OtherAttackers.GetAt(i) as Actor
				
				if(thisActor)
					; Move OtherAttackers into position
					if(bMoveAttackersToStartPoint)
						thisActor.MoveTo(kAttackFrom)
					endif
				endif
				
				i += 1
			endWhile			
		endif
	endif
		
	; 2.3.5 - Make sure attackers aren't in WorkshopNPCFaction or the settlement's ownership faction or they won't be hostile to defenders
	RemoveSettlementFactionsFromCollection(AttackerFactionAlias)
		
	; 2.3.3 - Storing original attacker/defender sets in unique collections. This is to maintain a copy of the original sets of attackers and defenders without having to check PlayerAllies and PlayerEnemies since we want to eventually support NPC vs NPC assaults
	StartingAttackers.AddRefCollection(Attackers)
	StartingDefenders.AddRefCollection(Defenders)
		
	if(bPlayerInvolved)		
		if(iCurrentAssaultType == AssaultManager.iType_Defend)
			PlayerAllies.AddRefCollection(Defenders)
			PlayerEnemies.AddRefCollection(Attackers)
		else
			PlayerAllies.AddRefCollection(Attackers)
			PlayerEnemies.AddRefCollection(Defenders)
			
			if(kWorkshopRef != None && bAutoTurnTargetSettlementAgainstPlayer)
				; Turn settlement against the player		ControlManager.TurnSettlementAgainstPlayer(kWorkshopRef)
			endif
		endif
		
		; Clear the player enemy application from any allies in case they switched for some reason
		i = 0
		while(i < PlayerAllies.GetCount())
			Actor thisActor = PlayerAllies.GetAt(i) as Actor
			
			if(thisActor)
				AssaultManager.RemainPlayerEnemyCollection.RemoveRef(thisActor)
			endif
			
			i += 1
		endWhile
	endif
		
	if(SubdueToComplete.GetCount() == 0)
		SetStage(iStage_AllEnemiesSubdued)
	else
		; Make sure SubdueToComplete stay down
		PreventCollectionBleedoutRecovery(SubdueToComplete)
	endif
	
	if(KillToComplete.GetCount() == 0)
		SetStage(iStage_AllEnemiesDead)
	endif
	
	SetStage(iStage_Ready)
	
	if(bAutoStartAssaultOnLoad)
		Location thisLocation = TargetLocationAlias.GetLocation()
		if(thisLocation)
			if(thisLocation.IsLoaded())
				StartAssault()
			else
				RegisterForRemoteEvent(thisLocation, "OnLocationLoaded")
			endif
		else
			ModTrace("AssaultSettlement could not find target location. Shutting down...")
			SetStage(iStage_Shutdown)
		endif		
	endif
EndFunction


; 2.1.2 - Refactoring
Function SpawnDefenders(ActorBase aSpawnMe, Int aiSpawnCount, ObjectReference akSpawnAt)
	ModTraceCustom(sLogName, "SpawnDefenders(" + aSpawnMe + ", " + aiSpawnCount + ", " + akSpawnAt + ")")
	int i = 0
	while(i < aiSpawnCount)
		Actor kDefenderRef = akSpawnAt.PlaceActorAtMe(aSpawnMe)
		
		if(kDefenderRef)
			SetupSpawnedDefender(kDefenderRef)
		endif
		
		i += 1
	endWhile
EndFunction

; 2.1.2 - Refactoring
Function SpawnAttackers(ActorBase aSpawnMe, Int aiSpawnCount, ObjectReference akSpawnAt)
	int i = 0
	while(i < aiSpawnCount)
		Actor kAttackerRef = akSpawnAt.PlaceActorAtMe(aSpawnMe)
		
		if(kAttackerRef)
			SetupSpawnedAttacker(kAttackerRef)
		endif
		
		i += 1
	endWhile
EndFunction

; 2.3.3 - Refactoring to separate alias handling from spawning - this will allow callers to handle their own spawning externally
Function SetupSpawnedAttacker(Actor akSpawnedActor, Bool abIsReinforcement = false)
	ModTraceCustom(sLogName, "SetupSpawnedAttacker(" + akSpawnedActor + ", abIsReinforcement = " + abIsReinforcement + ")")
	
	; First call SetupAttacker
	SetupAttacker(akSpawnedActor, abIsReinforcement = abIsReinforcement)
	
	; Add to Spawned alias
	SpawnedAttackersAlias.AddRef(akSpawnedActor)
	
	; Ensure killable
	if(iCurrentAssaultType == AssaultManager.iType_Defend)
		KillToComplete.AddRef(akSpawnedActor)
		SubdueToComplete.RemoveRef(akSpawnedActor) ; Make sure not in both aliases
	else
		ClearProtectedStatus(akSpawnedActor)
	endif
EndFunction


; 2.3.5 - Further refactored SetupSpawnedAttacker so we can use this same setup for other attackers, particularly non-spawned reinforcements
Function SetupAttacker(Actor akAttacker, Bool abIsReinforcement = false)
	ModTraceCustom(sLogName, "SetupAttacker(" + akAttacker + ", abIsReinforcement = " + abIsReinforcement + ")")

	Attackers.AddRef(akAttacker)
	AttackerFactionAlias.AddRef(akAttacker)
	
	; 2.3.5 - Make sure attackers aren't in WorkshopNPCFaction or the settlement's ownership faction or they won't be hostile to defenders
	RemoveSettlementFactions(akAttacker)
	
	if(abIsReinforcement)
		ReinforcementAttackers.AddRef(akAttacker)
		
		if(GetStageDone(iStage_TriggerAI))
			akAttacker.AddToFaction(ActivateAIFaction)
		else
			akAttacker.RemoveFromFaction(ActivateAIFaction) ; In case they were still in that faction from a previous assault
		endif
	else
		StartingAttackers.AddRef(akAttacker)
	endif
	
	if(iCurrentAssaultType == AssaultManager.iType_Defend)
		if(bPlayerInvolved)
			PlayerEnemies.AddRef(akAttacker)
		endif
		
		ModTraceCustom(sLogName, "    Defend assault type, adding attacker to victory condition alias.")
		; Spawned NPCs should just be killed unless unique/essential already
		if(ShouldForceSubdue(akAttacker))
			SubdueToComplete.AddRef(akAttacker)
			KillToComplete.RemoveRef(akAttacker)
		else
			if(abIsReinforcement || ! bAutoStartAssaultWhenPlayerReachesAttackFrom) ; Protected status will be cleared later
				ClearProtectedStatus(akAttacker)
			endif
			
			KillToComplete.AddRef(akAttacker)
			SubdueToComplete.RemoveRef(akAttacker)
		endif
	else
		if(bPlayerInvolved)
			PlayerAllies.AddRef(akAttacker)
		endif
		
		if( ! ShouldForceSubdue(akAttacker))
			ClearProtectedStatus(akAttacker)
		endif
	endif
	
	if(GetStageDone(iStage_TriggerAI))
		akAttacker.AddToFaction(ActivateAIFaction)
	endif
EndFunction


Function SetupSpawnedDefender(Actor akSpawnedActor, Bool abIsReinforcement = false)
	SetupDefender(akSpawnedActor, abIsReinforcement = abIsReinforcement)
	
	SpawnedDefendersAlias.AddRef(akSpawnedActor)
	
	; Ensure killable
	if(iCurrentAssaultType == AssaultManager.iType_Defend)
		ClearProtectedStatus(akSpawnedActor)
	else
		ClearProtectedStatus(akSpawnedActor)
		KillToComplete.AddRef(akSpawnedActor)
		
		SubdueToComplete.RemoveRef(akSpawnedActor) ; Make sure not in both aliases
	endif
EndFunction


Function SetupDefender(Actor akDefender, Bool abIsReinforcement = false)
	Defenders.AddRef(akDefender)
	DefenderFactionAlias.AddRef(akDefender)
	
	if(abIsReinforcement)
		ReinforcementDefenders.AddRef(akDefender)
	else
		StartingDefenders.AddRef(akDefender)
	endif
	
	if(iCurrentAssaultType == AssaultManager.iType_Defend)
		if(bPlayerInvolved)
			PlayerAllies.AddRef(akDefender)
		endif
		
		if( ! ShouldForceSubdue(akDefender))
			ClearProtectedStatus(akDefender)
		endif
	else
		if(bPlayerInvolved)
			PlayerEnemies.AddRef(akDefender)
		endif
		
		; Spawned NPCs should just be killed unless unique/essential already
		if(ShouldForceSubdue(akDefender))
			SubdueToComplete.AddRef(akDefender)
			KillToComplete.RemoveRef(akDefender)
		else
			ClearProtectedStatus(akDefender)
			KillToComplete.AddRef(akDefender)
			SubdueToComplete.RemoveRef(akDefender)
		endif
	endif
EndFunction


 ; 1.1.3
Function RemoveInvalidSettlers()
	int i = Settlers.GetCount() - 1
	while(i >= 0)
		Actor thisActor = Settlers.GetAt(i) as Actor
		
		if(thisActor != None && ( ! thisActor.IsInFaction(WorkshopNPCFaction) || thisActor.IsInFaction(CaptiveFaction)))
			Settlers.RemoveRef(thisActor)
		endif
		
		i -= 1
	endWhile
	
	i = Synths.GetCount() - 1
	while(i >= 0)
		Actor thisActor = Synths.GetAt(i) as Actor
		
		if(thisActor != None && ( ! thisActor.IsInFaction(WorkshopNPCFaction) || thisActor.IsInFaction(CaptiveFaction)))
			Synths.RemoveRef(thisActor)
		endif
		
		i -= 1
	endWhile
EndFunction

 ; 1.1.3
Function ClearCaravanNPCsFromDefenders()
	int i = Defenders.GetCount() - 1
	while(i > 0)
		Actor thisActor = Defenders.GetAt(i) as Actor
		
		if(thisActor != None && thisActor.IsInFaction(WorkshopCaravanFaction))
			Defenders.RemoveRef(thisActor)
		endif
		
		i -= 1
	endWhile
EndFunction


Function ClearProtectedStatusOnRefCollection(RefCollectionAlias aCollection)
	int i = 0
	while(i < aCollection.GetCount())
		Actor thisActor = aCollection.GetAt(i) as Actor
		if( ! ShouldForceSubdue(thisActor))
			ClearProtectedStatus(thisActor)
		endif
		
		i += 1
	endWhile
EndFunction


Function StartAssault()
	if(GetStageDone(iStage_Ready) && ! GetStageDone(iStage_Started))
		SetStage(iStage_Started)
		SetStage(iStage_TriggerAI)		
		
		AssaultManager.AssaultStarted_Private(Self, WorkshopAlias.GetRef(), iCurrentAssaultType, AttackingFaction, DefendingFaction)
		
		ConfigureTurrets(abMakeDefenders = true)
	endif
EndFunction

Function TryToAutoResolveAssault()
	; Player didn't show up to resolve this in time, resolve "off-camera"
	ObjectReference kWorkshopRef = WorkshopAlias.GetRef()
	
	if(kWorkshopRef.Is3dLoaded() && GetStageDone(iStage_Started))
		; Assault running and player is here, check again shortly
		StartTimerGameTime(0.01, iTimerID_AutoComplete)
	else
		AutoResolveAssault()
	endif
EndFunction

Function AutoResolveAssault()
	if( ! GetStageDone(iStage_Shutdown))		
		if( ! bAutoCalculateVictor)
			; We're not going to mark this as a success or failure and instead are just going to end it
			SetStage(iStage_NoVictor)
		else
			; Calculate how the battle should be resolved
			WorkshopScript thisWorkshop = WorkshopAlias.GetRef() as WorkshopScript
			
			Actor[] kTurretRefs = new Actor[0]
			Float fNonTurretDefenseScore = 0.0
			Float fTurretScore = 0.0
			Float fDefenderScore = 0.0 
			Float fAttackerScore = 0.0
			Float fSiegeScore = 0.0
			
			; Grab all defenders			
			Actor[] kAllDefenders = new Actor[0]
			
			int i = 0
			while(i < Defenders.GetCount())
				Actor thisActor = Defenders.GetAt(i) as Actor
				
				if(FighterStrengthAV != None)
					fDefenderScore += thisActor.GetValue(FighterStrengthAV)
				else
					fDefenderScore += thisActor.GetLevel() as Float
				endif
				
				kAllDefenders.Add(thisActor)
				
				i += 1
			endWhile
			
			; Grab all attackers
			Actor[] kAllAttackers = new Actor[0]
			
			i = 0
			while(i < Attackers.GetCount())
				Actor thisActor = Attackers.GetAt(i) as Actor
				
				fSiegeScore += thisActor.GetValue(SiegeAV)
				
				if(FighterStrengthAV != None)
					fAttackerScore += thisActor.GetValue(FighterStrengthAV)
				else
					fAttackerScore += thisActor.GetLevel() as Float
				endif
				
				kAllAttackers.Add(thisActor)
				
				i += 1
			endWhile
			
			
			; Step 1, defenses negate some amount of attack strength
			Float fRemainingDefenses = fNonTurretDefenseScore - fSiegeScore
			Int iNegatedTurrets = 0
			ActorValue SafetyAV = ResourceManager.Safety
			
			if(thisWorkshop)				
				Float fDefenseScore = ResourceManager.GetWorkshopValue(thisWorkshop, SafetyAV)
			
				; Grab all turrets
				ObjectReference[] kLinkedObjects = thisWorkshop.GetLinkedRefChildren(WorkshopItemKeyword)
				
				i = 0
				while(i < kLinkedObjects.Length)
					if(kLinkedObjects[i] as WorkshopObjectActorScript)
						Actor thisActor = kLinkedObjects[i] as Actor	
						
						if( ! kLinkedObjects[i].IsDestroyed())
							fNonTurretDefenseScore -= kLinkedObjects[i].GetBaseValue(SafetyAV)
							
							Float fThisTurretScore = 0.0
							if(FighterStrengthAV != None)
								fThisTurretScore += thisActor.GetValue(FighterStrengthAV)
							else
								fThisTurretScore += thisActor.GetLevel() as Float
							endif		
							
							
							if(fRemainingDefenses < 0 && (fThisTurretScore * -1) > fRemainingDefenses)
								; Siege eliminated all non-turret defenses, apply remainder to turrets
								
								iNegatedTurrets += 1
								fRemainingDefenses += fThisTurretScore
							else
								fTurretScore += fThisTurretScore
							endif
									
				
							kTurretRefs.Add(thisActor)
						endif
					endif
					
					i += 1
				endWhile
			endif
			
			; Step 2, determine expected casualty count from each side based final attack/defense strengths
			Float fAttackerCasualtyRate = 1 - ((fAttackerScore - (fRemainingDefenses + fTurretScore + fDefenderScore))/fAttackerScore)
			
			Float fDefenderCasualtyRate = 1 - ((fDefenderScore - (fAttackerScore - (fRemainingDefenses + fTurretScore) ))/fDefenderScore)
			
			; Step 3, check if fMaxAttackerCasualtyPercentBeforeRetreat or fMaxDefenderCasualtyPercentBeforeSurrender would be triggered, which would force that size to lose and reduce the opposite side's losses
			float fRetreatTriggerTime = fMaxAttackerCasualtyPercentBeforeRetreat * (kAllAttackers.Length/fAttackerCasualtyRate)
			
			Float fSurrenderTriggerTime = fMaxDefenderCasualtyPercentBeforeSurrender * (kAllDefenders.Length/fDefenderCasualtyRate)
			
			; Step 4, determine winner
			Bool bAttackersWin = false
			Float fBattleTime = fRetreatTriggerTime
			if(fSurrenderTriggerTime < fRetreatTriggerTime)
				bAttackersWin = true
				fBattleTime = fSurrenderTriggerTime
			endif
			
			; Step 5, apply losses 
			Int iTurretsToDestroy = iNegatedTurrets
			
			if(bKillCombatants)
				; Attackers at random, between spawned and other. The goal is to kill iAttackersToKill count, but if the player is lucky, they can lose fewer from their permanent forces
				int iAttackersToKill = Math.Ceiling(fBattleTime * fAttackerCasualtyRate)
				Float fRandomAttackersPercentage = SpawnedAttackersAlias.GetCount()/kAllAttackers.Length
				
				i = 0
				while(i < kAllAttackers.Length && iAttackersToKill > 0)
					if(SpawnedAttackersAlias.Find(kAllAttackers[i]) < 0)
						Float fDieRoll = Utility.RandomFloat()
					
						if(fDieRoll > fRandomAttackersPercentage)
							kAllAttackers[i].Kill()
							iAttackersToKill -= 1
						endif
					endif
					
					i += 1
				endWhile
				
				if(bAttackersWin && iAttackersToKill < SpawnedAttackersAlias.GetCount())
					if(iAttackersToKill > 0)
						i = 0
						while(i < iAttackersToKill)
							Actor thisActor = SpawnedAttackersAlias.GetAt(i) as Actor
							
							if(thisActor)
								thisActor.Kill()
							endif
							
							i += 1
						endWhile
					endif
				else
					SpawnedAttackersAlias.KillAll()
				endif
				
				
				
				int iDefendersToKill = Math.Ceiling(fBattleTime * fDefenderCasualtyRate) 
				int iDefenderCount = kAllDefenders.Length
				Float fDestroyTurretPercentage = 0
				
				if(bDamageDefenses)
					iDefendersToKill += iNegatedTurrets
					iDefenderCount += kTurretRefs.Length
					fDestroyTurretPercentage = kTurretRefs.Length/iDefenderCount
				endif				
				
				Float fNonRandomDefendersPercentage = iDefenderCount - SpawnedDefendersAlias.GetCount()/iDefenderCount
				
				; Defenders at random, between turrets, spawned, and other (Note: Turrets do not count as casualties in the MaxDefenderCasualtyPercentBeforeSurrender), but do not kill last non-random defender unless the attackers won
				i = 0
				while(i < kAllDefenders.Length + kTurretRefs.Length && iDefendersToKill > 0)
					if(SpawnedDefendersAlias.Find(kAllDefenders[i]) < 0)
						Float fDieRoll = Utility.RandomFloat()
					
						if(fDieRoll < fDestroyTurretPercentage)
							iTurretsToDestroy += 1
							iDefendersToKill -= 1
						elseif(fDieRoll > fNonRandomDefendersPercentage)
							kAllDefenders[i].Kill()
							iDefendersToKill -= 1							
						endif
					endif
					
					i += 1
				endWhile
				
				if( ! bAttackersWin && iDefendersToKill < SpawnedDefendersAlias.GetCount())
					if(iDefendersToKill > 0)
						i = 0
						while(i < iDefendersToKill)
							Actor thisActor = SpawnedDefendersAlias.GetAt(i) as Actor
							
							if(thisActor)
								thisActor.Kill()
							endif
							
							i += 1
						endWhile
					endif
				else
					SpawnedDefendersAlias.KillAll()
				endif
			endif
			
			if(bDamageDefenses)
				if(iTurretsToDestroy > 0)
					i = 0
					while(i < iTurretsToDestroy && i < kTurretRefs.Length)
						WorkshopParent.ApplyResourceDamage((kTurretRefs[i] as ObjectReference) as WorkshopObjectScript, SafetyAV, kTurretRefs[i].GetValue(SafetyAV))
						
						i += 1
					endWhile
				endif
			endif
			
			; Step 6, trigger completion
			if(bAttackersWin)
				if(bPlayerInvolved)
					TryToMarkSuccessful()
				else
					SetStage(iStage_Failed)
				endif
			else
				if( ! bPlayerInvolved)
					TryToMarkSuccessful()
				else
					SetStage(iStage_Failed)
				endif
			endif
		endif
	endif
EndFunction


Function ProcessCapture()
	if(bAutoCaptureSettlement)
		if(bSettlersJoinFaction && ! bPlayerIsEnemy)
			; Clear our RemainPlayerEnemyCollection alias
			int i = 0
			while(i < Settlers.GetCount())
				Actor thisActor = Settlers.GetAt(i) as Actor
				if(thisActor)
					AssaultManager.RemainPlayerEnemyCollection.RemoveRef(thisActor)
				endif
				
				i += 1
			endWhile
			
			i = 0
			while(i < NonSpeakingSettlers.GetCount())
				Actor thisActor = NonSpeakingSettlers.GetAt(i) as Actor
				if(thisActor)
					AssaultManager.RemainPlayerEnemyCollection.RemoveRef(thisActor)
				endif
				
				i += 1
			endWhile
			
			i = 0
			while(i < Synths.GetCount())
				Actor thisActor = Synths.GetAt(i) as Actor
				if(thisActor)
					AssaultManager.RemainPlayerEnemyCollection.RemoveRef(thisActor)
				endif
				
				i += 1
			endWhile
		endif
		
		ControlManager.CaptureSettlement(WorkshopAlias.GetRef() as WorkshopScript, AttackingFactionData, bSeverEnemySupplyLines, bRemoveEnemySettlers, bKillEnemySettlers, bCaptureTurrets, bCaptureContainers, bSettlersJoinFaction, bTogglePlayerOwnership, bPlayerIsEnemy, iCreateInvadingSettlers)
	endif
EndFunction


Function StartAIPackages()
	if(bPlayerInvolved)
		if(iCurrentAssaultType == AssaultManager.iType_Defend)
			AssaultAttackersFaction.SetPlayerEnemy(true)
			
			if(AttackingFaction != None)
				AttackingFaction.SetPlayerEnemy(true)
			endif
		else
			AssaultDefendersFaction.SetPlayerEnemy(true)
			
			if(DefendingFaction != None)
				DefendingFaction.SetPlayerEnemy(true)
			endif			
		endif
	endif
	
	Attackers.AddToFaction(ActivateAIFaction)
	if(bChildrenFleeDuringAttack) ; 1.1.1 - This hadn't been setup correctly before
		if(Children != None)
			Children.AddToFaction(ActivateAIFaction)
		endif
	endif
	
	Attackers.EvaluateAll()	
	Defenders.EvaluateAll()
EndFunction


Function AddCollectionToCompleteAliases(RefCollectionAlias aCollection, Bool abDefenders = false, Bool abGuardNPCs = false)
	int i = 0
	int iCount = aCollection.GetCount()
	ObjectReference kDefendFromRef = DefendFromAlias.GetRef()
	ObjectReference kAttackFromRef = AttackFromAlias.GetRef()
	
	ModTraceCustom(sLogName, "AddCollectionToCompleteAliases(" + aCollection + ", " + abDefenders + ", " + abGuardNPCs + ") bMoveDefendersToCenterPoint = " + bMoveDefendersToCenterPoint + " (" + kDefendFromRef + "), bMoveAttackersToStartPoint = " + bMoveAttackersToStartPoint + " (" + kAttackFromRef + ")")
	
	if(kAttackFromRef.HasRefType(MapMarkerRefType))
		ObjectReference kLinkedHeadingRef = kAttackFromRef.GetLinkedRef()
		if(kLinkedHeadingRef != None)
			kAttackFromRef = kLinkedHeadingRef
		endif
	endif
	
	Bool bIsDefendFromLoaded = kDefendFromRef.Is3dLoaded()
	Bool bIsAttackFromLoaded = kAttackFromRef.Is3dLoaded()
	
	while(i < iCount)
		Actor thisActor = aCollection.GetAt(i) as Actor
		
		if(thisActor)
			Bool bSkipActor = false
			if(aCollection == Settlers || aCollection == NonSpeakingSettlers || aCollection == Synths)
				if( ! (thisActor as WorkshopNPCScript) && thisActor.GetLinkedRef(WorkshopLinkHome) == None) ; 2.0.1 - Added check for link via WorkshopLinkHome in addition to WorkshopNPCScript so we have two potential catches for settlers
					bSkipActor = true
				endif
			endif
			
			if( ! bSkipActor)
				; Move units
				if(abDefenders)
					if(bMoveDefendersToCenterPoint)
						thisActor.MoveTo(kDefendFromRef)
					endif
					
					if(bIsDefendFromLoaded)
						thisActor.MoveToNearestNavmeshLocation()
					endif
				elseif( ! abDefenders)
					if(bMoveAttackersToStartPoint)
						thisActor.MoveTo(kAttackFromRef)
					endif
					
					if(bIsAttackFromLoaded)
						thisActor.MoveToNearestNavmeshLocation()
					endif
				endif
			endif 
			
			; 1.1.1 - adjusted function to ensure WorkshopNPCs are correctly added to the victory aliases, and so NPCs are killable when appropriate
				
			; Add to victory tracking aliases
			Bool bForceSubdue = ShouldForceSubdue(thisActor)
			
			if(bForceSubdue || (iCurrentAssaultType == AssaultManager.iType_Attack_Subdue && abDefenders && ! bForceDefendersKillable && ( ! abGuardNPCs || ! bGuardsKillableEvenOnSubdue)))
				SubdueToComplete.AddRef(thisActor)
				KillToComplete.RemoveRef(thisActor)
			else
				ClearProtectedStatus(thisActor)
													
				KillToComplete.AddRef(thisActor)
				SubdueToComplete.RemoveRef(thisActor)
			endif
		endif
		
		i += 1
	endWhile
EndFunction


Function ClearProtectedStatus(Actor akActorRef)
	if( ! akActorRef.IsEssential())
		akActorRef.AddKeyword(ProtectedStatusRemoved)
		akActorRef.SetProtected(false)
	endif
EndFunction

Bool Function ShouldForceSubdue(Actor akActorRef)
	Bool bIsActorEssential = akActorRef.IsEssential()
	
	;ModTraceCustom(sLogName, "     ShouldForceSubdue(" + akActorRef + ") bIsActorEssential = " + bIsActorEssential)
	
	if(bIsActorEssential || (bAlwaysSubdueUniques && akActorRef.GetLeveledActorBase().IsUnique()) || akActorRef.HasKeyword(ForceSubdueDuringAssaultTagKeyword))
		return true
	endif
	
	return false
EndFunction


Function SetupMapMarker(bool abStart = true)
	ObjectReference kMapMarker = MapMarkerAlias.GetRef()
	
	if(kMapMarker != None)
		if(abStart)
			; Make sure player can see the target
			kMapMarker.AddToMap()
			
			if(kMapMarker.CanFastTravelToMarker())
				if(bDisableFastTravel)
					kMapMarker.EnableFastTravel(false)
					bDisabledMapMarker = true
				endif
  			endif
		else
			;If fast travel has been disabled here, enable it
			if(bDisabledMapMarker)
				kMapMarker.EnableFastTravel()
			endif
		endif
	endif 
EndFunction


Function RemoveSettlementFactionsFromCollection(RefCollectionAlias aCollection)
	int i = 0
	while(i < aCollection.GetCount())
		Actor thisActor = aCollection.GetAt(i) as Actor
		if(thisActor != None)
			RemoveSettlementFactions(thisActor)
		endif
		
		i += 1
	endWhile
EndFunction

Function RemoveSettlementFactions(Actor akActorRef)
	ModTraceCustom(sLogName, "RemoveSettlementFactions(" + akActorRef + ")")
	
	WorkshopScript kActorWorkshopRef = akActorRef.GetLinkedRef(WorkshopItemKeyword) as WorkshopScript
	if(kActorWorkshopRef != None && kActorWorkshopRef.SettlementOwnershipFaction != None && kActorWorkshopRef.UseOwnershipFaction)
		if(ApplyWorkshopOwnerFaction(akActorRef))
			if(CountsForPopulation(akActorRef))
				akActorRef.SetCrimeFaction(None)
			else
				akActorRef.SetFactionOwner(None)
			endif
		endif
						
		akActorRef.RemoveFromFaction(kActorWorkshopRef.SettlementOwnershipFaction)
	endif
	
	akActorRef.RemoveFromFaction(WorkshopNPCFaction)
EndFunction

Function RestoreSettlementFactionsToCollection(RefCollectionAlias aCollection)
	int i = 0
	while(i < aCollection.GetCount())
		Actor thisActor = aCollection.GetAt(i) as Actor
		if(thisActor != None)
			RestoreSettlementFactions(thisActor)
		endif
		
		i += 1
	endWhile
EndFunction

Function RestoreSettlementFactions(Actor akActorRef)
	ModTraceCustom(sLogName, "RestoreSettlementFactions(" + akActorRef + ")")
	WorkshopScript kActorWorkshopRef = akActorRef.GetLinkedRef(WorkshopItemKeyword) as WorkshopScript
	
	if(kActorWorkshopRef != None)
		if(kActorWorkshopRef.SettlementOwnershipFaction != None && kActorWorkshopRef.UseOwnershipFaction)
			if(ApplyWorkshopOwnerFaction(akActorRef))
				if(CountsForPopulation(akActorRef))
					akActorRef.SetCrimeFaction(kActorWorkshopRef.SettlementOwnershipFaction)
				else
					akActorRef.SetFactionOwner(kActorWorkshopRef.SettlementOwnershipFaction)
				endif
				
				akActorRef.AddToFaction(kActorWorkshopRef.SettlementOwnershipFaction)
			endif
		endif
		
		akActorRef.AddToFaction(WorkshopNPCFaction)
	endif
EndFunction


Function CleanupAssault()
	WorkshopScript thisWorkshop = WorkshopAlias.GetRef() as WorkshopScript
	
	if(Attackers != None)
		Attackers.RemoveFromFaction(ActivateAIFaction) ; Clear attack AI
		RestoreSettlementFactionsToCollection(Attackers)
	endif
	
	if(Children != None)
		Children.RemoveFromFaction(ActivateAIFaction) ; Clear flee AI
	endif
	
	RestoreProtectedStatus()
		
	if(bPlayerInvolved && bEnemySurvivorsRemainEnemyToPlayer)
		; Only mark them enemies to the player if this settlement wasn't captured - otherwise the player will be stuck murdering everyone inthe settlement
		if( ! bAutoCaptureSettlement || GetStageDone(iStage_Failed))
			int i = 0
			while(i < PlayerEnemies.GetCount())
				Actor thisActor = PlayerEnemies.GetAt(i) as Actor
				if(thisActor && ! thisActor.IsEssential()&& ! thisActor.IsDead())
					AssaultManager.RemainPlayerEnemyCollection.AddRef(thisActor)
				endif
				
				i += 1
			endWhile
		endif
	endif
	
	if(bSurvivingSpawnedAttackersMoveIn && thisWorkshop)
		int i = 0
		while(i < SpawnedAttackersAlias.GetCount())
			Actor thisActor = SpawnedAttackersAlias.GetAt(i) as Actor
			
			if( ! thisActor.IsDead())
				WorkshopNPCScript thisNPC = thisActor as WorkshopNPCScript
				
				if(thisNPC)
					NPCManager.AddNewActorToWorkshop(thisNPC, thisWorkshop)
				else
					thisActor.SetPersistLoc(thisWorkshop.myLocation)
				endif
			endif
						
			i += 1
		endWhile
	endif
	
	if(bSurvivingSpawnedDefendersRemain)
		int i = 0
		while(i < SpawnedDefendersAlias.GetCount() && thisWorkshop)
			Actor thisActor = SpawnedDefendersAlias.GetAt(i) as Actor
			
			if( ! thisActor.IsDead())
				WorkshopNPCScript thisNPC = thisActor as WorkshopNPCScript
				
				if(thisNPC)
					NPCManager.AddNewActorToWorkshop(thisNPC, thisWorkshop)
				else
					thisActor.SetPersistLoc(thisWorkshop.myLocation)
				endif
			endif
						
			i += 1
		endWhile
	endif

	AssaultAttackersFaction.SetPlayerEnemy(false)
	AssaultDefendersFaction.SetPlayerEnemy(false)
	
	if(AttackingFaction != None)
		AttackingFaction.SetPlayerEnemy(false)
	endif
	
	if(DefendingFaction != None)
		DefendingFaction.SetPlayerEnemy(false)
	endif
	
	; Restore fast travel if necessary
	SetupMapMarker(abStart = false)
	
	; Reset everything to defaults
	iReserveID = -1
	UpdateCurrentAssaultType(-1)
	
	bDisableFastTravel = true
	bSettlersAreDefenders = true
	bRobotsAreDefenders = true
	bAutoStartAssaultOnLoad = true
	bAutoStartAssaultWhenPlayerReachesAttackFrom = true
	bDisabledMapMarker = false
	bAttackersDeadFailsAssault = true
	bAutoHandleObjectives = true
	bChildrenFleeDuringAttack = true
	
	bAutoCaptureSettlement = false
	
	AttackingFactionData = None
	bSeverEnemySupplyLines = true
	bRemoveEnemySettlers = true
	bKillEnemySettlers = false
	bCaptureTurrets = true
	bCaptureContainers = true
	bSettlersJoinFaction = false
	bTogglePlayerOwnership = false
	bPlayerIsEnemy = false
	iCreateInvadingSettlers = -1	
	
	SpawnAttackerCounts = None
	SpawnAttackerForm = None
	iSpawnAttackers = 0
	OtherAttackers = None
	bMoveAttackersToStartPoint = true
	SpawnDefenderForm = None
	iSpawnDefenders = 0
	SpawnDefenderCounts = None
	OtherDefenders = None
	bMoveDefendersToCenterPoint = true
	; 1.1.2 - Hide all objectives
	HideAllObjectives()
	
	; 1.1.9 - Moved this to the last thing
	RestoreBleedoutRecovery()
EndFunction


; 1.1.2 - Override
Function Stop()
	; Hide objectives before stopping or they end up stuck displayed
	if( ! GetStageDone(iStage_Failed) && ! GetStageDone(iStage_Success	))
		HideAllObjectives()
	endif
	
	Parent.Stop()
EndFunction

Function HideAllObjectives()
	SetObjectiveDisplayed(10, false)
	SetObjectiveDisplayed(15, false)
	SetObjectiveDisplayed(16, false)
	SetObjectiveDisplayed(17, false)
	SetObjectiveDisplayed(20, false)
	SetObjectiveDisplayed(21, false)
	SetObjectiveDisplayed(22, false)
	SetObjectiveDisplayed(30, false)
	SetObjectiveDisplayed(31, false)
	SetObjectiveDisplayed(32, false)
EndFunction


Function StopAllCombat()
	(PlayerAlias.GetRef() as Actor).StopCombatAlarm()
	
	StopCombatAlarmOnCollection(Attackers)
	StopCombatAlarmOnCollection(Defenders)
EndFunction


Function StopCombatAlarmOnCollection(RefCollectionAlias aCollection)
	int i = 0
	int iCount = aCollection.GetCount()

	while(i < iCount)
		Actor kActorRef = aCollection.GetAt(i) as Actor
		kActorRef.StopCombatAlarm()
		
		i += 1
	endWhile
EndFunction



Function RestoreBleedoutRecovery()
	RestoreCollectionBleedoutRecovery(Attackers)
	RestoreCollectionBleedoutRecovery(SubdueToComplete)
	RestoreCollectionBleedoutRecovery(Defenders)
EndFunction

Function RestoreCollectionBleedoutRecovery(RefCollectionAlias aCollection)
	int i = 0
	while(i < aCollection.GetCount())
		Actor thisActor = aCollection.GetAt(i) as Actor
		if(thisActor && thisActor.HasKeyword(BleedoutRecoveryStopped))
			RestoreActorBleedoutRecovery(thisActor)
		endif
		
		i += 1
	endWhile
EndFunction


Function RestoreActorBleedoutRecovery(Actor akActorRef)
	; First make sure they have some health or they will immediately drop dead
	ActorValue HealthAV = Game.GetHealthAV()
	Float fCurrentHealth = akActorRef.GetValue(HealthAV)
	Float fRestore = 10.0
	
	if(fCurrentHealth < 0)
		fRestore += fCurrentHealth * -1
	endif
	
	akActorRef.RestoreValue(HealthAV, fRestore)
	akActorRef.SetNoBleedoutRecovery(false)
	akActorRef.RemoveKeyword(BleedoutRecoveryStopped)
EndFunction


Function PreventCollectionBleedoutRecovery(RefCollectionAlias aCollection)
	int i = 0
	while(i < aCollection.GetCount())
		Actor thisActor = aCollection.GetAt(i) as Actor
		if(thisActor)
			PreventActorBleedoutRecovery(thisActor)
		endif
		
		i += 1
	endWhile
EndFunction

Function PreventActorBleedoutRecovery(Actor akActorRef)
	akActorRef.SetNoBleedoutRecovery(true)
	akActorRef.AddKeyword(BleedoutRecoveryStopped)
EndFunction


; 1.1.1
Function RestoreProtectedStatus()
	int i = 0
	while(i < Attackers.GetCount())
		Actor thisActor = Attackers.GetAt(i) as Actor
		
		if(thisActor.HasKeyword(ProtectedStatusRemoved))
			thisActor.SetProtected(true)
			thisActor.RemoveKeyword(ProtectedStatusRemoved)
		endif
		
		i += 1
	endWhile
	
	i = 0
	while(i < Defenders.GetCount())
		Actor thisActor = Defenders.GetAt(i) as Actor
		
		if(thisActor.HasKeyword(ProtectedStatusRemoved))
			thisActor.SetProtected(true)
			thisActor.RemoveKeyword(ProtectedStatusRemoved)
		endif
		
		i += 1
	endWhile
EndFunction


Function ConfigureTurrets(Bool abMakeDefenders = true)
	; Grab all turrets
	if(abMakeDefenders)
		WorkshopScript thisWorkshop = WorkshopAlias.GetRef() as WorkshopScript
		
		if(thisWorkshop)
			ObjectReference[] kLinkedObjects = thisWorkshop.GetLinkedRefChildren(WorkshopItemKeyword)
			
			int i = 0
			while(i < kLinkedObjects.Length)
				if(kLinkedObjects[i] as WorkshopObjectActorScript)
					DefenderFactionAlias.AddRef(kLinkedObjects[i])
				endif
				
				i += 1
			endWhile
		endif
	else
		int i = DefenderFactionAlias.GetCount() - 1
		while(i >= 0)
			WorkshopObjectActorScript asTurret = DefenderFactionAlias.GetAt(i) as WorkshopObjectActorScript
			if(asTurret)
				DefenderFactionAlias.RemoveRef(asTurret)
			endif
			
			i -= 1
		endWhile
	endif
EndFunction


Function RunEnemyMonitor() ; 1.1.10
	StartTimer(fTimerLength_EnemyMonitor, iTimerID_EnemyMonitor)
EndFunction

ObjectReference Function GetFallbackDefendFromRef()
	ObjectReference kDefendFromRef = DefendFromAlias.GetRef()
	ObjectReference kCenterMarkerRef = CenterMarkerAlias.GetRef()
	ObjectReference kWorkshopRef = WorkshopAlias.GetRef()
	; This is not ideal and will often result in NPCs under the world, let's try for center marker or spawn point. Note: We have center marker set up as a force into alias which should overwrite workshop ref being forced into the defend from alias, but it does not work for unknown reasons.
	if(kCenterMarkerRef != None)
		kDefendFromRef = kCenterMarkerRef
	elseif(kWorkshopRef != None)
		ObjectReference kSpawnPointRef = kWorkshopRef.GetLinkedRef(WorkshopLinkSpawn)
		if(kSpawnPointRef != None)
			kDefendFromRef = kSpawnPointRef
		endif
	endif
	
	if(kDefendFromRef == None)
		kDefendFromRef = kWorkshopRef
	endif
	
	return kDefendFromRef
EndFunction

; Added in 1.1.10 to ensure an assault doesn't get stuck if an Alias script fails to register a death/subdue
; 2.3.11 - Modified this check to also do a full reset of the location of unloaded or non-visible enemies to avoid them stuck under the world. Previously this would only hit the first NPC and then exit the check.
Bool Function CheckForEnemiesDown()
	Actor PlayerRef = PlayerAlias.GetActorRef()
	int iCount = SubdueToComplete.GetCount()
	Bool bAllDown = true
	ObjectReference kMoveToRef = None
	ObjectReference kDefendFromRef = DefendFromAlias.GetRef()
	if(kDefendFromRef == None)
		kDefendFromRef = GetFallbackDefendFromRef()
	endif
	
	if(iCurrentAssaultType == AssaultManager.iType_Defend || (iCurrentAssaultType != AssaultManager.iType_Defend && bReinforcementsPhase))
		ObjectReference kAttackFromRef = AttackFromAlias.GetRef()
		
		if(kAttackFromRef == None)
			kAttackFromRef = kDefendFromRef
		endif
		
		kMoveToRef = kAttackFromRef
	else
		kMoveToRef = kDefendFromRef
	endif
	
	Bool bPlayerCanSeeMoveToRef = PlayerRef.HasDetectionLOS(kMoveToRef)
	
	if(iCount > 0)		
		int i = iCount
		while(i > 0)
			i -= 1
			Actor thisActor = SubdueToComplete.GetAt(i) as Actor
			
			if(thisActor != None)
				if(thisActor.IsDeleted())
					SubdueToComplete.RemoveRef(thisActor)
				elseif( ! thisActor.IsBleedingOut() && ! thisActor.IsDead())
					if(thisActor.IsDisabled())
						thisActor.Enable(false)
					endif
					
					if(bAutoAttemptToPreventEnemiesUnderTheWorld)
						Bool bIsActor3dloaded = thisActor.Is3dLoaded()
						Float fDistanceToPlayer = PlayerRef.GetDistance(thisActor)
							; We're only trying to move actors that are stuck under the world - this should only happen near the start location, hence the small distance check
						if(bIsActor3dloaded && bPlayerInvolved && ! bPlayerCanSeeMoveToRef && thisActor.GetDistance(kMoveToRef) < 1000.0 && ! PlayerRef.HasDetectionLOS(thisActor) && fDistanceToPlayer > 2000.0)
						
							; In case the actor fled, the AI package took it somewhere strange, or the game put them under the world
							
							thisActor.MoveTo(kMoveToRef)
							
							if(bIsActor3dloaded)
								thisActor.MoveToNearestNavmeshLocation()
							endif
						endif				
						
						bAllDown = false
					endif
				endif
			endif
		endWhile
	endif
	
	iCount = KillToComplete.GetCount()
	
	if(iCount > 0)
		int i = iCount
		while(i > 0)
			i -= 1
			Actor thisActor = KillToComplete.GetAt(i) as Actor
			
			if(thisActor != None)
				if(thisActor.IsDeleted())
					KillToComplete.RemoveRef(thisActor)
				elseif(thisActor && ! thisActor.IsBleedingOut() && ! thisActor.IsDead())
					if(thisActor.IsDisabled())
						thisActor.Enable(false)
					endif
					
					if(bAutoAttemptToPreventEnemiesUnderTheWorld)
						Bool bIsActor3dloaded = thisActor.Is3dLoaded()
						Float fDistanceToPlayer = PlayerRef.GetDistance(thisActor)
							; We're only trying to move actors that are stuck under the world - this should only happen near the start location, hence the small distance check
						if(bIsActor3dloaded && bPlayerInvolved && ! bPlayerCanSeeMoveToRef && thisActor.GetDistance(kMoveToRef) < 1000.0 && ! PlayerRef.HasDetectionLOS(thisActor) && fDistanceToPlayer > 2000.0)
						
							; In case the actor fled, the AI package took it somewhere strange, or the game put them under the world
							
							thisActor.MoveTo(kMoveToRef)
							
							if(bIsActor3dloaded)
								thisActor.MoveToNearestNavmeshLocation()
							endif
						endif				
						
						bAllDown = false
					endif
					
					bAllDown = false
				endif
			endif
		endWhile
	endif
	
	return bAllDown
EndFunction


Function TriggerInitialObjectives()
	if(iOverrideObjectiveSet >= 1)
		iObjectiveSet = iOverrideObjectiveSet
	else
		if(iCurrentAssaultType == AssaultManager.iType_Defend)
			iObjectiveSet = iObjectiveSet_Defend
		elseif(iCurrentAssaultType == AssaultManager.iType_Attack_Subdue)
			iObjectiveSet = iObjectiveSet_Subdue
		else
			iObjectiveSet = iObjectiveSet_Wipeout
		endif
	endif
	
	if(iObjectiveSet == iObjectiveSet_Defend)
		if(bAutoHandleObjectives)
			SetObjectiveDisplayed(17)
		endif
	else
		if(bAutoHandleObjectives)
			SetObjectiveDisplayed(10)					
		endif
	endif
	
	if(bAutoHandleObjectives)
		SetActive() ; Mark it active in the player's quest log
	endif
EndFunction

Function TriggerPlayerInvolvedObjectives()
	if(IsObjectiveDisplayed(10))
		SetObjectiveCompleted(10)
	endif
	
	; When player arrives let's correct the objectives if there is no one to subdue
	if(iCurrentAssaultType == AssaultManager.iType_Attack_Subdue)
		if(SubdueToComplete.GetCount() == 0)
			UpdateCurrentAssaultType(AssaultManager.iType_Attack_Wipeout)
			if(iOverrideObjectiveSet < 1)
				iObjectiveSet = iObjectiveSet_Wipeout
			endif
		endif
	endif
	
	if(iObjectiveSet == iObjectiveSet_Defend) 
		; No additional objectives needed for defend
	elseif(iObjectiveSet == iObjectiveSet_Subdue)
		SetObjectiveDisplayed(16) ; Subdue
	else
		SetObjectiveDisplayed(15) ; Wipeout
	endif
EndFunction

Int Function CountActiveFighters(Bool abAttackers = true)
	int iCount = 0
	
	RefCollectionAlias checkCollection = Attackers
	if( ! abAttackers)
		checkCollection = Defenders
	endif
	
	int i = 0
	while(i < checkCollection.GetCount())
		Actor thisActor = checkCollection.GetAt(i) as Actor
		
		if(thisActor && ! thisActor.IsBleedingOut() && ! thisActor.IsDead())
			iCount += 1
		endif	
						
		i += 1
	endWhile
	
	return iCount
EndFunction


;
; Test Functions
;

Function CheckSubdueOtherDefenders()
	int i = 0
	while(i < OtherDefenders.GetCount())
		Actor thisActor = OtherDefenders.GetAt(i) as Actor
		ModTraceCustom(sLogName, "     ShouldForceSubdue(" + thisActor + ") = " + ShouldForceSubdue(thisActor))
		
		i += 1
	endWhile
EndFunction

Function CheckSubdue(Actor akActorRef)
	if(akActorRef.IsEssential() || (bAlwaysSubdueUniques && akActorRef.GetLeveledActorBase().IsUnique()))
		Debug.MessageBox("Actor should be subdued")
	else
		Debug.MessageBox("Actor should not be subdued")
	endif
EndFunction