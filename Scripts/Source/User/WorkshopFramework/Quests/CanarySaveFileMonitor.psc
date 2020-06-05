Scriptname WorkshopFramework:Quests:CanarySaveFileMonitor extends Quest

String sThisFullScriptName = "WorkshopFramework:Quests:CanarySaveFileMonitor" Const
; Inside the quotes, type the full script name including the folder you created. So if you put this in Fallout 4\Data\Scripts\Source\User\MyMod\ and you kept the script name the same, your full script name would be MyMod:CanarySaveFileMonitor (this should be the same thing you put in the Scriptname line at the top of this script!)



int Property iSaveFileMonitor Auto Hidden ; Do not mess with ever - this is used by Canary to track data loss

Event OnQuestInit()
    CheckForCanary()

   RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
EndEvent

Event Actor.OnPlayerLoadGame(Actor akSender)
    CheckForCanary()
endEvent

Function CheckForCanary()
    if(Game.IsPluginInstalled("CanarySaveFileMonitor.esl"))
        Var[] kArgs = new Var[2]
        kArgs[0] = Self as Quest
        kArgs[1] = sThisFullScriptName
        
        Utility.CallGlobalFunction("Canary:API", "MonitorForDataLoss", kArgs)
	endif
EndFunction