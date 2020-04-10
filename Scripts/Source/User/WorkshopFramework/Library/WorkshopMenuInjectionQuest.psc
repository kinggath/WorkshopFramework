; ---------------------------------------------
; WorkshopFramework:Library:WorkshopMenuInjectionQuest.psc - by kinggath
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

Scriptname WorkshopFramework:Library:WorkshopMenuInjectionQuest extends WorkshopFramework:Library:SlaveQuest
{ Inject additional menus into the workshop menu system safely }


import WorkshopFramework:Library:DataStructures
import WorkshopFramework:Library:UtilityFunctions
import WorkshopFramework:WorkshopFunctions


; ---------------------------------------------
; Consts
; ---------------------------------------------

int iWorkshopMenuManagerFormID = 0x0001143E Const

; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------


Group MyMod
	WorkshopMenuInjection[] Property MyMenuInjections Auto Const
	{ Add an entry for each vanilla workshop menu you'd like to inject to. You do not need to enter sub-menus of your own menus here, since you can configure those custom formlists however you like. }
	GlobalVariable Property gMyModVersion Auto Const
	{ Create a Global form, start it at 1, and then increase that number each time you update your mod for release so that WorkshopFramework knows to re-inject your menus for any player who upgrades your mod. (This makes the code run much faster) }
EndGroup

; ---------------------------------------------
; Vars
; ---------------------------------------------

Int iMyInstalledVersion = 0
Bool bUpdateRegistrationsInProgress = false

WorkshopFramework:WorkshopMenuManager Property WorkshopMenuManager Auto Hidden

; ---------------------------------------------
; Events
; ---------------------------------------------


; ---------------------------------------------
; Event Handlers
; ---------------------------------------------

Function HandleQuestInit()
	if(Self == Game.GetFormFromFile(0x0001143F, "WorkshopFramework.esm") as Quest)
		; The template itself shouldn't be running
		Stop()
		
		return
	endif
	
	
	while( ! WorkshopMenuManager.IsRunning())
		Utility.Wait(1.0)
	endwhile
	
	Parent.HandleQuestInit()
	
	UpdateRegistrations()
EndFunction

Function HandleGameLoaded()
	UpdateVars()
	
	Parent.HandleGameLoaded()
	
	UpdateRegistrations()
EndFunction

; ---------------------------------------------
; Functions
; ---------------------------------------------

Function UpdateRegistrations()
	if(bUpdateRegistrationsInProgress || (gMyModVersion != None && iMyInstalledVersion >= gMyModVersion.GetValueInt()) || ! WorkshopMenuManager.IsRunning())
		return
	endif
	
	bUpdateRegistrationsInProgress = true
	
	int i = 0
	while(i < MyMenuInjections.Length)
		WorkshopMenuManager.RegisterMenu(MyMenuInjections[i])
		
		i += 1
	endWhile
	
	if(gMyModVersion != None)
		iMyInstalledVersion = gMyModVersion.GetValueInt()
	endif
	
	bUpdateRegistrationsInProgress = false
EndFunction


Function UpdateVars()
	if( ! WorkshopMenuManager)
		WorkshopMenuManager = Game.GetFormFromFile(iWorkshopMenuManagerFormID, "WorkshopFramework.esm") as WorkshopFramework:WorkshopMenuManager
	endif
EndFunction