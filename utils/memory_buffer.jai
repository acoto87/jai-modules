MEMORY_BUFFER_DEFAULT_CAPACITY :: 8;

MemoryBuffer :: struct {
    length: s64;
    data: *u8;
    allocator: Allocator;
    _capacity: s64;
    _pointer: *u8;
}

SeekType :: enum {
    Begin;
    End;
    Current;
}

StringStoreOptions :: enum {
    None;
    ZeroTerminated;
    PrependCount;
}

mbInitEmpty :: (buffer: *MemoryBuffer, allocator: Allocator = null) {
    buffer.data = alloc(u8, MEMORY_BUFFER_DEFAULT_CAPACITY);
    buffer.length = 0;
    buffer.allocator = allocator;
    buffer._capacity = MEMORY_BUFFER_DEFAULT_CAPACITY;
    buffer._pointer = buffer.data;
}

mbInitFromMemory :: (buffer: *MemoryBuffer, data: *u8, length: s64, allocator: Allocator = null) {
    assert(data != null);
    assert(length > 0);

    buffer.data = data;
    buffer.length = length;
    buffer._capacity = length;
    buffer._pointer = buffer.data;
    buffer.allocator = allocator;
}

mbFree :: (buffer: *MemoryBuffer) {
    if (buffer.data != null) {
        free(buffer.data);
    }

    buffer.data = null;
    buffer.length = 0;
    buffer._capacity = 0;
    buffer._pointer = null;
}

mbEnd :: inline (buffer: *MemoryBuffer) -> *u8 {
    return buffer.data + buffer.length;
}

mbPosition :: inline (buffer: *MemoryBuffer) -> s64 {
    return buffer._pointer - buffer.data;
}

mbGetData :: (buffer: *MemoryBuffer, length: *s64) -> *u8 {
    data := alloc(u8, buffer.length);
    memoryCopy(data, buffer.data, buffer.length);
    <<length = buffer.length;
    return data;
}

mbSeek :: (buffer: *MemoryBuffer, position: s64, seekType: SeekType = SeekType.Begin) -> bool {
    pointer: *u8;

    if seekType == {
        case SeekType.Begin; {
            if (position > buffer._capacity && !mb__realloc(buffer, position)) {
                return false;
            }

            buffer._pointer = buffer.data + position;
        }
        case SeekType.End; {
            if (position > buffer.length) {
                return false;
            }

            buffer._pointer = mbEnd(buffer) - position;
        }
        case SeekType.Current; {
            if (position < 0 && -position > mbPosition(buffer)) {
                return false;
            } else if (position > 0 && position > (buffer.data + buffer._capacity) - buffer._pointer) {
                if (!mb__realloc(buffer, position)) {
                    return false;
                }
            }

            buffer._pointer += position;
        }
    }

    return true;
}

mbSkip :: inline (buffer: *MemoryBuffer, distance: s64) -> bool {
    return mbSeek(buffer, distance, SeekType.Current);
}

mbScanTo :: (buffer: *MemoryBuffer, data: *u8, length: s64) -> bool {
    while (buffer._pointer + length <= mbEnd(buffer)) {
        if(memoryCompare(buffer._pointer, data, length) == 0) {
            return true;
        }

        buffer._pointer += 1;
    }

    return false;
}

mbRead :: inline (buffer: *MemoryBuffer, value: *u8) -> bool {
    return mbReadBytes(buffer, value, 1);
}

mbReadBytes :: (buffer: *MemoryBuffer, values: *u8, count: s64) -> bool {
    assert(values != null);

    if (buffer._pointer + count > mbEnd(buffer)) {
        return false;
    }

    memoryCopy(values, buffer._pointer, count);
    buffer._pointer += count;
    return true;
}

mbReadString :: (buffer: *MemoryBuffer, str: *string, options: StringStoreOptions) -> bool {
    if options == {
        case StringStoreOptions.ZeroTerminated; {
            count := 0;
            capacity := 8;
            data := alloc(u8, capacity, buffer.allocator);
            defer free(data);

            byte: u8;
            while (mbRead(buffer, *byte) && byte != 0) {
                if (count + 1 > capacity) {
                    oldCapacity := capacity;
                    capacity = oldCapacity * 2;
                    data = realloc(data, capacity, oldCapacity, buffer.allocator);
                }
                data[count] = byte;
                count += 1;
            }

            str.count = count;
            str.data = alloc(u8, count, buffer.allocator);
            memoryCopy(str.data, data, count);
        }
        case StringStoreOptions.PrependCount; {
            count: s64;
            if (!mbReadInt64LE(buffer, *count) || count < 0) {
                return false;
            }
            data := alloc(u8, str.count, buffer.allocator);
            for i : range(0, count) {
                byte: u8;
                if (!mbRead(buffer, *byte)) {
                    return false;
                }
                data[i] = byte;
            }
            str.count = count;
            str.data = data;
        }

    }
    return true;
}

mbReadInt16LE :: (buffer: *MemoryBuffer, value: *s16) -> bool {
    return mbReadIntLE(s16, buffer, value);
}

mbReadInt16BE :: (buffer: *MemoryBuffer, value: *s16) -> bool {
    return mbReadIntBE(s16, buffer, value);
}

mbReadUInt16LE :: (buffer: *MemoryBuffer, value: *u16) -> bool {
    return mbReadIntLE(u16, buffer, value);
}

mbReadUInt16BE :: (buffer: *MemoryBuffer, value: *u16) -> bool {
    return mbReadIntBE(u16, buffer, value);
}

mbReadInt24LE :: (buffer: *MemoryBuffer, value: *s32) -> bool {
    byte0, byte1, byte2: u8;
    if(mbRead(buffer, *byte0) && mbRead(buffer, *byte1) && mbRead(buffer, *byte2))
    {
        <<value = ((cast(s32) byte2) << 16) |
                  ((cast(s32) byte1) << 8) |
                  ((cast(s32) byte0) << 0);
        return true;
    }
    return false;
}

mbReadInt24BE :: (buffer: *MemoryBuffer, value: *s32) -> bool {
    byte0, byte1, byte2: u8;
    if(mbRead(buffer, *byte0) && mbRead(buffer, *byte1) && mbRead(buffer, *byte2))
    {
        <<value = ((cast(s32) byte0) << 16) |
                  ((cast(s32) byte1) << 8) |
                  ((cast(s32) byte2) << 0);
        return true;
    }
    return false;
}

mbReadUInt24LE :: (buffer: *MemoryBuffer, value: *u32) -> bool {
    byte0, byte1, byte2: u8;
    if(mbRead(buffer, *byte0) && mbRead(buffer, *byte1) && mbRead(buffer, *byte2))
    {
        <<value = ((cast(u32) byte2) << 16) |
                  ((cast(u32) byte1) << 8) |
                  ((cast(u32) byte0) << 0);
        return true;
    }
    return false;
}

mbReadUInt24BE :: (buffer: *MemoryBuffer, value: *u32) -> bool {
    byte0, byte1, byte2: u8;
    if(mbRead(buffer, *byte0) && mbRead(buffer, *byte1) && mbRead(buffer, *byte2))
    {
        <<value = ((cast(u32) byte0) << 16) |
                  ((cast(u32) byte1) << 8) |
                  ((cast(u32) byte2) << 0);
        return true;
    }
    return false;
}

mbReadInt32LE :: (buffer: *MemoryBuffer, value: *s32) -> bool {
    return mbReadIntLE(s32, buffer, value);
}

mbReadInt32BE :: (buffer: *MemoryBuffer, value: *s32) -> bool {
    return mbReadIntBE(s32, buffer, value);
}

mbReadUInt32LE :: (buffer: *MemoryBuffer, value: *u32) -> bool {
    return mbReadIntLE(u32, buffer, value);
}

mbReadUInt32BE :: (buffer: *MemoryBuffer, value: *u32) -> bool {
    return mbReadIntBE(u32, buffer, value);
}

mbReadInt64LE :: (buffer: *MemoryBuffer, value: *s64) -> bool {
    return mbReadIntLE(s64, buffer, value);
}

mbReadInt64BE :: (buffer: *MemoryBuffer, value: *s64) -> bool {
    return mbReadIntBE(s64, buffer, value);
}

mbReadUInt64LE :: (buffer: *MemoryBuffer, value: *u64) -> bool {
    return mbReadIntLE(u64, buffer, value);
}

mbReadUInt64BE :: (buffer: *MemoryBuffer, value: *u64) -> bool {
    return mbReadIntBE(u64, buffer, value);
}

mbReadIntLE :: ($intType: Type, buffer: *MemoryBuffer, value: *intType) -> bool {
    intSize :: #run size_of(intType);

    result: intType = 0;

    for i : range(0, intSize) {
        byte: u8;
        if (!mbRead(buffer, *byte)) {
            return false;
        }
        result |= (cast(intType) byte) << (8 * i);
    }

    <<value = result;
    return true;
}

mbReadIntBE :: ($intType: Type, buffer: *MemoryBuffer, value: *intType) -> bool {
    intSize :: #run size_of(intType);

    result: intType = 0;

    for i : range(0, intSize) {
        byte: u8;
        if (!mbRead(buffer, *byte)) {
            return false;
        }
        result |= (cast(intType) byte) << (8 * (intSize - i - 1));
    }

    <<value = result;
    return true;
}

mbWrite :: (buffer: *MemoryBuffer, value: u8) -> bool {
    return mbWriteBytes(buffer, *value, 1);
}

mbWriteBytes :: inline (buffer: *MemoryBuffer, values: ..u8) -> bool {
    return mbWriteBytes(buffer, values.data, values.count);
}

mbWriteBytes :: (buffer: *MemoryBuffer, values: *u8, count: s64) -> bool {
    if (count >= buffer.data + buffer._capacity - buffer._pointer) {
        if (!mb__realloc(buffer, mbPosition(buffer) + count)) {
            return false;
        }
    }

    memoryCopy(buffer._pointer, values, count);
    buffer._pointer += count;
    buffer.length += count;
    return true;
}

mbWriteString :: (buffer: *MemoryBuffer, str: string, options: StringStoreOptions = StringStoreOptions.None) -> bool {
    if options == {
        case StringStoreOptions.ZeroTerminated; {
            if (!mbWriteBytes(buffer, str.data, str.count)) {
                return false;
            }
            if (!mbWrite(buffer, 0)) {
                return false;
            }
        }
        case StringStoreOptions.PrependCount; {
            if (!mbWriteInt64LE(buffer, str.count)) {
                return false;
            }
            if (!mbWriteBytes(buffer, str.data, str.count)) {
                return false;
            }
        }
        case; {
            if (!mbWriteBytes(buffer, str.data, str.count)) {
                return false;
            }
        }
    }
    return true;
}

mbWriteInt16LE :: (buffer: *MemoryBuffer, value: s16) -> bool {
    return mbWriteBytes(
        buffer,
        cast(u8) ((value >> 0) & 0xFF),
        cast(u8) ((value >> 8) & 0xFF)
    );
}

mbWriteInt16BE :: (buffer: *MemoryBuffer, value: s16) -> bool {
    return mbWriteBytes(
        buffer,
        cast(u8) ((value >> 8) & 0xFF),
        cast(u8) ((value >> 0) & 0xFF)
    );
}

mbWriteUInt16LE :: (buffer: *MemoryBuffer, value: u16) -> bool {
    return mbWriteBytes(
        buffer,
        cast(u8) ((value >> 0) & 0xFF),
        cast(u8) ((value >> 8) & 0xFF)
    );
}

mbWriteUInt16BE :: (buffer: *MemoryBuffer, value: u16) -> bool {
    return mbWriteBytes(
        buffer,
        cast(u8) ((value >> 8) & 0xFF),
        cast(u8) ((value >> 0) & 0xFF)
    );
}

mbWriteInt24LE :: (buffer: *MemoryBuffer, value: s32) -> bool {
    return mbWriteBytes(
        buffer,
        cast(u8) ((value >> 0) & 0xFF),
        cast(u8) ((value >> 8) & 0xFF),
        cast(u8) ((value >> 16) & 0xFF)
    );
}

mbWriteInt24BE :: (buffer: *MemoryBuffer, value: s32) -> bool {
    return mbWriteBytes(
        buffer,
        cast(u8) ((value >> 16) & 0xFF),
        cast(u8) ((value >> 8) & 0xFF),
        cast(u8) ((value >> 0) & 0xFF)
    );
}

mbWriteUInt24LE :: (buffer: *MemoryBuffer, value: u32) -> bool {
    return mbWriteBytes(
        buffer,
        cast(u8) ((value >> 0) & 0xFF),
        cast(u8) ((value >> 8) & 0xFF),
        cast(u8) ((value >> 16) & 0xFF)
    );
}

mbWriteUInt24BE :: (buffer: *MemoryBuffer, value: u32) -> bool {
    return mbWriteBytes(
        buffer,
        cast(u8) ((value >> 16) & 0xFF),
        cast(u8) ((value >> 8) & 0xFF),
        cast(u8) ((value >> 0) & 0xFF)
    );
}

mbWriteInt32LE :: (buffer: *MemoryBuffer, value: s32) -> bool {
    return mbWriteBytes(
        buffer,
        cast(u8) ((value >> 0) & 0xFF),
        cast(u8) ((value >> 8) & 0xFF),
        cast(u8) ((value >> 16) & 0xFF),
        cast(u8) ((value >> 24) & 0xFF)
    );
}

mbWriteInt32BE :: (buffer: *MemoryBuffer, value: s32) -> bool {
    return mbWriteBytes(
        buffer,
        cast(u8) ((value >> 24) & 0xFF),
        cast(u8) ((value >> 16) & 0xFF),
        cast(u8) ((value >> 8) & 0xFF),
        cast(u8) ((value >> 0) & 0xFF)
    );
}

mbWriteUInt32LE :: (buffer: *MemoryBuffer, value: u32) -> bool {
    return mbWriteBytes(
        buffer,
        cast(u8) ((value >> 0) & 0xFF),
        cast(u8) ((value >> 8) & 0xFF),
        cast(u8) ((value >> 16) & 0xFF),
        cast(u8) ((value >> 24) & 0xFF)
    );
}

mbWriteUInt32BE :: (buffer: *MemoryBuffer, value: u32) -> bool {
    return mbWriteBytes(
        buffer,
        cast(u8) ((value >> 24) & 0xFF),
        cast(u8) ((value >> 16) & 0xFF),
        cast(u8) ((value >> 8) & 0xFF),
        cast(u8) ((value >> 0) & 0xFF)
    );
}

mbWriteInt64LE :: (buffer: *MemoryBuffer, value: s64) -> bool {
    return mbWriteBytes(
        buffer,
        cast(u8) ((value >> 0) & 0xFF),
        cast(u8) ((value >> 8) & 0xFF),
        cast(u8) ((value >> 16) & 0xFF),
        cast(u8) ((value >> 24) & 0xFF),
        cast(u8) ((value >> 32) & 0xFF),
        cast(u8) ((value >> 40) & 0xFF),
        cast(u8) ((value >> 48) & 0xFF),
        cast(u8) ((value >> 56) & 0xFF)
    );
}

mbWriteInt64BE :: (buffer: *MemoryBuffer, value: s64) -> bool {
    return mbWriteBytes(
        buffer,
        cast(u8) ((value >> 56) & 0xFF),
        cast(u8) ((value >> 48) & 0xFF),
        cast(u8) ((value >> 40) & 0xFF),
        cast(u8) ((value >> 32) & 0xFF),
        cast(u8) ((value >> 24) & 0xFF),
        cast(u8) ((value >> 16) & 0xFF),
        cast(u8) ((value >> 8) & 0xFF),
        cast(u8) ((value >> 0) & 0xFF)
    );
}

mbWriteUInt64LE :: (buffer: *MemoryBuffer, value: u64) -> bool {
    return mbWriteBytes(
        buffer,
        cast(u8) ((value >> 0) & 0xFF),
        cast(u8) ((value >> 8) & 0xFF),
        cast(u8) ((value >> 16) & 0xFF),
        cast(u8) ((value >> 24) & 0xFF),
        cast(u8) ((value >> 32) & 0xFF),
        cast(u8) ((value >> 40) & 0xFF),
        cast(u8) ((value >> 48) & 0xFF),
        cast(u8) ((value >> 56) & 0xFF)
    );
}

mbWriteUInt64BE :: (buffer: *MemoryBuffer, value: u64) -> bool {
    return mbWriteBytes(
        buffer,
        cast(u8) ((value >> 56) & 0xFF),
        cast(u8) ((value >> 48) & 0xFF),
        cast(u8) ((value >> 40) & 0xFF),
        cast(u8) ((value >> 32) & 0xFF),
        cast(u8) ((value >> 24) & 0xFF),
        cast(u8) ((value >> 16) & 0xFF),
        cast(u8) ((value >> 8) & 0xFF),
        cast(u8) ((value >> 0) & 0xFF)
    );
}

mbIsEOF :: (buffer: *MemoryBuffer) -> bool {
    return buffer._pointer == mbEnd(buffer);
}

#scope_file

mb__realloc :: (buffer: *MemoryBuffer, newCapacity: s64) -> bool {
    if (newCapacity <= buffer._capacity) {
        buffer._capacity = newCapacity;
        return true;
    }

    oldData := buffer.data;
    newData := alloc(u8, newCapacity, buffer.allocator);
    if (newData == null) {
        return false;
    }

    memoryCopy(newData, oldData, buffer.length);

    buffer._pointer = newData + mbPosition(buffer);
    buffer._capacity = newCapacity;
    buffer.data = newData;

    free(oldData);
    return true;
}