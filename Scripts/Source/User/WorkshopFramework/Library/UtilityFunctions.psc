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
	Int iDayOne = 22 
	
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
		thisForm = Game.GetFormFromFile(aUniversalForm.iFormID, aUniversalForm.sPluginName)
	else
		return None
	endif
	
	return thisForm
EndFunction


; -----------------------------------
; GetIndexMappedUniversalForm
;
; Description: Returns the form from a WorkshopFramework:Library:DataStructures:IndexMappedUniversalForm  ableSet struct
;
; Added: 1.2.0
; -----------------------------------

Form Function GetIndexMappedUniversalForm(IndexMappedUniversalForm aUniversalForm) global
	if( ! aUniversalForm)
		return None
	endif
	
	Form thisForm
	
	if(aUniversalForm.BaseForm)
		thisForm = aUniversalForm.BaseForm
	elseif(aUniversalForm.iFormID > 0 && aUniversalForm.sPluginName != "" && Game.IsPluginInstalled(aUniversalForm.sPluginName))
		thisForm = Game.GetFormFromFile(aUniversalForm.iFormID, aUniversalForm.sPluginName)
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
; GetKeywordDataSetForm 
;
; Description: Returns the form from a WorkshopFramework:Library:DataStructures:KeywordDataSet struct
; -----------------------------------

Keyword Function GetKeywordDataSetForm(KeywordDataSet aKWDSet) global
	if( ! aKWDSet)
		return None
	endif
	
	Keyword thisForm
	
	if(aKWDSet.KeywordForm)
		thisForm = aKWDSet.KeywordForm
	elseif(aKWDSet.iFormID > 0 && aKWDSet.sPluginName != "" && Game.IsPluginInstalled(aKWDSet.sPluginName))
		thisForm = Game.GetFormFromFile(aKWDSet.iFormID, aKWDSet.sPluginName) as Keyword
	else
		return None
	endif
	
	return thisForm
EndFunction


; -----------------------------------
; CheckKeywordDataSet
; 
; Description: Checks if a KeywordDataSet passes
;
; Parameters:
; Location akLocation = The location to check the keyword data on
; KeywordDataSet aKWDSet = KeywordDataSet to evaluate against
;
; Added: XXXX
; -----------------------------------

Bool Function CheckKeywordDataSet(Location akLocation, KeywordDataSet aKWDSet) global
	if( ! akLocation)
		return false 
	endif

	Keyword thisForm = GetKeywordDataSetForm(aKWDSet)
	
	if(thisForm)
		Float fFormValue = akLocation.GetKeywordData(thisForm)
		Float fCheckValue = aKWDSet.fValue
		
		if(aKWDSet.iCompareMethod == -3)
			if(fFormValue != fCheckValue)
				return true
			endif
		elseif(aKWDSet.iCompareMethod == -2)
			if(fFormValue < fCheckValue)
				return true
			endif
		elseif(aKWDSet.iCompareMethod == -1)
			if(fFormValue <= fCheckValue)
				return true
			endif
		elseif(aKWDSet.iCompareMethod == 0)
			if(fFormValue == fCheckValue)
				return true
			endif
		elseif(aKWDSet.iCompareMethod == 1)
			if(fFormValue >= fCheckValue)
				return true
			endif
		elseif(aKWDSet.iCompareMethod == 2)
			if(fFormValue > fCheckValue)
				return true
			endif
		endif				
	endif
	
	; Keyword not found
	return false
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
		
		if(aAVSet.iCompareMethod == -3)
			if(fFormValue != fCheckValue)
				bCheckPassed =  true
			endif
		elseif(aAVSet.iCompareMethod == -2)
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
; CheckForPlugin
; 
; Description: Checks if a plugin is installed, even if the plugin is available as multiple types
;
; Parameters:
; String asPluginBaseName = Plugin file name WITHOUT the extension
; Bool abAvailableAsESP = Whether or not to check for .esp
; Bool abAvailableAsESL = Whether or not to check for .esl
; Bool abAvailableAsESM = Whether or not to check for .esm
;
; Added: 1.1.11
; -----------------------------------

Bool Function CheckForPlugin(String asPluginBaseName, Bool abAvailableAsESP = true, Bool abAvailableAsESL = true, Bool abAvailableAsESM = true) global
	if(Game.IsPluginInstalled(asPluginBaseName)) ; Full name was used
		return true
	endif
	
	if( ! abAvailableAsESP && ! abAvailableAsESL && ! abAvailableAsESM)
		; This should never happen, so we'll just fall back and check for esp
		if(Game.IsPluginInstalled(asPluginBaseName + ".esp"))
			return true
		endif
	else
		if(abAvailableAsESP && Game.IsPluginInstalled(asPluginBaseName + ".esp"))
			return true
		endif
		
		if(abAvailableAsESL && Game.IsPluginInstalled(asPluginBaseName + ".esl"))
			return true
		endif
		
		if(abAvailableAsESM && Game.IsPluginInstalled(asPluginBaseName + ".esm"))
			return true
		endif
	endif
	
	return false
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
		
		if(aGlobalSet.iCompareMethod == -3)
			if(fFormValue != fCheckValue)
				return true
			endif
		elseif(aGlobalSet.iCompareMethod == -2)
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
; GetQuestObjectiveSetForm 
;
; Description: Returns the form from a WorkshopFramework:Library:DataStructures:QuestStageSet struct
;
; Added: 1.2.0
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
; CheckQuestObjectiveSet
; 
; Description: Checks if a QuestObjectiveSet passes
;
; Added: 1.2.0
; -----------------------------------

Bool Function CheckQuestObjectiveSet(QuestObjectiveSet aQuestObjectiveSet) global
	Quest thisForm = GetQuestObjectiveSetForm(aQuestObjectiveSet)

	if(thisForm)
		if(aQuestObjectiveSet.iCompareMethod == -1)
			return thisForm.IsObjectiveFailed(aQuestObjectiveSet.iObjective)
		elseif(aQuestObjectiveSet.iCompareMethod == 0)
			return ( ! thisForm.IsObjectiveFailed(aQuestObjectiveSet.iObjective) && ! thisForm.IsObjectiveCompleted(aQuestObjectiveSet.iObjective))
		elseif(aQuestObjectiveSet.iCompareMethod == 1)
			return thisForm.IsObjectiveCompleted(aQuestObjectiveSet.iObjective)
		endif
	endif

	; Quest not found
	return false
EndFunction


; -----------------------------------
; GetScriptPropertySetCheckForm 
;
; Description: Returns the form from a WorkshopFramework:Library:DataStructures:ScriptPropertySet struct
;
; Added: 1.2.0
; -----------------------------------

Form Function GetScriptPropertySetCheckForm(ScriptPropertySet aScriptPropertySet) global
	if( ! aScriptPropertySet)
		return None
	endif
	
	Form thisForm
	
	if(aScriptPropertySet.CheckForm)
		thisForm = aScriptPropertySet.CheckForm
	elseif(aScriptPropertySet.iCheckFormID > 0 && aScriptPropertySet.sCheckPluginName != "" && Game.IsPluginInstalled(aScriptPropertySet.sCheckPluginName))
		thisForm = Game.GetFormFromFile(aScriptPropertySet.iCheckFormID, aScriptPropertySet.sCheckPluginName)
	else
		return None
	endif
	
	return thisForm
EndFunction


; -----------------------------------
; GetScriptPropertySetMatchForm 
;
; Description: Returns the form from a WorkshopFramework:Library:DataStructures:ScriptPropertySet struct
;
; Added: 1.2.0
; -----------------------------------

Form Function GetScriptPropertySetMatchForm(ScriptPropertySet aScriptPropertySet) global
	if( ! aScriptPropertySet)
		return None
	endif
	
	Form thisForm
	
	if(aScriptPropertySet.MatchForm)
		thisForm = aScriptPropertySet.MatchForm
	elseif(aScriptPropertySet.iMatchFormID > 0 && aScriptPropertySet.sMatchPluginName != "" && Game.IsPluginInstalled(aScriptPropertySet.sMatchPluginName))
		thisForm = Game.GetFormFromFile(aScriptPropertySet.iMatchFormID, aScriptPropertySet.sMatchPluginName)
	else
		return None
	endif
	
	return thisForm
EndFunction


; -----------------------------------
; CheckScriptPropertySet
; 
; Description: Checks if a ScriptPropertySet passes
;
; Added: 1.2.0
; -----------------------------------

Bool Function CheckScriptPropertySet(ScriptPropertySet aScriptPropertySet) global
	Form thisForm = GetScriptPropertySetCheckForm(aScriptPropertySet)
	
	ScriptObject CastForm = thisForm.CastAs(aScriptPropertySet.sScriptName)
	
	if(CastForm && aScriptPropertySet.sPropertyName != "")
		Var vPropertyValue = CastForm.GetPropertyValue(aScriptPropertySet.sPropertyName)
		
		if(vPropertyValue is Bool)
			if(vPropertyValue as Bool == aScriptPropertySet.fValue as Bool)
				return true
			endif
		elseif(vPropertyValue is Int || vPropertyValue is Float)
			Float fPropertyValue = vPropertyValue as Float
			if(aScriptPropertySet.iCompareMethod == -3)
				if(fPropertyValue != aScriptPropertySet.fValue)
					return true
				endif
			elseif(aScriptPropertySet.iCompareMethod == -2)
				if(fPropertyValue < aScriptPropertySet.fValue)
					return true
				endif
			elseif(aScriptPropertySet.iCompareMethod == -1)
				if(fPropertyValue <= aScriptPropertySet.fValue)
					return true
				endif
			elseif(aScriptPropertySet.iCompareMethod == 0)
				if(fPropertyValue == aScriptPropertySet.fValue)
					return true
				endif
			elseif(aScriptPropertySet.iCompareMethod == 1)
				if(fPropertyValue >= aScriptPropertySet.fValue)
					return true
				endif
			elseif(aScriptPropertySet.iCompareMethod == 2)
				if(fPropertyValue > aScriptPropertySet.fValue)
					return true
				endif
			endif
		elseif(vPropertyValue is String)
			String sPropertyValue = vPropertyValue as String
			
			if(sPropertyValue == aScriptPropertySet.fValue)
				if(aScriptPropertySet.iCompareMethod == 0)
					return true
				endif
			else
				; String doesn't match - if iCompareMethod is not the default value of 0, the user wanted anything but the value they requested
				if(aScriptPropertySet.iCompareMethod != 0)
					return true
				endif
			endif
		elseif(vPropertyValue as Form)
			Form checkForm = vPropertyValue as Form
			Form matchForm = GetScriptPropertySetMatchForm(aScriptPropertySet)
			
			if(checkForm == matchForm)
				if(aScriptPropertySet.iCompareMethod == 0)
					return true
				endif
			else
				; Form doesn't match - if iCompareMethod is not the default value of 0, the user wanted anything but the value they requested
				if(aScriptPropertySet.iCompareMethod != 0)
					return true
				endif
			endif
		endif					
	endif
	
	; No match occurred (or important data was missing)
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
	
    Float fBaseValue = akObjectRef.GetBaseValue(someValue)
    Float fCurrentValue = akObjectRef.GetValue(someValue)

    if(fCurrentValue < fBaseValue)
        akObjectRef.RestoreValue(someValue, fBaseValue - fCurrentValue)
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
; Author: cadpnq, edits by kinggath
; -----------------------------------
Function CleanFormList(FormList f, int index = -1) global
	int i = 0
	Form element

	if(index == -1)
		bool bDirty = False
		index = f.GetSize() - 1

		i = index
		while(i >= 0 && ! bDirty)
			element = f.GetAt(i)
			if(element == None)
				bDirty = True
			endIf

			i -= 1
		endWhile

		if(bDirty)
			CleanFormList(f, index)
		endIf
	else
		form[] tmp = New Form[0]

		while((i < 128) && (index >= 0))
			element = f.GetAt(index)
			
			if(element != None)
				tmp.Add(element)
				
				i += 1
			endIf
			
			index -= 1
		endWhile

		if(index == -1)
			f.Revert()
		else
			CleanFormList(f, index)
		endIf

		i = tmp.Length - 1
		while(i > -1)
			f.AddForm(tmp[i])
			
			i -= 1
		endWhile
	endIf
endFunction


; -----------------------------------
; CleanFormListRecursively
;
; Description: Removes all None elements from a form list, also digs into subformlists
;
; Author: kinggath
; -----------------------------------
Function CleanFormListRecursively(FormList f, int index = -1) global
	int i = 0
	Form element

	if(index == -1)
		bool bDirty = False
		index = f.GetSize() - 1

		i = index
		while(i >= 0)
			element = f.GetAt(i)
			if(element == None)
				bDirty = True
			else
				Formlist asFormlist = element as FormList
				if(asFormlist)
					CleanFormListRecursively(asFormlist)
				endif
			endIf

			i -= 1
		endWhile

		if(bDirty)
			CleanFormListRecursively(f, index)
		endIf
	else
		form[] tmp = New Form[0]

		while((i < 128) && (index >= 0))
			element = f.GetAt(index)
			
			if(element != None)
				tmp.Add(element)
				
				i += 1
			endIf
			
			index -= 1
		endWhile

		if(index == -1)
			f.Revert()
		else
			CleanFormListRecursively(f, index)
		endIf

		i = tmp.Length - 1
		while(i > -1)
			f.AddForm(tmp[i])
			
			i -= 1
		endWhile
	endIf
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
; Parameters:
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


; ------------------------------
; AddFormlistItemsToContainer 
; 
; Description: Add items to a container from a formlist. Idea is to thread this via CallGlobalFunctionNoWait. See function ShowFormlistBarterSelectMenu in WorkshopFramework:UIManager for an example of usage
;
; Parameters:
; aFormlist, akContainerRef, iIndexStart, iEntries
; 
; Added: 2.0.0
; ------------------------------
Function AddFormlistItemsToContainer(Formlist aFormlist, ObjectReference akContainerRef, Int aiIndexStart = 0, Int iMaxEntriesToAdd = -1) global
	int iListSize = aFormlist.GetSize()
	
	if(iMaxEntriesToAdd < 0)
		iMaxEntriesToAdd = iListSize - aiIndexStart
	endif
	
	int i = aiIndexStart
	int iCounter = 0
	while(i < iListSize && iCounter < iMaxEntriesToAdd)
		iCounter += 1 ; Intentionally incrementing her instead of inside if(thisForm) 
		
		Form thisForm = aFormlist.GetAt(i)
		if(thisForm)
			akContainerRef.AddItem(thisForm)
		endif
		
		i += 1
	endWhile
EndFunction


; ------------------------------
; IsPlayerInFirstPerson 
; 
; Description: Returns true or false depending on whether the player is in 1st or 3rd person
; 
; Added: 2.0.0
; ------------------------------

Bool Function IsPlayerInFirstPerson() global
	return (Game.GetPlayer() as Actor).GetAnimationVariableBool("IsFirstPerson")
EndFunction

; ------------------------------
; IsPlayerInPipboyMenu 
; 
; Description: Returns true or false depending on whether the player is in the pipboy menu
; 
; Added: 2.0.1
; ------------------------------
Bool Function IsPlayerInPipboyMenu() global
	if(Game.GetPlayer().GetAnimationVariableInt("pipboyState") == 0)
		return true
	else
		return false
	endIf	
EndFunction


; ------------------------------
; RandomizeArray 
; 
; Description: Randomizes an array's order
; 			Warning - this is destructive to the array sent to this function, so be certain to catch
; 						the results. For example, SomeArray = RandomizeArray(SomeArray)
;
; Parameters:
; Var[] myArray
; 
; Added: 2.0.0
; ------------------------------

Var[] Function RandomizeArray(Var[] myArray) global
	Var[] TempArray = new Var[0]
	
	int i = 0
	while(myArray.Length > 0)
		int index = Utility.RandomInt(0, myArray.Length - 1)
		
		TempArray.Add(myArray[index])		
		myArray.Remove(index)
		
		i += 1
	endWhile

	return TempArray
EndFunction


; ------------------------------
; GenerateRandomizedIntegerRangeArray 
; 
; Description: Randomizes a range of integers into an array
;
; Parameters:
; Int iStart, Int iEnd
; 
; Added: 2.0.0
; ------------------------------

int[] Function GenerateRandomizedIntegerRangeArray(Int iStart, Int iEnd) global
	Int[] Indexes = new Int[0]
	Int[] ReturnIndexes = new Int[0]
	
	if(iStart > iEnd)
		return None
	endif
	
	while(iStart <= iEnd && Indexes.Length < 128)
		Indexes.Add(iStart)
		
		iStart += 1
	endWhile
	
	return RandomizeArray(Indexes as Var[]) As Int[]
EndFunction


; ------------------------------
; StoryEventHash 
; 
; Description: Hashes all parameters that would be sent to StoryEventManager to match like-requests
;
; Parameters:
; Keyword pkwdKeyword, Location plocLocation, ObjectReference pobjObject1, ObjectReference pobjObject2, Int pintValue1, Int pintValue2
; 
; Added: 2.0.8
; ------------------------------
String Function StoryEventHash(Keyword pkwdKeyword, Location plocLocation, ObjectReference pobjObject1, ObjectReference pobjObject2, Int pintValue1, Int pintValue2) Global
	string strHash = ""
	
	strHash += "k"
	If pkwdKeyword
		strHash += pkwdKeyword.GetFormID()
	Else
		strHash += "0"
	EndIf
	
	strHash += "l"
	If plocLocation
		strHash += plocLocation.GetFormID()
	Else
		strHash += "0"
	EndIf
	
	strHash += "o"
	If pobjObject1
		strHash += pobjObject1.GetFormID()
	Else
		strHash += "0"
	EndIf
	
	strHash += "o"
	If pobjObject2
		strHash += pobjObject2.GetFormID()
	Else
		strHash += "0"
	EndIf
	
	strHash += "v" + pintValue1 + "v" + pintValue2
	
	Return strHash
EndFunction 


; ------------------------------
; FilterFormArrayByKeyword 
; 
; Description: Takes an array of forms and returns an array of those with the keyword on them
;
; Parameters:
; Form[] aForms, Keyword aFilterKeyword
; 
; Added: 2.0.8
; ------------------------------
Form[] Function FilterFormArrayByKeyword(Form[] aForms, Keyword aFilterKeyword) global
	Form[] FilteredArray = new Form[0]
	int i = 0
	while(i < aForms.Length && FilteredArray.Length < 128)
		if(aForms[i].HasKeyword(aFilterKeyword))
			FilteredArray.Add(aForms[i])
		endif
		
		i += 1
	endWhile
	
	return FilteredArray
EndFunction


; ------------------------------
; FilterFormArrayByKeywordArray
; 
; Description: Takes an array of forms and returns an array of those with the keyword on them
;
; Parameters:
; Form[] aForms, Keyword[] aFilterKeywords, Bool abAnyMatch
; 
; Added: 2.0.17
; ------------------------------
Form[] Function FilterFormArrayByKeywordArray(Form[] aForms, Keyword[] aFilterKeywords, Bool abAnyMatch = false) global
	Form[] FilteredArray = new Form[0]
	int i = 0
	
	while(i < aForms.Length && FilteredArray.Length < 128)
		Bool bAdded = false
		Bool bAllMatch = true		
		Form thisForm = aForms[i]
		
		int j = 0
		while(j < aFilterKeywords.Length && ! bAdded && (bAllMatch || abAnyMatch))
			if(thisForm.HasKeyword(aFilterKeywords[j]))
				if(abAnyMatch)
					FilteredArray.Add(thisForm)
					bAdded = true
				endif
			else
				bAllMatch = false
			endif
			
			j += 1
		endWhile
		
		if(bAllMatch && ! bAdded)
			FilteredArray.Add(thisForm)
			bAdded = true
		endif
		
		i += 1
	endWhile
		
	return FilteredArray
EndFunction


; ------------------------------
; FilterFormlistByKeyword
; 
; Description: All forms WITHOUT the filter keyword will be removed from aFormlist.
;
; Parameters:
; Formlist aFormlist, Keyword aFilterKeyword
; 
; Added: 2.0.8
; ------------------------------
Formlist Function FilterFormlistByKeyword(Formlist aFormlist, Keyword aFilterKeyword) global	
	int i = aFormlist.GetSize() - 1
	while(i >= 0)
		Form thisForm = aFormlist.GetAt(i)
		if( ! thisForm.HasKeyword(aFilterKeyword))
			aFormlist.RemoveAddedForm(thisForm)
		endif
		
		i -= 1
	endWhile
EndFunction

; ------------------------------
; FilterFormlistByKeywordToArray
; 
; Description: Takes a formlist and returns an array of the forms in it with the keyword on them
;
; Parameters:
; Formlist aFormlist, Keyword aFilterKeyword
; 
; Added: 2.0.8
; ------------------------------
Form[] Function FilterFormlistByKeywordToArray(Formlist aFormlist, Keyword aFilterKeyword) global
	Form[] FilteredArray = new Form[0]
	int i = 0
	while(i < aFormlist.GetSize() && FilteredArray.Length < 128)
		Form thisForm = aFormlist.GetAt(i)
		if(thisForm.HasKeyword(aFilterKeyword))
			FilteredArray.Add(thisForm)
		endif
		
		i += 1
	endWhile
	
	return FilteredArray
EndFunction

; ------------------------------
; FilterFormlistByKeywordArrayToArray
; 
; Description: Takes a formlist and returns an array of the forms in it with the keywords on them. If abAnyMatch is true, a single matching keyword will include that form.
;
; Parameters:
; Formlist aFormlist, Keyword[] aFilterKeywords, abAnyMatch
; 
; Added: 2.0.17
; ------------------------------
Form[] Function FilterFormlistByKeywordArrayToArray(Formlist aFormlist, Keyword[] aFilterKeywords, Bool abAnyMatch = false) global
	Form[] FilteredArray = new Form[0]
	int i = 0
	
	while(i < aFormlist.GetSize() && FilteredArray.Length < 128)
		Bool bAdded = false
		Bool bAllMatch = true		
		Form thisForm = aFormlist.GetAt(i)
		
		int j = 0
		while(j < aFilterKeywords.Length && ! bAdded && (bAllMatch || abAnyMatch))
			if(thisForm.HasKeyword(aFilterKeywords[j]))
				if(abAnyMatch)
					FilteredArray.Add(thisForm)
					bAdded = true
				endif
			else
				bAllMatch = false
			endif
			
			j += 1
		endWhile
		
		if(bAllMatch && ! bAdded)
			FilteredArray.Add(thisForm)
			bAdded = true
		endif
		
		i += 1
	endWhile
		
	return FilteredArray
EndFunction

; ------------------------------
; FilterFormlistByKeywordToFormlist
; 
; Description: All forms in aFormlist with the filter keyword will be added to aTargetFormlist.
;
; Parameters:
; Formlist aFormlist, Keyword aFilterKeyword, Formlist aTargetFormlist
; 
; Added: 2.0.8
; ------------------------------
Function FilterFormlistByKeywordToFormlist(Formlist aFormlist, Keyword aFilterKeyword, Formlist aTargetFormlist) global
	int i = 0
		
	while(i < aFormlist.GetSize())
		Form thisForm = aFormlist.GetAt(i)
		if(thisForm.HasKeyword(aFilterKeyword))
			aTargetFormlist.AddForm(thisForm)
		endif
		
		i += 1
	endWhile
EndFunction

; ------------------------------
; FilterFormlistByKeywordArrayToFormlist
; 
; Description: All forms in aFormlist with the filter keywords will be added to aTargetFormlist. If abAnyMatch == true, then a single match will count.
;
; Parameters:
; Formlist aFormlist, Keyword[] aFilterKeywords, Formlist aTargetFormlist, Bool abAnyMatch
; 
; Added: 2.0.17
; ------------------------------
Function FilterFormlistByKeywordArrayToFormlist(Formlist aFormlist, Keyword[] aFilterKeywords, Formlist aTargetFormlist, Bool abAnyMatch = false) global
	int i = 0	
	
	while(i < aFormlist.GetSize())
		Form thisForm = aFormlist.GetAt(i)
		Bool bAdded = false
		Bool bAllMatch = true
		int j = 0
		while(j < aFilterKeywords.Length && ! bAdded && (bAllMatch || abAnyMatch))
			if(thisForm.HasKeyword(aFilterKeywords[j]))
				if(abAnyMatch)
					aTargetFormlist.AddForm(thisForm)
					bAdded = true
				endif
			else
				bAllMatch = false
			endif
			
			j += 1
		endWhile
		
		if(bAllMatch && ! bAdded)
			aTargetFormlist.AddForm(thisForm)
			bAdded = true
		endif
		
		i += 1
	endWhile
EndFunction


; ************************************
; Math
; ************************************

; ------------------------------
; Mod 
; 
; Description: Basic math function to find remainder
; NOTE:  This function is redundant, use the native Papyrus modulo operator (%) 
; instead as it is many, many times faster. Maintaining function for backwards compatibility.
; 	ie, These are functionally equivalent:
;	x = Mod( y, 16 )
;	x = y % 16
; See: https://www.creationkit.com/fallout4/index.php?title=Operator_Reference
; Parameters:
; Int a, Int b
; 
; Added: 1.2.0
; ------------------------------
Int Function Mod(Int a, Int b) global
	;/
	Float x = a / b
	Int y = Math.Floor( x )
	
	return a - (b * y)
	/;
	
	return a % b
EndFunction


; ************************************
; String
; ************************************

; ------------------------------
; HexDigit
; 
; Description: Return the hexidecimal digit of an integer in the range of 0-15, will return "*" if out of range
;
; Parameters:
; Int aiDigit
; 
; Author: 1000101
; Added: 2.0.11
; ------------------------------
String Function HexDigit( Int aiDigit ) Global

	If( aiDigit >= 0 )&&( aiDigit <= 9 )
		Return aiDigit As String

	ElseIf( aiDigit == 10 )
		Return "A"

	ElseIf( aiDigit == 11 )
		Return "B"

	ElseIf( aiDigit == 12 )
		Return "C"

	ElseIf( aiDigit == 13 )
		Return "D"

	ElseIf( aiDigit == 14 )
		Return "E"

	ElseIf( aiDigit == 15 )
		Return "F"

	EndIf

	Return "*"
EndFunction

; ------------------------------
; IntToHex
; 
; Description: Return the hexidecimal value of an integer
;
; Parameters:
; Int aiInt
; Int aiPadDigits = Number of digits to pad to (prefixing the result with zeros to fill), an Int is 32-bits so the longest resulting hexidecimal value will be eight (8) digits
; 
; Author: 1000101
; Added: 2.0.11
; ------------------------------
String Function IntToHex( Int aiInt, Int aiPadDigits = 0 ) Global

	String lsResult = ""
	Int liDigitCount = 0
	Int liDigit

	Bool lbApplyHighBitToFirst = False
	If( aiInt < 0 )
		; Remove the sign-bit (bit 31) for negative input forcing aiInt to be positive for the conversion loop
		aiInt += 0x80000000
		lbApplyHighBitToFirst = True
	EndIf

	While( aiInt > 0 )

		liDigit = aiInt % 16 ; liDigit = aiInt & 0xF
		If( aiInt < 16 )&&( lbApplyHighBitToFirst )
			; Re-add the sign-bit (bit 31) for the first digit if the input value was negative
			liDigit += 0x8
		EndIf

		aiInt = aiInt / 16 ; aiInt = aiInt >> 4

		lsResult = HexDigit( liDigit ) + lsResult

		liDigitCount += 1
	EndWhile

	If( aiPadDigits > 0 )&&( liDigitCount < aiPadDigits )
		Int liZerosToAdd = aiPadDigits - liDigitCount

		While( liZerosToAdd > 0 )
			lsResult = "0" + lsResult
			liZerosToAdd -= 1
		EndWhile

	EndIf

	Return lsResult
EndFunction


; ------------------------------
; GetWorkshopLocation
; 
; Description: Return the location record the settlement workshop is in
;
; Parameters:
; WorkshopScript akWorkshopRef
; ------------------------------
Location Function GetWorkshopLocation(WorkshopScript akWorkshopRef) global
	Location thisLocation = akWorkshopRef.myLocation
	if(thisLocation == None)
		thisLocation = akWorkshopRef.GetCurrentLocation()
	endif
	
	return thisLocation
EndFunction

; ------------------------------
; GetWorkshopWorldspace
; 
; Description: Return the worldspace record the settlement workshop is in
;
; Parameters:
; WorkshopScript akWorkshopRef
; ------------------------------
WorldSpace Function GetWorkshopWorldspace(WorkshopScript akWorkshopRef) global
    if(akWorkshopRef.isInInterior() && akWorkshopRef.myMapMarker)
        return akWorkshopRef.myMapMarker.GetWorldspace()
    endif

    return akWorkshopRef.GetWorldspace()
EndFunction


; ------------------------------
; ApplyScriptPropertyChange
; 
; Description: Uses SetPropertyValue on akTargetRef based on settings of aChange
;
; ------------------------------
Function ApplyScriptPropertyChange(ObjectReference akTargetRef, ScriptPropertyChange aChange, Bool abReverse = false) global
	if(akTargetRef == None || aChange == None || aChange.sPropertyToChange == "")
		return
	endif
	
	if(aChange.ValueToUse == 0)
		Bool bValue = aChange.ValueAsBool
		
		if(abReverse)
			bValue = ! bValue
		endif
		
		akTargetRef.SetPropertyValue(aChange.sPropertyToChange, bValue)
	elseif(aChange.ValueToUse == 1)
		Float fValue = aChange.ValueAsFloat
		
		if(abReverse)
			Float CurrentValue = akTargetRef.GetPropertyValue(aChange.sPropertyToChange) as Float
			
			fValue = CurrentValue - aChange.ValueAsFloat			
		endif
		
		akTargetRef.SetPropertyValue(aChange.sPropertyToChange, fValue)
	elseif(aChange.ValueToUse == 2)
		Int iValue = aChange.ValueAsInt
		
		if(abReverse)
			Int CurrentValue = akTargetRef.GetPropertyValue(aChange.sPropertyToChange) as Int
			
			iValue = CurrentValue - aChange.ValueAsInt			
		endif
		
		akTargetRef.SetPropertyValue(aChange.sPropertyToChange, iValue)
	elseif(aChange.ValueToUse == 3)
		String sValue = aChange.ValueAsString
		
		if(abReverse)
			sValue = aChange.ReverseStringValue
		endif
		
		akTargetRef.SetPropertyValue(aChange.sPropertyToChange, sValue)
	endif
EndFunction


; ------------------------------
; FormListToArray
; 
; Description: Straight copy of a FormList to an Array
;
; Parameters:
; Formlist akFLST
; ------------------------------
Form[] Function FormListToArray( FormList akFLST ) Global
    If( akFLST == None )
        Return None
    EndIf
    
    Int liIndex = akFLST.GetSize()
    If( liIndex > 128 )
        Return None
    EndIf
    
    Form[] lkResult = New Form[ liIndex ]
    While( liIndex > 0 )
        liIndex -= 1
        lkResult[ liIndex ] = akFLST.GetAt( liIndex )
    EndWhile
    
    Return lkResult
EndFunction


; ------------------------------
; ClearCollectionFromCollection
; 
; Removes all aliases from one collection from another collection
;
; Parameters:
; RefCollectionAlias aRemoveCollection, RefCollectionAlias aFromCollection
; ------------------------------

Function ClearCollectionFromCollection(RefCollectionAlias aRemoveCollection, RefCollectionAlias aFromCollection) global
	int i = 0
	while(i < aRemoveCollection.GetCount())
		ObjectReference thisRef = aRemoveCollection.GetAt(i)
		
		if(thisRef != None)
			aFromCollection.RemoveRef(thisRef)
		endIf
		
		i += 1
	endWhile
EndFunction

; ------------------------------
; WorkshopFromReferences
; 
; Determine which of the two references is a Workshop and return it
;
; Parameters:
; ObjectReference akObj1, akObj2
; ------------------------------
WorkshopScript Function WorkshopFromReferences( ObjectReference akObj1, ObjectReference akObj2 ) Global
	WorkshopScript lkWorkshop = akObj1 As WorkshopScript
	If( lkWorkshop == None )
		lkWorkshop = akObj2 As WorkshopScript
	EndIf
	Return lkWorkshop
EndFunction


; ------------------------------
; Safe_RemoveAllItems
; 
; Removes all items from akSourceContainer, optionally sending it to akTransferTo. There are a few differences between this and the vanilla RemoveAllItems function. Most importantly, this takes into account the max number of an item that can be safely added in one call and divides it across multiple calls of Safe_RemoveItem. This also adds the abSilent option, but at the expense of the abKeepOwnership option.
;
; Parameters:
; ObjectReference akSourceContainer = Container to remove from
; ObjectReference akTransferTo = (optional) Container to move items to
; bool abSilent = (optional) If true, will not post notifications about items being removed if akSourceContainer or akOtherContainer is the player
; ------------------------------

bool Function Safe_RemoveAllItems(ObjectReference akSourceContainer, ObjectReference akTransferTo = None, Bool abSilent = true) global
 	; setup to prevent possible infinite loop
	int iBreakCount = 0
	int iBreakCountMax = 0x7FFFFFFF	; max Papyrus int, 32 bit signed integer, which I assume is the max number of forms a Container can hold
	
    ; this will loop while akSourceContainer has inventory and our break condition is false
    while(akSourceContainer.GetItemCount(None) > 0 && iBreakCount < iBreakCountMax)
        ; we will individually move one BaseObject at a time...        
        ObjectReference kDropped = akSourceContainer.DropFirstObject(abInitiallyDisabled=true)
        
        ; make sure we have a valid ref
        if(kDropped != none)
			Form aBaseForm = kDropped.GetBaseObject()
			
			; done with object, put it back! - for items like ammo, when dropped from a container, 1 = the whole stack!
			akSourceContainer.AddItem(kDropped, 1, abSilent = true)
			Safe_RemoveItem(akSourceContainer, aBaseForm, aiCount = -1, abSilent = abSilent, akOtherContainer = akTransferTo) ; -1 = All of that item
        endif
		
		iBreakCount += 1
    endwhile
    
	return iBreakCount < iBreakCountMax
EndFunction

; ------------------------------
; Safe_RemoveItem
; 
; Removes aiCount of item akItemToRemove from akSourceContainer, optionally sending it to akOtherContainer. The difference between this and the vanilla RemoveItem function is that this takes into account the max number of an item that can be safely added in one call and divides it across multiple calls.
;
; Parameters:
; ObjectReference akSourceContainer = Container to remove from
; Form akItemToRemove = Item type to remove, can be anything RemoveItem function supports
; Int aiCount = (optional) Number to remove
; bool abSilent = (optional) If true, will not post notifications about items being removed if akSourceContainer or akOtherContainer is the player
; ObjectReference akOtherContainer = (optional) Container to move items to
; ------------------------------
bool Function Safe_RemoveItem(ObjectReference akSourceContainer, Form akItemToRemove, Int aiCount = 1, bool abSilent = false, ObjectReference akOtherContainer = None) global
	if(akItemToRemove == None || akSourceContainer == None)
        return false
    endif
    
	int	uint_16max = 0x0000FFFF	; max value for unsigned 16 bit integer
	int iRemainingToMove = aiCount
	int iContainerItemCount = akSourceContainer.GetItemCount(akItemToRemove)
	
	if(iRemainingToMove < 0 || iRemainingToMove > iContainerItemCount)
		; negative number = move all
		iRemainingToMove = iContainerItemCount
	endIf

	Int iMoveCount = uint_16max
	
	; setup to prevent possible infinite loop
	int iBreakCount = 0
	int iBreakCountMax = 0x7FFFFFFF	; max value for signed 32 bit integer
	
	while(iRemainingToMove > 0 && iBreakCount < iBreakCountMax)
		if(iRemainingToMove < uint_16max)
			iMoveCount = iRemainingToMove
		endif
		
		akSourceContainer.RemoveItem(akItemToRemove, iMoveCount, abSilent = abSilent, akOtherContainer = akOtherContainer)
		; RemoveItem(Form akItemToRemove, int aiCount = 1, bool abSilent = false, ObjectReference akOtherContainer = None)
		
		iRemainingToMove -= iMoveCount
		iBreakCount += 1
	endwhile
	
	return iBreakCount < iBreakCountMax
EndFunction


Bool Function IsTrap(ObjectReference akRef) global
	if(akRef as DoorChain)
		return true
	endif
	
	if(akRef as TrapBase)
		return true
	endif
	
	if(akRef as TrapCanChimes)
		return true
	endif
	 
	if(akRef as TrapTripwire)
		return true
	endif
	
	if(akRef as TrapMonkeyTriggerScript)
		return true
	endif
		
	if(akRef as TrapBreakableWalkway)
		return true
	endif
		
	if(akRef as TrapTrigTension)
		return true
	endif
		
	if(akRef as TrapBreakableSoundScript)
		return true
	endif
	
	return false
EndFunction


Bool Function IsValidForm(Form aFormToCheck) global
	if(aFormToCheck == None)
		return false
	endif
	
	if(aFormToCheck.GetFormID() == 0x00000000)
		return false
	endif
	
	if( ! aFormToCheck.IsBoundGameObjectAvailable())
		return false
	endif
	
	return true
EndFunction