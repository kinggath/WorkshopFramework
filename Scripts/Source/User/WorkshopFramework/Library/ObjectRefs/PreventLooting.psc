; ---------------------------------------------
; WorkshopFramework:Library:ObjectRefs:PreventLooting.psc - by kinggath
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

Scriptname WorkshopFramework:Library:ObjectRefs:PreventLooting extends ObjectReference
{ If the player loots this, remove it from their inventory }

Bool Property bReturnToPreviousLocation = true Auto Const
{ If true, the object will be returned to its previous location or container when looted, otherwise it will just be deleted. }


Float[] Property KeepAtCoords Auto Hidden

Event OnInit()
	if(KeepAtCoords.Length == 0)
		KeepAtCoords = new Float[0]
		
		; Store starting position
		KeepAtCoords.Add(GetPositionX())
		KeepAtCoords.Add(GetPositionY())
		KeepAtCoords.Add(GetPositionZ())
	endif
EndEvent

Event OnContainerChanged(ObjectReference akNewContainer, ObjectReference akOldContainer)
	ObjectReference PlayerRef = Game.GetPlayer()
	
	if(akNewContainer == PlayerRef)
		if( ! bReturnToPreviousLocation)
			PlayerRef.RemoveItem(Self)
		else
			if(akOldContainer != None)
				PlayerRef.RemoveItem(Self, akOtherContainer = akOldContainer)
			else
				Self.Drop(true)
				
				if(KeepAtCoords.Length > 2)
					Self.SetPosition(KeepAtCoords[0], KeepAtCoords[1], KeepAtCoords[2])
				endif
			endif
		endif
	endif
EndEvent