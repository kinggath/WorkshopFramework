Scriptname WorkshopFramework:Library:ThirdParty:Cobb:CobbLibraryRotations
{Library by David J Cobb for handling rotations}

Import WorkshopFramework:Library:ThirdParty:Cobb:CobbLibraryVectors

Float Function atan2(float y, float x) Global
   Float out = 0
   If y != 0
      out = Math.sqrt(x * x + y * y) - x
      out /= y
      out = Math.atan(out) * 2
   Else
      If x == 0
         return 0
      EndIf
      out = Math.atan(y / x)
      If x < 0
         out += 180
      EndIf
   EndIf
   return out
EndFunction

Float Function MatrixTrace(Float[] afMatrix) Global
{Returns the trace of a 3x3 rotation matrix.}
   return afMatrix[0] + afMatrix[4] + afMatrix[8]
EndFunction

Float[] Function EulerToAxisAngle(float afX, float afY, float afZ) Global
{Converts a set of Euler angles to axis angle, returning [x, y, z, angle]. The angle is in degrees. Tailored for Skyrim (extrinsic left-handed ZYX Euler).}
   ;
   ; Source for the math: http://www.vectoralgebra.info/axisangle.html
   ; Source for the math: http://www.vectoralgebra.info/euleranglesvector.html
   ;
   ; This has been tested and confirmed to work.
   ;
   Float[] fOutput = new Float[4]
   Float[] fMatrix = EulerToMatrix(afX, afY, afZ)
   return MatrixToAxisAngle(fMatrix)
EndFunction

Float[] Function EulerToMatrix(float afX, float afY, float afZ) Global
{Converts a set of Euler angles to a rotation matrix. Tailored for Skyrim (extrinsic left-handed ZYX Euler).

Matrix indices are:
0 1 2
3 4 5
6 7 8}
   ;
   ; Source for the math: http://www.vectoralgebra.info/eulermatrix.html
   ;
   Float[] fOutput = new Float[9]
   Float fSinX = Math.sin(afX)
   Float fSinY = Math.sin(afY)
   Float fSinZ = Math.sin(afZ)
   Float fCosX = Math.cos(afX)
   Float fCosY = Math.cos(afY)
   Float fCosZ = Math.cos(afZ)
   ;
   ; Build the matrix.
   ;
   fOutput[0] = fCosY * fCosZ				; 1,1
   fOutput[1] = fCosY * fSinZ				; 1,2
   fOutput[2] = -fSinY					; 1,3
   fOutput[3] = fSinX * fSinY * fCosZ - fCosX * fSinZ	; 2,1
   fOutput[4] = fSinX * fSinY * fSinZ + fCosX * fCosZ	; 2,2
   fOutput[5] = fSinX * fCosY				; 2,3
   fOutput[6] = fCosX * fSinY * fCosZ + fSinX * fSinZ	; 3,1
   fOutput[7] = fCosX * fSinY * fSinZ - fSinX * fCosZ	; 3,2
   fOutput[8] = fCosX * fCosY				; 3,3
   ;
   ; Done!
   ;
   return fOutput
EndFunction

Float[] Function EulerToQuaternion(float afX, float afY, float afZ) Global
{Converts a set of Euler angles to a quaternion (represented as [w, x, y, z]). Tailored for Skyrim (extrinsic left-handed ZYX Euler).}
   return AxisAngleToQuaternion(EulerToAxisAngle(afX, afY, afZ))
EndFunction

Float[] Function MatrixToAxisAngle(Float[] afMatrix) Global
{Converts a rotation matrix to axis angle, returning [x, y, z, angle]. The angle is in degrees. Tailored for Skyrim (extrinsic left-handed ZYX Euler).}
   Float[] fOutput = new Float[4]
   ;
   ; Determine the angle.
   ;
   Float fTrace = MatrixTrace(afMatrix)
   fOutput[3] = Math.acos((fTrace - 1) / 2)
   ;
   ; Determine the axis.
   ;
   fOutput[0] = afMatrix[7] - afMatrix[5]
   fOutput[1] = afMatrix[2] - afMatrix[6]
   fOutput[2] = afMatrix[3] - afMatrix[1]
   If fOutput[3] == 180
      ;
      ; A 180-degree angle tends to lead to a zero vector as our axis. 
      ; There seems to be a way to correct that...
      ;
      ; Source for the math: http://www.euclideanspace.com/maths/geometry/rotations/conversions/matrixToAngle/index.htm
      ; Source for the math: http://sourceforge.net/p/mjbworld/discussion/122133/thread/912b44f7
      ;
      fOutput[0] = Math.sqrt((afMatrix[0] + 1) / 2)
      fOutput[1] = Math.sqrt((afMatrix[4] + 1) / 2)
      fOutput[2] = Math.sqrt((afMatrix[8] + 1) / 2)
      ;
      ; We don't know the signs of the above terms. Per our second 
      ; source, we can start to figure that out by finding the largest 
      ; term, and then...
      ;
      Int iLargestIndex = 0
      Float fTemporary = fOutput[0]
      If fTemporary < fOutput[1]
         fTemporary = fOutput[1]
         iLargestIndex = 1
      EndIf
      If fTemporary < fOutput[2]
         fTemporary = fOutput[2]
         iLargestIndex = 2
      EndIf
      Int iIterator = 0
      While iIterator < 3
         Int iIndex = iLargestIndex * 3 + iIterator
         If iIterator != iLargestIndex
            ;
            ; Get the sign of the relevant matrix term.
            ;
            Int iSign = 0
            If afMatrix[iIndex]
               iSign = 1
               If afMatrix[iIndex] < 0
                  iSign = -1
               EndIf
            EndIf
            ;
            ; Result.
            ;
            fOutput[iIterator] = fOutput[iIterator] * iSign
         EndIf
         iIterator += 1
      EndWhile
   EndIf
   ;
   ; Normalize the axis.
   ;
   If VectorLength(fOutput) != 0
      Float[] fNormalized = VectorNormalize(fOutput)
      fOutput[0] = fNormalized[0]
      fOutput[1] = fNormalized[1]
      fOutput[2] = fNormalized[2]
   Else
      ;
      ; Edge-case caused a zero vector! Dumb fallback to the Z-axis.
      ;
      fOutput[0] = 0
      fOutput[1] = 0
      fOutput[2] = 1
   EndIf
   ;
   ; Done!
   ;
   return fOutput
EndFunction

Float[] Function MatrixToEuler(Float[] afMatrix) Global
{Converts a rotation matrix to Euler angles. Tailored for Skyrim (extrinsic left-handed ZYX Euler).}
   ;
   ; Source for the math: https://web.archive.org/web/20051124013711/http://skal.planet-d.net/demo/matrixfaq.htm#Q37
   ;
   ; The math there is righthanded, but it's easy to tailor it to 
   ; lefthanded if you have a handy-dandy reference like the one 
   ; at <http://www.vectoralgebra.info/eulermatrix.html>.
   ;
   Float[] fEuler = new Float[3]
   ; 
   ; We can immediately solve for Y, but we must round it to account 
   ; for imprecision that is sometimes introduced when we have 
   ; converted through other forms (e.g. axis-angle). fCYTest exists 
   ; solely as part of that accounting.
   ; 
   Float fY = Math.asin( (((-afMatrix[2] * 1000000) as int) as float) / 1000000 )
   Float fCY = Math.cos(fY)
   Float fCYTest = (((fCY * 100) as int) as float) / 100
   Float fTX
   Float fTY
   If fCY && fCY >= 0.00000011920929 && fCYTest
      ;Debug.Trace("MatrixToEuler: Y == " + fY + "; cos(Y) == " + fCY)
      fTX = afMatrix[8] / fCY
      fTY = afMatrix[5] / fCY
      fEuler[0] = atan2(fTY, fTX)   ; = atan(sinXcosY / cosXcosY) = atan(sin X / cos X)
      fTX = afMatrix[0] / fCY
      fTY = afMatrix[1] / fCY
      fEuler[2] = atan2(fTY, fTX)   ; = atan(cosYcosZ / cosYsinZ) = atan(sin Z / cos Z)
   Else
      ;Debug.Trace("MatrixToEuler: cos(Y) == 0. Taking another path...")
      ;
      ; We can't compute X and Z by using Y, because cos(Y) is zero. Therefore, 
      ; we have to compromise.
      ;
      ; We'll assume X to be zero, and dump the rest into Z.
      ;
      fEuler[0] = 0
      fTX = afMatrix[4]             ; Setting X to zero simplifies this element to: 0*sinY*sinZ + 1*cosZ
      fTY = afMatrix[3]             ; Setting X to zero simplifies this element to: 0*sinY*cosZ - 1*sinZ
      ;
      ; NOTE: Negating the result APPEARS to be necessary to account for our use of a 
      ; left-handed system versus the source's use of a right-handed system. However, 
      ; I arrived at that conclusion deductively, and I am not 100% certain of it.
      ;
      fEuler[2] = -atan2(fTY, fTX)   ; = atan(sin Z / cos Z)
   EndIf
   fEuler[1] = fY
   Return fEuler
EndFunction

Float[] Function MatrixToQuaternion(Float[] afMatrix) Global
   return AxisAngleToQuaternion(MatrixToAxisAngle(afMatrix)) ; TODO: Find a more direct method, if possible.
EndFunction

Float[] Function AxisAngleToEuler(Float[] afAxisAngle) Global
{Converts an axis-angle orientation to Euler angles in degrees. Tailored for Skyrim (extrinsic left-handed ZYX Euler).}
   return MatrixToEuler(AxisAngleToMatrix(afAxisAngle)) ; TODO: Find a more direct method, if possible.
EndFunction

Float[] Function AxisAngleToMatrix(Float[] afAxisAngle) Global
{Converts an axis-angle orientation to a rotation matrix. Tailored for Skyrim (extrinsic left-handed ZYX Euler).}
   ;
   ; Based on the math at: https://en.wikipedia.org/wiki/Rotation_matrix#Rotation_matrix_from_axis_and_angle
   ;
   ; The source does NOT state its Euler sequence, and it isn't entirely clear about its handedness 
   ; or whether or not it's extrinsic, either. Proceed with caution. It DOES line up with the other 
   ; sites I've been using, though.
   ;
   Float[] fMatrix = new Float[9]
   Float fOneMinusCos = (1 - Math.cos(afAxisAngle[3]))
   fMatrix[0] = Math.cos(afAxisAngle[3]) + Math.pow(afAxisAngle[0], 2) * fOneMinusCos
   fMatrix[1] = afAxisAngle[0] * afAxisAngle[1] * fOneMinusCos - afAxisAngle[2] * Math.sin(afAxisAngle[3])
   fMatrix[2] = afAxisAngle[0] * afAxisAngle[2] * fOneMinusCos + afAxisAngle[1] * Math.sin(afAxisAngle[3])
   fMatrix[3] = afAxisAngle[1] * afAxisAngle[0] * fOneMinusCos + afAxisAngle[2] * Math.sin(afAxisAngle[3])
   fMatrix[4] = Math.cos(afAxisAngle[3]) + Math.pow(afAxisAngle[1], 2) * fOneMinusCos
   fMatrix[5] = afAxisAngle[1] * afAxisAngle[2] * fOneMinusCos - afAxisAngle[0] * Math.sin(afAxisAngle[3])
   fMatrix[6] = afAxisAngle[2] * afAxisAngle[0] * fOneMinusCos - afAxisAngle[1] * Math.sin(afAxisAngle[3])
   fMatrix[7] = afAxisAngle[2] * afAxisAngle[1] * fOneMinusCos + afAxisAngle[0] * Math.sin(afAxisAngle[3])
   fMatrix[8] = Math.cos(afAxisAngle[3]) + Math.pow(afAxisAngle[2], 2) * fOneMinusCos
   return fMatrix
EndFunction

Float[] Function AxisAngleToQuaternion(Float[] afAxisAngle) Global
{Converts an axis-angle orientation to a unit quaternion (versor), returning [w, x, y, z].}
   ;
   ; Source for the math: https://en.wikipedia.org/w/index.php?title=Axis%E2%80%93angle_representation&oldid=608157500#Unit_quaternions
   ;
   Float[] qOutput = new Float[4]
   Float fHalfAngle = afAxisAngle[3] / 2
   qOutput[0] = Math.cos(fHalfAngle) 			; w
   qOutput[1] = Math.sin(fHalfAngle) * afAxisAngle[0] 	; x
   qOutput[2] = Math.sin(fHalfAngle) * afAxisAngle[1] 	; y
   qOutput[3] = Math.sin(fHalfAngle) * afAxisAngle[2] 	; z
   return qOutput
EndFunction

Float[] Function QuaternionToAxisAngle(Float[] aqQuat) Global
{Converts a unit quaternion (versor) to an axis-angle representation, returning [x, y, z, angle].}
   ;
   ; I can't get the math working for a direct conversion. We'll do it indirectly, instead.
   ;
   return MatrixToAxisAngle(QuaternionToMatrix(aqQuat))
EndFunction

Float[] Function QuaternionToEuler(Float[] aqQuat) Global
   return MatrixToEuler(QuaternionToMatrix(aqQuat))
EndFunction

Float[] Function QuaternionToMatrix(Float[] aqQuat) Global
{Converts a quaternion (as [w, x, y, z]) to a rotation matrix.

NOTE: I have not tested to see whether using a unit quaternion or a non-normalized quaternion makes any difference.}
   ;
   ; Source for the math: http://www.euclideanspace.com/maths/geometry/rotations/conversions/quaternionToMatrix/index.htm
   ;
   int W = 0
   int X = 1
   int Y = 2
   int Z = 3
   Float[] mOutput = new Float[9]
   mOutput[0] = 1 - 2*Math.pow(aqQuat[Y],2) - 2*Math.pow(aqQuat[Z],2)
   mOutput[1] = 2*aqQuat[X]*aqQuat[Y] - 2*aqQuat[Z]*aqQuat[W]
   mOutput[2] = 2*aqQuat[X]*aqQuat[Z] + 2*aqQuat[Y]*aqQuat[W]
   mOutput[3] = 2*aqQuat[X]*aqQuat[Y] + 2*aqQuat[Z]*aqQuat[W]
   mOutput[4] = 1 - 2*Math.pow(aqQuat[X],2) - 2*Math.pow(aqQuat[Z],2)
   mOutput[5] = 2*aqQuat[Y]*aqQuat[Z] - 2*aqQuat[X]*aqQuat[W]
   mOutput[6] = 2*aqQuat[X]*aqQuat[Z] - 2*aqQuat[Y]*aqQuat[W]
   mOutput[7] = 2*aqQuat[Y]*aqQuat[Z] + 2*aqQuat[X]*aqQuat[W]
   mOutput[8] = 1 - 2*Math.pow(aqQuat[X],2) - 2*Math.pow(aqQuat[Y],2)
   return mOutput
EndFunction

Float[] Function QuaternionAdd(Float[] aqA, Float[] aqB) Global
{Adds two quaternions, returning the result as a new quaternion.}
   Float[] qOut = new Float[4]
   qOut[0] = aqA[0] + aqB[0]
   qOut[1] = aqA[1] + aqB[1]
   qOut[2] = aqA[2] + aqB[2]
   qOut[3] = aqA[3] + aqB[3]
   return qOut
EndFunction

Float[] Function QuaternionMultiply(Float[] aqA, Float[] aqB) Global
{Returns as a new quaternion the Hamilton product of two quaternions (of the form [w, x, y, z]).}
   ;
   ; Source for the math: https://en.wikipedia.org/w/index.php?title=Quaternion&oldid=618007927#Hamilton_product
   ;
   Float[] qOut = new Float[4]
   qOut[0] = aqA[0]*aqB[0] - aqA[1]*aqB[1] - aqA[2]*aqB[2] - aqA[3]*aqB[3]
   qOut[1] = aqA[0]*aqB[1] + aqA[1]*aqB[0] + aqA[2]*aqB[3] - aqA[3]*aqB[2]
   qOut[2] = aqA[0]*aqB[2] - aqA[1]*aqB[3] + aqA[2]*aqB[0] + aqA[3]*aqB[1]
   qOut[3] = aqA[0]*aqB[3] + aqA[1]*aqB[2] - aqA[2]*aqB[1] + aqA[3]*aqB[0]
   return qOut
EndFunction

Float[] Function QuaternionConjugate(Float[] aq) Global
{UNTESTED. Returns as a new quaternion the conjugate of the given quaternion (of the form [w, x, y, z]).}
   Float[] qOut = new Float[4]
   Float[] v = new Float[3]
   v[1] = aq[0]
   v[2] = aq[1]
   v = VectorNegate(v)
   qOut[0] = aq[0]
   qOut[1] = v[1]
   qOut[2] = v[2]
   return qOut
EndFunction

Float[] Function MatrixMultiplyByColumn(Float[] amMatrix, Float[] avColumn) Global
{Multiplies a matrix by a column vector, and returns the resulting column vector.}
   Float[] vResult = new Float[3]
   vResult[0] = amMatrix[0]*avColumn[0] + amMatrix[1]*avColumn[1] + amMatrix[2]*avColumn[2]
   vResult[1] = amMatrix[3]*avColumn[0] + amMatrix[4]*avColumn[1] + amMatrix[5]*avColumn[2]
   vResult[2] = amMatrix[6]*avColumn[0] + amMatrix[7]*avColumn[1] + amMatrix[8]*avColumn[2]
   Return vResult
EndFunction

Float[] Function GetCoordinatesRelativeToBase(Float[] afParentPosition, Float[] afParentRotation, Float[] afOffsetPosition, Float[] afOffsetRotation) Global
{Given two sets of positions and rotations -- those of a parent object, and those of a child object relative to the parent -- this function returns an array of the form [XPos, YPos, ZPos, XAng, YAng, ZAng]. These are the positions and rotations of the child object relative to the world. In other words, this function exists as an alternative to MoveObjectRelativeToObject, allowing you to move objects however you wish.

Position code was inspired by GetPosXYZRotateAroundRef, a function authored by Chesko that can be found on the Creation Kit wiki.}
   ;
   ; CONSTRUCT POSITION.
   ;
   ; Child world position = parent rotation as matrix * child parent-relative position
   ;
   Float[] fOutput = new Float[6]
   Float[] fVector = new Float[3]
   Float[] mParentRotation = EulerToMatrix(afParentRotation[0], afParentRotation[1], afParentRotation[2])
   Float[] vChildPosition = MatrixMultiplyByColumn(mParentRotation, afOffsetPosition)
   vChildPosition[0] = vChildPosition[0] + afParentPosition[0]
   vChildPosition[1] = vChildPosition[1] + afParentPosition[1]
   vChildPosition[2] = vChildPosition[2] + afParentPosition[2]
   fOutput[0] = vChildPosition[0]
   fOutput[1] = vChildPosition[1]
   fOutput[2] = vChildPosition[2]
   ;
   ; CONSTRUCT ROTATION USING THIS LIBRARY:
   ;
   Float[] qParent = EulerToQuaternion(afParentRotation[0], afParentRotation[1], afParentRotation[2])
   Float[] qChild  = EulerToQuaternion(afOffsetRotation[0], afOffsetRotation[1], afOffsetRotation[2])
   Float[] qDone = QuaternionMultiply(qParent, qChild)
   Float[] eDone = QuaternionToEuler(qDone)
   ;
   ; Return result.
   ;
   fOutput[3] = eDone[0]
   fOutput[4] = eDone[1]
   fOutput[5] = eDone[2]
   Return fOutput
EndFunction

Function MoveObjectRelativeToObject(ObjectReference akChild, ObjectReference akParent, Float[] afPositionOffset, Float[] afRotationOffset) Global
{Moves the child reference relative to the parent reference. Position code is based on GetPosXYZRotateAroundRef, a function authored by Chesko that can be found on the Creation Kit wiki.}
   If !afPositionOffset || !afRotationOffset || afPositionOffset.length < 3 || afRotationOffset.length < 3
      return
   EndIf
   ;
   ; CONSTRUCT POSITION USING CHESKO'S METHOD.
   ;
   Float[] Angles = new Float[3]
   Float[] Origin = new Float[3]
   Float[] Output = new Float[3]
   Float[] Vector = new Float[3]

   Angles[0] = -akParent.GetAngleX()
   Angles[1] = -akParent.GetAngleY()
   Angles[2] = -akParent.GetAngleZ()

   Origin[0] = akParent.GetPositionX()
   Origin[1] = akParent.GetPositionY()
   Origin[2] = akParent.GetPositionZ()
   ;
   ; Apply Z-axis rotation matrix. (Modify the final X- and Y-axis positions based on the Z rotation.)
   ;
   Output[0] = (afPositionOffset[0] * Math.cos(Angles[2])) + (afPositionOffset[1] * Math.sin(-Angles[2]))
   Output[1] = (afPositionOffset[0] * Math.sin(Angles[2])) + (afPositionOffset[1] * Math.cos( Angles[2]))
   Output[2] = afPositionOffset[2]
   ;
   ; Apply Y-axis rotation matrix. (Modify the final X- and Z-axis positions based on the Y rotation.)
   ;
   Vector[0] = Output[0]
   Vector[2] = Output[2]
   Output[0] = (Vector[0] * Math.cos( Angles[1])) + (Vector[2] * Math.sin(Angles[1]))
   Output[2] = (Vector[0] * Math.sin(-Angles[1])) + (Vector[2] * Math.cos(Angles[1]))
   ;
   ; Apply X-axis rotation matrix. (Modify the final Y- and Z-axis positions based on the X rotation.)
   ;
   Vector[1] = Output[1]
   Vector[2] = Output[2]
   Output[1] = (Vector[1] * Math.cos(Angles[0])) + (Vector[2] * Math.sin(-Angles[0]))
   Output[2] = (Vector[1] * Math.sin(Angles[0])) + (Vector[2] * Math.cos( Angles[0]))
   ;
   ; Finalize coordinates.
   ;
   Output[0] = Output[0] + Origin[0]
   Output[1] = Output[1] + Origin[1]
   Output[2] = Output[2] + Origin[2]
   ;
   ; CONSTRUCT ROTATION USING THIS LIBRARY.
   ;
   Float[] qParent = EulerToQuaternion(akParent.GetAngleX(), akParent.GetAngleY(), akParent.GetAngleZ())
   Float[] qChild  = EulerToQuaternion(afRotationOffset[0], afRotationOffset[1], afRotationOffset[2])
   Float[] qDone = QuaternionMultiply(qParent, qChild)
   Float[] eDone = QuaternionToEuler(qDone)
   ;
   ; Move the child object.
   ;
   akChild.SetPosition(Output[0], Output[1], Output[2])
   akChild.SetAngle(eDone[0], eDone[1], eDone[2])
EndFunction