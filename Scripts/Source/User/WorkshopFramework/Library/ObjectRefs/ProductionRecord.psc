; ---------------------------------------------
; WorkshopFramework:Library:ObjectRefs:ProductionRecord.psc - by kinggath
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

Scriptname WorkshopFramework:Library:ObjectRefs:ProductionRecord extends ObjectReference

LeveledItem Property ProduceItem Auto Hidden

Int Property iCount = 0 Auto Hidden
Int Property iWorkshopID = -1 Auto Hidden
Bool Property bIsFood = false Auto Hidden
Bool Property bIsWater = false Auto Hidden
Bool Property bIsScavenge = false Auto Hidden
Keyword Property TargetContainerKeyword Auto Hidden