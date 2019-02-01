Scriptname WorkshopFramework:Aliases:RemoveSubdueTargetFromAlias extends RefCollectionAlias Const

RefCollectionAlias Property ForcedSubdueAlias Auto Const Mandatory
{  1.1.1 - When used with Subdue assaults, this will prevent them being stuck in the alias }

Event OnEnterBleedout(ObjectReference akSenderRef) 
	if(ForcedSubdueAlias.Find(akSenderRef) >= 0) ; NPC is set to subdue
		; We don't want them left in this
		RemoveRef(akSenderRef)
	endif
EndEvent
