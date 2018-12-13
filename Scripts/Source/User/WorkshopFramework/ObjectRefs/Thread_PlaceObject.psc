; ---------------------------------------------
; WorkshopFramework:ObjectRefs:Thread_PlaceObject.psc - by kinggath
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

Scriptname WorkshopFramework:ObjectRefs:Thread_PlaceObject extends WorkshopFramework:Library:ObjectRefs:Thread

import WorkshopFramework:Library:DataStructures
import WorkshopFramework:Library:ThirdParty:Cobb:CobbLibraryRotations

; -
; Consts
; -


; - 
; Editor Properties
; -

WorkshopFramework:WorkshopResourceManager Property ResourceManager Auto Const Mandatory
Form Property PositionHelper Auto Const Mandatory
{ XMarker object for temporary positioning }
WorkshopParentScript Property WorkshopParent Auto Const Mandatory
ActorValue Property PowerRequired Auto Const Mandatory
{ Autofill }
ActorValue Property PowerGenerated Auto Const Mandatory
{ Autofill }
ActorValue Property WorkshopResourceObject Auto Const Mandatory
{ Autofill }
Keyword Property WorkshopCanBePowered Auto Const Mandatory
{ Autofill }
Keyword Property WorkshopItemKeyword Auto Const Mandatory
{ Autofill }
Keyword Property WorkshopRadioObject Auto Const Mandatory
{ Autofill }
Keyword Property WorkshopEventRadioBeacon Auto Const Mandatory
{ Found on WorkshopParent script property of same name }
Scene Property WorkshopRadioScene01 Auto Const Mandatory
{ Found on WorkshopParent script property of same name }
ObjectReference Property WorkshopRadioRef Auto Mandatory ; Do not make Const - we need to clear this ref later
{ Found on WorkshopParent script property of same name }

Keyword Property ForceStaticKeyword Auto Const Mandatory
{ Keyword to tag objects so we can monitor for their onload event }

; -
; Properties
; -

; We are turning off bAutoDestroy so our batch event manager can grab the result ref
ObjectReference Property kResult Auto Hidden
Bool Property bAwaitingOnLoadEvent = false Auto Hidden

ObjectReference Property kPositionRelativeTo Auto Hidden
WorkshopScript Property kWorkshopRef Auto Hidden
ObjectReference Property kSpawnAt Auto Hidden
ObjectReference Property kMoveToWorldspaceRef Auto Hidden ; 1.0.8 - If set, objects will be moved to this item post-rotation, pre-positioning so they are placed in the correct worldspace
Form Property SpawnMe Auto Hidden
Float Property fPosX = 0.0 Auto Hidden
Float Property fPosY = 0.0 Auto Hidden
Float Property fPosZ = 0.0 Auto Hidden 
Float Property fAngleX = 0.0 Auto Hidden 
Float Property fAngleY = 0.0 Auto Hidden 
Float Property fAngleZ = 0.0 Auto Hidden 
Float Property fScale = 0.0 Auto Hidden
Bool Property bFadeIn = false Auto Hidden ; 1.0.5 - Adding option to allow fading these items in instead of popping them in
Bool Property bStartEnabled = true Auto Hidden
Bool Property bForceStatic = false Auto Hidden ; 1.0.5 - Default to false
Bool Property bFauxPowered = false Auto Hidden ; 1.0.5 - Default to false
Bool Property bSelfDestructThreadAfterOnLoad = true Auto Hidden ; 1.0.5 - Added option to prevent the self destruct
ActorValueSet[] Property TagAVs Auto Hidden
Keyword[] Property TagKeywords Auto Hidden
LinkToMe[] Property LinkedRefs Auto Hidden
Int Property iBatchID = -1 Auto Hidden ; 1.0.5 - Used for tagging a group of threads
; -
; Events
; -

Event ObjectReference.OnLoad(ObjectReference akSenderRef)
	if(akSenderRef.HasKeyword(ForceStaticKeyword))
		akSenderRef.SetMotionType(akSenderRef.Motion_Keyframed)
	else
		akSenderRef.SetAngle(fAngleX, fAngleY, fAngleZ)
		akSenderRef.SetPosition(fPosX, fPosY, fPosZ)
		
		if(fScale != 1.0 && fScale != 0)
			akSenderRef.SetScale(fScale)
		endif
	endif

	UnregisterForAllEvents()
	
	if(bSelfDestructThreadAfterOnLoad) ; Added means of disabling this self-destruction
		SelfDestruct()
	endif
EndEvent

; - 
; Functions 
; -

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

Function AddLinkedRef(ObjectReference akLinkToMe, Keyword akLinkWithKeyword = None)
	LinkToMe newLink = new LinkToMe
	
	newLink.kLinkToMe = akLinkToMe
	newLink.LinkWith = akLinkWithKeyword
	
	if( ! LinkedRefs)
		LinkedRefs = new LinkToMe[0]
	endif
	
	LinkedRefs.Add(newLink)
EndFunction

	
Function ReleaseObjectReferences()
	kResult = None
	kSpawnAt = None
	LinkedRefs = None
	kWorkshopRef = None
	WorkshopRadioRef = None
	kPositionRelativeTo = None
	kMoveToWorldspaceRef = None
EndFunction


Function RunCode()
	bAutoDestroy = false
	kResult = None
	; Place temporary object at player
	ObjectReference kTempPositionHelper = kSpawnAt.PlaceAtMe(PositionHelper, abInitiallyDisabled = true)
	
	if(kTempPositionHelper)
		if(kPositionRelativeTo != None)
			; Calculate position
			Float[] fPosition = new Float[3]
			Float[] fAngle = new Float[3]
			Float[] fPosOffset = new Float[3]
			Float[] fAngleOffset = new Float[3]
			Float[] fNew3dData = new Float[6]
					
			fPosition[0] = kPositionRelativeTo.X
			fPosition[1] = kPositionRelativeTo.Y
			fPosition[2] = kPositionRelativeTo.Z
			fAngle[0] = kPositionRelativeTo.GetAngleX()
			fAngle[1] = kPositionRelativeTo.GetAngleY()
			fAngle[2] = kPositionRelativeTo.GetAngleZ()
	
			fPosOffset[0] = fPosX
			fPosOffset[1] = fPosY
			fPosOffset[2] = fPosZ
			fAngleOffset[0] = fAngleX
			fAngleOffset[1] = fAngleY
			fAngleOffset[2] = fAngleZ
			
			fNew3dData = GetCoordinatesRelativeToBase(fPosition, fAngle, fPosOffset, fAngleOffset)
			
			fPosX = fNew3dData[0]
			fPosY = fNew3dData[1]
			fPosZ = fNew3dData[2]
			fAngleX = fNew3dData[3]
			fAngleY = fNew3dData[4]
			fAngleZ = fNew3dData[5]
		endif
				
		; Rotation can only occur in the loaded area, so handle that immediately
		kTempPositionHelper.SetAngle(fAngleX, fAngleY, fAngleZ)
		
		
		; 1.0.8 - Added kMoveToWorldspaceRef to ensure objects end up in the correct worldspace before the coordinates are set
		if( ! kMoveToWorldspaceRef && kWorkshopRef)
			kMoveToWorldspaceRef = kWorkshopRef
		endif
		
		if(kMoveToWorldspaceRef)
			kTempPositionHelper.MoveTo(kMoveToWorldspaceRef, abMatchRotation = false)
		endif
		
		kTempPositionHelper.SetPosition(fPosX, fPosY, fPosZ)
		
		; Place Object at temp object
			; 1.0.5 - Support for bFadeIn which will allow differentiating between items popping in or fading in
		Bool bInitiallyDisabled = true
		
		if(bStartEnabled && bFadeIn)
			bInitiallyDisabled = false
		endif
		
		
		kResult = kTempPositionHelper.PlaceAtMe(SpawnMe, 1, abInitiallyDisabled = bInitiallyDisabled, abDeleteWhenAble = false)
				
		if(kResult)
			if(kResult as Actor)
				; Actors must be enabled before they can be manipulated
				kResult.Enable(false)
				
				if(kResult.Is3dLoaded())
					; Can't rotate/scale actors until their 3d is loaded
					kResult.SetAngle(fAngleX, fAngleY, fAngleZ)
					kResult.SetPosition(fPosX, fPosY, fPosZ)
					
					if(fScale != 1)
						kResult.SetScale(fScale)
					endif
				else					
					RegisterForRemoteEvent(kResult, "OnLoad")
					bAwaitingOnLoadEvent = true
				endif
			endif
			
			if(bForceStatic)
				kResult.AddKeyword(ForceStaticKeyword)
				RegisterForRemoteEvent(kResult, "OnLoad")
				bAwaitingOnLoadEvent = true
			endif
			
			if(fScale != 1)
				kResult.SetScale(fScale)
			endif
			
			; 1.0.5 - Prior to this, the item was either faded in, or left for the calling script to enable, the bFadeIn adds the possibility of popping in the object from here. We do it at this particular point because the OnLoad event is registered and all 3d data is set which all go quicker while disabled
			if(bStartEnabled && ! bFadeIn)
				kResult.Enable(false)
			endif
			
			if(kWorkshopRef)
				kResult.SetLinkedRef(kWorkshopRef, WorkshopItemKeyword)
				
				if(bFauxPowered && kResult.HasKeyword(WorkshopCanBePowered))
					FauxPowered(kResult)
				endif
				
				WorkshopObjectScript asWorkshopObject = kResult as WorkshopObjectScript
				if(asWorkshopObject)
					asWorkshopObject.workshopID = kWorkshopRef.GetWorkshopID()
					
					if(asWorkshopObject.HasKeyword(WorkshopRadioObject))
						ConfigureRadio(asWorkshopObject, kWorkshopRef)				
					endif
					
					asWorkshopObject.HandleCreation(true)
					
					; Instead of doing kWorkshopRef.RecalculateWorkshopResources, we'll allow our ResourceManager to handle it. This let's us remotely update the workshop so things like the pipboy data are correct even when the settlement is unloaded.
					ResourceManager.ApplyObjectSettlementResources(asWorkshopObject, kWorkshopRef)
				endif
			endif
			
			if(TagAVs)
				int i = 0
				while(i < TagAVs.Length)
					kResult.SetValue(TagAVs[i].AVForm, TagAVs[i].fValue)
					
					i += 1
				endWhile
			endif
			
			if(TagKeywords)
				int i = 0
				while(i < TagKeywords.Length)
					kResult.AddKeyword(TagKeywords[i])
					
					i += 1
				endWhile
			endif
			
			if(LinkedRefs)
				int i = 0
				while(i < LinkedRefs.Length)
					kResult.SetLinkedRef(LinkedRefs[i].kLinkToMe, LinkedRefs[i].LinkWith)
					
					i += 1
				endWhile
			endif
		endif
	endif
EndFunction


Function ConfigureRadio(WorkshopObjectScript akWorkshopObject, WorkshopScript akWorkshopRef)
	; Copied from WorkshopParent.UpdateRadioObject
	
	if(akWorkshopObject.bRadioOn && akWorkshopObject.IsPowered())
		if(akWorkshopRef.WorkshopRadioRef)
			akWorkshopRef.WorkshopRadioRef.Enable() ; enable in case this is a unique station
			akWorkshopObject.MakeTransmitterRepeater(akWorkshopRef.WorkshopRadioRef, akWorkshopRef.workshopRadioInnerRadius, akWorkshopRef.workshopRadioOuterRadius)
			if(akWorkshopRef.WorkshopRadioScene.IsPlaying() == false)
				akWorkshopRef.WorkshopRadioScene.Start()
			endif
		else 
			akWorkshopObject.MakeTransmitterRepeater(WorkshopRadioRef, akWorkshopRef.workshopRadioInnerRadius, akWorkshopRef.workshopRadioOuterRadius)
			if(WorkshopRadioScene01.IsPlaying() == false)
				WorkshopRadioScene01.Start()
			endif
		endif
		
		if(akWorkshopRef.RadioBeaconFirstRecruit == false)
			WorkshopEventRadioBeacon.SendStoryEvent(akRef1 = akWorkshopRef)
		endif
	else
		akWorkshopObject.MakeTransmitterRepeater(NONE, 0, 0)
		
		; if unique radio, turn it off completely
		if(akWorkshopRef.WorkshopRadioRef && akWorkshopRef.bWorkshopRadioRefIsUnique)
			akWorkshopRef.WorkshopRadioRef.Disable()
			; stop custom scene if unique
			akWorkshopRef.WorkshopRadioScene.Stop()
		endif
	endif
	
	; send power change event so quests can react to this
	WorkshopParent.SendPowerStateChangedEvent(akWorkshopObject, akWorkshopRef)	
EndFunction


Function FauxPowered(ObjectReference akRef)
	float fPowerReq = akRef.GetValue(PowerRequired)
	if(fPowerReq > 0)
		akRef.ModValue(PowerRequired, fPowerReq * -1)
	endif
	
	akRef.SetValue(PowerGenerated, 0.1)
	akRef.SetValue(WorkshopResourceObject, 1.0)
EndFunction