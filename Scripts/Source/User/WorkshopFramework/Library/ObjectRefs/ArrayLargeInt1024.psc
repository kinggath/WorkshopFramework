; ---------------------------------------------
; WorkshopFramework:Library:ObjectRefs:ArrayLargeInt1024.psc - by kinggath
; ---------------------------------------------
; Reusage Rights ------------------------------
; You are free to use this script or portions of it in your own mods, provided you give me credit in your description and maintain this section of comments in any released source code (which includes the IMPORTED SCRIPT CREDIT section to give credit to anyone in the associated Import scripts below).
; 
; Warning !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
; Do not directly recompile this script for redistribution without first renaming it to avoid compatibility issues with the mod this came from.
; 
; IMPORTED SCRIPT CREDITS
; N/A
; ---------------------------------------------

Scriptname WorkshopFramework:Library:ObjectRefs:ArrayLargeInt1024 extends WorkshopFramework:Library:ObjectRefs:LockableObjectRef

import WorkshopFramework:Library:UtilityFunctions

; ------------------------------------------
; Consts
; ------------------------------------------

Int Property TOTALARRAYS = 8 autoReadOnly
Int Property MAXENTRIES = 1024 autoReadOnly
Int Property NULL_Int = -2147483646 autoReadOnly ; Our version of NULL for integers - otherwise we can't store 0 (NOTE: The number we chose is 1 shy of the max represented integer)

; ------------------------------------------
; Editor Properties
; ------------------------------------------

Bool Property bAutoReUseOnceFull = false Auto Const
{ If checked, once the arrays are full, they will be used from the beginning. This makes the array faster, and you don't have to manage removal of entries you are finished with - but data will be overwritten during operation. }

; ------------------------------------------
; Vars
; ------------------------------------------

Int[] Array0
Int[] Array1
Int[] Array2
Int[] Array3
Int[] Array4
Int[] Array5
Int[] Array6
Int[] Array7

Int iNextIndex = -1
Int Property NextIndex
	Int Function Get()
		if(iNextIndex + 1 >= MAXENTRIES)
			iNextIndex = 0
		else
			iNextIndex += 1
		endif
		
		return iNextIndex
	EndFunction
EndProperty

; ------------------------------------------
; Events
; ------------------------------------------

Event OnInit()
	; Init arrays
	ClearAll()
EndEvent

; ------------------------------------------
; Functions
; ------------------------------------------

Int Function GetEditLock()
	int iLockKey = GetLock()
	if(iLockKey <= GENERICLOCK_KEY_NONE)
        ModTrace("Unable to get lock!", 2)
		
        return -1
    endif
	
	return iLockKey
endFunction

Function ClearEditLock(Int aiLockKey)
	; Release Edit Lock
	if(ReleaseLock(aiLockKey) < GENERICLOCK_KEY_NONE )
        ModTrace("Failed to release lock " + aiLockKey + "!", 2)
    endif	
EndFunction

Bool Function IsNull(Int aiCheck)
	if(aiCheck == NULL_Int)
		return true
	endif
	
	return false
EndFunction

Bool Function StoreElement(Int akStoreMe, Int aiIndex = -1)
	int iLockKey = GetEditLock()
	if(FindElement(akStoreMe, abGetEditLock = false) > -1)
		Debug.MessageBox("Attempting to store duplicate value.")
	endif
	
	Int[] StoreHere
	
	if(aiIndex < 0 && bAutoReUseOnceFull)
		aiIndex = NextIndex
	endif
	
	if(aiIndex >= MAXENTRIES)
		ClearEditLock(iLockKey)
		
		return false
	elseif(aiIndex < 0)
		; Find next available spot
			; First check lengths - if an array has length < 128, we can just store there
		if(Array0.Length < 128)
			StoreHere = Array0
			aiIndex = Array0.Length
		elseif(Array1.Length < 128)
			StoreHere = Array1
			aiIndex = Array1.Length
		elseif(Array2.Length < 128)
			StoreHere = Array2
			aiIndex = Array2.Length
		elseif(Array3.Length < 128)
			StoreHere = Array3
			aiIndex = Array3.Length
		elseif(Array4.Length < 128)
			StoreHere = Array4
			aiIndex = Array4.Length
		elseif(Array5.Length < 128)
			StoreHere = Array5
			aiIndex = Array5.Length
		elseif(Array6.Length < 128)
			StoreHere = Array6
			aiIndex = Array6.Length
		elseif(Array7.Length < 128)
			StoreHere = Array7
			aiIndex = Array7.Length
		else
			; Find next available spot
			aiIndex = Array0.Find(NULL_Int)
			
			if(aiIndex > -1)
				StoreHere = Array0
			else
				aiIndex = Array1.Find(NULL_Int)
			
				if(aiIndex > -1)
					StoreHere = Array1
				else
					aiIndex = Array2.Find(NULL_Int)
				
					if(aiIndex > -1)
						StoreHere = Array2
					else
						aiIndex = Array3.Find(NULL_Int)
					
						if(aiIndex > -1)
							StoreHere = Array3
						else
							aiIndex = Array4.Find(NULL_Int)
						
							if(aiIndex > -1)
								StoreHere = Array4
							else
								aiIndex = Array5.Find(NULL_Int)
							
								if(aiIndex > -1)
									StoreHere = Array5
								else
									aiIndex = Array6.Find(NULL_Int)
								
									if(aiIndex > -1)
										StoreHere = Array6
									else
										aiIndex = Array7.Find(NULL_Int)
									
										if(aiIndex > -1)
											StoreHere = Array7
										else
											ClearEditLock(iLockKey)
											
											return false ; All arrays full
										endif
									endif
								endif
							endif
						endif
					endif
				endif
			endif
		endif
	else
		if(aiIndex < 128)
			StoreHere = Array0
		elseif(aiIndex < 256)
			aiIndex -= 128
			StoreHere = Array1
		elseif(aiIndex < 384)
			aiIndex -= 256
			StoreHere = Array2
		elseif(aiIndex < 512)
			aiIndex -= 384
			StoreHere = Array3
		elseif(aiIndex < 640)
			aiIndex -= 512
			StoreHere = Array4
		elseif(aiIndex < 768)
			aiIndex -= 640
			StoreHere = Array5
		elseif(aiIndex < 896)
			aiIndex -= 768
			StoreHere = Array6
		elseif(aiIndex < MAXENTRIES)
			aiIndex -= 896
			StoreHere = Array7
		else 
			ClearEditLock(iLockKey)
			
			return false
		endif
	endif
	
	if(aiIndex < 0)
		ClearEditLock(iLockKey)
		
		return false
	endif
	
	int i = StoreHere.Length
	while(i < aiIndex + 1)
		StoreHere.Add(NULL_Int)
		
		i += 1
	endWhile
	
	StoreHere[aiIndex] = akStoreMe
	
	ClearEditLock(iLockKey)
	
	return true
EndFunction


Function RemoveElementByIndex(Int aiIndex)
	int iLockKey = GetEditLock()
	
	if(aiIndex < 0 || aiIndex >= MAXENTRIES)
		ClearEditLock(iLockKey)
		
		return
	endif
	
	if(aiIndex < 128)
		Array0.Remove(aiIndex)
	elseif(aiIndex < 256)
		aiIndex -= 128
		Array1.Remove(aiIndex)
	elseif(aiIndex < 384)
		aiIndex -= 256
		Array2.Remove(aiIndex)
	elseif(aiIndex < 512)
		aiIndex -= 384
		Array3.Remove(aiIndex)
	elseif(aiIndex < 640)
		aiIndex -= 512
		Array4.Remove(aiIndex)
	elseif(aiIndex < 768)
		aiIndex -= 640
		Array5.Remove(aiIndex)
	elseif(aiIndex < 896)
		aiIndex -= 768
		Array6.Remove(aiIndex)
	elseif(aiIndex < MAXENTRIES)
		aiIndex -= 896
		Array7.Remove(aiIndex)
	endif
	
	ClearEditLock(iLockKey)
EndFunction

Function RemoveElement(Int akInt)
	int iLockKey = GetEditLock()
	
	int iIndex = Array0.Find(akInt)
			
	if(iIndex > -1)
		Array0.Remove(iIndex)
	else
		iIndex = Array1.Find(akInt)
	
		if(iIndex > -1)
			Array1.Remove(iIndex)
		else
			iIndex = Array2.Find(akInt)
		
			if(iIndex > -1)
				Array2.Remove(iIndex)
			else
				iIndex = Array3.Find(akInt)
			
				if(iIndex > -1)
					Array3.Remove(iIndex)
				else
					iIndex = Array4.Find(akInt)
				
					if(iIndex > -1)
						Array4.Remove(iIndex)
					else
						iIndex = Array5.Find(akInt)
					
						if(iIndex > -1)
							Array5.Remove(iIndex)
						else
							iIndex = Array6.Find(akInt)
						
							if(iIndex > -1)
								Array6.Remove(iIndex)
							else
								iIndex = Array7.Find(akInt)
							
								if(iIndex > -1)
									Array7.Remove(iIndex)
								endif
							endif
						endif
					endif
				endif
			endif
		endif
	endif
	
	ClearEditLock(iLockKey)
EndFunction

Function ClearAll()
	; Init arrays
	Array0 = new Int[0]
	Array1 = new Int[0]
	Array2 = new Int[0]
	Array3 = new Int[0]
	Array4 = new Int[0]
	Array5 = new Int[0]
	Array6 = new Int[0]
	Array7 = new Int[0]
EndFunction

Int Function FindElement(Int aiFindMe, Bool abClear = false, Bool abGetEditLock = true)
	int iLockKey = -1
	
	if(abGetEditLock)
		iLockKey = GetEditLock()
	endif
	
	; For temporary arrays, "clearing" the value after finding it will avoid the issue of race conditions that can be caused by removing entries by index
	;Debug.Trace("Searching Array0 for " + aiFindMe + ", Current Array Contents: " + Array0)
	int iIndex = Array0.Find(aiFindMe)
	
	if(iIndex >= 0)
		if(abClear)
			Array0[iIndex] = NULL_Int
		endif
		
		ClearEditLock(iLockKey)
		
		return iIndex
	else
		iIndex = Array1.Find(aiFindMe)
	
		if(iIndex >= 0)
			if(abClear)
				Array1[iIndex] = NULL_Int
			endif
		
			ClearEditLock(iLockKey)
			
			return iIndex + 128
		else
			iIndex = Array2.Find(aiFindMe)
	
			if(iIndex >= 0)
				if(abClear)
					Array2[iIndex] = NULL_Int
				endif
				
				ClearEditLock(iLockKey)
				
				return iIndex + 256
			else
				iIndex = Array3.Find(aiFindMe)
	
				if(iIndex >= 0)
					if(abClear)
						Array3[iIndex] = NULL_Int
					endif
					
					ClearEditLock(iLockKey)
					
					return iIndex + 384
				else
					iIndex = Array4.Find(aiFindMe)
	
					if(iIndex >= 0)
						if(abClear)
							Array4[iIndex] = NULL_Int
						endif
						
						ClearEditLock(iLockKey)
						
						return iIndex + 512
					else
						iIndex = Array5.Find(aiFindMe)
	
						if(iIndex >= 0)
							if(abClear)
								Array5[iIndex] = NULL_Int
							endif
							
							ClearEditLock(iLockKey)
							
							return iIndex + 640
						else
							iIndex = Array6.Find(aiFindMe)
	
							if(iIndex > 6)
								if(abClear)
									Array6[iIndex] = NULL_Int
								endif
								
								ClearEditLock(iLockKey)
								
								return iIndex + 768
							else
								iIndex = Array7.Find(aiFindMe)
	
								if(iIndex >= 0)
									if(abClear)
										Array7[iIndex] = NULL_Int
									endif
									
									ClearEditLock(iLockKey)
									
									return iIndex + 896
								else
									ClearEditLock(iLockKey)
									
									return -1
								endif
							endif
						endif
					endif
				endif
			endif
		endif
	endif
EndFunction

Int Function GetElement(Int aiIndex)
	int iLockKey = GetEditLock()
	
	if(aiIndex < 0)
		ClearEditLock(iLockKey)
		
		return NULL_Int
	endif
	
	if(aiIndex < 128)
		ClearEditLock(iLockKey)
		
		return Array0[aiIndex]
	elseif(aiIndex < 256)
		ClearEditLock(iLockKey)
		
		return Array1[aiIndex - 128]
	elseif(aiIndex < 384)
		ClearEditLock(iLockKey)
		
		return Array2[aiIndex - 256]
	elseif(aiIndex < 512)
		ClearEditLock(iLockKey)
		
		return Array3[aiIndex - 384]
	elseif(aiIndex < 640)
		ClearEditLock(iLockKey)
		
		return Array4[aiIndex - 512]
	elseif(aiIndex < 768)
		ClearEditLock(iLockKey)
		
		return Array5[aiIndex - 640]
	elseif(aiIndex < 896)
		ClearEditLock(iLockKey)
		
		return Array6[aiIndex - 768]
	elseif(aiIndex < MAXENTRIES)
		ClearEditLock(iLockKey)
		
		return Array7[aiIndex - 896]
	endif
EndFunction