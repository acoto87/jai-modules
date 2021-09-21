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

// this comes from GL module
GL_LUMINANCE :: 0x1909;

NVGcreateFlags :: enum s32 {
    // Flag indicating if geometry based anti-aliasing is used (may not be needed when using MSAA).
    NVG_ANTIALIAS       :: 1<<0;
    // Flag indicating if strokes should be drawn using stencil buffer. The rendering will be a little
    // slower, but path overlaps (i.e. self-intersecting or sharp turns) will be drawn just once.
    NVG_STENCIL_STROKES :: 1<<1;
    // Flag indicating that additional debug checks are done.
    NVG_DEBUG           :: 1<<2;
}

#if NANOVG_GL2 {
    nvgCreateGL2 :: (flags: NVGcreateFlags) -> *NVGcontext {
        return nvg__createGL(flags);
    }

    nvgDeleteGL2 :: (ctx: *NVGcontext) {
        nvg__deleteGL(ctx);
    }

    nvglCreateImageFromHandleGL2 :: (ctx: *NVGcontext, textureId: GLuint, w: s32, h: s32, flags: NVGimageFlags) -> s32 {
        return nvg__createImageFromHandleGL(ctx, textureId, w, h, flags);
    }

    nvglImageHandleGL2 :: (ctx: *NVGcontext, image: s32) -> GLuint {
        return nvg__imageHandleGL(ctx, image);
    }
}

#if NANOVG_GL3 {
    nvgCreateGL3 :: (flags: NVGcreateFlags) -> *NVGcontext {
        return nvg__createGL(flags);
    }

    nvgDeleteGL3 :: (ctx: *NVGcontext) {
        nvg__deleteGL(ctx);
    }

    nvglCreateImageFromHandleGL3 :: (ctx: *NVGcontext, textureId: GLuint, w: s32, h: s32, flags: NVGimageFlags) -> s32 {
        return nvg__createImageFromHandleGL(ctx, textureId, w, h, flags);
    }

    nvglImageHandleGL3 :: (ctx: *NVGcontext, image: s32) -> GLuint {
        return nvg__imageHandleGL(ctx, image);
    }
}

#if NANOVG_GLES2 {
    nvgCreateGLES2 :: (flags: NVGcreateFlags) -> *NVGcontext {
        return nvg__createGL(flags);
    }

    nvgDeleteGLES2 :: (ctx: *NVGcontext) {
        nvg__deleteGL(ctx);
    }

    nvglCreateImageFromHandleGLES2 :: (ctx: *NVGcontext, textureId: GLuint, w: s32, h: s32, flags: NVGimageFlags) -> s32 {
        return nvg__createImageFromHandleGL(ctx, textureId, w, h, flags);
    }

    nvglImageHandleGLES2 :: (ctx: *NVGcontext, image: s32) -> GLuint {
        return nvg__imageHandleGL(ctx, image);
    }
}

#if NANOVG_GLES3 {
    nvgCreateGLES3 :: (flags: NVGcreateFlags) -> *NVGcontext {
        return nvg__createGL(flags);
    }

    nvgDeleteGLES3 :: (ctx: *NVGcontext) {
        nvg__deleteGL(ctx);
    }

    nvglCreateImageFromHandleGLES3 :: (ctx: *NVGcontext, textureId: GLuint, w: s32, h: s32, flags: NVGimageFlags) -> s32 {
        return nvg__createImageFromHandleGL(ctx, textureId, w, h, flags);
    }

    nvglImageHandleGLES3 :: (ctx: *NVGcontext, image: s32) -> GLuint {
        return nvg__imageHandleGL(ctx, image);
    }
}

#scope_file

#import "GL";
#import "utils";
#import "strings";

// @Note: This constant is missing from gl_core.jai in compiler modules
GL_GENERATE_MIPMAP :: 0x8191;

GLNVGuniformLoc :: enum s32 {
    GLNVG_LOC_VIEWSIZE :: 0;
    GLNVG_LOC_TEX :: 1;
    GLNVG_LOC_FRAG :: 2;
    GLNVG_MAX_LOCS :: 3;
}

GLNVGshaderType :: enum s32 {
    NSVG_SHADER_FILLGRAD :: 0;
    NSVG_SHADER_FILLIMG :: 1;
    NSVG_SHADER_SIMPLE :: 2;
    NSVG_SHADER_IMG :: 3;
}

#if NANOVG_GL_USE_UNIFORMBUFFER {
    GLNVGuniformBindings :: enum s32 {
        GLNVG_FRAG_BINDING :: 0;
    };
}

GLNVGshader :: struct {
    prog: GLuint;
    frag: GLuint;
    vert: GLuint;
    loc: [GLNVGuniformLoc.GLNVG_MAX_LOCS] GLint;
}

GLNVGtexture :: struct {
    id: s32;
    tex: GLuint;
    width: s32;
    height: s32;
    type: NVGtexture;
    flags: NVGimageFlags;
}

GLNVGblend :: struct {
    srcRGB: GLenum;
    dstRGB: GLenum;
    srcAlpha: GLenum;
    dstAlpha: GLenum;
}

GLNVGcallType :: enum s32 {
    GLNVG_NONE;
    GLNVG_FILL;
    GLNVG_CONVEXFILL;
    GLNVG_STROKE;
    GLNVG_TRIANGLES;
}

GLNVGcall :: struct {
    type: GLNVGcallType;
    image: s32;
    pathOffset: s32;
    pathCount: s32;
    triangleOffset: s32;
    triangleCount: s32;
    uniformOffset: s32;
    blendFunc: GLNVGblend;
}

GLNVGpath :: struct {
    fillOffset: s32;
    fillCount: s32;
    strokeOffset: s32;
    strokeCount: s32;
}

// note: after modifying layout or size of uniform array,
// don't forget to also update the fragment shader source!
#if !NANOVG_GL_USE_UNIFORMBUFFER {
    NANOVG_GL_UNIFORMARRAY_SIZE :: 11;
}

GLNVGfragUniforms :: struct {
    #if NANOVG_GL_USE_UNIFORMBUFFER {
        scissorMat: [12] f32; // matrices are actually 3 vec4s
		paintMat: [12] f32;
		innerCol: NVGcolor;
		outerCol: NVGcolor;
		scissorExt: [2] f32;
		scissorScale: [2] f32;
		extent: [2] f32;
		radius: f32;
		feather: f32;
		strokeMult: f32;
		strokeThr: f32;
		texType: s32;
		type: GLNVGshaderType;
    } else {
        union {
            struct {
                scissorMat: [12] f32; // matrices are actually 3 vec4s
                paintMat: [12] f32;
                innerCol: NVGcolor;
                outerCol: NVGcolor;
                scissorExt: [2] f32;
                scissorScale: [2] f32;
                extent: [2] f32;
                radius: f32;
                feather: f32;
                strokeMult: f32;
                strokeThr: f32;
                texType: f32;
                type: f32;
            };
            uniformArray: [NANOVG_GL_UNIFORMARRAY_SIZE][4] f32;
        };
    }
}

GLNVGcontext :: struct {
    shader: GLNVGshader;
    view: [2] f32;
    textures: List(GLNVGtexture);
    textureId: s32;
    vertBuf: GLuint;
    #if NANOVG_GL3 {
        vertArr: GLuint;
    }
    #if NANOVG_GL_USE_UNIFORMBUFFER {
	    fragBuf: GLuint;
    }
    fragSize: s32;
    flags: NVGcreateFlags;

    // Per frame buffers
    calls: List(GLNVGcall);
    paths: List(GLNVGpath);
    verts: List(NVGvertex);
    uniforms: *u8;
    cuniforms: s32;
    nuniforms: s32;

    // cached state
    #if NANOVG_GL_USE_STATE_FILTER {
        boundTexture: GLuint;
        stencilMask: GLuint;
        stencilFunc: GLenum;
        stencilFuncRef: GLint;
        stencilFuncMask: GLuint;
        blendFunc: GLNVGblend;
    }
    dummyTex: s32;
}

nvg__createGL :: (flags: NVGcreateFlags) -> *NVGcontext {
    gl := alloc(GLNVGcontext);
    if (gl == null) {
        return null;
    }

    gl.flags = flags;

    gl.textures = createList(GLNVGtexture, ListOptions(GLNVGtexture).{
        capacity = 8
    });
    if (gl.textures.items == null) {
        return null;
    }

    gl.calls = createList(GLNVGcall, ListOptions(GLNVGcall).{
        capacity = 128
    });
    if (gl.calls.items == null) {
        return null;
    }

    gl.paths = createList(GLNVGpath, ListOptions(GLNVGpath).{
        capacity = 128
    });
    if (gl.paths.items == null) {
        return null;
    }

    gl.verts = createList(NVGvertex, ListOptions(NVGvertex).{
        capacity = 4096
    });
    if (gl.verts.items == null) {
        return null;
    }

    params: NVGparams;
    params.renderCreate = glnvg__renderCreate;
    params.renderCreateTexture = glnvg__renderCreateTexture;
    params.renderDeleteTexture = glnvg__renderDeleteTexture;
    params.renderUpdateTexture = glnvg__renderUpdateTexture;
    params.renderGetTextureSize = glnvg__renderGetTextureSize;
    params.renderViewport = glnvg__renderViewport;
    params.renderCancel = glnvg__renderCancel;
    params.renderFlush = glnvg__renderFlush;
    params.renderFill = glnvg__renderFill;
    params.renderStroke = glnvg__renderStroke;
    params.renderTriangles = glnvg__renderTriangles;
    params.renderDelete = glnvg__renderDelete;
    params.userPtr = gl;
    params.edgeAntiAlias = (flags & .NVG_ANTIALIAS) != 0;

    ctx := nvgCreateInternal(*params);
    if (ctx == null) {
        glnvg__renderDelete(gl);
        return null;
    }

    return ctx;
}

nvg__deleteGL :: (ctx: *NVGcontext) {
    nvgDeleteInternal(ctx);
}

nvg__createImageFromHandleGL :: (ctx: *NVGcontext, textureId: GLuint, w: s32, h: s32, flags: NVGimageFlags) -> s32 {
    gl := cast(*GLNVGcontext) nvgInternalParams(ctx).userPtr;

    tex := glnvg__allocTexture(gl);
    if (tex == null) {
        return 0;
    }
    tex.type = .NVG_TEXTURE_RGBA;
    tex.tex = textureId;
    tex.flags = flags;
    tex.width = w;
    tex.height = h;

    return tex.id;
}

nvg__imageHandleGL :: (ctx: *NVGcontext, image: s32) -> GLuint {
    gl := cast(*GLNVGcontext) nvgInternalParams(ctx).userPtr;
    tex := glnvg__findTexture(gl, image);
    return tex.tex;
}

#if NANOVG_GLES2 {
    glnvg__nearestPow2 :: (num: u32) -> u32 {
        n := ifx num > 0 then num - 1 else 0;
        n |= n >> 1;
        n |= n >> 2;
        n |= n >> 4;
        n |= n >> 8;
        n |= n >> 16;
        n += 1;
        return n;
    }
}

glnvg__bindTexture :: (gl: *GLNVGcontext, tex: GLuint) {
    #if NANOVG_GL_USE_STATE_FILTER {
        if (gl.boundTexture != tex) {
            gl.boundTexture = tex;
            glBindTexture(GL_TEXTURE_2D, tex);
        }
    } else {
	    glBindTexture(GL_TEXTURE_2D, tex);
    }
}

glnvg__stencilMask :: (gl: *GLNVGcontext, mask: GLuint) {
    #if NANOVG_GL_USE_STATE_FILTER {
        if (gl.stencilMask != mask) {
            gl.stencilMask = mask;
            glStencilMask(mask);
        }
    } else {
        glStencilMask(mask);
    }
}

glnvg__stencilFunc :: (gl: *GLNVGcontext, func: GLenum, ref: GLint, mask: GLuint) {
    #if NANOVG_GL_USE_STATE_FILTER {
        if ((gl.stencilFunc != func) ||
            (gl.stencilFuncRef != ref) ||
            (gl.stencilFuncMask != mask)) {

            gl.stencilFunc = func;
            gl.stencilFuncRef = ref;
            gl.stencilFuncMask = mask;
            glStencilFunc(func, ref, mask);
        }
    } else {
	    glStencilFunc(func, ref, mask);
    }
}

glnvg__blendFuncSeparate :: (gl: *GLNVGcontext, blend: *GLNVGblend) {
    #if NANOVG_GL_USE_STATE_FILTER {
        if ((gl.blendFunc.srcRGB != blend.srcRGB) ||
            (gl.blendFunc.dstRGB != blend.dstRGB) ||
            (gl.blendFunc.srcAlpha != blend.srcAlpha) ||
            (gl.blendFunc.dstAlpha != blend.dstAlpha)) {

            gl.blendFunc = <<blend;
            glBlendFuncSeparate(blend.srcRGB, blend.dstRGB, blend.srcAlpha,blend.dstAlpha);
        }
    } else {
	    glBlendFuncSeparate(blend.srcRGB, blend.dstRGB, blend.srcAlpha,blend.dstAlpha);
    }
}

glnvg__allocTexture :: (gl: *GLNVGcontext) -> *GLNVGtexture {
    texture := glnvg__findTexture(gl, 0);

    if (texture == null) {
        texture = addNew(*gl.textures);
    }

    memoryClear(texture);

    gl.textureId += 1;

    texture.id = gl.textureId;
    return texture;
}

glnvg__findTexture :: (gl: *GLNVGcontext, id: s32) -> *GLNVGtexture {
    for * texture : gl.textures {
        if (texture.id == id) {
            return texture;
        }
    }
    return null;
}

glnvg__deleteTexture :: (gl: *GLNVGcontext, id: s32) -> bool {
    for * texture : gl.textures {
        if (texture.id == id) {
            if (texture.tex != 0 && (texture.flags & .NVG_IMAGE_NODELETE) == 0) {
                glDeleteTextures(1, *texture.tex);
            }
            memoryClear(texture);
            return true;
        }
    }
    return false;
}

glnvg__dumpShaderError :: (shader: GLuint, name: string, type: string) {
    str: [512+1] GLchar;
    len: GLsizei = 0;
    glGetShaderInfoLog(shader, 512, *len, str.data);
    if (len > 512) {
        len = 512;
    }
    str[len] = #char "\0";
    print("Shader %/% error:\n%\n", name, type, toString(str.data));
}

glnvg__dumpProgramError :: (prog: GLuint, name: string) {
    str: [512+1] GLchar;
    len: GLsizei = 0;
    glGetProgramInfoLog(prog, 512, *len, str.data);
    if (len > 512) {
        len = 512;
    }
    str[len] = #char "\0";
    print("Program % error:\n%\n", name, toString(str.data));
}

glnvg__checkError :: (gl: *GLNVGcontext, str: string) {
    if (!(gl.flags & .NVG_DEBUG)) {
        return;
    }
    err := glGetError();
    while (err != GL_NO_ERROR) {
        print("Error % after %\n", glnvg__getErrorCodeName(err), str);
        err = glGetError();
    }
}

glnvg__getErrorCodeName :: (errCode: GLenum) -> string {
    if errCode == {
        case GL_INVALID_ENUM; return "GL INVALID ENUM";
        case GL_INVALID_VALUE; return "GL INVALID VALUE";
        case GL_INVALID_OPERATION; return "GL INVALID OPERATION";
        case GL_INVALID_FRAMEBUFFER_OPERATION; return "GL INVALID FRAMEBUFFER OPERATION";
        case GL_OUT_OF_MEMORY; return "GL OUT OF MEMORY";
        case; return "";
    }
}

glnvg__createShader :: (shader: *GLNVGshader, name: string, header: string, opts: string, vshader: string, fshader: string) -> bool {
    status: GLint;

    source: [3] *u8;
    source[0] = toCString(header);
    source[1] = toCString(opts);

    memoryClear(shader);

    prog := gl.glCreateProgram();
    vert := glCreateShader(GL_VERTEX_SHADER);
    frag := glCreateShader(GL_FRAGMENT_SHADER);

    source[2] = toCString(vshader);
    glShaderSource(vert, 3, source.data, null);
    free(source[2]);

    source[2] = toCString(fshader);
    glShaderSource(frag, 3, source.data, null);
    free(source[2]);
    free(source[1]);
    free(source[0]);

    glCompileShader(vert);
    glGetShaderiv(vert, GL_COMPILE_STATUS, *status);
    if (status != 1 /* GL_TRUE */) {
        glnvg__dumpShaderError(vert, name, "vert");
        return false;
    }

    glCompileShader(frag);
    glGetShaderiv(frag, GL_COMPILE_STATUS, *status);
    if (status != 1 /* GL_TRUE */) {
        glnvg__dumpShaderError(frag, name, "frag");
        return false;
    }

    glAttachShader(prog, vert);
    glAttachShader(prog, frag);

    glBindAttribLocation(prog, 0, "vertex");
    glBindAttribLocation(prog, 1, "tcoord");

    glLinkProgram(prog);
    glGetProgramiv(prog, GL_LINK_STATUS, *status);
    if (status != 1 /* GL_TRUE */) {
        glnvg__dumpProgramError(prog, name);
        return false;
    }

    shader.prog = prog;
    shader.vert = vert;
    shader.frag = frag;

    return true;
}

glnvg__deleteShader :: (shader: *GLNVGshader) {
    if (shader.prog != 0) {
        glDeleteProgram(shader.prog);
    }
    if (shader.vert != 0) {
        glDeleteShader(shader.vert);
    }
    if (shader.frag != 0) {
        glDeleteShader(shader.frag);
    }
}

glnvg__getUniforms :: (shader: *GLNVGshader) {
    shader.loc[GLNVGuniformLoc.GLNVG_LOC_VIEWSIZE] = glGetUniformLocation(shader.prog, "viewSize");
    shader.loc[GLNVGuniformLoc.GLNVG_LOC_TEX] = glGetUniformLocation(shader.prog, "tex");

    #if NANOVG_GL_USE_UNIFORMBUFFER {
	    shader.loc[GLNVGuniformLoc.GLNVG_LOC_FRAG] = cast(s32) glGetUniformBlockIndex(shader.prog, "frag");
    } else {
        shader.loc[GLNVGuniformLoc.GLNVG_LOC_FRAG] = glGetUniformLocation(shader.prog, "frag");
    }
}

glnvg__renderCreate :: (uptr: *void) -> bool {
    gl := cast(*GLNVGcontext) uptr;
    align: s32 = 4;

    // TODO: mediump float may not be enough for GLES2 in iOS.
    // see the following discussion: https://github.com/memononen/nanovg/issues/46

    builder: StringBuilder;
    defer freeBuffers(*builder);

    #if NANOVG_GL2 {
        appendToBuilder(*builder, "#define NANOVG_GL2 1\n");
    } else if NANOVG_GL3 {
        appendToBuilder(*builder, "#version 150 core\n");
        appendToBuilder(*builder, "#define NANOVG_GL3 1\n");
    } else if NANOVG_GLES2 {
        appendToBuilder(*builder, "#version 100\n");
        appendToBuilder(*builder, "#define NANOVG_GL2 1\n");
    } else if NANOVG_GLES3 {
        appendToBuilder(*builder, "#version 300 es\n");
        appendToBuilder(*builder, "#define NANOVG_GL3 1\n");
    }

    #if NANOVG_GL_USE_UNIFORMBUFFER {
        appendToBuilder(*builder, "#define USE_UNIFORMBUFFER 1\n");
    } else {
        appendToBuilder(*builder, "#define UNIFORMARRAY_SIZE 11\n");
    }

    shaderHeader := builderToString(*builder);

    fillVertShader := #string DONE
        #ifdef NANOVG_GL3
            uniform vec2 viewSize;
            in vec2 vertex;
            in vec2 tcoord;
            out vec2 ftcoord;
            out vec2 fpos;
        #else
            uniform vec2 viewSize;
            attribute vec2 vertex;
            attribute vec2 tcoord;
            varying vec2 ftcoord;
            varying vec2 fpos;
        #endif
        void main(void) {
            ftcoord = tcoord;
            fpos = vertex;
            gl_Position = vec4(2.0 * vertex.x / viewSize.x - 1.0, 1.0 - 2.0 * vertex.y / viewSize.y, 0, 1);
        }
    DONE;

    fillFragShader := #string DONE
        #ifdef GL_ES
            #if defined(GL_FRAGMENT_PRECISION_HIGH) || defined(NANOVG_GL3)
                precision highp float;
            #else
                precision mediump float;
            #endif
        #endif

        #ifdef NANOVG_GL3
            #ifdef USE_UNIFORMBUFFER
                layout(std140) uniform frag {
                    mat3 scissorMat;
                    mat3 paintMat;
                    vec4 innerCol;
                    vec4 outerCol;
                    vec2 scissorExt;
                    vec2 scissorScale;
                    vec2 extent;
                    float radius;
                    float feather;
                    float strokeMult;
                    float strokeThr;
                    int texType;
                    int type;
                };
            #else
                uniform vec4 frag[UNIFORMARRAY_SIZE];
            #endif
            uniform sampler2D tex;
            in vec2 ftcoord;
            in vec2 fpos;
            out vec4 outColor;
        #else
            uniform vec4 frag[UNIFORMARRAY_SIZE];
            uniform sampler2D tex;
            varying vec2 ftcoord;
            varying vec2 fpos;
        #endif

        #ifndef USE_UNIFORMBUFFER
            #define scissorMat mat3(frag[0].xyz, frag[1].xyz, frag[2].xyz)
		    #define paintMat mat3(frag[3].xyz, frag[4].xyz, frag[5].xyz)
		    #define innerCol frag[6]
		    #define outerCol frag[7]
		    #define scissorExt frag[8].xy
		    #define scissorScale frag[8].zw
		    #define extent frag[9].xy
		    #define radius frag[9].z
		    #define feather frag[9].w
		    #define strokeMult frag[10].x
		    #define strokeThr frag[10].y
		    #define texType int(frag[10].z)
		    #define type int(frag[10].w)
        #endif

        float sdroundrect(vec2 pt, vec2 ext, float rad) {
            vec2 ext2 = ext - vec2(rad,rad);
            vec2 d = abs(pt) - ext2;
            return min(max(d.x,d.y),0.0) + length(max(d,0.0)) - rad;
        }

        // Scissoring
        float scissorMask(vec2 p) {
            vec2 sc = (abs((scissorMat * vec3(p,1.0)).xy) - scissorExt);
            sc = vec2(0.5,0.5) - sc * scissorScale;
            return clamp(sc.x,0.0,1.0) * clamp(sc.y,0.0,1.0);
        }

        #ifdef EDGE_AA
            // Stroke - from [0..1] to clipped pyramid, where the slope is 1px.
            float strokeMask() {
                return min(1.0, (1.0 - abs(ftcoord.x * 2.0 - 1.0)) * strokeMult) * min(1.0, ftcoord.y);
            }
        #endif

        void main(void) {
            vec4 result;
            float scissor = scissorMask(fpos);

            #ifdef EDGE_AA
                float strokeAlpha = strokeMask();
                if (strokeAlpha < strokeThr) discard;
            #else
                float strokeAlpha = 1.0;
            #endif

            if (type == 0) {                // Gradient
                // Calculate gradient color using box gradient
                vec2 pt = (paintMat * vec3(fpos,1.0)).xy;
                float d = clamp((sdroundrect(pt, extent, radius) + feather * 0.5) / feather, 0.0, 1.0);
                vec4 color = mix(innerCol,outerCol,d);
                // Combine alpha
                color *= strokeAlpha * scissor;
                result = color;
            } else if (type == 1) {         // Image
                // Calculate color fron texture
                vec2 pt = (paintMat * vec3(fpos,1.0)).xy / extent;
                #ifdef NANOVG_GL3
                    vec4 color = texture(tex, pt);
                #else
                    vec4 color = texture2D(tex, pt);
                #endif
                if (texType == 1) color = vec4(color.xyz * color.w, color.w);
                if (texType == 2) color = vec4(color.x);
                // Apply color tint and alpha.
                color *= innerCol;
                // Combine alpha
                color *= strokeAlpha * scissor;
                result = color;
            } else if (type == 2) {         // Stencil fill
                result = vec4(1,1,1,1);
            } else if (type == 3) {         // Textured tris
                #ifdef NANOVG_GL3
                    vec4 color = texture(tex, ftcoord);
                #else
                    vec4 color = texture2D(tex, ftcoord);
                #endif
                if (texType == 1) color = vec4(color.xyz * color.w,color.w);
                if (texType == 2) color = vec4(color.x);
                color *= scissor;
                result = color * innerCol;
            }
            #ifdef NANOVG_GL3
            	outColor = result;
            #else
            	gl_FragColor = result;
            #endif
        }
    DONE;

    glnvg__checkError(gl, "init");

    if (gl.flags & .NVG_ANTIALIAS) {
        if (!glnvg__createShader(*gl.shader, "shader", shaderHeader, "#define EDGE_AA 1\n", fillVertShader, fillFragShader)) {
            return false;
        }
    } else {
        if (!glnvg__createShader(*gl.shader, "shader", shaderHeader, "", fillVertShader, fillFragShader)) {
            return false;
        }
    }

    glnvg__checkError(gl, "uniform locations");
    glnvg__getUniforms(*gl.shader);

    #if NANOVG_GL3 {
        glGenVertexArrays(1, *gl.vertArr);
    }
    glGenBuffers(1, *gl.vertBuf);

    #if NANOVG_GL_USE_UNIFORMBUFFER {
        // Create UBOs
        glUniformBlockBinding(gl.shader.prog, cast(u32) gl.shader.loc[GLNVGuniformLoc.GLNVG_LOC_FRAG], cast(u32) GLNVGuniformBindings.GLNVG_FRAG_BINDING);
        glGenBuffers(1, *gl.fragBuf);
        glGetIntegerv(GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT, *align);
    }
    gl.fragSize = size_of(GLNVGfragUniforms) + align - size_of(GLNVGfragUniforms) % align;

    // Some platforms does not allow to have samples to unset textures.
	// Create empty one which is bound when there's no texture specified.
	gl.dummyTex = glnvg__renderCreateTexture(gl, .NVG_TEXTURE_ALPHA, 1, 1, 0, null);

    glnvg__checkError(gl, "create done");

    glFinish();

    return true;
}

glnvg__renderCreateTexture :: (uptr: *void, type: NVGtexture, w: s32, h: s32, imageFlags: NVGimageFlags, data: *u8) -> s32 {
    gl := cast(*GLNVGcontext) uptr;
    tex := glnvg__allocTexture(gl);

    if (tex == null) {
        return 0;
    }

    uw := cast(u32) w;
    uh := cast(u32) h;

    #if NANOVG_GLES2 {
        // Check for non-power of 2.
        if (glnvg__nearestPow2(uw) != uw || glnvg__nearestPow2(uh) != uh) {
            // No repeat
            if ((imageFlags & .NVG_IMAGE_REPEATX) != 0 || (imageFlags & .NVG_IMAGE_REPEATY) != 0) {
                print("Repeat X/Y is not supported for non power-of-two textures (% x %)\n", w, h);
                imageFlags &= ~(NVGimageFlags.NVG_IMAGE_REPEATX | .NVG_IMAGE_REPEATY);
            }
            // No mips.
            if (imageFlags & .NVG_IMAGE_GENERATE_MIPMAPS) {
                print("Mip-maps is not support for non power-of-two textures (% x %)\n", w, h);
                imageFlags &= ~.NVG_IMAGE_GENERATE_MIPMAPS;
            }
        }
    }

    glGenTextures(1, *tex.tex);
    tex.width = w;
    tex.height = h;
    tex.type = type;
    tex.flags = imageFlags;
    glnvg__bindTexture(gl, tex.tex);

    glPixelStorei(GL_UNPACK_ALIGNMENT,1);
    #if !NANOVG_GLES2 {
        glPixelStorei(GL_UNPACK_ROW_LENGTH, tex.width);
        glPixelStorei(GL_UNPACK_SKIP_PIXELS, 0);
        glPixelStorei(GL_UNPACK_SKIP_ROWS, 0);
    }

    #if NANOVG_GL2 {
        // GL 1.4 and later has support for generating mipmaps using a tex parameter.
    	if (imageFlags & .NVG_IMAGE_GENERATE_MIPMAPS) {
            glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, 1);
        }
    }

    if (type == .NVG_TEXTURE_RGBA) {
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, uw, uh, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
    } else {
        #if NANOVG_GLES2 || NANOVG_GL2 {
    		glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, uw, uh, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, data);
        } else if NANOVG_GLES3 {
            glTexImage2D(GL_TEXTURE_2D, 0, GL_R8, uw, uh, 0, GL_RED, GL_UNSIGNED_BYTE, data);
        } else {
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, uw, uh, 0, GL_RED, GL_UNSIGNED_BYTE, data);
        }
    }

    if (imageFlags & .NVG_IMAGE_GENERATE_MIPMAPS) {
        if (imageFlags & .NVG_IMAGE_NEAREST) {
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_NEAREST);
        } else {
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
        }
    } else {
        if (imageFlags & .NVG_IMAGE_NEAREST) {
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        } else {
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        }
    }

    if (imageFlags & .NVG_IMAGE_NEAREST) {
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    } else {
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    }

    if (imageFlags & .NVG_IMAGE_REPEATX) {
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    } else {
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    }

    if (imageFlags & .NVG_IMAGE_REPEATY) {
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    } else {
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }

    glPixelStorei(GL_UNPACK_ALIGNMENT, 4);
    #if !NANOVG_GLES2 {
        glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
        glPixelStorei(GL_UNPACK_SKIP_PIXELS, 0);
        glPixelStorei(GL_UNPACK_SKIP_ROWS, 0);
    }

    #if !NANOVG_GL2 {
        // The new way to build mipmaps on GLES and GL3
        if (imageFlags & .NVG_IMAGE_GENERATE_MIPMAPS) {
            glGenerateMipmap(GL_TEXTURE_2D);
        }
    }

    glnvg__checkError(gl, "create tex");
    glnvg__bindTexture(gl, 0);

    return tex.id;
}

glnvg__renderDeleteTexture :: (uptr: *void, image: s32) -> bool {
    gl := cast(*GLNVGcontext) uptr;
    return glnvg__deleteTexture(gl, image);
}

glnvg__renderUpdateTexture :: (uptr: *void, image: s32, x: s32, y: s32, w: s32, h: s32, data: *u8) -> bool {
    gl := cast(*GLNVGcontext) uptr;

    tex := glnvg__findTexture(gl, image);
    if (tex == null) {
        return false;
    }
    glnvg__bindTexture(gl, tex.tex);

    uw := cast(u32) w;
    uh := cast(u32) h;

    glPixelStorei(GL_UNPACK_ALIGNMENT,1);

    #if !NANOVG_GLES2 {
        glPixelStorei(GL_UNPACK_ROW_LENGTH, tex.width);
        glPixelStorei(GL_UNPACK_SKIP_PIXELS, x);
        glPixelStorei(GL_UNPACK_SKIP_ROWS, y);
    } else {
        // No support for all of skip, need to update a whole row at a time.
        if (tex.type == .NVG_TEXTURE_RGBA) {
            data += y*tex.width*4;
        } else {
            data += y*tex.width;
        }
        x = 0;
        w = tex.width;
    }

    if (tex.type == .NVG_TEXTURE_RGBA) {
        glTexSubImage2D(GL_TEXTURE_2D, 0, x, y, uw, uh, GL_RGBA, GL_UNSIGNED_BYTE, data);
    } else {
        #if NANOVG_GLES2 || NANOVG_GL2 {
		    glTexSubImage2D(GL_TEXTURE_2D, 0, x, y, uw, uh, GL_LUMINANCE, GL_UNSIGNED_BYTE, data);
        } else {
		    glTexSubImage2D(GL_TEXTURE_2D, 0, x, y, uw, uh, GL_RED, GL_UNSIGNED_BYTE, data);
        }
    }

    glPixelStorei(GL_UNPACK_ALIGNMENT, 4);
    #if !NANOVG_GLES2 {
        glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
        glPixelStorei(GL_UNPACK_SKIP_PIXELS, 0);
        glPixelStorei(GL_UNPACK_SKIP_ROWS, 0);
    }

    glnvg__bindTexture(gl, 0);

    return true;
}

glnvg__renderGetTextureSize :: (uptr: *void, image: s32, w: *s32, h: *s32) -> bool {
    gl := cast(*GLNVGcontext) uptr;
    tex := glnvg__findTexture(gl, image);
    if (tex == null) {
        return false;
    }
    <<w = tex.width;
    <<h = tex.height;
    return true;
}

glnvg__xformToMat3x4 :: (r: [] f32, t: [] f32) {
    r[0] = t[0];
    r[1] = t[1];
    r[2] = 0.0;
    r[3] = 0.0;
    r[4] = t[2];
    r[5] = t[3];
    r[6] = 0.0;
    r[7] = 0.0;
    r[8] = t[4];
    r[9] = t[5];
    r[10] = 1.0;
    r[11] = 0.0;
}

glnvg__premulColor :: (c: NVGcolor) -> NVGcolor {
    r: NVGcolor = c;
    r.r *= r.a;
    r.g *= r.a;
    r.b *= r.a;
    return r;
}

glnvg__convertPaint :: (gl: *GLNVGcontext, frag: *GLNVGfragUniforms, paint: *NVGpaint,
                        scissor: *NVGscissor, width: f32, fringe: f32, strokeThr: f32) -> bool
{
    tex: *GLNVGtexture = null;
    invxform: [6] f32;

    memoryClear(frag);

    frag.innerCol = glnvg__premulColor(paint.innerColor);
    frag.outerCol = glnvg__premulColor(paint.outerColor);

    if (scissor.extent[0] < -0.5 || scissor.extent[1] < -0.5) {
        frag.scissorExt[0] = 1.0;
        frag.scissorExt[1] = 1.0;
        frag.scissorScale[0] = 1.0;
        frag.scissorScale[1] = 1.0;
    } else {
        nvgTransformInverse(invxform, scissor.xform);
        glnvg__xformToMat3x4(frag.scissorMat, invxform);
        frag.scissorExt[0] = scissor.extent[0];
        frag.scissorExt[1] = scissor.extent[1];
        frag.scissorScale[0] = sqrtf(scissor.xform[0] * scissor.xform[0] + scissor.xform[2] * scissor.xform[2]) / fringe;
        frag.scissorScale[1] = sqrtf(scissor.xform[1] * scissor.xform[1] + scissor.xform[3] * scissor.xform[3]) / fringe;
    }

    arrayCopy(paint.extent, frag.extent, 2);

    frag.strokeMult = (width * 0.5 + fringe * 0.5) / fringe;
    frag.strokeThr = strokeThr;

    if (paint.image != 0) {
        tex = glnvg__findTexture(gl, paint.image);
        if (tex == null) {
            return false;
        }
        if (tex.flags & .NVG_IMAGE_FLIPY) {
            m1, m2: [6] f32;
            nvgTransformTranslate(m1, 0.0, frag.extent[1] * 0.5);
            nvgTransformMultiply(m1, paint.xform);
            nvgTransformScale(m2, 1.0, -1.0);
            nvgTransformMultiply(m2, m1);
            nvgTransformTranslate(m1, 0.0, -frag.extent[1] * 0.5);
            nvgTransformMultiply(m1, m2);
            nvgTransformInverse(invxform, m1);
        } else {
            nvgTransformInverse(invxform, paint.xform);
        }

        #if NANOVG_GL_USE_UNIFORMBUFFER {
            frag.type = .NSVG_SHADER_FILLIMG;
            if (tex.type == .NVG_TEXTURE_RGBA) {
                frag.texType = cast(s32) (ifx (tex.flags & .NVG_IMAGE_PREMULTIPLIED) then 0 else 1);
            } else {
                frag.texType = 2;
            }
        } else {
            frag.type = cast(f32) GLNVGshaderType.NSVG_SHADER_FILLIMG;
            if (tex.type == .NVG_TEXTURE_RGBA) {
                frag.texType = ifx (tex.flags & .NVG_IMAGE_PREMULTIPLIED) then 0.0 else 1.0;
            } else {
                frag.texType = 2.0;
            }
        }
    } else {
        #if NANOVG_GL_USE_UNIFORMBUFFER {
            frag.type = .NSVG_SHADER_FILLGRAD;
        } else {
            frag.type = cast(f32) GLNVGshaderType.NSVG_SHADER_FILLGRAD;
        }
        frag.radius = paint.radius;
        frag.feather = paint.feather;
        nvgTransformInverse(invxform, paint.xform);
    }

    glnvg__xformToMat3x4(frag.paintMat, invxform);

    return true;
}

glnvg__setUniforms :: (gl: *GLNVGcontext, uniformOffset: s32, image: s32) {
    #if NANOVG_GL_USE_UNIFORMBUFFER {
        glBindBufferRange(GL_UNIFORM_BUFFER, cast(u32) GLNVGuniformBindings.GLNVG_FRAG_BINDING, gl.fragBuf, uniformOffset, size_of(GLNVGfragUniforms));
    } else {
        frag := nvg__fragUniformPtr(gl, uniformOffset);
        glUniform4fv(gl.shader.loc[GLNVGuniformLoc.GLNVG_LOC_FRAG], NANOVG_GL_UNIFORMARRAY_SIZE, *(frag.uniformArray[0][0]));
    }

	tex: *GLNVGtexture = null;

    if (image != 0) {
		tex = glnvg__findTexture(gl, image);
	}
	// If no image is set, use empty texture
	if (tex == null) {
		tex = glnvg__findTexture(gl, gl.dummyTex);
	}
	glnvg__bindTexture(gl, ifx tex != null then tex.tex else 0);
	glnvg__checkError(gl, "tex paint tex");
}

glnvg__renderViewport :: (uptr: *void, width: f32, height: f32, devicePixelRatio: f32) {
    gl := cast(*GLNVGcontext) uptr;
    gl.view[0] = width;
    gl.view[1] = height;
}

glnvg__fill :: (gl: *GLNVGcontext, call: *GLNVGcall) {
    paths := ref(*gl.paths, call.pathOffset);
    npaths := call.pathCount;

    // Draw shapes
    glEnable(GL_STENCIL_TEST);
    glnvg__stencilMask(gl, 0xff);
    glnvg__stencilFunc(gl, GL_ALWAYS, 0, 0xff);
    glColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE);

    // set bindpoint for solid loc
    glnvg__setUniforms(gl, call.uniformOffset, 0);
    glnvg__checkError(gl, "fill simple");

    glStencilOpSeparate(GL_FRONT, GL_KEEP, GL_KEEP, GL_INCR_WRAP);
    glStencilOpSeparate(GL_BACK, GL_KEEP, GL_KEEP, GL_DECR_WRAP);
    glDisable(GL_CULL_FACE);
    for i : 0..npaths-1 {
        glDrawArrays(GL_TRIANGLE_FAN, paths[i].fillOffset, cast(GLsizei) paths[i].fillCount);
    }
    glEnable(GL_CULL_FACE);

    // Draw anti-aliased pixels
    glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);

    glnvg__setUniforms(gl, call.uniformOffset + gl.fragSize, call.image);
    glnvg__checkError(gl, "fill fill");

    if (gl.flags & .NVG_ANTIALIAS) {
        glnvg__stencilFunc(gl, GL_EQUAL, 0x00, 0xff);
        glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP);
        // Draw fringes
        for i : 0..npaths-1 {
            glDrawArrays(GL_TRIANGLE_STRIP, paths[i].strokeOffset, cast(GLsizei) paths[i].strokeCount);
        }
    }

    // Draw fill
    glnvg__stencilFunc(gl, GL_NOTEQUAL, 0x0, 0xff);
    glStencilOp(GL_ZERO, GL_ZERO, GL_ZERO);
    glDrawArrays(GL_TRIANGLE_STRIP, call.triangleOffset, cast(GLsizei) call.triangleCount);

    glDisable(GL_STENCIL_TEST);
}

glnvg__convexFill :: (gl: *GLNVGcontext, call: *GLNVGcall) {
    paths := ref(*gl.paths, call.pathOffset);
    npaths := call.pathCount;

    glnvg__setUniforms(gl, call.uniformOffset, call.image);
    glnvg__checkError(gl, "convex fill");

    for i : 0..npaths-1 {
        glDrawArrays(GL_TRIANGLE_FAN, paths[i].fillOffset, cast(GLsizei) paths[i].fillCount);
        // Draw fringes
        if (paths[i].strokeCount > 0) {
            glDrawArrays(GL_TRIANGLE_STRIP, paths[i].strokeOffset, cast(GLsizei) paths[i].strokeCount);
        }
    }
}

glnvg__stroke :: (gl: *GLNVGcontext, call: *GLNVGcall) {
    paths := ref(*gl.paths, call.pathOffset);
    npaths := call.pathCount;

    if (gl.flags & .NVG_STENCIL_STROKES) {
        glEnable(GL_STENCIL_TEST);
        glnvg__stencilMask(gl, 0xff);

        // Fill the stroke base without overlap
        glnvg__stencilFunc(gl, GL_EQUAL, 0x0, 0xff);
        glStencilOp(GL_KEEP, GL_KEEP, GL_INCR);
        glnvg__setUniforms(gl, call.uniformOffset + gl.fragSize, call.image);
        glnvg__checkError(gl, "stroke fill 0");
        for i : 0..npaths-1 {
            glDrawArrays(GL_TRIANGLE_STRIP, paths[i].strokeOffset, cast(GLsizei) paths[i].strokeCount);
        }

        // Draw anti-aliased pixels.
        glnvg__setUniforms(gl, call.uniformOffset, call.image);
        glnvg__stencilFunc(gl, GL_EQUAL, 0x00, 0xff);
        glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP);
        for i : 0..npaths-1 {
            glDrawArrays(GL_TRIANGLE_STRIP, paths[i].strokeOffset, cast(GLsizei) paths[i].strokeCount);
        }

        // Clear stencil buffer.
        glColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE);
        glnvg__stencilFunc(gl, GL_ALWAYS, 0x0, 0xff);
        glStencilOp(GL_ZERO, GL_ZERO, GL_ZERO);
        glnvg__checkError(gl, "stroke fill 1");
        for i : 0..npaths-1 {
            glDrawArrays(GL_TRIANGLE_STRIP, paths[i].strokeOffset, cast(GLsizei) paths[i].strokeCount);
        }
        glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);

        glDisable(GL_STENCIL_TEST);

        // glnvg__convertPaint(gl, nvg__fragUniformPtr(gl, call.uniformOffset + gl.fragSize), paint, scissor, strokeWidth, fringe, 1.0 - 0.5/255.0);
    } else {
        glnvg__setUniforms(gl, call.uniformOffset, call.image);
        glnvg__checkError(gl, "stroke fill");
        // Draw Strokes
        for i : 0..npaths-1 {
            glDrawArrays(GL_TRIANGLE_STRIP, paths[i].strokeOffset, cast(GLsizei) paths[i].strokeCount);
        }
    }
}

glnvg__triangles :: (gl: *GLNVGcontext, call: *GLNVGcall) {
    glnvg__setUniforms(gl, call.uniformOffset, call.image);
    glnvg__checkError(gl, "triangles fill");

    glDrawArrays(GL_TRIANGLES, call.triangleOffset, cast(GLsizei) call.triangleCount);
}

glnvg__renderCancel :: (uptr: *void) {
    gl := cast(*GLNVGcontext) uptr;
    clear(*gl.verts);
    clear(*gl.paths);
    clear(*gl.calls);
    gl.nuniforms = 0;
}

glnvg_convertBlendFuncFactor :: (factor: NVGblendFactor) -> GLenum {
    if factor == {
        case .NVG_ZERO;                return GL_ZERO;
        case .NVG_ONE;                 return GL_ONE;
        case .NVG_SRC_COLOR;           return GL_SRC_COLOR;
        case .NVG_ONE_MINUS_SRC_COLOR; return GL_ONE_MINUS_SRC_COLOR;
        case .NVG_DST_COLOR;           return GL_DST_COLOR;
        case .NVG_ONE_MINUS_DST_COLOR; return GL_ONE_MINUS_DST_COLOR;
        case .NVG_SRC_ALPHA;           return GL_SRC_ALPHA;
        case .NVG_ONE_MINUS_SRC_ALPHA; return GL_ONE_MINUS_SRC_ALPHA;
        case .NVG_DST_ALPHA;           return GL_DST_ALPHA;
        case .NVG_ONE_MINUS_DST_ALPHA; return GL_ONE_MINUS_DST_ALPHA;
        case .NVG_SRC_ALPHA_SATURATE;  return GL_SRC_ALPHA_SATURATE;
        case;                          return GL_INVALID_ENUM;
    }
}

glnvg__blendCompositeOperation :: (op: NVGcompositeOperationState) -> GLNVGblend {
    blend: GLNVGblend;
    blend.srcRGB = glnvg_convertBlendFuncFactor(op.srcRGB);
    blend.dstRGB = glnvg_convertBlendFuncFactor(op.dstRGB);
    blend.srcAlpha = glnvg_convertBlendFuncFactor(op.srcAlpha);
    blend.dstAlpha = glnvg_convertBlendFuncFactor(op.dstAlpha);
    if (blend.srcRGB == GL_INVALID_ENUM ||
        blend.dstRGB == GL_INVALID_ENUM ||
        blend.srcAlpha == GL_INVALID_ENUM ||
        blend.dstAlpha == GL_INVALID_ENUM)
    {
        blend.srcRGB = GL_ONE;
        blend.dstRGB = GL_ONE_MINUS_SRC_ALPHA;
        blend.srcAlpha = GL_ONE;
        blend.dstAlpha = GL_ONE_MINUS_SRC_ALPHA;
    }
    return blend;
}

glnvg__renderFlush :: (uptr: *void) {
    gl := cast(*GLNVGcontext) uptr;

    if (gl.calls.count > 0) {
        // Setup require GL state.
        glUseProgram(gl.shader.prog);

        #if NVG_DISABLE_CULL_FACE {
            // disable cull face to support negative scaling with the sprite batch code
            glDisable(GL_CULL_FACE);
        } else {
            glEnable(GL_CULL_FACE);
            glCullFace(GL_BACK);
        }
        glFrontFace(GL_CCW);
        glEnable(GL_BLEND);
        glDisable(GL_DEPTH_TEST);
        glDisable(GL_SCISSOR_TEST);
        glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
        glStencilMask(0xffffffff);
        glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP);
        glStencilFunc(GL_ALWAYS, 0, 0xffffffff);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, 0);
        #if NANOVG_GL_USE_STATE_FILTER {
            gl.boundTexture = 0;
            gl.stencilMask = 0xffffffff;
            gl.stencilFunc = GL_ALWAYS;
            gl.stencilFuncRef = 0;
            gl.stencilFuncMask = 0xffffffff;
            gl.blendFunc.srcRGB = GL_INVALID_ENUM;
            gl.blendFunc.srcAlpha = GL_INVALID_ENUM;
            gl.blendFunc.dstRGB = GL_INVALID_ENUM;
            gl.blendFunc.dstAlpha = GL_INVALID_ENUM;
        }

        #if NANOVG_GL_USE_UNIFORMBUFFER {
            // Upload ubo for frag shaders
            glBindBuffer(GL_UNIFORM_BUFFER, gl.fragBuf);
            glBufferData(GL_UNIFORM_BUFFER, gl.nuniforms * gl.fragSize, gl.uniforms, GL_STREAM_DRAW);
        }

        // Upload vertex data
        #if NANOVG_GL3 {
            glBindVertexArray(gl.vertArr);
        }
        glBindBuffer(GL_ARRAY_BUFFER, gl.vertBuf);
        glBufferData(GL_ARRAY_BUFFER, gl.verts.count * size_of(NVGvertex), gl.verts.items, GL_STREAM_DRAW);
        glEnableVertexAttribArray(0);
        glEnableVertexAttribArray(1);
        glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, size_of(NVGvertex), null);
        glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, size_of(NVGvertex), cast(*void)(0 + 2 * size_of(float)));

        // Set view and texture just once per frame.
        glUniform1i(gl.shader.loc[GLNVGuniformLoc.GLNVG_LOC_TEX], 0);
        glUniform2fv(gl.shader.loc[GLNVGuniformLoc.GLNVG_LOC_VIEWSIZE], 1, gl.view.data);

        #if NANOVG_GL_USE_UNIFORMBUFFER {
            glBindBuffer(GL_UNIFORM_BUFFER, gl.fragBuf);
        }

        for * call : gl.calls {
            glnvg__blendFuncSeparate(gl, *call.blendFunc);
            if call.type == {
                case .GLNVG_FILL;       glnvg__fill(gl, call);
                case .GLNVG_CONVEXFILL; glnvg__convexFill(gl, call);
                case .GLNVG_STROKE;     glnvg__stroke(gl, call);
                case .GLNVG_TRIANGLES;  glnvg__triangles(gl, call);
            }
        }

        glDisableVertexAttribArray(0);
        glDisableVertexAttribArray(1);
        #if NANOVG_GL3 {
            glBindVertexArray(0);
        }
        #if !NVG_DISABLE_CULL_FACE {
            glDisable(GL_CULL_FACE);
        }
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        glUseProgram(0);
        glnvg__bindTexture(gl, 0);
    }

    // Reset calls
    clear(*gl.verts);
    clear(*gl.paths);
    clear(*gl.calls);
    gl.nuniforms = 0;
}

glnvg__maxVertCount :: (paths: *NVGpath, npaths: s32) -> s32 {
    count: s32 = 0;
    for i : 0..npaths-1 {
        count += paths[i].nfill;
        count += paths[i].nstroke;
    }
    return count;
}

glnvg__allocCall :: (gl: *GLNVGcontext) -> *GLNVGcall {
    ret := addNew(*gl.calls);
    memoryClear(ret);
    return ret;
}

glnvg__allocPaths :: (gl: *GLNVGcontext, n: s32) -> s32 {
    ensureCapacity(*gl.paths, gl.paths.count + n);
    return cast(s32) gl.paths.count;
}

glnvg__allocVerts :: (gl: *GLNVGcontext, n: s32) -> s32 {
    ensureCapacity(*gl.verts, gl.verts.count + n);
    return cast(s32) gl.verts.count;
}

glnvg__allocFragUniforms :: (gl: *GLNVGcontext, n: s32) -> s32 {
    ret: s32 = 0;
    structSize: s32 = gl.fragSize;
    if (gl.nuniforms + n > gl.cuniforms) {
        cuniforms := max(gl.nuniforms + n, 128) + gl.cuniforms / 2; // 1.5x Overallocate
        uniforms := realloc(gl.uniforms, structSize * cuniforms);
        if (uniforms == null) {
            return -1;
        }
        gl.uniforms = uniforms;
        gl.cuniforms = cuniforms;
    }
    ret = gl.nuniforms * structSize;
    gl.nuniforms += n;
    return ret;
}

nvg__fragUniformPtr :: (gl: *GLNVGcontext, i: s32) -> *GLNVGfragUniforms {
    return cast(*GLNVGfragUniforms)*gl.uniforms[i];
}

glnvg__vtx :: (x: f32, y: f32, u: f32, v: f32) -> NVGvertex {
    vtx: NVGvertex = ---;
    vtx.x = x;
    vtx.y = y;
    vtx.u = u;
    vtx.v = v;
    return vtx;
}

glnvg__rollbackLastCall :: (gl: *GLNVGcontext) {
    // We get here if call alloc was ok, but something else is not.
    // Roll back the last call to prevent drawing it.
    if (gl.calls.count > 0) {
        gl.calls.count -= 1;
    }
}

glnvg__renderFill :: (uptr: *void, paint: *NVGpaint, compositeOperation: NVGcompositeOperationState, scissor: *NVGscissor,
                      fringe: f32, bounds: [] f32, paths: *NVGpath, npaths: s32)
{
    gl := cast(*GLNVGcontext) uptr;

    call := glnvg__allocCall(gl);
    if (call == null) {
        return;
    }

    call.type = .GLNVG_FILL;
    call.triangleCount = 4;
    call.pathOffset = glnvg__allocPaths(gl, npaths);
    if (call.pathOffset == -1) {
        glnvg__rollbackLastCall(gl);
        return;
    }
    call.pathCount = npaths;
    call.image = paint.image;
    call.blendFunc = glnvg__blendCompositeOperation(compositeOperation);

    if (npaths == 1 && paths[0].convex) {
        call.type = .GLNVG_CONVEXFILL;
        call.triangleCount = 0;    // Bounding box fill quad not needed for convex fill
    }

    // Allocate vertices for all the paths.
    nverts := glnvg__maxVertCount(paths, npaths) + call.triangleCount;
    offset := glnvg__allocVerts(gl, nverts);
    if (offset == -1) {
        glnvg__rollbackLastCall(gl);
        return;
    }

    for i : 0..npaths-1 {
        copy := addNew(*gl.paths);
        memoryClear(copy);

        path := *paths[i];
        if (path.nfill > 0) {
            copy.fillOffset = offset;
            copy.fillCount = path.nfill;
            addRange(*gl.verts, path.fill, path.nfill);
            offset += path.nfill;
        }
        if (path.nstroke > 0) {
            copy.strokeOffset = offset;
            copy.strokeCount = path.nstroke;
            addRange(*gl.verts, path.stroke, path.nstroke);
            offset += path.nstroke;
        }
    }

    // Setup uniforms for draw calls
    if (call.type == .GLNVG_FILL) {
        // Quad
        call.triangleOffset = offset;
        add(*gl.verts, glnvg__vtx(bounds[2], bounds[3], 0.5, 1.0));
        add(*gl.verts, glnvg__vtx(bounds[2], bounds[1], 0.5, 1.0));
        add(*gl.verts, glnvg__vtx(bounds[0], bounds[3], 0.5, 1.0));
        add(*gl.verts, glnvg__vtx(bounds[0], bounds[1], 0.5, 1.0));

        call.uniformOffset = glnvg__allocFragUniforms(gl, 2);
        if (call.uniformOffset == -1) {
            glnvg__rollbackLastCall(gl);
            return;
        }
        // Simple shader for stencil
        frag := nvg__fragUniformPtr(gl, call.uniformOffset);
        memoryClear(frag);
        frag.strokeThr = -1.0;

        #if NANOVG_GL_USE_UNIFORMBUFFER {
            frag.type = .NSVG_SHADER_SIMPLE;
        } else {
            frag.type = cast(f32) GLNVGshaderType.NSVG_SHADER_SIMPLE;
        }

        // Fill shader
        glnvg__convertPaint(gl, nvg__fragUniformPtr(gl, call.uniformOffset + gl.fragSize), paint, scissor, fringe, fringe, -1.0);
    } else {
        call.uniformOffset = glnvg__allocFragUniforms(gl, 1);
        if (call.uniformOffset == -1) {
            glnvg__rollbackLastCall(gl);
            return;
        }
        // Fill shader
        glnvg__convertPaint(gl, nvg__fragUniformPtr(gl, call.uniformOffset), paint, scissor, fringe, fringe, -1.0);
    }
}

glnvg__renderStroke :: (uptr: *void, paint: *NVGpaint, compositeOperation: NVGcompositeOperationState, scissor: *NVGscissor,
                        fringe: f32, strokeWidth: f32, paths: *NVGpath, npaths: s32)
{
    gl := cast(*GLNVGcontext) uptr;

    call := glnvg__allocCall(gl);
    if (call == null) {
        return;
    }
    call.type = .GLNVG_STROKE;
    call.pathOffset = glnvg__allocPaths(gl, npaths);
    if (call.pathOffset == -1) {
        glnvg__rollbackLastCall(gl);
        return;
    }
    call.pathCount = npaths;
    call.image = paint.image;
    call.blendFunc = glnvg__blendCompositeOperation(compositeOperation);

    // Allocate vertices for all the paths.
    nverts := glnvg__maxVertCount(paths, npaths);
    offset := glnvg__allocVerts(gl, nverts);
    if (offset == -1) {
        glnvg__rollbackLastCall(gl);
        return;
    }

    for i : 0..npaths-1 {
        copy := addNew(*gl.paths);
        memoryClear(copy);

        path := *paths[i];
        if (path.nstroke) {
            copy.strokeOffset = offset;
            copy.strokeCount = path.nstroke;
            addRange(*gl.verts, path.stroke, path.nstroke);
            offset += path.nstroke;
        }
    }

    if (gl.flags & .NVG_STENCIL_STROKES) {
        // Fill shader
        call.uniformOffset = glnvg__allocFragUniforms(gl, 2);
        if (call.uniformOffset == -1) {
            glnvg__rollbackLastCall(gl);
            return;
        }

        glnvg__convertPaint(gl, nvg__fragUniformPtr(gl, call.uniformOffset), paint, scissor, strokeWidth, fringe, -1.0);
        glnvg__convertPaint(gl, nvg__fragUniformPtr(gl, call.uniformOffset + gl.fragSize), paint, scissor, strokeWidth, fringe, 1.0 - 0.5 / 255.0);

    } else {
        // Fill shader
        call.uniformOffset = glnvg__allocFragUniforms(gl, 1);
        if (call.uniformOffset == -1) {
            glnvg__rollbackLastCall(gl);
            return;
        }
        glnvg__convertPaint(gl, nvg__fragUniformPtr(gl, call.uniformOffset), paint, scissor, strokeWidth, fringe, -1.0);
    }
}

glnvg__renderTriangles :: (uptr: *void, paint: *NVGpaint, compositeOperation: NVGcompositeOperationState, scissor: *NVGscissor,
                           verts: *NVGvertex, nverts: s32)
{
    gl := cast(*GLNVGcontext) uptr;

    call := glnvg__allocCall(gl);
    if (call == null) {
        return;
    }
    call.type = .GLNVG_TRIANGLES;
    call.image = paint.image;
    call.blendFunc = glnvg__blendCompositeOperation(compositeOperation);

    // Allocate vertices for all the paths.
    call.triangleOffset = glnvg__allocVerts(gl, nverts);
    if (call.triangleOffset == -1) {
        glnvg__rollbackLastCall(gl);
        return;
    }
    call.triangleCount = nverts;

    addRange(*gl.verts, verts, nverts);

    // Fill shader
    call.uniformOffset = glnvg__allocFragUniforms(gl, 1);
    if (call.uniformOffset == -1) {
        glnvg__rollbackLastCall(gl);
        return;
    }
    frag := nvg__fragUniformPtr(gl, call.uniformOffset);
    glnvg__convertPaint(gl, frag, paint, scissor, 1.0, 1.0, -1.0);

    #if NANOVG_GL_USE_UNIFORMBUFFER {
        frag.type = .NSVG_SHADER_IMG;
    } else {
        frag.type = cast(f32) GLNVGshaderType.NSVG_SHADER_IMG;
    }
}

glnvg__renderDelete :: (uptr: *void) {
    gl := cast(*GLNVGcontext) uptr;
    if (gl == null) {
        return;
    }

    glnvg__deleteShader(*gl.shader);

    #if NANOVG_GL3 {
        #if NANOVG_GL_USE_UNIFORMBUFFER {
            if (gl.fragBuf != 0) {
                glDeleteBuffers(1, *gl.fragBuf);
            }
        }
        if (gl.vertArr != 0) {
		    glDeleteVertexArrays(1, *gl.vertArr);
        }
    }

    if (gl.vertBuf != 0) {
        glDeleteBuffers(1, *gl.vertBuf);
    }

    for * texture : gl.textures {
        if (texture.tex != 0 && (texture.flags & .NVG_IMAGE_NODELETE) == 0) {
            glDeleteTextures(1, *texture.tex);
        }
    }

    uninit(*gl.textures);

    uninit(*gl.paths);
    uninit(*gl.verts);
    uninit(*gl.calls);
    free(gl.uniforms);

    free(gl);
}