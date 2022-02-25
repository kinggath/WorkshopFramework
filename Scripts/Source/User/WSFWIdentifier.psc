ScriptName WSFWIdentifier native hidden

Struct PowerGridStatistics
	Bool broken
	Bool checked
	Int validNodes
	Int invalidNodes
	Int numBadGrids
	Int totalNodes
	Int totalGrids
EndStruct

;-- Functions ---------------------------------------

string Function GetReferenceName( ObjectReference ref ) global native

Function MessageReferenceName( ObjectReference ref ) global
	Debug.MessageBox( "ref.GetName(): " + ref.GetName() + "<br>ref.GetBaseObject().GetName(): " + ref.GetBaseObject().GetName() + "<br>ref.GetDisplayName(): " + ref.GetDisplayName() + "<br>GetReferenceName( ref ): " + GetReferenceName( ref ) )
EndFunction


; Completely deletes the power grid of a settlement. Use only for settlements with a broken power grid.
Bool Function ResetPowerGrid( ObjectReference workshop_ref ) global native

; Check and optionally fix errors for a settlement power grid. Returns statistics data in PowerGridStatistics struct. Log results.
; fixerrors = 0 - check settlement for power grid errors, but don't fix anything
; fixerrors = 1 - check settlement for power grid errors, and fix errors by trying to remove faulty subgrids only
PowerGridStatistics Function CheckAndFixPowerGrid( ObjectReference workshop_ref, Int fixerrors ) global native

; Check errors for a settlement power grid. Log results.
Bool Function ScanPowerGrid( ObjectReference workshop_ref ) global native

