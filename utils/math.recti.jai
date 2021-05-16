Recti :: struct {
    x, y: s32;
    w, h: s32;
}

RECTI_EMPTY :: Rect.{};

getTopLeft :: inline (r: Recti) -> Vec2i { return vec2i(r.x, r.y); }
getTopRight :: inline (r: Recti) -> Vec2i { return vec2i(r.x + r.w, r.y); }
getBottomLeft :: inline (r: Recti) -> Vec2i { return vec2i(r.x, r.y + r.h); }
getBottomRight :: inline (r: Recti) -> Vec2i { return vec2i(r.x + r.w, r.y + r.h); }
getCenter :: inline (r: Recti) -> Vec2i { return vec2i(r.x + r.w / 2, r.y + r.h / 2); }
getSize :: inline (r: Recti) -> Vec2i { return vec2i(r.w, r.h); }

recti :: inline (x: s32, y: s32, w: s32, h: s32) -> Recti {
    r: Recti = ---;
    r.x = x;
    r.y = y;
    r.w = w;
    r.h = h;
    return r;
}

recti :: inline (x: f32, y: f32, w: f32, h: f32) -> Recti {
    return recti(cast(s32) x, cast(s32) y, cast(s32) w, cast(s32) h);
}

rectip :: inline (x1: s32, y1: s32, x2: s32, y2: s32) -> Recti {
    return recti(min(x1, x2), min(y1, y2), abs(x1 - x2), abs(y1 - y2));
}

recti :: inline (pos: Vec2i, size: Vec2i) -> Recti {
    return recti(pos.x, pos.y, size.x, size.y);
}

recti :: inline (size: Vec2i) -> Recti {
    return recti(0.0, 0.0, size.x, size.y);
}

recti :: inline (r: Rect) -> Recti {
    return recti(r.x, r.y, r.w, r.h);
}

contains :: inline (r: Recti, x: s32, y: s32) -> bool {
    return x >= r.x && x <= r.x + r.w &&
           y >= r.y && y <= r.y + r.h;
}

contains :: inline (r: Recti, x: f32, y: f32) -> bool {
    return x >= r.x && x <= r.x + r.w &&
           y >= r.y && y <= r.y + r.h;
}

intersects :: inline (r1: Recti, r2: Recti) -> bool {
    return !(r1.x + r1.w < r2.x || r1.x > r2.x + r2.w ||
             r1.y + r1.h < r2.y || r1.y > r2.y + r2.h);
}

scale :: inline (r: Recti, s: f32) -> Recti {
    return recti(
        r.x * s,
        r.y * s,
        r.w * s,
        r.h * s
    );
}

translate :: inline (r: Recti, x: f32, y: f32) -> Recti {
    return recti(
        r.x + x,
        r.y + y,
        r.w,
        r.h
    );
}

expand :: inline (r: Recti, dx: f32, dy: f32) -> Recti {
    return recti(
        r.x - dx,
        r.y - dy,
        r.w + dx * 2,
        r.h + dy * 2
    );
}

getClosestPointOnRect :: (p: Vec2i, r: Recti) -> Vec2i {
    left := r.x;
    top := r.y;
    right := r.x + r.w - 1;
    bottom := r.y + r.h - 1;

    // top-left
    if (p.x < left && p.y < top) {
        return vec2i(left, top);
    }

    // top-center
    if (p.x >= left && p.x <= right && p.y < top) {
        return vec2i(p.x, top);
    }

    // top-right
    if (p.x > right && p.y < top) {
        return vec2i(right, top);
    }

    // middle-right
    if (p.x > right && p.y >= top && p.y <= bottom) {
        return vec2i(right, p.y);
    }

    // bottom-right
    if (p.x > right && p.y > bottom) {
        return vec2i(right, bottom);
    }

    // bottom-center
    if (p.x >= left && p.x <= right && p.y > bottom) {
        return vec2i(p.x, bottom);
    }

    // bottom-left
    if (p.x < left && p.y > bottom) {
        return vec2i(left, bottom);
    }

    // middle-left
    if (p.x < left && p.y >= top && p.y <= bottom) {
        return vec2i(left, p.y);
    }

    // the point is inside the rect
    return p;
}