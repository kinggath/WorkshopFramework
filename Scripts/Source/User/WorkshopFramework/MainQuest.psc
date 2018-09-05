; ---------------------------------------------
; WorkshopFramework:MainQuest.psc - by kinggath
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

Scriptname WorkshopFramework:MainQuest extends WorkshopFramework:Library:MasterQuest

import WorkshopFramework:Library:DataStructures
import WorkshopFramework:Library:UtilityFunctions

; ---------------------------------------------
; Consts
; ---------------------------------------------


; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------

Group FormLists
	FormList Property WorkshopParentExcludeFromAssignmentRules Auto Const Mandatory
	{ Point to the same list as WorkshopParent.ParentExcludeFromAssignmentRules }
EndGroup

Group Keywords
	Keyword Property LocationTypeSettlement Auto Const
EndGroup

Group Assets
	Form Property TestSpawnForm Auto Const
	WorldObject[] Property WOTest Auto Const
EndGroup

; ---------------------------------------------
; Properties
; ---------------------------------------------

Bool Property bFrameworkReady = false Auto Hidden

; ---------------------------------------------
; Vars
; ---------------------------------------------

; ---------------------------------------------
; Events 
; ---------------------------------------------

int iAwaitingBatchID = -1
Event WorkshopFramework:PlaceObjectManager.ObjectBatchCreated(WorkshopFramework:PlaceObjectManager akSenderRef, Var[] akArgs)
	if((akArgs[0] as ActorValue) == WorkshopFramework:WSWF_API.GetDefaultPlaceObjectsBatchAV() && (akArgs[1] as Float) == iAwaitingBatchID)		
		String sMessage = "Event batch ID matches, found " + (akArgs.Length - 3) + " objects."
		if((akArgs[2] as Bool) == true)
			Debug.Trace(sMessage + "Expecting additional event.")
		else
			Debug.Trace(sMessage + "End of batch.")
			Debug.MessageBox("Received final event, total process took: " + (Utility.GetCurrentRealTime() - fTestTime) + " seconds.")
		endif
	else
		Debug.MessageBox("Batch received, but the ID doesn't belong to us.")
	endif
EndEvent

; ---------------------------------------------
; Extended Handlers
; ---------------------------------------------

Function HandleGameLoaded()
	; Make sure our debug log is open
	WorkshopFramework:Library:UtilityFunctions.StartUserLog()
	
	Parent.HandleGameLoaded()
	
	ThreadManager.RegisterForCallbackThreads(Self)
EndFunction


Function HandleQuestInit()
	Parent.HandleQuestInit()
EndFunction

; ---------------------------------------------
; Overrides
; ---------------------------------------------

Bool Function StartQuests()
	bFrameworkReady = Parent.StartQuests()
	
	
	return bFrameworkReady
EndFunction

; Override parent function - to check for same location on the settlement type
Function HandleLocationChange(Location akNewLoc)
	if( ! akNewLoc)
		return
	endif
	
	Location lastParentLocation = LatestLocation.GetLocation()
	
	if( ! akNewLoc.IsSameLocation(lastParentLocation) || ! akNewLoc.IsSameLocation(lastParentLocation, LocationTypeSettlement))
		LatestLocation.ForceLocationTo(akNewLoc)
		StartTimer(fLocationChangeDelay, LocationChangeTimerID)	
	endif
EndFunction


; ---------------------------------------------
; Test Functions
; ---------------------------------------------
Float fTestTime = 0.0
Function TestAPI()
	fTestTime = Utility.GetCurrentRealTime()
	Debug.MessageBox("Creating 2000 items via API method...")
	iAwaitingBatchID = WorkshopFramework:WSWF_API.CreateBatchSettlementObjects(WOTest, None, None, true, None)
	Float fFinishTime = Utility.GetCurrentRealTime() - fTestTime
	Debug.MessageBox("Finished in " + fFinishTime + " seconds.")
EndFunction


Function TestWorldObjects()
	Float fStarted = Utility.GetCurrentRealTime()
	
	Float[] fPosition = new Float[6]
	fPosition[0] = PlayerRef.X
	fPosition[1] = PlayerRef.Y
	fPosition[2] = PlayerRef.Z + 200.0
	fPosition[3] = 0.0
	fPosition[4] = 0.0
	fPosition[5] = 0.0
	
	int i = 0
	while(i < WOTest.Length)
		Var[] kArgs = new Var[0]
		
		kArgs.Add(GetWorldObjectForm(WOTest[i]))
		kArgs.Add(fPosition[0])
		kArgs.Add(fPosition[1])
		kArgs.Add(fPosition[2])
		kArgs.Add(fPosition[3])
		kArgs.Add(fPosition[4])
		kArgs.Add(fPosition[5])
		kArgs.Add(WOTest[i].fScale)
		kArgs.Add(None) ; TagAV
		kArgs.Add(0.0) ; TagAVVAlue
		kArgs.Add(false) ; Forcestatic
		kArgs.Add(true) ; Enable
		
		ThreadManager.QueueThread("", "PlaceObject", kArgs)
		
		i += 1
	endWhile
	
	Float fEnded = Utility.GetCurrentRealTime()
	Debug.MessageBox("Finished test, took " + (fEnded - fStarted) + " seconds. Created " + WOTest.Length + " items.")
EndFunction

Event WorkshopFramework:Library:ThreadRunner.OnThreadCompleted(WorkshopFramework:Library:ThreadRunner akThreadRunner, Var[] akargs)
	; akargs[0] = sCustomCallCallbackID, akargs[1] = iCallbackID, akargs[2] = Result from called function
	
EndEvent

Function TestThreadManager(Bool abGlobal = false, Int aiMaxThreads = 0)
	if(aiMaxThreads > 0)
		ThreadManager.OverrideMaxThreads(aiMaxThreads)
	endif
	
	int i = 0
	int iMax = 2000
	
	Var[] kArgs = new Var[6]
	kArgs[0] = PlayerRef as ObjectReference
	kArgs[1] = TestSpawnForm as Form
	kArgs[2] = LocationTypeSettlement
	kArgs[3] = PlayerRef.X
	kArgs[4] = PlayerRef.Y
	kArgs[5] = PlayerRef.Z
	
	Debug.MessageBox("Attempting to create 2000 items")
	;Debug.Trace("Queuing thread with args: " + kArgs)
	int iCallbackID
	Float fStarted = Utility.GetCurrentRealTime()
	
	if(abGlobal)
		Debug.MessageBox("Using CallGlobalFunction method...")
		while(i < iMax)		
			iCallbackID = ThreadManager.QueueGlobalThread("", "WorkshopFramework:Library:UtilityFunctions", "SpawnTestObject", kArgs)
			Debug.Trace("QueuedGlobalThread, callbackID: " + iCallbackID)
			
			i += 1
		endWhile
	else
		Debug.MessageBox("Using Predefined function on ThreadRunner method...")
		
		;(Int aiCallBackID, String asCustomCallbackID, Form PlaceMe, Float afPosX, Float afPosY, Float afPosZ, Float afAngleX, Float afAngleY, Float afAngleZ, Float afScale, ActorValue aTagAV = None, Float afTagAVValue = 0.0, Bool abForceStatic = false, Bool abEnable = true)
		kArgs = new Var[0]
		
		kArgs.Add(TestSpawnForm)
		kArgs.Add(PlayerRef.X)
		kArgs.Add(PlayerRef.Y)
		kArgs.Add(PlayerRef.Z + 200)
		kArgs.Add(0.0)
		kArgs.Add(0.0)
		kArgs.Add(0.0)
		kArgs.Add(1.0)
		kArgs.Add(None)
		kArgs.Add(0.0)
		kArgs.Add(false)
		kArgs.Add(true)
		
		while(i < iMax)		
			iCallbackID = ThreadManager.QueueThread("", "PlaceObject", kArgs)
			if(iCallbackID < 0)
				; Try again shortly
				Utility.Wait(0.1)
				i -= 1
			endif
			
			i += 1
		endWhile
	endif
	
	Float fEnded = Utility.GetCurrentRealTime()
	Debug.MessageBox("Finished test, took " + (fEnded - fStarted) + " seconds.")
EndFunction

Keyword Property WorkshopItemKeyword Auto Const
ActorValue Property WorkshopResourceObject Auto Const

Function CheckLinkedRefs(WorkshopScript akWorkshopRef, int aiCountToReport = 1)
	if( ! akWorkshopRef)
		return
	endif
	
	; Note - only loaded and persisted refs will be returned with this
	ObjectReference[] kLinked = akWorkshopRef.GetLinkedRefChildren(WorkshopItemKeyword)
	
	Debug.MessageBox("Found " + kLinked.Length + " linked refs, reporting on first " + aiCountToReport + " resource objects.")
	
	int i = 0
	int iReported = 0
	while(i < kLinked.Length && iReported < aiCountToReport)
		Debug.Trace("Testing for resource on ref: " + kLinked[i] + ", resource value = " + kLinked[i].GetValue(WorkshopResourceObject))
		if(kLinked[i].GetValue(WorkshopResourceObject) > 0)
			TestAVs(kLinked[i])
			iReported += 1
		endif
	
		i += 1
	endWhile
EndFunction

ActorValue Property HappinessBonus Auto Const
ActorValue Property Food Auto Const
ActorValue Property Water Auto Const
ActorValue Property Safety Auto Const
ActorValue Property Scavenge Auto Const
ActorValue Property PowerGenerated Auto Const
ActorValue Property Income Auto Const
Function TestAVs(ObjectReference akRefCheck)
	if( ! akRefCheck)
		return
	endif
	
	String thisMessage = "Reference Adds: "
	
	Float fHappinessBonus = akRefCheck.GetValue(HappinessBonus)
	Float fFood = akRefCheck.GetValue(Food)
	Float fWater = akRefCheck.GetValue(Water)
	Float fSafety = akRefCheck.GetValue(Safety)
	Float fScavenge = akRefCheck.GetValue(Scavenge)
	Float fPower = akRefCheck.GetValue(PowerGenerated)
	Float fIncome = akRefCheck.GetValue(Income)
	
	if(fHappinessBonus > 0)
		thisMessage += fHappinessBonus + " HappinessBonus"
	elseif(fFood > 0)
		thisMessage += fFood + " Food"
	elseif(fWater > 0)
		thisMessage += fWater + " Water"
	elseif(fSafety > 0)
		thisMessage += fSafety + " Safety"
	elseif(fScavenge > 0)
		thisMessage += fScavenge + " Scavenge"
	elseif(fPower > 0)
		thisMessage += fPower + " Power"
	elseif(fIncome > 0)
		thisMessage += fIncome + " Income"
	else
		thisMessage += "nothing."
	endif
	
	Debug.MessageBox(thisMessage)
EndFunction