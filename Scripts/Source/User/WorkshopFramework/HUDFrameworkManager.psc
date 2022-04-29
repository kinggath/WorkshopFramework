; ---------------------------------------------
; WorkshopFramework:HUDFrameworkManager.psc - by kinggath
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

Scriptname WorkshopFramework:HUDFrameworkManager extends WorkshopFramework:Library:SlaveQuest Conditional
{ Interface for HUDFramework - ensures no hard requirement on HUDFramework, acts as a throttle to prevent overloading HUDFramework, offers some common elements without the need for the mod author to do any flash work. }


import WorkshopFramework:Library:UtilityFunctions
import WorkshopFramework:Library:DataStructures

; ---------------------------------------------
; Consts
; ---------------------------------------------

int iCommand_ShowProgressBar = 201 Const
int iCommand_HideProgressBar = 202 Const
int iCommand_AddProgressBar = 301 Const ; Update label and icon
int iCommand_UpdateProgressBar = 401 Const ; Update number

String sDelimiter_CommandString = "]"

String sWSFWWidget_Framework = "WorkshopFramework_HUDFramework.swf"

int MAXPROGRESSBARID = 1000000 Const ; Some large value. We just want to make sure that we never overwrite an earlier progress bar and that we never go out of bounds for an int. This will be checked on game load and if iNextProgressBarID is larger than this, it will reset to 0

; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------


; ---------------------------------------------
; Properties
; ---------------------------------------------

Bool bIsHUDFrameworkInstalled = false Conditional
Bool Property IsHUDFrameworkInstalled
	Bool Function Get()
		return bIsHUDFrameworkInstalled
	EndFunction
EndProperty

Float Property fWSFWWidget_HUDFrameworkX = 1000.0 Auto Hidden ; right side of screen
Float Property fWSFWWidget_HUDFrameworkY = 70.0 Auto Hidden

Float fWSFWWidget_HUDFrameworkXSS2Override = 900.0 Const

int iNextProgressBarID = 0
Int Property NextProgressBarID
	Int Function Get()
		iNextProgressBarID += 1
		
		return iNextProgressBarID
	EndFunction
EndProperty

; ---------------------------------------------
; Vars
; ---------------------------------------------

ScriptObject HudInstance = None
String[] RegisteredWidgets

ProgressBar[] RegisteredProgressBars



; ---------------------------------------------
; Events 
; ---------------------------------------------

; TODO - Allow position and scaling of the progress bars block (can we add outline while positioning/scaling?)

Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)
    if(asMenuName== "WorkshopMenu")
        ShowHUDWidgetsInWorkshopMode()
    endif
endEvent


; ---------------------------------------------
; Methods 
; ---------------------------------------------

Function HandleQuestInit()
	RegisteredProgressBars = new ProgressBar[0]
	
	Parent.HandleQuestInit()
	
	MustRunOnStartup() 
EndFunction


Function MustRunOnStartup() 
	RegisterForMenuOpenCloseEvent("WorkshopMenu")
	PrepareHUDFramework()
EndFunction


Function HandleGameLoaded()
	MustRunOnStartup() 
	
	Parent.HandleGameLoaded()	
	
	if(HudInstance == None || RegisteredWidgets == None)
		RegisteredWidgets = new String[0]
	endif
	
	; Register any of the WorkshopFramework included widgets
	Float fX = fWSFWWidget_HUDFrameworkX
	if(Game.IsPluginInstalled("SS2.esm"))
		fX = fWSFWWidget_HUDFrameworkXSS2Override
	endif
	
	if(RegisteredWidgets.Find(sWSFWWidget_Framework) < 0)
		RegisterWidget(Self, sWSFWWidget_Framework, fX, fWSFWWidget_HUDFrameworkY)
	else
		SetWidgetPosition(sWSFWWidget_Framework, fX, fWSFWWidget_HUDFrameworkY)
	endif
	
	if(iNextProgressBarID > MAXPROGRESSBARID)
		; Make sure we never go out of bounds
		iNextProgressBarID = 0
	endif
	
	; Restore any progress bars
	int i = 0
	if(RegisteredProgressBars != None)
		while(i < RegisteredProgressBars.Length)
			CreateProgressBar(RegisteredProgressBars[i].Source, RegisteredProgressBars[i].sSourceID, RegisteredProgressBars[i].sLabel, RegisteredProgressBars[i].sIconPath)
			
			UpdateProgressBarPercentage(RegisteredProgressBars[i].Source, RegisteredProgressBars[i].sSourceID, RegisteredProgressBars[i].fValue as Int)
			
			i += 1
		endWhile
	endif
EndFunction


Function HandleInstallModChanges()
	if(iInstalledVersion < 26) ; 1.2.0
		RegisterForMenuOpenCloseEvent("WorkshopMenu")
	endif
	
	Parent.HandleInstallModChanges()
EndFunction

; Called by HUDFramework
Function HUD_WidgetLoaded(string asWidgetName)
	; Do we want to do anything?
EndFunction


Function PrepareHUDFramework()
	if(Game.IsPluginInstalled("HUDFramework.esm") || Game.IsPluginInstalled("HUDFramework.esp"))
		bIsHUDFrameworkInstalled = true
		
		if(HudInstance == None)
			if(Game.IsPluginInstalled("HUDFramework.esm"))	
				HudInstance = Game.GetFormFromFile(0xF99, "HUDFramework.esm").CastAs("HUDFramework")
			elseif(Game.IsPluginInstalled("HUDFramework.esp"))
				HudInstance = Game.GetFormFromFile(0xF99, "HUDFramework.esp").CastAs("HUDFramework")
			endif
		endif
		
		; Clear out any orphaned widgets
		Var[] kArgs = new Var[0]
		HudInstance.CallFunction("ClearOrphanedRegistrations", kArgs)
		
		; Now update our RegisteredWidgets array
		String[] RemoveMe = new String[0]
		int i = 0
		while(i < RegisteredWidgets.Length)
			kArgs = new Var[1]
			kArgs[0] = RegisteredWidgets[i]
			Bool bIsActive = HudInstance.CallFunction("IsWidgetRegistered", kArgs) as Bool
			
			if( ! bIsActive)
				RemoveMe.Add(RegisteredWidgets[i])
			endif
			
			i += 1
		endWhile
		
		i = 0
		while(i < RemoveMe.Length)
			int iIndex = RegisteredWidgets.Find(RemoveMe[i])
			if(iIndex >= 0)
				RegisteredWidgets.Remove(iIndex)
			endif
			
			i += 1
		endWhile
	else
		bIsHUDFrameworkInstalled = false
		HudInstance = None
	endif
EndFunction


; Troubleshooting function for fixing stuck registrations
Function ResetWidgetRegistrations()
	; TODO - We also need a means to reset the HUDFramework quest in case it gets stuck, which you've seen happen once now. Unfortunately, starting and stopping it doesn't seem to fix anything.
	int i = 0
	while(i < RegisteredWidgets.Length)
		UnregisterWidget(RegisteredWidgets[i])
		
		i += 1
	endWhile
	
	RegisteredWidgets = new String[0]
EndFunction

; ----------------------------------
;
; Progress Bars
; 
; ----------------------------------

int iTestCount = 0
Function TestAddProgressBar()
	iTestCount += 1
	String sId = "ProgressBar" + iTestCount as String
	String sLabel = "Progress Bar " + iTestCount as String
	CreateProgressBar(Self, sId, sLabel, "WSFWIcons\\SimSettlementsSpinningIcon.swf")
	UpdateProgressBarPercentage(Self, sId, Utility.RandomInt(1, 100))
EndFunction


Function CreateProgressBar(Form akHandler, String asCustomIdentifier, String asInitialLabel, String asIconPath = "")
	int iLockKey = GetLock()
		
	if(iLockKey <= GENERICLOCK_KEY_NONE)
		ModTrace("[HUDFrameworkManager] CreateProgressBar: Unable to get lock!")
		
		return None
	endif
	
	ProgressBar thisBar
	int iIndex = -1
	if(RegisteredProgressBars == None || RegisteredProgressBars.Length == 0)
		RegisteredProgressBars = new ProgressBar[0]
	else
		; Check if progress bar already exists
		iIndex = FindProgressBar(akHandler, asCustomIdentifier)
		if(iIndex >= 0)
			thisBar = RegisteredProgressBars[iIndex]
		endif
	endif
	
	if(iIndex < 0)
		; Create new entry
		thisBar = new ProgressBar
		thisBar.Source = akHandler
		thisBar.sSourceID = asCustomIdentifier
		thisBar.sLabel = asInitialLabel
		thisBar.sIconPath = asIconPath
		thisBar.fValue = 0.0
		thisBar.fLastUpdated = Utility.GetCurrentGameTime()
		thisBar.iBarIndex = NextProgressBarID
		
		RegisteredProgressBars.Add(thisBar)
	endif
	
	; Send Progress Bar to HUDFramework
	SendMessageString(sWSFWWidget_Framework, iCommand_AddProgressBar as String, thisBar.iBarIndex as String +  sDelimiter_CommandString + asInitialLabel + sDelimiter_CommandString + asIconPath, abReplaceExisting = false)
	
	if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
		ModTrace("[HUDFrameworkManager] CreateProgressBar: Failed to release lock " + iLockKey + "!")
	endif
EndFunction

Int Function FindProgressBar(Form akHandler, String asCustomIdentifier)
	int i = 0
	while(i < RegisteredProgressBars.Length)
		if(RegisteredProgressBars[i].Source == akHandler && RegisteredProgressBars[i].sSourceID == asCustomIdentifier)
			return i
		endif
		
		i += 1
	endWhile
	
	return -1
EndFunction

Function CompleteProgressBar(Form akHandler, String asCustomIdentifier)
	int iLockKey = GetLock()
		
	if(iLockKey <= GENERICLOCK_KEY_NONE)
		ModTrace("[HUDFrameworkManager] CompleteProgressBar: Unable to get lock!")
		
		return None
	endif
	
	; Remove from array and hide
	Int iIndex = FindProgressBar(akHandler, asCustomIdentifier)
	
	if(iIndex >= 0)	
		SendMessage(sWSFWWidget_Framework, iCommand_HideProgressBar, RegisteredProgressBars[iIndex].iBarIndex)
		
		RegisteredProgressBars.Remove(iIndex)
	endif
	
	if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
		ModTrace("[HUDFrameworkManager] CompleteProgressBar: Failed to release lock " + iLockKey + "!")
	endif
EndFunction

Function ForceCloseAllProgressBars()
	int i = RegisteredProgressBars.Length - 1
	while(i >= 0)
		CompleteProgressBar(RegisteredProgressBars[i].Source, RegisteredProgressBars[i].sSourceID)
		
		i -= 1
	endWhile
EndFunction

Function UpdateProgressBarPercentage(Form akHandler, String asCustomIdentifier, Int aiNewValue)
	if(aiNewValue > 100)
		aiNewValue = 100
	elseif(aiNewValue < 0)
		aiNewValue = 0
	endif
	
	Int iIndex = FindProgressBar(akHandler, asCustomIdentifier)
	
	if(iIndex >= 0)		
		if(RegisteredProgressBars[iIndex].fValue != aiNewValue as Float)
			; Value updated, send to HUDFramework
			SendMessage(sWSFWWidget_Framework, iCommand_UpdateProgressBar, RegisteredProgressBars[iIndex].iBarIndex, aiNewValue)
		endif
		
		; Update our record
		RegisteredProgressBars[iIndex].fValue = aiNewValue
		RegisteredProgressBars[iIndex].fLastUpdated = Utility.GetCurrentGameTime()
	endif
EndFunction

Function UpdateProgressBarData(Form akHandler, String asCustomIdentifier, String asUpdateLabel, String asIconPath = "", Bool abForceUpdate = false)
	int iLockKey = GetLock()
		
	if(iLockKey <= GENERICLOCK_KEY_NONE)
		ModTrace("[HUDFrameworkManager] UpdateProgressBarData: Unable to get lock!")
		
		return None
	endif
	
	Int iIndex = FindProgressBar(akHandler, asCustomIdentifier)
	
	if(iIndex >= 0)
		if(abForceUpdate || RegisteredProgressBars[iIndex].sLabel != asUpdateLabel || RegisteredProgressBars[iIndex].sIconPath != asIconPath)
			; Value updated, send to HUDFramework
			SendMessageString(sWSFWWidget_Framework, iCommand_AddProgressBar as String, RegisteredProgressBars[iIndex].iBarIndex as String + sDelimiter_CommandString + asUpdateLabel + sDelimiter_CommandString + asIconPath, abReplaceExisting = false)
		endif
		
		; Update our record
		RegisteredProgressBars[iIndex].sLabel = asUpdateLabel
		RegisteredProgressBars[iIndex].sIconPath = asIconPath
		RegisteredProgressBars[iIndex].fLastUpdated = Utility.GetCurrentGameTime()
	endif
	
	if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
		ModTrace("[HUDFrameworkManager] UpdateProgressBarData: Failed to release lock " + iLockKey + "!")
	endif
EndFunction




; ----------------------------------
;
; HUDFramework Wrappers
; 
; ----------------------------------

Bool Function RegisterWidget(ScriptObject akHandler, String asWidgetName, Float afPositionX, Float afPositionY, Bool abLoadNow = true, Bool abAutoLoad = true)
	if( ! IsHUDFrameworkInstalled || ! IsRunning()) ; 1.0.5 - Needs HF to continue
		return false
	endif
	
	if(RegisteredWidgets == None)
		RegisteredWidgets = new String[0]
	endif
	
	if(RegisteredWidgets.Find(asWidgetName) < 0)
		ModTrace("[WSFW] HUDFrameworkManager: Registering Widget: " + asWidgetName)
		
		Var[] kArgs = new Var[6]
		kArgs[0] = akHandler
		kArgs[1] = asWidgetName
		kArgs[2] = afPositionX
		kArgs[3] = afPositionY
		kArgs[4] = abLoadNow
		kArgs[5] = abAutoLoad
		
		HudInstance.CallFunction("RegisterWidget", kArgs)
		
		; Confirm that it registered - experience with this in the past is that early calls can fail before HUDFramework has finished initializing
		kArgs = new Var[1]
		kArgs[0] = asWidgetName
		Var WidgetCheck = HudInstance.CallFunction("GetWidgetByID", kArgs)
		if( ! WidgetCheck)
			Utility.Wait(2.0)
			
			; Try again
			return RegisterWidget(akHandler, asWidgetName, afPositionX, afPositionY, abLoadNow, abAutoLoad)
		else
			RegisteredWidgets.Add(asWidgetName)		
			
			return true
		endif
	else
		ModTrace(asWidgetName + " already in RegisteredWidgets array.")
		
		return true
	endif
EndFunction


Function UnregisterWidget(String asWidgetName)
	if( ! IsHUDFrameworkInstalled) ; 1.0.5 - Needs HF to continue
		return 
	endif
	
	int index = RegisteredWidgets.Find(asWidgetName)
	
	if(index > -1)
		RegisteredWidgets.Remove(index)		
	endif
	
	Var[] kArgs = new Var[1]
	kArgs[0] = asWidgetName
	
	HudInstance.CallFunction("UnregisterWidget", kArgs)
EndFunction


Bool Function IsWidgetLoaded(String asWidgetName)
	if( ! IsHUDFrameworkInstalled) ; 1.0.5 - Needs HF to continue
		return false
	endif
	
	if(RegisteredWidgets.Find(asWidgetName) < 0)
		ModTrace("[WSFW] Widget " + asWidgetName + " it is not registered yet.")
		return false
	endif
	
	Var[] kArgs = new Var[1]
	kArgs[0] = asWidgetName
	
	return HudInstance.CallFunction("IsWidgetLoaded", kArgs) as Bool
EndFunction


Function LoadWidget(String asWidgetName)
	if( ! IsHUDFrameworkInstalled) ; 1.0.5 - Needs HF to continue
		return 
	endif
	
	if(RegisteredWidgets.Find(asWidgetName) < 0)
		ModTrace("[WSFW] Unable to load widget " + asWidgetName + ", it is not registered yet.")
		return
	endif
	
	Var[] kArgs = new Var[1]
	kArgs[0] = asWidgetName
	
	HudInstance.CallFunction("LoadWidget", kArgs)
EndFunction


Function UnloadWidget(String asWidgetName)
	if( ! IsHUDFrameworkInstalled) ; 1.0.5 - Needs HF to continue
		return 
	endif
	
	if(RegisteredWidgets.Find(asWidgetName) < 0)
		ModTrace("[WSFW] Unable to unload widget " + asWidgetName + ", it is not registered yet.")
		return
	endif
	
	Var[] kArgs = new Var[1]
	kArgs[0] = asWidgetName
	
	HudInstance.CallFunction("UnloadWidget", kArgs)
EndFunction


Function SetWidgetPosition(String asWidgetName, Float afX, Float afY, Bool abTemporary = false)
	if( ! IsHUDFrameworkInstalled) ; 1.0.5 - Needs HF to continue
		return 
	endif
	
	if(RegisteredWidgets.Find(asWidgetName) < 0)
		ModTrace("[WSFW] Unable to send command to HUDFramework. Widget " + asWidgetName + " is not registered yet.")
		return
	endif
	
	Var[] Args = new Var[4]
	Args[0] = asWidgetName
	Args[1] = afX
	Args[2] = afY
	Args[3] = abTemporary
	
	HudInstance.CallFunction("SetWidgetPosition", Args)
EndFunction


Function ModWidgetPosition(String asWidgetName, Float afDeltaX = 0.0, Float afDeltaY = 0.0, Bool abTemporary = False)	
	if( ! IsHUDFrameworkInstalled) ; 1.0.5 - Needs HF to continue
		return 
	endif
	
	if(RegisteredWidgets.Find(asWidgetName) < 0)
		ModTrace("[WSFW] Unable to send command to HUDFramework. Widget " + asWidgetName + " is not registered yet.")
		return
	endif
	
	Var[] Args = new Var[4]
	Args[0] = asWidgetName
	Args[1] = afDeltaX
	Args[2] = afDeltaY
	Args[3] = abTemporary
	
	HudInstance.CallFunction("ModWidgetPosition", Args)
EndFunction


Float[] Function GetWidgetPosition(String asWidgetName)	
	if( ! IsHUDFrameworkInstalled) ; 1.0.5 - Needs HF to continue
		return None
	endif
	
	if(RegisteredWidgets.Find(asWidgetName) < 0)
		ModTrace("[WSFW] Unable to send command to HUDFramework. Widget " + asWidgetName + " is not registered yet.")
		return None
	endif
	
	; We can't use CallFunction here because it is unable to return an array
	return (HudInstance as HUDFramework).GetWidgetPosition(asWidgetName)
EndFunction



Function SetWidgetScale(String asWidgetName, Float afScaleX, Float afScaleY, Bool abTemporary = false)
	if( ! IsHUDFrameworkInstalled) ; 1.0.5 - Needs HF to continue
		return 
	endif
	
	if(RegisteredWidgets.Find(asWidgetName) < 0)
		ModTrace("[WSFW] Unable to send command to HUDFramework. Widget " + asWidgetName + " is not registered yet.")
		return
	endif
	
	Var[] Args = new Var[4]
	Args[0] = asWidgetName
	Args[1] = afScaleX
	Args[2] = afScaleY
	Args[3] = abTemporary
	
	HudInstance.CallFunction("SetWidgetScale", Args)
EndFunction


Function ModWidgetScale(String asWidgetName, Float afScaleX = 0.0, Float afScaleY = 0.0, Bool abTemporary = False)
	if( ! IsHUDFrameworkInstalled) ; 1.0.5 - Needs HF to continue
		return 
	endif
	
	if(RegisteredWidgets.Find(asWidgetName) < 0)
		ModTrace("[WSFW] Unable to send command to HUDFramework. Widget " + asWidgetName + " is not registered yet.")
		return
	endif
	
	Var[] Args = new Var[4]
	Args[0] = asWidgetName
	Args[1] = afScaleX
	Args[2] = afScaleY
	Args[3] = abTemporary
	
	HudInstance.CallFunction("ModWidgetScale", Args)
EndFunction


Float[] Function GetWidgetScale(String asWidgetName)	
	if(RegisteredWidgets.Find(asWidgetName) < 0)
		ModTrace("[WSFW] Unable to send command to HUDFramework. Widget " + asWidgetName + " is not registered yet.")
		return None
	endif
	
	; We can't use CallFunction here because it is unable to return an array
	return (HudInstance as HUDFramework).GetWidgetScale(asWidgetName)
EndFunction


Function SetWidgetOpacity(String asWidgetName, Float afOpacity = 1.0, Bool abTemporary = False)
	if( ! IsHUDFrameworkInstalled) ; 1.0.5 - Needs HF to continue
		return 
	endif
	
	if(RegisteredWidgets.Find(asWidgetName) < 0)
		ModTrace("[WSFW] Unable to send command to HUDFramework. Widget " + asWidgetName + " is not registered yet.")
		return
	endif
	
	Var[] Args = new Var[3]
	Args[0] = asWidgetName
	Args[1] = afOpacity
	Args[2] = abTemporary
	
	HudInstance.CallFunction("SetWidgetOpacity", Args)
EndFunction


Float Function GetWidgetOpacity(String asWidgetName)
	if( ! IsHUDFrameworkInstalled) ; 1.0.5 - Needs HF to continue
		return -1.0
	endif
	
	if(RegisteredWidgets.Find(asWidgetName) < 0)
		ModTrace("[WSFW] Unable to send command to HUDFramework. Widget " + asWidgetName + " is not registered yet.")
		return -1.0
	endif
	
	Var[] Args = new Var[1]
	Args[0] = asWidgetName
	
	return HudInstance.CallFunction("GetWidgetOpacity", Args) as Float
EndFunction



Function SendMessage(string asWidgetName, int aiCommand, float arg1 = 0.0, float arg2 = 0.0, \
    float arg3 = 0.0, float arg4 = 0.0, float arg5 = 0.0, float arg6 = 0.0)

	if( ! IsHUDFrameworkInstalled) ; 1.0.5 - Needs HF to continue
		return 
	endif
	
	if(RegisteredWidgets.Find(asWidgetName) < 0)
		ModTrace("[WSFW] Unable to send command to HUDFramework. Widget " + asWidgetName + " is not registered yet.")
		return
	endif
	
	Var[] Args = new Var[8]
	Args[0] = asWidgetName
	Args[1] = aiCommand
	Args[2] = arg1
	Args[3] = arg2
	Args[4] = arg3
	Args[5] = arg4
	Args[6] = arg5
	Args[7] = arg6
	
	HudInstance.CallFunction("SendMessage", Args)
EndFunction


Function SendCustomMessage(Message akMessageToSend, float arg1 = 0.0, float arg2 = 0.0, \
    float arg3 = 0.0, float arg4 = 0.0, float arg5 = 0.0, float arg6 = 0.0, float arg7 = 0.0, \
    float arg8 = 0.0, float arg9 = 0.0)
		
	if( ! IsHUDFrameworkInstalled) ; 1.0.5 - Needs HF to continue
		return 
	endif
	
	Var[] Args = new Var[10]
	Args[0] = akMessageToSend
	Args[1] = arg1
	Args[2] = arg2
	Args[3] = arg3
	Args[4] = arg4
	Args[5] = arg5
	Args[6] = arg6
	Args[7] = arg7
	Args[8] = arg8
	Args[9] = arg9
	
	HudInstance.CallFunction("SendCustomMessage", Args)
EndFunction


Function SendMessageString(string asWidgetName, string asCommand, string asBody, \
    bool abReplaceExisting = True, bool abDeferSend = False)
	
	if( ! IsHUDFrameworkInstalled) ; 1.0.5 - Needs HF to continue
		return 
	endif
	
	if(RegisteredWidgets.Find(asWidgetName) < 0)
		ModTrace("[WSFW] Unable to send command to HUDFramework. Widget " + asWidgetName + " is not registered yet.")
		return
	endif
	
	Var[] Args = new Var[5]
	Args[0] = asWidgetName
	Args[1] = asCommand
	Args[2] = asBody
	Args[3] = abReplaceExisting
	Args[4] = abDeferSend
	
	HudInstance.CallFunction("SendMessageString", Args)
EndFunction


Function Eval(string asExpression)
	if( ! IsHUDFrameworkInstalled) ; 1.0.5 - Needs HF to continue
		return 
	endif
	
	Var[] Args = new Var[1]
	Args[0] = asExpression
	
	HudInstance.CallFunction("Eval", Args)
EndFunction



; ---------------------------
;
; Display functions
;
; ---------------------------

Function NudgeWidget(String asWidgetName, Int aiDirection = 0, Float afAmount = 10.0)
	Float fDeltaX = 0.0
	Float fDeltaY = 0.0
	
	if(aiDirection == 0) ; Up
		fDeltaY = -1 * afAmount
	elseif(aiDirection == 1) ; Right
		fDeltaX = afAmount
	elseif(aiDirection == 2) ; Down
		fDeltaY = afAmount
	else ; Left
		fDeltaX = -1 * afAmount
	endif
	
	ModWidgetPosition(asWidgetName, fDeltaX, fDeltaY)	
EndFunction


Function NudgeWidgetScale(String asWidgetName, Float afAmount = 0.1)
	ModWidgetScale(asWidgetName, afAmount, afAmount)
EndFunction


Function ShowHUDWidgetsInWorkshopMode()
	if( ! IsHUDFrameworkInstalled) ; 1.0.5 - Needs HF to continue
		return 
	endif
	
	Var[] Args = new Var[5]
	Args[0] = "HUDFramework"
	Args[1] = "SwitchToPA"
	Args[2] = "1"
	Args[3] = true
	Args[4] = false
	
	HudInstance.CallFunction("SendMessageString", Args)
EndFunction


Function ResetWidget(String asWidgetName)
	; Tell HUDFramework to Unload/Load widget
	if( ! IsHUDFrameworkInstalled)
		return
	endif
	
	Var[] kArgs = new Var[1]
	kArgs[0] = asWidgetName
	
	HudInstance.CallFunction("UnloadWidget", kArgs)
	
	Utility.Wait(1.0)
	
	HudInstance.CallFunction("LoadWidget", kArgs)
EndFunction

Function ResetAllWidgets()
	int i = 0
	while(i < RegisteredWidgets.Length)
		ResetWidget(RegisteredWidgets[i])
		i += 1
	endWhile
EndFunction