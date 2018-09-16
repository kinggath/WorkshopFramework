; ---------------------------------------------
; WorkshopFramework:Library:ObjectRefs:ThreadStarter.psc - by kinggath
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

Scriptname WorkshopFramework:Library:ObjectRefs:ThreadStarter extends ObjectReference

; -
; Consts
; -

Int MAXWAITCOUNT = 100 


; - 
; Editor Properties
; -

WorkshopFramework:Library:ThreadRunner[] Property ThreadRunners Auto Const


; -
; Properties
; - 

Int Property iThreadRunnerIndex Auto Hidden
String Property sFunction Auto Hidden
Var[] Property kArgs Auto Hidden
Bool Property bReadyToLaunch = false Auto Hidden

Int iWaitCount = 0

; -
; Events
; -

Event OnInit()
	StartTimer(0.1)
EndEvent


Event OnTimer(Int aiTimerID)
	if( ! bReadyToLaunch && iWaitCount < MAXWAITCOUNT)
		iWaitCount += 1
		StartTimer(0.1)
		return
	endif
	
	if(bReadyToLaunch)
		StartThread()
	else
		SelfDestruct()
	endif
EndEvent

; - 
; Functions 
; -

Function StartThread()
	ThreadRunners[iThreadRunnerIndex].CallFunctionNoWait(sFunction, kArgs)
	SelfDestruct()
EndFunction

Function SelfDestruct()
	Self.Disable(false)
	Self.Delete()
EndFunction