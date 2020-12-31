testHeap :: () {
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
    heap: BinaryHeap(s32);
    init(*heap, BinaryHeapOptions(s32).{
        compareFn = (a: s32, b: s32) -> s64 {
            return a - b;
        }
    });

    print("--- Start value type tests ---\n");

    print("\n");

    min := count;

    measure(sprint("test 1: add % objects", count), #code {
        for i : 0..count-1 {
            x := randomNext() % count;
            if (x < min) {
                min = x;
            }
            push(*heap, xx x);
            assert(peek(*heap) == xx min);
        }
    });

    print("\n");

    measure(sprint("test 2: peek min object"), #code {
        assert(peek(*heap) == xx min);
    });

    print("\n");

    measure(sprint("test 3: pop min object"), #code {
        prev := -1;
        while (heap.count > 0) {
            x := pop(*heap);
            assert(prev < 0 || prev <= x);
            prev = x;
        }
    });

    print("\n");

    print("--- End value type tests ---\n");
}

referenceTypeTest :: (count: u32 = 10000) {
    generateString :: () -> string {
        stringLength := randomNext() % 100000;

        data := alloc(u8, stringLength);
        for i : 0..stringLength-1 {
            data[i] = cast(u8) (randomNext() % 27 + 97);
        }

        s: string = ---;
        s.data = data;
        s.count = stringLength;
        return s;
    }

    heap: BinaryHeap(string);
    init(*heap, BinaryHeapOptions(string).{
        compareFn = (a: string, b: string) -> s64 {
            return xx compare(a, b);
        }
    });

    print("--- Start reference type tests ---\n");

    print("\n");

    strings: [10000] string;
    for i : 0..count-1 {
        strings[i] = generateString();
    }

    min: string;

    measure(sprint("test 1: add % objects", count), #code {
        for i : 0..count-1 {
            index := randomNext() % count;
            push(*heap, strings[index]);
            if (min.count == 0 || compare(strings[index], min) < 0) {
                min = strings[index];
            }
            assert(compare(peek(*heap), min) == 0);
        }
    });

    print("\n");

    measure(sprint("test 2: peek min object"), #code {
        assert(compare(peek(*heap), min) == 0);
    });

    print("\n");

    measure(sprint("test 3: pop min object"), #code {
        prev := peek(*heap);
        while (heap.count > 0) {
            x := pop(*heap);
            assert(compare(prev, x) <= 0);
            prev = x;
        }
    });

    print("\n");

    for i : 0..count-1 {
        free(strings[i].data);
    }
    free(strings.data);

    print("--- End reference type tests ---\n");
}
