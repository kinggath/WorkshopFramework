; ---------------------------------------------
; Scriptname WorkshopFramework:ObjectRefs:RealInventoryDisplay.psc - by kinggath
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

Scriptname WorkshopFramework:ObjectRefs:RealInventoryDisplay extends ObjectReference

import WorkshopFramework:Library:DataStructures
import WorkshopFramework:Library:ThirdParty:Cobb:CobbLibraryRotations


; --------------------------------
; Editor Properties
; --------------------------------

Group DisplaySettings
	RIDPNodeDisplayData[] Property RealInventoryDisplayNodes Auto Const
	{ Use this or RealInventoryDisplayData, not both. Form should be pointed at your own copy of the Activator form WSFW_Template_RealInventoryDisplayPoint with the appropriate types of items you want displayed set in the properties. 
	IMPORTANT - if multiple of your markers are searching for the same items, put them next to each other in this array - this will allow the code to run much faster.
	Be sure you have sCustomVendorID or VendorType configured so this system knows which vendor to check. }
	
	WorldObject[] Property RealInventoryDisplayData Auto Const
	{ Use this or RealInventoryDisplayNodes, not both. Form should be pointed at your own copy of the Activator form WSFW_Template_RealInventoryDisplayPoint with the appropriate types of items you want displayed set in the properties. 
	IMPORTANT - if multiple of your markers are searching for the same items, put them next to each other in this array - this will allow the code to run much faster.
	Be sure you have sCustomVendorID or VendorType configured so this system knows which vendor to check. }
EndGroup

Group VendorDetails	
	String Property sVendorID Auto Const
	{ The vendor type or custom vendor ID to pull inventory data from. Vanilla vendor IDs: 0 = General Store, 1 = Armor, 2 = Weapons, 3 = Bar, 4 = Clinic, 5 = Clothing. NOTE: If this script is on an object that has WorkshopObjectScript as well, and that script has VendorType or sCustomVendorID set, this can read that information so you can skip this field if you like. }
	
	Int Property iVendorLevel = -1 Auto Const
	{ The vendor level to pull inventory data from (0, 1, or 2). NOTE: If this script is on an object that has WorkshopObjectScript as well, and that script has VendorType or sCustomVendorID set, this can read that information so you can skip this field if you like. }
EndGroup

; -------------------------------
; Vars
; -------------------------------

WorkshopFramework:ObjectRefs:RealInventoryDisplayPoint[] Property myRealInventoryDisplayMarkerRefs Auto Hidden
Bool bFirstLoad = true


; -------------------------------
; Events
; -------------------------------

Event OnLoad()
	if(bFirstLoad)
		bFirstLoad = false
		
		CreateRealInventoryDisplayMarkerRefs()
	elseif(RealInventoryDisplayNodes.Length > 0 || RealInventoryDisplayData.Length > 0)
		RealInventoryDisplayEventRegistration(true)
	endif
EndEvent

Event OnUnload()
	if(RealInventoryDisplayNodes.Length > 0 || RealInventoryDisplayData.Length > 0)
		RealInventoryDisplayEventRegistration(false)
	endif
EndEvent

Event OnWorkshopObjectMoved(ObjectReference akReference)
	if( ! myRealInventoryDisplayMarkerRefs || myRealInventoryDisplayMarkerRefs.Length == 0)
		CreateRealInventoryDisplayMarkerRefs()
	endif
EndEvent

Event OnWorkshopObjectGrabbed(ObjectReference akReference)
	DeleteRealInventoryDisplayMarkerRefs()
EndEvent

Event OnWorkshopObjectDestroyed(ObjectReference akActionRef)
	DeleteRealInventoryDisplayMarkerRefs()
EndEvent

Event WorkshopFramework:WorkshopObjectManager.WorkshopVendorItemsPurchased(WorkshopFramework:WorkshopObjectManager akSender, Var[] akArgs)
	;/
	akArgs[0] = akWorkshopRef
	akArgs[1] = asVendorID
	/;
	
	WorkshopScript thisWorkshop = GetWorkshop()
	
	if(akArgs[0] as WorkshopScript == thisWorkshop)
		String thisVendorID = GetVendorID()
		
		if(akArgs[1] as String == thisVendorID)
			UpdateRealInventoryDisplay()
		endif
	endif
EndEvent


; -------------------------------
; Functions
; -------------------------------

WorkshopScript Function GetWorkshop()
	WorkshopScript thisWorkshop = GetLinkedRef(GetWorkshopItemKeyword()) as WorkshopScript
	if( ! thisWorkshop)
		thisWorkshop = WorkshopFramework:WSFW_API.GetNearestWorkshop(Self)
	endif
	
	return thisWorkshop
EndFunction

String Function GetVendorID()
	if(sVendorID != "")
		return sVendorID
	else
		if((Self as ObjectReference) as WorkshopObjectScript)
			return ((Self as ObjectReference) as WorkshopObjectScript).GetVendorID()
		endif
	endif
	
	return ""
EndFunction

Int Function GetVendorLevel()
	if(iVendorLevel >= 0)
		return iVendorLevel
	else
		if((Self as ObjectReference) as WorkshopObjectScript)
			return ((Self as ObjectReference) as WorkshopObjectScript).VendorLevel
		endif
	endif
	
	return 0
EndFunction

Function CreateRealInventoryDisplayMarkerRefs()
	DeleteRealInventoryDisplayMarkerRefs() ; Delete previous
	
	if(GetVendorID() != "" && (RealInventoryDisplayNodes != None || RealInventoryDisplayData != None))
		if(RealInventoryDisplayNodes != None)
			int i = 0
			while(i < RealInventoryDisplayNodes.Length)
				WorldObject thisWorldObject = new WorldObject
				thisWorldObject.ObjectForm = RealInventoryDisplayNodes[i].NodeRealInventoryDisplayPoint
				
				ObjectReference kCreatedRef = WorkshopFramework:WSFW_API.CreateSettlementObject(thisWorldObject, akPositionRelativeTo = Self, abStartEnabled = false)
				
				if(kCreatedRef)
					kCreatedRef.MoveToNode(Self, RealInventoryDisplayNodes[i].NodeName)
					kCreatedRef.Enable(false)
					
					myRealInventoryDisplayMarkerRefs.Add(kCreatedRef as WorkshopFramework:ObjectRefs:RealInventoryDisplayPoint)
				endif
				
				i += 1
			endWhile
		else
			int i = 0
			while(i < RealInventoryDisplayData.Length)
				ObjectReference kCreatedRef = WorkshopFramework:WSFW_API.CreateSettlementObject(RealInventoryDisplayData[i], akPositionRelativeTo = Self, abStartEnabled = true)
				
				if(kCreatedRef)
					myRealInventoryDisplayMarkerRefs.Add(kCreatedRef as WorkshopFramework:ObjectRefs:RealInventoryDisplayPoint)
				endif
				
				i += 1
			endWhile
		endif
		
		RealInventoryDisplayEventRegistration(true)		
		UpdateRealInventoryDisplay()
	endif
EndFunction

Function UpdateRealInventoryDisplay()
	if(myRealInventoryDisplayMarkerRefs != None && myRealInventoryDisplayMarkerRefs.Length > 0)
		WorkshopFramework:WorkshopObjectManager WorkshopObjectManager = GetWorkshopObjectManager()
		WorkshopScript thisWorkshop = GetWorkshop()
		String VendorID = GetVendorID()	
		Int VendorLevel = GetVendorLevel()
		FormCount[] DisplayedItems = new FormCount[0] ; Prevent displaying the same exact item multiple times
		Formlist LastQueriedList = None ; This will allow us to "cache" the results if multiple markers in a row use the same lists. 
		FormCount[] AvailableInventory
		
		int i = 0
		while(i < myRealInventoryDisplayMarkerRefs.Length)
			Formlist RequestedItemsList = myRealInventoryDisplayMarkerRefs[i].ValidObjectsToDisplay
			if(LastQueriedList != RequestedItemsList)
				AvailableInventory = WorkshopObjectManager.GetAvailableInventoryItems(thisWorkshop, VendorID, VendorLevel, RequestedItemsList)
				
				LastQueriedList = RequestedItemsList
			endif
			
			Bool bDelete = false
			if(AvailableInventory.Length > 0)
				ObjectReference kCurrentlyDisplayed = myRealInventoryDisplayMarkerRefs[i].GetDisplayItem()
				Bool bDisplaySomething = true
				if(kCurrentlyDisplayed != None)
					Form CurrentDisplayedForm = kCurrentlyDisplayed.GetBaseObject()
					int iAvailableIndex = AvailableInventory.FindStruct("CountedForm", CurrentDisplayedForm)
					if(iAvailableIndex >= 0)
						int iDisplayedIndex = DisplayedItems.FindStruct("CountedForm", CurrentDisplayedForm)
						
						if(iDisplayedIndex >= 0)
							if(DisplayedItems[iDisplayedIndex].iCount >= AvailableInventory[iAvailableIndex].iCount)
								bDelete = true
							else
								DisplayedItems[iDisplayedIndex].iCount += 1
								bDisplaySomething = false
							endif
						else
							FormCount newEntry = new FormCount
							newEntry.CountedForm = CurrentDisplayedForm
							newEntry.iCount = 1
							DisplayedItems.Add(newEntry)
							bDisplaySomething = false
						endif
					else
						bDelete = true
					endif
				endif
				
				if(bDisplaySomething)
					Form[] Eligible = new Form[0]
					
					int j = 0
					while(j < AvailableInventory.Length)
						int iDisplayedIndex = DisplayedItems.FindStruct("CountedForm", AvailableInventory[j].CountedForm)
						
						if(iDisplayedIndex < 0 || DisplayedItems[iDisplayedIndex].iCount < AvailableInventory[j].iCount)
							Eligible.Add(AvailableInventory[j].CountedForm)
						endif
						
						j += 1
					endWhile
					
					if(Eligible.Length > 0)
						Form SelectedForm = Eligible[Utility.RandomInt(0, Eligible.Length - 1)]
						myRealInventoryDisplayMarkerRefs[i].DisplayItem(SelectedForm)
						
						int iDisplayedIndex = DisplayedItems.FindStruct("CountedForm", SelectedForm)
						if(iDisplayedIndex >= 0)
							DisplayedItems[iDisplayedIndex].iCount += 1
						else
							FormCount newEntry = new FormCount
							newEntry.CountedForm = SelectedForm
							newEntry.iCount = 1
							DisplayedItems.Add(newEntry)
						endif
					endif
				endif
			else
				bDelete = true
			endif
			
			if(bDelete)
				myRealInventoryDisplayMarkerRefs[i].Cleanup()
			endif
			
			i += 1
		endWhile
	endif
EndFunction


Function RealInventoryDisplayEventRegistration(Bool abRegister = true)
	WorkshopFramework:WorkshopObjectManager WorkshopObjectManager = GetWorkshopObjectManager()
	
	if(abRegister)
		WorkshopObjectManager.RegisterForWorkshopVendorItemPurchases(GetWorkshop(), GetVendorID())
		RegisterForCustomEvent(WorkshopObjectManager, "WorkshopVendorItemsPurchased")
	else
		; Note - we are not unregistering for the vendor item purchases of a particular type as that would unregister us for all objects in this settlement, which we don't necessarily want to do
		UnregisterForCustomEvent(WorkshopObjectManager, "WorkshopVendorItemsPurchased")
	endIf
EndFunction


Function DeleteRealInventoryDisplayMarkerRefs()
	if(myRealInventoryDisplayMarkerRefs.Length > 0)
		int i = 0
		while(i < myRealInventoryDisplayMarkerRefs.Length)
			myRealInventoryDisplayMarkerRefs[i].Delete()
			i += 1
		endWhile
		
		myRealInventoryDisplayMarkerRefs.Clear()
	endif
	
	myRealInventoryDisplayMarkerRefs = new WorkshopFramework:ObjectRefs:RealInventoryDisplayPoint[0]
EndFunction


Function Delete()
	DeleteRealInventoryDisplayMarkerRefs()
	
	Parent.Delete()
EndFunction


Keyword Function GetWorkshopItemKeyword()
	return Game.GetFormFromFile(0x00054BA6, "Fallout4.esm") as Keyword
EndFunction

WorkshopFramework:WorkshopObjectManager Function GetWorkshopObjectManager()
	return Game.GetFormFromFile(0x00006B5C, "WorkshopFramework.esm") as WorkshopFramework:WorkshopObjectManager
EndFunction