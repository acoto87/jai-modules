testList :: () {
    valueTypeTest();

    print("\n\n");

    referenceTypeTest();
}

#scope_file

String :: #import "String";
compare :: String.compare;

Random :: #import "Random";
randomNext :: Random.random_get;

#import "utils";

valueTypeTest :: (count: u32 = 100000) {
    list: List(s32);
    init(*list, ListOptions(s32).{});

    print("--- Start value type tests ---\n");

    print("\n");

    measure(sprint("test 1: add % objects", count), #code {
        for i : 0..count-1 {
            add(*list, xx i);
            assert(list[list.count - 1] == xx i);
        }
    });

    print("\n");

    measure(sprint("test 2: contains % objects", count / 2), #code {
        for i : 0..count/2-1 {
            value := randomNext() % count;
            assert(contains(*list, xx value));
        }
    });

    print("\n");

    measure(sprint("test 3: remove by index % objects", count / 2), #code {
        for i : 0..count/2-1 {
            index := randomNext() % list.count;
            value := list[index];
            removeAt(*list, index);
            assert(index >= list.count || list[index] != value);
        }
    });

    print("\n");

    measure(sprint("test 4: remove by value % objects", count / 2), #code {
        for i : 0..count/2-1 {
            value := randomNext() % count;
            removeItem(*list, xx value);
            assert(!contains(*list, xx value));
        }
    });

    print("\n");

    measure(sprint("test 5: insert % objects", count / 2), #code {
        for i : 0..count/2-1 {
            index := randomNext() % list.count;
            insert(*list, index, xx index);
            assert(list[index] == xx index);
        }
    });

    print("\n");

    rangeCount :: 50000;
    rangeAt :: 100;

    rangeValues := allocArray(s32, rangeCount);
    for i : 0..rangeCount-1 {
        rangeValues[i] = xx -i;
    }

    measure(sprint("test 6: insert range % objects", rangeCount), #code {
        insertRange(*list, rangeAt, ..rangeValues);
    }, post = #code {
        for i : 0..rangeCount-1 {
            assert(list[rangeAt + i] == rangeValues[i]);
        }
    });

    print("\n");

    measure(sprint("test 7: remove range % objects", rangeCount), #code {
        removeAtRange(*list, rangeAt, rangeCount);
    }, post = #code {
        for i : 0..rangeCount-1 {
            assert(list[rangeAt + i] != rangeValues[i]);
        }
    });

    freeArray(rangeValues);

    print("\n");

    measure(sprint("test 8: sorting with byFn % objects", list.count), #code {
        sort(*list, (item) => item);
    }, post = #code {
        for i : 1..list.count-1 {
            assert(list[i-1] <= list[i]);
        }
    });

    print("\n");

    measure(sprint("test 9: sorting with compareFn % objects", list.count), #code {
        sort(*list, (a, b) => cast(s64) (b - a));
    }, post = #code {
        for i : 1..list.count-1 {
            assert(list[i-1] >= list[i]);
        }
    });

    uninit(*list);

    print("--- End value type tests ---\n");
}

referenceTypeTest :: (count: u32 = 100000) {
    Entry :: struct {
        index: s32;
        name: string;
    };

    options: ListOptions(*Entry);
    options.freeItems = true;
    options.equalsFn = (e1: *Entry, e2: *Entry) -> bool {
        return e1.index == e2.index;
    };

    list: List(*Entry);
    init(*list, options);

    entries := allocArray(*Entry, count);

    print("--- Start reference type tests ---\n");

    print("\n");

    measure(sprint("test 1: add % objects", count), #code {
        for i : 0..count-1 {
            entry := alloc(Entry);
            entry.index = xx i;
            entry.name = "entry";
            add(*list, entry);
            assert(list[list.count - 1].index == xx i);
            entries[i] = entry;
        }
    });

    print("\n");

    measure(sprint("test 2: contains % objects", count / 2), #code {
        for i : 0..count/2-1 {
            entry := entries[randomNext() % count];
            assert(contains(*list, entry));
        }
    });

    print("\n");

    measure(sprint("test 3: insert % objects", count / 2), #code {
        for i : 0..count/2-1 {
            entry := alloc(Entry);
            entry.index = xx (randomNext() % list.count);
            entry.name = "entry";
            insert(*list, entry.index, entry);
            assert(list[entry.index] == entry);
        }
    });

    print("\n");

    measure(sprint("test 4: remove by index % objects", count / 2), #code {
        for i : 0..count/2-1 {
            index := randomNext() % (list.count - 1);
            entry := list[index + 1];
            removeAt(*list, index);
            assert(list[index] == entry);
        }
    });

    print("\n");

    freeArray(entries);

    entries = allocArray(*Entry, count/2);
    for i : 0..count/2-1 {
        entry := alloc(Entry);
        entry.index = xx (randomNext() % list.count);
        entry.name = "negative";
        insert(*list, entry.index, entry);
        entries[i] = entry;
    }

    measure(sprint("test 5: remove by value % objects", count / 2), #code {
        for i : 0..count/2-1 {
            removeItem(*list, entries[i]);
        }
    }, post = #code {
        for i : 0..list.count-1 {
            assert(list[i].name == "negative");
        }
    });

    print("\n");

    rangeCount :: 50000;
    rangeAt :: 100;

    rangeValues := allocArray(*Entry, rangeCount);
    for i : 0..rangeCount-1 {
        entry := alloc(Entry);
        entry.index = xx -i;
        entry.name = "insert range";
        rangeValues[i] = entry;
    }

    measure(sprint("test 6: insert range % objects", rangeCount), #code {
        insertRange(*list, rangeAt, ..rangeValues);
    }, post = #code {
        for i : 0..rangeCount-1 {
            assert(list[rangeAt + i] == rangeValues[i]);
        }
    });

    print("\n");

    measure(sprint("test 7: remove range % objects", rangeCount), #code {
        removeAtRange(*list, rangeAt, rangeCount);
    }, post = #code {
        for i : 0..rangeCount-1 {
            assert(list[rangeAt + i].index >= 0);
        }
    });

    freeArray(rangeValues);

    print("\n");

    measure(sprint("test 8: sorting with byFn % objects", list.count), #code {
        sort(*list, (item: *Entry) -> s32 {
            return item.index;
        });
    }, post = #code {
        for i : 1..list.count-1 {
            assert(list[i-1] <= list[i]);
        }
    });

    print("\n");

    measure(sprint("test 9: sorting with compareFn % objects", list.count), #code {
        sort(*list, (a: *Entry, b: *Entry) -> s64 {
            if (a.index == b.index) {
                return xx -compare(a.name, b.name);
            }
            return xx (b.index - a.index);
        });
    }, post = #code {
        for i : 1..list.count-1 {
            assert(list[i-1] >= list[i]);
        }
    });

    uninit(*list);

    print("--- End reference type tests ---\n");
}
