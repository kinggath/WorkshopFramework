;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
Scriptname WorkshopFramework:Fragments:Perks:PRKF_WSFW_ActivationsPerk_01015131 Extends Perk Hidden Const

;BEGIN FRAGMENT Fragment_Entry_00
Function Fragment_Entry_00(ObjectReference akTargetRef, Actor akActor)
;BEGIN CODE
WSFW_Main.PresentManageSettlementMenu(akTargetRef as WorkshopScript)
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

WorkshopFramework:MainQuest Property WSFW_Main Auto Const Mandatory
