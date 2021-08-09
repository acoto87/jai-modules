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

getEnumCount :: inline ($T: Type) -> s64 {
    ti := type_info(T);
    assert(ti.type == .ENUM);
    return ti.values.count;
}

getEnumInternalType :: ($T: Type) -> Type {
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

getStructName :: ($T: Type) -> string {
    ti := type_info(T);
    assert(ti.type == .STRUCT);
    return ti.name;
}

isArray :: ($T: Type) -> bool {
    ti := type_info(T);
    return ti.type == .ARRAY;
}

isPointer :: ($T: Type) -> bool {
    ti := type_info(T);
    return ti.type == .POINTER;
}

createInstance :: ($T: Type, allocator: Allocator = null) -> T {
    item: T;
    #if #run isPointer(T) {
        info := type_info(T);
        runtime_size := info.pointer_to.runtime_size;
        item = cast(T) _alloc(runtime_size, allocator);
    }
    return item;
}

getRuntimeSize :: inline ($T: Type) -> s64 {
    ti := type_info(T);
    return ti.runtime_size;
}

default_of :: inline ($T: Type) -> T {
    item: T;
    return item;
}

align_of :: ($T: Type) -> s64 {
    d :: struct(T) {
        c: u8;
        m: T;
    }
    return offset_of(d, "m");
}

offset_of :: ($T: Type, name: string) -> s64 {
    ti := type_info(T);
    assert(ti.type == .STRUCT);
    for member : ti.members {
        if (member.name == name) {
            return member.offset_in_bytes;
        }
    }
    return -1;
}

#scope_file

Basic :: #import "Basic";
_alloc :: Basic.alloc;