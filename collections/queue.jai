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
// It defines a strongly-typed queue of elements and its operations.
//
Queue :: struct(TItem: Type) {
    head: s64;
    tail: s64;
    count: s64;
    capacity: s64;
    freeItems: bool;
    allocator: Allocator;
    items: *TItem;
}

QueueOptions :: struct(TItem: Type) {
    capacity: s64 = 8;
    freeItems: bool;
    allocator: Allocator;
}

createQueue :: inline ($T: Type) -> Queue(T) {
    queue: Queue(T);
    init(*queue);
    return queue;
}

createQueue :: inline ($T: Type, capacity: s64) -> Queue(T) {
    queue: Queue(T);
    init(*queue, capacity);
    return queue;
}

createQueue :: inline ($T: Type, options: QueueOptions(T)) -> Queue(T) {
    queue: Queue(T);
    init(*queue, options);
    return queue;
}

init :: inline (queue: *$T/Queue) {
    init(queue, QueueOptions(T.TItem).{});
}

init :: inline (queue: *$T/Queue, capacity: s64) {
    options: QueueOptions(T.TItem);
    options.capacity = capacity;
    init(queue, options);
}

init :: (queue: *$T/Queue, options: QueueOptions(T.TItem)) {
    //assert(options.capacity > 0);

    queue.head = 0;
    queue.tail = 0;
    queue.count = 0;
    queue.capacity = options.capacity;
    queue.freeItems = options.freeItems;
    queue.allocator = options.allocator;
    queue.items = alloc(T.TItem, queue.capacity, queue.allocator, initialized = false);
}

uninit :: (queue: *$T/Queue, freeQueue: bool = false) {
    if (queue.items) {
        clear(queue);
        free(queue.items, queue.allocator);
    }

    if (freeQueue) {
        free(queue, queue.allocator);
    }
}

clear :: (queue: *$T/Queue) {
    assert(queue.items != null);

    #insert #run () -> string {
        info := type_info(T.TItem);

        if (info.type == Type_Info_Tag.POINTER) {
            return #string DONE
                if (queue.freeItems) {
                    for i : 0..queue.count-1 {
                        free(queue.items[(queue.head + i) % queue.capacity], queue.allocator);
                    }
                }
            DONE;
        }

        return "";
    }();

    queue.count = 0;
}

push :: (queue: *$T/Queue, item: T.TItem) {
    assert(queue.items != null);

    if (queue.count == queue.capacity) {
        resize(queue);
    }

    queue.items[queue.tail] = item;
    queue.tail += 1;
    if (queue.tail >= queue.capacity) {
        queue.tail = 0;
    }
    queue.count += 1;
}

pop :: (queue: *$T/Queue) -> T.TItem {
    assert(queue.items != null);
    assert(queue.count > 0);

    item := queue.items[queue.head];
    queue.head += 1;
    if (queue.head >= queue.capacity) {
        queue.head = 0;
    }
    queue.count -= 1;
    return item;
}

peek :: (queue: *$T/Queue) -> T.TItem {
    assert(queue.items != null);
    assert(queue.count > 0);

    return queue.items[queue.head];
}

indexOf :: (queue: *$T/Queue, item: T.TItem) -> s64 {
    assert(queue.items != null);

    index := 0;
    current := queue.head;
    while (index < queue.count) {
        if (queue.items[current] == item) {
            return index;
        }
        index += 1;
        current += 1;
        if (current >= queue.capacity) {
            current = 0;
        }
    }

    return -1;
}

indexOf :: (queue: *$T/Queue, item: T.TItem, equalsFn: (T.TItem, T.TItem) -> bool) -> s64 {
    assert(queue.items != null);
    assert(equalsFn != null);

    index := 0;
    current := queue.head;
    while (index < queue.count) {
        if (equalsFn(queue.items[current], item)) {
            return index;
        }
        index += 1;
        current += 1;
        if (current >= queue.capacity) {
            current = 0;
        }
    }

    return -1;
}

contains :: inline (queue: *$T/Queue, item: T.TItem) -> bool {
    return indexOf(queue, item) >= 0;
}

contains :: inline (queue: *$T/Queue, item: T.TItem, equalsFn: (T.TItem, T.TItem) -> bool) -> bool {
    return indexOf(queue, item, equalsFn) >= 0;
}

for_expansion :: (queue: *$T/Queue, body: Code, flags: For_Flags) #expand {
    #assert(!(flags & .REVERSE));

    index := 0;
    current := queue.head;
    while (index < queue.count) {
        #if flags & .POINTER {
            `it := *queue.items[current];
        } else {
            `it := queue.items[current];
        }
        `it_index := index;

        index += 1;
        current += 1;
        if (current >= queue.capacity) {
            current = 0;
        }

        #insert (remove=assert(false)) body;
    }
}

#scope_file

#import "utils";

resize :: (queue: *$T/Queue) {
    oldCapacity := queue.capacity;
    oldItems := queue.items;

    queue.capacity = oldCapacity * 2;
    queue.items = alloc(T.TItem, queue.capacity, queue.allocator, initialized = false);

    if (queue.head >= queue.tail) {
        memoryCopy(queue.items, oldItems + queue.head, oldCapacity - queue.head);
        memoryCopy(queue.items + oldCapacity - queue.head, oldItems, (queue.head + queue.count) % oldCapacity);
    } else {
        memoryCopy(queue.items, oldItems + queue.head, queue.count);
    }

    queue.head = 0;
    queue.tail = queue.count;

    free(oldItems, queue.allocator);
}

