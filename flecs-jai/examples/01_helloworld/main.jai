#import "utils";
#import "strings";
#import "flecs-jai";

Position :: struct {
    x, y: float32;
}

main :: () {
    /* Create the world, pass arguments for overriding the number of threads,fps
     * or for starting the admin dashboard (see flecs.h for details). */
    args := getCommandLineArguments();
    world := ecs_init_w_args(args);

    /* Register a component with the world. */
    componentId := ecs_component(world, Position);

    /* Create a new empty entity  */
    entityId := ecs_entity(world, "MyEntity", null);

    /* Set the Position component on the entity */
    position := Position.{10, 20};
    ecs_set(world, entityId, componentId, *position);

    /* Get the Position component */
    p := ecs_get(world, entityId, componentId, Position);
    print("Position of % is {%, %}\n", toString(ecs_get_name(world, entityId)), p.x, p.y);

    /* Cleanup */
    ecs_fini(world);
}
