copyFiles :: (source: string, dest: string) {
    visitor :: (info: *FileVisitInfo, paths: [2] string) {
        relativePath := subString(info.full_name, paths[0].count);
        outPath := join(paths[1], "/", relativePath);
        makeDirectoryTree(getDirectoryPath(outPath));
        copyFile(info.full_name, outPath);
    }

    paths: [2] string;
    paths[0] = source;
    paths[1] = dest;

    res := visitFiles(paths[0], true, paths, visitor);
    assert(res);
}

makeDirectoryTree :: (directoryPath: string) {
    path := directoryPath;
    if (path.count > 0 && path[path.count - 1] == #char "/") {
        path.count -= 1;
    }

    if (path == "") {
        return;
    }

    parent := getDirectoryPath(path);
    makeDirectoryTree(parent);
    makeDirectoryIfNotExist(path);
}

makeDirectoryIfNotExist :: File.make_directory_if_it_does_not_exist;
FileVisitInfo :: FileUtilities.File_Visit_Info;
copyFile :: FileUtilities.copy_file;
visitFiles :: FileUtilities.visit_files;
getDirectoryPath :: String.path_strip_filename;

#scope_file

File :: #import "File";
FileUtilities :: #import "File_Utilities";
String :: #import "String";
