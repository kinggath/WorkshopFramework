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

Keyword Property WorkshopPowerConnectionDUPLICATE000 Auto Const Mandatory ; 1.0.6 - Used to check for delete safety
ActorValue Property WorkshopSnapTransmitsPower Auto Const Mandatory ; 1.0.6 - Used to check for delete safety

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
		
		; 1.0.7 RemoveObjectPUBLIC will handle this for WorkshopObjectScript objects, but let's make sure it's cleared from general ownership - this may not be necessary - but we want to avoid persistence at all costs
		kScrapMe.SetActorRefOwner(None)
		
		; 1.0.6 - Switching to safe scrapping method to avoid power grid corruption
		SafeDelete(kScrapMe)
		
		bWasRemoved = true
	endif
EndFunction


Function SafeDelete(ObjectReference akDeleteMe)
	; TODO - Once F4SE adds scrap function, make use of it and skip these checks
	Bool bSafeToDelete = true
	; 1.0.8 - Take current statuses into account
	Bool bIsDeleted = akDeleteMe.IsDeleted() 
	Bool bIsDisabled = akDeleteMe.IsDisabled()
	Bool bTemporarilyRelocated = false ; 1.0.8 - Tracking whether object is moved to hide the Enable from the player
	if(akDeleteMe.HasKeyword(WorkshopPowerConnectionDUPLICATE000))
		bSafeToDelete = false
	elseif( ! bIsDeleted)
		if(akDeleteMe.IsDisabled())
			bTemporarilyRelocated = true
			akDeleteMe.MoveTo(akDeleteMe, 0.0, 0.0, -10000.0) ; 1.0.8 - Hiding the enable/disable from the player
			akDeleteMe.Enable(false) ; Must be enabled to test AVs
		endif
		
		if(akDeleteMe.GetValue(WorkshopSnapTransmitsPower) > 0)
			bSafeToDelete = false
		endif
	endif
	
	; Disable
	if( ! bIsDisabled)
		akDeleteMe.Disable(false)
	endif
	
	if(bTemporarilyRelocated)
		akDeleteMe.MoveTo(akDeleteMe, 0.0, 0.0, 10000.0) ; 1.0.8 - Restore to original position
	endif
	
	; Delete
	if( ! bIsDeleted && bSafeToDelete)
		akDeleteMe.Delete()
	endif
EndFunction



Bool Function ScrapSafetyCheck(ObjectReference akScrapMe)
	; Special handling for Covenant turrets - which are actors but not WorkshopObjectActorScripts
	if(akScrapMe as Actor && (akScrapMe as Actor).GetActorBase() == CovenantTurret)
		return true
	endif
	; TODO- Change as WorkshopObjectActorScript check to HasKeyword(TurretKeyword)
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