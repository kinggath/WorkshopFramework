; ---------------------------------------------
; WorkshopFramework:WorkshopFunctions.psc - by kinggath
; ---------------------------------------------
; Reusage Rights ------------------------------
; You are free to use this script or portions of it in your own mods, provided you give me credit in your description and maintain this section of comments in any released source code (which includes the IMPORTED SCRIPT CREDIT section to give credit to anyone in the associated Import scripts below).
; 
; Warning !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
; Do not directly recompile this script for redistribution without first renaming it to avoid compatibility issues issues with the mod this came from.
; 
; IMPORTED SCRIPT CREDITS
; N/A
; ---------------------------------------------

Scriptname WorkshopFramework:WorkshopFunctions Hidden Const

import WorkshopDataScript
import WorkshopFramework:Library:DataStructures


; -----------------------------------
; Workshop Parent Replacements
;
;/ 
The goal of these functions is to reduce the traffic on WorkshopParent. Any functionality that was relatively fast and didn't require stored data or aliases from WorkshopParent has been duplicated here.

Note: Some functions copied were done to eliminate requirement of WorkshopNPCScript to allow for any NPC to potentially become a settler.
/;
;----------------------------------- 
;>>

; Copied from WorkshopParent to reduce calls to it
function SetUnassignedPopulationRating(WorkshopScript workshopRef, ObjectReference[] WorkshopActors = none) global
	if(WorkshopActors == none)
		if( ! workshopRef.Is3dLoaded())
			return
		endif
		
		WorkshopActors = GetWorkshopActors(workshopRef)
	endif

	WorkshopParentScript WorkshopParent = GetWorkshopParent()
	
	int countActors = WorkshopActors.Length
	int unassignedPopulation = 0
	int i = 0
	while(i < countActors)
		Actor theActor = WorkshopActors[i] as Actor
		
		if(theActor && ! IsWorker(theActor) && ! IsCaravanNPC(theActor))
			unassignedPopulation += 1
		endif
		
		i += 1
	endWhile

	SetResourceData(GetUnassignedPopulationAV(), workshopRef, unassignedPopulation)
endFunction


; Copied from WorkshopParent to reduce calls to it
function SetResourceData(ActorValue pValue, WorkshopScript pWorkshopRef, float newValue) global
	if(pValue == None)
		return
	endif
	
	float oldBaseValue = pWorkshopRef.GetBaseValue(pValue)
	float oldValue = pWorkshopRef.GetValue(pValue)
	
	; restore any damage first, then set
	if(oldValue < oldBaseValue)
		pWorkshopRef.RestoreValue(pValue, oldBaseValue-oldValue)
	endif
	
	; now set the value
	pWorkshopRef.SetValue(pValue, newValue)
endFunction

; Copied from WorkshopParent to reduce calls to it
function ModifyResourceData(ActorValue pValue, WorkshopScript pWorkshopRef, float modValue) global
	if(pWorkshopRef == None || pValue == None)
		return
	endif
	
	float currentValue = pWorkshopRef.GetValue(pValue)
	; don't mod value below 0
	
	float newValue = modValue + currentValue
	if(newValue < 0)
		newValue = 0
	endif
	
	SetResourceData(pValue, pWorkshopRef, newValue)
endFunction


; Copied from WorkshopParent but accessing the formlist directly to avoid having to touch WorkshopParent
bool Function IsExcludedFromAssignmentRules(Form aFormToCheck) global
	Formlist ExcludeFromAssignmentRules = GetExcludeFromAssignmentRulesFormlist()

	if(aFormToCheck as ObjectReference)
		aFormToCheck = (aFormToCheck as ObjectReference).GetBaseObject()
	endif
	
	Bool bExclude = ExcludeFromAssignmentRules.HasForm(aFormToCheck)
	
	return bExclude
EndFunction


; Copied from WorkshopParent to reduce calls to it
Function AssignHomeMarkerToActor(Actor akActorRef, WorkshopScript akWorkshopRef) global
	; If sandbox link exists, use that - otherwise use center marker
	Keyword WorkshopLinkSandbox = GetWorkshopLinkSandboxKeyword()
	Keyword WorkshopLinkHome = GetWorkshopLinkHomeKeyword()
	
	ObjectReference kHomeMarker = akWorkshopRef.GetLinkedRef(WorkshopLinkSandbox)
	if(kHomeMarker == None)
		Keyword WorkshopLinkCenter = GetWorkshopLinkCenterKeyword()
		kHomeMarker = akWorkshopRef.GetLinkedRef(WorkshopLinkCenter)
	endif
	
	akActorRef.SetLinkedRef(kHomeMarker, WorkshopLinkHome)
endFunction

; Copied from Workshop Parent to reduce calls to it
ObjectReference[] Function GetWorkshopActors(WorkshopScript workshopRef) global
	return workshopRef.GetWorkshopResourceObjects(GetPopulationAV())
endFunction

; Copied from Workshop Parent to reduce calls to it
; aiDamageOption:
;	0 = return all objects
;	1 = return only damaged objects (at least 1 damaged resource value)
;	2 = return only undamaged objects (NO damaged resource values)
ObjectReference[] Function GetResourceObjects(WorkshopScript workshopRef, ActorValue resourceValue = NONE, int aiDamageOption = 0) global
	return workshopRef.GetWorkshopResourceObjects(resourceValue, aiDamageOption)
endFunction

; Copied from WorkshopParent to reduce calls to it
function UpdateWorkshopRatingsForResourceObject(WorkshopObjectScript workshopObject, WorkshopScript workshopRef, bool bRemoveObject = false, bool bRecalculateResources = true) global
	UpdateVendorFlags(workshopObject, workshopRef)
	
	WorkshopParentScript WorkshopParent = GetWorkshopParent()
	
	if(workshopObject.HasKeyword(GetWorkshopRadioObjectKeyword()))
		WorkshopParent.UpdateRadioObject(workshopObject)
	elseif(bRecalculateResources)
		workshopRef.RecalculateWorkshopResources()
	endif
endFunction

; Copied from WorkshopParent to reduce calls to it
float function GetWorkshopPopulationDamage(WorkshopScript workshopRef)
	ActorValue PopulationAV = GetPopulationAV()
	ActorValue PopulationDamageAV = GetPopulationDamageAV()
	
	; difference between base value and current value
	float populationDamage = workshopRef.GetBaseValue(PopulationAV) - workshopRef.GetValue(PopulationAV)
	
	; add in any extra damage (recorded but not yet processed into wounded actors)
	populationDamage += workshopRef.GetBaseValue(PopulationDamageAV)

	return populationDamage
endFunction

; Copied from WorkshopParent to reduce calls to it
function UpdateVendorFlags(WorkshopObjectScript workshopObject, WorkshopScript workshopRef) global
	WorkshopParentScript WorkshopParent = GetWorkshopParent()
	; set this to true if we are going to change state
	bool bShouldVendorFlagBeSet = false
	Int iVendorType = workshopObject.VendorType
	
	if(iVendorType > -1)
		WorkshopVendorType vendorType = WorkshopParent.WorkshopVendorTypes[iVendorType]

		if(vendorType)
			; if a vendor object, increment global if necessary
			if(workshopObject.vendorLevel >= 2) ; Hard coding VendorTopLevel from WorkshopParent
				; check for minimum connected population
				int linkedPopulation = WorkshopParent.GetLinkedPopulation(workshopRef, false) as int
				int totalPopulation = workshopRef.GetBaseValue(GetPopulationAV()) as int
				int vendorPopulation = linkedPopulation + totalPopulation

				if(vendorType && vendorPopulation >= vendorType.minPopulationForTopVendor && workshopRef.OwnedByPlayer)
					bShouldVendorFlagBeSet = true
				endif
			endif
			
			if(bShouldVendorFlagBeSet)
				if(workshopObject.bVendorTopLevelValid == false)
					; increment top vendor global
					vendorType.topVendorFlag.Mod(1.0)
					workshopObject.bVendorTopLevelValid = true
				endif
			elseif(workshopObject.bVendorTopLevelValid == true)
				; decrement top vendor global
				vendorType.topVendorFlag.Mod(-1.0)
				workshopObject.bVendorTopLevelValid = false
			endif
		endif
	endif
endFunction

; Copied from WorkshopParent to reduce calls to it
function UpdateVendorFlagsAll(WorkshopScript workshopRef) global
	; get stores
	ObjectReference[] stores = GetResourceObjects(workshopRef, GetVendorIncomeAV())			
	
	; update vendor data for all of them (might trigger top level vendor for increase in population)
	int i = 0
	while(i < stores.Length)
		WorkshopObjectScript theStore = stores[i] as WorkshopObjectScript
		if(theStore)
			UpdateVendorFlags(theStore, workshopRef)
		endif
		
		i += 1
	endWhile
endFunction

; Bypassing need to call WorkshopParent
Int Function GetMultiResourceIndex(ActorValue aMultiResourceAV) global
	if(aMultiResourceAV == GetSafetyAV())
		return 3
	elseif(aMultiResourceAV == GetFoodAV())
		return 0
	endif
	
	return -1
EndFunction

; Bypassing need to call WorkshopParent
Float Function GetMaxProductionPerNPC(Int aiResourceID) global
	Float fMaxProduction = 6.0 ; Hard coding - if people are using Workshop Framework they can override anyway
				
	if(aiResourceID == 0) ; Food
		fMaxProduction = GetMaxFoodWorkPerSettlerGlobal().GetValue()
	elseif(aiResourceID == 3) ; Safety
		fMaxProduction = GetMaxSafetyWorkPerSettlerGlobal().GetValue()
	endif
	
	return fMaxProduction
EndFunction


; Copied from older version of WorkshopParentScript - the UFO4P version wouldn't work on actors assigned to remote settlements, even if the actor was loaded
bool function IsObjectOwner(WorkshopScript workshopRef, Actor theActor) global
	ObjectReference[] ResourceObjects = workshopRef.GetWorkshopOwnedObjects(theActor)
	int objectCount = ResourceObjects.Length
	int i = 0
	while(i < objectCount)
		WorkshopObjectScript resourceObject = ResourceObjects[i] as WorkshopObjectScript
		if(resourceObject && ! resourceObject.IsBed())
			return true
		endif
		
		i += 1
	endWhile
	
	return false
endFunction

;<<


; -----------------------------------
; WorkshopNPCScript Alternatives
;
;/ 
The goal of these functions is to allow for actors without WorkshopNPCScript to be able to exist in the settlement system. This will effectively serve as a feature rich API, where all necessary calls and access to arrays and aliases will be routed to the appropriate quest(s).
The goal of these functions is to allow for actors without WorkshopNPCScript to be able to exist in the settlement system. This will effectively serve as a feature rich API, where all necessary calls and access to arrays and aliases will be routed to the appropriate quest(s).

These functions offer replacements or alternatives for a variety of functions and properties from WorkshopScript, WorkshopNPCScript, and WorkshopParentScript that explicitly reference or require WorkshopNPCScript somewhere.

Note that mods that are relying on WorkshopNPCScript in their data would need to explicitly switch to our global functions and alternative functions within the corresponding workshop scripts to support this.
/;
; ----------------------------------- 
;>>


; Replace WorkshopNPCScript.UpdatePlayerOwnership
Function UpdatePlayerOwnership(Actor akActorRef, WorkshopScript akWorkshopRef) global
	; set player ownership actor value
	ActorValue WorkshopPlayerOwned = GetWorkshopPlayerOwnedAV()
	
	akActorRef.SetValue(WorkshopPlayerOwned, akWorkshopRef.OwnedByPlayer as int)
endFunction


; Replace WorkshopParent.SetVendorData
function SetVendorData(WorkshopScript workshopRef, Actor assignedActor, WorkshopObjectScript assignedObject, bool bSetData = true) global
	WorkshopParentScript WorkshopParent = GetWorkshopParent()		
	Formlist VendorContainerKeywords = WorkshopParent.VendorContainerKeywords
	
	if(assignedObject.VendorType > -1)
		
		WorkshopVendorType vendorData = WorkshopParent.WorkshopVendorTypes[assignedObject.VendorType]
		Int VendorTopLevel = WorkshopParent.VendorTopLevel
		
		if(vendorData)
			; -- vendor faction
			if(bSetData)
				assignedActor.AddToFaction(vendorData.VendorFaction)
				if(vendorData.keywordToAdd01)
					assignedActor.AddKeyword(vendorData.keywordToAdd01)
				endif
			else
				assignedActor.RemoveFromFaction(vendorData.VendorFaction)
				if(vendorData.keywordToAdd01)
					assignedActor.RemoveKeyword(vendorData.keywordToAdd01)
				endif
			endif

			; -- assign vendor chests
			ObjectReference[] vendorContainers = workshopRef.GetVendorContainersByType(assignedObject.VendorType)
			int i = 0
			while(i <= assignedObject.vendorLevel)
				if(bSetData)
					assignedActor.SetLinkedRef(vendorContainers[i], VendorContainerKeywords.GetAt(i) as Keyword)
				else
					assignedActor.SetLinkedRef(NONE, VendorContainerKeywords.GetAt(i) as Keyword)
				endif
				i += 1
			endWhile

			; special vendor data
			WorkshopNPCScript asWorkshopNPC = assignedActor as WorkshopNPCScript
			if(asWorkshopNPC && bSetData)
				if(asWorkshopNPC.specialVendorType > -1 && asWorkshopNPC.specialVendorType == assignedObject.VendorType)
					; link to special vendor containers
					if(asWorkshopNPC.specialVendorContainerBase)
						; create the container ref if it doesn't exist yet
						if(asWorkshopNPC.specialVendorContainerRef == NONE)
							asWorkshopNPC.specialVendorContainerRef = WorkshopParent.WorkshopHoldingCellMarker.PlaceAtMe(asWorkshopNPC.specialVendorContainerBase)
						endif
						
						; link using 4th keyword
						asWorkshopNPC.SetLinkedRef(asWorkshopNPC.specialVendorContainerRef, VendorContainerKeywords.GetAt(VendorTopLevel+1) as Keyword)
					endif
					
					if(asWorkshopNPC.specialVendorContainerRefUnique)
						; link using 4th keyword
						asWorkshopNPC.SetLinkedRef(asWorkshopNPC.specialVendorContainerRefUnique, VendorContainerKeywords.GetAt(VendorTopLevel+2) as Keyword)
					endif
				endif
			else
				; always clear for safety
				if(asWorkshopNPC.specialVendorContainerRef)
					asWorkshopNPC.specialVendorContainerRef.Delete()
					asWorkshopNPC.specialVendorContainerRef = NONE
					; clear link
					asWorkshopNPC.SetLinkedRef(NONE, VendorContainerKeywords.GetAt(VendorTopLevel+1) as Keyword)
				endif
				
				if(asWorkshopNPC.specialVendorContainerRefUnique)
					; clear link
					asWorkshopNPC.SetLinkedRef(NONE, VendorContainerKeywords.GetAt(VendorTopLevel+2) as Keyword)
				endif
			endif
		else
			; ERROR
		endif
	elseif(assignedObject.sCustomVendorID != "") ; WSFW 2.0.0 - Adding support for custom vendors
		CustomVendor[] CustomVendorTypes = WorkshopParent.CustomVendorTypes
		int iIndex = CustomVendorTypes.FindStruct("sVendorID", assignedObject.sCustomVendorID)
		if(iIndex >= 0)
			if(bSetData)
				assignedActor.AddToFaction(CustomVendorTypes[iIndex].VendorFaction)
				if(CustomVendorTypes[iIndex].VendorKeyword)
					assignedActor.AddKeyword(CustomVendorTypes[iIndex].VendorKeyword)
				endif
			else
				assignedActor.RemoveFromFaction(CustomVendorTypes[iIndex].VendorFaction)
				if(CustomVendorTypes[iIndex].VendorKeyword)
					assignedActor.RemoveKeyword(CustomVendorTypes[iIndex].VendorKeyword)
				endif
			endif

			; -- assign vendor chests
			ObjectReference[] vendorContainers = workshopRef.GetCustomVendorContainers(assignedObject.sCustomVendorID)
			
			int i = 0
			while(i <= assignedObject.vendorLevel)
				if bSetData
					assignedActor.SetLinkedRef(vendorContainers[i], VendorContainerKeywords.GetAt(i) as Keyword)
				else
					assignedActor.SetLinkedRef(NONE, VendorContainerKeywords.GetAt(i) as Keyword)
				endif
				
				i += 1
			endWhile
			
			; TODO - Add support for special vendors (see above section for stuff we skipped regarding special vendors for this function), will require special container registration, moving to 4 container levels, and an addition to the UpdateVendorFlags function
		else
			; ERROR
			; Debug.MessageBox("Custom vendor type not found registered to workshop parent")
		endif
	endif
endFunction
;<<

;
; Replace WorkshopObjectScript.GetAssignedActor
;
Actor Function GetAssignedActor(ObjectReference akObjectRef) global
	Actor kAssignedActor = akObjectRef.GetActorRefOwner()
	if( ! kAssignedActor)
		; check for base actor ownership
		ActorBase baseActor = akObjectRef.GetActorOwner()
		
		if(baseActor && baseActor.IsUnique())
			; if this has Actor ownership, use GetUniqueActor when available to get the actor ref
			kAssignedActor = baseActor.GetUniqueActor()
		endif
	endif
	
	return kAssignedActor
EndFunction

; Replace WorkshopParent.TurnOnCaravanActor
function TurnOnCaravanActor(Actor caravanActor, bool bTurnOn, bool bBrahminCheck = true) global
	WorkshopParentScript WorkshopParent = GetWorkshopParent()
	Keyword WorkshopCaravanKeyword = GetWorkshopCaravanKeyword()
	; find linked locations
	WorkshopScript workshopStart = caravanActor.GetLinkedRef(GetWorkshopItemKeyword()) as WorkshopScript

	Location startLocation = workshopStart.myLocation
	Location endLocation = WorkshopParent.GetWorkshop(GetCaravanDestinationID(caravanActor)).myLocation

	if(bTurnOn)
		; add link between locations
		startLocation.AddLinkedLocation(endLocation, WorkshopCaravanKeyword)
	else
		; unlink locations
		startLocation.RemoveLinkedLocation(endLocation, WorkshopCaravanKeyword)
	endif

	if(bBrahminCheck)
		CaravanActorBrahminCheck(caravanActor, bTurnOn)
	endif
endFunction

; Replace WorkshopParent.CaravanActorBrahminCheck
function CaravanActorBrahminCheck(Actor akActorRef, bool abShouldHaveBrahmin = true) global
	WorkshopParentScript WorkshopParent = GetWorkshopParent()
	
	; is my brahmin dead?
	Actor kBrahminRef = GetMyBrahmin(akActorRef)
	if(kBrahminRef && kBrahminRef.IsDead())
		; clear
		WorkshopParent.CaravanBrahminAliases.RemoveRef(kBrahminRef)
		SetMyBrahmin(akActorRef, None)
		kBrahminRef = None
	endif
	
	; should I have a brahmin?
	if(IsCaravanNPC(akActorRef) && abShouldHaveBrahmin && akActorRef.GetValue(GetWorkshopActorWoundedAV()) <= 0)
		; if I don't have a brahmin, make me a new one
		if(kBrahminRef == None)
			kBrahminRef = akActorRef.PlaceAtMe(GetCaravanBrahminForm()) as Actor
			SetMyBrahmin(akActorRef, kBrahminRef)
		endif
	else
		; clear and delete brahmin
		if(kBrahminRef != None)
			; clear this and mark brahmin for deletion
			SetMyBrahmin(akActorRef, None)
			
			WorkshopParent.CaravanBrahminAliases.RemoveRef(kBrahminRef)			
			kBrahminRef.SetLinkedRef(None, GetWorkshopLinkFollowKeyword())
			kBrahminRef.Delete()			
		endif
	endif
endFunction


; global method of applying the WorkshopActorApply alias from WorkshopParent
Function ApplyWorkshopAliasStamp(Actor akActorRef) global
	WorkshopFramework:NPCManager NPCManager = GetNPCManager()
	
	NPCManager.WorkshopActorApply.ApplyToRef(akActorRef)
EndFunction

; global method of removing the WorkshopActorApply alias from WorkshopParent
Function RemoveWorkshopAliasStamp(Actor akActorRef) global
	WorkshopFramework:NPCManager NPCManager = GetNPCManager()
	
	NPCManager.WorkshopActorApply.RemoveFromRef(akActorRef)
EndFunction

;<<

; -----------------------------------
; WorkshopNPCScript Property/Variable/Etc Replacements
;
;/ 
These offer replacements for the properties and functions on WorkshopNPCScript via keywords, actorvalues, and other tricks.

Wherever a more feature rich version exists on WorkshopNPCScript, such as accessing a property that we can't fake, like CustomBossLocRefType, the actor will be tested for WorkshopNPCScript and if found, that version will be used.

This means that these functions can be used as a strict replacement in code even for actual WorkshopNPCScript actors.
/;
; ----------------------------------- 
;>>


Int Function GetWorkshopID(ObjectReference akObjectRef) global
	WorkshopNPCScript asWorkshopNPC = akObjectRef as WorkshopNPCScript
	if(asWorkshopNPC)
		return asWorkshopNPC.GetWorkshopID()
	endIf
	
	Actor asActor = akObjectRef as Actor
	if(asActor)
		ActorValue WorkshopIDAV = GetWorkshopIDAV()
		
		return (asActor.GetValue(WorkshopIDAV) as Int) - 1 ; Subtracting 1 because the default value of 0 will correspond to an actual workshop
	endif
	
	WorkshopScript asWorkshop = akObjectRef as WorkshopScript
	if(asWorkshop)
		return asWorkshop.GetWorkshopID()
	endif
	
	WorkshopObjectScript asWorkshopObject = akObjectRef as WorkshopObjectScript
	if(asWorkshopObject)
		return asWorkshopObject.workshopID
	endif
	
	return -1
EndFunction

Function SetWorkshopID(ObjectReference akObjectRef, Int aiWorkshopID) global
	WorkshopNPCScript asWorkshopNPC = akObjectRef as WorkshopNPCScript
	
	if(asWorkshopNPC)
		asWorkshopNPC.SetWorkshopID(aiWorkshopID)
	elseif(akObjectRef as Actor)
		ActorValue WorkshopIDAV = GetWorkshopIDAV()
		
		akObjectRef.SetValue(WorkshopIDAV, (aiWorkshopID + 1) as Float) ; Adding 1 to ensure that a default AV of 0 is considered a non-workshopID value (GetWorkshopID will subtract 1)
		
		WorkshopFramework:NPCManager NPCManager = GetNPCManager()
		
		NPCManager.NonWorkshopNPCScriptWorkshopChanged(akObjectRef as Actor, aiWorkshopID)
	endif
	
	WorkshopObjectScript asWorkshopObject = akObjectRef as WorkshopObjectScript
	if(asWorkshopObject)
		asWorkshopObject.workshopID = aiWorkshopID
	endif
	
	WorkshopScript asWorkshop = akObjectRef as WorkshopScript
	if(asWorkshop && asWorkshop.GetWorkshopID() < 0)
		asWorkshop.InitWorkshopID(aiWorkshopID)
	endif
EndFunction


Int Function GetCaravanDestinationID(Actor akActorRef) global
	ActorValue CaravanDestinationIDAV = GetCaravanDestinationIDAV()
	
	return akActorRef.GetValue(CaravanDestinationIDAV) as Int
EndFunction


Function SetCaravanDestinationID(Actor akActorRef, Int aiDestinationWorkshopID) global
	ActorValue CaravanDestinationIDAV = GetCaravanDestinationIDAV()
	
	akActorRef.SetValue(CaravanDestinationIDAV, aiDestinationWorkshopID as Float)
EndFunction


Function SetAsBoss(Actor akActorRef, Location aLocation) global
	WorkshopNPCScript asWorkshopNPC = akActorRef as WorkshopNPCScript
	
	if(asWorkshopNPC)
		asWorkshopNPC.SetAsBoss(aLocation)
	else
		akActorRef.SetLocRefType(aLocation, GetBossRefType())
		
		akActorRef.ClearFromOldLocations()
	endif
endFunction

;
; Replace WorkshopNPCScript.iSelfActivationCount variable
;

Function SetSelfActivationCount(Actor akActorRef, Int aiCount) global
	WorkshopNPCScript asWorkshopNPC = akActorRef as WorkshopNPCScript
	
	if(asWorkshopNPC)
		asWorkshopNPC.SetSelfActivationCount(aiCount)
	else
		akActorRef.SetValue(GetSelfActivationCountAV(), aiCount)
	endif
EndFunction


Int Function GetSelfActivationCount(Actor akActorRef) global
	WorkshopNPCScript asWorkshopNPC = akActorRef as WorkshopNPCScript
	
	if(asWorkshopNPC)
		return asWorkshopNPC.GetSelfActivationCount()
	else
		return akActorRef.GetValue(GetSelfActivationCountAV()) as Int
	endif
EndFunction


;
; Replace WorkshopNPCScript.multiResourceProduction variable
;

Float Function GetMultiResourceProduction(Actor akActorRef) global
	WorkshopNPCScript asWorkshopNPC = akActorRef as WorkshopNPCScript
	
	if(asWorkshopNPC)
		return asWorkshopNPC.multiResourceProduction
	else
		ActorValue MultiResourceProductionAV = GetMultiResourceProductionAV()
		
		return akActorRef.GetValue(MultiResourceProductionAV) as Int
	endif
EndFunction


Function SetMultiResourceProduction(Actor akActorRef, Float afValue) global
	WorkshopNPCScript asWorkshopNPC = akActorRef as WorkshopNPCScript
	
	if(asWorkshopNPC)
		asWorkshopNPC.multiResourceProduction = afValue
	else
		ActorValue MultiResourceProductionAV = GetMultiResourceProductionAV()
		
		akActorRef.SetValue(MultiResourceProductionAV, afValue)
	endif
EndFunction

;
; Replace WorkshopNPCScript.assignedMultiResource variable
;

ActorValue Function GetAssignedMultiResource(Actor akActorRef) global
	WorkshopNPCScript asWorkshopNPC = akActorRef as WorkshopNPCScript
	
	if(asWorkshopNPC)
		return asWorkshopNPC.assignedMultiResource
	else
		; Food
		Keyword FoodMultiResourceKW = GetFoodMultiResourceKW()
		if(akActorRef.HasKeyword(FoodMultiResourceKW))
			ActorValue FoodAV = GetFoodAV()
			
			return FoodAV
		else
			ActorValue SafetyAV = GetSafetyAV()
			
			return SafetyAV
		endif
	endif
	
	return None
EndFunction

Function SetAssignedMultiResource(Actor akActorRef, ActorValue aAVForm) global
	WorkshopNPCScript asWorkshopNPC = akActorRef as WorkshopNPCScript
	
	if(asWorkshopNPC)
		asWorkshopNPC.SetMultiResource(aAVForm)
	else
		if(aAVForm == None)
			; Food
			Keyword MultiResourceKW = GetFoodMultiResourceKW()
			akActorRef.RemoveKeyword(MultiResourceKW)
			; Safety
			MultiResourceKW = GetSafetyMultiResourceKW()
			akActorRef.RemoveKeyword(MultiResourceKW)
			
			return
		endif
		
		ActorValue FoodAV = GetFoodAV()
		if(aAVForm == FoodAV)
			Keyword FoodMultiResourceKW = GetFoodMultiResourceKW()
			akActorRef.RemoveKeyword(FoodMultiResourceKW)
		else
			Keyword SafetyMultiResourceKW = GetSafetyMultiResourceKW()
			akActorRef.RemoveKeyword(SafetyMultiResourceKW)
		endif
	endif
EndFunction


;
; Replace WorkshopNPCScript.bCommandable
;

Bool Function IsCommandable(Actor akActorRef) global
	WorkshopNPCScript asWorkshopNPC = akActorRef as WorkshopNPCScript
	
	if(asWorkshopNPC)
		return asWorkshopNPC.bCommandable
	else
		Keyword thisKW = GetCommandableKeyword()
		
		return akActorRef.HasKeyword(thisKW)
	endif
EndFunction

Function SetCommandable(Actor akActorRef, Bool abFlag) global
	WorkshopNPCScript asWorkshopNPC = akActorRef as WorkshopNPCScript
	
	if(asWorkshopNPC)
		asWorkshopNPC.SetCommandable(abFlag)
	else
		Keyword thisKW = GetCommandableKeyword()
		
		if(abFlag)
			akActorRef.AddKeyword(thisKW)
		else
			akActorRef.RemoveKeyword(thisKW)
		endif
	endif
EndFunction


;
; Replace WorkshopNPCScript.bAllowCaravan
;

Bool Function AllowCaravan(Actor akActorRef) global
	WorkshopNPCScript asWorkshopNPC = akActorRef as WorkshopNPCScript
	
	if(asWorkshopNPC)
		return asWorkshopNPC.bAllowCaravan
	else
		Keyword thisKW = GetAllowCaravanKeyword()
		
		return akActorRef.HasKeyword(thisKW)
	endif
EndFunction

Function SetAllowCaravan(Actor akActorRef, Bool abFlag) global
	WorkshopNPCScript asWorkshopNPC = akActorRef as WorkshopNPCScript
	
	if(asWorkshopNPC)
		asWorkshopNPC.SetAllowCaravan(abFlag)
	else
		Keyword thisKW = GetAllowCaravanKeyword()
		
		if(abFlag)
			akActorRef.AddKeyword(thisKW)
		else
			akActorRef.RemoveKeyword(thisKW)
		endif
	endif
EndFunction


;
; Replace WorkshopNPCScript.bAllowMove
;

Bool Function AllowMove(Actor akActorRef) global
	WorkshopNPCScript asWorkshopNPC = akActorRef as WorkshopNPCScript
	
	if(asWorkshopNPC)
		return asWorkshopNPC.bAllowMove
	else
		Keyword thisKW = GetAllowMoveKeyword()
		
		return akActorRef.HasKeyword(thisKW)
	endif
EndFunction

Function SetAllowMove(Actor akActorRef, Bool abFlag) global
	WorkshopNPCScript asWorkshopNPC = akActorRef as WorkshopNPCScript
	
	if(asWorkshopNPC)
		asWorkshopNPC.SetAllowMove(abFlag)
	else
		Keyword thisKW = GetAllowMoveKeyword()
		
		if(abFlag)
			akActorRef.AddKeyword(thisKW)
		else
			akActorRef.RemoveKeyword(thisKW)
		endif
	endif
EndFunction


; 
; Replace WorkshopNPCScript.bIsWorker
;
Bool Function IsWorker(Actor akActorRef) global
	WorkshopNPCScript asWorkshopNPC = akActorRef as WorkshopNPCScript
	
	if(asWorkshopNPC)
		return asWorkshopNPC.bIsWorker
	else
		Keyword thisKW = GetIsWorkerKeyword()
		
		return akActorRef.HasKeyword(thisKW)
	endif
EndFunction

Function SetWorker(Actor akActorRef, Bool abFlag) global
	WorkshopNPCScript asWorkshopNPC = akActorRef as WorkshopNPCScript
	
	if(asWorkshopNPC)
		asWorkshopNPC.SetWorker(abFlag)
	else
		Keyword thisKW = GetIsWorkerKeyword()
		
		if(abFlag)
			akActorRef.AddKeyword(thisKW)
		else
			akActorRef.RemoveKeyword(thisKW)
		endif
	endif
EndFunction


; 
; Replace WorkshopNPCScript.bWork24Hours
;
Bool Function DoesWork24Hours(Actor akActorRef) global
	WorkshopNPCScript asWorkshopNPC = akActorRef as WorkshopNPCScript
	
	if(asWorkshopNPC)
		return asWorkshopNPC.bWork24Hours
	else
		Keyword thisKW = GetWorks24HoursKeyword()
		
		return akActorRef.HasKeyword(thisKW)
	endif
EndFunction

Function SetWork24Hours(Actor akActorRef, Bool abFlag) global
	WorkshopNPCScript asWorkshopNPC = akActorRef as WorkshopNPCScript
	
	if(asWorkshopNPC)
		asWorkshopNPC.bWork24Hours = abFlag
	else
		Keyword thisKW = GetWorks24HoursKeyword()
		
		if(abFlag)
			akActorRef.AddKeyword(thisKW)
		else
			akActorRef.RemoveKeyword(thisKW)
		endif
	endif
EndFunction


; 
; Replace WorkshopNPCScript.bIsGuard
;
Bool Function IsGuard(Actor akActorRef) global
	WorkshopNPCScript asWorkshopNPC = akActorRef as WorkshopNPCScript
	
	if(asWorkshopNPC)
		return asWorkshopNPC.bIsGuard
	else
		Keyword thisKW = GetIsGuardKeyword()
		
		return akActorRef.HasKeyword(thisKW)
	endif
EndFunction

Function SetGuard(Actor akActorRef, Bool abFlag) global
	WorkshopNPCScript asWorkshopNPC = akActorRef as WorkshopNPCScript
	
	if(asWorkshopNPC)
		asWorkshopNPC.bIsGuard = abFlag
	else
		Keyword thisKW = GetIsGuardKeyword()
		
		if(abFlag)
			akActorRef.AddKeyword(thisKW)
		else
			akActorRef.RemoveKeyword(thisKW)
		endif
	endif
EndFunction


; 
; Replace WorkshopNPCScript.bIsScavenger
;
Bool Function IsScavenger(Actor akActorRef) global
	WorkshopNPCScript asWorkshopNPC = akActorRef as WorkshopNPCScript
	
	if(asWorkshopNPC)
		return asWorkshopNPC.bIsScavenger
	else
		Keyword thisKW = GetIsScavengerKeyword()
		
		return akActorRef.HasKeyword(thisKW)
	endif
EndFunction

Function SetScavenger(Actor akActorRef, Bool abFlag) global
	WorkshopNPCScript asWorkshopNPC = akActorRef as WorkshopNPCScript
	
	if(asWorkshopNPC)
		asWorkshopNPC.bIsScavenger = abFlag
	else
		Keyword thisKW = GetIsScavengerKeyword()
		
		if(abFlag)
			akActorRef.AddKeyword(thisKW)
		else
			akActorRef.RemoveKeyword(thisKW)
		endif
	endif
EndFunction


; 
; Replace WorkshopNPCScript.bIsSynth
;
Bool Function IsSynth(Actor akActorRef) global
	WorkshopNPCScript asWorkshopNPC = akActorRef as WorkshopNPCScript
	
	if(asWorkshopNPC)
		return asWorkshopNPC.bIsSynth
	else
		Keyword thisKW = GetIsSynthKeyword()
		
		return akActorRef.HasKeyword(thisKW)
	endif
EndFunction

Function SetSynth(Actor akActorRef, Bool abFlag) global
	WorkshopNPCScript asWorkshopNPC = akActorRef as WorkshopNPCScript
	
	if(asWorkshopNPC)
		asWorkshopNPC.bIsSynth = abFlag
	else
		Keyword thisKW = GetIsSynthKeyword()
		
		if(abFlag)
			akActorRef.AddKeyword(thisKW)
		else
			akActorRef.RemoveKeyword(thisKW)
		endif
	endif
EndFunction


; 
; Replace WorkshopNPCScript.bResetDone
;
Bool Function IsResetDone(Actor akActorRef) global
	WorkshopNPCScript asWorkshopNPC = akActorRef as WorkshopNPCScript
	
	if(asWorkshopNPC)
		return asWorkshopNPC.bResetDone
	else
		Keyword thisKW = GetResetDoneKeyword()
		
		return akActorRef.HasKeyword(thisKW)
	endif
EndFunction

Function SetResetDone(Actor akActorRef, Bool abFlag) global
	WorkshopNPCScript asWorkshopNPC = akActorRef as WorkshopNPCScript
	
	if(asWorkshopNPC)
		asWorkshopNPC.bResetDone = abFlag
	else
		Keyword thisKW = GetResetDoneKeyword()
		
		if(abFlag)
			akActorRef.AddKeyword(thisKW)
		else
			akActorRef.RemoveKeyword(thisKW)
		endif
	endif
EndFunction


; 
; Replace WorkshopNPCScript.bNewSettler
;
Bool Function IsNewSettler(Actor akActorRef) global
	WorkshopNPCScript asWorkshopNPC = akActorRef as WorkshopNPCScript
	
	if(asWorkshopNPC)
		return asWorkshopNPC.bNewSettler
	else
		Keyword thisKW = GetNewSettlerKeyword()
		
		return akActorRef.HasKeyword(thisKW)
	endif
EndFunction

Function SetNewSettler(Actor akActorRef, Bool abFlag) global
	WorkshopNPCScript asWorkshopNPC = akActorRef as WorkshopNPCScript
	
	if(asWorkshopNPC)
		asWorkshopNPC.bNewSettler = abFlag
	else
		Keyword thisKW = GetNewSettlerKeyword()
		
		if(abFlag)
			akActorRef.AddKeyword(thisKW)
		else
			akActorRef.RemoveKeyword(thisKW)
		endif
	endif
EndFunction


; 
; Replace WorkshopNPCScript.bCountsForPopulation
;
Bool Function CountsForPopulation(Actor akActorRef) global
	WorkshopNPCScript asWorkshopNPC = akActorRef as WorkshopNPCScript
	
	if(asWorkshopNPC)
		return asWorkshopNPC.bCountsForPopulation
	else
		Keyword thisKW = GetDoesNotCountForPopulationKeyword()
		
		return ! akActorRef.HasKeyword(thisKW) ; This is inverted - the keyword means - does NOT count for population
	endif
EndFunction

Function SetCountsForPopulation(Actor akActorRef, Bool abFlag) global
	WorkshopNPCScript asWorkshopNPC = akActorRef as WorkshopNPCScript
	
	if(asWorkshopNPC)
		asWorkshopNPC.bCountsForPopulation = abFlag
	else
		Keyword thisKW = GetDoesNotCountForPopulationKeyword()
		
		 ; This is inverted - the keyword means - does NOT count for population
		if(abFlag)
			akActorRef.RemoveKeyword(thisKW)
		else
			akActorRef.AddKeyword(thisKW)
		endif
	endif
EndFunction


; 
; Replace WorkshopNPCScript.bApplyWorkshopOwnerFaction
;
Bool Function ApplyWorkshopOwnerFaction(Actor akActorRef) global
	WorkshopNPCScript asWorkshopNPC = akActorRef as WorkshopNPCScript
	
	if(asWorkshopNPC)
		return asWorkshopNPC.bApplyWorkshopOwnerFaction
	else
		Keyword thisKW = GetDoNotApplyWorkshopOwnerFactionKeyword()
		
		return ! akActorRef.HasKeyword(thisKW) ; This is inverted - the keyword means - do NOT apply faction
	endif
EndFunction

Function SetApplyWorkshopOwnerFaction(Actor akActorRef, Bool abFlag) global
	WorkshopNPCScript asWorkshopNPC = akActorRef as WorkshopNPCScript
	
	if(asWorkshopNPC)
		asWorkshopNPC.bApplyWorkshopOwnerFaction = abFlag
	else
		Keyword thisKW = GetDoNotApplyWorkshopOwnerFactionKeyword()
		
		 ; This is inverted - the keyword means - do NOT apply faction
		if(abFlag)
			akActorRef.RemoveKeyword(thisKW)
		else
			akActorRef.AddKeyword(thisKW)
		endif
	endif
EndFunction


;
; Replace WorkshopNPCScript.StartCommandState
;
function StartCommandState(Actor akActorRef) global
	; clear "activate count"
	SetSelfActivationCount(akActorRef, 0)
	
	WorkshopScript myWorkshop = akActorRef.GetLinkedRef(GetWorkshopItemKeyword()) as WorkshopScript
	if(myWorkshop)
		akActorRef.SetDoingFavor(abDoingFavor = true, abWorkShopMode = true)
	endif
endFunction

;
; Replace WorkshopNPCScript.myBrahmin
;
Actor Function GetMyBrahmin(Actor akActorRef) global
	WorkshopNPCScript asWorkshopNPC = akActorRef as WorkshopNPCScript
	
	if(asWorkshopNPC)
		return asWorkshopNPC.myBrahmin
	else
		Keyword thisKW = GetBrahminLinkKeyword()
		
		Actor kBrahminRef = akActorRef.GetLinkedRef(thisKW) as Actor
		return kBrahminRef
	endif
EndFunction

Function SetMyBrahmin(Actor akActorRef, Actor akBrahminRef) global
	WorkshopNPCScript asWorkshopNPC = akActorRef as WorkshopNPCScript
	
	WorkshopParentScript WorkshopParent = GetWorkshopParent()
	Keyword WorkshopLinkFollow = GetWorkshopLinkFollowKeyword()
	
	if(akBrahminRef != None)
		akBrahminRef.SetActorRefOwner(akActorRef)
		WorkshopParent.CaravanBrahminAliases.AddRef(akBrahminRef)
		akBrahminRef.SetLinkedRef(akActorRef, WorkshopLinkFollow)
	endif
	
	if(asWorkshopNPC)
		asWorkshopNPC.myBrahmin = akBrahminRef
	else
		Keyword thisKW = GetBrahminLinkKeyword()
		
		akActorRef.SetLinkedRef(akBrahminRef, thisKW)
	endif
EndFunction


;
; Replace WorkshopNPCScript Wounded
;
bool function IsWounded(Actor akActorRef) global
	return akActorRef.GetValue(GetWorkshopActorWoundedAV()) as bool
endFunction

function SetWounded(Actor akActorRef, bool bIsWounded) global
	akActorRef.SetValue(GetWorkshopActorWoundedAV(), bIsWounded as int)
	
	WorkshopFramework:NPCManager NPCManager = GetNPCManager()
	int foundIndex = NPCManager.CaravanActorAliases.Find(akActorRef)
	if(foundIndex > -1)
		TurnOnCaravanActor(akActorRef, bIsWounded == false)
	endif
endFunction

;
; Replace WorkshopParent.WoundActor
;
function WoundActor(Actor woundedActor, bool bWoundMe = true, Bool abRecalculateResources = true) global
	WorkshopFramework:NPCManager NPCManager = GetNPCManager()
	
	NPCManager.WoundNPC(woundedActor, bWoundMe, abRecalculateResources)
EndFunction

;<<



; -----------------------------------
; Replacement functions routed through NPCManager
;
;/

Note that the versions here with locks default to true, while the versions on NPCManager default to false. The idea is that these are the API version other systems should be calling, while NPCManager will call it's own versions internally and we don't have to worry about accidentally permalocking by calling a lock from within a lock.

/;
; ----------------------------------- 
;>>

; Replacement for WorkshopParent.AddActorToWorkshopPUBLIC
Function AddActorToWorkshop(Actor akActorRef, WorkshopScript akWorkshopRef, Bool abResetMode = false) global
	WorkshopFramework:NPCManager NPCManager = GetNPCManager()
	NPCManager.AddNPCToWorkshop(akActorRef, akWorkshopRef, abResetMode)
endFunction

; Replacement for WorkshopParent.RemoveActorFromWorkshopPUBLIC
Function RemoveActorFromWorkshop(Actor akActorRef, WorkshopScript akWorkshopRef = None, Bool abNPCTransfer = false) global
	WorkshopFramework:NPCManager NPCManager = GetNPCManager()
	NPCManager.RemoveNPCFromWorkshop(akActorRef, akWorkshopRef, abNPCTransfer)
EndFunction

;
; Replace WorkshopObjectScript.AssignNPC and WorkshopParent.AssignActorToObject
;
;/
	AssignActorToObject from WorkshopParent, was split into three parts: AssignActorToObject, UpdateActorStatus, and HandleAssignmentRules. By default, this will call all 3 pieces.

	This allows us to send non-WorskhopNPCScript actors to the assignment method as well as do bulk assignment to objects without excess processing. 
	
	For example, if the managing code is bulk assigning an NPC to objects and has previously cleared their assignments, there is no reason to handle assignment rules on each item, nor should the worker's status be recalculated after each item. 
/;
Function AssignActorToObject(WorkshopObjectScript akWorkshopObject, Actor akNewActor = None, Bool abAutoHandleAssignmentRules = true, Bool abAutoUpdateActorStatus = true, Bool abRecalculateWorkshopResources = true) global
	WorkshopFramework:NPCManager NPCManager = GetNPCManager()
	
	NPCManager.AssignNPCToObject(akWorkshopObject, akNewActor, abAutoHandleAssignmentRules, abAutoUpdateActorStatus, abRecalculateWorkshopResources, abGetLock = true)
EndFunction

;
;/
UpdateWorkshopActorStatus is meant to be called after using AssignNPC to bypass WorkshopParent's assignment method. This handles much of the actor changes that WorkshopParent.AssignActorToObject would otherwise handle.
/;
;
Function UpdateWorkshopActorStatus(Actor akActorRef, WorkshopScript akWorkshopRef = None, Bool abHandleMultiResourceAssignment = true) global
	WorkshopFramework:NPCManager NPCManager = GetNPCManager()
	NPCManager.UpdateWorkshopNPCStatus(akActorRef, akWorkshopRef, abHandleMultiResourceAssignment, abGetLock = true)
EndFunction

; Decides whether new assigned actor should be unassigned from objects and unassigns previous owner
function HandleAssignmentRules(Actor akActorRef, WorkshopObjectScript akLastAssigned, Actor akCurrentOwner = None, bool abResetMode = false) global
	WorkshopFramework:NPCManager NPCManager = GetNPCManager()
	
	NPCManager.HandleNPCAssignmentRules(akActorRef, akLastAssigned, akCurrentOwner, abResetMode, abGetLock = true)
endFunction

; Alternative to UnassignActorFromObject from WorkshopParent
Function UnassignActorFromObject(Actor akActorRef, WorkshopObjectScript akWorkshopObject, bool abSendUnassignEvent = true, bool abResetMode = false, WorkshopScript akWorkshopRef = None) global
	WorkshopFramework:NPCManager NPCManager = GetNPCManager()
	
	NPCManager.UnassignNPCFromObject(akActorRef, akWorkshopObject, abSendUnassignEvent, abResetMode, akWorkshopRef, abGetLock = true)
endFunction


; Replace WorkshopParent.UnassignActor 
function UnassignActor(Actor akActorRef, bool abSendUnassignEvent = true, bool abResetMode = false, bool abNPCTransfer = false, bool abRemovingFromWorkshop = false, WorkshopScript akWorkshopRef = None) global
	WorkshopFramework:NPCManager NPCManager = GetNPCManager()
	
	NPCManager.UnassignNPC(akActorRef, abSendUnassignEvent, abResetMode, abNPCTransfer, abRemovingFromWorkshop, akWorkshopRef, abGetLock = true)
endFunction


; Replaces WorkshopParent.UnassignActor_Private_SkipExclusions - which was added by WSFW for when automated code wants to unassign an actor from everything, but leave them assigned to things that exclusions normally apply to. The reason for this existing, is that we also needed a version of  UnassignActor that would ignore exclusions when transfering the NPC to a different settlement, or when they die.
Function UnassignActorSkipExclusions(Actor akActorRef, WorkshopScript akWorkshopRef = None, Form aLastAssigned = None, Bool abAutoUpdateActorStatus = true) global
	WorkshopFramework:NPCManager NPCManager = GetNPCManager()
	
	NPCManager.UnassignNPCSkipExclusions(akActorRef, akWorkshopRef, aLastAssigned, abAutoUpdateActorStatus, abGetLock = true)
EndFunction


; Replace WorkshopParent.UnassignActorFromCaravan
Function UnassignActorFromCaravan(Actor akActorRef, WorkshopScript workshopRef, Bool bRemoveFromWorkshop = false) global
	WorkshopFramework:NPCManager NPCManager = GetNPCManager()
	
	NPCManager.UnassignNPCFromCaravan(akActorRef, workshopRef, bRemoveFromWorkshop, abGetLock = true)
EndFunction


; Replaces WorkshopParent.AssignCaravanActorPUBLIC
function AssignCaravanActor(Actor akActorRef, Location destinationLocation) global
	WorkshopFramework:NPCManager NPCManager = GetNPCManager()
	
	NPCManager.AssignCaravanNPC(akActorRef, destinationLocation, abGetLock = true)
endFunction


; Replacement for WorkshopParent.UpdateActorsWorkObjects
function UpdateActorsWorkObjects(Actor theActor, WorkshopScript workshopRef = NONE, bool bRecalculateResources = false) global
	WorkshopFramework:NPCManager NPCManager = GetNPCManager()
	
	NPCManager.UpdateNPCsWorkObjects(theActor, workshopRef, bRecalculateResources, abGetLock = true)
endFunction


; Replace WorkshopParent.ClearCaravansFromWorkshopPUBLIC - not strictly necessary since the signature does not include WorkshopNPCScript, but could be used to reduce WorkshopParent traffic
function ClearCaravansFromWorkshop(WorkshopScript workshopRef) global
	WorkshopFramework:NPCManager NPCManager = GetNPCManager()
	
	NPCManager.ClearCaravansFromSettlement(workshopRef, abGetLock = true)
endFunction


; Replacement for WorkshopParent.RemoveObjectFromWorkshop - not strictly necessary since the signature does not include WorkshopNPCScript, but could be used to reduce WorkshopParent traffic
Function RemoveObjectFromWorkshop(WorkshopObjectScript akWorkshopObject, WorkshopScript akWorkshopRef = None) global
	WorkshopFramework:NPCManager NPCManager = GetNPCManager()
	
	NPCManager.RemoveWorkshopObjectFromWorkshop(akWorkshopObject, akWorkshopRef, abGetLock = true)
EndFunction


; Replacement for WorkshopParent.UnassignObject - not strictly necessary since the signature does not include WorkshopNPCScript, but could be used to reduce WorkshopParent traffic
function UnassignObject(WorkshopObjectScript akWorkshopObject, bool abRemovingObject = false, bool abUnassigningMultipleResources = false, WorkshopScript akWorkshopRef = None) global
	WorkshopFramework:NPCManager NPCManager = GetNPCManager()
	
	NPCManager.UnassignWorkshopObject(akWorkshopObject, abRemovingObject, abUnassigningMultipleResources, akWorkshopRef, abGetLock = true)
endFunction

;<< 




; -----------------------------------
; Extra Utilities
;
;/
These are extra functions to make certain workshop related activity easier.
/;
;>>

; -----------------------------------

; -----------------------------------
; MakePermanentNPCFullSettler
;
; Description: Brings up the settlement select menu to send a permanent NPC to a settlement as a settler. This combined with all of the WorkshopNPCScript replacement code in this script file effectively allows for any NPC to be made a settler.
; -----------------------------------
Location Function MakePermanentNPCFullSettler(Actor akActorRef, Bool abCommandable = true, Bool abAllowCaravan = true, Bool abAllowMove = true) global
	Location ChosenLocation
	
	if(akActorRef as WorkshopNPCScript)
		Keyword WorkshopAssignHomePermanentActor = GetAssignHomePermanentActorKeyword()
		
		ChosenLocation = akActorRef.OpenWorkshopSettlementMenu(WorkshopAssignHomePermanentActor)
	else
		ChosenLocation = Game.GetPlayer().OpenWorkshopSettlementMenuEx(None)
		
		if(ChosenLocation != None)
			WorkshopParentScript WorkshopParent = GetWorkshopParent()
			WorkshopScript thisWorkshop = WorkshopParent.GetWorkshopFromLocation(ChosenLocation)
			
			if(thisWorkshop != None)
				AddActorToWorkshop(akActorRef, thisWorkshop)
			endif
		endif
	endIf
	
	SetCommandable(akActorRef, abCommandable)
	SetAllowCaravan(akActorRef, abAllowCaravan)
	SetAllowMove(akActorRef, abAllowMove)
	
	return ChosenLocation
EndFunction


; -----------------------------------
; IsCaravanNPC
;
; Description: Allows checking for caravan without checking aliases on WorkshopParent
; -----------------------------------
Bool Function IsCaravanNPC(Actor akActorRef, WorkshopScript akForWorkshop = None) global
	WorkshopScript checkWorkshop = akActorRef.GetLinkedRef(GetWorkshopLinkCaravanStartKeyword()) as WorkshopScript
	
	if(akForWorkshop == None)
		if(checkWorkshop != None)
			return true
		else
			return false
		endif
	elseif(akForWorkshop == checkWorkshop)
		return true
	endif
	
	; Still here, check if destination matches akForWorkshop
	checkWorkshop = akActorRef.GetLinkedRef(GetWorkshopLinkCaravanEndKeyword()) as WorkshopScript
	if(akForWorkshop == checkWorkshop)
		return true
	endif
	
	return false
EndFunction

; -----------------------------------
; IsTerminal
;
; Description: Tests item for various keywords that identify it as a terminal.
; -----------------------------------

Bool Function IsTerminal(ObjectReference akTestRef) global
	if( ! akTestRef)
		return false
	endif
	
	Keyword[] TerminalKeywords = GetTerminalKeywords()
	
	int i = 0
	while(i < TerminalKeywords.Length)
		if(akTestRef.HasKeyword(TerminalKeywords[i]))
			return true
		endif
		
		i += 1
	endWhile
	
	return false
EndFunction

; -----------------------------------
; GetNearestWorkshop
;
; Description: Grabs closest WorkshopScript reference - with some exceptions. If the object is linked to a settlement, it will grab that workshop. If an object is in a workshop's location, it will grab that. Lastly, it will search in a radius to find the closest.
; -----------------------------------

WorkshopScript Function GetNearestWorkshop(ObjectReference akToRef) global
	WorkshopScript nearestWorkshop = akToRef.GetLinkedRef(GetWorkshopItemKeyword()) as WorkshopScript
	if( ! nearestWorkshop)	
		WorkshopParentScript WorkshopParent = GetWorkshopParent()
		Location thisLocation = akToRef.GetCurrentLocation()
		nearestWorkshop = WorkshopParent.GetWorkshopFromLocation(thisLocation)
		
		if( ! nearestWorkshop)
			ObjectReference[] WorkshopsNearby = akToRef.FindAllReferencesWithKeyword(GetWorkshopKeyword(), 20000.0)
			int i = 0
			while(i < WorkshopsNearby.Length)
				if(nearestWorkshop)
					if(WorkshopsNearby[i].GetDistance(akToRef) < nearestWorkshop.GetDistance(akToRef))
						nearestWorkshop = WorkshopsNearby[i] as WorkshopScript
					endIf
				else
					nearestWorkshop = WorkshopsNearby[i] as WorkshopScript
				endif
				
				i += 1
			EndWhile
		endif
	endif
	
	return nearestWorkshop
EndFunction


; -----------------------------------
; GetSettlements
;
; Description: Returns an array of settlements based on criteria
;
; Parameters: abIncludeOutposts - if true, settlements which are flagged as Outposts will be included, abIncludeVassals - if true, settlements which are flagged as Vassals will be included, abIncludeVirtual - if true, settlements from the virtual workshops will be included, abIncludeHelpers - if true, settlements like the helper settlement set up for Nukaworld for tributes to go to will be included
; -----------------------------------

WorkshopScript[] Function GetSettlements(Bool abIncludeOutposts = true, Bool abIncludeVassals = false, Bool abIncludeVirtual = false, Bool abIncludeHelpers = false) global
	WorkshopScript[] Settlements = new WorkshopScript[0]
	
	WorkshopParentScript WorkshopParent = GetWorkshopParent()
	Keyword OutpostKeyword = GetOutpostKeyword()
	Keyword VassalKeyword = GetVassalKeyword()
	Keyword VRWorkshopKeyword = GetVRWorkshopKeyword()	
	
	WorkshopScript[] AllWorkshops = WorkshopParent.Workshops
	WorkshopScript NukaWorldTributeWorkshop = None
	if(Game.IsPluginInstalled("DLCNukaWorld.esm"))
		NukaWorldTributeWorkshop = Game.GetFormFromFile(0x00047DFB, "DLCNukaWorld.esm") as WorkshopScript
	endIf
	
	int i = 0 
	while(i < AllWorkshops.Length)
		if((abIncludeHelpers || AllWorkshops[i] != NukaWorldTributeWorkshop) && (abIncludeOutposts || ! AllWorkshops[i].HasKeyword(OutpostKeyword)) && (abIncludeVassals || ! AllWorkshops[i].HasKeyword(VassalKeyword)) && (abIncludeVirtual || ! AllWorkshops[i].HasKeyword(VRWorkshopKeyword)))
			Settlements.Add(AllWorkshops[i])
		endif
		
		i += 1
	endWhile
	
	return Settlements
EndFunction


; -----------------------------------
; GetPlayerOwnedSettlements
;
; Description: Returns an array of player owned settlements
;
; Parameters: abIncludeOutposts - if true, settlements which are flagged as Outposts will be included, abIncludeVassals - if true, settlements which are flagged as Vassals will be included, abIncludeVirtual - if true, settlements from the virtual workshops will be included
; -----------------------------------

WorkshopScript[] Function GetPlayerOwnedSettlements(Bool abIncludeOutposts = true, Bool abIncludeVassals = false, Bool abIncludeVirtual = false) global
	WorkshopScript[] OwnedSettlements = new WorkshopScript[0]
	
	WorkshopParentScript WorkshopParent = GetWorkshopParent()
	Keyword OutpostKeyword = GetOutpostKeyword()
	Keyword VassalKeyword = GetVassalKeyword()
	Keyword VRWorkshopKeyword = GetVRWorkshopKeyword()	
	
	WorkshopScript[] AllWorkshops = WorkshopParent.Workshops
	
	int i = 0 
	while(i < AllWorkshops.Length)
		if(AllWorkshops[i].OwnedByPlayer && (abIncludeOutposts || ! AllWorkshops[i].HasKeyword(OutpostKeyword)) && (abIncludeVassals || ! AllWorkshops[i].HasKeyword(VassalKeyword)) && (abIncludeVirtual || ! AllWorkshops[i].HasKeyword(VRWorkshopKeyword)))
			OwnedSettlements.Add(AllWorkshops[i])
		endif
		
		i += 1
	endWhile
	
	return OwnedSettlements
EndFunction

ObjectReference Function GetWorkshopSpawnPoint(WorkshopScript akWorkshopRef) global
	ObjectReference kSpawnPoint = None
	Keyword WorkshopLinkSpawn = GetWorkshopLinkSpawnKeyword()
	kSpawnPoint = akWorkshopRef.GetLinkedRef(WorkshopLinkSpawn)
	if(kSpawnPoint == None)
		Keyword WorkshopLinkCenter = GetWorkshopLinkCenterKeyword()
		kSpawnPoint = akWorkshopRef.GetLinkedRef(WorkshopLinkCenter)
		
		if(kSpawnPoint == None)
			kSpawnPoint = akWorkshopRef
		endif
	endif
	
	return kSpawnPoint
EndFunction

;<<

; -----------------------------------
; Get Form Functions
;
;/ 
The purpose of these is to avoid the need for a parent object to hold these as properties. This allows this script to act as an API that can be called from anywhere easily.
/;
; -----------------------------------
;>>

WorkshopParentScript Function GetWorkshopParent() global
	return Game.GetFormFromFile(0x0002058E, "Fallout4.esm") as WorkshopParentScript
EndFunction

WorkshopFramework:NPCManager Function GetNPCManager() global
	return Game.GetFormFromFile(0x000091E2, "WorkshopFramework.esm") as WorkshopFramework:NPCManager
EndFunction

Formlist Function GetExcludeFromAssignmentRulesFormlist() global
	return Game.GetFormFromFile(0x000092A8, "WorkshopFramework.esm") as Formlist
EndFunction

Keyword Function GetWorkshopLinkCaravanStartKeyword() global
	return Game.GetFormFromFile(0x00066EAE, "Fallout4.esm") as Keyword
EndFunction

Keyword Function GetWorkshopLinkCaravanEndKeyword() global
	return Game.GetFormFromFile(0x00066EAF, "Fallout4.esm") as Keyword
EndFunction

Keyword Function GetAssignHomePermanentActorKeyword() global
	return Game.GetFormFromFile(0x0014FC3B, "Fallout4.esm") as Keyword
EndFunction

Keyword Function GetWorkshopKeyword() global
	return Game.GetFormFromFile(0x00054BA7, "Fallout4.esm") as Keyword
EndFunction

Keyword Function GetOutpostKeyword() global
	return Game.GetFormFromFile(0x00249FD7, "Fallout4.esm") as Keyword
EndFunction

Keyword Function GetVassalKeyword() global
	return Game.GetFormFromFile(0x00249FDA, "Fallout4.esm") as Keyword
EndFunction

Keyword Function GetVRWorkshopKeyword() global
	return Game.GetFormFromFile(0x0024A34F, "Fallout4.esm") as Keyword
EndFunction

Keyword Function GetWorkshopItemKeyword() global
	return Game.GetFormFromFile(0x00054BA6, "Fallout4.esm") as Keyword
EndFunction

Keyword Function GetFoodMultiResourceKW() global
	return Game.GetFormFromFile(0x0000D766, "WorkshopFramework.esm") as Keyword
EndFunction

Keyword Function GetSafetyMultiResourceKW() global
	return Game.GetFormFromFile(0x0000D767, "WorkshopFramework.esm") as Keyword 
EndFunction

Keyword Function GetWorkshopRadioObjectKeyword() global
	return Game.GetFormFromFile(0x0002A196, "Fallout4.esm") as Keyword 
EndFunction

Keyword Function GetCommandableKeyword() global
	return Game.GetFormFromFile(0x0012818F, "Fallout4.esm") as Keyword 
EndFunction

Keyword Function GetAllowCaravanKeyword() global
	return Game.GetFormFromFile(0x0012818E, "Fallout4.esm") as Keyword
EndFunction

Keyword Function GetAllowMoveKeyword() global
	return Game.GetFormFromFile(0x00128190, "Fallout4.esm") as Keyword
EndFunction

Keyword Function GetIsWorkerKeyword() global
	return Game.GetFormFromFile(0x0000D762, "WorkshopFramework.esm") as Keyword
EndFunction

Keyword Function GetWorks24HoursKeyword() global
	return Game.GetFormFromFile(0x0000D763, "WorkshopFramework.esm") as Keyword
EndFunction

Keyword Function GetIsGuardKeyword() global
	return Game.GetFormFromFile(0x0000D764, "WorkshopFramework.esm") as Keyword
EndFunction

Keyword Function GetIsScavengerKeyword() global
	return Game.GetFormFromFile(0x0000D765, "WorkshopFramework.esm") as Keyword
EndFunction

Keyword Function GetIsSynthKeyword() global
	return Game.GetFormFromFile(0x0000D768, "WorkshopFramework.esm") as Keyword
EndFunction

Keyword Function GetResetDoneKeyword() global
	return Game.GetFormFromFile(0x0000D769, "WorkshopFramework.esm") as Keyword
EndFunction

Keyword Function GetNewSettlerKeyword() global
	return Game.GetFormFromFile(0x0000D76B, "WorkshopFramework.esm") as Keyword
EndFunction

Keyword Function GetDoesNotCountForPopulationKeyword() global
	return Game.GetFormFromFile(0x0000D76C, "WorkshopFramework.esm") as Keyword
EndFunction

Keyword Function GetDoNotApplyWorkshopOwnerFactionKeyword() global
	return Game.GetFormFromFile(0x0000D76C, "WorkshopFramework.esm") as Keyword
EndFunction

Keyword Function GetWorkshopLinkFollowKeyword() global
	return Game.GetFormFromFile(0x00020C3E, "Fallout4.esm") as Keyword
EndFunction


Keyword Function GetWorkshopLinkSpawnKeyword() global
	return Game.GetFormFromFile(0x0002A198, "Fallout4.esm") as Keyword
EndFunction

Keyword Function GetWorkshopLinkCenterKeyword() global
	return Game.GetFormFromFile(0x00038C0B, "Fallout4.esm") as Keyword
EndFunction

Keyword Function GetWorkshopLinkHomeKeyword() global
	return Game.GetFormFromFile(0x0002058F, "Fallout4.esm") as Keyword
EndFunction

Keyword Function GetWorkshopLinkSandboxKeyword() global
	return Game.GetFormFromFile(0x0022B5A7, "Fallout4.esm") as Keyword
EndFunction

Keyword Function GetWorkshopCaravanKeyword() global
	return Game.GetFormFromFile(0x00061C0C, "Fallout4.esm") as Keyword
EndFunction

Keyword Function GetWorkshopWorkObjectKeyword() global
	return Game.GetFormFromFile(0x00020592, "Fallout4.esm") as Keyword
EndFunction

Keyword Function GetBrahminLinkKeyword() global
	return Game.GetFormFromFile(0x0000D769, "WorkshopFramework.esm") as Keyword
EndFunction

ActorValue Function GetSelfActivationCountAV() global
	return Game.GetFormFromFile(0x00022EE7, "WorkshopFramework.esm") as ActorValue
EndFunction

ActorValue Function GetWorkshopActorWoundedAV() global
	return Game.GetFormFromFile(0x0000033B, "Fallout4.esm") as ActorValue
EndFunction

ActorValue Function GetWorkshopProhibitRenameAV() global
	return Game.GetFormFromFile(0x00249F0B, "Fallout4.esm") as ActorValue 
EndFunction

ActorValue Function GetVendorIncomeAV() global
	return Game.GetFormFromFile(0x0010C847, "Fallout4.esm") as ActorValue 
EndFunction

ActorValue Function GetWorkshopPlayerOwnedAV() global
	return Game.GetFormFromFile(0x0000033C, "Fallout4.esm") as ActorValue 
EndFunction

ActorValue Function GetMultiResourceProductionAV() global
	return Game.GetFormFromFile(0x0000D76F, "WorkshopFramework.esm") as ActorValue
EndFunction

ActorValue Function GetWorkshopIDAV() global
	return Game.GetFormFromFile(0x000002D1, "Fallout4.esm") as ActorValue 
EndFunction

ActorValue Function GetBedAV() global
	return Game.GetFormFromFile(0x00000334, "Fallout4.esm") as ActorValue 
EndFunction

ActorValue Function GetSafetyAV() global
	return Game.GetFormFromFile(0x00000333, "Fallout4.esm") as ActorValue 
EndFunction

ActorValue Function GetFoodAV() global
	return Game.GetFormFromFile(0x00000331, "Fallout4.esm") as ActorValue 
EndFunction

ActorValue Function GetWorkshopBrahminAV() global
	return Game.GetFormFromFile(0x0012722D, "Fallout4.esm") as ActorValue 
EndFunction

ActorValue Function GetPopulationAV() global
	return Game.GetFormFromFile(0x0012723E, "Fallout4.esm") as ActorValue 
EndFunction

ActorValue Function GetPopulationDamageAV() global
	return Game.GetFormFromFile(0x00127232, "Fallout4.esm") as ActorValue 
EndFunction

ActorValue Function GetUnassignedPopulationAV() global
	return Game.GetFormFromFile(0x00127240, "Fallout4.esm") as ActorValue 
EndFunction

ActorValue Function GetScavengeRatingAV() global
	return Game.GetFormFromFile(0x00086748, "Fallout4.esm") as ActorValue
EndFunction

ActorValue Function GetRobotPopulationAV() global
	return Game.GetFormFromFile(0x0012723F, "Fallout4.esm") as ActorValue 
EndFunction

GlobalVariable Function GetCurrentWorkshopIDGlobal() global
	return Game.GetFormFromFile(0x0003E0CE, "Fallout4.esm") as GlobalVariable
EndFunction

GlobalVariable Function GetAutoAssignFoodGlobal() global
	return Game.GetFormFromFile(0x000092AB, "WorkshopFramework.esm") as GlobalVariable
EndFunction

GlobalVariable Function GetAutoAssignDefenseGlobal() global
	return Game.GetFormFromFile(0x000092AA, "WorkshopFramework.esm") as GlobalVariable
EndFunction

GlobalVariable Function GetAutoAssignBedsGlobal() global
	return Game.GetFormFromFile(0x000092A9, "WorkshopFramework.esm") as GlobalVariable
EndFunction

GlobalVariable Function GetMaxFoodWorkPerSettlerGlobal() global
	return Game.GetFormFromFile(0x000092B7, "WorkshopFramework.esm") as GlobalVariable
EndFunction

GlobalVariable Function GetMaxSafetyWorkPerSettlerGlobal() global
	return Game.GetFormFromFile(0x000092B6, "WorkshopFramework.esm") as GlobalVariable
EndFunction

Form Function GetWorkshopBrahminForm() global
	return Game.GetFormFromFile(0x000091E5, "WorkshopFramework.esm") ; Getting our injectable version
EndFunction

Form Function GetCaravanBrahminForm() global
	return Game.GetFormFromFile(0x00114A66, "Fallout4.esm")
EndFunction

ActorValue Function GetCaravanDestinationIDAV() global
	return Game.GetFormFromFile(0x000A56F9, "Fallout4.esm") as ActorValue
EndFunction

ActorValue Function GetHappinessAV() global
	return Game.GetFormFromFile(0x00129157, "Fallout4.esm") as ActorValue
EndFunction

ActorValue Function GetHappinessTargetAV() global
	return Game.GetFormFromFile(0x00127238, "Fallout4.esm") as ActorValue
EndFunction

ActorValue Function GetLastAttackDaysSinceAV() global
	return Game.GetFormFromFile(0x00127239, "Fallout4.esm") as ActorValue
EndFunction


LocationRefType Function GetWorkshopSynthRefType() global
	return Game.GetFormFromFile(0x001346C9, "Fallout4.esm") as LocationRefType
EndFunction

LocationRefType Function GetWorkshopCaravanRefType() global
	return Game.GetFormFromFile(0x0012AFB2, "Fallout4.esm") as LocationRefType
EndFunction

LocationRefType Function GetBossRefType() global
	return Game.GetFormFromFile(0x00003956, "Fallout4.esm") as LocationRefType
EndFunction

Keyword[] Function GetTerminalKeywords() global
	Keyword[] TerminalKeywords = new Keyword[0]
	
	; Putting these in order of most to least common so checks for these can short as quickly as possible
	
		; AnimFurnDeskTerminal
	Keyword tempKeyword = Game.GetFormFromFile(0x000286E6, "Fallout4.esm") as Keyword
	if(tempKeyword)
		TerminalKeywords.Add(tempKeyword)
	endif
		
		; AnimFurnDeskTerminalNoChair
	tempKeyword = Game.GetFormFromFile(0x000FCB12, "Fallout4.esm") as Keyword
	if(tempKeyword)
		TerminalKeywords.Add(tempKeyword)
	endif
	
		; AnimFurnWallTerminal
	tempKeyword = Game.GetFormFromFile(0x000C2022, "Fallout4.esm") as Keyword
	if(tempKeyword)
		TerminalKeywords.Add(tempKeyword)
	endif
	
		; AnimFurnDeskTerminalWithChair
	tempKeyword = Game.GetFormFromFile(0x0010F78B, "Fallout4.esm") as Keyword
	if(tempKeyword)
		TerminalKeywords.Add(tempKeyword)
	endif	
	
		; AnimFurnWallTerminalInst
	tempKeyword = Game.GetFormFromFile(0x001E5DC6, "Fallout4.esm") as Keyword
	if(tempKeyword)
		TerminalKeywords.Add(tempKeyword)
	endif
	
		; AnimFurnWallTerminalInstFloor
	tempKeyword = Game.GetFormFromFile(0x001E5DC5, "Fallout4.esm") as Keyword
	if(tempKeyword)
		TerminalKeywords.Add(tempKeyword)
	endif
	
		; AnimFurnPCUseTerminal
	tempKeyword = Game.GetFormFromFile(0x000C01A6, "Fallout4.esm") as Keyword
	if(tempKeyword)
		TerminalKeywords.Add(tempKeyword)
	endif
	
	return TerminalKeywords
EndFunction


;<<
