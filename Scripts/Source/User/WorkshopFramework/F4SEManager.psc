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



ObjectReference Function AttachWire(ObjectReference akOriginRef, ObjectReference akTargetRef, Form akSpline = None)
	return akOriginRef.AttachWire(akTargetRef, akSpline)
EndFunction

ObjectReference Function CreateWire(ObjectReference akOriginRef, ObjectReference akTargetRef, Form akSpline = None)
	return akOriginRef.CreateWire(akTargetRef, akSpline)
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
; Below funcitons provided by WSFWIdentifier.dll, created by cdante
;

String Function WSFWID_GetReferenceName(ObjectReference akObjectRef)
	String sName = GetReferenceName(akObjectRef)
	
	return sName
EndFunction

Bool Function WSFWID_CheckAndFixPowerGrid(WorkshopScript akWorkshopRef = None, Bool abFixAndScan = true, Bool abResetIfFixFails = false)
	if(akWorkshopRef == None)
		akWorkshopRef = WorkshopFramework:WSFW_API.GetNearestWorkshop(Game.GetPlayer())
		
		if(akWorkshopRef == None)
			ModTrace("WSFWID_CheckAndFixPowerGrid could not find a valid settlement to check.")
			return true
		endif
	endif
	
	Int iFix = abFixAndScan as Int
	
	PowerGridStatistics Results = CheckAndFixPowerGrid(akWorkshopRef, iFix)
	
	ModTrace("CheckAndFixPowerGrid " + akWorkshopRef + " results: " + Results)
	
	if(abFixAndScan) ; Should be fixed
		Results = CheckAndFixPowerGrid(akWorkshopRef, 0) ; Scan again - should be clean
		
		ModTrace("abFixAndScan == true, Rescan with iFix == 0: " + akWorkshopRef + " results: " + Results)
		if(abResetIfFixFails && Results.broken)
			ModTrace("Corrupt power grid detected, calling WSFWID_ResetPowerGrid on " + akWorkshopRef + ".")
			WSFWID_ResetPowerGrid(akWorkshopRef)
		endif
	endif
	
	return Results.broken
EndFunction

Function MCM_RepairPowerGrid()
	bool bSuccess = WSFWID_CheckAndFixPowerGrid(akWorkshopRef = None, abFixAndScan = true, abResetIfFixFails = false)
EndFunction

Bool Function WSFWID_ResetPowerGrid(WorkshopScript akWorkshopRef = None)
	if(akWorkshopRef == None)
		akWorkshopRef = WorkshopFramework:WSFW_API.GetNearestWorkshop(Game.GetPlayer())
		
		if(akWorkshopRef == None)
			ModTrace("WSFWID_ResetPowerGrid could not find a valid settlement to check.")
			return true
		endif
	endif
	
	Bool bSuccess = ResetPowerGrid(akWorkshopRef)
	
	ModTrace("ResetPowerGrid " + akWorkshopRef + " returned: " + bSuccess)
	
	return bSuccess
EndFunction

Function MCM_ResetPowerGrid()
	bool bSuccess = WSFWID_ResetPowerGrid(akWorkshopRef = None)
EndFunction

Bool Function WSFWID_ScanPowerGrid(WorkshopScript akWorkshopRef = None)
	if(akWorkshopRef == None)
		akWorkshopRef = WorkshopFramework:WSFW_API.GetNearestWorkshop(Game.GetPlayer())
		
		if(akWorkshopRef == None)
			ModTrace("WSFWID_ScanPowerGrid could not find a valid settlement to check.")
			return true
		endif
	endif
	
	; First make sure a grid exists or this will crash the game
	PowerGridStatistics Results = CheckAndFixPowerGrid(akWorkshopRef, 0)
	
	if(Results.totalGrids <= 0)
		return true
	endif
	
	Bool bSuccess = ScanPowerGrid(akWorkshopRef)
	
	ModTrace("ScanPowerGrid " + akWorkshopRef + " returned: " + bSuccess + ". Full grid output dumped to Documents\\My Games\\Fallout4\\F4SE\\wsfw_identifier.log.")
	
	return bSuccess
EndFunction

Function MCM_ScanPowerGrid()
	Bool bSuccess = WSFWID_ScanPowerGrid(akWorkshopRef = None)
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