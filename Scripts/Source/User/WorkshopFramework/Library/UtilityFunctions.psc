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


ActorValue Function GetActorValueSetForm(ActorValueSet aAVSet) global
	if( ! aAVSet)
		return None
	endif
	
	ActorValue thisAV
	
	if(aAVSet.AVForm)
		thisAV = aAVSet.AVForm
	elseif(aAVSet.iFormID > 0 && aAVSet.sPluginName != "" && Game.IsPluginInstalled(aAVSet.sPluginName))
		thisAV = Game.GetFormFromFile(aAVSet.iFormID, aAVSet.sPluginName) as ActorValue
	else
		return None
	endif
	
	return thisAV
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
; AdjustActorValue
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