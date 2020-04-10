; ---------------------------------------------
; WorkshopFramework:Library:SettlementLayoutRegistrationQuest.psc - by kinggath
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

Scriptname WorkshopFramework:Library:SettlementLayoutRegistrationQuest extends Quest
{ Register your Settlement Layouts with WorkshopFramework so players can select them. }


import WorkshopFramework:Library:DataStructures
import WorkshopFramework:Library:UtilityFunctions
import WorkshopFramework:WorkshopFunctions


; ---------------------------------------------
; Consts
; ---------------------------------------------

int iSettlementLayoutManagerFormID = 0x00012B0D Const

; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------

Group MyMod
	Formlist Property MySettlementLayoutsList Auto Const Mandatory
	GlobalVariable Property gMyModVersion Auto Const
	{ Create a Global form, start it at 1, and then increase that number each time you update your mod for release so that WorkshopFramework knows to register new layouts for any player who upgrades your mod. (This makes the code run much faster) }
EndGroup

; ---------------------------------------------
; Vars
; ---------------------------------------------

Int iMyInstalledVersion = 0
Bool bUpdateRegistrationsInProgress = false
Actor PlayerRef


WorkshopFramework:SettlementLayoutManager Property SettlementLayoutManager Auto Hidden

; ---------------------------------------------
; Events
; ---------------------------------------------

Event OnQuestInit()
	if(Self == Game.GetFormFromFile(0x00014980, "WorkshopFramework.esm") as Quest)
		; The template itself shouldn't be running
		Stop()
		
		return
	endif
	
	PlayerRef = Game.GetPlayer() as Actor
	
	HandleGameLoaded()
	
	RegisterForRemoteEvent(PlayerRef, "OnPlayerLoadGame")
EndEvent

Event Actor.OnPlayerLoadGame(Actor akSender)
	HandleGameLoaded()
EndEvent

; ---------------------------------------------
; Event Handlers
; ---------------------------------------------

Function HandleGameLoaded()
	UpdateVars()
	UpdateRegistrations()
EndFunction

; ---------------------------------------------
; Functions
; ---------------------------------------------

Function UpdateRegistrations()
	if(bUpdateRegistrationsInProgress || (gMyModVersion != None && iMyInstalledVersion >= gMyModVersion.GetValueInt()))
		return
	endif
	
	Formlist SettlementLayoutList = SettlementLayoutManager.SettlementLayoutList
	
	if(MySettlementLayoutsList != None)
		int i = 0
		int iCount = MySettlementLayoutsList.GetSize()
		while(i < iCount)
			; For now we'll inject the layouts directly in the formlist to avoid overwhelming SettlementLayoutManager quest
			Form thisForm = MySettlementLayoutsList.GetAt(i)
			SettlementLayoutList.AddForm(thisForm)
			
			i += 1
		endWhile
	endif
	
	if(gMyModVersion != None)
		iMyInstalledVersion = gMyModVersion.GetValueInt()
	endif
EndFunction


Function UpdateVars()
	if( ! SettlementLayoutManager)
		SettlementLayoutManager = Game.GetFormFromFile(iSettlementLayoutManagerFormID, "WorkshopFramework.esm") as WorkshopFramework:SettlementLayoutManager
	endif
EndFunction