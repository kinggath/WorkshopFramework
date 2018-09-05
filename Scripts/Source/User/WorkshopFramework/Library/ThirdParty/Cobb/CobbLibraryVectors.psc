Scriptname WorkshopFramework:Library:ThirdParty:Cobb:CobbLibraryVectors
{Library by David J Cobb for handling vectors}

Float[] Function VectorAdd(Float[] avA, Float[] avB) Global
{Adds two vectors together and returns the sum as a new vector.}
   Float[] vOut = new Float[3]
   vOut[0] = avA[0] + avB[0]
   vOut[1] = avA[1] + avB[1]
   vOut[2] = avA[2] + avB[2]
   return vOut
EndFunction

Float[] Function VectorSubtract(Float[] avA, Float[] avB) Global
{Subtracts one vector from another and returns the difference as a new vector.}
   Float[] vOut = new Float[3]
   vOut[0] = avA[0] - avB[0]
   vOut[1] = avA[1] - avB[1]
   vOut[2] = avA[2] - avB[2]
   return vOut
EndFunction

Float[] Function VectorMultiply(Float[] avA, Float afB) Global
{Multiplies a vector by a scalar and returns the result as a new vector.}
   Float[] vOut = new Float[3]
   vOut[0] = avA[0] * afB
   vOut[1] = avA[1] * afB
   vOut[2] = avA[2] * afB
   return vOut
EndFunction

Float[] Function VectorDivide(Float[] avA, Float afB) Global
{Divides a vector by a scalar and returns the result as a new vector.}
   Float[] vOut = new Float[3]
   If afB == 0
      Debug.TraceStack("VectorDivide: A script asked me to divide a vector by zero. I just returned a null vector instead.", 1)
      return vOut
   EndIf
   vOut[0] = avA[0] / afB
   vOut[1] = avA[1] / afB
   vOut[2] = avA[2] / afB
   return vOut
EndFunction

Float[] Function VectorProject(Float[] avA, Float[] avB) Global
{Projects one vector onto another, returning the result as a new vector.}
   Float[] vOut = new Float[3]
   vOut[0] = avB[0]
   vOut[1] = avB[1]
   vOut[2] = avB[2]
   Float scalar = VectorDotProduct(avA, avB) / VectorDotProduct(avB, avB)
   return VectorMultiply(vOut, scalar)
EndFunction

Float[] Function VectorCrossProduct(Float[] avA, Float[] avB) Global
{Takes the cross product of two vectors and returns the result as a new vector.}
   Float[] vOut = new Float[3]
   vOut[0] = avA[1] * avB[2] - avA[2] * avB[1]
   vOut[1] = avA[2] * avB[0] - avA[0] * avB[2]
   vOut[2] = avA[0] * avB[1] - avA[1] * avB[0]
   return vOut
EndFunction

Float Function VectorDotProduct(Float[] avA, Float[] avB) Global
{Returns the dot product of two vectors.}
   Float fOut = 0
   fOut += avA[0] * avB[0]
   fOut += avA[1] * avB[1]
   fOut += avA[2] * avB[2]
   return fOut
EndFunction

Float[] Function VectorNegate(Float[] av) Global
{Multiplies a vector by -1 and returns the result as a new vector.}
   Return VectorMultiply(av, -1)
EndFunction

Float Function VectorLength(Float[] av) Global
{Returns the length of a vector.}
   return Math.sqrt(av[0]*av[0] + av[1]*av[1] + av[2]*av[2])
EndFunction

Float[] Function VectorNormalize(Float[] av) Global
{Normalizes a vector and returns the result as a new vector.}
   Return VectorDivide(av, VectorLength(av))
EndFunction