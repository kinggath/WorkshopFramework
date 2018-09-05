; ---------------------------------------------
; WorkshopFramework:MainThreadRunner.psc - by kinggath
; ---------------------------------------------
; Reusage Rights ------------------------------
; You are free to use this script or portions of it in your own mods, provided you give me credit in your description and maintain this section of comments in any released source code (which includes the IMPORTED SCRIPT CREDIT section to give credit to anyone in the associated Import scripts below).
; 
; Warning !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
; Do not directly recompile this script for redistribution without first renaming it to avoid compatibility issues issues with the mod this came from.
; 
; IMPORTED SCRIPT CREDITS
; David J Cobb for the Rotation/Vector Library, and Chesko for his influence on said libraries.
; ---------------------------------------------

Scriptname WorkshopFramework:MainThreadRunner extends WorkshopFramework:Library:ThreadRunner

import WorkshopFramework:Library:DataStructures
import WorkshopFramework:Library:UtilityFunctions

; -----------------------------------
; Editor Properties
; -----------------------------------


; -
; Set by ThreadManager
; -

Keyword Property MakeStaticKeyword Auto Hidden
Keyword Property WorkshopItemKeyword Auto Hidden
ActorValue Property PositionXAV Auto Hidden
ActorValue Property PositionYAV Auto Hidden
ActorValue Property PositionZAV Auto Hidden
ActorValue Property RotationXAV Auto Hidden
ActorValue Property RotationYAV Auto Hidden
ActorValue Property RotationZAV Auto Hidden
ActorValue Property ScaleAV Auto Hidden
Form Property PositionHelper Auto Hidden

; -
; Events
; - 

Event ObjectReference.OnLoad(ObjectReference akSpawn)
	if(akSpawn.HasKeyword(MakeStaticKeyword))
		if( ! akSpawn as Actor)
			akSpawn.SetMotionType(akSpawn.Motion_Keyframed, true)
		endif
	endif
	
	Float fTargetAngleX = akSpawn.GetValue(RotationXAV)
	Float fTargetAngleY = akSpawn.GetValue(RotationYAV)
	Float fTargetAngleZ = akSpawn.GetValue(RotationZAV)
	
	if(fTargetAngleX != 0 || fTargetAngleY != 0 || fTargetAngleZ != 0)
		akSpawn.SetAngle(fTargetAngleX, fTargetAngleY, fTargetAngleZ)
		
		; Clear these temp vars
		akSpawn.SetValue(RotationXAV, 0.0)
		akSpawn.SetValue(RotationYAV, 0.0)
		akSpawn.SetValue(RotationZAV, 0.0)
	endif
	
	UnregisterForRemoteEvent(akSpawn, "OnLoad")
EndEvent

; -----------------------------------
; Additional Threadable Functions
; -----------------------------------

; The fastest means of threading is to have the functionality directly on the threadrunner scripts - so here we'll define some common operations that night need to be run at large scale

Bool Function PlaceObjectRelative(Int aiCallBackID, String asCustomCallbackID, Form PlaceMe, ObjectReference akRelativeTo, Float afPosX, Float afPosY, Float afPosZ, Float afAngleX, Float afAngleY, Float afAngleZ, Float afScale, ActorValue aTagAV = None, Float afTagAVValue = 0.0, Bool abForceStatic = false, Bool abEnable = true)
	; TODO!
EndFunction


Bool Function PlaceObject(Int aiCallBackID, String asCustomCallbackID, Form PlaceMe, Float afPosX, Float afPosY, Float afPosZ, Float afAngleX, Float afAngleY, Float afAngleZ, Float afScale, ActorValue aTagAV = None, Float afTagAVValue = 0.0, Bool abForceStatic = false, Bool abEnable = true)
	ObjectReference kResult = None
	
	; Get Edit Lock 
	int iLockKey = GetLock()
	if(iLockKey <= GENERICLOCK_KEY_NONE)
        ModTrace("Unable to get lock!", 2)
	else
		;
		; Lock acquired - do work
		;
		
		Debug.Trace("PlaceObject called with callback ID: " + aiCallBackID)
		; Place temporary object at player
		ObjectReference kTempPositionHelper = PlayerRef.PlaceAtMe(PositionHelper, abInitiallyDisabled = true) ; Leave deletewhenable on so it cleans itself up
		
		if(kTempPositionHelper)
			; Rotation can only occur in the loaded area, so handle that immediately
			kTempPositionHelper.SetAngle(afAngleX, afAngleY, afAngleZ)
			kTempPositionHelper.SetPosition(afPosX, afPosY, afPosZ)
			
			; Place Object at temp object
			Bool bStartDisabled = true
			if(abEnable)
				bStartDisabled = false
			endif
			
			kResult = kTempPositionHelper.PlaceAtMe(PlaceMe, 1, abInitiallyDisabled = bStartDisabled, abDeleteWhenAble = false)
						
			if(kResult)
				if(abForceStatic)
					kResult.AddKeyword(MakeStaticKeyword)
					RegisterForRemoteEvent(kResult, "OnLoad")
				endif
				
				if(kResult as Actor)
					; Actors must be enabled before they can be manipulated
					kResult.Enable()
					
					if( ! kResult.Is3dLoaded())
						; Can't rotate/scale actors until their 3d is loaded
						kResult.SetAngle(afAngleX, afAngleY, afAngleZ)
						kResult.SetScale(afScale)
						
						RegisterForRemoteEvent(kResult, "OnLoad")
					endif
				endif
				
				if(afScale != 1)
					kResult.SetScale(afScale)
				endif
				
				if(aTagAV)
					kResult.SetValue(aTagAV, afTagAVValue)
				endif
			endif
		endif
    endif	
	
	CompleteRun(asCustomCallbackID, aiCallBackID, kResult)
		
	; Release Edit Lock
	if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
        ModTrace("Failed to release lock " + iLockKey + "!", 2)
    endif	
	
	return true
EndFunction