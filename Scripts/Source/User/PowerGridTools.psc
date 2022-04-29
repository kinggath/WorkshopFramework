ScriptName PowerGridTools Native Hidden

; Checks whether the given workshop reference has power grids with invalid nodes.
bool Function HasBadPowerGrids(ObjectReference akWorkshopRef) native global

; Removes power grids with invalid entries from the specified workshop reference.
; Returns whether any fixes were performed. Returns false if there was nothing to fix.
bool Function FixPowerGrids(ObjectReference akWorkshopRef) native global

; Scraps the specified workshop object.
; If akWorkshopRef is None, the workshop for the settlement that the player is currently in will be used. If Workshop mode is currently active, the currently opened workshop is always used, regardless of the setting.
bool Function Scrap(ObjectReference akRef, ObjectReference akWorkshopRef = None) native global

; Stores the specified workshop object in the given workshop.
; If akWorkshopRef is None, the workshop for the settlement that the player is currently in will be used. If Workshop mode is currently active, the currently opened workshop is always used, regardless of the setting.
bool Function Store(ObjectReference akRef, ObjectReference akWorkshopRef = None) native global
