; ---------------------------------------------
; WorkshopFramework:Library:ObjectRefs:ProtectedWorkshopObjectScript.psc - by kinggath
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

Scriptname WorkshopFramework:Library:ObjectRefs:ProtectedWorkshopObjectScript extends WorkshopFramework:Library:ObjectRefs:LockableWorkshopObjectScript

Bool bAllowDisable = false
Bool bAllowDelete = false

Function AllowDisable()
	bAllowDisable = true
EndFunction

Function AllowDelete()
	bAllowDelete = true
EndFunction

Function Disable(Bool abFade = false)
	if( ! bAllowDisable)
		; Do nothing - overriding vanilla behaviort to avoid these being destroyed
		
		return
	endif
	
	Parent.Disable(abFade)
EndFunction

Function Delete()
	if( ! bAllowDelete)
		; Do nothing - overriding vanilla behaviort to avoid these being destroyed
		
		return
	endif
	
	Parent.Delete()
EndFunction