; ---------------------------------------------
; WorkshopFramework:PlaceObjectManager.psc - by kinggath
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

Scriptname WorkshopFramework:PlaceObjectManager extends WorkshopFramework:Library:SlaveQuest

import WorkshopFramework:Library:DataStructures
import WorkshopFramework:Library:UtilityFunctions
import WorkshopFramework:Library:ThirdParty:Cobb:CobbLibraryRotations


CustomEvent ObjectBatchCreated
CustomEvent ObjectRemoved

Struct ObjectWatch
	int iAwaitingObjectCount = 0
	ActorValue WithAV
	Float WithAVValue
	int iSeenObjectCount = 0
EndStruct

; ---------------------------------------------
; Consts
; ---------------------------------------------

String sThreadID_ObjectCreated = "ObjectCreated"
String sThreadID_ObjectRemoved = "ObjectRemoved"
Int MAXBATCHQUEUEID = 1000000

; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------

Group Controllers
	WorkshopFramework:MainThreadManager Property ThreadManager Auto Const Mandatory
EndGroup

Group Aliases
	RefCollectionAlias Property CreatedObjects Auto Const Mandatory
	{ Temporary holder to track created objects returned from thread manager }
	RefCollectionAlias Property SentObjects Auto Const Mandatory
	{ Temporary holder to track which objects have been sent out in an event }
EndGroup

Group Assets
	Form Property PlaceObjectThread Auto Const Mandatory
	Form Property ScrapObjectThread Auto Const Mandatory
	Form Property PositionHelper Auto Const Mandatory
EndGroup

Group AVs
	ActorValue Property BatchTagAV Auto Const Mandatory
EndGroup

; ---------------------------------------------
; Properties
; ---------------------------------------------

Int iLastQueuedBatchIndex = -1
Int Property NextQueuedBatchIndex	
	Int Function Get()
		iLastQueuedBatchIndex += 1
		
		if(iLastQueuedBatchIndex > 127)
			iLastQueuedBatchIndex = 0
		endif
		
		return iLastQueuedBatchIndex
	EndFunction
EndProperty

Int iLastQueuedBatchID = -1
Int Property NextQueuedBatchID	
	Int Function Get()
		iLastQueuedBatchID += 1
		
		return iLastQueuedBatchID
	EndFunction
EndProperty



; ---------------------------------------------
; Vars
; ---------------------------------------------

ObjectWatch[] QueuedBatches

; ---------------------------------------------
; Events 
; ---------------------------------------------

Event WorkshopFramework:Library:ThreadRunner.OnThreadCompleted(WorkshopFramework:Library:ThreadRunner akThreadRunner, Var[] akargs)
	; akargs[0] = sCustomCallCallbackID, akargs[1] = iCallbackID, akargs[2] = ThreadRef
	String sCustomCallCallbackID = akargs[0] as String
	if(sCustomCallCallbackID == sThreadID_ObjectCreated)
		WorkshopFramework:ObjectRefs:Thread_PlaceObject kThreadRef = akargs[2] as WorkshopFramework:ObjectRefs:Thread_PlaceObject
		if(kThreadRef)
			ObjectReference kCreatedRef = kThreadRef.kResult
			
			if(kCreatedRef)
				CreatedObjects.AddRef(kCreatedRef)
				
				ModTrace("[WSFW] PlaceObjectManager - CreatedRef " + kCreatedRef + "returned from thread, updating monitors.")
				
				UpdateMonitors(kCreatedRef)
			endif
			
			; Clean up thread now that we have the result
			kThreadRef.SelfDestruct()
		endif
	elseif(sCustomCallCallbackID == sThreadID_ObjectRemoved)
		WorkshopFramework:ObjectRefs:Thread_ScrapObject kThreadRef = akargs[2] as WorkshopFramework:ObjectRefs:Thread_ScrapObject
		
		Var[] kArgs = new Var[2]
		kArgs[0] = akargs[1] as Int
		kArgs[1] = kThreadRef.bWasRemoved
		
		SendCustomEvent("ObjectRemoved", kArgs)
	endif
EndEvent


; ---------------------------------------------
; Extended Handlers
; ---------------------------------------------

Function HandleQuestInit()
	Parent.HandleQuestInit()
	
	ThreadManager.RegisterForCallbackThreads(Self)
EndFunction

Function HandleGameLoaded()
	Parent.HandleGameLoaded()
	
	if(iLastQueuedBatchID > MAXBATCHQUEUEID)
		MAXBATCHQUEUEID = 0
	endif
EndFunction

; ---------------------------------------------
; Overrides
; ---------------------------------------------


; ---------------------------------------------
; Functions
; ---------------------------------------------

Int Function CreateBatchObjects(WorldObject[] PlaceMe, WorkshopScript akWorkshopRef = None, ActorValueSet aSetAV = None, ObjectReference akPositionRelativeTo = None, Bool abStartEnabled = true, Bool abCallbackEventNeeded = true)
	; Setup a monitor so we can fire off an event when these are all created
	Int iBatchID = NextQueuedBatchID
	
	if(abCallbackEventNeeded)
		ObjectWatch NewBatch = new ObjectWatch
		NewBatch.iAwaitingObjectCount = PlaceMe.Length
		NewBatch.iSeenObjectCount = 0
		if(aSetAV)
			NewBatch.WithAV = GetActorValueSetForm(aSetAV)
			NewBatch.WithAVValue = aSetAV.fValue
		else
			; No specific data sent, apply our own
				; For monitor
			NewBatch.WithAV = BatchTagAV
			NewBatch.WithAVValue = iBatchID as Float
			
				; For items
			aSetAV = new ActorValueSet
			aSetAV.AVForm = BatchTagAV
			aSetAV.fValue = iBatchID as Float
		endif
		
		ModTrace("[WSFW] PlaceObjectManager: CreateBatchObjects setting up batch monitor " + NewBatch + ".")
		
		MonitorBatch(NewBatch)
	endif
	
	; Send all creation requests to the thread manager
	Float[] fPosition = new Float[3]
	Float[] fAngle = new Float[3]
		
	if(akPositionRelativeTo)		
		; Calculate this here so we're not doing it over and over inside the loop
		fPosition[0] = akPositionRelativeTo.X
		fPosition[1] = akPositionRelativeTo.Y
		fPosition[2] = akPositionRelativeTo.Z
		fAngle[0] = akPositionRelativeTo.GetAngleX()
		fAngle[1] = akPositionRelativeTo.GetAngleY()
		fAngle[2] = akPositionRelativeTo.GetAngleZ()
	endif
			
	int i = 0
	int index = 0
	while(i < PlaceMe.Length)
		; Create new version of WorldObject
		WorldObject newObject = PlaceMe[index]
		
		if(akPositionRelativeTo)
			; Calculate new coords
			Float[] fPosOffset = new Float[3]
			Float[] fAngleOffset = new Float[3]
			Float[] fNew3dData = new Float[6]
			
			fPosOffset[0] = newObject.fPosX
			fPosOffset[1] = newObject.fPosY
			fPosOffset[2] = newObject.fPosZ
			fAngleOffset[0] = newObject.fAngleX
			fAngleOffset[1] = newObject.fAngleY
			fAngleOffset[2] = newObject.fAngleZ
			
			fNew3dData = GetCoordinatesRelativeToBase(fPosition, fAngle, fPosOffset, fAngleOffset)
			
			newObject.fPosX = fNew3dData[0]
			newObject.fPosY = fNew3dData[1]
			newObject.fPosZ = fNew3dData[2]
			newObject.fAngleX = fNew3dData[3]
			newObject.fAngleY = fNew3dData[4]
			newObject.fAngleZ = fNew3dData[5]
		endif
		
		CreateObject(newObject, akWorkshopRef, aSetAV, -1, None, abStartEnabled, abCallbackEventNeeded)
		
		index += 1
		if(index >= PlaceMe.Length)
			index = 0
		endif
		i += 1
	endWhile
	
	return iBatchID
EndFunction


Int Function CreateObject(WorldObject aPlaceMe, WorkshopScript akWorkshopRef = None, ActorValueSet aSetAV = None, Int aiFormlistIndex = -1, ObjectReference akPositionRelativeTo = None, Bool abStartEnabled = true, Bool abCallbackEventNeeded = true)
	; Send creation request to the thread manager
	Form FormToPlace = GetWorldObjectForm(aPlaceMe, aiFormlistIndex)
		
	if(FormToPlace)
		String sCustomCallbackID = sThreadID_ObjectCreated
		if( ! abCallbackEventNeeded)
			sCustomCallbackID = ""
		else
			ModTrace("[WSFW] PlaceObjectManager: Creating CreateObject thread - requesting callback event.")
		endif
		
		WorkshopFramework:ObjectRefs:Thread_PlaceObject kThread = ThreadManager.CreateThread(PlaceObjectThread) as WorkshopFramework:ObjectRefs:Thread_PlaceObject
		
		if(kThread)
			if(aSetAV)
				kThread.AddTagAVSet(GetActorValueSetForm(aSetAV), aSetAV.fValue)
			endif
			
			kThread.bStartEnabled = abStartEnabled
			kThread.bForceStatic = aPlaceMe.bForceStatic
			kThread.kSpawnAt = PlayerRef
			kThread.SpawnMe = FormToPlace
			kThread.fPosX = aPlaceMe.fPosX
			kThread.fPosY = aPlaceMe.fPosY
			kThread.fPosZ = aPlaceMe.fPosZ
			kThread.fAngleX = aPlaceMe.fAngleX
			kThread.fAngleY = aPlaceMe.fAngleY
			kThread.fAngleZ = aPlaceMe.fAngleZ
			kThread.fScale = aPlaceMe.fScale
			kThread.kWorkshopRef = akWorkshopRef
			
			int iCallBackID = ThreadManager.QueueThread(kThread, sCustomCallbackID)
			
			return iCallBackID
		endif
	endif
		
	return -1
EndFunction


ObjectReference Function CreateObjectImmediately(WorldObject aPlaceMe, WorkshopScript akWorkshopRef = None, ActorValueSet aSetAV = None, Int aiFormlistIndex = -1, ObjectReference akPositionRelativeTo = None, Bool abStartEnabled = true)
	; Send creation request to the thread manager
	Form FormToPlace = GetWorldObjectForm(aPlaceMe, aiFormlistIndex)
		
	if(FormToPlace)
		WorkshopFramework:ObjectRefs:Thread_PlaceObject kThread = ThreadManager.CreateThread(PlaceObjectThread) as WorkshopFramework:ObjectRefs:Thread_PlaceObject
		
		if(kThread)
			if(aSetAV)
				kThread.AddTagAVSet(GetActorValueSetForm(aSetAV), aSetAV.fValue)
			endif
			
			kThread.bStartEnabled = abStartEnabled
			kThread.bForceStatic = aPlaceMe.bForceStatic
			kThread.kSpawnAt = PlayerRef
			kThread.SpawnMe = FormToPlace
			kThread.fPosX = aPlaceMe.fPosX
			kThread.fPosY = aPlaceMe.fPosY
			kThread.fPosZ = aPlaceMe.fPosZ
			kThread.fAngleX = aPlaceMe.fAngleX
			kThread.fAngleY = aPlaceMe.fAngleY
			kThread.fAngleZ = aPlaceMe.fAngleZ
			kThread.fScale = aPlaceMe.fScale
			kThread.kWorkshopRef = akWorkshopRef
			
			kThread.RunCode()
			
			ObjectReference kCreatedRef = kThread.kResult
			
			if( ! kThread.bAwaitingOnLoadEvent)
				kThread.ReleaseObjectReferences()
				kThread.SelfDestruct()
			endif
			
			return kCreatedRef
		endif
	endif
		
	return None
EndFunction


Int Function ScrapObject(ObjectReference akScrapMe, Bool abCallbackEventNeeded = true)
	; Send creation request to the thread manager
	String sCustomCallbackID = sThreadID_ObjectRemoved
	if( ! abCallbackEventNeeded)
		sCustomCallbackID = ""
	else
		ModTrace("[WSFW] PlaceObjectManager: Creating ScrapObject thread - requesting callback event.")
	endif
		
	WorkshopFramework:ObjectRefs:Thread_ScrapObject kThread = ThreadManager.CreateThread(ScrapObjectThread) as WorkshopFramework:ObjectRefs:Thread_ScrapObject
	
	if(kThread)
		kThread.kScrapMe = akScrapMe
					
		int iCallBackID = ThreadManager.QueueThread(kThread, sCustomCallbackID)
		
		return iCallBackID
	endif	
		
	return -1
EndFunction


Function FetchMyObjects(ActorValue aWithAV, Float afWithAVValue)
	; Get Edit Lock 
	int iLockKey = GetLock()
	if(iLockKey <= GENERICLOCK_KEY_NONE)
        ModTrace("Unable to get lock!", 2)
		
		return
	endif
	
	;
	; Lock acquired - do work
	;
	int i = 0
	int iTotal = CreatedObjects.GetCount()
	ObjectReference[] kSendBatch = new ObjectReference[0]
	while(i < iTotal)
		ObjectReference thisObject = CreatedObjects.GetAt(i)
		if(thisObject.GetValue(aWithAV) == afWithAVValue)
			if(kSendBatch.Length == 125)
				SendBatchEvent(aWithAV, afWithAVValue, kSendBatch, true)
				
				SentObjects.AddArray(kSendBatch)
				
				kSendBatch = new ObjectReference[0]
			endif
			
			kSendBatch.Add(thisObject)			
		endif
		
		i += 1
	endWhile
	
	if(kSendBatch.Length > 0)
		SendBatchEvent(aWithAV, afWithAVValue, kSendBatch, false)
		
		SentObjects.AddArray(kSendBatch)
	endif
	
	ClearSentObjects()
	
	; Release Edit Lock
	if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
        ModTrace("Failed to release lock " + iLockKey + "!", 2)
    endif	
EndFunction


Function ClearSentObjects()
	; Be sure to call this behind a lock or new refs could be added to SentObjects while this is running
	int i = 0
	int iTotal = SentObjects.GetCount()
	while(i < iTotal)
		CreatedObjects.RemoveRef(SentObjects.GetAt(i))
		
		i += 1
	endWhile
	
	SentObjects.RemoveAll()
EndFunction


Function SendBatchEvent(ActorValue aWithAV, Float afWithAVValue, ObjectReference[] akSendRefs, Bool abMoreEventsComing = false)
	Var[] kArgs = new Var[0]
	
	kArgs.Add(aWithAV)
	kArgs.Add(afWithAVValue)
	kArgs.Add(abMoreEventsComing)
	
	int i = 0 
	while(i < akSendRefs.Length)
		kArgs.Add(akSendRefs[i])
		
		i += 1
	endWhile
	
	SendCustomEvent("ObjectBatchCreated", kArgs)
EndFunction

Int Function MonitorBatch(ObjectWatch aBatch)
	if( ! QueuedBatches)
		QueuedBatches = new ObjectWatch[0]
	endif
	
	int IncrementIndex = NextQueuedBatchIndex
		
	if(QueuedBatches.Length < 128)
		QueuedBatches.Add(aBatch)
	else
		QueuedBatches[IncrementIndex] = aBatch
	endif
	
	Debug.Trace("Stored batch monitor at index " + IncrementIndex + ": " + QueuedBatches)
	
	return IncrementIndex
EndFunction


Function UpdateMonitors(ObjectReference akPlacedRef)
	Bool bStartedDisabled = akPlacedRef.IsDisabled()
	
	if(bStartedDisabled)
		; Must be enabled in order to check AVs
		akPlacedRef.Enable(false)
	endif
	
	
	int i = 0
	while(i < QueuedBatches.Length)
		ModTrace("[WSFW] UpdateMonitors, testing " + akPlacedRef + " with batch value: " + akPlacedRef.GetValue(QueuedBatches[i].WithAV) + " against monitor: " + QueuedBatches[i])
		
		if(QueuedBatches[i].WithAV && akPlacedRef.GetValue(QueuedBatches[i].WithAV) == QueuedBatches[i].WithAVValue)
			QueuedBatches[i].iSeenObjectCount += 1
			
			if(QueuedBatches[i].iSeenObjectCount >= QueuedBatches[i].iAwaitingObjectCount)
				; Send all objects
				FetchMyObjects(QueuedBatches[i].WithAV, QueuedBatches[i].WithAVValue)
				
				; Clear out this entry
				QueuedBatches[i] = new ObjectWatch	
			endif
			
			if(bStartedDisabled)
				akPlacedRef.Disable(false)
			endif
			
			; End this loop
			return
		endif
		
		i += 1
	endWhile
	
	if(bStartedDisabled)
		akPlacedRef.Disable(false)
	endif
EndFunction