testQueue :: () {
    valueTypeTest();

    print("\n\n");

    referenceTypeTest();
}

#scope_file

Random :: #import "Random";
randomNext :: Random.random_get;

#import "utils";

valueTypeTest :: (count: u32 = 100000) {
    queue: Queue(s32);
    init(*queue, QueueOptions(s32).{});

    print("--- Start value type tests ---\n");

    print("\n");

    measure(sprint("test 1: enqueue % objects", count), #code {
        for i : 0..count {
            push(*queue, xx i);
            assert(peek(*queue) == 0);
        }
    });

    print("\n");

    measure(sprint("test 2: contains % objects", count/2), #code {
        for i : 0..count/2-1 {
            value := randomNext() % count;
            assert(contains(*queue, xx value));
        }
    });

    print("\n");

    measure(sprint("test 3: pop % objects", count/2), #code {
        for i : 0..count/2-1 {
            peekValue := peek(*queue);
            popValue := pop(*queue);
            assert(peekValue == popValue);
        }
    });

    print("\n");

    peekValue := peek(*queue);
    measure(sprint("test 4: push/pop % objects", count/2), #code {
        for i : 0..count/2-1 {
            if (randomNext() % 100 > 50) {
                push(*queue, xx i);
                assert(peek(*queue) == peekValue);
            } else {
                popValue := pop(*queue);
                assert(peekValue == popValue);
                peekValue = peek(*queue);
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

    options: QueueOptions(*Entry);
    options.freeItems = true;
    options.equalsFn = (e1: *Entry, e2: *Entry) -> bool {
        return e1.index == e2.index;
    };

    queue: Queue(*Entry);
    init(*queue, options);

    print("--- Start reference type tests ---\n");

    print("\n");

    measure(sprint("test 1: enqueue % objects", count), #code {
        for i : 0..count {
            entry := alloc(Entry);
            entry.index = xx i;
            entry.name = "insert";
            push(*queue, entry);
            assert(peek(*queue).index == 0);
        }
    });

    print("\n");

    measure(sprint("test 2: contains % objects", count/2), #code {
        for i : 0..count/2-1 {
            entry := alloc(Entry);
            entry.index = xx (randomNext() % count);
            entry.name = "contains";
            assert(contains(*queue, entry));
            free(entry);
        }
    });

    print("\n");

    measure(sprint("test 3: pop % objects", count/2), #code {
        for i : 0..count/2-1 {
            peekValue := peek(*queue);
            popValue := pop(*queue);
            assert(peekValue.index == popValue.index);
        }
    });

    print("\n");

    peekValue := peek(*queue);
    measure(sprint("test 4: push/pop % objects", count/2), #code {
        for i : 0..count/2-1 {
            if (randomNext() % 100 > 50) {
                entry := alloc(Entry);
                entry.index = xx i;
                entry.name = "insert";
                push(*queue, entry);
                assert(peek(*queue).index == peekValue.index);
            } else {
                popValue := pop(*queue);
                assert(peekValue.index == popValue.index);
                peekValue = peek(*queue);
                free(popValue);
            }
        }
    });

    print("\n");

    print("--- End reference type tests ---\n");
}