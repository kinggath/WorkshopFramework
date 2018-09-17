Scriptname WorkshopRadioBeaconRecruitScript extends Quest Conditional
{quickly summon new workshop recruit}

ReferenceAlias Property Alias_Workshop Auto Const
ReferenceAlias Property Alias_WorkshopAttackMarker Auto Const

workshopparentscript Property WorkshopParent Auto Const

Group WSWF
	WorkshopFramework:NPCManager Property NPCManager Auto Const
EndGroup

function Startup()
	; run random timer for new recruits to show up
	float gameTime = utility.RandomFloat(0.2, 0.5)

	StartTimerGameTime(gameTime)
endFunction

; create new recruits
Event OnTimerGameTime(int aiTimerID)
	WorkshopScript workshopRef = Alias_Workshop.GetRef() as WorkshopScript
	NPCManager.CreateInitialSettlers(workshopRef, Alias_WorkshopAttackMarker.GetRef())
	
		;/ WSWF - Rerouting this code to NPCManager
			; how many new settlers?
			int recruitRoll = utility.randomint(1, 100)
			int recruitCount = 1
			if recruitRoll > 60
				recruitCount = 2
			elseif recruitRoll > 80
				recruitCount = 3
			endif
			debug.trace(self + " recruitRoll=" + recruitRoll + ", creating " + recruitCount + " settlers")
			WorkshopScript workshopRef = Alias_Workshop.GetRef() as WorkshopScript
			; create new settler for this workshop at nearby marker
			int i = 0
			while i < recruitCount
				WorkshopParent.CreateActorPUBLIC(workshopRef, Alias_WorkshopAttackMarker.GetRef(), i == 0)
				
				
				i += 1
			endWhile
		/;

	; flag this workshop - no more free recruits
	workshopRef.RadioBeaconFirstRecruit = true

	Stop()
EndEvent
