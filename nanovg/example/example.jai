Compiler :: #import "Compiler";

// @Note: To compile a different example a change is needed in the nanovg/modules.jai
// to set the appropriate GLXX parameter
workspaceName :: "example_gl2";
executableName :: "example_gl2.exe";
buildFileName :: "example_gl2.jai";

build :: (building_executable := true, build_release := false) {
    set_working_directory(#filepath);

    // Don't produce output for this default workspace
    opts := Compiler.get_build_options();
    opts.output_type = Compiler.Build_Output_Type.NO_OUTPUT;
    Compiler.set_build_options(opts);

    // Start a new workspace for the actual program
    workspace := Compiler.compiler_create_workspace(workspaceName);
    opts.output_type = Compiler.Build_Output_Type.EXECUTABLE;
    opts.output_executable_name = executableName;
    opts.output_path = "build/";
    opts.shorten_filenames_in_error_messages = false;
    // opts.backend = Compiler.Backend.X64;
    array_add(*opts.modules_search_path_array, "../..");
    Compiler.set_build_options(opts, workspace);
    Compiler.add_build_file(buildFileName, workspace);

    make_directory_if_it_does_not_exist(opts.output_path);
    copy_files_recursively("libs", opts.output_path);
}

make_directory_tree :: (_path: string) {
    path := _path;
    if path.count && path[path.count-1] == #char "/" {
        path.count -= 1;
    }

    if path == "" return;
    parent := path_strip_filename(path);
    make_directory_tree(parent);
    make_directory_if_it_does_not_exist(path);
}

copy_files_recursively :: (source: string, dest: string) {
    paths: [2] string;
    paths[0] = source;
    paths[1] = dest;

    visitor :: (info: *File_Visit_Info, paths: [2] string) {
        relative_path := info.full_name;
        advance(*relative_path, paths[0].count);
        out_path := concatenate(paths[1], "/", relative_path);
        make_directory_tree(path_strip_filename(out_path));
        copy_file(info.full_name, out_path);
    }

    res := visit_files(paths[0], true, paths, visitor);
    assert(res);
}

#run build();

#scope_file

#import "Basic";
#import "File";
#import "File_Utilities";
#import "String";