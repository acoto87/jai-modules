Stack :: struct(TItem: Type) {
    count: s64;
    capacity: s64;
    allocator: Allocator;
    freeItems: bool;
    equalsFn: (TItem, TItem) -> bool;
    items: *TItem;
}

StackOptions :: struct(TItem: Type) {
    capacity: s64 = 8;
    freeItems: bool;
    allocator: Allocator;
    equalsFn: (TItem, TItem) -> bool;
}

init :: (stack: *$T/Stack, options: StackOptions) {
    assert(options.capacity > 0);

    stack.count = 0;
    stack.capacity = options.capacity;
    stack.freeItems = options.freeItems;
    stack.allocator = options.allocator;
    stack.equalsFn = options.equalsFn;
    stack.items = alloc(T.TItem, stack.capacity, stack.allocator, initialized = false);
}

free :: (stack: *$T/Stack, freeList: bool = false) {
    if (stack.items) {
        clear(stack);
        free(stack.items, stack.allocator);
    }

    if (freeList) {
        free(stack, stack.allocator);
    }
}

clear :: (stack: *$T/Stack) {
    assert(stack.items != null);

    #insert #run () -> string {
        info := type_info(T.TItem);

        if (info.type == Type_Info_Tag.POINTER) {
            return #string DONE
                if (queue.freeItems) {
                    for i : 0..stack.count-1 {
                        free(stack.items[i], stack.allocator);
                    }
                }
            DONE;
        }

        return null;
    }();

    stack.count = 0;
}

push :: (stack: *$T/Stack, item: T.TItem) {
    assert(stack.items != null);

    if (stack.count == stack.capacity) {
        resize(stack);
    }

    stack.items[stack.count] = item;
    stack.count += 1;
}

pop :: (stack: *$T/Stack) -> T.TItem {
    assert(stack.items != null);
    assert(stack.count > 0);

    item := stack.items[stack.count - 1];
    stack.count -= 1;
    return item;
}

peek :: (stack: *$T/Stack) -> T.TItem {
    assert(stack.items != null);
    assert(stack.count > 0);

    return stack.items[stack.count - 1];
}

indexOf :: (stack: *$T/Stack, item: T.TItem) -> s64 {
    assert(stack.items != null);

    if (stack.equalsFn != null) {
        for i : 0..stack.count-1 {
            if (stack.equalsFn(stack.items[i], item)) {
                return i;
            }
        }
    } else {
        for i : 0..stack.count-1 {
            if (stack.items[i] == item) {
                return i;
            }
        }
    }

    return -1;
}

contains :: (stack: *$T/Stack, item: T.TItem) -> bool {
    return indexOf(stack, item) >= 0;
}

for_expansion :: (stack: *$T/Stack, body: Code, $pointer: bool, reverse: bool) #expand {
    for <=reverse i : 0..stack.count-1 {
        #if pointer {
            `it := *stack.items[i];
        } else {
            `it := stack.items[i];
        }
        `it_index := i;

        #insert (remove=assert(false)) body;
    }
}

#scope_file

#import "utils";

resize :: (stack: *$T/Stack) {
    oldCapacity := stack.capacity;

    stack.capacity = oldCapacity * 2;
    stack.items = realloc(stack.items, stack.capacity, oldCapacity, stack.allocator);
}
