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
// It defines a strongly-typed unordered list of elements and its operations.
// This list has the property that it's stable with respect to the indices of
// its elements. Once an element is added to the list, the position in which
// is assigned won't change until the element is removed from the list.
//
StableList :: struct(TItem: Type) {
    count: s64;
    capacity: s64;
    freeItems: bool;
    allocator: Allocator;
    items: *TItem;
    freeStart: s64;
    freeEnd: s64;
    free: *s64;
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
    list.items = alloc(T.TItem, list.capacity, list.allocator, initialized = false);
    list.free = alloc(s64, list.capacity, list.allocator, initialized = false);
    for i : 0..list.capacity-2 {
        list.free[i] = i + 1;
    }
    list.free[list.capacity-1] = 0;
    list.freeStart = 0;
    list.freeEnd = list.capacity-1;
}

uninit :: (list: *$T/StableList, freeList: bool = false) {
    if (list.items) {
        clear(list);
        free(list.items, list.allocator);
        free(list.free);
    }

    if (freeList) {
        free(list, list.allocator);
    }
}

clear :: (list: *$T/StableList) {
    assert(list.items != null);

    #insert #run () -> string {
        info := type_info(T.TItem);

        if (info.type == Type_Info_Tag.POINTER) {
            return #string DONE
                if (list.freeItems) {
                    for i : 0..list.capacity-1 {
                        if (list.free[i] < 0) {
                            free(list.items[i], list.allocator);
                        }
                    }
                }
            DONE;
        }

        return "";
    }();

    for i : 0..list.capacity-2 {
        list.free[i] = i + 1;
    }
    list.free[list.capacity-1] = 0;
    list.freeStart = 0;
    list.freeEnd = list.capacity-1;
    list.count = 0;
}

add :: (list: *$T/StableList, item: T.TItem) -> s64 {
    assert(list.items != null);

    if (list.freeStart < 0) {
        resize(list, list.count + 1);
    }

    oldFreeStart := list.freeStart;
    if (list.count + 1 < list.capacity) {
        list.freeStart = list.free[list.freeStart];
        list.free[list.freeEnd] = list.freeStart;
    } else {
        list.freeStart = -1;
        list.freeEnd = -1;
    }
    list.items[oldFreeStart] = item;
    list.free[oldFreeStart] = -1;
    list.count += 1;
    return oldFreeStart;
}

addNew :: (list: *$T/StableList) -> s64, *T.TItem {
    assert(list.items != null);

    if (list.freeStart < 0) {
        resize(list, list.count + 1);
    }

    oldFreeStart := list.freeStart;
    if (list.count + 1 < list.capacity) {
        list.freeStart = list.free[list.freeStart];
        list.free[list.freeEnd] = list.freeStart;
    } else {
        list.freeStart = -1;
        list.freeEnd = -1;
    }

    #insert #run () -> Code {
        info := type_info(T.TItem);

        if (info.type == Type_Info_Tag.POINTER) {
            return #code item := alloc(T.TItem);;
        } else {
            return #code item: T.TItem;;
        }
    }();

    list.items[oldFreeStart] = item;
    list.free[oldFreeStart] = -1;
    list.count += 1;
    return oldFreeStart, *list.items[oldFreeStart];
}

addRange :: inline (list: *$T/StableList, items: ..T.TItem) {
    for item : items {
        add(list, item);
    }
}

indexOf :: (list: *$T/StableList, item: T.TItem) -> s64 {
    assert(list.items != null);

    for i : 0..list.capacity - 1 {
        a := list.items[i];
        f := list.free[i];
        if (list.free[i] < 0 && list.items[i] == item) {
            return i;
        }
    }

    return -1;
}

indexOf :: (list: *$T/StableList, item: T.TItem, equalsFn: (T.TItem, T.TItem) -> bool) -> s64 {
    assert(list.items != null);
    assert(equalsFn != null);

    for i : 0..list.capacity - 1 {
        if (list.free[i] < 0 && equalsFn(list.items[i], item)) {
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
    assert(list.items != null);
    assert(index >= 0 && index < list.capacity);
    assert(list.free[index] < 0);

    #insert #run () -> string {
        info := type_info(T.TItem);

        if (info.type == Type_Info_Tag.POINTER) {
            return #string DONE
                if (list.freeItems) {
                    free(list.items[index], list.allocator);
                }
            DONE;
        }

        return "";
    }();

    if (list.freeStart >= 0) {
        list.free[list.freeEnd] = index;
        list.freeEnd = index;
        list.free[list.freeEnd] = list.freeStart;
    } else {
        list.free[index] = index;
        list.freeStart = index;
        list.freeEnd = index;
    }
}

isEmpty :: inline (list: *$T/StableList, index: s64) -> bool {
    assert(list.items != null);
    assert(index >= 0 && index < list.capacity);
    return list.free[index] >= 0;
}

ref :: (list: *$T/StableList, index: s64) -> *T.TItem {
    assert(index >= 0 && index < list.capacity);
    assert(list.free[index] < 0);
    return *list.items[index];
}

operator [] :: (list: *$T/StableList, index: s64) -> T.TItem {
    assert(index >= 0 && index < list.capacity);
    assert(list.free[index] < 0);
    return list.items[index];
}

operator [] :: (list: $T/List, index: s64) -> T.TItem {
    assert(index >= 0 && index < list.capacity);
    assert(list.free[index] < 0);
    return list.items[index];
}

fromArray :: inline (array: [] $T, options: StableListOptions(T)) -> List(T) {
    options.capacity = max(options.capacity, array.count);

    list: List(T);
    init(*list, options);
    addRange(*list, ..array);
    return list;
}

toArray :: (list: *$T/StableList) -> [] T.TItem {
    array := allocArray(T.TItem, list.count, list.allocator);
    j := 0;
    for i : 0..list.capacity-1 {
        if (list.free[i] < 0) {
            array[j] = list.items[i];
            j += 1;
        }
    }
    return array;
}

for_expansion :: (list: *$T/StableList, body: Code, flags: For_Flags) #expand {
    #assert(!(flags & .REVERSE));

    for i : 0..list.capacity-1 {
        if (list.free[i] < 0) {
            #if flags & .POINTER {
                `it := *list.items[i];
            } else {
                `it := list.items[i];
            }
            `it_index := i;

            #insert (remove=assert(false)) body;
        }
    }
}

#scope_file

#import "utils";

resize :: (list: *$T/StableList, minSize: s64) {
    oldCapacity := list.capacity;

    list.capacity = oldCapacity * 2;
    if (list.capacity < minSize) {
        list.capacity = minSize;
    }

    list.items = realloc(list.items, list.capacity, oldCapacity, list.allocator);
    list.free = realloc(list.free, list.capacity, oldCapacity, list.allocator);

    for i : oldCapacity..list.capacity-2 {
        list.free[i] = i + 1;
    }
    list.free[list.capacity-1] = oldCapacity;
    list.freeStart = oldCapacity;
    list.freeEnd = list.capacity-1;
}
