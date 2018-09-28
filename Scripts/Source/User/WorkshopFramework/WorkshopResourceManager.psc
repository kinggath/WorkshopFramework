; ---------------------------------------------
; WorkshopFramework:WorkshopResourceManager.psc - by kinggath
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

Scriptname WorkshopFramework:WorkshopResourceManager extends WorkshopFramework:Library:SlaveQuest
{ This will provide two things: 1. When in a settlement, all resources will be stored in an alias so they are persisted until you leave - this will fix issues with places like Spectacle Island. 2. When building remote objects, it will update the settlement resources on the workshop to ensure the update applies when looking at the pipboy. }

import WorkshopFramework:Library:DataStructures
import WorkshopFramework:Library:UtilityFunctions
import WorkshopFramework:WorkshopFunctions


; ---------------------------------------------
; Consts
; ---------------------------------------------
int RecheckWithinSettlementTimerID = 100 Const
int FixSettlerCountTimerID = 101 Const

; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------

Group Controllers
	WorkshopFramework:MainThreadManager Property ThreadManager Auto Const Mandatory
	WorkshopParentScript Property WorkshopParent Auto Const Mandatory
	Int Property iWorkshopParentInitializedStage = 20 Auto Const
EndGroup


Group ActorValue
	Formlist Property WorkshopTrackedAVs Auto Const
	{ Formlist holding all AVs we're going to test items for }
	
	ActorValue Property WorkshopResourceObject Auto Const Mandatory
	ActorValue Property HappinessBonus Auto Const Mandatory
	ActorValue Property Happiness Auto Const Mandatory
	{ Actual happiness AV, not the bonus AV }
	ActorValue Property Food Auto Const Mandatory
	ActorValue Property Water Auto Const Mandatory
	ActorValue Property Safety Auto Const Mandatory
	ActorValue Property Scavenge Auto Const Mandatory
	ActorValue Property PowerGenerated Auto Const Mandatory
	ActorValue Property Income Auto Const Mandatory
	ActorValue Property Population Auto Const Mandatory
	ActorValue Property RobotPopulation Auto Const Mandatory
	
	ActorValue Property MissingFood Auto Const Mandatory
	ActorValue Property MissingWater Auto Const Mandatory
	
	ActorValue Property ExtraNeeds_Food Auto Const Mandatory
	ActorValue Property ExtraNeeds_Safety Auto Const Mandatory
	ActorValue Property ExtraNeeds_Water Auto Const Mandatory
	
	ActorValue Property Negative_Food Auto Const Mandatory
	ActorValue Property Negative_Water Auto Const Mandatory
	ActorValue Property Negative_Safety Auto Const Mandatory
	ActorValue Property Negative_PowerGenerated Auto Const Mandatory
EndGroup

Group Keywords
	Keyword Property WorkshopItemKeyword Auto Const Mandatory
	Keyword Property WorkshopCanBePowered Auto Const Mandatory
	Keyword Property WorkshopResourceKeyword Auto Const Mandatory
	{ Special keyword we're going to tag resources with that we've added to the LatestSettlementResources alias }
	Keyword Property FoodContainerKeyword Auto Const Mandatory
	Keyword Property WaterContainerKeyword Auto Const Mandatory
	Keyword Property ObjectTypeFood Auto Const Mandatory
	Keyword Property ObjectTypeWater Auto Const Mandatory
	Keyword Property WorkshopCaravanKeyword Auto Const Mandatory
	Keyword Property TemporarilyMoved Auto Const Mandatory
EndGroup

Group Aliases
	RefCollectionAlias Property LatestSettlementResources Auto Const Mandatory
	ReferenceAlias Property LatestWorkshop Auto Const Mandatory
EndGroup

Group Assets
	Form Property PositionHelper Auto Const Mandatory
EndGroup


Group SettingsToCopyToWorkshops
	GlobalVariable Property WSFW_Setting_minProductivity Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_productivityHappinessMult  Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_maxHappinessNoFood  Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_maxHappinessNoWater  Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_maxHappinessNoShelter  Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_happinessBonusFood  Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_happinessBonusWater  Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_happinessBonusBed Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_happinessBonusShelter Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_happinessBonusSafety Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_minHappinessChangePerUpdate Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_happinessChangeMult Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_minHappinessThreshold Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_minHappinessWarningThreshold Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_minHappinessClearWarningThreshold Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_happinessBonusChangePerUpdate Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_maxStoredFoodBase Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_maxStoredFoodPerPopulation Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_maxStoredWaterBase Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_maxStoredWaterPerPopulation Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_maxStoredScavengeBase Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_maxStoredScavengePerPopulation Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_brahminProductionBoost Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_maxProductionPerBrahmin Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_maxBrahminFertilizerProduction Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_maxStoredFertilizerBase Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_minVendorIncomePopulation Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_maxVendorIncome Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_vendorIncomePopulationMult Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_vendorIncomeBaseMult Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_iMaxSurplusNPCs Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_attractNPCDailyChance Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_iMaxBonusAttractChancePopulation Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_iBaseMaxNPCs Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_attractNPCHappinessMult Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_attackChanceBase Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_attackChanceResourceMult Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_attackChanceSafetyMult Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_attackChancePopulationMult Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_minDaysSinceLastAttack Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_damageDailyRepairBase Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_damageDailyPopulationMult Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_iBaseMaxBrahmin Auto Mandatory	
	GlobalVariable Property WSFW_Setting_iBaseMaxSynths Auto Mandatory	
	GlobalVariable Property WSFW_Setting_recruitmentGuardChance Auto Mandatory	
	GlobalVariable Property WSFW_Setting_recruitmentBrahminChance Auto Mandatory	
	GlobalVariable Property WSFW_Setting_recruitmentSynthChance Auto Mandatory	
	GlobalVariable Property WSFW_Setting_actorDeathHappinessModifier Auto Mandatory	
	GlobalVariable Property WSFW_Setting_maxAttackStrength Auto Mandatory	
	GlobalVariable Property WSFW_Setting_maxDefenseStrength Auto Mandatory	
	GlobalVariable Property WSFW_Setting_AdjustMaxNPCsByCharisma Auto Mandatory
	GlobalVariable Property WSFW_Setting_RobotHappinessLevel Auto Mandatory
	
	ActorValue Property WSFW_AV_minProductivity Auto Const Mandatory
	ActorValue Property WSFW_AV_productivityHappinessMult Auto Const Mandatory
	ActorValue Property WSFW_AV_maxHappinessNoFood  Auto Const Mandatory
	ActorValue Property WSFW_AV_maxHappinessNoWater  Auto Const Mandatory
	ActorValue Property WSFW_AV_maxHappinessNoShelter  Auto Const Mandatory
	ActorValue Property WSFW_AV_happinessBonusFood  Auto Const Mandatory
	ActorValue Property WSFW_AV_happinessBonusWater  Auto Const Mandatory
	ActorValue Property WSFW_AV_happinessBonusBed Auto Const Mandatory
	ActorValue Property WSFW_AV_happinessBonusShelter Auto Const Mandatory
	ActorValue Property WSFW_AV_happinessBonusSafety Auto Const Mandatory
	ActorValue Property WSFW_AV_minHappinessChangePerUpdate Auto Const Mandatory
	ActorValue Property WSFW_AV_happinessChangeMult Auto Const Mandatory
	ActorValue Property WSFW_AV_happinessBonusChangePerUpdate Auto Const Mandatory
	ActorValue Property WSFW_AV_maxStoredFoodBase Auto Const Mandatory
	ActorValue Property WSFW_AV_maxStoredFoodPerPopulation Auto Const Mandatory
	ActorValue Property WSFW_AV_maxStoredWaterBase Auto Const Mandatory
	ActorValue Property WSFW_AV_maxStoredWaterPerPopulation Auto Const Mandatory
	ActorValue Property WSFW_AV_maxStoredScavengeBase Auto Const Mandatory
	ActorValue Property WSFW_AV_maxStoredScavengePerPopulation Auto Const Mandatory
	ActorValue Property WSFW_AV_brahminProductionBoost Auto Const Mandatory
	ActorValue Property WSFW_AV_maxProductionPerBrahmin Auto Const Mandatory
	ActorValue Property WSFW_AV_maxBrahminFertilizerProduction Auto Const Mandatory
	ActorValue Property WSFW_AV_maxStoredFertilizerBase Auto Const Mandatory
	ActorValue Property WSFW_AV_minVendorIncomePopulation Auto Const Mandatory
	ActorValue Property WSFW_AV_maxVendorIncome Auto Const Mandatory
	ActorValue Property WSFW_AV_vendorIncomePopulationMult Auto Const Mandatory
	ActorValue Property WSFW_AV_vendorIncomeBaseMult Auto Const Mandatory
	ActorValue Property WSFW_AV_iMaxSurplusNPCs Auto Const Mandatory
	ActorValue Property WSFW_AV_attractNPCDailyChance Auto Const Mandatory
	ActorValue Property WSFW_AV_iMaxBonusAttractChancePopulation Auto Const Mandatory
	ActorValue Property WSFW_AV_iBaseMaxNPCs Auto Const Mandatory
	ActorValue Property WSFW_AV_attractNPCHappinessMult Auto Const Mandatory
	ActorValue Property WSFW_AV_attackChanceBase Auto Const Mandatory
	ActorValue Property WSFW_AV_attackChanceResourceMult Auto Const Mandatory
	ActorValue Property WSFW_AV_attackChanceSafetyMult Auto Const Mandatory
	ActorValue Property WSFW_AV_attackChancePopulationMult Auto Const Mandatory
	ActorValue Property WSFW_AV_minDaysSinceLastAttack Auto Const Mandatory
	ActorValue Property WSFW_AV_damageDailyRepairBase Auto Const Mandatory
	ActorValue Property WSFW_AV_damageDailyPopulationMult Auto Const Mandatory
	ActorValue Property WSFW_AV_MaxBrahmin Auto Const Mandatory
	ActorValue Property WSFW_AV_MaxSynths Auto Const Mandatory
	ActorValue Property WSFW_AV_recruitmentGuardChance Auto Const Mandatory	
	ActorValue Property WSFW_AV_recruitmentBrahminChance Auto Const Mandatory	
	ActorValue Property WSFW_AV_recruitmentSynthChance Auto Const Mandatory	
	ActorValue Property WSFW_AV_actorDeathHappinessModifier Auto Const Mandatory	
	ActorValue Property WSFW_AV_maxAttackStrength Auto Const Mandatory	
	ActorValue Property WSFW_AV_maxDefenseStrength Auto Const Mandatory	
	ActorValue Property WSFW_AV_RobotHappinessLevel Auto Const Mandatory	
	
	ActorValue Property BonusHappiness Auto Const Mandatory
	ActorValue Property HappinessTarget Auto Const Mandatory
	ActorValue Property HappinessModifier Auto Const Mandatory
	ActorValue Property DamagePopulation Auto Const Mandatory
	ActorValue Property DamageFood Auto Const Mandatory
	ActorValue Property FoodActual Auto Const Mandatory
	ActorValue Property Power Auto Const Mandatory
	ActorValue Property DamageSafety Auto Const Mandatory
	ActorValue Property MissingSafety Auto Const Mandatory
	ActorValue Property LastAttackDaysSince Auto Const Mandatory
	ActorValue Property WorkshopPlayerLostControl Auto Const Mandatory
	ActorValue Property WorkshopPlayerOwnership Auto Const Mandatory
	ActorValue Property PopulationRobots Auto Const Mandatory
	ActorValue Property PopulationBrahmin Auto Const Mandatory
	ActorValue Property PopulationUnassigned Auto Const Mandatory
	ActorValue Property VendorIncome Auto Const Mandatory
	ActorValue Property DamageCurrent Auto Const Mandatory
	ActorValue Property Beds Auto Const Mandatory
	ActorValue Property MissingBeds Auto Const Mandatory 
	ActorValue Property Caravan Auto Const Mandatory
	ActorValue Property Radio Auto Const Mandatory
	ActorValue Property WorkshopGuardPreference Auto Const Mandatory
	Keyword Property WorkshopType02 Auto Const Mandatory
	Keyword Property WorkshopLinkContainer Auto Const Mandatory
	Faction Property FarmDiscountFaction Auto Const Mandatory
	GlobalVariable Property CurrentWorkshopID Auto Const Mandatory
EndGroup


; ---------------------------------------------
; Properties
; ---------------------------------------------
	; Mirroring WorkshopParent arrays to reduce cross-ref talk which slows down code
WorkshopScript[] Property Workshops Auto Hidden
Location[] Property WorkshopLocations Auto Hidden 

; ---------------------------------------------
; Vars
; ---------------------------------------------

Bool bGatherRunningBlock = false


; ---------------------------------------------
; Events 
; ---------------------------------------------

Event Actor.OnLocationChange(Actor akActorRef, Location akOldLoc, Location akNewLoc)
	HandleLocationChange(akNewLoc)
EndEvent


Event OnTimer(Int aiTimerID)
	if(aiTimerID == RecheckWithinSettlementTimerID)
		CheckForWorkshopChange(true)
	elseif(aiTimerID == FixSettlerCountTimerID)
		Bool bSettlerCountStable = false
		ObjectReference kWorkshopRef = LatestWorkshop.GetRef()
		if(kWorkshopRef)
			Float fPopulationValue = kWorkshopRef.GetValue(Population)
			
			while( ! bSettlerCountStable)
				; Wait for recalculateResources to complete - this can take several seconds real time and there is no event for it
				Utility.Wait(1.0)
				Float fCurrentPop = kWorkshopRef.GetValue(Population)
				
				if(fCurrentPop != fPopulationValue)
					fPopulationValue = fCurrentPop
				else
					bSettlerCountStable = true
				endif
			endWhile
			
			FixSettlerCount()
		endif
	endif
EndEvent


Event WorkshopFramework:Library:ThreadRunner.OnThreadCompleted(WorkshopFramework:Library:ThreadRunner akThreadRunner, Var[] akargs)
	;/
	akargs[0] = sCustomCallCallbackID
	akargs[1] = iCallbackID
	akargs[2] = Result from called function
	/;
EndEvent


Event WorkshopParentScript.WorkshopObjectBuilt(WorkshopParentScript akSenderRef, Var[] akArgs)
	;/
	kargs[0] = newWorkshopObject
	kargs[1] = workshopRef
	/;
	
	ObjectReference kObjectRef = akArgs[0] as ObjectReference
	WorkshopScript kWorkshopRef = akArgs[1] as WorkshopScript
		
	if(kWorkshopRef == LatestWorkshop.GetRef() && kWorkshopRef.Is3dLoaded())
		; No need to alter tracked resources as this was placed in the current settlement
		TrackSettlementResource(kObjectRef, false)
	elseif( ! kWorkshopRef.Is3dLoaded() && kObjectRef.IsDisabled() == false)
		; Applying resources remotely
		ApplyObjectSettlementResources(kObjectRef, kWorkshopRef, false, true)
	endif
EndEvent

Event WorkshopParentScript.WorkshopObjectMoved(WorkshopParentScript akSenderRef, Var[] akArgs)
	;/
	kargs[0] = workshopObjectRef
	kargs[1] = workshopRef
	/;
EndEvent

Event WorkshopParentScript.WorkshopObjectDestroyed(WorkshopParentScript akSenderRef, Var[] akArgs)
	;/
	kargs[0] = workObject
	kargs[1] = workshopRef
	/;
	
	ObjectReference kObjectRef = akArgs[0] as ObjectReference
	WorkshopScript kWorkshopRef = akArgs[1] as WorkshopScript
		
	if(kWorkshopRef == LatestWorkshop.GetRef())
		UntrackSettlementResource(kObjectRef)
	endif
	
	if( ! kWorkshopRef.Is3dLoaded())
		ApplyObjectSettlementResources(kObjectRef, kWorkshopRef, abRemoved = true, abGetLock = true)
	endif
EndEvent

Event WorkshopParentScript.WorkshopActorAssignedToWork(WorkshopParentScript akSenderRef, Var[] akArgs)
	;/
	kargs[0] = assignedObject
	kargs[1] = workshopRef
	kargs[2] = actorRef ; Added with our version of scripts
	/;
EndEvent

Event WorkshopParentScript.WorkshopActorUnassigned(WorkshopParentScript akSenderRef, Var[] akArgs)
	;/
	kargs[0] = theObject
	kargs[1] = workshopRef
	kargs[2] = actorRef ; Added with our version of scripts
	/;
EndEvent

Event WorkshopParentScript.WorkshopObjectDestructionStageChanged(WorkshopParentScript akSenderRef, Var[] akArgs)
	;/
	kargs[0] = workObject
	kargs[1] = workshopRef
	/;
EndEvent

Event WorkshopParentScript.WorkshopObjectPowerStageChanged(WorkshopParentScript akSenderRef, Var[] akArgs)
	;/
	kargs[0] = workObject
	kargs[1] = workshopRef
	/;
EndEvent

Event WorkshopParentScript.WorkshopPlayerOwnershipChanged(WorkshopParentScript akSenderRef, Var[] akArgs)
	;/
	kargs[0] = workshopRef.OwnedByPlayer
	kargs[1] = workshopRef
	/;
EndEvent

Event WorkshopParentScript.WorkshopEnterMenu(WorkshopParentScript akSenderRef, Var[] akArgs)
	;/
	kargs[0] = None ; This appears to be a design decision so they could send the same sets of args to the tutorial quest
	kargs[1] = workshopRef
	kargs[2] = bEnteredWorkshopMode ; Added with our version of scripts
	/;
EndEvent

Event WorkshopParentScript.WorkshopObjectRepaired(WorkshopParentScript akSenderRef, Var[] akArgs)
	;/
	kargs[0] = workshopObjectRef
	kargs[1] = workshopRef
	/;
EndEvent


Event Quest.OnStageSet(Quest akSenderRef, Int aiStageID, Int aiItemID)
	if(akSenderRef == WorkshopParent)
		SetupAllWorkshopProperties()
	
		UnregisterForRemoteEvent(akSenderRef, "OnStageSet")
	endif
EndEvent

Event WorkshopParentScript.WorkshopInitializeLocation(WorkshopParentScript akSenderRef, Var[] akArgs)
	WorkshopScript akWorkshopRef = akArgs[0] as WorkshopScript
	
	SetupNewWorkshopProperties(akWorkshopRef)
EndEvent


; ---------------------------------------------
; Extended Handlers
; ---------------------------------------------

Function HandleQuestInit()
	Parent.HandleQuestInit()
	
	; Init arrays
	Workshops = new WorkshopScript[0]
	WorkshopLocations = new Location[0]
	
	; Register for events
	RegisterForRemoteEvent(PlayerRef, "OnLocationChange") ; We want to be directly aware of this for settlements like Spectacle Island
	RegisterForCustomEvent(WorkshopParent, "WorkshopInitializeLocation")
	
	ThreadManager.RegisterForCallbackThreads(Self)
	WorkshopParent.RegisterForWorkshopEvents(Self, bRegister = true)
	
	if(WorkshopParent.GetStageDone(iWorkshopParentInitializedStage))
		SetupAllWorkshopProperties()
	else
		RegisterForRemoteEvent(WorkshopParent, "OnStageSet")
	endif
EndFunction


Function HandleGameLoaded()
	Parent.HandleGameLoaded()
	
	if( ! Workshops)
		Workshops = new WorkshopScript[0]
	endif
	
	if( ! WorkshopLocations)
		WorkshopLocations = new Location[0]
	endif
	
	CleanFormList(WorkshopTrackedAVs)
EndFunction


Function HandleLocationChange(Location akNewLoc)
	if( ! akNewLoc)
		return
	endif
	
	CheckForWorkshopChange(false)
EndFunction


; ---------------------------------------------
; Overrides
; ---------------------------------------------


; ---------------------------------------------
; Functions
; ---------------------------------------------

Function SetupAllWorkshopProperties()
	int i = 0
	WorkshopScript[] WorkshopsArray = WorkshopParent.Workshops
	
	while(i < WorkshopsArray.Length)
		WorkshopScript thisWorkshop = WorkshopsArray[i]
		
		SetupNewWorkshopProperties(thisWorkshop)
		
		i += 1
	endWhile
EndFunction


Function SetupNewWorkshopProperties(WorkshopScript akWorkshopRef)
	if( ! akWorkshopRef)
		return
	endif
	
	akWorkshopRef.WSFW_Setting_minProductivity = WSFW_Setting_minProductivity
	akWorkshopRef.WSFW_Setting_productivityHappinessMult = WSFW_Setting_productivityHappinessMult
	akWorkshopRef.WSFW_Setting_maxHappinessNoFood = WSFW_Setting_maxHappinessNoFood
	akWorkshopRef.WSFW_Setting_maxHappinessNoWater = WSFW_Setting_maxHappinessNoWater
	akWorkshopRef.WSFW_Setting_maxHappinessNoShelter = WSFW_Setting_maxHappinessNoShelter
	akWorkshopRef.WSFW_Setting_happinessBonusFood = WSFW_Setting_happinessBonusFood
	akWorkshopRef.WSFW_Setting_happinessBonusWater = WSFW_Setting_happinessBonusWater
	akWorkshopRef.WSFW_Setting_happinessBonusBed = WSFW_Setting_happinessBonusBed
	akWorkshopRef.WSFW_Setting_happinessBonusShelter = WSFW_Setting_happinessBonusShelter
	akWorkshopRef.WSFW_Setting_happinessBonusSafety = WSFW_Setting_happinessBonusSafety
	akWorkshopRef.WSFW_Setting_minHappinessChangePerUpdate = WSFW_Setting_minHappinessChangePerUpdate
	akWorkshopRef.WSFW_Setting_happinessChangeMult = WSFW_Setting_happinessChangeMult
	akWorkshopRef.WSFW_Setting_minHappinessThreshold = WSFW_Setting_minHappinessThreshold
	akWorkshopRef.WSFW_Setting_minHappinessWarningThreshold = WSFW_Setting_minHappinessWarningThreshold
	akWorkshopRef.WSFW_Setting_minHappinessClearWarningThreshold = WSFW_Setting_minHappinessClearWarningThreshold
	akWorkshopRef.WSFW_Setting_happinessBonusChangePerUpdate = WSFW_Setting_happinessBonusChangePerUpdate
	akWorkshopRef.WSFW_Setting_maxStoredFoodBase = WSFW_Setting_maxStoredFoodBase
	akWorkshopRef.WSFW_Setting_maxStoredFoodPerPopulation = WSFW_Setting_maxStoredFoodPerPopulation
	akWorkshopRef.WSFW_Setting_maxStoredWaterBase = WSFW_Setting_maxStoredWaterBase
	akWorkshopRef.WSFW_Setting_maxStoredWaterPerPopulation = WSFW_Setting_maxStoredWaterPerPopulation
	akWorkshopRef.WSFW_Setting_maxStoredScavengeBase = WSFW_Setting_maxStoredScavengeBase
	akWorkshopRef.WSFW_Setting_maxStoredScavengePerPopulation = WSFW_Setting_maxStoredScavengePerPopulation
	akWorkshopRef.WSFW_Setting_brahminProductionBoost = WSFW_Setting_brahminProductionBoost
	akWorkshopRef.WSFW_Setting_maxProductionPerBrahmin = WSFW_Setting_maxProductionPerBrahmin
	akWorkshopRef.WSFW_Setting_maxBrahminFertilizerProduction = WSFW_Setting_maxBrahminFertilizerProduction
	akWorkshopRef.WSFW_Setting_maxStoredFertilizerBase = WSFW_Setting_maxStoredFertilizerBase
	akWorkshopRef.WSFW_Setting_minVendorIncomePopulation = WSFW_Setting_minVendorIncomePopulation
	akWorkshopRef.WSFW_Setting_maxVendorIncome = WSFW_Setting_maxVendorIncome
	akWorkshopRef.WSFW_Setting_vendorIncomePopulationMult = WSFW_Setting_vendorIncomePopulationMult
	akWorkshopRef.WSFW_Setting_vendorIncomeBaseMult = WSFW_Setting_vendorIncomeBaseMult
	akWorkshopRef.WSFW_Setting_iMaxSurplusNPCs = WSFW_Setting_iMaxSurplusNPCs
	akWorkshopRef.WSFW_Setting_attractNPCDailyChance = WSFW_Setting_attractNPCDailyChance
	akWorkshopRef.WSFW_Setting_iMaxBonusAttractChancePopulation = WSFW_Setting_iMaxBonusAttractChancePopulation
	akWorkshopRef.WSFW_Setting_iBaseMaxNPCs = WSFW_Setting_iBaseMaxNPCs
	akWorkshopRef.WSFW_Setting_attractNPCHappinessMult = WSFW_Setting_attractNPCHappinessMult
	akWorkshopRef.WSFW_Setting_attackChanceBase = WSFW_Setting_attackChanceBase
	akWorkshopRef.WSFW_Setting_attackChanceResourceMult = WSFW_Setting_attackChanceResourceMult
	akWorkshopRef.WSFW_Setting_attackChanceSafetyMult = WSFW_Setting_attackChanceSafetyMult
	akWorkshopRef.WSFW_Setting_attackChancePopulationMult = WSFW_Setting_attackChancePopulationMult
	akWorkshopRef.WSFW_Setting_minDaysSinceLastAttack = WSFW_Setting_minDaysSinceLastAttack
	akWorkshopRef.WSFW_Setting_damageDailyRepairBase = WSFW_Setting_damageDailyRepairBase
	akWorkshopRef.WSFW_Setting_damageDailyPopulationMult = WSFW_Setting_damageDailyPopulationMult
	akWorkshopRef.WSFW_Setting_iBaseMaxBrahmin = WSFW_Setting_iBaseMaxBrahmin
	akWorkshopRef.WSFW_Setting_iBaseMaxSynths = WSFW_Setting_iBaseMaxSynths
	akWorkshopRef.WSFW_Setting_recruitmentGuardChance = WSFW_Setting_recruitmentGuardChance
	akWorkshopRef.WSFW_Setting_recruitmentBrahminChance = WSFW_Setting_recruitmentBrahminChance
	akWorkshopRef.WSFW_Setting_recruitmentSynthChance = WSFW_Setting_recruitmentSynthChance
	akWorkshopRef.WSFW_Setting_actorDeathHappinessModifier = WSFW_Setting_actorDeathHappinessModifier
	akWorkshopRef.WSFW_Setting_maxAttackStrength = WSFW_Setting_maxAttackStrength
	akWorkshopRef.WSFW_Setting_maxDefenseStrength = WSFW_Setting_maxDefenseStrength
	akWorkshopRef.WSFW_Setting_AdjustMaxNPCsByCharisma = WSFW_Setting_AdjustMaxNPCsByCharisma
	akWorkshopRef.WSFW_Setting_AdjustMaxNPCsByCharisma = WSFW_Setting_RobotHappinessLevel
	
	akWorkshopRef.WSFW_AV_minProductivity = WSFW_AV_minProductivity
	akWorkshopRef.WSFW_AV_productivityHappinessMult = WSFW_AV_productivityHappinessMult
	akWorkshopRef.WSFW_AV_maxHappinessNoFood = WSFW_AV_maxHappinessNoFood
	akWorkshopRef.WSFW_AV_maxHappinessNoWater = WSFW_AV_maxHappinessNoWater
	akWorkshopRef.WSFW_AV_maxHappinessNoShelter = WSFW_AV_maxHappinessNoShelter
	akWorkshopRef.WSFW_AV_happinessBonusFood = WSFW_AV_happinessBonusFood
	akWorkshopRef.WSFW_AV_happinessBonusWater = WSFW_AV_happinessBonusWater
	akWorkshopRef.WSFW_AV_happinessBonusBed = WSFW_AV_happinessBonusBed
	akWorkshopRef.WSFW_AV_happinessBonusShelter = WSFW_AV_happinessBonusShelter
	akWorkshopRef.WSFW_AV_happinessBonusSafety = WSFW_AV_happinessBonusSafety
	akWorkshopRef.WSFW_AV_minHappinessChangePerUpdate = WSFW_AV_minHappinessChangePerUpdate
	akWorkshopRef.WSFW_AV_happinessChangeMult = WSFW_AV_happinessChangeMult
	akWorkshopRef.WSFW_AV_happinessBonusChangePerUpdate = WSFW_AV_happinessBonusChangePerUpdate
	akWorkshopRef.WSFW_AV_maxStoredFoodBase = WSFW_AV_maxStoredFoodBase
	akWorkshopRef.WSFW_AV_maxStoredFoodPerPopulation = WSFW_AV_maxStoredFoodPerPopulation
	akWorkshopRef.WSFW_AV_maxStoredWaterBase = WSFW_AV_maxStoredWaterBase
	akWorkshopRef.WSFW_AV_maxStoredWaterPerPopulation = WSFW_AV_maxStoredWaterPerPopulation
	akWorkshopRef.WSFW_AV_maxStoredScavengeBase = WSFW_AV_maxStoredScavengeBase
	akWorkshopRef.WSFW_AV_maxStoredScavengePerPopulation = WSFW_AV_maxStoredScavengePerPopulation
	akWorkshopRef.WSFW_AV_brahminProductionBoost = WSFW_AV_brahminProductionBoost
	akWorkshopRef.WSFW_AV_maxProductionPerBrahmin = WSFW_AV_maxProductionPerBrahmin
	akWorkshopRef.WSFW_AV_maxBrahminFertilizerProduction = WSFW_AV_maxBrahminFertilizerProduction
	akWorkshopRef.WSFW_AV_maxStoredFertilizerBase = WSFW_AV_maxStoredFertilizerBase
	akWorkshopRef.WSFW_AV_minVendorIncomePopulation = WSFW_AV_minVendorIncomePopulation
	akWorkshopRef.WSFW_AV_maxVendorIncome = WSFW_AV_maxVendorIncome
	akWorkshopRef.WSFW_AV_vendorIncomePopulationMult = WSFW_AV_vendorIncomePopulationMult
	akWorkshopRef.WSFW_AV_vendorIncomeBaseMult = WSFW_AV_vendorIncomeBaseMult
	akWorkshopRef.WSFW_AV_iMaxSurplusNPCs = WSFW_AV_iMaxSurplusNPCs
	akWorkshopRef.WSFW_AV_attractNPCDailyChance = WSFW_AV_attractNPCDailyChance
	akWorkshopRef.WSFW_AV_iMaxBonusAttractChancePopulation = WSFW_AV_iMaxBonusAttractChancePopulation
	akWorkshopRef.WSFW_AV_iBaseMaxNPCs = WSFW_AV_iBaseMaxNPCs
	akWorkshopRef.WSFW_AV_attractNPCHappinessMult = WSFW_AV_attractNPCHappinessMult
	akWorkshopRef.WSFW_AV_attackChanceBase = WSFW_AV_attackChanceBase
	akWorkshopRef.WSFW_AV_attackChanceResourceMult = WSFW_AV_attackChanceResourceMult
	akWorkshopRef.WSFW_AV_attackChanceSafetyMult = WSFW_AV_attackChanceSafetyMult
	akWorkshopRef.WSFW_AV_attackChancePopulationMult = WSFW_AV_attackChancePopulationMult
	akWorkshopRef.WSFW_AV_minDaysSinceLastAttack = WSFW_AV_minDaysSinceLastAttack
	akWorkshopRef.WSFW_AV_damageDailyRepairBase = WSFW_AV_damageDailyRepairBase
	akWorkshopRef.WSFW_AV_damageDailyPopulationMult = WSFW_AV_damageDailyPopulationMult
	akWorkshopRef.WSFW_AV_ExtraNeeds_Food = ExtraNeeds_Food
	akWorkshopRef.WSFW_AV_ExtraNeeds_Safety = ExtraNeeds_Safety
	akWorkshopRef.WSFW_AV_ExtraNeeds_Water = ExtraNeeds_Water
	akWorkshopRef.WSFW_AV_RobotHappinessLevel = WSFW_AV_RobotHappinessLevel
	
	
	akWorkshopRef.WSFW_AV_MaxBrahmin = WSFW_AV_MaxBrahmin
	akWorkshopRef.WSFW_AV_MaxSynths = WSFW_AV_MaxSynths
	akWorkshopRef.WSFW_AV_recruitmentGuardChance = WSFW_AV_recruitmentGuardChance
	akWorkshopRef.WSFW_AV_recruitmentBrahminChance = WSFW_AV_recruitmentBrahminChance
	akWorkshopRef.WSFW_AV_recruitmentSynthChance = WSFW_AV_recruitmentSynthChance
	akWorkshopRef.WSFW_AV_actorDeathHappinessModifier = WSFW_AV_actorDeathHappinessModifier
	akWorkshopRef.WSFW_AV_maxAttackStrength = WSFW_AV_maxAttackStrength
	akWorkshopRef.WSFW_AV_maxDefenseStrength = WSFW_AV_maxDefenseStrength
	
	
	akWorkshopRef.Happiness = Happiness
	akWorkshopRef.BonusHappiness = BonusHappiness
	akWorkshopRef.HappinessTarget = HappinessTarget
	akWorkshopRef.HappinessModifier = HappinessModifier
	akWorkshopRef.Population = Population
	akWorkshopRef.DamagePopulation = DamagePopulation
	akWorkshopRef.Food = Food
	akWorkshopRef.DamageFood = DamageFood
	akWorkshopRef.FoodActual = FoodActual
	akWorkshopRef.MissingFood = MissingFood
	akWorkshopRef.Power = Power
	akWorkshopRef.Water = Water
	akWorkshopRef.MissingWater = MissingWater
	akWorkshopRef.Safety = Safety
	akWorkshopRef.DamageSafety = DamageSafety
	akWorkshopRef.MissingSafety = MissingSafety
	akWorkshopRef.LastAttackDaysSince = LastAttackDaysSince
	akWorkshopRef.WorkshopPlayerLostControl = WorkshopPlayerLostControl
	akWorkshopRef.WorkshopPlayerOwnership = WorkshopPlayerOwnership
	akWorkshopRef.PopulationRobots = PopulationRobots
	akWorkshopRef.PopulationBrahmin = PopulationBrahmin
	akWorkshopRef.PopulationUnassigned = PopulationUnassigned
	akWorkshopRef.VendorIncome = VendorIncome
	akWorkshopRef.DamageCurrent = DamageCurrent
	akWorkshopRef.Beds = Beds
	akWorkshopRef.MissingBeds = MissingBeds 
	akWorkshopRef.Caravan = Caravan
	akWorkshopRef.Radio = Radio
	akWorkshopRef.WorkshopGuardPreference = WorkshopGuardPreference
	akWorkshopRef.WorkshopType02 = WorkshopType02
	akWorkshopRef.WorkshopCaravanKeyword = WorkshopCaravanKeyword
	akWorkshopRef.ObjectTypeWater = ObjectTypeWater
	akWorkshopRef.ObjectTypeFood = ObjectTypeFood
	akWorkshopRef.WorkshopLinkContainer = WorkshopLinkContainer
	akWorkshopRef.FarmDiscountFaction = FarmDiscountFaction
	akWorkshopRef.CurrentWorkshopID = CurrentWorkshopID
	
	; Add workshop and location to our copy of the arrays
	Workshops.Add(akWorkshopRef)
	WorkshopLocations.Add(akWorkshopRef.GetCurrentLocation())
	
	akWorkshopRef.bPropertiesConfigured = true
	
	ModTrace("[WSFW] Resource Manager: Finished configuring workshop vars. " + akWorkshopRef)
EndFunction

Function CheckForWorkshopChange(Bool abTimedDoubleCheck = false)
	WorkshopScript thisWorkshop = GetNearestWorkshop(PlayerRef)
	WorkshopScript previousWorkshop = LatestWorkshop.GetRef() as WorkshopScript
	
	if(thisWorkshop)
		if(thisWorkshop != previousWorkshop)		
			if( ! PlayerRef.IsWithinBuildableArea(thisWorkshop))
				if( ! abTimedDoubleCheck)
					StartTimer(5.0, RecheckWithinSettlementTimerID) ; Check again in a few seconds, the player could just be hanging out near the border
				endif
			elseif( ! previousWorkshop || ! PlayerRef.IsWithinBuildableArea(previousWorkshop))
				HandleWorkshopChange(thisWorkshop)
			endif
		else
			; Player moved to a new location within the same workshop - check for additional resources
			GatherLatestSettlementResources()
		endif
	endif
EndFunction


Function HandleWorkshopChange(WorkshopScript akWorkshopRef)
	FixSettlerCount() ; Do one last settler count fix before we leave - this should eliminate the pipboy display bug
	LatestWorkshop.ForceRefTo(akWorkshopRef)
	ClearLatestSettlementResources()
	GatherLatestSettlementResources()
EndFunction

Function ClearLatestSettlementResources()
	int i = 0
	while(i < LatestSettlementResources.GetCount())
		ObjectReference thisRef = LatestSettlementResources.GetAt(i)
		
		if(thisRef)
			thisRef.RemoveKeyword(WorkshopResourceKeyword)
		endif
		
		i += 1
	endWhile
	
	LatestSettlementResources.RemoveAll()
EndFunction

Function TrackSettlementResource(ObjectReference akObjectRef, Bool bConfirmLink = true)
	if( ! bConfirmLink || akObjectRef.GetLinkedRef(WorkshopItemKeyword) == LatestWorkshop.GetRef())
		akObjectRef.AddKeyword(WorkshopResourceKeyword)
		LatestSettlementResources.AddRef(akObjectRef)
	endif
EndFunction

Function UntrackSettlementResource(ObjectReference akObjectRef)
	akObjectRef.RemoveKeyword(WorkshopResourceKeyword)
	LatestSettlementResources.RemoveRef(akObjectRef)
EndFunction

Function GatherLatestSettlementResources()
	if(bGatherRunningBlock)
		return
	endif
	
	bGatherRunningBlock = true
	; Call workshopRef.GetWorkshopResourceObjects(None, 2)
	WorkshopScript thisWorkshop = LatestWorkshop.GetRef() as WorkshopScript
	
	if( ! thisWorkshop || ! PlayerRef.IsWithinBuildableArea(thisWorkshop))
		return
	endif
	
	ObjectReference[] ResourceObjects = thisWorkshop.GetWorkshopResourceObjects(None, 2)
	
	; Place results in LatestSettlementResources and tag with WorkshopResourceKeyword
	int i = 0
	while(i < ResourceObjects.Length)
		TrackSettlementResource(ResourceObjects[i], false)
		
		i += 1
	endWhile
		
	bGatherRunningBlock = false
EndFunction


Function FixSettlerCount()
	; There is a frequent bug in the game where the settler count will end up doubled in the UI, this will attempt to fix that
	
	int i = 0
	int iPopulation = 0
	while(i < LatestSettlementResources.GetCount())
		WorkshopNPCScript asWorkshopNPC = LatestSettlementResources.GetAt(i) as WorkshopNPCScript
		
		if(asWorkshopNPC && asWorkshopNPC.bCountsForPopulation)
			iPopulation += 1
		endif
		
		i += 1
	endWhile
	
	if(iPopulation > 0)
		ObjectReference thisWorkshop = LatestWorkshop.GetRef()
		thisWorkshop.SetValue(Population, iPopulation as Float)
	endif
EndFunction


Function ApplyObjectSettlementResources(ObjectReference akObjectRef, WorkshopScript akWorkshopRef, Bool abRemoved = false, Bool abGetLock = false)
	if( ! akWorkshopRef || akWorkshopRef.Is3dLoaded())
		return
	endif
	
	int iWorkshopID = akWorkshopRef.GetWorkshopID()
	
	if(iWorkshopID < 0)
		return
	endif
	
	int iLockKey
	if(abGetLock)
		; Get Edit Lock 
		iLockKey = GetLock()
		if(iLockKey <= GENERICLOCK_KEY_NONE)
			ModTrace("Unable to get lock!", 2)
			
			return
		endif
	endif
	
	Bool bContinue = true
		
	ObjectReference kHoldPosition = None
	if(akObjectRef.IsDisabled())
		if(abRemoved)
			kHoldPosition = akObjectRef.PlaceAtMe(PositionHelper, abInitiallyDisabled = true)
			akObjectRef.AddKeyword(TemporarilyMoved)
			akObjectRef.SetPosition(0.0, 0.0, -10000.0)
			akObjectRef.Enable(false) ; Temporarily enable for checking resources
		else
			bContinue = false
		endif
	endif
	
	if(bContinue)		
		WorkshopObjectScript asWorkshopObject = akObjectRef as WorkshopObjectScript
		
		Bool bCountResources = true
		if(asWorkshopObject)
			; For assignable objects, confirm they have a worker
			if(asWorkshopObject.RequiresActor() && ! asWorkshopObject.IsActorAssigned())
				bCountResources = false
			endif
		endif
		
		if(bCountResources && akObjectRef.HasKeyword(WorkshopCanBePowered) && ! akObjectRef.IsPowered())
			; For powered objects, confirm they have power
			bCountResources = false
		endif
			
		int i = 0
		if(bCountResources)
			while(i < WorkshopTrackedAVs.GetSize())
				ActorValue thisAV = WorkshopTrackedAVs.GetAt(i) as ActorValue
				if(thisAV)
					Float fAdjustBy = akObjectRef.GetValue(thisAV)
					
					if(fAdjustBy != 0)
						AdjustResource(akWorkshopRef, thisAV, fAdjustBy, abRemoved, false)
					endif
				endif
				
				i += 1
			endWhile
		endif
	endif
		
	if(kHoldPosition)
		akObjectRef.Disable(false)
		akObjectRef.MoveTo(kHoldPosition)
		akObjectRef.RemoveKeyword(TemporarilyMoved)
	endif
	
	if(abGetLock)
		; Release Edit Lock
		if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
			ModTrace("Failed to release lock " + iLockKey + "!", 2)
		endif	
	endif
EndFunction


Function AdjustResource(WorkshopScript akWorkshopRef, ActorValue ResourceAV, Float afAdjustBy, Bool abRemoved = false, Bool abGetLock = false)
	if( ! akWorkshopRef)
		return
	endif
	
	int iWorkshopID = akWorkshopRef.GetWorkshopID()
	
	if(iWorkshopID < 0)
		return
	endif
	
	int iLockKey
	if(abGetLock)
		; Get Edit Lock 
		iLockKey = GetLock()
		if(iLockKey <= GENERICLOCK_KEY_NONE)
			ModTrace("Unable to get lock!", 2)
			
			return
		endif
	endif
	
	Float fNewValue = 0.0
	Float fCurrentValue = akWorkshopRef.GetValue(ResourceAV)
	
	if(abRemoved)
		afAdjustBy *= -1
	endif
	
	fNewValue = fCurrentValue + afAdjustBy
	
	; Store negative values separately for UI affecting resources
	if(ResourceAV == Food)
		if(fNewValue < 0)
			akWorkshopRef.SetValue(Negative_Food, fNewValue)
			fNewValue = 0
		else
			akWorkshopRef.SetValue(Negative_Food, 0.0)
		endif		
	elseif(ResourceAV == Water)
		if(fNewValue < 0)
			akWorkshopRef.SetValue(Negative_Water, fNewValue)
			fNewValue = 0
		else
			akWorkshopRef.SetValue(Negative_Water, 0.0)
		endif
	elseif(ResourceAV == Safety)
		if(fNewValue < 0)
			akWorkshopRef.SetValue(Negative_Safety, fNewValue)
			fNewValue = 0
		else
			akWorkshopRef.SetValue(Negative_Safety, 0.0)
		endif
	elseif(ResourceAV == PowerGenerated)
		if(fNewValue < 0)
			akWorkshopRef.SetValue(Negative_PowerGenerated, fNewValue)
			fNewValue = 0
		else
			akWorkshopRef.SetValue(Negative_PowerGenerated, 0.0)
		endif
	endif
	
	akWorkshopRef.SetValue(ResourceAV, fNewValue)	
	
	if(abGetLock)
		; Release Edit Lock
		if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
			ModTrace("Failed to release lock " + iLockKey + "!", 2)
		endif	
	endif
EndFunction


Float Function GetProductivityMultiplier(WorkshopScript akWorkshopRef)
	if( ! akWorkshopRef)
		return 0.0
	endif
	
	Float fCurrentHappiness = akWorkshopRef.GetValue(Happiness)
	return akWorkshopRef.minProductivity + (fCurrentHappiness/100) * (1 - akWorkshopRef.minProductivity)
endFunction


Float Function GetLinkedPopulation(WorkshopScript akWorkshopRef, Bool abIncludeProductivityMultiplier = false)
	; adapted from WorkshopParent
	
	if( ! akWorkshopRef)
		return -1
	endif
	
	int iWorkshopID = akWorkshopRef.GetWorkshopID()
	
	if(iWorkshopID < 0)
		return -1
	endif
	
	Float fTotalLinkedPopulation = 0.0 ; using float for the sake of productivity calculations

	; get all linked workshop locations
	Location[] linkedLocations = akWorkshopRef.myLocation.GetAllLinkedLocations(WorkshopCaravanKeyword)
	int i = 0
	while(i < linkedLocations.Length)
		; get linked workshop from location
		int iLinkedWorkshopID = WorkshopLocations.Find(linkedLocations[i])
		
		if(iLinkedWorkshopID >= 0)
			WorkshopScript linkedWorkshop = GetWorkshop(iLinkedWorkshopID)
			
			; for this, we will use only unwounded population 
			Float fPopulation = Math.Max(linkedWorkshop.GetValue(Population), 0.0)
			
			if(abIncludeProductivityMultiplier)
				float fProductivity = GetProductivityMultiplier(linkedWorkshop)
				
				fPopulation = fPopulation * fProductivity
			endif
			
			; add linked population to total
			fTotalLinkedPopulation += fPopulation
		endif
		
		i += 1
	endwhile

	return fTotalLinkedPopulation
EndFunction


WorkshopScript Function GetWorkshop(Int aiWorkshopID)
	if(aiWorkshopID < 0 || aiWorkshopID >= Workshops.Length)
		return None
	endif
	
	return Workshops[aiWorkshopID]
EndFunction


WorkshopScript Function GetWorkshopFromLocation(Location akLocation)
	int iIndex = WorkshopLocations.Find(akLocation)
	
	if(iIndex >= 0)
		return Workshops[iIndex] as WorkshopScript
	endif
	
	return None
EndFunction


Float Function GetWorkshopValue(ObjectReference akWorkshopRef, ActorValue aValueToCheck)
	Float fValue = akWorkshopRef.GetValue(aValueToCheck)
	
	if(fValue == 0) ; If one of our negative supporters - check for a negative value
		if(aValueToCheck == Food)
			fValue = akWorkshopRef.GetValue(Negative_Food)
		elseif(aValueToCheck == Water)
			fValue = akWorkshopRef.GetValue(Negative_Water)
		elseif(aValueToCheck == Safety)
			fValue = akWorkshopRef.GetValue(Negative_Safety)
		elseif(aValueToCheck == PowerGenerated)
			fValue = akWorkshopRef.GetValue(Negative_PowerGenerated)
		endif
	endif
	
	return fValue
EndFunction