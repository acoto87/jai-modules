/* ********************************************************************************************
*
*   raymath v1.2 - Math functions to work with Vector3, Matrix and Quaternions
*
*   CONFIGURATION:
*
*   #define RAYMATH_IMPLEMENTATION
*       Generates the implementation of the library into the included file.
*       If not defined, the library is in header only mode and can be included in other headers
*       or source files without problems. But only ONE file should hold the implementation.
*
*   #define RAYMATH_HEADER_ONLY
*       Define static inline functions code, so #include header suffices for use.
*       This may use up lots of memory.
*
*   #define RAYMATH_STANDALONE
*       Avoid raylib.h header inclusion in this file.
*       Vector3 and Matrix data types are defined internally in raymath module.
*
*
*   LICENSE: zlib/libpng
*
*   Copyright (c) 2015-2021 Ramon Santamaria (@raysan5)
*
*   This software is provided "as-is", without any express or implied warranty. In no event
*   will the authors be held liable for any damages arising from the use of this software.
*
*   Permission is granted to anyone to use this software for any purpose, including commercial
*   applications, and to alter it and redistribute it freely, subject to the following restrictions:
*
*     1. The origin of this software must not be misrepresented; you must not claim that you
*     wrote the original software. If you use this software in a product, an acknowledgment
*     in the product documentation would be appreciated but is not required.
*
*     2. Altered source versions must be plainly marked as such, and must not be misrepresented
*     as being the original software.
*
*     3. This notice may not be removed or altered from any source distribution.
*
**********************************************************************************************/

//----------------------------------------------------------------------------------
// Defines and Macros
//----------------------------------------------------------------------------------
PI : float32 : 3.14159265358979323846;
DEG2RAD : float32 : (PI/180.0);
RAD2DEG : float32 : (180.0/PI);

//----------------------------------------------------------------------------------
// Types and Structures Definition
//----------------------------------------------------------------------------------

//----------------------------------------------------------------------------------
// Module Functions Definition - Utils math
//----------------------------------------------------------------------------------

// Clamp float value
Clamp :: (value: float32, min: float32, max: float32) -> float32 #foreign raylib;
// Calculate linear interpolation between two floats
Lerp :: (start: float32, end: float32, amount: float32) -> float32 #foreign raylib;
// Normalize input value within input range
Normalize :: (value: float32, start: float32, end: float32) -> float32 #foreign raylib;
// Remap input value within input range to output range
Remap :: (value: float32, inputStart: float32, inputEnd: float32, outputStart: float32, outputEnd: float32) -> float32 #foreign raylib;

//----------------------------------------------------------------------------------
// Module Functions Definition - Vector2 math
//----------------------------------------------------------------------------------

// Vector with components value 0.0f
Vector2Zero :: () -> Vector2 #foreign raylib;
// Vector with components value 1.0f
Vector2One :: () -> Vector2 #foreign raylib;
// Add two vectors (v1 + v2)
Vector2Add :: (v1: Vector2, v2: Vector2) -> Vector2 #foreign raylib;
// Add vector and float value
Vector2AddValue :: (v: Vector2, add: float32) -> Vector2 #foreign raylib;
// Subtract two vectors (v1 - v2)
Vector2Subtract :: (v1: Vector2, v2: Vector2) -> Vector2 #foreign raylib;
// Subtract vector by float value
Vector2SubtractValue :: (v: Vector2, sub: float32) -> Vector2 #foreign raylib;
// Calculate vector length
Vector2Length :: (v: Vector2) -> float32 #foreign raylib;
// Calculate vector square length
Vector2LengthSqr :: (v: Vector2) -> float32 #foreign raylib;
// Calculate two vectors dot product
Vector2DotProduct :: (v1: Vector2, v2: Vector2) -> float32 #foreign raylib;
// Calculate distance between two vectors
Vector2Distance :: (v1: Vector2, v2: Vector2) -> float32 #foreign raylib;
// Calculate angle from two vectors in X-axis
Vector2Angle :: (v1: Vector2, v2: Vector2) -> float32 #foreign raylib;
// Scale vector (multiply by value)
Vector2Scale :: (v: Vector2, scale: float32) -> Vector2 #foreign raylib;
// Multiply vector by vector
Vector2Multiply :: (v1: Vector2, v2: Vector2) -> Vector2 #foreign raylib;
// Negate vector
Vector2Negate :: (v: Vector2) -> Vector2 #foreign raylib;
// Divide vector by vector
Vector2Divide :: (v1: Vector2, v2: Vector2) -> Vector2 #foreign raylib;
// Normalize provided vector
Vector2Normalize :: (v: Vector2) -> Vector2 #foreign raylib;
// Calculate linear interpolation between two vectors
Vector2Lerp :: (v1: Vector2, v2: Vector2, amount: float32) -> Vector2 #foreign raylib;
// Calculate reflected vector to normal
Vector2Reflect :: (v: Vector2, normal: Vector2) -> Vector2 #foreign raylib;
// Rotate Vector by float in Degrees.
Vector2Rotate :: (v: Vector2, degs: float32) -> Vector2 #foreign raylib;
// Move Vector towards target
Vector2MoveTowards :: (v: Vector2, target: Vector2, maxDistance: float32) -> Vector2 #foreign raylib;

//----------------------------------------------------------------------------------
// Module Functions Definition - Vector3 math
//----------------------------------------------------------------------------------

// Vector with components value 0.0f
Vector3Zero :: () -> Vector3 #foreign raylib;
// Vector with components value 1.0f
Vector3One :: () -> Vector3 #foreign raylib;
// Add two vectors
Vector3Add :: (v1: Vector3, v2: Vector3) -> Vector3 #foreign raylib;
// Add vector and float value
Vector3AddValue :: (v: Vector3, add: float32) -> Vector3 #foreign raylib;
// Subtract two vectors
Vector3Subtract :: (v1: Vector3, v2: Vector3) -> Vector3 #foreign raylib;
// Subtract vector by float value
Vector3SubtractValue :: (v: Vector3, sub: float32) -> Vector3 #foreign raylib;
// Multiply vector by scalar
Vector3Scale :: (v: Vector3, scalar: float32) -> Vector3 #foreign raylib;
// Multiply vector by vector
Vector3Multiply :: (v1: Vector3, v2: Vector3) -> Vector3 #foreign raylib;
// Calculate two vectors cross product
Vector3CrossProduct :: (v1: Vector3, v2: Vector3) -> Vector3 #foreign raylib;
// Calculate one vector perpendicular vector
Vector3Perpendicular :: (v: Vector3) -> Vector3 #foreign raylib;
// Calculate vector length
Vector3Length :: (v: Vector3) -> float32 #foreign raylib;
// Calculate vector square length
Vector3LengthSqr :: (v: Vector3) -> float32 #foreign raylib;
// Calculate two vectors dot product
Vector3DotProduct :: (v1: Vector3, v2: Vector3) -> float32 #foreign raylib;
// Calculate distance between two vectors
Vector3Distance :: (v1: Vector3, v2: Vector3) -> float32 #foreign raylib;
// Negate provided vector (invert direction)
Vector3Negate :: (v: Vector3) -> Vector3 #foreign raylib;
// Divide vector by vector
Vector3Divide :: (v1: Vector3, v2: Vector3) -> Vector3 #foreign raylib;
// Normalize provided vector
Vector3Normalize :: (v: Vector3) -> Vector3 #foreign raylib;
// Orthonormalize provided vectors
// Makes vectors normalized and orthogonal to each other
// Gram-Schmidt function implementation
Vector3OrthoNormalize :: (v1: *Vector3, v2: *Vector3) #foreign raylib;
// Transforms a Vector3 by a given Matrix
Vector3Transform :: (v: Vector3, mat: Matrix) -> Vector3 #foreign raylib;
// Transform a vector by quaternion rotation
Vector3RotateByQuaternion :: (v: Vector3, q: Quaternion) -> Vector3 #foreign raylib;
// Calculate linear interpolation between two vectors
Vector3Lerp :: (v1: Vector3, v2: Vector3, amount: float32) -> Vector3 #foreign raylib;
// Calculate reflected vector to normal
Vector3Reflect :: (v: Vector3, normal: Vector3) -> Vector3 #foreign raylib;
// Return min value for each pair of components
Vector3Min :: (v1: Vector3, v2: Vector3) -> Vector3 #foreign raylib;
// Return max value for each pair of components
Vector3Max :: (v1: Vector3, v2: Vector3) -> Vector3 #foreign raylib;
// Compute barycenter coordinates (u, v, w) for point p with respect to triangle (a, b, c)
// NOTE: Assumes P is on the plane of the triangle
Vector3Barycenter :: (p: Vector3, a: Vector3, b: Vector3, c: Vector3) -> Vector3 #foreign raylib;
// Returns Vector3 as float array
Vector3ToFloatV :: (v: Vector3) -> [3] float32 #foreign raylib;

//----------------------------------------------------------------------------------
// Module Functions Definition - Matrix math
//----------------------------------------------------------------------------------

// Compute matrix determinant
MatrixDeterminant :: (mat: Matrix) -> float #foreign raylib;
// Returns the trace of the matrix (sum of the values along the diagonal)
MatrixTrace :: (mat: Matrix) -> float #foreign raylib;
// Transposes provided matrix
MatrixTranspose :: (mat: Matrix) -> Matrix #foreign raylib;
// Invert provided matrix
MatrixInvert :: (mat: Matrix) -> Matrix #foreign raylib;
// Normalize provided matrix
MatrixNormalize :: (mat: Matrix) -> Matrix #foreign raylib;
// Returns identity matrix
MatrixIdentity :: () -> Matrix #foreign raylib;
// Add two matrices
MatrixAdd :: (left: Matrix, right: Matrix) -> Matrix #foreign raylib;
// Subtract two matrices (left - right)
MatrixSubtract :: (left: Matrix, right: Matrix) -> Matrix #foreign raylib;
// Returns two matrix multiplication
// NOTE: When multiplying matrices... the order matters!
MatrixMultiply :: (left: Matrix, right: Matrix) -> Matrix #foreign raylib;
// Returns translation matrix
MatrixTranslate :: (x: float32, y: float32, z: float32) -> Matrix #foreign raylib;
// Create rotation matrix from axis and angle
// NOTE: Angle should be provided in radians
MatrixRotate :: (axis: Vector3, angle: float32) -> Matrix #foreign raylib;
// Returns x-rotation matrix (angle in radians)
MatrixRotateX :: (angle: float32) -> Matrix #foreign raylib;
// Returns y-rotation matrix (angle in radians)
MatrixRotateY :: (angle: float32) -> Matrix #foreign raylib;
// Returns z-rotation matrix (angle in radians)
MatrixRotateZ :: (angle: float32) -> Matrix #foreign raylib;
// Returns xyz-rotation matrix (angles in radians)
MatrixRotateXYZ :: (ang: Vector3) -> Matrix #foreign raylib;
// Returns zyx-rotation matrix (angles in radians)
MatrixRotateZYX :: (ang: Vector3) -> Matrix #foreign raylib;
// Returns scaling matrix
MatrixScale :: (x: float32, y: float32, z: float32) -> Matrix #foreign raylib;
// Returns perspective projection matrix
MatrixFrustum :: (left: float64, right: float64, bottom: float64, top: float64, near: float64, far: float64) -> Matrix #foreign raylib;
// Returns perspective projection matrix
// NOTE: Angle should be provided in radians
MatrixPerspective :: (fovy: float64, aspect: float64, near: float64, far: float64) -> Matrix #foreign raylib;
// Returns orthographic projection matrix
MatrixOrtho :: (left: float64, right: float64, bottom: float64, top: float64, near: float64, far: float64) -> Matrix #foreign raylib;
// Returns camera look-at matrix (view matrix)
MatrixLookAt :: (eye: Vector3, target: Vector3, up: Vector3) -> Matrix #foreign raylib;
// Returns float array of matrix data
MatrixToFloatV :: (mat: Matrix) -> [16] float32 #foreign raylib;

//----------------------------------------------------------------------------------
// Module Functions Definition - Quaternion math
//----------------------------------------------------------------------------------

// Add two quaternions
QuaternionAdd :: (q1: Quaternion, q2: Quaternion) -> Quaternion #foreign raylib;
// Add quaternion and float value
QuaternionAddValue :: (q: Quaternion, add: float32) -> Quaternion #foreign raylib;
// Subtract two quaternions
QuaternionSubtract :: (q1: Quaternion, q2: Quaternion) -> Quaternion #foreign raylib;
// Subtract quaternion and float value
QuaternionSubtractValue :: (q: Quaternion, sub: float32) -> Quaternion #foreign raylib;
// Returns identity quaternion
QuaternionIdentity :: () -> Quaternion #foreign raylib;
// Computes the length of a quaternion
QuaternionLength :: (q: Quaternion) -> float #foreign raylib;
// Normalize provided quaternion
QuaternionNormalize :: (q: Quaternion) -> Quaternion #foreign raylib;
// Invert provided quaternion
QuaternionInvert :: (q: Quaternion) -> Quaternion #foreign raylib;
// Calculate two quaternion multiplication
QuaternionMultiply :: (q1: Quaternion, q2: Quaternion) -> Quaternion #foreign raylib;
// Scale quaternion by float value
QuaternionScale :: (q: Quaternion, mul: float32) -> Quaternion #foreign raylib;
// Divide two quaternions
QuaternionDivide :: (q1: Quaternion, q2: Quaternion) -> Quaternion #foreign raylib;
// Calculate linear interpolation between two quaternions
QuaternionLerp :: (q1: Quaternion, q2: Quaternion, amount: float32) -> Quaternion #foreign raylib;
// Calculate slerp-optimized interpolation between two quaternions
QuaternionNlerp :: (q1: Quaternion, q2: Quaternion, amount: float32) -> Quaternion #foreign raylib;
// Calculates spherical linear interpolation between two quaternions
QuaternionSlerp :: (q1: Quaternion, q2: Quaternion, amount: float32) -> Quaternion #foreign raylib;
// Calculate quaternion based on the rotation from one vector to another
QuaternionFromVector3ToVector3 :: (from: Vector3, to: Vector3) -> Quaternion #foreign raylib;
// Returns a quaternion for a given rotation matrix
QuaternionFromMatrix :: (mat: Matrix) -> Quaternion #foreign raylib;
// Returns a matrix for a given quaternion
QuaternionToMatrix :: (q: Quaternion) -> Matrix #foreign raylib;
// Returns rotation quaternion for an angle and axis
// NOTE: angle must be provided in radians
QuaternionFromAxisAngle :: (axis: Vector3, angle: float32) -> Quaternion #foreign raylib;
// Returns the rotation angle and axis for a given quaternion
QuaternionToAxisAngle :: (q: Quaternion, outAxis: *Vector3, outAngle: *float32) #foreign raylib;
// Returns the quaternion equivalent to Euler angles
// NOTE: Rotation order is ZYX
QuaternionFromEuler :: (pitch: float32, yaw: float32, roll: float32) -> Quaternion #foreign raylib;
// Return the Euler angles equivalent to quaternion (roll, pitch, yaw)
// NOTE: Angles are returned in a Vector3 struct in degrees
QuaternionToEuler :: (q: Quaternion) -> Vector3 #foreign raylib;
// Transform a quaternion given a transformation matrix
QuaternionTransform :: (q: Quaternion, mat: Matrix) -> Quaternion #foreign raylib;
// Projects a Vector3 from screen space into object space
Vector3Unproject :: (source: Vector3, projection: Matrix, view: Matrix) -> Vector3 #foreign raylib;

#scope_file

#if OS == .WINDOWS {
	raylib :: #foreign_library "lib/3.7.0/win64/raylib";
}
