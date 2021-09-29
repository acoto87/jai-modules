NVG_WHITE :: NVGcolor.{ r = 255, g = 255, b = 255, a = 255 };
NVG_BLACK :: NVGcolor.{ r = 0, g = 0, b = 0, a = 255 };
NVG_FOG :: NVGcolor.{ r = 0, g = 0, b = 0, a = 128 };
NVG_GRAY_TRANSPARENT :: NVGcolor.{ r = 128, g = 128, b = 128, a = 128 };
NVG_RED_TRANSPARENT :: NVGcolor.{ r = 128, g = 0, b = 0, a = 128 };
NVG_GREEN_SELECTION :: NVGcolor.{ r = 0, g = 199, b = 0, a = 255 };
NVG_RED_SELECTION :: NVGcolor.{ r = 199, g = 0, b = 0, a = 255 };
NVG_WHITE_SELECTION :: NVGcolor.{ r = 199, g = 199, b = 199, a = 255 };
NVG_BLUE_INVULNERABLE :: NVGcolor.{ r = 0, g = 0, b = 199, a = 255 };

NVGimageBatch :: struct {
    image: s32;              // the id of the source image
    cimages: s32;            // how many images are going to be rendered
    iw: s32;                 // width of the source image in pixels
    ih: s32;                 // height of the source image in pixels
    nvertices: s32;          // actual count of vertices
    cvertices: s32;          // total count of vertices
    vertices: *NVGvertex;    // the vertices
}

nvgBeginImageBatch :: (gfx: *NVGcontext, image: s32, cimages: s32) -> *NVGimageBatch {
    batch := alloc(NVGimageBatch);
    batch.image = image;
    batch.cimages = cimages;
    batch.nvertices = 0;
    batch.cvertices = cimages * 6;
    batch.vertices = alloc(NVGvertex, batch.cvertices);

    nvgImageSize(gfx, batch.image, *batch.iw, *batch.ih);

    return batch;
}

nvgRenderBatchImage :: (gfx: *NVGcontext, batch: *NVGimageBatch, rs: Rect, rd: Rect, scale: Vec2) {
    if (batch.nvertices + 6 > batch.cvertices) {
        logError("Can't print more images in this batch: (nvertices: %, cvertices: %)\n", batch.nvertices, batch.cvertices);
        return;
    }

    state := nvgGetState(gfx);

    // if the scale is (1.0, 1.0) then these transformations aren't necessary
    if (!equals(scale, VEC2_ONE)) {
        nvgTranslate(gfx, rd.w * 0.5, rd.h * 0.5);
        nvgScale(gfx, scale.x, scale.y);
        nvgTranslate(gfx, -rd.w * 0.5, -rd.h * 0.5);
    }

    // positions of the four vertices
    px := rd.x;
    py := rd.y;
    pw := rd.w;
    ph := rd.h;

    // tex-coords of the four vertices
    tx := rs.x / batch.iw;
    ty := rs.y / batch.ih;
    tw := rs.w / batch.iw;
    th := rs.h / batch.ih;

    pxs: [] f32 = array(f32, px, px,      px + pw, px + pw, px,      px + pw);
    pys: [] f32 = array(f32, py, py + ph, py,      py,      py + ph, py + ph);

    cxs: [] f32 = array(f32, tx, tx,      tx + tw, tx + tw, tx,      tx + tw);
    cys: [] f32 = array(f32, ty, ty + th, ty,      ty,      ty + th, ty + th);

    for i : range(s32, 0, 6) {
        vertex := *batch.vertices[batch.nvertices];
        x, y := nvgTransformPoint(state.xform, pxs[i], pys[i]);
        nvgVset(vertex, x, y, cxs[i], cys[i]);
        batch.nvertices += 1;
    }
}

nvgEndImageBatch :: (gfx: *NVGcontext, batch: *NVGimageBatch) {
    state := nvgGetState(gfx);
    paint := state.fill;

    paint.image = batch.image;
    paint.innerColor.a *= state.alpha;
    paint.outerColor.a *= state.alpha;

	gfx.params.renderTriangles(
        gfx.params.userPtr,
        *paint,
        state.compositeOperation,
        *state.scissor,
        batch.vertices,
        batch.nvertices);

	gfx.drawCallCount += 1;
	gfx.textTriCount += batch.nvertices/3;

    free(batch.vertices);
    free(batch);
}

nvgRenderSubImage :: (gfx: *NVGcontext, image: s32, rs: Rect, rd: Rect, scale: Vec2) {
    batch := nvgBeginImageBatch(gfx, image, 1);
    nvgRenderBatchImage(gfx, batch, rs, rd, scale);
    nvgEndImageBatch(gfx, batch);
}

nvgRenderImage :: (gfx: *NVGcontext, image: s32, rd: Rect, scale: Vec2) {
    rs := rect(0, 0, rd.w, rd.h);
    nvgRenderSubImage(gfx, image, rs, rd, scale);
}

nvgFillRect :: (gfx: *NVGcontext, r: Rect, color: NVGcolor) {
    nvgSave(gfx);
    nvgBeginPath(gfx);
    nvgRect(gfx, r.x, r.y, r.w, r.h);
    nvgFillColor(gfx, color);
    nvgFill(gfx);
    nvgRestore(gfx);
}

nvgFillRects :: (gfx: *NVGcontext, rects: [] Rect, color: NVGcolor) {
    nvgSave(gfx);
    nvgBeginPath(gfx);

    for r : rects {
        nvgRect(gfx, r.x, r.y, r.w, r.h);
    }

    nvgFillColor(gfx, color);
    nvgFill(gfx);
    nvgRestore(gfx);
}

nvgStrokeRect :: (gfx: *NVGcontext, r: Rect, color: NVGcolor, width: f32) {
    nvgSave(gfx);
    nvgBeginPath(gfx);
    nvgRect(gfx, r.x, r.y, r.w, r.h);
    nvgStrokeColor(gfx, color);
    nvgStrokeWidth(gfx, width);
    nvgStroke(gfx);
    nvgRestore(gfx);
}

nvgStrokeRects :: (gfx: *NVGcontext, rects: [] Rect, color: NVGcolor, width: f32) {
    nvgSave(gfx);
    nvgBeginPath(gfx);

    for r : rects {
        nvgRect(gfx, r.x, r.y, r.w, r.h);
    }

    nvgStrokeColor(gfx, color);
    nvgStrokeWidth(gfx, width);
    nvgStroke(gfx);
    nvgRestore(gfx);
}

nvgStrokeLine :: (gfx: *NVGcontext, p1: Vec2, p2: Vec2, color: NVGcolor, width: f32) {
    nvgSave(gfx);
    nvgBeginPath(gfx);
    nvgMoveTo(gfx, p1.x, p1.y);
    nvgLineTo(gfx, p2.x, p2.y);
    nvgStrokeColor(gfx, color);
    nvgStrokeWidth(gfx, width);
    nvgStroke(gfx);
    nvgRestore(gfx);
}

nvgStrokePolyline :: (gfx: *NVGcontext, points: [] Vec2, color: NVGcolor, width: f32) {
    if (points.count <= 1) {
        return;
    }

    nvgSave(gfx);
    nvgBeginPath(gfx);

    nvgMoveTo(gfx, points[0].x, points[0].y);
    for i : range(s32, 1, points.count) {
        nvgLineTo(gfx, points[i].x, points[i].y);
    }

    nvgStrokeColor(gfx, color);
    nvgStrokeWidth(gfx, width);
    nvgStroke(gfx);
    nvgRestore(gfx);
}

#scope_file
