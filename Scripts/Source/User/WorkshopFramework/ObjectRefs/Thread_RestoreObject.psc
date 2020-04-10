; ---------------------------------------------
; WorkshopFramework:ObjectRefs:Thread_RestoreObject.psc - by kinggath
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

Scriptname WorkshopFramework:ObjectRefs:Thread_RestoreObject extends WorkshopFramework:Library:ObjectRefs:Thread

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
WorldObject Property RestoreObjectData Auto Hidden

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
	; Check if object already exists
	if(RestoreObjectData == None || kWorkshopRef == None)
		return
	endif
	
	ObjectReference kPositionHelper = kWorkshopRef.PlaceAtMe(PositionHelper)
	kPositionHelper.SetPosition(RestoreObjectData.fPosX, RestoreObjectData.fPosY, RestoreObjectData.fPosZ)
	
	Form BaseForm = GetWorldObjectForm(RestoreObjectData)
	
	ObjectReference kFoundRef = Game.FindClosestReferenceOfTypeFromRef(BaseForm, kPositionHelper, 5.0)
	
	; If yes, can we restore it?
	Bool bCreateNew = true
	if(kFoundRef != None)
		if(kFoundRef.IsDisabled())
			kFoundRef.Enable(false)
			
			Utility.Wait(0.01)
			
			if( ! kFoundRef.IsDisabled())
				bCreateNew = false
			endif
		else
			bCreateNew = false
		endif
	endif
	
	; Can't find or can't restore, build a new one
	if(bCreateNew)
		PlaceObjectManager.CreateObject(RestoreObjectData, kWorkshopRef, abCallbackEventNeeded = false)
	endif
EndFunction