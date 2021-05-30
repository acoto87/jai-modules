CheatsPanel :: struct {
    enabled: bool;
    visible: bool;
    position: s32;
    prefix: string;
    text: FixedString;
    feedback: bool;
    feedbackTime: f32;
    feedbackText: string;
}

CheatId :: s16;
CheatFunc :: #type (arguments: string);

CheatDescriptor :: struct {
    id: CheatId;
    text: string;
    requireArguments: bool;
    fn: CheatFunc;
}

CheatsManager :: struct {
    cheats: HashMap(CheatId, CheatDescriptor);
}

initCheatsManager :: (manager: *CheatsManager) {
    init(*manager.cheats, HashMapOptions(CheatId, CheatDescriptor).{
        hashFn = hashCheatId
    });
}

registerCheat :: (id: CheatId, descriptor: CheatDescriptor) {
    ctx := context.gameContext;
    assert(ctx != null);

    scene := ctx.scene;
    assert(scene != null);

    cheatsManager := *scene.cheatsManager;
    if (contains(*cheatsManager.cheats, id)) {
        logWarning("There is an existing cheat (%, %). Overriding it.\n", id, descriptor.text);
    }
    set(*cheatsManager.cheats, id, descriptor);
}

unregisterCheat :: (id: CheatId) {
    ctx := context.gameContext;
    assert(ctx != null);

    scene := ctx.scene;
    assert(scene != null);

    cheatsManager := *scene.cheatsManager;
    removeKey(*cheatsManager.cheats, id);
}

applyCheat :: (text: string) {
    ctx := context.gameContext;
    assert(ctx != null);

    scene := ctx.scene;
    assert(scene != null);

    cheatsManager := *scene.cheatsManager;

    for entry : cheatsManager.cheats {
        cheat := entry.value;
        if (!cheat.requireArguments) {
            if (equal_nocase(text, cheat.text)) {
                cheat.fn("");
                return;
            }
        } else {
            if (begins_with_nocase(text, cheat.text)) {
                arguments := trim(slice(text, cheat.text.count, text.count - cheat.text.count));
                cheat.fn(arguments);
                return;
            }
        }
    }

    // if we reach here no cheat was applied
    logWarning("Unknown cheat: %\n", text);
}

cheatsEnabledAndVisible :: inline () -> bool {
    ctx := context.gameContext;
    assert(ctx != null);

    scene := ctx.scene;
    assert(scene != null);

    return scene.cheatsPanel.enabled && scene.cheatsPanel.visible;
}

#scope_file

hashCheatId :: inline (id: CheatId) -> s64 {
    return cast(s64) id;
}

#import "String";
