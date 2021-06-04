FlashText :: struct {
    enabled: bool;
    visible: bool;
    duration: f32;
    text: string;
    textUIName: string;
}

FlashTextOptions :: struct {
    textUIName: string = "txtFlash";
    textUIPosition: Vec2;
    textUIColor: Color = COLOR_YELLOW;
    textUIFontIndex: s32 = 0;
    textUIFontSize: f32 = 6;
}

initFlashText :: (options: FlashTextOptions) {
    ctx := context.gameContext;
    assert(ctx != null);

    scene := ctx.scene;
    assert(scene != null);

    flashText := *scene.flashText;
    flashText.enabled = true;
    flashText.visible = false;
    flashText.text = "";
    flashText.textUIName = options.textUIName;

    uiEntity := createUIText(options.textUIName, options.textUIFontIndex, options.textUIFontSize, "", options.textUIPosition);
    setUITextColor(uiEntity, options.textUIColor);
    setUIEntityStatus(uiEntity, false);
}

updateFlashText :: (stop: bool = false) {
    ctx := context.gameContext;
    assert(ctx != null);

    scene := ctx.scene;
    assert(scene != null);

    flashText := *scene.flashText;
    if (!flashText.enabled) {
        return;
    }

    textEntity := findUIEntity(flashText.textUIName);
    assert(textEntity != null);

    if (flashText.visible && !stop) {
        setUIEntityStatus(textEntity, true);
        setUIText(textEntity, flashText.text);

        flashText.duration -= ctx.deltaTime;
        if (flashText.duration <= 0) {
            flashText.visible = false;
            flashText.duration = 0;
        }
    } else {
        setUIEntityStatus(textEntity, false);
        setUIText(textEntity, "");
        flashText.visible = false;
        flashText.duration = 0;
    }
}

isFlashTextVisible :: inline () -> bool {
    ctx := context.gameContext;
    assert(ctx != null);

    scene := ctx.scene;
    assert(scene != null);

    return scene.flashText.enabled && scene.flashText.visible;
}

setFlashText :: inline (text: string, duration: f32 = 2.0) {
    textInternal := allocString(text);
    setFlashTextInternal(textInternal, duration);
}

setFlashTextFormat :: inline (textFormat: string, args: ..Any, duration: f32 = 2.0) {
    textInternal := sprint(textFormat, ..args);
    setFlashTextInternal(textInternal, duration);
}

#scope_file

setFlashTextInternal :: (text: string, duration: f32) {
    ctx := context.gameContext;
    assert(ctx != null);

    scene := ctx.scene;
    assert(scene != null);

    flashText := *scene.flashText;

    if (!isEmpty(flashText.text)) {
        free(flashText.text);
    }

    if (!isEmpty(text)) {
        flashText.visible = true;
        flashText.duration = duration;
        flashText.text = text;
    } else {
        flashText.visible = false;
        flashText.duration = 0;
        flashText.text = "";
    }
}