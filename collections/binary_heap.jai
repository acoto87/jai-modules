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
// It defines a strongly-typed binary heap of elements and its operations.
//
BinaryHeap :: struct(TItem: Type) {
    count: s64;
    capacity: s64;
    freeItems: bool;
    allocator: Allocator;
    compareFn: (TItem, TItem) -> s64;
    items: *TItem;
}

BinaryHeapOptions :: struct(TItem: Type) {
    capacity: s64 = 8;
    freeItems: bool;
    allocator: Allocator;
    compareFn: (a: TItem, b: TItem) -> s64;
}

init :: (heap: *$T/BinaryHeap) {
    init(heap, BinaryHeapOptions(T.TItem).{
        compareFn = (a: TItem, b: TItem) -> s64 { return a - b; }
    });
}

init :: (heap: *$T/BinaryHeap, options: BinaryHeapOptions(T.TItem)) {
    assert(options.capacity > 0);
    assert(options.compareFn != null);

    heap.count = 0;
    heap.capacity = options.capacity;
    heap.allocator = options.allocator;
    heap.compareFn = options.compareFn;
    heap.items = alloc(T.TItem, heap.capacity, heap.allocator, initialized = false);
}

uninit :: (heap: *$T/BinaryHeap, freePointer: bool = false) {
    if (heap.items) {
        clear(heap);
        free(heap.items, heap.allocator);
        heap.items = null;
    }

    if (freePointer) {
        free(heap, heap.allocator);
    }
}

clear :: (heap: *$T/BinaryHeap) {
    assert(heap.items != null);

    #insert #run () -> string {
        info := type_info(T);

        if (info.type == Type_Info_Tag.POINTER) {
            return #string DONE
                if (heap.freeItems) {
                    for i : 0..heap.count-1 {
                        free(heap.items[i], heap.allocator);
                    }
                }
            DONE;
        }

        return "";
    }();

    heap.count = 0;
}

push :: (heap: *$T/BinaryHeap, item: T.TItem) {
    assert(heap.items != null);

    if (heap.count + 1 >= heap.capacity) {
        resize(heap);
    }

    heap.items[heap.count] = item;
    heapUp(heap, heap.count);
    heap.count += 1;
}

peek :: (heap: *$T/BinaryHeap) -> T.TItem {
    assert(heap.items != null);
    assert(heap.count > 0);

    return heap.items[0];
}

pop :: (heap: *$T/BinaryHeap) -> T.TItem {
    assert(heap.items != null);
    assert(heap.count > 0);

    item := heap.items[0];

    heap.items[0] = heap.items[heap.count - 1];
    heap.count -= 1;
    heapDown(heap, 0);

    return item;
}

indexOf :: (heap: *$T/BinaryHeap, item: T.TItem) -> s64 {
    assert(heap.items != null);

    for i : 0..heap.count-1 {
        if (heap.compareFn(heap.items[i], item) == 0) {
            return i;
        }
    }

    return -1;
}

contains :: (heap: *$T/BinaryHeap, item: T.TItem) -> bool {
    return indexOf(heap, item) >= 0;
}

update :: (heap: *$T/BinaryHeap, index: s64, newItem: T.TItem) {
    assert(heap.items != null);
    assert(index >= 0 && index < heap.count);

    oldItem := heap.items[index];
    heap.items[index] = newItem;
    cmpValue := heap.compareFn(oldItem, newItem);
    if (cmpValue < 0) {
        heapUp(heap, index);
    } else if (cmpValue > 0) {
        heapDown(heap, index);
    }

}

#scope_file

#import "utils";

resize :: (heap: *$T/BinaryHeap) {
    oldCapacity := heap.capacity;

    heap.capacity = oldCapacity * 2;
    heap.items = realloc(heap.items, heap.capacity, oldCapacity, heap.allocator);
}

heapUp :: (heap: *$T/BinaryHeap, index: s64) {
    pIndex := (index - 1) >> 1;
    while (index > 0 && heap.compareFn(heap.items[index], heap.items[pIndex]) < 0) {
        tmp := heap.items[index];
        heap.items[index] = heap.items[pIndex];
        heap.items[pIndex] = tmp;

        index = pIndex;
        pIndex = (index - 1) >> 1;
    }
}

heapDown :: (heap: *$T/BinaryHeap, index: s64) {
    while (index < heap.count) {
        item := heap.items[index];

        leftIndex := 2 * index + 1;
        if (leftIndex >= heap.count) {
            break;
        }

        minIndex := leftIndex;
        minItem := heap.items[minIndex];

        rightIndex := 2 * index + 2;
        if (rightIndex < heap.count) {
            rightItem := heap.items[rightIndex];
            if (heap.compareFn(rightItem, minItem) < 0) {
                minIndex = rightIndex;
                minItem = rightItem;
            }
        }

        if (heap.compareFn(minItem, item) >= 0) {
            break;
        }

        tmp := heap.items[index];
        heap.items[index] = heap.items[minIndex];
        heap.items[minIndex] = tmp;

        index = minIndex;
    }
}
