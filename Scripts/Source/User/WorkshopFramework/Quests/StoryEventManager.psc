; ---------------------------------------------
; WorkshopFramework:Quests:StoryEventManager.psc - by redbaron148
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

Scriptname WorkshopFramework:Quests:StoryEventManager extends WorkshopFramework:Library:SlaveQuest Conditional

import WorkshopFramework:Library:DataStructures
import WorkshopFramework:Library:UtilityFunctions

;-----------------------------------------------------------------------------------------
;------------------------------------ Custom Events --------------------------------------
;-----------------------------------------------------------------------------------------


;-----------------------------------------------------------------------------------------
;------------------------------------ Global Variables -----------------------------------
;-----------------------------------------------------------------------------------------
StoryEventRequestStruct[] marrRequests
Int mintNextStoryEventID = 1


;-----------------------------------------------------------------------------------------
;------------------------------------ ERROR Codes ----------------------------------------
;-----------------------------------------------------------------------------------------
Int Property ERC_NO_EVENT_QUEST_FOUND = -1 AutoReadOnly Hidden
Int Property ERC_STORY_EVENT_FAILURE = -2 AutoReadOnly Hidden
Int Property ERC_SEQ_QUEUE_FULL = -3 AutoReadOnly Hidden


;-----------------------------------------------------------------------------------------
;------------------------------------ Properties -----------------------------------------
;-----------------------------------------------------------------------------------------
Int Property _NextStoryEventID Hidden
    Int Function Get()
        Int intNextStoryEventID = mintNextStoryEventID
        
        mintNextStoryEventID += 1
        
        Return intNextStoryEventID
    EndFunction
EndProperty

;-----------------------------------------------------------------------------------------
;------------------------------------ Extended Parent Functions --------------------------
;-----------------------------------------------------------------------------------------
Function HandleQuestInit()
	Parent.HandleQuestInit()
		
	marrRequests = New StoryEventRequestStruct[0]
EndFunction


;-----------------------------------------------------------------------------------------
;------------------------------------ Overridable Functions ------------------------------
;-----------------------------------------------------------------------------------------


;-----------------------------------------------------------------------------------------
;------------------------------------ Event Handling -------------------------------------
;-----------------------------------------------------------------------------------------
Event Quest.OnQuestShutdown(Quest pqstQuest)
	UnregisterForRemoteEvent(pqstQuest, "OnQuestShutdown")
	
	WorkshopFramework:Library:StoryEventQuest seqFulfiller = pqstQuest as WorkshopFramework:Library:StoryEventQuest
	
	Int intReqPos = marrRequests.FindStruct("Fulfiller", seqFulfiller)
	
	If intReqPos >= 0
		marrRequests.Remove(intReqPos)
	EndIf
EndEvent


;-----------------------------------------------------------------------------------------
;------------------------------------ API Functions --------------------------------------
;-----------------------------------------------------------------------------------------
WorkshopFramework:Library:StoryEventQuest Function WSFW_API_SendStoryEvent(Keyword pkwdKeyword, Location plocLocation = None, ObjectReference pobjObject1 = None, ObjectReference pobjObject2 = None, Int pintValue1 = 0, Int pintValue2 = 0, Float pfltTimeout = 5.0)
	ModTrace("WSFW_API_SendStoryEvent(" + pkwdKeyword + ", " + plocLocation + ", " + pobjObject1 + ", " + pobjObject2 + ", " + pintValue1 + ", " + pintValue2 + ", " + pfltTimeout + ")")
	
	StoryEventRequestStruct vntRequest
	
	;Story event hashes effectively serve as the identifier for the event. Use the hash to form a queue and reply to all waiting on completion.
	;The theory being the same story event call should result in the same return...
	String strStoryEventHash = StoryEventHash(pkwdKeyword, plocLocation, pobjObject1, pobjObject2, pintValue1, pintValue2)
	
	Int intLockKey = GetLock()
	
	If intLockKey < 0
		Return None
	EndIf
	
	Int intResult
	
	Int intReqPos = marrRequests.FindStruct("StoryEventHash", strStoryEventHash)
	
	If intReqPos < 0 ;Story event has not been queued
		If marrRequests.Length < 128
			vntRequest = new StoryEventRequestStruct
			vntRequest.StoryEventHash = strStoryEventHash
			vntRequest.ThreadID = _NextStoryEventID
			marrRequests.Add(vntRequest)
			
			If !pkwdKeyword.SendStoryEventAndWait(plocLocation, pobjObject1, pobjObject2, pintValue1, pintValue2)
				ModTrace("  Failed to start story event quest!", 2)
				intReqPos = marrRequests.FindStruct("ThreadID", vntRequest.ThreadID)
				marrRequests.Remove(intReqPos)
				intResult = ERC_STORY_EVENT_FAILURE
			EndIf
		Else
			intResult = ERC_SEQ_QUEUE_FULL
		EndIf
	Else
		vntRequest = marrRequests[intReqPos]
	EndIf
	
	ReleaseLock(intLockKey)
	
	If intResult < 0
		Return None
	EndIf
	
	Float fltDuration = 0
	While !vntRequest.Fulfiller
		ModTrace("  Waiting for fulfiller to register...")
		Utility.WaitMenuMode(0.1)
		fltDuration += 0.1
		
		If fltDuration >= pfltTimeout
			ModTrace("  Story event registration timedout...", 2)
			Return None
		EndIf
	EndWhile
	
	If vntRequest.Fulfiller
		vntRequest.Fulfiller.Requested()
	
		Return vntRequest.Fulfiller
	Else
		Return None
	EndIf
EndFunction 


;-----------------------------------------------------------------------------------------
;------------------------------------ Private External Functions -------------------------
;-----------------------------------------------------------------------------------------
Int Function RegisterStoryEventQuest(WorkshopFramework:Library:StoryEventQuest pqstHQStoryEventQuest, String pstrStoryEventHash)
	ModTrace("RegisterStoryEventQuest(" + pqstHQStoryEventQuest + ", " + pstrStoryEventHash + ")")
	
	Int intReqPos = marrRequests.FindStruct("StoryEventHash", pstrStoryEventHash)
	
	If intReqPos >= 0
		marrRequests[intReqPos].Fulfiller = pqstHQStoryEventQuest
		RegisterForRemoteEvent(pqstHQStoryEventQuest, "OnQuestShutdown")
		Return marrRequests[intReqPos].ThreadID
	Else
		Return ERC_NO_EVENT_QUEST_FOUND
	EndIf
EndFunction


;-----------------------------------------------------------------------------------------
;------------------------------------ High-Level Internal Functions ----------------------
;-----------------------------------------------------------------------------------------


;-----------------------------------------------------------------------------------------
;------------------------------------ Low-level Internal Functions -----------------------
;-----------------------------------------------------------------------------------------