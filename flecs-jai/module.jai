#load "flecs.jai";

ecs_init_w_args :: (args: [] string) -> *ecs_world_t {
    argv := allocArray(*u8, args.count);
    for arg, i : args {
        argv[i] = toCString(arg);
    }
    defer {
        for arg : argv {
            free(arg);
        }
        free(argv);
    }
    return ecs_init_w_args(cast(s32) args.count, argv);
}

/* Declare a component.
 * Example:
 *   ecs_component(world, Position);
 */
ecs_component :: (world: *ecs_world_t, $T: Type) -> ecs_entity_t {
    #assert(isStruct(T));
    typeName: *u8 = #run getStructName(T);

    entity_desc: ecs_entity_desc_t;
    entity_desc.name = typeName;
    entity_desc.symbol = typeName;

    component_desc: ecs_component_desc_t;
    component_desc.entity = entity_desc;
    component_desc.size = cast(u32) size_of(T);
    component_desc.alignment = cast(u32) align_of(T);

    return ecs_component_init(world, *component_desc);
}

/* Declare an entity.
 * Example:
 *   ecs_entity(world, "MyEntity", "Position, Velocity");
 */
ecs_entity :: (world: *ecs_world_t, id: *u8, add_expr: *u8 = null) -> ecs_entity_t {
    entity_desc: ecs_entity_desc_t;
    entity_desc.name = id;
    entity_desc.add_expr = add_expr;

    return ecs_entity_init(world, *entity_desc);
}

/* Declare a system.
 * Example:
 *   ecs_system(world, Move, EcsOnUpdate, "Position, Velocity");
 */
ecs_system :: (
    world: *ecs_world_t,
    name: *u8,
    callback: ecs_iter_action_t,
    kind: ecs_id_t = 0,
    filter_expr: *u8 = null,
    order_by_id: ecs_id_t = 0,
    order_by: ecs_compare_action_t = null,
    group_by_id: ecs_id_t = 0,
    group_by: ecs_rank_type_action_t = null) -> ecs_entity_t
{
    ecs_assert(callback != null, ECS_INVALID_PARAMETER, null);

    entity_desc: ecs_entity_desc_t;
    entity_desc.name = name;
    entity_desc.add_ids[0] = kind;

    filter_desc: ecs_filter_desc_t;
    filter_desc.expr = filter_expr;

    query_desc: ecs_query_desc_t;
    query_desc.filter = filter_desc;
    query_desc.order_by_id = order_by_id;
    query_desc.order_by = order_by;
    query_desc.group_by_id = group_by_id;
    query_desc.group_by = group_by;

    system_desc: ecs_system_desc_t;
    system_desc.entity = entity_desc;
    system_desc.query = query_desc;
    system_desc.callback = callback;

    return ecs_system_init(world, *system_desc);
}

/* Declare a trigger.
 * Example:
 *   ecs_trigger(world, AddPosition, EcsOnAdd, Position);
 */
ecs_trigger :: (
    world: *ecs_world_t,
    name: *u8,
    callback: ecs_iter_action_t,
    kind: ecs_id_t = 0,
    trigger_expr: *u8 = null) -> ecs_entity_t
{
    ecs_assert(callback != null, ECS_INVALID_PARAMETER, null);

    entity_desc: ecs_entity_desc_t;
    entity_desc.name = name;

    trigger_desc: ecs_trigger_desc_t;
    trigger_desc.entity = entity_desc;
    trigger_desc.callback = callback;
    trigger_desc.expr = trigger_expr;
    trigger_desc.events[0] = kind;

    return ecs_trigger_init(world, *trigger_desc);
}

/* Declare a trigger.
 * Example:
 *   ecs_query(world, AddPosition, EcsOnAdd, Position);
 */
ecs_query :: (
    world: *ecs_world_t,
    filter_expr: *u8,
    order_by_id: ecs_id_t = 0,
    order_by: ecs_compare_action_t = null,
    group_by_id: ecs_id_t = 0,
    group_by: ecs_rank_type_action_t = null) -> *ecs_query_t
{
    filter_desc: ecs_filter_desc_t;
    filter_desc.expr = filter_expr;

    query_desc: ecs_query_desc_t;
    query_desc.filter = filter_desc;
    query_desc.order_by_id = order_by_id;
    query_desc.order_by = order_by;
    query_desc.group_by_id = group_by_id;
    query_desc.group_by = group_by;

    return ecs_query_init(world, *query_desc);
}

/* Get an immutable pointer to a component.
 * Same as ecs_get_id, but accepts the typename of a component.
 *
 * @param world The world.
 * @param entity The entity.
 * @param id The component to obtain.
 * @return The component pointer, NULL if the entity does not have the component.
 */
ecs_get :: inline (world: *ecs_world_t, entity: ecs_entity_t, component: ecs_entity_t, $T: Type) -> *T {
    return cast(*T) ecs_get_id(world, entity, component);
}

/* Set the value of a component.
 * Same as ecs_set_ptr, but accepts a value instead of a pointer to a value.
 *
 * @param world The world.
 * @param entity The entity.
 * @param component The component to set.
 * @param size The size of the pointer to the value.
 * @return The entity. A new entity if no entity was provided.
 */
ecs_set :: inline (world: *ecs_world_t, entity: ecs_entity_t, component: ecs_entity_t, ptr: *$T) -> ecs_entity_t {
    return ecs_set_id(world, entity, component, size_of(T), ptr);
}

/* Same as ecs_term_w_size, but accepts a type instead of a size. */
ecs_term :: inline (it: *ecs_iter_t, $T: Type, index: int32_t) -> *T {
    #assert(isStruct(T));
    return cast(*T) ecs_term_w_size(it, cast(size_t) size_of(T), index);
}

#scope_file

#import "utils";