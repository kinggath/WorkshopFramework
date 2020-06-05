; ---------------------------------------------
; Scriptname WorkshopFramework:Forms:RealInventoryProxyItem.psc - by kinggath
; ---------------------------------------------
; Reusage Rights ------------------------------
; You are free to use this script or portions of it in your own mods, provided you give me credit in your description and maintain this section of comments in any released source code (which includes the IMPORTED SCRIPT CREDIT section to give credit to anyone in the associated Import scripts below.
; 
; Warning !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
; Do not directly recompile this script for redistribution without first renaming it to avoid compatibility issues issues with the mod this came from.
; 
; IMPORTED SCRIPT CREDIT
; N/A
; ---------------------------------------------

Scriptname WorkshopFramework:Forms:RealInventoryProxyItem extends Form Const

import WorkshopFramework:Library:DataStructures

UniversalForm Property DisplayVersion Auto Const
{ If set, the form set here will be placed by the Real Inventory Display system instead of the item this script is attached to when found for sale. }