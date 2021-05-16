MouseButtons :: enum u8 {
    None;
    Left;
    Right;
}

Keys :: enum u8 {
    None;

    Space;
    Apostrophe;
    Asterisk;
    Plus;
    Comma;
    Minus;
    Period;
    Slash;

    D0;
    D1;
    D2;
    D3;
    D4;
    D5;
    D6;
    D7;
    D8;
    D9;

    Semicolon;
    Equal;

    A;
    B;
    C;
    D;
    E;
    F;
    G;
    H;
    I;
    J;
    K;
    L;
    M;
    N;
    O;
    P;
    Q;
    R;
    S;
    T;
    U;
    V;
    W;
    X;
    Y;
    Z;

    LeftBracket;
    Backslash;
    RightBracket;
    GraveAccent;

    Esc;
    Enter;
    Tab;
    Backspace;
    Insert;
    Delete;

    Right;
    Left;
    Down;
    Up;

    PageUp;
    PageDown;
    Home;
    End;

    F1;
    F2;
    F3;
    F4;
    F5;
    F6;
    F7;
    F8;
    F9;
    F10;
    F11;
    F12;

    Shift;
    Ctrl;
    Alt;
}

KeyButtonState :: struct {
    // indicates if the key is pressed in the current frame
    pressed: bool;

    // indicate if the key was pressed in the previous frame
    wasPressed: bool;
}

Input :: struct {
    // current mouse position
    pos: Vec2;

    // state of the mouse buttons
    buttons: [#run getCount(MouseButtons)] KeyButtonState;

    // state of the keys
    keys: [#run getCount(Keys)] KeyButtonState;

    // drag
    isDragging: bool;
    wasDragging: bool;
    dragPos: Vec2;
    dragRect: Rect;
}

inputGame :: () {
    ctx := context.gameContext;
    assert(ctx != null);

    // mouse position
    xpos, ypos: f64;
    glfwGetCursorPos(ctx.window, *xpos, *ypos);

    ctx.input.pos = vec2(cast(f32) floor(xpos), cast(f32) floor(ypos)) / ctx.globalScale;

    // mouse buttons
    setInputButton(MouseButtons.Left, glfwIsAnyButtonPressed(GLFW_MOUSE_BUTTON_LEFT));
    setInputButton(MouseButtons.Right, glfwIsAnyButtonPressed(GLFW_MOUSE_BUTTON_RIGHT));

    // keyboard keys
    setInputKey(Keys.Space, glfwIsAnyKeyPressed(GLFW_KEY_SPACE));
    setInputKey(Keys.Apostrophe, glfwIsAnyKeyPressed(GLFW_KEY_APOSTROPHE));
    setInputKey(Keys.Comma, glfwIsAnyKeyPressed(GLFW_KEY_COMMA));
    setInputKey(Keys.Minus, glfwIsAnyKeyPressed(GLFW_KEY_MINUS, GLFW_KEY_KP_SUBTRACT));
    setInputKey(Keys.Period, glfwIsAnyKeyPressed(GLFW_KEY_PERIOD, GLFW_KEY_KP_DECIMAL));
    setInputKey(Keys.Slash, glfwIsAnyKeyPressed(GLFW_KEY_SLASH, GLFW_KEY_KP_DIVIDE));

    setInputKey(Keys.D0, glfwIsAnyKeyPressed(GLFW_KEY_0, GLFW_KEY_KP_0));
    setInputKey(Keys.D1, glfwIsAnyKeyPressed(GLFW_KEY_1, GLFW_KEY_KP_1));
    setInputKey(Keys.D2, glfwIsAnyKeyPressed(GLFW_KEY_2, GLFW_KEY_KP_2));
    setInputKey(Keys.D3, glfwIsAnyKeyPressed(GLFW_KEY_3, GLFW_KEY_KP_3));
    setInputKey(Keys.D4, glfwIsAnyKeyPressed(GLFW_KEY_4, GLFW_KEY_KP_4));
    setInputKey(Keys.D5, glfwIsAnyKeyPressed(GLFW_KEY_5, GLFW_KEY_KP_5));
    setInputKey(Keys.D6, glfwIsAnyKeyPressed(GLFW_KEY_6, GLFW_KEY_KP_6));
    setInputKey(Keys.D7, glfwIsAnyKeyPressed(GLFW_KEY_7, GLFW_KEY_KP_7));
    setInputKey(Keys.D8, glfwIsAnyKeyPressed(GLFW_KEY_8, GLFW_KEY_KP_8));
    setInputKey(Keys.D9, glfwIsAnyKeyPressed(GLFW_KEY_9, GLFW_KEY_KP_9));

    setInputKey(Keys.Semicolon, glfwIsAnyKeyPressed(GLFW_KEY_SEMICOLON));
    setInputKey(Keys.Equal, glfwIsAnyKeyPressed(GLFW_KEY_EQUAL, GLFW_KEY_KP_EQUAL));

    setInputKey(Keys.A, glfwIsAnyKeyPressed(GLFW_KEY_A));
    setInputKey(Keys.B, glfwIsAnyKeyPressed(GLFW_KEY_B));
    setInputKey(Keys.C, glfwIsAnyKeyPressed(GLFW_KEY_C));
    setInputKey(Keys.D, glfwIsAnyKeyPressed(GLFW_KEY_D));
    setInputKey(Keys.E, glfwIsAnyKeyPressed(GLFW_KEY_E));
    setInputKey(Keys.F, glfwIsAnyKeyPressed(GLFW_KEY_F));
    setInputKey(Keys.G, glfwIsAnyKeyPressed(GLFW_KEY_G));
    setInputKey(Keys.H, glfwIsAnyKeyPressed(GLFW_KEY_H));
    setInputKey(Keys.I, glfwIsAnyKeyPressed(GLFW_KEY_I));
    setInputKey(Keys.J, glfwIsAnyKeyPressed(GLFW_KEY_J));
    setInputKey(Keys.K, glfwIsAnyKeyPressed(GLFW_KEY_K));
    setInputKey(Keys.L, glfwIsAnyKeyPressed(GLFW_KEY_L));
    setInputKey(Keys.M, glfwIsAnyKeyPressed(GLFW_KEY_M));
    setInputKey(Keys.N, glfwIsAnyKeyPressed(GLFW_KEY_N));
    setInputKey(Keys.O, glfwIsAnyKeyPressed(GLFW_KEY_O));
    setInputKey(Keys.P, glfwIsAnyKeyPressed(GLFW_KEY_P));
    setInputKey(Keys.Q, glfwIsAnyKeyPressed(GLFW_KEY_Q));
    setInputKey(Keys.R, glfwIsAnyKeyPressed(GLFW_KEY_R));
    setInputKey(Keys.S, glfwIsAnyKeyPressed(GLFW_KEY_S));
    setInputKey(Keys.T, glfwIsAnyKeyPressed(GLFW_KEY_T));
    setInputKey(Keys.U, glfwIsAnyKeyPressed(GLFW_KEY_U));
    setInputKey(Keys.V, glfwIsAnyKeyPressed(GLFW_KEY_V));
    setInputKey(Keys.W, glfwIsAnyKeyPressed(GLFW_KEY_W));
    setInputKey(Keys.X, glfwIsAnyKeyPressed(GLFW_KEY_X));
    setInputKey(Keys.Y, glfwIsAnyKeyPressed(GLFW_KEY_Y));
    setInputKey(Keys.Z, glfwIsAnyKeyPressed(GLFW_KEY_Z));

    setInputKey(Keys.LeftBracket, glfwIsAnyKeyPressed(GLFW_KEY_LEFT_BRACKET));
    setInputKey(Keys.Backslash, glfwIsAnyKeyPressed(GLFW_KEY_BACKSLASH));
    setInputKey(Keys.RightBracket, glfwIsAnyKeyPressed(GLFW_KEY_RIGHT_BRACKET));
    setInputKey(Keys.GraveAccent, glfwIsAnyKeyPressed(GLFW_KEY_GRAVE_ACCENT));

    setInputKey(Keys.Esc, glfwIsAnyKeyPressed(GLFW_KEY_ESCAPE));
    setInputKey(Keys.Enter, glfwIsAnyKeyPressed(GLFW_KEY_ENTER, GLFW_KEY_KP_ENTER));
    setInputKey(Keys.Tab, glfwIsAnyKeyPressed(GLFW_KEY_TAB));
    setInputKey(Keys.Backspace, glfwIsAnyKeyPressed(GLFW_KEY_BACKSPACE));
    setInputKey(Keys.Insert, glfwIsAnyKeyPressed(GLFW_KEY_INSERT));
    setInputKey(Keys.Delete, glfwIsAnyKeyPressed(GLFW_KEY_DELETE));

    setInputKey(Keys.Right, glfwIsAnyKeyPressed(GLFW_KEY_RIGHT));
    setInputKey(Keys.Left, glfwIsAnyKeyPressed(GLFW_KEY_LEFT));
    setInputKey(Keys.Down, glfwIsAnyKeyPressed(GLFW_KEY_DOWN));
    setInputKey(Keys.Up, glfwIsAnyKeyPressed(GLFW_KEY_UP));

    setInputKey(Keys.PageUp, glfwIsAnyKeyPressed(GLFW_KEY_PAGE_UP));
    setInputKey(Keys.PageDown, glfwIsAnyKeyPressed(GLFW_KEY_PAGE_DOWN));
    setInputKey(Keys.Home, glfwIsAnyKeyPressed(GLFW_KEY_HOME));
    setInputKey(Keys.End, glfwIsAnyKeyPressed(GLFW_KEY_END));

    setInputKey(Keys.F1, glfwIsAnyKeyPressed(GLFW_KEY_F1));
    setInputKey(Keys.F2, glfwIsAnyKeyPressed(GLFW_KEY_F2));
    setInputKey(Keys.F3, glfwIsAnyKeyPressed(GLFW_KEY_F3));
    setInputKey(Keys.F4, glfwIsAnyKeyPressed(GLFW_KEY_F4));
    setInputKey(Keys.F5, glfwIsAnyKeyPressed(GLFW_KEY_F5));
    setInputKey(Keys.F6, glfwIsAnyKeyPressed(GLFW_KEY_F6));
    setInputKey(Keys.F7, glfwIsAnyKeyPressed(GLFW_KEY_F7));
    setInputKey(Keys.F8, glfwIsAnyKeyPressed(GLFW_KEY_F8));
    setInputKey(Keys.F9, glfwIsAnyKeyPressed(GLFW_KEY_F9));
    setInputKey(Keys.F10, glfwIsAnyKeyPressed(GLFW_KEY_F10));
    setInputKey(Keys.F11, glfwIsAnyKeyPressed(GLFW_KEY_F11));
    setInputKey(Keys.F12, glfwIsAnyKeyPressed(GLFW_KEY_F12));

    setInputKey(Keys.Asterisk, glfwIsAnyKeyPressed(GLFW_KEY_KP_MULTIPLY));
    setInputKey(Keys.Plus, glfwIsAnyKeyPressed(GLFW_KEY_KP_ADD));

    setInputKey(Keys.Shift, glfwIsAnyKeyPressed(GLFW_KEY_LEFT_SHIFT, GLFW_KEY_RIGHT_SHIFT));
    setInputKey(Keys.Ctrl, glfwIsAnyKeyPressed(GLFW_KEY_LEFT_CONTROL, GLFW_KEY_RIGHT_CONTROL));
    setInputKey(Keys.Alt, glfwIsAnyKeyPressed(GLFW_KEY_LEFT_ALT, GLFW_KEY_RIGHT_ALT));
}

isButtonPressed :: inline (btn: MouseButtons) -> bool {
    ctx := context.gameContext;
    assert(ctx != null);

    return ctx.input.buttons[cast(s32) btn].pressed;
}

wasButtonPressed :: inline (btn: MouseButtons) -> bool {
    ctx := context.gameContext;
    assert(ctx != null);

    return ctx.input.buttons[cast(s32) btn].wasPressed;
}

isKeyPressed :: inline (key: Keys) -> bool {
    ctx := context.gameContext;
    assert(ctx != null);

    return ctx.input.keys[cast(s32) key].pressed;
}

wasKeyPressed :: inline (key: Keys) -> bool {
    ctx := context.gameContext;
    assert(ctx != null);

    return ctx.input.keys[cast(s32) key].wasPressed;
}

#scope_file

setInputButton :: (button: MouseButtons, pressed: bool) {
    ctx := context.gameContext;
    assert(ctx != null);

    input := *ctx.input;

    input.buttons[button].wasPressed = input.buttons[button].pressed && !pressed;
    input.buttons[button].pressed = pressed;
}

setInputKey :: (key: Keys, pressed: bool) {
    ctx := context.gameContext;
    assert(ctx != null);

    input := *ctx.input;

    input.keys[key].wasPressed = input.keys[key].pressed && !pressed;
    input.keys[key].pressed = pressed;
}

glfwIsAnyKeyPressed :: (keys: ..s32) -> bool {
    ctx := context.gameContext;
    assert(ctx != null);

    for key : keys {
        if (glfwGetKey(ctx.window, key) == GLFW_PRESS) {
            return true;
        }
    }
    return false;
}

glfwIsAnyButtonPressed :: (buttons: ..s32) -> bool {
    ctx := context.gameContext;
    assert(ctx != null);

    for button : buttons {
        if (glfwGetMouseButton(ctx.window, button) == GLFW_PRESS) {
            return true;
        }
    }
    return false;
}
