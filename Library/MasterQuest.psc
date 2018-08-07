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
	FormList Property GameLoadedQuests Auto Const
	{ Blank formlist for registered quests }
	
	Formlist Property LocationChangedQuests Auto Const
	{ Blank formlist for registered quests }
EndGroup

Group Aliases	
	LocationAlias Property LatestLocation Auto Const
	{ Alias to store the store the last player visited location }
EndGroup


; ---------------------------------------------
; Properties
; ---------------------------------------------

Bool Property bFreshInstall = true Auto Hidden
Bool Property bQuestStartupsComplete = false Auto Hidden


; ---------------------------------------------
; Vars
; ---------------------------------------------

Bool bTriggerGameLoadRunning = false


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
	if(akQuestRef == CheckQuest && auiStageID == iCheckQuestSafeToLaunchStage)
		StartQuests()
	endif
EndEvent


Event OnTimer(Int aiTimerID)
	if(aiTimerID == LocationChangeTimerID)
		TriggerLocationChange()
	endif
EndEvent


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
	if(iInstalledVersion < gCurrentVersion.GetValue())
		bQuestStartupsComplete = false ; Make sure we confirm all necessary quests are running - including any new ones
	endif
	
	if( ! StartQuests())
		return
	endif
	
	; Ensure registered quest formlists are clean
	CleanFormlist(GameLoadedQuests)
	CleanFormlist(LocationChangedQuests)
	
	; Ensure location change triggers when player loads the game	
	OnPlayerTeleport() 
	
	; Trigger all quests registered for the OnPlayerLoadGameEvent
	TriggerGameLoaded()
	
	; Process parent game loaded actions
	Parent.HandleGameLoaded()
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
	if( ! akNewLoc)
		return
	endif
	
	Location lastParentLocation = LatestLocation.GetLocation()
	
	if( ! akNewLoc.IsSameLocation(lastParentLocation))
		LatestLocation.ForceLocationTo(akNewLoc)
		StartTimer(fLocationChangeDelay, LocationChangeTimerID)	
	endif
EndFunction


Function TriggerLocationChange()
	int i = 0
	
	while(i < LocationChangedQuests.GetSize())
		Var[] kArgs = new Var[2]
		kArgs[0] = EVENTSTAGE_FromMasterQuest
		kArgs[1] = EVENTSTAGEITEM_PlayerChangedLocation
		ThreadManager.QueueRemoteFunctionThread(LocationChangedQuests.GetAt(i), "Quest", "OnStageSet", kArgs)
		
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
		Var[] kArgs = new Var[2]
		kArgs[0] = EVENTSTAGE_FromMasterQuest
		kArgs[1] = EVENTSTAGEITEM_PlayerLoadedGame
		ThreadManager.QueueRemoteFunctionThread(GameLoadedQuests.GetAt(i), "Quest", "OnStageSet", kArgs)
	
		i += 1
	endWhile
	
	bTriggerGameLoadRunning = false
EndFunction


Bool Function StartQuests()
	if(bQuestStartupsComplete)
		return true
	endif
	
	; In case of new game, be sure to wait for initialization to complete
	if(CheckQuest.GetStageDone(iCheckQuestSafeToLaunchStage) == false)
		RegisterForRemoteEvent(CheckQuest, "OnStageSet")
		return false
	else
		UnRegisterForRemoteEvent(CheckQuest, "OnStageSet")
		int i = 0
		int iStartedQuests = 0
		while(i < FrameworkStartQuests.Length)
			if( ! FrameworkStartQuests[i].IsRunning() && ! FrameworkStartQuests[i].IsStarting())
				if(FrameworkStartQuests[i].Start())
					iStartedQuests += 1
				endif
			elseif(FrameworkStartQuests[i].IsRunning())
				iStartedQuests += 1
			endif
			
			i += 1
		endWhile
		
		if(iStartedQuests >= FrameworkStartQuests.Length)
			bQuestStartupsComplete = true
		endif
	endif
	
	return bQuestStartupsComplete
EndFunction