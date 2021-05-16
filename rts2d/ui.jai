setUIEntityStatus :: inline (entity: *Entity, enabled: bool) {
    setComponentStatus(entity, ComponentType.UI, enabled);
}

clearUIText :: (entity: *Entity) {
    textComponent := getComponent(entity, TextComponent);
    assert(textComponent != null);

    free(textComponent.text);

    textComponent.text = "";
    textComponent.enabled = false;
}

setUIText :: (entity: *Entity, text: string) {
    textComponent := getComponent(entity, TextComponent);
    assert(textComponent != null);

    free(textComponent.text);

    textComponent.text = allocString(text);
    textComponent.enabled = true;
}

setUITextFormat :: (entity: *Entity, format: string, args: ..Any) {
    text := tprint(format, args);
    setUIText(entity, text);
}

setUIImage :: (entity: *Entity, frameIndex: s32) {
    sprite := getComponent(entity, SpriteComponent);
    assert(sprite != null);

    sprite.frameIndex = frameIndex;
    sprite.enabled = frameIndex >= 0;
}

setUIRectWidth :: (entity: *Entity, width: s32) {
    rect := getComponent(entity, RectComponent);
    assert(rect != null);

    rect.size.x = cast(f32) width;
    rect.enabled = width > 0;
}

clearUITooltip :: (entity: *Entity) {
    button := getComponent(entity, ButtonComponent);
    assert(button != null);

    free(button.tooltip);
    button.tooltip = "";
}

setUITooltip :: (entity: *Entity, highlightIndex: s32, highlightCount: s32, text: string) {
    button := getComponent(entity, ButtonComponent);
    assert(button != null);

    free(button.tooltip);

    button.highlightIndex = highlightIndex;
    button.highlightCount = highlightCount;
    button.tooltip = text;
}

setUITextBoundings :: inline (entity: *Entity, value: Vec2) {
    text := getComponent(entity, TextComponent);
    assert(text != null);

    text.boundings = value;
}

setUITextHorizontalAlign :: inline (entity: *Entity, value: TextAlignment) {
    text := getComponent(entity, TextComponent);
    assert(text != null);

    text.horizontalAlign = value;
}

setUITextVerticalAlign :: inline (entity: *Entity, value: TextAlignment) {
    text := getComponent(entity, TextComponent);
    assert(text != null);

    text.verticalAlign = value;
}

setUITextLineAlign :: inline (entity: *Entity, value: TextAlignment) {
    text := getComponent(entity, TextComponent);
    assert(text != null);

    text.lineAlign = value;
}

setUITextWrapping :: inline (entity: *Entity, value: TextWrapping) {
    text := getComponent(entity, TextComponent);
    assert(text != null);

    text.wrapping = value;
}

setUITextColor :: inline (entity: *Entity, value: Color) {
    text := getComponent(entity, TextComponent);
    assert(text != null);

    text.fontColor = value;
}

setUITextHighlight :: inline (entity: *Entity, index: s32, count: s32) {
    text := getComponent(entity, TextComponent);
    assert(text != null);

    text.highlightIndex = index;
    text.highlightCount = count;
}

setUITextHighlightColor :: inline (entity: *Entity, color: Color) {
    text := getComponent(entity, TextComponent);
    assert(text != null);

    text.highlightColor = color;
}

setUITextMultiline :: inline (entity: *Entity, value: bool) {
    text := getComponent(entity, TextComponent);
    assert(text != null);

    text.multiline = value;
}

setUITextLineHeight :: inline (entity: *Entity, value: f32) {
    text := getComponent(entity, TextComponent);
    assert(text != null);

    text.lineHeight = value;
}

setUITextTrimming :: inline (entity: *Entity, value: TextTrimming) {
    text := getComponent(entity, TextComponent);
    assert(text != null);

    text.trimming = value;
}

setUIButtonInteractive :: inline (entity: *Entity, value: bool) {
    button := getComponent(entity, ButtonComponent);
    assert(button != null);

    button.interactive = value;
}

setUIButtonHotKey :: inline (entity: *Entity, key: Keys) {
    button := getComponent(entity, ButtonComponent);
    assert(button != null);

    button.hotKey = key;
}

setUIButtonClickHandler :: inline (entity: *Entity, handler: ClickHandler) {
    button := getComponent(entity, ButtonComponent);
    assert(button != null);

    button.clickHandler = handler;
}

setUIButtonStatus :: inline (entity: *Entity, enabled: bool) {
    setComponentStatus(entity, ComponentType.Button, enabled);
}

setUIButtonStatusByName :: (name: string, enabled: bool) {
    entity := findUIEntity(name);
    if (entity) {
        setUIButtonStatus(entity, enabled);
    }
}

setUIButtonInteractiveByName :: (name: string, interactive: bool) {
    entity := findUIEntity(name);
    if (entity) {
        setUIButtonInteractive(entity, interactive);
    }
}

setUIButtonHotKeyByName :: (name: string, key: Keys) {
    entity := findUIEntity(name);
    if (entity) {
        setUIButtonHotKey(entity, key);
    }
}

setUIEntityStatusByName :: (name: string, enabled: bool) {
    entity := findUIEntity(name);
    if (entity) {
        setUIEntityStatus(entity, enabled);
    }
}

createUIText :: (name: string, fontIndex: s32, fontSize: f32, text: string, position: Vec2) -> *Entity {
    entity := createEntity(EntityType.Text);
    addTransformComponent(entity, position);
    addUIComponent(entity, name);
    addTextComponent(entity, fontIndex, fontSize, text);
    return entity;
}

createUIRect :: (name: string, position: Vec2, size: Vec2, color: Color) -> *Entity {
    entity := createEntity(EntityType.Rect);
    addTransformComponent(entity, position);
    addUIComponent(entity, name);
    addRectComponent(entity, size, color);
    return entity;
}

createUIImage :: (name: string, sprite: Sprite, position: Vec2) -> *Entity {
    entity := createEntity(EntityType.Image);
    addTransformComponent(entity, position);
    addUIComponent(entity, name);
    addSpriteComponent(entity, sprite);
    return entity;
}

createUITextButton :: (name: string,
                       fontIndex: s32,
                       fontSize: f32,
                       text: string,
                       backgroundNormalSprite: Sprite,
                       backgroundPressedSprite: Sprite,
                       foregroundSprite: Sprite,
                       position: Vec2) -> *Entity
{
    entity := createEntity(EntityType.Button);
    addTransformComponent(entity, position);
    addUIComponent(entity, name);
    addSpriteComponent(entity, foregroundSprite);
    textComponent := addTextComponent(entity, fontIndex, fontSize, text);
    buttonComponent := addButtonComponent(entity, backgroundNormalSprite, backgroundPressedSprite);

    textComponent.boundings = vec2(buttonComponent.normalSprite.frameWidth, buttonComponent.normalSprite.frameHeight);
    textComponent.horizontalAlign = TextAlignment.Center;
    textComponent.verticalAlign = TextAlignment.Middle;

    return entity;
}

createUIImageButton :: (name: string,
                        backgroundNormalSprite: Sprite,
                        backgroundPressedSprite: Sprite,
                        foregroundSprite: Sprite,
                        position: Vec2) -> *Entity
{
    entity := createEntity(EntityType.Button);
    addTransformComponent(entity, position);
    addUIComponent(entity, name);
    addSpriteComponent(entity, foregroundSprite);
    addButtonComponent(entity, backgroundNormalSprite, backgroundPressedSprite);
    return entity;
}

updateUIButtons :: (hotKeysEnabled: bool) {
    ctx := context.gameContext;
    assert(ctx != null);

    input := *ctx.input;

    buttons := getEntitiesOfType(EntityType.Button);

    // store the buttons to update in this frame first
    // because the action of some buttons is to show other buttons
    // in their same location, and if the newly shown button is
    // after in the list, then it will update in this same frame
    // which it shouldn't happen
    buttonsToUpdate := createHashSet(EntityId, HashSetOptions(EntityId).{
        hashFn = hashEntityId
    });
    defer uninit(*buttonsToUpdate);

    for entity : buttons {
        ui := getComponent(entity, UIComponent);
        button := getComponent(entity, ButtonComponent);

        if (ui.enabled && button.enabled && button.interactive) {
            add(*buttonsToUpdate, entity.id);
        } else {
            button.hot = false;
            button.active = false;
        }
    }

    for entity : buttons {
        if (contains(*buttonsToUpdate, entity.id)) {
            transform := getComponent(entity, TransformComponent);
            button := getComponent(entity, ButtonComponent);

            if (hotKeysEnabled && wasKeyPressed(button.hotKey)) {
                if (button.clickHandler) {
                    button.hot = false;
                    button.active = false;

                    button.clickHandler(entity);

                    // in this case break to not allow pressing multiple keys
                    // and executing all of the command for those keys
                    break;
                }
            }

            backgroundSize := vec2(button.backgroundNormalSprite.frameWidth, button.backgroundNormalSprite.frameHeight);
            buttonRect := rect(transform.position, backgroundSize);
            pointerInside := contains(buttonRect, input.pos.x, input.pos.y);

            if (wasButtonPressed(MouseButtons.Left)) {
                if (button.active) {
                    if (pointerInside && button.clickHandler) {
                        button.clickHandler(entity);
                        // createAudio(WAR_UI_CLICK, false);
                    }

                    button.active = false;
                }
            } else if (isButtonPressed(MouseButtons.Left)) {
                if (button.hot) {
                    button.active = true;
                }
            } else if (pointerInside) {
                for other : buttons {
                    otherButton := getComponent(other, ButtonComponent);
                    otherButton.hot = false;
                    otherButton.active = false;
                }

                button.hot = true;
                button.active = false;
            } else {
                button.hot = false;
                button.active = false;
            }
        }
    }
}

renderUIEntities :: () {
    entities := getUIEntities();
    for entity : entities {
        renderEntity(entity);
    }
}
