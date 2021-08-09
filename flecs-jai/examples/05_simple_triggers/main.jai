#import "utils";
#import "strings";
#import "flecs-jai";

Position :: struct {
    x, y: float64;
}

/* This system will be called when Position is added */
AddPosition :: (it: *ecs_iter_t) #c_call {
    newContext: Context;
    push_context newContext {
        p := ecs_term(it, Position, 1);

        for i : 0..it.count-1 {
            p[i].x = 10;
            p[i].y = 20;
            print("Position added\n");
        }
    }
}

/* This system will be called when Position is removed */
RemovePosition :: (it: *ecs_iter_t) #c_call {
    newContext: Context;
    push_context newContext {
        p := ecs_term(it, Position, 1);

        for i : 0..it.count-1 {
            print("Position removed -> {%, %}\n", p[i].x, p[i].y);
        }
    }
}

main :: () {
    /* Create the world, pass arguments for overriding the number of threads,fps
     * or for starting the admin dashboard (see flecs.h for details). */
    args := getCommandLineArguments();
    world := ecs_init_w_args(args);

    /* Register Position component */
    componentId := ecs_component(world, Position);

    /* Register two systems that are executed when Position is added or removed
     * to entities. */
    ecs_trigger(world, "AddPosition", AddPosition, EcsOnAdd, "Position");
    ecs_trigger(world, "RemovePosition", RemovePosition, EcsOnRemove, "Position");

    /* Create new entity with Position. This triggers the OnAdd system. */
    e := ecs_new_w_id(world, componentId);

    /* Remove Position. This will trigger the OnRemove system. */
    // ecs_remove(world, e, Position);
    ecs_remove_id(world, e, componentId);

    /* Add Position again. This will retrigger the OnAdd system */
    // ecs_add(world, e, Position);
    ecs_add_id(world, e, componentId);

    /* Add Position again. This does not retrigger the OnAdd system since the
     * entity already has Position */
    // ecs_add(world, e, Position);
    ecs_add_id(world, e, componentId);

    /* Cleanup: will invoke OnRemove system */
    ecs_fini(world);
}
