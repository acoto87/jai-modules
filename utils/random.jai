// This is the same implementation of PCG.jai in compiler modules, but bounded the internal state to a struct.
// A C implementation of this can also be found here: https://github.com/imneme/pcg-c-basic/
//
// Global functions (the ones without rnd: *PCG32Random parameter are not thread-safe)
// For now it's left to the user to create and use a specific PCG32Random for each thread, local function or whatever.
//
PCG32Random :: struct  {
    state: u64; // The internal state of the generator.
    inc: u64;   // Which RNG sequence is being generated. Must *always* be odd.
}

randomSeed :: (initState: u64, initSeq: u64) {
    randomSeed(*globalRng, initState, initSeq);
}

randomNext :: () -> u32 {
    ensureGlobalRandom();
    return randomNext(*globalRng);
}

randomNext :: (max: u32) -> u32 {
    ensureGlobalRandom();
    return randomNext(*globalRng, max);
}

randomNext :: (min: s32, max: s32) -> s32 {
    ensureGlobalRandom();
    return randomNext(*globalRng, min, max);
}

randomNext :: (min: f32, max: f32) -> f32 {
    ensureGlobalRandom();
    return randomNext(*globalRng, min, max);
}

randomNext01 :: () -> f32 {
    ensureGlobalRandom();
    return randomNext01(*globalRng);
}

randomSeed :: (rng: *PCG32Random, initState: u64, initSeq: u64) {
    assert(rng != null);

    rng.state = 0;
    rng.inc = (initSeq << 1) | 1;
    randomNext(rng);
    rng.state += initState;
    randomNext(rng);
}

randomNext :: (rng: *PCG32Random) -> u32 {
    assert(rng != null);

    oldState := rng.state;
    rng.state = oldState * 6364136223846793005 + rng.inc;
    xorshifted := cast,no_check(u32) (((oldState >> 18) ^ oldState) >> 27);
    rot := cast(u32) (oldState >> 59);
    return (xorshifted >> rot) | (xorshifted << (neg(rot) & 31));
}

randomNext :: (rng: *PCG32Random, max: u32) -> u32 {
    assert(rng != null);

    threshold := neg(max) % max;
    while true {
        r := randomNext(rng);
        if r >= threshold return r % max;
    }
    return 0;
}

randomNext :: (rng: *PCG32Random, min: s32, max: s32) -> s32 {
    assert(rng != null);
    assert(min <= max);
    return min + cast(s32) (randomNext01(rng) * cast(f32) (max - min));
}

randomNext :: (rng: *PCG32Random, min: f32, max: f32) -> f32 {
    assert(rng != null);
    assert(min <= max);
    return min + randomNext01(rng) * (max - min);
}

randomNext01 :: (rng: *PCG32Random) -> f32 {
    assert(rng != null);
    return cast(f32) (cast(f64) randomNext(rng) * (1.0/U32_MAX)); // 1.0/U32_MAX
}

#scope_file

globalRng := PCG32Random.{
    state = 0,
    inc = 0
};

ensureGlobalRandom :: () {
    if (globalRng.state == 0 && globalRng.inc == 0) {
        randomSeed(*globalRng, cast(u64) time(null), cast(u64) time(null));
    }
}

neg :: inline (x: u32) -> u32 {
    return ~x + 1;
}
