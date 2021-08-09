// @Note: call this to build the dll and lib files
build :: (dll: bool = true, lib: bool = true) {
    if (dll) {
        print("Building dynamic library:\n");
        buildCppDynamicLib("jai-modules/flecs-jai/lib/win64/flecs", "jai-modules/flecs-jai/source/main.c", "jai-modules/flecs-jai/source/flecs.c", debug = true);
    }

    if (lib) {
        print("Building static library:\n");
        buildCppStaticLib("jai-modules/flecs-jai/lib/win64/flecs", "jai-modules/flecs-jai/source/main.c", "jai-modules/flecs-jai/source/flecs.c");
    }

    buildCppDone();
}

#scope_file

#import "utils";

BuildCpp :: #import "BuildCpp";
buildCppDynamicLib :: BuildCpp.build_cpp_dynamic_lib;
buildCppStaticLib :: BuildCpp.build_cpp_static_lib;
buildCppDone :: BuildCpp.build_cpp_done;