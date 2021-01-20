strlen :: (str: *u8) -> s64 {
    assert(str != null);

    len := 0;
    while (<<str != 0) {
        len += 1;
        str += 1;
    }
    return len;
}

strcmp :: (a: *u8, b: *u8) -> s32 #must {
    assert(a != null);
    assert(b != null);

    lena := strlen(a);
    lenb := strlen(b);

    for i : range(0, min(lena, lenb)) {
        if a[i] > b[i] return 1;
        if a[i] < b[i] return -1;
    }
    if lena > lenb return 1;
    if lena < lenb return -1;
    return 0;
}

strncmp :: (a: *u8, b: *u8, count: s64) -> s32 #must {
    assert(a != null);
    assert(b != null);

    lena := strlen(a);
    lenb := strlen(b);

    count = min(count, lena);
    count = min(count, lenb);

    for i : range(0, count) {
        if a[i] > b[i] return 1;
        if a[i] < b[i] return -1;
    }

    return 0;
}

strcpy :: (dst: *u8, src: *u8) {
    assert(dst != null);
    assert(src != null);

    while (<<src) {
        <<dst = <<src;
        src += 1;
        dst += 1;
    }
    <<dst = 0;
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

StringBuilder :: Basic.String_Builder;
freeBuffers :: Basic.free_buffers;
printToBuilder :: Basic.print_to_builder;
builderToString :: Basic.builder_to_string;

#scope_file

Basic :: #import "Basic";
