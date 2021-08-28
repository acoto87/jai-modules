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

NanoVG_API :: enum {
    GL2;
    GL3;
    GLES2;
    GLES3;
}

#module_parameters (
    api := NanoVG_API.GL2,
    useStateFilter := true,
    disableCullFace := true
);

NANOVG_GL2 :: api == NanoVG_API.GL2;
NANOVG_GL3 :: api == NanoVG_API.GL3;
NANOVG_GLES2 :: api == NanoVG_API.GLES2;
NANOVG_GLES3 :: api == NanoVG_API.GLES3;

NANOVG_GL :: NANOVG_GL2 || NANOVG_GL3 || NANOVG_GLES2 || NANOVG_GLES3;
NANOVG_GL_USE_UNIFORMBUFFER :: NANOVG_GL3;

NANOVG_GL_USE_STATE_FILTER :: useStateFilter;
NVG_DISABLE_CULL_FACE :: disableCullFace;

#load "nanovg.jai";
#load "nanovg_ext.jai";

#if NANOVG_GL {
    #load "nanovg_gl.jai";
}
