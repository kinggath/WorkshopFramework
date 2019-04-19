Scriptname WorkshopNPCScript extends Actor Conditional
{script for all NPCs that can be assigned to a workshop}

WorkshopParentScript Property WorkshopParent Auto Const

Group WorkerData

	bool Property bCommandable = false auto Conditional
	{ TRUE = commandable by player - can be ordered to different work objects (default)
	  FALSE = player can't command although will still count as worker if given default work
	}

	bool Property bAllowCaravan = false auto Conditional
	{ TRUE = can be assigned to caravan duty
	}

	bool Property bAllowMove = false auto Conditional
	{ TRUE = can be moved to different settlements
	}

	; worker flag - used by package conditions etc.
	bool Property bIsWorker = false auto Conditional
	{ worker flag - used by package conditions
		set to TRUE if this NPC is a worker of any kind
	}

	bool Property bWork24Hours = false auto Conditional
	{ set to TRUE to have someone work 24 hours }

	; guard flag - used by package conditions
	bool Property bIsGuard = false auto Conditional Hidden
	{ set to TRUE if this NPC is a "guard" - assigned to Safety work objects like guard posts etc. }

	; scavenger flag - used by package conditions
	bool Property bIsScavenger = false auto Conditional Hidden
	{ set to TRUE if this NPC is a scavenger - assigned to Scavenge work objects }

	ActorValue Property assignedMultiResource auto
	{ if NONE this worker is assigned a single object to work on
	  otherwise, this is the rating keyword (food, safety, etc.) of the type of resource
	  this NPC can work on }

	float Property multiResourceProduction = 0.0 auto Hidden Conditional
	{ if assignedMultiResource is set, this tracks how much production this NPC is assigned to }

	bool Property bIsSynth = false auto conditional hidden
	{ set to TRUE if this NPC has been tagged as a synth - gives appropriate death item }
endGroup

bool Property bWorkshopStatusOn = true auto conditional hidden
{ set to false when temporarily turning off - but saving - workshop NPC status, e.g. for companions }
; if workshop status turned off, save these flags here so they can be restored later
bool bSavedAllowMove
bool bSavedAllowCaravan
bool bSavedCommandable

; used by ResetWorkshop to indicate which objects it has finished with
bool Property bResetDone = false auto hidden

; the brahmin assigned to me if I'm a caravan actor
Actor Property myBrahmin auto

bool Property bNewSettler = false auto Conditional
{ set to true when new settlers are created - set back to false after player "meets" them }

bool Property bCountsForPopulation = true auto Conditional
{ set to false for things like brahmin which don't count for total population }

bool Property bApplyWorkshopOwnerFaction = true auto conditional
{ set to false for NPCs that should not pick up the owner faction of their assigned workshop - e.g. companions }

LocationRefType Property CustomBossLocRefType Auto Const
{ Patch 1.4: custom loc ref type to use for this actor when assigning to workshop }

group VendorData
	int Property specialVendorType = -1 auto const
	{ based on index from WorkshopParent VendorTypes - set for NPCs who have special vendor abilities }

	int Property specialVendorMinLevel = 2 auto const
	{ if a special vendor, what level does the vendor object have to be to allow special ability? }

	Container Property specialVendorContainerBase auto const
	{ base object of special vendor container to link to when special ability is allowed }

	ObjectReference Property specialVendorContainerRef auto hidden
	{ reference (created by script) to link to when special ability is allowed }

	ObjectReference Property specialVendorContainerRefUnique auto
	{ reference to link to when special ability is allowed }
endGroup

; workshop that this NPC is assigned to (also mirrored by the actor value - but need a way to say "no workshop" since the default actor value is 0)
int workshopID = -1 conditional

; for dropping out of command state
int iSelfActivationCount = 0

;---------------------------------------------
;	Added by UFO4P 2.0 for Bug #21578
;---------------------------------------------

bool UFO4P_WaitingForNPCRecovering = false

;---------------------------------------------

; return the workshopID of this actor
int function GetWorkshopID()
	return workshopID
endFunction

function SetWorkshopID(int newWorkshopID)
	workshopID = newWorkshopID
	SetValue(WorkshopParent.workshopIDActorValue, newWorkshopID)
	; put script in correct state (we only care about events if assigned to a workshop)
	if newWorkshopID > -1
		gotoState("assigned")
	else
		gotoState("unassigned")
	endif
endFunction

function UpdatePlayerOwnership(WorkshopScript workshopRef = NONE)
	; get workshop if not passed in
	if workshopRef == NONE
		workshopRef = WorkshopParent.GetWorkshop(workshopID)
	endif
	;WorkshopParent.wsTrace(self + " UpdatePlayerOwnership for workshop " + workshopRef + ": OwnedByPlayer=" + workshopRef.OwnedByPlayer)
	if workshopRef
		; set player ownership actor value
		SetValue(WorkshopParent.WorkshopPlayerOwnership, workshopRef.OwnedByPlayer as int)
	endif
endFunction

; return workshopID of caravan destination (if any)
int function GetCaravanDestinationID()
	return GetValue(WorkshopParent.WorkshopCaravanDestination) as int   
endFunction

bool function IsWounded()
;	;;debug.trace(GetValue(WorkshopParent.WorkshopActorWounded) as bool)
	return GetValue(WorkshopParent.WorkshopActorWounded) as bool
endFunction

function SetWounded(bool bIsWounded)
	SetValue(WorkshopParent.WorkshopActorWounded, bIsWounded as int)
	; am I a caravan actor?
	int foundIndex = WorkshopParent.CaravanActorAliases.Find(self)
	if foundIndex > -1
		WorkshopParent.TurnOnCaravanActor(self, bIsWounded == false)
	endif
endFunction

function SetWorker(bool isWorker)
	bIsWorker = isWorker
	if !isWorker
		bIsGuard = false
		bIsScavenger = false
	endif
endFunction

function SetScavenger(bool isScavenger)
	bIsScavenger = isScavenger
endFunction

function SetSynth(bool isSynth)
	;WorkshopParent.wsTrace(self + " SetSynth " + isSynth)
	bIsSynth = isSynth
	SetValue(WorkshopParent.WorkshopRatings[WorkshopParent.WorkshopRatingPopulationSynths].resourceValue, (isSynth == true) as float)
	; if created and assigned to a workshop, set ref type
	if IsCreated() && workshopID > -1
		WorkshopScript workshopRef = WorkshopParent.GetWorkshop(GetWorkshopID())
		if workshopRef.myLocation
			if isSynth
				SetLocRefType(workshopRef.myLocation, WorkshopParent.WorkshopSynthRefType)
			else
				; change back to Boss
				SetLocRefType(workshopRef.myLocation, WorkshopParent.Boss)
			endif
			ClearFromOldLocations() ; 101931: make sure location data is correct
		endif
	endif
endFunction

function SetMultiResource(ActorValue resourceValue)
	;WorkshopParent.wstrace(self + " SetMultiResource: resourceValue=" + resourceValue)

	assignedMultiResource = resourceValue
	if assignedMultiResource == WorkshopParent.WorkshopRatings[WorkshopParent.WorkshopRatingSafety].resourceValue
		bIsGuard = true
	else
		bIsGuard = false
	endif

	if !assignedMultiResource
		; clear production if no longer assigned to a multiresource
		multiResourceProduction = 0.0
	endif
endFunction

function AddMultiResourceProduction(float newProduction)
	multiResourceProduction += newProduction
endFunction

; Patch 1.4 - custom boss loc ref type
function SetAsBoss(Location newLocation)
	if CustomBossLocRefType
		SetLocRefType(newLocation, CustomBossLocRefType)
	else
		SetLocRefType(newLocation, WorkshopParent.Boss)
	endif
	ClearFromOldLocations() ; 101931: make sure location data is correct
endFunction

auto state unassigned
; default state

	Event OnInit()
	
		;UFO4P 2.0.4 Bug #24437: added this check:
		if IsBoundGameObjectAvailable() == false
			return
		endif

		; if I'm a follower, register for companion change events
		;UFO4P 1.0.3 Bug #20575: 'is' replaced with 'as'
		if (self as Actor) as CompanionActorScript
			;;debug.trace(self + " OnInit - Companion - registering for CompanionChange events")
			RegisterForCustomEvent(FollowersScript.GetScript(), "CompanionChange")		
		endif
		SetCommandable(bCommandable)
		SetAllowCaravan(bAllowCaravan)
		SetAllowMove(bAllowMove)

		; if I have a linked work object, set my ownership to it
		if GetLinkedRef(WorkshopParent.WorkshopLinkWork)
			WorkshopObjectScript workobject = (GetLinkedRef(WorkshopParent.WorkshopLinkWork) as WorkshopObjectScript)
			;WorkshopParent.wstrace(self + " assigning to " + workobject)
			workobject.AssignActor(self)
		endif
	EndEvent

endState

; when assigned to a workshop, script is put into this state
state assigned

	Event OnActivate(ObjectReference akActionRef)
		;;debug.trace(self + "OnActivate " + akActionRef)
		if WorkshopParent.GetWorkshop(GetWorkshopID()).OwnedByPlayer
			;;debug.trace(self + " Owned by player")
			if IsDoingFavor() && akActionRef == self && bCommandable ; must be commandable so this doesn't trigger for companions
				;debug.trace(self + " OnActivate - workshop commandable")
				iSelfActivationCount += 1
				if iSelfActivationCount > 1
					; toggle favor state
					setDoingFavor(false, true)
				endif
			endif
		endif
	EndEvent

	Event OnCommandModeGiveCommand(int aeCommandType, ObjectReference akTarget)
		;debug.trace(self + " OnCommandModeGiveCommand aeCommandType=" + aeCommandType + " akTarget=" + akTarget)
		WorkshopObjectScript workObject = akTarget as WorkshopObjectScript
		if workObject && aeCommandType == 10 ; workshop assign command
			workObject.ActivatedByWorkshopActor(self)
		endif
	endEvent

	;---------------------------------------------------------------------------------------------------------------------------------------------------------------
	;	UFO4P 2.0 Bug #21578: Notes on modifications to OnEnterBleedout() and OnCombatStateChanged():
	;---------------------------------------------------------------------------------------------------------------------------------------------------------------
	;
	;If an actor was wounded, the vanilla OnEnterBleedout() event always called the WoundActor function on WorkshopParentScript to unassign him from all of his
	;work objects and to update the workshop resource data values accordingly. However, in most cases of an actor getting wounded, an OnCombatStateChanged event
	;will fire immediately after OnEnterBleedout. In the vanilla script, that event did reset the actor to not wounded and called the WoundActor function again,
	;this time to reassign the actor to any available work objects and to update the workshop resource data values again.
	;
	;Thus, there were alweys two calls of WoundActor() every time an actor got wounded. The second call did occur a short time after the first call and did effec-
	;tively cancel everything the first call did. This is a complete waste of performance. To make things even worse, this could happen half a dozen of times for
	;every workshop actor while an attack was running (this was found out by evaluating the workshop logs recorded during workshop attacks). Simply speaking, the
	;scripts wasted a significant bit of performance at times when the workload on the engine is particularly high anyway.
	;
	;To stop this from happening, the OnEnterBleedout() event will now wait for 10 seconds for the OnCombatStateChanged event to fire, and then checks again whether
	;the actor is still wounded before it calls the WoundActor function. If the latter event fired within that period of time, he will not be wounded anymore, and
	;the competing calls are cancelled.
	;
	;---------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	Event OnEnterBleedout()
		; set this guy as "wounded"
		;WorkshopParent.wstrace(self + " OnEnterBleedout")
		if IsWounded()
			;WorkshopParent.wstrace(self + " already wounded - do nothing")
		else
			
			;WorkshopParent.WoundActor(self)

			;UFO4P 2.0 Bug #21578: Replaced the previous line with the following code:
			SetValue(WorkshopParent.WorkshopActorWounded, 1)
			UFO4P_WaitingForNPCRecovering = true
			WorkshopParent.wstrace(self + " OnEnterBleedout: IsWounded = true")
			int counter = 0
			while IsWounded() && !IsDead() && (counter < 20)
				Utility.Wait(1.0)
				counter += 1
			endWhile
			UFO4P_WaitingForNPCRecovering = false
			if IsWounded() && !IsDead()
				WorkshopParent.wstrace(self + " OnEnterBleedout: IsWounded = true. Calling WoundActor.")
				WorkshopParent.WoundActor(self)
			else
				WorkshopParent.wstrace(self + " OnEnterBleedout: IsWounded = false. Skipping WoundActor.")
			endIf
	
		endIf
	EndEvent

	; WOUNDED STATE: removing visible wounded state for now
	Event OnCombatStateChanged(Actor akTarget, int aeCombatState)
	    if aeCombatState == 0 && IsWounded()

			;WorkshopParent.WoundActor(self, false)

			;UFO4P 2.0 Bug #21578: Replaced the previous line with the following code:
			WorkshopParent.wstrace(self + " OnCombatStateChanged: IsWounded = false")
			if UFO4P_WaitingForNPCRecovering
				SetValue(WorkshopParent.WorkshopActorWounded, 0)
			else
				WorkshopParent.wstrace(self + " OnCombatStateChanged: Calling WoundActor.")
				WorkshopParent.WoundActor(self, false)
			endif

	    endif
	EndEvent

	Event OnDeath(Actor akKiller)
		WorkshopParent.wstrace(self + " OnDeath")
		; death item if synth
		if bIsSynth
			AddItem(WorkshopParent.SynthDeathItem)
		endif
		; remove me from the workshop
		WorkshopParent.HandleActorDeath(self, akKiller)
	EndEvent

	Event OnLoad()
	
		;UFO4P 2.0.1 Bug #22246:
		;Added these lines to let dead actors kick themselves out. This is to handle rare cases where dead actors have been added to a workshop.
		if (self as Actor).IsDead()
			WorkshopParent.wstrace(self + " OnLoad: " + self + " is dead. Removing from workshop ...")
			WorkshopParent.UnassignActor(self, bRemoveFromWorkshop = true, bSendUnassignEvent = false)
			return
		endif

		; do this on load to make sure reset doesn't clear it
		if bWorkshopStatusOn
			SetCommandable(bCommandable)
			SetAllowCaravan(bAllowCaravan)
			SetAllowMove(bAllowMove)
		endif

		; WOUNDED STATE: removing visible wounded state for now
		if IsDead() == false && IsWounded()
	    	WorkshopParent.WoundActor(self, false)
		endif			

		; check if I should create caravan brahmin
		WorkshopParent.CaravanActorBrahminCheck(self)
	EndEvent


endState

Event FollowersScript.CompanionChange(FollowersScript akSender, Var[] akArgs)
	Actor EventActor = akArgs[0] as Actor
	Bool IsNowCompanion = akArgs[1] as bool
	;;debug.trace(self + " CompanionChange event received for " + EventActor + " IsNowCompanion=" + IsNowCompanion)
	if EventActor == self
		if IsNowCompanion
			; turn off workshop status when I become a companion
			SetWorkshopStatus(false)
		else
			; turn on workshop status when I stop being a companion
			SetWorkshopStatus(true)
		endif
	endif
EndEvent

Event OnWorkshopNPCTransfer(Location akNewWorkshopLocation, Keyword akActionKW)
	;debug.trace(self + " OnWorkshopNPCTransfer " + akNewWorkshopLocation + " keyword=" + akActionKW)
	;WorkshopParent.wsTrace(self + " has been directed to transfer to the workshop at " + akNewWorkshopLocation + " with the " + akActionKW + " action")
	; what kind of transfer?
	if akActionKW == WorkshopParent.WorkshopAssignCaravan
		WorkshopParent.AssignCaravanActorPUBLIC(self, akNewWorkshopLocation)
	else
		WorkshopScript newWorkshop = WorkshopParent.GetWorkshopFromLocation(akNewWorkshopLocation)
		if newWorkshop
			if akActionKW == WorkshopParent.WorkshopAssignHome
				WorkshopParent.AddActorToWorkshopPUBLIC(self, newWorkshop)
			elseif akActionKW == WorkshopParent.WorkshopAssignHomePermanentActor
				WorkshopParent.AddPermanentActorToWorkshopPUBLIC(self, newWorkshop.GetWorkshopID())
			endif
		
			; WSFW 1.1.4 - Send event that an NPC transfer occurred
			WorkshopParent.SendWorkshopNPCTransferEvent(Self, newWorkshop, akActionKW)
		else
			; WSFW 1.1.4 - New functionality to allow for workshops that exist outside of the vanilla Workshops array
			WorkshopParent.WSFW_AddActorToLocationPUBLIC(self as Actor, akNewWorkshopLocation, akActionKW)
		endif
	endif
EndEvent

int timerIDCommandState = 1
float timerCommandStateSeconds = 5.0

int timerIDAssigned = 2 			; run a timer when assigned to a new work object
float timerAssignedSeconds = 120.0 ; how long to stay in the "just assigned" package

function StartAssignmentTimer(bool bStart = true)
	if bStart
		; set assigned actor value
		SetValue(WorkshopParent.WorkshopActorAssigned, 1)
		StartTimer(timerAssignedSeconds, timerIDAssigned)
		EvaluatePackage()
	else
		; clear assigned actor value
		SetValue(WorkshopParent.WorkshopActorAssigned, 0)
		CancelTimer(timerIDAssigned)
	endif
endFunction

function StartCommandState()
	;debug.trace(self + "StartCommandState")
	; clear "activate count"
	iSelfActivationCount = 0
	; set up distance check from workshop
	WorkshopScript myWorkshop = WorkshopParent.GetWorkshop(GetWorkshopID())
	if myWorkshop
		StartTimer(timerCommandStateSeconds, timerIDCommandState)
		setDoingFavor(abDoingFavor = true, abWorkShopMode = true)
	endif
endFunction

Event OnTimer(int aiTimerID)
    if aiTimerID == timerIDCommandState
		WorkshopScript myWorkshop = WorkshopParent.GetWorkshop(GetWorkshopID())
    	if myWorkshop && IsWithinBuildableArea(myWorkshop)
    		; if still within build area, keep waiting
			StartTimer(timerCommandStateSeconds, timerIDCommandState)
		else
			; kill command mode
			setDoingFavor(false, false)
		endif
	elseif aiTimerID == timerIDAssigned
		StartAssignmentTimer(false)
    endif
EndEvent

function SetCommandable(bool bFlag)
	;debug.trace(self + "SetCommandable: " + bFlag)
	; always save new state in "saved" variable
	bSavedCommandable = bFlag
	; if workshop status on, change commandable state
	if bWorkshopStatusOn
		bCommandable = bFlag
		if bCommandable
			;;debug.trace(self + " adding keyword " + WorkshopParent.WorkshopAllowCommand)
			AddKeyword(WorkshopParent.WorkshopAllowCommand)
		else
			RemoveKeyword(WorkshopParent.WorkshopAllowCommand)
		endif
		;;debug.trace(self + " HasKeyword " + WorkshopParent.WorkshopAllowCommand + "=" + HasKeyword(WorkshopParent.WorkshopAllowCommand))
	else
		;;debug.trace(self + " 	workshop status temporarily turned off - saving new state for when turned back on")
	endif
endFunction

function SetAllowCaravan(bool bFlag)
	; always save new state in "saved" variable
	bSavedAllowCaravan = bFlag
	; if workshop status on, change commandable state
	if bWorkshopStatusOn
		bAllowCaravan = bFlag
		if bAllowCaravan
			AddKeyword(WorkshopParent.WorkshopAllowCaravan)
		else
			RemoveKeyword(WorkshopParent.WorkshopAllowCaravan)
		endif

	else
		;;debug.trace(self + " 	workshop status temporarily turned off - saving new state for when turned back on")
	endif
endFunction

function SetAllowMove(bool bFlag)
	; always save new state in "saved" variable
	bSavedAllowMove = bFlag
	; if workshop status on, change commandable state
	if bWorkshopStatusOn
		bAllowMove = bFlag
		if bAllowMove
			AddKeyword(WorkshopParent.WorkshopAllowMove)
		else
			RemoveKeyword(WorkshopParent.WorkshopAllowMove)
		endif
	else
		;;debug.trace(self + " 	workshop status temporarily turned off - saving new state for when turned back on")
	endif
endFunction

function SetWorkshopStatus(bool setWorkshopStatusOn)
	;;debug.trace(self + " SetWorkshopStatus " + setWorkshopStatusOn)
	bWorkshopStatusOn = setWorkshopStatusOn
	if bWorkshopStatusOn
		; restore saved state
		SetCommandable(bSavedCommandable)
		SetAllowMove(bSavedAllowMove)
		SetAllowCaravan(bSavedAllowCaravan)
	else
		; save out current state (failsafe)
		bSavedAllowMove = bAllowMove
		bSavedAllowCaravan = bAllowCaravan
		bSavedCommandable = bCommandable
		; now turn it all off
		RemoveKeyword(WorkshopParent.WorkshopAllowCommand)
		RemoveKeyword(WorkshopParent.WorkshopAllowMove)
		RemoveKeyword(WorkshopParent.WorkshopAllowCaravan)
		bAllowMove = false
		bAllowCaravan = false
		bCommandable = false
		; unassign from any current work
		;UFO4P 1.0.5 Bug #20870: Added a check for workshopID: only unassign the actor when he's assigned to a workshop:
		if (workshopID >= 0)
			WorkshopParent.UnassignActor(self)
		endif
	endif
endFunction

function TestKill()
	KillEssential()
endFunction
