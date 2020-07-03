; ---------------------------------------------
; WorkshopFramework:Weapons:SettlementLayout.psc - by kinggath
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

Scriptname WorkshopFramework:Weapons:SettlementLayout extends Form Const

import WorkshopFramework:Library:DataStructures
import WorkshopFramework:Library:UtilityFunctions

; Below were copied from SettlementLayoutManager and then converted to properties so extended classes can use them
String Property sRestoreObjectCallbackID = "WSFW_RestoreObject" Auto Const 
String Property sPlaceObjectCallbackID = "WSFW_PlaceObject" Auto Const 
String Property sScrapObjectCallbackID = "WSFW_ScrapObject" Auto Const 
Int Property iGroupType_WorkshopResources = 1 Auto Const 
Int Property iGroupType_NonResources = 2 Auto Const

Group GeneratedData
	UniversalForm Property WorkshopRef Auto Const Mandatory
	{ The object reference of the workshop workbench at the settlement this is for. }
	
	WorldObject[] Property VanillaObjectsToRestore Auto Const
	{ Objects from the vanilla settlement that are needed for the design }
	
	WorldObject[] Property VanillaObjectsToRemove Auto Const
	{ Vanilla objects that should be removed. }
	
	WorldObject[] Property WorkshopResources Auto Const
	{ Objects that generate resources for the settlement, such as crops. }
	
	WorldObject[] Property NonResourceObjects Auto Const
	{ Non-resource generating objects, such as static items. }
		
	PowerConnectionMap[] Property PowerConnections Auto Const
	
	Keyword Property TagKeyword Auto Const Mandatory
	{ Used to tag all items for linking back to this layer. }
	
	String[] Property sPluginsUsed Auto Const
	{ Plugins used in the design }
	
	Form[] Property PluginNameHolders Auto Const
	Form Property DesignerNameHolder Auto Const
	
	Message Property InformationMessage Auto Const
EndGroup

Group ExtraData
	IndexMappedUniversalForm[] Property ExtraData_Forms01 Auto Const
	IndexMappedUniversalForm[] Property ExtraData_Forms02 Auto Const
	IndexMappedUniversalForm[] Property ExtraData_Forms03 Auto Const
	
	IndexMappedNumber[] Property ExtraData_Numbers01 Auto Const
	IndexMappedNumber[] Property ExtraData_Numbers02 Auto Const
	IndexMappedNumber[] Property ExtraData_Numbers03 Auto Const
	
	IndexMappedString[] Property ExtraData_Strings01 Auto Const
	IndexMappedString[] Property ExtraData_Strings02 Auto Const
	IndexMappedString[] Property ExtraData_Strings03 Auto Const
	
	IndexMappedBool[] Property ExtraData_Bools01 Auto Const
	IndexMappedBool[] Property ExtraData_Bools02 Auto Const
	IndexMappedBool[] Property ExtraData_Bools03 Auto Const
EndGroup


; -------------------------------------
; Functions
; -------------------------------------

Function Add(WorkshopScript akWorkshopRef = None)
	; Defined as function for easy extension
	if(akWorkshopRef == None)
		akWorkshopRef = GetUniversalForm(WorkshopRef) as WorkshopScript
		
		if(akWorkshopRef == None)
			return
		endif
	endif
	
	; Add to array on workshop ref
	if(akWorkshopRef.AppliedLayouts.Find(Self) < 0)
		; Confirm all arrays are initialized
		if(akWorkshopRef.AppliedLayouts == None)
			akWorkshopRef.AppliedLayouts = new WorkshopFramework:Weapons:SettlementLayout[0]
		endif
		
		if(akWorkshopRef.LayoutScrappingComplete == None)
			akWorkshopRef.LayoutScrappingComplete = new Bool[0]
		endif
		
		if(akWorkshopRef.LayoutPlacementComplete == None)
			akWorkshopRef.LayoutPlacementComplete = new Bool[0]
		endif
		
		akWorkshopRef.AppliedLayouts.Add(Self)
		akWorkshopRef.LayoutScrappingComplete.Add(false)
		akWorkshopRef.LayoutPlacementComplete.Add(false)
	endif
EndFunction

Function Remove(WorkshopScript akWorkshopRef = None)
	; Defined as function for easy extension
	if(akWorkshopRef == None)
		akWorkshopRef = GetUniversalForm(WorkshopRef) as WorkshopScript
		
		if(akWorkshopRef == None)
			return
		endif
	endif
	
	int iIndex = akWorkshopRef.AppliedLayouts.Find(Self)
	if(iIndex >= 0)
		akWorkshopRef.AppliedLayouts.Remove(iIndex)
		akWorkshopRef.LayoutScrappingComplete.Remove(iIndex)
		akWorkshopRef.LayoutPlacementComplete.Remove(iIndex)
	endif
EndFunction


Int Function GetPredictedItemCount()
	return WorkshopResources.Length + NonResourceObjects.Length
EndFunction


Function RestoreVanillaObjects(WorkshopScript akWorkshopRef)
	if(akWorkshopRef == None)
		return
	endif
	
	WorkshopFramework:MainThreadManager ThreadManager = GetThreadManager()
	Form RestoreObjectThread = GetRestoreObjectThread()
	int i = 0
	while(i < VanillaObjectsToRestore.Length)
		WorkshopFramework:ObjectRefs:Thread_RestoreObject kThread = ThreadManager.CreateThread(RestoreObjectThread) as WorkshopFramework:ObjectRefs:Thread_RestoreObject

		if(kThread)
			kThread.kWorkshopRef = akWorkshopRef
			kThread.RestoreObjectData = CopyWorldObject(VanillaObjectsToRestore[i])
			
			if(RestoreVanillaObjectThreadLastCall(kThread))
				ThreadManager.QueueThread(kThread)
			endif
		endif
				
		i += 1
	endWhile
EndFunction

Bool Function RestoreVanillaObjectThreadLastCall(ObjectReference akThreadRef)
	; Chance for extension, could use this to cancel thread or even alter details before it proceeds
	return true
EndFunction


Int Function PlaceWorkshopResources(WorkshopScript akWorkshopRef, Int aiCustomCallbackID = -1, Bool abProtectFromScrapPhase = false)
	; Defining here instead of manager to allow extension
	return PlaceObjects(akWorkshopRef, iGroupType_WorkshopResources, aiCustomCallbackID, abProtectFromScrapPhase)
EndFunction


Int Function PlaceNonResourceObjects(WorkshopScript akWorkshopRef, Int aiCustomCallbackID = -1, Bool abProtectFromScrapPhase = false)
	; Defining here instead of manager to allow extension
	return PlaceObjects(akWorkshopRef, iGroupType_NonResources, aiCustomCallbackID, abProtectFromScrapPhase)
EndFunction


Int[] Function UpdateExtraDataIndexes(Int[] aiExtraDataIndexes = None, Int aiCurrentIndex = -1)
	if(aiExtraDataIndexes == None)
		aiExtraDataIndexes = new Int[25]
		
		int i = 1
		while(i < aiExtraDataIndexes.Length)
			; Alternate entries - the first will represent the object index found in extra data in the iIndex field, and the second will be the actual index from the extra data array it was found
			if(Mod(i, 2) == 1)
				aiExtraDataIndexes[i] = -1
			else
				aiExtraDataIndexes[i] = 0
			endif
			
			i += 1
		endWhile
	endif
	
	; Update called - we need to recalculate the lowest index
	aiExtraDataIndexes[0] = 100000
	
	if(ExtraData_Forms01 != None && aiExtraDataIndexes[2] < ExtraData_Forms01.Length)
		Bool bContinue = false
		
		while( ! bContinue)
			if(aiCurrentIndex > ExtraData_Forms01[aiExtraDataIndexes[2]].iIndex && aiExtraDataIndexes[2] < ExtraData_Forms01.Length - 1)
				; The current iterator is already past the index we were at, so increment this extra data counter so in the next chunk we grab the next IndexMapped iIndex field for testing against
				aiExtraDataIndexes[2] += 1
			else
				bContinue = true ; We have the next index queued or are at the end of the array
			endif
			
			; Our extra data counter is still within our length - update the iIndex we're storing
			aiExtraDataIndexes[1] = ExtraData_Forms01[aiExtraDataIndexes[2]].iIndex
		endWhile
	endif
	
	if(ExtraData_Forms02 != None && aiExtraDataIndexes[4] < ExtraData_Forms02.Length)
		Bool bContinue = false
		
		while( ! bContinue)
			if(aiCurrentIndex > ExtraData_Forms02[aiExtraDataIndexes[4]].iIndex && aiExtraDataIndexes[4] < ExtraData_Forms02.Length - 1)
				aiExtraDataIndexes[4] += 1
			else
				bContinue = true ; We have the next index queued or are at the end of the array
			endif
			
			aiExtraDataIndexes[3] = ExtraData_Forms02[aiExtraDataIndexes[4]].iIndex
		endWhile
	endif
	
	if(ExtraData_Forms03 != None && aiExtraDataIndexes[6] < ExtraData_Forms03.Length)
		Bool bContinue = false
		
		while( ! bContinue)
			if(aiCurrentIndex > ExtraData_Forms03[aiExtraDataIndexes[6]].iIndex && aiExtraDataIndexes[6] < ExtraData_Forms03.Length - 1)
				aiExtraDataIndexes[6] += 1
			else
				bContinue = true ; We have the next index queued or are at the end of the array
			endif
			
			aiExtraDataIndexes[5] = ExtraData_Forms03[aiExtraDataIndexes[6]].iIndex
		endWhile
	endif
	
	if(ExtraData_Numbers01 != None && aiExtraDataIndexes[8] < ExtraData_Numbers01.Length)
		Bool bContinue = false
		
		while( ! bContinue)
			if(aiCurrentIndex > ExtraData_Numbers01[aiExtraDataIndexes[8]].iIndex && aiExtraDataIndexes[8] < ExtraData_Numbers01.Length - 1)
				aiExtraDataIndexes[8] += 1
			else
				bContinue = true ; We have the next index queued or are at the end of the array
			endif
			
			aiExtraDataIndexes[7] = ExtraData_Numbers01[aiExtraDataIndexes[8]].iIndex
		endWhile
	endif
	
	if(ExtraData_Numbers02 != None && aiExtraDataIndexes[10] < ExtraData_Numbers02.Length)
		Bool bContinue = false
		
		while( ! bContinue)
			if(aiCurrentIndex > ExtraData_Numbers02[aiExtraDataIndexes[10]].iIndex && aiExtraDataIndexes[10] < ExtraData_Numbers02.Length - 1)
				aiExtraDataIndexes[10] += 1
			else
				bContinue = true ; We have the next index queued or are at the end of the array
			endif
			
			aiExtraDataIndexes[9] = ExtraData_Numbers02[aiExtraDataIndexes[10]].iIndex
		endWhile
	endif
	
	if(ExtraData_Numbers03 != None && aiExtraDataIndexes[12] < ExtraData_Numbers03.Length)
		Bool bContinue = false
		
		while( ! bContinue)
			if(aiCurrentIndex > ExtraData_Numbers03[aiExtraDataIndexes[12]].iIndex && aiExtraDataIndexes[12] < ExtraData_Numbers03.Length - 1)
				aiExtraDataIndexes[12] += 1
			else
				bContinue = true ; We have the next index queued or are at the end of the array
			endif
			
			aiExtraDataIndexes[11] = ExtraData_Numbers03[aiExtraDataIndexes[12]].iIndex
		endWhile
	endif
	
	if(ExtraData_Strings01 != None && aiExtraDataIndexes[14] < ExtraData_Strings01.Length)
		Bool bContinue = false
		
		while( ! bContinue)
			if(aiCurrentIndex > ExtraData_Strings01[aiExtraDataIndexes[14]].iIndex && aiExtraDataIndexes[14] < ExtraData_Strings01.Length - 1)
				aiExtraDataIndexes[14] += 1
			else
				bContinue = true ; We have the next index queued or are at the end of the array
			endif
			
			aiExtraDataIndexes[13] = ExtraData_Strings01[aiExtraDataIndexes[14]].iIndex
		endWhile
	endif
	
	if(ExtraData_Strings02 != None && aiExtraDataIndexes[16] < ExtraData_Strings02.Length)
		Bool bContinue = false
		
		while( ! bContinue)
			if(aiCurrentIndex > ExtraData_Strings02[aiExtraDataIndexes[16]].iIndex && aiExtraDataIndexes[16] < ExtraData_Strings02.Length - 1)
				aiExtraDataIndexes[16] += 1
			else
				bContinue = true ; We have the next index queued or are at the end of the array
			endif
			
			aiExtraDataIndexes[15] = ExtraData_Strings02[aiExtraDataIndexes[16]].iIndex
		endWhile
	endif
	
	if(ExtraData_Strings03 != None && aiExtraDataIndexes[18] < ExtraData_Strings03.Length)
		Bool bContinue = false
		
		while( ! bContinue)
			if(aiCurrentIndex > ExtraData_Strings03[aiExtraDataIndexes[18]].iIndex && aiExtraDataIndexes[18] < ExtraData_Strings03.Length - 1)
				aiExtraDataIndexes[18] += 1
			else
				bContinue = true ; We have the next index queued or are at the end of the array
			endif
			
			aiExtraDataIndexes[17] = ExtraData_Strings03[aiExtraDataIndexes[18]].iIndex
		endWhile
	endif
	
	if(ExtraData_Bools01 != None && aiExtraDataIndexes[20] < ExtraData_Bools01.Length)
		Bool bContinue = false
		
		while( ! bContinue)
			if(aiCurrentIndex > ExtraData_Bools01[aiExtraDataIndexes[20]].iIndex && aiExtraDataIndexes[20] < ExtraData_Bools01.Length - 1)
				aiExtraDataIndexes[20] += 1
			else
				bContinue = true ; We have the next index queued or are at the end of the array
			endif
			
			aiExtraDataIndexes[19] = ExtraData_Bools01[aiExtraDataIndexes[20]].iIndex
		endWhile
	endif
	
	if(ExtraData_Bools02 != None && aiExtraDataIndexes[22] < ExtraData_Bools02.Length)
		Bool bContinue = false
		
		while( ! bContinue)
			if(aiCurrentIndex > ExtraData_Bools02[aiExtraDataIndexes[22]].iIndex && aiExtraDataIndexes[22] < ExtraData_Bools02.Length - 1)
				aiExtraDataIndexes[22] += 1
			else
				bContinue = true ; We have the next index queued or are at the end of the array
			endif
			
			aiExtraDataIndexes[21] = ExtraData_Bools02[aiExtraDataIndexes[22]].iIndex
		endWhile
	endif
	
	if(ExtraData_Bools03 != None && aiExtraDataIndexes[24] < ExtraData_Bools03.Length)
		Bool bContinue = false
		
		while( ! bContinue)
			if(aiCurrentIndex > ExtraData_Bools03[aiExtraDataIndexes[24]].iIndex && aiExtraDataIndexes[24] < ExtraData_Bools03.Length - 1)
				aiExtraDataIndexes[24] += 1
			else
				bContinue = true ; We have the next index queued or are at the end of the array
			endif
			
			aiExtraDataIndexes[23] = ExtraData_Bools03[aiExtraDataIndexes[24]].iIndex
		endWhile
	endif
	
	; aiExtraDataIndexes[0] holds our lowest iIndex across the entire array, this will let us skip constantly checking every single item against the entire array of aiExtraDataIndexes
	; Find lowest index
	int i = 1
	while(i < aiExtraDataIndexes.Length)
		if(Mod(i, 2) == 1 && aiExtraDataIndexes[i] >= 0 && aiExtraDataIndexes[i] < aiExtraDataIndexes[0])
			aiExtraDataIndexes[0] = aiExtraDataIndexes[i]
		endif
		
		i += 1
	endWhile
	
	return aiExtraDataIndexes
EndFunction


Int[] Function FillExtraData(WorkshopFramework:ObjectRefs:Thread_PlaceObject akThreadRef, Int[] aiExtraDataIndexes, Int aiCurrentIndex)
	if(aiCurrentIndex > aiExtraDataIndexes[0])
		aiExtraDataIndexes = UpdateExtraDataIndexes(aiExtraDataIndexes, aiCurrentIndex)
	endif	
	
	if(aiCurrentIndex == aiExtraDataIndexes[0])		
		aiExtraDataIndexes[0] = 100000 ; We're going to need to update this again
		
		if(aiExtraDataIndexes[1] == aiCurrentIndex && ExtraData_Forms01 != None)
			; Match found, send to thread
			akThreadRef.ExtraData_Form01 = GetIndexMappedUniversalForm(ExtraData_Forms01[aiExtraDataIndexes[2]])
			akThreadRef.ExtraData_Form01Set = true
			
			if(aiExtraDataIndexes[2] < ExtraData_Forms01.Length - 1)
				aiExtraDataIndexes[2] += 1
				aiExtraDataIndexes[1] = ExtraData_Forms01[aiExtraDataIndexes[2]].iIndex
			endif
		endif
		
		if(aiExtraDataIndexes[3] == aiCurrentIndex && ExtraData_Forms02 != None)
			; Match found, send to thread
			akThreadRef.ExtraData_Form02 = GetIndexMappedUniversalForm(ExtraData_Forms02[aiExtraDataIndexes[4]])
			akThreadRef.ExtraData_Form02Set = true
			
			if(aiExtraDataIndexes[4] < ExtraData_Forms02.Length - 1)
				aiExtraDataIndexes[4] += 1
				aiExtraDataIndexes[3] = ExtraData_Forms02[aiExtraDataIndexes[4]].iIndex
			endif
		endif
		
		if(aiExtraDataIndexes[5] == aiCurrentIndex && ExtraData_Forms03 != None)
			; Match found, send to thread
			akThreadRef.ExtraData_Form03 = GetIndexMappedUniversalForm(ExtraData_Forms03[aiExtraDataIndexes[6]])
			akThreadRef.ExtraData_Form03Set = true
			
			if(aiExtraDataIndexes[6] < ExtraData_Forms03.Length - 1)
				aiExtraDataIndexes[6] += 1
				aiExtraDataIndexes[5] = ExtraData_Forms03[aiExtraDataIndexes[6]].iIndex
			endif
		endif
		
		if(aiExtraDataIndexes[7] == aiCurrentIndex && ExtraData_Numbers01 != None)
			; Match found, send to thread
			akThreadRef.ExtraData_Number01 = ExtraData_Numbers01[aiExtraDataIndexes[8]].fNumber
			akThreadRef.ExtraData_Number01Set = true
			
			if(aiExtraDataIndexes[8] < ExtraData_Numbers01.Length - 1)
				aiExtraDataIndexes[8] += 1
				aiExtraDataIndexes[7] = ExtraData_Numbers01[aiExtraDataIndexes[8]].iIndex
			endif
		endif
		
		if(aiExtraDataIndexes[9] == aiCurrentIndex && ExtraData_Numbers02 != None)
			; Match found, send to thread
			akThreadRef.ExtraData_Number02 = ExtraData_Numbers02[aiExtraDataIndexes[10]].fNumber
			akThreadRef.ExtraData_Number02Set = true
			
			if(aiExtraDataIndexes[10] < ExtraData_Numbers02.Length - 1)
				aiExtraDataIndexes[10] += 1
				aiExtraDataIndexes[9] = ExtraData_Numbers02[aiExtraDataIndexes[10]].iIndex
			endif
		endif
		
		if(aiExtraDataIndexes[11] == aiCurrentIndex && ExtraData_Numbers03 != None)
			; Match found, send to thread
			akThreadRef.ExtraData_Number03 = ExtraData_Numbers03[aiExtraDataIndexes[12]].fNumber
			akThreadRef.ExtraData_Number03Set = true
			
			if(aiExtraDataIndexes[12] < ExtraData_Numbers03.Length - 1)
				aiExtraDataIndexes[12] += 1
				aiExtraDataIndexes[11] = ExtraData_Numbers03[aiExtraDataIndexes[12]].iIndex
			endif
		endif
		
		if(aiExtraDataIndexes[13] == aiCurrentIndex && ExtraData_Strings01 != None)
			; Match found, send to thread
			akThreadRef.ExtraData_String01 = ExtraData_Strings01[aiExtraDataIndexes[14]].sString
			akThreadRef.ExtraData_String01Set = true
			
			if(aiExtraDataIndexes[14] < ExtraData_Strings01.Length - 1)
				aiExtraDataIndexes[14] += 1
				aiExtraDataIndexes[13] = ExtraData_Strings01[aiExtraDataIndexes[14]].iIndex
			endif
		endif
		
		if(aiExtraDataIndexes[15] == aiCurrentIndex && ExtraData_Strings02 != None)
			; Match found, send to thread
			akThreadRef.ExtraData_String02 = ExtraData_Strings02[aiExtraDataIndexes[16]].sString
			akThreadRef.ExtraData_String02Set = true
			
			if(aiExtraDataIndexes[16] < ExtraData_Strings02.Length - 1)
				aiExtraDataIndexes[16] += 1
				aiExtraDataIndexes[15] = ExtraData_Strings02[aiExtraDataIndexes[16]].iIndex
			endif
		endif
		
		if(aiExtraDataIndexes[17] == aiCurrentIndex && ExtraData_Strings03 != None)
			; Match found, send to thread
			akThreadRef.ExtraData_String03 = ExtraData_Strings03[aiExtraDataIndexes[18]].sString
			akThreadRef.ExtraData_String03Set = true
			
			if(aiExtraDataIndexes[18] < ExtraData_Strings03.Length - 1)
				aiExtraDataIndexes[18] += 1
				aiExtraDataIndexes[17] = ExtraData_Strings03[aiExtraDataIndexes[18]].iIndex
			endif
		endif
		
		if(aiExtraDataIndexes[19] == aiCurrentIndex && ExtraData_Bools01 != None)
			; Match found, send to thread
			akThreadRef.ExtraData_Bool01 = ExtraData_Bools01[aiExtraDataIndexes[20]].bBool
			akThreadRef.ExtraData_Bool01Set = true
			
			if(aiExtraDataIndexes[20] < ExtraData_Bools01.Length - 1)
				aiExtraDataIndexes[20] += 1
				aiExtraDataIndexes[19] = ExtraData_Bools01[aiExtraDataIndexes[20]].iIndex
			endif
		endif
		
		if(aiExtraDataIndexes[21] == aiCurrentIndex && ExtraData_Bools02 != None)
			; Match found, send to thread
			akThreadRef.ExtraData_Bool02 = ExtraData_Bools02[aiExtraDataIndexes[22]].bBool
			akThreadRef.ExtraData_Bool02Set = true
			
			if(aiExtraDataIndexes[22] < ExtraData_Bools02.Length - 1)
				aiExtraDataIndexes[22] += 1
				aiExtraDataIndexes[21] = ExtraData_Bools02[aiExtraDataIndexes[22]].iIndex
			endif
		endif
		
		if(aiExtraDataIndexes[23] == aiCurrentIndex && ExtraData_Bools03 != None)
			; Match found, send to thread
			akThreadRef.ExtraData_Bool03 = ExtraData_Bools03[aiExtraDataIndexes[24]].bBool
			akThreadRef.ExtraData_Bool03Set = true
			
			if(aiExtraDataIndexes[24] < ExtraData_Bools03.Length - 1)
				aiExtraDataIndexes[24] += 1
				aiExtraDataIndexes[23] = ExtraData_Bools03[aiExtraDataIndexes[24]].iIndex
			endif
		endif
		
		; Find lowest index
		int i = 1
		while(i < aiExtraDataIndexes.Length)
			if(Mod(i, 2) == 1 && aiExtraDataIndexes[i] >= 0 && aiExtraDataIndexes[i] < aiExtraDataIndexes[0])
				aiExtraDataIndexes[0] = aiExtraDataIndexes[i]
			endif
			
			i += 1
		endWhile
	endif
	
	return aiExtraDataIndexes
EndFunction


Int Function PlaceObjects(WorkshopScript akWorkshopRef, Int aiObjectsGroupType, Int aiCustomCallbackID = -1, Bool abProtectFromScrapPhase = false)
	if(akWorkshopRef == None)
		return 0
	endif
	
	WorldObject[] aObjectsToPlace
	if(aiObjectsGroupType == iGroupType_NonResources)
		aObjectsToPlace = NonResourceObjects
	elseif(aiObjectsGroupType == iGroupType_WorkshopResources)
		aObjectsToPlace = WorkshopResources
	endif
	
	ObjectReference PlayerRef = Game.GetPlayer()
	
	WorkshopFramework:MainThreadManager ThreadManager = GetThreadManager()
	Form PlaceObjectThread = GetPlaceObjectThread()
	ActorValue LayoutIndexAV = GetLayoutIndexAV()
	ActorValue LayoutIndexTypeAV = GetLayoutIndexTypeAV()
	WorkshopFramework:F4SEManager F4SEManager = GetF4SEManager()
	Bool bFauxPoweredSettingEnabled = GetSetting_Import_FauxPowerItems().GetValueInt() == 1
	Bool bSpawnNPCs = GetSetting_Import_SpawnNPCs().GetValueInt() == 1
	Bool bSpawnPowerArmor = GetSetting_Import_SpawnPowerArmor().GetValueInt() == 1
	
	Keyword PowerArmorKeyword = GetPowerArmorKeyword()
	Keyword WorkshopKeyword = GetWorkshopKeyword()
	Keyword PreventScrappingKeyword = GetPreventScrappingKeyword()
	Keyword InvisibleWorkshopObjectKeyword = GetInvisibleWorkshopObjectKeyword()
	
	WorkshopFramework:SettlementLayoutManager SettlementLayoutManager = GetSettlementLayoutManager()
	UniversalForm[] UF_AlwaysAllowedActorTypes = SettlementLayoutManager.AlwaysAllowedActorTypes
	Form[] AlwaysAllowedActorTypes = new Form[0]
	int i = 0
	while(i < UF_AlwaysAllowedActorTypes.Length)
		AlwaysAllowedActorTypes.Add(GetUniversalForm(UF_AlwaysAllowedActorTypes[i]))
		
		i += 1
	endWhile
	
	int iThreadsStarted = 0
	
	int[] iExtraDataIndexes = UpdateExtraDataIndexes()
	
	i = 0
	while(i < aObjectsToPlace.Length)
		int iTagIndex = i + 1 ; We can't tag with a base-0 index or the 0 entry will likely be wrong since all AVs default to 0
		Form FormToPlace = GetWorldObjectForm(aObjectsToPlace[i])
		Bool bShouldPlace = ShouldPlaceObject(akWorkshopRef, aiObjectsGroupType, i)
		
		if(FormToPlace == None)
			bShouldPlace = false
		else
			if(FormToPlace.HasKeyword(WorkshopKeyword))
				bShouldPlace = false
			elseif(FormToPlace.HasKeyword(PowerArmorKeyword))
				if( ! bSpawnPowerArmor)
					bShouldPlace = false
				endif
			elseif(FormToPlace as ActorBase)
				if( ! bSpawnNPCs)
					bShouldPlace = false
					
					; Look for exceptions
					int j = 0
					while(j < AlwaysAllowedActorTypes.Length && ! bShouldPlace)
						Keyword asKeyword = AlwaysAllowedActorTypes[j] as Keyword
						
						if(asKeyword)
							if(FormToPlace.HasKeyword(asKeyword))
								bShouldPlace = true
							endif
						elseif(FormToPlace == AlwaysAllowedActorTypes[j])
							bShouldPlace = true
						endif
						
						j += 1
					endWhile
				endif
			endif
		endif
		
		if(bShouldPlace)
			WorkshopFramework:ObjectRefs:Thread_PlaceObject kThread = ThreadManager.CreateThread(PlaceObjectThread) as WorkshopFramework:ObjectRefs:Thread_PlaceObject
			
			if(kThread)	
				; Configure threading so we can correctly identify when layer construction is complete
				kThread.bAutoDestroy = false
				kThread.iBatchID = aiCustomCallbackID ; Reusing PlaceObjectManager's batch field to tie our layout items together
				
				; Tag with AVs to setup which group it came from to assist power code
				kThread.AddTagAVSet(LayoutIndexAV, iTagIndex as float)
				kThread.AddTagAVSet(LayoutIndexTypeAV, aiObjectsGroupType as float)
				
				; Tag items with the layer keyword
				if(TagKeyword != None)
					kThread.AddTagKeyword(TagKeyword)
				endif
				
				if(abProtectFromScrapPhase)
					; If scrap phase is delayed for some reason, we need to protect this from it
					kThread.AddTagKeyword(PreventScrappingKeyword)
				endif
				
				; Setup spawning info on thread
				kThread.bFadeIn = false
				
				if(FormToPlace.HasKeyword(InvisibleWorkshopObjectKeyword))
					kThread.bStartEnabled = false ; Let those objects handle themselves
				else
					kThread.bStartEnabled = true
				endif
				
				kThread.bForceStatic = aObjectsToPlace[i].bForceStatic
				kThread.kSpawnAt = PlayerRef
				kThread.SpawnMe = FormToPlace
				kThread.fPosX = aObjectsToPlace[i].fPosX
				kThread.fPosY = aObjectsToPlace[i].fPosY
				kThread.fPosZ = aObjectsToPlace[i].fPosZ
				kThread.fAngleX = aObjectsToPlace[i].fAngleX
				kThread.fAngleY = aObjectsToPlace[i].fAngleY
				kThread.fAngleZ = aObjectsToPlace[i].fAngleZ
				kThread.fScale = aObjectsToPlace[i].fScale
				kThread.kWorkshopRef = akWorkshopRef
				
				kThread.bRecalculateWorkshopResources = false ; We will just run this once when its done
				
				if( ! F4SEManager.IsF4SERunning || bFauxPoweredSettingEnabled)
					kThread.bFauxPowered = true
				endif
				
				; Handle extra data indexes
				if(aiObjectsGroupType == iGroupType_WorkshopResources && i >= iExtraDataIndexes[0])
					iExtraDataIndexes = FillExtraData(kThread, iExtraDataIndexes, aiCurrentIndex = i)
				endif
				
				; Check for Sim Settlements data
				if(aObjectsToPlace[i].sPluginName == "SimSettlements.esm")
					if(aiObjectsGroupType == iGroupType_WorkshopResources)
						int iSSIndex = ExtraData_Forms01.FindStruct("iIndex", i)
						if(iSSIndex >= 0)
							String sPluginName = ExtraData_Forms01[iSSIndex].sPluginName
							Int iFormID = ExtraData_Forms01[iSSIndex].iFormID
							if(Game.IsPluginInstalled(sPluginName))
								Form PlanForm = Game.GetFormFromFile(iFormID, sPluginName)
								if(PlanForm != None)
									kThread.BuildingPlan = PlanForm
									
									iSSIndex = ExtraData_Numbers01.FindStruct("iIndex", i)
									if(iSSIndex >= 0)
										kThread.iStartingLevel = ExtraData_Numbers01[iSSIndex].fNumber as Int
									else
										kThread.iStartingLevel = -1 ; -1 = Max level
									endif
								endif
							endif
						endif
						
						iSSIndex = ExtraData_Forms03.FindStruct("iIndex", i)
						if(iSSIndex >= 0)
							String sPluginName = ExtraData_Forms03[iSSIndex].sPluginName
							Int iFormID = ExtraData_Forms03[iSSIndex].iFormID
							if(Game.IsPluginInstalled(sPluginName))
								Form PlanForm = Game.GetFormFromFile(iFormID, sPluginName)
								if(PlanForm != None)
									kThread.StoryPlan = PlanForm
								endif
							endif
						endif
						
						iSSIndex = ExtraData_Forms02.FindStruct("iIndex", i)
						if(iSSIndex >= 0)
							String sPluginName = ExtraData_Forms02[iSSIndex].sPluginName
							Int iFormID = ExtraData_Forms02[iSSIndex].iFormID
							if(Game.IsPluginInstalled(sPluginName))
								Form PlanForm = Game.GetFormFromFile(iFormID, sPluginName)
								if(PlanForm != None)
									kThread.SkinPlan = PlanForm
								endif
							endif
						endif
					endif
				endif
				
				if(PlaceObjectThreadLastCall(kThread))
					ThreadManager.QueueThread(kThread, sPlaceObjectCallbackID)
					
					iThreadsStarted += 1
				endif				
			endif
		endif
		
		i += 1
	endWhile
	
	return iThreadsStarted
EndFunction


Bool Function PlaceObjectThreadLastCall(ObjectReference akThreadRef)
	; Chance for extension, could use this to cancel thread or even alter details before it proceeds
	return true
EndFunction


Int Function RemoveVanillaObjects(WorkshopScript akWorkshopRef, Bool abCallbacksNeeded = false)
	; Defining here instead of manager to allow extension
	if(akWorkshopRef == None)
		return 0
	endif
	
	WorkshopFramework:MainThreadManager ThreadManager = GetThreadManager()
	Form FindAndScrapObjectThread = GetFindAndScrapObjectThread()
	
	int iThreadsStarted = 0
	
	int i = 0
	while(i < VanillaObjectsToRemove.Length)
		WorkshopFramework:ObjectRefs:Thread_FindAndScrapObject kThread = ThreadManager.CreateThread(FindAndScrapObjectThread) as WorkshopFramework:ObjectRefs:Thread_FindAndScrapObject

		if(kThread)
			kThread.kWorkshopRef = akWorkshopRef
			kThread.ScrapObjectData = CopyWorldObject(VanillaObjectsToRemove[i])
			
			String sCallbackID = ""
			if(abCallbacksNeeded)
				sCallbackID = sScrapObjectCallbackID
			endif
			
			if(RemoveVanillaObjectThreadLastCall(kThread))
				ThreadManager.QueueThread(kThread, sCallbackID)
				iThreadsStarted += 1
			endif
		endif
		
		i += 1
	endWhile
	
	return iThreadsStarted
EndFunction


Bool Function RemoveVanillaObjectThreadLastCall(ObjectReference akThreadRef)
	; Chance for extension, could use this to cancel thread or even alter details before it proceeds
	return true
EndFunction


Int Function RemoveLayoutObjects(WorkshopScript akWorkshopRef, Bool abCallbacksNeeded = false)
	Keyword WorkshopItemKeyword = GetWorkshopItemKeyword()
	ObjectReference[] kLinkedRefs = akWorkshopRef.GetLinkedRefChildren(WorkshopItemKeyword)
		
	int iThreadsStarted = 0
	WorkshopFramework:MainThreadManager ThreadManager = GetThreadManager()
	Form ScrapObjectThread = GetScrapObjectThread()
	
	int i = 0
	while(i < kLinkedRefs.Length)
		if(kLinkedRefs[i].HasKeyword(TagKeyword))
			WorkshopFramework:ObjectRefs:Thread_ScrapObject kThread = ThreadManager.CreateThread(ScrapObjectThread) as WorkshopFramework:ObjectRefs:Thread_ScrapObject

			if(kThread)
				kThread.kScrapMe = kLinkedRefs[i]
				kThread.kWorkshopRef = akWorkshopRef
					
				String sCallbackID = ""
				if(abCallbacksNeeded)
					sCallbackID = sScrapObjectCallbackID
				endif
				
				if(RemoveLayoutObjectThreadLastCall(kThread))	
					iThreadsStarted += 1
					ThreadManager.QueueThread(kThread, sCallbackID)
				endif
			endif
		endif
		
		i += 1
	endWhile
	
	return iThreadsStarted
EndFunction	

Bool Function RemoveLayoutObjectThreadLastCall(ObjectReference akThreadRef)
	; Chance for extension, could use this to cancel thread or even alter details before it proceeds
	return true
EndFunction


Function PowerUp(WorkshopScript akWorkshopRef)
	WorkshopFramework:F4SEManager F4SEManager = GetF4SEManager()
	if(F4SEManager.IsF4SERunning)
		; Wiring up is only reliable in WS Mode
		if( ! akWorkshopRef.bHasEnteredWorkshopModeHere)
			akWorkshopRef.StartWorkshop()
		endif
		
		if(PowerConnections != None)
			ObjectReference[] kLinkedRefs = akWorkshopRef.GetLinkedRefChildren(GetWorkshopItemKeyword())
			ActorValue LayoutIndexAV = GetLayoutIndexAV()
			ActorValue LayoutIndexTypeAV = GetLayoutIndexTypeAV()
			ActorValue WorkshopPowerConnectionAV = GetWorkshopPowerConnectionAV()
			ActorValue WorkshopSnapTransmitsPowerAV = GetWorkshopSnapTransmitsPowerAV()
			Keyword WorkshopPowerConnectionKeyword = GetWorkshopPowerConnectionKeyword()
			Formlist SkipPowerOnList = GetSkipPowerOnList()
			
			PowerConnectionLookup[] Group01 = new PowerConnectionLookup[0]
			PowerConnectionLookup[] Group02 = new PowerConnectionLookup[0]
			PowerConnectionLookup[] Group03 = new PowerConnectionLookup[0]
			PowerConnectionLookup[] Group04 = new PowerConnectionLookup[0]
			PowerConnectionLookup[] Group05 = new PowerConnectionLookup[0]
			PowerConnectionLookup[] Group06 = new PowerConnectionLookup[0]
			PowerConnectionLookup[] Group07 = new PowerConnectionLookup[0]
			PowerConnectionLookup[] Group08 = new PowerConnectionLookup[0]
			
			int i = 0
			int iPoweredConnectableCounter = 0
			int iPowerDataFoundFor = 0
			while(i < kLinkedRefs.Length)
				if( ! kLinkedRefs[i].IsDisabled() && kLinkedRefs[i].HasKeyword(TagKeyword) && (kLinkedRefs[i].HasKeyword(WorkshopPowerConnectionKeyword) || kLinkedRefs[i].GetValue(WorkshopPowerConnectionAV) > 0))
					iPoweredConnectableCounter += 1
					Int iIndex = (kLinkedRefs[i].GetValue(LayoutIndexAV) - 1) as Int 
					if(iIndex >= 0) ; We have power connection data for this
						iPowerDataFoundFor += 1
						Int iType = kLinkedRefs[i].GetValue(LayoutIndexTypeAV) as Int 
						
						PowerConnectionLookup newLookup = new PowerConnectionLookup
						newLookup.kPowereableRef = kLinkedRefs[i]
						newLookup.iIndex = iIndex
						newLookup.iIndexType = iType
						; Store in a lookup group
						if(Group01.Length < 128)
							Group01.Add(newLookup)
						elseif(Group02.Length < 128)
							Group02.Add(newLookup)
						elseif(Group03.Length < 128)
							Group03.Add(newLookup)
						elseif(Group04.Length < 128)
							Group04.Add(newLookup)
						elseif(Group05.Length < 128)
							Group05.Add(newLookup)
						elseif(Group06.Length < 128)
							Group06.Add(newLookup)
						elseif(Group07.Length < 128)
							Group07.Add(newLookup)
						elseif(Group08.Length < 128)
							if(Group08.Length == 0)
								ModTrace(">>>>>>>>>>Filling group 8 - should add more groups to code base.")
							endif
							
							Group08.Add(newLookup)
						endif
					endif
				endif
				
				i += 1
			endWhile
			
			;Debug.MessageBox("Found "+ iPoweredConnectableCounter + " items w/ connectors and " + iPowerDataFoundFor + " items with stored connection data. Trace dumping list of refs.")
			
			;i = 0
			;while(i < Group01.Length)
			;	ModTrace(">>>>Group01 Dump: " + Group01[i])
				
			;	i += 1
			;endWhile
			
			i = 0
			while(i < PowerConnections.Length)
				;Debug.Trace("PowerConnections[" + i + "]: " + PowerConnections[i])
				ObjectReference kObjectRefA = FindPowereableRef(Group01, PowerConnections[i], true)
				ObjectReference kObjectRefB = None
				
				if( ! kObjectRefA)
					kObjectRefA = FindPowereableRef(Group02, PowerConnections[i], true)
					
					if( ! kObjectRefA)
						kObjectRefA = FindPowereableRef(Group03, PowerConnections[i], true)
						
						if( ! kObjectRefA)
							kObjectRefA = FindPowereableRef(Group04, PowerConnections[i], true)
							
							if( ! kObjectRefA)
								kObjectRefA = FindPowereableRef(Group05, PowerConnections[i], true)
								
								if( ! kObjectRefA)
									kObjectRefA = FindPowereableRef(Group06, PowerConnections[i], true)
									
									if( ! kObjectRefA)
										kObjectRefA = FindPowereableRef(Group07, PowerConnections[i], true)
										
										if( ! kObjectRefA)
											kObjectRefA = FindPowereableRef(Group08, PowerConnections[i], true)
										endif										
									endif
								endif
							endif
						endif
					endif
				endif
				
				if(kObjectRefA && ! kObjectRefB)
					; A found, now search for B
					kObjectRefB = FindPowereableRef(Group01, PowerConnections[i], false)
					if( ! kObjectRefB)
						kObjectRefB = FindPowereableRef(Group02, PowerConnections[i], false)
						
						if( ! kObjectRefB)
							kObjectRefB = FindPowereableRef(Group03, PowerConnections[i], false)
							
							if( ! kObjectRefB)
								kObjectRefB = FindPowereableRef(Group04, PowerConnections[i], false)
								
								if( ! kObjectRefB)
									kObjectRefB = FindPowereableRef(Group05, PowerConnections[i], false)
									
									if( ! kObjectRefB)
										kObjectRefB = FindPowereableRef(Group06, PowerConnections[i], false)
										
										if( ! kObjectRefB)
											kObjectRefB = FindPowereableRef(Group07, PowerConnections[i], false)
											
											if( ! kObjectRefB)
												kObjectRefB = FindPowereableRef(Group08, PowerConnections[i], false)
											endif										
										endif
									endif
								endif
							endif
						endif
					endif
				endif
				
				if(kObjectRefA && kObjectRefB)
					ModTrace("[PowerUpAttempt] Creating Wire between: " + kObjectRefA + " and " + kObjectRefB)
					
					; Both found - create wire
					ObjectReference kWireRef = F4SEManager.AttachWire(kObjectRefA, kObjectRefB)
					if(kWireRef != None)
						kWireRef.Enable(false)
						kWireRef.AddKeyword(TagKeyword)
					else
						; Try using CreateWire instead
						kWireRef = F4SEManager.CreateWire(kObjectRefA, kObjectRefB)
						
						if( ! kWireRef)
							ModTrace("[PowerUpAttemptResult] Failed to create wire between " + kObjectRefA + " and " + kObjectRefB + ".")
						else
							if(kWireRef.IsDisabled())
								kWireRef.Enable(false)
								kWireRef.AddKeyword(TagKeyword)
							endif
						endif
					endif
				else
					ModTrace("[PowerUpFailure] Could not find refs to make connection: " + PowerConnections[i])
				endif				
				
				i += 1
			endWhile
			
			; Wires complete, now transmit power so snap power functions
			i = 0
			while(i < kLinkedRefs.Length)
				if( ! kLinkedRefs[i].IsDisabled())
					if(kLinkedRefs[i].GetValue(WorkshopSnapTransmitsPowerAV) > 0)
						F4SEManager.TransmitConnectedPower(kLinkedRefs[i])
					elseif(SkipPowerOnList.HasForm(kLinkedRefs[i].GetBaseObject()))
						kLinkedRefs[i].SetOpen(false) ; This will turn off any switches on the devices
						kLinkedRefs[i].OnPowerOff()
					endif
				endif
				
				i += 1
			endWhile
		endif
	endif
EndFunction


ObjectReference Function FindPowereableRef(PowerConnectionLookup[] aLookupGroup, PowerConnectionMap aPowerConnectionMap, Bool abSearchForIndexA = true)
	if(aLookupGroup.Length > 0)
		if(abSearchForIndexA)
			int i = 0
			while(i < aLookupGroup.Length)
				if(aLookupGroup[i].iIndex == aPowerConnectionMap.iIndexA && aLookupGroup[i].iIndexType == aPowerConnectionMap.iIndexTypeA)
					;Debug.Trace("Returning ref A: " + aLookupGroup[i].kPowereableRef)
					return aLookupGroup[i].kPowereableRef
				endif
				
				i += 1
			endWhile
		else	
			int i = 0
			while(i < aLookupGroup.Length)
				if(aLookupGroup[i].iIndex == aPowerConnectionMap.iIndexB && aLookupGroup[i].iIndexType == aPowerConnectionMap.iIndexTypeB)
					;Debug.Trace("Returning ref B: " + aLookupGroup[i].kPowereableRef)
					return aLookupGroup[i].kPowereableRef
				endif
				
				i += 1
			endWhile
		endif						
	endif	
	
	return None
EndFunction

Bool Function ShouldPlaceObject(WorkshopScript akWorkshopRef, Int aiObjectsGroupType, Int aiObjectsGroupIndex)
	; For extension overrride
	return true
EndFunction


; ---------------------------------
; Form Loader Functions
; 
;/ 
The goal of this method is to allow easy extension. To facilitate this, we are not setting these up as editor properties so that the extending implementation can override the forms. This also ensures that even entries using this exact script don't have to set up the script properties which future-proofs us if we need to change some of them and don't want to force every creator to have to update their version.
/;
; ---------------------------------

WorkshopFramework:MainThreadManager Function GetThreadManager()
	return Game.GetFormFromFile(0x00001736, "WorkshopFramework.esm") as WorkshopFramework:MainThreadManager
EndFunction

WorkshopFramework:F4SEManager Function GetF4SEManager()
	return Game.GetFormFromFile(0x0000269C, "WorkshopFramework.esm") as WorkshopFramework:F4SEManager
EndFunction

WorkshopFramework:SettlementLayoutManager Function GetSettlementLayoutManager()
	return Game.GetFormFromFile(0x00012B0D, "WorkshopFramework.esm") as WorkshopFramework:SettlementLayoutManager
EndFunction

Keyword Function GetPreventScrappingKeyword()
	return Game.GetFormFromFile(0x000158D9, "WorkshopFramework.esm") as Keyword
EndFunction

Keyword Function GetWorkshopItemKeyword()
	return Game.GetFormFromFile(0x00054BA6, "Fallout4.esm") as Keyword
EndFunction

Keyword Function GetWorkshopKeyword()
	return Game.GetFormFromFile(0x00054BA7, "Fallout4.esm") as Keyword
EndFunction

Formlist Function GetSkipPowerOnList()
	return Game.GetFormFromFile(0x000158CD, "WorkshopFramework.esm") as Formlist
EndFunction

ActorValue Function GetWorkshopPowerConnectionAV()
	return Game.GetFormFromFile(0x000002D0, "Fallout4.esm") as ActorValue
EndFunction

ActorValue Function GetWorkshopSnapTransmitsPowerAV()
	return Game.GetFormFromFile(0x00000354, "Fallout4.esm") as ActorValue
EndFunction

Keyword Function GetWorkshopPowerConnectionKeyword()
	return Game.GetFormFromFile(0x00054BA4, "Fallout4.esm") as Keyword
EndFunction

Keyword Function GetPowerArmorKeyword()
	return Game.GetFormFromFile(0x0003430B, "Fallout4.esm") as Keyword
EndFunction

Keyword Function GetInvisibleWorkshopObjectKeyword()
	return Game.GetFormFromFile(0x00006B5A, "WorkshopFramework.esm") as Keyword
EndFunction

Form Function GetFindAndScrapObjectThread()
	return Game.GetFormFromFile(0x00012B16, "WorkshopFramework.esm")
EndFunction

Form Function GetPlaceObjectThread()
	return Game.GetFormFromFile(0x00004CEB, "WorkshopFramework.esm")
EndFunction

Form Function GetRestoreObjectThread()
	return Game.GetFormFromFile(0x00012B11, "WorkshopFramework.esm")
EndFunction

Form Function GetScrapObjectThread()
	return Game.GetFormFromFile(0x00001F02, "WorkshopFramework.esm")
EndFunction


ActorValue Function GetLayoutIndexAV()
	return Game.GetFormFromFile(0x000141E4, "WorkshopFramework.esm") as ActorValue
EndFunction

ActorValue Function GetLayoutIndexTypeAV()
	return Game.GetFormFromFile(0x000141E5, "WorkshopFramework.esm") as ActorValue
EndFunction

GlobalVariable Function GetSetting_Import_FauxPowerItems()
	return Game.GetFormFromFile(0x000158D3, "WorkshopFramework.esm") as GlobalVariable
EndFunction

GlobalVariable Function GetSetting_Import_SpawnNPCs()
	return Game.GetFormFromFile(0x000158D4, "WorkshopFramework.esm") as GlobalVariable
EndFunction

GlobalVariable Function GetSetting_Import_SpawnPowerArmor()
	return Game.GetFormFromFile(0x000158D5, "WorkshopFramework.esm") as GlobalVariable
EndFunction


; Test Commands

Function DumpNonResourceObjects()
	ModTrace("==============================")
	ModTrace("Starting dump of NonResourceObjects for " + Self)
	ModTrace("==============================")
	
	int i = 0
	while(i < NonResourceObjects.Length)
		ModTrace("[" + i + "] " + NonResourceObjects[i])
		
		i += 1
	endWhile
	
	ModTrace("==============================")
	ModTrace("Completed dump of NonResourceObjects for " + Self)
	ModTrace("==============================")
EndFunction

Function DumpWorkshopResources()
	ModTrace("==============================")
	ModTrace("Starting dump of WorkshopResources for " + Self)
	ModTrace("==============================")
	
	int i = 0
	while(i < WorkshopResources.Length)
		ModTrace(WorkshopResources[i])
		
		i += 1
	endWhile
	
	ModTrace("==============================")
	ModTrace("Completed dump of WorkshopResources for " + Self)
	ModTrace("==============================")
EndFunction

Function DumpPowerConnections()
	ModTrace("==============================")
	ModTrace("Starting dump of PowerConnections for " + Self)
	ModTrace("==============================")
	
	int i = 0
	while(i < PowerConnections.Length)
		ModTrace(PowerConnections[i])
		
		i += 1
	endWhile
	
	ModTrace("==============================")
	ModTrace("Completed dump of PowerConnections for " + Self)
	ModTrace("==============================")
EndFunction