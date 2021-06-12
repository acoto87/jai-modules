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
//
SmallList :: struct(TItem: Type, length: s64) {
    count: s64;
    capacity: s64;
    freeItems: bool;
    allocator: Allocator;
    items: [length] TItem;
}

SmallListOptions :: struct(TItem: Type, length: s64) {
    freeItems: bool;
    allocator: Allocator;
}

createList :: inline ($T: Type, $length: s64) -> SmallList(T, length) {
    list: SmallList(T, length);
    init(*list);
    return list;
}

createList :: inline ($T: Type, $length: s64, options: SmallListOptions(T, length)) -> SmallList(T, length) {
    list: SmallList(T, length);
    init(*list, options);
    return list;
}

init :: inline (list: *$T/SmallList) {
    init(list, SmallListOptions(T.TItem, T.length).{});
}

init :: (list: *$T/SmallList, options: SmallListOptions(T.TItem, T.length)) {
    list.count = 0;
    list.capacity = T.length;
    list.freeItems = options.freeItems;
    list.allocator = options.allocator;
}

uninit :: (list: *$T/SmallList, freeList: bool = false) {
    clear(list);

    if (freeList) {
        free(list, list.allocator);
    }
}

clear :: (list: *$T/SmallList) {
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

add :: inline (list: *$T/SmallList, item: T.TItem) {
    assert(list.count < list.capacity);
    insert(list, list.count, item);
}

addNew :: inline (list: *$T/SmallList) -> *T.TItem {
    assert(list.count < list.capacity);
    return insertNew(list, list.count);
}

addRange :: inline (list: *$T/SmallList, items: ..T.TItem) {
    assert(list.count + items.count <= list.capacity);
    insertRange(list, list.count, ..items);
}

insert :: (list: *$T/SmallList, index: s64, item: T.TItem) {
    assert(list.count < list.capacity);
    assert(index >= 0 && index <= list.count);

    memoryMove(list.items.data + index + 1, list.items.data + index, list.count - index);

    list.items[index] = item;
    list.count += 1;
}

insertNew :: (list: *$T/SmallList, index: s64) -> *T.TItem {
    assert(list.count < list.capacity);
    assert(index >= 0 && index <= list.count);

    memoryMove(list.items.data + index + 1, list.items.data + index, list.count - index);

    #insert #run () -> Code {
        info := type_info(T.TItem);

        if (info.type == Type_Info_Tag.POINTER) {
            return #code item := alloc(T.TItem, list.allocator);
        } else {
            return #code item: T.TItem;
        }
    }();

    list.items[index] = item;
    list.count += 1;

    return *list.items[index];
}

insertRange :: (list: *$T/SmallList, index: s64, items: ..T.TItem) {
    assert(list.count + items.count <= list.capacity);
    assert(index >= 0 && index <= list.count);

    if (items.count == 0) {
        return;
    }

    memoryMove(list.items.data + index + items.count, list.items.data + index, list.count - index);
    memoryCopy(list.items.data + index, items.data, items.count);

    list.count += items.count;
}

indexOf :: (list: *$T/SmallList, item: T.TItem) -> s64 {
    for i : 0..list.count-1 {
        if (list.items[i] == item) {
            return i;
        }
    }

    return -1;
}

indexOf :: (list: *$T/SmallList, item: T.TItem, equalsFn: (T.TItem, T.TItem) -> bool) -> s64 {
    assert(equalsFn != null);

    for i : 0..list.count-1 {
        if (equalsFn(list.items[i], item)) {
            return i;
        }
    }

    return -1;
}

contains :: inline (list: *$T/SmallList, item: T.TItem) -> bool {
    return indexOf(list, item) >= 0;
}

contains :: inline (list: *$T/SmallList, item: T.TItem, equalsFn: (T.TItem, T.TItem) -> bool) -> bool {
    return indexOf(list, item, equalsFn) >= 0;
}

removeItem :: inline (list: *$T/SmallList, item: T.TItem) {
    index := indexOf(list, item);
    if (index >= 0 && index < list.count) {
        removeAt(list, index);
    }
}

removeItem :: inline (list: *$T/SmallList, item: T.TItem, equalsFn: (T.TItem, T.TItem) -> bool) {
    index := indexOf(list, item, equalsFn);
    if (index >= 0 && index < list.count) {
        removeAt(list, index);
    }
}

removeAt :: inline (list: *$T/SmallList, index: s64) {
    removeAtRange(list, index, 1);
}

removeAtRange :: (list: *$T/SmallList, index: s64, count: s64) {
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

    memoryMove(list.items.data + index, list.items.data + index + count, list.count - index - count);
    list.count = list.count - count;
}

reverse :: (list: *$T/SmallList) {
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

sort :: inline (list: *$T/SmallList, compareFn: (T.TItem, T.TItem) -> s64) {
    qsort(list.items, 0, list.count - 1, compareFn);
}

sort :: inline (list: *$T/SmallList, byFn: (T.TItem) -> $R) {
    qsort(list.items, 0, list.count - 1, byFn);
}

ref :: inline (list: *$T/SmallList, index: s64) -> *T.TItem {
    assert(index >= 0 && index < list.count);
    return *list.items[index];
}

operator [] :: (list: *$T/SmallList, index: s64) -> T.TItem {
    assert(index >= 0 && index < list.count);
    return list.items[index];
}

operator [] :: (list: $T/SmallList, index: s64) -> T.TItem {
    assert(index >= 0 && index < list.count);
    return list.items[index];
}

toArray :: (list: *$T/SmallList) -> [] T.TItem {
    array := allocArray(T.TItem, list.count, list.allocator);
    memoryCopy(array.data, list.items, list.count);
    return array;
}

for_expansion :: (list: *$T/SmallList, body: Code, flags: For_Flags) #expand {
    #assert(!(flags & .REVERSE));

    index := 0;
    while (index < list.count) {
        #if flags & .POINTER {
            `it := *list.items[index];
        } else {
            `it := list.items[index];
        }
        `it_index := index;

        #insert (remove=assert(false)) body;
        index += 1;
    }
}

#scope_file

#import "utils";
