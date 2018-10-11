Scriptname WorkshopFramework:Library:DataStructures Hidden Const

Struct WorldObject
	Form ObjectForm
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
	ActorValue AVForm
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
	GlobalVariable GlobalForm
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
	Quest QuestForm
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
	Form BaseForm
	
	Int iFormID = -1
	{ Decimal conversion of the last 6 digits of a forms Hex ID. [Optional] Either this + sPluginName, or BaseForm have to be set. }
	String sPluginName = ""
	{ Exact file name the form is from (ex. Fallout.esm). [Optional] Either this + iFormID, or BaseForm have to be set. }
EndStruct


Struct LinkToMe
	ObjectReference kLinkToMe
	
	Keyword LinkWith
	{ [Optional] If this is not set, nor are iFormID + sPluginName, kLinkToMe will just be linked to the target without a keyword }
	
	Int iFormID = -1
	{ Decimal conversion of the last 6 digits of a forms Hex ID. [Optional] Either this + sPluginName, or BaseForm have to be set. }
	String sPluginName = ""
	{ Exact file name the form is from (ex. Fallout.esm). [Optional] Either this + iFormID, or BaseForm have to be set. }
EndStruct


Struct InjectableActorMap
	LeveledActor TargetLeveledActor
	FormList DefaultEntries
	FormList AdditionalEntries
	FormList RemovedDefaultEntries
EndStruct


Struct InjectableItemMap
	LeveledItem TargetLeveledItem
	FormList DefaultEntries
	FormList AdditionalEntries
	FormList RemovedDefaultEntries
EndStruct


Struct WorkshopTargetContainer
	Keyword TargetContainerKeyword
	Int iWorkshopID
EndStruct