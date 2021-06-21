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
SmallHashSet :: struct(TItem: Type, length: s64) {
    count: s64;
    capacity: s64;
    defaultValue: TItem;
    freeItems: bool;
    firstInOrder: s64;
    lastInOrder: s64;
    allocator: Allocator;
    hashFn: (TItem) -> s64;
    equalsFn: (TItem, TItem) -> bool;
    entries: [length] SmallHashSetEntry(TItem);
}

SmallHashSetEntry :: struct(TItem: Type) {
    active: bool;
    hash: s64;
    idx: s64;
    prev: s64;
    next: s64;
    prevInOrder: s64;
    nextInOrder: s64;
    item: TItem;
}

SmallHashSetOptions :: struct(TItem: Type, length: s64) {
    capacity: s64 = 8;
    defaultValue: TItem;
    freeItems: bool;
    allocator: Allocator;
    hashFn: (TItem) -> s64;
    equalsFn: (TItem, TItem) -> bool;
}

createSmallHashSet :: ($T: Type, $length: s64, options: SmallHashSetOptions(T, length)) -> SmallHashSet(T, length) {
    set: SmallHashSet(T, length);
    init(*set, options);
    return set;
}

init :: (set: *$T/SmallHashSet, options: SmallHashSetOptions(T.TItem, T.length)) {
    assert(options.hashFn != null);

    set.capacity = T.length;
    set.defaultValue = options.defaultValue;
    set.freeItems = options.freeItems;
    set.firstInOrder = -1;
    set.lastInOrder = -1;
    set.allocator = options.allocator;
    set.hashFn = options.hashFn;
    set.equalsFn = options.equalsFn;
    set.count = 0;
}

uninit :: (set: *$T/SmallHashSet, freeSet: bool = false) {
    clear(set);

    if (freeSet) {
        free(set, set.allocator);
    }
}

clear :: (set: *$T/SmallHashSet) {
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

contains :: (set: *$T/SmallHashSet, item: T.TItem) -> bool {
    found := getEntry(set, item);
    return found;
}

add :: (set: *$T/SmallHashSet, item: T.TItem) -> bool {
    return insert(set, item);
}

removeItem :: (set: *$T/SmallHashSet, item: T.TItem) {
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

        if (entry.prevInOrder >= 0) {
            prevEntryInOrder := *set.entries[entry.prevInOrder];
            prevEntryInOrder.nextInOrder = entry.nextInOrder;
        }

        if (entry.nextInOrder >= 0) {
            nextEntryInOrder := *set.entries[entry.nextInOrder];
            nextEntryInOrder.prevInOrder = entry.prevInOrder;
        }

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

for_expansion :: (set: *$T/SmallHashSet, body: Code, flags: For_Flags) #expand {
    #assert(!(flags & .REVERSE));

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

        #insert (remove=assert(false)) body;

        current = entry.nextInOrder;
        index += 1;
    }
}

#scope_file

#import "utils";

insert :: (set: *$T/SmallHashSet, item: T.TItem) -> bool {
    found, entry := getEntry(set, item);
    if (found) {
        return false;
    }

    hash := set.hashFn(item) % set.capacity;

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
        nextEntry.prevInOrder = set.lastInOrder;
        nextEntry.nextInOrder = -1;
        nextEntry.item = item;

        if (set.lastInOrder >= 0) {
            lastEntryInOrder := *set.entries[set.lastInOrder];
            lastEntryInOrder.nextInOrder = next;
        }

        set.lastInOrder = next;
    } else {
        entry.active = true;
        entry.hash = hash;
        entry.idx = hash;
        entry.prev = -1;
        entry.next = -1;
        entry.prevInOrder = set.lastInOrder;
        entry.nextInOrder = -1;
        entry.item = item;

        if (set.firstInOrder < 0) {
            set.firstInOrder = hash;
        }

        if (set.lastInOrder >= 0) {
            lastEntryInOrder := *set.entries[set.lastInOrder];
            lastEntryInOrder.nextInOrder = hash;
        }

        set.lastInOrder = hash;
    }

    set.count += 1;
    return true;
}

getEntry :: (set: *$T/SmallHashSet, item: T.TItem) -> bool, *SmallHashSetEntry(T.TItem) {
    found := false;

    hash := set.hashFn(item) % set.capacity;
    index := hash;

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

findEmptyEntry :: (set: *$T/SmallHashSet, index: s64) -> s64 {
    for i : 0..set.capacity - 1 {
        entryIndex := (index + i) % set.capacity;
        if (!set.entries[entryIndex].active) {
            return entryIndex;
        }
    }

    return -1;
}
