isInteger :: ($T: Type) -> bool {
    ti := type_info(T);
    return ti.type == .INTEGER;
}

isFloat :: ($T: Type) -> bool {
    ti := type_info(T);
    return ti.type == .FLOAT;
}

isBool :: ($T: Type) -> bool {
    ti := type_info(T);
    return ti.type == .BOOL;
}

isString :: ($T: Type) -> bool {
    ti := type_info(T);
    return ti.type == .STRING;
}

isEnum :: ($T: Type) -> bool {
    ti := type_info(T);
    return ti.type == .ENUM;
}

isEnumFlags :: inline ($T: Type) -> bool {
    ti := type_info(T);
    return ti.type == .ENUM && (ti.enum_type_flags & .Is_Flags) == .Is_Flags;
}

getCount :: inline ($T: Type) -> s64 {
    ti := type_info(T);
    assert(ti.type == .ENUM);
    return ti.values.count;
}

getInternalType :: ($T: Type) -> Type {
    ti := type_info(T);
    assert(ti.type == .ENUM);
    if (ti.internal_type == type_info(s8)) return s8;
    else if (ti.internal_type == type_info(u8)) return u8;
    else if (ti.internal_type == type_info(s16)) return s16;
    else if (ti.internal_type == type_info(u16)) return u16;
    else if (ti.internal_type == type_info(s32)) return s32;
    else if (ti.internal_type == type_info(u32)) return u32;
    else if (ti.internal_type == type_info(s64)) return s64;
    else if (ti.internal_type == type_info(u64)) return u64;
    else {
        assert(false, "Enum type should be of integer type;");
        return u64;
    }
}

isStruct :: ($T: Type) -> bool {
    ti := type_info(T);
    return ti.type == .STRUCT;
}

isArray :: ($T: Type) -> bool {
    ti := type_info(T);
    return ti.type == .ARRAY;
}

default_of :: ($T: Type) -> T {
    #assert(canDetermineDefault(T));
    #if #run isInteger(T) return 0;
    else #if #run isFloat(T) return 0;
    else #if #run isBool(T) return false;
    else #if #run isString(T) return "";
    else #if #run isEnum(T) return cast(T) getEnumDefaultValue(T);
    else #if #run isStruct(T) return .{};
    else #if #run isArray(T) return .[];
    else return null;
}

#scope_file

canDetermineDefault :: ($T: Type) -> bool {
    ti := type_info(T);
    return ti.type == .INTEGER ||
           ti.type == .FLOAT ||
           ti.type == .BOOL ||
           ti.type == .STRING ||
           ti.type == .POINTER ||
           ti.type == .STRUCT ||
           ti.type == .ARRAY ||
           ti.type == .ENUM;;
}

getEnumDefaultValue :: ($T: Type) -> s64 {
    ti := type_info(T);
    assert(ti.type == .ENUM);
    return ifx ti.values.count > 0 then ti.values[0] else 0;
}
