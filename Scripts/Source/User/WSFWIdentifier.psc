ScriptName WSFWIdentifier native hidden

Struct PowerGridStatistics
	Bool corrupt
	Bool checked
	Int existingNodes
	Int deletedNodes
	Int numCorruptGrids
	Int totalNodes
	Int totalGrids
EndStruct

Struct RecipeComponent
	Form Object
	Int Count
EndStruct

;-- Functions ---------------------------------------

Bool Function ArePowerGridStatisticsCorrupt(PowerGridStatistics pgs) global
	if(pgs != None && pgs.corrupt)
		return true
	endif
	
	return false
EndFunction

string Function GetReferenceName( ObjectReference ref ) global native

Function MessageReferenceName( ObjectReference ref ) global
	Debug.MessageBox( "ref.GetName(): " + ref.GetName() + "<br>ref.GetBaseObject().GetName(): " + ref.GetBaseObject().GetName() + "<br>ref.GetDisplayName(): " + ref.GetDisplayName() + "<br>GetReferenceName( ref ): " + GetReferenceName( ref ) )
EndFunction


; Completely deletes all power grids of a settlement. Recommended to use for settlements that are to be scrapped entirely.
Bool Function ResetPowerGrid( ObjectReference workshop_ref ) global native

; Checks and optionally fixes errors of settlement power grids. Takes an array of power grid indices as a filter parameter. Returns statistics data in PowerGridStatistics struct. Logs results.
; fixerrors = 0 - check settlement for power grid errors, but don't fix anything
; fixerrors = 1 - check settlement for power grid errors, and fix errors by removing corrupt power grids entirely (not recommended legacy feature)
; fixerrors = 2 - check settlement for power grid errors, and fix errors by cleaning corrupt power grids by removing deleted power nodes only (recommended)
PowerGridStatistics Function CheckAndFixPowerGridWithFilter( ObjectReference workshop_ref, Int fixerrors, Int[] gridFilter ) global native

; Checks and optionally fixes errors of settlement power grids. Returns statistics data in PowerGridStatistics struct. Logs results.
; fixerrors = 0 - check settlement for power grid errors, but don't fix anything
; fixerrors = 1 - check settlement for power grid errors, and fix errors by removing corrupt power grids entirely (not recommended legacy feature)
; fixerrors = 2 - check settlement for power grid errors, and fix errors by cleaning corrupt power grids by removing deleted power nodes only (recommended)
PowerGridStatistics Function CheckAndFixPowerGrid( ObjectReference workshop_ref, Int fixerrors ) global

	Int[] emptyArray
	return CheckAndFixPowerGridWithFilter( workshop_ref, fixerrors, emptyArray )

EndFunction

; Checks errors of settlement power grids. Takes an array of power grid indices as a filter parameter. Logs results.
Bool Function ScanPowerGridWithFilter( ObjectReference workshop_ref, Int[] gridFilter ) global native

; Checks errors of settlement power grids. Logs results.
Bool Function ScanPowerGrid( ObjectReference workshop_ref ) global

	Int[] emptyArray
	return ScanPowerGridWithFilter( workshop_ref, emptyArray )

EndFunction

; Gets the number of power grids of a settlement.
Int Function GetPowerGridCount( ObjectReference workshop_ref ) global native

; Gets the indices of good power grids of a settlement.
Int[] Function GetGoodPowerGridIndices( ObjectReference workshop_ref ) global native

; Gets the indices of corrupt power grids of a settlement.
Int[] Function GetCorruptPowerGridIndices( ObjectReference workshop_ref ) global native

; Gets the FormIDs of all deleted power nodes.
Int[] Function GetDeletedNodeFormIDs( ObjectReference workshop_ref ) global native

; Gets the FormIDs of all existing power nodes.
Int[] Function GetExistingNodeFormIDs( ObjectReference workshop_ref ) global native

; Removes power nodes from all power grids by a list of FormIDs. Note that the reason it takes FormIDs instead of Object References is because most of the times these objects don't exist in the game anymore.
Int[] Function RemoveNodesFromPowerGrid( ObjectReference workshop_ref, Int[] iFormIDs ) global native

; Removes the power node of an existing Object Reference from all power grids. This is mostly for testing purposes.
Bool Function RemoveExistingObjectFromPowerGrid( ObjectReference workshop_ref, ObjectReference akRefToRemove ) global
	
	Int[] formIDs = New Int[1]
	formIDs[0] = akRefToRemove.GetFormID()
	return RemoveNodesFromPowerGrid( workshop_ref, formIDs ).Length > 0
	
EndFunction

; Gets the index of the power grid of an existing settlement object. Returns a negative number on errors.
Int Function GetPowerGridIndexForObject( ObjectReference workshop_ref, ObjectReference refObject ) global native

Int Function CreatePowerGridFromRefs( ObjectReference workshop_ref, ObjectReference[] refObjects, Bool removeFromOtherGrids ) global native

Bool Function AddRefsToPowerGrid( ObjectReference workshop_ref, Int gridIndex, ObjectReference[] refObjects, Bool removeFromOtherGrids ) global native

ConstructibleObject Function GetRecipe( Form baseform ) global native

ConstructibleObject Function GetRefRecipe( ObjectReference refObject ) global

	return GetRecipe( refObject.GetBaseObject() )

EndFunction

RecipeComponent[] Function GetRecipeComponents( ConstructibleObject recipe ) global native

RecipeComponent[] Function GetRefRecipeComponents( ObjectReference refObject, Bool original = False ) global

	RecipeComponent[] res
	ConstructibleObject recipe = GetRecipe( refObject.GetBaseObject() )
	If recipe
		res = GetRecipeComponents( recipe )
	EndIf
	return res

EndFunction

Int[] Function IntArrayPush( Int[] arr, Int val ) global native

Int[] Function AddInt( Int[] arr, Int val ) global

	If arr.Length < 128
		arr.Add( val )
		return arr
	Else
		return IntArrayPush( arr, val )
	EndIf

EndFunction

String[] Function StringArrayPush( String[] arr, String val ) global native

String[] Function AddString( String[] arr, String val ) global

	If arr.Length < 128
		arr.Add( val )
		return arr
	Else
		return StringArrayPush( arr, val )
	EndIf

EndFunction

ObjectReference[] Function ObjectReferenceArrayPush( ObjectReference[] arr, ObjectReference val ) global native

ObjectReference[] Function AddObjectReference( ObjectReference[] arr, ObjectReference val ) global

	If arr.Length < 128
		arr.Add( val )
		return arr
	Else
		return ObjectReferenceArrayPush( arr, val )
	EndIf

EndFunction

Function Delete( ObjectReference akRefToRemove ) global
	
	akRefToRemove.Disable()
	akRefToRemove.Delete()
	
EndFunction

Function SafeDelete( ObjectReference akRefToRemove ) global

	Keyword WorkshopItemKeyword = Game.GetFormFromFile(0x00054BA6, "Fallout4.esm") as Keyword	
	ObjectReference workshop_ref = akRefToRemove.GetLinkedRef( WorkshopItemKeyword )
	Int[] tmpNodeFormID = New Int[1]
	If workshop_ref
		tmpNodeFormID[0] = akRefToRemove.GetFormID()
	EndIf
	akRefToRemove.Disable()
	akRefToRemove.Delete()
	If workshop_ref
		RemoveNodesFromPowerGrid( workshop_ref, tmpNodeFormID )
	EndIf
	
EndFunction

Function SafeScrap( ObjectReference akRefToRemove ) global

	Int i
	Var[] params2 = New Var[2]
	Keyword WorkshopItemKeyword = Game.GetFormFromFile(0x00054BA6, "Fallout4.esm") as Keyword	
	ObjectReference workshop_ref = akRefToRemove.GetLinkedRef( WorkshopItemKeyword )
	Int[] tmpNodeFormID = New Int[1]
	If workshop_ref
		tmpNodeFormID[0] = akRefToRemove.GetFormID()
	EndIf
	
	params2[0] = "WSFW"
	params2[1] = akRefToRemove as Form
	String akRefToRemoveFormInfo = Utility.CallGlobalFunction( "WSFW_Utility", "GetFormInfo", params2 ) as String
	
	ObjectReference[] connected = akRefToRemove.GetConnectedObjects()
	
	If akRefToRemove.GetBaseObject() is MiscObject
		MiscObject:MiscComponent[] miscComponents = (akRefToRemove.GetBaseObject() as MiscObject).GetMiscComponents()
		
		Debug.Trace( "WSFW " + akRefToRemoveFormInfo + " components:" )
	
		If miscComponents.Length
			i = 0
			While i < miscComponents.Length
				Form comp = miscComponents[i].Object as Form
				Int baseCount = miscComponents[i].Count
				
				Int pay = ComputePayout( comp, baseCount, False, Game.GetPlayer() )
				if pay > 0
					Game.GetPlayer().AddItem( miscComponents[i].Object.GetScrapItem(), pay, False )
				EndIf

				params2[0] = "WSFW"
				params2[1] = comp
				String componentFormInfo = Utility.CallGlobalFunction( "WSFW_Utility", "GetFormInfo", params2 ) as String
				Debug.Trace( "	WSFW " + baseCount + " x " + componentFormInfo )
				Debug.Trace( "		WSFW Scrapper rank: " + GetScrapperRank( Game.GetPlayer() ) )
				String rarity = "Common"
				If IsZeroYield( comp )
					rarity = "Zero yield"
				ElseIf IsRare( comp )
					rarity = "Rare"
				ElseIf IsUncommon( comp )
					rarity = "Uncommon"
				EndIf
				Debug.Trace( "		WSFW rarity: " + rarity )
				Debug.Trace( "		WSFW scalar: " + miscComponents[i].Object.GetScrapScalar().GetValue() )
				Debug.Trace( "		WSFW type: Junk" )
				Debug.Trace( "		WSFW player gets " + pay + " x " + componentFormInfo )
				
				i += 1
			EndWhile
		Else
			params2[0] = "WSFW"
			params2[1] = akRefToRemove.GetBaseObject() as Form
			String refBaseObjectFormInfo = Utility.CallGlobalFunction( "WSFW_Utility", "GetFormInfo", params2 ) as String
			Debug.Trace( "	WSFW no misc object components found, " + refBaseObjectFormInfo + " added to the Player without breaking it down to components" )
			Game.GetPlayer().AddItem( akRefToRemove, 1, False )
		EndIf
	Else
		RecipeComponent[] recipeComponents = GetRefRecipeComponents( akRefToRemove )
		
		Debug.Trace( "WSFW " + akRefToRemoveFormInfo + " components:" )
	
		If recipeComponents.Length
			i = 0
			While i < recipeComponents.Length
				Float scalar = 0.0
				Form comp = recipeComponents[i].Object as Form
				Int recipeCount = recipeComponents[i].Count
				Int pay = 0
				If comp
					If comp is MiscObject
						scalar = 1.0
						pay = recipeCount
					ElseIf comp is Component
						scalar = (comp as Component).GetScrapScalar().GetValue()
						pay = ComputePayout( comp, recipeCount, True, Game.GetPlayer() )
					EndIf
				EndIf

				if pay > 0
					If comp is MiscObject
						Game.GetPlayer().AddItem( comp, pay, False )
					ElseIf comp is Component
						Game.GetPlayer().AddItem( (comp as Component).GetScrapItem(), pay, False )
					EndIf
				EndIf
				
				params2[0] = "WSFW"
				params2[1] = comp
				String componentFormInfo = Utility.CallGlobalFunction( "WSFW_Utility", "GetFormInfo", params2 ) as String
				Debug.Trace( "	WSFW " + recipeCount + " x " + componentFormInfo )
				Debug.Trace( "		WSFW Scrapper rank: " + GetScrapperRank( Game.GetPlayer() ) )
				String rarity = "Common"
				If IsZeroYield( comp )
					rarity = "Zero yield"
				ElseIf IsRare( comp )
					rarity = "Rare"
				ElseIf IsUncommon( comp )
					rarity = "Uncommon"
				EndIf
				Debug.Trace( "		WSFW rarity: " + rarity )
				Debug.Trace( "		WSFW scalar: " + scalar )
				Debug.Trace( "		WSFW type: Recipe based" )
				Debug.Trace( "		WSFW player gets " + pay + " x " + componentFormInfo )
				i += 1
			EndWhile
		Else
			params2[0] = "WSFW"
			params2[1] = akRefToRemove.GetBaseObject() as Form
			String refBaseObjectFormInfo = Utility.CallGlobalFunction( "WSFW_Utility", "GetFormInfo", params2 ) as String
			If !akRefToRemove.GetBaseObject() is Activator && !akRefToRemove.GetBaseObject() is Container && !akRefToRemove.GetBaseObject() is Door && !akRefToRemove.GetBaseObject() is Explosion && !akRefToRemove.GetBaseObject() is Hazard && !akRefToRemove.GetBaseObject() is IdleMarker && !akRefToRemove.GetBaseObject() is Light && !akRefToRemove.GetBaseObject() is Static && !akRefToRemove.GetBaseObject() is Terminal && akRefToRemove.GetBaseObject().GetFormID() != 0x0001D971
				Debug.Trace( "	WSFW no recipe found, " + refBaseObjectFormInfo + " added to the Player without breaking it down to components" )
				Game.GetPlayer().AddItem( akRefToRemove, 1, False )
			Else
				Debug.Trace( "	WSFW no recipe found, " + refBaseObjectFormInfo + " cannot be added to the Player without breaking it down to components, deleted without storing anything" )
			EndIf
		EndIf
		
		If akRefToRemove.GetBaseObject() is Armor || akRefToRemove.GetBaseObject() is Weapon
			ObjectMod[] omods = akRefToRemove.GetAllMods()
			
			Int k = 0
			While k < omods.Length
				RecipeComponent[] omodComponents = GetRecipeComponents( GetRecipe( omods[k] ) )

				params2[0] = "WSFW"
				params2[1] = omods[k] as Form
				String omodToRemoveFormInfo = Utility.CallGlobalFunction( "WSFW_Utility", "GetFormInfo", params2 ) as String
				Debug.Trace( "WSFW	" + omodToRemoveFormInfo + " components:" )
			
				If omodComponents.Length
					i = 0
					While i < omodComponents.Length
						Float scalar = 0.0
						Form comp = omodComponents[i].Object as Form
						Int recipeCount = omodComponents[i].Count
						Int pay = 0
						If comp
							If comp is MiscObject
								scalar = 1.0
								pay = recipeCount
							ElseIf comp is Component
								scalar = (comp as Component).GetScrapScalar().GetValue()
								pay = ComputePayout( comp, recipeCount, True, Game.GetPlayer() )
							EndIf
						EndIf

						if pay > 0
							If comp is MiscObject
								Game.GetPlayer().AddItem( comp, pay, False )
							ElseIf comp is Component
								Game.GetPlayer().AddItem( (comp as Component).GetScrapItem(), pay, False )
							EndIf
						EndIf
						
						params2[0] = "WSFW"
						params2[1] = comp
						String componentFormInfo = Utility.CallGlobalFunction( "WSFW_Utility", "GetFormInfo", params2 ) as String
						Debug.Trace( "		WSFW " + recipeCount + " x " + componentFormInfo )
						Debug.Trace( "			WSFW Scrapper rank: " + GetScrapperRank( Game.GetPlayer() ) )
						String rarity = "Common"
						If IsZeroYield( comp )
							rarity = "Zero yield"
						ElseIf IsRare( comp )
							rarity = "Rare"
						ElseIf IsUncommon( comp )
							rarity = "Uncommon"
						EndIf
						Debug.Trace( "			WSFW rarity: " + rarity )
						Debug.Trace( "			WSFW scalar: " + scalar )
						Debug.Trace( "			WSFW type: Recipe based" )
						Debug.Trace( "			WSFW player gets " + pay + " x " + componentFormInfo )
						i += 1
					EndWhile
				Else
					params2[0] = "WSFW"
					params2[1] = omods[k].GetLooseMod() as Form
					String omodLooseModFormInfo = Utility.CallGlobalFunction( "WSFW_Utility", "GetFormInfo", params2 ) as String
					Debug.Trace( "		WSFW no recipe found, " + omodLooseModFormInfo + " added to the Player without breaking it down to components" )
					Game.GetPlayer().AddItem( omods[k].GetLooseMod(), 1, False )
				EndIf
				
				k += 1
			EndWhile
		EndIf
		
	EndIf
	
	If akRefToRemove
		akRefToRemove.Disable()
		akRefToRemove.Delete()
	EndIF
	If workshop_ref
		RemoveNodesFromPowerGrid( workshop_ref, tmpNodeFormID )
	EndIf
	
	i = 0
	While i < connected.Length
		If connected[i].GetBaseObject().GetFormID() == 0x0001D971
			SafeScrap( connected[i] )
		EndIf
		i += 1
	EndWhile
	
EndFunction

; Public entry point.
; - startRef: any power-connected workshop object (or a wire)
; - includeWires: if true, output will contain wire refs too; otherwise they’re only traversed through
; - maxCount: safety cap to avoid runaway recursion on strange setups
ObjectReference[] Function TraversePowerGrid(ObjectReference startRef, Bool includeWires = False, Int maxCount = 8192) global
	if startRef == None
		return new ObjectReference[0]
	endif

	Form WireBase = Game.GetFormFromFile(0x0001D971, "Fallout4.esm")

	ObjectReference[] seen = new ObjectReference[0]   ; loop prevention (wires AND non-wires)
	ObjectReference[] result = new ObjectReference[0] ; what we return (optionally excluding wires)

	_DFS_Grid(startRef, None, includeWires, maxCount, seen, result)
	return result
EndFunction

; --- Internal recursive DFS ---
Function _DFS_Grid(ObjectReference node, ObjectReference cameFrom, Bool includeWires, Int maxCount, ObjectReference[] seen, ObjectReference[] result) global
	if node == None
		return
	endif

	; Safety cap
	if seen.Length >= maxCount
		return
	endif

	; Already processed?
	if _ArrHas(seen, node)
		return
	endif

	; Mark as seen for loop prevention (regardless of wire or not).
	;seen.Add(node)
	seen = AddObjectReference( seen, node )

	Form wireBase = Game.GetFormFromFile(0x0001D971, "Fallout4.esm")
	ActorValue WorkshopSnapTransmitsPower = Game.GetFormFromFile(0x00000354, "Fallout4.esm") as ActorValue
	ActorValue PowerRadiation = Game.GetFormFromFile(0x0000032F, "Fallout4.esm") as ActorValue
	Keyword WorkshopCanBePowered = Game.GetFormFromFile( 0x0003037E, "Fallout4.esm" ) as Keyword
	Bool isWire = _IsWire(node, wireBase)

	; Add to output only if requested (wires optional).
	if includeWires || !isWire
		;result.Add(node)
		result = AddObjectReference( result, node )
	endif

	; Get neighbors using the F4SE extension
	ObjectReference[] neighbors = node.GetConnectedObjects()
	ObjectReference:ConnectPoint[] connectPoints = node.GetConnectPoints()
	ObjectReference[] wireless
	ObjectReference[] wireless_
	Var[] params2 = New Var[2]
	If node.GetValue( PowerRadiation ) > 0.0 && 0
		wireless = node.FindAllReferencesWithKeyword( WorkshopCanBePowered, node.GetValue( PowerRadiation ) )
		wireless_ = New ObjectReference[0]
		Int i = 0
		While i < wireless.Length
			params2[0] = "WSFW"
			params2[1] = wireless[i] as Form
			String wirelessPowerGridNodeFormInfo = Utility.CallGlobalFunction( "WSFW_Utility", "GetFormInfo", params2 ) as String
			Debug.Trace( "WSFW wireless connection " + (i + 1) + " / " + wireless.Length + ": " + wirelessPowerGridNodeFormInfo + " " + GetFormIDHex( wireless[i].GetBaseObject().GetFormID() ) )
			ObjectReference n = wireless[i]
			Bool hasWireConnection = False
			ObjectReference[] connections = n.GetConnectedObjects()
			If connections
				hasWireConnection = True
				Debug.Trace( "	WSFW " + wirelessPowerGridNodeFormInfo + " connected to " + connections.Length + " wires" )
			Else
				ObjectReference:ConnectPoint[] neighborConnectPoints = n.GetConnectPoints()
				If neighborConnectPoints
					Int j = 0
					While j < neighborConnectPoints.Length && !hasWireConnection
						Debug.Trace( "	WSFW " + wirelessPowerGridNodeFormInfo + " connect point " + (j + 1) + " / " + neighborConnectPoints.Length + ": " + neighborConnectPoints[j].name )
						If neighborConnectPoints[j].name == "P-WS-Snap" || neighborConnectPoints[j].name == "P-WS-Input" || neighborConnectPoints[j].name == "P-WS-Output"
							hasWireConnection = True
						EndIf
						j += 1
					EndWhile
				EndIf
			EndIf
			;ObjectReference[] neighborsneighbors = n.GetConnectedObjects()
			;j = 0
			;While j < neighborsneighbors.Length && !hasWireConnection
			;	params2[0] = "WSFW"
			;	params2[1] = neighborsneighbors[j] as Form
			;	String neighborPowerGridNodeFormInfo = Utility.CallGlobalFunction( "WSFW_Utility", "GetFormInfo", params2 ) as String
			;	If _IsWire( neighborsneighbors[j], wireBase )
			;		hasWireConnection = True
			;		Debug.Trace( "	WSFW " + wirelessPowerGridNodeFormInfo + " connected object " + (j + 1) + " / " + neighborsneighbors.Length + ": WIRE - " + neighborPowerGridNodeFormInfo + " " + GetFormIDHex( neighborsneighbors[j].GetBaseObject().GetFormID() ) )
			;	Else
			;		Debug.Trace( "	WSFW " + wirelessPowerGridNodeFormInfo + " connected object " + (j + 1) + " / " + neighborsneighbors.Length + ": " + neighborPowerGridNodeFormInfo + " " + GetFormIDHex( neighborsneighbors[j].GetBaseObject().GetFormID() ) )
			;	EndIf
			;	j += 1
			;EndWhile
			If !hasWireConnection
				;wireless_.Add( n )
				wireless_ = AddObjectReference( wireless_, n )
			EndIf
			i += 1
		EndWhile
	EndIf
	
	if neighbors == None && connectPoints == None && (wireless_ == None || wireless_.Length == 0)
		return
	endif
	
	Int i = 0
	If node.GetValue( PowerRadiation ) > 0.0 && 0
		while i < wireless_.Length
			ObjectReference n = wireless_[i]
			; Skip invalid and trivial back-edge
			if n != None && n != cameFrom
				; Recurse to every neighbor. Loop prevention is handled by 'seen'.
				;params2[0] = "WSFW"
				;params2[1] = n as Form
				;String wirelessPowerGridNodeFormInfo = Utility.CallGlobalFunction( "WSFW_Utility", "GetFormInfo", params2 ) as String
				;Debug.Trace( "WSFW true wireless connection " + (i + 1) + " / " + wireless_.Length + ": " + wirelessPowerGridNodeFormInfo + " " + GetFormIDHex( n.GetBaseObject().GetFormID() ) )
				_DFS_Grid(n, node, includeWires, maxCount, seen, result)
			endif
			i += 1
		endWhile
	EndIf
	
	i = 0
	If node.GetValue( WorkshopSnapTransmitsPower ) > 0.0
		while i < connectPoints.Length
			ObjectReference n = connectPoints[i].object
			; Skip invalid and trivial back-edge
			if n != None && n != cameFrom && n.GetValue( WorkshopSnapTransmitsPower ) > 0.0
				; Recurse to every neighbor. Loop prevention is handled by 'seen'.
				_DFS_Grid(n, node, includeWires, maxCount, seen, result)
			endif
			i += 1
		endWhile
	EndIf

	i = 0
	while i < neighbors.Length
		ObjectReference n = neighbors[i]
		; Skip invalid and trivial back-edge
		if n != None && n != cameFrom
			; Recurse to every neighbor. Loop prevention is handled by 'seen'.
			_DFS_Grid(n, node, includeWires, maxCount, seen, result)
		endif
		i += 1
	endWhile
EndFunction


; ===== Public API =====
; workshopRef        : the settlement’s workbench (or any valid workshop reference your native expects)
; workshopObjects    : all workshop-placed refs in this settlement (see notes below)
; verboseToLog       : if true, emits Debug.Trace lines as well as returning messages[]
; maxTraverseCount   : safety cap passed through to TraversePowerGrid
String[] Function ScanForPowerGridCorruption(ObjectReference workshopRef, ObjectReference[] workshopObjects, Bool verboseToLog = True, Int maxTraverseCount = 8192, Bool requireValidIndex = True, Bool reconnectResidualGridFragments = False, Bool createNewGrids = False) global
	String[] messages = new String[0]
	Var[] params2 = New Var[2]

	If workshopRef == None || workshopObjects == None
		;messages.Add("[Error] Missing workshopRef, workshopObjects.")
		messages = AddString( messages, "[Error] Missing workshopRef, workshopObjects." )
		return messages
	EndIf

	Form wireBase = Game.GetFormFromFile(0x0001D971, "Fallout4.esm")

	; track coverage of non-wire members we’ve already grouped
	ObjectReference[] globalSeen = new ObjectReference[0]
	
	ObjectReference[] firstSeedForGroup = new ObjectReference[0]
	ObjectReference[] finalPairsToConnect = New ObjectReference[0]
	Int[] handledGroupIds = New Int[0]

	; Type-2 map: internalIndex -> first groupId seen
	Int[] indicesSeen = new Int[0]
	String indicesSeenStr = ""
	Int[] firstGroupForIndex = new Int[0]
	String firstGroupForIndexStr = ""
	Int[] indexForGroup = new Int[0]
	String indexForGroupStr = ""

	Int groupId = 0
	Int i = 0
	While i < workshopObjects.Length
		ObjectReference seed = workshopObjects[i]

		; guard chain instead of continue
		Bool ok = True
		If seed == None
			ok = False
		EndIf
		If ok
			ObjectReference[] neigh = seed.GetConnectedObjects()
			If neigh == None || neigh.Length == 0
				ok = False
			EndIf
		EndIf
		If ok
			If _IsWire(seed, wireBase)
				ok = False ; don’t seed on wires
			EndIf
		EndIf
		If ok
			If _HasRef(globalSeen, seed)
				ok = False ; already covered by a previous group
			EndIf
		EndIf

		If ok
			; build the connectivity group (non-wires only)
			ObjectReference[] group_ = TraversePowerGrid(seed, False, maxTraverseCount)
			If group_ != None && group_.Length > 0

				; check if this whole group is already accounted for
				Bool allSeen = True
				Int j = 0
				While j < group_.Length
					If !_HasRef(globalSeen, group_[j])
						allSeen = False
					EndIf
					j += 1
				EndWhile

				If !allSeen
					; mark group covered
					;firstSeedForGroup.Add( seed )
					firstSeedForGroup = AddObjectReference( firstSeedForGroup, seed )
					j = 0
					While j < group_.Length
						If !_HasRef(globalSeen, group_[j])
							;globalSeen.Add(group_[j])
							globalSeen = AddObjectReference( globalSeen, group_[j] )
						EndIf
						j += 1
					EndWhile

					; collect unique internal indices for this group
					Int[] uniqueIdx = new Int[0]
					String uniqueIdxStr = ""
					Int[] nonUniqueIdx = new Int[0]
					String nonUniqueIdxStr = ""
					j = 0
					While j < group_.Length
						Int idx = GetPowerGridIndexForObject(workshopRef, group_[j])
						If (!requireValidIndex) || (idx >= 0)
							If _AddUniqueInt(uniqueIdx, idx)
								uniqueIdxStr += idx + " "
							EndIf
							;nonUniqueIdx.Add(idx)
							nonUniqueIdx = AddInt( nonUniqueIdx, idx )
							nonUniqueIdxStr += idx + " "
						EndIf
						j += 1
					EndWhile
					;Debug.MessageBox( "group #" + groupId + "<br>uniqueIdxStr: " + uniqueIdxStr + "<br>nonUniqueIdxStr: " + nonUniqueIdxStr )

					If verboseToLog
						Debug.Trace("[PowerScan] Group " + groupId + " size=" + group_.Length + " idx=" + uniqueIdx)
					EndIf

					; Type-1: mixed indices inside one traverse group
					If uniqueIdx.Length > 1
						;messages.Add("[Type1] Group #" + groupId + " has mixed InternalIndices: " + uniqueIdx)
						messages = AddString( messages, "[Type1] Group #" + groupId + " has mixed InternalIndices: " + uniqueIdx )
						If verboseToLog
							Debug.Trace("[PowerScan] Type1: group " + groupId + " mixed indices " + uniqueIdx)
						EndIf
					EndIf

					; Type-2: same internal index appears in >1 distinct traverse group
					Int mostFrequentIndex = MostFrequentInt(nonUniqueIdx, -1)
					;indexForGroup.Add(mostFrequentIndex)
					indexForGroup = AddInt( indexForGroup, mostFrequentIndex )
					indexForGroupStr += mostFrequentIndex + " "
					Int pos = _IndexOfInt(indicesSeen, mostFrequentIndex)
					;Debug.MessageBox( "group #" + groupId + "<br>mostFrequentIndex: " + mostFrequentIndex + "<br>indicesSeenStr: " + indicesSeenStr + "<br>firstGroupForIndexStr: " + firstGroupForIndexStr + "<br>indexForGroupStr: " + indexForGroupStr )
					If pos == -1
						;indicesSeen.Add(mostFrequentIndex)
						indicesSeen = AddInt( indicesSeen, mostFrequentIndex )
						indicesSeenStr += mostFrequentIndex + " "
						;firstGroupForIndex.Add(groupId)
						firstGroupForIndex = AddInt( firstGroupForIndex, groupId )
						firstGroupForIndexStr += groupId + " "
						String groupWithNewIndexPowerGridNodes = ""
						j = 0
						While j < group_.Length
							If j > 0
								groupWithNewIndexPowerGridNodes += ", "
							EndIf
							params2[0] = "WSFW"
							params2[1] = group_[j] as Form
							String groupWithNewIndexPowerGridNodeFormInfo = Utility.CallGlobalFunction( "WSFW_Utility", "GetFormInfo", params2 ) as String
							groupWithNewIndexPowerGridNodes += groupWithNewIndexPowerGridNodeFormInfo + "[" + GetPowerGridIndexForObject( workshopRef, group_[j] ) + "]"
							j += 1
						EndWhile
						;Debug.MessageBox( "group#" + groupId + "WithNewIndex(" + mostFrequentIndex + ")PowerGridNodes[gridIndex]: " + groupWithNewIndexPowerGridNodes )
					Else
						;messages.Add("[Type2] InternalIndex " + mostFrequentIndex + " occurs in multiple Traverse groups (first seen in #" + firstGroupForIndex[pos] + ", also in #" + groupId + ")")
						messages = AddString( messages, "[Type2] InternalIndex " + mostFrequentIndex + " occurs in multiple Traverse groups (first seen in #" + firstGroupForIndex[pos] + ", also in #" + groupId + ")" )
						If verboseToLog
							Debug.Trace("[PowerScan] Type2: index " + mostFrequentIndex + " in groups " + firstGroupForIndex[pos] + " and " + groupId)
						EndIf
						String groupWithSameIndexPowerGridNodes = ""
						j = 0
						While j < group_.Length
							If j > 0
								groupWithSameIndexPowerGridNodes += ", "
							EndIf
							params2[0] = "WSFW"
							params2[1] = group_[j] as Form
							String groupWithSameIndexPowerGridNodeFormInfo = Utility.CallGlobalFunction( "WSFW_Utility", "GetFormInfo", params2 ) as String
							groupWithSameIndexPowerGridNodes += groupWithSameIndexPowerGridNodeFormInfo + "[" + GetPowerGridIndexForObject( workshopRef, group_[j] ) + "]"
							j += 1
						EndWhile
						;Debug.MessageBox( "group#" + groupId + "WithSameIndex(" + mostFrequentIndex + ")PowerGridNodes[gridIndex]: " + groupWithSameIndexPowerGridNodes )
					EndIf

					groupId += 1
				EndIf
			EndIf
		EndIf

		i += 1
	EndWhile

	If messages.Length == 0
		;messages.Add("[OK] No Type1/Type2 power grid index inconsistencies detected. (groups built: " + groupId + ")")
		messages = AddString( messages, "[OK] No Type1/Type2 power grid index inconsistencies detected. (groups built: " + groupId + ")" )
	EndIf
	
	If createNewGrids
		i = 0
		While i < groupId
			Int idx1
			ObjectReference[] group1
			idx1 = indexForGroup[i]
			Int j = i + 1
			While j < groupId
				Int idx2 = indexForGroup[j]
				If idx2 == idx1
					ObjectReference[] group2 = TraversePowerGrid( firstSeedForGroup[j], False, maxTraverseCount )
					If group2.Length > 1
						indexForGroup[j] = CreatePowerGridFromRefs( workshopRef, group2, True )
						Debug.Trace( "WSFW group #" + i + " and group #" + j + " had the same index: " + idx1 + " -> group #" + j + " got new grid with index " + indexForGroup[j] )
					ElseIf group2.Length == 1
						If RemoveExistingObjectFromPowerGrid( workshopRef, group2[0] )
							Debug.Trace( "WSFW group #" + j + " is only a single object -> removed from grid with index: " + idx1 )
						Else
							Debug.Trace( "WSFW group #" + j + " is only a single object -> FAILED to remove from grid with index: " + idx1 )
						EndIf
					Else
						Debug.Trace( "WSFW group #" + j + " is EMPTY" )
					EndIf
				EndIf
				j += 1
			EndWhile
			i += 1
		EndWhile
	EndIf
	
	If reconnectResidualGridFragments
		Int[] groupIds = new Int[groupId]
		i = 0
		While i < groupId
			groupIds[i] = i
			i += 1
		EndWhile
		Int[] plan = ComputeWirePlan(groupIds, indexForGroup, firstSeedForGroup, maxTraverseCount, 0.0 ) ; set >0 to cap max wire length

		int k = 0
		while k < plan.Length
				ObjectReference[] group1 = TraversePowerGrid( firstSeedForGroup[plan[k]], False, maxTraverseCount )
				ObjectReference[] group2 = TraversePowerGrid( firstSeedForGroup[plan[k + 1]], False, maxTraverseCount )
				ObjectReference[] pair = ClosestPair3D( group1, group2, False, maxTraverseCount)
				ConnectRefsWithPylons( pair, workshopRef, plan[k], plan[k + 1], 1100.0 )
			k += 2
		endWhile
	EndIf

	If reconnectResidualGridFragments && 0
		i = 0
		While i < groupId
			;If !_HasInt(handledGroupIds, i)
				Int idx1
				ObjectReference[] group1
				ObjectReference[] closestPairFinal
				Float closestDistance = 9999999.9
				Int closestGroup = -1
				idx1 = indexForGroup[i]
				group1 = TraversePowerGrid( firstSeedForGroup[i], False, maxTraverseCount )
				Int j = i + 1
				While j < groupId
					If j != i
						Int idx2 = indexForGroup[j]
						If idx2 == idx1
							ObjectReference[] group2 = TraversePowerGrid( firstSeedForGroup[j], False, maxTraverseCount )
							ObjectReference[] closestPair = ClosestPair3D( group1, group2, False, maxTraverseCount)
							Float distance = closestPair[0].GetDistance( closestPair[1] )
							If distance < closestDistance
								closestDistance = distance
								closestGroup = j
								closestPairFinal = closestPair
							EndIf
						EndIf
					EndIf
					j += 1
				EndWhile
				If closestGroup > -1
					ConnectRefsWithPylons( closestPairFinal, workshopRef, i, closestGroup, 1100.0 )
				EndIf
			;EndIf
			i += 1
		EndWhile
	EndIf

	If 0
		If reconnectResidualGridFragments
			Int[] handled = New Int[0]
			Int[] ids = New Int[0]
			i = 0
			While i < groupId
				_DFS_Group( i, ids, handled, groupId, indexForGroup, firstSeedForGroup, maxTraverseCount, workshopRef, finalPairsToConnect )
				i += 1
			EndWhile
			i = 0
			While i < finalPairsToConnect.Length
				ObjectReference[] pair = New ObjectReference[2]
				pair[0] = finalPairsToConnect[i]
				pair[1] = finalPairsToConnect[i + 1]
				ConnectRefsWithPylons( pair, workshopRef, -1, -1, 1100.0 )
				i += 2
			EndWhile
		EndIf
	EndIf

	return messages
EndFunction


Int[] Function ComputeWirePlan( Int[] groupIds, Int[] indexForGroup, ObjectReference[] firstSeedForGroup, Int maxTraverseCount, float maxWireLength = 0.0 ) Global
	int[] gridIndices = _GetUniqueIndices(groupIds, indexForGroup)

	Int[] allPairs = new Int[0]

	int i = 0
	while i < gridIndices.Length
		Int[] groupSet = _FilterByIndex(groupIds, gridIndices[i], indexForGroup)
		if groupSet.Length >= 2
			Int[] mst = _PrimMST(groupSet, maxWireLength, firstSeedForGroup, maxTraverseCount)
			int j = 0
			While j < mst.Length
				allPairs = AddInt( allPairs, mst[j] )
				j += 1
			EndWhile
		endif
		i += 1
	endWhile

	return allPairs
EndFunction
Int[] Function _PrimMST(Int[] g, float maxWireLength, ObjectReference[] firstSeedForGroup, Int maxTraverseCount) Global
	int n = g.Length
	bool[] inTree = new bool[n]
	inTree[0] = true

	Int[] result = new Int[0]
	int edgesAdded = 0

	while edgesAdded < (n - 1)
		float bestD = 0.0
		int bestI = -1
		int bestJ = -1

		int i = 0
		while i < n
			if inTree[i]
				int j = 0
				while j < n
					if !inTree[j] && j != i
						ObjectReference[] group1 = TraversePowerGrid( firstSeedForGroup[g[i]], False, maxTraverseCount )
						ObjectReference[] group2 = TraversePowerGrid( firstSeedForGroup[g[j]], False, maxTraverseCount )
						ObjectReference[] closestPair = ClosestPair3D( group1, group2, False, maxTraverseCount)
						float d = closestPair[0].GetDistance(closestPair[1]) ; <-- Papyrus native
						if (bestI < 0) || (d < bestD)
							if (maxWireLength <= 0.0) || (d <= maxWireLength)
								bestD = d
								bestI = i
								bestJ = j
							endif
						endif
					endif
					j += 1
				endWhile
			endif
			i += 1
		endWhile

		if bestI < 0
			; No permissible edge (likely due to maxWireLength). Stop this group.
			;break
		else

			result = AddInt(result, g[bestI])
			result = AddInt(result, g[bestJ])

			inTree[bestJ] = true
			edgesAdded += 1
		endif
	endWhile

	return result
EndFunction
Int[] Function _FilterByIndex(Int[] groupIds, int index, Int[] indexForGroup) Global
	Int[] outArr = new Int[0]
	int i = 0
	while i < groupIds.Length
		if indexForGroup[groupIds[i]] == index
			outArr = AddInt(outArr, groupIds[i])
		endif
		i += 1
	endWhile
	return outArr
EndFunction
int[] Function _GetUniqueIndices(Int[] groupIds, Int[] indexForGroup) Global
	int[] indices = new int[0]
	int i = 0
	while i < groupIds.Length
		int idx = indexForGroup[groupIds[i]]
		if !_HasInt(indices, idx)
			indices = AddInt(indices, idx)
		endif
		i += 1
	endWhile
	return indices
EndFunction


Function _DFS_Group( Int newId, Int[] aiGroupIds, Int[] handled, Int maxId, Int[] indexForGroup, ObjectReference[] firstSeedForGroup, Int maxTraverseCount, ObjectReference workshopRef, ObjectReference[] finalPairsToConnect ) global
	If aiGroupIds.Length > 0
		_AddUniqueInt( handled, aiGroupIds[aiGroupIds.Length - 1] )
	EndIf
	_AddUniqueInt( aiGroupIds, newId )
	Var[] params2 = New Var[2]
	Int idx1
	ObjectReference[] group1
	ObjectReference[] group1final
	Float closestDistance = 9999999.9
	Int groupIdFinal
	Int closestGroup = -1
	Int i = 0
	While i < aiGroupIds.Length
		idx1 = indexForGroup[i]
		group1 = TraversePowerGrid( firstSeedForGroup[i], False, maxTraverseCount )
		Int j = 0
		While j < maxId
			If j != i && !_HasInt(handled, j)
				Int idx2 = indexForGroup[i]
				If idx2 == idx1
					ObjectReference[] group2 = TraversePowerGrid( firstSeedForGroup[j], False, maxTraverseCount )
					ObjectReference[] closestPair = ClosestPair3D( group1, group2, False, maxTraverseCount)
					Float distance = closestPair[0].GetDistance( closestPair[1] )
					If distance < closestDistance
						closestDistance = distance
						closestGroup = j
						groupIdFinal = i
						group1final = group1
					EndIf
				EndIf
			EndIf
			j += 1
		EndWhile
		i += 1
	EndWhile
	If closestGroup > -1
		ObjectReference[] group2 = TraversePowerGrid( firstSeedForGroup[closestGroup], False, maxTraverseCount )
		ObjectReference[] closestPair = ClosestPair3D( group1final, group2, False, maxTraverseCount)
		;finalPairsToConnect.Add( closestPair[0] )
		;finalPairsToConnect.Add( closestPair[1] )
		finalPairsToConnect = AddObjectReference( finalPairsToConnect, closestPair[0] )
		finalPairsToConnect = AddObjectReference( finalPairsToConnect, closestPair[1] )
		_DFS_Group( closestGroup, aiGroupIds, handled, maxId, indexForGroup, firstSeedForGroup, maxTraverseCount, workshopRef, finalPairsToConnect )
	EndIf
EndFunction


Function ConnectRefsWithPylons( ObjectReference[] closestPair, ObjectReference workshopRef, Int groupId1, Int groupId2, Float maxDistance = 1100.0 ) global
	Var[] params2 = New Var[2]
	Form powerPylon = Game.GetFormFromFile(0x0015D76F, "Fallout4.esm")
	Keyword WorkshopItemKeyword = Game.GetFormFromFile(0x00054BA6, "Fallout4.esm") as Keyword
	Form wireBase = Game.GetFormFromFile(0x0001D971, "Fallout4.esm")
	
	params2[0] = "WSFW"
	params2[1] = closestPair[0] as Form
	String closestPairFirstFormInfo = Utility.CallGlobalFunction( "WSFW_Utility", "GetFormInfo", params2 ) as String
	params2[0] = "WSFW"
	params2[1] = closestPair[1] as Form
	String closestPairSecondFormInfo = Utility.CallGlobalFunction( "WSFW_Utility", "GetFormInfo", params2 ) as String
	
	Float distance = closestPair[0].GetDistance( closestPair[1] )
	If distance <= maxDistance
		Debug.MessageBox( "creating " + distance + " long wire between group #" + groupId1 + " and group #" + groupId2 + "<br>closestPair: group #" + groupId1 + " " + closestPairFirstFormInfo + ", group #" + groupId2 + " " + closestPairSecondFormInfo )
		closestPair[0].CreateWire( closestPair[1], wireBase )
	Else
		Int numberOfPylons = Math.Floor( distance / maxDistance )
		Float pylonDistance = distance / (numberOfPylons + 1)
		;Debug.MessageBox( "distance: " + distance + "<br>fPowerConnectionMaxLength: " + Game.GetGameSettingFloat( "fPowerConnectionMaxLength" ) + "numberOfPylons: " + numberOfPylons + "<br>pylonDistance: " + pylonDistance )
		ObjectReference node1
		ObjectReference node2
		Int k = 0
		While k < numberOfPylons + 1
			If k == 0
				node1 = closestPair[0]
			Else
				node1 = node2
			EndIf
			If k < numberOfPylons
				node2 = Game.GetPlayer().PlaceAtMe( powerPylon, 1, False, True, False )
				Float[] coordinates = GetPointInDirection( closestPair[0], closestPair[1], pylonDistance * (k + 1) )
				node2.SetPosition( coordinates[0], coordinates[1], coordinates[2] )
				node2.Enable()
				Utility.Wait( 0.5 )
				node2.MoveToNearestNavmeshLocation()
				node2.SetLinkedRef( workshopRef, WorkshopItemKeyword )
				Utility.Wait( 0.5 )
			Else
				node2 = closestPair[1]
			EndIf
			params2[0] = "WSFW"
			params2[1] = node1 as Form
			String node1FormInfo = Utility.CallGlobalFunction( "WSFW_Utility", "GetFormInfo", params2 ) as String
			params2[0] = "WSFW"
			params2[1] = node2 as Form
			String node2FormInfo = Utility.CallGlobalFunction( "WSFW_Utility", "GetFormInfo", params2 ) as String
			If k == 0
				Debug.MessageBox( "creating " + pylonDistance + " long wire between group #" + groupId1 + " " + node1FormInfo + " and injected pylon #" + (k + 1) + " " + node2FormInfo )
			ElseIf k < numberOfPylons
				Debug.MessageBox( "creating " + pylonDistance + " long wire between injected pylon #" + k + " " + node1FormInfo + " and injected pylon #" + (k + 1) + " " + node2FormInfo )
			Else
				Debug.MessageBox( "creating " + pylonDistance + " long wire between injected pylon #" + k + " " + node1FormInfo + " and group #" + groupId2 + " " + node2FormInfo )
			EndIf
			node1.CreateWire( node2, wireBase )
			k += 1
		EndWhile
	EndIf
EndFunction


Function TestPowerGridFunctions( ObjectReference workshop_ref, ObjectReference akRefToRemove ) global

	Int i
	PowerGridStatistics pgs
	Var[] params2 = New Var[2]
	
	Int powerGridCount = GetPowerGridCount( workshop_ref )
	Int[] goodPowerGridIndices = GetGoodPowerGridIndices( workshop_ref )
	String goodPowerGrids = ""
	i = 0
	While i < goodPowerGridIndices.Length
		If i > 0
			goodPowerGrids += ", "
		EndIf
		goodPowerGrids += goodPowerGridIndices[i]
		i += 1
	EndWhile
	Int[] corruptPowerGridIndices = GetCorruptPowerGridIndices( workshop_ref )
	String corruptPowerGrids = ""
	i = 0
	While i < corruptPowerGridIndices.Length
		If i > 0
			corruptPowerGrids += ", "
		EndIf
		corruptPowerGrids += corruptPowerGridIndices[i]
		i += 1
	EndWhile
	Debug.MessageBox( "powerGridCount: " + powerGridCount + "<br>" + "goodPowerGridIndices: " + goodPowerGrids + "<br>" + "corruptPowerGridIndices: " + corruptPowerGrids )
	Utility.Wait( 0.5 )
	
	ScanPowerGrid( workshop_ref )
	Debug.MessageBox( "power grids scanned" )
	Utility.Wait( 0.5 )
	
	ScanPowerGridWithFilter( workshop_ref, goodPowerGridIndices )
	Debug.MessageBox( "good power grids scanned" )
	Utility.Wait( 0.5 )
	
	ScanPowerGridWithFilter( workshop_ref, corruptPowerGridIndices )
	Debug.MessageBox( "corrupt power grids scanned" )
	Utility.Wait( 0.5 )
	
	Keyword WorkshopItemKeyword = Game.GetFormFromFile( 0x00054BA6, "Fallout4.esm" ) as Keyword
	ObjectReference[] workshopObjects = workshop_ref.GetRefsLinkedToMe( WorkshopItemKeyword )
	
	String[] report = ScanForPowerGridCorruption(workshop_ref, workshopObjects, False, 8192)
	i = 0
	while i < report.Length
		Debug.MessageBox(report[i]) ; or dump to a log UI
		i += 1
	endWhile
	Utility.Wait( 0.5 )
	
	pgs = CheckAndFixPowerGrid( workshop_ref, 0 )
	Debug.MessageBox( "power grids checked" + "<br>" + "corrupt: " + pgs.corrupt + "<br>" + "checked: " + pgs.checked + "<br>" + "existingNodes: " + pgs.existingNodes + "<br>" + "deletedNodes: " + pgs.deletedNodes + "<br>" + "numCorruptGrids: " + pgs.numCorruptGrids + "<br>" + "totalNodes: " + pgs.totalNodes + "<br>" + "totalGrids: " + pgs.totalGrids )
	Utility.Wait( 0.5 )
	
	pgs = CheckAndFixPowerGridWithFilter( workshop_ref, 0, goodPowerGridIndices )
	Debug.MessageBox( "good power grids checked" + "<br>" + "corrupt: " + pgs.corrupt + "<br>" + "checked: " + pgs.checked + "<br>" + "existingNodes: " + pgs.existingNodes + "<br>" + "deletedNodes: " + pgs.deletedNodes + "<br>" + "numCorruptGrids: " + pgs.numCorruptGrids + "<br>" + "totalNodes: " + pgs.totalNodes + "<br>" + "totalGrids: " + pgs.totalGrids )
	Utility.Wait( 0.5 )
	
	pgs = CheckAndFixPowerGridWithFilter( workshop_ref, 0, CorruptPowerGridIndices )
	Debug.MessageBox( "corrupt power grids checked" + "<br>" + "corrupt: " + pgs.corrupt + "<br>" + "checked: " + pgs.checked + "<br>" + "existingNodes: " + pgs.existingNodes + "<br>" + "deletedNodes: " + pgs.deletedNodes + "<br>" + "numCorruptGrids: " + pgs.numCorruptGrids + "<br>" + "totalNodes: " + pgs.totalNodes + "<br>" + "totalGrids: " + pgs.totalGrids )
	Utility.Wait( 0.5 )
	
	Int[] deletedNodeFormIDs = GetDeletedNodeFormIDs( workshop_ref )
	String deletedNodes = ""
	i = 0
	While i < deletedNodeFormIDs.Length
		If i > 0
			deletedNodes += ", "
		EndIf
		deletedNodes += GetFormIDHex( deletedNodeFormIDs[i] )
		i += 1
	EndWhile
	Debug.MessageBox( "deletedNodes: " + deletedNodes )
	Utility.Wait( 0.5 )
	
	Keyword WorkshopCanBePowered = Game.GetFormFromFile( 0x0003037E, "Fallout4.esm" ) as Keyword
	Keyword WorkshopPowerConnection = Game.GetFormFromFile( 0x00054BA4, "Fallout4.esm" ) as Keyword
	Int[] existingNodeFormIDs = GetExistingNodeFormIDs( workshop_ref )
	Int[] corruptNodeFormIDs = New Int[128]
	Int[] goodNodeFormIDs = New Int[128]
	ObjectReference lastGoodNode
	String existingNodes = ""
	String corruptNodes = ""
	String goodNodes = ""
	i = 0
	Int j = 0
	Int k = 0
	Int l = 0
	While i < existingNodeFormIDs.Length
		ObjectReference existingNodeRef = Game.GetForm( existingNodeFormIDs[i] ) as ObjectReference
		If existingNodeRef.GetBaseObject().HasKeyword( WorkshopCanBePowered ) || existingNodeRef.GetBaseObject().HasKeyword( WorkshopPowerConnection )
			If l > 0
				existingNodes += ", "
			EndIf
			params2[0] = "WSFW"
			params2[1] = existingNodeRef as Form
			String existingNodeFormInfo = Utility.CallGlobalFunction( "WSFW_Utility", "GetFormInfo", params2 ) as String
			;existingNodes += GetFormIDHex( existingNodeFormIDs[i] )
			existingNodes += existingNodeFormInfo
			ObjectReference[] ConnectedObjects
			ObjectReference[] ConnectedWires = existingNodeRef.GetConnectedObjects()
			Int connectedObjectsLength = 0
			Int iws = 0
			While iws < ConnectedWires.Length
				ConnectedObjects = ConnectedWires[iws].GetConnectedObjects()
				Int ios = 0
				While ios < ConnectedObjects.Length
					If ConnectedObjects[ios] != existingNodeRef
						connectedObjectsLength += 1
					EndIf
					ios += 1
				EndWhile
				iws += 1
			EndWhile
			existingNodes += "[" + ConnectedWires.Length + "," + connectedObjectsLength + "]"
			If existingNodeRef.GetLinkedRef( WorkshopItemKeyword ) == None || !existingNodeRef.IsWithinBuildableArea( workshop_ref )
				corruptNodeFormIDs[j] = existingNodeFormIDs[i]
				corruptNodes += existingNodeFormInfo
				corruptNodes += "[" + ConnectedWires.Length + "," + connectedObjectsLength + "]"
				j += 1
			Else
				goodNodeFormIDs[k] = existingNodeFormIDs[i]
				goodNodes += existingNodeFormInfo
				goodNodes += "[" + ConnectedWires.Length + "," + connectedObjectsLength + "]"
				lastGoodNode = Game.GetForm( goodNodeFormIDs[k] ) as ObjectReference
				k += 1
			EndIf
			l += 1
		EndIf
		i += 1
	EndWhile
	Debug.MessageBox( "existingNodes[wires,neighbors]: " + existingNodes )
	Debug.MessageBox( "corruptNodes[wires,neighbors]: " + corruptNodes )
	Debug.MessageBox( "goodNodes[wires,neighbors]: " + goodNodes )
	Utility.Wait( 0.5 )
	
	String orphanedWires = ""
	Int orphanedWiresCount = 0
	i = 0
	While i < workshopObjects.Length
		If workshopObjects[i].GetBaseObject().GetFormID() == 0x0001D971
			ObjectReference[] ConnectedObjects = workshopObjects[i].GetConnectedObjects()
			ObjectReference validConnectedObject
			Int connectedObjectsLength = 0
			Int ios = 0
			While ios < ConnectedObjects.Length
				If ConnectedObjects[ios] is ObjectReference
					validConnectedObject = ConnectedObjects[ios]
					connectedObjectsLength += 1
				EndIf
				ios += 1
			EndWhile
			If connectedObjectsLength < 2
				If orphanedWiresCount > 0
					orphanedWires += ", "
				EndIf
				orphanedWires += GetFormIDHex( workshopObjects[i].GetFormID() )
				orphanedWiresCount += 1
			EndIf
		EndIf
		i += 1
	EndWhile
	Debug.MessageBox( "orphanedWires: " + orphanedWires )
	Utility.Wait( 0.5 )
	
	Int[] removedDeletedNodeFormIDs = RemoveNodesFromPowerGrid( workshop_ref, deletedNodeFormIDs )
	If lastGoodNode
		RefreshPowerGrids( lastGoodNode, workshop_ref )
	EndIf
	String removedDeletedNodes = ""
	i = 0
	While i < removedDeletedNodeFormIDs.Length
		If i > 0
			removedDeletedNodes += ", "
		EndIf
		removedDeletedNodes += GetFormIDHex( removedDeletedNodeFormIDs[i] )
		i += 1
	EndWhile
	Debug.MessageBox( "removedDeletedNodes: " + removedDeletedNodes )
	Utility.Wait( 0.5 )
	
	Int[] removedCorruptNodeFormIDs = RemoveNodesFromPowerGrid( workshop_ref, corruptNodeFormIDs )
	If lastGoodNode
		RefreshPowerGrids( lastGoodNode, workshop_ref )
	EndIf
	String removedCorruptNodes = ""
	i = 0
	While i < removedCorruptNodeFormIDs.Length
		If i > 0
			removedCorruptNodes += ", "
		EndIf
		ObjectReference removedCorruptNodeRef = Game.GetForm( removedCorruptNodeFormIDs[i] ) as ObjectReference
		params2[0] = "WSFW"
		params2[1] = removedCorruptNodeRef as Form
		String removedCorruptNodeFormInfo = Utility.CallGlobalFunction( "WSFW_Utility", "GetFormInfo", params2 ) as String
		;removedCorruptNodes += GetFormIDHex( removedCorruptNodeFormIDs[i] )
		removedCorruptNodes += removedCorruptNodeFormInfo
		i += 1
	EndWhile
	Debug.MessageBox( "removedCorruptNodes: " + removedCorruptNodes )
	Utility.Wait( 0.5 )
	
	String removedOrphanedWires = ""
	Int removedOrphanedWiresCount = 0
	i = 0
	While i < workshopObjects.Length
		If workshopObjects[i].GetBaseObject().GetFormID() == 0x0001D971
			ObjectReference[] ConnectedObjects = workshopObjects[i].GetConnectedObjects()
			Int connectedObjectsLength = 0
			Int ios = 0
			While ios < ConnectedObjects.Length
				If ConnectedObjects[ios] is ObjectReference
					connectedObjectsLength += 1
				EndIf
				ios += 1
			EndWhile
			If connectedObjectsLength < 2
				If removedOrphanedWiresCount > 0
					removedOrphanedWires += ", "
				EndIf
				removedOrphanedWires += GetFormIDHex( workshopObjects[i].GetFormID() )
				workshopObjects[i].Disable()
				workshopObjects[i].Delete()
				removedOrphanedWiresCount += 1
			EndIf
		EndIf
		i += 1
	EndWhile
	Debug.MessageBox( "removedOrphanedWires: " + removedOrphanedWires )
	Utility.Wait( 0.5 )
	
	; reconnect residual power grid fragments
	ScanForPowerGridCorruption(workshop_ref, workshopObjects, False, 8192, True, True)
	Utility.Wait( 0.5 )
	
	; split residual grid fragments into new individual grids
	;ScanForPowerGridCorruption(workshop_ref, workshopObjects, False, 8192, True, False, True)
	;Utility.Wait( 0.5 )
	
	report = ScanForPowerGridCorruption(workshop_ref, workshopObjects, False, 8192)
	i = 0
	while i < report.Length
		Debug.MessageBox(report[i]) ; or dump to a log UI
		i += 1
	endWhile
	Utility.Wait( 0.5 )
	
	pgs = CheckAndFixPowerGrid( workshop_ref, 0 )
	Debug.MessageBox( "power grids checked" + "<br>" + "corrupt: " + pgs.corrupt + "<br>" + "checked: " + pgs.checked + "<br>" + "existingNodes: " + pgs.existingNodes + "<br>" + "deletedNodes: " + pgs.deletedNodes + "<br>" + "numCorruptGrids: " + pgs.numCorruptGrids + "<br>" + "totalNodes: " + pgs.totalNodes + "<br>" + "totalGrids: " + pgs.totalGrids )
	Utility.Wait( 0.5 )
	
	Int gridIndex
	
	gridIndex = GetPowerGridIndexForObject( workshop_ref, workshop_ref )
	
	If gridIndex > -1
		Debug.MessageBox( "object " + GetFormIDHex( workshop_ref.GetFormID() ) + " is in power grid #" + gridIndex )
	Else
		Debug.MessageBox( "object " + GetFormIDHex( workshop_ref.GetFormID() ) + " is not part of any power grid" )
	EndIf
	Utility.Wait( 0.5 )
	
	gridIndex = GetPowerGridIndexForObject( workshop_ref, akRefToRemove )
	
	If gridIndex > -1
		Debug.MessageBox( "object " + GetFormIDHex( akRefToRemove.GetFormID() ) + " is in power grid #" + gridIndex )
	Else
		Debug.MessageBox( "object " + GetFormIDHex( akRefToRemove.GetFormID() ) + " is not part of any power grid" )
	EndIf
	Utility.Wait( 0.5 )
	
	Debug.MessageBox( "object " + GetFormIDHex( akRefToRemove.GetFormID() ) + " removed: " + RemoveExistingObjectFromPowerGrid( workshop_ref, akRefToRemove ) )
	Utility.Wait( 0.5 )
	
	gridIndex = GetPowerGridIndexForObject( workshop_ref, akRefToRemove )
	
	If gridIndex > -1
		Debug.MessageBox( "object " + GetFormIDHex( akRefToRemove.GetFormID() ) + " is in power grid #" + gridIndex )
	Else
		Debug.MessageBox( "object " + GetFormIDHex( akRefToRemove.GetFormID() ) + " is not part of any power grid" )
	EndIf

EndFunction


; -- helper functions --

; inCount   = source count before rank gated filtering
; bFromRecipe = true if this came from COBJ (built object), false if from MiscObject junk split
Int Function ComputePayout(Form comp, Int inCount, Bool bFromRecipe, Actor akPlayer) global
	if inCount <= 0
		return 0
	EndIf
	
	If comp && comp is Component
	Else
		return 0
	EndIf
	
	Float recipeScalar = (comp as Component).GetScrapScalar().GetValue()
	if recipeScalar <= 0.0
		recipeScalar = 0.25 ; fallback to vanilla default
	endif

	; 1) Start from base count (apply COBJ scalar if needed)
	Int count = inCount
	if bFromRecipe
		count = Math.Floor(inCount * recipeScalar)
		if count < 0
			count = 0
		EndIf
	EndIf

	; 2) Zero-yield is always zero
	if IsZeroYield(comp)
		return 0
	EndIf

	Int rank = GetScrapperRank(akPlayer)

	; 3) Rarity gating by rank
	if IsRare(comp)
		if rank < 2
			return 0
		EndIf
	ElseIf IsUncommon(comp)
		if rank < 1
			return 0
		EndIf
	; Common → no gate
	EndIf

	; 4) Rank 3 “double (or double+1)”
	if rank >= 3
		; mirrors “approximately doubles (double or double+1)” described on wiki
		count = count * 2 + (count % 2)
	EndIf
	
	If count < 0
		count = 0
	EndIf

	return count
EndFunction


Int Function GetScrapperRank( Actor ak ) global

	Perk Scrapper01 = Game.GetFormFromFile( 0x00065E65, "Fallout4.esm" ) as Perk
	Perk Scrapper02 = Game.GetFormFromFile( 0x001D2483, "Fallout4.esm" ) as Perk
	Perk Scrapper03
	If Game.IsPluginInstalled( "DLCCoast.esm" )
		Scrapper03 = Game.GetFormFromFile( 0x030423A5, "DLCCoast.esm" ) as Perk
	EndIf
	
	If ak.HasPerk( Scrapper03 )
		return 3
	ElseIf ak.HasPerk( Scrapper02 )
		return 2
	ElseIf ak.HasPerk( Scrapper01 )
		return 1
	EndIf
	return 0

EndFunction


Bool Function IsZeroYield( Form comp ) global   ; adhesive & oil never returned
	
	Form[] ZeroYieldComponents = New Form[0]
	ZeroYieldComponents.Add( Game.GetFormFromFile( 0x0001FAA5, "Fallout4.esm" ) )	; c_Adhesive "Adhesive" [CMPO:0001FAA5]
	ZeroYieldComponents.Add( Game.GetFormFromFile( 0x0001FAB4, "Fallout4.esm" ) )	; c_Oil "Oil" [CMPO:0001FAB4]
	
	return ZeroYieldComponents.Find( comp ) >= 0

EndFunction


Bool Function IsRare( Form comp ) global
	
	Form[] RareComponents = New Form[0]
	RareComponents.Add( Game.GetFormFromFile( 0x0001FA8C, "Fallout4.esm" ) )	; c_Acid "Acid" [CMPO:0001FA8C]
	RareComponents.Add( Game.GetFormFromFile( 0x0001FA96, "Fallout4.esm" ) )	; c_Antiseptic "Antiseptic" [CMPO:0001FA96]
	RareComponents.Add( Game.GetFormFromFile( 0x0001FA97, "Fallout4.esm" ) )	; c_Asbestos "Asbestos" [CMPO:0001FA97]
	RareComponents.Add( Game.GetFormFromFile( 0x0001FA94, "Fallout4.esm" ) )	; c_AntiBallisticFiber "Ballistic Fiber" [CMPO:0001FA94]
	RareComponents.Add( Game.GetFormFromFile( 0x0001FA9B, "Fallout4.esm" ) )	; c_Circuitry "Circuitry" [CMPO:0001FA9B]
	RareComponents.Add( Game.GetFormFromFile( 0x0001FA9F, "Fallout4.esm" ) )	; c_Crystal "Crystal" [CMPO:0001FA9F]
	RareComponents.Add( Game.GetFormFromFile( 0x0001FAA0, "Fallout4.esm" ) )	; c_FiberOptics "Fiber Optics" [CMPO:0001FAA0]
	RareComponents.Add( Game.GetFormFromFile( 0x0001FAA6, "Fallout4.esm" ) )	; c_Gold "Gold" [CMPO:0001FAA6]
	RareComponents.Add( Game.GetFormFromFile( 0x0001FAB3, "Fallout4.esm" ) )	; c_NuclearMaterial "Nuclear Material" [CMPO:0001FAB3]
	
	return RareComponents.Find( comp ) >= 0

EndFunction


Bool Function IsUncommon( Form comp ) global
	
	Form[] UncommonComponents = New Form[0]
	UncommonComponents.Add( Game.GetFormFromFile( 0x0001FA91, "Fallout4.esm" ) )	; c_Aluminum "Aluminum" [CMPO:0001FA91]
	UncommonComponents.Add( Game.GetFormFromFile( 0x0001FA9C, "Fallout4.esm" ) )	; c_Copper "Copper" [CMPO:0001FA9C]
	UncommonComponents.Add( Game.GetFormFromFile( 0x0001FA9D, "Fallout4.esm" ) )	; c_Cork "Cork" [CMPO:0001FA9D]
	UncommonComponents.Add( Game.GetFormFromFile( 0x0005A0C7, "Fallout4.esm" ) )	; c_Fertilizer "Fertilizer" [CMPO:0005A0C7]
	UncommonComponents.Add( Game.GetFormFromFile( 0x0001FAA1, "Fallout4.esm" ) )	; c_Fiberglass "Fiberglass" [CMPO:0001FAA1]
	UncommonComponents.Add( Game.GetFormFromFile( 0x0001FAB0, "Fallout4.esm" ) )	; c_Gears "Gear" [CMPO:0001FAB0]
	UncommonComponents.Add( Game.GetFormFromFile( 0x0001FAA4, "Fallout4.esm" ) )	; c_Glass "Glass" [CMPO:0001FAA4]
	UncommonComponents.Add( Game.GetFormFromFile( 0x0001FAAD, "Fallout4.esm" ) )	; c_Lead "Lead" [CMPO:0001FAAD]
	UncommonComponents.Add( Game.GetFormFromFile( 0x0003D294, "Fallout4.esm" ) )	; c_Screws "Screw" [CMPO:0003D294]
	UncommonComponents.Add( Game.GetFormFromFile( 0x0001FABB, "Fallout4.esm" ) )	; c_Silver "Silver" [CMPO:0001FABB]
	UncommonComponents.Add( Game.GetFormFromFile( 0x0001FABC, "Fallout4.esm" ) )	; c_Springs "Spring" [CMPO:0001FABC]
	
	return UncommonComponents.Find( comp ) >= 0

EndFunction


Function RefreshPowerGrids( ObjectReference node, ObjectReference workshop_ref ) global
	Form powerPylon = Game.GetFormFromFile(0x0015D76F, "Fallout4.esm")
	Keyword WorkshopItemKeyword = Game.GetFormFromFile( 0x00054BA6, "Fallout4.esm" ) as Keyword
	ObjectReference tmpNode = Game.GetPlayer().PlaceAtMe( powerPylon, 1, False, True, False )
	Int[] tmpNodeFormID = New Int[1]
	tmpNodeFormID[0] = tmpNode.GetFormID()
	tmpNode.MoveTo( node, Utility.RandomFloat( 50.0, 200.0 ), Utility.RandomFloat( 50.0, 200.0 ) )
	tmpNode.Enable()
	Utility.Wait( 0.5 )
	tmpNode.MoveToNearestNavmeshLocation()
	tmpNode.SetLinkedRef( workshop_ref, WorkshopItemKeyword )
	Utility.Wait( 0.5 )
	ObjectReference wireRef = node.CreateWire( tmpNode )
	Utility.Wait( 0.5 )
	tmpNode.Disable()
	tmpNode.Delete()
	RemoveNodesFromPowerGrid( workshop_ref, tmpNodeFormID )
	wireRef.Disable()
	wireRef.Delete()
EndFunction

; Find the closest pair between two groups.
; - excludeSame: if True, won't match the same ref when it appears in both arrays.
; - requireEnabled: if True, skips disabled refs.
; Returns [bestRef1, bestRef2]. If no valid pair, returns [None, None].
ObjectReference[] Function ClosestPair3D(ObjectReference[] groupA, ObjectReference[] groupB, Bool excludeSame = True, Bool requireEnabled = False) global
	ObjectReference[] result = new ObjectReference[2]
	result[0] = None
	result[1] = None

	If groupA == None || groupB == None || groupA.Length == 0 || groupB.Length == 0
		return result
	EndIf

	Float bestD2 = -1.0

	Int i = 0
	While i < groupA.Length
		ObjectReference a = groupA[i]

		Bool aOk = (a != None)
		If aOk && requireEnabled
			If a.IsDisabled()
				aOk = False
			EndIf
		EndIf

		If aOk
			Float ax = a.GetPositionX()
			Float ay = a.GetPositionY()
			Float az = a.GetPositionZ()

			Int j = 0
			While j < groupB.Length
				ObjectReference b = groupB[j]

				Bool bOk = (b != None)
				If bOk && requireEnabled
					If b.IsDisabled()
						bOk = False
					EndIf
				EndIf
				If bOk
					If !(excludeSame && (a == b))
						; squared distance for speed (no sqrt)
						Float dx = ax - b.GetPositionX()
						Float dy = ay - b.GetPositionY()
						Float dz = az - b.GetPositionZ()
						Float d2 = dx*dx + dy*dy + dz*dz

						; pick strictly smaller, or if equal keep the earlier pair (tie -> lower indices)
						If (bestD2 < 0.0) || (d2 < bestD2)
							bestD2 = d2
							result[0] = a
							result[1] = b
						EndIf
					EndIf
				EndIf
				j += 1
			EndWhile
		EndIf

		i += 1
	EndWhile

	return result
EndFunction


Float[] Function GetPointInDirection(ObjectReference refA, ObjectReference refB, Float d) global
	Float[] result = New Float[3]
    
	Float dx = refB.GetPositionX() - refA.GetPositionX()
    Float dy = refB.GetPositionY() - refA.GetPositionY()
    Float dz = refB.GetPositionZ() - refA.GetPositionZ()

    Float len = Math.Sqrt(dx*dx + dy*dy + dz*dz)
    If len <= 0.0
		result[0] = refA.GetPositionX()
		result[1] = refA.GetPositionY()
		result[2] = refA.GetPositionZ()
		Return result
    EndIf

    Float nx = dx / len
    Float ny = dy / len
    Float nz = dz / len

	result[0] = refA.GetPositionX() + nx * d
	result[1] = refA.GetPositionY() + ny * d
	result[2] = refA.GetPositionZ() + nz * d

    Return result
EndFunction


Bool Function _AddUniqueInt(Int[] arr, Int v) global
	Int i = 0
	while i < arr.Length
		if arr[i] == v
			return False
		endif
		i += 1
	endWhile
	;arr.Add(v)
	arr = AddInt( arr, v )
	return True
EndFunction


Bool Function _HasInt(Int[] arr, Int v) global
	if arr == None
		return False
	endif
	Int i = 0
	while i < arr.Length
		if arr[i] == v
			return True
		endif
		i += 1
	endWhile
	return False
EndFunction


Bool Function _HasRef(ObjectReference[] arr, ObjectReference r) global
	if arr == None || r == None
		return False
	endif
	Int i = 0
	while i < arr.Length
		if arr[i] == r
			return True
		endif
		i += 1
	endWhile
	return False
EndFunction


Int Function _IndexOfInt(Int[] arr, Int v) global
	If arr == None
		return -1
	EndIf
	Int i = 0
	While i < arr.Length
		If arr[i] == v
			return i
		EndIf
		i += 1
	EndWhile
	return -1
EndFunction


Int Function MostFrequentInt(Int[] arr, Int fallback = 0) global
	If arr == None || arr.Length == 0
		return fallback
	EndIf

	; Build unique values + counts + first-occurrence indices
	Int[] values   = new Int[0]
	Int[] counts   = new Int[0]
	Int[] firstIdx = new Int[0]

	Int i = 0
	While i < arr.Length
		Int v = arr[i]
		Int pos = _IndexOfInt(values, v)
		If pos == -1
			;values.Add(v)
			;counts.Add(1)
			;firstIdx.Add(i)
			values = AddInt( values, v )
			counts = AddInt( counts, 1 )
			firstIdx = AddInt( firstIdx, i )
		Else
			counts[pos] = counts[pos] + 1
		EndIf
		i += 1
	EndWhile

	; Pick best by (count desc, firstIdx asc)
	Int bestVal   = values[0]
	Int bestCount = counts[0]
	Int bestFirst = firstIdx[0]

	i = 1
	While i < values.Length
		Int c = counts[i]
		If c > bestCount
			bestVal   = values[i]
			bestCount = c
			bestFirst = firstIdx[i]
		Else
			If c == bestCount
				If firstIdx[i] < bestFirst
					bestVal   = values[i]
					bestFirst = firstIdx[i]
				EndIf
			EndIf
		EndIf
		i += 1
	EndWhile

	return bestVal
EndFunction


Bool Function _IsWire(ObjectReference r, Form wireBase) global
	If r == None || wireBase == None
		return False
	EndIf
	return (r.GetBaseObject() == wireBase)
EndFunction


Bool Function _ArrHas(ObjectReference[] arr, ObjectReference x) global
	if arr == None || x == None
		return False
	endif
	Int i = 0
	while i < arr.Length
		if arr[i] == x
			return True
		endif
		i += 1
	endWhile
	return False
EndFunction


String Function GetFormIDHex( Int thisFormID, Bool lightMaster = False ) global

	If !lightMaster
		Int ModIndexInt = GetModIndex( thisFormID )
		String ModIndexHex = DecToHex( ModIndexInt, 2 )
		Int StrippedFormIDInt = thisFormID - ModIndexInt * 0x1000000
		String StrippedFormIDHex = DecToHex( StrippedFormIDInt, 6 )
		
		return ModIndexHex + StrippedFormIDHex
	Else
		Int ModIndexInt = GetModIndex( thisFormID, True )
		String ModIndexHex = DecToHex( ModIndexInt, 3 )
		Int StrippedFormIDInt = thisFormID - ModIndexInt * 0x1000
		String StrippedFormIDHex = DecToHex( StrippedFormIDInt, 3 )
		
		return "FE" + ModIndexHex + StrippedFormIDHex
	EndIf
	
EndFunction


Int Function GetModIndex( Int aiFormID, Bool lightMaster = False ) global
    
	Int n
	
	If !lightMaster
		n = aiFormID
		If n < 0
			return 255 - ((n + 1) / -16777216)
		Else
			return (n / 0x1000000)
		EndIf
	Else
		n = aiFormID
		If n < 0
			return (255 - ((n + 1) / -4096)) - 0xFE
		Else
			return (n / 0x1000) - 0xFE
		EndIf
	EndIf
	
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


Int Function Mod( Int a, Int b ) global

	Float x = a / b
	Int y = Math.Floor( x )
	
	return a - (b * y)

EndFunction
