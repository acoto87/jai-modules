sqrtf  :: (x: f32) -> f32 #foreign crt;
fmodf  :: (x: f32, divisor: f32) -> f32 #foreign crt;
sinf   :: (x: f32) -> f32 #foreign crt;
cosf   :: (x: f32) -> f32 #foreign crt;
tanf   :: (x: f32) -> f32 #foreign crt;
atan2f :: (a: f32, b: f32) -> f32 #foreign crt;
acosf  :: (x: f32) -> f32 #foreign crt;
ceilf  :: (x: f32) -> f32 #foreign crt;
expf   :: (x: f32) -> f32 #foreign crt;
pow    :: (x: f64, y: f64) -> f64 #foreign crt;
powf   :: inline (x: f32, y: f32) -> f32 {
    return cast,no_check(f32) pow(x, y);
}
floor :: (x: f64) -> f64 #foreign crt;
floorf :: (x: f32) -> f32 #foreign crt;

sign :: inline (x: s16) -> s16 { return cast(s16) (ifx x < 0 then -1 else 1); }
sign :: inline (x: s32) -> s32 { return cast(s32) (ifx x < 0 then -1 else 1); }
sign :: inline (x: s64) -> s64 { return cast(s64) (ifx x < 0 then -1 else 1); }
sign :: inline (x: f32) -> f32 { return cast(f32) (ifx x < 0 then -1 else 1); }
sign :: inline (x: f64) -> f64 { return cast(f64) (ifx x < 0 then -1 else 1); }

abs :: inline (x: s16) -> s16 { return ifx x < 0 then -x else x; }
abs :: inline (x: s32) -> s32 { return ifx x < 0 then -x else x; }
abs :: inline (x: s64) -> s64 { return ifx x < 0 then -x else x; }
abs :: inline (x: f32) -> f32 { return ifx x < 0 then -x else x; }
abs :: inline (x: f64) -> f64 { return ifx x < 0 then -x else x; }

min :: inline (a: s16, b: s16) -> s16 { return ifx a < b then a else b; }
min :: inline (a: s32, b: s32) -> s32 { return ifx a < b then a else b; }
min :: inline (a: s64, b: s64) -> s64 { return ifx a < b then a else b; }
min :: inline (a: f32, b: f32) -> f32 { return ifx a < b then a else b; }
min :: inline (a: f64, b: f64) -> f64 { return ifx a < b then a else b; }

max :: inline (a: s16, b: s16) -> s16 { return ifx a > b then a else b; }
max :: inline (a: s32, b: s32) -> s32 { return ifx a > b then a else b; }
max :: inline (a: s64, b: s64) -> s64 { return ifx a > b then a else b; }
max :: inline (a: f32, b: f32) -> f32 { return ifx a > b then a else b; }
max :: inline (a: f64, b: f64) -> f64 { return ifx a > b then a else b; }

clamp :: inline (x: s16, a: s16, b: s16) -> s16 { return max(min(x, b), a); }
clamp :: inline (x: s32, a: s32, b: s32) -> s32 { return max(min(x, b), a); }
clamp :: inline (x: s64, a: s64, b: s64) -> s64 { return max(min(x, b), a); }
clamp :: inline (x: f32, a: f32, b: f32) -> f32 { return max(min(x, b), a); }
clamp :: inline (x: f64, a: f64, b: f64) -> f64 { return max(min(x, b), a); }

TAU   :: Math.TAU;
TAU64 :: Math.TAU64;

PI    :: Math.PI;
PI64  :: Math.PI64;

F32_MIN        :: Math.FLOAT32_MIN;
F32_MAX        :: Math.FLOAT32_MAX;
F32_INFINITY   :: Math.FLOAT32_INFINITY;
F32_NAN        :: Math.FLOAT32_NAN;

F64_MIN        :: Math.FLOAT64_MIN;
F64_MAX        :: Math.FLOAT64_MAX;
F64_INFINITY   :: Math.FLOAT64_INFINITY;
F64_NAN        :: Math.FLOAT64_NAN;

S8_MIN  :: Math.S8_MIN;
S8_MAX  :: Math.S8_MAX;
U8_MAX  :: Math.U8_MAX;
S16_MIN :: Math.S16_MIN;
S16_MAX :: Math.S16_MAX;
U16_MAX :: Math.U16_MAX;
S32_MIN :: Math.S32_MIN;
S32_MAX :: Math.S32_MAX;
U32_MAX :: Math.U32_MAX;
S64_MIN :: Math.S64_MIN;
S64_MAX :: Math.S64_MAX;
U64_MAX :: Math.U64_MAX;

#scope_file

Math :: #import "Math";

#if OS == .WINDOWS {
    crt :: #foreign_system_library "msvcrt";
} else if OS == .LINUX {
    crt :: #foreign_system_library "libc";
}
