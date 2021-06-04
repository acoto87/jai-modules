CheatsPanel :: struct {
    enabled: bool;
    visible: bool;
    position: s32;
    prefix: string;
    text: FixedString;
    panelUIName: string;
    textUIName: string;
    cursorUIName: string;
}

CheatPanelOptions :: struct {
    panelUIName: string = "panelCheat";
    panelBackgroundColor: Color = COLOR_TRANSPARENT;
    panelRect: Rect;
    textUIName: string = "txtCheat";
    textUIOffset: Vec2;
    textUIColor: Color = COLOR_WHITE;
    textUIFontIndex: s32 = 0;
    textUIFontSize: f32 = 6;
    textUIMaxLength: s32 = CHEAT_TEXT_MAX_LENGTH;
    cursorUIName: string = "cursorCheat";
    cursorUIOffset: Vec2;
    prefix: string = "";
}

initCheatsPanel :: (options: CheatPanelOptions) {
    ctx := context.gameContext;
    assert(ctx != null);

    scene := ctx.scene;
    assert(scene != null);

    cheatsPanel := *scene.cheatsPanel;
    cheatsPanel.enabled = true;
    cheatsPanel.visible = false;
    cheatsPanel.position = 0;
    cheatsPanel.prefix = options.prefix;
    cheatsPanel.text = createFixedString(options.textUIMaxLength);
    cheatsPanel.panelUIName = options.panelUIName;
    cheatsPanel.textUIName = options.textUIName;
    cheatsPanel.cursorUIName = options.cursorUIName;

    uiEntity: *Entity;

    panelPosition := getTopLeft(options.panelRect);
    panelSize := getSize(options.panelRect);
    uiEntity = createUIRect(options.panelUIName, panelPosition, panelSize, options.panelBackgroundColor);
    setUIEntityStatus(uiEntity, false);

    textUIPosition := panelPosition + options.textUIOffset;
    uiEntity = createUIText(options.textUIName, options.textUIFontIndex, options.textUIFontSize, "", textUIPosition);
    setUITextColor(uiEntity, options.textUIColor);
    setUIEntityStatus(uiEntity, false);

    cursorUIPosition := panelPosition + options.cursorUIOffset;
    uiEntity = createUIRect(options.cursorUIName, cursorUIPosition, vec2(1, 7), COLOR_WHITE);
    setUIEntityStatus(uiEntity, false);
}

updateCheatsPanel :: () {
    ctx := context.gameContext;
    assert(ctx != null);

    scene := ctx.scene;
    assert(scene != null);

    cheatsPanel := *scene.cheatsPanel;
    if (!cheatsPanel.enabled) {
        return;
    }

    panelEntity := findUIEntity(cheatsPanel.panelUIName);
    assert(panelEntity != null);

    textEntity := findUIEntity(cheatsPanel.textUIName);
    assert(textEntity != null);

    cursorEntity := findUIEntity(cheatsPanel.cursorUIName);
    assert(cursorEntity != null);

    if (cheatsPanel.visible) {
        if (wasKeyPressed(Keys.Esc)) {
            setCheatsPanelVisible(false);
            return;
        }

        if (wasKeyPressed(Keys.Enter)) {
            applyCheat(toString(*cheatsPanel.text));
            setCheatsPanelVisible(false);
            return;
        }

        if (wasKeyPressed(Keys.Tab)) {
            if (hasEnoughFor(*cheatsPanel.text, TAB_WIDTH)) {
                insertAt(*cheatsPanel.text, cheatsPanel.position, #char "\t");
                cheatsPanel.position += 1;
            }
        } else if (wasKeyPressed(Keys.Backspace)) {
            if (cheatsPanel.position > 0) {
                removeAt(*cheatsPanel.text, cheatsPanel.position - 1);
                cheatsPanel.position -= 1;
            }
        } else if (wasKeyPressed(Keys.Delete)) {
            if (cheatsPanel.position < cheatsPanel.text.count) {
                removeAt(*cheatsPanel.text, cheatsPanel.position);
            }
        } else if (wasKeyPressed(Keys.Right)) {
            if (cheatsPanel.position < cheatsPanel.text.count) {
                cheatsPanel.position += 1;
            }
        } else if (wasKeyPressed(Keys.Left)) {
            if (cheatsPanel.position > 0) {
                cheatsPanel.position -= 1;
            }
        } else if (wasKeyPressed(Keys.Home)) {
            cheatsPanel.position = 0;
        } else if (wasKeyPressed(Keys.End)) {
            cheatsPanel.position = cast(s32) cheatsPanel.text.count;
        }

        statusText := getCheatsText(cheatsPanel);
        defer free(statusText);

        setUITextFormat(textEntity, statusText);
        setCheatCursorPosition(cheatsPanel, panelEntity, cursorEntity, textEntity, statusText);

        setUIEntityStatus(panelEntity, true);
        setUIEntityStatus(cursorEntity, true);
        setUIEntityStatus(textEntity, true);
    } else {
        setUIEntityStatus(panelEntity, false);
        setUIEntityStatus(cursorEntity, false);
        setUIEntityStatus(textEntity, false);

        if (wasKeyPressed(Keys.Enter)) {
            setCheatsPanelVisible(true);
        }
    }
}

isCheatsPanelVisible :: inline () -> bool {
    ctx := context.gameContext;
    assert(ctx != null);

    scene := ctx.scene;
    assert(scene != null);

    return scene.cheatsPanel.enabled && scene.cheatsPanel.visible;
}

keyPressCheatsPanel :: (codepoint: u32) {
    ctx := context.gameContext;
    assert(ctx != null);

    scene := ctx.scene;
    assert(scene != null);

    cheatsPanel := *scene.cheatsPanel;
    if (cheatsPanel.enabled && cheatsPanel.visible) {
        if (hasEnoughFor(*cheatsPanel.text, 1)) {
            insertAt(*cheatsPanel.text, cheatsPanel.position, cast(u8) codepoint);
            cheatsPanel.position += 1;
        }
    }
}

#scope_file

setCheatsPanelVisible :: (visible: bool) {
    ctx := context.gameContext;
    scene := ctx.scene;

    cheatsPanel := *scene.cheatsPanel;
    cheatsPanel.visible = visible;
    cheatsPanel.position = 0;
    clear(*cheatsPanel.text);
}

getCheatsText :: (cheatsPanel: *CheatsPanel) -> string {
    cheatTextBuilder: StringBuilder;
    if (!isEmpty(cheatsPanel.prefix)) {
        appendToBuilder(*cheatTextBuilder, cheatsPanel.prefix);
    }
    appendToBuilder(*cheatTextBuilder, cheatsPanel.text.data, cheatsPanel.text.count);
    return builderToString(*cheatTextBuilder);
}

setCheatCursorPosition :: (cheatsPanel: *CheatsPanel, panelEntity: *Entity, cursorEntity: *Entity, textEntity: *Entity, statusText: string) {
    ctx := context.gameContext;
    assert(ctx != null);

    panelTransform := getComponent(panelEntity, TransformComponent);
    assert(panelTransform != null);

    textComponent := getComponent(textEntity, TextComponent);
    assert(textComponent != null);

    transformComponent := getComponent(cursorEntity, TransformComponent);
    assert(transformComponent != null);

    params: NVGfontParams;
    params.fontSize = textComponent.fontSize;
    params.fontData = ctx.fonts[textComponent.fontIndex];

    statusTextUpToCursor := slice(statusText, 0, cheatsPanel.prefix.count + cheatsPanel.position);
    statusTextUpToCursorSize := nvgMeasureSingleSpriteText(statusTextUpToCursor, params);
    transformComponent.position.x = panelTransform.position.x + statusTextUpToCursorSize.x;
}
