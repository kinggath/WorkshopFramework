; ---------------------------------------------
; WorkshopFramework:WorkshopProductionManager.psc - by kinggath
; ---------------------------------------------
; Reusage Rights ------------------------------
; You are free to use this script or portions of it in your own mods, provided you give me credit in your description and maintain this section of comments in any released source code (which includes the IMPORTED SCRIPT CREDIT section to give credit to anyone in the associated Import scripts below.
; 
; Warning !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
; Do not directly recompile this script for redistribution without first renaming it to avoid compatibility issues issues with the mod this came from.
; 
; IMPORTED SCRIPT CREDIT
; N/A
; ---------------------------------------------

Scriptname WorkshopFramework:WorkshopProductionManager extends WorkshopFramework:Library:SlaveQuest
{ Handles workshop daily production }


import WorkshopFramework:Library:DataStructures
import WorkshopFramework:Library:UtilityFunctions
import WorkshopFramework:WorkshopFunctions
import WorkshopDataScript ; 1.0.4 - Vanilla structs for Workshop stuff 


CustomEvent NotEnoughResources

;/TODO 	
- Create report holotape or note (ala AFT) for viewing all of the custom resources
- How can we support productivity boosts?
/;

; ---------------------------------------------
; Consts
; ---------------------------------------------

int ProductionLoopTimerID = 100 Const
float fThrottleContainerRouting = 0.04 Const

; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------

Group Controllers
	WorkshopFramework:MainThreadManager Property ThreadManager Auto Const Mandatory
	WorkshopParentScript Property WorkshopParent Auto Const Mandatory 
	Int Property iWorkshopParentInitializedStage = 20 Auto Const
	WorkshopFramework:WorkshopResourceManager Property ResourceManager Auto Const Mandatory
	
	GlobalVariable Property Setting_AllowLinkedWorkshopConsumption Auto Const Mandatory
	GlobalVariable Property Setting_MaintainDeficits Auto Const Mandatory
	GlobalVariable Property Setting_BasicConsumptionOnly Auto Const Mandatory
	{ 1.0.7 - New option so that settlers only consume purified water and vanilla crops, so they leave specialty food and water alone }
EndGroup


Group ActorValues
	ActorValue[] Property FoodTypes Auto Const Mandatory
	ActorValue Property Food Auto Const Mandatory
	ActorValue Property MissingFood Auto Const Mandatory
	ActorValue Property Water Auto Const Mandatory
	ActorValue Property MissingWater Auto Const Mandatory
	ActorValue Property Population Auto Const Mandatory
	ActorValue Property RobotPopulation Auto Const Mandatory
	ActorValue Property BrahminPopulation Auto Const Mandatory
	ActorValue Property Food_Carrot Auto Const Mandatory
	ActorValue Property Food_Corn Auto Const Mandatory
	ActorValue Property Food_Gourd Auto Const Mandatory
	ActorValue Property Food_Melon Auto Const Mandatory
	ActorValue Property Food_Mutfruit Auto Const Mandatory
	ActorValue Property Food_Razorgrain Auto Const Mandatory
	ActorValue Property Food_Tarberry Auto Const Mandatory
	ActorValue Property Food_Tato Auto Const Mandatory
	ActorValue Property Scavenge_BuildingMaterials Auto Const Mandatory
	ActorValue Property Scavenge_General Auto Const Mandatory
	ActorValue Property Scavenge_Parts Auto Const Mandatory
	ActorValue Property Scavenge_Rare Auto Const Mandatory
	ActorValue Property VendorIncome Auto Const Mandatory
	
	ActorValue Property FoodDamaged Auto Const Mandatory
	ActorValue Property WaterDamaged Auto Const Mandatory
	
	ActorValue Property WorkshopTargetContainerHolderValue Auto Const Mandatory
	{ AV we'll use to track the index of our WorkshopTargetContainerRecords on temporary containers }
	
	ActorValue Property ExtraNeeds_Food Auto Const Mandatory
	ActorValue Property ExtraNeeds_Safety Auto Const Mandatory
	ActorValue Property ExtraNeeds_Water Auto Const Mandatory
EndGroup

Group Aliases
	ReferenceAlias Property SafeSpawnPoint Auto Const Mandatory 
	{ Location to store production records }
	RefCollectionAlias Property ProductionList Auto Const Mandatory
	{ Alias to hold all registered ProduceResourceType objects }
	RefCollectionAlias Property ProducedList Auto Const Mandatory
	{ Alias to hold all registered ProductionRecord objects }
	RefCollectionAlias Property ConsumptionList Auto Const Mandatory
	{ Alias to hold all registered ConsumeResourceType objects }
	RefCollectionAlias Property MissingConsumptionList Auto Const Mandatory
	{ Alias to hold all ConsumeResourceTypes that still need production for the day }
	RefCollectionAlias Property WorkshopContainers Auto Const Mandatory
	{ Alias to hold all workshop containers so we can produce in them }
EndGroup


Group Assets
	Form Property BlankProductionRecord Auto Const Mandatory
	Form Property BlankProductionResourceRecord Auto Const Mandatory
	Form Property BlankConsumptionResourceRecord Auto Const Mandatory
	Form Property BlankMissingConsumptionForm Auto Const Mandatory
	
	LeveledItem Property DefaultScavProductionItem_All Auto Const Mandatory
	{ The default WorkshopProduceScavenge leveleditem from the vanilla game. This will be used until the individual AVs are detected as a means of ensuring WorkshopFramework leaves the game largely working the same. }
	LeveledItem Property DefaultFoodProductionItem Auto Const Mandatory
	LeveledItem Property DefaultFoodProductionItem_Carrot Auto Const Mandatory
	LeveledItem Property DefaultFoodProductionItem_Corn Auto Const Mandatory
	LeveledItem Property DefaultFoodProductionItem_Gourd Auto Const Mandatory
	LeveledItem Property DefaultFoodProductionItem_Melon Auto Const Mandatory
	LeveledItem Property DefaultFoodProductionItem_Mutfruit Auto Const Mandatory
	LeveledItem Property DefaultFoodProductionItem_Razorgrain Auto Const Mandatory	
	LeveledItem Property DefaultFoodProductionItem_Tarberry Auto Const Mandatory
	LeveledItem Property DefaultFoodProductionItem_Tato Auto Const Mandatory
	LeveledItem Property DefaultWaterProductionItem Auto Const Mandatory
	LeveledItem Property DefaultScavProductionItem_BuildingMaterials Auto Const Mandatory
	LeveledItem Property DefaultScavProductionItem_General Auto Const Mandatory
	LeveledItem Property DefaultScavProductionItem_Parts Auto Const Mandatory
	LeveledItem Property DefaultScavProductionItem_Rare Auto Const Mandatory
	LeveledItem Property DefaultFertilizerProductionItem Auto Const Mandatory
	Form Property Caps001 Auto Const Mandatory
	Form Property DummyContainerForm Auto Const Mandatory
	Form Property PurifiedWater Auto Const Mandatory
	{ 1.0.7 - Supporting option to only consume purified water }
EndGroup


Group Formlists
	FormList Property ScavengeList_All Auto Const Mandatory
	{ Used to determine how much scavenge the workshop has }
	FormList Property FertilizerList Auto Const Mandatory
	{ Making a formlist so mods can inject alternate types of fertilizer }
	FormList Property ScavengeList_BuildingMaterials Auto Const Mandatory
	{ Point to active list used by injection manager }
	FormList Property ScavengeList_General Auto Const Mandatory
	{ Point to active list used by injection manager }
	FormList Property ScavengeList_Parts Auto Const Mandatory
	{ Point to active list used by injection manager }
	FormList Property ScavengeList_Rare Auto Const Mandatory
	{ Point to active list used by injection manager }
	
	FormList Property VanillaBuildableCropList Auto Const Mandatory
	{ 1.0.7 - Supporting option to only consume basic crops }
EndGroup


Group Keywords
	Keyword Property AidContainerKeyword Auto Const Mandatory
		Keyword Property DrinkContainerKeyword Auto Const Mandatory
			Keyword Property WaterContainerKeyword Auto Const Mandatory
			Keyword Property AlcoholContainerKeyword Auto Const Mandatory
			Keyword Property NukaColaContainerKeyword Auto Const Mandatory
		Keyword Property FoodContainerKeyword Auto Const Mandatory
		Keyword Property ChemContainerKeyword Auto Const Mandatory
		
	Keyword Property JunkContainerKeyword Auto Const Mandatory
		Keyword Property ScrapContainerKeyword Auto Const Mandatory
			Keyword Property ScavengeBuildingMaterialsContainerKeyword Auto Const Mandatory
			Keyword Property ScavengeGeneralScrapContainerKeyword Auto Const Mandatory
			Keyword Property ScavengePartsContainerKeyword Auto Const Mandatory
			Keyword Property ScavengeRareContainerKeyword Auto Const Mandatory
		Keyword Property ComponentContainerKeyword Auto Const Mandatory
	
	Keyword Property EquipmentContainerKeyword Auto Const Mandatory
		Keyword Property ArmorContainerKeyword Auto Const Mandatory
		Keyword Property ModContainerKeyword Auto Const Mandatory
		Keyword Property WeaponContainerKeyword Auto Const Mandatory
			Keyword Property AmmoContainerKeyword Auto Const Mandatory
		
	Keyword Property MiscContainerKeyword Auto Const Mandatory
		Keyword Property NoteContainerKeyword Auto Const Mandatory
		Keyword Property HolotapeContainerKeyword Auto Const Mandatory
		Keyword Property FertilizerContainerKeyword Auto Const Mandatory
		Keyword Property CapsContainerKeyword Auto Const Mandatory
		
	Keyword Property ObjectTypeFood Auto Const Mandatory
	Keyword Property ObjectTypeWater Auto Const Mandatory
	Keyword Property ObjectTypeAlcohol Auto Const Mandatory
	Keyword Property ObjectTypeChem Auto Const Mandatory
	Keyword Property ObjectTypeDrink Auto Const Mandatory
	Keyword Property ObjectTypeNukaCola Auto Const Mandatory	
	
	Keyword Property WorkshopItemKeyword Auto Const Mandatory
	Keyword Property WorkshopCaravanKeyword Auto Const Mandatory
EndGroup

; ---------------------------------------------
; Properties
; ---------------------------------------------

LeveledItem Property FoodProductionItem Auto Hidden
LeveledItem Property FoodProductionItem_Carrot Auto Hidden
LeveledItem Property FoodProductionItem_Corn Auto Hidden
LeveledItem Property FoodProductionItem_Gourd Auto Hidden
LeveledItem Property FoodProductionItem_Melon Auto Hidden
LeveledItem Property FoodProductionItem_Mutfruit Auto Hidden
LeveledItem Property FoodProductionItem_Razorgrain Auto Hidden
LeveledItem Property FoodProductionItem_Tarberry Auto Hidden
LeveledItem Property FoodProductionItem_Tato Auto Hidden
LeveledItem Property WaterProductionItem Auto Hidden
LeveledItem Property ScavProductionItem_BuildingMaterials Auto Hidden
LeveledItem Property ScavProductionItem_General Auto Hidden
LeveledItem Property ScavProductionItem_Parts Auto Hidden
LeveledItem Property ScavProductionItem_Rare Auto Hidden
LeveledItem Property FertilizerProductionItem Auto Hidden


Float Property fProductionLoopTime = 24.0 Auto Hidden

; ---------------------------------------------
; Vars
; ---------------------------------------------

; Unlike a lock, with blocks we will just reject any incoming calls if a block is held
Bool bProductionUnderwayBlock 
Bool bUpdatingFoodTypesBlock  ; 1.0.4

ObjectReference[] RouteContainers ; Holds containers we'll monitor for OnItemAdded to re-distribute items to appropriate containers

Int iMaxProduceItemRecordIndex = 1023
Int iNextWorkshopTargetContainerRecordIndex = 0
Int Property NextWorkshopTargetContainerRecordIndex
	Int Function Get()
		iNextWorkshopTargetContainerRecordIndex += 1
		
		if(iNextWorkshopTargetContainerRecordIndex > iMaxProduceItemRecordIndex)
			iNextWorkshopTargetContainerRecordIndex = 1 ; 1.0.4 - Never use 0, since we're setting this index as an AV, we need to be able to treat 0 as the container not being part of this system
		endif
		
		return iNextWorkshopTargetContainerRecordIndex
	endFunction
EndProperty

WorkshopTargetContainer[] Property WorkshopTargetContainerRecords01 Auto Hidden
WorkshopTargetContainer[] Property WorkshopTargetContainerRecords02 Auto Hidden
WorkshopTargetContainer[] Property WorkshopTargetContainerRecords03 Auto Hidden
WorkshopTargetContainer[] Property WorkshopTargetContainerRecords04 Auto Hidden
WorkshopTargetContainer[] Property WorkshopTargetContainerRecords05 Auto Hidden
WorkshopTargetContainer[] Property WorkshopTargetContainerRecords06 Auto Hidden
WorkshopTargetContainer[] Property WorkshopTargetContainerRecords07 Auto Hidden
WorkshopTargetContainer[] Property WorkshopTargetContainerRecords08 Auto Hidden

; 1.0.4 - Tracking workshopFoodTypes from WorkshopParent so we can auto create compatibility with mods that alter it
WorkshopFoodType[] KnownWorkshopFoodTypes 

; ---------------------------------------------
; Events 
; ---------------------------------------------

Event OnTimerGameTime(Int aiTimerID)
	if(aiTimerID == ProductionLoopTimerID)
		ProduceAllWorkshopResources()
		
		StartProductionTimer()
	endif
EndEvent

Event WorkshopParentScript.WorkshopObjectBuilt(WorkshopParentScript akSenderRef, Var[] akArgs)
	WorkshopObjectScript BuiltObject = akArgs[0] as WorkshopObjectScript
	
	if(BuiltObject && BuiltObject.WorkshopContainerType)
		SetupWorkshopContainer(BuiltObject, akArgs[1] as WorkshopScript)
	endif
EndEvent

Event WorkshopParentScript.WorkshopObjectDestroyed(WorkshopParentScript akSenderRef, Var[] akArgs)
	WorkshopObjectScript BuiltObject = akArgs[0] as WorkshopObjectScript
	
	if(BuiltObject && BuiltObject.WorkshopContainerType)
		ClearWorkshopContainer(BuiltObject)
	endif
EndEvent

Event Quest.OnStageSet(Quest akSenderRef, Int aiStageID, Int aiItemID)
	if(akSenderRef == WorkshopParent)
		StartProductionTimer()
	
		UnregisterForRemoteEvent(akSenderRef, "OnStageSet")
	endif
EndEvent


Event ObjectReference.OnItemAdded(ObjectReference akAddedTo, Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
	int iRouteContainerIndex = RouteContainers.Find(akAddedTo) ; 1.0.4 - Renamed to iRouteContainerIndex for clarity
	
	if(iRouteContainerIndex < 0)
		ModTrace("[WSFW]  >>>>>>>>>>>>>> OnItemAdded Event: Target container " + akAddedTo + " is temporary, storing production in temporary holding record.")
		; Not a RouteContainer
		UnRegisterForRemoteEvent(akAddedTo, "OnItemAdded")
		
		WorkshopScript thisWorkshop = akAddedTo.GetLinkedRef(WorkshopItemKeyword) as WorkshopScript
		int iWorkshopID = thisWorkshop.GetWorkshopID()
		
		; Likely one of our temporary containers
		int iWorkshopTargetContainerIndex = akAddedTo.GetValue(WorkshopTargetContainerHolderValue) as Int
		
		ModTrace("[WSFW]  >>>>>>>>>>>>>> OnItemAdded Event: WorkshopTargetContainerIndex for temp container: " + iWorkshopTargetContainerIndex)
		if(iWorkshopTargetContainerIndex > 0)
			WorkshopTargetContainer WorkshopTargetData = GetWorkshopTargetContainerRecord(iWorkshopTargetContainerIndex)
			
			ObjectReference kSpawnPoint = SafeSpawnPoint.GetRef()
			
			WorkshopFramework:Library:ObjectRefs:ProductionRecord kRecord = kSpawnPoint.PlaceAtMe(BlankProductionRecord, abDeleteWhenAble = false) as WorkshopFramework:Library:ObjectRefs:ProductionRecord
			
			if(kRecord)
				; Store a record of the actual produced items and their ultimate destination
				kRecord.TemporaryContainer = akAddedTo
				kRecord.iWorkshopID = iWorkshopID
				kRecord.ContainerKeyword = WorkshopTargetData.TargetContainerKeyword
				
				ProducedList.AddRef(kRecord)
				
				ModTrace("[WSFW]  >>>>>>>>>>>>>> OnItemAdded Event: Added to ProducedList: " + kRecord + ", kRecord.TemporaryContainer: " + kRecord.TemporaryContainer)
			endif
		else
			; 1.0.4 - This should never happen - but seems to be occasionally for some players. Just going to log this for now so we can attempt to debug it in the future
			ModTrace("[WSFW] XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")
			ModTrace("[WSFW] XXXXXXXXXXXXXXXXXXX Lost Container Found: " + akAddedTo + ", this container reported " + iRouteContainerIndex + " when checking RouteContainers, and " + iWorkshopTargetContainerIndex + " when tested for temporary container holding value.")
			ModTrace("[WSFW] XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")
		endif
	else
		ModTrace("[WSFW]  >>>>>>>>>>>>>> OnItemAdded Event: Target container is a routing container. Redirecting items to final destination.")
		
		WorkshopScript thisWorkshop = ResourceManager.Workshops[iRouteContainerIndex]
		ObjectReference kContainer = None
		
		if(thisWorkshop)
			; 1.0.8 - Changing the auto-classification to a function we can use externally
			kContainer = GetContainerForItem(thisWorkshop, akBaseItem)
			
			ModTrace("[WSFW]  >>>>>>>>>>>>>> OnItemAdded Event: Final destination: " + kContainer)
			if(kContainer)
				akAddedTo.RemoveAllItems(kContainer)
			endif
		endif
	endif
EndEvent

; ---------------------------------------------
; Extended Handlers
; ---------------------------------------------

Function HandleQuestInit()
	Parent.HandleQuestInit()
	
	; Register for events
	RegisterForCustomEvent(WorkshopParent, "WorkshopObjectBuilt")
	RegisterForCustomEvent(WorkshopParent, "WorkshopObjectDestroyed")
	AddInventoryEventFilter(None)
	
	; Init arrays
	RouteContainers = new ObjectReference[0]
	WorkshopTargetContainerRecords01 = new WorkshopTargetContainer[128]
	WorkshopTargetContainerRecords02 = new WorkshopTargetContainer[128]
	WorkshopTargetContainerRecords03 = new WorkshopTargetContainer[128]
	WorkshopTargetContainerRecords04 = new WorkshopTargetContainer[128]
	WorkshopTargetContainerRecords05 = new WorkshopTargetContainer[128]
	WorkshopTargetContainerRecords06 = new WorkshopTargetContainer[128]
	WorkshopTargetContainerRecords07 = new WorkshopTargetContainer[128]
	WorkshopTargetContainerRecords08 = new WorkshopTargetContainer[128]
	
	; Setup defaults
	FoodProductionItem = DefaultFoodProductionItem
	FoodProductionItem_Carrot = DefaultFoodProductionItem_Carrot
	FoodProductionItem_Corn = DefaultFoodProductionItem_Corn
	FoodProductionItem_Gourd = DefaultFoodProductionItem_Gourd
	FoodProductionItem_Melon = DefaultFoodProductionItem_Melon
	FoodProductionItem_Mutfruit = DefaultFoodProductionItem_Mutfruit
	FoodProductionItem_Razorgrain = DefaultFoodProductionItem_Razorgrain
	FoodProductionItem_Tarberry = DefaultFoodProductionItem_Tarberry
	FoodProductionItem_Tato = DefaultFoodProductionItem_Tato
	WaterProductionItem = DefaultWaterProductionItem
	ScavProductionItem_BuildingMaterials = DefaultScavProductionItem_BuildingMaterials
	ScavProductionItem_General = DefaultScavProductionItem_General
	ScavProductionItem_Parts = DefaultScavProductionItem_Parts
	ScavProductionItem_Rare = DefaultScavProductionItem_Rare
	FertilizerProductionItem = DefaultFertilizerProductionItem
	
	; Start Production Loop
	if(WorkshopParent.GetStageDone(iWorkshopParentInitializedStage))
		StartProductionTimer()
	else
		RegisterForRemoteEvent(WorkshopParent, "OnStageSet")
	endif
EndFunction


Function HandleGameLoaded()
	Parent.HandleGameLoaded()
	
	; Check for changes to WorkshopParent.WorkshopFoodTypes
	UpdateFoodTypesData()
EndFunction

; ---------------------------------------------
; Overrides
; ---------------------------------------------


; ---------------------------------------------
; Functions
; ---------------------------------------------

; 1.0.8 - Making single line function for grabbing the container based on the base item 
ObjectReference Function GetContainerForItem(WorkshopScript akWorkshopRef, Form akBaseItem)
	return GetContainer(akWorkshopRef, GetContainerKeyword(akBaseItem))
EndFunction

; 1.0.8 - Switched this code to a function so we can call it externally
Keyword Function GetContainerKeyword(Form akBaseItem)
	; Try and auto-classify
	if(akBaseItem as Potion)
		if(akBaseItem.HasKeyword(ObjectTypeAlcohol))
			return AlcoholContainerKeyword
		elseif(akBaseItem.HasKeyword(ObjectTypeNukaCola))
			return NukaColaContainerKeyword
		elseif(akBaseItem.HasKeyword(ObjectTypeWater))
			return WaterContainerKeyword
		elseif(akBaseItem.HasKeyword(ObjectTypeDrink))
			return DrinkContainerKeyword
		elseif(akBaseItem.HasKeyword(ObjectTypeFood))
			return FoodContainerKeyword
		elseif(akBaseItem.HasKeyword(ObjectTypeChem))
			return ChemContainerKeyword
		else
			return AidContainerKeyword
		endif
	elseif(akBaseItem as Component)
		return ComponentContainerKeyword
	elseif(akBaseItem == Caps001)
		return CapsContainerKeyword
	elseif(akBaseItem as Holotape)
		return HolotapeContainerKeyword
	elseif(akBaseItem as Book)
		return NoteContainerKeyword
	elseif(FertilizerList.Find(akBaseItem) >= 0)
		return FertilizerContainerKeyword
	elseif(akBaseItem as Ammo)
		return AmmoContainerKeyword
	elseif(akBaseItem as Armor)
		return ArmorContainerKeyword
	elseif(akBaseItem as ObjectMod)
		return ModContainerKeyword
	elseif(akBaseItem as Weapon)
		return WeaponContainerKeyword
	elseif(akBaseItem as MiscObject)
		if(ScavengeList_BuildingMaterials.Find(akBaseItem) >= 0)
			return ScavengeBuildingMaterialsContainerKeyword
		elseif(ScavengeList_General.Find(akBaseItem) >= 0)
			return ScavengeGeneralScrapContainerKeyword
		elseif(ScavengeList_Parts.Find(akBaseItem) >= 0)
			return ScavengePartsContainerKeyword
		elseif(ScavengeList_Rare.Find(akBaseItem) >= 0)
			return ScavengeRareContainerKeyword
		else
			return MiscContainerKeyword
		endif
	endif
	
	return None
EndFunction

; 1.0.4 - Integrating mods that have changed the WorkshopFoodTypes array on WorkshopParent
Function UpdateFoodTypesData()
	;/
	;struct WorkshopFoodType
	;	ActorValue resourceValue
	;	{ what resource value matches this food type }
	;
	;	LeveledItem foodObject
	;	{ leveled item to use to create this food type }
	;endStruct
	/;
	if(bUpdatingFoodTypesBlock)
		return
	endif
	
	bUpdatingFoodTypesBlock = true
	
	int i = 0
	
	if( ! KnownWorkshopFoodTypes || KnownWorkshopFoodTypes.Length == 0)
		KnownWorkshopFoodTypes = new WorkshopFoodType[0]
	else
		; Clean out our KnownWorkshopFoodTypes in case a mod was uninstalled
		i = 0
		int[] RemoveIndexes = new Int[0]
		
		while(i < KnownWorkshopFoodTypes.Length)
			if(KnownWorkshopFoodTypes[i].foodObject.GetFormID() == 0x00000000 || KnownWorkshopFoodTypes[i].resourceValue.GetFormID() == 0x00000000)
				RemoveIndexes.Add(i)
			endif
			
			i += 1
		endWhile
		
		i = RemoveIndexes.Length ; Go through this in reverse so we don't screw up the index order 
		while(i > 0)
			ModTrace("[WSFW] Abandoned mod left empty entry in KnownWorkshopFoodTypes, clearing out index " + i)
			KnownWorkshopFoodTypes.Remove(RemoveIndexes[i])
		
			i -= 1
		endWhile
	endif
	
	
	; Now compare our known to those in the Workshopparent array
	WorkshopFoodType[] MissingFoodTypes = new WorkshopFoodType[0]
	WorkshopFoodType[] WPFoodTypes = WorkshopParent.WorkshopFoodTypes
	i = 0
	while(i < WPFoodTypes.Length)
		int j = 0
		WorkshopFoodType thisFoodType = WPFoodTypes[i]
		
		if(thisFoodType.resourceValue == Food_Carrot || \
		   thisFoodType.resourceValue == Food_Corn || \
		   thisFoodType.resourceValue == Food_Gourd || \
		   thisFoodType.resourceValue == Food_Melon || \
		   thisFoodType.resourceValue == Food_Mutfruit || \
		   thisFoodType.resourceValue == Food_Razorgrain || \
		   thisFoodType.resourceValue == Food_Tarberry || \
		   thisFoodType.resourceValue == Food_Tato)
		   ; Vanilla type - ignore
		else
			Bool bFoundMatch = false
			while(j < KnownWorkshopFoodTypes.Length && ! bFoundMatch)
				if(thisFoodType.resourceValue == KnownWorkshopFoodTypes[j].resourceValue)
					bFoundMatch = true
					
					if(KnownWorkshopFoodTypes[j].foodObject != thisFoodType.foodObject)
						; Production type changed
						UnregisterProductionResource(KnownWorkshopFoodTypes[j].foodObject, KnownWorkshopFoodTypes[j].resourceValue)
						
						; Update type in our Known records
						KnownWorkshopFoodTypes[j].foodObject = thisFoodType.foodObject
						
						; Register new type
						RegisterProductionResource(KnownWorkshopFoodTypes[j].foodObject, KnownWorkshopFoodTypes[j].resourceValue)
					endif
				endif
			
				j += 1
			endWhile
			
			if( ! bFoundMatch)
				; New type
				MissingFoodTypes.Add(thisFoodType)
			endif
		endif
		
		i += 1
	endWhile
	
	i = 0
	while(i < MissingFoodTypes.Length && KnownWorkshopFoodTypes.Length < 128)
		ModTrace("[WSFW] Registering new food type from WorkshopParent: " + MissingFoodTypes[i])
		; Store in array
		KnownWorkshopFoodTypes.Add(MissingFoodTypes[i])
		
		; Do actual production registration
		RegisterProductionResource(MissingFoodTypes[i].foodObject, MissingFoodTypes[i].resourceValue)
		
		i += 1
	endWhile
	
	bUpdatingFoodTypesBlock = false
EndFunction


Function CleanResourceLists()
	; Clean ProductionList
	int i = 0
	ObjectReference[] RemoveMe = new ObjectReference[0]
	while(i < ProductionList.GetCount())
		WorkshopFramework:Library:ObjectRefs:ResourceTypeProduction kRecord = ProductionList.GetAt(i) as WorkshopFramework:Library:ObjectRefs:ResourceTypeProduction
		
		; 1.0.4 - Removed mods will not return None from their forms, but GetFormID will return 0x00000000
		if(kRecord.ProduceForm.GetFormID() == 0x00000000 || kRecord.ResourceAV.GetFormID() == 0x00000000)
			RemoveMe.Add(kRecord)
		endif
		
		i += 1
	endWhile
	
	i = 0
	while(i < RemoveMe.Length)
		ProductionList.RemoveRef(RemoveMe[i])
		RemoveMe[i].Disable()
		RemoveMe[i].Delete()
		
		i += 1
	endWhile
	
	i = 0
	RemoveMe = new ObjectReference[0]
	
	; Clean ConsumptionList
	while(i < ConsumptionList.GetCount())
		WorkshopFramework:Library:ObjectRefs:ResourceTypeConsumption kRecord = ConsumptionList.GetAt(i) as WorkshopFramework:Library:ObjectRefs:ResourceTypeConsumption
		
		; 1.0.4 - Removed mods will not return None from their forms, but GetFormID will return 0x00000000
		if(kRecord.ConsumeForm.GetFormID() == 0x00000000 || kRecord.ResourceAV.GetFormID() == 0x00000000)
			RemoveMe.Add(kRecord)
		endif
		
		i += 1
	endWhile
	
	i = 0
	while(i < RemoveMe.Length)
		ConsumptionList.RemoveRef(RemoveMe[i])
		RemoveMe[i].Disable()
		RemoveMe[i].Delete()
		
		i += 1
	endWhile
	
	
	i = 0
	RemoveMe = new ObjectReference[0]
	
	; Clean MissingConsumptionList
	while(i < MissingConsumptionList.GetCount())
		WorkshopFramework:Library:ObjectRefs:ResourceTypeConsumptionMissing kRecord = ConsumptionList.GetAt(i) as WorkshopFramework:Library:ObjectRefs:ResourceTypeConsumptionMissing
		
		; The referenced consumption record will already have been cleared previously
		if(ConsumptionList.Find(kRecord.ResourceTypeConsumptionRecord) < 0)
			kRecord.ResourceTypeConsumptionRecord = None ; Clear ref so it can be cleaned up
			RemoveMe.Add(kRecord)
		endif
		
		i += 1
	endWhile
	
	i = 0
	while(i < RemoveMe.Length)
		MissingConsumptionList.RemoveRef(RemoveMe[i])
		RemoveMe[i].Disable()
		RemoveMe[i].Delete()
		
		i += 1
	endWhile
EndFunction


Int Function IsProductionResourceRegistered(LeveledItem aProduceMe, ActorValue aResourceAV)
	int i = 0
	int iCount = ProductionList.GetCount()
	while(i < iCount)
		WorkshopFramework:Library:ObjectRefs:ResourceTypeProduction kRecord = ProductionList.GetAt(i) as WorkshopFramework:Library:ObjectRefs:ResourceTypeProduction
		
		if(kRecord.ProduceForm == aProduceMe && kRecord.ResourceAV == aResourceAV)
			return i
		endif
		
		i += 1
	endWhile
	
	return -1
EndFunction


Int Function IsConsumptionResourceRegistered(Form aConsumeMe, ActorValue aResourceAV)
	int i = 0
	int iCount = ConsumptionList.GetCount()
	while(i < iCount)
		WorkshopFramework:Library:ObjectRefs:ResourceTypeConsumption kRecord = ConsumptionList.GetAt(i) as WorkshopFramework:Library:ObjectRefs:ResourceTypeConsumption
		
		if(kRecord.ConsumeForm == aConsumeMe && kRecord.ResourceAV == aResourceAV)
			return i
		endif
		
		i += 1
	endWhile
	
	return -1
EndFunction


Function RegisterProductionResource(LeveledItem aProduceMe, ActorValue aResourceAV, Keyword aTargetContainerKeyword = None)
	; Confirm this isn't already registered
	if(IsProductionResourceRegistered(aProduceMe, aResourceAV) >= 0)
		ModTrace("[WSFW] >>>>>>>> Resource already registered: " + aResourceAV + " " + aProduceMe)
		return
	endif
	
	ObjectReference kSpawnPoint = SafeSpawnPoint.GetRef()
	
	if(kSpawnPoint)
		WorkshopFramework:Library:ObjectRefs:ResourceTypeProduction kRecord = kSpawnPoint.PlaceAtMe(BlankProductionResourceRecord, abDeleteWhenAble = false) as WorkshopFramework:Library:ObjectRefs:ResourceTypeProduction
		
		if(kRecord)
			kRecord.ProduceForm = aProduceMe
			kRecord.ResourceAV = aResourceAV
			kRecord.TargetContainerKeyword = aTargetContainerKeyword
			
			ModTrace("[WSFW] >>>>>>>> Created Production record : " + kRecord)
			ProductionList.AddRef(kRecord)
			
			ResourceManager.WorkshopTrackedAVs.AddForm(kRecord.ResourceAV)
		endif
	endif
EndFunction


Function UnregisterProductionResource(LeveledItem aProduceMe, ActorValue aResourceAV)
	; Confirm this is already registered
	int iIndex = IsProductionResourceRegistered(aProduceMe, aResourceAV)
	if(iIndex < 0)
		return
	endif
	
	ProductionList.RemoveRef(ProductionList.GetAt(iIndex))
	ResourceManager.WorkshopTrackedAVs.RemoveAddedForm(aResourceAV)
EndFunction



Function RegisterConsumptionResource(Form aConsumeMe, ActorValue aResourceAV, Keyword aSearchContainerKeyword = None, Bool abIsComponentFormList = false)
	; Confirm this isn't already registered
	if(IsConsumptionResourceRegistered(aConsumeMe, aResourceAV) >= 0)
		return
	endif
	
	ObjectReference kSpawnPoint = SafeSpawnPoint.GetRef()
	
	if(kSpawnPoint)
		WorkshopFramework:Library:ObjectRefs:ResourceTypeConsumption kRecord = kSpawnPoint.PlaceAtMe(BlankConsumptionResourceRecord, abDeleteWhenAble = false) as WorkshopFramework:Library:ObjectRefs:ResourceTypeConsumption
		
		kRecord.ConsumeForm = aConsumeMe
		kRecord.ResourceAV = aResourceAV
		kRecord.SearchContainerKeyword = aSearchContainerKeyword
		kRecord.bIsComponentFormList = abIsComponentFormList
		
		ConsumptionList.AddRef(kRecord)
		
		ResourceManager.WorkshopTrackedAVs.AddForm(kRecord.ResourceAV)
	endif
EndFunction



Function UnregisterConsumptionResource(Form aConsumeMe, ActorValue aResourceAV)
	; Confirm this is already registered
	int iIndex = IsConsumptionResourceRegistered(aConsumeMe, aResourceAV)
	if(iIndex < 0)
		return
	endif
	
	ConsumptionList.RemoveRef(ConsumptionList.GetAt(iIndex))
	ResourceManager.WorkshopTrackedAVs.RemoveAddedForm(aResourceAV)
EndFunction


Function StartProductionTimer()
	WorkshopScript[] kWorkshops = ResourceManager.Workshops
	
	; 1.0.4 - Ensure this gets initialized. 
	if( ! RouteContainers || RouteContainers.length == 0)
		RouteContainers = new ObjectReference[0]
	endif
	
	int i = 0
	while(i < kWorkshops.Length)
		; 1.0.4 - There was a bug for some users where the RouteContainers weren't being detected correctly in the OnItemAdded event, and were being counted as temporary containers, which caused them to be deleted. This change will ensure the containers are correctly recreated on the next production run
		if(RouteContainers.Length == i || RouteContainers[i] == None)
			ObjectReference kRouteContainer = SafeSpawnPoint.GetRef().PlaceAtMe(DummyContainerForm, abForcePersist = true, abDeleteWhenAble = false)
		
			if(kRouteContainer)
				RouteContainers.Add(kRouteContainer)
				RegisterForRemoteEvent(kRouteContainer, "OnItemAdded")
			endif
		endif
		
		i += 1
	endWhile
	
	StartTimerGameTime(fProductionLoopTime, ProductionLoopTimerID)
EndFunction


Function ProduceAllWorkshopResources()
	if(bProductionUnderwayBlock)
		return
	endif
	
	bProductionUnderwayBlock = true
	
	Float fStartTime = Utility.GetCurrentRealtime()
	
	; Clear out any resource that was part of a mod that is no longer installed
	CleanResourceLists()
	
	int i = 0
	WorkshopScript[] WorkshopsArray = ResourceManager.Workshops
	
	ModTrace("[WSFW] ==============================================")
	ModTrace("[WSFW] ==============================================")
	ModTrace("[WSFW] ==============================================")
	ModTrace("[WSFW]              Starting Production")
	ModTrace("[WSFW] ==============================================")
	ModTrace("[WSFW] ==============================================")
	ModTrace("[WSFW] ==============================================")
	while(i < WorkshopsArray.Length)
		WorkshopScript kWorkshopRef = WorkshopsArray[i]
		
		; Start by consuming from existing resources in the appropriate containers - this gives players the most control over what should be consumed
		ConsumeWorkshopResources(kWorkshopRef)
		
		; Produce the day's resources but place them in a holding state since the production is based on leveledItems, versus Consumption which is based on base items
		ProduceWorkshopResources(kWorkshopRef)
		
		i += 1
	endWhile
	
	; Give the OnItemAdded events time to complete
	Utility.Wait(10.0)
	
	; Finally, finish consumption of resources and then send the surplus to the appropriate containers
	ProcessSurplusResources()
	
	ModTrace("[WSFW] Resource production for " + WorkshopsArray.Length + " workshops took " + (Utility.GetCurrentRealtime() - fStartTime) + " seconds.")
	
	bProductionUnderwayBlock = false
EndFunction


Function ConsumeWorkshopResources(WorkshopScript akWorkshopRef)
	if( ! akWorkshopRef)
		return
	endif
	
	ModTrace("[WSFW] =============================================")
	ModTrace("[WSFW] =============================================")
	ModTrace("[WSFW]        ConsumeWorkshopResources: " + akWorkshopRef)
	ModTrace("[WSFW] ==============================================")
	; Start with the defaults of Food and Water
	Float fLivingPopulation = ResourceManager.GetWorkshopValue(akWorkshopRef, Population) - ResourceManager.GetWorkshopValue(akWorkshopRef, RobotPopulation)
	
	int iRequiredFood = fLivingPopulation as Int
	int iRequiredWater = fLivingPopulation as Int
	
	; Test if negative food/water production is being applied to simulate excessive requirements. This will ensure backwards compatibility with older Sim Settlements add-ons
	Int iCurrentFoodProductionValue = Math.Ceiling(ResourceManager.GetWorkshopValue(akWorkshopRef, Food))
	Int iCurrentWaterProductionValue = Math.Ceiling(ResourceManager.GetWorkshopValue(akWorkshopRef, Water))
	
	; Check for excess need
	if(iCurrentFoodProductionValue < 0)
		iRequiredFood += Math.Abs(iCurrentFoodProductionValue) as Int
	endif
	
	iRequiredFood += akWorkshopRef.GetValue(ExtraNeeds_Food) as Int
	
	if(iCurrentWaterProductionValue < 0)
		iRequiredWater += Math.Abs(iCurrentWaterProductionValue) as Int
	endif
	
	iRequiredWater += akWorkshopRef.GetValue(ExtraNeeds_Water) as Int
	
	ModTrace("[WSFW]            Food Needs: " + iRequiredFood)
	ModTrace("[WSFW]            Water Needs: " + iRequiredWater)
		; Handle actual consumption
	if(iRequiredFood > 0)
		; 1.0.7 - Adding option to change consumption to only use easily produced crops
		if(Setting_BasicConsumptionOnly.GetValue() == 1.0)
			iRequiredFood -= ConsumeFromWorkshopV2(VanillaBuildableCropList, iRequiredFood, akWorkshopRef, FoodContainerKeyword)
		else
			; 1.0.4a - Changed from = to -=
			iRequiredFood -= ConsumeFromWorkshopV2(ObjectTypeFood, iRequiredFood, akWorkshopRef, FoodContainerKeyword)
		endif
	endif
	
	if(iRequiredWater > 0)
		; 1.0.7 - Adding option to change consumption to only use easily produced PurifiedWater
		if(Setting_BasicConsumptionOnly.GetValue() == 1.0)
			iRequiredWater -= ConsumeFromWorkshopV2(PurifiedWater, iRequiredWater, akWorkshopRef, WaterContainerKeyword)
		else
			; 1.0.4a - Changed from = to -=
			iRequiredWater -= ConsumeFromWorkshopV2(ObjectTypeWater, iRequiredWater, akWorkshopRef, WaterContainerKeyword)
		endif
	endif
	
	
	ModTrace("[WSFW]            Missing Food: " + iRequiredFood)
	ModTrace("[WSFW]            Missing Water: " + iRequiredWater)
	; Missing AVs are used by radiant quests - we can also use them in the WorkshopScript daily update loop
	akWorkshopRef.SetValue(MissingFood, iRequiredFood)
	akWorkshopRef.SetValue(MissingWater, iRequiredWater)
	
	; Next handle custom registered consumption
	int i = 0
	while(i < ConsumptionList.GetCount())
		WorkshopFramework:Library:ObjectRefs:ResourceTypeConsumption thisConsumeType = ConsumptionList.GetAt(i) as WorkshopFramework:Library:ObjectRefs:ResourceTypeConsumption
		
		int iRequired = akWorkshopRef.GetValue(thisConsumeType.ResourceAV) as Int
		
		if(iRequired > 0)
			iRequired -= ConsumeFromWorkshopV2(thisConsumeType.ConsumeForm, iRequired, akWorkshopRef, thisConsumeType.SearchContainerKeyword, thisConsumeType.bIsComponentFormList)
			
			if(iRequired > 0) ; Still some missing
				; During production - we'll only check those that we know have a missing resource
				ObjectReference kSpawnPoint = SafeSpawnPoint.GetRef()
				
				if(kSpawnPoint)
					WorkshopFramework:Library:ObjectRefs:ResourceTypeConsumptionMissing kMissingConsumptionRef = kSpawnPoint.PlaceAtMe(BlankMissingConsumptionForm, abDeleteWhenAble = false) as WorkshopFramework:Library:ObjectRefs:ResourceTypeConsumptionMissing
					
					if(kMissingConsumptionRef)
						kMissingConsumptionRef.ResourceTypeConsumptionRecord = thisConsumeType
						kMissingConsumptionRef.kWorkshopRef = akWorkshopRef
						kMissingConsumptionRef.iMissing = iRequired
												
						MissingConsumptionList.AddRef(kMissingConsumptionRef)
					endif
				endif
			endif
		endif
		
		i += 1
	endWhile
EndFunction


; 1.0.8 - Calling V2 for backwards compatibility
Int Function ConsumeFromWorkshop(Form aConsumeMe, Int aiCount, WorkshopScript akWorkshopRef, Keyword aTargetContainerKeyword = None, Bool abIsComponentFormList = false, Bool abLinkedWorkshopConsumption = false)
	ConsumeFromWorkshopV2(aConsumeMe, aiCount, akWorkshopRef, aTargetContainerKeyword, abIsComponentFormList, abLinkedWorkshopConsumption, abCheckOnly = false)
EndFunction


; 1.0.8 - Adding ability to test if there is enough from this settlement without actually consuming
Int Function ConsumeFromWorkshopV2(Form aConsumeMe, Int aiCount, WorkshopScript akWorkshopRef, Keyword aTargetContainerKeyword = None, Bool abIsComponentFormList = false, Bool abLinkedWorkshopConsumption = false, Bool abCheckOnly = false)
	if( ! akWorkshopRef || aiCount <= 0 || ! aConsumeMe)
		return 0
	endif
	
	int iRemainingToConsume = aiCount
	
	; Check keyword specific containers
	ObjectReference[] kContainers
	Int iContainerItemCount = 0
	if(aTargetContainerKeyword)
		kContainers = GetAllContainers(akWorkshopRef, aTargetContainerKeyword)
		
		if(kContainers.Length > 0)
			int i = 0
			while(i < kContainers.Length && iRemainingToConsume > 0)
				iRemainingToConsume -= ConsumeResourceV2(kContainers[i], aConsumeMe, iRemainingToConsume, abIsComponentFormList, abCheckOnly)
				
				i += 1
			endWhile
		endif
	endif
	
	; Check workshop container
	if(iRemainingToConsume > 0)
		ObjectReference workshopContainer = akWorkshopRef.GetContainer()
		
		if(kContainers.Find(workshopContainer) < 0)
			iRemainingToConsume -= ConsumeResourceV2(workshopContainer, aConsumeMe, iRemainingToConsume, abIsComponentFormList, abCheckOnly)
		endif
		
		if(iRemainingToConsume > 0 && ! abLinkedWorkshopConsumption)
			; Check linked workshops and consume from them 
			
			; TODO - This is super inefficient and impractical (was in the vanilla game method as well). Although much harder to solve now that we've introduced custom consumption, so we can't even easily just flag a settlement as having nothing to ensure it is skipped in the next round of checks.
			if(Setting_AllowLinkedWorkshopConsumption.GetValue() == 1)
				int i = 0
				Location[] LinkedLocations = akWorkshopRef.myLocation.GetAllLinkedLocations(WorkshopCaravanKeyword)
				
				while(i < LinkedLocations.Length && iRemainingToConsume > 0)
					int iLinkedWorkshopID = ResourceManager.WorkshopLocations.Find(LinkedLocations[i])
					
					if(iLinkedWorkshopID >= 0)
						WorkshopScript thisWorkshop = ResourceManager.Workshops[iLinkedWorkshopID]
						
						if(thisWorkshop.bAllowLinkedConsumption)
							iRemainingToConsume -= ConsumeFromWorkshopV2(aConsumeMe, iRemainingToConsume, thisWorkshop, aTargetContainerKeyword, abIsComponentFormList, true, abCheckOnly) ; Send true to second to last arg to prevent an infinite loop
						endif
					endif
					
					i += 1
				endWhile
			endif
		endif
	endif
	
	; return amount consumed
	return aiCount - iRemainingToConsume
EndFunction


Function ProcessSurplusResources()
	ModTrace("[WSFW] =============================================")
	ModTrace("[WSFW] =============================================")
	ModTrace("[WSFW]        ProcessSurplusResources")
	ModTrace("[WSFW] ==============================================")
	ModTrace("[WSFW] ==============================================")
	
	int i = 0
	int iWorkshopCount = ResourceManager.Workshops.Length
	while(i < iWorkshopCount)
		WorkshopScript thisWorkshop = ResourceManager.Workshops[i]	
		int iWorkshopID = i
		
		; Process food and water and update our AVs
		int iFoodMissing = thisWorkshop.GetValue(MissingFood) as Int
		int iWaterMissing = thisWorkshop.GetValue(MissingWater) as Int
		
		ObjectReference[] RemoveMe = new ObjectReference[0]
		
		int j = 0
		while(j < ProducedList.GetCount())
			WorkshopFramework:Library:ObjectRefs:ProductionRecord kRecord = ProducedList.GetAt(j) as WorkshopFramework:Library:ObjectRefs:ProductionRecord
			
			if(kRecord.iWorkshopID == iWorkshopID)
				; Can we fix any issues with food or water
				if(iFoodMissing > 0)
					; 1.0.7 - New option to only consume easy to acquire crops
					if(Setting_BasicConsumptionOnly.GetValue() == 1.0)
						iFoodMissing = ConsumeResourceV2(kRecord.TemporaryContainer, VanillaBuildableCropList, iFoodMissing)
					else
						iFoodMissing = ConsumeResourceV2(kRecord.TemporaryContainer, ObjectTypeFood, iFoodMissing)
					endif
				endif
				
				if(iWaterMissing > 0)
					; 1.0.7 - New option to only consume purified water
					if(Setting_BasicConsumptionOnly.GetValue() == 1.0)
						iWaterMissing = ConsumeResourceV2(kRecord.TemporaryContainer, PurifiedWater, iWaterMissing)
					else
						iWaterMissing = ConsumeResourceV2(kRecord.TemporaryContainer, ObjectTypeWater, iWaterMissing)
					endif
				endif
				
				; Check if any of our missing consumption records are searching for produced items
				UpdateMissingConsumptionList(kRecord.TemporaryContainer)
				
				; Anything remaining in the container should be sent to the appropriate place	
				ObjectReference kContainer

				if(kRecord.ContainerKeyword)
					; Production record specified a specific destination
					kContainer = GetContainer(thisWorkshop, kRecord.ContainerKeyword)	

					ModTrace("[WSFW]             Moving all surplus items from " + kRecord.TemporaryContainer + " to specific container: " + kContainer)				
				else
					; Send to route container so we can determine where things should go based on type
					kContainer = RouteContainers[kRecord.iWorkshopID]
					
					ModTrace("[WSFW]             Moving all surplus items from " + kRecord.TemporaryContainer + " to routing container: " + kContainer)
					; Prevent OnItemAdded spam
					Utility.Wait(fThrottleContainerRouting)
				endif
				
				if(kContainer)
					kRecord.TemporaryContainer.RemoveAllItems(kContainer)
				endif
								
				; Destroy temporary container - we'll clear it from the alias at the end of the function
				kRecord.TemporaryContainer.SetLinkedRef(None, WorkshopItemKeyword)
				kRecord.TemporaryContainer.Disable()
				kRecord.TemporaryContainer.Delete()
				
				; 1.0.9 We no longer need this record, destroy it
				kRecord.Disable(false)
				kRecord.Delete()
			endif
			
			j += 1
		endWhile
		
		; Update missing food and water
		thisWorkshop.SetValue(MissingFood, iFoodMissing)
		thisWorkshop.SetValue(MissingWater, iWaterMissing)
		
		i += 1
	endWhile
		
	
	; Send out events for any remaining Missing Consumption List items so mods who are watching for it can produce side effects - since the base game only applies happiness hits based on things like food and water
	i = 0
	while(i < MissingConsumptionList.GetCount())
		WorkshopFramework:Library:ObjectRefs:ResourceTypeConsumptionMissing thisMissingRecord = MissingConsumptionList.GetAt(i) as WorkshopFramework:Library:ObjectRefs:ResourceTypeConsumptionMissing
				
		Var[] kArgs = new Var[4]
		kArgs[0] = thisMissingRecord.kWorkshopRef
		kArgs[1] = thisMissingRecord.ResourceTypeConsumptionRecord.ResourceAV
		kArgs[2] = thisMissingRecord.ResourceTypeConsumptionRecord.ConsumeForm
		kArgs[3] = thisMissingRecord.iMissing
		
		SendCustomEvent("NotEnoughResources", kArgs)
		
		; 1.0.9 - Destroy records once we're done with them
		if(Setting_MaintainDeficits.GetValue() == 0.0)
			thisMissingRecord.Disable(false)
			thisMissingRecord.Delete()
		endif
		
		i += 1
	endWhile
	
	; If deficits are disabled, clear missing consumption list for the day unless Deficits are turned on
	if(Setting_MaintainDeficits.GetValue() == 0.0)
		MissingConsumptionList.RemoveAll()
	endif
	
	; Clear the produced list for the day
	ProducedList.RemoveAll()
EndFunction


Function UpdateMissingConsumptionList(ObjectReference akContainerRef)
	int i = 0
	
	WorkshopFramework:Library:ObjectRefs:ResourceTypeConsumptionMissing[] RemoveMe = new WorkshopFramework:Library:ObjectRefs:ResourceTypeConsumptionMissing[0]
	
	while(i < MissingConsumptionList.GetCount())
		WorkshopFramework:Library:ObjectRefs:ResourceTypeConsumptionMissing thisMissingRecord = MissingConsumptionList.GetAt(i) as WorkshopFramework:Library:ObjectRefs:ResourceTypeConsumptionMissing
		
		int iConsumedCount = ConsumeResourceV2(akContainerRef, thisMissingRecord.ResourceTypeConsumptionRecord.ConsumeForm, thisMissingRecord.iMissing, thisMissingRecord.ResourceTypeConsumptionRecord.bIsComponentFormList)
		
		if(iConsumedCount > 0)
			if(thisMissingRecord.iMissing == iConsumedCount)
				RemoveMe.Add(thisMissingRecord)
			else
				thisMissingRecord.iMissing -= iConsumedCount
			endif
		endif
		
		i += 1
	endWhile
	
	
	i = 0
	while(i < RemoveMe.Length)
		MissingConsumptionList.RemoveRef(RemoveMe[i])
		
		i += 1
	endWhile
EndFunction


; 1.0.8 - Calling V2 for backwards compatibility
Int Function ConsumeResource(ObjectReference akContainerRef, Form aConsumeMe, Int aiCount, Bool abComponentFormList = false)
	ConsumeResourceV2(akContainerRef, aConsumeMe, aiCount, abComponentFormList, abCheckOnly = false)
EndFunction


; 1.0.8 - Adding ability to test only without actually consuming
Int Function ConsumeResourceV2(ObjectReference akContainerRef, Form aConsumeMe, Int aiCount, Bool abComponentFormList = false, Bool abCheckOnly = false)
	Int iContainerItemCount
	Bool bComponents = false
	if(abComponentFormList || aConsumeMe as Component)
		bComponents = true
		iContainerItemCount = akContainerRef.GetComponentCount(aConsumeMe)
	else
		iContainerItemCount = akContainerRef.GetItemCount(aConsumeMe)
	endif
	
	Int iConsumedCount = 0
	if(iContainerItemCount > 0)
		if(iContainerItemCount >= aiCount)
			iConsumedCount = aiCount
		else
			iConsumedCount = iContainerItemCount
		endif
		
		if( ! abCheckOnly)
			if(bComponents)
				akContainerRef.RemoveItemByComponent(aConsumeMe, iConsumedCount)
			else
				akContainerRef.RemoveItem(aConsumeMe, iConsumedCount)
			endif
		endif
	endif
	
	return iConsumedCount
EndFunction


Function ProduceWorkshopResources(WorkshopScript akWorkshopRef)
	if( ! akWorkshopRef)
		return
	endif
	
	int iWorkshopID = akWorkshopRef.GetWorkshopID()
	
	if(iWorkshopID < 0)
		return
	endif

	ModTrace("[WSFW] =============================================")
	ModTrace("[WSFW] =============================================")
	ModTrace("[WSFW]        ProduceWorkshopResources: " + akWorkshopRef)
	ModTrace("[WSFW] ==============================================")	
	
	; First produce general resources based on ratings (food/water/scavenge/caps/fertilizer)
	int iMaxProduceFoodRemaining = ProduceFood(akWorkshopRef)
	int iMaxProduceWaterRemaining = ProduceWater(akWorkshopRef)
	int iMaxProduceScavengeRemaining = ProduceScavenge(akWorkshopRef)
		
	ProduceFertilizer(akWorkshopRef)
	ProduceVendorIncome(akWorkshopRef)		
	
	ModTrace("[WSFW] ==============================================")	
	ModTrace("[WSFW]                  Produce Mod Added Resources: " + akWorkshopRef)
	ModTrace("[WSFW] ==============================================")	
	
	; Next produce specialty resources
	int i = 0
	int iMax = ProductionList.GetCount()
	
	ModTrace("[WSFW]                      Found " + iMax + " New Resource Types")
	while(i < iMax)
		WorkshopFramework:Library:ObjectRefs:ResourceTypeProduction kRecord = ProductionList.GetAt(i) as WorkshopFramework:Library:ObjectRefs:ResourceTypeProduction
		
		if(kRecord.ProduceForm)
			int iProduceCount = akWorkshopRef.GetValue(kRecord.ResourceAV) as Int
			
			if(kRecord.TargetContainerKeyword == WaterContainerKeyword)
				if(iMaxProduceWaterRemaining > 0)
					if(iMaxProduceWaterRemaining > iProduceCount)
						iMaxProduceWaterRemaining -= iProduceCount
					else
						iProduceCount = iMaxProduceWaterRemaining
						iMaxProduceWaterRemaining = 0
					endif
				endif
			elseif(kRecord.TargetContainerKeyword == FoodContainerKeyword)
				if(iMaxProduceFoodRemaining > 0)
					if(iMaxProduceFoodRemaining > iProduceCount)
						iMaxProduceFoodRemaining -= iProduceCount
					else
						iProduceCount = iMaxProduceFoodRemaining
						iMaxProduceFoodRemaining = 0
					endif
				endif
			elseif(kRecord.TargetContainerKeyword == ScrapContainerKeyword || GetParentContainerKeyword(kRecord.TargetContainerKeyword) == ScrapContainerKeyword)	
				if(iMaxProduceScavengeRemaining > 0)
					if(iMaxProduceScavengeRemaining > iProduceCount)
						iMaxProduceScavengeRemaining -= iProduceCount
					else
						iProduceCount = iMaxProduceScavengeRemaining
						iMaxProduceScavengeRemaining = 0
					endif
				endif
			else
				; TODO: Expand the storage system for more gameplay options - things like limitations on non-scavenge items so players can build more storage. Ex. MaxProduceWeapons or MaxProduceAmmo
			endif
			
			if(iProduceCount > 0)
				ModTrace("[WSFW]                 Producing " + iProduceCount + " " + kRecord.ProduceForm)
				ProduceItems(kRecord.ProduceForm, akWorkshopRef, iProduceCount, kRecord.TargetContainerKeyword)
			endif
		endif
		
		i += 1
	endWhile
EndFunction


; Returns max that can still be produced so specialty resources can respect storage limits without needing to check again
int Function ProduceFood(WorkshopScript akWorkshopRef)
	if( ! akWorkshopRef)
		return -1
	endif
	
	int iWorkshopID = akWorkshopRef.GetWorkshopID()
	
	if(iWorkshopID < 0)
		return -1
	endif
	
	ModTrace("[WSFW] ==============================================")	
	ModTrace("[WSFW]                  ProduceFood: " + akWorkshopRef)
	ModTrace("[WSFW] ==============================================")	
	
	Int iCurrentFoodProductionValue = Math.Ceiling(ResourceManager.GetWorkshopValue(akWorkshopRef, Food))
	Float fLivingPopulation = akWorkshopRef.GetBaseValue(Population) - akWorkshopRef.GetBaseValue(RobotPopulation)
	Float fPopulationBrahmin = akWorkshopRef.GetValue(BrahminPopulation)
	
	; Increase production via fertilizer (in the form of Brahmin poo)
	if(fPopulationBrahmin > 0)
		int iBrahminMaxFoodBoost = Math.min(fPopulationBrahmin * akWorkshopRef.maxProductionPerBrahmin, iCurrentFoodProductionValue) as int
		iCurrentFoodProductionValue += Math.Ceiling(iBrahminMaxFoodBoost * akWorkshopRef.brahminProductionBoost)
	endif
	
	; Reduce by damage
	int iFoodDamage = akWorkshopRef.GetValue(FoodDamaged) as Int
	iCurrentFoodProductionValue = Math.max(0, iCurrentFoodProductionValue - iFoodDamage) as int
	
	ModTrace("[WSFW]                  Damaged Food Resources: " + iFoodDamage)
	ModTrace("[WSFW]                  Food Production Value: " + iCurrentFoodProductionValue)
		
	if(iCurrentFoodProductionValue > 0)
		; Test to make sure we aren't at max surplus food
		int iMaxStoredFood = akWorkshopRef.maxStoredFoodBase + Math.Ceiling(akWorkshopRef.maxStoredFoodPerPopulation * fLivingPopulation) + (fLivingPopulation as Int) ; Since we've fully separated consumption from production, we need to allow for the next day's consumption in the max storage so we add living population here
		
		ObjectReference FoodContainer = GetContainer(akWorkshopRef, FoodContainerKeyword)
		
		int iCurrentStoredFood = FoodContainer.GetItemCount(ObjectTypeFood)
		int iMaxProduceFood = iMaxStoredFood - iCurrentStoredFood
		int iProduceFood = iCurrentFoodProductionValue
		
		if(iMaxProduceFood < 0)
			iMaxProduceFood = 0
		endif
		
		if(iMaxProduceFood < iProduceFood)
			iProduceFood = iMaxProduceFood
		endif
		
		ModTrace("[WSFW]                  Current Stored Food: " + iCurrentStoredFood)
		ModTrace("[WSFW]                  Max Stored Food: " + iMaxStoredFood)
		
		if(iProduceFood > 0)
			ModTrace("[WSFW]				  Producing: " + iProduceFood)
			
			ProduceFoodTypes(akWorkshopRef, iProduceFood)
			
			if(iProduceFood < iMaxProduceFood)
				return iMaxProduceFood - iProduceFood
			endif
		endif
	endif
	
	return 0	
EndFunction


; Returns max that can still be produced so specialty resources can respect storage limits without needing to check again
int Function ProduceWater(WorkshopScript akWorkshopRef)
	if( ! akWorkshopRef)
		return -1
	endif
	
	int iWorkshopID = akWorkshopRef.GetWorkshopID()
	
	if(iWorkshopID < 0)
		return -1
	endif
	
	ModTrace("[WSFW] ==============================================")	
	ModTrace("[WSFW]                  ProduceWater: " + akWorkshopRef)
	ModTrace("[WSFW] ==============================================")	
	
	Int iCurrentWaterProductionValue = Math.Ceiling(ResourceManager.GetWorkshopValue(akWorkshopRef, Water))
	Float fLivingPopulation = akWorkshopRef.GetBaseValue(Population) - akWorkshopRef.GetBaseValue(RobotPopulation)
	
	; Reduce by damage
	Int iWaterDamage = akWorkshopRef.GetValue(WaterDamaged) as int
	iCurrentWaterProductionValue = Math.max(0, iCurrentWaterProductionValue - iWaterDamage) as int
	
	ModTrace("[WSFW]                  Damaged Water Resources: " + iWaterDamage)
	ModTrace("[WSFW]                  Water Production Value: " + iCurrentWaterProductionValue)
	
	if(iCurrentWaterProductionValue > 0)
		; Test to make sure we aren't at max surplus water
		int iMaxStoredWater = akWorkshopRef.maxStoredWaterBase + Math.Ceiling(akWorkshopRef.maxStoredWaterPerPopulation * fLivingPopulation) + (fLivingPopulation as Int) ; Since we've fully separated consumption from production, we need to allow for the next day's consumption in the max storage so we add living population here
		
		ObjectReference WaterContainer = GetContainer(akWorkshopRef, WaterContainerKeyword)
		
		int iCurrentStoredWater = WaterContainer.GetItemCount(ObjectTypeWater)
		int iMaxProduceWater = iMaxStoredWater - iCurrentStoredWater
		int iProduceWater = iCurrentWaterProductionValue
		
		if(iMaxProduceWater < 0)
			iMaxProduceWater = 0
		endif
		
		if(iMaxProduceWater < iProduceWater)
			iProduceWater = iMaxProduceWater
		endif
		
		ModTrace("[WSFW]                  Current Stored Water: " + iCurrentStoredWater)
		ModTrace("[WSFW]                  Max Stored Water: " + iMaxStoredWater)
		
		
		if(iProduceWater > 0)
			ModTrace("[WSFW]                  Producing: " + iProduceWater)
			
			ProduceItems(WaterProductionItem, akWorkshopRef, iProduceWater, WaterContainerKeyword)
			
			if(iProduceWater < iMaxProduceWater)
				return iMaxProduceWater - iProduceWater
			endif
		endif
	endif
	
	return 0	
EndFunction


; Returns max that can still be produced so specialty resources can respect storage limits without needing to check again
int Function ProduceScavenge(WorkshopScript akWorkshopRef)
	if( ! akWorkshopRef)
		return -1
	endif
	
	int iWorkshopID = akWorkshopRef.GetWorkshopID()
	
	if(iWorkshopID < 0)
		return -1
	endif
	
	ModTrace("[WSFW] ==============================================")	
	ModTrace("[WSFW]                  ProduceScavenge: " + akWorkshopRef)
	ModTrace("[WSFW] ==============================================")
	
	ObjectReference ScavengeContainer = GetContainer(akWorkshopRef, ScrapContainerKeyword)
	ObjectReference BuildingMaterialsContainer = GetContainer(akWorkshopRef, ScavengeBuildingMaterialsContainerKeyword)
	ObjectReference GeneralContainer = GetContainer(akWorkshopRef, ScavengeGeneralScrapContainerKeyword)
	ObjectReference PartsContainer = GetContainer(akWorkshopRef, ScavengePartsContainerKeyword)
	ObjectReference RareContainer = GetContainer(akWorkshopRef, ScavengeRareContainerKeyword)
	
	int iCurrentStoredScavenge = ScavengeContainer.GetItemCount(ScavengeList_All)
	ModTrace("[WSFW]                  Current Stored Scav: " + iCurrentStoredScavenge)
	Float fLivingPopulation = akWorkshopRef.GetBaseValue(Population) - akWorkshopRef.GetBaseValue(RobotPopulation)
	
	if(BuildingMaterialsContainer != ScavengeContainer)
		iCurrentStoredScavenge += BuildingMaterialsContainer.GetItemCount(ScavengeList_All)
	endif
	
	if(GeneralContainer != ScavengeContainer)
		iCurrentStoredScavenge += GeneralContainer.GetItemCount(ScavengeList_All)
	endif
	
	if(PartsContainer != ScavengeContainer)
		iCurrentStoredScavenge += PartsContainer.GetItemCount(ScavengeList_All)
	endif
	
	if(RareContainer != ScavengeContainer)
		iCurrentStoredScavenge += RareContainer.GetItemCount(ScavengeList_All)
	endif
	
	int iMaxStoredScavenge = (akWorkshopRef.maxStoredScavengeBase + akWorkshopRef.maxStoredScavengePerPopulation * fLivingPopulation) as Int
	
	if(iMaxStoredScavenge < 0)
		iMaxStoredScavenge = 0
	endif
	
	Float fScavengeBuildingMaterialsProduction = ResourceManager.GetWorkshopValue(akWorkshopRef, Scavenge_BuildingMaterials)
	Float fScavengeGeneralProduction = ResourceManager.GetWorkshopValue(akWorkshopRef, Scavenge_General)
	Float fScavengePartsProduction = ResourceManager.GetWorkshopValue(akWorkshopRef, Scavenge_Parts)
	Float fScavengeRareProduction = ResourceManager.GetWorkshopValue(akWorkshopRef, Scavenge_Rare)
	
	ModTrace("[WSFW]                  Scav Production Value: " + fScavengeGeneralProduction)
	ModTrace("[WSFW]                  Current Stored Scav (After adding subcontainers): " + iCurrentStoredScavenge)
	ModTrace("[WSFW]                  Max Stored Scav: " + iMaxStoredScavenge)
	int iMaxProduce = iMaxStoredScavenge - iCurrentStoredScavenge
	
	if(iMaxProduce < 0)
		iMaxProduce = 0
	endif
	
	if(iMaxProduce > 0)
		if(fScavengeBuildingMaterialsProduction <= 0 && fScavengePartsProduction <= 0 && fScavengeRareProduction <=0)
			int iProduce = fScavengeGeneralProduction as Int
			if(iMaxProduce < iProduce)
				iProduce = iMaxProduce
			endif
			
			ModTrace("[WSFW]                  Producing: " + iProduce)
				
			; Player has no mods taking advantage of the new AVs, just use the default scavenge system
			if(iProduce > 0)
				ProduceItems(DefaultScavProductionItem_All, akWorkshopRef, iProduce, ScavengeGeneralScrapContainerKeyword)
				
				iMaxProduce -= Math.Floor(iProduce)
			endif
		else	
			Float fTotalProduction = fScavengeBuildingMaterialsProduction + fScavengeGeneralProduction + fScavengePartsProduction + fScavengeRareProduction
			
			ModTrace("[WSFW]                  Producing: " + fTotalProduction)
			
			if(fTotalProduction > iMaxProduce)
				; Determine percentages of each type to produce up to max
				fScavengeBuildingMaterialsProduction = Math.Min(fScavengeBuildingMaterialsProduction, iMaxProduce * (fScavengeBuildingMaterialsProduction/fTotalProduction))
				fScavengeGeneralProduction = Math.Min(fScavengeGeneralProduction, iMaxProduce * (fScavengeGeneralProduction/fTotalProduction))
				fScavengePartsProduction = Math.Min(fScavengePartsProduction, iMaxProduce * (fScavengePartsProduction/fTotalProduction))
				fScavengeRareProduction = Math.Min(fScavengeRareProduction, iMaxProduce * (fScavengeRareProduction/fTotalProduction))
			endif
			
			if(fScavengeBuildingMaterialsProduction > 0)
				ProduceItems(ScavProductionItem_BuildingMaterials, akWorkshopRef, Math.Floor(fScavengeBuildingMaterialsProduction), ScavengeBuildingMaterialsContainerKeyword)
				
				iMaxProduce -= Math.Floor(fScavengeBuildingMaterialsProduction)
			endif
			
			if(fScavengeGeneralProduction > 0)
				ProduceItems(ScavProductionItem_General, akWorkshopRef, Math.Floor(fScavengeGeneralProduction), ScavengeGeneralScrapContainerKeyword)
				
				iMaxProduce -= Math.Floor(fScavengeGeneralProduction)
			endif
			
			if(fScavengePartsProduction > 0)
				ProduceItems(ScavProductionItem_Parts, akWorkshopRef, Math.Floor(fScavengePartsProduction), ScavengePartsContainerKeyword)
				
				iMaxProduce -= Math.Floor(fScavengePartsProduction)
			endif
			
			if(fScavengeRareProduction > 0)
				ProduceItems(ScavProductionItem_Rare, akWorkshopRef, Math.Floor(fScavengeRareProduction), ScavengeRareContainerKeyword)
				
				iMaxProduce -= Math.Floor(fScavengeRareProduction)
			endif
		endif
	endif
	
	return iMaxProduce
EndFunction


int Function ProduceFertilizer(WorkshopScript akWorkshopRef)
	if( ! akWorkshopRef)
		return -1
	endif
	
	int iWorkshopID = akWorkshopRef.GetWorkshopID()
	
	if(iWorkshopID < 0)
		return -1
	endif
	
	ModTrace("[WSFW] ==============================================")	
	ModTrace("[WSFW]                  ProduceFertilizer: " + akWorkshopRef)
	ModTrace("[WSFW] ==============================================")
	
	ObjectReference FertilizerContainer = GetContainer(akWorkshopRef, FertilizerContainerKeyword)
	
	int iProduce = akWorkshopRef.GetBaseValue(BrahminPopulation) as int
	int iCurrentStoredFertilizer = FertilizerContainer.GetItemCount(FertilizerList)
	; Test against max and produce
	int iMaxStoredFertilizer = akWorkshopRef.maxBrahminFertilizerProduction
	int iMaxProduce = iMaxStoredFertilizer - iCurrentStoredFertilizer
	
	if(iMaxProduce < 0)
		iMaxProduce = 0
	endif
	
	if(iMaxProduce < iProduce)
		iProduce = iMaxProduce
	endif
	
	ModTrace("[WSFW]                  Fertilizer Production Value: " + iProduce)
	ModTrace("[WSFW]                  Current Stored Fertilizer: " + iCurrentStoredFertilizer)
	ModTrace("[WSFW]                  Max Stored Fertilizer: " + iMaxStoredFertilizer)
	
	if(iProduce > 0)		
		ModTrace("[WSFW]                  Producing: " + iProduce)
		
		ProduceItems(FertilizerProductionItem, akWorkshopRef, iProduce, FertilizerContainerKeyword)
		
		return iMaxProduce - iProduce
	endif
	
	return 0
EndFunction


Function ProduceVendorIncome(WorkshopScript akWorkshopRef)
	if( ! akWorkshopRef)
		return
	endif
	
	int iWorkshopID = akWorkshopRef.GetWorkshopID()
	
	if(iWorkshopID < 0)
		return
	endif
	
	ModTrace("[WSFW] ==============================================")	
	ModTrace("[WSFW]                  ProduceVendorIncome: " + akWorkshopRef)
	ModTrace("[WSFW] ==============================================")
	
	Float fBaseIncome = ResourceManager.GetWorkshopValue(akWorkshopRef, VendorIncome) * akWorkshopRef.vendorIncomeBaseMult
	
	Int iVendorIncomeFinal = 0

	; get linked population with productivity excluded
	float fTotalPopulation = akWorkshopRef.GetBaseValue(Population)
	float fLinkedPopulation = ResourceManager.GetLinkedPopulation(akWorkshopRef, false)
	float fVendorPopulation = fLinkedPopulation + fTotalPopulation
	float fLocalProductivity = ResourceManager.GetProductivityMultiplier(akWorkshopRef)
	; only get income if population >= minimum
	if(fVendorPopulation >= akWorkshopRef.minVendorIncomePopulation)
		; get productivity-adjusted linked population
		fLinkedPopulation = ResourceManager.GetLinkedPopulation(akWorkshopRef, true)

		; our population also gets productivity factor
		fVendorPopulation = fTotalPopulation * fLocalProductivity + fLinkedPopulation
		
		float fIncomeBonus = fBaseIncome * akWorkshopRef.vendorIncomePopulationMult * fVendorPopulation
		
		; vendor income is multiplied by productivity (happiness)
		iVendorIncomeFinal = Math.Ceiling(fBaseIncome + fIncomeBonus)
		; don't go above max allowed
		iVendorIncomeFinal = Math.Min(iVendorIncomeFinal, akWorkshopRef.maxVendorIncome) as int
		
		ModTrace("[WSFW]                  VendorIncome Value: " + iVendorIncomeFinal)
		if(iVendorIncomeFinal >= 1)
			ProduceItems(Caps001, akWorkshopRef, iVendorIncomeFinal, CapsContainerKeyword)
		endif	
	else
		ModTrace("[WSFW]                  Population Too Low to Produce Vendor Income")
	endif
EndFunction


Function ProduceFoodTypes(WorkshopScript akWorkshopRef, Int aiCount = 1)
	if( ! akWorkshopRef)
		return
	endif
	
	int iWorkshopID = akWorkshopRef.GetWorkshopID()
	
	if(iWorkshopID < 0)
		return
	endif
	
	ModTrace("[WSFW] ==============================================")	
	ModTrace("[WSFW]                  ProduceFoodTypes: " + akWorkshopRef + ", Count: " + aiCount)
	ModTrace("[WSFW] ==============================================")
	
	; Calculate food specialties
	int iFoodTypeCount = FoodTypes.Length
	Float[] fFoodTypeChance = new Float[iFoodTypeCount]

	;of all food types with a production chance value > 0 will be stored in this array:
	int[] iFoodTypeIndex_CurrentWorkshop = New int[0]
	Float fTotalFoodResources = ResourceManager.GetWorkshopValue(akWorkshopRef, Food)
	Float fChanceTotal = 0
	
	int i = 0
	while(i < iFoodTypeCount)
		ActorValue foodType = FoodTypes[i]
		fFoodTypeChance[i] = ResourceManager.GetWorkshopValue(akWorkshopRef, foodType) / fTotalFoodResources
		
		fChanceTotal += fFoodTypeChance[i]
		
		if(fFoodTypeChance[i] > 0)
			iFoodTypeIndex_CurrentWorkshop.Add(i)
		endif
		
		i += 1
	endWhile
	
	;Calculate cumulated chance values (so we don't have to do it in every loop cycle, as tha vanilla code does):
	;After this procedure, the foodTypeChance at array position i will hold the sum of the chance values for the food types 0 to i.
	i = 1
	while(i < iFoodTypeCount)
		fFoodTypeChance[i] = fFoodTypeChance[i] + fFoodTypeChance[i - 1]
		
		i += 1
	endWhile
	
	int iFoodTypeCount_CurrentWorkshop = iFoodTypeIndex_CurrentWorkshop.Length
	
	ModTrace("[WSFW]                  Food Type Array iFoodTypeIndex_CurrentWorkshop: " + iFoodTypeIndex_CurrentWorkshop)
	if(iFoodTypeCount_CurrentWorkshop > 0)
		if(iFoodTypeCount_CurrentWorkshop == 1)
			ProduceItems(GetFoodItem(iFoodTypeIndex_CurrentWorkshop[0]), akWorkshopRef, aiCount, FoodContainerKeyword)
		else
			int iFoodProduced = 0
			while(iFoodProduced < aiCount)
				float fRandomRoll = Utility.RandomFloat(0.0, fChanceTotal)
				
				int iFoodTypeIndex = -1
				i = 0
				while(i < iFoodTypeCount && iFoodTypeIndex < 0)
					if(fRandomRoll <= fFoodTypeChance[i])
						iFoodTypeIndex = i
					endif
					
					i += 1
				endWhile
				
				ProduceItems(GetFoodItem(iFoodTypeIndex), akWorkshopRef, 1, FoodContainerKeyword)

				iFoodProduced += 1
			endWhile			
		endif
	endif
EndFunction


LeveledItem Function GetFoodItem(Int aiFoodTypeIndex)
	if(aiFoodTypeIndex == 0)
		return FoodProductionItem_Carrot
	elseif(aiFoodTypeIndex == 1)
		return FoodProductionItem_Corn
	elseif(aiFoodTypeIndex == 2)
		return FoodProductionItem_Gourd
	elseif(aiFoodTypeIndex == 3)
		return FoodProductionItem_Melon
	elseif(aiFoodTypeIndex == 4)
		return FoodProductionItem_Mutfruit
	elseif(aiFoodTypeIndex == 5)
		return FoodProductionItem_Razorgrain
	elseif(aiFoodTypeIndex == 6)
		return FoodProductionItem_Tarberry
	elseif(aiFoodTypeIndex == 7)
		return FoodProductionItem_Tato
	else
		return FoodProductionItem
	endif
EndFunction


Function ProduceItems(Form aProduceMe, WorkshopScript akWorkshopRef, Int aiCount = 1, Keyword aTargetContainerKeyword = None)
	if( ! aProduceMe || ! akWorkshopRef || aiCount < 1)
		return
	endif
	
	int iWorkshopID = akWorkshopRef.GetWorkshopID()
	
	ModTrace("[WSFW] ==============================================")	
	ModTrace("[WSFW]                       ProduceItems: " + aProduceMe + " at " + akWorkshopRef + ", Count: " + aiCount)
	ModTrace("[WSFW] ==============================================")
	
	; We need to first create the items in a temporary container so we resolve things like LeveledItems which can represent a large quantity of various items. In order to track where these are supposed to end up ultimately, we'll create our tracking record and store a ref to the destination container, we'll then tag our temporary container with an AV that matches the index of our tracking record.
		; Set up a tracking record so we can pair the destination container keyword and workshop ID with the final created items
	int iWorkshopTargetContainerIndex = PrepareWorkshopTargetContainerRecord_Lock(iWorkshopID, aTargetContainerKeyword)
	
	if(iWorkshopTargetContainerIndex < 1) ; Couldn't prep a record - just drop it in the container directly
	; 1.0.4 - Changed check to < 1, we don't want to use index 0 as it makes it impossible to check for the index as an AV without a potential false positive
		; This should never happen as we're just looping through the indexes, but just to be thorough....
		ObjectReference kContainer = GetContainer(akWorkshopRef, aTargetContainerKeyword)
					
		if(kContainer)
			ModTrace("[WSFW] !!!!! Failed to get WorkshopTargetContainerIndex - creating resources directly in container.")
			kContainer.AddItem(aProduceMe, aiCount)
		endif
	else
		; Setup our temp container and tag it with the WorkshopTargetContainerRecord index
		ObjectReference kTempContainer = SafeSpawnPoint.GetRef().PlaceAtMe(DummyContainerForm, abDeleteWhenAble = false)
		kTempContainer.SetValue(WorkshopTargetContainerHolderValue, iWorkshopTargetContainerIndex)
		kTempContainer.SetLinkedRef(akWorkshopRef, WorkshopItemKeyword)
		
		; After the item is created in the temporary container, we'll check the AV, and record the final actual items that are being produced. The consumption cycle will then consume things from the temporary containers and the Workshop Workbench, when it finishes, it will create the remaining surplus items in the corresponding containers and clear all of the temporary containers/records.
			; Monitor for the OnItemAdded event and add the additem
		RegisterForRemoteEvent(kTempContainer, "OnItemAdded")
		
		ModTrace("[WSFW]                       Creating " + aiCount + " items in temp container: " + kTempContainer + " with holding container index: " + iWorkshopTargetContainerIndex)
		kTempContainer.AddItem(aProduceMe, aiCount)
	endif		
	
	; Give a brief pause so we don't overwhelm ourselves with OnItemAdded events
	Utility.Wait(fThrottleContainerRouting)
EndFunction


Int Function PrepareWorkshopTargetContainerRecord_Lock(Int aiWorkshopID, Keyword aTargetContainerKeyword)
	Int iLockKey = GetLock()
	if(iLockKey <= GENERICLOCK_KEY_NONE)
		ModTrace("Unable to get lock!", 2)
		
		return -1
	endif	
	
	; Lock acquired do work
	int iWorkshopTargetContainerRecordIndex = NextWorkshopTargetContainerRecordIndex 
	
	WorkshopTargetContainer NewWorkshopTargetContainer = new WorkshopTargetContainer
	NewWorkshopTargetContainer.TargetContainerKeyword = aTargetContainerKeyword
	NewWorkshopTargetContainer.iWorkshopID = aiWorkshopID
	
	UpdateWorkshopTargetContainerRecord(iWorkshopTargetContainerRecordIndex, NewWorkshopTargetContainer)
	
	; Release Edit Lock
	if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
		ModTrace("Failed to release lock " + iLockKey + "!", 2)
	endif
	
	return iWorkshopTargetContainerRecordIndex
EndFunction


WorkshopTargetContainer Function GetWorkshopTargetContainerRecord(Int aiIndex)
	if(aiIndex < 128)
		return WorkshopTargetContainerRecords01[aiIndex]
	elseif(aiIndex < 256)
		return WorkshopTargetContainerRecords02[aiIndex - 128]
	elseif(aiIndex < 384)
		return WorkshopTargetContainerRecords03[aiIndex - 256]
	elseif(aiIndex < 512)
		return WorkshopTargetContainerRecords04[aiIndex - 384]
	elseif(aiIndex < 640)
		return WorkshopTargetContainerRecords05[aiIndex - 512]
	elseif(aiIndex < 768)
		return WorkshopTargetContainerRecords06[aiIndex - 640]
	elseif(aiIndex < 896)
		return WorkshopTargetContainerRecords07[aiIndex - 768]
	elseif(aiIndex < 1024)
		return WorkshopTargetContainerRecords08[aiIndex - 896]
	endif
	
	return None
EndFunction


Function UpdateWorkshopTargetContainerRecord(Int aiIndex, WorkshopTargetContainer aProducedRecord)
	if(aiIndex < 128)
		if(WorkshopTargetContainerRecords01 == None)
			WorkshopTargetContainerRecords01 = new WorkshopTargetContainer[128]
		endif
		
		WorkshopTargetContainerRecords01[aiIndex] = aProducedRecord
	elseif(aiIndex < 256)
		if(WorkshopTargetContainerRecords02 == None)
			WorkshopTargetContainerRecords02 = new WorkshopTargetContainer[128]
		endif
		
		WorkshopTargetContainerRecords02[aiIndex - 128] = aProducedRecord
	elseif(aiIndex < 384)
		if(WorkshopTargetContainerRecords03 == None)
			WorkshopTargetContainerRecords03 = new WorkshopTargetContainer[128]
		endif
		
		WorkshopTargetContainerRecords03[aiIndex - 256] = aProducedRecord
	elseif(aiIndex < 512)
		if(WorkshopTargetContainerRecords04 == None)
			WorkshopTargetContainerRecords04 = new WorkshopTargetContainer[128]
		endif
		
		WorkshopTargetContainerRecords04[aiIndex - 384] = aProducedRecord
	elseif(aiIndex < 640)
		if(WorkshopTargetContainerRecords05 == None)
			WorkshopTargetContainerRecords05 = new WorkshopTargetContainer[128]
		endif
		
		WorkshopTargetContainerRecords05[aiIndex - 512] = aProducedRecord
	elseif(aiIndex < 768)
		if(WorkshopTargetContainerRecords06 == None)
			WorkshopTargetContainerRecords06 = new WorkshopTargetContainer[128]
		endif
		
		WorkshopTargetContainerRecords06[aiIndex - 640] = aProducedRecord
	elseif(aiIndex < 896)
		if(WorkshopTargetContainerRecords07 == None)
			WorkshopTargetContainerRecords07 = new WorkshopTargetContainer[128]
		endif
		
		WorkshopTargetContainerRecords07[aiIndex - 768] = aProducedRecord
	elseif(aiIndex < 1024)
		if(WorkshopTargetContainerRecords08 == None)
			WorkshopTargetContainerRecords08 = new WorkshopTargetContainer[128]
		endif
		
		WorkshopTargetContainerRecords08[aiIndex - 896] = aProducedRecord
	endif
endFunction


Function SetupWorkshopContainer(WorkshopObjectScript akContainerRef, WorkshopScript akWorkshopRef)
	if(akContainerRef && akContainerRef.WorkshopContainerType && akWorkshopRef)
		akContainerRef.SetLinkedRef(akWorkshopRef, akContainerRef.WorkshopContainerType)
		WorkshopContainers.AddRef(akContainerRef)
	endif
EndFunction

Function ClearWorkshopContainer(WorkshopObjectScript akContainerRef)
	if(akContainerRef && akContainerRef.WorkshopContainerType)
		akContainerRef.SetLinkedRef(None, akContainerRef.WorkshopContainerType)
		WorkshopContainers.RemoveRef(akContainerRef)
	endif
EndFunction


ObjectReference[] Function GetAllContainers(WorkshopScript akWorkshopRef, Keyword aTargetContainerKeyword)
	if( ! akWorkshopRef)
		return None
	endif
	
	ObjectReference[] kContainers = new ObjectReference[0] ; 1.0.1 - Ensure this is initialized
	
	if(aTargetContainerKeyword != None)
		kContainers = akWorkshopRef.GetLinkedRefChildren(aTargetContainerKeyword)
		
		if(kContainers.Length > 0)
			return kContainers
		else
			; Recurse up chain of container type keywords
			return GetAllContainers(akWorkshopRef, GetParentContainerKeyword(aTargetContainerKeyword))
		endif
	endif
	
	if(kContainers.Length == 0)
		kContainers = new ObjectReference[0] ; 1.0.1 - Ensure this is initialized
		kContainers.Add(akWorkshopRef.GetContainer())
	endif
	
	return kContainers
EndFunction


ObjectReference Function GetContainer(WorkshopScript akWorkshopRef, Keyword aTargetContainerKeyword = None)
	if( ! akWorkshopRef)
		return None
	endif
	
	ObjectReference kContainer
	
	if(aTargetContainerKeyword != None)
		ObjectReference[] kTemp = akWorkshopRef.GetLinkedRefChildren(aTargetContainerKeyword)
		
		if(kTemp.Length)
			kContainer = kTemp[Utility.RandomInt(0, kTemp.Length - 1)]
		else
			; Recurse up chain of container type keywords
			return GetContainer(akWorkshopRef, GetParentContainerKeyword(aTargetContainerKeyword))
		endif
	endif
	
	if(kContainer)
		return kContainer
	else
		return akWorkshopRef.GetContainer()
	endif
EndFunction


Keyword Function GetParentContainerKeyword(Keyword aKeyword)
	if(aKeyword == WaterContainerKeyword || aKeyword == AlcoholContainerKeyword || aKeyword == NukaColaContainerKeyword)
		return DrinkContainerKeyword
	elseif(aKeyword == DrinkContainerKeyword || aKeyword == FoodContainerKeyword || aKeyword == ChemContainerKeyword)
		return AidContainerKeyword
	elseif(aKeyword == ScavengeBuildingMaterialsContainerKeyword || aKeyword == ScavengeGeneralScrapContainerKeyword || aKeyword == ScavengePartsContainerKeyword || aKeyword == ScavengeRareContainerKeyword)
		return ScrapContainerKeyword
	elseif(aKeyword == ComponentContainerKeyword || aKeyword == ScrapContainerKeyword)
		return JunkContainerKeyword
	elseif(aKeyword == AmmoContainerKeyword)
		return WeaponContainerKeyword
	elseif(aKeyword == WeaponContainerKeyword || aKeyword == ModContainerKeyword || aKeyword == ArmorContainerKeyword)
		return EquipmentContainerKeyword
	elseif(aKeyword == FertilizerContainerKeyword || aKeyword == HolotapeContainerKeyword || aKeyword == NoteContainerKeyword || aKeyword == CapsContainerKeyword)
		return MiscContainerKeyword
	else
		return None
	endif
EndFunction