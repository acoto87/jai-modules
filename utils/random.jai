randomNext :: () -> s32 {
    return cast(s32) Random.random_get();
}

randomNext01 :: Random.random_get_zero_to_one;

randomSeed :: inline (seed: s32) {
    Random.random_seed(cast(s32) seed);
}

chance :: inline (p: s32) -> bool {
    return ((randomNext() % 100) < p);
}

chance :: inline (p: f32) -> bool {
    return ((randomNext() % 100) < cast(s32) (p * 100));
}

randomNext :: inline (a: s32, b: s32) -> s32 {
    return cast(s32) Random.random_get_within_range(cast(f32) a, cast(f32) b);
}

randomNext :: inline (a: f32, b: f32) -> f32 {
    return Random.random_get_within_range(a, b);
}

randomNext :: inline (a: f64, b: f64) -> f64 {
    return cast(f64) Random.random_get_within_range(cast(f32) a, cast(f32) b);
}

#scope_file

Random :: #import "Random";
