#import "utils";
#import "strings";
#import "flecs-jai";

/* Component types */
Position :: struct {
    x, y: float64;
}

WorldPosition :: struct {
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

/* Implement a system that transforms world coordinates hierarchically. If the
 * CASCADE column is set, it points to the world coordinate of the parent. This
 * will be used to then transform Position to WorldPosition of the child.
 * If the CASCADE column is not set, the system matched a root. In that case,
 * just assign the Position to the WorldPosition. */
Transform :: (it: *ecs_iter_t) #c_call {
    newContext: Context;
    push_context newContext {
        /* Get the two columns from the system signature */
        parent_wp := ecs_term(it, WorldPosition, 1);
        wp := ecs_term(it, WorldPosition, 2);
        p := ecs_term(it, Position, 3);

        if (!parent_wp) {
            for i : 0..it.count-1 {
                wp[i].x = p[i].x;
                wp[i].y = p[i].y;

                /* Print something to the console so we can see the system is being
                * invoked */
                print("% transformed to {.x = %, .y = %} <<root>>\n",
                    toString(ecs_get_name(it.world, it.entities[i])),
                    wp[i].x, wp[i].y);
            }
        } else {
            for i : 0..it.count-1 {
                wp[i].x = parent_wp.x + p[i].x;
                wp[i].y = parent_wp.y + p[i].y;

                /* Print something to the console so we can see the system is being
                * invoked */
                print("% transformed to {.x = %, .y = %} <<child>>\n",
                    toString(ecs_get_name(it.world, it.entities[i])),
                    wp[i].x, wp[i].y);
            }
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
    worldPositionId := ecs_component(world, WorldPosition);
    velocityId := ecs_component(world, Velocity);

    /* Move entities with Position and Velocity */
    ecs_system(world, "Move", Move, EcsOnUpdate, "Position, Velocity");

    /* Transform local coordinates to world coordinates. A CASCADE column
     * guarantees that entities are evaluated breadth-first, according to the
     * hierarchy. This system will depth-sort based on parents that have the
     * WorldPosition component. */
    ecs_system(world, "Transform", Transform, EcsOnUpdate, "CASCADE:WorldPosition, WorldPosition, Position");

    /* Create root of the hierachy which moves around */
    root := ecs_entity(world, "Root", "WorldPosition, Position, Velocity");
        ecs_set(world, root, positionId, *Position.{0, 0});
        ecs_set(world, root, velocityId, *Velocity.{1, 2});

        /* Create children that don't move and are relative to the parent */
        child1 := ecs_entity(world, "Child1", "WorldPosition, Position, CHILDOF | Root");
            ecs_set(world, child1, positionId, *Position.{100, 100});

            gchild1 := ecs_entity(world, "GChild1", "WorldPosition, Position, CHILDOF | Root.Child1");
                ecs_set(world, gchild1, positionId, *Position.{1000, 1000});

        child2 := ecs_entity(world, "Child2", "WorldPosition, Position, CHILDOF | Root");
            ecs_set(world, child2, positionId, *Position.{200, 200});

            gchild2 := ecs_entity(world, "GChild2", "WorldPosition, Position, CHILDOF | Root.Child2");
                ecs_set(world, gchild2, positionId, *Position.{2000, 2000});

    /* Set target FPS for main loop to 1 frame per second */
    ecs_set_target_fps(world, 1);

    print("Application move_system is running, press CTRL-C to exit...\n");

    /* Run systems */
    while (ecs_progress(world, 0)) {
        print("----\n");
    }

    /* Cleanup */
    ecs_fini(world);
}
