Scriptname WorkshopFramework:ObjectRefs:SelfResettingRef extends ObjectReference

import WorkshopFramework:Library:UtilityFunctions

Float Property fResetTime = 0.0 Auto Const
{ If set, this container will be set to reset every this many game hours }

Bool bResetTimerRunning = false

Event OnInit()
	if(fResetTime > 0.0 && ! bResetTimerRunning)
		StartResetTimer()
	endif
EndEvent

Event OnCellLoad()
	if(fResetTime > 0.0 && ! bResetTimerRunning)
		Reset() ; Immediately reset the first time to ensure in correct state
		StartResetTimer()
	endif
EndEvent


Event OnTimerGameTime(Int aiTimerID)
	Reset()
	StartResetTimer()
EndEvent

Function StartResetTimer()
	StartTimerGameTime(fResetTime)
	bResetTimerRunning = true
EndFunction