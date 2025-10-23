ScriptName WSFW_Utility native hidden

;-- Functions ---------------------------------------

Bool Function IsPipboyOpen() global

	If Game.GetPlayer().GetAnimationVariableInt( "pipboyState" ) == 0
		return True
	Else
		return False
	EndIf
	
EndFunction


Bool Function IsF4SEInstalled() global

	If F4SE.GetVersion() >= 0 && F4SE.GetVersion() + "." + F4SE.GetVersionMinor() + "." + F4SE.GetVersionBeta() != "0.0.0"
		return True
	Else
		return False
	EndIf

EndFunction


String Function IsF4SEUpToDate( Int F4SErequiredVersion = 0, Int F4SErequiredVersionMinor = 3, Int F4SErequiredVersionBeta = 1 ) global

	Bool upToDate = False
	Int version = F4SE.GetVersion()
	Int versionMinor = F4SE.GetVersionMinor()
	Int versionBeta = F4SE.GetVersionBeta()
	If version > F4SErequiredVersion
		upToDate = True
	ElseIf version == F4SErequiredVersion && versionMinor > F4SErequiredVersionMinor
		upToDate = True
	ElseIf version == F4SErequiredVersion && versionMinor == F4SErequiredVersionMinor && versionBeta >= F4SErequiredVersionBeta
		upToDate = True
	EndIf
	
	If upToDate
		return version + "." + versionMinor + "." + versionBeta
	Else
		return ""
	EndIf

EndFunction


ObjectMod[] Function IsF4SEScriptPresent_Actor( String asModPrefix, String asPluginName ) global

	Form XMarker = Game.GetFormFromFile( 0x0000003B, "Fallout4.esm" )
	Form EncSecurityDiamondCityTemplate00 = Game.GetFormFromFile( 0x00002F63, "Fallout4.esm" )
	Form AssaultRifle = Game.GetFormFromFile( 0x0000463F, "Fallout4.esm" )
	ObjectMod[] res
	
	ObjectReference XMarkerRef = Game.GetPlayer().PlaceAtMe( XMarker )
	If XMarkerRef
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Actor", "marker created at player" )
		XMarkerRef.SetPosition( XMarkerRef.GetPositionX() + 5000.0, XMarkerRef.GetPositionY() + 5000.0, XMarkerRef.GetPositionZ() - 5000.0 )
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Actor", "marker moved away" )
		Actor TestNPCRef = XMarkerRef.PlaceAtMe( EncSecurityDiamondCityTemplate00 ) as Actor
		If TestNPCRef
			DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Actor", "test NPC " + GetFormInfo( asModPrefix, TestNPCRef ) + " created at marker" )
			XMarkerRef.Disable()
			DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Actor", "marker disabled" )
			XMarkerRef.Delete()
			DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Actor", "marker deleted" )
			TestNPCRef.EquipItem( AssaultRifle )
			DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Actor", "test NPC " + GetFormInfo( asModPrefix, TestNPCRef ) + " equipped with weapon " + GetFormInfo( asModPrefix, AssaultRifle ) )
			Bool somethingEquipped = False
			Int i = 0
			While i <= 43 && !somethingEquipped
			DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Actor", "attempting to call GetWornItemMods( " + i + " ) on test NPC " + GetFormInfo( asModPrefix, TestNPCRef ) )
			res = TestNPCRef.GetWornItemMods( i )
				If res.Length > 0
					somethingEquipped = True
					Int j = 0
					While j < res.Length
						DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Actor", "WornItemMod " + j + " at slot " + i + " is " + GetFormInfo( asModPrefix, res[j] ) )
						j += 1
					EndWhile
				Else
					DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Actor", "there are no WornItemMods at slot " + i )
				EndIf
				i += 1
			EndWhile
			TestNPCRef.Disable()
			DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Actor", "test NPC " + GetFormInfo( asModPrefix, TestNPCRef ) + " disabled" )
			TestNPCRef.Delete()
			DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Actor", "test NPC " + GetFormInfo( asModPrefix, EncSecurityDiamondCityTemplate00 ) + " deleted" )
		Else
			DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Actor", "failed to create test NPC " + GetFormInfo( asModPrefix, EncSecurityDiamondCityTemplate00 ), -1, 1 )
			XMarkerRef.Disable()
			DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Actor", "marker disabled" )
			XMarkerRef.Delete()
			DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Actor", "marker deleted" )
			return None
		EndIf
	Else
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Actor", "failed to create marker", -1, 1 )
		return None
	EndIf
	
	return res

EndFunction


HeadPart[] Function IsF4SEScriptPresent_ActorBase( String asModPrefix, String asPluginName ) global

	ActorBase Natalie = Game.GetFormFromFile( 0x00002F20, "Fallout4.esm" ) as ActorBase
	HeadPart[] res
	DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ActorBase", "attempting to call GetHeadParts() on " + GetFormInfo( asModPrefix, Natalie ) )
	res = Natalie.GetHeadParts()
	If res.Length > 0
		Int i = 0
		While i < res.Length
			DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ActorBase", "HeadPart " + i + " is " + GetFormInfo( asModPrefix, res[i] ) )
			i += 1
		EndWhile
	Else
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ActorBase", "there are no HeadParts", -1, 1 )
	EndIf
	return res

EndFunction


ScriptObject Function IsF4SEScriptPresent_ArmorAddon( String asModPrefix, String asPluginName ) global

	Form AAArmorBoSCade = Game.GetFormFromFile( 0x001F1A7D, "Fallout4.esm" )
	ScriptObject res
	DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ArmorAddon", "attempting to cast " + GetFormInfo( asModPrefix, AAArmorBoSCade ) + " as an ArmorAddon script" )
	res = AAArmorBoSCade.CastAs( "ArmorAddon" )
	If res
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ArmorAddon", "successful casting" )
	Else
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ArmorAddon", "casting failed", -1, 1 )
	EndIf
	return res

EndFunction


Form Function IsF4SEScriptPresent_Cell( String asModPrefix, String asPluginName ) global
	
	Cell DBTechHighSchool02 = Game.GetFormFromFile( 0x000E214D, "Fallout4.esm" ) as Cell
	Form res
	DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Cell", "attempting to call GetWaterType() on " + GetFormInfo( asModPrefix, DBTechHighSchool02 ) )
	res = DBTechHighSchool02.CallFunction( "GetWaterType", New Var[0] ) as Form
	If res
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Cell", "WaterType is " + GetFormInfo( asModPrefix, res ) )
	Else
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Cell", "there is no WaterType", -1, 1 )
	EndIf
	return res

EndFunction


MiscObject Function IsF4SEScriptPresent_Component( String asModPrefix, String asPluginName ) global

	Component c_Acid = Game.GetFormFromFile( 0x0001FA8C, "Fallout4.esm" ) as Component
	MiscObject res
	DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Component", "attempting to call GetScrapItem() on " + GetFormInfo( asModPrefix, c_Acid ) )
	res = c_Acid.CallFunction( "GetScrapItem", None ) as MiscObject
	If res
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Component", "MiscObject is " + GetFormInfo( asModPrefix, res ) )
	Else
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Component", "there is no MiscObject", -1, 1 )
	EndIf
	return res

EndFunction


Form Function IsF4SEScriptPresent_ConstructibleObject( String asModPrefix, String asPluginName ) global

	ConstructibleObject workshop_co_GuardTower = Game.GetFormFromFile( 0x000192F2, "Fallout4.esm" ) as ConstructibleObject
	Form res
	DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ConstructibleObject", "attempting to call GetCreatedObject() on " + GetFormInfo( asModPrefix, workshop_co_GuardTower ) )
	res = workshop_co_GuardTower.CallFunction( "GetCreatedObject", None ) as Form
	If res
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ConstructibleObject", "created Form is " + GetFormInfo( asModPrefix, res ) )
	Else
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ConstructibleObject", "there is no created Form", -1, 1 )
	EndIf
	return res

EndFunction


ScriptObject Function IsF4SEScriptPresent_DefaultObject( String asModPrefix, String asPluginName ) global

	Form HoursToRespawnCellClearedMult_DO = Game.GetFormFromFile( 0x000008B6, "Fallout4.esm" )
	ScriptObject res
	DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_DefaultObject", "attempting to cast " + GetFormInfo( asModPrefix, HoursToRespawnCellClearedMult_DO ) + " as a DefaultObject script" )
	res = HoursToRespawnCellClearedMult_DO.CastAs( "DefaultObject" )
	If res
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_DefaultObject", "successful casting" )
	Else
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_DefaultObject", "casting failed", -1, 1 )
	EndIf
	return res

EndFunction


Location Function IsF4SEScriptPresent_EncounterZone( String asModPrefix, String asPluginName ) global

	EncounterZone ConcordMuseumZone = Game.GetFormFromFile( 0x00017E01, "Fallout4.esm" ) as EncounterZone
	Location res
	DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_EncounterZone", "attempting to call GetLocation() on " + GetFormInfo( asModPrefix, ConcordMuseumZone ) )
	res = ConcordMuseumZone.CallFunction( "GetLocation", None ) as Location
	If res
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_EncounterZone", "Location is " + GetFormInfo( asModPrefix, res ) )
	Else
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_EncounterZone", "there is no Location", -1, 1 )
	EndIf
	return res

EndFunction


ScriptObject Function IsF4SEScriptPresent_EquipSlot( String asModPrefix, String asPluginName ) global

	Form EitherHand = Game.GetFormFromFile( 0x00013F44, "Fallout4.esm" )
	ScriptObject res
	DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_EquipSlot", "attempting to cast " + GetFormInfo( asModPrefix, EitherHand ) + " as an EquipSlot script" )
	res = EitherHand.CastAs( "EquipSlot" )
	If res
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_EquipSlot", "successful casting" )
	Else
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_EquipSlot", "casting failed", -1, 1 )
	EndIf
	return res

EndFunction


Form[] Function IsF4SEScriptPresent_FavoritesManager( String asModPrefix, String asPluginName ) global

	Form[] res
	DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_FavoritesManager", "attempting to call FavoritesManager.GetFavorites()" )
	res = FavoritesManager.GetFavorites()
	If res.Length > 0
		Int i = 0
		While i < res.Length
			DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_FavoritesManager", "Favorite " + i + " is " + GetFormInfo( asModPrefix, res[i] ) )
			i += 1
		EndWhile
	Else
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_FavoritesManager", "there are no Favorites", -1, 1 )
	EndIf
	return res

EndFunction


Bool Function IsF4SEScriptPresent_Form( String asModPrefix, String asPluginName ) global

	Form DefaultAshPile1 = Game.GetFormFromFile( 0x0000001B, "Fallout4.esm" )
	String res
	DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Form", "attempting to call GetName() on " + GetFormInfo( asModPrefix, DefaultAshPile1 ) )
	res = DefaultAshPile1.CallFunction( "GetName", None ) as String
	If res && res != "None"
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Form", "name is " + res )
	Else
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Form", "there is no name", -1, 1 )
		return False
	EndIf
	return True

EndFunction


String[] Function IsF4SEScriptPresent_Game( String asModPrefix, String asPluginName ) global

	String[] res
	DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Game", "attempting to call Game.GetPluginDependencies() on " + asPluginName )
	res = Game.GetPluginDependencies( asPluginName )
	If res.Length > 0
		Int i = 0
		While i < res.Length
			DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Game", "dependency " + i + " is " + res[i] )
			i += 1
		EndWhile
	Else
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Game", "there are no dependencies", -1, 1 )
	EndIf
	return res

EndFunction


Int Function IsF4SEScriptPresent_HeadPart( String asModPrefix, String asPluginName ) global

	HeadPart MaleHeadHuman = Game.GetFormFromFile( 0x0001EEBB, "Fallout4.esm" ) as HeadPart
	Int res
	DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_HeadPart", "attempting to get Type_HeadRear property from " + GetFormInfo( asModPrefix, MaleHeadHuman ) )
	res = MaleHeadHuman.GetPropertyValue( "Type_HeadRear" ) as Int
	If res
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_HeadPart", "Type_HeadRear property is " + res )
	Else
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_HeadPart", "there is no Type_HeadRear property", -1, 1 )
	EndIf
	return res

EndFunction


Int Function IsF4SEScriptPresent_Input( String asModPrefix, String asPluginName ) global

	Int res
	DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Input", "attempting to call Input.GetMappedKey( 'Sneak' )" )
	res = Input.GetMappedKey( "Sneak" )
	If res
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Input", "MappedKey for Sneak is " + res )
	Else
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Input", "there is no MappedKey for Sneak", -1, 1 )
	EndIf
	return res

EndFunction


Location Function IsF4SEScriptPresent_Location( String asModPrefix, String asPluginName ) global

	Location DiamondCityAllFaithsChapelLocation = Game.GetFormFromFile( 0x00003953, "Fallout4.esm" ) as Location
	Location res
	DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Location", "attempting to call GetParent() on " + GetFormInfo( asModPrefix, DiamondCityAllFaithsChapelLocation ) )
	res = DiamondCityAllFaithsChapelLocation.CallFunction( "GetParent", None ) as Location
	If res
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Location", "parent Location is " + GetFormInfo( asModPrefix, res ) )
	Else
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Location", "there is no parent Location", -1, 1 )
	EndIf
	return res

EndFunction


Float Function IsF4SEScriptPresent_Math( String asModPrefix, String asPluginName ) global

	Float res
	DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Math", "attempting to call Math.LogicalOr( 1, 0 )" )
	res = Math.LogicalOr( 1, 0 )
	If res
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Math", "Math.LogicalOr( 1, 0 ) is " + res )
	Else
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Math", "there is no Math.LogicalOr( 1, 0 )", -1, 1 )
	EndIf
	return res

EndFunction


MiscObject Function IsF4SEScriptPresent_ObjectMod( String asModPrefix, String asPluginName ) global

	ObjectMod mod_LaserGun_Muzzle_Splitter_A = Game.GetFormFromFile( 0x00020BD1, "Fallout4.esm" ) as ObjectMod
	MiscObject res
	DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ObjectMod", "attempting to call GetLooseMod() on " + GetFormInfo( asModPrefix, mod_LaserGun_Muzzle_Splitter_A ) )
	res = mod_LaserGun_Muzzle_Splitter_A.CallFunction( "GetLooseMod", None ) as MiscObject
	If res
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ObjectMod", "LooseMod is " + GetFormInfo( asModPrefix, res ) )
	Else
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ObjectMod", "there is no LooseMod", -1, 1 )
	EndIf
	return res

EndFunction


Bool Function IsF4SEScriptPresent_ObjectReference( String asModPrefix, String asPluginName ) global

	String res
	DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ObjectReference", "attempting to call GetDisplayName() on " + GetFormInfo( asModPrefix, Game.GetPlayer() ) )
	res = Game.GetPlayer().CallFunction( "GetDisplayName", None ) as String
	If res && res != "None"
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ObjectReference", "display name is " + res )
	Else
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ObjectReference", "there is no display name", -1, 1 )
		return False
	EndIf
	return True

EndFunction


Bool Function IsF4SEScriptPresent_Perk( String asModPrefix, String asPluginName ) global

	Perk LadyKiller01 = Game.GetFormFromFile( 0x00019AA3, "Fallout4.esm" ) as Perk
	Bool res
	DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Perk", "attempting to call IsPlayable() on " + GetFormInfo( asModPrefix, LadyKiller01 ) )
	res = LadyKiller01.CallFunction( "IsPlayable", None ) as Bool
	If res
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Perk", "playable" )
	Else
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Perk", "not playable", -1, 1 )
		return False
	EndIf
	return True

EndFunction


Bool Function IsF4SEScriptPresent_ScriptObject( String asModPrefix, String asPluginName ) global

	{ THIS DOESN'T WORK YET! }
	
	ScriptObject Logger = Game.GetFormFromFile( 0x01000812, asPluginName ).CastAs( asModPrefix + "_Logger" )
	Form XMarker = Game.GetFormFromFile( 0x0000003B, "Fallout4.esm" )
	Form Mq101Newscaster = Game.GetFormFromFile( 0x001F0719, "Fallout4.esm" )
	Form NpcChairFederalistOfficeSit01 = Game.GetFormFromFile( 0x0001F88B, "Fallout4.esm" )
	Form TeddyBear = Game.GetFormFromFile( 0x00059B14, "Fallout4.esm" )
	Keyword LinkCustom01 = Game.GetFormFromFile( 0x0005D5E6, "Fallout4.esm" ) as Keyword
	GlobalVariable F4SEScriptInstalled_ScriptObject = Game.GetFormFromFile( 0x01000880, asPluginName ) as GlobalVariable
	F4SEScriptInstalled_ScriptObject.SetValue( 0.0 )
	Int i
	Bool res = False
	Var[] params1 = New Var[1]

	ObjectReference XMarker0Ref = Game.GetPlayer().PlaceAtMe( XMarker )
	ObjectReference XMarkerRef
	ObjectReference ChairRef
	If XMarker0Ref
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "marker 0 created at player" )
		XMarkerRef = XMarker0Ref.PlaceAtMe( XMarker )
		If XMarkerRef
			DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "marker created at marker 0" )
			XMarkerRef.SetPosition( XMarkerRef.GetPositionX() + 5000.0, XMarkerRef.GetPositionY() + 5000.0, XMarkerRef.GetPositionZ() + 5000.0 )
			DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "marker moved away by x:5000.0, y:5000.0, z:5000.0 from marker 0" )
			ObjectReference TeddyBearRef = XMarkerRef.PlaceAtMe( TeddyBear )
			If TeddyBearRef
				DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "Teddy Bear " + GetFormInfo( asModPrefix, TeddyBearRef ) + " created at marker" )
				Float TeddyBearPositionZ = TeddyBearRef.GetPositionZ()
				Float speed_old = 0
				Float speed_new = 0
				Float time_old = Utility.GetCurrentRealTime()
				Float time_new = Utility.GetCurrentRealTime() + 0.1
				i = 0
				While i < 150 && speed_new >= speed_old
					DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "waiting a maximum of " + (150 * (time_new - time_old)) + "s for Teddy Bear " + GetFormInfo( asModPrefix, TeddyBearRef ) + " to fall on the ground - " + (i * (time_new - time_old)) + "s, current speed: " + speed_new + " km/h" )
					speed_old = speed_new
					time_old = time_new
					;Utility.Wait( 0.1 )
					Utility.Wait( 1.0 )
					time_new = Utility.GetCurrentRealTime()
					speed_new = 3600 * (((TeddyBearPositionZ - TeddyBearRef.GetPositionZ()) / 142800) / (time_new - time_old))
					i += 1
				EndWhile
				Float[] safePositionArray = TeddyBearRef.GetSafePosition( 5000.0 )
				If safePositionArray
					XMarkerRef.SetPosition( safePositionArray[0], safePositionArray[1], safePositionArray[2] )
					DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "marker moved away, it's by x:" + (Game.GetPlayer().GetPositionX() - safePositionArray[0]) + ", y:" + (Game.GetPlayer().GetPositionY() - safePositionArray[1]) + ", z:" + (Game.GetPlayer().GetPositionZ() - safePositionArray[2]) + " from the player" )
				Else
					DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "marker can't be moved to a safe position, searching for nearest navmesh location", -1, 1 )
					If speed_new < speed_old
						TeddyBearRef.MoveToNearestNavmeshLocation()
						DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "Teddy Bear " + GetFormInfo( asModPrefix, TeddyBearRef ) + " moved to the nearest navmesh location" )
						XMarkerRef.MoveTo( TeddyBearRef )
						DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "marker moved to Teddy Bear " + GetFormInfo( asModPrefix, TeddyBearRef ) + ", it's by x:" + (Game.GetPlayer().GetPositionX() - XMarkerRef.GetPositionX()) + ", y:" + (Game.GetPlayer().GetPositionY() - XMarkerRef.GetPositionY()) + ", z:" + (Game.GetPlayer().GetPositionZ() - XMarkerRef.GetPositionZ()) + " from the player" )
					Else
						DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "Teddy Bear " + GetFormInfo( asModPrefix, TeddyBearRef ) + " didn't stop falling", -1, 1 )
						ObjectReference XMarker2Ref = XMarkerRef.PlaceAtMe( XMarker )
						If XMarker2Ref
							DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "marker 2 created at marker" )
							XMarkerRef.MoveToNearestNavmeshLocation()
							DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "marker moved to the nearest navmesh location" )
							Float dist = XMarkerRef.GetDistance( XMarker2Ref )
							If dist < 100.0
								DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "marker couldn't be moved to a navmesh location, distance between markers: " + dist, -1, 1 )
								XMarkerRef.MoveTo( XMarker0Ref )
								DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "marker moved back to marker 0" )
							EndIf
							XMarker2Ref.Disable()
							DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "marker 2 disabled" )
							XMarker2Ref.Delete()
							DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "marker 2 deleted" )
						Else
							DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "failed to create marker 2", -1, 1 )
							XMarkerRef.MoveTo( XMarker0Ref )
							DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "marker moved back to marker 0" )
						EndIf
					EndIf
					TeddyBearRef.Disable()
					DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "Teddy Bear " + GetFormInfo( asModPrefix, TeddyBearRef ) + " disabled" )
					TeddyBearRef.Delete()
					DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "Teddy Bear " + GetFormInfo( asModPrefix, TeddyBear ) + " deleted" )
				EndIf
				ChairRef = XMarkerRef.PlaceAtMe( NpcChairFederalistOfficeSit01 )
				If ChairRef
					DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "chair " + GetFormInfo( asModPrefix, ChairRef ) + " created at marker" )
					;Game.GetPlayer().MoveTo( XMarkerRef )
					;DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "Player moved to marker" )
					;Utility.Wait( 10.0 )
					XMarkerRef.Disable()
					DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "marker disabled" )
					XMarkerRef.Delete()
					DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "marker deleted" )
					Actor TestNPCRef = ChairRef.PlaceAtMe( Mq101Newscaster ) as Actor
					If TestNPCRef
						DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "test NPC " + GetFormInfo( asModPrefix, TestNPCRef ) + " created at chair " + GetFormInfo( asModPrefix, ChairRef ) )
						TestNPCRef.GetActorBase().SetInvulnerable()
						DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "test NPC " + GetFormInfo( asModPrefix, TestNPCRef ) + " turned invulnerable" )
						TestNPCRef.SetAlpha( 0.0 )
						DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "test NPC " + GetFormInfo( asModPrefix, TestNPCRef ) + " turned invisible" )
						Utility.Wait( 1.0 )
						ChairRef.MoveTo( TestNPCRef )
						DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "chair " + GetFormInfo( asModPrefix, ChairRef ) + " moved to test NPC " + GetFormInfo( asModPrefix, TestNPCRef ) )
						Utility.Wait( 3.0 )
						If ChairRef.GetDistance( TestNPCRef ) > 300.0
							DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "test NPC " + GetFormInfo( asModPrefix, TestNPCRef ) + " is probably still falling", -1, 1 )
							ChairRef.MoveTo( XMarker0Ref )
							DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "chair " + GetFormInfo( asModPrefix, ChairRef ) + " moved back to marker 0" )
							TestNPCRef.MoveTo( ChairRef )
							DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "test NPC " + GetFormInfo( asModPrefix, TestNPCRef ) + " moved to chair " + GetFormInfo( asModPrefix, ChairRef ) )
						EndIf
						XMarker0Ref.Disable()
						DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "marker 0 disabled" )
						XMarker0Ref.Delete()
						DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "marker 0 deleted" )
						F4SEScriptInstalled_ScriptObject.SetValue( 0.0 )
						params1[0] = TestNPCRef as ObjectReference
						Logger.CallFunction( "DoRegisterForFurnitureEvent", params1 )
						DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "registered to FurnitureEvent of " + GetFormInfo( asModPrefix, ChairRef ) )
						TestNPCRef.SetLinkedRef( ChairRef, LinkCustom01 )
						DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "test NPC " + GetFormInfo( asModPrefix, TestNPCRef ) + " linked to chair " + GetFormInfo( asModPrefix, ChairRef ) + " with keyword " + GetFormInfo( asModPrefix, LinkCustom01 ) )
						i = 0
						While i < 30 && F4SEScriptInstalled_ScriptObject.GetValue() == 0.0
							DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "waiting a maximum of 30s for test NPC " + GetFormInfo( asModPrefix, TestNPCRef ) + " to sit down to chair " + GetFormInfo( asModPrefix, ChairRef ) + " - " + i + "s" )
							Utility.Wait( 1.0 )
							i += 1
						EndWhile
						If F4SEScriptInstalled_ScriptObject.GetValue() == 1.0
							res = True
							DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "FurnitureEvent caught successfully" )
						Else
							DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "failed to catch FurnitureEvent" )
						EndIf
						TestNPCRef.GetActorBase().SetInvulnerable( False )
						DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "test NPC " + GetFormInfo( asModPrefix, TestNPCRef ) + " turned vulnerable" )
						TestNPCRef.Disable()
						DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "test NPC " + GetFormInfo( asModPrefix, TestNPCRef ) + " disabled" )
						TestNPCRef.Delete()
						DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "test NPC " + GetFormInfo( asModPrefix, Mq101Newscaster ) + " deleted" )
						ChairRef.Disable()
						DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "chair " + GetFormInfo( asModPrefix, ChairRef ) + " disabled" )
						ChairRef.Delete()
						DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "chair " + GetFormInfo( asModPrefix, NpcChairFederalistOfficeSit01 ) + " deleted" )
					Else
						DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "failed to create test NPC " + GetFormInfo( asModPrefix, Mq101Newscaster ), -1, 1 )
						ChairRef.Disable()
						DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "chair " + GetFormInfo( asModPrefix, ChairRef ) + " disabled" )
						ChairRef.Delete()
						DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "chair " + GetFormInfo( asModPrefix, NpcChairFederalistOfficeSit01 ) + " deleted" )
						return res
					EndIf
				Else
					DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "failed to create chair " + GetFormInfo( asModPrefix, NpcChairFederalistOfficeSit01 ), -1, 1 )
					XMarkerRef.Disable()
					DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "marker disabled" )
					XMarkerRef.Delete()
					DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "marker deleted" )
					XMarker0Ref.Disable()
					DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "marker 0 disabled" )
					XMarker0Ref.Delete()
					DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "marker 0 deleted" )
					return res
				EndIf
			Else
				DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "failed to create Teddy Bear " + GetFormInfo( asModPrefix, TeddyBear ), -1, 1 )
				XMarkerRef.Disable()
				DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "marker disabled" )
				XMarkerRef.Delete()
				DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "marker deleted" )
				XMarker0Ref.Disable()
				DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "marker 0 disabled" )
				XMarker0Ref.Delete()
				DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "marker 0 deleted" )
				return res
			EndIf
		Else
			DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "failed to create marker", -1, 1 )
			XMarker0Ref.Disable()
			DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "marker 0 disabled" )
			XMarker0Ref.Delete()
			DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "marker 0 deleted" )
			return res
		EndIf
	Else
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_ScriptObject", "failed to create marker 0", -1, 1 )
		return res
	EndIf
	return res

EndFunction


Bool Function IsF4SEScriptPresent_UI( String asModPrefix, String asPluginName ) global

	Bool res
	DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_UI", "attempting to call UI.IsMenuRegistered( 'HUDMenu' )" )
	res = UI.IsMenuRegistered( "HUDMenu" )
	If res
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_UI", "HUDMenu registered" )
		return True
	Else
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_UI", "HUDMenu not registered", -1, 1 )
		return False
	EndIf
	return res

EndFunction


Var Function IsF4SEScriptPresent_Utility( String asModPrefix, String asPluginName ) global

	Var res
	Var[] v = New Var[1]
	v[0] = 10
	DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Utility", "attempting to call Utility.VarArrayToVar() on a Var Array" )
	res = Utility.VarArrayToVar( v )
	If res
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Utility", "successful conversion" )
	Else
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Utility", "conversion failed", -1, 1 )
	EndIf
	return res

EndFunction


ScriptObject Function IsF4SEScriptPresent_WaterType( String asModPrefix, String asPluginName ) global

	Form PurifiedWater = Game.GetFormFromFile( 0x000C8975, "Fallout4.esm" )
	ScriptObject res
	DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_WaterType", "attempting to cast " + GetFormInfo( asModPrefix, PurifiedWater ) + " as a WaterType script" )
	res = PurifiedWater.CastAs( "WaterType" )
	If res
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_WaterType", "successful casting" )
	Else
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_WaterType", "casting failed", -1, 1 )
	EndIf
	return res

EndFunction


ObjectMod Function IsF4SEScriptPresent_Weapon( String asModPrefix, String asPluginName ) global

	Weapon FusionCoreKnightWeapon = Game.GetFormFromFile( 0x000865E9, "Fallout4.esm" ) as Weapon
	ObjectMod res
	DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Weapon", "attempting to call GetEmbeddedMod() on " + GetFormInfo( asModPrefix, FusionCoreKnightWeapon ) )
	res = FusionCoreKnightWeapon.CallFunction( "GetEmbeddedMod", None ) as ObjectMod
	If res
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Weapon", "EmbeddedMod is " + GetFormInfo( asModPrefix, res ) )
	Else
		DebugMsg( asModPrefix, asPluginName, "IsF4SEScriptPresent_Weapon", "there is no EmbeddedMod", -1, 1 )
	EndIf
	return res

EndFunction


String[] Function CollectRequiredF4SEScriptsThatMissing( Quest akConfigQuest, String asModPrefix, Bool abFixedArray = False ) global

	String[] res
	String[] res_ = New String[29]
	String[] res__ = New String[29]
	Int countMissing = 0
	Int countAll = 0
	String scriptPath
	Var[] params2 = New Var[2]
	Bool isWaterTypeAlreadyChecked = False
	Bool isWaterTypeMissing = False
	
	ScriptObject Config = akConfigQuest.CastAs( asModPrefix + "_Config" )
	String pluginName = (Config.GetPropertyValue( "PluginName" ) as String) + "." + (Config.GetPropertyValue( "FileType" ) as String)
	
	If Config.GetPropertyValue( "F4SERequiredScript_Actor" ) as Bool
		scriptPath = "Data/Scripts/Actor.pex"
		DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", "checking for " + scriptPath )
		If IsF4SEScriptPresent_Actor( asModPrefix, pluginName )
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " found" )
			res__[countAll] = ""
			countAll += 1
		Else
			res__[countAll] = scriptPath
			countAll += 1
			res_[countMissing] = scriptPath
			countMissing += 1
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " not found", -1, 1 )
		EndIf
	Else
		res__[countAll] = ""
		countAll += 1
	EndIf
	
	If Config.GetPropertyValue( "F4SERequiredScript_ActorBase" ) as Bool
		scriptPath = "Data/Scripts/ActorBase.pex"
		DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", "checking for " + scriptPath )
		If IsF4SEScriptPresent_ActorBase( asModPrefix, pluginName )
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " found" )
			res__[countAll] = ""
			countAll += 1
		Else
			res__[countAll] = scriptPath
			countAll += 1
			res_[countMissing] = scriptPath
			countMissing += 1
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " not found", -1, 1 )
		EndIf
	Else
		res__[countAll] = ""
		countAll += 1
	EndIf
	
	If Config.GetPropertyValue( "F4SERequiredScript_ArmorAddon" ) as Bool || Config.GetPropertyValue( "F4SERequiredScript_Armor" ) as Bool
		scriptPath = "Data/Scripts/ArmorAddon.pex"
		DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", "checking for " + scriptPath )
		If IsF4SEScriptPresent_ArmorAddon( asModPrefix, pluginName )
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " found" )
			If Config.GetPropertyValue( "F4SERequiredScript_Armor" ) as Bool
				scriptPath = "Data/Scripts/Armor.pex"
				DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", "checking for " + scriptPath )
				params2[0] = asModPrefix as String
				params2[1] = pluginName as String
				If Utility.CallGlobalFunction( asModPrefix + "_Maintenance:ArmorCheck", "IsF4SEScriptPresent_Armor", params2 )
					DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " found" )
					res__[countAll] = ""
					countAll += 1
					res__[countAll] = ""
					countAll += 1
				Else
					res__[countAll] = scriptPath
					countAll += 1
					res__[countAll] = ""
					countAll += 1
					res_[countMissing] = scriptPath
					countMissing += 1
					DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " not found", -1, 1 )
				EndIf
			EndIf
		Else
			res__[countAll] = ""
			countAll += 1
			res__[countAll] = scriptPath
			countAll += 1
			res_[countMissing] = scriptPath
			countMissing += 1
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " not found", -1, 1 )
		EndIf
	Else
		res__[countAll] = ""
		countAll += 1
		res__[countAll] = ""
		countAll += 1
	EndIf
	
	If Config.GetPropertyValue( "F4SERequiredScript_Cell" ) as Bool
		scriptPath = "Data/Scripts/Cell.pex"
		DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", "checking for " + scriptPath )
		If IsF4SEScriptPresent_Cell( asModPrefix, pluginName )
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " found" )
			res__[countAll] = ""
			countAll += 1
		Else
			String scriptPath2 = "Data/Scripts/WaterType.pex"
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", "checking for " + scriptPath2 )
			isWaterTypeAlreadyChecked = True
			If IsF4SEScriptPresent_WaterType( asModPrefix, pluginName )
				res__[countAll] = scriptPath
				countAll += 1
				res_[countMissing] = scriptPath
				countMissing += 1
				DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath2 + " found" )
				DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " not found", -1, 1 )
			Else
				isWaterTypeMissing = True
				res__[countAll] = ""
				countAll += 1
				DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath2 + " not found", -1, 1 )
				DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " unknown" )
			EndIf
		EndIf
	Else
		res__[countAll] = ""
		countAll += 1
	EndIf
	
	If Config.GetPropertyValue( "F4SERequiredScript_Component" ) as Bool
		scriptPath = "Data/Scripts/Component.pex"
		DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", "checking for " + scriptPath )
		If IsF4SEScriptPresent_Component( asModPrefix, pluginName )
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " found" )
			res__[countAll] = ""
			countAll += 1
		Else
			res__[countAll] = scriptPath
			countAll += 1
			res_[countMissing] = scriptPath
			countMissing += 1
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " not found", -1, 1 )
		EndIf
	Else
		res__[countAll] = ""
		countAll += 1
	EndIf
	
	If Config.GetPropertyValue( "F4SERequiredScript_ConstructibleObject" ) as Bool
		scriptPath = "Data/Scripts/ConstructibleObject.pex"
		DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", "checking for " + scriptPath )
		If IsF4SEScriptPresent_ConstructibleObject( asModPrefix, pluginName )
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " found" )
			res__[countAll] = ""
			countAll += 1
		Else
			res__[countAll] = scriptPath
			countAll += 1
			res_[countMissing] = scriptPath
			countMissing += 1
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " not found", -1, 1 )
		EndIf
	Else
		res__[countAll] = ""
		countAll += 1
	EndIf
	
	If Config.GetPropertyValue( "F4SERequiredScript_DefaultObject" ) as Bool
		scriptPath = "Data/Scripts/DefaultObject.pex"
		DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", "checking for " + scriptPath )
		If IsF4SEScriptPresent_DefaultObject( asModPrefix, pluginName )
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " found" )
			res__[countAll] = ""
			countAll += 1
		Else
			res__[countAll] = scriptPath
			countAll += 1
			res_[countMissing] = scriptPath
			countMissing += 1
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " not found", -1, 1 )
		EndIf
	Else
		res__[countAll] = ""
		countAll += 1
	EndIf
	
	If Config.GetPropertyValue( "F4SERequiredScript_EncounterZone" ) as Bool
		scriptPath = "Data/Scripts/EncounterZone.pex"
		DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", "checking for " + scriptPath )
		If IsF4SEScriptPresent_EncounterZone( asModPrefix, pluginName )
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " found" )
			res__[countAll] = ""
			countAll += 1
		Else
			res__[countAll] = scriptPath
			countAll += 1
			res_[countMissing] = scriptPath
			countMissing += 1
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " not found", -1, 1 )
		EndIf
	Else
		res__[countAll] = ""
		countAll += 1
	EndIf
	
	If Config.GetPropertyValue( "F4SERequiredScript_EquipSlot" ) as Bool
		scriptPath = "Data/Scripts/EquipSlot.pex"
		DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", "checking for " + scriptPath )
		If IsF4SEScriptPresent_EquipSlot( asModPrefix, pluginName )
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " found" )
			res__[countAll] = ""
			countAll += 1
		Else
			res__[countAll] = scriptPath
			countAll += 1
			res_[countMissing] = scriptPath
			countMissing += 1
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " not found", -1, 1 )
		EndIf
	Else
		res__[countAll] = ""
		countAll += 1
	EndIf
	
	If Config.GetPropertyValue( "F4SERequiredScript_F4SE" ) as Bool
		scriptPath = "Data/Scripts/F4SE.pex"
		DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", "checking for " + scriptPath )
		If GetF4SEVersionString() != "0.0.0"
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " found" )
			res__[countAll] = ""
			countAll += 1
		Else
			res__[countAll] = scriptPath
			countAll += 1
			res_[countMissing] = scriptPath
			countMissing += 1
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " not found", -1, 1 )
		EndIf
	Else
		res__[countAll] = ""
		countAll += 1
	EndIf
	
	If Config.GetPropertyValue( "F4SERequiredScript_FavoritesManager" ) as Bool
		scriptPath = "Data/Scripts/FavoritesManager.pex"
		DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", "checking for " + scriptPath )
		If IsF4SEScriptPresent_FavoritesManager( asModPrefix, pluginName )
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " found" )
			res__[countAll] = ""
			countAll += 1
		Else
			res__[countAll] = scriptPath
			countAll += 1
			res_[countMissing] = scriptPath
			countMissing += 1
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " not found", -1, 1 )
		EndIf
	Else
		res__[countAll] = ""
		countAll += 1
	EndIf
	
	If Config.GetPropertyValue( "F4SERequiredScript_Form" ) as Bool
		scriptPath = "Data/Scripts/Form.pex"
		DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", "checking for " + scriptPath )
		If IsF4SEScriptPresent_Form( asModPrefix, pluginName )
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " found" )
			res__[countAll] = ""
			countAll += 1
		Else
			res__[countAll] = scriptPath
			countAll += 1
			res_[countMissing] = scriptPath
			countMissing += 1
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " not found", -1, 1 )
		EndIf
	Else
		res__[countAll] = ""
		countAll += 1
	EndIf
	
	If Config.GetPropertyValue( "F4SERequiredScript_Game" ) as Bool
		scriptPath = "Data/Scripts/Game.pex"
		DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", "checking for " + scriptPath )
		If IsF4SEScriptPresent_Game( asModPrefix, pluginName )
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " found" )
			res__[countAll] = ""
			countAll += 1
		Else
			res__[countAll] = scriptPath
			countAll += 1
			res_[countMissing] = scriptPath
			countMissing += 1
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " not found", -1, 1 )
		EndIf
	Else
		res__[countAll] = ""
		countAll += 1
	EndIf
	
	If Config.GetPropertyValue( "F4SERequiredScript_HeadPart" ) as Bool
		scriptPath = "Data/Scripts/HeadPart.pex"
		DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", "checking for " + scriptPath )
		If IsF4SEScriptPresent_HeadPart( asModPrefix, pluginName )
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " found" )
			res__[countAll] = ""
			countAll += 1
		Else
			res__[countAll] = scriptPath
			countAll += 1
			res_[countMissing] = scriptPath
			countMissing += 1
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " not found", -1, 1 )
		EndIf
	Else
		res__[countAll] = ""
		countAll += 1
	EndIf
	
	If Config.GetPropertyValue( "F4SERequiredScript_Input" ) as Bool
		scriptPath = "Data/Scripts/Input.pex"
		DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", "checking for " + scriptPath )
		If IsF4SEScriptPresent_Input( asModPrefix, pluginName )
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " found" )
			res__[countAll] = ""
			countAll += 1
		Else
			res__[countAll] = scriptPath
			countAll += 1
			res_[countMissing] = scriptPath
			countMissing += 1
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " not found", -1, 1 )
		EndIf
	Else
		res__[countAll] = ""
		countAll += 1
	EndIf
	
	If Config.GetPropertyValue( "F4SERequiredScript_InstanceData" ) as Bool
		scriptPath = "Data/Scripts/InstanceData.pex"
		DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", "checking for " + scriptPath )
		params2[0] = asModPrefix as String
		params2[1] = pluginName as String
		If Utility.CallGlobalFunction( asModPrefix + "_Maintenance:InstanceDataCheck", "IsF4SEScriptPresent_InstanceData", params2 )
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " found" )
			res__[countAll] = ""
			countAll += 1
		Else
			res__[countAll] = scriptPath
			countAll += 1
			res_[countMissing] = scriptPath
			countMissing += 1
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " not found", -1, 1 )
		EndIf
	Else
		res__[countAll] = ""
		countAll += 1
	EndIf
	
	If Config.GetPropertyValue( "F4SERequiredScript_Location" ) as Bool
		scriptPath = "Data/Scripts/Location.pex"
		DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", "checking for " + scriptPath )
		If IsF4SEScriptPresent_Location( asModPrefix, pluginName )
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " found" )
			res__[countAll] = ""
			countAll += 1
		Else
			res__[countAll] = scriptPath
			countAll += 1
			res_[countMissing] = scriptPath
			countMissing += 1
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " not found", -1, 1 )
		EndIf
	Else
		res__[countAll] = ""
		countAll += 1
	EndIf
	
	If Config.GetPropertyValue( "F4SERequiredScript_Math" ) as Bool
		scriptPath = "Data/Scripts/Math.pex"
		DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", "checking for " + scriptPath )
		If IsF4SEScriptPresent_Math( asModPrefix, pluginName )
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " found" )
			res__[countAll] = ""
			countAll += 1
		Else
			res__[countAll] = scriptPath
			countAll += 1
			res_[countMissing] = scriptPath
			countMissing += 1
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " not found", -1, 1 )
		EndIf
	Else
		res__[countAll] = ""
		countAll += 1
	EndIf
	
	If Config.GetPropertyValue( "F4SERequiredScript_MatSwap" ) as Bool
		scriptPath = "Data/Scripts/MatSwap.pex"
		DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", "checking for " + scriptPath )
		params2[0] = asModPrefix as String
		params2[1] = pluginName as String
		If Utility.CallGlobalFunction( asModPrefix + "_Maintenance:MatSwapCheck", "IsF4SEScriptPresent_MatSwap", params2 )
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " found" )
			res__[countAll] = ""
			countAll += 1
		Else
			res__[countAll] = scriptPath
			countAll += 1
			res_[countMissing] = scriptPath
			countMissing += 1
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " not found", -1, 1 )
		EndIf
	Else
		res__[countAll] = ""
		countAll += 1
	EndIf
	
	If Config.GetPropertyValue( "F4SERequiredScript_MiscObject" ) as Bool
		scriptPath = "Data/Scripts/MiscObject.pex"
		DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", "checking for " + scriptPath )
		params2[0] = asModPrefix as String
		params2[1] = pluginName as String
		If Utility.CallGlobalFunction( asModPrefix + "_Maintenance:MiscObjectCheck", "IsF4SEScriptPresent_MiscObject", params2 )
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " found" )
			res__[countAll] = ""
			countAll += 1
		Else
			res__[countAll] = scriptPath
			countAll += 1
			res_[countMissing] = scriptPath
			countMissing += 1
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " not found", -1, 1 )
		EndIf
	Else
		res__[countAll] = ""
		countAll += 1
	EndIf
	
	If Config.GetPropertyValue( "F4SERequiredScript_ObjectMod" ) as Bool
		scriptPath = "Data/Scripts/ObjectMod.pex"
		DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", "checking for " + scriptPath )
		If IsF4SEScriptPresent_ObjectMod( asModPrefix, pluginName )
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " found" )
			res__[countAll] = ""
			countAll += 1
		Else
			res__[countAll] = scriptPath
			countAll += 1
			res_[countMissing] = scriptPath
			countMissing += 1
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " not found", -1, 1 )
		EndIf
	Else
		res__[countAll] = ""
		countAll += 1
	EndIf
	
	If Config.GetPropertyValue( "F4SERequiredScript_ObjectReference" ) as Bool
		scriptPath = "Data/Scripts/ObjectReference.pex"
		DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", "checking for " + scriptPath )
		If IsF4SEScriptPresent_ObjectReference( asModPrefix, pluginName )
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " found" )
			res__[countAll] = ""
			countAll += 1
		Else
			res__[countAll] = scriptPath
			countAll += 1
			res_[countMissing] = scriptPath
			countMissing += 1
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " not found", -1, 1 )
		EndIf
	Else
		res__[countAll] = ""
		countAll += 1
	EndIf
	
	If Config.GetPropertyValue( "F4SERequiredScript_Perk" ) as Bool
		scriptPath = "Data/Scripts/Perk.pex"
		DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", "checking for " + scriptPath )
		If IsF4SEScriptPresent_Perk( asModPrefix, pluginName )
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " found" )
			res__[countAll] = ""
			countAll += 1
		Else
			res__[countAll] = scriptPath
			countAll += 1
			res_[countMissing] = scriptPath
			countMissing += 1
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " not found", -1, 1 )
		EndIf
	Else
		res__[countAll] = ""
		countAll += 1
	EndIf
	
	If Config.GetPropertyValue( "F4SERequiredScript_ScriptObject" ) as Bool
		scriptPath = "Data/Scripts/ScriptObject.pex"
		DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", "checking for " + scriptPath )
		If IsF4SEScriptPresent_ScriptObject( asModPrefix, pluginName )
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " found" )
			res__[countAll] = ""
			countAll += 1
		Else
			res__[countAll] = scriptPath
			countAll += 1
			res_[countMissing] = scriptPath
			countMissing += 1
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " not found", -1, 1 )
		EndIf
	Else
		res__[countAll] = ""
		countAll += 1
	EndIf
	
	If Config.GetPropertyValue( "F4SERequiredScript_UI" ) as Bool
		scriptPath = "Data/Scripts/UI.pex"
		DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", "checking for " + scriptPath )
		If IsF4SEScriptPresent_UI( asModPrefix, pluginName )
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " found" )
			res__[countAll] = ""
			countAll += 1
		Else
			res__[countAll] = scriptPath
			countAll += 1
			res_[countMissing] = scriptPath
			countMissing += 1
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " not found", -1, 1 )
		EndIf
	Else
		res__[countAll] = ""
		countAll += 1
	EndIf
	
	If Config.GetPropertyValue( "F4SERequiredScript_Utility" ) as Bool
		scriptPath = "Data/Scripts/Utility.pex"
		DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", "checking for " + scriptPath )
		If IsF4SEScriptPresent_Utility( asModPrefix, pluginName )
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " found" )
			res__[countAll] = ""
			countAll += 1
		Else
			res__[countAll] = scriptPath
			countAll += 1
			res_[countMissing] = scriptPath
			countMissing += 1
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " not found", -1, 1 )
		EndIf
	Else
		res__[countAll] = ""
		countAll += 1
	EndIf
	
	If Config.GetPropertyValue( "F4SERequiredScript_WaterType" ) as Bool
		scriptPath = "Data/Scripts/WaterType.pex"
		DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", "checking for " + scriptPath )
		If isWaterTypeAlreadyChecked
			If !isWaterTypeMissing
				DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " found" )
				res__[countAll] = ""
				countAll += 1
			Else
				res__[countAll] = scriptPath
				countAll += 1
				res_[countMissing] = scriptPath
				countMissing += 1
				DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " not found", -1, 1 )
			EndIf
		Else
			If IsF4SEScriptPresent_WaterType( asModPrefix, pluginName )
				DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " found" )
				res__[countAll] = ""
				countAll += 1
			Else
				res__[countAll] = scriptPath
				countAll += 1
				res_[countMissing] = scriptPath
				countMissing += 1
				DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " not found", -1, 1 )
			EndIf
		EndIf
	Else
		res__[countAll] = ""
		countAll += 1
	EndIf
	
	If Config.GetPropertyValue( "F4SERequiredScript_Weapon" ) as Bool
		scriptPath = "Data/Scripts/Weapon.pex"
		DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", "checking for " + scriptPath )
		If IsF4SEScriptPresent_Weapon( asModPrefix, pluginName )
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " found" )
			res__[countAll] = ""
			countAll += 1
		Else
			res__[countAll] = scriptPath
			countAll += 1
			res_[countMissing] = scriptPath
			countMissing += 1
			DebugMsg( asModPrefix, pluginName, "CollectRequiredF4SEScriptsThatMissing", scriptPath + " not found", -1, 1 )
		EndIf
	Else
		res__[countAll] = ""
		countAll += 1
	EndIf
	
	If abFixedArray
		return res__
	EndIf
	
	If countMissing > 0
		res = New String[countMissing]
		Int i = 0
		While i < countMissing
			res[i] = res_[i]
			i += 1
		EndWhile
	Else
		res = None
	EndIf
	
	return res

EndFunction


String Function ImplodeRequiredF4SEScriptsThatMissing( Quest akConfigQuest, String asModPrefix, String glue ) global
	
	String res
	String[] res_ = CollectRequiredF4SEScriptsThatMissing( akConfigQuest, asModPrefix )
	
	If res_
		res = Implode( res_, glue )
	Else
		res = ""
	EndIf
	
	return res
	
EndFunction


Int Function CollectRequiredF4SEScriptsThatMissingIntoInt( Quest akConfigQuest, String asModPrefix ) global
	
	Int res = 0
	String[] res_ = CollectRequiredF4SEScriptsThatMissing( akConfigQuest, asModPrefix, True )
	
	Int i = 0
	While i < res_.Length
		If res_[i] != ""
			res += Math.Pow( 2, i ) as Int
		EndIf
		i += 1
	EndWhile
	
	return res
	
EndFunction


String Function GetF4SEVersionString() global

	return F4SE.GetVersion() + "." + F4SE.GetVersionMinor() + "." + F4SE.GetVersionBeta()

EndFunction


Bool Function IsItemSortingInstalled() global

	String[] VIS_PluginNames = New String[9]
	VIS_PluginNames[0] = "ValdacilsItemSorting-00-ValsPicks-DLCVersion-VanillaWeight.esp"
	VIS_PluginNames[1] = "ValdacilsItemSorting-00-ValsPicks-DLCVersion.esp"
	VIS_PluginNames[2] = "ValdacilsItemSorting-00-ValsPicks-NoDLCVersion-VanillaWeight.esp"
	VIS_PluginNames[3] = "ValdacilsItemSorting-00-ValsPicks-NoDLCVersion.esp"
	VIS_PluginNames[4] = "ValdacilsItemSorting-ExplosivesSortBottom.esp"
	VIS_PluginNames[5] = "ValdacilsItemSorting-ExplosivesSortBottomWeightless.esp"
	VIS_PluginNames[6] = "ValdacilsItemSorting-ExplosivesSortTop.esp"
	VIS_PluginNames[7] = "ValdacilsItemSorting-ExplosivesSortTopWeightless.esp"
	VIS_PluginNames[8] = "VIS-G Item Sorting.esp"
	
	Int i = 0
	While i < VIS_PluginNames.Length
		If Game.IsPluginInstalled( VIS_PluginNames[i] )
			return True
		EndIf
		i += 1
	EndWhile
	
	return False

EndFunction


String Function Implode( String[] asStringArray, String glue = ", " ) global

	String res = ""
	Int i = 0
	While i < asStringArray.Length
		If i > 0
			res += glue + asStringArray[i]
		Else
			res += asStringArray[i]
		EndIf
		i += 1
	EndWhile
	
	return res

EndFunction


Faction Function GetFactionByFactionID( Int factionID ) global

	Faction res
	FollowersScript Followers = Game.GetFormFromFile( 0x000289E4, "Fallout4.esm" ) as FollowersScript
	res = Followers.EncDefinitions[factionID].Associated_Faction
	
	return res

EndFunction


String Function GetFormInfo( String asModPrefix, Form thisForm ) global

	If thisForm
		String name = ""
		String baseInfo = "[" + GetTypeSignature( thisForm ) + ":" + GetFormIDHex( thisForm ) + "]"
		If IsF4SEInstalled()
			If !(thisForm is ObjectReference)
				name = thisForm.GetName()
			Else
				name = (thisForm as ObjectReference).GetDisplayName()
			EndIf
		EndIf
		If name != ""
			return "'" + name + "' " + baseInfo
		Else
			return baseInfo
		EndIf
	Else
		return "None"
	EndIf

EndFunction


String Function GetFormIDHex( Form thisForm, Bool lightMaster = False ) global

	If !lightMaster
		Int ModIndexInt = GetModIndex( thisForm )
		String ModIndexHex = DecToHex( ModIndexInt, 2 )
		Int StrippedFormIDInt = thisForm.GetFormID() - ModIndexInt * 0x1000000
		String StrippedFormIDHex = DecToHex( StrippedFormIDInt, 6 )
		
		return ModIndexHex + StrippedFormIDHex
	Else
		Int ModIndexInt = GetModIndex( thisForm, True )
		String ModIndexHex = DecToHex( ModIndexInt, 3 )
		Int StrippedFormIDInt = thisForm.GetFormID() - ModIndexInt * 0x1000
		String StrippedFormIDHex = DecToHex( StrippedFormIDInt, 3 )
		
		return "FE" + ModIndexHex + StrippedFormIDHex
	EndIf
	
EndFunction


String Function GetTypeSignature( Form thisForm ) global

	If thisForm is Actor
		return "ACHR"
	ElseIf thisForm is ObjectReference
		return "REFR"
	ElseIf thisForm is Action
		return "AACT"
	ElseIf thisForm is Activator
		return "ACTI"
	ElseIf thisForm is ActorBase
		return "NPC_"
	ElseIf thisForm is ActorValue
		return "AVIF"
	ElseIf thisForm is Ammo
		return "AMMO"
	ElseIf thisForm is Armor
		return "ARMO"
	ElseIf thisForm is AssociationType
		return "ASTP"
	ElseIf thisForm is Book
		return "BOOK"
	ElseIf thisForm is CameraShot
		return "CAMS"
	ElseIf thisForm is Cell
		return "CELL"
	ElseIf thisForm is Class
		return "CLAS"
	ElseIf thisForm is CombatStyle
		return "CSTY"
	ElseIf thisForm is Component
		return "CMPO"
	ElseIf thisForm is ConstructibleObject
		return "COBJ"
	ElseIf thisForm is Container
		return "CONT"
	ElseIf thisForm is Door
		return "DOOR"
	ElseIf thisForm is EffectShader
		return "EFSH"
	ElseIf thisForm is EncounterZone
		return "ECZN"
	ElseIf thisForm is Explosion
		return "EXPL"
	ElseIf thisForm is Faction
		return "FACT"
	ElseIf thisForm is Flora
		return "FLOR"
	ElseIf thisForm is FormList
		return "FLST"
	ElseIf thisForm is Furniture
		return "FURN"
	ElseIf thisForm is GlobalVariable
		return "GLOB"
	ElseIf thisForm is Hazard
		return "HAZD"
	ElseIf thisForm is HeadPart
		return "HDPT"
	ElseIf thisForm is Idle
		return "IDLE"
	ElseIf thisForm is IdleMarker
		return "IDLM"
	ElseIf thisForm is ImageSpaceModifier
		return "IMGS"
	ElseIf thisForm is ImpactDataSet
		return "IPDS"
	ElseIf thisForm is Ingredient
		return "INGR"
	ElseIf thisForm is InstanceNamingRules
		return "INNR"
	ElseIf thisForm is Key
		return "KEYM"
	ElseIf thisForm is Keyword
		return "KYWD"
	ElseIf thisForm is LeveledActor
		return "LVLN"
	ElseIf thisForm is LeveledItem
		return "LVLI"
	ElseIf thisForm is Light
		return "LIGH"
	ElseIf thisForm is Location
		return "LCTN"
	ElseIf thisForm is MagicEffect
		return "MGEF"
	ElseIf thisForm is Message
		return "MESG"
	ElseIf thisForm is MiscObject
		return "MISC"
	ElseIf thisForm is MovableStatic
		return "MSTT"
	ElseIf thisForm is MusicType
		return "MUSC"
	ElseIf thisForm is ObjectMod
		return "OMOD"
	ElseIf thisForm is Outfit
		return "OTFT"
	ElseIf thisForm is OutputModel
		return "SOPM"
	ElseIf thisForm is Package
		return "PACK"
	ElseIf thisForm is Perk
		return "PERK"
	ElseIf thisForm is Projectile
		return "PROJ"
	ElseIf thisForm is Quest
		return "QUST"
	ElseIf thisForm is Race
		return "RACE"
	ElseIf thisForm is Scene
		return "SCEN"
	ElseIf thisForm is Sound
		return "SNDR"
	ElseIf thisForm is SoundCategory
		return "SNCT"
	ElseIf thisForm is Spell
		return "SPEL"
	ElseIf thisForm is Static
		return "STAT"
	ElseIf thisForm is TalkingActivator
		return "TACT"
	ElseIf thisForm is Terminal
		return "TERM"
	ElseIf thisForm is Topic
		return "DIAL"
	ElseIf thisForm is TopicInfo
		return "INFO"
	ElseIf thisForm is VisualEffect
		return "RFCT"
	ElseIf thisForm is VoiceType
		return "VTYP"
	ElseIf thisForm is WaterType
		return "WATR"
	ElseIf thisForm is Weapon
		return "WEAP"
	ElseIf thisForm is Weather
		return "WTHR"
	ElseIf thisForm is WorldSpace
		return "WRLD"
	Else
		return "FORM"
	EndIf

EndFunction


String Function GetTypeName( Form thisForm ) global

	If thisForm is Actor
		return "Placed Actor"
	ElseIf thisForm is ObjectReference
		return "Placed Reference"
	ElseIf thisForm is Action
		return "Action"
	ElseIf thisForm is Activator
		return "Activator"
	ElseIf thisForm is ActorBase
		return "Non-Player Character (Actor)"
	ElseIf thisForm is ActorValue
		return "Actor Value Information"
	ElseIf thisForm is Ammo
		return "Ammunition"
	ElseIf thisForm is Armor
		return "Armor"
	ElseIf thisForm is AssociationType
		return "Association Type"
	ElseIf thisForm is Book
		return "Book"
	ElseIf thisForm is CameraShot
		return "Camera Shot"
	ElseIf thisForm is Cell
		return "Cell"
	ElseIf thisForm is Class
		return "Class"
	ElseIf thisForm is CombatStyle
		return "Combat Style"
	ElseIf thisForm is Component
		return "Component"
	ElseIf thisForm is ConstructibleObject
		return "Constructible Object"
	ElseIf thisForm is Container
		return "Container"
	ElseIf thisForm is Door
		return "Door"
	ElseIf thisForm is EffectShader
		return "Effect Shader"
	ElseIf thisForm is Enchantment
		return "Enchantment"
	ElseIf thisForm is EncounterZone
		return "Encounter Zone"
	ElseIf thisForm is Explosion
		return "Explosion"
	ElseIf thisForm is Faction
		return "Faction"
	ElseIf thisForm is Flora
		return "Flora"
	ElseIf thisForm is FormList
		return "FormID List"
	ElseIf thisForm is Furniture
		return "Furniture"
	ElseIf thisForm is GlobalVariable
		return "Global"
	ElseIf thisForm is Hazard
		return "Hazard"
	ElseIf thisForm is HeadPart
		return "Head Part"
	ElseIf thisForm is Holotape
		return "Holotape"
	ElseIf thisForm is Idle
		return "Idle Animation"
	ElseIf thisForm is IdleMarker
		return "Idle Marker"
	ElseIf thisForm is ImageSpaceModifier
		return "Image Space"
	ElseIf thisForm is ImpactDataSet
		return "Impact Data Set"
	ElseIf thisForm is Ingredient
		return "Ingredient"
	ElseIf thisForm is InstanceNamingRules
		return "Instance Naming Rules"
	ElseIf thisForm is Key
		return "Key"
	ElseIf thisForm is Keyword
		return "Keyword"
	ElseIf thisForm is LeveledActor
		return "Leveled NPC"
	ElseIf thisForm is LeveledItem
		return "Leveled Item"
	ElseIf thisForm is LeveledSpell
		return "Leveled Spell"
	ElseIf thisForm is Light
		return "Light"
	ElseIf thisForm is Location
		return "Location"
	ElseIf thisForm is LocationRefType
		return "Location Reference Type"
	ElseIf thisForm is MagicEffect
		return "Magic Effect"
	ElseIf thisForm is Message
		return "Message"
	ElseIf thisForm is MiscObject
		return "Misc. Item"
	ElseIf thisForm is MovableStatic
		return "Moveable Static"
	ElseIf thisForm is MusicType
		return "Music Type"
	ElseIf thisForm is ObjectMod
		return "Object Modification"
	ElseIf thisForm is Outfit
		return "Outfit"
	ElseIf thisForm is OutputModel
		return "Sound Output Model"
	ElseIf thisForm is Package
		return "Package"
	ElseIf thisForm is Perk
		return "Perk"
	ElseIf thisForm is Potion
		return "Potion"
	ElseIf thisForm is Projectile
		return "Projectile"
	ElseIf thisForm is Quest
		return "Quest"
	ElseIf thisForm is Race
		return "Race"
	ElseIf thisForm is Scene
		return "Scene"
	ElseIf thisForm is Scroll
		return "Scroll"
	ElseIf thisForm is ShaderParticleGeometry
		return "Shader Particle Geometry"
	ElseIf thisForm is Shout
		return "Shout"
	ElseIf thisForm is SoulGem
		return "Soul Gem"
	ElseIf thisForm is Sound
		return "Sound Descriptor"
	ElseIf thisForm is SoundCategory
		return "Sound Category"
	ElseIf thisForm is SoundCategorySnapshot
		return "Sound Category Snapshot"
	ElseIf thisForm is Spell
		return "Spell"
	ElseIf thisForm is Static
		return "Static"
	ElseIf thisForm is TalkingActivator
		return "Talking Activator"
	ElseIf thisForm is Terminal
		return "Terminal"
	ElseIf thisForm is Topic
		return "Dialog Topic"
	ElseIf thisForm is TopicInfo
		return "TopicInfo"
	ElseIf thisForm is VisualEffect
		return "Visual Effect"
	ElseIf thisForm is VoiceType
		return "Voice Type"
	ElseIf thisForm is WaterType
		return "Water"
	ElseIf thisForm is Weapon
		return "Weapon"
	ElseIf thisForm is Weather
		return "Weather"
	ElseIf thisForm is WordOfPower
		return "Word Of Power"
	ElseIf thisForm is WorldSpace
		return "WorldSpace"
	Else
		return "Form"
	EndIf

EndFunction


String Function GetWeatherType( Int weatherClass ) global

	String res
	
	If weatherClass == 0
		res = "Pleasant"
	ElseIf weatherClass == 1
		res = "Cloudy"
	ElseIf weatherClass == 2
		res = "Rainy"
	ElseIf weatherClass == 3
		res = "Snow"
	Else
		res = "No classification"
	EndIf
	
	return res

EndFunction


Int Function Mod( Int a, Int b ) global

	Float x = a / b
	Int y = Math.Floor( x )
	
	return a - (b * y)

EndFunction


String Function DecToHex( Int n, Int lngth = 8 ) global

	String res = ""

	String[] hexaValues = New String[16]
	hexaValues[0] = "0"
	hexaValues[1] = "1"
	hexaValues[2] = "2"
	hexaValues[3] = "3"
	hexaValues[4] = "4"
	hexaValues[5] = "5"
	hexaValues[6] = "6"
	hexaValues[7] = "7"
	hexaValues[8] = "8"
	hexaValues[9] = "9"
	hexaValues[10] = "A"
	hexaValues[11] = "B"
	hexaValues[12] = "C"
	hexaValues[13] = "D"
	hexaValues[14] = "E"
	hexaValues[15] = "F"
	
	String[] hexaDeciNum = New String[lngth]
     
    Int i = 0
    While n != 0

        Int temp = 0
         
        temp = Mod( n, 16 )
         
		hexaDeciNum[i] = hexaValues[temp]
		i +=1 
		
        n = ( n / 16 )
    EndWhile
     
	Int k = i
	While lngth - k > 0
		res += "0"
		k += 1
	EndWhile
	
	Int j = i - 1
	While j >= 0
        res += hexaDeciNum[j]
		j -= 1
	EndWhile
	
	return res

EndFunction


Int Function DecToBin( Int n ) global

	Int res = 0

	Int[] binValues = New Int[2]
	binValues[0] = 0
	binValues[1] = 1
	
	Int[] binNum = New Int[32]
     
    Int i = 0
    While n != 0

        Int temp = 0
         
        temp = Mod( n, 2 )
         
		binNum[i] = binValues[temp]
		i +=1 
		
        n = ( n / 2 )
    EndWhile
     
	Int j = i - 1
	While j >= 0
        res += Math.Pow( 10, j ) as Int * binNum[j]
		j -= 1
	EndWhile
	
	return res

EndFunction


Int Function GetModIndex( Form akForm, Bool lightMaster = False ) global
    
	Int n
	
	If !lightMaster
		If akForm
			n = akForm.GetFormID()
			If n < 0
				return 255 - ((n + 1) / -16777216)
			Else
				return (n / 0x1000000)
			EndIf
		Else
			return -1
		EndIf
	Else
		If akForm
			n = akForm.GetFormID()
			If n < 0
				return (255 - ((n + 1) / -4096)) - 0xFE
			Else
				return (n / 0x1000) - 0xFE
			EndIf
		Else
			return -1
		EndIf
	EndIf
	
EndFunction


Int Function Round( Float fl ) global

	Int res
	
	If fl - (Math.Floor( fl ) as Float ) >= 0.5
		res = Math.Ceiling( fl )
	Else
		res = Math.Floor( fl )
	EndIf
	
	return res

EndFunction


Function TestFunction() global

	Debug.Messagebox( "Global test function called successfully." )

EndFunction


Function DebugMsg( String asModPrefix, String asPluginName, String asFunctionName = "", String asMessageBody = "", Int auiDLevelLocal = -1, Int auiSeverity = 0, String asUserFileName = "" ) global

	ScriptObject Logger = Game.GetFormFromFile( 0x01000812, asPluginName ).CastAs( asModPrefix + "_Logger" )

	If Logger
		Var[] params6 = New Var[6]
		params6[0] = "Utility"
		params6[1] = asFunctionName as String
		params6[2] = asMessageBody as String
		params6[3] = auiDLevelLocal as Int
		params6[4] = auiSeverity as Int
		params6[5] = asUserFileName as String
		Logger.CallFunctionNoWait( "DebugMsg", params6 )
	Endif

EndFunction
