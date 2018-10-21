; ---------------------------------------------
; WorkshopFramework:Library:ObjectRefs:PreventDroppingOnGround.psc - by kinggath
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

Scriptname WorkshopFramework:Library:ObjectRefs:PreventDroppingOnGround extends ObjectReference
{ Put this on items that you don't want the player to drop on the ground }

Bool Property bReturnToInventory = false Auto Const
{ If true, this will be put back in the player's inventory - otherwise it will just be destroyed }

Event OnContainerChanged(ObjectReference akNewContainer, ObjectReference akOldContainer)
	ObjectReference PlayerRef = Game.GetPlayer()
	
	if(akOldContainer == PlayerRef && ! akNewContainer)
		if(bReturnToInventory)
			PlayerRef.AddItem(Self)
		else
			Disable(false)
			Delete()
		endif
	endif
EndEvent