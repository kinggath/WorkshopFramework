; ---------------------------------------------
; WorkshopFramework:Library:ControlledQuest.psc - by kinggath
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


Scriptname WorkshopFramework:Library:VersionedLockableQuest extends WorkshopFramework:Library:LockableQuest
{ This quest has version control }

; ------------------------------------------
; Consts
; ------------------------------------------


; ------------------------------------------
; Editor Properties
; ------------------------------------------

Group Globals
	GlobalVariable Property gCurrentVersion Auto Const Mandatory
	{ Point to mod's version control global }
EndGroup


; ------------------------------------------
; Vars
; ------------------------------------------

int Property iInstalledVersion = 0 Auto Hidden


; ------------------------------------------
; Events
; ------------------------------------------


; ------------------------------------------
; Maintenance Functions
; ------------------------------------------

Function InstallModChanges()
	HandleInstallModChanges()
	
	iInstalledVersion = gCurrentVersion.GetValueInt()
EndFunction


; ------------------------------------------
; Handler Functions - These should be written by the extended scripts that use them
; ------------------------------------------

Function HandleGameLoaded()
	Parent.HandleGameLoaded()
	if(iInstalledVersion < gCurrentVersion.GetValueInt())
		if(iInstalledVersion > 0)
			InstallModChanges()
		else
			iInstalledVersion = gCurrentVersion.GetValueInt()
		endif
	endif
EndFunction


Function HandleInstallModChanges()
	; Use format:
	; if(iInstalledVersion < X)
	;      ; Make changes
	; endif
EndFunction