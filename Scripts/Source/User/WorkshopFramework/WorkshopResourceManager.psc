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


CustomEvent ResourceShortageResolved
CustomEvent ResourceShortageExpired

; ---------------------------------------------
; Consts
; ---------------------------------------------
int iTimerID_RecheckWithinSettlement = 100 Const
Float fTimerLength_RecheckWithinSettlement = 5.0 Const
int iTimerID_FixSettlerCount = 101 Const ; TODO - This doesn't appear to be started anywhere
int iTimerID_DoubleCheckRemoteBuiltResources = 102 Const ; 1.0.5 - Switching remote resource management to a queue system
Float fTimerLength_DoubleCheckRemoteBuiltResources = 3.0 Const

int iTimerID_CheckResourceShortages = 103 ; 1.0.8 - Adding new ResourceShortage system
float fTimerLength_CheckResourceShortages = 24.0 ; 1.0.8 - Checking daily
Float fLastTimerStart_CheckResourceShortages = 0.0 ; Intentionally not const - organizing timer vars

float fResourceShortageExpirationPeriod = 2.0 ; 1.0.8 - The amount of time before a ResourceShortage expires (in game days), this should be longer than the daily check in case the daily check hasn't completed within the expiration period

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
	ActorValue Property WSFW_Safety Auto Const Mandatory ; 1.1.7
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
	RefCollectionAlias Property RemoteBuiltResources Auto Const Mandatory
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
	GlobalVariable Property WSFW_Setting_AllowSettlementsToLeavePlayerControl Auto Mandatory ; 1.0.4 - New Setting
	GlobalVariable Property WSFW_Setting_RobotHappinessLevel Auto Mandatory
	GlobalVariable Property WSFW_Setting_ShelterMechanic Auto Mandatory ; 1.0.5 - New Setting
	
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
	ActorValue Property WSFW_AV_iBaseMaxBrahmin Auto Const Mandatory
	ActorValue Property WSFW_AV_iBaseMaxSynths Auto Const Mandatory
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
Bool bHandleRemoteBuiltResourcesBlock = false
Bool bUpdateResourceShortagesBlock = false

; ---------------------------------------------
; Events 
; ---------------------------------------------

Event Actor.OnLocationChange(Actor akActorRef, Location akOldLoc, Location akNewLoc)
	HandleLocationChange(akNewLoc)
EndEvent


Event OnTimer(Int aiTimerID)
	if(aiTimerID == iTimerID_RecheckWithinSettlement)
		CheckForWorkshopChange(true)
	elseif(aiTimerID == iTimerID_FixSettlerCount)
		; do nothing
	elseif(aiTimerID == iTimerID_DoubleCheckRemoteBuiltResources)
		HandleRemoteBuiltResources()
	endif
EndEvent


Event OnTimerGameTime(Int aiTimerID)
	if(aiTimerID == iTimerID_CheckResourceShortages)
		UpdateAllResourceShortages()
		
		StartCheckResourceShortagesTimer()
	endif
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
		; 1.0.5 - This is causing thread lock up when a large batch of items is built at once - such as via a Sim Settlements City Plan or Transfer Settlemetns import. Switching to a queue system.
		; Applying resources remotely
		; ApplyObjectSettlementResources(kObjectRef, kWorkshopRef, false, true)
		if(kObjectRef.GetValue(WorkshopResourceObject) > 0)
			RemoteBuiltResources.AddRef(kObjectRef)
			HandleRemoteBuiltResources()
		endif
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
	;ModTrace("[WorkshopActorAssignedToWork Event Received] AssignedObject: " + akArgs[0] + ", Workshop: " + akArgs[1] + ", ActorRef: " + akArgs[2])
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
	if(akSenderRef == WorkshopParent && aiStageID == iWorkshopParentInitializedStage) ; 1.1.0 - added specific stage check
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
	
	RegisterForEvents()
	
	if(WorkshopParent.GetStageDone(iWorkshopParentInitializedStage))
		SetupAllWorkshopProperties()
	else
		RegisterForRemoteEvent(WorkshopParent, "OnStageSet")
	endif
EndFunction


Function HandleGameLoaded()
	RegisterForEvents()
	
	Parent.HandleGameLoaded()
	
	if( ! Workshops)
		Workshops = new WorkshopScript[0]
	endif
	
	if( ! WorkshopLocations)
		WorkshopLocations = new Location[0]
	endif
	
	CleanFormList(WorkshopTrackedAVs)
	SyncWorkshopArrayIndexes()
	
	Float fCurrentGameTime = Utility.GetCurrentGameTime()
	
	if(fLastTimerStart_CheckResourceShortages < fCurrentGameTime - (fTimerLength_CheckResourceShortages/24.0))
		StartCheckResourceShortagesTimer()
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

Function HandleInstallModChanges()
	SetupAllWorkshopProperties() ; 1.0.8 - Confirm any new properties are configured each patch
	
	if(iInstalledVersion < 26)
		ThreadManager.UnregisterForCallbackThreads(Self) ; We don't need these callbacks
	endif
	
	if(iInstalledVersion < 22) ; 1.1.8 - Update vars for new WSFW_PowerRequired feature
		int i = 0
		WorkshopScript[] WorkshopsArray = WorkshopParent.Workshops
		
		while(i < WorkshopsArray.Length)
			WorkshopScript thisWorkshop = WorkshopsArray[i]
			thisWorkshop.FillWSFWVars()
			
			i += 1
		endWhile
	endif
	
	if(iInstalledVersion < 21) ; 1.1.7 - Update vars for new WSFW_Safety fix
		int i = 0
		WorkshopScript[] WorkshopsArray = WorkshopParent.Workshops
		
		while(i < WorkshopsArray.Length)
			WorkshopScript thisWorkshop = WorkshopsArray[i]
			thisWorkshop.FillWSFWVars()
			
			i += 1
		endWhile
	endif
	
	if(iInstalledVersion < 15)
		WorkshopParent.WSFWPatch112Fix()
	endif
	
	if(iInstalledVersion < 12)
		; 1.0.8 - Starting resource shortage loop
		StartCheckResourceShortagesTimer()
	endif
	
	
	if(iInstalledVersion < 11)
		; 1.0.7 - WSFW_Setting_AdjustMaxNPCsByCharisma was pointing to the wrong variable for people who started on versions earlier than 1.0.4
		int i = 0
		WorkshopScript[] WorkshopsArray = WorkshopParent.Workshops
		
		while(i < WorkshopsArray.Length)
			WorkshopScript thisWorkshop = WorkshopsArray[i]
			
			thisWorkshop.WSFW_Setting_AdjustMaxNPCsByCharisma = WSFW_Setting_AdjustMaxNPCsByCharisma
			
			i += 1
		endWhile		
	endif
	
	if(iInstalledVersion < 10) 
		; 1.0.5 - Adding new ShelterMechanic option
		int i = 0
		WorkshopScript[] WorkshopsArray = WorkshopParent.Workshops
		
		while(i < WorkshopsArray.Length)
			WorkshopScript thisWorkshop = WorkshopsArray[i]
			
			thisWorkshop.WSFW_Setting_ShelterMechanic = WSFW_Setting_ShelterMechanic
			
			i += 1
		endWhile
	endif
	
	if(iInstalledVersion < 4) 
		; 1.0.3 - Fix for RobotHappinessLevel which was pointing to the wrong variable
		int i = 0
		WorkshopScript[] WorkshopsArray = WorkshopParent.Workshops
		
		while(i < WorkshopsArray.Length)
			WorkshopScript thisWorkshop = WorkshopsArray[i]
			
			thisWorkshop.WSFW_Setting_RobotHappinessLevel = WSFW_Setting_RobotHappinessLevel
			thisWorkshop.WSFW_AV_RobotHappinessLevel = WSFW_AV_RobotHappinessLevel
			; We changed the names of MaxBrahmin and MaxSynths to iBaseMax to clarify what they are for
			thisWorkshop.WSFW_AV_iBaseMaxBrahmin = WSFW_AV_iBaseMaxBrahmin
			thisWorkshop.WSFW_AV_iBaseMaxSynths = WSFW_AV_iBaseMaxSynths
			
			i += 1
		endWhile
	endif
	
	if(iInstalledVersion < 6) 
		; 1.0.4 - If someone installed this for the first time with 1.0.3 on an existing save, many of their settlements wouldn't get the vars until they visited for the first time - rectifying this
		int i = 0
		WorkshopScript[] WorkshopsArray = WorkshopParent.Workshops
		
		while(i < WorkshopsArray.Length)
			WorkshopScript thisWorkshop = WorkshopsArray[i]
			
			; Fix happiness which was pointed at the wrong AV in 1.0.3
			thisWorkshop.Happiness = Happiness
			
			thisWorkshop.FillWSFWVars()
			
			i += 1
		endWhile
	endif
	
	; 1.0.4b - Cleaning up Workshops array, may have been a bug that caused settlements to be added multiple times
	if(iInstalledVersion < 7)
		if(WorkshopParent.Workshops.Length < Workshops.Length)
			Workshops = new WorkshopScript[0]
			WorkshopLocations = new Location[0]
			
			SetupAllWorkshopProperties()
		endif
	endif
	
	Parent.HandleInstallModChanges()
EndFunction

; ---------------------------------------------
; Functions
; ---------------------------------------------

Function RegisterForEvents()
	; Register for events
	RegisterForRemoteEvent(PlayerRef, "OnLocationChange") ; We want to be directly aware of this for settlements like Spectacle Island
	RegisterForCustomEvent(WorkshopParent, "WorkshopInitializeLocation")
	
	WorkshopParent.RegisterForWorkshopEvents(Self, bRegister = true)
EndFunction


Function StartCheckResourceShortagesTimer()
	fLastTimerStart_CheckResourceShortages = Utility.GetCurrentGameTime()
	StartTimerGameTime(fTimerLength_CheckResourceShortages, iTimerID_CheckResourceShortages)
EndFunction

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
	
	; 1.0.4 - Ensure that properties get filled on workshops array immediately - otherwise if DailyUpdate hits before the player visits each settlement the properties will have never filled
	akWorkshopRef.FillWSFWVars()
	
	; Add workshop and location to our copy of the arrays
	if(Workshops.Find(akWorkshopRef) < 0) ; 1.0.5 - ensure this doesn't get added twice
		Workshops.Add(akWorkshopRef)
		WorkshopLocations.Add(akWorkshopRef.GetCurrentLocation())
	endif
	
	ModTrace("Marking properties configured for workshop: " + akWorkshopRef)
	akWorkshopRef.bPropertiesConfigured = true
EndFunction

Function SyncWorkshopArrayIndexes()
	; Ensure our workshop array indexes match the workshopID - TODO: We should probably stick this on workshop parent as well
	WorkshopScript[] kRearrangedWorkshops = new WorkshopScript[0]
	Location[] kRearrangedLocations = new Location[0]
	
	Int[] iWorkshopIDs = new Int[0]
	
	int i = 0
	while(i < Workshops.Length)
		iWorkshopIDs.Add(Workshops[i].GetWorkshopID())
		
		i += 1
	endWhile
	
	int iSearchingFor = 0
	Bool bAdded = false
	while(iSearchingFor < iWorkshopIDs.Length)
		Int iIndex = iWorkshopIDs.Find(iSearchingFor)
		
		if(iIndex < 0)
			; Not found, insert blanks
			kRearrangedWorkshops.Add(None)
			kRearrangedLocations.Add(None)
		else
			kRearrangedWorkshops.Add(Workshops[iIndex])
			Location thisLocation = Workshops[iIndex].myLocation
			if( ! thisLocation)
				thisLocation = Workshops[iIndex].GetCurrentLocation()
			endif
			
			kRearrangedLocations.Add(thisLocation)
		endif
		
		iSearchingFor += 1
	endWhile
	
	Workshops = kRearrangedWorkshops
	WorkshopLocations = kRearrangedLocations
EndFunction


Function CheckForWorkshopChange(Bool abTimedDoubleCheck = false)
	WorkshopScript thisWorkshop = GetNearestWorkshop(PlayerRef)
	WorkshopScript previousWorkshop = LatestWorkshop.GetRef() as WorkshopScript
	
	if(thisWorkshop)
		if(thisWorkshop != previousWorkshop)		
			if( ! PlayerRef.IsWithinBuildableArea(thisWorkshop))
				if( ! abTimedDoubleCheck)
					StartTimer(fTimerLength_RecheckWithinSettlement, iTimerID_RecheckWithinSettlement) ; Check again in a few seconds, the player could just be hanging out near the border
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
	; No longer necessary after fixing the WorkshopParentScript.AddActorToWorkshop() bug
EndFunction


Function ApplyObjectSettlementResources(ObjectReference akObjectRef, WorkshopScript akWorkshopRef, Bool abRemoved = false, Bool abGetLock = false)
	if( ! akObjectRef || ! akWorkshopRef) 
		return
	endif
	
	if(akWorkshopRef.Is3dLoaded()) ; 1.1.7 - Changed to calling recalc on the workshopRef instead
		; If the workshop is loaded, there's no need to run this manually - in fact doing so, will cause duplicate resource counts
		if(akWorkshopRef.myLocation && akWorkshopRef.myLocation.IsLoaded())
			akWorkshopRef.RecalculateWorkshopResources()
		endif
		
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
	Bool bTemporarilyEnabled = false	
	if(akObjectRef.IsDisabled())
		if(abRemoved)
			bTemporarilyEnabled = true
			; 1.0.5 - No need to move this object since we're only doing it if the workshop is unloaded
			akObjectRef.Enable(false) ; Temporarily enable for checking resources
		else
			bContinue = false
		endif
	endif
	
	if(bContinue)		
		WorkshopObjectScript asWorkshopObject = akObjectRef as WorkshopObjectScript
		
		Bool bCountResources = true
		if( ! abRemoved)
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
		endif
			
		int i = 0
		if(bCountResources)
			; TODO - This is way too slow, switch WorkshopTrackedAVs to a set of arrays intead of a formlist
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
		
	if(bTemporarilyEnabled) ; 1.0.5 - No need to move the object since we're only doing this while the settlement is unloaded
		akObjectRef.Disable(false)
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

; 1.0.5 - Switching to a block function that acts as a queue instead of trying to use an edit lock on calls during an event. The event method works fine until the system is hit by a burst of requests at once, such as from a TS Import or SS City Plan
Function HandleRemoteBuiltResources()
	if(bHandleRemoteBuiltResourcesBlock)
		return
	endif
	
	bHandleRemoteBuiltResourcesBlock = true
	
	int i = RemoteBuiltResources.GetCount()
	
	while(i > 0)
		ObjectReference kObjectRef = RemoteBuiltResources.GetAt(0)
		
		if(kObjectRef)
			RemoteBuiltResources.RemoveRef(kObjectRef)
			
			WorkshopScript thisWorkshop = kObjectRef.GetLinkedRef(WorkshopItemKeyword) as WorkshopScript
			
			if(thisWorkshop)
				; Since we're now doing these in a queue instead of at the event level - we shouldn't need to worry about grabbing a lock - even if there is a race condition that occurs due to another mod trying to handle something similar (applying workshopRef resources remotely) - it will be resolved when the player next returns to the settlement - so the minimal risk is worth it.
				ApplyObjectSettlementResources(kObjectRef, thisWorkshop, abRemoved = false, abGetLock = false)
			endif
		endif
	
		i -= 1
	endWhile
	
	bHandleRemoteBuiltResourcesBlock = false
	
	if(RemoteBuiltResources.GetCount() > 0)
		; Some more resources were added while we were running, just in case a follow-up event doesn't trigger this, we'll check again shortly
		StartTimer(fTimerLength_DoubleCheckRemoteBuiltResources, iTimerID_DoubleCheckRemoteBuiltResources)
	endif
EndFunction


; 1.0.8 - Loop through cleaning up resource shortages for all settlements
Function UpdateAllResourceShortages()
	if(bUpdateResourceShortagesBlock)
		return
	endif
	
	bUpdateResourceShortagesBlock = true
	
	int i = 0
	while(i < Workshops.Length)
		UpdateResourceShortages(Workshops[i])
		
		i += 1
	endWhile
	
	bUpdateResourceShortagesBlock = false
EndFunction

; 1.0.8 - Clean up the resource shortages data, clearing out expired or untrue shortages
Function UpdateResourceShortages(WorkshopScript akWorkshopRef)
	if( ! akWorkshopRef)
		return
	endif
	
	int i = 0
	Int[] iClear = new Int[0]
	Float fExpiredTime = Utility.GetCurrentGameTime() - fResourceShortageExpirationPeriod
	
	while(i < akWorkshopRef.ShortResources.Length)
		if(akWorkshopRef.ShortResources[i].fTimeLastReported < fExpiredTime)
			iClear.Add(i)
			
			Var[] kArgs = new Var[3]
			kArgs[0] = akWorkshopRef
			kArgs[1] = akWorkshopRef.ShortResources[i].ResourceAV
			kArgs[2] = akWorkshopRef.ShortResources[i].fAmountRequired
			SendCustomEvent("ResourceShortageExpired", kArgs)
		elseif(GetWorkshopValue(akWorkshopRef, akWorkshopRef.ShortResources[i].ResourceAV) >= akWorkshopRef.ShortResources[i].fAmountRequired)
			iClear.Add(i)
			
			Var[] kArgs = new Var[3]
			kArgs[0] = akWorkshopRef
			kArgs[1] = akWorkshopRef.ShortResources[i].ResourceAV
			kArgs[2] = akWorkshopRef.ShortResources[i].fAmountRequired
			SendCustomEvent("ResourceShortageResolved", kArgs)
		endif
		
		i += 1
	endWhile
	
	i = iClear.Length
	while(i > 0)
		if(akWorkshopRef.ShortResources.Length >= i)
			if(akWorkshopRef.ShortResources.Length == 1)
				akWorkshopRef.ShortResources = new ResourceShortage[0]
			else
				akWorkshopRef.ShortResources.Remove(i)
			endif
		endif
		
		i -= 1
	endWhile
EndFunction



Bool Function RegisterResourceShortage(WorkshopScript akWorkshopRef, ActorValue aResourceAV, Float afTargetWorkshopValue)
	if( ! akWorkshopRef || ! aResourceAV || afTargetWorkshopValue <= GetWorkshopValue(akWorkshopRef, aResourceAV))
		return false
	endif
	
	int i = 0
	bool bShortageFound = false
	bool bNewShortage = false
	while(i < akWorkshopRef.ShortResources.Length && ! bShortageFound)
		if(akWorkshopRef.ShortResources[i].ResourceAV == aResourceAV)
			bShortageFound = true
			
			if(akWorkshopRef.ShortResources[i].fAmountRequired <= afTargetWorkshopValue) ; <= so we can update the time
				bNewShortage = true
				; We just want to store the largest amount reported as needed
				akWorkshopRef.ShortResources[i].fAmountRequired = afTargetWorkshopValue
				akWorkshopRef.ShortResources[i].fTimeLastReported = Utility.GetCurrentGameTime()
			endif
		endif
		
		i += 1
	endWhile
	
	if( ! bShortageFound)
		bNewShortage = true
		; New entry needed
		ResourceShortage newShortage = new ResourceShortage
		newShortage.ResourceAV = aResourceAV
		newShortage.fAmountRequired = afTargetWorkshopValue
		newShortage.fTimeLastReported = Utility.GetCurrentGameTime()
		
		if( ! akWorkshopRef.ShortResources)
			akWorkshopRef.ShortResources = new ResourceShortage[0]
		endif
		
		akWorkshopRef.ShortResources.Add(newShortage)
	endif
	
	return bNewShortage
EndFunction