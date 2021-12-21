Scriptname WorkshopFramework:ObjectRefs:MoveContainerItemsOnLoad extends ObjectReference Const

Keyword Property MoveToLinkedRefOnKeyword = None Auto Const
{ Items will be moved to whatever GetLinkedRef(MoveToLinkedRefOnKeyword) returns }

Event OnInit()
	StartTimer(3.0)
EndEvent

Event OnCellLoad()
	StartTimer(3.0) ; Give a moment to ensure this container and the linked have finished respawning
EndEvent

Event OnTimer(Int aiTimerID)
	MoveItems()
EndEvent


Function MoveItems()
	ObjectReference kTargetRef = GetLinkedRef(MoveToLinkedRefOnKeyword)
	
	;Debug.Trace(">>>>>>>>>>>>>>> " + Self + " Moving " + Self.GetItemCount() + " items to " + kTargetRef)
	
	if(kTargetRef != None)
		Self.RemoveAllItems(kTargetRef, false)
	endif
EndFunction