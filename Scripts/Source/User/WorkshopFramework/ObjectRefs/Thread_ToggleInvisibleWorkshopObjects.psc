; ---------------------------------------------
; WorkshopFramework:ObjectRefs:Thread_ToggleInvisibleWorkshopObjects.psc - by kinggath
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

Scriptname WorkshopFramework:ObjectRefs:Thread_ToggleInvisibleWorkshopObjects extends WorkshopFramework:Library:ObjectRefs:Thread

; -
; Consts
; -


; - 
; Editor Properties
; -


; -
; Properties
; -

Bool Property bInWorkshopMode Auto Hidden
ObjectReference[] Property kObjectRefs Auto Hidden

; -
; Events
; -

; - 
; Functions 
; -

	
Function ReleaseObjectReferences()
	kObjectRefs = None
EndFunction


Function RunCode()
	int i = 0
	while(i < kObjectRefs.Length)
		WorkshopFramework:ObjectRefs:InvisibleWorkshopObject asInvis = kObjectRefs[i] as WorkshopFramework:ObjectRefs:InvisibleWorkshopObject
		if(asInvis)
			asInvis.Toggle(bInWorkshopMode)
		endif
		
		i += 1
	endWhile
EndFunction