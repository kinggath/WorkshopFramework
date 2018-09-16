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
	Keyword Property LocationTypeSettlement Auto Const
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
		if(kNewLoc.HasKeyword(LocationTypeSettlement))
			Var[] kArgs
			
			WorkshopScript currentWorkshop = WorkshopParent.CurrentWorkshop.GetRef() as WorkshopScript
			WorkshopScript lastWorkshop = LastWorkshopAlias.GetRef() as WorkshopScript
			if( ! lastWorkshop && currentWorkshop) ; This should only happen once, after which there will always be a lastWorkshop stored in the alias
				LastWorkshopAlias.ForceRefTo(currentWorkshop)
			endif

			if(lastWorkshop)
				Bool bLastWorkshopLoaded = lastWorkshop.GetCurrentLocation().IsLoaded()
				kArgs = new Var[2]
				kArgs[0] = lastWorkshop
				kArgs[1] = bLastWorkshopLoaded ; Scripts can use this to determine if the player has actually left or is maybe just hanging out around the edge of the settlement
				
				if(lastWorkshop != currentWorkshop && (currentWorkshop || ! bLastSettlementUnloaded))
					; Workshop changed or they are no longer in a settlement
					if(currentWorkshop)
						LastWorkshopAlias.ForceRefTo(currentWorkshop)
					endif
					
					if( ! bLastWorkshopLoaded)
						bLastSettlementUnloaded = true
					endif				
					
					SendCustomEvent("PlayerExitedSettlement", kArgs)
				else
					; Player changed location but is still in same settlement - don't send event					
				endif	
			endif
			
			if(currentWorkshop && (lastWorkshop != currentWorkshop || bLastSettlementUnloaded))
				; Workshop changed or they are no longer in a settlement
				
				kArgs = new Var[2]
				kArgs[0] = currentWorkshop
				kArgs[1] = bLastSettlementUnloaded
				
				SendCustomEvent("PlayerEnteredSettlement", kArgs)
				
				bLastSettlementUnloaded = false
			endif
		endif
	endif
EndEvent

; ---------------------------------------------
; Extended Handlers
; ---------------------------------------------

Function HandleGameLoaded()
	; Make sure our debug log is open
	WorkshopFramework:Library:UtilityFunctions.StartUserLog()
	
	Parent.HandleGameLoaded()
EndFunction


Function HandleQuestInit()
	Parent.HandleQuestInit()
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
		StartTimer(fLocationChangeDelay, LocationChangeTimerID)	
	endif	
EndFunction