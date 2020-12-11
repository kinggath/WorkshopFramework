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
import WorkshopFramework:Library:UtilityFunctions
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
ActorValue Property WorkshopCurrentDraws Auto Const Mandatory
{ Autofill }
ActorValue Property WorkshopCurrentTriangles Auto Const Mandatory
{ Autofill }
Keyword Property WorkshopCanBePowered Auto Const Mandatory
{ Autofill }
Keyword Property WorkshopItemKeyword Auto Const Mandatory
{ Autofill }
Keyword Property WorkshopRadioObject Auto Const Mandatory
{ Autofill }
Keyword Property WorkshopStartPoweredOn Auto Const Mandatory
{ Autofill }
Keyword Property WorkshopEventRadioBeacon Auto Const Mandatory
{ Found on WorkshopParent script property of same name }
Scene Property WorkshopRadioScene01 Auto Const Mandatory
{ Found on WorkshopParent script property of same name }
ObjectReference Property WorkshopRadioRef Auto Mandatory ; Do not make Const - we need to clear this ref later
{ Found on WorkshopParent script property of same name }

Keyword Property FauxPoweredKeyword Auto Const Mandatory

Keyword Property ForceStaticKeyword Auto Const Mandatory
{ Keyword to tag objects so we can monitor for their onload event }

Formlist Property SkipPowerOnList Auto Const Mandatory
{ Formlist to skip the power on triggers for some items, such as the siren }
; -
; Properties
; -
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
Float Property fScale = 1.0 Auto Hidden ; 1.1.6 - Defaulting to 1
Bool Property bFadeIn = false Auto Hidden ; 1.0.5 - Adding option to allow fading these items in instead of popping them in
Bool Property bStartEnabled = true Auto Hidden
Bool Property bForceStatic = false Auto Hidden ; 1.0.5 - Default to false
Bool Property bFauxPowered = false Auto Hidden ; 1.0.5 - Default to false
Bool Property bSelfDestructThreadAfterOnLoad = true Auto Hidden ; 1.0.5 - Added option to prevent the self destruct
Bool Property bApplyDrawCount = false Auto Hidden ; 1.1.5 - Defaults to false - if WorkshopCurrentDraws is applied to the placed object, it will be added to the workshop for the sake of the build limit
Bool Property bApplyTriCount = false Auto Hidden ; 1.1.5 - Defaults to false - if WorkshopCurrentTriangles is applied to the placed object, it will be added to the workshop for the sake of the build limit
Bool Property bRecalculateWorkshopResources = true Auto Hidden ; 1.2.0 - For huge batches where we know the player will stay put, we don't want this triggering for every item
Bool Property bForceWorkshopItemLink = true Auto Hidden
ActorValueSet[] Property TagAVs Auto Hidden
Keyword[] Property TagKeywords Auto Hidden
LinkToMe[] Property LinkedRefs Auto Hidden
RefCollectionAlias Property AddPlacedObjectToCollection Auto Hidden ; 2.0.0 - Simple way for calling function to remotely gain access to these - they'll be in charge of unpersisting these


Int Property iBatchID = -1 Auto Hidden ; 1.0.5 - Used for tagging a group of threads


; Extra Data to Pass to Spawned item
Form Property ExtraData_Form01 Auto Hidden
Form Property ExtraData_Form02 Auto Hidden
Form Property ExtraData_Form03 Auto Hidden
Bool Property ExtraData_Form01Set = false Auto Hidden
Bool Property ExtraData_Form02Set = false Auto Hidden
Bool Property ExtraData_Form03Set = false Auto Hidden

Float Property ExtraData_Number01 Auto Hidden
Float Property ExtraData_Number02 Auto Hidden
Float Property ExtraData_Number03 Auto Hidden	
Bool Property ExtraData_Number01Set = false Auto Hidden
Bool Property ExtraData_Number02Set = false Auto Hidden
Bool Property ExtraData_Number03Set = false Auto Hidden

String Property ExtraData_String01 Auto Hidden
String Property ExtraData_String02 Auto Hidden
String Property ExtraData_String03 Auto Hidden
Bool Property ExtraData_String01Set = false Auto Hidden
Bool Property ExtraData_String02Set = false Auto Hidden
Bool Property ExtraData_String03Set = false Auto Hidden

Bool Property ExtraData_Bool01 Auto Hidden
Bool Property ExtraData_Bool02 Auto Hidden
Bool Property ExtraData_Bool03 Auto Hidden
Bool Property ExtraData_Bool01Set = false Auto Hidden
Bool Property ExtraData_Bool02Set = false Auto Hidden
Bool Property ExtraData_Bool03Set = false Auto Hidden

; Sim Settlements specific
Form Property BuildingPlan Auto Hidden
Form Property SkinPlan Auto Hidden
Form Property StoryPlan Auto Hidden
Int Property iStartingLevel = -1 Auto Hidden

; -
; Events
; -

Event ObjectReference.OnLoad(ObjectReference akSenderRef)
	if(akSenderRef.HasKeyword(ForceStaticKeyword))
		akSenderRef.SetMotionType(akSenderRef.Motion_Keyframed)
	elseif(kResult && (kResult.HasKeyword(WorkshopCanBePowered) || kResult.HasKeyword(WorkshopStartPoweredOn)))
		kResult.PlayAnimation("Reset")
		kResult.PlayAnimation("Powered")
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

Bool Property bVerbose = false Auto Hidden
Function RunCode()
	if(bVerbose)
		Debug.MessageBox("RunCode called")
	endif
	
	; bAutoDestroy = false ; 1.2.0 - Commenting this out as this thread is being used by more than just our batch system, this value will now be set by the code that sets up the thread before its run
	
	kResult = None
	; Place temporary object at player
	ObjectReference kTempPositionHelper = kSpawnAt.PlaceAtMe(PositionHelper, abInitiallyDisabled = true)
	
	if(kTempPositionHelper)
		if(bVerbose)
			Debug.MessageBox("PositionHelper placed")
		endif
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
		
		if(bVerbose)
			Debug.MessageBox("Final position data: " + fPosX + ", " + fPosY + ", " + fPosZ)
		endif		
		; Rotation can only occur in the loaded area, so handle that immediately
		kTempPositionHelper.SetAngle(fAngleX, fAngleY, fAngleZ)
		
		
		; 1.0.8 - Added kMoveToWorldspaceRef to ensure objects end up in the correct worldspace before the coordinates are set
		if( ! kMoveToWorldspaceRef && kWorkshopRef && ! kWorkshopRef.Is3dLoaded()) ; 1.1.6, skip moving to worldspace for workshop ref items if the player is there
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
			SendExtraData(kResult)
			; Handle Sim Settlements extras immediately so we can pause the initilization and prevent mass spam
			if(BuildingPlan != None)
				HandleSimSettlementsData(kResult)
			endif
			
			if(bVerbose)
				Debug.TraceAndBox("Object placed " + kResult)
			endif
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
				if(bVerbose)
					Debug.MessageBox("Object enabled")
				endif
				kResult.Enable(false)
			endif
			
			if(bVerbose)
				Debug.MessageBox("About to test for kWorkshopRef")
			endif
			
			if(kWorkshopRef)
				if(bVerbose)
					Debug.MessageBox("Object linking to workshop")
				endif
			
				WorkshopObjectScript asWorkshopObject = kResult as WorkshopObjectScript
				
				if(bForceWorkshopItemLink || asWorkshopObject || kResult.GetValue(WorkshopResourceObject) > 0 || (kResult as WorkshopFramework:ObjectRefs:RealInventoryDisplay))
					kResult.SetLinkedRef(kWorkshopRef, WorkshopItemKeyword)
				endif
				
				if(kResult.HasKeyword(WorkshopCanBePowered))
					if(bFauxPowered)
						FauxPowered(kResult)
					endif
					
					if(SkipPowerOnList != None && ! SkipPowerOnList.HasForm(SpawnMe))
						if(kResult.Is3dLoaded())
							kResult.PlayAnimation("Reset")
							kResult.PlayAnimation("Powered")
						else
							RegisterForRemoteEvent(kResult, "OnLoad")
						endif
					endif
				endif	

				if(kResult.HasKeyword(WorkshopStartPoweredOn))
					if(kResult.Is3dLoaded())
						kResult.PlayAnimation("Reset")
						kResult.PlayAnimation("Powered")
					else
						RegisterForRemoteEvent(kResult, "OnLoad")
					endif
				endif
				
				
				if(asWorkshopObject)
					asWorkshopObject.workshopID = kWorkshopRef.GetWorkshopID()
					
					if(asWorkshopObject.HasKeyword(WorkshopRadioObject))
						ConfigureRadio(asWorkshopObject, kWorkshopRef)				
					endif
					
					asWorkshopObject.HandleCreation(true)
					
					; Instead of doing kWorkshopRef.RecalculateWorkshopResources, we'll allow our ResourceManager to handle it. This let's us remotely update the workshop so things like the pipboy data are correct even when the settlement is unloaded.
					if(bRecalculateWorkshopResources)
						ResourceManager.ApplyObjectSettlementResources(asWorkshopObject, kWorkshopRef)
					endif
				endif
			else
				if(bVerbose)
					Debug.MessageBox("No workshop found")
				endif
			endif
			
			if(TagAVs != None)
				int i = 0
				while(i < TagAVs.Length)
					kResult.SetValue(TagAVs[i].AVForm, TagAVs[i].fValue)
					
					i += 1
				endWhile
			endif
			
			if(TagKeywords != None)
				int i = 0
				while(i < TagKeywords.Length)
					kResult.AddKeyword(TagKeywords[i])
					
					i += 1
				endWhile
			endif
			
			if(LinkedRefs != None)
				int i = 0
				while(i < LinkedRefs.Length)
					kResult.SetLinkedRef(LinkedRefs[i].kLinkToMe, LinkedRefs[i].LinkWith)
					
					i += 1
				endWhile
			endif
			
			if(bApplyDrawCount)
				Float fCurrentDraws = kWorkshopRef.GetValue(WorkshopCurrentDraws)
				Float fItemDraws = kResult.GetValue(WorkshopCurrentDraws)
				
				if(fItemDraws > 0)
					kWorkshopRef.SetValue(WorkshopCurrentDraws, (fCurrentDraws + fItemDraws))
				endif
			endif
			
			if(bApplyTriCount)
				Float fCurrentTris = kWorkshopRef.GetValue(WorkshopCurrentTriangles)
				Float fItemTris = kResult.GetValue(WorkshopCurrentDraws)
				
				if(fItemTris > 0)
					kWorkshopRef.SetValue(WorkshopCurrentTriangles, (fCurrentTris + fItemTris))
				endif
			endif
			
			if(AddPlacedObjectToCollection != None)
				AddPlacedObjectToCollection.AddRef(kResult)
			endif
			
			;ModTrace("[Placed Object] " + kResult)
		endif
	endif
	
	if(bVerbose)
		Debug.MessageBox("Thread_PlaceObject: Completed RunCode.")
	endif
EndFunction


Function HandleSimSettlementsData(ObjectReference akPlacedRef)
	ScriptObject PlotRef = akPlacedRef.CastAs("SimSettlements:SimPlot")
	
	if(PlotRef != None)
		; Pause init and send plot to Sim Settlements for queued initilization - this prevents SS Plots from mass spamming functions as soon as they are spawned
		PlotRef.SetPropertyValue("bPauseInit", true)
		
		Form WSFWRelay = Game.GetFormFromFile(0x0000BD42, "SimSettlements.esm")
		ScriptObject CastWSFWRelay = WSFWRelay.CastAs("SimSettlements:WorkshopFrameworkIntegration")
		
		Var[] kArgs = new Var[1]
		kArgs[0] = akPlacedRef ; Don't send PlotRef here or you'll get a type mismatch error
		CastWSFWRelay.CallFunction("RegisterSpawnedPlot", kArgs)
		
		; Prep BuildingPlan
		if(BuildingPlan != None)
			PlotRef.SetPropertyValue("ForcedBuildingPlan", BuildingPlan)
		endif
		
		PlotRef.SetPropertyValue("iForceStartingLevel", iStartingLevel) ; This will force to appropriate level
		
		; Prep Skin
		if(SkinPlan != None)
			PlotRef.SetPropertyValue("ForcedSkin", SkinPlan)
		endif
		
		; Prep VIP Story
		if(StoryPlan != None)
			PlotRef.SetPropertyValue("ForcedVIP", StoryPlan)
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
	akRef.AddKeyword(FauxPoweredKeyword)
EndFunction


Function SendExtraData(ObjectReference akRef)
	if(ExtraData_Form01Set || ExtraData_Form02Set || ExtraData_Form03Set || ExtraData_Number01Set || ExtraData_Number02Set || ExtraData_Number03Set || ExtraData_String01Set || ExtraData_String02Set || ExtraData_String03Set || ExtraData_Bool01Set || ExtraData_Bool02Set || ExtraData_Bool03Set)
		; Users should grab this data with GetExtraData and then trigger a timer or a CallFunctionNoWait to ensure this thread isn't held up while they process the data
		
		akRef.OnTriggerEnter(Self) ; Send import notice - objects can define this vanilla event to be treated like a function so they grab the ExtraData stored on this thread
	endif
EndFunction

Var[] Function GetExtraData()
	Var[] ExtraData = new Var[0]
	
	if(ExtraData_Form01Set)
		ExtraData.Add(ExtraData_Form01)
	endif
	
	if(ExtraData_Form02Set)
		ExtraData.Add(ExtraData_Form02)
	endif
	
	if(ExtraData_Form03Set)
		ExtraData.Add(ExtraData_Form03)
	endif
	
	if(ExtraData_Number01Set)
		ExtraData.Add(ExtraData_Number01)
	endif
	
	if(ExtraData_Number02Set)
		ExtraData.Add(ExtraData_Number02)
	endif
	
	if(ExtraData_Number03Set)
		ExtraData.Add(ExtraData_Number03)
	endif
	
	if(ExtraData_String01Set)
		ExtraData.Add(ExtraData_String01)
	endif
	
	if(ExtraData_String02Set)
		ExtraData.Add(ExtraData_String02)
	endif
	
	if(ExtraData_String03Set)
		ExtraData.Add(ExtraData_String03)
	endif
	
	if(ExtraData_Bool01Set)
		ExtraData.Add(ExtraData_Bool01)
	endif
	
	if(ExtraData_Bool02Set)
		ExtraData.Add(ExtraData_Bool02)
	endif
	
	if(ExtraData_Bool03Set)
		ExtraData.Add(ExtraData_Bool03)
	endif
	
	return ExtraData
EndFunction