#import "utils";
#import "strings";
#import "flecs-jai";

/* Component types */
Position :: struct {
    x, y: float64;
}

Velocity :: struct {
    x, y: float64;
}

/* Implement a simple move system */
Move :: (it: *ecs_iter_t) #c_call {
    newContext: Context;
    push_context newContext {
        /* Get the two columns from the system signature */
        p := ecs_term(it, Position, 1);
        v := ecs_term(it, Velocity, 2);

        for i : 0..it.count-1 {
            p[i].x += v[i].x;
            p[i].y += v[i].y;

            /* Print something to the console so we can see the system is being
            * invoked */
            print("% moved to {.x = %, .y = %}\n",
                toString(ecs_get_name(it.world, it.entities[i])),
                p[i].x, p[i].y);
        }
    }
}

main :: () {
    /* Create the world, pass arguments for overriding the number of threads,fps
     * or for starting the admin dashboard (see flecs.h for details). */
    args := getCommandLineArguments();
    world := ecs_init_w_args(args);

    /* Register components */
    positionId := ecs_component(world, Position);
    velocityId := ecs_component(world, Velocity);

    /* Define a system called Move that is executed every frame, and subscribes
     * for the 'Position' and 'Velocity' components */
    systemId := ecs_system(world, "Move", Move, EcsOnUpdate, "Position, Velocity");

    /* Create an entity with Position and Velocity. Creating an entity with the
     * ECS_ENTITY macro is an easy way to create entities with multiple
     * components. Additionally, entities created with this macro can be looked
     * up by their name ('MyEntity'). */
    entityId := ecs_entity(world, "MyEntity", "Position, Velocity");

    /* Initialize values for the entity */
    position := Position.{0, 0};
    ecs_set(world, entityId, positionId, *position);
    velocity := Velocity.{1, 1};
    ecs_set(world, entityId, velocityId, *velocity);

    /* Set target FPS for main loop to 1 frame per second */
    ecs_set_target_fps(world, 1);

    print("Application move_system is running, press CTRL-C to exit...\n");

    /* Run systems */
    while (ecs_progress(world, 0)) {}

    /* Cleanup */
    ecs_fini(world);
}
