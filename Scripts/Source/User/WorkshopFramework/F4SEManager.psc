; ---------------------------------------------
; WorkshopFramework:F4SEManager.psc - by kinggath
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

Scriptname WorkshopFramework:F4SEManager extends WorkshopFramework:Library:SlaveQuest Conditional
{ Acts as an interface to F4SE }

import WorkshopFramework:Library:DataStructures
import WorkshopFramework:Library:UtilityFunctions
import WSFWIdentifier

; ---------------------------------------------
; Consts
; ---------------------------------------------

int iExpectedVersion_Major = 0 Const
int iExpectedVersion_Minor = 6 Const
int iExpectedVersion_Release = 12 Const

; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------

Group Settings
	GlobalVariable Property Setting_IgnoreF4SEVersion Auto Const Mandatory
EndGroup

Group Controllers
	WorkshopParentScript Property WorkshopParent Auto Const Mandatory
	;WorkshopFramework:MainQuest Property WSFW_Main Auto Const Mandatory
	WorkshopFramework:PersistenceManager Property PersistenceManager Auto Const Mandatory
EndGroup

Group Keywords
	Keyword Property WorkshopItemKeyword Auto Const Mandatory
EndGroup

Group Messages	
	Message Property Menu_RemoteSettlementOption Auto Const Mandatory
	Message Property Confirm_ScanPowerGrid Auto Const Mandatory
	Message Property Confirm_RepairPowerGrid Auto Const Mandatory
	Message Property Confirm_ResetPowerGrid Auto Const Mandatory
	Message Property Confirm_ResetLocation Auto Const Mandatory

	Message Property Complete_ScanPowerGrid Auto Const Mandatory
	Message Property Failure_RepairPowerGrid Auto Const Mandatory
	Message Property Success_RepairPowerGrid Auto Const Mandatory
	Message Property Complete_ResetPowerGrid Auto Const Mandatory
	Message Property Failure_ResetLocation Auto Const Mandatory
	Message Property Success_ResetLocation Auto Const Mandatory
	Message Property ConfirmOverride_RemoteSettlement Auto Const Mandatory
EndGroup

; ---------------------------------------------
; Properties
; ---------------------------------------------

Bool bFirstCheckComplete = false
Bool bIsF4SERunning = false Conditional
Bool Property IsF4SERunning
	Bool Function Get()
		if( ! bFirstCheckComplete)
			bFirstCheckComplete = true
			F4SERunningCheck()
		endif
		
		return bIsF4SERunning
	EndFunction
EndProperty

Int iVersion_Major = 0
Int iVersion_Minor = 0
Int iVersion_Release = 0


; ---------------------------------------------
; Vars
; ---------------------------------------------

; ---------------------------------------------
; Events 
; ---------------------------------------------

Function HandleGameLoaded()
	Parent.HandleGameLoaded()
	
	F4SERunningCheck()
EndFunction


; ---------------------------------------------
; Methods 
; ---------------------------------------------

Function F4SERunningCheck()
	bIsF4SERunning = false
	
	if(F4SE.GetVersion() > 0 || F4SE.GetVersionMinor() > 0)
		bIsF4SERunning = true
		iVersion_Major = F4SE.GetVersion()
		iVersion_Minor = F4SE.GetVersionMinor()
		iVersion_Release = F4SE.GetVersionRelease()
	endif
EndFunction


Bool Function F4SECheck()
	if( ! IsF4SERunning)
		return false
	endif
	
	if(Setting_IgnoreF4SEVersion.GetValueInt() == 1)
		return true
	else
		if(iVersion_Major == iExpectedVersion_Major && iVersion_Minor == iExpectedVersion_Minor && iVersion_Release == iExpectedVersion_Release)
			return true
		endif		
	endif
	
	return false
EndFunction


ObjectReference[] Function GetConnectedObjects(ObjectReference akObjectRef)
	return akObjectRef.GetConnectedObjects()
EndFunction

String Function GetFormName(Form aForm)
	String sName = aForm.GetName()
	
	return sName
EndFunction

String Function GetDisplayName(ObjectReference akObjectRef)
	String sName = akObjectRef.GetDisplayName()
	
	return sName
EndFunction

Function TestAttachWire(ObjectReference akOriginRef, ObjectReference akTargetRef, Form akSpline = None)
	ObjectReference kWireRef = akOriginRef.AttachWire(akTargetRef, akSpline)
	
	if(kWireRef != None)
		kWireRef.Enable(false)
	else
		Debug.MessageBox("Failed to attach wire.")
	endif
EndFunction


ObjectReference Function AttachWire(ObjectReference akOriginRef, ObjectReference akTargetRef, Form akSpline = None)
	Return AttachWireV2( None, akOriginRef, akTargetRef, akSpline )
EndFunction

ObjectReference Function AttachWireV2(ObjectReference akWorkshopRef, ObjectReference akOriginRef, ObjectReference akTargetRef, Form akSpline = None)
	ObjectReference lkResult = akOriginRef.AttachWire(akTargetRef, akSpline)
	If( lkResult != None )
		If( akWorkshopRef != None )
			;; Wires must be linked to the workshop too or holes in the PowerGrid may appear
			lkResult.SetLinkedRef( akWorkshopRef, WorkshopItemKeyword )
		EndIf
		PersistenceManager.QueueObjectPersistence( lkResult )
	EndIf
	Return lkResult
EndFunction

ObjectReference Function CreateWire(ObjectReference akOriginRef, ObjectReference akTargetRef, Form akSpline = None)
	Return CreateWireV2( None, akOriginRef, akTargetRef, akSpline )
EndFunction

ObjectReference Function CreateWireV2(ObjectReference akWorkshopRef, ObjectReference akOriginRef, ObjectReference akTargetRef, Form akSpline = None)
	ObjectReference lkResult = akOriginRef.CreateWire(akTargetRef, akSpline)
	If( lkResult != None )
		If( akWorkshopRef != None )
			;; Wires must be linked to the workshop too or holes in the PowerGrid may appear
			lkResult.SetLinkedRef( akWorkshopRef, WorkshopItemKeyword )
		EndIf
		PersistenceManager.QueueObjectPersistence( lkResult )
	EndIf
	Return lkResult
EndFunction


Bool Function TransmitConnectedPower(ObjectReference akObjectRef)
	return akObjectRef.TransmitConnectedPower()
EndFunction


Int Function GetLoadOrderAgnosticFormID(Int aiFormID)
	return Math.LogicalAnd(aiFormID, 0x00FFFFFF)
EndFunction

String Function GetInstalledPluginsString(String sDelimiter = ",")
	String sPlugins = ""
	
	Game:PluginInfo[] Plugins = Game.GetInstalledPlugins()
	
	int i = 0
	while(i < Plugins.length)
		sPlugins += Plugins[i].Name + ","
		
		i += 1
	endWhile
	
	return sPlugins
EndFunction

String Function GetInstalledLightPluginsString(String sDelimiter = ",")
	String sLightPlugins = ""
	
	Game:PluginInfo[] LightPlugins = Game.GetInstalledLightPlugins()
	
	int i = 0
	while(i < LightPlugins.length)
		sLightPlugins += LightPlugins[i].Name + ","
		
		i += 1
	endWhile
	
	return sLightPlugins
EndFunction

String Function GetPluginNameFromForm(Form aFormOrReference, Bool abCheckLightPluginsOnly = false)
	if(aFormOrReference != None)
		int iFormID = aFormOrReference.GetFormID()
		iFormID = GetLoadOrderAgnosticFormID(iFormID)
		Game:PluginInfo[] Plugins = Game.GetInstalledPlugins()
		Game:PluginInfo[] LightPlugins = Game.GetInstalledLightPlugins()
		
		if( ! abCheckLightPluginsOnly)
			int i = 0
			while(i < Plugins.Length)
				Form FetchForm = Game.GetFormFromFile(iFormID, Plugins[i].Name)
				
				if(FetchForm != None && FetchForm == aFormOrReference && Plugins[i].Name != "")
					return Plugins[i].Name
				endif
				
				i += 1
			endWhile
		endif
		
		int i = 0
		while(i < LightPlugins.Length)
			Form FetchForm = Game.GetFormFromFile(iFormID, LightPlugins[i].Name)
			
			if(FetchForm != None)
				if(FetchForm == aFormOrReference && Plugins[i].Name != "")
					return LightPlugins[i].Name
				else
					;ModTrace("LightPlugin: Form " + FetchForm + " found, but doesn't match requested form " + aFormOrReference)
				endif
			else
				;ModTrace("LightPlugin: [" + LightPlugins[i].Index + "] " + LightPlugins[i].Name + " doesn't have a form matching: " + iFormID)
			endif
			
			i += 1
		endWhile
		
		ModTrace("[GetPluginNameFromForm] Failed to find plugin name for " + aFormOrReference)
	else
		ModTrace("Could not find plugin to match " + aFormOrReference)
	endif
	
	return ""
EndFunction

;
; Below functions provided by WSFWIdentifier.dll, created by cdante
;

String Function WSFWID_GetReferenceName(ObjectReference akObjectRef)
	String sName = WSFWIdentifier.GetReferenceName(akObjectRef)
	
	return sName
EndFunction

int iPowerGridFix_CheckOnly = 0 Const
int iPowerGridFix_RemoveBadGrids = 1 Const
int iPowerGridFix_RemoveBadNodes = 2 Const ; Added in 2.3.3

Bool Function WSFWID_CheckAndFixPowerGrid(WorkshopScript akWorkshopRef = None, Bool abFixAndScan = true, Bool abResetIfFixFails = false)
	if(akWorkshopRef == None)
		;akWorkshopRef = WorkshopFramework:WSFW_API.GetNearestWorkshop(Game.GetPlayer())
		
		if(akWorkshopRef == None)
			ModTrace("WSFWID_CheckAndFixPowerGrid could not find a valid settlement to check.")
			return true
		endif
	endif
	
	Int iFix = iPowerGridFix_CheckOnly
	if(abFixAndScan)
		iFix = iPowerGridFix_RemoveBadNodes
	endif
	
	PowerGridStatistics Results = WSFWIdentifier.CheckAndFixPowerGrid(akWorkshopRef, iFix)
	
	ModTrace("CheckAndFixPowerGrid " + akWorkshopRef + " results: " + Results)
	
	if(abFixAndScan) ; Should be fixed
		Results = WSFWIdentifier.CheckAndFixPowerGrid(akWorkshopRef, 0) ; Scan again - should be clean
		
		ModTrace("abFixAndScan == true, Rescan with iFix == 0: " + akWorkshopRef + " results: " + Results)
		if(abResetIfFixFails && Results.broken)
			ModTrace("Corrupt power grid detected, calling WSFWID_ResetPowerGrid on " + akWorkshopRef + ".")
			WSFWID_ResetPowerGrid(akWorkshopRef, abAutoRan = true)
		endif
	endif
	
	return Results.broken
EndFunction

Function MCM_RepairPowerGrid()
	bool bSuccess = WSFWID_CheckAndFixPowerGrid(akWorkshopRef = None, abFixAndScan = true, abResetIfFixFails = false)
EndFunction

Bool Function WSFWID_ResetPowerGrid(WorkshopScript akWorkshopRef = None, Bool abAutoRan = false)
	if(akWorkshopRef == None)
		;akWorkshopRef = WorkshopFramework:WSFW_API.GetNearestWorkshop(Game.GetPlayer())
		
		if(akWorkshopRef == None)
			ModTrace("WSFWID_ResetPowerGrid could not find a valid settlement to check.")
			return true
		endif
	endif
	
	Bool bSuccess = WSFWIdentifier.ResetPowerGrid(akWorkshopRef)
	
	if(bSuccess)
		if(abAutoRan)
			if(PlayerRef.IsWithinBuildableArea(akWorkshopRef))
				;WSFW_Main.OfferPostResetPowerGridRebuild(akWorkshopRef)
			else
				akWorkshopRef.bPowerGridRebuildOfferNeeded = true
				
				;WSFW_Main.ShowPowerGridResetWarning(akWorkshopRef)
			endif
		endif
	endif
	
	ModTrace("ResetPowerGrid " + akWorkshopRef + " returned: " + bSuccess)
	
	return bSuccess
EndFunction

Function MCM_ResetPowerGrid()
	bool bSuccess = WSFWID_ResetPowerGrid(akWorkshopRef = None, abAutoRan = false)
EndFunction

Bool Function WSFWID_ScanPowerGrid(WorkshopScript akWorkshopRef = None)
	if(akWorkshopRef == None)
		;akWorkshopRef = WorkshopFramework:WSFW_API.GetNearestWorkshop(Game.GetPlayer())
		
		if(akWorkshopRef == None)
			ModTrace("WSFWID_ScanPowerGrid could not find a valid settlement to check.")
			return true
		endif
	endif
	
	; First make sure a grid exists or this will crash the game
	PowerGridStatistics Results = WSFWIdentifier.CheckAndFixPowerGrid(akWorkshopRef, 0)
	
	if(Results.totalGrids <= 0)
		return true
	endif
	
	Bool bSuccess = WSFWIdentifier.ScanPowerGrid(akWorkshopRef)
	
	ModTrace("ScanPowerGrid " + akWorkshopRef + " returned: " + bSuccess + ". Full grid output dumped to Documents\\My Games\\Fallout4\\F4SE\\wsfw_identifier.log.")
	
	return bSuccess
EndFunction

Function MCM_ScanPowerGrid()
	Bool bSuccess = WSFWID_ScanPowerGrid(akWorkshopRef = None)
EndFunction


Function WSFWID_RemoveNodesFromPowerGrid(WorkshopScript akWorkshopRef = None, Int[] aiNodesToRemove = None)
	if(akWorkshopRef == None)
		akWorkshopRef = WorkshopFramework:WSFW_API.GetNearestWorkshop(Game.GetPlayer())
		
		if(akWorkshopRef == None)
			ModTrace("WSFWID_RemoveNodesFromPowerGrid could not find a valid settlement to check.")
			return
		endif
	endif
	
	if(aiNodesToRemove == None)
		return
	endif
	
	if(aiNodesToRemove != None && aiNodesToRemove.Length > 0)
		Int[] iResults = WSFWIdentifier.RemoveNodesFromPowerGrid(akWorkshopRef, aiNodesToRemove)
	endif
EndFunction



Function ShowRemoteLocationManagementMenu()
	; Pick Settlement
	Location ChosenLocation = PlayerRef.OpenWorkshopSettlementMenuEx(None, ConfirmOverride_RemoteSettlement, abExcludeZeroPopulation = false, abOnlyOwnedWorkshops = false, abTurnOffHeader = true, abOnlyPotentialVassalSettlements = false, abDisableReservedByQuests = false)
	
	if(ChosenLocation != None)
		WorkshopScript kChosenWorkshop = WorkshopParent.GetWorkshopFromLocation(ChosenLocation)
		
		if(kChosenWorkshop == None)
			return
		endif		
		
		; Pick Option
		int iChoice = Menu_RemoteSettlementOption.Show()
		
		if(iChoice == 0)
			return ; Cancel
		elseif(iChoice == 1)
			; Scan Power Grid
			iChoice = Confirm_ScanPowerGrid.Show()
			
			if(iChoice == 0)
				return ; Cancel
			else
				Bool bSuccess = WSFWID_ScanPowerGrid(akWorkshopRef = kChosenWorkshop)
				
				Complete_ScanPowerGrid.Show()
			endif
		elseif(iChoice == 2)
			; Repair Power Grid
			iChoice = Confirm_RepairPowerGrid.Show()
			
			if(iChoice == 0)
				return ; Cancel
			else
				Bool bSuccess = WSFWID_CheckAndFixPowerGrid(akWorkshopRef = kChosenWorkshop, abFixAndScan = true, abResetIfFixFails = false)
				
				if(bSuccess)
					Success_RepairPowerGrid.Show()
				else
					Failure_RepairPowerGrid.Show()
				endif
			endif
		elseif(iChoice == 3)
			; Reset Power Grid
			iChoice = Confirm_ResetPowerGrid.Show()
			
			if(iChoice == 0)
				return ; Cancel
			else
				Bool bSuccess = WSFWID_ResetPowerGrid(kChosenWorkshop, abAutoRan = false)
				
				Complete_ResetPowerGrid.Show()
			endif
		elseif(iChoice == 4)
			if(kChosenWorkshop.Is3dLoaded())
				Failure_ResetLocation.Show()
			else
				; Reset Location
				iChoice = Confirm_ResetLocation.Show()
				
				if(iChoice == 0)
					return ; Cancel
				else
					ChosenLocation.Reset()
					
					Success_ResetLocation.Show()
				endif
			endif
		endif
	endif
EndFunction

;
; Test Plugins
;


Function CountPluginsPopup()
	Debug.MessageBox("Plugins: " + Game.GetInstalledPlugins().Length + "\nLight Plugins: " + Game.GetInstalledLightPlugins().Length)
EndFunction


Function DumpLoadOrder()
	Game:PluginInfo[] Plugins = Game.GetInstalledPlugins()
	Game:PluginInfo[] LightPlugins = Game.GetInstalledLightPlugins()
	
	ModTrace("======================================")
	ModTrace("Dumping Load Order > Light Plugins")
	ModTrace("======================================")
	
	int i = 0
	while(i < LightPlugins.Length)
		ModTrace("[" + i + "] " + LightPlugins[i]) 
		
		i += 1
	endWhile
	
	ModTrace("======================================")
	ModTrace("Dumping Load Order > Plugins")
	ModTrace("======================================")
	
	i = 0
	while(i < Plugins.Length)
		ModTrace("[" + i + "] " + Plugins[i]) 
		
		i += 1
	endWhile
EndFunction