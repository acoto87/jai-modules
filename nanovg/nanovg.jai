//
// Copyright (C) 2020 Alejandro Coto Gutiérrez (https://github.com/acoto87)
//
// This software is provided 'as-is', without any express or implied
// warranty.  In no event will the authors be held liable for any damages
// arising from the use of this software.
//
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it
// freely, subject to the following restrictions:
//
// 1. The origin of this software must not be misrepresented; you must not
//    claim that you wrote the original software. If you use this software
//    in a product, an acknowledgment in the product documentation would be
//    appreciated but is not required.
// 2. Altered source versions must be plainly marked as such, and must not be
//    misrepresented as being the original software.
// 3. This notice may not be removed or altered from any source distribution.
//
// NanoVG-jai is a library written in Jai.
//
// It is a port from the original [NanoVG](https://github.com/memononen/nanovg)
// written in C by memononen (https://github.com/memononen).
//
// The ported code includes the following modifications:
//
// 27 Feb 2019 - Modified by Alejandro Coto - @acoto87.
//     The NVG_DISABLE_CULL_FACE will disable GL_CULL_FACE to allow negative scaling of sprites and paths.
//

// Matrices are represented by a [6] f32 array
// This refers to the following 2d matrix
//   [sx kx tx]
//   [ky sy ty]
//   [ 0  0  1]

NVG_INIT_FONTIMAGE_SIZE : s32 : 512;
NVG_MAX_FONTIMAGE_SIZE  : s32 : 2048;
NVG_MAX_FONTIMAGES      : s32 : 4;

NVG_INIT_COMMANDS_SIZE  : s32 : 256;
NVG_INIT_POINTS_SIZE    : s32 : 128;
NVG_INIT_PATHS_SIZE     : s32 : 16;
NVG_INIT_VERTS_SIZE     : s32 : 256;
NVG_MAX_STATES          : s32 : 32;

NVG_KAPPA90 : f32 : 0.5522847493; // Length proportional to radius of a cubic bezier handle for 90deg arcs.
NVG_PI      : f32 : 3.14159265358979323846264338327;

NVGcommands :: enum s32 {
    NVG_MOVETO   :: 0;
    NVG_LINETO   :: 1;
    NVG_BEZIERTO :: 2;
    NVG_CLOSE    :: 3;
    NVG_WINDING  :: 4;
}

NVGcommand :: struct {
    type: NVGcommands;
    args: [6] f32;
}

NVGpointFlags :: enum s32 {
    NVG_PT_CORNER     :: 1;
    NVG_PT_LEFT       :: 2;
    NVG_PT_BEVEL      :: 4;
    NVG_PR_INNERBEVEL :: 8;
}

NVGstate :: struct {
    compositeOperation: NVGcompositeOperationState;
    shapeAntiAlias: s32;
    fill: NVGpaint;
    stroke: NVGpaint;
    strokeWidth: f32;
    miterLimit: f32;
    lineJoin: NVGlineCap;
    lineCap: NVGlineCap;
    alpha: f32;
    xform: [6] f32;
    scissor: NVGscissor;
    fontSize: f32;
    letterSpacing: f32;
    lineHeight: f32;
    fontBlur: f32;
    textAlign: NVGalign;
    fontId: s32;
}

NVGcontext :: struct {
    params: NVGparams;
    commands: List(NVGcommand);
    commandx: f32;
    commandy: f32;
    states: [NVG_MAX_STATES] NVGstate;
    nstates: s32;
    cache: *NVGpathCache;
    tessTol: f32;
    distTol: f32;
    fringeWidth: f32;
    devicePxRatio: f32;
    fs: *FONScontext;
    fontImages: [NVG_MAX_FONTIMAGES] s32;
    fontImageIdx: s32;
    drawCallCount: s32;
    fillTriCount: s32;
    strokeTriCount: s32;
    textTriCount: s32;
}

NVGpoint :: struct {
    x,y: f32;
    dx, dy: f32;
    len: f32;
    dmx, dmy: f32;
    flags: NVGpointFlags;
}

NVGpathCache :: struct {
    points: List(NVGpoint);
    paths: List(NVGpath);
    verts: List(NVGvertex);
    bounds: [4] f32;
}

NVGcolor :: union {
    rgba: [4] f32;
    struct {
        r,g,b,a: f32;
    };
}

NVGpaint :: struct {
    xform: [6] f32;
    extent: [2] f32;
    radius: f32;
    feather: f32;
    innerColor: NVGcolor;
    outerColor: NVGcolor;
    image: s32;
}

NVGwinding :: enum s32 {
    NVG_CCW :: 1;         // CCW
    NVG_CW  :: 2;         // CW
}

NVGsolidity :: enum s32 {
    NVG_SOLID :: 1;       // Winding for solid shapes
    NVG_HOLE  :: 2;       // Winding for holes
}

NVGlineCap :: enum s32 {
    NVG_BUTT;
    NVG_ROUND;
    NVG_SQUARE;
    NVG_BEVEL;
    NVG_MITER;
}

NVGalign :: enum s32 {
    // Horizontal align
    NVG_ALIGN_LEFT     :: 1<<0;    // Default, align text horizontally to left.
    NVG_ALIGN_CENTER   :: 1<<1;    // Align text horizontally to center.
    NVG_ALIGN_RIGHT    :: 1<<2;    // Align text horizontally to right.
    // Vertical align
    NVG_ALIGN_TOP      :: 1<<3;    // Align text vertically to top.
    NVG_ALIGN_MIDDLE   :: 1<<4;    // Align text vertically to middle.
    NVG_ALIGN_BOTTOM   :: 1<<5;    // Align text vertically to bottom.
    NVG_ALIGN_BASELINE :: 1<<6;    // Default, align text vertically to baseline.
}

NVGblendFactor :: enum s32 {
    NVG_ZERO                :: 1<<0;
    NVG_ONE                 :: 1<<1;
    NVG_SRC_COLOR           :: 1<<2;
    NVG_ONE_MINUS_SRC_COLOR :: 1<<3;
    NVG_DST_COLOR           :: 1<<4;
    NVG_ONE_MINUS_DST_COLOR :: 1<<5;
    NVG_SRC_ALPHA           :: 1<<6;
    NVG_ONE_MINUS_SRC_ALPHA :: 1<<7;
    NVG_DST_ALPHA           :: 1<<8;
    NVG_ONE_MINUS_DST_ALPHA :: 1<<9;
    NVG_SRC_ALPHA_SATURATE  :: 1<<10;
}

NVGcompositeOperation :: enum s32 {
    NVG_SOURCE_OVER;
    NVG_SOURCE_IN;
    NVG_SOURCE_OUT;
    NVG_ATOP;
    NVG_DESTINATION_OVER;
    NVG_DESTINATION_IN;
    NVG_DESTINATION_OUT;
    NVG_DESTINATION_ATOP;
    NVG_LIGHTER;
    NVG_COPY;
    NVG_XOR;
}

NVGcompositeOperationState :: struct {
    srcRGB: NVGblendFactor;
    dstRGB: NVGblendFactor;
    srcAlpha: NVGblendFactor;
    dstAlpha: NVGblendFactor;
}

NVGglyphPosition :: struct {
    str: *u8;           // Position of the glyph in the input string.
    x: f32;             // The x-coordinate of the logical glyph position.
    minx, maxx: f32;    // The bounds of the glyph shape.
}

NVGtextRow :: struct {
    start: *u8;         // Pointer to the input text where the row starts.
    end: *u8;           // Pointer to the input text where the row ends (one past the last character).
    next: *u8;          // Pointer to the beginning of the next row.
    width: f32;         // Logical width of the row.
    minx, maxx: f32;    // Actual bounds of the row. Logical with and bounds can differ because of kerning and some parts over extending.
}

NVGimageFlags :: enum {
    NVG_IMAGE_GENERATE_MIPMAPS :: 1<<0;    // Generate mipmaps during creation of the image.
    NVG_IMAGE_REPEATX          :: 1<<1;    // Repeat image in X direction.
    NVG_IMAGE_REPEATY          :: 1<<2;    // Repeat image in Y direction.
    NVG_IMAGE_FLIPY            :: 1<<3;    // Flips (inverses) image in Y direction when rendered.
    NVG_IMAGE_PREMULTIPLIED    :: 1<<4;    // Image data has premultiplied alpha.
    NVG_IMAGE_NEAREST          :: 1<<5;    // Image interpolation is Nearest instead Linear.
    NVG_IMAGE_NODELETE         :: 1<<16;   // Do not delete image/handle.
}

NVGcodepointType :: enum s32 {
    NVG_SPACE :: 0;
    NVG_NEWLINE :: 1;
    NVG_CHAR :: 2;
    NVG_CJK_CHAR :: 3;
};

// Begin drawing a new frame
// Calls to nanovg drawing API should be wrapped in nvgBeginFrame() & nvgEndFrame()
// nvgBeginFrame() defines the size of the window to render to in relation currently
// set viewport (i.e. glViewport on GL backends). Device pixel ration allows to
// control the rendering on Hi-DPI devices.
// For example, GLFW returns two dimension for an opened window: window size and
// frame buffer size. In that case you would set windowWidth/Height to the window size
// devicePixelRatio to: frameBufferWidth / windowWidth.
nvgBeginFrame :: (ctx: *NVGcontext, windowWidth: f32, windowHeight: f32, devicePixelRatio: f32) {
    ctx.nstates = 0;
    nvgSave(ctx);
    nvgReset(ctx);

    nvg__setDevicePixelRatio(ctx, devicePixelRatio);

    ctx.params.renderViewport(ctx.params.userPtr, windowWidth, windowHeight, devicePixelRatio);

    ctx.drawCallCount = 0;
    ctx.fillTriCount = 0;
    ctx.strokeTriCount = 0;
    ctx.textTriCount = 0;
}

// Cancels drawing the current frame.
nvgCancelFrame :: (ctx: *NVGcontext) {
    ctx.params.renderCancel(ctx.params.userPtr);
}

// Ends drawing flushing remaining render state.
nvgEndFrame :: (ctx: *NVGcontext) {
    ctx.params.renderFlush(ctx.params.userPtr);

    if (ctx.fontImageIdx != 0) {
        fontImage := ctx.fontImages[ctx.fontImageIdx];

        // delete images that smaller than current one
        if (fontImage == 0) {
            return;
        }

        iw, ih: s32;
        nvgImageSize(ctx, fontImage, *iw, *ih);

        i, j: s32 = 0;
        while (i < ctx.fontImageIdx) {
            if (ctx.fontImages[i] != 0) {
                nw, nh: s32;
                nvgImageSize(ctx, ctx.fontImages[i], *nw, *nh);
                if (nw < iw || nh < ih) {
                    nvgDeleteImage(ctx, ctx.fontImages[i]);
                } else {
                    ctx.fontImages[j] = ctx.fontImages[i];
                    j += 1;
                }
            }
            i += 1;
        }

        // make current font image to first
        ctx.fontImages[j] = ctx.fontImages[0];
        j += 1;

        ctx.fontImages[0] = fontImage;
        ctx.fontImageIdx = 0;

        // clear all images after j
        i = j;
        while (i < NVG_MAX_FONTIMAGES) {
            ctx.fontImages[i] = 0;
            i += 1;
        }
    }
}

//
// Composite operation
//
// The composite operations in NanoVG are modeled after HTML Canvas API, and
// the blend func is based on OpenGL (see corresponding manuals for more info).
// The colors in the blending state have premultiplied alpha.

// Sets the composite operation. The op parameter should be one of NVGcompositeOperation.
nvgGlobalCompositeOperation :: (ctx: *NVGcontext, op: NVGcompositeOperation) {
    state := nvg__getState(ctx);
    state.compositeOperation = nvg__compositeOperationState(op);
}

// Sets the composite operation with custom pixel arithmetic. The parameters should be one of NVGblendFactor.
nvgGlobalCompositeBlendFunc :: (ctx: *NVGcontext, sfactor: NVGblendFactor, dfactor: NVGblendFactor) {
    nvgGlobalCompositeBlendFuncSeparate(ctx, sfactor, dfactor, sfactor, dfactor);
}

// Sets the composite operation with custom pixel arithmetic for RGB and alpha components separately. The parameters should be one of NVGblendFactor.
nvgGlobalCompositeBlendFuncSeparate :: (ctx: *NVGcontext, srcRGB: NVGblendFactor, dstRGB: NVGblendFactor, srcAlpha: NVGblendFactor, dstAlpha: NVGblendFactor) {
    op: NVGcompositeOperationState = ---;
    op.srcRGB = srcRGB;
    op.dstRGB = dstRGB;
    op.srcAlpha = srcAlpha;
    op.dstAlpha = dstAlpha;

    state := nvg__getState(ctx);
    state.compositeOperation = op;
}

//
// Color utils
//
// Colors in NanoVG are stored as unsigned ints in ABGR format.

// Returns a color value from red, green, blue values. Alpha will be set to 255 (1.0f).
nvgRGB :: (r: u8, g: u8, b: u8) -> NVGcolor {
    return nvgRGBA(r, g, b, 255);
}

// Returns a color value from red, green, blue values. Alpha will be set to 1.0f.
nvgRGBf :: (r: f32, g: f32, b: f32) -> NVGcolor {
    return nvgRGBAf(r, g, b, 1.0);
}

// Returns a color value from red, green, blue and alpha values.
nvgRGBA :: (r: u8, g: u8, b: u8, a: u8) -> NVGcolor {
    color: NVGcolor = ---;
    color.g = g / 255.0;
    color.r = r / 255.0;
    color.b = b / 255.0;
    color.a = a / 255.0;
    return color;
}

// Returns a color value from red, green, blue and alpha values.
nvgRGBAf :: (r: f32, g: f32, b: f32, a: f32) -> NVGcolor {
    color: NVGcolor = ---;
    color.r = r;
    color.g = g;
    color.b = b;
    color.a = a;
    return color;
}

// Linearly interpolates from color c0 to c1, and returns resulting color value.
nvgLerpRGBA :: (c0: NVGcolor, c1: NVGcolor, u: float) -> NVGcolor {
    cint: NVGcolor;

    u = clamp(u, 0.0, 1.0);
    oneminu: f32 = 1.0 - u;
    for i : 0..3 {
        cint.rgba[i] = c0.rgba[i] * oneminu + c1.rgba[i] * u;
    }

    return cint;
}

// Sets transparency of a color value.
nvgTransRGBA :: (c: NVGcolor, a: u8) -> NVGcolor {
    return nvgRGBAf(c.r, c.g, c.b, a / 255.0);
}

// Sets transparency of a color value.
nvgTransRGBAf :: (c: NVGcolor, a: f32) -> NVGcolor {
    return nvgRGBAf(c.r, c.g, c.b, a);
}

// Returns color value specified by hue, saturation and lightness.
// HSL values are all in range [0..1], alpha will be set to 255.
nvgHSL :: (h: f32, s: f32, l: f32) -> NVGcolor {
    return nvgHSLA(h, s, l, 255);
}

// Returns color value specified by hue, saturation and lightness and alpha.
// HSL values are all in range [0..1], alpha in range [0..255]
nvgHSLA :: (h: f32, s: f32, l: f32, a: u8) -> NVGcolor {
    h = fmodf(h, 1.0);
    if (h < 0.0) {
        h += 1.0;
    }
    s = clamp(s, 0.0, 1.0);
    l = clamp(l, 0.0, 1.0);

    m2: f32 = ifx l <= 0.5 then (l * (1 + s)) else (l + s - l * s);
    m1: f32 = 2 * l - m2;

    col: NVGcolor = ---;
    col.r = clamp(nvg__hue(h + 1.0 / 3.0, m1, m2), 0.0, 1.0);
    col.g = clamp(nvg__hue(h, m1, m2), 0.0, 1.0);
    col.b = clamp(nvg__hue(h - 1.0 / 3.0, m1, m2), 0.0, 1.0);
    col.a = a / 255.0;
    return col;
}

//
// State Handling
//
// NanoVG contains state which represents how paths will be rendered.
// The state contains transform, fill and stroke styles, text and font styles,
// and scissor clipping.

// Pushes and saves the current render state into a state stack.
// A matching nvgRestore() must be used to restore the state.
nvgSave :: (ctx: *NVGcontext) {
    if (ctx.nstates >= NVG_MAX_STATES) {
        return;
    }
    if (ctx.nstates > 0) {
        ctx.states[ctx.nstates] = ctx.states[ctx.nstates - 1];
    }
    ctx.nstates += 1;
}

// Pops and restores current render state.
nvgRestore :: (ctx: *NVGcontext) {
    if (ctx.nstates <= 1) {
        return;
    }
    ctx.nstates -= 1;
}

// Resets current render state to default values. Does not affect the render state stack.
nvgReset :: (ctx: *NVGcontext) {
    state := nvg__getState(ctx);
    memoryClear(state);

    nvg__setPaintColor(*state.fill, nvgRGBA(255,255,255,255));
    nvg__setPaintColor(*state.stroke, nvgRGBA(0,0,0,255));
    state.compositeOperation = nvg__compositeOperationState(.NVG_SOURCE_OVER);
    state.shapeAntiAlias = 1;
    state.strokeWidth = 1.0;
    state.miterLimit = 10.0;
    state.lineCap = .NVG_BUTT;
    state.lineJoin = .NVG_MITER;
    state.alpha = 1.0;
    nvgTransformIdentity(state.xform);

    state.scissor.extent[0] = -1.0;
    state.scissor.extent[1] = -1.0;

    state.fontSize = 16.0;
    state.letterSpacing = 0.0;
    state.lineHeight = 1.0;
    state.fontBlur = 0.0;
    state.textAlign = NVGalign.NVG_ALIGN_LEFT | .NVG_ALIGN_BASELINE;
    state.fontId = 0;
}

//
// Render styles
//
// Fill and stroke render style can be either a solid color or a paint which is a gradient or a pattern.
// Solid color is simply defined as a color value, different kinds of paints can be created
// using nvgLinearGradient(), nvgBoxGradient(), nvgRadialGradient() and nvgImagePattern().
//
// Current render style can be saved and restored using nvgSave() and nvgRestore().

// Sets whether to draw antialias for nvgStroke() and nvgFill(). It's enabled by default.
nvgShapeAntiAlias :: (ctx: *NVGcontext, enabled: s32) {
    state := nvg__getState(ctx);
    state.shapeAntiAlias = enabled;
}

// Sets current stroke style to a solid color.
nvgStrokeColor :: (ctx: *NVGcontext, color: NVGcolor) {
    state := nvg__getState(ctx);
    nvg__setPaintColor(*state.stroke, color);
}

// Sets current stroke style to a paint, which can be a one of the gradients or a pattern.
nvgStrokePaint :: (ctx: *NVGcontext, paint: NVGpaint) {
    state := nvg__getState(ctx);
    state.stroke = paint;
    nvgTransformMultiply(state.stroke.xform, state.xform);
}

// Sets current fill style to a solid color.
nvgFillColor :: (ctx: *NVGcontext, color: NVGcolor) {
    state := nvg__getState(ctx);
    nvg__setPaintColor(*state.fill, color);
}

// Sets current fill style to a paint, which can be a one of the gradients or a pattern.
nvgFillPaint :: (ctx: *NVGcontext, paint: NVGpaint) {
    state := nvg__getState(ctx);
    state.fill = paint;
    nvgTransformMultiply(state.fill.xform, state.xform);
}

// Sets the miter limit of the stroke style.
// Miter limit controls when a sharp corner is beveled.
nvgMiterLimit :: (ctx: *NVGcontext, limit: f32) {
    state := nvg__getState(ctx);
    state.miterLimit = limit;
}

// Sets the stroke width of the stroke style.
nvgStrokeWidth :: (ctx: *NVGcontext, width: f32) {
    state := nvg__getState(ctx);
    state.strokeWidth = width;
}

// Sets how the end of the line (cap) is drawn,
// Can be one of: NVG_BUTT (default), NVG_ROUND, NVG_SQUARE.
nvgLineCap :: (ctx: *NVGcontext, cap: NVGlineCap) {
    state := nvg__getState(ctx);
    state.lineCap = cap;
}

// Sets how sharp path corners are drawn.
// Can be one of NVG_MITER (default), NVG_ROUND, NVG_BEVEL.
nvgLineJoin :: (ctx: *NVGcontext, join: NVGlineCap) {
    state := nvg__getState(ctx);
    state.lineJoin = join;
}

// Sets the transparency applied to all rendered shapes.
// Already transparent paths will get proportionally more transparent as well.
nvgGlobalAlpha :: (ctx: *NVGcontext, alpha: f32) {
    state := nvg__getState(ctx);
    state.alpha = alpha;
}

//
// Transforms
//
// The paths, gradients, patterns and scissor region are transformed by an transformation
// matrix at the time when they are passed to the API.
// The current transformation matrix is a affine matrix:
//   [sx kx tx]
//   [ky sy ty]
//   [ 0  0  1]
// Where: sx,sy define scaling, kx,ky skewing, and tx,ty translation.
// The last row is assumed to be 0,0,1 and is not stored.
//
// Apart from nvgResetTransform(), each transformation function first creates
// specific transformation matrix and pre-multiplies the current transformation by it.
//
// Current coordinate system (transformation) can be saved and restored using nvgSave() and nvgRestore().

// Resets current transform to a identity matrix.
nvgResetTransform :: (ctx: *NVGcontext) {
    state := nvg__getState(ctx);
    nvgTransformIdentity(state.xform);
}

// Premultiplies current coordinate system by specified matrix.
// The parameters are interpreted as matrix as follows:
//   [a c e]
//   [b d f]
//   [0 0 1]
nvgTransform :: (ctx: *NVGcontext, a: f32, b: f32, c: f32, d: f32, e: f32, f: f32) {
    state := nvg__getState(ctx);
    t: [6] f32 = ---;
    t[0] = a; t[1] = b; t[2] = c;
    t[3] = d; t[4] = e; t[5] = f;
    nvgTransformPremultiply(state.xform, t);
}

// Translates current coordinate system.
nvgTranslate :: (ctx: *NVGcontext, x: f32, y: f32) {
    state := nvg__getState(ctx);
    t: [6] f32 = ---;
    nvgTransformTranslate(t, x, y);
    nvgTransformPremultiply(state.xform, t);
}

// Rotates current coordinate system. Angle is specified in radians.
nvgRotate :: (ctx: *NVGcontext, angle: f32) {
    state := nvg__getState(ctx);
    t: [6] f32 = ---;
    nvgTransformRotate(t, angle);
    nvgTransformPremultiply(state.xform, t);
}

// Skews the current coordinate system along X axis. Angle is specified in radians.
nvgSkewX :: (ctx: *NVGcontext, angle: f32) {
    state := nvg__getState(ctx);
    t: [6] f32 = ---;
    nvgTransformSkewX(t, angle);
    nvgTransformPremultiply(state.xform, t);
}

// Skews the current coordinate system along Y axis. Angle is specified in radians.
nvgSkewY :: (ctx: *NVGcontext, angle: f32) {
    state := nvg__getState(ctx);
    t: [6] f32 = ---;
    nvgTransformSkewY(t, angle);
    nvgTransformPremultiply(state.xform, t);
}

// Scales the current coordinate system.
nvgScale :: (ctx: *NVGcontext, x: f32, y: f32) {
    state := nvg__getState(ctx);
    t: [6] f32 = ---;
    nvgTransformScale(t, x, y);
    nvgTransformPremultiply(state.xform, t);
}

// Stores the top part (a-f) of the current transformation matrix in to the specified buffer.
//   [a c e]
//   [b d f]
//   [0 0 1]
// There should be space for 6 floats in the return buffer for the values a-f.
nvgCurrentTransform :: (ctx: *NVGcontext, xform: [] f32) {
    state := nvg__getState(ctx);
    arrayCopy(state.xform, xform, 6);
}

// The following functions can be used to make calculations on 2x3 transformation matrices.
// A 2x3 matrix is represented as float[6].

// Sets the transform to identity matrix.
nvgTransformIdentity :: (t: [] f32) {
    t[0] = 1.0; t[1] = 0.0;
    t[2] = 0.0; t[3] = 1.0;
    t[4] = 0.0; t[5] = 0.0;
}

// Sets the transform to translation matrix matrix.
nvgTransformTranslate :: (t: [] f32, tx: f32, ty: f32) {
    t[0] = 1.0; t[1] = 0.0;
    t[2] = 0.0; t[3] = 1.0;
    t[4] = tx;  t[5] = ty;
}

// Sets the transform to scale matrix.
nvgTransformScale :: (t: [] f32, sx: f32, sy: f32) {
    t[0] = sx;  t[1] = 0.0;
    t[2] = 0.0; t[3] = sy;
    t[4] = 0.0; t[5] = 0.0;
}

// Sets the transform to rotate matrix. Angle is specified in radians.
nvgTransformRotate :: (t: [] f32, a: f32) {
    cs := cosf(a);
    sn := sinf(a);
    t[0] = cs;  t[1] = sn;
    t[2] = -sn; t[3] = cs;
    t[4] = 0.0; t[5] = 0.0;
}

// Sets the transform to skew-x matrix. Angle is specified in radians.
nvgTransformSkewX :: (t: [] f32, a: f32) {
    t[0] = 1.0;     t[1] = 0.0;
    t[2] = tanf(a); t[3] = 1.0;
    t[4] = 0.0;     t[5] = 0.0;
}

// Sets the transform to skew-y matrix. Angle is specified in radians.
nvgTransformSkewY :: (t: [] f32, a: f32) {
    t[0] = 1.0; t[1] = tanf(a);
    t[2] = 0.0; t[3] = 1.0;
    t[4] = 0.0; t[5] = 0.0;
}

// Sets the transform to the result of multiplication of two transforms, of A = A*B.
nvgTransformMultiply :: (t: [] f32, s: [] f32) {
    t0 := t[0] * s[0] + t[1] * s[2];
    t2 := t[2] * s[0] + t[3] * s[2];
    t4 := t[4] * s[0] + t[5] * s[2] + s[4];
    t[1] = t[0] * s[1] + t[1] * s[3];
    t[3] = t[2] * s[1] + t[3] * s[3];
    t[5] = t[4] * s[1] + t[5] * s[3] + s[5];
    t[0] = t0;
    t[2] = t2;
    t[4] = t4;
}

// Sets the transform to the result of multiplication of two transforms, of A = B*A.
nvgTransformPremultiply :: (t: [] f32, s: [] f32) {
    s2: [6] f32 = ---;
    arrayCopy(s, s2, 6);
    nvgTransformMultiply(s2, t);
    arrayCopy(s2, t, 6);
}

// Sets the destination to inverse of specified transform.
// Returns 1 if the inverse could be calculated, else 0.
nvgTransformInverse :: (inv: [] f32, t: [] f32) -> bool {
    det: f64 = cast(f64) t[0] * t[3] - cast(f64) t[2] * t[1];
    if (det > -1.0e-6 && det < 1.0e-6) {
        nvgTransformIdentity(inv);
        return false;
    }
    invdet := 1.0 / det;
    inv[0] = cast(f32) (t[3] * invdet);
    inv[2] = cast(f32) (-t[2] * invdet);
    inv[4] = cast(f32) ((cast(f64) t[2] * t[5] - cast(f64) t[3] * t[4]) * invdet);
    inv[1] = cast(f32) (-t[1] * invdet);
    inv[3] = cast(f32) (t[0] * invdet);
    inv[5] = cast(f32) ((cast(f64) t[1] * t[4] - cast(f64) t[0] * t[5]) * invdet);
    return true;
}

// Transform a point by given transform.
nvgTransformPoint :: (t: [] f32, x: f32, y: f32) -> f32, f32 {
    return x * t[0] + y * t[2] + t[4],
           x * t[1] + y * t[3] + t[5];
}

// Converts degrees to radians and vice versa.
nvgDegToRad :: (deg: f32) -> f32 {
    return deg / 180.0 * NVG_PI;
}

nvgRadToDeg :: (rad: f32) -> f32 {
    return rad / NVG_PI * 180.0;
}

//
// Images
//
// NanoVG allows you to load jpg, png, psd, tga, pic and gif files to be used for rendering.
// In addition you can upload your own image. The image loading is provided by stb_image.
// The parameter imageFlags is combination of flags defined in NVGimageFlags.

// Creates image by loading it from the disk from specified file name.
// Returns handle to the image.
nvgCreateImage :: (ctx: *NVGcontext, filename: *u8, imageFlags: NVGimageFlags) -> s32 {
    // @Check
    // stbi_set_unpremultiply_on_load(1);
    // stbi_convert_iphone_png_to_rgb(1);

    w, h, n: s32;
    img := stbi_load(filename, *w, *h, *n, 4);
    if (img == null) {
        return 0;
    }
    image := nvgCreateImageRGBA(ctx, w, h, imageFlags, img);
    stbi_image_free(img);
    return image;
}

// Creates image by loading it from the specified chunk of memory.
// Returns handle to the image.
nvgCreateImageMem :: (ctx: *NVGcontext, imageFlags: NVGimageFlags, data: *u8, ndata: s32) -> s32 {
    w, h, n: s32;
    img := stbi_load_from_memory(data, ndata, *w, *h, *n, 4);
    if (img == null) {
        return 0;
    }
    image := nvgCreateImageRGBA(ctx, w, h, imageFlags, img);
    stbi_image_free(img);
    return image;
}

// Creates image from specified image data.
// Returns handle to the image.
nvgCreateImageRGBA :: (ctx: *NVGcontext, w: s32, h: s32, imageFlags: NVGimageFlags, data: *u8) -> s32 {
    return ctx.params.renderCreateTexture(ctx.params.userPtr, .NVG_TEXTURE_RGBA, w, h, imageFlags, data);
}

// Updates image data specified by image handle.
nvgUpdateImage :: (ctx: *NVGcontext, image: s32, data: *u8) {
    w, h: s32;
    ctx.params.renderGetTextureSize(ctx.params.userPtr, image, *w, *h);
    ctx.params.renderUpdateTexture(ctx.params.userPtr, image, 0, 0, w, h, data);
}

// Returns the dimensions of a created image.
nvgImageSize :: (ctx: *NVGcontext, image: s32, w: *s32, h: *s32) {
    ctx.params.renderGetTextureSize(ctx.params.userPtr, image, w, h);
}

// Deletes created image.
nvgDeleteImage :: (ctx: *NVGcontext, image: s32) {
    ctx.params.renderDeleteTexture(ctx.params.userPtr, image);
}

//
// Paints
//
// NanoVG supports four types of paints: linear gradient, box gradient, radial gradient and image pattern.
// These can be used as paints for strokes and fills.

// Creates and returns a linear gradient. Parameters (sx,sy)-(ex,ey) specify the start and end coordinates
// of the linear gradient, icol specifies the start color and ocol the end color.
// The gradient is transformed by the current transform when it is passed to nvgFillPaint() or nvgStrokePaint().
nvgLinearGradient :: (ctx: *NVGcontext, sx: f32, sy: f32, ex: f32, ey: f32, icol: NVGcolor, ocol: NVGcolor) -> NVGpaint {
    // Calculate transform aligned to the line
    dx := ex - sx;
    dy := ey - sy;
    d := sqrtf(dx * dx + dy * dy);
    if (d > 0.0001) {
        dx /= d;
        dy /= d;
    } else {
        dx = 0;
        dy = 1;
    }

    large: f32 = 1.0e5;

    p: NVGpaint;
    p.xform[0] = dy;
    p.xform[1] = -dx;
    p.xform[2] = dx;
    p.xform[3] = dy;
    p.xform[4] = sx - dx * large;
    p.xform[5] = sy - dy * large;

    p.extent[0] = large;
    p.extent[1] = large + d * 0.5;

    p.radius = 0.0;

    p.feather = max(1.0, d);

    p.innerColor = icol;
    p.outerColor = ocol;

    return p;
}

// Creates and returns a box gradient. Box gradient is a feathered rounded rectangle, it is useful for rendering
// drop shadows or highlights for boxes. Parameters (x,y) define the top-left corner of the rectangle,
// (w,h) define the size of the rectangle, r defines the corner radius, and f feather. Feather defines how blurry
// the border of the rectangle is. Parameter icol specifies the inner color and ocol the outer color of the gradient.
// The gradient is transformed by the current transform when it is passed to nvgFillPaint() or nvgStrokePaint().
nvgBoxGradient :: (ctx: *NVGcontext, x: f32, y: f32, w: f32, h: f32, r: f32, f: f32, icol: NVGcolor, ocol: NVGcolor) -> NVGpaint {
    p: NVGpaint;
    nvgTransformIdentity(p.xform);
    p.xform[4] = x + w * 0.5;
    p.xform[5] = y + h * 0.5;

    p.extent[0] = w * 0.5;
    p.extent[1] = h * 0.5;

    p.radius = r;

    p.feather = max(1.0, f);

    p.innerColor = icol;
    p.outerColor = ocol;

    return p;
}

// Creates and returns a radial gradient. Parameters (cx,cy) specify the center, inr and outr specify
// the inner and outer radius of the gradient, icol specifies the start color and ocol the end color.
// The gradient is transformed by the current transform when it is passed to nvgFillPaint() or nvgStrokePaint().
nvgRadialGradient :: (ctx: *NVGcontext, cx: f32, cy: f32, inr: f32, outr: f32, icol: NVGcolor, ocol: NVGcolor) -> NVGpaint {
    r := (inr + outr) * 0.5;
    f := (outr - inr);

    p: NVGpaint;
    nvgTransformIdentity(p.xform);
    p.xform[4] = cx;
    p.xform[5] = cy;

    p.extent[0] = r;
    p.extent[1] = r;

    p.radius = r;

    p.feather = max(1.0, f);

    p.innerColor = icol;
    p.outerColor = ocol;

    return p;
}

// Creates and returns an image patter. Parameters (ox,oy) specify the left-top location of the image pattern,
// (ex,ey) the size of one image, angle rotation around the top-left corner, image is handle to the image to render.
// The gradient is transformed by the current transform when it is passed to nvgFillPaint() or nvgStrokePaint().
nvgImagePattern :: (ctx: *NVGcontext, cx: f32, cy: f32, w: f32, h: f32, angle: f32, image: s32, alpha: f32) -> NVGpaint {
    p: NVGpaint;
    nvgTransformRotate(p.xform, angle);
    p.xform[4] = cx;
    p.xform[5] = cy;

    p.extent[0] = w;
    p.extent[1] = h;

    p.image = image;

    p.innerColor = nvgRGBAf(1, 1, 1, alpha);
    p.outerColor = p.innerColor;

    return p;
}

//
// Scissoring
//
// Scissoring allows you to clip the rendering into a rectangle. This is useful for various
// user interface cases like rendering a text edit or a timeline.

// Sets the current scissor rectangle.
// The scissor rectangle is transformed by the current transform.
nvgScissor :: (ctx: *NVGcontext, x: f32, y: f32, w: f32, h: f32) {
    state := nvg__getState(ctx);

    w = max(0.0, w);
    h = max(0.0, h);

    nvgTransformIdentity(state.scissor.xform);
    state.scissor.xform[4] = x + w * 0.5;
    state.scissor.xform[5] = y + h * 0.5;
    nvgTransformMultiply(state.scissor.xform, state.xform);

    state.scissor.extent[0] = w * 0.5;
    state.scissor.extent[1] = h * 0.5;
}

// Intersects current scissor rectangle with the specified rectangle.
// The scissor rectangle is transformed by the current transform.
// Note: in case the rotation of previous scissor rect differs from
// the current one, the intersection will be done between the specified
// rectangle and the previous scissor rectangle transformed in the current
// transform space. The resulting shape is always rectangle.
nvgIntersectScissor :: (ctx: *NVGcontext, x: f32, y: f32, w: f32, h: f32) {
    state := nvg__getState(ctx);

    // If no previous scissor has been set, set the scissor as current scissor.
    if (state.scissor.extent[0] < 0) {
        nvgScissor(ctx, x, y, w, h);
        return;
    }

    // Transform the current scissor rect into current transform space.
    // If there is difference in rotation, this will be approximation.
    pxform: [6] f32 = ---;
    arrayCopy(state.scissor.xform, pxform, 6);

    ex := state.scissor.extent[0];
    ey := state.scissor.extent[1];

    invxform: [6] f32 = ---;
    nvgTransformInverse(invxform, state.xform);
    nvgTransformMultiply(pxform, invxform);

    tex := ex * abs(pxform[0]) + ey * abs(pxform[2]);
    tey := ex * abs(pxform[1]) + ey * abs(pxform[3]);

    // Intersect rects.
    rect: [4] f32;
    nvg__isectRects(rect, pxform[4] - tex,pxform[5] - tey,tex * 2,tey * 2, x,y,w,h);

    nvgScissor(ctx, rect[0], rect[1], rect[2], rect[3]);
}

// Reset and disables scissoring.
nvgResetScissor :: (ctx: *NVGcontext) {
    state := nvg__getState(ctx);
    arrayClear(state.scissor.xform);
    state.scissor.extent[0] = -1.0;
    state.scissor.extent[1] = -1.0;
}

//
// Paths
//
// Drawing a new shape starts with nvgBeginPath(), it clears all the currently defined paths.
// Then you define one or more paths and sub-paths which describe the shape. The are functions
// to draw common shapes like rectangles and circles, and lower level step-by-step functions,
// which allow to define a path curve by curve.
//
// NanoVG uses even-odd fill rule to draw the shapes. Solid shapes should have counter clockwise
// winding and holes should have clockwise order. To specify winding of a path you can
// call nvgPathWinding(). This is useful especially for the common shapes, which are drawn CCW.
//
// Finally you can fill the path using current fill style by calling nvgFill(), and stroke it
// with current stroke style by calling nvgStroke().
//
// The curve segments and sub-paths are transformed by the current transform.

// Clears the current path and sub-paths.
nvgBeginPath :: (ctx: *NVGcontext) {
    clear(*ctx.commands);
    nvg__clearPathCache(ctx);
}

nvgBeginPathBatch :: (ctx: *NVGcontext) {
    clear(*ctx.commands);
    nvg__clearPathCache(ctx);
}

// Move to the specified point. This will start a new sub-path if it's not in batch.
nvgMoveTo :: (ctx: *NVGcontext, x: f32, y: f32) {
    nvg__appendCommands(ctx,
        nvg__command(.NVG_MOVETO, x, y)
    );
}

// Adds line segment from the last point in the path to the specified point.
nvgLineTo :: (ctx: *NVGcontext, x: f32, y: f32) {
    nvg__appendCommands(ctx,
        nvg__command(.NVG_LINETO, x, y)
    );
}

// Adds cubic bezier segment from last point in the path via two control points to the specified point.
nvgBezierTo :: (ctx: *NVGcontext, c1x: f32, c1y: f32, c2x: f32, c2y: f32, x: f32, y: f32) {
    nvg__appendCommands(ctx,
        nvg__command(.NVG_BEZIERTO, c1x, c1y, c2x, c2y, x, y)
    );
}

// Adds quadratic bezier segment from last point in the path via a control point to the specified point.
nvgQuadTo :: (ctx: *NVGcontext, cx: f32, cy: f32, x: f32, y: f32) {
    x0 := ctx.commandx;
    y0 := ctx.commandy;

    nvg__appendCommands(ctx,
        nvg__command(.NVG_BEZIERTO,
            x0 + 2.0 / 3.0 * (cx - x0),
            y0 + 2.0 / 3.0 * (cy - y0),
            x + 2.0 / 3.0 * (cx - x),
            y + 2.0 / 3.0 * (cy - y),
            x,
            y
        )
    );
}

// Adds an arc segment at the corner defined by the last path point, and two specified points.
nvgArcTo :: (ctx: *NVGcontext, x1: f32, y1: f32, x2: f32, y2: f32, radius: f32) {
    if (ctx.commands.count == 0) {
        return;
    }

    x0 := ctx.commandx;
    y0 := ctx.commandy;

    // Handle degenerate cases.
    if (nvg__ptEquals(x0, y0, x1, y1, ctx.distTol) ||
        nvg__ptEquals(x1,y1, x2,y2, ctx.distTol) ||
        nvg__distPtSeg(x1,y1, x0,y0, x2,y2) < ctx.distTol * ctx.distTol ||
        radius < ctx.distTol)
    {
        nvgLineTo(ctx, x1,y1);
        return;
    }

    // Calculate tangential circle to lines (x0,y0)-(x1,y1) and (x1,y1)-(x2,y2).
    dx0 := x0 - x1;
    dy0 := y0 - y1;
    dx1 := x2 - x1;
    dy1 := y2 - y1;
    nvg__normalize(*dx0, *dy0);
    nvg__normalize(*dx1, *dy1);
    a := acosf(dx0 * dx1 + dy0 * dy1);
    d := radius / tanf(a / 2.0);

    if (d > 10000.0) {
        nvgLineTo(ctx, x1,y1);
        return;
    }

    cx, cy, a0, a1: f32;
    dir: NVGwinding;
    if (nvg__cross(dx0,dy0, dx1,dy1) > 0.0) {
        cx = x1 + dx0 * d + dy0 * radius;
        cy = y1 + dy0 * d + -dx0 * radius;
        a0 = atan2f(dx0, -dy0);
        a1 = atan2f(-dx1, dy1);
        dir = .NVG_CW;
    } else {
        cx = x1 + dx0 * d + -dy0 * radius;
        cy = y1 + dy0 * d + dx0 * radius;
        a0 = atan2f(-dx0, dy0);
        a1 = atan2f(dx1, -dy1);
        dir = .NVG_CCW;
    }

    nvgArc(ctx, cx, cy, radius, a0, a1, dir);
}

// Closes current sub-path with a line segment.
nvgClosePath :: (ctx: *NVGcontext) {
    nvg__appendCommands(ctx,
        nvg__command(NVGcommands.NVG_CLOSE)
    );
}

// Sets the current sub-path winding, see NVGwinding and NVGsolidity.
nvgPathWinding :: (ctx: *NVGcontext, dir: NVGwinding) {
    nvg__appendCommands(ctx,
        nvg__command(NVGcommands.NVG_WINDING, cast(f32) dir)
    );
}

// Creates new circle arc shaped sub-path. The arc center is at cx,cy, the arc radius is r,
// and the arc is drawn from angle a0 to a1, and swept in direction dir (NVG_CCW, or NVG_CW).
// Angles are specified in radians.
nvgArc :: (ctx: *NVGcontext, cx: f32, cy: f32, r: f32, a0: f32, a1: f32, dir: NVGwinding) {
    // Clamp angles
    da := a1 - a0;
    if (dir == .NVG_CW) {
        if (abs(da) >= NVG_PI * 2) {
            da = NVG_PI * 2;
        } else {
            while (da < 0.0) {
                da += NVG_PI * 2;
            }
        }
    } else {
        if (abs(da) >= NVG_PI * 2) {
            da = -NVG_PI * 2;
        } else {
            while (da > 0.0) {
                da -= NVG_PI * 2;
            }
        }
    }

    // Split arc into max 90 degree segments.
    ndivs := max(1, min(cast(s32) (abs(da) / (NVG_PI * 0.5) + 0.5), 5));
    hda := (da / cast(f32) ndivs) / 2.0;
    kappa := abs(4.0 / 3.0 * (1.0 - cosf(hda)) / sinf(hda));

    if (dir == .NVG_CCW) {
        kappa = -kappa;
    }

    move := ifx ctx.commands.count > 0 then NVGcommands.NVG_LINETO else .NVG_MOVETO;

    cmds := allocArray(NVGcommand, ndivs + 1);
    defer free(cmds);

    px, py, ptanx, ptany: f32 = 0;

    for i : 0..ndivs {
        a := a0 + da * (i / cast(f32) ndivs);
        dx := cosf(a);
        dy := sinf(a);
        x := cx + dx * r;
        y := cy + dy * r;
        tanx := -dy * r * kappa;
        tany := dx * r * kappa;

        if (i == 0) {
            cmds[0] = nvg__command(move, x, y);
        } else {
            cmds[i] = nvg__command(
                .NVG_BEZIERTO,
                px + ptanx, py + ptany,
                x - tanx, y - tany,
                x, y
            );
        }
        px = x;
        py = y;
        ptanx = tanx;
        ptany = tany;
    }

    nvg__appendCommands(ctx, ..cmds);
}

// Creates new rectangle shaped sub-path.
nvgRect :: (ctx: *NVGcontext, x: f32, y: f32, w: f32, h: f32) {
    nvg__appendCommands(ctx,
        nvg__command(.NVG_MOVETO, x, y),
        nvg__command(.NVG_LINETO, x, y + h),
        nvg__command(.NVG_LINETO, x + w, y + h),
        nvg__command(.NVG_LINETO, x + w, y),
        nvg__command(.NVG_CLOSE)
    );
}

// Creates new rounded rectangle shaped sub-path.
nvgRoundedRect :: (ctx: *NVGcontext, x: f32, y: f32, w: f32, h: f32, r: f32) {
    nvgRoundedRectVarying(ctx, x, y, w, h, r, r, r, r);
}

// Creates new rounded rectangle shaped sub-path with varying radii for each corner.
nvgRoundedRectVarying :: (ctx: *NVGcontext, x: f32, y: f32, w: f32, h: f32, radTopLeft: f32, radTopRight: f32, radBottomRight: f32, radBottomLeft: f32) {
    if(radTopLeft < 0.1 && radTopRight < 0.1 && radBottomRight < 0.1 && radBottomLeft < 0.1) {
        nvgRect(ctx, x, y, w, h);
        return;
    }

    halfw := abs(w) * 0.5;
    halfh := abs(h) * 0.5;
    rxBL := min(radBottomLeft, halfw) * sign(w);
    ryBL := min(radBottomLeft, halfh) * sign(h);
    rxBR := min(radBottomRight, halfw) * sign(w);
    ryBR := min(radBottomRight, halfh) * sign(h);
    rxTR := min(radTopRight, halfw) * sign(w);
    ryTR := min(radTopRight, halfh) * sign(h);
    rxTL := min(radTopLeft, halfw) * sign(w);
    ryTL := min(radTopLeft, halfh) * sign(h);

    nvg__appendCommands(ctx,
        nvg__command(.NVG_MOVETO, x, y + ryTL),
        nvg__command(.NVG_LINETO, x, y + h - ryBL),
        nvg__command(.NVG_BEZIERTO, x, y + h - ryBL * (1 - NVG_KAPPA90), x + rxBL * (1 - NVG_KAPPA90), y + h, x + rxBL, y + h),
        nvg__command(.NVG_LINETO, x + w - rxBR, y + h),
        nvg__command(.NVG_BEZIERTO, x + w - rxBR * (1 - NVG_KAPPA90), y + h, x + w, y + h - ryBR * (1 - NVG_KAPPA90), x + w, y + h - ryBR),
        nvg__command(.NVG_LINETO, x + w, y + ryTR),
        nvg__command(.NVG_BEZIERTO, x + w, y + ryTR * (1 - NVG_KAPPA90), x + w - rxTR * (1 - NVG_KAPPA90), y, x + w - rxTR, y),
        nvg__command(.NVG_LINETO, x + rxTL, y),
        nvg__command(.NVG_BEZIERTO, x + rxTL * (1 - NVG_KAPPA90), y, x, y + ryTL * (1 - NVG_KAPPA90), x, y + ryTL),
        nvg__command(.NVG_CLOSE)
    );
}

// Creates new ellipse shaped sub-path.
nvgEllipse :: (ctx: *NVGcontext, cx: f32, cy: f32, rx: f32, ry: f32) {
    nvg__appendCommands(ctx,
        nvg__command(.NVG_MOVETO, cx - rx, cy),
        nvg__command(.NVG_BEZIERTO, cx - rx, cy + ry * NVG_KAPPA90, cx - rx * NVG_KAPPA90, cy + ry, cx, cy + ry),
        nvg__command(.NVG_BEZIERTO, cx + rx * NVG_KAPPA90, cy + ry, cx + rx, cy + ry * NVG_KAPPA90, cx + rx, cy),
        nvg__command(.NVG_BEZIERTO, cx + rx, cy - ry * NVG_KAPPA90, cx + rx * NVG_KAPPA90, cy - ry, cx, cy - ry),
        nvg__command(.NVG_BEZIERTO, cx - rx * NVG_KAPPA90, cy - ry, cx - rx, cy - ry * NVG_KAPPA90, cx - rx, cy),
        nvg__command(.NVG_CLOSE)
    );
}

// Creates new circle shaped sub-path.
nvgCircle :: (ctx: *NVGcontext, cx: f32, cy: f32, r: f32) {
    nvgEllipse(ctx, cx, cy, r, r);
}

// Fills the current path with current fill style.
nvgFill :: (ctx: *NVGcontext) {
    state := nvg__getState(ctx);

    nvg__flattenPaths(ctx);

    if (ctx.params.edgeAntiAlias && state.shapeAntiAlias) {
        nvg__expandFill(ctx, ctx.fringeWidth, .NVG_MITER, 2.4);
    } else {
        nvg__expandFill(ctx, 0.0, .NVG_MITER, 2.4);
    }

    // Apply global alpha
    fillPaint := state.fill;
    fillPaint.innerColor.a *= state.alpha;
    fillPaint.outerColor.a *= state.alpha;

    ctx.params.renderFill(ctx.params.userPtr, *fillPaint, state.compositeOperation, *state.scissor, ctx.fringeWidth,
                          ctx.cache.bounds, ctx.cache.paths.items, cast(s32) ctx.cache.paths.count);

    // Count triangles
    for * path : ctx.cache.paths {
        ctx.fillTriCount += path.nfill - 2;
        ctx.fillTriCount += path.nstroke - 2;
        ctx.drawCallCount += 2;
    }
}

nvgFillBatch :: (ctx: *NVGcontext) {
    state := nvg__getState(ctx);

    nvg__flattenPaths(ctx);

    if (ctx.params.edgeAntiAlias && state.shapeAntiAlias) {
        nvg__expandFill(ctx, ctx.fringeWidth, .NVG_MITER, 2.4);
    } else {
        nvg__expandFill(ctx, 0.0, .NVG_MITER, 2.4);
    }

    // Apply global alpha
    fillPaint := state.fill;
    fillPaint.innerColor.a *= state.alpha;
    fillPaint.outerColor.a *= state.alpha;

    ctx.params.renderFillBatch(ctx.params.userPtr, *fillPaint, state.compositeOperation, *state.scissor, ctx.fringeWidth,
                               ctx.cache.bounds, ctx.cache.paths.items, cast(s32) ctx.cache.paths.count);

    // Count triangles
    for * path : ctx.cache.paths {
        ctx.fillTriCount += path.nfill / 3;
        ctx.fillTriCount += path.nstroke / 3;
    }
    ctx.drawCallCount += 1;
}

// Fills the current path with current stroke style.
nvgStroke :: (ctx: *NVGcontext) {
    state := nvg__getState(ctx);

    strokePaint := state.stroke;

    scale := nvg__getAverageScale(state.xform);
    strokeWidth := clamp(state.strokeWidth * scale, 0.0, 200.0);
    if (strokeWidth < ctx.fringeWidth) {
        // If the stroke width is less than pixel size, use alpha to emulate coverage.
        // Since coverage is area, scale by alpha * alpha.
        alpha := clamp(strokeWidth / ctx.fringeWidth, 0.0, 1.0);
        strokePaint.innerColor.a *= alpha * alpha;
        strokePaint.outerColor.a *= alpha * alpha;
        strokeWidth = ctx.fringeWidth;
    }

    // Apply global alpha
    strokePaint.innerColor.a *= state.alpha;
    strokePaint.outerColor.a *= state.alpha;

    nvg__flattenPaths(ctx);

    if (ctx.params.edgeAntiAlias && state.shapeAntiAlias) {
        nvg__expandStroke(ctx, strokeWidth * 0.5, ctx.fringeWidth, state.lineCap, state.lineJoin, state.miterLimit);
    } else {
        nvg__expandStroke(ctx, strokeWidth * 0.5, 0.0, state.lineCap, state.lineJoin, state.miterLimit);
    }

    ctx.params.renderStroke(ctx.params.userPtr, *strokePaint, state.compositeOperation, *state.scissor, ctx.fringeWidth,
                            strokeWidth, ctx.cache.paths.items, cast(s32) ctx.cache.paths.count);

    // Count triangles
    for * path : ctx.cache.paths {
        ctx.strokeTriCount += path.nstroke - 2;
        ctx.drawCallCount += 1;
    }
}

//
// Text
//
// NanoVG allows you to load .ttf files and use the font to render text.
//
// The appearance of the text can be defined by setting the current text style
// and by specifying the fill color. Common text and font settings such as
// font size, letter spacing and text align are supported. Font blur allows you
// to create simple text effects such as drop shadows.
//
// At render time the font face can be set based on the font handles or name.
//
// Font measure functions return values in local space, the calculations are
// carried in the same resolution as the final rendering. This is done because
// the text glyph positions are snapped to the nearest pixels sharp rendering.
//
// The local space means that values are not rotated or scale as per the current
// transformation. For example if you set font size to 12, which would mean that
// line height is 16, then regardless of the current scaling and rotation, the
// returned line height is always 16. Some measures may vary because of the scaling
// since aforementioned pixel snapping.
//
// While this may sound a little odd, the setup allows you to always render the
// same way regardless of scaling. I.e. following works regardless of scaling:
//
//        txt: *u8 = "Text me up.";
//        nvgTextBounds(vg, x, y, txt, null, bounds);
//        nvgBeginPath(vg);
//        nvgRoundedRect(vg, bounds[0],bounds[1], bounds[2]-bounds[0], bounds[3]-bounds[1]);
//        nvgFill(vg);
//
// Note: currently only solid color fill is supported for text.

// Creates font by loading it from the disk from specified file name.
// Returns handle to the font.
nvgCreateFont :: (ctx: *NVGcontext, name: *u8, path: *u8) -> s32 {
    return fonsAddFont(ctx.fs, name, path, 0);
}

nvgCreateFontAtIndex :: (ctx: *NVGcontext, name: *u8, filename: *u8, fontIndex: s32) -> s32 {
	return fonsAddFont(ctx.fs, name, filename, fontIndex);
}

// Creates font by loading it from the specified memory chunk.
// Returns handle to the font.
nvgCreateFontMem :: (ctx: *NVGcontext, name: *u8, data: *u8, ndata: s32, freeData: bool) -> s32 {
    return fonsAddFontMem(ctx.fs, name, data, ndata, freeData, 0);
}

nvgCreateFontMemAtIndex :: (ctx: *NVGcontext, name: *u8, data: *u8, ndata: s32, freeData: bool, fontIndex: s32) -> s32 {
    return fonsAddFontMem(ctx.fs, name, data, ndata, freeData, 0);
}

// Finds a loaded font of specified name, and returns handle to it, or -1 if the font is not found.
nvgFindFont :: (ctx: *NVGcontext, name: *u8) -> s32 {
    if (name == null) {
        return -1;
    }
    return fonsGetFontByName(ctx.fs, name);
}

// Adds a fallback font by handle.
nvgAddFallbackFontId :: (ctx: *NVGcontext, baseFont: s32, fallbackFont: s32) -> bool {
    if (baseFont == -1 || fallbackFont == -1) {
        return false;
    }
    return fonsAddFallbackFont(ctx.fs, baseFont, fallbackFont);
}

// Adds a fallback font by name.
nvgAddFallbackFont :: (ctx: *NVGcontext, baseFont: *u8, fallbackFont: *u8) -> bool {
    return nvgAddFallbackFontId(ctx, nvgFindFont(ctx, baseFont), nvgFindFont(ctx, fallbackFont));
}

// Sets the font size of current text style.
nvgFontSize :: (ctx: *NVGcontext, size: f32) {
    state := nvg__getState(ctx);
    state.fontSize = size;
}

// Sets the blur of current text style.
nvgFontBlur :: (ctx: *NVGcontext, blur: f32) {
    state := nvg__getState(ctx);
    state.fontBlur = blur;
}

// Sets the letter spacing of current text style.
nvgTextLetterSpacing :: (ctx: *NVGcontext, spacing: f32) {
    state := nvg__getState(ctx);
    state.letterSpacing = spacing;
}

// Sets the proportional line height of current text style. The line height is specified as multiple of font size.
nvgTextLineHeight :: (ctx: *NVGcontext, lineHeight: f32) {
    state := nvg__getState(ctx);
    state.lineHeight = lineHeight;
}

// Sets the text align of current text style, see NVGalign for options.
nvgTextAlign :: (ctx: *NVGcontext, align: NVGalign) {
    state := nvg__getState(ctx);
    state.textAlign = align;
}

// Sets the font face based on specified id of current text style.
nvgFontFaceId :: (ctx: *NVGcontext, font: s32) {
    state := nvg__getState(ctx);
    state.fontId = font;
}

// Sets the font face based on specified name of current text style.
nvgFontFace :: (ctx: *NVGcontext, font: *u8) {
    state := nvg__getState(ctx);
    state.fontId = fonsGetFontByName(ctx.fs, font);
}

// Draws text string at specified location. If end is specified only the sub-string up to the end is drawn.
nvgText :: (ctx: *NVGcontext, x: f32, y: f32, str: *u8, end: *u8) -> f32 {
    state := nvg__getState(ctx);
    if (state.fontId == FONS_INVALID) {
        return x;
    }

    if (end == null) {
        end = str + strlen(str);
    }

    cverts := max(2, cast(s32)(end - str)) * 6; // conservative estimate.

    verts := *ctx.cache.verts;
    ensureCapacity(verts, cverts);
    clear(verts);

    scale := nvg__getFontScale(state) * ctx.devicePxRatio;
    invscale := 1.0 / scale;

    fonsSetSize(ctx.fs, state.fontSize * scale);
    fonsSetSpacing(ctx.fs, state.letterSpacing * scale);
    fonsSetBlur(ctx.fs, state.fontBlur * scale);
    fonsSetAlign(ctx.fs, nvg__nvgAlignToFONSAlign(state.textAlign));
    fonsSetFont(ctx.fs, state.fontId);

    q: FONSquad;

    isFlipped := nvg__isTransformFlipped(state.xform);

    iter: FONStextIter;
    fonsTextIterInit(ctx.fs, *iter, x * scale, y * scale, str, end, .FONS_GLYPH_BITMAP_REQUIRED);
    prevIter := iter;

    while (fonsTextIterNext(ctx.fs, *iter, *q)) {
        if (iter.prevGlyphIndex == -1) { // can not retrieve glyph?
            if (verts.count != 0) {
                nvg__renderText(ctx, verts.items, cast(s32) verts.count);
                clear(verts);
            }
            if (!nvg__allocTextAtlas(ctx)) {
                break; // no memory :(
            }
            iter = prevIter;
            fonsTextIterNext(ctx.fs, *iter, *q); // try again
            if (iter.prevGlyphIndex == -1) { // still can not find glyph?
                break;
            }
        }

        prevIter = iter;

        if (isFlipped) {
            tmp: f32;

            tmp = q.y0;
            q.y0 = q.y1;
            q.y1 = tmp;

            tmp = q.t0;
            q.t0 = q.t1;
            q.t1 = tmp;
        }

        c: [4 * 2] f32;

        // Transform corners.
        c[0], c[1] = nvgTransformPoint(state.xform, q.x0 * invscale, q.y0 * invscale);
        c[2], c[3] = nvgTransformPoint(state.xform, q.x1 * invscale, q.y0 * invscale);
        c[4], c[5] = nvgTransformPoint(state.xform, q.x1 * invscale, q.y1 * invscale);
        c[6], c[7] = nvgTransformPoint(state.xform, q.x0 * invscale, q.y1 * invscale);

        // Create triangles
        if (verts.count + 6 <= cverts) {
            add(verts, nvg__vtx(c[0], c[1], q.s0, q.t0));
            add(verts, nvg__vtx(c[4], c[5], q.s1, q.t1));
            add(verts, nvg__vtx(c[2], c[3], q.s1, q.t0));
            add(verts, nvg__vtx(c[0], c[1], q.s0, q.t0));
            add(verts, nvg__vtx(c[6], c[7], q.s0, q.t1));
            add(verts, nvg__vtx(c[4], c[5], q.s1, q.t1));
        }
    }

    // TODO: add back-end bit to do this just once per frame.
    nvg__flushTextTexture(ctx);

    nvg__renderText(ctx, verts.items, cast(s32) verts.count);

    return iter.nextx / scale;
}

// Draws multi-line text string at specified location wrapped at the specified width. If end is specified only the sub-string up to the end is drawn.
// White space is stripped at the beginning of the rows, the text is split at word boundaries or when new-line characters are encountered.
// Words longer than the max width are slit at nearest character (i.e. no hyphenation).
nvgTextBox :: (ctx: *NVGcontext, x: f32, y: f32, breakRowWidth: f32, str: *u8, end: *u8) {
    state := nvg__getState(ctx);
    if (state.fontId == FONS_INVALID) {
        return;
    }

    oldAlign := state.textAlign;
    haling := state.textAlign & (NVGalign.NVG_ALIGN_LEFT | .NVG_ALIGN_CENTER | .NVG_ALIGN_RIGHT);
    valign := state.textAlign & (NVGalign.NVG_ALIGN_TOP | .NVG_ALIGN_MIDDLE | .NVG_ALIGN_BOTTOM | .NVG_ALIGN_BASELINE);

    lineh: f32 = 0;
    nvgTextMetrics(ctx, null, null, *lineh);

    state.textAlign = .NVG_ALIGN_LEFT | valign;

    rows: [2] NVGtextRow;
    nrows := nvgTextBreakLines(ctx, str, end, breakRowWidth, rows, 2);
    while (nrows > 0) {
        for i : 0..nrows-1 {
            row := *rows[i];
            if (haling & .NVG_ALIGN_LEFT) {
                nvgText(ctx, x, y, row.start, row.end);
            } else if (haling & .NVG_ALIGN_CENTER) {
                nvgText(ctx, x + breakRowWidth * 0.5 - row.width * 0.5, y, row.start, row.end);
            } else if (haling & .NVG_ALIGN_RIGHT) {
                nvgText(ctx, x + breakRowWidth - row.width, y, row.start, row.end);
            }
            y += lineh * state.lineHeight;
        }
        str = rows[nrows - 1].next;
        nrows = nvgTextBreakLines(ctx, str, end, breakRowWidth, rows, 2);
    }

    state.textAlign = oldAlign;
}

// Measures the specified text string. Parameter bounds should be a pointer to float[4],
// if the bounding box of the text should be returned. The bounds value are [xmin,ymin, xmax,ymax]
// Returns the horizontal advance of the measured text (i.e. where the next character should drawn).
// Measured values are returned in local coordinate space.
nvgTextBounds :: (ctx: *NVGcontext, x: f32, y: f32, str: *u8, end: *u8, bounds: *f32) -> f32 {
    state := nvg__getState(ctx);
    if (state.fontId == FONS_INVALID) {
        return 0;
    }

    scale := nvg__getFontScale(state) * ctx.devicePxRatio;
    invscale := 1.0 / scale;

    fonsSetSize(ctx.fs, state.fontSize * scale);
    fonsSetSpacing(ctx.fs, state.letterSpacing * scale);
    fonsSetBlur(ctx.fs, state.fontBlur * scale);
    fonsSetAlign(ctx.fs, nvg__nvgAlignToFONSAlign(state.textAlign));
    fonsSetFont(ctx.fs, state.fontId);

    width := fonsTextBounds(ctx.fs, x * scale, y * scale, str, end, bounds);
    if (bounds != null) {
        // Use line bounds for height.
        fonsLineBounds(ctx.fs, y * scale, *bounds[1], *bounds[3]);
        bounds[0] *= invscale;
        bounds[1] *= invscale;
        bounds[2] *= invscale;
        bounds[3] *= invscale;
    }
    return width * invscale;
}

// Measures the specified multi-text string. Parameter bounds should be a pointer to float[4],
// if the bounding box of the text should be returned. The bounds value are [xmin,ymin, xmax,ymax]
// Measured values are returned in local coordinate space.
nvgTextBoxBounds :: (ctx: *NVGcontext, x: f32, y: f32, breakRowWidth: f32, str: *u8, end: *u8, bounds: *f32) {
    state := nvg__getState(ctx);
    if (state.fontId == FONS_INVALID) {
        if (bounds != null) {
            bounds[0] = 0.0;
            bounds[1] = 0.0;
            bounds[2] = 0.0;
            bounds[3] = 0.0;
        }
        return;
    }

    scale := nvg__getFontScale(state) * ctx.devicePxRatio;
    invscale := 1.0 / scale;

    oldAlign := state.textAlign;
    haling := state.textAlign & (NVGalign.NVG_ALIGN_LEFT | .NVG_ALIGN_CENTER | .NVG_ALIGN_RIGHT);
    valign := state.textAlign & (NVGalign.NVG_ALIGN_TOP | .NVG_ALIGN_MIDDLE | .NVG_ALIGN_BOTTOM | .NVG_ALIGN_BASELINE);

    state.textAlign = .NVG_ALIGN_LEFT | valign;

    lineh: f32;
    nvgTextMetrics(ctx, null, null, *lineh);

    minx := x;
    maxx := x;
    miny := y;
    maxy := y;

    rminy, rmaxy: f32 = 0;
    fonsSetSize(ctx.fs, state.fontSize * scale);
    fonsSetSpacing(ctx.fs, state.letterSpacing * scale);
    fonsSetBlur(ctx.fs, state.fontBlur * scale);
    fonsSetAlign(ctx.fs, nvg__nvgAlignToFONSAlign(state.textAlign));
    fonsSetFont(ctx.fs, state.fontId);
    fonsLineBounds(ctx.fs, 0, *rminy, *rmaxy);

    rminy *= invscale;
    rmaxy *= invscale;

    rows: [2] NVGtextRow;
    nrows := nvgTextBreakLines(ctx, str, end, breakRowWidth, rows, 2);
    while (nrows > 0) {
        for i : 0..nrows-1 {
            row := *rows[i];

            dx: f32 = 0;
            // Horizontal bounds
            if (haling & .NVG_ALIGN_LEFT) {
                dx = 0;
            } else if (haling & .NVG_ALIGN_CENTER) {
                dx = breakRowWidth * 0.5 - row.width * 0.5;
            } else if (haling & .NVG_ALIGN_RIGHT) {
                dx = breakRowWidth - row.width;
            }

            rminx := x + row.minx + dx;
            rmaxx := x + row.maxx + dx;
            minx = min(minx, rminx);
            maxx = max(maxx, rmaxx);

            // Vertical bounds.
            miny = min(miny, y + rminy);
            maxy = max(maxy, y + rmaxy);

            y += lineh * state.lineHeight;
        }
        str = rows[nrows - 1].next;
        nrows = nvgTextBreakLines(ctx, str, end, breakRowWidth, rows, 2);
    }

    state.textAlign = oldAlign;

    if (bounds != null) {
        bounds[0] = minx;
        bounds[1] = miny;
        bounds[2] = maxx;
        bounds[3] = maxy;
    }
}

// Calculates the glyph x positions of the specified text. If end is specified only the sub-string will be used.
// Measured values are returned in local coordinate space.
nvgTextGlyphPositions :: (ctx: *NVGcontext, x: f32, y: f32, str: *u8, end: *u8, positions: *NVGglyphPosition, maxPositions: s32) -> s32 {
    state := nvg__getState(ctx);
    if (state.fontId == FONS_INVALID) {
        return 0;
    }

    scale := nvg__getFontScale(state) * ctx.devicePxRatio;
    invscale := 1.0 / scale;

    if (end == null) {
        end = str + strlen(str);
    }

    if (str == end) {
        return 0;
    }

    fonsSetSize(ctx.fs, state.fontSize * scale);
    fonsSetSpacing(ctx.fs, state.letterSpacing * scale);
    fonsSetBlur(ctx.fs, state.fontBlur * scale);
    fonsSetAlign(ctx.fs, nvg__nvgAlignToFONSAlign(state.textAlign));
    fonsSetFont(ctx.fs, state.fontId);

    q: FONSquad;
    npos: s32 = 0;

    iter: FONStextIter;
    fonsTextIterInit(ctx.fs, *iter, x * scale, y * scale, str, end, .FONS_GLYPH_BITMAP_OPTIONAL);
    prevIter := iter;

    while (fonsTextIterNext(ctx.fs, *iter, *q)) {
        if (iter.prevGlyphIndex < 0 && nvg__allocTextAtlas(ctx)) { // can not retrieve glyph?
            iter = prevIter;
            fonsTextIterNext(ctx.fs, *iter, *q); // try again
        }
        prevIter = iter;
        positions[npos].str = iter.str;
        positions[npos].x = iter.x * invscale;
        positions[npos].minx = min(iter.x, q.x0) * invscale;
        positions[npos].maxx = max(iter.nextx, q.x1) * invscale;
        npos += 1;
        if (npos >= maxPositions) {
            break;
        }
    }

    return npos;
}

// Returns the vertical metrics based on the current text style.
// Measured values are returned in local coordinate space.
nvgTextMetrics :: (ctx: *NVGcontext, ascender: *f32, descender: *f32, lineh: *f32) {
    state := nvg__getState(ctx);
    if (state.fontId == FONS_INVALID) {
        return;
    }

    scale := nvg__getFontScale(state) * ctx.devicePxRatio;
    invscale := 1.0 / scale;

    fonsSetSize(ctx.fs, state.fontSize * scale);
    fonsSetSpacing(ctx.fs, state.letterSpacing * scale);
    fonsSetBlur(ctx.fs, state.fontBlur * scale);
    fonsSetAlign(ctx.fs, nvg__nvgAlignToFONSAlign(state.textAlign));
    fonsSetFont(ctx.fs, state.fontId);

    fonsVertMetrics(ctx.fs, ascender, descender, lineh);
    if (ascender != null) {
        <<ascender *= invscale;
    }
    if (descender != null) {
        <<descender *= invscale;
    }
    if (lineh != null) {
        <<lineh *= invscale;
    }
}

// Breaks the specified text into lines. If end is specified only the sub-string will be used.
// White space is stripped at the beginning of the rows, the text is split at word boundaries or when new-line characters are encountered.
// Words longer than the max width are slit at nearest character (i.e. no hyphenation).
nvgTextBreakLines :: (ctx: *NVGcontext, str: *u8, end: *u8, breakRowWidth: f32, rows: [] NVGtextRow, maxRows: s32) -> s32 {
    state := nvg__getState(ctx);
    if (state.fontId == FONS_INVALID) {
        return 0;
    }

    if (maxRows == 0) {
        return 0;
    }

    if (end == null) {
        end = str + strlen(str);
    }

    if (str == end) {
        return 0;
    }

    scale := nvg__getFontScale(state) * ctx.devicePxRatio;
    invscale := 1.0 / scale;

    fonsSetSize(ctx.fs, state.fontSize * scale);
    fonsSetSpacing(ctx.fs, state.letterSpacing * scale);
    fonsSetBlur(ctx.fs, state.fontBlur * scale);
    fonsSetAlign(ctx.fs, nvg__nvgAlignToFONSAlign(state.textAlign));
    fonsSetFont(ctx.fs, state.fontId);

    breakRowWidth *= scale;

    rowStartX, rowWidth: f32 = 0;
    rowMinX, rowMaxX: f32 = 0;
    wordStartX, wordMinX: f32 = 0;
    breakWidth, breakMaxX: f32 = 0;

    rowStart: *u8;
    rowEnd: *u8;
    wordStart: *u8;
    breakEnd: *u8;

    type := NVGcodepointType.NVG_SPACE;
    ptype := NVGcodepointType.NVG_SPACE;

    pcodepoint: u32 = 0;

    q: FONSquad;
    nrows: s32 = 0;

    iter: FONStextIter;
    fonsTextIterInit(ctx.fs, *iter, 0, 0, str, end, .FONS_GLYPH_BITMAP_OPTIONAL);
    prevIter := iter;

    while (fonsTextIterNext(ctx.fs, *iter, *q)) {
        if (iter.prevGlyphIndex < 0 && nvg__allocTextAtlas(ctx)) { // can not retrieve glyph?
            iter = prevIter;
            fonsTextIterNext(ctx.fs, *iter, *q); // try again
        }
        prevIter = iter;
        if iter.codepoint == {
            case 9; #through;       // \t
            case 11; #through;      // \v
            case 12; #through;      // \f
            case 32; #through;      // space
            case 0x00a0;            // NBSP
                type = .NVG_SPACE;
            case 10;                // \n
                type = ifx pcodepoint == 13 then NVGcodepointType.NVG_SPACE else NVGcodepointType.NVG_NEWLINE;
            case 13;                // \r
                type = ifx pcodepoint == 10 then NVGcodepointType.NVG_SPACE else NVGcodepointType.NVG_NEWLINE;
            case 0x0085;            // NEL
                type = .NVG_NEWLINE;
            case;
                if ((iter.codepoint >= 0x4E00 && iter.codepoint <= 0x9FFF) ||
                    (iter.codepoint >= 0x3000 && iter.codepoint <= 0x30FF) ||
                    (iter.codepoint >= 0xFF00 && iter.codepoint <= 0xFFEF) ||
                    (iter.codepoint >= 0x1100 && iter.codepoint <= 0x11FF) ||
                    (iter.codepoint >= 0x3130 && iter.codepoint <= 0x318F) ||
                    (iter.codepoint >= 0xAC00 && iter.codepoint <= 0xD7AF))
                {
                    type = .NVG_CJK_CHAR;
                } else {
                    type = .NVG_CHAR;
                }
        }

        if (type == .NVG_NEWLINE) {
            // Always handle new lines.
            rows[nrows].start = ifx rowStart != null then rowStart else iter.str;
            rows[nrows].end = ifx rowEnd != null then rowEnd else iter.str;
            rows[nrows].width = rowWidth * invscale;
            rows[nrows].minx = rowMinX * invscale;
            rows[nrows].maxx = rowMaxX * invscale;
            rows[nrows].next = iter.next;
            nrows += 1;
            if (nrows >= maxRows) {
                return nrows;
            }
            // Set null break point
            breakEnd = rowStart;
            breakWidth = 0.0;
            breakMaxX = 0.0;
            // Indicate to skip the white space at the beginning of the row.
            rowStart = null;
            rowEnd = null;
            rowWidth = 0;
            rowMinX = 0;
            rowMaxX = 0;
        } else {
            if (rowStart == null) {
                // Skip white space until the beginning of the line
                if (type == .NVG_CHAR || type == .NVG_CJK_CHAR) {
                    // The current char is the row so far
                    rowStartX = iter.x;
                    rowStart = iter.str;
                    rowEnd = iter.next;
                    rowWidth = iter.nextx - rowStartX; // q.x1 - rowStartX;
                    rowMinX = q.x0 - rowStartX;
                    rowMaxX = q.x1 - rowStartX;
                    wordStart = iter.str;
                    wordStartX = iter.x;
                    wordMinX = q.x0 - rowStartX;
                    // Set null break point
                    breakEnd = rowStart;
                    breakWidth = 0.0;
                    breakMaxX = 0.0;
                }
            } else {
                nextWidth := iter.nextx - rowStartX;

                // track last non-white space character
                if (type == .NVG_CHAR || type == .NVG_CJK_CHAR) {
                    rowEnd = iter.next;
                    rowWidth = iter.nextx - rowStartX;
                    rowMaxX = q.x1 - rowStartX;
                }
                // track last end of a word
                if (((ptype == .NVG_CHAR || ptype == .NVG_CJK_CHAR) && type == .NVG_SPACE) || type == .NVG_CJK_CHAR) {
                    breakEnd = iter.str;
                    breakWidth = rowWidth;
                    breakMaxX = rowMaxX;
                }
                // track last beginning of a word
                if ((ptype == .NVG_SPACE && (type == .NVG_CHAR || type == .NVG_CJK_CHAR)) || type == .NVG_CJK_CHAR) {
                    wordStart = iter.str;
                    wordStartX = iter.x;
                    wordMinX = q.x0;
                }

                // Break to new line when a character is beyond break width.
                if ((type == .NVG_CHAR || type == .NVG_CJK_CHAR) && nextWidth > breakRowWidth) {
                    // The run length is too long, need to break to new line.
                    if (breakEnd == rowStart) {
                        // The current word is longer than the row length, just break it from here.
                        rows[nrows].start = rowStart;
                        rows[nrows].end = iter.str;
                        rows[nrows].width = rowWidth * invscale;
                        rows[nrows].minx = rowMinX * invscale;
                        rows[nrows].maxx = rowMaxX * invscale;
                        rows[nrows].next = iter.str;
                        nrows += 1;
                        if (nrows >= maxRows) {
                            return nrows;
                        }
                        rowStartX = iter.x;
                        rowStart = iter.str;
                        rowEnd = iter.next;
                        rowWidth = iter.nextx - rowStartX;
                        rowMinX = q.x0 - rowStartX;
                        rowMaxX = q.x1 - rowStartX;
                        wordStart = iter.str;
                        wordStartX = iter.x;
                        wordMinX = q.x0 - rowStartX;
                    } else {
                        // Break the line from the end of the last word, and start new line from the beginning of the new.
                        rows[nrows].start = rowStart;
                        rows[nrows].end = breakEnd;
                        rows[nrows].width = breakWidth * invscale;
                        rows[nrows].minx = rowMinX * invscale;
                        rows[nrows].maxx = breakMaxX * invscale;
                        rows[nrows].next = wordStart;
                        nrows += 1;
                        if (nrows >= maxRows) {
                            return nrows;
                        }
                        rowStartX = wordStartX;
                        rowStart = wordStart;
                        rowEnd = iter.next;
                        rowWidth = iter.nextx - rowStartX;
                        rowMinX = wordMinX - rowStartX;
                        rowMaxX = q.x1 - rowStartX;
                        // No change to the word start
                    }
                    // Set null break point
                    breakEnd = rowStart;
                    breakWidth = 0.0;
                    breakMaxX = 0.0;
                }
            }
        }

        pcodepoint = iter.codepoint;
        ptype = type;
    }

    // Break the line from the end of the last word, and start new line from the beginning of the new.
    if (rowStart != null) {
        rows[nrows].start = rowStart;
        rows[nrows].end = rowEnd;
        rows[nrows].width = rowWidth * invscale;
        rows[nrows].minx = rowMinX * invscale;
        rows[nrows].maxx = rowMaxX * invscale;
        rows[nrows].next = end;
        nrows += 1;
    }

    return nrows;
}

//
// Internal Render API
//
NVGtexture :: enum s32 {
    NVG_TEXTURE_ALPHA :: 1;
    NVG_TEXTURE_RGBA :: 2;
}

NVGscissor :: struct {
    xform: [6] f32;
    extent: [2] f32;
}

NVGvertex :: struct {
    x,y,u,v : f32;
}

NVGpath :: struct {
    first: s32;
    count: s32;
    closed: bool;
    nbevel: s32;
    fill: *NVGvertex;
    nfill: s32;
    stroke: *NVGvertex;
    nstroke: s32;
    winding: NVGwinding;
    convex: bool;
}

NVGparams :: struct {
    userPtr: *void;
    edgeAntiAlias: bool;
    renderCreate: (uptr: *void) -> bool;
    renderCreateTexture: (uptr: *void, type: NVGtexture, w: s32, h: s32, imageFlags: NVGimageFlags, data: *u8) -> s32;
    renderDeleteTexture: (uptr: *void, image: s32) -> bool;
    renderUpdateTexture: (uptr: *void, image: s32, x: s32, y: s32, w: s32, h: s32, data: *u8) -> bool;
    renderGetTextureSize: (uptr: *void, image: s32, w: *s32, h: *s32) -> bool;
    renderViewport: (uptr: *void, width: f32, height: f32, devicePixelRatio: f32);
    renderCancel: (uptr: *void);
    renderFlush: (uptr: *void);
    renderFill: (uptr: *void, paint: *NVGpaint, compositeOperation: NVGcompositeOperationState, scissor: *NVGscissor, fringe: f32, bounds: [] f32, paths: *NVGpath, npaths: s32);
    renderFillBatch: (uptr: *void, paint: *NVGpaint, compositeOperation: NVGcompositeOperationState, scissor: *NVGscissor, fringe: f32, bounds: [] f32, paths: *NVGpath, npaths: s32);
    renderStroke: (uptr: *void, paint: *NVGpaint, compositeOperation: NVGcompositeOperationState, scissor: *NVGscissor, fringe: f32, strokeWidth: f32, paths: *NVGpath, npaths: s32);
    renderTriangles: (uptr: *void, paint: *NVGpaint, compositeOperation: NVGcompositeOperationState, scissor: *NVGscissor, verts: *NVGvertex, nverts: s32);
    renderDelete: (uptr: *void);
}

// Constructor and destructor, called by the render back-end.
nvgCreateInternal :: (params: *NVGparams) -> *NVGcontext {
    ctx := alloc(NVGcontext);
    if (ctx == null) {
        nvgDeleteInternal(ctx);
        return null;
    }

    ctx.params = <<params;

    for i : 0..NVG_MAX_FONTIMAGES-1 {
        ctx.fontImages[i] = 0;
    }

    ctx.commands = createList(NVGcommand, ListOptions(NVGcommand).{
        capacity = NVG_INIT_COMMANDS_SIZE
    });
    if (ctx.commands.items == null) {
        nvgDeleteInternal(ctx);
        return null;
    }

    ctx.cache = nvg__allocPathCache();
    if (ctx.cache == null) {
        nvgDeleteInternal(ctx);
        return null;
    }

    nvgSave(ctx);
    nvgReset(ctx);

    nvg__setDevicePixelRatio(ctx, 1.0);

    if (!ctx.params.renderCreate(ctx.params.userPtr)) {
        nvgDeleteInternal(ctx);
        return null;
    }

    // Init font rendering
    fontParams: FONSparams;
    fontParams.width = NVG_INIT_FONTIMAGE_SIZE;
    fontParams.height = NVG_INIT_FONTIMAGE_SIZE;
    fontParams.flags = .FONS_ZERO_TOPLEFT;
    fontParams.renderCreate = null;
    fontParams.renderUpdate = null;
    fontParams.renderDraw = null;
    fontParams.renderDelete = null;
    fontParams.userPtr = null;
    ctx.fs = fonsCreateInternal(*fontParams);
    if (ctx.fs == null) {
        nvgDeleteInternal(ctx);
        return null;
    }

    // Create font texture
    ctx.fontImages[0] = ctx.params.renderCreateTexture(ctx.params.userPtr, .NVG_TEXTURE_ALPHA, fontParams.width, fontParams.height, 0, null);
    if (ctx.fontImages[0] == 0) {
        nvgDeleteInternal(ctx);
        return null;
    }
    ctx.fontImageIdx = 0;

    return ctx;
}

nvgDeleteInternal :: (ctx: *NVGcontext) {
    if (ctx == null) {
        return;
    }
    uninit(*ctx.commands);
    if (ctx.cache != null) {
        nvg__deletePathCache(ctx.cache);
    }
    if (ctx.fs != null) {
        fonsDeleteInternal(ctx.fs);
    }

    for i : 0..NVG_MAX_FONTIMAGES-1 {
        if (ctx.fontImages[i] != 0) {
            nvgDeleteImage(ctx, ctx.fontImages[i]);
            ctx.fontImages[i] = 0;
        }
    }

    if (ctx.params.renderDelete != null) {
        ctx.params.renderDelete(ctx.params.userPtr);
    }

    free(ctx);
}

nvgInternalParams :: (ctx: *NVGcontext) -> *NVGparams {
    return *ctx.params;
}

// Debug function to dump cached path data.
nvgDebugDumpPathCache :: (ctx: *NVGcontext) {}

nvgGetState :: inline (ctx: *NVGcontext) -> *NVGstate {
    return nvg__getState(ctx);
}

#scope_file

#import "utils";
#import "fontstash";
#import "stb_image";

nvg__setDevicePixelRatio :: (ctx: *NVGcontext, ratio: f32) {
    ctx.tessTol = 0.25 / ratio;
    ctx.distTol = 0.01 / ratio;
    ctx.fringeWidth = 1.0 / ratio;
    ctx.devicePxRatio = ratio;
}

nvg__compositeOperationState :: (op: NVGcompositeOperation) -> NVGcompositeOperationState {
    sfactor, dfactor: NVGblendFactor;

    if op == {
        case .NVG_SOURCE_OVER;
            sfactor = .NVG_ONE;
            dfactor = .NVG_ONE_MINUS_SRC_ALPHA;
        case .NVG_SOURCE_IN;
            sfactor = .NVG_DST_ALPHA;
            dfactor = .NVG_ZERO;
        case .NVG_SOURCE_OUT;
            sfactor = .NVG_ONE_MINUS_DST_ALPHA;
            dfactor = .NVG_ZERO;
        case .NVG_ATOP;
            sfactor = .NVG_DST_ALPHA;
            dfactor = .NVG_ONE_MINUS_SRC_ALPHA;
        case .NVG_DESTINATION_OVER;
            sfactor = .NVG_ONE_MINUS_DST_ALPHA;
            dfactor = .NVG_ONE;
        case .NVG_DESTINATION_IN;
            sfactor = .NVG_ZERO;
            dfactor = .NVG_SRC_ALPHA;
        case .NVG_DESTINATION_OUT;
            sfactor = .NVG_ZERO;
            dfactor = .NVG_ONE_MINUS_SRC_ALPHA;
        case .NVG_DESTINATION_ATOP;
            sfactor = .NVG_ONE_MINUS_DST_ALPHA;
            dfactor = .NVG_SRC_ALPHA;
        case .NVG_LIGHTER;
            sfactor = .NVG_ONE;
            dfactor = .NVG_ONE;
        case .NVG_COPY;
            sfactor = .NVG_ONE;
            dfactor = .NVG_ZERO;
        case .NVG_XOR;
            sfactor = .NVG_ONE_MINUS_DST_ALPHA;
            dfactor = .NVG_ONE_MINUS_SRC_ALPHA;
        case;
            sfactor = .NVG_ONE;
            dfactor = .NVG_ZERO;
    }

    state: NVGcompositeOperationState = ---;
    state.srcRGB = sfactor;
    state.dstRGB = dfactor;
    state.srcAlpha = sfactor;
    state.dstAlpha = dfactor;
    return state;
}

nvg__getState :: (ctx: *NVGcontext) -> *NVGstate {
    return *ctx.states[ctx.nstates - 1];
}

nvg__hue :: (h: f32, m1: f32, m2: f32) -> f32 {
    if (h < 0) {
        h += 1;
    }
    if (h > 1) {
        h -= 1;
    }
    if (h < 1.0 / 6.0) {
        return m1 + (m2 - m1) * h * 6.0;
    }
    if (h < 3.0 / 6.0) {
        return m2;
    }
    if (h < 4.0 / 6.0) {
        return m1 + (m2 - m1) * (2.0 / 3.0 - h) * 6.0;
    }
    return m1;
}

nvg__setPaintColor :: (p: *NVGpaint, color: NVGcolor) {
    memoryClear(p);
    nvgTransformIdentity(p.xform);
    p.radius = 0.0;
    p.feather = 1.0;
    p.innerColor = color;
    p.outerColor = color;
}

nvg__isectRects :: (
    dst: [] f32,
    ax: f32, ay: f32, aw: f32, ah: f32,
    bx: f32, by: f32, bw: f32, bh: f32)
{
    minx := max(ax, bx);
    miny := max(ay, by);
    maxx := min(ax + aw, bx + bw);
    maxy := min(ay + ah, by + bh);
    dst[0] = minx;
    dst[1] = miny;
    dst[2] = max(0.0, maxx - minx);
    dst[3] = max(0.0, maxy - miny);
}

nvg__ptEquals :: (x1: f32, y1: f32, x2: f32, y2: f32, tol: f32) -> bool {
    dx := x2 - x1;
    dy := y2 - y1;
    return dx * dx + dy * dy < tol * tol;
}

nvg__distPtSeg :: (x: f32, y: f32, px: f32, py: f32, qx: f32, qy: f32) -> f32 {
    pqx := qx - px;
    pqy := qy - py;
    dx := x - px;
    dy := y - py;
    d := pqx * pqx + pqy * pqy;
    t := pqx * dx + pqy * dy;
    if (d > 0) {
        t /= d;
    }
    if (t < 0) {
        t = 0;
    } else if (t > 1) {
        t = 1;
    }
    dx = px + t * pqx - x;
    dy = py + t * pqy - y;
    return dx * dx + dy * dy;
}

nvg__appendCommands :: (ctx: *NVGcontext, cmds: ..NVGcommand) {
    state := nvg__getState(ctx);

    firstCmd := cmds[0];
    if (firstCmd.type != .NVG_CLOSE &&
        firstCmd.type != .NVG_WINDING)
    {
        lastCmd := cmds[cmds.count - 1];
        argCount := nvg__argCount(lastCmd.type);
        if (argCount > 1) {
            ctx.commandx = lastCmd.args[argCount - 2];
            ctx.commandy = lastCmd.args[argCount - 1];
        }
    }

    // transform commands
    for *cmd : cmds {
        if cmd.type == {
            case .NVG_MOVETO;
                cmd.args[0], cmd.args[1] = nvgTransformPoint(state.xform, cmd.args[0], cmd.args[1]);
            case .NVG_LINETO;
                cmd.args[0], cmd.args[1] = nvgTransformPoint(state.xform, cmd.args[0], cmd.args[1]);
            case .NVG_BEZIERTO;
                cmd.args[0], cmd.args[1] = nvgTransformPoint(state.xform, cmd.args[0], cmd.args[1]);
                cmd.args[2], cmd.args[3] = nvgTransformPoint(state.xform, cmd.args[2], cmd.args[3]);
                cmd.args[4], cmd.args[5] = nvgTransformPoint(state.xform, cmd.args[4], cmd.args[5]);
        }
    }

    addRange(*ctx.commands, ..cmds);
}

nvg__clearPathCache :: (ctx: *NVGcontext) {
    clear(*ctx.cache.points);
    clear(*ctx.cache.paths);
    clear(*ctx.cache.verts);
}

nvg__lastPath :: (ctx: *NVGcontext) -> *NVGpath {
    if (ctx.cache.paths.count == 0) {
        return null;
    }
    return ref(*ctx.cache.paths, ctx.cache.paths.count - 1);
}

nvg__addPath :: (ctx: *NVGcontext) {
    path: NVGpath;
    path.first = cast(s32) ctx.cache.points.count;
    path.winding = .NVG_CCW;

    add(*ctx.cache.paths, path);
}

nvg__lastPoint :: (ctx: *NVGcontext) -> *NVGpoint {
    if (ctx.cache.points.count == 0) {
        return null;
    }
    return ref(*ctx.cache.points, ctx.cache.points.count - 1);
}

nvg__addPoint :: (ctx: *NVGcontext, x: f32, y: f32, flags: NVGpointFlags) {
    path := nvg__lastPath(ctx);
    if (path == null) {
        return;
    }

    if (path != null && ctx.cache.points.count > 0) {
        pt := nvg__lastPoint(ctx);
        if (nvg__ptEquals(pt.x,pt.y, x,y, ctx.distTol)) {
            pt.flags |= flags;
            return;
        }
    }

    pt: NVGpoint;
    pt.x = x;
    pt.y = y;
    pt.flags = flags;
    add(*ctx.cache.points, pt);

    path.count += 1;
}

nvg__closePath :: (ctx: *NVGcontext) {
    path := nvg__lastPath(ctx);
    if (path == null) {
        return;
    }
    path.closed = true;
}

nvg__pathWinding :: (ctx: *NVGcontext, winding: NVGwinding) {
    path := nvg__lastPath(ctx);
    if (path == null) {
        return;
    }
    path.winding = winding;
}

nvg__getAverageScale :: (t: [] f32) -> f32 {
    sx := sqrtf(t[0] * t[0] + t[2] * t[2]);
    sy := sqrtf(t[1] * t[1] + t[3] * t[3]);
    return (sx + sy) * 0.5;
}

nvg__triarea2 :: (ax: f32, ay: f32, bx: f32, by: f32, cx: f32, cy: f32) -> f32 {
    abx := bx - ax;
    aby := by - ay;
    acx := cx - ax;
    acy := cy - ay;
    return acx * aby - abx * acy;
}

nvg__polyArea :: (pts: *NVGpoint, npts: s32) -> f32 {
    area: f32 = 0.0;
    a := pts[0];
    for i : 2..npts-1 {
        b := pts[i - 1];
        c := pts[i];
        area += nvg__triarea2(a.x,a.y, b.x,b.y, c.x,c.y);
    }
    return area * 0.5;
}

nvg__polyReverse :: (pts: *NVGpoint, npts: s32) {
    i: s32 = 0;
    j: s32 = npts-1;
    while (i < j) {
        tmp := pts[i];
        pts[i] = pts[j];
        pts[j] = tmp;
        i += 1;
        j -= 1;
    }
}

nvg__vtx :: (x: f32, y: f32, u: f32, v: f32) -> NVGvertex {
    vtx: NVGvertex = ---;
    vtx.x = x;
    vtx.y = y;
    vtx.u = u;
    vtx.v = v;
    return vtx;
}

nvg__tesselateBezier :: (
    ctx: *NVGcontext,
    x1: f32, y1: f32, x2: f32, y2: f32,
    x3: f32, y3: f32, x4: f32, y4: f32,
    level: s32, type: NVGpointFlags)
{
    if (level > 10) {
        return;
    }

    x12 := (x1 + x2) * 0.5;
    y12 := (y1 + y2) * 0.5;
    x23 := (x2 + x3) * 0.5;
    y23 := (y2 + y3) * 0.5;
    x34 := (x3 + x4) * 0.5;
    y34 := (y3 + y4) * 0.5;
    x123 := (x12 + x23) * 0.5;
    y123 := (y12 + y23) * 0.5;

    dx := x4 - x1;
    dy := y4 - y1;
    d2 := abs(((x2 - x4) * dy - (y2 - y4) * dx));
    d3 := abs(((x3 - x4) * dy - (y3 - y4) * dx));

    if ((d2 + d3) * (d2 + d3) < ctx.tessTol * (dx * dx + dy * dy)) {
        nvg__addPoint(ctx, x4, y4, type);
        return;
    }

    x234 := (x23 + x34) * 0.5;
    y234 := (y23 + y34) * 0.5;
    x1234 := (x123 + x234) * 0.5;
    y1234 := (y123 + y234) * 0.5;

    nvg__tesselateBezier(ctx, x1,y1, x12,y12, x123,y123, x1234,y1234, level + 1, 0);
    nvg__tesselateBezier(ctx, x1234,y1234, x234,y234, x34,y34, x4,y4, level + 1, type);
}

nvg__flattenPaths :: (ctx: *NVGcontext) {
    cache := ctx.cache;
    if (cache.paths.count > 0) {
        return;
    }

    // Flatten
    for cmd : ctx.commands {
        if cmd.type == {
            case .NVG_MOVETO;
                nvg__addPath(ctx);
                nvg__addPoint(ctx, cmd.args[0], cmd.args[1], .NVG_PT_CORNER);
            case .NVG_LINETO;
                nvg__addPoint(ctx, cmd.args[0], cmd.args[1], .NVG_PT_CORNER);
            case .NVG_BEZIERTO;
                last := nvg__lastPoint(ctx);
                if (last != null) {
                    nvg__tesselateBezier(ctx, last.x, last.y, cmd.args[0], cmd.args[1], cmd.args[2], cmd.args[3], cmd.args[4], cmd.args[5], 0, .NVG_PT_CORNER);
                }
            case .NVG_CLOSE;
                nvg__closePath(ctx);
            case .NVG_WINDING;
                nvg__pathWinding(ctx, cast(NVGwinding) cmd.args[0]);
        }
    }

    cache.bounds[0] = 1.0e6;
    cache.bounds[1] = 1.0e6;
    cache.bounds[2] = -1.0e6;
    cache.bounds[3] = -1.0e6;

    // Calculate the direction and length of line segments.
    for * path : cache.paths {
        pts := ref(*cache.points, path.first);

        // If the first and last points are the same, remove the last, mark as closed path.
        p0 := *pts[path.count - 1];
        p1 := *pts[0];
        if (nvg__ptEquals(p0.x,p0.y, p1.x,p1.y, ctx.distTol)) {
            path.closed = true;
            path.count -= 1;
            p0 = *pts[path.count - 1];
        }

        // Enforce winding.
        if (path.count > 2) {
            area := nvg__polyArea(pts, path.count);
            if (path.winding == .NVG_CCW && area < 0.0) {
                nvg__polyReverse(pts, path.count);
            }
            if (path.winding == .NVG_CW && area > 0.0) {
                nvg__polyReverse(pts, path.count);
            }
        }

        for 0..path.count-1 {
            // Calculate segment direction and length
            p0.dx = p1.x - p0.x;
            p0.dy = p1.y - p0.y;
            p0.len = nvg__normalize(*p0.dx, *p0.dy);
            // Update bounds
            cache.bounds[0] = min(cache.bounds[0], p0.x);
            cache.bounds[1] = min(cache.bounds[1], p0.y);
            cache.bounds[2] = max(cache.bounds[2], p0.x);
            cache.bounds[3] = max(cache.bounds[3], p0.y);
            // Advance
            p0 = p1;
            p1 += 1;
        }
    }
}

nvg__curveDivs :: (r: f32, arc: f32, tol: f32) -> s32 {
    da := acosf(r / (r + tol)) * 2.0;
    return max(2, cast(s32) ceilf(arc / da));
}

nvg__chooseBevel :: (bevel: NVGpointFlags, p0: *NVGpoint, p1: *NVGpoint, w: f32) -> f32, f32, f32, f32
{
    if (bevel) {
        return p1.x + p0.dy * w,
               p1.y - p0.dx * w,
               p1.x + p1.dy * w,
               p1.y - p1.dx * w;
    }

    return p1.x + p1.dmx * w,
           p1.y + p1.dmy * w,
           p1.x + p1.dmx * w,
           p1.y + p1.dmy * w;
}

nvg__roundJoin :: (
    dst: *List(NVGvertex), p0: *NVGpoint, p1: *NVGpoint,
    lw: f32, rw: f32, lu: f32, ru: f32, ncap: s32,
    fringe: f32)
{
    dlx0 := p0.dy;
    dly0 := -p0.dx;
    dlx1 := p1.dy;
    dly1 := -p1.dx;

    if (p1.flags & .NVG_PT_LEFT) {
        lx0, ly0, lx1, ly1 := nvg__chooseBevel(p1.flags & .NVG_PR_INNERBEVEL, p0, p1, lw);

        a0 := atan2f(-dly0, -dlx0);
        a1 := atan2f(-dly1, -dlx1);
        if (a1 > a0) {
            a1 -= cast(f32) (NVG_PI * 2);
        }

        add(dst, nvg__vtx(lx0, ly0, lu,1));
        add(dst, nvg__vtx(p1.x - dlx0 * rw, p1.y - dly0 * rw, ru,1));

        n := clamp(cast(s32) ceilf(((a0 - a1) / NVG_PI) * ncap), 2, ncap);
        for i : 0..n-1 {
            u := i / cast(f32)(n - 1);
            a := a0 + u * (a1 - a0);
            rx := p1.x + cosf(a) * rw;
            ry := p1.y + sinf(a) * rw;
            add(dst, nvg__vtx(p1.x, p1.y, 0.5,1));
            add(dst, nvg__vtx(rx, ry, ru,1));
        }

        add(dst, nvg__vtx(lx1, ly1, lu,1));
        add(dst, nvg__vtx(p1.x - dlx1 * rw, p1.y - dly1 * rw, ru,1));
    } else {
        rx0, ry0, rx1, ry1 := nvg__chooseBevel(p1.flags & .NVG_PR_INNERBEVEL, p0, p1, -rw);

        a0 := atan2f(dly0, dlx0);
        a1 := atan2f(dly1, dlx1);
        if (a1 < a0) {
            a1 += cast(f32) (NVG_PI * 2);
        }

        add(dst, nvg__vtx(p1.x + dlx0 * rw, p1.y + dly0 * rw, lu,1));
        add(dst, nvg__vtx(rx0, ry0, ru,1));

        n := clamp(cast(s32) ceilf(((a1 - a0) / NVG_PI) * ncap), 2, ncap);
        for i : 0..n-1 {
            u := i / cast(f32)(n - 1);
            a := a0 + u * (a1 - a0);
            lx := p1.x + cosf(a) * lw;
            ly := p1.y + sinf(a) * lw;
            add(dst, nvg__vtx(lx, ly, lu,1));
            add(dst, nvg__vtx(p1.x, p1.y, 0.5,1));
        }

        add(dst, nvg__vtx(p1.x + dlx1 * rw, p1.y + dly1 * rw, lu,1));
        add(dst, nvg__vtx(rx1, ry1, ru,1));
    }
}

nvg__bevelJoin :: (
    verts: *List(NVGvertex), p0: *NVGpoint, p1: *NVGpoint,
    lw: f32, rw: f32, lu: f32, ru: f32, fringe: f32)
{
    dlx0 := p0.dy;
    dly0 := -p0.dx;
    dlx1 := p1.dy;
    dly1 := -p1.dx;

    if (p1.flags & .NVG_PT_LEFT) {
        lx0, ly0, lx1, ly1 := nvg__chooseBevel(p1.flags & .NVG_PR_INNERBEVEL, p0, p1, lw);

        add(verts, nvg__vtx(lx0, ly0, lu,1));
        add(verts, nvg__vtx(p1.x - dlx0 * rw, p1.y - dly0 * rw, ru,1));

        if (p1.flags & .NVG_PT_BEVEL) {
            add(verts, nvg__vtx(lx0, ly0, lu,1));
            add(verts, nvg__vtx(p1.x - dlx0 * rw, p1.y - dly0 * rw, ru,1));

            add(verts, nvg__vtx(lx1, ly1, lu,1));
            add(verts, nvg__vtx(p1.x - dlx1 * rw, p1.y - dly1 * rw, ru,1));
        } else {
            rx0 := p1.x - p1.dmx * rw;
            ry0 := p1.y - p1.dmy * rw;

            add(verts, nvg__vtx(p1.x, p1.y, 0.5,1));
            add(verts, nvg__vtx(p1.x - dlx0 * rw, p1.y - dly0 * rw, ru,1));

            add(verts, nvg__vtx(rx0, ry0, ru,1));
            add(verts, nvg__vtx(rx0, ry0, ru,1));

            add(verts, nvg__vtx(p1.x, p1.y, 0.5,1));
            add(verts, nvg__vtx(p1.x - dlx1 * rw, p1.y - dly1 * rw, ru,1));
        }

        add(verts, nvg__vtx(lx1, ly1, lu,1));
        add(verts, nvg__vtx(p1.x - dlx1 * rw, p1.y - dly1 * rw, ru,1));

    } else {
        rx0, ry0, rx1, ry1 := nvg__chooseBevel(p1.flags & .NVG_PR_INNERBEVEL, p0, p1, -rw);

        add(verts, nvg__vtx(p1.x + dlx0 * lw, p1.y + dly0 * lw, lu,1));
        add(verts, nvg__vtx(rx0, ry0, ru,1));

        if (p1.flags & .NVG_PT_BEVEL) {
            add(verts, nvg__vtx(p1.x + dlx0 * lw, p1.y + dly0 * lw, lu,1));
            add(verts, nvg__vtx(rx0, ry0, ru,1));

            add(verts, nvg__vtx(p1.x + dlx1 * lw, p1.y + dly1 * lw, lu,1));
            add(verts, nvg__vtx(rx1, ry1, ru,1));
        } else {
            lx0 := p1.x + p1.dmx * lw;
            ly0 := p1.y + p1.dmy * lw;

            add(verts, nvg__vtx(p1.x + dlx0 * lw, p1.y + dly0 * lw, lu,1));
            add(verts, nvg__vtx(p1.x, p1.y, 0.5,1));

            add(verts, nvg__vtx(lx0, ly0, lu,1));
            add(verts, nvg__vtx(lx0, ly0, lu,1));

            add(verts, nvg__vtx(p1.x + dlx1 * lw, p1.y + dly1 * lw, lu,1));
            add(verts, nvg__vtx(p1.x, p1.y, 0.5,1));
        }

        add(verts, nvg__vtx(p1.x + dlx1 * lw, p1.y + dly1 * lw, lu,1));
        add(verts, nvg__vtx(rx1, ry1, ru,1));
    }
}

nvg__buttCapStart :: (
    verts: *List(NVGvertex), p: *NVGpoint,
    dx: f32, dy: f32, w: f32, d: f32,
    aa: f32, u0: f32, u1: f32)
{
    px := p.x - dx * d;
    py := p.y - dy * d;
    dlx := dy;
    dly := -dx;

    add(verts, nvg__vtx(px + dlx * w - dx * aa, py + dly * w - dy * aa, u0,0));
    add(verts, nvg__vtx(px - dlx * w - dx * aa, py - dly * w - dy * aa, u1,0));
    add(verts, nvg__vtx(px + dlx * w, py + dly * w, u0,1));
    add(verts, nvg__vtx(px - dlx * w, py - dly * w, u1,1));
}

nvg__buttCapEnd :: (
    verts: *List(NVGvertex), p: *NVGpoint,
    dx: f32, dy: f32, w: f32, d: f32,
    aa: f32, u0: f32, u1: f32)
{
    px := p.x + dx * d;
    py := p.y + dy * d;
    dlx := dy;
    dly := -dx;

    add(verts, nvg__vtx(px + dlx * w, py + dly * w, u0,1));
    add(verts, nvg__vtx(px - dlx * w, py - dly * w, u1,1));
    add(verts, nvg__vtx(px + dlx * w + dx * aa, py + dly * w + dy * aa, u0,0));
    add(verts, nvg__vtx(px - dlx * w + dx * aa, py - dly * w + dy * aa, u1,0));
}

nvg__roundCapStart :: (
    verts: *List(NVGvertex), p: *NVGpoint,
    dx: f32, dy: f32, w: f32, ncap: s32,
    aa: f32, u0: f32, u1: f32)
{
    px := p.x;
    py := p.y;
    dlx := dy;
    dly := -dx;

    for i : 0..ncap-1 {
        a := i / cast(f32) (ncap - 1) * NVG_PI;
        ax := cosf(a) * w;
        ay := sinf(a) * w;
        add(verts, nvg__vtx(px - dlx * ax - dx * ay, py - dly * ax - dy * ay, u0,1));
        add(verts, nvg__vtx(px, py, 0.5,1));
    }
    add(verts, nvg__vtx(px + dlx * w, py + dly * w, u0,1));
    add(verts, nvg__vtx(px - dlx * w, py - dly * w, u1,1));
}

nvg__roundCapEnd :: (
    verts: *List(NVGvertex), p: *NVGpoint,
    dx: f32, dy: f32, w: f32, ncap: s32,
    aa: f32, u0: f32, u1: f32)
{
    px := p.x;
    py := p.y;
    dlx := dy;
    dly := -dx;

    add(verts, nvg__vtx(px + dlx * w, py + dly * w, u0,1));
    add(verts, nvg__vtx(px - dlx * w, py - dly * w, u1,1));

    for i : 0..ncap-1 {
        a := i / cast(f32)(ncap - 1) * NVG_PI;
        ax := cosf(a) * w;
        ay := sinf(a) * w;
        add(verts, nvg__vtx(px, py, 0.5,1));
        add(verts, nvg__vtx(px - dlx * ax + dx * ay, py - dly * ax + dy * ay, u0,1));
    }
}

nvg__calculateJoins :: (ctx: *NVGcontext, w: f32, lineJoin: NVGlineCap, miterLimit: f32) {
    cache := ctx.cache;
    iw: f32 = 0.0;

    if (w > 0.0) {
        iw = 1.0 / w;
    }

    // Calculate which joins needs extra vertices to append, and gather vertex count.
    for * path : cache.paths {
        pts := ref(*cache.points, path.first);

        p0 := *pts[path.count - 1];
        p1 := *pts[0];

        nleft: s32 = 0;

        path.nbevel = 0;

        for j : 0..path.count-1 {
            dlx0 := p0.dy;
            dly0 := -p0.dx;
            dlx1 := p1.dy;
            dly1 := -p1.dx;

            // Calculate extrusions
            p1.dmx = (dlx0 + dlx1) * 0.5;
            p1.dmy = (dly0 + dly1) * 0.5;
            dmr2 := p1.dmx * p1.dmx + p1.dmy * p1.dmy;
            if (dmr2 > 0.000001) {
                scale := 1.0 / dmr2;
                if (scale > 600.0) {
                    scale = 600.0;
                }
                p1.dmx *= scale;
                p1.dmy *= scale;
            }

            // Clear flags, but keep the corner.
            p1.flags = (p1.flags & .NVG_PT_CORNER);

            // Keep track of left turns.
            cross := p1.dx * p0.dy - p0.dx * p1.dy;
            if (cross > 0.0) {
                nleft += 1;
                p1.flags |= .NVG_PT_LEFT;
            }

            // Calculate if we should use bevel or miter for inner join.
            limit := max(1.01, min(p0.len, p1.len) * iw);
            if ((dmr2 * limit * limit) < 1.0) {
                p1.flags |= .NVG_PR_INNERBEVEL;
            }

            // Check to see if the corner needs to be beveled.
            if (p1.flags & .NVG_PT_CORNER) {
                if ((dmr2 * miterLimit * miterLimit) < 1.0 || lineJoin == .NVG_BEVEL || lineJoin == .NVG_ROUND) {
                    p1.flags |= .NVG_PT_BEVEL;
                }
            }

            if ((p1.flags & (NVGpointFlags.NVG_PT_BEVEL | .NVG_PR_INNERBEVEL)) != 0) {
                path.nbevel += 1;
            }

            p0 = p1;
            p1 += 1;
        }

        path.convex = (nleft == path.count);
    }
}

nvg__expandStroke :: (ctx: *NVGcontext, w: f32, fringe: f32, lineCap: NVGlineCap, lineJoin: NVGlineCap, miterLimit: f32) {
    cache := ctx.cache;

    u0: f32 = 0.0;
    u1: f32 = 1.0;
    ncap := nvg__curveDivs(w, NVG_PI, ctx.tessTol); // Calculate divisions per half circle.

    w += fringe * 0.5;

    // Disable the gradient used for antialiasing when antialiasing is not used.
    if (fringe == 0.0) {
        u0 = 0.5;
        u1 = 0.5;
    }

    nvg__calculateJoins(ctx, w, lineJoin, miterLimit);

    // Calculate max vertex usage.
    cverts: s32 = 0;
    for * path : cache.paths {
        if (lineJoin == .NVG_ROUND) {
            cverts += (path.count + path.nbevel * (ncap + 2) + 1) * 2; // plus one for loop
        } else {
            cverts += (path.count + path.nbevel * 5 + 1) * 2; // plus one for loop
        }

        if (!path.closed) {
            // space for caps
            if (lineCap == .NVG_ROUND) {
                cverts += (ncap * 2 + 2) * 2;
            } else {
                cverts += (3 + 3) * 2;
            }
        }
    }

    verts := *cache.verts;
    ensureCapacity(verts, cverts);
    clear(verts);

    for * path : cache.paths {
        pts := ref(*cache.points, path.first);

        path.fill = null;
        path.nfill = 0;

        prevCount := verts.count;

        // Calculate fringe or stroke

        p0: *NVGpoint;
        p1: *NVGpoint;
        s, e: s32;

        if (path.closed) {
            // Looping
            p0 = *pts[path.count - 1];
            p1 = *pts[0];
            s = 0;
            e = path.count;
        } else {
            // Add cap
            p0 = *pts[0];
            p1 = *pts[1];
            s = 1;
            e = path.count - 1;
        }

        if (!path.closed) {
            // Add cap
            dx := p1.x - p0.x;
            dy := p1.y - p0.y;
            nvg__normalize(*dx, *dy);
            if (lineCap == .NVG_BUTT) {
                nvg__buttCapStart(verts, p0, dx, dy, w, -fringe * 0.5, fringe, u0, u1);
            } else if (lineCap == .NVG_BUTT || lineCap == .NVG_SQUARE) {
                nvg__buttCapStart(verts, p0, dx, dy, w, w - fringe, fringe, u0, u1);
            } else if (lineCap == .NVG_ROUND) {
                nvg__roundCapStart(verts, p0, dx, dy, w, ncap, fringe, u0, u1);
            }
        }

        for j : s..e-1 {
            if ((p1.flags & (NVGpointFlags.NVG_PT_BEVEL | .NVG_PR_INNERBEVEL)) != 0) {
                if (lineJoin == .NVG_ROUND) {
                    nvg__roundJoin(verts, p0, p1, w, w, u0, u1, ncap, fringe);
                } else {
                    nvg__bevelJoin(verts, p0, p1, w, w, u0, u1, fringe);
                }
            } else {
                add(verts, nvg__vtx(p1.x + (p1.dmx * w), p1.y + (p1.dmy * w), u0,1));
                add(verts, nvg__vtx(p1.x - (p1.dmx * w), p1.y - (p1.dmy * w), u1,1));
            }
            p0 = p1;
            p1 += 1;
        }

        if (path.closed) {
            // Loop it
            add(verts, nvg__vtx(ref(verts, prevCount + 0).x, ref(verts, prevCount + 0).y, u0,1));
            add(verts, nvg__vtx(ref(verts, prevCount + 1).x, ref(verts, prevCount + 1).y, u1,1));
        } else {
            // Add cap
            dx := p1.x - p0.x;
            dy := p1.y - p0.y;
            nvg__normalize(*dx, *dy);
            if (lineCap == .NVG_BUTT) {
                nvg__buttCapEnd(verts, p1, dx, dy, w, -fringe * 0.5, fringe, u0, u1);
            } else if (lineCap == .NVG_BUTT || lineCap == .NVG_SQUARE) {
                nvg__buttCapEnd(verts, p1, dx, dy, w, w - fringe, fringe, u0, u1);
            } else if (lineCap == .NVG_ROUND) {
                nvg__roundCapEnd(verts, p1, dx, dy, w, ncap, fringe, u0, u1);
            }
        }

        path.stroke = ref(verts, prevCount);
        path.nstroke = cast(s32) (verts.count - prevCount);
    }
}

nvg__expandFill :: (ctx: *NVGcontext, w: f32, lineJoin: NVGlineCap, miterLimit: f32) {
    cache := ctx.cache;

    fringe := w > 0.0;

    nvg__calculateJoins(ctx, w, lineJoin, miterLimit);

    // Calculate max vertex usage.
    nverts: s32 = 0;
    for * path : cache.paths {
        nverts += path.count + path.nbevel + 1;
        if (fringe) {
            nverts += (path.count + path.nbevel * 5 + 1) * 2; // plus one for loop
        }
    }

    verts := *cache.verts;
    ensureCapacity(verts, nverts);
    clear(verts);

    convex := cache.paths.count == 1 && cache.paths[0].convex;

    for * path : cache.paths {
        pts := ref(*cache.points, path.first);

        prevCount := verts.count;

        // Calculate shape vertices.
        woff := 0.5 * w;

        if (fringe) {
            // Looping
            p0 := *pts[path.count - 1];
            p1 := *pts[0];

            for j : 0..path.count-1 {
                if (p1.flags & .NVG_PT_BEVEL) {
                    dlx0 := p0.dy;
                    dly0 := -p0.dx;
                    dlx1 := p1.dy;
                    dly1 := -p1.dx;
                    if (p1.flags & .NVG_PT_LEFT) {
                        lx := p1.x + p1.dmx * woff;
                        ly := p1.y + p1.dmy * woff;
                        add(verts, nvg__vtx(lx, ly, 0.5, 1));
                    } else {
                        lx0 := p1.x + dlx0 * woff;
                        ly0 := p1.y + dly0 * woff;
                        lx1 := p1.x + dlx1 * woff;
                        ly1 := p1.y + dly1 * woff;
                        add(verts, nvg__vtx(lx0, ly0, 0.5, 1));
                        add(verts, nvg__vtx(lx1, ly1, 0.5, 1));
                    }
                } else {
                    add(verts, nvg__vtx(p1.x + (p1.dmx * woff), p1.y + (p1.dmy * woff), 0.5, 1));
                }
                p0 = p1;
                p1 += 1;
            }
        } else {
            for j : 0..path.count-1 {
                add(verts, nvg__vtx(pts[j].x, pts[j].y, 0.5, 1));
            }

            // triangulate if batching
            // if (path.convex) {
            //     dst = nvg__triangulate_convex(dst, pts, path.count);
            // } else {
            //     nvg__triangulate(dst, pts, path.count);
            // }
        }

        path.fill = ref(verts, prevCount);
        path.nfill = cast(s32) (verts.count - prevCount);

        // Calculate fringe
        if (fringe) {
            lw := w + woff;
            rw := w - woff;
            lu: f32 = 0.0;
            ru: f32 = 1.0;

            prevCount = verts.count;

            // Create only half a fringe for convex shapes so that
            // the shape can be rendered without stenciling.
            if (convex) {
                lw = woff; // This should generate the same vertex as fill inset above.
                lu = 0.5;  // Set outline fade at middle.
            }

            // Looping
            p0 := *pts[path.count - 1];
            p1 := *pts[0];

            for j : 0..path.count-1 {
                if ((p1.flags & (NVGpointFlags.NVG_PT_BEVEL | .NVG_PR_INNERBEVEL)) != 0) {
                    nvg__bevelJoin(verts, p0, p1, lw, rw, lu, ru, w);
                } else {
                    add(verts, nvg__vtx(p1.x + (p1.dmx * lw), p1.y + (p1.dmy * lw), lu, 1));
                    add(verts, nvg__vtx(p1.x - (p1.dmx * rw), p1.y - (p1.dmy * rw), ru, 1));
                }
                p0 = p1;
                p1 += 1;
            }

            // Loop it
            add(verts, nvg__vtx(ref(verts, prevCount + 0).x, ref(verts, prevCount + 0).y, lu, 1));
            add(verts, nvg__vtx(ref(verts, prevCount + 1).x, ref(verts, prevCount + 1).y, ru, 1));

            path.stroke = ref(verts, prevCount);
            path.nstroke = cast(s32) (verts.count - prevCount);
        } else {
            path.stroke = null;
            path.nstroke = 0;
        }
    }
}

// nvg__triangulate_convex :: (verts: *NVGvertex, pts: *NVGpoint, npts: s32) -> *NVGvertex {
//     for j : 2..npts-1 {
//         nvg__vset(verts, pts[0].x, pts[0].y, 0.5, 1);
//         verts += 1;
//         nvg__vset(verts, pts[j-1].x, pts[j-1].y, 0.5, 1);
//         verts += 1;
//         nvg__vset(verts, pts[j].x, pts[j].y, 0.5, 1);
//         verts += 1;
//     }
//     return verts;
// }

// nvg__triangulate :: (verts: *NVGvertex, pts: *NVGpoint, npts: s32) {
// }

nvg__command :: inline (cmd: NVGcommands, args: ..f32) -> NVGcommand {
    result: NVGcommand;
    result.type = cmd;
    for i : 0..args.count-1 {
        result.args[i] = args[i];
    }
    return result;
}

nvg__argCount :: inline (cmd: NVGcommands) -> s32 {
    if cmd == {
        case .NVG_MOVETO; return 2;
        case .NVG_LINETO; return 2;
        case .NVG_BEZIERTO; return 6;
        case .NVG_CLOSE; return 0;
        case .NVG_WINDING; return 1;
        case; return -1;
    }
}

nvg__deletePathCache :: (c: *NVGpathCache) {
    if (c == null) {
        return;
    }
    uninit(*c.points);
    uninit(*c.paths);
    uninit(*c.verts);
    free(c);
}

nvg__allocPathCache :: () -> *NVGpathCache {
    c := alloc(NVGpathCache);
    if (c == null) {
        nvg__deletePathCache(c);
        return null;
    }

    c.points = createList(NVGpoint, ListOptions(NVGpoint).{
        capacity = NVG_INIT_POINTS_SIZE
    });
    if (c.points.items == null) {
        nvg__deletePathCache(c);
        return null;
    }

    c.paths = createList(NVGpath, ListOptions(NVGpath).{
        capacity = NVG_INIT_PATHS_SIZE
    });
    if (c.paths.items == null) {
        nvg__deletePathCache(c);
        return null;
    };

    c.verts = createList(NVGvertex, ListOptions(NVGvertex).{
        capacity = NVG_INIT_VERTS_SIZE
    });
    if (c.verts.items == null) {
        nvg__deletePathCache(c);
        return null;
    }

    return c;
}

nvg__quantize :: (a: f32, d: f32) -> f32 {
    return (cast(s32)(a / d + 0.5)) * d;
}

nvg__getFontScale :: (state: *NVGstate) -> f32 {
    return min(nvg__quantize(nvg__getAverageScale(state.xform), 0.01), 4.0);
}

nvg__flushTextTexture :: (ctx: *NVGcontext) {
    dirty: [4] s32;
    if (fonsValidateTexture(ctx.fs, dirty)) {
        fontImage := ctx.fontImages[ctx.fontImageIdx];
        // Update texture
        if (fontImage != 0) {
            iw, ih: s32;
            data := fonsGetTextureData(ctx.fs, *iw, *ih);
            x := dirty[0];
            y := dirty[1];
            w := dirty[2] - dirty[0];
            h := dirty[3] - dirty[1];
            ctx.params.renderUpdateTexture(ctx.params.userPtr, fontImage, x,y, w,h, data);
        }
    }
}

nvg__allocTextAtlas :: (ctx: *NVGcontext) -> bool {
    nvg__flushTextTexture(ctx);
    if (ctx.fontImageIdx >= NVG_MAX_FONTIMAGES - 1) {
        return false;
    }
    iw, ih: s32;
    // if next fontImage already have a texture
    if (ctx.fontImages[ctx.fontImageIdx + 1] != 0) {
        nvgImageSize(ctx, ctx.fontImages[ctx.fontImageIdx + 1], *iw, *ih);
    } else {
        // calculate the new font image size and create it.
        nvgImageSize(ctx, ctx.fontImages[ctx.fontImageIdx], *iw, *ih);
        if (iw > ih) {
            ih *= 2;
        } else {
            iw *= 2;
        }
        if (iw > NVG_MAX_FONTIMAGE_SIZE || ih > NVG_MAX_FONTIMAGE_SIZE) {
            iw = NVG_MAX_FONTIMAGE_SIZE;
            ih = NVG_MAX_FONTIMAGE_SIZE;
        }
        ctx.fontImages[ctx.fontImageIdx + 1] = ctx.params.renderCreateTexture(ctx.params.userPtr, .NVG_TEXTURE_ALPHA, iw, ih, 0, null);
    }
    ctx.fontImageIdx += 1;
    fonsResetAtlas(ctx.fs, iw, ih);
    return true;
}

nvg__renderText :: (ctx: *NVGcontext, verts: *NVGvertex, nverts: s32) {
    state := nvg__getState(ctx);
    paint := state.fill;

    // Render triangles.
    paint.image = ctx.fontImages[ctx.fontImageIdx];

    // Apply global alpha
    paint.innerColor.a *= state.alpha;
    paint.outerColor.a *= state.alpha;

    ctx.params.renderTriangles(ctx.params.userPtr, *paint, state.compositeOperation, *state.scissor, verts, nverts);

    ctx.drawCallCount += 1;
    ctx.textTriCount += nverts / 3;
}

nvg__nvgAlignToFONSAlign :: inline (align: NVGalign) -> FONSalign {
    return cast(FONSalign) (cast(s32) align);
}

nvg__isTransformFlipped :: (xform: [] f32) -> bool {
    det := xform[0] * xform[3] - xform[2] * xform[1];
    return det < 0;
}

nvg__cross :: (x0: f32, y0: f32, x1: f32, y1: f32) -> f32 {
    return x1 * y0 - x0 * y1;
}

nvg__normalize :: (x: *f32, y: *f32) -> f32 {
    d := sqrtf((<<x) * (<<x) + (<<y) * (<<y));
    if (d > 1.0e-6) {
        id := 1.0 / d;
        <<x *= id;
        <<y *= id;
    }
    return d;
}
