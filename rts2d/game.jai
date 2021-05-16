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
