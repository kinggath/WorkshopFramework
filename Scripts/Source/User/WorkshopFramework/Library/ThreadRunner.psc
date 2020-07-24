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

; ---------------------------------------------
; States 
; ---------------------------------------------


; ---------------------------------------------
; Events 
; ---------------------------------------------

Event WorkshopFramework:Library:ObjectRefs:Thread.ThreadRunComplete(WorkshopFramework:Library:ObjectRefs:Thread akThreadRef, Var[] akArgs)
	UnregisterForCustomEvent(akThreadRef, "ThreadRunComplete")
	CompleteRun(akArgs[0] as String, akArgs[1] as Int, akThreadRef)
	iRunningThreads -= 1
	TryToProcessNextQueuedThread()
EndEvent


; ---------------------------------------------
; Event Handler Functions
; ---------------------------------------------

Function HandleGameLoaded()
	; Make sure the queue never gets stuck due to things like externally deleted threads, or mods using the threading engine being uninstalled
	iRunningThreads = 0 
	
	Parent.HandleGameLoaded()
	
	TryToProcessNextQueuedThread()
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
		
		int iCount = QueuedThreads.GetCount()
		if(iCount > 0)
			int i = 0
			
			ObjectReference kTemp = None
			while(i < iCount && kTemp == None)
				; loop past any None entries which could happen due to mods being uninstalled
				kTemp = QueuedThreads.GetAt(i)
			
				if(kTemp != None && kTemp.GetBaseObject() != None && kTemp.GetBaseObject().GetFormID() != 0x00000000)
					WorkshopFramework:Library:ObjectRefs:Thread thisThread = kTemp as WorkshopFramework:Library:ObjectRefs:Thread
					
					; Clear from queue - even if it isn't a thread object, should never happen, but just in case
					QueuedThreads.RemoveRef(kTemp)
					
					if(thisThread && thisThread.IsBoundGameObjectAvailable())
						ProcessThreadObject(thisThread)
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
	RegisterForCustomEvent(akThreadRef, "ThreadRunComplete")
	Var[] kArgs = new Var[0]
	akThreadRef.CallFunctionNoWait("StartThread", kArgs)	
EndFunction