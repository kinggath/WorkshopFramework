; ---------------------------------------------
; Scriptname WorkshopFramework:ObjectRefs:DisplayRack.psc - by kinggath
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

Scriptname WorkshopFramework:ObjectRefs:DisplayRack extends WorkshopFramework:Library:ObjectRefs:LockableObjectRef

import WorkshopFramework:Library:DataStructures
import WorkshopFramework:Library:UtilityFunctions
import WorkshopFramework:Library:ThirdParty:Cobb:CobbLibraryRotations

struct NodeDisplayData
	String NodeName
	Form NodeFormKeywordOrFormlist
endStruct

; --------------------------------
; Editor Properties
; --------------------------------

Group Forms
	Message Property RackFullMessage Auto Const
	{ [Optional] Fill this to customize the message shown if the player attempts to add too many items }
EndGroup

Group DisplayPositioning
	NodeDisplayData[] Property DisplayRackNodes Auto Const
	{ Use either Nodes or Positions, not both. When using this field, use the NodeFormKeywordOrFormlist field to point to a specific form that would be eligible, a keyword eligible items would have, or a formlist of eligible items. }
	WorldObject[] Property DisplayRackPositions Auto Const
	{ Use either Nodes or Positions, not both. When using this field, use the ObjectForm field to point to a specific form that would be eligible, a keyword eligible items would have, or a formlist of eligible items. }
EndGroup

Int[] DisplayedPositionOrNodeIndex
Form[] DisplayedForms
ObjectReference[] DisplayedRefs

Auto State AllowActivate
	Event OnActivate(ObjectReference akActionRef)
		; Block activation of the rack when the player activates it, add inventory event filter, then display items afterwards

		GoToState("Busy")
		if(DisplayedForms == None)
			DisplayedForms = new Form[0]
		endif
		
		
		BlockActivation(true)
		AddInventoryEventFilter(None)

		if(akActionRef == Game.GetPlayer())
	    	Utility.Wait(0.1)
	    	PlaceItems()
	    else
		    GoToState("AllowActivate")
	    endif

		BlockActivation(false)
	EndEvent
EndState

State Busy
	Event OnItemRemoved(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
		; Do Nothing
	EndEvent
EndState



Event OnWorkshopObjectDestroyed(ObjectReference akActionRef)
	Cleanup()
EndEvent

Event ObjectReference.OnActivate(ObjectReference akSender, ObjectReference akActionRef)
	AttachItem(akSender, abAttach = false)
	ClearItemSlot(akSender)
EndEvent

Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
	int iLockKey = GetLock()
		
	if(iLockKey <= GENERICLOCK_KEY_NONE)
		ModTrace("DisplayRack: Unable to get lock!", 2)
		
		return None
	endif
	
	; Store form
	if(DisplayedForms.Length >= 128)
		if(RackFullMessage)
			RackFullMessage.Show()
		else
			ShowDefaultRackFullMessage()
		endif
		
		if(akItemReference)
			RemoveItem(akItemReference, aiItemCount, false, Game.GetPlayer())
		else
			RemoveItem(akBaseItem, aiItemCount, false, Game.GetPlayer())
		endif
	else
		if(akItemReference)
			DisplayedForms.Add(akItemReference)
		else
			int i = 0
			while(i < aiItemCount && DisplayedForms.Length < 128)
				DisplayedForms.Add(akBaseItem)
				
				i += 1
			endWhile
		endif
	endif
	
    if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
		ModTrace("DisplayRack: Failed to release lock " + iLockKey + "!", 2)
	endif
EndEvent


Event OnItemRemoved(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
	int iLockKey = GetLock()
		
	if(iLockKey <= GENERICLOCK_KEY_NONE)
		ModTrace("DisplayRack: Unable to get lock!", 2)
		
		return None
	endif

	if(akItemReference != None)
		ClearItemSlot(akItemReference)
	else
		ClearItemSlot(akBaseItem)
	endif

    if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
		ModTrace("DisplayRack: Failed to release lock " + iLockKey + "!", 2)
	endif
EndEvent


Function ShowDefaultRackFullMessage()
	Message DefaultRackFullMessage = Game.GetFormFromFile(0x00023687, "WorkshopFramework.esm") as Message
	
	DefaultRackFullMessage.Show()
EndFunction

Bool Function DoesItemMatchDisplayPoint(Form akTestMe, Form akDisplayPointMatch)
	if(akTestMe == akDisplayPointMatch)
		return true
	elseif(akDisplayPointMatch as Keyword)
		if(akTestMe.HasKeyword(akDisplayPointMatch as Keyword))
			return true
		endif
	elseif(akDisplayPointMatch as Formlist)
		if((akDisplayPointMatch as Formlist).HasForm(akTestMe))
			return true
		endif
	endif
	
	return false
EndFunction

Int Function FindDisplayPoint(Form akDisplayMe)
	if(DisplayRackNodes != None)
		int i = 0
		while(i < DisplayRackNodes.Length)
			if(DisplayedPositionOrNodeIndex.Find(i) < 0 && DoesItemMatchDisplayPoint(akDisplayMe, DisplayRackNodes[i].NodeFormKeywordOrFormlist))
				; Position not in use, and form matches
				return i
			endif
			
			i += 1
		endWhile
	elseif(DisplayRackPositions != None)
		int i = 0
		while(i < DisplayRackPositions.Length)
			if(DisplayedPositionOrNodeIndex.Find(i) <= 0 && DoesItemMatchDisplayPoint(akDisplayMe, DisplayRackPositions[i].ObjectForm))
				; Position not in use, and form matches
				return i
			endif
			
			i += 1
		endWhile
	endif
	
	return -1
EndFunction

Function PlaceItems()
	if(DisplayedRefs == None)
		DisplayedRefs = new ObjectReference[0]
	endif
	
	if(DisplayedPositionOrNodeIndex == None)
		DisplayedPositionOrNodeIndex = new Int[0]
	endif
	
	int i = DisplayedRefs.Length ; Start with last displayed ref and check for forms not yet displayed
	while(i < DisplayedForms.Length)
		Int iPositionOrNodeIndex = FindDisplayPoint(DisplayedForms[i])
		if(iPositionOrNodeIndex >= 0)
			ObjectReference PlacedRef = None
			; turn this into a ref if it wasn't already
			if(DisplayedForms[i] is ObjectReference)
				(DisplayedForms[i] as ObjectReference).Drop()
				PlacedRef = DisplayedForms[i] as ObjectReference
			else
				PlacedRef = DropObject(DisplayedForms[i])
			endif
			
			if(PlacedRef != None)
				AttachItem(PlacedRef, iPositionOrNodeIndex, true)
				
				DisplayedRefs.Add(PlacedRef)
				DisplayedPositionOrNodeIndex.Add(iPositionOrNodeIndex)
			endif
		
			i += 1 ; Increment
		else
			DisplayedForms.Remove(i)
		endif
	endWhile
	
	; clear inventory back to player as failsafe - nothing should be in container
	ObjectReference droppedRef = DropFirstObject(abInitiallyDisabled = true)
	while(droppedRef)
		Game.GetPlayer().AddItem(droppedRef)
		droppedRef.Enable()
		droppedRef = DropFirstObject(abInitiallyDisabled = true)
	endWhile	
	
	UpdateActivationStatus()
EndFunction


function AttachItem(ObjectReference akItemRef, Int aiPositionIndex = -1, bool abAttach = true)
	if(akItemRef)
		if(abAttach && aiPositionIndex >= 0)
			akItemRef.SetLinkedRef(self, GetWorkshopStackedItemParentKeyword())
			
			akItemRef.WaitFor3DLoad()
			akItemRef.SetMotionType(Motion_Keyframed, false)
			
			akItemRef.AddKeyword(GetBlockWorkshopInteractionKeyword())
			RegisterForRemoteEvent(akItemRef, "OnActivate")
			
			
			if(DisplayRackNodes != None)
				if(DisplayRackNodes.Length > aiPositionIndex)
					akItemRef.MoveToNode(Self, DisplayRackNodes[aiPositionIndex].NodeName)
				endif
			else
				if(DisplayRackPositions.Length > aiPositionIndex)
					Float[] pfPositionOffset = new Float[3]
					Float[] pfRotationOffset = new Float[3]
					
					pfPositionOffset[0] = DisplayRackPositions[aiPositionIndex].fPosX
					pfPositionOffset[1] = DisplayRackPositions[aiPositionIndex].fPosY
					pfPositionOffset[2] = DisplayRackPositions[aiPositionIndex].fPosZ
					pfRotationOffset[0] = DisplayRackPositions[aiPositionIndex].fAngleX
					pfRotationOffset[1] = DisplayRackPositions[aiPositionIndex].fAngleY
					pfRotationOffset[2] = DisplayRackPositions[aiPositionIndex].fAngleZ
					
					if(DisplayRackPositions[aiPositionIndex].fScale != 1)
						akItemRef.SetScale(DisplayRackPositions[aiPositionIndex].fScale)
					endif
					
					MoveObjectRelativeToObject(akItemRef, Self, pfPositionOffset, pfRotationOffset)
				endif
			endif
		else
			akItemRef.RemoveKeyword(GetBlockWorkshopInteractionKeyword())
			akItemRef.SetLinkedRef(None, GetWorkshopStackedItemParentKeyword())
			akItemRef.SetMotionType(Motion_Dynamic, true)
			UnregisterForRemoteEvent(akItemRef, "OnActivate")
			
			Int iIndex = DisplayedRefs.Find(akItemRef)
			
			if(iIndex >= 0 && DisplayedPositionOrNodeIndex != None && DisplayedPositionOrNodeIndex.Length > iIndex && DisplayedPositionOrNodeIndex[iIndex] > -1)
				if(DisplayRackPositions[DisplayedPositionOrNodeIndex[iIndex]].fScale != 1.0)
					akItemRef.SetScale(1.0) ; Restore scale
				endif
			endif
		endif
	endif
endFunction

Function ClearItemSlot(Form akItem)
	Int iIndex = -1
	
	if(akItem is ObjectReference)
		iIndex = DisplayedRefs.Find(akItem as ObjectReference)
	else
		iIndex = DisplayedForms.Find(akItem)
	endif
	
	if(iIndex >= 0)
		DisplayedPositionOrNodeIndex.Remove(iIndex)
		DisplayedRefs.Remove(iIndex)
		DisplayedForms.Remove(iIndex)
	endif
	
	UpdateActivationStatus()
EndFunction

Function UpdateActivationStatus()
	; Should we allow items to still be added?
	if(DisplayedRefs.Length == 128)
		AddKeyword(GetBlockPlayerActivation())
	else
		GoToState("AllowActivate")
		RemoveKeyword(GetBlockPlayerActivation())
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
	
Function Cleanup()
	int i = DisplayedRefs.Length - 1
	while(i >= 0)
		AttachItem(DisplayedRefs[i], abAttach = false)
		ClearItemSlot(DisplayedRefs[i])
	
		i -= 1
	endWhile
EndFunction


Function Delete()
	Cleanup()
	
	Parent.Delete()
EndFunction