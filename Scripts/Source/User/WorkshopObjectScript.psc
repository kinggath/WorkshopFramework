Scriptname WorkshopObjectScript extends ObjectReference
{script for workshop buildable objects
holds data about the object and sends event when build
(possibly all of this will turn out to be temp)
TODO - make const when it stops holding data
}

import WorkshopFramework:Library:DataStructures ; WSFW - 2.0.0
import WorkshopDataScript

WorkshopParentScript Property WorkshopParent Auto Const mandatory

Group VendorData
	int Property VendorType = -1 auto const
	{ based on index from WorkshopParent VendorTypes }

	int Property VendorLevel = 0 auto const
	{ level of vendor for this store: 0-2 }

	bool Property bVendorTopLevelValid = false auto hidden
	{ set to TRUE when this object counts as a valid top level vendor}

	String Property sCustomVendorID Auto Const ; WSFW - 2.0.0
	{ Set this OR VendorType, not both! Be sure you are using a custom vendor ID that has been registered by your mod or another mod via WorkshopParent.RegisterCustomVendor }
EndGroup

; the workshop that created me
; -1 means no workshop assigned (editor-placed object)
int Property workshopID = -1 auto hidden conditional

bool Property bAllowPlayerAssignment = true auto conditional
{ 	TRUE = player can assign NPCs to work on this object (default)
	FALSE = ignore assignment by player - scripted/editor set assignment is all that is allowed
}

bool Property bAllowAutoRepair = true auto conditional
{ TRUE = can be repaired automatically by daily update process
  FALSE = can ONLY be repaired manually by player
}

bool Property bEnablePlayerComments = true auto const
{
    TRUE = The player will comment on the lack of power or assignment when activating this object
    FALSE = The player won't do that
}

bool Property bDefaultPlayerOwnership = true auto conditional
{ 	TRUE = set to player ownership when built - this allows objects which aren't work objects to be targeted by enemies
	FALSE = no default player ownership
}

bool Property bWork24Hours = false auto const conditional
{ 	TRUE = NPCs assigned to this will be set to work 24 hours a day (no sleep, no relaxation)
	FALSE = normal work hours
}

Keyword Property AssignedActorLinkKeyword auto conditional
{ OPTIONAL - if specified, assigned actor will be linked to this object using this keyword
  allows assigned actor to hold position near the object in combat
}

; used by ResetWorkshop to indicate which objects it has finished with
bool Property bResetDone = false auto hidden
;UFO4P 2.0.6 Note:
;The ResetWorkshop function once used this bool to flag objects that were handled while looping through the damaged objects, so they would
;not be considered again when looping through the undamaged objects. However, because undamaged and damaged objects were filled in separate
;arrays, this case did never occur and this bool was obsolete from the beginning. In the vanilla script, ResetWorkshop did still update it
;but it was not used anymore since UFO4P 2.0.4. WorkshopParentScript is now reusing it to tag specific objects for tracking them, e.g. when
;objects are unassigned while their workshop is not loaded, so we cannot send any events immediately but have to do it later.


; INTERNAL VARIABLES:
	bool bHasMultiResource = false
	; true = this object has a "multi resource" - allows one NPC to work on multiple resource objects }

	ActorValue multiResourceValue
	; if bHasMultiResource = true, this stores the resource rating (if any) that allows multiple objects per NPC (e.g. food) }

	bool bMultiResourceInitialized = false
	; set to true after we've initialized multi-resource data - no need to do it again }



; furniture marker (for things that aren't furniture)
group FurnitureMarker
	Form Property FurnitureBase const auto
	{ if set, will be used to create reference (myFurnitureMarkerRef) when object is created }


	bool property bPlaceMarkerOnCreation = false const auto
	{ true = place marker when object is created -- this is a very special case, currently used only for MQ206 teleporter objects
	  false = place marker only when object is assigned (and delete when unassigned) }

	bool property bMarkersGetOwnership = true const auto
	{ true = markers get same ownership as object (e.g. flora work markers)
	  false = markers don't pick up object ownership (e.g. relaxation markers) }

	String[] property FurnitureMarkerNodes const auto
	{ Nodes to use to place furniture markers }

	; Patch 1.4 - add a special furniture base to look for that gets ownership based on its own flag
	Form Property SpecialFurnitureBase const auto
	{ use this as a flag - whereever this appears place at SpecialFurnitureBaseNode }

	String property SpecialFurnitureBaseNode const auto
	{ see above - node in FurnitureMarkerNodes array to place SpecialFurnitureBase }

	bool property bSpecialMarkerGetsOwnership = true const auto
	{ true = special marker gets same ownership as object
	  false = marker doesn't pick up object ownership }

	Keyword property SpecialFurniturePlacementKeyword const auto
	{ OPTIONAL - if it exists, only place SpecialFurnitureBase if owning actor has this keyword }
endGroup

ObjectReference[] Property myFurnitureMarkerRefs Auto Hidden ; 1.1.10 - Made a property so we can access this in an extended script


MovableStatic Property DamageHelper const auto
{ OPTIONAL - if set, create a damage helper when built and link it to me }

; damage helper reference
ObjectReference myDamageHelperRef

bool Property bRadioOn = true auto hidden		; for now only used on temp radio object

;
; WSFW New Editor Properties
;

Group WSFWSettings
	Keyword Property WorkshopContainerType Auto Const
	{ [Optional] If set, this will be linked to the workshop as a special sub-container for redirecting certain resources. See documentation for valid keywords. }

	; WSFW Change - Making this a property that can be defaulted in the CK and also changed dynamically at runtime
	Float Property fDefaultFloraResetHarvestDays = 1.0 Auto Const
	{ Number of days required before the player can harvest this again - only applies to Flora type }
EndGroup

Float WSFW_fFloraResetHarvestDays = 0.0
float Property floraResetHarvestDays
	Float Function Get()
		if(WSFW_fFloraResetHarvestDays != 0.0)
			return WSFW_fFloraResetHarvestDays
		else
			return fDefaultFloraResetHarvestDays
		endif
	EndFunction
	
	Function Set(Float aValue)
		WSFW_fFloraResetHarvestDays = aValue
	EndFunction
EndProperty

;--------------------------------------------------------
;	Added by UFO4P 2.0.3 for Bug #23211: 
;--------------------------------------------------------

ObjectReference Property myIdleMarkerRef = none auto

;--------------------------------------------------------
;	Added by UFO4P 2.0.6 for Bug #25215 
;--------------------------------------------------------

int resourceID = -2
;This value stores the resource index of this object (i.e. the index of its resource rating value in the WorkshopRatingValues array of WorkshopParentScript):
;0 - food, 3 - safety, 4 - water, 5 - power; additional values: -1 - none of these, and -2 - not initialized. This saves the ResetWorkshop() function the time
;to check the four corresponding actor values every time it runs a damage pass on this object.
;Note that this value can also be used for other purposes, e.g. to check in which helper array an object is stored. This saves subsequent calls of GetMulti
;ResourceValue() (on this script) and GetResourceIndex() (on WorkshopParentScript).

;--------------------------------------------------------

Event OnInit()
;	;WorkshopParent.wsTrace(self + " OnInit")
	; if an actor that requires power, make unconscious
	Actor meActor = (self as ObjectReference) as Actor
	if meActor && IsPowered() == false && RequiresPower() 
		meActor.SetUnconscious(true)
	endif
	if bPlaceMarkerOnCreation
		CreateFurnitureMarkers()
	endif
	
	;UFO4P 2.0.2 Bug #23017: Added check for a valid workshopID:
	;If there's no valid workshopID (which is the case for most objects if this event runs), the ResetWorkshop function will call this function anyway on the
	;player's first visit to this workshop, and there's no need to run it twice.
	if workshopID >= 0
		HandleCreation(false)
		
		;UFO4P 2.0.6 Bug #25215: on pre-placed objects, also initialize the resourceID:
		resourceID = WorkshopParent.InitResourceID (self)
	endif
EndEvent

event OnLoad()
	; create link on load if I have an owner
	if AssignedActorLinkKeyword
		Actor myOwner = GetActorRefOwner()
		if myOwner
			myOwner.SetLinkedRef(self, AssignedActorLinkKeyword)
		endif
	endif
EndEvent

event OnUnload()
	; remove link on unload if it exists, to avoid creating persistence
	if AssignedActorLinkKeyword
		Actor myOwner = GetActorRefOwner()
		if myOwner
			myOwner.SetLinkedRef(NONE, AssignedActorLinkKeyword)
		endif
	endif
EndEvent




; returns true if this object has a "multi resource" actor value
bool function HasMultiResource()
	if bMultiResourceInitialized
		return bHasMultiResource
	else
		GetMultiResourceValue()
		return bHasMultiResource
	endif
endFunction


; returns "multi resource" actor value, if any; otherwise returns NONE
ActorValue function GetMultiResourceValue()
	if bMultiResourceInitialized
		if bHasMultiResource
			return multiResourceValue
		else
			return NONE
		endif
	endif

	; otherwise, initialize multiresource values
	; get this once for speed
	WorkshopDataScript:WorkshopActorValue[] WorkshopResourceAVs = WorkshopParent.WorkshopResourceAVs
	int arrayLength = WorkshopResourceAVs.Length
	int i = 0
	while i < arrayLength
;		;WorkshopParent.wstrace(self + " i=" + i + ": WorkshopResourceAVs[i].resourceValue=" + WorkshopResourceAVs[i].resourceValue)
		; check for multi-resource
		if GetBaseValue(WorkshopResourceAVs[i].resourceValue) > 0 && WorkshopParent.WorkshopRatings[WorkshopResourceAVs[i].workshopRatingIndex].maxProductionPerNPC > 0
			;WorkshopParent.wstrace(self + " 	'Multi' resource found: " + WorkshopResourceAVs[i].resourceValue, bNormalTraceAlso=true)
			bHasMultiResource = true
			multiResourceValue = WorkshopResourceAVs[i].resourceValue
			i = arrayLength
		endif
		i += 1
	endWhile
	bMultiResourceInitialized = true
	
	; WSFW - 1.0.6 return the value after initialization in case the first call happens to be requesting the AV
	return multiResourceValue
endFunction

; returns true if this requires an actor assigned in order to produce/consume resources
bool function RequiresActor()
	return HasKeyword(WorkshopParent.WorkshopWorkObject)
endFunction

; returns true if this is considered a bed by the workshop system
bool function IsBed()
	float val = GetBaseValue(WorkshopParent.WorkshopRatings[WorkshopParent.WorkshopRatingBeds].resourceValue)
	;WorkshopParent.wsTrace(self + " IsBed=" + val )
	return ( val > 0 )
endFunction

; is an actor assigned to this?
bool function IsActorAssigned()
	bool val = GetAssignedNPC() != NONE
	if( !val && IsBed() && GetFactionOwner() != NONE)
		; if I'm a bed, faction ownership counts as valid "assignment"
		val = true
	endif
	
	return val
endFunction


; WSFW 2.0.0 - Added nonWorkshopNPCScript version
Actor function GetAssignedNPC()
	Actor assignedActor = GetActorRefOwner()
	if(!assignedActor)
		; check for base actor ownership
		ActorBase baseActor = GetActorOwner()
		
		if(baseActor && baseActor.IsUnique())
			; if this has Actor ownership, use GetUniqueActor when available to get the actor ref
			assignedActor = baseActor.GetUniqueActor()
		endif
	endif
	
	if(assignedActor == Game.GetPlayer())
		return None
	endIf
	
	return assignedActor
endFunction

WorkshopNPCScript function GetAssignedActor()
	; WSFW 2.0.0 rerouting through our other function
	Actor kAssignedActor = GetAssignedNPC()
	if(kAssignedActor)
		return kAssignedActor as WorkshopNPCScript
	endif
endFunction

bool function RequiresPower()
	return ( GetValue(WorkshopParent.PowerRequired) > 0 )
endFunction

bool function GeneratesPower()
	return ( GetValue(WorkshopParent.PowerGenerated) > 0 )
endFunction

; timer ID - waiting to respond to OnPowerOn event
int OnPowerOnTimer = 0
float OnPowerOnTimerLength = 0.5 	; in seconds
int OnPowerOnTimerMaxCount = 10		; max times to iterate waiting for OnPowerOn event (failsafe to end waiting for timer)
int OnPowerOnTimerCount = 0			; how many times have we iterated?

; timer event
Event OnTimer(int aiTimerID)
	; waiting to respond to OnPowerOn event
	if aiTimerID == OnPowerOnTimer
		OnPowerOnTimerCount += 1
		if OnPowerOnTimerCount <= OnPowerOnTimerMaxCount
			HandlePowerStateChange(true)
		endif
	endif
EndEvent

bool function IsFactionOwner(WorkshopNPCScript theActor)
	Faction theFaction = GetFactionOwner()
	return ( theFaction && theActor.IsInFaction(theFaction) )
endFunction

; special helper function for MQ206 objects
; just assign/remove actor ref ownership for specified actor
function AssignActorOwnership(Actor newActor = None)
	if newActor
		SetActorRefOwner(newActor, true)
		; create furniture marker if necessary
		if FurnitureBase && myFurnitureMarkerRefs.Length == 0
			CreateFurnitureMarkers()
			UpdatePosition()
		endif
		SetFurnitureMarkerOwnership(newActor)
	else
		SetActorRefOwner(none)
		; if marker placed on creation, just remove ownership
		if bPlaceMarkerOnCreation
			SetFurnitureMarkerOwnership(none)
		else
		; otherwise, delete marker when unassigned
			DeleteFurnitureMarkers()
		endif
	endif
endFunction

; helper function to set/clear ownership of furniture markers
function SetFurnitureMarkerOwnership(Actor newActor)
	if myFurnitureMarkerRefs.Length > 0
		int i = 0
		while i < myFurnitureMarkerRefs.Length
			if newActor
				; Patch 1.4 - special marker check
				bool bSetOwnership = bMarkersGetOwnership
				if SpecialFurnitureBase
					if myFurnitureMarkerRefs[i].GetBaseObject() == SpecialFurnitureBase && bSpecialMarkerGetsOwnership
						bSetOwnership = true
					endif
				endif
				if bSetOwnership
					myFurnitureMarkerRefs[i].SetActorRefOwner(newActor, true)
				endif
			else
				myFurnitureMarkerRefs[i].SetActorRefOwner(None)
			endif
			i += 1
		endWhile
	endif
endFunction

; helper function to delete furniture markers and clear array
function DeleteFurnitureMarkers()
	if myFurnitureMarkerRefs.Length > 0
		int i = 0
		while i < myFurnitureMarkerRefs.Length
			myFurnitureMarkerRefs[i].Delete()
			i += 1
		endWhile
		myFurnitureMarkerRefs.Clear()
	endif
endFunction


Function AssignNPC(Actor newActor = None)
	if(newActor)
		; if this is a bed, and has faction ownership OR actor base ownership, just keep it
		if( ! IsBed() || ! IsOwnedBy(newActor))
			SetActorRefOwner(newActor, true)
		endif
		
		; create furniture marker if necessary
		if(FurnitureBase && myFurnitureMarkerRefs.Length == 0)
			CreateFurnitureMarkers()
			UpdatePosition()
		endif
		
		if(myFurnitureMarkerRefs.Length > 0)
			SetFurnitureMarkerOwnership(newActor)
		endif

		; link actor to me if keyword
		if(AssignedActorLinkKeyword)
			;In case this function runs after a workshop has unloaded, the new owner should not be linked to the object to avoid
			;persistence (all WorkshopObjectScripts clear these links on unload and restore them on load).
			if(WorkshopID == WorkshopParent.WorkshopCurrentWorkshopID.GetValue())
				newActor.SetLinkedRef(self, AssignedActorLinkKeyword)
			endif
		endif
	else
		SetActorRefOwner(none)
		
		; default ownership = player (so enemies will attack them if appropriate)
		SetActorOwner(Game.GetPlayer().GetActorBase())
		
		if(myFurnitureMarkerRefs.Length > 0)
			; if marker placed on creation, just remove ownership
			if(bPlaceMarkerOnCreation)
				SetFurnitureMarkerOwnership(none)
			else
				; otherwise, delete markers when unassigned
				DeleteFurnitureMarkers()
			endif
		endif
	endif
	
	if(newActor as WorkshopNPCScript) ; Make sure any previous defined versions from extensions are called correctly
		AssignActorCustom(newActor as WorkshopNPCScript)
	else
		AssignNPCCustom(newActor)
	endif
EndFunction

function AssignActor(WorkshopNPCScript newActor = None)
	AssignNPC(newActor as Actor) ; WSFW 2.0.0 - Rerouting to our new version
endFunction

function AssignNPCCustom(Actor newActor)
	; blank function for extended scripts to use
endFunction

function AssignActorCustom(WorkshopNPCScript newActor)
	; blank function for extended scripts to use
	AssignNPCCustom(newActor as Actor) ; WSFW 2.0.0 - Rerouting to our new version
endFunction

function CreateFurnitureMarkers()
	if FurnitureBase == None
		return
	else
		; clear marker ref array for safety
		if myFurnitureMarkerRefs.Length > 0
			DeleteFurnitureMarkers()
		endif
		; recreate
		myFurnitureMarkerRefs = new ObjectReference[0]
	endif

	Form myFurnitureBase
	FormList myFormList = FurnitureBase as FormList

	int i = 0
	while i < FurnitureMarkerNodes.Length
		; place marker at each node
		if myFormList
			; if FurnitureBase is a form list, pick one at random
			int pickIndex = Utility.RandomInt(0, myFormList.GetSize() - 1)
			myFurnitureBase = myFormList.GetAt(pickIndex)
		else
			; otherwise, just use FurnitureBase
			myFurnitureBase = FurnitureBase
		endif

		; Patch 1.4 - special marker check
		if SpecialFurnitureBase
			; if this node matches the special node, use this instead of normal marker
			String currentNode = FurnitureMarkerNodes[i]
			if currentNode == SpecialFurnitureBaseNode
				if SpecialFurniturePlacementKeyword
					; if keyword is present, only place this marker if owner has this keyword
					Actor myOwner = GetActorRefOwner()
					if myOwner && myOwner.HasKeyword(SpecialFurniturePlacementKeyword)
						myFurnitureBase = SpecialFurnitureBase
					else
						myFurnitureBase = NONE
					endif
				else
					myFurnitureBase = SpecialFurnitureBase
				endif
			endif
		endif

		if myFurnitureBase
			ObjectReference newMarker = PlaceAtMe(myFurnitureBase)
			; add to array
			myFurnitureMarkerRefs.Add(newMarker)
			;UFO4P 1.0.3 Bug #20580: Added 3D check
			if WaitFor3DLoad() && HasNode(FurnitureMarkerNodes[i])
				newMarker.MoveToNode(self, FurnitureMarkerNodes[i])
			endif
			;UFO4P 1.0.3 Bug #20580: Added check for parent cell being loaded (otherwise, no navmesh will be found):
			if newMarker.GetParentCell() && newMarker.GetParentCell().IsLoaded()
				; move to closest spot on navmesh
				newMarker.MoveToNearestNavmeshLocation()
			endif
		endif

		i += 1
	endWhile

endFunction

function HandleDestruction()
	;debug.tracestack(self + " HandleDestruction")

	;UFO4P 1.0.5 Bug #21028: Added check for workshopID: Don't try to get a workshopRef (and to run subsequent functions that rely on it) if the crop that runs
	;this script is not assigned to a workshop:
	if workshopID >= 0
		;WorkshopParent.wsTrace(self + "HandleDestruction")
		WorkshopScript workshopRef = GetWorkshop()

		RecalculateResourceDamage(workshopRef)

		;WorkshopParent.wsTrace(self + "HandleDestruction: done with resources")
		WorkshopParent.UpdateWorkshopRatingsForResourceObject(self, GetWorkshop(), bRecalculateResources = false)
		
		;UFO4P 1.0.5 Bug #21028: Moved this here from the end of the function:
		; send custom event for this object
		WorkshopParent.SendDestructionStateChangedEvent(self, workshopRef)
		;WorkshopParent.wsTrace(self + "HandleDestruction: sent event")
	endif

	; destroy furniture marker if any
	int i = 0
	while i < myFurnitureMarkerRefs.Length
		myFurnitureMarkerRefs[i].SetDestroyed()
		i += 1
	endwhile

	; if Flora, mark as harvested
	if GetBaseObject() as Flora
		SetHarvested(true)
	endif
	
	;UFO4P 2.0.3 Bug #23211: Added these lines to handle the pre-placed gardening markers at Graygarden:
	if myIdleMarkerRef
		myIdleMarkerRef.DisableNoWait()
	endif
endFunction

function RecalculateResourceDamage(WorkshopScript workshopRef = NONE, bool clearAllDamage = false)
	if workshopRef == NONE
		; get it
		workshopRef = GetWorkshop()
	endif

	; get this once for speed
	WorkshopDataScript:WorkshopActorValue[] WorkshopResourceAVs = WorkshopParent.WorkshopResourceAVs

	; recalc total damage ratings for each relevant resource
	int i = 0
	int arrayLength = WorkshopResourceAVs.Length
	while i < arrayLength
		ActorValue resourceValue = WorkshopResourceAVs[i].resourceValue
		float baseValue = GetBaseValue(resourceValue)
		if baseValue > 0
			if clearAllDamage 
				; restore this value
				RestoreValue(resourceValue, baseValue)
			endif
			;WorkshopParent.wsTrace(self + "RecalculateResourceDamage: resource  " + resourceValue)
			; recalculate the total damage for this resource
			WorkshopParent.RecalculateResourceDamageForResource(workshopRef, resourceValue)
		endif
		i += 1
	endWhile

	; update overall damage
	WorkshopParent.UpdateCurrentDamage(workshopRef)

endFunction

Event OnDestructionStageChanged(int aiOldStage, int aiCurrentStage)
	;WorkshopParent.wsTrace(self + " OnDestructionStageChanged: oldStage=" + aiOldStage + ", currentStage=" + aiCurrentStage)
	if IsDestroyed()
		HandleDestruction()
	elseif aiCurrentStage == 0
		WorkshopScript workshopRef = GetWorkshop()
		; I've been repaired  - clear all damage
		RecalculateResourceDamage(workshopRef, true)
		; send custom event for this object
		WorkshopParent.SendDestructionStateChangedEvent(self, workshopRef)

		;UFO4P 2.0.4 Bug #24312: added these lines:
		;Once repaired, fill unassigned multi-resource objects in the UFO4P object arrays, so they can get assigned:
		if HasMultiResource() && HasKeyword (WorkshopParent.WorkshopWorkObject) && GetAssignedNPC() == none
			WorkshopParent.UFO4P_AddObjectToObjectArray (self)
		endif

		;UFO4P 2.0.5 Bug #24775: added check:
		;Reset the actor value that controls the harvest time. Otherwise, this crop will regrow faster than a newly built one.
		if GetBaseObject() as Flora
			SetValue(WorkshopParent.WorkshopFloraHarvestTime, Utility.GetCurrentGameTime())
		endif
	endif
EndEvent

Event OnPowerOn(ObjectReference akPowerGenerator)
	;WorkshopParent.wsTrace(self + " OnPowerOn akPowerGenerator=" + akPowerGenerator)
	HandlePowerStateChange(true)
EndEvent

Event OnPowerOff()
	;WorkshopParent.wsTrace(self + " OnPowerOff")
	HandlePowerStateChange(false)
EndEvent

function HandlePowerStateChange(bool bPowerOn = true)
	if bPowerOn
		; if we don't have a workshopID yet, wait to handle this later
		if workshopID < 0
			;WorkshopParent.wsTrace(self + " HandlePowerStateChange: waiting for valid workshop ID")
			StartTimer(OnPowerOnTimerLength, OnPowerOnTimer)
			return
		endif

		; we got an ID, clear the counter
		OnPowerOnTimerCount = 0
	endif
	WorkshopParent.UpdateWorkshopRatingsForResourceObject(self, GetWorkshop(), bRecalculateResources = false) ; code handles recalculating resources from power state changes

	; send custom event for this object
	WorkshopScript workshopRef = GetWorkshop()
	WorkshopParent.SendPowerStateChangedEvent(self, workshopRef)
endFunction

Event OnActivate(ObjectReference akActionRef)
	;WorkshopParent.wsTrace(self + " activated by " + akActionRef + " isradio?" + HasKeyword(WorkshopParent.WorkshopRadioObject))
	if akActionRef == Game.Getplayer() 
		;WorkshopParent.wstrace(self + " activated by player")
		if CanProduceForWorkshop()
			if HasKeyword(WorkshopParent.WorkshopRadioObject)
				; radio on/off
				; toggle state
				bRadioOn = !bRadioOn
				WorkshopParent.UpdateRadioObject(self)
			endif
		else
		endif
		
		; player comment
		if(bEnablePlayerComments && IsBed() == false) ; 2.0.8
			WorkshopParent.PlayerComment(self)
		endif
	endif

	if GetBaseObject() as Flora
		SetValue(WorkshopParent.WorkshopFloraHarvestTime, Utility.GetCurrentGameTime())
	endif
EndEvent


; WSFW 2.0.0 - Alternate version for nonWorkshopNPCScript actors
function ActivatedByWorkshopNPC(Actor akSettlerRef)
	If(workshopID == -1)
		Return
	EndIf

	if(akSettlerRef && akSettlerRef.IsDoingFavor() && akSettlerRef.IsInFaction(WorkshopParent.Followers.CurrentCompanionFaction) == false)
		if(bAllowPlayerAssignment)
			; turn off favor state
			akSettlerRef.setDoingFavor(false, false) ; going back to using normal command mode for now
			
			; unregister for distance event
			akSettlerRef.UnregisterForDistanceEvents(akSettlerRef, GetWorkshop())
			
			; assign this NPC to me if this is a work object
			if(RequiresActor() || IsBed())
				akSettlerRef.SayCustom(WorkshopParent.WorkshopParentAssignConfirmTopicType)
				
				WorkshopFramework:WorkshopFunctions.AssignActorToObject(self, akSettlerRef, abRecalculateWorkshopResources = false)
				WorkshopParent.WorkshopResourceAssignedMessage.Show()
				
				if(akSettlerRef as WorkshopNPCScript)
					; This will make the AI Package work the assigned object for 2 minutes, regardless of time of day so the player feels like things are responsive
					(akSettlerRef as WorkshopNPCScript).StartAssignmentTimer()
				endif
				
				; if food/water/safety are missing, run check if this is that kind of object
				if(IsBed() == false)
					WorkshopScript workshopRef = GetWorkshop()
					workshopRef.RecalculateResources()
				endif
			endif
			
			akSettlerRef.EvaluatePackage()
		else
			WorkshopParent.WorkshopResourceNoAssignmentMessage.Show()
		endif
	endif
endFunction


function ActivatedByWorkshopActor(WorkshopNPCScript workshopNPC)
	; WSFW 2.0.0 - Rerouting to our version that doesn't require WorkshopNPCScript
	ActivatedByWorkshopNPC(workshopNPC as Actor)
endFunction

; returns TRUE if object was actually damaged/repaired
; otherwise FALSE
bool function ModifyResourceDamage(ActorValue akActorValue, float aiDamageMod)
	WorkshopParent.wsTrace(self + "	ModifyResourceDamage: " + akActorValue + " " + aiDamageMod)
	;/
	----------------------------------------------------------------------------------------------------------
		UFO4P 2.0.5 Bug #24637:
		Some of the operations of this could be substantially simplified. To keep the code legible
		it has been rewritten. Comments on edits prior to UFO4P 2.0.5 have been left out.
	----------------------------------------------------------------------------------------------------------
	/;

	if aiDamageMod == 0.0
		;no damage means that the object's status won't change
		return false
	endif

	float totalDamage = 0
	float baseValue = GetBaseValue (akActorValue)
	bool returnVal = false

	if baseValue > 0
		if aiDamageMod < 0 
			; negative aiDamageMod = repair
			if bAllowAutoRepair
				WorkshopParent.wsTrace(self + "		restoring " + (aiDamageMod * -1) + " to " + akActorValue)
				RestoreValue(akActorValue, aiDamageMod * -1)
				returnVal = true
			endif
		else
			; positive aiDamageMod = damage
			float currentValue = GetValue (akActorValue)
			WorkshopParent.wsTrace(self + "		currentDamage = " + (baseValue - currentValue) + ", baseValue = " + baseValue)
			; total damage can't exceed base value, so make sure it doesn't:
			aiDamageMod = Math.Min (aiDamageMod, currentValue)
			WorkshopParent.wsTrace(self + "		final aiDamageMod = " + aiDamageMod)
			DamageValue(akActorValue, aiDamageMod)
			returnVal = true
		endif
		; update total damage:
		totalDamage = baseValue - GetValue(akActorValue)
	endif
	
	WorkshopParent.wsTrace(self + "		totalDamage = " + totalDamage)

	; if there is any damage, destroy me
	if totalDamage > 0
		if IsDestroyed() == false
			; state change
			SetDestroyed(true)
			DamageObject(9999.0)
			;UFO4P 2.0.5 Bug #24642: no need to call HandleDestruction() here:
			;SetDestroyed will trigger an OnDestructionStageChanged event and that event calls HabdleDestruction() anyway
		endif
		WorkshopParent.wsTrace(self + "		DESTROYED")
	else
		WorkshopParent.wsTrace(self + "		UNDESTROYED")
		Repair()

		int i = 0
		while i < myFurnitureMarkerRefs.Length
			myFurnitureMarkerRefs[i].SetDestroyed(false)
			i += 1
		endWhile

		if myDamageHelperRef
			myDamageHelperRef.ClearDestruction()
		endif
	
		if myIdleMarkerRef
			myIdleMarkerRef.Enable()
		endif
	endif

	return returnVal
endFunction

Event OnWorkshopObjectGrabbed(ObjectReference akReference)
	;debug.trace(self + " OnWorkshopObjectGrabbed")
	; disable markers while moving
	HideMarkers()
EndEvent

Event OnWorkshopObjectMoved(ObjectReference akReference)
	;debug.trace(self + " OnWorkshopObjectMoved")
	UpdatePosition()
EndEvent

function UpdatePosition()

	;UFO4P 2.0 Bug #21656: Added this variable for use in a sanity check below. An object may not have nodes specified for every marker to be placed,
	;and thus the FurnitureMarkerNodes array may not have the same length as the myFurnitureMarkerRefs array. This could result in 'index out of range'
	;errors because the script tried to access non-existing positions in the FurnitureMarkerNodes array.
	int UFO4P_NodeArrayLength = 0
	if FurnitureMarkerNodes
		UFO4P_NodeArrayLength = FurnitureMarkerNodes.Length
	endIf
	
	int i = 0
	int size = myFurnitureMarkerRefs.Length
	while i < size
		ObjectReference theMarker = myFurnitureMarkerRefs[i]
		;debug.trace(self + " UpdatePosition: marker " + i + ": " + theMarker)
		; make sure enabled
		theMarker.Enable()
		theMarker.MoveTo(self)
		;debug.trace(self + " 	UpdatePosition: " + theMarker + "GetDistance=" + theMarker.GetDistance(self))
		;UFO4P 1.0.3 Bug #20580: Added 3D check
		;UFO4P 2.0 Bug #21656: Added another check to avoid 'index out of range' errors when trying to access the FurnitureMarkerNodes array
		if i < UFO4P_NodeArrayLength && WaitFor3DLoad() && HasNode(FurnitureMarkerNodes[i])
			;debug.trace(self + " 	UpdatePosition: moving to node " + FurnitureMarkerNodes[i])
			theMarker.MoveToNode(self, FurnitureMarkerNodes[i])
			;debug.trace(self + " 	UpdatePosition: " + theMarker + "GetDistance=" + theMarker.GetDistance(self))
		endif
		; move to closest spot on navmesh
		;UFO4P 1.0.3 Bug #20580: Added check for parent cell being loaded (otherwise, no navmesh will be found)
		if theMarker.GetParentCell() && theMarker.GetParentCell().IsLoaded()
			;debug.trace(self + " 	UpdatePosition: now move to nearest navmesh location")
			;debug.trace(self + " 	UpdatePosition: " + theMarker + "GetDistance=" + theMarker.GetDistance(self))
			theMarker.MoveToNearestNavmeshLocation()
			;debug.trace(self + " 	UpdatePosition: " + theMarker + "GetDistance=" + theMarker.GetDistance(self))
		endif
		i += 1
	endWhile
	
	;UFO4P 2.0.4 Bug #23755: added a check for deleted damage helpers:
	;There's evidence that thic ode may run after the HandleDeletion() function if a crop is first moved and then immediately stored in the workbench.
	if myDamageHelperRef && myDamageHelperRef.IsDeleted() == false
		myDamageHelperRef.Moveto(self)
		; make sure enabled
		myDamageHelperRef.Enable()
	endif
	
	;UFO4P 2.0.3 Bug #23211: Added the following lines:
	;This is to handle the MrHandy gardening markers of the mutfruits at Graygarden. They should now move together with the crops.
	;To make this work, the pre-placed mutfruits have the pre-placed markers specified in the new myIdleMarkerRef property. Also note that the
	;script only handles the already existing markers. It won't create any new ones.
	if myIdleMarkerRef
		myIdleMarkerRef.Enable()
		float helperAngle = 90 - self.GetAngleZ()
		float yOffset = 120.0 * Math.sin (helperAngle)
		float xOffset = 120.0 * Math.cos (helperAngle)
		myIdleMarkerRef.MoveTo (self, afXOffset = xOffset, afYOffset = yOffset)
		myIdleMarkerRef.SetAngle (0.0, 0.0, self.GetAngleZ() + 180.0)
		myIdleMarkerRef.MoveToNearestNavmeshLocation()
	endif
	
endFunction

function HideMarkers()
	int i = 0
	int size = myFurnitureMarkerRefs.Length
	while i < size
		myFurnitureMarkerRefs[i].Disable()
		i += 1
	endWhile
	
	if myDamageHelperRef
		myDamageHelperRef.Disable()
	endif

	;UFO4P 2.0.3 Bug #23211: Added these lines to handle the pre-placed gardening markers at Graygarden:
	if myIdleMarkerRef
		myIdleMarkerRef.DisableNoWait()
	endif

endFunction

; called when object is created
;UFO4P 1.0.5 Note: This function is also called by the ResetWorkshop function on WorkshopParentScript (with bNewlyBuilt = false) if the object has not yet been
;assigned to a workshop (i.e. if workshopID = -1)
function HandleCreation(bool bNewlyBuilt = true)
	; create damage helper if appropriate

	;UFO4P 1.0.5 Bug #21039: Added this to replace the vanilla code below: call the new UFO4P_ValidateDamageHelperRef function to make sure that there
	;is a valid reference in myDamageHelperRef. If there's a broken pointer in myDamagHelperRef, the check performed by the vanilla code would return false
	;and it would not create a new helper but the reference stored in myDamagHelperRef would be unusable and there would be problems cropping up down the
	;line such as the crop becoming indestructible after having been damaged once. The new function can detect broken pointers and tries to repair them;
	;if that's not possible or if there's really no helper existing (i.e. if myDamagHelperRef is really 'none'), it will create a new helper (for more
	;information, see general notes on this bug in the sectin at the end of this script).
	;Note: Calling this function here is for safety reasons. There actually should be no damage helper existing when the HandleCreation function runs.
	if DamageHelper
		UFO4P_ValidateDamageHelperRef()
	endIf

	;if DamageHelper && !myDamageHelperRef
		;myDamageHelperRef = PlaceAtMe(DamageHelper)
;		 link to me
		;myDamageHelperRef.SetLinkedRef(self)
	;endif

	if bNewlyBuilt
		; if flora, mark initially as harvested
		if GetBaseObject() as Flora
			SetHarvested(true)
			;UFO4P 2.0.5 Bug #24775: also initialize the related actor value:
			SetValue (WorkshopParent.WorkshopFloraHarvestTime, Utility.GetCurrentGameTime())
		endif	

		;UFO4P 2.0.6 Bug #25215: also initialize the resourceID:
		resourceID = WorkshopParent.InitResourceID (self)	
	endif

	; if unowned, give player ownership
	if HasOwner() == false && IsBed() == false && bDefaultPlayerOwnership
		; default ownership = player (so enemies will attack them if appropriate)
		SetFactionOwner(WorkshopParent.PlayerFaction)
		;WorkshopParent.wsTrace(self + " HandleCreation: unowned, assigning PlayerFaction ownership: " + GetFactionOwner())
	endif	
endFunction

; clean up created refs when deleted
function HandleDeletion()

	if(myFurnitureMarkerRefs != None && myFurnitureMarkerRefs.Length > 0)
		DeleteFurnitureMarkers()
	endif
	
	if myDamageHelperRef
		;myDamageHelperRef.Delete()
		;UFO4P 1.0.5 Bug #20945: Replaced the previous line with a call of the new UFO4P_DeleteDamageHelper function to delete the helper:
		UFO4P_DeleteDamageHelper()
	endif

	;UFO4P 2.0.3 Bug #23211: Added these lines to handle the pre-placed gardening markers at Graygarden:
	if myIdleMarkerRef
		myIdleMarkerRef.DisableNoWait()
		myIdleMarkerRef = none
	endif
endFunction

; called on workshop objects during reset
function HandleWorkshopReset()
	; since workshop locations don't reset, do it manually
	float harvestTime = GetValue(WorkshopParent.WorkshopFloraHarvestTime)
	if GetBaseObject() as Flora
		;WorkshopParent.wsTrace(self + " HandleWorkshopReset: last harvest time=" + harvestTime +", IsActorAssigned=" + IsActorAssigned() + ", current time=" + utility.GetCurrentGameTime())
		;UFO4P 2.0.5 Bug #24775: also check for destroyed crops. Otherwise, they may be regrown immediately after the repair:
		if !IsDestroyed() && IsActorAssigned() && utility.GetCurrentGameTime() > (harvestTime + floraResetHarvestDays)
			SetHarvested(false)
		endif
	endif
endFunction


bool function HasResourceValue(ActorValue akValue)
	if akValue && GetBaseValue(akValue) > 0
		return true
	else
		return false
	endif
endFunction

float function GetResourceRating(ActorValue akValue)
;	;WorkshopParent.wsTrace(self + "GetResourceRating for " + akValue)
	return GetValue(akValue)
endFunction

bool function HasResourceDamage()
	; loop through resource actor value on this object
	int i = 0
	float totalDamage = 0

	; get this once for speed
	WorkshopDataScript:WorkshopActorValue[] WorkshopResourceAVs = WorkshopParent.WorkshopResourceAVs
	int arrayLength = WorkshopResourceAVs.Length
	while i < WorkshopResourceAVs.Length && totalDamage == 0
		ActorValue testValue = WorkshopResourceAVs[i].resourceValue
		float damage = GetBaseValue(testValue) - GetValue(testValue)
		totalDamage = totalDamage + damage
		i += 1
	endWhile
	return (totalDamage > 0)
endFunction

function testGetResourceDamage(ActorValue akAV = None)
	float damage = GetResourceDamage(akAV)
	;debug.trace(self + " GetResourceDamage(" +akAV + ")=" + damage)
endFunction

;--------------------------------------------
;    Added by UFO4P 1.0.5. for Bug #20945:
;--------------------------------------------

;Helper function to delete the passed in damage helper. Unlike the vanilla code, this function makes sure that the helper is unlinked from any crops and that
;its reference is removed from the myDamageHelperRef variable. Otherwise, the helper remains persistent, is never actually deleted and keeps to exist in the
;game as an orphaned marker. Those orphaned markers are responsible for the invisible crop issue.
function UFO4P_DeleteDamageHelper (ObjectReference RefToDelete = none, bool bClearPointer = true)
	If RefToDelete == none
		RefToDelete = myDamageHelperRef
	endIf
	RefToDelete.SetLinkedRef (none)
	;UFO4P 2.0.1 Bug #22272: Disable before deleting. Deletion will not occur before unload, so the enabled reference (despite marked for deletion) may
	;still cause trouble as long as the player is around
	RefToDelete.DisableNoWait()
	RefToDelete.Delete()
	if bClearPointer
		myDamageHelperRef = none
	endIf
EndFunction


;This function is for checking the helper that matches the current crop. Since the reference of that helper should be stored in myDamageHelperRef (unless the pointer
;is broken or the helper is misconfigured or entirely missing), this function checks the validity of that variable in the first place. If the pointer is found to be
;broken, it calls the UFO4P_CheckDamageHelper function to search for a matching helper that is still linked to the current crop. If none is found, or when the helper
;is entirely missing (i.e. when myDamageHelperRef is really 'none'), it will create a new one.
function UFO4P_ValidateDamageHelperRef()
	bool bBrokenPointer = true
	if myDamageHelperRef
		;If pointer is broken, this check fails with an error and papyrus skips the entire 'if' structure
		if myDamageHelperRef.GetBaseObject()
			;If check succeeds, the pointer is not broken 
			bBrokenPointer = false
			;Now check whether myDamageHelperRef points to a valid damage helper object:
			If myDamageHelperRef.IsDeleted()
				WorkshopParent.wsTrace(self + "	UFO4P_ValidateDamageHelperRef - myDamageHelperRef points to a deleted object; creating new one")
			elseIf !myDamageHelperRef.GetParentCell() || !myDamageHelperRef.GetParentCell().IsLoaded()
				WorkshopParent.wsTrace(self + "	UFO4P_ValidateDamageHelperRef - myDamageHelperRef points to an object in an unloaded cell; deleting and creating new one")
				UFO4P_DeleteDamageHelper()				
			elseIf myDamageHelperRef.GetBaseObject() == DamageHelper
				ObjectReference myDamageHelperLinkedRef = myDamageHelperRef.GetLinkedRef()
				if myDamageHelperLinkedRef && myDamageHelperLinkedRef == self
					return
				else
					WorkshopParent.wsTrace(self + "	UFO4P_ValidateDamageHelperRef - myDamageHelperRef not linked to me; relinking")
					myDamageHelperRef.SetLinkedRef(self)
				endIf
			else
				WorkshopParent.wsTrace(self + "	UFO4P_ValidateDamageHelperRef - myDamageHelperRef points to a wrong object; deleting and creating new one")
				UFO4P_DeleteDamageHelper()
			endIf
		endIf
		
		
		if bBrokenPointer
			WorkshopParent.wsTrace(self + "	UFO4P_ValidateDamageHelperRef - Invalid myDamageHelperRef. Creating new helper.")
		endIf
	endIf
	myDamageHelperRef = PlaceAtMe(DamageHelper)
	myDamageHelperRef.SetLinkedRef(self)
endFunction

;--------------------------------------------
;    Added by UFO4P 2.0.for Bug #21894:
;--------------------------------------------

;helper function to return the value stored in myDamageHelperRef to an external script
ObjectReference function UFO4P_GetMyDamageHelperRef()
	return myDamageHelperRef
endFunction

;--------------------------------------------
;    Added by UFO4P 2.0.6 for Bug #25215:
;--------------------------------------------

int function GetResourceID()
	if resourceID == -2
		resourceID = WorkshopParent.InitResourceID (self)
	endif
	return resourceID
endFunction


; WSFW - 2.0.0 - Attempting to reduce traffic to WorkshopParent
WorkshopScript Function GetWorkshop()
	WorkshopScript thisWorkshop = GetLinkedRef(GetWorkshopItemKeyword()) as WorkshopScript
	
	if( ! thisWorkshop)
		return WorkshopParent.GetWorkshop(workshopID)
	endif
	
	return thisWorkshop
EndFunction


; WSFW - 2.0.0
Keyword Function GetWorkshopItemKeyword()
	return Game.GetFormFromFile(0x00054BA6, "Fallout4.esm") as Keyword
EndFunction

; WSFW - 2.0.0
String Function GetVendorID()
	String sVendorID = sCustomVendorID
	if(sVendorID == "")
		sVendorID = VendorType as String
	endif
	
	return sVendorID
EndFunction