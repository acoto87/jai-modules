TestFunc :: #type () -> ();

registerTest :: (func: TestFunc, name: string, description: string = "") {
    entry: TestEntry;
    entry.func = func;
    entry.name = name;
    entry.description = description;
    arrayAdd(*testEntries, entry);
}

registerTestSuccess :: (message: string = "") {
    assert(currentEntry != null);
    currentEntry.success = true;
    currentEntry.message = message;
}

registerTestFail :: (message: string = "") {
    assert(currentEntry != null);
    currentEntry.failed = true;
    currentEntry.message = message;
}

assertEqual :: (expected: $T, actual: T) #expand {
    if (expected != actual) {
        registerTestFail(tprint("Expected % but got %", expected, actual));
        `return;
    }
}

assertNotEqual :: (expected: $T, actual: T) #expand {
    if (expected == actual) {
        registerTestFail(tprint("Expected % but got %", expected, actual));
        `return;
    }
}

assertTrue :: (value: bool) #expand {
    if (!value) {
        registerTestFail("Expected true but got false");
        `return;
    }
}

assertFalse :: (value: bool) #expand {
    if (value) {
        registerTestFail("Expected false but got true");
        `return;
    }
}

runTests :: (measureTime: bool = false) {
    for * entry, i : testEntries {
        currentEntry = entry;
        elapsed: f64;

        print("Test %: %\n", i + 1, currentEntry.name);

        if (measureTime) {
            elapsed = measure(#code {
                currentEntry.func();
            });
        } else {
            currentEntry.func();
        }

        if (!currentEntry.success && !currentEntry.failed) {
            registerTestSuccess();
        }

        if (currentEntry.success) {
            print("  Result: SUCCESS!\n");
        } else if (currentEntry.failed) {
            print("  Result: FAILED!\n");
        }

        if (currentEntry.message.count > 0) {
            print("  Message: %\n", currentEntry.message);
        }

        if (measureTime) {
            print("  Elapsed: %s\n", formatFloat(elapsed, trailing_width=4, zero_removal=.NO));
        }

        print("\n");
    }
}

#scope_file

#import "utils";

Basic :: #import "Basic";
arrayAdd :: Basic.array_add;

TestEntry :: struct {
    func: TestFunc;
    name: string;
    description: string;

    success: bool;
    failed: bool;
    message: string;
}

testEntries: [..] TestEntry;
currentEntry: *TestEntry;

measure :: inline (code: Code) -> f64 #expand {
    start := getTime();
    #insert code;
    end := getTime();
    return end - start;
}

createStr :: inline (c: u8, count: s64, allocator: Allocator = null) -> string {
    s: string = ---;
    s.count = count;
    s.data = alloc(u8, count, allocator);
    memorySet(s.data, c, count);
    return s;
}