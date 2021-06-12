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
// It defines a strongly-typed hash set of elements and its operations.
//
HashSet :: struct(TItem: Type) {
    count: s64;
    capacity: s64;
    loadFactor: float64;
    shift: s64;
    defaultValue: TItem;
    freeItems: bool;
    allocator: Allocator;
    hashFn: (TItem) -> s64;
    equalsFn: (TItem, TItem) -> bool;
    entries: *HashSetEntry(TItem);
}

HashSetEntry :: struct(TItem: Type) {
    active: bool;
    hash: s64;
    next: s64;
    item: TItem;
}

HashSetOptions :: struct(TItem: Type) {
    capacity: s64 = 8;
    defaultValue: TItem;
    freeItems: bool;
    allocator: Allocator;
    hashFn: (TItem) -> s64;
    equalsFn: (TItem, TItem) -> bool;
}

createHashSet :: ($T: Type, options: HashSetOptions(T)) -> HashSet(T) {
    set: HashSet(T);
    init(*set, options);
    return set;
}

init :: (set: *$T/HashSet, options: HashSetOptions(T.TItem)) {
    assert(options.capacity > 0);
    assert(options.hashFn != null);

    set.capacity = options.capacity;
    set.loadFactor = 0.8;
    set.shift = 29;
    set.defaultValue = options.defaultValue;
    set.freeItems = options.freeItems;
    set.allocator = options.allocator;
    set.hashFn = options.hashFn;
    set.equalsFn = options.equalsFn;
    set.count = 0;
    set.entries = alloc(HashSetEntry(T.TItem), count = set.capacity, allocator = set.allocator);
}

uninit :: (set: *$T/HashSet, freeSet: bool = false) {
    if (set.entries) {
        clear(set);
        free(set.entries, set.allocator);
    }

    if (freeSet) {
        free(set, set.allocator);
    }
}

clear :: (set: *$T/HashSet) {
    assert(set.entries != null);

    #insert #run () -> string {
        info := type_info(T.TItem);

        if (info.type == Type_Info_Tag.POINTER) {
            return #string DONE
                if (set.freeItems) {
                    for i : 0..set.capacity - 1 {
                        entry := *set.entries[i];

                        if (entry.active) {
                            free(entry.item, set.allocator);
                            entry.value = set.defaultValue;
                            entry.active = false;
                        }
                    }
                }
            DONE;
        }

        return "";
    }();

    set.count = 0;
}

contains :: (set: *$T/HashSet, item: T.TItem) -> bool {
    assert(set.entries != null);

    found := getEntry(set, item);
    return found;
}

add :: (set: *$T/HashSet, item: T.TItem) -> bool {
    assert(set.entries != null);

    load := cast(s64) (set.loadFactor * set.capacity);
    if (set.count >= load) {
        resize(set);
    }

    return insert(set, item);
}

removeItem :: (set: *$T/HashSet, item: T.TItem) {
    assert(set.entries != null);

    found, entry, prevEntry := getEntry(set, item);
    if (found) {
        value := entry.item;

        prevEntry.next = entry.next;
        entry.item = set.defaultValue;
        entry.active = false;

        #insert #run () -> string {
            info := type_info(T.TItem);

            if (info.type == Type_Info_Tag.POINTER) {
                return #string DONE
                    if (set.freeItems) {
                        free(value, set.allocator);
                    }
                DONE;
            }

            return "";
        }();

        set.count -= 1;
    }
}

for_expansion :: (set: *$T/HashSet, body: Code, flags: For_Flags) #expand {
    #assert(!(flags & .REVERSE));

    for i : 0..set.capacity - 1 {
        entry := *set.entries[i];
        if (entry.active) {
            #if flags & .POINTER {
                `it := *entry.item;
            } else {
                `it := entry.item;
            }
            #insert (remove=assert(false)) body;
        }
    }
}

#scope_file

#import "utils";

resize :: (set: *$T/HashSet) {
    oldCapacity := set.capacity;
    oldEntries := set.entries;

    set.shift -= 1;
    set.capacity = 1 << (32 - set.shift);
    set.entries = alloc(HashSetEntry(T.TItem), count = set.capacity, allocator = set.allocator);
    set.count = 0;

    for i : 0..oldCapacity - 1 {
        entry := *oldEntries[i];
        if (entry.active) {
            insert(set, entry.item);
        }
    }

    free(oldEntries, set.allocator);
}

insert :: (set: *$T/HashSet, item: T.TItem) -> bool {
    found, entry := getEntry(set, item);
    if (found) {
        return false;
    }

    hash := set.hashFn(item) % set.capacity;

    if (entry.active) {
        next := findEmptyEntry(set, 0);
        assert(next >= 0 && next < set.capacity);

        entry.next = next;

        set.entries[next].active = true;
        set.entries[next].hash = hash;
        set.entries[next].next = -1;
        set.entries[next].item = item;
    } else {
        entry.active = true;
        entry.hash = hash;
        entry.next = -1;
        entry.item = item;
    }

    set.count += 1;
    return true;
}

getEntry :: (set: *$T/HashSet, item: T.TItem) -> bool, *HashSetEntry(T.TItem), *HashSetEntry(T.TItem) {
    found := false;

    hash := set.hashFn(item) % set.capacity;
    index := hash;
    prevIndex := index;

    entry := *set.entries[index];
    prevEntry := entry;
    while (entry.active) {
        if (entry.hash == hash) {
            if (set.equalsFn != null) {
                if (set.equalsFn(entry.item, item)) {
                    found = true;
                    break;
                }
            } else {
                if (entry.item == item) {
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
        entry = *set.entries[index];
    }

    return found, entry, prevEntry;
}

findEmptyEntry :: (set: *$T/HashSet, index: s64) -> s64 {
    for i : 0..set.capacity - 1 {
        entryIndex := (index + i) % set.capacity;
        if (!set.entries[entryIndex].active) {
            return entryIndex;
        }
    }

    return -1;
}
