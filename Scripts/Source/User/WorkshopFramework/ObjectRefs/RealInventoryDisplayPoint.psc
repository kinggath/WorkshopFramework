; ---------------------------------------------
; Scriptname WorkshopFramework:ObjectRefs:RealInventoryDisplayPoint.psc - by kinggath
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

Scriptname WorkshopFramework:ObjectRefs:RealInventoryDisplayPoint extends ObjectReference Const

import WorkshopFramework:Library:UtilityFunctions

Formlist Property ValidObjectsToDisplay Auto Const Mandatory
{ A formlist of the items that are OK to place at this point. Should be items that will fit within the same space and that have a similar positioned origin point, they should also all be items that the vendor you expect to use these with would have in inventory. The longer this list, the slower this functionality will be. }


Function DisplayItem(Form akItem)
	WorkshopFramework:Forms:RealInventoryProxyItem asProxyItem = akItem as WorkshopFramework:Forms:RealInventoryProxyItem
	
	Form DisplayMe
	if(asProxyItem && asProxyItem.DisplayVersion != None)
		DisplayMe = GetUniversalForm(asProxyItem.DisplayVersion)
	else
		DisplayMe = akItem
	endif
	
	ObjectReference kItemRef = GetDisplayItem()
	if(kItemRef && kItemRef.GetBaseObject() != DisplayMe)
		Cleanup()
	endif
	
	kItemRef = PlaceAtMe(DisplayMe, abInitiallyDisabled = true)
	kItemRef.BlockActivation(abBlocked = True, abHideActivateText = true)
	Self.SetLinkedRef(kItemRef)
	kItemRef.AddKeyword(GetBlockWorkshopInteractionKeyword())
	kItemRef.Enable(false)
	kItemRef.WaitFor3dLoad()
	kItemRef.SetMotionType(Motion_Keyframed)
EndFunction

Function Cleanup()
	ObjectReference kItemRef = GetDisplayItem()
	if(kItemRef != None)
		kItemRef.Disable(false)
		kItemRef.Delete()
		
		SetLinkedRef(None)
	endif
EndFunction

ObjectReference Function GetDisplayItem()
	return GetLinkedRef()
EndFunction

Function Disable(Bool abFade = false)
	Cleanup()
	
	Parent.Disable(abFade)
EndFunction

Function Delete()
	Cleanup()
	
	Parent.Delete()
EndFunction

Keyword Function GetBlockWorkshopInteractionKeyword()
	return Game.GetFormFromFile(0x001BDBA6, "Fallout4.esm") as Keyword
EndFunction