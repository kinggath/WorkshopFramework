Scriptname WorkshopFramework:ObjectRefs:PreventExportingRefHolder Const

ObjectReference[] Property ProtectRefs Auto Const Mandatory

Event OnInit()
	; IgnoreAccuracyBonusInUI
	Keyword PreventExportKeyword = Game.GetFormFromFile(0x00247F26, "Fallout4.esm") as Keyword
	int i = 0
	while(i < ProtectRefs.Length)
		ProtectRefs[i].AddKeyword(PreventExportKeyword)
		
		i += 1
	endWhile
EndEvent