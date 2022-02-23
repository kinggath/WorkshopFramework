; ---------------------------------------------
; WorkshopFramework:Library:SimpleInjectionManager.psc - by kinggath
; ---------------------------------------------
; Reusage Rights ------------------------------
; You are free to use this script or portions of it in your own mods, provided you give me credit in your description and maintain this section of comments in any released source code (which includes the IMPORTED SCRIPT CREDIT section to give credit to anyone in the associated Import scripts below).
; 
; Warning !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
; Do not directly recompile this script for redistribution without first renaming it to avoid compatibility issues issues with the mod this came from.
; 
; IMPORTED SCRIPT CREDITS
; N/A
; ---------------------------------------------

Scriptname WorkshopFramework:Library:SimpleInjectionManager extends WorkshopFramework:Library:SlaveQuest Conditional

import WorkshopFramework:Library:DataStructures

InjectionMap[] Property InjectData Auto Const

int iLastInjectedIndex = -1

Function HandleGameLoaded()
	Parent.HandleGameLoaded()
	
	HandleInjections()
EndFunction

Function HandleInjections()
	int i = iLastInjectedIndex + 1
	while(i < InjectData.Length)
		iLastInjectedIndex = i
		
		int j = 0
		while(j < InjectData[i].NewEntries.GetSize())
			InjectData[i].TargetLeveledItem.AddForm(InjectData[i].NewEntries.GetAt(j), InjectData[i].iLevel, InjectData[i].iCount)
			
			j += 1
		endWhile
		
		i += 1
	endWhile
EndFunction