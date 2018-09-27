; ---------------------------------------------
; WorkshopFramework:Library:ObjectRefs:ResourceTypeProduction.psc - by kinggath
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

Scriptname WorkshopFramework:Library:ObjectRefs:ResourceTypeProduction extends ObjectReference

LeveledItem Property ProduceForm Auto Hidden
{ Item to be produced each day }
ActorValue Property ResourceAV Auto Hidden
{ The AV to check the workshop for to determine how much of this item to produce }
Keyword Property TargetContainerKeyword Auto Hidden
{ [Optional] Attempts to place in containers using the WorkshopFramework container routing system with this keyword - see Documentation for default options, or create your own type. If None, it will simply place in the Workshop container. }