setCheatsPanelVisible :: (visible: bool) {
    ctx := context.gameContext;
    assert(ctx != null);

    scene := ctx.scene;
    assert(scene != null);

    cheatsPanel := *scene.cheatsPanel;
    cheatsPanel.visible = visible;
    cheatsPanel.position = 0;
    clear(*cheatsPanel.text);
}

setCheatsFeedback :: inline (feedbackText: string) {
    feedbackTextInternal := allocString(feedbackText);
    setCheatsFeedbackInternal(feedbackTextInternal);
}

setCheatsFeedbackFormat :: inline (feedbackTextFormat: string, args: ..Any) {
    feedbackTextInternal := sprint(feedbackTextFormat, ..args);
    setCheatsFeedbackInternal(feedbackTextInternal);
}

initCheatsPanel :: (prefix: string = "") {
    ctx := context.gameContext;
    assert(ctx != null);

    scene := ctx.scene;
    assert(scene != null);

    cheatsPanel := *scene.cheatsPanel;
    cheatsPanel.enabled = true;
    cheatsPanel.visible = false;
    cheatsPanel.position = 0;
    cheatsPanel.prefix = prefix;
    cheatsPanel.text = createFixedString(CHEAT_TEXT_MAX_LENGTH);

    uiEntity: *Entity;

    cheatSize := vec2(ctx.originalWindowSize.x, 12);
    cheatBackgroundColor := rgba(100, 100, 100, 160);
    uiEntity = createUIRect("panelCheat", VEC2_ZERO, cheatSize, cheatBackgroundColor);
    setUIEntityStatus(uiEntity, false);

    uiEntity = createUIText("txtCheat", 0, 6, "", vec2(2, 4));
    setUIEntityStatus(uiEntity, false);

    uiEntity = createUIRect("cursorCheat", vec2(2, 3), vec2(1, 7), COLOR_WHITE);
    setUIEntityStatus(uiEntity, false);

    uiEntity = createUIText("txtCheatFeedbackText", 1, 8, "", vec2(10, 20));
    setUITextColor(uiEntity, COLOR_YELLOW);
    setUIEntityStatus(uiEntity, false);
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

updateCheatsPanel :: () {
    ctx := context.gameContext;
    assert(ctx != null);

    scene := ctx.scene;
    assert(scene != null);

    cheatsPanel := *scene.cheatsPanel;
    if (!cheatsPanel.enabled) {
        return;
    }

    panelEntity := findUIEntity("panelCheat");
    assert(panelEntity != null);

    cursorEntity := findUIEntity("cursorCheat");
    assert(cursorEntity != null);

    textEntity := findUIEntity("txtCheat");
    assert(textEntity != null);

    feedbackText := findUIEntity("txtCheatFeedbackText");
    assert(feedbackText != null);

    if (cheatsPanel.feedback) {
        setUIEntityStatus(feedbackText, true);
        setUIText(feedbackText, cheatsPanel.feedbackText);

        cheatsPanel.feedbackTime -= ctx.deltaTime;
        if (cheatsPanel.feedbackTime <= 0) {
            cheatsPanel.feedbackTime = 0;
            cheatsPanel.feedback = false;
        }
    } else {
        setUIEntityStatus(feedbackText, false);
    }

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

        statusText := getStatusText(cheatsPanel);
        defer free(statusText);

        setUITextFormat(textEntity, statusText);
        setCursorPosition(cheatsPanel, cursorEntity, textEntity, statusText);

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

#scope_file

setCheatsFeedbackInternal :: (feedbackText: string) {
    ctx := context.gameContext;
    assert(ctx != null);

    scene := ctx.scene;
    assert(scene != null);

    cheatsPanel := *scene.cheatsPanel;
    if (!isEmpty(feedbackText)) {
        cheatsPanel.feedback = true;
        cheatsPanel.feedbackTime = 3.0;

        if (!isEmpty(cheatsPanel.feedbackText)) {
            free(cheatsPanel.feedbackText);
        }

        cheatsPanel.feedbackText = feedbackText;
    } else {
        cheatsPanel.feedback = false;
    }
}

getStatusText :: (cheatsPanel: *CheatsPanel) -> string {
    statusTextBuilder: StringBuilder;
    if (!isEmpty(cheatsPanel.prefix)) {
        appendToBuilder(*statusTextBuilder, cheatsPanel.prefix);
    }
    appendToBuilder(*statusTextBuilder, cheatsPanel.text.data, cheatsPanel.text.count);
    return builderToString(*statusTextBuilder);
}

setCursorPosition :: (cheatsPanel: *CheatsPanel, cursorEntity: *Entity, textEntity: *Entity, statusText: string) {
    ctx := context.gameContext;

    textComponent := getComponent(textEntity, TextComponent);
    assert(textComponent != null);

    transformComponent := getComponent(cursorEntity, TransformComponent);
    assert(transformComponent != null);

    params: NVGfontParams;
    params.fontSize = textComponent.fontSize;
    params.fontData = ctx.fonts[textComponent.fontIndex];

    statusTextUpToCursor := slice(statusText, 0, cheatsPanel.prefix.count + cheatsPanel.position);
    statusTextUpToCursorSize := nvgMeasureSingleSpriteText(statusTextUpToCursor, params);
    transformComponent.position.x = statusTextUpToCursorSize.x;
}
