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
// This is not a resizable queue but a fixed length queue that can be stack-allocated.
//
SmallQueue :: struct(TItem: Type, length: s64) {
    head: s64;
    tail: s64;
    count: s64;
    capacity: s64;
    freeItems: bool;
    allocator: Allocator;
    items: [length] TItem;
}

SmallQueueOptions :: struct(TItem: Type, length: s64) {
    freeItems: bool;
    allocator: Allocator;
}

createSmallQueue :: inline ($T: Type, $length: s64) -> SmallQueue(T, length) {
    queue: SmallQueue(T);
    init(*queue);
    return queue;
}

createSmallQueue :: inline ($T: Type, $length: s64, options: SmallQueueOptions(T, length)) -> SmallQueue(T, length) {
    queue: SmallQueue(T);
    init(*queue, options);
    return queue;
}

init :: inline (queue: *$T/SmallQueue) {
    #assert(T.length > 0);
    init(queue, SmallQueueOptions(T.TItem, T.length).{});
}

init :: (queue: *$T/SmallQueue, options: SmallQueueOptions(T.TItem, T.length)) {
    #assert(T.length > 0);

    queue.head = 0;
    queue.tail = 0;
    queue.count = 0;
    queue.capacity = T.length;
    queue.freeItems = options.freeItems;
    queue.allocator = options.allocator;
}

uninit :: (queue: *$T/SmallQueue, freeQueue: bool = false) {
    clear(queue);

    if (freeQueue) {
        free(queue, queue.allocator);
    }
}

clear :: (queue: *$T/SmallQueue) {
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

push :: (queue: *$T/SmallQueue, item: T.TItem) {
    assert(queue.count < queue.capacity);

    queue.items[queue.tail] = item;
    queue.tail += 1;
    if (queue.tail >= queue.capacity) {
        queue.tail = 0;
    }
    queue.count += 1;
}

pop :: (queue: *$T/SmallQueue) -> T.TItem {
    assert(queue.count > 0);

    item := queue.items[queue.head];
    queue.head += 1;
    if (queue.head >= queue.capacity) {
        queue.head = 0;
    }
    queue.count -= 1;
    return item;
}

peek :: inline (queue: *$T/SmallQueue) -> T.TItem {
    assert(queue.count > 0);
    return queue.items[queue.head];
}

indexOf :: (queue: *$T/SmallQueue, item: T.TItem) -> s64 {
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

indexOf :: (queue: *$T/SmallQueue, item: T.TItem, equalsFn: (T.TItem, T.TItem) -> bool) -> s64 {
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

contains :: inline (queue: *$T/SmallQueue, item: T.TItem) -> bool {
    return indexOf(queue, item) >= 0;
}

contains :: inline (queue: *$T/SmallQueue, item: T.TItem, equalsFn: (T.TItem, T.TItem) -> bool) -> bool {
    return indexOf(queue, item, equalsFn) >= 0;
}

for_expansion :: (queue: *$T/SmallQueue, body: Code, flags: For_Flags) #expand {
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

        #insert (remove=assert(false)) body;
        index += 1;
        current += 1;
        if (current >= queue.capacity) {
            current = 0;
        }
    }
}
