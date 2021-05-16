SpriteAnimationStatus :: enum {
    NotStarted;
    Running;
    Finished;
}

SpriteAnimation :: struct {
    name: string;
    loop: bool;
    loopDelay: f32;

    offset: Vec2;
    scale: Vec2;

    frameDelay: f32;
    frames: List(s32);
    sprite: Sprite;

    animTime: f32;
    loopTime: f32;
    status: SpriteAnimationStatus;
}

equalsAnim :: inline (anim1: SpriteAnimation, anim2: SpriteAnimation) -> bool {
    return anim1.name == anim2.name;
}

equalsAnim :: inline (anim1: *SpriteAnimation, anim2: *SpriteAnimation) -> bool {
    return anim1.name == anim2.name;
}

createAnimation :: (name: string, sprite: Sprite, frameDelay: f32, loop: bool) -> *SpriteAnimation {
    anim := alloc(SpriteAnimation);
    anim.name = allocString(name);
    anim.loop = loop;
    anim.offset = VEC2_ZERO;
    anim.scale = VEC2_ONE;
    anim.frameDelay = frameDelay;
    anim.sprite = sprite;
    anim.animTime = 0;
    anim.loopTime = 0;
    anim.status = SpriteAnimationStatus.NotStarted;
    init(*anim.frames);
    return anim;
}

addAnimation :: inline (entity: *Entity, animation: *SpriteAnimation) {
    component := getComponent(entity, AnimationsComponent);
    assert(component != null);

    add(*component.animations, animation);
}

addAnimationFrame :: inline (animation: *SpriteAnimation, frameIndex: s32) {
    assert(animation != null);
    add(*animation.frames, frameIndex);
}

addAnimationFrames :: inline (animation: *SpriteAnimation, frameIndices: ..s32) {
    for index : frameIndices {
        addAnimationFrame(animation, index);
    }
}

addAnimationFramesRange :: inline (animation: *SpriteAnimation, from: s32, to: s32) {
    assert(from >= 0 && to >= 0);

    for i : range(s32, from, to, toInclusive=true) {
        addAnimationFrame(animation, i);
    }
}

getAnimationDuration :: inline (animation: *SpriteAnimation) -> f32 {
    assert(animation != null);
    return animation.frameDelay * animation.frames.count;
}

freeAnimation :: (animation: *SpriteAnimation) {
    assert(animation != null);

    logInfo("Freeing animation: %\n", animation.name);

    free(animation.name);
    uninit(*animation.frames);
    for frame : animation.sprite.frames {
        free(frame.data);
    }
    free(animation);
}

findAnimationIndex :: (entity: *Entity, name: string) -> s32 {
    component := getComponent(entity, AnimationsComponent);
    assert(component != null);

    for anim, i : component.animations {
        if (anim.name == name) {
            return cast(s32) i;
        }
    }

    return -1;
}

findAnimation :: (entity: *Entity, name: string) -> *SpriteAnimation {
    component := getComponent(entity, AnimationsComponent);
    assert(component != null);

    for anim, i : component.animations {
        if (anim.name == name) {
            return anim;
        }
    }

    return null;
}

containsAnimation :: inline (entity: *Entity, name: string) -> bool {
    return findAnimationIndex(entity, name) >= 0;
}

removeAnimation :: (entity: *Entity, name: string) {
    logInfo("Trying to remove animation: %\n", name);

    index := findAnimationIndex(entity, name);
    if (index >= 0) {
        component := getComponent(entity, AnimationsComponent);
        assert(component != null);

        removeAt(*component.animations, index);
    }
}

resetAnimation :: (animation: *SpriteAnimation) {
    assert(animation != null);

    animation.animTime = 0;
    animation.loopTime = 0;
    animation.status = SpriteAnimationStatus.NotStarted;
}

updateAnimation :: (entity: *Entity, animation: *SpriteAnimation) {
    ctx := context.gameContext;
    assert(ctx != null);

    if (animation.status == SpriteAnimationStatus.Finished) {
        removeAnimation(entity, animation.name);
        return;
    }

    animation.status = SpriteAnimationStatus.Running;

    if (animation.loopTime > 0) {
        animation.loopTime -= getScaledSpeed(ctx.deltaTime);
        return;
    }

    dt := ctx.deltaTime / getAnimationDuration(animation);
    dt = getScaledSpeed(dt);

    animation.animTime += dt;

    if (animation.animTime >= 1) {
        animation.animTime = 1;
        animation.status = SpriteAnimationStatus.Finished;

        if(animation.loop) {
            resetAnimation(animation);
            animation.loopTime = animation.loopDelay;
            animation.status = SpriteAnimationStatus.Running;
        }
    }
}

updateAnimations :: () {
    ctx := context.gameContext;

    assert(ctx != null);
    assert(ctx.scene != null);

    entityManager := *ctx.scene.entityManager;
    for * entry : entityManager.entitiesById {
        entity := entry.value;
        assert(entity != null);

        component := getComponent(entity, AnimationsComponent);
        if (component != null && component.enabled) {
            for anim : component.animations {
                updateAnimation(entity, anim);
            }
        }
    }
}
