Scriptname WorkshopParentScript extends Quest Hidden Conditional
{parent workshop script to hold global data}

import CommonArrayFunctions
import WorkshopDataScript
; WSFW - 1.0.4: Getting ModTrace function imported to monitor for some specific issues
import WorkshopFramework:Library:UtilityFunctions
; WSFW - 1.0.8: Getting structures needed for MessageManager quest integration
import WorkshopFramework:Library:DataStructures 

Group WorkshopRatingsGroup
	WorkshopRatingKeyword[] Property WorkshopRatings Auto Const
	{
		0 = food - base production
		1 = happiness (town's happiness rating)
		2 = population
		3 = safety
		4 = water
		5 = power
		6 = beds
		7 = bonus happiness (output from town, used when calculating actual Happiness rating)
		8 = unassigned population (people not assigned to a specific job)
		9 = radio (for now just 1/0 - maybe later it will be "strength" of station or something)
		10 = current damage (current % damage from raider attacks)
		11 = max damage (max % damage from last attack)
		12 = days since last attack (it will be 0 if just attacked)
		13 = current damage to food - resource points that are damaged
		14 = current damage to water - resource points that are damaged
		15 = current damage to safety - resource points that are damaged
		16 = current damage to power - resource points that are damaged
		17 = extra damage to population - number of wounded people. NOTE: total damage = base population value - current population value + extra population damage
		18 = quest-related happiness modifier
		19 = food - actual production
		20 = happiness target - where is happiness headed
		21 = artillery
		22 = current damage to artillery - resource points that are damaged
		23 = last attacking faction ID (see Followers.GetEncDefinition() for list of factions)
		24 = robot population (so, number of humans = population - robot population)
		25 = base income from vendors
		26 = brahmin population - used for food use plus increasing food production
		27 = MISSING food - amount needed for 0 unhappiness from food
		28 = MISSING water - amount needed for 0 unhappiness from water
		29 = MISSING beds - amount needed for 0 unhappiness from beds
		30 = scavenging - general
		31 = scavenging - building materials
		32 = scavenging - machine parts
		33 = scavenging - rare items
		34 = caravan - greater than 0 means on caravan route
		35 = food type - carrot - so that production can match crops
		36 = food type - corn - so that production can match crops
		37 = food type - gourd - so that production can match crops
		38 = food type - melon - so that production can match crops
		39 = food type - mutfruit - so that production can match crops
		40 = food type - razorgrain - so that production can match crops
		41 = food type - tarberry - so that production can match crops
		42 = food type - tato - so that production can match crops
		43 = synth population (meaning hostile Institute agents): > 0 means there's a hidden synth at the settlement
		44 = MISSING safety - amount needed for minimum risk of attack
	}

	; location data keywords
	ActorValue[] Property WorkshopRatingValues Auto
	{ for now this is created at runtime from the actor values in WorkshopRatings array, so we can use Find to get index with actor values }

	WorkshopActorValue[] Property WorkshopResourceAVs Auto
	{ created at runtime - list of resource actor values used by WorkshopObjects }

	; index "enums" to match the above
	int Property WorkshopRatingFood = 0 autoReadOnly
	int Property WorkshopRatingHappiness = 1 autoReadOnly
	int Property WorkshopRatingPopulation = 2 autoReadOnly
	int Property WorkshopRatingSafety = 3 autoReadOnly
	int Property WorkshopRatingWater = 4 autoReadOnly
	int Property WorkshopRatingPower = 5 autoReadOnly
	int Property WorkshopRatingBeds = 6 autoReadOnly
	int Property WorkshopRatingBonusHappiness = 7 autoReadOnly
	int Property WorkshopRatingPopulationUnassigned = 8 autoReadOnly
	int Property WorkshopRatingRadio = 9 autoReadOnly
	int Property WorkshopRatingDamageCurrent = 10 autoReadOnly
	int Property WorkshopRatingDamageMax = 11 autoReadOnly
	int Property WorkshopRatingLastAttackDaysSince = 12 autoReadOnly
	int Property WorkshopRatingDamageFood = 13 autoReadOnly
	int Property WorkshopRatingDamageWater = 14 autoReadOnly
	int Property WorkshopRatingDamageSafety = 15 autoReadOnly
	int Property WorkshopRatingDamagePower = 16 autoReadOnly
	int Property WorkshopRatingDamagePopulation = 17 autoReadOnly
	int Property WorkshopRatingHappinessModifier = 18 autoReadOnly
	int Property WorkshopRatingFoodActual = 19 autoReadOnly
	int Property WorkshopRatingHappinessTarget = 20 autoReadOnly
	int Property WorkshopRatingArtillery = 21 autoReadOnly
	int Property WorkshopRatingDamageArtillery = 22 autoReadOnly
	int Property WorkshopRatingLastAttackFaction = 23 autoReadOnly
	int Property WorkshopRatingPopulationRobots = 24 autoReadOnly
	int Property WorkshopRatingVendorIncome = 25 autoReadOnly
	int Property WorkshopRatingBrahmin = 26 autoReadOnly
	int Property WorkshopRatingMissingFood = 27 autoReadOnly
	int Property WorkshopRatingMissingWater = 28 autoReadOnly
	int Property WorkshopRatingMissingBeds = 29 autoReadOnly
	int Property WorkshopRatingScavengeGeneral = 30 autoReadOnly
	int Property WorkshopRatingScavengeBuilding = 31 autoReadOnly
	int Property WorkshopRatingScavengeParts = 32 autoReadOnly
	int Property WorkshopRatingScavengeRare = 33 autoReadOnly
	int Property WorkshopRatingCaravan = 34 autoReadOnly
	int Property WorkshopRatingFoodTypeCarrot = 35 autoReadOnly
	int Property WorkshopRatingFoodTypeCorn = 36 autoReadOnly
	int Property WorkshopRatingFoodTypeGourd = 37 autoReadOnly
	int Property WorkshopRatingFoodTypeMelon = 38 autoReadOnly
	int Property WorkshopRatingFoodTypeMutfruit = 39 autoReadOnly
	int Property WorkshopRatingFoodTypeRazorgrain = 40 autoReadOnly
	int Property WorkshopRatingFoodTypeTarberry = 41 autoReadOnly
	int Property WorkshopRatingFoodTypeTato = 42 autoReadOnly
	int Property WorkshopRatingPopulationSynths = 43 autoReadOnly
	int Property WorkshopRatingMissingSafety = 44 autoReadOnly

EndGroup

; array of all workshops - set in the editor
; index is the "workshopID" of that workshop
Group WorkshopMasterList
	RefCollectionAlias Property WorkshopsCollection Auto Const
	{ pointer to ref collection of workshops }

	WorkshopScript[] Property Workshops Auto
	{ Array of all workshops
	  index is the "workshopID" of that workshop
	  initialized at runtime
	}
	Location[] Property WorkshopLocations Auto
	{ associated locations - initialized at runtime }	
EndGroup

FormList Property WorkshopCrimeFactions Auto const mandatory
{ used to set crime faction on all workshops that don't have one }

int currentWorkshopID = -1
GlobalVariable Property WorkshopCurrentWorkshopID const auto ; global tracking currentWorkshopID

Group CurrentWorkshopData
	ReferenceAlias Property CurrentWorkshop auto 
	{ current workshop - in this alias }
	ReferenceAlias Property WorkshopCenterMarker Auto
	{center marker of the current workshop, used for packages
	}
	ReferenceAlias Property WorkshopNewSettler Auto const
	{ used for new settler intro scenes }
	ReferenceAlias Property WorkshopSpokesmanAfterRaiderAttack Auto const
	{ used for post raider attack scenes }
EndGroup

Group VendorTypes
	int Property WorkshopTypeMisc = 0 autoReadOnly
	int Property WorkshopTypeArmor = 1 autoReadOnly
	int Property WorkshopTypeWeapons = 2 autoReadOnly
	int Property WorkshopTypeBar = 3 autoReadOnly
	int Property WorkshopTypeClinic = 4 autoReadOnly
	int Property WorkshopTypeClothing = 5 autoReadOnly
	int Property WorkshopTypeChems = 6 autoReadOnly

	WorkshopVendorType[] Property WorkshopVendorTypes Auto Const
	{ array of flags indicating whether the top level vendor is now available }
	int Property VendorTopLevel = 2 auto const
	{ what level makes you a "top level" vendor? Currently there are exactly 3 levels of vendor: 0-2 }
	FormList[] Property WorkshopVendorContainers Auto Const
	{ list of form lists, indexed by VendorType 
		- each form list is indexed by vendor level
	}
EndGroup

Group FarmDiscount 
	Faction Property FarmDiscountFaction const auto mandatory
	{ remove from all settlement NPCs when settlement becomes unallied }
	FarmDiscountVendor[] Property FarmDiscountVendors Auto Const
	{ list of discount vendors }
EndGroup


RefCollectionAlias Property PermanentActorAliases Auto const mandatory
{ref alias collection of non-workshop actors who have been permanently moved to workshops
 the alias gives them a package to keep them at their new workshop "home"
 }

Group TradeCaravans
	RefCollectionAlias Property TradeCaravanWorkshops Auto Const
	{ pointer to ref collection of workshops }
EndGroup

ReferenceAlias Property WorkshopActorApply Auto const mandatory
{used to "stamp" workshop NPCs with alias data (packages, etc.) that they will retain without having to be in the aliases
}

Group Dogmeat
	ReferenceAlias Property DogmeatAlias Auto const mandatory
	{ Dogmeat companion alias - used to check when turning idle scene on and off }
	Scene Property WorkshopDogmeatWhileBuildingScene Auto const mandatory
	{ Dogmeat idle scene }
EndGroup

Group Companion
	ReferenceAlias Property CompanionAlias Auto const mandatory
	{ Companion alias - used to check when turning idle scene on and off }
	Scene Property WorkshopCompanionWhileBuildingScene Auto const mandatory
	{ Companion idle scene }
EndGroup


Group Messages
	ReferenceAlias Property MessageRefAlias Const Auto  mandatory
	{ used for inserting text into messages }
	LocationAlias Property MessageLocationAlias Const Auto mandatory
	{ used for inserting text into messages }
	Message Property WorkshopLosePlayerOwnership const auto mandatory
	Message Property WorkshopGainPlayerOwnership const auto mandatory
	Message Property WorkshopUnhappinessWarning const auto mandatory
	Message Property WorkshopUnownedMessage const auto mandatory
	Message Property WorkshopUnownedHostileMessage const auto mandatory
	Message Property WorkshopUnownedSettlementMessage const auto mandatory
	Message Property WorkshopOwnedMessage const auto mandatory
	Message Property WorkshopTutorialMessageBuild const auto
	Message Property WorkshopResourceAssignedMessage const auto mandatory
	{ message when a resource is successfully assigned }
	Message Property WorkshopResourceNoAssignmentMessage Auto Const mandatory
	{ message that this object can't be assigned to this NPC }
	Message Property WorkshopExitMenuMessage Auto Const mandatory
	{ message the first time you exit workshop mode at each workshop }
EndGroup

Group CaravanActorData
	RefCollectionAlias Property CaravanActorAliases Auto const mandatory
	{ref alias collection of actors assigned to caravans
	 }
	RefCollectionAlias Property CaravanActorRenameAliases Auto const mandatory
	{ref alias collection of actors assigned to caravans - these get renamed "Provisioner"
		(subset of CaravanActorAliases)
	 }
	RefCollectionAlias Property CaravanBrahminAliases Auto const mandatory
	{ref alias collection of brahmins assigned to caravans
	 }
	Keyword Property WorkshopLinkCaravanStart const auto
	{ keyword for linked ref to start marker - used for caravan packages }
	Keyword Property WorkshopLinkCaravanEnd const auto
	{ keyword for linked ref to end marker - used for caravan packages }
	ActorBase Property CaravanBrahmin Auto const mandatory
	{ the pack brahmin that gets autogenerated by caravan actors }
EndGroup
; index to track the highest used index in the CaravanActor array
int caravanActorMaxIndex = 0


Group Keywords
	Keyword Property WorkshopWorkObject Auto Const mandatory
	{ keyword on built object that indicates it is a "work" object for an actor }
	Keyword Property WorkshopAllowCaravan Auto Const mandatory
	{ put this keyword on actors that can be assigned to caravan duty }
	Keyword Property WorkshopAllowCommand Auto Const mandatory
	{ put this keyword on actors that can be commanded to resource objects }
	Keyword Property WorkshopAllowMove Auto Const mandatory
	{ put this keyword on actors that can be moved to different settlements }
	keyword Property WorkshopLinkContainer const auto mandatory
	{ keyword for the linked container that holds workshop resources }
	keyword Property WorkshopLinkSpawn const auto mandatory
	{ keyword for the linked spawn marker for creating new NPCs }
	keyword Property WorkshopLinkCenter const auto mandatory
	{ keyword for the linked center marker }
	keyword Property WorkshopLinkSandbox const auto mandatory
	{ keyword for the linked sandbox primitive }
	keyword Property WorkshopLinkWork const auto mandatory
	{ keyword for actors to editor-set work objects }
	; event keywords:
	Keyword Property WorkshopEventAttack const auto mandatory
	{ keyword for workshop attack radiant quests }
	Keyword Property WorkshopEventRadioBeacon const auto mandatory
	{ keyword for workshop radio beacon quest }
	Keyword Property WorkshopEventInitializeLocation const auto mandatory
	{ keyword for workshop initialization story manager events }
	
	Keyword Property LocTypeWorkshopSettlement const auto mandatory
	{ keyword used to test for workshop locations }
	Keyword Property LocTypeWorkshopRobotsOnly const auto mandatory
	{ keyword used to initialize "robots only" locations (e.g. Graygarden) }
	Keyword Property WorkshopCaravanKeyword const auto mandatory
	{ keyword used for links between workshop locations }
	Keyword Property WorkshopLinkFollow const auto mandatory
	{ keyword used to create dynamic linked refs for follow packages (e.g. caravan brahmin)}
	Keyword Property WorkshopLinkHome const auto mandatory
	{ keyword used to create dynamic linked refs for persistent workshop NPCs - center of their default sandbox package }
	Keyword Property WorkshopItemKeyword Auto Const mandatory
	{ keyword that links all workshop-created items to their workshop }
	FormList Property VendorContainerKeywords Auto Const mandatory
	{ form list of keywords that link vendor containers to the vendor - indexed by vendor level }
	Keyword Property WorkshopAssignCaravan const auto mandatory
	{ keyword sent by interface when assigning an NPC to a caravan destination }
	Keyword Property WorkshopAssignHome const auto mandatory
	{ keyword sent by interface when assigning an NPC to a new home }
	Keyword Property WorkshopAssignHomePermanentActor const auto mandatory
	{ keyword sent by interface when assigning a "permanent" NPC to a new home }
	Keyword Property WorkshopType02 const auto mandatory
	{ default keyword to flag secondary settlement type }
	Keyword Property WorkshopType02Vassal const auto mandatory
	{ default keyword to flag secondary settlement vassals }
	FormList Property WorkshopSettlementMenuExcludeList Auto const mandatory
	{ form list of keywords for secondary settlement types (to exclude them from settlement menu) }
EndGroup

group Globals
	GlobalVariable Property MinutemenRecruitmentAvailable const auto mandatory
	{ number of settlements available for Minutemen recruiting. Updated by UpdateMinutemenRecruitmentAvailable() }
	GlobalVariable Property MinutemenOwnedSettlements const auto mandatory
	{ number of populated settlements owned by Minutemen. Updated by UpdateMinutemenRecruitmentAvailable() }
	GlobalVariable property WorkshopMinRansom auto const mandatory
	GlobalVariable property WorkshopMaxRansom auto const mandatory
	GlobalVariable Property GameHour Auto Const
	GlobalVariable Property PlayerInstitute_Destroyed auto const mandatory
	GlobalVariable Property PlayerInstitute_KickedOut auto const mandatory
	GlobalVariable Property PlayerBeenToInstitute auto const mandatory
	{ used for attack quests - to know if synths can teleport }
EndGroup

group ActorValues
	ActorValue Property Charisma const auto mandatory
	ActorValue Property WorkshopIDActorValue const auto mandatory
	ActorValue Property WorkshopCaravanDestination const auto mandatory
	ActorValue Property WorkshopActorWounded const auto mandatory
	ActorValue Property PowerGenerated const auto mandatory
	ActorValue Property PowerRequired const auto mandatory
	ActorValue Property WorkshopGuardPreference const auto mandatory
	{ base actors with this value will try to guard when first created (instead of farming)}
	ActorValue Property WorkshopActorAssigned const auto mandatory
	{ actors get this value temporarily after being assigned so they will always run their work package }
	ActorValue Property WorkshopFloraHarvestTime const auto mandatory
	{ flora objects get this when harvested, to track when they should "regrow" }
	ActorValue Property WorkshopPlayerOwnership const auto mandatory
	{ actor value used to flag player-owned workshops for use by condition checks }
	ActorValue Property WorkshopPlayerLostControl const auto mandatory
	{ set to 1 on workshops that was friendly to player then became "unfriendly" - set back to 0 when owned status restored
		set to 2 on workshops after first Reset - to indicate that anything that needs to be cleared is taken care of
	 }
	ActorValue Property WorkshopResourceObject Auto Const mandatory
	{ actor value on built object that indicates it is a resource object of some kind
		all objects that the scripted workshop system cares about should have this actor value }
	ActorValue Property WorkshopAttackSAEFaction auto const mandatory
	{ actor value to record the attack faction for WorkshopAttackDialogueFaction
		uses SAE_XXX globals for faction values }
	ActorValue Property WorkshopFastTravel const auto mandatory
	{ actor resource value to prevent building multiple fast travel targets in a single workshop location}
	ActorValue Property WorkshopMaxTriangles auto const
	{ used to set build budget on workshop ref}
	ActorValue Property WorkshopCurrentTriangles auto const
	{ used to set build budget on workshop ref}
	ActorValue Property WorkshopMaxDraws auto const
	{ used to set build budget on workshop ref}
	ActorValue Property WorkshopCurrentDraws auto const
	{ used to set build budget on workshop ref}
	ActorValue Property WorkshopProhibitRename const auto mandatory
	{ actors with this > 0 will not be put in the CaravanActorRenameAliases collection }
EndGroup

Group AchievementData
	globalVariable property AlliedSettlementAchievementCount auto const
	int property AlliedSettlementsForAchievement = 3 auto const
	int property AlliedSettlementAchievementID = 23 auto const
	int property HappinessAchievementValue = 100 auto const
	int property HappinessAchievementID = 24 auto const
endGroup

ReferenceAlias Property PlayerCommentTarget Auto const
{ used for player comment }
Scene Property WorkshopPlayerCommentScene auto const
{ player comment scene }
ReferenceAlias Property WorkshopRecruit Const Auto mandatory
bool Property PlayerOwnsAWorkshop auto Conditional
{ set to true when the player owns ANY workshop - used for dialogue conditions }
int Property CurrentNewSettlerCount auto Conditional
{ how many new settlers at current workshop? }
int Property MaxNewSettlerCount = 4 auto const hidden
{ max number to put into "new settler" collection - don't want massive crowd following player around }
ActorBase Property WorkshopNPC Auto const mandatory
{ the actor that gets created when a settlement makes a successful recruitment roll }
ActorBase Property WorkshopNPCGuard Auto const mandatory
{ sometimes a "guard" NPC gets created instead }
Topic Property WorkshopParentAssignConfirm auto const mandatory hidden
{ OBSOLETE }
Keyword Property WorkshopParentAssignConfirmTopicType auto const mandatory
{ replaces WorkshopParentAssignConfirm topic - shared topic type allows DLC to add new lines more easily }
ActorBase Property WorkshopBrahmin Auto mandatory
{ the workshop brahmin that can be randomly created during recruitment }
Quest Property WorkshopInitializeLocation const auto mandatory
{ quest that initializes workshop locations }
String Property userlogName = "Workshop" Auto Const Hidden
MiscObject Property SynthDeathItem auto const mandatory
{ death item for synths }

Group LeveledItems
	; used when producing resources from workshop objects
	LeveledItem Property WorkshopProduceFood Auto Const mandatory
	LeveledItem Property WorkshopProduceWater Auto Const mandatory
	LeveledItem Property WorkshopProduceScavenge Auto Const mandatory
	LeveledItem Property WorkshopProduceVendorIncome Auto Const mandatory
	LeveledItem Property WorkshopProduceFertilizer Auto Const mandatory

	WorkshopFoodType[] Property WorkshopFoodTypes auto const
	{ array of food types used to produce appropriate food type }
EndGroup

Group Resources
	; used when consuming resources from workshop objects
	Keyword Property WorkshopConsumeFood Auto Const mandatory
	Keyword Property WorkshopConsumeWater Auto Const mandatory
	FormList Property WorkshopConsumeScavenge Auto Const  mandatory			; list of components
EndGroup

Group LocRefTypes
	; used when checking for bosses in order to clear a location
	FormList Property BossLocRefTypeList auto const mandatory
	LocationRefType Property MapMarkerRefType Auto Const mandatory
	LocationRefType Property Boss Auto Const mandatory
	LocationRefType Property WorkshopCaravanRefType Auto Const mandatory
	LocationRefType Property WorkshopSynthRefType Auto Const mandatory
	{ used to flag created synth settlers }
endGroup

Group factions
	Faction Property REIgnoreForCleanup Const Auto mandatory
	{ add actors to this faction to have them ignored during RE cleanup check
	  i.e. quest can clean up even if they are loaded/alive
	}
	Faction Property REDialogueRescued Const Auto mandatory
	{ remove from this faction after RE NPCs are added to workshop }
	Faction Property RaiderFaction const auto mandatory
	{ used for random attacks }
	Faction Property RobotFaction const auto mandatory
	{ used to check for robot actors in daily update etc. }
	Faction Property BrahminFaction const auto mandatory
	{ used to check for brahmin actors in daily update etc. }
	Faction Property PlayerFaction const auto mandatory
	{ assign default ownership to non-assigned workshop objects }
	Faction Property WorkshopAttackDialogueFaction const auto mandatory
	{ used to condition "grateful" dialogue after player helps fight off attackers }
	Faction Property MinRadiantDialogueDisappointed const auto mandatory
	Faction Property MinRadiantDialogueWorried const auto mandatory
	Faction Property MinRadiantDialogueHopeful const auto mandatory
	Faction Property MinRadiantDialogueThankful const auto mandatory
	Faction Property MinRadiantDialogueFailure const auto mandatory
EndGroup

ObjectReference Property WorkshopHoldingCellMarker Const Auto mandatory
{ marker for holding cell - use to place vendor chests }
FollowersScript Property Followers const auto mandatory
{ pointer to Followers quest script for utility functions }


; how large a radius to search for workshop objects/actors? (should be whole loaded area)
int findWorkshopObjectRadius = 5000 const

; how many food points can each NPC work on?
int maxFoodProductionPerFarmer = 10 const ; WSFW Note: Unused

; timer IDs
int dailyUpdateTimerID = 0 const

; update timer
float updateIntervalGameHours = 24.0 const	 ; daily
float dailyUpdateSpreadHours = 12.0 const  	; how many hours to spread out (total) all the daily updates for workshops

float Property dailyUpdateIncrement = 0.0 auto
{ updated during daily update process - how much time in between each workshop's own daily update }


; custom event sent each time an Initialize quest completes, to signal starting the next one
CustomEvent WorkshopInitializeLocation
; custom event sent when DailyUpdate is processed
CustomEvent WorkshopDailyUpdate
; custom event sent when a non-workshop actor is added to a workshop
CustomEvent WorkshopAddActor 
; custom event sent when an actor is assigned to a work object
CustomEvent WorkshopActorAssignedToWork
; custom event sent when an actor is unassigned from a work object
CustomEvent WorkshopActorUnassigned
; custom event sent when a workshop object is built
CustomEvent WorkshopObjectBuilt 
; custom event sent when a workshop object is destroyed (removed from the world)
CustomEvent WorkshopObjectDestroyed
; custom event sent when a workshop object is moved
CustomEvent WorkshopObjectMoved 
; custom event sent when a workshop object is damaged or repaired
CustomEvent WorkshopObjectDestructionStageChanged
; custom event sent when a workshop object is damaged or repaired
CustomEvent WorkshopObjectPowerStageChanged
; custom event sent when a workshop becomes player-owned
CustomEvent WorkshopPlayerOwnershipChanged
; custom event sent when player enters workshop menu
CustomEvent WorkshopEnterMenu 
; custom event sent when a workshop object is repaired
CustomEvent WorkshopObjectRepaired 
; 1.6 custom event sent when an NPC is assigned to a supply line
CustomEvent WorkshopActorCaravanAssign
; 1.6 custom event sent when an NPC is unassigned from a supply line
CustomEvent WorkshopActorCaravanUnassign
; set to true after initializition is complete - so other scripts don't try to use data on this script before then
bool property Initialized = false auto

; set to true while thread-sensitive functions are in progress
bool EditLock = false
; WorkshopScript sets this to true during daily update, other workshops won't do daily updates until this is clear to prevent script overload
bool property DailyUpdateInProgress = false auto hidden

;------------------------------------------------------
;	Added by UFO4P 1.0.3 for Bug #20576:
;------------------------------------------------------

;The game time when the last ResetWorkshop function started running
Float UFO4P_GameTimeOfLastResetStarted = 0.0

;The last workshop location visited by the player
Location UFO4P_PreviousWorkshopLocation = None

;------------------------------------------------------
;	Added by UFO4P 1.0.3 for Bug #20775:
;------------------------------------------------------

;ID for starting a timer on WorkshopScript to handle calls of the DailyUpdate function
int UFO4P_DailyUpdateResetHappinessTimerID = 99
 
;------------------------------------------------------
;	Added by UFO4P 1.0.5 for Bug #21039:
;------------------------------------------------------

;UFO4P 2.0 Bug #21894: With this fix in place, the form list is no longer needed.

;List of all damage helper base objects
;FormList Property UFO4P_WorkshopFloraDamageHelpers auto const

;------------------------------------------------------
;	Added by UFO4P 2.0 for Bug #21895:
;------------------------------------------------------

;Helper bool to delay any daily updates of the workshop scripts while an attack is physically running:
 ; UFO4P 2.0.6: made this a conditional property
bool Property UFO4P_AttackRunning = false auto hidden conditional

int UFO4P_DelayedResetTimerID = 96

WorkshopScript UFO4P_WorkshopRef_ResetDelayed = none


;------------------------------------------------------
;	Added by UFO4P 2.0.6 for Bug #25230:
;------------------------------------------------------

;Needs to be checked by the overseer's job handling terminal
bool Property UFO4P_ResetRunning = false auto hidden conditional

;------------------------------------------------------
;	Added by UFO4P 2.1.0 for Bug #27621:
;------------------------------------------------------

faction Property WorkshopEnemyFaction auto Hidden ; WSFW - Changed to hidden so we can populate it on start

;------------------------------------------------------



; WSFW - Leaving these as straight variables for backwards compatibility, but moving the functional versions to workshop level variables
Int Property recruitmentGuardChance = 20 auto const hidden
Int Property recruitmentBrahminChance = 20 auto const hidden
Int Property recruitmentSynthChance = 10 auto const hidden
Float Property actorDeathHappinessModifier = -20.0 auto const hidden
Int Property maxAttackStrength = 100 auto const hidden
Int Property maxDefenseStrength = 100 auto const hidden


; ------------------------------------------------------
;
; WSFW - Variables converted into editable properties - Likely will convert all these to have globals as well. By doing them as non-Auto properties we can just edit the Property functions to call and set the global values as opposed to having to edit every call throughout the script.
;
; ------------------------------------------------------

Bool Property bUseGlobalTradeCaravanMinimumPopulation = true Auto Hidden
int WSFW_iTradeCaravanMinimumPopulation = 5  ; min population for rolling for a synth
Int Property TradeCaravanMinimumPopulation ; minimum population for a settlement to count as a valid trade caravan destination
	Int Function Get()
		if(bUseGlobalTradeCaravanMinimumPopulation)
			return WSFW_Setting_TradeCaravanMinimumPopulation.GetValueInt()
		else
			return WSFW_iTradeCaravanMinimumPopulation
		endif
	EndFunction
	
	Function Set(Int aiValue)
		WSFW_iTradeCaravanMinimumPopulation = aiValue
	EndFunction
EndProperty
	
	
Bool Property bUseGlobalrecruitmentMinPopulationForSynth = true Auto Hidden
int WSFW_iRecruitmentMinPopulationForSynth = 4  ; min population for rolling for a synth
Int Property recruitmentMinPopulationForSynth
	Int Function Get()
		if(bUseGlobalrecruitmentMinPopulationForSynth)
			return WSFW_Setting_recruitmentMinPopulationForSynth.GetValueInt()
		else
			return WSFW_iRecruitmentMinPopulationForSynth
		endif
	EndFunction
	
	Function Set(Int aiValue)
		WSFW_iRecruitmentMinPopulationForSynth = aiValue
	EndFunction
EndProperty

Bool Property bUseGlobalstartingHappiness = true Auto Hidden
Float WSFW_fStartingHappiness = 50.0  ; happiness of a new workshop starts here
Float Property startingHappiness
	Float Function Get()
		if(bUseGlobalstartingHappiness)
			return WSFW_Setting_startingHappiness.GetValue()
		else
			return WSFW_fStartingHappiness
		endif
	EndFunction
	
	Function Set(Float afValue)
		WSFW_fStartingHappiness = afValue
	EndFunction
EndProperty

Bool Property bUseGlobalstartingHappinessMin = true Auto Hidden
Float WSFW_fStartingHappinessMin = 20.0  ; when resetting happiness, don't start lower than this
Float Property startingHappinessMin
	Float Function Get()
		if(bUseGlobalstartingHappinessMin)
			return WSFW_Setting_startingHappinessMin.GetValue()
		else
			return WSFW_fStartingHappinessMin
		endif
	EndFunction
	
	Function Set(Float afValue)
		WSFW_fStartingHappinessMin = afValue
	EndFunction
EndProperty
	
Bool Property bUseGlobalstartingHappinessTarget = true Auto Hidden	
Float WSFW_fStartingHappinessTarget = 50.0  ; init happiness target to this
Float Property startingHappinessTarget
	Float Function Get()
		if(bUseGlobalstartingHappinessTarget)
			return WSFW_Setting_startingHappinessTarget.GetValue()
		else
			return WSFW_fStartingHappinessTarget
		endif
	EndFunction
	
	Function Set(Float afValue)
		WSFW_fStartingHappinessTarget = afValue
	EndFunction
EndProperty	

Bool Property bUseGlobalresolveAttackMaxAttackRoll = true Auto Hidden	
Int WSFW_iResolveAttackMaxAttackRoll = 150 ; max allowed attack roll when resolving offscreen
Int Property resolveAttackMaxAttackRoll
	Int Function Get()
		if(bUseGlobalresolveAttackMaxAttackRoll)
			return WSFW_Setting_resolveAttackMaxAttackRoll.GetValueInt()
		else
			return WSFW_iResolveAttackMaxAttackRoll
		endif
	EndFunction
	
	Function Set(Int aValue)
		WSFW_iResolveAttackMaxAttackRoll = aValue
	EndFunction
EndProperty

Bool Property bUseGlobalresolveAttackAllowedDamageMin = true Auto Hidden
Float WSFW_fResolveAttackAllowedDamageMin = 25.0 ; this is as low as allowed damage can go when an attack is resolved offscreen
Float Property resolveAttackAllowedDamageMin
	Float Function Get()
		if(bUseGlobalresolveAttackAllowedDamageMin)
			return WSFW_Setting_resolveAttackAllowedDamageMin.GetValue()
		else
			return WSFW_fResolveAttackAllowedDamageMin
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSFW_fResolveAttackAllowedDamageMin = aValue
	EndFunction
EndProperty


Bool Property bUseGlobalworkshopRadioInnerRadius = true Auto Hidden
Float WSFW_fWorkshopRadioInnerRadius = 9000.0
Float Property workshopRadioInnerRadius
	Float Function Get()
		if(bUseGlobalworkshopRadioInnerRadius)
			return WSFW_Setting_workshopRadioInnerRadius.GetValue()
		else
			return WSFW_fWorkshopRadioInnerRadius
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSFW_fWorkshopRadioInnerRadius = aValue
	EndFunction
EndProperty


Bool Property bUseGlobalworkshopRadioOuterRadius = true Auto Hidden
Float WSFW_fWorkshopRadioOuterRadius = 20000.0
Float Property workshopRadioOuterRadius
	Float Function Get()
		if(bUseGlobalworkshopRadioOuterRadius)
			return WSFW_Setting_workshopRadioOuterRadius.GetValue()
		else
			return WSFW_fWorkshopRadioOuterRadius
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSFW_fWorkshopRadioOuterRadius = aValue
	EndFunction
EndProperty


Bool Property bUseGlobalhappinessModifierMax = true Auto Hidden
Float WSFW_fHappinessModifierMax = 40.0
Float Property happinessModifierMax
	Float Function Get()
		if(bUseGlobalhappinessModifierMax)
			return WSFW_Setting_happinessModifierMax.GetValue()
		else
			return WSFW_fHappinessModifierMax
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSFW_fHappinessModifierMax = aValue
	EndFunction
EndProperty


Bool Property bUseGlobalhappinessModifierMin = true Auto Hidden
Float WSFW_fHappinessModifierMin = -50.0
Float Property happinessModifierMin
	Float Function Get()
		if(bUseGlobalhappinessModifierMin)
			return WSFW_Setting_happinessModifierMin.GetValue()
		else
			return WSFW_fHappinessModifierMin
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSFW_fHappinessModifierMin = aValue
	EndFunction
EndProperty



;
; WSFW - New Properties
;

; Store registered custom vendors
CustomVendor[] Property CustomVendorTypes Auto Hidden


Bool Property AutoAssignBeds
	Bool Function Get()
		return (WSFW_Setting_AutoAssignBeds.GetValue() == 1)
	EndFunction
	
	Function Set(Bool aValue)
		if(aValue)
			WSFW_Setting_AutoAssignBeds.SetValue(1)
		else
			WSFW_Setting_AutoAssignBeds.SetValue(0)
		endif
	EndFunction
EndProperty		

Bool Property AutoAssignFood
	Bool Function Get()
		return (WSFW_Setting_AutoAssignFood.GetValue() == 1.0)
	EndFunction
	
	Function Set(Bool aValue)
		if(aValue)
			WSFW_Setting_AutoAssignFood.SetValue(1)
		else
			WSFW_Setting_AutoAssignFood.SetValue(0)
		endif
	EndFunction
EndProperty	

Bool Property AutoAssignDefense
	Bool Function Get()
		return (WSFW_Setting_AutoAssignDefense.GetValue() == 1.0)
	EndFunction
	
	Function Set(Bool aValue)
		if(aValue)
			WSFW_Setting_AutoAssignDefense.SetValue(1)
		else
			WSFW_Setting_AutoAssignDefense.SetValue(0)
		endif
	EndFunction
EndProperty	

Float Property MaxFoodWorkPerSettler
	Float Function Get()
		return WSFW_Setting_MaxFoodWorkPerSettler.GetValue()
	EndFunction
	
	Function Set(Float aValue)
		WSFW_Setting_MaxFoodWorkPerSettler.SetValue(aValue)
	EndFunction
EndProperty	


Float Property MaxDefenseWorkPerSettler
	Float Function Get()
		return WSFW_Setting_MaxDefenseWorkPerSettler.GetValue()
	EndFunction
	
	Function Set(Float aValue)
		WSFW_Setting_MaxDefenseWorkPerSettler.SetValue(aValue)
	EndFunction
EndProperty


; TODO WSWF - add globals for the new vars below
Float WSFW_fAttackDamageToTheftRatio_Food = 1.0
Float Property AttackDamageToTheftRatio_Food
	Float Function Get()
		return WSFW_fAttackDamageToTheftRatio_Food
	EndFunction
	
	Function Set(Float aValue)
		WSFW_fAttackDamageToTheftRatio_Food = aValue
	EndFunction
EndProperty

Float WSFW_fAttackDamageToTheftRatio_Water = 1.0
Float Property AttackDamageToTheftRatio_Water
	Float Function Get()
		return WSFW_fAttackDamageToTheftRatio_Water
	EndFunction
	
	Function Set(Float aValue)
		WSFW_fAttackDamageToTheftRatio_Water = aValue
	EndFunction
EndProperty

Float WSFW_fAttackDamageToTheftRatio_Scrap = 1.0
Float Property AttackDamageToTheftRatio_Scrap
	Float Function Get()
		return WSFW_fAttackDamageToTheftRatio_Scrap
	EndFunction
	
	Function Set(Float aValue)
		WSFW_fAttackDamageToTheftRatio_Scrap = aValue
	EndFunction
EndProperty


Float WSFW_fAttackDamageToTheftRatio_Caps = 1.0
Float Property AttackDamageToTheftRatio_Caps
	Float Function Get()
		return WSFW_fAttackDamageToTheftRatio_Caps
	EndFunction
	
	Function Set(Float aValue)
		WSFW_fAttackDamageToTheftRatio_Caps = aValue
	EndFunction
EndProperty

Bool WSFW_bExcludeProvisionersFromAssignmentRules = false ; If set to true, caravaneers won't be auto-unassigned when assigned to other things and instead a AssignmentRulesOverriden event will be thrown
Bool Property ExcludeProvisionersFromAssignmentRules
	Bool Function Get()
		return WSFW_bExcludeProvisionersFromAssignmentRules
	EndFunction
	
	Function Set(Bool aValue)
		WSFW_bExcludeProvisionersFromAssignmentRules = aValue
	EndFunction
EndProperty		


; ------------------------------------------------------
;
; WSFW - New Properties 1.0.1 - Switched all to Hidden and added FillWSFWVars function to load them via GetFormFromFile, this new function will be called from the WSFW framework's main quest
;
; ------------------------------------------------------

GlobalVariable Property WSFW_Setting_AutoAssignBeds Auto Hidden
GlobalVariable Property WSFW_Setting_AutoAssignFood Auto Hidden
GlobalVariable Property WSFW_Setting_AutoAssignDefense Auto Hidden
GlobalVariable Property WSFW_Setting_MaxFoodWorkPerSettler Auto Hidden
GlobalVariable Property WSFW_Setting_MaxDefenseWorkPerSettler Auto Hidden
GlobalVariable Property WSFW_Setting_TradeCaravanMinimumPopulation Auto Hidden
GlobalVariable Property WSFW_Setting_recruitmentMinPopulationForSynth Auto Hidden
GlobalVariable Property WSFW_Setting_startingHappiness Auto Hidden
GlobalVariable Property WSFW_Setting_startingHappinessMin Auto Hidden
GlobalVariable Property WSFW_Setting_startingHappinessTarget Auto Hidden
GlobalVariable Property WSFW_Setting_resolveAttackMaxAttackRoll Auto Hidden
GlobalVariable Property WSFW_Setting_resolveAttackAllowedDamageMin Auto Hidden
GlobalVariable Property WSFW_Setting_workshopRadioInnerRadius Auto Hidden
GlobalVariable Property WSFW_Setting_workshopRadioOuterRadius Auto Hidden
GlobalVariable Property WSFW_Setting_happinessModifierMax Auto Hidden
GlobalVariable Property WSFW_Setting_happinessModifierMin Auto Hidden
FormList Property ExcludeFromAssignmentRules Auto Hidden
{ Items in this list won't be auto-unassigned when a settler is assigned to them. Instead an event will be fired so the mod involved can act on the information. }
WorkshopFramework:NPCManager Property WSFW_NPCManager Auto Hidden
Keyword Property WSFW_DoNotAutoassignKeyword Auto Hidden
WorkshopFramework:MessageManager Property WSFW_MessageManager Auto Hidden

String sWSFW_Plugin = "WorkshopFramework.esm" Const

int iFormID_WSFW_Setting_AutoAssignBeds = 0x000092A9 Const
int iFormID_WSFW_Setting_AutoAssignFood = 0x000092AB Const
int iFormID_WSFW_Setting_AutoAssignDefense = 0x000092AA Const
int iFormID_WSFW_Setting_MaxFoodWorkPerSettler = 0x000092B7 Const
int iFormID_WSFW_Setting_MaxDefenseWorkPerSettler = 0x000092B6 Const
int iFormID_WSFW_Setting_TradeCaravanMinimumPopulation = 0x000092B8 Const
int iFormID_WSFW_Setting_recruitmentMinPopulationForSynth = 0x000092B5 Const
int iFormID_WSFW_Setting_startingHappiness = 0x000092B4 Const
int iFormID_WSFW_Setting_startingHappinessMin = 0x000092B3 Const
int iFormID_WSFW_Setting_startingHappinessTarget = 0x000092B2 Const
int iFormID_WSFW_Setting_resolveAttackMaxAttackRoll = 0x000092B1 Const
int iFormID_WSFW_Setting_resolveAttackAllowedDamageMin = 0x000092B0 Const
int iFormID_WSFW_Setting_workshopRadioInnerRadius = 0x000092AF Const
int iFormID_WSFW_Setting_workshopRadioOuterRadius = 0x000092AE Const
int iFormID_WSFW_Setting_happinessModifierMax = 0x000092AC Const
int iFormID_WSFW_Setting_happinessModifierMin = 0x000092AD Const
int iFormID_ExcludeFromAssignmentRules = 0x000092A8 Const
int iFormID_WSFW_NPCManager = 0x000091E2 Const
int iFormID_WSFW_DoNotAutoassignKeyword = 0x000082A5 Const ; WSFW 1.0.8
int iFormID_WSFW_MessageManager = 0x000092C5 Const ; WSFW 1.0.8
int iFormID_WorkshopEnemyFaction = 0x001357E7 Const ; WSFW 1.1.10

Function FillWSFWVars()
	if( ! WSFW_NPCManager)
		WSFW_NPCManager = Game.GetFormFromFile(iFormID_WSFW_NPCManager, sWSFW_Plugin) as WorkshopFramework:NPCManager
	endif
	
	; WSFW 1.0.8
	if( ! WSFW_MessageManager)
		WSFW_MessageManager = Game.GetFormFromFile(iFormID_WSFW_MessageManager, sWSFW_Plugin) as WorkshopFramework:MessageManager
	endif
	
	; WSFW 1.0.8
	if( ! WSFW_DoNotAutoassignKeyword)
		WSFW_DoNotAutoassignKeyword = Game.GetFormFromFile(iFormID_WSFW_DoNotAutoassignKeyword, sWSFW_Plugin) as Keyword
	endif
	
	if( ! WSFW_Setting_AutoAssignBeds)
		WSFW_Setting_AutoAssignBeds = Game.GetFormFromFile(iFormID_WSFW_Setting_AutoAssignBeds, sWSFW_Plugin) as GlobalVariable
	endif
	
	if( ! WSFW_Setting_AutoAssignFood)
		WSFW_Setting_AutoAssignFood = Game.GetFormFromFile(iFormID_WSFW_Setting_AutoAssignFood, sWSFW_Plugin) as GlobalVariable
	endif
	
	if( ! WSFW_Setting_AutoAssignDefense)
		WSFW_Setting_AutoAssignDefense = Game.GetFormFromFile(iFormID_WSFW_Setting_AutoAssignDefense, sWSFW_Plugin) as GlobalVariable
	endif
	
	if( ! WSFW_Setting_MaxFoodWorkPerSettler)
		WSFW_Setting_MaxFoodWorkPerSettler = Game.GetFormFromFile(iFormID_WSFW_Setting_MaxFoodWorkPerSettler, sWSFW_Plugin) as GlobalVariable
	endif
	
	if( ! WSFW_Setting_MaxDefenseWorkPerSettler)
		WSFW_Setting_MaxDefenseWorkPerSettler = Game.GetFormFromFile(iFormID_WSFW_Setting_MaxDefenseWorkPerSettler, sWSFW_Plugin) as GlobalVariable
	endif
	
	if( ! WSFW_Setting_TradeCaravanMinimumPopulation)
		WSFW_Setting_TradeCaravanMinimumPopulation = Game.GetFormFromFile(iFormID_WSFW_Setting_TradeCaravanMinimumPopulation, sWSFW_Plugin) as GlobalVariable
	endif
	
	if( ! WSFW_Setting_recruitmentMinPopulationForSynth)
		WSFW_Setting_recruitmentMinPopulationForSynth = Game.GetFormFromFile(iFormID_WSFW_Setting_recruitmentMinPopulationForSynth, sWSFW_Plugin) as GlobalVariable
	endif
	
	if( ! WSFW_Setting_startingHappiness)
		WSFW_Setting_startingHappiness = Game.GetFormFromFile(iFormID_WSFW_Setting_startingHappiness, sWSFW_Plugin) as GlobalVariable
	endif
	
	if( ! WSFW_Setting_startingHappinessMin)
		WSFW_Setting_startingHappinessMin = Game.GetFormFromFile(iFormID_WSFW_Setting_startingHappinessMin, sWSFW_Plugin) as GlobalVariable
	endif
	
	if( ! WSFW_Setting_startingHappinessTarget)
		WSFW_Setting_startingHappinessTarget = Game.GetFormFromFile(iFormID_WSFW_Setting_startingHappinessTarget, sWSFW_Plugin) as GlobalVariable
	endif
	
	if( ! WSFW_Setting_resolveAttackMaxAttackRoll)
		WSFW_Setting_resolveAttackMaxAttackRoll = Game.GetFormFromFile(iFormID_WSFW_Setting_resolveAttackMaxAttackRoll, sWSFW_Plugin) as GlobalVariable
	endif
	
	if( ! WSFW_Setting_resolveAttackAllowedDamageMin)
		WSFW_Setting_resolveAttackAllowedDamageMin = Game.GetFormFromFile(iFormID_WSFW_Setting_resolveAttackAllowedDamageMin, sWSFW_Plugin) as GlobalVariable
	endif
	
	if( ! WSFW_Setting_workshopRadioInnerRadius)
		WSFW_Setting_workshopRadioInnerRadius = Game.GetFormFromFile(iFormID_WSFW_Setting_workshopRadioInnerRadius, sWSFW_Plugin) as GlobalVariable
	endif
	
	if( ! WSFW_Setting_workshopRadioOuterRadius)
		WSFW_Setting_workshopRadioOuterRadius = Game.GetFormFromFile(iFormID_WSFW_Setting_workshopRadioOuterRadius, sWSFW_Plugin) as GlobalVariable
	endif
	
	if( ! WSFW_Setting_happinessModifierMax)
		WSFW_Setting_happinessModifierMax = Game.GetFormFromFile(iFormID_WSFW_Setting_happinessModifierMax, sWSFW_Plugin) as GlobalVariable
	endif
	
	if( ! WSFW_Setting_happinessModifierMin)
		WSFW_Setting_happinessModifierMin = Game.GetFormFromFile(iFormID_WSFW_Setting_happinessModifierMin, sWSFW_Plugin) as GlobalVariable
	endif
	
	if( ! ExcludeFromAssignmentRules)
		ExcludeFromAssignmentRules = Game.GetFormFromFile(iFormID_ExcludeFromAssignmentRules, sWSFW_Plugin) as Formlist
	endif
	
	if( ! WorkshopEnemyFaction)
		WorkshopEnemyFaction = Game.GetFormFromFile(iFormID_WorkshopEnemyFaction, "Fallout4.esm") as Faction
	endif
Endfunction

; ------------------------------------------------------
;
; WSFW - New Events
;
; ------------------------------------------------------

; WorkshopRemoveActor
;
; Event when an actor is removed from a settlement, via death or some other mechanism
; 
; kArgs[0] = actorRef
; kArgs[1] = workshopRef
CustomEvent WorkshopRemoveActor 

; WorkshopActorAssignedToBed
; Event when an actor is assigned to a bed (only fires if this is a new bed for them, as the bed code often runs quite frequently)
; 
; kArgs[0] = actorRef
; kArgs[1] = workshopRef
; kArgs[2] = objectRef
CustomEvent WorkshopActorAssignedToBed ; TODO: Implement this

; WSFW_LocationAddActor - 1.1.4
; Event when an actor is transferred to a settlement not registered with the Workshops array
; kArgs[0] = assignedActor
; kArgs[1] = assignedLocation
; kArgs[2] = assignedKeyword
CustomEvent WSFW_LocationAddActor

; WSFW_WorkshopNPCTransfer - 1.1.4
; Event when an actor is transferred to a settlement
; kArgs[0] = assignedActor
; kArgs[1] = newWorkshop
; kArgs[2] = assignedKeyword
CustomEvent WSFW_WorkshopNPCTransfer

; AssignmentRulesOverriden
;
; Event when an actor would normally be unassigned due to assignment rules, but was overridden because the item was found in the ExcludeFromAssignmentRules formlist
; kArgs[0] = objectRef or WorkshopCaravanKeyword for Caravan ; WSFW 1.0.6 - Switched to sending a keyword for Caravan, since this is a Var type, it can take either - receiving event handler will need to prepare for both. Due to how early in the life of WSFW this is, it shouldn't be a problem - especially since at this phase, the public documentation doesn't even cover this system yet.
; kArgs[1] = workshopRef
; kArgs[2] = actorRef
; kArgs[3] = lastAssignedRef
CustomEvent AssignmentRulesOverriden

; ------------------------------------------------------
;
; WSFW - New Functions
;
; ------------------------------------------------------

; Send data about new custom vendors
; aCustomVendorID - An absolute unique string across all mods using this system, this is what you'll use on the corresponding workshop furniture items in their sCustomVendorID property
; aVendorContainerList - A formlist with 4 container forms defined. Each entry will be added to the next for higher level vendors - for example a level 2 vendor will also get the inventory from the level 1 container. Filter for WorkshopVendorChest under WorldObjects > Containers to see an example of how to set these up.
; aVendorKeyword - Optional to tag any NPC using this vendor type object with a keyword, which can help with things like perks or other systems to detect that an NPC is this vendor type easily
; aCustomVendorFaction - If blank, this will default to WorkshopVendorFactionMisc (this is used to control dialogue). Be sure if you override this that you have your own dialogue handling in place or the settler won't actually sell anything.
Function RegisterCustomVendor(String aCustomVendorID, Formlist aVendorContainerList, Keyword aVendorKeyword = None, Faction aCustomVendorFaction = None)
	if(CustomVendorTypes == None)
		CustomVendorTypes = new CustomVendor[0]
	endif
	
	int iIndex = CustomVendorTypes.FindStruct("sVendorID", aCustomVendorID)
	if(iIndex < 0)
		; New vendor; store it
		if(aCustomVendorFaction == None)
			; Default to WorkshopVendorFactionMisc so NPC will have dialogue
			aCustomVendorFaction = Game.GetFormFromFile(0x00062555, "Fallout4.esm") as Faction
		endif
		
		CustomVendor newEntry = new CustomVendor
		newEntry.sVendorID = aCustomVendorID
		newEntry.VendorFaction = aCustomVendorFaction
		newEntry.VendorKeyword = aVendorKeyword
		newEntry.VendorContainerList = aVendorContainerList
		
		CustomVendorTypes.Add(newEntry)
	endif
EndFunction


; Send forms you'd like to manage assignment rules for and register for the custom event: AssignmentRulesOverriden
Function ExcludeFromAssignmentRules(Form aFormOrListToExclude)
	FormList asFormlist = aFormOrListToExclude as FormList
	if(asFormlist)
		int i = 0
		int iCount = asFormlist.GetSize()
		while(i < iCount)
			ExcludeFromAssignmentRules.AddForm(asFormlist.GetAt(i))
			
			i += 1
		endWhile
	else
		ExcludeFromAssignmentRules.AddForm(aFormOrListToExclude)
	endif
EndFunction

; WSFW - Internal use
Bool Function IsExcludedFromAssignmentRules(Form aFormToCheck)
	if(aFormToCheck as ObjectReference)
		aFormToCheck = (aFormToCheck as ObjectReference).GetBaseObject()
	endif
	
	Bool bExclude = ExcludeFromAssignmentRules.HasForm(aFormToCheck)
	
	return bExclude
EndFunction

; WSFW - Internal use
Function UnassignActor_Private_SkipExclusions(WorkshopNPCScript akActorRef, WorkshopScript akWorkshopRef)
	; 2.0.0 - Blanking this out as we switched to a global function that accepts nonWorkshopNPCScript actors
EndFunction

; WSFW - Internal use
; WSFW 1.0.6 - Added a new argument (so versioning the function call), so we can ensure anything handling assignment rule exclusions has information on what was last assigned
Function UnassignActor_Private_SkipExclusionsV2(WorkshopNPCScript akActorRef, WorkshopScript akWorkshopRef, Form aLastAssigned = None)
	; 2.0.0 - Blanking this out as we switched to a global function that accepts nonWorkshopNPCScript actors
EndFunction



Event Location.OnLocationCleared(Location akSender)
	WorkshopScript workshopRef = GetWorkshopFromLocation(akSender)

	if(workshopRef && workshopRef.OwnedByPlayer)
		UpdateMinutemenRecruitmentAvailable()
	endif

	;last one of them is killed. As this won't change workshop ownership, running UpdateMinutemenRecruitmentAvailable again is superfluous)
	UnregisterForRemoteEvent(akSender, "OnLocationCleared")
endEvent


; NOTE: changed from OnInit because of timing issues - startup stage will not be set until aliases are filled
Event OnStageSet(int auiStageID, int auiItemID)
	if(auiStageID == 10)
		; open workshop log
		debug.OpenUserLog(userlogName)

		; initialize workshop arrays
		WorkshopLocations = new Location[WorkshopsCollection.GetCount()]
		Workshops = new WorkshopScript[WorkshopsCollection.GetCount()]
		WorkshopRatingValues = new ActorValue[WorkshopRatings.Length]

		int index = 0
		int crimeFactionIndex = 0

		while(index < WorkshopsCollection.GetCount())
			WorkshopScript workshopRef = WorkshopsCollection.GetAt(index) as WorkshopScript
			; add workshop to array
			Workshops[index] = workshopRef
			; initialize workshopID on this workshop
			workshopRef.InitWorkshopID(index)
			; initialize location
			WorkshopLocations[index] = workshopRef.GetCurrentLocation()
			workshopRef.myLocation = WorkshopLocations[index]
			; initialize happiness to 50 for safety
			workshopRef.SetValue(WorkshopRatings[WorkshopRatingHappiness].resourceValue, startingHappiness)
			; register for location cleared events
			RegisterForRemoteEvent(WorkshopLocations[index], "OnLocationCleared")

			; set ownership/crime faction if it doesn't have one already
			if(workshopRef.SettlementOwnershipFaction == NONE && workshopRef.UseOwnershipFaction && crimeFactionIndex < WorkshopCrimeFactions.GetSize())
				workshopRef.SettlementOwnershipFaction = WorkshopCrimeFactions.GetAt(crimeFactionIndex) as Faction
				crimeFactionIndex += 1
			endif

			; register for daily update
			Workshops[index].RegisterForCustomEvent(self, "WorkshopDailyUpdate")

			index += 1
		endWhile
		
		index = 0
		int resourceAVCount = 0
		while(index < WorkshopRatings.Length)
			; add keyword to array
			WorkshopRatingValues[index] = WorkshopRatings[index].resourceValue
			; if this has a resource AV, increment count
			if(WorkshopRatings[index].resourceValue)
				resourceAVCount += 1
			endif
			
			index += 1
		endWhile
		
		; initialize workshop resource AV array
		WorkshopResourceAVs = new WorkshopActorValue[resourceAVCount]

		index = 0
		int resourceAVIndex = 0
		
		while(index < WorkshopRatings.Length)
			; if this has a resource AV, add to resource AV array and increment index
			if(WorkshopRatings[index].resourceValue)
				WorkshopResourceAVs[resourceAVIndex] = new WorkshopActorValue
				WorkshopResourceAVs[resourceAVIndex].workshopRatingIndex = index
				WorkshopResourceAVs[resourceAVIndex].resourceValue = WorkshopRatings[index].resourceValue
				
				resourceAVIndex += 1
			endif
			index += 1
		endWhile

		; initialize Minutemen recruitment available
		UpdateMinutemenRecruitmentAvailable()

		; get location change events for player
		RegisterForRemoteEvent(Game.GetPlayer(), "OnLocationChange")
		
		; start daily update timer
		StartTimerGameTime(updateIntervalGameHours, dailyUpdateTimerID)

		; start initialize workshop locations process
		RegisterForCustomEvent(self, "WorkshopInitializeLocation")
		SendCustomEvent("WorkshopInitializeLocation")		

		Initialized = true
	endif
endEvent


function InitializeLocation(WorkshopScript workshopRef, RefCollectionAlias SettlementNPCs, ReferenceAlias theLeader, ReferenceAlias theMapMarker)
	workshopRef.myMapMarker = theMapMarker.GetRef()

	; force recalc (unloaded workshop)
	workshopRef.RecalculateWorkshopResources(true)
	
	int initPopulation = workshopRef.GetBaseValue(WorkshopRatings[WorkshopRatingPopulation].resourceValue) as int
	int initPopulationVal = workshopRef.GetValue(WorkshopRatings[WorkshopRatingPopulation].resourceValue) as int
	
	if(SettlementNPCs)
		AddCollectionToWorkshopPUBLIC(SettlementNPCs, workshopRef, true)
	endif
	
	if(theLeader && theLeader.GetActorRef())
		AddActorToWorkshopPUBLIC(theLeader.GetActorRef() as WorkshopNPCScript, workshopRef, true)
	endif 

	
	initPopulation = workshopRef.GetBaseValue(WorkshopRatings[WorkshopRatingPopulation].resourceValue) as int
	initPopulationVal = workshopRef.GetValue(WorkshopRatings[WorkshopRatingPopulation].resourceValue) as int
	
	; WSFW 2.0.3 - In 2.0.2, we fixed a bug that could cause population numbers to get out of sync in the pipboy. This fix had the unintended consequence of breaking behavior this section was relying on.	The below section will fix this issue. Without this, Minutemen radiant quests to help settlements will fail to find people as all population AVs will be 0.
	if(initPopulation < SettlementNPCs.GetCount())
		int iWorkshopNPCs = 0
		
		int i = 0
		while(i < SettlementNPCs.GetCount())
			; Need to check for WorkshopNPCScript or it will count other NPCs with Boss ref, such as the raiders occupying Outpost Zimonja
			if((SettlementNPCs.GetAt(i) as Actor) as WorkshopNPCScript)
				iWorkshopNPCs += 1
			endIf
			
			i += 1
		endWhile
		
		initPopulation = iWorkshopNPCs
		
		ModifyResourceData(WorkshopRatings[WorkshopRatingPopulation].resourceValue, workshopRef, initPopulation)
	endif
	
	int robotPopulation = 0
	if(workshopRef.myLocation.HasKeyword(LocTypeWorkshopRobotsOnly))
		; this means everyone here (at game start) is a robot
		robotPopulation = initPopulation
	endif
	
	ModifyResourceData(WorkshopRatings[WorkshopRatingPopulationRobots].resourceValue, workshopRef, robotPopulation)

	; initialize ratings if it has population
	if(initPopulation > 0)
		; happiness
		SetResourceData(WorkshopRatings[WorkshopRatingHappiness].resourceValue, workshopRef, startingHappiness)
		; set food, water, beds equal to population (this will be corrected to reality the first time the player visits the location)
		SetResourceData(WorkshopRatings[WorkshopRatingFood].resourceValue, workshopRef, initPopulation)
		SetResourceData(WorkshopRatings[WorkshopRatingWater].resourceValue, workshopRef, initPopulation)
		SetResourceData(WorkshopRatings[WorkshopRatingBeds].resourceValue, workshopRef, initPopulation - robotPopulation)
		; set "last attacked" to a very large number (so they don't act like they were just attacked)
		SetResourceData(WorkshopRatings[WorkshopRatingLastAttackDaysSince].resourceValue, workshopRef, 99)
	endif

	; send "done" event
	Var[] kargs = new Var[1]
	kargs[0] = workshopRef
	
	SendCustomEvent("WorkshopInitializeLocation", kargs)		
endFunction

int initializationIndex = 0
Event WorkshopParentScript.WorkshopInitializeLocation(WorkshopParentScript akSender, Var[] akArgs)
	WorkshopScript nextWorkshopRef = NONE
	
	if(akArgs.Length > 0)
		WorkshopScript workshopRef = akArgs[0] as WorkshopScript
		if(workshopRef)
			; this is the location that was just initialized - find the next
			;int newWorkshopIndex = workshopRef.GetWorkshopID() + 1
			; Try just going up through the array
			initializationIndex += 1
			int newWorkshopIndex = initializationIndex
			if(newWorkshopIndex >= Workshops.Length)
				setStage(20) ; way to easily track when this is done
				
				; initial daily update
				DailyWorkshopUpdate(true)
				
				; reset daily update timer - failsafe
				StartTimerGameTime(updateIntervalGameHours, dailyUpdateTimerID)
			else
				; send story event for next workshop location
				nextWorkshopRef = workshops[newWorkshopIndex]
			endif
		endif
	else
		; if no location sent, start with first
		nextWorkshopRef = Workshops[0]
	endif

	; send event if we found next workshop
	if(nextWorkshopRef)
		; wait a bit for quest to finish shutting down
		int maxWait = 5
		int i = 0
		while(i < maxWait && WorkshopInitializeLocation.IsStopped() == false)
			utility.wait(1.0)
			
			i += 1
		endWhile
		
		bool bSuccess = WorkshopEventInitializeLocation.SendStoryEventAndWait(nextWorkshopRef.myLocation)
		
		if( ! bSuccess)
			; quest failed to start for this location - skip it and move on
			; send "done" event
			Var[] kargs = new Var[1]
			kargs[0] = nextWorkshopRef
			
			SendCustomEvent("WorkshopInitializeLocation", kargs)		
		endif
	endif
EndEvent

; called when new locations are added (e.g. by DLC init quests)
; newWorkshops - array of new workshops to check for
; return value:
;		TRUE = initializeEventHandler needs to handle initialize events for new locations
;		FALSE = no locations need to be initialized (all are already in Workshops array)
bool function ReinitializeLocationsPUBLIC(WorkshopScript[] newWorkshops, Form initializeEventHandler)
	; wait for main initialization process to finish
	while(GetStageDone(20) == false)
		debug.trace( " ... waiting for primary WorkshopInitializeLocation process to finish...")
		utility.wait(2.0)
	endWhile

	; lock editing
	GetEditLock()

	; make sure to unregister WorkshopParent from this event - DLC will register and handle the event for themselves
	UnregisterForCustomEvent(self, "WorkshopInitializeLocation")

	; save current size of Workshops array - this will be our starting point for the new init loop
	int startingNewWorkshopIndex = Workshops.Length

	; run through newWorkshops to see if they're already in the workshop list
	int i = 0
	while(i < newWorkshops.Length)
		WorkshopScript workshopRef = newWorkshops[i]
		; is this already in Workshops array?
		int workshopIndex = Workshops.Find(workshopRef)
		if workshopIndex == -1
			; not in list - add me to arrays and initialize
			; NOTE: this basically replicates code in OnStageSet, but safer to duplicate it here than change that to a function call
			; START:
				; add workshop to array
				Workshops.Add(workshopRef)
				int newIndex = Workshops.Length-1
				; initialize workshopID on this workshop to the index
				workshopRef.InitWorkshopID(newIndex)
				; initialize location
				WorkshopLocations.Add(workshopRef.GetCurrentLocation())
				workshopRef.myLocation = WorkshopLocations[newIndex]
				; initialize happiness to 50 for safety
				workshopRef.SetValue(WorkshopRatings[WorkshopRatingHappiness].resourceValue, startingHappiness)
				; register for location cleared events
				RegisterForRemoteEvent(WorkshopLocations[newIndex], "OnLocationCleared")

				; NOTE: ownership/crime faction must be set on new workshops manually

				debug.trace(" OnInit: location " + newIndex + "=" + WorkshopLocations[newIndex])
				; register for daily update
				Workshops[newIndex].RegisterForCustomEvent(self, "WorkshopDailyUpdate")
			; END
		endif
		i += 1
	endWhile

	; if we added any new locations, need to initialize them
	bool bLocationsToInit = (startingNewWorkshopIndex < Workshops.Length)
	if(bLocationsToInit)
		; whatever was passed in will handle this event
		initializeEventHandler.RegisterForCustomEvent(self, "WorkshopInitializeLocation")

		; start the process by sending the event with the LAST initialized workshop (top of original Workshops array)
		WorkshopScript lastInitializedWorkshop = Workshops[startingNewWorkshopIndex - 1]
		Var[] kargs = new Var[1]
		kargs[0] = lastInitializedWorkshop
		debug.trace(" 	sending WorkshopInitializeLocation event for " + lastInitializedWorkshop)
		SendCustomEvent("WorkshopInitializeLocation", kargs)		
	endif

	debug.trace(" ReinitializeLocationsPUBLIC DONE")

	; unlock editing
	EditLock = false

	return bLocationsToInit
endFunction

; returns the total in all player-owned settlements for the specified rating
float function GetWorkshopRatingTotal(int ratingIndex)
	ActorValue resourceValue = GetRatingAV(ratingIndex)

	; go through player-owned workshops
	int index = 0
	float total = 0.0
	while(index < Workshops.Length)
		if(Workshops[index].GetValue(WorkshopPlayerOwnership) > 0)
			total += Workshops[index].GetValue(resourceValue)
		endif
		
		index += 1
	endWhile
	
	return total
endFunction

; returns the total of player-owned settlements for the specified rating
int function GetWorkshopRatingLocations(int ratingIndex, float ratingMustBeGreaterThan = 0.0)
	actorValue resourceValue = GetRatingAV(ratingIndex)
	
	; go through player-owned locations
	int index = 0
	int locationCount = 0
	while(index < Workshops.Length)
		if(Workshops[index].GetValue(WorkshopPlayerOwnership) > 0 && Workshops[index].GetValue(resourceValue) > ratingMustBeGreaterThan)
			locationCount += 1
		endif
		
		index += 1
	endWhile
	
	return locationCount
endFunction


; utility function - updates flag used to indicate if there are any settlements available for recruitment
function UpdateMinutemenRecruitmentAvailable()
	; go through locations - looking for:
	; * not player-owned
	; * population > 0
	int index = 0
	int neutralCount = 0	 ; count the number of "neutral" settlements (not owned by player)
	int totalCount = 0		; count total number of populated settlements
	Faction MinutemenFaction = Game.GetFormFromFile(0x00068043, "Fallout4.esm") as Faction
	
	while(index < Workshops.Length)
		WorkshopScript workshopRef = Workshops[index]
		
		if(workshopRef.GetBaseValue(WorkshopRatings[WorkshopRatingPopulation].resourceValue) > 0 && ((workshopRef.HasKeyword(WorkshopType02) == false && workshopRef.HasKeyword(WorkshopType02Vassal) == false) || workshopRef.ControllingFaction == MinutemenFaction))
			totalCount += 1
			
			if(workshopRef.GetValue(WorkshopPlayerOwnership) == 0)
				neutralCount += 1
			endif
		endif
		
		index += 1
	endWhile
	
	; update globals
	MinutemenRecruitmentAvailable.SetValue(neutralCount)
	MinutemenOwnedSettlements.SetValue(totalCount - neutralCount)
endFunction

Event OnTimerGameTime(int aiTimerID)
	if(aiTimerID == dailyUpdateTimerID)
		DailyWorkshopUpdate()
		
		; start timer again
		StartTimerGameTime(updateIntervalGameHours, dailyUpdateTimerID)
	endif
EndEvent


Event Actor.OnLocationChange(Actor akSender, Location akOldLoc, Location akNewLoc)
	if(akNewLoc && akNewLoc.HasKeyword(LocTypeWorkshopSettlement))
		WorkshopScript workshopRef = GetWorkshopFromLocation(akNewLoc)
		
		if( ! workshopRef)
			return
		else
			SetCurrentWorkshop(workshopRef)

			if(workshopRef.UFO4P_CurrentlyUnderAttack == false)
				if(UFO4P_PreviousWorkshopLocation && UFO4P_PreviousWorkshopLocation.IsSameLocation(akNewLoc))
					Float UFO4P_GameTimeSinceLastReset = Utility.GetCurrentGameTime() - UFO4P_GameTimeOfLastResetStarted
					
					if(UFO4P_GameTimeSinceLastReset < 1)
						return
					endIf
				endIf
			endIf

			UFO4P_InitCurrentWorkshopArrays()

			if(workshopRef.UFO4P_CurrentlyUnderAttack)
				UFO4P_AttackRunning = true
				UFO4P_WorkshopRef_ResetDelayed = workshopRef
			else
				UFO4P_GameTimeOfLastResetStarted = Utility.GetCurrentGameTime()
				ResetWorkshop(workshopRef)
			endIf
		EndIf
	EndIf


	if(akOldLoc && akOldLoc.HasKeyword(LocTypeWorkshopSettlement))	
		; when player leaves a workshop location, recalc the workbench ratings
		; get the workbench
		WorkshopScript workshopRef = GetWorkshopFromLocation(akOldLoc)
		if( ! workshopRef)
			return
		else
			UFO4P_PreviousWorkshopLocation = akOldLoc
			
			; reset days since last visit for this workshop
			workshopRef.DaysSinceLastVisit = 0
		endif
	endif

EndEvent


WorkshopScript function GetWorkshopFromLocation(Location workshopLocation)
	int index = WorkshopLocations.Find(workshopLocation)
	
	if(index < 0)
		return NONE	
	else
		return Workshops[index] as WorkshopScript
	endif
endFunction

int tempBuildCounter = 0

; main function called by workshop when new object is built
bool function BuildObjectPUBLIC(ObjectReference newObject, WorkshopScript workshopRef)
	; lock editing
	GetEditLock()

	tempBuildCounter += 1
	
	WorkshopObjectScript newWorkshopObject = newObject as WorkshopObjectScript

	; if this is a scripted object, check for input/output data
	if(newWorkshopObject)
		newWorkshopObject.workshopID = workshopRef.GetWorkshopID()
		
		AssignObjectToWorkshop(newWorkshopObject, workshopRef, false)
		
		; object handles any creation needs
		newWorkshopObject.HandleCreation(true)

		; send custom event for this object
		Var[] kargs = new Var[2]
		kargs[0] = newWorkshopObject
		kargs[1] = workshopRef
		SendCustomEvent("WorkshopObjectBuilt", kargs)
	endif

	; unlock building
	EditLock = false

	; return true if this is a scripted object
	return ( newWorkshopObject != NONE )
endFunction

; called by WorkshopScript on timer periodically to keep new work objects assigned
function TryToAssignResourceObjectsPUBLIC(WorkshopScript workshopRef)
	; lock editing
	GetEditLock()
	
	Bool bOwnedByPlayer = workshopRef.OwnedByPlayer
	; WSFW - Override based on autoassign settings
	if( ! bOwnedByPlayer || AutoAssignFood)
		TryToAssignResourceType(workshopRef, WorkshopRatings[WorkshopRatingFood].resourceValue)
	endif
	
	; WSFW - Override based on autoassign settings
	if( ! bOwnedByPlayer || AutoAssignDefense)
		TryToAssignResourceType(workshopRef, WorkshopRatings[WorkshopRatingSafety].resourceValue)
	endif
	
	; WSFW - Override based on autoassign settings
	if( ! bOwnedByPlayer || AutoAssignBeds)
		TryToAssignBeds(workshopRef)
	endif
	
	; unlock building
	EditLock = false
endFunction


function WoundActor(WorkShopNPCScript woundedActor, bool bWoundMe = true)
	if(woundedActor.IsWounded() == bWoundMe)
		return
	endif

	; get actor's workshop
	WorkshopScript workshopRef = GetWorkshop(woundedActor.GetWorkshopID())
	; wound/heal actor
	woundedActor.SetWounded(bWoundMe)

	; increase or decrease damage?
	int damageValue = 1
	if( ! bWoundMe)
		damageValue = -1
	endif

	; update damage rating
	; RESOURCE CHANGE:
	; reduce extra pop damage if > 0 ; otherwise, damage is normally tracked within WorkshopRatingPopulation (difference between base value and current value)
	if(bWoundMe == false && workshopRef.GetValue(WorkshopRatings[WorkshopRatingDamagePopulation].resourceValue) > 0)
		ModifyResourceData(WorkshopRatings[WorkshopRatingDamagePopulation].resourceValue, workshopRef, damageValue)
	endif

	UpdateActorsWorkObjects_Private(woundedActor, workshopRef, true)
endFunction

function HandleActorDeath(WorkShopNPCScript deadActor, Actor akKiller)
	; get actor's workshop
	WorkshopScript workshopRef = GetWorkshop(deadActor.GetWorkshopID())

	UnassignActor(deadActor, bRemoveFromWorkshop = true)
	
	; WSFW 2.0.0 - Added check for non-synth since people often use mods to detect the, this means they won't get the happiness penalty now (though they will have to deal with other settlers turning on them still)
	if( ! deadActor.bIsSynth && deadActor.bCountsForPopulation && deadActor.IsInFaction(WorkshopEnemyFaction) == false)
		ModifyHappinessModifier(workshopRef, workshopRef.actorDeathHappinessModifier)
	endif	
endFunction

function UpdateActorsWorkObjects(WorkShopNPCScript theActor, WorkshopScript workshopRef = NONE, bool bRecalculateResources = false)
	GetEditLock()
	UpdateActorsWorkObjects_Private(theActor, workshopRef, bRecalculateResources)
	EditLock = false
endFunction


function UpdateActorsWorkObjects_Private(WorkShopNPCScript theActor, WorkshopScript workshopRef = NONE, bool bRecalculateResources = false)
	if(workshopRef == none)
		int workshopID = theActor.GetWorkshopID()
		if(workshopID < 0)
			return
		endif
		
		workshopRef = GetWorkshop(workshopID)		
	endif

	if(UFO4P_IsWorkshopLoaded (workshopRef) == false)
		return
	endif

	ObjectReference[] ResourceObjects = workshopRef.GetWorkshopOwnedObjects(theActor)
	int countResourceObjects = ResourceObjects.Length
	int i = 0
	
	while(i < countResourceObjects)
		WorkshopObjectScript theObject = ResourceObjects[i] as WorkshopObjectScript
		if(theObject)
			UpdateWorkshopRatingsForResourceObject(theObject, workshopRef, bRecalculateResources = false) ; WSFW 2.0.0, forced recalc to false - silly to recalculate the workshop for every item when we can do it once for the workshop at the end
		endif
		
		i += 1
	endWhile
	
	; WSFW 2.0.0 - Run once after countResourceObjects are processed
	if(bRecalculateResources)
		workshopRef.RecalculateWorkshopResources()
	endif
endFunction

; main function called by workshop when object is deleted
function RemoveObjectPUBLIC(ObjectReference removedObject, WorkshopScript workshopRef)
	; lock editing
	GetEditLock()
	WorkshopObjectScript workObject = removedObject as WorkshopObjectScript

	; if this is a scripted object, check for input/output data
	if(workObject)
		RemoveObjectFromWorkshop(workObject, workshopRef)

		; send custom event for this object
		Var[] kargs = new Var[2]
		kargs[0] = workObject
		kargs[1] = workshopRef
		SendCustomEvent("WorkshopObjectDestroyed", kargs)		
	endif

	; unlock building
	EditLock = false
endFunction

; called when a workshop object is deleted
function RemoveObjectFromWorkshop(WorkshopObjectScript workObject, WorkshopScript workshopRef)
	UnassignObject_Private(workObject, bRemoveObject = true)

	; clear workshopID
	workObject.workshopID = -1

	; tell object it's being deleted
	workObject.HandleDeletion()
endFunction


; Create a new actor and assign it to the specified workshop
function CreateActorPUBLIC(WorkshopScript workshopRef, ObjectReference spawnMarker = NONE, bool bNewSettlerAlias = false)
	; lock editing
	GetEditLock()
	CreateActor(workshopRef, false, spawnMarker, bNewSettlerAlias)
	; unlock editing
	EditLock = false
endFunction

WorkshopNPCScript function CreateActor_DailyUpdate(WorkshopScript workshopRef, bool bBrahmin = false, ObjectReference spawnMarker = NONE, bool bNewSettlerAlias = false)
	GetEditLock()
	WorkshopNPCScript NewActorScript = CreateActor(workshopRef, bBrahmin, spawnMarker, bNewSettlerAlias)
	EditLock = false
	return NewActorScript
endFunction


WorkshopNPCScript function CreateActor(WorkshopScript workshopRef, bool bBrahmin = false, ObjectReference spawnMarker = NONE, bool bNewSettlerAlias = false)
	; WSFW - Rerouting to our NPCManager quest
	if(bBrahmin)
		return WSFW_NPCManager.CreateBrahmin(workshopRef, spawnMarker)
	else
		return WSFW_NPCManager.CreateSettler(workshopRef, spawnMarker)
	endif
endFunction


function TryToAutoAssignActor(WorkshopScript workshopRef, WorkshopNPCScript actorToAssign)
	; WSFW 2.0.0 - Added a new function that works with non workshopNPCScript npcs
	TryToAutoAssignNPC(workshopRef, actorToAssign)
endFunction

function TryToAutoAssignNPC(WorkshopScript workshopRef, Actor actorToAssign)
	; WSFW - Introduced autoassign controls
	Bool bAutoAssignBeds = AutoAssignBeds
	Bool bAutoAssignFood = AutoAssignFood
	Bool bAutoAssignDefense = AutoAssignDefense
		; TryToAutoAssignActor is only called when an NPC is added to the settlement. For non-created NPCs, ie. the starting NPCs, we want them to autoassign at first or else when the player arrives at a settlement the first time, if they have the options disabled, those NPCs won't have assignments
	if(	! actorToAssign.IsCreated() || ! workshopRef.OwnedByPlayer)
		bAutoAssignBeds = true
		bAutoAssignFood = true
		bAutoAssignDefense = true
	endif
	
	
	if( ! bAutoAssignBeds && ! bAutoAssignFood && ! bAutoAssignDefense)
		return
	endif
	
	if(UFO4P_IsWorkshopLoaded (workshopRef) == false)
		return
	endif

	int resourceIndex
	if(actorToAssign.GetValue(WorkshopGuardPreference) > 0)
		resourceIndex = WorkshopRatingSafety		
	else
		resourceIndex = WorkshopRatingFood
	endif

	actorValue resourceValue = WorkshopRatings[resourceIndex].resourceValue
	WorkshopFramework:WorkshopFunctions.SetAssignedMultiResource(actorToAssign, resourceValue)
	
	if((resourceIndex == WorkshopRatingSafety && bAutoAssignDefense) || (resourceIndex == WorkshopRatingFood && bAutoAssignFood))
		WSFW_AddActorToWorkerArray(actorToAssign, resourceIndex)
		TryToAssignResourceType(workshopRef, resourceValue)
	endif

	if(WorkshopFramework:WorkshopFunctions.GetMultiResourceProduction(actorToAssign) == 0.0)
		WorkshopFramework:WorkshopFunctions.SetAssignedMultiResource(actorToAssign, None)
		WSFW_RemoveActorFromWorkerArray(actorToAssign)
	endif
endFunction


; assign specified actor to specified workshop object - PUBLIC version (called by other scripts)
function AssignActorToObjectPUBLIC(WorkshopNPCScript assignedActor, WorkshopObjectScript assignedObject, bool bResetMode = false)
	; lock editing
	GetEditLock()
	
	AssignActorToObject(assignedActor, assignedObject, bResetMode = bResetMode)
	
	if(bResetMode)
		int workshopID = assignedObject.workshopID
		if(workshopID >= 0)
			GetWorkshop(workshopID).RecalculateWorkshopResources()
		endif
	endif
	
	EditLock = false
endFunction


; private version - called only by this script
; bResetMode: TRUE means to skip trying to assign other resource objects of this type
; bAddActorCheck: TRUE is default; FALSE means to skip adding the actor - calling function guarantees that the actor is already assigned to this workshop (speed optimization)
function AssignActorToObject(WorkshopNPCScript assignedActor, WorkshopObjectScript assignedObject, bool bResetMode = false, bool bAddActorCheck = true)
	; WSFW 1.0.8a - Pointing to new signature needed for UFO4P 2.0.6
	AssignActorToObjectV2(assignedActor, assignedObject, bResetMode, bAddActorCheck)	
EndFunction

function AssignActorToObjectV2(WorkshopNPCScript assignedActor, WorkshopObjectScript assignedObject, bool bResetMode = false, bool bAddActorCheck = true, bool bUpdateObjectArray = true)
	Debug.TraceStack("AssignActorToObjectV2 call stack.")
	int workshopID = assignedObject.workshopID
	WorkshopScript workshopRef

	if(workshopID >= 0)
		workshopRef = GetWorkshop (workshopID)
	else
		return
	endif

	if(bAddActorCheck)
		AddActorToWorkshop(assignedActor, workshopRef, bResetMode)
	endif
	
	; WSFW - Adding option to avoid unassignment to other objects
	Bool bExcludedFromAssignmentRules = IsExcludedFromAssignmentRules(assignedObject)
	Var[] kExcludedArgs = new Var[0]
	kExcludedArgs.Add(assignedObject)
	kExcludedArgs.Add(workshopRef)
	kExcludedArgs.Add(assignedActor)
	kExcludedArgs.Add(assignedObject) ; WSFW 1.0.6 - Also sending last assigned ref so handling code can decide whether to prioritize it
	
	Actor previousOwner = assignedObject.GetAssignedNPC()
	bool bAlreadyAssigned = (previousOwner == assignedActor)

	if(assignedObject.IsBed())
		bool UFO4P_IsRobot = (assignedActor.GetBaseValue(WorkshopRatings[WorkshopRatingPopulationRobots].resourceValue) > 0)
	
		if(bAlreadyAssigned)
			if(UFO4P_IsRobot)
				; WSFW Exclusion from assignment rules
				if(bExcludedFromAssignmentRules)
					SendCustomEvent("AssignmentRulesOverriden", kExcludedArgs)
				else
					assignedObject.AssignActor(none)
					UFO4P_AddUnassignedBedToArray(assignedObject)
				endif
			endif
		elseif( ! UFO4P_IsRobot)
			; WSFW - Since we've introduced a possibility where an NPC can have multiple beds, we have to account for it here
			; WSFW - The UFO4P_ActorsWithoutBeds update is not always timed correctly, have found multiple instances where it isn't updated correctly and it prevents the unassign code from ever running. So we're removing it for now.
			ObjectReference[] WorkshopBeds = GetBeds (workshopRef)
			int countBeds = WorkshopBeds.Length
			
			; bool ExitLoop = false
			int i = 0
			while(i < countBeds) ; WSFW - Removing Loop Shortcut && ExitLoop == false
				WorkshopObjectScript theBed = WorkshopBeds[i] as WorkshopObjectScript
				
				if(theBed && theBed.GetActorRefOwner() == assignedActor)
					; WSFW - Exclusion from assignment rules
					if(IsExcludedFromAssignmentRules(theBed))
						Var[] kBedExcludedArgs = new Var[0]
						kBedExcludedArgs.Add(theBed)
						kBedExcludedArgs.Add(workshopRef)
						kBedExcludedArgs.Add(assignedActor)
						kBedExcludedArgs.Add(assignedObject) ; WSFW 1.0.6 - Also sending last assigned ref so handling code can decide whether to prioritize it
						SendCustomEvent("AssignmentRulesOverriden", kBedExcludedArgs)
					else
						theBed.AssignActor (none)
						UFO4P_AddUnassignedBedToArray(theBed)
						 ; WSFW - Removing Loop Shortcut ExitLoop = true
					endif
				endif
				i += 1
			endWhile
			
			assignedObject.AssignActor(assignedActor)
			
			;If there was no previous owner, this bed must have been in the unassigned beds array, so it should be removed now.
			if(previousOwner == none)
				UFO4P_RemoveFromUnassignedBedsArray (assignedObject)
			endif
			
			SendWorkshopActorAssignedToWorkEvent(assignedActor, assignedObject, workshopRef)
		endif
	elseif(assignedObject.HasKeyword(WorkshopWorkObject))
		String sLog = "aaa"
		Debug.OpenUserLog(sLog)
		; Debug.TraceUser(sLog, "Assigning " + assignedActor + " to object " + assignedObject + ", bResetMode = " + bResetMode)
		assignedActor.bNewSettler = false
	
		bool bShouldUnassignAllObjects = true
		bool bShouldUnassignSingleObject = false
		bool bShouldTryToAssignResources = false
		actorValue multiResourceValue = assignedActor.assignedMultiResource

		if(bAlreadyAssigned)
			; Debug.TraceUser(sLog, assignedActor + " was already assigned to object " + assignedObject)
			bShouldUnassignAllObjects = false
		endif
	
		float maxProduction = 0.0 ; Placing here so we can use this same calculated value later in the function
		if(multiResourceValue)
			; Debug.TraceUser(sLog, assignedActor + " was assigned to multiResourceValue " + multiResourceValue)
			if(assignedObject.HasResourceValue(multiResourceValue))
				; Debug.TraceUser(sLog, assignedObject + " has multiResourceValue " + multiResourceValue)
				int resourceIndex = GetResourceIndex (multiResourceValue)
				maxProduction = WorkshopRatings[resourceIndex].maxProductionPerNPC
				
				; WSFW - Introducing settings to control how much of each value a settler can work
				if(multiResourceValue == WorkshopRatings[WorkshopRatingSafety].resourceValue)
					maxProduction = MaxDefenseWorkPerSettler
				elseif(multiResourceValue == WorkshopRatings[WorkshopRatingFood].resourceValue)
					maxProduction = MaxFoodWorkPerSettler
				endif
				
				float currentProduction = assignedActor.multiResourceProduction
				
				; Debug.TraceUser(sLog, "Max Production: " + maxProduction + ", Current Production: " + currentProduction)
				
				if( ! bResetMode && bAlreadyAssigned && currentProduction <= maxProduction)
					bShouldUnassignAllObjects = false
					
					; Debug.TraceUser(sLog, "Already assigned and this doesn't push us past max production. Turning off bShouldUnassignAllObjects")
				else
					float totalProduction = currentProduction
					if(bResetMode || ! bAlreadyAssigned)
						totalProduction = totalProduction + assignedObject.GetBaseValue(multiResourceValue)
					endif

					if(totalProduction <= maxProduction)
						; Debug.TraceUser(sLog, "Under or right at max production. Turning off bShouldUnassignAllObjects")
						bShouldUnassignAllObjects = false
					elseif(bAlreadyAssigned)
						; Debug.TraceUser(sLog, "Already assigned but we're over max production, so we need to unassign one item.")
						bShouldUnassignSingleObject = true
					endif
				endif
			else
				; Debug.TraceUser(sLog, assignedObject + " doesn't have multiResourceValue " + multiResourceValue + ", time to unassign the NPC from everything before assigning them to it.")
				bShouldUnassignAllObjects = true
			endif
		endif

		; WSFW - Adding option to have certain items bypass assignment rules
		; if bShouldUnassignSingleObject
		if(bShouldUnassignSingleObject)
			; WSFW Exclusion from assignment rules
			if(bExcludedFromAssignmentRules)
				SendCustomEvent("AssignmentRulesOverriden", kExcludedArgs)
			else
				; Debug.TraceUser(sLog, "Unassigning " + assignedActor + " from " + assignedObject + ", bResetMode = " + bResetMode)
				UnassignActorFromObjectV2(assignedActor, assignedObject, bResetMode)
				
				bShouldTryToAssignResources = true
			endif
		elseif(bShouldUnassignAllObjects && IsObjectOwner(workshopRef, assignedActor))
			;/
			; WSFW - Calling our own version of this function. We don't want to change the original function 
			; because there are legitimate reasons to ignore our our exclusion list, for example if the object is
			; scrapped or the NPC is killed.
			/;
			; Debug.TraceUser(sLog, "Calling UnassignActorSkipExclusions on " + assignedActor + " with aLastAssigned = " + assignedObject)
			WorkshopFramework:WorkshopFunctions.UnassignActorSkipExclusions(assignedActor, workshopRef, aLastAssigned = assignedObject)
		endif

		; unassign current owner, if any (and different from new owner)
		if(previousOwner && previousOwner != assignedActor)
			; Debug.TraceUser(sLog, "Calling unassign on previousOwner " + previousOwner + " so " + assignedActor + " can be assigned to " + assignedObject)
			if(previousOwner as WorkshopNPCScript)
				UnassignActorFromObjectV2(previousOwner as WorkshopNPCScript, assignedObject, bResetMode)
			else
				WorkshopFramework:WorkshopFunctions.UnassignActorFromObject(previousOwner, assignedObject, akWorkshopRef = workshopRef)
			endif
		endif

		; Debug.TraceUser(sLog, "Calling AssignActor on " + assignedObject + " for actor " + assignedActor)
		
		assignedObject.AssignActor(assignedActor)
		assignedActor.SetWorker(true)

		; 1.5 - new 24-hour work flag
		if(assignedObject.bWork24Hours)
			assignedActor.bWork24Hours = true 
		endif

		; if assigned object has scavenge rating, flag worker as scavenger (for packages)
		if(assignedObject.HasResourceValue(WorkshopRatings[WorkshopRatingScavengeGeneral].resourceValue))
			assignedActor.SetScavenger(true)
		endif

		; add vendor faction if any
		if(assignedObject.VendorType >= 0 || assignedObject.sCustomVendorID != "")
			; WSFW - 2.0.0 added check for sCustomVendorID
			SetVendorData(workshopRef, assignedActor, assignedObject)
		endif
		
		UpdateWorkshopRatingsForResourceObject(assignedObject, workshopRef, bRecalculateResources = !bResetMode || !bAlreadyAssigned)
		
		assignedActor.SetValue(WorkshopRatings[WorkshopRatingPopulationUnassigned].resourceValue, 0)

		if( ! bResetMode)
			SetUnassignedPopulationRating(workshopRef)
		endif

		assignedActor.EvaluatePackage()

		if(assignedObject.HasMultiResource() && (bResetMode || !bAlreadyAssigned))
			; Debug.TraceUser(sLog, assignedObject + " is a multi resource item and bResetMode = " + bResetMode + ", bAlreadyAssigned = " + bAlreadyAssigned)
			multiResourceValue = assignedObject.GetMultiResourceValue()
			assignedActor.SetMultiResource (multiResourceValue)
			
			if(workshopID == currentWorkshopID)
				float currentProduction = assignedActor.multiResourceProduction
				int resourceIndex = GetResourceIndex(multiResourceValue)
				
				if(currentProduction >= maxProduction) ; WSFW 2.0.0 - Now correctly using the user defined max production
					WSFW_RemoveActorFromWorkerArray(assignedActor)
				else
					; Debug.TraceUser(sLog, "Adding " + assignedActor + " to worker array and flagging bShouldTryToAssignResources to true.")
					WSFW_AddActorToWorkerArray(assignedActor, resourceIndex)
					bShouldTryToAssignResources = true
				endif
				
				if( ! bAlreadyAssigned && bUpdateObjectArray)
					; Debug.TraceUser(sLog, "Removing " + assignedObject + " from unassigned objects array.")
					UFO4P_RemoveFromUnassignedObjectsArray(assignedObject, resourceIndex)
				else
					; Debug.TraceUser(sLog, "Skipping removal of " + assignedObject + " from unassigned objects array. bAlreadyAssigned = " + bAlreadyAssigned + ", bUpdateObjectArray = " + bUpdateObjectArray)
				endif
			endif
		endif

		if(bAlreadyAssigned == false)
			; Debug.TraceUser(sLog, "This was a new assignment so sending WorkshopActorAssignedToWorkEvent.")
			SendWorkshopActorAssignedToWorkEvent(assignedActor, assignedObject, workshopRef)
		endif

		; WSWF - Ignore AutoAssign properties here so multi-assignment still works
		if( ! bResetMode && bShouldTryToAssignResources && workshopID == currentWorkshopID)
			; Debug.TraceUser(sLog, "Calling TryToAssignResourceType functions")
			TryToAssignResourceType(workshopRef, WorkshopRatings[WorkshopRatingFood].resourceValue)
			TryToAssignResourceType(workshopRef, WorkshopRatings[WorkshopRatingSafety].resourceValue)
		else
			; Debug.TraceUser(sLog, "Skipping TryToAssignResourceType functions, bResetMode = " + bResetMode + ", bShouldTryToAssignResources = " + bShouldTryToAssignResources + ", workshopID = " + workshopID + ", currentWorkshopID = " + currentWorkshopID)
		endif		
	endif
endFunction


; WSFW - Restored the vanilla signature to this function in case external scripts are calling it
function SetUnassignedPopulationRating(WorkshopScript workshopRef)
	SetUnassignedPopulationRating_Private(workshopRef, None)
endFunction

function SetUnassignedPopulationRating_Private(WorkshopScript workshopRef, ObjectReference[] WorkshopActors = none)
	if(WorkshopActors == none)
		if(UFO4P_IsWorkshopLoaded(workshopRef) == false)
			return
		endif
		
		WorkshopActors = GetWorkshopActors(workshopRef)
	endif

	int countActors = WorkshopActors.Length
	int unassignedPopulation = 0
	int i = 0
	while(i < countActors)
		Actor theActor = WorkshopActors[i] as Actor
		
		if(theActor && WorkshopFramework:WorkshopFunctions.IsWorker(theActor) == false && CaravanActorAliases.Find(theActor) < 0)
			unassignedPopulation += 1
		endif
		
		i += 1
	endWhile

	SetResourceData(WorkshopRatings[WorkshopRatingPopulationUnassigned].resourceValue, workshopRef, unassignedPopulation)
endFunction

; utility function for setting/clearing vendor data on an actor
function SetVendorData(WorkshopScript workshopRef, WorkshopNPCScript assignedActor, WorkshopObjectScript assignedObject, bool bSetData = true)
	if(assignedObject.VendorType > -1)
		WorkshopVendorType vendorData = WorkshopVendorTypes[assignedObject.VendorType]
		if(vendorData)
			; -- vendor faction
			if(bSetData)
				assignedActor.AddToFaction(vendorData.VendorFaction)
				
				if(vendorData.keywordToAdd01)
					assignedActor.AddKeyword(vendorData.keywordToAdd01)
				endif
			else
				assignedActor.RemoveFromFaction(vendorData.VendorFaction)
				if(vendorData.keywordToAdd01)
					assignedActor.RemoveKeyword(vendorData.keywordToAdd01)
				endif
			endif

			; -- assign vendor chests
			ObjectReference[] vendorContainers = workshopRef.GetVendorContainersByType(assignedObject.VendorType)
			int i = 0
			while(i <= assignedObject.vendorLevel)
				if(bSetData)
					assignedActor.SetLinkedRef(vendorContainers[i], VendorContainerKeywords.GetAt(i) as Keyword)
				else
					assignedActor.SetLinkedRef(NONE, VendorContainerKeywords.GetAt(i) as Keyword)
				endif
				
				i += 1
			endWhile

			; special vendor data
			if(bSetData)
				if(assignedActor.specialVendorType > -1 && assignedActor.specialVendorType == assignedObject.VendorType)
					; link to special vendor containers
					if(assignedActor.specialVendorContainerBase)
						; create the container ref if it doesn't exist yet
						if(assignedActor.specialVendorContainerRef == NONE)
							assignedActor.specialVendorContainerRef = WorkshopHoldingCellMarker.PlaceAtMe(assignedActor.specialVendorContainerBase)
						endif
						
						; link using 4th keyword
						assignedActor.SetLinkedRef(assignedActor.specialVendorContainerRef, VendorContainerKeywords.GetAt(VendorTopLevel+1) as Keyword)
					endif
					
					if(assignedActor.specialVendorContainerRefUnique)
						; link using 4th keyword
						assignedActor.SetLinkedRef(assignedActor.specialVendorContainerRefUnique, VendorContainerKeywords.GetAt(VendorTopLevel+2) as Keyword)
					endif
				endif
			else
				; always clear for safety
				if(assignedActor.specialVendorContainerRef)
					assignedActor.specialVendorContainerRef.Delete()
					assignedActor.specialVendorContainerRef = NONE
					; clear link
					assignedActor.SetLinkedRef(NONE, VendorContainerKeywords.GetAt(VendorTopLevel+1) as Keyword)
				endif
				
				if(assignedActor.specialVendorContainerRefUnique)
					; clear link
					assignedActor.SetLinkedRef(NONE, VendorContainerKeywords.GetAt(VendorTopLevel+2) as Keyword)
				endif

			endif

		else
			; ERROR
		endif
	elseif(assignedObject.sCustomVendorID != "") ; WSFW 2.0.0 - Adding support for custom vendors
		int iIndex = CustomVendorTypes.FindStruct("sVendorID", assignedObject.sCustomVendorID)
		if(iIndex >= 0)
			if(bSetData)
				assignedActor.AddToFaction(CustomVendorTypes[iIndex].VendorFaction)
				if(CustomVendorTypes[iIndex].VendorKeyword)
					assignedActor.AddKeyword(CustomVendorTypes[iIndex].VendorKeyword)
				endif
			else
				assignedActor.RemoveFromFaction(CustomVendorTypes[iIndex].VendorFaction)
				if(CustomVendorTypes[iIndex].VendorKeyword)
					assignedActor.RemoveKeyword(CustomVendorTypes[iIndex].VendorKeyword)
				endif
			endif

			; -- assign vendor chests
			ObjectReference[] vendorContainers = workshopRef.GetCustomVendorContainers(assignedObject.sCustomVendorID)
			
			int i = 0
			while(i <= assignedObject.vendorLevel)
				if(bSetData)
					assignedActor.SetLinkedRef(vendorContainers[i], VendorContainerKeywords.GetAt(i) as Keyword)
				else
					assignedActor.SetLinkedRef(NONE, VendorContainerKeywords.GetAt(i) as Keyword)
				endif
				
				i += 1
			endWhile
			
			; TODO - Add support for special vendors (see above section for stuff we skipped regarding special vendors for this function), will require special container registration, moving to 4 container levels, and an addition to the UpdateVendorFlags function
		else
			; ERROR
		endif
	endif
endFunction


function AssignCaravanActorPUBLIC(WorkshopNPCScript assignedActor, Location destinationLocation)
	; NOTE: package on alias uses two actor values to condition travel between the two workshops
	; lock editing
	GetEditLock()

	; get destination workshop
	WorkshopScript workshopDestination = GetWorkshopFromLocation(destinationLocation)

	; current workshop
	WorkshopScript workshopStart = GetWorkshop(assignedActor.GetWorkshopID())
	
	; unassign this actor from any current job
	; WSFW - Using Our Exclusion Check
	WorkshopFramework:WorkshopFunctions.UnassignActorSkipExclusions(assignedActor, workshopStart, aLastAssigned = WorkshopCaravanKeyword)

	; is this actor already assigned to a caravan?
	int caravanIndex = CaravanActorAliases.Find(assignedActor)
	if(caravanIndex < 0)
		; add to caravan actor alias collection
		CaravanActorAliases.AddRef(assignedActor)
		
		if(assignedActor.GetActorBase().IsUnique() == false && assignedActor.GetValue(WorkshopProhibitRename) == 0)
			; put in "rename" alias
			CaravanActorRenameAliases.AddRef(assignedActor)
		endif
	else
		; clear current location link
		Location oldDestination = GetWorkshop(assignedActor.GetCaravanDestinationID()).myLocation
		workshopStart.myLocation.RemoveLinkedLocation(oldDestination, WorkshopCaravanKeyword)
	endif
	
	int destinationID = workshopDestination.GetWorkshopID()

	; set destination actor value (used to find destination workshop from actor)
	assignedActor.SetValue(WorkshopCaravanDestination, destinationID)
	
	; make caravan ref type
	if(assignedActor.IsCreated())
		assignedActor.SetLocRefType(workshopStart.myLocation, WorkshopCaravanRefType)
	endif

	; add linked refs to actor (for caravan package)
	assignedActor.SetLinkedRef(workshopStart.GetLinkedRef(WorkshopLinkCenter), WorkshopLinkCaravanStart)
	
	assignedActor.SetLinkedRef(workshopDestination.GetLinkedRef(WorkshopLinkCenter), WorkshopLinkCaravanEnd)

	; add link between locations
	workshopStart.myLocation.AddLinkedLocation(workshopDestination.myLocation, WorkshopCaravanKeyword)

	assignedActor.SetValue (WorkshopRatings[WorkshopRatingPopulationUnassigned].resourceValue, 0)

	; 1.6: send custom event for this actor
	SendWorkshopActorCaravanAssignEvent(assignedActor, workshopStart, workshopDestination)

	; stat update
	Game.IncrementStat("Supply Lines Created")

	; unlock editing
	EditLock = false
endFunction

; call this to temporarily turn on/off a caravan actor - remove brahmin and unlink
function TurnOnCaravanActor(WorkshopNPCScript caravanActor, bool bTurnOn, bool bBrahminCheck = true)
	; find linked locations
	WorkshopScript workshopStart = GetWorkshop(caravanActor.GetWorkshopID())

	Location startLocation = workshopStart.myLocation
	Location endLocation = GetWorkshop(caravanActor.GetCaravanDestinationID()).myLocation

	if(bTurnOn)
		; add link between locations
		startLocation.AddLinkedLocation(endLocation, WorkshopCaravanKeyword)
	else
		; unlink locations
		startLocation.RemoveLinkedLocation(endLocation, WorkshopCaravanKeyword)
	endif

	if(bBrahminCheck)
		CaravanActorBrahminCheck(caravanActor, bTurnOn)
	endif
endFunction

; check to see if this actor needs a new brahmin, or if current brahmin should be flagged for delete
function CaravanActorBrahminCheck(WorkshopNPCScript actorToCheck, bool bShouldHaveBrahmin = true)
	; is my brahmin dead?
	if(actorToCheck.myBrahmin && actorToCheck.myBrahmin.IsDead())
		; clear
		CaravanBrahminAliases.RemoveRef(actorToCheck.myBrahmin)
		actorToCheck.myBrahmin = NONE
	endif

	; should I have a brahmin?
	if(CaravanActorAliases.Find(actorToCheck) > -1 && bShouldHaveBrahmin && actorToCheck.IsWounded() == false)
		; if I don't have a brahmin, make me a new one
		if(actorToCheck.myBrahmin == NONE)
			; WSFW 2.0.0 - Removed redundant actorToCheck.IsWounded() == false check
			actorToCheck.myBrahmin = actorToCheck.placeAtMe(CaravanBrahmin) as Actor
			actorToCheck.myBrahmin.SetActorRefOwner(actorToCheck)
			CaravanBrahminAliases.AddRef(actorToCheck.myBrahmin)
			actorToCheck.myBrahmin.SetLinkedRef(actorToCheck, WorkshopLinkFollow)
		endif
	else
		; clear and delete brahmin
		if(actorToCheck.myBrahmin)
			; clear this and mark brahmin for deletion
			Actor deleteBrahmin = actorToCheck.myBrahmin
			CaravanBrahminAliases.RemoveRef(deleteBrahmin)
			actorToCheck.myBrahmin = NONE
			deleteBrahmin.Delete()
			deleteBrahmin.SetLinkedRef(NONE, WorkshopLinkFollow)
		endif
	endif
endFunction

; called when player loses control of a workshop - clears all caravans to/from this workshop
function ClearCaravansFromWorkshopPUBLIC(WorkshopScript workshopRef)
	; NOTE: package on alias uses two actor values to condition travel between the two workshops
	
	; lock editing
	GetEditLock()

	; check all caravan actors for either belonging to this workshop, or targeting it - unassign them
	int i = CaravanActorAliases.GetCount() - 1 ; start at top of list since we may be removing things from it

	while(i	> -1)
		Actor theActor = CaravanActorAliases.GetAt(i) as Actor
		if(theActor)
			; check start and end locations
			int destinationWorkshopID = WorkshopFramework:WorkshopFunctions.GetCaravanDestinationID(theActor)
			
			WorkshopScript endWorkshop = GetWorkshop(destinationWorkshopID)
			WorkshopScript startWorkshop = GetWorkshop(WorkshopFramework:WorkshopFunctions.GetWorkshopID(theActor))
			
			if(endWorkshop == workshopRef || startWorkshop == workshopRef)
				; WSFW 2.0.0 - Calling method that doesn't require WorkshopNPCScript
				WorkshopFramework:WorkshopFunctions.UnassignActorFromCaravan(theActor, workshopRef, false)
			endif
		endif
		
		i += -1 ; decrement
	endWhile

	; unlock editing
	EditLock = false
endFunction


function AddToWorkshopRecruitAlias(Actor assignableActor)
	if(assignableActor)
		WorkshopRecruit.ForceRefTo(assignableActor)
	else
		WorkshopRecruit.Clear()
	endif
endFunction

; called by dialogue/quests to add non-persistent actor (not already in a dialogue quest alias) to workshop system using workshop settlement menu
; actorToAssign: if NONE, use the actor in WorkshopRecruit alias
location function AddActorToWorkshopPlayerChoice(Actor actorToAssign = NONE, bool bWaitForActorToBeAdded = true, bool bPermanentActor = false)
	if(actorToAssign == NONE)
		actorToAssign = WorkshopRecruit.GetActorRef()
	endif

	WorkShopNPCScript asWorkshopNPC = actorToAssign as WorkShopNPCScript
	
	keyword keywordToUse = WorkshopAssignHome
	if(bPermanentActor)
		keywordToUse = WorkshopAssignHomePermanentActor
	endif

	int previousWorkshopID = WorkshopFramework:WorkshopFunctions.GetWorkshopID(actorToAssign)
	WorkshopScript previousWorkshop = NONE
	if(previousWorkshopID >= 0)
		previousWorkshop = GetWorkshop(previousWorkshopID)
	endIf

	Location previousLocation = NONE
	if(previousWorkshop)
		previousLocation = previousWorkshop.myLocation
	endif

	; 102314: allow non-population actors to be assigned to any workshop
	FormList excludeKeywordList
	if(WorkshopFramework:WorkshopFunctions.CountsForPopulation(actorToAssign))
		excludeKeywordList = WorkshopSettlementMenuExcludeList
	endif 
	
	Location newLocation = actorToAssign.OpenWorkshopSettlementMenuEx(akActionKW=keywordToUse, aLocToHighlight=previousLocation, akExcludeKeywordList=excludeKeywordList)

	if(bWaitForActorToBeAdded && newLocation)
		; wait for menu to resolve (when called in scenes)
		int failsafeCount = 0
		while(failsafeCount < 5 && WorkshopFramework:WorkshopFunctions.GetWorkshopID(actorToAssign) == -1)
			failsafeCount += 1
			utility.wait(0.5)
		endWhile
	endif

	return newLocation	
endFunction

; called by dialogue/quests to add an existing actor to a workshop by bringing up workshop settlement menu
; actorToAssign: if NONE, use the actor in WorkshopRecruit alias
location function AddPermanentActorToWorkshopPlayerChoice(Actor actorToAssign = NONE, bool bWaitForActorToBeAdded = true)
	return AddActorToWorkshopPlayerChoice(actorToAssign, bWaitForActorToBeAdded, true)
endFunction

; called by dialogue/quests to add an existing actor to a workshop
; actorToAssign: if NONE, use the actor in WorkshopRecruit alias
; newWorkshopID: if -1, bring up message box to pick the workshop (TEMP)
function AddPermanentActorToWorkshopPUBLIC(Actor actorToAssign = NONE, int newWorkshopID = -1, bool bAutoAssign = true)
	WorkshopFramework:Library:UtilityFunctions.ModTrace("AddPermanentActorToWorkshopPUBLIC called on " + actorToAssign + " with workshop ID: " + newWorkshopID)
	if(actorToAssign == NONE)
		actorToAssign = WorkshopRecruit.GetActorRef()
	elseif(actorToAssign.IsDead())
		return
	endif
	
	WorkShopNPCScript asWorkshopNPC = actorToAssign as WorkShopNPCScript
	
	if(newWorkshopID < 0)
		actorToAssign.OpenWorkshopSettlementMenu(WorkshopAssignHomePermanentActor)
		; NOTE: event from menu is handled by WorkshopNPCScript
	else
		GetEditLock()

		WorkshopScript newWorkshop = GetWorkshop(newWorkshopID)
		
		; put in "ignore for cleanup" faction so that RE quests can shut down
		actorToAssign.AddToFaction(REIgnoreForCleanup)
		
		; remove from rescued faction to stop those hellos
		actorToAssign.RemoveFromFaction(REDialogueRescued)

		; make Boss loc ref type for this location
		if(actorToAssign.IsCreated())
			if(asWorkshopNPC)
				asWorkshopNPC.SetAsBoss(newWorkshop.myLocation)
			else
				WorkshopFramework:WorkshopFunctions.SetAsBoss(actorToAssign, newWorkshop.myLocation)
			endif
		endif
		
		WorkshopFramework:Library:UtilityFunctions.ModTrace("AddPermanentActorToWorkshopPUBLIC adding " + actorToAssign + " to PermanentActorAliases " + PermanentActorAliases)
		; add to alias collection for existing actors - gives them packages to stay at new "home"
		PermanentActorAliases.AddRef(actorToAssign)
		
		; add to the workshop
		if(asWorkshopNPC)
			AddActorToWorkshop(asWorkshopNPC, newWorkshop)
		else
			WorkshopFramework:WorkshopFunctions.AddActorToWorkshop(actorToAssign, newWorkshop, abResetMode = false)
		endif

		; try to automatically assign to do something:
		if(bAutoAssign && actorToAssign != DogmeatAlias.GetActorReference())
			TryToAutoAssignNPC(newWorkshop, actorToAssign)			
		endif
		
		;/ WSFW 2.0.3 - Moving to be called in AddActorToWorkshop so it fires for all actors not just uniques 
		; send custom event for this actor
		Var[] kargs = new Var[2]
		kargs[0] = actorToAssign
		kargs[1] = newWorkshopID
		SendCustomEvent("WorkshopAddActor", kargs)		
		/;
		; unlock editing
		EditLock = false
	endif
endFunction

; utility function used to assign home marker to workshop actor
function AssignHomeMarkerToActor(Actor actorToAssign, WorkshopScript workshopRef)
	; if sandbox link exists, use that - otherwise use center marker
	ObjectReference homeMarker = workshopRef.GetLinkedRef(WorkshopLinkSandbox)
	if(homeMarker == NONE)
		homeMarker = workshopRef.GetLinkedRef(WorkshopLinkCenter)
	endif
	
	actorToAssign.SetLinkedRef(homeMarker, WorkshopLinkHome)
endFunction


function AddCollectionToWorkshopPUBLIC(RefCollectionAlias thecollection, WorkshopScript workshopRef, bool bResetMode = false)
	GetEditLock()
	int i = 0
	while(i < theCollection.GetCount())
		Actor theActor = theCollection.GetAt(i) as Actor
		if(theActor)
			WorkshopNPCScript asWorkshopNPC = theActor as WorkshopNPCScript
			if(asWorkshopNPC)
				AddActorToWorkshop(asWorkshopNPC, workshopRef, bResetMode)
			elseif( ! bResetMode && theActor.GetValue(WorkshopRatings[WorkshopRatingPopulation].resourceValue) > 0)
				; WSFW 2.0.1 - Checking for bResetMode, as that is used by initialization scripts and we don't want to add random NPCs to the workshop like that. We only want the AddCollectionToWorkshopPUBLIC to function when modders are trying to bulk add NPCs
				; WSFW 2.0.0 - Switching to global function for nonWorkshopNPCScript actors
				WorkshopFramework:WorkshopFunctions.AddActorToWorkshop(theActor, workshopRef, abResetMode = bResetMode)
			endif
		endif
			
		i += 1
	endWhile

	; unlock editing
	EditLock = false
endFunction

; called by external scripts to assign or reassign a workshop actor to a new workshop location
function AddActorToWorkshopPUBLIC(WorkshopNPCScript assignedActor, WorkshopScript workshopRef, bool bResetMode = false)
	GetEditLock()

	AddActorToWorkshop(assignedActor, workshopRef, bResetMode)

	; unlock editing
	EditLock = false
endFunction


function AddActorToWorkshop(WorkshopNPCScript assignedActor, WorkshopScript workshopRef, bool bResetMode = false, ObjectReference[] WorkshopActors = NONE)
	bool bResetHappiness = false

	; WSFW - Skip based on autoassign settings
	Bool bAutoAssignBeds = AutoAssignBeds
	if( ! workshopRef.OwnedByPlayer)
		bAutoAssignBeds = true
	endif
	
	if(WorkshopActors == NONE)
		WorkshopActors = GetWorkshopActors(workshopRef)
	endif

	bool bAlreadyAssigned = false
	bool UFO4P_RecalcResourcesForOldWorkshop = false
	int oldWorkshopID = assignedActor.GetWorkshopID()
	int newWorkshopID = workshopRef.GetWorkshopID()


	if(WorkshopActors.Find(assignedActor) > -1 && oldWorkshopID == newWorkshopID)
		; if already in the list and not in reset mode, return
		if( ! bResetMode)
			return
		endif
		
		bAlreadyAssigned = true
	else
		if(oldWorkshopID > -1 && oldWorkshopID != newWorkshopID)
			UnassignActor_PrivateV2(assignedActor, bRemoveFromWorkshop = true, bSendUnassignEvent = true, bResetMode = bResetMode, bNPCTransfer = true)
			
			assignedActor.bNewSettler = false
			
			; remember this, so we don't have to check the workshopIDs again
			UFO4P_RecalcResourcesForOldWorkshop = true
		endif
	endif

	if( ! bAlreadyAssigned)
		assignedActor.SetWorkshopID (newWorkshopID)

		if(workshopRef.SettlementOwnershipFaction && workshopRef.UseOwnershipFaction && assignedActor.bApplyWorkshopOwnerFaction)
			if(assignedActor.bCountsForPopulation)
				assignedActor.SetCrimeFaction(workshopRef.SettlementOwnershipFaction)
			else
				assignedActor.SetFactionOwner(workshopRef.SettlementOwnershipFaction)
			endif
		endif

		assignedActor.SetLinkedRef( workshopRef, WorkshopItemKeyword)
		AssignHomeMarkerToActor(assignedActor, workshopRef)
		
		if(oldWorkshopID < 0)
			; Only apply if a new settler, this will allow for mods to have removed this set of packages if they wanted to create alternate AI sets
			ApplyWorkshopAliasData(assignedActor)
		endif
		
		assignedActor.UpdatePlayerOwnership(workshopRef)

		if(UFO4P_RecalcResourcesForOldWorkshop)
			WorkshopScript oldWorkshopRef = GetWorkshop(oldWorkshopID)		
			if(oldWorkshopRef)
				oldWorkshopRef.RecalculateWorkshopResources()
			endif
		endif

		if(assignedActor.bCountsForPopulation)
			int totalPopulation = workshopRef.GetBaseValue(WorkshopRatings[WorkshopRatingPopulation].resourceValue) as int
			float currentHappiness = workshopRef.GetValue(WorkshopRatings[WorkshopRatingHappiness].resourceValue)
			
			
			if(totalPopulation == 0)
				SetResourceData (WorkshopRatings[WorkshopRatingHappinessModifier].resourceValue, workshopRef, 0)
				
				if(bResetMode)
					SetResourceData(WorkshopRatings[WorkshopRatingHappiness].resourceValue, workshopRef, startingHappiness)
					SetResourceData(WorkshopRatings[WorkshopRatingHappinessTarget].resourceValue, workshopRef, startingHappiness)
				else
					bResetHappiness = true
				endif
				SetResourceData(WorkshopRatings[WorkshopRatingLastAttackDaysSince].resourceValue, workshopRef, 99)
			endif
			
			assignedActor.SetValue(WorkshopRatings[WorkshopRatingPopulationUnassigned].resourceValue, 1)
			UpdateVendorFlagsAll(workshopRef)
		endif
	
		if(assignedActor.IsCreated())
			assignedActor.SetPersistLoc(workshopRef.myLocation)
			
			if(assignedActor.bIsSynth)
				assignedActor.SetLocRefType (workshopRef.myLocation, WorkshopSynthRefType)
			elseif assignedActor.bCountsForPopulation
				assignedActor.SetAsBoss (workshopRef.myLocation)
			endif
			
			assignedActor.ClearFromOldLocations() ; 101931: make sure location data is correct
		else
			; WSWF - When an NPC is first added we want to assign 
			bAutoAssignBeds = true
		endif

		if(workshopRef.PlayerHasVisited)
			assignedActor.SetWorker(false)
		endif

		;If workshop is currently loaded, also save all new actors that are not robots in the UFO4P_ActorsWithoutBeds array.
		;Otherwise, the new version of the TryToAssignBeds function won't find them.
		if(assignedActor.GetBaseValue (WorkshopRatings[WorkshopRatingPopulationRobots].resourceValue) == 0 && newWorkshopID == currentWorkshopID)
			; WSWF - Likely the UFO4P patch would have added this change as well, but hasn't done so yet
			WSFW_AddToActorsWithoutBedsArray(assignedActor)
		endif		
	endif

	if(bResetMode)
		assignedActor.multiResourceProduction = 0.0
		
		ActorValue multiResourceValue = assignedActor.assignedMultiResource
		if(multiResourceValue)
			UFO4P_AddActorToWorkerArray(assignedActor, GetResourceIndex (multiResourceValue))
		endif
	endif

	;Even if not in reset mode, this should not run if the workshop is not loaded:
	if( ! bResetMode && newWorkshopID == currentWorkshopID && bAutoAssignBeds) 
		TryToAssignBeds(workshopRef)
	endif

	assignedActor.EvaluatePackage()

	if( ! bResetMode && ! workshopRef.RecalculateWorkshopResources()) ; 2.0.2 - Added bResetMode check
		; WSWF - Added if(assignedActor.bCountsForPopulation) to ensure it isn't increased when sending those NPCs
		if(assignedActor.bCountsForPopulation)
			ModifyResourceData(WorkshopRatings[WorkshopRatingPopulation].resourceValue, workshopRef, 1)
		endif
	endif

	if( ! bResetMode && bResetHappiness)
		ResetHappiness (workshopRef)
	endif
	
	
	if( ! bResetMode && ! bAlreadyAssigned)
		; WSFW 2.0.3 - Previously, this event was only being fired for unique actors which made it far less useful
		Var[] kargs = new Var[2]
		kargs[0] = assignedActor
		kargs[1] = newWorkshopID
		SendCustomEvent("WorkshopAddActor", kargs)
	endif
endFunction


; WSFW: WARNING - This is not ready for use yet and the signature may change
Function WSFW_AddActorToLocationPUBLIC(Actor assignedActor, Location assignedLocation, Keyword assignedKeyword)
	; TODO: Implement actual AddActorToLocation function to handle work
    wsTrace("    WSFW_AddActorToLocationPUBLIC: " + assignedActor)
    var[] akArgs = new var[3]
    akArgs[0] = assignedActor
    akArgs[1] = assignedLocation
    akArgs[2] = assignedKeyword
    SendCustomEvent("WSFW_LocationAddActor", akArgs)
EndFunction


function ResetHappiness(WorkshopScript workshopRef)
	workshopRef.StartTimer(3.0, UFO4P_DailyUpdateResetHappinessTimerID)	
endFunction

function ResetHappinessPUBLIC(WorkshopScript workshopRef)
	GetEditLock()
	
	float happinessTarget = workshopRef.GetValue(WorkshopRatings[WorkshopRatingHappinessTarget].resourceValue)
	; if current target below min, set target to min
	if(happinessTarget < startingHappinessMin)
		happinessTarget = startingHappinessMin
		SetResourceData(WorkshopRatings[WorkshopRatingHappinessTarget].resourceValue, workshopRef, happinessTarget)
	endif
	
	; set happiness to target
	SetResourceData(WorkshopRatings[WorkshopRatingHappiness].resourceValue, workshopRef, happinessTarget)
	
	EditLock = false
endFunction;


; call to stamp actor with WorkshopActorApply alias data
function ApplyWorkshopAliasData(actor theActor)
	WorkshopActorApply.ApplyToRef(theActor)
endFunction


function UnassignActorFromObjectPUBLIC(WorkshopNPCScript theActor, WorkshopObjectScript theObject, bool bSendUnassignEvent = true, bool bTryToAssignResources = true)
	int workshopID = theActor.GetWorkshopID()
	
	;WSFW 2.0.0 - Removed current workshop requirement - have not found the logic for this as tracing through sub functions this ends up calling, none of them care if the settlement is loaded or not.
	
	GetEditLock()

	; WSFW 1.0.8a - preserving signature
	UnassignActorFromObjectV2(theActor, theObject, bSendUnassignEvent, bResetMode = false)
	
	if(bTryToAssignResources && ! UFO4P_AttackRunning)
		WorkshopScript workshopRef = GetWorkshop (workshopID)
		; WSFW 1.0.8a - acknowledge auto assign settings
		if(theObject.IsBed() && ( ! workshopRef.OwnedByPlayer || AutoAssignBeds))
			TryToAssignBeds(workshopRef)
		elseif(theObject.HasMultiResource())
			int resourceIndex = theObject.GetResourceID()
			bool bAllowAssign = true
			
			if(workshopRef.OwnedByPlayer)
				if((resourceIndex == WorkshopRatingFood && ! AutoAssignFood) || (resourceIndex == WorkshopRatingSafety && ! AutoAssignDefense))
					bAllowAssign = false
				endif
			endif
			
			if(bAllowAssign)
				TryToAssignResourceType(workshopRef, WorkshopRatings[resourceIndex].resourceValue)
			endif
		endif
	endif

	EditLock = false
endFunction

function UnassignActorFromObject(WorkshopNPCScript theActor, WorkshopObjectScript theObject, bool bSendUnassignEvent = true)
	UnassignActorFromObjectV2(theActor, theObject, bSendUnassignEvent)
endfunction

; WSFW 1.0.8a - Creating new version to avoid signature change caused by WSFW 1.0.6
function UnassignActorFromObjectV2(WorkshopNPCScript theActor, WorkshopObjectScript theObject, bool bSendUnassignEvent = true, bool bResetMode = false)
	; do I currently own this object?
	if(theObject.GetActorRefOwner() == theActor)
		UnassignObject_Private(theObject, bUnassignActorMode = bResetMode)
		
		if(bSendUnassignEvent)
			WorkshopScript workshopRef = GetWorkshop(theActor.GetWorkshopID())
			SendWorkshopActorUnassignedEvent(theObject, workshopRef, theActor)
		endif
	endif
endFunction


function RemoveActorFromWorkshopPUBLIC(WorkshopNPCScript theActor)
	; lock editing
	GetEditLock()

	UnassignActor_PrivateV2(theActor, bRemoveFromWorkshop = true, bSendUnassignEvent = true, bResetMode = false, bNPCTransfer = false)

	; unlock editing
	EditLock = false
endFunction

function UnassignActor(WorkshopNPCScript theActor, bool bRemoveFromWorkshop = false, bool bSendUnassignEvent = true)
	GetEditLock()
	
	UnassignActor_PrivateV2(theActor, bRemoveFromWorkshop, bSendUnassignEvent, bResetMode = false, bNPCTransfer = false)
	
	EditLock = false
EndFunction

function UnassignActor_Private(WorkshopNPCScript theActor, bool bRemoveFromWorkshop = false, bool bSendUnassignEvent = true, bool bResetMode = false)
	UnassignActor_PrivateV2(theActor, bRemoveFromWorkshop, bSendUnassignEvent, bResetMode)
EndFunction

; UFO4P 2.0.6, WSFW 1.0.8a, Added new arg, so versioning the function to maintain signatures
function UnassignActor_PrivateV2(WorkshopNPCScript theActor, bool bRemoveFromWorkshop = false, bool bSendUnassignEvent = true, bool bResetMode = false, bool bNPCTransfer = false)
	int workshopID = theActor.GetWorkshopID()
	
	if(workshopID < 0)
		return
	endif
	
	WorkshopScript workshopRef = GetWorkshop (workshopID)
	bool bWorkshopLoaded = (workshopID == currentWorkshopID)
	
	int caravanActorIndex = CaravanActorAliases.Find (theActor)
	if(caravanActorIndex >= 0)
		; WSFW - Moved Caravan Unassignment to its own function
		UnassignActorFromCaravan(theActor, workshopRef, bRemoveFromWorkshop)
	endif
	
	bool bShouldTryToAssignResources = false
	bool bSendCollectiveEvent = false
	
	if(bWorkshopLoaded == false)
		UFO4P_RegisterUnassignedActor(theActor)
		;Also set a tracking bool on the actor's workshop:
		workshopRef.UFO4P_HandleUnassignedActors = true
	endif

	ObjectReference[] ResourceObjects = workshopRef.GetWorkshopOwnedObjects(theActor)
	int countResourceObjects = ResourceObjects.Length
	int i = 0
	while(i < countResourceObjects)
		ObjectReference objectRef = ResourceObjects[i]
		WorkshopObjectScript theObject = objectRef as WorkshopObjectScript
		
		if(theObject != none && theObject.HasKeyword (WorkshopWorkObject))
			bool bIsBed = theObject.IsBed()
			
			;don't remove the bed if the actor is not removed from the workshop:
			if(bIsBed == false || bRemoveFromWorkshop)
				UnassignObject_Private(theObject, bUnassignActorMode = true)
				
				;No need to send events on unassigned beds. The quests that deal with beds don't care whether they are assigned or not.
				if(bSendUnassignEvent && bIsBed == false)
					if(theObject.HasMultiResource())							
						if(bWorkshopLoaded)
							bSendCollectiveEvent = true
						else
							;using the bResetDone flag on WorkshopObjectScript to tag the object:
							theObject.bResetDone = true
						endif
					else	
						SendWorkshopActorUnassignedEvent(theObject, workshopRef, theActor)
					endif
				endif
			endif
		endif
		i += 1
	endWhile
	
	;Clear all worker flags: doing this even if we can't be sure that all objects have been unassigned (i.e. if the workshop was not loaded) since
	;we need to make sure that the actor will count as unassigned from any job.
	theActor.SetMultiResource(none)
	theActor.SetWorker(false)
	theActor.bWork24Hours = false
	
	;if workshop is loaded, also make sure that the actor gets removed from the worker arrays to prevent him from automatically becoming reassigned:
	if(bWorkshopLoaded && caravanActorIndex < 0)
		UFO4P_RemoveActorFromWorkerArray(theActor)
	endif

	if(! bRemoveFromWorkshop)
		theActor.SetValue (WorkshopRatings[WorkshopRatingPopulationUnassigned].resourceValue, 1)

		;Note: bShouldTryToAssignResources is never true if bWorkshopLoaded = false:
		if(bShouldTryToAssignResources)
			workshopRef.RecalculateWorkshopResources()
		endif
	else
		theActor.SetLinkedRef(NONE, WorkshopItemKeyword)
		theActor.SetLinkedRef(NONE, WorkshopLinkHome)

		if(bNPCTransfer == false)
			WorkshopActorApply.RemoveFromRef (theActor)
			PermanentActorAliases.RemoveRef (theActor)
			theActor.SetValue(WorkshopPlayerOwnership, 0)
		endif

		; PATCH - remove workshop ID as well
		theActor.SetWorkshopID (-1)

		; update population rating on workshop's location
		if(workshopRef.RecalculateWorkshopResources() == false)
			if(theActor.bCountsForPopulation)
				ModifyResourceData(WorkshopRatings[WorkshopRatingPopulation].resourceValue, workshopRef, -1)
			elseif(theActor.GetActorBase() == WorkshopBrahmin)
				ModifyResourceData(WorkshopRatings[WorkshopRatingBrahmin].resourceValue, workshopRef, 1)
			endif
		endif

		; WSFW New Event
		Var[] kArgs = new Var[0]
		kArgs.Add(theActor)
		kArgs.Add(workshopRef)
		
		SendCustomEvent("WorkshopRemoveActor", kArgs)
	endif

	if(bSendCollectiveEvent)
		SendWorkshopActorUnassignedEvent(None, workshopRef, theActor)
	endif

	if( ! bResetMode && bRemoveFromWorkshop && bShouldTryToAssignResources && ! UFO4P_AttackRunning)
		if(AutoAssignFood || ! workshopRef.OwnedByPlayer)
			TryToAssignResourceType(workshopRef, WorkshopRatings[WorkshopRatingFood].resourceValue)
		endif
		
		if(AutoAssignDefense || ! workshopRef.OwnedByPlayer)
			TryToAssignResourceType(workshopRef, WorkshopRatings[WorkshopRatingSafety].resourceValue)
		endif
		
		;If actor was removed from workshop, there may be an unassigned bed now:
		if(bRemoveFromWorkshop && (AutoAssignBeds || ! workshopRef.OwnedByPlayer))
			TryToAssignBeds(workshopRef)
		endif
	endif
endFunction

; WSFW - Refactoring caravan unassignment to its own function
Function UnassignActorFromCaravan(WorkshopNPCScript theActor, WorkshopScript workshopRef, Bool bRemoveFromWorkshop = false)
	CaravanActorAliases.RemoveRef(theActor)
	CaravanActorRenameAliases.RemoveRef(theActor)
	; unlink locations
	Location startLocation = workshopRef.myLocation
	Location endLocation = GetWorkshop(theActor.GetCaravanDestinationID()).myLocation
	startLocation.RemoveLinkedLocation(endLocation, WorkshopCaravanKeyword)
	
	; clear caravan brahmin
	CaravanActorBrahminCheck(theActor)

	; set back to Boss - UFO4P 2.0.4 Bug #24263: but only if we don't remove him from the workshop:
	if(theActor.IsCreated() && ! bRemoveFromWorkshop)
		; Patch 1.4: allow custom loc ref type on workshop NPC
		theActor.SetAsBoss(startLocation)
	endif

	; WSFW - Since we introduced the possibility of caravan owners having other jobs, we don't want to automatically assume this leaves them unassigned
	if( ! bRemoveFromWorkshop && ! IsObjectOwner(workshopRef, theActor))
		; update workshop rating - increment unassigned actors total
		theActor.SetValue(WorkshopRatings[WorkshopRatingPopulationUnassigned].resourceValue, 1)
	endif

	; 1.6: send custom event for this actor
	SendWorkshopActorCaravanUnassignEvent(theActor, workshopRef)
EndFunction

; WSFW - Reverting this to its original signature to avoid causing conflicts with mods that opted to call this directly based on it's original design
function UnassignObject(WorkshopObjectScript theObject, bool bRemoveObject = false)
	; WSFW - Refactored version of UnassignObject
	UnassignObject_Private(theObject, bRemoveObject, false)
endFunction

; WSFW - Refactored version of UnassignObject to allow UFO4P idea to live on without breaking the original function signature
function UnassignObject_Private(WorkshopObjectScript theObject, bool bRemoveObject = false, bool bUnassignActorMode = false)
	WorkshopScript workshopRef = none
	int UFO4P_WorkshopID = theObject.workshopID
	
	if(UFO4P_WorkshopID >= 0)
		workshopRef = GetWorkshop(UFO4P_WorkshopID)
	endIf

	Actor assignedActor = theObject.GetActorRefOwner()
	
	bool bShouldTryToAssignBeds = false
	int iResourceIndexToAssign = -1
	
	if(assignedActor)
		WorkshopNPCScript asWorkshopNPC = assignedActor as WorkshopNPCScript
		
		theObject.AssignActor(none)

		keyword actorLinkKeyword = theObject.AssignedActorLinkKeyword
		if(actorLinkKeyword)
			assignedActor.SetLinkedRef(NONE, actorLinkKeyword)
		endif

		if(UFO4P_WorkshopID >= 0)
			if(theObject.VendorType > -1 || theObject.sCustomVendorID != "")
				; WSFW - 2.0.0 Added check for sCustomVendorID
				if(asWorkshopNPC)
					SetVendorData(workshopRef, asWorkshopNPC, theObject, false)
				else
					WorkshopFramework:WorkshopFunctions.SetVendorData(workshopRef, assignedActor, theObject, bSetData = false)
				endif
			endif

			bool bIsBed = theObject.IsBed()

			;if workshop is currently loaded and object is a bed or multi-resource object, add it to the respective object array:
			if(UFO4P_WorkshopID == currentWorkshopID)
				if(bRemoveObject && bIsBed)
					;Note: if this  function is called by UnassignActrr_Private, bRemoveObject is never true, so there is no risk here to add an actor to
					;the array who is subsequently removed from the workshop.
					WSFW_AddToActorsWithoutBedsArray(assignedActor) ; 2.0.0 - Switched to nonWorkshopNPCScript actors array
					
					bShouldTryToAssignBeds = true
				elseif( ! bRemoveObject)
					if(bIsBed)
						UFO4P_AddUnassignedBedToArray(theObject)
					elseif(theObject.HasMultiResource())
						UFO4P_AddObjectToObjectArray(theObject)
					endif
				endif
			endif

			;If object is a bed, this code can be skipped: removal of a bed has no impact on an actor's worker status
			if(bIsBed == false && ! bUnassignActorMode)
				if(WorkshopFramework:WorkshopFunctions.IsObjectOwner(workshopRef, assignedActor) == false)
					assignedActor.SetValue (WorkshopRatings[WorkshopRatingPopulationUnassigned].resourceValue, 1)
					
					if(asWorkshopNPC)
						asWorkshopNPC.SetMultiResource(none)
						asWorkshopNPC.SetWorker(false)
						asWorkshopNPC.bWork24Hours = false
					else
						WorkshopFramework:WorkshopFunctions.SetAssignedMultiResource(assignedActor, None)
						WorkshopFramework:WorkshopFunctions.SetWorker(assignedActor, false)
						WorkshopFramework:WorkshopFunctions.SetWork24Hours(assignedActor, false)
					endIf
					
					;if workshop is currently loaded, also make sure that the actor gets removed from the worker arrays:
					if(UFO4P_WorkshopID == currentWorkshopID)
						WSFW_RemoveActorFromWorkerArray(assignedActor)
					endif
				else
					actorValue multiResourceValue = WorkshopFramework:WorkshopFunctions.GetAssignedMultiResource(assignedActor)
					
					if(multiResourceValue && theObject.HasResourceValue(multiResourceValue))
						float previousProduction = WorkshopFramework:WorkshopFunctions.GetMultiResourceProduction(assignedActor)
						
						WorkshopFramework:WorkshopFunctions.SetMultiResourceProduction(assignedActor, previousProduction - theObject.GetBaseValue(multiResourceValue))
						
						if(UFO4P_WorkshopID == currentWorkshopID)
							iResourceIndexToAssign = GetResourceIndex(multiResourceValue)
							WSFW_AddActorToWorkerArray(assignedActor, iResourceIndexToAssign)
						endif
					endif
				endif
			endif
		endif	
	else
		;If a work object is removed that was not assigned to an actor, we have to make sure that it is no longer in the unassigned object arrays.
		if(bRemoveObject)
			if(theObject.IsBed())
				UFO4P_RemoveFromUnassignedBedsArray(theObject)
			elseif(theObject.HasMultiResource())
				UFO4P_RemoveFromUnassignedObjectsArray(theObject, theObject.GetResourceID())
			endif
		endif
	endif

	if(UFO4P_WorkshopID >= 0 && (assignedActor || bRemoveObject))
		UpdateWorkshopRatingsForResourceObject(theObject, workshopRef, bRemoveObject, bRecalculateResources = !bUnassignActorMode)
		
		if(bRemoveObject)
			if(iResourceIndexToAssign >= 0)
				; WSWF 1.0.8a - Check autoassign settings
				bool bAllowAssign = true
				if(iResourceIndexToAssign == WorkshopRatingFood)
					if(workshopRef.OwnedByPlayer && ! AutoAssignFood)
						bAllowAssign = false
					endif
				elseif(iResourceIndexToAssign == WorkshopRatingSafety)
					if(workshopRef.OwnedByPlayer && ! AutoAssignDefense)
						bAllowAssign = false
					endif
				endif
				
				if(bAllowAssign)
					TryToAssignResourceType(workshopRef, WorkshopRatings[iResourceIndexToAssign].resourceValue)
				endif
			endif
			
			; WSFW 1.0.8a - Check autoassign settings
			if(bShouldTryToAssignBeds && AutoAssignBeds)
				TryToAssignBeds(workshopRef)
			endif
		endif
	endif
endFunction


function AssignObjectToWorkshop(WorkshopObjectScript workObject, WorkshopScript workshopRef, bool bResetMode = false)
	; bResetMode: true means to ignore TryToAssignFarms/Beds calls (ResetWorkshop calls it once at the end)
	String sLog = "aaaObject"
	Debug.OpenUserLog(sLog)
	; Debug.TraceUser(sLog, "AssignObjectToWorkshop called on " + workObject + ", bResetMode = " + bResetMode)
	int workshopID = workshopRef.GetWorkshopID()
	
	Actor owner = workObject.GetActorRefOwner()
	WorkShopNPCScript asWorkshopNPC
	if(owner)
		; Debug.TraceUser(sLog, workObject + " has owner " + owner)
		asWorkshopNPC = owner as WorkshopNPCScript
	endIf
	
	if(workObject.IsBed())
		bool UFO4P_Owned = false
		
		if(owner)
			if(owner.GetBaseValue(WorkshopRatings[WorkshopRatingPopulationRobots].resourceValue) > 0)
				workObject.AssignActor(None)
			else
				ObjectReference[] WorkshopActors = GetWorkshopActors (workshopRef)
				int actorIndex = WorkshopActors.Find(owner)
				
				if(actorIndex == -1)
					workObject.AssignActor(None)
				else
					UFO4P_Owned = true
				endif
			endif
		endif

		;if workshop is the current workshop, add all unowned beds to the UFO4P_UnassignedBeds array:
		if(UFO4P_Owned == false && workshopRef.GetWorkshopID() == currentWorkshopID)
			UFO4P_AddUnassignedBedToArray(workObject)
			
			if( ! bResetMode && AutoAssignBeds)
				TryToAssignBeds(workshopRef)
			endif
		endif
	else
		; Debug.TraceUser(sLog, workObject + " is not a bed.")
		bool UFO4P_ShouldUpdateRatings = true

		;UFO4P 2.0.6 Bug #25215. removed the check for IsActorAssigned() (was superfluous with our followup check to GetAssignedActor)
		if(workObject.HasKeyword (WorkshopWorkObject))
			; Debug.TraceUser(sLog, workObject + " has assignable keyword WorkshopWorkObject.")
			bool UFO4P_ShouldSendEvent = false		
			
			if(owner)
				bool bObjectHandled = false
				
				if(bResetMode && workshopRef.UFO4P_HandleUnassignedActors)
					int unassignedActorID = UFO4P_UnassignedActors.Find(owner)
					
					if(unassignedActorID > -1)
						; WSFW - Need to do another exclusion check here
						if(IsExcludedFromAssignmentRules(workObject))
							Var[] kargs = new Var[0]
							kargs.Add(workObject)
							kargs.Add(workshopRef)
							kargs.Add(owner)
							kargs.Add(workObject) ; WSFW 1.0.6 - Also sending last assigned ref so handling code can decide whether to prioritize it
							
							SendCustomEvent("AssignmentRulesOverriden", kargs)
						else
							workObject.AssignActor(None)

							keyword actorLinkKeyword = workObject.AssignedActorLinkKeyword
							if(actorLinkKeyword)
								owner.SetLinkedRef (NONE, actorLinkKeyword)
							endif

							;UFO4P 2.0.6 Bug #25238: added this line:
							UFO4P_ShouldSendEvent = true
						
							;Store unassignedActorID in a separate array, so we know which actors to remove after ResetWorkshop() has finished looping through the
							;resource object arrays (we can't remove him now because there may be other objects to handle).
							UFO4P_StoreUnassignedActorID(unassignedActorID)
						endif
						
						bObjectHandled = true
						
						;UFO4P 2.0.6 Bug #25238: added this line, just to make sure:
						workObject.bResetDone = false
					endif
				endif
								
				if(bObjectHandled == false)
					ObjectReference[] WorkshopActors = GetWorkshopActors(workshopRef)
					int actorIndex = WorkshopActors.Find(owner)
					
					if(actorIndex > -1)
						if(asWorkshopNPC)
							AssignActorToObject(asWorkshopNPC, workObject, bResetMode = bResetMode, bAddActorCheck = false)
						else
							; WSFW 2.0.0 - Calling our global function for non WorkshopNPCScript actors
							WorkshopFramework:WorkshopFunctions.AssignActorToObject(workObject, owner, abAutoHandleAssignmentRules = true, abAutoUpdateActorStatus = true, abRecalculateWorkshopResources = ( ! bResetMode))
						endif
						
						; NOTE don't need to call UpdateWorkshopRatingsForResourceObject - this is called in AssignActorToObject
						UFO4P_ShouldUpdateRatings = false
					else
						workObject.AssignActor(None)
					endif
				endif
			elseif(workObject.bResetDone)
				UFO4P_ShouldSendEvent = true
				workObject.bResetDone = false
			endif
						
			if(UFO4P_ShouldSendEvent)
				;We must update the ratings (and recalculate the workshop resources) before sending the event because the quests that listen to
				;this event may need the updated ratings values to process it:
				UpdateWorkshopRatingsForResourceObject (workObject, workshopRef, bRecalculateResources = true)
				
				UFO4P_ShouldUpdateRatings = false
				
				SendWorkshopActorUnassignedEvent(workObject, workshopRef, owner)	
			endif
		endif
		
		if(UFO4P_ShouldUpdateRatings)
			UpdateWorkshopRatingsForResourceObject(workObject, workshopRef, bRecalculateResources = ( ! bResetMode))
		endif

		if(workObject.HasMultiResource() && workObject.HasKeyword(WorkshopWorkObject) && workObject.IsActorAssigned() == false)
			; Debug.TraceUser(sLog, workObject + " has a multiResource, let's try to assign it.")
			actorValue multiResourceValue = workObject.GetMultiResourceValue()
			
			;Don't try to assign damaged objects:
			if(workObject.GetBaseValue(multiResourceValue) == workObject.GetValue(multiResourceValue))
				UFO4P_AddObjectToObjectArray(workObject)
				; Debug.TraceUser(sLog, workObject + " added to unassigned array.")
				
				if( ! bResetMode)
					; Debug.TraceUser(sLog, "Calling TryToAssignResourceType on " + multiResourceValue)
					TryToAssignResourceType(workshopRef, multiResourceValue)
				else
					; Debug.TraceUser(sLog, "bResetMode, skipping call to TryToAssignResourceType for " + workObject)
				endif
			endif
		else
			; Debug.TraceUser(sLog, "Bypassed TryToAssignResourceType section. " + workObject + " hworkObject.HasMultiResource() = " + workObject.HasMultiResource() + ", workObject.HasKeyword(WorkshopWorkObject) = " + workObject.HasKeyword(WorkshopWorkObject) + ", workObject.IsActorAssigned() = " + workObject.IsActorAssigned())
		endif
	endif
endFunction

; turn on/off radio
function UpdateRadioObject(WorkshopObjectScript radioObject)
	WorkshopScript workshopRef = GetWorkshop(radioObject.workshopID)
	
	; radio
	if(radioObject.bRadioOn && radioObject.IsPowered())
		; make me a transmitter and start radio scene
		if(workshopRef.WorkshopRadioRef)
			workshopRef.WorkshopRadioRef.Enable() ; enable in case this is a unique station
			
			radioObject.MakeTransmitterRepeater(workshopRef.WorkshopRadioRef, workshopRef.workshopRadioInnerRadius, workshopRef.workshopRadioOuterRadius)
			
			if(workshopRef.WorkshopRadioScene)
				if(workshopRef.WorkshopRadioScene.IsPlaying() == false)
					workshopRef.WorkshopRadioScene.Start()
				endif
			elseif(WorkshopRadioScene01.IsPlaying() == false)
				WorkshopRadioScene01.Start()
			endif
		else 
			radioObject.MakeTransmitterRepeater(WorkshopRadioRef, workshopRadioInnerRadius, workshopRadioOuterRadius)
			
			if(WorkshopRadioScene01.IsPlaying() == false)
				WorkshopRadioScene01.Start()
			endif
		endif
		
		if(workshopRef.RadioBeaconFirstRecruit == false)
			WorkshopEventRadioBeacon.SendStoryEvent(akRef1 = workshopRef)
		endif
	else		
		radioObject.MakeTransmitterRepeater(NONE, 0, 0)
		
		; if unique radio, turn it off completely
		if(workshopRef.WorkshopRadioRef && workshopRef.bWorkshopRadioRefIsUnique)
			workshopRef.WorkshopRadioRef.Disable()
			
			; stop custom scene if unique
			workshopRef.WorkshopRadioScene.Stop()
		endif
	endif
	
	; send power change event so quests can react to this
	workshopRef.RecalculateWorkshopResources()
	SendPowerStateChangedEvent(radioObject, workshopRef)
endFunction

; call any time an object's status changes
; adds/removes this object's ratings to the workshop's ratings
; also updates the object's production flag
function UpdateWorkshopRatingsForResourceObject(WorkshopObjectScript workshopObject, WorkshopScript workshopRef, bool bRemoveObject = false, bool bRecalculateResources = true)
	UpdateVendorFlags(workshopObject, workshopRef)
		
	if(workshopObject.HasKeyword(WorkshopRadioObject))
		UpdateRadioObject (workshopObject)
	elseif(bRecalculateResources)
		workshopRef.RecalculateWorkshopResources()
	endif
endFunction


function RecalculateResourceDamage(WorkshopScript workshopRef)
	RecalculateResourceDamageForResource(workshopRef, WorkshopRatings[WorkshopRatingFood].resourceValue)
	RecalculateResourceDamageForResource(workshopRef, WorkshopRatings[WorkshopRatingWater].resourceValue)
	RecalculateResourceDamageForResource(workshopRef, WorkshopRatings[WorkshopRatingSafety].resourceValue)
	RecalculateResourceDamageForResource(workshopRef, WorkshopRatings[WorkshopRatingPower].resourceValue)
	RecalculateResourceDamageForResource(workshopRef, WorkshopRatings[WorkshopRatingPopulation].resourceValue)
endFunction


function RecalculateResourceDamageForResource(WorkshopScript workshopRef, actorValue akResource)
	ActorValue damageRatingValue = GetDamageRatingValue(akResource)
	
	; if not a resource with a damage rating, don't need to do anything
	if(damageRatingValue)
		float totalDamage = workshopRef.GetWorkshopResourceDamage(akResource)
		; set new damage total
		SetResourceData(damageRatingValue, workshopRef, totalDamage)
	endif
endFunction

; call to update vendor flags on all stores (e.g. for when adding population)
function UpdateVendorFlagsAll(WorkshopScript workshopRef)
	; get stores
	ObjectReference[] stores = GetResourceObjects(workshopRef, WorkshopRatings[WorkshopRatingVendorIncome].resourceValue)			
	; update vendor data for all of them (might trigger top level vendor for increase in population)
	int i = 0
	while(i < stores.Length)
		WorkshopObjectScript theStore = stores[i] as WorkshopObjectScript
		
		if(theStore)
			UpdateVendorFlags(theStore, workshopRef)
		endif
		
		i += 1
	endWhile
endFunction

; helper function for UpdateWorkshopRatingsForResourceObject
; update vendor flags based on this object's production state
function UpdateVendorFlags(WorkshopObjectScript workshopObject, WorkshopScript workshopRef)
	; set this to true if we are going to change state
	bool bShouldVendorFlagBeSet = false
	if(workshopObject.VendorType > -1)
		WorkshopVendorType vendorType = WorkshopVendorTypes[workshopObject.VendorType]

		if(vendorType)
			; if a vendor object, increment global if necessary
			if(workshopObject.vendorLevel >= VendorTopLevel)
				; WSFW 2.0.0 - Removed redundant check that workshopObject.VendorType > -1
				
				; check for minimum connected population
				int linkedPopulation = GetLinkedPopulation(workshopRef, false) as int
				int totalPopulation = workshopRef.GetBaseValue(WorkshopRatings[WorkshopRatingPopulation].resourceValue) as int
				int vendorPopulation = linkedPopulation + totalPopulation

				; NOTE: known issue - we're not checking for population dropping below minimum to invalidate top vendor flag. Acceptable.				
				if(vendorType)
					if(vendorPopulation >= vendorType.minPopulationForTopVendor && workshopRef.OwnedByPlayer)
						bShouldVendorFlagBeSet = true
					endif
				endif
			endif
			
			if(bShouldVendorFlagBeSet)
				if( ! workshopObject.bVendorTopLevelValid)
					; change state:
					; increment top vendor global
					vendorType.topVendorFlag.Mod(1.0)
					workshopObject.bVendorTopLevelValid = true
				endif
			else
				if(workshopObject.bVendorTopLevelValid)
					; change state:
					; increment top vendor global
					vendorType.topVendorFlag.Mod(-1.0)
					workshopObject.bVendorTopLevelValid = false
				endif
			endif
		endif
	endif
endFunction


; assign spare beds to any NPCs that don't have one
function TryToAssignBeds(WorkshopScript workshopRef)
	; WSFW 2.0.0 - Switched to our array of nonWorkshopNPCScript actors
	while(WSFW_ActorsWithoutBeds.Length > 0 && UFO4P_UnassignedBeds.Length > 0)
		Actor theActor = WSFW_ActorsWithoutBeds[0]
		
		if(theActor && theActor.IsBoundGameObjectAvailable())
			WorkshopObjectScript bedToAssign = UFO4P_UnassignedBeds[0]
			UFO4P_UnassignedBeds.Remove(0)
			
			if(bedToAssign)
				; WSFW 2.0.0 - Switching to nonWorkshopNPCScript version
				bedToAssign.AssignNPC(theActor)
				SendWorkshopActorAssignedToWorkEvent(theActor, bedToAssign, workshopRef)
			endif
		endif
		
		WSFW_ActorsWithoutBeds.Remove(0)
	endWhile
endFunction

; assign a spare bed to the specified actor if he needs one
function TryToAssignBedToActor(WorkshopScript workshopRef, WorkshopNPCScript theActor)
	;UFO4P 2.0.4 Bug #24312: this function is obsolete now:
	;The only users were TryToAssignBeds and AddActorToWorkshop. TryToAssignBeds does not need to loop through the beds array to get the
	;assignment done and therefore doesn't need to call this function. AddActorToWorkshop now calls TryToAssignBeds instead.
endFunction

;UFO4P 2.0.4 Note: this function is obsolete now:
;The vanilla TryToAssignResourceType function was the only user; the new version of that function does not use iz anymore.
int function GetNextIndex(int currentIndex, int maxIndex)
	if(currentIndex < maxIndex)
		return currentIndex + 1
	else
		return 0
	endif
endFunction

; try to assign all objects of the specified resource types
function TryToAssignResourceType(WorkshopScript workshopRef, ActorValue resourceValue)
	String sLog = "aaaTryToAssignResourceType"
	Debug.OpenUserLog(sLog)
	; Debug.TraceUser(sLog, "TryToAssignResourceType called on " + workshopRef + " for AV " + resourceValue)
	if(resourceValue)		
		int resourceIndex = GetResourceIndex(resourceValue)

		; Debug.TraceUser(sLog, "resourceIndex = " + resourceIndex)
		; WSFW 2.0.0 - Switching to nonWorkshopNPCScript arrays
		Actor[] workers 
		if(resourceIndex == WorkshopRatingFood)
			workers = WSFW_FoodWorkers
		elseif(resourceIndex == WorkshopRatingSafety)
			workers = WSFW_SafetyWorkers
		else
			; Debug.TraceUser(sLog, "No workers found for resourceIndex " + resourceIndex)
			return
		endif
		
		ObjectReference[] ResourceObjects = UFO4P_GetObjectArray(resourceIndex)
		
		; Debug.TraceUser(sLog, "Found workers " + workers + ", and resource objects " + ResourceObjects)
		
		int countWorkers = workers.Length
		int countResourceObjects = ResourceObjects.Length
			
		if(countResourceObjects <= 0 || countWorkers <= 0)
			return
		endif

		float maxProduction = WorkshopRatings[resourceIndex].maxProductionPerNPC
		; WSFW - Introducing edits to max production
		if(resourceValue == WorkshopRatings[WorkshopRatingSafety].resourceValue)
			maxProduction = MaxDefenseWorkPerSettler
		elseif(resourceValue == WorkshopRatings[WorkshopRatingFood].resourceValue)
			maxProduction = MaxFoodWorkPerSettler
		endif
	
		; WSFW 2.0.0 - The two nested loops below were previously using conditioned index incrementing, which made the code more difficult to read and prone to errors if we added additional conditioning that didn't match up with the original design pattern. We've switched them to reverse loops which can safely remove indexes without breaking the iteration.
		
		int workerIndex = workers.Length -1
		
		while(workerIndex > -1)
			Actor theWorker = workers[workerIndex]
			; Debug.TraceUser(sLog, "Attempting to assign settler " + theWorker + " to items...")
			if(theWorker == none || theWorker.IsBoundGameObjectAvailable() == false)
				workers.Remove(workerIndex)
			else
				; WSFW 2.0.0 - Use our global functions which work for Actors and WorkshopNPCScript actors
				float resourceTotal = WorkshopFramework:WorkshopFunctions.GetMultiResourceProduction(theWorker)
				
				; Debug.TraceUser(sLog, "Attempting to assign settler " + theWorker + " to items, currently has production of " + resourceTotal)
				
				bool actorAssigned = false
				int objectIndex = ResourceObjects.Length - 1

				while(objectIndex > -1 && actorAssigned == false)
					ObjectReference theObjectRef = ResourceObjects[objectIndex]
					WorkshopObjectScript theObject = theObjectRef as WorkshopObjectScript
					Actor currentOwner = theObject.GetActorRefOwner()
					; Debug.TraceUser(sLog, "Checking if settler " + theWorker + " can be assigned to " + theObject)				
					if(theObject.HasKeyword(WSFW_DoNotAutoassignKeyword)) 
						; Debug.TraceUser(sLog, theObject + " is flagged to not be autoassigned via keyword - removing from array.")
						ResourceObjects.Remove(objectIndex)
					elseif(currentOwner != None && currentOwner != Game.GetPlayer())
						; Debug.TraceUser(sLog, theObject + " already assigned, removing from array.")
						; Object is already assigned to someone
						ResourceObjects.Remove(objectIndex)
					elseif(theObject.GetBaseValue(resourceValue) > theObject.GetValue(resourceValue))
						; Debug.TraceUser(sLog, theObject + " is damaged - removing from array.")
						; Damaged object, do not autoassign
						ResourceObjects.Remove(objectIndex)
					else
						float resourceRating = theObject.GetResourceRating(resourceValue)
						; Debug.TraceUser(sLog, theObject + " provides " + resourceRating + ", user is at " + resourceTotal + ", maxProduction = " + maxProduction)
						if(resourceTotal + resourceRating <= maxProduction)
							; WSFW 2.0.0 - Moving the call to ResourceObjects.Remove before the assign calls, that way TryToAssignResourceType can be called safely from with the assign functions. Currently the default function uses bResetMode = true to prevent that, but our chain of functions for nonWorkshopNPCScript functions doesn't have that flag (primarily because that flag is being used to do too many things and it makes the code unclear)
							
							; Debug.TraceUser(sLog, theObject + " is about to be assigned to " + theWorker + ", removing from array.")
							;object is being assigned -> remove 
							ResourceObjects.Remove(objectIndex)
							
							WorkshopNPCScript asWorkshopNPC = theWorker as WorkshopNPCScript
							if(asWorkshopNPC)
								; Debug.TraceUser(sLog, "Calling AssignActorToObjectV2 for " + theWorker + " to " + theObject)
								AssignActorToObjectV2(asWorkshopNPC, theObject, bResetMode = true, bAddActorCheck = false, bUpdateObjectArray = false)
							else
								; Debug.TraceUser(sLog, "Calling WorkshopFunctions.AssignActorToObject for non-WorkshopNPCScript " + theWorker + " to " + theObject)
								; WSFW 2.0.0 - Route regular actors to our centralized functions
								WorkshopFramework:WorkshopFunctions.AssignActorToObject(theObject, theWorker, abAutoHandleAssignmentRules = true, abAutoUpdateActorStatus = true, abRecalculateWorkshopResources = false)
							endif
							
							;update worker's production:							
							resourceTotal += resourceRating
							WorkshopFramework:WorkshopFunctions.SetMultiResourceProduction(theWorker, resourceTotal)
							
							if(resourceTotal >= maxProduction)
								; Debug.TraceUser(sLog, theWorker + " is fully assigned for resource with " + resourceTotal + ", maxProduction = " + maxProduction)
								actorAssigned = true
							endif
						endif
					endif
					
					objectIndex -= 1
				endWhile
			endif
			
			workerIndex -= 1
		endWhile
	endif
endFunction

; called by each workshop on the timer update loop
function DailyWorkshopUpdate(bool bInitialize = false)
	; produce for all workshops
	int workshopIndex = 0

	; calculate time interval between each workshop update
	if(bInitialize)
		dailyUpdateIncrement = 0.0 ; short increment on initialization - FOR NOW just keep it at 0 so it happens as fast as possible
	else
	 	dailyUpdateIncrement = dailyUpdateSpreadHours/Workshops.Length
	endif

	SendCustomEvent("WorkshopDailyUpdate")		
endFunction

; used by test terminal to automatically calculate and force an attack
function TestForceAttack()
	GetWorkshop(currentWorkshopID).CheckForAttack(true)
endFunction

; trigger story manager attack
function TriggerAttack(WorkshopScript workshopRef, int attackStrength)
	; Don't throw workshop attacks for vassal locations
	if(workshopRef.HasKeyword(WorkshopType02Vassal) == false)
		if( ! WorkshopEventAttack.SendStoryEventAndWait(akLoc = workshopRef.myLocation, aiValue1 = attackStrength, akRef1 = workshopRef))
			; Removed - now that we have an attack message, don't do fake attacks
		endif
	endif
endFunction


int function CalculateAttackStrength(int foodRating, int waterRating)
	; attack strength: based on "juiciness" of target
	int attackStrength = math.min(foodRating + waterRating, maxAttackStrength) as int
	int attackStrengthMin = attackStrength/2 * -1
	int attackStrengthMax = attackStrength/2
	
	attackStrength = math.min(attackStrength + utility.randomInt(attackStrengthMin, attackStrengthMax), maxAttackStrength) as int
	
	return attackStrength
endFunction

int function CalculateDefenseStrength(int safety, int totalPopulation)
	int defenseStrength = math.min(safety + totalPopulation, maxDefenseStrength) as int
	
	return defenseStrength
endFunction

; called to set lastAttack, lastAttack faction
function RecordAttack(WorkshopScript workshopRef, Faction attackingFaction)
	; only reset last attack days if we can find the attacking faction
	FollowersScript:EncDefinition encDef = Followers.GetEncDefinition(factionToCheck = attackingFaction)
	
	if(encDef)
		; set days since last attack to 0
		SetResourceData(WorkshopRatings[WorkshopRatingLastAttackDaysSince].resourceValue, workshopRef, 0)
		; set attacking faction ID
		SetResourceData(WorkshopRatings[WorkshopRatingLastAttackFaction].resourceValue, workshopRef, encDef.LocEncGlobal.GetValue())
	endif
endFunction


; called by attack quests if they need to be resolved "off stage"
; return value: TRUE = attackers won, FALSE = defenders won (to match CheckResolveAttackk on WorkshopAttackScript)
bool function ResolveAttack(WorkshopScript workshopRef, int attackStrength, Faction attackFaction)
	ObjectReference containerRef = workshopRef.GetContainer()
	if( ! containerRef)
		return false
	endif

	workshopRef.UFO4P_CurrentlyUnderAttack = false
	if(UFO4P_WorkshopRef_ResetDelayed && workshopRef == UFO4P_WorkshopRef_ResetDelayed)
		UFO4P_WorkshopRef_ResetDelayed = none
		UFO4P_AttackRunning = false
	endif

	bool attackersWin = false

	int totalPopulation = workshopRef.GetBaseValue(WorkshopRatings[WorkshopRatingPopulation].resourceValue) as int
	int safety = workshopRef.GetValue(WorkshopRatings[WorkshopRatingSafety].resourceValue) as int

	; record attack in location data
	RecordAttack(workshopRef, attackFaction)

	; defense strength: safety + totalPopulation 
	int defenseStrength = CalculateDefenseStrength(safety, totalPopulation)
	
	; "combat resolution" - each roll 1d100 + strength, if attack > defense that's the damage done.
	int attackRoll = utility.randomInt() + attackStrength
	
	; don't let attack roll exceed 150 - makes high defense more likely to win
	attackRoll = math.min(attackRoll, resolveAttackMaxAttackRoll) as int

	int defenseRoll = utility.randomInt() + defenseStrength
	
	if(attackRoll > defenseRoll)
		attackersWin = true

		; limit max damage based on defense - but max can't go below 25
		float maxAllowedDamage = math.max(resolveAttackAllowedDamageMin, 100-defenseStrength)
		float damage = math.min(attackRoll - defenseRoll, maxAllowedDamage)

		; get current damage - ignore if already more than this attack
		float currentDamage = workshopRef.GetValue(WorkshopRatings[WorkshopRatingDamageCurrent].resourceValue)
		
		if(currentDamage < damage)
			float totalDamagePoints = 0.0
			; now set damage to all the resources
			totalDamagePoints += SetRandomDamage(workshopRef, WorkshopRatings[WorkshopRatingFood].resourceValue, damage)	; use total rating for food, water, safety, power
			totalDamagePoints += SetRandomDamage(workshopRef, WorkshopRatings[WorkshopRatingWater].resourceValue, damage)
			totalDamagePoints += SetRandomDamage(workshopRef, WorkshopRatings[WorkshopRatingSafety].resourceValue, damage)
			totalDamagePoints += SetRandomDamage(workshopRef, WorkshopRatings[WorkshopRatingPower].resourceValue, damage)
			totalDamagePoints += SetRandomDamage(workshopRef, WorkshopRatings[WorkshopRatingPopulation].resourceValue, damage)
			
			; now calc total points to get "real" max damage
			float totalResourcePoints = GetTotalResourcePoints(workshopRef)
			float maxDamage = 0.0
			if totalResourcePoints > 0
				maxDamage = totalDamagePoints/totalResourcePoints * 100
			endif

			; max damage = starting "maximum" damage inflicted by the attack
			SetResourceData(WorkshopRatings[WorkshopRatingDamageMax].resourceValue, workshopRef, maxDamage)
			; current damage starts out at the max, then goes down as repairs are made during the daily update
			SetResourceData(WorkshopRatings[WorkshopRatingDamageCurrent].resourceValue, workshopRef, maxDamage)
		endif

		; in any case, remove resources from container based on current damage
		if(containerRef)
			int stolenFood = math.ceiling(containerRef.GetItemCount(WorkshopConsumeFood) * damage/100)
			int stolenWater = math.ceiling(containerRef.GetItemCount(WorkshopConsumeWater) * damage/100)
			int stolenScrap = math.ceiling(containerRef.GetItemCount(WorkshopConsumeScavenge) * damage/100)
			int stolenCaps = math.ceiling(containerRef.GetItemCount(Game.GetCaps()) * damage/100)
			
			containerRef.RemoveItem(WorkshopConsumeFood, stolenFood)
			containerRef.RemoveItem(WorkshopConsumeWater, stolenWater)
			containerRef.RemoveItemByComponent(WorkshopConsumeScavenge, stolenScrap)
			containerRef.RemoveItem(Game.GetCaps(), stolenCaps)
		endif
	endif

	return attackersWin
endFunction

; utility function - get current population damage
float function GetPopulationDamage(WorkshopScript workshopRef)
	; difference between base value and current value
	float populationDamage = workshopRef.GetBaseValue(WorkshopRatings[WorkshopRatingPopulation].resourceValue) - workshopRef.GetValue(WorkshopRatings[WorkshopRatingPopulation].resourceValue)
	; add in any extra damage (recorded but not yet processed into wounded actors)
	populationDamage += workshopRef.GetBaseValue(WorkshopRatings[WorkshopRatingDamagePopulation].resourceValue)

	return populationDamage
endFunction

; utility function - return total resource rating (potential), used for damage % calculation
float function GetTotalResourcePoints(WorkshopScript workshopRef)
	; total resource points = sum of all potential resource points + total population
	float totalPopulation = workshopRef.GetBaseValue(WorkshopRatings[WorkshopRatingPopulation].resourceValue) ; total population is base value
	
	float foodTotal = workshopRef.GetBaseValue(WorkshopRatings[WorkshopRatingFood].resourceValue)
	float waterTotal = workshopRef.GetBaseValue(WorkshopRatings[WorkshopRatingWater].resourceValue)
	float safetyTotal = workshopRef.GetBaseValue(WorkshopRatings[WorkshopRatingSafety].resourceValue)
	float powerTotal = workshopRef.GetBaseValue(WorkshopRatings[WorkshopRatingPower].resourceValue)
	
	return (totalPopulation + foodTotal + waterTotal + safetyTotal + powerTotal)
endFunction

; return total damage points
float function GetTotalDamagePoints(WorkshopScript workshopRef)
	; RESOURCE CHANGE: population damage is recorded in difference between base and current population value
	float populationDamage = GetPopulationDamage(workshopRef)
	float foodDamage = workshopRef.GetValue(WorkshopRatings[WorkshopRatingDamageFood].resourceValue)
	float waterDamage = workshopRef.GetValue(WorkshopRatings[WorkshopRatingDamageWater].resourceValue)
	float safetyDamage = workshopRef.GetValue(WorkshopRatings[WorkshopRatingDamageSafety].resourceValue)
	float powerDamage = workshopRef.GetValue(WorkshopRatings[WorkshopRatingDamagePower].resourceValue)

	return (populationDamage + foodDamage + waterDamage + safetyDamage + powerDamage)
endFunction


function ProduceFood(WorkshopScript workshopref, int totalFoodToProduce)
	; WSFW - This is handled by our WorkshopProductionManager script now
	return
endFunction


float function SetRandomDamage(WorkshopScript workshopRef, ActorValue resourceValue, float baseDamage)
	float rating = workshopRef.GetBaseValue(resourceValue)

	; randomize baseDamage a bit
	float realDamageMult = (baseDamage + utility.RandomFloat(baseDamage/2.0 * -1, baseDamage/2.0))/100
	realDamageMult = math.min(realDamageMult, 1.0)
	realDamageMult = math.max(realDamageMult, 0.0)
	
	int damage = math.Ceiling(rating * realDamageMult)
	; figure out damage rating:
	actorValue damageRatingValue = GetDamageRatingValue(resourceValue)
	
	if(damageRatingValue)
		SetResourceData(damageRatingValue, workshopRef, damage)
		
		; adjust resource value down for this damage - except for population (since we display the base value in the interface)
		if(resourceValue != WorkshopRatings[WorkshopRatingPopulation].resourceValue)
			ModifyResourceData(resourceValue, workshopRef, damage*-1)
		endif
		
		return damage
	else
		return 0
	endif
endFunction

; return population from linked workshops
;  if bIncludeProductivityMult = true, return the population * productivityMult for each linked workshop
float function GetLinkedPopulation(WorkshopScript workshopRef, bool bIncludeProductivityMult = false)
	int workshopID = workshopRef.GetWorkshopID()
	float totalLinkedPopulation = 0

	; get all linked workshop locations
	Location[] linkedLocations = workshopRef.myLocation.GetAllLinkedLocations(WorkshopCaravanKeyword)
	int index = 0
	while(index < linkedLocations.Length)
		; get linked workshop from location
		int linkedWorkshopID = WorkshopLocations.Find(linkedLocations[index])
		
		if(linkedWorkshopID >= 0)
			; get the linked workshop
			WorkshopScript linkedWorkshop = GetWorkshop(linkedWorkshopID)
			
			float population = Math.max(linkedWorkshop.GetBaseValue(WorkshopRatings[WorkshopRatingPopulation].resourceValue) - GetPopulationDamage(workshopRef), 0.0)
			
			if(bIncludeProductivityMult)
				float productivity = linkedWorkshop.GetProductivityMultiplier(WorkshopRatings)
				
				population = population * productivity
			endif
			
			; add linked population to total
			totalLinkedPopulation += population
		endif
		
		index += 1
	endwhile

	return totalLinkedPopulation
endFunction


function TransferResourcesFromLinkedWorkshops(WorkshopScript workshopRef, int neededFood, int neededWater)
	; WSFW - We're handling this in WorkshopResourceManager now
	return
endFunction

; called by ResetWorkshop
; also called when activating workshop
function SetCurrentWorkshop(WorkshopScript workshopRef)
	CurrentWorkshop.ForceRefTo(workshopRef)
	currentWorkshopID = workshopRef.GetWorkshopID()
	WorkshopCurrentWorkshopID.SetValue(currentWorkshopID)
endFunction


; clear and recalculate workshop ratings
function ResetWorkshop(WorkshopScript workshopRef)
	int workshopID = workshopRef.GetWorkshopID()

	if(workshopID != currentWorkshopID)
		return
	endif
	
	GetEditLock()
	
	;UFO4P 2.0.6 Bug #25230: added this line:
	UFO4P_ResetRunning = true

	UFO4P_WorkshopRef_ResetDelayed = none
	UFO4P_AttackRunning = false
	UFO4P_ClearBedArrays = false

	WorkshopNewSettler.Clear()
	WorkshopSpokesmanAfterRaiderAttack.Clear()

	CurrentNewSettlerCount = 0

	ObjectReference[] WorkshopActors = GetWorkshopActors(workshopRef)
	ObjectReference[] ResourceObjectsDamaged = GetResourceObjects(workshopRef, NONE, 1)
	ObjectReference[] ResourceObjectsUndamaged = GetResourceObjects(workshopRef, NONE, 2)

	if(workshopRef.EnableAutomaticPlayerOwnership && ! workshopRef.OwnedByPlayer)
		int bossIndex = 0
		int bossCount = 0
		
		while(bossIndex < BossLocRefTypeList.GetSize())
			LocationRefType bossRefType = BossLocRefTypeList.GetAt(bossIndex) as LocationRefType
			bossCount += WorkshopLocations[workshopID].GetRefTypeAliveCount(bossRefType)
			
			bossIndex += 1
		endWhile

		if(bossCount == 0)
			WorkshopLocations[workshopID].SetCleared(true)
		endif
	endif

	bool bFirstResetAfterLostControl = false
	if( ! workshopRef.OwnedByPlayer && workshopRef.GetValue(WorkshopPlayerLostControl) == 1)
		workshopRef.SetValue(WorkshopPlayerLostControl, 2)
		bFirstResetAfterLostControl = true
	endif

	float currentDamage = workshopRef.GetValue(WorkshopRatings[WorkshopRatingDamageCurrent].resourceValue) / 100
	
	float[] resourceToDamage = new float [6]
	resourceToDamage[WorkshopRatingFood] = math.Ceiling (workshopRef.GetValue (WorkshopRatings[WorkshopRatingDamageFood].resourceValue))
	resourceToDamage[WorkshopRatingSafety] = math.Ceiling (workshopRef.GetValue (WorkshopRatings[WorkshopRatingDamageSafety].resourceValue))
	resourceToDamage[WorkshopRatingWater] = math.Ceiling (workshopRef.GetValue (WorkshopRatings[WorkshopRatingDamageWater].resourceValue))
	resourceToDamage[WorkshopRatingPower] = math.Ceiling (workshopRef.GetValue (WorkshopRatings[WorkshopRatingDamagePower].resourceValue))
	
	int populationToDamage = math.Ceiling (workshopRef.GetValue (WorkshopRatings[WorkshopRatingDamagePopulation].resourceValue)) as int

	;If false, we can skip the second loop through the actor array.
	;Getting this here because the damage value will be counted down, so we can't check it later on.
	bool UFO4P_ApplyPopulationDamage = (populationToDamage > 0)

	workshopRef.RecalculateWorkshopResources(false)
	WorkshopCenterMarker.ForceRefTo(workshopRef.GetLinkedRef(WorkshopLinkCenter))

	;ADD THE ACTORS:
	int maxIndex = WorkshopActors.length
	
	int i = 0
	while(i < maxIndex)
		Actor actorRef = WorkshopActors[i] as Actor
		
		if(actorRef)
			int iActorWorkshopID = WorkshopFramework:WorkshopFunctions.GetWorkshopID(actorRef)
			if(iActorWorkshopID == workshopID || iActorWorkshopID < 0)
				if(actorRef.IsDead())
					WorkshopActors.Remove(i)
					maxIndex -= 1
					
					;Also need to update the loop index variable: with an actor removed, we need to check the same position again:
					i -= 1
				else
					if(bFirstResetAfterLostControl)
						actorRef.RemoveFromFaction(FarmDiscountFaction)
					endif

					WorkshopFramework:WorkshopFunctions.UpdatePlayerOwnership(actorRef, workshopRef)
					
					if(actorRef as WorkshopNPCScript)
						(actorRef as WorkshopNPCScript).StartAssignmentTimer(false)
					else
						actorRef.SetValue(WorkshopActorAssigned, 0)
					endif

					if(workshopRef.DaysSinceLastVisit > 3)
						actorRef.RemoveFromFaction(MinRadiantDialogueThankful)
						actorRef.RemoveFromFaction(MinRadiantDialogueDisappointed)
						actorRef.RemoveFromFaction(MinRadiantDialogueFailure)
					endif
					
					if(actorRef.GetBaseValue(WorkshopRatings[WorkshopRatingPopulationRobots].resourceValue) == 0)
						; WSWF - Likely the UFO4P patch would have added this change as well, but hasn't done so yet
						WSFW_AddToActorsWithoutBedsArray(actorRef)
					endif

					if(CaravanActorAliases.Find(actorRef) < 0)
						if(actorRef as WorkshopNPCScript)
							AddActorToWorkshop(actorRef as WorkshopNPCScript, workshopRef, true, WorkshopActors)
						else
							WorkshopFramework:WorkshopFunctions.AddActorToWorkshop(actorRef, workshopRef, abResetMode = true)
						endif
						
						if(WorkshopFramework:WorkshopFunctions.IsWounded(actorRef))
							if(populationToDamage > 0)
								populationToDamage -= 1
							else
								WorkshopFramework:WorkshopFunctions.SetWounded(actorRef, false)
							endif
							
							;If no damage had to be applied to the population, there will be no second pass, so we don't need to set this flag
							if(UFO4P_ApplyPopulationDamage)
								WorkshopFramework:WorkshopFunctions.SetResetDone(actorRef, true)
							endif
						endif
					endif

					;Moved this block in here from an extra loop at the end of the vanilla ResetWorkshop function:
					if(WorkshopFramework:WorkshopFunctions.IsNewSettler(actorRef) == true && WorkshopFramework:WorkshopFunctions.IsWorker(actorRef) == false)
						if(CurrentNewSettlerCount == 0)
							WorkshopNewSettler.ForceRefTo(actorRef)
						else
							WorkshopFramework:WorkshopFunctions.SetNewSettler(actorRef, false)
							actorRef.EvaluatePackage()
						endif
						
						CurrentNewSettlerCount += 1
					endif
				endif
			endif
		else
			WorkshopActors.Remove(i)
			maxIndex -= 1
			i -= 1
		endif

		i += 1

	endWhile

	;No need to run this if no damage had to be applied to the population
	if(UFO4P_ApplyPopulationDamage && workshopID == currentWorkshopID)
		i = 0
		while(i < maxIndex)
			Actor actorRef = WorkshopActors[i] as Actor
			
			if(actorRef)
				if(PopulationToDamage > 0 && WorkshopFramework:WorkshopFunctions.IsResetDone(actorRef) == false && CaravanActorAliases.Find(actorRef) < 0)
					WorkshopFramework:WorkshopFunctions.SetWounded(actorRef, true)
					populationToDamage -= 1
				endif

				WorkshopFramework:WorkshopFunctions.SetResetDone(actorRef, false)
			endif
			i += 1
		endWhile
	endif

	if(workshopID != currentWorkshopID)
		UFO4P_StopWorkshopReset()
		EditLock = false
		return
	endif

	SetResourceData(WorkshopRatings[WorkshopRatingDamagePopulation].resourceValue, workshopRef, 0)

	;Now run this function to make sure that the WSFW_ActorsWithoutBeds array is up to date before we start adding the work objects.
	WSFW_UpdateActorsWithoutBedsArray(workshopRef)

	;Get this once from the workshop, for faster access:
	bool bCleanupDamageHelpers_WorkObjects = workshopRef.UFO4P_CleanupDamageHelpers_WorkObjects

	;ADD THE WORK OBJECTS:
	maxIndex = ResourceObjectsDamaged.length
	
	i = 0
	while(i < maxIndex && workshopID == currentWorkshopID)
		WorkshopObjectScript resourceRef = ResourceObjectsDamaged[i] as WorkshopObjectScript
		if(resourceRef)
			;pre-placed objects:
			if(resourceRef.workshopID == -1)
				resourceRef.workshopID = workshopID
				resourceRef.HandleCreation (false)
			endif

			int resourceID = resourceRef.GetResourceID()
			
			if(resourceID >= 0)
				resourceToDamage[resourceID] = UpdateResourceDamage(resourceRef, WorkshopRatings[resourceID].resourceValue, resourceToDamage[resourceID])
			elseif(resourceRef.HasKeyword (WorkshopWorkObject) == false || resourceRef.IsBed())
				resourceRef.Repair()
				
				;also remove visible signs of destruction, if any:
				resourceRef.ClearDestruction()
			endif
			
			AssignObjectToWorkshop(resourceRef, workshopRef, true)
			resourceRef.HandleWorkshopReset()

			if(bCleanupDamageHelpers_WorkObjects && resourceRef.GetBaseObject() as Flora)
				resourceRef.UFO4P_ValidateDamageHelperRef()
			endif
		endif
		i += 1
	endWhile

	if(workshopID != currentWorkshopID)
		UFO4P_StopWorkshopReset()
		EditLock = false
		return
	endif

	i = 0
	bool UFO4P_ApplyDamageToResourceObjects = false
	while(i < 6 && UFO4P_ApplyDamageToResourceObjects == false)
		if(resourceToDamage[i] > 0)
			UFO4P_ApplyDamageToResourceObjects = true
		endif
		
		i += 1
	endWhile
	
	; now we do another pass, looking at the rest of the objects in the list
	maxIndex = ResourceObjectsUndamaged.Length
	
	i = 0
	while(i < maxIndex && workshopID == currentWorkshopID)
		WorkshopObjectScript resourceRef = ResourceObjectsUndamaged[i] as WorkshopObjectScript
		if(resourceRef)
			;pre-placed objects
			if(resourceRef.workshopID == -1)
				resourceRef.workshopID = workshopID
				resourceRef.HandleCreation(false)
			endif

			;No need to run this if there's no damage to apply:
			if(UFO4P_ApplyDamageToResourceObjects)
				int resourceID = resourceRef.GetResourceID()
				
				if(resourceID >= 0)
					resourceToDamage[resourceID] = ApplyResourceDamage(resourceRef, WorkshopRatings[resourceID].resourceValue, resourceToDamage[resourceID])
				endif
			endif

			AssignObjectToWorkshop(resourceRef, workshopRef, true)
			resourceRef.HandleWorkshopReset()

			if(bCleanupDamageHelpers_WorkObjects && resourceRef.GetBaseObject() as Flora)
				resourceRef.UFO4P_ValidateDamageHelperRef()
			endif
		endif
		
		i += 1
	endWhile

	;UFO4P 2.0.5 Bug #25129 added this line:
	UFO4P_UpdateUnassignedActorsArray(workshopRef)
		
	if(workshopID != currentWorkshopID)
		UFO4P_StopWorkshopReset()
		EditLock = false
		return
	endif

	;Doing this once now after each loop through an object array: UpdateWorkshopRatingsForResourceObject() will skip this now if called from a function
	;that runs in reset mode, so we don't have to superfluously call it several times in a row.
	workshopRef.RecalculateWorkshopResources(false)
	
	
	;WorkshopRatingDamageFood = 13
	;WorkshopRatingDamageWater = 14
	;WorkshopRatingDamageSafety = 15
	;WorkshopRatingDamagePower = 16
	;Thus, run this from a loop:
	i = 13
	while(i < 17)
		SetResourceData(WorkshopRatings[i].resourceValue, workshopRef, 0)
		i += 1
	endWhile

	if(workshopID != currentWorkshopID)
		UFO4P_StopWorkshopReset()
		EditLock = false
		return
	endif

	UFO4P_InitObjectArrays(workshopRef)
	
	Bool bOwnedByPlayer = workshopRef.OwnedByPlayer
	if(AutoAssignFood || ! bOwnedByPlayer)
		TryToAssignResourceType(workshopRef, WorkshopRatings[WorkshopRatingFood].resourceValue)
	endif
	
	if(AutoAssignDefense || ! bOwnedByPlayer)
		TryToAssignResourceType(workshopRef, WorkshopRatings[WorkshopRatingSafety].resourceValue)
	endif
	
	;Put this at the end since this is now still safe to do if the workshop has unloaded (because we have all the data we need
	;to run this stored in arrays):
	if(AutoAssignBeds || ! bOwnedByPlayer)
		TryToAssignBeds(workshopRef)
	endif
	
	SetUnassignedPopulationRating_Private(workshopRef, workshopActors)

	;Check whether workshop is still loaded, and if not, clear the bed arrays. Otherwise set UFO4P_ClearBedArrays to 'true'
	;for UFO4P_ResetCurrentWorkshop to clear them if it resets the current workshop:
	if(workshopID == currentWorkshopID)
		UFO4P_ClearBedArrays = true
	else
		UFO4P_UnassignedBeds = none
		UFO4P_ActorsWithoutBeds = none
		WSFW_ActorsWithoutBeds = None
	endif

	workshopRef.PlayerHasVisited = true

	if(bCleanupDamageHelpers_WorkObjects)
		workshopRef.UFO4P_CleanupDamageHelpers_WorkObjects = false
	endIf

	EditLock = false
	UFO4P_ResetRunning = false
endFunction

; WSFW 2.0.1
function SendWorkshopActorAssignedToWorkEvent(Actor assignedActor, WorkshopObjectScript assignedObject, WorkshopScript workshopRef)
	Var[] kargs = new Var[0]
	kargs.Add(assignedObject)
	kargs.Add(workshopRef)
	kargs.Add(assignedActor)
	
	SendCustomEvent("WorkshopActorAssignedToWork", kargs)		
endFunction

; WSFW 2.0.1
function SendWorkshopActorCaravanAssignEvent(Actor assignedActor, WorkshopScript workshopStart, WorkshopScript workshopDestination)
	Var[] kargs = new Var[0]
	kargs.Add(assignedActor)
	kargs.Add(workshopStart)
	kArgs.Add(workshopDestination) ; Added by WSFW
	
	SendCustomEvent("WorkshopActorCaravanAssign", kargs)
endFunction

; WSFW 2.0.1
Function SendWorkshopActorUnassignedEvent(WorkshopObjectScript akWorkshopObjectRef, WorkshopScript akWorkshopRef, Actor akActorRef)
	Var[] kargs = new Var[0]
	kargs.Add(akWorkshopObjectRef)
	kargs.Add(akWorkshopRef)
	kargs.Add(akActorRef)
	
	SendCustomEvent("WorkshopActorUnassigned", kargs)
EndFunction


; WSFW 2.0.1
Function SendWorkshopActorCaravanUnassignEvent(Actor akActorRef, WorkshopScript akWorkshopOrigin)
	Var[] kargs = new Var[0]
	kargs.Add(akActorRef)
	kargs.Add(akWorkshopOrigin)
	
	SendCustomEvent("WorkshopActorCaravanUnassign", kargs)
EndFunction

; utility function to send custom destruction state change event (because it has to be sent from the defining script)
function SendDestructionStateChangedEvent(WorkshopObjectScript workObject, WorkshopScript workshopRef)
	; send custom event for this object
	Var[] kargs = new Var[2]
	kargs[0] = workObject
	kargs[1] = workshopRef
	SendCustomEvent("WorkshopObjectDestructionStageChanged", kargs)		
endFunction

; utility function to send custom ownership state change event (because it has to be sent from the defining script)
function SendPlayerOwnershipChangedEvent(WorkshopScript workshopRef)
	; send custom event for this object
	Var[] kargs = new Var[2]
	kargs[0] = workshopRef.OwnedByPlayer
	kargs[1] = workshopRef
	SendCustomEvent("WorkshopPlayerOwnershipChanged", kargs)		
endFunction

; utility function to send custom destruction state change event (because it has to be sent from the defining script)
function SendPowerStateChangedEvent(WorkshopObjectScript workObject, WorkshopScript workshopRef)
	; send custom event for this object
	Var[] kargs = new Var[2]
	kargs[0] = workObject
	kargs[1] = workshopRef
	SendCustomEvent("WorkshopObjectPowerStageChanged", kargs)		
endFunction

; WSFW 1.1.4 - Allow WorkshopNPCScript to send out an event that an NPC was transferred between settlements
Function SendWorkshopNPCTransferEvent(Actor akActorRef, WorkshopScript akNewWorkshopRef, Keyword akActionKeyword)
	Var[] kArgs = new Var[3]
	kArgs[0] = akActorRef
	kArgs[1] = akNewWorkshopRef
	kArgs[2] = akActionKeyword
	
	SendCustomEvent("WSFW_WorkshopNPCTransfer", kArgs)
EndFunction

; helper function for ResetWorkshop
; pass in resourceRef, keyword, current damage
; return new damage (after applying damage to this resource)
float function ApplyResourceDamage(WorkshopObjectScript resourceRef, ActorValue resourceValue, float currentDamage)
	if(currentDamage > 0)
		float damageAmount = math.min(resourceRef.GetResourceRating(resourceValue), currentDamage)
		if(damageAmount > 0)			
			if(resourceRef.ModifyResourceDamage(resourceValue, damageAmount))
				currentDamage = currentDamage - damageAmount
			endif
		endif
	endif
	
	return currentDamage
endFunction

; helper function for ResetWorkshop
; pass in resourceRef, keyword, current damage
; if resourceRef already damaged, either reduce current damage by that amount or repair excess
; return new damage
float function UpdateResourceDamage(WorkshopObjectScript resourceRef, ActorValue resourceValue, float currentDamage)
	float damageAmount = resourceRef.GetResourceDamage(resourceValue)
	if(damageAmount > 0)
		currentDamage = currentDamage - damageAmount
		
		if(currentDamage < 0)
			; excess damage - repair this object the excess amount
			resourceRef.ModifyResourceDamage(resourceValue, currentDamage)
			currentDamage = 0
		endif
	endif
	
	return currentDamage
endFunction


function ClearWorkshopRatings(WorkshopScript workshopRef)
	int i = 0
	while(i < WorkshopRatings.Length)
		if(WorkshopRatings[i].clearOnReset)
			SetResourceData(WorkshopRatings[i].resourceValue, workshopRef, 0.0)
		endif
		
		i += 1
	endWhile
endFunction

; test function to print current workshop ratings to the log
function OutputWorkshopRatings(WorkshopScript workshopRef)
	if(workshopRef == NONE)
		workshopRef = GetWorkshopFromLocation(Game.GetPlayer().GetCurrentLocation())
	endif
	
	wsTrace("------------------------------------------------------------------------------ ", bNormalTraceAlso = true)
	wsTrace(" OutputWorkshopRatings " + workshopRef, bNormalTraceAlso = true)
	int i = 0
	while(i < WorkshopRatings.Length)
		wsTrace("   " + WorkshopRatings[i].resourceValue + ": " + workshopRef.GetValue(WorkshopRatings[i].resourceValue) + " (" + workshopRef.GetBaseValue(WorkshopRatings[i].resourceValue) + ")", bNormalTraceAlso = true)
		i += 1
	endWhile
	wsTrace("------------------------------------------------------------------------------ ", bNormalTraceAlso = true)
endFunction


; *****************************************************************************************************
; HELPER FUNCTIONS
; *****************************************************************************************************

; returns the workshopID for the supplied workshop ref
WorkshopScript function GetWorkshop(int workshopID)
	;workshop NPC or object):
	if(workshopID < 0 || workshopID >= workshops.length)
		return none
	endif
	
	return Workshops[workshopID]
endFunction


int function GetWorkshopID(WorkshopScript workshopRef)
	int workshopIndex = Workshops.Find(workshopRef)
	
	return workshopIndex
endfunction


function ModifyResourceData(ActorValue pValue, WorkshopScript pWorkshopRef, float modValue)
	if(pWorkshopRef == NONE || pValue == NONE)
		return
	endif
	
	float currentValue = pWorkshopRef.GetValue(pValue)
	
	; don't mod value below 0
	float newValue = modValue + currentValue
	if(newValue < 0)
		newValue = 0
	endif
	
	; NOTE: we don't want to actually call ModValue since ModValue changes the actor value "modifier" pool and SetValue changes the base value
	;  so instead we always use SetValue
	SetResourceData(pValue, pWorkshopRef, newValue)
endFunction



function SetResourceData(ActorValue pValue, WorkshopScript pWorkshopRef, float newValue)
	if(pValue == NONE)
		return
	endif
	
	float oldBaseValue = pWorkshopRef.GetBaseValue(pValue)
	float oldValue = pWorkshopRef.GetValue(pValue)
	
	; restore any damage first, then set
	if(oldValue < oldBaseValue)
		pWorkshopRef.RestoreValue(pValue, oldBaseValue-oldValue)
	endif
	
	; now set the value
	pWorkshopRef.SetValue(pValue, newValue)
endFunction


; update current damage rating for this workshop
function UpdateCurrentDamage(WorkshopScript workshopRef)
	float totalResourcePoints = GetTotalResourcePoints(workshopRef)
	float totalDamagePoints = GetTotalDamagePoints(workshopRef)
	float currentDamage = totalDamagePoints/totalResourcePoints * 100
	
	SetResourceData(WorkshopRatings[WorkshopRatingDamageCurrent].resourceValue, workshopRef, currentDamage)
	
	; update max damage if current damage is bigger
	float maxDamage = workshopRef.GetValue(WorkshopRatings[WorkshopRatingDamageMax].resourceValue)
	
	if(currentDamage > maxDamage)
		SetResourceData(WorkshopRatings[WorkshopRatingDamageMax].resourceValue, workshopRef, currentDamage)
	endif		
endFunction


int function GetResourceIndex(ActorValue pValue)
	return WorkshopRatingValues.Find(pValue)
endFunction


ActorValue function GetRatingAV(int ratingIndex)
	if ratingIndex >= 0 && ratingIndex < WorkshopRatings.Length
		return WorkshopRatings[ratingIndex].resourceValue
	else
		return NONE
	endif
endFunction

; specialized helper function - pass in rating index to WorkshopRatingValues (food, water, etc.), get back index to corresponding damage rating 
; returns -1 if not a valid rating index
ActorValue function GetDamageRatingValue(ActorValue resourceValue)
	int damageIndex = -1
	int ratingIndex = WorkshopRatingValues.Find(resourceValue)
	if ratingIndex == WorkshopRatingFood
		damageIndex = WorkshopRatingDamageFood
	elseif ratingIndex == WorkshopRatingWater
		damageIndex = WorkshopRatingDamageWater
	elseif ratingIndex == WorkshopRatingSafety
		damageIndex = WorkshopRatingDamageSafety
	elseif ratingIndex == WorkshopRatingPower
		damageIndex = WorkshopRatingDamagePower
	elseif ratingIndex == WorkshopRatingPopulation
		damageIndex = WorkshopRatingDamagePopulation
	endif
	if damageIndex > -1
		return WorkshopRatings[damageIndex].resourceValue
	else
		return NONE
	endif
endFunction


ObjectReference[] Function GetWorkshopActors(WorkshopScript workshopRef)
	return workshopRef.GetWorkshopResourceObjects(WorkshopRatings[WorkshopRatingPopulation].resourceValue)
endFunction

; aiDamageOption:
;	0 = return all objects
;	1 = return only damaged objects (at least 1 damaged resource value)
;	2 = return only undamaged objects (NO damaged resource values)
ObjectReference[] Function GetResourceObjects(WorkshopScript workshopRef, ActorValue resourceValue = NONE, int aiDamageOption = 0)
	return workshopRef.GetWorkshopResourceObjects(resourceValue, aiDamageOption)
endFunction


ObjectReference[] Function GetBeds(WorkshopScript workshopRef)
	return workshopRef.GetWorkshopResourceObjects(WorkshopRatings[WorkshopRatingBeds].resourceValue)
endFunction

; return true if actor owns a bed on this workshop
bool Function ActorOwnsBed(WorkshopScript workshopRef, WorkshopNPCScript actorRef)
	; WSFW 2.0.0 - Pointing to our arrays that allow regular actors
	if(workshopRef.GetWorkshopID() == currentWorkshopID)
		return (WSFW_ActorsWithoutBeds == none) || (WSFW_ActorsWithoutBeds.Find(actorRef) < 0)
	endif
	
	return false
endFunction


; utility function for all Workshop traces
function wsTrace(string traceString, int severity = 0, bool bNormalTraceAlso = false) DebugOnly
	;UFO4P: Added line to re-open the log:
	debug.OpenUserLog(UserLogName)
	; Debug.TraceUser(userlogName, " " + traceString, severity)
endFunction

; utility function to wait for edit lock
; increase wait time while more threads are in here
int editLockCount = 1
function GetEditLock()
	editLockCount += 1
	
	if(editLockCount > 4 && UFO4P_ThreadMonitorStarted == false)
		StartTimer (1.0, UFO4P_ThreadMonitorTimerID)
	endif
	
	while(EditLock)
		utility.wait(0.1 * editLockCount)
	endWhile
	
	EditLock = true
	
	editLockCount -= 1
endFunction


bool function IsEditLocked()
	return EditLock
endFunction


Group WorkshopRadioData
	Scene Property WorkshopRadioScene01 Auto Const
	ObjectReference Property WorkshopRadioRef Auto Const
	Keyword Property WorkshopRadioObject Auto Const
endGroup



function RegisterForWorkshopEvents(Quest questToRegister, bool bRegister = true)
	; register for build events from workshop
	if(bRegister)
		questToRegister.RegisterForCustomEvent(self, "WorkshopObjectBuilt")
		questToRegister.RegisterForCustomEvent(self, "WorkshopObjectMoved")
		questToRegister.RegisterForCustomEvent(self, "WorkshopObjectDestroyed")
		questToRegister.RegisterForCustomEvent(self, "WorkshopActorAssignedToWork")
		questToRegister.RegisterForCustomEvent(self, "WorkshopActorUnassigned")
		questToRegister.RegisterForCustomEvent(self, "WorkshopObjectDestructionStageChanged")
		questToRegister.RegisterForCustomEvent(self, "WorkshopObjectPowerStageChanged")
		questToRegister.RegisterForCustomEvent(self, "WorkshopPlayerOwnershipChanged")
		questToRegister.RegisterForCustomEvent(self, "WorkshopEnterMenu")
		questToRegister.RegisterForCustomEvent(self, "WorkshopObjectRepaired")
	else
		questToRegister.UnregisterForCustomEvent(self, "WorkshopObjectBuilt")
		questToRegister.UnregisterForCustomEvent(self, "WorkshopObjectMoved")
		questToRegister.UnregisterForCustomEvent(self, "WorkshopObjectDestroyed")
		questToRegister.UnregisterForCustomEvent(self, "WorkshopActorAssignedToWork")
		questToRegister.UnregisterForCustomEvent(self, "WorkshopActorUnassigned")
		questToRegister.UnregisterForCustomEvent(self, "WorkshopObjectDestructionStageChanged")
		questToRegister.UnregisterForCustomEvent(self, "WorkshopObjectPowerStageChanged")
		questToRegister.UnregisterForCustomEvent(self, "WorkshopPlayerOwnershipChanged")
		questToRegister.UnregisterForCustomEvent(self, "WorkshopObjectRepaired")
		questToRegister.UnregisterForCustomEvent(self, "WorkshopEnterMenu")
	endif
endFunction


Struct WorkshopObjective
	int index	;{ objective number }
	int startStage	;{ stage which started the objective }
	int doneStage	;{ stage to set when objective complete }
	int ratingIndex	;{ WorkshopParent.WorkshopRatingKeyword index}
	Keyword requiredKeyword ; optional - a keyword to check on the new built object
	GlobalVariable currentCount	; global holding current count - if filled, use ModObjectiveGlobal when new object is created
	GlobalVariable maxCount	; global holding max we're looking for - needs to be filled if currentCount is filled
	GlobalVariable percentComplete ; global holding % complete (for objective display)
	int startingCount ; this is subtracted from currentCount and maxCount when displaying the percentage (if 0, will just use real totals)
	bool useBaseValue = false ; if true, check base value instead of current value (e.g. for beds)
	bool rollbackObjective = false ; if true, can uncomplete objectives if they are now below the target value
EndStruct

; call this if you don't care which workshop the event came from
function UpdateWorkshopObjectivesAny(Quest theQuest, WorkshopObjective[] workshopObjectives, Var[] akArgs)
	if(akArgs.Length > 0)
		WorkshopScript workshopRef = akArgs[1] as WorkshopScript
		
		UpdateWorkshopObjectivesSpecific (theQuest, workshopObjectives, workshopRef)
	endif
endFunction

;a daily update is running because plenty of messages from this and the subsequent function may get inserted at any time.
function UpdateWorkshopObjectives(Quest theQuest, WorkshopObjective[] workshopObjectives, WorkshopScript theWorkshop, Var[] akArgs)
	if(akArgs.Length > 0)
		WorkshopScript workshopRef = akArgs[1] as WorkshopScript

		if(workshopRef && workshopRef == theWorkshop)
			UpdateWorkshopObjectivesSpecific(theQuest, workshopObjectives, theWorkshop)
		endif
	endif
endFunction

;Since that function is on the same script, this function will only let one thread through at a time and thus eliminates threading issues. 
function UpdateWorkshopObjectivesSpecific(Quest theQuest, WorkshopObjective[] workshopObjectives, WorkshopScript theWorkshop)
	UpdateWorkshopObjectivesSpecific_Private(theQuest, workshopObjectives, theWorkshop)
endFunction

;Never call this function directly from an external script as it is not threading safe. Call UpdateWorkshopObjectivesSpecific instead which makes sure
;that only one thread will be let through to this function at a time.
function UpdateWorkshopObjectivesSpecific_Private(Quest theQuest, WorkshopObjective[] workshopObjectives, WorkshopScript theWorkshop)
	; wait for recalc to finish
	theWorkshop.WaitForWorkshopResourceRecalc()
	
	; check for objectives being completed
	int i = 0
	int countWorkshopObjectives = WorkshopObjectives.Length
	while(i < countWorkshopObjectives)
		WorkshopObjective theObjective = WorkshopObjectives[i]
		if(theQuest.GetStageDone(theObjective.startStage) && (!theQuest.GetStageDone(theObjective.doneStage) || theObjective.rollbackObjective))
			float currentRating = 0
			if(theObjective.useBaseValue)
				currentRating = theWorkshop.GetBaseValue(WorkshopRatings[theObjective.ratingIndex].resourceValue)
			else
				currentRating = theWorkshop.GetValue(WorkshopRatings[theObjective.ratingIndex].resourceValue)
			endif
			
			if(theObjective.currentCount)
				; update objective count if the current rating has increased by at least 1
				float objectiveCount = theObjective.currentCount.GetValue()
				int diff = Math.Floor(currentRating - objectiveCount)
				if(diff != 0)
					; get % complete - if there's a startingCount, reduce both current and max by that amount
					float percentComplete = ((currentRating  - theObjective.startingCount)/(theObjective.maxCount.GetValue() - theObjective.startingCount)) * 100
					percentComplete = math.min(percentComplete, 100)
					theObjective.percentComplete.SetValue(percentComplete)
					theQuest.UpdateCurrentInstanceGlobal(theObjective.percentComplete)
					
					if(theQuest.ModObjectiveGlobal(afModValue = diff, aModGlobal = theObjective.currentCount, aiObjectiveID = theObjective.index, afTargetValue = theObjective.maxCount.GetValue(), abAllowRollbackObjective = theObjective.rollbackObjective))
						theQuest.setStage(theObjective.doneStage)
					endif
				endif
			else
				; just check if rating is positive
				if(currentRating > 0)
					theQuest.setStage(theObjective.doneStage)
				endif
			endif
		endif
		i += 1
	endwhile
endFunction

; returns rating for specified workshop and ratingIndex
float function GetRating(WorkshopScript workshopRef, int ratingIndex)
	float rating = workshopRef.GetValue(WorkshopRatings[ratingIndex].resourceValue)
	return rating
endFunction

; call this to randomize ransom value
function RandomizeRansom(GlobalVariable randomGlobal)
	int randomRansom = utility.randomInt(WorkshopMinRansom.GetValueInt(), WorkshopMaxRansom.GetValueInt())
	
	; round to closest 50
	float randomRounded = randomRansom/50 + 0.5
	randomRansom = math.floor(randomRounded) * 50
	
	randomGlobal.SetValue(randomRansom)
endFunction

; returns true if the passed in reference is in a "friendly" location (meaning the buildable area of a friendly settlement)
; * population > 0
; * workshop settlement
; * 1.5 not type02 settlement
bool function IsFriendlyLocation(ObjectReference targetRef)
	Location locationToCheck = targetRef.GetCurrentLocation()
	
	if(locationToCheck == NONE)
		return false
	else
		WorkshopScript workshopRef = GetWorkshopFromLocation(locationToCheck)
		if(workshopRef && workshopRef.GetBaseValue(WorkshopRatings[WorkshopRatingPopulation].resourceValue) > 0 && targetRef.IsWithinBuildableArea(workshopRef) && (workshopRef.HasKeyword(WorkshopType02) == false || workshopRef.OwnedByPlayer))
			return true
		else
			return false
		endif
	endif
endFunction

; utility functions to change the happiness modifier
; special handling: these all check for change in player ownership
function ModifyHappinessModifierAllWorkshops(float modValue, bool bPlayerOwnedOnly = true)
	; go through all workshops
	int index = 0
	while(index < Workshops.Length)
		WorkshopScript workshopRef = Workshops[index]
		
		; only ones with population matter
		if workshopRef.GetBaseValue(WorkshopRatings[WorkshopRatingPopulation].resourceValue) > 0
			; player owned if specified
			if( ! bPlayerOwnedOnly || (bPlayerOwnedOnly && workshopRef.GetValue(WorkshopPlayerOwnership) > 0))
				ModifyHappinessModifier(workshopRef, modValue)
			endif
		endif
		
		index += 1
	endWhile
endFunction


function ModifyHappinessModifier(WorkshopScript workshopRef, float modValue)
	if(workshopRef)
		float currentValue = workshopRef.GetValue(WorkshopRatingValues[WorkshopRatingHappinessModifier])
		float targetHappiness = workshopRef.GetValue(WorkshopRatingValues[WorkshopRatingHappinessTarget])
		float newValue = currentValue + modValue
		
		; don't modify past max/min limits so this doesn't overwhelm the base happiness value
		newValue = Math.Min(newValue, happinessModifierMax)
		newValue = Math.Max(newValue, happinessModifierMin)

		SetResourceData(WorkshopRatingValues[WorkshopRatingHappinessModifier], workshopRef, newValue)

		; recalc mod value to get the actual delta
		modValue = newValue - currentValue
		; if delta would reduce target to <= 0, end player ownership if it exists (and population is > 0)
		int population = workshopRef.GetBaseValue(WorkshopRatings[WorkshopRatingPopulation].resourceValue) as int
		int robots = workshopRef.GetBaseValue(WorkshopRatings[WorkshopRatingPopulationRobots].resourceValue) as int
		
		if((targetHappiness + modValue) <= 0 && workshopRef.OwnedByPlayer && (population - robots) > 0 && workshopRef.AllowUnownedFromLowHappiness)
			workshopRef.SetOwnedByPlayer(false)
		endif
	endif
endFunction


function SetHappinessModifier(WorkshopScript workshopRef, float newValue)
	if(workshopRef)
		float currentValue = workshopRef.GetValue(WorkshopRatingValues[WorkshopRatingHappinessModifier])
		
		float modValue = newValue - currentValue
		ModifyHappinessModifier(workshopRef, modValue)
	endif
endFunction

; utility function to display a message with text replacement from an object reference name
function DisplayMessage(Message messageToDisplay, ObjectReference refToInsert = NONE, Location locationToInsert = NONE)
	; WSFW 1.0.8 - Sending messages through a centralized manager so we can queue them under certain circumstances
	if(refToInsert && locationToInsert)
		LocationAndAliasMessage NewMessage = new LocationAndAliasMessage
		
		NewMessage.lamLocationAlias = MessageLocationAlias
		NewMessage.lamLocation = locationToInsert
		NewMessage.lamAlias = MessageRefAlias
		NewMessage.lamObjectRef = refToInsert
		NewMessage.lamMessage = messageToDisplay
		
		WSFW_MessageManager.ShowLocationAndAliasMessage(NewMessage)
	elseif(refToInsert)
		AliasMessage NewMessage = new AliasMessage
		
		NewMessage.amAlias = MessageRefAlias
		NewMessage.amObjectRef = refToInsert
		NewMessage.amMessage = messageToDisplay
		
		WSFW_MessageManager.ShowAliasMessage(NewMessage)
	elseif(locationToInsert)
		LocationMessage NewMessage = new LocationMessage
		
		NewMessage.lmLocationAlias = MessageLocationAlias
		NewMessage.lmLocation = locationToInsert
		NewMessage.lmMessage = messageToDisplay
		
		WSFW_MessageManager.ShowLocationMessage(NewMessage)
	else
		WSFW_MessageManager.ShowMessage(messageToDisplay)
	endif
endFunction


function PlayerComment(WorkshopObjectScript targetObject)
	If(targetObject.workshopID < 0)
		Return
	EndIf
	
	; only if at owned workshop
	WorkshopScript workshopRef = GetWorkshop(targetObject.workshopID)
	if(workshopRef && workshopRef.OwnedByPlayer)
		if(WorkshopPlayerCommentScene.IsPlaying() == false)
			PlayerCommentTarget.ForceRefTo(targetObject)
			WorkshopPlayerCommentScene.Start()
		endif
	endif
endFunction

;added by jduvall
function ToggleOnAllWorkshops()
	int i = 0
	while(i < WorkshopsCollection.GetCount() - 1)
		(WorkshopsCollection.GetAt(i) as WorkshopScript).SetOwnedByPlayer(true)
		
		i += 1
	endwhile
	
	PlayerOwnsAWorkshop = true
endFunction


bool Function PermanentActorsAliveAndPresent(WorkshopScript workshopRef)
	int i = 0
	int iCount = PermanentActorAliases.GetCount()

	;If there are permanent actors...
	if(iCount > 0)
		int iClearedWorkshopID = workshopRef.GetWorkshopID()

		;Then loop through all the permanent actors and get their workshop ID...
		while(i < iCount)
			Actor act = (PermanentActorAliases.GetAt(i) as Actor)
			
			int iActorWorkshopID = (act as WorkshopNPCScript).GetWorkshopID()

			;If the selected Permanent Actor is assigned to a workshop location and isn't dead...
			if(iActorWorkshopID > -1 && ! act.IsDead())
				if(iActorWorkshopID == iClearedWorkshopID)
					return true
				endif

			endif

			i += 1
		endwhile
	endif

	return false
EndFunction


;helper function to check whether the passed in actor owns anything else than a bed
bool function IsObjectOwner(WorkshopScript workshopRef, WorkshopNPCScript theActor)
	int minObjectCount = 1
	if(ActorOwnsBed(workshopRef, theActor))
		minObjectCount += 1
	endif
	
	ObjectReference[] ResourceObjects = workshopRef.GetWorkshopOwnedObjects (theActor)
	if(ResourceObjects.Length >= minObjectCount)
		return true
	endif
	
	return false
endFunction

;This will be called by WorkshopAttackScript when the attack quest starts running (usually when the attack message pops up on the screen):
function UFO4P_StartAttack (WorkshopScript workshopRef)
	if(workshopRef.GetWorkshopID() != currentWorkshopID)
		workshopRef.UFO4P_CurrentlyUnderAttack = true
	endIf
endFunction

function UFO4P_ResolveAttack (WorkshopScript workshopRef)
	if(workshopRef.UFO4P_CurrentlyUnderAttack)
		;Clear the attack bool on workshopRef:
		workshopRef.UFO4P_CurrentlyUnderAttack = false
		
		if(UFO4P_WorkshopRef_ResetDelayed && workshopRef == UFO4P_WorkshopRef_ResetDelayed)
			;Start reset via timer to prevent delays on WorkshopAttackScript:
			StartTimer(0.1, UFO4P_DelayedResetTimerID)
		endIf
	endIf
endFunction


event OnTimer(int aiTimerID)
	if(aiTimerID == UFO4P_DelayedResetTimerID)
		if(UFO4P_IsWorkshopLoaded(UFO4P_WorkshopRef_ResetDelayed))
			UFO4P_GameTimeOfLastResetStarted = Utility.GetCurrentGameTime()
			ResetWorkshop(UFO4P_WorkshopRef_ResetDelayed)
		else
			UFO4P_WorkshopRef_ResetDelayed = none
			UFO4P_AttackRunning = false
		endIf
	elseif(aiTimerID == UFO4P_ForcedResetTimerID)
		if(currentWorkshopID >= 0 && UFO4P_AttackRunning == false)
			workshopScript workshopRef = Workshops[currentWorkshopID]
			UFO4P_PreviousWorkshopLocation = workshopRef.myLocation
			UFO4P_GameTimeOfLastResetStarted = Utility.GetCurrentGameTime()
			UFO4P_InitCurrentWorkshopArrays()
			ResetWorkshop(workshopRef)
		endif
	elseif(aiTimerID == UFO4P_ThreadMonitorTimerID)
		UFO4P_ThreadMonitorStart()
	endIf
endEvent


function UFO4P_ResetCropMarkerCleanupBool(int workshopID = -1)
	if(workshopID >= 0)
		GetWorkshop(workshopID).UFO4P_CleanupDamageHelpers_WorkObjects = true
	else
		int workshopCount = workshops.Length
		workshopID = 0
		while(workshopID < workshopCount)
			GetWorkshop(workshopID).UFO4P_CleanupDamageHelpers_WorkObjects = true
			
			workshopID += 1
		endWhile
	endif
endFunction

ObjectReference Property UFO4P_ThreadMonitorRef = none auto hidden ; This will be filled by the thread monitor quest when it starts running, so we don't have to set it in the editor. Doing it that way makes sure that it still works with mods that modify properties on this script (these would be inevtiably missing this property until they are updated).

bool UFO4P_ThreadMonitorStarted = false
int UFO4P_ThreadMonitorTimerID = 37 const

int function UFO4P_GetThreadCount()
	return editLockCount
endFunction

function UFO4P_ThreadMonitorStopped()
	UFO4P_ThreadMonitorStarted = false
endFunction

function UFO4P_ThreadMonitorStart()
	if(UFO4P_ThreadMonitorRef)
		UFO4P_ThreadMonitorRef.Activate(akActivator = Workshops[0])
		UFO4P_ThreadMonitorStarted = true
	endif
endFunction

;recovery function: not nrmally used !!!
;call by external scripts to release the lock once (use with great care !!!)
function UFO4P_ReleaseLock()
	EditLock = false
endFunction


function UFO4P_ResetCurrentWorkshop (int workshopID)
	if(workshopID != currentWorkshopID)
		return
	endif

	if(UFO4P_AttackRunning && Workshops[workshopID] == UFO4P_WorkshopRef_ResetDelayed)
		UFO4P_WorkshopRef_ResetDelayed.UFO4P_CurrentlyUnderAttack = false
		UFO4P_WorkshopRef_ResetDelayed = none
	endif

	UFO4P_AttackRunning = false
	
	CurrentWorkshop.Clear()
	currentWorkshopID = -1
	WorkshopCurrentWorkshopID.SetValue(currentWorkshopID)
	UFO4P_ClearCurrentWorkshopArrays()

	;If a workshop unloads, we always must run another reset if the player returns.
	UFO4P_PreviousWorkshopLocation = none
endFunction


bool function UFO4P_IsWorkshopLoaded(WorkshopScript workshopRef, bool bResetIfUnloaded = false)
	if(workshopRef)
		int workshopID = workshopRef.GetWorkshopID()
		if(workshopID == currentWorkshopID)
			if(Game.GetPlayer().GetCurrentLocation() == workshopRef.myLocation || workshopRef.UFO4P_InWorkshopMode == true)
				return true
			elseif(bResetIfUnloaded)
				UFO4P_ResetCurrentWorkshop(workshopID)
			endif
		endif
	endif
	return false
endFunction 

;--------------------------------------------------------------------------------------------------------------------------------------------
;	Added by UFO4P 2.0.4 for Bug #24411:
;--------------------------------------------------------------------------------------------------------------------------------------------

;This bundles some operations to be carried out if a workshop reset is stopped prematurely
function UFO4P_StopWorkshopReset()
	UFO4P_UnassignedBeds = none
	UFO4P_ActorsWithoutBeds = none
	WSFW_ActorsWithoutBeds = None ; WSFW 2.0.0
	
	UFO4P_ResetRunning = false
	UFO4P_PreviousWorkshopLocation = none
endFunction

;--------------------------------------------------------------------------------------------------------------------------------------------
;	Added by UFO4P 2.0.4 for Bug #24312:
;--------------------------------------------------------------------------------------------------------------------------------------------
;	Helper arrays and variables:
;--------------------------------------------------------------------------------------------------------------------------------------------

bool UFO4P_ClearBedArrays

;UFO4P 2.0.6 Bug #25483 Note: These bools are obsolete now
bool UFO4P_FoodObjectArrayInitialized
bool UFO4P_SafetyObjectArrayInitialized

objectReference[] UFO4P_UnassignedFoodObjects
objectReference[] UFO4P_UnassignedSafetyObjects

WorkshopObjectScript[] UFO4P_UnassignedBeds
WorkshopNPCScript[] Property UFO4P_ActorsWithoutBeds Auto Hidden ; WSFW - Made into a property
WorkshopNPCScript[] UFO4P_FoodWorkers
WorkshopNPCScript[] UFO4P_SafetyWorkers

; WSFW 2.0.0 equivalent arrays of UFO4P above but for non-WorkshopNPCScript actors
Actor[] Property WSFW_ActorsWithoutBeds Auto Hidden
Actor[] WSFW_FoodWorkers
Actor[] WSFW_SafetyWorkers

;--------------------------------------------------------------------------------------------------------------------------------------------
;	Functions to manage the new helper arrays
;--------------------------------------------------------------------------------------------------------------------------------------------

;called by the OnLocationChange event before a workshop reset is started
function UFO4P_InitCurrentWorkshopArrays()
	UFO4P_ActorsWithoutBeds = New WorkshopNPCScript[0]
	UFO4P_FoodWorkers = New WorkshopNPCScript[0]
	UFO4P_SafetyWorkers = New WorkshopNPCScript[0]
	UFO4P_UnassignedBeds = New WorkshopObjectScript[0]
	UFO4P_UnassignedFoodObjects = New ObjectReference[0]
	UFO4P_UnassignedSafetyObjects = New ObjectReference[0]
	
	; WSFW 2.0.0
	WSFW_ActorsWithoutBeds = new Actor[0]
	WSFW_FoodWorkers = new Actor[0]
	WSFW_SafetyWorkers = new Actor[0]
endFunction

function UFO4P_ClearCurrentWorkshopArrays()
	UFO4P_FoodWorkers = none
	UFO4P_SafetyWorkers = none
	UFO4P_UnassignedFoodObjects = none
	UFO4P_UnassignedSafetyObjects = none
	; WSFW 2.0.0
	WSFW_FoodWorkers = None
	WSFW_SafetyWorkers = None
	
	if(UFO4P_ClearBedArrays)
		UFO4P_UnassignedBeds = none
		UFO4P_ActorsWithoutBeds = none
		; WSFW 2.0.0
		WSFW_ActorsWithoutBeds = None
	endif
endFunction


function UFO4P_AddActorToWorkerArray(WorkshopNPCScript actorRef, int resourceIndex)
	; WSFW 2.0.0 - Rerouting to our function which does not require WorkshopNPCScript
	WSFW_AddActorToWorkerArray(actorRef as Actor, resourceIndex)
endFunction

function WSFW_AddActorToWorkerArray(Actor actorRef, int resourceIndex)
	if(actorRef)
		if(resourceIndex == WorkshopRatingFood)
			if(WSFW_FoodWorkers == None)
				WSFW_FoodWorkers = new Actor[0]
			endIf
				
			if(WSFW_FoodWorkers.Find(actorRef) < 0)
				WSFW_FoodWorkers.Add(actorRef)
			endif
		elseif(resourceIndex == WorkshopRatingSafety)
			if(WSFW_SafetyWorkers == None)
				WSFW_SafetyWorkers = new Actor[0]
			endIf
				
			if(WSFW_SafetyWorkers.Find(actorRef) < 0)
				WSFW_SafetyWorkers.Add(actorRef)
			endif
		endif
	endif
endFunction


function UFO4P_RemoveActorFromWorkerArray(WorkshopNPCScript actorRef)
	; WSFW 2.0.0 - Rerouting to our function which does not require WorkshopNPCScript
	WSFW_RemoveActorFromWorkerArray(actorRef as Actor)
endFunction


function WSFW_RemoveActorFromWorkerArray(Actor actorRef)
	if(actorRef)
		int workerIndex = WSFW_FoodWorkers.Find(actorRef)
		
		if(workerIndex >= 0)
			WSFW_FoodWorkers.Remove(workerIndex)
		else
			workerIndex = WSFW_SafetyWorkers.Find(actorRef)
			
			if(workerIndex >= 0)
				WSFW_SafetyWorkers.Remove(workerIndex)
			endif
		endif
	endif
endFunction

			
function UFO4P_AddObjectToObjectArray(WorkshopObjectScript objectRef)
	if(objectRef)
		int resourceIndex = objectRef.GetResourceID()
						
		if(resourceIndex == WorkshopRatingFood)
			if(UFO4P_UnassignedFoodObjects == none)
				UFO4P_UnassignedFoodObjects = New ObjectReference[0]
			elseif(UFO4P_UnassignedFoodObjects.Find(objectRef) >= 0)
				return
			endif
			
			UFO4P_UnassignedFoodObjects.Add(objectRef)
		elseif(resourceIndex == WorkshopRatingSafety)
			if(UFO4P_UnassignedSafetyObjects == none)
				UFO4P_UnassignedSafetyObjects = New ObjectReference[0]
			elseif(UFO4P_UnassignedSafetyObjects.Find(objectRef) >= 0)
				return
			endif
			
			UFO4P_UnassignedSafetyObjects.Add(objectRef)
		endif
	endif
endFunction

;Called once from the ResetWorkshop function after it has looped through the actor array
function UFO4P_UpdateActorsWithoutBedsArray(WorkshopScript workshopRef)
	; WSFW 2.0.0 - Rerouting to our version taht doesn't require WorkshopNPCScript
	WSFW_UpdateActorsWithoutBedsArray(workshopRef)
endFunction

function WSFW_UpdateActorsWithoutBedsArray(WorkshopScript workshopRef)
	ObjectReference[] WorkshopBeds = GetBeds(workshopRef)
	int workshopID = workshopRef.GetWorkshopID()
	int countBeds = WorkshopBeds.Length
	
	int i = 0
	while(i < countBeds)
		WorkshopObjectScript theBed = WorkshopBeds[i] as WorkshopObjectScript
		
		if(theBed)
			Actor theOwner = theBed.GetActorRefOwner()
			if(theOwner && WorkshopFramework:WorkshopFunctions.GetWorkshopID(theOwner) == workshopID)
				int actorIndex = WSFW_ActorsWithoutBeds.Find (theOwner)
				if(actorIndex >= 0)
					WSFW_ActorsWithoutBeds.Remove(actorIndex)
				endif
			endif
		endif
		
		i += 1
	endWhile		
endFunction


function UFO4P_AddUnassignedBedToArray(WorkshopObjectScript objectRef)
	if(objectRef && UFO4P_UnassignedBeds.Find(objectRef) < 0)
		UFO4P_UnassignedBeds.Add(objectRef)
	endif
endFunction

function UFO4P_AddToActorsWithoutBedsArray(WorkshopNPCScript actorRef)
	; WSFW 2.0.0 - Rerouting to our non-WorkshopNPCScript version
	WSFW_AddToActorsWithoutBedsArray(actorRef as Actor)
endFunction

; WSFW 2.0.0: Alternate version of UFO4P_AddToActorsWithoutBedsArray that does not require WorkshopNPCScript
function WSFW_AddToActorsWithoutBedsArray(Actor actorRef)
	if(actorRef)
		if(WSFW_ActorsWithoutBeds == None)
			WSFW_ActorsWithoutBeds = new Actor[0]
		elseif(WSFW_ActorsWithoutBeds.Find(actorRef) >= 0)
			return
		endif
		
		WSFW_ActorsWithoutBeds.Add(actorRef)
	endif
endFunction

bool function UFO4P_ObjectArrayInitialized(int resourceIndex)
	if(resourceIndex == WorkshopRatingFood)
		return UFO4P_FoodObjectArrayInitialized
	else
		return UFO4P_SafetyObjectArrayInitialized
	endif
endFunction


ObjectReference[] function UFO4P_GetObjectArray(int resourceIndex)
	if(resourceIndex == WorkshopRatingFood)
		return UFO4P_UnassignedFoodObjects
	else
		return UFO4P_UnassignedSafetyObjects
	endif
endFunction

function UFO4P_SaveObjectArray(objectReference[] ResourceObjects, int resourceIndex)
	if(resourceIndex == WorkshopRatingFood)
		UFO4P_UnassignedFoodObjects = ResourceObjects
		UFO4P_FoodObjectArrayInitialized = true
	else
		UFO4P_UnassignedSafetyObjects = ResourceObjects
		UFO4P_SafetyObjectArrayInitialized = true
	endif
endFunction


;--------------------------------------------------------------------------------------------------------------------------------------------
;	Added by UFO4P 2.0.5 for Bug #25129:
;--------------------------------------------------------------------------------------------------------------------------------------------

actor[] UFO4P_UnassignedActors
int[] UFO4P_UnassignedActorIDs


function UFO4P_RegisterUnassignedActor(actor actorRef)
	if(actorRef && ! actorRef.IsDead()) ; WSFW 1.1.2 - Prevent persistence of dead NPCs
		if(UFO4P_UnassignedActors == none)
			UFO4P_UnassignedActors = new actor[0]
		elseif(UFO4P_UnassignedActors.Find(actorRef) >= 0)
			return
		endif
		
		UFO4P_UnassignedActors.Add(actorRef)
	endif
endFunction


function UFO4P_StoreUnassignedActorID(int actorID)
	if(UFO4P_UnassignedActorIDs == none)
		UFO4P_UnassignedActorIDs = new int [0]
	elseif(UFO4P_UnassignedActorIDs.Find(actorID) >= 0)
		return
	endif
	
	UFO4P_UnassignedActorIDs.Add(actorID)
endFunction

;called once by each workhop reset after looping through the resource object arrays:
function UFO4P_UpdateUnassignedActorsArray (WorkshopScript workshopRef)
	if(UFO4P_UnassignedActorIDs)
		int countIDs = UFO4P_UnassignedActorIDs.Length
		int i = 0
		
		while(i < countIDs)
			int actorID = UFO4P_UnassignedActorIDs[i]
			UFO4P_UnassignedActors.Remove(actorID)
			i += 1 ; WSFW - 1.0.2 - Added increment to eliminate infinite loop, notified Arthmoor about issue with UFO4P code
		endWhile
		
		UFO4P_UnassignedActorIDs = none
		workshopRef.UFO4P_HandleUnassignedActors = false
	endif
endFunction

Function WSFWPatch112Fix()
	; Prior to this, the UFO4P code could end up persisting dead NPCs
	int i = UFO4P_UnassignedActors.Length
	while(i > 0)
		int iIndex = i - 1
		
		if(UFO4P_UnassignedActors[i].IsDead())
			UFO4P_UnassignedActors.Remove(iIndex)
		endif
		
		i -= 1
	endWhile
EndFunction


;--------------------------------------------------------------------------------------------------------------------------------------------
;	Helper for UFO4P 2.0.4 retro script:
;--------------------------------------------------------------------------------------------------------------------------------------------

int UFO4P_ForcedResetTimerID = 52

function UFO4P_ForceWorkshopReset()
	if(currentWorkshopID >= 0)
		workshopScript workshopRef = Workshops[currentWorkshopID]
		;Make sure that the workshop is still loaded and reset currentWorkshopID if it's not. This will force a reset on next location change
		;without having to use the timer.
		
		if(UFO4P_IsWorkshopLoaded(workshopRef, bResetIfUnloaded = true))
			;Start the reset from a timer, so the UFO4P 2.0.4 retro quest can shut down immediately and doesn't have to wait
			;until the reset has finished running:
			StartTimer(0.1, UFO4P_ForcedResetTimerID)
		endif
	endif
endFunction

function UFO4P_InitObjectArrays(WorkshopScript workshopRef)
	UFO4P_UnassignedFoodObjects = UFO4P_BuildObjectArray(workshopRef, WorkshopRatingFood)
	UFO4P_UnassignedSafetyObjects = UFO4P_BuildObjectArray(workshopRef, WorkshopRatingSafety)
endFunction

;Helper to return an object array with all invalid objects removed:
ObjectReference[] Function UFO4P_BuildObjectArray(WorkshopScript workshopRef, int resourceIndex)
	ObjectReference[] ResourceObjects = GetResourceObjects(workshopRef, WorkshopRatings[resourceIndex].resourceValue, 2)
	
	int i = 0
	while(i < ResourceObjects.Length)
		ObjectReference theObjectRef = ResourceObjects [i]
		WorkshopObjectScript theObject = theObjectRef as WorkshopObjectScript
		
		if(theObject == None)
			ResourceObjects.Remove(i)
		elseif(theObject.IsActorAssigned() || theObject.HasKeyword(WorkshopWorkObject) == false)
			ResourceObjects.Remove(i)
		else
			i += 1
		endif
	endWhile
	
	return ResourceObjects
endFunction

function UFO4P_RemoveFromUnassignedObjectsArray(ObjectReference objectRef, int resourceIndex)
	if(resourceIndex == WorkshopRatingFood && UFO4P_UnassignedFoodObjects)
		int objectID = UFO4P_UnassignedFoodObjects.Find (objectRef)
		if(objectID >= 0)
			UFO4P_UnassignedFoodObjects.Remove(objectID)
		endif
	elseif(resourceIndex == WorkshopRatingSafety && UFO4P_UnassignedSafetyObjects)
		int	objectID = UFO4P_UnassignedSafetyObjects.Find (objectRef)
		if(objectID >= 0)
			UFO4P_UnassignedSafetyObjects.Remove(objectID)
		endif
	endif
endFunction

function UFO4P_RemoveFromUnassignedBedsArray(WorkshopObjectScript theObject)
	if(theObject && UFO4P_UnassignedBeds)
		int objectID = UFO4P_UnassignedBeds.Find(theObject)
		if(objectID >= 0)
			UFO4P_UnassignedBeds.Remove(objectID)
		endif
	endif
endFunction

int function InitResourceID(WorkshopObjectScript resourceRef)
	if(resourceRef.HasResourceValue (WorkshopRatings[0].resourceValue))
		;0 - food
		return 0
	else
		int i = 3
		while(i < 6)
			if(resourceRef.HasResourceValue(WorkshopRatings[i].resourceValue))
				;3 - safety, 4 - water, 5 - power
				return i
			endif
			
			i += 1
		endWhile
	endif
	
	return -1
endFunction