; ---------------------------------------------
; WorkshopFramework:WorkshopFunctions.psc - by kinggath
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

Scriptname WorkshopFramework:WorkshopFunctions Hidden Const

import WorkshopFramework:Library:DataStructures


; -----------------------------------
; Get common form functions
; -----------------------------------

WorkshopParentScript Function GetWorkshopParent() global
	return Game.GetFormFromFile(0x0002058E, "Fallout4.esm") as WorkshopParentScript
EndFunction

Keyword Function GetWorkshopKeyword() global
	return Game.GetFormFromFile(0x00054BA7, "Fallout4.esm") as Keyword
EndFunction

Keyword Function GetWorkshopItemKeyword() global
	return Game.GetFormFromFile(0x00054BA6, "Fallout4.esm") as Keyword
EndFunction


; -----------------------------------
; GetNearestWorkshop
;
; Description: Grabs closest WorkshopScript reference - with some exceptions. If the object is linked to a settlement, it will grab that workshop. If an object is in a workshop's location, it will grab that. Lastly, it will search in a radius to find the closest.
; -----------------------------------

WorkshopScript Function GetNearestWorkshop(ObjectReference akToRef) global
	WorkshopScript nearestWorkshop = akToRef.GetLinkedRef(GetWorkshopItemKeyword()) as WorkshopScript
	if( ! nearestWorkshop)	
		WorkshopParentScript WorkshopParent = GetWorkshopParent()
		Location thisLocation = akToRef.GetCurrentLocation()
		nearestWorkshop = WorkshopParent.GetWorkshopFromLocation(thisLocation)
		
		if( ! nearestWorkshop)
			ObjectReference[] WorkshopsNearby = akToRef.FindAllReferencesWithKeyword(GetWorkshopKeyword(), 20000.0)
			int i = 0
			while(i < WorkshopsNearby.Length)
				if(nearestWorkshop)
					if(WorkshopsNearby[i].GetDistance(akToRef) < nearestWorkshop.GetDistance(akToRef))
						nearestWorkshop = WorkshopsNearby[i] as WorkshopScript
					endIf
				else
					nearestWorkshop = WorkshopsNearby[i] as WorkshopScript
				endif
				
				i += 1
			EndWhile
		endif
	endif
	
	return nearestWorkshop
EndFunction