SceneFn :: #type ();

// SceneType :: enum {
//     Map;
// }

Scene :: struct {
    //type: SceneType;
    entityManager: EntityManager;
    componentsManager: ComponentsManager;
    cheatsManager: CheatsManager;
    cheatsPanel: CheatsPanel;
    flashText: FlashText;

    enterSceneFn: SceneFn;
    leaveSceneFn: SceneFn;
    updateSceneFn: SceneFn;
    renderSceneFn: SceneFn;
}

// createScene :: (sceneType: SceneType) -> *Scene {
//     assert(ctx != null);

//     type := sceneTypeMapping[sceneType];
//     scene := cast(*Scene) staticAlloc(type);
//     initEntityManager(*scene.entityManager);
//     initComponentsManager(*scene.componentsManager);
//     return scene;
// }

createScene :: ($type: Type) -> *type {
    scene := alloc(type);
    initEntityManager(*scene.entityManager);
    initComponentsManager(*scene.componentsManager);
    initCheatsManager(*scene.cheatsManager);
    return scene;
}

freeScene :: (scene: *Scene) {
    assert(scene != null);

    freeEntityManager(*scene.entityManager);
    freeComponentsManager(*scene.componentsManager);
    free(scene);
}

setNextScene :: (scene: *Scene, transitionDelay: f32) {
    ctx := context.gameContext;
    assert(ctx != null);

    ctx.nextScene = scene;
    ctx.transitionDelay = transitionDelay;
}

enterScene :: () {
    ctx := context.gameContext;

    assert(ctx != null);
    assert(ctx.scene != null);

    if (ctx.scene.enterSceneFn != null) {
        ctx.scene.enterSceneFn();
    }
}

leaveScene :: () {
    ctx := context.gameContext;
    assert(ctx != null);

    if (ctx.scene == null) {
        return;
    }

    if (ctx.scene.leaveSceneFn != null) {
        ctx.scene.leaveSceneFn();
    } else {
        freeScene(ctx.scene);
        ctx.scene = null;
    }
}

updateScene :: () {
    ctx := context.gameContext;

    assert(ctx != null);
    assert(ctx.scene != null);

    if (ctx.scene.updateSceneFn != null) {
        ctx.scene.updateSceneFn();
    } else {
        updateCheatsPanel();
        updateFlashText(isCheatsPanelVisible());
        updateUIButtons(!isCheatsPanelVisible());
        updateUICursor();
        updateAnimations();
    }
}

renderScene :: () {
    ctx := context.gameContext;

    assert(ctx != null);
    assert(ctx.scene != null);

    nvgSave(ctx.gfx);
    nvgScale(ctx.gfx, ctx.globalScale, ctx.globalScale);

    if (ctx.scene.renderSceneFn != null) {
        ctx.scene.renderSceneFn();
    } else {
        entityManager := *ctx.scene.entityManager;
        for *entry : entityManager.entitiesById {
            entity := entry.value;
            assert(entity != null);

            renderEntity(entity);
        }
    }

    nvgRestore(ctx.gfx);
}

#scope_file
