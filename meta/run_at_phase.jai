runAtPhase :: (workspace: Workspace, message: *Message) {
    if message.kind == {
        case .TYPECHECKED; {
            typechecked := cast(*MessageTypechecked) message;

            for decl : typechecked.declarations {
                if (isProcedureHeader(decl)) {
                    proc := cast(*CodeProcedureHeader) decl.root_expression;

                    parsedNotes := parseNotes(decl);
                    if (parsedNotes.count > 0) {
                        for note : parsedNotes {
                            if (startsWith(note.ident, "RunAtPhase")) {
                                assert(!isEmpty(note.args[0]));

                                phaseValue := getMessagePhaseValue(note.args[0]);
                                registerToRun(phaseValue, proc);
                            }
                        }
                    }
                }
            }
        }

        case .PHASE; {
            phase := cast(*MessagePhase) message;
            runProceduresAtPhase(workspace, cast(u32) phase.phase);
        }
    }
}

#scope_file

proceduresToRunByPhases: HashMap(u32, *List(*CodeProcedureHeader));

registerToRun :: (phase: u32, procedureHeader: *CodeProcedureHeader) {
    if (proceduresToRunByPhases.entries == null) {
        options: HashMapOptions(u32, *List(*CodeProcedureHeader));
        init(*proceduresToRunByPhases, options);
    }

    found, procedures := get(*proceduresToRunByPhases, phase);
    if (!found) {
        procedures = alloc(List(*CodeProcedureHeader));
        init(procedures);
        set(*proceduresToRunByPhases, phase, procedures);
    }

    add(procedures, procedureHeader);
}

getMessagePhaseValue :: (phaseStr: string) -> u32 {
    if phaseStr == {
        case "ALL_SOURCE_CODE_PARSED"; return cast(u32) 0;
        case "TYPECHECKED_ALL_WE_CAN"; return cast(u32) 1;
        case "ALL_TARGET_CODE_BUILT"; return cast(u32) 2;
        case "PRE_WRITE_EXECUTABLE"; return cast(u32) 3;
        case "POST_WRITE_EXECUTABLE"; return cast(u32) 4;
        case "READY_FOR_CUSTOM_LINK_COMMAND"; return cast(u32) 5;
    }
}

runProceduresAtPhase :: (workspace: Workspace, phase: u32) {
    if (proceduresToRunByPhases.entries == null) {
        return;
    }

    found, procedures := get(*proceduresToRunByPhases, phase);
    if (found) {
        for proc : procedures {
            runDirective := tprint("#run %();", proc.name);
            addBuildString(runDirective, workspace);
        }

        // ensure the procedures only runs once
        uninit(procedures, true);
        removeKey(*proceduresToRunByPhases, phase);
    }
}

#import "collections";
