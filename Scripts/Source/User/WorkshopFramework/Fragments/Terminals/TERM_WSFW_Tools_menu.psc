;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
Scriptname WorkshopFramework:Fragments:Terminals:TERM_WSFW_Tools_menu Extends Terminal Hidden Const

;BEGIN FRAGMENT Fragment_Terminal_01
Function Fragment_Terminal_01(ObjectReference akTerminalRef)
;BEGIN CODE
MainQuest.ClaimSettlement(None)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_02
Function Fragment_Terminal_02(ObjectReference akTerminalRef)
;BEGIN CODE
WorkshopScript thisWorkshop = WorkshopFramework:WSFW_API.GetNearestWorkshop(Game.GetPlayer())
if(thisWorkshop)
MainQuest.PresentManageSettlementMenu(thisWorkshop)
endif
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_03
Function Fragment_Terminal_03(ObjectReference akTerminalRef)
;BEGIN CODE
HUDFrameworkManager.ForceCloseAllProgressBars()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_04
Function Fragment_Terminal_04(ObjectReference akTerminalRef)
;BEGIN CODE
MainQuest.ClaimAllSettlements()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_05
Function Fragment_Terminal_05(ObjectReference akTerminalRef)
;BEGIN CODE
HUDFrameworkManager.ResetAllWidgets()
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

WorkshopFramework:MainQuest Property MainQuest Auto Const Mandatory
WorkshopFramework:HUDFrameworkManager Property HUDFrameworkManager Auto Const Mandatory
