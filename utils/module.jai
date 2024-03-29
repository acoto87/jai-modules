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
// utils-jai is a library written in Jai.
//
// It includes commonly used utilities.
//
f32 :: float32;
f64 :: float64;

#load "color.jai";
#load "memory.jai";
#load "memory_buffer.jai";
#load "arrays.jai";
#load "fixed_string.jai";
#load "random.jai";
#load "log.jai";
#load "enums.jai";
#load "range.jai";
#load "reflection.jai";
#load "hash.jai";
#load "io.jai";

measure :: (message: string, code: Code, prev: Code = null, post: Code = null) #expand {
    print("--- Start % ---\n", message);
    #if prev {
        #insert prev;
    }
    start := getTime();
    #insert code;
    end := getTime();
    #if post {
        #insert post;
    }
    print("Time: % seconds\n", formatFloat(end - start, trailing_width=4));
    print("--- End % ---\n", message);
}

time_t :: s64;

tm :: struct {
    sec : s32; // seconds after the minute: [0-60]
    min : s32; // minutes after the hour: [0-59]
    hour : s32; // hours after midnight: [0-23]
    mday : s32; // day of the month: [1-31]
    mon : s32; // months since January: [0-11]
    year : s32; // years since 1900
    wday : s32; // days since Sunday: [0-6]
    yday : s32; // days since January 1: [0-365]
    isdst : s32; // daylight saving time flag: < 0, 0, or > 0

    gmtoff: s64;
    zone: *u8;
}

time :: (t: *time_t) -> time_t #foreign crt;
localtime :: (t: *time_t) -> *tm #foreign crt;

FILE :: void;

SEEK_SET :: 0;
SEEK_CUR :: 1;
SEEK_END :: 2;

fopen :: (path: *u8, mode: *u8) -> *FILE #foreign crt;
fclose :: (stream: *FILE) -> s32 #foreign crt;
ftell :: (stream: *FILE) -> s64 #foreign crt;
fread :: (ptr: *void, size: s64, count: s64, stream: *FILE) -> s64 #foreign crt;
fwrite :: (ptr: *void, size: s64, count: s64, stream: *FILE) -> s64 #foreign crt;
fseek :: (stream: *FILE, offset: s64, whence: s32) -> s32 #foreign crt;
#if OS == .WINDOWS {
    access :: (path: *u8, mode: s32) -> s32 #foreign crt "_access";
} else if OS == .LINUX {
    access :: (path: *u8, mode: s32) -> s32 #foreign crt;
}

getTime :: Basic.get_time;
assert :: Basic.assert;
print :: Basic.print;
sprint :: Basic.sprint;
tprint :: Basic.tprint;
formatFloat :: Basic.formatFloat;
FormatFloat :: Basic.FormatFloat;
formatInt :: Basic.formatInt;
FormatInt :: Basic.FormatInt;
formatStruct :: Basic.formatStruct;
FormatStruct :: Basic.FormatStruct;
getCommandLineArguments :: Basic.get_command_line_arguments;
exit :: Basic.exit;
resetTemporaryStorage :: Basic.reset_temporary_storage;

setWorkingDirectory :: Basic.set_working_directory;
getWorkingDirectory :: Basic.get_working_directory;

arrayAdd :: Basic.array_add;

glCheckOpenGLVersion :: () {
    vendor := glGetString(GL_VENDOR);
    print("Vendor: %\n", toString(vendor));

    renderer := glGetString(GL_RENDERER);
    print("Renderer: %\n", toString(renderer));

    version := glGetString(GL_VERSION);
    print("Version: %\n", toString(version));

    glslVersion := glGetString(GL_SHADING_LANGUAGE_VERSION);
    print("GLSL Version: %\n", toString(glslVersion));

    extensions := glGetString(GL_EXTENSIONS);
    print("Extensions: %\n", toString(extensions));
}

glLoad :: (getProcAddress: GetProcAddressFunction = null) {
    gl_load(*gl, getProcAddress);
}

inRange :: inline (x: s32, min: s32, max: s32) -> bool {
    return x >= min && x < max;
}

KeyValuePair :: struct(TKey: Type, TValue: Type) {
    key: TKey;
    value: TValue;
}

createKeyValuePair :: inline (key: $TKey, value: $TValue) -> KeyValuePair(TKey, TValue) {
    result: KeyValuePair(TKey, TValue) = ---;
    result.key = key;
    result.value = value;
    return result;
}

#scope_module

Basic :: #import "Basic";

#import "strings";

#scope_file

#import "GL";

#if OS == .WINDOWS {
    crt :: #foreign_system_library "msvcrt";
} else if OS == .LINUX {
    crt :: #foreign_system_library "libc";
}
