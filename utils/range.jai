Range :: struct(type: Type) {
    from: s64;
    to: s64;
    step: s64;
    toInclusive: bool;
}

range :: (from: s64, to: s64, toInclusive: bool = false) -> Range(s64) {
    return range(s64, from, to, toInclusive);
}

range :: (from: s64, to: s64, step: s64, toInclusive: bool = false) -> Range(s64) {
    return range(s64, from, to, step, toInclusive);
}

range :: ($type: Type, from: s64, to: s64, toInclusive: bool = false) -> Range(type) {
    step := ifx from <= to then 1 else -1;
    return range(type, from, to, step, toInclusive);
}

range :: ($type: Type, from: s64, to: s64, step: s64, toInclusive: bool = false) -> Range(type) {
    r: Range(type);
    r.from = from;
    r.to = to;
    r.step = step;
    r.toInclusive = toInclusive;
    return r;
}

for_expansion :: (range: *$T/Range, body: Code, $flags: For_Flags) #expand {
    #assert(!(flags & .POINTER));
    #assert(!(flags & .REVERSE));

    size := abs(cast(s64) range.from - cast(s64) range.to);
    dir := sign(range.step);
    step := abs(range.step);

    index := 0;
    current := 0;
    while (true) {
        if (range.toInclusive && current > size) break;
        else if (!range.toInclusive && current >= size) break;

        `it := cast,no_check(T.type) (range.from + current * dir);
        `it_index := index;

        current += step;
        index += 1;

        #insert (remove=assert(false)) body;
    }
}
