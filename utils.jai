f32 :: float32;
f64 :: float64;

memoryCopy :: inline (dest: *$T, src: *T, count: s64 = 1) {
    assert(count >= 0);
    memcpy(dest, src, count * size_of(T));
}

memoryMove :: (dest: *$T, src: *T, count: s64 = 1) {
    assert(count >= 0);

    if (dest < src) {
        memoryCopy(dest, src, count);
    } else {
        count *= size_of(T);
        r := count % size_of(s32);
        while (r > 0) {
            <<(dest + count) = <<(src + count);
            r -= 1;
        }

        count -= count % size_of(s32);

        dest32 := cast(*s32)(dest + count);
        dest32 -= 1;

        src32 := cast(*s32)(src + count);
        src32 -= 1;

        while (count > 0) {
            <<dest32 = <<src32;
            dest32 -= 1;
            src32 -= 1;
            count -= size_of(s32);
        }
    }
}

memorySet :: inline (dest: *$T, value: u8, count: s64 = 1) {
    assert(count >= 0);
    memset(dest, value, count * size_of(T));
}

memoryCompare :: inline (a: *$T, b: *T, count: s64 = 1) -> s16 {
    assert(count >= 0);
    return memcmp(a, b, count * size_of(T));
}

alloc :: inline ($T: Type, count: s64 = 1, allocator: Allocator = null, $initialized: bool = true) -> *T {
    assert(count > 0);
    result := cast(*T) _alloc(count * size_of(T), allocator);

    #if initialized {
        ini :: initializer_of(T);

        #if ini {
            item := result;
            for 0..count-1 {
                inline ini(item);
                item += size_of(T);
            }
        } else {
            memorySet(result, 0, count);
        }
    }

    return result;
}

realloc :: inline (value: *$T, count: s64 = 1, oldCount: s64 = 1, allocator: Allocator = null) -> *T {
    return cast(*T) _realloc(cast(*void) value, count * size_of(T), oldCount * size_of(T), allocator);
}

allocArray :: ($T: Type, length: s64, allocator: Allocator = null, $initialized: bool = true) -> [] T {
    assert(length > 0);
    items := alloc(T, length, allocator, initialized);

    array: [] T = ---;
    array.count = length;
    array.data = items;

    return array;
}

freeArray :: inline (array: [] $T, allocator: Allocator = null) {
    _free(array.data, allocator);
}

reallocArray :: inline (array: *[] $T, newLength: s64, oldLength: s64, allocator: Allocator = null) {
    array.data = realloc(array.data, newLength, oldLength, allocator);
    array.count = newLength;
}

free :: inline (s: string, allocator: Allocator = null) {
    assert(s.data != null);
    _free(s.data, allocator);
}

free :: inline (p: *$T, allocator: Allocator = null) {
    assert(p != null);
    _free(cast(*void) p);
}

tempAllocator :: __temporary_allocator;

copy :: inline (src: [] $T, dst: [] T, count: s64) {
    copy(src, 0, dst, 0, count);
}

copy :: inline (src: [] $T, srcIdx: s64, dst: [] T, dstIdx: s64, count: s64) {
    assert(srcIdx >= 0 && srcIdx < src.count);
    assert(dstIdx >= 0 && dstIdx < dst.count);
    assert(count >= 0);
    assert(count <= src.count - srcIdx);
    assert(count <= dst.count - dstIdx);

    memoryCopy(dst.data + dstIdx, src.data + srcIdx, count);
}

clear :: inline (value: *$T) {
    assert(value != null);
    memorySet(value, 0);
}

clear :: inline (array: [] $T) {
    assert(array.data != null);
    memorySet(array.data, 0, array.count);
}

qsort :: inline (array: [] $T, compareFn: (T, T) -> s64) {
    qsort(array, 0, array.count - 1, compareFn);
}

qsort :: inline (array: [] $T, left: s64, right: s64, compareFn: (T, T) -> s64) {
    assert(left >= 0 && left < array.count);
    assert(right >= 0 && right < array.count);

    qsort(array.data, left, right, compareFn);
}

qsort :: inline (array: *$T, count: s64, compareFn: (T, T) -> s64) {
    qsort(array, 0, count - 1, compareFn);
}

qsort :: (array: *$T, left: s64, right: s64, compareFn: (T, T) -> s64) {
    assert(left >= 0 && right >= 0);
    assert(compareFn != null);

    if (left >= right) {
        return;
    }

    middle := left + (right - left) / 2;
    p := array[middle];

    i := left;
    j := right;

    while (true) {
        while (compareFn(array[i], p) < 0) { i += 1; }
        while (compareFn(array[j], p) > 0) { j -= 1; }

        if (i >= j) {
            break;
        }

        tmp := array[i];
        array[i] = array[j];
        array[j] = tmp;

        i += 1;
        j -= 1;
    }

    qsort(array, left, j, compareFn);
    qsort(array, j + 1, right, compareFn);
}

qsort :: inline (array: [] $T, byFn: (T) -> $R) {
    qsort(array, 0, array.count - 1, byFn);
}

qsort :: inline (array: [] $T, left: s64, right: s64, byFn: (T) -> $R) {
    assert(left >= 0 && left < array.count);
    assert(right >= 0 && right < array.count);

    qsort(array.data, left, right, byFn);
}

qsort :: inline (array: *$T, count: s64, byFn: (T) -> $R) {
    qsort(array, 0, count - 1, byFn);
}

qsort :: (array: *$T, left: s64, right: s64, byFn: (T) -> $R) {
    assert(left >= 0 && right >= 0);
    assert(byFn != null);

    if (left >= right) {
        return;
    }

    middle := left + (right - left) / 2;
    p := array[middle];
    by := byFn(p);

    i := left;
    j := right;

    while (true) {
        while (byFn(array[i]) < by) { i += 1; }
        while (byFn(array[j]) > by) { j -= 1; }

        if (i >= j) {
            break;
        }

        tmp := array[i];
        array[i] = array[j];
        array[j] = tmp;

        i += 1;
        j -= 1;
    }

    qsort(array, left, j, byFn);
    qsort(array, j + 1, right, byFn);
}

heapSort :: inline (array: [] $T, compareFn: (T, T) -> s64) {
    heapSort(array, 0, array.count - 1, compareFn);
}

heapSort :: inline (array: [] $T, left: s64, right: s64, compareFn: (T, T) -> s64) {
    assert(left >= 0 && left < array.count);
    assert(right >= 0 && right < array.count);

    heapSort(array.data, left, right, compareFn);
}

heapSort :: inline (array: *$T, count: s64, compareFn: (T, T) -> s64) {
    heapSort(array, 0, count - 1, compareFn);
}

heapSort :: (array: *$T, left: s64, right: s64, compareFn: (T, T) -> s64) {
    assert(left >= 0 && right >= 0);
    assert(compareFn != null);

    if (left >= right) {
        return;
    }

    options: BinaryHeapOptions(T);
    options.capacity = right - left + 1;
    options.compareFn = compareFn;

    heap: BinaryHeap(T);
    init(*heap, options);

    for i : left..right {
        push(*heap, array[i]);
    }

    i := 0;
    while (heap.count > 0) {
        array[left + i] = pop(*heap);
        i += 1;
    }

    free(*heap);
}

heapSort :: inline (array: [] $T, byFn: (T) -> $R) {
    heapSort(array, 0, array.count - 1, byFn);
}

heapSort :: inline (array: [] $T, left: s64, right: s64, byFn: (T) -> $R) {
    assert(left >= 0 && left < array.count);
    assert(right >= 0 && right < array.count);

    heapSort(array.data, left, right, byFn);
}

heapSort :: inline (array: *$T, count: s64, byFn: (T) -> $R) {
    heapSort(array, 0, count - 1, byFn);
}

heapSort :: inline (array: *$T, left: s64, right: s64, byFn: (T) -> $R) {
    assert(left >= 0 && right >= 0);
    assert(byFn != null);

    heapSort(array.data, left, right, (item1: T, item2: T) -> s32 {
        by1 := byFn(item1);
        by2 := byFn(item2);
        if (b1 < b2) return -1;
        if (b1 > b2) return 1;
        return 0;
    });
}

measure :: (message: string, code: Code, prev: Code = null, post: Code = null) #expand {
    print("--- Start % ---\n", message);
    #if prev {
        #insert prev;
    }
    start := getTime();
    #insert code;
    end := getTime();
    #if post {
        #insert post;
    }
    print("Time: % seconds\n", formatFloat(end - start, trailing_width=4));
    print("--- End % ---\n", message);
}

default :: inline ($type: Type) -> type {
    #if type == s8 return 0;
    #if type == u8 return 0;
    #if type == s16 return 0;
    #if type == u16 return 0;
    #if type == s32 return 0;
    #if type == u32 return 0;
    #if type == s64 return 0;
    #if type == u64 return 0;
    #if type == f32 return 0.0;
    #if type == f64 return 0.0;
    #if type == string return "";
    return null;
}

time_t :: s64;
time :: (destTime: *time_t) -> time_t #foreign crt;

FILE :: void;

SEEK_SET :: 0;
SEEK_CUR :: 1;
SEEK_END :: 2;

fopen :: (pathname: *u8, mode: *u8) -> *FILE #foreign crt;
fclose :: (stream: *FILE) -> s32 #foreign crt;
ftell :: (stream: *FILE) -> s64 #foreign crt;
fread :: (ptr: *void, size: s64, count: s64, stream: *FILE) -> s64 #foreign crt;
fwrite :: (ptr: *void, size: s64, count: s64, stream: *FILE) -> s64 #foreign crt;
fseek :: (stream: *FILE, offset: s64, whence: s32) -> s32 #foreign crt;

randomNext :: Random.random_get;
randomSeed :: (seed: s64) {
    Random.random_seed(cast(s32) seed);
}

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

getTime :: Basic.get_time;
assert :: Basic.assert;
print :: Basic.print;
sprint :: Basic.sprint;
formatFloat :: Basic.formatFloat;
FormatFloat :: Basic.FormatFloat;
exit :: Basic.exit;

strlen :: (str: *u8) -> s64 {
    len := 0;
    while (<<str != 0) {
        len += 1;
        str += 1;
    }
    return len;
}

strcmp :: (a: *u8, b: *u8) -> s32 #must {
    lena := strlen(a);
    lenb := strlen(b);

    for i : 0..min(lena, lenb)-1 {
        if a[i] > b[i] return 1;
        if a[i] < b[i] return -1;
    }
    if lena > lenb return 1;
    if lena < lenb return -1;
    return 0;
}

toString :: (cString: *u8) -> string {
    s: string = ---;
    s.data = cString;
    s.count = strlen(cString);
    return s;
}

toCString :: (s: string, allocator: Allocator = null) -> *u8 {
    result := alloc(u8, s.count + 1, allocator);
    memoryCopy(result, s.data, s.count);
    result[s.count] = 0;
    return result;
}

glCheckOpenGLVersion :: () {
    vendor := glGetString(GL_VENDOR);
    print("Vendor: %\n", toString(vendor));

    renderer := glGetString(GL_RENDERER);
    print("Renderer: %\n", toString(renderer));

    version := glGetString(GL_VERSION);
    print("Version: %\n", toString(version));

    glslVersion := glGetString(GL_SHADING_LANGUAGE_VERSION);
    print("GLSL Version: %\n", toString(glslVersion));

    extensions := glGetString(GL_EXTENSIONS);
    print("Extensions: %\n", toString(extensions));
}

glLoad :: (getProcAddress: GetProcAddressFunction = null) {
    gl_load(*gl, getProcAddress);
}

#scope_file

Basic :: #import "Basic";
_alloc :: Basic.alloc;
_realloc :: Basic.realloc;
_free :: Basic.free;
__temporary_allocator :: Basic.__temporary_allocator;

Random :: #import "Random";

#import "GL";

#if OS == .WINDOWS {
    crt :: #foreign_system_library "msvcrt";
} else if OS == .LINUX {
    crt :: #foreign_system_library "libc";
}
