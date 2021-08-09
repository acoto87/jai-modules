#import "utils";
#import "strings";
#import "flecs-jai";

/* Component type */
Message :: struct {
    text: *u8;
}

/* Must have the same name as the ECS_SYSTEM definition */
PrintMessage :: (it: *ecs_iter_t) #c_call {
    newContext: Context;
    push_context newContext {
        /* Get a pointer to the array of the first column in the system. The order
        * of columns is the same as the one provided in the system signature. */
        msg := ecs_term(it, Message, 1);

        /* Iterate all the messages */
        for i : 0..it.count-1 {
            print("%\n", toString(msg[i].text));
        }
    }
}

main :: () {
    /* Create the world, pass arguments for overriding the number of threads,fps
     * or for starting the admin dashboard (see flecs.h for details). */
    args := getCommandLineArguments();
    world := ecs_init_w_args(args);

    /* Define component */
    componentId := ecs_component(world, Message);

    /* Define a system called PrintMessage that is executed every frame, and
     * subscribes for the 'Message' component */
    systemId := ecs_system(world, "PrintMessage", PrintMessage, EcsOnUpdate, "Message");

    /* Create new entity, add the component to the entity */
    e := ecs_new_w_id(world, componentId);

    message := Message.{ text = "Hello Flecs!" };
    ecs_set(world, e, componentId, *message);

    /* Set target FPS for main loop to 1 frame per second */
    ecs_set_target_fps(world, 1);

    print("Application simple_system is running, press CTRL-C to exit...\n");

    /* Run systems */
    while (ecs_progress(world, 0)) {}

    /* Cleanup */
    ecs_fini(world);
}
