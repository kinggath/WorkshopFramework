; ---------------------------------------------
; WorkshopFramework:InjectionManager.psc - by kinggath
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

Scriptname WorkshopFramework:InjectionManager extends WorkshopFramework:Library:SlaveQuest
{ Handles injection into leveled lists. Overall goal is to allow multiple mods to alter the same list without requiring patches and reducing the likelihood of crashes if a player uninstalls an injected mod mid-playthrough }

import WorkshopFramework:Library:DataStructures
import WorkshopFramework:Library:UtilityFunctions

; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------

Group Controllers
	WorkshopFramework:WorkshopResourceManager Property ResourceManager Auto Const
EndGroup

Group Injectables
	LeveledActor Property BrahminLCharHolder Auto Const Mandatory
	{ Blank leveled actor }
	LeveledActor Property SettlerLCharHolder Auto Const Mandatory
	{ Blank leveled actor }
	LeveledActor Property SettlerGuardLCharHolder Auto Const Mandatory
	{ Blank leveled actor }
	LeveledItem Property WorkshopFood Auto Const Mandatory
	{ Blank leveled item }
	LeveledItem Property WorkshopFoodTypeCarrot Auto Const Mandatory
	{ Blank leveled item }
	LeveledItem Property WorkshopFoodTypeCorn Auto Const Mandatory
	{ Blank leveled item }
	LeveledItem Property WorkshopFoodTypeGourd Auto Const Mandatory
	{ Blank leveled item }
	LeveledItem Property WorkshopFoodTypeMelon Auto Const Mandatory
	{ Blank leveled item }
	LeveledItem Property WorkshopFoodTypeMutfruit Auto Const Mandatory
	{ Blank leveled item }
	LeveledItem Property WorkshopFoodTypeRazorgrain Auto Const Mandatory
	{ Blank leveled item }
	LeveledItem Property WorkshopFoodTypeTarberry Auto Const Mandatory
	{ Blank leveled item }
	LeveledItem Property WorkshopFoodTypeTato Auto Const Mandatory
	{ Blank leveled item }
	LeveledItem Property WorkshopWater Auto Const Mandatory
	{ Blank leveled item }
	LeveledItem Property WorkshopFertilizer Auto Const Mandatory
	{ Blank leveled item }
	LeveledItem Property WorkshopScavAll Auto Const Mandatory
	{ Blank leveled item }
	LeveledItem Property WorkshopScavRare Auto Const Mandatory
	{ Blank leveled item }
	LeveledItem Property WorkshopScavBuildingMaterials Auto Const Mandatory
	{ Blank leveled item }
	LeveledItem Property WorkshopScavGeneral Auto Const Mandatory
	{ Blank leveled item }
	LeveledItem Property WorkshopScavParts Auto Const Mandatory
	{ Blank leveled item }
	LeveledItem[] Property WorkshopVendorInventoryArmor Auto Const Mandatory
	LeveledItem[] Property WorkshopVendorInventoryBar Auto Const Mandatory
	LeveledItem[] Property WorkshopVendorInventoryClinic Auto Const Mandatory
	LeveledItem[] Property WorkshopVendorInventoryClothing Auto Const Mandatory
	LeveledItem[] Property WorkshopVendorInventoryGeneral Auto Const Mandatory
	LeveledItem[] Property WorkshopVendorInventoryWeapon Auto Const Mandatory
EndGroup



Group InjectableRecords
	InjectableActorMap[] Property InjectableLeveledActors Auto Const
	InjectableItemMap[] Property InjectableLeveledItems Auto Const
EndGroup


; ---------------------------------------------
; Properties
; ---------------------------------------------

int Property VendorTopLevel = 2 Auto Const

; ---------------------------------------------
; Vars
; ---------------------------------------------

Bool bSetupListsBlock = false ; Unlike a lock, with the block we will just reject any incoming calls if a block is held


; ---------------------------------------------
; Events 
; ---------------------------------------------

Function HandleQuestInit()
	Parent.HandleQuestInit()
	
	; For existing saves, force vendor containers to be recreated using our new versions
	WorkshopScript[] Workshops = ResourceManager.Workshops
	
	int i = 0
	while(i < Workshops.Length)
		Workshops[i].VendorContainersMisc = None
		Workshops[i].VendorContainersArmor = None
		Workshops[i].VendorContainersWeapons = None
		Workshops[i].VendorContainersBar = None
		Workshops[i].VendorContainersClinic = None
		Workshops[i].VendorContainersClothing = None	
		
		i += 1
	endWhile
	
	SetupLeveledLists()
EndFunction


Function HandleGameLoaded()
	Parent.HandleGameLoaded()
	
	SetupLeveledLists()
EndFunction


; ---------------------------------------------
; Methods 
; ---------------------------------------------

Function SetupLeveledLists()
	if(bSetupListsBlock)
		return
	endif
	
	bSetupListsBlock = true
	
	; Setup LeveledActors
	int i = 0
	while(i < InjectableLeveledActors.Length)
		RebuildActorList(InjectableLeveledActors[i])
		
		i += 1
	endWhile
	
	; Setup LeveledItems
	i = 0
	while(i < InjectableLeveledItems.Length)
		RebuildItemList(InjectableLeveledItems[i])
		
		i += 1
	endWhile
	
	bSetupListsBlock = false
EndFunction


Function RebuildActorList(InjectableActorMap aListToRebuild)
	int iLockKey
	
	; Get Edit Lock 
	iLockKey = GetLock()
	if(iLockKey <= GENERICLOCK_KEY_NONE)
		ModTrace("Unable to get lock!", 2)
		
		return
	endif
	
	LeveledActor asLA = aListToRebuild.TargetLeveledActor
	
	if(asLA)
		asLA.Revert()
		
		; Add defaults
		if(aListToRebuild.DefaultEntries)
			int i = 0
			while(i < aListToRebuild.DefaultEntries.GetSize())
				Form thisForm = aListToRebuild.DefaultEntries.GetAt(i)
				
				if( ! aListToRebuild.RemovedDefaultEntries || aListToRebuild.RemovedDefaultEntries.Find(thisForm) < 0)
					asLA.AddForm(thisForm, 1)
				endif
			
				i += 1
			endWhile
		endif
		
		; Add additions
		if(aListToRebuild.AdditionalEntries)
			CleanFormList(aListToRebuild.AdditionalEntries)
			
			int i = 0
			while(i < aListToRebuild.AdditionalEntries.GetSize())
				Form thisForm = aListToRebuild.AdditionalEntries.GetAt(i)
				
				asLA.AddForm(thisForm, 1)
			
				i += 1
			endWhile
		endif
	endif
	
	; Release Edit Lock
	if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
		ModTrace("Failed to release lock " + iLockKey + "!", 2)
	endif	
EndFunction



Function RebuildItemList(InjectableItemMap aListToRebuild)
	int iLockKey
	
	; Get Edit Lock 
	iLockKey = GetLock()
	if(iLockKey <= GENERICLOCK_KEY_NONE)
		ModTrace("Unable to get lock!", 2)
		
		return
	endif
	
	LeveledItem asLI = aListToRebuild.TargetLeveledItem
	
	if(asLI)
		asLI.Revert()
		
		; Add defaults
		if(aListToRebuild.DefaultEntries)
			int i = 0
			while(i < aListToRebuild.DefaultEntries.GetSize())
				Form thisForm = aListToRebuild.DefaultEntries.GetAt(i)
				
				if( ! aListToRebuild.RemovedDefaultEntries || aListToRebuild.RemovedDefaultEntries.Find(thisForm) < 0)
					asLI.AddForm(thisForm, 1, 1)
				endif
			
				i += 1
			endWhile
		endif
		
		; Add additions
		if(aListToRebuild.AdditionalEntries)
			CleanFormList(aListToRebuild.AdditionalEntries)
			
			int i = 0
			while(i < aListToRebuild.AdditionalEntries.GetSize())
				Form thisForm = aListToRebuild.AdditionalEntries.GetAt(i)
				
				asLI.AddForm(thisForm, 1, 1)
			
				i += 1
			endWhile
		endif
	endif
	
	; Release Edit Lock
	if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
		ModTrace("Failed to release lock " + iLockKey + "!", 2)
	endif	
EndFunction


InjectableActorMap Function FindInjectableActorMap(LeveledActor aTargetList)
	int i = 0
	while(i < InjectableLeveledActors.Length)
		if(InjectableLeveledActors[i].TargetLeveledActor == aTargetList)
			return InjectableLeveledActors[i]
		endif
		
		i += 1
	endWhile
	
	return None
EndFunction


InjectableItemMap Function FindInjectableItemMap(LeveledItem aTargetList)
	int i = 0
	while(i < InjectableLeveledItems.Length)
		if(InjectableLeveledItems[i].TargetLeveledItem == aTargetList)
			return InjectableLeveledItems[i]
		endif
		
		i += 1
	endWhile
	
	return None
EndFunction


Function AddToList(Form aTargetList, Form aAddForm)
	LeveledActor asLA = aTargetList as LeveledActor
	LeveledItem asLI = aTargetList as LeveledItem
	FormList asFormList = (aAddForm as FormList) ; 1.0.1 - Added support for adding all items in a formlist with one function call
	
	if(asLA)
		InjectableActorMap thisMap = FindInjectableActorMap(asLA)
		
		if(thisMap && thisMap.AdditionalEntries)			
			if(asFormList)
				int i = 0
				while(i < asFormList.GetSize())
					thisMap.AdditionalEntries.AddForm(asFormList.GetAt(i))			
					asLA.AddForm(asFormList.GetAt(i), 1)
				
					i += 1
				endWhile
			else
				thisMap.AdditionalEntries.AddForm(aAddForm)			
				asLA.AddForm(aAddForm, 1)
			endif
		endif
	elseif(asLI)
		InjectableItemMap thisMap = FindInjectableItemMap(asLI)
		
		if(thisMap && thisMap.AdditionalEntries)
			if(asFormList)
				int i = 0
				while(i < asFormList.GetSize())
					thisMap.AdditionalEntries.AddForm(asFormList.GetAt(i))			
					asLI.AddForm(asFormList.GetAt(i), 1, 1)
				
					i += 1
				endWhile
			else
				thisMap.AdditionalEntries.AddForm(aAddForm)
				asLI.AddForm(aAddForm, 1, 1)
			endif
		endif
	endif
EndFunction


Function RemoveDefault(Form aFormToRemove, Form aTargetList)
	LeveledActor asLA = aTargetList as LeveledActor
	LeveledItem asLI = aTargetList as LeveledItem
	
	if(asLA)
		InjectableActorMap thisMap = FindInjectableActorMap(asLA)
		
		if(thisMap && thisMap.RemovedDefaultEntries)
			thisMap.RemovedDefaultEntries.AddForm(aFormToRemove)
			
			RebuildActorList(thisMap)
		endif
	elseif(asLI)
		InjectableItemMap thisMap = FindInjectableItemMap(asLI)
		
		if(thisMap && thisMap.RemovedDefaultEntries)
			thisMap.RemovedDefaultEntries.AddForm(aFormToRemove)
			
			RebuildItemList(thisMap)
		endif
	endif
EndFunction