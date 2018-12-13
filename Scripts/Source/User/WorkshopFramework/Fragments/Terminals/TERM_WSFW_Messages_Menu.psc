;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
Scriptname WorkshopFramework:Fragments:Terminals:TERM_WSFW_Messages_Menu Extends Terminal Hidden Const

;BEGIN FRAGMENT Fragment_Terminal_01
Function Fragment_Terminal_01(ObjectReference akTerminalRef)
;BEGIN CODE
MessageManager.DisplayNextQueuedMessage()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_02
Function Fragment_Terminal_02(ObjectReference akTerminalRef)
;BEGIN CODE
MessageManager.DisplayAllQueuedMessages()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_03
Function Fragment_Terminal_03(ObjectReference akTerminalRef)
;BEGIN CODE
MessageManager.ClearAllQueuedMessages()
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

WorkshopFramework:MessageManager Property MessageManager Auto Const Mandatory
