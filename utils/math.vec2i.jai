Vec2i :: struct {
    x, y: s32;
}

VEC2I_ZERO   :: Vec2i.{};
VEC2I_ONE    :: Vec2i.{ x = 1, y = 1 };
VEC2I_LEFT   :: Vec2i.{ x = -1, y = 0 };
VEC2I_UP     :: Vec2i.{ x = 0, x = -1 };
VEC2I_RIGHT  :: Vec2i.{ x = 1, y = 0 };
VEC2I_DOWN   :: Vec2i.{ x = 0, y = 1 };

vec2i :: inline (x: s32, y: s32) -> Vec2i {
    r: Vec2i = ---;
    r.x = x;
    r.y = y;
    return r;
}

vec2i :: inline (x: f32, y: f32) -> Vec2i {
    return vec2i(cast(s32) x, cast(s32) y);
}

vect2i :: inline (v: Vec2) -> Vec2i {
    return vec2i(cast(s32) v.x, cast(s32) v.y);
}

equals :: inline (v1: Vec2i, v2: Vec2i) -> bool {
    return v1.x == v2.x && v1.y == v2.y;
}

isZero :: inline (v: Vec2i) -> bool {
    return equals(v, VEC2I_ZERO);
}

lengthSqr :: inline (v: Vec2i) -> s32 {
    return v.x * v.x + v.y * v.y;
}

length :: inline (v: Vec2i) -> f32 {
    return sqrtf(cast(f32) lengthSqr(v));
}

distanceSqr :: inline (v1: Vec2i, v2: Vec2i) -> s32 {
    dx := v1.x - v2.x;
    dy := v1.y - v2.y;
    return dx * dx + dy * dy;
}

distance :: inline (v1: Vec2i, v2: Vec2i) -> f32 {
    return sqrtf(cast(f32) distanceSqr(v1, v2));
}

distanceInTiles :: inline (v1: Vec2i, v2: Vec2i) -> s32 {
    dx := v1.x - v2.x;
    dy := v1.y - v2.y;
    return max(abs(dx), abs(dy));
}

distanceManhattan :: inline (v1: Vec2i, v2: Vec2i) -> s32 {
    dx := v1.x - v2.x;
    dy := v1.y - v2.y;
    return abs(dx) + abs(dy);
}

operator == :: (v1: Vec2i, v2: Vec2i) -> bool {
    return equals(v1, v2);
}

operator != :: (v1: Vec2i, v2: Vec2i) -> bool {
    return !equals(v1, v2);
}

operator + :: (v1: Vec2i, v2: Vec2i) -> Vec2i {
    r: Vec2i = ---;
    r.x = v1.x + v2.x;
    r.y = v1.y + v2.y;
    return r;
}

operator + :: (v: Vec2i, x: s32) -> Vec2i #symetric {
    r: Vec2i = ---;
    r.x = v.x + x;
    r.y = v.y + x;
    return r;
}

operator + :: (v: Vec2i, x: f32) -> Vec2i #symetric {
    r: Vec2i = ---;
    r.x = v.x + cast(s32) x;
    r.y = v.y + cast(s32) x;
    return r;
}

operator - :: (v1: Vec2i, v2: Vec2i) -> Vec2i {
    r: Vec2i = ---;
    r.x = v1.x - v2.x;
    r.y = v1.y - v2.y;
    return r;
}

operator - :: (v: Vec2i, x: s32) -> Vec2i #symetric {
    r: Vec2i = ---;
    r.x = v.x - x;
    r.y = v.y - x;
    return r;
}

operator - :: (v: Vec2i, x: f32) -> Vec2i #symetric {
    r: Vec2i = ---;
    r.x = v.x - cast(s32) x;
    r.y = v.y - cast(s32) x;
    return r;
}

operator * :: (v1: Vec2i, v2: Vec2i) -> Vec2i {
    r: Vec2i = ---;
    r.x = v1.x * v2.x;
    r.y = v1.y * v2.y;
    return r;
}

operator * :: (v: Vec2i, x: s32) -> Vec2i #symetric {
    r: Vec2i = ---;
    r.x = v.x * x;
    r.y = v.y * x;
    return r;
}

operator * :: (v: Vec2i, x: f32) -> Vec2i #symetric {
    r: Vec2i = ---;
    r.x = v.x * cast(s32) x;
    r.y = v.y * cast(s32) x;
    return r;
}

operator / :: (v: Vec2i, x: s32) -> Vec2i {
    r: Vec2i = ---;
    r.x = v.x / x;
    r.y = v.y / x;
    return r;
}

operator / :: (v: Vec2i, x: f32) -> Vec2i {
    r: Vec2i = ---;
    r.x = v.x / cast(s32) x;
    r.y = v.y / cast(s32) x;
    return r;
}
