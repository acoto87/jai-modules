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
// It defines a strongly-typed hash map of elements and its operations.
//
SmallHashMap :: struct(TKey: Type, TValue: Type, length: s64) {
    count: s64;
    capacity: s64;
    defaultValue: TValue;
    freeItems: bool;
    firstInOrder: s64;
    lastInOrder: s64;
    allocator: Allocator;
    hashFn: (TKey) -> s64;
    equalsFn: (TKey, TKey) -> bool;
    entries: [length] SmallHashMapEntry(TKey, TValue);
}

SmallHashMapEntry :: struct(TKey: Type, TValue: Type) {
    active: bool;
    hash: s64;
    idx: s64;
    prev: s64;
    next: s64;
    prevInOrder: s64;
    nextInOrder: s64;
    key: TKey;
    value: TValue;
}

SmallHashMapOptions :: struct(TKey: Type, TValue: Type, length: s64) {
    defaultValue: TValue;
    freeItems: bool;
    allocator: Allocator;
    hashFn: (TKey) -> s64;
    equalsFn: (TKey, TKey) -> bool;
}

createSmallMap :: ($TKey: Type, $TValue: Type, $length: s64, options: SmallHashMapOptions(TKey, TValue, length)) -> SmallHashMap(TKey, TValue, length) {
    map: SmallHashMap(TKey, TValue, length);
    init(*map, options);
    return map;
}

init :: (map: *$T/SmallHashMap, options: SmallHashMapOptions(T.TKey, T.TValue, T.length)) {
    assert(options.hashFn != null);

    map.capacity = T.length;
    map.defaultValue = options.defaultValue;
    map.freeItems = options.freeItems;
    map.firstInOrder = -1;
    map.lastInOrder = -1;
    map.allocator = options.allocator;
    map.hashFn = options.hashFn;
    map.equalsFn = options.equalsFn;
    map.count = 0;
}

uninit :: (map: *$T/SmallHashMap, freeMap: bool = false) {
    clear(map);

    if (freeMap) {
        free(map, map.allocator);
    }
}

clear :: (map: *$T/SmallHashMap) {
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

containsKey :: (map: *$T/SmallHashMap, key: T.TKey) -> bool {
    found := getEntry(map, key);
    return found;
}

get :: (map: *$T/SmallHashMap, key: T.TKey) -> bool, T.TValue {
    found, entry := getEntry(map, key);
    if (found) {
        return true, entry.value;
    }
    return false, map.defaultValue;
}

ref :: (map: *$T/SmallHashMap, key: T.TKey) -> bool, *T.TValue {
    found, entry := getEntry(map, key);
    if (found) {
        return true, *entry.value;
    }
    return false, null;
}

set :: (map: *$T/SmallHashMap, key: T.TKey, value: T.TValue) {
    insert(map, key, value);
}

removeKey :: (map: *$T/SmallHashMap, key: T.TKey) {
    found, entry := getEntry(map, key);
    if (found) {
        value := entry.value;

        if (entry.prev >= 0) {
            prevEntry := *map.entries[entry.prev];
            prevEntry.next = entry.next;
        }

        if (entry.next >= 0) {
            nextEntry := *map.entries[entry.next];
            nextEntry.prev = entry.prev;
        }

        if (entry.prevInOrder >= 0) {
            prevEntryInOrder := *map.entries[entry.prevInOrder];
            prevEntryInOrder.nextInOrder = entry.nextInOrder;
        }

        if (entry.nextInOrder >= 0) {
            nextEntryInOrder := *map.entries[entry.nextInOrder];
            nextEntryInOrder.prevInOrder = entry.prevInOrder;
        }

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

getKeys :: (map: *$T/SmallHashMap) -> [] T.TKey {
    if (map.count == 0) {
        return T.TKey.[];
    }

    keys := allocArray(T.TKey, map.count);

    index := 0;
    current := map.firstInOrder;
    while (current >= 0) {
        entry := *map.entries[current];
        keys[index] = entry.key;

        current = entry.nextInOrder;
        index += 1;
    }

    return keys;
}

getValues :: (map: *$T/SmallHashMap) -> [] T.Value {
    if (map.count == 0) {
        return T.TValue.[];
    }

    values := allocArray(T.TValue, map.count);

    index := 0;
    current := map.firstInOrder;
    while (current >= 0) {
        entry := *map.entries[current];
        values[index] = entry.value;

        current = entry.nextInOrder;
        index += 1;
    }

    return values;
}

for_expansion :: (map: *$T/SmallHashMap, body: Code, flags: For_Flags) #expand {
    #assert(!(flags & .REVERSE));

    index := 0;
    current := map.firstInOrder;
    while (current >= 0) {
        entry := *map.entries[current];
        #if flags & .POINTER {
            pair: KeyValuePair(T.TKey, *T.TValue);
            pair.key = entry.key;
            pair.value = *entry.value;
            `it := pair;
        } else {
            pair: KeyValuePair(T.TKey, T.TValue);
            pair.key = entry.key;
            pair.value = entry.value;
            `it := pair;
        }
        `it_index := index;

        #insert (remove=assert(false)) body;

        current = entry.nextInOrder;
        index += 1;
    }
}

#scope_file

#import "utils";

insert :: (map: *$T/SmallHashMap, key: T.TKey, value: T.TValue) {
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

    assert(map.count < map.capacity);

    hash := map.hashFn(key) % map.capacity;

    if (entry.active) {
        next := findEmptyEntry(map, 0);
        assert(next >= 0 && next < map.capacity);

        entry.next = next;

        nextEntry := *map.entries[next];
        nextEntry.active = true;
        nextEntry.hash = hash;
        nextEntry.idx = next;
        nextEntry.prev = entry.idx;
        nextEntry.next = -1;
        nextEntry.prevInOrder = map.lastInOrder;
        nextEntry.nextInOrder = -1;
        nextEntry.key = key;
        nextEntry.value = value;

        if (map.lastInOrder >= 0) {
            lastEntryInOrder := *map.entries[map.lastInOrder];
            lastEntryInOrder.nextInOrder = next;
        }

        map.lastInOrder = next;
    } else {
        entry.active = true;
        entry.hash = hash;
        entry.idx = hash;
        entry.prev = -1;
        entry.next = -1;
        entry.prevInOrder = map.lastInOrder;
        entry.nextInOrder = -1;
        entry.key = key;
        entry.value = value;

        if (map.firstInOrder < 0) {
            map.firstInOrder = hash;
        }

        if (map.lastInOrder >= 0) {
            lastEntryInOrder := *map.entries[map.lastInOrder];
            lastEntryInOrder.nextInOrder = hash;
        }

        map.lastInOrder = hash;
    }

    map.count += 1;
}

getEntry :: (map: *$T/SmallHashMap, key: T.TKey) -> bool, *SmallHashMapEntry(T.TKey, T.TValue) {
    found := false;

    hash := map.hashFn(key) % map.capacity;
    index := hash;

    entry := *map.entries[index];
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

        index = entry.next;
        entry = *map.entries[index];
    }

    return found, entry;
}

findEmptyEntry :: (map: *$T/SmallHashMap, index: s64) -> s64 {
    for i : 0..map.capacity - 1 {
        entryIndex := (index + i) % map.capacity;
        if (!map.entries[entryIndex].active) {
            return entryIndex;
        }
    }

    return -1;
}
