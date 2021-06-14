#load "partial_enums.jai";
#load "run_at_phase.jai";

ParsedNote :: struct {
    ident: string;
    args: [10] string;
}

isProcedureHeader :: inline (decl: *CodeDeclaration) -> bool {
    return decl.root_expression && decl.root_expression.kind == .PROCEDURE_HEADER;
}

isEnumDeclaration :: inline (decl: *CodeDeclaration) -> bool {
    return decl.root_expression && decl.root_expression.kind == .ENUM;
}

hasNote :: inline (decl: *CodeDeclaration, text: string) -> bool {
    for note : decl.notes {
        if (note.text == text) {
            return true;
        }
    }
    return false;
}

parseNote :: (note: *CodeNote) -> ParsedNote {
    parts := splitAny(note.text, " ();,", StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
    assert(parts.count > 0);

    parsedNote: ParsedNote;
    parsedNote.ident = parts[0];

    if (parts.count > 1) {
        for i : range(1, parts.count) {
            parsedNote.args[i-1] = parts[i];
        }
    }

    return parsedNote;
}

parseNotes :: (decl: *CodeDeclaration) -> [] ParsedNote {
    if (decl.notes.count == 0) {
        return ParsedNote.[];
    }

    parsedNotes := allocArray(ParsedNote, decl.notes.count);
    for note, i : decl.notes {
        parsedNotes[i] = parseNote(note);
    }
    return parsedNotes;
}

#scope_file

Compiler :: #import "Compiler";
Message :: Compiler.Message;
CodeDeclaration :: Compiler.Code_Declaration;
CodeNote :: Compiler.Code_Note;

#import "utils";
#import "strings";
