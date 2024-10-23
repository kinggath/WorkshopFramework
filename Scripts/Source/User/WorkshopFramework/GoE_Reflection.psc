ScriptName WorkshopFramework:GoE_Reflection Const Hidden
{
    Script to access Garden of Eden debugging functions without causing other scripts to crash if it's not present
}


;; Note, GoE encodes version X.Y as XY; eg: v8.1 = 81; v14.7 = 147; etc
Int Function GoE_Version() Global
    Return Utility.CallGlobalFunction( "GardenOfEden", "GetVersionRelease", None ) As Int
EndFunction
Bool Function GoE_VersionTest( Int aiVersion ) Global
    Return GoE_Version() >= aiVersion
EndFunction


String[] Function GoE_GetPersistentPromoters( ObjectReference akReference, Bool abAddZeroXPrefix = false, Bool abRemove28a = True ) Global
    If( GoE_Version() < 184 )
        Debug.Trace( "WorkshopFramework:GoE_Reflection.GoE_GetPersistentPromoters() :: Garden of Eden v18.4 or later required" )
        Return None
    EndIf
    If( akReference == None )
        Return None
    EndIf
    Return __GoE_GetPersistentPromoters( akReference, abAddZeroXPrefix, abRemove28a)
EndFunction


String[] Function __GoE_GetPersistentPromoters( ObjectReference akReference, Bool abAddZeroXPrefix = false, Bool abRemove28a = True ) Global
    String[] lsReasons = GardenOfEden2.GetPersistentPromoters( akReference, abAddZeroXPrefix )
    
    Int liIndex = lsReasons.Length
    If( liIndex > 0 )
        While( liIndex > 0 )
            liIndex -= 1
            If( abRemove28a )   ;; Remove the hardcoded master object that is holding a reference to everything
                If( lsReasons[ liIndex ] == "28a" )\
                ||( lsReasons[ liIndex ] == "0x28a" )
                    lsReasons.Remove( liIndex, 1 )
                EndIf
            EndIf
        EndWhile
    EndIf
    
    If( lsReasons.Length == 0 )
        Return None
    EndIf
    Return lsReasons
EndFunction


;; cgf "WorkshopFramework:GoE_Reflection.GoE_LogPersistentRefs"
function GoE_LogPersistentRefs() Global
    If( GoE_Version() < 184 )
        Debug.Trace( "WorkshopFramework:GoE_Reflection.GoE_LogPersistentRefs() :: Garden of Eden v18.4 or later required" )
        Return
    EndIf
    __GoE_LogPersistentRefs()
EndFunction

function __GoE_LogPersistentRefs() Global
    GardenOfEden2.LogPersistentRefs( -1, -1, False, \
        None, None, None, \
        False, False, None, \
        -1, -1, -1.0, None, \
        False, 0 )
EndFunction



