; ---------------------------------------------
; WorkshopFramework:Library:StoryEventQuest.psc - by redbaron148
; ---------------------------------------------
; Reusage Rights ------------------------------
; You are free to use this script or portions of it in your own mods, provided you give me credit in your description and maintain this section of comments in any released source code (which includes the IMPORTED SCRIPT CREDIT section to give credit to anyone in the associated Import scripts below).
; 
; Warning !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
; Do not directly recompile this script for redistribution without first renaming it to avoid compatibility issues issues with the mod this came from.
; 
; IMPORTED SCRIPT CREDITS
; N/A
; ---------------------------------------------

Scriptname WorkshopFramework:Library:StoryEventQuest extends WorkshopFramework:Library:VersionedLockableQuest

import WorkshopFramework:Library:DataStructures
import WorkshopFramework:Library:UtilityFunctions

;-----------------------------------------------------------------------------------------
;------------------------------------ Custom Events --------------------------------------
;-----------------------------------------------------------------------------------------


;-----------------------------------------------------------------------------------------
;------------------------------------ Global Variables -----------------------------------
;-----------------------------------------------------------------------------------------
Int mintRequestCount = 0
Int mintStoryEventID = -1


;-----------------------------------------------------------------------------------------
;------------------------------------ ERROR Codes ----------------------------------------
;-----------------------------------------------------------------------------------------


;-----------------------------------------------------------------------------------------
;------------------------------------ Properties -----------------------------------------
;-----------------------------------------------------------------------------------------
Group REFERENCES
	WorkshopFramework:Quests:StoryEventManager Property StoryEventManagerQuest Auto Const Mandatory
	{ Story Event Manager parent quest }
EndGroup

Group BASE_PROPERTIES
	Int Property Timeout = 10 Auto Const
	{ Number of seconds after startup until the story event quest is forced to reset. }
	
	Bool Property Initialized = False Auto Hidden
	
	Int Property TimeoutTimerID = 1 AutoReadOnly Hidden
EndGroup


;-----------------------------------------------------------------------------------------
;------------------------------------ Overridable Functions ------------------------------
;-----------------------------------------------------------------------------------------
Function HandleStoryEvent(Keyword pkwdKeyword, Location plocLocation, ObjectReference pobjObject1, ObjectReference pobjObject2, Int pintValue1, Int pintValue2)
	;Override me!
EndFunction 

Function HandleRequested()
	;Override me!
EndFunction


;-----------------------------------------------------------------------------------------
;------------------------------------ Event Handling -------------------------------------
;-----------------------------------------------------------------------------------------
Event OnStoryScript(Keyword pkwdKeyword, Location plocLocation, ObjectReference pobjObject1, ObjectReference pobjObject2, Int pintValue1, Int pintValue2)
	mintStoryEventID = pintValue2
	ModTrace("HandleEvent:OnStoryScript(" + Self + ")")
	
	StartTimer(Timeout, TimeoutTimerID)
	
	String strStoryEventHash = StoryEventHash(pkwdKeyword, plocLocation, pobjObject1, pobjObject2, pintValue1, pintValue2)
	
	mintStoryEventID = StoryEventManagerQuest.RegisterStoryEventQuest(Self, strStoryEventHash)
	
	If mintStoryEventID >= 0
		HandleStoryEvent(pkwdKeyword, plocLocation, pobjObject1, pobjObject2, pintValue1, pintValue2)
		Initialized = True
	Else
		ModTrace("Failed to register helper quest with story event manager")
		Cleanup()
	EndIf
EndEvent

Event OnTimer(Int pintTimerId)
	ModTrace("HandleEvent:OnTimer(" + pintTimerId + ")")
	If pintTimerId == TimeoutTimerID
		If mintRequestCount > 0
			ModTrace("Request timedout before it could be disposed by it's requester", 2)
		Else
			ModTrace("Timedout, but no pending requesters... someone didn't dispose properly.", 1)
		EndIf
		Cleanup()
	EndIf
EndEvent


;-----------------------------------------------------------------------------------------
;------------------------------------ Private External Functions -------------------------
;-----------------------------------------------------------------------------------------
Function Requested()
	mintRequestCount += 1
	ModTrace("Requested() - " + mintRequestCount)
	HandleRequested()
EndFunction

Bool Function Dispose()
	mintRequestCount -= 1
	ModTrace("Dispose() - " + mintRequestCount)
	If mintRequestCount <= 0
		Cleanup()
		Return True
	EndIf
	Return False
EndFunction

Bool Function WaitForInitialization(Float pfltTimeout = 5.0)
	ModTrace("WaitForCompletion(" + pfltTimeout + ")")
	
	Float fltDuration = 0.0
	
	While !Initialized
		Utility.WaitMenuMode(0.1)
		fltDuration += 0.1
		
		If fltDuration >= pfltTimeout
			Return False
		EndIf
	EndWhile
	
	Return True
EndFunction


;-----------------------------------------------------------------------------------------
;------------------------------------ High-Level Internal Functions ----------------------
;-----------------------------------------------------------------------------------------

Function Cleanup()
	CancelTimer(TimeoutTimerID)
	Reset()
EndFunction


;-----------------------------------------------------------------------------------------
;------------------------------------ Low-level Internal Functions -----------------------
;-----------------------------------------------------------------------------------------