; ---------------------------------------------
; WorkshopFramework:ObjectRefs:InvisibleWorkshopActorSpawner.psc - by kinggath
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

Scriptname WorkshopFramework:ObjectRefs:InvisibleWorkshopActorSpawner extends WorkshopFramework:ObjectRefs:InvisibleWorkshopObject
{ Spawns an NPC of some sort and then applies options to them. Actual built object only displays in workshop mode and scrapping that item also destroys the spawned actor. }

Group SpawnedActor
	ReferenceAlias Property ApplyAlias Auto Const
	{ Alias for applying AI packages and factions, should have "Can Apply Data to Non-Aliased Refs" checked in }
	Bool Property bPersistToLocation = true Auto Const
	{ This ensures the NPC doesn't reset when the location unloads }
	Bool Property bRemoveFromExistingFactions = false Auto Const
	{ If true, it will have all factions removed before ApplyAlias is called. This is useful for ensuring the NPC does not begin attacking immediately due to faction affiliations when using a default NPC record. }
EndGroup


Function UpdateDisplay() ; Override
	Parent.UpdateDisplay() ; Still call parent to handle most things
	
	Actor asActor = kControlledRef as Actor
	
	if(asActor)
		asActor.StopCombat() ; Just in case
		asActor.EnableAI(false)
		
		if(bRemoveFromExistingFactions)
			asActor.RemoveFromAllFactions()
		endif
		
		if(bPersistToLocation)
			asActor.ClearFromOldLocations()
			asActor.SetPersistLoc(asActor.GetCurrentLocation())
		endif
		
		if(ApplyAlias != None)
			ApplyAlias.ApplyToRef(asActor)
		endif
		
		asActor.EnableAI(true)
	endif
EndFunction