testMap :: () {
    valueTypeTest();

    print("\n\n");

    referenceTypeTest();
}

#scope_file

String :: #import "String";
equal :: String.equal;

Random :: #import "Random";
randomNext :: Random.random_get;

Basic :: #import "Basic";
to_upper :: Basic.to_upper;

#import "utils";

valueTypeTest :: ($count: s64 = 100000) {
    options := HashMapOptions(s64, s64).{
        hashFn = (k: s64) -> s64 {
            return k;
        }
    };

    map: HashMap(s64, s64);
    init(*map, options);

    measure(sprint("test 1: add % objects", count), #code {
        for i : 0..count-1 {
            set(*map, i, i*i);
            found, value := get(*map, i);
            assert(found && value == i*i);
        }
    });

    print("\n");

    measure(sprint("test 2: contains % objects", count/2), #code {
        for i : 0..count/2-1 {
            key := randomNext() % count;
            assert(containsKey(*map, key));
        }
    });

    print("\n");

    measure(sprint("test 3: set existing % objects", count/2), #code {
        for i : 0..count/2-1 {
            key := randomNext() % count;
            set(*map, key, key);
            found, value := get(*map, key);
            assert(found && value == key);
        }
    });

    print("\n");

    measure(sprint("test 4: remove % objects", count/2), #code {
        for i : 0..count/2-1 {
            key := randomNext() % count;
            removeKey(*map, key);
            assert(!containsKey(*map, key));
        }
    });

    print("\n");

    measure("test 5: iterate in order", #code {
        last := -1;
        for * entry : map {
            assert(entry.key >= last);
            last = entry.key;
        }
    });
}

referenceTypeTest :: ($count: u32 = 10000) {
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

    toUpperString :: (s: string) -> string {
        data := alloc(u8, s.count);

        for i : 0..s.count-1 {
            data[i] = to_upper(s[i]);
        }

        upper: string = ---;
        upper.data = data;
        upper.count = s.count;
        return upper;
    }

    reverseString :: (s: string) -> string {
        data := alloc(u8, s.count);
        for i : 0..s.count-1 {
            data[i] = s[s.count - i - 1];
        }

        reverse: string = ---;
        reverse.data = data;
        reverse.count = s.count;
        return reverse;
    }

    strings: [count] string;
    for i : 0..count-1 {
        strings[i] = generateString();
    }

    options := HashMapOptions(string, string).{
        hashFn = (k: string) -> s64 {
            FNV_PRIME : u32 : 0x01000193;
            FNV_OFFSET : u32 : 0x811c9dc5;

            hash := FNV_OFFSET;
            for i : 0..k.count-1 {
                hash = (cast(u32) k[i] ^ hash) * FNV_PRIME;
            }

            return cast(s64) hash;
        },
        equalsFn = (s1: string, s2: string) -> bool {
            return equal(s1, s2);
        }
    };

    map: HashMap(string, string);
    init(*map, options);

    measure(sprint("test 1: add % objects", count), #code {
        for i : 0..count-1 {
            key := strings[i];
            upper := toUpperString(key);
            set(*map, key, upper);
            found, value := get(*map, key);
            assert(found && equal(value, upper));
        }
    });

    print("\n");

    measure(sprint("test 2: contains % objects", count/2), #code {
        for i : 0..count/2-1 {
            index := randomNext() % count;
            assert(containsKey(*map, strings[index]));
        }
    });

    print("\n");

    measure(sprint("test 3: set existing % objects", count/2), #code {
        for i : 0..count/2-1 {
            index := randomNext() % count;
            reverse := reverseString(strings[index]);
            set(*map, strings[index], reverse);
            found, value := get(*map, strings[index]);
            assert(found && equal(value, reverse));
        }
    });

    print("\n");

    measure(sprint("test 4: remove % objects", count/2), #code {
        for i : 0..count/2-1 {
            index := randomNext() % count;
            removeKey(*map, strings[index]);
            assert(!containsKey(*map, strings[index]));
        }
    });

    print("\n");

    measure("test 5: iterate in order", #code {
        last := -1;
        for * entry : map {
            index := -1;
            for i : 0..strings.count-1 {
                if (equal(entry.key, strings[i])) {
                    index = i;
                    break;
                }
            }
            assert(index >= last);
            last = index;
        }
    });
}