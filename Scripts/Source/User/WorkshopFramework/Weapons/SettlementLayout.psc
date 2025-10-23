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

Float fExtraDataFlag_SkipWorkshopItemLink = 1.0 Const

Int HIGH_INT = 9999999 Const

Int POWERCONNECTIONTYPE_WORKSHOPRESOURCE = 1 Const
Int POWERCONNECTIONTYPE_NONRESOURCE = 2 Const
Int POWERCONNECTIONTYPE_VANILLA = 3 Const

Int iExtraDataIndex_NextObjectIndex = 0 Const
Int iExtraDataIndex_Forms01_NextObjectIndex = 1 Const
Int iExtraDataIndex_Forms01_ExtraDataArrayIndex = 2 Const
Int iExtraDataIndex_Forms02_NextObjectIndex = 3 Const
Int iExtraDataIndex_Forms02_ExtraDataArrayIndex = 4 Const
Int iExtraDataIndex_Forms03_NextObjectIndex = 5 Const
Int iExtraDataIndex_Forms03_ExtraDataArrayIndex = 6 Const
Int iExtraDataIndex_Numbers01_NextObjectIndex = 7 Const
Int iExtraDataIndex_Numbers01_ExtraDataArrayIndex = 8 Const
Int iExtraDataIndex_Numbers02_NextObjectIndex = 9 Const
Int iExtraDataIndex_Numbers02_ExtraDataArrayIndex = 10 Const
Int iExtraDataIndex_Numbers03_NextObjectIndex = 11 Const
Int iExtraDataIndex_Numbers03_ExtraDataArrayIndex = 12 Const
Int iExtraDataIndex_Strings01_NextObjectIndex = 13 Const
Int iExtraDataIndex_Strings01_ExtraDataArrayIndex = 14 Const
Int iExtraDataIndex_Strings02_NextObjectIndex = 15 Const
Int iExtraDataIndex_Strings02_ExtraDataArrayIndex = 16 Const
Int iExtraDataIndex_Strings03_NextObjectIndex = 17 Const
Int iExtraDataIndex_Strings03_ExtraDataArrayIndex = 18 Const
Int iExtraDataIndex_Bools01_NextObjectIndex = 19 Const
Int iExtraDataIndex_Bools01_ExtraDataArrayIndex = 20 Const
Int iExtraDataIndex_Bools02_NextObjectIndex = 21 Const
Int iExtraDataIndex_Bools02_ExtraDataArrayIndex = 22 Const
Int iExtraDataIndex_Bools03_NextObjectIndex = 23 Const
Int iExtraDataIndex_Bools03_ExtraDataArrayIndex = 24 Const

Int iExtraDataValues_OutOfSequence = -1 Const
Int iExtraDataValues_AllDistributed = -2 Const
Int iExtraDataValues_NoExtraDataFound = -3 Const

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
	ActorValue LayoutIndexAV = GetLayoutIndexAV()
	ActorValue LayoutIndexTypeAV = GetLayoutIndexTypeAV()
	
	int i = 0
	while(i < VanillaObjectsToRestore.Length)
		WorkshopFramework:ObjectRefs:Thread_RestoreObject kThread = ThreadManager.CreateThread(RestoreObjectThread) as WorkshopFramework:ObjectRefs:Thread_RestoreObject

		if(kThread)
			kThread.kWorkshopRef = akWorkshopRef
			kThread.RestoreObjectData = CopyWorldObject(VanillaObjectsToRestore[i])
			
			; Tag with AVs to setup which group it came from to assist power code
			int iTagIndex = i + 1
			kThread.AddTagAVSet(LayoutIndexAV, iTagIndex as float)
			kThread.AddTagAVSet(LayoutIndexTypeAV, POWERCONNECTIONTYPE_VANILLA)
						
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


Function InitializeExtraDataIndexes(Int[] aiExtraDataIndexes)
	if(ExtraData_Forms01 == None && ExtraData_Forms02 == None && ExtraData_Forms03 == None && ExtraData_Numbers01 == None && ExtraData_Numbers02 == None && ExtraData_Numbers03 == None && ExtraData_Strings01 == None && ExtraData_Strings02 == None && ExtraData_Strings03 == None && ExtraData_Bools01 == None && ExtraData_Bools02 == None && ExtraData_Bools03 == None)
		aiExtraDataIndexes[iExtraDataIndex_NextObjectIndex] = iExtraDataValues_NoExtraDataFound
		
		return
	endif
	
	int iFirstFoundObjectIndex = iExtraDataValues_OutOfSequence
	Bool bExtraDataFound = false
	
	if(ExtraData_Forms01 != None)
		bExtraDataFound = true
		int iThisLowest = HIGH_INT
		bool bIndexSequential = true
		
		int i = 0
		while(i < ExtraData_Forms01.Length && bIndexSequential)			
			if(i > 0)
				; We expect extra data to be in order from lowest index to highest, so if we find one out of order, we will have to search via FindStruct later instead of assuming an index
				if(ExtraData_Forms01[i].iIndex < ExtraData_Forms01[(i-1)].iIndex)
					;Debug.MessageBox("ExtraData_Forms01 are non-sequential")
					bIndexSequential = false
					
					; -1 will indicate the data has to be checked with FindStruct
					aiExtraDataIndexes[iExtraDataIndex_Forms01_NextObjectIndex] = iExtraDataValues_OutOfSequence
					aiExtraDataIndexes[iExtraDataIndex_Forms01_ExtraDataArrayIndex] = iExtraDataValues_OutOfSequence
				endif
			endif
			
			if(bIndexSequential && ExtraData_Forms01[i].iIndex <= iThisLowest)
				if(ExtraData_Forms01[i].iIndex < 0)
					;Debug.MessageBox("iIndex for ExtraData_Forms01 " + i + " is " + ExtraData_Forms01[i].iIndex)			
				endif
				
				;Debug.MessageBox("Setting iThisLowest for ExtraData_Forms01 to " + ExtraData_Forms01[i].iIndex)
				iThisLowest = ExtraData_Forms01[i].iIndex
			
				aiExtraDataIndexes[iExtraDataIndex_Forms01_NextObjectIndex] = iThisLowest
				aiExtraDataIndexes[iExtraDataIndex_Forms01_ExtraDataArrayIndex] = i
			endif
			
			i += 1
		endWhile

		if(bIndexSequential)
			if(iThisLowest != HIGH_INT && (iFirstFoundObjectIndex < 0 || iThisLowest < iFirstFoundObjectIndex))
				;Debug.MessageBox("Setting iFirstFoundObjectIndex to " + iThisLowest)
				iFirstFoundObjectIndex = iThisLowest
			endif
		else
			;Debug.MessageBox("ExtraData_Forms01 are non-sequential")
		endif
	else
		;Debug.MessageBox("ExtraData_Forms01 == None")
	endif
	
	if(ExtraData_Forms02 != None)
		bExtraDataFound = true
		int iThisLowest = HIGH_INT
		bool bIndexSequential = true
		
		int i = 0
		while(i < ExtraData_Forms02.Length && bIndexSequential)			
			if(i > 0)
				; We expect extra data to be in order from lowest index to highest, so if we find one out of order, we will have to search via FindStruct later instead of assuming an index
				if(ExtraData_Forms02[i].iIndex < ExtraData_Forms02[(i-1)].iIndex)
					;Debug.MessageBox("ExtraData_Forms02 are non-sequential")
					bIndexSequential = false
					
					; -1 will indicate the data has to be checked with FindStruct
					aiExtraDataIndexes[iExtraDataIndex_Forms02_NextObjectIndex] = iExtraDataValues_OutOfSequence
					aiExtraDataIndexes[iExtraDataIndex_Forms02_ExtraDataArrayIndex] = iExtraDataValues_OutOfSequence
				endif
			endif
			
			if(bIndexSequential && ExtraData_Forms02[i].iIndex <= iThisLowest)
				if(ExtraData_Forms02[i].iIndex < 0)
					;Debug.MessageBox("iIndex for ExtraData_Forms02 " + i + " is " + ExtraData_Forms02[i].iIndex)
				endif
				
				iThisLowest = ExtraData_Forms02[i].iIndex
			
				aiExtraDataIndexes[iExtraDataIndex_Forms02_NextObjectIndex] = iThisLowest
				aiExtraDataIndexes[iExtraDataIndex_Forms02_ExtraDataArrayIndex] = i
			endif
			
			i += 1
		endWhile
		
		if(bIndexSequential)
			if(iThisLowest != HIGH_INT && (iFirstFoundObjectIndex < 0 || iThisLowest < iFirstFoundObjectIndex))
				;Debug.MessageBox("Setting iFirstFoundObjectIndex to " + iThisLowest)
				iFirstFoundObjectIndex = iThisLowest
			endif
		else
			;Debug.MessageBox("ExtraData_Forms02 are non-sequential")
		endif
	else
		;Debug.MessageBox("ExtraData_Forms02 == None")
	endif
	
	if(ExtraData_Forms03 != None)
		bExtraDataFound = true
		int iThisLowest = HIGH_INT
		bool bIndexSequential = true
		
		int i = 0
		while(i < ExtraData_Forms03.Length && bIndexSequential)			
			if(i > 0)
				; We expect extra data to be in order from lowest index to highest, so if we find one out of order, we will have to search via FindStruct later instead of assuming an index
				if(ExtraData_Forms03[i].iIndex < ExtraData_Forms03[(i-1)].iIndex)
					;Debug.MessageBox("ExtraData_Forms03 are non-sequential")
					bIndexSequential = false
					
					; -1 will indicate the data has to be checked with FindStruct
					aiExtraDataIndexes[iExtraDataIndex_Forms03_NextObjectIndex] = iExtraDataValues_OutOfSequence
					aiExtraDataIndexes[iExtraDataIndex_Forms03_ExtraDataArrayIndex] = iExtraDataValues_OutOfSequence
				endif
			endif
			
			if(bIndexSequential && ExtraData_Forms03[i].iIndex <= iThisLowest)
				if(ExtraData_Forms03[i].iIndex < 0)
					;Debug.MessageBox("iIndex for ExtraData_Forms03 " + i + " is " + ExtraData_Forms03[i].iIndex)
				endif
				
				iThisLowest = ExtraData_Forms03[i].iIndex
			
				aiExtraDataIndexes[iExtraDataIndex_Forms03_NextObjectIndex] = iThisLowest
				aiExtraDataIndexes[iExtraDataIndex_Forms03_ExtraDataArrayIndex] = i
			endif
			
			i += 1
		endWhile
		
		if(bIndexSequential)
			if(iThisLowest != HIGH_INT && (iFirstFoundObjectIndex < 0 || iThisLowest < iFirstFoundObjectIndex))
				;Debug.MessageBox("Setting iFirstFoundObjectIndex to " + iThisLowest)
				iFirstFoundObjectIndex = iThisLowest
			endif
		else
			;Debug.MessageBox("ExtraData_Forms03 are non-sequential")
		endif
	else
		;Debug.MessageBox("ExtraData_Forms03 == None")
	endif
	
	if(ExtraData_Numbers01 != None)
		bExtraDataFound = true
		int iThisLowest = HIGH_INT
		bool bIndexSequential = true
		
		int i = 0
		while(i < ExtraData_Numbers01.Length && bIndexSequential)			
			if(i > 0)
				; We expect extra data to be in order from lowest index to highest, so if we find one out of order, we will have to search via FindStruct later instead of assuming an index
				if(ExtraData_Numbers01[i].iIndex < ExtraData_Numbers01[(i-1)].iIndex)
					;Debug.MessageBox("ExtraData_Numbers01 are non-sequential")
					bIndexSequential = false
					
					; -1 will indicate the data has to be checked with FindStruct
					aiExtraDataIndexes[iExtraDataIndex_Numbers01_NextObjectIndex] = iExtraDataValues_OutOfSequence
					aiExtraDataIndexes[iExtraDataIndex_Numbers01_ExtraDataArrayIndex] = iExtraDataValues_OutOfSequence
				endif
			endif
			
			if(bIndexSequential && ExtraData_Numbers01[i].iIndex <= iThisLowest)
				if(ExtraData_Numbers01[i].iIndex < 0)
					;Debug.MessageBox("iIndex for ExtraData_Numbers01 " + i + " is " + ExtraData_Numbers01[i].iIndex)			
				endif
				
				;Debug.MessageBox("Setting iThisLowest for ExtraData_Numbers01 to " + ExtraData_Numbers01[i].iIndex)
				iThisLowest = ExtraData_Numbers01[i].iIndex
			
				aiExtraDataIndexes[iExtraDataIndex_Numbers01_NextObjectIndex] = iThisLowest
				aiExtraDataIndexes[iExtraDataIndex_Numbers01_ExtraDataArrayIndex] = i
			endif
			
			i += 1
		endWhile

		if(bIndexSequential)
			if(iThisLowest != HIGH_INT && (iFirstFoundObjectIndex < 0 || iThisLowest < iFirstFoundObjectIndex))
				;Debug.MessageBox("Setting iFirstFoundObjectIndex to " + iThisLowest)
				iFirstFoundObjectIndex = iThisLowest
			endif
		else
			;Debug.MessageBox("ExtraData_Numbers01 are non-sequential")
		endif
	else
		;Debug.MessageBox("ExtraData_Numbers01 == None")
	endif
	
	if(ExtraData_Numbers02 != None)
		bExtraDataFound = true
		int iThisLowest = HIGH_INT
		bool bIndexSequential = true
		
		int i = 0
		while(i < ExtraData_Numbers02.Length && bIndexSequential)			
			if(i > 0)
				; We expect extra data to be in order from lowest index to highest, so if we find one out of order, we will have to search via FindStruct later instead of assuming an index
				if(ExtraData_Numbers02[i].iIndex < ExtraData_Numbers02[(i-1)].iIndex)
					;Debug.MessageBox("ExtraData_Numbers02 are non-sequential")
					bIndexSequential = false
					
					; -1 will indicate the data has to be checked with FindStruct
					aiExtraDataIndexes[iExtraDataIndex_Numbers02_NextObjectIndex] = iExtraDataValues_OutOfSequence
					aiExtraDataIndexes[iExtraDataIndex_Numbers02_ExtraDataArrayIndex] = iExtraDataValues_OutOfSequence
				endif
			endif
			
			if(bIndexSequential && ExtraData_Numbers02[i].iIndex <= iThisLowest)
				if(ExtraData_Numbers02[i].iIndex < 0)
					;Debug.MessageBox("iIndex for ExtraData_Numbers02 " + i + " is " + ExtraData_Numbers02[i].iIndex)
				endif
				
				iThisLowest = ExtraData_Numbers02[i].iIndex
			
				aiExtraDataIndexes[iExtraDataIndex_Numbers02_NextObjectIndex] = iThisLowest
				aiExtraDataIndexes[iExtraDataIndex_Numbers02_ExtraDataArrayIndex] = i
			endif
			
			i += 1
		endWhile
		
		if(bIndexSequential)
			if(iThisLowest != HIGH_INT && (iFirstFoundObjectIndex < 0 || iThisLowest < iFirstFoundObjectIndex))
				;Debug.MessageBox("Setting iFirstFoundObjectIndex to " + iThisLowest)
				iFirstFoundObjectIndex = iThisLowest
			endif
		else
			;Debug.MessageBox("ExtraData_Numbers02 are non-sequential")
		endif
	else
		;Debug.MessageBox("ExtraData_Numbers01 == None")
	endif
	
	if(ExtraData_Numbers03 != None)
		bExtraDataFound = true
		int iThisLowest = HIGH_INT
		bool bIndexSequential = true
		
		int i = 0
		while(i < ExtraData_Numbers03.Length && bIndexSequential)			
			if(i > 0)
				; We expect extra data to be in order from lowest index to highest, so if we find one out of order, we will have to search via FindStruct later instead of assuming an index
				if(ExtraData_Numbers03[i].iIndex < ExtraData_Numbers03[(i-1)].iIndex)
					;Debug.MessageBox("ExtraData_Numbers03 are non-sequential")
					bIndexSequential = false
					
					; -1 will indicate the data has to be checked with FindStruct
					aiExtraDataIndexes[iExtraDataIndex_Numbers03_NextObjectIndex] = iExtraDataValues_OutOfSequence
					aiExtraDataIndexes[iExtraDataIndex_Numbers03_ExtraDataArrayIndex] = iExtraDataValues_OutOfSequence
				endif
			endif
			
			if(bIndexSequential && ExtraData_Numbers03[i].iIndex <= iThisLowest)
				if(ExtraData_Numbers03[i].iIndex < 0)
					;Debug.MessageBox("iIndex for ExtraData_Numbers03 " + i + " is " + ExtraData_Numbers03[i].iIndex)
				endif
				
				iThisLowest = ExtraData_Numbers03[i].iIndex
			
				aiExtraDataIndexes[iExtraDataIndex_Numbers03_NextObjectIndex] = iThisLowest
				aiExtraDataIndexes[iExtraDataIndex_Numbers03_ExtraDataArrayIndex] = i
			endif
			
			i += 1
		endWhile
		
		if(bIndexSequential)
			if(iThisLowest != HIGH_INT && (iFirstFoundObjectIndex < 0 || iThisLowest < iFirstFoundObjectIndex))
				;Debug.MessageBox("Setting iFirstFoundObjectIndex to " + iThisLowest)
				iFirstFoundObjectIndex = iThisLowest
			endif
		else
			;Debug.MessageBox("ExtraData_Numbers03 are non-sequential")
		endif
	else
		;Debug.MessageBox("ExtraData_Numbers03 == None")
	endif
	
	
	if(ExtraData_Strings01 != None)
		bExtraDataFound = true
		int iThisLowest = HIGH_INT
		bool bIndexSequential = true
		
		int i = 0
		while(i < ExtraData_Strings01.Length && bIndexSequential)			
			if(i > 0)
				; We expect extra data to be in order from lowest index to highest, so if we find one out of order, we will have to search via FindStruct later instead of assuming an index
				if(ExtraData_Strings01[i].iIndex < ExtraData_Strings01[(i-1)].iIndex)
					;Debug.MessageBox("ExtraData_Strings01 are non-sequential")
					bIndexSequential = false
					
					; -1 will indicate the data has to be checked with FindStruct
					aiExtraDataIndexes[iExtraDataIndex_Strings01_NextObjectIndex] = iExtraDataValues_OutOfSequence
					aiExtraDataIndexes[iExtraDataIndex_Strings01_ExtraDataArrayIndex] = iExtraDataValues_OutOfSequence
				endif
			endif
			
			if(bIndexSequential && ExtraData_Strings01[i].iIndex <= iThisLowest)
				if(ExtraData_Strings01[i].iIndex < 0)
					;Debug.MessageBox("iIndex for ExtraData_Strings01 " + i + " is " + ExtraData_Strings01[i].iIndex)			
				endif
				
				;Debug.MessageBox("Setting iThisLowest for ExtraData_Strings01 to " + ExtraData_Strings01[i].iIndex)
				iThisLowest = ExtraData_Strings01[i].iIndex
			
				aiExtraDataIndexes[iExtraDataIndex_Strings01_NextObjectIndex] = iThisLowest
				aiExtraDataIndexes[iExtraDataIndex_Strings01_ExtraDataArrayIndex] = i
			endif
			
			i += 1
		endWhile

		if(bIndexSequential)
			if(iThisLowest != HIGH_INT && (iFirstFoundObjectIndex < 0 || iThisLowest < iFirstFoundObjectIndex))
				;Debug.MessageBox("Setting iFirstFoundObjectIndex to " + iThisLowest)
				iFirstFoundObjectIndex = iThisLowest
			endif
		else
			;Debug.MessageBox("ExtraData_Strings01 are non-sequential")
		endif
	else
		;Debug.MessageBox("ExtraData_Strings01 == None")
	endif
	
	if(ExtraData_Strings02 != None)
		bExtraDataFound = true
		int iThisLowest = HIGH_INT
		bool bIndexSequential = true
		
		int i = 0
		while(i < ExtraData_Strings02.Length && bIndexSequential)			
			if(i > 0)
				; We expect extra data to be in order from lowest index to highest, so if we find one out of order, we will have to search via FindStruct later instead of assuming an index
				if(ExtraData_Strings02[i].iIndex < ExtraData_Strings02[(i-1)].iIndex)
					;Debug.MessageBox("ExtraData_Strings02 are non-sequential")
					bIndexSequential = false
					
					; -1 will indicate the data has to be checked with FindStruct
					aiExtraDataIndexes[iExtraDataIndex_Strings02_NextObjectIndex] = iExtraDataValues_OutOfSequence
					aiExtraDataIndexes[iExtraDataIndex_Strings02_ExtraDataArrayIndex] = iExtraDataValues_OutOfSequence
				endif
			endif
			
			if(bIndexSequential && ExtraData_Strings02[i].iIndex <= iThisLowest)
				if(ExtraData_Strings02[i].iIndex < 0)
					;Debug.MessageBox("iIndex for ExtraData_Strings02 " + i + " is " + ExtraData_Strings02[i].iIndex)
				endif
				
				iThisLowest = ExtraData_Strings02[i].iIndex
			
				aiExtraDataIndexes[iExtraDataIndex_Strings02_NextObjectIndex] = iThisLowest
				aiExtraDataIndexes[iExtraDataIndex_Strings02_ExtraDataArrayIndex] = i
			endif
			
			i += 1
		endWhile
		
		if(bIndexSequential)
			if(iThisLowest != HIGH_INT && (iFirstFoundObjectIndex < 0 || iThisLowest < iFirstFoundObjectIndex))
				;Debug.MessageBox("Setting iFirstFoundObjectIndex to " + iThisLowest)
				iFirstFoundObjectIndex = iThisLowest
			endif
		else
			;Debug.MessageBox("ExtraData_Strings02 are non-sequential")
		endif
	else
		;Debug.MessageBox("ExtraData_Strings01 == None")
	endif
	
	if(ExtraData_Strings03 != None)
		bExtraDataFound = true
		int iThisLowest = HIGH_INT
		bool bIndexSequential = true
		
		int i = 0
		while(i < ExtraData_Strings03.Length && bIndexSequential)			
			if(i > 0)
				; We expect extra data to be in order from lowest index to highest, so if we find one out of order, we will have to search via FindStruct later instead of assuming an index
				if(ExtraData_Strings03[i].iIndex < ExtraData_Strings03[(i-1)].iIndex)
					;Debug.MessageBox("ExtraData_Strings03 are non-sequential")
					bIndexSequential = false
					
					; -1 will indicate the data has to be checked with FindStruct
					aiExtraDataIndexes[iExtraDataIndex_Strings03_NextObjectIndex] = iExtraDataValues_OutOfSequence
					aiExtraDataIndexes[iExtraDataIndex_Strings03_ExtraDataArrayIndex] = iExtraDataValues_OutOfSequence
				endif
			endif
			
			if(bIndexSequential && ExtraData_Strings03[i].iIndex <= iThisLowest)
				if(ExtraData_Strings03[i].iIndex < 0)
					;Debug.MessageBox("iIndex for ExtraData_Strings03 " + i + " is " + ExtraData_Strings03[i].iIndex)
				endif
				
				iThisLowest = ExtraData_Strings03[i].iIndex
			
				aiExtraDataIndexes[iExtraDataIndex_Strings03_NextObjectIndex] = iThisLowest
				aiExtraDataIndexes[iExtraDataIndex_Strings03_ExtraDataArrayIndex] = i
			endif
			
			i += 1
		endWhile
		
		if(bIndexSequential)
			if(iThisLowest != HIGH_INT && (iFirstFoundObjectIndex < 0 || iThisLowest < iFirstFoundObjectIndex))
				;Debug.MessageBox("Setting iFirstFoundObjectIndex to " + iThisLowest)
				iFirstFoundObjectIndex = iThisLowest
			endif
		else
			;Debug.MessageBox("ExtraData_Strings03 are non-sequential")
		endif
	else
		;Debug.MessageBox("ExtraData_Strings03 == None")
	endif
	
	
	if(ExtraData_Bools01 != None)
		bExtraDataFound = true
		int iThisLowest = HIGH_INT
		bool bIndexSequential = true
		
		int i = 0
		while(i < ExtraData_Bools01.Length && bIndexSequential)			
			if(i > 0)
				; We expect extra data to be in order from lowest index to highest, so if we find one out of order, we will have to search via FindStruct later instead of assuming an index
				if(ExtraData_Bools01[i].iIndex < ExtraData_Bools01[(i-1)].iIndex)
					;Debug.MessageBox("ExtraData_Bools01 are non-sequential")
					bIndexSequential = false
					
					; -1 will indicate the data has to be checked with FindStruct
					aiExtraDataIndexes[iExtraDataIndex_Bools01_NextObjectIndex] = iExtraDataValues_OutOfSequence
					aiExtraDataIndexes[iExtraDataIndex_Bools01_ExtraDataArrayIndex] = iExtraDataValues_OutOfSequence
				endif
			endif
			
			if(bIndexSequential && ExtraData_Bools01[i].iIndex <= iThisLowest)
				if(ExtraData_Bools01[i].iIndex < 0)
					;Debug.MessageBox("iIndex for ExtraData_Bools01 " + i + " is " + ExtraData_Bools01[i].iIndex)			
				endif
				
				;Debug.MessageBox("Setting iThisLowest for ExtraData_Bools01 to " + ExtraData_Bools01[i].iIndex)
				iThisLowest = ExtraData_Bools01[i].iIndex
			
				aiExtraDataIndexes[iExtraDataIndex_Bools01_NextObjectIndex] = iThisLowest
				aiExtraDataIndexes[iExtraDataIndex_Bools01_ExtraDataArrayIndex] = i
			endif
			
			i += 1
		endWhile

		if(bIndexSequential)
			if(iThisLowest != HIGH_INT && (iFirstFoundObjectIndex < 0 || iThisLowest < iFirstFoundObjectIndex))
				;Debug.MessageBox("Setting iFirstFoundObjectIndex to " + iThisLowest)
				iFirstFoundObjectIndex = iThisLowest
			endif
		else
			;Debug.MessageBox("ExtraData_Bools01 are non-sequential")
		endif
	else
		;Debug.MessageBox("ExtraData_Bools01 == None")
	endif
	
	if(ExtraData_Bools02 != None)
		bExtraDataFound = true
		int iThisLowest = HIGH_INT
		bool bIndexSequential = true
		
		int i = 0
		while(i < ExtraData_Bools02.Length && bIndexSequential)			
			if(i > 0)
				; We expect extra data to be in order from lowest index to highest, so if we find one out of order, we will have to search via FindStruct later instead of assuming an index
				if(ExtraData_Bools02[i].iIndex < ExtraData_Bools02[(i-1)].iIndex)
					;Debug.MessageBox("ExtraData_Bools02 are non-sequential")
					bIndexSequential = false
					
					; -1 will indicate the data has to be checked with FindStruct
					aiExtraDataIndexes[iExtraDataIndex_Bools02_NextObjectIndex] = iExtraDataValues_OutOfSequence
					aiExtraDataIndexes[iExtraDataIndex_Bools02_ExtraDataArrayIndex] = iExtraDataValues_OutOfSequence
				endif
			endif
			
			if(bIndexSequential && ExtraData_Bools02[i].iIndex <= iThisLowest)
				if(ExtraData_Bools02[i].iIndex < 0)
					;Debug.MessageBox("iIndex for ExtraData_Bools02 " + i + " is " + ExtraData_Bools02[i].iIndex)
				endif
				
				iThisLowest = ExtraData_Bools02[i].iIndex
			
				aiExtraDataIndexes[iExtraDataIndex_Bools02_NextObjectIndex] = iThisLowest
				aiExtraDataIndexes[iExtraDataIndex_Bools02_ExtraDataArrayIndex] = i
			endif
			
			i += 1
		endWhile
		
		if(bIndexSequential)
			if(iThisLowest != HIGH_INT && (iFirstFoundObjectIndex < 0 || iThisLowest < iFirstFoundObjectIndex))
				;Debug.MessageBox("Setting iFirstFoundObjectIndex to " + iThisLowest)
				iFirstFoundObjectIndex = iThisLowest
			endif
		else
			;Debug.MessageBox("ExtraData_Bools02 are non-sequential")
		endif
	else
		;Debug.MessageBox("ExtraData_Bools01 == None")
	endif
	
	if(ExtraData_Bools03 != None)
		bExtraDataFound = true
		int iThisLowest = HIGH_INT
		bool bIndexSequential = true
		
		int i = 0
		while(i < ExtraData_Bools03.Length && bIndexSequential)			
			if(i > 0)
				; We expect extra data to be in order from lowest index to highest, so if we find one out of order, we will have to search via FindStruct later instead of assuming an index
				if(ExtraData_Bools03[i].iIndex < ExtraData_Bools03[(i-1)].iIndex)
					;Debug.MessageBox("ExtraData_Bools03 are non-sequential")
					bIndexSequential = false
					
					; -1 will indicate the data has to be checked with FindStruct
					aiExtraDataIndexes[iExtraDataIndex_Bools03_NextObjectIndex] = iExtraDataValues_OutOfSequence
					aiExtraDataIndexes[iExtraDataIndex_Bools03_ExtraDataArrayIndex] = iExtraDataValues_OutOfSequence
				endif
			endif
			
			if(bIndexSequential && ExtraData_Bools03[i].iIndex <= iThisLowest)
				if(ExtraData_Bools03[i].iIndex < 0)
					;Debug.MessageBox("iIndex for ExtraData_Bools03 " + i + " is " + ExtraData_Bools03[i].iIndex)
				endif
				
				iThisLowest = ExtraData_Bools03[i].iIndex
			
				aiExtraDataIndexes[iExtraDataIndex_Bools03_NextObjectIndex] = iThisLowest
				aiExtraDataIndexes[iExtraDataIndex_Bools03_ExtraDataArrayIndex] = i
			endif
			
			i += 1
		endWhile
		
		if(bIndexSequential)
			if(iThisLowest != HIGH_INT && (iFirstFoundObjectIndex < 0 || iThisLowest < iFirstFoundObjectIndex))
				;Debug.MessageBox("Setting iFirstFoundObjectIndex to " + iThisLowest)
				iFirstFoundObjectIndex = iThisLowest
			endif
		else
			;Debug.MessageBox("ExtraData_Bools03 are non-sequential")
		endif
	else
		;Debug.MessageBox("ExtraData_Bools03 == None")
	endif
	
	;Debug.MessageBox("iFirstFoundObjectIndex = " + iFirstFoundObjectIndex)
	
	if(iFirstFoundObjectIndex < HIGH_INT && iFirstFoundObjectIndex >= 0)
		aiExtraDataIndexes[iExtraDataIndex_NextObjectIndex] = iFirstFoundObjectIndex
	elseif(bExtraDataFound)
		aiExtraDataIndexes[iExtraDataIndex_NextObjectIndex] = iExtraDataValues_OutOfSequence
	else
		aiExtraDataIndexes[iExtraDataIndex_NextObjectIndex] = iExtraDataValues_NoExtraDataFound
	endif
EndFunction



Function FillExtraData(WorkshopFramework:ObjectRefs:Thread_PlaceObject akThreadRef, Int[] aiExtraDataIndexes, Int aiCurrentIndex)
	Bool bSS2PlotFound = false
	Keyword PlotKeyword = Game.GetFormFromFile(0x000149A4, "SS2.esm") as Keyword
	if(PlotKeyword != None && akThreadRef.SpawnMe.HasKeyword(PlotKeyword))
		ModTrace("    FillExtraData called (aiCurrentIndex = " + aiCurrentIndex + ") for a thread (" + akThreadRef + ") that's going to spawn an SS2 plot (" + akThreadRef.SpawnMe + "), expecting building plan data...")
		bSS2PlotFound = true
	endif
	
	int iNewLowest = HIGH_INT
	
	if(ExtraData_Forms01 != None)
		if(bSS2PlotFound)
			ModTrace("         Found ExtraData_Forms01 entries. aiCurrentIndex = " + aiCurrentIndex + ", aiExtraDataIndexes[iExtraDataIndex_Forms01_NextObjectIndex] = " + aiExtraDataIndexes[iExtraDataIndex_Forms01_NextObjectIndex])
			;/
			ModTrace("             Other aiExtraDataIndexes:")
			int x = 0
			while(x < aiExtraDataIndexes.Length)
				ModTrace("               " + x + ": " + aiExtraDataIndexes[x])
				x += 1
			endWhile
			/;
		endif
		
		int iThisObjectIndex = iExtraDataIndex_Forms01_NextObjectIndex
		int iThisArrayIndex = iExtraDataIndex_Forms01_ExtraDataArrayIndex
		
		Form FoundForm = None
		Bool bMatchingEntryFound = false
		if(aiExtraDataIndexes[iThisObjectIndex] == aiCurrentIndex)
			; Match found
			bMatchingEntryFound = true
			FoundForm = GetIndexMappedUniversalForm(ExtraData_Forms01[aiExtraDataIndexes[iThisArrayIndex]])
			
			if(ExtraData_Forms01.Length > aiExtraDataIndexes[iThisArrayIndex] + 1)
				aiExtraDataIndexes[iThisArrayIndex] += 1
				aiExtraDataIndexes[iThisObjectIndex] = ExtraData_Forms01[aiExtraDataIndexes[iThisArrayIndex]].iIndex
				
				iNewLowest = aiExtraDataIndexes[iThisObjectIndex]
			else
				; Flag as finished
				aiExtraDataIndexes[iThisArrayIndex] = iExtraDataValues_AllDistributed
			endif			
		elseif(aiExtraDataIndexes[iExtraDataIndex_NextObjectIndex] == iExtraDataValues_OutOfSequence) ; Check if the broader array is set to Out of Sequence
			; Entries are out of order, so we need to use findstruct
			int iStructArrayIndex = ExtraData_Forms01.FindStruct("iIndex", aiCurrentIndex)
			if(iStructArrayIndex >= 0)
				FoundForm = GetIndexMappedUniversalForm(ExtraData_Forms01[iStructArrayIndex])
				bMatchingEntryFound = true
				
				if(ExtraData_Forms01.Length > iStructArrayIndex + 1)
					aiExtraDataIndexes[iThisArrayIndex] = iStructArrayIndex + 1
					aiExtraDataIndexes[iThisObjectIndex] = ExtraData_Forms01[aiExtraDataIndexes[iThisArrayIndex]].iIndex
					
					iNewLowest = aiExtraDataIndexes[iThisObjectIndex]
				else
					aiExtraDataIndexes[iThisArrayIndex] = iExtraDataValues_AllDistributed
					iNewLowest = iExtraDataValues_AllDistributed
				endif
			elseif(bSS2PlotFound)
				ModTrace("     Plot found, but no ExtraData_Forms01 found for index " + aiCurrentIndex)
				iNewLowest = iExtraDataValues_OutOfSequence
			else
				iNewLowest = iExtraDataValues_OutOfSequence
			endif
		endif
		
		if(FoundForm != None)
			ModTrace("    ExtraData_Forms01 entry " + FoundForm + " found for spawn thread " + aiCurrentIndex)
			akThreadRef.ExtraData_Form01 = FoundForm
			akThreadRef.ExtraData_Form01Set = true			
		else
			if(bSS2PlotFound && bMatchingEntryFound)
				ModTrace("         ExtraData_Forms01 index " + aiExtraDataIndexes[iThisArrayIndex] + " failed to return valid form via GetIndexMappedUniversalForm. aiCurrentIndex = " + aiCurrentIndex + ", aiExtraDataIndexes[" + iThisArrayIndex + "] = " + aiExtraDataIndexes[iThisArrayIndex] + ", ExtraData_Forms01[aiExtraDataIndexes[" + iThisArrayIndex + "]] = " + ExtraData_Forms01[aiExtraDataIndexes[iThisArrayIndex]])
			endif
		endif
	else
		if(bSS2PlotFound)
			ModTrace("         Failed to find ExtraData_Forms01 entry for a plot. aiCurrentIndex = " + aiCurrentIndex + ", aiExtraDataIndexes[iExtraDataIndex_Forms01_NextObjectIndex] = " + aiExtraDataIndexes[iExtraDataIndex_Forms01_NextObjectIndex])
		endif
	endif
	
	if(ExtraData_Forms02 != None)
		if(bSS2PlotFound)
			ModTrace("         Found ExtraData_Forms02 entry for a plot. aiCurrentIndex = " + aiCurrentIndex + ", aiExtraDataIndexes[iExtraDataIndex_Forms02_NextObjectIndex] = " + aiExtraDataIndexes[iExtraDataIndex_Forms02_NextObjectIndex])
		endif
		
		int iThisObjectIndex = iExtraDataIndex_Forms02_NextObjectIndex
		int iThisArrayIndex = iExtraDataIndex_Forms02_ExtraDataArrayIndex
		
		Form FoundForm = None
		Bool bMatchingEntryFound = false
		if(aiExtraDataIndexes[iThisObjectIndex] == aiCurrentIndex)
			; Match found
			bMatchingEntryFound = true
			FoundForm = GetIndexMappedUniversalForm(ExtraData_Forms02[aiExtraDataIndexes[iThisArrayIndex]])
			
			if(ExtraData_Forms02.Length > aiExtraDataIndexes[iThisArrayIndex] + 1)
				aiExtraDataIndexes[iThisArrayIndex] += 1
				aiExtraDataIndexes[iThisObjectIndex] = ExtraData_Forms02[aiExtraDataIndexes[iThisArrayIndex]].iIndex
				
				iNewLowest = aiExtraDataIndexes[iThisObjectIndex]
			else
				; Flag as finished
				aiExtraDataIndexes[iThisArrayIndex] = iExtraDataValues_AllDistributed
			endif			
		elseif(aiExtraDataIndexes[iExtraDataIndex_NextObjectIndex] == iExtraDataValues_OutOfSequence) ; Check if the broader array is set to Out of Sequence
			; Entries are out of order, so we need to use findstruct
			int iStructArrayIndex = ExtraData_Forms02.FindStruct("iIndex", aiCurrentIndex)
			if(iStructArrayIndex >= 0)
				FoundForm = GetIndexMappedUniversalForm(ExtraData_Forms02[iStructArrayIndex])
				bMatchingEntryFound = true
				
				if(ExtraData_Forms02.Length > iStructArrayIndex + 1)
					aiExtraDataIndexes[iThisArrayIndex] = iStructArrayIndex + 1
					aiExtraDataIndexes[iThisObjectIndex] = ExtraData_Forms02[aiExtraDataIndexes[iThisArrayIndex]].iIndex
					
					iNewLowest = aiExtraDataIndexes[iThisObjectIndex]
				else
					aiExtraDataIndexes[iThisArrayIndex] = iExtraDataValues_AllDistributed
					iNewLowest = iExtraDataValues_AllDistributed
				endif
			elseif(bSS2PlotFound)
				ModTrace("     Plot found, but no ExtraData_Forms02 found for index " + aiCurrentIndex)
				iNewLowest = iExtraDataValues_OutOfSequence
			else
				iNewLowest = iExtraDataValues_OutOfSequence
			endif
		endif
		
		if(FoundForm != None)
			ModTrace("    ExtraData_Forms02 entry " + FoundForm + " found for spawn thread " + aiCurrentIndex)
			akThreadRef.ExtraData_Form02 = FoundForm
			akThreadRef.ExtraData_Form02Set = true			
		else
			if(bSS2PlotFound && bMatchingEntryFound)
				ModTrace("         ExtraData_Forms02 index " + aiExtraDataIndexes[iThisArrayIndex] + " failed to return valid form via GetIndexMappedUniversalForm. aiCurrentIndex = " + aiCurrentIndex + ", aiExtraDataIndexes[" + iThisArrayIndex + "] = " + aiExtraDataIndexes[iThisArrayIndex] + ", ExtraData_Forms02[aiExtraDataIndexes[" + iThisArrayIndex + "]] = " + ExtraData_Forms02[aiExtraDataIndexes[iThisArrayIndex]])
			endif
		endif
	else
		if(bSS2PlotFound)
			ModTrace("         Failed to find ExtraData_Forms02 entry for a plot. aiCurrentIndex = " + aiCurrentIndex + ", aiExtraDataIndexes[iExtraDataIndex_Forms02_NextObjectIndex] = " + aiExtraDataIndexes[iExtraDataIndex_Forms02_NextObjectIndex])
		endif
	endif
	
	if(ExtraData_Forms03 != None)
		if(bSS2PlotFound)
			ModTrace("         Found ExtraData_Forms03 entry for a plot. aiCurrentIndex = " + aiCurrentIndex + ", aiExtraDataIndexes[iExtraDataIndex_Forms03_NextObjectIndex] = " + aiExtraDataIndexes[iExtraDataIndex_Forms03_NextObjectIndex])
		endif
		
		int iThisObjectIndex = iExtraDataIndex_Forms03_NextObjectIndex
		int iThisArrayIndex = iExtraDataIndex_Forms03_ExtraDataArrayIndex
		
		Form FoundForm = None
		Bool bMatchingEntryFound = false
		if(aiExtraDataIndexes[iThisObjectIndex] == aiCurrentIndex)
			; Match found
			bMatchingEntryFound = true
			FoundForm = GetIndexMappedUniversalForm(ExtraData_Forms03[aiExtraDataIndexes[iThisArrayIndex]])
			
			if(ExtraData_Forms03.Length > aiExtraDataIndexes[iThisArrayIndex] + 1)
				aiExtraDataIndexes[iThisArrayIndex] += 1
				aiExtraDataIndexes[iThisObjectIndex] = ExtraData_Forms03[aiExtraDataIndexes[iThisArrayIndex]].iIndex
				
				iNewLowest = aiExtraDataIndexes[iThisObjectIndex]
			else
				; Flag as finished
				aiExtraDataIndexes[iThisArrayIndex] = iExtraDataValues_AllDistributed
			endif			
		elseif(aiExtraDataIndexes[iExtraDataIndex_NextObjectIndex] == iExtraDataValues_OutOfSequence) ; Check if the broader array is set to Out of Sequence
			; Entries are out of order, so we need to use findstruct
			int iStructArrayIndex = ExtraData_Forms03.FindStruct("iIndex", aiCurrentIndex)
			if(iStructArrayIndex >= 0)
				FoundForm = GetIndexMappedUniversalForm(ExtraData_Forms03[iStructArrayIndex])
				bMatchingEntryFound = true
				
				if(ExtraData_Forms03.Length > iStructArrayIndex + 1)
					aiExtraDataIndexes[iThisArrayIndex] = iStructArrayIndex + 1
					aiExtraDataIndexes[iThisObjectIndex] = ExtraData_Forms03[aiExtraDataIndexes[iThisArrayIndex]].iIndex
					
					iNewLowest = aiExtraDataIndexes[iThisObjectIndex]
				else
					aiExtraDataIndexes[iThisArrayIndex] = iExtraDataValues_AllDistributed
					iNewLowest = iExtraDataValues_AllDistributed
				endif
			elseif(bSS2PlotFound)
				ModTrace("     Plot found, but no ExtraData_Forms03 found for index " + aiCurrentIndex)
				iNewLowest = iExtraDataValues_OutOfSequence
			else
				iNewLowest = iExtraDataValues_OutOfSequence
			endif
		endif
		
		if(FoundForm != None)
			ModTrace("    ExtraData_Forms03 entry " + FoundForm + " found for spawn thread " + aiCurrentIndex)
			akThreadRef.ExtraData_Form03 = FoundForm
			akThreadRef.ExtraData_Form03Set = true			
		else
			if(bSS2PlotFound && bMatchingEntryFound)
				ModTrace("         ExtraData_Forms03 index " + aiExtraDataIndexes[iThisArrayIndex] + " failed to return valid form via GetIndexMappedUniversalForm. aiCurrentIndex = " + aiCurrentIndex + ", aiExtraDataIndexes[" + iThisArrayIndex + "] = " + aiExtraDataIndexes[iThisArrayIndex] + ", ExtraData_Forms03[aiExtraDataIndexes[" + iThisArrayIndex + "]] = " + ExtraData_Forms03[aiExtraDataIndexes[iThisArrayIndex]])
			endif
		endif
	else
		if(bSS2PlotFound)
			ModTrace("         Failed to find ExtraData_Forms03 entry for a plot. aiCurrentIndex = " + aiCurrentIndex + ", aiExtraDataIndexes[iExtraDataIndex_Forms03_NextObjectIndex] = " + aiExtraDataIndexes[iExtraDataIndex_Forms03_NextObjectIndex])
		endif
	endif
	
	if(ExtraData_Numbers01 != None)
		if(bSS2PlotFound)
			ModTrace("         Found ExtraData_Numbers01 entry for a plot. aiCurrentIndex = " + aiCurrentIndex + ", aiExtraDataIndexes[iExtraDataIndex_Numbers01_NextObjectIndex] = " + aiExtraDataIndexes[iExtraDataIndex_Numbers01_NextObjectIndex])
		endif
		
		int iThisObjectIndex = iExtraDataIndex_Numbers01_NextObjectIndex
		int iThisArrayIndex = iExtraDataIndex_Numbers01_ExtraDataArrayIndex
		
		Float FoundValue = HIGH_INT
		Bool bMatchingEntryFound = false
		if(aiExtraDataIndexes[iThisObjectIndex] == aiCurrentIndex)
			; Match found
			bMatchingEntryFound = true
			FoundValue = ExtraData_Numbers01[aiExtraDataIndexes[iThisArrayIndex]].fNumber
			
			if(ExtraData_Numbers01.Length > aiExtraDataIndexes[iThisArrayIndex] + 1)
				aiExtraDataIndexes[iThisArrayIndex] += 1
				aiExtraDataIndexes[iThisObjectIndex] = ExtraData_Numbers01[aiExtraDataIndexes[iThisArrayIndex]].iIndex
				
				iNewLowest = aiExtraDataIndexes[iThisObjectIndex]
			else
				; Flag as finished
				aiExtraDataIndexes[iThisArrayIndex] = iExtraDataValues_AllDistributed
			endif			
		elseif(aiExtraDataIndexes[iExtraDataIndex_NextObjectIndex] == iExtraDataValues_OutOfSequence) ; Check if the broader array is set to Out of Sequence
			; Entries are out of order, so we need to use findstruct
			int iStructArrayIndex = ExtraData_Numbers01.FindStruct("iIndex", aiCurrentIndex)
			if(iStructArrayIndex >= 0)
				FoundValue = ExtraData_Numbers01[iStructArrayIndex].fNumber
				bMatchingEntryFound = true
				
				if(ExtraData_Numbers01.Length > iStructArrayIndex + 1)
					aiExtraDataIndexes[iThisArrayIndex] = iStructArrayIndex + 1
					aiExtraDataIndexes[iThisObjectIndex] = ExtraData_Numbers01[aiExtraDataIndexes[iThisArrayIndex]].iIndex
					
					iNewLowest = aiExtraDataIndexes[iThisObjectIndex]				
				else
					aiExtraDataIndexes[iThisArrayIndex] = iExtraDataValues_AllDistributed
					iNewLowest = iExtraDataValues_AllDistributed
				endif
			elseif(bSS2PlotFound)
				ModTrace("     Plot found, but no ExtraData_Numbers01 found for index " + aiCurrentIndex)
				iNewLowest = iExtraDataValues_OutOfSequence
			else
				iNewLowest = iExtraDataValues_OutOfSequence
			endif
		endif
		
		if(FoundValue != HIGH_INT)
			ModTrace("    ExtraData_Numbers01 entry " + FoundValue + " found for spawn thread " + aiCurrentIndex)
			akThreadRef.ExtraData_Number01 = FoundValue
			akThreadRef.ExtraData_Number01Set = true			
		else
			if(bSS2PlotFound && bMatchingEntryFound)
				ModTrace("         ExtraData_Numbers01 index " + aiExtraDataIndexes[iThisArrayIndex] + " failed to return valid form via GetIndexMappedUniversalForm. aiCurrentIndex = " + aiCurrentIndex + ", aiExtraDataIndexes[" + iThisArrayIndex + "] = " + aiExtraDataIndexes[iThisArrayIndex] + ", ExtraData_Numbers01[aiExtraDataIndexes[" + iThisArrayIndex + "]] = " + ExtraData_Numbers01[aiExtraDataIndexes[iThisArrayIndex]])
			endif
		endif
	else
		if(bSS2PlotFound)
			ModTrace("         Failed to find ExtraData_Numbers01 entry for a plot. aiCurrentIndex = " + aiCurrentIndex + ", aiExtraDataIndexes[iExtraDataIndex_Numbers01_NextObjectIndex] = " + aiExtraDataIndexes[iExtraDataIndex_Numbers01_NextObjectIndex])
		endif
	endif
	
	if(ExtraData_Numbers02 != None)
		if(bSS2PlotFound)
			ModTrace("         Found ExtraData_Numbers02 entry for a plot. aiCurrentIndex = " + aiCurrentIndex + ", aiExtraDataIndexes[iExtraDataIndex_Numbers02_NextObjectIndex] = " + aiExtraDataIndexes[iExtraDataIndex_Numbers02_NextObjectIndex])
		endif
		
		int iThisObjectIndex = iExtraDataIndex_Numbers02_NextObjectIndex
		int iThisArrayIndex = iExtraDataIndex_Numbers02_ExtraDataArrayIndex
		
		Float FoundValue = HIGH_INT
		Bool bMatchingEntryFound = false
		if(aiExtraDataIndexes[iThisObjectIndex] == aiCurrentIndex)
			; Match found
			bMatchingEntryFound = true
			FoundValue = ExtraData_Numbers02[aiExtraDataIndexes[iThisArrayIndex]].fNumber
			
			if(ExtraData_Numbers02.Length > aiExtraDataIndexes[iThisArrayIndex] + 1)
				aiExtraDataIndexes[iThisArrayIndex] += 1
				aiExtraDataIndexes[iThisObjectIndex] = ExtraData_Numbers02[aiExtraDataIndexes[iThisArrayIndex]].iIndex
				
				iNewLowest = aiExtraDataIndexes[iThisObjectIndex]
			else
				; Flag as finished
				aiExtraDataIndexes[iThisArrayIndex] = iExtraDataValues_AllDistributed
			endif			
		elseif(aiExtraDataIndexes[iExtraDataIndex_NextObjectIndex] == iExtraDataValues_OutOfSequence) ; Check if the broader array is set to Out of Sequence
			; Entries are out of order, so we need to use findstruct
			int iStructArrayIndex = ExtraData_Numbers02.FindStruct("iIndex", aiCurrentIndex)
			if(iStructArrayIndex >= 0)
				FoundValue = ExtraData_Numbers02[iStructArrayIndex].fNumber
				bMatchingEntryFound = true
				
				if(ExtraData_Numbers02.Length > iStructArrayIndex + 1)
					aiExtraDataIndexes[iThisArrayIndex] = iStructArrayIndex + 1
					aiExtraDataIndexes[iThisObjectIndex] = ExtraData_Numbers02[aiExtraDataIndexes[iThisArrayIndex]].iIndex
					
					iNewLowest = aiExtraDataIndexes[iThisObjectIndex]
				else
					aiExtraDataIndexes[iThisArrayIndex] = iExtraDataValues_AllDistributed
					iNewLowest = iExtraDataValues_AllDistributed
				endif
			elseif(bSS2PlotFound)
				ModTrace("     Plot found, but no ExtraData_Numbers02 found for index " + aiCurrentIndex)
				iNewLowest = iExtraDataValues_OutOfSequence
			else
				iNewLowest = iExtraDataValues_OutOfSequence
			endif
		endif
		
		if(FoundValue != HIGH_INT)
			ModTrace("    ExtraData_Numbers02 entry " + FoundValue + " found for spawn thread " + aiCurrentIndex)
			akThreadRef.ExtraData_Number02 = FoundValue
			akThreadRef.ExtraData_Number02Set = true			
		else
			if(bSS2PlotFound && bMatchingEntryFound)
				ModTrace("         ExtraData_Numbers02 index " + aiExtraDataIndexes[iThisArrayIndex] + " failed to return valid form via GetIndexMappedUniversalForm. aiCurrentIndex = " + aiCurrentIndex + ", aiExtraDataIndexes[" + iThisArrayIndex + "] = " + aiExtraDataIndexes[iThisArrayIndex] + ", ExtraData_Numbers02[aiExtraDataIndexes[" + iThisArrayIndex + "]] = " + ExtraData_Numbers02[aiExtraDataIndexes[iThisArrayIndex]])
			endif
		endif
	else
		if(bSS2PlotFound)
			ModTrace("         Failed to find ExtraData_Numbers02 entry for a plot. aiCurrentIndex = " + aiCurrentIndex + ", aiExtraDataIndexes[iExtraDataIndex_Numbers02_NextObjectIndex] = " + aiExtraDataIndexes[iExtraDataIndex_Numbers02_NextObjectIndex])
		endif
	endif
	
	if(ExtraData_Numbers03 != None)
		if(bSS2PlotFound)
			ModTrace("         Found ExtraData_Numbers03 entry for a plot. aiCurrentIndex = " + aiCurrentIndex + ", aiExtraDataIndexes[iExtraDataIndex_Numbers03_NextObjectIndex] = " + aiExtraDataIndexes[iExtraDataIndex_Numbers03_NextObjectIndex])
		endif
		
		int iThisObjectIndex = iExtraDataIndex_Numbers03_NextObjectIndex
		int iThisArrayIndex = iExtraDataIndex_Numbers03_ExtraDataArrayIndex
		
		Float FoundValue = HIGH_INT
		Bool bMatchingEntryFound = false
		if(aiExtraDataIndexes[iThisObjectIndex] == aiCurrentIndex)
			; Match found
			bMatchingEntryFound = true
			FoundValue = ExtraData_Numbers03[aiExtraDataIndexes[iThisArrayIndex]].fNumber
			
			if(ExtraData_Numbers03.Length > aiExtraDataIndexes[iThisArrayIndex] + 1)
				aiExtraDataIndexes[iThisArrayIndex] += 1
				aiExtraDataIndexes[iThisObjectIndex] = ExtraData_Numbers03[aiExtraDataIndexes[iThisArrayIndex]].iIndex
				
				iNewLowest = aiExtraDataIndexes[iThisObjectIndex]
			else
				; Flag as finished
				aiExtraDataIndexes[iThisArrayIndex] = iExtraDataValues_AllDistributed
			endif			
		elseif(aiExtraDataIndexes[iExtraDataIndex_NextObjectIndex] == iExtraDataValues_OutOfSequence) ; Check if the broader array is set to Out of Sequence
			; Entries are out of order, so we need to use findstruct
			int iStructArrayIndex = ExtraData_Numbers03.FindStruct("iIndex", aiCurrentIndex)
			if(iStructArrayIndex >= 0)
				FoundValue = ExtraData_Numbers03[iStructArrayIndex].fNumber
				bMatchingEntryFound = true
				
				if(ExtraData_Numbers03.Length > iStructArrayIndex + 1)
					aiExtraDataIndexes[iThisArrayIndex] = iStructArrayIndex + 1
					aiExtraDataIndexes[iThisObjectIndex] = ExtraData_Numbers03[aiExtraDataIndexes[iThisArrayIndex]].iIndex
					
					iNewLowest = aiExtraDataIndexes[iThisObjectIndex]
				else
					aiExtraDataIndexes[iThisArrayIndex] = iExtraDataValues_AllDistributed
					iNewLowest = iExtraDataValues_AllDistributed
				endif
			elseif(bSS2PlotFound)
				ModTrace("     Plot found, but no ExtraData_Numbers03 found for index " + aiCurrentIndex)
				iNewLowest = iExtraDataValues_OutOfSequence
			else
				iNewLowest = iExtraDataValues_OutOfSequence
			endif
		endif
		
		if(FoundValue != HIGH_INT)
			ModTrace("    ExtraData_Numbers03 entry " + FoundValue + " found for spawn thread " + aiCurrentIndex)
			akThreadRef.ExtraData_Number03 = FoundValue
			akThreadRef.ExtraData_Number03Set = true			
		else
			if(bSS2PlotFound && bMatchingEntryFound)
				ModTrace("         ExtraData_Numbers03 index " + aiExtraDataIndexes[iThisArrayIndex] + " failed to return valid form via GetIndexMappedUniversalForm. aiCurrentIndex = " + aiCurrentIndex + ", aiExtraDataIndexes[" + iThisArrayIndex + "] = " + aiExtraDataIndexes[iThisArrayIndex] + ", ExtraData_Numbers03[aiExtraDataIndexes[" + iThisArrayIndex + "]] = " + ExtraData_Numbers03[aiExtraDataIndexes[iThisArrayIndex]])
			endif
		endif
	else
		if(bSS2PlotFound)
			ModTrace("         Failed to find ExtraData_Numbers03 entry for a plot. aiCurrentIndex = " + aiCurrentIndex + ", aiExtraDataIndexes[iExtraDataIndex_Numbers03_NextObjectIndex] = " + aiExtraDataIndexes[iExtraDataIndex_Numbers03_NextObjectIndex])
		endif
	endif
	
	if(ExtraData_Strings01 != None)
		if(bSS2PlotFound)
			ModTrace("         Found ExtraData_Strings01 entry for a plot. aiCurrentIndex = " + aiCurrentIndex + ", aiExtraDataIndexes[iExtraDataIndex_Strings01_NextObjectIndex] = " + aiExtraDataIndexes[iExtraDataIndex_Strings01_NextObjectIndex])
		endif
		
		int iThisObjectIndex = iExtraDataIndex_Strings01_NextObjectIndex
		int iThisArrayIndex = iExtraDataIndex_Strings01_ExtraDataArrayIndex
		
		String FoundString = ""
		Bool bMatchingEntryFound = false
		if(aiExtraDataIndexes[iThisObjectIndex] == aiCurrentIndex)
			; Match found
			bMatchingEntryFound = true
			FoundString = ExtraData_Strings01[aiExtraDataIndexes[iThisArrayIndex]].sString
			
			if(ExtraData_Strings01.Length > aiExtraDataIndexes[iThisArrayIndex] + 1)
				aiExtraDataIndexes[iThisArrayIndex] += 1
				aiExtraDataIndexes[iThisObjectIndex] = ExtraData_Strings01[aiExtraDataIndexes[iThisArrayIndex]].iIndex
				
				iNewLowest = aiExtraDataIndexes[iThisObjectIndex]
			else
				; Flag as finished
				aiExtraDataIndexes[iThisArrayIndex] = iExtraDataValues_AllDistributed
			endif			
		elseif(aiExtraDataIndexes[iExtraDataIndex_NextObjectIndex] == iExtraDataValues_OutOfSequence) ; Check if the broader array is set to Out of Sequence
			; Entries are out of order, so we need to use findstruct
			int iStructArrayIndex = ExtraData_Strings01.FindStruct("iIndex", aiCurrentIndex)
			if(iStructArrayIndex >= 0)
				FoundString = ExtraData_Strings01[iStructArrayIndex].sString
				bMatchingEntryFound = true
				
				if(ExtraData_Strings01.Length > iStructArrayIndex + 1)
					aiExtraDataIndexes[iThisArrayIndex] = iStructArrayIndex + 1
					aiExtraDataIndexes[iThisObjectIndex] = ExtraData_Strings01[aiExtraDataIndexes[iThisArrayIndex]].iIndex
					
					iNewLowest = aiExtraDataIndexes[iThisObjectIndex]
				else
					aiExtraDataIndexes[iThisArrayIndex] = iExtraDataValues_AllDistributed
					iNewLowest = iExtraDataValues_AllDistributed
				endif
			elseif(bSS2PlotFound)
				ModTrace("     Plot found, but no ExtraData_Strings01 found for index " + aiCurrentIndex)
				iNewLowest = iExtraDataValues_OutOfSequence
			else
				iNewLowest = iExtraDataValues_OutOfSequence
			endif
		endif
		
		if(FoundString != "")
			ModTrace("    ExtraData_Strings01 entry " + FoundString + " found for spawn thread " + aiCurrentIndex)
			akThreadRef.ExtraData_String01 = FoundString
			akThreadRef.ExtraData_String01Set = true			
		else
			if(bSS2PlotFound && bMatchingEntryFound)
				ModTrace("         ExtraData_Strings01 index " + aiExtraDataIndexes[iThisArrayIndex] + " failed to return valid form via GetIndexMappedUniversalForm. aiCurrentIndex = " + aiCurrentIndex + ", aiExtraDataIndexes[" + iThisArrayIndex + "] = " + aiExtraDataIndexes[iThisArrayIndex] + ", ExtraData_Strings01[aiExtraDataIndexes[" + iThisArrayIndex + "]] = " + ExtraData_Strings01[aiExtraDataIndexes[iThisArrayIndex]])
			endif
		endif
	else
		if(bSS2PlotFound)
			ModTrace("         Failed to find ExtraData_Strings01 entry for a plot. aiCurrentIndex = " + aiCurrentIndex + ", aiExtraDataIndexes[iExtraDataIndex_Strings01_NextObjectIndex] = " + aiExtraDataIndexes[iExtraDataIndex_Strings01_NextObjectIndex])
		endif
	endif
	
	if(ExtraData_Strings02 != None)
		if(bSS2PlotFound)
			ModTrace("         Found ExtraData_Strings02 entry for a plot. aiCurrentIndex = " + aiCurrentIndex + ", aiExtraDataIndexes[iExtraDataIndex_Strings02_NextObjectIndex] = " + aiExtraDataIndexes[iExtraDataIndex_Strings02_NextObjectIndex])
		endif
		
		int iThisObjectIndex = iExtraDataIndex_Strings02_NextObjectIndex
		int iThisArrayIndex = iExtraDataIndex_Strings02_ExtraDataArrayIndex
		
		String FoundString = ""
		Bool bMatchingEntryFound = false
		if(aiExtraDataIndexes[iThisObjectIndex] == aiCurrentIndex)
			; Match found
			bMatchingEntryFound = true
			FoundString = ExtraData_Strings02[aiExtraDataIndexes[iThisArrayIndex]].sString
			
			if(ExtraData_Strings02.Length > aiExtraDataIndexes[iThisArrayIndex] + 1)
				aiExtraDataIndexes[iThisArrayIndex] += 1
				aiExtraDataIndexes[iThisObjectIndex] = ExtraData_Strings02[aiExtraDataIndexes[iThisArrayIndex]].iIndex
				
				iNewLowest = aiExtraDataIndexes[iThisObjectIndex]
			else
				; Flag as finished
				aiExtraDataIndexes[iThisArrayIndex] = iExtraDataValues_AllDistributed
			endif			
		elseif(aiExtraDataIndexes[iExtraDataIndex_NextObjectIndex] == iExtraDataValues_OutOfSequence) ; Check if the broader array is set to Out of Sequence
			; Entries are out of order, so we need to use findstruct
			int iStructArrayIndex = ExtraData_Strings02.FindStruct("iIndex", aiCurrentIndex)
			if(iStructArrayIndex >= 0)
				FoundString = ExtraData_Strings02[iStructArrayIndex].sString
				bMatchingEntryFound = true
				
				if(ExtraData_Strings02.Length > iStructArrayIndex + 1)
					aiExtraDataIndexes[iThisArrayIndex] = iStructArrayIndex + 1
					aiExtraDataIndexes[iThisObjectIndex] = ExtraData_Strings02[aiExtraDataIndexes[iThisArrayIndex]].iIndex
					
					iNewLowest = aiExtraDataIndexes[iThisObjectIndex]
				else
					aiExtraDataIndexes[iThisArrayIndex] = iExtraDataValues_AllDistributed
					iNewLowest = iExtraDataValues_AllDistributed
				endif
			elseif(bSS2PlotFound)
				ModTrace("     Plot found, but no ExtraData_Strings02 found for index " + aiCurrentIndex)
				iNewLowest = iExtraDataValues_OutOfSequence
			else
				iNewLowest = iExtraDataValues_OutOfSequence
			endif
		endif
		
		if(FoundString != "")
			ModTrace("    ExtraData_Strings02 entry " + FoundString + " found for spawn thread " + aiCurrentIndex)
			akThreadRef.ExtraData_String02 = FoundString
			akThreadRef.ExtraData_String02Set = true			
		else
			if(bSS2PlotFound && bMatchingEntryFound)
				ModTrace("         ExtraData_Strings02 index " + aiExtraDataIndexes[iThisArrayIndex] + " failed to return valid form via GetIndexMappedUniversalForm. aiCurrentIndex = " + aiCurrentIndex + ", aiExtraDataIndexes[" + iThisArrayIndex + "] = " + aiExtraDataIndexes[iThisArrayIndex] + ", ExtraData_Strings02[aiExtraDataIndexes[" + iThisArrayIndex + "]] = " + ExtraData_Strings02[aiExtraDataIndexes[iThisArrayIndex]])
			endif
		endif
	else
		if(bSS2PlotFound)
			ModTrace("         Failed to find ExtraData_Strings02 entry for a plot. aiCurrentIndex = " + aiCurrentIndex + ", aiExtraDataIndexes[iExtraDataIndex_Strings02_NextObjectIndex] = " + aiExtraDataIndexes[iExtraDataIndex_Strings02_NextObjectIndex])
		endif
	endif
	
	if(ExtraData_Strings03 != None)
		if(bSS2PlotFound)
			ModTrace("         Found ExtraData_Strings03 entry for a plot. aiCurrentIndex = " + aiCurrentIndex + ", aiExtraDataIndexes[iExtraDataIndex_Strings03_NextObjectIndex] = " + aiExtraDataIndexes[iExtraDataIndex_Strings03_NextObjectIndex])
		endif
		
		int iThisObjectIndex = iExtraDataIndex_Strings03_NextObjectIndex
		int iThisArrayIndex = iExtraDataIndex_Strings03_ExtraDataArrayIndex
		
		String FoundString = ""
		Bool bMatchingEntryFound = false
		if(aiExtraDataIndexes[iThisObjectIndex] == aiCurrentIndex)
			; Match found
			bMatchingEntryFound = true
			FoundString = ExtraData_Strings03[aiExtraDataIndexes[iThisArrayIndex]].sString
			
			if(ExtraData_Strings03.Length > aiExtraDataIndexes[iThisArrayIndex] + 1)
				aiExtraDataIndexes[iThisArrayIndex] += 1
				aiExtraDataIndexes[iThisObjectIndex] = ExtraData_Strings03[aiExtraDataIndexes[iThisArrayIndex]].iIndex
				
				iNewLowest = aiExtraDataIndexes[iThisObjectIndex]
			else
				; Flag as finished
				aiExtraDataIndexes[iThisArrayIndex] = iExtraDataValues_AllDistributed
			endif			
		elseif(aiExtraDataIndexes[iExtraDataIndex_NextObjectIndex] == iExtraDataValues_OutOfSequence) ; Check if the broader array is set to Out of Sequence
			; Entries are out of order, so we need to use findstruct
			int iStructArrayIndex = ExtraData_Strings03.FindStruct("iIndex", aiCurrentIndex)
			if(iStructArrayIndex >= 0)
				FoundString = ExtraData_Strings03[iStructArrayIndex].sString
				bMatchingEntryFound = true
				
				if(ExtraData_Strings03.Length > iStructArrayIndex + 1)
					aiExtraDataIndexes[iThisArrayIndex] = iStructArrayIndex + 1
					aiExtraDataIndexes[iThisObjectIndex] = ExtraData_Strings03[aiExtraDataIndexes[iThisArrayIndex]].iIndex
					
					iNewLowest = aiExtraDataIndexes[iThisObjectIndex]
				else
					aiExtraDataIndexes[iThisArrayIndex] = iExtraDataValues_AllDistributed
					iNewLowest = iExtraDataValues_AllDistributed
				endif
			elseif(bSS2PlotFound)
				ModTrace("     Plot found, but no ExtraData_Strings03 found for index " + aiCurrentIndex)
				iNewLowest = iExtraDataValues_OutOfSequence
			else
				iNewLowest = iExtraDataValues_OutOfSequence
			endif
		endif
		
		if(FoundString != "")
			ModTrace("    ExtraData_Strings03 entry " + FoundString + " found for spawn thread " + aiCurrentIndex)
			akThreadRef.ExtraData_String03 = FoundString
			akThreadRef.ExtraData_String03Set = true			
		else
			if(bSS2PlotFound && bMatchingEntryFound)
				ModTrace("         ExtraData_Strings03 index " + aiExtraDataIndexes[iThisArrayIndex] + " failed to return valid form via GetIndexMappedUniversalForm. aiCurrentIndex = " + aiCurrentIndex + ", aiExtraDataIndexes[" + iThisArrayIndex + "] = " + aiExtraDataIndexes[iThisArrayIndex] + ", ExtraData_Strings03[aiExtraDataIndexes[" + iThisArrayIndex + "]] = " + ExtraData_Strings03[aiExtraDataIndexes[iThisArrayIndex]])
			endif
		endif
	else
		if(bSS2PlotFound)
			ModTrace("         Failed to find ExtraData_Strings03 entry for a plot. aiCurrentIndex = " + aiCurrentIndex + ", aiExtraDataIndexes[iExtraDataIndex_Strings03_NextObjectIndex] = " + aiExtraDataIndexes[iExtraDataIndex_Strings03_NextObjectIndex])
		endif
	endif
	
	if(ExtraData_Bools01 != None)
		if(bSS2PlotFound)
			ModTrace("         Found ExtraData_Bools01 entry for a plot. aiCurrentIndex = " + aiCurrentIndex + ", aiExtraDataIndexes[iExtraDataIndex_Bools01_NextObjectIndex] = " + aiExtraDataIndexes[iExtraDataIndex_Bools01_NextObjectIndex])
		endif
		
		int iThisObjectIndex = iExtraDataIndex_Bools01_NextObjectIndex
		int iThisArrayIndex = iExtraDataIndex_Bools01_ExtraDataArrayIndex
		
		Int FoundBoolTest = -1
		Bool bMatchingEntryFound = false
		if(aiExtraDataIndexes[iThisObjectIndex] == aiCurrentIndex)
			; Match found
			bMatchingEntryFound = true
			FoundBoolTest = ExtraData_Bools01[aiExtraDataIndexes[iThisArrayIndex]].bBool as Int
			
			if(ExtraData_Bools01.Length > aiExtraDataIndexes[iThisArrayIndex] + 1)
				aiExtraDataIndexes[iThisArrayIndex] += 1
				aiExtraDataIndexes[iThisObjectIndex] = ExtraData_Bools01[aiExtraDataIndexes[iThisArrayIndex]].iIndex
				
				iNewLowest = aiExtraDataIndexes[iThisObjectIndex]
			else
				; Flag as finished
				aiExtraDataIndexes[iThisArrayIndex] = iExtraDataValues_AllDistributed
			endif			
		elseif(aiExtraDataIndexes[iExtraDataIndex_NextObjectIndex] == iExtraDataValues_OutOfSequence) ; Check if the broader array is set to Out of Sequence
			; Entries are out of order, so we need to use findstruct
			int iStructArrayIndex = ExtraData_Bools01.FindStruct("iIndex", aiCurrentIndex)
			if(iStructArrayIndex >= 0)
				FoundBoolTest = ExtraData_Bools01[iStructArrayIndex].bBool as Int
				bMatchingEntryFound = true
				
				if(ExtraData_Bools01.Length > iStructArrayIndex + 1)
					aiExtraDataIndexes[iThisArrayIndex] = iStructArrayIndex + 1
					aiExtraDataIndexes[iThisObjectIndex] = ExtraData_Bools01[aiExtraDataIndexes[iThisArrayIndex]].iIndex
					
					iNewLowest = aiExtraDataIndexes[iThisObjectIndex]
				else
					aiExtraDataIndexes[iThisArrayIndex] = iExtraDataValues_AllDistributed
					iNewLowest = iExtraDataValues_AllDistributed
				endif
			elseif(bSS2PlotFound)
				ModTrace("     Plot found, but no ExtraData_Bools01 found for index " + aiCurrentIndex)
				iNewLowest = iExtraDataValues_OutOfSequence
			else
				iNewLowest = iExtraDataValues_OutOfSequence
			endif
		endif
		
		if(FoundBoolTest != -1)
			ModTrace("    ExtraData_Bools01 entry " + FoundBoolTest + " found for spawn thread " + aiCurrentIndex)
			akThreadRef.ExtraData_Bool01 = FoundBoolTest as Bool
			akThreadRef.ExtraData_Bool01Set = true			
		else
			if(bSS2PlotFound && bMatchingEntryFound)
				ModTrace("         ExtraData_Bools01 index " + aiExtraDataIndexes[iThisArrayIndex] + " failed to return valid form via GetIndexMappedUniversalForm. aiCurrentIndex = " + aiCurrentIndex + ", aiExtraDataIndexes[" + iThisArrayIndex + "] = " + aiExtraDataIndexes[iThisArrayIndex] + ", ExtraData_Bools01[aiExtraDataIndexes[" + iThisArrayIndex + "]] = " + ExtraData_Bools01[aiExtraDataIndexes[iThisArrayIndex]])
			endif
		endif
	else
		if(bSS2PlotFound)
			ModTrace("         Failed to find ExtraData_Bools01 entry for a plot. aiCurrentIndex = " + aiCurrentIndex + ", aiExtraDataIndexes[iExtraDataIndex_Bools01_NextObjectIndex] = " + aiExtraDataIndexes[iExtraDataIndex_Bools01_NextObjectIndex])
		endif
	endif
	
	if(ExtraData_Bools02 != None)
		if(bSS2PlotFound)
			ModTrace("         Found ExtraData_Bools02 entry for a plot. aiCurrentIndex = " + aiCurrentIndex + ", aiExtraDataIndexes[iExtraDataIndex_Bools02_NextObjectIndex] = " + aiExtraDataIndexes[iExtraDataIndex_Bools02_NextObjectIndex])
		endif
		
		int iThisObjectIndex = iExtraDataIndex_Bools02_NextObjectIndex
		int iThisArrayIndex = iExtraDataIndex_Bools02_ExtraDataArrayIndex
		
		Int FoundBoolTest = -1
		Bool bMatchingEntryFound = false
		if(aiExtraDataIndexes[iThisObjectIndex] == aiCurrentIndex)
			; Match found
			bMatchingEntryFound = true
			FoundBoolTest = ExtraData_Bools02[aiExtraDataIndexes[iThisArrayIndex]].bBool as Int
			
			if(ExtraData_Bools02.Length > aiExtraDataIndexes[iThisArrayIndex] + 1)
				aiExtraDataIndexes[iThisArrayIndex] += 1
				aiExtraDataIndexes[iThisObjectIndex] = ExtraData_Bools02[aiExtraDataIndexes[iThisArrayIndex]].iIndex
				
				iNewLowest = aiExtraDataIndexes[iThisObjectIndex]
			else
				; Flag as finished
				aiExtraDataIndexes[iThisArrayIndex] = iExtraDataValues_AllDistributed
			endif			
		elseif(aiExtraDataIndexes[iExtraDataIndex_NextObjectIndex] == iExtraDataValues_OutOfSequence) ; Check if the broader array is set to Out of Sequence
			; Entries are out of order, so we need to use findstruct
			int iStructArrayIndex = ExtraData_Bools02.FindStruct("iIndex", aiCurrentIndex)
			if(iStructArrayIndex >= 0)
				FoundBoolTest = ExtraData_Bools02[iStructArrayIndex].bBool as Int
				bMatchingEntryFound = true
				
				if(ExtraData_Bools02.Length > iStructArrayIndex + 1)
					aiExtraDataIndexes[iThisArrayIndex] = iStructArrayIndex + 1
					aiExtraDataIndexes[iThisObjectIndex] = ExtraData_Bools02[aiExtraDataIndexes[iThisArrayIndex]].iIndex
					
					iNewLowest = aiExtraDataIndexes[iThisObjectIndex]
				else
					aiExtraDataIndexes[iThisArrayIndex] = iExtraDataValues_AllDistributed
					iNewLowest = iExtraDataValues_AllDistributed
				endif
			elseif(bSS2PlotFound)
				ModTrace("     Plot found, but no ExtraData_Bools02 found for index " + aiCurrentIndex)
				iNewLowest = iExtraDataValues_OutOfSequence
			else
				iNewLowest = iExtraDataValues_OutOfSequence
			endif
		endif
		
		if(FoundBoolTest != -1)
			ModTrace("    ExtraData_Bools02 entry " + FoundBoolTest + " found for spawn thread " + aiCurrentIndex)
			akThreadRef.ExtraData_Bool02 = FoundBoolTest as Bool
			akThreadRef.ExtraData_Bool02Set = true			
		else
			if(bSS2PlotFound && bMatchingEntryFound)
				ModTrace("         ExtraData_Bools02 index " + aiExtraDataIndexes[iThisArrayIndex] + " failed to return valid form via GetIndexMappedUniversalForm. aiCurrentIndex = " + aiCurrentIndex + ", aiExtraDataIndexes[" + iThisArrayIndex + "] = " + aiExtraDataIndexes[iThisArrayIndex] + ", ExtraData_Bools02[aiExtraDataIndexes[" + iThisArrayIndex + "]] = " + ExtraData_Bools02[aiExtraDataIndexes[iThisArrayIndex]])
			endif
		endif
	else
		if(bSS2PlotFound)
			ModTrace("         Failed to find ExtraData_Bools02 entry for a plot. aiCurrentIndex = " + aiCurrentIndex + ", aiExtraDataIndexes[iExtraDataIndex_Bools02_NextObjectIndex] = " + aiExtraDataIndexes[iExtraDataIndex_Bools02_NextObjectIndex])
		endif
	endif
	
	if(ExtraData_Bools03 != None)
		if(bSS2PlotFound)
			ModTrace("         Found ExtraData_Bools03 entry for a plot. aiCurrentIndex = " + aiCurrentIndex + ", aiExtraDataIndexes[iExtraDataIndex_Bools03_NextObjectIndex] = " + aiExtraDataIndexes[iExtraDataIndex_Bools03_NextObjectIndex])
		endif
		
		int iThisObjectIndex = iExtraDataIndex_Bools03_NextObjectIndex
		int iThisArrayIndex = iExtraDataIndex_Bools03_ExtraDataArrayIndex
		
		Int FoundBoolTest = -1
		Bool bMatchingEntryFound = false
		if(aiExtraDataIndexes[iThisObjectIndex] == aiCurrentIndex)
			; Match found
			bMatchingEntryFound = true
			FoundBoolTest = ExtraData_Bools03[aiExtraDataIndexes[iThisArrayIndex]].bBool as Int
			
			if(ExtraData_Bools03.Length > aiExtraDataIndexes[iThisArrayIndex] + 1)
				aiExtraDataIndexes[iThisArrayIndex] += 1
				aiExtraDataIndexes[iThisObjectIndex] = ExtraData_Bools03[aiExtraDataIndexes[iThisArrayIndex]].iIndex
				
				iNewLowest = aiExtraDataIndexes[iThisObjectIndex]
			else
				; Flag as finished
				aiExtraDataIndexes[iThisArrayIndex] = iExtraDataValues_AllDistributed
			endif			
		elseif(aiExtraDataIndexes[iExtraDataIndex_NextObjectIndex] == iExtraDataValues_OutOfSequence) ; Check if the broader array is set to Out of Sequence
			; Entries are out of order, so we need to use findstruct
			int iStructArrayIndex = ExtraData_Bools03.FindStruct("iIndex", aiCurrentIndex)
			if(iStructArrayIndex >= 0)
				FoundBoolTest = ExtraData_Bools03[iStructArrayIndex].bBool as Int
				bMatchingEntryFound = true
				
				if(ExtraData_Bools03.Length > iStructArrayIndex + 1)
					aiExtraDataIndexes[iThisArrayIndex] = iStructArrayIndex + 1
					aiExtraDataIndexes[iThisObjectIndex] = ExtraData_Bools03[aiExtraDataIndexes[iThisArrayIndex]].iIndex
					
					iNewLowest = aiExtraDataIndexes[iThisObjectIndex]
				else
					aiExtraDataIndexes[iThisArrayIndex] = iExtraDataValues_AllDistributed
					iNewLowest = iExtraDataValues_AllDistributed
				endif
			elseif(bSS2PlotFound)
				ModTrace("     Plot found, but no ExtraData_Bools03 found for index " + aiCurrentIndex)
				iNewLowest = iExtraDataValues_OutOfSequence
			else
				iNewLowest = iExtraDataValues_OutOfSequence
			endif
		endif
		
		if(FoundBoolTest != -1)
			ModTrace("    ExtraData_Bools03 entry " + FoundBoolTest + " found for spawn thread " + aiCurrentIndex)
			akThreadRef.ExtraData_Bool03 = FoundBoolTest as Bool
			akThreadRef.ExtraData_Bool03Set = true			
		else
			if(bSS2PlotFound && bMatchingEntryFound)
				ModTrace("         ExtraData_Bools03 index " + aiExtraDataIndexes[iThisArrayIndex] + " failed to return valid form via GetIndexMappedUniversalForm. aiCurrentIndex = " + aiCurrentIndex + ", aiExtraDataIndexes[" + iThisArrayIndex + "] = " + aiExtraDataIndexes[iThisArrayIndex] + ", ExtraData_Bools03[aiExtraDataIndexes[" + iThisArrayIndex + "]] = " + ExtraData_Bools03[aiExtraDataIndexes[iThisArrayIndex]])
			endif
		endif
	else
		if(bSS2PlotFound)
			ModTrace("         Failed to find ExtraData_Bools03 entry for a plot. aiCurrentIndex = " + aiCurrentIndex + ", aiExtraDataIndexes[iExtraDataIndex_Bools03_NextObjectIndex] = " + aiExtraDataIndexes[iExtraDataIndex_Bools03_NextObjectIndex])
		endif
	endif
	
	if(iNewLowest == HIGH_INT)
		iNewLowest = iExtraDataValues_OutOfSequence
	endif
	
	aiExtraDataIndexes[iExtraDataIndex_NextObjectIndex] = iNewLowest
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
	Keyword LinkCustom10 = GetLinkCustom10()
	
	WorkshopFramework:SettlementLayoutManager SettlementLayoutManager = GetSettlementLayoutManager()
	UniversalForm[] UF_AlwaysAllowedActorTypes = SettlementLayoutManager.AlwaysAllowedActorTypes
	Form[] AlwaysAllowedActorTypes = new Form[0]
	int i = 0
	while(i < UF_AlwaysAllowedActorTypes.Length)
		AlwaysAllowedActorTypes.Add(GetUniversalForm(UF_AlwaysAllowedActorTypes[i]))
		
		i += 1
	endWhile
	
	int iThreadsStarted = 0
	
	int[] iExtraDataIndexes = new Int[25]
	
	InitializeExtraDataIndexes(iExtraDataIndexes)
	
		;int[] iExtraDataIndexes = UpdateExtraDataIndexes() ; Generate fresh extra data array with trackers for where we are at in iterating over arrays index-wise for both the overall layout and the various ExtraData_* arrays - this is done to speed up processing so we don't have to keep iterating over the entire collection each time. Instead, we track the last index we found, and assume that we can start from that point going forward as the data is stored in indexed order (ie the extra data array order will be stacked from item 0 to item X, so for example - once you reach item 10, you are done with all extra data for previous indexes 0 through 9 and can skip those).
	
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
			ModTrace("Layout placing " + FormToPlace + ", found in group " + aiObjectsGroupType)
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
				kThread.bRequiresWorkshopOrWorldspace = true
				
				if(aObjectsToPlace[i].fExtraDataFlag == fExtraDataFlag_SkipWorkshopItemLink)
					kThread.bBypassWorkshopItemLink = true
					kThread.AddLinkedRef(akWorkshopRef, LinkCustom10)
				endif
				
				kThread.bRecalculateWorkshopResources = false ; We will just run this once when its done
				
				if( ! F4SEManager.IsF4SERunning || bFauxPoweredSettingEnabled)
					kThread.bFauxPowered = true
				endif
				
				; Handle extra data indexes
				if(aiObjectsGroupType == iGroupType_WorkshopResources)
					; We store the next object index in iExtraDataIndexes[iExtraDataIndex_NextObjectIndex] to avoid having to check every ExtraData_ array for each item when only a small percentage have any extra data at all
					if(i > iExtraDataIndexes[iExtraDataIndex_NextObjectIndex])
						; Something went wrong and the next object index failed to update
						ModTrace("iExtraDataIndexes[iExtraDataIndex_NextObjectIndex] was lower than current iterator (" + iExtraDataIndexes[iExtraDataIndex_NextObjectIndex] + " vs " + i + "), flagging as out of sequence.")
						iExtraDataIndexes[iExtraDataIndex_NextObjectIndex] = iExtraDataValues_OutOfSequence
					endif
					
					if(i == iExtraDataIndexes[iExtraDataIndex_NextObjectIndex] || iExtraDataIndexes[iExtraDataIndex_NextObjectIndex] == iExtraDataValues_OutOfSequence)
						FillExtraData(kThread, iExtraDataIndexes, aiCurrentIndex = i)
					else
						Bool bSS2Plot = false
						Keyword PlotKeyword = Game.GetFormFromFile(0x000149A4, "SS2.esm") as Keyword
						
						if(PlotKeyword != None && FormToPlace.HasKeyword(PlotKeyword))
							ModTrace("        Skipping FillExtraData for Workshop object.")
							ModTrace("              i = " + i + ", iExtraDataIndexes[" + iExtraDataIndex_NextObjectIndex + "] = " + iExtraDataIndexes[iExtraDataIndex_NextObjectIndex])
						endif
					endif
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
	
	; Now grab items that were set to bypass the workshopItemKeyword link
	Keyword LinkCustom10 = GetLinkCustom10()	
	ObjectReference[] kAlternateLinkedRefs = akWorkshopRef.GetLinkedRefChildren(LinkCustom10)
	i = 0
	while(i < kAlternateLinkedRefs.Length)
		if(kAlternateLinkedRefs[i].HasKeyword(TagKeyword))
			WorkshopFramework:ObjectRefs:Thread_ScrapObject kThread = ThreadManager.CreateThread(ScrapObjectThread) as WorkshopFramework:ObjectRefs:Thread_ScrapObject

			if(kThread)
				kThread.kScrapMe = kAlternateLinkedRefs[i]
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
			
			Utility.Wait(0.1)
			
			akWorkshopRef.StartWorkshop(false)
		endif
		
		Keyword WorkshopItemKeyword = GetWorkshopItemKeyword()
		
		if(PowerConnections != None)
			ObjectReference[] kLinkedRefs = akWorkshopRef.GetLinkedRefChildren( WorkshopItemKeyword )
			ActorValue LayoutIndexAV = GetLayoutIndexAV()
			ActorValue LayoutIndexTypeAV = GetLayoutIndexTypeAV()
			ActorValue WorkshopPowerConnectionAV = GetWorkshopPowerConnectionAV()
			ActorValue WorkshopSnapTransmitsPowerAV = GetWorkshopSnapTransmitsPowerAV()
			Keyword WorkshopPowerConnectionKeyword = GetWorkshopPowerConnectionKeyword()
		
			
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
				;if( ! kLinkedRefs[i].IsDisabled() && kLinkedRefs[i].HasKeyword(TagKeyword) && (kLinkedRefs[i].HasKeyword(WorkshopPowerConnectionKeyword) || kLinkedRefs[i].GetValue(WorkshopPowerConnectionAV) > 0))
				
				; Patch 2.4.9 - Removed HasKeyword check so we can wire to vanilla items
				if( ! kLinkedRefs[i].IsDisabled() && (kLinkedRefs[i].HasKeyword(WorkshopPowerConnectionKeyword) || kLinkedRefs[i].GetValue(WorkshopPowerConnectionAV) > 0))
					iPoweredConnectableCounter += 1
					Int iIndex = (kLinkedRefs[i].GetValue(LayoutIndexAV) - 1) as Int 
					if(iIndex >= 0) ; We have power connection data for this
						iPowerDataFoundFor += 1
						Int iType = kLinkedRefs[i].GetValue(LayoutIndexTypeAV) as Int 
						if(iType == 0) ; Ie. no layoutIndexTypeAV applied, assume vanilla item or recreated vanilla item
							iType = POWERCONNECTIONTYPE_VANILLA
						endif
						
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
			
			;;Debug.MessageBox("Found "+ iPoweredConnectableCounter + " items w/ connectors and " + iPowerDataFoundFor + " items with stored connection data. Trace dumping list of refs.")
			
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
					ObjectReference kWireRef = F4SEManager.AttachWireV2(akWorkshopRef, kObjectRefA, kObjectRefB)
					if(kWireRef != None)
						kWireRef.Enable(false)
						kWireRef.AddKeyword(TagKeyword)
					else
						; Try using CreateWire instead
						kWireRef = F4SEManager.CreateWireV2(akWorkshopRef, kObjectRefA, kObjectRefB)
						
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

Keyword Function GetWorkbenchGeneralKeyword()
	return Game.GetFormFromFile(0x00091FD4, "Fallout4.esm") as Keyword
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

Keyword Function GetLinkCustom10()
	return Game.GetFormFromFile(0x00030972, "Fallout4.esm") as Keyword
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

Function DumpVanillaObjectsToRemove()
	ModTrace("==============================")
	ModTrace("Starting dump of VanillaObjectsToRemove for " + Self)
	ModTrace("==============================")
	
	int i = 0
	while(i < VanillaObjectsToRemove.Length)
		ModTrace("[" + i + "] " + VanillaObjectsToRemove[i])
		
		i += 1
	endWhile
	
	ModTrace("==============================")
	ModTrace("Completed dump of VanillaObjectsToRemove for " + Self)
	ModTrace("==============================")
EndFunction

Function DumpVanillaObjectsToRestore()
	ModTrace("==============================")
	ModTrace("Starting dump of VanillaObjectsToRestore for " + Self)
	ModTrace("==============================")
	
	int i = 0
	while(i < VanillaObjectsToRestore.Length)
		ModTrace("[" + i + "] " + VanillaObjectsToRestore[i])
		
		i += 1
	endWhile
	
	ModTrace("==============================")
	ModTrace("Completed dump of VanillaObjectsToRestore for " + Self)
	ModTrace("==============================")
EndFunction

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