memoryCopy :: inline (dest: *$T, src: *T, count: s64 = 1) {
    assert(count >= 0);
    memcpy(dest, src, count * size_of(T));
}

memoryMove :: (dest: *$T, src: *T, count: s64 = 1) {
    assert(count >= 0);

    if (count == 0) {
        return;
    }

    if (dest < src) {
        memoryCopy(dest, src, count);
    } else {
        dest8 := cast(*u8) dest;
        src8 := cast(*u8) src;

        count *= size_of(T);
        r := count % size_of(s32);
        while (r > 0) {
            <<(dest8 + count) = <<(src8 + count);
            r -= 1;
            count -= 1;
        }

        dest32 := cast(*s32) (dest8 + count);
        dest32 -= 1;

        src32 := cast(*s32) (src8 + count);
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

memoryClear :: inline (value: *$T) {
    assert(value != null);
    memorySet(value, 0);
}

allocRaw :: _alloc;
reallocRaw :: _realloc;

alloc :: inline ($T: Type, count: s64 = 1, allocator: Allocator = null, $initialized: bool = true) -> *T {
    assert(count >= 0);

    result := cast(*T) _alloc(count * size_of(T), allocator);

    #if initialized {
        ini :: initializer_of(T);

        #if ini {
            item := result;
            for range(0, count) {
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
    assert(length >= 0);

    items := alloc(T, length, allocator, initialized);

    array: [] T = ---;
    array.count = length;
    array.data = items;

    return array;
}

reallocArray :: inline (array: *[] $T, newLength: s64, oldLength: s64, allocator: Allocator = null) {
    array.data = realloc(array.data, newLength, oldLength, allocator);
    array.count = newLength;
}

allocString :: inline (str: string, allocator: Allocator = null) -> string {
    return allocString(str.count, str, allocator);
}

allocString :: (length: s64, initStr: string = "", allocator: Allocator = null) -> string {
    assert(length >= 0);

    if (length == 0) {
        return "";
    }

    data := alloc(u8, length, allocator);

    if (!isEmpty(initStr)) {
        memoryCopy(data, initStr.data, min(length, initStr.count));
    }

    str: string = ---;
    str.count = length;
    str.data = data;

    return str;
}

reallocString :: inline (str: string, newLength: s64, oldLength: s64, allocator: Allocator = null) {
    str.data = realloc(str.data, newLength, oldLength, allocator);
    str.count = newLength;
}

free :: inline (array: [] $T, allocator: Allocator = null) {
    if (array.data != null) {
        _free(cast(*void) array.data, allocator);
    }
}

free :: inline (ptr: *$T, allocator: Allocator = null) {
    if (ptr != null) {
        _free(cast(*void) ptr);
    }
}

free :: inline (s: string, allocator: Allocator = null) {
    if (s.data != null) {
        _free(cast(*void) s.data, allocator);
    }
}

tempAllocator :: __temporary_allocator;

memoryRead :: ($type: Type, ptr: *void, index: s64, littleEndian: bool = true) -> type {
    size :: #run size_of(type);

    bytes := cast(*u8) ptr;
    start := bytes + index;

    result: type = 0;

    if (!littleEndian) {
        for i : range(0, size) {
            result |= (cast(type) (<<start)) << (8 * (size - i - 1));
            start += 1;
        }
    } else {
        for i : range(0, size) {
            result |= (cast(type) (<<start)) << (8 * i);
            start += 1;
        }
    }

    return result;
}

#scope_file

_alloc :: Basic.alloc;
_realloc :: Basic.realloc;
_free :: Basic.free;
__temporary_allocator :: Basic.__temporary_allocator;