EntityId :: u16;

EntityType :: enum u16 {
    None;

    // Units
    Unit;

    // UI
    Image;
    Text;
    Rect;
    Button;
    Cursor;

    Audio;

    Minimap;
    Animation;
}

Entity :: struct {
    id: EntityId;
    type: EntityType;
    enabled: bool;
    components: [#run getCount(ComponentType)] s32;
}

EntityManager :: struct {
    entitiesById: HashMap(EntityId, Entity);
    entitiesByType: HashMap(EntityType, List(EntityId));
    uiEntities: List(EntityId);
}

operator == :: (e1: Entity, e2: Entity) -> bool {
    return equalsEntity(e1, e2);
}

equalsEntity :: inline (e1: Entity, e2: Entity) -> bool {
    return e1.id == e2.id;
}

equalsEntity :: inline (e1: *Entity, e2: *Entity) -> bool {
    return e1.id == e2.id;
}

hashEntityType :: inline (type: EntityType) -> s64 {
    return cast(s64) type;
}

hashEntityId :: inline (id: EntityId) -> s64 {
    return cast(s64) id;
}

initEntityManager :: (manager: *EntityManager) {
    // initialize the entities by id map
    init(*manager.entitiesById, HashMapOptions(EntityId, Entity).{
        hashFn = hashEntityId
    });

    // initialize entity by type map
    init(*manager.entitiesByType, HashMapOptions(EntityType, List(EntityId)).{
        hashFn = hashEntityType
    });

    for entry : iterate(EntityType) {
        set(*manager.entitiesByType, entry.value, createList(EntityId));
    }

    // initialize ui entities list
    init(*manager.uiEntities);
}

freeEntityManager :: (manager: *EntityManager) {
    uninit(*manager.entitiesById);
    uninit(*manager.entitiesByType);
    uninit(*manager.uiEntities);
}

createEntity :: (type: EntityType) -> *Entity {
    ctx := context.gameContext;

    assert(ctx != null);
    assert(ctx.scene != null);

    staticEntityId += 1;

    entityManager := *ctx.scene.entityManager;

    entity: Entity;
    entity.id = staticEntityId;
    entity.type = type;
    entity.enabled = true;

    for i : range(s32, 0, #run getCount(ComponentType)) {
        entity.components[i] = -1;
    }

    set(*entityManager.entitiesById, entity.id, entity);

    found, entitiesOfType := ref(*entityManager.entitiesByType, type);
    if (found) {
        add(entitiesOfType, entity.id);
    }

    if (isUIEntity(*entity)) {
        add(*entityManager.uiEntities, entity.id);
    }

    _, result := ref(*entityManager.entitiesById, entity.id);
    return result;
}

removeEntityById :: (id: EntityId) {
    ctx := context.gameContext;

    assert(ctx != null);
    assert(ctx.scene != null);

    entityManager := *ctx.scene.entityManager;

    logDebug("trying to remove entity with id: %\n", id);

    entity := findEntity(id);
    if (entity != null) {
        // pthread_mutex_lock(&context.__mutex);

        if (isUIEntity(entity)) {
            removeItem(*entityManager.uiEntities, entity.id);
        }

        found, entities := ref(*entityManager.entitiesByType, entity.type);
        if (found) {
            removeItem(entities, entity.id);
        }

        for entry : iterate(ComponentType) {
            removeComponent(entity, entry.value);
        }

        removeKey(*entityManager.entitiesById, entity.id);

        // pthread_mutex_unlock(&context.__mutex);

        logDebug("removed entity with id: %\n", id);
    }
}

getEntitiesOfType :: (type: EntityType) -> List(*Entity) {
    ctx := context.gameContext;

    assert(ctx != null);
    assert(ctx.scene != null);

    entitiesOfType := createList(*Entity);

    entityManager := *ctx.scene.entityManager;
    found, entities := ref(*entityManager.entitiesByType, type);
    if (found) {
        for id : entities {
            found, entity := ref(*entityManager.entitiesById, id);
            assert(found && entity != null);

            add(*entitiesOfType, entity);
        }
    }

    return entitiesOfType;
}

getUnitsOfPlayer :: (player: u8) -> List(*Entity) {
    ctx := context.gameContext;

    assert(ctx != null);
    assert(ctx.scene != null);

    unitsOfPlayer := createList(*Entity);

    entityManager := *ctx.scene.entityManager;
    found, entities := ref(*entityManager.entitiesByType, EntityType.Unit);
    if (found) {
        for id : entities {
            found, entity := ref(*entityManager.entitiesById, id);
            assert(found && entity != null);

            unit := getComponent(entity, UnitComponent);
            assert(unit != null);

            if (unit.player == player) {
                add(*unitsOfPlayer, entity);
            }
        }
    }

    return unitsOfPlayer;
}

getUIEntities :: () -> List(*Entity) {
    ctx := context.gameContext;

    assert(ctx != null);
    assert(ctx.scene != null);

    uiEntities := createList(*Entity);

    entityManager := *ctx.scene.entityManager;
    for id : entityManager.uiEntities {
        found, entity := ref(*entityManager.entitiesById, id);
        assert(found && entity != null && isUIEntity(entity));

        add(*uiEntities, entity);
    }

    return uiEntities;
}

findEntity :: (id: EntityId) -> *Entity {
    ctx := context.gameContext;

    assert(ctx != null);
    assert(ctx.scene != null);

    entityManager := *ctx.scene.entityManager;
    found, entity := ref(*entityManager.entitiesById, id);
    return ifx found then entity else null;
}

findUIEntity :: (name: string) -> *Entity {
    ctx := context.gameContext;

    assert(ctx != null);
    assert(ctx.scene != null);

    entityManager := *ctx.scene.entityManager;
    for id : entityManager.uiEntities {
        found, entity := ref(*entityManager.entitiesById, id);
        assert(found && entity != null);

        ui := getComponent(entity, UIComponent);
        assert(ui != null);

        if (ui.name == name) {
            return entity;
        }
    }

    return null;
}

isUIEntity :: (entity: *Entity) -> bool {
    if entity.type == {
        case EntityType.Image; #through;
        case EntityType.Text; #through;
        case EntityType.Rect; #through;
        case EntityType.Button; #through;
        case EntityType.Cursor; #through;
        case EntityType.Minimap;
            return true;

        case;
            return false;
    }
}

renderEntity :: (entity: *Entity) {
    ctx := context.gameContext;

    assert(ctx != null);
    assert(entity != null);

    if (entity.id > 0 && entity.enabled) {
        renderFn := renderFns[cast(s32) entity.type];
        if (renderFn == null) {
            logError("Entity of type % can't be render. renderFn = NULL\n", entity.type);
            return;
        }

        nvgSave(ctx.gfx);
        renderFn(entity);
        nvgRestore(ctx.gfx);
    }
}

#scope_file

staticEntityId: EntityId = 0;

RenderFunc :: #type (entity: *Entity);

renderFns : [] RenderFunc = .[
    null,               // NONE
    null,               // UNIT
    renderImage,        // IMAGE
    renderText,         // TEXT
    renderRect,         // RECT
    renderButton,       // BUTTON
    renderImage,        // CURSOR
    null,               // AUDIO
    null,               // MINIMAP
    renderAnimation,    // ANIMATION
];

renderImage :: (entity: *Entity) {
    ctx := context.gameContext;
    assert(ctx != null);

    transform := getComponent(entity, TransformComponent);
    assert(transform != null);

    ui := getComponent(entity, UIComponent);
    assert(ui != null);

    sprite := getComponent(entity, SpriteComponent);
    assert(sprite != null);

    if (ui.enabled && sprite.enabled && sprite.frameIndex >= 0) {
        nvgSave(ctx.gfx);

        if (sprite.sprite.framesCount > 1) {
            frame := getSpriteFrame(sprite.sprite, sprite.frameIndex);
            updateSpriteImage(sprite.sprite, frame.data);

            nvgTranslate(ctx.gfx, cast(f32) -frame.dx, cast(f32) -frame.dy);
        }

        nvgTranslate(ctx.gfx, transform.position.x, transform.position.y);
        renderSprite(sprite.sprite, VEC2_ZERO, VEC2_ONE);
        nvgRestore(ctx.gfx);
    }
}

renderText :: (entity: *Entity) {
    ctx := context.gameContext;
    assert(ctx != null);

    transform := getComponent(entity, TransformComponent);
    assert(transform != null);

    ui := getComponent(entity, UIComponent);
    assert(ui != null);

    text := getComponent(entity, TextComponent);
    assert(text != null);

    if (ui.enabled && text.enabled && !isEmpty(text.text)) {
        nvgSave(ctx.gfx);
        nvgTranslate(ctx.gfx, transform.position.x, transform.position.y);
        nvgScale(ctx.gfx, transform.scale.x, transform.scale.y);

        params: NVGfontParams;
        params.fontIndex = text.fontIndex;
        params.fontSize = text.fontSize;
        params.lineHeight = text.lineHeight;
        params.fontColor = colorToNVGcolor(text.fontColor);
        params.highlightColor = colorToNVGcolor(text.highlightColor);
        params.highlightIndex = text.highlightIndex;
        params.highlightCount = text.highlightCount;
        params.boundings = text.boundings;
        params.horizontalAlign = textAlignToNVGalign(text.horizontalAlign);
        params.verticalAlign = textAlignToNVGalign(text.verticalAlign);
        params.lineAlign = textAlignToNVGalign(text.lineAlign);
        params.wrapping = textWrappingToNVGwrap(text.wrapping);
        params.trimming = textTrimmingToNVGtrim(text.trimming);
        params.fontData = ctx.fonts[text.fontIndex];

        if (text.multiline) {
            nvgMultiSpriteText(ctx.gfx, toCString(text.text, tempAllocator), 0, 0, params);
        } else {
            nvgSingleSpriteText(ctx.gfx, toCString(text.text, tempAllocator), 0, 0, params);
        }

        nvgRestore(ctx.gfx);
    }
}

renderRect :: (entity: *Entity) {
    ctx := context.gameContext;
    assert(ctx != null);

    transform := getComponent(entity, TransformComponent);
    assert(transform != null);

    ui := getComponent(entity, UIComponent);
    assert(ui != null);

    rectComponent := getComponent(entity, RectComponent);
    assert(rectComponent != null);

    if (ui.enabled && rectComponent.enabled) {
        nvgSave(ctx.gfx);
        nvgTranslate(ctx.gfx, transform.position.x, transform.position.y);
        nvgScale(ctx.gfx, transform.scale.x, transform.scale.y);

        color := nvgRGBA(rectComponent.color.r, rectComponent.color.g, rectComponent.color.b, rectComponent.color.a);
        nvgFillRect(ctx.gfx, rect(0.0, 0.0, rectComponent.size.x, rectComponent.size.y), color);

        nvgRestore(ctx.gfx);
    }
}

renderButton :: (entity: *Entity) {
    ctx := context.gameContext;
    assert(ctx != null);

    transform := getComponent(entity, TransformComponent);
    assert(transform != null);

    ui := getComponent(entity, UIComponent);
    assert(ui != null);

    button := getComponent(entity, ButtonComponent);
    assert(button != null);

    if (ui.enabled && button.enabled) {
        nvgSave(ctx.gfx);
        nvgTranslate(ctx.gfx, transform.position.x, transform.position.y);
        nvgScale(ctx.gfx, transform.scale.x, transform.scale.y);

        // render background
        {
            backgroundSprite := ifx button.active then button.backgroundPressedSprite else button.backgroundNormalSprite;
            renderSprite(backgroundSprite, VEC2_ZERO, VEC2_ONE);
        }

        // render foreground
        {
            sprite := getComponent(entity, SpriteComponent);
            if (sprite != null && sprite.enabled) {
                backgroundSize := vec2(button.backgroundNormalSprite.frameWidth, button.backgroundNormalSprite.frameHeight);
                foregroundSize := vec2(sprite.sprite.frameWidth, sprite.sprite.frameHeight);
                offset := (backgroundSize - foregroundSize) / 2;

                if (button.active) {
                    offset = offset + vec2(0, 1);
                }

                nvgTranslate(ctx.gfx, offset.x, offset.y);

                frame := getSpriteFrame(sprite.sprite, sprite.frameIndex);
                updateSpriteImage(sprite.sprite, frame.data);
                renderSprite(sprite.sprite, VEC2_ZERO, VEC2_ONE);
            }
        }

        // render text
        {
            text := getComponent(entity, TextComponent);
            if (text != null && text.enabled && !isEmpty(text.text)) {
                params: NVGfontParams;
                params.fontIndex = text.fontIndex;
                params.fontSize = text.fontSize;
                params.fontColor = colorToNVGcolor(text.fontColor);
                params.highlightColor = colorToNVGcolor(text.highlightColor);
                params.highlightIndex = ifx button.hot then ALL_HIGHLIGHT else text.highlightIndex;
                params.highlightCount = text.highlightCount;
                params.boundings = text.boundings;
                params.horizontalAlign = textAlignToNVGalign(text.horizontalAlign);
                params.verticalAlign = textAlignToNVGalign(text.verticalAlign);
                params.lineAlign = textAlignToNVGalign(text.lineAlign);
                params.wrapping = textWrappingToNVGwrap(text.wrapping);
                params.fontData = ctx.fonts[text.fontIndex];

                nvgSingleSpriteText(ctx.gfx, toCString(text.text, tempAllocator), 0, 0, params);
            }
        }

        nvgRestore(ctx.gfx);
    }
}

renderAnimation :: (entity: *Entity) {
    ctx := context.gameContext;
    assert(ctx != null);

    transform := getComponent(entity, TransformComponent);
    assert(transform != null);

    animations := getComponent(entity, AnimationsComponent);
    assert(animations != null);

    if (animations.enabled) {
        nvgTranslate(ctx.gfx, transform.position.x, transform.position.y);

        for anim : animations.animations {
            if (anim.status == SpriteAnimationStatus.Running) {
                nvgSave(ctx.gfx);

                nvgTranslate(ctx.gfx, anim.offset.x, anim.offset.y);
                nvgScale(ctx.gfx, anim.scale.x, anim.scale.y);

                animFrameIndex := cast(s32) (anim.animTime * anim.frames.count);
                animFrameIndex = clamp(animFrameIndex, 0, cast(s32) anim.frames.count - 1);

                spriteFrameIndex := anim.frames[animFrameIndex];
                frame := getSpriteFrame(anim.sprite, spriteFrameIndex);

                updateSpriteImage(anim.sprite, frame.data);
                renderSprite(anim.sprite, VEC2_ZERO, VEC2_ONE);

                nvgRestore(ctx.gfx);
            }
        }
    }
}
