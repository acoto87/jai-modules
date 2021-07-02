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

isStructDeclaration :: inline (decl: *CodeDeclaration) -> bool {
    return decl.root_expression && decl.root_expression.kind == .STRUCT;
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

isSubClassOf :: (decl: *CodeDeclaration, baseName: string) -> bool {
    assert(isStructDeclaration(decl));

    codeStruct := cast(*CodeStruct) decl.root_expression;
    assert(codeStruct != null);

    codeBlock := cast(*CodeBlock) codeStruct.block;
    assert(codeBlock != null);

    if (codeBlock.members.count == 0) {
        return false;
    }

    firstMemberDecl := cast(*CodeDeclaration) codeBlock.members[0];
    assert(firstMemberDecl != null);

    if (!(firstMemberDecl.flags & .IS_MARKED_AS_USING)) {
        return false;
    }

    firstMemberTypeInst := cast(*CodeTypeInstantiation) firstMemberDecl.type_inst;
    assert(firstMemberTypeInst != null);

    firstMemberCodeIdent := cast(*CodeIdent) firstMemberTypeInst.type_valued_expression;
    if (firstMemberCodeIdent == null) {
        return false;
    }

    return firstMemberCodeIdent.name == baseName;
}

X64Options :: Compiler.X64_Options;
LlvmOptions :: Compiler.Llvm_Options;

BuildOptions :: Compiler.Build_Options;

Message :: Compiler.Message;
MessageFile :: Compiler.Message_File;
MessageImport :: Compiler.Message_Import;
MessageComplete :: Compiler.Message_Complete;
MessagePhase :: Compiler.Message_Phase;
MessageTypechecked :: Compiler.Message_Typechecked;
MessageDebug_Dump :: Compiler.Message_Debug_Dump;

CodeNode :: Compiler.Code_Node;
CodeArgument :: Compiler.Code_Argument;
CodeProcedureCall :: Compiler.Code_Procedure_Call;
CodeReturn :: Compiler.Code_Return;
CodeWhile :: Compiler.Code_While;
CodeFor :: Compiler.Code_For;
CodeScopeEntry :: Compiler.Code_Scope_Entry;
CodeCompoundDeclaration :: Compiler.Code_Compound_Declaration;
CodeDeclaration :: Compiler.Code_Declaration;
CodeBlock :: Compiler.Code_Block;
CodeIdent :: Compiler.Code_Ident;
CodeTypeInstantiation :: Compiler.Code_Type_Instantiation;
CodeEnum :: Compiler.Code_Enum;
CodeDirectiveThrough :: Compiler.Code_Directive_Through;
CodeDirectiveStaticIf :: Compiler.Code_Directive_Static_If;
CodeDirectiveCode :: Compiler.Code_Directive_Code;
CodeDirectivePokeName :: Compiler.Code_Directive_Poke_Name;
CodeDirectiveLocation :: Compiler.Code_Directive_Location;
CodeDirectiveForeignLibrary :: Compiler.Code_Directive_Foreign_Library;
CodeDirectiveWildcard :: Compiler.Code_Directive_Wildcard;
CodeDirectiveInsert :: Compiler.Code_Directive_Insert;
CodeStruct :: Compiler.Code_Struct;
CodeUsing :: Compiler.Code_Using;
CodeDefer :: Compiler.Code_Defer;
CodeAsm :: Compiler.Code_Asm;
CodeNote :: Compiler.Code_Note;
CodeStructLiteralInfo :: Compiler.Code_Struct_Literal_Info;
CodeArrayLiteralInfo :: Compiler.Code_Array_Literal_Info;
CodePointerLiteralInfo :: Compiler.Code_Pointer_Literal_Info;
CodeLiteral :: Compiler.Code_Literal;
CodeProcedureHeader :: Compiler.Code_Procedure_Header;
CodeProcedureBody :: Compiler.Code_Procedure_Body;
CodeCast :: Compiler.Code_Cast;
CodeSizeOrTypeInfo :: Compiler.Code_Size_Or_Type_Info;
CodeIf :: Compiler.Code_If;
CodeCase :: Compiler.Code_Case;
CodeUnaryOperator :: Compiler.Code_Unary_Operator;
CodeBinaryOperator :: Compiler.Code_Binary_Operator;
CodeDirectiveRun :: Compiler.Code_Directive_Run;
CodeDirectiveImport :: Compiler.Code_Directive_Import;
CodeContext :: Compiler.Code_Context;
CodePushContext :: Compiler.Code_Push_Context;
CodeCommaSeparated_Arguments :: Compiler.Code_Comma_Separated_Arguments;
CodeExtract :: Compiler.Code_Extract;
CodeMakeVarargs :: Compiler.Code_Make_Varargs;
CodeLoopControl :: Compiler.Code_Loop_Control;
CodeSequence :: Compiler.Code_Sequence;
CodeTypeDefinition :: Compiler.Code_Type_Definition;
CodeDirectiveModify :: Compiler.Code_Directive_Modify;
CodeDirectiveScope :: Compiler.Code_Directive_Scope;
CodeDirectiveModuleParameters :: Compiler.Code_Directive_Module_Parameters;
CodeDirectiveBake :: Compiler.Code_Directive_Bake;
CodeDirectiveCaller_Location :: Compiler.Code_Directive_Caller_Location;
CodePlaceholder :: Compiler.Code_Placeholder;

OperatorType :: Compiler.Operator_Type;

InterceptFlags :: Compiler.Intercept_Flags;

Report :: Compiler.Report;
VersionInfo :: Compiler.Version_Info;
TypeInfoFlags :: Compiler.Type_Info_Flags;

createWorkspace  :: Compiler.compiler_create_workspace;
destroyWorkspace :: Compiler.compiler_destroy_workspace;
getCurrentWorkspace :: get_current_workspace; // This is in Preload...
getWorkspaceName :: Compiler.get_name;

getBuildOptions :: Compiler.get_build_options;
setBuildOptions :: Compiler.set_build_options;
setOutputExecutableName :: Compiler.set_output_executable_name;
setBuildFilePath :: Compiler.set_build_file_path;
setOptimizationLevel :: Compiler.set_optimization_level;

beginIntercept :: Compiler.compiler_begin_intercept;
endIntercept :: Compiler.compiler_end_intercept;

waitForMessage :: Compiler.compiler_wait_for_message;

getCommandLineArguments :: Compiler.compiler_get_command_line_arguments;
setCommandLineArguments :: Compiler.compiler_set_command_line_arguments;

getTypeTable :: Compiler.get_type_table;
addBuildFile :: Compiler.add_build_file;
addBuildString :: Compiler.add_build_string;
isSubClassOf :: Compiler.is_subclass_of;

getNodes :: Compiler.compiler_get_nodes;
getCode :: Compiler.compiler_get_code;

report :: Compiler.compiler_report;

getVersionInfo :: Compiler.compiler_get_version_info;
setTypeInfoFlags :: Compiler.compiler_set_type_info_flags;

modifyProcedure :: Compiler.compiler_modify_procedure;
makeProcedureLive :: Compiler.compiler_make_procedure_live;
getSourceFiles :: Compiler.compiler_get_source_files;
customLinkCommandIsComplete :: Compiler.compiler_custom_link_command_is_complete;
getStructLocation :: Compiler.compiler_get_struct_location;
addLibrarySearchDirectory :: Compiler.compiler_add_library_search_directory;
addDataSection :: Compiler.add_data_section;
preCompile :: Compiler.precompile;
compileAndGetSingleProcedure :: Compiler.compile_and_get_single_procedure;
makeIntegerLiteral :: Compiler.make_integer_literal;
makeStringLiteral :: Compiler.make_string_literal;
makeLocation :: Compiler.make_location;

#scope_file

Compiler :: #import "Compiler";

#import "utils";
#import "strings";
