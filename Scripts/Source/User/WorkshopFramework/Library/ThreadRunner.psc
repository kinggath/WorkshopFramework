; ---------------------------------------------
; WorkshopFramework:Library:ThreadRunner.psc - by kinggath
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

Scriptname WorkshopFramework:Library:ThreadRunner extends WorkshopFramework:Library:LockableQuest
{ Should be extended and variations of RunThread should be set up for whatever needs your mod has }

import WorkshopFramework:Library:UtilityFunctions

; ---------------------------------------------
; Consts
; ---------------------------------------------

Float NULLARGUMENT = -1522753.0 Const ; Copied from ThreadManager
Int OVERLOADTHRESHOLD = 20 Const ; Copied from ThreadManager
Int iTimerID_QueuePump = 1 Const
Float fQueuePumpInterval = 5.0 Const
Float fQueuePumpRecoveryDelay = 30.0 Const
Float fThreadStartTimeout = 30.0 Const
Float fThreadRunTimeout = 300.0 Const
Float fDurableRunRetryDelay = 2.0 Const
Int iMaxDurableRunRetries = 3 Const
String sLayoutRecoveryLog = "WSFWLayoutRecovery" Const

; ---------------------------------------------
; Custom Events
; ---------------------------------------------

CustomEvent OnThreadCompleted ; kArgs[0] = iCallbackID, kArgs[1] = Result from called function

; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------

GlobalVariable Property QueueCounter Auto Const
RefCollectionAlias Property QueuedThreads Auto Const Mandatory

; ---------------------------------------------
; Dynamic Properties 
; ---------------------------------------------

; Need one set of these for each OVERLOADTHRESHOLD, this will allow us to "queue" up the functions with dynamic variables
Var[] StoredArguments1
Var[] StoredArguments2
Var[] StoredArguments3
Var[] StoredArguments4
Var[] StoredArguments5
Var[] StoredArguments6
Var[] StoredArguments7
Var[] StoredArguments8
Var[] StoredArguments9
Var[] StoredArguments10
Var[] StoredArguments11
Var[] StoredArguments12
Var[] StoredArguments13
Var[] StoredArguments14
Var[] StoredArguments15
Var[] StoredArguments16
Var[] StoredArguments17
Var[] StoredArguments18
Var[] StoredArguments19
Var[] StoredArguments20


int iNextStoredArgumentIndex = 0
Int Property NextStoredArgumentIndex
	Int Function Get()
		iNextStoredArgumentIndex += 1
		
		if(iNextStoredArgumentIndex > OVERLOADTHRESHOLD)
			iNextStoredArgumentIndex = 1
		endif
		
		return iNextStoredArgumentIndex
	EndFunction
EndProperty

Function StoreArguments(Int aiArgumentIndex, Var[] akArgs)
	int i = 0
	Var[] StoreHere
	if(aiArgumentIndex == 1)
		if( ! StoredArguments1) ; Init
			StoredArguments1 = new Var[0]
		endif
		
		StoreHere = StoredArguments1
	elseif(aiArgumentIndex == 2)
		if( ! StoredArguments2) ; Init
			StoredArguments2 = new Var[0]
		endif
		
		StoreHere = StoredArguments2
	elseif(aiArgumentIndex == 3)
		if( ! StoredArguments3) ; Init
			StoredArguments3 = new Var[0]
		endif
		
		StoreHere = StoredArguments3
	elseif(aiArgumentIndex == 4)
		if( ! StoredArguments4) ; Init
			StoredArguments4 = new Var[0]
		endif
		
		StoreHere = StoredArguments4
	elseif(aiArgumentIndex == 5)
		if( ! StoredArguments5) ; Init
			StoredArguments5 = new Var[0]
		endif
		
		StoreHere = StoredArguments5
	elseif(aiArgumentIndex == 6)
		if( ! StoredArguments6) ; Init
			StoredArguments6 = new Var[0]
		endif
		
		StoreHere = StoredArguments6
	elseif(aiArgumentIndex == 7)
		if( ! StoredArguments7) ; Init
			StoredArguments7 = new Var[0]
		endif
		
		StoreHere = StoredArguments7
	elseif(aiArgumentIndex == 8)
		if( ! StoredArguments8) ; Init
			StoredArguments8 = new Var[0]
		endif
		
		StoreHere = StoredArguments8
	elseif(aiArgumentIndex == 9)
		if( ! StoredArguments9) ; Init
			StoredArguments9 = new Var[0]
		endif
		
		StoreHere = StoredArguments9
	elseif(aiArgumentIndex == 10)
		if( ! StoredArguments10) ; Init
			StoredArguments10 = new Var[0]
		endif
		
		StoreHere = StoredArguments10
	elseif(aiArgumentIndex == 11)
		if( ! StoredArguments11) ; Init
			StoredArguments11 = new Var[0]
		endif
		
		StoreHere = StoredArguments11
	elseif(aiArgumentIndex == 12)
		if( ! StoredArguments12) ; Init
			StoredArguments12 = new Var[0]
		endif
		
		StoreHere = StoredArguments12
	elseif(aiArgumentIndex == 13)
		if( ! StoredArguments13) ; Init
			StoredArguments13 = new Var[0]
		endif
		
		StoreHere = StoredArguments13
	elseif(aiArgumentIndex == 14)
		if( ! StoredArguments14) ; Init
			StoredArguments14 = new Var[0]
		endif
		
		StoreHere = StoredArguments14
	elseif(aiArgumentIndex == 15)
		if( ! StoredArguments15) ; Init
			StoredArguments15 = new Var[0]
		endif
		
		StoreHere = StoredArguments15
	elseif(aiArgumentIndex == 16)
		if( ! StoredArguments16) ; Init
			StoredArguments16 = new Var[0]
		endif
		
		StoreHere = StoredArguments16
	elseif(aiArgumentIndex == 17)
		if( ! StoredArguments17) ; Init
			StoredArguments17 = new Var[0]
		endif
		
		StoreHere = StoredArguments17
	elseif(aiArgumentIndex == 18)
		if( ! StoredArguments18) ; Init
			StoredArguments18 = new Var[0]
		endif
		
		StoreHere = StoredArguments18
	elseif(aiArgumentIndex == 19)
		if( ! StoredArguments19) ; Init
			StoredArguments19 = new Var[0]
		endif
		
		StoreHere = StoredArguments19
	elseif(aiArgumentIndex == 20)
		if( ! StoredArguments20) ; Init
			StoredArguments20 = new Var[0]
		endif
		
		StoreHere = StoredArguments20
	endif
	
	; Change the StoredArguments array to be the same length as the sent arguments
	if(StoreHere.Length > akArgs.Length)
		StoreHere.Remove(StoreHere.Length - (StoreHere.Length - akArgs.Length), (StoreHere.Length - akArgs.Length))
	endif
	
	i = 0
	while(i < akArgs.Length)
		if(StoreHere.Length > i)
			StoreHere[i] = akArgs[i]
		else
			StoreHere.Add(akArgs[i])
		endif
		
		i += 1
	endWhile
EndFunction

Var[] Function GetStoredArguments(Int aiArgumentIndex)
	if(aiArgumentIndex == 1)
		return StoredArguments1
	elseif(aiArgumentIndex == 2)
		return StoredArguments2
	elseif(aiArgumentIndex == 3)
		return StoredArguments3
	elseif(aiArgumentIndex == 4)
		return StoredArguments4
	elseif(aiArgumentIndex == 5)
		return StoredArguments5
	elseif(aiArgumentIndex == 6)
		return StoredArguments6
	elseif(aiArgumentIndex == 7)
		return StoredArguments7
	elseif(aiArgumentIndex == 8)
		return StoredArguments8
	elseif(aiArgumentIndex == 9)
		return StoredArguments9
	elseif(aiArgumentIndex == 10)
		return StoredArguments10
	elseif(aiArgumentIndex == 11)
		return StoredArguments11
	elseif(aiArgumentIndex == 12)
		return StoredArguments12
	elseif(aiArgumentIndex == 13)
		return StoredArguments13
	elseif(aiArgumentIndex == 14)
		return StoredArguments14
	elseif(aiArgumentIndex == 15)
		return StoredArguments15
	elseif(aiArgumentIndex == 16)
		return StoredArguments16
	elseif(aiArgumentIndex == 17)
		return StoredArguments17
	elseif(aiArgumentIndex == 18)
		return StoredArguments18
	elseif(aiArgumentIndex == 19)
		return StoredArguments19
	elseif(aiArgumentIndex == 20)
		return StoredArguments20
	endif
EndFunction

; ---------------------------------------------
; Variables 
; ---------------------------------------------

int iRunningThreads = 0
WorkshopFramework:Library:ObjectRefs:Thread kRunningThread
Float fRunningThreadStartTime = 0.0
Bool bQueuePumpTimerRunning = false
Float fQueuePumpTimerStartTime = 0.0

; ---------------------------------------------
; States 
; ---------------------------------------------


; ---------------------------------------------
; Events 
; ---------------------------------------------

Event WorkshopFramework:Library:ObjectRefs:Thread.ThreadRunComplete(WorkshopFramework:Library:ObjectRefs:Thread akThreadRef, Var[] akArgs)
	UnregisterForCustomEvent(akThreadRef, "ThreadRunComplete")
	HandleCompletedThread(akThreadRef)
EndEvent

Event OnTimer(Int aiTimerID)
	if(aiTimerID == iTimerID_QueuePump)
		bQueuePumpTimerRunning = false
		fQueuePumpTimerStartTime = 0.0
		PumpDurableQueue()
	endif
EndEvent


; ---------------------------------------------
; Event Handler Functions
; ---------------------------------------------

Function HandleGameLoaded()
	; Make sure the queue never gets stuck due to things like externally deleted threads, or mods using the threading engine being uninstalled
	CancelTimer(iTimerID_QueuePump)
	iRunningThreads = 0 
	kRunningThread = None
	fRunningThreadStartTime = 0.0
	bQueuePumpTimerRunning = false
	fQueuePumpTimerStartTime = 0.0
	
	Parent.HandleGameLoaded()
	
	TryToProcessNextQueuedThread()
	StartQueuePumpTimer(fQueuePumpInterval)
EndFunction
; ---------------------------------------------
; Functions
; ---------------------------------------------

Function CompleteRun(String asCustomCallbackID, Int aiCallBackID, Var akResult)
	QueueCounter.Mod(-1)
	
	;Debug.Trace("ThreadRunner.CompleteRun. asCustomCallbackID = " + asCustomCallbackID + " Thread = " + akResult)
	; Send the response with the callback ID so in case the original caller needs it
	if(asCustomCallbackID != "")
		Var[] kResultArgs = new Var[3]
		kResultArgs[0] = asCustomCallbackID
		kResultArgs[1] = aiCallBackID
		kResultArgs[2] = akResult
		
		SendCustomEvent("OnThreadCompleted", kResultArgs)
	endif
EndFunction

; Simple threader that just calls a function and some float arguments to an arbitrary form, if multiple threads use the same aCallingForm, this won't be any faster than just calling them directly on that object in a sequence. The benefit of this particular RunThread function is as a throttle, or when many different objects need a function called on them.
Bool Function RunRemoteFunctionThread(Int aiCallBackID, String asCustomCallbackID, Form aCallingForm, String asCastAs, String asFunction, Int aiStoredArgumentsIndex)
	ModTrace(Self + ".RunRemoteFunctionThread(aiCallBackID = " + aiCallBackID + ", asCustomCallbackID = " + asCustomCallbackID + ", aCallingForm = " + aCallingForm + ", asFunction = " + asFunction + ", " + aiStoredArgumentsIndex + ")")
	
	if( ! aCallingForm)
		return false
	endif
	
	; Get Edit Lock
	int iLockKey = GetLock()
	if(iLockKey <= GENERICLOCK_KEY_NONE)
        ModTrace("Unable to get lock!", 2)
		
        return false
    endif
	
	; Start Thread
	Var[] params = new Var[0]
	
	if(aiStoredArgumentsIndex > 0)
		params = GetStoredArguments(aiStoredArgumentsIndex)
	endif
	
	ScriptObject callingScript = aCallingForm
	if(asCastAs != "")
		callingScript = aCallingForm.CastAs(asCastAs)
	endif
	
	if( ! callingScript)
		return false
	endif
	
	Var response = callingScript.CallFunction(asFunction, params)
	
	CompleteRun(asCustomCallbackID, aiCallBackID, response)
	
	; Release Edit Lock
	if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
        ModTrace("Failed to release lock " + iLockKey + "!", 2)
    endif
	
	return true
EndFunction


; Calls a global function with arguements stored in one of this script's arrays
Bool Function RunGlobalFunctionThread(Int aiCallBackID, String asCustomCallbackID, String asGlobalScript, String asGlobalFunction, Int aiStoredArgumentsIndex)
	Var[] gArgs
	Var kTemp
	
	; Get Edit Lock 
	int iLockKey = GetLock()
	if(iLockKey <= GENERICLOCK_KEY_NONE)
        ModTrace("Unable to get lock!", 2)
	else
		if(aiStoredArgumentsIndex > 0)
			gArgs = GetStoredArguments(aiStoredArgumentsIndex)
		endif
		
		;Debug.Trace("Found global args at index " + aiStoredArgumentsIndex + ": " + gArgs)
		
		kTemp = Utility.CallGlobalFunction(asGlobalScript, asGlobalFunction, gArgs)
    endif
	
	CompleteRun(asCustomCallbackID, aiCallBackID, kTemp)
	
	; Release Edit Lock
	if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
        ModTrace("Failed to release lock " + iLockKey + "!", 2)
    endif
	
	return true
EndFunction


Function HandleNewThread(WorkshopFramework:Library:ObjectRefs:Thread akThreadRef)
	QueuedThreads.AddRef(akThreadRef)
	QueueCounter.Mod(1)
	TryToProcessNextQueuedThread()
EndFunction

Bool Function QueueDurableThread(WorkshopFramework:Library:ObjectRefs:Thread akThreadRef)
	if( ! akThreadRef)
		return false
	endif

	if(QueuedThreads.Find(akThreadRef) < 0)
		QueuedThreads.AddRef(akThreadRef)
	endif

	if(QueuedThreads.Find(akThreadRef) < 0)
		return false
	endif

	akThreadRef.bDurableQueued = true
	akThreadRef.fDurableQueueTime = Utility.GetCurrentRealTime()
	StartQueuePumpTimer(0.1)
	return true
EndFunction

Function StartQueuePumpTimer(Float afDelay)
	Float fCurrentTime = Utility.GetCurrentRealTime()
	Float fElapsed = fCurrentTime - fQueuePumpTimerStartTime
	if(bQueuePumpTimerRunning && (fQueuePumpTimerStartTime <= 0.0 || fElapsed > fQueuePumpRecoveryDelay))
		CancelTimer(iTimerID_QueuePump)
		bQueuePumpTimerRunning = false
		Debug.TraceUser(sLayoutRecoveryLog, "Reset overdue durable queue pump on " + Self + " after " + fElapsed + " seconds", 1)
	endif
	if( ! bQueuePumpTimerRunning)
		bQueuePumpTimerRunning = true
		fQueuePumpTimerStartTime = fCurrentTime
		StartTimer(afDelay, iTimerID_QueuePump)
	endif
EndFunction

Bool Function ReleaseDurableThread(WorkshopFramework:Library:ObjectRefs:Thread akThreadRef)
	if( ! akThreadRef || QueuedThreads.Find(akThreadRef) < 0)
		return false
	endif

	UnregisterForCustomEvent(akThreadRef, "ThreadRunComplete")
	QueuedThreads.RemoveRef(akThreadRef)
	QueueCounter.Mod(-1)
	if(kRunningThread == akThreadRef)
		kRunningThread = None
		fRunningThreadStartTime = 0.0
		iRunningThreads = 0
	endif
	akThreadRef.bDurableQueued = false
	akThreadRef.iDurableRunnerIndex = -1
	StartQueuePumpTimer(0.1)
	return true
EndFunction


Function TryToProcessNextQueuedThread()
	if(iRunningThreads > 0)
		;Debug.Trace(Self + " busy, will try again after previous thread completes.")
		return
	endif	
	
	; Get Edit Lock 
	int iLockKey = GetLock()
	if(iLockKey <= GENERICLOCK_KEY_NONE)
        ModTrace("Unable to get lock!", 2)
	else
		;
		; Lock acquired - do work
		;
		
		; Check again now that we hold the lock: another call may have started a thread while we waited in GetLock.
		; Starting a second one here strands the first thread's completion and leaves the runner stuck busy
		; (iRunningThreads > 0 with kRunningThread = None) until the next game load.
		if(iRunningThreads > 0)
			if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE)
				ModTrace("Failed to release lock " + iLockKey + "!", 2)
			endif
			
			return
		endif
		
		int iCount = QueuedThreads.GetCount()
		if(iCount > 0)
			int i = 0
			
			ObjectReference kTemp = None
			while(i < iCount && kTemp == None)
				; loop past any None entries which could happen due to mods being uninstalled
				kTemp = QueuedThreads.GetAt(i)
			
				if(kTemp != None && kTemp.GetBaseObject() != None && kTemp.GetBaseObject().GetFormID() != 0x00000000)
					WorkshopFramework:Library:ObjectRefs:Thread thisThread = kTemp as WorkshopFramework:Library:ObjectRefs:Thread
					
					if(thisThread && thisThread.IsBoundGameObjectAvailable())
						if(thisThread.bDurableQueued)
							if(thisThread.bThreadRunComplete)
								HandleCompletedThreadV2(thisThread, false)
							elseif(thisThread.bThreadRunStarted)
								iRunningThreads = 1
								kRunningThread = thisThread
								fRunningThreadStartTime = thisThread.fThreadRunStartTime
								if(fRunningThreadStartTime <= 0.0 || fRunningThreadStartTime > Utility.GetCurrentRealTime())
									fRunningThreadStartTime = Utility.GetCurrentRealTime()
									thisThread.fThreadRunStartTime = fRunningThreadStartTime
								endif
							else
								ProcessThreadObject(thisThread)
							endif
						else
							QueuedThreads.RemoveRef(kTemp)
							ProcessThreadObject(thisThread)
						endif
					else
						QueuedThreads.RemoveRef(kTemp)
					endif
				endif
				
				i += 1
			endWhile
		endif
	endif	
	
	; Release Edit Lock
	if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
        ModTrace("Failed to release lock " + iLockKey + "!", 2)
    endif
EndFunction


Function ProcessThreadObject(WorkshopFramework:Library:ObjectRefs:Thread akThreadRef)
	iRunningThreads += 1
	kRunningThread = akThreadRef
	fRunningThreadStartTime = Utility.GetCurrentRealTime()
	RegisterForCustomEvent(akThreadRef, "ThreadRunComplete")
	Var[] kArgs = new Var[0]
	akThreadRef.CallFunctionNoWait("StartThread", kArgs)	
EndFunction

Function HandleCompletedThread(WorkshopFramework:Library:ObjectRefs:Thread akThreadRef)
	HandleCompletedThreadV2(akThreadRef)
EndFunction


Function HandleCompletedThreadV2(WorkshopFramework:Library:ObjectRefs:Thread akThreadRef, Bool abProcessNext = true)
	if( ! akThreadRef)
		return
	endif

	if(akThreadRef.bDurableQueued && akThreadRef.bThreadRunComplete && ! akThreadRef.WasThreadRunSuccessful() && akThreadRef.iDurableRetryCount < iMaxDurableRunRetries)
		akThreadRef.iDurableRetryCount += 1
		Int iRunnerIndex = akThreadRef.iDurableRunnerIndex
		Debug.TraceUser(sLayoutRecoveryLog, "Retrying failed durable worker " + akThreadRef + " on runner " + Self + " - operation=" + akThreadRef.iDurableOperationID + ", layout=" + akThreadRef.kDurableLayout + ", form=" + akThreadRef.kDurableTargetForm + ", item=" + akThreadRef.iDurableItemIndex + ", group=" + akThreadRef.iDurableItemGroup + ", attempt=" + akThreadRef.iDurableRetryCount, 1)
		UnregisterForCustomEvent(akThreadRef, "ThreadRunComplete")
		if(kRunningThread == akThreadRef)
			kRunningThread = None
			fRunningThreadStartTime = 0.0
			iRunningThreads = 0
		endif
		akThreadRef.PrepareDurableRetry()
		akThreadRef.iDurableRunnerIndex = iRunnerIndex
		akThreadRef.bDurableQueued = true
		akThreadRef.fDurableQueueTime = Utility.GetCurrentRealTime()
		StartQueuePumpTimer(fDurableRunRetryDelay)
		return
	elseif(akThreadRef.bDurableQueued && akThreadRef.bThreadRunComplete && ! akThreadRef.WasThreadRunSuccessful())
		akThreadRef.bDurableRunFailed = true
		Debug.TraceUser(sLayoutRecoveryLog, "Durable worker failed after retries " + akThreadRef + " on runner " + Self + " - operation=" + akThreadRef.iDurableOperationID + ", layout=" + akThreadRef.kDurableLayout + ", form=" + akThreadRef.kDurableTargetForm + ", item=" + akThreadRef.iDurableItemIndex + ", group=" + akThreadRef.iDurableItemGroup, 2)
	endif

	Bool bAwaitingDurableCredit = akThreadRef.bDurableQueued && akThreadRef.kDurableOwnerRef && akThreadRef.kDurableTrackingKeyword && akThreadRef.sCustomCallbackID != "" && ! akThreadRef.bDurableCredited
	if(akThreadRef.bDurableQueued && ! bAwaitingDurableCredit)
		QueuedThreads.RemoveRef(akThreadRef)
		akThreadRef.bDurableQueued = false
	endif

	if( ! akThreadRef.bRunnerCompletionHandled)
		akThreadRef.bRunnerCompletionHandled = true
		CompleteRun(akThreadRef.sCustomCallbackID, akThreadRef.iCallBackID, akThreadRef)
	elseif(bAwaitingDurableCredit)
		Var[] kResultArgs = new Var[3]
		kResultArgs[0] = akThreadRef.sCustomCallbackID
		kResultArgs[1] = akThreadRef.iCallBackID
		kResultArgs[2] = akThreadRef
		SendCustomEvent("OnThreadCompleted", kResultArgs)
	endif

	if(bAwaitingDurableCredit)
		StartQueuePumpTimer(fQueuePumpInterval)
		return
	endif

	if(kRunningThread == akThreadRef)
		iRunningThreads -= 1
		if(iRunningThreads < 0)
			iRunningThreads = 0
		endif

		kRunningThread = None
		fRunningThreadStartTime = 0.0
	endif

	if(abProcessNext)
		TryToProcessNextQueuedThread()
	endif
	if(iRunningThreads > 0 || QueuedThreads.GetCount() > 0)
		StartQueuePumpTimer(fQueuePumpInterval)
	endif
EndFunction

Function PumpDurableQueue()
	WorkshopFramework:Library:ObjectRefs:Thread kCurrentThread = kRunningThread
	if(kCurrentThread)
		Float fElapsed = Utility.GetCurrentRealTime() - fRunningThreadStartTime
		if(kCurrentThread.bThreadRunComplete)
			HandleCompletedThread(kCurrentThread)
		elseif(( ! kCurrentThread.bThreadRunStarted && fElapsed >= fThreadStartTimeout) || fElapsed >= fThreadRunTimeout)
			if(kRunningThread == kCurrentThread)
				UnregisterForCustomEvent(kCurrentThread, "ThreadRunComplete")
				kRunningThread = None
				fRunningThreadStartTime = 0.0
				iRunningThreads = 0
				kCurrentThread.PrepareDurableRetry()
				QueueDurableThread(kCurrentThread)
			endif
		endif
	endif

	TryToProcessNextQueuedThread()
	if(iRunningThreads > 0 || QueuedThreads.GetCount() > 0)
		StartQueuePumpTimer(fQueuePumpInterval)
	endif
EndFunction
