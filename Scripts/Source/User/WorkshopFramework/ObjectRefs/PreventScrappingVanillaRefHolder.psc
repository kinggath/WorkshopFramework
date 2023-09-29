Scriptname WorkshopFramework:ObjectRefs:PreventScrappingVanillaRefHolder Const

ObjectReference[] Property ProtectRefs Auto Const Mandatory

Event OnInit()
	; WISabotageStart
	Keyword PreventScrapKeyword = Game.GetFormFromFile(0x0006D1E5, "Fallout4.esm") as Keyword
	int i = 0
	while(i < ProtectRefs.Length)
		ProtectRefs[i].AddKeyword(PreventScrapKeyword)
		
		i += 1
	endWhile
EndEvent