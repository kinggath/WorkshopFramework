Scriptname WorkshopScript extends ObjectReference Conditional
{script for Workshop reference}

; WSWF
import WorkshopFramework:Library:UtilityFunctions

;import WorkShopObjectScript
;import WorkshopParentScript

WorkshopParentScript Property WorkshopParent Auto Const mandatory
{ parent quest - holds most general workshop properties }

Location Property myLocation Auto Hidden
{workshop's location (filled onInit)
 this is a property so the WorkshopParent script can access it}

ObjectReference Property myMapMarker auto hidden
{workshop's map marker (filled by WorkshopParent.InitializeLocation) }

Group Optional
	Faction Property SettlementOwnershipFaction auto
	{ optional - if the workshop settlement has an ownership faction, set this here so the player can be added to that faction when workshop becomes player-owned }
	bool Property UseOwnershipFaction = true auto
	{ set to false to not use the ownership faction }

	ActorBase Property CustomWorkshopNPC Auto const
	{ Patch 1.4: the actor that gets created when a settlement makes a successful recruitment roll - overrides properties on WorkshopParentScript }

	Message Property CustomUnownedMessage const auto
	{ Patch 1.4: a custom unowned message, that overrides standard messages from WorkshopParentScript }
	
	bool Property AllowBrahminRecruitment = true auto const 
	{ Patch 1.6: set to false to prevent brahmin from being randomly recruited at this workshop settlement }
endGroup

group BuildingBudget
	int property MaxTriangles auto
	{ if > 0, initialize WorkshopMaxTriangles to this value }
	int property MaxDraws auto
	{ if > 0, initialize WorkshopMaxDraws to this value }
	int property CurrentTriangles auto
	{ if > 0, initialize WorkshopCurrentTriangles to this value }
	int property CurrentDraws auto
	{ if > 0, initialize WorkshopCurrentDraws to this value }
endGroup

Group Flags
	bool Property OwnedByPlayer = false Auto Conditional
	{ all workshops start "unowned" - activate after location is cleared to "own"
	}

	bool Property StartsHostile = false Auto Conditional
	{ set to true for workbench locations that start out with hostiles in control (to prevent it being counted as a valid Minuteman recruiting target)}

	bool Property EnableAutomaticPlayerOwnership = true Auto
	{ TRUE = workshop will automatically become usable when the location is cleared (or if there are no bosses)
	  FALSE = workshop won't be usable by player until SetOwnedByPlayer(true) is called on it
	 }

	bool Property AllowUnownedFromLowHappiness = false Auto
	{ 	TRUE = workshop can become unowned due to low happiness (<=minHappinessThreshold)
		FALSE (default) = workshop can never become unowned, no matter how low the happiness (for special cases like the Castle)
	}

	bool Property HappinessWarning Auto Hidden Conditional
	{ set to true when happiness warning given; set back to false when happiness goes above the warning level 
	  NOTE: only applies when AllowUnownedFromLowHappiness = true }

	int Property DaysSinceLastVisit Auto Hidden Conditional
	{ this gets cleared when player visits, incremented by daily update }

	bool Property PlayerHasVisited Auto Hidden Conditional
	{ this gets set to true the first time player visits - used by ResetWorkshop to initialize data on first visit }

	bool Property MinRecruitmentProhibitRandom = false Auto Conditional
	{ set to TRUE to prohibit random Minutemen recruitment quests from picking this workshop
	}

	bool Property MinRecruitmentAllowRandomAfterPlayerOwned = true Auto Conditional
	{ set to FALSE to prohibit random Minutemen quests from picking this workshop AFTER the player takes over (TRUE = random quests are allowed once owned by player)
	}

	bool Property AllowAttacksBeforeOwned = true auto conditional
	{ set to FALSE to prevent attacks when unowned
		NOTE: this always gets set to true when the player takes ownership for the first time
	}

	bool Property AllowAttacks = true auto conditional
	{ set to FALSE to prevent ALL random attacks (e.g. the Castle)
	}

	bool Property RadioBeaconFirstRecruit = false auto conditional hidden
	{ set to true after player first builds a radio beacon here and gets the first "quick" recruit }

	bool Property ShowedWorkshopMenuExitMessage = false auto conditional hidden
	{ set to true after player first exits the workshop menu here }
	
endGroup

int WorkshopID = -1 	; initialize to real workshop ID first time it's requested (workshopID = index of this workshop in WorkshopParent.Workshops)

Group VendorData
	ObjectReference[] Property VendorContainersMisc auto hidden
	{
		array of Misc vendor containers, indexed by vendor level
	 }
	ObjectReference[] Property VendorContainersArmor auto hidden
	ObjectReference[] Property VendorContainersWeapons auto hidden
	ObjectReference[] Property VendorContainersBar auto hidden
	ObjectReference[] Property VendorContainersClinic auto hidden
	ObjectReference[] Property VendorContainersClothing auto hidden
endGroup

; 1.6: optional radio override data
Group WorkshopRadioData
	ObjectReference Property WorkshopRadioRef Auto Const
	{ if WorkshopRadioRef exists, it will override the default WorkshopRadioRef from WorkshopParent }

	float property workshopRadioInnerRadius = 9000.0 auto const
	{ override workshop parent values }
	float property workshopRadioOuterRadius = 20000.0 auto const
	{ override workshop parent values }

	Scene Property WorkshopRadioScene Auto Const
	{ if WorkshopRadioRef exists, WorkshopRadioScene will be started instead of the default scene from WorkshopParent }

	bool property bWorkshopRadioRefIsUnique = true auto const 
	{ TRUE: WorkshopRadioScene is unique to this workshop, so it should be stopped/disabled when radio is shut off (completely) }
endGroup

; -------------------------------
; WSWF - New Properties
; -------------------------------

Group WSWF_Globals
	GlobalVariable Property WSWF_Setting_minProductivity Auto Hidden
	GlobalVariable Property WSWF_Setting_productivityHappinessMult  Auto Hidden
	GlobalVariable Property WSWF_Setting_maxHappinessNoFood  Auto Hidden
	GlobalVariable Property WSWF_Setting_maxHappinessNoWater  Auto Hidden
	GlobalVariable Property WSWF_Setting_maxHappinessNoShelter  Auto Hidden
	GlobalVariable Property WSWF_Setting_happinessBonusFood  Auto Hidden
	GlobalVariable Property WSWF_Setting_happinessBonusWater  Auto Hidden
	GlobalVariable Property WSWF_Setting_happinessBonusBed Auto Hidden
	GlobalVariable Property WSWF_Setting_happinessBonusShelter Auto Hidden
	GlobalVariable Property WSWF_Setting_happinessBonusSafety Auto Hidden
	GlobalVariable Property WSWF_Setting_minHappinessChangePerUpdate Auto Hidden
	GlobalVariable Property WSWF_Setting_happinessChangeMult Auto Hidden
	GlobalVariable Property WSWF_Setting_minHappinessThreshold Auto Hidden
	GlobalVariable Property WSWF_Setting_minHappinessWarningThreshold Auto Hidden
	GlobalVariable Property WSWF_Setting_minHappinessClearWarningThreshold Auto Hidden
	GlobalVariable Property WSWF_Setting_happinessBonusChangePerUpdate Auto Hidden
	GlobalVariable Property WSWF_Setting_maxStoredFoodBase Auto Hidden
	GlobalVariable Property WSWF_Setting_maxStoredFoodPerPopulation Auto Hidden
	GlobalVariable Property WSWF_Setting_maxStoredWaterBase Auto Hidden
	GlobalVariable Property WSWF_Setting_maxStoredWaterPerPopulation Auto Hidden
	GlobalVariable Property WSWF_Setting_maxStoredScavengeBase Auto Hidden
	GlobalVariable Property WSWF_Setting_maxStoredScavengePerPopulation Auto Hidden
	GlobalVariable Property WSWF_Setting_brahminProductionBoost Auto Hidden
	GlobalVariable Property WSWF_Setting_maxProductionPerBrahmin Auto Hidden
	GlobalVariable Property WSWF_Setting_maxBrahminFertilizerProduction Auto Hidden
	GlobalVariable Property WSWF_Setting_maxStoredFertilizerBase Auto Hidden
	GlobalVariable Property WSWF_Setting_minVendorIncomePopulation Auto Hidden
	GlobalVariable Property WSWF_Setting_maxVendorIncome Auto Hidden
	GlobalVariable Property WSWF_Setting_vendorIncomePopulationMult Auto Hidden
	GlobalVariable Property WSWF_Setting_vendorIncomeBaseMult Auto Hidden
	GlobalVariable Property WSWF_Setting_iMaxSurplusNPCs Auto Hidden
	GlobalVariable Property WSWF_Setting_attractNPCDailyChance Auto Hidden
	GlobalVariable Property WSWF_Setting_iMaxBonusAttractChancePopulation Auto Hidden
	GlobalVariable Property WSWF_Setting_iBaseMaxNPCs Auto Hidden
	GlobalVariable Property WSWF_Setting_attractNPCHappinessMult Auto Hidden
	GlobalVariable Property WSWF_Setting_attackChanceBase Auto Hidden
	GlobalVariable Property WSWF_Setting_attackChanceResourceMult Auto Hidden
	GlobalVariable Property WSWF_Setting_attackChanceSafetyMult Auto Hidden
	GlobalVariable Property WSWF_Setting_attackChancePopulationMult Auto Hidden
	GlobalVariable Property WSWF_Setting_minDaysSinceLastAttack Auto Hidden
	GlobalVariable Property WSWF_Setting_damageDailyRepairBase Auto Hidden
	GlobalVariable Property WSWF_Setting_damageDailyPopulationMult Auto Hidden
	
	GlobalVariable Property WSWF_Setting_iBaseMaxBrahmin Auto Hidden	
	GlobalVariable Property WSWF_Setting_iBaseMaxSynths Auto Hidden	
	
	GlobalVariable Property WSWF_Setting_recruitmentGuardChance Auto Hidden	
	GlobalVariable Property WSWF_Setting_recruitmentBrahminChance Auto Hidden	
	GlobalVariable Property WSWF_Setting_recruitmentSynthChance Auto Hidden	
	GlobalVariable Property WSWF_Setting_actorDeathHappinessModifier Auto Hidden	
	GlobalVariable Property WSWF_Setting_maxAttackStrength Auto Hidden	
	GlobalVariable Property WSWF_Setting_maxDefenseStrength Auto Hidden	
	
	GlobalVariable Property WSWF_Setting_AdjustMaxNPCsByCharisma Auto Hidden
EndGroup

Group WSWF_AVs
	ActorValue Property WSWF_AV_minProductivity Auto Hidden
	ActorValue Property WSWF_AV_productivityHappinessMult  Auto Hidden
	ActorValue Property WSWF_AV_maxHappinessNoFood  Auto Hidden
	ActorValue Property WSWF_AV_maxHappinessNoWater  Auto Hidden
	ActorValue Property WSWF_AV_maxHappinessNoShelter  Auto Hidden
	ActorValue Property WSWF_AV_happinessBonusFood  Auto Hidden
	ActorValue Property WSWF_AV_happinessBonusWater  Auto Hidden
	ActorValue Property WSWF_AV_happinessBonusBed Auto Hidden
	ActorValue Property WSWF_AV_happinessBonusShelter Auto Hidden
	ActorValue Property WSWF_AV_happinessBonusSafety Auto Hidden
	ActorValue Property WSWF_AV_minHappinessChangePerUpdate Auto Hidden
	ActorValue Property WSWF_AV_happinessChangeMult Auto Hidden
	ActorValue Property WSWF_AV_minHappinessThreshold Auto Hidden
	ActorValue Property WSWF_AV_minHappinessWarningThreshold Auto Hidden
	ActorValue Property WSWF_AV_minHappinessClearWarningThreshold Auto Hidden
	ActorValue Property WSWF_AV_happinessBonusChangePerUpdate Auto Hidden
	ActorValue Property WSWF_AV_maxStoredFoodBase Auto Hidden
	ActorValue Property WSWF_AV_maxStoredFoodPerPopulation Auto Hidden
	ActorValue Property WSWF_AV_maxStoredWaterBase Auto Hidden
	ActorValue Property WSWF_AV_maxStoredWaterPerPopulation Auto Hidden
	ActorValue Property WSWF_AV_maxStoredScavengeBase Auto Hidden
	ActorValue Property WSWF_AV_maxStoredScavengePerPopulation Auto Hidden
	ActorValue Property WSWF_AV_brahminProductionBoost Auto Hidden
	ActorValue Property WSWF_AV_maxProductionPerBrahmin Auto Hidden
	ActorValue Property WSWF_AV_maxBrahminFertilizerProduction Auto Hidden
	ActorValue Property WSWF_AV_maxStoredFertilizerBase Auto Hidden
	ActorValue Property WSWF_AV_minVendorIncomePopulation Auto Hidden
	ActorValue Property WSWF_AV_maxVendorIncome Auto Hidden
	ActorValue Property WSWF_AV_vendorIncomePopulationMult Auto Hidden
	ActorValue Property WSWF_AV_vendorIncomeBaseMult Auto Hidden
	ActorValue Property WSWF_AV_iMaxSurplusNPCs Auto Hidden
	ActorValue Property WSWF_AV_attractNPCDailyChance Auto Hidden
	ActorValue Property WSWF_AV_iMaxBonusAttractChancePopulation Auto Hidden
	ActorValue Property WSWF_AV_iBaseMaxNPCs Auto Hidden
	ActorValue Property WSWF_AV_attractNPCHappinessMult Auto Hidden
	ActorValue Property WSWF_AV_attackChanceBase Auto Hidden
	ActorValue Property WSWF_AV_attackChanceResourceMult Auto Hidden
	ActorValue Property WSWF_AV_attackChanceSafetyMult Auto Hidden
	ActorValue Property WSWF_AV_attackChancePopulationMult Auto Hidden
	ActorValue Property WSWF_AV_minDaysSinceLastAttack Auto Hidden
	ActorValue Property WSWF_AV_damageDailyRepairBase Auto Hidden
	ActorValue Property WSWF_AV_damageDailyPopulationMult Auto Hidden
	
	ActorValue Property WSWF_AV_ExtraNeeds_Food Auto Hidden
	ActorValue Property WSWF_AV_ExtraNeeds_Safety Auto Hidden
	ActorValue Property WSWF_AV_ExtraNeeds_Water Auto Hidden
	
	ActorValue Property WSWF_AV_MaxBrahmin Auto Hidden
	ActorValue Property WSWF_AV_MaxSynths Auto Hidden	
	ActorValue Property WSWF_AV_recruitmentGuardChance Auto Hidden	
	ActorValue Property WSWF_AV_recruitmentBrahminChance Auto Hidden	
	ActorValue Property WSWF_AV_recruitmentSynthChance Auto Hidden	
	ActorValue Property WSWF_AV_actorDeathHappinessModifier Auto Hidden	
	ActorValue Property WSWF_AV_maxAttackStrength Auto Hidden	
	ActorValue Property WSWF_AV_maxDefenseStrength Auto Hidden	

	; Replacing calls to WorkshopParent ratings vars
	ActorValue Property Happiness Auto Hidden
	ActorValue Property BonusHappiness Auto Hidden
	ActorValue Property HappinessTarget Auto Hidden
	ActorValue Property HappinessModifier Auto Hidden
	ActorValue Property Population Auto Hidden
	ActorValue Property DamagePopulation Auto Hidden
	ActorValue Property Food Auto Hidden
	ActorValue Property DamageFood Auto Hidden
	ActorValue Property FoodActual Auto Hidden
	ActorValue Property Power Auto Hidden
	ActorValue Property Water Auto Hidden
	ActorValue Property Safety Auto Hidden
	ActorValue Property DamageSafety Auto Hidden
	ActorValue Property MissingSafety Auto Hidden
	ActorValue Property LastAttackDaysSince Auto Hidden
	ActorValue Property WorkshopPlayerLostControl Auto Hidden
	ActorValue Property WorkshopPlayerOwnership Auto Hidden
	ActorValue Property PopulationRobots Auto Hidden
	ActorValue Property BrahminPopulation Auto Hidden
	ActorValue Property PopulationUnassigned Auto Hidden
	ActorValue Property VendorIncome Auto Hidden
	ActorValue Property DamageCurrent Auto Hidden
	ActorValue Property Beds Auto Hidden
	ActorValue Property MissingBeds Auto Hidden 
	ActorValue Property Caravan Auto Hidden
	ActorValue Property Radio Auto Hidden
	ActorValue Property WorkshopGuardPreference Auto Hidden
	Keyword Property WorkshopType02 Auto Hidden
	Keyword Property WorkshopCaravanKeyword Auto Hidden
	Keyword Property ObjectTypeWater Auto Hidden
	Keyword Property ObjectTypeFood Auto Hidden
	Keyword Property WorkshopLinkContainer Auto Hidden
	Faction Property FarmDiscountFaction Auto Hidden
	GlobalVariable Property CurrentWorkshopID Auto Hidden
EndGroup

;******************
; moved from workshopparent			
; WSWF: Note - This was all added here by BGS to avoid having to constantly query WorkshopParent for the numbers

; productivity formula stuff
Bool Property bUseGlobalminProductivity = true Auto Hidden
Float WSWF_minProductivity = 0.25
float Property minProductivity
	Float Function Get()
		Float AppliedValue = GetValue(WSWF_AV_minProductivity)
		
		if(bUseGlobalminProductivity)
			return AppliedValue + WSWF_Setting_minProductivity.GetValue()
		else
			return AppliedValue + WSWF_minProductivity
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSWF_minProductivity = aValue
	EndFunction
EndProperty

Bool Property bUseGlobalproductivityHappinessMult = true Auto Hidden
Float WSWF_productivityHappinessMult = 0.75
float Property productivityHappinessMult
	Float Function Get()
		Float AppliedValue = GetValue(WSWF_AV_productivityHappinessMult)
		
		if(bUseGlobalproductivityHappinessMult)
			return AppliedValue + WSWF_Setting_productivityHappinessMult.GetValue()
		else
			return AppliedValue + WSWF_productivityHappinessMult
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSWF_productivityHappinessMult = aValue
	EndFunction
EndProperty

; happiness formula stuff
Bool Property bUseGlobalmaxHappinessNoFood = true Auto Hidden
Float WSWF_maxHappinessNoFood = 30.0
float Property maxHappinessNoFood
	Float Function Get()
		Float AppliedValue = GetValue(WSWF_AV_maxHappinessNoFood)
		
		if(bUseGlobalmaxHappinessNoFood)
			return AppliedValue + WSWF_Setting_maxHappinessNoFood.GetValue()
		else
			return AppliedValue + WSWF_maxHappinessNoFood
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSWF_maxHappinessNoFood = aValue
	EndFunction
EndProperty

Bool Property bUseGlobalmaxHappinessNoWater = true Auto Hidden
Float WSWF_maxHappinessNoWater = 30.0
float Property maxHappinessNoWater
	Float Function Get()
		Float AppliedValue = GetValue(WSWF_AV_maxHappinessNoWater)
		
		if(bUseGlobalmaxHappinessNoWater)
			return AppliedValue + WSWF_Setting_maxHappinessNoWater.GetValue()
		else
			return AppliedValue + WSWF_maxHappinessNoWater
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSWF_maxHappinessNoWater = aValue
	EndFunction
EndProperty

Bool Property bUseGlobalmaxHappinessNoShelter = true Auto Hidden
Float WSWF_maxHappinessNoShelter = 60.0
float Property maxHappinessNoShelter
	Float Function Get()
		Float AppliedValue = GetValue(WSWF_AV_maxHappinessNoShelter)
		
		if(bUseGlobalmaxHappinessNoShelter)
			return AppliedValue + WSWF_Setting_maxHappinessNoShelter.GetValue()
		else
			return AppliedValue + WSWF_maxHappinessNoShelter
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSWF_maxHappinessNoShelter = aValue
	EndFunction
EndProperty

Bool Property bUseGlobalhappinessBonusFood = true Auto Hidden
Float WSWF_happinessBonusFood = 20.0
float Property happinessBonusFood
	Float Function Get()
		Float AppliedValue = GetValue(WSWF_AV_happinessBonusFood)
		
		if(bUseGlobalhappinessBonusFood)
			return AppliedValue + WSWF_Setting_happinessBonusFood.GetValue()
		else
			return AppliedValue + WSWF_happinessBonusFood
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSWF_happinessBonusFood = aValue
	EndFunction
EndProperty

Bool Property bUseGlobalhappinessBonusWater = true Auto Hidden
Float WSWF_happinessBonusWater = 20.0
float Property happinessBonusWater
	Float Function Get()
		Float AppliedValue = GetValue(WSWF_AV_happinessBonusWater)
		
		if(bUseGlobalhappinessBonusWater)
			return AppliedValue + WSWF_Setting_happinessBonusWater.GetValue()
		else
			return AppliedValue + WSWF_happinessBonusWater
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSWF_happinessBonusWater = aValue
	EndFunction
EndProperty

Bool Property bUseGlobalhappinessBonusBed = true Auto Hidden
Float WSWF_happinessBonusBed = 10.0
float Property happinessBonusBed
	Float Function Get()
		Float AppliedValue = GetValue(WSWF_AV_happinessBonusBed)
		
		if(bUseGlobalhappinessBonusBed)
			return AppliedValue + WSWF_Setting_happinessBonusBed.GetValue()
		else
			return AppliedValue + WSWF_happinessBonusBed
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSWF_happinessBonusBed = aValue
	EndFunction
EndProperty

Bool Property bUseGlobalhappinessBonusShelter = true Auto Hidden
Float WSWF_happinessBonusShelter = 10.0
float Property happinessBonusShelter
	Float Function Get()
		Float AppliedValue = GetValue(WSWF_AV_happinessBonusShelter)
		
		if(bUseGlobalhappinessBonusShelter)
			return AppliedValue + WSWF_Setting_happinessBonusShelter.GetValue()
		else
			return AppliedValue + WSWF_happinessBonusShelter
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSWF_happinessBonusShelter = aValue
	EndFunction
EndProperty

Bool Property bUseGlobalhappinessBonusSafety = true Auto Hidden
Float WSWF_happinessBonusSafety = 20.0
float Property happinessBonusSafety
	Float Function Get()
		Float AppliedValue = GetValue(WSWF_AV_happinessBonusSafety)
		
		if(bUseGlobalhappinessBonusSafety)
			return AppliedValue + WSWF_Setting_happinessBonusSafety.GetValue()
		else
			return AppliedValue + WSWF_happinessBonusSafety
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSWF_happinessBonusSafety = aValue
	EndFunction
EndProperty

Bool Property bUseGlobalminHappinessChangePerUpdate = true Auto Hidden
Int WSWF_minHappinessChangePerUpdate = 1 ; what's the min happiness can change in one update?
Int Property minHappinessChangePerUpdate
	Int Function Get()
		Int AppliedValue = Math.Ceiling(GetValue(WSWF_AV_minHappinessChangePerUpdate))
		
		if(bUseGlobalminHappinessChangePerUpdate)
			return AppliedValue + WSWF_Setting_minHappinessChangePerUpdate.GetValueInt()
		else
			return AppliedValue + WSWF_minHappinessChangePerUpdate
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSWF_minHappinessChangePerUpdate = aValue
	EndFunction
EndProperty

Bool Property bUseGlobalhappinessChangeMult = true Auto Hidden
Float WSWF_happinessChangeMult = 0.20 ; multiplier on happiness delta
float Property happinessChangeMult
	Float Function Get()
		Float AppliedValue = GetValue(WSWF_AV_happinessChangeMult)
		
		if(bUseGlobalhappinessChangeMult)
			return AppliedValue + WSWF_Setting_happinessChangeMult.GetValue()
		else
			return AppliedValue + WSWF_happinessChangeMult
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSWF_happinessChangeMult = aValue
	EndFunction
EndProperty		
		
Bool Property bUseGlobalminHappinessThreshold = true Auto Hidden
Int WSWF_minHappinessThreshold = 10 ; if happiness drops <= to this value, player ownership is cleared
Int Property minHappinessThreshold
	Int Function Get()
		Int AppliedValue = Math.Ceiling(GetValue(WSWF_AV_minHappinessThreshold))
		
		if(bUseGlobalminHappinessThreshold)
			return AppliedValue + WSWF_Setting_minHappinessThreshold.GetValueInt()
		else
			return AppliedValue + WSWF_minHappinessThreshold
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSWF_minHappinessThreshold = aValue
	EndFunction
EndProperty

Bool Property bUseGlobalminHappinessWarningThreshold = true Auto Hidden
Int WSWF_minHappinessWarningThreshold = 15 ; if happiness drops <= to this value, player ownership is cleared
Int Property minHappinessWarningThreshold
	Int Function Get()
		Int AppliedValue = Math.Ceiling(GetValue(WSWF_AV_minHappinessWarningThreshold))
		
		if(bUseGlobalminHappinessWarningThreshold)
			return AppliedValue + WSWF_Setting_minHappinessWarningThreshold.GetValueInt()
		else
			return AppliedValue + WSWF_minHappinessWarningThreshold
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSWF_minHappinessWarningThreshold = aValue
	EndFunction
EndProperty
				
Bool Property bUseGlobalminHappinessClearWarningThreshold = true Auto Hidden
Int WSWF_minHappinessClearWarningThreshold = 20 ; if happiness >= this value, clear happiness warning
Int Property minHappinessClearWarningThreshold
	Int Function Get()
		Int AppliedValue = Math.Ceiling(GetValue(WSWF_AV_minHappinessClearWarningThreshold))
		
		if(bUseGlobalminHappinessClearWarningThreshold)
			return AppliedValue + WSWF_Setting_minHappinessClearWarningThreshold.GetValueInt()
		else
			return AppliedValue + WSWF_minHappinessClearWarningThreshold
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSWF_minHappinessClearWarningThreshold = aValue
	EndFunction
EndProperty	

Bool Property bUseGlobalhappinessBonusChangePerUpdate = true Auto Hidden
Int WSWF_happinessBonusChangePerUpdate = 2 ; happiness bonus trends back to 0 (from positive or negative)
Int Property happinessBonusChangePerUpdate
	Int Function Get()
		Int AppliedValue = Math.Ceiling(GetValue(WSWF_AV_happinessBonusChangePerUpdate))
		
		if(bUseGlobalhappinessBonusChangePerUpdate)
			return AppliedValue + WSWF_Setting_happinessBonusChangePerUpdate.GetValueInt()
		else
			return AppliedValue + WSWF_happinessBonusChangePerUpdate
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSWF_happinessBonusChangePerUpdate = aValue
	EndFunction
EndProperty
	

; production
Bool Property bUseGlobalmaxStoredFoodBase = true Auto Hidden
Int WSWF_maxStoredFoodBase = 10 ; stop producing when we reach this amount stored
Int Property maxStoredFoodBase
	Int Function Get()
		Int AppliedValue = Math.Ceiling(GetValue(WSWF_AV_maxStoredFoodBase))
		
		if(bUseGlobalmaxStoredFoodBase)
			return AppliedValue + WSWF_Setting_maxStoredFoodBase.GetValueInt()
		else
			return AppliedValue + WSWF_maxStoredFoodBase
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSWF_maxStoredFoodBase = aValue
	EndFunction
EndProperty
				
Bool Property bUseGlobalmaxStoredFoodPerPopulation = true Auto Hidden
Int WSWF_maxStoredFoodPerPopulation = 1 ; increase max for each population
Int Property maxStoredFoodPerPopulation
	Int Function Get()
		Int AppliedValue = Math.Ceiling(GetValue(WSWF_AV_maxStoredFoodPerPopulation))
		
		if(bUseGlobalmaxStoredFoodPerPopulation)
			return AppliedValue + WSWF_Setting_maxStoredFoodPerPopulation.GetValueInt()
		else
			return AppliedValue + WSWF_maxStoredFoodPerPopulation
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSWF_maxStoredFoodPerPopulation = aValue
	EndFunction
EndProperty

Bool Property bUseGlobalmaxStoredWaterBase = true Auto Hidden
Int WSWF_maxStoredWaterBase = 5 ; stop producing when we reach this amount stored
Int Property maxStoredWaterBase
	Int Function Get()
		Int AppliedValue = Math.Ceiling(GetValue(WSWF_AV_maxStoredWaterBase))
		
		if(bUseGlobalmaxStoredWaterBase)
			return AppliedValue + WSWF_Setting_maxStoredWaterBase.GetValueInt()
		else
			return AppliedValue + WSWF_maxStoredWaterBase
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSWF_maxStoredWaterBase = aValue
	EndFunction
EndProperty

Bool Property bUseGlobalmaxStoredWaterPerPopulation = true Auto Hidden
Float WSWF_maxStoredWaterPerPopulation = 0.25 ; increase max for each population
float Property maxStoredWaterPerPopulation
	Float Function Get()
		Float AppliedValue = GetValue(WSWF_AV_maxStoredWaterPerPopulation)
		
		if(bUseGlobalmaxStoredWaterPerPopulation)
			return AppliedValue + WSWF_Setting_maxStoredWaterPerPopulation.GetValue()
		else
			return AppliedValue + WSWF_maxStoredWaterPerPopulation
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSWF_maxStoredWaterPerPopulation = aValue
	EndFunction
EndProperty	
				
Bool Property bUseGlobalmaxStoredScavengeBase = true Auto Hidden
Int WSWF_maxStoredScavengeBase = 100 ; stop producing when we reach this amount stored
Int Property maxStoredScavengeBase
	Int Function Get()
		Int AppliedValue = Math.Ceiling(GetValue(WSWF_AV_maxStoredScavengeBase))
		
		if(bUseGlobalmaxStoredScavengeBase)
			return AppliedValue + WSWF_Setting_maxStoredScavengeBase.GetValueInt()
		else
			return AppliedValue + WSWF_maxStoredScavengeBase
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSWF_maxStoredScavengeBase = aValue
	EndFunction
EndProperty

Bool Property bUseGlobalmaxStoredScavengePerPopulation = true Auto Hidden
Int WSWF_maxStoredScavengePerPopulation = 5 ; increase max for each population
Int Property maxStoredScavengePerPopulation
	Int Function Get()
		Int AppliedValue = Math.Ceiling(GetValue(WSWF_AV_maxStoredScavengePerPopulation))
		
		if(bUseGlobalmaxStoredScavengePerPopulation)
			return AppliedValue + WSWF_Setting_maxStoredScavengePerPopulation.GetValueInt()
		else
			return AppliedValue + WSWF_maxStoredScavengePerPopulation
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSWF_maxStoredScavengePerPopulation = aValue
	EndFunction
EndProperty		
	
Bool Property bUseGlobalbrahminProductionBoost = true Auto Hidden
Float WSWF_brahminProductionBoost = 0.5 ; what percent increase per brahmin
float Property brahminProductionBoost
	Float Function Get()
		Float AppliedValue = GetValue(WSWF_AV_brahminProductionBoost)
		
		if(bUseGlobalbrahminProductionBoost)
			return AppliedValue + WSWF_Setting_brahminProductionBoost.GetValue()
		else
			return AppliedValue + WSWF_brahminProductionBoost
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSWF_brahminProductionBoost = aValue
	EndFunction
EndProperty	

Bool Property bUseGlobalmaxProductionPerBrahmin = true Auto Hidden
Int WSWF_maxProductionPerBrahmin = 10 ; each brahmin can only boost this much food (so max 10 * 0.5 = 5)
Int Property maxProductionPerBrahmin
	Int Function Get()
		Int AppliedValue = Math.Ceiling(GetValue(WSWF_AV_maxProductionPerBrahmin))
		
		if(bUseGlobalmaxProductionPerBrahmin)
			return AppliedValue + WSWF_Setting_maxProductionPerBrahmin.GetValueInt()
		else
			return AppliedValue + WSWF_maxProductionPerBrahmin
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSWF_maxProductionPerBrahmin = aValue
	EndFunction
EndProperty		
				
Bool Property bUseGlobalmaxBrahminFertilizerProduction = true Auto Hidden
Int WSWF_maxBrahminFertilizerProduction = 3 ; max fertilizer production per settlement per day
Int Property maxBrahminFertilizerProduction
	Int Function Get()
		Int AppliedValue = Math.Ceiling(GetValue(WSWF_AV_maxBrahminFertilizerProduction))
		
		if(bUseGlobalmaxBrahminFertilizerProduction)
			return AppliedValue + WSWF_Setting_maxBrahminFertilizerProduction.GetValueInt()
		else
			return AppliedValue + WSWF_maxBrahminFertilizerProduction
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSWF_maxBrahminFertilizerProduction = aValue
	EndFunction
EndProperty					

Bool Property bUseGlobalmaxStoredFertilizerBase = true Auto Hidden
Int WSWF_maxStoredFertilizerBase = 10 ; stop producing when we reach this amount stored
Int Property maxStoredFertilizerBase
	Int Function Get()
		Int AppliedValue = Math.Ceiling(GetValue(WSWF_AV_maxStoredFertilizerBase))
		
		if(bUseGlobalmaxStoredFertilizerBase)
			return AppliedValue + WSWF_Setting_maxStoredFertilizerBase.GetValueInt()
		else
			return AppliedValue + WSWF_maxStoredFertilizerBase
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSWF_maxStoredFertilizerBase = aValue
	EndFunction
EndProperty					

; vendor income
Bool Property bUseGlobalminVendorIncomePopulation = true Auto Hidden
Int WSWF_minVendorIncomePopulation = 5 ; need at least this population to get any vendor income
Int Property minVendorIncomePopulation
	Int Function Get()
		Int AppliedValue = Math.Ceiling(GetValue(WSWF_AV_minVendorIncomePopulation))
		
		if(bUseGlobalminVendorIncomePopulation)
			return AppliedValue + WSWF_Setting_minVendorIncomePopulation.GetValueInt()
		else
			return AppliedValue + WSWF_minVendorIncomePopulation
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSWF_minVendorIncomePopulation = aValue
	EndFunction
EndProperty	

Bool Property bUseGlobalmaxVendorIncome = true Auto Hidden
Float WSWF_maxVendorIncome = 50.0 ; max daily vendor income from any settlement
float Property maxVendorIncome
	Float Function Get()
		Float AppliedValue = GetValue(WSWF_AV_maxVendorIncome)
		
		if(bUseGlobalmaxVendorIncome)
			return AppliedValue + WSWF_Setting_maxVendorIncome.GetValue()
		else
			return AppliedValue + WSWF_maxVendorIncome
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSWF_maxVendorIncome = aValue
	EndFunction
EndProperty	
				
Bool Property bUseGlobalvendorIncomePopulationMult = true Auto Hidden
Float WSWF_vendorIncomePopulationMult = 0.03 ; multiplier on population, added to vendor income
float Property vendorIncomePopulationMult
	Float Function Get()
		Float AppliedValue = GetValue(WSWF_AV_vendorIncomePopulationMult)
		
		if(bUseGlobalvendorIncomePopulationMult)
			return AppliedValue + WSWF_Setting_vendorIncomePopulationMult.GetValue()
		else
			return AppliedValue + WSWF_vendorIncomePopulationMult
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSWF_vendorIncomePopulationMult = aValue
	EndFunction
EndProperty						

Bool Property bUseGlobalvendorIncomeBaseMult = true Auto Hidden
Float WSWF_vendorIncomeBaseMult = 2.0 ; multiplier on base vendor income
float Property vendorIncomeBaseMult
	Float Function Get()
		Float AppliedValue = GetValue(WSWF_AV_vendorIncomeBaseMult)
		
		if(bUseGlobalvendorIncomeBaseMult)
			return AppliedValue + WSWF_Setting_vendorIncomeBaseMult.GetValue()
		else
			return AppliedValue + WSWF_vendorIncomeBaseMult
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSWF_vendorIncomeBaseMult = aValue
	EndFunction
EndProperty		
				

; radio/attracting NPC stuff
Bool Property bUseGlobaliMaxSurplusNPCs = true Auto Hidden
Int WSWF_iMaxSurplusNPCs = 5 ; for now, max number of unassigned NPCs - if you have this many or more, no new NPCs will arrive.
Int Property iMaxSurplusNPCs
	Int Function Get()
		Int AppliedValue = Math.Ceiling(GetValue(WSWF_AV_iMaxSurplusNPCs))
		
		if(bUseGlobaliMaxSurplusNPCs)
			return AppliedValue + WSWF_Setting_iMaxSurplusNPCs.GetValueInt()
		else
			return AppliedValue + WSWF_iMaxSurplusNPCs
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSWF_iMaxSurplusNPCs = aValue
	EndFunction
EndProperty	
			
Bool Property bUseGlobalattractNPCDailyChance = true Auto Hidden
Float WSWF_attractNPCDailyChance = 0.1 ; for now, roll <= to this to attract an NPC each day, modified by happiness
float Property attractNPCDailyChance
	Float Function Get()
		Float AppliedValue = GetValue(WSWF_AV_attractNPCDailyChance)
		
		if(bUseGlobalattractNPCDailyChance)
			return AppliedValue + WSWF_Setting_attractNPCDailyChance.GetValue()
		else
			return AppliedValue + WSWF_attractNPCDailyChance
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSWF_attractNPCDailyChance = aValue
	EndFunction
EndProperty			
 	
Bool Property bUseGlobaliMaxBonusAttractChancePopulation = true Auto Hidden
Int WSWF_iMaxBonusAttractChancePopulation = 5 ; for now, there's a bonus attract chance until the total population reaches this value more, no new NPCs will arrive.
Int Property iMaxBonusAttractChancePopulation
	Int Function Get()
		Int AppliedValue = Math.Ceiling(GetValue(WSWF_AV_iMaxBonusAttractChancePopulation))
		
		if(bUseGlobaliMaxBonusAttractChancePopulation)
			return AppliedValue + WSWF_Setting_iMaxBonusAttractChancePopulation.GetValueInt()
		else
			return AppliedValue + WSWF_iMaxBonusAttractChancePopulation
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSWF_iMaxBonusAttractChancePopulation = aValue
	EndFunction
EndProperty		

Bool Property bUseGlobaliBaseMaxNPCs = true Auto Hidden
Int WSWF_iBaseMaxNPCs = 10 ; base total NPCs that can be at a player's town - this is used in GetMaxWorkshopNPCs formula
Int Property iBaseMaxNPCs
	Int Function Get()
		Int AppliedValue = Math.Ceiling(GetValue(WSWF_AV_iBaseMaxNPCs))
		
		if(bUseGlobaliBaseMaxNPCs)
			return AppliedValue + WSWF_Setting_iBaseMaxNPCs.GetValueInt()
		else
			return AppliedValue + WSWF_iBaseMaxNPCs
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSWF_iBaseMaxNPCs = aValue
	EndFunction
EndProperty	

Bool Property bUseGlobalattractNPCHappinessMult = true Auto Hidden
Float WSWF_attractNPCHappinessMult = 0.5 ; multiplier on happiness to attraction chance
float Property attractNPCHappinessMult
	Float Function Get()
		Float AppliedValue = GetValue(WSWF_AV_attractNPCHappinessMult)
		
		if(bUseGlobalattractNPCHappinessMult)
			return AppliedValue + WSWF_Setting_attractNPCHappinessMult.GetValue()
		else
			return AppliedValue + WSWF_attractNPCHappinessMult
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSWF_attractNPCHappinessMult = aValue
	EndFunction
EndProperty			
		

; attack chance formula
Bool Property bUseGlobalattackChanceBase = true Auto Hidden
Float WSWF_attackChanceBase = 0.02
float Property attackChanceBase
	Float Function Get()
		Float AppliedValue = GetValue(WSWF_AV_attackChanceBase)
		
		if(bUseGlobalattackChanceBase)
			return AppliedValue + WSWF_Setting_attackChanceBase.GetValue()
		else
			return AppliedValue + WSWF_attackChanceBase
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSWF_attackChanceBase = aValue
	EndFunction
EndProperty		

Bool Property bUseGlobalattackChanceResourceMult = true Auto Hidden
Float WSWF_attackChanceResourceMult = 0.001
float Property attackChanceResourceMult
	Float Function Get()
		Float AppliedValue = GetValue(WSWF_AV_attackChanceResourceMult)
		
		if(bUseGlobalattackChanceResourceMult)
			return AppliedValue + WSWF_Setting_attackChanceResourceMult.GetValue()
		else
			return AppliedValue + WSWF_attackChanceResourceMult
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSWF_attackChanceResourceMult = aValue
	EndFunction
EndProperty	

Bool Property bUseGlobalattackChanceSafetyMult = true Auto Hidden
Float WSWF_attackChanceSafetyMult = 0.01
float Property attackChanceSafetyMult
	Float Function Get()
		Float AppliedValue = GetValue(WSWF_AV_attackChanceSafetyMult)
		
		if(bUseGlobalattackChanceSafetyMult)
			return AppliedValue + WSWF_Setting_attackChanceSafetyMult.GetValue()
		else
			return AppliedValue + WSWF_attackChanceSafetyMult
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSWF_attackChanceSafetyMult = aValue
	EndFunction
EndProperty	

Bool Property bUseGlobalattackChancePopulationMult = true Auto Hidden
Float WSWF_attackChancePopulationMult = 0.005
float Property attackChancePopulationMult
	Float Function Get()
		Float AppliedValue = GetValue(WSWF_AV_attackChancePopulationMult)
		
		if(bUseGlobalattackChancePopulationMult)
			return AppliedValue + WSWF_Setting_attackChancePopulationMult.GetValue()
		else
			return AppliedValue + WSWF_attackChancePopulationMult
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSWF_attackChancePopulationMult = aValue
	EndFunction
EndProperty	

Bool Property bUseGlobalminDaysSinceLastAttack = true Auto Hidden
Float WSWF_minDaysSinceLastAttack = 7.0 ;	minimum days before another attack can be rolled for
float Property minDaysSinceLastAttack
	Float Function Get()
		Float AppliedValue = GetValue(WSWF_AV_minDaysSinceLastAttack)
		
		if(bUseGlobalminDaysSinceLastAttack)
			return AppliedValue + WSWF_Setting_minDaysSinceLastAttack.GetValue()
		else
			return AppliedValue + WSWF_minDaysSinceLastAttack
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSWF_minDaysSinceLastAttack = aValue
	EndFunction
EndProperty	
		

; damage
Bool Property bUseGlobaldamageDailyRepairBase = true Auto Hidden
Float WSWF_damageDailyRepairBase = 5.0 ; amount of damage repaired per day (overall)
float Property damageDailyRepairBase
	Float Function Get()
		Float AppliedValue = GetValue(WSWF_AV_damageDailyRepairBase)
		
		if(bUseGlobaldamageDailyRepairBase)
			return AppliedValue + WSWF_Setting_damageDailyRepairBase.GetValue()
		else
			return AppliedValue + WSWF_damageDailyRepairBase
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSWF_damageDailyRepairBase = aValue
	EndFunction
EndProperty	

Bool Property bUseGlobaldamageDailyPopulationMult = true Auto Hidden
Float WSWF_damageDailyPopulationMult = 0.20 ;	multiplier on population for repair:  repair = population * damageDailyPopulationMult * damageDailyPopulationMult
float Property damageDailyPopulationMult
	Float Function Get()
		Float AppliedValue = GetValue(WSWF_AV_damageDailyPopulationMult)
		
		if(bUseGlobaldamageDailyPopulationMult)
			return AppliedValue + WSWF_Setting_damageDailyPopulationMult.GetValue()
		else
			return AppliedValue + WSWF_damageDailyPopulationMult
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSWF_damageDailyPopulationMult = aValue
	EndFunction
EndProperty	
			
			
			
; WSWF - Entirely new modifiers with global and local controls
Bool Property bUseGlobaliBaseMaxBrahmin = true Auto Hidden
Int WSWF_iBaseMaxBrahmin = 1
Int Property iBaseMaxBrahmin
	Int Function Get()
		Float AppliedValue = GetValue(WSWF_AV_MaxBrahmin)
		
		if(bUseGlobaliBaseMaxBrahmin)
			return (AppliedValue + WSWF_Setting_iBaseMaxBrahmin.GetValue()) as Int
		else
			return (AppliedValue + WSWF_iBaseMaxBrahmin) as Int
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSWF_iBaseMaxBrahmin = aValue
	EndFunction
EndProperty


Bool Property bUseGlobaliBaseMaxSynths = true Auto Hidden
Int WSWF_iBaseMaxSynths = 1
Int Property iBaseMaxSynths
	Int Function Get()
		Float AppliedValue = GetValue(WSWF_AV_MaxSynths)
		
		if(bUseGlobaliBaseMaxSynths)
			return (AppliedValue + WSWF_Setting_iBaseMaxSynths.GetValue()) as Int
		else
			return (AppliedValue + WSWF_iBaseMaxSynths) as Int
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSWF_iBaseMaxSynths = aValue
	EndFunction
EndProperty


Bool Property bUseGlobalrecruitmentGuardChance = true Auto Hidden
Int WSWF_recruitmentGuardChance = 20 ; % chance of getting a "guard" NPC
Int Property recruitmentGuardChance
	Int Function Get()
		Float AppliedValue = GetValue(WSWF_AV_recruitmentGuardChance)
		
		if(bUseGlobalrecruitmentGuardChance)
			return (AppliedValue + WSWF_Setting_recruitmentGuardChance.GetValue()) as Int
		else
			return (AppliedValue + WSWF_recruitmentGuardChance) as Int
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSWF_recruitmentGuardChance = aValue
	EndFunction
EndProperty


Bool Property bUseGlobalrecruitmentBrahminChance = true Auto Hidden
Int WSWF_recruitmentBrahminChance = 20 ; % chance of getting a brahmin with a "farmer" settler
Int Property recruitmentBrahminChance
	Int Function Get()
		Float AppliedValue = GetValue(WSWF_AV_recruitmentBrahminChance)
		
		if(bUseGlobalrecruitmentBrahminChance)
			return (AppliedValue + WSWF_Setting_recruitmentBrahminChance.GetValue()) as Int
		else
			return (AppliedValue + WSWF_recruitmentBrahminChance) as Int
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSWF_recruitmentBrahminChance = aValue
	EndFunction
EndProperty


Bool Property bUseGlobalrecruitmentSynthChance = true Auto Hidden
Int WSWF_recruitmentSynthChance = 10 ; % chance of a settler being a Synth
Int Property recruitmentSynthChance
	Int Function Get()
		Float AppliedValue = GetValue(WSWF_AV_recruitmentSynthChance)
		
		if(bUseGlobalrecruitmentSynthChance)
			return (AppliedValue + WSWF_Setting_recruitmentSynthChance.GetValue()) as Int
		else
			return (AppliedValue + WSWF_recruitmentSynthChance) as Int
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSWF_recruitmentSynthChance = aValue
	EndFunction
EndProperty


Bool Property bUseGlobalactorDeathHappinessModifier = true Auto Hidden
Float WSWF_actorDeathHappinessModifier = -20.0 ; happiness modifier when an actor dies
Float Property actorDeathHappinessModifier
	Float Function Get()
		Float AppliedValue = GetValue(WSWF_AV_actorDeathHappinessModifier)
		
		if(bUseGlobalactorDeathHappinessModifier)
			return AppliedValue + WSWF_Setting_actorDeathHappinessModifier.GetValue()
		else
			return AppliedValue + WSWF_actorDeathHappinessModifier
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSWF_actorDeathHappinessModifier = aValue
	EndFunction
EndProperty


Bool Property bUseGlobalmaxAttackStrength = true Auto Hidden
Int WSWF_maxAttackStrength = 100
Int Property maxAttackStrength
	Int Function Get()
		Float AppliedValue = GetValue(WSWF_AV_maxAttackStrength)
		
		if(bUseGlobalmaxAttackStrength)
			return (AppliedValue + WSWF_Setting_maxAttackStrength.GetValue()) as Int
		else
			return (AppliedValue + WSWF_maxAttackStrength) as Int
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSWF_maxAttackStrength = aValue
	EndFunction
EndProperty


Bool Property bUseGlobalmaxDefenseStrength = true Auto Hidden
Int WSWF_maxDefenseStrength = 100
Int Property maxDefenseStrength
	Int Function Get()
		Float AppliedValue = GetValue(WSWF_AV_maxDefenseStrength)
		
		if(bUseGlobalmaxDefenseStrength)
			return (AppliedValue + WSWF_Setting_maxDefenseStrength.GetValue()) as Int
		else
			return (AppliedValue + WSWF_maxDefenseStrength) as Int
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSWF_maxDefenseStrength = aValue
	EndFunction
EndProperty

int VendorTopLevel = 2 ; WSWF - Copied from WorkshopParent


; timer IDs
int buildWorkObjectTimerID = 0 const
int dailyUpdateTimerID = 1 const

; randomized wait for next try at DailyUpdate if system is busy
float maxDailyUpdateWaitHours = 1.0
float minDailyUpdateWaitHours = 0.2

;-----------------------------------------------------------
;	Added by UFO4P 1.0.3 for Bug #20576:
;-----------------------------------------------------------

;The game time when a daily update was last started upon exiting the OnWorkshopMode event
Float UFO4P_TimeOfLastWorkshopExitUpdateStarted = 0.0

;-----------------------------------------------------------
;	Added by UFO4P 1.0.3 for Bug #20775:
;-----------------------------------------------------------

;TimerIDs to handle calls of the DailyUpdate function with bRealUpdate = false
int UFO4P_DailyUpdateTimerID = 98
int UFO4P_DailyUpdateResetHappinessTimerID = 99

;-----------------------------------------------------------
;	Added by UFO4P 1.0.5. for Bug #21039:
;-----------------------------------------------------------

;This tells WorkshopParentScript to run damage helper cleanups on all crops at this workshop during the next workshop reset. Once this has been done,
;the bool is set to 'false'.
bool property UFO4P_CleanupDamageHelpers_WorkObjects = true auto hidden

;-----------------------------------------------------------
;	Added by UFO4P 2.0 for Bug #21895:
;-----------------------------------------------------------

;This will be set to 'true' when the attack message pops up on the screen and reset to 'false' when the attack quest shuts down:
bool property UFO4P_CurrentlyUnderAttack = false auto hidden

;-----------------------------------------------------------
;	Added by UFO4P 2.0.1 for Bug #22234:
;-----------------------------------------------------------

bool bResetHappiness = false

;-----------------------------------------------------------
;	Added by UFO4P 2.0.2 for Bug #21408:
;-----------------------------------------------------------

bool UFO4P_CheckFactionOwnershipClearedOnBeds = true
;A tracking bool needed to apply the fix for bug #21408 retroactively.

;-----------------------------------------------------------
;	Added by UFO4P 2.0.4 for Bug #24122:
;-----------------------------------------------------------

bool Property UFO4P_InWorkshopMode = false auto hidden
;Tells whether the player is currently in workshop mode at this workshop.


; utility function to return vendor container array
; create containers as necessary
ObjectReference[] function GetVendorContainersByType(int vendorType)
	if vendorType == 0
		if VendorContainersMisc == NONE
			VendorContainersMisc = InitializeVendorChests(vendorType)
		endif
		return VendorContainersMisc
	elseif vendorType == 1
		if VendorContainersArmor == NONE
			VendorContainersArmor = InitializeVendorChests(vendorType)
		endif
		return VendorContainersArmor
	elseif vendorType == 2
		if VendorContainersWeapons == NONE
			VendorContainersWeapons = InitializeVendorChests(vendorType)
		endif
		return VendorContainersWeapons
	elseif vendorType == 3
		if VendorContainersBar == NONE
			VendorContainersBar = InitializeVendorChests(vendorType)
		endif
		return VendorContainersBar
	elseif vendorType == 4
		if VendorContainersClinic == NONE
			VendorContainersClinic = InitializeVendorChests(vendorType)
		endif
		return VendorContainersClinic
	elseif vendorType == 5
		if VendorContainersClothing == NONE
			VendorContainersClothing = InitializeVendorChests(vendorType)
		endif
		return VendorContainersClothing
	endif
endFunction

ObjectReference[] function InitializeVendorChests(int vendorType)
	; initialize array
	int containerArraySize = VendorTopLevel + 1
	ObjectReference[] vendorContainers = new ObjectReference[containerArraySize]

	; create the chests
	FormList vendorContainerList = WorkshopParent.WorkshopVendorContainers[vendorType]
	int vendorLevel = 0
	while vendorLevel <= VendorTopLevel
		; create ref for each vendor level
		vendorContainers[vendorLevel] = WorkshopParent.WorkshopHoldingCellMarker.PlaceAtMe(vendorContainerList.GetAt(vendorLevel))
		vendorLevel += 1
	endWhile

	return vendorContainers
endFunction

Event OnInit()
    ; initialize building budget actor values if necessary
	if MaxTriangles > 0
		SetValue(WorkshopParent.WorkshopMaxTriangles, MaxTriangles)
	endif
	if MaxDraws > 0
		SetValue(WorkshopParent.WorkshopMaxDraws, MaxDraws)
	endif
	if CurrentTriangles > 0
		SetValue(WorkshopParent.WorkshopCurrentTriangles, CurrentTriangles)
	endif
	if CurrentDraws > 0
		SetValue(WorkshopParent.WorkshopCurrentDraws, CurrentDraws)
	endif

	;UFO4P 2.0.2 Bug #21408: Added this line:
	;If the modified script is isntalled at game start (since workshop locations never reset, this event only runs on the player's first visit to this
	;workshop), set this bool to false since the function it checks for will run automatically once the workshop gets player owned.
	UFO4P_CheckFactionOwnershipClearedOnBeds = false

	; happiness target (don't want to set a default value)
	SetValue(HappinessTarget, WorkshopParent.startingHappinessTarget)
EndEvent

Event OnLoad()
	; for now, block activation if not "owned" by player
	BlockActivation(!OwnedByPlayer)
	; grab inventory from linked container if I'm a container myself
	if (GetBaseObject() as Container)
		; get linked container
		ObjectReference linkedContainer = GetLinkedRef(WorkshopLinkContainer)
		if linkedContainer
			linkedContainer.RemoveAllItems(self)
		endif

		; get all linked containers (children)
		ObjectReference[] linkedContainers = GetLinkedRefChildren(WorkshopLinkContainer)
		int i = 0
		while i < linkedContainers.Length
			linkedContainer = linkedContainers[i]
			if linkedContainer
				linkedContainer.RemoveAllItems(self)
			endif
			i += 1
		endWhile
	endif

	; if no location (this is not a settlement location so skipped WorkshopParent init process), get current location
	if !myLocation
		myLocation = GetCurrentLocation()
	endif

	;UFO4P 2.0.2 Bug #21408: Added these lines to make the fix for bug #21408 work retroactively:
	;If workshop is player owned and faction ownerships on beds has not yet been cleared, do it now:
	if UFO4P_CheckFactionOwnershipClearedOnBeds && OwnedByPlayer
		UFO4P_ClearFactionOwnershipOnBeds()
	endif

EndEvent

Event OnUnload()
	; reset days since last visit whenever you leave
	DaysSinceLastVisit = 0

	;UFO4P 2.0.2 Bug #23016: Added the following line:
	;If the workbench unloads, check whether this workshop was the last workshop visited by the player, and if so, reset currentWorkshopID
	;(and related properties) on WorkshopParentScript:
	WorkshopParent.UFO4P_ResetCurrentWorkshop (workshopID)
endEvent

; block activation until player "owns" this workbench
Event OnActivate(ObjectReference akActionRef)
	;;debug.trace(self + "OnActivate")
	if akActionRef == Game.GetPlayer()
		CheckOwnership()

		if OwnedByPlayer
			; go into workshop mode
			StartWorkshop()
		endif
	endif
EndEvent

; called by OnActivate and workbench scripts to check if player ownership should change
function CheckOwnership()
		; if location is cleared, automatically count this as owned by player
		if myLocation.IsCleared() && !OwnedByPlayer && EnableAutomaticPlayerOwnership && !WorkshopParent.PermanentActorsAliveAndPresent(self)
			SetOwnedByPlayer(true)
			; go into workshop mode
;			StartWorkshop()
		endif

		if !OwnedByPlayer
			; which message to show?
			; Patch 1.4: handle custom unowned message
			if CustomUnownedMessage
				CustomUnownedMessage.Show()
			else
				int totalPopulation = GetBaseValue(Population) as int

				if totalPopulation > 0
					WorkshopParent.WorkshopUnownedSettlementMessage.Show()
				elseif myLocation.IsCleared() == false && EnableAutomaticPlayerOwnership
					WorkshopParent.WorkshopUnownedHostileMessage.Show()
				else
					WorkshopParent.WorkshopUnownedMessage.Show()
				endif
			endif
		endif
endFunction

Event OnWorkshopMode(bool aStart)

	;UFO4P 2.0.4 Bug #24122: added this line:
	UFO4P_InWorkshopMode = aStart

	;debug.trace(self + " OnWorkshopMode " + aStart)
	if aStart
		if OwnedByPlayer
			; make this the current workshop
			WorkshopParent.SetCurrentWorkshop(self)
		endif
		
		; WSWF Event Edit - Adding aStart to the end of event arguments 
		;Var[] kargs = new Var[2]
		;kargs[0] = NONE
		;kargs[1] = self
		Var[] kargs = new Var[0]
		kargs.Add(NONE)
		kargs.Add(Self)
		kargs.Add(aStart)
					
		WorkshopParent.SendCustomEvent("WorkshopEnterMenu", kargs)		
	endif

	; Dogmeat scene
	if aStart && WorkshopParent.DogmeatAlias.GetRef()
		WorkshopParent.WorkshopDogmeatWhileBuildingScene.Start()
	else
		WorkshopParent.WorkshopDogmeatWhileBuildingScene.Stop()
	endif

	; Companion scene
	;debug.trace(self + " OnWorkshopMode " + WorkshopParent.CompanionAlias.GetRef())
	if aStart && WorkshopParent.CompanionAlias.GetRef()
		;debug.trace(self + " starting WorkshopParent.WorkshopCompanionWhileBuildingScene")
		WorkshopParent.WorkshopCompanionWhileBuildingScene.Start()
	else
		WorkshopParent.WorkshopCompanionWhileBuildingScene.Stop()
	endif

	if !aStart
		; show message if haven't before
		if ShowedWorkshopMenuExitMessage == false
			ShowedWorkshopMenuExitMessage = true
			WorkshopParent.WorkshopExitMenuMessage.ShowAsHelpMessage("WorkshopMenuExit", 10.0, 0, 1, "NoMenu")
		endif
		; make sure resources stay assigned
		;UFO4P 2.0.4 Bug #24312: removed the following line:
		;AssignObjectToWorkshop (on WorkshopParentScript) now runs the assignment procedures directly on all new resource objects.
		;WorkshopParent.TryToAssignResourceObjectsPUBLIC(self)
	endif

	;try recalcing when you enter/exit workshop mode
	;UFO4P 1.0.3 Bug #20576: According to the notes on the DailyUpdate function, the update on exiting workshop mode was never considered important and would
	;be skipped entirely when the system was busy. With the vanilla version of WorkshopParentScript where several resets could run on a workshop in a sequence,
	;this function call rarely found a time window of low script activity and was skipped most of the time. With the reset issue fixed however, this function
	;call succeeded most of the time. Depending on the player's activities while at a workshop (i.e. depending on how often he entered and left workshop mode),
	;it could easily run ten times or more in a row. Considering that this was never considered a priority task though, this is a waste of performance. There-
	;fore, the number of calls has been limited to four per game day.

	If (Utility.GetCurrentGameTime() - UFO4P_TimeOfLastWorkshopExitUpdateStarted > 0.25)
		UFO4P_TimeOfLastWorkshopExitUpdateStarted = Utility.GetCurrentGameTime()
		;UFO4P 1.0.3 Bug #20775: Start timer to handle the update call (Note: this was done for consistency, as calls of the DailyUpdate function from
		;WorkshopParentScript must be handled via timer event to resolve the bug)
		StartTimer(3.0, UFO4P_DailyUpdateTimerID)
		;DailyUpdate(bRealUpdate = false)
	EndIf

endEvent

Event OnTimer(int aiTimerID)
	if aiTimerID == buildWorkObjectTimerID
		WorkshopParent.TryToAssignResourceObjectsPUBLIC(self)
	;UFO4P 1.0.3 Bug #20775: Added two branches to handle calls of the DailyUpdate function with bRealUpdate = false: the first one is for all calls from this
	;script, the second one is for calls from WorkshopParentScript
	elseIf aiTimerID == UFO4P_DailyUpdateTimerID
		DailyUpdate(bRealUpdate = false)
	elseIf aiTimerID == UFO4P_DailyUpdateResetHappinessTimerID
		;UFO4P 2.0.1 Bug #22234: set bResetHappiness to 'true' to tell the DailyUpdate function to call ResetHappinessPUBLIC before it stops running:
		bResetHappiness = true
		DailyUpdate(bRealUpdate = false)
	endif
EndEvent

Event OnTimerGameTime(int aiTimerID)
	if aiTimerID == dailyUpdateTimerID
		;UFO4P 2.0. Bug #21895: Added check for the UFO4P_AttackRunning bool on WorkshopParentScript. This will delay any resets while an attack is physically
		;running (workshop script activity will be particularly high in that case, so this will draw some work load from the engine):
		if WorkshopParent.IsEditLocked() || WorkshopParent.DailyUpdateInProgress || WorkshopParent.UFO4P_AttackRunning
			float waitTime = utility.RandomFloat(minDailyUpdateWaitHours, maxDailyUpdateWaitHours)
			; run another timer - system is too busy
			StartTimerGameTime(waitTime, dailyUpdateTimerID)
		else
			DailyUpdate()
		endif	
	endif
endEvent

function SetOwnedByPlayer(bool bIsOwned)
	; is state changing?
	if !bIsOwned && OwnedByPlayer
		OwnedByPlayer = bIsOwned ; do this here so workshop is updated for UpdatePlayerOwnership check

		; display loss of ownership message
		WorkshopParent.DisplayMessage(WorkshopParent.WorkshopLosePlayerOwnership, NONE, myLocation)
		; flag as "lost control"
		SetValue(WorkshopPlayerLostControl, 1.0)
		; clear farm discount faction if we can get actors
		ObjectReference[] WorkshopActors = WorkshopParent.GetWorkshopActors(self)
		int i = 0
		while i < WorkshopActors.Length
			WorkshopNPCScript theActor = (WorkshopActors[i] as Actor) as WorkshopNPCScript
			if theActor
				theActor.RemoveFromFaction(FarmDiscountFaction)
				; clear "player owned" actor value (used to condition trade items greetings)
				theActor.UpdatePlayerOwnership(self)
			endif
			i += 1
		endWhile

		; remove all caravans to/from this settlement
		WorkshopParent.ClearCaravansFromWorkshopPUBLIC(self)

	elseif bIsOwned && !OwnedByPlayer
		OwnedByPlayer = bIsOwned ; do this here so workshop is updated for UpdatePlayerOwnership check

		; make sure owns a workshop flag is set first time you own one
		if !WorkshopParent.PlayerOwnsAWorkshop
			WorkshopParent.PlayerOwnsAWorkshop = true
		endif

		; make sure happiness (and happiness target) is set to minimum (so doesn't immediately become unowned again)
		float currentHappiness = GetValue(Happiness)
		float currentHappinessTarget = GetValue(HappinessTarget)
		if currentHappiness < minHappinessClearWarningThreshold || currentHappinessTarget < minHappinessClearWarningThreshold
			ModifyActorValue(self, Happiness, minHappinessClearWarningThreshold)		
			ModifyActorValue(self, HappinessTarget, minHappinessClearWarningThreshold)		
		EndIf
		
		; display gain of ownership message
		WorkshopParent.DisplayMessage(WorkshopParent.WorkshopGainPlayerOwnership, NONE, myLocation)

		; if this is the first time player owns this, increment stat
		if GetValue(WorkshopParent.WorkshopPlayerLostControl) == 0
			;debug.trace("Increment Workshops Unlocked stat")
			Game.IncrementStat("Workshops Unlocked")
			;UFO4P 2.0.2 Bug #21408: Also run this function to clear faction ownership on all preplaced beds:
			UFO4P_ClearFactionOwnershipOnBeds()
		else
			; clear "lost control" flag
			SetValue(WorkshopParent.WorkshopPlayerLostControl, 0.0)
		EndIf

		; if allowed, allow random quests from now on
		if MinRecruitmentAllowRandomAfterPlayerOwned
			MinRecruitmentProhibitRandom = false
		EndIf

		; allow attacks when unowned now
		AllowAttacksBeforeOwned = true

		; add player owned actor value if possible
		ObjectReference[] WorkshopActors = WorkshopParent.GetWorkshopActors(self)
		int i = 0
		while i < WorkshopActors.Length
			WorkshopNPCScript theActor = (WorkshopActors[i] as Actor) as WorkshopNPCScript
			if theActor
				theActor.UpdatePlayerOwnership(self)
			endif
			i += 1
		endWhile

	endif

	OwnedByPlayer = bIsOwned
	BlockActivation(!OwnedByPlayer)
	; set player ownership value on myself
	SetValue(WorkshopPlayerOwnership, (bIsOwned as float))
	
	
	if bIsOwned
		SetActorOwner(Game.GetPlayer().GetActorBase())
		; don't want this flagged as cleared so story manager doesn't skip it
		myLocation.SetCleared(false)
		; add player to ownership faction is there is one
		if SettlementOwnershipFaction && UseOwnershipFaction
			Game.GetPlayer().AddToFaction(SettlementOwnershipFaction)
		endif
	else
		SetActorOwner(NONE)
		; remove player from ownership faction is there is one
		if SettlementOwnershipFaction && UseOwnershipFaction
			Game.GetPlayer().RemoveFromFaction(SettlementOwnershipFaction)
		endif
	endif

	; send custom event for this workshop
	WorkshopParent.SendPlayerOwnershipChangedEvent(self)
endFunction

Event OnWorkshopObjectPlaced(ObjectReference akReference)
	if WorkshopParent.BuildObjectPUBLIC(akReference, self)
		; run timer for assigning resource objects
		;UFO4P 2.0.4 Bug #24312: removed this line:
		;AssignObjectToWorkshop (called from BuildObjectPUBLIC on WorkshopParentScript) now runs the assignment procedures directly on
		;all new resource objects. Calling the functions from a timer started if any new object is built has always been a waste of time
		;because they do not need to run on anything else than assignable resource objects.
		;StartTimer(3.0, buildWorkObjectTimerID)
	endif

endEvent

Event OnWorkshopObjectMoved(ObjectReference akReference)
	; for now, just tell the object it moved so it can update markers etc.
	WorkshopObjectScript workshopObjectRef = akReference as WorkShopObjectScript

	if workshopObjectRef
;		workshopObjectRef.UpdatePosition()
		; send custom event for this object
		Var[] kargs = new Var[2]
		kargs[0] = workshopObjectRef
		kargs[1] = self
		WorkshopParent.SendCustomEvent("WorkshopObjectMoved", kargs)		
	endif
EndEvent

Event OnWorkshopObjectDestroyed(ObjectReference akReference)
	WorkshopParent.RemoveObjectPUBLIC(akReference, self)
endEvent

Event OnWorkshopObjectRepaired(ObjectReference akReference)
	WorkshopObjectActorScript workshopObjectActor = akReference as WorkshopObjectActorScript
	if workshopObjectActor
		; send destruction state changed event manually since actors aren't destructible objects
		WorkshopObjectScript workshopObject = (akReference as WorkshopObjectScript)
		workshopObject.OnDestructionStageChanged(1, 0)
	endif

	WorkshopObjectScript workshopObjectRef = akReference as WorkShopObjectScript

	if workshopObjectRef
;		workshopObjectRef.UpdatePosition()
		; send custom event for this object
		Var[] kargs = new Var[2]
		kargs[0] = workshopObjectRef
		kargs[1] = self
		
		WorkshopParent.SendCustomEvent("WorkshopObjectRepaired", kargs)		
	endif

endEvent

ObjectReference function GetContainer()
	if (GetBaseObject() as Container)
		return self
	else
		return GetLinkedRef(WorkshopLinkContainer)
	endif
endFunction

Event WorkshopParentScript.WorkshopDailyUpdate(WorkshopParentScript akSender, Var[] akArgs)
	; calculate custom time interval for this workshop (to stagger out the update process throughout the day)
	float waitTime = WorkshopParent.dailyUpdateIncrement * workshopID
	
	StartTimerGameTime(waitTime, dailyUpdateTimerID)
EndEvent

; return max NPCs for this workshop
int function GetMaxWorkshopNPCs()
	; base + player's charisma
	int iMaxNPCs = iBaseMaxNPCs
	
	if(WSWF_Setting_AdjustMaxNPCsByCharisma.GetValue() == 1)
		iMaxNPCs += (Game.GetPlayer().GetValue(Game.GetCharismaAV()) as int)
	endif
	
	return iMaxNPCs
endFunction

; Data struct for passing data to/from DailyUpdate helper functions
struct DailyUpdateData
	int totalPopulation
	int robotPopulation
	int brahminPopulation
	int unassignedPopulation
	float vendorIncome
	float currentHappiness
	float damageMult
	float productivity
	int availableBeds
	int shelteredBeds
	int bonusHappiness
	int happinessModifier
	int safety
	int safetyDamage
	int foodProduction
	int waterProduction
	int availableFood
	int availableWater
	int safetyPerNPC
	float totalHappiness
endStruct

; process daily update
; 	bRealUpdate:
;		TRUE = normal daily update - consume/produce resources, etc.
;		FALSE = recalculate happiness etc. but don't produce/consume

bool bDailyUpdateInProgress = false

;UFO4P 1.0.3 Bug #20775: Added a bool argument to handle calls from WorkShopParentScript (in that case, bResetHappiness will be true): those calls will not be
;skipped (even though bRealUpdate is false) and when the function finishes running, it calls the ResetHappinessPUBLIC function on WorkshopParentScript. Also
;modified the traces to display the value of the new bool.
;UFO4P 2.0.1 Bug #22234: Removed the bResetHappiness argument from this function to eliminate API problems.
;bResetHappiness is now a script variable that is set to 'true' when the timer event catches the call from the ResetHappiness function and reset to 'false' by
;the DailyUpdate function when it stops running. This workaround has a minor flaw in that there is no guarantee that the thread started by the timer is also
;the thread that will call WorkshopParentScript (e.g. there may be another thread alread waiting in the lock). Fortunately though, this doesn't matter here
;as long as WorkshopParentScript is called from the right workshop.
function DailyUpdate(bool bRealUpdate = true)
;	;debug.tracestack(self + " DailyUpdate " + bRealUpdate)
	;UFO4P 1.0.2 Bug #20295: GENERAL NOTES:
	;---------------------------------------
	;
	;There are two ways in which this function is called:
	;(1) full updates (bRealUpdate = true): these are priority calls from the OnTimerGameTime event. That event checks WorkshopParent.DailyUpdateInProgress
	;	 for the current lock state and will not let any calls of this function through when another thread is still running it.
	;(2) partial updates (bRealUpdate = false): these are low priority calls that are skipped entirely when another instance is already running.
	;In the vanilla script, the partial updates never checked the true Lock state in WorkshopParent.DailyUpdateInProgress; they only checked bDailyUpdateIn
	;Progress but this turned out to be completely unreliable as a lock bool here. As a result, they could bypass the lock unwantedly and cause interferences
	;(such as messed-up settlement stats in the pip-boy). Therefore, all threads will now check WorkshopParent.DailyUpdateInProgress only. bDailyUpdateInProgress
	;will not be used anymore.

	;UFO4P 1.0.2 Bug #20295: Traces added to check the bools (the trace for bDailyUpdateInProgress was subsequently commented out):
	
	; wait for update lock to be released
	;UFO4P 1.0.2 Bug #20295: Checking WorkshopParent.DailyUpdateInProgress here instead of bDailyUpdateInProgress
	if WorkshopParent.DailyUpdateInProgress
		;UFO4P 1.0.3 Bug #20775: if bResetHappiness = true, the call should not be skipped even when bRealUpdate = false:
		if bRealUpdate || bResetHappiness
			;UFO4P 1.0.2 Bug #20295: Added a loop to wait for the thread to unlock (without that loop, the lock won't work)
			While WorkshopParent.DailyUpdateInProgress
				utility.wait(0.5)
			EndWhile
		else
			; just bail if not a real update - no need
			;UFO4P 2.0: the following trace has been commented out (no need to log this)
			return
		endif
	EndIf
	;bDailyUpdateInProgress = true
	WorkshopParent.DailyUpdateInProgress = true

	;UFO4P 1.0.2 Bug #20295: Moved this block of code up here: There's no need to proceed with the function if we have to bail out anyway.
	ObjectReference containerRef = GetContainer()
	if !containerRef
		;UFO4P 1.0.2 Bug #20295: Added the following line. Otherwise the lock is never actually released.
		;Ironically, this was not a problem when the lock was broken as there was always a chance for it to get eventually released.
		WorkshopParent.DailyUpdateInProgress = false
		;bDailyUpdateInProgress = false
		return
	endif

	; create local pointer to WorkshopRatings array to speed things up
	WorkshopDataScript:WorkshopRatingKeyword[] ratings = WorkshopParent.WorkshopRatings
	DailyUpdateData updateData = new DailyUpdateData

	; NOTE: GetBaseValue for these because we don't care if they can "produce" - actors that are wounded don't "produce" their population resource values
	updateData.totalPopulation = GetBaseValue(Population) as int
	updateData.robotPopulation = GetBaseValue(PopulationRobots) as int
	updateData.brahminPopulation = GetBaseValue(BrahminPopulation) as int
	updateData.unassignedPopulation = GetBaseValue(PopulationUnassigned) as int

	updateData.vendorIncome = GetValue(VendorIncome) * vendorIncomeBaseMult
	updateData.currentHappiness = GetValue(Happiness)

	updateData.damageMult = 1 - GetValue(DamageCurrent)/100.0
	updateData.productivity = GetProductivityMultiplier(ratings)
	updateData.availableBeds = GetBaseValue(Beds) as int
	updateData.shelteredBeds = GetValue(Beds) as int
	updateData.bonusHappiness = GetValue(BonusHappiness) as int
	updateData.happinessModifier = GetValue(HappinessModifier) as int
	updateData.safety = GetValue(Safety) as int
	updateData.safetyDamage = GetValue(DamageSafety) as int
	updateData.totalHappiness = 0.0	; sum of all happiness of each actor in town

	; REAL UPDATE ONLY
	if bRealUpdate
		DailyUpdateAttractNewSettlers(ratings, updateData)
	EndIf

	; if this is current workshop, update actors (in case some have been wounded since last update)
	;UFO4P 2.0.2 Bug #23016: Also check whether the location is still loaded (otherwise, the WorkshopActors array will be empty):
	if GetWorkshopID() == CurrentWorkshopID.GetValue() && WorkshopParent.UFO4P_IsWorkshopLoaded (self)
		ObjectReference[] WorkshopActors = WorkshopParent.GetWorkshopActors(self)
		int i = 0
		while i < WorkshopActors.Length
			WorkshopParent.UpdateActorsWorkObjects(WorkshopActors[i] as WorkShopNPCScript, self)
			i += 1
		endWhile
	endif

	DailyUpdateProduceResources(ratings, updateData, containerRef, bRealUpdate)

	DailyUpdateConsumeResources(ratings, updateData, containerRef, bRealUpdate)


	; REAL UPDATE ONLY:
	if bRealUpdate
		; WSWF - Surplus handled by our WorkshopProductionManager script now 
		; DailyUpdateSurplusResources(ratings, updateData, containerRef)

		RepairDamage()
	
		; now recalc all workshop resources if the current workshop - we don't want to do this when unloaded or everything will be 0
		RecalculateWorkshopResources()

		CheckForAttack()
	endif

	; update trade caravan list
	if updateData.totalPopulation >= WorkshopParent.TradeCaravanMinimumPopulation && GetValue(Caravan) > 0
		WorkshopParent.TradeCaravanWorkshops.AddRef(self)
	else
		WorkshopParent.TradeCaravanWorkshops.RemoveRef(self)
	EndIf

	;UFO4P 1.0.3 Bug #20775: If the timer to call this function was started by WorkshopParentScript (only then, bResetHappiness is true), call the
	;ResetHappinessPUBLIC function on WorkshopParentScript when everything else is done
	if bResetHappiness
		WorkshopParent.ResetHappinessPUBLIC(self)
		;UFO4P 2.0.1 Bug #22234: reset bResetHappiness:
		bResetHappiness = false
	endif

	; clear update lock
	; bDailyUpdateInProgress = false
	WorkshopParent.DailyUpdateInProgress = false

endFunction


; **********************************************************************************************
; DAILY UPDATE HELPER FUNCTIONS - to reduce memory footprint of DailyUpdate process
; **********************************************************************************************
function DailyUpdateAttractNewSettlers(WorkshopDataScript:WorkshopRatingKeyword[] ratings, DailyUpdateData updateData)
	; increment last visit counter each day
	DaysSinceLastVisit += 1

	; WSWF - Handled by our NPCManager quest
	return
	
	; attract new NPCs
	; if I have a radio station
	int radioRating = GetValue(Radio) as int
	if radioRating > 0 && HasKeyword(WorkshopType02) == false && updateData.unassignedPopulation < iMaxSurplusNPCs && updateData.totalPopulation < GetMaxWorkshopNPCs()
		float attractChance = attractNPCDailyChance + updateData.currentHappiness/100 * attractNPCHappinessMult
		if updateData.totalPopulation < iMaxBonusAttractChancePopulation
			attractChance += (iMaxBonusAttractChancePopulation - updateData.totalPopulation) * attractNPCDailyChance
		endif
		; roll to see if a new NPC arrives
		float dieRoll = utility.RandomFloat()
		
		if dieRoll <= attractChance
			;WorkshopNPCScript newWorkshopActor = WorkshopParent.CreateActor(self)
			
			;UFO4P 1.0.5 Bug #21002 (Regression of UFO4P 1.0.3 Bug #20581): Since all edits from UFO4P 1.0.3 to the CreateActor PUBLIC function on WorkshopParent
			;Script had to be removed (see general notes around line 280 for more information), there still remained the problem of this function calling a non-
			;public function on WorkshopParentScript (i.e. bug #20581 still required an appropriate solution). Therefore, the new CreateActor_DailyUpdate function
			;was created on WorkshopParentScript as a safe (public) entry point, to handle calls from this function exclusively:
			WorkshopNPCScript newWorkshopActor = WorkshopParent.CreateActor_DailyUpdate(self)
			updateData.totalPopulation += 1

			if newWorkshopActor.GetValue(WorkshopGuardPreference) == 0
				; see if also generate a brahmin
				; for now just roll if no brahmin here yet
				if GetValue(BrahminPopulation) == 0.0 && AllowBrahminRecruitment
					int brahminRoll = utility.RandomInt()
					
					if brahminRoll <= recruitmentBrahminChance
						;actor newBrahmin = WorkshopParent.CreateActor(self, true)
						
						;UFO4P 1.0.5 Bug #21002 (Regression of UFO4P 1.0.3 Bug #20581): Call CreateActor_DailyUpdate here (see explanations above):
						actor newBrahmin = WorkshopParent.CreateActor_DailyUpdate(self, bBrahmin = true)
						; NOTE: don't increment total population - brahmin aren't counted as population
					endif
				endif
			endif

		endif
	endif
endFunction

; WSWF - Cleared out traces and UFO4P notes to make this quicker to skim through. Also removed all checks that are not necessary any longer given the fact that actual production/consumption is handled by different management scripts
function DailyUpdateProduceResources(WorkshopDataScript:WorkshopRatingKeyword[] ratings, DailyUpdateData updateData, ObjectReference containerRef, bool bRealUpdate)
	; get base food production
	updateData.foodProduction = GetValue(Food) as int
	
	; safety check: WSWF - Adding additional needs AV here
	Float fSafetyNeeded = updateData.totalPopulation + GetValue(WSWF_AV_ExtraNeeds_Safety)
	int iMissingSafety = math.max(0, fSafetyNeeded - updateData.safety) as int
	WorkshopParent.SetResourceData(MissingSafety, self, iMissingSafety)

	; subtract damage from food
	updateData.foodProduction = math.max(0, updateData.foodProduction - (GetValue(DamageFood) as int)) as int
	
	; each brahmin can assist with 10 food production
	if updateData.brahminPopulation > 0
		int brahminMaxFoodBoost = math.min(updateData.brahminPopulation * maxProductionPerBrahmin, updateData.foodProduction) as int
		int brahminFoodProduction = math.Ceiling(brahminMaxFoodBoost * brahminProductionBoost)
		updateData.foodProduction = updateData.foodProduction + brahminFoodProduction
	endif
	
	SetAndRestoreActorValue(self, FoodActual, updateData.foodProduction)
		
	; reduce safety by current damage (food and water already got that treatment in the Production phase)
	updateData.safety = math.Max(updateData.safety -  updateData.safetyDamage, 0) as int
	updateData.safetyPerNPC = 0
	if updateData.totalPopulation > 0
		updateData.safetyperNPC = math.ceiling(updateData.safety/updateData.totalPopulation)
	endif

	updateData.availableFood = containerRef.GetItemCount(ObjectTypeFood)
	updateData.availableWater = containerRef.GetItemCount(ObjectTypeWater)

	; get local food and water totals (including current production)
	updateData.availableFood = containerRef.GetItemCount(ObjectTypeFood) + updateData.foodProduction
	updateData.availableWater = containerRef.GetItemCount(ObjectTypeWater) + updateData.waterProduction

	; how much food & water is needed? (robots don't need either) ; WSWF - Added extra food and water needs
	int neededFood = (Self.GetValue(WSWF_AV_ExtraNeeds_Food) as Int) + updateData.totalPopulation - updateData.robotPopulation - updateData.availableFood 
	int neededWater = (Self.GetValue(WSWF_AV_ExtraNeeds_Water) as Int) + updateData.totalPopulation - updateData.robotPopulation - updateData.availableWater

	; add in food and water from linked workshops if needed
	if neededFood > 0 || neededWater > 0
		WorkshopParent.TransferResourcesFromLinkedWorkshops(self, neededFood, neededWater)
		
		; WSWF - Moved these secondary GetItemCount calls inside the if, as they aren't always needed
		; now, get again (now including any transfers from linked workshops)
		updateData.availableFood = containerRef.GetItemCount(ObjectTypeFood) + updateData.foodProduction
		updateData.availableWater = containerRef.GetItemCount(ObjectTypeWater) + updateData.waterProduction
	endif
endFunction

function DailyUpdateConsumeResources(WorkshopDataScript:WorkshopRatingKeyword[] ratings, DailyUpdateData updateData, ObjectReference containerRef, bool bRealUpdate)
	; don't need to do any of this if no population
	if updateData.totalPopulation == 0
		return
	endif

	; variables used to track happiness for each actor
	float ActorHappiness
	bool ActorBed
	bool ActorShelter
	bool ActorFood
	bool ActorWater

	
	;WSWF - Removed UFO4P Notes to make skimming through code easier	
	;UFO4P: new code starts here:
	;----------------------------
	
	int Actors_Human = updateData.totalPopulation - updateData.robotPopulation	

	;helper array for all resource values that contribute to actor happiness
	int[] ResourceCount = New int [5]
	;helper array that holds the positions at which the individual resource values are found in the ResourceCount array:
	int[] ResourcePos = New Int [4]

	;helper variables for quick access of the respective resources in ResourcePos array:
	Int posShelter = 0
	Int posBeds = 1
	Int posWater = 2
	Int posFood = 3

	;Since updateData.shelteredBeds <= updateData.availableBeds, and both updateData.availableWater and updateData.availableFood are usually larger than the
	;latter, filling the array in the following order will save a couple of swaps when it is sorted below:
	ResourceCount[0] = updateData.shelteredBeds
	ResourceCount[1] = updateData.availableBeds
	ResourceCount[2] = updateData.availableWater
	ResourceCount[3] = updateData.availableFood
	;This is a helper position for all actors who do not benefit from any rexource. Set this to the maximum possible value:
	ResourceCount[4] = Actors_Human

	;Save the positions of the resource values in ResourceCount array in the ResourcePos array. After the arrays are sorted, ResourcePos [posShelter], ResourcePos
	;[posBeds], etc. will return the positions at which updateData.shelteredBeds, updateData.availableBeds etc. have ended up in the ResourceCount array.
	ResourcePos [posShelter] = 0
	ResourcePos [posBeds] = 1
	ResourcePos [posWater] = 2
	ResourcePos [posFood] = 3

	;sort arrays (disregard last position of the ResourceCount array):
	int i = 3
	While (i > 0)
		int j = 0
		While (j < i)
			If ResourceCount [j] > ResourceCount [j + 1]
				int swapInt = ResourceCount [j]
				ResourceCount [j] = ResourceCount [j + 1]
				ResourceCount [j + 1] = swapInt
				swapInt = ResourcePos [j]
				ResourcePos [j] = ResourcePos [j + 1]
				ResourcePos [j + 1] = swapInt
			EndIf
			j += 1
		EndWhile
		i -= 1
	EndWhile

	;Calculate the numbers of actors to benefit from the individual resources (again, the last array position is disregarded).
	i = 3
	while i > 0
		ResourceCount [i] = ResourceCount [i] - ResourceCount [i - 1]
		i -= 1
	EndWhile
	
	ActorWater = True
	ActorFood = True
	ActorBed = True
	ActorShelter = True

	;Calculate the maximum possible ActorHappiness. This value applies to all actors who benefit from all four resources. As the loop progresses, individual
	;boni will be subtracted from this value:
	ActorHappiness = happinessBonusWater + happinessBonusFood + happinessBonusBed + happinessBonusShelter
	;The safety bonus applies either to all actors or to none:
	If updateData.safetyperNPC > 0
		ActorHappiness += happinessBonusSafety
	EndIf

	Int ActorCount = Math.Min (ResourceCount [0], Actors_Human) As Int
	Int RemainingActors = Actors_Human - ActorCount

	;For i = 0, none of the conditions checksd in the loop would return true and there is also no need to call the CheckActorHappiness function (because there
	;are no happiness caps applying when no resources are missing). Therefore, we take the following value as start value and begin the loop with i = 1
	updateData.totalHappiness = updateData.totalHappiness + (ActorCount * ActorHappiness)
		
	i = 1	
	while i < 5 && RemainingActors > 0

		If ActorWater && ResourcePos [posWater] < i
			ActorHappiness -= happinessBonusWater
			ActorWater = False
		EndIf
				
		If ActorFood && ResourcePos [posFood] < i
			ActorHappiness -= happinessBonusFood
			ActorFood = False
		EndIf

		If ActorBed && ResourcePos [posBeds] < i
			ActorHappiness -= happinessBonusBed
			ActorBed = False
		EndIf

		If ActorShelter && ResourcePos [posShelter] < i
			ActorHappiness -= happinessBonusShelter
			ActorShelter = False
		EndIf		

		ActorCount = Math.Min (ResourceCount [i], RemainingActors) As Int
		RemainingActors -= ActorCount

		Float CorrectedActorHappiness = CheckActorHappiness (ActorHappiness, ActorFood, ActorWater, ActorBed, ActorShelter)
		updateData.totalHappiness = updateData.totalHappiness + ActorCount * CorrectedActorHappiness
		
		i += 1

	EndWhile

	updateData.totalHappiness = updateData.totalHappiness + ( 50 * updateData.robotPopulation)
	
	int iMissingBeds = Math.Max (0, Actors_Human - updateData.availableBeds) As Int
	SetAndRestoreActorValue(self, MissingBeds, iMissingBeds)
	
	;/ WSWF - Actual Food/Water consumption is now handled by our WorkshopResourceManager script
		; Removed bRealUpdate consumption code
	/;

	; add "bonus happiness" and any happiness modifiers
	updateData.totalHappiness = updateData.totalHappiness + updateData.bonusHappiness

	; calculate happiness
	; add happiness modifier here - it isn't dependent on population
	updateData.totalHappiness = math.max(updateData.totalHappiness/updateData.totalPopulation + updateData.happinessModifier, 0)
	; don't let happiness exceed 100
	updateData.totalHappiness = math.min(updateData.totalHappiness, 100)

	; for now, record this as a rating
	SetAndRestoreActorValue(self, HappinessTarget, updateData.totalHappiness)

	; REAL UPDATE ONLY:
	if bRealUpdate
		float deltaHappinessFloat = (updateData.totalHappiness - updateData.currentHappiness) * happinessChangeMult
	
		int deltaHappiness
		if deltaHappinessFloat < 0
			deltaHappiness = math.floor(deltaHappinessFloat)	; how much does happiness want to change?
		else
			deltaHappiness = math.ceiling(deltaHappinessFloat)	; how much does happiness want to change?
		endif

		if deltaHappiness != 0 && math.abs(deltaHappiness) < minHappinessChangePerUpdate
			; increase delta to the min
			deltaHappiness = minHappinessChangePerUpdate * (deltaHappiness/math.abs(deltaHappiness)) as int
		endif
		
		; update happiness rating on workshop's location
		ModifyActorValue(self, Happiness, deltaHappiness)

		; what is happiness now?
		float finalHappiness = GetValue(Happiness)
		
		; achievement
		if finalHappiness >= WorkshopParent.HappinessAchievementValue
			;debug.Trace(self + " HAPPINESS ACHIEVEMENT UNLOCKED!!!!")
			Game.AddAchievement(WorkshopParent.HappinessAchievementID)
		endif

		; if happiness is below threshold, no longer player-owned
		if OwnedByPlayer && AllowUnownedFromLowHappiness
			; issue warning?
			if finalHappiness <= minHappinessWarningThreshold && HappinessWarning == false
				HappinessWarning = true
				; always show warning first
				WorkshopParent.DisplayMessage(WorkshopParent.WorkshopUnhappinessWarning, NONE, myLocation)
			elseif finalHappiness <= minHappinessThreshold
				SetOwnedByPlayer(false)
			endif

			; clear warning if above threshold
			if finalHappiness > minHappinessClearWarningThreshold && HappinessWarning == true
				HappinessWarning = false
			endif
		endif

		; happiness modifier tends toward 0 over time
		if updateData.happinessModifier != 0
			float modifierSign = -1 * (updateData.happinessModifier/math.abs(updateData.happinessModifier))
			int deltaHappinessModifier
			float deltaHappinessModifierFloat = math.abs(updateData.happinessModifier) * modifierSign * happinessChangeMult
			if deltaHappinessModifierFloat > 0
				deltaHappinessModifier = math.floor(deltaHappinessModifierFloat)	; how much does happiness modifier want to change?
			else
				deltaHappinessModifier = math.ceiling(deltaHappinessModifierFloat)	; how much does happiness modifier want to change?
			EndIf
			
			if math.abs(deltaHappinessModifier) < happinessBonusChangePerUpdate
				deltaHappinessModifier = (modifierSign * happinessBonusChangePerUpdate) as int
			endif

			if deltaHappinessModifier > math.abs(updateData.happinessModifier)
				WorkshopParent.SetHappinessModifier(self, 0)
			else
				WorkshopParent.ModifyHappinessModifier(self, deltaHappinessModifier)
			endif
		endif

	EndIf

endFunction

function DailyUpdateSurplusResources(WorkshopDataScript:WorkshopRatingKeyword[] ratings, DailyUpdateData updateData, ObjectReference containerRef)
	; WSWF - This is now handled by our WorkshopProductionManager script
	return
endFunction
; ***********************************************
; END DAILY UPDATE HELPER FUNCTIONS
; ***********************************************



; TEMP:
bool showVendorTraces = true

function RepairDamage()
	; repair damage to each resource
	RepairDamageToResource(Food)
	RepairDamageToResource(Water)
	RepairDamageToResource(Safety)
	RepairDamageToResource(Power)
	RepairDamageToResource(Population)

	; repair damage (this is an overall rating that won't exactly match each resource rating)
	float currentDamage = GetValue(DamageCurrent)
	if currentDamage > 0
		; update current damage rating
		WorkshopParent.UpdateCurrentDamage(self)
	endif
endFunction

function RepairDamageToResource(ActorValue resourceValue)
	; get corresponding damage actor value
	ActorValue damageRating = WorkshopParent.GetDamageRatingValue(resourceValue)

	; create local pointer to WorkshopRatings array to speed things up
	WorkshopDataScript:WorkshopRatingKeyword[] ratings = WorkshopParent.WorkshopRatings

	bool bPopulationDamage = ( damageRating == DamagePopulation )

	; get current damage - population is a special case
	float currentDamage
	if bPopulationDamage
		currentDamage = WorkshopParent.GetPopulationDamage(self)
	else
		currentDamage = GetValue(damageRating)
	endif

	int iCurrentWorkshopID = CurrentWorkshopID.GetValueInt()

	;UFO4P 2.0.2 Bug #23016: Added the following lines:
	;If iCurrentWorkshopID is this workshop's ID, make sure that the workshop location is loaded. Otherwise, there actually is no current workshop, so
	;the related properties on WorkshopParentScript have to be reset (and iCurrentWorkshopID set to -1). This will skip some of the subsequent operations
	;that are unsafe to be carried out if the workshop location is not loaded.
	if iCurrentWorkshopID == workshopID && WorkshopParent.UFO4P_IsWorkshopLoaded (self) == false
		iCurrentWorkshopID = -1
	endif

	if currentDamage > 0
		; amount repaired
		; scale this by population (uninjured) - unless this is population
		float repairAmount = 1
		bool bHealedActor = false 	; set to true if we find an actor to heal
		if damageRating != DamagePopulation
			repairAmount = CalculateRepairAmount(ratings)
			repairAmount = math.Max(repairAmount, 1.0)
		else
			; if this is population, try to heal an actor:
			; are any of this workshop's NPC assigned to caravans?
			Location[] linkedLocations = myLocation.GetAllLinkedLocations(WorkshopCaravanKeyword)
			if linkedLocations.Length > 0
				; there is at least 1 actor - find them
				; loop through caravan actors
				int index = 0
				while (index < WorkshopParent.CaravanActorAliases.GetCount())
					; check this actor - is he owned by this workshop?
					WorkShopNPCScript caravanActor = WorkshopParent.CaravanActorAliases.GetAt(index) as WorkshopNPCScript
					if caravanActor && caravanActor.GetWorkshopID() == workshopID && caravanActor.IsWounded()
					; is this actor wounded? if so heal and exit
						bHealedActor = true
						WorkshopParent.WoundActor(caravanActor, false)
						return
					endif
					index += 1
				endwhile
			endif

			if !bHealedActor
				; if this is the current workshop, we can try to heal one of the actors (otherwise we don't have them)
				if workshopID == iCurrentWorkshopID
					int i = 0
					ObjectReference[] WorkshopActors = WorkshopParent.GetWorkshopActors(self)
					while i < WorkshopActors.Length && !bHealedActor
						WorkShopNPCScript theActor = WorkshopActors[i] as WorkShopNPCScript
						if theActor && theActor.IsWounded()
							bHealedActor = true
							WorkshopParent.WoundActor(theActor, false)
						endif
						i += 1
					endWhile
				endif
			endif
		endif

		if !bHealedActor
			; if we healed an actor, keyword data already modified
			repairAmount = math.min(repairAmount, currentDamage)
			ModifyActorValue(self, damageRating, repairAmount*-1.0)
			
			; if this is the current workshop, find an object to repair (otherwise we don't have them)
			if workshopID == iCurrentWorkshopID && damageRating != DamagePopulation
				int i = 0
				; want only damaged objects that produce this resource
				ObjectReference[] ResourceObjects = GetWorkshopResourceObjects(akAV = resourceValue, aiOption = 1)
				while i < ResourceObjects.Length && repairAmount > 0
					WorkShopObjectScript theObject = ResourceObjects[i] as WorkShopObjectScript
					float damage = theObject.GetResourceDamage(resourceValue)
					
					if damage > 0
						float modDamage = math.min(repairAmount, damage)*-1.0
						if theObject.ModifyResourceDamage(resourceValue, modDamage)
							repairAmount += modDamage
						endif
					endif
					i += 1
				endWhile
			endif
		endif
	endif
endFunction

; NOTE: pass in ratings array to speed things up since this is often part of an iteration
float function CalculateRepairAmount(WorkshopDataScript:WorkshopRatingKeyword[] ratings)
	; RESOURCE CHANGE: now GetValue(population) is the unwounded population; GetBaseValue() is total population
	float uninjuredPopulation = GetValue(Population)
	float productivityMult = GetProductivityMultiplier(ratings)
	float amountRepaired = math.Ceiling(uninjuredPopulation * damageDailyPopulationMult * damageDailyRepairBase * productivityMult)
	
	return amountRepaired
endFunction

function CheckForAttack(bool bForceAttack = false)
	; bForceAttack = true  - don't roll, automatically trigger attack
	; create local pointer to WorkshopRatings array to speed things up
	WorkshopDataScript:WorkshopRatingKeyword[] ratings = WorkshopParent.WorkshopRatings

	; PREVIOUS ATTACKS:
	; increment days since last attack
	ModifyActorValue(self, LastAttackDaysSince, 1.0)

	; attacks allowed at all?
	if AllowAttacks == false
		return
	EndIf

	; don't attack unowned workshop if flag unless allowed
	if AllowAttacksBeforeOwned == false && OwnedByPlayer == false && bForceAttack == false
		return
	endif

	; NEW ATTACK:
	ObjectReference containerRef = GetContainer()
	if !containerRef
		return
	endif

	int totalPopulation = GetBaseValue(Population) as int
	int iSafety = GetValue(Safety) as int
	int safetyPerNPC = 0
	if totalPopulation > 0
		safetyperNPC = math.ceiling(iSafety/totalPopulation)
	elseif bForceAttack
		safetyperNPC = iSafety
	else
		; no population - no attack
		return
	endif

	int daysSinceLastAttack = GetValue(LastAttackDaysSince) as int
	if minDaysSinceLastAttack > daysSinceLastAttack && !bForceAttack
		; attack happened recently - no new attack
		return
	endif

	int foodRating = GetTotalFoodRating(ratings)
	int waterRating = GetTotalWaterRating(ratings)

	; chance of attack:
	; 	base chance + (food/water rating) - iSafety - total population
	float attackChance = attackChanceBase + attackChanceResourceMult * (foodRating + waterRating) - attackChanceSafetyMult*iSafety - attackChancePopulationMult * totalPopulation
	if attackChance < attackChanceBase
		attackChance = attackChanceBase
	endif
	
	
	float attackRoll = Utility.RandomFloat()
	
	if attackRoll <= attackChance || bForceAttack
		int attackStrength = CalculateAttackStrength(foodRating, waterRating)
		WorkshopParent.TriggerAttack(self, attackStrength)
	endif
endFunction


; WSWF - Copy from WorkshopParent, which will use local version of maxAttackStrength 
int function CalculateAttackStrength(int foodRating, int waterRating)
	; attack strength: based on "juiciness" of target
	int attackStrength = math.min(foodRating + waterRating, maxAttackStrength) as int
	int attackStrengthMin = attackStrength/2 * -1
	int attackStrengthMax = attackStrength/2
	
	attackStrength = math.min(attackStrength + utility.randomInt(attackStrengthMin, attackStrengthMax), maxAttackStrength) as int
	
	return attackStrength
endFunction


; WSWF - Copy from WorkShopParent, which will use local version of maxDefenseStrength
int function CalculateDefenseStrength(int aiSafety, int totalPopulation)
	int defenseStrength = math.min(aiSafety + totalPopulation, maxDefenseStrength) as int
	
	return defenseStrength
endFunction


; helper function to calculate total food = food production + inventory
int function GetTotalFoodRating(WorkshopDataScript:WorkshopRatingKeyword[] ratings)
	int foodRating = GetValue(Food) as int
	foodRating = foodRating + GetContainer().GetItemCount(ObjectTypeFood)
	
	return foodRating
endFunction

; helper function to calculate total water = water production + inventory
int function GetTotalWaterRating(WorkshopDataScript:WorkshopRatingKeyword[] ratings)
	int waterRating = GetValue(Water) as int
	waterRating = waterRating + GetContainer().GetItemCount(ObjectTypeWater)
	
	return waterRating
endFunction

; helper function - add modValue to the specified actor's happiness
; holds the rules for how happiness can go up based on the actor's various ratings (food, water, shelter, etc.)

;
; WSWF - Undid the UFO4P Change to this function as it assumed that the maxHappinessNoFood/maxHappinessNoWater are always less than maxHappinessNoShelter - which isn't necessarily true now that we've converted them to controllable properties
;

float function CheckActorHappiness(float currentHappiness, bool bFood, bool bWater, bool bBed, bool bShelter)
	; check rules
	if !bWater && currentHappiness > maxHappinessNoWater
		; max happiness with no water is maxHappinessNoWater
		currentHappiness = maxHappinessNoWater
	endif

	if !bFood && currentHappiness > maxHappinessNoFood
		; max happiness with no food is maxHappinessNoFood
		currentHappiness = maxHappinessNoFood
	endif

	if !bShelter && currentHappiness > maxHappinessNoShelter
		; max happiness with no shelter is maxHappinessNoShelter
		currentHappiness = maxHappinessNoShelter
	endif

	return currentHappiness
endFunction

;--------------------------------------------------------------------------------------------------------------------------------

; get productivity multiplier for this workshop
float function GetProductivityMultiplier(WorkshopDataScript:WorkshopRatingKeyword[] ratings)
	float currentHappiness = GetValue(Happiness)
	return minProductivity + (currentHappiness/100) * (1 - minProductivity)
endFunction


int function GetWorkshopID()
	if workshopID < 0
		InitWorkshopID(WorkshopParent.GetWorkshopID(self))
	endif
	return workshopID
endFunction

function InitWorkshopID(int newWorkshopID)
	if workshopID < 0
		workshopID = newWorkshopID
	endif
endFunction

; helper function to recalc
; we don't normally want to do this when unloaded or everything will be 0
; TRUE = we did recalc; FALSE = we didn't
bool function RecalculateWorkshopResources(bool bOnlyIfLocationLoaded = true)

	;if bOnlyIfLocationLoaded == false || myLocation.IsLoaded()
	;UFO4P 2.0.3 Bug #23469: replaced the previous line with the following line:
	;IsLoaded() returns 'true' if any cell of a location is loaded. Thus, it will be 'true' even if only a few cells on the edge of the player's 5x5 grid are
	;loaded and most of the workshop is still in unloaded area. Checking for the player currently being within a cell of the workshop will remedy the problem
	;for small workshops that cover an area not larger than 3x3 cells. For larger workshops, there's currently no practicable solution.
	;if bOnlyIfLocationLoaded == false || Game.GetPlayer().GetCurrentLocation() == myLocation
	
	;UFO4P 2.0.4 Bug #24122: replaced the previous line with the following line:
	;While in workshop mode, the player's current location is 'none' (entering/leaving workshop mode triggers a location change event). Thus,
	;the location check alone is not reliable and may result in the rexource calculation never running at all if the player spends extended
	;peropds of time in workshop mode.
	if bOnlyIfLocationLoaded == false || Game.GetPlayer().GetCurrentLocation() == myLocation || UFO4P_InWorkshopMode == true
	
		RecalculateResources()
		return true
	else
		return false
	endif
endFunction 

;----------------------------------------------------------------------------------------------------------------------------------------------------------
;	Added by UFO4P 2.0.2 for bug #21408:
;
;	This function clears faction ownership settings on preplaced beds as they may cause trouble once the workshop is player-owned:
;	- Beds with faction ownership are automatically considered as assigned, even if no specific actor has been assigned as their owner
;	- Likewise, actors in the bed ownership faction are considered as having a bed assigned.
;	The workshop scripts never try on their own to assign a faction-owned bed to anyone, or to assign actors in the owning faction to other beds when
;	they run their householding functions, but workshop mode allows the player to do it anyway. This leads to various unwanted results:
;	- For some reason, the AI appears to prefer faction onwed beds. Even if assigned to another bed, an actor in the bed-owning faction will
;	  continue to use the beds owned by his faction.
;	- Assigning an actor to a faction-owend bed seems not to work properly, presumably because he's not in the bed-owning faction. Workshop logs
;	  show that he effectively remains unassigned.
;	- Workshop logs also show that bed assignment may break at the affected workshops entirely: in workshop mode, all beds will show as unassigned
;	  and the householding functions running on subsequent visits to this workshop show all actors as having no bed assigned.
;
;----------------------------------------------------------------------------------------------------------------------------------------------------------

function UFO4P_ClearFactionOwnershipOnBeds()
	ObjectReference[] BedRefs = WorkshopParent.GetBeds(self)
	
	int bedCount = BedRefs.Length
	int i = 0
	while i < bedCount
		WorkshopObjectScript theBed = BedRefs[i] as WorkshopObjectScript
		if theBed && theBed.GetFactionOwner() != none
			theBed.SetFactionOwner(none)
		endif
		i += 1
	endWhile
	UFO4P_CheckFactionOwnershipClearedOnBeds = false
endFunction
