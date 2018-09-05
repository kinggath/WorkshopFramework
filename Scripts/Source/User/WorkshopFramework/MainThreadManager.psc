; ---------------------------------------------
; WorkshopFramework:MainThreadManager.psc - by kinggath
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

Scriptname WorkshopFramework:MainThreadManager extends WorkshopFramework:Library:ThreadManager

; -----------------------------------
; Consts
; -----------------------------------



; -----------------------------------
; Editor Properties
; -----------------------------------

Group Keywords
	Keyword Property MakeStaticKeyword Auto Const Mandatory
	{ Temporary keyword to be assigned to objects that need to be made static once they load }
	Keyword Property WorkshopItemKeyword Auto Const Mandatory
	{ Autofill }
EndGroup

Group AVs
	ActorValue Property PositionXAV Auto Const Mandatory
	{ Temp AV to store position data }
	ActorValue Property PositionYAV Auto Const Mandatory
	{ Temp AV to store position data }
	ActorValue Property PositionZAV Auto Const Mandatory
	{ Temp AV to store position data }
	ActorValue Property RotationXAV Auto Const Mandatory
	{ Temp AV to store rotation data }
	ActorValue Property RotationYAV Auto Const Mandatory
	{ Temp AV to store rotation data }
	ActorValue Property RotationZAV Auto Const Mandatory
	{ Temp AV to store rotation data }
	ActorValue Property ScaleAV Auto Const Mandatory
	{ Temp AV to store scale data }
EndGroup


Group Assets
	Form Property PositionHelper Auto Const Mandatory
	{ Form to be used for marking positions }
EndGroup


; --------------------------------------------- 
; Consts
; ---------------------------------------------

int iUpdateThreadRunnersTimerID = 0

; ---------------------------------------------
; Events
; ---------------------------------------------

Event OnTimer(Int aiTimerID)
	if(aiTimerID == iUpdateThreadRunnersTimerID)
		UpdateThreadRunnerVars()
		
		; Call init function
		Parent.HandleQuestInit()
	endif
EndEvent

; -----------------------------------
; Overrides
; -----------------------------------

Function HandleQuestInit()	
	; First setup thread runners before initializing - as part of the initializing is to switch the state so the thread queues are available
	StartTimer(1.0, iUpdateThreadRunnersTimerID)
EndFunction

Function HandleInstallModChanges()
	Parent.HandleInstallModChanges()
	
	; Copy our properties down to the threadrunners - this ensures they don't all need to have a bunch of properties set, nor do they need to keep touching back to the Threadmanager
	UpdateThreadRunnerVars()

	
	; For patch specific updates, Use format:
	; if(iInstalledVersion < X)
	;      ; Make changes
	; endif
EndFunction

Function CalculateAvailableThreads()
	; Determine how many threads this should allow itself	
	if( ! bOverride)
		; TODO - Look at list of installed plugins and determine how many threads to allow
		iMaxThreads = ThreadRunners.Length 
	endif
EndFunction



; -----------------------------------
; Functions
; -----------------------------------

Function UpdateThreadRunnerVars()
	bool bInterrupt = false
	int i = 0
	while(i < ThreadRunners.Length && bInterrupt)
		WorkshopFramework:MainThreadRunner thisRunner = ThreadRunners[i] as WorkshopFramework:MainThreadRunner
		
		if(thisRunner && ! thisRunner.MakeStaticKeyword)
			if(thisRunner.IsRunning())
				thisRunner.MakeStaticKeyword = MakeStaticKeyword
				thisRunner.WorkshopItemKeyword = WorkshopItemKeyword
				thisRunner.PositionXAV = PositionXAV
				thisRunner.PositionYAV = PositionYAV
				thisRunner.PositionZAV = PositionZAV
				thisRunner.RotationXAV = RotationXAV
				thisRunner.RotationYAV = RotationYAV
				thisRunner.RotationZAV = RotationZAV
				thisRunner.ScaleAV = ScaleAV
				thisRunner.PositionHelper = PositionHelper
			else
				bInterrupt = true				
			endif
		endif
		
		i += 1
	endWhile
	
	if(bInterrupt)
		; Try again shortly
		StartTimer(1.0, iUpdateThreadRunnersTimerID)
	endif
EndFunction