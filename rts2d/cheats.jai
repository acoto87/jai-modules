CheatId :: u16;
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

BuiltInCheat :: enum u16 {
    Music :: 100;   // Music #: Set volume music (enter 1-45 for #)
                    // Music {on|off}: Enable or disable music
    Sound;          // Sound {on|off}: Enable or disable sounds
    MusicVol;       // Music volume #: Set volume of music (enter 0-100 for #)
    SoundVol;       // Sound volume #: Set volume of sounds (enter 0-100 for #)
    GlobalScale;    // Scale #: Set global scale (enter 1-5 for #)
    GlobalSpeed;    // Speed #: Set global speed (enter 1-5 for #)
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
    if (containsKey(*cheatsManager.cheats, id)) {
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
            }
        } else {
            if (begins_with_nocase(text, cheat.text)) {
                arguments := trim(slice(text, cheat.text.count, text.count - cheat.text.count));
                cheat.fn(arguments);
            }
        }
    }
}

registerBuiltInCheats :: () {
    for desc : builtInCheatDescriptors {
        registerCheat(desc.id, desc);
    }
}

#scope_file

Basic :: #import "Basic";
parseInt :: Basic.string_to_int;

String :: #import "String";

hashCheatId :: inline (id: CheatId) -> s64 {
    return cast(s64) id;
}

builtInCheatDescriptors : [] CheatDescriptor = .[
    // built in
    .{ cast(u16) BuiltInCheat.MusicVol,         "Music vol",                true,   applyMusicVolCheat    },
    .{ cast(u16) BuiltInCheat.SoundVol,         "Sound vol",                true,   applySoundVolCheat    },
    .{ cast(u16) BuiltInCheat.Music,            "Music",                    true,   applyMusicCheat       },
    .{ cast(u16) BuiltInCheat.Sound,            "Sound",                    true,   applySoundCheat       },
    .{ cast(u16) BuiltInCheat.GlobalScale,      "Scale",                    true,   applyGlobalScaleCheat },
    .{ cast(u16) BuiltInCheat.GlobalSpeed,      "Speed",                    true,   applyGlobalSpeedCheat },
];

applyMusicCheat :: (arguments: string) {
    ctx := cast(*GameContext) context.gameContext;
    assert(ctx != null);

    if (!ctx.cheatsEnabled) {
        return;
    }

    if (equal_nocase(arguments, "on")) {
        ctx.musicEnabled = true;
        setFlashText("Music on");
    } else if (equal_nocase(arguments, "off")) {
        ctx.musicEnabled = false;
        setFlashText("Music off");
    }
}

applySoundCheat :: (arguments: string) {
    ctx := cast(*GameContext) context.gameContext;
    assert(ctx != null);

    if (!ctx.cheatsEnabled) {
        return;
    }

    if (equal_nocase(arguments, "on")) {
        ctx.soundEnabled = true;
        setFlashText("Sounds on");
    } else if (equal_nocase(arguments, "off")) {
        ctx.soundEnabled = false;
        setFlashText("Sounds off");
    }
}

applyMusicVolCheat :: (arguments: string) {
    ctx := cast(*GameContext) context.gameContext;
    assert(ctx != null);

    if (!ctx.cheatsEnabled) {
        return;
    }

    musicVol, success := parseInt(arguments);
    if (success) {
        musicVol = clamp(musicVol, 0, 100);

        // round the argument to a value multiple of 5
        if musicVol % 5 == {
            case 1; { musicVol -= 1; }
            case 2; { musicVol -= 2; }
            case 3; { musicVol += 2; }
            case 4; { musicVol += 1; }
            case; {
                // do nothing, it's already a multiple of 5
            }
        }

        ctx.musicEnabled = true;

        setMusicVolume(cast(f32) musicVol / 100);
        setFlashTextFormat("Music volume set to %", musicVol);
    }
}

applySoundVolCheat :: (arguments: string) {
    ctx := cast(*GameContext) context.gameContext;
    assert(ctx != null);

    if (!ctx.cheatsEnabled) {
        return;
    }

    sfxVol, success := parseInt(arguments);
    if (success) {
        sfxVol = clamp(sfxVol, 0, 100);

        // round the argument to a value multiple of 5
        if sfxVol % 5 == {
            case 1; { sfxVol -= 1; }
            case 2; { sfxVol -= 2; }
            case 3; { sfxVol += 2; }
            case 4; { sfxVol += 1; }
            case; {
                // do nothing, it's already a multiple of 5
            }
        }

        ctx.soundEnabled = true;

        setSoundVolume(cast(f32) sfxVol / 100);
        setFlashTextFormat("Sounds volume set to %", sfxVol);
    }
}

applyGlobalScaleCheat :: (arguments: string) {
    ctx := cast(*GameContext) context.gameContext;
    assert(ctx != null);

    if (!ctx.cheatsEnabled) {
        return;
    }

    scale, success := parseInt(arguments);
    if (success) {
        scale = clamp(scale, 1, 5);
        setGlobalScale(cast(f32) scale);
        setFlashTextFormat("Global scale set to %", scale);
    }
}

applyGlobalSpeedCheat :: (arguments: string) {
    ctx := cast(*GameContext) context.gameContext;
    assert(ctx != null);

    if (!ctx.cheatsEnabled) {
        return;
    }

    speed, success := parseInt(arguments);
    if (success) {
        speed = clamp(speed, 1, 5);
        setGlobalSpeed(cast(f32) speed);
        setFlashTextFormat("Global speed set to %", speed);
    }
}
