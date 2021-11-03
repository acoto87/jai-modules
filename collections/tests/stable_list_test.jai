main :: () {
    registerTest(testReserve, tprint("reserve for % items", NUMBER_OF_ITEMS));
    registerTest(testAdd, tprint("add % items", NUMBER_OF_ITEMS));
    registerTest(testContains, tprint("contains % items", NUMBER_OF_ITEMS / 2));
    registerTest(testRemoveByIndex, tprint("remove by index % items", NUMBER_OF_ITEMS / 2));
    registerTest(testRemoveByValue, tprint("remove by value % items", NUMBER_OF_ITEMS / 2));
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
    list := createStableList(s64);
    defer uninit(*list);

    for i : 0..NUMBER_OF_ITEMS-1 {
        prevCount := list.count;
        add(*list, i);
        assertEqual(prevCount + 1, list.count);
        assertEqual(i, get(*list, list.count - 1));
    }
}

testContains :: () {
    list := createStableList(s64);
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
    list := createStableList(s64);
    defer uninit(*list);

    for i : 0..NUMBER_OF_ITEMS-1 {
        add(*list, i);
    }

    for i : 0..NUMBER_OF_ITEMS/2-1 {
        prevCount := list.count;
        index := randomNext() % list.count;
        while (isEmpty(*list, index)) {
            index = randomNext() % list.count;
        }
        value := get(*list, index);
        removeAt(*list, index);
        assertEqual(prevCount - 1, list.count);
        assertTrue(index >= list.count || isEmpty(*list, index));
    }
}

testRemoveByValue :: () {
    list := createStableList(s64);
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

testReserve :: () {
    list := createStableList(s64);
    defer uninit(*list);

    reserve(*list, NUMBER_OF_ITEMS);

    assertEqual(NUMBER_OF_ITEMS, list.capacity);
    assertEqual(NUMBER_OF_ITEMS / list.bucketCapacity, list.buckets.count);

    for bucket : list.buckets {
        assertTrue(bucket != null);
    }
}

testIteration :: () {
    list := createStableList(s64);
    defer uninit(*list);

    for i : 0..NUMBER_OF_ITEMS-1 {
        add(*list, i);
    }

    for item, index : list {
        assertEqual(index, item);
    }
}
