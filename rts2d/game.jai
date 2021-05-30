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
    ctx.musicEnabled = true;
    ctx.soundEnabled = true;
    ctx.musicVolume = 1;
    ctx.soundVolume = 1;
    ctx.cheatsEnabled = false;
    ctx.originalWindowSize = originalWindowSize;
    ctx.windowSize = ctx.originalWindowSize * ctx.globalScale;
    ctx.windowTitle = windowTitle;
    ctx.window = glfwCreateWindow(ctx.windowSize.x, ctx.windowSize.y, toCString(ctx.windowTitle, tempAllocator), null, null);
    ctx.transitionDelay = 0;

    // pthread_mutex_init(&ctx.__mutex, NULL);

    if (!ctx.window) {
        logError("GLFW window could not be created!\n");
        glfwTerminate();
        return false;
    }

    glfwSetWindowUserPointer(ctx.window, ctx);
    glfwSetCharCallback(ctx.window, inputCharCallback);

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

updateGame :: () {
    ctx := context.gameContext;
    assert(ctx != null);

    if (isKeyPressed(Keys.Ctrl) && wasKeyPressed(Keys.P)) {
        ctx.paused = !ctx.paused;
    }

    if (ctx.paused) {
        return;
    }

    if (ctx.nextScene != null) {
        // ctx.audioEnabled = false;

        leaveScene();

        ctx.scene = ctx.nextScene;
        ctx.nextScene = null;

        enterScene();

        // ctx.audioEnabled = true;
    }

    if (ctx.transitionDelay > 0) {
        ctx.transitionDelay = max(ctx.transitionDelay - ctx.deltaTime, 0.0);
        return;
    }

    updateScene();
}

renderGame :: () {
    ctx := context.gameContext;
    assert(ctx != null);

    glViewport(0, 0, cast(u32) ctx.framebufferSize.x, cast(u32) ctx.framebufferSize.y);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);

    // don't render anything if it's transitioning
    if (ctx.transitionDelay > 0) {
        return;
    }

    nvgBeginFrame(ctx.gfx, cast(f32) ctx.windowSize.x, cast(f32) ctx.windowSize.y, ctx.devicePixelRatio);
    renderScene();
    nvgEndFrame(ctx.gfx);
}

presentGame :: () {
    ctx := context.gameContext;
    assert(ctx != null);

    glfwSwapBuffers(ctx.window);
    glfwPollEvents();

    currentTime := cast(f32) glfwGetTime();
    ctx.deltaTime = (currentTime - ctx.time);

    // This code is good in theory, but the sleep resolution on different OSes
    // varies, so Sleep in Windows may take a longer time than specified.
    //
    // On Linux I should do a do {..} while (); using the nanosleep function
    // and check for interrutions that wake up the thread before.
    //
    // msleep((s32)((SECONDS_PER_FRAME - context.deltaTime) * 1000));
    // currentTime = (f32)glfwGetTime();
    // context.deltaTime = (currentTime - context.time);

    // This was the previous code that wait until the end of the frame
    // but this burn too much CPU, so it's better the alternative of
    // sleep the process and save CPU usage and battery.
    //
    // Going back to this code for now, until we get a consistent game loop with sleep.
    while (ctx.deltaTime <= SECONDS_PER_FRAME) {
        currentTime = cast(f32) glfwGetTime();
        ctx.deltaTime = (currentTime - ctx.time);
    }

    ctx.time = currentTime;
    ctx.fps = cast(u32) (1.0 / ctx.deltaTime);
}

#scope_file

glfwErrorCallback :: (error: s32, description: *u8) #c_call {
    newContext: Context;
    push_context newContext {
        loggerData := LoggerData.{};
        initLogger(*loggerData);

        logError("Error: %\n", toString(description));
    }
}

inputCharCallback :: (window: *GLFWwindow, codepoint: u32) #c_call {
    ctx := cast(*GameContext) glfwGetWindowUserPointer(window);

    newContext: Context;
    newContext.gameContext = ctx;
    push_context newContext {
        keyPressCheatsPanel(codepoint);
    }
}
