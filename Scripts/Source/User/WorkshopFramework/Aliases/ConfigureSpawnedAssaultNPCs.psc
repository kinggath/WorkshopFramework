Scriptname WorkshopFramework:Aliases:ConfigureSpawnedAssaultNPCs extends RefCollectionAlias

Spell Property NeutralAggression Auto Const
Faction Property SettlementFriendlyFaction Auto Const

Event OnLoad(ObjectReference akSender)
	Actor thisActor = akSender as Actor
	if(SettlementFriendlyFaction)
		thisActor.AddToFaction(SettlementFriendlyFaction)
	endif
	
	if(NeutralAggression)
		thisActor.AddSpell(NeutralAggression, abVerbose = false)
	endif
EndEvent