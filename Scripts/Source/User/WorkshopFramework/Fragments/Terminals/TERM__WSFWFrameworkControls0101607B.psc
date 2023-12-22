;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
Scriptname WorkshopFramework:Fragments:Terminals:TERM__WSFWFrameworkControls0101607B Extends Terminal Hidden Const

;BEGIN FRAGMENT Fragment_Terminal_01
Function Fragment_Terminal_01(ObjectReference akTerminalRef)
;BEGIN CODE
WSFW_Setting_Import_FauxPowerItems.SetValueInt(0)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_02
Function Fragment_Terminal_02(ObjectReference akTerminalRef)
;BEGIN CODE
WSFW_Setting_Import_FauxPowerItems.SetValueInt(1)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_03
Function Fragment_Terminal_03(ObjectReference akTerminalRef)
;BEGIN CODE
WSFW_Setting_Import_HandleLootablesMethod.SetValueInt(0)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_04
Function Fragment_Terminal_04(ObjectReference akTerminalRef)
;BEGIN CODE
WSFW_Setting_Import_HandleLootablesMethod.SetValueInt(1)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_05
Function Fragment_Terminal_05(ObjectReference akTerminalRef)
;BEGIN CODE
WSFW_Setting_Import_SpawnNPCs.SetValueInt(0)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_06
Function Fragment_Terminal_06(ObjectReference akTerminalRef)
;BEGIN CODE
WSFW_Setting_Import_SpawnNPCs.SetValueInt(1)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_07
Function Fragment_Terminal_07(ObjectReference akTerminalRef)
;BEGIN CODE
WSFW_Setting_Import_SpawnPowerArmor.SetValueInt(0)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_08
Function Fragment_Terminal_08(ObjectReference akTerminalRef)
;BEGIN CODE
WSFW_Setting_Import_SpawnPowerArmor.SetValueInt(1)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_09
Function Fragment_Terminal_09(ObjectReference akTerminalRef)
;BEGIN CODE
WSFW_Setting_Export_IncludeAnimals.SetValueInt(0)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_10
Function Fragment_Terminal_10(ObjectReference akTerminalRef)
;BEGIN CODE
WSFW_Setting_Export_IncludeAnimals.SetValueInt(1)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_11
Function Fragment_Terminal_11(ObjectReference akTerminalRef)
;BEGIN CODE
WSFW_Setting_Export_IncludePowerArmor.SetValueInt(0)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_12
Function Fragment_Terminal_12(ObjectReference akTerminalRef)
;BEGIN CODE
WSFW_Setting_Export_IncludePowerArmor.SetValueInt(1)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_13
Function Fragment_Terminal_13(ObjectReference akTerminalRef)
;BEGIN CODE
WSFW_Setting_Export_IncludeVanillaScrap.SetValueInt(0)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_14
Function Fragment_Terminal_14(ObjectReference akTerminalRef)
;BEGIN CODE
WSFW_Setting_Export_IncludeVanillaScrap.SetValueInt(1)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_15
Function Fragment_Terminal_15(ObjectReference akTerminalRef)
;BEGIN CODE
WSFW_Setting_Import_F4SEPower.SetValueInt(0)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_16
Function Fragment_Terminal_16(ObjectReference akTerminalRef)
;BEGIN CODE
WSFW_Setting_Import_F4SEPower.SetValueInt(1)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_17
Function Fragment_Terminal_17(ObjectReference akTerminalRef)
;BEGIN CODE
WSFW_Setting_AutomaticallyUnhideInvisibleWorkshopObjects.SetValueInt(0)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_18
Function Fragment_Terminal_18(ObjectReference akTerminalRef)
;BEGIN CODE
WSFW_Setting_AutomaticallyUnhideInvisibleWorkshopObjects.SetValueInt(1)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_19
Function Fragment_Terminal_19(ObjectReference akTerminalRef)
;BEGIN CODE
WSFW_Setting_AutoRepairPowerGrids.SetValueInt(0)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_20
Function Fragment_Terminal_20(ObjectReference akTerminalRef)
;BEGIN CODE
WSFW_Setting_AutoRepairPowerGrids.SetValueInt(1)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_21
Function Fragment_Terminal_21(ObjectReference akTerminalRef)
;BEGIN CODE
WSFW_Setting_AutoResetCorruptPowerGrid.SetValueInt(0)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_22
Function Fragment_Terminal_22(ObjectReference akTerminalRef)
;BEGIN CODE
WSFW_Setting_AutoResetCorruptPowerGrid.SetValueInt(1)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_23
Function Fragment_Terminal_23(ObjectReference akTerminalRef)
;BEGIN CODE
PersistenceManager.EnablePersistenceManagement(false)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_24
Function Fragment_Terminal_24(ObjectReference akTerminalRef)
;BEGIN CODE
PersistenceManager.EnablePersistenceManagement(true)
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

GlobalVariable Property WSFW_AlternateActivation_Workshop Auto Const Mandatory

GlobalVariable Property WSFW_Setting_Import_FauxPowerItems Auto Const Mandatory

GlobalVariable Property WSFW_Setting_Export_IncludeAnimals Auto Const Mandatory

GlobalVariable Property WSFW_Setting_Export_IncludePowerArmor Auto Const Mandatory

GlobalVariable Property WSFW_Setting_Export_IncludeVanillaScrap Auto Const Mandatory

GlobalVariable Property WSFW_Setting_Import_HandleLootablesMethod Auto Const Mandatory

GlobalVariable Property WSFW_Setting_Import_SpawnNPCs Auto Const Mandatory

GlobalVariable Property WSFW_Setting_Import_SpawnPowerArmor Auto Const Mandatory

GlobalVariable Property WSFW_Setting_Import_F4SEPower Auto Const Mandatory

GlobalVariable Property WSFW_Setting_AutomaticallyUnhideInvisibleWorkshopObjects Auto Const Mandatory

GlobalVariable Property WSFW_Setting_AutoRepairPowerGrids Auto Const Mandatory

GlobalVariable Property WSFW_Setting_AutoResetCorruptPowerGrid Auto Const Mandatory
GlobalVariable Property WSFW_Setting_PersistWorkshopResourceObjects Auto Const Mandatory
WorkshopFramework:PersistenceManager Property PersistenceManager Auto Const Mandatory
