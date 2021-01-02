#import "glfw";
#import "GL";
#import "nanovg";

#import "collections";
#import "utils";

#load "demo.jai";

EXIT_SUCCESS :: 0;
EXIT_FAILURE :: -1;

blowup := false;
screenshot: s32 = 0;
premult := false;

errorCallback :: (error: s32, description: *u8) #c_call {
    newContext: Context;
    push_context newContext {
        print("Error: %\n", toString(description));
    }
}

keyCallback :: (window: *GLFWwindow, key: s32, scancode: s32, action: s32, mods: s32) #c_call {
	if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS) {
		glfwSetWindowShouldClose(window, 1);
    }
	if (key == GLFW_KEY_SPACE && action == GLFW_PRESS) {
		blowup = !blowup;
    }
	if (key == GLFW_KEY_S && action == GLFW_PRESS) {
		screenshot = 1;
    }
	if (key == GLFW_KEY_P && action == GLFW_PRESS) {
		premult = !premult;
    }
}

main :: () {
    randomSeed(time(null));

    glfwSetErrorCallback(errorCallback);

    if (!glfwInit()) {
        exit(EXIT_FAILURE);
    }

    // fps: PerfGraph;
    // initGraph(*fps, GRAPH_RENDER_FPS, "Frame Time");

    // glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
	// glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GLFW_TRUE);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1);
    glfwWindowHint(GLFW_OPENGL_DEBUG_CONTEXT, GLFW_TRUE);

    window := glfwCreateWindow(1000, 600, "NanoVG", null, null);
	if (!window) {
		glfwTerminate();
		exit(EXIT_FAILURE);
	}

    glfwMakeContextCurrent(window);

    glLoad(glfwGetProcAddress);

    glCheckOpenGLVersion();

	glfwSetKeyCallback(window, keyCallback);

    //vg := nvgCreateGLES2(NVGcreateFlags.NVG_ANTIALIAS | .NVG_STENCIL_STROKES | .NVG_DEBUG);
    vg := nvgCreateGL3(NVGcreateFlags.NVG_ANTIALIAS | .NVG_STENCIL_STROKES | NVGcreateFlags.NVG_DEBUG);
	if (vg == null) {
		print("Could not init nanovg.\n");
		exit(EXIT_FAILURE);
	}

    data: DemoData;
    if (loadDemoData(vg, *data) == -1) {
		exit(EXIT_FAILURE);
    }

    glfwSwapInterval(0);

    glfwSetTime(0);
	prevt := glfwGetTime();

    while (!glfwWindowShouldClose(window)) {
        t := glfwGetTime();
        dt := t - prevt;
		prevt = t;
		// updateGraph(*fps, dt);

        mx, my: f64;
        glfwGetCursorPos(window, *mx, *my);

        winWidth, winHeight: s32;
		glfwGetWindowSize(window, *winWidth, *winHeight);

        fbWidth, fbHeight: s32;
		glfwGetFramebufferSize(window, *fbWidth, *fbHeight);

		pxRatio := cast(f32)fbWidth / cast(f32)winWidth;

        glViewport(0, 0, cast(u32)fbWidth, cast(u32)fbHeight);

        if (premult) {
			glClearColor(0,0,0,0);
        } else {
			glClearColor(0.3, 0.3, 0.32, 1.0);
        }

		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);

        glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glEnable(GL_CULL_FACE);
		glDisable(GL_DEPTH_TEST);

		nvgBeginFrame(vg, cast(f32)winWidth, cast(f32)winHeight, pxRatio);

        renderDemo(vg, cast(f32)mx, cast(f32)my, cast(f32)winWidth, cast(f32)winHeight, cast(f32)t, blowup, *data);
		// renderGraph(vg, 5,5, &fps);

        //drawSpinner(vg, 200, 200, 100, 0);

		nvgEndFrame(vg);

        glEnable(GL_DEPTH_TEST);

		glfwSwapBuffers(window);
		glfwPollEvents();
    }

	freeDemoData(vg, *data);
	nvgDeleteGL3(vg);
    glfwDestroyWindow(window);
    glfwTerminate();

    exit(EXIT_SUCCESS);
}

#scope_file
