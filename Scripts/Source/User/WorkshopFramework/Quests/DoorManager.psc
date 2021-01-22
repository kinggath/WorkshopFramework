; ---------------------------------------------
; WorkshopFramework:Quests:DoorManager.psc - by kinggath
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

Scriptname WorkshopFramework:Quests:DoorManager extends WorkshopFramework:Library:SlaveQuest
{ Handles auto opening/closing of settlement doors }

import WorkshopFramework:Library:DataStructures
import WorkshopFramework:Library:UtilityFunctions

; ------------------------------------------
; Consts
; ------------------------------------------

int iMaxEntries = 512 Const ; Increase if adding more arrays

int iTimerID_CleanupDoorRegistration = 3001 Const ; Starting extremely high to give us room to grow support for more doors
Float fTimerLength_CleanupDoorRegistration = 24.0 Const

Float fLastTimerStart_CleanupDoorRegistration = 0.0 ; Not a const, keeping it here for organization purposes. Used to ensure we can reboot this timer if it fails due to save file issues.

; ------------------------------------------
; Editor Properties
; ------------------------------------------

Group Quests
	WorkshopFramework:MainQuest Property WSFW_Main Auto Const Mandatory
	WorkshopFramework:SettlementLayoutManager Property SettlementLayoutManager Auto Const Mandatory
	WorkshopFramework:Quests:DoorFinder[] Property DoorFinders Auto Const Mandatory
EndGroup

Group Globals
	GlobalVariable Property Setting_DoorManagement Auto Const Mandatory
	{ This is our master toggle for the system. This way we can keep the other settings defaulted to something reasonable without the player having to turn each one on to start using this. }
	GlobalVariable Property Setting_AutoCloseTime Auto Const Mandatory
	GlobalVariable Property Setting_AutoOpenDoorsInWorkshopMode Auto Const Mandatory
	GlobalVariable Property Setting_AutoCloseDoorsOnWorkshopModeExit Auto Const Mandatory
	GlobalVariable Property Setting_AutoCloseDoorsOpenedByPlayer Auto Const Mandatory
	GlobalVariable Property Setting_AutoCloseDoorsOpenedByNPCs Auto Const Mandatory
EndGroup

Group Keywords
	Keyword Property DoNotAutoCloseMe Auto Const Mandatory
	{ Vanilla VatsCCNoCloseUps keyword so that any mod can add to their doors }
	; TODO - Add a perk entry to tag a door as "Do Not Auto-Close", ensure this can be disabled the same way the workshop one can, and ensure it only works on settlement doors to avoid conflicting with lock mods
	Keyword Property AutoCloseUnlinkedDoor Auto Const Mandatory
	{ Vanilla LinkTerminalDoor keyword so doors not connected via WorkshopItemKeyword can be picked up by our system. (Not directly used in this script, but held so other mods can fetch the property for applying the keyword at runtime.) }
	Keyword Property EventKeyword_DoorFinder Auto Const Mandatory
EndGroup

; ------------------------------------------
; Vars
; ------------------------------------------

Int iNextQueueSlot = -1 ; Start at -1 so our first request becomes 0
Int Property NextQueueSlot	
	Int Function Get()
		iNextQueueSlot += 1
		
		if(iNextQueueSlot >= 512)
			iNextQueueSlot = 0
		endif
		
		return iNextQueueSlot
	EndFunction
EndProperty


ObjectReference[] Property DoorsToClose01 Auto Hidden
ObjectReference[] Property DoorsToClose02 Auto Hidden
ObjectReference[] Property DoorsToClose03 Auto Hidden
ObjectReference[] Property DoorsToClose04 Auto Hidden ; Up to 512

Bool bAllDoorTogglingInProgress = false
Bool bOpeningAllDoors = false

Bool[] bDoorRegistrationInProgress
Bool[] bDoorRegistrationCompleted

; ------------------------------------------
; Events
; ------------------------------------------

Event OnTimer(Int aiTimerID)
	CloseDoor(aiTimerID)
	RemoveFromQueueByIndex(aiTimerID)
EndEvent


Event OnTimerGameTime(Int aiTimerID)
	if(aiTimerID == iTimerID_CleanupDoorRegistration)
		bDoorRegistrationCompleted = new Bool[128] ; Reset so cleanup will occur upon arrival at a settlement
		
		StartCleanupDoorRegistrationTimer()
	endif
EndEvent


Event ObjectReference.OnOpen(ObjectReference akRef, ObjectReference akOpenedBy)
	if(Setting_DoorManagement.GetValue() == 0 || (akOpenedBy != PlayerRef && Setting_AutoCloseDoorsOpenedByPlayer.GetValue() == 0) || (akOpenedBy == PlayerRef && Setting_AutoCloseDoorsOpenedByNPCs.GetValue() == 0) || akRef.HasKeyword(DoNotAutoCloseMe))
		return
	endif
	
	if(Setting_AutoOpenDoorsInWorkshopMode.GetValueInt() == 1 && WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		; Player is in workshop mode with Auto Open in Workshop Mode on - we'll close when the player exits
		return
	endif
	
	AddToQueue(akRef)
EndEvent

Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)
    if(asMenuName== "WorkshopMenu")
		if(abOpening)
			if(Setting_DoorManagement.GetValue() == 1 && Setting_AutoOpenDoorsInWorkshopMode.GetValue() == 1)
				ToggleAllDoors(WorkshopFramework:WSFW_API.GetNearestWorkshop(PlayerRef), true)
			endif
		else
			if(Setting_DoorManagement.GetValue() == 1 && Setting_AutoCloseDoorsOnWorkshopModeExit.GetValue() == 1)
				ToggleAllDoors(WorkshopFramework:WSFW_API.GetNearestWorkshop(PlayerRef), false)
			endif
		endif
    endif
endEvent


Event WorkshopFramework:MainQuest.PlayerEnteredSettlement(WorkshopFramework:MainQuest akQuestRef, Var[] akArgs)
	WorkshopScript kWorkshopRef = akArgs[0] as WorkshopScript
	Bool bPreviouslyUnloaded = akArgs[1] as Bool
	
	if(bPreviouslyUnloaded)
		HandlePlayerEnteredSettlement(kWorkshopRef)
	endif
EndEvent


Event WorkshopFramework:SettlementLayoutManager.SettlementLayoutBuilt(WorkshopFramework:SettlementLayoutManager akSender, Var[] akArgs)
	;/
	akArgs[0] = akWorkshopRef
	akArgs[1] = aBuiltLayout
	/;
	
	WorkshopScript thisWorkshop = akArgs[0] as WorkshopScript
	
	if(thisWorkshop != None)
		RegisterAllDoors(thisWorkshop)
	endif
EndEvent


Event ObjectReference.OnWorkshopObjectPlaced(ObjectReference akWorkshop, ObjectReference akBuiltRef)
	if(akBuiltRef.GetBaseObject() as Door)
		RegisterDoor(akBuiltRef)
	endif
EndEvent


Event ObjectReference.OnWorkshopObjectDestroyed(ObjectReference akWorkshop, ObjectReference akDestroyedRef)
	if(akDestroyedRef.GetBaseObject() as Door)
		UnregisterDoor(akDestroyedRef)
	endif
EndEvent

; ------------------------------------------
; Functions
; ------------------------------------------

Function HandleQuestInit()
	; Init arrays
	bDoorRegistrationInProgress = new Bool[128]
	bDoorRegistrationCompleted = new Bool[128]
	
	RegisterForEvents()
	
	StartCleanupDoorRegistrationTimer()
	
	WorkshopScript kWorkshopRef = WorkshopFramework:WSFW_API.GetNearestWorkshop(PlayerRef)
	
	if(kWorkshopRef && kWorkshopRef.Is3dLoaded())
		HandlePlayerEnteredSettlement(kWorkshopRef)
	endif
EndFunction


Function HandlePlayerEnteredSettlement(WorkshopScript akWorkshopRef)
	if( ! akWorkshopRef)
		return
	endif
	
	int iWorkshopID = akWorkshopRef.GetWorkshopID()
	if( ! bDoorRegistrationCompleted[iWorkshopID])
		RegisterAllDoors(akWorkshopRef)
	endif
	
	; Make sure we're registered for workshop place/destroy
	RegisterForRemoteEvent(akWorkshopRef, "OnWorkshopObjectPlaced")
	RegisterForRemoteEvent(akWorkshopRef, "OnWorkshopObjectDestroyed")
EndFunction


Function HandleGameLoaded()
	RegisterForEvents()
	
	Float fCurrentGameTime = Utility.GetCurrentGameTime()
	
	if(fLastTimerStart_CleanupDoorRegistration < fCurrentGameTime - (fTimerLength_CleanupDoorRegistration/24.0))
		StartCleanupDoorRegistrationTimer()
	endif
EndFunction


Function RegisterForEvents()
	RegisterForCustomEvent(WSFW_Main, "PlayerEnteredSettlement")
	RegisterForMenuOpenCloseEvent("WorkshopMenu")
	RegisterForCustomEvent(SettlementLayoutManager, "SettlementLayoutBuilt")
EndFunction


Function StartCleanupDoorRegistrationTimer()
	fLastTimerStart_CleanupDoorRegistration = Utility.GetCurrentGameTime()
	StartTimerGameTime(fTimerLength_CleanupDoorRegistration, iTimerID_CleanupDoorRegistration)
EndFunction


Function RegisterDoor(ObjectReference akRef)
	if( ! akRef || ! akRef.GetBaseObject() as Door)
		ModTrace("[DoorManager] Attempted to register a non-door ref: " + akRef)
		return
	endif
	
	RegisterForRemoteEvent(akRef, "OnOpen")
	
	if(Setting_DoorManagement.GetValueInt() == 1 && Setting_AutoOpenDoorsInWorkshopMode.GetValueInt() == 1 && WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		akRef.SetOpen(true)
	endif
EndFunction


Function UnregisterDoor(ObjectReference akRef)
	if( ! akRef)
		return
	endif
	
	RemoveFromQueue(akRef)
	
	UnregisterForRemoteEvent(akRef, "OnOpen")
EndFunction


Int Function FindQueueIndex(ObjectReference akRef)
	int index = DoorsToClose01.Find(akRef)
	if(index < 0)
		index = DoorsToClose02.Find(akRef)
		
		if(index < 0)
			index = DoorsToClose03.Find(akRef)
		
			if(index < 0)
				index = DoorsToClose04.Find(akRef)
			endif
		endif
	endif
	
	return index
EndFunction


ObjectReference Function FindRefByIndex(Int aiIndex)
	if(aiIndex >= 0 && aiIndex < iMaxEntries)
		if(aiIndex >= 384)
			return DoorsToClose04[aiIndex - 384]
		elseif(aiIndex >= 256)
			return DoorsToClose03[aiIndex - 256]
		elseif(aiIndex >= 128)
			return DoorsToClose02[aiIndex - 128]
		else
			return DoorsToClose01[aiIndex]
		endif
	endif
	
	return None
EndFunction


Function AddToQueue(ObjectReference akRef)
	Int index = FindQueueIndex(akRef)
	
	if(index <= 0)
		int iNewIndex = NextQueueSlot
		
		if(iNewIndex >= 384)
			if(DoorsToClose04 == None)
				DoorsToClose04 = new ObjectReference[128]
			endif
			
			DoorsToClose04[iNewIndex - 384] = akRef
		elseif(iNewIndex >= 256)
			if(DoorsToClose03 == None)
				DoorsToClose03 = new ObjectReference[128]
			endif
			
			DoorsToClose03[iNewIndex - 256] = akRef
		elseif(iNewIndex >= 128)
			if(DoorsToClose02 == None)
				DoorsToClose02 = new ObjectReference[128]
			endif
			
			DoorsToClose02[iNewIndex - 128] = akRef
		else
			if(DoorsToClose01 == None)
				DoorsToClose01 = new ObjectReference[128]
			endif
			
			DoorsToClose01[iNewIndex] = akRef
		endif
		
		StartTimer(Setting_AutoCloseTime.GetValue(), iNewIndex)
	endif
EndFunction


Function RemoveFromQueue(ObjectReference akRef)
	Int index = FindQueueIndex(akRef)
	
	RemoveFromQueueByIndex(index)
EndFunction


Function RemoveFromQueueByIndex(Int aiIndex)
	if(aiIndex < iMaxEntries && aiIndex >= 0)
		if(aiIndex >= 384)
			DoorsToClose04[aiIndex - 384] = None
		elseif(aiIndex >= 256)
			DoorsToClose03[aiIndex - 256] = None
		elseif(aiIndex >= 128)
			DoorsToClose02[aiIndex - 128] = None
		else
			DoorsToClose01[aiIndex] = None
		endif
	endif
EndFunction


Function CloseDoor(Int aiIndex)
	if(aiIndex >= 0 && aiIndex < iMaxEntries)
		if(aiIndex >= 384)
			DoorsToClose04[aiIndex - 384].SetOpen(false)
		elseif(aiIndex >= 256)
			DoorsToClose03[aiIndex - 256].SetOpen(false)
		elseif(aiIndex >= 128)
			DoorsToClose02[aiIndex - 128].SetOpen(false)
		else
			DoorsToClose01[aiIndex].SetOpen(false)
		endif
	endif
EndFunction


Function ToggleAllDoors(WorkshopScript akWorkshopRef, Bool abOpen = true)
	if(bAllDoorTogglingInProgress)
		if(bOpeningAllDoors == abOpen) ; Already processing request
			return
		else
			int iWaitCount = 0
			while(bAllDoorTogglingInProgress)
				iWaitCount += 1
				Utility.Wait(1.0)
				
				if(iWaitCount > 10 && bAllDoorTogglingInProgress)
					return
				endif
			endWhile
		endif
	endif
	
	bAllDoorTogglingInProgress = true
	bOpeningAllDoors = abOpen
	
	; Use an event to find all doors linked to the ref
	int iCallerID = Utility.RandomInt(0, 999999)
	
	if(EventKeyword_DoorFinder.SendStoryEventAndWait(akWorkshopRef.myLocation, aiValue1 = iCallerID))
		Utility.Wait(0.1) ; Give finder a moment to configure it's caller ID variable
		WorkshopFramework:Quests:DoorFinder DoorFinder = None
		int iQuestIndex = 0
		while(iQuestIndex < DoorFinders.Length && DoorFinder == None)
			if(DoorFinders[iQuestIndex].iCallerID == iCallerID)
				DoorFinder = DoorFinders[iQuestIndex]
			endif
			
			iQuestIndex += 1
		endWhile
		
		if(DoorFinder != None)
			int i = 0
			RefCollectionAlias FoundDoors = DoorFinder.SettlementDoors
			int iCount = FoundDoors.GetCount()
			while(i < iCount)
				ObjectReference thisDoor = FoundDoors.GetAt(i)
				if( ! thisDoor.IsDisabled())
					if( ! abOpen)
						if( ! thisDoor.HasKeyword(DoNotAutoCloseMe))
							thisDoor.SetOpen(false)
						endif
					else
						; Unregister temporarily to avoid a bunch of event spam
						UnregisterDoor(thisDoor)
						
						thisDoor.SetOpen(true)
						
						RegisterDoor(thisDoor)
					endif
				endif
				
				i += 1
			endWhile
			
			DoorFinder.Stop()
		endif
	endif
	
	bAllDoorTogglingInProgress = false	
EndFunction



Function RegisterAllDoors(WorkshopScript akWorkshopRef)
	if( ! akWorkshopRef)
		return
	endif
	
	int iWorkshopID = akWorkshopRef.GetWorkshopID()
	if(bDoorRegistrationInProgress[iWorkshopID])
		return
	endif
	
	bDoorRegistrationInProgress[iWorkshopID] = true
	
	; Use an event to find all doors linked to the ref
	int iCallerID = Utility.RandomInt(0, 999999)
	
	if(EventKeyword_DoorFinder.SendStoryEventAndWait(akWorkshopRef.myLocation, aiValue1 = iCallerID))
		Utility.Wait(0.1) ; Give finder a moment to configure it's caller ID variable
		WorkshopFramework:Quests:DoorFinder DoorFinder = None
		int iQuestIndex = 0
		while(iQuestIndex < DoorFinders.Length && DoorFinder == None)
			if(DoorFinders[iQuestIndex].iCallerID == iCallerID)
				DoorFinder = DoorFinders[iQuestIndex]
			endif
			
			iQuestIndex += 1
		endWhile
		
		if(DoorFinder != None)		
			int i = 0
			RefCollectionAlias FoundDoors = DoorFinder.SettlementDoors
			int iCount = FoundDoors.GetCount()
			
			while(i < iCount)
				ObjectReference thisDoor = FoundDoors.GetAt(i)
				if(thisDoor != None)
					RegisterDoor(thisDoor)
				endif
				
				i += 1
			endWhile
			
			; Clean up deleted doors
			RefCollectionAlias DisabledDoors = DoorFinder.DisabledDoors
			i = 0
			iCount = DisabledDoors.GetCount()
			while(i < iCount)
				ObjectReference thisDoor = FoundDoors.GetAt(i)
				if(thisDoor != None && thisDoor.IsDeleted())
					UnregisterDoor(thisDoor)
				endif
				
				i += 1
			endWhile
			
			DoorFinder.Stop()
		endif
	endif
	
	bDoorRegistrationInProgress[iWorkshopID] = false
	bDoorRegistrationCompleted[iWorkshopID] = true
EndFunction


Function SettingsUpdated()
	WorkshopScript kWorkshopRef = WorkshopFramework:WSFW_API.GetNearestWorkshop(PlayerRef)
	
	if(kWorkshopRef.Is3dLoaded())
		; Let's make sure events for this settlement are registered for and all doors are registered
		HandlePlayerEnteredSettlement(kWorkshopRef)
	endif
EndFunction