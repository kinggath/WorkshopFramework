Scriptname WSWF_InjectionScript extends Quest

Formlist Property MyBrahminList Auto Const
Formlist Property MySettlerList Auto Const
Formlist Property MySettlerGuardList Auto Const

GlobalVariable Property MyModVersion Auto Const Mandatory
{ Setup a global with a version number. Then anytime you update your mod and change one of these lists, be sure to update that global so this InjectionScript runs again to add any additional entries }

String sWorkshopFrameworkPlugin = "WorkshopFramework.esm" Const
int iFormID_InjectionManager = 0x000091E3 Const
int iFormID_BrahminLA = 0x000091EA Const
int iFormID_SettlerLA = 0x000091E8 Const
int iFormID_SettlerGuardLA = 0x000091E9 Const

Float fLastInjectedVersion = 0.0
Bool bInjectionProcessing = false

Event Actor.OnPlayerLoadGame(Actor akSenderRef)
	ProcessInjection()
EndEvent

Event OnQuestInit()
	RegisterForRemoteEvent(Game.GetPlayer() as Actor, "OnPlayerLoadGame")
	ProcessInjection()
EndEvent


Function ProcessInjection()
	if(bInjectionProcessing || (MyModVersion && fLastInjectedVersion*10000 == MyModVersion.GetValue()*10000))
		return
	endif
	
	bInjectionProcessing = true
	
	if(Game.IsPluginInstalled(sWorkshopFrameworkPlugin))
		Quest WSFW_InjectionManager = Game.GetFormFromFile(iFormID_InjectionManager, sWorkshopFrameworkPlugin) as Quest
		
		if(WSFW_InjectionManager)
			ScriptObject asInjectionManager = WSFW_InjectionManager.CastAs("WorkshopFramework:InjectionManager")
			LeveledActor WSFW_BrahminLA = Game.GetFormFromFile(iFormID_BrahminLA, sWorkshopFrameworkPlugin) as LeveledActor
			LeveledActor WSFW_SettlerLA = Game.GetFormFromFile(iFormID_SettlerLA, sWorkshopFrameworkPlugin) as LeveledActor			
			LeveledActor WSFW_SettlerGuardLA = Game.GetFormFromFile(iFormID_SettlerGuardLA, sWorkshopFrameworkPlugin) as LeveledActor
			
			if(MyBrahminList && MyBrahminList.GetSize() > 0 && WSFW_BrahminLA)
				InjectFormList(asInjectionManager, MyBrahminList, WSFW_BrahminLA)
			endif			
			
			if(MySettlerList && MySettlerList.GetSize() > 0 && WSFW_SettlerLA)
				InjectFormList(asInjectionManager, MySettlerList, WSFW_SettlerLA)
			endif			
			
			if(MySettlerGuardList && MySettlerGuardList.GetSize() > 0 && WSFW_SettlerGuardLA)
				InjectFormList(asInjectionManager, MySettlerGuardList, WSFW_SettlerGuardLA)
			endif
			
			fLastInjectedVersion = MyModVersion.GetValue()
		endif
	endif
	
	bInjectionProcessing = false
EndFunction


Function InjectFormList(ScriptObject aInjectionManager, Formlist aFormlist, Form aTargetLL)
	if( ! aInjectionManager)
		return
	endif
	
	Bool bLeveledActor = false
	if(aTargetLL as LeveledActor)
		bLeveledActor = true
	endif
	
	int i = 0
	while(i < aFormlist.GetSize())
		if(bLeveledActor)
			LeveledActor thisLA = aFormlist.GetAt(i) as LeveledActor
			if(thisLA)
				Var[] kArgs = new Var[2]
				kArgs[0] = aTargetLL
				kArgs[1] = thisLA
				aInjectionManager.CallFunction("AddToList", kArgs)
			endif
		else
			LeveledItem thisLI = aFormlist.GetAt(i) as LeveledItem
			if(thisLI)
				Var[] kArgs = new Var[2]
				kArgs[0] = aTargetLL
				kArgs[1] = thisLI
				aInjectionManager.CallFunction("AddToList", kArgs)
			endif
		endif
		
		i += 1
	endWhile
EndFunction