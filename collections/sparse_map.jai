//
// Copyright (C) 2020 Alejandro Coto Gutiérrez (https://github.com/acoto87)
//
// This software is provided 'as-is', without any express or implied
// warranty.  In no event will the authors be held liable for any damages
// arising from the use of this software.
//
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it
// freely, subject to the following restrictions:
//
// 1. The origin of this software must not be misrepresented; you must not
//    claim that you wrote the original software. If you use this software
//    in a product, an acknowledgment in the product documentation would be
//    appreciated but is not required.
// 2. Altered source versions must be plainly marked as such, and must not be
//    misrepresented as being the original software.
// 3. This notice may not be removed or altered from any source distribution.
//
// It defines a strongly-typed sparse map of elements and its operations.
//
SparseMap :: struct(TKey: Type, TValue: Type) {
    count: s64;
    capacity: s64;
    freeItems: bool;
    allocator: Allocator;
    maxKey: TKey;
    sparse: *TKey;
    keys: *TKey;
    values: *TValue;
}

SparseMapOptions :: struct(TKey: Type, TValue: Type) {
    maxKey: TKey;
    capacity: s64 = 8;
    freeItems: bool;
    allocator: Allocator;
}

createSparseMap :: ($TKey: Type, $TValue: Type, options: SparseMapOptions(TKey, TValue)) -> SparseMap(TKey, TValue) {
    map: SparseMap(TKey, TValue);
    init(*map, options);
    return map;
}

init :: (map: *$T/SparseMap, options: SparseMapOptions(T.TKey, T.TValue)) {
    assert(options.maxKey > 0);
    assert(options.capacity > 0);

    map.count = 0;
    map.capacity = options.capacity;
    map.freeItems = options.freeItems;
    map.allocator = options.allocator;
    map.maxKey = options.maxKey;
    map.sparse = alloc(T.TKey, map.maxKey + 1, map.allocator);
    map.keys = alloc(T.TKey, map.capacity, map.allocator, initialized = false);
    map.values = alloc(T.TValue, map.capacity, map.allocator, initialized = false);
}

uninit :: (map: *$T/SparseMap, freeMap: bool = false) {
    if (map.sparse != null && map.keys != null && map.values != null) {
        clear(map);
    }

    free(map.sparse, map.allocator);
    free(map.keys, map.allocator);
    free(map.values, map.allocator);

    if (freeMap) {
        free(map, map.allocator);
    }
}

clear :: (map: *$T/SparseMap) {
    assert(map.sparse != null);
    assert(map.keys != null);
    assert(map.values != null);

    #if #run isPointer(T.TValue) {
        if (map.freeItems) {
            for i : 0..map.count-1 {
                free(map.values[i], map.allocator);
            }
        }
    }

    map.count = 0;
}

indexOfKey :: (map: *$T/SparseMap, key: T.TKey) -> s64 {
    assert(map.sparse != null);
    assert(map.keys != null);
    assert(map.values != null);

    if key > map.maxKey then return -1;
    index := map.sparse[key];
    if map.keys[index] != key then return -1;
    return index;
}

containsKey :: inline (map: *$T/SparseMap, key: T.TKey) -> bool {
    return indexOf(map, key) >= 0;
}

get :: (map: *$T/SparseMap, key: T.TKey) -> bool, T.TValue {
    assert(map.sparse != null);
    assert(map.keys != null);
    assert(map.values != null);

    if (key > map.maxKey) {
        return false, default_of(T.TValue);
    }

    index := map.sparse[key];
    if (map.keys[index] != key) {
        return false, default_of(T.TValue);
    }

    return true, map.values[index];
}

ref :: (map: *$T/SparseMap, key: T.TKey) -> bool, *T.TValue {
    assert(map.sparse != null);
    assert(map.keys != null);
    assert(map.values != null);

    if (key > map.maxKey) {
        return false, null;
    }

    index := map.sparse[value];
    if (map.keys[index] != key) {
        return false, null;
    }

    return true, *map.values[index];
}

set :: (map: *$T/SparseMap, key: T.TKey, value: T.TValue) {
    assert(map.sparse != null);
    assert(map.keys != null);
    assert(map.values != null);

    if (key > map.maxKey) {
        return;
    }

    index := map.sparse[key];
    if (map.keys[index] == key) {
        currentValue := map.values[index];

        #if #run isPointer(T.TValue) {
            if (map.freeItems) {
                free(currentValue, map.allocator);
            }
        }

        map.values[index] = value;
        return;
    }

    if (map.count >= map.capacity) {
        resize(map, map.count + 1);
    }

    map.values[map.count] = value;
    map.keys[map.count] = key;
    map.sparse[key] = cast(T.TKey) map.count;
    map.count += 1;
    return;
}

removeKey :: (map: *$T/SparseMap, key: T.TKey) {
    assert(map.sparse != null);
    assert(map.keys != null);
    assert(map.values != null);

    if (map.count == 0) {
        return;
    }

    if (key > map.maxKey) {
        return;
    }

    index := map.sparse[key];
    if (map.keys[index] != key) {
        return;
    }

    #if #run isPointer(T.TValue) {
        if (map.freeItems) {
            currentValue := map.values[index];
            free(currentValue, map.allocator);
        }
    }

    lastKey := map.keys[map.count - 1];
    lastValue := map.values[map.count - 1];

    map.values[index] = lastValue;
    map.keys[index] = lastKey;
    map.sparse[lastKey] = index;
    map.sparse[key] = 0;
    map.count -= 1;
}

for_expansion :: (map: *$T/SparseMap, body: Code, flags: For_Flags) #expand {
    #assert(!(flags & .REVERSE));

    assert(map.sparse != null);
    assert(map.keys != null);
    assert(map.values != null);

    index := 0;
    while (index < map.count) {
        #if flags & .POINTER {
            `it := *map.keys[index];
        } else {
            `it := map.keys[index];
        }
        `it_index := index;

        index += 1;

        #insert (remove=assert(false)) body;
    }
}

values :: (map: *$T/SparseMap, body: Code, flags: For_Flags) #expand {
    #assert(!(flags & .REVERSE));

    assert(map.sparse != null);
    assert(map.keys != null);
    assert(map.values != null);

    index := 0;
    while (index < map.count) {
        #if flags & .POINTER {
            `it := *map.values[index];
        } else {
            `it := map.values[index];
        }
        `it_index := index;

        index += 1;

        #insert (remove=assert(false)) body;
    }
}

#scope_file

resize :: (map: *$T/SparseMap, minSize: s64) {
    oldCapacity := map.capacity;

    map.capacity = oldCapacity * 2;
    if (map.capacity < minSize) {
        map.capacity = minSize;
    }

    map.keys = realloc(map.keys, map.capacity, oldCapacity, map.allocator);
    map.values = realloc(map.values, map.capacity, oldCapacity, map.allocator);
}
