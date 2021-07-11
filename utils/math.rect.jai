Rect :: struct {
    x, y: f32;
    w, h: f32;
}

RECT_EMPTY :: Rect.{};

getTopLeft :: inline (r: Rect) -> Vec2 { return vec2(r.x, r.y); }
getTopCenter :: inline (r: Rect) -> Vec2 { return vec2(r.x + r.w * 0.5, r.y); }
getTopRight :: inline (r: Rect) -> Vec2 { return vec2(r.x + r.w, r.y); }
getMiddleLeft :: inline (r: Rect) -> Vec2 { return vec2(r.x, r.y + r.h * 0.5); }
getMiddleCenter :: inline (r: Rect) -> Vec2 { return vec2(r.x + r.w * 0.5, r.y + r.h * 0.5); }
getMiddleRight :: inline (r: Rect) -> Vec2 { return vec2(r.x + r.w, r.y + r.h * 0.5); }
getBottomLeft :: inline (r: Rect) -> Vec2 { return vec2(r.x, r.y + r.h); }
getBottomCenter :: inline (r: Rect) -> Vec2 { return vec2(r.x + r.w * 0.5, r.y + r.h); }
getBottomRight :: inline (r: Rect) -> Vec2 { return vec2(r.x + r.w, r.y + r.h); }
getCenter :: inline (r: Rect) -> Vec2 { return vec2(r.x + r.w * 0.5, r.y + r.h * 0.5); }
getSize :: inline (r: Rect) -> Vec2 { return vec2(r.w, r.h); }

rect :: inline (x: f32, y: f32, w: f32, h: f32) -> Rect {
    r: Rect = ---;
    r.x = x;
    r.y = y;
    r.w = w;
    r.h = h;
    return r;
}

rect :: inline (x: s32, y: s32, w: s32, h: s32) -> Rect {
    return rect(cast(f32) x, cast(f32) y, cast(f32) w, cast(f32) h);
}

rectp :: inline (x1: f32, y1: f32, x2: f32, y2: f32) -> Rect {
    return rect(min(x1, x2), min(y1, y2), abs(x1 - x2), abs(y1 - y2));
}

rect :: inline (pos: Vec2, size: Vec2) -> Rect {
    return rect(pos.x, pos.y, size.x, size.y);
}

rect :: inline (size: Vec2) -> Rect {
    return rect(0.0, 0.0, size.x, size.y);
}

rect :: inline (r: Recti) -> Rect {
    return rect(r.x, r.y, r.w, r.h);
}

contains :: inline (r: Rect, x: f32, y: f32) -> bool {
    return x >= r.x && x <= r.x + r.w &&
           y >= r.y && y <= r.y + r.h;
}

contains :: inline (r: Rect, x: s32, y: s32) -> bool {
    return x >= r.x && x <= r.x + r.w &&
           y >= r.y && y <= r.y + r.h;
}

intersects :: inline (r1: Rect, r2: Rect) -> bool {
    return !(r1.x + r1.w < r2.x || r1.x > r2.x + r2.w ||
             r1.y + r1.h < r2.y || r1.y > r2.y + r2.h);
}

intersects :: inline (r: Rect, c: Circle) -> bool {
    xn := max(r.x, min(c.x, r.x + r.w));
    yn := max(r.y, min(c.y, r.y + r.h));
    dx := xn - c.x;
    dy := yn - c.y;
    return dx * dx + dy * dy <= c.r * c.r;
}

scale :: inline (r: Rect, s: f32) -> Rect {
    return rect(
        r.x * s,
        r.y * s,
        r.w * s,
        r.h * s
    );
}

translate :: inline (r: Rect, x: f32, y: f32) -> Rect {
    return rect(
        r.x + x,
        r.y + y,
        r.w,
        r.h
    );
}

expand :: inline (r: Rect, dx: f32, dy: f32) -> Rect {
    return rect(
        r.x - dx,
        r.y - dy,
        r.w + dx * 2,
        r.h + dy * 2
    );
}

getClosestPointOnRect :: (p: Vec2, r: Rect) -> Vec2 {
    left := r.x;
    top := r.y;
    right := r.x + r.w - 1;
    bottom := r.y + r.h - 1;

    // top-left
    if (p.x < left && p.y < top) {
        return vec2(left, top);
    }

    // top-center
    if (p.x >= left && p.x <= right && p.y < top) {
        return vec2(p.x, top);
    }

    // top-right
    if (p.x > right && p.y < top) {
        return vec2(right, top);
    }

    // middle-right
    if (p.x > right && p.y >= top && p.y <= bottom) {
        return vec2(right, p.y);
    }

    // bottom-right
    if (p.x > right && p.y > bottom) {
        return vec2(right, bottom);
    }

    // bottom-center
    if (p.x >= left && p.x <= right && p.y > bottom) {
        return vec2(p.x, bottom);
    }

    // bottom-left
    if (p.x < left && p.y > bottom) {
        return vec2(left, bottom);
    }

    // middle-left
    if (p.x < left && p.y >= top && p.y <= bottom) {
        return vec2(left, p.y);
    }

    // the point is inside the rect
    return p;
}