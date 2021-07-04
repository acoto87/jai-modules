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
// It defines a strongly-typed unordered list of elements and its operations.
// This list has the property that it's stable with respect to the indices of
// its elements. Once an element is added to the list, the position in which
// is assigned won't change until the element is removed from the list.
//
StableList :: struct(TItem: Type) {
    count: s64;
    capacity: s64;
    freeItems: bool;
    freeStart: s64;
    freeEnd: s64;
    allocator: Allocator;
    entries: *StableListEntry(TItem);
}

StableListOptions :: struct(TItem: Type) {
    capacity: s64 = 8;
    freeItems: bool;
    allocator: Allocator;
}

createStableList :: ($T: Type) -> StableList(T) {
    list: StableList(T);
    init(*list);
    return list;
}

createStableList :: ($T: Type, options: StableListOptions(T)) -> StableList(T) {
    list: StableList(T);
    init(*list, options);
    return list;
}

init :: inline (list: *$T/StableList) {
    init(list, StableListOptions(T.TItem).{});
}

init :: (list: *$T/StableList, options: StableListOptions(T.TItem)) {
    assert(options.capacity > 0);

    list.count = 0;
    list.capacity = options.capacity;
    list.freeItems = options.freeItems;
    list.allocator = options.allocator;
    list.entries = alloc(StableListEntry(T.TItem), list.capacity, list.allocator, initialized = false);
    for i : 0..list.capacity-2 {
        list.entries[i].next = i + 1;
    }
    list.entries[list.capacity - 1].next = 0;
    list.freeStart = 0;
    list.freeEnd = list.capacity - 1;
}

uninit :: (list: *$T/StableList, freeList: bool = false) {
    if (list.entries) {
        clear(list);
        free(list.entries, list.allocator);
        free(list.free);
    }

    if (freeList) {
        free(list, list.allocator);
    }
}

clear :: (list: *$T/StableList) {
    assert(list.entries != null);

    #if #run isPointer(T.TItem) {
        if (list.freeItems) {
            for i : 0..list.capacity-1 {
                if (list.entries[i].next < 0) {
                    free(list.entries[i].item, list.allocator);
                }
            }
        }
    }

    for i : 0..list.capacity-2 {
        list.entries[i].next = i + 1;
    }
    list.entries[list.capacity - 1].next = 0;
    list.freeStart = 0;
    list.freeEnd = list.capacity - 1;
    list.count = 0;
}

add :: (list: *$T/StableList, item: T.TItem) -> s64 {
    assert(list.entries != null);

    if (list.freeStart < 0) {
        resize(list, list.count + 1);
    }

    oldFreeStart := list.freeStart;
    if (list.count + 1 < list.capacity) {
        list.freeStart = list.entries[list.freeStart].next;
        list.entries[list.freeEnd].next = list.freeStart;
    } else {
        list.freeStart = -1;
        list.freeEnd = -1;
    }
    list.entries[oldFreeStart].item = item;
    list.entries[oldFreeStart].next = -1;
    list.count += 1;
    return oldFreeStart;
}

addNew :: (list: *$T/StableList) -> s64, *T.TItem {
    assert(list.entries != null);

    if (list.freeStart < 0) {
        resize(list, list.count + 1);
    }

    oldFreeStart := list.freeStart;
    if (list.count + 1 < list.capacity) {
        list.freeStart = list.entries[list.freeStart].next;
        list.entries[list.freeEnd].next = list.freeStart;
    } else {
        list.freeStart = -1;
        list.freeEnd = -1;
    }

    list.entries[oldFreeStart].item = createInstance(T.TItem);
    list.entries[oldFreeStart].next = -1;
    list.count += 1;
    return oldFreeStart, *list.entries[oldFreeStart].item;
}

addRange :: inline (list: *$T/StableList, items: ..T.TItem) {
    for item : items {
        add(list, item);
    }
}

indexOf :: (list: *$T/StableList, item: T.TItem) -> s64 {
    assert(list.entries != null);

    for i : 0..list.capacity - 1 {
        if (list.entries[i].next < 0 && list.entries[i].item == item) {
            return i;
        }
    }

    return -1;
}

indexOf :: (list: *$T/StableList, item: T.TItem, equalsFn: (T.TItem, T.TItem) -> bool) -> s64 {
    assert(list.entries != null);
    assert(equalsFn != null);

    for i : 0..list.capacity - 1 {
        if (list.entries[i].next < 0 && equalsFn(list.entries[i].item, item)) {
            return i;
        }
    }

    return -1;
}

contains :: inline (list: *$T/StableList, item: T.TItem) -> bool {
    return indexOf(list, item) >= 0;
}

contains :: inline (list: *$T/StableList, item: T.TItem, equalsFn: (T.TItem, T.TItem) -> bool) -> bool {
    return indexOf(list, item, equalsFn) >= 0;
}

removeItem :: inline (list: *$T/StableList, item: T.TItem) {
    index := indexOf(list, item);
    if (index >= 0 && index < list.capacity) {
        removeAt(list, index);
    }
}

removeItem :: inline (list: *$T/StableList, item: T.TItem, equalsFn: (T.TItem, T.TItem) -> bool) {
    index := indexOf(list, item, equalsFn);
    if (index >= 0 && index < list.capacity) {
        removeAt(list, index);
    }
}

removeAt :: inline (list: *$T/StableList, index: s64) {
    assert(list.entries != null);
    assert(index >= 0 && index < list.capacity);
    assert(list.entries[index].next < 0);

    #if #run isPointer(T.TItem) {
        if (list.freeItems) {
            free(list.entries[index].item, list.allocator);
        }
    }

    if (list.freeStart >= 0) {
        list.entries[list.freeEnd].next = index;
        list.freeEnd = index;
        list.entries[list.freeEnd].next = list.freeStart;
    } else {
        list.entries[index].next = index;
        list.freeStart = index;
        list.freeEnd = index;
    }
}

isEmpty :: inline (list: *$T/StableList, index: s64) -> bool {
    assert(list.entries != null);
    assert(index >= 0 && index < list.capacity);
    return list.entries[index].next >= 0;
}

ref :: (list: *$T/StableList, index: s64) -> *T.TItem {
    assert(index >= 0 && index < list.capacity);
    assert(list.entries[index].next < 0);
    return *list.entries[index].item;
}

operator [] :: (list: *$T/StableList, index: s64) -> T.TItem {
    assert(index >= 0 && index < list.capacity);
    assert(list.entries[index].next < 0);
    return list.entries[index].item;
}

operator [] :: (list: $T/StableList, index: s64) -> T.TItem {
    assert(index >= 0 && index < list.capacity);
    assert(list.entries[index].next < 0);
    return list.entries[index].item;
}

fromArray :: inline (array: [] $T, options: StableListOptions(T)) -> StableList(T) {
    options.capacity = max(options.capacity, array.count);

    list: StableList(T);
    init(*list, options);
    addRange(*list, ..array);
    return list;
}

toArray :: (list: *$T/StableList) -> [] T.TItem {
    array := allocArray(T.TItem, list.count, list.allocator);
    j := 0;
    for i : 0..list.capacity-1 {
        if (list.entries[i].next < 0) {
            array[j] = list.entries[i].item;
            j += 1;
        }
    }
    return array;
}

for_expansion :: (list: *$T/StableList, body: Code, flags: For_Flags) #expand {
    #assert(!(flags & .REVERSE));

    index := 0;
    while (index < list.capacity) {
        if (list.entries[index].next < 0) {
            #if flags & .POINTER {
                `it := *list.entries[index].item;
            } else {
                `it := list.entries[index].item;
            }
            `it_index := index;

            index += 1;

            #insert (remove=assert(false)) body;
        } else {
            index += 1;
        }
    }
}

#scope_file

#import "utils";

StableListEntry :: struct(TITem: Type) {
    next: s64;      // Index in the list of the next free position if this one is empty.
                    // It will have -1 if this position is occupied.
    item: TITem;    // The item.
}

resize :: (list: *$T/StableList, minSize: s64) {
    oldCapacity := list.capacity;

    list.capacity = oldCapacity * 2;
    if (list.capacity < minSize) {
        list.capacity = minSize;
    }

    list.entries = realloc(list.entries, list.capacity, oldCapacity, list.allocator);

    for i : oldCapacity..list.capacity-2 {
        list.entries[i].next = i + 1;
    }
    list.entries[list.capacity - 1].next = oldCapacity;
    list.freeStart = oldCapacity;
    list.freeEnd = list.capacity - 1;
}
