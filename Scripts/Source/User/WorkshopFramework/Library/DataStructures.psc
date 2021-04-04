Scriptname WorkshopFramework:Library:DataStructures Hidden Const

Struct WorldObject
	Form ObjectForm = None
	{ Form to be created. [Optional] Either this, or iFormID + sPluginName have to be set. }
	Int iFormID = -1
	{ Decimal conversion of the last 6 digits of a forms Hex ID. [Optional] Either this + sPluginName, or ObjectForm have to be set. }
	String sPluginName = ""
	{ Exact file name the form is from (ex. Fallout.esm). [Optional] Either this + iFormID, or ObjectForm have to be set. }
	Float fPosX = 0.0
	Float fPosY = 0.0
	Float fPosZ = 0.0
	Float fAngleX = 0.0
	Float fAngleY = 0.0
	Float fAngleZ = 0.0
	Float fScale = 1.0
	
	Bool bForceStatic = false
EndStruct

struct RIDPNodeDisplayData
	String NodeName
	Form NodeRealInventoryDisplayPoint
endStruct


Struct ActorValueSet
	ActorValue AVForm = None
	{ ActorValue form. [Optional] Either this, or iFormID + sPluginName have to be set. }
	Int iFormID = -1
	{ Decimal conversion of the last 6 digits of a forms Hex ID. [Optional] Either this + sPluginName, or AVForm have to be set. }
	String sPluginName = ""
	{ Exact file name the form is from (ex. Fallout.esm). [Optional] Either this + iFormID, or AVForm have to be set. }
	
	Float fValue = 0.0
	{ The value to check for based on iCompareMethod }
	
	; 1.0.4 addition - will allow for using these as conditionals
	Int iCompareMethod = 0
	{ 0 means the value must be exactly = fValue, -1 means the value must be <= fValue, -2 means the value must be < fValue, 1 means the value must be >= fValue, 2 means the value must be > fValue }
EndStruct

Struct KeywordDataSet
	Keyword KeywordForm = None
	{ Location form. [Optional] Either this, or iFormID + sPluginName have to be set. }
	Int iFormID = -1
	{ Decimal conversion of the last 6 digits of a forms Hex ID. [Optional] Either this + sPluginName, or AVForm have to be set. }
	String sPluginName = ""
	{ Exact file name the form is from (ex. Fallout.esm). [Optional] Either this + iFormID, or AVForm have to be set. }

	Float fValue = 0.0
	{ The value to check for based on iCompareMethod }
	
	; 1.0.4 addition - will allow for using these as conditionals
	Int iCompareMethod = 0
	{ 0 means the value must be exactly = fValue, -1 means the value must be <= fValue, -2 means the value must be < fValue, 1 means the value must be >= fValue, 2 means the value must be > fValue }
EndStruct


; 1.0.4 - Expanding common structure options
Struct GlobalVariableSet
	GlobalVariable GlobalForm = None
	{ GlobalVariable form. [Optional] Either this, or iFormID + sPluginName have to be set. }
	Int iFormID = -1
	{ Decimal conversion of the last 6 digits of a forms Hex ID. [Optional] Either this + sPluginName, or GlobalVariable have to be set. }
	String sPluginName = ""
	{ Exact file name the form is from (ex. Fallout.esm). [Optional] Either this + iFormID, or GlobalVariable have to be set. }
	
	Float fValue = 0.0
	{ The value to check for based on iCompareMethod }
	
	Int iCompareMethod = 0
	{ 0 means the value must be exactly = fValue, -1 means the value must be <= fValue, -2 means the value must be < fValue, 1 means the value must be >= fValue, 2 means the value must be > fValue }
EndStruct

; 1.0.4 - Expanding common structure options
Struct QuestStageSet
	Quest QuestForm = None
	{ Quest form. [Optional] Either this, or iFormID + sPluginName have to be set. }
	Int iFormID = -1
	{ Decimal conversion of the last 6 digits of a forms Hex ID. [Optional] Either this + sPluginName, or QuestForm have to be set. }
	String sPluginName = ""
	{ Exact file name the form is from (ex. Fallout.esm). [Optional] Either this + iFormID, or QuestForm have to be set. }
	
	Int iStage = 0
	{ The stage that must be complete on this quest }
	Bool bNotDoneCheck = false
	{ If set to true, this will instead look to see that this stage is NOT complete }
EndStruct

; 1.2.0 - Expanding common structure options
Struct QuestObjectiveSet
	Quest QuestForm = None
	{ Quest form. [Optional] Either this, or iFormID + sPluginName have to be set. }
	Int iFormID = -1
	{ Decimal conversion of the last 6 digits of a forms Hex ID. [Optional] Either this + sPluginName, or QuestForm have to be set. }
	String sPluginName = ""
	{ Exact file name the form is from (ex. Fallout.esm). [Optional] Either this + iFormID, or QuestForm have to be set. }

	Int iObjective = 0
	{ The objective to check on this quest }

	Int iCompareMethod = 1
	{ 1 means the objective must be completed, 0 means the objective must not be failed and must not be completed, -1 means the objective must be failed }
EndStruct

; 1.2.0 - Expanding common structure options
Struct ScriptPropertySet
	Form CheckForm = None
	{ Form to check for script property value. [Optional] Either this, or iCheckFormID + sCheckPluginName have to be set. }
	Int iCheckFormID = -1
	{ Decimal conversion of the last 6 digits of a forms Hex ID. [Optional] Either this + sCheckPluginName, or CheckForm have to be set. }
	String sCheckPluginName = ""
	{ Exact file name the form is from (ex. Fallout.esm). [Optional] Either this + iCheckFormID, or CheckForm have to be set. }
	
	String sScriptName = ""
	{ Exact script name to be checked, including namespaces. }
	
	String sPropertyName = ""
	{ Exact property name to be checked. }
	
	Float fValue = 0.0
	{ If property holds a float/int/ bool, it will be compared to this (for bool 0.0 = false, 1.0 = true) for float/int this is based on iCompareMethod}
	
	String sValue = ""
	{ If property holds a string, it will be checked for matching against this }
	
	Int iCompareMethod = 0
	{ Float/Int: 0 means the value must be exactly = fValue, -1 means the value must be <= fValue, -2 means the value must be < fValue, 1 means the value must be >= fValue, 2 means the value must be > fValue, String/Form: 0 means check for match, any other value means check for mismatch }
	
	Form MatchForm = None
	{ Form to test property value against if it is a Form. [Optional] Either this, or iMatchFormID + sMatchPluginName have to be set. }
	Int iMatchFormID = -1
	{ Decimal conversion of the last 6 digits of a forms Hex ID. [Optional] Either this + sMatchPluginName, or FormToCheck have to be set. }
	String sMatchPluginName = ""
	{ Exact file name the form is from (ex. Fallout.esm). [Optional] Either this + iMatchFormID, or FormToCheck have to be set. }
EndStruct

; 1.0.4 - Expanding common structure options
Struct PluginCheck
	String PluginName
	{ The plugin name. If the plugin exists in multiple file extensions, and you want to accept any of the extensions, exclude the file extension here. }
	Bool bAvailableAsESL = false
	{ If you left off the extension on the PluginName, set this to true if an ESL version exists in the community. }
	Bool bAvailableAsESP = false
	{ If you left off the extension on the PluginName, set this to true if an ESP version exists in the community. }
	Bool bAvailableAsESM = false
	{ If you left off the extension on the PluginName, set this to true if an ESM version exists in the community. }
EndStruct


Struct UniversalForm
	Form BaseForm = None
	
	Int iFormID = -1
	{ Decimal conversion of the last 6 digits of a forms Hex ID. [Optional] Either this + sPluginName, or BaseForm have to be set. }
	String sPluginName = ""
	{ Exact file name the form is from (ex. Fallout.esm). [Optional] Either this + iFormID, or BaseForm have to be set. }
EndStruct

; 1.2.0 - Version of UniversalForm that can have a corresponding index for pairing with another array that might have a different number of entries
Struct IndexMappedUniversalForm
	Int iIndex
	Form BaseForm = None
	
	Int iFormID = -1
	{ Decimal conversion of the last 6 digits of a forms Hex ID. [Optional] Either this + sPluginName, or BaseForm have to be set. }
	String sPluginName = ""
	{ Exact file name the form is from (ex. Fallout.esm). [Optional] Either this + iFormID, or BaseForm have to be set. }
EndStruct

Struct IndexMappedNumber
	Int iIndex
	Float fNumber = 0.0
EndStruct

Struct IndexMappedString
	Int iIndex
	String sString = ""
EndStruct

Struct IndexMappedBool
	Int iIndex
	Bool bBool = false
EndStruct


Struct LinkToMe
	ObjectReference kLinkToMe = None
	
	Keyword LinkWith = None
	{ [Optional] If this is not set, nor are iFormID + sPluginName, kLinkToMe will just be linked to the target without a keyword }
	
	Int iFormID = -1
	{ Decimal conversion of the last 6 digits of a forms Hex ID. [Optional] Either this + sPluginName, or BaseForm have to be set. }
	String sPluginName = ""
	{ Exact file name the form is from (ex. Fallout.esm). [Optional] Either this + iFormID, or BaseForm have to be set. }
EndStruct


Struct InjectableActorMap
	LeveledActor TargetLeveledActor = None
	FormList DefaultEntries = None
	FormList AdditionalEntries = None
	FormList RemovedDefaultEntries = None
EndStruct


Struct InjectableItemMap
	LeveledItem TargetLeveledItem = None
	FormList DefaultEntries = None
	FormList AdditionalEntries = None
	FormList RemovedDefaultEntries = None
EndStruct


Struct InjectionMap
	LeveledItem TargetLeveledItem = None
	Formlist NewEntries = None
	Int iLevel = 1
	Int iCount = 1
EndStruct

Struct WorkshopTargetContainer
	Keyword TargetContainerKeyword
	Int iWorkshopID
EndStruct

; 1.0.8 - Adding new centralized method for mods to report a new shortage. Since we don't have a UI method of displaying new shortages, this will be an easy way for mods to communicate about needs for the sake of reporting and automation
Struct ResourceShortage
	ActorValue ResourceAV
	Float fAmountRequired
	{ The total value this settlement should have to no longer be considered short }
	Float fTimeLastReported
	{ If a shortage isn't re-reported after 2 days in-game, it will be cleared - this is to prevent changes in logic from mods, or removal of mods, or other circumstances from permanently affecting the shortage data }
EndStruct

; 1.1.11 - Used for pairing a global to wether or not a plugin is installed
Struct PluginInstalledGlobal
	GlobalVariable GlobalForm
	String sPluginName
EndStruct

; 1.1.11 - Used for handling workshop menu injection pairing
Struct WorkshopMenuInjection
	Formlist TargetMenu
	Form InjectKeywordOrFormlist
EndStruct


; 1.0.8 - Simple global/value pair storage - for use in comparison, or creating localized equivalents of globals
Struct GlobalSettingMap
	GlobalVariable GlobalForm
	Float fValue
EndStruct


; 1.0.8 - Simple ActorValue/value pair storage
Struct ActorValueMap
	ActorValue ActorValueForm
	Float fValue
EndStruct


; 1.0.8 - Structs for new MessageManager controller quest
Struct BasicMessage
	Message bmMessage
	Float fFloat01 = 0.0
	Float fFloat02 = 0.0
	Float fFloat03 = 0.0
	Float fFloat04 = 0.0
	Float fFloat05 = 0.0
	Float fFloat06 = 0.0
	Float fFloat07 = 0.0
	Float fFloat08 = 0.0
	Float fFloat09 = 0.0
	Quest QuestRef = None ; Quest to display objective of
	Int iObjectiveID = -1 ; Objective of QuestRef to display
	Int iStageCheck = -1 ; If this stage of QuestRef is complete, the objective won't be displayed
EndStruct


; 1.0.8 - Structs for new MessageManager controller quest
Struct AliasMessage
	ReferenceAlias amAlias
	ObjectReference amObjectRef
	Message amMessage
	Bool bAutoClearAlias = true
	Float fFloat01 = 0.0
	Float fFloat02 = 0.0
	Float fFloat03 = 0.0
	Float fFloat04 = 0.0
	Float fFloat05 = 0.0
	Float fFloat06 = 0.0
	Float fFloat07 = 0.0
	Float fFloat08 = 0.0
	Float fFloat09 = 0.0
	Quest QuestRef = None ; Quest to display objective of
	Int iObjectiveID = -1 ; Objective of QuestRef to display
	Int iStageCheck = -1 ; If this stage of QuestRef is complete, the objective won't be displayed
EndStruct

; 1.0.8 - Structs for new MessageManager controller quest
Struct LocationMessage
	LocationAlias lmLocationAlias
	Location lmLocation
	Message lmMessage
	Bool bAutoClearAlias = true
	Float fFloat01 = 0.0
	Float fFloat02 = 0.0
	Float fFloat03 = 0.0
	Float fFloat04 = 0.0
	Float fFloat05 = 0.0
	Float fFloat06 = 0.0
	Float fFloat07 = 0.0
	Float fFloat08 = 0.0
	Float fFloat09 = 0.0
	Quest QuestRef = None ; Quest to display objective of
	Int iObjectiveID = -1 ; Objective of QuestRef to display
	Int iStageCheck = -1 ; If this stage of QuestRef is complete, the objective won't be displayed
EndStruct

; 1.0.8 - Structs for new MessageManager controller quest
Struct LocationAndAliasMessage
	LocationAlias lamLocationAlias
	Location lamLocation
	ReferenceAlias lamAlias
	ObjectReference lamObjectRef
	Message lamMessage
	Bool bAutoClearAlias = true
	Float fFloat01 = 0.0
	Float fFloat02 = 0.0
	Float fFloat03 = 0.0
	Float fFloat04 = 0.0
	Float fFloat05 = 0.0
	Float fFloat06 = 0.0
	Float fFloat07 = 0.0
	Float fFloat08 = 0.0
	Float fFloat09 = 0.0
	Quest QuestRef = None ; Quest to display objective of
	Int iObjectiveID = -1 ; Objective of QuestRef to display
	Int iStageCheck = -1 ; If this stage of QuestRef is complete, the objective won't be displayed
EndStruct


; 1.1.0 - Struct for new Control system
Struct FactionControl
	Faction FactionForm = None
	{ Faction taking control. [Optional] Either this, or iFormID + sPluginName have to be set. }
	Int iFormID = -1
	{ Decimal conversion of the last 6 digits of a forms Hex ID. [Optional] Either this + sPluginName, or FactionForm have to be set. }
	String sPluginName = ""
	{ Exact file name the form is from (ex. Fallout.esm). [Optional] Either this + iFormID, or FactionForm have to be set. }
	
	ActorBase Guards = None
	{ [Optional] Used, by the Assault system to spawn defending NPCs during assaults }
	
	ActorBase SettlerOverride = None
	{ Pool of NPCs to replace the spawning of settlers, these should have the WorkshopNPCScript }
	
	GlobalVariable ControlledSettlementCount
	{ Global to track the number of settlements this faction controls }
	
	Formlist FriendlyFactions = None
	{ Factions this settlement should maintain supply lines with and allow to stay in the settlement. }
	
	Formlist EnemyFactions = None
	{ Factions this settlement should cut supply lines with and force out of the settlement }
	
	Bool bTreatAllOtherFactionsAsEnemies = false
	{ If true, all factions outside of these lists will be considered enemies. If false, all factions outside of these lists will be considered friendly. }
EndStruct

; 1.1.0 - Struct for new assault system
Struct ReservedAssaultQuest
	int iReserveID = -1
	Quest kQuestRef
	Bool bCompleteEventFired = false
EndStruct


; 1.2.0 - Struct to link some form to a callback counter
Struct CallbackTracking
	int iCustomCallBackID = -1
	String sCustomCallbackID
	int iAwaitingCallbacks = 0
	int iCallbacksReceived = 0
	Form RelatedForm
EndStruct


; 1.2.0 - Struct to track power connections between SettlementLayout objects
Struct PowerConnectionMap
	Int iIndexA
	Int iIndexTypeA
	Int iIndexB
	Int iIndexTypeB
EndStruct

; 1.2.0 - Struct to store power connection data for an object so we only have to query each item once
Struct PowerConnectionLookup
	ObjectReference kPowereableRef
	Int iIndex
	Int iIndexType
EndStruct


; 1.2.0 - Struct to hold our HUD Progress Bars
Struct ProgressBar
	Form Source ; Used so we can check if the mod registering this was removed
	String sSourceID ; String the calling mod is using to identify the bar
	String sLabel = ""
	String sIconPath = ""
	Float fValue = 0.0
	Float fLastUpdated = 0.0 ; Holds Utility.GetCurrentGameTime of last update we can use this to monitor for bars that the caller failed to handle correctly and left running
	Int iBarIndex = -1 ; We need to track the index we are using
EndStruct


; 2.0.0 - Struct to hold GridSettings for grid item creation
struct GridSettings
	Float fMaxXDistance = 5000.0
	;{ Max distance to go in any direction on this axis }
	Float fMaxYDistance = 5000.0
	;{ Max distance to go in any direction on this axis }
	Float fMaxZDistance = 1000.0
	;{ Max distance to go in any direction on this axis }

	Int iMaxObjectsPerAxisX = 0
	;{ Max objects to create in each direction on this axis }
	Int iMaxObjectsPerAxisY = 0
	;{ Max objects to create in each direction on this axis }
	Int iMaxObjectsPerAxisZ = 0
	;{ Max objects to create in each direction on this axis }

	Bool bLinkAsWorkshopItems = false
	;{ If checked, and a workshop ref is found, these will be linked on WorkshopItemKeyword }
	Bool bGridWorkshopCellsOnly = true
	;{ If checked, cells that are part of a Settlement will be used as the boundary instead of the Max Distance or Max Object settings }
	Int iBoundaryOverlapCount = 1
	;{ Allow this many on each grid axis to go outside the established range }

	Float fScale = 1.0
	
	Float fInitialXOffset = 0.0
	;{ Offset from origin object to start the grid }
	Float fInitialYOffset = 0.0
	;{ Offset from origin object to start the grid }
	Float fInitialZOffset = 0.0
	;{ Offset from origin object to start the grid }

	Float fXSpacing = 512.0
	;{ Space between grid objects on this axis }
	Float fYSpacing = 512.0
	;{ Space between grid objects on this axis }
	Float fZSpacing = 512.0
	;{ Space between grid objects on this axis }

	Float fXRandomization = 0.0
    ; Random value +/- added to X coordinate
    Float fYRandomization = 0.0
    ; Random value +/- added to Y coordinate
    Float fZRandomization = 0.0
    ; Random value +/- added to Z coordinate

	Bool bGridPositiveX = true
	;{ Grid objects in positive direction on this axis }
	Bool bGridPositiveY = true
	;{ Grid objects in positive direction on this axis }
	Bool bGridPositiveZ = true
	;{ Grid objects in positive direction on this axis }

	Bool bGridNegativeX = true
	;{ Grid objects in negative direction on this axis }
	Bool bGridNegativeY = true
	;{ Grid objects in negative direction on this axis }
	Bool bGridNegativeZ = true
	;{ Grid objects in negative direction on this axis }
	
	Bool bAlignToGround = true
	;{ Grid objects will be placed Z units above the navmesh }
	
	Bool bPreventOverlapWhenAligningToGround = true
    ; When used with bAlignToGround, items will be deleted if they are too close together
    
    Bool bHideUntilCellUnloads = false
    
    Bool bRandomizeZRotation = false
endStruct


Struct TranslateTarget
	ObjectReference kTarget
	Float fPosX
	Float fPosY
	Float fPosZ
	Float fAngleX
	Float fAngleY
	Float fAngleZ
EndStruct


Struct TargetContainerItemCount
	Form Item
	Int iCount = 1		
	Keyword TargetContainerKeyword = None
EndStruct

Struct CustomVendor
	String sVendorID
	Faction VendorFaction
	Keyword VendorKeyword
	Formlist VendorContainerList
EndStruct


Struct FormCount
	Form CountedForm
	Int iCount
EndStruct


Struct StoryEventRequestStruct
	String StoryEventHash = ""
	
	Int ThreadID = -1
	
	WorkshopFramework:Library:StoryEventQuest Fulfiller = None
	
	Float Timeout = 0.0
EndStruct