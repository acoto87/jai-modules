getCount :: inline ($enumType: Type) -> s64 {
    ti := type_info(enumType);
    return ti.values.count;
}

getInternalType :: ($enumType: Type) -> Type {
    ti := type_info(enumType);
    if (ti == type_info(s8)) return s8;
    else if (ti == type_info(s8)) return u8;
    else if (ti == type_info(s16)) return s16;
    else if (ti == type_info(s16)) return u16;
    else if (ti == type_info(s32)) return s32;
    else if (ti == type_info(s32)) return u32;
    else if (ti == type_info(s64)) return s64;
    else if (ti == type_info(s64)) return u64;
    else {
        assert(false, "Enum type should be of integer type;");
    }
}

EnumIterator :: struct(enumType: Type) {
}

EnumEntry :: struct(valueType: Type) {
    name: string;
    value: valueType;
}

iterate :: ($enumType: Type) -> EnumIterator(enumType) {
    iterator: EnumIterator(enumType);
    return iterator;
}

for_expansion :: (iterator: *$T/EnumIterator, body: Code, flags: For_Flags) #expand {
    #assert(!(flags & .REVERSE));
    #assert(!(flags & .POINTER));

    ti := type_info(T.enumType);
    for i : 0..ti.values.count-1 {
        entry: EnumEntry(T.enumType);
        entry.name = ti.names[i];
        entry.value = cast(T.enumType) ti.values[i];

        `it := entry;
        `it_index := i;

        #insert body;
    }
}
