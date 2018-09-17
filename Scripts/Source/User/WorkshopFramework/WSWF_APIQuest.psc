; ---------------------------------------------
; WorkshopFramework:WSWF_APIQuest.psc - by kinggath
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

Scriptname WorkshopFramework:WSWF_APIQuest extends WorkshopFramework:Library:SlaveQuest
{ Holds all properties needed by the global API functions }


; -
; Editor Properties 
; -

Group Controllers
	WorkshopParentScript Property WorkshopParent Auto Const Mandatory
	WorkshopFramework:MainQuest Property WSWF_Main Auto Const Mandatory
	WorkshopFramework:PlaceObjectManager Property PlaceObjectManager Auto Const Mandatory
	WorkshopFramework:WorkshopResourceManager Property WorkshopResourceManager Auto Const Mandatory
	WorkshopFramework:NPCManager Property NPCManager Auto Const Mandatory
EndGroup


Group Keywords
	Keyword Property WorkshopItemKeyword Auto Const Mandatory
	Keyword Property WorkshopKeyword Auto Const Mandatory
EndGroup