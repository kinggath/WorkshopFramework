; ---------------------------------------------
; WorkshopFramework:ObjectRefs:Thread_UpdateClutteredItems.psc - by kinggath
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

Scriptname WorkshopFramework:ObjectRefs:Thread_UpdateClutteredItems extends WorkshopFramework:Library:ObjectRefs:Thread

; -
; Consts
; -


; - 
; Editor Properties
; -


; -
; Properties
; -

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
		WorkshopFramework:ObjectRefs:ClutteredItem asCluttered = kObjectRefs[i] as WorkshopFramework:ObjectRefs:ClutteredItem
		if(asCluttered)
			asCluttered.DisplayClutter()
		endif
		
		i += 1
	endWhile
EndFunction


Function AddObject(ObjectReference akObjectRef)
	if(kObjectRefs == None || kObjectRefs.Length == 0)
		kObjectRefs = new ObjectReference[0]
	endif
	
	kObjectRefs.Add(akObjectRef)
EndFunction