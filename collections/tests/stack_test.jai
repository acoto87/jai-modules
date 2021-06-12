testStack :: () {
    valueTypeTest();
    print("\n\n");
    referenceTypeTest();
    print("\n\n");
}

#scope_file

Random :: #import "Random";
randomNext :: Random.random_get;

#import "utils";

valueTypeTest :: (count: u32 = 100000) {
    stack: Stack(s32);
    init(*stack, StackOptions(s32).{});
    defer uninit(*stack);

    print("--- Start value type tests ---\n");

    print("\n");

    measure(sprint("test 1: push % objects", count), #code {
        for i : 0..count-1 {
            push(*stack, xx i);
            assert(peek(*stack) == xx i);
        }
    });

    print("\n");

    measure(sprint("test 2: contains % objects", count / 2), #code {
        for i : 0..count/2-1 {
            value := randomNext() % count;
            assert(contains(*stack, xx value));
        }
    });

    print("\n");

    measure(sprint("test 3: pop % objects", count / 2), #code {
        for i : 0..count/2-1 {
            peekValue := peek(*stack);
            popValue := pop(*stack);
            assert(peekValue == popValue);
        }
    });

    print("\n");

    measure(sprint("test 4: push/pop % objects", count/2), #code {
        for i : 0..count/2-1 {
            if (randomNext() % 100 > 50) {
                push(*stack, -(cast(s32) i));
                assert(peek(*stack) == -(cast(s32) i));
            } else {
                popValue := pop(*stack);
                assert(peek(*stack) != popValue);
            }
        }
    });

    print("\n");

    print("--- End value type tests ---\n");
}

referenceTypeTest :: (count: u32 = 100000) {
    Entry :: struct {
        index: s32;
        name: string;
    };

    entryEquals :: inline (e1: *Entry, e2: *Entry) -> bool {
        return e1.index == e2.index;
    };

    options: StackOptions(*Entry);
    options.freeItems = true;

    stack: Stack(*Entry);
    init(*stack, options);
    defer uninit(*stack);

    print("--- Start reference type tests ---\n");

    print("\n");

    measure(sprint("test 1: push % objects", count), #code {
        for i : 0..count-1 {
            entry := alloc(Entry);
            entry.index = xx i;
            entry.name = "entry";
            push(*stack, entry);
            assert(peek(*stack).index == entry.index);
        }
    });

    print("\n");

    measure(sprint("test 2: contains % objects", count / 2), #code {
        for i : 0..count/2-1 {
            entry := alloc(Entry);
            entry.index = xx (randomNext() % count);
            entry.name = "entry";
            assert(contains(*stack, entry, entryEquals));
            free(entry);
        }
    });

    print("\n");

    measure(sprint("test 3: pop % objects", count / 2), #code {
        for i : 0..count/2-1 {
            peekValue := peek(*stack);
            popValue := pop(*stack);
            assert(peekValue.index == popValue.index);
            free(popValue);
        }
    });

    print("\n");

    measure(sprint("test 4: push/pop % objects", count/2), #code {
        for i : 0..count/2-1 {
            if (randomNext() % 100 > 50) {
                entry := alloc(Entry);
                entry.index = -(cast(s32) i);
                entry.name = "entry";
                push(*stack, entry);
                assert(peek(*stack).index == -(cast(s32) i));
            } else {
                popValue := pop(*stack);
                assert(peek(*stack).index != popValue.index);
            }
        }
    });

    print("\n");

    print("--- End reference type tests ---\n");
}