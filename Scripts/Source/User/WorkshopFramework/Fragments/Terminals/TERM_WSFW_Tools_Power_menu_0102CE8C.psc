;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
Scriptname WorkshopFramework:Fragments:Terminals:TERM_WSFW_Tools_Power_menu_0102CE8C Extends Terminal Hidden Const

;BEGIN FRAGMENT Fragment_Terminal_01
Function Fragment_Terminal_01(ObjectReference akTerminalRef)
;BEGIN CODE
int iConfirm = WSFW_PowerGridDestroyConfirm.Show()

if(iConfirm == 1)
   Bool bSuccess = F4SEManager.WSFWID_ResetPowerGrid(None)

  WSFW_PowerGridFixDestroyComplete.Show()
endif
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_02
Function Fragment_Terminal_02(ObjectReference akTerminalRef)
;BEGIN CODE
WSFW_PowerGridScanStarted.Show()

Bool bSuccess = F4SEManager.WSFWID_ScanPowerGrid(akWorkshopRef = None)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_03
Function Fragment_Terminal_03(ObjectReference akTerminalRef)
;BEGIN CODE
WorkshopObjectManager.ForcePowerTransmission(None)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_04
Function Fragment_Terminal_04(ObjectReference akTerminalRef)
;BEGIN CODE
Bool bSuccess = F4SEManager.WSFWID_CheckAndFixPowerGrid(akWorkshopRef = None, abFixAndScan = true, abResetIfFixFails = false)

if(bSuccess)
RepairResultsMessage.Show()
else
RepairFailMessage.Show()
endif
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

WorkshopFramework:WorkshopObjectManager Property WorkshopObjectManager Auto Const Mandatory
WorkshopFramework:F4SEManager Property F4SEManager Auto Const Mandatory
Message Property RepairResultsMessage Auto Const Mandatory

Message Property RepairFailMessage Auto Const Mandatory

Message Property WSFW_PowerGridDestroyConfirm Auto Const Mandatory

Message Property WSFW_PowerGridFixDestroyComplete Auto Const Mandatory

Message Property WSFW_PowerGridScanStarted Auto Const Mandatory
