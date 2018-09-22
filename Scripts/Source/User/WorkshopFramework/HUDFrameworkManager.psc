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

Scriptname WorkshopFramework:HUDFrameworkManager extends WorkshopFramework:Library:SlaveQuest
{ Interface for HUDFramework }


import WorkshopFramework:Library:UtilityFunctions

; ---------------------------------------------
; Consts
; ---------------------------------------------


; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------


; ---------------------------------------------
; Properties
; ---------------------------------------------

Bool bIsHUDFrameworkInstalled = false
Bool Property IsHUDFrameworkInstalled
	Bool Function Get()
		return bIsHUDFrameworkInstalled
	EndFunction
EndProperty



; ---------------------------------------------
; Vars
; ---------------------------------------------

ScriptObject HudInstance = None
String[] RegisteredWidgets


; ---------------------------------------------
; Events 
; ---------------------------------------------




; ---------------------------------------------
; Methods 
; ---------------------------------------------

Function HandleGameLoaded()
	Parent.HandleGameLoaded()
	
	PrepareHUDFramework()
	
	if(HudInstance == None || RegisteredWidgets == None)
		RegisteredWidgets = new String[0]
	endif
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


Bool Function RegisterWidget(ScriptObject akHandler, String asWidgetName, Float afPositionX, Float afPositionY, Bool abLoadNow = true, Bool abAutoLoad = true)
	if( ! IsHUDFrameworkInstalled)
		return false
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
	int index = RegisteredWidgets.Find(asWidgetName)
	
	if(index > -1)
		RegisteredWidgets.Remove(index)		
	endif
	
	Var[] kArgs = new Var[1]
	kArgs[0] = asWidgetName
	
	HudInstance.CallFunction("UnregisterWidget", kArgs)
EndFunction


Bool Function IsWidgetLoaded(String asWidgetName)
	if(RegisteredWidgets.Find(asWidgetName) < 0)
		ModTrace("[WSFW] Widget " + asWidgetName + " it is not registered yet.")
		return false
	endif
	
	Var[] kArgs = new Var[1]
	kArgs[0] = asWidgetName
	
	return HudInstance.CallFunction("IsWidgetLoaded", kArgs) as Bool
EndFunction


Function LoadWidget(String asWidgetName)
	if(RegisteredWidgets.Find(asWidgetName) < 0)
		ModTrace("[WSFW] Unable to load widget " + asWidgetName + ", it is not registered yet.")
		return
	endif
	
	Var[] kArgs = new Var[1]
	kArgs[0] = asWidgetName
	
	HudInstance.CallFunction("LoadWidget", kArgs)
EndFunction


Function UnloadWidget(String asWidgetName)
	if(RegisteredWidgets.Find(asWidgetName) < 0)
		ModTrace("[WSFW] Unable to unload widget " + asWidgetName + ", it is not registered yet.")
		return
	endif
	
	Var[] kArgs = new Var[1]
	kArgs[0] = asWidgetName
	
	HudInstance.CallFunction("UnloadWidget", kArgs)
EndFunction


Function SetWidgetPosition(String asWidgetName, Float afX, Float afY, Bool abTemporary = false)
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
	if(RegisteredWidgets.Find(asWidgetName) < 0)
		ModTrace("[WSFW] Unable to send command to HUDFramework. Widget " + asWidgetName + " is not registered yet.")
		return None
	endif
	
	; We can't use CallFunction here because it is unable to return an array
	return (HudInstance as HUDFramework).GetWidgetPosition(asWidgetName)
EndFunction



Function SetWidgetScale(String asWidgetName, Float afScaleX, Float afScaleY, Bool abTemporary = false)
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
		
	Var[] Args = new Var[11]
	Args[0] = akMessageToSend
	Args[1] = arg1
	Args[3] = arg2
	Args[4] = arg3
	Args[5] = arg4
	Args[6] = arg5
	Args[7] = arg6
	Args[8] = arg7
	Args[9] = arg8
	Args[10] = arg9
	
	HudInstance.CallFunction("SendCustomMessage", Args)
EndFunction


Function SendMessageString(string asWidgetName, string asCommand, string asBody, \
    bool abReplaceExisting = True, bool abDeferSend = False)
	
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
	Var[] Args = new Var[1]
	Args[0] = asExpression
	
	HudInstance.CallFunction("Eval", Args)
EndFunction



; ---------------------------
; Wrapper functions
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