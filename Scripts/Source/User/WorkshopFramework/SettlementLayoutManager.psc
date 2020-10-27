; ---------------------------------------------
; WorkshopFramework:SettlementLayoutManager.psc - by kinggath
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

Scriptname WorkshopFramework:SettlementLayoutManager extends WorkshopFramework:Library:SlaveQuest
{ Handles settlement layouts }

; TODO - For WSFW Scrap Settlement option on settlement menu, show progress bar
; TODO - Detect major scrap mods and disable Scrap Profile automatically to prevent issues

import WorkshopFramework:Library:DataStructures
import WorkshopFramework:Library:UtilityFunctions
import WorkshopFramework:WorkshopFunctions

CustomEvent SettlementLayoutAdded
CustomEvent SettlementLayoutBuilt
CustomEvent SettlementLayoutScrapped
CustomEvent ExportStarting

; ---------------------------------------------
; Consts
; ---------------------------------------------

String sExportLogBase = "WSFWExport_Settlement" Const
String sPlaceObjectCallbackID = "WSFW_PlaceObject" Const
String sExportCallbackID = "WSFW_ExportObjectData" Const
String sScrapObjectCallbackID = "WSFW_ScrapObject" Const
Int iGroupType_WorkshopResources = 1 Const
Int iGroupType_NonResources = 2 Const
Int iDummyCallbackCount = 10000 Const

String sProgressBarID_Export = "ExportProgress" Const
String sProgressBarID_Scrap = "ScrapProgress" Const
String sProgressBarID_Build = "BuildProgress" Const

; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------

Group Quests
	WorkshopFramework:PlaceObjectManager Property PlaceObjectManager Auto Const Mandatory
	WorkshopFramework:ScrapFinder[] Property ScrapFinders Auto Const Mandatory
	WorkshopFramework:MainThreadManager Property ThreadManager Auto Const Mandatory
	WorkshopFramework:F4SEManager Property F4SEManager Auto Const Mandatory
	WorkshopFramework:MainQuest Property WSFW_Main Auto Const Mandatory
	WorkshopFramework:HUDFrameworkManager Property HUDFrameworkManager Auto Const Mandatory
EndGroup

Group ActorValues
	ActorValue Property PopulationAV Auto Const Mandatory
EndGroup

Group Aliases
	ReferenceAlias Property SafeSpawnPoint Auto Const Mandatory
	LocationAlias Property NameHolder_Settlement Auto Const Mandatory
	ReferenceAlias Property NameHolder_Layout Auto Const Mandatory
	ReferenceAlias Property NameHolder_Designer Auto Const Mandatory
	ReferenceAlias Property DynamicText_WarningLabel Auto Const Mandatory
	ReferenceAlias Property DynamicText_WarningMessage Auto Const Mandatory
	ReferenceAlias Property StaticText_NA Auto Const Mandatory
	ReferenceAlias Property StaticText_Space Auto Const Mandatory
	ReferenceAlias Property StaticText_Warning Auto Const Mandatory
	ReferenceAlias Property StaticText_PluginsMissing Auto Const Mandatory
	ReferenceAlias[] Property NameHolder_MissingPlugins Auto Const Mandatory
EndGroup

Group Assets
	Form Property ScrapObjectThread Auto Const Mandatory
	Form Property RestoreObjectThread Auto Const Mandatory
	Form Property ExportObjectThread Auto Const Mandatory
	
	Formlist Property SettlementLayoutList Auto Const Mandatory
EndGroup

Group Globals
	GlobalVariable Property gMenuControl_LayoutInformation Auto Const Mandatory
	GlobalVariable Property gMenuControl_MissingPlugins Auto Const Mandatory
	GlobalVariable Property gMenuControl_RefreshLayout Auto Const Mandatory
	GlobalVariable Property gMenuControl_BuildLayout Auto Const Mandatory
	GlobalVariable Property gMenuControl_RemoveLayout Auto Const Mandatory
	
	GlobalVariable Property Setting_Export_IncludeAnimals Auto Const Mandatory
	GlobalVariable Property Setting_Export_IncludePowerArmor Auto Const Mandatory
	GlobalVariable Property Setting_Export_IncludeVanillaScrapInfo Auto Const Mandatory
	
	GlobalVariable Property Setting_Import_F4SEPowerItems Auto Const Mandatory
	GlobalVariable Property Setting_Import_FauxPowerItems Auto Const Mandatory
	GlobalVariable Property Setting_Import_HandleLootablesMethod Auto Const Mandatory
	GlobalVariable Property Setting_Import_SpawnNPCs Auto Const Mandatory
	GlobalVariable Property Setting_Import_SpawnPowerArmor Auto Const Mandatory
EndGroup

Group Keywords
	Keyword Property EventKeyword_ScrapFinder Auto Const Mandatory
	Keyword Property WorkshopItemKeyword Auto Const Mandatory
	Keyword Property PowerArmorKeyword Auto Const Mandatory
	Keyword Property PreventScrappingKeyword Auto Const Mandatory
	
	UniversalForm[] Property AlwaysAllowedActorTypes Auto Const Mandatory
	{ Keywords or forms that should be imported/exported even when options exclude most Actors - for things like turrets and armor stands }
EndGroup

Group Messages
	Message Property LayoutManagementMenu Auto Const Mandatory
	Message Property NoLayoutsForThisSettlement Auto Const Mandatory
	Message Property SettlementLayoutSelectMenu Auto Const Mandatory
	Message Property MissingPluginsMessage Auto Const Mandatory
	Message Property ExportConfirmation Auto Const Mandatory
	Message Property ScrapConfirmation Auto Const Mandatory
	Message Property RemoveConfirmation Auto Const Mandatory
	Message Property BuildConfirmation Auto Const Mandatory
	Message Property RefreshConfirmation Auto Const Mandatory
	Message Property RefreshAllConfirmation Auto Const Mandatory
	Message Property BuildingFinished Auto Const Mandatory
	Message Property ExportProgressUpdate Auto Const Mandatory
	Message Property ScrappingProgressUpdate Auto Const Mandatory
	Message Property BuildingProgressUpdate Auto Const Mandatory
	Message Property ScrappingFinished Auto Const Mandatory
EndGroup

; ---------------------------------------------
; Vars
; ---------------------------------------------
WorkshopScript[] AwaitingScrapping
WorkshopScript[] AwaitingPowerup

Bool[] SettlementScrapThreadingInProgress
Bool[] SettlementBuildThreadingInProgress

Bool[] LootablePickupComplete
Bool[] PowerUpPhaseComplete
Function UpdatePowerUpPhaseStatus(Int aiWorkshopID, Bool abComplete)
	if(PowerUpPhaseComplete == None)
		PowerUpPhaseComplete = new Bool[128]
	endif
	
	PowerUpPhaseComplete[aiWorkshopID] = abComplete
EndFunction

; Handle tracking of item building via threading
CallbackTracking[] LayoutBuildTracking

Bool bUseHUDProgressModule = false ; On startup, check for hud framework and set to true

Bool Property bManualScrapTriggered = false Auto Hidden
Bool Property bManualImportInProgress = false Auto Hidden
WorkshopScript Property kWorkshopAwaitingBuildFromRefresh Auto Hidden
Float Property fManuaBuildStartTime = 0.0 Auto Hidden

int iAwaitingScrapCallbacks = 0
int iScrapCallbacksReceived = 0

String sLastExportLogName
int iAwaitingExportCallbacks = 0
int iExportCallbacksReceived = 0
Float fExportStartTime = 0.0
Bool bExportInProgress = false
Bool bExportThreadingInProgress = false

int iProgressUpdateCounter_Build = 0
int iProgressUpdateCounter_Export = 0
int iProgressUpdateCounter_Scrap = 0

; ---------------------------------------------
; Events
; ---------------------------------------------

Event WorkshopFramework:Library:ThreadRunner.OnThreadCompleted(WorkshopFramework:Library:ThreadRunner akThreadRunner, Var[] akargs)
	;/
	akargs[0] = sCustomCallCallbackID
	akargs[1] = iCallbackID
	akargs[2] = Result from called function
	/;
	String sCallbackID = akargs[0] as String
	;Debug.Trace("Thread Callback Received: " + sCallbackID)
	
	if(sCallbackID == sScrapObjectCallbackID)
		iScrapCallbacksReceived += 1
		
		;Debug.Trace("Scrap Callback Received: " + iScrapCallbacksReceived + "/" + iAwaitingScrapCallbacks)
		if(bManualImportInProgress || bManualScrapTriggered)
			Float fProgress = Math.Floor((iScrapCallbacksReceived as Float/iAwaitingScrapCallbacks as Float) * 100) ; *100 to get as whole percentage
			
			if(bUseHUDProgressModule)
				HUDFrameworkManager.UpdateProgressBarPercentage(Self, sProgressBarID_Scrap, fProgress as Int)
			else
				; Update every 15%
				Float fTarget = 15.0 * (iProgressUpdateCounter_Scrap + 1)
				if(fProgress > 0 && fProgress >= fTarget)
					ScrappingProgressUpdate.Show(fProgress)
					iProgressUpdateCounter_Scrap += 1
				endif
			endif
		endif
		
		if(iScrapCallbacksReceived >= iAwaitingScrapCallbacks)
			ScrappingCompleted()
		endif
	elseif(sCallbackID == sPlaceObjectCallbackID)
		WorkshopFramework:ObjectRefs:Thread_PlaceObject kThreadRef = akargs[2] as WorkshopFramework:ObjectRefs:Thread_PlaceObject
		
		ObjectReference kCreatedRef = kThreadRef.kResult
		int iCallbackTrackingIndex = kThreadRef.iBatchID
		
		; We have the info we need from the thread, so trigger it's self destruction
		kThreadRef.bAutoDestroy = true
		if(kThreadRef.IsBoundGameObjectAvailable())
			kThreadRef.StartTimer(1.0)
		endif
		
		LayoutBuildTracking[iCallbackTrackingIndex].iCallbacksReceived += 1
		
		if(LayoutBuildTracking[iCallbackTrackingIndex].iCallbacksReceived >=  LayoutBuildTracking[iCallbackTrackingIndex].iAwaitingCallbacks)
			BuildingCompleted(iCallbackTrackingIndex)
		elseif(bManualImportInProgress)
			Float fProgress = Math.Floor((LayoutBuildTracking[iCallbackTrackingIndex].iCallbacksReceived as Float/LayoutBuildTracking[iCallbackTrackingIndex].iAwaitingCallbacks as Float) * 100) ; *100 to get as whole percentage
			
			if(bUseHUDProgressModule)
				HUDFrameworkManager.UpdateProgressBarPercentage(Self, sProgressBarID_Build, fProgress as Int)
			else
				; Update every 15%
				Float fTarget = 15.0 * (iProgressUpdateCounter_Build + 1)
				if(fProgress > 0 && fProgress >= fTarget)
					BuildingProgressUpdate.Show(fProgress)
					iProgressUpdateCounter_Build += 1
				endif
			endif
		endif				
	elseif(sCallbackID == sExportCallbackID)
		iExportCallbacksReceived += 1
		
		if(iExportCallbacksReceived >= iAwaitingExportCallbacks)
			ExportCompleted()
		else
			Float fProgress = Math.Floor((iExportCallbacksReceived as Float/iAwaitingExportCallbacks as Float) * 100) ; *100 to get as whole percentage
			if(bUseHUDProgressModule)
				HUDFrameworkManager.UpdateProgressBarPercentage(Self, sProgressBarID_Export, fProgress as Int)
			else
				; Update every 10% to avoid spamming notifications
				Float fTarget = 10.0 * (iProgressUpdateCounter_Export + 1)
				if(fProgress > 0 && fProgress >= fTarget)
					ExportProgressUpdate.Show(fProgress)
					iProgressUpdateCounter_Export += 1
				endif
			endif
		endif
	endif
	
	if(AllCallbacksReceived() && AllCallbacksSent())
		;Debug.MessageBox("AllCallbacksReceived and AllCallbacksSent - unregistering for callbackthreads.")
		ThreadManager.UnregisterForCallbackThreads(Self)
	endif
EndEvent


Event WorkshopFramework:MainQuest.PlayerEnteredSettlement(WorkshopFramework:MainQuest akQuestRef, Var[] akArgs)
	WorkshopScript kWorkshopRef = akArgs[0] as WorkshopScript
	Bool bPreviouslyUnloaded = akArgs[1] as Bool
	
	if(bPreviouslyUnloaded)
		HandlePlayerEnteredSettlement(kWorkshopRef)
	endif
EndEvent


Event WorkshopFramework:MainQuest.PlayerExitedSettlement(WorkshopFramework:MainQuest akQuestRef, Var[] akArgs)
	WorkshopScript kWorkshopRef = akArgs[0] as WorkshopScript
	Bool bStillLoaded = akArgs[1] as Bool
	
	if( ! bStillLoaded)
		HandlePlayerExitedSettlement(kWorkshopRef)
	else
		RegisterForRemoteEvent(kWorkshopRef, "OnUnload")
	endif
EndEvent


Event ObjectReference.OnUnload(ObjectReference akSender)
	WorkshopScript thisWorkshop = akSender as WorkshopScript
	
	if(thisWorkshop)
		HandlePlayerExitedSettlement(thisWorkshop)
	endif
	
	UnregisterForRemoteEvent(akSender, "OnUnload")
EndEvent

; ---------------------------------------------
; Event Handlers
; ---------------------------------------------

Function HandleQuestInit()
	; Init arrays
	SettlementScrapThreadingInProgress = new Bool[128]
	LootablePickupComplete = new Bool[128]
	
	SettlementBuildThreadingInProgress = new Bool[128]
	PowerUpPhaseComplete = new Bool[128]
	
	Parent.HandleQuestInit()
	
	
	if(F4SEManager.IsF4SERunning)
		Setting_Import_FauxPowerItems.SetValue(0.0)
	else
		; For Xbox and Non-F4SE players, lets default to faux power
		Setting_Import_FauxPowerItems.SetValue(1.0)
	endif
	
	RegisterForEvents()
EndFunction


Function HandleGameLoaded()
	bExportInProgress = false ; Make sure this never gets stuck
	
	if(HUDFrameworkManager.IsHUDFrameworkInstalled)
		bUseHUDProgressModule = true
	else
		bUseHUDProgressModule = false
	endif
	
	RegisterForEvents()
	
	Parent.HandleGameLoaded()
EndFunction

Function HandleInstallModChanges()
	if(iInstalledVersion < 27)
		; This check was failing in patch 26 (1.2.0), because F4SEManager was not correctly flagging before this quest initialized
		if(F4SEManager.IsF4SERunning)
			Setting_Import_FauxPowerItems.SetValue(0.0)
		else
			Setting_Import_FauxPowerItems.SetValue(1.0)
		endif
	endif
EndFunction


Function HandlePlayerEnteredSettlement(WorkshopScript akWorkshopRef)
	int iWorkshopID = akWorkshopRef.GetWorkshopID()
	
	; Handle scrapping
	int iIndex = AwaitingScrapping.Find(akWorkshopRef)
	if(iIndex >= 0)
		ScrapSettlement(AwaitingScrapping[iIndex])
	endif
EndFunction


Function HandlePlayerExitedSettlement(WorkshopScript akWorkshopRef)
	; Placeholder in case we need to react to this
EndFunction


; ---------------------------------------------
; Functions
; ---------------------------------------------

Function RegisterForEvents()
	RegisterForCustomEvent(WSFW_Main, "PlayerEnteredSettlement")
	RegisterForCustomEvent(WSFW_Main, "PlayerExitedSettlement")
EndFunction

Bool Function AllCallbacksReceived()
	if(iExportCallbacksReceived >= iAwaitingExportCallbacks)
		; Export callbacks are good, check placement
		if(LayoutBuildTracking != None)
			int i = 0
			while(i < LayoutBuildTracking.Length)
				if(LayoutBuildTracking[i] != None && LayoutBuildTracking[i].iAwaitingCallbacks > LayoutBuildTracking[i].iCallbacksReceived)
					return false
				endif
				
				i += 1
			endWhile
		endif
		
		; Check scrap callbacks
		if(iScrapCallbacksReceived < iAwaitingScrapCallbacks)
			return false
		endif
		
		; All call backs are complete
		return true
	endif
	
	return false
EndFunction


Bool Function AllCallbacksSent()
	; Check that all building, scrapping, and export processes have finished firing threads
	if(bExportThreadingInProgress)
		return false
	endif
	
	int i = 0
	while(i < 128)
		if(SettlementBuildThreadingInProgress[i] || SettlementScrapThreadingInProgress[i])
			return false
		endif
		
		i += 1
	endWhile
	
	return true
EndFunction


Function CleanLayoutsArray(WorkshopScript akWorkshopRef)
	int i = akWorkshopRef.AppliedLayouts.Length - 1
	
	while(i >= 0)
		if(akWorkshopRef.AppliedLayouts.Length > i && akWorkshopRef.AppliedLayouts[i] == None)
			akWorkshopRef.AppliedLayouts.Remove(i)
			akWorkshopRef.LayoutScrappingComplete.Remove(i)
			akWorkshopRef.LayoutPlacementComplete.Remove(i)
		else
			i -= 1
		endif
	endWhile
EndFunction


Function PresentLayoutManagementMenu(WorkshopScript akWorkshopRef)
	if( ! akWorkshopRef)
		return
	endif
	
	Bool bRelaunchMenu = false
	
	ObjectReference kTempName
	if(akWorkshopRef.AppliedLayouts != None && akWorkshopRef.AppliedLayouts.Length > 0)
		gMenuControl_RefreshLayout.SetValueInt(1)
	else
		gMenuControl_RefreshLayout.SetValueInt(0)
	endif
	
	; Display menu
	int iConfirm = LayoutManagementMenu.Show()
	
	if(iConfirm == 0)
		; Import/Manage Layouts
		bRelaunchMenu = PresentLayoutOptionsMenu(akWorkshopRef)
	elseif(iConfirm == 1)
		; Refresh Settlement
		int iWorkshopID = akWorkshopRef.GetWorkshopID()
		
		iConfirm = RefreshAllConfirmation.Show()
		if(iConfirm != 0)
			UpdatePowerUpPhaseStatus(iWorkshopID, false)
		endif
		
		if(iConfirm == 1)			
			RefreshSettlement(akWorkshopRef)
		elseif(iConfirm == 2)
			RefreshSettlement(akWorkshopRef, abRedoLayoutScrapping = false)
		endif		
	elseif(iConfirm == 2)
		iConfirm = ExportConfirmation.Show()
		
		if(iConfirm == 1)
			; Export Layout
			ExportSettlementLayout(akWorkshopRef = akWorkshopRef)
		endif
	elseif(iConfirm == 3)
		; Cancel
	endif
	
	if(kTempName != None)
		NameHolder_Layout.Clear()
		kTempName.Disable(false)
		kTempName.Delete()
	endif
	
	if(bRelaunchMenu)
		Var[] kArgs = new Var[1]
		kArgs[0] = akWorkshopRef
		
		CallFunctionNoWait("PresentLayoutManagementMenu", kArgs)
	endif
EndFunction


Bool Function PresentLayoutOptionsMenu(WorkshopScript akWorkshopRef, WorkshopFramework:Weapons:SettlementLayout[] AvailableLayouts = None, Int aiStart = 0)
	if(akWorkshopRef == None)
		return false
	endif
	
	; Build array of eligible for this settlement to speed up our menu
	if(AvailableLayouts == None || AvailableLayouts.Length == 0)
		AvailableLayouts = new WorkshopFramework:Weapons:SettlementLayout[0]
		
		int i = 0
		int iCount = SettlementLayoutList.GetSize()
		
		while(i < iCount && AvailableLayouts.Length < 128)
			WorkshopFramework:Weapons:SettlementLayout thisLayout = SettlementLayoutList.GetAt(i) as WorkshopFramework:Weapons:SettlementLayout
		
			if(thisLayout && GetUniversalForm(thisLayout.WorkshopRef) as WorkshopScript == akWorkshopRef)
				AvailableLayouts.Add(thisLayout)
			endif
		
			i += 1
		endWhile
	endif
	
	if(AvailableLayouts.Length == 0)
		NoLayoutsForThisSettlement.Show()
		return false
	endif
	
	int i = aiStart	
	int iCount = AvailableLayouts.Length
	Location thisLocation = akWorkshopRef.myLocation
	NameHolder_Settlement.ForceLocationTo(thisLocation)
	
	ObjectReference kSpawnPoint = SafeSpawnPoint.GetRef()
	Bool bCycle = true
	
	while(bCycle)
		WorkshopFramework:Weapons:SettlementLayout thisLayout = AvailableLayouts[i]
		
		; Setup aliases
		ObjectReference kTempLayoutName = kSpawnPoint.PlaceAtMe(thisLayout as Form)
		NameHolder_Layout.ForceRefTo(kTempLayoutName)
		ObjectReference kTempDesignerName = kSpawnPoint.PlaceAtMe(thisLayout.DesignerNameHolder)
		NameHolder_Designer.ForceRefTo(kTempDesignerName)
		
			; Check for plugins
		Int[] iMissingPluginIndexes = new Int[0]
		int j = 0
		while(j < thisLayout.sPluginsUsed.Length)
			if(thisLayout.sPluginsUsed[j] != "" && ! Game.IsPluginInstalled(thisLayout.sPluginsUsed[j]))
				iMissingPluginIndexes.Add(j)
			endif
			
			j += 1
		endWhile
		
		if(iMissingPluginIndexes.Length > 0)
			DynamicText_WarningLabel.ForceRefTo(StaticText_Warning.GetRef())
			DynamicText_WarningMessage.ForceRefTo(StaticText_PluginsMissing.GetRef())
			
			gMenuControl_MissingPlugins.SetValueInt(1)
		else
			DynamicText_WarningLabel.ForceRefTo(StaticText_Space.GetRef())
			DynamicText_WarningMessage.ForceRefTo(StaticText_Space.GetRef())
			
			gMenuControl_MissingPlugins.SetValueInt(0)
		endif
		
		if(thisLayout.InformationMessage != None)
			gMenuControl_LayoutInformation.SetValueInt(1)
		else
			gMenuControl_LayoutInformation.SetValueInt(0)
		endif
		
		int iIndex = akWorkshopRef.AppliedLayouts.Find(thisLayout)
		if(iIndex >= 0)
			gMenuControl_RefreshLayout.SetValueInt(1)
			gMenuControl_RemoveLayout.SetValueInt(1)
			gMenuControl_BuildLayout.SetValueInt(0)
		else
			gMenuControl_RefreshLayout.SetValueInt(0)
			gMenuControl_RemoveLayout.SetValueInt(0)
			gMenuControl_BuildLayout.SetValueInt(1)
		endif
		
		int iSelect = SettlementLayoutSelectMenu.Show()
		
		if(iSelect == 0) ; Next
			i += 1
		elseif(iSelect == 1) ; Previous
			i -= 1			
		elseif(iSelect == 2) ; Missing Plugins
			; Setup aliases
			Int iTotalMissing = iMissingPluginIndexes.Length
			Int iMaxPerPage = 5
			Int iCurrentPage = 1
			Int iPages = Math.Ceiling(iTotalMissing as Float/iMaxPerPage as Float)
			int iViewMissingSelection = 0
			ObjectReference[] kTempRefs = new ObjectReference[iTotalMissing]
			
			int k = 0
			while(k < iMissingPluginIndexes.Length)
				kTempRefs[k] = kSpawnPoint.PlaceAtMe(thisLayout.PluginNameHolders[iMissingPluginIndexes[k]])
				
				k += 1
			endWhile
			
				
			while(iViewMissingSelection < 2)
				Int iFirst = ((iCurrentPage - 1) * iMaxPerPage) + 1
				Int iTotalShowing = Math.Min(iTotalMissing - (iMaxPerPage * (iCurrentPage - 1)), iMaxPerPage) as Int
				
				k = 0
				while(k < iMaxPerPage)
					if(k + 1 > iTotalShowing)
						NameHolder_MissingPlugins[k].ForceRefTo(StaticText_Space.GetRef())
					else
						NameHolder_MissingPlugins[k].ForceRefTo(kTempRefs[iFirst - 1 + k])
					endif
					
					k += 1
				endWhile
								
				iViewMissingSelection = MissingPluginsMessage.Show(iTotalMissing, iFirst, iFirst + iTotalShowing - 1)
				
				if(iViewMissingSelection == 0)
					iCurrentPage += 1
				elseif(iViewMissingSelection == 1)
					iCurrentPage -= 1
				endif
				
				if(iCurrentPage > iPages)
					iCurrentPage = 1
				elseif(iCurrentPage < 1)
					iCurrentPage = 1
				endif
			endWhile			
			
			; Cleanup temp name objects
			k = 0
			while(k < kTempRefs.Length)	
				NameHolder_MissingPlugins[k].Clear()
				kTempRefs[k].Disable(false)
				kTempRefs[k].Delete()
				
				k += 1
			endWhile
		elseif(iSelect == 3) ; Layout information
			thisLayout.InformationMessage.Show()
		elseif(iSelect == 4) ; Use Layout
			int iConfirm = BuildConfirmation.Show()
			bCycle = false
			
			if(iConfirm == 0) ; Cancel
				bCycle = true ; Go back
			elseif(iConfirm == 1) ; Build and normal scrap application
				Bool bSuccess = TryToApplySettlementLayout(thisLayout)
			elseif(iConfirm == 2) ; Don't scrap anything
				Bool bSuccess = TryToApplySettlementLayout(thisLayout, abScrapAsRequestedByLayout = false)
			elseif(iConfirm == 3) ; Scrap everything player built, then build layout
				Bool bSuccess = TryToApplySettlementLayout(thisLayout, abScrapLinkedItemsInSettlementFirst = true)
			endif
		elseif(iSelect == 5) ; Refresh Layout
			int iConfirm = RefreshConfirmation.Show()
			
			if(iConfirm == 1) ; Also redo scrap
				bCycle = false
				
				RefreshSettlementLayout(akWorkshopRef, thisLayout, abRedoLayoutScrapping = true)
			elseif(iConfirm == 2) ; Skip scrap
				bCycle = false
				
				RefreshSettlementLayout(akWorkshopRef, thisLayout, abRedoLayoutScrapping = false)
			endif
		elseif(iSelect == 6) ; Remove Layout
			int iConfirm = RemoveConfirmation.Show()
			
			if(iConfirm == 1) ; 
				bCycle = false
				
				TryToClearSettlementLayout(thisLayout)
			endif
		elseif(iSelect == 7) ; Cancel
			; Handled below
		endif
		
		if(i < 0)
			i = AvailableLayouts.Length - 1
		elseif(i >= AvailableLayouts.Length)
			i = 0
		endif
		
		; Delete name holder refs
		kTempLayoutName.Disable(false)
		NameHolder_Layout.Clear()
		kTempDesignerName.Disable(false)
		NameHolder_Designer.Clear()
		
		if(iSelect == 7) ; Cancel
			return true ; Go back to other menu
		endif
	endWhile
	
	return false
EndFunction


Bool Function TryToApplySettlementLayout(WorkshopFramework:Weapons:SettlementLayout aApplyLayout, Bool abScrapAsRequestedByLayout = true, Bool abScrapLinkedItemsInSettlementFirst = false)
	; Check if target settlement exists
	if(aApplyLayout.WorkshopRef == None)
		return false
	endif
	
	WorkshopScript thisWorkshop = GetUniversalForm(aApplyLayout.WorkshopRef) as WorkshopScript
	
	if(thisWorkshop == None)
		return false
	endif
	
	; Check if already applied
	if(thisWorkshop.AppliedLayouts.Find(aApplyLayout) >= 0)
		return false
	endif

	; Flag as manual so we know to show a completed message
	bManualImportInProgress = true
	bManualScrapTriggered = false
	iProgressUpdateCounter_Build = 0
	fManuaBuildStartTime = Utility.GetCurrentRealTime()
	
	ThreadManager.RegisterForCallbackThreads(Self)
	
	; Add layout data to workshop ref
	AddSettlementLayout(thisWorkshop, aApplyLayout)
	
	; Scrap player built items and planned removed items
	if(abScrapAsRequestedByLayout || abScrapLinkedItemsInSettlementFirst)
		if(bUseHUDProgressModule)
			HUDFrameworkManager.CreateProgressBar(Self, sProgressBarID_Scrap, "Cleaning Up Settlement")
		endif
		
		ScrapSettlement(thisWorkshop, abScrapLinkedAndCollectLootables = abScrapLinkedItemsInSettlementFirst)
		
		if(iAwaitingScrapCallbacks <= iScrapCallbacksReceived)
			ScrappingCompleted()
		endif
	endif
	
	if(bUseHUDProgressModule)
		HUDFrameworkManager.CreateProgressBar(Self, sProgressBarID_Build, "Building Layout")
	endif
	
	; Trigger build
	BuildSettlement(thisWorkshop)
	
	return true
EndFunction
	
	
Function AddSettlementLayout(WorkshopScript akWorkshopRef, WorkshopFramework:Weapons:SettlementLayout aAddLayout)
	if(akWorkshopRef == None || aAddLayout == None)
		return
	endif
	
	CleanLayoutsArray(akWorkshopRef) ; Clear out any empty layouts due to uninstalled layout mods
	
	WorkshopFramework:Weapons:SettlementLayout[] CurrentLayouts = akWorkshopRef.AppliedLayouts
	if(CurrentLayouts != None && CurrentLayouts.Find(aAddLayout) >= 0)
		; This layout is already applied
		return
	endif
	
	; Store record so we can keep track of it and refresh it later
	aAddLayout.Add(akWorkshopRef)
	
	; Send out custom event
	SendAddSettlementLayoutEvent(akWorkshopRef, aAddLayout)
EndFunction


Function SendAddSettlementLayoutEvent(WorkshopScript akWorkshopRef, WorkshopFramework:Weapons:SettlementLayout aAppliedLayout)
	Var[] kArgs = new Var[2]
	kArgs[0] = akWorkshopRef
	kArgs[1] = aAppliedLayout
	
	SendCustomEvent("SettlementLayoutAdded", kArgs)
EndFunction


Function RemoveSettlementLayout(WorkshopScript akWorkshopRef, WorkshopFramework:Weapons:SettlementLayout aRemoveLayout)
	if(aRemoveLayout == None)
		return
	endif
	
	WorkshopFramework:Weapons:SettlementLayout[] CurrentLayouts = akWorkshopRef.AppliedLayouts
	if(CurrentLayouts != None && CurrentLayouts.Find(aRemoveLayout) >= 0)	
		aRemoveLayout.Remove(akWorkshopRef)
		
		SendScrapSettlementLayoutEvent(akWorkshopRef, aRemoveLayout)
	endif	
EndFunction


Function SendScrapSettlementLayoutEvent(WorkshopScript akWorkshopRef, WorkshopFramework:Weapons:SettlementLayout aRemovedLayout)
	Var[] kArgs = new Var[2]
	kArgs[0] = akWorkshopRef
	kArgs[1] = aRemovedLayout
	
	SendCustomEvent("SettlementLayoutScrapped", kArgs)
EndFunction


Bool Function TryToClearSettlementLayout(WorkshopFramework:Weapons:SettlementLayout aRemoveLayout)
	; Check if target settlement exists
	if(aRemoveLayout.WorkshopRef == None)
		return false
	endif
	
	WorkshopScript thisWorkshop = GetUniversalForm(aRemoveLayout.WorkshopRef) as WorkshopScript
	
	if(thisWorkshop == None)
		return false
	endif
	
	; Make sure this is applied
	if(thisWorkshop.AppliedLayouts.Find(aRemoveLayout) < 0)
		return false
	endif

	; Flag as manual so we know to show a completed message
	bManualScrapTriggered = true
	iProgressUpdateCounter_Scrap = 0
	iScrapCallbacksReceived = 0
	iAwaitingScrapCallbacks = iDummyCallbackCount
	int iPredictedThreads = aRemoveLayout.GetPredictedItemCount()
	int iActualThreads = 0
	
	iAwaitingScrapCallbacks += iPredictedThreads
	
	ThreadManager.RegisterForCallbackThreads(Self)
	
	if(bUseHUDProgressModule)
		HUDFrameworkManager.CreateProgressBar(Self, sProgressBarID_Scrap, "Scrapping Layout")
	endif
	
	iActualThreads = aRemoveLayout.RemoveLayoutObjects(thisWorkshop, abCallbacksNeeded = true)
	
	; Correct for over-prediction
	iAwaitingScrapCallbacks -= iPredictedThreads - iActualThreads	
	
	Utility.Wait(3.0)
	iAwaitingScrapCallbacks -= iDummyCallbackCount
	
	if(iAwaitingScrapCallbacks <= iScrapCallbacksReceived)
		ScrappingCompleted()
	endif
	
	; Remove layout data from workshop ref
	RemoveSettlementLayout(thisWorkshop, aRemoveLayout)
	
	return true
EndFunction


Int Function ScrapSettlement(WorkshopScript akWorkshopRef, Bool abScrapLinkedAndCollectLootables = false)
	if(akWorkshopRef == None)
		return -1
	endif
	
	int iWorkshopID = akWorkshopRef.GetWorkshopID()
		
	if(SettlementScrapThreadingInProgress[iWorkshopID])
		return -1
	endif
	
	if( ! akWorkshopRef.Is3dLoaded())
		QueueScrapSettlement(akWorkshopRef)
		
		return -1
	endif
	
	if(bUseHUDProgressModule && (bManualImportInProgress || bManualScrapTriggered))
		HUDFrameworkManager.CreateProgressBar(Self, sProgressBarID_Scrap, "Cleaning Up Settlement")
	endif
		
	; Prevent race conditions
	SettlementScrapThreadingInProgress[iWorkshopID] = true
	iAwaitingScrapCallbacks = iDummyCallbackCount ; Some arbitrarily high number to ensure the log doesn't prematurely close
	iProgressUpdateCounter_Scrap = 0
	int iActualThreads = 0
	int iPredictedThreads = 0
		
	; Add potential scrap callbacks from layouts to prediction
	int i = 0
	while(i < akWorkshopRef.AppliedLayouts.Length)
		if( ! akWorkshopRef.LayoutScrappingComplete[i])
			iPredictedThreads += akWorkshopRef.AppliedLayouts[i].VanillaObjectsToRemove.Length
		endif
		
		i += 1
	endWhile
	
	iAwaitingScrapCallbacks += iPredictedThreads	
	
	; Now we need to add linked ref count to prediction if we're doing a full scrap. Rather than end up with multiple calls to getlinkedrefchildren, let's just process that right here before we go back and do layer handling
	if(abScrapLinkedAndCollectLootables)
		; Start with linked refs
		ObjectReference[] kLinkedRefs = akWorkshopRef.GetLinkedRefChildren(WorkshopItemKeyword)
		iPredictedThreads += kLinkedRefs.Length
		iAwaitingScrapCallbacks += kLinkedRefs.Length
	
		i = 0
		while(i < kLinkedRefs.Length)
			if( ! abScrapLinkedAndCollectLootables || kLinkedRefs[i].IsCreated())
				if(kLinkedRefs[i].HasKeyword(PreventScrappingKeyword))
					; Remove this so future attempts to scrap the settlement will work
					kLinkedRefs[i].RemoveKeyword(PreventScrappingKeyword)
				else
					WorkshopFramework:ObjectRefs:Thread_ScrapObject kThread = ThreadManager.CreateThread(ScrapObjectThread) as WorkshopFramework:ObjectRefs:Thread_ScrapObject

					if(kThread)
						iActualThreads += 1
						kThread.kScrapMe = kLinkedRefs[i]
						kThread.kWorkshopRef = akWorkshopRef
						
						String sCallbackID = sScrapObjectCallbackID
						if( ! bManualImportInProgress && ! bManualScrapTriggered)
							sCallbackID = "" ; We don't need the event
						endif
						
						ThreadManager.QueueThread(kThread, sCallbackID)
					endif
				endif
			endif
			
			i += 1
		endWhile
				
		int iLootHandling = Setting_Import_HandleLootablesMethod.GetValueInt()
		if(iLootHandling > 0)
			; Grab all lootable items and stash them away
			WorkshopFramework:ScrapFinder ScrapFinderQuest = None
			int iCallerID = Utility.RandomInt(0, 999999)
			if(EventKeyword_ScrapFinder.SendStoryEventAndWait(akWorkshopRef.myLocation, aiValue1 = iCallerID))
				Utility.Wait(2.0) ; Give ScrapFinder a moment to configure it's caller ID variable
				
				int iQuestIndex = 0
				while(iQuestIndex < ScrapFinders.Length && ScrapFinderQuest == None)
					if(ScrapFinders[iQuestIndex].iCallerID == iCallerID)
						ScrapFinderQuest = ScrapFinders[iQuestIndex]
					endif
					
					iQuestIndex += 1
				endWhile
			endif 
			
			if(ScrapFinderQuest)
				if(iLootHandling == 1) ; Named the settling HandleLootablesMethod with the intention that we might want to code alternate methods beyond just Yes (put loot in workshop) and No (don't touch loot) in the future. Perhaps put the items directly in their inventory.
					; Handle lootables
					ObjectReference kMoveLootablesTo = akWorkshopRef
							
					RefCollectionAlias LootableObjects = ScrapFinderQuest.Lootable
					Location WorkshopLocation = akWorkshopRef.myLocation
					
					i = 0
					while(i < LootableObjects.GetCount())
						ObjectReference kThisRef = LootableObjects.GetAt(i)
						
						if(kThisRef.GetCurrentLocation() == WorkshopLocation || kThisRef.IsWithinBuildableArea(akWorkshopRef))
							kMoveLootablesTo.AddItem(kThisRef)
						endif
						
						i += 1
					endWhile
				endif
				
				ScrapFinderQuest.Stop()
			endif
		endif
	endif	
	
	; Handle scrapping based on layout needs
	i = 0
	while(i < akWorkshopRef.AppliedLayouts.Length)
		if( ! akWorkshopRef.LayoutScrappingComplete[i])
			int iLayoutThreads = akWorkshopRef.AppliedLayouts[i].RemoveVanillaObjects(akWorkshopRef, abCallbacksNeeded = (bManualImportInProgress || bManualScrapTriggered))
			iActualThreads += iLayoutThreads
			
			if(iLayoutThreads > 0 || akWorkshopRef.AppliedLayouts[i].VanillaObjectsToRemove == None || akWorkshopRef.AppliedLayouts[i].VanillaObjectsToRemove.Length == 0)
				akWorkshopRef.LayoutScrappingComplete[i] = true
			endif
		endif
		
		i += 1
	endWhile
	
	; Update for bad prediction
	iAwaitingScrapCallbacks -= iPredictedThreads - iActualThreads
	
	SettlementScrapThreadingInProgress[iWorkshopID] = false
	
	Utility.Wait(3.0) ; Give enough time for each call to have predicted callbacks
	iAwaitingScrapCallbacks -= iDummyCallbackCount
	
	if(iAwaitingScrapCallbacks <= iScrapCallbacksReceived)
		ScrappingCompleted()
	endif
	
	return iActualThreads
EndFunction


Function QueueScrapSettlement(WorkshopScript akWorkshopRef)
	if(AwaitingScrapping == None || AwaitingScrapping.Length == 0)
		AwaitingScrapping = new WorkshopScript[0]
	endif
	
	AwaitingScrapping.Add(akWorkshopRef)
EndFunction


Int Function FindAvailableLayoutTrackingSlot(Form aLayoutForm)
	if(LayoutBuildTracking == None || LayoutBuildTracking.Length == 0)
		LayoutBuildTracking = new CallbackTracking[128]
	endif
	
	int i = 0
	Int iFirstEmpty = -1
	while(i < LayoutBuildTracking.Length)
		if(LayoutBuildTracking[i] == None)
			if(iFirstEmpty < 0)
				iFirstEmpty = i
			endif
		elseif(LayoutBuildTracking[i].RelatedForm == aLayoutForm)
			return i
		endif
		
		i += 1
	endWhile
	
	CallbackTracking thisTracker = new CallbackTracking
	
	thisTracker.RelatedForm = aLayoutForm
	LayoutBuildTracking[iFirstEmpty] = thisTracker
	
	return iFirstEmpty
EndFunction


Function BuildSettlement(WorkshopScript akWorkshopRef)
	if(akWorkshopRef == None || akWorkshopRef.AppliedLayouts == None)
		return
	endif
	
	int iWorkshopID = akWorkshopRef.GetWorkshopID()
	
	if(SettlementBuildThreadingInProgress == None || SettlementBuildThreadingInProgress.Length == 0)
		SettlementBuildThreadingInProgress = new Bool[128]
	endif
	
	if(SettlementBuildThreadingInProgress[iWorkshopID])
		return
	endif
	
	SettlementBuildThreadingInProgress[iWorkshopID] = true ; This settlement under construction
	UpdatePowerUpPhaseStatus(iWorkshopID, false)
	
	; Check if scrapping is queued - if so, we need to protect these items from being scrapped as well
	Bool bIsScrappingQueued = AwaitingScrapping.Find(akWorkshopRef) >= 0
		
	; Prepare to thread
	ThreadManager.RegisterForCallbackThreads(Self)
	
	int i = 0	
	WorkshopFramework:Weapons:SettlementLayout[] Layouts = akWorkshopRef.AppliedLayouts
	
	; Need to set a prediction immediately to avoid a race condition where the layout placement threads complete before the AwaitingPlacementCallbacks are updated
	while(i < Layouts.Length)
		if( ! akWorkshopRef.LayoutPlacementComplete[i])
			int iCallbackTrackingIndex = FindAvailableLayoutTrackingSlot(Layouts[i])			
			int iPredictedThreads = Layouts[i].GetPredictedItemCount()			
			
			LayoutBuildTracking[iCallbackTrackingIndex].iAwaitingCallbacks += iPredictedThreads
		endif
		
		i += 1
	endWhile
	
	i = 0
	while(i < Layouts.Length)
		if( ! akWorkshopRef.LayoutPlacementComplete[i])
			int iCallbackTrackingIndex = FindAvailableLayoutTrackingSlot(Layouts[i])
			
			; Restore vanilla objects
			Layouts[i].RestoreVanillaObjects(akWorkshopRef)
			
			; Send our tracking index as a custom callback ID so we can track placement\
				; Build non-workshop resources
			int iThreadsStarted = Layouts[i].PlaceNonResourceObjects(akWorkshopRef, iCallbackTrackingIndex, abProtectFromScrapPhase = bIsScrappingQueued)
				; Build workshop resources
			iThreadsStarted += Layouts[i].PlaceWorkshopResources(akWorkshopRef, iCallbackTrackingIndex, abProtectFromScrapPhase = bIsScrappingQueued)
			
			; If prediction was off, correct it
			LayoutBuildTracking[iCallbackTrackingIndex].iAwaitingCallbacks -= Layouts[i].GetPredictedItemCount() - iThreadsStarted
			
			if(LayoutBuildTracking[iCallbackTrackingIndex].iCallbacksReceived >= LayoutBuildTracking[iCallbackTrackingIndex].iAwaitingCallbacks)
				BuildingCompleted(iCallbackTrackingIndex)
			endif
			
			akWorkshopRef.LayoutPlacementComplete[i] = true
		endif
		
		i += 1
	endWhile
	
	SettlementBuildThreadingInProgress[iWorkshopID] = false
EndFunction


Function PowerUpSettlement(WorkshopScript akWorkshopRef, WorkshopFramework:Weapons:SettlementLayout aSpecificLayout = None)
	WorkshopFramework:Weapons:SettlementLayout[] Layouts = akWorkshopRef.AppliedLayouts
	
	if(Layouts == None || Layouts.Length == 0)
		return
	endif
	
	if(aSpecificLayout != None)
		int iIndex = Layouts.Find(aSpecificLayout)
		if(iIndex < 0 || ! akWorkshopRef.LayoutPlacementComplete[iIndex] || aSpecificLayout.PowerConnections == None || aSpecificLayout.PowerConnections.Length == 0)
			return
		endif		
	else
		Bool bPowerDataFound = false
		int i = 0
		while(i < Layouts.Length && ! bPowerDataFound)
			if(akWorkshopRef.LayoutPlacementComplete[i])
				if(Layouts[i].PowerConnections != None && Layouts[i].PowerConnections.Length > 0)
					bPowerDataFound = true
				endif
			endif
			
			i += 1
		endWhile
		
		if( ! bPowerDataFound)
			return
		endif
	endif
	
	
	if(aSpecificLayout != None)		
		aSpecificLayout.PowerUp(akWorkshopRef)
	else
		int i = 0
		while(i < Layouts.Length)
			if(akWorkshopRef.LayoutPlacementComplete[i])
				Layouts[i].PowerUp(akWorkshopRef)
			endif
			
			i += 1
		endWhile
	endif
	
	int iWorkshopID = akWorkshopRef.GetWorkshopID()
	UpdatePowerUpPhaseStatus(iWorkshopID, true)
EndFunction


Function SendSettlementLayoutBuiltEvent(WorkshopScript akWorkshopRef, WorkshopFramework:Weapons:SettlementLayout aBuiltLayout)
	Var[] kArgs = new Var[2]
	kArgs[0] = akWorkshopRef
	kArgs[1] = aBuiltLayout
	
	SendCustomEvent("SettlementLayoutBuilt", kArgs)
EndFunction



Function RefreshSettlement(WorkshopScript akWorkshopRef, Bool abRedoLayoutScrapping = true)
	if(akWorkshopRef == None || akWorkshopRef.AppliedLayouts == None)
		return
	endif
	
	bManualImportInProgress = true
	bManualScrapTriggered = false
	iProgressUpdateCounter_Build = 0
	fManuaBuildStartTime = Utility.GetCurrentRealTime()
	iProgressUpdateCounter_Scrap = 0
	
	; For a refresh, we'll handle scrap calls directly so that we can remove that layer's items and also redo the scrap profile. ScrapSettlement can't do that, which means we have to handle our own progress bar and callbacks.
	
	; Prepare to thread
	ThreadManager.RegisterForCallbackThreads(Self)
	iScrapCallbacksReceived = 0
	iAwaitingScrapCallbacks = iDummyCallbackCount
	int iPredictedThreads = 0
	int iActualThreads = 0
		
	int iWorkshopID = akWorkshopRef.GetWorkshopID()
	int iAppliedLayoutCount = akWorkshopRef.AppliedLayouts.Length
	
	int i = 0
	while(i < iAppliedLayoutCount)
		WorkshopFramework:Weapons:SettlementLayout thisLayout = akWorkshopRef.AppliedLayouts[i]
		
		iPredictedThreads += thisLayout.GetPredictedItemCount() ; Start with this since we're going to scrap all original items given that this is a refresh
		
		if(abRedoLayoutScrapping)
			if(thisLayout.VanillaObjectsToRemove != None)
				iPredictedThreads += thisLayout.VanillaObjectsToRemove.Length
			endif
		endif	
	
		i += 1
	endWhile
	
	iAwaitingScrapCallbacks += iPredictedThreads
	
	if(bUseHUDProgressModule)
		HUDFrameworkManager.CreateProgressBar(Self, sProgressBarID_Scrap, "Scrapping Layout")
	endif
	
	i = 0
	while(i < iAppliedLayoutCount)
		WorkshopFramework:Weapons:SettlementLayout thisLayout = akWorkshopRef.AppliedLayouts[i]
	
		; Handle actual removal
		iActualThreads += thisLayout.RemoveLayoutObjects(akWorkshopRef, abCallbacksNeeded = true)
		
		if(abRedoLayoutScrapping)
			akWorkshopRef.LayoutScrappingComplete[i] = false
			
			if(thisLayout.VanillaObjectsToRemove != None)
				iActualThreads += thisLayout.RemoveVanillaObjects(akWorkshopRef, abCallbacksNeeded = true)
			endif
		endif
		
		i += 1
	endWhile
	
	
	; Correct for over-prediction
	iAwaitingScrapCallbacks -= iPredictedThreads - iActualThreads	
	
	; Queue up rebuild of settlement from ScrappingCompleted
	kWorkshopAwaitingBuildFromRefresh = akWorkshopRef
	i = 0
	while(i < iAppliedLayoutCount)
		akWorkshopRef.LayoutPlacementComplete[i] = false
	
		i += 1
	endWhile	
	
	Utility.Wait(3.0)
	iAwaitingScrapCallbacks -= iDummyCallbackCount
	
	if(iAwaitingScrapCallbacks <= iScrapCallbacksReceived)
		ScrappingCompleted()
	endif
EndFunction
	

Int Function RefreshSettlementLayout(WorkshopScript akWorkshopRef, WorkshopFramework:Weapons:SettlementLayout aLayoutForm, Bool abRedoLayoutScrapping = true)
	if(akWorkshopRef == None || akWorkshopRef.AppliedLayouts == None || akWorkshopRef.AppliedLayouts.Find(aLayoutForm) < 0)
		return -1
	endif
	
	bManualImportInProgress = true
	bManualScrapTriggered = false
	iProgressUpdateCounter_Build = 0
	fManuaBuildStartTime = Utility.GetCurrentRealTime()
	iProgressUpdateCounter_Scrap = 0
	
	; For a refresh, we'll handle scrap calls directly so that we can remove that layer's items and also redo the scrap profile. ScrapSettlement can't do that, which means we have to handle our own progress bar and callbacks.
	
	; Prepare to thread
	ThreadManager.RegisterForCallbackThreads(Self)
	iScrapCallbacksReceived = 0
	iAwaitingScrapCallbacks = iDummyCallbackCount
	int iPredictedThreads = aLayoutForm.GetPredictedItemCount() ; Start with this since we're going to scrap all original items given that this is a refresh
	int iActualThreads = 0
	
	if(abRedoLayoutScrapping && aLayoutForm.VanillaObjectsToRemove != None)
		iPredictedThreads += aLayoutForm.VanillaObjectsToRemove.Length
	endif
	
	iAwaitingScrapCallbacks += iPredictedThreads
	
	if(bUseHUDProgressModule)
		HUDFrameworkManager.CreateProgressBar(Self, sProgressBarID_Scrap, "Scrapping Layout")
	endif
	
	int iWorkshopID = akWorkshopRef.GetWorkshopID()
	int iLayoutIndex = akWorkshopRef.AppliedLayouts.Find(aLayoutForm)
	
	; Handle actual removal
	iActualThreads += aLayoutForm.RemoveLayoutObjects(akWorkshopRef, abCallbacksNeeded = true)
	
	if(abRedoLayoutScrapping)
		akWorkshopRef.LayoutScrappingComplete[iLayoutIndex] = false
		
		if(aLayoutForm.VanillaObjectsToRemove != None)
			iActualThreads += aLayoutForm.RemoveVanillaObjects(akWorkshopRef, abCallbacksNeeded = true)
		endif
	endif
	
	; Correct for over-prediction
	iAwaitingScrapCallbacks -= iPredictedThreads - iActualThreads
	
	Utility.Wait(3.0)
	
	iAwaitingScrapCallbacks -= iDummyCallbackCount
	
	if(iAwaitingScrapCallbacks <= iScrapCallbacksReceived)
		ScrappingCompleted()
	endif
	
	; Clear layout placement status so it gets placed again
	akWorkshopRef.LayoutPlacementComplete[iLayoutIndex] = false
	
	if(bUseHUDProgressModule)
		HUDFrameworkManager.CreateProgressBar(Self, sProgressBarID_Build, "Rebuilding Layout")
	endif
		
	; Rebuild settlement with existing applied layouts
	BuildSettlement(akWorkshopRef)
EndFunction


int iPreExportHolds = 0
Function PreExportHold(Bool abRelease = false)
	if(abRelease)
		iPreExportHolds -= 1
	else
		iPreExportHolds += 1
	endif
EndFunction


Function ExportSettlementLayout(String asExportFileName = "", WorkshopScript akWorkshopRef = None)
	if( ! F4SEManager.IsF4SERunning)
		Debug.MessageBox("This feature requires the Fallout 4 script extender (F4SE).")
		
		return
	endif	
	
	if( ! akWorkshopRef)
		akWorkshopRef = WorkshopFramework:WSFW_API.GetNearestWorkshop(PlayerRef)
		
		if( ! akWorkshopRef)
			Debug.MessageBox("Could not find a settlement to export. Try moving closer to the workbench.")
			
			return
		endif
	endif
	
	if(bExportInProgress)
		return
	endif
	
	iPreExportHolds = 0
	bExportInProgress = true
	bExportThreadingInProgress = true
	fExportStartTime = Utility.GetCurrentRealTime()
	
	; Prepare to export by closing previous log and resetting tracking variables
	Debug.CloseUserLog(sLastExportLogName)
	sLastExportLogName = ""
	iAwaitingExportCallbacks = iDummyCallbackCount ; Some arbitrarily high number to ensure the log doesn't prematurely close
	iExportCallbacksReceived = 0
	iProgressUpdateCounter_Export = 0
	
	if(bUseHUDProgressModule)
		HUDFrameworkManager.CreateProgressBar(Self, sProgressBarID_Export, "Exporting Settlement") ; TODO - Get an icon for this
		
		; Display immediately so user knows something is happening
		HUDFrameworkManager.UpdateProgressBarPercentage(Self, sProgressBarID_Export, 0)
	endif
	
	ThreadManager.RegisterForCallbackThreads(Self)
	
	String sPlayerName = F4SEManager.GetDisplayName(PlayerRef)
	
	; Open Debug Log
	if(asExportFileName == "")
		asExportFileName = sExportLogBase + "_" + Utility.RandomInt(0, 999999)
	endif
	
	Debug.OpenUserLog(asExportFileName)
	
	Var[] kArgs = new Var[2]
	kArgs[0] = akWorkshopRef
	kArgs[1] = asExportFileName
	
	SendCustomEvent("ExportStarting", kArgs)
	
	Utility.Wait(5.0)
	int iWaitCounter = 0
	int iLastHoldCount = 0
	; If any preexport lock gets stuck for more than 30 seconds, we'll just break free
	while(iPreExportHolds > 0 && iWaitCounter < 30)
		Utility.Wait(1.0)
		
		if(iPreExportHolds == iLastHoldCount)
			iWaitCounter += 1
		else
			iLastHoldCount = iPreExportHolds
		endif
	endWhile
	
	; Record workshop data - this section was added to support conversion to TS Blueprints
	Worldspace WorkshopWorldspace = akWorkshopRef.GetWorldspace()
	String sWorkshopData = sPlayerName + "," + WorkshopWorldspace + "," + F4SEManager.GetFormName(WorkshopWorldspace) + "," + F4SEManager.GetPluginNameFromForm(WorkshopWorldspace) + "," + akWorkshopRef.GetBaseObject() + "," + akWorkshopRef.GetParentCell() + "," + F4SEManager.GetPluginNameFromForm(akWorkshopRef.GetParentCell()) + "," + (akWorkshopRef.IsInInterior() as Int) + "," + akWorkshopRef.X + "," + akWorkshopRef.Y + "," + akWorkshopRef.Z + "," + akWorkshopRef.GetAngleX() + "," + akWorkshopRef.GetAngleY() + "," + akWorkshopRef.GetAngleZ() + "," + akWorkshopRef.GetValue(PopulationAV) as Int
	
	ModTraceCustom(asExportFileName, "=====================================")
	ModTraceCustom(asExportFileName, "Workshop Framework: Settlement Layout Export")
	ModTraceCustom(asExportFileName, "=====================================")
	ModTraceCustom(asExportFileName, "Internal Version Number: " + gCurrentVersion.GetValue())
	ModTraceCustom(asExportFileName, "=====================================")
	ModTraceCustom(asExportFileName, "Upload this log to SimSettlements.com/tools/layoutcreator.php to generate a mod file you can distribute!")
	ModTraceCustom(asExportFileName, "=====================================")
	ModTraceCustom(asExportFileName, "|||Starting export of settlement " + akWorkshopRef + ";;;" + F4SEManager.GetPluginNameFromForm(akWorkshopRef) + ";;;" + F4SEManager.GetFormName(akWorkshopRef.myLocation) + ";;;" + sWorkshopData)
	
	; Export load order
	String sPlugins = F4SEManager.GetInstalledPluginsString()
	String sLightPlugins = F4SEManager.GetInstalledLightPluginsString()
	ModTraceCustom(asExportFileName, "|||Load Order;;;" + sPlugins + ";;;" + sLightPlugins)
	
	if(Setting_Export_IncludeVanillaScrapInfo.GetValueInt() == 1)
		kArgs = new Var[2]
		kArgs[0] = akWorkshopRef
		kArgs[1] = asExportFileName
		; Calling export functions in parallel to reduce change the log will close before ExportLinkedItems has a chance to increment the iAwaitingExportCallbacks
		CallFunctionNoWait("ExportUnlinkedItems", kArgs)
	endif
	
	int iThreadsStarted = ExportLinkedItems(akWorkshopRef, asExportFileName)
	
	bExportThreadingInProgress = false
	; Record Debug Log name so that the next run can close it
	sLastExportLogName = asExportFileName
	
	Utility.Wait(3.0) ; Give enough time for each export call to have predicted callbacks
	iAwaitingExportCallbacks -=	iDummyCallbackCount
	
	
	if(iExportCallbacksReceived >= iAwaitingExportCallbacks)
		ExportCompleted()
	endif
EndFunction


Int Function ExportLinkedItems(WorkshopScript akWorkshopRef, String asLogName)
	; Linked objects
	ObjectReference[] kLinkedRefs = akWorkshopRef.GetLinkedRefChildren(WorkshopItemKeyword)
	
	int i = 0
	int iPredictedThreads = kLinkedRefs.Length
	int iActualThreads = 0
	iAwaitingExportCallbacks += iPredictedThreads
	Form[] AdditionalSkipForms = new Form[0]
	
	if(Setting_Export_IncludePowerArmor.GetValueInt() == 0)
		AdditionalSkipForms.Add(PowerArmorKeyword)
	endif
	
	while(i < kLinkedRefs.Length)
		WorkshopFramework:ObjectRefs:Thread_ExportObjectData kThread = ThreadManager.CreateThread(ExportObjectThread) as WorkshopFramework:ObjectRefs:Thread_ExportObjectData
		
		
		if(kThread)
			int j = 0
			while(j < AdditionalSkipForms.Length)
				kThread.AddSkipForm(AdditionalSkipForms[j])
				
				j += 1
			endWhile
			
			kThread.kWorkshopRef = akWorkshopRef
			kThread.kObjectRef = kLinkedRefs[i]
			kThread.sLogName = asLogName
			kThread.bIsLinkedWorkshopItem = true
			
			int iThreadQueueResult = ThreadManager.QueueThread(kThread, sExportCallbackID)
			
			if(iThreadQueueResult >= 0)
				iActualThreads += 1
			endif						
		endif
		
		i += 1
	endWhile
	
	; Correct for bad prediction
	ModTrace("[Export] Linked Item thread details: iAwaitingExportCallbacks (before prediction correction) = " + iAwaitingExportCallbacks + ", iPredictedThreads = " + iPredictedThreads + ", iActualThreads = " + iActualThreads)
	iAwaitingExportCallbacks -= iPredictedThreads - iActualThreads
	
	return iActualThreads
EndFunction


Int Function ExportUnlinkedItems(WorkshopScript akWorkshopRef, String asLogName)
	int iActualThreads = 0
	
	; Use ScrapFinder to find non-linked scrappable object data, this will be compared to our baseline to generate a scrap profile and figure out which items to restore/scrap
	WorkshopFramework:ScrapFinder ScrapFinderQuest = None
	int iCallerID = Utility.RandomInt(0, 999999)
	if(EventKeyword_ScrapFinder.SendStoryEventAndWait(akWorkshopRef.myLocation, aiValue1 = iCallerID))
		Utility.Wait(2.0) ; Give ScrapFinder a moment to configure it's caller ID variable
		int iQuestIndex = 0
		while(iQuestIndex < ScrapFinders.Length && ScrapFinderQuest == None)
			if(ScrapFinders[iQuestIndex].iCallerID == iCallerID)
				ScrapFinderQuest = ScrapFinders[iQuestIndex]
			endif
			
			iQuestIndex += 1
		endWhile
		
		if(ScrapFinderQuest)
			int i = 0
			RefCollectionAlias ScrappableCollection = ScrapFinderQuest.Scrappable
			int iCount = ScrappableCollection.GetCount()
			
			int iPredictedThreads = iCount
			
			iAwaitingExportCallbacks += iPredictedThreads
			while(i < iCount)
				WorkshopFramework:ObjectRefs:Thread_ExportObjectData kThread = ThreadManager.CreateThread(ExportObjectThread) as WorkshopFramework:ObjectRefs:Thread_ExportObjectData
		
				if(kThread)
					kThread.kWorkshopRef = akWorkshopRef
					kThread.kObjectRef = ScrappableCollection.GetAt(i)
					kThread.sLogName = asLogName
					kThread.bIsLinkedWorkshopItem = false
					
					int iThreadQueueResult = ThreadManager.QueueThread(kThread, sExportCallbackID)		
					
					if(iThreadQueueResult >= 0)
						iActualThreads += 1
					endif
				endif
				
				i += 1
			endWhile
			
			; Correct for bad prediction
			ModTrace("[Export] Unlinked Item thread details: iAwaitingExportCallbacks (before prediction correction) = " + iAwaitingExportCallbacks + ", iPredictedThreads = " + iPredictedThreads + ", iActualThreads = " + iActualThreads)
			iAwaitingExportCallbacks -= iPredictedThreads - iActualThreads
	
			ScrapFinderQuest.Stop()
		endif
	endif
	
	return iActualThreads
EndFunction

Function ExportCompleted()
	Debug.CloseUserLog(sLastExportLogName)
			
	if(bUseHUDProgressModule)
		HUDFrameworkManager.CompleteProgressBar(Self, sProgressBarID_Export)
	endif
	
	Float fExportEndTime = Utility.GetCurrentRealTime()
	bExportInProgress = false
	
	Debug.MessageBox("Completed Settlement Layout export in " + (fExportEndTime - fExportStartTime) + " seconds!\n\nFilename: %UserProfile%\\Documents\\My Games\\Fallout4\\Logs\\Script\\User\\" + sLastExportLogName + ".0.log\n\nIf you were unable to locate this file, you will need to enable Papyrus logging in your Fallout4Custom.ini and run this export again.")
EndFunction


Function BuildingCompleted(Int aiCallbackTrackingIndex)
	WorkshopFramework:Weapons:SettlementLayout thisLayout = LayoutBuildTracking[aiCallbackTrackingIndex].RelatedForm as WorkshopFramework:Weapons:SettlementLayout
			
	;Debug.MessageBox("Layout building completed. " + LayoutBuildTracking[aiCallbackTrackingIndex].iCallbacksReceived + " objects placed. Attempting to wire/power.")
	
	; All callbacks received, send out event, trigger power up, and clear this tracker
	WorkshopScript thisWorkshop = GetUniversalForm(thisLayout.WorkshopRef) as WorkshopScript
	int iWorkshopID = thisWorkshop.GetWorkshopID()
	
	; We suspended the individual objects from calling recalc on the workshop so let's do it now for the entire place
	thisWorkshop.RecalculateWorkshopResources()
	
	; Send out the event
	SendSettlementLayoutBuiltEvent(thisWorkshop, thisLayout)
	
	; Trigger power up			
	if(F4SEManager.IsF4SERunning && Setting_Import_F4SEPowerItems.GetValueInt() == 1)
		if( ! PowerUpPhaseComplete[iWorkshopID])
			if(thisWorkshop.Is3dLoaded() && PlayerRef.IsWithinBuildableArea(thisWorkshop))
				PowerUpSettlement(thisWorkshop, thisLayout)
			endif
		endif
	else
		UpdatePowerUpPhaseStatus(iWorkshopID, true)
	endif
	
	if(bManualImportInProgress)
		if(bUseHUDProgressModule)
			HUDFrameworkManager.CompleteProgressBar(Self, sProgressBarID_Build)
		endif
	
		BuildingFinished.Show(Utility.GetCurrentRealTime() - fManuaBuildStartTime)
	endif
	
	bManualImportInProgress = false
	
	LayoutBuildTracking[aiCallbackTrackingIndex] = None
EndFunction

Function ScrappingCompleted()
	if((bManualImportInProgress || bManualScrapTriggered) && bUseHUDProgressModule)
		HUDFrameworkManager.CompleteProgressBar(Self, sProgressBarID_Scrap)
	endif
		
	if(bManualScrapTriggered)				
		ScrappingFinished.Show()
	endif
	
	if(kWorkshopAwaitingBuildFromRefresh != None)
		WorkshopScript kRebuildMe = kWorkshopAwaitingBuildFromRefresh
		kWorkshopAwaitingBuildFromRefresh = None ; Set to None so another ScrappingCompleted call occurs before this one completes we don't end up running this twice
		
		if(bUseHUDProgressModule)
			HUDFrameworkManager.CreateProgressBar(Self, sProgressBarID_Build, "Rebuilding Layout")
		endif
	
		BuildSettlement(kRebuildMe)
	endif
	
	bManualScrapTriggered = false
EndFunction


; Test Functions
Function DumpSettlementLayoutInfo(WorkshopScript akWorkshopRef, Int aiType)
	int i = 0
	while(i < akWorkshopRef.AppliedLayouts.Length)
		WorkshopFramework:Weapons:SettlementLayout thisLayout = akWorkshopRef.AppliedLayouts[i]
		
		if(aiType == 0)
			thisLayout.DumpNonResourceObjects()
		elseif(aiType == 1)
			thisLayout.DumpWorkshopResources()
		elseif(aiType == 2)
			thisLayout.DumpPowerConnections()
		endif
		
		i += 1
	endWhile	
EndFunction