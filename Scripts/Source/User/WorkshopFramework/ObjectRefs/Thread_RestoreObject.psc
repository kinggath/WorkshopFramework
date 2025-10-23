; ---------------------------------------------
; WorkshopFramework:ObjectRefs:Thread_RestoreObject.psc - by kinggath
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

Scriptname WorkshopFramework:ObjectRefs:Thread_RestoreObject extends WorkshopFramework:Library:ObjectRefs:Thread

import WorkshopFramework:Library:DataStructures
import WorkshopFramework:Library:UtilityFunctions

; -
; Consts
; -


; - 
; Editor Properties
; -
WorkshopFramework:PlaceObjectManager Property PlaceObjectManager Auto Const Mandatory
WorkshopFramework:MainThreadManager Property ThreadManager Auto Const Mandatory
WorkshopFramework:F4SEManager Property F4SEManager Auto Const Mandatory
Form Property PositionHelper Auto Const Mandatory

; -
; Properties
; -
WorkshopScript Property kWorkshopRef Auto Hidden
WorldObject Property RestoreObjectData Auto Hidden

ActorValueSet[] Property TagAVs Auto Hidden
Keyword[] Property TagKeywords Auto Hidden

; -
; Events
; -

; - 
; Functions 
; -
	
Function ReleaseObjectReferences()
	kWorkshopRef = None
EndFunction


Function RunCode()
	; Check if object already exists
	if(RestoreObjectData == None || kWorkshopRef == None)
		return
	endif
	
	ObjectReference kPositionHelper = kWorkshopRef.PlaceAtMe(PositionHelper)
	kPositionHelper.SetPosition(RestoreObjectData.fPosX, RestoreObjectData.fPosY, RestoreObjectData.fPosZ)
	
	Form BaseForm = GetWorldObjectForm(RestoreObjectData)
	
	ObjectReference kFoundRef = Game.FindClosestReferenceOfTypeFromRef(BaseForm, kPositionHelper, 5.0)
	
	;ModTrace("Thread_RestoreObject attempting to restore " + BaseForm)
	; If yes, can we restore it?
	Bool bCreateNew = true
	if(kFoundRef != None)
		ModTrace("    Found ref " + kFoundRef)
		
		if(kFoundRef.IsDisabled())
			;ModTrace("    Ref was disabled, let's re-enable it.")
			kFoundRef.Enable(false)
			
			Utility.Wait(0.01)
			
			if( ! kFoundRef.IsDisabled())
				bCreateNew = false
			endif
		else
			bCreateNew = false
		endif
		
		if( ! bCreateNew) ; This ref is good to go
			if(TagAVs != None)
				int i = 0
				while(i < TagAVs.Length)
					kFoundRef.SetValue(TagAVs[i].AVForm, TagAVs[i].fValue)
					
					i += 1
				endWhile
			endif
			
			if(TagKeywords != None)
				int i = 0
				while(i < TagKeywords.Length)
					kFoundRef.AddKeyword(TagKeywords[i])
					
					i += 1
				endWhile
			endif
		endif
	endif
	
	; Can't find or can't restore, build a new one
	if(bCreateNew)
		;ModTrace("    No ref found, creating new.")
		;Int iPlaceObjectCallbackID = PlaceObjectManager.CreateObject(RestoreObjectData, kWorkshopRef, abCallbackEventNeeded = false)
		
		WorkshopFramework:ObjectRefs:Thread_PlaceObject kThread = ThreadManager.CreateThread(GetPlaceObjectThread()) as WorkshopFramework:ObjectRefs:Thread_PlaceObject
			
		if(kThread)	
			kThread.bAutoDestroy = true
			
			if(TagAVs != None)
				int i = 0
				while(i < TagAVs.Length)
					kThread.AddTagAVSet(TagAVs[i].AVForm, TagAVs[i].fValue)
					
					i += 1
				endWhile
			endif
			
			if(TagKeywords != None)
				int i = 0
				while(i < TagKeywords.Length)
					kThread.AddTagKeyword(TagKeywords[i])
					
					i += 1
				endWhile
			endif
						
			kThread.bForceStatic = RestoreObjectData.bForceStatic
			kThread.kSpawnAt = Game.GetPlayer()
			kThread.SpawnMe = GetWorldObjectForm(RestoreObjectData)
			kThread.fPosX = RestoreObjectData.fPosX
			kThread.fPosY = RestoreObjectData.fPosY
			kThread.fPosZ = RestoreObjectData.fPosZ
			kThread.fAngleX = RestoreObjectData.fAngleX
			kThread.fAngleY = RestoreObjectData.fAngleY
			kThread.fAngleZ = RestoreObjectData.fAngleZ
			kThread.fScale = RestoreObjectData.fScale
			kThread.kWorkshopRef = kWorkshopRef
			kThread.bRequiresWorkshopOrWorldspace = true
			kThread.bRecalculateWorkshopResources = false ; We will just run this once when its done
			
			if( ! F4SEManager.IsF4SERunning || GetSetting_Import_FauxPowerItems().GetValueInt() == 1)
				kThread.bFauxPowered = true
			endif
		endif
	endif
EndFunction






Function AddTagAVSet(ActorValue aAV, Float afValue)
	ActorValueSet newSet = new ActorValueSet
	
	newSet.AVForm = aAV
	newSet.fValue = afValue
	
	if( ! TagAVs)
		TagAVs = new ActorValueSet[0]
	endif
	
	TagAVs.Add(newSet)
EndFunction

Function AddTagKeyword(Keyword aKeyword)
	if( ! TagKeywords)
		TagKeywords = new Keyword[0]
	endif
	
	TagKeywords.Add(aKeyword)
EndFunction


Form Function GetPlaceObjectThread()
	return Game.GetFormFromFile(0x00004CEB, "WorkshopFramework.esm")
EndFunction

GlobalVariable Function GetSetting_Import_FauxPowerItems()
	return Game.GetFormFromFile(0x000158D3, "WorkshopFramework.esm") as GlobalVariable
EndFunction