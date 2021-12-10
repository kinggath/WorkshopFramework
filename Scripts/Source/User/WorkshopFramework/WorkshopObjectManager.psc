; ---------------------------------------------
; WorkshopFramework:WorkshopObjectManager.psc - by kinggath
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

Scriptname WorkshopFramework:WorkshopObjectManager extends WorkshopFramework:Library:SlaveQuest
{ Handles special types of Workshop Objects that need management }


import WorkshopFramework:Library:DataStructures
import WorkshopFramework:Library:UtilityFunctions
import WorkshopFramework:WorkshopFunctions

CustomEvent WorkshopVendorItemsPurchased

; ---------------------------------------------
; Consts
; ---------------------------------------------

int iBatchSize = 10 ; Every X items found will be threaded out
int iMinCountForThreading = 30 ; Must find at least this many items before we bother threading

; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------

Group Controllers
	WorkshopFramework:MainThreadManager Property ThreadManager Auto Const Mandatory
	WorkshopFramework:F4SEManager Property F4SEManager Auto Const Mandatory
	
	WorkshopParentScript Property WorkshopParent Auto Const Mandatory
	
	GlobalVariable Property Setting_AutomaticallyUnhideInvisibleWorkshopObjects Auto Const Mandatory
EndGroup

Group ActorValues
	ActorValue Property WorkshopSnapTransmitsPowerAV Auto Const Mandatory
EndGroup

Group Assets
	Form Property Thread_ToggleInvisibleWorkshopObjects Auto Const Mandatory
	Form Property Thread_UpdateClutteredItems Auto Const Mandatory
	
	Message Property PowerTransmissionResults Auto Const Mandatory
EndGroup

Group Keywords
	Keyword Property InvisibleWorkshopObjectKeyword Auto Const Mandatory
	Keyword Property ClutteredItemKeyword Auto Const Mandatory
	
	Keyword Property WorkshopPowerConnectionKeyword Auto Const Mandatory
	Keyword Property WorkshopCanBePowered Auto Const Mandatory
EndGroup


; ---------------------------------------------
; Vars
; ---------------------------------------------

ObjectReference kLastPurchaseFromVendorContainer

; ---------------------------------------------
; Events
; ---------------------------------------------

Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)
    if(asMenuName== "WorkshopMenu")
		if( ! abOpening || Setting_AutomaticallyUnhideInvisibleWorkshopObjects.GetValueInt() == 1)
			ToggleInvisibleWorkshopObjects(abOpening)
		endif		
	elseif(asMenuName == "BarterMenu")
		if( ! abOpening)
			if(kLastPurchaseFromVendorContainer != None)
				ProcessPurchaseFromWorkshopVendor()
			endif
		endif
	endif
EndEvent


Event ObjectReference.OnItemRemoved(ObjectReference akSender, Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
	kLastPurchaseFromVendorContainer = akSender
EndEvent

; ---------------------------------------------
; Event Handlers
; ---------------------------------------------

Function HandleQuestInit()
	Parent.HandleQuestInit()
	
	RegisterForEvents()
EndFunction

Function HandleGameLoaded()
	Parent.HandleGameLoaded()
	
	RegisterForEvents()
EndFunction

; ---------------------------------------------
; Functions
; ---------------------------------------------

Function RegisterForEvents()
	RegisterForMenuOpenCloseEvent("WorkshopMenu")
EndFunction

Function ToggleInvisibleWorkshopObjects(Bool abOpening)	
	WorkshopScript thisWorkshop = GetNearestWorkshop(PlayerRef)
	ObjectReference[] kInvisibleObjects = thisWorkshop.FindAllReferencesWithKeyword(InvisibleWorkshopObjectKeyword, 20000.0)
	
	int iTotal = kInvisibleObjects.Length
	if(iTotal > iMinCountForThreading)
		int i = 0
		while(i < iTotal)
			WorkshopFramework:ObjectRefs:Thread_ToggleInvisibleWorkshopObjects kThreadRef = ThreadManager.CreateThread(Thread_ToggleInvisibleWorkshopObjects) as WorkshopFramework:ObjectRefs:Thread_ToggleInvisibleWorkshopObjects
			
			if(kThreadRef)
				int j = i
				int iMaxIndex = i + iBatchSize
				while(j < iTotal && j < iMaxIndex)
					kThreadRef.AddObject(kInvisibleObjects[j])
					
					j += 1
				endWhile
				
				kThreadRef.bInWorkshopMode = abOpening
				
				ThreadManager.QueueThread(kThreadRef)
			endif
		
			i += iBatchSize
		endWhile
	else
		int i = 0
		while(i < iTotal)
			(kInvisibleObjects[i] as WorkshopFramework:ObjectRefs:InvisibleWorkshopObject).Toggle(abOpening)
			
			i += 1
		endWhile
	endif
EndFunction


Function UpdateClutteredItems(Bool abOpening)
	WorkshopScript thisWorkshop = GetNearestWorkshop(PlayerRef)
	ObjectReference[] kClutteredItems = thisWorkshop.FindAllReferencesWithKeyword(ClutteredItemKeyword, 20000.0)
	
	int iTotal = kClutteredItems.Length
	
	int i = 0
	while(i < iTotal)
		WorkshopFramework:ObjectRefs:Thread_UpdateClutteredItems kThreadRef = ThreadManager.CreateThread(Thread_UpdateClutteredItems) as WorkshopFramework:ObjectRefs:Thread_UpdateClutteredItems
		
		if(kThreadRef)
			int j = i
			int iMaxIndex = i + iBatchSize
			while(j < iTotal && j < iMaxIndex)
				kThreadRef.AddObject(kClutteredItems[j])
				
				j += 1
			endWhile
			
			ThreadManager.QueueThread(kThreadRef)
		endif
	
		i += iBatchSize
	endWhile
EndFunction


; Send a formlist of specific items and/or keywords of item types to get a list of available inventory item types
FormCount[] Function GetAvailableInventoryItems(WorkshopScript akWorkshopRef, String asVendorID, Int aiVendorLevel, Formlist aRequestedItemsList)
	ObjectReference[] kVendorContainers
	if(asVendorID == "0")
		kVendorContainers = akWorkshopRef.GetVendorContainersByType(0)
	elseif(asVendorID as Int && (asVendorID as Int) > 0)
		kVendorContainers = akWorkshopRef.GetVendorContainersByType(asVendorID as Int)
	else
		kVendorContainers = akWorkshopRef.GetCustomVendorContainers(asVendorID)	
	endif
	
	FormCount[] FoundItems = new FormCount[0]
	
	int i = 0
	while(i < aRequestedItemsList.GetSize() && FoundItems.Length < 128)
		Form thisItem = aRequestedItemsList.GetAt(i)
		
		int j = 0
		while(j < kVendorContainers.Length && j <= aiVendorLevel && FoundItems.Length < 128)
			int iCount = kVendorContainers[j].GetItemCount(thisItem)
			if(iCount > 0)
				int iIndex = FoundItems.FindStruct("CountedForm", thisItem)
				if(iIndex < 0)
					FormCount thisCount = new FormCount
					thisCount.CountedForm = thisItem
					thisCount.iCount = iCount
					
					FoundItems.Add(thisCount)
				else
					FoundItems[iIndex].iCount += iCount
				endif
			endif
			
			j += 1
		endWhile
		
		i += 1
	endWhile
	
	return FoundItems
EndFunction


Function RegisterForWorkshopVendorItemPurchases(WorkshopScript akWorkshopRef, String asVendorID)
	ObjectReference[] kVendorContainers
	if(asVendorID == "0")
		kVendorContainers = akWorkshopRef.GetVendorContainersByType(0)
	elseif(asVendorID as Int && (asVendorID as Int) > 0)
		kVendorContainers = akWorkshopRef.GetVendorContainersByType(asVendorID as Int)
	else
		kVendorContainers = akWorkshopRef.GetCustomVendorContainers(asVendorID)	
	endif
	
	AddInventoryEventFilter(None)
	
	int i = 0
	while(i < kVendorContainers.Length)
		RegisterForRemoteEvent(kVendorContainers[i], "OnItemRemoved")
		
		i += 1
	endWhile
	
	RegisterForMenuOpenCloseEvent("BarterMenu")
EndFunction


Function ProcessPurchaseFromWorkshopVendor()
	WorkshopScript thisWorkshop = WorkshopFramework:WSFW_API.GetNearestWorkshop(PlayerRef)
	ObjectReference kCheckMe = kLastPurchaseFromVendorContainer
	kLastPurchaseFromVendorContainer = None	
	
	; Check which container
	int i = 0
	; Misc
	ObjectReference[] kContainersToCheck = thisWorkshop.VendorContainersMisc
	while(i < kContainersToCheck.Length)
		if(kContainersToCheck[i] == kCheckMe)
			SendWorkshopVendorItemsPurchasedEvent(thisWorkshop, WorkshopParent.WorkshopTypeMisc as String)
			return
		endif
		
		i += 1
	endWhile
	
	; Armor
	i = 0
	kContainersToCheck = thisWorkshop.VendorContainersArmor
	while(i < kContainersToCheck.Length)
		if(kContainersToCheck[i] == kCheckMe)
			SendWorkshopVendorItemsPurchasedEvent(thisWorkshop, WorkshopParent.WorkshopTypeArmor as String)
			return
		endif
		
		i += 1
	endWhile
	
	; Weapons
	i = 0
	kContainersToCheck = thisWorkshop.VendorContainersWeapons
	while(i < kContainersToCheck.Length)
		if(kContainersToCheck[i] == kCheckMe)
			SendWorkshopVendorItemsPurchasedEvent(thisWorkshop, WorkshopParent.WorkshopTypeWeapons as String)
			return
		endif
		
		i += 1
	endWhile
	
	; Bar
	i = 0
	kContainersToCheck = thisWorkshop.VendorContainersBar
	while(i < kContainersToCheck.Length)
		if(kContainersToCheck[i] == kCheckMe)
			SendWorkshopVendorItemsPurchasedEvent(thisWorkshop, WorkshopParent.WorkshopTypeBar as String)
			return
		endif
		
		i += 1
	endWhile
	
	; Clinic
	i = 0
	kContainersToCheck = thisWorkshop.VendorContainersClinic
	while(i < kContainersToCheck.Length)
		if(kContainersToCheck[i] == kCheckMe)
			SendWorkshopVendorItemsPurchasedEvent(thisWorkshop, WorkshopParent.WorkshopTypeClinic as String)
			return
		endif
		
		i += 1
	endWhile
	
	; Clothing
	i = 0
	kContainersToCheck = thisWorkshop.VendorContainersClothing
	while(i < kContainersToCheck.Length)
		if(kContainersToCheck[i] == kCheckMe)
			SendWorkshopVendorItemsPurchasedEvent(thisWorkshop, WorkshopParent.WorkshopTypeClothing as String)
			return
		endif
		
		i += 1
	endWhile
	
	; Custom Vendors
		; L0
	int iIndex = thisWorkshop.kCustomVendorContainersL0.Find(kCheckMe)
	if(iIndex >= 0)
		SendWorkshopVendorItemsPurchasedEvent(thisWorkshop, WorkshopParent.CustomVendorTypes[iIndex].sVendorID)
		return
	endif
	
		; L1
	iIndex = thisWorkshop.kCustomVendorContainersL1.Find(kCheckMe)
	if(iIndex >= 0)
		SendWorkshopVendorItemsPurchasedEvent(thisWorkshop, WorkshopParent.CustomVendorTypes[iIndex].sVendorID)
		return
	endif
	
		; L2
	iIndex = thisWorkshop.kCustomVendorContainersL2.Find(kCheckMe)
	if(iIndex >= 0)
		SendWorkshopVendorItemsPurchasedEvent(thisWorkshop, WorkshopParent.CustomVendorTypes[iIndex].sVendorID)
		return
	endif	
EndFunction

Function SendWorkshopVendorItemsPurchasedEvent(WorkshopScript akWorkshopRef, String asVendorID)
	Var[] kArgs = new Var[2]
	kArgs[0] = akWorkshopRef
	kArgs[1] = asVendorID
	
	SendCustomEvent("WorkshopVendorItemsPurchased", kArgs)
EndFunction


Function MCM_ForcePowerTransmission()
	ForcePowerTransmission(None)
EndFunction

Function ForcePowerTransmission(WorkshopScript akWorkshopRef = None)
	if( ! F4SEManager.IsF4SERunning)
		return
	endif
	
	if(akWorkshopRef == None)
		akWorkshopRef = WorkshopFramework:WSFW_API.GetNearestWorkshop(PlayerRef)
		
		if(akWorkshopRef == None)
			ModTrace("ForcePowerTransmission could not find workshop ref.")
			
			return
		endif
	endif
		
	ObjectReference[] kLinkedRefs = akWorkshopRef.GetLinkedRefChildren(GetWorkshopItemKeyword())
	int i = 0
	int iTransmittedTo = 0
	while(i < kLinkedRefs.Length)
		if( ! kLinkedRefs[i].IsDisabled())
			if(kLinkedRefs[i].HasKeyword(WorkshopCanBePowered) || kLinkedRefs[i].HasKeyword(WorkshopPowerConnectionKeyword) || kLinkedRefs[i].GetValue(WorkshopSnapTransmitsPowerAV) > 0)
				F4SEManager.TransmitConnectedPower(kLinkedRefs[i])
				iTransmittedTo += 1
			endif
		endif
		
		i += 1
	endWhile
	
	PowerTransmissionResults.Show(iTransmittedTo as Float)
EndFunction