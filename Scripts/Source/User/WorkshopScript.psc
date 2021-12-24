Scriptname WorkshopScript extends ObjectReference Conditional
{script for Workshop reference}

; WSFW
import WorkshopFramework:Library:UtilityFunctions
import WorkshopFramework:Library:DataStructures ; WSFW - 1.0.8
String sWSFW_Plugin = "WorkshopFramework.esm" Const ; WSFW - 1.0.3
String sFO4_Plugin = "Fallout4.esm" Const ; WSFW - 1.0.3

;import WorkShopObjectScript
;import WorkshopParentScript

WorkshopParentScript Property WorkshopParent Auto Const mandatory
{ parent quest - holds most general workshop properties }

Location Property myLocation Auto Hidden
{workshop's location (filled onInit)
 this is a property so the WorkshopParent script can access it}

ObjectReference Property myMapMarker auto
{ workshop's map marker (filled by WorkshopParent.InitializeLocation) - or you can fill it manually here }

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
	
	; WSFW - 2.0.0
	ObjectReference[] Property kCustomVendorContainersL0 Auto Hidden
	ObjectReference[] Property kCustomVendorContainersL1 Auto Hidden
	ObjectReference[] Property kCustomVendorContainersL2 Auto Hidden
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
; WSFW - New Properties
; -------------------------------

Group WSFW_Globals
	GlobalVariable Property WSFW_Setting_minProductivity Auto Hidden
	GlobalVariable Property WSFW_Setting_productivityHappinessMult  Auto Hidden
	GlobalVariable Property WSFW_Setting_maxHappinessNoFood  Auto Hidden
	GlobalVariable Property WSFW_Setting_maxHappinessNoWater  Auto Hidden
	GlobalVariable Property WSFW_Setting_maxHappinessNoShelter  Auto Hidden
	GlobalVariable Property WSFW_Setting_happinessBonusFood  Auto Hidden
	GlobalVariable Property WSFW_Setting_happinessBonusWater  Auto Hidden
	GlobalVariable Property WSFW_Setting_happinessBonusBed Auto Hidden
	GlobalVariable Property WSFW_Setting_happinessBonusShelter Auto Hidden
	GlobalVariable Property WSFW_Setting_happinessBonusSafety Auto Hidden
	GlobalVariable Property WSFW_Setting_minHappinessChangePerUpdate Auto Hidden
	GlobalVariable Property WSFW_Setting_happinessChangeMult Auto Hidden
	GlobalVariable Property WSFW_Setting_minHappinessThreshold Auto Hidden
	GlobalVariable Property WSFW_Setting_minHappinessWarningThreshold Auto Hidden
	GlobalVariable Property WSFW_Setting_minHappinessClearWarningThreshold Auto Hidden
	GlobalVariable Property WSFW_Setting_happinessBonusChangePerUpdate Auto Hidden
	GlobalVariable Property WSFW_Setting_maxStoredFoodBase Auto Hidden
	GlobalVariable Property WSFW_Setting_maxStoredFoodPerPopulation Auto Hidden
	GlobalVariable Property WSFW_Setting_maxStoredWaterBase Auto Hidden
	GlobalVariable Property WSFW_Setting_maxStoredWaterPerPopulation Auto Hidden
	GlobalVariable Property WSFW_Setting_maxStoredScavengeBase Auto Hidden
	GlobalVariable Property WSFW_Setting_maxStoredScavengePerPopulation Auto Hidden
	GlobalVariable Property WSFW_Setting_brahminProductionBoost Auto Hidden
	GlobalVariable Property WSFW_Setting_maxProductionPerBrahmin Auto Hidden
	GlobalVariable Property WSFW_Setting_maxBrahminFertilizerProduction Auto Hidden
	GlobalVariable Property WSFW_Setting_maxStoredFertilizerBase Auto Hidden
	GlobalVariable Property WSFW_Setting_minVendorIncomePopulation Auto Hidden
	GlobalVariable Property WSFW_Setting_maxVendorIncome Auto Hidden
	GlobalVariable Property WSFW_Setting_vendorIncomePopulationMult Auto Hidden
	GlobalVariable Property WSFW_Setting_vendorIncomeBaseMult Auto Hidden
	GlobalVariable Property WSFW_Setting_iMaxSurplusNPCs Auto Hidden
	GlobalVariable Property WSFW_Setting_attractNPCDailyChance Auto Hidden
	GlobalVariable Property WSFW_Setting_iMaxBonusAttractChancePopulation Auto Hidden
	GlobalVariable Property WSFW_Setting_iBaseMaxNPCs Auto Hidden
	GlobalVariable Property WSFW_Setting_attractNPCHappinessMult Auto Hidden
	GlobalVariable Property WSFW_Setting_attackChanceBase Auto Hidden
	GlobalVariable Property WSFW_Setting_attackChanceResourceMult Auto Hidden
	GlobalVariable Property WSFW_Setting_attackChanceSafetyMult Auto Hidden
	GlobalVariable Property WSFW_Setting_attackChancePopulationMult Auto Hidden
	GlobalVariable Property WSFW_Setting_minDaysSinceLastAttack Auto Hidden
	GlobalVariable Property WSFW_Setting_damageDailyRepairBase Auto Hidden
	GlobalVariable Property WSFW_Setting_damageDailyPopulationMult Auto Hidden
	
	GlobalVariable Property WSFW_Setting_iBaseMaxBrahmin Auto Hidden	
	GlobalVariable Property WSFW_Setting_iBaseMaxSynths Auto Hidden	
	
	GlobalVariable Property WSFW_Setting_recruitmentGuardChance Auto Hidden	
	GlobalVariable Property WSFW_Setting_recruitmentBrahminChance Auto Hidden	
	GlobalVariable Property WSFW_Setting_recruitmentSynthChance Auto Hidden	
	GlobalVariable Property WSFW_Setting_actorDeathHappinessModifier Auto Hidden	
	GlobalVariable Property WSFW_Setting_maxAttackStrength Auto Hidden	
	GlobalVariable Property WSFW_Setting_maxDefenseStrength Auto Hidden	
	
	GlobalVariable Property WSFW_Setting_AdjustMaxNPCsByCharisma Auto Hidden
	GlobalVariable Property WSFW_Setting_CapMaxNPCsByBedCount Auto Hidden
	GlobalVariable Property WSFW_Setting_RobotHappinessLevel Auto Hidden
	GlobalVariable Property CurrentWorkshopID Auto Hidden
	
	; 1.0.4 - Give players means to turn the happiness loss of control feature off
	GlobalVariable Property WSFW_Setting_AllowSettlementsToLeavePlayerControl Auto Hidden
	
	; 1.0.5 - Give player means to disable shelter mechanic
	GlobalVariable Property WSFW_Setting_ShelterMechanic Auto Hidden
EndGroup

Group WSFW_AVs
	ActorValue Property WSFW_AV_minProductivity Auto Hidden
	ActorValue Property WSFW_AV_productivityHappinessMult  Auto Hidden
	ActorValue Property WSFW_AV_maxHappinessNoFood  Auto Hidden
	ActorValue Property WSFW_AV_maxHappinessNoWater  Auto Hidden
	ActorValue Property WSFW_AV_maxHappinessNoShelter  Auto Hidden
	ActorValue Property WSFW_AV_happinessBonusFood  Auto Hidden
	ActorValue Property WSFW_AV_happinessBonusWater  Auto Hidden
	ActorValue Property WSFW_AV_happinessBonusBed Auto Hidden
	ActorValue Property WSFW_AV_happinessBonusShelter Auto Hidden
	ActorValue Property WSFW_AV_happinessBonusSafety Auto Hidden
	ActorValue Property WSFW_AV_minHappinessChangePerUpdate Auto Hidden
	ActorValue Property WSFW_AV_happinessChangeMult Auto Hidden
	ActorValue Property WSFW_AV_happinessBonusChangePerUpdate Auto Hidden
	ActorValue Property WSFW_AV_maxStoredFoodBase Auto Hidden
	ActorValue Property WSFW_AV_maxStoredFoodPerPopulation Auto Hidden
	ActorValue Property WSFW_AV_maxStoredWaterBase Auto Hidden
	ActorValue Property WSFW_AV_maxStoredWaterPerPopulation Auto Hidden
	ActorValue Property WSFW_AV_maxStoredScavengeBase Auto Hidden
	ActorValue Property WSFW_AV_maxStoredScavengePerPopulation Auto Hidden
	ActorValue Property WSFW_AV_brahminProductionBoost Auto Hidden
	ActorValue Property WSFW_AV_maxProductionPerBrahmin Auto Hidden
	ActorValue Property WSFW_AV_maxBrahminFertilizerProduction Auto Hidden
	ActorValue Property WSFW_AV_maxStoredFertilizerBase Auto Hidden
	ActorValue Property WSFW_AV_minVendorIncomePopulation Auto Hidden
	ActorValue Property WSFW_AV_maxVendorIncome Auto Hidden
	ActorValue Property WSFW_AV_vendorIncomePopulationMult Auto Hidden
	ActorValue Property WSFW_AV_vendorIncomeBaseMult Auto Hidden
	ActorValue Property WSFW_AV_iMaxSurplusNPCs Auto Hidden
	ActorValue Property WSFW_AV_attractNPCDailyChance Auto Hidden
	ActorValue Property WSFW_AV_iMaxBonusAttractChancePopulation Auto Hidden
	ActorValue Property WSFW_AV_iBaseMaxNPCs Auto Hidden
	ActorValue Property WSFW_AV_attractNPCHappinessMult Auto Hidden
	ActorValue Property WSFW_AV_attackChanceBase Auto Hidden
	ActorValue Property WSFW_AV_attackChanceResourceMult Auto Hidden
	ActorValue Property WSFW_AV_attackChanceSafetyMult Auto Hidden
	ActorValue Property WSFW_AV_attackChancePopulationMult Auto Hidden
	ActorValue Property WSFW_AV_minDaysSinceLastAttack Auto Hidden
	ActorValue Property WSFW_AV_damageDailyRepairBase Auto Hidden
	ActorValue Property WSFW_AV_damageDailyPopulationMult Auto Hidden
	
	ActorValue Property WSFW_AV_ExtraNeeds_Food Auto Hidden
	ActorValue Property WSFW_AV_ExtraNeeds_Safety Auto Hidden
	ActorValue Property WSFW_AV_ExtraNeeds_Water Auto Hidden
	
	ActorValue Property WSFW_AV_iBaseMaxBrahmin Auto Hidden
	ActorValue Property WSFW_AV_iBaseMaxSynths Auto Hidden	
	ActorValue Property WSFW_AV_recruitmentGuardChance Auto Hidden	
	ActorValue Property WSFW_AV_recruitmentBrahminChance Auto Hidden	
	ActorValue Property WSFW_AV_recruitmentSynthChance Auto Hidden	
	ActorValue Property WSFW_AV_actorDeathHappinessModifier Auto Hidden	
	ActorValue Property WSFW_AV_maxAttackStrength Auto Hidden	
	ActorValue Property WSFW_AV_maxDefenseStrength Auto Hidden	

	ActorValue Property WSFW_AV_RobotHappinessLevel Auto Hidden
	ActorValue Property WSFW_Safety Auto Hidden ; 1.1.7
	ActorValue Property WSFW_PowerRequired Auto Hidden ; WSFW 1.1.8
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
	ActorValue Property MissingFood Auto Hidden
	ActorValue Property Power Auto Hidden
	ActorValue Property PowerRequired Auto Hidden ; WSFW 1.1.8
	ActorValue Property Water Auto Hidden
	ActorValue Property MissingWater Auto Hidden
	ActorValue Property Safety Auto Hidden
	ActorValue Property DamageSafety Auto Hidden
	ActorValue Property MissingSafety Auto Hidden
	ActorValue Property LastAttackDaysSince Auto Hidden
	ActorValue Property WorkshopPlayerLostControl Auto Hidden
	ActorValue Property WorkshopPlayerOwnership Auto Hidden
	ActorValue Property PopulationRobots Auto Hidden
	ActorValue Property PopulationBrahmin Auto Hidden
	ActorValue Property PopulationUnassigned Auto Hidden
	ActorValue Property VendorIncome Auto Hidden
	ActorValue Property DamageCurrent Auto Hidden
	ActorValue Property Beds Auto Hidden
	ActorValue Property MissingBeds Auto Hidden 
	ActorValue Property Caravan Auto Hidden
	ActorValue Property Radio Auto Hidden
	ActorValue Property WorkshopGuardPreference Auto Hidden
	
	ActorValue Property WorkshopHideHappinessBarAV Auto Hidden ; 2.0.18a
EndGroup

Group WSFW_Added
	Keyword Property WorkshopType02 Auto Hidden
	Keyword Property WorkshopCaravanKeyword Auto Hidden
	Keyword Property ObjectTypeWater Auto Hidden
	Keyword Property ObjectTypeFood Auto Hidden
	Keyword Property WorkshopLinkContainer Auto Hidden
	Keyword Property WorkshopCanBePowered Auto Hidden ; WSFW 1.1.8
	Faction Property FarmDiscountFaction Auto Hidden
	Faction Property PlayerFaction Auto Hidden
	{ 1.1.0 }
EndGroup


; Form IDs
	; WorkshopFramework.esm
int iFormID_Setting_minProductivity = 0x0000730E Const
int iFormID_Setting_productivityHappinessMult = 0x0000730F Const
int iFormID_Setting_maxHappinessNoFood = 0x00007310 Const
int iFormID_Setting_maxHappinessNoWater = 0x00007311 Const
int iFormID_Setting_maxHappinessNoShelter = 0x00007312 Const
int iFormID_Setting_happinessBonusFood = 0x00007313 Const
int iFormID_Setting_happinessBonusWater = 0x00007314 Const
int iFormID_Setting_happinessBonusBed = 0x00007315 Const
int iFormID_Setting_happinessBonusShelter = 0x00007316 Const
int iFormID_Setting_happinessBonusSafety = 0x00007317 Const
int iFormID_Setting_minHappinessChangePerUpdate = 0x00007318 Const
int iFormID_Setting_happinessChangeMult = 0x00007319 Const
int iFormID_Setting_minHappinessThreshold = 0x0000731A Const
int iFormID_Setting_minHappinessWarningThreshold = 0x0000731B Const
int iFormID_Setting_minHappinessClearWarningThreshold = 0x0000731C Const
int iFormID_Setting_happinessBonusChangePerUpdate = 0x0000731D Const
int iFormID_Setting_maxStoredFoodBase = 0x0000731E Const
int iFormID_Setting_maxStoredFoodPerPopulation = 0x0000731F Const
int iFormID_Setting_maxStoredWaterBase = 0x00007320 Const
int iFormID_Setting_maxStoredWaterPerPopulation = 0x00007321 Const
int iFormID_Setting_maxStoredScavengeBase = 0x00007322 Const
int iFormID_Setting_maxStoredScavengePerPopulation = 0x00007323 Const
int iFormID_Setting_brahminProductionBoost = 0x00007324 Const
int iFormID_Setting_maxProductionPerBrahmin = 0x00007325 Const
int iFormID_Setting_maxBrahminFertilizerProduction = 0x00007326 Const
int iFormID_Setting_maxStoredFertilizerBase = 0x00007327 Const
int iFormID_Setting_minVendorIncomePopulation = 0x00007328 Const
int iFormID_Setting_maxVendorIncome = 0x00007329 Const
int iFormID_Setting_vendorIncomePopulationMult = 0x0000732A Const
int iFormID_Setting_vendorIncomeBaseMult = 0x0000732B Const
int iFormID_Setting_iMaxSurplusNPCs = 0x0000732C Const
int iFormID_Setting_attractNPCDailyChance = 0x0000732D Const
int iFormID_Setting_iMaxBonusAttractChancePopulation = 0x0000732E Const
int iFormID_Setting_iBaseMaxNPCs = 0x0000732F Const
int iFormID_Setting_attractNPCHappinessMult = 0x00007330 Const
int iFormID_Setting_attackChanceBase = 0x00007331 Const
int iFormID_Setting_attackChanceResourceMult = 0x00007332 Const
int iFormID_Setting_attackChanceSafetyMult = 0x00007333 Const
int iFormID_Setting_attackChancePopulationMult = 0x00007334 Const
int iFormID_Setting_minDaysSinceLastAttack = 0x00007335 Const
int iFormID_Setting_damageDailyRepairBase = 0x00007336 Const
int iFormID_Setting_damageDailyPopulationMult = 0x00007337 Const
int iFormID_Setting_iBaseMaxBrahmin = 0x000091D3 Const
int iFormID_Setting_iBaseMaxSynths = 0x000091D5 Const
int iFormID_Setting_recruitmentGuardChance = 0x000091D7 Const
int iFormID_Setting_recruitmentBrahminChance = 0x000091D8 Const
int iFormID_Setting_recruitmentSynthChance = 0x000091DA Const
int iFormID_Setting_actorDeathHappinessModifier = 0x000091DC Const
int iFormID_Setting_maxAttackStrength = 0x000091DE Const
int iFormID_Setting_maxDefenseStrength = 0x000091E0 Const
int iFormID_Setting_AdjustMaxNPCsByCharisma = 0x0000A98D Const ; 1.0.4 - Fixed typo in form ID
int iFormID_Setting_CapMaxNPCsByBedCount = 0x0002A0F1 Const
int iFormID_Setting_ShelterMechanic = 0x00006B5D ; 1.0.5
int iFormID_Setting_RobotHappinessLevel = 0x000035D8 Const
int iFormID_Setting_AllowSettlementsToLeavePlayerControl = 0x00004CF3 ; 1.0.4 - New setting
int iFormID_ControlManger = 0x0000B137 Const ; 1.1.0
int iFormID_AV_minProductivity = 0x00007338 Const
int iFormID_AV_productivityHappinessMult = 0x00007339 Const
int iFormID_AV_maxHappinessNoFood = 0x0000733A Const
int iFormID_AV_maxHappinessNoWater = 0x0000733B Const
int iFormID_AV_maxHappinessNoShelter = 0x0000733C Const
int iFormID_AV_happinessBonusFood = 0x0000733D Const
int iFormID_AV_happinessBonusWater = 0x0000733E Const
int iFormID_AV_happinessBonusBed = 0x0000733F Const
int iFormID_AV_happinessBonusShelter = 0x00007340 Const
int iFormID_AV_happinessBonusSafety = 0x00007341 Const
int iFormID_AV_minHappinessChangePerUpdate = 0x00007342 Const
int iFormID_AV_happinessChangeMult = 0x00007343 Const
int iFormID_AV_happinessBonusChangePerUpdate = 0x00007347 Const
int iFormID_AV_maxStoredFoodBase = 0x00007348 Const
int iFormID_AV_maxStoredFoodPerPopulation = 0x00007349 Const
int iFormID_AV_maxStoredWaterBase = 0x0000734A Const
int iFormID_AV_maxStoredWaterPerPopulation = 0x0000734B Const
int iFormID_AV_maxStoredScavengeBase = 0x0000734C Const
int iFormID_AV_maxStoredScavengePerPopulation = 0x0000734D Const
int iFormID_AV_brahminProductionBoost = 0x0000734E Const
int iFormID_AV_maxProductionPerBrahmin = 0x0000734F Const
int iFormID_AV_maxBrahminFertilizerProduction = 0x00007350 Const
int iFormID_AV_maxStoredFertilizerBase = 0x00007351 Const
int iFormID_AV_minVendorIncomePopulation = 0x00007352 Const
int iFormID_AV_maxVendorIncome = 0x00007353 Const
int iFormID_AV_vendorIncomePopulationMult = 0x00007354 Const
int iFormID_AV_vendorIncomeBaseMult = 0x00007355 Const
int iFormID_AV_iMaxSurplusNPCs = 0x00007356 Const
int iFormID_AV_attractNPCDailyChance = 0x00007357 Const
int iFormID_AV_iMaxBonusAttractChancePopulation = 0x00007358 Const
int iFormID_AV_iBaseMaxNPCs = 0x00007359 Const
int iFormID_AV_attractNPCHappinessMult = 0x0000735A Const
int iFormID_AV_attackChanceBase = 0x0000735B Const
int iFormID_AV_attackChanceResourceMult = 0x0000735C Const
int iFormID_AV_attackChanceSafetyMult = 0x0000735D Const
int iFormID_AV_attackChancePopulationMult = 0x0000735E Const
int iFormID_AV_minDaysSinceLastAttack = 0x0000735F Const
int iFormID_AV_damageDailyRepairBase = 0x00007360 Const
int iFormID_AV_damageDailyPopulationMult = 0x00007361 Const
int iFormID_AV_ExtraNeeds_Food = 0x000072EF Const
int iFormID_AV_ExtraNeeds_Safety = 0x000072F1 Const
int iFormID_AV_ExtraNeeds_Water = 0x000072F0 Const
int iFormID_AV_iBaseMaxBrahmin = 0x000091D2 Const
int iFormID_AV_iBaseMaxSynths = 0x000091D4 Const
int iFormID_AV_recruitmentGuardChance = 0x000091D6 Const
int iFormID_AV_recruitmentBrahminChance = 0x000091D9 Const
int iFormID_AV_recruitmentSynthChance = 0x000091DB Const
int iFormID_AV_actorDeathHappinessModifier = 0x000091DD Const
int iFormID_AV_maxAttackStrength = 0x000091DF Const
int iFormID_AV_maxDefenseStrength = 0x000091E1 Const
int iFormID_AV_RobotHappinessLevel = 0x000035D9 Const
int iFormID_WSFW_Safety = 0x0000A9C2 Const
int iFormID_WSFW_PowerRequired = 0x0000B15D Const

	; Fallout4.esm
int iFormID_CurrentWorkshopID = 0x0003E0CE Const
int iFormID_Happiness = 0x00129157 Const ; 1.0.4 - Was pointing at the wrong AV 
int iFormID_BonusHappiness = 0x0012722C Const
int iFormID_HappinessTarget = 0x00127238 Const
int iFormID_HappinessModifier = 0x00127237 Const
int iFormID_Population = 0x0012723E Const
int iFormID_DamagePopulation = 0x00127232 Const
int iFormID_Food = 0x00000331 Const
int iFormID_DamageFood = 0x00127230 Const
int iFormID_FoodActual = 0x00127236 Const
int iFormID_MissingFood = 0x0012723C Const
int iFormID_Power = 0x0000032E Const
int iFormID_PowerRequired = 0x00000330 Const
int iFormID_Water = 0x00000332 Const
int iFormID_MissingWater = 0x0012723D Const
int iFormID_Safety = 0x00000333 Const
int iFormID_DamageSafety = 0x00127234 Const
int iFormID_MissingSafety = 0x001E3272 Const
int iFormID_LastAttackDaysSince = 0x00127239 Const
int iFormID_WorkshopPlayerLostControl = 0x0018BCC2 Const
int iFormID_WorkshopPlayerOwnership = 0x0000033C Const
int iFormID_PopulationRobots = 0x0012723F Const
int iFormID_PopulationBrahmin = 0x0012722D Const
int iFormID_PopulationUnassigned = 0x00127240 Const
int iFormID_VendorIncome = 0x0010C847 Const
int iFormID_DamageCurrent = 0x0012722F Const
int iFormID_Beds = 0x00000334 Const
int iFormID_MissingBeds = 0x0012723B Const
int iFormID_Caravan = 0x000A46FD Const
int iFormID_Radio = 0x00127241 Const
int iFormID_WorkshopHideHappinessBarAV = 0x00249E91 Const
int iFormID_WorkshopGuardPreference = 0x00113342 Const
int iFormID_WorkshopType02 = 0x00249FD7 Const
int iFormID_WorkshopCaravanKeyword = 0x00061C0C Const
int iFormID_ObjectTypeWater = 0x000F4AED Const
int iFormID_ObjectTypeFood = 0x00055ECC Const
int iFormID_WorkshopLinkContainer = 0x0002682F Const
int iFormID_WorkshopCanBePowered = 0x0003037E Const
int iFormID_FarmDiscountFaction = 0x0019FFC4 Const
int iFormID_PlayerFaction = 0x0001C21C Const ; 1.1.0

Bool bWSFWVarsFilled = false ; 1.0.3 - this will allow us to update workshops that have already past the init phase when this was installed

;******************
; moved from workshopparent			
; WSFW: Note - This was all added here by BGS to avoid having to constantly query WorkshopParent for the numbers

; productivity formula stuff
Bool Property bUseGlobalminProductivity = true Auto Hidden
Float WSFW_minProductivity = 0.25
float Property minProductivity
	Float Function Get()
		Float AppliedValue = GetValue(WSFW_AV_minProductivity)
		
		if(bUseGlobalminProductivity)
			return AppliedValue + WSFW_Setting_minProductivity.GetValue()
		else
			return AppliedValue + WSFW_minProductivity
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSFW_minProductivity = aValue
	EndFunction
EndProperty

Bool Property bUseGlobalproductivityHappinessMult = true Auto Hidden
Float WSFW_productivityHappinessMult = 0.75
float Property productivityHappinessMult
	Float Function Get()
		Float AppliedValue = GetValue(WSFW_AV_productivityHappinessMult)
		
		if(bUseGlobalproductivityHappinessMult)
			return AppliedValue + WSFW_Setting_productivityHappinessMult.GetValue()
		else
			return AppliedValue + WSFW_productivityHappinessMult
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSFW_productivityHappinessMult = aValue
	EndFunction
EndProperty

; happiness formula stuff
Bool Property bUseGlobalmaxHappinessNoFood = true Auto Hidden
Float WSFW_maxHappinessNoFood = 30.0
float Property maxHappinessNoFood
	Float Function Get()
		Float AppliedValue = GetValue(WSFW_AV_maxHappinessNoFood)
		
		if(bUseGlobalmaxHappinessNoFood)
			return AppliedValue + WSFW_Setting_maxHappinessNoFood.GetValue()
		else
			return AppliedValue + WSFW_maxHappinessNoFood
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSFW_maxHappinessNoFood = aValue
	EndFunction
EndProperty

Bool Property bUseGlobalmaxHappinessNoWater = true Auto Hidden
Float WSFW_maxHappinessNoWater = 30.0
float Property maxHappinessNoWater
	Float Function Get()
		Float AppliedValue = GetValue(WSFW_AV_maxHappinessNoWater)
		
		if(bUseGlobalmaxHappinessNoWater)
			return AppliedValue + WSFW_Setting_maxHappinessNoWater.GetValue()
		else
			return AppliedValue + WSFW_maxHappinessNoWater
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSFW_maxHappinessNoWater = aValue
	EndFunction
EndProperty

Bool Property bUseGlobalmaxHappinessNoShelter = true Auto Hidden
Float WSFW_maxHappinessNoShelter = 60.0
float Property maxHappinessNoShelter
	Float Function Get()
		Float AppliedValue = GetValue(WSFW_AV_maxHappinessNoShelter)
		
		if(bUseGlobalmaxHappinessNoShelter)
			return AppliedValue + WSFW_Setting_maxHappinessNoShelter.GetValue()
		else
			return AppliedValue + WSFW_maxHappinessNoShelter
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSFW_maxHappinessNoShelter = aValue
	EndFunction
EndProperty

Bool Property bUseGlobalhappinessBonusFood = true Auto Hidden
Float WSFW_happinessBonusFood = 20.0
float Property happinessBonusFood
	Float Function Get()
		Float AppliedValue = GetValue(WSFW_AV_happinessBonusFood)
		
		if(bUseGlobalhappinessBonusFood)
			return AppliedValue + WSFW_Setting_happinessBonusFood.GetValue()
		else
			return AppliedValue + WSFW_happinessBonusFood
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSFW_happinessBonusFood = aValue
	EndFunction
EndProperty

Bool Property bUseGlobalhappinessBonusWater = true Auto Hidden
Float WSFW_happinessBonusWater = 20.0
float Property happinessBonusWater
	Float Function Get()
		Float AppliedValue = GetValue(WSFW_AV_happinessBonusWater)
		
		if(bUseGlobalhappinessBonusWater)
			return AppliedValue + WSFW_Setting_happinessBonusWater.GetValue()
		else
			return AppliedValue + WSFW_happinessBonusWater
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSFW_happinessBonusWater = aValue
	EndFunction
EndProperty

Bool Property bUseGlobalhappinessBonusBed = true Auto Hidden
Float WSFW_happinessBonusBed = 10.0
float Property happinessBonusBed
	Float Function Get()
		Float AppliedValue = GetValue(WSFW_AV_happinessBonusBed)
		
		if(bUseGlobalhappinessBonusBed)
			return AppliedValue + WSFW_Setting_happinessBonusBed.GetValue()
		else
			return AppliedValue + WSFW_happinessBonusBed
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSFW_happinessBonusBed = aValue
	EndFunction
EndProperty

Bool Property bUseGlobalhappinessBonusShelter = true Auto Hidden
Float WSFW_happinessBonusShelter = 10.0
float Property happinessBonusShelter
	Float Function Get()
		Float AppliedValue = GetValue(WSFW_AV_happinessBonusShelter)
		
		if(bUseGlobalhappinessBonusShelter)
			return AppliedValue + WSFW_Setting_happinessBonusShelter.GetValue()
		else
			return AppliedValue + WSFW_happinessBonusShelter
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSFW_happinessBonusShelter = aValue
	EndFunction
EndProperty

Bool Property bUseGlobalhappinessBonusSafety = true Auto Hidden
Float WSFW_happinessBonusSafety = 20.0
float Property happinessBonusSafety
	Float Function Get()
		Float AppliedValue = GetValue(WSFW_AV_happinessBonusSafety)
		
		if(bUseGlobalhappinessBonusSafety)
			return AppliedValue + WSFW_Setting_happinessBonusSafety.GetValue()
		else
			return AppliedValue + WSFW_happinessBonusSafety
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSFW_happinessBonusSafety = aValue
	EndFunction
EndProperty

Bool Property bUseGlobalminHappinessChangePerUpdate = true Auto Hidden
Int WSFW_minHappinessChangePerUpdate = 1 ; what's the min happiness can change in one update?
Int Property minHappinessChangePerUpdate
	Int Function Get()
		Int AppliedValue = Math.Ceiling(GetValue(WSFW_AV_minHappinessChangePerUpdate))
		
		if(bUseGlobalminHappinessChangePerUpdate)
			return AppliedValue + WSFW_Setting_minHappinessChangePerUpdate.GetValueInt()
		else
			return AppliedValue + WSFW_minHappinessChangePerUpdate
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSFW_minHappinessChangePerUpdate = aValue
	EndFunction
EndProperty

Bool Property bUseGlobalhappinessChangeMult = true Auto Hidden
Float WSFW_happinessChangeMult = 0.20 ; multiplier on happiness delta
float Property happinessChangeMult
	Float Function Get()
		Float AppliedValue = GetValue(WSFW_AV_happinessChangeMult)
		
		if(bUseGlobalhappinessChangeMult)
			return AppliedValue + WSFW_Setting_happinessChangeMult.GetValue()
		else
			return AppliedValue + WSFW_happinessChangeMult
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSFW_happinessChangeMult = aValue
	EndFunction
EndProperty		
		
Bool Property bUseGlobalminHappinessThreshold = true Auto Hidden
Int WSFW_minHappinessThreshold = 10 ; if happiness drops <= to this value, player ownership is cleared
Int Property minHappinessThreshold
	Int Function Get()
		if(bUseGlobalminHappinessThreshold)
			return WSFW_Setting_minHappinessThreshold.GetValueInt()
		else
			return WSFW_minHappinessThreshold
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSFW_minHappinessThreshold = aValue
	EndFunction
EndProperty

Bool Property bUseGlobalminHappinessWarningThreshold = true Auto Hidden
Int WSFW_minHappinessWarningThreshold = 15 ; if happiness drops <= to this value, player ownership is cleared
Int Property minHappinessWarningThreshold
	Int Function Get()
		if(bUseGlobalminHappinessWarningThreshold)
			return WSFW_Setting_minHappinessWarningThreshold.GetValueInt()
		else
			return WSFW_minHappinessWarningThreshold
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSFW_minHappinessWarningThreshold = aValue
	EndFunction
EndProperty
				
Bool Property bUseGlobalminHappinessClearWarningThreshold = true Auto Hidden
Int WSFW_minHappinessClearWarningThreshold = 20 ; if happiness >= this value, clear happiness warning
Int Property minHappinessClearWarningThreshold
	Int Function Get()
		if(bUseGlobalminHappinessClearWarningThreshold)
			return WSFW_Setting_minHappinessClearWarningThreshold.GetValueInt()
		else
			return WSFW_minHappinessClearWarningThreshold
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSFW_minHappinessClearWarningThreshold = aValue
	EndFunction
EndProperty	

Bool Property bUseGlobalhappinessBonusChangePerUpdate = true Auto Hidden
Int WSFW_happinessBonusChangePerUpdate = 2 ; happiness bonus trends back to 0 (from positive or negative)
Int Property happinessBonusChangePerUpdate
	Int Function Get()
		Int AppliedValue = Math.Ceiling(GetValue(WSFW_AV_happinessBonusChangePerUpdate))
		
		if(bUseGlobalhappinessBonusChangePerUpdate)
			return AppliedValue + WSFW_Setting_happinessBonusChangePerUpdate.GetValueInt()
		else
			return AppliedValue + WSFW_happinessBonusChangePerUpdate
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSFW_happinessBonusChangePerUpdate = aValue
	EndFunction
EndProperty
	

; production
Bool Property bUseGlobalmaxStoredFoodBase = true Auto Hidden
Int WSFW_maxStoredFoodBase = 10 ; stop producing when we reach this amount stored
Int Property maxStoredFoodBase
	Int Function Get()
		Int AppliedValue = Math.Ceiling(GetValue(WSFW_AV_maxStoredFoodBase))
		
		if(bUseGlobalmaxStoredFoodBase)
			return AppliedValue + WSFW_Setting_maxStoredFoodBase.GetValueInt()
		else
			return AppliedValue + WSFW_maxStoredFoodBase
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSFW_maxStoredFoodBase = aValue
	EndFunction
EndProperty
				
Bool Property bUseGlobalmaxStoredFoodPerPopulation = true Auto Hidden
Int WSFW_maxStoredFoodPerPopulation = 1 ; increase max for each population
Int Property maxStoredFoodPerPopulation
	Int Function Get()
		Int AppliedValue = Math.Ceiling(GetValue(WSFW_AV_maxStoredFoodPerPopulation))
		
		if(bUseGlobalmaxStoredFoodPerPopulation)
			return AppliedValue + WSFW_Setting_maxStoredFoodPerPopulation.GetValueInt()
		else
			return AppliedValue + WSFW_maxStoredFoodPerPopulation
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSFW_maxStoredFoodPerPopulation = aValue
	EndFunction
EndProperty

Bool Property bUseGlobalmaxStoredWaterBase = true Auto Hidden
Int WSFW_maxStoredWaterBase = 5 ; stop producing when we reach this amount stored
Int Property maxStoredWaterBase
	Int Function Get()
		Int AppliedValue = Math.Ceiling(GetValue(WSFW_AV_maxStoredWaterBase))
		
		if(bUseGlobalmaxStoredWaterBase)
			return AppliedValue + WSFW_Setting_maxStoredWaterBase.GetValueInt()
		else
			return AppliedValue + WSFW_maxStoredWaterBase
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSFW_maxStoredWaterBase = aValue
	EndFunction
EndProperty

Bool Property bUseGlobalmaxStoredWaterPerPopulation = true Auto Hidden
Float WSFW_maxStoredWaterPerPopulation = 0.25 ; increase max for each population
float Property maxStoredWaterPerPopulation
	Float Function Get()
		Float AppliedValue = GetValue(WSFW_AV_maxStoredWaterPerPopulation)
		
		if(bUseGlobalmaxStoredWaterPerPopulation)
			return AppliedValue + WSFW_Setting_maxStoredWaterPerPopulation.GetValue()
		else
			return AppliedValue + WSFW_maxStoredWaterPerPopulation
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSFW_maxStoredWaterPerPopulation = aValue
	EndFunction
EndProperty	
				
Bool Property bUseGlobalmaxStoredScavengeBase = true Auto Hidden
Int WSFW_maxStoredScavengeBase = 100 ; stop producing when we reach this amount stored
Int Property maxStoredScavengeBase
	Int Function Get()
		Int AppliedValue = Math.Ceiling(GetValue(WSFW_AV_maxStoredScavengeBase))
		
		if(bUseGlobalmaxStoredScavengeBase)
			return AppliedValue + WSFW_Setting_maxStoredScavengeBase.GetValueInt()
		else
			return AppliedValue + WSFW_maxStoredScavengeBase
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSFW_maxStoredScavengeBase = aValue
	EndFunction
EndProperty

Bool Property bUseGlobalmaxStoredScavengePerPopulation = true Auto Hidden
Int WSFW_maxStoredScavengePerPopulation = 5 ; increase max for each population
Int Property maxStoredScavengePerPopulation
	Int Function Get()
		Int AppliedValue = Math.Ceiling(GetValue(WSFW_AV_maxStoredScavengePerPopulation))
		
		if(bUseGlobalmaxStoredScavengePerPopulation)
			return AppliedValue + WSFW_Setting_maxStoredScavengePerPopulation.GetValueInt()
		else
			return AppliedValue + WSFW_maxStoredScavengePerPopulation
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSFW_maxStoredScavengePerPopulation = aValue
	EndFunction
EndProperty		
	
Bool Property bUseGlobalbrahminProductionBoost = true Auto Hidden
Float WSFW_brahminProductionBoost = 0.5 ; what percent increase per brahmin
float Property brahminProductionBoost
	Float Function Get()
		Float AppliedValue = GetValue(WSFW_AV_brahminProductionBoost)
		
		if(bUseGlobalbrahminProductionBoost)
			return AppliedValue + WSFW_Setting_brahminProductionBoost.GetValue()
		else
			return AppliedValue + WSFW_brahminProductionBoost
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSFW_brahminProductionBoost = aValue
	EndFunction
EndProperty	

Bool Property bUseGlobalmaxProductionPerBrahmin = true Auto Hidden
Int WSFW_maxProductionPerBrahmin = 10 ; each brahmin can only boost this much food (so max 10 * 0.5 = 5)
Int Property maxProductionPerBrahmin
	Int Function Get()
		Int AppliedValue = Math.Ceiling(GetValue(WSFW_AV_maxProductionPerBrahmin))
		
		if(bUseGlobalmaxProductionPerBrahmin)
			return AppliedValue + WSFW_Setting_maxProductionPerBrahmin.GetValueInt()
		else
			return AppliedValue + WSFW_maxProductionPerBrahmin
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSFW_maxProductionPerBrahmin = aValue
	EndFunction
EndProperty		
				
Bool Property bUseGlobalmaxBrahminFertilizerProduction = true Auto Hidden
Int WSFW_maxBrahminFertilizerProduction = 3 ; max fertilizer production per settlement per day
Int Property maxBrahminFertilizerProduction
	Int Function Get()
		Int AppliedValue = Math.Ceiling(GetValue(WSFW_AV_maxBrahminFertilizerProduction))
		
		if(bUseGlobalmaxBrahminFertilizerProduction)
			return AppliedValue + WSFW_Setting_maxBrahminFertilizerProduction.GetValueInt()
		else
			return AppliedValue + WSFW_maxBrahminFertilizerProduction
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSFW_maxBrahminFertilizerProduction = aValue
	EndFunction
EndProperty					

Bool Property bUseGlobalmaxStoredFertilizerBase = true Auto Hidden
Int WSFW_maxStoredFertilizerBase = 10 ; stop producing when we reach this amount stored
Int Property maxStoredFertilizerBase
	Int Function Get()
		Int AppliedValue = Math.Ceiling(GetValue(WSFW_AV_maxStoredFertilizerBase))
		
		if(bUseGlobalmaxStoredFertilizerBase)
			return AppliedValue + WSFW_Setting_maxStoredFertilizerBase.GetValueInt()
		else
			return AppliedValue + WSFW_maxStoredFertilizerBase
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSFW_maxStoredFertilizerBase = aValue
	EndFunction
EndProperty					

; vendor income
Bool Property bUseGlobalminVendorIncomePopulation = true Auto Hidden
Int WSFW_minVendorIncomePopulation = 5 ; need at least this population to get any vendor income
Int Property minVendorIncomePopulation
	Int Function Get()
		Int AppliedValue = Math.Ceiling(GetValue(WSFW_AV_minVendorIncomePopulation))
		
		if(bUseGlobalminVendorIncomePopulation)
			return AppliedValue + WSFW_Setting_minVendorIncomePopulation.GetValueInt()
		else
			return AppliedValue + WSFW_minVendorIncomePopulation
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSFW_minVendorIncomePopulation = aValue
	EndFunction
EndProperty	

Bool Property bUseGlobalmaxVendorIncome = true Auto Hidden
Float WSFW_maxVendorIncome = 50.0 ; max daily vendor income from any settlement
float Property maxVendorIncome
	Float Function Get()
		Float AppliedValue = GetValue(WSFW_AV_maxVendorIncome)
		
		if(bUseGlobalmaxVendorIncome)
			return AppliedValue + WSFW_Setting_maxVendorIncome.GetValue()
		else
			return AppliedValue + WSFW_maxVendorIncome
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSFW_maxVendorIncome = aValue
	EndFunction
EndProperty	
				
Bool Property bUseGlobalvendorIncomePopulationMult = true Auto Hidden
Float WSFW_vendorIncomePopulationMult = 0.03 ; multiplier on population, added to vendor income
float Property vendorIncomePopulationMult
	Float Function Get()
		Float AppliedValue = GetValue(WSFW_AV_vendorIncomePopulationMult)
		
		if(bUseGlobalvendorIncomePopulationMult)
			return AppliedValue + WSFW_Setting_vendorIncomePopulationMult.GetValue()
		else
			return AppliedValue + WSFW_vendorIncomePopulationMult
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSFW_vendorIncomePopulationMult = aValue
	EndFunction
EndProperty						

Bool Property bUseGlobalvendorIncomeBaseMult = true Auto Hidden
Float WSFW_vendorIncomeBaseMult = 2.0 ; multiplier on base vendor income
float Property vendorIncomeBaseMult
	Float Function Get()
		Float AppliedValue = GetValue(WSFW_AV_vendorIncomeBaseMult)
		
		if(bUseGlobalvendorIncomeBaseMult)
			return AppliedValue + WSFW_Setting_vendorIncomeBaseMult.GetValue()
		else
			return AppliedValue + WSFW_vendorIncomeBaseMult
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSFW_vendorIncomeBaseMult = aValue
	EndFunction
EndProperty		
				

; radio/attracting NPC stuff
Bool Property bUseGlobaliMaxSurplusNPCs = true Auto Hidden
Int WSFW_iMaxSurplusNPCs = 5 ; for now, max number of unassigned NPCs - if you have this many or more, no new NPCs will arrive.
Int Property iMaxSurplusNPCs
	Int Function Get()
		Int AppliedValue = Math.Ceiling(GetValue(WSFW_AV_iMaxSurplusNPCs))
		
		if(bUseGlobaliMaxSurplusNPCs)
			return AppliedValue + WSFW_Setting_iMaxSurplusNPCs.GetValueInt()
		else
			return AppliedValue + WSFW_iMaxSurplusNPCs
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSFW_iMaxSurplusNPCs = aValue
	EndFunction
EndProperty	
			
Bool Property bUseGlobalattractNPCDailyChance = true Auto Hidden
Float WSFW_attractNPCDailyChance = 0.1 ; for now, roll <= to this to attract an NPC each day, modified by happiness
float Property attractNPCDailyChance
	Float Function Get()
		Float AppliedValue = GetValue(WSFW_AV_attractNPCDailyChance)
		
		if(bUseGlobalattractNPCDailyChance)
			return AppliedValue + WSFW_Setting_attractNPCDailyChance.GetValue()
		else
			return AppliedValue + WSFW_attractNPCDailyChance
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSFW_attractNPCDailyChance = aValue
	EndFunction
EndProperty			
 	
Bool Property bUseGlobaliMaxBonusAttractChancePopulation = true Auto Hidden
Int WSFW_iMaxBonusAttractChancePopulation = 5 ; for now, there's a bonus attract chance until the total population reaches this value more, no new NPCs will arrive.
Int Property iMaxBonusAttractChancePopulation
	Int Function Get()
		Int AppliedValue = Math.Ceiling(GetValue(WSFW_AV_iMaxBonusAttractChancePopulation))
		
		if(bUseGlobaliMaxBonusAttractChancePopulation)
			return AppliedValue + WSFW_Setting_iMaxBonusAttractChancePopulation.GetValueInt()
		else
			return AppliedValue + WSFW_iMaxBonusAttractChancePopulation
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSFW_iMaxBonusAttractChancePopulation = aValue
	EndFunction
EndProperty		

Int Property iOverrideTotalMaxNPCs = -1 Auto Hidden
Bool Property bUseGlobaliBaseMaxNPCs = true Auto Hidden
Int WSFW_iBaseMaxNPCs = 10 ; base total NPCs that can be at a player's town - this is used in GetMaxWorkshopNPCs formula
Int Property iBaseMaxNPCs
	Int Function Get()
		Int AppliedValue = Math.Ceiling(GetValue(WSFW_AV_iBaseMaxNPCs))
		
		if(bUseGlobaliBaseMaxNPCs)
			return AppliedValue + WSFW_Setting_iBaseMaxNPCs.GetValueInt()
		else
			return AppliedValue + WSFW_iBaseMaxNPCs
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSFW_iBaseMaxNPCs = aValue
	EndFunction
EndProperty	

Bool Property bUseGlobalattractNPCHappinessMult = true Auto Hidden
Float WSFW_attractNPCHappinessMult = 0.5 ; multiplier on happiness to attraction chance
float Property attractNPCHappinessMult
	Float Function Get()
		Float AppliedValue = GetValue(WSFW_AV_attractNPCHappinessMult)
		
		if(bUseGlobalattractNPCHappinessMult)
			return AppliedValue + WSFW_Setting_attractNPCHappinessMult.GetValue()
		else
			return AppliedValue + WSFW_attractNPCHappinessMult
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSFW_attractNPCHappinessMult = aValue
	EndFunction
EndProperty			
		

; attack chance formula
Bool Property bUseGlobalattackChanceBase = true Auto Hidden
Float WSFW_attackChanceBase = 0.02
float Property attackChanceBase
	Float Function Get()
		Float AppliedValue = GetValue(WSFW_AV_attackChanceBase)
		
		if(bUseGlobalattackChanceBase)
			return AppliedValue + WSFW_Setting_attackChanceBase.GetValue()
		else
			return AppliedValue + WSFW_attackChanceBase
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSFW_attackChanceBase = aValue
	EndFunction
EndProperty		

Bool Property bUseGlobalattackChanceResourceMult = true Auto Hidden
Float WSFW_attackChanceResourceMult = 0.001
float Property attackChanceResourceMult
	Float Function Get()
		Float AppliedValue = GetValue(WSFW_AV_attackChanceResourceMult)
		
		if(bUseGlobalattackChanceResourceMult)
			return AppliedValue + WSFW_Setting_attackChanceResourceMult.GetValue()
		else
			return AppliedValue + WSFW_attackChanceResourceMult
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSFW_attackChanceResourceMult = aValue
	EndFunction
EndProperty	

Bool Property bUseGlobalattackChanceSafetyMult = true Auto Hidden
Float WSFW_attackChanceSafetyMult = 0.01
float Property attackChanceSafetyMult
	Float Function Get()
		Float AppliedValue = GetValue(WSFW_AV_attackChanceSafetyMult)
		
		if(bUseGlobalattackChanceSafetyMult)
			return AppliedValue + WSFW_Setting_attackChanceSafetyMult.GetValue()
		else
			return AppliedValue + WSFW_attackChanceSafetyMult
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSFW_attackChanceSafetyMult = aValue
	EndFunction
EndProperty	

Bool Property bUseGlobalattackChancePopulationMult = true Auto Hidden
Float WSFW_attackChancePopulationMult = 0.005
float Property attackChancePopulationMult
	Float Function Get()
		Float AppliedValue = GetValue(WSFW_AV_attackChancePopulationMult)
		
		if(bUseGlobalattackChancePopulationMult)
			return AppliedValue + WSFW_Setting_attackChancePopulationMult.GetValue()
		else
			return AppliedValue + WSFW_attackChancePopulationMult
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSFW_attackChancePopulationMult = aValue
	EndFunction
EndProperty	

Bool Property bUseGlobalminDaysSinceLastAttack = true Auto Hidden
Float WSFW_minDaysSinceLastAttack = 7.0 ;	minimum days before another attack can be rolled for
float Property minDaysSinceLastAttack
	Float Function Get()
		Float AppliedValue = GetValue(WSFW_AV_minDaysSinceLastAttack)
		
		if(bUseGlobalminDaysSinceLastAttack)
			return AppliedValue + WSFW_Setting_minDaysSinceLastAttack.GetValue()
		else
			return AppliedValue + WSFW_minDaysSinceLastAttack
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSFW_minDaysSinceLastAttack = aValue
	EndFunction
EndProperty	
		

; damage
Bool Property bUseGlobaldamageDailyRepairBase = true Auto Hidden
Float WSFW_damageDailyRepairBase = 5.0 ; amount of damage repaired per day (overall)
float Property damageDailyRepairBase
	Float Function Get()
		Float AppliedValue = GetValue(WSFW_AV_damageDailyRepairBase)
		
		if(bUseGlobaldamageDailyRepairBase)
			return AppliedValue + WSFW_Setting_damageDailyRepairBase.GetValue()
		else
			return AppliedValue + WSFW_damageDailyRepairBase
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSFW_damageDailyRepairBase = aValue
	EndFunction
EndProperty	

Bool Property bUseGlobaldamageDailyPopulationMult = true Auto Hidden
Float WSFW_damageDailyPopulationMult = 0.20 ;	multiplier on population for repair:  repair = population * damageDailyPopulationMult * damageDailyPopulationMult
float Property damageDailyPopulationMult
	Float Function Get()
		Float AppliedValue = GetValue(WSFW_AV_damageDailyPopulationMult)
		
		if(bUseGlobaldamageDailyPopulationMult)
			return AppliedValue + WSFW_Setting_damageDailyPopulationMult.GetValue()
		else
			return AppliedValue + WSFW_damageDailyPopulationMult
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSFW_damageDailyPopulationMult = aValue
	EndFunction
EndProperty	
			
			
			
; WSFW - Entirely new modifiers with global and local controls
Bool Property bUseGlobaliBaseMaxBrahmin = true Auto Hidden
Int WSFW_iBaseMaxBrahmin = 1
Int Property iBaseMaxBrahmin
	Int Function Get()
		Float AppliedValue = GetValue(WSFW_AV_iBaseMaxBrahmin)
		
		if(bUseGlobaliBaseMaxBrahmin)
			return (AppliedValue + WSFW_Setting_iBaseMaxBrahmin.GetValue()) as Int
		else
			return (AppliedValue + WSFW_iBaseMaxBrahmin) as Int
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSFW_iBaseMaxBrahmin = aValue
	EndFunction
EndProperty


Bool Property bUseGlobaliBaseMaxSynths = true Auto Hidden
Int WSFW_iBaseMaxSynths = 1
Int Property iBaseMaxSynths
	Int Function Get()
		Float AppliedValue = GetValue(WSFW_AV_iBaseMaxSynths)
		
		if(bUseGlobaliBaseMaxSynths)
			return (AppliedValue + WSFW_Setting_iBaseMaxSynths.GetValue()) as Int
		else
			return (AppliedValue + WSFW_iBaseMaxSynths) as Int
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSFW_iBaseMaxSynths = aValue
	EndFunction
EndProperty


Bool Property bUseGlobalrecruitmentGuardChance = true Auto Hidden
Int WSFW_recruitmentGuardChance = 20 ; % chance of getting a "guard" NPC
Int Property recruitmentGuardChance
	Int Function Get()
		Float AppliedValue = GetValue(WSFW_AV_recruitmentGuardChance)
		
		if(bUseGlobalrecruitmentGuardChance)
			return (AppliedValue + WSFW_Setting_recruitmentGuardChance.GetValue()) as Int
		else
			return (AppliedValue + WSFW_recruitmentGuardChance) as Int
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSFW_recruitmentGuardChance = aValue
	EndFunction
EndProperty


Bool Property bUseGlobalrecruitmentBrahminChance = true Auto Hidden
Int WSFW_recruitmentBrahminChance = 20 ; % chance of getting a brahmin with a "farmer" settler
Int Property recruitmentBrahminChance
	Int Function Get()
		Float AppliedValue = GetValue(WSFW_AV_recruitmentBrahminChance)
		
		if(bUseGlobalrecruitmentBrahminChance)
			return (AppliedValue + WSFW_Setting_recruitmentBrahminChance.GetValue()) as Int
		else
			return (AppliedValue + WSFW_recruitmentBrahminChance) as Int
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSFW_recruitmentBrahminChance = aValue
	EndFunction
EndProperty


Bool Property bUseGlobalrecruitmentSynthChance = true Auto Hidden
Int WSFW_recruitmentSynthChance = 10 ; % chance of a settler being a Synth
Int Property recruitmentSynthChance
	Int Function Get()
		Float AppliedValue = GetValue(WSFW_AV_recruitmentSynthChance)
		
		if(bUseGlobalrecruitmentSynthChance)
			return (AppliedValue + WSFW_Setting_recruitmentSynthChance.GetValue()) as Int
		else
			return (AppliedValue + WSFW_recruitmentSynthChance) as Int
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSFW_recruitmentSynthChance = aValue
	EndFunction
EndProperty


Bool Property bUseGlobalactorDeathHappinessModifier = true Auto Hidden
Float WSFW_actorDeathHappinessModifier = -20.0 ; happiness modifier when an actor dies
Float Property actorDeathHappinessModifier
	Float Function Get()
		Float AppliedValue = GetValue(WSFW_AV_actorDeathHappinessModifier)
		
		if(bUseGlobalactorDeathHappinessModifier)
			return AppliedValue + WSFW_Setting_actorDeathHappinessModifier.GetValue()
		else
			return AppliedValue + WSFW_actorDeathHappinessModifier
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSFW_actorDeathHappinessModifier = aValue
	EndFunction
EndProperty


Bool Property bUseGlobalmaxAttackStrength = true Auto Hidden
Int WSFW_maxAttackStrength = 100
Int Property maxAttackStrength
	Int Function Get()
		Float AppliedValue = GetValue(WSFW_AV_maxAttackStrength)
		
		if(bUseGlobalmaxAttackStrength)
			return (AppliedValue + WSFW_Setting_maxAttackStrength.GetValue()) as Int
		else
			return (AppliedValue + WSFW_maxAttackStrength) as Int
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSFW_maxAttackStrength = aValue
	EndFunction
EndProperty


Bool Property bUseGlobalmaxDefenseStrength = true Auto Hidden
Int WSFW_maxDefenseStrength = 100
Int Property maxDefenseStrength
	Int Function Get()
		Float AppliedValue = GetValue(WSFW_AV_maxDefenseStrength)
		
		if(bUseGlobalmaxDefenseStrength)
			return (AppliedValue + WSFW_Setting_maxDefenseStrength.GetValue()) as Int
		else
			return (AppliedValue + WSFW_maxDefenseStrength) as Int
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSFW_maxDefenseStrength = aValue
	EndFunction
EndProperty


Bool Property bUseGlobalRobotHappinessLevel = true Auto Hidden
Int WSFW_RobotHappinessLevel = 50
Int Property RobotHappinessLevel
	Int Function Get()
		Float AppliedValue = GetValue(WSFW_AV_RobotHappinessLevel)
		
		if(bUseGlobalmaxDefenseStrength)
			return (AppliedValue + WSFW_Setting_RobotHappinessLevel.GetValue()) as Int
		else
			return (AppliedValue + WSFW_RobotHappinessLevel) as Int
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSFW_RobotHappinessLevel = aValue
	EndFunction
EndProperty


Bool Property bAllowLinkedConsumption = true Auto Hidden ; WSFW - Allow flagging a particular workshop to not share its workshop contents for consumption by other settlements

ResourceShortage[] Property ShortResources Auto Hidden ; WSFW 1.0.8 - Resources that mods have reported are lacking


; WSFW 1.1.0 - Support for Control system - we don't want to use SettlementOwnershipFaction as it is used by the base game for another purpose
Faction Property ControllingFaction Auto Hidden ; Non-WSFW specific for simple checks
FactionControl Property FactionControlData Auto Hidden ; All WSFW data
WorkshopFramework:WorkshopControlManager Property ControlManager Auto Hidden

; WSFW 1.2.0 - Support for Settlement Layout system
WorkshopFramework:Weapons:SettlementLayout[] Property AppliedLayouts Auto Hidden
Bool[] Property LayoutScrappingComplete Auto Hidden
Bool[] Property LayoutPlacementComplete Auto Hidden
Bool Property bHasEnteredWorkshopModeHere = false Auto Hidden ; F4SE cannot wire up settlements until this is true

int VendorTopLevel = 2 const ; WSFW - Copied from WorkshopParent

Bool Property bPropertiesConfigured = false Auto Hidden ; Flag from WSFW ResourceManager after it has configured all AVs, etc.

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
int WSFW_RetryRealDailyUpdateTimerID = 100

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


;---------------------------------------------------------------
;	Added by UFO4P 2.0.5 for Bug #25129:
;---------------------------------------------------------------

bool property UFO4P_HandleUnassignedActors = false auto hidden


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
	int containerArraySize = WorkshopParent.VendorTopLevel + 1
	ObjectReference[] vendorContainers = new ObjectReference[containerArraySize]

	; create the chests
	FormList vendorContainerList = WorkshopParent.WorkshopVendorContainers[vendorType]
	FormList WSFW_InjectionContainerList = WorkshopParent.WSFW_InjectionVendorContainers[vendorType]
	
	int vendorLevel = 0
	while vendorLevel <= WorkshopParent.VendorTopLevel
		; create ref for each vendor level
		ObjectReference thisVendorContainer = WorkshopParent.WorkshopHoldingCellMarker.PlaceAtMe(vendorContainerList.GetAt(vendorLevel))
		
		vendorContainers[vendorLevel] = thisVendorContainer
		
		if(WSFW_InjectionContainerList != None)
			ObjectReference kWSFWInjectionContainerRef = Self.PlaceAtMe(WSFW_InjectionContainerList.GetAt(vendorLevel))
			
			if(kWSFWInjectionContainerRef != None)
				;Debug.Trace(">>>>>>>>>>>>>>> Linking injection container " + kWSFWInjectionContainerRef + " (base object: " + kWSFWInjectionContainerRef.GetBaseObject() + "), to vendor container " + thisVendorContainer + " (base object: " + kWSFWInjectionContainerRef.GetBaseObject() + ")")
				
				kWSFWInjectionContainerRef.SetLinkedRef(thisVendorContainer, (kWSFWInjectionContainerRef as WorkshopFramework:ObjectRefs:MoveContainerItemsOnLoad).MoveToLinkedRefOnKeyword)
			endif
		endif
		
		vendorLevel += 1
	endWhile

	return vendorContainers
endFunction


; WSFW 2.0.0 - Pull vendor containers for custom vendor types
ObjectReference[] Function GetCustomVendorContainers(String asCustomVendorID)
	int iIndex = WorkshopParent.CustomVendorTypes.FindStruct("sVendorID", asCustomVendorID)
	if(iIndex >= 0) ; Vendor type registered - look for local containers
		ObjectReference[] kContainers = new ObjectReference[3]
		
		if(kCustomVendorContainersL0 == None)
			kCustomVendorContainersL0 = new ObjectReference[128]
		endif
		
		if(kCustomVendorContainersL1 == None)
			kCustomVendorContainersL1 = new ObjectReference[128]
		endif
		
		if(kCustomVendorContainersL2 == None)
			kCustomVendorContainersL2 = new ObjectReference[128]
		endif
		
		if(kCustomVendorContainersL0[iIndex] == None || kCustomVendorContainersL1[iIndex] == None || kCustomVendorContainersL2[iIndex] == None)
			kContainers = InitializeCustomVendorChests(asCustomVendorID)
		else
			kContainers[0] = kCustomVendorContainersL0[iIndex]
			kContainers[1] = kCustomVendorContainersL1[iIndex]
			kContainers[2] = kCustomVendorContainersL2[iIndex]
		endif
		
		return kContainers
	endif
	
	return None
EndFunction

; WSFW 2.0.0 - Create vendor containers for custom vendor types
ObjectReference[] function InitializeCustomVendorChests(String asCustomVendorID)
	; initialize array
	ObjectReference[] kVendorContainers = new ObjectReference[3]

	; create the chests
	int iIndex = WorkshopParent.CustomVendorTypes.FindStruct("sVendorID", asCustomVendorID)
	if(iIndex >= 0)
		FormList vendorContainerList = WorkshopParent.CustomVendorTypes[iIndex].VendorContainerList
		int iVendorLevel = 0
		while(iVendorLevel < 3)
			; create ref for each vendor level
			kVendorContainers[iVendorLevel] = WorkshopParent.WorkshopHoldingCellMarker.PlaceAtMe(vendorContainerList.GetAt(iVendorLevel))
			
			if(iVendorLevel == 0)
				kCustomVendorContainersL0[iIndex] = kVendorContainers[iVendorLevel]
			elseif(iVendorLevel == 1)
				kCustomVendorContainersL1[iIndex] = kVendorContainers[iVendorLevel]
			elseif(iVendorLevel == 2)
				kCustomVendorContainersL2[iIndex] = kVendorContainers[iVendorLevel]
			endif
			
			iVendorLevel += 1
		endWhile
	endif
	
	return kVendorContainers
endFunction


Event OnInit()
	; WSFW - 1.0.5 - Imperative that all vars are loaded. This will slow down the init, but will ensure we don't run into any None forms
	WorkshopParent.FillWSFWVars()
	
	; WSFW - 1.0.3
	FillWSFWVars() 
	
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
	if( ! bWSFWVarsFilled)
		FillWSFWVars()
	endif
	
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

	if aStart
		if OwnedByPlayer
			; make this the current workshop
			WorkshopParent.SetCurrentWorkshop(self)
		endif
		
		; WSFW 1.2.0 - The player must have entered workshop mode in a settlement for the F4SE wire functions to work - this way we can check for it
		bHasEnteredWorkshopModeHere = true
		
		; WSFW Event Edit - Adding aStart to the end of event arguments 
		;Var[] kargs = new Var[2]
		;kargs[0] = NONE
		;kargs[1] = self
	endif
	
	; 1.1.7 - WSFW Moving outside of aStart block
	Var[] kargs = new Var[0]
	kargs.Add(NONE)
	kargs.Add(Self)
	kargs.Add(aStart)
				
	WorkshopParent.SendCustomEvent("WorkshopEnterMenu", kargs)		

	; Dogmeat scene
	if aStart && WorkshopParent.DogmeatAlias.GetRef()
		WorkshopParent.WorkshopDogmeatWhileBuildingScene.Start()
	else
		WorkshopParent.WorkshopDogmeatWhileBuildingScene.Stop()
	endif

	; Companion scene
	if aStart && WorkshopParent.CompanionAlias.GetRef()
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
	elseif(aiTimerID == WSFW_RetryRealDailyUpdateTimerID)
		TryRealDailyUpdate()
	endif
EndEvent

Event OnTimerGameTime(int aiTimerID)
	if aiTimerID == dailyUpdateTimerID
		; WSWF - This is no longer used. Since we've converted the daily update process to be handled by multiple managers, they operate much faster and no longer require spreading throughout the game day
	endif
endEvent


Function TryRealDailyUpdate()
	if(WorkshopParent.DailyUpdateInProgress || ! bPropertiesConfigured)
		String sMessage = "Starting timer to retry daily update."
		
		if( ! bPropertiesConfigured)
			sMessage += " Awaiting properties to be configured from WSFWResourceManager."
		else
			sMessage += " WorkshopParent.DailyUpdateInProgress = " + WorkshopParent.DailyUpdateInProgress
		endif
		
		Debug.Trace(Self + sMessage)
		; run another timer - system is too busy
		StartTimer(Utility.RandomInt(5, 10), WSFW_RetryRealDailyUpdateTimerID)
	else
		DailyUpdate()
	endif	
EndFunction

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
		while(i < WorkshopActors.Length)
			; WSFW 2.0.0 - Switched to nonWorkshopNPCScript actor
			Actor theActor = WorkshopActors[i] as Actor
			if(theActor)
				theActor.RemoveFromFaction(FarmDiscountFaction)
				
				; clear "player owned" actor value (used to condition trade items greetings)
				WorkshopFramework:WorkshopFunctions.UpdatePlayerOwnership(theActor, self)
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
		while(i < WorkshopActors.Length)
			; WSFW 2.0.0 - Switched to nonWorkshopNPCScript actors
			Actor theActor = WorkshopActors[i] as Actor
			if(theActor)
				WorkshopFramework:WorkshopFunctions.UpdatePlayerOwnership(theActor, self)
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
	; WSFW 1.1.0 - Support for FactionControl system
	if(ControllingFaction != None && akReference.GetBaseValue(Safety) > 0)
		Actor TurretRef = akReference as Actor
		
		if(TurretRef && ControlManager)
			WorkshopScript thisWorkshop = GetLinkedRef(WorkshopParent.WorkshopItemKeyword) as WorkshopScript
			ControlManager.CaptureTurret(TurretRef, thisWorkshop, aFactionData = thisWorkshop.FactionControlData, abPlayerIsEnemy = (ControllingFaction.GetFactionReaction(Game.GetPlayer() as Actor) == 1), abForPlayer = thisWorkshop.OwnedByPlayer)
		endif
	endif
	
	WorkshopParent.BuildObjectPUBLIC(akReference, self)
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
	;float waitTime = WorkshopParent.dailyUpdateIncrement * workshopID
	
	;StartTimerGameTime(waitTime, dailyUpdateTimerID)
	
	; WSFW - Now that we've separated out most of the daily update functionality to other quests, the portion the workshops handle is very small and can just use a normal quick time for thread safety
	StartTimer(workshopID, WSFW_RetryRealDailyUpdateTimerID) ; We'll use the workshopID as our number of seconds to wait so that they each fire one after the other a second apart
EndEvent

; return max NPCs for this workshop
int function GetMaxWorkshopNPCs()
	if(iOverrideTotalMaxNPCs >= 0)
		return iOverrideTotalMaxNPCs
	endif
	
	; base + player's charisma
	int iMaxNPCs = iBaseMaxNPCs
	
	if(WSFW_Setting_AdjustMaxNPCsByCharisma.GetValue() == 1)
		iMaxNPCs += (Game.GetPlayer().GetValue(Game.GetCharismaAV()) as int)
	endif
	
	if(WSFW_Setting_CapMaxNPCsByBedCount.GetValue() == 1)
		Int iBedCount = GetBaseValue(Beds) as Int
		if(iMaxNPCs > iBedCount)
			iMaxNPCs = iBedCount
		endif
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

function DailyUpdate(bool bRealUpdate = true)
	; wait for update lock to be released
	
	if(WorkshopParent.DailyUpdateInProgress)
		if(bRealUpdate || bResetHappiness)
			while(WorkshopParent.DailyUpdateInProgress)
				utility.wait(0.5)
			endWhile
		else
			; just bail if not a real update - no need
			return
		endif
	EndIf
	
	WorkshopParent.DailyUpdateInProgress = true

	; create local pointer to WorkshopRatings array to speed things up
	WorkshopDataScript:WorkshopRatingKeyword[] ratings = WorkshopParent.WorkshopRatings
	
	; REAL UPDATE ONLY
	if(bRealUpdate)
		; WSFW - New settlers handled by our NPCManager
		; DailyUpdateAttractNewSettlers(ratings, updateData)
		
		; WSFW - Pulled this from DailyUpdateAttractNewSettlers
		; increment last visit counter each day
		DaysSinceLastVisit += 1
	EndIf

	; if this is current workshop, update actors (in case some have been wounded since last update)
	if(GetWorkshopID() == CurrentWorkshopID.GetValue() && WorkshopParent.UFO4P_IsWorkshopLoaded(self))
		ObjectReference[] WorkshopActors = WorkshopParent.GetWorkshopActors(self)
		int i = 0
		while(i < WorkshopActors.Length)
			; WSFW 2.0.0 - Switched to nonWorkshopNPCScript actors
			Actor theActor = WorkshopActors[i] as Actor
			
			if(theActor)
				WorkshopFramework:WorkshopFunctions.UpdateActorsWorkObjects(theActor, self, false)
			endif
			
			i += 1
		endWhile
	endif

	; WSFW - Reminder: Production and Consumption are now handled by our WorkshopProductionManager script
	WSFW_DailyUpdate_AdjustResourceValues(ratings, bRealUpdate)
	
	; REAL UPDATE ONLY:
	if(bRealUpdate)
		; WSFW - Surplus handled by our WorkshopProductionManager script now 
		
		RepairDamage()
	
		; now recalc all workshop resources if the current workshop - we don't want to do this when unloaded or everything will be 0
		RecalculateWorkshopResources()

		CheckForAttack()
	endif

	if(bResetHappiness)
		WorkshopParent.ResetHappinessPUBLIC(self)
		
		bResetHappiness = false
	endif

	; clear update lock
	WorkshopParent.DailyUpdateInProgress = false
	
	if(bRealUpdate)
		Debug.Trace("<<<<<<<<< DailyUpdate Finished for " + Self)
	endif
endFunction


; **********************************************************************************************
; DAILY UPDATE HELPER FUNCTIONS - to reduce memory footprint of DailyUpdate process
; **********************************************************************************************
; WSFW - New function to handle the resource updating on the workshop during a daily update
Function WSFW_DailyUpdate_AdjustResourceValues(WorkshopDataScript:WorkshopRatingKeyword[] ratings, bool bRealUpdate)
	if(bRealUpdate)
		ModTrace("==============================================")
		ModTrace("[WSFW] 			Starting WSFW_DailyUpdate_AdjustResourceValues  " + Self)
		ModTrace("==============================================")
	endif
	
	; Instead of using DailyUpdateData, we're only going to grab the values we actually need here
	Int iTotalPopulation = GetBaseValue(Population) as int
	Int iRobotPopulation = GetBaseValue(PopulationRobots) as int
	Int iLivingPopulation = iTotalPopulation - iRobotPopulation	
	if(iLivingPopulation < 0)
		iLivingPopulation = 0
	endif
	Int iBrahminPopulation = GetBaseValue(PopulationBrahmin) as int
	Float fDamageMult = 1 - GetValue(DamageCurrent)/100.0
	Float fProductivity = GetProductivityMultiplier(ratings)
	Int iAvailableBeds = GetBaseValue(Beds) as int
	Int iSheltedBeds = GetValue(Beds) as int
	
	; 1.0.5 - Added option to turn off the shelter mechanic as it's very buggy
	if(WSFW_Setting_ShelterMechanic.GetValue() == 0.0)
		iSheltedBeds = iAvailableBeds
	endif
	
	Int iSafety = GetValue(Safety) as int
	Int iSafetyDamage = GetValue(DamageSafety) as int

	; To be calculated ahead
	Int iSafetyPerNPC = 0
	
	
	; ----------------------------
	; Update Safety
	; ----------------------------
	
	; safety check: WSFW - Adding additional needs AV here
	Float fSafetyNeeded = iTotalPopulation + GetValue(WSFW_AV_ExtraNeeds_Safety)
	int iMissingSafety = Math.Max(0, fSafetyNeeded - iSafety) as int
	SetAndRestoreActorValue(self, MissingSafety, iMissingSafety)

	; reduce safety by current damage (food and water already got that treatment in the Production phase)
	iSafety = Math.Max(iSafety - iSafetyDamage, 0) as int
	
	if(iTotalPopulation > 0)
		iSafetyPerNPC = Math.Ceiling(iSafety/iTotalPopulation)
	endif
	
	; ----------------------------
	; Update FoodActual 
	; ----------------------------
	
	; get base food production
	Int iFoodProduction = GetValue(Food) as int
	
	; subtract damage from food
	iFoodProduction = math.max(0, iFoodProduction - (GetValue(DamageFood) as int)) as int
	
	; each brahmin can assist with X food production
	if(iBrahminPopulation > 0)
		int iBrahminMaxFoodBoost = math.min(iBrahminPopulation * maxProductionPerBrahmin, iFoodProduction) as int
		int iBrahminFoodProduction = math.Ceiling(iBrahminMaxFoodBoost * brahminProductionBoost)
		iFoodProduction = iFoodProduction + iBrahminFoodProduction
	endif
	
	SetAndRestoreActorValue(self, FoodActual, iFoodProduction)
		
	
	; ----------------------------
	; Update Beds
	; ----------------------------
	
	int iMissingBeds = Math.Max(0, iLivingPopulation - iAvailableBeds) As Int
	SetAndRestoreActorValue(self, MissingBeds, iMissingBeds)	
	
	
	; ----------------------------
	; Update Trade Caravans
	; ----------------------------
	
	; update trade caravan list
	if(iTotalPopulation >= WorkshopParent.TradeCaravanMinimumPopulation && GetValue(Caravan) > 0)
		WorkshopParent.TradeCaravanWorkshops.AddRef(self)
	else
		WorkshopParent.TradeCaravanWorkshops.RemoveRef(self)
	EndIf
	
	
	; ----------------------------
	;
	; Can skip everything below if no population - this will essentially lock happiness until the next time settlers live there, which is fine
	;
	; ----------------------------

	if(iTotalPopulation <= 0)
		if(bRealUpdate)
			ModTrace("[WSFW] 			Settlement has no population, skipping happiness checks.")
		endif
		
		return
	endif
	
	if(GetValue(WorkshopHideHappinessBarAV) > 0)
		; This settlement isn't using happiness - likely an interior player home settlement
		
		return
	endif
	
	
	; ----------------------------
	; Update Happiness 
	; ----------------------------

	;WSFW - Below is based on the UFO4P optimized happiness calculation code
	Float fTotalHappiness = 0.0	; sum of all happiness of each actor in town
	Float fCurrentHappiness = GetValue(Happiness)
	Float fBonusHappiness = GetValue(BonusHappiness) as int
	Float fHappinessModifier = GetValue(HappinessModifier) as int
	
	Int iMissingFood = GetValue(MissingFood) as Int
	Int iMissingWater = GetValue(MissingWater) as Int
	
	
	; variables used to track happiness for each actor
	float fActorHappiness
	bool bActorBed
	bool bActorShelter
	bool bActorFood
	bool bActorWater

	;helper array for all resource values that contribute to actor happiness
	int[] ResourceCount = New int [5]
	;helper array that holds the positions at which the individual resource values are found in the ResourceCount array:
	int[] ResourcePos = New Int [4]

	;helper variables for quick access of the respective resources in ResourcePos array:
	Int posShelter = 0
	Int posBeds = 1
	Int posWater = 2
	Int posFood = 3

	; 1.0.4 - Making this code easier to follow so we can track down happiness issues
	int iHaveFood = iLivingPopulation - iMissingFood
	if(iHaveFood < 0)
		iHaveFood = 0
	endif
	int iHaveWater = iLivingPopulation - iMissingWater
	if(iHaveWater < 0)
		iHaveWater = 0
	endif
	
	;Since iSheltedBeds <= iAvailableBeds, and both AvailableWater and AvailableFood are usually larger than the
	;latter, filling the array in the following order will save a couple of swaps when it is sorted below:
	ResourceCount[0] = iSheltedBeds
	ResourceCount[1] = iAvailableBeds
	ResourceCount[2] = iHaveWater
	ResourceCount[3] = iHaveFood
	;This is a helper position for all actors who do not benefit from any rexource. Set this to the maximum possible value:
	ResourceCount[4] = iLivingPopulation

	if(bRealUpdate)
		ModTrace("[WSFW] 				Available Beds: " + iAvailableBeds)
		ModTrace("[WSFW] 				Sheltered Beds: " + iSheltedBeds)
		ModTrace("[WSFW] 				Hungry Settlers: " + Math.Min(iMissingFood, iLivingPopulation) as Int)
		ModTrace("[WSFW] 				Thirsty Settlers: " + Math.Min(iMissingWater, iLivingPopulation) as Int)
	endif
		
	;Save the positions of the resource values in ResourceCount array in the ResourcePos array. After the arrays are sorted, ResourcePos [posShelter], ResourcePos
	;[posBeds], etc. will return the positions at which updateData.shelteredBeds, updateData.availableBeds etc. have ended up in the ResourceCount array.
	ResourcePos[posShelter] = 0
	ResourcePos[posBeds] = 1
	ResourcePos[posWater] = 2
	ResourcePos[posFood] = 3

	;sort arrays (disregard last position of the ResourceCount array):
	int i = 3
	While(i > 0)
		int j = 0
		While(j < i)
			If(ResourceCount[j] > ResourceCount[j + 1])
				; Sort counts
				int swapInt = ResourceCount[j]
				ResourceCount[j] = ResourceCount[j + 1]
				ResourceCount[j + 1] = swapInt
				
				; Sort indexes to match
				swapInt = ResourcePos[j]
				ResourcePos[j] = ResourcePos[j + 1]
				ResourcePos[j + 1] = swapInt
			EndIf
			j += 1
		EndWhile
		i -= 1
	EndWhile

	;Calculate the numbers of actors to benefit from the individual resources (again, the last array position is disregarded).
	i = 3
	while(i > 0)
		ResourceCount[i] = ResourceCount[i] - ResourceCount[i - 1]
		i -= 1
	EndWhile
	
	bActorWater = True
	bActorFood = True
	bActorBed = True
	bActorShelter = True

	;Calculate the maximum possible Happiness for an individual actor. This value applies to all actors who benefit from all four resources. As the loop progresses, individual
	;boni will be subtracted from this value:
	fActorHappiness = happinessBonusWater + happinessBonusFood + happinessBonusBed + happinessBonusShelter
	;The safety bonus applies either to all actors or to none:
	If(iSafetyPerNPC > 0)
		fActorHappiness += happinessBonusSafety
		
		if(bRealUpdate)
			ModTrace("[WSFW] 				Happiness For Proper Defenses Applied: " + happinessBonusSafety)
		endif
	else
		if(bRealUpdate)
			ModTrace("[WSFW] 				Happiness Penalty for Poor Defenses: -" + happinessBonusSafety)
		endif
	EndIf

	Int iActorCount = Math.Min(ResourceCount[0], iLivingPopulation) As Int
	Int iRemainingActors = iLivingPopulation - iActorCount

	;For i = 0, none of the conditions checksd in the loop would return true and there is also no need to call the CheckActorHappiness function (because there
	;are no happiness caps applying when no resources are missing). Therefore, we take the following value as start value and begin the loop with i = 1

	if(bRealUpdate)
		ModTrace("[WSFW] 				Settlers with All Needs Mets (" + fActorHappiness + " happiness): " + iActorCount)
	endif
	
	fTotalHappiness += (iActorCount * fActorHappiness)
	i = 1	
	while(i < 5 && iRemainingActors > 0)
		If(bActorWater && ResourcePos[posWater] < i)
			fActorHappiness -= happinessBonusWater
			bActorWater = False
		EndIf
				
		If(bActorFood && ResourcePos[posFood] < i)
			fActorHappiness -= happinessBonusFood
			bActorFood = False
		EndIf

		If(bActorBed && ResourcePos[posBeds] < i)
			fActorHappiness -= happinessBonusBed
			bActorBed = False
		EndIf

		If(bActorShelter && ResourcePos[posShelter] < i)
			fActorHappiness -= happinessBonusShelter
			bActorShelter = False
		EndIf		

		iActorCount = Math.Min(ResourceCount[i], iRemainingActors) As Int
		iRemainingActors -= iActorCount

		; Get the max possible happiness the remaining settlers can have
		Float fCorrectedActorHappiness = CheckActorHappiness(fActorHappiness, bActorFood, bActorWater, bActorBed, bActorShelter)
		
		fTotalHappiness += iActorCount * fCorrectedActorHappiness
		
		if(bRealUpdate)
			ModTrace("[WSFW] 				Settlers with Partial Happiness of " + fCorrectedActorHappiness + ": " + iActorCount)
		endif
		
		i += 1
	EndWhile

	; Add in Robot happiness
	fTotalHappiness += (RobotHappinessLevel * iRobotPopulation)
	
	if(bRealUpdate)
		ModTrace("[WSFW] 				Robot Happiness: " + iRobotPopulation + " Robots, With Base Happiness of: " + RobotHappinessLevel)
	endif
	
	; add "bonus happiness" and any happiness modifiers
	fTotalHappiness += fBonusHappiness
	
	if(bRealUpdate)
		ModTrace("[WSFW] 				Total Bonus Happiness: " + fBonusHappiness)
	endif
	
	; calculate happiness
	; add happiness modifier here - it isn't dependent on population
	fTotalHappiness = math.max(fTotalHappiness/iTotalPopulation + fHappinessModifier, 0)
	
	; don't let happiness exceed 100
	fTotalHappiness = math.min(fTotalHappiness, 100)

	; for now, record this as a rating
	SetAndRestoreActorValue(self, HappinessTarget, fTotalHappiness)
	
	; REAL UPDATE ONLY:
	if(bRealUpdate)
		float fDeltaHappinessFloat = (fTotalHappiness - fCurrentHappiness) * happinessChangeMult
	
		int iDeltaHappiness
		if(fDeltaHappinessFloat < 0)
			iDeltaHappiness = math.floor(fDeltaHappinessFloat)	; how much does happiness want to change?
		else
			iDeltaHappiness = math.ceiling(fDeltaHappinessFloat)	; how much does happiness want to change?
		endif

		if(iDeltaHappiness != 0 && math.abs(iDeltaHappiness) < minHappinessChangePerUpdate)
			; increase delta to the min
			iDeltaHappiness = minHappinessChangePerUpdate * (iDeltaHappiness/math.abs(iDeltaHappiness)) as int
		endif
		
		; update happiness rating on workshop's location
		ModifyActorValue(Self, Happiness, iDeltaHappiness)

		; what is happiness now?
		float fFinalHappiness = GetValue(Happiness)
		
		ModTrace("[WSFW] 				Current Happiness: " + fFinalHappiness)
		ModTrace("[WSFW] 				Target Happiness Long Term: " + fTotalHappiness)
		ModTrace("[WSFW] 				Predicted Happiness Change Tomorrow: " + iDeltaHappiness)
		; achievement
		if(fFinalHappiness >= WorkshopParent.HappinessAchievementValue)
			Game.AddAchievement(WorkshopParent.HappinessAchievementID)
		endif

		; if happiness is below threshold, no longer player-owned
		if(OwnedByPlayer && AllowUnownedFromLowHappiness)
			; issue warning?
			if(fFinalHappiness <= minHappinessWarningThreshold && HappinessWarning == false)
				HappinessWarning = true
				; always show warning first
				WorkshopParent.DisplayMessage(WorkshopParent.WorkshopUnhappinessWarning, NONE, myLocation)
			elseif(fFinalHappiness <= minHappinessThreshold)
				if(WSFW_Setting_AllowSettlementsToLeavePlayerControl.GetValue() == 1.0)
					; Player loses control 
					SetOwnedByPlayer(false)
				endif
			endif

			; clear warning if above threshold
			if(fFinalHappiness > minHappinessClearWarningThreshold && HappinessWarning == true)
				HappinessWarning = false
			endif
		endif

		; happiness modifier tends toward 0 over time
		if(fHappinessModifier != 0)
			float fModifierSign = -1 * (fHappinessModifier/math.abs(fHappinessModifier))
			int iDeltaHappinessModifier
			float fDeltaHappinessModifierFloat = math.abs(fHappinessModifier) * fModifierSign * happinessChangeMult
			if(fDeltaHappinessModifierFloat > 0)
				iDeltaHappinessModifier = math.floor(fDeltaHappinessModifierFloat)	; how much does happiness modifier want to change?
			else
				iDeltaHappinessModifier = math.ceiling(fDeltaHappinessModifierFloat)	; how much does happiness modifier want to change?
			EndIf
			
			if(math.abs(iDeltaHappinessModifier) < happinessBonusChangePerUpdate)
				iDeltaHappinessModifier = (fModifierSign * happinessBonusChangePerUpdate) as int
			endif

			if(iDeltaHappinessModifier > math.abs(fHappinessModifier))
				WorkshopParent.SetHappinessModifier(self, 0)
			else
				WorkshopParent.ModifyHappinessModifier(Self, iDeltaHappinessModifier)
			endif
		endif
	EndIf
	
	if(bRealUpdate)
		ModTrace("[WSFW] 			Completed WSFW_DailyUpdate_AdjustResourceValues  " + Self)
	endif
EndFunction

function DailyUpdateAttractNewSettlers(WorkshopDataScript:WorkshopRatingKeyword[] ratings, DailyUpdateData updateData)
	; WSFW - Handled by our NPCManager now
	return
endFunction

function DailyUpdateProduceResources(WorkshopDataScript:WorkshopRatingKeyword[] ratings, DailyUpdateData updateData, ObjectReference containerRef, bool bRealUpdate)
	; WSFW Handled by our WorkshopProductionManager and WSFW_DailyUpdate_AdjustResourceValues
	return
endFunction

function DailyUpdateConsumeResources(WorkshopDataScript:WorkshopRatingKeyword[] ratings, DailyUpdateData updateData, ObjectReference containerRef, bool bRealUpdate)
	; WSFW - This is now handled by our WorkshopProductionManager and WSFW_DailyUpdate_AdjustResourceValues
	return
endFunction

function DailyUpdateSurplusResources(WorkshopDataScript:WorkshopRatingKeyword[] ratings, DailyUpdateData updateData, ObjectReference containerRef)
	; WSFW - This is now handled by our WorkshopProductionManager script
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

	if(iCurrentWorkshopID == workshopID && WorkshopParent.UFO4P_IsWorkshopLoaded(self) == false)
		iCurrentWorkshopID = -1
	endif

	if(currentDamage > 0)
		; amount repaired
		; scale this by population (uninjured) - unless this is population
		float repairAmount = 1
		
		if(damageRating != DamagePopulation)
			repairAmount = CalculateRepairAmount(ratings)
			repairAmount = math.Max(repairAmount, 1.0)
		else
			; if this is population, try to heal an actor:
			; are any of this workshop's NPC assigned to caravans?
			Location[] linkedLocations = myLocation.GetAllLinkedLocations(WorkshopCaravanKeyword)
			if(linkedLocations.Length > 0)
				; there is at least 1 actor - find them
				; loop through caravan actors
				int index = 0
				while(index < WorkshopParent.CaravanActorAliases.GetCount())
					; check this actor - is he owned by this workshop?
					; WSFW 2.0.0 - Switch this section to use our global functions that avoid WorkshopNPCScript
					Actor caravanActor = WorkshopParent.CaravanActorAliases.GetAt(index) as Actor
					
					if(caravanActor && WorkshopFramework:WorkshopFunctions.GetWorkshopID(caravanActor) == workshopID && WorkshopFramework:WorkshopFunctions.IsWounded(caravanActor))
						; is this actor wounded? if so heal and exit
						WorkshopFramework:WorkshopFunctions.WoundActor(caravanActor, false, abRecalculateResources = false)
						
						return
					endif
					index += 1
				endwhile
			endif

			; if this is the current workshop, we can try to heal one of the actors (otherwise we don't have them)
			if(workshopID == iCurrentWorkshopID)
				int i = 0
				ObjectReference[] WorkshopActors = WorkshopParent.GetWorkshopActors(self)
				while(i < WorkshopActors.Length)
					; WSFW 2.0.0 - Switch this section to use our global functions that avoid WorkshopNPCScript
					Actor theActor = WorkshopActors[i] as Actor
					if(theActor && WorkshopFramework:WorkshopFunctions.IsWounded(theActor))
						; is this actor wounded? if so heal and exit
						WorkshopFramework:WorkshopFunctions.WoundActor(theActor, false, abRecalculateResources = false)
						
						return
					endif
					i += 1
				endWhile
			endif
		endif

		
		repairAmount = math.min(repairAmount, currentDamage)
		ModifyActorValue(self, damageRating, repairAmount*-1.0)
			
		; if this is the current workshop, find an object to repair (otherwise we don't have them)
		if(workshopID == iCurrentWorkshopID && damageRating != DamagePopulation)
			int i = 0
			; want only damaged objects that produce this resource
			ObjectReference[] ResourceObjects = GetWorkshopResourceObjects(akAV = resourceValue, aiOption = 1)
			while(i < ResourceObjects.Length && repairAmount > 0)
				WorkShopObjectScript theObject = ResourceObjects[i] as WorkShopObjectScript
				float damage = theObject.GetResourceDamage(resourceValue)
				
				if(damage > 0)
					float modDamage = math.min(repairAmount, damage)*-1.0
					if(theObject.ModifyResourceDamage(resourceValue, modDamage))
						repairAmount += modDamage
					endif
				endif
				i += 1
			endWhile
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


; WSFW - Copy from WorkshopParent, which will use local version of maxAttackStrength 
int function CalculateAttackStrength(int foodRating, int waterRating)
	; attack strength: based on "juiciness" of target
	int attackStrength = math.min(foodRating + waterRating, maxAttackStrength) as int
	int attackStrengthMin = attackStrength/2 * -1
	int attackStrengthMax = attackStrength/2
	
	attackStrength = math.min(attackStrength + utility.randomInt(attackStrengthMin, attackStrengthMax), maxAttackStrength) as int
	
	return attackStrength
endFunction


; WSFW - Copy from WorkShopParent, which will use local version of maxDefenseStrength
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
; WSFW - Undid the UFO4P Change to this function as it assumed that the maxHappinessNoFood/maxHappinessNoWater are always less than maxHappinessNoShelter - which isn't necessarily true now that we've converted them to controllable properties
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
	
	;UFO4P 2.0.4 Bug #24122: replaced the previous line with the following line:
	;While in workshop mode, the player's current location is 'none' (entering/leaving workshop mode triggers a location change event). Thus,
	;the location check alone is not reliable and may result in the resource calculation never running at all if the player spends extended
	;periods of time in workshop mode.
	if bOnlyIfLocationLoaded == false || Game.GetPlayer().GetCurrentLocation() == myLocation || UFO4P_InWorkshopMode == true
	
		RecalculateResources()
		
		;  WSFW - 1.1.7 | Unowned workshops do not appear to correctly calculate Safety objects - this is a problem for Nukaworld Vassal settlements
		if( ! OwnedByPlayer)
			ObjectReference[] SafetyObjects = GetWorkshopResourceObjects(Safety)
			Float fSafetyValue = 0.0
			
			int i = 0
			while(i < SafetyObjects.Length)
				if( ! SafetyObjects[i].IsDisabled())
					Float fValue = SafetyObjects[i].GetValue(Safety)
					fSafetyValue += fValue
				endif

				i += 1
			endWhile

			SetValue(WSFW_Safety, fSafetyValue)
		endif
		
		; WSFW 1.1.8 - Add up PowerRequired and store on workshop
		ObjectReference[] PowerReqObjects = FindAllReferencesWithKeyword(WorkshopCanBePowered, 20000.0)
		Float fPowerRequired = 0.0
		Keyword WorkshopItemKeyword = WorkshopParent.WorkshopItemKeyword
		int i = 0
		while(i < PowerReqObjects.Length)
			if( ! PowerReqObjects[i].IsDisabled() && PowerReqObjects[i].GetLinkedRef(WorkshopItemKeyword) == Self)
				Float fValue = PowerReqObjects[i].GetValue(PowerRequired)
				fPowerRequired += fValue
			endif

			i += 1
		endWhile

		SetValue(WSFW_PowerRequired, fPowerRequired)		
		
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


; WSFW - Patch 1.0.3
Function FillWSFWVars() 
	bWSFWVarsFilled = true
	
	if( ! WSFW_Setting_minProductivity)
		WSFW_Setting_minProductivity = Game.GetFormFromFile(iFormID_Setting_minProductivity, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_productivityHappinessMult)
		WSFW_Setting_productivityHappinessMult = Game.GetFormFromFile(iFormID_Setting_productivityHappinessMult, sWSFW_Plugin) as GlobalVariable
	endif
	
	if( ! WSFW_Setting_maxHappinessNoFood)
		WSFW_Setting_maxHappinessNoFood = Game.GetFormFromFile(iFormID_Setting_maxHappinessNoFood, sWSFW_Plugin) as GlobalVariable
	endif
	
	if( ! WSFW_Setting_maxHappinessNoWater)
		WSFW_Setting_maxHappinessNoWater = Game.GetFormFromFile(iFormID_Setting_maxHappinessNoWater, sWSFW_Plugin) as GlobalVariable
	endif
	
	if( ! WSFW_Setting_maxHappinessNoShelter)
		WSFW_Setting_maxHappinessNoShelter = Game.GetFormFromFile(iFormID_Setting_maxHappinessNoShelter, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_happinessBonusFood)
		WSFW_Setting_happinessBonusFood = Game.GetFormFromFile(iFormID_Setting_happinessBonusFood, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_happinessBonusWater)
		WSFW_Setting_happinessBonusWater = Game.GetFormFromFile(iFormID_Setting_happinessBonusWater, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_happinessBonusBed)
		WSFW_Setting_happinessBonusBed = Game.GetFormFromFile(iFormID_Setting_happinessBonusBed, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_happinessBonusShelter)
		WSFW_Setting_happinessBonusShelter = Game.GetFormFromFile(iFormID_Setting_happinessBonusShelter, sWSFW_Plugin) as GlobalVariable
	endif
	
	if( ! WSFW_Setting_happinessBonusSafety)
		WSFW_Setting_happinessBonusSafety = Game.GetFormFromFile(iFormID_Setting_happinessBonusSafety, sWSFW_Plugin) as GlobalVariable
	endif
	
	if( ! WSFW_Setting_minHappinessChangePerUpdate)
		WSFW_Setting_minHappinessChangePerUpdate = Game.GetFormFromFile(iFormID_Setting_minHappinessChangePerUpdate, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_happinessChangeMult)
		WSFW_Setting_happinessChangeMult = Game.GetFormFromFile(iFormID_Setting_happinessChangeMult, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_minHappinessThreshold)
		WSFW_Setting_minHappinessThreshold = Game.GetFormFromFile(iFormID_Setting_minHappinessThreshold, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_minHappinessWarningThreshold)
		WSFW_Setting_minHappinessWarningThreshold = Game.GetFormFromFile(iFormID_Setting_minHappinessWarningThreshold, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_minHappinessClearWarningThreshold)
		WSFW_Setting_minHappinessClearWarningThreshold = Game.GetFormFromFile(iFormID_Setting_minHappinessClearWarningThreshold, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_happinessBonusChangePerUpdate)
		WSFW_Setting_happinessBonusChangePerUpdate = Game.GetFormFromFile(iFormID_Setting_happinessBonusChangePerUpdate, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_maxStoredFoodBase)
		WSFW_Setting_maxStoredFoodBase = Game.GetFormFromFile(iFormID_Setting_maxStoredFoodBase, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_maxStoredFoodPerPopulation)
		WSFW_Setting_maxStoredFoodPerPopulation = Game.GetFormFromFile(iFormID_Setting_maxStoredFoodPerPopulation, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_maxStoredWaterBase)
		WSFW_Setting_maxStoredWaterBase = Game.GetFormFromFile(iFormID_Setting_maxStoredWaterBase, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_maxStoredWaterPerPopulation)
		WSFW_Setting_maxStoredWaterPerPopulation = Game.GetFormFromFile(iFormID_Setting_maxStoredWaterPerPopulation, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_maxStoredScavengeBase)
		WSFW_Setting_maxStoredScavengeBase = Game.GetFormFromFile(iFormID_Setting_maxStoredScavengeBase, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_maxStoredScavengePerPopulation)
		WSFW_Setting_maxStoredScavengePerPopulation = Game.GetFormFromFile(iFormID_Setting_maxStoredScavengePerPopulation, sWSFW_Plugin) as GlobalVariable
	endif
	
	if( ! WSFW_Setting_brahminProductionBoost)
		WSFW_Setting_brahminProductionBoost = Game.GetFormFromFile(iFormID_Setting_brahminProductionBoost, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_maxProductionPerBrahmin)
		WSFW_Setting_maxProductionPerBrahmin = Game.GetFormFromFile(iFormID_Setting_maxProductionPerBrahmin, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_maxBrahminFertilizerProduction)
		WSFW_Setting_maxBrahminFertilizerProduction = Game.GetFormFromFile(iFormID_Setting_maxBrahminFertilizerProduction, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_maxStoredFertilizerBase)
		WSFW_Setting_maxStoredFertilizerBase = Game.GetFormFromFile(iFormID_Setting_maxStoredFertilizerBase, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_minVendorIncomePopulation)
		WSFW_Setting_minVendorIncomePopulation = Game.GetFormFromFile(iFormID_Setting_minVendorIncomePopulation, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_maxVendorIncome)
		WSFW_Setting_maxVendorIncome = Game.GetFormFromFile(iFormID_Setting_maxVendorIncome, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_vendorIncomePopulationMult)
		WSFW_Setting_vendorIncomePopulationMult = Game.GetFormFromFile(iFormID_Setting_vendorIncomePopulationMult, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_vendorIncomeBaseMult)
		WSFW_Setting_vendorIncomeBaseMult = Game.GetFormFromFile(iFormID_Setting_vendorIncomeBaseMult, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_iMaxSurplusNPCs)
		WSFW_Setting_iMaxSurplusNPCs = Game.GetFormFromFile(iFormID_Setting_iMaxSurplusNPCs, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_attractNPCDailyChance)
		WSFW_Setting_attractNPCDailyChance = Game.GetFormFromFile(iFormID_Setting_attractNPCDailyChance, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_iMaxBonusAttractChancePopulation)
		WSFW_Setting_iMaxBonusAttractChancePopulation = Game.GetFormFromFile(iFormID_Setting_iMaxBonusAttractChancePopulation, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_iBaseMaxNPCs)
		WSFW_Setting_iBaseMaxNPCs = Game.GetFormFromFile(iFormID_Setting_iBaseMaxNPCs, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_attractNPCHappinessMult)
		WSFW_Setting_attractNPCHappinessMult = Game.GetFormFromFile(iFormID_Setting_attractNPCHappinessMult, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_attackChanceBase)
		WSFW_Setting_attackChanceBase = Game.GetFormFromFile(iFormID_Setting_attackChanceBase, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_attackChanceResourceMult)
		WSFW_Setting_attackChanceResourceMult = Game.GetFormFromFile(iFormID_Setting_attackChanceResourceMult, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_attackChanceSafetyMult)
		WSFW_Setting_attackChanceSafetyMult = Game.GetFormFromFile(iFormID_Setting_attackChanceSafetyMult, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_attackChancePopulationMult)
		WSFW_Setting_attackChancePopulationMult = Game.GetFormFromFile(iFormID_Setting_attackChancePopulationMult, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_minDaysSinceLastAttack)
		WSFW_Setting_minDaysSinceLastAttack = Game.GetFormFromFile(iFormID_Setting_minDaysSinceLastAttack, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_damageDailyRepairBase)
		WSFW_Setting_damageDailyRepairBase = Game.GetFormFromFile(iFormID_Setting_damageDailyRepairBase, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_damageDailyPopulationMult)
		WSFW_Setting_damageDailyPopulationMult = Game.GetFormFromFile(iFormID_Setting_damageDailyPopulationMult, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_iBaseMaxBrahmin)
		WSFW_Setting_iBaseMaxBrahmin = Game.GetFormFromFile(iFormID_Setting_iBaseMaxBrahmin, sWSFW_Plugin) as GlobalVariable
	endif
	
	if( ! WSFW_Setting_iBaseMaxSynths)
		WSFW_Setting_iBaseMaxSynths = Game.GetFormFromFile(iFormID_Setting_iBaseMaxSynths, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_recruitmentGuardChance)
		WSFW_Setting_recruitmentGuardChance = Game.GetFormFromFile(iFormID_Setting_recruitmentGuardChance, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_recruitmentBrahminChance)
		WSFW_Setting_recruitmentBrahminChance = Game.GetFormFromFile(iFormID_Setting_recruitmentBrahminChance, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_recruitmentSynthChance)
		WSFW_Setting_recruitmentSynthChance = Game.GetFormFromFile(iFormID_Setting_recruitmentSynthChance, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_actorDeathHappinessModifier)
		WSFW_Setting_actorDeathHappinessModifier = Game.GetFormFromFile(iFormID_Setting_actorDeathHappinessModifier, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_maxAttackStrength)
		WSFW_Setting_maxAttackStrength = Game.GetFormFromFile(iFormID_Setting_maxAttackStrength, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_maxDefenseStrength)
		WSFW_Setting_maxDefenseStrength = Game.GetFormFromFile(iFormID_Setting_maxDefenseStrength, sWSFW_Plugin) as GlobalVariable
	endif
	
	; 1.0.5
	if( ! WSFW_Setting_ShelterMechanic)
		WSFW_Setting_ShelterMechanic = Game.GetFormFromFile(iFormID_Setting_ShelterMechanic, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_Setting_AdjustMaxNPCsByCharisma)
		WSFW_Setting_AdjustMaxNPCsByCharisma = Game.GetFormFromFile(iFormID_Setting_AdjustMaxNPCsByCharisma, sWSFW_Plugin) as GlobalVariable
	endif
	
	if( ! WSFW_Setting_CapMaxNPCsByBedCount)
		WSFW_Setting_CapMaxNPCsByBedCount = Game.GetFormFromFile(iFormID_Setting_CapMaxNPCsByBedCount, sWSFW_Plugin) as GlobalVariable
	endif	

	if( ! WSFW_Setting_RobotHappinessLevel)
		WSFW_Setting_RobotHappinessLevel = Game.GetFormFromFile(iFormID_Setting_RobotHappinessLevel, sWSFW_Plugin) as GlobalVariable
	endif
	
	if( ! WSFW_Setting_AllowSettlementsToLeavePlayerControl)
		WSFW_Setting_AllowSettlementsToLeavePlayerControl = Game.GetFormFromFile(iFormID_Setting_AllowSettlementsToLeavePlayerControl, sWSFW_Plugin) as GlobalVariable
	endif

	if( ! WSFW_AV_minProductivity)
		WSFW_AV_minProductivity = Game.GetFormFromFile(iFormID_AV_minProductivity, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_productivityHappinessMult)
		WSFW_AV_productivityHappinessMult = Game.GetFormFromFile(iFormID_AV_productivityHappinessMult, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_maxHappinessNoFood)
		WSFW_AV_maxHappinessNoFood = Game.GetFormFromFile(iFormID_AV_maxHappinessNoFood, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_maxHappinessNoWater)
		WSFW_AV_maxHappinessNoWater = Game.GetFormFromFile(iFormID_AV_maxHappinessNoWater, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_maxHappinessNoShelter)
		WSFW_AV_maxHappinessNoShelter = Game.GetFormFromFile(iFormID_AV_maxHappinessNoShelter, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_happinessBonusFood)
		WSFW_AV_happinessBonusFood = Game.GetFormFromFile(iFormID_AV_happinessBonusFood, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_happinessBonusWater)
		WSFW_AV_happinessBonusWater = Game.GetFormFromFile(iFormID_AV_happinessBonusWater, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_happinessBonusBed)
		WSFW_AV_happinessBonusBed = Game.GetFormFromFile(iFormID_AV_happinessBonusBed, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_happinessBonusShelter)
		WSFW_AV_happinessBonusShelter = Game.GetFormFromFile(iFormID_AV_happinessBonusShelter, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_happinessBonusSafety)
		WSFW_AV_happinessBonusSafety = Game.GetFormFromFile(iFormID_AV_happinessBonusSafety, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_minHappinessChangePerUpdate)
		WSFW_AV_minHappinessChangePerUpdate = Game.GetFormFromFile(iFormID_AV_minHappinessChangePerUpdate, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_happinessChangeMult)
		WSFW_AV_happinessChangeMult = Game.GetFormFromFile(iFormID_AV_happinessChangeMult, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_happinessBonusChangePerUpdate)
		WSFW_AV_happinessBonusChangePerUpdate = Game.GetFormFromFile(iFormID_AV_happinessBonusChangePerUpdate, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_maxStoredFoodBase)
		WSFW_AV_maxStoredFoodBase = Game.GetFormFromFile(iFormID_AV_maxStoredFoodBase, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_maxStoredFoodPerPopulation)
		WSFW_AV_maxStoredFoodPerPopulation = Game.GetFormFromFile(iFormID_AV_maxStoredFoodPerPopulation, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_maxStoredWaterBase)
		WSFW_AV_maxStoredWaterBase = Game.GetFormFromFile(iFormID_AV_maxStoredWaterBase, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_maxStoredWaterPerPopulation)
		WSFW_AV_maxStoredWaterPerPopulation = Game.GetFormFromFile(iFormID_AV_maxStoredWaterPerPopulation, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_maxStoredScavengeBase)
		WSFW_AV_maxStoredScavengeBase = Game.GetFormFromFile(iFormID_AV_maxStoredScavengeBase, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_maxStoredScavengePerPopulation)
		WSFW_AV_maxStoredScavengePerPopulation = Game.GetFormFromFile(iFormID_AV_maxStoredScavengePerPopulation, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_brahminProductionBoost)
		WSFW_AV_brahminProductionBoost = Game.GetFormFromFile(iFormID_AV_brahminProductionBoost, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_maxProductionPerBrahmin)
		WSFW_AV_maxProductionPerBrahmin = Game.GetFormFromFile(iFormID_AV_maxProductionPerBrahmin, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_maxBrahminFertilizerProduction)
		WSFW_AV_maxBrahminFertilizerProduction = Game.GetFormFromFile(iFormID_AV_maxBrahminFertilizerProduction, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_maxStoredFertilizerBase)
		WSFW_AV_maxStoredFertilizerBase = Game.GetFormFromFile(iFormID_AV_maxStoredFertilizerBase, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_minVendorIncomePopulation)
		WSFW_AV_minVendorIncomePopulation = Game.GetFormFromFile(iFormID_AV_minVendorIncomePopulation, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_maxVendorIncome)
		WSFW_AV_maxVendorIncome = Game.GetFormFromFile(iFormID_AV_maxVendorIncome, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_vendorIncomePopulationMult)
		WSFW_AV_vendorIncomePopulationMult = Game.GetFormFromFile(iFormID_AV_vendorIncomePopulationMult, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_vendorIncomeBaseMult)
		WSFW_AV_vendorIncomeBaseMult = Game.GetFormFromFile(iFormID_AV_vendorIncomeBaseMult, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_iMaxSurplusNPCs)
		WSFW_AV_iMaxSurplusNPCs = Game.GetFormFromFile(iFormID_AV_iMaxSurplusNPCs, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_attractNPCDailyChance)
		WSFW_AV_attractNPCDailyChance = Game.GetFormFromFile(iFormID_AV_attractNPCDailyChance, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_iMaxBonusAttractChancePopulation)
		WSFW_AV_iMaxBonusAttractChancePopulation = Game.GetFormFromFile(iFormID_AV_iMaxBonusAttractChancePopulation, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_iBaseMaxNPCs)
		WSFW_AV_iBaseMaxNPCs = Game.GetFormFromFile(iFormID_AV_iBaseMaxNPCs, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_attractNPCHappinessMult)
		WSFW_AV_attractNPCHappinessMult = Game.GetFormFromFile(iFormID_AV_attractNPCHappinessMult, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_attackChanceBase)
		WSFW_AV_attackChanceBase = Game.GetFormFromFile(iFormID_AV_attackChanceBase, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_attackChanceResourceMult)
		WSFW_AV_attackChanceResourceMult = Game.GetFormFromFile(iFormID_AV_attackChanceResourceMult, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_attackChanceSafetyMult)
		WSFW_AV_attackChanceSafetyMult = Game.GetFormFromFile(iFormID_AV_attackChanceSafetyMult, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_attackChancePopulationMult)
		WSFW_AV_attackChancePopulationMult = Game.GetFormFromFile(iFormID_AV_attackChancePopulationMult, sWSFW_Plugin) as ActorValue
	endif
	
	if( ! WSFW_AV_minDaysSinceLastAttack)
		WSFW_AV_minDaysSinceLastAttack = Game.GetFormFromFile(iFormID_AV_minDaysSinceLastAttack, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_damageDailyRepairBase)
		WSFW_AV_damageDailyRepairBase = Game.GetFormFromFile(iFormID_AV_damageDailyRepairBase, sWSFW_Plugin) as ActorValue
	endif
	
	if( ! WSFW_AV_damageDailyPopulationMult)
		WSFW_AV_damageDailyPopulationMult = Game.GetFormFromFile(iFormID_AV_damageDailyPopulationMult, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_ExtraNeeds_Food)
		WSFW_AV_ExtraNeeds_Food = Game.GetFormFromFile(iFormID_AV_ExtraNeeds_Food, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_ExtraNeeds_Safety)
		WSFW_AV_ExtraNeeds_Safety = Game.GetFormFromFile(iFormID_AV_ExtraNeeds_Safety, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_ExtraNeeds_Water)
		WSFW_AV_ExtraNeeds_Water = Game.GetFormFromFile(iFormID_AV_ExtraNeeds_Water, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_ExtraNeeds_Water)
		WSFW_AV_ExtraNeeds_Water = Game.GetFormFromFile(iFormID_AV_ExtraNeeds_Water, sWSFW_Plugin) as ActorValue
	endif
	
	if( ! WSFW_AV_iBaseMaxBrahmin)
		WSFW_AV_iBaseMaxBrahmin = Game.GetFormFromFile(iFormID_AV_iBaseMaxBrahmin, sWSFW_Plugin) as ActorValue
	endif
	
	if( ! WSFW_AV_iBaseMaxSynths)
		WSFW_AV_iBaseMaxSynths = Game.GetFormFromFile(iFormID_AV_iBaseMaxSynths, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_recruitmentGuardChance)
		WSFW_AV_recruitmentGuardChance = Game.GetFormFromFile(iFormID_AV_recruitmentGuardChance, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_recruitmentBrahminChance)
		WSFW_AV_recruitmentBrahminChance = Game.GetFormFromFile(iFormID_AV_recruitmentBrahminChance, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_recruitmentSynthChance)
		WSFW_AV_recruitmentSynthChance = Game.GetFormFromFile(iFormID_AV_recruitmentSynthChance, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_actorDeathHappinessModifier)
		WSFW_AV_actorDeathHappinessModifier = Game.GetFormFromFile(iFormID_AV_actorDeathHappinessModifier, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_maxAttackStrength)
		WSFW_AV_maxAttackStrength = Game.GetFormFromFile(iFormID_AV_maxAttackStrength, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_maxDefenseStrength)
		WSFW_AV_maxDefenseStrength = Game.GetFormFromFile(iFormID_AV_maxDefenseStrength, sWSFW_Plugin) as ActorValue
	endif

	if( ! WSFW_AV_RobotHappinessLevel)
		WSFW_AV_RobotHappinessLevel = Game.GetFormFromFile(iFormID_AV_RobotHappinessLevel, sWSFW_Plugin) as ActorValue
	endif
	
	if( ! ControlManager) ; 1.1.0
		ControlManager = Game.GetFormFromFile(iFormID_ControlManger, sWSFW_Plugin) as WorkshopFramework:WorkshopControlManager
	endif
	
	if( ! WSFW_Safety)
		WSFW_Safety = Game.GetFormFromFile(iFormID_WSFW_Safety, sWSFW_Plugin) as ActorValue
	endif
	
	if( ! WSFW_PowerRequired)
		WSFW_PowerRequired = Game.GetFormFromFile(iFormID_WSFW_PowerRequired, sWSFW_Plugin) as ActorValue
	endif
	
	;
	; Fallout4.esm
	;
	if( ! CurrentWorkshopID)
		CurrentWorkshopID = Game.GetFormFromFile(iFormID_CurrentWorkshopID, sFO4_Plugin) as GlobalVariable
	endif

	if( ! Happiness)
		Happiness = Game.GetFormFromFile(iFormID_Happiness, sFO4_Plugin) as ActorValue
	endif

	if( ! BonusHappiness)
		BonusHappiness = Game.GetFormFromFile(iFormID_BonusHappiness, sFO4_Plugin) as ActorValue
	endif
	
	if( ! HappinessTarget)
		HappinessTarget = Game.GetFormFromFile(iFormID_HappinessTarget, sFO4_Plugin) as ActorValue
	endif

	if( ! HappinessModifier)
		HappinessModifier = Game.GetFormFromFile(iFormID_HappinessModifier, sFO4_Plugin) as ActorValue
	endif

	if( ! Population)
		Population = Game.GetFormFromFile(iFormID_Population, sFO4_Plugin) as ActorValue
	endif

	if( ! DamagePopulation)
		DamagePopulation = Game.GetFormFromFile(iFormID_DamagePopulation, sFO4_Plugin) as ActorValue
	endif

	if( ! Food)
		Food = Game.GetFormFromFile(iFormID_Food, sFO4_Plugin) as ActorValue
	endif

	if( ! DamageFood)
		DamageFood = Game.GetFormFromFile(iFormID_DamageFood, sFO4_Plugin) as ActorValue
	endif

	if( ! FoodActual)
		FoodActual = Game.GetFormFromFile(iFormID_FoodActual, sFO4_Plugin) as ActorValue
	endif

	if( ! MissingFood)
		MissingFood = Game.GetFormFromFile(iFormID_MissingFood, sFO4_Plugin) as ActorValue
	endif

	if( ! Power)
		Power = Game.GetFormFromFile(iFormID_Power, sFO4_Plugin) as ActorValue
	endif
	
	if( ! PowerRequired)
		PowerRequired = Game.GetFormFromFile(iFormID_PowerRequired, sFO4_Plugin) as ActorValue
	endif

	if( ! Water)
		Water = Game.GetFormFromFile(iFormID_Water, sFO4_Plugin) as ActorValue
	endif

	if( ! MissingWater)
		MissingWater = Game.GetFormFromFile(iFormID_MissingWater, sFO4_Plugin) as ActorValue
	endif

	if( ! Safety)
		Safety = Game.GetFormFromFile(iFormID_Safety, sFO4_Plugin) as ActorValue
	endif

	if( ! DamageSafety)
		DamageSafety = Game.GetFormFromFile(iFormID_DamageSafety, sFO4_Plugin) as ActorValue
	endif

	if( ! MissingSafety)
		MissingSafety = Game.GetFormFromFile(iFormID_MissingSafety, sFO4_Plugin) as ActorValue
	endif

	if( ! LastAttackDaysSince)
		LastAttackDaysSince = Game.GetFormFromFile(iFormID_LastAttackDaysSince, sFO4_Plugin) as ActorValue
	endif

	if( ! WorkshopPlayerLostControl)
		WorkshopPlayerLostControl = Game.GetFormFromFile(iFormID_WorkshopPlayerLostControl, sFO4_Plugin) as ActorValue
	endif

	if( ! WorkshopPlayerOwnership)
		WorkshopPlayerOwnership = Game.GetFormFromFile(iFormID_WorkshopPlayerOwnership, sFO4_Plugin) as ActorValue
	endif

	if( ! PopulationRobots)
		PopulationRobots = Game.GetFormFromFile(iFormID_PopulationRobots, sFO4_Plugin) as ActorValue
	endif

	if( ! PopulationBrahmin)
		PopulationBrahmin = Game.GetFormFromFile(iFormID_PopulationBrahmin, sFO4_Plugin) as ActorValue
	endif

	if( ! PopulationUnassigned)
		PopulationUnassigned = Game.GetFormFromFile(iFormID_PopulationUnassigned, sFO4_Plugin) as ActorValue
	endif

	if( ! VendorIncome)
		VendorIncome = Game.GetFormFromFile(iFormID_VendorIncome, sFO4_Plugin) as ActorValue
	endif

	if( ! DamageCurrent)
		DamageCurrent = Game.GetFormFromFile(iFormID_DamageCurrent, sFO4_Plugin) as ActorValue
	endif

	if( ! Beds)
		Beds = Game.GetFormFromFile(iFormID_Beds, sFO4_Plugin) as ActorValue
	endif
	
	if( ! MissingBeds)
		MissingBeds = Game.GetFormFromFile(iFormID_MissingBeds, sFO4_Plugin) as ActorValue
	endif

	if( ! Caravan)
		Caravan = Game.GetFormFromFile(iFormID_Caravan, sFO4_Plugin) as ActorValue
	endif

	if( ! Radio)
		Radio = Game.GetFormFromFile(iFormID_Radio, sFO4_Plugin) as ActorValue
	endif
	
	if( ! WorkshopHideHappinessBarAV)
		WorkshopHideHappinessBarAV = Game.GetFormFromFile(iFormID_WorkshopGuardPreference, sFO4_Plugin) as ActorValue
	endif
	
	if( ! WorkshopGuardPreference)
		WorkshopGuardPreference = Game.GetFormFromFile(iFormID_WorkshopGuardPreference, sFO4_Plugin) as ActorValue
	endif

	if( ! WorkshopType02)
		WorkshopType02 = Game.GetFormFromFile(iFormID_WorkshopType02, sFO4_Plugin) as Keyword
	endif

	if( ! WorkshopCaravanKeyword)
		WorkshopCaravanKeyword = Game.GetFormFromFile(iFormID_WorkshopCaravanKeyword, sFO4_Plugin) as Keyword
	endif

	if( ! ObjectTypeWater)
		ObjectTypeWater = Game.GetFormFromFile(iFormID_ObjectTypeWater, sFO4_Plugin) as Keyword
	endif

	if( ! ObjectTypeFood)
		ObjectTypeFood = Game.GetFormFromFile(iFormID_ObjectTypeFood, sFO4_Plugin) as Keyword
	endif

	if( ! WorkshopLinkContainer)
		WorkshopLinkContainer = Game.GetFormFromFile(iFormID_WorkshopLinkContainer, sFO4_Plugin) as Keyword
	endif
	
	if( ! WorkshopCanBePowered)
		WorkshopCanBePowered = Game.GetFormFromFile(iFormID_WorkshopCanBePowered, sFO4_Plugin) as Keyword
	endif

	if( ! FarmDiscountFaction)
		FarmDiscountFaction = Game.GetFormFromFile(iFormID_FarmDiscountFaction, sFO4_Plugin) as Faction
	endif

	; 1.1.0
	if( ! PlayerFaction)
		PlayerFaction = Game.GetFormFromFile(iFormID_PlayerFaction, sFO4_Plugin) as Faction
	endif
EndFunction


; 1.1.7 - Low level override to fix an issue with Safety in unowned workshops
Float Function GetValue(ActorValue akAV)
	if(akAV == Safety && ! OwnedByPlayer && WSFW_Safety != None)
		return Parent.GetValue(WSFW_Safety)
	else
		return Parent.GetValue(akAV)
	endif
EndFunction

; 1.1.7 - Low level override to fix an issue with Safety in unowned workshops
Function SetValue(ActorValue akAV, Float afValue)
	if(akAV == None)
		return
	endif	
	
	Parent.SetValue(akAV, afValue)
	
	 ; Also set our version
	if(akAV == Safety && WSFW_Safety != None)
		Parent.SetValue(WSFW_Safety, afValue)
	endif
EndFunction

; 1.1.7 - Low level ovveride to fix an issue with Safety in unowned workshops
Float Function GetBaseValue(ActorValue akAV)
	if(akAV == Safety && ! OwnedByPlayer && WSFW_Safety != None)
		return Parent.GetBaseValue(WSFW_Safety)
	else
		return Parent.GetBaseValue(akAV)
	endif
EndFunction

; 1.1.7 - Low level ovveride to fix an issue with Safety in unowned workshops
Function DamageValue(ActorValue akAV, float afDamage)
	Parent.DamageValue(akAV, afDamage)

	; Also damage WSFW safety
	if(akAV == Safety && WSFW_Safety != None)
		Parent.DamageValue(WSFW_Safety, afDamage)
	endif
EndFunction

; 1.1.7 - Low level ovveride to fix an issue with Safety in unowned workshops
Function ModValue(ActorValue akAV, float afAmount)
	Parent.ModValue(akAV, afAmount)

	; Also mod WSFW safety
	if(akAV == Safety && WSFW_Safety != None)
		Parent.ModValue(WSFW_Safety, afAmount)
	endif
EndFunction

; 1.1.7 - Low level ovveride to fix an issue with Safety in unowned workshops
Function RestoreValue(ActorValue akAV, float afAmount)
	Parent.RestoreValue(akAV, afAmount)

	; Also mod WSFW safety
	if(akAV == Safety)
		if(WSFW_Safety != None)
			Parent.RestoreValue(WSFW_Safety, afAmount)
		endif
	endif
EndFunction



Function _SetMapMarker(ObjectReference akMapMarkerRef)
	myMapMarker = akMapMarkerRef
EndFunction


; WSFW 1.0.8 - Troubleshooting tool
Function DumpVariables()
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_minProductivity )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_productivityHappinessMult  )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_maxHappinessNoFood  )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_maxHappinessNoWater  )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_maxHappinessNoShelter  )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_happinessBonusFood  )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_happinessBonusWater  )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_happinessBonusBed )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_happinessBonusShelter )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_happinessBonusSafety )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_minHappinessChangePerUpdate )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_happinessChangeMult )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_minHappinessThreshold )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_minHappinessWarningThreshold )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_minHappinessClearWarningThreshold )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_happinessBonusChangePerUpdate )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_maxStoredFoodBase )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_maxStoredFoodPerPopulation )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_maxStoredWaterBase )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_maxStoredWaterPerPopulation )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_maxStoredScavengeBase )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_maxStoredScavengePerPopulation )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_brahminProductionBoost )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_maxProductionPerBrahmin )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_maxBrahminFertilizerProduction )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_maxStoredFertilizerBase )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_minVendorIncomePopulation )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_maxVendorIncome )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_vendorIncomePopulationMult )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_vendorIncomeBaseMult )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_iMaxSurplusNPCs )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_attractNPCDailyChance )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_iMaxBonusAttractChancePopulation )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_iBaseMaxNPCs )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_attractNPCHappinessMult )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_attackChanceBase )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_attackChanceResourceMult )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_attackChanceSafetyMult )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_attackChancePopulationMult )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_minDaysSinceLastAttack )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_damageDailyRepairBase )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_damageDailyPopulationMult )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_iBaseMaxBrahmin )	
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_iBaseMaxSynths )	
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_recruitmentGuardChance )	
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_recruitmentBrahminChance )	
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_recruitmentSynthChance )	
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_actorDeathHappinessModifier )	
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_maxAttackStrength )	
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_maxDefenseStrength )	
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_AdjustMaxNPCsByCharisma )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_RobotHappinessLevel )
	ModTrace("[WSFW Var Dump]: " + CurrentWorkshopID )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_AllowSettlementsToLeavePlayerControl )
	ModTrace("[WSFW Var Dump]: " + WSFW_Setting_ShelterMechanic )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_minProductivity )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_productivityHappinessMult  )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_maxHappinessNoFood  )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_maxHappinessNoWater  )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_maxHappinessNoShelter  )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_happinessBonusFood  )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_happinessBonusWater  )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_happinessBonusBed )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_happinessBonusShelter )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_happinessBonusSafety )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_minHappinessChangePerUpdate )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_happinessChangeMult )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_happinessBonusChangePerUpdate )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_maxStoredFoodBase )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_maxStoredFoodPerPopulation )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_maxStoredWaterBase )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_maxStoredWaterPerPopulation )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_maxStoredScavengeBase )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_maxStoredScavengePerPopulation )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_brahminProductionBoost )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_maxProductionPerBrahmin )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_maxBrahminFertilizerProduction )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_maxStoredFertilizerBase )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_minVendorIncomePopulation )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_maxVendorIncome )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_vendorIncomePopulationMult )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_vendorIncomeBaseMult )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_iMaxSurplusNPCs )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_attractNPCDailyChance )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_iMaxBonusAttractChancePopulation )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_iBaseMaxNPCs )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_attractNPCHappinessMult )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_attackChanceBase )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_attackChanceResourceMult )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_attackChanceSafetyMult )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_attackChancePopulationMult )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_minDaysSinceLastAttack )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_damageDailyRepairBase )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_damageDailyPopulationMult )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_ExtraNeeds_Food )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_ExtraNeeds_Safety )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_ExtraNeeds_Water )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_iBaseMaxBrahmin )
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_iBaseMaxSynths )	
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_recruitmentGuardChance )	
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_recruitmentBrahminChance )	
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_recruitmentSynthChance )	
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_actorDeathHappinessModifier )	
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_maxAttackStrength )	
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_maxDefenseStrength )	
	ModTrace("[WSFW Var Dump]: " + WSFW_AV_RobotHappinessLevel )
	ModTrace("[WSFW Var Dump]: " + Happiness )
	ModTrace("[WSFW Var Dump]: " + BonusHappiness )
	ModTrace("[WSFW Var Dump]: " + HappinessTarget )
	ModTrace("[WSFW Var Dump]: " + HappinessModifier )
	ModTrace("[WSFW Var Dump]: " + Population )
	ModTrace("[WSFW Var Dump]: " + DamagePopulation )
	ModTrace("[WSFW Var Dump]: " + Food )
	ModTrace("[WSFW Var Dump]: " + DamageFood )
	ModTrace("[WSFW Var Dump]: " + FoodActual )
	ModTrace("[WSFW Var Dump]: " + MissingFood )
	ModTrace("[WSFW Var Dump]: " + Power )
	ModTrace("[WSFW Var Dump]: " + Water )
	ModTrace("[WSFW Var Dump]: " + MissingWater )
	ModTrace("[WSFW Var Dump]: " + Safety )
	ModTrace("[WSFW Var Dump]: " + DamageSafety )
	ModTrace("[WSFW Var Dump]: " + MissingSafety )
	ModTrace("[WSFW Var Dump]: " + LastAttackDaysSince )
	ModTrace("[WSFW Var Dump]: " + WorkshopPlayerLostControl )
	ModTrace("[WSFW Var Dump]: " + WorkshopPlayerOwnership )
	ModTrace("[WSFW Var Dump]: " + PopulationRobots )
	ModTrace("[WSFW Var Dump]: " + PopulationBrahmin )
	ModTrace("[WSFW Var Dump]: " + PopulationUnassigned )
	ModTrace("[WSFW Var Dump]: " + VendorIncome )
	ModTrace("[WSFW Var Dump]: " + DamageCurrent )
	ModTrace("[WSFW Var Dump]: " + Beds )
	ModTrace("[WSFW Var Dump]: " + MissingBeds ) 
	ModTrace("[WSFW Var Dump]: " + Caravan )
	ModTrace("[WSFW Var Dump]: " + Radio )
	ModTrace("[WSFW Var Dump]: " + WorkshopGuardPreference )
	ModTrace("[WSFW Var Dump]: " + WorkshopType02 )
	ModTrace("[WSFW Var Dump]: " + WorkshopCaravanKeyword )
	ModTrace("[WSFW Var Dump]: " + ObjectTypeWater )
	ModTrace("[WSFW Var Dump]: " + ObjectTypeFood )
	ModTrace("[WSFW Var Dump]: " + WorkshopLinkContainer )
	ModTrace("[WSFW Var Dump]: " + FarmDiscountFaction )
endFunction