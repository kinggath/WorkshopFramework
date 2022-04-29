Scriptname WorkshopFramework:ObjectRefs:InteriorWorkshopRoomboundHelper extends ObjectReference Const
{ Add this to the workshop of an interior settlement that uses Roombounds to fix the invisibility problem. }

Event OnWorkshopObjectPlaced(ObjectReference akItemReference)
	akItemReference.Disable(false)
	akItemReference.Enable(false)
EndEvent