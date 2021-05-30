FixedString :: struct {
    count: s64;
    capacity: s64;
    data: *u8;
}

createFixedString :: (length: s64) -> FixedString {
    assert(length > 0);

    fstr: FixedString = ---;
    fstr.count = 0;
    fstr.capacity = length;
    fstr.data = alloc(u8, length);
    return fstr;
}

appendr :: inline (fstr: *FixedString, c: u8) {
    insertAt(fstr, fstr.count, c);
}

append :: inline (fstr: *FixedString, str: string) {
    insertAt(fstr, fstr.count, str);
}

insertAt :: inline (fstr: *FixedString, index: s64, c: u8) {
    assert(fstr != null);
    assert(fstr.count + 1 <= fstr.capacity);
    assert(index >= 0 && index < fstr.capacity);

    memoryMove(fstr.data + index + 1, fstr.data + index, fstr.count - index);
    fstr.data[index] = c;
    fstr.count += 1;
}

insertAt :: inline (fstr: *FixedString, index: s64, str: string) {
    assert(fstr != null);
    assert(fstr.count + str.count <= fstr.capacity);
    assert(index >= 0 && index < fstr.capacity - str.count);

    memoryMove(fstr.data + index + str.count, fstr.data + index, fstr.count - index - str.count + 1);
    memoryCopy(fstr.data + index, str.data, str.count);
    fstr.count += str.count;
}

removeAt :: inline (fstr: *FixedString, index: s64, count: s64 = 1) {
    assert(fstr != null);
    assert(fstr.count > 0);
    assert(count >= 0);
    assert(index >= 0 && index + count <= fstr.count);

    memoryMove(fstr.data + index, fstr.data + index + count, fstr.count - index - count);
    fstr.count -= count;
}

clear :: inline (fstr: *FixedString) {
    assert(fstr != null);

    memorySet(fstr.data, 0, fstr.count);
    fstr.count = 0;
}

hasEnoughFor :: inline (fstr: *FixedString, count: s64) -> bool {
    assert(fstr != null);
    return count <= fstr.capacity - fstr.count;
}

toString :: inline (fstr: *FixedString) -> string {
    assert(fstr != null);

    str: string = ---;
    str.count = fstr.count;
    str.data = alloc(u8, fstr.count);
    memoryCopy(str.data, fstr.data, fstr.count);
    return str;
}
