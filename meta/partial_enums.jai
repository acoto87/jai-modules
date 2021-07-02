partialEnums :: (workspace: Workspace, message: *Message) {
    if message.kind == {
        case .TYPECHECKED; {
            typechecked := cast(*MessageTypechecked) message;

            for decl : typechecked.declarations {
                if (isEnumDeclaration(decl)) {
                    parsedNotes := parseNotes(decl);
                    if (parsedNotes.count > 0) {
                        for note : parsedNotes {
                            if (startsWith(note.ident, "Partial")) {
                                assert(!isEmpty(note.args[0]));

                                registerPartialEnum(note.args[0], decl);
                            }
                        }
                    }
                }
            }
        }

        case .PHASE; {
            phase := cast(*MessagePhase) message;
            if (phase.phase == .TYPECHECKED_ALL_WE_CAN) {
                generatePartialEnums(workspace);
            }
        }
    }
}

#scope_file

partialEnums: HashMap(string, *List(*CodeDeclaration));

registerPartialEnum :: (enumName: string, decl: *CodeDeclaration) {
    if (partialEnums.entries == null) {
        options: HashMapOptions(string, *List(*CodeDeclaration));
        init(*partialEnums, options);
    }

    found, declarations := get(*partialEnums, enumName);
    if (!found) {
        declarations = alloc(List(*CodeDeclaration));
        init(declarations);
        set(*partialEnums, enumName, declarations);
    }

    add(declarations, decl);
}

generatePartialEnums :: (workspace: Workspace) {
    if (partialEnums.entries == null) {
        return;
    }

    keys := getKeys(*partialEnums);
    defer free(keys);

    for key : keys {
        _, declarations := get(*partialEnums, key);
        generatePartialEnum(workspace, key, declarations);

        uninit(declarations, true);
        removeKey(*partialEnums, key);
    }
}

generatePartialEnum :: (workspace: Workspace, enumName: string, enumDeclarations: *List(*CodeDeclaration)) {
    NameValuePair :: struct {
        name: string;
        value: u16;
    };

    members := createList(NameValuePair);
    defer uninit(*members);

    for decl : enumDeclarations {
        enumExpr := cast(*CodeEnum) decl.root_expression;
        if (enumExpr.block != null) {
            block := cast(*CodeBlock) enumExpr.block;
            for member : block.members {
                if (member.kind == .DECLARATION) {
                    memberDecl := cast(*CodeDeclaration) member;
                    if (memberDecl.root_expression.kind == .LITERAL) {
                        literal := cast(*CodeLiteral) memberDecl.root_expression;
                        if (literal.value_type == .NUMBER) {
                            pair: NameValuePair = ---;
                            pair.name = memberDecl.name;
                            pair.value = cast(u16) literal._u64;
                            add(*members, pair);
                        }
                    }
                }
            }
        }
    }

    if (members.count > 0) {
        sort(*members, (p1: NameValuePair, p2: NameValuePair) -> s64 {
            if (p1.value < p2.value) then return -1;
            if (p1.value > p2.value) then return 1;
            return 0;
        });

        for i : range(1, members.count) {
            if (members[i].value == members[i-1].value) {
                report(
                    tprint(
                        "Some EntityType members has same value. That was probably unintentional. % == % == %",
                        members[i-1].name,
                        members[i].name,
                        members[i].value),
                    mode = .WARNING);
            }
        }

        builder: StringBuilder;
        defer freeBuffers(*builder);

        printToBuilder(*builder, "% :: enum u16 {\n", enumName);

        for member : members {
            printToBuilder(*builder, "    % :: %;\n", member.name, member.value);
        }

        appendToBuilder(*builder, "}");
        entityTypeEnum := builderToString(*builder);
        addBuildString(entityTypeEnum, workspace);
    }
}

#import "collections";
