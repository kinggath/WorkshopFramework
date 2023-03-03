; ---------------------------------------------
; WorkshopFramework:ObjectRefs:Thread_ExportObjectData.psc - by kinggath
; ---------------------------------------------
; Reusage Rights ------------------------------
; You are free to use this script or portions of it in your own mods, provided you give me credit in your description and maintain this section of comments in any released source code (which includes the IMPORTED SCRIPT CREDIT section to give credit to anyone in the associated Import scripts below).
; 
; Warning !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
; Do not directly recompile this script for redistribution without first renaming it to avoid compatibility issues with the mod this came from.
; 
; IMPORTED SCRIPT CREDITS
; N/A
; ---------------------------------------------

Scriptname WorkshopFramework:ObjectRefs:Thread_ExportObjectData extends WorkshopFramework:Library:ObjectRefs:Thread

import WorkshopFramework:Library:DataStructures
import WorkshopFramework:Library:UtilityFunctions

; -
; Consts
; -

String sLogDelimitter_Date = "|||"
String sLogDelimitter_LineType = ";;;"
String sLogDelimitter_LineItem = "~_~"
String sLogDelimitter_Plugin = "-|-"
String sLogDelimitter_Flags = "###"
String sLogDelimitter_ExtraData = ".#|"
; - 
; Editor Properties
; -

ActorValue Property WorkshopResourceObject Auto Const Mandatory
WorkshopFramework:F4SEManager Property F4SEManager Auto Const Mandatory
Keyword Property WorkshopPowerConnection Auto Const Mandatory
UniversalForm[] Property SkipForms Auto Const Mandatory
Keyword Property WorkshopWorkObject Auto Const Mandatory
ActorValue Property FoodAV Auto Const Mandatory
ActorValue Property WaterAV Auto Const Mandatory
ActorValue Property PowerGeneratedAV Auto Const Mandatory
Keyword Property WorkshopCanBePowered Auto Const Mandatory
Keyword Property ActorTypeTurret Auto Const Mandatory
Keyword Property IncludeIfDisabled Auto Const Mandatory
{ Point to vanilla keyword LinkDisable - this way any mod can add it to their items to allow them to be exported while hidden. }

Keyword Property WorkshopStackedItemParentKEYWORD Auto Const Mandatory

Faction Property DomesticAnimalFaction Auto Const Mandatory

GlobalVariable Property Setting_Export_IncludeAnimals Auto Const Mandatory
UniversalForm[] Property AlwaysAllowedActorTypes Auto Const Mandatory
{ Copy me from SettlementLayoutManager }

; -
; Properties
; -

WorkshopScript Property kWorkshopRef Auto Hidden
ObjectReference Property kObjectRef Auto Hidden
String Property sLogName Auto Hidden
Bool Property bIsLinkedWorkshopItem Auto Hidden
Form[] Property AdditionalSkipForms Auto Hidden
Var[] Property ExtraData Auto Hidden

; -
; Events
; -

; - 
; Functions 
; -
	
Function ReleaseObjectReferences()
	kObjectRef = None
	kWorkshopRef = None
	
	; In case any object refs were filled in
	ExtraData = new Var[0]
EndFunction


Function RunCode()
	if( ! ShouldExport())
		return
	endif
	
	Form BaseForm = kObjectRef.GetBaseObject()
	String sPluginName = F4SEManager.GetPluginNameFromForm(BaseForm)
	Float fX = kObjectRef.X
	Float fY = kObjectRef.Y
	Float fZ = kObjectRef.Z
	Float fAngleX = kObjectRef.GetAngleX()
	Float fAngleY = kObjectRef.GetAngleY()
	Float fAngleZ = kObjectRef.GetAngleZ()
	Float fScale = kObjectRef.GetScale()
	
	Bool bIsLootable = false
	
	Bool bIsActor = false
	Bool bIsAssignable = false
	Bool bIsCreated = false
	Bool bIsFarmAnimal = false
	Bool bIsFood = false
	Bool bIsGenerator = false
	Bool bIsPowered = false
	Bool bIsTamedCreature = false
	Bool bIsTurret = false
	Bool bIsWater = false
	
	if(bIsLinkedWorkshopItem)
		; Grabbing so we can convert to TS blueprints
		bIsActor = (kObjectRef as Actor)
		bIsAssignable = kObjectRef.HasKeyword(WorkshopWorkObject)
		bIsCreated = true ; TS treats these as items the player didn't build, even if they moved their position, making for awkward behavior so we're going to call these all created
		bIsFarmAnimal = ((kObjectRef as Actor) && (kObjectRef as Actor).IsInFaction(DomesticAnimalFaction))
		bIsFood = kObjectRef.GetValue(FoodAV) > 0
		bIsGenerator = kObjectRef.GetValue(PowerGeneratedAV) > 0
		bIsPowered = kObjectRef.HasKeyword(WorkshopCanBePowered)
		bIsTamedCreature = false
		bIsTurret = kObjectRef.HasKeyword(ActorTypeTurret)
		bIsWater = kObjectRef.GetValue(WaterAV) > 0
	endif
	
	Bool bForceStatic = false
	if(BaseForm as MovableStatic || BaseForm as Book || BaseForm as Holotape || BaseForm as Ammo || BaseForm as Weapon || BaseForm as Armor || BaseForm as Potion || BaseForm as MiscObject)
		if( ! BaseForm as MovableStatic)
			bIsLootable = true
		endif
		
		kObjectRef.ApplyHavokImpulse(1.0, 0.0, 0.0, 10.0)
		; TODO - Test this thoroughly - it might not be worth the trouble
		Utility.Wait(0.2)
		if(kObjectRef.X == fX)
			bForceStatic = true
		else
			; Return to previous position
			kObjectRef.SetPosition(fX, fY, fZ)
			kObjectRef.SetAngle(fAngleX, fAngleY, fAngleZ)
		endif
	endif
	
	ObjectReference kStackedParentRef = kObjectRef.GetLinkedRef(WorkshopStackedItemParentKEYWORD)
	
	; This will make it easier to potentially do manual edits of items - we can also use this to filter out a lot of the items from being included in the RestoreVanilla lists
	String sObjectName = F4SEManager.GetFormName(BaseForm)
	if(sObjectName == "")
		; Try and grab from ref instead
		sObjectName = F4SEManager.WSFWID_GetReferenceName(kObjectRef)
	endif
	
	Bool bIsResourceObject = false
	
	; NOTE: In addition to using the "Linked Object"/"Unlinked Object" field to identify those types, in the future we could also use it to differentiate between export styles and then configure our converter to change parsing based on this string. Ex. "Linked Object V2" could expect the fields in a different order, or with additional data
	
	String sMessageText = sLogDelimitter_Date
	if(bIsLinkedWorkshopItem)
		sMessageText += "Linked Object" + sLogDelimitter_LineType
		
		bIsResourceObject = kObjectRef.GetValue(WorkshopResourceObject) > 0
	else
		sMessageText += "Unlinked Object" + sLogDelimitter_LineType
	endif
	
	ExtraData = new Var[0]
	ExtraData = GetExtraModData(kObjectRef, sPluginName)
	
	; Send export notice - objects can define this vanilla event to be treated like a function and add data to the thread	
	if(kObjectRef as WorkshopFramework:Library:ObjectRefs:ExportExtraData)
		; Special script type specifically for this - this will ensure that if the object has multiple scripts attached, this one is handled
		(kObjectRef as WorkshopFramework:Library:ObjectRefs:ExportExtraData).OnTriggerLeave(Self)
	else
		kObjectRef.OnTriggerLeave(Self)
	endif
	
	sMessageText += BaseForm + sLogDelimitter_LineItem + sPluginName + sLogDelimitter_LineItem + fX + sLogDelimitter_LineItem + fY + sLogDelimitter_LineItem + fZ + sLogDelimitter_LineItem + fAngleX + sLogDelimitter_LineItem + fAngleY + sLogDelimitter_LineItem + fAngleZ + sLogDelimitter_LineItem + fScale + sLogDelimitter_LineItem + bForceStatic + sLogDelimitter_LineItem + bIsResourceObject + sLogDelimitter_LineItem + sObjectName + sLogDelimitter_LineItem + kObjectRef + sLogDelimitter_LineItem
	
	; Add flags
	if(bIsLootable)
		sMessageText += "1"
	else
		sMessageText += "0"
	endif	
	sMessageText += sLogDelimitter_Flags
	if(bIsActor)
		sMessageText += "1"
	else
		sMessageText += "0"
	endif
	sMessageText += sLogDelimitter_Flags
	if(bIsAssignable)
		sMessageText += "1"
	else
		sMessageText += "0"
	endif
	sMessageText += sLogDelimitter_Flags
	if(bIsCreated)
		sMessageText += "1"
	else
		sMessageText += "0"
	endif
	sMessageText += sLogDelimitter_Flags
	if(bIsFarmAnimal)
		sMessageText += "1"
	else
		sMessageText += "0"
	endif
	sMessageText += sLogDelimitter_Flags
	if(bIsFood)
		sMessageText += "1"
	else
		sMessageText += "0"
	endif
	sMessageText += sLogDelimitter_Flags
	if(bIsGenerator)
		sMessageText += "1"
	else
		sMessageText += "0"
	endif
	sMessageText += sLogDelimitter_Flags
	if(bIsPowered)
		sMessageText += "1"
	else
		sMessageText += "0"
	endif
	sMessageText += sLogDelimitter_Flags
	if(bIsTamedCreature)
		sMessageText += "1"
	else
		sMessageText += "0"
	endif
	sMessageText += sLogDelimitter_Flags
	if(bIsTurret)
		sMessageText += "1"
	else
		sMessageText += "0"
	endif
	sMessageText += sLogDelimitter_Flags
	if(bIsWater)
		sMessageText += "1"
	else
		sMessageText += "0"
	endif
	
	; Sort extra data so it always is passed in the same order: Forms, Numbers, Strings, Bools - and only as many as our current software design supports (1.2.0 supports 3 of each)
	sMessageText += sLogDelimitter_LineItem ; Separate flags from extra data
	int i = 0
	int iCurrentType = 0
	int iCurrentTypeCounter = 0
	bool bFirstExtra = true
	while(iCurrentType < 4)
		i = 0
		iCurrentTypeCounter = 0
		
		while(i < ExtraData.Length && iCurrentTypeCounter < 3)
			if(iCurrentType == 0)
				if(ExtraData[i] is Form)
					if(bFirstExtra)
						bFirstExtra = false
					else
						sMessageText += sLogDelimitter_ExtraData
					endif
					
					sMessageText += ExtraData[i] as Form + sLogDelimitter_Plugin + F4SEManager.GetPluginNameFromForm(ExtraData[i] as Form)
					
					iCurrentTypeCounter += 1
				endif
			elseif(iCurrentType == 1) ; numbers
				if(ExtraData[i] is Int)
					if(bFirstExtra)
						bFirstExtra = false
					else
						sMessageText += sLogDelimitter_ExtraData
					endif
					
					sMessageText += ExtraData[i] as Int
					iCurrentTypeCounter += 1
				elseif(ExtraData[i] is Float)
					if(bFirstExtra)
						bFirstExtra = false
					else
						sMessageText += sLogDelimitter_ExtraData
					endif
					
					sMessageText += ExtraData[i] as Float
					iCurrentTypeCounter += 1
				endif
			elseif(iCurrentType == 2)
				if(ExtraData[i] is String)
					if(bFirstExtra)
						bFirstExtra = false
					else
						sMessageText += sLogDelimitter_ExtraData
					endif
					
					sMessageText += ExtraData[i] as String
				endif
			elseif(iCurrentType == 3)
				if(ExtraData[i] is Bool)
					if(bFirstExtra)
						bFirstExtra = false
					else
						sMessageText += sLogDelimitter_ExtraData
					endif
					
					sMessageText += ExtraData[i] as Bool
				endif
			endif
			
			i += 1
		endWhile
		
		while(iCurrentTypeCounter < 3)
			; Add blank spaces
			if(bFirstExtra)
				bFirstExtra = false
			else
				sMessageText += sLogDelimitter_ExtraData
			endif
			
			iCurrentTypeCounter += 1
		endWhile
		
		iCurrentType += 1		
	endWhile
	
	
	ModTraceCustom(sLogName, sMessageText) ; Using kObjectRef as our reference point to connected objects instead of generating a BP index
	
	if(bIsLinkedWorkshopItem) ; Grab power info
		Bool bIsWire = (BaseForm.GetFormID() == 0x0001D971)
		if(bIsWire || kObjectRef.HasKeyword(WorkshopPowerConnection))
			ObjectReference[] kConnected = F4SEManager.GetConnectedObjects(kObjectRef)
			
			i = 0
			while(i < kConnected.Length)
				if(bIsWire)
					; This is a wire already output the connected objects directly
					ModTraceCustom(sLogName, sLogDelimitter_Date + "Power Connection" + sLogDelimitter_LineType + kObjectRef + sLogDelimitter_LineItem + kConnected[i])
				elseif(kConnected[i].GetBaseObject().GetFormID() == 0x0001D971) ; Wire - find attached to it
					ObjectReference[] kConnectedToWire = F4SEManager.GetConnectedObjects(kConnected[i])
					int j = 0
					while(j < kConnectedToWire.Length)
						if(kConnectedToWire[j] != kObjectRef)
							ModTraceCustom(sLogName, sLogDelimitter_Date + "Power Connection" + sLogDelimitter_LineType + kObjectRef + sLogDelimitter_LineItem + kConnectedToWire[j])
						endif
						
						j += 1
					endWhile
				endif
				
				i += 1
			endWhile
		endif
	endif
EndFunction


Var[] Function GetExtraModData(ObjectReference akObjectRef, String asPluginName)
	Var[] thisExtraData = new Var[0]
	
	; Append additional data needed for certain mods during export - such as Sim Settlements Plots
	if(asPluginName == "SimSettlements.esm")
		Keyword PlotKeyword = Game.GetFormFromFile(0x0001AB79, "SimSettlements.esm") as Keyword
		
		if(PlotKeyword && akObjectRef.HasKeyword(PlotKeyword))
			; Get extra data from plot
			ScriptObject asPlot = akObjectRef.CastAs("SimSettlements:SimPlot")
						
			; Building Plan
			Var BuildingPlan = asPlot.GetPropertyValue("CurrentLevelSubPlan")
			thisExtraData.Add(BuildingPlan)
			
			Var iLevel = asPlot.GetPropertyValue("CurrentLevel")
			thisExtraData.Add(iLevel)
			
			; Building Skin
			Var Skin = asPlot.GetPropertyValue("AppliedSkin")
			thisExtraData.Add(Skin)
			
			; VIP Story
			Var[] kArgs = new Var[0]
			Var Story = asPlot.CallFunction("GetCurrentStory", kArgs)
			thisExtraData.Add(Story)
		endif
	endif
	
	return thisExtraData
EndFunction


Bool Function ShouldExport()
	if(kObjectRef.IsDeleted() || (kObjectRef.IsDisabled() && ! kObjectRef.HasKeyword(IncludeIfDisabled)))
		return false
	endif
	
	if(kObjectRef.GetLinkedRef() != None && ! IsTrap(kObjectRef))
		return false
	endif
	
	Form BaseForm = kObjectRef.GetBaseObject()
	
	int i = 0
	while(i < SkipForms.Length)
		Form thisForm = GetUniversalForm(SkipForms[i])
		
		if(BaseForm == thisForm)
			return false
		elseif(thisForm as Keyword && kObjectRef.HasKeyword(thisForm as Keyword))
			return false
		endif
		
		i += 1
	endWhile	
	
	i = 0
	while(i < AdditionalSkipForms.Length)
		Form thisForm = AdditionalSkipForms[i]
		
		if(BaseForm == thisForm)
			return false
		elseif(thisForm as Keyword && kObjectRef.HasKeyword(thisForm as Keyword))
			return false
		endif
		
		i += 1
	endWhile
		
	if( ! bIsLinkedWorkshopItem)
		; Make sure this item is within the settlement location or build area
		if(kObjectRef.GetCurrentLocation() != kWorkshopRef.myLocation && ! kObjectRef.IsWithinBuildableArea(kWorkshopRef))
			return false
		endif
	endif
	
	
	if(kObjectRef as Actor)
		Bool bIsAnimal = (kObjectRef as Actor).IsInFaction(DomesticAnimalFaction)
		
		i = 0
		while(i < AlwaysAllowedActorTypes.Length)
			Form thisForm = GetUniversalForm(AlwaysAllowedActorTypes[i])
			Keyword asKeyword = thisForm as Keyword
			
			if(asKeyword)
				if(kObjectRef.HasKeyword(asKeyword))
					return true
				endif
			elseif(BaseForm == thisForm)
				return true
			endif
			
			i += 1
		endWhile
		
		if( ! bIsAnimal || Setting_Export_IncludeAnimals.GetValueInt() == 0)
			return false
		endif
	endif
	
	return true
EndFunction


Function AddSkipForm(Form aForm)
	if(AdditionalSkipForms == None || AdditionalSkipForms.Length == 0)
		AdditionalSkipForms = new Form[0]
	endif
	
	AdditionalSkipForms.Add(aForm)
EndFunction


Function AddExtraData(Var aExtraVar)
	if(ExtraData == None)
		ExtraData = new Var[0]
	endif
	
	ExtraData.Add(aExtraVar)
EndFunction