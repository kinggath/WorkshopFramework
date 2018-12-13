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


Struct ActorValueSet
	ActorValue AVForm = None
	{ ActorValue form. [Optional] Either this, or iFormID + sPluginName have to be set. }
	Int iFormID = -1
	{ Decimal conversion of the last 6 digits of a forms Hex ID. [Optional] Either this + sPluginName, or ObjectForm have to be set. }
	String sPluginName = ""
	{ Exact file name the form is from (ex. Fallout.esm). [Optional] Either this + iFormID, or ObjectForm have to be set. }
	
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
	{ Decimal conversion of the last 6 digits of a forms Hex ID. [Optional] Either this + sPluginName, or ObjectForm have to be set. }
	String sPluginName = ""
	{ Exact file name the form is from (ex. Fallout.esm). [Optional] Either this + iFormID, or ObjectForm have to be set. }
	
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
	{ Decimal conversion of the last 6 digits of a forms Hex ID. [Optional] Either this + sPluginName, or ObjectForm have to be set. }
	String sPluginName = ""
	{ Exact file name the form is from (ex. Fallout.esm). [Optional] Either this + iFormID, or ObjectForm have to be set. }
	
	Int iStage = 0
	{ The stage that must be complete on this quest }
	Bool bNotDoneCheck = false
	{ If set to true, this will instead look to see that this stage is NOT complete }
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