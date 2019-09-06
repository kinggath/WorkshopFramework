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

Int iTimerID_BuildableAreaCheck = 100
Float fTimerLength_BuildableAreaCheck = 3.0

; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------

Group Controllers
	WorkshopParentScript Property WorkshopParent Auto Const
	WorkshopTutorialScript Property TutorialQuest Auto Const
	{ 1.0.7 - Adding ability to control this quest }
	GlobalVariable Property Setting_WorkshopTutorialsEnabled Auto Const
	{ 1.0.7 - Toggle to track whether the tutorial messages were last turned on or off }
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
		Location kPreviousLoc = PreviousLocation.GetLocation()
		Location kNewLoc = LatestLocation.GetLocation()
		Bool bEnteringWorkshopLocation = false
		Bool bLeavingWorkshopLocation = false
		
		if(kNewLoc != None)
			if(kNewLoc.HasKeyword(LocationTypeWorkshop))
				bEnteringWorkshopLocation = true
			endif
		endif
		
		if(kPreviousLoc != None)
			if(kPreviousLoc.HasKeyword(LocationTypeWorkshop))
				bLeavingWorkshopLocation = true
			endif
		endif
		
		if(bEnteringWorkshopLocation || bLeavingWorkshopLocation)
			Var[] kArgs
			
			WorkshopScript currentWorkshop = WorkshopParent.GetWorkshopFromLocation(PlayerRef.GetCurrentLocation())
			; 1.0.4 - Added sanity check
			if( ! currentWorkshop || ! PlayerRef.IsWithinBuildableArea(currentWorkshop))
				; Check if player is in a different workshop - it can sometimes take a moment before WorkshopParent updates the CurrentWorkshop
				currentWorkshop = WorkshopFramework:WSFW_API.GetNearestWorkshop(PlayerRef)
				
				if(bLeavingWorkshopLocation && ! bEnteringWorkshopLocation && currentWorkshop && ! PlayerRef.IsWithinBuildableArea(currentWorkshop))
					currentWorkshop = None
				else
					if(currentWorkshop.myLocation != None)
						; Player is in limbo area - it is not flagged as part of a specific location (likely just the overworld location - ie. Commonwealth) and so another LocationChange event isn't likely to fire - so instead we'll do a 5 second repeating loop to check if they returned to the location tagged part of the settlement or are out of the build area
						StartTimer(fTimerLength_BuildableAreaCheck, iTimerID_BuildableAreaCheck)
						
						; Update Latest Location so the next change will correctly be aware the player was previously in a settlement
						LatestLocation.ForceLocationTo(currentWorkshop.myLocation)
					else
						; Player is not in limbo area
						CancelTimer(iTimerID_BuildableAreaCheck)
					endif
				endif
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
			
			;Debug.Trace(">>>>>>>>>>>>>>>> bLastWorkshopRefFound: " + bLastWorkshopRefFound + ", kPreviousLoc: " + kPreviousLoc + ", kNewLoc: " + kNewLoc + ", lastWorkshop: " + lastWorkshop + ", currentWorkshop: " + currentWorkshop + ", bCurrentWorkshopRefFound: " + bCurrentWorkshopRefFound + ", bLastSettlementUnloaded: " + bLastSettlementUnloaded)
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
			
			if(bCurrentWorkshopRefFound)
				; Workshop changed or previous settlement unloaded
				kArgs = new Var[3]
				kArgs[0] = currentWorkshop
				kArgs[1] = lastWorkshop
				kArgs[2] = bLastSettlementUnloaded ; If lastWorkshop == currentWorkshop && bLastSettlementUnloaded - it means the player traveled far enough to unload the last settlement, but never visited a new one in between
				
				SendCustomEvent("PlayerEnteredSettlement", kArgs)
				
				bLastSettlementUnloaded = false ; Since we've entered a settlement, the lastWorkshop is changing
			endif
		endif
	elseif(aiTimerID == iTimerID_BuildableAreaCheck)
		WorkshopScript currentWorkshop = WorkshopFramework:WSFW_API.GetNearestWorkshop(PlayerRef)
		Location PlayerLocation = PlayerRef.GetCurrentLocation()
		
		if(currentWorkshop && PlayerRef.IsWithinBuildableArea(currentWorkshop))
			if(currentWorkshop.myLocation && currentWorkshop.myLocation != PlayerLocation)
				; Player is in a limbo area of a settlement not flagged as part of the settlement - repeat this loop
				StartTimer(fTimerLength_BuildableAreaCheck, iTimerID_BuildableAreaCheck)
			endif
		else
			LatestLocation.ForceLocationTo(PlayerLocation)
			; Player probably exited settlement
			Bool bLastWorkshopLoaded = currentWorkshop.GetCurrentLocation().IsLoaded()
			Var[] kArgs = new Var[2]
			kArgs[0] = currentWorkshop
			kArgs[1] = bLastWorkshopLoaded ; Scripts can use this to determine if the player has actually left or is maybe just hanging out around the edge of the settlement
			
			SendCustomEvent("PlayerExitedSettlement", kArgs)
		endif			
	endif
EndEvent


Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)
    if(asMenuName == "WorkshopMenu")
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
;/
1.1.0 - Removed this block as you can't override remote event blocks, instead we've switched to calling a handler function from the parent quest so we can override that
Event Quest.OnStageSet(Quest akSenderRef, Int auiStageID, Int auiItemID)
	if(akSenderRef == WorkshopParent)
		WorkshopParent.FillWSFWVars()
	endif
EndEvent
/;

; ---------------------------------------------
; Extended Handlers
; ---------------------------------------------

Function HandleGameLoaded()
	ModTrace("[WSFW] >>>>>>>>>>>>>>>>> HandleGameLoaded called on WSFW MainQuest")
	; Make sure our debug log is open
	if(WorkshopParent.IsRunning())
		WorkshopParent.FillWSFWVars() ; Patch 1.0.1 - Eliminating all vanilla form edits and switching to GetFormFromFile
	else
		RegisterForRemoteEvent(WorkshopParent as Quest, "OnStageSet")
	endif
	
	WorkshopFramework:Library:UtilityFunctions.StartUserLog()
	
	ModTrace("[WSFW] >>>>>>>>>>>>>>>>> Calling HandleGameLoaded on Parent of WSFW MainQuest")
	Parent.HandleGameLoaded()
EndFunction


Function HandleQuestInit()
	Parent.HandleQuestInit()
	
	RegisterForMenuOpenCloseEvent("WorkshopMenu")
EndFunction


Function HandleStageSet(Quest akQuestRef, int auiStageID, int auiItemID)
	ModTrace("[WSFW] >>>>>>>>>>>>>>>>>>> Quest event received on WSFW Main: " + akQuestRef + " reached stage " + auiStageID)
	if(akQuestRef == WorkshopParent)
		WorkshopParent.FillWSFWVars()
	endif
	
	Parent.HandleStageSet(akQuestRef, auiStageID, auiItemID)
EndFunction


; ---------------------------------------------
; Overrides
; ---------------------------------------------

Bool Function StartQuests()
	ModTrace("[WSFW] >>>>>>>>>>>>>>>>> WSFW MainQuest.StartQuests called.")
	bFrameworkReady = Parent.StartQuests()
	
	
	return bFrameworkReady
EndFunction

; Override parent function - to check for same location on the settlement type
Function HandleLocationChange(Location akNewLoc)
	Location lastParentLocation = LatestLocation.GetLocation()
	
	; Always proceed if buildable area check is running - as that indicates the player entered a limbo zone where they were within settlement bounds that were not tagged with the correct location
	if(akNewLoc == None || lastParentLocation == None || ! akNewLoc.IsSameLocation(lastParentLocation) || ! akNewLoc.IsSameLocation(lastParentLocation, LocationTypeSettlement))
		if(lastParentLocation == None)
			PreviousLocation.Clear() ; 1.1.9
		else
			PreviousLocation.ForceLocationTo(lastParentLocation) ; 1.1.7			
		endif
		
		if(akNewLoc == None)
			LatestLocation.Clear()
		else
			LatestLocation.ForceLocationTo(akNewLoc)
		endif
		
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

; 1.0.7 - Adding option to toggle Workshop Tutorials
Function DisableWorkshopTutorials()
	TutorialQuest.UnregisterForCustomEvent(WorkshopParent, "WorkshopObjectBuilt")
	TutorialQuest.UnregisterForCustomEvent(WorkshopParent, "WorkshopObjectMoved")
	TutorialQuest.UnregisterForCustomEvent(WorkshopParent, "WorkshopObjectDestroyed")
	TutorialQuest.UnregisterForCustomEvent(WorkshopParent, "WorkshopActorAssignedToWork")
	TutorialQuest.UnregisterForCustomEvent(WorkshopParent, "WorkshopActorUnassigned")
	TutorialQuest.UnregisterForCustomEvent(WorkshopParent, "WorkshopObjectDestructionStageChanged")
	TutorialQuest.UnregisterForCustomEvent(WorkshopParent, "WorkshopObjectPowerStageChanged")
	TutorialQuest.UnregisterForCustomEvent(WorkshopParent, "WorkshopEnterMenu")
	
	; Stop any existing help messages
	int i = 0
	while(i < TutorialQuest.TutorialSteps.Length)
		if(TutorialQuest.TutorialSteps[i].HelpMessage)
			TutorialQuest.TutorialSteps[i].HelpMessage.UnshowAsHelpMessage()
		endif
		
		i += 1
	endWhile
EndFunction

; 1.0.7 - Adding option to toggle Workshop Tutorials
Function EnableWorkshopTutorials()
	TutorialQuest.InitializeQuest()
	
	; Reset all of the tutorials
	int i = 0
	while(i < TutorialQuest.Tutorials.Length)
		TutorialQuest.RollBackTutorial(TutorialQuest.Tutorials[i])
		
		i += 1
	endWhile
EndFunction


; MCM Can't send None, so we're adding a wrapper
Function MCM_ClaimSettlement()
	ClaimSettlement(None)
EndFunction


Function MCM_ToggleWorkshopTutorials()
	if(Setting_WorkshopTutorialsEnabled.GetValue() == 1.0)
		EnableWorkshopTutorials()
	else
		DisableWorkshopTutorials()
	endif
EndFunction