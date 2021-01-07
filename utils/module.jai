f32 :: float32;
f64 :: float64;

#load "math.jai";
#load "memory.jai";
#load "arrays.jai";
#load "strings.jai";
#load "random.jai";

clear :: inline (value: *$T) {
    assert(value != null);
    memorySet(value, 0);
}

clear :: inline (array: [] $T) {
    assert(array.data != null);
    memorySet(array.data, 0, array.count);
}

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
time :: (destTime: *time_t) -> time_t #foreign crt;

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

getTime :: Basic.get_time;
assert :: Basic.assert;
print :: Basic.print;
sprint :: Basic.sprint;
formatFloat :: Basic.formatFloat;
FormatFloat :: Basic.FormatFloat;
exit :: Basic.exit;

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

#scope_file

Basic :: #import "Basic";

#import "GL";

#if OS == .WINDOWS {
    crt :: #foreign_system_library "msvcrt";
} else if OS == .LINUX {
    crt :: #foreign_system_library "libc";
}
