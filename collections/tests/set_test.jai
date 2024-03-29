testSet :: () {
    valueTypeTest();
    print("\n\n");
    referenceTypeTest();
    print("\n\n");
}

#scope_file

#import "utils";
#import "strings";

valueTypeTest :: ($count: s64 = 100000) {
    set := alloc(HashSet(s64, true));
    init(set, HashSetOptions(s64).{});

    measure(sprint("test 1: add % objects", count), #code {
        for i : 0..count-1 {
            added := add(set, i);
            assert(added && set.count == i + 1);
        }
    });

    print("\n");

    measure(sprint("test 2: contains % objects", count/2), #code {
        for i : 0..count/2-1 {
            item := randomNext() % count;
            assert(contains(set, item));
        }
    });

    print("\n");

    measure(sprint("test 3: remove % objects", count/2), #code {
        for i : 0..count/2-1 {
            item := randomNext() % count;
            removeItem(set, item);
            assert(!contains(set, item));
        }
    });

    print("\n");

    measure("test 4: iterate in order", #code {
        last := -1;
        for item : set {
            assert(item >= last);
            last = item;
        }
    });
}

referenceTypeTest :: ($count: s64 = 100000) {
    randomSeed(3323, 1212);

    generateString :: () -> string {
        stringLength :: 50;

        data := alloc(u8, stringLength);
        for i : 0..stringLength-1 {
            data[i] = cast(u8) (randomNext() % 27 + 97);
        }

        s: string = ---;
        s.data = data;
        s.count = stringLength;
        return s;
    }

    strings := allocArray(string, count);
    for i : 0..count-1 {
        strings[i] = generateString();
    }

    options := HashSetOptions(string).{
        equalsFn = (s1: string, s2: string) -> bool {
            return equals(s1, s2);
        }
    };

    set := alloc(HashSet(string, true));
    init(set, options);

    measure(sprint("test 1: add % objects", count), #code {
        for i : 0..count-1 {
            item := strings[i];
            added := add(set, item);
            assert(added && set.count == i + 1);
        }
    });

    print("\n");

    measure(sprint("test 2: contains % objects", count/2), #code {
        for i : 0..count/2-1 {
            index := randomNext() % count;
            assert(contains(set, strings[index]));
        }
    });

    print("\n");

    measure(sprint("test 3: remove % objects", count/2), #code {
        for i : 0..count/2-1 {
            index := randomNext() % count;
            removeItem(set, strings[index]);
            assert(!contains(set, strings[index]));
        }
    });

    print("\n");

    measure("test 4: iterate in order", #code {
        last := -1;
        for item : set {
            index := -1;
            for i : 0..strings.count-1 {
                if (equals(item, strings[i])) {
                    index = i;
                    break;
                }
            }
            assert(index >= last);
            last = index;
        }
    });
}