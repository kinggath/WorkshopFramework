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

String sProgressBarID_Rewire = "RewireProgress" Const
String sProgressBarID_AutoWire = "AutoWireProgress" Const
String sProgressBarID_FauxPower = "FauxPowerProgress" Const

Float fDefaultMaxPowerWireLength = 1100.0 Const ; from fWorkshopWireMaxLength game setting
Int iMaxCubeConnectionDistance = 1 Const ; The most cubes away autowiring should attempt to connect

String sPowerToolsLog = "WSFWPowerTools" Const

; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------

Group Controllers
	WorkshopFramework:MainThreadManager Property ThreadManager Auto Const Mandatory
	WorkshopFramework:F4SEManager Property F4SEManager Auto Const Mandatory
	WorkshopFramework:HUDFrameworkManager Property HUDFrameworkManager Auto Const Mandatory
	
	WorkshopParentScript Property WorkshopParent Auto Const Mandatory
	
	GlobalVariable Property Setting_AutomaticallyUnhideInvisibleWorkshopObjects Auto Const Mandatory
EndGroup

Group ActorValues
	ActorValue Property WorkshopSnapTransmitsPowerAV Auto Const Mandatory
	ActorValue Property PowerGeneratedAV Auto Const Mandatory
EndGroup

Group Assets
	Form Property Thread_ToggleInvisibleWorkshopObjects Auto Const Mandatory
	Form Property Thread_UpdateClutteredItems Auto Const Mandatory
	
	Message Property PowerTransmissionResults Auto Const Mandatory
	Message Property RewireWorkshopModeWarning Auto Const Mandatory
	Message Property RewireWorkshopModeConfirm Auto Const Mandatory
	Message Property DestroyWiresWorkshopModeWarning Auto Const Mandatory
	Message Property DestroyWiresWorkshopModeConfirm Auto Const Mandatory
EndGroup

Group Keywords
	Keyword Property InvisibleWorkshopObjectKeyword Auto Const Mandatory
	Keyword Property ClutteredItemKeyword Auto Const Mandatory
	Keyword Property WorkshopItemKeyword Auto Const Mandatory
	
	Keyword Property WorkshopPowerConnectionKeyword Auto Const Mandatory
	Keyword Property WorkshopCanBePowered Auto Const Mandatory
EndGroup


; ---------------------------------------------
; Vars
; ---------------------------------------------

ObjectReference kLastPurchaseFromVendorContainer
Bool bUseHUDProgressModule = true

	
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
	Debug.OpenUserLog(sPowerToolsLog)
	
	Parent.HandleGameLoaded()
	
	if(HUDFrameworkManager.IsHUDFrameworkInstalled)
		bUseHUDProgressModule = true
	else
		bUseHUDProgressModule = false
	endif
	
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


ObjectReference[] Property CollectedWires01 Auto Hidden
ObjectReference[] Property CollectedWires02 Auto Hidden
ObjectReference[] Property CollectedWires03 Auto Hidden
ObjectReference[] Property CollectedWires04 Auto Hidden
ObjectReference[] Property CollectedWires05 Auto Hidden
ObjectReference[] Property CollectedWires06 Auto Hidden
ObjectReference[] Property CollectedWires07 Auto Hidden
ObjectReference[] Property CollectedWires08 Auto Hidden
ObjectReference[] Property CollectedPowerableRefs01 Auto Hidden
ObjectReference[] Property CollectedPowerableRefs02 Auto Hidden
ObjectReference[] Property CollectedPowerableRefs03 Auto Hidden
ObjectReference[] Property CollectedPowerableRefs04 Auto Hidden
ObjectReference[] Property CollectedPowerableRefs05 Auto Hidden
ObjectReference[] Property CollectedPowerableRefs06 Auto Hidden
ObjectReference[] Property CollectedPowerableRefs07 Auto Hidden
ObjectReference[] Property CollectedPowerableRefs08 Auto Hidden
ObjectReference[] Property CollectedPowerableRefs09 Auto Hidden
ObjectReference[] Property CollectedPowerableRefs10 Auto Hidden
ObjectReference[] Property CollectedPowerableRefs11 Auto Hidden
ObjectReference[] Property CollectedPowerableRefs12 Auto Hidden
ObjectReference[] Property CollectedPowerableRefs13 Auto Hidden
ObjectReference[] Property CollectedPowerableRefs14 Auto Hidden
ObjectReference[] Property CollectedPowerableRefs15 Auto Hidden
ObjectReference[] Property CollectedPowerableRefs16 Auto Hidden
	
Bool Function CollectPoweredItems(WorkshopScript akWorkshopRef = None, Bool abCollectWires = true, Bool abWireableOnly = false, Bool abExcludeGenerators = false)
	if(akWorkshopRef == None)
		akWorkshopRef = WorkshopFramework:WSFW_API.GetNearestWorkshop(PlayerRef)
		
		if(akWorkshopRef == None)
			ModTrace("CollectPoweredItems could not find workshop ref.")
			
			return false
		endif
	endif
	
	CollectedWires01 = new ObjectReference[0]
	CollectedWires02 = new ObjectReference[0]
	CollectedWires03 = new ObjectReference[0]
	CollectedWires04 = new ObjectReference[0]
	CollectedWires05 = new ObjectReference[0]
	CollectedWires06 = new ObjectReference[0]
	CollectedWires07 = new ObjectReference[0]
	CollectedWires08 = new ObjectReference[0]
	CollectedPowerableRefs01 = new ObjectReference[0]
	CollectedPowerableRefs02 = new ObjectReference[0]
	CollectedPowerableRefs03 = new ObjectReference[0]
	CollectedPowerableRefs04 = new ObjectReference[0]
	CollectedPowerableRefs05 = new ObjectReference[0]
	CollectedPowerableRefs06 = new ObjectReference[0]
	CollectedPowerableRefs07 = new ObjectReference[0]
	CollectedPowerableRefs08 = new ObjectReference[0]
	CollectedPowerableRefs09 = new ObjectReference[0]
	CollectedPowerableRefs10 = new ObjectReference[0]
	CollectedPowerableRefs11 = new ObjectReference[0]
	CollectedPowerableRefs12 = new ObjectReference[0]
	CollectedPowerableRefs13 = new ObjectReference[0]
	CollectedPowerableRefs14 = new ObjectReference[0]
	CollectedPowerableRefs15 = new ObjectReference[0]
	CollectedPowerableRefs16 = new ObjectReference[0]
	
	ObjectReference[] kLinkedRefs = akWorkshopRef.GetLinkedRefChildren(WorkshopItemKeyword)
	Bool bWireArraysFull = false
	Bool bWireableArraysFull = false
	
	int i = 0
	int iTransmittedTo = 0
	while(i < kLinkedRefs.Length && ( ! bWireableArraysFull || ! bWireArraysFull))
		if( ! kLinkedRefs[i].IsDisabled())
			Bool bIsWire = (kLinkedRefs[i].GetBaseObject().GetFormID() == 0x0001D971)
			
			if(bIsWire)
				if(abCollectWires && ! bWireArraysFull)
					if(CollectedWires01.Length < 128)
						CollectedWires01.Add(kLinkedRefs[i])
					elseif(CollectedWires02.Length < 128)
						CollectedWires02.Add(kLinkedRefs[i])
					elseif(CollectedWires03.Length < 128)
						CollectedWires03.Add(kLinkedRefs[i])
					elseif(CollectedWires04.Length < 128)
						CollectedWires04.Add(kLinkedRefs[i])
					elseif(CollectedWires05.Length < 128)
						CollectedWires05.Add(kLinkedRefs[i])
					elseif(CollectedWires06.Length < 128)
						CollectedWires06.Add(kLinkedRefs[i])
					elseif(CollectedWires07.Length < 128)
						CollectedWires07.Add(kLinkedRefs[i])
					elseif(CollectedWires08.Length < 128)
						CollectedWires08.Add(kLinkedRefs[i])
					else
						bWireArraysFull = true
						Debug.MessageBox("More than 1024 wires found. Unable to process them all. (Psst... ask kinggath to expand the limit!)")
					endif
				endif
			elseif( ! bWireableArraysFull)
				Bool bCollectMe = false
				if(abWireableOnly)
					if(kLinkedRefs[i].HasKeyword(WorkshopPowerConnectionKeyword))
						bCollectMe = true
					endif
				elseif(kLinkedRefs[i].HasKeyword(WorkshopPowerConnectionKeyword) || kLinkedRefs[i].HasKeyword(WorkshopCanBePowered) || kLinkedRefs[i].GetValue(WorkshopSnapTransmitsPowerAV) > 0)
					if( ! abExcludeGenerators || kLinkedRefs[i].GetValue(PowerGeneratedAV) <= 0)
						bCollectMe = true
					endif
				endif
				
				if(bCollectMe)
					if(CollectedPowerableRefs01.Length < 128)
						CollectedPowerableRefs01.Add(kLinkedRefs[i])
					elseif(CollectedPowerableRefs02.Length < 128)
						CollectedPowerableRefs02.Add(kLinkedRefs[i])
					elseif(CollectedPowerableRefs03.Length < 128)
						CollectedPowerableRefs03.Add(kLinkedRefs[i])
					elseif(CollectedPowerableRefs04.Length < 128)
						CollectedPowerableRefs04.Add(kLinkedRefs[i])
					elseif(CollectedPowerableRefs05.Length < 128)
						CollectedPowerableRefs05.Add(kLinkedRefs[i])
					elseif(CollectedPowerableRefs06.Length < 128)
						CollectedPowerableRefs06.Add(kLinkedRefs[i])
					elseif(CollectedPowerableRefs07.Length < 128)
						CollectedPowerableRefs07.Add(kLinkedRefs[i])
					elseif(CollectedPowerableRefs08.Length < 128)
						CollectedPowerableRefs08.Add(kLinkedRefs[i])
					elseif(CollectedPowerableRefs09.Length < 128)
						CollectedPowerableRefs09.Add(kLinkedRefs[i])
					elseif(CollectedPowerableRefs10.Length < 128)
						CollectedPowerableRefs10.Add(kLinkedRefs[i])
					elseif(CollectedPowerableRefs11.Length < 128)
						CollectedPowerableRefs11.Add(kLinkedRefs[i])
					elseif(CollectedPowerableRefs12.Length < 128)
						CollectedPowerableRefs12.Add(kLinkedRefs[i])
					elseif(CollectedPowerableRefs13.Length < 128)
						CollectedPowerableRefs13.Add(kLinkedRefs[i])
					elseif(CollectedPowerableRefs14.Length < 128)
						CollectedPowerableRefs14.Add(kLinkedRefs[i])
					elseif(CollectedPowerableRefs15.Length < 128)
						CollectedPowerableRefs15.Add(kLinkedRefs[i])
					elseif(CollectedPowerableRefs16.Length < 128)
						CollectedPowerableRefs16.Add(kLinkedRefs[i])
					else
						bWireableArraysFull = true
						Debug.MessageBox("More than 2048 powered objects found. Unable to process them all. (Psst... ask kinggath to expand the limit!)")
					endif
				endif
			endif
		endif
		
		i += 1
	endWhile
	
	return true
EndFunction

Function DumpCollectedItems(Bool abPowerRefs = true, Bool abWires = true)
	if(abPowerRefs)
		ModTrace("[WorkshopObjectManager] Dumping powered refs...")
		int i = 0
		while(i < CollectedPowerableRefs01.Length)
			ModTrace("    " + CollectedPowerableRefs01[i])
			
			i += 1
		endWhile
		
		i = 0
		while(i < CollectedPowerableRefs02.Length)
			ModTrace("    " + CollectedPowerableRefs02[i])
			
			i += 1
		endWhile
		
		i = 0
		while(i < CollectedPowerableRefs03.Length)
			ModTrace("    " + CollectedPowerableRefs03[i])
			
			i += 1
		endWhile
		
		i = 0
		while(i < CollectedPowerableRefs04.Length)
			ModTrace("    " + CollectedPowerableRefs04[i])
			
			i += 1
		endWhile
		
		i = 0
		while(i < CollectedPowerableRefs05.Length)
			ModTrace("    " + CollectedPowerableRefs05[i])
			
			i += 1
		endWhile
		
		i = 0
		while(i < CollectedPowerableRefs06.Length)
			ModTrace("    " + CollectedPowerableRefs06[i])
			
			i += 1
		endWhile
		
		i = 0
		while(i < CollectedPowerableRefs07.Length)
			ModTrace("    " + CollectedPowerableRefs07[i])
			
			i += 1
		endWhile
		
		i = 0
		while(i < CollectedPowerableRefs08.Length)
			ModTrace("    " + CollectedPowerableRefs08[i])
			
			i += 1
		endWhile
		
		i = 0
		while(i < CollectedPowerableRefs09.Length)
			ModTrace("    " + CollectedPowerableRefs09[i])
			
			i += 1
		endWhile
		
		i = 0
		while(i < CollectedPowerableRefs10.Length)
			ModTrace("    " + CollectedPowerableRefs10[i])
			
			i += 1
		endWhile
		
		i = 0
		while(i < CollectedPowerableRefs11.Length)
			ModTrace("    " + CollectedPowerableRefs11[i])
			
			i += 1
		endWhile
		
		i = 0
		while(i < CollectedPowerableRefs12.Length)
			ModTrace("    " + CollectedPowerableRefs12[i])
			
			i += 1
		endWhile
		
		i = 0
		while(i < CollectedPowerableRefs13.Length)
			ModTrace("    " + CollectedPowerableRefs13[i])
			
			i += 1
		endWhile
		
		i = 0
		while(i < CollectedPowerableRefs14.Length)
			ModTrace("    " + CollectedPowerableRefs14[i])
			
			i += 1
		endWhile
		
		i = 0
		while(i < CollectedPowerableRefs15.Length)
			ModTrace("    " + CollectedPowerableRefs15[i])
			
			i += 1
		endWhile
		
		i = 0
		while(i < CollectedPowerableRefs16.Length)
			ModTrace("    " + CollectedPowerableRefs16[i])
			
			i += 1
		endWhile
	endif
	
	if(abWires)
		ModTrace("[WorkshopObjectManager] Dumping wires...")
		
		int i = 0
		while(i < CollectedWires01.Length)
			ModTrace("    " + CollectedWires01[i])
			
			i += 1
		endWhile
		
		i = 0
		while(i < CollectedWires02.Length)
			ModTrace("    " + CollectedWires02[i])
			
			i += 1
		endWhile
		
		i = 0
		while(i < CollectedWires03.Length)
			ModTrace("    " + CollectedWires03[i])
			
			i += 1
		endWhile
		
		i = 0
		while(i < CollectedWires04.Length)
			ModTrace("    " + CollectedWires04[i])
			
			i += 1
		endWhile
		
		i = 0
		while(i < CollectedWires05.Length)
			ModTrace("    " + CollectedWires05[i])
			
			i += 1
		endWhile
		
		i = 0
		while(i < CollectedWires06.Length)
			ModTrace("    " + CollectedWires06[i])
			
			i += 1
		endWhile
		
		i = 0
		while(i < CollectedWires07.Length)
			ModTrace("    " + CollectedWires07[i])
			
			i += 1
		endWhile
		
		i = 0
		while(i < CollectedWires08.Length)
			ModTrace("    " + CollectedWires08[i])
			
			i += 1
		endWhile
	endif
	
	ModTrace("[WorkshopObjectManager] DumpCollectedItems finished.")
EndFunction


Struct AutoWireData
	Float fX = 0.0
	Float fY = 0.0
	Float fZ = 0.0
	Int iIndex = -1
	Int iCubeIndex = -1
EndStruct

Bool bAutoWireInProgress = false
Int iAutoWireItemsFound = 0
Int iAutoWireItemsProcessed = 0

Float[] fAutoWireHighs
Float[] fAutoWireLows

Function AutoWireSettlement(WorkshopScript akWorkshopRef = None)
	if( ! F4SEManager.IsF4SERunning)
		return
	endif
	
	if(akWorkshopRef == None)
		akWorkshopRef = WorkshopFramework:WSFW_API.GetNearestWorkshop(PlayerRef)
		
		if(akWorkshopRef == None)
			ModTrace("AutoWireSettlement could not find workshop ref.")
			
			return
		endif
	endif
	
	; Make sure player has been in workshop once
	akWorkshopRef.StartWorkshop(true)
	
	if(bUseHUDProgressModule)
		HUDFrameworkManager.CreateProgressBar(Self, sProgressBarID_AutoWire, "AutoWire: Gathering Items")
	endif
	
	if(CollectPoweredItems(akWorkshopRef, abCollectWires = false, abWireableOnly = true))
		iAutoWireItemsFound = CollectedPowerableRefs01.Length + CollectedPowerableRefs02.Length + CollectedPowerableRefs03.Length + CollectedPowerableRefs04.Length + CollectedPowerableRefs05.Length + CollectedPowerableRefs06.Length + CollectedPowerableRefs07.Length + CollectedPowerableRefs08.Length + CollectedPowerableRefs09.Length + CollectedPowerableRefs10.Length + CollectedPowerableRefs11.Length + CollectedPowerableRefs12.Length + CollectedPowerableRefs13.Length + CollectedPowerableRefs14.Length + CollectedPowerableRefs15.Length + CollectedPowerableRefs16.Length
		
		ModTrace("AutoWireSettlement found " + iAutoWireItemsFound + " items that can be wired.")
		
		iAutoWireItemsProcessed = 0
		
		fAutoWireHighs = new Float[3]
		fAutoWireLows = new Float[3]
		
		AutoWireData[] Data01 = new AutoWireData[0]
		AutoWireData[] Data02 = new AutoWireData[0]
		AutoWireData[] Data03 = new AutoWireData[0]
		AutoWireData[] Data04 = new AutoWireData[0]
		AutoWireData[] Data05 = new AutoWireData[0]
		AutoWireData[] Data06 = new AutoWireData[0]
		AutoWireData[] Data07 = new AutoWireData[0]
		AutoWireData[] Data08 = new AutoWireData[0]
		AutoWireData[] Data09 = new AutoWireData[0]
		AutoWireData[] Data10 = new AutoWireData[0]
		AutoWireData[] Data11 = new AutoWireData[0]
		AutoWireData[] Data12 = new AutoWireData[0]
		AutoWireData[] Data13 = new AutoWireData[0]
		AutoWireData[] Data14 = new AutoWireData[0]
		AutoWireData[] Data15 = new AutoWireData[0]
		AutoWireData[] Data16 = new AutoWireData[0]
		; Query once for data from each ref
		if(CollectedPowerableRefs01.Length > 0)
			Data01 = GatherDataForAutoWire(CollectedPowerableRefs01)
			ModTrace("Found " + Data01.Length + " entries from CollectedPowerableRefs01.")
			if(CollectedPowerableRefs02.Length > 0)
				Data02 = GatherDataForAutoWire(CollectedPowerableRefs02, 128)
				
				if(CollectedPowerableRefs03.Length > 0)
					Data03 = GatherDataForAutoWire(CollectedPowerableRefs03, 256)
				
					if(CollectedPowerableRefs04.Length > 0)
						Data04 = GatherDataForAutoWire(CollectedPowerableRefs04, 384)
				
						if(CollectedPowerableRefs05.Length > 0)
							Data05 = GatherDataForAutoWire(CollectedPowerableRefs05, 512)
				
							if(CollectedPowerableRefs06.Length > 0)
								Data06 = GatherDataForAutoWire(CollectedPowerableRefs06, 640)
				
								if(CollectedPowerableRefs07.Length > 0)
									Data07 = GatherDataForAutoWire(CollectedPowerableRefs07, 768)
				
									if(CollectedPowerableRefs08.Length > 0)
										Data08 = GatherDataForAutoWire(CollectedPowerableRefs08, 896)
										
										if(CollectedPowerableRefs09.Length > 0)
											Data09 = GatherDataForAutoWire(CollectedPowerableRefs09, 1024)
											
											if(CollectedPowerableRefs10.Length > 0)
												Data10 = GatherDataForAutoWire(CollectedPowerableRefs10, 1152)
												
												if(CollectedPowerableRefs11.Length > 0)
													Data11 = GatherDataForAutoWire(CollectedPowerableRefs11, 1280)
													
													if(CollectedPowerableRefs12.Length > 0)
														Data12 = GatherDataForAutoWire(CollectedPowerableRefs12, 1408)
														
														if(CollectedPowerableRefs13.Length > 0)
															Data13 = GatherDataForAutoWire(CollectedPowerableRefs13, 1536)
															
															if(CollectedPowerableRefs14.Length > 0)
																Data14 = GatherDataForAutoWire(CollectedPowerableRefs14, 1664)
																
																if(CollectedPowerableRefs15.Length > 0)
																	Data15 = GatherDataForAutoWire(CollectedPowerableRefs15, 1792)
																	
																	if(CollectedPowerableRefs16.Length > 0)
																		Data16 = GatherDataForAutoWire(CollectedPowerableRefs16, 1920)
																	endif
																endif
															endif
														endif
													endif
												endif
											endif
										endif
									endif
								endif
							endif
						endif
					endif
				endif
			endif
		endif
		
		ModTrace("[AutoWire Details] Powered item data gathered, chunking settlement into cubes.")
		
		; Create "cubes" dividing the settlement into chunks of 1100 (which is the max wiring distance by default)
		Coordinates[] CubeHighCorners = new Coordinates[0]
		Coordinates LastCubeCorner = new Coordinates
		
		; Iterate from high corner across X
		Float fCurrentX = fAutoWireHighs[0]
		Float fCurrentY = fAutoWireHighs[1]
		Float fCurrentZ = fAutoWireHighs[2]
		while(fCurrentZ > fAutoWireLows[2])
			while(fCurrentY > fAutoWireLows[1])
				while(fCurrentX > fAutoWireLows[0])
					Coordinates newCorner = new Coordinates
					newCorner.fX = fCurrentX
					newCorner.fY = fCurrentY
					newCorner.fZ = fCurrentZ
					
					CubeHighCorners.Add(newCorner)
					
					; Decrement X
					fCurrentX -= fDefaultMaxPowerWireLength
				endWhile
				
				LastCubeCorner.fX = fCurrentX
				
				; Reset X
				fCurrentX = fAutoWireHighs[0]
				; ModTrace("Reset X to " + fCurrentX)
				; Decrement Y
				fCurrentY -= fDefaultMaxPowerWireLength
			endWhile
			
			LastCubeCorner.fY = fCurrentY
			
			; Reset X & Y
			fCurrentX = fAutoWireHighs[0]
			fCurrentY = fAutoWireHighs[1]
			; ModTrace("Reset X to " + fCurrentX + " and Y to " + fCurrentY)
			; Decrement Z
			fCurrentZ -= fDefaultMaxPowerWireLength
		endWhile
		
		LastCubeCorner.fZ = fCurrentZ
		
		ModTrace("[AutoWire Details] High Points: " + fAutoWireHighs + ", Low Points: " + fAutoWireLows + ", Cube Count: " + CubeHighCorners.Length + ", First Cube: " + CubeHighCorners[0] + ", Last Cube: " + LastCubeCorner)
		
		; Determine which cube each item is in
		AddCubeIndexes(Data01, CubeHighCorners)
		;ModTrace("[AutoWire Details] Finished AddCubeIndexes for array 01.")
		AddCubeIndexes(Data02, CubeHighCorners)
		;ModTrace("[AutoWire Details] Finished AddCubeIndexes for array 02.")
		AddCubeIndexes(Data03, CubeHighCorners)
		;ModTrace("[AutoWire Details] Finished AddCubeIndexes for array 03.")
		AddCubeIndexes(Data04, CubeHighCorners)
		;ModTrace("[AutoWire Details] Finished AddCubeIndexes for array 04.")
		AddCubeIndexes(Data05, CubeHighCorners)
		;ModTrace("[AutoWire Details] Finished AddCubeIndexes for array 05.")
		AddCubeIndexes(Data06, CubeHighCorners)
		;ModTrace("[AutoWire Details] Finished AddCubeIndexes for array 06.")
		AddCubeIndexes(Data07, CubeHighCorners)
		;ModTrace("[AutoWire Details] Finished AddCubeIndexes for array 07.")
		AddCubeIndexes(Data08, CubeHighCorners)
		;ModTrace("[AutoWire Details] Finished AddCubeIndexes for array 08.")
		
		; Wire everything together in the same cube
		iAutoWireItemsProcessed = 0
		if(bUseHUDProgressModule)
			HUDFrameworkManager.UpdateProgressBarData(Self, sProgressBarID_AutoWire, "AutoWire: Creating Wiring", abForceUpdate = true)
			HUDFrameworkManager.UpdateProgressBarPercentage(Self, sProgressBarID_AutoWire, 0)
		endif
		
		int i = 0
		while(i < CubeHighCorners.Length)
			ObjectReference[] InCubeObjects = GetInCubeObjects(i, Data01, Data02, Data03, Data04, Data05, Data06, Data07, Data08)
			
			InCubeObjects = SortObjectsByDistanceToEachOther(InCubeObjects)
			
			ModTrace("[AutoWire Details] Found " + InCubeObjects.Length + " objects in cube " + i + ". Attempting to connect within cube.")
			int j = 0
			while(j < InCubeObjects.Length - 1) ; -1 because each iteration we'll be linking to the next
				iAutoWireItemsProcessed += 1
				ObjectReference kWireRef = F4SEManager.AttachWireV2(akWorkshopRef, InCubeObjects[j], InCubeObjects[(j + 1)])
				
				if(kWireRef)
					kWireRef.Enable(false)
				endif
				
				if(bUseHUDProgressModule)
					Float fPercentComplete = iAutoWireItemsProcessed as Float/iAutoWireItemsFound as Float
					Int iWholePercentageComplete = Math.Ceiling(fPercentComplete) * 100
					
					HUDFrameworkManager.UpdateProgressBarPercentage(Self, sProgressBarID_AutoWire, iWholePercentageComplete)		
				endif
				
				j += 1
			endWhile
			
			i += 1
		endWhile
		
		; Wire each cube to any neighbors within range. To limit excessive wiring, we'll first try straight down on X and Y, if none for either - we'll try diagonal down on X and Y. Next, we'll try straigt down on Z, if that fails, we'll try diagonal to X and Z, and if that fails diagonal to Y and Z
		ModTrace("[AutoWire Details] Wiring cubes to neighbors.")
		i = 0
		while(i < CubeHighCorners.Length)
			Coordinates thisCube = CubeHighCorners[i]
			Bool bXNeighborFound = false
			; X neighbor
			Float fNeighborX = thisCube.fX - fDefaultMaxPowerWireLength
			Int iCubeDistance = 0
			while( ! bXNeighborFound && iCubeDistance < iMaxCubeConnectionDistance && fNeighborX >= LastCubeCorner.fX)
				
				int XNeighborIndex = CubeHighCorners.FindStruct("fX", fNeighborX)
				
				; ModTrace("Cube " + i + " searching for neighbor on X axis with items. Potential neighbor coordinates: " + fNeighborX + "/" + thisCube.fY + "/" + thisCube.fZ + ". First XNeighborIndex: " + XNeighborIndex)
				
				while(XNeighborIndex >= 0 && (XNeighborIndex == i || CubeHighCorners[XNeighborIndex].fY != thisCube.fY || CubeHighCorners[XNeighborIndex].fZ != thisCube.fZ))
					; Find a matching cube
					XNeighborIndex = CubeHighCorners.FindStruct("fX", fNeighborX, XNeighborIndex + 1)
				endWhile
				
				if(XNeighborIndex >= 0)
					; ModTrace("   Attempting to connect cubes " + i + " and " + XNeighborIndex + ". Cube[" + i + "] = " + thisCube + ", Neighbor = " + CubeHighCorners[XNeighborIndex])
					if(ConnectCubesV2(akWorkshopRef, i, XNeighborIndex, Data01, Data02, Data03, Data04, Data05, Data06, Data07, Data08))
						; Both cubes had items
						bXNeighborFound = true
					else
						; One cube must have lacked an item so we'll need to connect to the next cube on this axis
					endif
				endif
				
				fNeighborX -= fDefaultMaxPowerWireLength
				iCubeDistance += 1
			endWhile
			
			; Y Neighbor
			Bool bYNeighborFound = false
			Float fNeighborY = thisCube.fY - fDefaultMaxPowerWireLength
			iCubeDistance = 0
			while( ! bYNeighborFound && iCubeDistance < iMaxCubeConnectionDistance && fNeighborY >= LastCubeCorner.fY)
				; ModTrace("Cube " + i + " searching for neighbor on Y axis with items. Potential neighbor coordinates: " + thisCube.fX + "/" + fNeighborY + "/" + thisCube.fZ)
				
				int YNeighborIndex = CubeHighCorners.FindStruct("fY", fNeighborY)
				while(YNeighborIndex >= 0 && (YNeighborIndex == i || CubeHighCorners[YNeighborIndex].fX != thisCube.fX || CubeHighCorners[YNeighborIndex].fZ != thisCube.fZ))
					YNeighborIndex = CubeHighCorners.FindStruct("fY", fNeighborY, YNeighborIndex + 1)
				endWhile
				
				if(YNeighborIndex >= 0)
					if(ConnectCubesV2(akWorkshopRef, i, YNeighborIndex, Data01, Data02, Data03, Data04, Data05, Data06, Data07, Data08))
						; Both cubes had items
						bYNeighborFound = true
					else
						; One cube must have lacked an item so we'll need to connect to the next cube on this axis
					endif
				endif
				
				fNeighborY -= fDefaultMaxPowerWireLength
				iCubeDistance += 1
			endWhile
			
			; XY neighbor
			Bool bXYNeighborFound = (bXNeighborFound || bYNeighborFound)
			if( ! bXYNeighborFound)
				fNeighborX = thisCube.fX - fDefaultMaxPowerWireLength
				fNeighborY = thisCube.fY - fDefaultMaxPowerWireLength
				iCubeDistance = 0
				while( ! bXYNeighborFound && iCubeDistance < iMaxCubeConnectionDistance && fNeighborX >= LastCubeCorner.fX && fNeighborY >= LastCubeCorner.fY)
					
					int XYNeighborIndex = CubeHighCorners.FindStruct("fX", fNeighborX)
					
					; ModTrace("Cube " + i + " searching for neighbor on XY axis with items. Potential neighbor coordinates: " + fNeighborX + "/" + fNeighborY + "/" + thisCube.fZ + ". First XYNeighborIndex: " + XYNeighborIndex)
					
					while(XYNeighborIndex >= 0 && (XYNeighborIndex == i || CubeHighCorners[XYNeighborIndex].fY != fNeighborY || CubeHighCorners[XYNeighborIndex].fZ != thisCube.fZ))
						; Find a matching cube
						XYNeighborIndex = CubeHighCorners.FindStruct("fX", fNeighborX, XYNeighborIndex + 1)
					endWhile
					
					if(XYNeighborIndex >= 0)
						; ModTrace("   Attempting to connect cubes " + i + " and " + XYNeighborIndex + ". Cube[" + i + "] = " + thisCube + ", Neighbor = " + CubeHighCorners[XYNeighborIndex])
						if(ConnectCubesV2(akWorkshopRef, i, XYNeighborIndex, Data01, Data02, Data03, Data04, Data05, Data06, Data07, Data08))
							; Both cubes had items
							bXYNeighborFound = true
						else
							; One cube must have lacked an item so we'll need to connect to the next cube on this axis
						endif
					endif
					
					fNeighborX -= fDefaultMaxPowerWireLength
					fNeighborY -= fDefaultMaxPowerWireLength
					iCubeDistance += 1
				endWhile
			endif
			
			; Z Neighbor
			Bool bZNeighborFound = false
			Float fNeighborZ = thisCube.fZ - fDefaultMaxPowerWireLength
			iCubeDistance = 0
			while( ! bZNeighborFound && iCubeDistance < iMaxCubeConnectionDistance && fNeighborZ >= LastCubeCorner.fZ)	
				; ModTrace("Cube " + i + " searching for neighbor on Z axis with items. Potential neighbor coordinates: " + thisCube.fX + "/" + thisCube.fY + "/" + fNeighborZ)
				
				int ZNeighborIndex = CubeHighCorners.FindStruct("fZ", fNeighborZ)
				while(ZNeighborIndex >= 0 && (ZNeighborIndex == i || CubeHighCorners[ZNeighborIndex].fX != thisCube.fX || CubeHighCorners[ZNeighborIndex].fY != thisCube.fY))
					ZNeighborIndex = CubeHighCorners.FindStruct("fZ", fNeighborZ, ZNeighborIndex + 1)
				endWhile
				
				if(ZNeighborIndex >= 0)
					if(ConnectCubesV2(akWorkshopRef, i, ZNeighborIndex, Data01, Data02, Data03, Data04, Data05, Data06, Data07, Data08))
						; Both cubes had items
						bZNeighborFound = true
					else
						; One cube must have lacked an item so we'll need to connect to the next cube on this axis
					endif
				endif
				
				fNeighborZ -= fDefaultMaxPowerWireLength
				iCubeDistance += 1
			endWhile
			
			; XZ neighbor
			Bool bXZNeighbor = (bZNeighborFound || bXYNeighborFound)
			if( ! bXZNeighbor)
				fNeighborX = thisCube.fX - fDefaultMaxPowerWireLength
				fNeighborZ = thisCube.fZ - fDefaultMaxPowerWireLength
				iCubeDistance = 0
				while( ! bXZNeighbor && iCubeDistance < iMaxCubeConnectionDistance && fNeighborX >= LastCubeCorner.fX && fNeighborZ >= LastCubeCorner.fZ)
					
					int XZNeighborIndex = CubeHighCorners.FindStruct("fX", fNeighborX)
					
					; ModTrace("Cube " + i + " searching for neighbor on XZ axis with items. Potential neighbor coordinates: " + fNeighborX + "/" + thisCube.fY + "/" + fNeighborZ + ". First XZNeighborIndex: " + XZNeighborIndex)
					
					while(XZNeighborIndex >= 0 && (XZNeighborIndex == i || CubeHighCorners[XZNeighborIndex].fY != thisCube.fY || CubeHighCorners[XZNeighborIndex].fZ != fNeighborZ))
						; Find a matching cube
						XZNeighborIndex = CubeHighCorners.FindStruct("fX", fNeighborX, XZNeighborIndex + 1)
					endWhile
					
					if(XZNeighborIndex >= 0)
						; ModTrace("   Attempting to connect cubes " + i + " and " + XZNeighborIndex + ". Cube[" + i + "] = " + thisCube + ", Neighbor = " + CubeHighCorners[XZNeighborIndex])
						if(ConnectCubesV2(akWorkshopRef, i, XZNeighborIndex, Data01, Data02, Data03, Data04, Data05, Data06, Data07, Data08))
							; Both cubes had items
							bXZNeighbor = true
						else
							; One cube must have lacked an item so we'll need to connect to the next cube on this axis
						endif
					endif
					
					fNeighborX -= fDefaultMaxPowerWireLength
					fNeighborZ -= fDefaultMaxPowerWireLength
					iCubeDistance += 1
				endWhile
			endif
			
			; YZ neighbor
			Bool bYZNeighbor = bXZNeighbor
			if( ! bYZNeighbor)
				fNeighborY = thisCube.fY - fDefaultMaxPowerWireLength
				fNeighborZ = thisCube.fZ - fDefaultMaxPowerWireLength
				iCubeDistance = 0
				while( ! bYZNeighbor && iCubeDistance < iMaxCubeConnectionDistance && fNeighborY >= LastCubeCorner.fY && fNeighborZ >= LastCubeCorner.fZ)
					
					int YZNeighborIndex = CubeHighCorners.FindStruct("fY", fNeighborY)
					
					; ModTrace("Cube " + i + " searching for neighbor on YZ axis with items. Potential neighbor coordinates: " + thisCube.fX + "/" + fNeighborY + "/" + fNeighborZ + ". First YZNeighborIndex: " + YZNeighborIndex)
					
					while(YZNeighborIndex >= 0 && (YZNeighborIndex == i || CubeHighCorners[YZNeighborIndex].fY != thisCube.fY || CubeHighCorners[YZNeighborIndex].fZ != fNeighborZ))
						; Find a matching cube
						YZNeighborIndex = CubeHighCorners.FindStruct("fY", fNeighborY, YZNeighborIndex + 1)
					endWhile
					
					if(YZNeighborIndex >= 0)
						; ModTrace("   Attempting to connect cubes " + i + " and " + YZNeighborIndex + ". Cube[" + i + "] = " + thisCube + ", Neighbor = " + CubeHighCorners[YZNeighborIndex])
						if(ConnectCubesV2(akWorkshopRef, i, YZNeighborIndex, Data01, Data02, Data03, Data04, Data05, Data06, Data07, Data08))
							; Both cubes had items
							bYZNeighbor = true
						else
							; One cube must have lacked an item so we'll need to connect to the next cube on this axis
						endif
					endif
					
					fNeighborY -= fDefaultMaxPowerWireLength
					fNeighborZ -= fDefaultMaxPowerWireLength
					iCubeDistance += 1
				endWhile
			endif
			
			; ModTrace(" Finished searching for neighbors for cube " + i + ".")
			
			i += 1
		endWhile
	endif
	
	Debug.MessageBox("Auto-Wiring complete!\n\nSince the code is unable to detect geometry, some wires may be clipping, but they will still function to transmit power.")
	
	if(bUseHUDProgressModule)
		; Make sure progress bar closed
		HUDFrameworkManager.CompleteProgressBar(Self, sProgressBarID_AutoWire)
		Utility.Wait(2.0)
		; Doing so again to be absolutely certain it closed
		HUDFrameworkManager.CompleteProgressBar(Self, sProgressBarID_AutoWire)
	endif
	
	bAutoWireInProgress = false
EndFunction


ObjectReference[] Function SortObjectsByDistanceToEachOther(ObjectReference[] akObjects)
	ObjectReference[] kSorted = new ObjectReference[0]
	ObjectReference[] kSortCopy = (akObjects as Var[]) as ObjectReference[]
	; Use item 0 as starting point
	kSorted.Add(kSortCopy[0])
	kSortCopy.Remove(0)
	
	Int iLastSortedIndex = 0
	while(iLastSortedIndex < akObjects.Length)
		Float fClosestDistance = 999999.0
		Int iClosestIndex = -1
		int i = 0
		while(i < kSortCopy.Length)
			Float fDistance = kSorted[iLastSortedIndex].GetDistance(kSortCopy[i])
			if(fDistance < fClosestDistance)
				fClosestDistance = fDistance
				iClosestIndex = i
			endif
			
			i += 1
		endWhile
		
		kSorted.Add(kSortCopy[iClosestIndex])
		kSortCopy.Remove(iClosestIndex)
	
		iLastSortedIndex += 1
	endWhile
	
	return kSorted
EndFunction

Bool Function ConnectCubes(Int aiCubeIndexA, Int aiCubeIndexB, AutoWireData[] aGroup01, AutoWireData[] aGroup02, AutoWireData[] aGroup03, AutoWireData[] aGroup04, AutoWireData[] aGroup05, AutoWireData[] aGroup06, AutoWireData[] aGroup07, AutoWireData[] aGroup08)
	Debug.Trace( Self + " :: ConnectCubes() Obsolete, use ConnectCubesV2()" )
	Return False
EndFunction
Bool Function ConnectCubesV2(ObjectReference akWorkshopRef, Int aiCubeIndexA, Int aiCubeIndexB, AutoWireData[] aGroup01, AutoWireData[] aGroup02, AutoWireData[] aGroup03, AutoWireData[] aGroup04, AutoWireData[] aGroup05, AutoWireData[] aGroup06, AutoWireData[] aGroup07, AutoWireData[] aGroup08)
	If( akWorkshopRef == None )
		Debug.Trace( Self + " :: ConnectCubesV2() :: Cannot create a PowerGrid without a WorkshopRef!" )
		Return False
	EndIf
	ObjectReference[] CubeAObjects = GetInCubeObjects(aiCubeIndexA, aGroup01, aGroup02, aGroup03, aGroup04, aGroup05, aGroup06, aGroup07, aGroup08)
	ObjectReference[] CubeBObjects = GetInCubeObjects(aiCubeIndexB, aGroup01, aGroup02, aGroup03, aGroup04, aGroup05, aGroup06, aGroup07, aGroup08)
	
	ObjectReference kRefA = None
	ObjectReference kRefB = None
	Float fShortestDistance = 999999.0
	int i = 0
	while(i < CubeAObjects.Length)
		int j = 0
		while(j < CubeBObjects.Length)
			Float fCheckDistance = CubeBObjects[j].GetDistance(CubeAObjects[i])
			if(fCheckDistance < fShortestDistance)
				fShortestDistance = fCheckDistance
				kRefA = CubeAObjects[i]
				kRefB = CubeBObjects[j]
			endif
			
			j += 1
		endWhile
		
		i += 1
	endWhile
	
	if(kRefA != None && kRefB != None)
		ObjectReference kWireRef = F4SEManager.AttachWireV2(akWorkshopRef, kRefA, kRefB)
		
		if(kWireRef != None)
			kWireRef.Enable(false)
		endif
		
		iAutoWireItemsProcessed += 1
		
		if(bUseHUDProgressModule)
			Float fPercentComplete = iAutoWireItemsProcessed as Float/iAutoWireItemsFound as Float
			Int iWholePercentageComplete = Math.Ceiling(fPercentComplete) * 100
			
			HUDFrameworkManager.UpdateProgressBarPercentage(Self, sProgressBarID_AutoWire, Math.Min(100, iWholePercentageComplete) as Int)
		endif
		
		return true
	endif
	
	return false
EndFunction


ObjectReference[] Function GetInCubeObjects(Int aiCubeIndex, AutoWireData[] aGroup01, AutoWireData[] aGroup02, AutoWireData[] aGroup03, AutoWireData[] aGroup04, AutoWireData[] aGroup05, AutoWireData[] aGroup06, AutoWireData[] aGroup07, AutoWireData[] aGroup08)
	ObjectReference[] InCubeObjects = new ObjectReference[0]
	int j = 0
	while(j < aGroup01.Length)
		if(aGroup01[j].iCubeIndex == aiCubeIndex)
			ObjectReference kRef = GetCollectedPowerableRefByIndex(aGroup01[j].iIndex)
			if(kRef != None)
				InCubeObjects.Add(kRef)
			endif
		endif
		
		j += 1
	endWhile
	
	j = 0
	while(j < aGroup02.Length)
		if(aGroup02[j].iCubeIndex == aiCubeIndex)
			ObjectReference kRef = GetCollectedPowerableRefByIndex(aGroup02[j].iIndex)
			if(kRef != None)
				InCubeObjects.Add(kRef)
			endif
		endif
		
		j += 1
	endWhile
	
	j = 0
	while(j < aGroup03.Length)
		if(aGroup03[j].iCubeIndex == aiCubeIndex)
			ObjectReference kRef = GetCollectedPowerableRefByIndex(aGroup03[j].iIndex)
			if(kRef != None)
				InCubeObjects.Add(kRef)
			endif
		endif
		
		j += 1
	endWhile
		
	j = 0
	while(j < aGroup04.Length)
		if(aGroup04[j].iCubeIndex == aiCubeIndex)
			ObjectReference kRef = GetCollectedPowerableRefByIndex(aGroup04[j].iIndex)
			if(kRef != None)
				InCubeObjects.Add(kRef)
			endif
		endif
		
		j += 1
	endWhile
	
	j = 0
	while(j < aGroup05.Length)
		if(aGroup05[j].iCubeIndex == aiCubeIndex)
			ObjectReference kRef = GetCollectedPowerableRefByIndex(aGroup05[j].iIndex)
			if(kRef != None)
				InCubeObjects.Add(kRef)
			endif
		endif
		
		j += 1
	endWhile
	
	j = 0
	while(j < aGroup06.Length)
		if(aGroup06[j].iCubeIndex == aiCubeIndex)
			ObjectReference kRef = GetCollectedPowerableRefByIndex(aGroup06[j].iIndex)
			if(kRef != None)
				InCubeObjects.Add(kRef)
			endif
		endif
		
		j += 1
	endWhile
		
	j = 0
	while(j < aGroup07.Length)
		if(aGroup07[j].iCubeIndex == aiCubeIndex)
			ObjectReference kRef = GetCollectedPowerableRefByIndex(aGroup07[j].iIndex)
			if(kRef != None)
				InCubeObjects.Add(kRef)
			endif
		endif
		
		j += 1
	endWhile
		
	j = 0
	while(j < aGroup08.Length)
		if(aGroup08[j].iCubeIndex == aiCubeIndex)
			ObjectReference kRef = GetCollectedPowerableRefByIndex(aGroup08[j].iIndex)
			if(kRef != None)
				InCubeObjects.Add(kRef)
			endif
		endif
		
		j += 1
	endWhile
	
	return InCubeObjects
EndFunction


ObjectReference Function GetCollectedPowerableRefByIndex(Int aiIndex)
	if(aiIndex < 128)
		return CollectedPowerableRefs01[aiIndex]
	elseif(aiIndex < 256)
		return CollectedPowerableRefs02[(aiIndex - 128)]
	elseif(aiIndex < 384)
		return CollectedPowerableRefs03[(aiIndex - 256)]
	elseif(aiIndex < 512)
		return CollectedPowerableRefs04[(aiIndex - 384)]
	elseif(aiIndex < 640)
		return CollectedPowerableRefs05[(aiIndex - 512)]
	elseif(aiIndex < 768)
		return CollectedPowerableRefs06[(aiIndex - 640)]
	elseif(aiIndex < 896)
		return CollectedPowerableRefs07[(aiIndex - 768)]
	elseif(aiIndex < 1024)
		return CollectedPowerableRefs08[(aiIndex - 896)]
	elseif(aiIndex < 1152)
		return CollectedPowerableRefs09[(aiIndex - 1024)]
	elseif(aiIndex < 1280)
		return CollectedPowerableRefs10[(aiIndex - 1152)]
	elseif(aiIndex < 1408)
		return CollectedPowerableRefs11[(aiIndex - 1280)]
	elseif(aiIndex < 1536)
		return CollectedPowerableRefs12[(aiIndex - 1408)]
	elseif(aiIndex < 1664)
		return CollectedPowerableRefs13[(aiIndex - 1536)]
	elseif(aiIndex < 1792)
		return CollectedPowerableRefs14[(aiIndex - 1664)]
	elseif(aiIndex < 1920)
		return CollectedPowerableRefs15[(aiIndex - 1792)]
	elseif(aiIndex < 2048)
		return CollectedPowerableRefs16[(aiIndex - 1920)]
	else
		return None
	endif
EndFunction

Function AddCubeIndexes(AutoWireData[] aWireDataArray, Coordinates[] aCubeHighCornerArray)
	; ModTrace("AddCubeIndexes sent " + aWireDataArray.Length + " entries to add indexes for. Cube array has " + aCubeHighCornerArray.Length + " entries.")
	
	if(aWireDataArray.Length == 0)
		return
	endif
	
	AutoWireData[] CubesNotFound = (aWireDataArray as Var[]) as AutoWireData[]
	int i = 0
	while(i < aCubeHighCornerArray.Length)		
		ModTrace("Checking Cube " + i + " for objects. Coordinates: " + aCubeHighCornerArray[i])
		int j = 0
		while(j < aWireDataArray.Length)
			if(IsWithinCube(aWireDataArray[j], aCubeHighCornerArray[i]))
				aWireDataArray[j].iCubeIndex = i
				
				CubesNotFound[j] = None
				ModTrace("   AddCubeIndexes found object " + GetCollectedPowerableRefByIndex(aWireDataArray[j].iIndex) + " is within cube " + i) 
			endif
			j += 1
		endWhile		
		
		i += 1
	endWhile
	
	ModTrace("The following items were not found within any cube:")
	i = 0
	while(i < CubesNotFound.Length)
		if(CubesNotFound[i] != None)
			ModTrace("    " + GetCollectedPowerableRefByIndex(CubesNotFound[i].iIndex) + " " + CubesNotFound[i])
		endif
		
		i += 1
	endWhile
EndFunction

Bool Function IsWithinCube(AutoWireData aWireData, Coordinates aCubeHighCorner)
	; ModTrace("   IsWithinCube: " + aWireData + ", Cube Coordinates: " + aCubeHighCorner)
	if(aWireData.fX <= aCubeHighCorner.fX && aWireData.fX > aCubeHighCorner.fX - fDefaultMaxPowerWireLength)
		if(aWireData.fY <= aCubeHighCorner.fY && aWireData.fY > aCubeHighCorner.fY - fDefaultMaxPowerWireLength)
			if(aWireData.fZ <= aCubeHighCorner.fZ && aWireData.fZ > aCubeHighCorner.fZ - fDefaultMaxPowerWireLength)
				return true
			endif
		endif
	endif
	
	return false
EndFunction

AutoWireData[] Function GatherDataForAutoWire(ObjectReference[] akRefs, int aiIndexModifier = 0)
	if(fAutoWireHighs == None)
		fAutoWireHighs = new Float[3]
	endif
	
	if(fAutoWireLows == None)
		fAutoWireLows = new Float[3]
	endif
	
	AutoWireData[] CollectedData = new AutoWireData[0]
	int i = 0
	while(i < akRefs.Length)
		if(akRefs[i] != None)
			iAutoWireItemsProcessed += 1
			
			AutoWireData newData = new AutoWireData
			newData.fX = akRefs[i].X
			newData.fY = akRefs[i].Y
			newData.fZ = akRefs[i].Z
			newData.iIndex = i + aiIndexModifier
			
			CollectedData.Add(newData)
			
			if(newData.fX < fAutoWireLows[0] || fAutoWireLows[0] == 0.0)
				fAutoWireLows[0] = newData.fX
			endif
			
			if(newData.fX > fAutoWireHighs[0] || fAutoWireHighs[0] == 0.0)
				fAutoWireHighs[0] = newData.fX
			endif
			
			if(newData.fY < fAutoWireLows[1] || fAutoWireLows[1] == 0.0)
				fAutoWireLows[1] = newData.fY
			endif
			
			if(newData.fY > fAutoWireHighs[1] || fAutoWireHighs[1] == 0.0)
				fAutoWireHighs[1] = newData.fY
			endif
			
			if(newData.fZ < fAutoWireLows[2] || fAutoWireLows[2] == 0.0)
				fAutoWireLows[2] = newData.fZ
			endif
			
			if(newData.fZ > fAutoWireHighs[2] || fAutoWireHighs[2] == 0.0)
				fAutoWireHighs[2] = newData.fZ
			endif
			
			if(bUseHUDProgressModule)
				Float fPercentComplete = iAutoWireItemsProcessed as Float/iAutoWireItemsFound as Float
				Int iWholePercentageComplete = Math.Ceiling(fPercentComplete) * 100
				
				HUDFrameworkManager.UpdateProgressBarPercentage(Self, sProgressBarID_AutoWire, iWholePercentageComplete)
			endif
		endif
		
		i += 1
	endWhile
	
	return CollectedData
EndFunction


Bool bFauxPowerInProgress = false
int iFauxPowerItemsFound = 0
int iFauxPowerItemsProcessed = 0
Function FauxPowerSettlement(WorkshopScript akWorkshopRef = None)
	if(akWorkshopRef == None)
		akWorkshopRef = WorkshopFramework:WSFW_API.GetNearestWorkshop(PlayerRef)
		
		if(akWorkshopRef == None)
			ModTrace("FauxPowerSettlement could not find workshop ref.")
			
			return
		endif
	endif
	
	bFauxPowerInProgress = true
	
	if(bUseHUDProgressModule)
		HUDFrameworkManager.CreateProgressBar(Self, sProgressBarID_FauxPower, "Faux Powering Settlement")
	endif
	
	; Find all powerable objects
	if(CollectPoweredItems(akWorkshopRef, abCollectWires = false, abWireableOnly = false, abExcludeGenerators = true))
		iFauxPowerItemsFound = CollectedPowerableRefs01.Length + CollectedPowerableRefs02.Length + CollectedPowerableRefs03.Length + CollectedPowerableRefs04.Length + CollectedPowerableRefs05.Length + CollectedPowerableRefs06.Length + CollectedPowerableRefs07.Length + CollectedPowerableRefs08.Length + CollectedPowerableRefs09.Length + CollectedPowerableRefs10.Length + CollectedPowerableRefs11.Length + CollectedPowerableRefs12.Length + CollectedPowerableRefs13.Length + CollectedPowerableRefs14.Length + CollectedPowerableRefs15.Length + CollectedPowerableRefs16.Length
		
		FauxPowerObjectArray(CollectedPowerableRefs01)
		FauxPowerObjectArray(CollectedPowerableRefs02)
		FauxPowerObjectArray(CollectedPowerableRefs03)
		FauxPowerObjectArray(CollectedPowerableRefs04)
		FauxPowerObjectArray(CollectedPowerableRefs05)
		FauxPowerObjectArray(CollectedPowerableRefs06)
		FauxPowerObjectArray(CollectedPowerableRefs07)
		FauxPowerObjectArray(CollectedPowerableRefs08)
		FauxPowerObjectArray(CollectedPowerableRefs09)
		FauxPowerObjectArray(CollectedPowerableRefs10)
		FauxPowerObjectArray(CollectedPowerableRefs11)
		FauxPowerObjectArray(CollectedPowerableRefs12)
		FauxPowerObjectArray(CollectedPowerableRefs13)
		FauxPowerObjectArray(CollectedPowerableRefs14)
		FauxPowerObjectArray(CollectedPowerableRefs15)
		FauxPowerObjectArray(CollectedPowerableRefs16)
	endif
	
	if(bUseHUDProgressModule)
		HUDFrameworkManager.CompleteProgressBar(Self, sProgressBarID_FauxPower)
		
		Utility.Wait(2.0)
		
		; Rerun to be certain it closed
		HUDFrameworkManager.CompleteProgressBar(Self, sProgressBarID_FauxPower)
	endif
EndFunction


Function FauxPowerObjectArray(ObjectReference[] aObjectArray)
	if(aObjectArray == None || aObjectArray.Length == 0)
		return
	endif
	
	int i = 0
	while(i < aObjectArray.Length)		
		FauxPowerWorkshopItem(aObjectArray[i])
		
		iFauxPowerItemsProcessed += 1
		
		if(bFauxPowerInProgress && bUseHUDProgressModule)
			Float fPercentComplete = iFauxPowerItemsProcessed as Float/iFauxPowerItemsFound as Float
			Int iWholePercentageComplete = Math.Ceiling(fPercentComplete) * 100
			
			HUDFrameworkManager.UpdateProgressBarPercentage(Self, sProgressBarID_FauxPower, iWholePercentageComplete)
		endif
		
		i += 1
	endWhile
EndFunction


Bool Function DestroyWires(WorkshopScript akWorkshopRef = None)
	if( ! F4SEManager.IsF4SERunning)
		return false
	endif
	
	if(akWorkshopRef == None)
		akWorkshopRef = WorkshopFramework:WSFW_API.GetNearestWorkshop(PlayerRef)
		
		if(akWorkshopRef == None)
			ModTrace("DestroyWires could not find workshop ref.")
			
			return false
		endif
	endif
	
	DestroyWiresWorkshopModeWarning.Show()
	
	Game.RequestAutoSave() ; Just in case it does crash this will bring the player back to the confirmation message so they can decline
	
	int iConfirm = DestroyWiresWorkshopModeConfirm.Show()
	
	if(iConfirm == 0)
		return false
	endif

	if(CollectPoweredItems(akWorkshopRef, abWireableOnly = true))
		akWorkshopRef.StartWorkshop(true)
		
		ScrapWireArray(CollectedWires01, akWorkshopRef)
		ScrapWireArray(CollectedWires02, akWorkshopRef)
		ScrapWireArray(CollectedWires03, akWorkshopRef)
		ScrapWireArray(CollectedWires04, akWorkshopRef)
		ScrapWireArray(CollectedWires05, akWorkshopRef)
		ScrapWireArray(CollectedWires06, akWorkshopRef)
		ScrapWireArray(CollectedWires07, akWorkshopRef)
		ScrapWireArray(CollectedWires08, akWorkshopRef)
	endif
		
	Debug.MessageBox("All found wires have been scrapped.\n\nIt is now safe to exit Workshop Mode!")
	
	return true
EndFunction

Function ScrapWireArray(ObjectReference[] akWireArray, WorkshopScript akWorkshopRef)
	if(akWireArray == None || akWireArray.Length == 0)
		return
	endif
	
	int i = akWireArray.Length
	while(i > 0)
		i -= 1
		
		if(akWireArray[i] != None)
			if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
				akWorkshopRef.StartWorkshop(true)
			endif
			
			; TODO - Once F4SE implements Scrap, we need to remove this routing through PowerGridTools
			ModTraceCustom(sPowerToolsLog, "     Attempting to scrap wire: " + akWireArray[i])
			if( ! PowerGridTools.Scrap(akWireArray[i], akWorkshopRef))
				ModTrace("     PowerGridTools.Scrap failed. Manually removing wire " + akWireArray[i])
				akWireArray[i].SetLinkedRef(None, WorkshopItemKeyword)
				akWireArray[i].Disable(false)
				akWireArray[i].SetPosition(0.0, 0.0, 0.0)
				akWireArray[i].Delete()
				Utility.Wait(1.0)
			else
				Utility.Wait(0.5) ; Short delay as spamming it seems to occasionally cause crashes in the same way doing so outside workshop mode doe
			endif
		
			akWireArray[i] = None
		endif
	endWhile
EndFunction

Function TraceConnections(ObjectReference akObjectRef)
	ObjectReference[] kConnected = F4SEManager.GetConnectedObjects(akObjectRef)
	
	ModTrace("TraceConnections(" + akObjectRef + "): " + kConnected)
EndFunction


int iTotalWiresToRecreate = 0
int iRemainingWiresToRecreate = 0
Bool Property bRewireInProgress = false Auto Hidden
Bool Function RewireSettlement(WorkshopScript akWorkshopRef = None)
	if( ! F4SEManager.IsF4SERunning)
		return false
	endif
	
	if(akWorkshopRef == None)
		akWorkshopRef = WorkshopFramework:WSFW_API.GetNearestWorkshop(PlayerRef)
		
		if(akWorkshopRef == None)
			ModTrace("RewireSettlement could not find workshop ref.")
			
			return false
		endif
	endif
	
	RewireWorkshopModeWarning.Show()
	
	Game.RequestAutoSave() ; Just in case it does crash this will bring the player back to the confirmation message so they can decline
	
	int iConfirm = RewireWorkshopModeConfirm.Show()
	
	if(iConfirm == 0)
		return false
	endif
	
	; Force into workshop mode
	akWorkshopRef.StartWorkshop(true)
	
	; Use WorkshopFramework progress meter
	if(bUseHUDProgressModule)
		HUDFrameworkManager.CreateProgressBar(Self, sProgressBarID_Rewire, "Rewiring Settlement")
	endif
	
	if(CollectPoweredItems(akWorkshopRef, abWireableOnly = true))
		if(CollectedWires01.Length > 0)
			bRewireInProgress = true
			iTotalWiresToRecreate = CollectedWires01.Length + CollectedWires02.Length + CollectedWires03.Length + CollectedWires04.Length + CollectedWires05.Length + CollectedWires06.Length + CollectedWires07.Length + CollectedWires08.Length
			
			iRemainingWiresToRecreate = iTotalWiresToRecreate
			
			
			RecreateWireArray(CollectedWires01, akWorkshopRef)
			
			if(CollectedWires02.Length > 0)
				RecreateWireArray(CollectedWires02, akWorkshopRef)				
				
				if(CollectedWires03.Length > 0)
					RecreateWireArray(CollectedWires03, akWorkshopRef)
					
					if(CollectedWires04.Length > 0)
						RecreateWireArray(CollectedWires04, akWorkshopRef)
						
						if(CollectedWires05.Length > 0)
							RecreateWireArray(CollectedWires05, akWorkshopRef)
							
							if(CollectedWires05.Length > 0)
								RecreateWireArray(CollectedWires05, akWorkshopRef)
								
								if(CollectedWires06.Length > 0)
									RecreateWireArray(CollectedWires06, akWorkshopRef)
									
									if(CollectedWires07.Length > 0)
										RecreateWireArray(CollectedWires07, akWorkshopRef)
										
										if(CollectedWires08.Length > 0)
											RecreateWireArray(CollectedWires08, akWorkshopRef)
										endif
									endif
								endif
							endif
						endif
					endif
				endif
			endif
		endif
		
		if(bUseHUDProgressModule)
			HUDFrameworkManager.CompleteProgressBar(Self, sProgressBarID_Rewire)
		endif
		
		Debug.MessageBox("Rewiring of settlement complete!\n\nForcing power transmission...")
		
		; Wires recreated - transmit power again
		ForcePowerTransmission(akWorkshopRef)
		
		Utility.Wait(2.0)
		Debug.MessageBox("Power grid fully recreated.\n\nIt is now safe to exit Workshop Mode!")
	else
		Debug.MessageBox("Failed to find connected wiring.")
	endif
	
	if(bUseHUDProgressModule)
		; Make sure progress bar closed
		HUDFrameworkManager.CompleteProgressBar(Self, sProgressBarID_Rewire)
	endif
	
	bRewireInProgress = false
	
	return true
EndFunction

Function RecreateWireArray(ObjectReference[] aWireArray, WorkshopScript akWorkshopRef)
	If( akWorkshopRef == None )
		Debug.Trace( Self + " :: RecreateWireArray() :: Cannot create a PowerGrid without a WorkshopRef!" )
		Return
	EndIf
	int i = aWireArray.Length
	while(i > 0)
		i -= 1
		
		iRemainingWiresToRecreate -= 1
		
		if(bRewireInProgress && bUseHUDProgressModule)
			Float fPercentComplete = iRemainingWiresToRecreate as Float/iTotalWiresToRecreate as Float
			Int iWholePercentageComplete = Math.Ceiling(fPercentComplete) * 100
			
			HUDFrameworkManager.UpdateProgressBarPercentage(Self, sProgressBarID_Rewire, iWholePercentageComplete)		
		endif
		
		ObjectReference[] kConnected = F4SEManager.GetConnectedObjects(aWireArray[i])
		
		ModTrace("     Deleting wire " + aWireArray[i])
		
		if(aWireArray[i] != None)
			if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
				akWorkshopRef.StartWorkshop(true)
			endif
			
			; TODO - Once F4SE implements Scrap, we need to remove this routing through PowerGridTools
			if( ! PowerGridTools.Scrap(aWireArray[i], akWorkshopRef))
				ModTrace("     PowerGridTools.Scrap failed. Manually removing wire " + aWireArray[i])
				aWireArray[i].SetLinkedRef(None, WorkshopItemKeyword)
				aWireArray[i].Disable(false)
				aWireArray[i].SetPosition(0.0, 0.0, 0.0)
				aWireArray[i].Delete()
				Utility.Wait(1.0)
			else
				Utility.Wait(0.1) ; Short delay as spamming it seems to occasionally cause crashes in the same way doing so outside workshop mode doe
			endif
		
			aWireArray[i] = None
		endif
			
		ObjectReference kWireRef = F4SEManager.AttachWireV2(akWorkshopRef, kConnected[0], kConnected[1])
		
		if(kWireRef == None)
			; Try using CreateWire
			kWireRef = F4SEManager.CreateWireV2(akWorkshopRef, kConnected[0], kConnected[1])
			
			if(kWireRef == None)
				ModTrace("[WorkshopObjectManager] Failed to recreate wire between " + kConnected[0] + " and " + kConnected[1] + ".")
			else
				ModTrace("[WorkshopObjectManager] CreateWire recreated wire between " + kConnected[0] + " and " + kConnected[1] + ".")
				kWireRef.Enable(false)
			endif
		else
			ModTrace("[WorkshopObjectManager] AttachWire recreated wire between " + kConnected[0] + " and " + kConnected[1] + ".")
			kWireRef.Enable(false)
		endif
	endWhile
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
		
	ObjectReference[] kLinkedRefs = akWorkshopRef.GetLinkedRefChildren(WorkshopItemKeyword)
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



Function DumpWorkshopResourceObjects(WorkshopScript akWorkshopRef = None, ActorValue aSpecificAV = None, Bool abFetchAll = false)
	if(akWorkshopRef == None)
		akWorkshopRef = WorkshopFramework:WSFW_API.GetNearestWorkshop(PlayerRef)
	endif
	
	ObjectReference[] ResourceObjects = new ObjectReference[0]
	
	if(abFetchAll)
		ResourceObjects = akWorkshopRef.GetWorkshopResourceObjects()
	else
		ResourceObjects = akWorkshopRef.GetWorkshopResourceObjects(aSpecificAV)
	endif
	
	ModTrace("[WorkshopObjectManager] DumpWorkshopItems(" + akWorkshopRef + ", " + aSpecificAV + ")")
	if(aSpecificAV != None)
		int i = 0
		while(i < ResourceObjects.Length)
			ModTrace("                      " + ResourceObjects[i] + ": " + ResourceObjects[i].GetValue(aSpecificAV) + "/" + ResourceObjects[i].GetBaseValue(aSpecificAV))
			i += 1
		endWhile
	else
		int i = 0
		while(i < ResourceObjects.Length)
			ModTrace("                      " + ResourceObjects[i])
			i += 1
		endWhile
	endif
	ModTrace("[WorkshopObjectManager] Finished DumpWorkshopItems(" + akWorkshopRef + ", " + aSpecificAV + ")")
EndFunction