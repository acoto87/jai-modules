hasFlags :: (value: $T, flags: T) -> bool {
    #assert(isEnumFlags(T));
    return (value & flags) == flags;
}

getEnumValueByName :: Reflection.get_enum_by_name;

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

#scope_file

 Reflection :: #import "Reflection";