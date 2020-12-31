LOAD_TESTS :: false;

#load "list.jai";
#load "map.jai";
#load "stack.jai";
#load "queue.jai";
#load "binary_heap.jai";

#if LOAD_TESTS {
    #load "tests/list_test.jai";
    #load "tests/map_test.jai";
    #load "tests/stack_test.jai";
    #load "tests/queue_test.jai";
    #load "tests/binary_heap_test.jai";
}
