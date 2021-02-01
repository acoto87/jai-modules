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
// It defines a strongly-typed list of elements and its operations.
//
List :: struct(TItem: Type) {
    count: s64;
    capacity: s64;
    freeItems: bool;
    allocator: Allocator;
    items: *TItem;
}

ListOptions :: struct(TItem: Type) {
    capacity: s64 = 8;
    freeItems: bool;
    allocator: Allocator;
}

createList :: ($T: Type) -> List(T) {
    list: List(T);
    init(*list);
    return list;
}

createList :: ($T: Type, options: ListOptions(T)) -> List(T) {
    list: List(T);
    init(*list, options);
    return list;
}

init :: inline (list: *$T/List) {
    init(list, ListOptions(T.TItem).{});
}

init :: (list: *$T/List, options: ListOptions(T.TItem)) {
    assert(options.capacity > 0);

    list.count = 0;
    list.capacity = options.capacity;
    list.freeItems = options.freeItems;
    list.allocator = options.allocator;
    list.items = alloc(T.TItem, list.capacity, list.allocator, initialized = false);
}

uninit :: (list: *$T/List, freeList: bool = false) {
    if (list.items) {
        clear(list);
        free(list.items, list.allocator);
    }

    if (freeList) {
        free(list, list.allocator);
    }
}

clear :: (list: *$T/List) {
    assert(list.items != null);

    #insert #run () -> string {
        info := type_info(T.TItem);

        if (info.type == Type_Info_Tag.POINTER) {
            return #string DONE
                if (list.freeItems) {
                    for i : 0..list.count-1 {
                        free(list.items[i], list.allocator);
                    }
                }
            DONE;
        }

        return "";
    }();

    list.count = 0;
}

add :: inline (list: *$T/List, item: T.TItem) {
    insert(list, list.count, item);
}

addNew :: inline (list: *$T/List) -> *T.TItem {
    return insertNew(list, list.count);
}

addRange :: inline (list: *$T/List, items: ..T.TItem) {
    insertRange(list, list.count, ..items);
}

insert :: (list: *$T/List, index: s64, item: T.TItem) {
    assert(list.items != null);
    assert(index >= 0 && index <= list.count);

    newCount := list.count + 1;

    if (newCount > list.capacity) {
        resize(list, newCount);
    }

    i := newCount - 1;
    while (i > index) {
        list.items[i] = list.items[i - 1];
        i -= 1;
    }

    list.items[index] = item;
    list.count = newCount;
}

insertNew :: (list: *$T/List, index: s64) -> *T.TItem {
    assert(list.items != null);
    assert(index >= 0 && index <= list.count);

    newCount := list.count + 1;

    if (newCount > list.capacity) {
        resize(list, newCount);
    }

    i := newCount - 1;
    while (i > index) {
        list.items[i] = list.items[i - 1];
        i -= 1;
    }

    #insert #run () -> Code {
        info := type_info(T.TItem);

        if (info.type == Type_Info_Tag.POINTER) {
            return #code item := alloc(T.TItem);
        } else {
            return #code item: T.TItem;
        }
    }();

    list.items[index] = item;
    list.count = newCount;

    return *list.items[index];
}

insertRange :: (list: *$T/List, index: s64, items: ..T.TItem) {
    assert(list.items != null);
    assert(index >= 0 && index <= list.count);

    if (items.count == 0) {
        return;
    }

    newCount := list.count + items.count;

    if (newCount > list.capacity) {
        resize(list, newCount);
    }

    memoryMove(list.items + index + items.count, list.items + index, list.count - index);
    memoryCopy(list.items + index, items.data, items.count);

    list.count = newCount;
}

indexOf :: (list: *$T/List, item: T.TItem) -> s64 {
    assert(list.items != null);

    for i : 0..list.count - 1 {
        if (list.items[i] == item) {
            return i;
        }
    }

    return -1;
}

indexOf :: (list: *$T/List, item: T.TItem, equalsFn: (T.TItem, T.TItem) -> bool) -> s64 {
    assert(list.items != null);
    assert(equalsFn != null);

    for i : 0..list.count - 1 {
        if (equalsFn(list.items[i], item)) {
            return i;
        }
    }

    return -1;
}

contains :: inline (list: *$T/List, item: T.TItem) -> bool {
    return indexOf(list, item) >= 0;
}

contains :: inline (list: *$T/List, item: T.TItem, equalsFn: (T.TItem, T.TItem) -> bool) -> bool {
    return indexOf(list, item, equalsFn) >= 0;
}

removeItem :: inline (list: *$T/List, item: T.TItem) {
    index := indexOf(list, item);
    if (index >= 0 && index < list.count) {
        removeAt(list, index);
    }
}

removeItem :: inline (list: *$T/List, item: T.TItem, equalsFn: (T.TItem, T.TItem) -> bool) {
    index := indexOf(list, item, equalsFn);
    if (index >= 0 && index < list.count) {
        removeAt(list, index);
    }
}

removeAt :: inline (list: *$T/List, index: s64) {
    removeAtRange(list, index, 1);
}

removeAtRange :: (list: *$T/List, index: s64, count: s64) {
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

    #insert #run () -> string {
        info := type_info(T.TItem);

        if (info.type == Type_Info_Tag.POINTER) {
            return #string DONE
                if (list.freeItems) {
                    for i : index..index+count-1 {
                        free(list.items[i], list.allocator);
                    }
                }
            DONE;
        }

        return "";
    }();

    memoryMove(list.items + index, list.items + index + count, list.count - index - count);
    list.count = list.count - count;
}

reverse :: (list: *$T/List) {
    assert(list.items != null);

    i := 0;
    j := list.count - 1;
    while (i < j)
    {
        tmp := list.items[i];
        list.items[i] = list.items[j];
        list.items[j] = tmp;

        i += 1;
        j -= 1;
    }
}

sort :: (list: *$T/List, compareFn: (T.TItem, T.TItem) -> s64) {
    qsort(list.items, 0, list.count - 1, compareFn);
}

sort :: (list: *$T/List, byFn: (T.TItem) -> $R) {
    qsort(list.items, 0, list.count - 1, byFn);
}

ref :: (list: *$T/List, index: s64) -> *T.TItem {
    assert(index >= 0 && index < list.count);
    return *list.items[index];
}

operator [] :: (list: *$T/List, index: s64) -> T.TItem {
    assert(index >= 0 && index < list.count);
    return list.items[index];
}

operator [] :: (list: $T/List, index: s64) -> T.TItem {
    assert(index >= 0 && index < list.count);
    return list.items[index];
}

fromArray :: inline (array: [] $T, options: ListOptions) -> List(T) {
    options.capacity = max(options.capacity, array.count);

    list: List(T);
    init(*list, options);
    addRange(*list, ..array);
    return list;
}

toArray :: (list: *$T/List) -> [] T.TItem {
    array := allocArray(T.TItem, list.count, list.allocator);
    memoryCopy(array.data, list.items, list.count);
    return array;
}

for_expansion :: (list: *$T/List, body: Code, flags: For_Flags) #expand {
    #assert(!(flags & .REVERSE));

    for i : 0..list.count-1 {
        #if flags & .POINTER {
            `it := *list.items[i];
        } else {
            `it := list.items[i];
        }
        `it_index := i;

        #insert (remove=assert(false)) body;
    }
}

#scope_file

#import "utils";

resize :: (list: *$T/List, minSize: s64) {
    oldCapacity := list.capacity;

    list.capacity = oldCapacity * 2;
    if (list.capacity < minSize) {
        list.capacity = minSize;
    }

    list.items = realloc(list.items, list.capacity, oldCapacity, list.allocator);
}
