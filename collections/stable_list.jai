//
// Copyright (C) 2020 Alejandro Coto Gutiérrez (https://github.com/acoto87)
//
// This software is provided 'as-is', without any express or implied
// warranty.  In no event will the authors be held liable for any damages
// arising from the use of this software.
//
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it
// freely, subject to the following restrictions:
//
// 1. The origin of this software must not be misrepresented; you must not
//    claim that you wrote the original software. If you use this software
//    in a product, an acknowledgment in the product documentation would be
//    appreciated but is not required.
// 2. Altered source versions must be plainly marked as such, and must not be
//    misrepresented as being the original software.
// 3. This notice may not be removed or altered from any source distribution.
//
// It defines a strongly-typed unordered list of elements and its operations.
// This list has the property that it's stable with respect to the indices of
// its elements. Once an element is added to the list, the position in which
// is assigned won't change until the element is removed from the list.
//
StableList :: struct(TItem: Type, bucketCapacity := DEFAULT_BUCKET_CAPACITY) {
    count: s64;
    capacity: s64;
    freeItems: bool;
    freeStart: s64;
    allocator: Allocator;
    buckets: List(*StableListBucket(TItem, bucketCapacity));
}

StableListOptions :: struct {
    capacity: s64 = 8;
    freeItems: bool;
    allocator: Allocator;
}

createStableList :: inline ($T: Type, $bucketCapacity: s64 = DEFAULT_BUCKET_CAPACITY) -> StableList(T, bucketCapacity) {
    list: StableList(T, bucketCapacity);
    init(*list);
    return list;
}

createStableList :: inline ($T: Type, $bucketCapacity: s64 = DEFAULT_BUCKET_CAPACITY, options: StableListOptions) -> StableList(T) {
    list: StableList(T, bucketCapacity);
    init(*list, options);
    return list;
}

init :: inline (list: *$T/StableList) {
    init(list, StableListOptions.{});
}

init :: (list: *$T/StableList, options: StableListOptions) {
    assert(options.capacity > 0);

    list.count = 0;
    list.capacity = 0;
    list.freeStart = -1;
    list.freeItems = options.freeItems;
    list.allocator = options.allocator;

    bucketsOptions: ListOptions;
    bucketsOptions.allocator = list.allocator;
    bucketsOptions.freeItems = true;
    bucketsOptions.capacity = getNumberOfBuckets(list, options.capacity);
    init(*list.buckets, bucketsOptions);

    while (list.capacity < options.capacity) {
        list.capacity += T.bucketCapacity;
        addNewBucket(list);
    }
}

uninit :: (list: *$T/StableList, freeList: bool = false) {
    if (list.buckets.items != null) {
        clear(list);
        uninit(*list.buckets);
    }

    if (freeList) {
        free(list, list.allocator);
    }
}

clear :: (list: *$T/StableList) {
    assert(list.buckets.items != null);

    #if #run isPointer(T.TItem) {
        if (list.freeItems && list.count > 0) {
            for item : list {
                free(item, list.allocator);
            }
        }
    }

    clear(*list.buckets);

    list.freeStart = -1;
    list.count = 0;
}

add :: (list: *$T/StableList, item: T.TItem) -> s64 {
    assert(list.buckets.items != null);

    index := ifx list.freeStart >= 0 then list.freeStart else list.count;
    index = setInternal(list, index, item);
    list.count += 1;
    return index;
}

addNew :: (list: *$T/StableList) -> s64, *T.TItem {
    assert(list.buckets.items != null);

    item: *T.TItem = null;
    index := ifx list.freeStart >= 0 then list.freeStart else list.count;
    index, item = setInternal(list, index, createInstance(T.TItem));
    list.count += 1;
    return index, item;
}

addRange :: inline (list: *$T/StableList, items: ..T.TItem) {
    assert(list.buckets.items != null);

    for item : items {
        add(list, item);
    }
}

addRange :: inline (list: *$T/StableList, items: *T.TItem, count: s64) {
    assert(list.buckets.items != null);

    for i : 0..count-1 {
        add(list, items[i]);
    }
}

indexOf :: (list: *$T/StableList, other: T.TItem) -> s64 {
    assert(list.buckets.items != null);

    for item, index : list {
        if (item == other) {
            return index;
        }
    }

    return -1;
}

indexOf :: (list: *$T/StableList, other: T.TItem, equalsFn: (T.TItem, T.TItem) -> bool) -> s64 {
    assert(list.buckets.items != null);
    assert(equalsFn != null);

    for item, index : list {
        if (equalsFn(item, other)) {
            return index;
        }
    }

    return -1;
}

contains :: inline (list: *$T/StableList, item: T.TItem) -> bool {
    return indexOf(list, item) >= 0;
}

contains :: inline (list: *$T/StableList, item: T.TItem, equalsFn: (T.TItem, T.TItem) -> bool) -> bool {
    return indexOf(list, item, equalsFn) >= 0;
}

removeItem :: inline (list: *$T/StableList, item: T.TItem) {
    index := indexOf(list, item);
    if (index >= 0 && index < list.capacity) {
        removeAt(list, index);
    }
}

removeItem :: inline (list: *$T/StableList, item: T.TItem, equalsFn: (T.TItem, T.TItem) -> bool) {
    index := indexOf(list, item, equalsFn);
    if (index >= 0 && index < list.capacity) {
        removeAt(list, index);
    }
}

removeAt :: (list: *$T/StableList, index: s64) {
    assert(list.buckets.items != null);
    assert(index >= 0 && index < list.capacity);

    bucket, itemIndex := getBucket(list, index);
    assert(bucket != null);
    assert(itemIndex >= 0 && itemIndex < T.bucketCapacity);

    #if #run isPointer(T.TItem) {
        if (list.freeItems) {
            free(bucket.items[itemIndex], list.allocator);
        }
    }

    bucket.status[itemIndex] = list.freeStart;

    list.freeStart = index;
    list.count -= 1;
}

isEmpty :: inline (list: *$T/StableList, index: s64) -> bool {
    assert(list.buckets.items != null);
    assert(index >= 0 && index < list.capacity);

    bucket, itemIndex := getBucket(list, index);
    assert(bucket != null);
    assert(itemIndex >= 0 && itemIndex < T.bucketCapacity);

    return bucket.status[itemIndex] != OCCUPIED;
}

get :: (list: *$T/StableList, index: s64) -> T.TItem {
    assert(list.buckets.items != null);
    assert(index >= 0 && index < list.capacity);

    bucket, itemIndex := getBucket(list, index);
    assert(bucket != null);
    assert(itemIndex >= 0 && itemIndex < T.bucketCapacity);
    assert(bucket.status[itemIndex] == OCCUPIED);
    return bucket.items[itemIndex];
}

tryGet :: (list: *$T/StableList, index: s64) -> bool, T.TItem {
    assert(list.buckets.items != null);
    assert(index >= 0 && index < list.capacity);

    bucket, itemIndex := getBucket(list, index);
    assert(bucket != null);
    assert(itemIndex >= 0 && itemIndex < T.bucketCapacity);
    return bucket.status[itemIndex] == OCCUPIED,
           bucket.items[itemIndex];
}

ref :: (list: *$T/StableList, index: s64) -> *T.TItem {
    assert(list.buckets.items != null);
    assert(index >= 0 && index < list.capacity);

    bucket, itemIndex := getBucket(list, index);
    assert(bucket != null);
    assert(itemIndex >= 0 && itemIndex < T.bucketCapacity);
    assert(bucket.status[itemIndex] == OCCUPIED);
    return *bucket.items[itemIndex];
}

tryGetRef :: (list: *$T/StableList, index: s64) -> bool, *T.TItem {
    assert(list.buckets.items != null);
    assert(index >= 0 && index < list.capacity);

    bucket, itemIndex := getBucket(list, index);
    assert(bucket != null);
    assert(itemIndex >= 0 && itemIndex < T.bucketCapacity);
    return bucket.status[itemIndex] == OCCUPIED,
           *bucket.items[itemIndex];
}

set :: inline (list: *$T/StableList, index: s64, item: T.TItem) {
    assert(list.buckets.items != null);
    assert(index >= 0 && index < list.capacity);

    setInternal(list, index, item);
}

reserve :: inline (list: *$T/StableList, capacity: s64) {
    assert(capacity > 0);

    if (capacity <= list.capacity) {
        return;
    }

    numberOfBuckets := getNumberOfBuckets(list, capacity);
    reserve(*list.buckets, numberOfBuckets);

    while (list.capacity < capacity) {
        list.capacity += T.bucketCapacity;
        addNewBucket(list);
    }
}

for_expansion :: (list: *$T/StableList, body: Code, flags: For_Flags) #expand {
    #assert(!(flags & .REVERSE));

    assert(list.buckets.items != null);

    index := 0;

    for k : 0..list.buckets.count-1 {
        bucket := get(*list.buckets, k);
        if (bucket != null) {
            for i : 0..T.bucketCapacity-1 {
                if (bucket.status[i] == OCCUPIED) {
                    #if flags & .POINTER {
                        `it := *bucket.items[i];
                    } else {
                        `it := bucket.items[i];
                    }
                    `it_index := index;

                    #insert (remove=assert(false)) body;
                }

                index += 1;
            }
        }
    }
}

#scope_file

#import "utils";
#import "math-jai";

DEFAULT_BUCKET_CAPACITY :: 16;

OCCUPIED :: -2;
END_OF_FREE_LIST :: -1;

StableListBucket :: struct(TItem: Type, capacity: s64) {
    status: [capacity] s64; // negative (usually -1) it's occupied,
                            // positive indicate next free index in the whole list
    items: [capacity] TItem;
}

setInternal :: (list: *$T/StableList, index: s64, item: T.TItem) -> s64, *T.TItem {
    bucket, itemIndex := getBucket(list, index);
    if (bucket == null) {
        bucket = addNewBucket(list);
        list.capacity += T.bucketCapacity;
    }

    if (list.freeStart == index) {
        list.freeStart = bucket.status[itemIndex];
    }

    bucket.items[itemIndex] = item;
    bucket.status[itemIndex] = OCCUPIED;

    return index, *bucket.items[itemIndex];
}

getBucket :: (list: *$T/StableList, index: s64) -> *StableListBucket(T.TItem, T.bucketCapacity), s64 {
    bucketIndex := index / T.bucketCapacity;
    itemIndex := index % T.bucketCapacity;

    if (list.buckets.count == 0 || bucketIndex >= list.buckets.count) {
        return null, itemIndex;
    }

    return get(*list.buckets, bucketIndex), itemIndex;
}

getNumberOfBuckets :: (list: *$T/StableList, capacity: s64) -> s64 {
    return cast(s64) ceilf(cast(f32) capacity / T.bucketCapacity);
}

addNewBucket :: inline (list: *$T/StableList) -> *StableListBucket(T.TItem, T.bucketCapacity) {
    bucket := <<addNew(*list.buckets);
    for i : 0..T.bucketCapacity-1 {
        bucket.status[i] = END_OF_FREE_LIST;
    }
    return bucket;
}