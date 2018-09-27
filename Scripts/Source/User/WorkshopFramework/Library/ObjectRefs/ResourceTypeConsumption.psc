; ---------------------------------------------
; WorkshopFramework:Library:ObjectRefs:ResourceTypeConsumption.psc - by kinggath
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

Scriptname WorkshopFramework:Library:ObjectRefs:ResourceTypeConsumption extends ObjectReference

Form Property ConsumeForm Auto Hidden
{ Formlist of items, Keyword to match item types, or specific item to be consumed each day }
ActorValue Property ResourceAV Auto Hidden
{ The AV to check the workshop for to determine how much of this item to consume }
Keyword Property SearchContainerKeyword Auto Hidden
{ [Optional] First targets containers using the WorkshopFramework container routing system with this keyword - see Documentation for default options, or create your own type. If None, it will simply look in the Workshop container. }
Bool Property bIsComponentFormList = false Auto Hidden
{ Set this to true if you are setting ConsumeForm to a formlist of components - otherwise this should remain false }