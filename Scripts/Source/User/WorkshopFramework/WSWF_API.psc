; ---------------------------------------------
; WorkshopFramework:WSWF_API.psc - by kinggath
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

Scriptname WorkshopFramework:WSWF_API Hidden Const

import WorkshopFramework:Library:DataStructures
import WorkshopFramework:Library:UtilityFunctions

; ------------------------------
; GetAPI
;
; Description: Used internally by these functions to get simple access to properties
; ------------------------------

WorkshopFramework:WSWF_APIQuest Function GetAPI() global
	WorkshopFramework:WSWF_APIQuest API = Game.GetFormFromFile(0x00004CA3, "WorkshopFramework.esm") as WorkshopFramework:WSWF_APIQuest
	
	if( ! (API.MasterQuest as WorkshopFramework:MainQuest).bFrameworkReady)
		if(API.MasterQuest.SafeToStartFrameworkQuests()) 
			Utility.WaitMenuMode(0.1)
		else
			; Player still hasn't reached a point where the quests are ready to start - let's not queue these up
			return None
		endif
	endif
	
	return API
EndFunction


; ------------------------------
; CreateSettlementObject
;
; Description: Creates a settlement object as if the player built it in workshop mode, and returns the CallbackID integer you should watch for if you included akRegisterMeForEvent and need to know about the reference
;
; Prepare to receive CustomEvent WorkshopFramework:Library:ThreadRunner.OnThreadCompleted (which your akRegisterMeForEvent will be automatically registered for if you sent it). 
; 
; When receiving the event you should confirm that kArgs[0] == the CallbackID you received from this call and kArgs[1] will equal the ObjectReference to your created item.
; 
;
; Parameters:
; PlaceMe - Your objects should be in an array of structs per the WorldObject definition found in Library:DataStructures.
;
; akWorkshopRef [Optional] - The objectreference of the settlement workbench cast as WorkshopScript. If this is not sent, the object will not be linked to the workshop. The Link is what allows several gameplay elements: Player Scrapping, Crafting Stations to share resources, Assignable objects to be assignable, and more.
; 
; akPositionRelativeTo [Optional] - It the positions in your PlaceMe data are offsets from a specific reference, send that reference (note that this increases the processing time by about 40%, so sending world coordinates is definitely preferred)
;
; abStartEnabled [Optional] - If you would like to handle enabling the objects yourself, set this to false
; 
; akRegisterMeForEvent [Optional] - The object or quest you would like to receive the WorkshopFramework:PlaceObjectManager.ObjectBatchCreated events. If you don't need to track the items, leave this field as None.
; ------------------------------

Int Function CreateSettlementObject(WorldObject PlaceMe, WorkshopScript akWorkshopRef = None, ObjectReference akPositionRelativeTo = None, Bool abStartEnabled = true, Form akRegisterMeForEvent = None) global
	WorkshopFramework:WSWF_APIQuest API = GetAPI()
	
	if( ! API)
		Debug.Trace("[WorkshopFramework] Failed to get API.")
		return -1
	endif
	
	Bool bRequestEvents = false
	if(akRegisterMeForEvent)
		akRegisterMeForEvent.RegisterForCustomEvent(API.PlaceObjectManager, "ObjectBatchCreated")
		bRequestEvents = true
	endif
	
	int iBatchID = API.PlaceObjectManager.CreateObject(PlaceMe, akWorkshopRef, None, -1, akPositionRelativeTo, abStartEnabled, bRequestEvents)
	
	return iBatchID
EndFunction



; ------------------------------
; CreateBatchSettlementObjects
;
; Description: Creates a batch of settlement objects through the thread manager and returns the batch ID to expect via custom event. This will be much faster than creating indivdual objects, but requires planning for batch-based event handling.
;
; Prepare to receive CustomEvent WorkshopFramework:PlaceObjectManager.ObjectBatchCreated (which your akRegisterMeForEvent will be automatically registered for if you sent it). Object refs will be sent via that event in batches. The Var contents will be as follows:
;    kArgs[0] = ActorValue items are tagged with, kArgs[1] = Value of tagged ActorValue, kArgs[2] = Whether or not to expect additional items in this batch, kArgs[3 through 127] = ObjectReferences of your created objects.
; 
; When receiving the event you should confirm that kArgs[0] == GetDefaultPlaceObjectsBatchAV() (from this API) and kArgs[1] == the batch Id return value you received from this function.
; 
;
; Parameters:
; PlaceMe - Your objects should be in an array of structs per the WorldObject definition found in Library:DataStructures.
;
; akPositionRelativeTo [Optional] - It the positions in your PlaceMe data are offsets from a specific reference
;
; abStartEnabled [Optional] - If you would like to handle enabling the objects yourself, set this to false
; 
; akRegisterMeForEvent [Optional] - The object or quest you would like to receive the WorkshopFramework:PlaceObjectManager.ObjectBatchCreated events. If you don't need to track the items, leave this field as None.
; ------------------------------

Int Function CreateBatchSettlementObjects(WorldObject[] PlaceMe, WorkshopScript akWorkshopRef = None, ObjectReference akPositionRelativeTo = None, Bool abStartEnabled = true, Form akRegisterMeForEvent = None) global
	WorkshopFramework:WSWF_APIQuest API = GetAPI()
	
	if( ! API)
		Debug.Trace("[WorkshopFramework] Failed to get API.")
		return -1
	endif
	
	Bool bRequestEvents = false
	if(akRegisterMeForEvent)
		akRegisterMeForEvent.RegisterForCustomEvent(API.PlaceObjectManager, "ObjectBatchCreated")
		bRequestEvents = true
	endif
	
	int iBatchID = API.PlaceObjectManager.CreateBatchObjects(PlaceMe, akWorkshopRef, None, akPositionRelativeTo, abStartEnabled, bRequestEvents)
	
	return iBatchID
EndFunction


; ------------------------------
; GetDefaultPlaceObjectsBatchAV
;
; Description: Grabs the default AV to expect from the WorkshopFramework:PlaceObjectManager.ObjectBatchCreated event so you can check that the event data matches what your object is expecting
; ------------------------------
ActorValue Function GetDefaultPlaceObjectsBatchAV() global
	return Game.GetFormFromFile(0x00004CA2, "WorkshopFramework.esm") as ActorValue
EndFunction




; ------------------------------ 
; GetWorkshopValue
;
; Description: Get an actorvalue from a workshop - this handles things like negative values in a clean way so that they don't display the 999 UI bug.
; ------------------------------

Float Function GetWorkshopValue(ObjectReference akWorkshopRef, ActorValue aValueToCheck) global
	WorkshopFramework:WSWF_APIQuest API = GetAPI()
	
	if( ! API)
		Debug.Trace("[WorkshopFramework] Failed to get API.")
		return 0.0
	endif
	
	return API.WorkshopResourceManager.GetWorkshopValue(akWorkshopRef, aValueToCheck)
EndFunction



; -----------------------------------
; GetNearestWorkshop
;
; Description: Grabs closest WorkshopScript reference - with some exceptions. If the object is linked to a settlement, it will grab that workshop. If an object is in a workshop's location, it will grab that. Lastly, it will search in a radius to find the closest.
; -----------------------------------

WorkshopScript Function GetNearestWorkshop(ObjectReference akToRef) global
	WorkshopFramework:WSWF_APIQuest API = GetAPI()
	
	if( ! API)
		Debug.Trace("[WorkshopFramework] Failed to get API.")
		return None
	endif
	
	WorkshopScript nearestWorkshop = akToRef.GetLinkedRef(API.WorkshopItemKeyword) as WorkshopScript
	if( ! nearestWorkshop)	
		WorkshopParentScript WorkshopParent = API.WorkshopParent
		Location thisLocation = akToRef.GetCurrentLocation()
		nearestWorkshop = WorkshopParent.GetWorkshopFromLocation(thisLocation)
		
		if( ! nearestWorkshop)
			ObjectReference[] WorkshopsNearby = akToRef.FindAllReferencesWithKeyword(API.WorkshopKeyword, 20000.0)
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
; SpawnWorkshopNPC
;
; Description: Spawns an NPC at the targeted settlement.
;
; Parameters:
; WorkshopScript akWorkshopRef - the settlement workshop to spawn at
; 
; Bool abBrahmin - Whether this should be a brahmin or a settler
;
; ActorBase aActorFormOverride - Allows you to spawn a custom NPC. Make sure that the Actor form you are sending has the WorkshopNPCScript attached and configured!
;
; Returns:
; Created NPC ref
; -----------------------------------

WorkshopNPCScript Function SpawnWorkshopNPC(WorkshopScript akWorkshopRef, Bool abBrahmin = false, ActorBase aActorFormOverride = None) global
	WorkshopFramework:WSWF_APIQuest API = GetAPI()
	
	if( ! API)
		Debug.Trace("[WorkshopFramework] Failed to get API.")
		return None
	endif
	
	if(aActorFormOverride != None)
		return API.NPCManager.CreateWorkshopNPC(aActorFormOverride, akWorkshopRef)
	elseif(abBrahmin)
		return API.NPCManager.CreateBrahmin(akWorkshopRef)
	else
		return API.NPCManager.CreateSettler(akWorkshopRef)
	endif
EndFunction


; -----------------------------------
; IsPlayerInWorkshopMode
; -----------------------------------

Bool Function IsPlayerInWorkshopMode() global
	WorkshopFramework:WSWF_APIQuest API = GetAPI()
	
	if( ! API)
		Debug.Trace("[WorkshopFramework] Failed to get API.")
		return None
	endif
	
	WorkshopScript workshopRef = API.WSWF_Main.LastWorkshopAlias.GetRef() as WorkshopScript
	
	if(workshopRef)
		return workshopRef.UFO4P_InWorkshopMode
	else
		return false
	endif
EndFunction