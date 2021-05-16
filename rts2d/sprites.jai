SpriteFrame :: struct {
    dx: s32;
    dy: s32;
    w: s32;
    h: s32;
    off: u32;
    data: *u8;
}

Sprite :: struct {
    image: s32;
    frameWidth: s32;
    frameHeight: s32;
    framesCount: s32;
    frames: [MAX_SPRITE_FRAME_COUNT] SpriteFrame;
}

createSprite :: (width: s32, height: s32, data: *u8) -> Sprite {
    ctx := context.gameContext;
    assert(ctx != null);

    assert(width >= 0 && height >= 0);

    sprite: Sprite;
    sprite.frameWidth = width;
    sprite.frameHeight = height;
    sprite.framesCount = 1;

    sprite.image = nvgCreateImageRGBA(ctx.gfx, width, height, .NVG_IMAGE_NEAREST, data);

    sprite.frames[0].dx = 0;
    sprite.frames[0].dy = 0;
    sprite.frames[0].w = width;
    sprite.frames[0].h = height;
    sprite.frames[0].off = 0;
    sprite.frames[0].data = alloc(u8, width * height * 4);

    if (data) {
        memoryCopy(sprite.frames[0].data, data, width * height * 4);
    }

    return sprite;
}

createSpriteFromFrames :: (frameWidth: s32, frameHeight: s32, frames: [] SpriteFrame) -> Sprite {
    ctx := context.gameContext;
    assert(ctx != null);

    assert(frameWidth >= 0 && frameHeight >= 0);
    assert(frames.count > 0);

    sprite: Sprite;
    sprite.frameWidth = frameWidth;
    sprite.frameHeight = frameHeight;
    sprite.framesCount = cast(s32) frames.count;

    sprite.image = nvgCreateImageRGBA(ctx.gfx, frameWidth, frameHeight, .NVG_IMAGE_NEAREST, null);

    for i : range(s32, 0, frames.count) {
        sprite.frames[i].dx = frames[i].dx;
        sprite.frames[i].dy = frames[i].dy;
        sprite.frames[i].w = frames[i].w;
        sprite.frames[i].h = frames[i].h;
        sprite.frames[i].off = 0;
        sprite.frames[i].data = alloc(u8, frameWidth * frameHeight * 4);

        if (frames[i].data) {
            memoryCopy(sprite.frames[i].data, frames[i].data, frameWidth * frameHeight * 4);
        }
    }

    return sprite;
}

loadSprite :: (fontPath: string) -> Sprite {
    sprite: Sprite;

    width, height, bitsPerPixel: s32;
    data := stbi_load(toCString(fontPath, tempAllocator), *width, *height, *bitsPerPixel, 0);
    if (data) {
        sprite = createSprite(width, height, data);
        stbi_image_free(data);
    }

    return sprite;
}

updateSpriteImage :: inline (sprite: Sprite, imageData: *u8) {
    ctx := context.gameContext;
    assert(ctx != null);

    if (sprite.image == 0) {
        logWarning("Trying to update a sprite with image: %d\n", sprite.image);
        return;
    }

    nvgUpdateImage(ctx.gfx, sprite.image, imageData);
}

renderSubSprite :: inline (sprite: Sprite, rs: Rect, rd: Rect, scale: Vec2) {
    ctx := context.gameContext;
    assert(ctx != null);

    if (sprite.image == 0) {
        logWarning("Trying to render a sprite with image: %d\n", sprite.image);
        return;
    }

    nvgRenderSubImage(ctx.gfx, sprite.image, rs, rd, scale);
}

renderSprite :: inline (sprite: Sprite, pos: Vec2, scale: Vec2) {
    ctx := context.gameContext;
    assert(ctx != null);

    if (sprite.image == 0) {
        logWarning("Trying to render a sprite with image: %d\n", sprite.image);
        return;
    }

    frameSize := vec2(sprite.frameWidth, sprite.frameHeight);
    rs := rect(VEC2_ZERO, frameSize);
    rd := rect(pos, frameSize);
    nvgRenderSubImage(ctx.gfx, sprite.image, rs, rd, scale);
}

getSpriteFrame :: inline (sprite: Sprite, frameIndex: s32) -> SpriteFrame {
    assert(sprite.image != 0);
    assert(frameIndex >= 0 && frameIndex < sprite.framesCount);
    return sprite.frames[frameIndex];
}

freeSprite :: (sprite: Sprite) {
    ctx := context.gameContext;
    assert(ctx != null);

    if (sprite.image == 0) {
        logWarning("Trying to free a sprite with image: %d\n", sprite.image);
        return;
    }

    for frame : sprite.frames {
        if (frame.data) {
            free(frame.data);
        }
    }

    nvgDeleteImage(ctx.gfx, sprite.image);
}
