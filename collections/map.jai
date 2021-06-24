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
HashMap :: struct(TKey: Type, TValue: Type, Sorted := false, MaxCapacity := 0) {
    count: s64;
    capacity: s64;
    #if MaxCapacity == 0 {
        loadFactor: f64;
    }
    defaultValue: TValue;
    freeItems: bool;
    #if Sorted {
        firstInOrder: s64;
        lastInOrder: s64;
    }
    allocator: Allocator;
    hashFn: (TKey) -> u64;
    equalsFn: (TKey, TKey) -> bool;
    #if MaxCapacity > 0 {
        entries: [MaxCapacity] HashMapEntry(TKey, TValue, Sorted);
    } else {
        entries: *HashMapEntry(TKey, TValue, Sorted);
    }
}

HashMapOptions :: struct(TKey: Type, TValue: Type) {
    capacity: s64 = 8;
    loadFactor: f64 = 0.8;
    defaultValue: TValue;
    freeItems: bool;
    allocator: Allocator;
    hashFn: (TKey) -> u64;
    equalsFn: (TKey, TKey) -> bool;
}

createMap :: ($TKey: Type, $TValue: Type, $Sorted := false, $MaxCapacity := 0) -> HashMap(TKey, TValue, Sorted, MaxCapacity) {
    map: HashMap(TKey, TValue, Sorted, MaxCapacity);
    init(*map);
    return map;
}

createMap :: ($TKey: Type, $TValue: Type, $Sorted := false, $MaxCapacity := 0, options: HashMapOptions(TKey, TValue)) -> HashMap(TKey, TValue, Sorted, MaxCapacity) {
    map: HashMap(TKey, TValue, Sorted, MaxCapacity);
    init(*map, options);
    return map;
}

init :: (map: *$T/HashMap) {
    init(*map, HashMapOptions(T.TKey, T.TValue).{});
}

init :: (map: *$T/HashMap, options: HashMapOptions(T.TKey, T.TValue)) {
    #if T.MaxCapacity == 0 {
        assert(options.capacity > 0);
        map.capacity = options.capacity;
    } else {
        map.capacity = T.MaxCapacity;
    }

    #if T.MaxCapacity == 0 {
        assert(options.loadFactor > 0 && options.loadFactor <= 1);
        map.loadFactor = options.loadFactor;
    }
    map.defaultValue = options.defaultValue;
    map.freeItems = options.freeItems;
    #if T.Sorted {
        map.firstInOrder = -1;
        map.lastInOrder = -1;
    }
    map.allocator = options.allocator;
    map.hashFn = options.hashFn;
    if (map.hashFn == null) {
        map.hashFn = defaultHashFn(T.TKey);
        assert(map.hashFn != null);
    }
    map.equalsFn = options.equalsFn;
    map.count = 0;
    #if T.MaxCapacity == 0 {
        map.entries = alloc(HashMapEntry(T.TKey, T.TValue, T.Sorted), count = map.capacity, allocator = map.allocator);
    }
}

uninit :: (map: *$T/HashMap, freeMap: bool = false) {
    if (map.entries) {
        clear(map);

        #if T.MaxCapacity > 0 {
            free(map.entries, map.allocator);
        }
    }

    if (freeMap) {
        free(map, map.allocator);
    }
}

clear :: (map: *$T/HashMap) {
    #if T.MaxCapacity == 0 {
        assert(map.entries != null);
    }

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
    #if T.MaxCapacity == 0 {
        assert(map.entries != null);
    }

    found := getEntry(map, key);
    return found;
}

get :: (map: *$T/HashMap, key: T.TKey) -> bool, T.TValue {
    #if T.MaxCapacity == 0 {
        assert(map.entries != null);
    }

    found, entry := getEntry(map, key);
    if (found) {
        return true, entry.value;
    }
    return false, map.defaultValue;
}

ref :: (map: *$T/HashMap, key: T.TKey) -> bool, *T.TValue {
    #if T.MaxCapacity == 0 {
        assert(map.entries != null);
    }

    found, entry := getEntry(map, key);
    if (found) {
        return true, *entry.value;
    }
    return false, null;
}

set :: (map: *$T/HashMap, key: T.TKey, value: T.TValue) {
    #if T.MaxCapacity == 0 {
        assert(map.entries != null);

        load := cast(s64) (map.loadFactor * map.capacity);
        if (map.count >= load) {
            resize(map);
        }
    }

    insertOrUpdate(map, key, value);
}

removeKey :: (map: *$T/HashMap, key: T.TKey) {
    #if T.MaxCapacity == 0 {
        assert(map.entries != null);
    }

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

        #if T.Sorted {
            if (entry.prevInOrder >= 0) {
                prevEntryInOrder := *map.entries[entry.prevInOrder];
                prevEntryInOrder.nextInOrder = entry.nextInOrder;
            }

            if (entry.nextInOrder >= 0) {
                nextEntryInOrder := *map.entries[entry.nextInOrder];
                nextEntryInOrder.prevInOrder = entry.prevInOrder;
            }
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

getKeys :: (map: *$T/HashMap) -> [] T.TKey {
    #if T.MaxCapacity == 0 {
        assert(map.entries != null);
    }

    if (map.count == 0) {
        return T.TKey.[];
    }

    keys := allocArray(T.TKey, map.count);

    #if T.Sorted {
        index := 0;
        current := map.firstInOrder;
        while (current >= 0) {
            entry := *map.entries[current];
            keys[index] = entry.key;

            current = entry.nextInOrder;
            index += 1;
        }
    } else {
        index := 0;
        for i : 0..map.capacity-1 {
            entry := *map.entries[i];
            if (entry.active) {
                keys[index] = entry.key;
                index += 1;
            }
        }
    }

    return keys;
}

getValues :: (map: *$T/HashMap) -> [] T.Value {
    #if T.MaxCapacity == 0 {
        assert(map.entries != null);
    }

    if (map.count == 0) {
        return T.TValue.[];
    }

    values := allocArray(T.TValue, map.count);

    #if T.Sorted {
        index := 0;
        current := map.firstInOrder;
        while (current >= 0) {
            entry := *map.entries[current];
            values[index] = entry.value;

            current = entry.nextInOrder;
            index += 1;
        }
    } else {
        index := 0;
        for i : 0..map.capacity-1 {
            entry := *map.entries[current];
            if (entry.active) {
                values[index] = entry.value;
                index += 1;
            }
        }
    }

    return values;
}

for_expansion :: (map: *$T/HashMap, body: Code, flags: For_Flags) #expand {
    #if T.MaxCapacity == 0 {
        assert(map.entries != null);
    }

    #assert(!(flags & .REVERSE));

    #if T.Sorted {
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
    } else {
        index := 0;
        for i : 0..map.capacity-1 {
            entry := *map.entries[i];
            if (!entry.active) {
                continue;
            }
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

            index += 1;
        }
    }
}

#scope_file

#import "utils";

HashMapEntry :: struct(TKey: Type, TValue: Type, Sorted := false) {
    active: bool;
    hash: u64;
    idx: s64;
    prev: s64;
    next: s64;
    #if Sorted {
        prevInOrder: s64;
        nextInOrder: s64;
    }
    key: TKey;
    value: TValue;
}

resize :: (map: *$T/HashMap) {
    #assert(T.MaxCapacity == 0);

    oldCapacity := map.capacity;
    oldEntries := map.entries;
    #if T.Sorted {
        oldFirstInOrder := map.firstInOrder;
    }

    map.capacity = oldCapacity * 2;
    map.entries = alloc(HashMapEntry(T.TKey, T.TValue, T.Sorted), count = map.capacity, allocator = map.allocator);
    #if T.Sorted {
        map.firstInOrder = -1;
        map.lastInOrder = -1;
    }
    map.count = 0;

    #if T.Sorted {
        current := oldFirstInOrder;
        while (current >= 0) {
            entry := *oldEntries[current];
            insertOrUpdate(map, entry.key, entry.value);
            current = entry.nextInOrder;
        }
    } else {
        for i : 0..oldCapacity-1 {
            entry := *oldEntries[i];
            if (entry.active) {
                insertOrUpdate(map, entry.key, entry.value);
            }
        }
    }

    free(oldEntries, map.allocator);
}

insertOrUpdate :: (map: *$T/HashMap, key: T.TKey, value: T.TValue) {
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

    hash := map.hashFn(key) % cast(u64) map.capacity;

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
        #if T.Sorted {
            nextEntry.prevInOrder = map.lastInOrder;
            nextEntry.nextInOrder = -1;
        }

        nextEntry.key = key;
        nextEntry.value = value;

        #if T.Sorted {
            if (map.lastInOrder >= 0) {
                lastEntryInOrder := *map.entries[map.lastInOrder];
                lastEntryInOrder.nextInOrder = next;
            }

            map.lastInOrder = next;
        }
    } else {
        entry.active = true;
        entry.hash = hash;
        entry.idx = cast(s64) hash;
        entry.prev = -1;
        entry.next = -1;
        #if T.Sorted {
            entry.prevInOrder = map.lastInOrder;
            entry.nextInOrder = -1;
        }
        entry.key = key;
        entry.value = value;

        #if T.Sorted {
            if (map.firstInOrder < 0) {
                map.firstInOrder = cast(s64) hash;
            }

            if (map.lastInOrder >= 0) {
                lastEntryInOrder := *map.entries[map.lastInOrder];
                lastEntryInOrder.nextInOrder = cast(s64) hash;
            }

            map.lastInOrder = cast(s64) hash;
        }
    }

    map.count += 1;
}

getEntry :: (map: *$T/HashMap, key: T.TKey) -> bool, *HashMapEntry(T.TKey, T.TValue, T.Sorted) {
    found := false;

    hash := map.hashFn(key) % cast(u64) map.capacity;
    index := cast(s64) hash;

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
