Scriptname WorkshopFramework:Aliases:RemoveOnDeath extends ReferenceAlias

Keyword Property IdentifierKeyword Auto Const Mandatory
{ Make sure this keyword is applied as part of the alias. }

Event OnDeath(Actor akKiller)
	if( ! akKiller)
		akKiller = Game.GetPlayer()
	endif
	
	ObjectReference[] IdentifiedRefs = akKiller.FindAllReferencesWithKeyword(IdentifierKeyword, 20000.0)
	
	int i = 0
	while(i < IdentifiedRefs.Length)
		if((IdentifiedRefs[i] as Actor).IsDead())
			RemoveFromRef(IdentifiedRefs[i])
		endif
		
		i += 1
	endWhile
EndEvent