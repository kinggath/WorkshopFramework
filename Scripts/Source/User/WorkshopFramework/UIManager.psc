; ---------------------------------------------
; WorkshopFramework:UIManager.psc - by kinggath
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

Scriptname WorkshopFramework:UIManager extends WorkshopFramework:Library:SlaveQuest
{ Handles various user interface related tasks }

import WorkshopFramework:Library:DataStructures
import WorkshopFramework:Library:UtilityFunctions


CustomEvent BarterSelectMenu_SelectionMade
CustomEvent Settlement_SelectionMade

; ---------------------------------------------
; Consts
; ---------------------------------------------

Group DoNotEdit
	int Property iAcceptStolen_None = 0 Auto Const
	int Property iAcceptStolen_Only = 1 Auto Const
	int Property iAcceptStolen_Either = 2 Auto Const
EndGroup

; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------

Group Controllers
	WorkshopParentScript Property WorkshopParent Auto Const Mandatory
EndGroup

Group Aliases
	ReferenceAlias Property PhantomVendorAlias Auto Const Mandatory
	ReferenceAlias Property PhantomVendorContainerAlias Auto Const Mandatory
	ReferenceAlias Property SelectCache_Settlements Auto Const Mandatory
	ReferenceAlias Property SafeSpawnPoint Auto Const Mandatory
EndGroup

Group Assets
	Formlist Property PhantomVendorBuySellList Auto Const Mandatory
	
	Faction Property PhantomVendorFaction_Either Auto Const Mandatory
	Faction Property PhantomVendorFaction_StolenOnly Auto Const Mandatory
	Faction Property PhantomVendorFaction_NonStolenOnly Auto Const Mandatory
	
	Faction Property PhantomVendorFaction_Either_Unfiltered Auto Const Mandatory
	Faction Property PhantomVendorFaction_StolenOnly_Unfiltered Auto Const Mandatory
	Faction Property PhantomVendorFaction_NonStolenOnly_Unfiltered Auto Const Mandatory
EndGroup

Group SettlementSelect
	Form[] Property Selectables_Settlements Auto Const Mandatory
	ReferenceAlias[] Property ApplyNames_Settlements Auto Const Mandatory
	LocationAlias[] Property StoreNames_Settlements Auto Const Mandatory
	Keyword Property SelectableSettlementKeyword Auto Const Mandatory
	Form Property VendorName_Settlements Auto Const Mandatory
EndGroup

; ---------------------------------------------
; Vars
; ---------------------------------------------

bool bPhantomVendorInUse = false
ObjectReference kCurrentCacheRef ; Stores latest cache ref so we can return the items to it
WorkshopScript[] kLastSelectedSettlements
Int iBarterSelectCallbackID = -1

Form[] SelectionPool01
Form[] SelectionPool02
Form[] SelectionPool03
Form[] SelectionPool04
Form[] SelectionPool05
Form[] SelectionPool06
Form[] SelectionPool07
Form[] SelectionPool08 ; Up to 1024 items

Formlist SelectedResultsFormlist

int iTotalSelected = 0
int iAwaitingSorting = 0

int Property iSplitFormlistIncrement = 30 Auto Hidden ; We might need to make this editable to avoid crashing when showing barter menu for a large formlist

; ---------------------------------------------
; Events 
; ---------------------------------------------

Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)
	if(asMenuName == "BarterMenu" && ! abOpening)
		UnregisterForMenuOpenCloseEvent("BarterMenu")
		RemoveAllInventoryEventFilters()
		
		; We should have already unregistered for this, but let's just make sure
		ObjectReference kPhantomVendorContainerRef = PhantomVendorContainerAlias.GetRef()
		UnregisterForRemoteEvent(kPhantomVendorContainerRef, "OnItemAdded")
		
		ProcessBarterSelection()
		
		; Unlock phantom vendor system
		bPhantomVendorInUse = false
	endif
EndEvent

Event ObjectReference.OnItemAdded(ObjectReference akAddedTo, Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
    ObjectReference kPhantomVendorContainerRef = PhantomVendorContainerAlias.GetRef()
	
    if(akAddedTo == kPhantomVendorContainerRef)
		iAwaitingSorting -= 1
		
		if( ! SortItem(akBaseItem))
			kPhantomVendorContainerRef.RemoveItem(akBaseItem) ; Get rid of this so player doesn't assume its a valid option
			ModTrace("[UIManager] Too many items to sort. Lost record of item " + akBaseItem)
		endif
		
		if(iAwaitingSorting <= 0)
			; No longer need to monitor this event as we're only watching for items initially set up via the aAvailableOptionsFormlist
			UnregisterForRemoteEvent(kPhantomVendorContainerRef, "OnItemAdded")
		endif
    endif
EndEvent



; ---------------------------------------------
; Functions 
; ---------------------------------------------
Int Function ShowCachedBarterSelectMenu(Form afBarterDisplayNameForm, ObjectReference aAvailableOptionsCacheContainerReference, Formlist aStoreResultsIn, Keyword[] aFilterKeywords = None, Int aiAcceptStolen = 2)
	if(bPhantomVendorInUse)
		return -1
	endif
	
	bPhantomVendorInUse = true
	
	ResetPhantomVendor()
	PreparePhantomVendor(afBarterDisplayNameForm, aFilterKeywords, aiAcceptStolen)
	
	SelectedResultsFormlist = aStoreResultsIn 
	
	; Add items to inventory and start barter
	Actor kPhantomVendorRef = PhantomVendorAlias.GetActorRef()
	ObjectReference kPhantomVendorContainerRef = PhantomVendorContainerAlias.GetRef()
		; Store cache ref so we can return the cache items
	kCurrentCacheRef = aAvailableOptionsCacheContainerReference
	iAwaitingSorting += kCurrentCacheRef.GetItemCount()
	
	; Monitor for the items to be added from the selection pool	
	RegisterForRemoteEvent(kPhantomVendorContainerRef, "OnItemAdded")
	
	kCurrentCacheRef.RemoveAllItems(kPhantomVendorContainerRef)
	
	; Brief pause to give OnItemAdded events time
	Utility.Wait(0.1 * (iAwaitingSorting/iSplitFormlistIncrement))
	
	iBarterSelectCallbackID = Utility.RandomInt(1, 999999)
	kPhantomVendorRef.ShowBarterMenu()
	
	return iBarterSelectCallbackID
EndFunction


int Function ShowFormlistBarterSelectMenu(Form afBarterDisplayNameForm, Formlist aAvailableOptionsFormlist, Formlist aStoreResultsIn, Keyword[] aFilterKeywords = None, Int aiAcceptStolen = 2)
	if(bPhantomVendorInUse)
		return -1
	endif
	
	bPhantomVendorInUse = true
	
	ResetPhantomVendor()
	PreparePhantomVendor(afBarterDisplayNameForm, aFilterKeywords, aiAcceptStolen)
	
	SelectedResultsFormlist = aStoreResultsIn 
	
	; Add items to vendor container and start barter
	Actor kPhantomVendorRef = PhantomVendorAlias.GetActorRef()
	ObjectReference kPhantomVendorContainerRef = PhantomVendorContainerAlias.GetRef()
	
	; Monitor for the items to be added from the selection pool	
	RegisterForRemoteEvent(kPhantomVendorContainerRef, "OnItemAdded")
	
	Int iListSize = aAvailableOptionsFormlist.GetSize()
	iAwaitingSorting = iListSize
	int i = 0
	int iLastAdded = 0
	while(i < iListSize)
		if(Mod((i + 1), iSplitFormlistIncrement) == 0)
			Var[] kArgs = new Var[4]
			kArgs[0] = aAvailableOptionsFormlist
			kArgs[1] = kPhantomVendorContainerRef
			kArgs[2] = i
			kArgs[3] = iSplitFormlistIncrement
			
			Utility.CallGlobalFunctionNoWait("WorkshopFramework:Library:UtilityFunctions", "AddFormlistItemsToContainer", kArgs)
			
			Utility.Wait(0.1) ; Pause to slow down OnItemAdded events and ensure all items are added before ShowBarterMenu is called below
			
			iLastAdded = i + iSplitFormlistIncrement - 1
		endif
		
		i += 1
	endWhile
	
	if(iLastAdded + 1 < iListSize)
		; Still entries remaining
		Var[] kArgs = new Var[3]
		kArgs[0] = aAvailableOptionsFormlist
		kArgs[1] = kPhantomVendorContainerRef
		kArgs[2] = iLastAdded
		kArgs[3] = iSplitFormlistIncrement
		
		Utility.CallGlobalFunctionNoWait("WorkshopFramework:Library:UtilityFunctions", "AddFormlistItemsToContainer", kArgs)
		
		Utility.Wait(0.1) ; Pause to slow down OnItemAdded events and ensure all items are added before ShowBarterMenu is called below
	endif
	
	iBarterSelectCallbackID = Utility.RandomInt(1, 999999)
	kPhantomVendorRef.ShowBarterMenu()
	
	return iBarterSelectCallbackID
EndFunction


int Function ShowBarterSelectMenu(Form afBarterDisplayNameForm, Form[] aAvailableOptions, Formlist aStoreResultsIn, Keyword[] aFilterKeywords = None, Int aiAcceptStolen = 2)
	if(bPhantomVendorInUse)
		return -1
	endif
	
	bPhantomVendorInUse = true
	
	ResetPhantomVendor()
	PreparePhantomVendor(afBarterDisplayNameForm, aFilterKeywords, aiAcceptStolen)
	
	SelectedResultsFormlist = aStoreResultsIn 
	
	; Add items to vendor container and start barter
	Actor kPhantomVendorRef = PhantomVendorAlias.GetActorRef()
	ObjectReference kPhantomVendorContainerRef = PhantomVendorContainerAlias.GetRef()
	
	Int iCount = aAvailableOptions.Length
	int i = 0
	while(i < iCount)
		Form FormToAdd = aAvailableOptions[i]
		
		if(FormToAdd != None)
			if(SortItem(FormToAdd))
				kPhantomVendorContainerRef.AddItem(FormToAdd)
			endif
		endif
		
		i += 1
	endWhile
		
	iBarterSelectCallbackID = Utility.RandomInt(1, 999999)
	kPhantomVendorRef.ShowBarterMenu()
	
	return iBarterSelectCallbackID
EndFunction



Function ProcessBarterSelection()
	ProcessItemPool(SelectionPool01)
	ProcessItemPool(SelectionPool02)
	ProcessItemPool(SelectionPool03)
	ProcessItemPool(SelectionPool04)
	ProcessItemPool(SelectionPool05)
	ProcessItemPool(SelectionPool06)
	ProcessItemPool(SelectionPool07)
	ProcessItemPool(SelectionPool08)
	
	; Return any remaining items to player as they were not part of our pool, player likely dropped them in to see what would happen
	ObjectReference kPhantomVendorContainerRef = PhantomVendorContainerAlias.GetRef()
	kPhantomVendorContainerRef.RemoveAllItems(PlayerRef)
	
	if(kCurrentCacheRef == SelectCache_Settlements.GetRef())
		Var[] kArgs = new Var[kLastSelectedSettlements.Length + 2]
		kArgs[0] = iBarterSelectCallbackID
		kArgs[1] = kLastSelectedSettlements.Length
		
		int i = 0		
		while(i < kLastSelectedSettlements.Length)
			int iNextArgsIndex = 2 + i
			kArgs[iNextArgsIndex] = kLastSelectedSettlements[i]
			
			i += 1
		endWhile
		
		; Send event
		SendCustomEvent("Settlement_SelectionMade", kArgs)		
	else
		; Send event
		Var[] kArgs = new Var[3]
		kArgs[0] = iBarterSelectCallbackID
		kArgs[1] = iTotalSelected
		kArgs[2] = SelectedResultsFormlist
		
		SendCustomEvent("BarterSelectMenu_SelectionMade", kArgs)
	endif
	
	; Clear our stored cache ref
	kCurrentCacheRef = None
	SelectCache_Settlements.GetRef().RemoveAllItems()
	
	; Clear out memory used by having phantom vendor set up
	ResetPhantomVendor()
EndFunction


Bool Function SortItem(Form aItemType)
	if(SelectionPool01 == None)
		SelectionPool01 = new Form[0]
	endif
	
	if( ! SortToPool(SelectionPool01, aItemType))
		if(SelectionPool02 == None)
			SelectionPool02 = new Form[0]
		endif
		
		if( ! SortToPool(SelectionPool02, aItemType))
			if(SelectionPool03 == None)
				SelectionPool03 = new Form[0]
			endif
	
			if( ! SortToPool(SelectionPool03, aItemType))
				if(SelectionPool04 == None)
					SelectionPool04 = new Form[0]
				endif
	
				if( ! SortToPool(SelectionPool04, aItemType))
					if(SelectionPool05 == None)
						SelectionPool05 = new Form[0]
					endif
	
					if( ! SortToPool(SelectionPool05, aItemType))    
						if(SelectionPool06 == None)
							SelectionPool06 = new Form[0]
						endif
	
						if( ! SortToPool(SelectionPool06, aItemType))
							if(SelectionPool07 == None)
								SelectionPool07 = new Form[0]
							endif
							
							if( ! SortToPool(SelectionPool07, aItemType))
								if(SelectionPool08 == None)
									SelectionPool08 = new Form[0]
								endif
								
								if( ! SortToPool(SelectionPool08, aItemType))
									ModTrace("[UIManager] Ran out of space to sort items.")
									return false
								endif
							endif
						endif
					endif
				endif
			endif
		endif
	endif
    
    return true
EndFunction


Bool Function SortToPool(Form[] aItemPool, Form aItemType)
    if(aItemPool.Find(aItemType) >= 0)
        return true
    elseif(aItemPool.Length < 128)
        aItemPool.Add(aItemType)
        return true
    endif
    
    return false
EndFunction


Function ProcessItemPool(Form[] aItemPool)
	ObjectReference kPhantomVendorContainerRef = PhantomVendorContainerAlias.GetRef()
		
    While(aItemPool.Length > 0)
        Form BaseItem = aItemPool[0]
        
		if(PlayerRef.GetItemCount(BaseItem) > 0)
			; return to cache
			PlayerRef.RemoveItem(BaseItem, 1, abSilent = true, akOtherContainer = kCurrentCacheRef)
			
			iTotalSelected += 1
			
			int iSettlementIndex = Selectables_Settlements.Find(BaseItem)
			if(iSettlementIndex >= 0)
				if( ! kLastSelectedSettlements)
					kLastSelectedSettlements = new WorkshopScript[0]
				endif
				
				Location settlementLocation = StoreNames_Settlements[iSettlementIndex].GetLocation()
				
				if(settlementLocation != None)										
					kLastSelectedSettlements.Add(WorkshopParent.GetWorkshopFromLocation(settlementLocation))
				endif
			else
				SelectedResultsFormlist.AddForm(BaseItem)	
			endif
		else
			; Item was left in vendor container, don't count as selected, but return to cache
			kPhantomVendorContainerRef.RemoveItem(BaseItem, 1, abSilent = true, akOtherContainer = kCurrentCacheRef)			
        endif
        
        aItemPool.Remove(0)
    EndWhile
EndFunction


Function ResetPhantomVendor()
	; Reset previous select data
	Actor kPhantomVendorRef = PhantomVendorAlias.GetReference() as Actor
	kPhantomVendorRef.RemoveFromFaction(PhantomVendorFaction_Either)
	kPhantomVendorRef.RemoveFromFaction(PhantomVendorFaction_StolenOnly)
	kPhantomVendorRef.RemoveFromFaction(PhantomVendorFaction_NonStolenOnly)
	
	ObjectReference kPhantomVendorContainerRef = PhantomVendorContainerAlias.GetReference()
	kPhantomVendorContainerRef.RemoveAllItems() ; Get rid of copies from previous
	kPhantomVendorContainerRef.SetActorRefOwner(PlayerRef) ; Prevent player from getting in trouble for stealing
	
	SelectedResultsFormlist = None
	
	; Clear out sorting pools
	iAwaitingSorting = 0
	iTotalSelected = 0
	
	SelectionPool01 = new Form[0]
	SelectionPool02 = new Form[0]
	SelectionPool03 = new Form[0]
	SelectionPool04 = new Form[0]
	SelectionPool05 = new Form[0]
	SelectionPool06 = new Form[0]
	SelectionPool07 = new Form[0]
	SelectionPool08 = new Form[0]
EndFunction


Function PreparePhantomVendor(Form afBarterDisplayNameForm, Keyword[] aFilterKeywords = None, Int aiAcceptStolen = 2)
	Actor kPhantomVendorRef = PhantomVendorAlias.GetReference() as Actor
	ObjectReference kPhantomVendorContainerRef = PhantomVendorContainerAlias.GetRef()
	
	; Setup phantom vendor for this selection	
	if(aFilterKeywords == None || aFilterKeywords.Length == 0)
		if(aiAcceptStolen == iAcceptStolen_None)
			kPhantomVendorRef.AddToFaction(PhantomVendorFaction_NonStolenOnly_Unfiltered)
		elseif(aiAcceptStolen == iAcceptStolen_Only)
			kPhantomVendorRef.AddToFaction(PhantomVendorFaction_StolenOnly_Unfiltered)
		else
			kPhantomVendorRef.AddToFaction(PhantomVendorFaction_Either_Unfiltered)
		endif
		
		AddInventoryEventFilter(None)	
	else		
		int i = 0
		while(i < aFilterKeywords.Length)
			PhantomVendorBuySellList.AddForm(aFilterKeywords[i])
			
			i += 1
		endWhile
		
		if(aiAcceptStolen == iAcceptStolen_None)
			kPhantomVendorRef.AddToFaction(PhantomVendorFaction_NonStolenOnly)
		elseif(aiAcceptStolen == iAcceptStolen_Only)
			kPhantomVendorRef.AddToFaction(PhantomVendorFaction_StolenOnly)
		else
			kPhantomVendorRef.AddToFaction(PhantomVendorFaction_Either)
		endif
		
		
		AddInventoryEventFilter(PhantomVendorBuySellList)	
	endif
	
	RegisterForMenuOpenCloseEvent("BarterMenu")
	
	; Clear previous name by removing from alias
	PhantomVendorAlias.Clear()
	
	; Return to alias 
	PhantomVendorAlias.ForceRefTo(kPhantomVendorRef)
	
	; Stamp text replacement data the Message form expects
	kPhantomVendorRef.AddTextReplacementData("SelectionName", afBarterDisplayNameForm)
EndFunction


; 2.0.0 settlement select system
int Function ShowSettlementBarterSelectMenu(Form afBarterDisplayNameForm = None, WorkshopScript[] akExcludeSettlements = None)
	if(afBarterDisplayNameForm == None)
		afBarterDisplayNameForm = VendorName_Settlements
	endif
	
	kLastSelectedSettlements = new WorkshopScript[0]
	
	ObjectReference kSpawnPoint = SafeSpawnPoint.GetRef()
	ObjectReference kCacheRef_Settlements = SelectCache_Settlements.GetRef()
	kCacheRef_Settlements.RemoveAllItems() ; We can't actually cache since player can install/uninstall settlements
	
	Location[] WorkshopLocations = WorkshopParent.WorkshopLocations
	WorkshopScript[] Workshops = WorkshopParent.Workshops
	WorkshopScript NukaWorldDummyWorkshop = None
	if(Game.IsPluginInstalled("DLCNukaWorld.esm"))
		NukaWorldDummyWorkshop = Game.GetFormFromFile(0x00047DFB, "DLCNukaWorld.esm") as WorkshopScript
		
		if( ! akExcludeSettlements)
			akExcludeSettlements = new WorkshopScript[0]
		endif
		
		akExcludeSettlements.Add(NukaWorldDummyWorkshop)
	endif
	
	int i = 0
	while(i < WorkshopLocations.Length)
		if(akExcludeSettlements == None || akExcludeSettlements.Find(Workshops[i]) < 0)
			StoreNames_Settlements[i].ForceLocationTo(WorkshopLocations[i])
			ObjectReference kSelectorRef = kSpawnPoint.PlaceAtMe(Selectables_Settlements[i])
			ApplyNames_Settlements[i].ApplyToRef(kSelectorRef)
			
			kCacheRef_Settlements.AddItem(kSelectorRef)
		endif
		
		i += 1
	endWhile
	
	Keyword[] FilterKeywords = new Keyword[1]
	FilterKeywords[0] = SelectableSettlementKeyword
	
	return ShowCachedBarterSelectMenu(afBarterDisplayNameForm, aAvailableOptionsCacheContainerReference = kCacheRef_Settlements, aStoreResultsIn = None, aFilterKeywords = FilterKeywords)
EndFunction


Function TestBarterSystem(int iTestNameChange = 0)
	Formlist scavList = Game.GetFormFromFile(0x00007B04, "WorkshopFramework.esm") as Formlist
	
	Form nameForm = Game.GetFormFromFile(0x0024A00F, "Fallout4.esm")
	
	if(iTestNameChange == 1)
		nameForm = Game.GetFormFromFile(0x00249AEB, "Fallout4.esm")
	endif
	
	Formlist holdList = Game.GetFormFromFile(0x0001CAE7, "WorkshopFramework.esm") as Formlist
	
	ShowFormlistBarterSelectMenu(nameForm, scavList, holdList)
EndFunction

Function TestSettlementBarterSystem()
	ShowSettlementBarterSelectMenu(None, None)
EndFunction

Function CheckBarterContainer()
	Debug.MessageBox(PhantomVendorContainerAlias.GetRef().GetItemCount())
EndFunction