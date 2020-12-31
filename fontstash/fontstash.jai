FONS_UTF8_ACCEPT :: 0;
FONS_UTF8_REJECT :: 12;

FONS_INVALID :: -1;

DEBUG :: false;

FONSflags :: enum s32 {
    FONS_ZERO_TOPLEFT    :: 1;
    FONS_ZERO_BOTTOMLEFT :: 2;
}

FONSalign :: enum s32 {
    // Horizontal align
    FONS_ALIGN_LEFT     :: 1<<0; // Default
    FONS_ALIGN_CENTER   :: 1<<1;
    FONS_ALIGN_RIGHT    :: 1<<2;
    // Vertical align
    FONS_ALIGN_TOP      :: 1<<3;
    FONS_ALIGN_MIDDLE   :: 1<<4;
    FONS_ALIGN_BOTTOM   :: 1<<5;
    FONS_ALIGN_BASELINE :: 1<<6; // Default
}

FONSglyphBitmap :: enum s32 {
    FONS_GLYPH_BITMAP_OPTIONAL :: 1;
    FONS_GLYPH_BITMAP_REQUIRED :: 2;
}

FONSerrorCode :: enum s32 {
    // Font atlas is full.
    FONS_ATLAS_FULL :: 1;
    // Scratch memory used to render glyphs is full, requested size reported in 'val', you may need to bump up FONS_SCRATCH_BUF_SIZE.
    FONS_SCRATCH_FULL :: 2;
    // Calls to fonsPushState has created too large stack, if you need deep state stack bump up FONS_MAX_STATES.
    FONS_STATES_OVERFLOW :: 3;
    // Trying to pop too many states fonsPopState().
    FONS_STATES_UNDERFLOW :: 4;
}

FONSparams :: struct {
    width, height: s32;
    flags: FONSflags;
    userPtr: *void;
    renderCreate: (uptr: *void, width: s32, height: s32) -> bool;
    renderResize: (uptr: *void, width: s32, height: s32) -> bool;
    renderUpdate: (uptr: *void, rect: [] s32, data: *u8);
    renderDraw: (uptr: *void, verts: [] f32, tcoords: [] f32, colors: [] u32, nverts: s32);
    renderDelete: (uptr: *void);
}

FONSquad :: struct {
    x0, y0, s0, t0: f32;
    x1, y1, s1, t1: f32;
}

FONStextIter :: struct {
    x, y: f32;
    nextx, nexty: f32;
    scale, spacing: f32;
    codepoint: u32;
    isize, iblur: s16;
    font: *FONSfont;
    prevGlyphIndex: s32;
    str: *u8;
    next: *u8;
    end: *u8;
    utf8state: u32;
    bitmapOption: FONSglyphBitmap;
}

FONSglyph :: struct {
    codepoint: u32;
    index: s32;
    next: s32;
    size, blur: s16;
    x0, y0, x1, y1: s16;
    xadv, xoff, yoff: s16;
}

FONSfont :: struct {
    font: FONSttFontImpl;
    name: *u8;
    data: *u8;
    dataSize: s32;
    freeData: bool;
    ascender: f32;
    descender: f32;
    lineh: f32;
    glyphs: *FONSglyph;
    cglyphs: s32;
    nglyphs: s32;
    lut: [FONS_HASH_LUT_SIZE] s32;
    fallbacks: [FONS_MAX_FALLBACKS] s32;
    nfallbacks: s32;
}

FONSstate :: struct {
    font: s32;
    align: FONSalign;
    size: f32;
    color: u32;
    blur: f32;
    spacing: f32;
}

FONSatlasNode :: struct {
    x, y, width: s16;
}

FONSatlas :: struct {
    width, height: s32;
    nodes: *FONSatlasNode;
    nnodes: s32;
    cnodes: s32;
}

FONScontext :: struct {
    params: FONSparams;
    itw: f32;
    ith: f32;
    texData: *u8;
    dirtyRect: [4] s32;
    fonts: **FONSfont;
    atlas: *FONSatlas;
    cfonts: s32;
    nfonts: s32;
    verts: [FONS_VERTEX_COUNT*2] f32;
    tcoords: [FONS_VERTEX_COUNT*2] f32;
    colors: [FONS_VERTEX_COUNT] u32;
    nverts: s32;
    scratch: *u8;
    nscratch: s32;
    states: [FONS_MAX_STATES] FONSstate;
    nstates: s32;
    handleError: (uptr: *void, error: FONSerrorCode, val: s32);
    errorUptr: *void;
}

// Constructor and destructor.
fonsCreateInternal :: (params: *FONSparams) -> *FONScontext {
    // Allocate memory for the font stash.
    stash := alloc(FONScontext);
    if (stash == null) {
        fonsDeleteInternal(stash);
        return null;
    }

    stash.params = <<params;

    // Allocate scratch buffer.
    stash.scratch = alloc(u8, FONS_SCRATCH_BUF_SIZE);
    if (stash.scratch == null) {
        fonsDeleteInternal(stash);
        return null;
    }

    // Initialize implementation library
    if (!fons__tt_init(stash)) {
        fonsDeleteInternal(stash);
        return null;
    }

    if (stash.params.renderCreate != null) {
        if (!stash.params.renderCreate(stash.params.userPtr, stash.params.width, stash.params.height)) {
            fonsDeleteInternal(stash);
            return null;
        }
    }

    stash.atlas = fons__allocAtlas(stash.params.width, stash.params.height, FONS_INIT_ATLAS_NODES);
    if (stash.atlas == null) {
        fonsDeleteInternal(stash);
        return null;
    }

    // Allocate space for fonts.
    stash.fonts = alloc(*FONSfont, FONS_INIT_FONTS);
    if (stash.fonts == null) {
        fonsDeleteInternal(stash);
        return null;
    }

    stash.cfonts = FONS_INIT_FONTS;
    stash.nfonts = 0;

    // Create texture for the cache.
    stash.itw = 1.0 / stash.params.width;
    stash.ith = 1.0 / stash.params.height;
    stash.texData = alloc(u8, stash.params.width * stash.params.height);
    if (stash.texData == null) {
        fonsDeleteInternal(stash);
        return null;
    }

    stash.dirtyRect[0] = stash.params.width;
    stash.dirtyRect[1] = stash.params.height;
    stash.dirtyRect[2] = 0;
    stash.dirtyRect[3] = 0;

    // Add white rect at 0,0 for debug drawing.
    fons__addWhiteRect(stash, 2,2);

    fonsPushState(stash);
    fonsClearState(stash);

    return stash;
}

fonsDeleteInternal :: (stash: *FONScontext) {
    if (stash == null) return;

    if (stash.params.renderDelete) {
        stash.params.renderDelete(stash.params.userPtr);
    }

    for i : 0..stash.nfonts-1 {
        fons__freeFont(stash.fonts[i]);
    }

    if (stash.atlas != null) fons__deleteAtlas(stash.atlas);
    if (stash.fonts != null) free(stash.fonts);
    if (stash.texData != null) free(stash.texData);
    if (stash.scratch != null) free(stash.scratch);
    free(stash);
    fons__tt_done(stash);
}

fonsSetErrorCallback :: (stash: *FONScontext, callback: (uptr: *void, error: FONSerrorCode, val: s32), uptr: *void) {
    if (stash == null) return;
    stash.handleError = callback;
    stash.errorUptr = uptr;
}

// Returns current atlas size.
fonsGetAtlasSize :: (stash: *FONScontext, width: *s32, height: *s32) {
    if (stash == null) return;
    <<width = stash.params.width;
    <<height = stash.params.height;
}

// Expands the atlas size.
fonsExpandAtlas :: (stash: *FONScontext, width: s32, height: s32) -> bool {
    if (stash == null) return false;

    width = max(width, stash.params.width);
    height = max(height, stash.params.height);

    if (width == stash.params.width && height == stash.params.height) {
        return true;
    }

    // Flush pending glyphs.
    fons__flush(stash);

    // Create new texture
    if (stash.params.renderResize != null) {
        if (!stash.params.renderResize(stash.params.userPtr, width, height)) {
            return false;
        }
    }

    // Copy old texture data over.
    data := alloc(u8, width * height);
    if (data == null) return false;

    for i : 0..stash.params.height-1 {
        dst := *data[i * width];
        src := *stash.texData[i * stash.params.width];
        memoryCopy(dst, src, stash.params.width);
        if (width > stash.params.width) {
            memorySet(dst + stash.params.width, 0, width - stash.params.width);
        }
    }

    if (height > stash.params.height) {
        memorySet(*data[stash.params.height * width], 0, (height - stash.params.height) * width);
    }

    free(stash.texData);
    stash.texData = data;

    // Increase atlas size
    fons__atlasExpand(stash.atlas, width, height);

    // Add existing data as dirty.
    maxy: s32 = 0;
    for i : 0..stash.atlas.nnodes-1 {
        maxy = max(maxy, stash.atlas.nodes[i].y);
    }
    stash.dirtyRect[0] = 0;
    stash.dirtyRect[1] = 0;
    stash.dirtyRect[2] = stash.params.width;
    stash.dirtyRect[3] = maxy;

    stash.params.width = width;
    stash.params.height = height;
    stash.itw = 1.0 / stash.params.width;
    stash.ith = 1.0 / stash.params.height;

    return true;
}

// Resets the whole stash.
fonsResetAtlas :: (stash: *FONScontext, width: s32, height: s32) -> bool {
    if (stash == null) return false;

    // Flush pending glyphs.
    fons__flush(stash);

    // Create new texture
    if (stash.params.renderResize != null) {
        if (!stash.params.renderResize(stash.params.userPtr, width, height)) {
            return false;
        }
    }

    // Reset atlas
    fons__atlasReset(stash.atlas, width, height);

    // Clear texture data.
    stash.texData = realloc(stash.texData, width * height);
    if (stash.texData == null) return false;
    memorySet(stash.texData, 0, width * height);

    // Reset dirty rect
    stash.dirtyRect[0] = width;
    stash.dirtyRect[1] = height;
    stash.dirtyRect[2] = 0;
    stash.dirtyRect[3] = 0;

    // Reset cached glyphs
    for i : 0..stash.nfonts-1 {
        font := stash.fonts[i];
        font.nglyphs = 0;
        for j : 0..FONS_HASH_LUT_SIZE-1 {
            font.lut[j] = -1;
        }
    }

    stash.params.width = width;
    stash.params.height = height;
    stash.itw = 1.0 / stash.params.width;
    stash.ith = 1.0 / stash.params.height;

    // Add white rect at 0,0 for debug drawing.
    fons__addWhiteRect(stash, 2, 2);

    return true;
}

// Add fonts
fonsAddFont :: (stash: *FONScontext, name: *u8, path: *u8, fontIndex: s32) -> s32 {
    // Read in the font data.
    fp := fopen(path, "rb");
    if (fp == null) {
        return FONS_INVALID;
    }
    fseek(fp, 0, SEEK_END);
    dataSize := cast(s32) ftell(fp);
    fseek(fp, 0, SEEK_SET);
    data := alloc(u8, dataSize);
    if (data == null) {
        fclose(fp);
        return FONS_INVALID;
    }
    readed := fread(data, 1, dataSize, fp);
    if (readed != dataSize) {
        free(data);
        fclose(fp);
        return FONS_INVALID;
    }
    fclose(fp);
    fp = null;
    return fonsAddFontMem(stash, name, data, dataSize, true, fontIndex);
}

fonsAddFontMem :: (stash: *FONScontext, name: *u8, data: *u8, dataSize: s32, freeData: bool, fontIndex: s32) -> s32 {
    idx := fons__allocFont(stash);
    if (idx == FONS_INVALID) {
        return FONS_INVALID;
    }

    font := stash.fonts[idx];
    font.name = name;

    // Init hash lookup.
    for i : 0..FONS_HASH_LUT_SIZE-1 {
        font.lut[i] = -1;
    }

    // Read in the font data.
    font.dataSize = dataSize;
    font.data = data;
    font.freeData = freeData;

    // Init font
    stash.nscratch = 0;
    if (!fons__tt_loadFont(stash, *font.font, data, dataSize, fontIndex)) {
        fons__freeFont(font);
        stash.nfonts -= 1;
        return FONS_INVALID;
    }

    // Store normalized line height. The real line height is got
    // by multiplying the lineh by font size.
    ascent, descent, lineGap: s32;
    fons__tt_getFontVMetrics(*font.font, *ascent, *descent, *lineGap);
    fh := ascent - descent;
    font.ascender = cast(f32) ascent / cast(f32) fh;
    font.descender = cast(f32) descent / cast(f32) fh;
    font.lineh = cast(f32) (fh + lineGap) / cast(f32) fh;

    return idx;
}

fonsGetFontByName :: (stash: *FONScontext, name: *u8) -> s32 {
    for i : 0..stash.nfonts-1 {
        if (strcmp(stash.fonts[i].name, name) == 0) {
            return i;
        }
    }
    return FONS_INVALID;
}

// State handling
fonsPushState :: (stash: *FONScontext) {
    if (stash.nstates >= FONS_MAX_STATES) {
        if (stash.handleError != null) {
            stash.handleError(stash.errorUptr, .FONS_STATES_OVERFLOW, 0);
        }
        return;
    }
    if (stash.nstates > 0) {
        memoryCopy(*stash.states[stash.nstates], *stash.states[stash.nstates-1]);
    }
    stash.nstates += 1;
}

fonsPopState :: (stash: *FONScontext) {
    if (stash.nstates <= 1) {
        if (stash.handleError) {
            stash.handleError(stash.errorUptr, .FONS_STATES_UNDERFLOW, 0);
        }
        return;
    }
    stash.nstates -= 1;
}

fonsClearState :: (stash: *FONScontext) {
    state := fons__getState(stash);
    state.size = 12.0;
    state.color = 0xffffffff;
    state.font = 0;
    state.blur = 0;
    state.spacing = 0;
    state.align = FONSalign.FONS_ALIGN_LEFT | .FONS_ALIGN_BASELINE;
}

fonsAddFallbackFont :: (stash: *FONScontext, base: s32, fallback: s32) -> bool {
	baseFont := stash.fonts[base];
	if (baseFont.nfallbacks < FONS_MAX_FALLBACKS) {
		baseFont.fallbacks[baseFont.nfallbacks] = fallback;
        baseFont.nfallbacks += 1;
		return true;
	}
	return false;
}

// State setting
fonsSetSize :: (stash: *FONScontext, size: f32) {
    state := fons__getState(stash);
    state.size = size;
}

fonsSetColor :: (stash: *FONScontext, color: u32) {
    state := fons__getState(stash);
    state.color = color;
}

fonsSetSpacing :: (stash: *FONScontext, spacing: f32) {
    state := fons__getState(stash);
    state.spacing = spacing;
}

fonsSetBlur :: (stash: *FONScontext, blur: f32) {
    state := fons__getState(stash);
    state.blur = blur;
}

fonsSetAlign :: (stash: *FONScontext, align: FONSalign) {
    state := fons__getState(stash);
    state.align = align;
}

fonsSetFont :: (stash: *FONScontext, font: s32) {
    state := fons__getState(stash);
    state.font = font;
}

// Draw text
fonsDrawText :: (stash: *FONScontext, x: f32, y: f32, str: *u8, end: *u8) -> f32 {
    if (stash == null) return x;

    state := fons__getState(stash);
    if (state.font < 0 || state.font >= stash.nfonts) return x;

    font := stash.fonts[state.font];
    if (font.data == null) return x;

    isize := cast(s16) (state.size * 10.0);
    iblur := cast(s16) (state.blur);

    scale := fons__tt_getPixelHeightScale(*font.font, cast(f32) isize / 10.0);

    if (end == null) {
        end = str + strlen(str);
    }

    // Align horizontally
    if (state.align & .FONS_ALIGN_LEFT) {
        // empty
    } else if (state.align & .FONS_ALIGN_RIGHT) {
        width := fonsTextBounds(stash, x, y, str, end, null);
        x -= width;
    } else if (state.align & .FONS_ALIGN_CENTER) {
        width := fonsTextBounds(stash, x, y, str, end, null);
        x -= width * 0.5;
    }
    // Align vertically.
    y += fons__getVertAlign(stash, font, state.align, isize);

    q: FONSquad;
    prevGlyphIndex: s32 = -1;

    utf8state, codepoint: u32;

    while (str != end) {
        if (fons__decutf8(*utf8state, *codepoint, <<str)) {
            str += 1;
            continue;
        }
        glyph := fons__getGlyph(stash, font, codepoint, isize, iblur, .FONS_GLYPH_BITMAP_REQUIRED);
        if (glyph != null) {
            fons__getQuad(stash, font, prevGlyphIndex, glyph, scale, state.spacing, *x, *y, *q);

            if (stash.nverts + 6 > FONS_VERTEX_COUNT) {
                fons__flush(stash);
            }

            fons__vertex(stash, q.x0, q.y0, q.s0, q.t0, state.color);
            fons__vertex(stash, q.x1, q.y1, q.s1, q.t1, state.color);
            fons__vertex(stash, q.x1, q.y0, q.s1, q.t0, state.color);

            fons__vertex(stash, q.x0, q.y0, q.s0, q.t0, state.color);
            fons__vertex(stash, q.x0, q.y1, q.s0, q.t1, state.color);
            fons__vertex(stash, q.x1, q.y1, q.s1, q.t1, state.color);
        }
        prevGlyphIndex = ifx glyph != null then glyph.index else -1;
        str += 1;
    }
    fons__flush(stash);

    return x;
}

// Measure text
fonsTextBounds :: (stash: *FONScontext, x: f32, y: f32, str: *u8, end: *u8, bounds: *f32) -> f32 {
    if (stash == null) return 0;

    state := fons__getState(stash);
    if (state.font < 0 || state.font >= stash.nfonts) return 0;

    font := stash.fonts[state.font];
    if (font.data == null) return 0;

    isize := cast(s16) (state.size*10.0);
    iblur := cast(s16) (state.blur);

    scale := fons__tt_getPixelHeightScale(*font.font, cast(f32) isize / 10.0);

    // Align vertically.
    y += fons__getVertAlign(stash, font, state.align, isize);

    minx, maxx := x;
    miny, maxy := y;
    startx := x;

    if (end == null) {
        end = str + strlen(str);
    }

    q: FONSquad;
    prevGlyphIndex: s32 = -1;

    utf8state, codepoint: u32;

    while (str != end) {
        if (fons__decutf8(*utf8state, *codepoint, <<str)) {
            str += 1;
            continue;
        }
        glyph := fons__getGlyph(stash, font, codepoint, isize, iblur, .FONS_GLYPH_BITMAP_OPTIONAL);
        if (glyph != null) {
            fons__getQuad(stash, font, prevGlyphIndex, glyph, scale, state.spacing, *x, *y, *q);
            if (q.x0 < minx) minx = q.x0;
            if (q.x1 > maxx) maxx = q.x1;
            if (stash.params.flags & .FONS_ZERO_TOPLEFT) {
                if (q.y0 < miny) miny = q.y0;
                if (q.y1 > maxy) maxy = q.y1;
            } else {
                if (q.y1 < miny) miny = q.y1;
                if (q.y0 > maxy) maxy = q.y0;
            }
        }
        prevGlyphIndex = ifx glyph != null then glyph.index else -1;
        str += 1;
    }

    advance := x - startx;

    // Align horizontally
    if (state.align & .FONS_ALIGN_LEFT) {
        // empty
    } else if (state.align & .FONS_ALIGN_RIGHT) {
        minx -= advance;
        maxx -= advance;
    } else if (state.align & .FONS_ALIGN_CENTER) {
        minx -= advance * 0.5;
        maxx -= advance * 0.5;
    }

    if (bounds) {
        bounds[0] = minx;
        bounds[1] = miny;
        bounds[2] = maxx;
        bounds[3] = maxy;
    }

    return advance;
}

fonsLineBounds :: (stash: *FONScontext, y: f32, miny: *f32, maxy: *f32) {
    if (stash == null) return;

    state := fons__getState(stash);
    if (state.font < 0 || state.font >= stash.nfonts) return;

    font := stash.fonts[state.font];
    if (font.data == null) return;

    isize := cast(s16) (state.size * 10.0);

    y += fons__getVertAlign(stash, font, state.align, isize);

    if (stash.params.flags & .FONS_ZERO_TOPLEFT) {
        <<miny = y - font.ascender * cast(f32) isize / 10.0;
        <<maxy = <<miny + font.lineh * isize/10.0;
    } else {
        <<maxy = y + font.descender * cast(f32) isize / 10.0;
        <<miny = <<maxy - font.lineh * isize/10.0;
    }
}

fonsVertMetrics :: (stash: *FONScontext, ascender: *f32, descender: *f32, lineh: *f32) {
    if (stash == null) return;

    state := fons__getState(stash);
    if (state.font < 0 || state.font >= stash.nfonts) return;

    font := stash.fonts[state.font];
    if (font.data == null) return;

    isize := cast(s16) (state.size*10.0);

    if (ascender) {
        <<ascender = font.ascender*isize/10.0;
    }
    if (descender) {
        <<descender = font.descender*isize/10.0;
    }
    if (lineh) {
        <<lineh = font.lineh*isize/10.0;
    }
}

// Text iterator
fonsTextIterInit :: (stash: *FONScontext, iter: *FONStextIter, x: f32, y: f32, str: *u8, end: *u8, bitmapOption: FONSglyphBitmap) -> bool {
    if (stash == null) return false;

    state := fons__getState(stash);
    if (state.font < 0 || state.font >= stash.nfonts) return false;

    clear(iter);
    iter.font = stash.fonts[state.font];
    if (iter.font.data == null) return false;
    iter.isize = cast(s16) (state.size * 10.0);
    iter.iblur = cast(s16) (state.blur);
    iter.scale = fons__tt_getPixelHeightScale(*iter.font.font, cast(f32) iter.isize / 10.0);

    // Align horizontally
    if (state.align & .FONS_ALIGN_LEFT) {
        // empty
    } else if (state.align & .FONS_ALIGN_RIGHT) {
        width := fonsTextBounds(stash, x, y, str, end, null);
        x -= width;
    } else if (state.align & .FONS_ALIGN_CENTER) {
        width := fonsTextBounds(stash, x, y, str, end, null);
        x -= width * 0.5;
    }
    // Align vertically.
    y += fons__getVertAlign(stash, iter.font, state.align, iter.isize);

    if (end == null) {
        end = str + strlen(str);
    }

    iter.x = x;
    iter.nextx = x;
    iter.y = y;
    iter.nexty = y;
    iter.spacing = state.spacing;
    iter.str = str;
    iter.next = str;
    iter.end = end;
    iter.codepoint = 0;
    iter.prevGlyphIndex = -1;
    iter.bitmapOption = bitmapOption;

    return true;
}

fonsTextIterNext :: (stash: *FONScontext, iter: *FONStextIter, quad: *FONSquad) -> bool {
    str := iter.next;
    iter.str = iter.next;

    if (str == iter.end) {
        return false;
    }

    while (str != iter.end) {
        if (fons__decutf8(*iter.utf8state, *iter.codepoint, <<str)) {
            str += 1;
            continue;
        }
        str += 1;
        // Get glyph and quad
        iter.x = iter.nextx;
        iter.y = iter.nexty;
        glyph := fons__getGlyph(stash, iter.font, iter.codepoint, iter.isize, iter.iblur, iter.bitmapOption);
        // If the iterator was initialized with FONS_GLYPH_BITMAP_OPTIONAL, then the UV coordinates of the quad will be invalid.
        if (glyph != null) {
            fons__getQuad(stash, iter.font, iter.prevGlyphIndex, glyph, iter.scale, iter.spacing, *iter.nextx, *iter.nexty, quad);
        }
        iter.prevGlyphIndex = ifx glyph != null then glyph.index else -1;
        break;
    }
    iter.next = str;

    return true;
}

// Pull texture changes
fonsGetTextureData :: (stash: *FONScontext, width: *s32, height: *s32) -> *u8 {
    if (width != null) {
        <<width = stash.params.width;
    }
    if (height != null) {
        <<height = stash.params.height;
    }
    return stash.texData;
}

fonsValidateTexture :: (stash: *FONScontext, dirty: [] s32) -> bool {
    if (stash.dirtyRect[0] < stash.dirtyRect[2] && stash.dirtyRect[1] < stash.dirtyRect[3]) {
        dirty[0] = stash.dirtyRect[0];
        dirty[1] = stash.dirtyRect[1];
        dirty[2] = stash.dirtyRect[2];
        dirty[3] = stash.dirtyRect[3];
        // Reset dirty rect
        stash.dirtyRect[0] = stash.params.width;
        stash.dirtyRect[1] = stash.params.height;
        stash.dirtyRect[2] = 0;
        stash.dirtyRect[3] = 0;
        return true;
    }
    return false;
}

// Draws the stash texture for debugging
fonsDrawDebug :: (stash: *FONScontext, x: f32, y: f32) {
    w := stash.params.width;
    h := stash.params.height;
    u := ifx w == 0 then 0 else (1.0 / w);
    v := ifx h == 0 then 0 else (1.0 / h);

    if (stash.nverts + 6 + 6 > FONS_VERTEX_COUNT) {
        fons__flush(stash);
    }

    // Draw background
    fons__vertex(stash, x + 0, y + 0, u, v, 0x0fffffff);
    fons__vertex(stash, x + w, y + h, u, v, 0x0fffffff);
    fons__vertex(stash, x + w, y + 0, u, v, 0x0fffffff);

    fons__vertex(stash, x + 0, y + 0, u, v, 0x0fffffff);
    fons__vertex(stash, x + 0, y + h, u, v, 0x0fffffff);
    fons__vertex(stash, x + w, y + h, u, v, 0x0fffffff);

    // Draw texture
    fons__vertex(stash, x + 0, y + 0, 0, 0, 0xffffffff);
    fons__vertex(stash, x + w, y + h, 1, 1, 0xffffffff);
    fons__vertex(stash, x + w, y + 0, 1, 0, 0xffffffff);

    fons__vertex(stash, x + 0, y + 0, 0, 0, 0xffffffff);
    fons__vertex(stash, x + 0, y + h, 0, 1, 0xffffffff);
    fons__vertex(stash, x + w, y + h, 1, 1, 0xffffffff);

    // Drawbug draw atlas
    for i : 0..stash.atlas.nnodes-1 {
        n := *stash.atlas.nodes[i];

        if (stash.nverts + 6 > FONS_VERTEX_COUNT) {
            fons__flush(stash);
        }

        fons__vertex(stash, x + n.x + 0, y + n.y + 0, u, v, 0xc00000ff);
        fons__vertex(stash, x + n.x + n.width, y + n.y + 1, u, v, 0xc00000ff);
        fons__vertex(stash, x + n.x + n.width, y + n.y + 0, u, v, 0xc00000ff);

        fons__vertex(stash, x + n.x + 0, y + n.y + 0, u, v, 0xc00000ff);
        fons__vertex(stash, x + n.x + 0, y + n.y + 1, u, v, 0xc00000ff);
        fons__vertex(stash, x + n.x + n.width, y + n.y + 1, u, v, 0xc00000ff);
    }

    fons__flush(stash);
}

#scope_file

#import "utils";
#import "stb_truetype";

utf8d: [] u8 = .[
    // The first part of the table maps bytes to character classes that
    // to reduce the size of the transition table and create bitmasks.
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,  9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
    7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,  7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
    8,8,2,2,2,2,2,2,2,2,2,2,2,2,2,2,  2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
    10,3,3,3,3,3,3,3,3,3,3,3,3,4,3,3, 11,6,6,6,5,8,8,8,8,8,8,8,8,8,8,8,

    // The second part is a transition table that maps a combination
    // of a state of the automaton and a character class to a state.
    0,12,24,36,60,96,84,12,12,12,48,72, 12,12,12,12,12,12,12,12,12,12,12,12,
    12, 0,12,12,12,12,12, 0,12, 0,12,12, 12,24,12,12,12,12,12,24,12,24,12,12,
    12,12,12,12,12,12,12,24,12,12,12,12, 12,24,12,12,12,12,12,12,12,24,12,12,
    12,12,12,12,12,12,12,36,12,36,12,12, 12,36,12,12,12,12,12,36,12,36,12,12,
    12,36,12,12,12,12,12,12,12,12,12,12,
];

fons__decutf8 :: (state: *u32, codep: *u32, byte: u32) -> u32 {
    type: u32 = utf8d[byte];

    <<codep = ifx (<<state) != FONS_UTF8_ACCEPT
        then (byte & cast(u32) 0x3f) | ((<<codep) << 6)
        else (cast(u32) 0xff >> type) & (byte);

    <<state = utf8d[256 + <<state + type];
    return <<state;
}

// Atlas based on Skyline Bin Packer by Jukka Jylänki

fons__deleteAtlas :: (atlas: *FONSatlas) {
    if (atlas == null) return;
    if (atlas.nodes != null) free(atlas.nodes);
    free(atlas);
}

fons__allocAtlas :: (w: s32, h: s32, nnodes: s32) -> *FONSatlas {
    // Allocate memory for the font stash.
    atlas := alloc(FONSatlas);
    if (atlas == null) {
        return null;
    }

    atlas.width = w;
    atlas.height = h;

    // Allocate space for skyline nodes
    atlas.nodes = alloc(FONSatlasNode, nnodes);
    if (atlas.nodes == null) {
        if (atlas != null) {
            fons__deleteAtlas(atlas);
        }
        return null;
    }
    atlas.nnodes = 0;
    atlas.cnodes = nnodes;

    // Init root node.
    atlas.nodes[0].x = 0;
    atlas.nodes[0].y = 0;
    atlas.nodes[0].width = cast(s16)w;
    atlas.nnodes += 1;

    return atlas;
}

fons__atlasInsertNode :: (atlas: *FONSatlas, idx: s32, x: s32, y: s32, w: s32) -> bool {
    // Insert node
    if (atlas.nnodes + 1 > atlas.cnodes) {
        atlas.cnodes = ifx atlas.cnodes == 0 then 8 else atlas.cnodes * 2;
        atlas.nodes = realloc(atlas.nodes, atlas.cnodes);
        if (atlas.nodes == null) {
            return false;
        }
    }
    for < i : atlas.nnodes..idx+1 {
        atlas.nodes[i] = atlas.nodes[i-1];
    }
    atlas.nodes[idx].x = cast(s16) x;
    atlas.nodes[idx].y = cast(s16) y;
    atlas.nodes[idx].width = cast(s16) w;
    atlas.nnodes += 1;

    return true;
}

fons__atlasRemoveNode :: (atlas: *FONSatlas, idx: s32) {
    if (atlas.nnodes == 0) return;
    for i : idx..atlas.nnodes-2 {
        atlas.nodes[i] = atlas.nodes[i+1];
    }
    atlas.nnodes -= 1;
}

fons__atlasExpand :: (atlas: *FONSatlas, w: s32, h: s32) {
    // Insert node for empty space
    if (w > atlas.width) {
        fons__atlasInsertNode(atlas, atlas.nnodes, atlas.width, 0, w - atlas.width);
    }
    atlas.width = w;
    atlas.height = h;
}

fons__atlasReset :: (atlas: *FONSatlas, w: s32, h: s32) {
    atlas.width = w;
    atlas.height = h;
    atlas.nnodes = 0;

    // Init root node.
    atlas.nodes[0].x = 0;
    atlas.nodes[0].y = 0;
    atlas.nodes[0].width = cast(s16) w;
    atlas.nnodes += 1;
}

fons__atlasAddSkylineLevel :: (atlas: *FONSatlas, idx: s32, x: s32, y: s32, w: s32, h: s32) -> bool {
    // Insert new node
    if (!fons__atlasInsertNode(atlas, idx, x, y+h, w)) {
        return false;
    }

    // Delete skyline segments that fall under the shadow of the new segment.
    i := idx + 1;
    while (i < atlas.nnodes) {
        node := *atlas.nodes[i];
        prev := *atlas.nodes[i - 1];
        if (node.x < prev.x + prev.width) {
            shrink := prev.x + prev.width - node.x;
            node.x += cast(s16) shrink;
            node.width -= cast(s16) shrink;
            if (node.width <= 0) {
                fons__atlasRemoveNode(atlas, i);
                i -= 1;
            } else {
                break;
            }
        } else {
            break;
        }
        i += 1;
    }

    // Merge same height skyline segments that are next to each other.
    i = 0;
    while (i < atlas.nnodes-1) {
        if (atlas.nodes[i].y == atlas.nodes[i+1].y) {
            atlas.nodes[i].width += atlas.nodes[i+1].width;
            fons__atlasRemoveNode(atlas, i+1);
            i -= 1;
        }
        i += 1;
    }

    return true;
}

fons__atlasRectFits :: (atlas: *FONSatlas, i: s32, w: s32, h: s32) -> s32 {
    // Checks if there is enough space at the location of skyline span 'i',
    // and return the max height of all skyline spans under that at that location,
    // (think tetris block being dropped at that position). Or -1 if no space found.
    x: s32 = atlas.nodes[i].x;
    y: s32 = atlas.nodes[i].y;
    if (x + w > atlas.width) {
        return -1;
    }
    spaceLeft := w;
    while (spaceLeft > 0) {
        if (i == atlas.nnodes) return -1;
        y = max(y, atlas.nodes[i].y);
        if (y + h > atlas.height) return -1;
        spaceLeft -= atlas.nodes[i].width;
        i += 1;
    }
    return y;
}

fons__atlasAddRect :: (atlas: *FONSatlas, rw: s32, rh: s32, rx: *s32, ry: *s32) -> bool {
    besth: s32 = atlas.height;
    bestw: s32 = atlas.width;
    besti, bestx, besty: s32 = -1;

    // Bottom left fit heuristic.
    for i : 0..atlas.nnodes-1 {
        y := fons__atlasRectFits(atlas, i, rw, rh);
        if (y != -1) {
            if (y + rh < besth || (y + rh == besth && atlas.nodes[i].width < bestw)) {
                besti = i;
                bestw = atlas.nodes[i].width;
                besth = y + rh;
                bestx = atlas.nodes[i].x;
                besty = y;
            }
        }
    }

    if (besti == -1) {
        return false;
    }

    // Perform the actual packing.
    if (!fons__atlasAddSkylineLevel(atlas, besti, bestx, besty, rw, rh)) {
        return false;
    }

    <<rx = bestx;
    <<ry = besty;

    return true;
}

fons__addWhiteRect :: (stash: *FONScontext, w: s32, h: s32) {
    gx, gy: s32;
    if (!fons__atlasAddRect(stash.atlas, w, h, *gx, *gy)) {
        return;
    }

    // Rasterize
    dst := *stash.texData[gx + gy * stash.params.width];
    for y : 0..h-1 {
        for x : 0..w-1 {
            dst[x] = 0xff;
        }
        dst += stash.params.width;
    }

    stash.dirtyRect[0] = min(stash.dirtyRect[0], gx);
    stash.dirtyRect[1] = min(stash.dirtyRect[1], gy);
    stash.dirtyRect[2] = max(stash.dirtyRect[2], gx+w);
    stash.dirtyRect[3] = max(stash.dirtyRect[3], gy+h);
}

fons__getState :: (stash: *FONScontext) -> *FONSstate {
    return *stash.states[stash.nstates-1];
}

fons__getGlyph :: (stash: *FONScontext, font: *FONSfont, codepoint: u32,
                   isize: s16, iblur: s16, bitmapOption: FONSglyphBitmap) -> *FONSglyph
{
    glyph: *FONSglyph = null;

    size := cast(f32) isize / 10.0;
    renderFont := font;

    if (isize < 2) return null;
    if (iblur > 20) {
        iblur = 20;
    }

    pad: s32 = iblur + 2;

    // Reset allocator.
    stash.nscratch = 0;

    // Find code point and size.
    h := fons__hashint(codepoint) & (FONS_HASH_LUT_SIZE-1);
    i := font.lut[h];
    while (i != -1) {
        if (font.glyphs[i].codepoint == codepoint && font.glyphs[i].size == isize && font.glyphs[i].blur == iblur) {
            glyph = *font.glyphs[i];
            if (bitmapOption == .FONS_GLYPH_BITMAP_OPTIONAL || (glyph.x0 >= 0 && glyph.y0 >= 0)) {
              return glyph;
            }
            // At this point, glyph exists but the bitmap data is not yet created.
            break;
        }
        i = font.glyphs[i].next;
    }

    // Create a new glyph or rasterize bitmap data for a cached glyph.
    g := fons__tt_getGlyphIndex(*font.font, codepoint);
    // Try to find the glyph in fallback fonts.
    if (g == 0) {
        for i : 0..font.nfallbacks-1 {
            fallbackFont := stash.fonts[font.fallbacks[i]];
            fallbackIndex := fons__tt_getGlyphIndex(*fallbackFont.font, codepoint);
            if (fallbackIndex != 0) {
                g = fallbackIndex;
                renderFont = fallbackFont;
                break;
            }
        }
        // It is possible that we did not find a fallback glyph.
        // In that case the glyph index 'g' is 0, and we'll proceed below and cache empty glyph.
    }

    advance, lsb, x0, y0, x1, y1: s32;
    scale := fons__tt_getPixelHeightScale(*renderFont.font, size);
    fons__tt_buildGlyphBitmap(*renderFont.font, g, size, scale, *advance, *lsb, *x0, *y0, *x1, *y1);

    gw := x1-x0 + pad*2;
    gh := y1-y0 + pad*2;

    gx, gy: s32;

    // Determines the spot to draw glyph in the atlas.
    if (bitmapOption == .FONS_GLYPH_BITMAP_REQUIRED) {
        // Find free spot for the rect in the atlas
        added := fons__atlasAddRect(stash.atlas, gw, gh, *gx, *gy);
        if (!added && stash.handleError != null) {
            // Atlas is full, let the user to resize the atlas (or not), and try again.
            stash.handleError(stash.errorUptr, .FONS_ATLAS_FULL, 0);
            added = fons__atlasAddRect(stash.atlas, gw, gh, *gx, *gy);
        }
        if (!added) return null;
    } else {
        // Negative coordinate indicates there is no bitmap data created.
        gx = -1;
        gy = -1;
    }

    // Init glyph.
    if (glyph == null) {
        glyph = fons__allocGlyph(font);
        glyph.codepoint = codepoint;
        glyph.size = isize;
        glyph.blur = iblur;
        glyph.next = 0;

        // Insert char to hash lookup.
        glyph.next = font.lut[h];
        font.lut[h] = font.nglyphs-1;
    }
    glyph.index = g;
    glyph.x0 = cast(s16) gx;
    glyph.y0 = cast(s16) gy;
    glyph.x1 = cast(s16) (glyph.x0+gw);
    glyph.y1 = cast(s16) (glyph.y0+gh);
    glyph.xadv = cast(s16) (scale * advance * 10.0);
    glyph.xoff = cast(s16) (x0 - pad);
    glyph.yoff = cast(s16) (y0 - pad);

    if (bitmapOption == .FONS_GLYPH_BITMAP_OPTIONAL) {
        return glyph;
    }

    // Rasterize
    dst := *stash.texData[(glyph.x0+pad) + (glyph.y0+pad) * stash.params.width];
    fons__tt_renderGlyphBitmap(*renderFont.font, dst, gw-pad*2,gh-pad*2, stash.params.width, scale, scale, g);

    // Make sure there is one pixel empty border.
    dst = *stash.texData[glyph.x0 + glyph.y0 * stash.params.width];
    for y : 0..gh-1 {
        dst[y * stash.params.width] = 0;
        dst[gw - 1 + y * stash.params.width] = 0;
    }
    for x : 0..gw-1 {
        dst[x] = 0;
        dst[x + (gh - 1) * stash.params.width] = 0;
    }

    #if FONS_DEBUG {
        // Debug code to color the glyph background
        fdst := *stash.texData[glyph.x0 + glyph.y0 * stash.params.width];
        for y : 0..gh-1 {
            for x : 0..gw-1 {
                a := cast(s32) fdst[x + y * stash.params.width] + 20;
                if (a > 255) {
                    a = 255;
                }
                fdst[x + y * stash.params.width] = a;
            }
        }
    }

    // Blur
    if (iblur > 0) {
        stash.nscratch = 0;
        bdst := *stash.texData[glyph.x0 + glyph.y0 * stash.params.width];
        fons__blur(stash, bdst, gw, gh, stash.params.width, iblur);
    }

    stash.dirtyRect[0] = min(stash.dirtyRect[0], glyph.x0);
    stash.dirtyRect[1] = min(stash.dirtyRect[1], glyph.y0);
    stash.dirtyRect[2] = max(stash.dirtyRect[2], glyph.x1);
    stash.dirtyRect[3] = max(stash.dirtyRect[3], glyph.y1);

    return glyph;
}

fons__getQuad :: (stash: *FONScontext, font: *FONSfont,
                  prevGlyphIndex: s32, glyph: *FONSglyph,
                  scale: f32, spacing: f32, x: *f32, y: *f32, q: *FONSquad)
{
    if (prevGlyphIndex != -1) {
        adv := fons__tt_getGlyphKernAdvance(*font.font, prevGlyphIndex, glyph.index) * scale;
        <<x += cast(s32)(adv + spacing + 0.5);
    }

    // Each glyph has 2px border to allow good interpolation,
    // one pixel to prevent leaking, and one to allow good interpolation for rendering.
    // Inset the texture region by one pixel for correct interpolation.
    xoff := cast(s16)(glyph.xoff+1);
    yoff := cast(s16)(glyph.yoff+1);
    x0 := cast(f32)(glyph.x0+1);
    y0 := cast(f32)(glyph.y0+1);
    x1 := cast(f32)(glyph.x1-1);
    y1 := cast(f32)(glyph.y1-1);

    if (stash.params.flags & .FONS_ZERO_TOPLEFT) {
        rx := floorf(<<x + xoff);
        ry := floorf(<<y + yoff);

        q.x0 = rx;
        q.y0 = ry;
        q.x1 = rx + x1 - x0;
        q.y1 = ry + y1 - y0;

        q.s0 = x0 * stash.itw;
        q.t0 = y0 * stash.ith;
        q.s1 = x1 * stash.itw;
        q.t1 = y1 * stash.ith;
    } else {
        rx := floorf(<<x + xoff);
        ry := floorf(<<y - yoff);

        q.x0 = rx;
        q.y0 = ry;
        q.x1 = rx + x1 - x0;
        q.y1 = ry - y1 + y0;

        q.s0 = x0 * stash.itw;
        q.t0 = y0 * stash.ith;
        q.s1 = x1 * stash.itw;
        q.t1 = y1 * stash.ith;
    }

    <<x += cast(s32) (glyph.xadv / 10.0 + 0.5);
}

fons__flush :: (stash: *FONScontext) {
    // Flush texture
    if (stash.dirtyRect[0] < stash.dirtyRect[2] && stash.dirtyRect[1] < stash.dirtyRect[3]) {
        if (stash.params.renderUpdate != null) {
            stash.params.renderUpdate(stash.params.userPtr, stash.dirtyRect, stash.texData);
        }
        // Reset dirty rect
        stash.dirtyRect[0] = stash.params.width;
        stash.dirtyRect[1] = stash.params.height;
        stash.dirtyRect[2] = 0;
        stash.dirtyRect[3] = 0;
    }

    // Flush triangles
    if (stash.nverts > 0) {
        if (stash.params.renderDraw != null) {
            stash.params.renderDraw(stash.params.userPtr, stash.verts, stash.tcoords, stash.colors, stash.nverts);
        }
        stash.nverts = 0;
    }
}

fons__vertex :: (stash: *FONScontext, x: f32, y: f32, s: f32, t: f32, c: u32) {
    stash.verts[stash.nverts * 2 + 0] = x;
    stash.verts[stash.nverts * 2 + 1] = y;
    stash.tcoords[stash.nverts * 2 + 0] = s;
    stash.tcoords[stash.nverts * 2 + 1] = t;
    stash.colors[stash.nverts] = c;
    stash.nverts += 1;
}

fons__getVertAlign :: (stash: *FONScontext, font: *FONSfont, align: FONSalign, isize: s16) -> f32 {
    if (stash.params.flags & .FONS_ZERO_TOPLEFT) {
        if (align & .FONS_ALIGN_TOP) {
            return font.ascender * cast(f32) isize / 10.0;
        } else if (align & .FONS_ALIGN_MIDDLE) {
            return (font.ascender + font.descender) / 2.0 * cast(f32) isize / 10.0;
        } else if (align & .FONS_ALIGN_BASELINE) {
            return 0.0;
        } else if (align & .FONS_ALIGN_BOTTOM) {
            return font.descender * cast(f32) isize / 10.0;
        }
    } else {
        if (align & .FONS_ALIGN_TOP) {
            return -font.ascender * cast(f32) isize / 10.0;
        } else if (align & .FONS_ALIGN_MIDDLE) {
            return -(font.ascender + font.descender) / 2.0 * cast(f32) isize / 10.0;
        } else if (align & .FONS_ALIGN_BASELINE) {
            return 0.0;
        } else if (align & .FONS_ALIGN_BOTTOM) {
            return -font.descender * cast(f32) isize / 10.0;
        }
    }
    return 0.0;
}

// Based on Exponential blur, Jani Huhtanen, 2006

APREC :: 16;
ZPREC :: 7;

fons__blurCols :: (dst: *u8, w: s32, h: s32, dstStride: s32, alpha: s32) {
    for y : 0..h-1 {
        z: s32 = 0; // force zero border
        for x : 1..w-1 {
            z += (alpha * ((cast(s32) (dst[x]) << ZPREC) - z)) >> APREC;
            dst[x] = cast(u8) (z >> ZPREC);
        }
        dst[w - 1] = 0; // force zero border
        z = 0;
        for < x : w-2..0 {
            z += (alpha * ((cast(s32) (dst[x]) << ZPREC) - z)) >> APREC;
            dst[x] = cast(u8) (z >> ZPREC);
        }
        dst[0] = 0; // force zero border
        dst += dstStride;
    }
}

fons__blurRows :: (dst: *u8, w: s32, h: s32, dstStride: s32, alpha: s32) {
    for x : 0..w-1 {
        z: s32 = 0; // force zero border
        y := dstStride;
        while (y < h*dstStride) {
            z += (alpha * ((cast(s32) (dst[y]) << ZPREC) - z)) >> APREC;
            dst[y] = cast(u8) (z >> ZPREC);
            y += dstStride;
        }
        dst[(h - 1) * dstStride] = 0; // force zero border
        z = 0;
        y = (h - 2) * dstStride;
        while (y >= 0) {
            z += (alpha * ((cast(s32) (dst[y]) << ZPREC) - z)) >> APREC;
            dst[y] = cast(u8) (z >> ZPREC);
            y -= dstStride;
        }
        dst[0] = 0; // force zero border
        dst += 1;
    }
}

fons__blur :: (stash: *FONScontext, dst: *u8, w: s32, h: s32, dstStride: s32, blur: s32)
{
    if (blur < 1) return;
    // Calculate the alpha such that 90% of the kernel is within the radius. (Kernel extends to infinity)
    sigma := cast(f32) blur * 0.57735; // 1 / sqrt(3)
    alpha := cast(s32) ((1 << APREC) * (1.0 - expf(-2.3 / (sigma + 1.0))));
    fons__blurRows(dst, w, h, dstStride, alpha);
    fons__blurCols(dst, w, h, dstStride, alpha);
    fons__blurRows(dst, w, h, dstStride, alpha);
    fons__blurCols(dst, w, h, dstStride, alpha);
    // fons__blurrows(dst, w, h, dstStride, alpha);
    // fons__blurcols(dst, w, h, dstStride, alpha);
}

fons__allocFont :: (stash: *FONScontext) -> s32 {
    if (stash.nfonts + 1 > stash.cfonts) {
        stash.cfonts = ifx stash.cfonts == 0 then 8 else stash.cfonts * 2;
        stash.fonts = realloc(stash.fonts, stash.cfonts);
        if (stash.fonts == null) {
            return -1;
        }
    }

    font := alloc(FONSfont);
    if (font == null) {
        fons__freeFont(font);
        return FONS_INVALID;
    }

    font.glyphs = alloc(FONSglyph, FONS_INIT_GLYPHS);
    if (font.glyphs == null) {
        fons__freeFont(font);
        return FONS_INVALID;
    }
    font.cglyphs = FONS_INIT_GLYPHS;
    font.nglyphs = 0;

    stash.fonts[stash.nfonts] = font;
    stash.nfonts += 1;
    return stash.nfonts - 1;
}

fons__freeFont :: (font: *FONSfont) {
    if (font == null) return;
    if (font.glyphs) free(font.glyphs);
    if (font.freeData && font.data) free(font.data);
    free(font);
}

fons__allocGlyph :: (font: *FONSfont) -> *FONSglyph {
    if (font.nglyphs + 1 > font.cglyphs) {
        font.cglyphs = ifx font.cglyphs == 0 then 8 else font.cglyphs * 2;
        font.glyphs = realloc(font.glyphs, font.cglyphs);
        if (font.glyphs == null) return null;
    }
    font.nglyphs += 1;
    return *font.glyphs[font.nglyphs - 1];
}

fons__hashint :: (a: u32) -> u32 {
    a += ~(a<<15);
    a ^=  (a>>10);
    a +=  (a<<3);
    a ^=  (a>>6);
    a += ~(a<<11);
    a ^=  (a>>16);
    return a;
}

FONSttFontImpl :: struct {
    font: stbtt_fontinfo;
};

fons__tt_init :: (stash: *FONScontext) -> s32 {
    return 1;
}

fons__tt_done :: (stash: *FONScontext) -> s32 {
    return 1;
}

fons__tt_loadFont :: (stash: *FONScontext, font: *FONSttFontImpl, data: *u8, dataSize: s32, fontIndex: s32) -> s32 {
    font.font.userdata = stash;
    offset := stbtt_GetFontOffsetForIndex(data, fontIndex);
    if (offset == -1) return 0;
    return stbtt_InitFont(*font.font, data, offset);
}

fons__tt_getFontVMetrics :: (font: *FONSttFontImpl, ascent: *s32, descent: *s32, lineGap: *s32) {
    stbtt_GetFontVMetrics(*font.font, ascent, descent, lineGap);
}

fons__tt_getPixelHeightScale :: (font: *FONSttFontImpl, size: f32) -> f32 {
    return stbtt_ScaleForMappingEmToPixels(*font.font, size);
}

fons__tt_getGlyphIndex :: (font: *FONSttFontImpl, codepoint: u32) -> s32 {
    return stbtt_FindGlyphIndex(*font.font, codepoint);
}

fons__tt_buildGlyphBitmap :: (font: *FONSttFontImpl, glyph: s32, size: f32, scale: f32,
                              advance: *s32, lsb: *s32, x0: *s32, y0: *s32, x1: *s32, y1: *s32) -> s32
{
    stbtt_GetGlyphHMetrics(*font.font, glyph, advance, lsb);
    stbtt_GetGlyphBitmapBox(*font.font, glyph, scale, scale, x0, y0, x1, y1);
    return 1;
}

fons__tt_renderGlyphBitmap :: (font: *FONSttFontImpl, output: *u8, outWidth: s32, outHeight: s32, outStride: s32,
                               scaleX: f32, scaleY: f32, glyph: s32)
{
    stbtt_MakeGlyphBitmap(*font.font, output, outWidth, outHeight, outStride, scaleX, scaleY, glyph);
}

fons__tt_getGlyphKernAdvance :: (font: *FONSttFontImpl, glyph1: s32, glyph2: s32) -> s32 {
    return stbtt_GetGlyphKernAdvance(*font.font, glyph1, glyph2);
}