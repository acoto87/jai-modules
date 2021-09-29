#import "math-jai";
#import "collections";
#import "strings";
#import "utils";

#import "flecs-jai";
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

PositionComponent :: struct {
    position: Vec2;
}

VelocityComponent :: struct {
    velocity: Vec2;
}

ColorComponent :: struct {
    color: Color;
}

TrailComponent :: struct {
    positions: List(Vec2);
}

// https://medium.com/osedea/boids-e98093b3b4fe
// https://zacktherrien.github.io/boids/

Flock :: struct {
    world: *ecs_world_t;
    positionId: ecs_entity_t;
    velocityId: ecs_entity_t;
    colorId: ecs_entity_t;
    trailId: ecs_entity_t;
    updateQuadTreeSystemId: ecs_entity_t;
    updateBoidsSystemId: ecs_entity_t;
    #if (RENDER_TRAILS) {
        updateTrailsSystemId: ecs_entity_t;
    }
    renderQuadTreeSystemId: ecs_entity_t;
    renderBoidsSystemId: ecs_entity_t;
    #if (RENDER_TRAILS) {
        renderTrailsSystemId: ecs_entity_t;
    }
    boidsQuadTree: *QuadTree;
}

Boid :: struct {
    id: ecs_entity_t;
    position: Vec2;
    velocity: Vec2;
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

    screenWidth := cast(float32) rl.GetScreenWidth();
    screenHeight := cast(float32) rl.GetScreenHeight();

    world := ecs_init();

    positionId := ecs_component(world, PositionComponent);
    velocityId := ecs_component(world, VelocityComponent);
    colorId := ecs_component(world, ColorComponent);

    #if (RENDER_TRAILS) {
        trailId := ecs_component(world, TrailComponent);
    }

    for i : 0..numberOfBoids-1 {
        entity := ecs_entity(world, null, "PositionComponent, VelocityComponent, ColorComponent");

        position := vec2(
            randomNext(0, screenWidth),
            randomNext(0, screenHeight)
        );
        positionComponent: PositionComponent;
        positionComponent.position = position;
        ecs_set(world, entity, positionId, *positionComponent);

        velocity := vec2Random() * randomNext(BOID_MAX_SPEED/2, BOID_MAX_SPEED);
        velocityComponent: VelocityComponent;
        velocityComponent.velocity = velocity;
        ecs_set(world, entity, velocityId, *velocityComponent);

        color := fromColorList(cast(s64) entity);
        colorComponent: ColorComponent;
        colorComponent.color = color;
        ecs_set(world, entity, colorId, *colorComponent);

        #if (RENDER_TRAILS) {
            trailComponent: TrailComponent;
            trailComponent.positions = createList(Vec2, ListOptions(Vec2).{
                capacity = BOID_TRAIL_LENGTH
            });
            ecs_set(world, entity, trailId, *trailComponent);
        }
    }

    updateQuadTreeSystemId := ecs_system(world, "UpdateQuadTree", updateQuadTree, 0, "PositionComponent, VelocityComponent");
    updateBoidsSystemId := ecs_system(world, "UpdateBoids", updateBoids, 0, "PositionComponent, VelocityComponent");
    #if (RENDER_TRAILS) {
        updateTrailsSystemId := ecs_system(world, "UpdateTrails", updateTrails, 0, "PositionComponent, TrailComponent");
    }
    renderQuadTreeSystemId := ecs_system(world, "RenderQuadTree", renderQuadTree, 0, null);
    renderBoidsSystemId := ecs_system(world, "RenderBoids", renderBoids, 0, "PositionComponent, VelocityComponent, ColorComponent", colorId);
    #if (RENDER_TRAILS) {
        renderTrailsSystemId := ecs_system(world, "RenderTrails", renderTrails, 0, "TrailComponent, ColorComponent");
    }

    flock.world = world;
    flock.positionId = positionId;
    flock.velocityId = velocityId;
    flock.colorId = colorId;
    flock.updateQuadTreeSystemId = updateQuadTreeSystemId;
    flock.updateBoidsSystemId = updateBoidsSystemId;
    flock.renderQuadTreeSystemId = renderQuadTreeSystemId;
    flock.renderBoidsSystemId = renderBoidsSystemId;

    #if (RENDER_TRAILS) {
        flock.trailId = trailId;
        flock.updateTrailsSystemId = updateTrailsSystemId;
        flock.renderTrailsSystemId = renderTrailsSystemId;
    }
}

updateGame :: () {
    flock := context.flock;

    ecs_run(flock.world, flock.updateQuadTreeSystemId, 0, flock);
    ecs_run(flock.world, flock.updateBoidsSystemId, 0, flock);
    #if (RENDER_TRAILS) {
        ecs_run(flock.world, flock.updateTrailsSystemId, 0, flock);
    }
}

updateQuadTree :: (it: *ecs_iter_t) #c_call {
    screenWidth := cast(float32) rl.GetScreenWidth();
    screenHeight := cast(float32) rl.GetScreenHeight();

    newContext: Context;
    push_context newContext {
        flock := cast(*Flock) it.param;

        boundary := rect(
            0, 0,
            screenWidth,
            screenHeight
        );

        if (flock.boidsQuadTree != null) {
            uninit(flock.boidsQuadTree, true, true);
        }
        flock.boidsQuadTree = alloc(QuadTree);
        init(flock.boidsQuadTree, boundary, 1);

        positionComponents := ecs_term(it, PositionComponent, 1);
        velocityComponents := ecs_term(it, VelocityComponent, 2);

        for i : 0..it.count-1 {
            boid := alloc(Boid);
            boid.id = it.entities[i];
            boid.position = positionComponents[i].position;
            boid.velocity = velocityComponents[i].velocity;

            insert(flock.boidsQuadTree, boid.position, boid);
        }
    }
}

updateBoids :: (it: *ecs_iter_t) #c_call {
    newContext: Context;
    push_context newContext {
        flock := cast(*Flock) it.param;

        positionComponents := ecs_term(it, PositionComponent, 1);
        velocityComponents := ecs_term(it, VelocityComponent, 2);

        for i : 0..it.count-1 {
            boid: Boid;
            boid.id = it.entities[i];
            boid.position = positionComponents[i].position;
            boid.velocity = velocityComponents[i].velocity;

            otherBoids := getOtherBoids(flock, boid);
            defer uninit(*otherBoids);

            boid.velocity += getBoundsSteering(boid);
            boid.velocity += getFlockSteering(boid, otherBoids);
            boid.velocity = clampLength(boid.velocity, BOID_MAX_SPEED);
            boid.position += boid.velocity;
            boid.position = getBoundsCheck(boid.position);

            positionComponents[i].position = boid.position;
            velocityComponents[i].velocity = boid.velocity;
        }
    }
}

#if (RENDER_TRAILS) {
    updateTrails :: (it: *ecs_iter_t) #c_call {
        newContext: Context;
        push_context newContext {
            flock := cast(*Flock) it.param;

            positionComponents := ecs_term(it, PositionComponent, 1);
            trailComponents := ecs_term(it, TrailComponent, 2);

            for i : 0..it.count-1 {
                position := positionComponents[i].position;
                trail := *trailComponents[i].positions;

                if (trail.count >= BOID_TRAIL_LENGTH) {
                    removeAt(trail, 0);
                }
                add(trail, position);
            }
        }
    }
}

renderGame :: () {
    flock := context.flock;

    rl.BeginDrawing();
        rl.ClearBackground(rl.BLACK);

        #if (RENDER_QUADTREE) {
            ecs_run(flock.world, flock.renderQuadTreeSystemId, 0, flock);
        }

        ecs_run(flock.world, flock.renderBoidsSystemId, 0, flock);

        #if (RENDER_TRAILS) {
            ecs_run(flock.world, flock.renderTrailsSystemId, 0, flock);
        }

        rl.DrawFPS(10, 10);
    rl.EndDrawing();
}

renderBoids :: (it: *ecs_iter_t) #c_call {
    newContext: Context;
    push_context newContext {
        flock := cast(*Flock) it.param;

        positionComponents := ecs_term(it, PositionComponent, 1);
        velocityComponents := ecs_term(it, VelocityComponent, 2);
        colorComponents := ecs_term(it, ColorComponent, 3);

        for i : 0..it.count-1 {
            position := positionComponents[i].position;
            velocity := velocityComponents[i].velocity;
            color := colorComponents[i].color;

            renderBoid(position, velocity, color);
        }

        #if (RENDER_PERCEPTION) {
            renderBoidPerception(positionComponents[0].position);
        }
    }
}

renderQuadTree :: (it: *ecs_iter_t) #c_call {
    newContext: Context;
    push_context newContext {
        flock := cast(*Flock) it.param;
        renderQuadTreeNode(flock.boidsQuadTree);
    }
}

renderQuadTreeNode :: (tree: *QuadTree) {
    boundary := rlRectangleFromRect(tree.boundary);
    rl.DrawRectangleLinesEx(boundary, 1, rl.ColorCreate(120, 120, 120, 255));

    if (tree.children != null) {
        for i : 0..3 {
            renderQuadTreeNode(*tree.children[i]);
        }
    }
}

renderBoid :: (position: Vec2, velocity: Vec2, color: Color) {
    points: [4] rl.Vector2;
    points[0] = rl.Vector2Create(0, 0);
    points[1] = rl.Vector2Create(-BOID_WIDTH/2, BOID_HEIGHT);
    points[2] = rl.Vector2Create(0, 2*BOID_HEIGHT/3);
    points[3] = rl.Vector2Create(BOID_WIDTH/2, BOID_HEIGHT);

    angle := angleClockwise(VEC2_UP, velocity);
    for i : 0..points.count-1 {
        points[i] = rl.Vector2Add(points[i], rl.Vector2Create(0, -2*BOID_HEIGHT/3));
        points[i] = rl.Vector2Rotate(points[i], angle * rl.RAD2DEG);
        points[i] = rl.Vector2Add(points[i], rl.Vector2Create(0, 2*BOID_HEIGHT/3));
        points[i] = rl.Vector2Add(points[i], rlVector2FromVec2(position));
    }

    rl.DrawTriangle(points[0], points[1], points[2], rlColorFromColor(color));
    rl.DrawTriangle(points[0], points[2], points[3], rlColorFromColor(color));
}

renderBoidPerception :: (position: Vec2) {
    center := rl.Vector2Create(0, 2*BOID_HEIGHT/3);
    center = rl.Vector2Add(center, rlVector2FromVec2(position));

    rl.DrawCircle(cast(s32) center.x, cast(s32) center.y, BOID_PERCEPTION, rl.ColorCreate(100, 100, 100, 100));
    rl.DrawCircleLines(cast(s32) center.x, cast(s32) center.y, BOID_PERCEPTION, rl.ColorCreate(255, 255, 255, 255));
}

#if (RENDER_TRAILS) {
    renderTrails :: (it: *ecs_iter_t) #c_call {
        newContext: Context;
        push_context newContext {
            flock := cast(*Flock) it.param;

            trailComponents := ecs_term(it, TrailComponent, 1);
            colorComponents := ecs_term(it, ColorComponent, 2);

            for i : 0..it.count-1 {
                renderBoidTrail(trailComponents[i].positions, colorComponents[i].color);
            }
        }
    }

    renderBoidTrail :: (trail: List(Vec2), color: Color) {
        if (trail.count < 2) {
            return;
        }

        rlcolor := rlColorFromColor(color);

        prev := rlVector2FromVec2(trail[0]);
        prev.y += 2*BOID_HEIGHT/3;

        for i : 1..trail.count-1 {
            curr := rlVector2FromVec2(trail[i]);
            curr.y += 2*BOID_HEIGHT/3;

            if (rl.Vector2Distance(curr, prev) < 10) {
                rl.DrawLineV(prev, curr, rlcolor);
            }

            prev = curr;
        }
    }
}

#scope_file

getOtherBoids :: (flock: *Flock, boid: Boid) -> List(Boid) {
    otherBoids := createList(Boid);

    entries := createList(QuadTreeEntry);
    defer uninit(*entries);

    range := rect(
        boid.position.x - BOID_PERCEPTION * 0.5,
        boid.position.y - BOID_PERCEPTION * 0.5,
        BOID_PERCEPTION,
        BOID_PERCEPTION
    );
    query(flock.boidsQuadTree, range, *entries);
    for entry : entries {
        other := cast(*Boid) entry.userData;
        if (other.id != boid.id) {
            add(*otherBoids, <<other);
        }
    }
    return otherBoids;
}

getBoundsSteering :: (boid: Boid) -> Vec2 {
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

getBoundsCheck :: (position: Vec2) -> Vec2 {
    result := position;

    screenWidth := cast(float32) rl.GetScreenWidth();
    screenHeight := cast(float32) rl.GetScreenHeight();

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

getFlockSteering :: (boid: Boid, otherBoids: List(Boid)) -> Vec2 {
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

// Compiler :: #import "Compiler";
// setTypeInfoFlags :: Compiler.compiler_set_type_info_flags;

// #run setTypeInfoFlags(GL_Procedures, .PROCEDURES_ARE_VOID_POINTERS);
// #run setTypeInfoFlags(GL_Procedures, .NO_SIZE_COMPLAINT);

rlColorFromColor :: inline (color: Color) -> rl.Color {
    return rl.ColorCreate(color.r, color.g, color.b, color.a);
}

rlRectangleFromRect :: inline (rect: Rect) -> rl.Rectangle {
    return rl.RectangleCreate(rect.x, rect.y, rect.w, rect.h);
}

rlVector2FromVec2 :: inline (v: Vec2) -> rl.Vector2 {
    return rl.Vector2Create(v.x, v.y);
}

