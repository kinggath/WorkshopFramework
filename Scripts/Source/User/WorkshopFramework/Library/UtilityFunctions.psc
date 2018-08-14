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


ObjectReference Function SpawnTestObject(ObjectReference akOriginRef, Form akSpawnMe, Keyword akLinkKeyword, Float fX, Float fY, Float fZ) global
	ObjectReference kTemp = akOriginRef.PlaceAtMe(akSpawnMe, 1, false, false)
	kTemp.SetLinkedRef(akOriginRef, akLinkKeyword)
	kTemp.SetPosition(fX, fY, fZ + 200)
	
	return kTemp
EndFunction


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