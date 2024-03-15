; ---------------------------------------------
; WorkshopFramework:ObjectRefs:Thread_AddNPCToWorkshop.psc - by kinggath
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

Scriptname WorkshopFramework:ObjectRefs:Thread_AddNPCToWorkshop extends WorkshopFramework:Library:ObjectRefs:Thread

import WorkshopFramework:WorkshopFunctions

Actor Property kActorToAssign Auto Hidden
WorkshopScript Property kWorkshopRef Auto Hidden

Function RunCode()
    AddActorToWorkshop(kActorToAssign, kWorkshopRef)
EndFunction

function ReleaseObjectReferences()
    kActorToAssign = none
    kWorkshopRef = none
endfunction
