; ---------------------------------------------
; Scriptname WorkshopFramework:ObjectRefs:ClutteredItem.psc - by kinggath
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

Scriptname WorkshopFramework:ObjectRefs:ClutteredItem extends ObjectReference

import WorkshopFramework:Library:DataStructures
import WorkshopFramework:Library:ThirdParty:Cobb:CobbLibraryRotations

struct NodeDisplayData
	String NodeName
	Formlist NodeFormlist
endStruct

; --------------------------------
; Editor Properties
; --------------------------------

Group ClutterSettings
	Bool Property bChangeOccasionally = true Auto Const
	{ Set to false to only add clutter when this is placed and then never change }
	
	Int Property iClutterAppearanceChance = 100 Auto Const
	{ If less than 100, this will provide a percent chance for each clutter display point to be left empty. }
	
	NodeDisplayData[] Property ClutterNodes Auto Const
	{ Use either Nodes or Positions, not both. When using this field, use the NodeFormlist field to point to a formlist of items to be randomized. }
	
	WorldObject[] Property ClutterPositions Auto Const
	{ Use either Nodes or Positions, not both. When using this field, use the ObjectForm field to point to a formlist of items to be randomized. }
EndGroup

Int[] DisplayedPositionOrNodeIndex
ObjectReference[] DisplayedRefs
Bool bFirstLoad = true

Event OnWorkshopObjectDestroyed(ObjectReference akActionRef)
	DeleteClutter()
EndEvent

Event OnWorkshopObjectMoved(ObjectReference akReference)
	RedisplayClutter()
EndEvent

Event OnLoad()
	if(bFirstLoad)
		bFirstLoad = false
		
		AddKeyword(GetClutteredItemTagKeyword())
		
		DisplayClutter()
		
		if( ! bChangeOccasionally)
			GoToState("Static")
		endif
	endif
EndEvent


State Static
	Function DisplayClutter()
		; Once in this state, no more item display should occur
	EndFunction
EndState


Function RedisplayClutter()
	Keyword WorkshopStackedItemParentKeyword = GetWorkshopStackedItemParentKeyword()
	int i = 0
	while(i < DisplayedRefs.Length)		
		DisplayedRefs[i].Disable(false)
		PositionItem(DisplayedRefs[i])
		DisplayedRefs[i].SetLinkedRef(Self, WorkshopStackedItemParentKeyword)
		DisplayedRefs[i].Enable(false)
		
		i += 1
	endWhile
EndFunction

Function DisplayClutter()
	if(DisplayedRefs == None)
		DisplayedRefs = new ObjectReference[0]
	endif
	
	DeleteClutter()
	
	if(ClutterNodes != None)
		int i = 0
		while(i < ClutterNodes.Length)
			if(Utility.RandomInt(1, 100) <= iClutterAppearanceChance)
				AttachItem(ClutterNodes[i].NodeFormlist.GetAt(Utility.RandomInt(0, ClutterNodes[i].NodeFormlist.GetSize() - 1)), i)
			endif
			
			i += 1
		endWhile
	else
		int i = 0
		while(i < ClutterPositions.Length)
			if(Utility.RandomInt(1, 100) <= iClutterAppearanceChance)
				Formlist asFormlist = ClutterPositions[i].ObjectForm as Formlist
				
				if(asFormlist)
					AttachItem(asFormlist.GetAt(Utility.RandomInt(0, asFormlist.GetSize() - 1)), i)
				else
					AttachItem(ClutterPositions[i].ObjectForm, i)
				endif
			endif
			
			i += 1
		endWhile
	endif
EndFunction



function AttachItem(Form akPlaceMe, Int aiPositionIndex)
	ObjectReference akItemRef = PlaceAtMe(akPlaceMe, abInitiallyDisabled = true)
	
	if(akItemRef)		
		if(DisplayedRefs == None)
			DisplayedRefs = new ObjectReference[0]
		endif
		
		if(DisplayedPositionOrNodeIndex == None)
			DisplayedPositionOrNodeIndex = new Int[0]
		endif
		
		DisplayedPositionOrNodeIndex.Add(aiPositionIndex)
		DisplayedRefs.Add(akItemRef)
		
		PositionItem(akItemRef)
		
		akItemRef.Enable(false)
		akItemRef.WaitFor3DLoad()
		akItemRef.SetMotionType(Motion_Keyframed, false)
		
		akItemRef.SetLinkedRef(Self, GetWorkshopStackedItemParentKeyword())
		akItemRef.AddKeyword(GetBlockWorkshopInteractionKeyword())
		akItemRef.AddKeyword(GetBlockPlayerActivation())
	endif
endFunction


Function PositionItem(ObjectReference akItemRef)
	int iPositionIndex = DisplayedRefs.Find(akItemRef)
	
	if(iPositionIndex < 0)
		return
	endif
	
	if(ClutterNodes != None)
		if(ClutterNodes.Length > iPositionIndex)
			akItemRef.MoveToNode(Self, ClutterNodes[iPositionIndex].NodeName)
		endif
	else
		if(ClutterPositions.Length > iPositionIndex)
			Float[] pfPositionOffset = new Float[3]
			Float[] pfRotationOffset = new Float[3]
			
			pfPositionOffset[0] = ClutterPositions[iPositionIndex].fPosX
			pfPositionOffset[1] = ClutterPositions[iPositionIndex].fPosY
			pfPositionOffset[2] = ClutterPositions[iPositionIndex].fPosZ
			pfRotationOffset[0] = ClutterPositions[iPositionIndex].fAngleX
			pfRotationOffset[1] = ClutterPositions[iPositionIndex].fAngleY
			pfRotationOffset[2] = ClutterPositions[iPositionIndex].fAngleZ
			
			if(ClutterPositions[iPositionIndex].fScale != 1)
				akItemRef.SetScale(ClutterPositions[iPositionIndex].fScale)
			endif
			
			MoveObjectRelativeToObject(akItemRef, Self, pfPositionOffset, pfRotationOffset)
		endif
	endif
EndFunction


Function DetachItem(ObjectReference akItem)
	Int iIndex = DisplayedRefs.Find(akItem as ObjectReference)
		
	if(iIndex >= 0)
		akItem.SetLinkedRef(None, GetWorkshopStackedItemParentKeyword())
		akItem.Disable(false)
		akItem.Delete()
		
		DisplayedRefs.Remove(iIndex)
	endif
EndFunction

Keyword Function GetBlockWorkshopInteractionKeyword()
	return Game.GetFormFromFile(0x001BDBA6, "Fallout4.esm") as Keyword
EndFunction

Keyword Function GetBlockPlayerActivation()
	return Game.GetFormFromFile(0x001CD02B, "Fallout4.esm") as Keyword
EndFunction

Keyword Function GetWorkshopStackedItemParentKeyword()
	return Game.GetFormFromFile(0x001C5EDD, "Fallout4.esm") as Keyword
EndFunction

Keyword Function GetClutteredItemTagKeyword()
	return Game.GetFormFromFile(0x00023688, "WorkshopFramework.esm") as Keyword
EndFunction
	
Function DeleteClutter()
	int i = DisplayedRefs.Length - 1
	while(i >= 0)
		DetachItem(DisplayedRefs[i])
	
		i -= 1
	endWhile
EndFunction


Function Delete()
	DeleteClutter()
	
	Parent.Delete()
EndFunction