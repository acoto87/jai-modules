defaultHash :: (value: $T) -> u64 {
    #if #run isInteger(T) return defaultIntegerHash(value);
    else #if #run isBool(T) return defaultBoolHash(value);
    else #if #run isString(T) return defaultStringHash(value);
    else #if #run isEnum(T) return defaultEnumHash(value);
    else return null;
}

#scope_file

defaultIntegerHash :: inline (value: s8) -> u64 {
    return cast(u64) value;
}

defaultIntegerHash :: inline (value: u8) -> u64 {
    return cast(u64) value;
}

defaultIntegerHash :: inline (value: s16) -> u64 {
    return cast(u64) value;
}

defaultIntegerHash :: inline (value: u16) -> u64 {
    return cast(u64) value;
}

defaultIntegerHash :: inline (value: s32) -> u64 {
    return cast(u64) value;
}

defaultIntegerHash :: inline (value: u32) -> u64 {
    return cast(u64) value;
}

defaultIntegerHash :: inline (value: s64) -> u64 {
    return cast(u64) value;
}

defaultIntegerHash :: inline (value: u64) -> u64 {
    return cast(u64) value;
}

defaultBoolHash :: inline (value: bool) -> u64 {
    return ifx value then 1 else 0;
}

defaultStringHash :: inline (value: string) -> u64 {
    return fnv1a_64(value.data, cast(u64) value.count);
}

defaultEnumHash :: inline (value: $T) -> u64 {
    return cast(u64) value;
}

// Fowler–Noll–Vo hash function
// https://en.wikipedia.org/wiki/Fowler%E2%80%93Noll%E2%80%93Vo_hash_function

fnv1_64 :: (data: *u8, count: u64) -> u64 {
    FNV_OFFSET : u64 : 0xcbf29ce484222325;
    FNV_PRIME : u64 : 0x00000100000001B3;

    if (count > 0) {
        assert(data != null);
    }

    hash := FNV_OFFSET;

    i: u64 = 0;
    while (i < count) {
        hash = hash * FNV_PRIME;
        hash = hash ^ data[i];
        i += 1;
    }

    return hash;
}

fnv1a_64 :: (data: *u8, count: u64) -> u64 {
    FNV_OFFSET : u64 : 0xcbf29ce484222325;
    FNV_PRIME : u64 : 0x00000100000001B3;

    if (count > 0) {
        assert(data != null);
    }

    hash := FNV_OFFSET;

    i: u64 = 0;
    while (i < count) {
        hash = hash ^ data[i];
        hash = hash * FNV_PRIME;
        i += 1;
    }

    return hash;
}
