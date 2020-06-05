;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
Scriptname WorkshopFramework:Fragments:Terminals:TERM_WSFW_Options_Menu_DoorM_0101E2D8 Extends Terminal Hidden Const

;BEGIN FRAGMENT Fragment_Terminal_01
Function Fragment_Terminal_01(ObjectReference akTerminalRef)
;BEGIN CODE
WSFW_Setting_DoorManagement.SetValueInt(0)
DoorManager.SettingsUpdated()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_02
Function Fragment_Terminal_02(ObjectReference akTerminalRef)
;BEGIN CODE
WSFW_Setting_DoorManagement.SetValueInt(1)
DoorManager.SettingsUpdated()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_03
Function Fragment_Terminal_03(ObjectReference akTerminalRef)
;BEGIN CODE
WSFW_Setting_DoorManagement_AutoCloseOpenedByPlayer.SetValueInt(0)
DoorManager.SettingsUpdated()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_04
Function Fragment_Terminal_04(ObjectReference akTerminalRef)
;BEGIN CODE
WSFW_Setting_DoorManagement_AutoCloseOpenedByPlayer.SetValueInt(1)
DoorManager.SettingsUpdated()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_05
Function Fragment_Terminal_05(ObjectReference akTerminalRef)
;BEGIN CODE
WSFW_Setting_DoorManagement_AutoCloseOpenedByNPCs.SetValueInt(0)
DoorManager.SettingsUpdated()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_06
Function Fragment_Terminal_06(ObjectReference akTerminalRef)
;BEGIN CODE
WSFW_Setting_DoorManagement_AutoCloseOpenedByNPCs.SetValueInt(1)
DoorManager.SettingsUpdated()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_07
Function Fragment_Terminal_07(ObjectReference akTerminalRef)
;BEGIN CODE
WSFW_Setting_DoorManagement_AutoOpenOnWSEnter.SetValueInt(0)
DoorManager.SettingsUpdated()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_08
Function Fragment_Terminal_08(ObjectReference akTerminalRef)
;BEGIN CODE
WSFW_Setting_DoorManagement_AutoOpenOnWSEnter.SetValueInt(1)
DoorManager.SettingsUpdated()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_09
Function Fragment_Terminal_09(ObjectReference akTerminalRef)
;BEGIN CODE
WSFW_Setting_DoorManagement_AutoCloseOnWSExit.SetValueInt(0)
DoorManager.SettingsUpdated()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_10
Function Fragment_Terminal_10(ObjectReference akTerminalRef)
;BEGIN CODE
WSFW_Setting_DoorManagement_AutoCloseOnWSExit.SetValueInt(1)
DoorManager.SettingsUpdated()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_11
Function Fragment_Terminal_11(ObjectReference akTerminalRef)
;BEGIN CODE
WSFW_Setting_DoorManagement_AutoCloseTime.SetValueInt(10)
DoorManager.SettingsUpdated()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_12
Function Fragment_Terminal_12(ObjectReference akTerminalRef)
;BEGIN CODE
WSFW_Setting_DoorManagement_AutoCloseTime.SetValueInt(15)
DoorManager.SettingsUpdated()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_13
Function Fragment_Terminal_13(ObjectReference akTerminalRef)
;BEGIN CODE
WSFW_Setting_DoorManagement_AutoCloseTime.SetValueInt(5)
DoorManager.SettingsUpdated()
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment


WorkshopFramework:Quests:DoorManager Property DoorManager Auto Const Mandatory

GlobalVariable Property WSFW_Setting_DoorManagement Auto Const Mandatory

GlobalVariable Property WSFW_Setting_DoorManagement_AutoCloseOnWSExit Auto Const Mandatory

GlobalVariable Property WSFW_Setting_DoorManagement_AutoCloseOpenedByNPCs Auto Const Mandatory

GlobalVariable Property WSFW_Setting_DoorManagement_AutoCloseOpenedByPlayer Auto Const Mandatory

GlobalVariable Property WSFW_Setting_DoorManagement_AutoCloseTime Auto Const Mandatory

GlobalVariable Property WSFW_Setting_DoorManagement_AutoOpenOnWSEnter Auto Const Mandatory
