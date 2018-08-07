; ---------------------------------------------
; WorkshopFramework:Library:ThreadManager.psc - by kinggath
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

; Number of arguments prefixed to arguments sent to QueueThread
int ARGCOUNT_Global = 2 Const 
int ARGCOUNT_Remote = 3 Const 

int OVERLOADTHRESHOLD = 20 Const ; If a thread exceeds this number of queued actions, the edit lock will be cleared to prevent the threading from overloading the VM and causing stack dumps 
int TOTALTHREADRUNNERS = 50 Const

; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------
Group Controllers
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner1 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner2 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner3 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner4 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner5 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner6 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner7 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner8 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner9 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner10 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner11 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner12 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner13 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner14 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner15 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner16 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner17 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner18 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner19 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner20 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner21 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner22 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner23 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner24 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner25 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner26 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner27 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner28 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner29 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner30 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner31 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner32 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner33 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner34 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner35 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner36 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner37 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner38 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner39 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner40 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner41 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner42 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner43 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner44 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner45 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner46 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner47 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner48 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner49 Auto Const
	WorkshopFramework:Library:ThreadRunner Property ThreadRunner50 Auto Const
EndGroup

; ---------------------------------------------
; Properties
; ---------------------------------------------
Int Property iNextRunner = 0 Auto Hidden
Int Property iMaxThreads = 50 Auto Hidden Conditional
bool Property bOverride = false Auto Hidden Conditional

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


; ---------------------------------------------
; States 
; ---------------------------------------------


; ---------------------------------------------
; Events 
; ---------------------------------------------


; ---------------------------------------------
; Event Handler Functions 
; ---------------------------------------------


Function HandleGameLoaded()	
	if(iNextCallbackID > MAXCALLBACKID)
		; Make sure we never go out of bounds
		iNextCallbackID = 0
	endif

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
		; TODO - Look at list of installed plugins and determine how many threads to allow
		iMaxThreads = 50 ; Just setting a default number for now
	endif
EndFunction


Function CheckForOvertaxing()
	; TODO - Instead of clearing the edit lock when stuck at a threshold - reject additional scripts queuing up, then keep track of the number of times the threshhold is triggered, and it hits that threshold - then clear the lock

	int i = 1
	
	while(i < TOTALTHREADRUNNERS)
		WorkshopFramework:Library:ThreadRunner thisRunner = Self.GetPropertyValue("ThreadRunner" + i) as WorkshopFramework:Library:ThreadRunner	
		
		if(thisRunner && thisRunner.GetQueueCount() > OVERLOADTHRESHOLD)
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
		int i = 1
	
		while(i < TOTALTHREADRUNNERS)
			WorkshopFramework:Library:ThreadRunner thisRunner = Self.GetPropertyValue("ThreadRunner" + i) as WorkshopFramework:Library:ThreadRunner	
			
			if(thisRunner)
				akRequestor.RegisterForCustomEvent(thisRunner, "OnThreadCompleted")
			endif
			
			i += 1
		endWhile
	endif
EndFunction


Int Function QueueRemoteFunctionThread(Form aCallingForm, String asCastAs, String asFunction, Var[] akArgs)
	if( ! aCallingForm)
		return QUEUEFAIL
	endif
	int inewArgsCounter = ARGCOUNT_Remote
	Var[] newArgs = new Var[(inewArgsCounter + akArgs.Length)]
	
	newArgs[0] = aCallingForm
	newArgs[1] = asCastAs
	newArgs[2] = asFunction
	
	int iakArgCounter = 0
	 ; Make sure this is the next index after manually fed arguments above
	while(iakArgCounter < akArgs.Length)
		newArgs[inewArgsCounter] = akArgs[iakArgCounter]
		
		iakArgCounter += 1
		inewArgsCounter += 1
	endWhile
	
	return QueueThread("RunRemoteFunctionThread", newArgs)
EndFunction


Int Function QueueGlobalThread(String asScriptName, String asFunctionName, Var[] akArgs)
	int iNewArgIndex = ARGCOUNT_Global
	Var[] newArgs = new Var[(akArgs.Length + iNewArgIndex)]
	newArgs[0] = asScriptName
	newArgs[1] = asFunctionName
	
	int iakArgIndex = 0
	
	while(iakArgIndex < akArgs.Length)
		newArgs[iNewArgIndex] = akArgs[iakArgIndex]
		
		iNewArgIndex += 1
		iakArgIndex += 1
	endWhile
	
	return QueueThread("RunGlobalFunctionThread", newArgs, true)
EndFunction


Int Function QueueThread(String asThreadRunnerFunction, Var[] akArgs, Bool abGlobalCall = false)
	WorkshopFramework:Library:ThreadRunner thisRunner = GetNextThreadRunner()
	
	if( ! thisRunner)
		return QUEUEFAIL
	endif
	
	Var[] newArgs
	int iCallbackID = NextCallbackID	
	int iakArgIndex = 0
	int iPrefixedVars = ARGCOUNT_Remote
	if(abGlobalCall)
		iPrefixedVars = ARGCOUNT_Global
	endif
	
	Int iStoredArgumentsIndex
	Var StoreStoredArguments 
	
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
			
			thisRunner.StoreStoredArguments(iStoredArgumentsIndex, StoreVars)
		else
			;Debug.Trace("No StoreVars found from akArgs: " + akArgs)
			iStoredArgumentsIndex = -1 ; No args to store
		endif
	else
		iStoredArgumentsIndex = -1 ; No arguments to store
	endif		
	
	; Prep vars to send to threadrunner
	newArgs = new Var[(iPrefixedVars + 2)]
		; Prepend CallbackID
	newArgs[0] = iCallbackID
	
	if(abGlobalCall)
		newArgs[1] = akArgs[0] ; Script name
		newArgs[2] = akArgs[1] ; function name
	else
		newArgs[1] = akArgs[0] ; Object
		newArgs[2] = akArgs[1] ; CastAs
		newArgs[3] = akArgs[2] ; Function
	endif
	
		; Append StoredArgumentsIndex
	newArgs[(newArgs.Length - 1)] = iStoredArgumentsIndex
	
	thisRunner.CallFunctionNoWait(asThreadRunnerFunction, newArgs)
	
	return iCallbackID
EndFunction


WorkshopFramework:Library:ThreadRunner Function GetNextThreadRunner(Int aiAttempted = 0)
	if(aiAttempted > TOTALTHREADRUNNERS)
		; Prevent from getting stuck in an infinite loop if all thread runners are overloaded
		return None
	endif
	
	aiAttempted += 1 
	iNextRunner += 1
	if(iNextRunner > iMaxThreads)
		iNextRunner = 1
	endif
	
	WorkshopFramework:Library:ThreadRunner thisRunner = Self.GetPropertyValue("ThreadRunner" + iNextRunner) as WorkshopFramework:Library:ThreadRunner	
	
	if(thisRunner)		
		if(thisRunner.GetQueueCount() >= OVERLOADTHRESHOLD)
			thisRunner = GetNextThreadRunner(aiAttempted)
		endif
		
		return thisRunner
	else
		return None
	endif
EndFunction