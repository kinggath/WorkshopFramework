; ---------------------------------------------
; WorkshopFramework:Quests:FindLayoutItems.psc - by kinggath
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

Scriptname WorkshopFramework:Quests:FindLayoutItems extends Quest

Group Aliases
	LocationAlias Property NearestWorkshopLocation Auto Const Mandatory
	LocationAlias Property PlayerLocation Auto Const Mandatory
	LocationAlias Property CleaningItemsFromLocation Auto Const Mandatory
	ReferenceAlias Property NearestWorkshop Auto Const Mandatory
	RefCollectionAlias Property FoundItems Auto Const Mandatory
EndGroup