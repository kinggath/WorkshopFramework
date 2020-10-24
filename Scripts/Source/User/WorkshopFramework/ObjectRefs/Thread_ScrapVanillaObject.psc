; ---------------------------------------------
; WorkshopFramework:ObjectRefs:Thread_ScrapVanillaObject.psc - by kinggath
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

Scriptname WorkshopFramework:ObjectRefs:Thread_ScrapVanillaObject extends WorkshopFramework:Library:ObjectRefs:Thread

import WorkshopFramework:Library:DataStructures
import WorkshopFramework:Library:UtilityFunctions

; -
; Consts
; -


; - 
; Editor Properties
; -
WorkshopFramework:PlaceObjectManager Property PlaceObjectManager Auto Const Mandatory
Form Property PositionHelper Auto Const Mandatory

; -
; Properties
; -
WorkshopScript Property kWorkshopRef Auto Hidden
WorldObject Property ScrapObjectData Auto Hidden

; -
; Events
; -

; - 
; Functions 
; -
	
Function ReleaseObjectReferences()
	kWorkshopRef = None
EndFunction


Function RunCode()
	; Check if object exists
	ObjectReference kPositionHelper = kWorkshopRef.PlaceAtMe(PositionHelper)
	kPositionHelper.SetPosition(ScrapObjectData.fPosX, ScrapObjectData.fPosY, ScrapObjectData.fPosZ)
	
	Form BaseForm = GetWorldObjectForm(ScrapObjectData)
	
	ObjectReference kFoundRef = Game.FindClosestReferenceOfTypeFromRef(BaseForm, kPositionHelper, 5.0)
	
	; If found, is it already disabled?
	Bool bScrapNeeded = true
	if(kFoundRef != None)
		if(kFoundRef.IsDisabled())
			bScrapNeeded = false
		endif
	else
		bScrapNeeded = false
	endif
	
	; Found, scrap it
	if(bScrapNeeded)
		PlaceObjectManager.ScrapObject(kFoundRef, abCallbackEventNeeded = false)
	endif
EndFunction