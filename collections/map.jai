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
HashMap :: struct(TKey: Type, TValue: Type) {
    count: s64;
    capacity: s64;
    loadFactor: float64;
    defaultValue: TValue;
    freeItems: bool;
    firstInOrder: s64;
    lastInOrder: s64;
    allocator: Allocator;
    hashFn: (TKey) -> s64;
    equalsFn: (TKey, TKey) -> bool;
    entries: *HashMapEntry(TKey, TValue);
}

HashMapEntry :: struct(TKey: Type, TValue: Type) {
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

createMap :: ($TKey: Type, $TValue: Type, options: HashMapOptions(TKey, TValue)) -> HashMap(TKey, TValue) {
    map: HashMap(TKey, TValue);
    init(*map, options);
    return map;
}

init :: (map: *$T/HashMap, options: HashMapOptions(T.TKey, T.TValue)) {
    assert(options.capacity > 0);
    assert(options.hashFn != null);

    map.capacity = options.capacity;
    map.loadFactor = 0.8;
    map.defaultValue = options.defaultValue;
    map.freeItems = options.freeItems;
    map.firstInOrder = -1;
    map.lastInOrder = -1;
    map.allocator = options.allocator;
    map.hashFn = options.hashFn;
    map.equalsFn = options.equalsFn;
    map.count = 0;
    map.entries = alloc(HashMapEntry(T.TKey, T.TValue), count = map.capacity, allocator = map.allocator);
}

uninit :: (map: *$T/HashMap, freeMap: bool = false) {
    if (map.entries) {
        clear(map);
        free(map.entries, map.allocator);
    }

    if (freeMap) {
        free(map, map.allocator);
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

for_expansion :: (map: *$T/HashMap, body: Code, flags: For_Flags) #expand {
    #assert(!(flags & .REVERSE));

    index := 0;
    current := map.firstInOrder;
    while (current >= 0) {
        entry := *map.entries[current];
        #if flags & .POINTER {
            pair: HashMapPair(T.TKey, *T.TValue);
            pair.key = entry.key;
            pair.value = *entry.value;
            `it := pair;
        } else {
            pair: HashMapPair(T.TKey, T.TValue);
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

resize :: (map: *$T/HashMap) {
    oldCapacity := map.capacity;
    oldEntries := map.entries;
    oldFirstInOrder := map.firstInOrder;

    map.capacity = oldCapacity * 2;
    map.entries = alloc(HashMapEntry(T.TKey, T.TValue), count = map.capacity, allocator = map.allocator);
    map.firstInOrder = -1;
    map.lastInOrder = -1;
    map.count = 0;

    current := oldFirstInOrder;
    while (current >= 0) {
        entry := *oldEntries[current];
        insert(map, entry.key, entry.value);
        current = entry.nextInOrder;
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

getEntry :: (map: *$T/HashMap, key: T.TKey) -> bool, *HashMapEntry(T.TKey, T.TValue) {
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

findEmptyEntry :: (map: *$T/HashMap, index: s64) -> s64 {
    for i : 0..map.capacity - 1 {
        entryIndex := (index + i) % map.capacity;
        if (!map.entries[entryIndex].active) {
            return entryIndex;
        }
    }

    return -1;
}
