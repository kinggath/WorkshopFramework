; ---------------------------------------------
; WorkshopFramework:MainQuest.psc - by kinggath
; ---------------------------------------------
; Reusage Rights ------------------------------
; You are free to use this script or portions of it in your own mods, provided you give me credit in your description and maintain this section of comments in any released source code (which includes the IMPORTED SCRIPT CREDIT section to give credit to anyone in the associated Import scripts below.
; 
; IMPORTED SCRIPT CREDIT
; N/A
; ---------------------------------------------

Scriptname WorkshopFramework:MainQuest extends WorkshopFramework:Library:MasterQuest

; ---------------------------------------------
; Consts
; ---------------------------------------------


; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------

Group Keywords
	Keyword Property LocationTypeSettlement Auto Const
EndGroup

Group Assets
	Form Property TestSpawnForm Auto Const
EndGroup

; ---------------------------------------------
; Properties
; ---------------------------------------------

; ---------------------------------------------
; Vars
; ---------------------------------------------

WorkshopFramework:Library:ObjectRefs:ArrayLargeInt1024 LargeArray_AwaitingSpawnThreads

; ---------------------------------------------
; Events 
; ---------------------------------------------
int iReceivedEvents = 0
int iExpectedEvents = 0
Event WorkshopFramework:Library:ThreadRunner.OnThreadCompleted(WorkshopFramework:Library:ThreadRunner akThreadRunner, Var[] akargs)

	; akargs[0] = sCustomCallCallbackID, akargs[1] = iCallbackID, akargs[2] = ThreadRunFunction, akargs[3] = Result from called function
	String sCustomCallCallbackID = akargs[0] as String
	if(sCustomCallCallbackID == "AwaitingObjectSpawn")
		iReceivedEvents += 1
		Debug.Trace("Received spawn ref for CallbackID: " + (akargs[1] as Int) + akargs[3] as ObjectReference)
		
		if(iReceivedEvents >= iExpectedEvents)
			Debug.MessageBox("Events completed")
		endif
	endif
EndEvent


Function Test()
	ObjectReference[] kAll = PlayerRef.GetLinkedRefChildren(LocationTypeSettlement)
		
	Debug.MessageBox("Player has " + kAll.Length + " objects linked")
EndFunction

; ---------------------------------------------
; Extended Handlers
; ---------------------------------------------

Function HandleGameLoaded()
	; Make sure our debug log is open
	WorkshopFramework:Library:UtilityFunctions.StartUserLog()
	
	Parent.HandleGameLoaded()
EndFunction


Function HandleQuestInit()
	Parent.HandleQuestInit()
	
	; Register for events
	ThreadManager.RegisterForCallbackThreads(Self)
EndFunction

; ---------------------------------------------
; Overrides
; ---------------------------------------------

; Override parent function - to check for same location on the settlement type
Function HandleLocationChange(Location akNewLoc)
	if( ! akNewLoc)
		return
	endif
	
	Location lastParentLocation = LatestLocation.GetLocation()
	
	if( ! akNewLoc.IsSameLocation(lastParentLocation) ||  ! akNewLoc.IsSameLocation(lastParentLocation, LocationTypeSettlement))
		LatestLocation.ForceLocationTo(akNewLoc)
		StartTimer(fLocationChangeDelay, LocationChangeTimerID)	
	endif
EndFunction


; ---------------------------------------------
; Test Functions
; ---------------------------------------------

; PROBLEMS
; - Using the LargeArray to track callbackIDs is slow - not likely something we can do for tons of operations like this
; 		Though - still need to get it working so that no callbackIDs are lost
; CallGlobalFunction is very slow, about 1/10th the speed of having the function on the ThreadRunner
; 	Likely need to rethink this solution
;		Goal: Limit the number of operations running at any given time, but encourage running parallel threads
;		Potential Options: 
;			- Include common operations as threadRunner functions
;			- Allow threadrunner to run CallFunctionNoWait on a thread pool that is registered to it
Function TestThreadManager(Bool abGlobal = false, Int aiMaxThreads = 0)
	if(aiMaxThreads > 0)
		ThreadManager.OverrideMaxThreads(aiMaxThreads)
	endif
	
	int i = 0
	int iMax = 2000
	
	iReceivedEvents = 0
	iExpectedEvents = iMax
	
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
			iCallbackID = ThreadManager.QueueGlobalThread("AwaitingObjectSpawn", "WorkshopFramework:Library:UtilityFunctions", "SpawnTestObject", kArgs)
			Debug.Trace("QueuedGlobalThread, callbackID: " + iCallbackID)
			
			i += 1
		endWhile
	else
		Debug.MessageBox("Using Predefined function on ThreadRunner method...")
		while(i < iMax)		
			ThreadManager.SimpleCallTest(kArgs)
			
			i += 1
		endWhile
	endif
	
	Float fEnded = Utility.GetCurrentRealTime()
	Debug.MessageBox("Finished test, took " + (fEnded - fStarted) + " seconds.")
EndFunction

Function TestGlobalFunctions()
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
	
	Float fStarted = Utility.GetCurrentRealTime()
	
	while(i < iMax)		
		Utility.CallGlobalFunction("WorkshopFramework:Library:UtilityFunctions", "SpawnTestObject", kArgs)
			
		i += 1
	endWhile
	
	Float fEnded = Utility.GetCurrentRealTime()
	Debug.MessageBox("Finished test, took " + (fEnded - fStarted) + " seconds.")
EndFunction