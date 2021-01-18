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
// It defines a strongly-typed stack of elements and its operations.
//
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

init :: (stack: *$T/Stack) {
    init(stack, StackOptions(T.TItem).{});
}

init :: (stack: *$T/Stack, options: StackOptions(T.TItem)) {
    assert(options.capacity > 0);

    stack.count = 0;
    stack.capacity = options.capacity;
    stack.freeItems = options.freeItems;
    stack.allocator = options.allocator;
    stack.equalsFn = options.equalsFn;
    stack.items = alloc(T.TItem, stack.capacity, stack.allocator, initialized = false);
}

uninit :: (stack: *$T/Stack, freeList: bool = false) {
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

        return "";
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

for_expansion :: (stack: *$T/Stack, body: Code, flags: For_Flags) #expand {
    #assert(!(flags & .REVERSE));

    for i : 0..stack.count-1 {
        #if flags & .POINTER {
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
