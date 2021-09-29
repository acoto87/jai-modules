#import "math-jai";
#import "collections";
#import "strings";
#import "utils";

rl :: #import "raylib";

NUMBER_OF_BOIDS :: 2000;
BOID_WIDTH :: 7;
BOID_HEIGHT :: 9;
BOID_MAX_SPEED :: 6.0;
BOID_PERCEPTION :: 50.0;
BOID_TRAIL_LENGTH :: 10;
ALIGNMENT_FACTOR :: 0.1;
SEPARATION_FACTOR :: 0.1;
SEPARATION_DISTANCE :: 1.5 * #run sqrtf(BOID_WIDTH * BOID_WIDTH + BOID_HEIGHT * BOID_HEIGHT);
COHESION_FACTOR :: 0.01;
BOUNDS_MARGIN :: 0;
BOUNDS_STEERING_FACTOR :: 0.7;
RENDER_QUADTREE :: false;
RENDER_PERCEPTION :: false;
RENDER_TRAILS :: false;

Flock :: struct {
    boids: *List(*Boid);
    boidsQuadTree: *QuadTree;
}

Boid :: struct {
    id: s32;
    position: Vec2;
    velocity: Vec2;
    color: Color;

    #if (RENDER_TRAILS) {
        trail: List(Vec2);
    }
}

#add_context flock: *Flock;

main :: () {
    screenWidth : s32 = 1366;
    screenHeight : s32 = 768;

    initGame("Boids", screenWidth, screenHeight);

    // rl.SetTargetFPS(60);

    while (!rl.WindowShouldClose()) {
        updateGame();
        renderGame();
    }

    rl.CloseWindow();
}

initGame :: (windowTitle: string, windowWidth: s32, windowHeight: s32) {
    rl.InitWindow(windowWidth, windowHeight, toCString(windowTitle));

    context.flock = alloc(Flock);
    initFlock();
}

initFlock :: (numberOfBoids := NUMBER_OF_BOIDS) {
    flock := context.flock;

    screenWidth := rl.GetScreenWidth();
    screenHeight := rl.GetScreenHeight();

    options: ListOptions(*Boid);
    options.capacity = numberOfBoids;
    options.freeItems = true;

    flock.boids = alloc(List(*Boid));
    init(flock.boids, options);

    for 0..numberOfBoids-1 {
        position := vec2(
            randomNext(0, screenWidth),
            randomNext(0, screenHeight)
        );
        velocity := vec2Random() * randomNext(5, 10);

        boid := alloc(Boid);
        initBoid(boid, position, velocity);
        add(flock.boids, boid);
    }

    initQuadTree();
}

initQuadTree :: () {
    flock := context.flock;

    screenWidth := rl.GetScreenWidth();
    screenHeight := rl.GetScreenHeight();

    boundary := rect(
        0, 0,
        screenWidth, screenHeight
    );

    flock.boidsQuadTree = alloc(QuadTree);
    init(flock.boidsQuadTree, boundary, 1);
    for boid : flock.boids {
        insert(flock.boidsQuadTree, vec2(boid.position.x, boid.position.y), boid);
    }
}

updateGame :: () {
    flock := context.flock;

    for boid : flock.boids {
        updateBoid(boid);
    }

    uninit(flock.boidsQuadTree, true);
    initQuadTree();
}

renderGame :: () {
    flock := context.flock;

    rl.BeginDrawing();
        rl.ClearBackground(rl.BLACK);

        #if (RENDER_QUADTREE) {
            renderQuadTree(flock.boidsQuadTree);
        }

        for boid : flock.boids {
            renderBoid(boid);
        }

        #if (RENDER_PERCEPTION) {
            firstBoid := get(flock.boids, 0);
            renderBoidPerception(firstBoid);
        }

        rl.DrawFPS(10, 10);
    rl.EndDrawing();
}

renderQuadTree :: (tree: *QuadTree) {
    boundary := rlRectangleFromRect(tree.boundary);
    rl.DrawRectangleLinesEx(boundary, 1, rl.ColorCreate(120, 120, 120, 255));

    if (tree.children != null) {
        for i : 0..3 {
            renderQuadTree(*tree.children[i]);
        }
    }
}

initBoid :: (boid: *Boid, position: Vec2, velocity: Vec2) {
    boidStaticId += 1;

    boid.id = boidStaticId;
    boid.position = position;
    boid.velocity = velocity;
    boid.color = fromColorList(boid.id);
    #if (RENDER_TRAILS) {
        boid.trail = createList(Vec2, ListOptions(Vec2).{
            capacity = BOID_TRAIL_LENGTH
        });
    }
}

updateBoid :: (boid: *Boid) {
    otherBoids := getOtherBoids(boid);
    defer uninit(*otherBoids);

    boid.velocity += getBoundsSteering(boid);
    boid.velocity += getFlockSteering(boid, otherBoids);
    boid.velocity = clampLength(boid.velocity, BOID_MAX_SPEED);
    boid.position += boid.velocity;
    boid.position = getBoundsCheck(boid);

    #if (RENDER_TRAILS) {
        if (boid.trail.count >= BOID_TRAIL_LENGTH) {
            removeAt(*boid.trail, 0);
        }
        add(*boid.trail, boid.position);
    }
}

renderBoid :: (boid: *Boid) {
    renderBoidBody(boid);

    #if (RENDER_TRAILS) {
        renderBoidTrail(boid);
    }
}

renderBoidBody :: (boid: *Boid) {
    points: [4] rl.Vector2;
    points[0] = rl.Vector2Create(0, 0);
    points[1] = rl.Vector2Create(-BOID_WIDTH/2, BOID_HEIGHT);
    points[2] = rl.Vector2Create(0, 2*BOID_HEIGHT/3);
    points[3] = rl.Vector2Create(BOID_WIDTH/2, BOID_HEIGHT);

    angle := angleClockwise(VEC2_UP, boid.velocity);
    for i : 0..points.count-1 {
        points[i] = rl.Vector2Add(points[i], rl.Vector2Create(0, -2*BOID_HEIGHT/3));
        points[i] = rl.Vector2Rotate(points[i], angle * rl.RAD2DEG);
        points[i] = rl.Vector2Add(points[i], rl.Vector2Create(0, 2*BOID_HEIGHT/3));
        points[i] = rl.Vector2Add(points[i], rlVector2FromVec2(boid.position));
    }

    rl.DrawTriangle(points[0], points[1], points[2], rlColorFromColor(boid.color));
    rl.DrawTriangle(points[0], points[2], points[3], rlColorFromColor(boid.color));
}

#if (RENDER_TRAILS) {
    renderBoidTrail :: (boid: *Boid) {
        if (boid.trail.count < 2) {
            return;
        }

        color := rlColorFromColor(boid.color);

        prev := rlVector2FromVec2(boid.trail[0]);
        prev.y += 2*BOID_HEIGHT/3;

        for i : 1..boid.trail.count-1 {
            curr := rlVector2FromVec2(boid.trail[i]);
            curr.y += 2*BOID_HEIGHT/3;

            if (rl.Vector2Distance(curr, prev) < 10) {
                rl.DrawLineV(prev, curr, color);
            }

            prev = curr;
        }
    }
}

#if (RENDER_PERCEPTION) {
    renderBoidPerception :: (boid: *Boid) {
        center := rl.Vector2Create(0, 2*BOID_HEIGHT/3);
        center = rl.Vector2Add(center, rlVector2FromVec2(boid.position));

        rl.DrawCircle(cast(s32) center.x, cast(s32) center.y, BOID_PERCEPTION, rl.ColorCreate(100, 100, 100, 100));
        rl.DrawCircleLines(cast(s32) center.x, cast(s32) center.y, BOID_PERCEPTION, rl.ColorCreate(255, 255, 255, 255));
    }
}

getOtherBoids :: (boid: *Boid) -> List(*Boid) {
    flock := context.flock;

    otherBoids := createList(*Boid);

    range := rect(
        boid.position.x - BOID_PERCEPTION * 0.5,
        boid.position.y - BOID_PERCEPTION * 0.5,
        BOID_PERCEPTION,
        BOID_PERCEPTION
    );
    entries := createList(QuadTreeEntry);
    defer uninit(*entries);

    query(flock.boidsQuadTree, range, *entries);
    for entry : entries {
        other := cast(*Boid) entry.userData;
        if (other != boid) {
            add(*otherBoids, other);
        }
    }
    return otherBoids;
}

getBoundsSteering :: (boid: *Boid) -> Vec2 {
    screenWidth := cast(float32) rl.GetScreenWidth();
    screenHeight := cast(float32) rl.GetScreenHeight();

    steering := vec2(0, 0);

    if (boid.position.x < BOUNDS_MARGIN) {
        steering.x = BOUNDS_STEERING_FACTOR;
    } else if (boid.position.x > screenWidth - BOUNDS_MARGIN) {
        steering.x = -BOUNDS_STEERING_FACTOR;
    }

    if (boid.position.y < BOUNDS_MARGIN) {
        steering.y = BOUNDS_STEERING_FACTOR;
    } else if (boid.position.y > screenHeight - BOUNDS_MARGIN) {
        steering.y = -BOUNDS_STEERING_FACTOR;
    }

    return steering;
}

getBoundsCheck :: (boid: *Boid) -> Vec2 {
    screenWidth := cast(float32) rl.GetScreenWidth();
    screenHeight := cast(float32) rl.GetScreenHeight();

    result := boid.position;

    if (result.x < 0) {
        result.x = screenWidth;
    } else if (result.x >= screenWidth) {
        result.x = 0;
    }

    if (result.y < 0) {
        result.y = screenHeight;
    } else if (result.y >= screenHeight) {
        result.y = 0;
    }

    return result;
}

getFlockSteering :: (boid: *Boid, otherBoids: List(*Boid)) -> Vec2 {
    flock := context.flock;

    alignment := vec2(0, 0);
    separation := vec2(0, 0);
    cohesion := vec2(0, 0);

    total: s32 = 0;

    for other : otherBoids {
        alignment += other.velocity;

        diff := boid.position - other.position;
        dist := length(diff);
        if (dist <= SEPARATION_DISTANCE) {
            separation += (diff / dist);
        }

        cohesion += other.position;

        total += 1;
    }

    if (total > 0) {
        alignment /= total;
        alignment = setLength(alignment, BOID_MAX_SPEED);
        alignment -= boid.velocity;
        alignment = clampLength(alignment, ALIGNMENT_FACTOR);

        separation /= total;
        separation = setLength(separation, BOID_MAX_SPEED);
        separation -= boid.velocity;
        separation = clampLength(separation, SEPARATION_FACTOR);

        cohesion /= total;
        cohesion -= boid.position;
        cohesion = setLength(cohesion, BOID_MAX_SPEED);
        cohesion -= boid.velocity;
        cohesion = clampLength(cohesion, COHESION_FACTOR);
    }

    return alignment + separation + cohesion;
}

#scope_file

boidStaticId : s32 = 0;

rlColorFromColor :: inline (color: Color) -> rl.Color {
    return rl.ColorCreate(color.r, color.g, color.b, color.a);
}

rlRectangleFromRect :: inline (rect: Rect) -> rl.Rectangle {
    return rl.RectangleCreate(rect.x, rect.y, rect.w, rect.h);
}

rlVector2FromVec2 :: inline (v: Vec2) -> rl.Vector2 {
    return rl.Vector2Create(v.x, v.y);
}
