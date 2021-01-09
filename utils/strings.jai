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

StringBuilder :: Basic.String_Builder;
freeBuffers :: Basic.free_buffers;
printToBuilder :: Basic.print_to_builder;
builderToString :: Basic.builder_to_string;

#scope_file

Basic :: #import "Basic";
