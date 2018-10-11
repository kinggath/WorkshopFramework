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