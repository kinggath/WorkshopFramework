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


; Completely deletes all power grids of a settlement. Recommended to use for settlements that are to be scrapped entirely.
Bool Function ResetPowerGrid( ObjectReference workshop_ref ) global native

; Checks and optionally fixes errors of settlement power grids. Takes an array of power grid indices as a filter parameter. Returns statistics data in PowerGridStatistics struct. Logs results.
; fixerrors = 0 - check settlement for power grid errors, but don't fix anything
; fixerrors = 1 - check settlement for power grid errors, and fix errors by removing bad power grids entirely (not recommended legacy feature)
; fixerrors = 2 - check settlement for power grid errors, and fix errors by cleaning bad power grids by removing invalid power nodes only (recommended)
PowerGridStatistics Function CheckAndFixPowerGridWithFilter( ObjectReference workshop_ref, Int fixerrors, Int[] gridFilter ) global native

; Checks and optionally fixes errors of settlement power grids. Returns statistics data in PowerGridStatistics struct. Logs results.
; fixerrors = 0 - check settlement for power grid errors, but don't fix anything
; fixerrors = 1 - check settlement for power grid errors, and fix errors by removing bad power grids entirely (not recommended legacy feature)
; fixerrors = 2 - check settlement for power grid errors, and fix errors by cleaning bad power grids by removing invalid power nodes only (recommended)
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

; Gets the indices of bad power grids of a settlement.
Int[] Function GetBadPowerGridIndices( ObjectReference workshop_ref ) global native

; Gets the FormIDs of all invalid power nodes.
Int[] Function GetInvalidNodeFormIDs( ObjectReference workshop_ref ) global native

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


Function TestPowerGridFunctions( ObjectReference workshop_ref, ObjectReference akRefToRemove ) global

	Int i
	PowerGridStatistics pgs
	
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
	Int[] badPowerGridIndices = GetBadPowerGridIndices( workshop_ref )
	String badPowerGrids = ""
	i = 0
	While i < badPowerGridIndices.Length
		If i > 0
			badPowerGrids += ", "
		EndIf
		badPowerGrids += badPowerGridIndices[i]
		i += 1
	EndWhile
	Debug.MessageBox( "powerGridCount: " + powerGridCount + "<br>" + "goodPowerGridIndices: " + goodPowerGrids + "<br>" + "badPowerGridIndices: " + badPowerGrids )
	Utility.Wait( 0.5 )
	
	ScanPowerGrid( workshop_ref )
	Debug.MessageBox( "power grids scanned" )
	Utility.Wait( 0.5 )
	
	ScanPowerGridWithFilter( workshop_ref, goodPowerGridIndices )
	Debug.MessageBox( "good power grids scanned" )
	Utility.Wait( 0.5 )
	
	ScanPowerGridWithFilter( workshop_ref, badPowerGridIndices )
	Debug.MessageBox( "bad power grids scanned" )
	Utility.Wait( 0.5 )
	
	pgs = CheckAndFixPowerGrid( workshop_ref, 0 )
	Debug.MessageBox( "power grids checked" + "<br>" + "broken: " + pgs.broken + "<br>" + "checked: " + pgs.checked + "<br>" + "validNodes: " + pgs.validNodes + "<br>" + "invalidNodes: " + pgs.invalidNodes + "<br>" + "numBadGrids: " + pgs.numBadGrids + "<br>" + "totalNodes: " + pgs.totalNodes + "<br>" + "totalGrids: " + pgs.totalGrids )
	Utility.Wait( 0.5 )
	
	pgs = CheckAndFixPowerGridWithFilter( workshop_ref, 0, goodPowerGridIndices )
	Debug.MessageBox( "good power grids checked" + "<br>" + "broken: " + pgs.broken + "<br>" + "checked: " + pgs.checked + "<br>" + "validNodes: " + pgs.validNodes + "<br>" + "invalidNodes: " + pgs.invalidNodes + "<br>" + "numBadGrids: " + pgs.numBadGrids + "<br>" + "totalNodes: " + pgs.totalNodes + "<br>" + "totalGrids: " + pgs.totalGrids )
	Utility.Wait( 0.5 )
	
	pgs = CheckAndFixPowerGridWithFilter( workshop_ref, 0, badPowerGridIndices )
	Debug.MessageBox( "bad power grids checked" + "<br>" + "broken: " + pgs.broken + "<br>" + "checked: " + pgs.checked + "<br>" + "validNodes: " + pgs.validNodes + "<br>" + "invalidNodes: " + pgs.invalidNodes + "<br>" + "numBadGrids: " + pgs.numBadGrids + "<br>" + "totalNodes: " + pgs.totalNodes + "<br>" + "totalGrids: " + pgs.totalGrids )
	Utility.Wait( 0.5 )
	
	Int[] invalidNodeFormIDs = GetInvalidNodeFormIDs( workshop_ref )
	String invalidNodes = ""
	i = 0
	While i < invalidNodeFormIDs.Length
		If i > 0
			invalidNodes += ", "
		EndIf
		invalidNodes += GetFormIDHex( invalidNodeFormIDs[i] )
		i += 1
	EndWhile
	Debug.MessageBox( "invalidNodes: " + invalidNodes )
	Utility.Wait( 0.5 )
	
	Int[] removedNodeFormIDs = RemoveNodesFromPowerGrid( workshop_ref, invalidNodeFormIDs )
	String removedNodes = ""
	i = 0
	While i < removedNodeFormIDs.Length
		If i > 0
			removedNodes += ", "
		EndIf
		removedNodes += GetFormIDHex( removedNodeFormIDs[i] )
		i += 1
	EndWhile
	Debug.MessageBox( "removedNodes: " + removedNodes )
	Utility.Wait( 0.5 )
	
	pgs = CheckAndFixPowerGrid( workshop_ref, 0 )
	Debug.MessageBox( "power grids checked" + "<br>" + "broken: " + pgs.broken + "<br>" + "checked: " + pgs.checked + "<br>" + "validNodes: " + pgs.validNodes + "<br>" + "invalidNodes: " + pgs.invalidNodes + "<br>" + "numBadGrids: " + pgs.numBadGrids + "<br>" + "totalNodes: " + pgs.totalNodes + "<br>" + "totalGrids: " + pgs.totalGrids )
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


; convenience functions for the test function
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
