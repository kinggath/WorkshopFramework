; ---------------------------------------------
; WorkshopFramework:Library:MasterQuest.psc - by kinggath
; ---------------------------------------------
; Reusage Rights ------------------------------
; You are free to use this script or portions of it in your own mods, provided you give me credit in your description and maintain this section of comments in any released source code (which includes the IMPORTED SCRIPT CREDIT section to give credit to anyone in the associated Import scripts below.
; 
; IMPORTED SCRIPT CREDIT
; N/A
; ---------------------------------------------

Scriptname WorkshopFramework:Library:MasterQuest extends WorkshopFramework:Library:VersionedLockableQuest
{ Centralized manager of other quests in the mod, designed to keep event calls to a minimum, and handle maintenance tasks like resetting quests as needed }

import WorkshopFramework:Library:UtilityFunctions

; ---------------------------------------------
; Consts NOTE: In order for extended quests to access these vars, they must be set as properties
; ---------------------------------------------

int Property EVENTSTAGE_FromMasterQuest = -1 autoReadOnly
int Property EVENTSTAGEITEM_PlayerLoadedGame = -1 autoReadOnly
int Property EVENTSTAGEITEM_PlayerChangedLocation = -2 autoReadOnly

int Property MANAGEDEVENT_OnPlayerLoadGame = 0 autoReadOnly
int Property MANAGEDEVENT_OnPlayerLocationChange = 1 autoReadOnly

Float Property fLocationChangeDelay = 6.0 autoReadOnly

; Timer IDs
Int Property LocationChangeTimerID = 0 autoReadOnly

; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------

Group Controllers
	Quest Property CheckQuest Auto Const Mandatory
	{ The Quest that has to be at a certain stage before all FrameworkStartQuests will be enabled. For the base game, this would generally be after WorkshopParent initializes all workshops. }
	Int Property iCheckQuestSafeToLaunchStage Auto Const Mandatory
	{ The stage CheckQuest has to be before all FrameworkStartQuests will be enabled. For the base game, this would generally be after WorkshopParent initializes all workshops. }
	
	WorkshopFramework:Library:ThreadManager Property ThreadManager Auto Const Mandatory
	
	Quest[] Property FrameworkStartQuests Auto Const
	{ These quests will be started, in order entered, after it's confirmed the player is past the iCheckQuestSafeToLaunchStage of CheckQuest. This will ensure we aren't competing with other mods for start-up script time and reduce the likelihood of quests failing to start. }
EndGroup

Group FormLists
	FormList Property GameLoadedQuests Auto Const Mandatory
	{ Blank formlist for registered quests }
	
	Formlist Property LocationChangedQuests Auto Const Mandatory
	{ Blank formlist for registered quests }
EndGroup

Group Aliases
	LocationAlias Property PreviousLocation Auto Const Mandatory
	{ 1.1.7 Alias to store the previous player visited location }
	LocationAlias Property LatestLocation Auto Const Mandatory
	{ Alias to store the last player visited location }
EndGroup


; ---------------------------------------------
; Properties
; ---------------------------------------------

Bool Property bFreshInstall = true Auto Hidden
Bool Property bQuestStartupsComplete = false Auto Hidden
Quest[] Property JustStartedQuests Auto Hidden

; ---------------------------------------------
; Vars
; ---------------------------------------------

Bool bQuestStartupInProgress = false
Bool Function IsQuestStartupInProgress()
	return bQuestStartupInProgress
endFunction
Bool bTriggerGameLoadRunning = false
Bool Function IsTriggerGameLoadRunning()
	return bTriggerGameLoadRunning
endFunction
Bool bLocationChangeTriggersSuppressed = false

Function SuppressLocationChangeTriggers(Bool abSuppress = true)
	bLocationChangeTriggersSuppressed = abSuppress
EndFunction

; ---------------------------------------------
; Events 
; ---------------------------------------------

Event Actor.OnLocationChange(Actor akActorRef, Location akOldLoc, Location akNewLoc)
	HandleLocationChange(akNewLoc)
EndEvent


Event OnPlayerTeleport()
	Location akNewLoc = PlayerRef.GetCurrentLocation()
	HandleLocationChange(akNewLoc)
EndEvent


Event Quest.OnStageSet(Quest akQuestRef, int auiStageID, int auiItemID)
	; 1.1.0 - Switching to event handler so we can override it
	HandleStageSet(akQuestRef, auiStageID, auiItemID)
EndEvent


Event OnTimer(Int aiTimerID)
	if(aiTimerID == LocationChangeTimerID)
		TriggerLocationChange()
	endif
EndEvent



; ---------------------------------------------
; Handlers
; ---------------------------------------------

Function HandleStageSet(Quest akQuestRef, int auiStageID, int auiItemID)
	ModTrace("[WSFW] >>>>>>>>>>>>>>>>>>> Quest event received on MasterQuest: " + akQuestRef + " reached stage " + auiStageID)
	if(akQuestRef == CheckQuest && auiStageID == iCheckQuestSafeToLaunchStage)
		StartQuests()
	endif
EndFunction


; ---------------------------------------------
; Extended Handlers
; ---------------------------------------------

Function HandleQuestInit()
	Parent.HandleQuestInit()
	
	; Register for events
	RegisterForRemoteEvent(PlayerRef, "OnLocationChange")
	RegisterForPlayerTeleport()	
EndFunction


Function HandleGameLoaded()
	ModTrace("[WSFW] >>>>>>>>>>>>>>>>> GameLoaded called on MasterQuest " + Self)
	JustStartedQuests = new Quest[0]
	
	; Clear vars to ensure they are never pemanently stuck
	bLocationChangeTriggersSuppressed = false
	bQuestStartupInProgress = false
	
	if(iInstalledVersion < gCurrentVersion.GetValue())
		bQuestStartupsComplete = false ; Make sure we confirm all necessary quests are running - including any new ones
	endif
	
	ModTrace("[WSFW] >>>>>>>>>>>>>>>>> Attempting to run StartQuests")
	if( ! StartQuests())
		return
	endif
	
	; Ensure registered quest formlists are clean
	CleanFormlist(GameLoadedQuests)
	CleanFormlist(LocationChangedQuests)
	
	; Ensure location change triggers when player loads the game	
	OnPlayerTeleport() 
	
	; Trigger all quests registered for the OnPlayerLoadGameEvent
	;Debug.MessageBox("TriggerGameLoaded called.")
	TriggerGameLoaded()
	
	; Process parent game loaded actions
	Parent.HandleGameLoaded()
	
	if(bFreshInstall)
		bFreshInstall = false
	endif
EndFunction


; ---------------------------------------------
; Methods -------------------------------------
; ---------------------------------------------
	
Function RegisterForManagedEvent(Quest akRegisterMe, int aiEventType = 0)
	if(aiEventType == MANAGEDEVENT_OnPlayerLoadGame)
		GameLoadedQuests.AddForm(akRegisterMe)
	elseif(aiEventType == MANAGEDEVENT_OnPlayerLocationChange)
		LocationChangedQuests.AddForm(akRegisterMe)
	endif
EndFunction


Function HandleLocationChange(Location akNewLoc)
	Location lastParentLocation = LatestLocation.GetLocation()
	
	if(akNewLoc == None || lastParentLocation == None || ! akNewLoc.IsSameLocation(lastParentLocation))
		if(lastParentLocation != None)
			PreviousLocation.ForceLocationTo(lastParentLocation) ; 1.1.7
		else
			PreviousLocation.Clear()
		endif
		
		if(akNewLoc != None)
			LatestLocation.ForceLocationTo(akNewLoc)
		else
			LatestLocation.Clear()
		endif
		
		StartTimer(fLocationChangeDelay, LocationChangeTimerID)	
	endif
EndFunction


Function TriggerLocationChange()
	if(bLocationChangeTriggersSuppressed)
		return
	endif
	
	int i = 0
	ModTrace("[MasterQuest] " + Self + " TriggerLocationChange called. Sending event to " + LocationChangedQuests.GetSize() + " quests.")
	while(i < LocationChangedQuests.GetSize())
		Quest thisQuest = LocationChangedQuests.GetAt(i) as Quest
		
		String sCastAs = "Quest"
		if(thisQuest is WorkshopFramework:Library:SlaveQuest)
			sCastAs = "WorkshopFramework:Library:SlaveQuest"
		endif
		
		ModTrace("[" + Self + "] TriggerLocationChange called on " + thisQuest)
		Var[] kArgs = new Var[2]
		kArgs[0] = EVENTSTAGE_FromMasterQuest
		kArgs[1] = EVENTSTAGEITEM_PlayerChangedLocation
		ThreadManager.QueueRemoteFunctionThread("TriggerLocationChange", thisQuest, sCastAs, "OnStageSet", kArgs)
		
		i += 1
	endWhile
EndFunction


Function TriggerGameLoaded()
	; Prevent these from stacking if the player loads, saves, quits and reloads quickly.
	if(bTriggerGameLoadRunning)
		return
	endif
	
	bTriggerGameLoadRunning = true
	
	int i = 0
	while(i < GameLoadedQuests.GetSize())
		Quest thisQuest = GameLoadedQuests.GetAt(i) as Quest
		
		String sCastAs = "Quest"
		if(thisQuest is WorkshopFramework:Library:SlaveQuest)
			sCastAs = "WorkshopFramework:Library:SlaveQuest"
		endif
		
		ModTrace("[" + Self + "] TriggerGameLoaded called on " + thisQuest)
		Var[] kArgs = new Var[2]
		kArgs[0] = EVENTSTAGE_FromMasterQuest
		kArgs[1] = EVENTSTAGEITEM_PlayerLoadedGame
		ThreadManager.QueueRemoteFunctionThread("TriggerGameLoaded", thisQuest, sCastAs, "OnStageSet", kArgs)
		
		i += 1
	endWhile
	
	bTriggerGameLoadRunning = false
EndFunction


Bool Function SafeToStartFrameworkQuests()
	if( ! CheckQuest)
		return true
	else
		return CheckQuest.GetStageDone(iCheckQuestSafeToLaunchStage)
	endif
EndFunction


Bool Function StartQuests()	
	if(bQuestStartupsComplete)
		ModTrace("[WSFW] >>>>>>>>>>>>>>>>>>> Quest startup already complete.")
		return true
	endif
	
	if(bQuestStartupInProgress)
		; Prevent multiple simultaneous runs
		return false
	endif
	
	bQuestStartupInProgress = true
	
	; In case of new game, be sure to wait for initialization to complete
	if( ! SafeToStartFrameworkQuests())
		ModTrace("[WSFW] >>>>>>>>>>>>>>>>>>> Can't start quests yet, waiting for " + CheckQuest + " to hit stage " + iCheckQuestSafeToLaunchStage + ".")
		
		RegisterForRemoteEvent(CheckQuest, "OnStageSet")
		bQuestStartupInProgress = false
		return false
	else
		ModTrace("[WSFW] >>>>>>>>>>>>>>>>>>> Starting up " + FrameworkStartQuests.Length + " framework quests")
		
		UnRegisterForRemoteEvent(CheckQuest, "OnStageSet")
		int i = 0
		int iStartedQuests = 0
		while(i < FrameworkStartQuests.Length)
			ModTrace("[WSFW] >>> Handling startup of quest " + FrameworkStartQuests[i])
			if( ! FrameworkStartQuests[i].IsRunning() && ! FrameworkStartQuests[i].IsStarting())
				Float fStartAttempt = Utility.GetCurrentRealTime()
				
				if(FrameworkStartQuests[i].Start())
					iStartedQuests += 1
				else
					ModTrace("Failed to start quest " + FrameworkStartQuests[i])
				endif
			elseif(FrameworkStartQuests[i].IsRunning())
				ModTrace("Quest " + FrameworkStartQuests[i] + " is already running.")
				iStartedQuests += 1
			else
				ModTrace("Failed to start quest " + FrameworkStartQuests[i])
			endif
			
			i += 1
		endWhile
		
		if(iStartedQuests >= FrameworkStartQuests.Length)
			bQuestStartupsComplete = true
		endif
	endif
	
	bQuestStartupInProgress = false
	
	return bQuestStartupsComplete
EndFunction