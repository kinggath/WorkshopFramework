; ---------------------------------------------
; WorkshopFramework:WorkshopObjectManager.psc - by kinggath
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

Scriptname WorkshopFramework:WorkshopObjectManager extends WorkshopFramework:Library:SlaveQuest
{ Handles special types of Workshop Objects that need management }


import WorkshopFramework:Library:DataStructures
import WorkshopFramework:Library:UtilityFunctions
import WorkshopFramework:WorkshopFunctions


; ---------------------------------------------
; Consts
; ---------------------------------------------

int iBatchSize = 10 ; Every X items found will be threaded out
int iMinCountForThreading = 30 ; Must find at least this many items before we bother threading

; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------

Group Controllers
	WorkshopFramework:MainThreadManager Property ThreadManager Auto Const Mandatory
	; TODO - Global to allow players to set Invis to never appear in workshop mode
EndGroup

Group Assets
	Form Property Thread_ToggleInvisibleWorkshopObjects Auto Const Mandatory
EndGroup

Group Keywords
	Keyword Property InvisibleWorkshopObjectKeyword Auto Const Mandatory
EndGroup

; ---------------------------------------------
; Vars
; ---------------------------------------------


; ---------------------------------------------
; Events
; ---------------------------------------------

Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)
    if(asMenuName== "WorkshopMenu")
		ToggleInvisibleWorkshopObjects(abOpening)
	endif
EndEvent


; ---------------------------------------------
; Event Handlers
; ---------------------------------------------

Function HandleQuestInit()
	Parent.HandleQuestInit()
	
	RegisterForMenuOpenCloseEvent("WorkshopMenu")
EndFunction

; ---------------------------------------------
; Functions
; ---------------------------------------------

Function ToggleInvisibleWorkshopObjects(Bool abOpening)
	WorkshopScript thisWorkshop = GetNearestWorkshop(PlayerRef)
	ObjectReference[] kInvisibleObjects = thisWorkshop.FindAllReferencesWithKeyword(InvisibleWorkshopObjectKeyword, 20000.0)
	
	int iTotal = kInvisibleObjects.Length
	
	if(iTotal > iMinCountForThreading)
		int i = 0
		while(i < iTotal)
			WorkshopFramework:ObjectRefs:Thread_ToggleInvisibleWorkshopObjects kThreadRef = ThreadManager.CreateThread(Thread_ToggleInvisibleWorkshopObjects) as WorkshopFramework:ObjectRefs:Thread_ToggleInvisibleWorkshopObjects
			
			if(kThreadRef)
				int j = i
				int iMaxIndex = i + iBatchSize
				while(j < iTotal && j < iMaxIndex)
					kThreadRef.kObjectRefs.Add(kInvisibleObjects[j])
					
					j += 1
				endWhile
				
				kThreadRef.bInWorkshopMode = abOpening
				
				ThreadManager.QueueThread(kThreadRef)
			endif
		
			i += iBatchSize
		endWhile
	else
		int i = 0
		while(i < iTotal)
			(kInvisibleObjects[i] as WorkshopFramework:ObjectRefs:InvisibleWorkshopObject).Toggle(abOpening)
			
			i += 1
		endWhile
	endif
EndFunction