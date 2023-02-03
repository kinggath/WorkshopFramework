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

CustomEvent WorkshopNPCSpawned ; 1.1.1

; ---------------------------------------------
; Consts
; ---------------------------------------------

int iTimerID_Recruitment = 100 Const
int iDefaultRecruitmentGuardChance = 20 Const ; Copy of value defined in WorkshopScript

; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------

Group Controllers
	WorkshopFramework:MainThreadManager Property ThreadManager Auto Const Mandatory
	WorkshopParentScript Property WorkshopParent Auto Const Mandatory 
	Int Property iWorkshopParentInitializedStage = 20 Auto Const
	WorkshopFramework:WorkshopResourceManager Property ResourceManager Auto Const Mandatory
	WorkshopFramework:InjectionManager Property InjectionManager Auto Const Mandatory
	GlobalVariable Property WorkshopCurrentWorkshopID Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_RobotsCountTowardsMaxPopulation Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_RecruitSettlersOnFirstBeaconActivation Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_AutoAssign_Beds Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_AutoAssign_Defense Auto Const Mandatory
	GlobalVariable Property WSFW_Setting_AutoAssign_Food Auto Const Mandatory
EndGroup


Group Aliases
	ReferenceAlias Property WorkshopNewSettlerAlias Auto Const Mandatory
	{ Point to WorkshopNewSettler on WorkshopParent }
	ReferenceAlias Property WorkshopActorApply Auto Const Mandatory
	{ Point to alias with our AI package }
	RefCollectionAlias Property CaravanActorAliases Auto Const Mandatory
	{ Linked to WorkshopParent alias of same name }
	RefCollectionAlias Property CaravanActorRenameAliases Auto Const Mandatory
	{ Linked to WorkshopParent alias of same name }
	RefCollectionAlias Property CaravanBrahminAliases Auto Const Mandatory
	{ Linked to WorkshopParent alias of same name }
EndGroup


Group ActorValues
	ActorValue Property WorkshopRadioRating Auto Const Mandatory
	ActorValue Property Population Auto Const Mandatory
	ActorValue Property RobotPopulation Auto Const Mandatory
	ActorValue Property BrahminPopulation Auto Const Mandatory
	ActorValue Property UnassignedPopulation Auto Const Mandatory
	ActorValue Property PopulationDamage Auto Const Mandatory
	ActorValue Property SynthPopulation Auto Const Mandatory
	ActorValue Property Happiness Auto Const Mandatory
	{ Actual happiness, not bonus }
	ActorValue Property HappinessModifier Auto Const Mandatory
	ActorValue Property HappinessTarget Auto Const Mandatory
	ActorValue Property LastAttackDaysSince Auto Const Mandatory
	ActorValue Property WorkshopGuardPreference Auto Const Mandatory
	ActorValue Property BedAV Auto Const Mandatory
	ActorValue Property FoodAV Auto Const Mandatory
	ActorValue Property SafetyAV Auto Const Mandatory
	ActorValue Property ScavengeAV Auto Const Mandatory
	ActorValue Property WorkshopProhibitRename Auto Const Mandatory
	ActorValue Property CaravanDestinationIDAV Auto Const Mandatory
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
	Keyword Property WorkshopWorkObject Auto Const Mandatory
	Keyword Property WorkshopCaravanKeyword Auto Const Mandatory
	
	Keyword Property WorkshopAssignCaravan Auto Const Mandatory
	Keyword Property WorkshopAssignHome Auto Const Mandatory
	Keyword Property WorkshopAssignHomePermanentActor Auto Const Mandatory
	
	LocationRefType Property WorkshopSynthRefType Auto Const Mandatory
	LocationRefType Property WorkshopCaravanRefType Auto Const Mandatory
EndGroup


Group Assets
	ActorBase Property BrahminActorBase Auto Const Mandatory
	{ Actorbase that should be using InjectionManager.BrahminLCharHolder as its template source }
	ActorBase Property SettlerActorBase Auto Const Mandatory
	{ Actorbase that should be using InjectionManager.SettlerLCharHolder as its template source }
	ActorBase Property SettlerGuardActorBase Auto Const Mandatory
	{ Actorbase that should be using InjectionManager.SettlerLCharHolder as its template source }
	Faction Property WorkshopEnemyFaction Auto Const Mandatory
	Form Property SynthDeathItem Auto Const Mandatory
EndGroup

Group Settings
	Float[] Property DefaultFirstSettlersRecruitmentChances Auto Const
	{ Each entry represents the percent chance of getting that settler when a beacon is first built in a settlement. For example, if the first number is 100, you will guarantee that settler. If the next number is 30, you'd have a 30% chance of getting a second settler, etc. }
EndGroup



; 1.0.1 While we sort out adjustments to the framework for specific mod compatibility, we're going to implement some temporary overrides
Group TemporaryFixes
	ActorBase Property DefaultSettlerRecord Auto Const Mandatory
	ActorBase Property DefaultSettlerGuardRecord Auto Const Mandatory
	String[] Property sForceOverrideInjectedSettlerPlugins Auto Const
EndGroup

; 1.0.1 - Temporary fix until we can alter the framework to handle what this mod is doing
Bool Property bOverrideInjectedSettlers = false Auto Hidden


; ---------------------------------------------
; Properties
; ---------------------------------------------

Float Property fTimerLength_Recruitment = 24.0 Auto Hidden
Float fLastTimerStart_Recruitment = 0.0 ; Will record when this timer starts so we can restart it if it is lost due to save file issues
Float[] Property FirstSettlersRecruitmentChances Auto Hidden

; ---------------------------------------------
; Vars
; ---------------------------------------------

Bool bRecruitmentUnderwayBlock ; Unlike a lock, with the block we will just reject any incoming calls if a block is held

; ---------------------------------------------
; Events 
; ---------------------------------------------

Event OnTimerGameTime(Int aiTimerID)
	if(aiTimerID == iTimerID_Recruitment)
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
	
	RegisterForEvents()
	
	; Configure Initial Settler Chances
	FirstSettlersRecruitmentChances = new Float[0]
	int i = 0
	while(i < DefaultFirstSettlersRecruitmentChances.Length)
		FirstSettlersRecruitmentChances.Add(DefaultFirstSettlersRecruitmentChances[i])
		
		i += 1
	endWhile
	
	; Start Recruitment Loop
	if(WorkshopParent.GetStageDone(iWorkshopParentInitializedStage))
		StartRecruitmentTimer()
	else
		RegisterForRemoteEvent(WorkshopParent, "OnStageSet")
	endif
EndFunction


Function HandleGameLoaded()
	RegisterForEvents()
	
	Parent.HandleGameLoaded()
	
	int i = 0
	bOverrideInjectedSettlers = false
	while(i < sForceOverrideInjectedSettlerPlugins.Length && ! bOverrideInjectedSettlers)
		if(Game.IsPluginInstalled(sForceOverrideInjectedSettlerPlugins[i]))
			bOverrideInjectedSettlers = true
		endif
		
		i += 1
	endWhile
	
	Float fCurrentGameTime = Utility.GetCurrentGameTime()
	
	; Has recruitment timer failed to restart?
	if(fLastTimerStart_Recruitment < fCurrentGameTime - (fTimerLength_Recruitment/24.0))
		StartRecruitmentTimer()
	endif
EndFunction

Function HandleInstallModChanges()
	int iVersion2010 = 38
	
	if(iInstalledVersion < iVersion2010)
		; Reapply script alias - previously we had our priority too low, and it made it so the PermanentActorAliases AI package was taking precendence. In testing, discovered that a reapplication of the packages is necessary to reclaim precendence after fixing the priority.
		
		RefCollectionAlias PermanentActorAliases = WorkshopParent.PermanentActorAliases
		
		int i = 0
		while(i < PermanentActorAliases.GetCount())
			Actor thisActor = PermanentActorAliases.GetAt(i) as Actor
			
			if(thisActor != None)
				RemoveAliasData(thisActor)
				Utility.Wait(0.1)
				ApplyAliasData(thisActor)
			endif
			
			i += 1
		endWhile
	endif
EndFunction

; ---------------------------------------------
; Overrides
; ---------------------------------------------


; ---------------------------------------------
; Functions
; ---------------------------------------------

Function RegisterForEvents() 
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
EndFunction


Function StartRecruitmentTimer()
	fLastTimerStart_Recruitment = Utility.GetCurrentGameTime()
	StartTimerGameTime(fTimerLength_Recruitment, iTimerID_Recruitment)
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
	
	ModTrace("[WSFW NPCManager]: Daily recruitment - START")
	
	Float fStartTime = Utility.GetCurrentRealtime()
	
	int i = 0
	WorkshopScript[] AllWorkshops = ResourceManager.Workshops
	
	while(i < AllWorkshops.Length)
		WorkshopScript kWorkshopRef = AllWorkshops[i]
		
		RecruitWorkshopNPCs(kWorkshopRef)
		
		i += 1
	endWhile
	
	Debug.Trace("WSFW: NPC recruitment for " + AllWorkshops.Length + " workshops took " + (Utility.GetCurrentRealtime() - fStartTime) + " seconds.")
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
	
	ModTrace("[WSFW NPCManager]: Daily recruitment check for settlement " + akWorkshopRef)
	
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
	
	if(iRadioRating <= 0)
		ModTrace("[WSFW NPCManager]: " + akWorkshopRef + " lacks a recruitment beacon.")
	endif
	
	if(akWorkshopRef.HasKeyword(WorkshopType02))
		ModTrace("[WSFW NPCManager]: " + akWorkshopRef + " is a raider settlement.")
	endif
	
	if(iUnassignedPopulation > iMaxSurplusNPCs)
		ModTrace("[WSFW NPCManager]: " + akWorkshopRef + " has " + iUnassignedPopulation + " unassigned settlers, which is over the max unassigned settlers allows (which is " + iMaxSurplusNPCs + ").")
	endif
	
	if(iCheckPopulation >= iMaxWorkshopNPCs)
		ModTrace("[WSFW NPCManager]: " + akWorkshopRef + " has " + iCheckPopulation + " settlers, which is at or over the max settlers allowed (which is " + iMaxWorkshopNPCs + ").")
	endif
	
	if(iRadioRating > 0 && akWorkshopRef.HasKeyword(WorkshopType02) == false && iUnassignedPopulation < iMaxSurplusNPCs && iCheckPopulation < iMaxWorkshopNPCs)
		
		float fAttractChance = fDailyChance + fCurrentHappiness/100 * fAttractNPCHappinessMult
		
		if(iCheckPopulation < iMaxBonusAttractChancePopulation)
			fAttractChance += (iMaxBonusAttractChancePopulation - iCheckPopulation) * fDailyChance
		endif
		
		; roll to see if a new NPC arrives
		float fDieRoll = utility.RandomFloat()
		
		if(fDieRoll <= fAttractChance)
			ModTrace("[WSFW NPCManager]: " + akWorkshopRef + " won the die roll, creating settler...")
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
		else
			ModTrace("[WSFW NPCManager]: " + akWorkshopRef + " rolled a " + (fDieRoll*100) + " versus a chance of " + (fAttractChance*100) + ".")
		endif
	endif
EndFunction


Function CreateInitialSettlers(WorkshopScript akWorkshopRef, ObjectReference akSpawnAtRef = None)
	if( ! akWorkshopRef || WSFW_Setting_RecruitSettlersOnFirstBeaconActivation.GetValue() == 0)
		ModTrace("[WSFW NPCManager]: Skipping creating of initial settlers because either the workshop ref is missing, or initial recruitment is disable.")
		
		return
	endif
	
	int recruitRoll = utility.randomint(1, 100)
	ModTrace("[WSFW NPCManager]: Recruit chances: " + FirstSettlersRecruitmentChances + ", Recruit Roll: " + recruitRoll)
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
	ActorBase thisActorBase = GetSettlerForm(akWorkshopRef)
		
	return CreateWorkshopNPC(thisActorBase, akWorkshopRef, akSpawnAtRef)
EndFunction


ActorBase Function GetSettlerForm(WorkshopScript akWorkshopRef = None)
	; 1.1.11 - Separated to a new function so we can call it externally
	ActorBase thisActorBase
	
	if(akWorkshopRef != None)
		; 1.1.0 - Allow faction control to override settlers
		FactionControl thisFactionControl = akWorkshopRef.FactionControlData
		if(thisFactionControl != None && thisFactionControl.SettlerOverride != None)
			thisActorBase = thisFactionControl.SettlerOverride
		endif
	endif
	
	if(thisActorBase == None)
		if(akWorkshopRef && akWorkshopRef.CustomWorkshopNPC)
			; Allow for things like special settler mix in Far Harbor
			thisActorBase = akWorkshopRef.CustomWorkshopNPC
		else
			Int iRecruitmentGuardChance = iDefaultRecruitmentGuardChance
			if(akWorkshopRef)
				iRecruitmentGuardChance = akWorkshopRef.recruitmentGuardChance
			endif
			
			; roll for farmer vs. guard
			if(Utility.RandomInt(1, 100) <= iRecruitmentGuardChance)
				thisActorBase = SettlerGuardActorBase
				
				if(bOverrideInjectedSettlers || ! InjectionManager.bInitialSetupComplete)
					thisActorBase = DefaultSettlerGuardRecord
				endif
			else
				thisActorBase = SettlerActorBase
				
				if(bOverrideInjectedSettlers || ! InjectionManager.bInitialSetupComplete)
					thisActorBase = DefaultSettlerRecord
				endif
			endif
		endif
	endif
	
	return thisActorBase
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
			WorkshopParent.TryToAutoAssignNPC(akWorkshopRef, asWorkshopNPC)
		endif

		WorkshopNewSettlerAlias.ForceRefTo(asWorkshopNPC)
		
		; 1.1.1 - Add event when a new settler is spawned and added to workshop
		Var[] kArgs = new Var[2]		
		kArgs[0] = asWorkshopNPC
		kArgs[1] = akWorkshopRef		
		SendCustomEvent("WorkshopNPCSpawned", kArgs)
		
		return asWorkshopNPC
	endif
	
	return None
EndFunction


Actor Function CreateNPC(Form aActorForm, ObjectReference akSpawnAtRef, int aiLevelMod = 4, EncounterZone akZone = None)
	if( ! akSpawnAtRef)
		return None
	endif
	
	if(akSpawnAtRef as WorkshopScript)
		ObjectReference kCenterRef = akSpawnAtRef.GetLinkedRef(WorkshopLinkSpawn)
		if(kCenterRef)
			akSpawnAtRef = kCenterRef
		endif
	endif
	
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

	;If workshop is currently loaded, also save all new actors that are not robots in the UFO4P_ActorsWithoutBeds array. Otherwise, the new version of TryToAssignBeds won't find them.
	if(akActorRef.GetBaseValue(RobotPopulation) == 0 && iNewWorkshopID == iCurrentWorkshopID)
		WorkshopParent.WSFW_AddToActorsWithoutBedsArray(akActorRef)
	endif
	
	if(iNewWorkshopID == iCurrentWorkshopID && (WSFW_Setting_AutoAssign_Beds.GetValueInt() == 1 || ! akWorkshopRef.OwnedByPlayer))
		WorkshopParent.TryToAssignBeds(akWorkshopRef)
	endif

	akActorRef.EvaluatePackage()

	if( ! akWorkshopRef.RecalculateWorkshopResources() && akActorRef.bCountsForPopulation)
		; Could not recalc workshop resources, manually adjust population
		ModifyActorValue(akWorkshopRef, Population, 1)
	endif	
	
	; Send WorkshopParent event for actor being added
	Var[] kargs = new Var[0]
	kargs.Add(akActorRef)
	kargs.Add(iNewWorkshopID)
	kArgs.Add(-1)
	WorkshopParent.SendCustomEvent("WorkshopAddActor", kargs)
endFunction


Function ApplyAliasData(Actor akActorRef)
	WorkshopActorApply.ApplyToRef(akActorRef)
EndFunction

Function RemoveAliasData(Actor akActorRef)
	WorkshopActorApply.RemoveFromRef(akActorRef)
EndFunction

; Alternative to WorkshopParent.AddActorToWorkshop that does not require the WorkshopNPCScript
Function AddNPCToWorkshop(Actor akActorRef, WorkshopScript akWorkshopRef, Bool abResetMode = false)
	ModTrace("AddNPCToWorkshop called on " + akActorRef + " targeting settlement " + akWorkshopRef)
	int iLockKey = GetLock()
		
	if(iLockKey <= GENERICLOCK_KEY_NONE)
		ModTrace("NPCManager.AddNPCToWorkshop: Unable to get lock!", 2)
		
		return
	endif
	
	Location WorkshopLocation = akWorkshopRef.myLocation
	
	bool bResetHappiness = false
	bool bAutoAssignBeds = (WSFW_Setting_AutoAssign_Beds.GetValueInt() == 1) as Bool
	if( ! akWorkshopRef.OwnedByPlayer)
		bAutoAssignBeds = true
	endif
	
	int iCurrentWorkshopID = WorkshopCurrentWorkshopID.GetValueInt()
	int iNewWorkshopID = akWorkshopRef.GetWorkshopID()
	
	WorkshopScript oldWorkshopRef = akActorRef.GetLinkedRef(WorkshopItemKeyword) as WorkshopScript
	int iOldWorkshopID = -1
	if(oldWorkshopRef)
		iOldWorkshopID = oldWorkshopRef.GetWorkshopID()
	endIf	
	
	if(iOldWorkshopID > -1 && iOldWorkshopID != iNewWorkshopID)
		RemoveNPCFromWorkshop(akActorRef, akWorkshopRef, abNPCTransfer = true)
		
		SetNewSettler(akActorRef, false)
	endif

	SetWorkshopID(akActorRef, iNewWorkshopID)
	
	Bool bCountsForPopulation = CountsForPopulation(akActorRef)
	Faction SettlementOwnershipFaction = akWorkshopRef.SettlementOwnershipFaction
	
	if(SettlementOwnershipFaction && akWorkshopRef.UseOwnershipFaction && ApplyWorkshopOwnerFaction(akActorRef))
		if(bCountsForPopulation)
			akActorRef.SetCrimeFaction(SettlementOwnershipFaction)
		else
			akActorRef.SetFactionOwner(SettlementOwnershipFaction)
		endif
	endif
	
	if(iOldWorkshopID < 0)
		; Only apply if a new settler, this will allow for mods to have removed this set of packages if they wanted to create alternate AI sets
		ApplyAliasData(akActorRef)	
	endif
	
	akActorRef.SetLinkedRef(akWorkshopRef, WorkshopItemKeyword)
	AssignHomeMarkerToActor(akActorRef, akWorkshopRef)
	UpdatePlayerOwnership(akActorRef, akWorkshopRef)

	; Recalc workshop ratings on old workshop (if there is one) now that actor is linked to new workshop
	if(oldWorkshopRef)
		oldWorkshopRef.RecalculateWorkshopResources()
	endif

	if(bCountsForPopulation)
		int iTotalPopulation = akWorkshopRef.GetBaseValue(Population) as int
		float currentHappiness = akWorkshopRef.GetValue(Happiness)
		
		if(iTotalPopulation == 0)
			if(abResetMode)
				SetResourceData(Happiness, akWorkshopRef, 50.0)
				SetResourceData(HappinessTarget, akWorkshopRef, 50.0)
			else
				bResetHappiness = true
			endif
			
			SetResourceData(LastAttackDaysSince, akWorkshopRef, 99.0)
		endif
		
		akActorRef.SetValue(UnassignedPopulation, 1)
		UpdateVendorFlagsAll(akWorkshopRef)
	endif

	Bool bIsCreated = akActorRef.IsCreated()
	
	if(bIsCreated)
		akActorRef.SetPersistLoc(WorkshopLocation)
		
		if(IsSynth(akActorRef))
			akActorRef.SetLocRefType(WorkshopLocation, WorkshopSynthRefType)
		elseif(bCountsForPopulation)
			SetAsBoss(akActorRef, WorkshopLocation)			
		endif
		
		akActorRef.ClearFromOldLocations() ; make sure location data is correct
	else
		WorkshopParent.PermanentActorAliases.AddRef(akActorRef)
	endif

	if(akWorkshopRef.PlayerHasVisited)
		SetWorker(akActorRef, false)
	endif

	;If workshop is currently loaded, also save all new actors that are not robots in the UFO4P_ActorsWithoutBeds array.
	if(akActorRef.GetBaseValue(RobotPopulation) == 0 && iNewWorkshopID == iCurrentWorkshopID)
		WorkshopParent.WSFW_AddToActorsWithoutBedsArray(akActorRef)
	endif

	if(abResetMode)
		SetMultiResourceProduction(akActorRef, 0.0)
		
		ActorValue multiResourceValue = GetAssignedMultiResource(akActorRef)
		
		if(multiResourceValue)
			WorkshopParent.WSFW_AddActorToWorkerArray(akActorRef, GetMultiResourceIndex(multiResourceValue))
		endif
	endif

	; Even if not in reset mode, this should not run if the workshop is not loaded:
	if( ! abResetMode && akActorRef && iNewWorkshopID == iCurrentWorkshopID && bAutoAssignBeds)
		WorkshopParent.TryToAssignBeds(akWorkshopRef)
	endif

	akActorRef.EvaluatePackage()

	if( ! akWorkshopRef.RecalculateWorkshopResources())
		if(bCountsForPopulation)
			ModifyResourceData(Population, akWorkshopRef, 1)
		endif
	endif

	if( ! abResetMode && bResetHappiness)
		WorkshopParent.ResetHappinessPUBLIC(akWorkshopRef)
	endif	
	
	; Send WorkshopParent event for actor being added
	Var[] kargs = new Var[0]
	kargs.Add(akActorRef)
	kargs.Add(iNewWorkshopID)
	kargs.Add(iOldWorkshopID)
	WorkshopParent.SendCustomEvent("WorkshopAddActor", kargs)
	
	if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
		ModTrace("NPCManager.AddNPCToWorkshop: Failed to release lock " + iLockKey + "!", 2)
	endif
endFunction


; Alternative to WorkshopParent.RemoveActorFromWorkshopPUBLIC that does not require the WorkshopNPCScript
Function RemoveNPCFromWorkshop(Actor akActorRef, WorkshopScript akWorkshopRef = None, Bool abNPCTransfer = false)
	if(akWorkshopRef == None)
		akWorkshopRef = akActorRef.GetLinkedRef(WorkshopItemKeyword) as WorkshopScript
		
		if(akWorkshopRef == None)
			return
		endif
	endif
	
	
	int iLockKey = GetLock()
		
	if(iLockKey <= GENERICLOCK_KEY_NONE)
		ModTrace("NPCManager.RemoveNPCFromWorkshop: Unable to get lock!", 2)
		
		return
	endif
	
	UnassignNPC(akActorRef, abSendUnassignEvent = true, abResetMode = false, abNPCTransfer = abNPCTransfer, abRemovingFromWorkshop = true, akWorkshopRef = akWorkshopRef, abGetLock = false)
	
	akActorRef.SetLinkedRef(None, WorkshopItemKeyword)
	akActorRef.SetLinkedRef(None, WorkshopLinkHome)
	
	if( ! abNPCTransfer)
		; Completely removed from workshop system
		if(akWorkshopRef.SettlementOwnershipFaction && akWorkshopRef.UseOwnershipFaction)
			akActorRef.SetCrimeFaction(None)
			akActorRef.SetFactionOwner(None)
		endif
		
		WorkshopParent.WorkshopActorApply.RemoveFromRef(akActorRef)
		WorkshopParent.PermanentActorAliases.RemoveRef(akActorRef)
		RemoveAliasData(akActorRef)
		akActorRef.SetValue(GetWorkshopPlayerOwnedAV(), 0)
	else
		; 2.0.7 - Fixing a bug where some NPCs, such as dogs, who's workshop package have a Wander flag, will get stuck wandering in their original location forever after being transferred
		RemoveAliasData(akActorRef)
		akActorRef.EvaluatePackage()
		ApplyAliasData(akActorRef)
		akActorRef.EvaluatePackage()
	endif

	SetWorkshopID(akActorRef, -1)

	; update population rating on workshop's location
	if(akWorkshopRef.RecalculateWorkshopResources() == false)
		if(CountsForPopulation(akActorRef))
			ModifyResourceData(GetPopulationAV(), akWorkshopRef, -1.0)
		elseif(akActorRef.GetActorBase() == GetWorkshopBrahminForm())
			; This is unintuitively increasing the brahmin AV. This is to prevent an issue where the value gets set to 0 by recalculateWorkshopResources which results in the player receiving a brahmin with every new "farmer" settler until they return to the settlement
			ModifyResourceData(GetWorkshopBrahminAV(), akWorkshopRef, 1.0)
		endif
	endif	

	; WSFW New Event
	Var[] kArgs = new Var[0]
	kArgs.Add(akActorRef)
	kArgs.Add(akWorkshopRef)
	WorkshopParent.SendCustomEvent("WorkshopRemoveActor", kArgs)
	
	; Trigger autoassignment to redistribute those owned objects
	Bool bOwnedByPlayer = akWorkshopRef.OwnedByPlayer
		
	if(WSFW_Setting_AutoAssign_Food.GetValueInt() == 1 || ! bOwnedByPlayer)
		WorkshopParent.TryToAssignResourceType(akWorkshopRef, GetFoodAV())
	endif
		
	if(WSFW_Setting_AutoAssign_Defense.GetValueInt() == 1 || ! bOwnedByPlayer)
		WorkshopParent.TryToAssignResourceType(akWorkshopRef, GetSafetyAV())
	endif
	
	;If actor was removed from workshop, there may be an unassigned bed now:
	if(WSFW_Setting_AutoAssign_Beds.GetValueInt() == 1 || ! bOwnedByPlayer)
		WorkshopParent.TryToAssignBeds(akWorkshopRef)
	endif
	
	if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
		ModTrace("NPCManager.RemoveNPCFromWorkshop: Failed to release lock " + iLockKey + "!", 2)
	endif
EndFunction

; Alternative to WorkshopParent.AssignActorToObject that does not require the WorkshopNPCScript
;
;/
 Note: Two parts of the functionality are broken off into their own functions so they can be called independently. They are called automatically from this function unless abAutoHandleNPCAssignmentRules or abAutoUpdateWorkshopNPCStatus are set to false to prevent the corresponding calls to HandleNPCAssignmentRules and UpdateWorkshopNPCStatus, respectively
/;
;
Function AssignNPCToObject(WorkshopObjectScript akWorkshopObject, Actor akNewActor = None, Bool abAutoHandleNPCAssignmentRules = true, Bool abAutoUpdateWorkshopNPCStatus = true, Bool abRecalculateWorkshopResources = true, Bool abGetLock = false)
 
	ModTrace("NPCManager.AssignNPCToObject(" + akWorkshopObject + ", " + akNewActor + ", abAutoHandleNPCAssignmentRules = " + abAutoHandleNPCAssignmentRules + ", abAutoUpdateWorkshopNPCStatus = " + abAutoUpdateWorkshopNPCStatus + ", abRecalculateWorkshopResources = " + abRecalculateWorkshopResources + ", abGetLock = " + abGetLock + ")")
	if( ! akWorkshopObject)
		return
	endif
	
	int iLockKey 
	
	if(abGetLock)
		iLockKey = GetLock()
		
		if(iLockKey <= GENERICLOCK_KEY_NONE)
			ModTrace("NPCManager.AssignNPCToObject: Unable to get lock!", 2)
			
			return
		endif
	endif
	
	WorkshopScript thisWorkshop = akWorkshopObject.GetLinkedRef(WorkshopItemKeyword) as WorkshopScript
	
	Actor kCurrentOwner = akWorkshopObject.GetActorRefOwner()
	bool bAssignmentChanged = (kCurrentOwner != akNewActor)
	
	if(akNewActor)
		if(abAutoHandleNPCAssignmentRules)
			; Trigger appropriate unassignment for current and previous owner
			HandleNPCAssignmentRules(akNewActor, akWorkshopObject, kCurrentOwner, abGetLock = false)
		endif
			
		Bool bIsBed = akWorkshopObject.IsBed()
		; Don't assign robots to beds
		if( ! bIsBed || akNewActor.GetBaseValue(GetRobotPopulationAV()) <= 0)
			WorkshopNPCScript asWorkshopNPC = akNewActor as WorkshopNPCScript
			
			; Let workshopObject handle most code - this allows to have item level overrides
			if(asWorkshopNPC) ; 2.0.4 - We need to call AssignActor or any workshop object overriding it won't be called
				ModTrace("NPCManager.AssignNPCToObject calling AssignActor on " + akWorkshopObject)
				akWorkshopObject.AssignActor(asWorkshopNPC)
			else
				ModTrace("NPCManager.AssignNPCToObject calling AssignNPC on " + akWorkshopObject)
				akWorkshopObject.AssignNPC(akNewActor)
			endif
			
			if(abAutoUpdateWorkshopNPCStatus)
				UpdateWorkshopNPCStatus(akNewActor, akWorkshopRef = thisWorkshop, abGetLock = false)
			endif
		endif
	else
		; Let workshopObject handle most code - this allows to have item level overrides
		akWorkshopObject.AssignNPC(None)
	endif
	
	UpdateWorkshopRatingsForResourceObject(akWorkshopObject, thisWorkshop, bRecalculateResources = bAssignmentChanged && abRecalculateWorkshopResources)
	
	WorkshopParent.SendWorkshopActorAssignedToWorkEvent(akNewActor, akWorkshopObject, thisWorkshop)
	
	if(abGetLock)
		if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
			ModTrace("NPCManager.AssignNPCToObject: Failed to release lock " + iLockKey + "!", 2)
		endif
	endif
EndFunction

Function UpdateWorkshopNPCStatus(Actor akActorRef, WorkshopScript akWorkshopRef = None, Bool abHandleMultiResourceAssignment = true, Bool abGetLock = false)
	if( ! akActorRef)
		return
	endif
	
	if( ! akWorkshopRef)
		akWorkshopRef = akActorRef.GetLinkedRef(WorkshopItemKeyword) as WorkshopScript
		
		if( ! akWorkshopRef)
			return
		endif
	endif
	
	int iLockKey
	
	if(abGetLock)
		iLockKey = GetLock()
		
		if(iLockKey <= GENERICLOCK_KEY_NONE)
			ModTrace("NPCManager.UpdateWorkshopNPCStatus: Unable to get lock!", 2)
			
			return
		endif
	endif
	
	int iWorkshopID = akWorkshopRef.GetWorkshopID()
	int iCurrentWorkshopID = GetCurrentWorkshopIDGlobal().GetValueInt()
	
	; Check for work objects
	ObjectReference[] ResourceObjects = akWorkshopRef.GetWorkshopOwnedObjects(akActorRef)
	
	Bool bMultiResourceFound = false
	Bool bScavengerFound = false
	Bool bWork24HoursFound = false
	Bool bWorkObjectFound = false
	
	if(ResourceObjects.Length == 0)
		akActorRef.SetValue(UnassignedPopulation, 1)
		SetAssignedMultiResource(akActorRef, None)
		SetMultiResourceProduction(akActorRef, 0)
		SetWorker(akActorRef, false)
		SetWork24Hours(akActorRef, false)
		SetScavenger(akActorRef, false)		
		WorkshopParent.WSFW_RemoveActorFromWorkerArray(akActorRef) ; WSFW 2.0.7 - ensure they are no longer queued up to be auto-assigned to additional multiresources until they are once again assigned to something
	else
		SetNewSettler(akActorRef, false)
		
		ActorValue SettlerMultiResource = None
		Float fResourceTotal = 0.0
		int i = 0
		while(i < ResourceObjects.Length)
			WorkshopObjectScript asWorkshopObject = ResourceObjects[i] as WorkshopObjectScript
			
			if(asWorkshopObject)
				if( ! asWorkshopObject.IsBed())
					bWorkObjectFound = true
					
					SetWorker(akActorRef, true)
					
					if(asWorkshopObject.bWork24Hours)
						SetWork24Hours(akActorRef, true)
						bWork24HoursFound = true
					endif
					
					ActorValue thisMultiResourceAV = asWorkshopObject.GetMultiResourceValue()
					if(thisMultiResourceAV)
						;ModTrace("NPCManager.UpdateWorkshopNPCStatus found actor is assigned to " + thisMultiResourceAV + ", setting as AssignedMultiResource.")
						SetAssignedMultiResource(akActorRef, thisMultiResourceAV)
						SettlerMultiResource = thisMultiResourceAV
						fResourceTotal += asWorkshopObject.GetBaseValue(thisMultiResourceAV)
						
						bMultiResourceFound = true
					endif
					
					if(asWorkshopObject.HasResourceValue(ScavengeAV))
						SetScavenger(akActorRef, true)
						bScavengerFound = true
					endif
					
					if(akWorkshopRef && (asWorkshopObject.VendorType >= 0 || asWorkshopObject.sCustomVendorID != ""))
						SetVendorData(akWorkshopRef, akActorRef, asWorkshopObject)		
					endif
				endif
			endif
			
			i += 1
		endWhile
		
		; Update all properties and AVs based on results of checking all
		if(bWorkObjectFound)			
			akActorRef.SetValue(UnassignedPopulation, 0)
		else
			SetWorker(akActorRef, false)
			akActorRef.SetValue(UnassignedPopulation, 1)
		endif
		
		if( ! bMultiResourceFound)
			SetAssignedMultiResource(akActorRef, None)
			SetMultiResourceProduction(akActorRef, 0.0)
		elseif(abHandleMultiResourceAssignment && iWorkshopID == iCurrentWorkshopID)
			Bool bShouldTryToAssignResources = false			
			SetMultiResourceProduction(akActorRef, fResourceTotal)
			
			int iResourceIndex = GetMultiResourceIndex(SettlerMultiResource)
			if(fResourceTotal >= GetMaxProductionPerNPC(iResourceIndex))
				WorkshopParent.WSFW_RemoveActorFromWorkerArray(akActorRef)
			elseif(iResourceIndex >= 0)
				;ModTrace("NPCManager.UpdateWorkshopNPCStatus adding actor " + akActorRef + " to worker array for resource index " + iResourceIndex)
				WorkshopParent.WSFW_AddActorToWorkerArray(akActorRef, iResourceIndex)
				
				bShouldTryToAssignResources = true
			endif
			
			if(bShouldTryToAssignResources)
				; Trigger resource type assignment so NPC will be bulk assigned to other resources of the same type
				WorkshopParent.TryToAssignResourceType(akWorkshopRef, FoodAV)
				WorkshopParent.TryToAssignResourceType(akWorkshopRef, SafetyAV)
			endif
		endif
		
		if( ! bScavengerFound)
			SetScavenger(akActorRef, false)
		endif
		
		if( ! bWork24HoursFound)
			SetWork24Hours(akActorRef, false)
		endif
	endif	
			
	if(akWorkshopRef)
		SetUnassignedPopulationRating(akWorkshopRef)
	endif
	
	if(abGetLock)
		if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
			ModTrace("NPCManager.UpdateWorkshopNPCStatus: Failed to release lock " + iLockKey + "!", 2)
		endif
	endif
EndFunction

function HandleNPCAssignmentRules(Actor akActorRef, WorkshopObjectScript akLastAssigned, Actor akCurrentOwner = None, bool abResetMode = false, bool abGetLock = false)
	int workshopID = akLastAssigned.workshopID
	if(workshopID < 0)
		return
	endIf
	
	int iLockKey
	
	if(abGetLock)
		iLockKey = GetLock()
		
		if(iLockKey <= GENERICLOCK_KEY_NONE)
			ModTrace("NPCManager.HandleNPCAssignmentRules: Unable to get lock!", 2)
			
			return
		endif
	endif
	
	WorkshopScript workshopRef = akActorRef.GetLinkedRef(WorkshopItemKeyword) as WorkshopScript
	
	Bool bExcludedFromAssignmentRules = IsExcludedFromAssignmentRules(akLastAssigned)
	Var[] kExcludedArgs = new Var[0]
	kExcludedArgs.Add(akLastAssigned)
	kExcludedArgs.Add(workshopRef)
	kExcludedArgs.Add(akActorRef)
	kExcludedArgs.Add(akLastAssigned)
	
	bool bAlreadyAssigned = (akCurrentOwner == akActorRef)

	if(akLastAssigned.IsBed())
		bool bIsRobot = (akActorRef.GetBaseValue(RobotPopulation) > 0)
	
		if(bAlreadyAssigned)
			if(bIsRobot)
				; WSFW Exclusion from assignment rules
				if(bExcludedFromAssignmentRules)
					WorkshopParent.SendCustomEvent("AssignmentRulesOverriden", kExcludedArgs)
				else
					akLastAssigned.AssignActor(None)
					WorkshopParent.UFO4P_AddUnassignedBedToArray(akLastAssigned)
				endif
			endif
		elseif( ! bIsRobot)
			ObjectReference[] WorkshopBeds = workshopRef.GetWorkshopResourceObjects(BedAV)

			int countBeds = WorkshopBeds.Length
			
			; Unassign this actor from other beds
			int i = 0
			while(i < countBeds)
				WorkshopObjectScript theBed = WorkshopBeds[i] as WorkshopObjectScript
				
				if(theBed && theBed.GetActorRefOwner() == akActorRef)
					if(IsExcludedFromAssignmentRules(theBed))
						Var[] kBedExcludedArgs = new Var[0]
						kBedExcludedArgs.Add(theBed)
						kBedExcludedArgs.Add(workshopRef)
						kBedExcludedArgs.Add(akActorRef)
						kBedExcludedArgs.Add(akLastAssigned) 
						
						WorkshopParent.SendCustomEvent("AssignmentRulesOverriden", kBedExcludedArgs)
					else
						theBed.AssignActor(None)
						WorkshopParent.UFO4P_AddUnassignedBedToArray(theBed)
					endif
				endif
				i += 1
			endWhile
			
			;If there was no previous owner, this bed must have been in the unassigned beds array, so it should be removed now.
			if(akCurrentOwner == none)
				WorkshopParent.UFO4P_RemoveFromUnassignedBedsArray(akLastAssigned)
			endif
		endif
	elseif(akLastAssigned.HasKeyword(WorkshopWorkObject))
		;ModTrace("NPCManager.HandleNPCAssignmentRules called. akActorRef = " + akActorRef + ", akLastAssigned = " + akLastAssigned + ", akCurrentOwner = " + akCurrentOwner + ", abResetMode = " + abResetMode + ", abGetLock = " + abGetLock)
		bool bShouldUnassignAllObjects = true
		bool bShouldUnassignSingleObject = false
		actorValue multiResourceValue = GetAssignedMultiResource(akActorRef)
		
		if(bAlreadyAssigned)
			bShouldUnassignAllObjects = false
		endif
	
		if(multiResourceValue)
			if(akLastAssigned.HasResourceValue(multiResourceValue))
				int iResourceIndex = GetMultiResourceIndex(multiResourceValue)
				float fMaxProduction = GetMaxProductionPerNPC(iResourceIndex)
				
				float currentProduction = GetMultiResourceProduction(akActorRef)
				float totalProduction = currentProduction
				
				if( ! abResetMode && bAlreadyAssigned && totalProduction <= fMaxProduction)
					bShouldUnassignAllObjects = false
				else					
					if(abResetMode || ! bAlreadyAssigned)
						totalProduction = totalProduction + akLastAssigned.GetBaseValue(multiResourceValue)
					endif

					if(totalProduction <= fMaxProduction)
						bShouldUnassignAllObjects = false
					elseif(bAlreadyAssigned)
						bShouldUnassignAllObjects = false
						bShouldUnassignSingleObject = true						
					endif
				endif
				
				;ModTrace("NPCManager.HandleNPCAssignmentRules " + akLastAssigned + " has multiResourceValue " + multiResourceValue + ", " + akActorRef + " is currently assigned to " + currentProduction + " worth. About to be assigned to " + totalProduction + " worth.")
			else
				;ModTrace("NPCManager.HandleNPCAssignmentRules " + akLastAssigned + " does not have multiResourceValue " + multiResourceValue + ", which is what " + akActorRef + " is currently assigned to - so we're going to unassign all of their work objects.")
				bShouldUnassignAllObjects = true
			endif
		else
			;ModTrace("NPCManager.HandleNPCAssignmentRules " + akActorRef + " is reported as having no multiResourceValue assignment.")
		endif

		; if bShouldUnassignSingleObject
		if(bShouldUnassignSingleObject)
			; WSFW Exclusion from assignment rules
			if(bExcludedFromAssignmentRules)
				WorkshopParent.SendCustomEvent("AssignmentRulesOverriden", kExcludedArgs)
			else
				UnassignNPCFromObject(akActorRef, akLastAssigned, abResetMode, akWorkshopRef = workshopRef)
			endif
		elseif(bShouldUnassignAllObjects && IsObjectOwner(workshopRef, akActorRef))
			;ModTrace("NPCManager.HandleNPCAssignmentRules unassigning " + akActorRef + " from all current assignments.")
			
			;ModTrace("NPCManager.HandleNPCAssignmentRules PRE-call to UnassignNPCSkipExclusions, outputting WorkshopParent worker arrays: Food = " + WorkshopParent.GetWSFW_FoodWorkers() + ", Safety = " + WorkshopParent.GetWSFW_SafetyWorkers())
			
			UnassignNPCSkipExclusions(akActorRef, workshopRef, akLastAssigned)
			
			;ModTrace("NPCManager.HandleNPCAssignmentRules POST-call to UnassignNPCSkipExclusions, outputting WorkshopParent worker arrays: Food = " + WorkshopParent.GetWSFW_FoodWorkers() + ", Safety = " + WorkshopParent.GetWSFW_SafetyWorkers())
		endif

		; unassign current owner, if any (and different from new owner)
		if(akCurrentOwner && akCurrentOwner != akActorRef)
			UnassignNPCFromObject(akCurrentOwner, akLastAssigned, abResetMode, akWorkshopRef = workshopRef)
		endif	
	endif
	
	
	if(abGetLock)
		if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
			ModTrace("NPCManager.HandleNPCAssignmentRules: Failed to release lock " + iLockKey + "!", 2)
		endif
	endif
endFunction

Function UnassignNPCFromObject(Actor akActorRef, WorkshopObjectScript akWorkshopObject, bool abSendUnassignEvent = true, bool abResetMode = false, WorkshopScript akWorkshopRef = None, bool abGetLock = false)
	int iLockKey
	
	if(akWorkshopObject.GetActorRefOwner() == akActorRef)
		if(abGetLock)
			iLockKey = GetLock()
			
			if(iLockKey <= GENERICLOCK_KEY_NONE)
				ModTrace("NPCManager.UnassignNPCFromObject: Unable to get lock!", 2)
				
				return
			endif
		endif
	
		;ModTrace("NPCManager.UnassignNPCFromObject: akActorRef = " + akActorRef + ", akWorkshopObject = " + akWorkshopObject + ", abSendUnassignEvent = " + abSendUnassignEvent + ", abResetMode = " + abResetMode + ", akWorkshopRef = " + akWorkshopRef + ", abGetLock = " + abGetLock)
		; Handle unassignment of object
		UnassignWorkshopObject(akWorkshopObject, abUnassigningMultipleResources = abResetMode, abGetLock = false)
		
		if(abSendUnassignEvent)
			if( ! akWorkshopRef)
				akWorkshopRef = akWorkshopObject.GetLinkedRef(WorkshopItemKeyword) as WorkshopScript
			endif
	
			if(akWorkshopRef)
				WorkshopParent.SendWorkshopActorUnassignedEvent(akWorkshopObject, akWorkshopRef, akActorRef)
			endif			
		endif
		
		if(abGetLock)
			if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
				ModTrace("NPCManager.UnassignNPCFromObject: Failed to release lock " + iLockKey + "!", 2)
			endif
		endif
	endif
endFunction

; UnassignNPC from all objects
Function UnassignNPC(Actor akActorRef, bool abSendUnassignEvent = true, bool abResetMode = false, bool abNPCTransfer = false, bool abRemovingFromWorkshop = false, WorkshopScript akWorkshopRef = None, bool abGetLock = false)
	if( ! akActorRef)
		return
	endif
	
	if( ! akWorkshopRef)
		akWorkshopRef = akActorRef.GetLinkedRef(WorkshopItemKeyword) as WorkshopScript
		
		if( ! akWorkshopRef)
			return
		endif
	endif
	
	int iLockKey
	
	if(abGetLock)
		iLockKey = GetLock()
		
		if(iLockKey <= GENERICLOCK_KEY_NONE)
			ModTrace("NPCManager.UnassignNPC: Unable to get lock!", 2)
			
			return
		endif
	endif
	
	int iCaravanActorIndex = CaravanActorAliases.Find(akActorRef)
	if(iCaravanActorIndex >= 0)
		UnassignNPCFromCaravan(akActorRef, akWorkshopRef, abRemovingFromWorkshop, abGetLock = false)
	endif
	
	bool bShouldTryToAssignResources = false
	bool bSendCollectiveEvent = false
	
	Bool bWorkshopLoaded = akWorkshopRef.Is3dLoaded()
	if(bWorkshopLoaded == false)
		WorkshopParent.UFO4P_RegisterUnassignedActor(akActorRef)
		
		;Also set a tracking bool on the actor's workshop:
		akWorkshopRef.UFO4P_HandleUnassignedActors = true
	endif

	ObjectReference[] ResourceObjects = akWorkshopRef.GetWorkshopOwnedObjects(akActorRef)
	int iCountResourceObjects = ResourceObjects.Length
	int i = 0
	while(i < iCountResourceObjects)
		ObjectReference objectRef = ResourceObjects[i]
		WorkshopObjectScript thisWorkshopObject = objectRef as WorkshopObjectScript
		
		if(thisWorkshopObject != none)
			if(thisWorkshopObject.HasKeyword(WorkshopWorkObject))
				bool bIsBed = thisWorkshopObject.IsBed()
				
				;don't remove the bed if the actor is not removed from the workshop:
				if(bIsBed == false || abRemovingFromWorkshop)
					UnassignWorkshopObject(thisWorkshopObject, abUnassigningMultipleResources = true, abGetLock = false)
					
					if(abSendUnassignEvent && ! bIsBed)
						if(thisWorkshopObject.HasMultiResource())
							if(bWorkshopLoaded)
								bSendCollectiveEvent = true
							else
								thisWorkshopObject.bResetDone = true
							endif
						else
							WorkshopParent.SendWorkshopActorUnassignedEvent(thisWorkshopObject, akWorkshopRef, akActorRef)
						endif
					endif
				endif
			endif
		endif
		i += 1
	endWhile
	
	;if workshop is loaded, also make sure that the actor gets removed from the worker arrays to prevent him from automatically becoming reassigned:
	if(bWorkshopLoaded && iCaravanActorIndex < 0)
		;ModTrace("NPCManager.UnassignNPC removing " + akActorRef + " from worker array to prevent reassignment.")
		WorkshopParent.WSFW_RemoveActorFromWorkerArray(akActorRef)
	endif
	
	if( ! abNPCTransfer) ; If transferring, they will be updated by the add call
		UpdateWorkshopNPCStatus(akActorRef, akWorkshopRef, abHandleMultiResourceAssignment = false, abGetLock = false)
	endif

	if(bSendCollectiveEvent)
		WorkshopParent.SendWorkshopActorUnassignedEvent(None, akWorkshopRef, akActorRef)
	endif
	
	if(abGetLock)
		if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
			ModTrace("NPCManager.UnassignNPC: Failed to release lock " + iLockKey + "!", 2)
		endif
	endif
endFunction

Function UnassignNPCSkipExclusions(Actor akActorRef, WorkshopScript akWorkshopRef = None, Form aLastAssigned = None, Bool abAutoUpdateWorkshopNPCStatus = true, bool abGetLock = false)
	if( ! akActorRef)
		return
	endif
	
	if( ! akWorkshopRef)
		akWorkshopRef = akActorRef.GetLinkedRef(WorkshopItemKeyword) as WorkshopScript
		
		if( ! akWorkshopRef)
			return
		endif
	endif
	
	
	int iLockKey
	
	if(abGetLock)
		iLockKey = GetLock()
		
		if(iLockKey <= GENERICLOCK_KEY_NONE)
			ModTrace("NPCManager.UnassignNPCSkipExclusions: Unable to get lock!", 2)
			
			return
		endif
	endif
	
	; Check caravan
	int iCaravanActorIndex = CaravanActorAliases.Find(akActorRef)
	if(iCaravanActorIndex >= 0)
		if(WorkshopParent.ExcludeProvisionersFromAssignmentRules)
			Var[] kargs = new Var[0]
			kargs.Add(WorkshopCaravanKeyword)
			kargs.Add(akWorkshopRef)
			kargs.Add(akActorRef)
			kargs.Add(aLastAssigned)
			
			WorkshopParent.SendCustomEvent("AssignmentRulesOverriden", kargs)
		else
			UnassignNPCFromCaravan(akActorRef, akWorkshopRef, bRemoveFromWorkshop = false, abGetLock = false)
		endif
	endif
	
	bool bWorkshopLoaded = akWorkshopRef.Is3dLoaded()
	bool bShouldTryToRecalculateResources = false
	bool bSendCollectiveEvent = false	
	bool bAssignmentRulesOverridden = false
	
	if(bWorkshopLoaded == false)
		WorkshopParent.UFO4P_RegisterUnassignedActor(akActorRef)
		;Also set a tracking bool on the actor's workshop:
		akWorkshopRef.UFO4P_HandleUnassignedActors = true
	endif
	
	ObjectReference[] ResourceObjects = akWorkshopRef.GetWorkshopOwnedObjects(akActorRef)
	int iCountResourceObjects = ResourceObjects.Length
	int i = 0
	while(i < iCountResourceObjects)
		ObjectReference objectRef = ResourceObjects[i]
		WorkshopObjectScript thisWorkshopObject = objectRef as WorkshopObjectScript
		if(thisWorkshopObject != none)
			if(thisWorkshopObject.HasKeyword(WorkshopWorkObject))
				bool bHasMultiResource = thisWorkshopObject.HasMultiResource()
				
				if(IsExcludedFromAssignmentRules(thisWorkshopObject))
					Var[] kargs = new Var[0]
					kargs.Add(thisWorkshopObject)
					kargs.Add(akWorkshopRef)
					kargs.Add(akActorRef)
					kargs.Add(aLastAssigned) 
					
					WorkshopParent.SendCustomEvent("AssignmentRulesOverriden", kargs)
					
					bAssignmentRulesOverridden = true
				else
					UnassignWorkshopObject(thisWorkshopObject, abUnassigningMultipleResources = true, abGetLock = false)
					
					bShouldTryToRecalculateResources = bWorkshopLoaded
											
					if(bHasMultiResource)
						bSendCollectiveEvent = true
					else
						WorkshopParent.SendWorkshopActorUnassignedEvent(thisWorkshopObject, akWorkshopRef, akActorRef)
					endif
				endif
			endif
		endif
		
		i += 1
	endWhile
	
	if(abAutoUpdateWorkshopNPCStatus)
		;ModTrace("NPCManager.UnassignNPCSkipExclusions calling UpdateWorkshopNPCStatus for " + akActorRef)
		UpdateWorkshopNPCStatus(akActorRef, akWorkshopRef, abHandleMultiResourceAssignment = false, abGetLock = false)
	endif
			
	;Note: bShouldTryToRecalculateResources is never true if bWorkshopLoaded = false:
	if(bShouldTryToRecalculateResources)
		akWorkshopRef.RecalculateWorkshopResources()
	endif
	
	if(bSendCollectiveEvent)
		WorkshopParent.SendWorkshopActorUnassignedEvent(None, akWorkshopRef, akActorRef)
	endif
	
	
	if(abGetLock)
		if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
			ModTrace("NPCManager.UnassignNPCSkipExclusions: Failed to release lock " + iLockKey + "!", 2)
		endif
	endif
EndFunction

Function AssignCaravanNPC(Actor akActorRef, Location destinationLocation, bool abGetLock = false)
	int iLockKey
	
	if(abGetLock)
		iLockKey = GetLock()
		
		if(iLockKey <= GENERICLOCK_KEY_NONE)
			ModTrace("NPCManager.AssignCaravanNPC: Unable to get lock!", 2)
			
			return
		endif
	endif
	
	; get destination workshop
	WorkshopScript workshopDestination = WorkshopParent.GetWorkshopFromLocation(destinationLocation)

	; current workshop
	WorkshopScript workshopStart = akActorRef.GetLinkedRef(WorkshopItemKeyword) as WorkshopScript
	
	; unassign this actor from any current job
	UnassignNPCSkipExclusions(akActorRef, workshopStart, WorkshopCaravanKeyword)

	; is this actor already assigned to a caravan?
	int iCaravanIndex = CaravanActorAliases.Find(akActorRef)
	if(iCaravanIndex < 0)
		; add to caravan actor alias collections on WorkshopParent (ours is just a linked mirror to WorkshopParents)
		WorkshopParent.CaravanActorAliases.AddRef(akActorRef)
		if(akActorRef.GetActorBase().IsUnique() == false && akActorRef.GetValue(WorkshopProhibitRename) == 0)
			; put in "rename" alias
			WorkshopParent.CaravanActorRenameAliases.AddRef(akActorRef)
		endif
	else
		; clear current location link
		Location oldDestination = WorkshopParent.GetWorkshop(GetCaravanDestinationID(akActorRef)).myLocation
		workshopStart.myLocation.RemoveLinkedLocation(oldDestination, WorkshopCaravanKeyword)
	endif
	
	int destinationID = workshopDestination.GetWorkshopID()

	; set destination actor value (used to find destination workshop from actor)
	akActorRef.SetValue(CaravanDestinationIDAV, destinationID)
	
	; make caravan ref type
	if(akActorRef.IsCreated())
		akActorRef.SetLocRefType(workshopStart.myLocation, WorkshopCaravanRefType)
	endif

	; add linked refs to actor (for caravan package)
	akActorRef.SetLinkedRef(workshopStart.GetLinkedRef(WorkshopLinkCenter), GetWorkshopLinkCaravanStartKeyword())
	akActorRef.SetLinkedRef(workshopDestination.GetLinkedRef(WorkshopLinkCenter), GetWorkshopLinkCaravanEndKeyword())

	; add link between locations
	workshopStart.myLocation.AddLinkedLocation(workshopDestination.myLocation, WorkshopCaravanKeyword)

	; Update workshop rating - provisioners should count as jobs:
	akActorRef.SetValue(UnassignedPopulation, 0)

	WorkshopParent.SendWorkshopActorCaravanAssignEvent(akActorRef, workshopStart, workshopDestination)

	; stat update
	Game.IncrementStat("Supply Lines Created")
	
	if(abGetLock)
		if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
			ModTrace("NPCManager.AssignCaravanNPC: Failed to release lock " + iLockKey + "!", 2)
		endif
	endif
endFunction

Function UnassignNPCFromCaravan(Actor akActorRef, WorkshopScript workshopRef, Bool bRemoveFromWorkshop = false, bool abGetLock = false)
	int iLockKey
	
	if(abGetLock)
		iLockKey = GetLock()
		
		if(iLockKey <= GENERICLOCK_KEY_NONE)
			ModTrace("NPCManager.UnassignNPCFromCaravan: Unable to get lock!", 2)
			
			return
		endif
	endif
	
	CaravanActorAliases.RemoveRef(akActorRef)
	CaravanActorRenameAliases.RemoveRef(akActorRef)
	
	; unlink locations
	Location startLocation = workshopRef.myLocation
	Location endLocation = WorkshopParent.GetWorkshop(GetCaravanDestinationID(akActorRef)).myLocation
	startLocation.RemoveLinkedLocation(endLocation, WorkshopCaravanKeyword)
	
	; clear caravan brahmin
	CaravanActorBrahminCheck(akActorRef)

	if(akActorRef.IsCreated() && ! bRemoveFromWorkshop)
		; Patch 1.4: allow custom loc ref type on workshop NPC
		SetAsBoss(akActorRef, startLocation)
	endif

	if( ! bRemoveFromWorkshop && ! IsObjectOwner(workshopRef, akActorRef))
		; update workshop rating - increment unassigned actors total
		akActorRef.SetValue(UnassignedPopulation, 1)
	endif

	WorkshopParent.SendWorkshopActorCaravanUnassignEvent(akActorRef, workshopRef)
	Var[] kargs = new Var[2]
	kargs[0] = akActorRef
	kargs[1] = workshopRef
	
	if(abGetLock)
		if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
			ModTrace("NPCManager.UnassignNPCFromCaravan: Failed to release lock " + iLockKey + "!", 2)
		endif
	endif
EndFunction

function UpdateNPCsWorkObjects(Actor akActorRef, WorkshopScript akWorkshopRef = NONE, bool bRecalculateResources = false, Bool abGetLock = false)
	if(akWorkshopRef == None)
		akWorkshopRef = akActorRef.GetLinkedRef(WorkshopItemKeyword) as WorkshopScript

		if( ! akWorkshopRef)
			return
		endif
	endif

	;Better bail out here instead of wasting resources by trying it anyway.
	if( ! akWorkshopRef.Is3dLoaded())
		return
	endif

	int iLockKey
	
	if(abGetLock)
		iLockKey = GetLock()
		
		if(iLockKey <= GENERICLOCK_KEY_NONE)
			ModTrace("NPCManager.UpdateNPCsWorkObjects: Unable to get lock!", 2)
			
			return
		endif
	endif
	
	ObjectReference[] ResourceObjects = akWorkshopRef.GetWorkshopOwnedObjects(akActorRef)
	int countResourceObjects = ResourceObjects.Length
	int i = 0
	
	while i < countResourceObjects
		WorkshopObjectScript theObject = ResourceObjects[i] as WorkshopObjectScript
		if(theObject)
			UpdateWorkshopRatingsForResourceObject(theObject, akWorkshopRef, bRecalculateResources = false)
		endif
		i += 1
	endWhile

	if(bRecalculateResources)
		akWorkshopRef.RecalculateWorkshopResources()
	endif
	
	if(abGetLock)
		if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
			ModTrace("NPCManager.UpdateNPCsWorkObjects: Failed to release lock " + iLockKey + "!", 2)
		endif
	endif
endFunction

Function ClearCaravansFromSettlement(WorkshopScript workshopRef, bool abGetLock = false)
	int iLockKey
	
	if(abGetLock)
		iLockKey = GetLock()
		
		if(iLockKey <= GENERICLOCK_KEY_NONE)
			ModTrace("NPCManager.ClearCaravansFromWorkshop: Unable to get lock!", 2)
			
			return
		endif
	endif
	
	; check all caravan actors for either belonging to this workshop, or targeting it - unassign them
	int i = CaravanActorAliases.GetCount() - 1 ; start at top of list since we may be removing things from it

	while(i	> -1)
		Actor theActor = CaravanActorAliases.GetAt(i) as Actor
		
		if(theActor)
			; check start and end locations
			int destinationWorkshopID = GetCaravanDestinationID(theActor)
			
			WorkshopScript endWorkshop = WorkshopParent.GetWorkshop(destinationWorkshopID)
			WorkshopScript startWorkshop = theActor.GetLinkedRef(WorkshopItemKeyword) as WorkshopScript
			
			if(endWorkshop == workshopRef || startWorkshop == workshopRef)
				; unassign this actor
				UnassignNPCFromCaravan(theActor, workshopRef, false, abGetLock = false)
			endif
		endif
		
		i += -1 ; decrement
	endWhile
	
	if(abGetLock)
		if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
			ModTrace("NPCManager.ClearCaravansFromWorkshop: Failed to release lock " + iLockKey + "!", 2)
		endif
	endif
endFunction

Function RemoveWorkshopObjectFromWorkshop(WorkshopObjectScript akWorkshopObject, WorkshopScript akWorkshopRef = None, bool abGetLock = false)
	if(akWorkshopRef == None)
		akWorkshopRef = akWorkshopObject.GetLinkedRef(WorkshopItemKeyword) as WorkshopScript
		
		if(akWorkshopRef == None)
			return
		endif
	endif
	
	int iLockKey
	
	if(abGetLock)
		iLockKey = GetLock()
		
		if(iLockKey <= GENERICLOCK_KEY_NONE)
			ModTrace("NPCManager.RemoveWorkshopObjectFromWorkshop: Unable to get lock!", 2)
			
			return
		endif
	endif
	
	if(akWorkshopObject.IsBed())
		WorkshopParent.UFO4P_RemoveFromUnassignedBedsArray(akWorkshopObject)
	elseif(akWorkshopObject.HasMultiResource())
		WorkshopParent.UFO4P_RemoveFromUnassignedObjectsArray(akWorkshopObject, akWorkshopObject.GetResourceID())
	endif
	
	UnassignWorkshopObject(akWorkshopObject, abRemovingObject = true, abUnassigningMultipleResources = false, akWorkshopRef = akWorkshopRef, abGetLock = false)
	
	; clear workshopID
	akWorkshopObject.workshopID = -1
	; tell object it's being deleted
	akWorkshopObject.HandleDeletion()
		
	if(abGetLock)
		if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
			ModTrace("NPCManager.RemoveWorkshopObjectFromWorkshop: Failed to release lock " + iLockKey + "!", 2)
		endif
	endif
EndFunction

Function UnassignWorkshopObject(WorkshopObjectScript akWorkshopObject, bool abRemovingObject = false, bool abUnassigningMultipleResources = false, WorkshopScript akWorkshopRef = None, bool abGetLock = false)
	if(akWorkshopRef == None)
		akWorkshopRef = akWorkshopObject.GetLinkedRef(WorkshopItemKeyword) as WorkshopScript
		
		if(akWorkshopRef == None)
			return
		endif
	endif
	
	int iWorkshopID = akWorkshopObject.workshopID
	if(iWorkshopID < 0)
		iWorkshopID = akWorkshopRef.GetWorkshopID()
		
		if(iWorkshopID < 0)
			return
		endif
	endif

	int iLockKey
	
	if(abGetLock)
		iLockKey = GetLock()
		
		if(iLockKey <= GENERICLOCK_KEY_NONE)
			ModTrace("NPCManager.UnassignWorkshopObject: Unable to get lock!", 2)
			
			return
		endif
	endif
	
	Int iCurrentWorkshopID = WorkshopCurrentWorkshopID.GetValueInt()
	Actor kAssignedActor = akWorkshopObject.GetActorRefOwner()
	
	bool bShouldTryToAssignBeds = false
	int iResourceIndexToAssign = -1
	ActorValue multiResourceValue = None
	
	if(kAssignedActor)
		akWorkshopObject.AssignActor(None)

		Keyword actorLinkKeyword = akWorkshopObject.AssignedActorLinkKeyword
		if(actorLinkKeyword)
			kAssignedActor.SetLinkedRef(None, actorLinkKeyword)
		endif

		if(iWorkshopID >= 0)
			if(akWorkshopObject.VendorType > -1 || akWorkshopObject.sCustomVendorID != "")
				SetVendorData(akWorkshopRef, kAssignedActor, akWorkshopObject, false)
			endif

			bool bIsBed = akWorkshopObject.IsBed()

			if(iWorkshopID == iCurrentWorkshopID)
				if(abRemovingObject && bIsBed)
					WorkshopParent.WSFW_AddToActorsWithoutBedsArray(kAssignedActor)
					
					bShouldTryToAssignBeds = true
				elseif( ! abRemovingObject)
					if(bIsBed)
						WorkshopParent.UFO4P_AddUnassignedBedToArray(akWorkshopObject)
					elseif(akWorkshopObject.HasMultiResource())
						WorkshopParent.UFO4P_AddObjectToObjectArray(akWorkshopObject)
					endif
				endif
			endif

			if(bIsBed == false && ! abUnassigningMultipleResources)				
				multiResourceValue = GetAssignedMultiResource(kAssignedActor)
				
				if(multiResourceValue && akWorkshopObject.HasResourceValue(multiResourceValue))
					float previousProduction = GetMultiResourceProduction(kAssignedActor)
					
					if(iWorkshopID == iCurrentWorkshopID)
						iResourceIndexToAssign = GetMultiResourceIndex(multiResourceValue)
						
						WorkshopParent.WSFW_AddActorToWorkerArray(kAssignedActor, iResourceIndexToAssign)
					endif
				endif
			endif
		endif	
	endif

	if(iWorkshopID >= 0 && (kAssignedActor || abRemovingObject))
		UpdateWorkshopRatingsForResourceObject(akWorkshopObject, akWorkshopRef, abRemovingObject, bRecalculateResources = ! abUnassigningMultipleResources)
	endif
	
	if(iResourceIndexToAssign >= 0)
		bool bAllowAssign = true
		if(iResourceIndexToAssign == 0) ; Food
			if(akWorkshopRef.OwnedByPlayer && ! WSFW_Setting_AutoAssign_Food.GetValueInt() == 1)
				bAllowAssign = false
			endif
		elseif(iResourceIndexToAssign == 3) ; Safety
			if(akWorkshopRef.OwnedByPlayer && ! WSFW_Setting_AutoAssign_Defense.GetValueInt() == 1)
				bAllowAssign = false
			endif
		endif
		
		if(bAllowAssign)
			WorkshopParent.TryToAssignResourceType(akWorkshopRef, multiResourceValue)
		endif
	endif
	
	if(bShouldTryToAssignBeds && WSFW_Setting_AutoAssign_Beds.GetValueInt() == 1)
		WorkshopParent.TryToAssignBeds(akWorkshopRef)
	endif	
	
	if(abGetLock)
		if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
			ModTrace("NPCManager.UnassignWorkshopObject: Failed to release lock " + iLockKey + "!", 2)
		endif
	endif
endFunction


function WoundNPC(Actor woundedActor, bool bWoundMe = true, Bool abRecalculateResources = true)
	if(IsWounded(woundedActor) == bWoundMe)
		return
	endif

	; get actor's workshop
	WorkshopScript workshopRef = woundedActor.GetLinkedRef(WorkshopItemKeyword) as WorkshopScript
	
	; wound/heal actor
	SetWounded(woundedActor, bWoundMe)

	; increase or decrease damage?
	int damageValue = 1
	if( ! bWoundMe)
		damageValue = -1
	endif

	; update damage rating
	; RESOURCE CHANGE:
	; reduce extra pop damage if > 0 ; otherwise, damage is normally tracked within WorkshopRatingPopulation (difference between base value and current value)
	if(bWoundMe == false && workshopRef.GetValue(PopulationDamage) > 0)
		ModifyResourceData(PopulationDamage, workshopRef, damageValue)
	endif
	
	UpdateNPCsWorkObjects(woundedActor, workshopRef, abRecalculateResources, abGetLock = false)
endFunction


function NonWorkshopNPCScriptWorkshopChanged(Actor akActorRef, Int aiNewWorkshopID)
	if(aiNewWorkshopID < 0)
		; Unregister for all events
		UnregisterForRemoteEvent(akActorRef, "OnActivate")
		UnregisterForRemoteEvent(akActorRef, "OnCommandModeGiveCommand")
		UnregisterForRemoteEvent(akActorRef, "OnDeath")
		UnregisterForRemoteEvent(akActorRef, "OnLoad")
		UnregisterForRemoteEvent(akActorRef, "OnWorkshopNPCTransfer")
	else
		; Register for all events
		RegisterForRemoteEvent(akActorRef, "OnActivate")
		RegisterForRemoteEvent(akActorRef, "OnCommandModeGiveCommand")
		RegisterForRemoteEvent(akActorRef, "OnDeath")
		RegisterForRemoteEvent(akActorRef, "OnLoad")
		RegisterForRemoteEvent(akActorRef, "OnWorkshopNPCTransfer")
	endif
EndFunction

function HandleNPCDeath(Actor deadActor, Actor akKiller)
	; get actor's workshop
	WorkshopScript workshopRef = deadActor.GetLinkedRef(WorkshopItemKeyword) as WorkshopScript

	RemoveNPCFromWorkshop(deadActor, workshopRef)
	
	if( ! IsSynth(deadActor) && CountsForPopulation(deadActor) && deadActor.IsInFaction(WorkshopEnemyFaction) == false)
		WorkshopParent.ModifyHappinessModifier(workshopRef, workshopRef.actorDeathHappinessModifier)
	endif	
endFunction



;
; Non-WorkshopNPCScript Actor Events
;
Event ObjectReference.OnLoad(ObjectReference akSender)
	Actor asActor = akSender as Actor
	
	if(asActor)
		if(asActor.IsDead())
			RemoveNPCFromWorkshop(asActor)
			
			return
		endif

		; Note: Removed the checks for resetting command, move, and caravan - there was mentions in the original code about cell resets requiring this. Due to the location persistence, this should not be an issue, but if it turns out to be, there's really nothing we can do as our setting of those is based on the same keywords that the vanilla system was using. Ie. if those keywords get cleared, we have no way to detect that they were set in the first place.
		
		; WOUNDED STATE: removing visible wounded state for now
		if(asActor.IsDead() == false && IsWounded(asActor))
			WoundNPC(asActor, false, false)
		endif		

		; check if I should create caravan brahmin
		CaravanActorBrahminCheck(asActor)
	endif
EndEvent
	
Event ObjectReference.OnActivate(ObjectReference akSender, ObjectReference akActionRef)
	Actor asActor = akSender as Actor
	
	if(asActor)
		WorkshopScript thisWorkshop = akSender.GetLinkedRef(WorkshopItemKeyword) as WorkshopScript
		if(thisWorkshop.OwnedByPlayer)			
			if(asActor && asActor.IsDoingFavor() && akActionRef == asActor && IsCommandable(asActor)) ; must be commandable so this doesn't trigger for companions
				int iSelfActivationCount = GetSelfActivationCount(asActor)
				iSelfActivationCount += 1
				
				if(iSelfActivationCount > 1)
					; toggle favor state
					asActor.SetDoingFavor(false, true)
				endif
			endif
		endif
	endif
EndEvent


Event Actor.OnCommandModeGiveCommand(Actor akSender, int aeCommandType, ObjectReference akTarget)
	WorkshopObjectScript workObject = akTarget as WorkshopObjectScript
	if(workObject && aeCommandType == 10) ; workshop assign command
		workObject.ActivatedByWorkshopNPC(akSender)
	endif
endEvent


Event Actor.OnDeath(Actor akSender, Actor akKiller)
	; death item if synth
	if(IsSynth(akSender))
		akSender.AddItem(SynthDeathItem)
	endif
	
	; remove me from the workshop
	HandleNPCDeath(akSender, akKiller)
EndEvent


Event ObjectReference.OnWorkshopNPCTransfer(ObjectReference akSender, Location akNewWorkshopLocation, Keyword akActionKW)
	; what kind of transfer?
	Actor asActor = akSender as Actor
	if(akActionKW == WorkshopAssignCaravan)
		AssignCaravanNPC(asActor, akNewWorkshopLocation, abGetLock = true)
	else
		WorkshopScript newWorkshop = WorkshopParent.GetWorkshopFromLocation(akNewWorkshopLocation)
		if(newWorkshop)
			if(akActionKW == WorkshopAssignHome || akActionKW == WorkshopAssignHomePermanentActor)
				AddNPCToWorkshop(asActor, newWorkshop, abResetMode = false)
			endif
		
			; Send event that an NPC transfer occurred
			WorkshopParent.SendWorkshopNPCTransferEvent(asActor, newWorkshop, akActionKW)
		else
			; TODO - Allow settlers to be assigned to non-Workshop Locations (for things like harvesting resources or guarding locations
		endif
	endif
EndEvent