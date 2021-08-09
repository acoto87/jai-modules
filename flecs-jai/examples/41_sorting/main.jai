#import "utils";
#import "strings";
#import "flecs-jai";

Position :: struct {
    x, y: float64;
}

/* Order by x member of Position */
comparePosition :: (
    e1: ecs_entity_t,
    ptr1: *void,
    e2: ecs_entity_t,
    ptr2: *void) -> s32 #c_call
{
    p1 := cast(*Position) ptr1;
    p2 := cast(*Position) ptr2;
    if p1.x < p2.x then return -1;
    if p1.x > p2.x then return 1;
    return 0;
}

/* Iterate iterator, printed values will be ordered */
print_iter :: (it: *ecs_iter_t) {
    p := ecs_term(it, Position, 1);

    for i : 0..it.count-1 {
        print("{%, %}\n", p[i].x, p[i].y);
    }
}

/* Iterate query */
print_query :: (q: *ecs_query_t) {
    it := ecs_query_iter(q);
    while (ecs_query_next(*it)) {
        print_iter(*it);
    }
}

/* Iterate system */
PrintSystem :: (it: *ecs_iter_t) #c_call {
    newContext: Context;
    push_context newContext {
        print_iter(it);
    }
}

main :: () {
    world := ecs_init();

    componentId := ecs_component(world, Position);

    /* Create entities, set Position in random order */
    e := ecs_set(world, 0, componentId, *Position.{3, 0});
    ecs_set(world, 0, componentId, *Position.{1, 0});
    ecs_set(world, 0, componentId, *Position.{6, 0});
    ecs_set(world, 0, componentId, *Position.{2, 0});
    ecs_set(world, 0, componentId, *Position.{5, 0});
    ecs_set(world, 0, componentId, *Position.{4, 0});

    /* Create system. To enable sorting for a system, we need to access its
     * underlying query object */
    systemId := ecs_system(world, "PrintSystem", PrintSystem, 0, "Position", componentId, comparePosition);
    // q_system := ecs_get_system_query(world, systemId);

    // /* We can now invoke the order_by operation on the query */
    // ecs_query_order_by(world, q_system, ecs_typeid(Position), comparePosition);

    /* Create a query for component Position */
    q := ecs_query(world, "Position", componentId, comparePosition);

    // /* Order by Position component */
    // ecs_query_order_by(world, q, ecs_typeid(Position), comparePosition);

    /* Iterate query, print values of Position */
    print("-- First iteration\n");
    print_query(q);

    /* Change the value of one entity, invalidating the order */
    ecs_set(world, e, componentId, *Position.{7, 0});

    /* Iterate query again, printed values are still ordered */
    print("\n-- Second iteration\n");
    print_query(q);

    /* Create new entity to show that data is also sorted for system */
    ecs_set(world, 0, componentId, *Position.{3, 0});

    /* Run the system, output will be sorted */
    print("\n-- System iteration\n");
    ecs_run(world, systemId, 0, null);

    /* Cleanup */
    ecs_fini(world);
}
