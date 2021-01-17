getCount :: inline ($enumType: Type) -> s64 {
    ti := type_info(WarFeatureType);
    return ti.values.count;
}

getInternalType :: ($enumType: Type) -> Type {
    ti := type_info(enumType);
    if ti.runtime_size == {
        case 1; return ifx ti.internal_type.signed then s8 else u8;
        case 2; return ifx ti.internal_type.signed then s16 else u16;
        case 4; return ifx ti.internal_type.signed then s32 else u32;
        case 8; return ifx ti.internal_type.signed then s64 else u64;
        case; return s64;
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

    getIterationCode :: ($enumType: Type, $intType: Type) -> string {
        codeStr := #string DONE
            ti := type_info(%1);
            count := ti.values.count;
            for i : 0..count-1 {
                entry: EnumEntry(%2);
                entry.name = ti.names[i];
                entry.value = cast(%2) ti.values[i];

                `it := entry;
                `it_index := i;

                #insert body;
            }
        DONE;

        enumTypeInfo := type_info(enumType);
        enumTypeName := enumTypeInfo.name;

        intTypeInfo := type_info(intType);
        intTypeName := "s64";

        if intTypeInfo == type_info(u8)   intTypeName = "u8";
        if intTypeInfo == type_info(u16)  intTypeName = "u16";
        if intTypeInfo == type_info(u32)  intTypeName = "u32";
        if intTypeInfo == type_info(u64)  intTypeName = "u64";
        if intTypeInfo == type_info(s8)   intTypeName = "s8";
        if intTypeInfo == type_info(s16)  intTypeName = "s16";
        if intTypeInfo == type_info(s32)  intTypeName = "s32";

        builder: StringBuilder;
        defer freeBuffers(*builder);
        printToBuilder(*builder, codeStr, enumTypeName, intTypeName);
        return builderToString(*builder);
    }

    internalType :: #run getInternalType(T.enumType);
    #insert #run getIterationCode(T.enumType, internalType);
}
