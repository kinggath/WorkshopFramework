; ---------------------------------------------
; WorkshopFramework:Library:UtilityFunctions.psc - by kinggath
; ---------------------------------------------
; Reusage Rights ------------------------------
; You are free to use this script or portions of it in your own mods, provided you give me credit in your description and maintain this section of comments in any released source code (which includes the IMPORTED SCRIPT CREDIT section to give credit to anyone in the associated Import scripts below).
; 
; Warning !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
; Do not directly recompile this script for redistribution without first renaming it to avoid compatibility issues issues with the mod this came from.
; 
; IMPORTED SCRIPT CREDITS
; N/A
; ---------------------------------------------

Scriptname WorkshopFramework:Library:UtilityFunctions Hidden Const

import WorkshopFramework:Library:DataStructures


Function StartUserLog() global DebugOnly
	String sDebugLog = "WorkshopFrameworkLog"
	
	Debug.OpenUserLog(sDebugLog)
EndFunction

Function ModTrace(string traceString, int severity = 0, bool bNormalTraceAlso = false) global DebugOnly
	String sDebugLog = "WorkshopFrameworkLog"
	
	; severity 0 = info; 1 = warning; 2 = error
	
	Debug.TraceUser(sDebugLog, " " + traceString, severity)
	
	if(bNormalTraceAlso)
		Debug.Trace("[WorkshopFrameworkLog]: " + traceString)
	endif
EndFunction	

; 1.0.4 - Adding custom log options
Function StartUserLogCustom(String asLogName) global DebugOnly
	Debug.OpenUserLog(asLogName)
EndFunction

Function ModTraceCustom(String asLogName, string traceString, int severity = 0, bool bNormalTraceAlso = false) global DebugOnly
	; severity 0 = info; 1 = warning; 2 = error
	
	Debug.TraceUser(asLogName, " " + traceString, severity)
	
	if(bNormalTraceAlso)
		Debug.Trace("[WorkshopFrameworkLog]: " + traceString)
	endif
EndFunction	


; -----------------------------------
; GetGameDate
;
; Version: Added 1.0.8
; 
; Description: returns an array of integers representing the in-game day/month/year
;
; Parameters:
; 
; fSpecificGameTime - [Optional] If != 0 this time will be used instead of the current in-game time. If you want to use the day the game starts - which would be 0.0 exactly, just use something like 0.01 which will still translate to the same date
;
; Returns:
; Array of ints - Int[0] = Year, Int[1] = Month, Int[2] = Day
; -----------------------------------

Int[] Function GetGameDate(Float fSpecificGameTime = 0.0) global
	if(fSpecificGameTime == 0.0)
		fSpecificGameTime = Utility.GetCurrentGameTime()
	endif
	
	; 0 = 10/22/2287
	Int iPrepassedGameDaysInYearOne = 294
	Int iYearOne = 2287
	Int iMonthOne = 10
	Int iDayOne = 21 
	
	Int[] iDaysPerMonth = new Int[12]
	iDaysPerMonth[0] = 31 ;Jan
	iDaysPerMonth[1] = 28 ;Feb
	iDaysPerMonth[2] = 31 ;Mar
	iDaysPerMonth[3] = 30 ;Apr
	iDaysPerMonth[4] = 31 ;May
	iDaysPerMonth[5] = 30 ;Jun
	iDaysPerMonth[6] = 31 ;Jul
	iDaysPerMonth[7] = 31 ;Aug
	iDaysPerMonth[8] = 30 ;Sep
	iDaysPerMonth[9] = 31 ;Oct
	iDaysPerMonth[10] = 30 ;Nov
	iDaysPerMonth[11] = 31 ;Dec
	
	
	Int iThisYear = iYearOne
	Int iThisMonth = iMonthOne
	Int iThisDay = iDayOne
	
	; Since we're just getting the date and the time is accessible via the GameHour global, we'll ceil the value
	Int iDaysSinceStart = Math.Ceiling(fSpecificGameTime)
	
	; Let's shortcut the years
	Int iYearsPassed = Math.Floor((iPrepassedGameDaysInYearOne as float + iDaysSinceStart as float)/365 as float)
	Float fYearsPassed = (iPrepassedGameDaysInYearOne as float + iDaysSinceStart as float)/365 as float
	
	iThisYear += iYearsPassed
	
	Int iLeapDaysPassed = CountLeapDays(iYearsPassed)

	Int iDaysRemaining = Math.Floor(((iDaysSinceStart as float/365 as float) - iYearsPassed) as Float * 365 as Float) - iLeapDaysPassed
	
	if(iDaysRemaining < 0) ; Leap years mean that our calculation using 365 was off
		iYearsPassed -= 1
		iDaysRemaining += 365
	endif
	
	while(iDaysRemaining > 0)
		iThisDay += 1
		
		int iDaysThisMonth = iDaysPerMonth[(iThisMonth - 1)]
		if(iThisMonth == 2 && (iThisYear as Float/4.0 == Math.Floor(iThisYear as Float/4.0)))
			iDaysThisMonth = 29
		endif		
		
		if(iThisDay > iDaysThisMonth)
			iThisDay = 1
			iThisMonth += 1
			
			if(iThisMonth > 12)
				iThisMonth = 1
				iThisYear += 1
			endif
		endif
		
		iDaysRemaining -= 1
	endWhile
	
	Int[] iGameDate = new Int[3]
	iGameDate[0] = iThisYear
	iGameDate[1] = iThisMonth
	iGameDate[2] = iThisDay
	
	return iGameDate
EndFunction

Int Function CountLeapDays(Int aiYearsPassed) global
	Int iFirstYear = 2287
	Int iFirstLeapYear = 2288
	
	Int iCurrentYear = iFirstYear + aiYearsPassed
	Int iLeapDays = 0
	
	if(iCurrentYear >= iFirstLeapYear)
		iLeapDays = 1
		
		iCurrentYear -= iFirstLeapYear
		
		while(iCurrentYear > 4)
			iLeapDays += 1
			iCurrentYear -= 4
		endWhile
	endif
	
	return iLeapDays
EndFunction


; -----------------------------------
; GetWorldObjectForm 
;
; Description: Returns the form from a WorkshopFramework:Library:DataStructures:WorldObject struct
; -----------------------------------

Form Function GetWorldObjectForm(WorldObject aObject, Int aiFormlistIndex = -1) global
	if( ! aObject)
		return None
	endif
	
	Form thisForm
	
	if(aObject.ObjectForm)
		thisForm = aObject.ObjectForm
	elseif(aObject.iFormID > 0 && aObject.sPluginName != "" && Game.IsPluginInstalled(aObject.sPluginName))
		thisForm = Game.GetFormFromFile(aObject.iFormID, aObject.sPluginName)
	else
		return None
	endif
	
	Formlist asFormlist = thisForm as FormList
	if(asFormlist)
		Bool bUseRandom = true
		
		if(aiFormlistIndex >= 0)
			if(asFormlist.GetSize() > aiFormlistIndex)
				thisForm = asFormlist.GetAt(aiFormlistIndex)
				bUseRandom = false
			endif
		endif
		
		if(bUseRandom)
			thisForm = asFormlist.GetAt(Utility.RandomInt(0, asFormlist.GetSize() - 1))
		endif
	endif
	
	return thisForm
EndFunction


; -----------------------------------
; GetUniversalForm 
;
; Description: Returns the form from a WorkshopFramework:Library:DataStructures:UniversalForm  ableSet struct
;
; Added: 1.0.4
; -----------------------------------

Form Function GetUniversalForm(UniversalForm aUniversalForm) global
	if( ! aUniversalForm)
		return None
	endif
	
	Form thisForm
	
	if(aUniversalForm.BaseForm)
		thisForm = aUniversalForm.BaseForm
	elseif(aUniversalForm.iFormID > 0 && aUniversalForm.sPluginName != "" && Game.IsPluginInstalled(aUniversalForm.sPluginName))
		thisForm = Game.GetFormFromFile(aUniversalForm.iFormID, aUniversalForm.sPluginName) as Form
	else
		return None
	endif
	
	return thisForm
EndFunction


; -----------------------------------
; GetActorValueSetForm 
;
; Description: Returns the form from a WorkshopFramework:Library:DataStructures:ActorValueSet struct
; -----------------------------------

ActorValue Function GetActorValueSetForm(ActorValueSet aAVSet) global
	if( ! aAVSet)
		return None
	endif
	
	ActorValue thisForm
	
	if(aAVSet.AVForm)
		thisForm = aAVSet.AVForm
	elseif(aAVSet.iFormID > 0 && aAVSet.sPluginName != "" && Game.IsPluginInstalled(aAVSet.sPluginName))
		thisForm = Game.GetFormFromFile(aAVSet.iFormID, aAVSet.sPluginName) as ActorValue
	else
		return None
	endif
	
	return thisForm
EndFunction


; -----------------------------------
; CheckActorValueSet
; 
; Description: Checks if a ActorValueSet passes
;
; Parameters:
; ObjectReference akCheckRef = The object ref to check the actorvalue on
; ActorValueSet aAVSet = ActorValueSet to evaluate against
; Bool abForceReenable = If true, and akCheckRef is disabled, it will temporarily re-enable it so it can test the values, otherwise, if disabled, it will fail the check
;
; Added: 1.0.4
; -----------------------------------

Bool Function CheckActorValueSet(ObjectReference akCheckRef, ActorValueSet aAVSet, Bool abForceReenable = false) global
	if( ! akCheckRef)
		return false 
	endif
	
	Bool bCheckPassed = false
	Bool bTemporarilyEnabled = false
	
	ActorValue thisForm = GetActorValueSetForm(aAVSet)
	
	if(thisForm)
		if(akCheckRef.IsDisabled())
			; All values will come back 0 on a disabled object
			if(abForceReenable)
				akCheckRef.Enable(false)
				
				bTemporarilyEnabled = true
			else
				return false
			endif
		endif
	
		Float fFormValue = akCheckRef.GetValue(thisForm)
		Float fCheckValue = aAVSet.fValue
		
		if(aAVSet.iCompareMethod == -2)
			if(fFormValue < fCheckValue)
				bCheckPassed = true
			endif
		elseif(aAVSet.iCompareMethod == -1)
			if(fFormValue <= fCheckValue)
				bCheckPassed = true
			endif
		elseif(aAVSet.iCompareMethod == 0)
			if(fFormValue == fCheckValue)
				bCheckPassed = true
			endif
		elseif(aAVSet.iCompareMethod == 1)
			if(fFormValue >= fCheckValue)
				bCheckPassed = true
			endif
		elseif(aAVSet.iCompareMethod == 2)
			if(fFormValue > fCheckValue)
				bCheckPassed = true
			endif
		endif				
	endif
	
	if(bTemporarilyEnabled)
		akCheckRef.Disable(false)
	endif
	
	return bCheckPassed
EndFunction


; -----------------------------------
; GetGlobalVariableSetForm 
;
; Description: Returns the form from a WorkshopFramework:Library:DataStructures:GlobalVariableSet struct
;
; Added: 1.0.4
; -----------------------------------

GlobalVariable Function GetGlobalVariableSetForm(GlobalVariableSet aGlobalSet) global
	if( ! aGlobalSet)
		return None
	endif
	
	GlobalVariable thisForm
	
	if(aGlobalSet.GlobalForm)
		thisForm = aGlobalSet.GlobalForm
	elseif(aGlobalSet.iFormID > 0 && aGlobalSet.sPluginName != "" && Game.IsPluginInstalled(aGlobalSet.sPluginName))
		thisForm = Game.GetFormFromFile(aGlobalSet.iFormID, aGlobalSet.sPluginName) as GlobalVariable
	else
		return None
	endif
	
	return thisForm
EndFunction


; -----------------------------------
; CheckGlobalVariableSet
; 
; Description: Checks if a GlobalVariableSet passes
;
; Added: 1.0.4
; -----------------------------------

Bool Function CheckGlobalVariableSet(GlobalVariableSet aGlobalSet) global
	GlobalVariable thisForm = GetGlobalVariableSetForm(aGlobalSet)
	
	if(thisForm)
		Float fFormValue = thisForm.GetValue()
		Float fCheckValue = aGlobalSet.fValue
		
		if(aGlobalSet.iCompareMethod == -2)
			if(fFormValue < fCheckValue)
				return true
			endif
		elseif(aGlobalSet.iCompareMethod == -1)
			if(fFormValue <= fCheckValue)
				return true
			endif
		elseif(aGlobalSet.iCompareMethod == 0)
			if(fFormValue == fCheckValue)
				return true
			endif
		elseif(aGlobalSet.iCompareMethod == 1)
			if(fFormValue >= fCheckValue)
				return true
			endif
		elseif(aGlobalSet.iCompareMethod == 2)
			if(fFormValue > fCheckValue)
				return true
			endif
		endif				
	endif
	
	; Global not found
	return false
EndFunction


; -----------------------------------
; GetQuestStageSetForm 
;
; Description: Returns the form from a WorkshopFramework:Library:DataStructures:QuestStageSet struct
;
; Added: 1.0.4
; -----------------------------------

Quest Function GetQuestStageSetForm(QuestStageSet aQuestSet) global
	if( ! aQuestSet)
		return None
	endif
	
	Quest thisForm
	
	if(aQuestSet.QuestForm)
		thisForm = aQuestSet.QuestForm
	elseif(aQuestSet.iFormID > 0 && aQuestSet.sPluginName != "" && Game.IsPluginInstalled(aQuestSet.sPluginName))
		thisForm = Game.GetFormFromFile(aQuestSet.iFormID, aQuestSet.sPluginName) as Quest
	else
		return None
	endif
	
	return thisForm
EndFunction


; -----------------------------------
; GetQuestObjectiveSetForm 
;
; Description: Returns the form from a WorkshopFramework:Library:DataStructures:QuestStageSet struct
;
; Added: 1.1.12
; -----------------------------------

Quest Function GetQuestObjectiveSetForm(QuestObjectiveSet aQuestSet) global
	if( ! aQuestSet)
		return None
	endif
	
	Quest thisForm
	
	if(aQuestSet.QuestForm)
		thisForm = aQuestSet.QuestForm
	elseif(aQuestSet.iFormID > 0 && aQuestSet.sPluginName != "" && Game.IsPluginInstalled(aQuestSet.sPluginName))
		thisForm = Game.GetFormFromFile(aQuestSet.iFormID, aQuestSet.sPluginName) as Quest
	else
		return None
	endif
	
	return thisForm
EndFunction


; -----------------------------------
; CheckQuestStageSet
; 
; Description: Checks if a QuestStageSet passes
;
; Added: 1.0.4
; -----------------------------------

Bool Function CheckQuestStageSet(QuestStageSet aQuestSet) global
	Quest thisForm = GetQuestStageSetForm(aQuestSet)
	
	if(thisForm)
		bool bIsStageDone = thisForm.GetStageDone(aQuestSet.iStage)
		
		if(aQuestSet.bNotDoneCheck)
			return ! bIsStageDone ; Return the opposite as this check wants this stage to NOT be complete
		else
			return bIsStageDone
		endif
	endif
	
	; Quest not found
	return false
EndFunction



; -----------------------------------
; CheckQuestObjectiveSet
; 
; Description: Checks if a QuestObjectiveSet passes
;
; Added: 1.1.12
; -----------------------------------

Bool Function CheckQuestObjectiveSet(QuestObjectiveSet aQuestObjectiveSet) global
	Quest thisForm = GetQuestObjectiveSetForm(aQuestObjectiveSet)
	
	if(thisForm)
		if(aQuestObjectiveSet.iCompareMethod == -1)
			return thisForm.IsObjectiveFailed(aQuestObjectiveSet.iObjective)
		elseif(aQuestObjectiveSet.iCompareMethod == 0)
			return !thisForm.IsObjectiveFailed(aQuestObjectiveSet.iObjective) && !thisForm.IsObjectiveCompleted(aQuestObjectiveSet.iObjective)
		elseif(aQuestObjectiveSet.iCompareMethod == 1)
			return thisForm.IsObjectiveCompleted(aQuestObjectiveSet.iObjective)
		endif
	endif
	
	; Quest not found
	return false
EndFunction



; -----------------------------------
; SetAndRestoreActorValue
;
; Description: Sets an actor value and restores the current value to the max
;
; -----------------------------------
Function SetAndRestoreActorValue(ObjectReference akObjectRef, ActorValue someValue, Float afNewValue) global
	if(akObjectRef == NONE || someValue == NONE)
		return
	endif
	
    Float BaseValue = akObjectRef.GetBaseValue(someValue)
    Float CurrentValue = akObjectRef.GetValue(someValue)

    if(CurrentValue < BaseValue)
        akObjectRef.RestoreValue(someValue, BaseValue - CurrentValue)
    endif

    akObjectRef.SetValue(someValue, afNewValue)
EndFunction


; -----------------------------------
; ModifyActorValue
;
; Description: Adjust a value, increasing max if necessary
;
; -----------------------------------
Function ModifyActorValue(ObjectReference akObjectRef, ActorValue someValue, float afAdjustBy) global
	if(akObjectRef == NONE || someValue == NONE)
		return
	endif
	
	Float fCurrentValue = akObjectRef.GetValue(someValue)

	; don't mod value below 0
	Float fNewValue = math.Max(fCurrentValue + afAdjustBy, 0)
	
	SetAndRestoreActorValue(akObjectRef, someValue, fNewValue)
endFunction


; -----------------------------------
; CleanFormList
;
; Description: Removes all None elements from a form list
;
; Author: cadpnq
; -----------------------------------
Function CleanFormList(FormList f, int index = -1) global
  int i = 0
  Form element

  If (index == -1)
    bool dirty = False
    index = f.GetSize() - 1

    i = index
    While (i >= 0)
      element = f.GetAt(i)
      If (element == None)
        dirty = True
      EndIf

      i -= 1
    EndWhile

    If (dirty)
      CleanFormList(f, index)
    EndIf
  Else
    Form[] tmp = New Form[0]

    While ((i < 128) && (index >= 0))
      element = f.GetAt(index)
      If (element != None)
        tmp.Add(element)
        i += 1
      EndIf
      index -= 1
    EndWhile

    If (index == -1)
      f.Revert()
    Else
      CleanFormList(f, index)
    EndIf

    i = tmp.Length - 1
    While (i > -1)
      f.AddForm(tmp[i])
      i -= 1
    EndWhile
  EndIf
EndFunction


; ------------------------------
; IsModInstalled
;
; Description: Checks if a plugin is installed, including checking for alternate extension versions - provided a name without an extension is sent.
; 
; Parameters:
; String asBaseName: This should be the plugin file name without the extension. For example, to check for IDEK's Logistics Station, you would send "SimSettlements_IDEKsLogisticsStation", notice that there is no ".esp" or ".esl"
;
; Added: 1.0.4
; ------------------------------
Bool Function IsModInstalled(String asBaseName, Bool abAlsoCheckForESL = false, Bool abAlsoCheckForESM = false)
	if( ! abAlsoCheckForESL && ! abAlsoCheckForESM)
		return Game.IsPluginInstalled(asBaseName)
	else
		Bool bInstalled = Game.IsPluginInstalled(asBaseName + ".esp")
		
		if( ! bInstalled)
			if(abAlsoCheckForESL)
				bInstalled = Game.IsPluginInstalled(asBaseName + ".esl")
			endif
			
			if( ! bInstalled && abAlsoCheckForESM)
				bInstalled = Game.IsPluginInstalled(asBaseName + ".esm")
			endif
		endif
		
		return bInstalled
	endif
EndFunction


; ------------------------------
; CopyWorldObject 
; 
; Description: Creates a new copy of a WorldObject. This is useful due to the way structs and arrays are passed by reference, so that you don't edit the original copy, if you just want to tweak the data itself
;
; Parmeters:
; WorldObject aWorldObject: A WorldObject struct you want to make a copy of
; 
; Added: 1.0.7
; ------------------------------
WorldObject Function CopyWorldObject(WorldObject aWorldObject) global
	WorldObject newObject = new WorldObject
	
	newObject.ObjectForm = aWorldObject.ObjectForm
	newObject.iFormID = aWorldObject.iFormID
	newObject.sPluginName = aWorldObject.sPluginName
	newObject.fPosX = aWorldObject.fPosX
	newObject.fPosY = aWorldObject.fPosY
	newObject.fPosZ = aWorldObject.fPosZ
	newObject.fAngleX = aWorldObject.fAngleX
	newObject.fAngleY = aWorldObject.fAngleY
	newObject.fAngleZ = aWorldObject.fAngleZ
	newObject.fScale = aWorldObject.fScale
	newObject.bForceStatic = aWorldObject.bForceStatic
	
	return newObject
EndFunction


; ------------------------------
; RecordWorldObjectCoordinatesOnRef
;
; Description: Checks if a plugin is installed, including checking for alternate extension versions - provided a name without an extension is sent.
; 
; Parameters:
; WorldObject aWorldObject: A WorldObject struct you want the position/rotation data stored in the form of AVs on a reference. This would be useful for recalculating coordinates of the item later on, especially after it was moved.
;
; ObjectReference akObjectRef: The ref to store the data on
; 
; Added: 1.0.7
; ------------------------------
Function RecordWorldObjectCoordinatesOnRef(WorldObject aWorldObject, ObjectReference akObjectRef) global
	ActorValue PosX = Game.GetFormFromFile(0x00004502, "WorkshopFramework.esm") as ActorValue
	ActorValue PosY = Game.GetFormFromFile(0x00004503, "WorkshopFramework.esm") as ActorValue
	ActorValue PosZ = Game.GetFormFromFile(0x00004504, "WorkshopFramework.esm") as ActorValue
	ActorValue AngX = Game.GetFormFromFile(0x00004505, "WorkshopFramework.esm") as ActorValue
	ActorValue AngY = Game.GetFormFromFile(0x00004506, "WorkshopFramework.esm") as ActorValue
	ActorValue AngZ = Game.GetFormFromFile(0x00004507, "WorkshopFramework.esm") as ActorValue
	
	akObjectRef.SetValue(PosX, aWorldObject.fPosX)
	akObjectRef.SetValue(PosY, aWorldObject.fPosY)
	akObjectRef.SetValue(PosZ, aWorldObject.fPosZ)
	akObjectRef.SetValue(AngX, aWorldObject.fAngleX)
	akObjectRef.SetValue(AngY, aWorldObject.fAngleY)
	akObjectRef.SetValue(AngZ, aWorldObject.fAngleZ)
EndFunction

; ------------------------------
; GetWorldObjectCoordinatesFromRef
;
; Description: Checks if a plugin is installed, including checking for alternate extension versions - provided a name without an extension is sent.
; 
; Parameters:
; ObjectReference akObjectRef: The ref to pulled stored data from
; 
; Returns: Array of 6 floats, Arr[0] = posX, Arr[1] = posY, Arr[2] = posZ, Arr[3] = angX, Arr[4] = angY, Arr[5] = angZ
; 
; Added: 1.0.7
; ------------------------------
Float[] Function GetWorldObjectCoordinatesFromRef(ObjectReference akObjectRef) global
	ActorValue PosX = Game.GetFormFromFile(0x00004502, "WorkshopFramework.esm") as ActorValue
	ActorValue PosY = Game.GetFormFromFile(0x00004503, "WorkshopFramework.esm") as ActorValue
	ActorValue PosZ = Game.GetFormFromFile(0x00004504, "WorkshopFramework.esm") as ActorValue
	ActorValue AngX = Game.GetFormFromFile(0x00004505, "WorkshopFramework.esm") as ActorValue
	ActorValue AngY = Game.GetFormFromFile(0x00004506, "WorkshopFramework.esm") as ActorValue
	ActorValue AngZ = Game.GetFormFromFile(0x00004507, "WorkshopFramework.esm") as ActorValue
	
	Float[] Coordinates = new Float[6]
	
	Coordinates[0] = akObjectRef.GetValue(PosX)
	Coordinates[1] = akObjectRef.GetValue(PosY)
	Coordinates[2] = akObjectRef.GetValue(PosZ)
	Coordinates[3] = akObjectRef.GetValue(AngX)
	Coordinates[4] = akObjectRef.GetValue(AngY)
	Coordinates[5] = akObjectRef.GetValue(AngZ)
	
	return Coordinates
EndFunction