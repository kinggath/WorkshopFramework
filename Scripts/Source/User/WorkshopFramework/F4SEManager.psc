; ---------------------------------------------
; WorkshopFramework:F4SEManager.psc - by kinggath
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

Scriptname WorkshopFramework:F4SEManager extends WorkshopFramework:Library:SlaveQuest Conditional
{ Acts as an interface to F4SE }

import WorkshopFramework:Library:DataStructures
import WorkshopFramework:Library:UtilityFunctions

; ---------------------------------------------
; Consts
; ---------------------------------------------

int iExpectedVersion_Major = 0 Const
int iExpectedVersion_Minor = 6 Const
int iExpectedVersion_Release = 12 Const

; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------

Group Settings
	GlobalVariable Property Setting_IgnoreF4SEVersion Auto Const Mandatory
EndGroup

; ---------------------------------------------
; Properties
; ---------------------------------------------

Bool bIsF4SERunning = false Conditional
Bool Property IsF4SERunning
	Bool Function Get()
		return bIsF4SERunning
	EndFunction
EndProperty

Int iVersion_Major = 0
Int iVersion_Minor = 0
Int iVersion_Release = 0


; ---------------------------------------------
; Vars
; ---------------------------------------------

; ---------------------------------------------
; Events 
; ---------------------------------------------

Function HandleGameLoaded()
	Parent.HandleGameLoaded()
	
	F4SERunningCheck()
EndFunction


; ---------------------------------------------
; Methods 
; ---------------------------------------------

Function F4SERunningCheck()
	bIsF4SERunning = false
	
	if(F4SE.GetVersion() > 0 || F4SE.GetVersionMinor() > 0)
		bIsF4SERunning = true
		iVersion_Major = F4SE.GetVersion()
		iVersion_Minor = F4SE.GetVersionMinor()
		iVersion_Release = F4SE.GetVersionRelease()
	endif
EndFunction


Bool Function F4SECheck()
	if( ! IsF4SERunning)
		return false
	endif
	
	if(Setting_IgnoreF4SEVersion.GetValueInt() == 1)
		return true
	else
		if(iVersion_Major == iExpectedVersion_Major && iVersion_Minor == iExpectedVersion_Minor && iVersion_Release == iExpectedVersion_Release)
			return true
		endif		
	endif
	
	return false
EndFunction


ObjectReference[] Function GetConnectedObjects(ObjectReference akObjectRef)
	if( ! F4SECheck())
		return None
	endif
	
	return akObjectRef.GetConnectedObjects()
EndFunction


ObjectReference Function AttachWire(ObjectReference akOriginRef, ObjectReference akTargetRef, Form akSpline = None)
	if( ! F4SECheck())
		return None
	endif
	
	return akOriginRef.AttachWire(akTargetRef, akSpline)
EndFunction

ObjectReference Function CreateWire(ObjectReference akOriginRef, ObjectReference akTargetRef, Form akSpline = None)
	if( ! F4SECheck())
		return None
	endif
	
	return akOriginRef.CreateWire(akTargetRef, akSpline)
EndFunction

Bool Function TransmitConnectedPower(ObjectReference akObjectRef)
	if( ! F4SECheck())
		return false
	endif
	
	return akObjectRef.TransmitConnectedPower()
EndFunction