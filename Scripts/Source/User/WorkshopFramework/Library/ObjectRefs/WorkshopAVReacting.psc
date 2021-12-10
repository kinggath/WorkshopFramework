Scriptname WorkshopFramework:Library:ObjectRefs:WorkshopAVReacting extends ObjectReference Const

import WorkshopFramework:Library:DataStructures
import WorkshopFramework:Library:UtilityFunctions
import WorkshopFramework:WorkshopFunctions


ActorValueSet[] Property ActiveThresholds Auto Const Mandatory
{ If all these evaluate to true, this object will be enabled, otherwise disabled }

Event OnCellLoad()
	Keyword WorkshopItemKeyword = GetWorkshopItemKeyword()
	
	WorkshopScript thisWorkshop = GetLinkedRef(WorkshopItemKeyword) as WorkshopScript
	if(thisWorkshop)
		int i = 0
		bool bEnable = true
		while(i < ActiveThresholds.Length && bEnable)
			if( ! CheckActorValueSet(thisWorkshop, ActiveThresholds[i]))
				bEnable = false
			endif
			
			i += 1
		endWhile
		
		if(bEnable)
			Self.Enable()
		else
			Self.Disable()
		endif
	endif
EndEvent