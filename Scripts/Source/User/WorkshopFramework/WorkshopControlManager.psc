; ---------------------------------------------
; WorkshopFramework:WorkshopControlManager.psc - by kinggath
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

Scriptname WorkshopFramework:WorkshopControlManager extends WorkshopFramework:Library:SlaveQuest
{ 
This will handle the settlement control system, whereby mods can allow a faction to take control of the settlement. It's primary function is to allow for offering simple hooks into the system for overriding various aspects of a settlement - such as the settler recruitment type - based on the control. It will also provide a relay point for events and information mods can share in this regard. 

It will NOT handle actual actual triggering of the control system, only the system framework itself. 

In the future, this will likely be expanded to offer a framework for attack events based around control.
}

import WorkshopFramework:Library:DataStructures
import WorkshopFramework:Library:UtilityFunctions
import WorkshopFramework:WorkshopFunctions


CustomEvent SettlementControlled

; ---------------------------------------------
; Consts
; ---------------------------------------------


; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------

Group Controllers
	WorkshopFramework:MainThreadManager Property ThreadManager Auto Const Mandatory
	WorkshopParentScript Property WorkshopParent Auto Const Mandatory
	WorkshopFramework:NPCManager Property NPCManager Auto Const Mandatory
	WorkshopFramework:WorkshopResourceManager Property ResourceManager Auto Const Mandatory
EndGroup

Group ActorValues
	ActorValue Property PopulationAV Auto Const Mandatory
	ActorValue Property SafetyAV Auto Const Mandatory
EndGroup

Group Factions
	Faction Property PlayerFaction Auto Const Mandatory
	Faction Property WorkshopNPCFaction Auto Const Mandatory
EndGroup

Group Keywords
	Keyword Property WorkshopItemKeyword Auto Const Mandatory
	Keyword Property WorkshopCaravanKeyword Auto Const Mandatory
EndGroup

; ---------------------------------------------
; Properties
; ---------------------------------------------


; ---------------------------------------------
; Vars
; ---------------------------------------------

Bool bSeverSupplyLineBlock = false
; ---------------------------------------------
; Events 
; ---------------------------------------------

Event WorkshopParentScript.WorkshopObjectBuilt(WorkshopParentScript akSenderRef, Var[] akArgs)
	;/
	kargs[0] = newWorkshopObject
	kargs[1] = workshopRef
	/;
	
	WorkshopScript thisWorkshop = akArgs[1] as WorkshopScript
	WorkshopObjectScript thisObject = akArgs[0] as WorkshopObjectScript
	
	if(thisWorkshop && thisObject && (thisObject as ObjectReference) as WorkshopObjectActorScript)
		; Turret, check if this settlement is under control, in which case we need to setup the turrets allegiance
		int iWorkshopID = thisWorkshop.GetWorkshopID()
		
		; Check for faction
		if(thisWorkshop.ControllingFaction != None)
			CaptureTurret((thisObject as ObjectReference) as Actor, thisWorkshop, thisWorkshop.FactionControlData, abPlayerIsEnemy = false, abForPlayer = thisWorkshop.OwnedByPlayer)
		endif
	endif
EndEvent

; ---------------------------------------------
; Extended Handlers
; ---------------------------------------------

Function HandleQuestInit()
	RegisterForCustomEvent(WorkshopParent, "WorkshopObjectBuilt")
	
	Parent.HandleQuestInit()
EndFunction


Function HandleGameLoaded()
	Parent.HandleGameLoaded()
	
	RegisterForCustomEvent(WorkshopParent, "WorkshopObjectBuilt")
EndFunction

; ---------------------------------------------
; Overrides
; ---------------------------------------------


; ---------------------------------------------
; Functions
; ---------------------------------------------

Function TurnSettlementAgainstPlayer(WorkshopScript akWorkshopRef)
	CaptureSettlement(akWorkshopRef, None, abSeverEnemySupplyLines = false, abRemoveEnemySettlers = false, abKillEnemySettlers = false, abCaptureTurrets = true, abCaptureContainers = false, abSettlersJoinFaction = false, abTogglePlayerOwnership = false, abPlayerIsEnemy = true, iCreateInvadingSettlers = -1)
EndFunction

Function CaptureSettlement(WorkshopScript akWorkshopRef, FactionControl aFactionData = None, Bool abSeverEnemySupplyLines = true, Bool abRemoveEnemySettlers = true, Bool abKillEnemySettlers = false, Bool abCaptureTurrets = true, Bool abCaptureContainers = true, Bool abSettlersJoinFaction = false, Bool abTogglePlayerOwnership = false, Bool abPlayerIsEnemy = false, Int iCreateInvadingSettlers = -1)
	if(akWorkshopRef == None)
		return
	endif
	
	; Setup ControllingFaction and FactionControlData vars on workshop
	Faction PreviousControllingFaction = GetControllingFaction(akWorkshopRef)
	FactionControl PreviousControlData = GetControllingFactionData(akWorkshopRef)
	
	SetControllingFaction(akWorkshopRef, aFactionData)
	
	Faction thisFaction = GetFactionFromFactionData(aFactionData)
	
	if(thisFaction != PreviousControllingFaction)
		if(aFactionData && aFactionData.ControlledSettlementCount)
			aFactionData.ControlledSettlementCount.Mod(1)
		endif
		
		if(PreviousControllingFaction != None && PreviousControlData && PreviousControlData.ControlledSettlementCount)
			PreviousControlData.ControlledSettlementCount.Mod(-1)
		endif
	endif
	
	; Sever provisioners between enemy settlements
	if(abSeverEnemySupplyLines && aFactionData)
		SeverSupplyLines(akWorkshopRef)
	endif
	
	; Boot out enemy factions
	if(abRemoveEnemySettlers || abKillEnemySettlers || abSettlersJoinFaction)
		RemoveEnemyFaction(akWorkshopRef, abRemoveEnemySettlers, abKillEnemySettlers, abSettlersJoinFaction, abPlayerIsEnemy)
	endif
	
	; Capture turrets
	if(abCaptureTurrets)
		CaptureTurrets(akWorkshopRef, PreviousControllingFaction, abPlayerIsEnemy)
	else
		CaptureTurrets(akWorkshopRef, PreviousControllingFaction, abPlayerIsEnemy, ! abPlayerIsEnemy)
	endif
	
	if(abTogglePlayerOwnership)
		if(abPlayerIsEnemy)
			if(akWorkshopRef.OwnedByPlayer)
				ClearPlayerOwnership(akWorkshopRef)
			endif
		elseif( ! akWorkshopRef.OwnedByPlayer)
			RestorePlayerOwnership(akWorkshopRef)
		endif
	endif
	
	if(abCaptureContainers)
		CaptureContainers(akWorkshopRef, abPlayerIsEnemy)
	endif
	
	if(akWorkshopRef.UseOwnershipFaction && akWorkshopRef.SettlementOwnershipFaction)
		if(abPlayerIsEnemy)
			; Turn all settlers and turrets against the player
			akWorkshopRef.SettlementOwnershipFaction.SetPlayerEnemy()
		else
			akWorkshopRef.SettlementOwnershipFaction.SetPlayerEnemy(false)
		endif
	endif
	
	; Create invading settlers
	if(iCreateInvadingSettlers > 0)
		int i = 0
		while(i < iCreateInvadingSettlers)
			NPCManager.CreateSettler(akWorkshopRef)
			
			i += 1
		endWhile
	endif
	
	; Notify other mods that this settlement is now controlled
	Var[] kArgs = new Var[3]
	kArgs[0] = akWorkshopRef
	kArgs[1] = thisFaction
	kArgs[2] = PreviousControllingFaction
	
	SendCustomEvent("SettlementControlled", kArgs)
EndFunction


Function ClearPlayerOwnership(WorkshopScript akWorkshopRef)
	Debug.TraceStack("[WSFW] ClearPlayerOwnership called")
	akWorkshopRef.SetOwnedByPlayer(false)
	if(WorkshopParent.CurrentWorkshop.GetRef() == akWorkshopRef)
		; Player was in the settlement they lost, make sure they aren't in WS mode
		akWorkshopRef.StartWorkshop(false)
	endif
	
	; Prevent player from just retaking it by clicking on it
	akWorkshopRef.EnableAutomaticPlayerOwnership = false 
EndFunction

Function RestorePlayerOwnership(WorkShopScript akWorkshopRef)
	if( ! akWorkshopRef.OwnedByPlayer)
		akWorkshopRef.SetOwnedByPlayer(true)
	endif
EndFunction


Function CaptureContainers(WorkshopScript akWorkshopRef, Bool abForPlayer = false)
	Faction thisFaction = GetControllingFaction(akWorkshopRef)
	
	if(abForPlayer)
		thisFaction = PlayerFaction
	endif
	
	if(thisFaction)
		ObjectReference[] kLinkedRefs = akWorkshopRef.GetLinkedRefChildren(WorkshopItemKeyword)
		
		int i = 0
		while(i < kLinkedRefs.Length)
			if(kLinkedRefs[i].GetBaseObject() as Container)
				kLinkedRefs[i].SetFactionOwner(thisFaction)
			endif
			
			i += 1
		endWhile
	endif
EndFunction


Function RemoveEnemyFaction(WorkshopScript akWorkshopRef, Bool abRemoveEnemySettlers = true, Bool abKillEnemySettlers = false, Bool abSettlersJoinFaction = false, Bool abPlayerIsEnemy = false)
	Faction thisFaction = GetControllingFaction(akWorkshopRef)
	FactionControl FactionControlData = GetControllingFactionData(akWorkshopRef)
	
		; Grab workshop actors
	ObjectReference[] kWorkshopActors = new ObjectReference[0]
	
	if(akWorkshopRef.Is3dLoaded()) 
		kWorkshopActors = akWorkshopRef.GetWorkshopResourceObjects(PopulationAV)
	else
		; Search linked refs
		ObjectReference[] kLinkedRefs = akWorkshopRef.GetLinkedRefChildren(WorkshopItemKeyword)
		
		int i = 0
		while(i < kLinkedRefs.Length)
			if(kLinkedRefs[i] as WorkshopNPCScript)
				kWorkshopActors.Add(kLinkedRefs[i])
			endif
			
			i += 1
		endWhile
	endif
	
	if(kWorkshopActors.Length > 0)
		WorkshopScript kTransferTo = None
		
		if( ! abKillEnemySettlers && abRemoveEnemySettlers)
			; Find another settlement to send them to
			int i = 0
			WorkshopScript[] Workshops = ResourceManager.Workshops
			while(i < Workshops.Length)
				if(Workshops[i] != akWorkshopRef && ! IsAnEnemySettlement(akWorkshopRef, Workshops[i], abPlayerIsEnemy))
					kTransferTo = Workshops[i]
				endif
				
				i += 1
			endWhile
		endif
		
		int i = 0
		
		while(i < kWorkshopActors.Length)
			WorkshopNPCScript asWorkshopNPC = kWorkshopActors[i] as WorkshopNPCScript
			if(asWorkshopNPC)
				if(abRemoveEnemySettlers || abKillEnemySettlers)
					if(IsAnEnemy(FactionControlData, asWorkshopNPC))
						if(abKillEnemySettlers || (abRemoveEnemySettlers && ! kTransferTo))
							if( ! asWorkshopNPC.GetLeveledActorBase().IsUnique())
								asWorkshopNPC.Kill()
							endif
						elseif(abRemoveEnemySettlers)
							WorkshopParent.AddActorToWorkshopPUBLIC(asWorkshopNPC, kTransferTo)
						endif
					endif
				elseif(abSettlersJoinFaction && thisFaction)
					asWorkshopNPC.AddToFaction(thisFaction)
				endif
			endif
			
			i += 1
		endWhile
	endif
EndFunction


Function SeverSupplyLines(WorkshopScript akWorkshopRef)
	Location[] LinkedLocations = akWorkshopRef.myLocation.GetAllLinkedLocations(WorkshopCaravanKeyword)
	
	Faction thisFaction = GetControllingFaction(akWorkshopRef)
	FactionControl FactionControlData = GetControllingFactionData(akWorkshopRef)
	int i = 0
	while(i < LinkedLocations.Length)
		int iLinkedWorkshopID = ResourceManager.WorkshopLocations.Find(LinkedLocations[i])
		
		if(iLinkedWorkshopID >= 0)
			WorkshopScript thisWorkshop = ResourceManager.Workshops[iLinkedWorkshopID]
			
			Faction thisControllingFaction = GetControllingFaction(thisWorkshop)
			
			if(thisControllingFaction != thisFaction)
				Bool bSeverSupplyLine = false
				
				if((thisControllingFaction == PlayerFaction || (thisControllingFaction == None && thisWorkshop.OwnedByPlayer)) && (thisFaction == PlayerFaction || (thisControllingFaction == None && thisWorkshop.OwnedByPlayer)) )
					bSeverSupplyLine = true
				elseif(FactionControlData && FactionControlData.EnemyFactions && FactionControlData.EnemyFactions.Find(thisControllingFaction) > -1)
					bSeverSupplyLine = true
				elseif(FactionControlData && FactionControlData.bTreatAllOtherFactionsAsEnemies)
					bSeverSupplyLine = true
					
					if(FactionControlData.FriendlyFactions && FactionControlData.FriendlyFactions.Find(thisControllingFaction) > -1)
						bSeverSupplyLine = false
					endif
				endif
				
				if(bSeverSupplyLine)
					SeverSupplyLinesBetweenSettlements(akWorkshopRef, thisWorkshop)
				endif
			endif
		endif
		
		i += 1
	endWhile
EndFunction


Function CaptureTurrets(WorkshopScript akWorkshopRef, Faction aRemoveFaction, Bool abPlayerIsEnemy = false, Bool abForPlayer = false)
	ObjectReference[] kDefenseObjects = new ObjectReference[0]
	
	if(akWorkshopRef.Is3dLoaded())
		kDefenseObjects = akWorkshopRef.GetWorkshopResourceObjects(SafetyAV)
	else
		ObjectReference[] LinkedRefs = akWorkshopRef.GetLinkedRefChildren(WorkshopItemKeyword)
		
		int j = 0
		while(j < LinkedRefs.Length)
			if(LinkedRefs[j] as WorkshopObjectActorScript)
				kDefenseObjects.Add(LinkedRefs[j])
			endif
			
			j += 1
		endWhile
	endif
	
	FactionControl FactionControlData = GetControllingFactionData(akWorkshopRef)
		
	int i = 0
	while(i < kDefenseObjects.Length)
		if(kDefenseObjects[i] as WorkshopObjectActorScript)
			if(aRemoveFaction)
				(kDefenseObjects[i] as Actor).RemoveFromFaction(aRemoveFaction)
			endif
			
			CaptureTurret(kDefenseObjects[i] as Actor, akWorkshopRef, FactionControlData, abPlayerIsEnemy, abForPlayer)				
		endif
		
		i += 1
	endWhile
EndFunction


Function CaptureTurret(Actor akTurretRef, WorkshopScript akWorkshopRef = None, FactionControl aFactionData = None, Bool abPlayerIsEnemy = false, Bool abForPlayer = false)
	if( ! akWorkshopRef)
		akWorkshopRef = ResourceManager.Workshops[((akTurretRef as ObjectReference) as WorkshopObjectScript).workshopID]
	endif
	
	Faction thisFaction = GetFactionFromFactionData(aFactionData)
	if( ! thisFaction && akWorkshopRef)
		thisFaction = GetControllingFaction(akWorkshopRef)
	endif
	
	if(abForPlayer)
		akTurretRef.AddToFaction(PlayerFaction)
	endif
	
	if(thisFaction)
		if(thisFaction != WorkshopNPCFaction && thisFaction != PlayerFaction)
			akTurretRef.RemoveFromFaction(WorkshopNPCFaction)
			akTurretRef.RemoveFromFaction(PlayerFaction)
		endif
		
		akTurretRef.AddToFaction(thisFaction)
		akTurretRef.SetCrimeFaction(thisFaction)
		
		; Remove from enemy factions
		if(aFactionData && aFactionData.EnemyFactions)
			int i = 0
			while(i < aFactionData.EnemyFactions.GetSize())
				akTurretRef.RemoveFromFaction(aFactionData.EnemyFactions.GetAt(i) as Faction)
				
				i += 1
			endWhile
		endif		
	else
		akTurretRef.AddToFaction(WorkshopNPCFaction)
		akTurretRef.AddToFaction(PlayerFaction)
		
		if(akWorkshopRef.UseOwnershipFaction)
			akTurretRef.AddToFaction(akWorkshopRef.SettlementOwnershipFaction)
			akTurretRef.SetCrimeFaction(akWorkshopRef.SettlementOwnershipFaction)
		else
			akTurretRef.SetCrimeFaction(None)
		endif
	endif
	
	if(abPlayerIsEnemy)
		akTurretRef.RemoveFromFaction(PlayerFaction)
	endif
EndFunction


Bool Function IsAnEnemy(FactionControl aFactionData, Actor akActorRef, Bool abPlayerIsEnemy = false)
	Faction thisFaction = GetFactionFromFactionData(aFactionData)
	
	if( ! thisFaction || akActorRef.IsInFaction(thisFaction))
		return false
	endif
	
	if(abPlayerIsEnemy && akActorRef.IsInFaction(PlayerFaction))
		return true
	endif
	
	if(aFactionData.EnemyFactions)
		int i = 0
		while(i < aFactionData.EnemyFactions.GetSize())
			if(akActorRef.IsInFaction(aFactionData.EnemyFactions.GetAt(i) as Faction))
				return true
			endif
			
			i += 1
		endWhile
	elseif(aFactionData.bTreatAllOtherFactionsAsEnemies)
		int i = 0
		while(i < aFactionData.FriendlyFactions.GetSize())
			if(akActorRef.IsInFaction(aFactionData.FriendlyFactions.GetAt(i) as Faction))
				return false
			endif
			
			i += 1
		endWhile
	endif
	
	return false
EndFunction


Bool Function IsAnEnemySettlement(WorkshopScript akWorkshopRef, WorkshopScript akCheckWorkshopRef, Bool abPlayerIsEnemy = false)
	Faction ControllingFaction = GetControllingFaction(akCheckWorkshopRef)
	FactionControl FactionControlData = akWorkshopRef.FactionControlData
	Faction thisFaction = GetFactionFromFactionData(FactionControlData)
	
	if( ! thisFaction || thisFaction == ControllingFaction)
		return false
	endif
	
	if(ControllingFaction == PlayerFaction || (ControllingFaction == None && akCheckWorkshopRef.OwnedByPlayer))
		if(abPlayerIsEnemy)
			return true
		endif
	elseif(FactionControlData.EnemyFactions && FactionControlData.EnemyFactions.Find(ControllingFaction) > -1)
		return true
	elseif(FactionControlData.bTreatAllOtherFactionsAsEnemies)
		if(FactionControlData.FriendlyFactions && FactionControlData.FriendlyFactions.Find(ControllingFaction) > -1)
			return false
		else
			return true
		endif
	endif
	
	return false
EndFunction


Function SeverSupplyLinesBetweenSettlements(WorkshopScript akWorkshopRef, WorkshopScript akDestinationRef)
	if(bSeverSupplyLineBlock)
		return
	endif
	
	bSeverSupplyLineBlock = true
	; check all caravan actors for either belonging to this workshop, or targeting it - unassign them
	
	int i = WorkshopParent.CaravanActorAliases.GetCount() - 1 ; start at top of list since we may be removing things from it

	while(i	> -1)
		WorkshopNPCScript theActor = WorkshopParent.CaravanActorAliases.GetAt(i) as WorkShopNPCScript
		
		if(theActor)
			; check start and end locations
			int destinationWorkshopID = theActor.GetCaravanDestinationID()
			WorkshopScript endWorkshop = ResourceManager.Workshops[destinationWorkshopID]
			
			WorkshopScript startWorkshop = ResourceManager.Workshops[theActor.GetWorkshopID()]
			
			if((endWorkshop == akWorkshopRef || startWorkshop == akWorkshopRef) && (endWorkshop == akDestinationRef || startWorkshop == akDestinationRef))
				WorkshopParent.UnassignActorFromCaravan(theActor, akWorkshopRef, false)
			endif
		endif
		
		i -= 1
	endWhile
	
	bSeverSupplyLineBlock = false
EndFunction


Faction Function GetFactionFromFactionData(FactionControl aFactionData)
	if(aFactionData != None)
		if(aFactionData.FactionForm != None)
			return aFactionData.FactionForm
		else
			Faction thisFaction = Game.GetFormFromFile(aFactionData.iFormID, aFactionData.sPluginName) as Faction
			
			return thisFaction
		endif
	endif
	
	return None
EndFunction


FactionControl Function GetControllingFactionData(WorkshopScript akWorkshopRef)
	return akWorkshopRef.FactionControlData
EndFunction

Faction Function GetControllingFaction(WorkshopScript akWorkshopRef)
	return akWorkshopRef.ControllingFaction
EndFunction

Function SetControllingFaction(WorkshopScript akWorkshopRef, FactionControl aFactionData)
	Faction thisFaction = GetFactionFromFactionData(aFactionData)
	akWorkshopRef.ControllingFaction = thisFaction
	akWorkshopRef.FactionControlData = aFactionData
EndFunction