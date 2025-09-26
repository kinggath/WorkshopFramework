; ---------------------------------------------
; WorkshopFramework:Library:ObjectRefs:Thread.psc - by kinggath
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

Scriptname WorkshopFramework:Library:ObjectRefs:Thread extends ObjectReference

CustomEvent ThreadRunComplete

; -
; Consts
; -
int SelfDestructTimerID = 0

; - 
; Editor Properties
; -

; -
; Properties
; - 
Bool Property bAutoDestroy = true Auto Hidden ; Note: When turning off AutoDestroy - you are in charge of calling SelfDestruct on this thread when you are done
Int Property iCallBackID = -1 Auto Hidden
String Property sCustomCallbackID = "" Auto Hidden

; -
; Events
; -

Event OnTimer(Int aiTimerID)
	if(aiTimerID == SelfDestructTimerID)
		if(bAutoDestroy) ; 1.0.5 - without this, we can't have the threads turn off their own self destruct to delay for events
			SelfDestruct()
		endif
	endif
EndEvent

; - 
; Functions 
; -

Function StartThread()
	RunCode()	
	
	Var[] kArgs = new Var[2]
	
	kArgs[0] = sCustomCallbackID
	kArgs[1] = iCallBackID
	
	SendCustomEvent("ThreadRunComplete", kArgs)
	
	
	if(bAutoDestroy)
		if(IsBoundGameObjectAvailable())
			StartTimer(3.0)
		else
			ReleaseObjectReferences()
		endif
	endif
EndFunction

Function SelfDestruct()
	ReleaseObjectReferences()
	
	Disable(false)
	Delete()
EndFunction

Function RunCode()
	; Extend me
EndFunction

Function ReleaseObjectReferences()
	; Implement Me - any global variables that you stored an object reference in need to be set to none or that reference and this thread will be permanently persisted causing a memory leak!
EndFunction