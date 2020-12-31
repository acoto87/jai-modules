// stb_truetype bindings.

stbtt_fontinfo :: struct {
   userdata: *void;
   data: *u8;                                   // pointer to .ttf file
   fontstart: s32;                              // offset of start of font

   numGlyphs: s32;                              // number of glyphs, needed for range checking

   loca,head,glyf,hhea,hmtx,kern,gpos,svg: s32; // table locations as offset from start of .ttf
   index_map: s32;                              // a cmap mapping for our chosen character encoding
   indexToLocFormat: s32;                       // format needed to map from glyph index to glyph

   cff: stbtt__buf;                             // cff font data
   charstrings: stbtt__buf;                     // the charstring index
   gsubrs: stbtt__buf;                          // global charstring subroutines index
   subrs: stbtt__buf;                           // private charstring subroutines index
   fontdicts: stbtt__buf;                       // array of font dicts
   fdselect: stbtt__buf;                        // map from glyph to fontdict
}

stbtt__buf :: struct {
   data: *u8;
   cursor: s32;
   size: s32;
}

stbtt_InitFont :: (info: *stbtt_fontinfo, data: *u8, offset: s32) -> s32 #foreign stb_truetype;
stbtt_GetFontVMetrics :: (info: *stbtt_fontinfo, ascent: *s32, descent: *s32, lineGap: *s32) #foreign stb_truetype;
stbtt_ScaleForPixelHeight :: (info: *stbtt_fontinfo, pixels: float32) -> float32 #foreign stb_truetype;
stbtt_ScaleForMappingEmToPixels :: (info: *stbtt_fontinfo, pixels: float32) -> float32 #foreign stb_truetype;
stbtt_FindGlyphIndex :: (info: *stbtt_fontinfo, unicode_codepoint: u32) -> s32 #foreign stb_truetype;
stbtt_GetGlyphHMetrics :: (info: *stbtt_fontinfo, glyph_index: s32, advanceWidth: *s32, leftSideBearing: *s32) #foreign stb_truetype;
stbtt_GetGlyphBitmapBox :: (font: *stbtt_fontinfo, glyph: s32, scale_x: float32, scale_y: float32, ix0: *s32, iy0: *s32, ix1: *s32, iy1: *s32) #foreign stb_truetype;
stbtt_MakeGlyphBitmap :: (info: *stbtt_fontinfo, output: *u8, out_w: s32, out_h: s32, out_stride: s32, scale_x: float32, scale_y: float32, glyph: s32) #foreign stb_truetype;
stbtt_GetGlyphKernAdvance :: (info: *stbtt_fontinfo, g1: s32, g2: s32) -> s32 #foreign stb_truetype;
stbtt_GetFontOffsetForIndex :: (data: *u8, index: s32) -> s32 #foreign stb_truetype;

// @Note: call this to build the dll and lib files
build :: (dll: bool = true, lib: bool = true) {
    if (dll) {
        print("Building dynamic library:\n");
        build_cpp_dynamic_lib("win/stb_truetype", "source/stb_truetype.c");
    }

    if (lib) {
        print("Building static library:\n");
        build_cpp_static_lib("win/stb_truetype", "source/stb_truetype.c");
    }

    build_cpp_done();
}

#scope_file

#import "BuildCpp";
#import "Basic";

#if OS == .WINDOWS {
	stb_truetype :: #foreign_library "win/stb_truetype";
} else #if OS == .LINUX {
	stb_truetype :: #foreign_library "linux/stb_truetype";
} else #if OS == .MACOS {
	stb_truetype :: #foreign_library "mac/stb_truetype";
}
