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

; ---------------------------------------------
; Consts
; ---------------------------------------------

String sPlugin_WSFW = "WorkshopFramework.esm"
String sPlugin_Fallout4 = "Fallout4.esm"

int iFormID_InvisibleWorkshopObjectKeyword = 0x00006B5A
int iFormID_WorkshopItemKeyword = 0x00054BA6
int iFormID_WorkshopStackedItemParentKeyword = 0X001C5EDD

; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------

Group InvisibleSettings
	Form Property ControlledObjectForm Auto Const Mandatory
	{ One of these will be created and attached. }
	Bool Property bReverse = false Auto Const
	{ If set to true, the ControlledObjectForm will be hidden in Workshop Mode, instead of this. }
EndGroup

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
Keyword WorkshopItemKeyword
Keyword WorkshopStackedItemParentKeyword
Bool bWorkshopMode = true
ObjectReference Property kControlledRef Auto Hidden


; ---------------------------------------------
; Events
; ---------------------------------------------

Event OnInit()
	UpdateVars()
	
	; Add the keyword so the manager can pick us up
	Self.AddKeyword(InvisibleWorkshopObjectKeyword)
	
	UpdateDisplay()
EndEvent


Event OnWorkshopObjectDestroyed(ObjectReference akWorkshopRef)
	Cleanup()
EndEvent

Event OnWorkshopObjectMoved(ObjectReference akWorkshopRef)
	UpdateDisplay()
EndEvent

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


Function UpdateDisplay()
	if(IsDeleted())
		Cleanup()
		return
	endif	
	
	if( ! kControlledRef)
		kControlledRef = PlaceAtMe(ControlledObjectForm, abDeleteWhenAble = false)
		
		if(bLinkControlledObjectToWorkshop)
			kControlledRef.SetLinkedRef(GetLinkedRef(WorkshopItemKeyword), WorkshopItemKeyword)
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


Function UpdateVars()
	if( ! InvisibleWorkshopObjectKeyword)
		InvisibleWorkshopObjectKeyword = Game.GetFormFromFile(iFormID_InvisibleWorkshopObjectKeyword, sPlugin_WSFW) as Keyword
	endif	
	
	if( ! WorkshopItemKeyword)
		WorkshopItemKeyword = Game.GetFormFromFile(iFormID_WorkshopItemKeyword, sPlugin_Fallout4) as Keyword
	endif
	
	if( ! WorkshopStackedItemParentKeyword)
		WorkshopStackedItemParentKeyword = Game.GetFormFromFile(iFormID_WorkshopStackedItemParentKeyword, sPlugin_Fallout4) as Keyword
	endif	
EndFunction


Function Delete()
	Cleanup()
EndFunction

Function Cleanup()
	Self.SetLinkedRef(None, WorkshopStackedItemParentKeyword)
	kControlledRef.SetLinkedRef(None, WorkshopStackedItemParentKeyword)
	kControlledRef.SetLinkedRef(None, WorkshopItemKeyword)
	kControlledRef.Disable(false)
	kControlledRef.Delete()
	kControlledRef = None
EndFunction