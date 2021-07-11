#import "flecs-jai";
#import "Basic";

Position :: struct {
    x, y: float32;
}

main :: () {
    /* Create the world, pass arguments for overriding the number of threads,fps
     * or for starting the admin dashboard (see flecs.h for details). */
    args := get_command_line_arguments();
    world: *ecs_world_t = ecs_init_w_args(args);

    /* Register a component with the world. */
    ECS_COMPONENT(world, Position);

    /* Create a new empty entity  */
    ECS_ENTITY(world, MyEntity, 0);

    /* Set the Position component on the entity */
    ecs_set(world, MyEntity, Position, .{10, 20});

    /* Get the Position component */
    p: *Position = ecs_get(world, MyEntity, Position);

    print("Position of % is {%, %}\n",
        ecs_get_name(world, MyEntity), p.x, p.y);

    /* Cleanup */
    ecs_fini(world);
}
