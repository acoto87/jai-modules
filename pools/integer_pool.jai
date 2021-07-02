IntegerPool :: struct(T: Type) {
    current: T = 0;
    reuse := true;
    available: Queue(T);
}

init :: (pool: *$T/IntegerPool, start: T.T = 0, reuse := true) {
    pool.current = start;
    pool.reuse = reuse;
    if (pool.reuse) {
        init(*pool.queue);
    }
}

take :: (pool: *$T/IntegerPool) -> T.T {
    if (pool.reuse && pool.available.count > 0) {
        return dequeue(*pool.available);
    }
    value := pool.current;
    pool.current += 1;
    return value;
}

give :: (pool: *$T/IntegerPool, value: T.T) {
    if (pool.reuse) {
        enqueue(*pool.available, value);
    }
}

#scope_file

#import "collections";