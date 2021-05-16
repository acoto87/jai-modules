EPSILON_FOR_EQUALITY :: 0.0001;

Vec2 :: struct {
    x, y: f32;
}

VEC2_ZERO   :: Vec2.{};
VEC2_ONE    :: Vec2.{ x = 1.0, y = 1.0 };
VEC2_LEFT   :: Vec2.{ x = -1.0, y = 0.0 };
VEC2_UP     :: Vec2.{ x = 0.0, x = -1.0 };
VEC2_RIGHT  :: Vec2.{ x = 1.0, y = 0.0 };
VEC2_DOWN   :: Vec2.{ x = 0.0, y = 1.0 };

EPSILON     : f32 : 0.0001;

vec2 :: inline (x: f32, y: f32) -> Vec2 {
    r: Vec2 = ---;
    r.x = x;
    r.y = y;
    return r;
}

vec2 :: inline (x: s32, y: s32) -> Vec2 {
    return vec2(cast(f32) x, cast(f32) y);
}

vect2 :: inline (v: Vec2i) -> Vec2 {
    return vec2i(cast(f32) v.x, cast(f32) v.y);
}

equals :: inline (v1: Vec2, v2: Vec2) -> bool {
    d := distance(v1, v2);
    return nearlyEquals(d, 0, EPSILON_FOR_EQUALITY);
}

isZero :: inline (v: Vec2) -> bool {
    return equals(v, VEC2_ZERO);
}

lengthSqr :: inline (v: Vec2) -> f32 {
    return v.x * v.x + v.y * v.y;
}

length :: inline (v: Vec2) -> f32 {
    return sqrtf(lengthSqr(v));
}

distanceSqr :: inline (v1: Vec2, v2: Vec2) -> f32 {
    dx := v1.x - v2.x;
    dy := v1.y - v2.y;
    return dx * dx + dy * dy;
}

distance :: inline (v1: Vec2, v2: Vec2) -> f32 {
    return sqrtf(distanceSqr(v1, v2));
}

distanceInTiles :: inline (v1: Vec2, v2: Vec2) -> s32 {
    dx := v1.x - v2.x;
    dy := v1.y - v2.y;
    return cast(s32) max(abs(dx), abs(dy));
}

distanceManhattan :: inline (v1: Vec2, v2: Vec2) -> s32 {
    dx := v1.x - v2.x;
    dy := v1.y - v2.y;
    return cast(s32) abs(dx) + cast(s32) abs(dy);
}

normalize :: inline (v: Vec2) -> Vec2 {
    len := length(v);
    return ifx len != 0 then (v / len) else VEC2_ZERO;
}

dot :: inline (v1: Vec2, v2: Vec2) -> f32 {
    return v1.x * v2.x + v1.y * v2.y;
}

operator == :: (v1: Vec2, v2: Vec2) -> bool {
    return equals(v1, v2);
}

operator != :: (v1: Vec2, v2: Vec2) -> bool {
    return !equals(v1, v2);
}

operator + :: (v1: Vec2, v2: Vec2) -> Vec2 {
    r: Vec2 = ---;
    r.x = v1.x + v2.x;
    r.y = v1.y + v2.y;
    return r;
}

operator + :: (v: Vec2, x: s32) -> Vec2 #symmetric {
    r: Vec2 = ---;
    r.x = v.x + x;
    r.y = v.y + x;
    return r;
}

operator + :: (v: Vec2, x: f32) -> Vec2 #symmetric {
    r: Vec2 = ---;
    r.x = v.x + x;
    r.y = v.y + x;
    return r;
}

operator - :: (v1: Vec2, v2: Vec2) -> Vec2 {
    r: Vec2 = ---;
    r.x = v1.x - v2.x;
    r.y = v1.y - v2.y;
    return r;
}

operator - :: (v: Vec2, x: s32) -> Vec2 #symmetric {
    r: Vec2 = ---;
    r.x = v.x - x;
    r.y = v.y - x;
    return r;
}

operator - :: (v: Vec2, x: f32) -> Vec2 #symmetric {
    r: Vec2 = ---;
    r.x = v.x - x;
    r.y = v.y - x;
    return r;
}

operator * :: (v1: Vec2, v2: Vec2) -> Vec2 {
    r: Vec2 = ---;
    r.x = v1.x * v2.x;
    r.y = v1.y * v2.y;
    return r;
}

operator * :: (v: Vec2, x: s32) -> Vec2 #symmetric {
    r: Vec2 = ---;
    r.x = v.x * x;
    r.y = v.y * x;
    return r;
}

operator * :: (v: Vec2, x: f32) -> Vec2 #symmetric {
    r: Vec2 = ---;
    r.x = v.x * x;
    r.y = v.y * x;
    return r;
}

operator / :: (v: Vec2, x: s32) -> Vec2 {
    r: Vec2 = ---;
    r.x = v.x / x;
    r.y = v.y / x;
    return r;
}

operator / :: (v: Vec2, x: f32) -> Vec2 {
    r: Vec2 = ---;
    r.x = v.x / x;
    r.y = v.y / x;
    return r;
}
