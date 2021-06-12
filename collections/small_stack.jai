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
// It defines a strongly-typed stack of elements and its operations.
// This is not a resizable stack but a fixed length stack that can be stack-allocated.
//
SmallStack :: struct(TItem: Type, length: s64) {
    count: s64;
    capacity: s64;
    freeItems: bool;
    allocator: Allocator;
    items: [length] TItem;
}

SmallStackOptions :: struct(TItem: Type, length: s64) {
    freeItems: bool;
    allocator: Allocator;
}

createSmallStack :: inline ($T: Type, $length: s64) -> SmallStack(T, length) {
    stack: SmallStack(T, length);
    init(*stack);
    return stack;
}

createSmallStack :: inline ($T: Type, $length: s64, options: SmallStackOptions(T, length)) -> SmallStack(T, length) {
    stack: SmallStack(T, length);
    init(*stack, options);
    return stack;
}

init :: inline (stack: *$T/SmallStack) {
    #assert(T.length > 0);
    init(stack, StackOptions(T.TItem, T.length).{});
}

init :: inline (stack: *$T/SmallStack, options: SmallStackOptions(T.TItem, T.length)) {
    #assert(T.length > 0);

    stack.count = 0;
    stack.capacity = T.length;
    stack.freeItems = options.freeItems;
}

uninit :: (stack: *$T/SmallStack, freeStack: bool = false) {
    clear(stack);

    if (freeStack) {
        free(stack, stack.allocator);
    }
}

clear :: (stack: *$T/SmallStack) {
    #insert #run () -> string {
        info := type_info(T.TItem);

        if (info.type == Type_Info_Tag.POINTER) {
            return #string DONE
                if (stack.freeItems) {
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

push :: (stack: *$T/SmallStack, item: T.TItem) {
    assert(stack.count < stack.capacity);
    stack.items[stack.count] = item;
    stack.count += 1;
}

pop :: (stack: *$T/SmallStack) -> T.TItem {
    assert(stack.count > 0);

    item := stack.items[stack.count - 1];
    stack.count -= 1;
    return item;
}

peek :: inline (stack: *$T/SmallStack) -> T.TItem {
    assert(stack.count > 0);
    return stack.items[stack.count - 1];
}

indexOf :: (stack: *$T/SmallStack, item: T.TItem) -> s64 {
    for i : 0..stack.count-1 {
        if (stack.items[stack.count - i - 1] == item) {
            return i;
        }
    }

    return -1;
}

indexOf :: (stack: *$T/SmallStack, item: T.TItem, equalsFn: (T.TItem, T.TItem) -> bool) -> s64 {
    assert(equalsFn != null);

    for i : 0..stack.count-1 {
        if (equalsFn(stack.items[stack.count - i - 1], item)) {
            return i;
        }
    }

    return -1;
}

contains :: inline (stack: *$T/SmallStack, item: T.TItem) -> bool {
    return indexOf(stack, item) >= 0;
}

contains :: inline (stack: *$T/SmallStack, item: T.TItem, equalsFn: (T.TItem, T.TItem) -> bool) -> bool {
    return indexOf(stack, item, equalsFn) >= 0;
}

for_expansion :: (stack: *$T/SmallStack, body: Code, flags: For_Flags) #expand {
    #assert(!(flags & .REVERSE));

    index := 0;
    while (index < stack.count) {
        #if flags & .POINTER {
            `it := *stack.items[stack.count - index - 1];
        } else {
            `it := stack.items[stack.count - index - 1];
        }
        `it_index := index;

        #insert (remove=assert(false)) body;
        index += 1;
    }
}
