;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
Scriptname Fragments:Quests:QF_WorkshopFeralGhoulAttack0_00097CC7 Extends Quest Hidden Const

;BEGIN FRAGMENT Fragment_Stage_0010_Item_00
Function Fragment_Stage_0010_Item_00()
;BEGIN AUTOCAST TYPE REScript
Quest __temp = self as Quest
REScript kmyQuest = __temp as REScript
;END AUTOCAST
;BEGIN CODE
kmyquest.Startup()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0010_Item_01
Function Fragment_Stage_0010_Item_01()
;BEGIN AUTOCAST TYPE WorkshopAttackScript
Quest __temp = self as Quest
WorkshopAttackScript kmyQuest = __temp as WorkshopAttackScript
;END AUTOCAST
;BEGIN CODE
; run timer to expire attack if player doesn't go to location
kmyQuest.StartTimerGameTime(24.0)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0015_Item_00
Function Fragment_Stage_0015_Item_00()
;BEGIN AUTOCAST TYPE WorkshopAttackScript
Quest __temp = self as Quest
WorkshopAttackScript kmyQuest = __temp as WorkshopAttackScript
;END AUTOCAST
;BEGIN CODE
kmyQuest.TryToStartAttack()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0020_Item_00
Function Fragment_Stage_0020_Item_00()
;BEGIN AUTOCAST TYPE REScript
Quest __temp = self as Quest
REScript kmyQuest = __temp as REScript
;END AUTOCAST
;BEGIN CODE
; reset timer to shorter
CancelTimerGameTime()
workshopScript workshopRef = Alias_Workshop.GetRef() as WorkshopScript
if workshopRef.Is3DLoaded() == false && workshopRef.OwnedByPlayer
	; WSFW - 1.0.8
	WorkshopFramework:MessageManager MessageManager = Game.GetFormFromFile(0x000092C5, "WorkshopFramework.esm") as WorkshopFramework:MessageManager
	
	MessageManager.ShowMessage(WorkshopRaiderAttack01Message, akQuestRef = kmyQuest, aiObjectiveID = 10, aiStageCheck = 100)
	;WorkshopRaiderAttack01Message.Show()
	;SetObjectiveDisplayed(10)
	; set workshop alert value
	Alias_SettlementSpokesman.TryToSetValue(kmyQuest.REParent.WorkshopActorAlert, 1)
	Alias_SettlementNPCs.SetValue(kmyQuest.REParent.WorkshopActorAlert, 1)

else
	; now quest should shutdown when everything unloads
	kmyQuest.StopQuestWhenAliasesUnloaded = true
endif
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0020_Item_01
Function Fragment_Stage_0020_Item_01()
;BEGIN AUTOCAST TYPE WorkshopAttackScript
Quest __temp = self as Quest
WorkshopAttackScript kmyQuest = __temp as WorkshopAttackScript
;END AUTOCAST
;BEGIN CODE
kmyQuest.StartAttack()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0050_Item_00
Function Fragment_Stage_0050_Item_00()
;BEGIN AUTOCAST TYPE WorkshopAttackScript
Quest __temp = self as Quest
WorkshopAttackScript kmyQuest = __temp as WorkshopAttackScript
;END AUTOCAST
;BEGIN CODE
; put everyone in "grateful" faction
kmyQuest.AddToGratefulFaction(Alias_SettlementSpokesman, Alias_SettlementNPCs, attackFactionValue = 4)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0100_Item_00
Function Fragment_Stage_0100_Item_00()
;BEGIN AUTOCAST TYPE REScript
Quest __temp = self as Quest
REScript kmyQuest = __temp as REScript
;END AUTOCAST
;BEGIN CODE
; failsafe - make sure registered for cleanup
kmyQuest.RegisterForCustomEvent(kmyQuest.REParent, "RECheckForCleanup")
SetObjectiveCompleted(10)
; clear workshop alert value
Alias_SettlementSpokesman.TryToSetValue(kmyQuest.REParent.WorkshopActorAlert, 0)
Alias_SettlementNPCs.SetValue(kmyQuest.REParent.WorkshopActorAlert, 0)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0200_Item_00
Function Fragment_Stage_0200_Item_00()
;BEGIN AUTOCAST TYPE WorkshopAttackScript
Quest __temp = self as Quest
WorkshopAttackScript kmyQuest = __temp as WorkshopAttackScript
;END AUTOCAST
;BEGIN CODE
; remove everyone from the "grateful" faction
kmyQuest.AddToGratefulFaction(Alias_SettlementSpokesman, Alias_SettlementNPCs, false)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_0400_Item_00
Function Fragment_Stage_0400_Item_00()
;BEGIN CODE
; Make this workshop player owned
(Alias_Workshop.GetRef() as WorkshopScript).SetOwnedByPlayer(true)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Stage_1000_Item_00
Function Fragment_Stage_1000_Item_00()
;BEGIN AUTOCAST TYPE WorkshopAttackScript
Quest __temp = self as Quest
WorkshopAttackScript kmyQuest = __temp as WorkshopAttackScript
;END AUTOCAST
;BEGIN CODE
; check to see if attack needs to be resolved by script
; WSFW - 1.0.8
WorkshopFramework:MessageManager MessageManager = Game.GetFormFromFile(0x000092C5, "WorkshopFramework.esm") as WorkshopFramework:MessageManager

if kmyQuest.CheckResolveAttack()
	if IsObjectiveDisplayed(10)
		; WSFW - 1.0.8
		MessageManager.ShowMessage(WorkshopFeralGhoulAttack01LoseMessage)
		;WorkshopFeralGhoulAttack01LoseMessage.Show()
	endif
	FailAllObjectives()
else
	if IsObjectiveDisplayed(10) && IsObjectiveCompleted(10) == false
		; WSFW - 1.0.8
		MessageManager.ShowMessage(WorkshopFeralGhoulAttack01WinMessage)
		;WorkshopFeralGhoulAttack01WinMessage.Show()
	endif
	CompleteAllObjectives()
endif
; remove everyone from the "grateful" faction
kmyQuest.AddToGratefulFaction(Alias_SettlementSpokesman, Alias_SettlementNPCs, false)
; clear workshop alert value
Alias_SettlementSpokesman.TryToSetValue(kmyQuest.REParent.WorkshopActorAlert, 0)
Alias_SettlementNPCs.SetValue(kmyQuest.REParent.WorkshopActorAlert, 0)
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

ReferenceAlias Property Alias_Workshop Auto Const

ReferenceAlias Property Alias_SettlementSpokesman Auto Const

RefCollectionAlias Property Alias_SettlementNPCs Auto Const

Message Property WorkshopRaiderAttack01Message Auto Const

Message Property WorkshopFeralGhoulAttack01LoseMessage Auto Const Mandatory

Message Property WorkshopFeralGhoulAttack01WinMessage Auto Const Mandatory
