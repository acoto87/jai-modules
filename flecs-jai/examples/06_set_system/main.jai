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

/* This system will be called when Position is set */
SetPosition :: (it: *ecs_iter_t) #c_call {
    newContext: Context;
    push_context newContext {
        p := ecs_term(it, Position, 1);

        for i : 0..it.count-1 {
            print("Position set -> {%, %}\n", p[i].x, p[i].y);
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

    /* Register system that is invoked when Position is added */
    systemAddId := ecs_system(world, "AddPosition", AddPosition, EcsOnAdd, "Position");

    /* Register system that is invoked when a value is assigned to Position.
     * There are different conditions under which an OnSet system is triggerd.
     * This example demonstrates how OnSet is called after an OnAdd system, and
     * after calling ecs_set. */
    systemSetId := ecs_system(world, "SetPosition", SetPosition, EcsOnSet, "Position");

    /* Create new entity with Position. Because we have an OnAdd system, flecs
     * assumes a valid value will be assigned to Position, and therefore the
     * OnSet system is invoked directly after the OnAdd system. */
    e := ecs_new_w_id(world, componentId);

    /* Set Position to a new value (invokes OnSet system) */
    position1 := Position.{20, 30};
    ecs_set(world, e, componentId, *position1);

    /* Set Position to a new value again (invokes OnSet system) */
    position2 := Position.{30, 40};
    ecs_set(world, e, componentId, *position2);

    /* Cleanup: will invoke OnRemove system */
    ecs_fini(world);
}
