defaultHashFn :: ($T: Type) -> ((value: T) -> s64) {
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

defaultIntegerHash :: (value: s8) -> s64 {
    return cast(s64) value;
}

defaultIntegerHash :: (value: u8) -> s64 {
    return cast(s64) value;
}

defaultIntegerHash :: (value: s16) -> s64 {
    return cast(s64) value;
}

defaultIntegerHash :: (value: u16) -> s64 {
    return cast(s64) value;
}

defaultIntegerHash :: (value: s32) -> s64 {
    return cast(s64) value;
}

defaultIntegerHash :: (value: u32) -> s64 {
    return cast(s64) value;
}

defaultIntegerHash :: (value: s64) -> s64 {
    return cast(s64) value;
}

defaultIntegerHash :: (value: u64) -> s64 {
    return cast,no_check(s64) value;
}

defaultBoolHash :: (value: bool) -> s64 {
    return ifx value then cast(s64) 1 else cast(s64) 0;
}

defaultStringHash :: (value: string) -> s64 {
    FNV_PRIME : s64 : 0x01000193;
    FNV_OFFSET : s64 : 0x811c9dc5;

    hash := FNV_OFFSET;
    for i : 0..value.count-1 {
        hash = (value[i] ^ hash) * FNV_PRIME;
    }

    return hash;
}

