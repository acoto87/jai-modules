parseBool :: inline (str: string) -> (value: bool, success: bool) {
    if equals(str, "true", StringComparison.OrdinalIgnoreCase) return (value = true, success = true);
    if equals(str, "false", StringComparison.OrdinalIgnoreCase) return (value = false, success = true);
    return (value = false, success = false);
}

parseEnum :: inline (str: string, $T : Type) -> (value: T, success: bool) {
    return getEnumValueByName(T, str);
}

parseFloat :: inline (str: string, $T: Type = f64) -> (value: T, success: bool) {
    value64, success := Basic.string_to_float64(str);
    return cast(T) value64, success;
}

parseInt :: inline (str: string, $T: Type = s64, base := 10) -> (value: T, success: bool) {
    value64, success := Basic.string_to_int(str, base);
    return cast(T) value64, success;
}
