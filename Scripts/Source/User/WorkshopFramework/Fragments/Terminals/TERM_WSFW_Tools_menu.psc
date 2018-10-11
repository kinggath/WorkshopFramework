;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
Scriptname WorkshopFramework:Fragments:Terminals:TERM_WSFW_Tools_menu Extends Terminal Hidden Const

;BEGIN FRAGMENT Fragment_Terminal_01
Function Fragment_Terminal_01(ObjectReference akTerminalRef)
;BEGIN CODE
MainQuest.ClaimSettlement(None)
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

WorkshopFramework:MainQuest Property MainQuest Auto Const Mandatory
