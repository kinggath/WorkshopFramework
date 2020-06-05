; ---------------------------------------------
; WorkshopFramework:ObjectRefs:InvisibleWorkshopObject.psc - by kinggath
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

Scriptname WorkshopFramework:ObjectRefs:InvisibleWorkshopObject extends WorkshopObjectScript
{ Control object that is visible and interactable in Workshop Mode only. Meant to be used to spawn an otherwise invisible object, such as an animation marker. }

import WorkshopFramework:Library:DataStructures
import WorkshopFramework:Library:UtilityFunctions

; ---------------------------------------------
; Consts
; ---------------------------------------------

String sPlugin_WSFW = "WorkshopFramework.esm" Const
String sPlugin_Fallout4 = "Fallout4.esm" Const

int iFormID_InvisibleWorkshopObjectKeyword = 0x00006B5A Const
int iFormID_WorkshopItemKeyword = 0x00054BA6 Const
int iFormID_WorkshopWorkObject = 0x00020592 Const
int iFormID_WorkshopStackedItemParentKeyword = 0X001C5EDD Const
int iFormID_LayoutExportDisabledKeyword = 0x0002B79D Const ; LinkDisable
; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------

Group InvisibleSettings
	UniversalForm Property UniversalControlledObjectForm Auto Const Mandatory
	{ One of these will be created and attached. }
	Bool Property bReverse = false Auto Const
	{ If set to true, the UniversalControlledObjectForm will be hidden in Workshop Mode, instead of this. }
EndGroup


	Form Property ControlledObjectForm Auto Const
	{ Maintained for backward compatibility - use UniversalControlledObjectForm instead. }

Group InvisibleSettings_Advanced Collapsed
	Bool Property bLinkControlledObjectToWorkshop = true Auto Const
	{ Set to false to prevent the controlled object from being linked to the workshop. }
	Bool Property bAttachObjects = true Auto Const
	{ If set to false, the objects will not follow each other, meaning the player will be able to move them independent of each other. }
	Bool Property bReverseFlipsStacking = false Auto Const
	{ If bReverse = true, and bAttachObjects then the Controlled Object will become the main moveable object that is meant to be picked up in workshop mode. }	
EndGroup


; ---------------------------------------------
; Vars
; ---------------------------------------------

Keyword InvisibleWorkshopObjectKeyword
Keyword LayoutExportDisabledKeyword
Keyword WorkshopItemKeyword
Keyword WorkshopStackedItemParentKeyword
Keyword WorkshopWorkObject
Bool bWorkshopMode = false
ObjectReference Property kControlledRef Auto Hidden

; ---------------------------------------------
; Events
; ---------------------------------------------
State Deleted
	Function UpdateDisplay()
		Self.Disable(false) ; Just make sure it's hidden
	EndFunction
EndState


Event OnInit()
	UpdateVars()
	
	Parent.OnInit()
	
	; Add the keyword so the manager can pick us up
	Self.AddKeyword(InvisibleWorkshopObjectKeyword)
	; Add the keyword so the item will be picked up by the layout export system even when disabled
	Self.AddKeyword(LayoutExportDisabledKeyword)
	
	bWorkshopMode = WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode()
	UpdateDisplay()
EndEvent


Event OnWorkshopObjectDestroyed(ObjectReference akWorkshopRef)
	Cleanup()
	
	Parent.OnWorkshopObjectDestroyed(akWorkshopRef)
EndEvent

Event OnWorkshopObjectMoved(ObjectReference akWorkshopRef)
	UpdateDisplay()
	
	Parent.OnWorkshopObjectMoved(akWorkshopRef)
EndEvent


; ---------------------------------------------
; Overrides
; ---------------------------------------------

Function AssignActorCustom(WorkshopNPCScript newActor)
	Parent.AssignActorCustom(newActor)
	
	if(kControlledRef != None && newActor != None)
		; Only assign - never send newActor == None, otherwise we'd end up never being able to assign to it. As soon as do assign, we're going to get a call to unassign the NPC from this invisible parent object, and we'd then be passing that unassign to the controlled object. We'll have to instead just rely on this thing being scrapped or someone else being assigned to unassign the actor.
		AssignToControlledObject(newActor)
	endif
EndFunction

; ---------------------------------------------
; Functions
; ---------------------------------------------

Function Toggle(Bool abWorkshopMode)
	if( ! IsBoundGameObjectAvailable())
		return
	endif
		
	bWorkshopMode = abWorkshopMode
	
	UpdateDisplay()
EndFunction


Form Function GetControlledObjectForm()
	if(UniversalControlledObjectForm != None)
		return GetUniversalForm(UniversalControlledObjectForm)
	else
		return ControlledObjectForm
	endif
EndFunction


Function UpdateDisplay()
	if(IsDeleted())
		Cleanup()
		return
	endif	
	
	if( ! kControlledRef)
		Form SpawnMe = GetControlledObjectForm()
		
		Bool bStartDisabled = true
		if(bReverse || bWorkshopMode)
			bStartDisabled = false
		endif
		
		kControlledRef = PlaceAtMe(SpawnMe, abInitiallyDisabled = bStartDisabled, abDeleteWhenAble = false)
		
		if(bLinkControlledObjectToWorkshop)
			kControlledRef.SetLinkedRef(GetLinkedRef(WorkshopItemKeyword), WorkshopItemKeyword)
			
			if(kControlledRef.HasKeyword(WorkshopWorkObject))
				Actor thisActor = GetAssignedActor()
				if(thisActor != None)
					AssignToControlledObject(thisActor)
				endif
			endif
		endif
	else
		if(bReverse && bReverseFlipsStacking)
			Self.MoveTo(kControlledRef)
		else
			kControlledRef.MoveTo(Self)
		endif
	endif
	
	; Set up the controlled ref so it follows this one in WS mode - relinking it every time in case it was moved independently which would cause the game to break the link
	if(bAttachObjects)
		if(bReverse && bReverseFlipsStacking)
			Self.SetLinkedRef(kControlledRef, WorkshopStackedItemParentKeyword)
		else
			kControlledRef.SetLinkedRef(Self, WorkshopStackedItemParentKeyword)
		endif
	endif
	
	if(bWorkshopMode)
		if(bReverse)
			kControlledRef.Enable(false)
			
			if(Self.IsDisabled())
				; Likely disabled due to not having a COBJ record and therefore was destroyed due to the WorkshopStackedItemParentKeyword link
				Self.Enable(false)
			endif
		else
			Self.Enable(false)
			
			if(kControlledRef.IsDisabled())
				; Likely disabled due to not having a COBJ record and therefore was destroyed due to the WorkshopStackedItemParentKeyword link
				kControlledRef.Enable(false)
			endif
		endif
	else
		if(bReverse)
			kControlledRef.Disable(false)
			
			if(Self.IsDisabled())
				; Likely disabled due to not having a COBJ record and therefore was destroyed due to the WorkshopStackedItemParentKeyword link
				Self.Enable(false)
			endif
		else
			Self.Disable(false)
			
			if(kControlledRef.IsDisabled())
				; Likely disabled due to not having a COBJ record and therefore was destroyed due to the WorkshopStackedItemParentKeyword link
				kControlledRef.Enable(false)
			endif
		endif
	endif
EndFunction


Function AssignToControlledObject(Actor akActorRef)
	if( ! kControlledRef.HasKeyword(WorkshopWorkObject))
		return
	endif
	
	WorkshopParent.AssignActorToObjectPUBLIC(akActorRef as WorkshopNPCScript, kControlledRef as WorkshopObjectScript)
	
	; Calling AssignActor will unassign our actor from this object, so let's assign them back to it immediately at the engine level or it will look confusing from an interface standpoint
	SetActorRefOwner(akActorRef, true)
EndFunction


Function UpdateVars()
	if( ! InvisibleWorkshopObjectKeyword)
		InvisibleWorkshopObjectKeyword = Game.GetFormFromFile(iFormID_InvisibleWorkshopObjectKeyword, sPlugin_WSFW) as Keyword
	endif

	if( ! LayoutExportDisabledKeyword)
		LayoutExportDisabledKeyword = Game.GetFormFromFile(iFormID_LayoutExportDisabledKeyword, sPlugin_Fallout4) as Keyword
	endif
	
	if( ! WorkshopItemKeyword)
		WorkshopItemKeyword = Game.GetFormFromFile(iFormID_WorkshopItemKeyword, sPlugin_Fallout4) as Keyword
	endif
	
	if( ! WorkshopWorkObject)
		WorkshopWorkObject = Game.GetFormFromFile(iFormID_WorkshopWorkObject, sPlugin_Fallout4) as Keyword
	endif
	
	if( ! WorkshopStackedItemParentKeyword)
		WorkshopStackedItemParentKeyword = Game.GetFormFromFile(iFormID_WorkshopStackedItemParentKeyword, sPlugin_Fallout4) as Keyword
	endif	
EndFunction


Function Delete()
	Cleanup()
EndFunction

Function Cleanup()
	GoToState("Deleted") ; Move to deleted state to ensure UpdateDisplay can't be called again
	Disable(false)
	DeleteControlledRef()
EndFunction

Function DeleteControlledRef()
	Self.SetLinkedRef(None, WorkshopStackedItemParentKeyword)
	kControlledRef.SetLinkedRef(None, WorkshopStackedItemParentKeyword)
	kControlledRef.SetLinkedRef(None, WorkshopItemKeyword)
	kControlledRef.Disable(false)
	kControlledRef.Delete()
	kControlledRef = None
EndFunction