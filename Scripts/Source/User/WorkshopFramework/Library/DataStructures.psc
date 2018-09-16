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
	{ ActorValue form to be set created. [Optional] Either this, or iFormID + sPluginName have to be set. }
	Int iFormID = -1
	{ Decimal conversion of the last 6 digits of a forms Hex ID. [Optional] Either this + sPluginName, or ObjectForm have to be set. }
	String sPluginName = ""
	{ Exact file name the form is from (ex. Fallout.esm). [Optional] Either this + iFormID, or ObjectForm have to be set. }
	
	Float fValue = 0.0
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