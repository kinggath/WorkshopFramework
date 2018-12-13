; ---------------------------------------------
; WorkshopFramework:MessageManager.psc - by kinggath
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

Scriptname WorkshopFramework:MessageManager extends WorkshopFramework:Library:SlaveQuest
{ Handles Message display and queuing so we can avoid spamming the player or showing messages at inopportune times, such as when they are in combat or conversing with an NPC }

import WorkshopFramework:Library:DataStructures
import WorkshopFramework:Library:UtilityFunctions


; ------------------------------------------
; Consts
; ------------------------------------------

Int iTimerID_DialogueCheck = 100 Const
Float fTimerLength_DialogueCheck = 10.0 Const

; ------------------------------------------
; Editor Properties
; ------------------------------------------

Group Display
	GlobalVariable Property DisplayVar_MessageCount Auto Const Mandatory
	{ Used to update the holotape entry with the appropriate quest global }
EndGroup

Group Settings
	GlobalVariable Property Settings_QueueAllMessages Auto Const Mandatory
	GlobalVariable Property Settings_AutoPlayMessages Auto Const Mandatory
	{ Once the settings allow for message display again, any queued messages will be played automatically - otherwise the player will have to trigger them. TODO: Add a message queue icon to the HUD (email icon with a number) }
	GlobalVariable Property Settings_MessageBufferTime Auto Const Mandatory
	GlobalVariable Property Settings_SuppressMessages_DuringCombat Auto Const Mandatory
	GlobalVariable Property Settings_SuppressMessages_DuringDialogue Auto Const Mandatory
EndGroup

; ------------------------------------------
; Dynamic Properties
; ------------------------------------------

Bool Property bCanShowMessage
	Bool Function Get()
		if(Settings_QueueAllMessages.GetValue() == 1)
			return false
		else	
			if(PlayerRef.IsInCombat() && Settings_SuppressMessages_DuringCombat.GetValue() == 1)
				RegisterForRemoteEvent(PlayerRef, "OnCombatStateChanged")
				return false
			elseif(PlayerRef.GetDialogueTarget() != None && Settings_SuppressMessages_DuringDialogue.GetValue() == 1)
				StartTimer(fTimerLength_DialogueCheck, iTimerID_DialogueCheck)
				return false
			endif
		endif
		
		return true
	EndFunction
EndProperty


Int iMessageCount = 0
Int Property iQueuedMessages Hidden
	Int Function Get()
		return iMessageCount
	EndFunction
	
	Function Set(Int aiValue)
		iMessageCount = aiValue
		DisplayVar_MessageCount.SetValueInt(aiValue)	
		UpdateCurrentInstanceGlobal(DisplayVar_MessageCount)
	EndFunction
EndProperty

; ------------------------------------------
; Vars
; ------------------------------------------
Bool bProcessQueuesBlock = false

	; Should we allow for extended queues if the player wants them?
BasicMessage[] MessageQueue01
LocationMessage[] LocationMessageQueue01
AliasMessage[] AliasMessageQueue01
LocationAndAliasMessage[] LocationAndAliasMessageQueue01

; ------------------------------------------
; Events
; ------------------------------------------

Event OnTimer(Int aiTimerID)
	if(aiTimerID == iTimerID_DialogueCheck)
		if(PlayerRef.GetDialogueTarget() != None)
			StartTimer(fTimerLength_DialogueCheck, iTimerID_DialogueCheck)
		else
			TryToProcessMessageQueues()
		endif
	endif
EndEvent


Event Actor.OnCombatStateChanged(Actor akSender, Actor akTarget, int aeCombatState)
	if(akSender == PlayerRef)
		if(aeCombatState == 0)
			TryToProcessMessageQueues()
			UnregisterForRemoteEvent(PlayerRef, "OnCombatStateChanged")
		endif
	endif
EndEvent

; ------------------------------------------
; Handlers
; ------------------------------------------


; ------------------------------------------
; Functions
; ------------------------------------------

Function TestMessageQueue()
	BasicMessage thisMessage = new BasicMessage
	thisMessage.bmMessage = Game.GetFormFromFile(0x0000451E, "WorkshopFramework.esm") as Message
	
	QueueBasicMessage(thisMessage)
EndFunction

Function TryToProcessMessageQueues()
	if(bProcessQueuesBlock)
		return
	endif
		
	bProcessQueuesBlock = true

	; Check between queues in case something changes
	if(bCanShowMessage && Settings_AutoPlayMessages.GetValue() == 1)
		ProcessLocationAndAliasMessageQueue()
	endif
		
	if(bCanShowMessage && Settings_AutoPlayMessages.GetValue() == 1)
		ProcessLocationMessageQueue()
	endif
		
	if(bCanShowMessage && Settings_AutoPlayMessages.GetValue() == 1)
		ProcessAliasMessageQueue()
	endif
		
	if(bCanShowMessage && Settings_AutoPlayMessages.GetValue() == 1)
		ProcessMessageQueue()
	endif
	
	bProcessQueuesBlock = false
	
	; Additional messages queued up
	if(MessageQueue01.Length > 0 || AliasMessageQueue01.Length > 0 || LocationMessageQueue01.Length > 0 || LocationAndAliasMessageQueue01.Length > 0)
		TryToProcessMessageQueues()
	endif
EndFunction


Function ClearAllQueuedMessages()
	ClearMessageQueue()
	ClearAliasMessageQueue()
	ClearLocationMessageQueue()
	ClearLocationAndAliasMessageQueue()
EndFunction


Function DisplayAllQueuedMessages()
	while(DisplayNextQueuedMessage())
		; DisplayNextQueuedMessage will return false when it has finished
	endWhile
EndFunction

Bool Function DisplayNextQueuedMessage()
	if(LocationAndAliasMessageQueue01.Length > 0)
		ShowLocationAndAliasMessage(LocationAndAliasMessageQueue01[0], true)
		LocationAndAliasMessageQueue01.Remove(0)
		iQueuedMessages -= 1
		return true
	endif
	
	if(LocationMessageQueue01.Length > 0)
		ShowLocationMessage(LocationMessageQueue01[0], true)
		LocationMessageQueue01.Remove(0)
		iQueuedMessages -= 1
		return true
	endif
	
	if(AliasMessageQueue01.Length > 0)
		ShowAliasMessage(AliasMessageQueue01[0], true)
		AliasMessageQueue01.Remove(0)
		iQueuedMessages -= 1
		return true
	endif
	
	if(MessageQueue01.Length > 0)
		ShowBasicMessage(MessageQueue01[0], true)
		MessageQueue01.Remove(0)
		iQueuedMessages -= 1
		return true
	endif
	
	return false
EndFunction


Bool Function ShowMessage(Message aMessage, float afArg1 = 0.0, float afArg2 = 0.0, float afArg3 = 0.0, float afArg4 = 0.0, float afArg5 = 0.0, float afArg6 = 0.0, float afArg7 = 0.0, float afArg8 = 0.0, float afArg9 = 0.0, Quest akQuestRef = None, Int aiObjectiveID = -1, Int aiStageCheck = -1, Bool abForceShowNow = false)
	if(abForceShowNow || bCanShowMessage)
		aMessage.Show(afArg1, afArg2, afArg3, afArg4, afArg5, afArg6, afArg7, afArg8, afArg9)
		
		if(akQuestRef != None && aiObjectiveID >= 0)
			akQuestRef.SetObjectiveDisplayed(aiObjectiveID)
		endif
		
		return true
	else
		BasicMessage thisMessage = new BasicMessage
		thisMessage.bmMessage = aMessage
		thisMessage.fFloat01 = afArg1
		thisMessage.fFloat02 = afArg2
		thisMessage.fFloat03 = afArg3
		thisMessage.fFloat04 = afArg4
		thisMessage.fFloat05 = afArg5
		thisMessage.fFloat06 = afArg6
		thisMessage.fFloat07 = afArg7
		thisMessage.fFloat08 = afArg8
		thisMessage.fFloat09 = afArg9
		thisMessage.QuestRef = akQuestRef
		thisMessage.iObjectiveID = aiObjectiveID
		thisMessage.iStageCheck = aiStageCheck
		
		Debug.Trace("Param: " + akQuestRef + ", In Struct: " + thisMessage.QuestRef)
		
		QueueBasicMessage(thisMessage)
	endif
	
	return false
EndFunction


Bool Function ShowBasicMessage(BasicMessage aMessage, Bool abForceShowNow = false)
	if(abForceShowNow || bCanShowMessage)
		aMessage.bmMessage.Show(aMessage.fFloat01, aMessage.fFloat02, aMessage.fFloat03, aMessage.fFloat04, aMessage.fFloat05, aMessage.fFloat06, aMessage.fFloat07, aMessage.fFloat08, aMessage.fFloat09)
		
		if(aMessage.QuestRef != None && aMessage.iObjectiveID >= 0)
			if(aMessage.QuestRef.IsRunning() && (aMessage.iStageCheck < 0 || ! aMessage .QuestRef.GetStageDone(aMessage.iStageCheck)))
				aMessage.QuestRef.SetObjectiveDisplayed(aMessage.iObjectiveID)
			endif
		endif
		
		return true
	else
		QueueBasicMessage(aMessage)
	endif
	
	return false
EndFunction


Function QueueBasicMessage(BasicMessage aMessage)
	if(MessageQueue01.Length == 128)
		; Queue is full - pop a message
		ShowBasicMessage(MessageQueue01[0], true)
		MessageQueue01.Remove(0)
		; Don't reduce iQueuedMessages since we're about to add a replacement
	else
		iQueuedMessages += 1
	endif
	
	if( ! MessageQueue01)
		MessageQueue01 = new BasicMessage[0]
	endif
	
	MessageQueue01.Add(aMessage)
EndFunction


Function ProcessMessageQueue()
	; Process entire queue
	int i = MessageQueue01.Length
	Float fMessageBuffer = Settings_MessageBufferTime.GetValue()
	while(i > 0 && bCanShowMessage)
		Utility.Wait(fMessageBuffer)
		
		ShowBasicMessage(MessageQueue01[0], true)
		MessageQueue01.Remove(0)
		iQueuedMessages -= 1
		
		i -= 1
	endWhile
EndFunction


Function ClearMessageQueue()
	; So player can clear the queue
	MessageQueue01 = new BasicMessage[0]
EndFunction


;
; Alias Messages
;

Bool Function ShowAliasMessage(AliasMessage aMessage, Bool abForceShowNow = false)
	if(abForceShowNow || bCanShowMessage)
		if(aMessage.amAlias && aMessage.amObjectRef)
			aMessage.amAlias.ForceRefTo(aMessage.amObjectRef)
		endif
		
		aMessage.amMessage.Show(aMessage.fFloat01, aMessage.fFloat02, aMessage.fFloat03, aMessage.fFloat04, aMessage.fFloat05, aMessage.fFloat06, aMessage.fFloat07, aMessage.fFloat08, aMessage.fFloat09)
		
		if(aMessage.bAutoClearAlias)
			if(aMessage.amAlias)
				aMessage.amAlias.Clear()
			endif
		endif
				
		if(aMessage.QuestRef != None && aMessage.iObjectiveID >= 0)
			if(aMessage.QuestRef.IsRunning() && (aMessage.iStageCheck < 0 || ! aMessage .QuestRef.GetStageDone(aMessage.iStageCheck)))
				aMessage.QuestRef.SetObjectiveDisplayed(aMessage.iObjectiveID)
			endif
		endif
		
		return true
	else
		QueueAliasMessage(aMessage)
	endif
	
	return false
EndFunction


Function QueueAliasMessage(AliasMessage aMessage)
	if(AliasMessageQueue01.Length == 128)
		; Queue is full - pop a message
		ShowAliasMessage(AliasMessageQueue01[0], true)
		AliasMessageQueue01.Remove(0)
		; Don't reduce iQueuedMessages since we're about to add a replacement
	else
		iQueuedMessages += 1
	endif
	
	if( ! AliasMessageQueue01)
		AliasMessageQueue01 = new AliasMessage[0]
	endif
	
	AliasMessageQueue01.Add(aMessage)
EndFunction


Function ProcessAliasMessageQueue()
	; Process entire queue
	int i = AliasMessageQueue01.Length
	Float fMessageBuffer = Settings_MessageBufferTime.GetValue()
	while(i > 0 && bCanShowMessage)
		Utility.Wait(fMessageBuffer)
		
		ShowAliasMessage(AliasMessageQueue01[0], true)
		AliasMessageQueue01.Remove(0)
		iQueuedMessages -= 1
		
		i -= 1
	endWhile
EndFunction


Function ClearAliasMessageQueue()
	; So player can clear the queue
	AliasMessageQueue01 = new AliasMessage[0]
EndFunction


;
; Location Messages
;

Bool Function ShowLocationMessage(LocationMessage aMessage, Bool abForceShowNow = false)
	if(abForceShowNow || bCanShowMessage)
		if(aMessage.lmLocationAlias && aMessage.lmLocation)
			aMessage.lmLocationAlias.ForceLocationTo(aMessage.lmLocation)
		endif
		
		aMessage.lmMessage.Show(aMessage.fFloat01, aMessage.fFloat02, aMessage.fFloat03, aMessage.fFloat04, aMessage.fFloat05, aMessage.fFloat06, aMessage.fFloat07, aMessage.fFloat08, aMessage.fFloat09)
		
		if(aMessage.bAutoClearAlias)
			if(aMessage.lmLocationAlias)
				aMessage.lmLocationAlias.Clear()
			endif
		endif
		
		if(aMessage.QuestRef != None && aMessage.iObjectiveID >= 0)
			if(aMessage.QuestRef.IsRunning() && (aMessage.iStageCheck < 0 || ! aMessage .QuestRef.GetStageDone(aMessage.iStageCheck)))
				aMessage.QuestRef.SetObjectiveDisplayed(aMessage.iObjectiveID)
			endif
		endif
		
		return true
	else
		QueueLocationMessage(aMessage)
	endif
	
	return false
EndFunction


Function QueueLocationMessage(LocationMessage aMessage)
	if(LocationMessageQueue01.Length == 128)
		; Queue is full - pop a message
		ShowLocationMessage(LocationMessageQueue01[0], true)
		LocationMessageQueue01.Remove(0)
		; Don't reduce iQueuedMessages since we're about to add a replacement
	else
		iQueuedMessages += 1
	endif
	
	if( ! LocationMessageQueue01)
		LocationMessageQueue01 = new LocationMessage[0]
	endif
	
	LocationMessageQueue01.Add(aMessage)
EndFunction


Function ProcessLocationMessageQueue()
	; Process entire queue
	int i = LocationMessageQueue01.Length
	Float fMessageBuffer = Settings_MessageBufferTime.GetValue()
	while(i > 0 && bCanShowMessage)
		Utility.Wait(fMessageBuffer)
		
		ShowLocationMessage(LocationMessageQueue01[0], true)
		LocationMessageQueue01.Remove(0)
		iQueuedMessages -= 1
		
		i -= 1
	endWhile
EndFunction


Function ClearLocationMessageQueue()
	; So player can clear the queue
	LocationMessageQueue01 = new LocationMessage[0]
EndFunction



;
; LocationAndAlias Messages
;

Bool Function ShowLocationAndAliasMessage(LocationAndAliasMessage aMessage, Bool abForceShowNow = false)
	if(abForceShowNow || bCanShowMessage)
		if(aMessage.lamLocationAlias && aMessage.lamLocation)
			aMessage.lamLocationAlias.ForceLocationTo(aMessage.lamLocation)
		endif
		
		if(aMessage.lamAlias && aMessage.lamObjectRef)
			aMessage.lamAlias.ForceRefTo(aMessage.lamObjectRef)
		endif
		
		aMessage.lamMessage.Show(aMessage.fFloat01, aMessage.fFloat02, aMessage.fFloat03, aMessage.fFloat04, aMessage.fFloat05, aMessage.fFloat06, aMessage.fFloat07, aMessage.fFloat08, aMessage.fFloat09)
		
		if(aMessage.bAutoClearAlias)
			if(aMessage.lamLocationAlias)
				aMessage.lamLocationAlias.Clear()
			endif
			
			if(aMessage.lamAlias)
				aMessage.lamAlias.Clear()
			endif
		endif		
		
		if(aMessage.QuestRef != None && aMessage.iObjectiveID >= 0)
			if(aMessage.QuestRef.IsRunning() && (aMessage.iStageCheck < 0 || ! aMessage .QuestRef.GetStageDone(aMessage.iStageCheck)))
				aMessage.QuestRef.SetObjectiveDisplayed(aMessage.iObjectiveID)
			endif
		endif
		
		return true
	else
		QueueLocationAndAliasMessage(aMessage)
	endif
	
	return false
EndFunction


Function QueueLocationAndAliasMessage(LocationAndAliasMessage aMessage)
	if(LocationAndAliasMessageQueue01.Length == 128)
		; Queue is full - pop a message
		ShowLocationAndAliasMessage(LocationAndAliasMessageQueue01[0], true)
		LocationAndAliasMessageQueue01.Remove(0)
		; Don't reduce iQueuedMessages since we're about to add a replacement
	else
		iQueuedMessages += 1
	endif
	
	if( ! LocationAndAliasMessageQueue01)
		LocationAndAliasMessageQueue01 = new LocationAndAliasMessage[0]
	endif
	
	LocationAndAliasMessageQueue01.Add(aMessage)
EndFunction


Function ProcessLocationAndAliasMessageQueue()
	; Process entire queue
	int i = LocationAndAliasMessageQueue01.Length
	Float fMessageBuffer = Settings_MessageBufferTime.GetValue()
	while(i > 0 && bCanShowMessage)
		Utility.Wait(fMessageBuffer)
		
		ShowLocationAndAliasMessage(LocationAndAliasMessageQueue01[0])
		iQueuedMessages -= 1
		LocationAndAliasMessageQueue01.Remove(0)
		
		i -= 1
	endWhile
EndFunction


Function ClearLocationAndAliasMessageQueue()
	; So player can clear the queue
	LocationAndAliasMessageQueue01 = new LocationAndAliasMessage[0]
EndFunction