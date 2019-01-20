; ---------------------------------------------
; WorkshopFramework:AssaultSettlement.psc - by kinggath
; ---------------------------------------------
; Reusage Rights ------------------------------
; You are free to use this script or portions of it in your own mods, provided you give me credit in your description and maintain this section of comments in any released source code (which includes the IMPORTED SCRIPT CREDIT section to give credit to anyone in the associated Import scripts below.
; 
; IMPORTED SCRIPT CREDIT
; N/A
; ---------------------------------------------

Scriptname WorkshopFramework:AssaultSettlement extends Quest

import WorkshopFramework:Library:DataStructures
import WorkshopFramework:Library:UtilityFunctions

; -------------------------------------------
; Consts
; -------------------------------------------

int iStage_Setup = 10 Const
int iStage_Ready = 20 Const
int iStage_PlayerArrived = 25 Const
int iStage_AttackStartedByCombat = 26 Const
int iStage_Started = 30 Const
int iStage_TriggerAI = 40 Const
int iStage_FirstDown = 50 Const
int iStage_MostEnemiesDown = 60 Const
int iStage_AllEnemiesSubdued = 61 Const
int iStage_AllEnemiesDead = 62 Const
int iStage_MostAlliesDown = 65 Const
int iStage_AllAlliesDown = 70 Const
int iStage_EnemiesDown = 75 Const

int iStage_AutoComplete = 80 Const
int iStage_NoVictor = 85 Const

int iStage_Failed = 90 Const
int iStage_Success = 100 Const

int iStage_Shutdown = 1000 Const

int iTimerID_AutoRunSetup = 100 Const
int iTimerID_Shutdown = 101 Const
int iTimerID_AutoComplete = 102 Const
int iTimerID_FailsafeNoSetup = 103 Const

float fTimerLength_AutoRunSetup = 30.0 Const ; If it takes longer than this, the requesting script can cancel the timer and call SetupAssault manually
float fTimerLength_Shutdown = 10.0 Const ; This is just designed to give other scripts a chance to react to the results before the aliases are cleared
float fTimerLength_FailsafeNoSetup = 300.0 Const ; After 5 minutes, quests are considered abandoned and shut down

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
	
	RefCollectionAlias Property KillToComplete Auto Const Mandatory
	RefCollectionAlias Property SubdueToComplete Auto Const Mandatory
	RefCollectionAlias Property PlayerAllies Auto Const Mandatory
	RefCollectionAlias Property PlayerEnemies Auto Const Mandatory
	
	RefCollectionAlias Property Defenders Auto Const Mandatory
	RefCollectionAlias Property Attackers Auto Const Mandatory
	
	RefCollectionAlias Property SpawnedAttackersAlias Auto Const Mandatory
	RefCollectionAlias Property SpawnedDefendersAlias Auto Const Mandatory
	
	RefCollectionAlias Property AttackerFactionAlias Auto Const Mandatory
	RefCollectionAlias Property DefenderFactionAlias Auto Const Mandatory
	
	ReferenceAlias Property SettlementLeader Auto Const Mandatory
	RefCollectionAlias Property Settlers Auto Const Mandatory
	RefCollectionAlias Property NonSpeakingSettlers Auto Const Mandatory
	RefCollectionAlias Property Robots Auto Const Mandatory
	RefCollectionAlias Property Children Auto Const Mandatory
EndGroup

Group Factions
	Faction Property AssaultAttackersFaction Auto Const Mandatory
	Faction Property AssaultDefendersFaction Auto Const Mandatory
	Faction Property ActivateAIFaction Auto Const Mandatory
EndGroup

Group Keywords
	Keyword Property BleedoutRecoveryStopped Auto Const Mandatory
	Keyword Property WorkshopItemKeyword Auto Const Mandatory
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

Bool bDisabledMapMarker = false
Int iReserveID = -1
Int iCurrentAssaultType = -1

; Prep variables
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
Bool Property bAutoCaptureSettlement = false Auto Hidden
Bool Property bChildrenFleeDuringAttack = true Auto Hidden

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
ActorBase Property SpawnAttackerForm Auto Hidden
Int Property iSpawnAttackers = 0 Auto Hidden ; This number of SpawnAttackerForm will be created
RefCollectionAlias Property OtherAttackers Auto Hidden ; collection from another quest of additional attackers
Faction Property AttackingFaction Auto Hidden

	; Defenders
ActorBase Property SpawnDefenderForm Auto Hidden
Int Property iSpawnDefenders = 0 Auto Hidden ; This number of SpawnDefenderForm will be created
RefCollectionAlias Property OtherDefenders Auto Hidden ; collection from another quest of additional guards
Faction Property DefendingFaction Auto Hidden

	; Cleanup
Bool Property bSurvivingSpawnedAttackersMoveIn = false Auto Hidden
Bool Property bSurvivingSpawnedDefendersRemain = false Auto Hidden
Bool Property bEnemySurvivorsRemainEnemyToPlayer = true Auto Hidden


; TODO: Currently using just one faction for attack and one for defense means that if we ever have two opposing attacks (one with the player attacking and one with the player defending) happening simultaneously, the factions will be incorrectly matched. Likely need a different solution to this for aggression against the player.

; -------------------------------------------
; Events
; -------------------------------------------

Event OnStoryScript(Keyword akKeyword, Location akLocation, ObjectReference akRef1, ObjectReference akRef2, int aiValue1, int aiValue2)
	; akRef1 = Verb
	; aiValue1 = Type 
	; aiValue2 = ReserveID
	if(akRef1 != None)
		VerbAlias.ForceRefTo(akRef1)
	endif
	
	iCurrentAssaultType = aiValue1
	iReserveID = aiValue2
	
	SetStage(iStage_Setup)
	
	StartTimer(fTimerLength_AutoRunSetup, iTimerID_AutoRunSetup)
	StartTimer(fTimerLength_FailsafeNoSetup, iTimerID_FailsafeNoSetup)
EndEvent


Event OnTimer(Int aiTimerID)
	if(aiTimerID == iTimerID_AutoRunSetup)
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


Event OnStageSet(Int aiStageID, Int aiItemID)
	if(aiStageID == iStage_Ready)
		if(fAutoEndTime > 0)
			StartTimerGameTime(fAutoEndTime, iTimerID_AutoComplete)
		endif
		
		if(bPlayerInvolved)
			if(iCurrentAssaultType != AssaultManager.iType_Defend)
				if(bAutoHandleObjectives)
					SetObjectiveDisplayed(10)
				endif
				
				ObjectReference kAttackFrom = AttackFromAlias.GetRef()
				
				if(PlayerAlias.GetRef().GetDistance(kAttackFrom) < fPlayerArriveDistance)
					SetStage(iStage_PlayerArrived)
				else
					RegisterForDistanceLessThanEvent(PlayerAlias.GetRef(), kAttackFrom, fPlayerArriveDistance)
				endif
				
				
				Actor PlayerRef = PlayerAlias.GetRef() as Actor
				AttackerFactionAlias.AddRef(PlayerRef)
			else
				if(bAutoHandleObjectives)
					SetObjectiveDisplayed(17)
				endif
				
				Actor PlayerRef = PlayerAlias.GetRef() as Actor
				DefenderFactionAlias.AddRef(PlayerRef)
			endif
		endif
	elseif(aiStageID == iStage_AttackStartedByCombat)
		; Combat started because player attacked settlement without meeting up, or the NPCs started combat before the player reached them - so we need to trigger the player arrived event and trigger the assault to start
		
		SetStage(iStage_PlayerArrived)
		StartAssault()
	elseif(aiStageID == iStage_PlayerArrived)
		if(bAutoHandleObjectives)
			if(IsObjectiveDisplayed(10))
				SetObjectiveCompleted(10)
			endif
			
			if(iCurrentAssaultType == AssaultManager.iType_Attack_Wipeout)
				SetObjectiveDisplayed(15)
			elseif(iCurrentAssaultType == AssaultManager.iType_Attack_Subdue)
				SetObjectiveDisplayed(16)
			endif
		endif
		
		if(bAutoStartAssaultWhenPlayerReachesAttackFrom)
			StartAssault()
		endif
	elseif(aiStageID == iStage_TriggerAI)
		StartAIPackages()
	elseif(aiStageID == iStage_MostEnemiesDown)
		if(bAutoHandleObjectives)
			if(iCurrentAssaultType == AssaultManager.iType_Defend)
				SetObjectiveDisplayed(17, false)
				SetObjectiveDisplayed(22)
			elseif(iCurrentAssaultType == AssaultManager.iType_Attack_Wipeout)
				SetObjectiveDisplayed(15, false)
				SetObjectiveDisplayed(20)
			elseif(iCurrentAssaultType == AssaultManager.iType_Attack_Subdue)
				SetObjectiveDisplayed(16, false)
				SetObjectiveDisplayed(21)
			endif
		endif
	elseif(aiStageID == iStage_AllEnemiesSubdued)
		if(GetStageDone(iStage_AllEnemiesDead))
			SetStage(iStage_EnemiesDown)
		endif
	elseif(aiStageID == iStage_AllEnemiesDead)
		if(GetStageDone(iStage_AllEnemiesSubdued))
			SetStage(iStage_EnemiesDown)
		endif
	elseif(aiStageID == iStage_EnemiesDown)
		if(TryToMarkSuccessful())
			if(iCurrentAssaultType == AssaultManager.iType_Defend)
				if(bAutoHandleObjectives)
					SetObjectiveCompleted(17)
					
					if(IsObjectiveDisplayed(22))
						SetObjectiveCompleted(22)
					endif
				endif
			elseif(iCurrentAssaultType == AssaultManager.iType_Attack_Wipeout)
				if(bAutoHandleObjectives)
					SetObjectiveCompleted(15)
					
					if(IsObjectiveDisplayed(20))
						SetObjectiveCompleted(20)
					endif
				endif
			elseif(iCurrentAssaultType == AssaultManager.iType_Attack_Subdue)
				if(bAutoHandleObjectives)
					SetObjectiveCompleted(16)
					
					if(IsObjectiveDisplayed(21))
						SetObjectiveCompleted(21)
					endif
				endif
			endif
		endif		
	elseif(aiStageID == iStage_AllAlliesDown)
		if(bAttackersDeadFailsAssault)
			SetStage(iStage_Failed)
		endif
	elseif(aiStageID == iStage_Failed)
		FailAllObjectives()
		
		AssaultManager.AssaultCompleted_Private(Self, WorkshopAlias.GetRef(), iCurrentAssaultType, AttackingFaction, DefendingFaction, false)
		
		StopAllCombat()
		
		if(iCurrentAssaultType == AssaultManager.iType_Defend)
			ProcessCapture()
		endif
			
		StartTimer(fTimerLength_Shutdown, iTimerID_Shutdown)
	elseif(aiStageID == iStage_Success)
		CompleteAllObjectives()		
			
		AssaultManager.AssaultCompleted_Private(Self, WorkshopAlias.GetRef(), iCurrentAssaultType, AttackingFaction, DefendingFaction, true)
		
		StopAllCombat()		
		
		if(iCurrentAssaultType != AssaultManager.iType_Defend)
			ProcessCapture()
		endif
		
		if(bPlayerInvolved)
			CompleteQuest()
		endif
		
		StartTimer(fTimerLength_Shutdown, iTimerID_Shutdown)
	elseif(aiStageID == iStage_NoVictor)
		; Ended without a victor
		AssaultManager.AssaultStopped_Private(Self)
		StartTimer(fTimerLength_Shutdown, iTimerID_Shutdown)
	elseif(aiStageID == iStage_AutoComplete)
		; Player didn't show up to resolve this in time, resolve "off-camera"
		ObjectReference kWorkshopRef = WorkshopAlias.GetRef()
		
		if(kWorkshopRef.Is3dLoaded() && GetStageDone(iStage_Started))
			; Assault running and player is here, check again shortly
			StartTimerGameTime(0.01, iTimerID_AutoComplete)
		else
			AutoResolveAssault()
		endif
	elseif(aiStageID == iStage_Shutdown)
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

Bool Function TryToMarkSuccessful()
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
		
	WorkshopScript kWorkshopRef = WorkshopAlias.GetRef() as WorkshopScript
	ObjectReference kDefendFromRef = DefendFromAlias.GetRef()
	
	
	; Add settlers to aliases
	if(bSettlersAreDefenders)
		Defenders.AddRefCollection(Settlers)
		DefenderFactionAlias.AddRefCollection(Settlers)
		Defenders.AddRefCollection(NonSpeakingSettlers)
		DefenderFactionAlias.AddRefCollection(NonSpeakingSettlers)
		
		Actor kLeaderRef = SettlementLeader.GetRef() as Actor
		
		if(kLeaderRef)
			Defenders.AddRef(kLeaderRef)
			DefenderFactionAlias.AddRef(kLeaderRef)
		endif
		
		if(iCurrentAssaultType != AssaultManager.iType_Defend)
			AddCollectionToCompleteAliases(Settlers, abDefenders = true)
			AddCollectionToCompleteAliases(NonSpeakingSettlers, abDefenders = true)
			
			if(kLeaderRef)
				if(ShouldForceSubdue(kLeaderRef) || iCurrentAssaultType == AssaultManager.iType_Attack_Subdue)
					SubdueToComplete.AddRef(kLeaderRef)
				else
					KillToComplete.AddRef(kLeaderRef)
				endif
			endif
		endif
	endif
	
	; Add robots to aliases
	if(bRobotsAreDefenders)
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
	
	
	; Spawn extra defenders
	if(iSpawnDefenders > 0 && SpawnDefenderForm != None)
		int i = 0
		while(i < iSpawnDefenders)
			Actor kDefenderRef = kDefendFromRef.PlaceActorAtMe(SpawnDefenderForm)
			
			if(kDefenderRef)
				SpawnedDefendersAlias.AddRef(kDefenderRef)
				Defenders.AddRef(kDefenderRef)
				DefenderFactionAlias.AddRef(kDefenderRef)
				
				if(iCurrentAssaultType != AssaultManager.iType_Defend)
					; Spawned NPCs should just be killed unless unique/essential already
					if(ShouldForceSubdue(kDefenderRef))
						SubdueToComplete.AddRef(kDefenderRef)
					else
						KillToComplete.AddRef(kDefenderRef)					
					endif
				endif
			endif
			
			i += 1
		endWhile
	endif
	
	; Setup attackers outside of the settlement somewhere
	ObjectReference kAttackFrom = AttackFromAlias.GetRef()
	
	; Spawn extra attackers
	if(iSpawnAttackers > 0 && SpawnAttackerForm != None)
		int i = 0
		while(i < iSpawnAttackers)
			Actor kAttackerRef = kAttackFrom.PlaceActorAtMe(SpawnAttackerForm)
			
			if(kAttackerRef)
				SpawnedAttackersAlias.AddRef(kAttackerRef)
				Attackers.AddRef(kAttackerRef)
				AttackerFactionAlias.AddRef(kAttackerRef)
				
				if(iCurrentAssaultType == AssaultManager.iType_Defend)
					; Spawned NPCs should just be killed unless unique/essential already
					if(ShouldForceSubdue(kAttackerRef))
						SubdueToComplete.AddRef(kAttackerRef)
					else
						KillToComplete.AddRef(kAttackerRef)
					endif
				endif
			endif
			
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
			; Just move OtherAttackers into position
			if(bMoveAttackersToStartPoint && OtherAttackers.GetCount() > 0)
				ObjectReference kAttackFromRef = AttackFromAlias.GetRef()
				int i = 0
				int iCount = OtherAttackers.GetCount()
				
				while(i < iCount)
					ObjectReference thisRef = OtherAttackers.GetAt(i)
					
					if(thisRef)
						Actor thisActor = thisRef as Actor
						
						if(thisActor)							
							thisActor.MoveTo(kAttackFromRef)
						endif
					endif
					
					i += 1
				endWhile
			endif
		endif
	endif
	
		
	if(bPlayerInvolved)
		if(iCurrentAssaultType == AssaultManager.iType_Defend)
			PlayerAllies.AddRefCollection(Defenders)
			PlayerEnemies.AddRefCollection(Attackers)
		else
			PlayerAllies.AddRefCollection(Attackers)
			PlayerEnemies.AddRefCollection(Defenders)
			
			; Turn settlement against the player		ControlManager.TurnSettlementAgainstPlayer(kWorkshopRef)
		endif
		
		; Clear the player enemy application from any allies in case they switched for some reason
		int i = 0
		while(i < PlayerAllies.GetCount())
			Actor thisActor = PlayerAllies.GetAt(i) as Actor
			
			if(thisActor)
				AssaultManager.RemainPlayerEnemy.RemoveFromRef(thisActor)
			endif
			
			i += 1
		endWhile
	endif
		
	if(SubdueToComplete.GetCount() == 0)
		SetStage(iStage_AllEnemiesSubdued)
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
			Stop()
		endif		
	endif
EndFunction


Function StartAssault()
	if(GetStageDone(iStage_Ready) && ! GetStageDone(iStage_Started))
		SetStage(iStage_Started)
		SetStage(iStage_TriggerAI)
			
		AssaultManager.AssaultStarted_Private(Self, WorkshopAlias.GetRef(), iCurrentAssaultType, AttackingFaction, DefendingFaction)
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
				
				if(FighterStrengthAV == None)
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
				
				if(FighterStrengthAV == None)
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
							if(FighterStrengthAV == None)
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
				
				if( ! bAttackersWin && iDefendersToKill < SpawnedAttackersAlias.GetCount())
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
			; Clear our RemainPlayerEnemy alias in case its applied
			int i = 0
			while(i < Settlers.GetCount())
				Actor thisActor = Settlers.GetAt(i) as Actor
				if(thisActor)
					AssaultManager.RemainPlayerEnemy.RemoveFromRef(thisActor)
				endif
				
				i += 1
			endWhile
			
			i = 0
			while(i < NonSpeakingSettlers.GetCount())
				Actor thisActor = NonSpeakingSettlers.GetAt(i) as Actor
				if(thisActor)
					AssaultManager.RemainPlayerEnemy.RemoveFromRef(thisActor)
				endif
				
				i += 1
			endWhile
		endif
		
		ControlManager.CaptureSettlement(WorkshopAlias.GetRef() as WorkshopScript, AttackingFactionData, bSeverEnemySupplyLines, bRemoveEnemySettlers, bKillEnemySettlers, bCaptureTurrets, bCaptureContainers, bSettlersJoinFaction, bTogglePlayerOwnership, bPlayerIsEnemy, iCreateInvadingSettlers)
	endif
EndFunction


Function StartAIPackages()
	if(AttackerFactionAlias.Find(PlayerAlias.GetRef()) >= 0)
		AssaultDefendersFaction.SetPlayerEnemy(true)
		
		if(DefendingFaction != None)
			DefendingFaction.SetPlayerEnemy(true)
		endif
	else
		AssaultAttackersFaction.SetPlayerEnemy(true)
		
		if(AttackingFaction != None)
			AttackingFaction.SetPlayerEnemy(true)
		endif
	endif
	
	Attackers.AddToFaction(ActivateAIFaction)
	Children.AddToFaction(ActivateAIFaction)
	Attackers.EvaluateAll()	
	Defenders.EvaluateAll()
EndFunction


Function AddCollectionToCompleteAliases(RefCollectionAlias aCollection, Bool abDefenders = false, Bool abGuardNPCs = false)
	int i = 0
	int iCount = aCollection.GetCount()
	ObjectReference kDefendFromRef = DefendFromAlias.GetRef()
	ObjectReference kAttackFromRef = AttackFromAlias.GetRef()
	
	while(i < iCount)
		ObjectReference thisRef = aCollection.GetAt(i)
		
		if(thisRef)
			Bool bSkipActor = false
			if(aCollection == Settlers || aCollection == NonSpeakingSettlers)
				if( ! (thisRef as Actor) as WorkshopNPCScript)
					bSkipActor = true
				endif
			endif
			
			if( ! bSkipActor)
				; Move units
				if(abDefenders && bMoveDefendersToCenterPoint)
					thisRef.MoveTo(kDefendFromRef)
				elseif( ! abDefenders && bMoveAttackersToStartPoint)
					thisRef.MoveTo(kAttackFromRef)
				endif
				
				; Add to victory tracking aliases
				if(ShouldForceSubdue(thisRef as Actor) || (iCurrentAssaultType == AssaultManager.iType_Attack_Subdue && abDefenders && ( ! abGuardNPCs || ! bGuardsKillableEvenOnSubdue)))
					SubdueToComplete.AddRef(thisRef)
				else
					KillToComplete.AddRef(thisRef)					
				endif
			endif
		endif
		
		i += 1
	endWhile
EndFunction


Bool Function ShouldForceSubdue(Actor akActorRef)
	if(akActorRef.IsEssential() || (bAlwaysSubdueUniques && akActorRef.GetLeveledActorBase().IsUnique()))
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


Function CleanupAssault()
	WorkshopScript thisWorkshop = WorkshopAlias.GetRef() as WorkshopScript
	
	Attackers.RemoveFromFaction(ActivateAIFaction) ; Clear attack AI
	
	if(bPlayerInvolved && bEnemySurvivorsRemainEnemyToPlayer)
		; Only mark them enemies to the player if this settlement wasn't captured - otherwise the player will be stuck murdering everyone inthe settlement
		if( ! bAutoCaptureSettlement || GetStageDone(iStage_Failed))
			int i = 0
			while(i < PlayerEnemies.GetCount())
				Actor thisActor = PlayerEnemies.GetAt(i) as Actor
				if(thisActor && ! thisActor.IsEssential())
					AssaultManager.RemainPlayerEnemy.ApplyToRef(thisActor)
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
	iCurrentAssaultType = -1
	
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
	
	RestoreBleedoutRecovery()
	
	SpawnAttackerForm = None
	iSpawnAttackers = 0
	OtherAttackers = None
	bMoveAttackersToStartPoint = true
	SpawnDefenderForm = None
	iSpawnDefenders = 0
	OtherDefenders = None
	bMoveDefendersToCenterPoint = true
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
	int i = 0
	while(i < Attackers.GetCount())
		Actor thisActor = Attackers.GetAt(i) as Actor
		
		if(thisActor.HasKeyword(BleedoutRecoveryStopped))
			thisActor.SetNoBleedoutRecovery(false)
			thisActor.RemoveKeyword(BleedoutRecoveryStopped)
		endif
		
		i += 1
	endWhile
	
	i = 0
	while(i < SubdueToComplete.GetCount())
		Actor thisActor = SubdueToComplete.GetAt(i) as Actor
		if(thisActor.HasKeyword(BleedoutRecoveryStopped))
			thisActor.SetNoBleedoutRecovery(false)
			thisActor.RemoveKeyword(BleedoutRecoveryStopped)
		endif
		
		i += 1
	endWhile
EndFunction