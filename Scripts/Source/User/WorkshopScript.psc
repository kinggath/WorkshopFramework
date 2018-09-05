Scriptname WorkshopScript extends ObjectReference Conditional
{script for Workshop reference}

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
EndGroup

;******************
; moved from workshopparent			
; WSWF: Note - This was all added here by BGS to avoid having to constantly query WorkshopParent for the numbers

; productivity formula stuff
Bool bUseGlobalminProductivity = true
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
		if(aValue == -1)
			bUseGlobalminProductivity = true
		else
			WSWF_minProductivity = aValue
		endif
	EndFunction
EndProperty

Bool bUseGlobalproductivityHappinessMult = true
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
		if(aValue == -1)
			bUseGlobalproductivityHappinessMult = true
		else
			WSWF_productivityHappinessMult = aValue
		endif
	EndFunction
EndProperty

; happiness formula stuff
Bool bUseGlobalmaxHappinessNoFood = true
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
		if(aValue == -1)
			bUseGlobalmaxHappinessNoFood = true
		else
			WSWF_maxHappinessNoFood = aValue
		endif
	EndFunction
EndProperty

Bool bUseGlobalmaxHappinessNoWater = true
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
		if(aValue == -1)
			bUseGlobalmaxHappinessNoWater = true
		else
			WSWF_maxHappinessNoWater = aValue
		endif
	EndFunction
EndProperty

Bool bUseGlobalmaxHappinessNoShelter = true
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
		if(aValue == -1)
			bUseGlobalmaxHappinessNoShelter = true
		else
			WSWF_maxHappinessNoShelter = aValue
		endif
	EndFunction
EndProperty

Bool bUseGlobalhappinessBonusFood = true
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
		if(aValue == -1)
			bUseGlobalhappinessBonusFood = true
		else
			WSWF_happinessBonusFood = aValue
		endif
	EndFunction
EndProperty

Bool bUseGlobalhappinessBonusWater = true
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
		if(aValue == -1)
			bUseGlobalhappinessBonusWater = true
		else
			WSWF_happinessBonusWater = aValue
		endif
	EndFunction
EndProperty

Bool bUseGlobalhappinessBonusBed = true
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
		if(aValue == -1)
			bUseGlobalhappinessBonusBed = true
		else
			WSWF_happinessBonusBed = aValue
		endif
	EndFunction
EndProperty

Bool bUseGlobalhappinessBonusShelter = true
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
		if(aValue == -1)
			bUseGlobalhappinessBonusShelter = true
		else
			WSWF_happinessBonusShelter = aValue
		endif
	EndFunction
EndProperty

Bool bUseGlobalhappinessBonusSafety = true
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
		if(aValue == -1)
			bUseGlobalhappinessBonusSafety = true
		else
			WSWF_happinessBonusSafety = aValue
		endif
	EndFunction
EndProperty

Bool bUseGlobalminHappinessChangePerUpdate = true
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
		if(aValue == -1)
			bUseGlobalminHappinessChangePerUpdate = true
		else
			WSWF_minHappinessChangePerUpdate = aValue
		endif
	EndFunction
EndProperty

Bool bUseGlobalhappinessChangeMult = true
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
		if(aValue == -1)
			bUseGlobalhappinessChangeMult = true
		else
			WSWF_happinessChangeMult = aValue
		endif
	EndFunction
EndProperty		
		
Bool bUseGlobalminHappinessThreshold = true
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
		if(aValue == -1)
			bUseGlobalminHappinessThreshold = true
		else
			WSWF_minHappinessThreshold = aValue
		endif
	EndFunction
EndProperty

Bool bUseGlobalminHappinessWarningThreshold = true
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
		if(aValue == -1)
			bUseGlobalminHappinessWarningThreshold = true
		else
			WSWF_minHappinessWarningThreshold = aValue
		endif
	EndFunction
EndProperty
				
Bool bUseGlobalminHappinessClearWarningThreshold = true
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
		if(aValue == -1)
			bUseGlobalminHappinessClearWarningThreshold = true
		else
			WSWF_minHappinessClearWarningThreshold = aValue
		endif
	EndFunction
EndProperty	

Bool bUseGlobalhappinessBonusChangePerUpdate = true
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
		if(aValue == -1)
			bUseGlobalhappinessBonusChangePerUpdate = true
		else
			WSWF_happinessBonusChangePerUpdate = aValue
		endif
	EndFunction
EndProperty
	

; production
Bool bUseGlobalmaxStoredFoodBase = true
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
		if(aValue == -1)
			bUseGlobalmaxStoredFoodBase = true
		else
			WSWF_maxStoredFoodBase = aValue
		endif
	EndFunction
EndProperty
				
Bool bUseGlobalmaxStoredFoodPerPopulation = true
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
		if(aValue == -1)
			bUseGlobalmaxStoredFoodPerPopulation = true
		else
			WSWF_maxStoredFoodPerPopulation = aValue
		endif
	EndFunction
EndProperty

Bool bUseGlobalmaxStoredWaterBase = true
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
		if(aValue == -1)
			bUseGlobalmaxStoredWaterBase = true
		else
			WSWF_maxStoredWaterBase = aValue
		endif
	EndFunction
EndProperty

Bool bUseGlobalmaxStoredWaterPerPopulation = true
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
		if(aValue == -1)
			bUseGlobalmaxStoredWaterPerPopulation = true
		else
			WSWF_maxStoredWaterPerPopulation = aValue
		endif
	EndFunction
EndProperty	
				
Bool bUseGlobalmaxStoredScavengeBase = true
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
		if(aValue == -1)
			bUseGlobalmaxStoredScavengeBase = true
		else
			WSWF_maxStoredScavengeBase = aValue
		endif
	EndFunction
EndProperty

Bool bUseGlobalmaxStoredScavengePerPopulation = true
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
		if(aValue == -1)
			bUseGlobalmaxStoredScavengePerPopulation = true
		else
			WSWF_maxStoredScavengePerPopulation = aValue
		endif
	EndFunction
EndProperty		
	
Bool bUseGlobalbrahminProductionBoost = true
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
		if(aValue == -1)
			bUseGlobalbrahminProductionBoost = true
		else
			WSWF_brahminProductionBoost = aValue
		endif
	EndFunction
EndProperty	

Bool bUseGlobalmaxProductionPerBrahmin = true
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
		if(aValue == -1)
			bUseGlobalmaxProductionPerBrahmin = true
		else
			WSWF_maxProductionPerBrahmin = aValue
		endif
	EndFunction
EndProperty		
				
Bool bUseGlobalmaxBrahminFertilizerProduction = true
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
		if(aValue == -1)
			bUseGlobalmaxBrahminFertilizerProduction = true
		else
			WSWF_maxBrahminFertilizerProduction = aValue
		endif
	EndFunction
EndProperty					

Bool bUseGlobalmaxStoredFertilizerBase = true
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
		if(aValue == -1)
			bUseGlobalmaxStoredFertilizerBase = true
		else
			WSWF_maxStoredFertilizerBase = aValue
		endif
	EndFunction
EndProperty					

; vendor income
Bool bUseGlobalminVendorIncomePopulation = true
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
		if(aValue == -1)
			bUseGlobalminVendorIncomePopulation = true
		else
			WSWF_minVendorIncomePopulation = aValue
		endif
	EndFunction
EndProperty	

Bool bUseGlobalmaxVendorIncome = true
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
		if(aValue == -1)
			bUseGlobalmaxVendorIncome = true
		else
			WSWF_maxVendorIncome = aValue
		endif
	EndFunction
EndProperty	
				
Bool bUseGlobalvendorIncomePopulationMult = true
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
		if(aValue == -1)
			bUseGlobalvendorIncomePopulationMult = true
		else
			WSWF_vendorIncomePopulationMult = aValue
		endif
	EndFunction
EndProperty						

Bool bUseGlobalvendorIncomeBaseMult = true
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
		if(aValue == -1)
			bUseGlobalvendorIncomeBaseMult = true
		else
			WSWF_vendorIncomeBaseMult = aValue
		endif
	EndFunction
EndProperty		
				

; radio/attracting NPC stuff
Bool bUseGlobaliMaxSurplusNPCs = true
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
		if(aValue == -1)
			bUseGlobaliMaxSurplusNPCs = true
		else
			WSWF_iMaxSurplusNPCs = aValue
		endif
	EndFunction
EndProperty	
			
Bool bUseGlobalattractNPCDailyChance = true
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
		if(aValue == -1)
			bUseGlobalattractNPCDailyChance = true
		else
			WSWF_attractNPCDailyChance = aValue
		endif
	EndFunction
EndProperty			
 	
Bool bUseGlobaliMaxBonusAttractChancePopulation = true
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
		if(aValue == -1)
			bUseGlobaliMaxBonusAttractChancePopulation = true
		else
			WSWF_iMaxBonusAttractChancePopulation = aValue
		endif
	EndFunction
EndProperty		

Bool bUseGlobaliBaseMaxNPCs = true
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
		if(aValue == -1)
			bUseGlobaliBaseMaxNPCs = true
		else
			WSWF_iBaseMaxNPCs = aValue
		endif
	EndFunction
EndProperty	

Bool bUseGlobalattractNPCHappinessMult = true
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
		if(aValue == -1)
			bUseGlobalattractNPCHappinessMult = true
		else
			WSWF_attractNPCHappinessMult = aValue
		endif
	EndFunction
EndProperty			
		

; attack chance formula
Bool bUseGlobalattackChanceBase = true
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
		if(aValue == -1)
			bUseGlobalattackChanceBase = true
		else
			WSWF_attackChanceBase = aValue
		endif
	EndFunction
EndProperty		

Bool bUseGlobalattackChanceResourceMult = true
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
		if(aValue == -1)
			bUseGlobalattackChanceResourceMult = true
		else
			WSWF_attackChanceResourceMult = aValue
		endif
	EndFunction
EndProperty	

Bool bUseGlobalattackChanceSafetyMult = true
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
		if(aValue == -1)
			bUseGlobalattackChanceSafetyMult = true
		else
			WSWF_attackChanceSafetyMult = aValue
		endif
	EndFunction
EndProperty	

Bool bUseGlobalattackChancePopulationMult = true
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
		if(aValue == -1)
			bUseGlobalattackChancePopulationMult = true
		else
			WSWF_attackChancePopulationMult = aValue
		endif
	EndFunction
EndProperty	

Bool bUseGlobalminDaysSinceLastAttack = true
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
		if(aValue == -1)
			bUseGlobalminDaysSinceLastAttack = true
		else
			WSWF_minDaysSinceLastAttack = aValue
		endif
	EndFunction
EndProperty	
		

; damage
Bool bUseGlobaldamageDailyRepairBase = true
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
		if(aValue == -1)
			bUseGlobaldamageDailyRepairBase = true
		else
			WSWF_damageDailyRepairBase = aValue
		endif
	EndFunction
EndProperty	

Bool bUseGlobaldamageDailyPopulationMult = true
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
		if(aValue == -1)
			bUseGlobaldamageDailyPopulationMult = true
		else
			WSWF_damageDailyPopulationMult = aValue
		endif
	EndFunction
EndProperty	
			
			

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
	;WorkshopParent.wsTrace(self + " GetVendorContainersByType " + vendorType)
	if vendorType == 0
		if VendorContainersMisc == NONE
			VendorContainersMisc = InitializeVendorChests(vendorType)
		endif
		return VendorContainersMisc
	elseif vendorType == 1
		;WorkshopParent.wsTrace("  VendorContainersArmor = NONE?" + (VendorContainersArmor == NONE) )
		;WorkshopParent.wsTrace("  VendorContainersArmor.Length =" + VendorContainersArmor.Length)
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
	else
		;WorkshopParent.wsTrace(self + " GetVendorContainersByType: WARNING - invalid vendorType=" + vendorType)
	endif
endFunction

; TODO WSWF: Integrate with our injection manager to allow mods to more easily alter the vendor chests

ObjectReference[] function InitializeVendorChests(int vendorType)
	;WorkshopParent.wsTrace(self + " InitializeVendorChests: vendorType=" + vendorType)
	; initialize array
	int containerArraySize = WorkshopParent.VendorTopLevel + 1
	ObjectReference[] vendorContainers = new ObjectReference[containerArraySize]

	; create the chests
	FormList vendorContainerList = WorkshopParent.WorkshopVendorContainers[vendorType]
	int vendorLevel = 0
	while vendorLevel <= WorkshopParent.VendorTopLevel
		;WorkshopParent.wsTrace(" vendorLevel=" + vendorLevel)
		; create ref for each vendor level
		vendorContainers[vendorLevel] = WorkshopParent.WorkshopHoldingCellMarker.PlaceAtMe(vendorContainerList.GetAt(vendorLevel))
		;WorkshopParent.wsTrace(" 		container=" + vendorContainers[vendorLevel])
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
	SetValue(WorkshopParent.WorkshopRatings[WorkshopParent.WorkshopRatingHappinessTarget].resourceValue, WorkshopParent.startingHappinessTarget)
EndEvent

Event OnLoad()
	; for now, block activation if not "owned" by player
	BlockActivation(!OwnedByPlayer)
	; grab inventory from linked container if I'm a container myself
	if (GetBaseObject() as Container)
		; get linked container
		ObjectReference linkedContainer = GetLinkedRef(WorkshopParent.WorkshopLinkContainer)
		if linkedContainer
			linkedContainer.RemoveAllItems(self)
		endif

		; get all linked containers (children)
		ObjectReference[] linkedContainers = GetLinkedRefChildren(WorkshopParent.WorkshopLinkContainer)
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
				int totalPopulation = GetBaseValue(WorkshopParent.WorkshopRatings[WorkshopParent.WorkshopRatingPopulation].resourceValue) as int

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
					
		;WorkshopParent.wsTrace(" 	sending WorkshopEnterMenu event")
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
	;WorkshopParent.wsTrace(self + " OnTimer: timerID=" + aiTimerID)
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
			WorkshopParent.wsTrace(self + " DailyUpdate: system busy, try again in " + waitTime + " game hours")
			; run another timer - system is too busy
			StartTimerGameTime(waitTime, dailyUpdateTimerID)
		else
			DailyUpdate()
		endif	
	endif
endEvent

function SetOwnedByPlayer(bool bIsOwned)
	;WorkshopParent.wsTrace(self + " SetOwnedByPlayer(" + bIsOwned + ")")

	; is state changing?
	if !bIsOwned && OwnedByPlayer
		;WorkshopParent.wsTrace(self + " SetOwnedByPlayer: state changing to UNOWNED")
		OwnedByPlayer = bIsOwned ; do this here so workshop is updated for UpdatePlayerOwnership check

		; display loss of ownership message
		WorkshopParent.DisplayMessage(WorkshopParent.WorkshopLosePlayerOwnership, NONE, myLocation)
		; flag as "lost control"
		SetValue(WorkshopParent.WorkshopPlayerLostControl, 1.0)
		; clear farm discount faction if we can get actors
		ObjectReference[] WorkshopActors = WorkshopParent.GetWorkshopActors(self)
		int i = 0
		while i < WorkshopActors.Length
			WorkshopNPCScript theActor = (WorkshopActors[i] as Actor) as WorkshopNPCScript
			if theActor
				theActor.RemoveFromFaction(WorkshopParent.FarmDiscountFaction)
				; clear "player owned" actor value (used to condition trade items greetings)
				theActor.UpdatePlayerOwnership(self)
			endif
			i += 1
		endWhile

		; remove all caravans to/from this settlement
		WorkshopParent.ClearCaravansFromWorkshopPUBLIC(self)

	elseif bIsOwned && !OwnedByPlayer
		;WorkshopParent.wsTrace(self + " SetOwnedByPlayer: state changing to OWNED")
		OwnedByPlayer = bIsOwned ; do this here so workshop is updated for UpdatePlayerOwnership check

		; make sure owns a workshop flag is set first time you own one
		if !WorkshopParent.PlayerOwnsAWorkshop
			WorkshopParent.PlayerOwnsAWorkshop = true
		endif

		; make sure happiness (and happiness target) is set to minimum (so doesn't immediately become unowned again)
		float currentHappiness = GetValue(WorkshopParent.WorkshopRatings[WorkshopParent.WorkshopRatingHappiness].resourceValue)
		float currentHappinessTarget = GetValue(WorkshopParent.WorkshopRatings[WorkshopParent.WorkshopRatingHappinessTarget].resourceValue)
		if currentHappiness < minHappinessClearWarningThreshold || currentHappinessTarget < minHappinessClearWarningThreshold
			WorkshopParent.ModifyResourceData(WorkshopParent.WorkshopRatings[WorkshopParent.WorkshopRatingHappiness].resourceValue, self, minHappinessClearWarningThreshold)		
			WorkshopParent.ModifyResourceData(WorkshopParent.WorkshopRatings[WorkshopParent.WorkshopRatingHappinessTarget].resourceValue, self, minHappinessClearWarningThreshold)		
		EndIf

		; display gain of ownership message
		;WorkshopParent.wsTrace(self + " SetOwnedByPlayer - display message for location " + myLocation)
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
	SetValue(WorkshopParent.WorkshopPlayerOwnership, (bIsOwned as float))
	;WorkshopParent.SetResourceData(WorkshopParent.WorkshopPlayerOwnership, self, (bIsOwned as float))

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
	;WorkshopParent.wsTrace(self + " received OnWorkshopObjectPlaced event")
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
	;WorkshopParent.wsTrace(self + " received OnWorkshopObjectMoved event. ObjectRef = " + akReference)
	; for now, just tell the object it moved so it can update markers etc.
	WorkshopObjectScript workshopObjectRef = akReference as WorkShopObjectScript

	if workshopObjectRef
;		workshopObjectRef.UpdatePosition()
		; send custom event for this object
		Var[] kargs = new Var[2]
		kargs[0] = workshopObjectRef
		kargs[1] = self
		;WorkshopParent.wsTrace(" 	sending WorkshopObjectMoved event")
		WorkshopParent.SendCustomEvent("WorkshopObjectMoved", kargs)		
	endif
EndEvent

Event OnWorkshopObjectDestroyed(ObjectReference akReference)
	;WorkshopParent.wsTrace(self + " received OnWorkshopObjectDestroyed event. ObjectRef = " + akReference)
	WorkshopParent.RemoveObjectPUBLIC(akReference, self)
endEvent

Event OnWorkshopObjectRepaired(ObjectReference akReference)
	;WorkshopParent.wsTrace(self + " received OnWorkshopObjectRepaired event")
	WorkshopObjectActorScript workshopObjectActor = akReference as WorkshopObjectActorScript
	if workshopObjectActor
		;WorkshopParent.wsTrace(self + " repairing object actor " + workshopObjectActor)
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
		;WorkshopParent.wsTrace(" 	sending WorkshopObjectMoved event")
		WorkshopParent.SendCustomEvent("WorkshopObjectRepaired", kargs)		
	endif

endEvent

ObjectReference function GetContainer()
	if (GetBaseObject() as Container)
		return self
	else
		return GetLinkedRef(WorkshopParent.WorkshopLinkContainer)
	endif
endFunction

Event WorkshopParentScript.WorkshopDailyUpdate(WorkshopParentScript akSender, Var[] akArgs)
	; calculate custom time interval for this workshop (to stagger out the update process throughout the day)
	float waitTime = WorkshopParent.dailyUpdateIncrement * workshopID
	;WorkshopParent.wsTrace(self + " WorkshopDailyUpdate event received with wait time " + waitTime + " hours")
	StartTimerGameTime(waitTime, dailyUpdateTimerID)
EndEvent

; return max NPCs for this workshop
int function GetMaxWorkshopNPCs()
	; base + player's charisma
	int iMaxNPCs = iBaseMaxNPCs + (Game.GetPlayer().GetValue(WorkshopParent.Charisma) as int)
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
	WorkshopParent.wsTrace(self + "------------------------------------------------------------------------------ ")
	WorkshopParent.wsTrace(self + " 	DAILY UPDATE: bRealUpdate = " + bRealUpdate + ", bResetHappiness = " + bResetHappiness, bNormalTraceAlso = true)
	WorkshopParent.wsTrace(self + "------------------------------------------------------------------------------ ")

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
	;WorkshopParent.wsTrace(self + "bDailyUpdateInProgress = " + bDailyUpdateInProgress)
	WorkshopParent.wsTrace(self + " 	WorkshopParent.DailyUpdateInProgress = " + WorkshopParent.DailyUpdateInProgress)
	WorkshopParent.wsTrace(self + "------------------------------------------------------------------------------ ")

	; wait for update lock to be released
	;UFO4P 1.0.2 Bug #20295: Checking WorkshopParent.DailyUpdateInProgress here instead of bDailyUpdateInProgress
	if WorkshopParent.DailyUpdateInProgress
		;UFO4P 1.0.3 Bug #20775: if bResetHappiness = true, the call should not be skipped even when bRealUpdate = false:
		if bRealUpdate || bResetHappiness
			WorkshopParent.wsTrace(self + "		waiting for update lock to clear ...")
			;UFO4P 1.0.2 Bug #20295: Added a loop to wait for the thread to unlock (without that loop, the lock won't work)
			While WorkshopParent.DailyUpdateInProgress
				utility.wait(0.5)
			EndWhile
		else
			; just bail if not a real update - no need
			;UFO4P 2.0: the following trace has been commented out (no need to log this)
			;WorkshopParent.wsTrace(self + "		update already in progress - don't try again right now")
			return
		endif
	EndIf
	;bDailyUpdateInProgress = true
	WorkshopParent.DailyUpdateInProgress = true

	;UFO4P 1.0.2 Bug #20295: Moved this block of code up here: There's no need to proceed with the function if we have to bail out anyway.
	ObjectReference containerRef = GetContainer()
	if !containerRef
		WorkshopParent.wsTrace(self + " ERROR - no container linked to workshop " + self + " with " + WorkshopParent.WorkshopLinkContainer, 2)
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
	updateData.totalPopulation = GetBaseValue(ratings[WorkshopParent.WorkshopRatingPopulation].resourceValue) as int
	updateData.robotPopulation = GetBaseValue(ratings[WorkshopParent.WorkshopRatingPopulationRobots].resourceValue) as int
	updateData.brahminPopulation = GetBaseValue(ratings[WorkshopParent.WorkshopRatingBrahmin].resourceValue) as int
	updateData.unassignedPopulation = GetBaseValue(ratings[WorkshopParent.WorkshopRatingPopulationUnassigned].resourceValue) as int

	updateData.vendorIncome = GetValue(ratings[WorkshopParent.WorkshopRatingVendorIncome].resourceValue) * vendorIncomeBaseMult
	updateData.currentHappiness = GetValue(ratings[WorkshopParent.WorkshopRatingHappiness].resourceValue)

	updateData.damageMult = 1 - GetValue(ratings[WorkshopParent.WorkshopRatingDamageCurrent].resourceValue)/100.0
	updateData.productivity = GetProductivityMultiplier(ratings)
	updateData.availableBeds = GetBaseValue(ratings[WorkshopParent.WorkshopRatingBeds].resourceValue) as int
	updateData.shelteredBeds = GetValue(ratings[WorkshopParent.WorkshopRatingBeds].resourceValue) as int
	updateData.bonusHappiness = GetValue(ratings[WorkshopParent.WorkshopRatingBonusHappiness].resourceValue) as int
	updateData.happinessModifier = GetValue(ratings[WorkshopParent.WorkshopRatingHappinessModifier].resourceValue) as int
	updateData.safety = GetValue(ratings[WorkshopParent.WorkshopRatingSafety].resourceValue) as int
	updateData.safetyDamage = GetValue(WorkshopParent.GetDamageRatingValue(ratings[WorkshopParent.WorkshopRatingSafety].resourceValue)) as int
	updateData.totalHappiness = 0.0	; sum of all happiness of each actor in town

	;WorkshopParent.wsTrace(self + "       total population=" + updateData.totalPopulation)

	; REAL UPDATE ONLY
	if bRealUpdate
		DailyUpdateAttractNewSettlers(ratings, updateData)
	EndIf

	;WorkshopParent.wsTrace(self + "		happiness: " + updateData.currentHappiness + ", productivity mult=" + updateData.productivity + ", damage mult=" + updateData.damageMult)

	; if this is current workshop, update actors (in case some have been wounded since last update)
	;UFO4P 2.0.2 Bug #23016: Also check whether the location is still loaded (otherwise, the WorkshopActors array will be empty):
	if GetWorkshopID() == WorkshopParent.WorkshopCurrentWorkshopID.GetValue() && WorkshopParent.UFO4P_IsWorkshopLoaded (self)
		WorkshopParent.wsTrace(self + "		Current workshop - update actors' work objects")

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
	if updateData.totalPopulation >= WorkshopParent.TradeCaravanMinimumPopulation && GetValue(ratings[WorkshopParent.WorkshopRatingCaravan].resourceValue) > 0
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

	WorkshopParent.wsTrace(self + "------------------------------------------------------------------------------ ")
	WorkshopParent.wsTrace(self + "	DAILY UPDATE - DONE - bRealUpdate = " + bRealUpdate, bNormalTraceAlso = true)
	WorkshopParent.wsTrace(self + "------------------------------------------------------------------------------ ")

	; clear update lock
	; bDailyUpdateInProgress = false
	WorkshopParent.DailyUpdateInProgress = false

endFunction


; **********************************************************************************************
; DAILY UPDATE HELPER FUNCTIONS - to reduce memory footprint of DailyUpdate process
; **********************************************************************************************
; TODO WSWF - Integrate with our NPC Manager
function DailyUpdateAttractNewSettlers(WorkshopDataScript:WorkshopRatingKeyword[] ratings, DailyUpdateData updateData)
	; increment last visit counter each day
	DaysSinceLastVisit += 1

	; attract new NPCs
	; if I have a radio station
	int radioRating = GetValue(ratings[WorkshopParent.WorkshopRatingRadio].resourceValue) as int
	if radioRating > 0 && HasKeyword(WorkshopParent.WorkshopType02) == false && updateData.unassignedPopulation < iMaxSurplusNPCs && updateData.totalPopulation < GetMaxWorkshopNPCs()
		;WorkshopParent.wsTrace(self + "       RADIO - unassigned population=" + updateData.unassignedPopulation)
		float attractChance = attractNPCDailyChance + updateData.currentHappiness/100 * attractNPCHappinessMult
		if updateData.totalPopulation < iMaxBonusAttractChancePopulation
			attractChance += (iMaxBonusAttractChancePopulation - updateData.totalPopulation) * attractNPCDailyChance
		endif
		; roll to see if a new NPC arrives
		float dieRoll = utility.RandomFloat()
		;WorkshopParent.wsTrace(self + "			dieRoll=" + dieRoll + ", attract NPC chance=" + attractChance)

		if dieRoll <= attractChance
			;WorkshopNPCScript newWorkshopActor = WorkshopParent.CreateActor(self)
			
			;UFO4P 1.0.5 Bug #21002 (Regression of UFO4P 1.0.3 Bug #20581): Since all edits from UFO4P 1.0.3 to the CreateActor PUBLIC function on WorkshopParent
			;Script had to be removed (see general notes around line 280 for more information), there still remained the problem of this function calling a non-
			;public function on WorkshopParentScript (i.e. bug #20581 still required an appropriate solution). Therefore, the new CreateActor_DailyUpdate function
			;was created on WorkshopParentScript as a safe (public) entry point, to handle calls from this function exclusively:
			WorkshopNPCScript newWorkshopActor = WorkshopParent.CreateActor_DailyUpdate(self)
			updateData.totalPopulation += 1

			if newWorkshopActor.GetValue(WorkshopParent.WorkshopGuardPreference) == 0
				; see if also generate a brahmin
				; for now just roll if no brahmin here yet
				if GetValue(ratings[WorkshopParent.WorkshopRatingBrahmin].resourceValue) == 0.0 && AllowBrahminRecruitment
					int brahminRoll = utility.RandomInt()
					;WorkshopParent.wsTrace(self + "			brahminRoll=" + brahminRoll + ", attract brahmin chance=" + WorkshopParent.recruitmentBrahminChance)
					if brahminRoll <= WorkshopParent.recruitmentBrahminChance
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
	updateData.foodProduction = GetValue(ratings[WorkshopParent.WorkshopRatingFood].resourceValue) as int
	
	; safety check: WSWF - Adding additional needs AV here
	Float fSafetyNeeded = updateData.totalPopulation + GetValue(WSWF_AV_ExtraNeeds_Safety)
	int missingSafety = math.max(0, fSafetyNeeded - updateData.safety) as int
	WorkshopParent.SetResourceData(ratings[WorkshopParent.WorkshopRatingMissingSafety].resourceValue, self, missingSafety)

	; subtract damage from food
	updateData.foodProduction = math.max(0, updateData.foodProduction - (GetValue(WorkshopParent.GetDamageRatingValue(ratings[WorkshopParent.WorkshopRatingFood].resourceValue)) as int)) as int
	
	; each brahmin can assist with 10 food production
	if updateData.brahminPopulation > 0
		int brahminMaxFoodBoost = math.min(updateData.brahminPopulation * maxProductionPerBrahmin, updateData.foodProduction) as int
		int brahminFoodProduction = math.Ceiling(brahminMaxFoodBoost * brahminProductionBoost)
		updateData.foodProduction = updateData.foodProduction + brahminFoodProduction
	endif
	
	WorkshopParent.SetResourceData(ratings[WorkshopParent.WorkshopRatingFoodActual].resourceValue, self, updateData.foodProduction)
		
	; reduce safety by current damage (food and water already got that treatment in the Production phase)
	updateData.safety = math.Max(updateData.safety -  updateData.safetyDamage, 0) as int
	updateData.safetyPerNPC = 0
	if updateData.totalPopulation > 0
		updateData.safetyperNPC = math.ceiling(updateData.safety/updateData.totalPopulation)
	endif

	updateData.availableFood = containerRef.GetItemCount(WorkshopParent.WorkshopConsumeFood)
	updateData.availableWater = containerRef.GetItemCount(WorkshopParent.WorkshopConsumeWater)

	; get local food and water totals (including current production)
	updateData.availableFood = containerRef.GetItemCount(WorkshopParent.WorkshopConsumeFood) + updateData.foodProduction
	updateData.availableWater = containerRef.GetItemCount(WorkshopParent.WorkshopConsumeWater) + updateData.waterProduction

	; how much food & water is needed? (robots don't need either) ; WSWF - Added extra food and water needs
	int neededFood = (Self.GetValue(WSWF_AV_ExtraNeeds_Food) as Int) + updateData.totalPopulation - updateData.robotPopulation - updateData.availableFood 
	int neededWater = (Self.GetValue(WSWF_AV_ExtraNeeds_Water) as Int) + updateData.totalPopulation - updateData.robotPopulation - updateData.availableWater

	; add in food and water from linked workshops if needed
	if neededFood > 0 || neededWater > 0
		WorkshopParent.TransferResourcesFromLinkedWorkshops(self, neededFood, neededWater)
		
		; WSWF - Moved these secondary GetItemCount calls inside the if, as they aren't always needed
		; now, get again (now including any transfers from linked workshops)
		updateData.availableFood = containerRef.GetItemCount(WorkshopParent.WorkshopConsumeFood) + updateData.foodProduction
		updateData.availableWater = containerRef.GetItemCount(WorkshopParent.WorkshopConsumeWater) + updateData.waterProduction
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
		
		;WorkshopParent.wsTrace(self + "Pass " + i + ": Actor happiness = " + CorrectedActorHappiness + "; Actor count = " + ActorCount)
		;WorkshopParent.wsTrace(self + "Pass " + i + ": Total happiness = " + updateData.totalHappiness)

		i += 1

	EndWhile

	updateData.totalHappiness = updateData.totalHappiness + ( 50 * updateData.robotPopulation)
	
	int missingBeds = Math.Max (0, Actors_Human - updateData.availableBeds) As Int
	WorkshopParent.SetResourceData(ratings[WorkshopParent.WorkshopRatingMissingBeds].resourceValue, self, missingBeds)
	
	;/ WSWF - Actual Food/Water consumption is now handled by our WorkshopResourceManager script
		; Removed bRealUpdate consumption code
	/;

	; add "bonus happiness" and any happiness modifiers
	updateData.totalHappiness = updateData.totalHappiness + updateData.bonusHappiness

	; calculate happiness
	WorkshopParent.wsTrace(self + "	CalculateHappiness: totalHappiness=" + updateData.totalHappiness + ", totalActors=" + updateData.totalPopulation + ", happiness modifier=" + updateData.happinessModifier)
	; add happiness modifier here - it isn't dependent on population
	updateData.totalHappiness = math.max(updateData.totalHappiness/updateData.totalPopulation + updateData.happinessModifier, 0)
	; don't let happiness exceed 100
	updateData.totalHappiness = math.min(updateData.totalHappiness, 100)

	WorkshopParent.wsTrace(self + "	CalculateHappiness: Happiness Target=" + updateData.totalHappiness)
	; for now, record this as a rating
	WorkshopParent.SetResourceData(ratings[WorkshopParent.WorkshopRatingHappinessTarget].resourceValue, self, updateData.totalHappiness)

	; REAL UPDATE ONLY:
	if bRealUpdate
		float deltaHappinessFloat = (updateData.totalHappiness - updateData.currentHappiness) * happinessChangeMult
	;	WorkshopParent.wsTrace(self + "	CalculateHappiness: delta happiness (float)=" + deltaHappinessFloat)

		int deltaHappiness
		if deltaHappinessFloat < 0
			deltaHappiness = math.floor(deltaHappinessFloat)	; how much does happiness want to change?
		else
			deltaHappiness = math.ceiling(deltaHappinessFloat)	; how much does happiness want to change?
		endif

	;	WorkshopParent.wsTrace(self + "	CalculateHappiness: delta happiness (int)=" + deltaHappiness)
		if deltaHappiness != 0 && math.abs(deltaHappiness) < minHappinessChangePerUpdate
			; increase delta to the min
			deltaHappiness = minHappinessChangePerUpdate * (deltaHappiness/math.abs(deltaHappiness)) as int
		endif
		WorkshopParent.wsTrace(self + "	CalculateHappiness: happiness change=" + deltaHappiness)

		; update happiness rating on workshop's location
		WorkshopParent.ModifyResourceData(ratings[WorkshopParent.WorkshopRatingHappiness].resourceValue, self, deltaHappiness)

		; what is happiness now?
		float finalHappiness = GetValue(ratings[WorkshopParent.WorkshopRatingHappiness].resourceValue)
		WorkshopParent.wsTrace(self + "	CalculateHappiness: final happiness=" + finalHappiness)

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
			WorkshopParent.wsTrace(self + "	CalculateHappiness: modifierSign=" + modifierSign)
			int deltaHappinessModifier
			float deltaHappinessModifierFloat = math.abs(updateData.happinessModifier) * modifierSign * happinessChangeMult
			WorkshopParent.wsTrace(self + "	CalculateHappiness: deltaHappinessModifierFloat=" + deltaHappinessModifierFloat)
			if deltaHappinessModifierFloat > 0
				deltaHappinessModifier = math.floor(deltaHappinessModifierFloat)	; how much does happiness modifier want to change?
			else
				deltaHappinessModifier = math.ceiling(deltaHappinessModifierFloat)	; how much does happiness modifier want to change?
			EndIf
			WorkshopParent.wsTrace(self + "	CalculateHappiness: deltaHappinessModifier=" + deltaHappinessModifier)

			if math.abs(deltaHappinessModifier) < happinessBonusChangePerUpdate
				deltaHappinessModifier = (modifierSign * happinessBonusChangePerUpdate) as int
			endif

			WorkshopParent.wsTrace(self + "	CalculateHappiness: FINAL deltaHappinessModifier=" + deltaHappinessModifier)
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
	
	
	WorkshopParent.wsTrace(self + "------------------------------------------------------------------------------ ")
	WorkshopParent.wsTrace(self + "	Add surplus to workshop container: ")
	WorkshopParent.wsTrace(self + "------------------------------------------------------------------------------ ")
	; add surplus (if any) to container
	; check for max stored resources
	int currentStoredFood = containerRef.GetItemCount(WorkshopParent.WorkshopConsumeFood)
	int currentStoredWater = containerRef.GetItemCount(WorkshopParent.WorkshopConsumeWater)
	int currentStoredScavenge = containerRef.GetItemCount(WorkshopParent.WorkshopConsumeScavenge)
	int currentStoredFertilizer = containerRef.GetItemCount(WorkshopParent.WorkshopProduceFertilizer)

	WorkshopParent.wsTrace(self + "		Check stored resources: food=" + currentStoredFood + ", water=" + currentStoredWater + ", scavenge=" + currentStoredScavenge)

	bool bAllowFoodProduction = true
	if currentStoredFood > maxStoredFoodBase + maxStoredFoodPerPopulation * updateData.totalPopulation
		bAllowFoodProduction = false
	endif

	bool bAllowWaterProduction = true
	if currentStoredWater > maxStoredWaterBase + math.floor(maxStoredWaterPerPopulation * updateData.totalPopulation)
		bAllowWaterProduction = false
	endif

	bool bAllowScavengeProduction = true
	if currentStoredScavenge > maxStoredScavengeBase + maxStoredScavengePerPopulation * updateData.totalPopulation
		bAllowScavengeProduction = false
	endif
	
	bool bAllowFertilizerProduction = true
	if currentStoredFertilizer > maxStoredFertilizerBase
		bAllowFertilizerProduction = false
	endif

	maxBrahminFertilizerProduction

	WorkshopParent.wsTrace(self + "		Allow production? food: " + bAllowFoodProduction + ", water: " + bAllowWaterProduction + ", scavenge: " + bAllowScavengeProduction)
	; add to workshop container
	if updateData.foodProduction > 0 && bAllowFoodProduction
		; MOVED FROM PRODUCTION SECTION:
		; - previously, multiplied all food production by productivity
		; - but, it was confusing if base food rating was higher than population but still red
		; - NOW: consume first, then multiply the surplus by productivity
		; food rating is multiplied by productivity 
		updateData.foodProduction = math.Floor(updateData.foodProduction * updateData.productivity)
		WorkshopParent.wsTrace(self + "		FOOD SURPLUS: +" + updateData.foodProduction)
		if updateData.foodProduction > 0
			WorkshopParent.ProduceFood(self, updateData.foodProduction)
		endif
	endif
	if updateData.waterProduction > 0 && bAllowWaterProduction
		WorkshopParent.wsTrace(self + "		WATER SURPLUS: +" + updateData.waterProduction)
		containerRef.AddItem(WorkshopParent.WorkshopProduceWater, updateData.waterProduction)
	endif
	if updateData.brahminPopulation > 0 && bAllowFertilizerProduction
		int fertilizerProduction = Math.Min(updateData.brahminPopulation, maxBrahminFertilizerProduction) as int
		WorkshopParent.wsTrace(self + "		FERTILIZER PRODUCTION: +" + fertilizerProduction)
		containerRef.AddItem(WorkshopParent.WorkshopProduceFertilizer, fertilizerProduction)
	endif

	; scavenging by unassigned population, minus wounded population (not quite accurate but good enough)
	int scavengePopulation = (updateData.unassignedPopulation - GetValue(ratings[WorkshopParent.WorkshopRatingDamagePopulation].resourceValue)) as int

	; add in general scavenging rating
	int scavengeProductionGeneral = GetValue(ratings[WorkshopParent.WorkshopRatingScavengeGeneral].resourceValue) as int

	; scavenging is multiplied by productivity (happiness) and damage (wounded people)
	int scavengeAmount = math.Ceiling(scavengePopulation * updateData.productivity * updateData.damageMult + scavengeProductionGeneral*updateData.productivity)
	WorkshopParent.wsTrace(self + "		scavenge population: " + scavengePopulation + " unassigned, " + scavengeProductionGeneral + " dedicated scavengers")
	if scavengeAmount > 0 && bAllowScavengeProduction
		WorkshopParent.wsTrace(self + "		SCAVENGING: +" + scavengeAmount)
		containerRef.AddItem(WorkshopParent.WorkshopProduceScavenge, scavengeAmount)
	endif


	if updateData.vendorIncome > 0
		WorkshopParent.wsTrace(self + "------------------------------------------------------------------------------ ")
		WorkshopParent.wsTrace(self + "	Vendor income: ")
		WorkshopParent.wsTrace(self + "------------------------------------------------------------------------------ ")
		WorkshopParent.wsTrace(self + "		Productivity mult: +" + updateData.productivity, bNormalTraceAlso = showVendorTraces)

		int vendorIncomeFinal = 0

		; get linked population with productivity excluded
		float linkedPopulation = WorkshopParent.GetLinkedPopulation(self, false)
		WorkshopParent.wsTrace(self + "		Linked population: +" + linkedPopulation, bNormalTraceAlso = showVendorTraces)
		float vendorPopulation = linkedPopulation + updateData.totalPopulation
		WorkshopParent.wsTrace(self + "		Total population: +" + vendorPopulation, bNormalTraceAlso = showVendorTraces)
		; only get income if population >= minimum
		if vendorPopulation >= minVendorIncomePopulation
			; get productivity-adjusted linked population
			linkedPopulation = WorkshopParent.GetLinkedPopulation(self, true)

			WorkshopParent.wsTrace(self + "		Linked population (productivity adjusted): +" + linkedPopulation, bNormalTraceAlso = showVendorTraces)

			; our population also gets productivity factor
			vendorPopulation = updateData.totalPopulation * updateData.productivity + linkedPopulation
			WorkshopParent.wsTrace(self + "		Total vendor population: " + vendorPopulation, bNormalTraceAlso = showVendorTraces)
			WorkshopParent.wsTrace(self + "		Base income: +" + updateData.vendorIncome, bNormalTraceAlso = showVendorTraces)
			float incomeBonus = updateData.vendorIncome * vendorIncomePopulationMult * vendorPopulation
			WorkshopParent.wsTrace(self + "		Population bonus: +" + incomeBonus, bNormalTraceAlso = showVendorTraces)
			updateData.vendorIncome = updateData.vendorIncome + incomeBonus
			; vendor income is multiplied by productivity (happiness)
			vendorIncomeFinal = math.Ceiling(updateData.vendorIncome)
			; don't go above max allowed
			vendorIncomeFinal = math.Min(vendorIncomeFinal, maxVendorIncome) as int
			; add to workshop container
			if vendorIncomeFinal >= 1.0
				containerRef.AddItem(WorkshopParent.WorkshopProduceVendorIncome, vendorIncomeFinal)
			endif	
		endif
		WorkshopParent.wsTrace(self + "		VENDOR INCOME: " + vendorIncomeFinal, bNormalTraceAlso = showVendorTraces)
	EndIf

endFunction
; ***********************************************
; END DAILY UPDATE HELPER FUNCTIONS
; ***********************************************



; TEMP:
bool showVendorTraces = true

function RepairDamage()
	WorkshopParent.wsTrace("	Repair damage: " + self)
	; create local pointer to WorkshopRatings array to speed things up
	WorkshopDataScript:WorkshopRatingKeyword[] ratings = WorkshopParent.WorkshopRatings

	; repair damage to each resource
	RepairDamageToResource(ratings[WorkshopParent.WorkshopRatingFood].resourceValue)
	RepairDamageToResource(ratings[WorkshopParent.WorkshopRatingWater].resourceValue)
	RepairDamageToResource(ratings[WorkshopParent.WorkshopRatingSafety].resourceValue)
	RepairDamageToResource(ratings[WorkshopParent.WorkshopRatingPower].resourceValue)
	RepairDamageToResource(ratings[WorkshopParent.WorkshopRatingPopulation].resourceValue)

	; repair damage (this is an overall rating that won't exactly match each resource rating)
	float currentDamage = GetValue(ratings[WorkshopParent.WorkshopRatingDamageCurrent].resourceValue)
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

	bool bPopulationDamage = ( damageRating == ratings[WorkshopParent.WorkshopRatingDamagePopulation].resourceValue )

	; get current damage - population is a special case
	float currentDamage
	if bPopulationDamage
		currentDamage = WorkshopParent.GetPopulationDamage(self)
	else
		currentDamage = GetValue(damageRating)
	endif

	WorkshopParent.wsTrace(self + "   RepairDamageToResource: damageRating=" + damageRating + " bPopulationDamage=" + bPopulationDamage)


	int currentWorkshopID = WorkshopParent.WorkshopCurrentWorkshopID.GetValueInt()

	;UFO4P 2.0.2 Bug #23016: Added the following lines:
	;If currentWorkshopID is this workshop's ID, make sure that the workshop location is loaded. Otherwise, there actually is no current workshop, so
	;the related properties on WorkshopParentScript have to be reset (and currentWorkshopID set to -1). This will skip some of the subsequent operations
	;that are unsafe to be carried out if the workshop location is not loaded.
	if currentWorkshopID == workshopID && WorkshopParent.UFO4P_IsWorkshopLoaded (self) == false
		currentWorkshopID = -1
	endif

	if currentDamage > 0
		; amount repaired
		WorkshopParent.wsTrace(self + "   RepairDamageToResource: " + currentDamage + " for " + " resourceValue=" + resourceValue)

		
		; scale this by population (uninjured) - unless this is population
		float repairAmount = 1
		bool bHealedActor = false 	; set to true if we find an actor to heal
		if damageRating != ratings[WorkshopParent.WorkshopRatingDamagePopulation].resourceValue
			repairAmount = CalculateRepairAmount(ratings)
			repairAmount = math.Max(repairAmount, 1.0)
			WorkshopParent.wstrace("		repair amount=" + repairAmount)
		else
			; if this is population, try to heal an actor:
			; are any of this workshop's NPC assigned to caravans?
			Location[] linkedLocations = myLocation.GetAllLinkedLocations(WorkshopParent.WorkshopCaravanKeyword)
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
				if workshopID == currentWorkshopID
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
			WorkshopParent.ModifyResourceData(damageRating, self, repairAmount*-1.0)
			WorkshopParent.wsTrace("		workshopID=" + workshopID + ", currentWorkshopID=" + currentWorkshopID)
			; if this is the current workshop, find an object to repair (otherwise we don't have them)
			if workshopID == currentWorkshopID && damageRating != ratings[WorkshopParent.WorkshopRatingDamagePopulation].resourceValue
				WorkshopParent.wsTrace("		Current workshop - find item(s) to repair " + repairAmount + " damage...")
				int i = 0
				; want only damaged objects that produce this resource
				ObjectReference[] ResourceObjects = GetWorkshopResourceObjects(akAV = resourceValue, aiOption = 1)
				while i < ResourceObjects.Length && repairAmount > 0
					WorkShopObjectScript theObject = ResourceObjects[i] as WorkShopObjectScript
					float damage = theObject.GetResourceDamage(resourceValue)
					WorkshopParent.wstrace("		" + theObject + "=" + damage + " damage")
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
	float uninjuredPopulation = GetValue(ratings[WorkshopParent.WorkshopRatingPopulation].resourceValue)
	float productivityMult = GetProductivityMultiplier(ratings)
	float amountRepaired = math.Ceiling(uninjuredPopulation * damageDailyPopulationMult * damageDailyRepairBase * productivityMult)
	;WorkshopParent.wstrace("		CalculateRepairAmount " + self + ": uninjured population=" + uninjuredPopulation + ", productivityMult=" + productivityMult + ":  amount repaired=" + amountRepaired)
	return amountRepaired
endFunction

function CheckForAttack(bool bForceAttack = false)
	; bForceAttack = true  - don't roll, automatically trigger attack

	WorkshopParent.wsTrace("------------------------------------------------------------------------------ ")
	WorkshopParent.wsTrace("	Check for attack: " + self)
	WorkshopParent.wsTrace("------------------------------------------------------------------------------ ")

	; create local pointer to WorkshopRatings array to speed things up
	WorkshopDataScript:WorkshopRatingKeyword[] ratings = WorkshopParent.WorkshopRatings

	; PREVIOUS ATTACKS:
	; increment days since last attack
	WorkshopParent.ModifyResourceData(ratings[WorkshopParent.WorkshopRatingLastAttackDaysSince].resourceValue, self, 1.0)

	; attacks allowed at all?
	if AllowAttacks == false
		WorkshopParent.wsTrace("		attacks not allowed - no attack roll for " + self)
		return
	EndIf

	; don't attack unowned workshop if flag unless allowed
	if AllowAttacksBeforeOwned == false && OwnedByPlayer == false && bForceAttack == false
		WorkshopParent.wsTrace("		attacks on unowned workshop not allowed - no attack roll for " + self)
		return
	endif

	; NEW ATTACK:
	ObjectReference containerRef = GetContainer()
	if !containerRef
		WorkshopParent.wsTrace(self + " ERROR - no container linked to workshop " + self + " with " + WorkshopParent.WorkshopLinkContainer, 2)
		return
	endif

	int totalPopulation = GetBaseValue(ratings[WorkshopParent.WorkshopRatingPopulation].resourceValue) as int
	int safety = GetValue(ratings[WorkshopParent.WorkshopRatingSafety].resourceValue) as int
	int safetyPerNPC = 0
	if totalPopulation > 0
		safetyperNPC = math.ceiling(safety/totalPopulation)
	elseif bForceAttack
		safetyperNPC = safety
	else
		; no population - no attack
		WorkshopParent.wsTrace("		0 population - no attack roll")
		return
	endif

	int daysSinceLastAttack = GetValue(ratings[WorkshopParent.WorkshopRatingLastAttackDaysSince].resourceValue) as int
	if minDaysSinceLastAttack > daysSinceLastAttack && !bForceAttack
		; attack happened recently - no new attack
		WorkshopParent.wsTrace("		" + daysSinceLastAttack + " days since last attack - no attack roll")
		return
	endif

	int foodRating = GetTotalFoodRating(ratings)
	int waterRating = GetTotalWaterRating(ratings)

	WorkshopParent.wsTrace("	Starting stats:")
	WorkshopParent.wsTrace("		population=" + totalPopulation)
	WorkshopParent.wsTrace("		food rating=" + foodRating)
	WorkshopParent.wsTrace("		water rating=" + waterRating)
	WorkshopParent.wsTrace("		total safety=" + safety)
	WorkshopParent.wsTrace("		safety per NPC=" + safetyPerNPC)

	; chance of attack:
	; 	base chance + (food/water rating) - safety - total population
	WorkshopParent.wsTrace("	Attack chance:")
	WorkshopParent.wsTrace("		base chance=" + attackChanceBase)
	WorkshopParent.wsTrace("		resources=+" + attackChanceResourceMult * (foodRating + waterRating))
	WorkshopParent.wsTrace("		safety=-" + attackChanceSafetyMult*safety)
	WorkshopParent.wsTrace("		population=-" + attackChancePopulationMult * totalPopulation)

	float attackChance = attackChanceBase + attackChanceResourceMult * (foodRating + waterRating) - attackChanceSafetyMult*safety - attackChancePopulationMult * totalPopulation
	if attackChance < attackChanceBase
		attackChance = attackChanceBase
	endif
	WorkshopParent.wsTrace("		TOTAL=" + attackChance)

	float attackRoll = Utility.RandomFloat()
	WorkshopParent.wsTrace("	Attack roll = " + attackRoll)
	if attackRoll <= attackChance || bForceAttack
		int attackStrength = WorkshopParent.CalculateAttackStrength(foodRating, waterRating)
		WorkshopParent.TriggerAttack(self, attackStrength)
	endif
endFunction

; helper function to calculate total food = food production + inventory
int function GetTotalFoodRating(WorkshopDataScript:WorkshopRatingKeyword[] ratings)
	int foodRating = GetValue(ratings[WorkshopParent.WorkshopRatingFood].resourceValue) as int
	foodRating = foodRating + GetContainer().GetItemCount(WorkshopParent.WorkshopConsumeFood)
	;WorkshopParent.wstrace(self + " GetTotalFoodRating=" + foodRating)
	return foodRating
endFunction

; helper function to calculate total water = water production + inventory
int function GetTotalWaterRating(WorkshopDataScript:WorkshopRatingKeyword[] ratings)
	int waterRating = GetValue(ratings[WorkshopParent.WorkshopRatingWater].resourceValue) as int
	waterRating = waterRating + GetContainer().GetItemCount(WorkshopParent.WorkshopConsumeWater)
	;WorkshopParent.wstrace(self + " GetTotalWaterRating=" + waterRating)
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
	float currentHappiness = GetValue(ratings[WorkshopParent.WorkshopRatingHappiness].resourceValue)
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
	
		;WorkshopParent.wstrace(self + " RecalculateWorkshopResources=TRUE")
		RecalculateResources()
		return true
	else
		;WorkshopParent.wstrace(self + " RecalculateWorkshopResources=FALSE")
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
	ObjectReference[] Beds = WorkshopParent.GetBeds(self)
	WorkshopParent.wsTrace(self + "	UFO4P_ClearFactionOwnershipOnBeds: Processing beds ...")
	int bedCount = Beds.Length
	int i = 0
	while i < bedCount
		WorkshopObjectScript theBed = Beds[i] as WorkshopObjectScript
		if theBed && theBed.GetFactionOwner() != none
			theBed.SetFactionOwner(none)
			WorkshopParent.wsTrace(self + "	     Cleared faction ownership from bed " + theBed)
		endif
		i += 1
	endWhile
	UFO4P_CheckFactionOwnershipClearedOnBeds = false
	WorkshopParent.wsTrace(self + "	UFO4P_ClearFactionOwnershipOnBeds: DONE")
endFunction
