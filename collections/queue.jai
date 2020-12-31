Queue :: struct(TItem: Type) {
    head: s64;
    tail: s64;
    count: s64;
    capacity: s64;
    freeItems: bool;
    allocator: Allocator;
    equalsFn: (TItem, TItem) -> bool;
    items: *TItem;
}

QueueOptions :: struct(TItem: Type) {
    capacity: s64 = 8;
    freeItems: bool;
    allocator: Allocator;
    equalsFn: (TItem, TItem) -> bool;
}

init :: (queue: *$T/Queue, options: QueueOptions) {
    assert(options.capacity > 0);

    queue.head = 0;
    queue.tail = 0;
    queue.count = 0;
    queue.capacity = options.capacity;
    queue.freeItems = options.freeItems;
    queue.allocator = options.allocator;
    queue.equalsFn = options.equalsFn;
    queue.items = alloc(T.TItem, queue.capacity, queue.allocator, initialized = false);
}

free :: (queue: *$T/Queue, freeList: bool = false) {
    if (queue.items) {
        clear(queue);
        free(queue.items, queue.allocator);
    }

    if (freeList) {
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
                        free(queue.items[(head + i) % queue.capacity], queue.allocator);
                    }
                }
            DONE;
        }

        return "__unnused_var := 0;";
    }();

    queue.count = 0;
}

push :: (queue: *$T/Queue, item: T.TItem) {
    assert(queue.items != null);

    if (queue.count == queue.capacity) {
        resize(queue);
    }

    queue.items[queue.tail] = item;
    queue.tail = (queue.tail + 1) % queue.capacity;
    queue.count += 1;
}

pop :: (queue: *$T/Queue) -> T.TItem {
    assert(queue.items != null);
    assert(queue.count > 0);

    item := queue.items[queue.head];
    queue.head = (queue.head + 1) % queue.capacity;
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

    if (queue.equalsFn != null) {
        for i : 0..queue.count-1 {
            if (queue.equalsFn(queue.items[(queue.head + i) % queue.capacity], item)) {
                return i;
            }
        }
    } else {
        for i : 0..queue.count-1 {
            if (queue.items[(queue.head + i) % queue.capacity] == item) {
                return i;
            }
        }
    }

    return -1;
}

contains :: (queue: *$T/Queue, item: T.TItem) -> bool {
    return indexOf(queue, item) >= 0;
}

for_expansion :: (queue: *$T/Queue, body: Code, $pointer: bool, reverse: bool) #expand {
    for <=reverse i : 0..queue.count-1 {
        #if pointer {
            `it := *queue.items[(queue.head + i) % queue.capacity];
        } else {
            `it := queue.items[(queue.head + i) % queue.capacity];
        }
        `it_index := i;

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

    if (queue.head > queue.tail) {
        memoryCopy(queue.items, oldItems + queue.head, oldCapacity - queue.head);
        memoryCopy(queue.items + oldCapacity - queue.head, oldItems, (queue.head + queue.count) % oldCapacity);
    } else {
        memoryCopy(queue.items, oldItems + queue.head, queue.count);
    }

    queue.head = 0;
    queue.tail = queue.count;

    free(oldItems, queue.allocator);
}
