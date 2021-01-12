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
// stack-jai is a library written in Jai.
//
// It defines a strongly-typed hash map of elements and its operations.
//
HashMap :: struct(TKey: Type, TValue: Type) {
    count: s64;
    capacity: s64;
    loadFactor: float64;
    shift: s64;
    defaultValue: TValue;
    freeItems: bool;
    allocator: Allocator;
    hashFn: (TKey) -> s64;
    equalsFn: (TKey, TKey) -> bool;
    entries: *HashMapEntry(TKey, TValue);
}

HashMapEntry :: struct(TKey: Type, TValue: Type) {
    active: bool;
    hash: s64;
    next: s64;
    key: TKey;
    value: TValue;
}

HashMapOptions :: struct(TKey: Type, TValue: Type) {
    capacity: s64 = 8;
    defaultValue: TValue;
    freeItems: bool;
    allocator: Allocator;
    hashFn: (TKey) -> s64;
    equalsFn: (TKey, TKey) -> bool;
}

HashMapPair :: struct(TKey: Type, TValue: Type) {
    key: TKey;
    value: TValue;
}

init :: (map: *$T/HashMap, options: HashMapOptions) {
    assert(options.capacity > 0);
    assert(options.hashFn != null);

    map.capacity = options.capacity;
    map.loadFactor = 0.8;
    map.shift = 29;
    map.defaultValue = options.defaultValue;
    map.freeItems = options.freeItems;
    map.allocator = options.allocator;
    map.hashFn = options.hashFn;
    map.equalsFn = options.equalsFn;
    map.count = 0;
    map.entries = alloc(HashMapEntry(T.TKey, T.TValue), count = map.capacity, allocator = map.allocator);
}

free :: (map: *$T/HashMap, freeMap: bool = false) {
    if (map.entries) {
        clear(map);
        free(map.entries, map.allocator);
    }

    if (freeMap) {
        free(map, list.allocator);
    }
}

clear :: (map: *$T/HashMap) {
    assert(map.entries != null);

    #insert #run () -> string {
        info := type_info(T.TValue);

        if (info.type == Type_Info_Tag.POINTER) {
            return #string DONE
                if (map.freeItems) {
                    for i : 0..map.capacity - 1 {
                        entry := *map.entries[i];

                        if (entry.active) {
                            free(entry.value, map.allocator);
                            entry.value = map.defaultValue;
                            entry.active = false;
                        }
                    }
                }
            DONE;
        }

        return "";
    }();

    map.count = 0;
}

containsKey :: (map: *$T/HashMap, key: T.TKey) -> bool {
    assert(map.entries != null);

    found := getEntry(map, key);
    return found;
}

get :: (map: *$T/HashMap, key: T.TKey) -> bool, T.TValue {
    assert(map.entries != null);

    found, entry := getEntry(map, key);
    if (found) {
        return true, entry.value;
    }
    return false, map.defaultValue;
}

ref :: (map: *$T/HashMap, key: T.TKey) -> bool, *T.TValue {
    assert(map.entries != null);

    found, entry := getEntry(map, key);
    if (found) {
        return true, *entry.value;
    }
    return false, null;
}

set :: (map: *$T/HashMap, key: T.TKey, value: T.TValue) {
    assert(map.entries != null);

    load := cast(s64) (map.loadFactor * map.capacity);
    if (map.count >= load) {
        resize(map);
    }

    insert(map, key, value);
}

removeKey :: (map: *$T/HashMap, key: T.TKey) {
    assert(map.entries != null);

    found, entry, prevEntry := getEntry(map, key);
    if (found) {
        value := entry.value;

        prevEntry.next = entry.next;
        entry.value = map.defaultValue;
        entry.active = false;

        #insert #run () -> string {
            info := type_info(T.TValue);

            if (info.type == Type_Info_Tag.POINTER) {
                return #string DONE
                    if (map.freeItems) {
                        free(value, map.allocator);
                    }
                DONE;
            }

            return "";
        }();

        map.count -= 1;
    }
}

for_expansion :: (map: *$T/HashMap, body: Code, flags: For_Flags) #expand {
    #assert(!(flags & .REVERSE));

    for i : 0..map.capacity - 1 {
        entry := *map.entries[i];
        if (entry.active) {
            #if flags & .POINTER {
                `it := HashMapPair.{
                    key = entry.key,
                    value = *entry.value
                };
            } else {
                `it := HashMapPair.{
                    key = entry.key,
                    value = entry.value
                };
            }
            #insert (remove=assert(false)) body;
        }
    }
}

#scope_file

#import "utils";

// fibHash :: (hash: s64, shift: s64) -> s64 {
//     hashConstant : s64 : 2654435769;
//     return (hash * hashConstant) >> shift;
// }

resize :: (map: *$T/HashMap) {
    oldCapacity := map.capacity;
    oldEntries := map.entries;

    map.shift -= 1;
    map.capacity = 1 << (32 - map.shift);
    map.entries = alloc(HashMapEntry(T.TKey, T.TValue), count = map.capacity, allocator = map.allocator);
    map.count = 0;

    for i : 0..oldCapacity - 1 {
        entry := *oldEntries[i];
        if (entry.active) {
            insert(map, entry.key, entry.value);
        }
    }

    free(oldEntries, map.allocator);
}

insert :: (map: *$T/HashMap, key: T.TKey, value: T.TValue) {
    found, entry := getEntry(map, key);
    if (found) {
        currentValue := entry.value;
        entry.value = value;

        #insert #run () -> string {
            info := type_info(T.TValue);

            if (info.type == Type_Info_Tag.POINTER) {
                return #string DONE
                    if (map.freeItems) {
                        free(currentValue, map.allocator);
                    }
                DONE;
            }

            return "";
        }();

        return;
    }

    hash := map.hashFn(key) % map.capacity;

    if (entry.active) {
        next := findEmptyEntry(map, 0);
        assert(next >= 0 && next < map.capacity);

        entry.next = next;

        map.entries[next].active = true;
        map.entries[next].hash = hash;
        map.entries[next].next = -1;
        map.entries[next].key = key;
        map.entries[next].value = value;
    } else {
        entry.active = true;
        entry.hash = hash;
        entry.next = -1;
        entry.key = key;
        entry.value = value;
    }

    map.count += 1;
}

getEntry :: (map: *$T/HashMap, key: T.TKey) -> bool, *HashMapEntry(T.TKey, T.TValue), *HashMapEntry(T.TKey, T.TValue) {
    found := false;

    hash := map.hashFn(key) % map.capacity;
    index := hash;
    prevIndex := index;

    entry := *map.entries[index];
    prevEntry := entry;
    while (entry.active) {
        if (entry.hash == hash) {
            if (map.equalsFn != null) {
                if (map.equalsFn(entry.key, key)) {
                    found = true;
                    break;
                }
            } else {
                if (entry.key == key) {
                    found = true;
                    break;
                }
            }
        }

        if (entry.next < 0) {
            break;
        }

        prevIndex = index;
        prevEntry = entry;

        index = entry.next;
        entry = *map.entries[index];
    }

    return found, entry, prevEntry;
}

findEmptyEntry :: (map: *$T/HashMap, index: s64) -> s64 {
    for i : 0..map.capacity - 1 {
        entryIndex := (index + i) % map.capacity;
        if (!map.entries[entryIndex].active) {
            return entryIndex;
        }
    }

    return -1;
}
