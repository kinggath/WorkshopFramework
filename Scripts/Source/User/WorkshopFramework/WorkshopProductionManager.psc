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

;/TODO 	
- Create report holotape or note (ala AFT) for viewing all of the custom resources
- How can we support productivity boosts?
/;

; ---------------------------------------------
; Consts
; ---------------------------------------------

int ProductionLoopTimerID = 100 Const
float fThrottleContainerRouting = 0.5 Const

; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------

Group Controllers
	WorkshopFramework:MainThreadManager Property ThreadManager Auto Const Mandatory
	WorkshopParentScript Property WorkshopParent Auto Const Mandatory 
	Int Property iWorkshopParentInitializedStage = 20 Auto Const
	WorkshopFramework:WorkshopResourceManager Property ResourceManager Auto Const Mandatory
EndGroup


Group ActorValues
	ActorValue[] Property FoodTypes Auto Const Mandatory
	ActorValue Property Food Auto Const Mandatory
	ActorValue Property Water Auto Const Mandatory
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
EndGroup

Group Aliases
	ReferenceAlias Property SafeSpawnPoint Auto Const Mandatory 
	{ Location to store production records }
	RefCollectionAlias Property ProductionList Auto Const Mandatory
	{ Alias to hold all registered ProductionRecord objects }
	RefCollectionAlias Property WorkshopContainers Auto Const Mandatory
	{ Alias to hold all workshop containers so we can produce in them }
EndGroup


Group Assets
	Form Property BlankProductionRecord Auto Const Mandatory
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

Bool bProductionUnderwayBlock ; Unlike a lock, with the block we will just reject any incoming calls if a block is held

; Food and water are handled special since they affect the UI and gameplay mechanics. So even with specialty production, we're going to want to include high AVs. Whereas Scavenge, we can just applied a .01 scavege rating to get the UI to flag the assigned settler as a scavenger.
Int[] iSpecialFoodProduction ; Total food value for each settlement that is producing specialty resources
Int[] iSpecialWaterProduction ; Total water value for each settlement that is producing specialty resources

ObjectReference[] RouteContainers ; Holds containers we'll monitor for OnItemAdded to re-distribute items to appropriate containers

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
	int iWorkshopID = RouteContainers.Find(akAddedTo)
	WorkshopScript kTargetWorkshop = ResourceManager.Workshops[iWorkshopID]
	ObjectReference kContainer = None
	
	if(kTargetWorkshop)
		Keyword TargetContainerKeyword = None
		
		; Try and auto-classify
		if(akBaseItem as Potion)
			if(akBaseItem.HasKeyword(ObjectTypeAlcohol))
				TargetContainerKeyword = AlcoholContainerKeyword
			elseif(akBaseItem.HasKeyword(ObjectTypeNukaCola))
				TargetContainerKeyword = NukaColaContainerKeyword
			elseif(akBaseItem.HasKeyword(ObjectTypeWater))
				TargetContainerKeyword = WaterContainerKeyword
			elseif(akBaseItem.HasKeyword(ObjectTypeDrink))
				TargetContainerKeyword = DrinkContainerKeyword
			elseif(akBaseItem.HasKeyword(ObjectTypeFood))
				TargetContainerKeyword = FoodContainerKeyword
			elseif(akBaseItem.HasKeyword(ObjectTypeChem))
				TargetContainerKeyword = ChemContainerKeyword
			else
				TargetContainerKeyword = AidContainerKeyword
			endif
		elseif(akBaseItem as Component)
			TargetContainerKeyword = ComponentContainerKeyword
		elseif(akBaseItem == Caps001)
			TargetContainerKeyword = CapsContainerKeyword
		elseif(akBaseItem as Holotape)
			TargetContainerKeyword = HolotapeContainerKeyword
		elseif(akBaseItem as Book)
			TargetContainerKeyword = NoteContainerKeyword
		elseif(FertilizerList.Find(akBaseItem) >= 0)
			TargetContainerKeyword = FertilizerContainerKeyword
		elseif(akBaseItem as Ammo)
			TargetContainerKeyword = AmmoContainerKeyword
		elseif(akBaseItem as Armor)
			TargetContainerKeyword = ArmorContainerKeyword
		elseif(akBaseItem as ObjectMod)
			TargetContainerKeyword = ModContainerKeyword
		elseif(akBaseItem as Weapon)
			TargetContainerKeyword = WeaponContainerKeyword
		elseif(akBaseItem as MiscObject)
			if(ScavengeList_BuildingMaterials.Find(akBaseItem) >= 0)
				TargetContainerKeyword = ScavengeBuildingMaterialsContainerKeyword
			elseif(ScavengeList_General.Find(akBaseItem) >= 0)
				TargetContainerKeyword = ScavengeGeneralScrapContainerKeyword
			elseif(ScavengeList_Parts.Find(akBaseItem) >= 0)
				TargetContainerKeyword = ScavengePartsContainerKeyword
			elseif(ScavengeList_Rare.Find(akBaseItem) >= 0)
				TargetContainerKeyword = ScavengeRareContainerKeyword
			else
				TargetContainerKeyword = MiscContainerKeyword
			endif
		endif
		
		kContainer = GetContainer(kTargetWorkshop, TargetContainerKeyword)
	endif
	
	if( ! kContainer)
		Debug.Trace("Unable to locate an eligible container for this item, deleting: " + akBaseItem + ".")
	endif
	
	; Route item
	akAddedTo.RemoveItem(akBaseItem, aiItemCount, akOtherContainer = kContainer)
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
	iSpecialFoodProduction = new Int[128]
	iSpecialWaterProduction = new Int[128]
	RouteContainers = new ObjectReference[0]
	
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

; ---------------------------------------------
; Overrides
; ---------------------------------------------


; ---------------------------------------------
; Functions
; ---------------------------------------------

Function RegisterProductionItem(LeveledItem aProduceMe, Int aiWorkshopID, Keyword aTargetContainerKeyword = None, Bool abIsFoodResource = false, Bool abIsWaterResource = false, Bool abIsScavengeResource = false)
	WorkshopFramework:Library:ObjectRefs:ProductionRecord kRecord = FindProductionItem(aProduceMe, aiWorkshopID)
	
	if(kRecord)
		kRecord.iCount += 1
	else
		CreateProductionItem(aProduceMe, aiWorkshopID, 1, aTargetContainerKeyword, abIsFoodResource, abIsWaterResource, abIsScavengeResource)
	endif	
	
	if(abIsFoodResource)
		iSpecialFoodProduction[aiWorkshopID] += 1
	endif
	
	if(abIsWaterResource)
		iSpecialWaterProduction[aiWorkshopID] += 1
	endif
EndFunction


Function UnregisterProductionItem(LeveledItem aRemoveMe, Int aiWorkshopID)
	WorkshopFramework:Library:ObjectRefs:ProductionRecord kRecord = FindProductionItem(aRemoveMe, aiWorkshopID)
	
	if(kRecord && kRecord.iCount > 0)
		kRecord.iCount -= 1
	endif
	
	if(kRecord.bIsFood && iSpecialFoodProduction[aiWorkshopID] > 0)
		iSpecialFoodProduction[aiWorkshopID] -= 1
	endif
	
	if(kRecord.bIsWater && iSpecialWaterProduction[aiWorkshopID] > 0)
		iSpecialWaterProduction[aiWorkshopID] -= 1
	endif
EndFunction


Function StartProductionTimer()
	WorkshopScript[] kWorkshops = ResourceManager.Workshops
	if(RouteContainers.Length < kWorkshops.Length)
		int i = RouteContainers.Length
		while(i < kWorkshops.Length)
			ObjectReference kTemp = SafeSpawnPoint.GetRef().PlaceAtMe(DummyContainerForm, abForcePersist = true, abDeleteWhenAble = false)
			
			if(kTemp)
				RouteContainers.Add(kTemp)
				RegisterForRemoteEvent(kTemp, "OnItemAdded")
			endif
			
			i += 1
		endWhile
	endif
	
	StartTimerGameTime(fProductionLoopTime, ProductionLoopTimerID)
EndFunction


WorkshopFramework:Library:ObjectRefs:ProductionRecord Function CreateProductionItem(LeveledItem aProduceMe, Int aiWorkshopID, Int aiStartCount = 1, Keyword aTargetContainerKeyword = None, Bool abIsFoodResource = false, Bool abIsWaterResource = false, Bool abIsScavengeResource = false)
	ObjectReference kSpawnPoint = SafeSpawnPoint.GetRef()
	
	if( ! kSpawnPoint)
		return None
	endif
	
	WorkshopFramework:Library:ObjectRefs:ProductionRecord kRecord = kSpawnPoint.PlaceAtMe(BlankProductionRecord, abDeleteWhenAble = false) as WorkshopFramework:Library:ObjectRefs:ProductionRecord
	
	if(kRecord)
		ProductionList.AddRef(kRecord)
		
		kRecord.ProduceItem = aProduceMe
		kRecord.iWorkshopID = aiWorkshopID
		kRecord.iCount = aiStartCount
		kRecord.bIsFood = abIsFoodResource
		kRecord.bIsWater = abIsWaterResource
		kRecord.bIsScavenge = abIsScavengeResource
		kRecord.TargetContainerKeyword = aTargetContainerKeyword

		return kRecord
	endif
	
	return None
EndFunction


WorkshopFramework:Library:ObjectRefs:ProductionRecord Function FindProductionItem(LeveledItem aFindMe, Int aiWorkshopID)
	int i = 0
	int iMax = ProductionList.GetCount()
	
	while(i < iMax)
		WorkshopFramework:Library:ObjectRefs:ProductionRecord kRecord = ProductionList.GetAt(i) as WorkshopFramework:Library:ObjectRefs:ProductionRecord
		
		if(kRecord.ProduceItem && kRecord.ProduceItem == aFindMe && kRecord.iWorkshopID)
			return kRecord
		endif
		
		i += 1
	endWhile
	
	return None
EndFunction


Function ProduceAllWorkshopResources()
	if(bProductionUnderwayBlock)
		return
	endif
	
	bProductionUnderwayBlock = true
	
	Float fStartTime = Utility.GetCurrentRealtime()
	
	int i = 0
	RefCollectionAlias WorkshopsAlias = ResourceManager.WorkshopsAlias
	int iCount = WorkshopsAlias.GetCount()
	
	while(i < iCount)
		WorkshopScript kWorkshopRef = WorkshopsAlias.GetAt(i) as WorkshopScript
		
		ProduceWorkshopResources(kWorkshopRef)
		
		i += 1
	endWhile
	
	Debug.Trace("WSWF: Resource production for " + iCount + " workshops took " + (Utility.GetCurrentRealtime() - fStartTime) + " seconds.")
	bProductionUnderwayBlock = false
EndFunction

Function ProduceWorkshopResources(WorkshopScript akWorkshopRef)
	if( ! akWorkshopRef)
		return
	endif
	
	int iWorkshopID = akWorkshopRef.GetWorkshopID()
	
	if(iWorkshopID < 0)
		return
	endif	
	
	; First produce general resources based on ratings (food/water/scavenge/caps/fertilizer)
	int iMaxProduceFoodRemaining = ProduceFood(akWorkshopRef)
	int iMaxProduceWaterRemaining = ProduceWater(akWorkshopRef)
	int iMaxProduceScavengeRemaining = ProduceScavenge(akWorkshopRef)
		
	ProduceFertilizer(akWorkshopRef)
	ProduceVendorIncome(akWorkshopRef)		
	
	; Next produce specialty resources
	int i = 0
	int iMax = ProductionList.GetCount()
	
	while(i < iMax)
		WorkshopFramework:Library:ObjectRefs:ProductionRecord kRecord = ProductionList.GetAt(i) as WorkshopFramework:Library:ObjectRefs:ProductionRecord
		
		if(kRecord.ProduceItem && kRecord.iWorkshopID == iWorkshopID)
			int iProduceCount = kRecord.iCount
			
			if(kRecord.bIsWater)
				if(iMaxProduceWaterRemaining > 0)
					Keyword ContainerKeyword = kRecord.TargetContainerKeyword
						
					if( ! ContainerKeyword)
						ContainerKeyword = WaterContainerKeyword
					endif
					
					if(iMaxProduceWaterRemaining > iProduceCount)
						iMaxProduceWaterRemaining -= iProduceCount
					else
						iProduceCount = iMaxProduceWaterRemaining
						iMaxProduceWaterRemaining = 0
					endif
					
					ProduceItems(kRecord.ProduceItem, akWorkshopRef, iProduceCount, ContainerKeyword)
				endif
			elseif(kRecord.bIsFood)
				if(iMaxProduceFoodRemaining > 0)
					Keyword ContainerKeyword = kRecord.TargetContainerKeyword
						
					if( ! ContainerKeyword)
						ContainerKeyword = FoodContainerKeyword
					endif
					
					if(iMaxProduceFoodRemaining > iProduceCount)
						iMaxProduceFoodRemaining -= iProduceCount
					else
						iProduceCount = iMaxProduceFoodRemaining
						iMaxProduceFoodRemaining = 0
					endif
					
					ProduceItems(kRecord.ProduceItem, akWorkshopRef, iProduceCount, ContainerKeyword)
				endif
			elseif(kRecord.bIsScavenge)
				if(iMaxProduceScavengeRemaining > 0)
					if(iMaxProduceScavengeRemaining > iProduceCount)
						iMaxProduceScavengeRemaining -= iProduceCount
					else
						iProduceCount = iMaxProduceScavengeRemaining
						iMaxProduceScavengeRemaining = 0
					endif
					
					ProduceItems(kRecord.ProduceItem, akWorkshopRef, kRecord.iCount, kRecord.TargetContainerKeyword)
				endif
			else
				; TODO: Expand the storage system for more gameplay options - things like limitations on non-scavenge items so players can build more storage. Ex. MaxProduceWeapons or MaxProduceAmmo
								
				ProduceItems(kRecord.ProduceItem, akWorkshopRef, kRecord.iCount, kRecord.TargetContainerKeyword)
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
	
	Int iCurrentFoodProductionValue = Math.Ceiling(ResourceManager.GetWorkshopValue(akWorkshopRef, Food))
	Float fLivingPopulation = akWorkshopRef.GetBaseValue(Population) - akWorkshopRef.GetBaseValue(RobotPopulation)
	Float fPopulationBrahmin = akWorkshopRef.GetValue(BrahminPopulation)
	
	; Increase production via fertilizer (in the form of Brahmin poo)
	if(fPopulationBrahmin > 0)
		int iBrahminMaxFoodBoost = Math.min(fPopulationBrahmin * akWorkshopRef.maxProductionPerBrahmin, iCurrentFoodProductionValue) as int
		iCurrentFoodProductionValue += Math.Ceiling(iBrahminMaxFoodBoost * akWorkshopRef.brahminProductionBoost)
	endif
	
	; Reduce by special production
	iCurrentFoodProductionValue -= iSpecialFoodProduction[iWorkshopID]
	
	; Reduce by damage
	iCurrentFoodProductionValue = Math.max(0, iCurrentFoodProductionValue - (akWorkshopRef.GetValue(FoodDamaged) as int)) as int
	
		
	if(iCurrentFoodProductionValue > 0)
		; Test to make sure we aren't at max surplus food
		int iMaxStoredFood = akWorkshopRef.maxStoredFoodBase + Math.Ceiling(akWorkshopRef.maxStoredFoodPerPopulation * fLivingPopulation) + (fLivingPopulation as Int) ; Since we've fully separated consumption from production, we need to allow for the next day's consumption in the max storage so we add living population here
		
		ObjectReference FoodContainer = GetContainer(akWorkshopRef, FoodContainerKeyword)
		
		int iCurrentStoredFood = FoodContainer.GetItemCount(ObjectTypeFood)
		int iMaxProduceFood = iMaxStoredFood - iCurrentStoredFood
		int iProduceFood = Math.Min(iCurrentFoodProductionValue, iMaxProduceFood) as Int
		if(iProduceFood > 0)
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
	
	Int iCurrentWaterProductionValue = Math.Ceiling(ResourceManager.GetWorkshopValue(akWorkshopRef, Water))
	Float fLivingPopulation = akWorkshopRef.GetBaseValue(Population) - akWorkshopRef.GetBaseValue(RobotPopulation)
		
	; Reduce by special production
	iCurrentWaterProductionValue -= iSpecialWaterProduction[iWorkshopID]
	
	; Reduce by damage
	iCurrentWaterProductionValue = Math.max(0, iCurrentWaterProductionValue - (akWorkshopRef.GetValue(WaterDamaged) as int)) as int
	
	if(iCurrentWaterProductionValue > 0)
		; Test to make sure we aren't at max surplus water
		int iMaxStoredWater = akWorkshopRef.maxStoredWaterBase + Math.Ceiling(akWorkshopRef.maxStoredWaterPerPopulation * fLivingPopulation) + (fLivingPopulation as Int) ; Since we've fully separated consumption from production, we need to allow for the next day's consumption in the max storage so we add living population here
		
		ObjectReference WaterContainer = GetContainer(akWorkshopRef, WaterContainerKeyword)
		
		int iCurrentStoredWater = WaterContainer.GetItemCount(ObjectTypeWater)
		int iMaxProduceWater = iMaxStoredWater - iCurrentStoredWater
		int iProduceWater = Math.Min(iCurrentWaterProductionValue, iMaxProduceWater) as Int
		if(iProduceWater > 0)
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
	
	ObjectReference ScavengeContainer = GetContainer(akWorkshopRef, ScrapContainerKeyword)
	ObjectReference BuildingMaterialsContainer = GetContainer(akWorkshopRef, ScavengeBuildingMaterialsContainerKeyword)
	ObjectReference GeneralContainer = GetContainer(akWorkshopRef, ScavengeGeneralScrapContainerKeyword)
	ObjectReference PartsContainer = GetContainer(akWorkshopRef, ScavengePartsContainerKeyword)
	ObjectReference RareContainer = GetContainer(akWorkshopRef, ScavengeRareContainerKeyword)
	
	int iCurrentStoredScavenge = ScavengeContainer.GetItemCount(ScavengeList_All)
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
	
	Float fScavengeBuildingMaterialsProduction = ResourceManager.GetWorkshopValue(akWorkshopRef, Scavenge_BuildingMaterials)
	Float fScavengeGeneralProduction = ResourceManager.GetWorkshopValue(akWorkshopRef, Scavenge_General)
	Float fScavengePartsProduction = ResourceManager.GetWorkshopValue(akWorkshopRef, Scavenge_Parts)
	Float fScavengeRareProduction = ResourceManager.GetWorkshopValue(akWorkshopRef, Scavenge_Rare)
	
	int iMaxProduce = iMaxStoredScavenge - iCurrentStoredScavenge
	
	if(fScavengeBuildingMaterialsProduction <= 0 && fScavengePartsProduction <= 0 && fScavengeRareProduction <=0)
		; Player has no mods taking advantage of the new AVs, just use the default scavenge system
		ProduceItems(DefaultScavProductionItem_All, akWorkshopRef, Math.Floor(fScavengeGeneralProduction), ScavengeGeneralScrapContainerKeyword)
		
		iMaxProduce -= Math.Floor(fScavengeGeneralProduction)
	else	
		Float fTotalProduction = fScavengeBuildingMaterialsProduction + fScavengeGeneralProduction + fScavengePartsProduction + fScavengeRareProduction
		
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
	
	ObjectReference FertilizerContainer = GetContainer(akWorkshopRef, FertilizerContainerKeyword)
	
	int iCurrentStoredFertilizer = FertilizerContainer.GetItemCount(FertilizerList)
	; Test against max and produce
	int iMaxStoredFertilizer = akWorkshopRef.maxBrahminFertilizerProduction
	if(iCurrentStoredFertilizer < iMaxStoredFertilizer)
		int iProduce = akWorkshopRef.GetBaseValue(BrahminPopulation) as int
		
		ProduceItems(FertilizerProductionItem, akWorkshopRef, Math.Min(iProduce, iMaxStoredFertilizer) as Int, FertilizerContainerKeyword)
		
		return iMaxStoredFertilizer - iProduce
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
		
		if(iVendorIncomeFinal >= 1)
			ProduceItems(Caps001, akWorkshopRef, iVendorIncomeFinal, CapsContainerKeyword)
		endif	
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
	ObjectReference kContainer 
	
	if( ! aTargetContainerKeyword)
		; Send to temporary container so we can reroute all items
		int iWorkshopID = akWorkshopRef.GetWorkshopID()
		kContainer = RouteContainers[iWorkshopID]
		; Give a brief pause so we don't overwhelm ourselves with OnItemAdded events
		Utility.Wait(fThrottleContainerRouting)
	else
		kContainer = GetContainer(akWorkshopRef, aTargetContainerKeyword)
	endif
	
	if(kContainer)
		kContainer.AddItem(aProduceMe, aiCount)
	endif
EndFunction


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


ObjectReference Function GetContainer(WorkshopScript akWorkshopRef, Keyword aTargetContainerKeyword = None)
	if( ! akWorkshopRef)
		return None
	endif
	
	ObjectReference kContainer = akWorkshopRef.GetContainer()
	
	if(aTargetContainerKeyword != None)
		ObjectReference[] kTemp = akWorkshopRef.GetLinkedRefChildren(aTargetContainerKeyword)
		
		if(kTemp.Length)
			kContainer = kTemp[Utility.RandomInt(0, kTemp.Length - 1)]
		else
			; Recurse up chain of container type keywords
			return GetContainer(akWorkshopRef, GetParentContainerKeyword(aTargetContainerKeyword))
		endif
	endif
	
	return kContainer
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