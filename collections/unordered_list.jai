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
// It defines a strongly-typed list of elements and its operations.
// This list doesn't mantain order, when an item is removed,
// the last item on the list is moved to the deleted position.
//
UnorderedList :: struct(TItem: Type) {
    count: s64;
    capacity: s64;
    freeItems: bool;
    allocator: Allocator;
    items: *TItem;
}

UnorderedListOptions :: struct(TItem: Type) {
    capacity: s64 = 8;
    freeItems: bool;
    allocator: Allocator;
}

createUnorderedList :: inline ($T: Type) -> UnorderedList(T) {
    list: UnorderedList(T);
    init(*list);
    return list;
}

createUnorderedList :: inline ($T: Type, capacity: s64) -> UnorderedList(T) {
    list: UnorderedList(T);
    init(*list, capacity);
    return list;
}

createUnorderedList :: inline ($T: Type, options: UnorderedListOptions(T)) -> UnorderedList(T) {
    list: UnorderedList(T);
    init(*list, options);
    return list;
}

init :: inline (list: *$T/UnorderedList) {
    init(list, UnorderedListOptions(T.TItem).{});
}

init :: inline (list: *$T/UnorderedList, capacity: s64) {
    options: UnorderedListOptions(T.TItem);
    options.capacity = capacity;
    init(list, options);
}

init :: (list: *$T/UnorderedList, options: UnorderedListOptions(T.TItem)) {
    assert(options.capacity > 0);

    list.count = 0;
    list.capacity = options.capacity;
    list.freeItems = options.freeItems;
    list.allocator = options.allocator;
    list.items = alloc(T.TItem, list.capacity, list.allocator, initialized = false);
}

uninit :: (list: *$T/UnorderedList, freeList: bool = false) {
    if (list.items) {
        clear(list);
        free(list.items, list.allocator);
    }

    if (freeList) {
        free(list, list.allocator);
    }
}

clear :: (list: *$T/UnorderedList) {
    assert(list.items != null);

    #if #run isPointer(T.TItem) {
        if (list.freeItems) {
            for i : 0..list.count-1 {
                free(list.items[i], list.allocator);
            }
        }
    }

    list.count = 0;
}

add :: inline (list: *$T/UnorderedList, item: T.TItem) {
    insert(list, list.count, item);
}

addNew :: inline (list: *$T/UnorderedList) -> *T.TItem {
    return insertNew(list, list.count);
}

addRange :: inline (list: *$T/UnorderedList, items: ..T.TItem) {
    insertRange(list, list.count, ..items);
}

addRange :: inline (list: *$T/UnorderedList, other: *List(T.TItem)) {
    insertRange(list, list.count, other);
}

addRange :: inline (list: *$T/UnorderedList, items: *T.TItem, count: s64) {
    insertRange(list, list.count, items, count);
}

insert :: (list: *$T/UnorderedList, index: s64, item: T.TItem) {
    assert(list.items != null);
    assert(index >= 0 && index <= list.count);

    newCount := list.count + 1;

    if (newCount > list.capacity) {
        resize(list, newCount);
    }

    memoryMove(list.items + index + 1, list.items + index, list.count - index);

    list.items[index] = item;
    list.count = newCount;
}

insertNew :: (list: *$T/UnorderedList, index: s64) -> *T.TItem {
    assert(list.items != null);
    assert(index >= 0 && index <= list.count);

    newCount := list.count + 1;

    if (newCount > list.capacity) {
        resize(list, newCount);
    }

    memoryMove(list.items + index + 1, list.items + index, list.count - index);

    list.items[index] = createInstance(T.TItem);
    list.count = newCount;

    return *list.items[index];
}

insertRange :: inline (list: *$T/UnorderedList, index: s64, items: ..T.TItem) {
    insertRange(list, index, items.data, items.count);
}

insertRange :: inline (list: *$T/UnorderedList, index: s64, other: *List(T.TItem)) {
    insertRange(list, index, other.items, other.count);
}

insertRange :: (list: *$T/UnorderedList, index: s64, items: *T.TItem, count: s64) {
    assert(list.items != null);
    assert(index >= 0 && index <= list.count);

    if (count == 0) {
        return;
    }

    newCount := list.count + count;

    if (newCount > list.capacity) {
        resize(list, newCount);
    }

    memoryMove(list.items + index + count, list.items + index, list.count - index);
    memoryCopy(list.items + index, items, count);

    list.count = newCount;
}

indexOf :: (list: *$T/UnorderedList, item: T.TItem) -> s64 {
    assert(list.items != null);

    for i : 0..list.count - 1 {
        if (list.items[i] == item) {
            return i;
        }
    }

    return -1;
}

indexOf :: (list: *$T/UnorderedList, item: T.TItem, equalsFn: (T.TItem, T.TItem) -> bool) -> s64 {
    assert(list.items != null);
    assert(equalsFn != null);

    for i : 0..list.count - 1 {
        if (equalsFn(list.items[i], item)) {
            return i;
        }
    }

    return -1;
}

contains :: inline (list: *$T/UnorderedList, item: T.TItem) -> bool {
    return indexOf(list, item) >= 0;
}

contains :: inline (list: *$T/UnorderedList, item: T.TItem, equalsFn: (T.TItem, T.TItem) -> bool) -> bool {
    return indexOf(list, item, equalsFn) >= 0;
}

removeItem :: inline (list: *$T/UnorderedList, item: T.TItem) {
    index := indexOf(list, item);
    if (index >= 0 && index < list.count) {
        removeAt(list, index);
    }
}

removeItem :: inline (list: *$T/UnorderedList, item: T.TItem, equalsFn: (T.TItem, T.TItem) -> bool) {
    index := indexOf(list, item, equalsFn);
    if (index >= 0 && index < list.count) {
        removeAt(list, index);
    }
}

removeAt :: inline (list: *$T/UnorderedList, index: s64) {
    removeAtRange(list, index, 1);
}

removeAtRange :: (list: *$T/UnorderedList, index: s64, count: s64) {
    assert(list.items != null);
    assert(index >= 0 && index < list.count);

    if (count <= 0) {
        return;
    }

    if (index + count > list.count) {
        count = list.count - index;
    }

    if (index == 0 && count == list.count) {
        list.count = 0;
        return;
    }

    #if #run isPointer(T.TItem) {
        if (list.freeItems) {
            for i : index..index + count - 1 {
                free(list.items[i], list.allocator);
            }
        }
    }

    if (index < list.count - 1) {
        memoryMove(list.items + index, list.items + list.count - count, count);
    }

    list.count -= count;
}

reverse :: (list: *$T/UnorderedList) {
    assert(list.items != null);

    i := 0;
    j := list.count - 1;
    while (i < j) {
        tmp := list.items[i];
        list.items[i] = list.items[j];
        list.items[j] = tmp;

        i += 1;
        j -= 1;
    }
}

sort :: inline (list: *$T/UnorderedList, compareFn: (T.TItem, T.TItem) -> s64) {
    assert(list.items != null);
    qsort(list.items, 0, list.count - 1, compareFn);
}

sort :: inline (list: *$T/UnorderedList, byFn: (T.TItem) -> $R) {
    assert(list.items != null);
    qsort(list.items, 0, list.count - 1, byFn);
}

get :: inline (list: *$T/UnorderedList, index: s64) -> T.TItem {
    assert(list.items != null);
    assert(index >= 0 && index < list.count);
    return list.items[index];
}

ref :: inline (list: *$T/UnorderedList, index: s64) -> *T.TItem {
    assert(list.items != null);
    assert(index >= 0 && index < list.count);
    return *list.items[index];
}

set :: inline (list: *$T/UnorderedList, index: s64, item: T.TItem) {
    assert(list.items != null);
    assert(index >= 0 && index < list.count);

    #if #run isPointer(T.TItem) {
        if (list.freeItems) {
            free(list.items[index], list.allocator);
        }
    }

    list.items[index] = item;
}

fromArray :: inline (array: [] $T, options: UnorderedListOptions(T)) -> UnorderedList(T) {
    list: List(T);
    init(*list, options);
    addRange(*list, ..array);
    return list;
}

toArray :: (list: *$T/UnorderedList, array: [] T.TItem, index: s64 = 0) {
    assert(list.items != null);
    assert(array.count - index >= list.count);
    memoryCopy(array.data + index, list.items, list.count);
    return array;
}

for_expansion :: (list: *$T/UnorderedList, body: Code, flags: For_Flags) #expand {
    #assert(!(flags & .REVERSE));

    assert(list.items != null);

    index := 0;
    while (index < list.count) {
        #if flags & .POINTER {
            `it := *list.items[index];
        } else {
            `it := list.items[index];
        }
        `it_index := index;

        index += 1;

        #insert (remove=assert(false)) body;
    }
}

reserve :: inline (list: *$T/UnorderedList, capacity: s64) {
    if (capacity > list.capacity) {
        resize(list, capacity);
    }
}

#scope_file

#import "utils";

resize :: (list: *$T/UnorderedList, minCapacity: s64) {
    oldCapacity := list.capacity;

    list.capacity = oldCapacity * 2;
    if (list.capacity < minCapacity) {
        list.capacity = minCapacity;
    }

    list.items = realloc(list.items, list.capacity, oldCapacity, list.allocator);
    assert(list.items != null);
}
