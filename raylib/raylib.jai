/* ********************************************************************************************
*
*   raylib - A simple and easy-to-use library to enjoy videogames programming (www.raylib.com)
*
*   FEATURES:
*       - NO external dependencies, all required libraries included with raylib
*       - Multiplatform: Windows, Linux, FreeBSD, OpenBSD, NetBSD, DragonFly,
*                        MacOS, Haiku, UWP, Android, Raspberry Pi, HTML5.
*       - Written in plain C code (C99) in PascalCase/camelCase notation
*       - Hardware accelerated with OpenGL (1.1, 2.1, 3.3 or ES2 - choose at compile)
*       - Unique OpenGL abstraction layer (usable as standalone module): [rlgl]
*       - Multiple Fonts formats supported (TTF, XNA fonts, AngelCode fonts)
*       - Outstanding texture formats support, including compressed formats (DXT, ETC, ASTC)
*       - Full 3d support for 3d Shapes, Models, Billboards, Heightmaps and more!
*       - Flexible Materials system, supporting classic maps and PBR maps
*       - Animated 3D models supported (skeletal bones animation) (IQM, glTF)
*       - Shaders support, including Model shaders and Postprocessing shaders
*       - Powerful math module for Vector, Matrix and Quaternion operations: [raymath]
*       - Audio loading and playing with streaming support (WAV, OGG, MP3, FLAC, XM, MOD)
*       - VR stereo rendering with configurable HMD device parameters
*       - Bindings to multiple programming languages available!
*
*   NOTES:
*       One default Font is loaded on InitWindow()->LoadFontDefault() [core, text]
*       One default Texture2D is loaded on rlglInit() [rlgl] (OpenGL 3.3 or ES2)
*       One default Shader is loaded on rlglInit()->rlLoadShaderDefault() [rlgl] (OpenGL 3.3 or ES2)
*       One default RenderBatch is loaded on rlglInit()->rlLoadRenderBatch() [rlgl] (OpenGL 3.3 or ES2)
*
*   DEPENDENCIES (included):
*       [core] rglfw (Camilla Löwy - github.com/glfw/glfw) for window/context management and input (PLATFORM_DESKTOP)
*       [rlgl] glad (David Herberth - github.com/Dav1dde/glad) for OpenGL 3.3 extensions loading (PLATFORM_DESKTOP)
*       [raudio] miniaudio (David Reid - github.com/dr-soft/miniaudio) for audio device/context management
*
*   OPTIONAL DEPENDENCIES (included):
*       [core] msf_gif (Miles Fogle) for GIF recording
*       [core] sinfl (Micha Mettke) for DEFLATE decompression algorythm
*       [core] sdefl (Micha Mettke) for DEFLATE compression algorythm
*       [textures] stb_image (Sean Barret) for images loading (BMP, TGA, PNG, JPEG, HDR...)
*       [textures] stb_image_write (Sean Barret) for image writting (BMP, TGA, PNG, JPG)
*       [textures] stb_image_resize (Sean Barret) for image resizing algorithms
*       [textures] stb_perlin (Sean Barret) for Perlin noise image generation
*       [text] stb_truetype (Sean Barret) for ttf fonts loading
*       [text] stb_rect_pack (Sean Barret) for rectangles packing
*       [models] par_shapes (Philip Rideout) for parametric 3d shapes generation
*       [models] tinyobj_loader_c (Syoyo Fujita) for models loading (OBJ, MTL)
*       [models] cgltf (Johannes Kuhlmann) for models loading (glTF)
*       [raudio] dr_wav (David Reid) for WAV audio file loading
*       [raudio] dr_flac (David Reid) for FLAC audio file loading
*       [raudio] dr_mp3 (David Reid) for MP3 audio file loading
*       [raudio] stb_vorbis (Sean Barret) for OGG audio loading
*       [raudio] jar_xm (Joshua Reisenauer) for XM audio module loading
*       [raudio] jar_mod (Joshua Reisenauer) for MOD audio module loading
*
*
*   LICENSE: zlib/libpng
*
*   raylib is licensed under an unmodified zlib/libpng license, which is an OSI-certified,
*   BSD-like license that allows static linking with closed source software:
*
*   Copyright (c) 2013-2021 Ramon Santamaria (@raysan5)
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
// Some basic Defines
//----------------------------------------------------------------------------------

// Some Basic Colors
// NOTE: Custom raylib color palette for amazing visuals on WHITE background
LIGHTGRAY       :: Color.{ 200, 200, 200, 255 };   // Light Gray
GRAY            :: Color.{ 130, 130, 130, 255 };   // Gray
DARKGRAY        :: Color.{ 80, 80, 80, 255 };      // Dark Gray
YELLOW          :: Color.{ 253, 249, 0, 255 };     // Yellow
GOLD            :: Color.{ 255, 203, 0, 255 };     // Gold
ORANGE          :: Color.{ 255, 161, 0, 255 };     // Orange
PINK            :: Color.{ 255, 109, 194, 255 };   // Pink
RED             :: Color.{ 230, 41, 55, 255 };     // Red
MAROON          :: Color.{ 190, 33, 55, 255 };     // Maroon
GREEN           :: Color.{ 0, 228, 48, 255 };      // Green
LIME            :: Color.{ 0, 158, 47, 255 };      // Lime
DARKGREEN       :: Color.{ 0, 117, 44, 255 };      // Dark Green
SKYBLUE         :: Color.{ 102, 191, 255, 255 };   // Sky Blue
BLUE            :: Color.{ 0, 121, 241, 255 };     // Blue
DARKBLUE        :: Color.{ 0, 82, 172, 255 };      // Dark Blue
PURPLE          :: Color.{ 200, 122, 255, 255 };   // Purple
VIOLET          :: Color.{ 135, 60, 190, 255 };    // Violet
DARKPURPLE      :: Color.{ 112, 31, 126, 255 };    // Dark Purple
BEIGE           :: Color.{ 211, 176, 131, 255 };   // Beige
BROWN           :: Color.{ 127, 106, 79, 255 };    // Brown
DARKBROWN       :: Color.{ 76, 63, 47, 255 };      // Dark Brown

WHITE           :: Color.{ 255, 255, 255, 255 };   // White
BLACK           :: Color.{ 0, 0, 0, 255 };         // Black
BLANK           :: Color.{ 0, 0, 0, 0 };           // Blank (Transparent)
MAGENTA         :: Color.{ 255, 0, 255, 255 };     // Magenta
RAYWHITE        :: Color.{ 245, 245, 245, 255 };   // My own White (raylib logo)

// Temporal hacks to avoid breaking old codebases using
// deprecated raylib implementation or definitions
// FormatText                          :: TextFormat;
// LoadText                            :: LoadFileText;
// GetExtension                        :: GetFileExtension;
// GetImageData                        :: LoadImageColors;
// FILTER_POINT                        :: TEXTURE_FILTER_POINT;
// FILTER_BILINEAR                     :: TEXTURE_FILTER_BILINEAR;
// MAP_DIFFUSE                         :: MATERIAL_MAP_DIFFUSE;
// PIXELFORMAT_UNCOMPRESSED_R8G8B8A8   :: PIXELFORMAT_PIXELFORMAT_UNCOMPRESSED_R8G8B8A8;

//----------------------------------------------------------------------------------
// Structures Definition
//----------------------------------------------------------------------------------

// Vector2 type
Vector2 :: struct {
    x, y: float32;
}

// Vector3 type
Vector3 :: struct {
    x, y, z: float32;
}

// Vector4 type
Vector4 :: struct {
    x, y, z, w: float32;
}

// Quaternion type, same as Vector4
Quaternion :: Vector4;

// Matrix type (OpenGL style 4x4 - right handed, column major)
Matrix :: struct {
    m0, m4, m8, m12: float32;
    m1, m5, m9, m13: float32;
    m2, m6, m10, m14: float32;
    m3, m7, m11, m15: float32;
}

// Color type, RGBA (32bit)
Color :: struct {
    r, g, b, a: u8;
}

// Rectangle type
Rectangle :: struct {
    x, y: float32;
    width, height: float32;
}

// Image type, bpp always RGBA (32bit)
// NOTE: Data stored in CPU memory (RAM)
Image :: struct {
    data: *void;            // Image raw data
    width: s32;             // Image base width
    height: s32;            // Image base height
    mipmaps: s32;           // Mipmap levels, 1 by default
    format: s32;            // Data format (PixelFormat type)
}

// Texture type
// NOTE: Data stored in GPU memory
Texture :: struct {
    id: u32;                // OpenGL texture id
    width: s32;             // Texture base width
    height: s32;            // Texture base height
    mipmaps: s32;           // Mipmap levels, 1 by default
    format: s32;            // Data format (PixelFormat type)
}

// Texture2D type, same as Texture
Texture2D :: Texture;

// TextureCubemap type, actually, same as Texture
TextureCubemap :: Texture;

// RenderTexture type, for texture rendering
RenderTexture :: struct {
    id: u32;                // OpenGL framebuffer object id
    texture: Texture;       // Color buffer attachment texture
    depth: Texture;         // Depth buffer attachment texture
}

// RenderTexture2D type, same as RenderTexture
RenderTexture2D :: RenderTexture;

// N-Patch layout info
NPatchInfo :: struct {
    source: Rectangle;      // Texture source rectangle
    left: s32;              // Left border offset
    top: s32;               // Top border offset
    right: s32;             // Right border offset
    bottom: s32;            // Bottom border offset
    layout: s32;            // Layout of the n-patch: 3x3, 1x3 or 3x1
}

// Font character info
CharInfo :: struct {
    value: s32;             // Character value (Unicode)
    offsetX: s32;           // Character offset X when drawing
    offsetY: s32;           // Character offset Y when drawing
    advanceX: s32;          // Character advance position X
    image: Image;           // Character image data
}

// Font type, includes texture and charSet array data
Font :: struct {
    baseSize: s32;          // Base size (default chars height)
    charsCount: s32;        // Number of characters
    charsPadding: s32;      // Padding around the chars
    texture: Texture2D;     // Characters texture atlas
    recs: *Rectangle;       // Characters rectangles in texture
    chars: *CharInfo;       // Characters info data
}

// Font :: SpriteFont;         // SpriteFont type fallback, defaults to Font

// Camera type, defines a camera position/orientation in 3d space
Camera3D :: struct {
    position: Vector3;                  // Camera position
    target: Vector3;                    // Camera target it looks-at
    up: Vector3;                        // Camera up vector (rotation over its axis)
    fovy: float32;                      // Camera field-of-view apperture in Y (degrees) in perspective, used as near plane width in orthographic
    projection: CameraProjection;       // Camera projection: CAMERA_PERSPECTIVE or CAMERA_ORTHOGRAPHIC
}

Camera :: Camera3D;         // Camera type fallback, defaults to Camera3D

// Camera2D type, defines a 2d camera
Camera2D :: struct {
    offset: Vector2;        // Camera offset (displacement from target)
    target: Vector2;        // Camera target (rotation and zoom origin)
    rotation: float32;          // Camera rotation in degrees
    zoom: float32;              // Camera zoom (scaling), should be 1.0f by default
}

// Vertex data definning a mesh
// NOTE: Data stored in CPU memory (and GPU)
Mesh :: struct {
    vertexCount: int;       // Number of vertices stored in arrays
    triangleCount: int;     // Number of triangles stored (indexed or not)

    // Default vertex data
    vertices: *float32;         // Vertex position (XYZ - 3 components per vertex) (shader-location = 0)
    texcoords: *float32;        // Vertex texture coordinates (UV - 2 components per vertex) (shader-location = 1)
    texcoords2: *float32;       // Vertex second texture coordinates (useful for lightmaps) (shader-location = 5)
    normals: *float32;          // Vertex normals (XYZ - 3 components per vertex) (shader-location = 2)
    tangents: *float32;         // Vertex tangents (XYZW - 4 components per vertex) (shader-location = 4)
    colors: *u8;            // Vertex colors (RGBA - 4 components per vertex) (shader-location = 3)
    indices: *u16;          // Vertex indices (in case vertex data comes indexed)

    // Animation vertex data
    animVertices: *float32;     // Animated vertex positions (after bones transformations)
    animNormals: *float32;      // Animated normals (after bones transformations)
    boneIds: *s32;          // Vertex bone ids, up to 4 bones influence by vertex (skinning)
    boneWeights: *float32;      // Vertex bone weight, up to 4 bones influence by vertex (skinning)

    // OpenGL identifiers
    vaoId: s32;             // OpenGL Vertex Array Object id
    vboId: *s32;            // OpenGL Vertex Buffer Objects id (default vertex data)
}

// Shader type (generic)
Shader :: struct {
    id: u32;                // Shader program id
    locs: *s32;             // Shader locations array (MAX_SHADER_LOCATIONS)
}

// Material texture map
MaterialMap :: struct {
    texture: Texture2D;     // Material map texture
    color: Color;           // Material map color
    value: float32;             // Material map value
}

// Material type (generic)
Material :: struct {
    shader: Shader;         // Material shader
    maps: *MaterialMap;     // Material maps array (MAX_MATERIAL_MAPS)
    params: [4] float32;        // Material generic parameters (if required)
}

// Transformation properties
Transform :: struct {
    translation: Vector3;   // Translation
    rotation: Quaternion;   // Rotation
    scale: Vector3;         // Scale
}

// Bone information
BoneInfo :: struct {
    name: [32] u8;          // Bone name
    parent: s32;            // Bone parent
}

// Model type
Model :: struct {
    transform: Matrix;      // Local transform matrix

    meshCount: s32;         // Number of meshes
    materialCount: s32;     // Number of materials
    meshes: *Mesh;          // Meshes array
    materials: *Material;   // Materials array
    meshMaterial: *s32;     // Mesh material number

    // Animation data
    boneCount: s32;         // Number of bones
    bones: *BoneInfo;       // Bones information (skeleton)
    bindPose: *Transform;   // Bones base transformation (pose)
}

// Model animation
ModelAnimation :: struct {
    boneCount: s32;          // Number of bones
    frameCount: s32;         // Number of animation frames
    bones: *BoneInfo;        // Bones information (skeleton)
    framePoses: **Transform; // Poses array by frame
}

// Ray type (useful for raycast)
Ray :: struct {
    position: Vector3;      // Ray position (origin)
    direction: Vector3;     // Ray direction
}

// Raycast hit information
RayHitInfo :: struct {
    hit: bool;              // Did the ray hit something?
    distance: float32;          // Distance to nearest hit
    position: Vector3;      // Position of nearest hit
    normal: Vector3;        // Surface normal of hit
}

// Bounding box type
BoundingBox :: struct {
    min: Vector3;           // Minimum vertex box-corner
    max: Vector3;           // Maximum vertex box-corner
}

// Wave type, defines audio wave data
Wave :: struct {
    sampleCount: u32;       // Total number of samples
    sampleRate: u32;        // Frequency (samples per second)
    sampleSize: u32;        // Bit depth (bits per sample): 8, 16, 32 (24 not supported)
    channels: u32;          // Number of channels (1-mono, 2-stereo)
    data: *void;            // Buffer data pointer
}

// Audio stream type
// NOTE: Useful to create custom audio streams not bound to a specific file
AudioStream :: struct {
    //buffer: *rAudioBuffer;  // Pointer to internal data used by the audio system

    sampleRate: u32;        // Frequency (samples per second)
    sampleSize: u32;        // Bit depth (bits per sample): 8, 16, 32 (24 not supported)
    channels: u32;          // Number of channels (1-mono, 2-stereo)
}

// Sound source type
Sound :: struct {
    stream: AudioStream;    // Audio stream
    sampleCount: s32;       // Total number of samples
}

// Music stream type (audio file streaming from memory)
// NOTE: Anything longer than ~10 seconds should be streamed
Music :: struct {
    stream: AudioStream;    // Audio stream
    sampleCount: s32;       // Total number of samples
    looping: bool;          // Music looping enable

    ctxType: s32;           // Type of music context (audio filetype)
    ctxData: *void;         // Audio context data, depends on type
}

// Head-Mounted-Display device parameters
VrDeviceInfo :: struct {
    hResolution: s32;               // Horizontal resolution in pixels
    vResolution: s32;               // Vertical resolution in pixels
    hScreenSize: float32;               // Horizontal size in meters
    vScreenSize: float32;               // Vertical size in meters
    vScreenCenter: float32;             // Screen center in meters
    eyeToScreenDistance: float32;       // Distance between eye and display in meters
    lensSeparationDistance: float32;    // Lens separation distance in meters
    interpupillaryDistance: float32;    // IPD (distance between pupils) in meters
    lensDistortionValues: [4] float32;  // Lens distortion constant parameters
    chromaAbCorrection: [4] float32;    // Chromatic aberration correction parameters
}

// VR Stereo rendering configuration for simulator
VrStereoConfig :: struct {
    projection: [2] Matrix;         // VR projection matrices (per eye)
    viewOffset: [2] Matrix;         // VR view offset matrices (per eye)
    leftLensCenter: [2] float32;        // VR left lens center
    rightLensCenter: [2] float32;       // VR right lens center
    leftScreenCenter: [2] float32;      // VR left screen center
    rightScreenCenter: [2] float32;     // VR right screen center
    scale: [2] float32;                 // VR distortion scale
    scaleIn: [2] float32;               // VR distortion scale in
}

//----------------------------------------------------------------------------------
// Enumerators Definition
//----------------------------------------------------------------------------------
// System/Window config flags
// NOTE: Every bit registers one state (use it with bit masks)
// By default all flags are set to 0
ConfigFlags :: enum s32 {
    FLAG_VSYNC_HINT         :: 0x00000040;    // Set to try enabling V-Sync on GPU
    FLAG_FULLSCREEN_MODE    :: 0x00000002;    // Set to run program in fullscreen
    FLAG_WINDOW_RESIZABLE   :: 0x00000004;    // Set to allow resizable window
    FLAG_WINDOW_UNDECORATED :: 0x00000008;    // Set to disable window decoration (frame and buttons)
    FLAG_WINDOW_HIDDEN      :: 0x00000080;    // Set to hide window
    FLAG_WINDOW_MINIMIZED   :: 0x00000200;    // Set to minimize window (iconify)
    FLAG_WINDOW_MAXIMIZED   :: 0x00000400;    // Set to maximize window (expanded to monitor)
    FLAG_WINDOW_UNFOCUSED   :: 0x00000800;    // Set to window non focused
    FLAG_WINDOW_TOPMOST     :: 0x00001000;    // Set to window always on top
    FLAG_WINDOW_ALWAYS_RUN  :: 0x00000100;    // Set to allow windows running while minimized
    FLAG_WINDOW_TRANSPARENT :: 0x00000010;    // Set to allow transparent framebuffer
    FLAG_WINDOW_HIGHDPI     :: 0x00002000;    // Set to support HighDPI
    FLAG_MSAA_4X_HINT       :: 0x00000020;    // Set to try enabling MSAA 4X
    FLAG_INTERLACED_HINT    :: 0x00010000;    // Set to try enabling interlaced video format (for V3D)
}

// Trace log level
TraceLogLevel :: enum s32 {
    LOG_ALL :: 0;       // Display all logs
    LOG_TRACE;
    LOG_DEBUG;
    LOG_INFO;
    LOG_WARNING;
    LOG_ERROR;
    LOG_FATAL;
    LOG_NONE;           // Disable logging
}

// Keyboard keys (US keyboard layout)
// NOTE: Use GetKeyPressed() to allow redefining
// required keys for alternative layouts
KeyboardKey ::  enum s32 {
    KEY_NULL            :: 0;
    // Alphanumeric keys
    KEY_APOSTROPHE      :: 39;
    KEY_COMMA           :: 44;
    KEY_MINUS           :: 45;
    KEY_PERIOD          :: 46;
    KEY_SLASH           :: 47;
    KEY_ZERO            :: 48;
    KEY_ONE             :: 49;
    KEY_TWO             :: 50;
    KEY_THREE           :: 51;
    KEY_FOUR            :: 52;
    KEY_FIVE            :: 53;
    KEY_SIX             :: 54;
    KEY_SEVEN           :: 55;
    KEY_EIGHT           :: 56;
    KEY_NINE            :: 57;
    KEY_SEMICOLON       :: 59;
    KEY_EQUAL           :: 61;
    KEY_A               :: 65;
    KEY_B               :: 66;
    KEY_C               :: 67;
    KEY_D               :: 68;
    KEY_E               :: 69;
    KEY_F               :: 70;
    KEY_G               :: 71;
    KEY_H               :: 72;
    KEY_I               :: 73;
    KEY_J               :: 74;
    KEY_K               :: 75;
    KEY_L               :: 76;
    KEY_M               :: 77;
    KEY_N               :: 78;
    KEY_O               :: 79;
    KEY_P               :: 80;
    KEY_Q               :: 81;
    KEY_R               :: 82;
    KEY_S               :: 83;
    KEY_T               :: 84;
    KEY_U               :: 85;
    KEY_V               :: 86;
    KEY_W               :: 87;
    KEY_X               :: 88;
    KEY_Y               :: 89;
    KEY_Z               :: 90;

    // Function keys
    KEY_SPACE           :: 32;
    KEY_ESCAPE          :: 256;
    KEY_ENTER           :: 257;
    KEY_TAB             :: 258;
    KEY_BACKSPACE       :: 259;
    KEY_INSERT          :: 260;
    KEY_DELETE          :: 261;
    KEY_RIGHT           :: 262;
    KEY_LEFT            :: 263;
    KEY_DOWN            :: 264;
    KEY_UP              :: 265;
    KEY_PAGE_UP         :: 266;
    KEY_PAGE_DOWN       :: 267;
    KEY_HOME            :: 268;
    KEY_END             :: 269;
    KEY_CAPS_LOCK       :: 280;
    KEY_SCROLL_LOCK     :: 281;
    KEY_NUM_LOCK        :: 282;
    KEY_PRINT_SCREEN    :: 283;
    KEY_PAUSE           :: 284;
    KEY_F1              :: 290;
    KEY_F2              :: 291;
    KEY_F3              :: 292;
    KEY_F4              :: 293;
    KEY_F5              :: 294;
    KEY_F6              :: 295;
    KEY_F7              :: 296;
    KEY_F8              :: 297;
    KEY_F9              :: 298;
    KEY_F10             :: 299;
    KEY_F11             :: 300;
    KEY_F12             :: 301;
    KEY_LEFT_SHIFT      :: 340;
    KEY_LEFT_CONTROL    :: 341;
    KEY_LEFT_ALT        :: 342;
    KEY_LEFT_SUPER      :: 343;
    KEY_RIGHT_SHIFT     :: 344;
    KEY_RIGHT_CONTROL   :: 345;
    KEY_RIGHT_ALT       :: 346;
    KEY_RIGHT_SUPER     :: 347;
    KEY_KB_MENU         :: 348;
    KEY_LEFT_BRACKET    :: 91;
    KEY_BACKSLASH       :: 92;
    KEY_RIGHT_BRACKET   :: 93;
    KEY_GRAVE           :: 96;

    // Keypad keys
    KEY_KP_0            :: 320;
    KEY_KP_1            :: 321;
    KEY_KP_2            :: 322;
    KEY_KP_3            :: 323;
    KEY_KP_4            :: 324;
    KEY_KP_5            :: 325;
    KEY_KP_6            :: 326;
    KEY_KP_7            :: 327;
    KEY_KP_8            :: 328;
    KEY_KP_9            :: 329;
    KEY_KP_DECIMAL      :: 330;
    KEY_KP_DIVIDE       :: 331;
    KEY_KP_MULTIPLY     :: 332;
    KEY_KP_SUBTRACT     :: 333;
    KEY_KP_ADD          :: 334;
    KEY_KP_ENTER        :: 335;
    KEY_KP_EQUAL        :: 336;
    // Android key buttons
    KEY_BACK            :: 4;
    KEY_MENU            :: 82;
    KEY_VOLUME_UP       :: 24;
    KEY_VOLUME_DOWN     :: 25;
}

// Mouse buttons
MouseButton :: enum s32 {
    MOUSE_LEFT_BUTTON   :: 0;
    MOUSE_RIGHT_BUTTON  :: 1;
    MOUSE_MIDDLE_BUTTON :: 2;
}

// Mouse cursor
MouseCursor :: enum s32 {
    MOUSE_CURSOR_DEFAULT       :: 0;
    MOUSE_CURSOR_ARROW         :: 1;
    MOUSE_CURSOR_IBEAM         :: 2;
    MOUSE_CURSOR_CROSSHAIR     :: 3;
    MOUSE_CURSOR_POINTING_HAND :: 4;
    MOUSE_CURSOR_RESIZE_EW     :: 5;     // The horizontal resize/move arrow shape
    MOUSE_CURSOR_RESIZE_NS     :: 6;     // The vertical resize/move arrow shape
    MOUSE_CURSOR_RESIZE_NWSE   :: 7;     // The top-left to bottom-right diagonal resize/move arrow shape
    MOUSE_CURSOR_RESIZE_NESW   :: 8;     // The top-right to bottom-left diagonal resize/move arrow shape
    MOUSE_CURSOR_RESIZE_ALL    :: 9;     // The omni-directional resize/move cursor shape
    MOUSE_CURSOR_NOT_ALLOWED   :: 10;    // The operation-not-allowed shape
}

// Gamepad buttons
GamepadButton :: enum s32 {
    // This is here just for error checking
    GAMEPAD_BUTTON_UNKNOWN :: 0;

    // This is normally a DPAD
    GAMEPAD_BUTTON_LEFT_FACE_UP;
    GAMEPAD_BUTTON_LEFT_FACE_RIGHT;
    GAMEPAD_BUTTON_LEFT_FACE_DOWN;
    GAMEPAD_BUTTON_LEFT_FACE_LEFT;

    // This normally corresponds with PlayStation and Xbox controllers
    // XBOX: [Y,X,A,B]
    // PS3: [Triangle,Square,Cross,Circle]
    // No support for 6 button controllers though..
    GAMEPAD_BUTTON_RIGHT_FACE_UP;
    GAMEPAD_BUTTON_RIGHT_FACE_RIGHT;
    GAMEPAD_BUTTON_RIGHT_FACE_DOWN;
    GAMEPAD_BUTTON_RIGHT_FACE_LEFT;

    // Triggers
    GAMEPAD_BUTTON_LEFT_TRIGGER_1;
    GAMEPAD_BUTTON_LEFT_TRIGGER_2;
    GAMEPAD_BUTTON_RIGHT_TRIGGER_1;
    GAMEPAD_BUTTON_RIGHT_TRIGGER_2;

    // These are buttons in the center of the gamepad
    GAMEPAD_BUTTON_MIDDLE_LEFT;     // PS3 Select
    GAMEPAD_BUTTON_MIDDLE;          // PS Button/XBOX Button
    GAMEPAD_BUTTON_MIDDLE_RIGHT;    // PS3 Start

    // These are the joystick press in buttons
    GAMEPAD_BUTTON_LEFT_THUMB;
    GAMEPAD_BUTTON_RIGHT_THUMB;
}

// Gamepad axis
GamepadAxis :: enum s32 {
    // Left stick
    GAMEPAD_AXIS_LEFT_X :: 0;
    GAMEPAD_AXIS_LEFT_Y :: 1;

    // Right stick
    GAMEPAD_AXIS_RIGHT_X :: 2;
    GAMEPAD_AXIS_RIGHT_Y :: 3;

    // Pressure levels for the back triggers
    GAMEPAD_AXIS_LEFT_TRIGGER :: 4;      // [1..-1] (pressure-level)
    GAMEPAD_AXIS_RIGHT_TRIGGER :: 5;     // [1..-1] (pressure-level)
}

// Material map index
MaterialMapIndex :: enum s32 {
    MATERIAL_MAP_ALBEDO    :: 0;       // MATERIAL_MAP_DIFFUSE
    MATERIAL_MAP_METALNESS :: 1;       // MATERIAL_MAP_SPECULAR
    MATERIAL_MAP_NORMAL    :: 2;
    MATERIAL_MAP_ROUGHNESS :: 3;
    MATERIAL_MAP_OCCLUSION;
    MATERIAL_MAP_EMISSION;
    MATERIAL_MAP_HEIGHT;
    MATERIAL_MAP_BRDG;
    MATERIAL_MAP_CUBEMAP;             // NOTE: Uses GL_TEXTURE_CUBE_MAP
    MATERIAL_MAP_IRRADIANCE;          // NOTE: Uses GL_TEXTURE_CUBE_MAP
    MATERIAL_MAP_PREFILTER;           // NOTE: Uses GL_TEXTURE_CUBE_MAP
}

MATERIAL_MAP_DIFFUSE :: MaterialMapIndex.MATERIAL_MAP_ALBEDO;
MATERIAL_MAP_SPECULAR :: MaterialMapIndex.MATERIAL_MAP_METALNESS;

// Shader location index
ShaderLocationIndex :: enum s32 {
    SHADER_LOC_VERTEX_POSITION :: 0;
    SHADER_LOC_VERTEX_TEXCOORD01;
    SHADER_LOC_VERTEX_TEXCOORD02;
    SHADER_LOC_VERTEX_NORMAL;
    SHADER_LOC_VERTEX_TANGENT;
    SHADER_LOC_VERTEX_COLOR;
    SHADER_LOC_MATRIX_MVP;
    SHADER_LOC_MATRIX_VIEW;
    SHADER_LOC_MATRIX_PROJECTION;
    SHADER_LOC_MATRIX_MODEL;
    SHADER_LOC_MATRIX_NORMAL;
    SHADER_LOC_VECTOR_VIEW;
    SHADER_LOC_COLOR_DIFFUSE;
    SHADER_LOC_COLOR_SPECULAR;
    SHADER_LOC_COLOR_AMBIENT;
    SHADER_LOC_MAP_ALBEDO;          // SHADER_LOC_MAP_DIFFUSE
    SHADER_LOC_MAP_METALNESS;       // SHADER_LOC_MAP_SPECULAR
    SHADER_LOC_MAP_NORMAL;
    SHADER_LOC_MAP_ROUGHNESS;
    SHADER_LOC_MAP_OCCLUSION;
    SHADER_LOC_MAP_EMISSION;
    SHADER_LOC_MAP_HEIGHT;
    SHADER_LOC_MAP_CUBEMAP;
    SHADER_LOC_MAP_IRRADIANCE;
    SHADER_LOC_MAP_PREFILTER;
    SHADER_LOC_MAP_BRDF;
}

SHADER_LOC_MAP_DIFFUSE :: ShaderLocationIndex.SHADER_LOC_MAP_ALBEDO;
SHADER_LOC_MAP_SPECULAR :: ShaderLocationIndex.SHADER_LOC_MAP_METALNESS;

// Shader uniform data type
ShaderUniformDataType :: enum s32 {
    SHADER_UNIFORM_FLOAT :: 0;
    SHADER_UNIFORM_VEC2;
    SHADER_UNIFORM_VEC3;
    SHADER_UNIFORM_VEC4;
    SHADER_UNIFORM_INT;
    SHADER_UNIFORM_IVEC2;
    SHADER_UNIFORM_IVEC3;
    SHADER_UNIFORM_IVEC4;
    SHADER_UNIFORM_SAMPLER2D;
}

// Pixel formats
// NOTE: Support depends on OpenGL version and platform
PixelFormat :: enum s32 {
    PIXELFORMAT_UNCOMPRESSED_GRAYSCALE :: 1;    // 8 bit per pixel (no alpha)
    PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA;        // 8*2 bpp (2 channels)
    PIXELFORMAT_UNCOMPRESSED_R5G6B5;            // 16 bpp
    PIXELFORMAT_UNCOMPRESSED_R8G8B8;            // 24 bpp
    PIXELFORMAT_UNCOMPRESSED_R5G5B5A1;          // 16 bpp (1 bit alpha)
    PIXELFORMAT_UNCOMPRESSED_R4G4B4A4;          // 16 bpp (4 bit alpha)
    PIXELFORMAT_UNCOMPRESSED_R8G8B8A8;          // 32 bpp
    PIXELFORMAT_UNCOMPRESSED_R32;               // 32 bpp (1 channel - float)
    PIXELFORMAT_UNCOMPRESSED_R32G32B32;         // 32*3 bpp (3 channels - float)
    PIXELFORMAT_UNCOMPRESSED_R32G32B32A32;      // 32*4 bpp (4 channels - float)
    PIXELFORMAT_COMPRESSED_DXT1_RGB;            // 4 bpp (no alpha)
    PIXELFORMAT_COMPRESSED_DXT1_RGBA;           // 4 bpp (1 bit alpha)
    PIXELFORMAT_COMPRESSED_DXT3_RGBA;           // 8 bpp
    PIXELFORMAT_COMPRESSED_DXT5_RGBA;           // 8 bpp
    PIXELFORMAT_COMPRESSED_ETC1_RGB;            // 4 bpp
    PIXELFORMAT_COMPRESSED_ETC2_RGB;            // 4 bpp
    PIXELFORMAT_COMPRESSED_ETC2_EAC_RGBA;       // 8 bpp
    PIXELFORMAT_COMPRESSED_PVRT_RGB;            // 4 bpp
    PIXELFORMAT_COMPRESSED_PVRT_RGBA;           // 4 bpp
    PIXELFORMAT_COMPRESSED_ASTC_4x4_RGBA;       // 8 bpp
    PIXELFORMAT_COMPRESSED_ASTC_8x8_RGBA;       // 2 bpp
}

// Texture parameters: filter mode
// NOTE 1: Filtering considers mipmaps if available in the texture
// NOTE 2: Filter is accordingly set for minification and magnification
TextureFilter :: enum s32 {
    TEXTURE_FILTER_POINT :: 0;              // No filter, just pixel aproximation
    TEXTURE_FILTER_BILINEAR;                // Linear filtering
    TEXTURE_FILTER_TRILINEAR;               // Trilinear filtering (linear with mipmaps)
    TEXTURE_FILTER_ANISOTROPIC_4X;          // Anisotropic filtering 4x
    TEXTURE_FILTER_ANISOTROPIC_8X;          // Anisotropic filtering 8x
    TEXTURE_FILTER_ANISOTROPIC_16X;         // Anisotropic filtering 16x
}

// Texture parameters: wrap mode
TextureWrap :: enum s32 {
    TEXTURE_WRAP_REPEAT :: 0;       // Repeats texture in tiled mode
    TEXTURE_WRAP_CLAMP;             // Clamps texture to edge pixel in tiled mode
    TEXTURE_WRAP_MIRROR_REPEAT;     // Mirrors and repeats the texture in tiled mode
    TEXTURE_WRAP_MIRROR_CLAMP;      // Mirrors and clamps to border the texture in tiled mode
}

// Cubemap layouts
CubemapLayout :: enum s32 {
    CUBEMAP_LAYOUT_AUTO_DETECT :: 0;       // Automatically detect layout type
    CUBEMAP_LAYOUT_LINE_VERTICAL;          // Layout is defined by a vertical line with faces
    CUBEMAP_LAYOUT_LINE_HORIZONTAL;        // Layout is defined by an horizontal line with faces
    CUBEMAP_LAYOUT_CROSS_THREE_BY_FOUR;    // Layout is defined by a 3x4 cross with cubemap faces
    CUBEMAP_LAYOUT_CROSS_FOUR_BY_THREE;    // Layout is defined by a 4x3 cross with cubemap faces
    CUBEMAP_LAYOUT_PANORAMA;               // Layout is defined by a panorama image (equirectangular map)
}

// Font type, defines generation method
FontType :: enum s32 {
    FONT_DEFAULT :: 0;      // Default font generation, anti-aliased
    FONT_BITMAP;            // Bitmap font generation, no anti-aliasing
    FONT_SDF;               // SDF font generation, requires external shader
}

// Color blending modes (pre-defined)
BlendMode :: enum s32 {
    BLEND_ALPHA :: 0;       // Blend textures considering alpha (default)
    BLEND_ADDITIVE;         // Blend textures adding colors
    BLEND_MULTIPLIED;       // Blend textures multiplying colors
    BLEND_ADD_COLORS;       // Blend textures adding colors (alternative)
    BLEND_SUBTRACT_COLORS;  // Blend textures subtracting colors (alternative)
    BLEND_CUSTOM;           // Belnd textures using custom src/dst factors (use rlSetBlendMode())
}

// Gestures
// NOTE: It could be used as flags to enable only some gestures
Gestures :: enum s32 {
    GESTURE_NONE        :: 0;
    GESTURE_TAP         :: 1;
    GESTURE_DOUBLETAP   :: 2;
    GESTURE_HOLD        :: 4;
    GESTURE_DRAG        :: 8;
    GESTURE_SWIPE_RIGHT :: 16;
    GESTURE_SWIPE_LEFT  :: 32;
    GESTURE_SWIPE_UP    :: 64;
    GESTURE_SWIPE_DOWN  :: 128;
    GESTURE_PINCH_IN    :: 256;
    GESTURE_PINCH_OUT   :: 512;
}

// Camera system modes
CameraMode :: enum s32 {
    CAMERA_CUSTOM :: 0;
    CAMERA_FREE;
    CAMERA_ORBITAL;
    CAMERA_FIRST_PERSON;
    CAMERA_THIRD_PERSON;
}

// Camera projection
CameraProjection :: enum s32 {
    CAMERA_PERSPECTIVE :: 0;
    CAMERA_ORTHOGRAPHIC;
}

// N-patch layout
NPatchLayout :: enum s32 {
    NPATCH_NINE_PATCH :: 0;         // Npatch layout: 3x3 tiles
    NPATCH_THREE_PATCH_VERTICAL;    // Npatch layout: 1x3 tiles
    NPATCH_THREE_PATCH_HORIZONTAL;  // Npatch layout: 3x1 tiles
}

//
// Callbacks to hook some internal functions
// WARNING: This callbacks are intended for advance users
//
// Logging: Redirect trace log messages
TraceLogCallback :: #type (logLevel: s32, text: *u8, args: ..Any) #c_call;
// FileIO: Load binary data
LoadFileDataCallback :: #type (fileName: *u8, bytesRead: *u32) -> *u8 #c_call;
// FileIO: Save binary data
SaveFileDataCallback :: #type (fileName: *u8, data: *void, bytesToWrite: u32) -> bool #c_call;
// FileIO: Load text data
LoadFileTextCallback :: #type (fileName: *u8) -> *u8 #c_call;
// FileIO: Save text data
SaveFileTextCallback :: #type (fileName: *u8, text: *u8) -> bool #c_call;

//------------------------------------------------------------------------------------
// Global Variables Definition
//------------------------------------------------------------------------------------
// It's lonely here...

//------------------------------------------------------------------------------------
// Window and Graphics Device Functions (Module: core)
//------------------------------------------------------------------------------------

//
// Window-related functions
//
// Initialize window and OpenGL context
InitWindow :: (width: s32, height: s32, title: *u8) #foreign raylib;
// Check if KEY_ESCAPE pressed or Close icon pressed
WindowShouldClose :: () -> bool #foreign raylib;
// Close window and unload OpenGL context
CloseWindow :: () #foreign raylib;
// Check if window has been initialized successfully
IsWindowReady :: () -> bool #foreign raylib;
// Check if window is currently fullscreen
IsWindowFullscreen :: () -> bool #foreign raylib;
// Check if window is currently hidden (only PLATFORM_DESKTOP)
IsWindowHidden :: () -> bool #foreign raylib;
// Check if window is currently minimized (only PLATFORM_DESKTOP)
IsWindowMinimized :: () -> bool #foreign raylib;
// Check if window is currently maximized (only PLATFORM_DESKTOP)
IsWindowMaximized :: () -> bool #foreign raylib;
// Check if window is currently focused (only PLATFORM_DESKTOP)
IsWindowFocused :: () -> bool #foreign raylib;
// Check if window has been resized last frame
IsWindowResized :: () -> bool #foreign raylib;
// Check if one specific window flag is enabled
IsWindowState :: (flag: u32) -> bool #foreign raylib;
// Set window configuration state using flags
SetWindowState :: (flags: u32) #foreign raylib;
// Clear window configuration state flags
ClearWindowState :: (flags: u32) #foreign raylib;
// Toggle window state: fullscreen/windowed (only PLATFORM_DESKTOP)
ToggleFullscreen :: () #foreign raylib;
// Set window state: maximized, if resizable (only PLATFORM_DESKTOP)
MaximizeWindow :: () #foreign raylib;
// Set window state: minimized, if resizable (only PLATFORM_DESKTOP)
MinimizeWindow :: () #foreign raylib;
// Set window state: not minimized/maximized (only PLATFORM_DESKTOP)
RestoreWindow :: () #foreign raylib;
// Set icon for window (only PLATFORM_DESKTOP)
SetWindowIcon :: (image: Image) #foreign raylib;
// Set title for window (only PLATFORM_DESKTOP)
SetWindowTitle :: (title: *u8) #foreign raylib;
// Set window position on screen (only PLATFORM_DESKTOP)
SetWindowPosition :: (x: s32, y: s32) #foreign raylib;
// Set monitor for the current window (fullscreen mode)
SetWindowMonitor :: (monitor: s32) #foreign raylib;
// Set window minimum dimensions (for FLAG_WINDOW_RESIZABLE)
SetWindowMinSize :: (width: s32, height: s32) #foreign raylib;
// Set window dimensions
SetWindowSize :: (width: s32, height: s32) #foreign raylib;
// Get native window handle
GetWindowHandle :: () -> *void #foreign raylib;
// Get current screen width
GetScreenWidth :: () -> s32 #foreign raylib;
// Get current screen height
GetScreenHeight :: () -> s32 #foreign raylib;
// Get number of connected monitors
GetMonitorCount :: () -> s32 #foreign raylib;
// Get current connected monitor
GetCurrentMonitor :: () -> s32 #foreign raylib;
// Get specified monitor position
GetMonitorPosition :: (monitor: s32) -> Vector2 #foreign raylib;
// Get specified monitor width (max available by monitor)
GetMonitorWidth :: (monitor: s32) -> s32 #foreign raylib;
// Get specified monitor height (max available by monitor)
GetMonitorHeight :: (monitor: s32) -> s32 #foreign raylib;
// Get specified monitor physical width in millimetres
GetMonitorPhysicalWidth :: (monitor: s32) -> s32 #foreign raylib;
// Get specified monitor physical height in millimetres
GetMonitorPhysicalHeight :: (monitor: s32) -> s32 #foreign raylib;
// Get specified monitor refresh rate
GetMonitorRefreshRate :: (monitor: s32) -> s32 #foreign raylib;
// Get window position XY on monitor
GetWindowPosition :: () -> Vector2 #foreign raylib;
// Get window scale DPI factor
GetWindowScaleDPI :: () -> Vector2 #foreign raylib;
// Get the human-readable, UTF-8 encoded name of the primary monitor
GetMonitorName :: (monitor: s32) -> *u8 #foreign raylib;
// Set clipboard text content
SetClipboardText :: (text: *u8) #foreign raylib;
// Get clipboard text content
GetClipboardText :: () -> *u8 #foreign raylib;

//
// Cursor-related functions
//
// Shows cursor
ShowCursor :: () #foreign raylib;
// Hides cursor
HideCursor :: () #foreign raylib;
// Check if cursor is not visible
IsCursorHidden :: () -> bool #foreign raylib;
// Enables cursor (unlock cursor)
EnableCursor :: () #foreign raylib;
// Disables cursor (lock cursor)
DisableCursor :: () #foreign raylib;
// Check if cursor is on the current screen.
IsCursorOnScreen :: () -> bool #foreign raylib;

//
// Drawing-related functions
//
// Set background color (framebuffer clear color)
ClearBackground :: (color: Color) #foreign raylib;
// Setup canvas (framebuffer) to start drawing
BeginDrawing :: () #foreign raylib;
// End canvas drawing and swap buffers (double buffering)
EndDrawing :: () #foreign raylib;
// Initialize 2D mode with custom camera (2D)
BeginMode2D :: (camera: Camera2D) #foreign raylib;
// Ends 2D mode with custom camera
EndMode2D :: () #foreign raylib;
// Initializes 3D mode with custom camera (3D)
BeginMode3D :: (camera: Camera3D) #foreign raylib;
// Ends 3D mode and returns to default 2D orthographic mode
EndMode3D :: () #foreign raylib;
// Initializes render texture for drawing
BeginTextureMode :: (target: RenderTexture2D) #foreign raylib;
// Ends drawing to render texture
EndTextureMode :: () #foreign raylib;
// Begin custom shader drawing
BeginShaderMode :: (shader: Shader) #foreign raylib;
// End custom shader drawing (use default shader)
EndShaderMode :: () #foreign raylib;
// Begin blending mode (alpha, additive, multiplied)
BeginBlendMode :: (mode: s32) #foreign raylib;
// End blending mode (reset to default: alpha blending)
EndBlendMode :: () #foreign raylib;
// Begin scissor mode (define screen area for following drawing)
BeginScissorMode :: (x: s32, y: s32, width: s32, height: s32) #foreign raylib;
// End scissor mode
EndScissorMode :: () #foreign raylib;
// Begin stereo rendering (requires VR simulator)
BeginVrStereoMode :: (config: VrStereoConfig) #foreign raylib;
// End stereo rendering (requires VR simulator)
EndVrStereoMode :: () #foreign raylib;

//
// VR stereo config functions for VR simulator
//
// Load VR stereo config for VR simulator device parameters
LoadVrStereoConfig :: (device: VrDeviceInfo) -> VrStereoConfig #foreign raylib;
// Unload VR stereo config
UnloadVrStereoConfig :: (config: VrStereoConfig) #foreign raylib;

//
// Shader management functions
// NOTE: Shader functionality is not available on OpenGL 1.1
//
// Load shader from files and bind default locations
LoadShader :: (vsFileName: *u8, fsFileName: *u8) -> Shader #foreign raylib;
// Load shader from code strings and bind default locations
LoadShaderFromMemory :: (vsCode: *u8, fsCode: *u8) -> Shader #foreign raylib;
// Get shader uniform location
GetShaderLocation :: (shader: Shader, uniformName: *u8) -> s32 #foreign raylib;
// Get shader attribute location
GetShaderLocationAttrib :: (shader: Shader, attribName: *u8) -> s32 #foreign raylib;
// Set shader uniform value
SetShaderValue :: (shader: Shader, locIndex: s32, value: *void, uniformType: s32) #foreign raylib;
// Set shader uniform value vector
SetShaderValueV :: (shader: Shader, locIndex: s32, value: *void, uniformType: s32, count: s32) #foreign raylib;
// Set shader uniform value (matrix 4x4)
SetShaderValueMatrix :: (shader: Shader, locIndex: s32, mat: Matrix) #foreign raylib;
// Set shader uniform value for texture (sampler2d)
SetShaderValueTexture :: (shader: Shader, locIndex: s32, texture: Texture2D) #foreign raylib;
// Unload shader from GPU memory (VRAM)
UnloadShader :: (shader: Shader) #foreign raylib;

//
// Screen-space-related functions
//
// Returns a ray trace from mouse position
GetMouseRay :: (mousePosition: Vector2, camera: Camera) -> Ray #foreign raylib;
// Returns camera transform matrix (view matrix)
GetCameraMatrix :: (camera: Camera) -> Matrix #foreign raylib;
// Returns camera 2d transform matrix
GetCameraMatrix2D :: (camera: Camera2D) -> Matrix #foreign raylib;
// Returns the screen space position for a 3d world space position
GetWorldToScreen :: (position: Vector3, camera: Camera) -> Vector2 #foreign raylib;
// Returns size position for a 3d world space position
GetWorldToScreenEx :: (position: Vector3, camera: Camera, width: s32, height: s32) -> Vector2 #foreign raylib;
// Returns the screen space position for a 2d camera world space position
GetWorldToScreen2D :: (position: Vector2, camera: Camera2D) -> Vector2 #foreign raylib;
// Returns the world space position for a 2d camera screen space position
GetScreenToWorld2D :: (position: Vector2, camera: Camera2D) -> Vector2 #foreign raylib;

//
// Timing-related functions
//
// Set target FPS (maximum)
SetTargetFPS :: (fps: int) #foreign raylib;
// Returns current FPS
GetFPS :: () -> int #foreign raylib;
// Returns time in seconds for last frame drawn (delta time)
GetFrameTime :: () -> float #foreign raylib;
// Returns elapsed time in seconds since InitWindow()
GetTime :: () -> float64 #foreign raylib;

//
// Misc. functions
//
// Returns a random value between min and max (both included)
GetRandomValue :: (min: int, max: int) -> int #foreign raylib;
// Takes a screenshot of current screen (filename extension defines format)
TakeScreenshot :: (fileName: *u8) #foreign raylib;
// Setup init configuration flags (view FLAGS)
SetConfigFlags :: (flags: s32) #foreign raylib;

// Show trace log messages (LOG_DEBUG, LOG_INFO, LOG_WARNING, LOG_ERROR)
TraceLog :: (logLevel: s32, text: *u8, args: ..Any) #foreign raylib;
// Set the current threshold (minimum) log level
SetTraceLogLevel :: (logLevel: s32) #foreign raylib;
// Internal memory allocator
MemAlloc :: (size: int) -> *void #foreign raylib;
// Internal memory reallocator
MemRealloc :: (ptr: *void, size: int) -> *void #foreign raylib;
// Internal memory free
MemFree :: (ptr: *void) #foreign raylib;

//
// Set custom callbacks
// WARNING: Callbacks setup is intended for advance users
//
// Set custom trace log
SetTraceLogCallback :: (callback: TraceLogCallback) #foreign raylib;
// Set custom file binary data loader
SetLoadFileDataCallback :: (callback: LoadFileDataCallback) #foreign raylib;
// Set custom file binary data saver
SetSaveFileDataCallback :: (callback: SaveFileDataCallback) #foreign raylib;
// Set custom file text data loader
SetLoadFileTextCallback :: (callback: LoadFileTextCallback) #foreign raylib;
// Set custom file text data saver
SetSaveFileTextCallback :: (callback: SaveFileTextCallback) #foreign raylib;

//
// Files management functions
//
// Load file data as byte array (read)
LoadFileData :: (fileName: *u8, bytesRead: *s32) -> *u8 #foreign raylib;
// Unload file data allocated by LoadFileData()
UnloadFileData :: (data: *u8) #foreign raylib;
// Save data to file from byte array (write), returns true on success
SaveFileData :: (fileName: *u8, data: *void, bytesToWrite: u32) -> bool #foreign raylib;
// Load text data from file (read), returns a '\0' terminated string
LoadFileText :: (fileName: *u8) -> *u8 #foreign raylib;
// Unload file text data allocated by LoadFileText()
UnloadFileText :: (text: *u8) #foreign raylib;
// Save text data to file (write), string must be '\0' terminated, returns true on success
SaveFileText :: (fileName: *u8, text: *u8) -> bool #foreign raylib;
// Check if file exists
FileExists :: (fileName: *u8) -> bool #foreign raylib;
// Check if a directory path exists
DirectoryExists :: (dirPath: *u8) -> bool #foreign raylib;
// Check file extension (including point: .png, .wav)
IsFileExtension :: (fileName: *u8, ext: *u8) -> bool #foreign raylib;
// Get pointer to extension for a filename string (includes dot: ".png")
GetFileExtension :: (fileName: *u8) -> *u8 #foreign raylib;
// Get pointer to filename for a path string
GetFileName :: (filePath: *u8) -> *u8 #foreign raylib;
// Get filename string without extension (uses static string)
GetFileNameWithoutExt :: (filePath: *u8) -> *u8 #foreign raylib;
// Get full path for a given fileName with path (uses static string)
GetDirectoryPath :: (filePath: *u8) -> *u8 #foreign raylib;
// Get previous directory path for a given path (uses static string)
GetPrevDirectoryPath :: (dirPath: *u8) -> *u8 #foreign raylib;
// Get current working directory (uses static string)
GetWorkingDirectory :: () -> *u8 #foreign raylib;
// Get filenames in a directory path (memory should be freed)
GetDirectoryFiles :: (dirPath: *u8, count: *s32) -> **u8 #foreign raylib;
// Clear directory files paths buffers (free memory)
ClearDirectoryFiles :: () #foreign raylib;
// Change working directory, return true on success
ChangeDirectory :: (dir: *u8) -> bool #foreign raylib;
// Check if a file has been dropped into window
IsFileDropped :: () -> bool #foreign raylib;
// Get dropped files names (memory should be freed)
GetDroppedFiles :: (count: *s32) -> **u8 #foreign raylib;
// Clear dropped files paths buffer (free memory)
ClearDroppedFiles :: () #foreign raylib;
// Get file modification time (last write time)
GetFileModTime :: (fileName: *u8) -> s64 #foreign raylib;

// Compress data (DEFLATE algorithm)
CompressData :: (data: *u8, dataLength: s32, compDataLength: *s32) -> *u8 #foreign raylib;
// Decompress data (DEFLATE algorithm)
DecompressData :: (compData: *u8, compDataLength: s32, dataLength: *s32) -> *u8 #foreign raylib;

//
// Persistent storage management
//
// Save integer value to storage file (to defined position), returns true on success
SaveStorageValue :: (position: s32, value: s32) -> bool #foreign raylib;
// Load integer value from storage file (from defined position)
LoadStorageValue :: (position: s32) -> int #foreign raylib;

// Open URL with default system browser (if available)
OpenURL :: (url: *u8) #foreign raylib;

//------------------------------------------------------------------------------------
// Input Handling Functions (Module: core)
//------------------------------------------------------------------------------------

//
// Input-related functions: keyboard
//
// Detect if a key has been pressed once
IsKeyPressed :: (key: KeyboardKey) -> bool #foreign raylib;
// Detect if a key is being pressed
IsKeyDown :: (key: KeyboardKey) -> bool #foreign raylib;
// Detect if a key has been released once
IsKeyReleased :: (key: KeyboardKey) -> bool #foreign raylib;
// Detect if a key is NOT being pressed
IsKeyUp :: (key: KeyboardKey) -> bool #foreign raylib;
// Set a custom key to exit program (default is ESC)
SetExitKey :: (key: KeyboardKey) #foreign raylib;
// Get key pressed (keycode), call it multiple times for keys queued
GetKeyPressed :: () -> KeyboardKey #foreign raylib;
// Get char pressed (unicode), call it multiple times for chars queued
GetCharPressed :: () -> KeyboardKey #foreign raylib;

//
// Input-related functions: gamepads
//
// Detect if a gamepad is available
IsGamepadAvailable :: (gamepad: s32) -> bool #foreign raylib;
// Check gamepad name (if available)
IsGamepadName :: (gamepad: s32, name: *u8) -> bool #foreign raylib;
// Return gamepad internal name id
GetGamepadName :: (gamepad: s32) -> *u8 #foreign raylib;
// Detect if a gamepad button has been pressed once
IsGamepadButtonPressed :: (gamepad: s32, button: GamepadButton) -> bool #foreign raylib;
// Detect if a gamepad button is being pressed
IsGamepadButtonDown :: (gamepad: s32, button: GamepadButton) -> bool #foreign raylib;
// Detect if a gamepad button has been released once
IsGamepadButtonReleased :: (gamepad: s32, button: GamepadButton) -> bool #foreign raylib;
// Detect if a gamepad button is NOT being pressed
IsGamepadButtonUp :: (gamepad: s32, button: GamepadButton) -> bool #foreign raylib;
// Get the last gamepad button pressed
GetGamepadButtonPressed :: () -> s32 #foreign raylib;
// Return gamepad axis count for a gamepad
GetGamepadAxisCount :: (gamepad: s32) -> s32 #foreign raylib;
// Return axis movement value for a gamepad axis
GetGamepadAxisMovement :: (gamepad: s32, axis: GamepadAxis) -> float32 #foreign raylib;
// Set internal gamepad mappings (SDL_GameControllerDB)
SetGamepadMappings :: (mappings: *u8) -> s32 #foreign raylib;

//
// Input-related functions: mouse
//
// Detect if a mouse button has been pressed once
IsMouseButtonPressed :: (button: MouseButton) -> bool #foreign raylib;
// Detect if a mouse button is being pressed
IsMouseButtonDown :: (button: MouseButton) -> bool #foreign raylib;
// Detect if a mouse button has been released once
IsMouseButtonReleased :: (button: MouseButton) -> bool #foreign raylib;
// Detect if a mouse button is NOT being pressed
IsMouseButtonUp :: (button: MouseButton) -> bool #foreign raylib;
// Returns mouse position X
GetMouseX :: () -> s32 #foreign raylib;
// Returns mouse position Y
GetMouseY :: () -> s32 #foreign raylib;
// Returns mouse position XY
GetMousePosition :: () -> Vector2 #foreign raylib;
// Set mouse position XY
SetMousePosition :: (x: s32, y: s32) #foreign raylib;
// Set mouse offset
SetMouseOffset :: (offsetX: s32, offsetY: s32) #foreign raylib;
// Set mouse scaling
SetMouseScale :: (scaleX: float32, scaleY: float32) #foreign raylib;
// Returns mouse wheel movement Y
GetMouseWheelMove :: () -> float32 #foreign raylib;
// Set mouse cursor
SetMouseCursor :: (cursor: s32) #foreign raylib;

//
// Input-related functions: touch
//
// Returns touch position X for touch point 0 (relative to screen size)
GetTouchX :: () -> s32 #foreign raylib;
// Returns touch position Y for touch point 0 (relative to screen size)
GetTouchY :: () -> s32 #foreign raylib;
// Returns touch position XY for a touch point index (relative to screen size)
GetTouchPosition :: (index: s32) -> Vector2 #foreign raylib;

//------------------------------------------------------------------------------------
// Gestures and Touch Handling Functions (Module: gestures)
//------------------------------------------------------------------------------------
// Enable a set of gestures using flags
SetGesturesEnabled :: (flags: u32) #foreign raylib;
// Check if a gesture have been detected
IsGestureDetected :: (gesture: s32) -> bool #foreign raylib;
// Get latest detected gesture
GetGestureDetected :: () -> s32 #foreign raylib;
// Get touch points count
GetTouchPointsCount :: () -> s32 #foreign raylib;
// Get gesture hold time in milliseconds
GetGestureHoldDuration :: () -> float32 #foreign raylib;
// Get gesture drag vector
GetGestureDragVector :: () -> Vector2 #foreign raylib;
// Get gesture drag angle
GetGestureDragAngle :: () -> float32 #foreign raylib;
// Get gesture pinch delta
GetGesturePinchVector :: () -> Vector2 #foreign raylib;
// Get gesture pinch angle
GetGesturePinchAngle :: () -> float32 #foreign raylib;

//------------------------------------------------------------------------------------
// Camera System Functions (Module: camera)
//------------------------------------------------------------------------------------
// Set camera mode (multiple camera modes available)
SetCameraMode :: (camera: Camera, mode: CameraMode) #foreign raylib;
// Update camera position for selected mode
UpdateCamera :: (camera: *Camera) #foreign raylib;

// Set camera pan key to combine with mouse movement (free camera)
SetCameraPanControl :: (keyPan: s32) #foreign raylib;
// Set camera alt key to combine with mouse movement (free camera)
SetCameraAltControl :: (keyAlt: s32) #foreign raylib;
// Set camera smooth zoom key to combine with mouse (free camera)
SetCameraSmoothZoomControl :: (keySmoothZoom: s32) #foreign raylib;
// Set camera move controls (1st person and 3rd person cameras)
SetCameraMoveControls :: (keyFront: s32, keyBack: s32, keyRight: s32, keyLeft: s32, keyUp: s32, keyDown: s32) #foreign raylib;

//------------------------------------------------------------------------------------
// Basic Shapes Drawing Functions (Module: shapes)
//------------------------------------------------------------------------------------
// Set texture and rectangle to be used on shapes drawing
// NOTE: It can be useful when using basic shapes and one single font,
// defining a font char white rectangle would allow drawing everything in a single draw call
SetShapesTexture :: (texture: Texture2D, source: Rectangle) #foreign raylib;

//
// Basic shapes drawing functions
//
// Draw a pixel
DrawPixel :: (posX: s32, posY: s32, color: Color) #foreign raylib;
// Draw a pixel (Vector version)
DrawPixelV :: (position: Vector2, color: Color) #foreign raylib;
// Draw a line
DrawLine :: (startPosX: s32, startPosY: s32, endPosX: s32, endPosY: s32, color: Color) #foreign raylib;
// Draw a line (Vector version)
DrawLineV :: (startPos: Vector2, endPos: Vector2, color: Color) #foreign raylib;
// Draw a line defining thickness
DrawLineEx :: (startPos: Vector2, endPos: Vector2, thick: float32, color: Color) #foreign raylib;
// Draw a line using cubic-bezier curves in-out
DrawLineBezier :: (startPos: Vector2, endPos: Vector2, thick: float32, color: Color) #foreign raylib;
// Draw line using quadratic bezier curves with a control point
DrawLineBezierQuad :: (startPos: Vector2, endPos: Vector2, controlPos: Vector2, thick: float32, color: Color) #foreign raylib;
// Draw lines sequence
DrawLineStrip :: (points: *Vector2, pointsCount: s32, color: Color) #foreign raylib;
// Draw a color-filled circle
DrawCircle :: (centerX: s32, centerY: s32, radius: float32, color: Color) #foreign raylib;
// Draw a piece of a circle
DrawCircleSector :: (center: Vector2, radius: float32, startAngle: float32, endAngle: float32, segments: s32, color: Color) #foreign raylib;
// Draw circle sector outline
DrawCircleSectorLines :: (center: Vector2, radius: float32, startAngle: float32, endAngle: float32, segments: s32, color: Color) #foreign raylib;
// Draw a gradient-filled circle
DrawCircleGradient :: (centerX: s32, centerY: s32, radius: float32, color1: Color, color2: Color) #foreign raylib;
// Draw a color-filled circle (Vector version)
DrawCircleV :: (center: Vector2, radius: float32, color: Color) #foreign raylib;
// Draw circle outline
DrawCircleLines :: (centerX: s32, centerY: s32, radius: float32, color: Color) #foreign raylib;
// Draw ellipse
DrawEllipse :: (centerX: s32, centerY: s32, radiusH: float32, radiusV: float32, color: Color) #foreign raylib;
// Draw ellipse outline
DrawEllipseLines :: (centerX: s32, centerY: s32, radiusH: float32, radiusV: float32, color: Color) #foreign raylib;
// Draw ring
DrawRing :: (center: Vector2, innerRadius: float32, outerRadius: float32, startAngle: float32, endAngle: float32, segments: s32, color: Color) #foreign raylib;
// Draw ring outline
DrawRingLines :: (center: Vector2, innerRadius: float32, outerRadius: float32, startAngle: float32, endAngle: float32, segments: s32, color: Color) #foreign raylib;
// Draw a color-filled rectangle
DrawRectangle :: (posX: s32, posY: s32, width: s32, height: s32, color: Color) #foreign raylib;
// Draw a color-filled rectangle (Vector version)
DrawRectangleV :: (position: Vector2, size: Vector2, color: Color) #foreign raylib;
// Draw a color-filled rectangle
DrawRectangleRec :: (rec: Rectangle, color: Color) #foreign raylib;
// Draw a color-filled rectangle with pro parameters
DrawRectanglePro :: (rec: Rectangle, origin: Vector2, rotation: float32, color: Color) #foreign raylib;
// Draw a vertical-gradient-filled rectangle
DrawRectangleGradientV :: (posX: s32, posY: s32, width: s32, height: s32, color1: Color, color2: Color) #foreign raylib;
// Draw a horizontal-gradient-filled rectangle
DrawRectangleGradientH :: (posX: s32, posY: s32, width: s32, height: s32, color1: Color, color2: Color) #foreign raylib;
// Draw a gradient-filled rectangle with custom vertex colors
DrawRectangleGradientEx :: (rec: Rectangle, col1: Color, col2: Color, col3: Color, col4: Color) #foreign raylib;
// Draw rectangle outline
DrawRectangleLines :: (posX: s32, posY: s32, width: s32, height: s32, color: Color) #foreign raylib;
// Draw rectangle outline with extended parameters
DrawRectangleLinesEx :: (rec: Rectangle, lineThick: s32, color: Color) #foreign raylib;
// Draw rectangle with rounded edges
DrawRectangleRounded :: (rec: Rectangle, roundness: float32, segments: s32, color: Color) #foreign raylib;
// Draw rectangle with rounded edges outline
DrawRectangleRoundedLines :: (rec: Rectangle, roundness: float32, segments: s32, lineThick: s32, color: Color) #foreign raylib;
// Draw a color-filled triangle (vertex in counter-clockwise order!)
DrawTriangle :: (v1: Vector2, v2: Vector2, v3: Vector2, color: Color) #foreign raylib;
// Draw triangle outline (vertex in counter-clockwise order!)
DrawTriangleLines :: (v1: Vector2, v2: Vector2, v3: Vector2, color: Color) #foreign raylib;
// Draw a triangle fan defined by points (first vertex is the center)
DrawTriangleFan :: (points: *Vector2, pointsCount: s32, color: Color) #foreign raylib;
// Draw a triangle strip defined by points
DrawTriangleStrip :: (points: *Vector2, pointsCount: s32, color: Color) #foreign raylib;
// Draw a regular polygon (Vector version)
DrawPoly :: (center: Vector2, sides: s32, radius: float32, rotation: float32, color: Color) #foreign raylib;
// Draw a polygon outline of n sides
DrawPolyLines :: (center: Vector2, sides: s32, radius: float32, rotation: float32, color: Color) #foreign raylib;

//
// Basic shapes collision detection functions
//
// Check collision between two rectangles
CheckCollisionRecs :: (rec1: Rectangle, rec2: Rectangle) -> bool #foreign raylib;
// Check collision between two circles
CheckCollisionCircles :: (center1: Vector2, radius1: float32, center2: Vector2, radius2: float32) -> bool #foreign raylib;
// Check collision between circle and rectangle
CheckCollisionCircleRec :: (center: Vector2, radius: float32, rec: Rectangle) -> bool #foreign raylib;
// Check if point is inside rectangle
CheckCollisionPointRec :: (point: Vector2, rec: Rectangle) -> bool #foreign raylib;
// Check if point is inside circle
CheckCollisionPointCircle :: (point: Vector2, center: Vector2, radius: float32) -> bool #foreign raylib;
// Check if point is inside a triangle
CheckCollisionPointTriangle :: (point: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) -> bool #foreign raylib;
// Check the collision between two lines defined by two points each, returns collision point by reference
CheckCollisionLines :: (startPos1: Vector2, endPos1: Vector2, startPos2: Vector2, endPos2: Vector2, collisionPoint: *Vector2) -> bool #foreign raylib;
// Get collision rectangle for two rectangles collision
GetCollisionRec :: (rec1: Rectangle, rec2: Rectangle) -> Rectangle #foreign raylib;

//------------------------------------------------------------------------------------
// Texture Loading and Drawing Functions (Module: textures)
//------------------------------------------------------------------------------------

//
// Image loading functions
// NOTE: This functions do not require GPU access
//
// Load image from file into CPU memory (RAM)
LoadImage :: (fileName: *u8) -> Image #foreign raylib;
// Load image from RAW file data
LoadImageRaw :: (fileName: *u8, width: s32, height: s32, format: s32, headerSize: s32) -> Image #foreign raylib;
// Load image sequence from file (frames appended to image.data)
LoadImageAnim :: (fileName: *u8, frames: *s32) -> Image #foreign raylib;
// Load image from memory buffer, fileType refers to extension: i.e. ".png"
LoadImageFromMemory :: (fileType: *u8, fileData: *u8, dataSize: s32) -> Image #foreign raylib;
// Unload image from CPU memory (RAM)
UnloadImage :: (image: Image) #foreign raylib;
// Export image data to file, returns true on success
ExportImage :: (image: Image, fileName: *u8) -> bool #foreign raylib;
// Export image as code file defining an array of bytes, returns true on success
ExportImageAsCode :: (image: Image, fileName: *u8) -> bool #foreign raylib;

//
// Image generation functions
//
// Generate image: plain color
GenImageColor :: (width: s32, height: s32, color: Color) -> Image #foreign raylib;
// Generate image: vertical gradient
GenImageGradientV :: (width: s32, height: s32, top: Color, bottom: Color) -> Image #foreign raylib;
// Generate image: horizontal gradient
GenImageGradientH :: (width: s32, height: s32, left: Color, right: Color) -> Image #foreign raylib;
// Generate image: radial gradient
GenImageGradientRadial :: (width: s32, height: s32, density: float32, inner: Color, outer: Color) -> Image #foreign raylib;
// Generate image: checked
GenImageChecked :: (width: s32, height: s32, checksX: s32, checksY: s32, col1: Color, col2: Color) -> Image #foreign raylib;
// Generate image: white noise
GenImageWhiteNoise :: (width: s32, height: s32, factor: float32) -> Image #foreign raylib;
// Generate image: perlin noise
GenImagePerlinNoise :: (width: s32, height: s32, offsetX: s32, offsetY: s32, scale: float32) -> Image #foreign raylib;
// Generate image: cellular algorithm. Bigger tileSize means bigger cells
GenImageCellular :: (width: s32, height: s32, tileSize: s32) -> Image #foreign raylib;

//
// Image manipulation functions
//
// Create an image duplicate (useful for transformations)
ImageCopy :: (image: *Image) -> Image #foreign raylib;
// Create an image from another image piece
ImageFromImage :: (image: *Image, rec: Rectangle) -> Image #foreign raylib;
// Create an image from text (default font)
ImageText :: (text: *u8, fontSize: s32, color: Color) -> Image #foreign raylib;
// Create an image from text (custom sprite font)
ImageTextEx :: (font: Font, text: *u8, fontSize: float32, spacing: float32, tint: Color) -> Image #foreign raylib;
// Convert image data to desired format
ImageFormat :: (image: *Image, newFormat: s32) #foreign raylib;
// Convert image to POT (power-of-two)
ImageToPOT :: (image: *Image, fill: Color) #foreign raylib;
// Crop an image to a defined rectangle
ImageCrop :: (image: *Image, crop: Rectangle) #foreign raylib;
// Crop image depending on alpha value
ImageAlphaCrop :: (image: *Image, threshold: float32) #foreign raylib;
// Clear alpha channel to desired color
ImageAlphaClear :: (image: *Image, color: Color, threshold: float32) #foreign raylib;
// Apply alpha mask to image
ImageAlphaMask :: (image: *Image, alphaMask: Image) #foreign raylib;
// Premultiply alpha channel
ImageAlphaPremultiply :: (image: *Image) #foreign raylib;
// Resize image (Bicubic scaling algorithm)
ImageResize :: (image: *Image, newWidth: s32, newHeight: s32) #foreign raylib;
// Resize image (Nearest-Neighbor scaling algorithm)
ImageResizeNN :: (image: *Image, newWidth: s32,newHeight: s32) #foreign raylib;
// Resize canvas and fill with color
ImageResizeCanvas :: (image: *Image, newWidth: s32, newHeight: s32, offsetX: s32, offsetY: s32, fill: Color) #foreign raylib;
// Generate all mipmap levels for a provided image
ImageMipmaps :: (image: *Image) #foreign raylib;
// Dither image data to 16bpp or lower (Floyd-Steinberg dithering)
ImageDither :: (image: *Image, rBpp: s32, gBpp: s32, bBpp: s32, aBpp: s32) #foreign raylib;
// Flip image vertically
ImageFlipVertical :: (image: *Image) #foreign raylib;
// Flip image horizontally
ImageFlipHorizontal :: (image: *Image) #foreign raylib;
// Rotate image clockwise 90deg
ImageRotateCW :: (image: *Image) #foreign raylib;
// Rotate image counter-clockwise 90deg
ImageRotateCCW :: (image: *Image) #foreign raylib;
// Modify image color: tint
ImageColorTint :: (image: *Image, color: Color) #foreign raylib;
// Modify image color: invert
ImageColorInvert :: (image: *Image) #foreign raylib;
// Modify image color: grayscale
ImageColorGrayscale :: (image: *Image) #foreign raylib;
// Modify image color: contrast (-100 to 100)
ImageColorContrast :: (image: *Image, contrast: float32) #foreign raylib;
// Modify image color: brightness (-255 to 255)
ImageColorBrightness :: (image: *Image, brightness: s32) #foreign raylib;
// Modify image color: replace color
ImageColorReplace :: (image: *Image, color: Color, replace: Color) #foreign raylib;
// Load color data from image as a Color array (RGBA - 32bit)
LoadImageColors :: (image: *Image) -> *Color #foreign raylib;
// Load colors palette from image as a Color array (RGBA - 32bit)
LoadImagePalette :: (image: *Image, maxPaletteSize: s32, colorsCount: *s32) -> *Color #foreign raylib;
// Unload color data loaded with LoadImageColors()
UnloadImageColors :: (colors: *Color) #foreign raylib;
// Unload colors palette loaded with LoadImagePalette()
UnloadImagePalette :: (colors: *Color) #foreign raylib;
// Get image alpha border rectangle
GetImageAlphaBorder :: (image: *Image, threshold: float32) -> Rectangle #foreign raylib;

//
// Image drawing functions
// NOTE: Image software-rendering functions (CPU)
//
// Clear image background with given color
ImageClearBackground :: (dst: *Image, color: Color) #foreign raylib;
// Draw pixel within an image
ImageDrawPixel :: (dst: *Image, posX: s32, posY: s32, color: Color) #foreign raylib;
// Draw pixel within an image (Vector version)
ImageDrawPixelV :: (dst: *Image, position: Vector2, color: Color) #foreign raylib;
// Draw line within an image
ImageDrawLine :: (dst: *Image, startPosX: s32, startPosY: s32, endPosX: s32, endPosY: s32, color: Color) #foreign raylib;
// Draw line within an image (Vector version)
ImageDrawLineV :: (dst: *Image, start: Vector2, end: Vector2, color: Color) #foreign raylib;
// Draw circle within an image
ImageDrawCircle :: (dst: *Image, centerX: s32, centerY: s32, radius: s32, color: Color) #foreign raylib;
// Draw circle within an image (Vector version)
ImageDrawCircleV :: (dst: *Image, center: Vector2, radius: s32, color: Color) #foreign raylib;
// Draw rectangle within an image
ImageDrawRectangle :: (dst: *Image, posX: s32, posY: s32, width: s32, height: s32, color: Color) #foreign raylib;
// Draw rectangle within an image (Vector version)
ImageDrawRectangleV :: (dst: *Image, position: Vector2, size: Vector2, color: Color) #foreign raylib;
// Draw rectangle within an image
ImageDrawRectangleRec :: (dst: *Image, rec: Rectangle, color: Color) #foreign raylib;
// Draw rectangle lines within an image
ImageDrawRectangleLines :: (dst: *Image, rec: Rectangle, thick: s32, color: Color) #foreign raylib;
// Draw a source image within a destination image (tint applied to source)
ImageDraw :: (dst: *Image, src: Image, srcRec: Rectangle, dstRec: Rectangle, tint: Color) #foreign raylib;
// Draw text (using default font) within an image (destination)
ImageDrawText :: (dst: *Image, text: *u8, posX: s32, posY: s32, fontSize: s32, color: Color) #foreign raylib;
// Draw text (custom sprite font) within an image (destination)
ImageDrawTextEx :: (dst: *Image, font: Font, text: *u8, position: Vector2, fontSize: float32, spacing: float32, tint: Color) #foreign raylib;

//
// Texture loading functions
// NOTE: These functions require GPU access
//
// Load texture from file into GPU memory (VRAM)
LoadTexture :: (fileName: *u8) -> Texture2D #foreign raylib;
// Load texture from image data
LoadTextureFromImage :: (image: Image) -> Texture2D #foreign raylib;
// Load cubemap from image, multiple image cubemap layouts supported
LoadTextureCubemap :: (image: Image, layout: s32) -> TextureCubemap #foreign raylib;
// Load texture for rendering (framebuffer)
LoadRenderTexture :: (width: s32, height: s32) -> RenderTexture2D #foreign raylib;
// Unload texture from GPU memory (VRAM)
UnloadTexture :: (texture: Texture2D) #foreign raylib;
// Unload render texture from GPU memory (VRAM)
UnloadRenderTexture :: (target: RenderTexture2D) #foreign raylib;
// Update GPU texture with new data
UpdateTexture :: (texture: Texture2D, pixels: *void) #foreign raylib;
// Update GPU texture rectangle with new data
UpdateTextureRec :: (texture: Texture2D, rec: Rectangle, pixels: *void) #foreign raylib;
// Get pixel data from GPU texture and return an Image
GetTextureData :: (texture: Texture2D) -> Image #foreign raylib;
// Get pixel data from screen buffer and return an Image (screenshot)
GetScreenData :: () -> Image #foreign raylib;

//
// Texture configuration functions
//
// Generate GPU mipmaps for a texture
GenTextureMipmaps :: (texture: *Texture2D) #foreign raylib;
// Set texture scaling filter mode
SetTextureFilter :: (texture: Texture2D, filter: s32) #foreign raylib;
// Set texture wrapping mode
SetTextureWrap :: (texture: Texture2D, wrap: s32) #foreign raylib;

//
// Texture drawing functions
//
// Draw a Texture2D
DrawTexture :: (texture: Texture2D, posX: int, posY: int, tint: Color) #foreign raylib;
// Draw a Texture2D with position defined as Vector2
DrawTextureV :: (texture: Texture2D, position: Vector2, tint: Color) #foreign raylib;
// Draw a Texture2D with extended parameters
DrawTextureEx :: (texture: Texture2D, position: Vector2, rotation: float, scale: float, tint: Color) #foreign raylib;
// Draw a part of a texture defined by a rectangle
DrawTextureRec :: (texture: Texture2D, source: Rectangle, position: Vector2, tint: Color) #foreign raylib;
// Draw texture quad with tiling and offset parameters
DrawTextureQuad :: (texture: Texture2D, tiling: Vector2, offset: Vector2, quad: Rectangle, tint: Color) #foreign raylib;
// Draw part of a texture (defined by a rectangle) with rotation and scale tiled into dest.
DrawTextureTiled :: (texture: Texture2D, source: Rectangle, dest: Rectangle, origin: Vector2, rotation: float32, scale: float32, tint: Color) #foreign raylib;
// Draw a part of a texture defined by a rectangle with 'pro' parameters
DrawTexturePro :: (texture: Texture2D, source: Rectangle, dest: Rectangle, origin: Vector2, rotation: float32, tint: Color) #foreign raylib;
// Draws a texture (or part of it) that stretches or shrinks nicely
DrawTextureNPatch :: (texture: Texture2D, nPatchInfo: NPatchInfo, dest: Rectangle, origin: Vector2, rotation: float32, tint: Color) #foreign raylib;
// Draw a textured polygon
DrawTexturePoly :: (texture: Texture2D, center: Vector2, points: *Vector2, texcoords: *Vector2, pointsCount: s32, tint: Color) #foreign raylib;

//
// Color/pixel related functions
//
// Returns color with alpha applied, alpha goes from 0.0f to 1.0f
Fade :: (color: Color, alpha: float32) -> Color #foreign raylib;
// Returns hexadecimal value for a Color
ColorToInt :: (color: Color) -> s32 #foreign raylib;
// Returns Color normalized as float [0..1]
ColorNormalize :: (color: Color) -> Vector4 #foreign raylib;
// Returns Color from normalized values [0..1]
ColorFromNormalized :: (normalized: Vector4) -> Color #foreign raylib;
// Returns HSV values for a Color, hue [0..360], saturation/value [0..1]
ColorToHSV :: (color: Color) -> Vector3 #foreign raylib;
// Returns a Color from HSV values, hue [0..360], saturation/value [0..1]
ColorFromHSV :: (hue: float32, saturation: float32, value: float32) -> Color #foreign raylib;
// Returns color with alpha applied, alpha goes from 0.0f to 1.0f
ColorAlpha :: (color: Color, alpha: float32) -> Color #foreign raylib;
// Returns src alpha-blended into dst color with tint
ColorAlphaBlend :: (dst: Color, src: Color, tint: Color) -> Color #foreign raylib;
// Get Color structure from hexadecimal value
GetColor :: (hexValue: s32) -> Color #foreign raylib;
// Get Color from a source pixel pointer of certain format
GetPixelColor :: (srcPtr: *void, format: s32) -> Color #foreign raylib;
// Set color formatted into destination pixel pointer
SetPixelColor :: (dstPtr: *void, color: Color, format: s32) #foreign raylib;
// Get pixel data size in bytes for certain format
GetPixelDataSize :: (width: s32, height: s32, format: s32) -> s32 #foreign raylib;

//------------------------------------------------------------------------------------
// Font Loading and Text Drawing Functions (Module: text)
//------------------------------------------------------------------------------------

//
// Font loading/unloading functions
//
// Get the default Font
GetFontDefault :: () -> Font #foreign raylib;
// Load font from file into GPU memory (VRAM)
LoadFont :: (fileName: *u8) -> Font #foreign raylib;
// Load font from file with extended parameters
LoadFontEx :: (fileName: *u8, fontSize: s32, fontChars: *s32, charsCount: s32) -> Font #foreign raylib;
// Load font from Image (XNA style)
LoadFontFromImage :: (image: Image, key: Color, firstChar: s32) -> Font #foreign raylib;
// Load font from memory buffer, fileType refers to extension: i.e. ".ttf"
LoadFontFromMemory :: (fileType: *u8, fileData: *u8, dataSize: s32, fontSize: s32, fontChars: *s32, charsCount: s32) -> Font #foreign raylib;
// Load font data for further use
LoadFontData :: (fileData: *u8, dataSize: s32, fontSize: s32, fontChars: *s32, charsCount: s32, type: s32) -> *CharInfo #foreign raylib;
// Generate image font atlas using chars info
GenImageFontAtlas :: (chars: *CharInfo, recs: **Rectangle, charsCount: s32, fontSize: s32, padding: s32, packMethod: s32) -> Image #foreign raylib;
// Unload font chars info data (RAM)
UnloadFontData :: (chars: *CharInfo, charsCount: s32) #foreign raylib;
// Unload Font from GPU memory (VRAM)
UnloadFont :: (font: Font) #foreign raylib;

//
// Text drawing functions
//
// Draw current FPS
DrawFPS :: (posX: s32, posY: s32) #foreign raylib;
// Draw text (using default font)
DrawText :: (text: *u8, posX: s32, posY: s32, fontSize: s32, color: Color) #foreign raylib;
// Draw text using font and additional parameters
DrawTextEx :: (font: Font, text: *u8, position: Vector2, fontSize: float32, spacing: float32, tint: Color) #foreign raylib;
// Draw text using font inside rectangle limits
DrawTextRec :: (font: Font, text: *u8, rec: Rectangle, fontSize: float32, spacing: float32, wordWrap: bool, tint: Color) #foreign raylib;
// Draw text using font inside rectangle limits with support for text selection
DrawTextRecEx :: (font: Font, text: *u8, rec: Rectangle, fontSize: float32, spacing: float32, wordWrap: bool, tint: Color,
                  selectStart: s32, selectLength: s32, selectTint: Color, selectBackTint: Color) #foreign raylib;
// Draw one character (codepoint)
DrawTextCodepoint :: (font: Font, codepoint: s32, position: Vector2, fontSize: float32, tint: Color) #foreign raylib;

//
// Text misc. functions
//
// Measure string width for default font
MeasureText :: (text: *u8, fontSize: s32) -> s32 #foreign raylib;
// Measure string size for Font
MeasureTextEx :: (font: Font, text: *u8, fontSize: float32, spacing: float32) -> Vector2 #foreign raylib;
// Get index position for a unicode character on font
GetGlyphIndex :: (font: Font, codepoint: s32) -> s32 #foreign raylib;

//
// Text strings management functions (no utf8 strings, only byte chars)
// NOTE: Some strings allocate memory internally for returned strings, just be careful!
//
// Copy one string to another, returns bytes copied
TextCopy :: (dst: *u8, src: *u8) -> s32 #foreign raylib;
// Check if two text string are equal
TextIsEqual :: (text1: *u8, text2: *u8) -> bool #foreign raylib;
// Get text length, checks for '\0' ending
TextLength :: (text: *u8) -> u32 #foreign raylib;
// Text formatting with variables (sprintf style)
TextFormat :: (text: *u8, args: ..Any) -> *u8 #foreign raylib;
// Get a piece of a text string
TextSubtext :: (text: *u8, position: s32, length: s32) -> *u8 #foreign raylib;
// Replace text string (memory must be freed!)
TextReplace :: (text: *u8, replace: *u8, by: *u8) -> *u8 #foreign raylib;
// Insert text in a position (memory must be freed!)
TextInsert :: (text: *u8, insert: *u8, position: s32) -> *u8 #foreign raylib;
// Join text strings with delimiter
TextJoin :: (textList: **u8, count: s32, delimiter: *u8) -> *u8 #foreign raylib;
// Split text into multiple strings
TextSplit :: (text: *u8, delimiter: u8, count: *s32) -> **u8 #foreign raylib;
// Append text at specific position and move cursor!
TextAppend :: (text: *u8, append: *u8, position: *s32) #foreign raylib;
// Find first text occurrence within a string
TextFindIndex :: (text: *u8, find: *u8) -> s32 #foreign raylib;
// Get upper case version of provided string
TextToUpper :: (text: *u8) -> *u8 #foreign raylib;
// Get lower case version of provided string
TextToLower :: (text: *u8) -> *u8 #foreign raylib;
// Get Pascal case notation version of provided string
TextToPascal :: (text: *u8) -> *u8 #foreign raylib;
// Get integer value from text (negative values not supported)
TextToInteger :: (text: *u8) -> s32 #foreign raylib;
// Encode text codepoint into utf8 text (memory must be freed!)
TextToUtf8 :: (codepoints: *s32, length: s32) -> *u8 #foreign raylib;

//
// UTF8 text strings management functions
//
// Get all codepoints in a string, codepoints count returned by parameters
GetCodepoints :: (text: *u8, count: *s32) -> s32 #foreign raylib;
// Get total number of characters (codepoints) in a UTF8 encoded string
GetCodepointsCount :: (text: *u8) -> s32 #foreign raylib;
// Returns next codepoint in a UTF8 encoded string #foreign raylib; 0x3f('?') is returned on failure
GetNextCodepoint :: (text: *u8, bytesProcessed: *s32) -> s32 #foreign raylib;
// Encode codepoint into utf8 text (char array length returned as parameter)
CodepointToUtf8 :: (codepoint: s32, byteLength: *s32) -> *u8 #foreign raylib;

//------------------------------------------------------------------------------------
// Basic 3d Shapes Drawing Functions (Module: models)
//------------------------------------------------------------------------------------

//
// Basic geometric 3D shapes drawing functions
//
// Draw a line in 3D world space
DrawLine3D :: (startPos: Vector3, endPos: Vector3, color: Color) #foreign raylib;
// Draw a point in 3D space, actually a small line
DrawPoint3D :: (position: Vector3, color: Color) #foreign raylib;
// Draw a circle in 3D world space
DrawCircle3D :: (center: Vector3, radius: float32, rotationAxis: Vector3, rotationAngle: float32, color: Color) #foreign raylib;
// Draw a color-filled triangle (vertex in counter-clockwise order!)
DrawTriangle3D :: (v1: Vector3, v2: Vector3, v3: Vector3, color: Color) #foreign raylib;
// Draw a triangle strip defined by points
DrawTriangleStrip3D :: (points: *Vector3, pointsCount: s32, color: Color) #foreign raylib;
// Draw cube
DrawCube :: (position: Vector3, width: float32, height: float32, length: float32, color: Color) #foreign raylib;
// Draw cube (Vector version)
DrawCubeV :: (position: Vector3, size: Vector3, color: Color) #foreign raylib;
// Draw cube wires
DrawCubeWires :: (position: Vector3, width: float32, height: float32, length: float32, color: Color) #foreign raylib;
// Draw cube wires (Vector version)
DrawCubeWiresV :: (position: Vector3, size: Vector3, color: Color) #foreign raylib;
// Draw cube textured
DrawCubeTexture :: (texture: Texture2D, position: Vector3, width: float32, height: float32, length: float32, color: Color) #foreign raylib;
// Draw sphere
DrawSphere :: (centerPos: Vector3, radius: float32, color: Color) #foreign raylib;
// Draw sphere with extended parameters
DrawSphereEx :: (centerPos: Vector3, radius: float32, rings: s32, slices: s32, color: Color) #foreign raylib;
// Draw sphere wires
DrawSphereWires :: (centerPos: Vector3, radius: float32, rings: s32, slices: s32, color: Color) #foreign raylib;
// Draw a cylinder/cone
DrawCylinder :: (position: Vector3, radiusTop: float32, radiusBottom: float32, height: float32, slices: s32, color: Color) #foreign raylib;
// Draw a cylinder/cone wires
DrawCylinderWires :: (position: Vector3, radiusTop: float32, radiusBottom: float32, height: float32, slices: s32, color: Color) #foreign raylib;
// Draw a plane XZ
DrawPlane :: (centerPos: Vector3, size: Vector2, color: Color) #foreign raylib;
// Draw a ray line
DrawRay :: (ray: Ray, color: Color) #foreign raylib;
// Draw a grid (centered at (0, 0, 0))
DrawGrid :: (slices: s32, spacing: float32) #foreign raylib;

//------------------------------------------------------------------------------------
// Model 3d Loading and Drawing Functions (Module: models)
//------------------------------------------------------------------------------------

//
// Model loading/unloading functions
//
// Load model from files (meshes and materials)
LoadModel :: (fileName: *u8) -> Model #foreign raylib;
// Load model from generated mesh (default material)
LoadModelFromMesh :: (mesh: Mesh) -> Model #foreign raylib;
// Unload model (including meshes) from memory (RAM and/or VRAM)
UnloadModel :: (model: Model) #foreign raylib;
// Unload model (but not meshes) from memory (RAM and/or VRAM)
UnloadModelKeepMeshes :: (model: Model) #foreign raylib;

//
// Mesh loading/unloading functions
//
// Upload mesh vertex data in GPU and provide VAO/VBO ids
UploadMesh :: (mesh: *Mesh, dynamic: bool) #foreign raylib;
// Update mesh vertex data in GPU for a specific buffer index
UpdateMeshBuffer :: (mesh: Mesh, index: s32, data: *void, dataSize: s32, offset: s32) #foreign raylib;
// Draw a 3d mesh with material and transform
DrawMesh :: (mesh: Mesh, material: Material, transform: Matrix) #foreign raylib;
// Draw multiple mesh instances with material and different transforms
DrawMeshInstanced :: (mesh: Mesh, material: Material, transforms: *Matrix, instances: s32) #foreign raylib;
// Unload mesh data from CPU and GPU
UnloadMesh :: (mesh: Mesh) #foreign raylib;
// Export mesh data to file, returns true on success
ExportMesh :: (mesh: Mesh, fileName: *u8) -> bool #foreign raylib;

//
// Material loading/unloading functions
//
// Load materials from model file
LoadMaterials :: (fileName: *u8, materialCount: *s32) -> *Material #foreign raylib;
// Load default material (Supports: DIFFUSE, SPECULAR, NORMAL maps)
LoadMaterialDefault :: () -> Material #foreign raylib;
// Unload material from GPU memory (VRAM)
UnloadMaterial :: (material: Material) #foreign raylib;
// Set texture for a material map type (MATERIAL_MAP_DIFFUSE, MATERIAL_MAP_SPECULAR...)
SetMaterialTexture :: (material: *Material, mapType: s32, texture: Texture2D) #foreign raylib;
// Set material for a mesh
SetModelMeshMaterial :: (model: *Model, meshId: s32, materialId: s32) #foreign raylib;

//
// Model animations loading/unloading functions
//
// Load model animations from file
LoadModelAnimations :: (fileName: *u8, animsCount: *s32) -> *ModelAnimation #foreign raylib;
// Update model animation pose
UpdateModelAnimation :: (model: Model, anim: ModelAnimation, frame: s32) #foreign raylib;
// Unload animation data
UnloadModelAnimation :: (anim: ModelAnimation) #foreign raylib;
// Unload animation array data
UnloadModelAnimations :: (animations: *ModelAnimation, count: u32) #foreign raylib;
// Check model animation skeleton match
IsModelAnimationValid :: (model: Model, anim: ModelAnimation) -> bool #foreign raylib;

//
// Mesh generation functions
//
// Generate polygonal mesh
GenMeshPoly :: (sides: s32, radius: float32) -> Mesh #foreign raylib;
// Generate plane mesh (with subdivisions)
GenMeshPlane :: (width: float32, length: float32, resX: s32, resZ: s32) -> Mesh #foreign raylib;
// Generate cuboid mesh
GenMeshCube :: (width: float32, height: float32, length: float32) -> Mesh #foreign raylib;
// Generate sphere mesh (standard sphere)
GenMeshSphere :: (radius: float32, rings: s32, slices: s32) -> Mesh #foreign raylib;
// Generate half-sphere mesh (no bottom cap)
GenMeshHemiSphere :: (radius: float32, rings: s32, slices: s32) -> Mesh #foreign raylib;
// Generate cylinder mesh
GenMeshCylinder :: (radius: float32, height: float32, slices: s32) -> Mesh #foreign raylib;
// Generate torus mesh
GenMeshTorus :: (radius: float32, size: float32, radSeg: s32, sides: s32) -> Mesh #foreign raylib;
// Generate trefoil knot mesh
GenMeshKnot :: (radius: float32, size: float32, radSeg: s32, sides: s32) -> Mesh #foreign raylib;
// Generate heightmap mesh from image data
GenMeshHeightmap :: (heightmap: Image, size: Vector3) -> Mesh #foreign raylib;
// Generate cubes-based map mesh from image data
GenMeshCubicmap :: (cubicmap: Image, cubeSize: Vector3) -> Mesh #foreign raylib;

//
// Mesh manipulation functions
//
// Compute mesh bounding box limits
MeshBoundingBox :: (mesh: Mesh) -> BoundingBox #foreign raylib;
// Compute mesh tangents
MeshTangents :: (mesh: *Mesh) #foreign raylib;
// Compute mesh binormals
MeshBinormals :: (mesh: *Mesh) #foreign raylib;

//
// Model drawing functions
//
// Draw a model (with texture if set)
DrawModel :: (model: Model, position: Vector3, scale: float32, tint: Color) #foreign raylib;
// Draw a model with extended parameters
DrawModelEx :: (model: Model, position: Vector3, rotationAxis: Vector3, rotationAngle: float32, scale: Vector3, tint: Color) #foreign raylib;
// Draw a model wires (with texture if set)
DrawModelWires :: (model: Model, position: Vector3, scale: float32, tint: Color) #foreign raylib;
// Draw a model wires (with texture if set) with extended parameters
DrawModelWiresEx :: (model: Model, position: Vector3, rotationAxis: Vector3, rotationAngle: float32, scale: Vector3, tint: Color) #foreign raylib;
// Draw bounding box (wires)
DrawBoundingBox :: (box: BoundingBox, color: Color) #foreign raylib;
// Draw a billboard texture
DrawBillboard :: (camera: Camera, texture: Texture2D, center: Vector3, size: float32, tint: Color) #foreign raylib;
// Draw a billboard texture defined by source
DrawBillboardRec :: (camera: Camera, texture: Texture2D, source: Rectangle, center: Vector3, size: float32, tint: Color) #foreign raylib;

//
// Collision detection functions
//
// Detect collision between two spheres
CheckCollisionSpheres :: (center1: Vector3, radius1: float32, center2: Vector3, radius2: float32) -> bool #foreign raylib;
// Detect collision between two bounding boxes
CheckCollisionBoxes :: (box1: BoundingBox, box2: BoundingBox) -> bool #foreign raylib;
// Detect collision between box and sphere
CheckCollisionBoxSphere :: (box: BoundingBox, center: Vector3, radius: float32) -> bool #foreign raylib;
// Detect collision between ray and sphere
CheckCollisionRaySphere :: (ray: Ray, center: Vector3, radius: float32) -> bool #foreign raylib;
// Detect collision between ray and sphere, returns collision point
CheckCollisionRaySphereEx :: (ray: Ray, center: Vector3, radius: float32, collisionPoint: *Vector3) -> bool #foreign raylib;
// Detect collision between ray and box
CheckCollisionRayBox :: (ray: Ray, box: BoundingBox) -> bool #foreign raylib;
// Get collision info between ray and mesh
GetCollisionRayMesh :: (ray: Ray, mesh: Mesh, transform: Matrix) -> RayHitInfo #foreign raylib;
// Get collision info between ray and model
GetCollisionRayModel :: (ray: Ray, model: Model) -> RayHitInfo #foreign raylib;
// Get collision info between ray and triangle
GetCollisionRayTriangle :: (ray: Ray, p1: Vector3, p2: Vector3, p3: Vector3) -> RayHitInfo #foreign raylib;
// Get collision info between ray and ground plane (Y-normal plane)
GetCollisionRayGround :: (ray: Ray, groundHeight: float32) -> RayHitInfo #foreign raylib;

//------------------------------------------------------------------------------------
// Audio Loading and Playing Functions (Module: audio)
//------------------------------------------------------------------------------------

//
// Audio device management functions
//
// Initialize audio device and context
InitAudioDevice :: () #foreign raylib;
// Close the audio device and context
CloseAudioDevice :: () #foreign raylib;
// Check if audio device has been initialized successfully
IsAudioDeviceReady :: () -> bool #foreign raylib;
// Set master volume (listener)
SetMasterVolume :: (volume: float32) #foreign raylib;

//
// Wave/Sound loading/unloading functions
//
// Load wave data from file
LoadWave :: (fileName: *u8) -> Wave #foreign raylib;
// Load wave from memory buffer, fileType refers to extension: i.e. ".wav"
LoadWaveFromMemory :: (fileType: *u8, fileData: *u8, dataSize: s32) -> Wave #foreign raylib;
// Load sound from file
LoadSound :: (fileName: *u8) -> Sound #foreign raylib;
// Load sound from wave data
LoadSoundFromWave :: (wave: Wave) -> Sound #foreign raylib;
// Update sound buffer with new data
UpdateSound :: (sound: Sound, data: *void, samplesCount: s32) #foreign raylib;
// Unload wave data
UnloadWave :: (wave: Wave) #foreign raylib;
// Unload sound
UnloadSound :: (sound: Sound) #foreign raylib;
// Export wave data to file, returns true on success
ExportWave :: (wave: Wave, fileName: *u8) -> bool #foreign raylib;
// Export wave sample data to code (.h), returns true on success
ExportWaveAsCode :: (wave: Wave, fileName: *u8) -> bool #foreign raylib;

//
// Wave/Sound management functions
//
// Play a sound
PlaySound :: (sound: Sound) #foreign raylib;
// Stop playing a sound
StopSound :: (sound: Sound) #foreign raylib;
// Pause a sound
PauseSound :: (sound: Sound) #foreign raylib;
// Resume a paused sound
ResumeSound :: (sound: Sound) #foreign raylib;
// Play a sound (using multichannel buffer pool)
PlaySoundMulti :: (sound: Sound) #foreign raylib;
// Stop any sound playing (using multichannel buffer pool)
StopSoundMulti :: () #foreign raylib;
// Get number of sounds playing in the multichannel
GetSoundsPlaying :: () -> s32 #foreign raylib;
// Check if a sound is currently playing
IsSoundPlaying :: (sound: Sound) -> bool #foreign raylib;
// Set volume for a sound (1.0 is max level)
SetSoundVolume :: (sound: Sound, volume: float32) #foreign raylib;
// Set pitch for a sound (1.0 is base level)
SetSoundPitch :: (sound: Sound, pitch: float32) #foreign raylib;
// Convert wave data to desired format
WaveFormat :: (wave: *Wave, sampleRate: s32, sampleSize: s32, channels: s32) #foreign raylib;
// Copy a wave to a new wave
WaveCopy :: (wave: Wave) -> Wave #foreign raylib;
// Crop a wave to defined samples range
WaveCrop :: (wave: *Wave, initSample: s32, finalSample: s32) #foreign raylib;
// Load samples data from wave as a floats array
LoadWaveSamples :: (wave: Wave) -> *float32 #foreign raylib;
// Unload samples data loaded with LoadWaveSamples()
UnloadWaveSamples :: (samples: *float32) #foreign raylib;

//
// Music management functions
//
// Load music stream from file
LoadMusicStream :: (fileName: *u8) -> Music #foreign raylib;
// Load music stream from data
LoadMusicStreamFromMemory :: (fileType: *u8, data: *u8, dataSize: s32) -> Music #foreign raylib;
// Unload music stream
UnloadMusicStream :: (music: Music) #foreign raylib;
// Start music playing
PlayMusicStream :: (music: Music) #foreign raylib;
// Check if music is playing
IsMusicPlaying :: (music: Music) -> bool #foreign raylib;
// Updates buffers for music streaming
UpdateMusicStream :: (music: Music) #foreign raylib;
// Stop music playing
StopMusicStream :: (music: Music) #foreign raylib;
// Pause music playing
PauseMusicStream :: (music: Music) #foreign raylib;
// Resume playing paused music
ResumeMusicStream :: (music: Music) #foreign raylib;
// Set volume for music (1.0 is max level)
SetMusicVolume :: (music: Music, volume: float32) #foreign raylib;
// Set pitch for a music (1.0 is base level)
SetMusicPitch :: (music: Music, pitch: float32) #foreign raylib;
// Get music time length (in seconds)
GetMusicTimeLength :: (music: Music) -> float32 #foreign raylib;
// Get current music time played (in seconds)
GetMusicTimePlayed :: (music: Music) -> float32 #foreign raylib;

//
// AudioStream management functions
//
// Init audio stream (to stream raw audio pcm data)
InitAudioStream :: (sampleRate: u32, sampleSize: u32, channels: u32) -> AudioStream #foreign raylib;
// Update audio stream buffers with data
UpdateAudioStream :: (stream: AudioStream, data: *void, samplesCount: s32) #foreign raylib;
// Close audio stream and free memory
CloseAudioStream :: (stream: AudioStream) #foreign raylib;
// Check if any audio stream buffers requires refill
IsAudioStreamProcessed :: (stream: AudioStream) -> bool #foreign raylib;
// Play audio stream
PlayAudioStream :: (stream: AudioStream) #foreign raylib;
// Pause audio stream
PauseAudioStream :: (stream: AudioStream) #foreign raylib;
// Resume audio stream
ResumeAudioStream :: (stream: AudioStream) #foreign raylib;
// Check if audio stream is playing
IsAudioStreamPlaying :: (stream: AudioStream) -> bool #foreign raylib;
// Stop audio stream
StopAudioStream :: (stream: AudioStream) #foreign raylib;
// Set volume for audio stream (1.0 is max level)
SetAudioStreamVolume :: (stream: AudioStream, volume: float32) #foreign raylib;
// Set pitch for audio stream (1.0 is base level)
SetAudioStreamPitch :: (stream: AudioStream, pitch: float32) #foreign raylib;
// Default size for new audio streams
SetAudioStreamBufferSizeDefault :: (size: s32) #foreign raylib;

#scope_file

#if OS == .WINDOWS {
	raylib :: #foreign_library "lib/3.7.0/win64/raylib";
}
