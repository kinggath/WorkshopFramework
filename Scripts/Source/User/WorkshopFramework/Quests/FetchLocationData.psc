; ---------------------------------------------
; WorkshopFramework:Quests:FetchLocationData.psc - by kinggath
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

Scriptname WorkshopFramework:Quests:FetchLocationData extends WorkshopFramework:Library:StoryEventQuest

Group Aliases
	LocationAlias Property RequestedLocation Auto Const Mandatory
	ReferenceAlias Property MapMarker Auto Const Mandatory
	{ IMPORTANT - Intentionally not allowing disabled, as we don't want to fetch markers that are meant to be replaced. For example, Malden Middle School becomes Vault 75 once you discover it. }
	ReferenceAlias Property MapMarker02 Auto Const Mandatory
	{ Some locations can end up with multiple map markers }
	ReferenceAlias Property MapMarker03 Auto Const Mandatory
	{ Some locations can end up with multiple map markers }
	ReferenceAlias Property CenterMarker Auto Const Mandatory
	ReferenceAlias[] Property EdgeMarkers Auto Const Mandatory
	ReferenceAlias[] Property LinkedAttackMarkers Auto Const Mandatory
	ReferenceAlias[] Property NearbyMapMarkers Auto Const Mandatory
EndGroup