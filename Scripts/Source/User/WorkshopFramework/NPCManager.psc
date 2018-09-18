; ---------------------------------------------
; WorkshopFramework:NPCManager.psc - by kinggath
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

Scriptname WorkshopFramework:NPCManager extends WorkshopFramework:Library:SlaveQuest
{ Handles NPCs - this will include things like Settlers and Brahmin by default, but can easily expand to other things }


import WorkshopFramework:Library:DataStructures
import WorkshopFramework:Library:UtilityFunctions
import WorkshopFramework:WorkshopFunctions


; ---------------------------------------------
; Consts
; ---------------------------------------------

int RecruitmentLoopTimerID = 100 Const


; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------

Group Controllers
	WorkshopFramework:MainThreadManager Property ThreadManager Auto Const Mandatory
	WorkshopParentScript Property WorkshopParent Auto Const Mandatory 
	Int Property iWorkshopParentInitializedStage = 20 Auto Const
	WorkshopFramework:WorkshopResourceManager Property ResourceManager Auto Const Mandatory
	GlobalVariable Property WorkshopCurrentWorkshopID Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_RobotsCountTowardsMaxPopulation Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_RecruitSettlersOnFirstBeaconActivation Auto Const Mandatory
EndGroup


Group Aliases
	ReferenceAlias Property WorkshopNewSettlerAlias Auto Const Mandatory
	{ Point to WorkshopNewSettler on WorkshopParent }
	ReferenceAlias Property WorkshopAIAlias Auto Const Mandatory
	{ Point to alias with our AI package }
EndGroup


Group ActorValues
	ActorValue Property WorkshopRadioRating Auto Const Mandatory
	ActorValue Property Population Auto Const Mandatory
	ActorValue Property RobotPopulation Auto Const Mandatory
	ActorValue Property BrahminPopulation Auto Const Mandatory
	ActorValue Property UnassignedPopulation Auto Const Mandatory
	ActorValue Property SynthPopulation Auto Const Mandatory
	ActorValue Property Happiness Auto Const Mandatory
	{ Actual happiness, not bonus }
	ActorValue Property HappinessModifier Auto Const Mandatory
	ActorValue Property LastAttackDaysSince Auto Const Mandatory
	ActorValue Property WorkshopGuardPreference Auto Const Mandatory
EndGroup


Group Keywords
	Keyword Property WorkshopType02 Auto Const Mandatory
	{ Keyword applied to workshop that indicates a raider settlement }
	Keyword Property WorkshopLinkSpawn Auto Const Mandatory
	{ Keyword linking the position new settlers should be spawned at }
	Keyword Property WorkshopItemKeyword Auto Const Mandatory
	{ Keyword items are linked to the workshop on (includes settlers/brahmin) }
	Keyword Property WorkshopLinkSandbox Auto Const Mandatory
	Keyword Property WorkshopLinkHome Auto Const Mandatory
	Keyword Property WorkshopLinkCenter Auto Const Mandatory
	
	LocationRefType Property WorkshopSynthRefType Auto Const Mandatory
EndGroup


Group Assets
	ActorBase Property BrahminActorBase Auto Const Mandatory
	{ Actorbase that should be using InjectionManger.BrahminLCharHolder as its template source }
	ActorBase Property SettlerActorBase Auto Const Mandatory
	{ Actorbase that should be using InjectionManger.SettlerLCharHolder as its template source }
	ActorBase Property SettlerGuardActorBase Auto Const Mandatory
	{ Actorbase that should be using InjectionManger.SettlerLCharHolder as its template source }
EndGroup

Group Settings
	Float[] Property DefaultFirstSettlersRecruitmentChances Auto Const
	{ Each entry represents the percent chance of getting that settler when a beacon is first built in a settlement. For example, if the first number is 100, you will guarantee that settler. If the next number is 30, you'd have a 30% chance of getting a second settler, etc. }
EndGroup

; ---------------------------------------------
; Properties
; ---------------------------------------------

Float Property fRecruitmentLoopTime = 24.0 Auto Hidden
Float[] Property FirstSettlersRecruitmentChances Auto Hidden

; ---------------------------------------------
; Vars
; ---------------------------------------------

Bool bRecruitmentUnderwayBlock ; Unlike a lock, with the block we will just reject any incoming calls if a block is held

; ---------------------------------------------
; Events 
; ---------------------------------------------

Event OnTimerGameTime(Int aiTimerID)
	if(aiTimerID == RecruitmentLoopTimerID)
		RecruitAllWorkshopNPCs()
		
		StartRecruitmentTimer()
	endif
EndEvent

Event WorkshopParentScript.WorkshopAddActor(WorkshopParentScript akSenderRef, Var[] akArgs)
	;/
	kargs[0] = newActorRef; kargs[1] = newWorkshopID
	/;
EndEvent

Event WorkshopParentScript.WorkshopRemoveActor(WorkshopParentScript akSenderRef, Var[] akArgs)
	;/
	kargs[0] = removedActor; kargs[1] = workshopRef
	/;
EndEvent

Event WorkshopParentScript.WorkshopActorAssignedToBed(WorkshopParentScript akSenderRef, Var[] akArgs)
	;/
	kargs[0] = assignedObject; kargs[1] = workshopRef; kargs[2] = assignedActor
	/;
EndEvent

Event WorkshopParentScript.WorkshopActorAssignedToWork(WorkshopParentScript akSenderRef, Var[] akArgs)
	;/
	kargs[0] = assignedObject; kargs[1] = workshopRef; kargs[2] = assignedActor
	/;
EndEvent

Event WorkshopParentScript.WorkshopActorUnassigned(WorkshopParentScript akSenderRef, Var[] akArgs)
	;/
	kargs[0] = assignedObject; kargs[1] = workshopRef; kargs[2] = assignedActor
	/;
EndEvent

Event WorkshopParentScript.WorkshopActorCaravanAssign(WorkshopParentScript akSenderRef, Var[] akArgs)
	;/
	kargs[0] = assignedActor; kargs[1] = workshopRef
	/;
EndEvent

Event WorkshopParentScript.WorkshopActorCaravanUnassign(WorkshopParentScript akSenderRef, Var[] akArgs)
	;/
	kargs[0] = assignedActor; kargs[1] = workshopRef
	/;
EndEvent

Event WorkshopParentScript.AssignmentRulesOverriden(WorkshopParentScript akSenderRef, Var[] akArgs)
	;/ 
	kArgs[0] = objectRef or None for Caravan; kArgs[1] = workshopRef; kArgs[2] = actorRef
	/;
EndEvent

Event Quest.OnStageSet(Quest akSenderRef, Int aiStageID, Int aiItemID)
	if(akSenderRef == WorkshopParent)
		StartRecruitmentTimer()
	
		UnregisterForRemoteEvent(akSenderRef, "OnStageSet")
	endif
EndEvent

; ---------------------------------------------
; Extended Handlers
; ---------------------------------------------

Function HandleQuestInit()
	Parent.HandleQuestInit()
	
	; Register for events
	RegisterForCustomEvent(WorkshopParent, "WorkshopAddActor")
	RegisterForCustomEvent(WorkshopParent, "WorkshopActorAssignedToWork")
	RegisterForCustomEvent(WorkshopParent, "WorkshopActorUnassigned")
	RegisterForCustomEvent(WorkshopParent, "WorkshopActorCaravanAssign")
	RegisterForCustomEvent(WorkshopParent, "WorkshopActorCaravanUnassign")
	; Custom WSFW events from WorkshopParent
	RegisterForCustomEvent(WorkshopParent, "WorkshopActorAssignedToBed")
	RegisterForCustomEvent(WorkshopParent, "WorkshopRemoveActor")
	RegisterForCustomEvent(WorkshopParent, "AssignmentRulesOverriden")
	
	; Configure Initial Settler Chances
	FirstSettlersRecruitmentChances = new Float[0]
	int i = 0
	while(i < DefaultFirstSettlersRecruitmentChances.Length)
		FirstSettlersRecruitmentChances.Add(i)
		
		i += 1
	endWhile
	
	; Start Recruitment Loop
	if(WorkshopParent.GetStageDone(iWorkshopParentInitializedStage))
		StartRecruitmentTimer()
	else
		RegisterForRemoteEvent(WorkshopParent, "OnStageSet")
	endif
EndFunction

; ---------------------------------------------
; Overrides
; ---------------------------------------------


; ---------------------------------------------
; Functions
; ---------------------------------------------

Function StartRecruitmentTimer()
	StartTimerGameTime(fRecruitmentLoopTime, RecruitmentLoopTimerID)
EndFunction


Function AlterFirstSettlersRecruitmentChances(Int aiChanceIndex, Int aiNewChancePercentage)
	if(aiChanceIndex >= FirstSettlersRecruitmentChances.Length)
		return
	endif
	
	if(aiNewChancePercentage < 0)
		aiNewChancePercentage = 0
	elseif(aiNewChancePercentage > 100)
		aiNewChancePercentage = 100
	endif
	
	FirstSettlersRecruitmentChances[aiChanceIndex] = aiNewChancePercentage
EndFunction


; Returns number of chance entries after adding this, or -1 if the array was full
Int Function AddFirstSettlerRecruitmentChance(Int aiNewChancePercentage)
	if(FirstSettlersRecruitmentChances.Length >= 128)
		return -1
	endif
	
	FirstSettlersRecruitmentChances.Add(aiNewChancePercentage)
	
	return FirstSettlersRecruitmentChances.Length
EndFunction


Function RecruitAllWorkshopNPCs()
	if(bRecruitmentUnderwayBlock)
		return
	endif
	
	bRecruitmentUnderwayBlock = true
	
	Float fStartTime = Utility.GetCurrentRealtime()
	
	int i = 0
	RefCollectionAlias WorkshopsAlias = ResourceManager.WorkshopsAlias
	int iCount = WorkshopsAlias.GetCount()
	
	while(i < iCount)
		WorkshopScript kWorkshopRef = WorkshopsAlias.GetAt(i) as WorkshopScript
		
		RecruitWorkshopNPCs(kWorkshopRef)
		
		i += 1
	endWhile
	
	Debug.Trace("WSFW: NPC recruitment for " + iCount + " workshops took " + (Utility.GetCurrentRealtime() - fStartTime) + " seconds.")
	bRecruitmentUnderwayBlock = false
EndFunction

Function RecruitWorkshopNPCs(WorkshopScript akWorkshopRef)
	if( ! akWorkshopRef)
		return
	endif
	
	int iWorkshopID = akWorkshopRef.GetWorkshopID()
	
	if(iWorkshopID < 0)
		return
	endif	
	
	; attract new NPCs
	; if I have a radio station
	int iRadioRating = akWorkshopRef.GetValue(WorkshopRadioRating) as int
	int iTotalPopulation = akWorkshopRef.GetBaseValue(Population) as int
	int iRobotPopulation = akWorkshopRef.GetBaseValue(RobotPopulation) as int
	int iLivingPopulation = iTotalPopulation - iRobotPopulation
	int iUnassignedPopulation = akWorkshopRef.GetValue(UnassignedPopulation) as int
	int iBrahminPopulation = akWorkshopRef.GetValue(BrahminPopulation) as int
	float fCurrentHappiness = akWorkshopRef.GetValue(Happiness)
	float fDailyChance = akWorkshopRef.attractNPCDailyChance
	float fAttractNPCHappinessMult = akWorkshopRef.attractNPCHappinessMult
	int iMaxBonusAttractChancePopulation = akWorkshopRef.iMaxBonusAttractChancePopulation
	int iMaxSurplusNPCs = akWorkshopRef.iMaxSurplusNPCs
	int iMaxWorkshopNPCs = akWorkshopRef.GetMaxWorkshopNPCs()
	int iMaxBrahmin = akWorkshopRef.iBaseMaxBrahmin
	bool bAllowBrahmin = akWorkshopRef.AllowBrahminRecruitment
	float fAttractBrahminChance = akWorkshopRef.recruitmentBrahminChance
	
	int iCheckPopulation = iTotalPopulation
	
	if(WSFW_Setting_RobotsCountTowardsMaxPopulation.GetValue() == 0)
		iCheckPopulation = iLivingPopulation
	endif
	
	if(iRadioRating > 0 && akWorkshopRef.HasKeyword(WorkshopType02) == false && iUnassignedPopulation < iMaxSurplusNPCs && iCheckPopulation < iMaxWorkshopNPCs)
		
		float fAttractChance = fDailyChance + fCurrentHappiness/100 * fAttractNPCHappinessMult
		
		if(iCheckPopulation < iMaxBonusAttractChancePopulation)
			fAttractChance += (iMaxBonusAttractChancePopulation - iCheckPopulation) * fDailyChance
		endif
		
		; roll to see if a new NPC arrives
		float fDieRoll = utility.RandomFloat()
		
		if(fDieRoll <= fAttractChance)
			WorkshopNPCScript newWorkshopActor = CreateSettler(akWorkshopRef)
			
			if(newWorkshopActor && newWorkshopActor.GetValue(WorkshopGuardPreference) == 0)
				; If settler is not a guard, they are considered a farmer, and might have a brahmin
				if(iBrahminPopulation < iMaxBrahmin && akWorkshopRef.AllowBrahminRecruitment)
					int brahminRoll = utility.RandomInt()
					
					if(brahminRoll <= fAttractBrahminChance)
						CreateBrahmin(akWorkshopRef)
					endif
				endif
			endif
		endif
	endif
EndFunction


Function CreateInitialSettlers(WorkshopScript akWorkshopRef, ObjectReference akSpawnAtRef = None)
	if( ! akWorkshopRef || WSFW_Setting_RecruitSettlersOnFirstBeaconActivation.GetValue() == 0)
		return
	endif
	
	int recruitRoll = utility.randomint(1, 100)
	int iRecruitCount = 0
	int i = 0
	while(i < FirstSettlersRecruitmentChances.Length)
		if(recruitRoll <= FirstSettlersRecruitmentChances[i])
			iRecruitCount += 1
		endif
		
		i += 1
	endWhile
	
	; Create settlers
	i = 0
	while(i < iRecruitCount)
		CreateSettler(akWorkshopRef, akSpawnAtRef)
		
		i += 1
	endWhile
EndFunction


WorkshopNPCScript Function CreateSettler(WorkshopScript akWorkshopRef, ObjectReference akSpawnAtRef = None)
	ActorBase thisActorBase

	if(akWorkshopRef.CustomWorkshopNPC)
		; Allow for things like special settler mix in Far Harbor
		thisActorBase = akWorkshopRef.CustomWorkshopNPC
	else
		Float fRecruitmentGuardChance = akWorkshopRef.recruitmentGuardChance
		
		; roll for farmer vs. guard
		if(Utility.RandomInt(1, 100) <= fRecruitmentGuardChance)
			thisActorBase = SettlerGuardActorBase
		else
			thisActorBase = SettlerActorBase
		endif
	endif
		
	return CreateWorkshopNPC(thisActorBase, akWorkshopRef, akSpawnAtRef)
EndFunction


WorkshopNPCScript Function CreateBrahmin(WorkshopScript akWorkshopRef, ObjectReference akSpawnAtRef = None)
	return CreateWorkshopNPC(BrahminActorBase, akWorkshopRef, akSpawnAtRef)
EndFunction


WorkshopNPCScript Function CreateWorkshopNPC(ActorBase aActorForm, WorkshopScript akWorkshopRef, ObjectReference akSpawnAtRef = None)
	if( ! akWorkshopRef)
		return None
	endif
	
	ObjectReference kSpawnAtRef = akSpawnAtRef
	if( ! kSpawnAtRef)
		kSpawnAtRef = akWorkshopRef
	endif
	
	ObjectReference kCenterRef = akWorkshopRef.GetLinkedRef(WorkshopLinkSpawn)
	if(kCenterRef)
		kSpawnAtRef = kCenterRef
	endif
		
	Actor kActorRef = CreateNPC(aActorForm, kSpawnAtRef)
	WorkshopNPCScript asWorkshopNPC = kActorRef as WorkshopNPCScript
	
	if(kActorRef)
		if( ! asWorkshopNPC)
			kActorRef.Disable()
			kActorRef.Delete()
			return None
		endif
		
		If(aActorForm != BrahminActorBase)
			asWorkshopNPC.bNewSettler = true
			
			;check for synth
			Int iSynthPopulation = akWorkshopRef.GetBaseValue(SynthPopulation) as int
			Int iPopulation = akWorkshopRef.GetBaseValue(Population) as int
			Int iMaxSynths = akWorkshopRef.iBaseMaxSynths 
			Int iMinPopulationForSynths = WorkshopParent.recruitmentMinPopulationForSynth
			Int iRecruitSynthChance = akWorkshopRef.recruitmentSynthChance
			
			if(iSynthPopulation < iMaxSynths && iPopulation >= iMinPopulationForSynths)
				if(Utility.RandomInt(1, 100) <= iRecruitSynthChance)
					asWorkshopNPC.SetSynth(true)
				endif
			endif
		EndIf
		
		; Setup new actor to work with this settlement
		AddNewActorToWorkshop(asWorkshopNPC, akWorkshopRef)
		
		; try to automatically assign to do something:
		If(aActorForm != BrahminActorBase)
			WorkshopParent.TryToAutoAssignActor(akWorkshopRef, asWorkshopNPC)
		endif

		WorkshopNewSettlerAlias.ForceRefTo(asWorkshopNPC)
		
		return asWorkshopNPC
	endif
	
	return None
EndFunction


Actor Function CreateNPC(Form aActorForm, ObjectReference akSpawnAtRef, int aiLevelMod = 4, EncounterZone akZone = None)
	ActorBase asBase = aActorForm as ActorBase
	if( ! asBase)
		FormList asFormList = aActorForm as FormList
		
		if(asFormList)
			asBase = asFormList.GetAt(Utility.RandomInt(0, asFormList.GetSize() - 1)) as ActorBase
			
			if( ! asBase)
				return None
			endif
		endif
	endif
	
	return akSpawnAtRef.PlaceActorAtMe(asBase, aiLevelMod, akZone)
EndFunction


Function AddNewActorToWorkshop(WorkshopNPCScript akActorRef, WorkshopScript akWorkshopRef)
	; Based on WorkshopParent.AddActorToWorkshop
	int iNewWorkshopID = akWorkshopRef.GetWorkshopID()
	int iCurrentWorkshopID = WorkshopCurrentWorkshopID.GetValueInt()
	
	akActorRef.SetWorkshopID(iNewWorkshopID)

	if(akWorkshopRef.SettlementOwnershipFaction && akWorkshopRef.UseOwnershipFaction && akActorRef.bApplyWorkshopOwnerFaction)
		if(akActorRef.bCountsForPopulation)
			akActorRef.SetCrimeFaction(akWorkshopRef.SettlementOwnershipFaction)
		else
			akActorRef.SetFactionOwner(akWorkshopRef.SettlementOwnershipFaction)
		endif
	endif

	akActorRef.SetLinkedRef(akWorkshopRef, WorkshopItemKeyword)
	
	ObjectReference homeMarker = akWorkshopRef.GetLinkedRef(WorkshopLinkSandbox)
	if homeMarker == NONE
		homeMarker = akWorkshopRef.GetLinkedRef(WorkshopLinkCenter)
	endif
	
	akActorRef.SetLinkedRef(homeMarker, WorkshopLinkHome)
	
	ApplyAliasData(akActorRef)
	akActorRef.UpdatePlayerOwnership(akWorkshopRef)

	if(akActorRef.bCountsForPopulation)
		int iPopulation = akWorkshopRef.GetBaseValue(Population) as int
		float fCurrentHappiness = akWorkshopRef.GetValue(Happiness)
		
		if(iPopulation == 0)
			SetAndRestoreActorValue(akWorkshopRef, HappinessModifier, 0)
			SetAndRestoreActorValue(akWorkshopRef, LastAttackDaysSince, 99)
			WorkshopParent.ResetHappiness(akWorkshopRef)
		endif
		
		akActorRef.SetValue(UnassignedPopulation, 1.0)
		WorkshopParent.UpdateVendorFlagsAll(akWorkshopRef)
	endif

	akActorRef.SetPersistLoc(akWorkshopRef.myLocation)
	
	if(akActorRef.bIsSynth)
		akActorRef.SetLocRefType(akWorkshopRef.myLocation, WorkshopSynthRefType)
	elseif(akActorRef.bCountsForPopulation)
		akActorRef.SetAsBoss(akWorkshopRef.myLocation)
	endif
	
	akActorRef.ClearFromOldLocations()
	akActorRef.SetWorker(false)

	;If workshop is currently loaded, also save all new actors that are not robots in the UFO4P_ActorsWithoutBeds array. Otherwise, the new version of the TryToAssignBeds function won't find them.
	if(akActorRef.GetBaseValue(RobotPopulation) == 0 && iNewWorkshopID == iCurrentWorkshopID)
		WorkshopParent.UFO4P_ActorsWithoutBeds.Add(akActorRef)
	endif
	
	if(iNewWorkshopID == iCurrentWorkshopID)
		WorkshopParent.TryToAssignBeds(akWorkshopRef)
	endif

	akActorRef.EvaluatePackage()

	if( ! akWorkshopRef.RecalculateWorkshopResources())
		; Could not recalc workshop resources, manually adjust population
		ModifyActorValue(akWorkshopRef, Population, 1)
	endif	
endFunction


Function ApplyAliasData(Actor akActorRef)
	WorkshopAIAlias.ApplyToRef(akActorRef)
EndFunction