; ---------------------------------------------
; WorkshopFramework:Library:SlaveQuest.psc - by kinggath
; ---------------------------------------------
; Reusage Rights ------------------------------
; You are free to use this script or portions of it in your own mods, provided you give me credit in your description and maintain this section of comments in any released source code (which includes the IMPORTED SCRIPT CREDIT section to give credit to anyone in the associated Import scripts below).
; 
; Warning !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
; Do not directly recompile this script for redistribution without first renaming it to avoid compatibility issues with the mod this came from.
; 
; IMPORTED SCRIPT CREDITS
; N/A
; ---------------------------------------------


Scriptname WorkshopFramework:Library:SlaveQuest extends WorkshopFramework:Library:VersionedLockableQuest
{ This quest will have certain events fed to it from MasterQuest, to allow for threading of common event processing code - such as PlayerLoadGame, or PlayerChangedLocation }

; ------------------------------------------
; Consts
; ------------------------------------------

	; Duplicates from MasterQuest, to avoid having to make calls to it
int Property EVENTSTAGE_FromMasterQuest = -1 autoReadOnly
int Property EVENTSTAGEITEM_PlayerLoadedGame = -1 autoReadOnly
int Property EVENTSTAGEITEM_PlayerChangedLocation = -2 autoReadOnly

int Property MANAGEDEVENT_OnPlayerLoadGame = 0 autoReadOnly
int Property MANAGEDEVENT_OnPlayerLocationChange = 1 autoReadOnly

; ------------------------------------------
; Editor Properties
; ------------------------------------------

Group Controllers
	WorkshopFramework:Library:MasterQuest Property MasterQuest Auto Const Mandatory
EndGroup

Group Aliases
	LocationAlias Property CurrentLocation Auto Const Mandatory
	{ Point to LatestLocation alias on MasterQuest, this will avoid papyrus needing to touch the MasterQuest }
EndGroup



; ------------------------------------------
; Vars
; ------------------------------------------


; ------------------------------------------
; Events
; ------------------------------------------

Event OnStageSet(Int auiStageID, Int auiItemID)
	if(auiStageID == EVENTSTAGE_FromMasterQuest)
		if(auiItemID == EVENTSTAGEITEM_PlayerLoadedGame) ; Player Loaded Game
			HandleGameLoaded()
		elseif(auiItemID == EVENTSTAGEITEM_PlayerChangedLocation) ; Player Changed Location
			HandleLocationChange(CurrentLocation.GetLocation())
		endif
	endif
EndEvent


; ------------------------------------------
; Handler Functions - These should be extended/written by the extended scripts that use them
; ------------------------------------------

Function HandleQuestInit()
	Parent.HandleQuestInit()
	
	; Unregister for this, as we want our GameLoaded code to run in response to the MasterQuest
	UnRegisterForRemoteEvent(PlayerRef, "OnPlayerLoadGame")
	
	MasterQuest.RegisterForManagedEvent(Self, MANAGEDEVENT_OnPlayerLoadGame)
	MasterQuest.RegisterForManagedEvent(Self, MANAGEDEVENT_OnPlayerLocationChange)
	
	; Extend me
EndFunction

Function HandleLocationChange(Location akLocationRef)
	; Extend me
EndFunction

Function HandleGameLoaded()
	Parent.HandleGameLoaded()
	
	; Extend me
EndFunction