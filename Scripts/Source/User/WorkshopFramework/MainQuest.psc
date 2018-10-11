; ---------------------------------------------
; WorkshopFramework:MainQuest.psc - by kinggath
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

Scriptname WorkshopFramework:MainQuest extends WorkshopFramework:Library:MasterQuest

import WorkshopFramework:Library:DataStructures
import WorkshopFramework:Library:UtilityFunctions
import WorkshopFramework:WorkshopFunctions

CustomEvent PlayerEnteredSettlement
CustomEvent PlayerExitedSettlement

; ---------------------------------------------
; Consts
; ---------------------------------------------


; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------

Group Controllers
	WorkshopParentScript Property WorkshopParent Auto Const
EndGroup

Group Aliases
	ReferenceAlias Property LastWorkshopAlias Auto Const
EndGroup

Group FormLists
	FormList Property WorkshopParentExcludeFromAssignmentRules Auto Const Mandatory
	{ Point to the same list as WorkshopParent.ParentExcludeFromAssignmentRules }
EndGroup

Group Keywords
	Keyword Property LocationTypeWorkshop Auto Const
	Keyword Property LocationTypeSettlement Auto Const
EndGroup

Group Messages
	; 1.0.4 - Adding new message to explain why ClaimSettlement isn't working 
	Message Property CannotFindSettlement Auto Const
EndGroup

; ---------------------------------------------
; Properties
; ---------------------------------------------

Bool Property bFrameworkReady = false Auto Hidden
Bool Property bLastSettlementUnloaded = true Auto Hidden

; ---------------------------------------------
; Vars
; ---------------------------------------------

; ---------------------------------------------
; Events 
; ---------------------------------------------

; Extending to fire off settlement enter/exit events
Event OnTimer(Int aiTimerID)
	Parent.OnTimer(aiTimerID)
	
	if(aiTimerID == LocationChangeTimerID)
		Location kNewLoc = LatestLocation.GetLocation()
		if(kNewLoc.HasKeyword(LocationTypeWorkshop))
			Var[] kArgs
			
			WorkshopScript currentWorkshop = WorkshopParent.CurrentWorkshop.GetRef() as WorkshopScript
			; 1.0.4 - Added sanity check
			if( ! currentWorkshop || ! PlayerRef.IsWithinBuildableArea(currentWorkshop))
				; Check if player is in a different workshop - it can sometimes take a moment before WorkshopParent updates the CurrentWorkshop
				currentWorkshop = WorkshopFramework:WSFW_API.GetNearestWorkshop(PlayerRef)
			endif
			
			
			WorkshopScript lastWorkshop = LastWorkshopAlias.GetRef() as WorkshopScript
			Bool bCurrentWorkshopRefFound = true
			if( ! currentWorkshop)
				bCurrentWorkshopRefFound = false
			endif
			
			Bool bLastWorkshopRefFound = true
			if( ! lastWorkshop)
				bLastWorkshopRefFound = false
			endif			
			
			if( ! bLastWorkshopRefFound && bCurrentWorkshopRefFound) ; This should only happen once, after which there will always be a lastWorkshop stored in the alias
				LastWorkshopAlias.ForceRefTo(currentWorkshop)
			endif

			if(bLastWorkshopRefFound)
				Bool bLastWorkshopLoaded = lastWorkshop.GetCurrentLocation().IsLoaded()
				kArgs = new Var[2]
				kArgs[0] = lastWorkshop
				kArgs[1] = bLastWorkshopLoaded ; Scripts can use this to determine if the player has actually left or is maybe just hanging out around the edge of the settlement
				
				if(lastWorkshop != currentWorkshop && (bCurrentWorkshopRefFound || ! bLastSettlementUnloaded))
					; Workshop changed or they are no longer in a settlement
					if(bCurrentWorkshopRefFound)
						; Changed settlement - update our lastWorkshop record to store the currentWorkshop
						LastWorkshopAlias.ForceRefTo(currentWorkshop)
					endif
					
					if( ! bLastWorkshopLoaded)
						; Our previous settlement is no longer loaded in memory
						bLastSettlementUnloaded = true
					endif				
					
					SendCustomEvent("PlayerExitedSettlement", kArgs)
				else
					; Player changed location but is still in same settlement - don't send event					
				endif	
			endif
			
			if(bCurrentWorkshopRefFound && (lastWorkshop != currentWorkshop || bLastSettlementUnloaded))
				; Workshop changed or they are no longer in a settlement
				
				kArgs = new Var[3]
				kArgs[0] = currentWorkshop
				kArgs[1] = lastWorkshop
				kArgs[2] = bLastSettlementUnloaded ; If lastWorkshop == currentWorkshop && bLastSettlementUnloaded - it means the player traveled far enough to unload the last settlement, but never visited a new one in between
				
				SendCustomEvent("PlayerEnteredSettlement", kArgs)
				
				bLastSettlementUnloaded = false ; Since we've entered a settlement, the lastWorkshop is changing
			endif
		endif
	endif
EndEvent


Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)
    if(asMenuName== "WorkshopMenu")
		if(abOpening)
			WorkshopScript currentWorkshop = WorkshopParent.CurrentWorkshop.GetRef() as WorkshopScript
			WorkshopScript lastWorkshop = LastWorkshopAlias.GetRef() as WorkshopScript
			
			if(lastWorkshop != currentWorkshop)
				 ; If this happens, there is likely some serious script lag happening - but since LastWorkshopAlias is used throughout our code, we don't ever want it to be incorrect, so use this opportunity to correct it
				 if( ! PlayerRef.IsWithinBuildableArea(currentWorkshop))
					; Check if player is in a different workshop - it can sometimes take a moment before WorkshopParent updates the CurrentWorkshop
					currentWorkshop = WorkshopFramework:WSFW_API.GetNearestWorkshop(PlayerRef)
				endif
				
				if(currentWorkshop)
					LastWorkshopAlias.ForceRefTo(currentWorkshop)
				endif
			endif
		endif
	endif
EndEvent


; 1.0.1 - Need to ensure FillWSFWVars is filled - will also update each time the game starts in case we needed to add additional properties
Event Quest.OnStageSet(Quest akSenderRef, Int auiStageID, Int auiItemID)
	if(akSenderRef == WorkshopParent)
		WorkshopParent.FillWSFWVars()
		UnregisterForRemoteEvent(akSenderRef, "OnStageSet")
	endif
EndEvent

; ---------------------------------------------
; Extended Handlers
; ---------------------------------------------

Function HandleGameLoaded()
	; Make sure our debug log is open
	if(WorkshopParent.IsRunning())
		WorkshopParent.FillWSFWVars() ; Patch 1.0.1 - Eliminating all vanilla form edits and switching to GetFormFromFile
	else
		RegisterForRemoteEvent(WorkshopParent as Quest, "OnStageSet")
	endif
	
	WorkshopFramework:Library:UtilityFunctions.StartUserLog()
	
	Parent.HandleGameLoaded()
EndFunction


Function HandleQuestInit()
	Parent.HandleQuestInit()
	
	RegisterForMenuOpenCloseEvent("WorkshopMenu")
EndFunction

; ---------------------------------------------
; Overrides
; ---------------------------------------------

Bool Function StartQuests()
	bFrameworkReady = Parent.StartQuests()
	
	
	return bFrameworkReady
EndFunction

; Override parent function - to check for same location on the settlement type
Function HandleLocationChange(Location akNewLoc)
	if( ! akNewLoc)
		return
	endif
	
	Location lastParentLocation = LatestLocation.GetLocation()
	
	if( ! akNewLoc.IsSameLocation(lastParentLocation) || ! akNewLoc.IsSameLocation(lastParentLocation, LocationTypeSettlement))
		LatestLocation.ForceLocationTo(akNewLoc)
		StartTimer(1.0, LocationChangeTimerID)	
	endif	
EndFunction


; 1.0.4 - Adding method for players to claim a settlement, this will help players recover after the bug from 1.0.3 that could cause happiness to tank
Function ClaimSettlement(WorkshopScript akWorkshopRef = None)
	if( ! akWorkshopRef)
		akWorkshopRef = GetNearestWorkshop(PlayerRef)
	endif
	
	if(akWorkshopRef)
		akWorkshopRef.SetOwnedByPlayer(true)
	else
		CannotFindSettlement.Show()
	endif
EndFunction


; MCM Can't send None, so we're adding a wrapper
Function MCM_ClaimSettlement()
	ClaimSettlement(None)
EndFunction