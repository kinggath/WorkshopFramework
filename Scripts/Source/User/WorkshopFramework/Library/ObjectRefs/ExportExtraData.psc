; ---------------------------------------------
; WorkshopFramework:Library:ObjectRefs:ExportExtraData.psc - by kinggath
; ---------------------------------------------
; Reusage Rights ------------------------------
; You are free to use this script or portions of it in your own mods, provided you give me credit in your description and maintain this section of comments in any released source code (which includes the IMPORTED SCRIPT CREDIT section to give credit to anyone in the associated Import scripts below).
; 
; Warning !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
; Do not directly recompile this script for redistribution without first renaming it to avoid compatibility issues with the mod this came from.
; 
; IMPORTED SCRIPT CREDITS
; N/A
; ---------------------------------------------

Scriptname WorkshopFramework:Library:ObjectRefs:ExportExtraData extends ObjectReference
{ Ensure this object gets tagged with an identifying string when exported as part of a layout }

import WorkshopFramework:Library:DataStructures
import WorkshopFramework:Library:UtilityFunctions

int iMaxNumbers = 3 Const
int iMaxStrings = 3 Const
int iMaxBools = 3 Const
int iMaxForms = 3 Const

Float[] Property ExtraNumbers Auto Const
{ Up to 3 numbers can be appended to the export data }
String[] Property ExtraStrings Auto Const
{ Up to 3 strings can be appended to the export data }
Bool[] Property ExtraBools Auto Const
{ Up to 3 bools can be appended to the export data }
UniversalForm[] Property ExtraForms Auto Const
{ Up to 3 forms can be appended to the export data }

; OnTriggerLeave used by WorkshopFramework to tell an object it is being exported
Event OnTriggerLeave(ObjectReference akActionRef)
	if(akActionRef as WorkshopFramework:ObjectRefs:Thread_ExportObjectData)
		WorkshopFramework:ObjectRefs:Thread_ExportObjectData kThreadRef = akActionRef as WorkshopFramework:ObjectRefs:Thread_ExportObjectData
		
		if(ExtraNumbers != None)
			int i = 0
			while(i < ExtraNumbers.Length && i < iMaxNumbers)
				kThreadRef.AddExtraData(ExtraNumbers[i])
				
				i += 1
			endWhile
		endif
		
		if(ExtraStrings != None)
			int i = 0
			while(i < ExtraStrings.Length && i < iMaxStrings)
				kThreadRef.AddExtraData(ExtraStrings[i])
				
				i += 1
			endWhile
		endif
		
		if(ExtraBools != None)
			int i = 0
			while(i < ExtraBools.Length && i < iMaxBools)
				kThreadRef.AddExtraData(ExtraBools[i])
				
				i += 1
			endWhile
		endif
		
		if(ExtraForms != None)
			int i = 0
			while(i < ExtraForms.Length && i < iMaxForms)
				Form thisForm = GetUniversalForm(ExtraForms[i])
				if(thisForm)
					kThreadRef.AddExtraData(thisForm)
				endif
				
				i += 1
			endWhile
		endif
	endif
EndEvent