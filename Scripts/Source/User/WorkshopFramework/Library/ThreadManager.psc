; ---------------------------------------------
; WorkshopFramework:Library:ThreadManager.psc - by kinggath, concept by E
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

Scriptname WorkshopFramework:Library:ThreadManager extends WorkshopFramework:Library:SlaveQuest Conditional

; ---------------------------------------------
; Consts 
; ---------------------------------------------

Float NULLARGUMENT = -1522753.0 Const ; Arbitrary number that's unlikely to ever actually be used - this will represent NULL for us
int MAXCALLBACKID = 1000000 Const ; Some large value. We just want to make sure that we never overwrite an earlier callback and that we never go out of bounds for an int. This will be checked on game load and if callback ID is larger than this, it will reset to 0
int QUEUEFAIL = -1 Const ; Return result if we couldn't generate a CallbackID, such as if required data was missing from the QueueThread call
Int NOTREADY = -2 Const ; Return result if threadmanager is accessed before init is finished

; Number of arguments prefixed to arguments sent to QueueThread
int ARGCOUNT_Global = 3 Const 
int ARGCOUNT_Remote = 4 Const 

int OVERLOADTHRESHOLD = 20 Const ; If a thread exceeds this number of queued actions, the edit lock will be cleared to prevent the threading from overloading the VM and causing stack dumps 

; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------
Group Controllers
	WorkshopFramework:Library:ThreadRunner[] Property ThreadRunners Auto Const
	GlobalVariable[] Property gThreadRunnerQueueCounts Auto Const
	ReferenceAlias Property ThreadSpawnPointAlias Auto Const Mandatory	
EndGroup


; ---------------------------------------------
; Properties
; ---------------------------------------------

Int Property iMaxThreads = 50 Auto Hidden Conditional
bool Property bOverride = false Auto Hidden Conditional


Int Property iNextRunner = -1 Auto Hidden
Int Property NextRunner
	Int Function Get()
		iNextRunner += 1
		
		if(iNextRunner >= iMaxThreads)
			iNextRunner = 0
		endif
		
		return iNextRunner
	EndFunction
EndProperty

int iNextCallbackID = 0
Int Property NextCallbackID
	Int Function Get()
		iNextCallbackID += 1
		
		return iNextCallbackID
	EndFunction
EndProperty


 
; ---------------------------------------------
; Variables 
; ---------------------------------------------


bool bLockThreadRunners = false


; ---------------------------------------------
; States 
; ---------------------------------------------

Auto State NotInitialized
	Int Function QueueStoredArgumentThread(String asThreadRunnerFunction, Var[] akArgs, Bool abGlobalCall = false)
		return NOTREADY
	EndFunction
	
	Int Function QueueThread(WorkshopFramework:Library:ObjectRefs:Thread akThreadRef, String asMyCallbackID = "")
		return NOTREADY
	EndFunction
EndState


; ---------------------------------------------
; Events 
; ---------------------------------------------


; ---------------------------------------------
; Event Handler Functions 
; ---------------------------------------------


Function HandleQuestInit()	
	Parent.HandleQuestInit()
	
	GoToState("")
EndFunction


Function HandleGameLoaded()	
	if(iNextCallbackID > MAXCALLBACKID)
		; Make sure we never go out of bounds
		iNextCallbackID = 0
	endif
	
	; v2.4.9 - add code to make sure our count globals stay in sync, call before CheckForOvertaxing.
	ResetQueueCounters()
	CalculateAvailableThreads()
	CheckForOvertaxing()
	
	; Handle parent changes such as running install code
	Parent.HandleGameLoaded()
EndFunction


; ---------------------------------------------
; Functions 
; ---------------------------------------------


Function CalculateAvailableThreads()
	; Determine how many threads this should allow itself
	if( ! bOverride)
		iMaxThreads = ThreadRunners.Length 
	endif
EndFunction


Function CheckForOvertaxing()
	int i = 1
	
	while(i < ThreadRunners.Length)
		WorkshopFramework:Library:ThreadRunner thisRunner = ThreadRunners[i]
		
		if(thisRunner != None && gThreadRunnerQueueCounts[i].GetValueInt() > OVERLOADTHRESHOLD)
			thisRunner.ForceClearLock()
		endif
		
		i += 1
	endWhile
EndFunction


Function OverrideMaxThreads(Int aiOverride)
	if(aiOverride <= 0)
		bOverride = false
		CalculateAvailableThreads()
	else
		bOverride = true
		iMaxThreads = aiOverride
	endif
EndFunction


Function RegisterForCallbackThreads(Form akRequestor)
	if(akRequestor)
		int i = 0
	
		while(i < ThreadRunners.Length)
			WorkshopFramework:Library:ThreadRunner thisRunner = ThreadRunners[i]
			
			if(thisRunner != None)
				akRequestor.RegisterForCustomEvent(thisRunner, "OnThreadCompleted")
			endif
			
			i += 1
		endWhile
	endif
EndFunction


Function UnregisterForCallbackThreads(Form akRequestor)
	if(akRequestor)
		int i = 0
	
		while(i < ThreadRunners.Length)
			WorkshopFramework:Library:ThreadRunner thisRunner = ThreadRunners[i]
			
			if(thisRunner != None)
				akRequestor.UnregisterForCustomEvent(thisRunner, "OnThreadCompleted")
			endif
			
			i += 1
		endWhile
	endif
EndFunction


Int Function QueueRemoteFunctionThread(String asMyCallbackID, Form aCallingForm, String asCastAs, String asFunction, Var[] akArgs)
	if( ! aCallingForm)
		return QUEUEFAIL
	endif
	
	int inewArgsCounter = ARGCOUNT_Remote
	Var[] newArgs = new Var[(inewArgsCounter + akArgs.Length)]
	
	newArgs[0] = asMyCallbackID
	newArgs[1] = aCallingForm
	newArgs[2] = asCastAs
	newArgs[3] = asFunction
	
	int iakArgCounter = 0
	 ; Make sure this is the next index after manually fed arguments above
	while(iakArgCounter < akArgs.Length)
		newArgs[inewArgsCounter] = akArgs[iakArgCounter]
		
		iakArgCounter += 1
		inewArgsCounter += 1
	endWhile
	
	return QueueStoredArgumentThread("RunRemoteFunctionThread", newArgs)
EndFunction


Int Function QueueGlobalThread(String asMyCallbackID, String asScriptName, String asFunctionName, Var[] akArgs)
	int iNewArgIndex = ARGCOUNT_Global
	Var[] newArgs = new Var[(akArgs.Length + iNewArgIndex)]
	newArgs[0] = asMyCallbackID
	newArgs[1] = asScriptName
	newArgs[2] = asFunctionName
	
	int iakArgIndex = 0
	
	while(iakArgIndex < akArgs.Length)
		newArgs[iNewArgIndex] = akArgs[iakArgIndex]
		
		iNewArgIndex += 1
		iakArgIndex += 1
	endWhile
	
	return QueueStoredArgumentThread("RunGlobalFunctionThread", newArgs, true)
EndFunction


Int Function QueueStoredArgumentThread(String asThreadRunnerFunction, Var[] akArgs, Bool abGlobalCall = false)
	Self.WaitWhileLocked()
	int iRunnerIndex = GetNextThreadRunner()
	
	if(iRunnerIndex < 0)
		return QUEUEFAIL
	endif
	
	WorkshopFramework:Library:ThreadRunner thisRunner = ThreadRunners[iRunnerIndex]
	
	Var[] newArgs
	int iCallbackID = NextCallbackID	
	int iakArgIndex = 0
	int iPrefixedVars = ARGCOUNT_Remote
	if(abGlobalCall)
		iPrefixedVars = ARGCOUNT_Global
	endif
	
	Int iStoredArgumentsIndex
	
	if(akArgs.Length > iPrefixedVars)
		; Store the sent vars
		Var[] StoreVars = new Var[0]
		
		iakArgIndex = iPrefixedVars ; Skip the prefixed vars
		while(iakArgIndex < akArgs.Length)
			StoreVars.Add(akArgs[iakArgIndex])
			
			iakArgIndex += 1
		endWhile
		
		if(StoreVars.Length > 0)
			iStoredArgumentsIndex = thisRunner.NextStoredArgumentIndex
			
			thisRunner.StoreArguments(iStoredArgumentsIndex, StoreVars)
		else
			;Debug.Trace("No StoreVars found from akArgs: " + akArgs)
			iStoredArgumentsIndex = -1 ; No args to store
		endif
	else
		iStoredArgumentsIndex = -1 ; No arguments to store
	endif		
	
	; Prep vars to send to threadrunner
	newArgs = new Var[(iPrefixedVars + 2)]
	
	newArgs[0] = iCallbackID	
	newArgs[1] = akArgs[0]
	
	if(abGlobalCall)
		newArgs[2] = akArgs[1] ; Script name
		newArgs[3] = akArgs[2] ; function name
	else
		newArgs[2] = akArgs[1] ; Object
		newArgs[3] = akArgs[2] ; CastAs
		newArgs[4] = akArgs[3] ; Function
	endif
	
		; Append StoredArgumentsIndex
	newArgs[(newArgs.Length - 1)] = iStoredArgumentsIndex
	
	thisRunner.CallFunctionNoWait(asThreadRunnerFunction, newArgs)
	
	return iCallbackID
EndFunction


Int Function QueueThread(WorkshopFramework:Library:ObjectRefs:Thread akThreadRef, String asMyCallbackID = "")
	Self.WaitWhileLocked()
	int iRunnerIndex = GetNextThreadRunner()
	
	if(iRunnerIndex < 0)
		return QUEUEFAIL
	endif
	
	int iCallbackID = NextCallbackID
	
	akThreadRef.iCallbackID = iCallbackID
	akThreadRef.sCustomCallbackID = asMyCallbackID
	
	Var[] kArgs = new Var[1]
	kArgs[0] = akThreadRef
	
	WorkshopFramework:Library:ThreadRunner thisRunner = ThreadRunners[iRunnerIndex]
	
	thisRunner.CallFunctionNoWait("HandleNewThread", kArgs)
	
	return iCallbackID
EndFunction


WorkshopFramework:Library:ThreadRunner Function GetThreadRunner()
	int iRunnerIndex = GetNextThreadRunner()
	
	WorkshopFramework:Library:ThreadRunner thisRunner = ThreadRunners[iRunnerIndex]
	
	return thisRunner
EndFunction


WorkshopFramework:Library:ObjectRefs:Thread Function CreateThread(Form aThread)
	ObjectReference kSpawnPoint = ThreadSpawnPointAlias.GetRef()
	
	WorkshopFramework:Library:ObjectRefs:Thread kTemp = kSpawnPoint.PlaceAtMe(aThread, abInitiallyDisabled = true) as WorkshopFramework:Library:ObjectRefs:Thread
	
	return kTemp
EndFunction


Int Function GetNextThreadRunner()
	int iRunnerIndex = NextRunner	
	
	if(iRunnerIndex >= 0)		
		gThreadRunnerQueueCounts[iRunnerIndex].Mod(1)
		
		return iRunnerIndex
	else
		return QUEUEFAIL
	endif
EndFunction


Function WaitWhileLocked()
; simple spin lock to prevent new threads starting while locked.
; called by QueueStoredArgumentThread and QueueThread.
	int iCount = 100	; prevent infinite loop.
	while ( bLockThreadRunners && iCount > 0 )
		iCount -= 1
		Utility.Wait(2.0)	; we shouldn't need to wait to long here...
	endWhile
EndFunction


Function ResetQueueCounters()
{ set each ThreadRunner.QueueCounter global to the count of refs in ThreadRunner.QueuedThreads RefCollectionAlias }
	; an alternative to a spin lock would be to lock each ThreadRunner before updating.
	bLockThreadRunners = true
	int i = ThreadRunners.Length
	int iCount
	GlobalVariable thisQueueCounter
	RefCollectionAlias thisColl
	
	while ( i > 0 )
		i -= 1
		
		thisQueueCounter = ThreadRunners[i].QueueCounter
		thisColl = ThreadRunners[i].QueuedThreads
		; safety check.
		if ( thisQueueCounter != none && thisColl != none )
			iCount = thisColl.GetCount()
			thisQueueCounter.SetValueInt(iCount)
		endif
	endWhile
	
	bLockThreadRunners = false
EndFunction
