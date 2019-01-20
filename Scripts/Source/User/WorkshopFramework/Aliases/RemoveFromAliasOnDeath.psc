Scriptname WorkshopFramework:Aliases:RemoveFromAliasOnDeath extends RefCollectionAlias Const

Event OnDeath(ObjectReference akSenderRef, Actor akKillerRef)
	RemoveRef(akSenderRef)
EndEvent