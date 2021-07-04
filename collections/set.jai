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
HashSet :: struct(TItem: Type, Sorted := false) {
    count: s64;
    capacity: s64;
    loadFactor: f64;
    freeItems: bool;
    #if Sorted {
        firstInOrder: s64;
        lastInOrder: s64;
    }
    allocator: Allocator;
    hashFn: (TItem) -> u64;
    equalsFn: (TItem, TItem) -> bool;
    entries: *HashSetEntry(TItem, Sorted);
}

HashSetOptions :: struct(TItem: Type) {
    capacity: s64 = 8;
    loadFactor: f64 = 0.8;
    freeItems: bool;
    allocator: Allocator;
    hashFn: (TItem) -> u64;
    equalsFn: (TItem, TItem) -> bool;
}

createHashSet :: ($T: Type, $Sorted := false) -> HashSet(T, Sorted) {
    set: HashSet(T, Sorted);
    init(*set);
    return set;
}

createHashSet :: ($T: Type, $Sorted := false, options: HashSetOptions(T)) -> HashSet(T, Sorted) {
    set: HashSet(T, Sorted);
    init(*set, options);
    return set;
}

init :: (set: *$T/HashSet) {
    init(set, HashSetOptions(T.TItem).{});
}

init :: (set: *$T/HashSet, options: HashSetOptions(T.TItem)) {
    assert(options.capacity > 0);
    assert(options.loadFactor > 0 && options.loadFactor <= 1);

    set.count = 0;
    set.capacity = options.capacity;
    set.loadFactor = options.loadFactor;
    set.freeItems = options.freeItems;
    #if T.Sorted {
        set.firstInOrder = -1;
        set.lastInOrder = -1;
    }
    set.allocator = options.allocator;
    set.hashFn = options.hashFn;
    set.equalsFn = options.equalsFn;
    set.entries = alloc(HashSetEntry(T.TItem, T.Sorted), count = set.capacity, allocator = set.allocator);
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

    #if #run isPointer(T.TItem) {
        if (set.freeItems) {
            for i : 0..set.capacity - 1 {
                entry := *set.entries[i];
                if (entry.active) {
                    free(entry.item, set.allocator);
                    entry.value = default_of(T.TItem);
                    entry.active = false;
                }
            }
        }
    }

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

    found, entry := getEntry(set, item);
    if (found) {
        value := entry.item;

        if (entry.prev >= 0) {
            prevEntry := *set.entries[entry.prev];
            prevEntry.next = entry.next;
        }

        if (entry.next >= 0) {
            nextEntry := *set.entries[entry.next];
            nextEntry.prev = entry.prev;
        }

        #if T.Sorted {
            if (entry.prevInOrder >= 0) {
                prevEntryInOrder := *set.entries[entry.prevInOrder];
                prevEntryInOrder.nextInOrder = entry.nextInOrder;
            }

            if (entry.nextInOrder >= 0) {
                nextEntryInOrder := *set.entries[entry.nextInOrder];
                nextEntryInOrder.prevInOrder = entry.prevInOrder;
            }
        }

        entry.item = default_of(T.TItem);
        entry.active = false;

        #if #run isPointer(T.TItem) {
            if (set.freeItems) {
                free(value, set.allocator);
            }
        }

        set.count -= 1;
    }
}

for_expansion :: (set: *$T/HashSet, body: Code, flags: For_Flags) #expand {
    #assert(!(flags & .REVERSE));

    assert(set.entries != null);

    #if T.Sorted {
        index := 0;
        current := set.firstInOrder;
        while (current >= 0) {
            entry := *set.entries[current];
            #if flags & .POINTER {
                `it := *entry.item;
            } else {
                `it := entry.item;
            }
            `it_index := index;

            current = entry.nextInOrder;
            index += 1;

            #insert (remove=assert(false)) body;
        }
    } else {
        index := 0;
        for i : 0..set.capacity-1 {
            entry := *set.entries[i];
            if (!entry.active) {
                continue;
            }
            #if flags & .POINTER {
                `it := *entry.item;
            } else {
                `it := entry.item;
            }
            `it_index := index;

            index += 1;

            #insert (remove=assert(false)) body;
        }
    }
}

#scope_file

#import "utils";

HashSetEntry :: struct(TItem: Type, Sorted := false) {
    active: bool;
    hash: u64;
    idx: s64;
    prev: s64;
    next: s64;
    #if Sorted {
        prevInOrder: s64;
        nextInOrder: s64;
    }
    item: TItem;
}

resize :: (set: *$T/HashSet) {
    oldCapacity := set.capacity;
    oldEntries := set.entries;
    #if T.Sorted {
        oldFirstInOrder := set.firstInOrder;
    }

    set.capacity = oldCapacity * 2;
    set.entries = alloc(HashSetEntry(T.TItem, T.Sorted), count = set.capacity, allocator = set.allocator);
    #if T.Sorted {
        set.firstInOrder = -1;
        set.lastInOrder = -1;
    }
    set.count = 0;

    #if T.Sorted {
        current := oldFirstInOrder;
        while (current >= 0) {
            entry := *oldEntries[current];
            insert(set, entry.item);
            current = entry.nextInOrder;
        }
    } else {
        for i : 0..oldCapacity-1 {
            entry := *oldEntries[i];
            if (entry.active) {
                insert(set, entry.item);
            }
        }
    }

    free(oldEntries, set.allocator);
}

insert :: (set: *$T/HashSet, item: T.TItem) -> bool {
    found, entry := getEntry(set, item);
    if (found) {
        return false;
    }

    hash := hashItem(set, item) % cast(u64) set.capacity;

    if (entry.active) {
        next := findEmptyEntry(set, 0);
        assert(next >= 0 && next < set.capacity);

        entry.next = next;

        nextEntry := *set.entries[next];
        nextEntry.active = true;
        nextEntry.hash = hash;
        nextEntry.idx = next;
        nextEntry.prev = entry.idx;
        nextEntry.next = -1;
        #if T.Sorted {
            nextEntry.prevInOrder = set.lastInOrder;
            nextEntry.nextInOrder = -1;
        }
        nextEntry.item = item;

        #if T.Sorted {
            if (set.lastInOrder >= 0) {
                lastEntryInOrder := *set.entries[set.lastInOrder];
                lastEntryInOrder.nextInOrder = next;
            }

            set.lastInOrder = next;
        }
    } else {
        entry.active = true;
        entry.hash = hash;
        entry.idx = cast(s64) hash;
        entry.prev = -1;
        entry.next = -1;
        #if T.Sorted {
            entry.prevInOrder = set.lastInOrder;
            entry.nextInOrder = -1;
        }
        entry.item = item;

        #if T.Sorted {
            if (set.firstInOrder < 0) {
                set.firstInOrder = cast(s64) hash;
            }

            if (set.lastInOrder >= 0) {
                lastEntryInOrder := *set.entries[set.lastInOrder];
                lastEntryInOrder.nextInOrder = cast(s64) hash;
            }

            set.lastInOrder = cast(s64) hash;
        }
    }

    set.count += 1;
    return true;
}

getEntry :: (set: *$T/HashSet, item: T.TItem) -> bool, *HashSetEntry(T.TItem, T.Sorted) {
    found := false;

    hash := hashItem(set, item) % cast(u64) set.capacity;
    index := cast(s64) hash;

    entry := *set.entries[index];
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

        index = entry.next;
        entry = *set.entries[index];
    }

    return found, entry;
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

hashItem :: (set: *$T/HashSet, item: T.TItem) -> u64 {
    return ifx set.hashFn != null then set.hashFn(item) else defaultHash(item);
}
