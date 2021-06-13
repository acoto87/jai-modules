isEnumFlags :: inline (type: Type) -> bool {
    return isEnumFlags(type_info(type));
}

isEnumFlags :: (ti: *Type_Info) -> bool {
    if (ti.type != .ENUM) {
        return false;
    }

    tie := cast(*Type_Info_Enum) ti;
    return (tie.enum_type_flags & .Is_Flags) == .Is_Flags;
}
