; ---------------------------------------------
; WorkshopFramework:ObjectRefs:Thread_ScrapObject.psc - by kinggath
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

Scriptname WorkshopFramework:ObjectRefs:Thread_ScrapObject extends WorkshopFramework:Library:ObjectRefs:Thread

; -
; Consts
; -


; - 
; Editor Properties
; -

WorkshopParentScript Property WorkshopParent Auto Const Mandatory
Keyword Property WorkshopKeyword Auto Const Mandatory
Keyword Property PowerArmorKeyword Auto Const Mandatory
Keyword Property WorkshopItemKeyword Auto Const Mandatory
ActorBase Property CovenantTurret Auto Const Mandatory
Keyword Property WorkshopStackedItemParentKEYWORD Auto Const Mandatory ; 1.0.2 - Clear links
; -
; Properties
; -
Bool Property bWasRemoved = false Auto Hidden
ObjectReference Property kScrapMe Auto Hidden

; -
; Events
; -

; - 
; Functions 
; -
	
Function ReleaseObjectReferences()
	kScrapMe = None
EndFunction


Function RunCode()
	if(ScrapSafetyCheck(kScrapMe))
		; 1.0.4a - Unlink any items to this one
		kScrapMe.SetLinkedRef(None)
		
		ObjectReference[] LinkedRefs = kScrapMe.GetLinkedRefChildren(None)
		int i = 0
		while(i < LinkedRefs.Length)
			LinkedRefs[i].SetLinkedRef(None)
			i += 1
		endWhile
		
		; 1.0.4a - Unlink any stacked items
		kScrapMe.SetLinkedRef(None, WorkshopStackedItemParentKEYWORD)
		LinkedRefs = kScrapMe.GetLinkedRefChildren(WorkshopStackedItemParentKEYWORD)
		i = 0
		while(i < LinkedRefs.Length)
			LinkedRefs[i].SetLinkedRef(None, WorkshopStackedItemParentKEYWORD)
			
			i += 1
		endWhile
		
		
		WorkshopScript thisWorkshop = kScrapMe.GetLinkedRef(WorkshopItemKeyword) as WorkshopScript
		if(thisWorkshop)
			; Remove from workshop
			WorkshopObjectScript workObject = kScrapMe as WorkshopObjectScript
			
			if(workObject)
				WorkshopParent.RemoveObjectPUBLIC(workObject, thisWorkshop)
			endif
			
			; Clear WorkshopItemKeyword link
			kScrapMe.SetLinkedRef(None, WorkshopItemKeyword)
		endif
		
		; Disable
		kScrapMe.Disable()
		
		; Delete
		kScrapMe.Delete()
		
		bWasRemoved = true
	endif
EndFunction



Bool Function ScrapSafetyCheck(ObjectReference akScrapMe)
	; Special handling for Covenant turrets - which are actors but not WorkshopObjectActorScripts
	if(akScrapMe as Actor && (akScrapMe as Actor).GetActorBase() == CovenantTurret)
		return true
	endif
	
	if((akScrapMe as WorkshopNPCScript) || \
		((akScrapMe as Actor) && ! (akScrapMe as WorkshopObjectActorScript)) || \
		(akScrapMe as WorkshopScript) || \
		akScrapMe.HasKeyword(WorkshopKeyword) || \
		akScrapMe.HasKeyword(PowerArmorKeyword))
		
		return false
	else
		return true
	endif
EndFunction