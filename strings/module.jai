#load "cstrings.jai";
#load "parsing.jai";

isEmpty :: inline (s: string) -> bool {
    return s.count == 0 || s.data == null;
}

for_expansion :: (str: *string, body: Code, flags: For_Flags) #expand {
    #assert(!(flags & .REVERSE));
    #assert(!(flags & .POINTER));

    for i : 0..str.count-1 {
        `it := str[i];
        `it_index := i;
        #insert (remove=assert(false)) body;
    }
}

StringBuilder :: Basic.String_Builder;
freeBuffers :: Basic.free_buffers;
appendToBuilder :: Basic.append;
printToBuilder :: Basic.print_to_builder;
builderToString :: Basic.builder_to_string;

StringComparison :: enum {
    Ordinal :: 0;
    OrdinalIgnoreCase :: 1;
}

toUpper :: Basic.to_upper;
toLower :: Basic.to_lower;
isAlpha :: Basic.is_alpha;
isDigit :: Basic.is_digit;
isAlphaNumeric :: Basic.is_alnum;
isSpace :: Basic.is_space;
isPrintable :: Basic.is_print;
isAny :: Basic.is_any;

compare :: inline (a: string, b: string, $$ comparison := StringComparison.Ordinal) -> s64 #must {
    return ifx comparison == StringComparison.OrdinalIgnoreCase
        then String.compare_no_case(a, b)
        else String.compare(a, b);
}

equals :: inline (a: string, b: string, $$ comparison := StringComparison.Ordinal) -> bool #must {
    return ifx comparison == StringComparison.OrdinalIgnoreCase
        then String.equal_nocase(a, b)
        else String.equal(a, b);
}

contains :: inline (str: string, substring: string, $$ comparison := StringComparison.Ordinal) -> bool #must {
    return ifx comparison == StringComparison.OrdinalIgnoreCase
        then String.contains_nocase(str, substring)
        else String.contains(str, substring);
}

startsWith :: inline (str: string, prefix: string, $$ comparison := StringComparison.Ordinal) -> bool #must {
    return ifx comparison == StringComparison.OrdinalIgnoreCase
        then String.begins_with_nocase(str, prefix)
        else String.begins_with(str, prefix);
}

endsWith :: inline (str: string, suffix: string, $$ comparison := StringComparison.Ordinal) -> bool #must {
    return ifx comparison == StringComparison.OrdinalIgnoreCase
        then String.ends_with_nocase(str, suffix)
        else String.ends_with(str, suffix);
}

indexOf :: (str: string, char: u8, $$ comparison := StringComparison.Ordinal) -> s64 {
    if (comparison == StringComparison.OrdinalIgnoreCase) {
        charLower := toLower(c);
        for 0..str.count-1 {
            if toLower(str[it]) == charLower return it;
        }
    } else {
        for 0..str.count-1 {
            if str[it] == char return it;
        }
    }
    return -1;
}

indexOf :: (str: string, substring: string, $$ comparison := StringComparison.Ordinal) -> s64 {
    return ifx comparison == StringComparison.OrdinalIgnoreCase
        then String.index_of_string_nocase(a, b)
        else String.index_of_string(a, b);
}

lastIndexOf :: (str: string, char: u8, $$ comparison := StringComparison.Ordinal) -> s64 {
    if (comparison == StringComparison.OrdinalIgnoreCase) {
        charLower := toLower(c);
        for < str.count-1..0 {
            if toLower(str[it]) == charLower return it;
        }
    } else {
        for < str.count-1..0 {
            if str[it] == char return it;
        }
    }
    return -1;
}

lastIndexOf :: (str: string, substring: string, $$ comparison := StringComparison.Ordinal) -> s64 {
    return ifx comparison == StringComparison.OrdinalIgnoreCase
        then String.index_of_string_nocase(a, b)
        else String.index_of_string(a, b);
}

toLower :: (str: string, $$ inPlace := false) -> string {
    if (inPlace) {
        String.to_lower(str);
        return str;
    }

    strLower := allocString(str.count, str);
    String.to_lower(strLower);
    return strLower;
}

toUpper :: (str: string, $$ inPlace := false) -> string {
    if (inPlace) {
        String.to_upper(str);
        return str;
    }

    strLower := allocString(str.count, str);
    String.to_upper(strLower);
    return strLower;
}

trimLeft :: String.trim_left;
trimRight :: String.trim_right;
trim :: String.trim;

subString :: String.slice;
subString :: inline (str: string, index: s64) -> string #must {
    return substring(str, index, str.count - index);
}

subStringCount :: String.count;

join :: String.join;

StringSplitOptions :: enum_flags {
    None :: 0;
    RemoveEmptyEntries :: 1;
    TrimEntries:: 2;
}

stringFromChar :: (c: u8) -> string {
    str := allocString(1);
    str[0] = c;
    return str;
}

split :: (str: string, separator: u8, $$ options := StringSplitOptions.None) -> [] string {
    separatorStr := stringFromChar(separator);
    defer free(separatorStr);
    return split(str, separatorStr, options);
}

split :: (str: string, separator: string, $$ options := StringSplitOptions.None) -> [] string {
    entries := String.split(str, separator);

    if (hasFlags(options, StringSplitOptions.TrimEntries)) {
        for i : 0..entries.count-1 {
            entries[i] = trim(entries[i]);
        }
    }

    if (hasFlags(options, StringSplitOptions.RemoveEmptyEntries)) {
        emptyEntriesCount := 0;
        for i : 0..entries.count-1 {
            if (isEmpty(entries[i])) {
                emptyEntriesCount += 1;
            }
        }

        if (emptyEntriesCount > 0) {
            newEntries := allocArray(string, emptyEntriesCount);
            i, j := 0;
            while (i < entries.count && j < newEntries.count) {
                if (!isEmpty(entries[i])) {
                    newEntries[j] = entries[i];
                    j += 1;
                }
                i += 1;
            }
            free(entries);
            entries = newEntries;
        }
    }

    return entries;
}

replace :: String.replace;

#scope_module

Basic :: #import "Basic";
String :: #import "String";

#import "utils";