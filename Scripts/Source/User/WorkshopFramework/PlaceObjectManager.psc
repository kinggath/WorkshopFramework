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
CustomEvent GridCreated

; 1.0.5 - Creating new event
CustomEvent SimpleObjectBatchCreated ; Simplied version of batch system that doesn't require testing each item for an AV


; 1.0.5 - Simplified ObjectWatch
Struct ObjectWatchSimple
	int iAwaitingObjectCount = 0
	int iBatchID = 0
	int iSeenObjectCount = 0
	int iBatchIndex = 0
EndStruct

; 2.0.0
Struct GridObjectWatch
	int iAwaitingObjectCount = 0
	int iGridCallbackID = 0
	int iSeenObjectCount = 0
	Bool bAlignToGround = false
	Bool bHideUntilCellUnloads = false	
EndStruct

; ---------------------------------------------
; Consts
; ---------------------------------------------

String sThreadID_GridObjectPlaced = "GridObjectPlaced" ; 2.0.0
String sThreadID_ObjectRemoved = "ObjectRemoved"
String sThreadID_ObjectPlaced = "ObjectPlaced" ; 1.0.5 - switching over to new event so we don't break earlier saves that might be relying on ObjectCreated
Int MAXBATCHQUEUEID = 1000000
Int iDummyCallbackCount = 10000

; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------

Group Controllers
	WorkshopFramework:MainThreadManager Property ThreadManager Auto Const Mandatory
	WorkshopFramework:MainQuest Property WSFW_Main Auto Const Mandatory
	WorkshopParentScript Property WorkshopParent Auto Const Mandatory
EndGroup

Group Aliases
	RefCollectionAlias Property CreatedObjects Auto Const Mandatory
	{ Temporary holder to track created objects returned from thread manager }
	RefCollectionAlias Property SentObjects Auto Const Mandatory
	{ Temporary holder to track which objects have been sent out in an event }
	RefCollectionAlias[] Property PlacedObjects Auto Const Mandatory
	{ 1.0.5 - Streamlining the threaded object creation. We'll now have a RefCollection for each of the Batches and just put the items in as opposed to having to test each item for an AV. }
	RefCollectionAlias Property EnableAfterUnload Auto Const Mandatory
	{ Items added here will be Enabled after the parent cell unloads }
EndGroup

Group Assets
	Form Property PlaceObjectThread Auto Const Mandatory
	Form Property ScrapObjectThread Auto Const Mandatory
	Form Property PositionHelper Auto Const Mandatory
EndGroup

Group AVs
	ActorValue Property BatchTagAV Auto Const Mandatory
EndGroup

Group Keywords
	Keyword Property WorkshopItemKeyword Auto Const Mandatory
	Keyword Property MoveToNavmeshKeyword Auto Const Mandatory
	Keyword Property PreventOverlapKeyword Auto Const Mandatory
EndGroup
; ---------------------------------------------
; Properties
; ---------------------------------------------

; 1.0.5 - Need a second index tracker as the previous version is being made obsolete
Int iLastQueuedSimpleBatchIndex = -1 ; Needs to start at -1 so first returned value is 0 since its array based
Int Property NextQueuedSimpleBatchIndex	
	Int Function Get()
		iLastQueuedSimpleBatchIndex += 1
		
		if(iLastQueuedSimpleBatchIndex > 127)
			iLastQueuedSimpleBatchIndex = 0
		endif
		
		return iLastQueuedSimpleBatchIndex
	EndFunction
EndProperty


Int iLastQueuedBatchID = 0
Int Property NextQueuedBatchID	
	Int Function Get()
		iLastQueuedBatchID += 1
		
		return iLastQueuedBatchID
	EndFunction
EndProperty


Int iLastQueuedGridIndex = -1 ; Needs to start at -1 so first returned value is 0 since its array based
Int Property NextQueuedGridIndex	
	Int Function Get()
		iLastQueuedGridIndex += 1
		
		if(iLastQueuedGridIndex > 127)
			iLastQueuedGridIndex = 0
		endif
		
		return iLastQueuedGridIndex
	EndFunction
EndProperty


; ---------------------------------------------
; Vars
; ---------------------------------------------

ObjectWatchSimple[] QueuedSimpleBatches ; 1.0.5
GridObjectWatch[] GridItemBatches ; 2.0.0

Keyword[] LinkedGridKeywords ; 2.0.0 - Used for when deleting overlapping grid objects so we can sever all links

; ---------------------------------------------
; Events 
; ---------------------------------------------

Event WorkshopFramework:Library:ThreadRunner.OnThreadCompleted(WorkshopFramework:Library:ThreadRunner akThreadRunner, Var[] akargs)
	; akargs[0] = sCustomCallCallbackID, akargs[1] = iCallbackID, akargs[2] = ThreadRef
	String sCustomCallCallbackID = akargs[0] as String
	
	;ModTrace("Received event with callback ID: " + sCustomCallCallbackID)
	if(sCustomCallCallbackID == sThreadID_ObjectCreated)
		WorkshopFramework:ObjectRefs:Thread_PlaceObject kThreadRef = akargs[2] as WorkshopFramework:ObjectRefs:Thread_PlaceObject
		if(kThreadRef)
			ObjectReference kCreatedRef = kThreadRef.kResult
			
			if(kCreatedRef)				
				CreatedObjects.AddRef(kCreatedRef)
				;ModTrace("[WSFW] PlaceObjectManager - CreatedRef " + kCreatedRef + "returned from thread, updating batch monitors.")
				UpdateMonitors(kCreatedRef)
 			endif
			
			; Clean up thread now that we have the result
			kThreadRef.SelfDestruct()
		endif
	elseif(sCustomCallCallbackID == sThreadID_ObjectPlaced)
		; 1.0.5 - Switching to a new callback event and method
		WorkshopFramework:ObjectRefs:Thread_PlaceObject kThreadRef = akargs[2] as WorkshopFramework:ObjectRefs:Thread_PlaceObject
		if(kThreadRef)
			ObjectReference kCreatedRef = kThreadRef.kResult
			int iBatchID = kThreadRef.iBatchID
			
			kThreadRef.SelfDestruct() ; 1.2.0 - this should have been set up this way from the get-go
			
			ModTrace("[WSFW] PlaceObjectManager - CreatedRef " + kCreatedRef + " returned from thread, updating simple monitor for batch " + iBatchID)
			if(kCreatedRef && iBatchID >= 0)
				int iBatchIndex = GetSimpleBatchIndex(iBatchID)
				PlacedObjects[iBatchIndex].AddRef(kCreatedRef)		
				UpdateSimpleBatchMonitor(iBatchIndex)						
			endif
		endif
	elseif(sCustomCallCallbackID == sThreadID_ObjectRemoved)
		WorkshopFramework:ObjectRefs:Thread_ScrapObject kThreadRef = akargs[2] as WorkshopFramework:ObjectRefs:Thread_ScrapObject
		
		Var[] kArgs = new Var[2]
		kArgs[0] = akargs[1] as Int
		kArgs[1] = kThreadRef.bWasRemoved
		
		SendCustomEvent("ObjectRemoved", kArgs)
	elseif(sCustomCallCallbackID == sThreadID_GridObjectPlaced)
		WorkshopFramework:ObjectRefs:Thread_PlaceObject kThreadRef = akargs[2] as WorkshopFramework:ObjectRefs:Thread_PlaceObject
		if(kThreadRef)
			ObjectReference kCreatedRef = kThreadRef.kResult
			int iGridCallbackID = kThreadRef.iBatchID
			
			kThreadRef.SelfDestruct() 
			
			int iWatchIndex = GridItemBatches.FindStruct("iGridCallbackID", iGridCallbackID)
			if(iWatchIndex >= 0)
				if(GridItemBatches[iWatchIndex].bAlignToGround)
					MoveToNavMesh(kCreatedRef)
				endif
				
				if(GridItemBatches[iWatchIndex].bHideUntilCellUnloads)
					EnableAfterUnload.AddRef(kCreatedRef)
				endif
				
				UpdateGridItemBatch(iWatchIndex)
			endif
		endif
	endif
EndEvent


Event WorkshopFramework:MainQuest.PlayerEnteredSettlement(WorkshopFramework:MainQuest akQuestRef, Var[] akArgs)
	WorkshopScript kWorkshopRef = akArgs[0] as WorkshopScript
	Bool bPreviouslyUnloaded = akArgs[1] as Bool
	
	if(bPreviouslyUnloaded)
		HandlePlayerEnteredSettlement(kWorkshopRef)
	endif
EndEvent

; ---------------------------------------------
; Extended Handlers
; ---------------------------------------------

Function HandleQuestInit()
	Parent.HandleQuestInit()
	
	RegisterForEvents()
EndFunction

Function HandleGameLoaded()
	Parent.HandleGameLoaded()
	
	RegisterForEvents()
	if(iLastQueuedBatchID > MAXBATCHQUEUEID)
		MAXBATCHQUEUEID = 0
	endif
EndFunction

Function RegisterForEvents()
	ThreadManager.RegisterForCallbackThreads(Self)
	
	RegisterForCustomEvent(WSFW_Main, "PlayerEnteredSettlement")
EndFunction

Function HandleInstallModChanges()
	if(iInstalledVersion < 28) ; 2.0.0
		RegisterForCustomEvent(WSFW_Main, "PlayerEnteredSettlement")
	endif	
	
	Parent.HandleInstallModChanges()
EndFunction


Function HandleLocationChange(Location akNewLoc)
	int iEnableCount = EnableAfterUnload.GetCount()
	
	if(iEnableCount > 0) 
        while(iEnableCount > 0)    
            ObjectReference thisObject = EnableAfterUnload.GetAt(iEnableCount - 1)
            
            Cell thisCell = thisObject.GetParentCell()
            if( ! thisCell || ! thisCell.IsLoaded())
                if( ! thisObject.IsDeleted())
                    thisObject.Enable(false)
                endif
                
                EnableAfterUnload.RemoveRef(thisObject)
            endif
            
            iEnableCount -= 1
        endWhile
    endif
EndFunction


Function HandlePlayerEnteredSettlement(WorkshopScript akWorkshopRef)
	UpdateObjects(akWorkshopRef)
EndFunction

; ---------------------------------------------
; Overrides
; ---------------------------------------------


; ---------------------------------------------
; Functions
; ---------------------------------------------

; 1.0.5 - Simplifying this function so it doesn't require checking each item for an AV
Int Function CreateBatchObjectsV2(WorldObject[] PlaceMe, WorkshopScript akWorkshopRef = None, ObjectReference akPositionRelativeTo = None, Bool abStartEnabled = true, Bool abCallbackEventNeeded = true)
	; Setup a monitor so we can fire off an event when these are all created
	Int iBatchID = NextQueuedBatchID
	
	if(abCallbackEventNeeded)
		ObjectWatchSimple NewBatch = new ObjectWatchSimple
		NewBatch.iAwaitingObjectCount = PlaceMe.Length
		NewBatch.iSeenObjectCount = 0
		NewBatch.iBatchID = iBatchID
		
		ModTrace("[WSFW] PlaceObjectManager: CreateBatchObjectsV2 setting up simple batch monitor " + NewBatch + ".")
		
		MonitorSimpleBatch(NewBatch)
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
			newObject = CopyWorldObject(PlaceMe[index]) ; 1.0.7: Avoid overwriting the original record
			
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
		
		int iThreadCallbackID = CreateObject_Private(newObject, akWorkshopRef, None, -1, None, abStartEnabled, abCallbackEventNeeded, sThreadID_ObjectPlaced, iBatchID)
		
		index += 1
		if(index >= PlaceMe.Length)
			index = 0
		endif
		i += 1
	endWhile
	
	return iBatchID
EndFunction


Function MonitorSimpleBatch(ObjectWatchSimple aBatch)
	if( ! QueuedSimpleBatches)
		QueuedSimpleBatches = new ObjectWatchSimple[0]
	endif
	
	int IncrementIndex = NextQueuedSimpleBatchIndex
	
	aBatch.iBatchIndex = IncrementIndex
	
	if(QueuedSimpleBatches.Length < 128)
		QueuedSimpleBatches.Add(aBatch)
	else
		QueuedSimpleBatches[IncrementIndex] = aBatch
	endif
	
	Debug.Trace("Stored simple batch monitor at index " + IncrementIndex + ": " + QueuedSimpleBatches)
EndFunction


Int Function GetSimpleBatchIndex(Int aiBatchID)
	int i = 0
	while(i < QueuedSimpleBatches.Length)
		if(QueuedSimpleBatches[i].iBatchID == aiBatchID)
			return QueuedSimpleBatches[i].iBatchIndex
		endif
		
		i += 1
	endWhile
	
	return -1
EndFunction


Function UpdateSimpleBatchMonitor(Int aiBatchIndex, Int aiAdditionalSeenObjects = 1)
	if(aiBatchIndex >= 0)
		QueuedSimpleBatches[aiBatchIndex].iSeenObjectCount += aiAdditionalSeenObjects
		
		if(QueuedSimpleBatches[aiBatchIndex].iSeenObjectCount >= QueuedSimpleBatches[aiBatchIndex].iAwaitingObjectCount)
			; Send all objects
			SimpleFetchMyObjects(aiBatchIndex)
			
			; Clear out this entry
			QueuedSimpleBatches[aiBatchIndex] = new ObjectWatchSimple
		endif
	endif
EndFunction


Function SimpleFetchMyObjects(Int aiBatchIndex)
	; Send all objects in the corresponding alias, then clear the alias
	int i = 0
	int iBatchID = QueuedSimpleBatches[aiBatchIndex].iBatchID
	int iTotal = PlacedObjects[aiBatchIndex].GetCount()
	ObjectReference[] kSendBatch = new ObjectReference[0]
	while(i < iTotal)
		ObjectReference thisObject = PlacedObjects[aiBatchIndex].GetAt(i)
		if(kSendBatch.Length == 126 && iTotal > i + 1)
			SendSimpleBatchEvent(kSendBatch, iBatchID, true)
						
			kSendBatch = new ObjectReference[0]
		endif
		
		kSendBatch.Add(thisObject)	
		
		i += 1
	endWhile
	
	if(kSendBatch.Length > 0)
		SendSimpleBatchEvent(kSendBatch, iBatchID, false)
		
		SentObjects.AddArray(kSendBatch)
	endif
	
	PlacedObjects[aiBatchIndex].RemoveAll()
EndFunction


Function SendSimpleBatchEvent(ObjectReference[] akSendRefs, Int aiBatchID, Bool abMoreEventsComing)
	Var[] kArgs = new Var[0]
	
	kArgs.Add(aiBatchID)
	kArgs.Add(abMoreEventsComing)
	
	int i = 0 
	while(i < akSendRefs.Length)
		kArgs.Add(akSendRefs[i])
		
		i += 1
	endWhile
	
	SendCustomEvent("SimpleObjectBatchCreated", kArgs)
EndFunction


Function MonitorGridItems(GridObjectWatch aGridObjectWatch)
	if( ! GridItemBatches)
		GridItemBatches = new GridObjectWatch[0]
	endif
	
	int IncrementIndex = NextQueuedGridIndex
	
	if(GridItemBatches.Length < 128)
		GridItemBatches.Add(aGridObjectWatch)
	else
		GridItemBatches[IncrementIndex] = aGridObjectWatch
	endif
EndFunction


Function UpdateGridItemBatch(Int aiBatchIndex, Int aiAdditionalSeenObjects = 1)
	if(aiBatchIndex >= 0)
		GridItemBatches[aiBatchIndex].iSeenObjectCount += aiAdditionalSeenObjects
		
		if(GridItemBatches[aiBatchIndex].iSeenObjectCount >= GridItemBatches[aiBatchIndex].iAwaitingObjectCount)
			Var[] kArgs = new Var[1]
			kArgs[0] = GridItemBatches[aiBatchIndex].iGridCallbackID
			SendCustomEvent("GridCreated", kArgs)
			
			; Clear out this entry
			GridItemBatches[aiBatchIndex] = new GridObjectWatch
		endif
	endif
EndFunction




; 1.0.5 - Added Private version so we could add additional args
Int Function CreateObject(WorldObject aPlaceMe, WorkshopScript akWorkshopRef = None, ActorValueSet aSetAV = None, Int aiFormlistIndex = -1, ObjectReference akPositionRelativeTo = None, Bool abStartEnabled = true, Bool abCallbackEventNeeded = true)
	int iThreadCallbackID = CreateObject_Private(aPlaceMe, akWorkshopRef, aSetAV, aiFormlistIndex, akPositionRelativeTo, abStartEnabled, abCallbackEventNeeded, sThreadID_ObjectCreated, aiBatchID = -1)
	
	return iThreadCallbackID
EndFunction

Int Function CreateObject_Private(WorldObject aPlaceMe, WorkshopScript akWorkshopRef = None, ActorValueSet aSetAV = None, Int aiFormlistIndex = -1, ObjectReference akPositionRelativeTo = None, Bool abStartEnabled = true, Bool abCallbackEventNeeded = true, String asCustomCallBackID = "", Int aiBatchID = -1)
	; Send creation request to the thread manager
	Form FormToPlace = GetWorldObjectForm(aPlaceMe, aiFormlistIndex)
		
	if(FormToPlace)
		String sCustomCallbackID = asCustomCallBackID
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
			
			kThread.bFadeIn = false ; 1.0.5 - Using new fade bool to ensure items pop in quickly
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
			
			; 1.0.5
			kThread.iBatchID = aiBatchID
			
			; 1.2.0 Only prevent autodestroy if used with the batch system
			if(sCustomCallbackID == sThreadID_ObjectPlaced && abCallbackEventNeeded)
				kThread.bAutoDestroy = false
			endif
			
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
			
			kThread.bFadeIn = false ; 1.0.5 - Using new fade bool to ensure items pop in quickly
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
			kThread.kPositionRelativeTo = akPositionRelativeTo ; 1.1.11 - This had been missing
			kThread.RunCode()
			
			ObjectReference kCreatedRef = kThread.kResult
			
			;ModTrace("CreateObjectImmediately thread " + kThread + " returned result " + kCreatedRef + ", it had been fed: FormToPlace = " + FormToPlace + " and aPlaceMe = " + aPlaceMe)
			if( ! kThread.bAwaitingOnLoadEvent)
				kThread.SelfDestruct()
			endif
			
			return kCreatedRef
		endif
	endif
		
	return None
EndFunction


Int Function CreateObjectGrid(ObjectReference akCenterPointRef, Form aObjectToPlace, GridSettings aGridSettings, ObjectReference akLinkToRef = None, Keyword aLinkKeyword = None, Bool abStartDisabled = false)
	if( ! akCenterPointRef || (((aGridSettings.iMaxObjectsPerAxisX <= 0 && aGridSettings.fMaxXDistance <= 0) || (aGridSettings.iMaxObjectsPerAxisY <= 0 && aGridSettings.fMaxYDistance <= 0) || (aGridSettings.iMaxObjectsPerAxisZ <= 0 && aGridSettings.fMaxZDistance <= 0)) && ! aGridSettings.bGridWorkshopCellsOnly))
        ; We're either missing the starting ref, or one of the dimensions is set to go infinite
        return -1
    endif

	Workshopscript kWorkshopRef
    if(aGridSettings.bGridWorkshopCellsOnly)
        if(akCenterPointRef as WorkshopScript)
            kWorkshopRef = akCenterPointRef as WorkshopScript
        else
            kWorkshopRef = WorkshopParent.GetWorkshopFromLocation(akCenterPointRef.GetCurrentLocation())
        endif
        
        if( ! kWorkshopRef)
            return -1
        endif
    endif
    
	if(LinkedGridKeywords == None)
		LinkedGridKeywords = new Keyword[0]
	endif
	
	if(aGridSettings.bLinkAsWorkshopItems)
		if(LinkedGridKeywords.Find(WorkshopItemKeyword) < 0)
			LinkedGridKeywords.Add(WorkshopItemKeyword)
		endif
    endif
	
	if(aLinkKeyword != None)
		if(LinkedGridKeywords.Find(aLinkKeyword) < 0)
			LinkedGridKeywords.Add(aLinkKeyword)
		endif
	endif
	
    if(aGridSettings.bHideUntilCellUnloads)
        abStartDisabled = true
    endif
	
	WorldObject centerSpawnWorldObject = new WorldObject
	centerSpawnWorldObject.ObjectForm = aObjectToPlace
	centerSpawnWorldObject.fPosX = akCenterPointRef.X + aGridSettings.fInitialXOffset
	centerSpawnWorldObject.fPosY = akCenterPointRef.Y + aGridSettings.fInitialYOffset
	centerSpawnWorldObject.fPosZ = akCenterPointRef.Z + aGridSettings.fInitialZOffset
	centerSpawnWorldObject.fAngleX = 0.0
	centerSpawnWorldObject.fAngleY = 0.0
	centerSpawnWorldObject.fAngleZ = akCenterPointRef.GetAngleZ()
	
    if(aGridSettings.bRandomizeZRotation)
        centerSpawnWorldObject.fAngleZ = Utility.RandomFloat(0.0, 359.0)
    Endif
	
	ObjectReference CenterSpawn = CreateObjectImmediately(centerSpawnWorldObject, kWorkshopRef, abStartEnabled = abStartDisabled)
	
	if(CenterSpawn)
		int iActualThreadsCreated = 0
		int iGridCallbackID = NextQueuedBatchID ; we can just piggy-back on the batch ID system
		
		GridObjectWatch thisGridWatch = new GridObjectWatch
		thisGridWatch.iAwaitingObjectCount = iDummyCallbackCount ; Arbitrarily high number we can subtract after all have been actually sent
		thisGridWatch.iGridCallbackID = iGridCallbackID
		thisGridWatch.iSeenObjectCount = 0
		thisGridWatch.bAlignToGround = aGridSettings.bAlignToGround
		thisGridWatch.bHideUntilCellUnloads = aGridSettings.bHideUntilCellUnloads
		
		MonitorGridItems(thisGridWatch)
	
		if(akLinkToRef != None)
			CenterSpawn.SetLinkedRef(akLinkToRef, aLinkKeyword)
			
			if(aGridSettings.bLinkAsWorkshopItems && kWorkshopRef != None)
				CenterSpawn.SetLinkedRef(kWorkshopRef, WorkshopItemKeyword)
			endif
		endif
		
		if(aGridSettings.bAlignToGround && aGridSettings.bPreventOverlapWhenAligningToGround)
			akCenterPointRef.AddKeyword(PreventOverlapKeyword) ; Prevent any axis objects from intersecting with our center point
			
			if(akCenterPointRef == kWorkshopRef)
				CenterSpawn.Disable(false) ; This will be intersecting with our workshop
			endif
		endif
	
		iActualThreadsCreated += CreateAxisObjects(CenterSpawn, aObjectToPlace, "X", aGridSettings, akLinkToRef, aLinkKeyword, abStartDisabled, false, iGridCallbackID)
		iActualThreadsCreated += CreateAxisObjects(CenterSpawn, aObjectToPlace, "Y", aGridSettings, akLinkToRef, aLinkKeyword, abStartDisabled, false, iGridCallbackID)
		iActualThreadsCreated += CreateAxisObjects(CenterSpawn, aObjectToPlace, "Z", aGridSettings, akLinkToRef, aLinkKeyword, abStartDisabled, false, iGridCallbackID)
		
		if(aGridSettings.bAlignToGround)
            MoveToNavMesh(CenterSpawn)
        endif
		
		; Update our actual expected callback count
		int iGridWatchIndex = GridItemBatches.FindStruct("iGridCallbackID", iGridCallbackID)
		if(iGridWatchIndex >= 0)
			GridItemBatches[iGridWatchIndex].iAwaitingObjectCount = iActualThreadsCreated
			
			; Check to see if this finished before we even got here
			UpdateGridItemBatch(iGridWatchIndex, aiAdditionalSeenObjects = 0)
		endif
		
		return iGridCallbackID
	endif
	
	return -1
EndFunction


Int Function CreateAxisObjects(ObjectReference akCenterPointRef, Form aObjectToPlace, String asAxis, GridSettings aGridSettings, ObjectReference akLinkToRef = None, Keyword aLinkKeyword = None, Bool abStartDisabled = false, Bool abDeleteCenterPointRefAtEnd = false, Int aiGridCallbackID = -1)
	if( ! akCenterPointRef)
        return 0
    endif
    
    if(aGridSettings.bHideUntilCellUnloads)
        abStartDisabled = true
    endif
    
    Workshopscript kWorkshopRef
    if(aGridSettings.bGridWorkshopCellsOnly)
        if(akCenterPointRef as WorkshopScript)
            kWorkshopRef = akCenterPointRef as WorkshopScript
        else
            kWorkshopRef = WorkshopParent.GetWorkshopFromLocation(akCenterPointRef.GetCurrentLocation())
        endif
        
        if( ! kWorkshopRef)
            return 0
        endif
    endif
    
    Bool bPositive = false
    Bool bNegative = false
    Int iMaxCount = 0
    Float fMaxDistance = 0.0
       
    Float StartX = akCenterPointRef.GetPositionX()
    Float StartY = akCenterPointRef.GetPositionY()
    Float StartZ = akCenterPointRef.GetPositionZ()
    
    Float AngleX = akCenterPointRef.GetAngleX()
    Float AngleY = akCenterPointRef.GetAngleY()
    Float AngleZ = akCenterPointRef.GetAngleZ()
    
    Float FirstX = StartX
    Float FirstY = StartY
    Float FirstZ = StartZ
    
    Float NextX = StartX
    Float NextY = StartY
    Float NextZ = StartZ
    
    Float fDistance = 0
    Float fPrevDistance = -1
	
	if(asAxis == "X")
        bPositive = aGridSettings.bGridPositiveX
        bNegative = aGridSettings.bGridNegativeX
        iMaxCount = aGridSettings.iMaxObjectsPerAxisX
        fMaxDistance = aGridSettings.fMaxXDistance
    elseif(asAxis == "Y")
        bPositive = aGridSettings.bGridPositiveY
        bNegative = aGridSettings.bGridNegativeY
        iMaxCount = aGridSettings.iMaxObjectsPerAxisY
        fMaxDistance = aGridSettings.fMaxYDistance
    elseif(asAxis == "Z")
        bPositive = aGridSettings.bGridPositiveZ
        bNegative = aGridSettings.bGridNegativeZ
        iMaxCount = aGridSettings.iMaxObjectsPerAxisZ
        fMaxDistance = aGridSettings.fMaxZDistance
    endif
  
	; ---------------------
	; Create all objects along axis recursively
	; ---------------------
	ObjectReference kPositionHelper = PlayerRef.PlaceAtMe(PositionHelper)
	Int iThreadsCreated = 0
	
	; Setup 1/-1 multipliers so we can use the same code loop for going positive and negative directions
	int[] iDirections = new int[0]
    if(bPositive)
		iDirections.Add(1)
	endif
	
	if(bNegative)
		iDirections.Add(-1)
	endif
	
	if(iDirections.Length > 0)
		int i = 0
		while(i < iDirections.Length)
			Int iCreated = 0
			Int iCreatedOverBoundary = 0
			Bool bStopLoop = false
			; Reset Vars to beginning for this direction
			FirstX = StartX
			FirstY = StartY
			FirstZ = StartZ

			NextX = StartX
			NextY = StartY
			NextZ = StartZ
			
			fDistance = 0
			fPrevDistance = -1
			
			while( ! bStopLoop)
				Float fXRandom = 0.0
				if(aGridSettings.fXRandomization != 0.0)
					if(aGridSettings.fXRandomization > 0)
						fXRandom = Utility.RandomInt((aGridSettings.fXRandomization * -1) as Int, (aGridSettings.fXRandomization) as Int) as Float
					else
						fXRandom = Utility.RandomInt((aGridSettings.fXRandomization) as Int, (aGridSettings.fXRandomization * -1) as Int) as Float
					endif
				endif
				
				Float fYRandom = 0.0
				if(aGridSettings.fYRandomization != 0.0)
					if(aGridSettings.fYRandomization > 0)
						fYRandom = Utility.RandomInt((aGridSettings.fYRandomization * -1) as Int, (aGridSettings.fYRandomization) as Int) as Float
					else
						fYRandom = Utility.RandomInt((aGridSettings.fYRandomization) as Int, (aGridSettings.fYRandomization * -1) as Int) as Float
					endif
				endif
				
				Float fZRandom = 0.0
				if(aGridSettings.fZRandomization != 0.0)
					if(aGridSettings.fZRandomization > 0)
						fZRandom = Utility.RandomInt((aGridSettings.fZRandomization * -1) as Int, (aGridSettings.fZRandomization) as Int) as Float
					else
						fZRandom = Utility.RandomInt((aGridSettings.fZRandomization) as Int, (aGridSettings.fZRandomization * -1) as Int) as Float
					endif
				endif
					
				if(asAxis == "X")
					NextX += aGridSettings.fXSpacing * iDirections[i]
					
					fDistance = Math.abs(FirstX + (NextX * -1)) + fXRandom
					
					if(NextX == StartX)
						bStopLoop = true
					endif
				elseif(asAxis == "Y")
					NextY += aGridSettings.fYSpacing * iDirections[i]
					
					fDistance = Math.abs(FirstY + (NextY * -1)) + fYRandom
					
					if(NextY == StartY)
						bStopLoop = true
					endif
				else
					NextZ += aGridSettings.fZSpacing * iDirections[i]
									
					fDistance = Math.abs(FirstZ + (NextZ * -1)) + fZRandom
					
					if(NextZ == StartZ)
						bStopLoop = true
					endif
				endif
				
				if(fPrevDistance == fDistance) 
					; This would only happen if we attempted to use the same location multiple times - basically using this to prevent an infinite loop
					bStopLoop = true
				endif
				
				if( ! bStopLoop)
					fPrevDistance = fDistance ; Store this for next loop - if distance is being used we don't want to risk getting stuck in an infinite loop
					
					; Move our helper into place to determine if we should bother spawning
					kPositionHelper.SetPosition(NextX, NextY, NextZ)
					
					iCreated += 1				
					
					if(iCreated >= iMaxCount && iMaxCount > 0)
						bStopLoop = true
					elseif((aGridSettings.bGridWorkshopCellsOnly && ( ! kPositionHelper.IsWithinBuildableArea(kWorkshopRef) || (fMaxDistance > 0 && fDistance > fMaxDistance))) || ( ! aGridSettings.bGridWorkshopCellsOnly && fDistance > fMaxDistance))
						iCreatedOverBoundary += 1
						
						if(iCreatedOverBoundary > aGridSettings.iBoundaryOverlapCount)
							; This object would be past the boundary, so don't create it
							bStopLoop = true
						endif
					endif
					
					
					if( ! bStopLoop)
						; Note: Use kPositionHelper to generate temporary center points
						if(aGridSettings.bRandomizeZRotation)
							AngleZ = Utility.RandomFloat(0.0, 359.0)
						Endif
			
						; Thread grid object creation
						int iThreadCallbackID = CreateGridObject(akCenterPointRef, aObjectToPlace, NextX, NextY, NextZ, AngleX, AngleY, AngleZ, abStartDisabled, aGridSettings, akLinkToRef, aLinkKeyword, kWorkshopRef, aiGridCallbackID = aiGridCallbackID)

						if(iThreadCallbackID > -1)
							iThreadsCreated += 1
						endif
						
						; Trigger axis objects from this position
						if(asAxis == "X")
							ObjectReference kNewCenter = kPositionHelper.PlaceAtMe(PositionHelper)
							
							iThreadsCreated += CreateAxisObjects(kNewCenter, aObjectToPlace, "Y", aGridSettings, akLinkToRef, aLinkKeyword, abStartDisabled, abDeleteCenterPointRefAtEnd = true, aiGridCallbackID = aiGridCallbackID)
							
							iThreadsCreated += CreateAxisObjects(kNewCenter, aObjectToPlace, "Z", aGridSettings, akLinkToRef, aLinkKeyword, abStartDisabled, abDeleteCenterPointRefAtEnd = true, aiGridCallbackID = aiGridCallbackID)
						elseif(asAxis == "Y")
							ObjectReference kNewCenter = kPositionHelper.PlaceAtMe(PositionHelper)
							
							iThreadsCreated += CreateAxisObjects(kNewCenter, aObjectToPlace, "Z", aGridSettings, akLinkToRef, aLinkKeyword, abStartDisabled, abDeleteCenterPointRefAtEnd = true, aiGridCallbackID = aiGridCallbackID)
						endif 
					endif
				endif
			endWhile
			
			i += 1
		endWhile
    endif

	if(abDeleteCenterPointRefAtEnd)
		if(akCenterPointRef.GetBaseObject() == PositionHelper)
			akCenterPointRef.Disable(false)
			kPositionHelper.Delete()
		else
			ScrapObject(akCenterPointRef)
		endif
	endif
	
	kPositionHelper.Disable(false)
	kPositionHelper.Delete()
	
	return iThreadsCreated
EndFunction


Int Function CreateGridObject(ObjectReference akSpawnAt, Form aObjectToPlace, Float afPosX, Float afPosY, Float afPosZ, Float afAngleX, Float afAngleY, Float afAngleZ, Bool abStartDisabled, GridSettings aGridSettings, ObjectReference akLinkToRef = None, Keyword aLinkKeyword = None, WorkshopScript akWorkshopRef = None, Int aiGridCallbackID = -1)
	; Send creation request to the thread manager
	WorkshopFramework:ObjectRefs:Thread_PlaceObject kThread = ThreadManager.CreateThread(PlaceObjectThread) as WorkshopFramework:ObjectRefs:Thread_PlaceObject
	
	if(kThread)
		if(aGridSettings.bAlignToGround && aGridSettings.bPreventOverlapWhenAligningToGround)
			kThread.AddTagKeyword(PreventOverlapKeyword)
		endif
		
		if(akLinkToRef != None)
			kThread.AddLinkedRef(akLinkToRef, aLinkKeyword)
		endif
		
		if(aGridSettings.bLinkAsWorkshopItems)
			kThread.bForceWorkshopItemLink = true
		else
			kThread.bForceWorkshopItemLink = false
		endif
				
		kThread.bFadeIn = false
		kThread.bStartEnabled = (abStartDisabled == false)
		kThread.kSpawnAt = akSpawnAt
		kThread.SpawnMe = aObjectToPlace
		kThread.fPosX = afPosX
		kThread.fPosY = afPosY
		kThread.fPosZ = afPosZ
		kThread.fAngleX = afAngleX
		kThread.fAngleY = afAngleY
		kThread.fAngleZ = afAngleZ
		if(aGridSettings.fScale > 0)
			kThread.fScale = aGridSettings.fScale
		endif
		kThread.kWorkshopRef = akWorkshopRef
		kThread.iBatchID = aiGridCallbackID
		kThread.bAutoDestroy = false
		
		int iCallBackID = ThreadManager.QueueThread(kThread, sThreadID_GridObjectPlaced)
		
		return iCallBackID
	endif
	
	return -1
EndFunction



Function MoveToNavMesh(ObjectReference akObjectRef)
    Cell thisCell = akObjectRef.GetParentCell()
    if( ! thisCell || ! thisCell.IsLoaded())
        akObjectRef.AddKeyword(MoveToNavmeshKeyword)        
        return
    endif
    
	akObjectRef.RemoveKeyword(MoveToNavmeshKeyword)
    akObjectRef.MoveToNearestNavmeshLocation()
    
    if(akObjectRef.HasKeyword(PreventOverlapKeyword))
        ObjectReference[] nearbyItems = akObjectRef.FindAllReferencesWithKeyword(PreventOverlapKeyword, akObjectRef.GetWidth() * 2)
        if(nearbyItems.Length > 1)
            int i = 0
            while(i < LinkedGridKeywords.Length)
                akObjectRef.SetLinkedRef(None, LinkedGridKeywords[i])
                i += 1
            endWhile
            
			ScrapObject(akObjectRef, abCallbackEventNeeded = false)
            
            return
        endif
    endif
    
    if(akObjectRef.IsEnabled())
        ; Prevent flickering
        akObjectRef.Disable(false)
        akObjectRef.Enable(false)
    endif
EndFunction



Int Function ScrapObject(ObjectReference akScrapMe, Bool abCallbackEventNeeded = true)
	; Send deletion request to the thread manager
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


Int Function ScrapObjectInWorkshopArea(ObjectReference akScrapMe, WorkshopScript akWorkshopRef, Bool abCallbackEventNeeded = true)
	; Send deletion request to the thread manager
	String sCustomCallbackID = sThreadID_ObjectRemoved
	if( ! abCallbackEventNeeded)
		sCustomCallbackID = ""
	else
		ModTrace("[WSFW] PlaceObjectManager: Creating ScrapObjectInWorkshopArea thread - requesting callback event.")
	endif
		
	WorkshopFramework:ObjectRefs:Thread_ScrapObject kThread = ThreadManager.CreateThread(ScrapObjectThread) as WorkshopFramework:ObjectRefs:Thread_ScrapObject
	
	if(kThread)
		kThread.kScrapMe = akScrapMe
		kThread.bWithinBuildableAreaCheck = true
		kThread.kWorkshopRef = akWorkshopRef
		
		int iCallBackID = ThreadManager.QueueThread(kThread, sCustomCallbackID)
		
		return iCallBackID
	endif	
		
	return -1
EndFunction


Function UpdateObjects(WorkshopScript akWorkshopRef)
    ObjectReference[] UpdateMe = akWorkshopRef.GetLinkedRefChildren(WorkshopItemKeyword)
    
	if(UpdateMe.Length)
        int i = 0
        
        while(i < UpdateMe.Length)
            if(UpdateMe[i].HasKeyword(MoveToNavmeshKeyword) && UpdateMe[i].Is3dLoaded())
                MoveToNavMesh(UpdateMe[i])           
            endif
            
            i += 1
        endWhile
    endif
EndFunction



; ==================================================================================
; ==================================================================================
; 1.0.5 - Everything below here is obsolete, maintaining for backwards compatibility
; ==================================================================================
; ==================================================================================

String sThreadID_ObjectCreated = "ObjectCreated"

Struct ObjectWatch
	int iAwaitingObjectCount = 0
	ActorValue WithAV
	Float WithAVValue
	int iSeenObjectCount = 0
EndStruct


ObjectWatch[] QueuedBatches


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
		
		; 1.0.5 - Updating to new version that handles specifying a batch ID and callback string
		int iThreadCallbackID = CreateObject_Private(newObject, akWorkshopRef, aSetAV, -1, None, abStartEnabled, abCallbackEventNeeded, sThreadID_ObjectCreated, iBatchID)
		
		index += 1
		if(index >= PlaceMe.Length)
			index = 0
		endif
		i += 1
	endWhile
	
	return iBatchID
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
		
		; TODO: Testing each item for an AV is likely slowing this code down - would probably be faster to instead setup a number of RefCollectionAliases = to the max batch count and just store the items in the appropriate ref collection - then just send all of those items to the requestor. We can then repurpose the alias used by FetchMyObjects to handle individual object creation calls.
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