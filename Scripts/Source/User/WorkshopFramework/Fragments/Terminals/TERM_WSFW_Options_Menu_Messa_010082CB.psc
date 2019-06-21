;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
Scriptname WorkshopFramework:Fragments:Terminals:TERM_WSFW_Options_Menu_Messa_010082CB Extends Terminal Hidden Const

;BEGIN FRAGMENT Fragment_Terminal_01
Function Fragment_Terminal_01(ObjectReference akTerminalRef)
;BEGIN CODE
Setting_AutoPlayMessages.SetValue(0)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_02
Function Fragment_Terminal_02(ObjectReference akTerminalRef)
;BEGIN CODE
Setting_AutoPlayMessages.SetValue(1.0)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_03
Function Fragment_Terminal_03(ObjectReference akTerminalRef)
;BEGIN CODE
Setting_SuppressMessages_DuringCombat.SetValue(1.0)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_04
Function Fragment_Terminal_04(ObjectReference akTerminalRef)
;BEGIN CODE
Setting_SuppressMessages_DuringCombat.SetValue(0.0)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_07
Function Fragment_Terminal_07(ObjectReference akTerminalRef)
;BEGIN CODE
Setting_SuppressMessages_DuringDialogue.SetValue(1.0)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_08
Function Fragment_Terminal_08(ObjectReference akTerminalRef)
;BEGIN CODE
Setting_SuppressMessages_DuringDialogue.SetValue(0.0)
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

GlobalVariable Property Setting_AutoPlayMessages Auto Const Mandatory
GlobalVariable Property Setting_SuppressAllMessages Auto Const Mandatory
GlobalVariable Property Setting_SuppressMessages_DuringCombat Auto Const Mandatory
GlobalVariable Property Setting_SuppressMessages_DuringDialogue Auto Const Mandatory
