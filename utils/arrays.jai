arrayCopy :: inline (src: [] $T, dst: [] T) {
    assert(dst.count >= src.count);
    arrayCopy(src, 0, dst, 0, src.count);
}

arrayCopy :: inline (src: [] $T, dst: [] T, count: s64) {
    arrayCopy(src, 0, dst, 0, count);
}

arrayCopy :: inline (src: [] $T, srcIdx: s64, dst: [] T, dstIdx: s64, count: s64) {
    assert(srcIdx >= 0 && srcIdx < src.count);
    assert(dstIdx >= 0 && dstIdx < dst.count);
    assert(count >= 0);
    assert(count <= src.count - srcIdx);
    assert(count <= dst.count - dstIdx);

    memoryCopy(dst.data + dstIdx, src.data + srcIdx, count);
}

arrayClear :: inline (array: [] $T) {
    assert(array.data != null);
    memorySet(array.data, 0, array.count);
}

array :: inline ($type: Type, values: ..type) -> [] type {
    return values;
}

qsort :: inline (array: [] $T, compareFn: (T, T) -> s64) {
    qsort(array, 0, array.count - 1, compareFn);
}

qsort :: inline (array: [] $T, left: s64, right: s64, compareFn: (T, T) -> s64) {
    assert(left >= 0 && left < array.count);
    assert(right >= 0 && right < array.count);

    qsort(array.data, left, right, compareFn);
}

qsort :: inline (array: *$T, count: s64, compareFn: (T, T) -> s64) {
    qsort(array, 0, count - 1, compareFn);
}

qsort :: (array: *$T, left: s64, right: s64, compareFn: (T, T) -> s64) {
    assert(left >= 0 && right >= 0);
    assert(compareFn != null);

    if (left >= right) {
        return;
    }

    middle := left + (right - left) / 2;
    p := array[middle];

    i := left;
    j := right;

    while (true) {
        while (compareFn(array[i], p) < 0) { i += 1; }
        while (compareFn(array[j], p) > 0) { j -= 1; }

        if (i >= j) {
            break;
        }

        tmp := array[i];
        array[i] = array[j];
        array[j] = tmp;

        i += 1;
        j -= 1;
    }

    qsort(array, left, j, compareFn);
    qsort(array, j + 1, right, compareFn);
}

qsort :: inline (array: [] $T, byFn: (T) -> $R) {
    qsort(array, 0, array.count - 1, byFn);
}

qsort :: inline (array: [] $T, left: s64, right: s64, byFn: (T) -> $R) {
    assert(left >= 0 && left < array.count);
    assert(right >= 0 && right < array.count);

    qsort(array.data, left, right, byFn);
}

qsort :: inline (array: *$T, count: s64, byFn: (T) -> $R) {
    qsort(array, 0, count - 1, byFn);
}

qsort :: (array: *$T, left: s64, right: s64, byFn: (T) -> $R) {
    assert(left >= 0 && right >= 0);
    assert(byFn != null);

    if (left >= right) {
        return;
    }

    middle := left + (right - left) / 2;
    p := array[middle];
    by := byFn(p);

    i := left;
    j := right;

    while (true) {
        while (byFn(array[i]) < by) { i += 1; }
        while (byFn(array[j]) > by) { j -= 1; }

        if (i >= j) {
            break;
        }

        tmp := array[i];
        array[i] = array[j];
        array[j] = tmp;

        i += 1;
        j -= 1;
    }

    qsort(array, left, j, byFn);
    qsort(array, j + 1, right, byFn);
}

heapSort :: inline (array: [] $T, compareFn: (T, T) -> s64) {
    heapSort(array, 0, array.count - 1, compareFn);
}

heapSort :: inline (array: [] $T, left: s64, right: s64, compareFn: (T, T) -> s64) {
    assert(left >= 0 && left < array.count);
    assert(right >= 0 && right < array.count);

    heapSort(array.data, left, right, compareFn);
}

heapSort :: inline (array: *$T, count: s64, compareFn: (T, T) -> s64) {
    heapSort(array, 0, count - 1, compareFn);
}

heapSort :: (array: *$T, left: s64, right: s64, compareFn: (T, T) -> s64) {
    assert(left >= 0 && right >= 0);
    assert(compareFn != null);

    if (left >= right) {
        return;
    }

    heap: BinaryHeap(T);
    init(*heap, BinaryHeapOptions(T).{
        capacity = right - left + 1,
        compareFn = compareFn
    });

    for i : left..right {
        push(*heap, array[i]);
    }

    i := 0;
    while (heap.count > 0) {
        array[left + i] = pop(*heap);
        i += 1;
    }

    uninit(*heap);
}

heapSort :: inline (array: [] $T, byFn: (T) -> $R) {
    heapSort(array, 0, array.count - 1, byFn);
}

heapSort :: inline (array: [] $T, left: s64, right: s64, byFn: (T) -> $R) {
    assert(left >= 0 && left < array.count);
    assert(right >= 0 && right < array.count);

    heapSort(array.data, left, right, byFn);
}

heapSort :: inline (array: *$T, count: s64, byFn: (T) -> $R) {
    heapSort(array, 0, count - 1, byFn);
}

heapSort :: inline (array: *$T, left: s64, right: s64, byFn: (T) -> $R) {
    assert(left >= 0 && right >= 0);
    assert(byFn != null);

    heapSort(array.data, left, right, (item1: T, item2: T) -> s32 {
        by1 := byFn(item1);
        by2 := byFn(item2);
        if (b1 < b2) return -1;
        if (b1 > b2) return 1;
        return 0;
    });
}
