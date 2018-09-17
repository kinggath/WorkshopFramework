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
int ConsumptionLoopTimerID = 102 Const

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
	
	ActorValue Property WorkshopResourceObject Auto Const
	ActorValue Property HappinessBonus Auto Const
	ActorValue Property Happiness Auto Const Mandatory
	{ Actual happiness AV, not the bonus AV }
	ActorValue Property Food Auto Const
	ActorValue Property Water Auto Const
	ActorValue Property Safety Auto Const
	ActorValue Property Scavenge Auto Const
	ActorValue Property PowerGenerated Auto Const
	ActorValue Property Income Auto Const
	ActorValue Property Population Auto Const
	ActorValue Property RobotPopulation Auto Const
	
	ActorValue Property MissingFood Auto Const
	ActorValue Property MissingWater Auto Const
	
	ActorValue Property ExtraNeeds_Food Auto Const
	ActorValue Property ExtraNeeds_Safety Auto Const
	ActorValue Property ExtraNeeds_Water Auto Const
	
	ActorValue Property Negative_Food Auto Const
	ActorValue Property Negative_Water Auto Const
	ActorValue Property Negative_Safety Auto Const
	ActorValue Property Negative_PowerGenerated Auto Const
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
EndGroup

Group Aliases
	RefCollectionAlias Property LatestSettlementResources Auto Const Mandatory
	ReferenceAlias Property LatestWorkshop Auto Const Mandatory
	RefCollectionAlias Property WorkshopsAlias Auto Const Mandatory
	{ RefCollection mirroring the WorkshopsCollection on WorkshopParent }
EndGroup

Group Assets
	Form Property PositionHelper Auto Const Mandatory
EndGroup


Group SettingsToCopyToWorkshops
	GlobalVariable Property WSWF_Setting_minProductivity Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_productivityHappinessMult  Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_maxHappinessNoFood  Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_maxHappinessNoWater  Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_maxHappinessNoShelter  Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_happinessBonusFood  Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_happinessBonusWater  Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_happinessBonusBed Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_happinessBonusShelter Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_happinessBonusSafety Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_minHappinessChangePerUpdate Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_happinessChangeMult Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_minHappinessThreshold Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_minHappinessWarningThreshold Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_minHappinessClearWarningThreshold Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_happinessBonusChangePerUpdate Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_maxStoredFoodBase Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_maxStoredFoodPerPopulation Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_maxStoredWaterBase Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_maxStoredWaterPerPopulation Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_maxStoredScavengeBase Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_maxStoredScavengePerPopulation Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_brahminProductionBoost Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_maxProductionPerBrahmin Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_maxBrahminFertilizerProduction Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_maxStoredFertilizerBase Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_minVendorIncomePopulation Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_maxVendorIncome Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_vendorIncomePopulationMult Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_vendorIncomeBaseMult Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_iMaxSurplusNPCs Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_attractNPCDailyChance Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_iMaxBonusAttractChancePopulation Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_iBaseMaxNPCs Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_attractNPCHappinessMult Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_attackChanceBase Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_attackChanceResourceMult Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_attackChanceSafetyMult Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_attackChancePopulationMult Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_minDaysSinceLastAttack Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_damageDailyRepairBase Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_damageDailyPopulationMult Auto Const Mandatory
	GlobalVariable Property WSWF_Setting_iBaseMaxBrahmin Auto Hidden	
	GlobalVariable Property WSWF_Setting_iBaseMaxSynths Auto Hidden	
	GlobalVariable Property WSWF_Setting_recruitmentGuardChance Auto Hidden	
	GlobalVariable Property WSWF_Setting_recruitmentBrahminChance Auto Hidden	
	GlobalVariable Property WSWF_Setting_recruitmentSynthChance Auto Hidden	
	GlobalVariable Property WSWF_Setting_actorDeathHappinessModifier Auto Hidden	
	GlobalVariable Property WSWF_Setting_maxAttackStrength Auto Hidden	
	GlobalVariable Property WSWF_Setting_maxDefenseStrength Auto Hidden	
	GlobalVariable Property WSWF_Setting_AdjustMaxNPCsByCharisma Auto Hidden
	
	ActorValue Property WSWF_AV_minProductivity Auto Const Mandatory
	ActorValue Property WSWF_AV_productivityHappinessMult Auto Const Mandatory
	ActorValue Property WSWF_AV_maxHappinessNoFood  Auto Const Mandatory
	ActorValue Property WSWF_AV_maxHappinessNoWater  Auto Const Mandatory
	ActorValue Property WSWF_AV_maxHappinessNoShelter  Auto Const Mandatory
	ActorValue Property WSWF_AV_happinessBonusFood  Auto Const Mandatory
	ActorValue Property WSWF_AV_happinessBonusWater  Auto Const Mandatory
	ActorValue Property WSWF_AV_happinessBonusBed Auto Const Mandatory
	ActorValue Property WSWF_AV_happinessBonusShelter Auto Const Mandatory
	ActorValue Property WSWF_AV_happinessBonusSafety Auto Const Mandatory
	ActorValue Property WSWF_AV_minHappinessChangePerUpdate Auto Const Mandatory
	ActorValue Property WSWF_AV_happinessChangeMult Auto Const Mandatory
	ActorValue Property WSWF_AV_minHappinessThreshold Auto Const Mandatory
	ActorValue Property WSWF_AV_minHappinessWarningThreshold Auto Const Mandatory
	ActorValue Property WSWF_AV_minHappinessClearWarningThreshold Auto Const Mandatory
	ActorValue Property WSWF_AV_happinessBonusChangePerUpdate Auto Const Mandatory
	ActorValue Property WSWF_AV_maxStoredFoodBase Auto Const Mandatory
	ActorValue Property WSWF_AV_maxStoredFoodPerPopulation Auto Const Mandatory
	ActorValue Property WSWF_AV_maxStoredWaterBase Auto Const Mandatory
	ActorValue Property WSWF_AV_maxStoredWaterPerPopulation Auto Const Mandatory
	ActorValue Property WSWF_AV_maxStoredScavengeBase Auto Const Mandatory
	ActorValue Property WSWF_AV_maxStoredScavengePerPopulation Auto Const Mandatory
	ActorValue Property WSWF_AV_brahminProductionBoost Auto Const Mandatory
	ActorValue Property WSWF_AV_maxProductionPerBrahmin Auto Const Mandatory
	ActorValue Property WSWF_AV_maxBrahminFertilizerProduction Auto Const Mandatory
	ActorValue Property WSWF_AV_maxStoredFertilizerBase Auto Const Mandatory
	ActorValue Property WSWF_AV_minVendorIncomePopulation Auto Const Mandatory
	ActorValue Property WSWF_AV_maxVendorIncome Auto Const Mandatory
	ActorValue Property WSWF_AV_vendorIncomePopulationMult Auto Const Mandatory
	ActorValue Property WSWF_AV_vendorIncomeBaseMult Auto Const Mandatory
	ActorValue Property WSWF_AV_iMaxSurplusNPCs Auto Const Mandatory
	ActorValue Property WSWF_AV_attractNPCDailyChance Auto Const Mandatory
	ActorValue Property WSWF_AV_iMaxBonusAttractChancePopulation Auto Const Mandatory
	ActorValue Property WSWF_AV_iBaseMaxNPCs Auto Const Mandatory
	ActorValue Property WSWF_AV_attractNPCHappinessMult Auto Const Mandatory
	ActorValue Property WSWF_AV_attackChanceBase Auto Const Mandatory
	ActorValue Property WSWF_AV_attackChanceResourceMult Auto Const Mandatory
	ActorValue Property WSWF_AV_attackChanceSafetyMult Auto Const Mandatory
	ActorValue Property WSWF_AV_attackChancePopulationMult Auto Const Mandatory
	ActorValue Property WSWF_AV_minDaysSinceLastAttack Auto Const Mandatory
	ActorValue Property WSWF_AV_damageDailyRepairBase Auto Const Mandatory
	ActorValue Property WSWF_AV_damageDailyPopulationMult Auto Const Mandatory
	ActorValue Property WSWF_AV_MaxBrahmin Auto Const Mandatory
	ActorValue Property WSWF_AV_MaxSynths Auto Const Mandatory
	ActorValue Property WSWF_AV_recruitmentGuardChance Auto Const Mandatory	
	ActorValue Property WSWF_AV_recruitmentBrahminChance Auto Const Mandatory	
	ActorValue Property WSWF_AV_recruitmentSynthChance Auto Const Mandatory	
	ActorValue Property WSWF_AV_actorDeathHappinessModifier Auto Const Mandatory	
	ActorValue Property WSWF_AV_maxAttackStrength Auto Const Mandatory	
	ActorValue Property WSWF_AV_maxDefenseStrength Auto Const Mandatory	
	
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

Float Property fConsumptionLoopTime = 24.0 Auto Hidden

; ---------------------------------------------
; Vars
; ---------------------------------------------

Bool bConsumptionUnderwayBlock = false
Bool bGatherRunningBlock = false

; ---------------------------------------------
; Events 
; ---------------------------------------------

Event Actor.OnLocationChange(Actor akActorRef, Location akOldLoc, Location akNewLoc)
	HandleLocationChange(akNewLoc)
EndEvent


Event OnTimerGameTime(Int aiTimerID)
	if(aiTimerID == ConsumptionLoopTimerID)
		ConsumeAllWorkshopResources()
		
		StartConsumptionTimer()
	endif
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


Event Quest.OnStageSet(Quest akSenderRef, Int aiStageID, Int aiItemID)
	if(akSenderRef == WorkshopParent)
		StartConsumptionTimer()
	
		UnregisterForRemoteEvent(akSenderRef, "OnStageSet")
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
		AddSettlementResource(kObjectRef, false)
	elseif( ! kWorkshopRef.Is3dLoaded() && kObjectRef.IsDisabled() == false)
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
		RemoveSettlementResource(kObjectRef)
	endif
	
	if( ! kWorkshopRef.Is3dLoaded())
		ApplyObjectSettlementResources(kObjectRef, kWorkshopRef, true, true)
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
	
	SetupAllWorkshopProperties()
	
	; Start Consumption Loop
	if(WorkshopParent.GetStageDone(iWorkshopParentInitializedStage))
		StartConsumptionTimer()
	else
		RegisterForRemoteEvent(WorkshopParent, "OnStageSet")
	endif
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
	int iCount = WorkshopsAlias.GetCount()
	
	while(i < iCount)
		WorkshopScript thisWorkshop = WorkshopsAlias.GetAt(i) as WorkshopScript
		
		SetupNewWorkshopProperties(thisWorkshop)
		
		i += 1
	endWhile
EndFunction


Function SetupNewWorkshopProperties(WorkshopScript akWorkshopRef)
	if( ! akWorkshopRef)
		return
	endif
	
	akWorkshopRef.WSWF_Setting_minProductivity = WSWF_Setting_minProductivity
	akWorkshopRef.WSWF_Setting_productivityHappinessMult = WSWF_Setting_productivityHappinessMult
	akWorkshopRef.WSWF_Setting_maxHappinessNoFood = WSWF_Setting_maxHappinessNoFood
	akWorkshopRef.WSWF_Setting_maxHappinessNoWater = WSWF_Setting_maxHappinessNoWater
	akWorkshopRef.WSWF_Setting_maxHappinessNoShelter = WSWF_Setting_maxHappinessNoShelter
	akWorkshopRef.WSWF_Setting_happinessBonusFood = WSWF_Setting_happinessBonusFood
	akWorkshopRef.WSWF_Setting_happinessBonusWater = WSWF_Setting_happinessBonusWater
	akWorkshopRef.WSWF_Setting_happinessBonusBed = WSWF_Setting_happinessBonusBed
	akWorkshopRef.WSWF_Setting_happinessBonusShelter = WSWF_Setting_happinessBonusShelter
	akWorkshopRef.WSWF_Setting_happinessBonusSafety = WSWF_Setting_happinessBonusSafety
	akWorkshopRef.WSWF_Setting_minHappinessChangePerUpdate = WSWF_Setting_minHappinessChangePerUpdate
	akWorkshopRef.WSWF_Setting_happinessChangeMult = WSWF_Setting_happinessChangeMult
	akWorkshopRef.WSWF_Setting_minHappinessThreshold = WSWF_Setting_minHappinessThreshold
	akWorkshopRef.WSWF_Setting_minHappinessWarningThreshold = WSWF_Setting_minHappinessWarningThreshold
	akWorkshopRef.WSWF_Setting_minHappinessClearWarningThreshold = WSWF_Setting_minHappinessClearWarningThreshold
	akWorkshopRef.WSWF_Setting_happinessBonusChangePerUpdate = WSWF_Setting_happinessBonusChangePerUpdate
	akWorkshopRef.WSWF_Setting_maxStoredFoodBase = WSWF_Setting_maxStoredFoodBase
	akWorkshopRef.WSWF_Setting_maxStoredFoodPerPopulation = WSWF_Setting_maxStoredFoodPerPopulation
	akWorkshopRef.WSWF_Setting_maxStoredWaterBase = WSWF_Setting_maxStoredWaterBase
	akWorkshopRef.WSWF_Setting_maxStoredWaterPerPopulation = WSWF_Setting_maxStoredWaterPerPopulation
	akWorkshopRef.WSWF_Setting_maxStoredScavengeBase = WSWF_Setting_maxStoredScavengeBase
	akWorkshopRef.WSWF_Setting_maxStoredScavengePerPopulation = WSWF_Setting_maxStoredScavengePerPopulation
	akWorkshopRef.WSWF_Setting_brahminProductionBoost = WSWF_Setting_brahminProductionBoost
	akWorkshopRef.WSWF_Setting_maxProductionPerBrahmin = WSWF_Setting_maxProductionPerBrahmin
	akWorkshopRef.WSWF_Setting_maxBrahminFertilizerProduction = WSWF_Setting_maxBrahminFertilizerProduction
	akWorkshopRef.WSWF_Setting_maxStoredFertilizerBase = WSWF_Setting_maxStoredFertilizerBase
	akWorkshopRef.WSWF_Setting_minVendorIncomePopulation = WSWF_Setting_minVendorIncomePopulation
	akWorkshopRef.WSWF_Setting_maxVendorIncome = WSWF_Setting_maxVendorIncome
	akWorkshopRef.WSWF_Setting_vendorIncomePopulationMult = WSWF_Setting_vendorIncomePopulationMult
	akWorkshopRef.WSWF_Setting_vendorIncomeBaseMult = WSWF_Setting_vendorIncomeBaseMult
	akWorkshopRef.WSWF_Setting_iMaxSurplusNPCs = WSWF_Setting_iMaxSurplusNPCs
	akWorkshopRef.WSWF_Setting_attractNPCDailyChance = WSWF_Setting_attractNPCDailyChance
	akWorkshopRef.WSWF_Setting_iMaxBonusAttractChancePopulation = WSWF_Setting_iMaxBonusAttractChancePopulation
	akWorkshopRef.WSWF_Setting_iBaseMaxNPCs = WSWF_Setting_iBaseMaxNPCs
	akWorkshopRef.WSWF_Setting_attractNPCHappinessMult = WSWF_Setting_attractNPCHappinessMult
	akWorkshopRef.WSWF_Setting_attackChanceBase = WSWF_Setting_attackChanceBase
	akWorkshopRef.WSWF_Setting_attackChanceResourceMult = WSWF_Setting_attackChanceResourceMult
	akWorkshopRef.WSWF_Setting_attackChanceSafetyMult = WSWF_Setting_attackChanceSafetyMult
	akWorkshopRef.WSWF_Setting_attackChancePopulationMult = WSWF_Setting_attackChancePopulationMult
	akWorkshopRef.WSWF_Setting_minDaysSinceLastAttack = WSWF_Setting_minDaysSinceLastAttack
	akWorkshopRef.WSWF_Setting_damageDailyRepairBase = WSWF_Setting_damageDailyRepairBase
	akWorkshopRef.WSWF_Setting_damageDailyPopulationMult = WSWF_Setting_damageDailyPopulationMult
	akWorkshopRef.WSWF_Setting_iBaseMaxBrahmin = WSWF_Setting_iBaseMaxBrahmin
	akWorkshopRef.WSWF_Setting_iBaseMaxSynths = WSWF_Setting_iBaseMaxSynths
	akWorkshopRef.WSWF_Setting_recruitmentGuardChance = WSWF_Setting_recruitmentGuardChance
	akWorkshopRef.WSWF_Setting_recruitmentBrahminChance = WSWF_Setting_recruitmentBrahminChance
	akWorkshopRef.WSWF_Setting_recruitmentSynthChance = WSWF_Setting_recruitmentSynthChance
	akWorkshopRef.WSWF_Setting_actorDeathHappinessModifier = WSWF_Setting_actorDeathHappinessModifier
	akWorkshopRef.WSWF_Setting_maxAttackStrength = WSWF_Setting_maxAttackStrength
	akWorkshopRef.WSWF_Setting_maxDefenseStrength = WSWF_Setting_maxDefenseStrength
	akWorkshopRef.WSWF_Setting_AdjustMaxNPCsByCharisma = WSWF_Setting_AdjustMaxNPCsByCharisma
	akWorkshopRef.WSWF_AV_minProductivity = WSWF_AV_minProductivity
	akWorkshopRef.WSWF_AV_productivityHappinessMult = WSWF_AV_productivityHappinessMult
	akWorkshopRef.WSWF_AV_maxHappinessNoFood = WSWF_AV_maxHappinessNoFood
	akWorkshopRef.WSWF_AV_maxHappinessNoWater = WSWF_AV_maxHappinessNoWater
	akWorkshopRef.WSWF_AV_maxHappinessNoShelter = WSWF_AV_maxHappinessNoShelter
	akWorkshopRef.WSWF_AV_happinessBonusFood = WSWF_AV_happinessBonusFood
	akWorkshopRef.WSWF_AV_happinessBonusWater = WSWF_AV_happinessBonusWater
	akWorkshopRef.WSWF_AV_happinessBonusBed = WSWF_AV_happinessBonusBed
	akWorkshopRef.WSWF_AV_happinessBonusShelter = WSWF_AV_happinessBonusShelter
	akWorkshopRef.WSWF_AV_happinessBonusSafety = WSWF_AV_happinessBonusSafety
	akWorkshopRef.WSWF_AV_minHappinessChangePerUpdate = WSWF_AV_minHappinessChangePerUpdate
	akWorkshopRef.WSWF_AV_happinessChangeMult = WSWF_AV_happinessChangeMult
	akWorkshopRef.WSWF_AV_minHappinessThreshold = WSWF_AV_minHappinessThreshold
	akWorkshopRef.WSWF_AV_minHappinessWarningThreshold = WSWF_AV_minHappinessWarningThreshold
	akWorkshopRef.WSWF_AV_minHappinessClearWarningThreshold = WSWF_AV_minHappinessClearWarningThreshold
	akWorkshopRef.WSWF_AV_happinessBonusChangePerUpdate = WSWF_AV_happinessBonusChangePerUpdate
	akWorkshopRef.WSWF_AV_maxStoredFoodBase = WSWF_AV_maxStoredFoodBase
	akWorkshopRef.WSWF_AV_maxStoredFoodPerPopulation = WSWF_AV_maxStoredFoodPerPopulation
	akWorkshopRef.WSWF_AV_maxStoredWaterBase = WSWF_AV_maxStoredWaterBase
	akWorkshopRef.WSWF_AV_maxStoredWaterPerPopulation = WSWF_AV_maxStoredWaterPerPopulation
	akWorkshopRef.WSWF_AV_maxStoredScavengeBase = WSWF_AV_maxStoredScavengeBase
	akWorkshopRef.WSWF_AV_maxStoredScavengePerPopulation = WSWF_AV_maxStoredScavengePerPopulation
	akWorkshopRef.WSWF_AV_brahminProductionBoost = WSWF_AV_brahminProductionBoost
	akWorkshopRef.WSWF_AV_maxProductionPerBrahmin = WSWF_AV_maxProductionPerBrahmin
	akWorkshopRef.WSWF_AV_maxBrahminFertilizerProduction = WSWF_AV_maxBrahminFertilizerProduction
	akWorkshopRef.WSWF_AV_maxStoredFertilizerBase = WSWF_AV_maxStoredFertilizerBase
	akWorkshopRef.WSWF_AV_minVendorIncomePopulation = WSWF_AV_minVendorIncomePopulation
	akWorkshopRef.WSWF_AV_maxVendorIncome = WSWF_AV_maxVendorIncome
	akWorkshopRef.WSWF_AV_vendorIncomePopulationMult = WSWF_AV_vendorIncomePopulationMult
	akWorkshopRef.WSWF_AV_vendorIncomeBaseMult = WSWF_AV_vendorIncomeBaseMult
	akWorkshopRef.WSWF_AV_iMaxSurplusNPCs = WSWF_AV_iMaxSurplusNPCs
	akWorkshopRef.WSWF_AV_attractNPCDailyChance = WSWF_AV_attractNPCDailyChance
	akWorkshopRef.WSWF_AV_iMaxBonusAttractChancePopulation = WSWF_AV_iMaxBonusAttractChancePopulation
	akWorkshopRef.WSWF_AV_iBaseMaxNPCs = WSWF_AV_iBaseMaxNPCs
	akWorkshopRef.WSWF_AV_attractNPCHappinessMult = WSWF_AV_attractNPCHappinessMult
	akWorkshopRef.WSWF_AV_attackChanceBase = WSWF_AV_attackChanceBase
	akWorkshopRef.WSWF_AV_attackChanceResourceMult = WSWF_AV_attackChanceResourceMult
	akWorkshopRef.WSWF_AV_attackChanceSafetyMult = WSWF_AV_attackChanceSafetyMult
	akWorkshopRef.WSWF_AV_attackChancePopulationMult = WSWF_AV_attackChancePopulationMult
	akWorkshopRef.WSWF_AV_minDaysSinceLastAttack = WSWF_AV_minDaysSinceLastAttack
	akWorkshopRef.WSWF_AV_damageDailyRepairBase = WSWF_AV_damageDailyRepairBase
	akWorkshopRef.WSWF_AV_damageDailyPopulationMult = WSWF_AV_damageDailyPopulationMult
	akWorkshopRef.WSWF_AV_ExtraNeeds_Food = ExtraNeeds_Food
	akWorkshopRef.WSWF_AV_ExtraNeeds_Safety = ExtraNeeds_Safety
	akWorkshopRef.WSWF_AV_ExtraNeeds_Water = ExtraNeeds_Water
	
	akWorkshopRef.WSWF_AV_MaxBrahmin = WSWF_AV_MaxBrahmin
	akWorkshopRef.WSWF_AV_MaxSynths = WSWF_AV_MaxSynths
	akWorkshopRef.WSWF_AV_recruitmentGuardChance = WSWF_AV_recruitmentGuardChance
	akWorkshopRef.WSWF_AV_recruitmentBrahminChance = WSWF_AV_recruitmentBrahminChance
	akWorkshopRef.WSWF_AV_recruitmentSynthChance = WSWF_AV_recruitmentSynthChance
	akWorkshopRef.WSWF_AV_actorDeathHappinessModifier = WSWF_AV_actorDeathHappinessModifier
	akWorkshopRef.WSWF_AV_maxAttackStrength = WSWF_AV_maxAttackStrength
	akWorkshopRef.WSWF_AV_maxDefenseStrength = WSWF_AV_maxDefenseStrength
	
	
	akWorkshopRef.Happiness = Happiness
	akWorkshopRef.BonusHappiness = BonusHappiness
	akWorkshopRef.HappinessTarget = HappinessTarget
	akWorkshopRef.HappinessModifier = HappinessModifier
	akWorkshopRef.Population = Population
	akWorkshopRef.DamagePopulation = DamagePopulation
	akWorkshopRef.Food = Food
	akWorkshopRef.DamageFood = DamageFood
	akWorkshopRef.FoodActual = FoodActual
	akWorkshopRef.Power = Power
	akWorkshopRef.Water = Water
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

Function AddSettlementResource(ObjectReference akObjectRef, Bool bConfirmLink = true)
	if( ! bConfirmLink || akObjectRef.GetLinkedRef(WorkshopItemKeyword) == LatestWorkshop.GetRef())
		akObjectRef.AddKeyword(WorkshopResourceKeyword)
		LatestSettlementResources.AddRef(akObjectRef)
	endif
EndFunction

Function RemoveSettlementResource(ObjectReference akObjectRef)
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
		AddSettlementResource(ResourceObjects[i], false)
		
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


Function StartConsumptionTimer()
	StartTimerGameTime(fConsumptionLoopTime, ConsumptionLoopTimerID)
EndFunction

; TODO WSWF - Add support for toggling resource consumption/production to be enabled/disabled when the player doesn't own the settlement, currently it happens no matter what - which is probably more interesting, but may as well allow control
Function ConsumeAllWorkshopResources()
	if(bConsumptionUnderwayBlock)
		return
	endif
	
	bConsumptionUnderwayBlock = true
	
	Float fStartTime = Utility.GetCurrentRealtime()
	
	int i = 0
	int iCount = WorkshopsAlias.GetCount()
	
	while(i < iCount)
		WorkshopScript kWorkshopRef = WorkshopsAlias.GetAt(i) as WorkshopScript
		
		ConsumeWorkshopResources(kWorkshopRef)
		
		i += 1
	endWhile
	
	Debug.Trace("WSWF: Resource consumption for " + iCount + " workshops took " + (Utility.GetCurrentRealtime() - fStartTime) + " seconds.")
	
	bConsumptionUnderwayBlock = false
EndFunction


Function ConsumeWorkshopResources(WorkshopScript akWorkshopRef)
	if( ! akWorkshopRef)
		return
	endif
	
	Float fLivingPopulation = GetWorkshopValue(akWorkshopRef, Population) - GetWorkshopValue(akWorkshopRef, RobotPopulation)
	
	int iRequiredFood = fLivingPopulation as Int
	int iRequiredWater = fLivingPopulation as Int
	
	; Test if negative food/water production is being applied to simulate excessive requirements. This will ensure backwards compatibility with older Sim Settlements add-ons
	Int iCurrentFoodProductionValue = Math.Ceiling(GetWorkshopValue(akWorkshopRef, Food))
	Int iCurrentWaterProductionValue = Math.Ceiling(GetWorkshopValue(akWorkshopRef, Water))
	
	; Check for excess need
	if(iCurrentFoodProductionValue < 0)
		iRequiredFood += Math.Abs(iCurrentFoodProductionValue) as Int
	endif
	
	if(iCurrentWaterProductionValue < 0)
		iRequiredWater += Math.Abs(iCurrentWaterProductionValue) as Int
	endif
	
	ObjectReference FoodContainer = GetContainer(akWorkshopRef, FoodContainerKeyword)
	ObjectReference WaterContainer = GetContainer(akWorkshopRef, WaterContainerKeyword)
	
	int iAvailableFood = FoodContainer.GetItemCount(ObjectTypeFood)
	int iAvailableWater = WaterContainer.GetItemCount(ObjectTypeWater)
	
	FoodContainer.RemoveItem(ObjectTypeFood, iRequiredFood)
	WaterContainer.RemoveItem(ObjectTypeWater, iRequiredWater)
	
	iRequiredFood = Math.Abs(iAvailableFood - iRequiredFood) as Int
	iRequiredWater = Math.Abs(iAvailableWater - iRequiredWater) as Int
	
	if(iRequiredFood > 0 || iRequiredWater > 0)
		TransferResourcesFromLinkedWorkshops(akWorkshopRef, iRequiredFood, iRequiredWater)
		
		iAvailableFood = FoodContainer.GetItemCount(ObjectTypeFood)
		iAvailableWater = WaterContainer.GetItemCount(ObjectTypeWater)
		
		FoodContainer.RemoveItem(ObjectTypeFood, iRequiredFood)
		WaterContainer.RemoveItem(ObjectTypeWater, iRequiredWater)
		
		iRequiredFood = Math.Abs(iAvailableFood - iRequiredFood) as Int
		iRequiredWater = Math.Abs(iAvailableWater - iRequiredWater) as Int
	
		; Missing AVs are used by radiant quests
		akWorkshopRef.SetValue(MissingFood, iRequiredFood)
		akWorkshopRef.SetValue(MissingWater, iRequiredWater)
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


Function TransferResourcesFromLinkedWorkshops(WorkshopScript akWorkshopRef, Int aiNeededFood, Int aiNeededWater)
	; Adapted from UFO4P version of WorkshopParent.TransferResourcesFromLinkedWorkshops
	if( ! akWorkshopRef)
		return
	endif
	
	ObjectReference FoodContainer = GetContainer(akWorkshopRef, FoodContainerKeyword)
	ObjectReference WaterContainer = GetContainer(akWorkshopRef, WaterContainerKeyword)
	
	bool bTransferComplete = false
	
	Location[] linkedLocations = akWorkshopRef.myLocation.GetAllLinkedLocations(WorkshopCaravanKeyword)

	int iLinkedLocationCount = linkedLocations.Length
	int i = 0
	while(i < iLinkedLocationCount && ! bTransferComplete)
		int iLinkedWorkshopID = WorkshopLocations.Find(linkedLocations[i])
		if(iLinkedWorkshopID >= 0)
			WorkshopScript linkedWorkshopRef = GetWorkshop(iLinkedWorkshopID)
			
			if(aiNeededFood > 0)
				ObjectReference LinkedFoodContainer = GetContainer(linkedWorkshopRef, FoodContainerKeyword)
				
				if(LinkedFoodContainer)
					int iAvailableFood = LinkedFoodContainer.GetItemCount(ObjectTypeFood)
					if(iAvailableFood > 0)
						int iFoodToRemove = Math.Min(iAvailableFood, aiNeededFood) as int
						LinkedFoodContainer.RemoveItem(ObjectTypeFood, iFoodToRemove, true, FoodContainer)
						
						aiNeededFood -= iFoodToRemove
					endif
				endif
			endif
			
			if(aiNeededWater > 0)
				ObjectReference LinkedWaterContainer = GetContainer(linkedWorkshopRef, WaterContainerKeyword)
				
				if(LinkedWaterContainer)
					int iAvailableWater = LinkedWaterContainer.GetItemCount(ObjectTypeWater)
					if(iAvailableWater > 0)
						int iWaterToRemove = Math.Min(iAvailableWater, aiNeededWater) as int
						LinkedWaterContainer.RemoveItem(ObjectTypeWater, iWaterToRemove, true, WaterContainer)
						
						aiNeededWater -= iWaterToRemove
					endif
				endif
			endif
		endif

		if(aiNeededFood <= 0) && (aiNeededWater <= 0)
			bTransferComplete = true
		endif
		
		i += 1
	endWhile
endFunction


ObjectReference Function GetContainer(WorkshopScript akWorkshopRef, Keyword aTargetContainerKeyword = None)
	if( ! akWorkshopRef)
		return None
	endif
	
	; Copy from WorkshopProductionManager
	ObjectReference kContainer = akWorkshopRef.GetContainer()
	
	if(aTargetContainerKeyword)
		ObjectReference kTemp = akWorkshopRef.GetLinkedRef(aTargetContainerKeyword)
		
		if(kTemp)
			kContainer = kTemp
		endif
	endif
	
	return kContainer
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