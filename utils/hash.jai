defaultHashFn :: ($T: Type) -> ((value: T) -> u64) {
    #assert(hasDefaultHash(T));
    #if #run isInteger(T) return defaultIntegerHash;
    else #if #run isBool(T) return defaultBoolHash;
    else #if #run isString(T) return defaultStringHash;
    else #if #run isEnum(T) return cast(T) getEnumDefaultValue(T);
    else return null;
}

#scope_file

hasDefaultHash :: ($T: Type) -> bool {
    ti := type_info(T);
    return ti.type == .INTEGER ||
           ti.type == .BOOL ||
           ti.type == .STRING;
}

defaultIntegerHash :: inline (value: s8) -> u64 {
    return fnv1a_64(cast(*u8) (*value), size_of(s8));
}

defaultIntegerHash :: inline (value: u8) -> u64 {
    return fnv1a_64(cast(*u8) (*value), size_of(u8));
}

defaultIntegerHash :: inline (value: s16) -> u64 {
    return fnv1a_64(cast(*u8) (*value), size_of(s16));
}

defaultIntegerHash :: inline (value: u16) -> u64 {
    return fnv1a_64(cast(*u8) (*value), size_of(u16));
}

defaultIntegerHash :: inline (value: s32) -> u64 {
    return fnv1a_64(cast(*u8) (*value), size_of(s32));
}

defaultIntegerHash :: inline (value: u32) -> u64 {
    return fnv1a_64(cast(*u8) (*value), size_of(u32));
}

defaultIntegerHash :: inline (value: s64) -> u64 {
    return fnv1a_64(cast(*u8) (*value), size_of(s64));
}

defaultIntegerHash :: inline (value: u64) -> u64 {
    return fnv1a_64(cast(*u8) (*value), size_of(u64));
}

defaultBoolHash :: inline (value: bool) -> u64 {
    value8 := ifx value then cast(u8) 1 else cast(u8) 0;
    return fnv1a_64(cast(*u8) (*value8), size_of(u8));
}

defaultStringHash :: inline (value: string) -> u64 {
    assert(value.data != null);
    return fnv1a_64(value.data, cast(u64) value.count);
}

// Fowler–Noll–Vo hash function
// https://en.wikipedia.org/wiki/Fowler%E2%80%93Noll%E2%80%93Vo_hash_function

fnv1_64 :: (data: *u8, count: u64) -> u64 {
    FNV_OFFSET : u64 : 0xcbf29ce484222325;
    FNV_PRIME : u64 : 0x00000100000001B3;

    hash := FNV_OFFSET;

    for i : 0..count-1 #no_abc {
        hash = hash * FNV_PRIME;
        hash = hash ^ data[i];
    }

    return hash;
}

fnv1a_64 :: (data: *u8, count: u64) -> u64 {
    FNV_OFFSET : u64 : 0xcbf29ce484222325;
    FNV_PRIME : u64 : 0x00000100000001B3;

    hash := FNV_OFFSET;

    for i : 0..count-1 #no_abc {
        hash = hash ^ data[i];
        hash = hash * FNV_PRIME;
    }

    return hash;
}
