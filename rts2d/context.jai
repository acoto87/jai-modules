GameContext :: struct {
    time: f32;
    deltaTime: f32;
    fps: u32;

    paused: bool;

    globalScale: f32;
    globalSpeed: f32;

    originalWindowSize: Vec2i;
    windowSize: Vec2i;
    framebufferSize: Vec2i;
    devicePixelRatio: f32;
    windowTitle: string;
    window: *GLFWwindow;

    fonts: [MAX_FONT_COUNT] FontData;

    gfx: *NVGcontext;

    // ma_device sfx;
    // tsf* soundFont;

    cheatsEnabled: bool;

    // // this is a mutex used to make the deletion of the entities thread-safe
    // // since the audio thread will delete audio entities, that could lead
    // // to inconsistent states in the internal lists when the game try to also
    // // delete other entities.
    // pthread_mutex_t __mutex;

    input: Input;

    transitionDelay: f32;
    scene: *Scene;
    nextScene: *Scene;

    userState: *void;
}

initGame :: (windowTitle: string, originalWindowSize: Vec2i, globalScale: f32, globalSpeed: f32) -> bool {
    ctx := context.gameContext;
    assert(ctx != null);

    assert(!isEmpty(windowTitle));
    assert(originalWindowSize.x > 0 && originalWindowSize.y > 0);

    if (globalScale <= 0) {
        globalScale = 1;
    }

    if (globalSpeed <= 0) {
        globalSpeed = 1;
    }

    glfwSetErrorCallback(glfwErrorCallback);

    if (!glfwInit()) {
        logError("Error initializing GLFW!\n");
        return false;
    }

    glfwWindowHint(GLFW_RESIZABLE, 0);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 2);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0);
    // glfwWindowHint(GLFW_CLIENT_API, GLFW_OPENGL_ES_API);

    ctx.globalScale = globalScale;
    ctx.globalSpeed = globalSpeed;
    ctx.originalWindowSize = originalWindowSize;
    ctx.windowSize = ctx.originalWindowSize * ctx.globalScale;
    ctx.windowTitle = windowTitle;
    ctx.window = glfwCreateWindow(ctx.windowSize.x, ctx.windowSize.y, toCString(ctx.windowTitle, tempAllocator), null, null);
    ctx.transitionDelay = 0;
    ctx.cheatsEnabled = false;

    // pthread_mutex_init(&ctx.__mutex, NULL);

    if (!ctx.window) {
        logError("GLFW window could not be created!\n");
        glfwTerminate();
        return false;
    }

    glfwGetWindowSize(ctx.window, *ctx.windowSize.x, *ctx.windowSize.y);
    glfwGetFramebufferSize(ctx.window, *ctx.framebufferSize.x, *ctx.framebufferSize.y);
    ctx.devicePixelRatio = cast(f32) ctx.framebufferSize.x / cast(f32) ctx.windowSize.x;

    glfwMakeContextCurrent(ctx.window);

    glfwSetInputMode(ctx.window, GLFW_CURSOR, GLFW_CURSOR_HIDDEN);

    glLoad(glfwGetProcAddress);

    glCheckOpenGLVersion();

    // init graphics
    ctx.gfx = nvgCreateGL2(NVGcreateFlags.NVG_STENCIL_STROKES | .NVG_DEBUG);
    if (ctx.gfx == null) {
        logError("Could not init nanovg.\n");
        glfwDestroyWindow(ctx.window);
        glfwTerminate();
        return false;
    }

    // init audio
    // if (!initAudio(context))
    // {
    //     logError("Could not initialize audio.\n");
    //     return false;
    // }

    glViewport(0, 0, cast(u32) ctx.framebufferSize.x, cast(u32) ctx.framebufferSize.y);
    glClearColor(0, 0, 0, 1.0);

    ctx.time = cast(f32) glfwGetTime();
    return true;
}

uninitGame :: () {
    ctx := context.gameContext;
    assert(ctx != null);

    nvgDeleteGL2(ctx.gfx);
    glfwDestroyWindow(ctx.window);
    glfwTerminate();
}

setWindowSize :: (size: Vec2i) {
    ctx := context.gameContext;
    assert(ctx != null);

    ctx.windowSize = size;
    glfwSetWindowSize(ctx.window, ctx.windowSize.x, ctx.windowSize.y);
    glfwGetFramebufferSize(ctx.window, *ctx.framebufferSize.x, *ctx.framebufferSize.y);
    ctx.devicePixelRatio = cast(f32) ctx.framebufferSize.x / cast(f32) ctx.windowSize.x;
}

setGlobalScale :: (scale: f32) {
    ctx := context.gameContext;
    assert(ctx != null);

    ctx.globalScale = max(scale, 1.0);
    logDebug("set global scale to: %\n", ctx.globalScale);

    newSize := ctx.originalWindowSize * ctx.globalScale;
    setWindowSize(newSize);
}

changeGlobalScale :: (deltaScale: f32) {
    ctx := context.gameContext;
    assert(ctx != null);

    setGlobalScale(ctx.globalScale + deltaScale);
}

setGlobalSpeed :: (speed: f32) {
    ctx := context.gameContext;
    assert(ctx != null);

    ctx.globalSpeed = max(speed, 1.0);
    logDebug("set global speed to: %\n", ctx.globalSpeed);
}

changeGlobalSpeed :: (deltaSpeed: f32) {
    ctx := context.gameContext;
    assert(ctx != null);

    setGlobalSpeed(ctx.globalSpeed + deltaSpeed);
}

getDirFromArrowKeys :: () -> Vec2 {
    dir := VEC2_ZERO;

    if (isKeyPressed(Keys.Left)) {
        dir.x = -1;
    } else if (isKeyPressed(Keys.Right)) {
        dir.x = 1;
    }

    if (isKeyPressed(Keys.Down)) {
        dir.y = 1;
    } else if (isKeyPressed(Keys.Up)) {
        dir.y = -1;
    }

    dir = normalize(dir);
    return dir;
}

getDirFromMousePos :: () -> Vec2 {
    ctx := context.gameContext;
    assert(ctx != null);

    input := *ctx.input;

    dir := VEC2_ZERO;

    if (input.pos.x < MAP_EDGE_SCROLL_GAP) {
        dir.x = -1;
    } else if (input.pos.x > ctx.originalWindowSize.x - MAP_EDGE_SCROLL_GAP) {
        dir.x = 1;
    }

    if (input.pos.y < MAP_EDGE_SCROLL_GAP) {
        dir.y = -1;
    } else if (input.pos.y > ctx.originalWindowSize.y - MAP_EDGE_SCROLL_GAP) {
        dir.y = 1;
    }

    dir = normalize(dir);
    return dir;
}

getScaledSpeed :: (t: f32) -> f32 {
    ctx := context.gameContext;

    assert(ctx != null);
    assert(ctx.scene != null);

    t *= ctx.globalSpeed;

    // if (ctx.scene.type == WarSceneType.Map) {
    //     map := cast(*WarMap) ctx.scene;

    //     if (map.settings.gameSpeed < WarMapSpeed.Normal) {
    //         t *= 1.0 - cast(s32) (WarMapSpeed.Normal - map.settings.gameSpeed) * 0.25;
    //     } else if (map.settings.gameSpeed > WarMapSpeed.Normal) {
    //         t *= 1.0 + cast(s32) (map.settings.gameSpeed - WarMapSpeed.Normal) * 0.5;
    //     }
    // }

    return t;
}

getScaledTime :: inline (t: f32) -> f32 {
    ctx := context.gameContext;

    assert(ctx != null);
    assert(ctx.scene != null);

    t /= ctx.globalSpeed;

    // if (ctx.scene.type == WarSceneType.Map) {
    //     map := cast(*WarMap) ctx.scene;

    //     if (map.settings.gameSpeed < WarMapSpeed.Normal) {
    //         t /= 1.0 - cast(s32) (WarMapSpeed.Normal - map.settings.gameSpeed) * 0.25;
    //     } else if (map.settings.gameSpeed > WarMapSpeed.Normal) {
    //         t /= 1.0 + cast(s32) (map.settings.gameSpeed - WarMapSpeed.Normal) * 0.5;
    //     }
    // }

    return t;
}

// setMusicVolume :: (ctx: *WarContext, volume: f32) {
//     ctx.musicVolume = clamp(volume, 0.0, 1.0);
//     logDebug("set music volume to: %\n", ctx.musicVolume);
// }

// changeMusicVolume :: (ctx: *WarContext, deltaVolume: f32) {
//     setMusicVolume(ctx.musicVolume + deltaVolume);
// }

// setSoundVolume :: (ctx: *WarContext, volume: f32) {
//     ctx.soundVolume = clamp(volume, 0.0, 1.0);
//     logDebug("set sound volume to: %\n", ctx.soundVolume);
// }

// changeSoundVolume :: (ctx: *WarContext, deltaVolume: f32) {
//     setSoundVolume(ctx.soundVolume + deltaVolume);
// }

#scope_file

glfwErrorCallback :: (error: s32, description: *u8) #c_call {
    newContext: Context;
    push_context newContext {
        loggerData := LoggerData.{};
        initLogger(*loggerData);

        logError("Error: %\n", toString(description));
    }
}