//
// A simple C file to be able to compile stb_truetype into a dynamic (.dll) and static (.lib).
//
// The modifications of the original stb_truetype library includes:
//
// Defining STBTT_EXPORT as
//      #define STBTT_EXPORT __declspec(dllexport)
// and mark several functions for dll exporting, see module.jai of this library for more information.
//
#define STB_TRUETYPE_IMPLEMENTATION  // force following include to generate implementation
#include "stb_truetype.h"
