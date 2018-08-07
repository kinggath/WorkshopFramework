; ---------------------------------------------
; WorkshopFramework:Library:ControllerQuest.psc - by kinggath
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

Scriptname WorkshopFramework:Library:ControllerQuest extends Quest
{ Quest designed to manage certain aspects of the gameplay loop }

; -----------------------------------------
; Consts
; -----------------------------------------


; -----------------------------------------
; Editor Properties
; -----------------------------------------

Group Controllers
	Actor Property PlayerRef Auto Const Mandatory
EndGroup

; -----------------------------------------
; Vars
; -----------------------------------------


; -----------------------------------------
; Events
; ----------------------------------------- 

Event OnQuestInit()
	; Run one-time initialization tasks
	RegisterForRemoteEvent(PlayerRef, "OnPlayerLoadGame")
	
	HandleQuestInit()
	
	; Run GameLoaded code
	GameLoaded()
EndEvent


Event Actor.OnPlayerLoadGame(Actor akActorRef)  
	; Run GameLoaded code
	GameLoaded()
EndEvent

; -----------------------------------------
; Functions
; -----------------------------------------

Function GameLoaded()
	HandleGameLoaded()
EndFunction

; -----------------------------------------
; Handler Functions - These should be written by the extended scripts that use them
; -----------------------------------------

Function HandleQuestInit()
	; Extend Me
EndFunction

Function HandleGameLoaded()
	; Extend Me
EndFunction