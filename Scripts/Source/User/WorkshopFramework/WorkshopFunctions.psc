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


Keyword[] Function GetTerminalKeywords() global
	Keyword[] TerminalKeywords = new Keyword[0]
	
	; Putting these in order of most to least common so checks for these can short as quickly as possible
	
		; AnimFurnDeskTerminal
	Keyword tempKeyword = Game.GetFormFromFile(0x000286E6, "Fallout4.esm") as Keyword
	if(tempKeyword)
		TerminalKeywords.Add(tempKeyword)
	endif
		
		; AnimFurnDeskTerminalNoChair
	tempKeyword = Game.GetFormFromFile(0x000FCB12, "Fallout4.esm") as Keyword
	if(tempKeyword)
		TerminalKeywords.Add(tempKeyword)
	endif
	
		; AnimFurnWallTerminal
	tempKeyword = Game.GetFormFromFile(0x000C2022, "Fallout4.esm") as Keyword
	if(tempKeyword)
		TerminalKeywords.Add(tempKeyword)
	endif
	
		; AnimFurnDeskTerminalWithChair
	tempKeyword = Game.GetFormFromFile(0x0010F78B, "Fallout4.esm") as Keyword
	if(tempKeyword)
		TerminalKeywords.Add(tempKeyword)
	endif	
	
		; AnimFurnWallTerminalInst
	tempKeyword = Game.GetFormFromFile(0x001E5DC6, "Fallout4.esm") as Keyword
	if(tempKeyword)
		TerminalKeywords.Add(tempKeyword)
	endif
	
		; AnimFurnWallTerminalInstFloor
	tempKeyword = Game.GetFormFromFile(0x001E5DC5, "Fallout4.esm") as Keyword
	if(tempKeyword)
		TerminalKeywords.Add(tempKeyword)
	endif
	
		; AnimFurnPCUseTerminal
	tempKeyword = Game.GetFormFromFile(0x000C01A6, "Fallout4.esm") as Keyword
	if(tempKeyword)
		TerminalKeywords.Add(tempKeyword)
	endif
	
	return TerminalKeywords
EndFunction

; -----------------------------------
; IsTerminal
;
; Description: Tests item for various keywords that identify it as a terminal.
; -----------------------------------

Bool Function IsTerminal(ObjectReference akTestRef) global
	if( ! akTestRef)
		return false
	endif
	
	Keyword[] TerminalKeywords = GetTerminalKeywords()
	
	int i = 0
	while(i < TerminalKeywords.Length)
		if(akTestRef.HasKeyword(TerminalKeywords[i]))
			return true
		endif
		
		i += 1
	endWhile
	
	return false
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