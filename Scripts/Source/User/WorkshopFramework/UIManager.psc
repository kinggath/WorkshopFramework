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

Float fBarterWaitLoopIncrement = 0.1 Const
Float fWaitForMenuAvailableLoopIncrement = 0.1 Const
int iMessageSelectorSource_Array = 0 Const
int iMessageSelectorSource_Formlist = 1 Const
int iMessageSelectorReturn_Failure = -1 Const
int iMessageSelectorReturn_Cancel = -2 Const

int iSortingComplete = -999 Const

String sUILog = "WSFW_UI" Const

Group DoNotEdit
	int Property iAcceptStolen_None = 0 autoReadOnly
	int Property iAcceptStolen_Only = 1 autoReadOnly
	int Property iAcceptStolen_Either = 2 autoReadOnly
EndGroup

; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------

Group Controllers
	WorkshopParentScript Property WorkshopParent Auto Const Mandatory
EndGroup

Group Aliases
	ReferenceAlias Property PhantomVendorAlias Auto Const Mandatory
	{ Obsolete }
	ReferenceAlias Property PhantomVendorContainerAlias Auto Const Mandatory
	{ Obsolete }
	
	ReferenceAlias[] Property PhantomVendorAliases Auto Const Mandatory
	ReferenceAlias[] Property PhantomVendorContainerAliases Auto Const Mandatory
	ReferenceAlias Property SelectCache_Settlements Auto Const Mandatory
	ReferenceAlias Property SafeSpawnPoint Auto Const Mandatory
EndGroup

Group Assets
	Formlist Property SortingFormlist01 Auto Const Mandatory
	{ Blank formlist functions can use for sorting }
	
	Formlist Property PhantomVendorBuySellList Auto Const Mandatory
	{ Obsolete }
	
	Formlist[] Property PhantomVendorBuySellLists Auto Const Mandatory
	
	Faction Property PhantomVendorFaction_Either Auto Const Mandatory
	Faction Property PhantomVendorFaction_StolenOnly Auto Const Mandatory
	Faction Property PhantomVendorFaction_NonStolenOnly Auto Const Mandatory
	
	Faction Property PhantomVendorFaction_Either_Unfiltered Auto Const Mandatory
	Faction Property PhantomVendorFaction_StolenOnly_Unfiltered Auto Const Mandatory
	Faction Property PhantomVendorFaction_NonStolenOnly_Unfiltered Auto Const Mandatory
	
	Faction Property MakeStolenFaction Auto Const Mandatory
EndGroup

Group MessageSelectorSystem
	Message Property MessageSelector_Default Auto Const Mandatory
	Message Property MessageSelector_NoOptions Auto Const Mandatory
	Form Property NameHolderForm_SelectAnOption Auto Const Mandatory
	GlobalVariable Property MenuControl_MessageSelector_MoreInfo Auto Const Mandatory
	
	ReferenceAlias Property MessageSelectorTitleAlias Auto Const Mandatory
	ReferenceAlias[] Property MessageSelectorItemLineAliases Auto Const Mandatory
	{ REMINDER: You must set up different Message forms to handle more aliases, our default (MessageSelector_Default) only displays one for the title of the selection type and another for the current option. }
	
	Form Property RenamableDummyForm Auto Const Mandatory
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

Actor kCurrentPhantomVendor
ObjectReference kCurrentPhantomVendorContainer
Formlist kCurrentBuySellList

bool bMessageSelectorInUse = false
Int iMessageSelector_SelectedOption = -1
Form[] MessageSelectorFormArray
Formlist MessageSelectorFormlist

Form[] SelectionPool01
Form[] SelectionPool02
Form[] SelectionPool03
Form[] SelectionPool04
Form[] SelectionPool05
Form[] SelectionPool06
Form[] SelectionPool07
Form[] SelectionPool08 ; Up to 1024 items

; Store barter modifiers sent from function call
Bool bVendorSideEqualsChoice = false
Bool bUsingReferences = false ; OBSOLETE
Bool bAvailableOptionItemsAreReferences = false
Bool bStartBarterSelectedFormlistAreReferences = false
Bool bStoreResultsAsReferences = false
Bool bDestroyNonCachedBarterSelectReferences = false
Formlist SelectedResultsFormlist
Formlist StartBarterSelectedFormList

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
		UnregisterForRemoteEvent(kCurrentPhantomVendorContainer, "OnItemAdded")
		
		ProcessBarterSelection()
		
		; Unlock phantom vendor system
		bPhantomVendorInUse = false
	endif
EndEvent

Event ObjectReference.OnItemAdded(ObjectReference akAddedTo, Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
	ModTraceCustom(sUILog, " item " + akItemReference + " (base: " + akBaseItem + ") added to " + akAddedTo + ", sorting. " + iAwaitingSorting + " items remaining.")
	
	if(akAddedTo == kCurrentPhantomVendorContainer)				
		Form SortMe = akBaseItem
		
		Bool bNewRefCreated = false
		if(akItemReference == None)
			; Our barter system seems to only work correctly with references - likely a limitation of the dynamic updating of the vendor filter formlist. So we'll stash a reference copy in the vendor's "pockets" until we're done processing these events, then we'll move all of the items to the vendor container after we've unregistered for OnItemAdded (otherwise we'd have an infinite loop if we just dropped them into the vendor container). Failure to use refs causes the non-ref items to be removed when ShowBarterMenu is called.
			
			kCurrentPhantomVendorContainer.RemoveItem(akBaseItem)
			
			akItemReference = SafeSpawnPoint.GetRef().PlaceAtMe(akBaseItem)
			bNewRefCreated = true
			
			if(kCurrentPhantomVendor.IsInFaction(PhantomVendorFaction_StolenOnly) || kCurrentPhantomVendor.IsInFaction(PhantomVendorFaction_StolenOnly_Unfiltered))
				akItemReference.SetFactionOwner(MakeStolenFaction)
				
				ModTraceCustom(sUILog, " New ref " + akItemReference + " (form " + akBaseItem + ") created for stolen selection, adding to StolenFaction.")
			else
				ModTraceCustom(sUILog, " New ref " + akItemReference + " (form " + akBaseItem + ") created for selection.")
			endif
		endif
		
		if(bAvailableOptionItemsAreReferences && akItemReference != None)
			SortMe = akItemReference
		endif
		
		if(SortItem(SortMe))
			if(StartBarterSelectedFormList != None)
				ModTraceCustom(sUILog, " " + SortMe + " sorted. Determining which container to deposit. StartBarterSelectedFormList: " + StartBarterSelectedFormList + ". In start selected list?: " + StartBarterSelectedFormList.HasForm(akItemReference) + ", is base in list?: " + StartBarterSelectedFormList.HasForm(akBaseItem))
			endif
			
			if(StartBarterSelectedFormList != None && (StartBarterSelectedFormList.HasForm(akItemReference) || ( ! bStartBarterSelectedFormlistAreReferences && StartBarterSelectedFormList.HasForm(akBaseItem))))
				if(bVendorSideEqualsChoice)
					kCurrentPhantomVendor.AddItem(akItemReference)
					
					ModTraceCustom(sUILog, " Starting Selected: " + akItemReference + " (form " + akBaseItem + ") adding to vendor inventory.")
				else
					ModTraceCustom(sUILog, " Starting Selected: " + akItemReference + " (form " + akBaseItem + ") adding to player container " + PlayerRef)
					
					PlayerRef.AddItem(akItemReference, abSilent = true)
				endif
			elseif(bVendorSideEqualsChoice)
				PlayerRef.AddItem(akItemReference, abSilent = true)
				
				ModTraceCustom(sUILog, " " + akItemReference + " (form " + akBaseItem + ") adding to player temp container " + PlayerRef)
			else
				kCurrentPhantomVendor.AddItem(akItemReference)
				
				ModTraceCustom(sUILog, " " + akItemReference + " (form " + akBaseItem + ") adding to vendor inventory.")
			endif
		else
			kCurrentPhantomVendorContainer.RemoveItem(akItemReference) ; Get rid of this so player doesn't assume its a valid option
			ModTraceCustom(sUILog, " Too many items to sort. Lost record of item " + akBaseItem)
		endif
		
		iAwaitingSorting -= 1
		if(iAwaitingSorting <= 0)
			Utility.Wait(1.0)
			; No longer need to monitor this event
			UnregisterForRemoteEvent(kCurrentPhantomVendorContainer, "OnItemAdded")
			
			; Move any refs we created into the selection container now that we've unregistered for OnItemAdded
			kCurrentPhantomVendor.RemoveAllItems(kCurrentPhantomVendorContainer)
			
			iAwaitingSorting = iSortingComplete
			ModTraceCustom(sUILog, " Completed sorting of barter items. Vendor container " + kCurrentPhantomVendorContainer + " has " + kCurrentPhantomVendorContainer.GetItemCount() + " items. The vendor has " + kCurrentPhantomVendor.GetItemCount() + " items.")
		endif
    endif
EndEvent



; ---------------------------------------------
; Functions 
; ---------------------------------------------

Function HandleGameLoaded()
	Debug.OpenUserLog(sUILog)
	
	Parent.HandleGameLoaded()
	
	bPhantomVendorInUse = false ; Make sure this never gets stuck
	iAwaitingSorting = iSortingComplete ; Make sure sorting never gets stuck
EndFunction

	; ---------------------------------------------
	; Barter Menu System 
	; ---------------------------------------------

Int Function ShowCachedBarterSelectMenu(Form afBarterDisplayNameForm, ObjectReference aAvailableOptionsCacheContainerReference, Formlist aStoreResultsIn, Keyword[] aFilterKeywords = None, Int aiAcceptStolen = 2)
	return ShowCachedBarterSelectMenuV4(afBarterDisplayNameForm, aAvailableOptionsCacheContainerReference, aStoreResultsIn, aFilterKeywords, aiAcceptStolen)
EndFunction


Int Function ShowCachedBarterSelectMenuV2(Form afBarterDisplayNameForm, ObjectReference aAvailableOptionsCacheContainerReference, Formlist aStoreResultsIn, Keyword[] aFilterKeywords = None, Int aiAcceptStolen = 2, Formlist aStartBarterSelectedFormlist = None, Bool abVendorSideEqualsChoice = false, Bool abUsingReferences = false)
	return ShowCachedBarterSelectMenuV4(afBarterDisplayNameForm, aAvailableOptionsCacheContainerReference, aStoreResultsIn, aFilterKeywords, aiAcceptStolen, aStartBarterSelectedFormlist, abVendorSideEqualsChoice, abUsingReferences, abStartBarterSelectedFormlistAreReferences = abUsingReferences, abStoreResultsAsReferences = abUsingReferences)
EndFunction

Int Function ShowCachedBarterSelectMenuV3(Form afBarterDisplayNameForm, ObjectReference aAvailableOptionsCacheContainerReference, Formlist aStoreResultsIn, Keyword[] aFilterKeywords = None, Int aiAcceptStolen = 2, Formlist aStartBarterSelectedFormlist = None, Bool abVendorSideEqualsChoice = false, Bool abUsingReferences = false, Float afMaxWaitForBarterSelect = 0.0)
	return ShowCachedBarterSelectMenuV4(afBarterDisplayNameForm, aAvailableOptionsCacheContainerReference, aStoreResultsIn, aFilterKeywords, aiAcceptStolen, aStartBarterSelectedFormlist, abVendorSideEqualsChoice, abAvailableOptionItemsAreReferences = abUsingReferences, abStartBarterSelectedFormlistAreReferences = abUsingReferences, abStoreResultsAsReferences = abUsingReferences, afMaxWaitForBarterSelect = afMaxWaitForBarterSelect)
EndFunction

Int Function ShowCachedBarterSelectMenuV4(Form afBarterDisplayNameForm, ObjectReference aAvailableOptionsCacheContainerReference, Formlist aStoreResultsIn, Keyword[] aFilterKeywords = None, Int aiAcceptStolen = 2, Formlist aStartBarterSelectedFormlist = None, Bool abVendorSideEqualsChoice = false, Bool abAvailableOptionItemsAreReferences = false, Bool abStartBarterSelectedFormlistAreReferences = false, Bool abStoreResultsAsReferences = false, Float afMaxWaitForBarterSelect = 0.0)
	if(bPhantomVendorInUse)
		if(afMaxWaitForBarterSelect != 0.0)
			Float fWaitedTime = 0.0
			if(afMaxWaitForBarterSelect < 0)
				afMaxWaitForBarterSelect = 99999999
			endif
			
			while(bPhantomVendorInUse && fWaitedTime < afMaxWaitForBarterSelect)
				Utility.WaitMenuMode(fWaitForMenuAvailableLoopIncrement)
				fWaitedTime += fWaitForMenuAvailableLoopIncrement
			endWhile
		else
			return -1
		endif
	endif
	
	bPhantomVendorInUse = true
	
	ResetPhantomVendors()
	ModTraceCustom(sUILog, " ShowCachedBarterSelectMenu called. aFilterKeywords = " + aFilterKeywords + ", aiAcceptStolen = " + aiAcceptStolen)
	PreparePhantomVendor(afBarterDisplayNameForm, aFilterKeywords, aiAcceptStolen)
	
	bVendorSideEqualsChoice = abVendorSideEqualsChoice
	bAvailableOptionItemsAreReferences = abAvailableOptionItemsAreReferences
	bStartBarterSelectedFormlistAreReferences = abStartBarterSelectedFormlistAreReferences
	bStoreResultsAsReferences = abStoreResultsAsReferences
	bDestroyNonCachedBarterSelectReferences = false
	SelectedResultsFormlist = aStoreResultsIn 
	StartBarterSelectedFormList = aStartBarterSelectedFormlist
	
	
	if(kCurrentPhantomVendorContainer == None)
		bPhantomVendorInUse = false
		Debug.MessageBox("Workshop Framework Error\n\nUnable to start barter menu system.")
		return -1
	endif
	
	; Add items to inventory and start barter
	
	; Store cache ref so we can return the cache items
	kCurrentCacheRef = aAvailableOptionsCacheContainerReference
	iAwaitingSorting += kCurrentCacheRef.GetItemCount()
	
	ModTraceCustom(sUILog, " ShowCachedBarterSelectMenu Post PreparePhantomVendor: kCurrentCacheRef: " + kCurrentCacheRef + " with " + iAwaitingSorting + " items, kCurrentPhantomVendor: " + kCurrentPhantomVendor + ", kCurrentPhantomVendorContainer: " + kCurrentPhantomVendorContainer)
	
	if(iAwaitingSorting > 0)
		; Monitor for the items to be added from the selection pool	
		RegisterForRemoteEvent(kCurrentPhantomVendorContainer, "OnItemAdded")
		ModTraceCustom(sUILog, " Moving all " + kCurrentCacheRef.GetItemCount() + " items from " + kCurrentCacheRef + " to " + kCurrentPhantomVendorContainer)
		kCurrentCacheRef.RemoveAllItems(kCurrentPhantomVendorContainer, abKeepOwnership = true)
		
		; Wait for OnItemAdded events to complete
		int iWaitCount = 0
		int iMaxWaitCount = iAwaitingSorting	
			; Start by waiting for a minimal amount of time based on number of items
		while(iAwaitingSorting > 0 && iWaitCount < iMaxWaitCount)
			Utility.Wait(0.1)
			iWaitCount += 1
		endWhile
		
		iWaitCount = 0
		; Next attempt to wait a couple extra seconds until iAwaitingSorting is marked as iSortingComplete
		while(iAwaitingSorting <= 0 && iAwaitingSorting > iSortingComplete && iWaitCount < 20)
			Utility.Wait(0.1) 
			iWaitCount += 1
		endWhile
	endif
	
	iBarterSelectCallbackID = Utility.RandomInt(1, 999999)
	
	ModTraceCustom(sUILog, " Pause over, calling ShowBarterMenu on " + kCurrentPhantomVendor + ", iBarterSelectCallbackID = " + iBarterSelectCallbackID)
	
	kCurrentPhantomVendor.ShowBarterMenu()
	
	ModTraceCustom(sUILog, " ShowBarterMenu called, returning iBarterSelectCallbackID = " + iBarterSelectCallbackID)
	
	return iBarterSelectCallbackID
EndFunction

; ------------------------------------
; ShowCachedBarterSelectMenuAndWait
;
; This is a simpler version of the ShowCachedBarterSelectMenu function that doesn't require monitoring for an event to know when to get the results. 
;
; Non-wait version above is still preferred if you're using it with something that shouldn't be blocked for long periods of time, as it doesn't hold your calling script the entire time that the player is selecting plus the time for processing the selection afterwards.
; ------------------------------------

Int Function ShowCachedBarterSelectMenuAndWait(Form afBarterDisplayNameForm, ObjectReference aAvailableOptionsCacheContainerReference, Formlist aStoreResultsIn, Keyword[] aFilterKeywords = None, Int aiAcceptStolen = 2, Formlist aStartBarterSelectedFormlist = None, Bool abVendorSideEqualsChoice = false, Bool abUsingReferences = false, Float afMaxWaitTime = 60.0)
	return ShowCachedBarterSelectMenuAndWaitV3(afBarterDisplayNameForm, aAvailableOptionsCacheContainerReference, aStoreResultsIn, aFilterKeywords, aiAcceptStolen, aStartBarterSelectedFormlist, abVendorSideEqualsChoice, abAvailableOptionItemsAreReferences = abUsingReferences, abStartBarterSelectedFormlistAreReferences = abUsingReferences, abStoreResultsAsReferences = abUsingReferences, afMaxWaitTime = afMaxWaitTime)
EndFunction

Int Function ShowCachedBarterSelectMenuAndWaitV2(Form afBarterDisplayNameForm, ObjectReference aAvailableOptionsCacheContainerReference, Formlist aStoreResultsIn, Keyword[] aFilterKeywords = None, Int aiAcceptStolen = 2, Formlist aStartBarterSelectedFormlist = None, Bool abVendorSideEqualsChoice = false, Bool abUsingReferences = false, Float afMaxWaitTime = 60.0, Float afMaxWaitForBarterSelect = 0.0)
	return ShowCachedBarterSelectMenuAndWaitV3(afBarterDisplayNameForm, aAvailableOptionsCacheContainerReference, aStoreResultsIn, aFilterKeywords, aiAcceptStolen, aStartBarterSelectedFormlist, abVendorSideEqualsChoice, abAvailableOptionItemsAreReferences = abUsingReferences, abStartBarterSelectedFormlistAreReferences = abUsingReferences, abStoreResultsAsReferences = abUsingReferences, afMaxWaitTime = afMaxWaitTime, afMaxWaitForBarterSelect = afMaxWaitForBarterSelect)
EndFunction

Int Function ShowCachedBarterSelectMenuAndWaitV3(Form afBarterDisplayNameForm, ObjectReference aAvailableOptionsCacheContainerReference, Formlist aStoreResultsIn, Keyword[] aFilterKeywords = None, Int aiAcceptStolen = 2, Formlist aStartBarterSelectedFormlist = None, Bool abVendorSideEqualsChoice = false, Bool abAvailableOptionItemsAreReferences = false, Bool abStartBarterSelectedFormlistAreReferences = false, Bool abStoreResultsAsReferences = false, Float afMaxWaitTime = 60.0, Float afMaxWaitForBarterSelect = 0.0)
	if(bPhantomVendorInUse) 
		if(afMaxWaitForBarterSelect != 0.0)
			Float fWaitedTime = 0.0
			if(afMaxWaitForBarterSelect < 0)
				afMaxWaitForBarterSelect = 99999999
			endif
			
			while(bPhantomVendorInUse && fWaitedTime < afMaxWaitForBarterSelect)
				Utility.WaitMenuMode(fWaitForMenuAvailableLoopIncrement)
				fWaitedTime += fWaitForMenuAvailableLoopIncrement
			endWhile
		else
			return -1
		endif
	endif   ; REMINDER - do not set this to true after this, as the menu function will do so
	
	Int iResult = ShowCachedBarterSelectMenuV4(afBarterDisplayNameForm, aAvailableOptionsCacheContainerReference, aStoreResultsIn, aFilterKeywords, aiAcceptStolen, aStartBarterSelectedFormlist, abVendorSideEqualsChoice, abAvailableOptionItemsAreReferences, abStartBarterSelectedFormlistAreReferences, abStoreResultsAsReferences, afMaxWaitForBarterSelect = afMaxWaitForBarterSelect)
	
	if(iResult > -1)
		; Callback ID received, let's begin our waiting loop
		Float fWaitedTime = 0.0
		while(bPhantomVendorInUse && fWaitedTime < afMaxWaitTime)
			Utility.WaitMenuMode(fBarterWaitLoopIncrement)
			fWaitedTime += fBarterWaitLoopIncrement
		endWhile
	endif
	
	return iResult
EndFunction

int Function ShowFormlistBarterSelectMenu(Form afBarterDisplayNameForm, Formlist aAvailableOptionsFormlist, Formlist aStoreResultsIn, Keyword[] aFilterKeywords = None, Int aiAcceptStolen = 2)
	return ShowFormlistBarterSelectMenuV5(afBarterDisplayNameForm, aAvailableOptionsFormlist, aStoreResultsIn, aFilterKeywords, aiAcceptStolen)
EndFunction

int Function ShowFormlistBarterSelectMenuV2(Form afBarterDisplayNameForm, Formlist aAvailableOptionsFormlist, Formlist aStoreResultsIn, Keyword[] aFilterKeywords = None, Int aiAcceptStolen = 2, Formlist aStartBarterSelectedFormlist = None, Bool abVendorSideEqualsChoice = false, Bool abUsingReferences = false)
	return ShowFormlistBarterSelectMenuV5(afBarterDisplayNameForm, aAvailableOptionsFormlist, aStoreResultsIn, aFilterKeywords, aiAcceptStolen, aStartBarterSelectedFormlist, abVendorSideEqualsChoice, abUsingReferences, abUsingReferences, abUsingReferences)
EndFunction

int Function ShowFormlistBarterSelectMenuV3(Form afBarterDisplayNameForm, Formlist aAvailableOptionsFormlist, Formlist aStoreResultsIn, Keyword[] aFilterKeywords = None, Int aiAcceptStolen = 2, Formlist aStartBarterSelectedFormlist = None, Bool abVendorSideEqualsChoice = false, Bool abUsingReferences = false, Float afMaxWaitForBarterSelect = 0.0)
	return ShowFormlistBarterSelectMenuV5(afBarterDisplayNameForm, aAvailableOptionsFormlist, aStoreResultsIn, aFilterKeywords, aiAcceptStolen, aStartBarterSelectedFormlist, abVendorSideEqualsChoice, abAvailableOptionItemsAreReferences = abUsingReferences, abStartBarterSelectedFormlistAreReferences = abUsingReferences, abStoreResultsAsReferences = abUsingReferences, abDestroyNonCachedBarterSelectReferences = false, afMaxWaitForBarterSelect = afMaxWaitForBarterSelect)
EndFunction

int Function ShowFormlistBarterSelectMenuV4(Form afBarterDisplayNameForm, Formlist aAvailableOptionsFormlist, Formlist aStoreResultsIn, Keyword[] aFilterKeywords = None, Int aiAcceptStolen = 2, Formlist aStartBarterSelectedFormlist = None, Bool abVendorSideEqualsChoice = false, Bool abAvailableOptionItemsAreReferences = false, Bool abStartBarterSelectedFormlistAreReferences = false, Bool abStoreResultsAsReferences = false, Float afMaxWaitForBarterSelect = 0.0)
	return ShowFormlistBarterSelectMenuV5(afBarterDisplayNameForm, aAvailableOptionsFormlist, aStoreResultsIn, aFilterKeywords, aiAcceptStolen, aStartBarterSelectedFormlist, abVendorSideEqualsChoice, abAvailableOptionItemsAreReferences, abStartBarterSelectedFormlistAreReferences, abStoreResultsAsReferences, abDestroyNonCachedBarterSelectReferences = false, afMaxWaitForBarterSelect = afMaxWaitForBarterSelect)
EndFunction

int Function ShowFormlistBarterSelectMenuV5(Form afBarterDisplayNameForm, Formlist aAvailableOptionsFormlist, Formlist aStoreResultsIn, Keyword[] aFilterKeywords = None, Int aiAcceptStolen = 2, Formlist aStartBarterSelectedFormlist = None, Bool abVendorSideEqualsChoice = false, Bool abAvailableOptionItemsAreReferences = false, Bool abStartBarterSelectedFormlistAreReferences = false, Bool abStoreResultsAsReferences = false, Bool abDestroyNonCachedBarterSelectReferences = false, Float afMaxWaitForBarterSelect = 0.0)
	if(bPhantomVendorInUse) 
		if(afMaxWaitForBarterSelect != 0.0)
			Float fWaitedTime = 0.0
			if(afMaxWaitForBarterSelect < 0)
				afMaxWaitForBarterSelect = 99999999
			endif
			
			while(bPhantomVendorInUse && fWaitedTime < afMaxWaitForBarterSelect)
				Utility.WaitMenuMode(fWaitForMenuAvailableLoopIncrement)
				fWaitedTime += fWaitForMenuAvailableLoopIncrement
			endWhile
		else
			return -1
		endif
	endif
	
	bPhantomVendorInUse = true
	
	ResetPhantomVendors()
	PreparePhantomVendor(afBarterDisplayNameForm, aFilterKeywords, aiAcceptStolen)
	
	SelectedResultsFormlist = aStoreResultsIn 
	bVendorSideEqualsChoice = abVendorSideEqualsChoice
	bAvailableOptionItemsAreReferences = abAvailableOptionItemsAreReferences	
	bStartBarterSelectedFormlistAreReferences = abStartBarterSelectedFormlistAreReferences
	bStoreResultsAsReferences = abStoreResultsAsReferences
	bDestroyNonCachedBarterSelectReferences = abDestroyNonCachedBarterSelectReferences
	StartBarterSelectedFormList = aStartBarterSelectedFormlist
	
	if(kCurrentPhantomVendorContainer == None)
		bPhantomVendorInUse = false
		Debug.MessageBox("Workshop Framework Error\n\nUnable to start barter menu system.")
		return -1
	endif
	
	; Register for event so items get sorted
	RegisterForRemoteEvent(kCurrentPhantomVendorContainer, "OnItemAdded")
	
	; Add items to vendor container and start barter
	ObjectReference kSafeSpawnPoint = SafeSpawnPoint.GetRef()
	
	Int iListSize = aAvailableOptionsFormlist.GetSize()
	iAwaitingSorting = iListSize
	int iExpectedAwaitingValue = iAwaitingSorting
	int i = 0
	while(i < iListSize)
		iExpectedAwaitingValue -= 1
		Form thisForm = aAvailableOptionsFormlist.GetAt(i)
		if(thisForm)
			if(abAvailableOptionItemsAreReferences)
				ModTraceCustom(sUILog, "Adding " + thisForm + " to phantom vendor container " + kCurrentPhantomVendorContainer)
				
				kCurrentPhantomVendorContainer.AddItem(thisForm)
			else
				; Spawning refs, as just adding items does not seem to work well with our dynamic filtering
				ObjectReference kSpawnedRef = kSafeSpawnPoint.PlaceAtMe(thisForm)
				if(kSpawnedRef)	
					ModTraceCustom(sUILog, "Adding " + kSpawnedRef + " of " + thisForm + " to phantom vendor container " + kCurrentPhantomVendorContainer)
					kCurrentPhantomVendorContainer.AddItem(kSpawnedRef)
				else
					Debug.MessageBox("Failed to add ref to vendor container!")
				endif
			endif
			
			if(iAwaitingSorting > 0)
				ModTraceCustom(sUILog, "Waiting for item to sort (when iAwaitingSorting [" + iAwaitingSorting + "] = iExpectedAwaitingValue [" + iExpectedAwaitingValue + "])")
				int iWaitCount = 0
				while(iExpectedAwaitingValue != iAwaitingSorting && iAwaitingSorting != iSortingComplete && iWaitCount < 500)
					Utility.Wait(0.01) ; Need to ensure iAwaitingSorting decrements
					iWaitCount += 1
				endWhile
				
				if(iAwaitingSorting > iExpectedAwaitingValue)
					iAwaitingSorting = iExpectedAwaitingValue
				endif
			endif
		else
			if(iAwaitingSorting > iExpectedAwaitingValue)
				iAwaitingSorting = iExpectedAwaitingValue
			endif
		endif
		
		i += 1
	endWhile	
	
	Utility.Wait(1.0) ; Give it a moment to handle the last OnItemAdded event
	
	iBarterSelectCallbackID = Utility.RandomInt(1, 999999)
	kCurrentPhantomVendor.ShowBarterMenu()
	
	return iBarterSelectCallbackID
EndFunction


int Function ShowRefCollectionBarterSelectMenu(Form afBarterDisplayNameForm, RefCollectionAlias aAvailableOptionsCollection, Formlist aStoreResultsIn, Keyword[] aFilterKeywords = None, Int aiAcceptStolen = 2, Formlist aStartBarterSelectedFormlist = None, Bool abVendorSideEqualsChoice = false, Float afMaxWaitForBarterSelect = 0.0)
	if(bPhantomVendorInUse) 
		if(afMaxWaitForBarterSelect != 0.0)
			Float fWaitedTime = 0.0
			if(afMaxWaitForBarterSelect < 0)
				afMaxWaitForBarterSelect = 99999999
			endif
			
			while(bPhantomVendorInUse && fWaitedTime < afMaxWaitForBarterSelect)
				Utility.WaitMenuMode(fWaitForMenuAvailableLoopIncrement)
				fWaitedTime += fWaitForMenuAvailableLoopIncrement
			endWhile
		else
			return -1
		endif
	endif
	
	bPhantomVendorInUse = true
	
	ResetPhantomVendors()
	PreparePhantomVendor(afBarterDisplayNameForm, aFilterKeywords, aiAcceptStolen)
	
	SelectedResultsFormlist = aStoreResultsIn 
	bVendorSideEqualsChoice = abVendorSideEqualsChoice
	bAvailableOptionItemsAreReferences = true	
	bStartBarterSelectedFormlistAreReferences = true
	bStoreResultsAsReferences = true
	bDestroyNonCachedBarterSelectReferences = false
	StartBarterSelectedFormList = aStartBarterSelectedFormlist
	
	if(kCurrentPhantomVendorContainer == None)
		bPhantomVendorInUse = false
		Debug.MessageBox("Workshop Framework Error\n\nUnable to start barter menu system.")
		return -1
	endif
	
	; Register for event so items get sorted
	RegisterForRemoteEvent(kCurrentPhantomVendorContainer, "OnItemAdded")
	
	; Add items to vendor container and start barter
	ObjectReference kSafeSpawnPoint = SafeSpawnPoint.GetRef()
	
	Int iCount = aAvailableOptionsCollection.GetCount()
	iAwaitingSorting = iCount
	int iExpectedAwaitingValue = iAwaitingSorting
	int i = 0
	while(i < iCount)
		iExpectedAwaitingValue -= 1
		ObjectReference thisRef = aAvailableOptionsCollection.GetAt(i)
		if(thisRef)
			ModTraceCustom(sUILog, "Adding " + thisRef + " to phantom vendor container " + kCurrentPhantomVendorContainer)
			
			kCurrentPhantomVendorContainer.AddItem(thisRef)
			
			if(iAwaitingSorting > 0)
				ModTraceCustom(sUILog, "Waiting for item to sort (when iAwaitingSorting [" + iAwaitingSorting + "] = iExpectedAwaitingValue [" + iExpectedAwaitingValue + "])")
				int iWaitCount = 0
				while(iExpectedAwaitingValue != iAwaitingSorting && iAwaitingSorting != iSortingComplete && iWaitCount < 500)
					Utility.Wait(0.01) ; Need to ensure iAwaitingSorting decrements
					iWaitCount += 1
				endWhile
				
				if(iAwaitingSorting > iExpectedAwaitingValue)
					iAwaitingSorting = iExpectedAwaitingValue
				endif
			endif
		else
			if(iAwaitingSorting > iExpectedAwaitingValue)
				iAwaitingSorting = iExpectedAwaitingValue
			endif
		endif
		
		i += 1
	endWhile	
	
	Utility.Wait(1.0) ; Give it a moment to handle the last OnItemAdded event
	
	iBarterSelectCallbackID = Utility.RandomInt(1, 999999)
	kCurrentPhantomVendor.ShowBarterMenu()
	
	return iBarterSelectCallbackID
EndFunction



Int Function ShowRefCollectionBarterSelectMenuAndWait(Form afBarterDisplayNameForm, RefCollectionAlias aAvailableOptionsCollection, Formlist aStoreResultsIn, Keyword[] aFilterKeywords = None, Int aiAcceptStolen = 2, Formlist aStartBarterSelectedFormlist = None, Bool abVendorSideEqualsChoice = false, Float afMaxWaitTime = 60.0, Float afMaxWaitForBarterSelect = 0.0)
	ModTraceCustom(sUILog, "ShowRefCollectionBarterSelectMenuAndWait called.")
	if(bPhantomVendorInUse)
		if(afMaxWaitForBarterSelect != 0.0)
			Float fWaitedTime = 0.0
			if(afMaxWaitForBarterSelect < 0)
				afMaxWaitForBarterSelect = 99999999
			endif
			
			while(bPhantomVendorInUse && fWaitedTime < afMaxWaitForBarterSelect)
				Utility.WaitMenuMode(fWaitForMenuAvailableLoopIncrement)
				fWaitedTime += fWaitForMenuAvailableLoopIncrement
			endWhile
		else
			return -1
		endif
	endif   ; REMINDER - do not set this to true after this, as the menu function will do so
	
	Int iResult = ShowRefCollectionBarterSelectMenu(afBarterDisplayNameForm, aAvailableOptionsCollection, aStoreResultsIn, aFilterKeywords, aiAcceptStolen, aStartBarterSelectedFormlist, abVendorSideEqualsChoice, afMaxWaitForBarterSelect)
	
	if(iResult > -1)
		; Callback ID received, let's begin our waiting loop
		Float fWaitedTime = 0.0
		while(bPhantomVendorInUse && fWaitedTime < afMaxWaitTime)
			Utility.WaitMenuMode(fBarterWaitLoopIncrement)
			fWaitedTime += fBarterWaitLoopIncrement
		endWhile
	endif
	
	return iResult
EndFunction


; ------------------------------------
; ShowFormlistBarterSelectMenuAndWait
;
; This is a simpler version of the ShowFormlistBarterSelectMenu function that doesn't require monitoring for an event to know when to get the results. 
;
; Non-wait version above is still preferred if you're using it with something that shouldn't be blocked for long periods of time, as it doesn't hold your calling script the entire time that the player is selecting plus the time for processing the selection afterwards.
; ------------------------------------

Int Function ShowFormlistBarterSelectMenuAndWait(Form afBarterDisplayNameForm, Formlist aAvailableOptionsFormlist, Formlist aStoreResultsIn, Keyword[] aFilterKeywords = None, Int aiAcceptStolen = 2, Formlist aStartBarterSelectedFormlist = None, Bool abVendorSideEqualsChoice = false, Bool abUsingReferences = false, Float afMaxWaitTime = 60.0)
	return ShowFormlistBarterSelectMenuAndWaitV5(afBarterDisplayNameForm, aAvailableOptionsFormlist, aStoreResultsIn, aFilterKeywords, aiAcceptStolen, aStartBarterSelectedFormlist, abVendorSideEqualsChoice, abAvailableOptionItemsAreReferences = abUsingReferences, abStartBarterSelectedFormlistAreReferences = abUsingReferences, abStoreResultsAsReferences = abUsingReferences, afMaxWaitTime = afMaxWaitTime)
EndFunction

Int Function ShowFormlistBarterSelectMenuAndWaitV2(Form afBarterDisplayNameForm, Formlist aAvailableOptionsFormlist, Formlist aStoreResultsIn, Keyword[] aFilterKeywords = None, Int aiAcceptStolen = 2, Formlist aStartBarterSelectedFormlist = None, Bool abVendorSideEqualsChoice = false, Bool abUsingReferences = false, Float afMaxWaitTime = 60.0, Float afMaxWaitForBarterSelect = 0.0)
	return ShowFormlistBarterSelectMenuAndWaitV5(afBarterDisplayNameForm, aAvailableOptionsFormlist, aStoreResultsIn, aFilterKeywords, aiAcceptStolen, aStartBarterSelectedFormlist, abVendorSideEqualsChoice, abAvailableOptionItemsAreReferences = abUsingReferences, abStartBarterSelectedFormlistAreReferences = abUsingReferences, abStoreResultsAsReferences = abUsingReferences, afMaxWaitTime = afMaxWaitTime, afMaxWaitForBarterSelect = afMaxWaitForBarterSelect)
EndFunction

Int Function ShowFormlistBarterSelectMenuAndWaitV3(Form afBarterDisplayNameForm, Formlist aAvailableOptionsFormlist, Formlist aStoreResultsIn, Keyword[] aFilterKeywords = None, Int aiAcceptStolen = 2, Formlist aStartBarterSelectedFormlist = None, Bool abVendorSideEqualsChoice = false, Bool abAvailableOptionItemsAreReferences = false, Bool abStartBarterSelectedFormlistAreReferences = false, Bool abStoreResultsAsReferences = false, Float afMaxWaitTime = 60.0, Float afMaxWaitForBarterSelect = 0.0)
	return ShowFormlistBarterSelectMenuAndWaitV5(afBarterDisplayNameForm, aAvailableOptionsFormlist, aStoreResultsIn, aFilterKeywords, aiAcceptStolen, aStartBarterSelectedFormlist, abVendorSideEqualsChoice, abAvailableOptionItemsAreReferences, abStartBarterSelectedFormlistAreReferences, abStoreResultsAsReferences, abDestroyNonCachedBarterSelectReferences = false, afMaxWaitTime = afMaxWaitTime, afMaxWaitForBarterSelect = afMaxWaitForBarterSelect)
EndFunction

Int Function ShowFormlistBarterSelectMenuAndWaitV5(Form afBarterDisplayNameForm, Formlist aAvailableOptionsFormlist, Formlist aStoreResultsIn, Keyword[] aFilterKeywords = None, Int aiAcceptStolen = 2, Formlist aStartBarterSelectedFormlist = None, Bool abVendorSideEqualsChoice = false, Bool abAvailableOptionItemsAreReferences = false, Bool abStartBarterSelectedFormlistAreReferences = false, Bool abStoreResultsAsReferences = false, Bool abDestroyNonCachedBarterSelectReferences = false, Float afMaxWaitTime = 60.0, Float afMaxWaitForBarterSelect = 0.0)
	if(bPhantomVendorInUse) 
		if(afMaxWaitForBarterSelect != 0.0)
			Float fWaitedTime = 0.0
			if(afMaxWaitForBarterSelect < 0)
				afMaxWaitForBarterSelect = 99999999
			endif
			
			while(bPhantomVendorInUse && fWaitedTime < afMaxWaitForBarterSelect)
				Utility.WaitMenuMode(fWaitForMenuAvailableLoopIncrement)
				fWaitedTime += fWaitForMenuAvailableLoopIncrement
			endWhile
		else
			return -1
		endif
	endif   ; REMINDER - do not set this to true after this, as the menu function will do so
	
	Int iResult = ShowFormlistBarterSelectMenuV5(afBarterDisplayNameForm, aAvailableOptionsFormlist, aStoreResultsIn, aFilterKeywords, aiAcceptStolen, aStartBarterSelectedFormlist, abVendorSideEqualsChoice, abAvailableOptionItemsAreReferences, abStartBarterSelectedFormlistAreReferences, abStoreResultsAsReferences, abDestroyNonCachedBarterSelectReferences, afMaxWaitForBarterSelect)
	
	;Debug.MessageBox("ShowFormlistBarterSelectMenuAndWaitV5 received call back ID " + iResult + " waiting for phantom vendor selection to complete for up to " + afMaxWaitTime + " seconds.")
	
	if(iResult > -1)
		; Callback ID received, let's begin our waiting loop
		Float fWaitedTime = 0.0
		while(bPhantomVendorInUse && fWaitedTime < afMaxWaitTime)
			Utility.WaitMenuMode(fBarterWaitLoopIncrement)
			fWaitedTime += fBarterWaitLoopIncrement
		endWhile
	endif
	
	return iResult
EndFunction



int Function ShowBarterSelectMenu(Form afBarterDisplayNameForm, Form[] aAvailableOptions, Formlist aStoreResultsIn, Keyword[] aFilterKeywords = None, Int aiAcceptStolen = 2)
	return ShowBarterSelectMenuV5(afBarterDisplayNameForm, aAvailableOptions, aStoreResultsIn, aFilterKeywords, aiAcceptStolen)
EndFunction

int Function ShowBarterSelectMenuV2(Form afBarterDisplayNameForm, Form[] aAvailableOptions, Formlist aStoreResultsIn, Keyword[] aFilterKeywords = None, Int aiAcceptStolen = 2, Formlist aStartBarterSelectedFormlist = None, Bool abVendorSideEqualsChoice = false, Bool abUsingReferences = false)	
	return ShowBarterSelectMenuV5(afBarterDisplayNameForm, aAvailableOptions, aStoreResultsIn, aFilterKeywords, aiAcceptStolen, aStartBarterSelectedFormlist, abVendorSideEqualsChoice, abAvailableOptionItemsAreReferences = abUsingReferences, abStartBarterSelectedFormlistAreReferences = abUsingReferences, abStoreResultsAsReferences = abUsingReferences)
EndFunction

int Function ShowBarterSelectMenuV3(Form afBarterDisplayNameForm, Form[] aAvailableOptions, Formlist aStoreResultsIn, Keyword[] aFilterKeywords = None, Int aiAcceptStolen = 2, Formlist aStartBarterSelectedFormlist = None, Bool abVendorSideEqualsChoice = false, Bool abUsingReferences = false, Float afMaxWaitForBarterSelect = 0.0)
	return ShowBarterSelectMenuV5(afBarterDisplayNameForm, aAvailableOptions, aStoreResultsIn, aFilterKeywords, aiAcceptStolen, aStartBarterSelectedFormlist, abVendorSideEqualsChoice, abAvailableOptionItemsAreReferences = abUsingReferences, abStartBarterSelectedFormlistAreReferences = abUsingReferences, abStoreResultsAsReferences = abUsingReferences, abDestroyNonCachedBarterSelectReferences = false, afMaxWaitForBarterSelect = afMaxWaitForBarterSelect)
EndFunction

int Function ShowBarterSelectMenuV4(Form afBarterDisplayNameForm, Form[] aAvailableOptions, Formlist aStoreResultsIn, Keyword[] aFilterKeywords = None, Int aiAcceptStolen = 2, Formlist aStartBarterSelectedFormlist = None, Bool abVendorSideEqualsChoice = false, Bool abAvailableOptionItemsAreReferences = false, Bool abStartBarterSelectedFormlistAreReferences = false, Bool abStoreResultsAsReferences = false, Float afMaxWaitForBarterSelect = 0.0)
	return ShowBarterSelectMenuV5(afBarterDisplayNameForm, aAvailableOptions, aStoreResultsIn, aFilterKeywords, aiAcceptStolen, aStartBarterSelectedFormlist, abVendorSideEqualsChoice, abAvailableOptionItemsAreReferences, abStartBarterSelectedFormlistAreReferences, abStoreResultsAsReferences, abDestroyNonCachedBarterSelectReferences = false, afMaxWaitForBarterSelect = afMaxWaitForBarterSelect)
EndFunction


int Function ShowBarterSelectMenuV5(Form afBarterDisplayNameForm, Form[] aAvailableOptions, Formlist aStoreResultsIn, Keyword[] aFilterKeywords = None, Int aiAcceptStolen = 2, Formlist aStartBarterSelectedFormlist = None, Bool abVendorSideEqualsChoice = false, Bool abAvailableOptionItemsAreReferences = false, Bool abStartBarterSelectedFormlistAreReferences = false, Bool abStoreResultsAsReferences = false, Bool abDestroyNonCachedBarterSelectReferences = false, Float afMaxWaitForBarterSelect = 0.0)
	ModTraceCustom(sUILog, "ShowBarterSelectMenuV5 called.")
	if(bPhantomVendorInUse)
		if(afMaxWaitForBarterSelect != 0.0)
			Float fWaitedTime = 0.0
			if(afMaxWaitForBarterSelect < 0)
				afMaxWaitForBarterSelect = 99999999
			endif
			
			while(bPhantomVendorInUse && fWaitedTime < afMaxWaitForBarterSelect)
				Utility.WaitMenuMode(fWaitForMenuAvailableLoopIncrement)
				fWaitedTime += fWaitForMenuAvailableLoopIncrement
			endWhile
		else
			return -1
		endif
	endif
	
	bPhantomVendorInUse = true
	
	ResetPhantomVendors()
	PreparePhantomVendor(afBarterDisplayNameForm, aFilterKeywords, aiAcceptStolen)
	
	SelectedResultsFormlist = aStoreResultsIn
	StartBarterSelectedFormList = aStartBarterSelectedFormlist
	bVendorSideEqualsChoice = abVendorSideEqualsChoice
	bAvailableOptionItemsAreReferences = abAvailableOptionItemsAreReferences	
	bStartBarterSelectedFormlistAreReferences = abStartBarterSelectedFormlistAreReferences
	bStoreResultsAsReferences = abStoreResultsAsReferences
	bDestroyNonCachedBarterSelectReferences = abDestroyNonCachedBarterSelectReferences
	
	if(kCurrentPhantomVendorContainer == None)
		bPhantomVendorInUse = false
		Debug.MessageBox("Workshop Framework Error\n\nUnable to start barter menu system.")
		return -1
	endif
	
	; Register for event so items get sorted
	RegisterForRemoteEvent(kCurrentPhantomVendorContainer, "OnItemAdded")
	
	; Add items to vendor container and start barter
	ObjectReference kSafeSpawnPoint = SafeSpawnPoint.GetRef()
	Int iCount = aAvailableOptions.Length
	iAwaitingSorting = iCount
	int iExpectedAwaitingValue = iAwaitingSorting
	
	int i = 0
	while(i < iCount)
		iExpectedAwaitingValue -= 1
		Form FormToAdd = aAvailableOptions[i]
		
		if(FormToAdd != None)
			Utility.Wait(0.01) ; Need to ensure iAwaitingSorting decrements so we force latent wait call
			
			if(abAvailableOptionItemsAreReferences)
				kCurrentPhantomVendorContainer.AddItem(FormToAdd)
			else
				; Spawning refs, as just adding items does not seem to work well with our dynamic filtering
				ObjectReference kSpawnedRef = kSafeSpawnPoint.PlaceAtMe(FormToAdd)
				if(kSpawnedRef)			
					kCurrentPhantomVendorContainer.AddItem(kSpawnedRef)
				endif
			endif
			
			int iWaitCount = 0
			while(iExpectedAwaitingValue != iAwaitingSorting && iAwaitingSorting != iSortingComplete && iWaitCount < 500)
				Utility.Wait(0.01) ; Need to ensure iAwaitingSorting decrements
				iWaitCount += 1
			endWhile
			
			if(iAwaitingSorting > iExpectedAwaitingValue)
				iAwaitingSorting = iExpectedAwaitingValue
			endif
		else
			if(iAwaitingSorting > iExpectedAwaitingValue)
				iAwaitingSorting = iExpectedAwaitingValue
			endif
		endif
		
		i += 1
	endWhile
	
	Utility.Wait(1.0) ; Give it a moment to handle the last OnItemAdded event
	iBarterSelectCallbackID = Utility.RandomInt(1, 999999)
	kCurrentPhantomVendor.ShowBarterMenu()
	
	return iBarterSelectCallbackID
EndFunction

; ------------------------------------
; ShowBarterSelectMenuAndWait
;
; This is a simpler version of the ShowBarterSelectMenu function that doesn't require monitoring for an event to know when to get the results. 
;
; Non-wait version above is still preferred if you're using it with something that shouldn't be blocked for long periods of time, as it doesn't hold your calling script the entire time that the player is selecting plus the time for processing the selection afterwards.
; ------------------------------------
Int Function ShowBarterSelectMenuAndWait(Form afBarterDisplayNameForm, Form[] aAvailableOptions, Formlist aStoreResultsIn, Keyword[] aFilterKeywords = None, Int aiAcceptStolen = 2, Formlist aStartBarterSelectedFormlist = None, Bool abVendorSideEqualsChoice = false, Bool abUsingReferences = false, Float afMaxWaitTime = 60.0)
	return ShowBarterSelectMenuAndWaitV4(afBarterDisplayNameForm, aAvailableOptions, aStoreResultsIn, aFilterKeywords, aiAcceptStolen, aStartBarterSelectedFormlist, abVendorSideEqualsChoice, abAvailableOptionItemsAreReferences = abUsingReferences, abStartBarterSelectedFormlistAreReferences = abUsingReferences, abStoreResultsAsReferences = abUsingReferences, afMaxWaitTime = afMaxWaitTime)
EndFunction

Int Function ShowBarterSelectMenuAndWaitV2(Form afBarterDisplayNameForm, Form[] aAvailableOptions, Formlist aStoreResultsIn, Keyword[] aFilterKeywords = None, Int aiAcceptStolen = 2, Formlist aStartBarterSelectedFormlist = None, Bool abVendorSideEqualsChoice = false, Bool abUsingReferences = false, Float afMaxWaitTime = 60.0, Float afMaxWaitForBarterSelect = 0.0)
	return ShowBarterSelectMenuAndWaitV4(afBarterDisplayNameForm, aAvailableOptions, aStoreResultsIn, aFilterKeywords, aiAcceptStolen, aStartBarterSelectedFormlist, abVendorSideEqualsChoice, abAvailableOptionItemsAreReferences = abUsingReferences, abStartBarterSelectedFormlistAreReferences = abUsingReferences, abStoreResultsAsReferences = abUsingReferences, afMaxWaitTime = afMaxWaitTime, afMaxWaitForBarterSelect = afMaxWaitForBarterSelect)
EndFunction

Int Function ShowBarterSelectMenuAndWaitV3(Form afBarterDisplayNameForm, Form[] aAvailableOptions, Formlist aStoreResultsIn, Keyword[] aFilterKeywords = None, Int aiAcceptStolen = 2, Formlist aStartBarterSelectedFormlist = None, Bool abVendorSideEqualsChoice = false, Bool abAvailableOptionItemsAreReferences = false, Bool abStartBarterSelectedFormlistAreReferences = false, Bool abStoreResultsAsReferences = false, Float afMaxWaitTime = 60.0, Float afMaxWaitForBarterSelect = 0.0)
	return ShowBarterSelectMenuAndWaitV4(afBarterDisplayNameForm, aAvailableOptions, aStoreResultsIn, aFilterKeywords, aiAcceptStolen, aStartBarterSelectedFormlist, abVendorSideEqualsChoice, abAvailableOptionItemsAreReferences, abStartBarterSelectedFormlistAreReferences, abStoreResultsAsReferences, abDestroyNonCachedBarterSelectReferences = false, afMaxWaitTime = afMaxWaitTime, afMaxWaitForBarterSelect = afMaxWaitForBarterSelect)
EndFunction

Int Function ShowBarterSelectMenuAndWaitV4(Form afBarterDisplayNameForm, Form[] aAvailableOptions, Formlist aStoreResultsIn, Keyword[] aFilterKeywords = None, Int aiAcceptStolen = 2, Formlist aStartBarterSelectedFormlist = None, Bool abVendorSideEqualsChoice = false, Bool abAvailableOptionItemsAreReferences = false, Bool abStartBarterSelectedFormlistAreReferences = false, Bool abStoreResultsAsReferences = false, Bool abDestroyNonCachedBarterSelectReferences = false, Float afMaxWaitTime = 60.0, Float afMaxWaitForBarterSelect = 0.0)
	ModTraceCustom(sUILog, "ShowBarterSelectMenuAndWaitV4 called.")
	if(bPhantomVendorInUse)
		if(afMaxWaitForBarterSelect != 0.0)
			Float fWaitedTime = 0.0
			if(afMaxWaitForBarterSelect < 0)
				afMaxWaitForBarterSelect = 99999999
			endif
			
			while(bPhantomVendorInUse && fWaitedTime < afMaxWaitForBarterSelect)
				Utility.WaitMenuMode(fWaitForMenuAvailableLoopIncrement)
				fWaitedTime += fWaitForMenuAvailableLoopIncrement
			endWhile
		else
			return -1
		endif
	endif   ; REMINDER - do not set this to true after this, as the menu function will do so
	
	Int iResult = ShowBarterSelectMenuV5(afBarterDisplayNameForm, aAvailableOptions, aStoreResultsIn, aFilterKeywords, aiAcceptStolen, aStartBarterSelectedFormlist, abVendorSideEqualsChoice, abAvailableOptionItemsAreReferences, abStartBarterSelectedFormlistAreReferences, abStoreResultsAsReferences, abDestroyNonCachedBarterSelectReferences = abDestroyNonCachedBarterSelectReferences, afMaxWaitForBarterSelect = afMaxWaitForBarterSelect)
	
	if(iResult > -1)
		; Callback ID received, let's begin our waiting loop
		Float fWaitedTime = 0.0
		while(bPhantomVendorInUse && fWaitedTime < afMaxWaitTime)
			Utility.WaitMenuMode(fBarterWaitLoopIncrement)
			fWaitedTime += fBarterWaitLoopIncrement
		endWhile
	endif
	
	return iResult
EndFunction
 

Function ProcessBarterSelection()
	;Debug.MessageBox("ProcessBarterSelection called, dumping selection pool")
	ModTraceCustom(sUILog, "ProcessBarterSelection on SelectionPool01: " + SelectionPool01)
	ProcessItemPool(SelectionPool01)
	ModTraceCustom(sUILog, "ProcessBarterSelection on SelectionPool02: " + SelectionPool02)
	ProcessItemPool(SelectionPool02)
	ModTraceCustom(sUILog, "ProcessBarterSelection on SelectionPool03: " + SelectionPool03)
	ProcessItemPool(SelectionPool03)
	ModTraceCustom(sUILog, "ProcessBarterSelection on SelectionPool04: " + SelectionPool04)
	ProcessItemPool(SelectionPool04)
	ModTraceCustom(sUILog, "ProcessBarterSelection on SelectionPool05: " + SelectionPool05)
	ProcessItemPool(SelectionPool05)
	ModTraceCustom(sUILog, "ProcessBarterSelection on SelectionPool06: " + SelectionPool06)
	ProcessItemPool(SelectionPool06)
	ModTraceCustom(sUILog, "ProcessBarterSelection on SelectionPool07: " + SelectionPool07)
	ProcessItemPool(SelectionPool07)
	ModTraceCustom(sUILog, "ProcessBarterSelection on SelectionPool08: " + SelectionPool08)
	ProcessItemPool(SelectionPool08)
	
	; Return any remaining items to player as they were not part of our pool, player likely dropped them in to see what would happen
	
	ModTraceCustom(sUILog, " Moving remaining " + kCurrentPhantomVendorContainer.GetItemCount() + " items from phantom vendor container to player.")
	
	kCurrentPhantomVendorContainer.RemoveAllItems(PlayerRef, abKeepOwnership = true)
	
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
	ResetPhantomVendors()
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
									ModTraceCustom(sUILog, " Ran out of space to sort items.")
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
		;ModTrace("SortToPool " + aItemType + " already in pool!")
        return true
    elseif(aItemPool.Length < 128)
		;ModTrace("SortToPool " + aItemType + " adding to pool...")
        aItemPool.Add(aItemType)
        return true
	else 
		;ModTrace("SortToPool " + aItemType + " pool already has 128 entries.")
    endif
    
    return false
EndFunction


Function ProcessItemPool(Form[] aItemPool)
	ModTraceCustom(sUILog, "ProcessItemPool called. ItemPool size = " + aItemPool.Length + ", bVendorSideEqualsChoice = " + bVendorSideEqualsChoice)
	ObjectReference kSafeSpawnPoint = SafeSpawnPoint.GetRef()
    While(aItemPool.Length > 0)
        Form thisForm = aItemPool[0]
        
		Bool bSelected = false
		Bool bItemRemoved = false
		if(bVendorSideEqualsChoice)
			if(bAvailableOptionItemsAreReferences && (thisForm as ObjectReference) != None)
				bSelected = ((thisForm as ObjectReference).GetContainer() == kCurrentPhantomVendorContainer)
			else
				bSelected = (kCurrentPhantomVendorContainer.GetItemCount(thisForm) > 0)
			endif
			
			; ModTrace("[ProcessItemPool] Checking for " + thisForm + " in " + kCurrentPhantomVendorContainer + " which currently has " + kCurrentPhantomVendorContainer.GetItemCount() + " items, found? :" + bSelected + " also checking phantom vendor " + PhantomVendorAlias.GetRef() + ", found there? : " + PhantomVendorAlias.GetRef().GetItemCount(thisForm))
		else
			int iPlayerItemCount = 0
			if(bAvailableOptionItemsAreReferences && (thisForm as ObjectReference) != None)
				bSelected = ((thisForm as ObjectReference).GetContainer() == PlayerRef)
				if(bSelected)
					iPlayerItemCount = 1
				endif
			else
				iPlayerItemCount = PlayerRef.GetItemCount(thisForm)
				bSelected = (iPlayerItemCount > 0)
			endif
			
			ModTraceCustom(sUILog, "[ProcessItemPool] Checking for " + thisForm + " in " + PlayerRef + ", found :" + iPlayerItemCount)
		endif
		
		if(bSelected)
			ModTraceCustom(sUILog, "ProcessItemPool form was selected: " + thisForm)
		
			iTotalSelected += 1
			
			int iSettlementIndex = -1
			if(thisForm as ObjectReference != None)
				iSettlementIndex = Selectables_Settlements.Find((thisForm as ObjectReference).GetBaseObject())
			else
				iSettlementIndex = Selectables_Settlements.Find(thisForm)
			endif
			
			if(iSettlementIndex >= 0)
				ModTraceCustom(sUILog, "    Selected form is part of Selectables_Settlements system.")
				if( ! kLastSelectedSettlements)
					kLastSelectedSettlements = new WorkshopScript[0]
				endif
				
				Location settlementLocation = StoreNames_Settlements[iSettlementIndex].GetLocation()
				
				if(settlementLocation != None)										
					kLastSelectedSettlements.Add(WorkshopParent.GetWorkshopFromLocation(settlementLocation))
				endif
			else
				ModTraceCustom(sUILog, "    Selected form is not part of Selectables_Settlements system.")
				if(bAvailableOptionItemsAreReferences && thisForm as ObjectReference)
					ModTraceCustom(sUILog, "    Selected form is a reference, handling accordingly.")
					
					; Since using references, we need to put these items somewhere or they will be destroyed when removed from inventory
					ObjectReference kDroppedRef = (thisForm as ObjectReference)
					kDroppedRef.Drop(true)
					
					if(kDroppedRef == None)
						ModTraceCustom(sUILog, "    Selected form failed to resolve to a reference after drop.")
					else
						ModTraceCustom(sUILog, "    Form dropped from select container, moving to safe spawn point " + kSafeSpawnPoint)
						kDroppedRef.MoveTo(kSafeSpawnPoint)
						
						if(bStoreResultsAsReferences)
							SelectedResultsFormlist.AddForm(kDroppedRef)
						else
							SelectedResultsFormlist.AddForm(kDroppedRef.GetBaseObject())
						endif
						
						if(kCurrentCacheRef != None)
							kCurrentCacheRef.AddItem(kDroppedRef)
						endif
						
						bItemRemoved = true
					endif
				else
					ModTraceCustom(sUILog, "    Selected form is not a reference, adding form to SelectedResultsFormlist " + SelectedResultsFormlist)
					SelectedResultsFormlist.AddForm(thisForm)	
				endif
			endif
			
			if( ! bItemRemoved)
				; return to cache				
				if(bVendorSideEqualsChoice)
					kCurrentPhantomVendorContainer.RemoveItem(thisForm, 1, abSilent = true, akOtherContainer = kCurrentCacheRef)
				else	
					PlayerRef.RemoveItem(thisForm, 1, abSilent = true, akOtherContainer = kCurrentCacheRef)
				endif
			endif
		else
			;ModTraceCustom(sUILog, " Removing item " + thisForm + " from phantom vendor container " + kCurrentPhantomVendorContainer + ", which currently has " + kCurrentPhantomVendorContainer.GetItemCount(thisForm) + ", sending to kCurrentCacheRef " + kCurrentCacheRef)
			
			; Item was left in select container, don't count as selected, but return to cache, destroy, or drop
			
			if(kCurrentCacheRef != None || ! bAvailableOptionItemsAreReferences || bDestroyNonCachedBarterSelectReferences)
				; If bAvailableOptionItemsAreReferences == true and not using a cache, moving the items to a None container would be destroying them, so only do so if explicitly requested. Otherwise, we'll just let them get returned to the player by ProcessBarterSelection
				if(bVendorSideEqualsChoice)
					PlayerRef.RemoveItem(thisForm, 1, abSilent = true, akOtherContainer = kCurrentCacheRef)
				else
					; ModTraceCustom(sUILog, " Removing item " + thisForm + " from phantom vendor container " + kCurrentPhantomVendorContainer + ", which currently has " + kCurrentPhantomVendorContainer.GetItemCount(thisForm) + ", sending to kCurrentCacheRef " + kCurrentCacheRef)
					kCurrentPhantomVendorContainer.RemoveItem(thisForm, 1, abSilent = true, akOtherContainer = kCurrentCacheRef)
				endif
			elseif(bAvailableOptionItemsAreReferences && ! bDestroyNonCachedBarterSelectReferences)
				; Added 2.3.2
				; If these were items the player accidentally deposited, they wouldn't be refs, since the caller doesn't want these destroyed, let's just drop them and they will be persisted by whatever system needs them and that way won't be confusingly returned to the player
				if(thisForm as ObjectReference)
					(thisForm as ObjectReference).Drop(true)
				else
					if(bVendorSideEqualsChoice)
						PlayerRef.DropObject(thisForm, 1)
					else
						kCurrentPhantomVendorContainer.DropObject(thisForm, 1)
					endif
				endif
			endif
        endif
        
		ModTraceCustom(sUILog, " Calling Remove(0) on pool we are processing, expecting to remove " + aItemPool[0])
        aItemPool.Remove(0)
		ModTraceCustom(sUILog, "     After remove call entry 0 of pool = " + aItemPool[0])
    EndWhile
EndFunction


Function ResetPhantomVendors()
	ModTraceCustom(sUILog, " ResetPhantomVendors called.")
	; Reset previous select data
	int i = 0
	while(i < PhantomVendorAliases.Length)
		Actor kPhantomVendorRef = PhantomVendorAliases[i].GetActorRef()
		ObjectReference kPhantomVendorContainerRef = PhantomVendorContainerAliases[i].GetRef()
		kPhantomVendorContainerRef.RemoveAllItems() ; Get rid of copies from previous
	
		kPhantomVendorContainerRef.SetActorRefOwner(PlayerRef) ; Prevent player from getting in trouble for stealing
		
		; Remove items from the vendor's pockets - they shouldn't have anything, but just in case
		kPhantomVendorRef.RemoveAllItems()
	
		i += 1
	endWhile
	
	
	; Clear out the filter list
	i = 0
	while(i < PhantomVendorBuySellLists.Length)
		PhantomVendorBuySellLists[i].Revert()
		
		i += 1
	endWhile
	
	bVendorSideEqualsChoice = false
	SelectedResultsFormlist = None
	StartBarterSelectedFormList = None
	
	bAvailableOptionItemsAreReferences = false
	bStartBarterSelectedFormlistAreReferences = false
	bStoreResultsAsReferences = false
	bDestroyNonCachedBarterSelectReferences = false
	
	kCurrentPhantomVendor = None
	kCurrentPhantomVendorContainer = None
	kCurrentBuySellList = None
	
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
	Bool bFiltered = (aFilterKeywords != None && aFilterKeywords.Length > 0)
	
	kCurrentPhantomVendor = GetPhantomVendor(aiAcceptStolen, bFiltered)
	kCurrentPhantomVendorContainer = GetPhantomVendorContainer(aiAcceptStolen, bFiltered)
	
	; Clear out the filter list
	if(bFiltered)
		kCurrentBuySellList = PhantomVendorBuySellLists[aiAcceptStolen]
		kCurrentBuySellList.Revert()
	else
		kCurrentBuySellList = None
	endif
	
	; Remove items from the vendor's pockets - they shouldn't have anything, but just in case
	kCurrentPhantomVendor.RemoveAllItems()
	kCurrentPhantomVendorContainer.RemoveAllItems()
	
	; Setup phantom vendor for this selection	
	if(aFilterKeywords != None && aFilterKeywords.Length > 0)
		int i = 0
		while(i < aFilterKeywords.Length)
			kCurrentBuySellList.AddForm(aFilterKeywords[i])
			
			i += 1
		endWhile
	endif
	
	; 2.2.3 - We were filtering on the aFilterKeywords if there were any, but this would mean that if a group of items that didn't match the filter was sent, they would fail to be processed and cause the awaiting sorting system to get stuck. 
	AddInventoryEventFilter(None)	
	
	RegisterForMenuOpenCloseEvent("BarterMenu")
	
	Int iAliasIndex = aiAcceptStolen
	if(bFiltered)
		iAliasIndex += 3
	endif
	
	; Clear previous name by removing from alias
	PhantomVendorAliases[iAliasIndex].Clear()
	
	; Return to alias 
	PhantomVendorAliases[iAliasIndex].ForceRefTo(kCurrentPhantomVendor)
	
	; Stamp text replacement data the Message form expects
	kCurrentPhantomVendor.AddTextReplacementData("SelectionName", afBarterDisplayNameForm)
EndFunction


; 2.0.0 settlement select system
	; This will return a callback ID, monitor for event Settlement_SelectionMade
int Function ShowSettlementBarterSelectMenu(Form afBarterDisplayNameForm = None, WorkshopScript[] akExcludeSettlements = None)
	return ShowSettlementBarterSelectMenuV2(afBarterDisplayNameForm, akExcludeSettlements, None)
EndFunction
 
; 2.0.23 - Added akStartSelectedSettlements option
int Function ShowSettlementBarterSelectMenuV2(Form afBarterDisplayNameForm = None, WorkshopScript[] akExcludeSettlements = None, WorkshopScript[] akStartSelectedSettlements = None)
	if(afBarterDisplayNameForm == None)
		afBarterDisplayNameForm = VendorName_Settlements
	endif
	
	kLastSelectedSettlements = new WorkshopScript[0]
	SortingFormlist01.Revert()
	
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
			Location LocationRef = WorkshopLocations[i]
			if(LocationRef == None)
				LocationRef = Workshops[i].GetCurrentLocation()
			endif
			
			StoreNames_Settlements[i].ForceLocationTo(LocationRef)
			ObjectReference kSelectorRef = kSpawnPoint.PlaceAtMe(Selectables_Settlements[i])
			ApplyNames_Settlements[i].ForceRefTo(kSelectorRef)
			
			kCacheRef_Settlements.AddItem(kSelectorRef)
			
			if(akStartSelectedSettlements != None && akStartSelectedSettlements.Find(Workshops[i]) >= 0)
				SortingFormlist01.AddForm(Selectables_Settlements[i])
			endif
		endif
		
		i += 1
	endWhile
	
	Keyword[] FilterKeywords = new Keyword[1]
	FilterKeywords[0] = SelectableSettlementKeyword
	
	return ShowCachedBarterSelectMenuV4(afBarterDisplayNameForm, aAvailableOptionsCacheContainerReference = kCacheRef_Settlements, aStoreResultsIn = None, aFilterKeywords = FilterKeywords, aStartBarterSelectedFormlist = SortingFormlist01, abAvailableOptionItemsAreReferences = false, abStartBarterSelectedFormlistAreReferences = false, abStoreResultsAsReferences = false)
EndFunction


Function TestBarterSystem(int iTestNameChange = 0)
	Formlist scavList = Game.GetFormFromFile(0x00007B04, "WorkshopFramework.esm") as Formlist
	
	Form nameForm = Game.GetFormFromFile(0x0024A00F, "Fallout4.esm")
	
	if(iTestNameChange == 1)
		nameForm = Game.GetFormFromFile(0x00249AEB, "Fallout4.esm")
	endif
	
	Formlist holdList = Game.GetFormFromFile(0x0001CAE7, "WorkshopFramework.esm") as Formlist
	
	if(ShowFormlistBarterSelectMenuAndWait(nameForm, scavList, holdList))
		Debug.MessageBox("Wait completed. holdList has " + holdList.GetSize() + " entries.")
	endif
EndFunction

Function TestSettlementBarterSystem()
	ShowSettlementBarterSelectMenuV2(afBarterDisplayNameForm = None, akExcludeSettlements = None, akStartSelectedSettlements = None)
EndFunction

Function CheckBarterContainer(Int aiIndex)
	ObjectReference kVendorContainerRef = PhantomVendorContainerAliases[aiIndex].GetRef()
	if(kVendorContainerRef != None)
		Debug.MessageBox(kVendorContainerRef.GetItemCount())
	else
		Debug.MessageBox("Failed to fetch phantom vendor container ref")
	endif
EndFunction


	; ---------------------------------------------
	; Message Select System
	; 
	; Uses a message to display an infinitely long formlist or array of items, displaying them one at a time to the player with Next/Previous/Select/More Info/Cancel buttons. If the player chooses select, the index of the item in that formlist or array is returned
	;
	; Because the game has a stack limit of 100 calls deep, this will asyncronously start a new call if the stack gets too deep.
	;
	; Return Values: -1 = error, -2 = user canceled selection
	; ---------------------------------------------

Int Function ShowMessageSelectorMenuAndWait(Form[] aSelectFromOptions, Form aMessageTitleNameHolder = None, Message aNoOptionsWarningOverride = None)
	return ShowMessageSelectorMenuAndWaitV2(aSelectFromOptions, aMessageTitleNameHolder, aNoOptionsWarningOverride)
EndFunction

	
Int Function ShowMessageSelectorMenuAndWaitV2(Form[] aSelectFromOptions, Form aMessageTitleNameHolder = None, Message aNoOptionsWarningOverride = None, Float afMaxWaitForSelector = 0.0)
	if( ! aSelectFromOptions)
		return iMessageSelectorReturn_Failure
	endif
	
	int iCount = aSelectFromOptions.Length
	if(iCount == 0)
		if(aNoOptionsWarningOverride != None)
			aNoOptionsWarningOverride.Show()
		else
			MessageSelector_NoOptions.Show()
		endif
		
		return iMessageSelectorReturn_Failure
	EndIf
	
	if(bMessageSelectorInUse)
		if(afMaxWaitForSelector != 0.0)
			Float fWaitedTime = 0.0
			if(afMaxWaitForSelector < 0)
				afMaxWaitForSelector = 99999999
			endif
			
			while(bMessageSelectorInUse && fWaitedTime < afMaxWaitForSelector)
				Utility.WaitMenuMode(fWaitForMenuAvailableLoopIncrement)
				fWaitedTime += fWaitForMenuAvailableLoopIncrement
			endWhile
		else
			return iMessageSelectorReturn_Failure
		endif
	endif
	
	bMessageSelectorInUse = true
	iMessageSelector_SelectedOption = -1
	MessageSelectorFormArray = aSelectFromOptions
	
	; Setup text replacement for title
	Form TitleForm = NameHolderForm_SelectAnOption
	if(aMessageTitleNameHolder != None)
		TitleForm = aMessageTitleNameHolder
	endif
	
	ObjectReference kTitleRef
	
	if(TitleForm as ObjectReference)
		kTitleRef = TitleForm as ObjectReference
	else
		kTitleRef = SafeSpawnPoint.GetRef().PlaceAtMe(TitleForm)
	endif
	
	MessageSelectorTitleAlias.ForceRefTo(kTitleRef)
	
	; Start the selection loop
	ShowMessageSelectorMenuLoop_InternalOnly(aiIndexToDisplay = 0, aiSource = iMessageSelectorSource_Array)
	
	bMessageSelectorInUse = false
	MessageSelectorFormArray = new Form[0] ; Clear this array
	MessageSelectorFormlist = None
	
	return iMessageSelector_SelectedOption
EndFunction


Int Function ShowMessageSelectorMenuFormlistAndWait(Formlist aSelectFromOptionsList, Form aMessageTitleNameHolder = None, Message aNoOptionsWarningOverride = None)
	return ShowMessageSelectorMenuFormlistAndWaitV2(aSelectFromOptionsList, aMessageTitleNameHolder, aNoOptionsWarningOverride)
EndFunction


Int Function ShowMessageSelectorMenuFormlistAndWaitV2(Formlist aSelectFromOptionsList, Form aMessageTitleNameHolder = None, Message aNoOptionsWarningOverride = None, Float afMaxWaitForSelector = 0.0)
	return ShowMessageSelectorMenuFormlistAndWaitV3(aSelectFromOptionsList, aMessageTitleNameHolder, aNoOptionsWarningOverride, afMaxWaitForSelector, aiStartingIndex = 0)
EndFunction


Int Function ShowMessageSelectorMenuFormlistAndWaitV3(Formlist aSelectFromOptionsList, Form aMessageTitleNameHolder = None, Message aNoOptionsWarningOverride = None, Float afMaxWaitForSelector = 0.0, Int aiStartingIndex = 0)
	if( ! aSelectFromOptionsList)
		return iMessageSelectorReturn_Failure
	endif
	
	int iCount = aSelectFromOptionsList.GetSize()
	if(iCount == 0)
		if(aNoOptionsWarningOverride != None)
			aNoOptionsWarningOverride.Show()
		else
			MessageSelector_NoOptions.Show()
		endif
		
		return iMessageSelectorReturn_Failure
	EndIf
	
	
	if(bMessageSelectorInUse)
		if(afMaxWaitForSelector != 0.0)
			Float fWaitedTime = 0.0
			if(afMaxWaitForSelector < 0)
				afMaxWaitForSelector = 99999999
			endif
			
			while(bMessageSelectorInUse && fWaitedTime < afMaxWaitForSelector)
				Utility.WaitMenuMode(fWaitForMenuAvailableLoopIncrement)
				fWaitedTime += fWaitForMenuAvailableLoopIncrement
			endWhile
		else
			return iMessageSelectorReturn_Failure
		endif
	endif
	
	bMessageSelectorInUse = true
	
	MessageSelectorFormArray = new Form[0]
	iMessageSelector_SelectedOption = -1
	int iSource = iMessageSelectorSource_Formlist
	if(iCount <= 128) ; Convert to array which will be faster
		int i = 0
		while(i < iCount)
			MessageSelectorFormArray.Add(aSelectFromOptionsList.GetAt(i))
			
			i += 1
		endWhile
		
		iSource = iMessageSelectorSource_Array
	else
		MessageSelectorFormlist = aSelectFromOptionsList
	endif
	
	; Setup text replacement for title
	Form TitleForm = NameHolderForm_SelectAnOption
	if(aMessageTitleNameHolder != None)
		TitleForm = aMessageTitleNameHolder
	endif
	
	ObjectReference kTitleRef
	
	if(TitleForm as ObjectReference)
		kTitleRef = TitleForm as ObjectReference
	else
		kTitleRef = SafeSpawnPoint.GetRef().PlaceAtMe(TitleForm)
	endif
	
	MessageSelectorTitleAlias.ForceRefTo(kTitleRef)
	
	; Start the selection loop
	ShowMessageSelectorMenuLoop_InternalOnly(aiIndexToDisplay = aiStartingIndex, aiSource = iSource)
	
	bMessageSelectorInUse = false
	MessageSelectorFormArray = new Form[0] ; Clear this array
	MessageSelectorFormlist = None
	
	return iMessageSelector_SelectedOption
EndFunction

Function ShowMessageSelectorMenuLoop_InternalOnly(Int aiIndexToDisplay = 0, Int aiSource = 0)
	ObjectReference kSafeSpawnPoint = SafeSpawnPoint.GetRef()
	int iOptionCount = 0
	if(aiSource == iMessageSelectorSource_Array)
		iOptionCount = MessageSelectorFormArray.Length
	elseif(aiSource == iMessageSelectorSource_Formlist)
		iOptionCount = MessageSelectorFormlist.GetSize()			
	endif
	
	if(iOptionCount <= 0)
		return
	endif
	
	; Wait for player to select an option or cancel
	while(true)
		Form CurrentForm
		if(aiSource == iMessageSelectorSource_Array)
			CurrentForm = MessageSelectorFormArray[aiIndexToDisplay]
		elseif(aiSource == iMessageSelectorSource_Formlist)
			CurrentForm = MessageSelectorFormlist.GetAt(aiIndexToDisplay)			
		endif
		
		; Setup text replacement
		if(CurrentForm as Message)
			ObjectReference kNameRef = kSafeSpawnPoint.PlaceAtMe(RenamableDummyForm)
			kNameRef.AddTextReplacementData("RenameMe", CurrentForm)
			MessageSelectorItemLineAliases[0].ForceRefTo(kNameRef)
		else
			ObjectReference kNameRef = kSafeSpawnPoint.PlaceAtMe(CurrentForm)
			MessageSelectorItemLineAliases[0].ForceRefTo(kNameRef)
		endif
		
		; Should we show More Info option?
		MenuControl_MessageSelector_MoreInfo.SetValueInt(0)
		if(CurrentForm as WorkshopFramework:Forms:FormInformation && (CurrentForm as WorkshopFramework:Forms:FormInformation).InformationMessage != None)
			MenuControl_MessageSelector_MoreInfo.SetValueInt(1)
		endif
		
		; Display select menu
		int iSelectedOption = MessageSelector_Default.Show()
		
		; Handle selection
		if(iSelectedOption == 0) ; Next
			aiIndexToDisplay += 1
			
			if(aiIndexToDisplay >= iOptionCount)
				aiIndexToDisplay = 0
			endif
		elseif(iSelectedOption == 1) ; Previous
			aiIndexToDisplay -= 1
			
			if(aiIndexToDisplay < 0)
				aiIndexToDisplay = iOptionCount - 1
			endif
		elseif(iSelectedOption == 2) ; More Info
			(CurrentForm as WorkshopFramework:Forms:FormInformation).InformationMessage.Show()
		elseif(iSelectedOption == 3) ; Select
			iMessageSelector_SelectedOption = aiIndexToDisplay
			return
		else ; Cancel
			return
		endif
	endWhile
EndFunction


Actor Function GetPhantomVendor(Int aiAcceptStolen, Bool abFiltered)
	if(abFiltered)
		aiAcceptStolen += 3
	endif
	
	return PhantomVendorAliases[aiAcceptStolen].GetActorRef()
EndFunction


Actor Function GetPhantomVendorByContainer(ObjectReference akContainerRef)
	int i = 0
	while(i < PhantomVendorContainerAliases.Length)
		if(PhantomVendorContainerAliases[i].GetRef() == akContainerRef)
			return PhantomVendorAliases[i].GetActorRef()
		endif
		
		i += 1
	endWhile
	
	return None
EndFunction

ObjectReference Function GetPhantomVendorContainer(Int aiAcceptStolen, Bool abFiltered)
	if(abFiltered)
		aiAcceptStolen += 3
	endif
	
	return PhantomVendorContainerAliases[aiAcceptStolen].GetRef()
EndFunction


Function TestMessageSelectorSystem()
	Formlist scavList = Game.GetFormFromFile(0x00007B04, "WorkshopFramework.esm") as Formlist
	
	Form nameForm = Game.GetFormFromFile(0x00249AEB, "Fallout4.esm")
	
	int iSelection = ShowMessageSelectorMenuFormlistAndWait(scavList, aMessageTitleNameHolder = nameForm)
	
	Debug.MessageBox("Player selected option " + iSelection)
EndFunction
