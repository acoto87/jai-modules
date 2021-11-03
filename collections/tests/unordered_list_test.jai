main :: () {
    registerTest(testReserve, tprint("reserve for % items", NUMBER_OF_ITEMS));
    registerTest(testAdd, tprint("add % objects", NUMBER_OF_ITEMS));
    registerTest(testInsert, tprint("insert % objects", NUMBER_OF_ITEMS / 2));
    registerTest(testInsertRange, tprint("insert range % objects", NUMBER_OF_ITEMS_RANGE));
    registerTest(testContains, tprint("contains % objects", NUMBER_OF_ITEMS / 2));
    registerTest(testRemoveByIndex, tprint("remove by index % objects", NUMBER_OF_ITEMS / 2));
    registerTest(testRemoveByValue, tprint("remove by value % objects", NUMBER_OF_ITEMS / 2));
    registerTest(testRemoveRange, tprint("remove range % objects", NUMBER_OF_ITEMS_RANGE));
    registerTest(testSortBy, tprint("sorting with byFn % objects", NUMBER_OF_ITEMS));
    registerTest(testSortCompare, tprint("sorting with compareFn % objects", NUMBER_OF_ITEMS));
    registerTest(testIteration, tprint("iterate over % items", NUMBER_OF_ITEMS));

    runTests(true);
}

#scope_file

#import "collections";
#load "tests.jai";

NUMBER_OF_ITEMS :: 100000;
NUMBER_OF_ITEMS_RANGE :: 50000;
INDEX_RANGE_AT :: 100;

testAdd :: () {
    list := createUnorderedList(s64);
    defer uninit(*list);

    for i : 0..NUMBER_OF_ITEMS-1 {
        prevCount := list.count;
        add(*list, i);
        assertEqual(prevCount + 1, list.count);
        assertEqual(i, get(*list, list.count - 1));
    }
}

testInsert :: () {
    list := createUnorderedList(s64);
    defer uninit(*list);

    for i : 0..NUMBER_OF_ITEMS-1 {
        add(*list, i);
    }

    for i : 0..NUMBER_OF_ITEMS/2-1 {
        prevCount := list.count;
        index := randomNext() % list.count;
        insert(*list, index, -index);
        assertEqual(prevCount + 1, list.count);
        assertEqual(-index, get(*list, index));
    }
}

testInsertRange :: () {
    list := createUnorderedList(s64);
    defer uninit(*list);

    for i : 0..NUMBER_OF_ITEMS-1 {
        add(*list, i);
    }

    rangeValues := allocArray(s64, NUMBER_OF_ITEMS_RANGE);
    defer free(rangeValues);

    for i : 0..NUMBER_OF_ITEMS_RANGE-1 {
        rangeValues[i] = -i;
    }

    insertRange(*list, INDEX_RANGE_AT, ..rangeValues);

    assertEqual(NUMBER_OF_ITEMS + NUMBER_OF_ITEMS_RANGE, list.count);

    for i : 0..NUMBER_OF_ITEMS_RANGE-1 {
        assertEqual(rangeValues[i], get(*list, INDEX_RANGE_AT + i));
    }
}

testContains :: () {
    list := createUnorderedList(s64);
    defer uninit(*list);

    for i : 0..NUMBER_OF_ITEMS-1 {
        add(*list, i);
    }

    for i : 0..NUMBER_OF_ITEMS/2-1 {
        value := randomNext() % NUMBER_OF_ITEMS;
        assertTrue(contains(*list, value));
    }
}

testRemoveByIndex :: () {
    list := createUnorderedList(s64);
    defer uninit(*list);

    for i : 0..NUMBER_OF_ITEMS-1 {
        add(*list, i);
    }

    for i : 0..NUMBER_OF_ITEMS/2-1 {
        prevCount := list.count;
        index := randomNext() % list.count;
        value := get(*list, index);
        removeAt(*list, index);
        assertEqual(prevCount - 1, list.count);
        assertTrue(index >= list.count || get(*list, index) != value);
    }
}

testRemoveByValue :: () {
    list := createUnorderedList(s64);
    defer uninit(*list);

    for i : 0..NUMBER_OF_ITEMS-1 {
        add(*list, i);
    }

    for i : 0..NUMBER_OF_ITEMS/2-1 {
        prevCount := list.count;
        value := randomNext() % NUMBER_OF_ITEMS;
        if (contains(*list, value)) {
            removeItem(*list, value);
            assertEqual(prevCount - 1, list.count);
            assertTrue(!contains(*list, value));
        }
    }
}

testRemoveRange :: () {
    list := createUnorderedList(s64);
    defer uninit(*list);

    for i : 0..NUMBER_OF_ITEMS-1 {
        add(*list, i);
    }

    removeAtRange(*list, INDEX_RANGE_AT, NUMBER_OF_ITEMS_RANGE);

    assertEqual(NUMBER_OF_ITEMS - NUMBER_OF_ITEMS_RANGE, list.count);

    c := NUMBER_OF_ITEMS_RANGE;
    if (list.count - INDEX_RANGE_AT < c) {
        c = list.count - INDEX_RANGE_AT;
    }
    for i : 0..c-1 {
        assertNotEqual(INDEX_RANGE_AT + i, get(*list, INDEX_RANGE_AT + i));
    }
}

testSortBy :: () {
    list := createUnorderedList(s64);
    defer uninit(*list);

    for i : 0..NUMBER_OF_ITEMS-1 {
        add(*list, NUMBER_OF_ITEMS - i);
    }

    sort(*list, (item) => item);

    for i : 1..list.count-1 {
        assertTrue(get(*list, i - 1) <= get(*list, i));
    }
}

testSortCompare :: () {
    list := createUnorderedList(s64);
    defer uninit(*list);

    for i : 0..NUMBER_OF_ITEMS-1 {
        add(*list, NUMBER_OF_ITEMS - i);
    }

    sort(*list, (a, b) => (b - a));

    for i : 1..list.count-1 {
        assertTrue(get(*list, i - 1) >= get(*list, i));
    }
}

testReserve :: () {
    list := createUnorderedList(s64);
    defer uninit(*list);

    reserve(*list, NUMBER_OF_ITEMS);

    assertEqual(NUMBER_OF_ITEMS, list.capacity);
}

testIteration :: () {
    list := createUnorderedList(s64);
    defer uninit(*list);

    for i : 0..NUMBER_OF_ITEMS-1 {
        add(*list, i);
    }

    for item, index : list {
        assertEqual(index, item);
    }
}