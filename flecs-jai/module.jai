uintptr_t :: u64;
int8_t :: s8;
uint8_t :: u8;
int16_t :: s16;
uint16_t :: u16;
int32_t :: s32;
uint32_t :: u32;
int64_t :: s64;
uint64_t :: u64;

FLECS_FLOAT :: float32;

ecs_flags32_t :: uint32_t;
ecs_flags64_t :: uint64_t;

/* Keep unsigned integers out of the codebase as they do more harm than good */
ecs_size_t :: int32_t;

////////////////////////////////////////////////////////////////////////////////
//// Convert between C typenames and variables
////////////////////////////////////////////////////////////////////////////////

/* Translate C type to ecs_type_t variable. */
#define ecs_type(T) FLECS__T##T

/* Translate C type to id. */
#define ecs_id(T) FLECS__E##T

/* Translate C type to module struct. */
#define ecs_module(T) FLECS__M##T

/* Translate C type to module struct. */
#define ecs_module_ptr(T) FLECS__M##T##_ptr

/* Translate C type to module struct. */
#define ecs_iter_action(T) FLECS__F##T

////////////////////////////////////////////////////////////////////////////////
//// Utilities for working with pair identifiers
////////////////////////////////////////////////////////////////////////////////

ecs_entity_t_lo :: inline (value: ecs_entity_t) -> uint32_t {
    return cast(uint32_t) value;
}

ecs_entity_t_hi :: inline (value: ecs_entity_t) -> uint32_t {
    return cast(uint32_t) (value >> 32);
}

ecs_entity_t_comb :: inline (lo: ecs_entity_t, hi: ecs_entity_t ) -> uint64_t {
    return (hi << 32) + lo;
}

ecs_pair :: (pred: ecs_entity_t, obj: ecs_entity_t) {
    return ECS_PAIR | ecs_entity_t_comb(obj, pred);
}

/* Get object from pair with the correct (current) generation count */
ecs_pair_relation :: inline (world: *ecs_world_t, pair: ecs_id_t) {
    return ecs_get_alive(world, ECS_PAIR_RELATION(pair));
}
ecs_pair_object :: inline (world: *ecs_world_t, pair: ecs_id_t) {
    return ecs_get_alive(world, ECS_PAIR_OBJECT(pair));
}

/*
 * @file vector.h
 * @brief Vector datastructure.
 *
 * This is an implementation of a simple vector type. The vector is allocated in
 * a single block of memory, with the element count, and allocated number of
 * elements encoded in the block. As this vector is used for user-types it has
 * been designed to support alignments higher than 8 bytes. This makes the size
 * of the vector header variable in size. To reduce the overhead associated with
 * retrieving or computing this size, the functions are wrapped in macro calls
 * that compute the header size at compile time.
 *
 * The API provides a number of _t macro's, which accept a size and alignment.
 * These macro's are used when no compile-time type is available.
 *
 * The vector guarantees contiguous access to its elements. When an element is
 * removed from the vector, the last element is copied to the removed element.
 *
 * The API requires passing in the type of the vector. This type is used to test
 * whether the size of the provided type equals the size of the type with which
 * the vector was created. In release mode this check is not performed.
 *
 * When elements are added to the vector, it will automatically resize to the
 * next power of two. This can change the pointer of the vector, which is why
 * operations that can increase the vector size, accept a double pointer to the
 * vector.
 */

/* Public, so we can do compile-time header size calculation */
ecs_vector_t :: struct {
    count: int32_t;
    size: int32_t;
    elem_size: int64_t;
}

/*
 * @file map.h
 * @brief Map datastructure.
 *
 * Key-value datastructure. The map allows for fast retrieval of a payload for
 * a 64-bit key. While it is not as fast as the sparse set, it is better at
 * handling randomly distributed values.
 *
 * Payload is stored in bucket arrays. A bucket is computed from an id by
 * using the (bucket_count - 1) as an AND-mask. The number of buckets is always
 * a power of 2. Multiple keys will be stored in the same bucket. As a result
 * the worst case retrieval performance of the map is O(n), though this is rare.
 * On average lookup performance should equal O(1).
 *
 * The datastructure will automatically grow the number of buckets when the
 * ratio between elements and buckets exceeds a certain threshold (LOAD_FACTOR).
 *
 * Note that while the implementation is a hashmap, it can only compute hashes
 * for the provided 64 bit keys. This means that the provided keys must always
 * be unique. If the provided keys are hashes themselves, it is the
 * responsibility of the user to ensure that collisions are handled.
 *
 * In debug mode the map verifies that the type provided to the map functions
 * matches the one used at creation time.
 */

ecs_map_key_t :: uint64_t;

ecs_map_t :: struct {
    buckets: *ecs_bucket_t;
    elem_size: int32_t;
    bucket_count: int32_t;
    count: int32_t;
}

ecs_map_iter_t :: struct {
    map: *ecs_map_t;
    bucket: *ecs_bucket_t;
    bucket_index: int32_t;
    element_index: int32_t;
    payload: *void;
}

/*
 * @file strbuf.h
 * @brief Utility for constructing strings.
 *
 * A buffer builds up a list of elements which individually can be up to N bytes
 * large. While appending, data is added to these elements. More elements are
 * added on the fly when needed. When an application calls ecs_strbuf_get, all
 * elements are combined in one string and the element administration is freed.
 *
 * This approach prevents reallocs of large blocks of memory, and therefore
 * copying large blocks of memory when appending to a large buffer. A buffer
 * preallocates some memory for the element overhead so that for small strings
 * there is hardly any overhead, while for large strings the overhead is offset
 * by the reduced time spent on copying memory.
 */

ECS_STRBUF_INIT :: ecs_strbuf_t.{};
ECS_STRBUF_ELEMENT_SIZE :: 511;
ECS_STRBUF_MAX_LIST_DEPTH :: 32;

ecs_strbuf_element :: struct {
    buffer_embedded: bool;
    pos: int32_t;
    buf: *u8;
    next: *ecs_strbuf_element;
}

ecs_strbuf_element_embedded :: struct {
    super: ecs_strbuf_element;
    buf :: [ECS_STRBUF_ELEMENT_SIZE + 1] u8;
}

ecs_strbuf_element_str :: struct {
    super: ecs_strbuf_element;
    alloc_str: *u8;
}

ecs_strbuf_list_elem :: struct {
    count: int32_t;
    separator: *u8;
}

ecs_strbuf_t :: struct {
    /* When set by an application, append will write to this buffer */
    buf: *u8;

    /* The maximum number of characters that may be printed */
    max: int32_t;

    /* Size of elements minus current element */
    size: int32_t;

    /* The number of elements in use */
    elementCount: int32_t;

    /* Always allocate at least one element */
    firstElement: ecs_strbuf_element_embedded;

    /* The current element being appended to */
    current: *ecs_strbuf_element;

    /* Stack that keeps track of number of list elements, used for conditionally
     * inserting a separator */
    list_stack: [ECS_STRBUF_MAX_LIST_DEPTH] ecs_strbuf_list_elem;
    list_sp: int32_t;
}

/*
 * @file os_api.h
 * @brief Operationg system abstractions.
 *
 * This file contains the operating system abstraction API. The flecs core
 * library avoids OS/runtime specific API calls as much as possible. Instead it
 * provides an interface that can be implemented by applications.
 *
 * Examples for how to implement this interface can be found in the
 * examples/os_api folder.
 */

ecs_time_t :: struct {
    sec: uint32_t;
    nanosec: uint32_t;
}

/* Use handle types that _at least_ can store pointers */
ecs_os_thread_t :: uintptr_t;
ecs_os_cond_t :: uintptr_t;
ecs_os_mutex_t :: uintptr_t;
ecs_os_dl_t :: uintptr_t;

/* Generic function pointer type */
ecs_os_proc_t :: #type ();

/* OS API init */
ecs_os_api_init_t :: #type ();

/* OS API deinit */
ecs_os_api_fini_t :: #type ();

/* Memory management */
ecs_os_api_malloc_t :: #type (
    size: ecs_size_t) -> (void);

ecs_os_api_free_t :: #type (
    ptr: *void);

ecs_os_api_realloc_t :: #type (
    ptr: *void,
    size: ecs_size_t) -> *void;

ecs_os_api_calloc_t :: #type (
    size: ecs_size_t) -> *void;

ecs_os_api_strdup_t :: #type (
    str: *u8) -> *u8;

/* Threads */
ecs_os_thread_callback_t :: #type (
    param: *void) -> *void;

ecs_os_api_thread_new_t :: #type (
    callback: ecs_os_thread_callback_t,
    param: *void) -> ecs_os_thread_t;

ecs_os_api_thread_join_t :: #type (
    thread: ecs_os_thread_t) -> *void;

/* Atomic increment / decrement */
ecs_os_api_ainc_t :: (
    value: *int32_t) -> int32_t;


/* Mutex */
ecs_os_api_mutex_new_t :: #type () -> ecs_os_mutex_t;

ecs_os_api_mutex_lock_t :: #type (
    mutex: ecs_os_mutex_t);

ecs_os_api_mutex_unlock_t :: #type (
    mutex: ecs_os_mutex_t);

ecs_os_api_mutex_free_t :: #type (
    mutex: ecs_os_mutex_t);

/* Condition variable */
ecs_os_api_cond_new_t :: #type () -> ecs_os_cond_t;

ecs_os_api_cond_free_t :: #type (
    cond: ecs_os_cond_t);

ecs_os_api_cond_signal_t :: #type (
    cond: ecs_os_cond_t);

ecs_os_api_cond_broadcast_t :: #type (
    cond: ecs_os_cond_t);

ecs_os_api_cond_wait_t :: #type (
    cond: ecs_os_cond_t,
    mutex: ecs_os_mutex_t);

ecs_os_api_sleep_t :: #type (
    sec: int32_t,
    nanosec: int32_t);

ecs_os_api_get_time_t :: #type (
    time_out: *ecs_time_t);

/* Logging */
ecs_os_api_log_t :: #type (
    fmt: *u8,
    args: va_list);

/* Application termination */
ecs_os_api_abort_t :: #type ();

/* Dynamic libraries */
ecs_os_api_dlopen_t :: #type (
    libname: *u8) -> ecs_os_dl_t;

ecs_os_api_dlproc_t :: #type (
    lib: ecs_os_dl_t,
    procname: *u8) -> ecs_os_proc_t;

ecs_os_api_dlclose_t :: #type (
    lib: ecs_os_dl_t);

ecs_os_api_module_to_path_t :: #type (
    module_id: *u8) -> *u8;

/* Prefix members of struct with 'ecs_' as some system headers may define
 * macro's for functions like "strdup", "log" or "_free" */

ecs_os_api_t :: struct {
    /* API init / deinit */
    init_: ecs_os_api_init_t;
    fini_: ecs_os_api_fini_t;

    /* Memory management */
    malloc_: ecs_os_api_malloc_t;
    realloc_: ecs_os_api_realloc_t;
    calloc_: ecs_os_api_calloc_t;
    free_: ecs_os_api_free_t;

    /* Strings */
    strdup_: ecs_os_api_strdup_t;

    /* Threads */
    thread_new_: ecs_os_api_thread_new_t;
    thread_join_: ecs_os_api_thread_join_t;

    /* Atomic incremenet / decrement */
    ainc_: ecs_os_api_ainc_t;
    adec_: ecs_os_api_ainc_t;

    /* Mutex */
    mutex_new_: ecs_os_api_mutex_new_t;
    mutex_free_: ecs_os_api_mutex_free_t;
    mutex_lock_: ecs_os_api_mutex_lock_t;
    mutex_unlock_: ecs_os_api_mutex_lock_t;

    /* Condition variable */
    cond_new_: ecs_os_api_cond_new_t;
    cond_free_: ecs_os_api_cond_free_t;
    cond_signal_: ecs_os_api_cond_signal_t;
    cond_broadcast_: ecs_os_api_cond_broadcast_t;
    cond_wait_: ecs_os_api_cond_wait_t;

    /* Time */
    sleep_: ecs_os_api_sleep_t;
    get_time_: ecs_os_api_get_time_t;

    /* Logging */
    log_: ecs_os_api_log_t;
    log_error_: ecs_os_api_log_t;
    log_debug_: ecs_os_api_log_t;
    log_warning_: ecs_os_api_log_t;

    /* Application termination */
    abort_: ecs_os_api_abort_t;

    /* Dynamic library loading */
    dlopen_: ecs_os_api_dlopen_t;
    dlproc_: ecs_os_api_dlproc_t;
    dlclose_: ecs_os_api_dlclose_t;

    /* Overridable function that translates from a logical module id to a
     * shared library filename */
    module_to_dl_: ecs_os_api_module_to_path_t;

    /* Overridable function that translates from a logical module id to a
     * path that contains module-specif resources or assets */
    module_to_etc_: ecs_os_api_module_to_path_t;
}

ecs_os_init :: () -> () #foreign flecs;
ecs_os_fini :: () -> () #foreign flecs;

ecs_os_get_api :: () -> ecs_os_api_t  #foreign flecs;
ecs_os_set_api :: (os_api: *ecs_os_api_t) #foreign flecs;

ecs_os_set_api_defaults :: () -> () #foreign flecs;

/* Logging (use functions to avoid using variadic macro arguments) */
ecs_os_log :: (fmt: *u8, args: ..Any) #foreign flecs;
ecs_os_warn :: (fmt: *u8, args: ..Any) #foreign flecs;
ecs_os_err :: (fmt: *u8, args: ..Any) #foreign flecs;
ecs_os_dbg :: (fmt: *u8, args: ..Any) #foreign flecs;

/* Sleep with floating point time */
ecs_sleepf :: (t: float64) #foreign flecs;

/* Measure time since provided timestamp */
ecs_time_measure :: (start: *ecs_time_t) -> float64 #foreign flecs;

/* Calculate difference between two timestamps */
ecs_time_sub ::  (t1: ecs_time_t, t2: ecs_time_t) -> ecs_time_t #foreign flecs;

/* Convert time value to a double */
ecs_time_to_double :: (t: ecs_time_t) -> float64 #foreign flecs;

ecs_os_memdup :: (src: *void, size: ecs_size_t) -> *void #foreign flecs;

/* Are heap functions available? */
ecs_os_has_heap :: () -> bool #foreign flecs;

/* Are threading functions available? */
ecs_os_has_threading :: () -> bool #foreign flecs;

/* Are time functions available? */
ecs_os_has_time :: () -> bool #foreign flecs;

/* Are logging functions available? */
ecs_os_has_logging :: () -> bool #foreign flecs;

/* Are dynamic library functions available? */
ecs_os_has_dl :: () -> bool #foreign flecs;

/* Are module path functions available? */
ecs_os_has_modules :: () -> bool #foreign flecs;

/*
 * @defgroup api_types Basic API types
 * @{
 */

/* An id. Ids are the things that can be added to an entity. An id can be an
 * entity or pair, and can have an optional role. */
ecs_id_t :: uint64_t;

/* An entity identifier. */
ecs_entity_t :: ecs_id_t;

/* A vector containing component identifiers used to describe a type. */
ecs_type_t :: *ecs_vector_t;

/* A world is the container for all ECS data and supporting features. */
/* The world stores and manages all ECS data. An application can have more than
 * one world, but data is not shared between worlds. */
ecs_world_t :: struct {
    magic: s32;               /* Magic number to verify world pointer */

    /* --  Type metadata -- */
    id_index: *ecs_map_t;         /* map<id, ecs_id_record_t> */
    id_triggers: *ecs_map_t;      /* map<id, ecs_id_trigger_t> */
    type_info_: *ecs_sparse_t;     /* sparse<type_id, type_info_t> */

    /* Is entity range checking enabled? */
    range_check_enabled: bool;

    /* --  Data storage -- */
    store: ecs_store_t;

    /* --  Storages for API objects -- */
    queries: *ecs_sparse_t; /* sparse<query_id, ecs_query_t> */
    triggers: *ecs_sparse_t; /* sparse<query_id, ecs_trigger_t> */
    observers: *ecs_sparse_t; /* sparse<query_id, ecs_observer_t> */


    /* Keep track of components that were added/removed to/from monitored
     * entities. Monitored entities are entities that a query has matched with
     * specifically, as is the case with PARENT / CASCADE columns, FromEntity
     * columns and columns matched from prefabs.
     * When these entities change type, queries may have to be rematched.
     * Queries register themselves as component monitors for specific components
     * and when these components change they are rematched. The component
     * monitors are evaluated during a merge. */
    monitors: *ecs_relation_monitor_t;

    /* -- Systems -- */
    pipeline: ecs_entity_t;             /* Current pipeline */
    on_activate_components: *ecs_map_t; /* Trigger on activate of [in] column */
    on_enable_components: *ecs_map_t;   /* Trigger on enable of [in] column */
    fini_tasks: *ecs_vector_t;          /* Tasks to execute on ecs_fini */

    /* -- Lookup Indices -- */
    type_handles: *ecs_map_t;           /* Handles to named types */

    /* -- Aliasses -- */
    aliases: *ecs_vector_t;

    /* -- Staging -- */
    stage: ecs_stage_t;               /* Main storage */
    worker_stages: *ecs_vector_t;     /* Stages for threads */

    /* -- Hierarchy administration -- */
    name_prefix: *u8;                 /* Remove prefix from C names in modules */

    /* -- Multithreading -- */
    worker_cond: ecs_os_cond_t;       /* Signal that worker threads can start */
    sync_cond: ecs_os_cond_t;         /* Signal that worker thread job is done */
    sync_mutex: ecs_os_mutex_t;       /* Mutex for job_cond */
    workers_running: s32;             /* Number of threads running */
    workers_waiting: s32;             /* Number of workers waiting on sync */

    /* -- Time management -- */
    world_start_time: ecs_time_t;  /* Timestamp of simulation start */
    frame_start_time: ecs_time_t;  /* Timestamp of frame start */
    fps_sleep: float32;            /* Sleep time to prevent fps overshoot */

    /* -- Metrics -- */
    stats: ecs_world_info_t;

    /* -- Settings from command line arguments -- */
    arg_fps: s32;
    arg_threads: s32;

    /* -- World lock -- */
    mutex: ecs_os_mutex_t;         /* Locks the world if locking enabled */
    thr_sync: ecs_os_mutex_t;      /* Used to signal threads at end of frame */
    thr_cond: ecs_os_cond_t;       /* Used to signal threads at end of frame */

    /* -- Defered operation count -- */
    new_count: s32;
    bulk_new_count: s32;
    delete_count: s32;
    clear_count: s32;
    add_count: s32;
    remove_count: s32;
    set_count: s32;
    discard_count: s32;

    /* -- World state -- */
    quit_workers: bool;            /* Signals worker threads to quit */
    is_readonly: bool;             /* Is world being progressed */
    is_fini: bool;                 /* Is the world being cleaned up? */
    measure_frame_time: bool;      /* Time spent on each frame */
    measure_system_time: bool;     /* Time spent by each system */
    should_quit: bool;             /* Did a system signal that app should quit */
    locking_enabled: bool;         /* Lock world when in progress */

    app_context: *void;                /* Application context */
    fini_actions: *ecs_vector_t;   /* Callbacks to execute when world exits */
}

/* A query allows for cached iteration over ECS data */
/* Query that is automatically matched against active tables */
ecs_query_t :: struct {
    /* Signature of query */
    filter: ecs_filter_t;

    /* Reference to world */
    world: *ecs_world_t;

    /* Tables matched with query */
    tables: *ecs_vector_t;
    empty_tables: *ecs_vector_t;
    table_indices: *ecs_map_t;

    /* Handle to system (optional) */
    system: ecs_entity_t;

    /* Used for sorting */
    sort_on_component: ecs_entity_t;
    compare: ecs_compare_action_t;
    table_slices: *ecs_vector_t;

    /* Used for table sorting */
    rank_on_component: ecs_entity_t;
    group_table: ecs_rank_type_action_t;

    /* Subqueries */
    parent: *ecs_query_t;
    subqueries: *ecs_vector_t;

    /* The query kind determines how it is registered with tables */
    flags: ecs_flags32_t;

    id: uint64_t;                /* Id of query in query storage */
    cascade_by: int32_t;         /* Identify CASCADE column */
    match_count: int32_t;        /* How often have tables been (un)matched */
    prev_match_count: int32_t;   /* Used to track if sorting is needed */

    needs_reorder: bool;         /* Whether next iteration should reorder */
    constraints_satisfied: bool; /* Are all term constraints satisfied */
}

/* A filter allows for uncached, ad hoc iteration over ECS data */
ecs_filter_t :: struct {
    terms: *ecs_term_t;         /* Array containing terms for filter */
    term_count: int32_t;        /* Number of elements in terms array */
    term_count_actual: int32_t; /* Processed count, which folds OR terms */

    name: *u8;                  /* Name of filter (optional) */
    expr: *u8;                  /* Expression of filter (if provided) */

    /* Deprecated fields */
    include: ecs_type_t;
    exclude: ecs_type_t;
    include_kind: ecs_match_kind_t;
    exclude_kind: ecs_match_kind_t;
}

/* A trigger reacts to events matching a single filter term */
ecs_trigger_t :: struct {
    term: ecs_term_t;            /* Term describing the trigger condition id */

    /* Trigger events */
    events: [ECS_TRIGGER_DESC_EVENT_COUNT_MAX] ecs_entity_t;
    event_count: int32_t;

    action: ecs_iter_action_t;   /* Callback */

    ctx: *void;                  /* Callback context */
    binding_ctx: *void;          /* Binding context (for language bindings) */

    ctx_free: ecs_ctx_free_t;    /* Callback to free ctx */
    binding_ctx_free: ecs_ctx_free_t; /* Callback to free binding_ctx */

    entity: ecs_entity_t;        /* Entity associated with trigger */

    id: uint64_t;                /* Internal id */
}

/* An observer reacts to events matching multiple filter terms */
ecs_observer_t :: struct {
    filter: ecs_filter_t;

    /* Triggers created by observer (array size same as number of terms) */
    triggers: *ecs_entity_t;

    /* Observer events */
    events: [ECS_TRIGGER_DESC_EVENT_COUNT_MAX] ecs_entity_t;
    event_count: int32_t;

    action: ecs_iter_action_t;   /* Callback */

    ctx: *void;                  /* Callback context */
    binding_ctx: *void;          /* Binding context (for language bindings) */

    ctx_free: ecs_ctx_free_t;    /* Callback to free ctx */
    binding_ctx_free: ecs_ctx_free_t; /* Callback to free binding_ctx */

    entity: ecs_entity_t;        /* Entity associated with observer */

    id: uint64_t;                /* Internal id */
}

/* The ecs_iter_t struct allows applications to iterate tables.
 * Queries and filters, among others, allow an application to iterate entities
 * that match a certain set of components. Because of how data is stored
 * internally, entities with a given set of components may be stored in multiple
 * consecutive arrays, stored across multiple tables. The ecs_iter_t type
 * enables iteration across tables. */
ecs_iter_t :: struct {
    world: *ecs_world_t;           /* The world */
    real_world: *ecs_world_t;      /* Actual world. This differs from world when using threads.  */
    system: ecs_entity_t;          /* The current system (if applicable) */
    event: ecs_entity_t;           /* The event (if applicable) */
    kind: ecs_query_iter_kind_t;

    table: *ecs_iter_table_t;      /* Table related data */
    query: *ecs_query_t;           /* Current query being evaluated */
    table_count: int32_t;          /* Active table count for query */
    inactive_table_count: int32_t; /* Inactive table count for query */
    column_count: int32_t;         /* Number of columns for system */

    table_columns: *void;          /* Table component data */
    entities: *ecs_entity_t;       /* Entity identifiers */

    param: *void;                  /* Param passed to ecs_run */
    ctx: *void;                    /* System context */
    binding_ctx: *void;            /* Binding context */
    delta_time: FLECS_FLOAT;       /* Time elapsed since last frame */
    delta_system_time: FLECS_FLOAT;/* Time elapsed since last system invocation */
    world_time: FLECS_FLOAT;       /* Time elapsed since start of simulation */

    frame_offset: int32_t;         /* Offset relative to frame */
    offset: int32_t;               /* Offset relative to current table */
    count: int32_t;                /* Number of entities to process by system */
    total_count: int32_t;          /* Total number of entities in table */

    triggered_by: *ecs_ids_t;      /* Component(s) that triggered the system */
    interrupted_by: ecs_entity_t;  /* When set, system execution is interrupted */

    iter :: union {                /* Iterator specific data */
        parent: ecs_scope_iter_t;
        filter: ecs_filter_iter_t;
        query: ecs_query_iter_t;
        snapshot: ecs_snapshot_iter_t;
    };
}

/* @} */

/*
 * @defgroup constants API constants
 * @{
 */

/* Maximum number of components to add/remove in a single operation */
ECS_MAX_ADD_REMOVE :: 32;

/* Maximum number of terms to set in static array of filter descriptor */
ECS_FILTER_DESC_TERM_ARRAY_MAX :: 16;

/* Maximum number of events to set in static array of trigger descriptor */
ECS_TRIGGER_DESC_EVENT_COUNT_MAX :: 8;

/* @} */

/*
 * @defgroup function_types Function Types
 * @{
 */

/* Action callback for systems and triggers */
ecs_iter_action_t :: #type (
    it: *ecs_iter_t);

ecs_iter_next_action_t :: #type (
    it: *ecs_iter_t) -> bool;

/* Callback used for ranking types */
ecs_rank_type_action_t :: #type (
    world: *ecs_world_t,
    rank_component: ecs_entity_t,
    type: ecs_type_t) -> int32_t;

/* Initialization action for modules */
ecs_module_action_t :: #type (
    world: *ecs_world_t);

/* Action callback on world exit */
ecs_fini_action_t :: #type (
    world: *ecs_world_t,
    ctx: *void);

/* Function to cleanup context data */
ecs_ctx_free_t :: #type (
    ctx: *void);

/* Callback used for sorting values */
ecs_compare_value_action_t :: #type (
    ptr1: *void,
    ptr2: *void) -> s32;

/* Callback used for hashing values */
ecs_hash_value_action_t :: #type (
    ptr: *void) -> uint64_t;

/* Callback used for sorting components */
ecs_compare_action_t :: #type (
    e1: ecs_entity_t,
    ptr1: *void,
    e2: ecs_entity_t,
    ptr2: *void) -> s32;

/* @} */

/*
 * @defgroup filter_types Types used to describe filters, terms and triggers
 * @{
 */

/* Set flags describe if & how a matched entity should be substituted */
EcsDefaultSet   :: 0;  /* Default set, SuperSet|Self for This subject */
EcsSelf         :: 1;  /* Select self (inclusive) */
EcsSuperSet     :: 2;  /* Select superset until predicate match */
EcsSubSet       :: 4;  /* Select subset until predicate match */
EcsCascade      :: 8;  /* Use breadth-first ordering of relations */
EcsAll          :: 16; /* Walk full super/subset, regardless of match */
EcsNothing      :: 32; /* Select from nothing */

/* Specify read/write access for term */
ecs_inout_kind_t :: enum {
    EcsInOutDefault;
    EcsInOut;
    EcsIn;
    EcsOut;
}

/* Specifies whether term identifier is a variable or entity */
ecs_var_kind_t :: enum {
    EcsVarDefault;      /* Variable if name is all caps, otherwise an entity */
    EcsVarIsEntity;     /* Term is an entity */
    EcsVarIsVariable;   /* Term is a variable */
}

/* Type describing an operator used in an signature of a system signature */
ecs_oper_kind_t :: enum {
    EcsAnd;         /* The term must match */
    EcsOr;          /* One of the terms in an or chain must match */
    EcsNot;         /* The term must not match */
    EcsOptional;    /* The term may match */
    EcsAndFrom;     /* Term must match all components from term id */
    EcsOrFrom;      /* Term must match at least one component from term id */
    EcsNotFrom;      /* Term must match none of the components from term id */
}

/* Substitution with set parameters.
 * These parameters allow for substituting a term id with its super- or subsets
 * for a specified relationship. This enables functionality such as selecting
 * components from a base (IsA) or a parent (ChildOf) in a single term */
ecs_term_set_t :: struct {
    relation: ecs_entity_t;      /* Relationship to substitute (default = IsA) */
    mask: uint8_t;               /* Substitute as self, subset, superset */
    min_depth: int32_t;          /* Min depth of subset/superset substitution */
    max_depth: int32_t;          /* Max depth of subset/superset substitution */
}

/* Type that describes a single identifier in a term */
ecs_term_id_t :: struct {
    entity: ecs_entity_t;        /* Entity (default = This) */
    name: *u8  ;                 /* Name (default = ".") */
    var: ecs_var_kind_t;         /* Is id a variable (default yes if name is
                                  * all caps & entity is 0) */
    set: ecs_term_set_t;         /* Set substitution parameters */
}

/* Type that describes a single column in the system signature */
ecs_term_t :: struct {
    id: ecs_id_t;                /* Can be used instead of pred, args and role to
                                  * set component/pair id. If not set, it will be
                                  * computed from predicate, object. If set, the
                                  * subject cannot be set, or be set to This. */

    inout: ecs_inout_kind_t;     /* Access to contents matched with term */
    pred: ecs_term_id_t;         /* Predicate of term */
    args: [2] ecs_term_id_t;     /* Subject (0), object (1) of term */
    oper: ecs_oper_kind_t;       /* Operator of term */
    role: ecs_id_t;              /* Role of term */
    name: *u8;                   /* Name of term */

    index: int32_t;              /* Computed term index in filter which takes
                                  * into account folded OR terms */

    move: bool;                  /* When true, this signals to ecs_term_copy that
                                  * the resources held by this term may be moved
                                  * into the destination term. */
}

/* Deprecated */
ecs_match_kind_t :: enum {
    EcsMatchDefault = 0;
    EcsMatchAll;
    EcsMatchAny;
    EcsMatchExact;
}

/* Filters alllow for ad-hoc quick filtering of entity tables. */
ecs_filter_t :: {
    terms: *ecs_term_t;         /* Array containing terms for filter */
    term_count: int32_t;        /* Number of elements in terms array */
    term_count_actual: int32_t; /* Processed count, which folds OR terms */

    name: *u8;                /* Name of filter (optional) */
    expr: *u8;                /* Expression of filter (if provided) */

    /* Deprecated fields */
    include: ecs_type_t;
    exclude: ecs_type_t;
    include_kind: ecs_match_kind_t;
    exclude_kind: ecs_match_kind_t;
};


/* A trigger reacts to events matching a single term */
ecs_trigger_t :: struct {
    ecs_term_t term;            /* Term describing the trigger condition id */

    /* Trigger events */
    ecs_entity_t events[ECS_TRIGGER_DESC_EVENT_COUNT_MAX];
    int32_t event_count;

    ecs_iter_action_t action;   /* Callback */

    void *ctx;                  /* Callback context */
    void *binding_ctx;          /* Binding context (for language bindings) */

    ecs_ctx_free_t ctx_free;    /* Callback to free ctx */
    ecs_ctx_free_t binding_ctx_free; /* Callback to free binding_ctx */

    ecs_entity_t entity;        /* Entity associated with trigger */

    uint64_t id;                /* Internal id */
};


/* An observer reacts to events matching a filter */
ecs_observer_t :: struct {
    filter: ecs_filter_t;

    /* Triggers created by observer (array size same as number of terms) */
    triggers: *ecs_entity_t;

    /* Observer events */
    events: [ECS_TRIGGER_DESC_EVENT_COUNT_MAX] ecs_entity_t;
    event_count: int32_t;

    action: ecs_iter_action_t;   /* Callback */

    ctx: *void;                  /* Callback context */
    binding_ctx: *void;          /* Binding context (for language bindings) */

    ctx_free: ecs_ctx_free_t;    /* Callback to free ctx */
    binding_ctx_free: ecs_ctx_free_t; /* Callback to free binding_ctx */

    entity: ecs_entity_t;        /* Entity associated with observer */

    id: uint64_t;                /* Internal id */
};

/* @} */

/*
 * @file api_types.h
 * @brief Supporting types for the public API.
 *
 * This file contains types that are typically not used by an application but
 * support the public API, and therefore must be exposed. This header should not
 * be included by itself.
 */

/* A stage is a data structure in which delta's are stored until it is safe to
 * merge those delta's with the main world stage. A stage allows flecs systems
 * to arbitrarily add/remove/set components and create/delete entities while
 * iterating. Additionally, worker threads have their own stage that lets them
 * mutate the state of entities without requiring locks. */
ecs_stage_t :: struct {
    magic: int32_t;              /* Magic number to verify thread pointer */
    id: int32_t;                 /* Unique id that identifies the stage */

    /* Are operations deferred? */
    defer_: int32_t;
    defer_queue: *ecs_vector_t;

    thread_ctx: *ecs_world_t;    /* Points to stage when a thread stage */
    world: *ecs_world_t;         /* Reference to world */
    thread: ecs_os_thread_t;     /* Thread handle (0 if no threading is used) */

    /* One-shot actions to be executed after the merge */
    post_frame_actions: *ecs_vector_t;

    /* Namespacing */
    scope_table: *ecs_table_t;      /* Table for current scope */
    scope: ecs_entity_t;            /* Entity of current scope */
    with: ecs_entity_t;             /* Id to add by default to new entities */

    /* Properties */
    auto_merge: bool;               /* Should this stage automatically merge? */
    asynchronous: bool;             /* Is stage asynchronous? (write only) */
};

/* A table is the Flecs equivalent of an archetype. Tables store all entities
 * with a specific set of components. Tables are automatically created when an
 * entity has a set of components not previously observed before. When a new
 * table is created, it is automatically matched with existing queries */
ecs_table_t :: struct {
    id: uint64_t;                     /* Table id in sparse set */
    type: ecs_type_t;                 /* Identifies table type in type_index */
    flags: ecs_flags32_t;             /* Flags for testing table properties */
    column_count: int32_t;            /* Number of data columns in table */

    data: *ecs_data_t;                /* Component storage */
    c_info: **ecs_type_info_t;        /* Cached pointers to component info */

    lo_edges: *ecs_edge_t;            /* Edges to other tables */
    hi_edges: *ecs_map_t;

    queries: *ecs_vector_t;           /* Queries matched with table */
    monitors: *ecs_vector_t;          /* Monitor systems matched with table */
    on_set: **ecs_vector_t;           /* OnSet systems, broken up by column */
    on_set_all: *ecs_vector_t;        /* All OnSet systems */
    on_set_override: *ecs_vector_t;   /* All OnSet systems with overrides */
    un_set_all: *ecs_vector_t;        /* All UnSet systems */

    dirty_state: *int32_t;            /* Keep track of changes in columns */
    alloc_count: int32_t;             /* Increases when columns are reallocd */

    sw_column_count: int32_t;
    sw_column_offset: int32_t;
    bs_column_count: int32_t;
    bs_column_offset: int32_t;

    lock: int32_t;
};

/* A record stores data to map an entity id to a location in a table */
ecs_record_t :: struct {
    table: *ecs_table_t;  /* Identifies a type (and table) in world */
    row: int32_t;         /* Table row of the entity */
};

/* Table column */
ecs_column_t :: struct {
    data: *ecs_vector_t;        /* Column data */
    size: int16_t;              /* Column element size */
    alignment: int16_t;         /* Column element alignment */
};

/* Table data */
ecs_data_t :: struct {
    entities: *ecs_vector_t;      /* Entity identifiers */
    record_ptrs: *ecs_vector_t;   /* Ptrs to records in main entity index */
    columns: *ecs_column_t;       /* Component columns */
    sw_columns: *ecs_sw_column_t; /* Switch columns */
    bs_columns: *ecs_bs_column_t; /* Bitset columns */
};

/*
 * @file sparse.h
 * @brief Sparse set datastructure.
 *
 * This is an implementation of a paged sparse set that stores the payload in
 * the sparse array.
 *
 * A sparse set has a dense and a sparse array. The sparse array is directly
 * indexed by a 64 bit identifier. The sparse element is linked with a dense
 * element, which allows for liveliness checking. The liveliness check itself
 * can be performed by doing (psuedo code):
 *  dense[sparse[sparse_id].dense] == sparse_id
 *
 * To ensure that the sparse array doesn't have to grow to a large size when
 * using large sparse_id's, the sparse set uses paging. This cuts up the array
 * into several pages of 4096 elements. When an element is set, the sparse set
 * ensures that the corresponding page is created. The page associated with an
 * id is determined by shifting a bit 12 bits to the right.
 *
 * The sparse set keeps track of a generation count per id, which is increased
 * each time an id is deleted. The generation is encoded in the returned id.
 *
 * This sparse set implementation stores payload in the sparse array, which is
 * not typical. The reason for this is to guarantee that (in combination with
 * paging) the returned payload pointers are stable. This allows for various
 * optimizations in the parts of the framework that uses the sparse set.
 *
 * The sparse set has been designed so that new ids can be generated in bulk, in
 * an O(1) operation. The way this works is that once a dense-sparse pair is
 * created, it is never unpaired. Instead it is moved to the end of the dense
 * array, and the sparse set stores an additional count to keep track of the
 * last alive id in the sparse set. To generate new ids in bulk, the sparse set
 * only needs to increase this count by the number of requested ids.
 */
ecs_sparse_t :: struct {
    dense: *ecs_vector_t;        /* Dense array with indices to sparse array. The
                                  * dense array stores both alive and not alive
                                  * sparse indices. The 'count' member keeps
                                  * track of which indices are alive. */

    chunks: *ecs_vector_t;       /* Chunks with sparse arrays & data */
    size: ecs_size_t;            /* Element size */
    count: int32_t;              /* Number of alive entries */
    max_id_local: uint64_t;      /* Local max index (if no global is set) */
    max_id: *uint64_t;           /* Maximum issued sparse index */
};

/*
 * @file switch_list.h
 * @brief Interleaved linked list for storing mutually exclusive values.
 *
 * Datastructure that stores N interleaved linked lists in an array.
 * This allows for efficient storage of elements with mutually exclusive values.
 * Each linked list has a header element which points to the index in the array
 * that stores the first node of the list. Each list node points to the next
 * array element.
 *
 * The datastructure needs to be created with min and max values, so that it can
 * allocate an array of headers that can be directly indexed by the value. The
 * values are stored in a contiguous array, which allows for the values to be
 * iterated without having to follow the linked list nodes.
 *
 * The datastructure allows for efficient storage and retrieval for values with
 * mutually exclusive values, such as enumeration values. The linked list allows
 * an application to obtain all elements for a given (enumeration) value without
 * having to search.
 *
 * While the list accepts 64 bit values, it only uses the lower 32bits of the
 * value for selecting the correct linked list.
 */

ecs_switch_header_t :: struct {
    element: int32_t;        /* First element for value */
    count: int32_t;          /* Number of elements for value */
}

ecs_switch_node_t :: struct {
    next: int32_t;           /* Next node in list */
    prev: int32_t;           /* Prev node in list */
}

ecs_switch_t :: struct {
    min: uint64_t;                  /* Minimum value the switch can store */
    max: uint64_t;                  /* Maximum value the switch can store */
    headers: *ecs_switch_header_t;  /* Array with headers, indexed by value */
    nodes: *ecs_vector_t;           /* Vector with nodes, of type ecs_switch_node_t */
    values: *ecs_vector_t;          /* Vector with values, of type uint64_t */
}

/* Refs cache data that lets them access components faster than ecs_get. */
ecs_ref_t :: struct {
    entity: ecs_entity_t;       /* Entity of the reference */
    component: ecs_entity_t;    /* Component of the reference */
    table: *void;               /* Last known table */
    row: int32_t;               /* Last known location in table */
    alloc_count: int32_t;       /* Last known alloc count of table */
    record: 8ecs_record_t;      /* Pointer to record, if in main stage */
    ptr: *void;                 /* Cached ptr */
};

/* Array of entity ids that, other than a type, can live on the stack */
ecs_ids_t :: struct {
    array: *ecs_entity_t;    /* An array with entity ids */
    count: int32_t;          /* The number of entities in the array */
}

ecs_page_cursor_t :: struct {
    first: int32_t;
    count: int32_t;
}

ecs_page_iter_t :: struct {
    offset: int32_t;
    limit: int32_t;
    remaining: int32_t;
}

/* Table specific data for iterators */
ecs_iter_table_t :: struct {
    columns: *int32_t;         /* Mapping from query terms to table columns */
    table: *ecs_table_t;       /* The current table. */
    data: *ecs_data_t;         /* Table component data */
    components: *ecs_entity_t; /* Components in current table */
    types: *ecs_type_t;        /* Components in current table */
    references: *ecs_ref_t;    /* References to entities (from query) */
}

/* Scope-iterator specific data */
ecs_scope_iter_t :: struct {
    filter: ecs_filter_t;
    tables: ecs_map_iter_t;
    index: int32_t;
    table: ecs_iter_table_t;
}

/* Filter-iterator specific data */
ecs_filter_iter_t :: struct {
    filter: ecs_filter_t;
    tables: *ecs_sparse_t;
    index: int32_t;
    table: ecs_iter_table_t;
}

/* Iterator flags used to quickly select the optimal iterator algorithm */
ecs_query_iter_kind_t :: enum {
    EcsQuerySimpleIter;     /* No paging, sorting or sparse columns */
    EcsQueryPagedIter;      /* Regular iterator with paging */
    EcsQuerySortedIter;     /* Sorted iterator */
    EcsQuerySwitchIter;     /* Switch type iterator */
}

/* Query-iterator specific data */
ecs_query_iter_t :: struct {
    page_iter: ecs_page_iter_t;
    index: int32_t;
    sparse_smallest: int32_t;
    sparse_first: int32_t;
    bitset_first: int32_t;
}

/* Query-iterator specific data */
ecs_snapshot_iter_t :: struct {
    filter: ecs_filter_t;
    tables: *ecs_vector_t; /* ecs_table_leaf_t */
    index: int32_t;
    table: ecs_iter_table_t;
} ecs_snapshot_iter_t;

EcsMatchFailureReason :: enum {
    EcsMatchOk;
    EcsMatchNotASystem;
    EcsMatchSystemIsATask;
    EcsMatchEntityIsDisabled;
    EcsMatchEntityIsPrefab;
    EcsMatchFromSelf;
    EcsMatchFromOwned;
    EcsMatchFromShared;
    EcsMatchFromContainer;
    EcsMatchFromEntity;
    EcsMatchOrFromSelf;
    EcsMatchOrFromOwned;
    EcsMatchOrFromShared;
    EcsMatchOrFromContainer;
    EcsMatchNotFromSelf;
    EcsMatchNotFromOwned;
    EcsMatchNotFromShared;
    EcsMatchNotFromContainer;
}

ecs_match_failure_t :: struct {
    reason: EcsMatchFailureReason;
    column: int32_t;
}

////////////////////////////////////////////////////////////////////////////////
//// Function types
////////////////////////////////////////////////////////////////////////////////

/* Constructor/destructor. Used for initializing / deinitializing components. */
ecs_xtor_t :: #type (
    world: *ecs_world_t,
    component: ecs_entity_t,
    entity_ptr: *ecs_entity_t,
    ptr: *void,
    size: size_t,
    count: int32_t,
    ctx: *void);

/* Copy is invoked when a component is copied into another component. */
ecs_copy_t :: #type (
    world: *ecs_world_t,
    component: ecs_entity_t,
    dst_entity: *ecs_entity_t,
    src_entity: *ecs_entity_t,
    dst_ptr: *void,
    src_ptr: *void,
    size: size_t,
    count: int32_t,
    ctx: *void);

/* Move is invoked when a component is moved to another component. */
ecs_move_t :: #type (
    world: *ecs_world_t,
    component: ecs_entity_t,
    dst_entity: *ecs_entity_t,
    src_entity: *ecs_entity_t,
    dst_ptr: *void,
    src_ptr: *void,
    size: size_t,
    count: int32_t,
    ctx: *void);

/* Copy ctor */
ecs_copy_ctor_t :: #type (
    world: *ecs_world_t,
    component: ecs_entity_t,
    callbacks: *EcsComponentLifecycle,
    dst_entity: *ecs_entity_t,
    src_entity: *ecs_entity_t,
    dst_ptr: *void,
    src_ptr: *void,
    size: size_t,
    count: int32_t,
    ctx: *void);

/* Move ctor */
ecs_move_ctor_t :: #type (
    world: *ecs_world_t,
    component: ecs_entity_t,
    callbacks: *EcsComponentLifecycle,
    dst_entity: *ecs_entity_t,
    src_entity: *ecs_entity_t,
    dst_ptr: *void,
    src_ptr: *void,
    size: size_t,
    count: int32_t,
    ctx: *void);

/*
 * @file api_support.h
 * @brief Support functions and constants.
 *
 * Supporting types and functions that need to be exposed either in support of
 * the public API or for unit tests, but that may change between minor / patch
 * releases.
 */

/* This reserves entity ids for components. Regular entity ids will start after
 * this constant. This affects performance of table traversal, as edges with ids
 * lower than this constant are looked up in an array, whereas constants higher
 * than this id are looked up in a map. Increasing this value can improve
 * performance at the cost of (significantly) higher memory usage. */
ECS_HI_COMPONENT_ID :: 256; /* Maximum number of components */

/* The maximum number of nested function calls before the core will throw a
 * cycle detected error */
ECS_MAX_RECURSION :: 512;

////////////////////////////////////////////////////////////////////////////////
//// Global type handles
////////////////////////////////////////////////////////////////////////////////

/* Type handles to builtin components */
FLECS_API
extern ecs_type_t
    ecs_type(EcsComponent),
    ecs_type(EcsComponentLifecycle),
    ecs_type(EcsType),
    ecs_type(EcsName);

/* This allows passing 0 as type to functions that accept types */
FLECS__TNULL :: 0;
FLECS__T0 :: 0;
FLECS__E0 :: 0;

////////////////////////////////////////////////////////////////////////////////
//// Functions used in declarative (macro) API
////////////////////////////////////////////////////////////////////////////////

ecs_new_module :: (
    world: *ecs_world_t,
    e: ecs_entity_t,
    name: *u8,
    size: size_t,
    alignment: size_t) -> ecs_entity_t #foreign flecs;

ecs_module_path_from_c :: (
    c_name: *u8) -> *u8 #foreign flecs;

ecs_component_has_actions :: (
    world: *ecs_world_t,
    component: ecs_entity_t) -> bool #foreign flecs;

ecs_add_module_tag :: (
    world: *ecs_world_t,
    module: ecs_entity_t) #foreign flecs;

/*
 * @file log.h
 * @brief Internal logging API.
 *
 * Internal utility functions for tracing, warnings and errors.
 */

////////////////////////////////////////////////////////////////////////////////
//// Color macro's
////////////////////////////////////////////////////////////////////////////////

ECS_BLACK   :: "\033[1;30m"
ECS_RED     :: "\033[0;31m"
ECS_GREEN   :: "\033[0;32m"
ECS_YELLOW  :: "\033[0;33m"
ECS_BLUE    :: "\033[0;34m"
ECS_MAGENTA :: "\033[0;35m"
ECS_CYAN    :: "\033[0;36m"
ECS_WHITE   :: "\033[1;37m"
ECS_GREY    :: "\033[0;37m"
ECS_NORMAL  :: "\033[0;49m"
ECS_BOLD    :: "\033[1;49m"


////////////////////////////////////////////////////////////////////////////////
//// Exceptions
////////////////////////////////////////////////////////////////////////////////

/* Get description for error code */
ecs_strerror :: (error_code: int32_t) -> *u8;

/* Abort */
_ecs_abort :: (
    error_code: int32_t,
    param: *u8,
    file: *u8,
    line: int32_t) #foreign flecs;

ecs_abort :: inline (error_code: int32_t, param: *u8, loc := #caller_location) {
    _ecs_abort(error_code, param, loc.fully_pathed_filename, loc.line_number);
}

/* Assert */
FLECS_API
_ecs_assert :: (
    condition: bool,
    error_code: int32_t,
    param: *u8,
    condition_str: *u8,
    file: *u8,
    line: int32_t) #foreign flecs;

ecs_assert :: (condition: bool, error_code: int32_t, param: *u8, loc := #caller_location) {
    _ecs_assert(condition, error_code, param, "", loc.fully_pathed_filename, loc.line_number);
    assert(condition);
}

FLECS_API
_ecs_parser_error :: (
    name: *u8,
    expr: *u8,
    column: int64_t,
    fmt: *u8,
    args: ..Any) #foreign flecs;

ecs_parser_error :: inline (name: *u8, expr: *u8, column: int64_t, fmt: *u8, args: ..Any) {
    _ecs_parser_error(name, expr, column, fmt, args);
}

/*
 * @file type.h
 * @brief Type API.
 *
 * This API contains utilities for working with types. Types are vectors of
 * component ids, and are used most prominently in the API to construct filters.
 */

ecs_type_from_id :: (
    world: *ecs_world_t,
    entity: ecs_entity_t) -> ecs_type_t #foreign flecs;

ecs_type_to_id :: (
    world: *ecs_world_t,
    type: ecs_type_t) -> ecs_entity_t #foreign flecs;

ecs_type_str :: (
    world: *ecs_world_t,
    type: ecs_type_t) -> *u8 #foreign flecs;

ecs_type_from_str :: (
    world: *ecs_world_t,
    expr: *u8) -> ecs_type_t #foreign flecs;

ecs_type_find :: (
    world: *ecs_world_t,
    array: *ecs_entity_t,
    count: int32_t) -> ecs_type_t #foreign flecs;

ecs_type_merge :: (
    world: *ecs_world_t,
    type: ecs_type_t,
    type_add: ecs_type_t,
    type_remove: ecs_type_t) -> ecs_type_t #foreign flecs;

ecs_type_add :: (
    world: *ecs_world_t,
    type: ecs_type_t,
    entity: ecs_entity_t) -> ecs_type_t #foreign flecs;

ecs_type_remove :: (
    world: *ecs_world_t,
    type: ecs_type_t,
    entity: ecs_entity_t) -> ecs_type_t #foreign flecs;

ecs_type_has_id :: (
    world: *ecs_world_t,
    type: ecs_type_t,
    entity: ecs_entity_t) -> bool #foreign flecs;

ecs_type_has_type :: (
    world: *ecs_world_t,
    type: ecs_type_t,
    has: ecs_type_t) -> bool #foreign flecs;

ecs_type_owns_id :: (
    world: *ecs_world_t,
    type: ecs_type_t,
    entity: ecs_entity_t,
    owned: bool) -> bool #foreign flecs;

ecs_type_owns_type :: (
    world: *ecs_world_t,
    type: ecs_type_t,
    has: ecs_type_t,
    owned: bool) -> bool #foreign flecs;

ecs_type_find_id :: (
    world: *ecs_world_t,
    type: ecs_type_t,
    id: ecs_entity_t,
    rel: ecs_entity_t,
    min_depth: int32_t,
    max_depth: int32_t,
    out: *ecs_entity_t) -> bool #foreign flecs;

ecs_type_get_entity_for_xor :: (
    world: *ecs_world_t,
    type: ecs_type_t,
    xor_tag: ecs_entity_t) -> ecs_entity_t #foreign flecs;

ecs_type_index_of :: (
    type: ecs_type_t,
    component: ecs_entity_t) -> int32_t #foreign flecs;

ecs_type_match :: (
    type: ecs_type_t,
    start_index: int32_t,
    pair: ecs_entity_t) -> int32_t #foreign flecs;

/*
 * @defgroup desc_types Types used for creating API constructs
 * @{
 */

/* Used with ecs_entity_init */
ecs_entity_desc_t :: struct {
    entity: ecs_entity_t; /* Optional existing entity handle. */

    name: *u8;    /* Name of the entity. If no entity is provided, an
                   * entity with this name will be looked up first. When
                   * an entity is provided, the name will be verified
                   * with the existing entity. */

    sep: *u8;     /* Optional custom separator for hierarchical names */

    symbol: *u8;  /* Optional entity symbol. A symbol is an unscoped
                   * identifier that can be used to lookup an entity. The
                   * primary use case for this is to associate the entity
                   * with a language identifier, such as a type or
                   * function name, where these identifiers differ from
                   * the name they are registered with in flecs. For
                   * example, C type "EcsPosition" might be registered
                   * as "flecs.components.transform.Position", with the
                   * symbol set to "EcsPosition". */

    use_low_id: bool;     /* When set to true, a low id (typically reserved for
                           * components) will be used to create the entity, if
                           * no id is specified. */

    /* Array of ids to add to the new or existing entity. */
    add: [ECS_MAX_ADD_REMOVE] ecs_id_t;

    /* Array of ids to remove from the existing entity. */
    remove: [ECS_MAX_ADD_REMOVE] ecs_id_t;

    /* String expression with components to add */
    add_expr: *u8;

    /* String expression with components to remove */
    remove_expr: *u8;
}

/* Used with ecs_component_init. */
ecs_component_desc_t :: struct {
    entity: ecs_entity_desc_t;           /* Parameters for component entity */
    size: size_t;                        /* Component size */
    alignment: size_t;                   /* Component alignment */
}

/* Used with ecs_type_init. */
ecs_type_desc_t :: struct {
    entity: ecs_entity_desc_t;          /* Parameters for type entity */
    ids: [ECS_MAX_ADD_REMOVE] ecs_id_t; /* Ids to include in type */
    ids_expr: *u8;                      /* Id expression to include in type */
}

/* Used with ecs_filter_init. */
ecs_filter_desc_t :: struct {
    /* Terms of the filter. If a filter has more terms than
     * ECS_FILTER_DESC_TERM_ARRAY_MAX use terms_buffer */
    terms: [ECS_FILTER_DESC_TERM_ARRAY_MAX] ecs_term_t;

    /* For filters with lots of terms an outside array can be provided. */
    terms_buffer: *ecs_term_t;
    terms_buffer_count: int32_t;

    /* Substitute IsA relationships by default. If true, any term with 'set'
     * assigned to DefaultSet will be modified to Self|SuperSet(IsA). */
    substitute_default: bool;

    /* Filter expression. Should not be set at the same time as terms array */
    expr: *u8;

    /* Optional name of filter, used for debugging. If a filter is created for
     * a system, the provided name should match the system name. */
    name: *u8;
}

/* Used with ecs_query_init. */
ecs_query_desc_t :: struct {
    /* Filter for the query */
    filter: ecs_filter_desc_t;

    /* Id (component) to be used by order_by */
    order_by_id: ecs_id_t;

    /* Callback used for ordering query results. If order_by_id is 0, the
     * pointer provided to the callback will be NULL. If the callback is not
     * set, results will not be ordered. */
    order_by: ecs_compare_action_t;

    /* Id (component) to be used by group_by */
    group_by_id: ecs_id_t;

    /* Callback used for grouping results. If the callback is not set, results
     * will not be grouped. */
    group_by: ecs_rank_type_action_t;

    /* If set, the query will be created as a subquery. A subquery matches at
     * most a subset of its parent query. Subqueries do not directly receive
     * (table) notifications from the world. Instead parent queries forward
     * results to subqueries. This can improve matching performance, as fewer
     * queries need to be matched with new tables.
     * Subqueries can be nested. */
    parent: *ecs_query_t;

    /* INTERNAL PROPERTY - system to be associated with query. Do not set, as
     * this will change in future versions. */
    system: ecs_entity_t;
}

/* Used with ecs_trigger_init. */
ecs_trigger_desc_t :: struct {
    /* Entity to associate with trigger */
    entity: ecs_entity_desc_t;

    /* Term specifying the id to subscribe for */
    term: ecs_term_t;

    /* Filter expression. May only contain a single term. If this field is set,
     * the term field is ignored. */
    expr: *u8;

    /* Events to trigger on (OnAdd, OnRemove, OnSet, UnSet) */
    events: [ECS_TRIGGER_DESC_EVENT_COUNT_MAX] ecs_entity_t;

    /* Callback to invoke on an event */
    callback: ecs_iter_action_t;

    /* User context to pass to callback */
    ctx: *void;

    /* Context to be used for language bindings */
    binding_ctx: *void;

    /* Callback to free ctx */
    ctx_free: ecs_ctx_free_t;

    /* Callback to free binding_ctx */
    binding_ctx_free: ecs_ctx_free_t;
}

/* Used with ecs_observer_init. */
ecs_observer_desc_t :: struct {
    /* Entity to associate with observer */
    entity: ecs_entity_desc_t;

    /* Filter for observer */
    filter: ecs_filter_desc_t;

    /* Events to observe (OnAdd, OnRemove, OnSet, UnSet) */
    events: [ECS_TRIGGER_DESC_EVENT_COUNT_MAX] ecs_entity_t;

    /* Callback to invoke on an event */
    callback: ecs_iter_action_t;

    /* User context to pass to callback */
    ctx: *void;

    /* Context to be used for language bindings */
    binding_ctx: *void;

    /* Callback to free ctx */
    ctx_free: ecs_ctx_free_t;

    /* Callback to free binding_ctx */
    binding_ctx_free: ecs_ctx_free_t;
}

/* @} */

/*
 * @defgroup builtin_components Builtin components
 * @{
 */

/* Entity name. */
EcsName :: struct {
    value: *u8;                 /* Entity name */
    symbol: *u8;                /* Optional symbol name, if it differs from name */
    alloc_value: *u8;           /* If set, value will be freed on destruction */
} EcsName;

/* Component information. */
EcsComponent :: struct {
    size: ecs_size_t;           /* Component size */
    alignment: ecs_size_t;      /* Component alignment */
}

/* Component that stores an ecs_type_t.
 * This component allows for the creation of entities that represent a type, and
 * therefore the creation of named types. This component is typically
 * instantiated by ECS_TYPE. */
EcsType :: struct {
    type: ecs_type_t;        /* Preserved nested types */
    normalized: ecs_type_t;  /* Union of type and nested AND types */
}

/* Component that contains lifecycle callbacks for a component. */
EcsComponentLifecycle :: struct {
    ctor: ecs_xtor_t;            /* ctor */
    dtor: ecs_xtor_t;            /* dtor */
    copy: ecs_copy_t;            /* copy assignment */
    move: ecs_move_t;            /* move assignment */

    ctx: *void;                  /* User defined context */

    copy_ctor: ecs_copy_ctor_t;  /* copy ctor (optional, ctor+copy) */
    move_ctor: ecs_move_ctor_t;  /* move ctor (optional, ctor+move) */
    merge: ecs_move_ctor_t;      /* move ctor (optional, ctor+move+dtor) */

    ctor_illegal: bool;          /* cannot default construct */
    copy_illegal: bool;          /* cannot copy assign */
    move_illegal: bool;          /* cannot move assign */
    copy_ctor_illegal: bool;     /* cannot copy construct */
    move_ctor_illegal: bool;     /* cannot move construct (or merge) */

    /* Note that a type must be destructible */
}

/* Component that stores reference to trigger */
EcsTrigger :: struct {
    trigger: *ecs_trigger_t;
}

/* Component that stores reference to observer */
EcsObserver :: struct {
    observer: *ecs_observer_t;
}

/* Component for storing a query */
EcsQuery :: struct {
    query: *ecs_query_t;
}

/* @} */

/*
 * @defgroup misc_types Miscalleneous types
 * @{
 */

/* Type that contains information about the world. */
ecs_world_info_t :: struct {
    last_component_id: ecs_entity_t;        /* Last issued component entity id */
    last_id: ecs_entity_t;                  /* Last issued entity id */
    min_id: ecs_entity_t;                   /* First allowed entity id */
    max_id: ecs_entity_t;                   /* Last allowed entity id */

    delta_time_raw: FLECS_FLOAT;            /* Raw delta time (no time scaling) */
    delta_time: FLECS_FLOAT;                /* Time passed to or computed by ecs_progress */
    time_scale: FLECS_FLOAT;                /* Time scale applied to delta_time */
    target_fps: FLECS_FLOAT;                /* Target fps */
    frame_time_total: FLECS_FLOAT;          /* Total time spent processing a frame */
    system_time_total: FLECS_FLOAT;         /* Total time spent in systems */
    merge_time_total: FLECS_FLOAT;          /* Total time spent in merges */
    world_time_total: FLECS_FLOAT;          /* Time elapsed in simulation */
    world_time_total_raw: FLECS_FLOAT;      /* Time elapsed in simulation (no scaling) */

    frame_count_total: int32_t;             /* Total number of frames */
    merge_count_total: int32_t;             /* Total number of merges */
    pipeline_build_count_total: int32_t;    /* Total number of pipeline builds */
    systems_ran_frame: int32_t;             /* Total number of systems ran in last frame */
}

/* @} */

/*
 * @defgroup type_roles Type Roles
 * @{
 */

/* Type roles are used to indicate the role of an entity in a type. If no flag
 * is specified, the entity is interpreted as a regular component or tag. Flags
 * are added to an entity by using a bitwise OR (|). An example:
 *
 * ecs_entity_t parent = ecs_new(world, 0);
 * ecs_entity_t child = ecs_add_pair(world, e, EcsChildOf, parent);
 *
 * Type flags can also be used in type expressions, without the ECS prefix:
 *
 * ECS_ENTITY(world, Base, Position);
 * ECS_TYPE(world, InstanceOfBase, INSTANCEOF | Base);
 */

/* Role bit added to roles to differentiate between roles and generations */
ECS_ROLE :: cast(u64) 1 << 63;

/* Cases are used to switch between mutually exclusive components */
ECS_CASE: ecs_id_t;

/* Switches allow for fast switching between mutually exclusive components */
ECS_SWITCH: ecs_id_t;

/* The PAIR role indicates that the entity is a pair identifier. */
ECS_PAIR: ecs_id_t;

/* Enforce ownership of a component */
ECS_OWNED: ecs_id_t;

/* Track whether component is enabled or not */
ECS_DISABLED: ecs_id_t;

/* @} */

/*
 * @defgroup builtin_tags Builtin Tags
 * @{
 */

/* Root scope for builtin flecs entities */
EcsFlecs: ecs_entity_t;

/* Core module scope */
EcsFlecsCore: ecs_entity_t;

/* Entity associated with world (used for "attaching" components to world) */
EcsWorld: ecs_entity_t;

/* Wildcard entity ("*"), Used in expressions to indicate wildcard matching */
EcsWildcard: ecs_entity_t;

/* This entity (".", "This"). Used in expressions to indicate This entity */
EcsThis: ecs_entity_t;

/* Can be added to relation to indicate it is transitive. */
EcsTransitive: ecs_entity_t;

/* Can be added to component/relation to indicate it is final. Final components/
 * relations cannot be derived from using an IsA relationship. Queries will not
 * attempt to substitute a component/relationship with IsA subsets if they are
 * final. */
EcsFinal: ecs_entity_t;

/* Can be added to relation to indicate that it should never hold data, even
 * when it or the relation object is a component. */
EcsTag: ecs_entity_t;

/* Used to express parent-child relations. */
EcsChildOf: ecs_entity_t;

/* Used to express is-a relations. An IsA relation indicates that the subject is
 * a subset of the relation object. For example:
 *   ecs_add_pair(world, Freighter, EcsIsA, SpaceShip);
 *
 * Here the Freighter is considered a subset of SpaceShip, meaning that every
 * entity that has Freighter also implicitly has SpaceShip.
 *
 * The subject of the relation (Freighter) inherits all components from any IsA
 * object (SpaceShip). If SpaceShip has a component "MaxSpeed", this component
 * will also appear on Freighter after adding (IsA, SpaceShip) to Freighter.
 *
 * The IsA relation is transitive. This means that if SpaceShip IsA Machine,
 * then Freigther is also a Machine. As a result, Freighter also inherits all
 * components from Machine, just as it does from SpaceShip.
 *
 * Queries/filters may implicitly substitute predicates, subjects and objects
 * with their IsA super/subsets. This behavior can be controlled by the "set"
 * member of a query term.
 */
EcsIsA: ecs_entity_t;

/* Tag added to module entities */
EcsModule: ecs_entity_t;

/* Tag added to prefab entities. Any entity with this tag is automatically
 * ignored by filters/queries, unless EcsPrefab is explicitly added. */
EcsPrefab: ecs_entity_t;

/* When this tag is added to an entity it is skipped by all queries/filters */
EcsDisabled: ecs_entity_t;

/* Tag added to builtin/framework entites. This tag can be used to automatically
 * hide components/systems that are part of infrastructure code vs. application
 * code. The tag has no functional implications. */
EcsHidden: ecs_entity_t;

/* Used to create triggers that subscribe on add events */
EcsOnAdd: ecs_entity_t;

/* Used to create triggers that subscribe on remove events */
EcsOnRemove: ecs_entity_t;

/* Used to create systems that subscribe on set events */
EcsOnSet: ecs_entity_t;

/* Used to create systems that subscribe on unset events */
EcsUnSet: ecs_entity_t;

/* Relationship used to define what should happen when an entity is deleted that
 * is added to other entities. For example, if an entity is used as a tag, and
 * this entity is deleted, this would leave dangling references (ids) to this
 * entity in the storage.
 * This relation, when combined with EcsRemove, EcsDelete or EcsThrow, can be
 * used to customize the deletion behavior. For example:
 *   ecs_add_pair(world, Position, EcsOnDelete, EcsThrow);
 *
 * This would throw an error when attempting to delete Position, if Position is
 * added to any entities at the time of deletion. */
EcsOnDelete: ecs_entity_t;

/* Relationship with similar functionality to EcsDelete, except that it allows
 * for specifying behavior when an object of a relation is removed. For example:
 *   ecs_add_pair(world, EcsChildOf, EcsOnDeleteObject, EcsDelete);
 *
 * This specifies that whenever an object of a ChildOf relation (the parent) is
 * removed, the entities with a relation to that object (the children) should be
 * deleted. */
EcsOnDeleteObject: ecs_entity_t;

/* Specifies that a component/relation/object of relation should be removed when
 * it is deleted. Must be combined with EcsOnDelete or EcsOnDeleteObject. */
EcsRemove: ecs_entity_t;

/* Specifies that entities with a component/relation/object of relation should
 * be deleted when the component/relation/object of relation is deleted. Must be
 * combined with EcsOnDelete or EcsOnDeleteObject. */
EcsDelete: ecs_entity_t;

/* Specifies that whenever a component/relation/object of relation is deleted an
 * error should be thrown. Must be combined with EcsOnDelete or
 * EcsOnDeleteObject. */
EcsThrow: ecs_entity_t;

/* System module tags */
EcsOnDemand: ecs_entity_t;
EcsMonitor: ecs_entity_t;
EcsDisabledIntern: ecs_entity_t;
EcsInactive: ecs_entity_t;

/* Pipeline module tags */
EcsPipeline: ecs_entity_t;
EcsPreFrame: ecs_entity_t;
EcsOnLoad: ecs_entity_t;
EcsPostLoad: ecs_entity_t;
EcsPreUpdate: ecs_entity_t;
EcsOnUpdate: ecs_entity_t;
EcsOnValidate: ecs_entity_t;
EcsPostUpdate: ecs_entity_t;
EcsPreStore: ecs_entity_t;
EcsOnStore: ecs_entity_t;
EcsPostFrame: ecs_entity_t;

/* Value used to quickly check if component is builtin. This is used to quickly
 * filter out tables with builtin components (for example for ecs_delete) */
#define EcsLastInternalComponentId (ecs_id(EcsSystem))

/* The first user-defined component starts from this id. Ids up to this number
 * are reserved for builtin components */
#define EcsFirstUserComponentId (32)

/* The first user-defined entity starts from this id. Ids up to this number
 * are reserved for builtin components */
#define EcsFirstUserEntityId (ECS_HI_COMPONENT_ID + 64)

/* @} */

/*
 * @defgroup convenience_macros Convenience Macro's
 * @{
 */

/* Macro's rely on variadic arguments which are C99 and above */
#ifndef FLECS_LEGACY
/*
 * TODO: Rewrite this macros!!!
 *

/* Declare a component.
 * Example:
 *   ECS_COMPONENT(world, Position);
 */
#ifndef ECS_COMPONENT
#define ECS_COMPONENT(world, id) \
    ecs_id_t ecs_id(id) = ecs_component_init(world, &(ecs_component_desc_t){\
        .entity = {\
            .name = #id,\
            .symbol = #id\
        },\
        .size = sizeof(id),\
        .alignment = ECS_ALIGNOF(id)\
    });\
    (void)ecs_id(id);
#endif

/* Declare an extern component variable.
 * Use this macro in a header when defining a component identifier globally.
 * Must be used together with ECS_COMPONENT_DECLARE.
 *
 * Example:
 *   ECS_COMPONENT_EXTERN(Position);
 */
#ifndef ECS_COMPONENT_EXTERN
#define ECS_COMPONENT_EXTERN(id)\
    extern ecs_id_t ecs_id(id);
#endif

/* Declare a component variable outside the scope of a function.
 * Use this macro in a header when defining a component identifier globally.
 * Must be used together with ECS_COMPONENT_DEFINE.
 *
 * Example:
 *   ECS_COMPONENT_IMPL(Position);
 */
#ifndef ECS_COMPONENT_DECLARE
#define ECS_COMPONENT_DECLARE(id)\
    ecs_id_t ecs_id(id);
#endif

/* Define a component, store in variable outside of the current scope.
 * Use this macro in a header when defining a component identifier globally.
 * Must be used together with ECS_COMPONENT_DECLARE.
 *
 * Example:
 *   ECS_COMPONENT_DEFINE(world, Position);
 */
#ifndef ECS_COMPONENT_DEFINE
#define ECS_COMPONENT_DEFINE(world, id)\
    ecs_id(id)= ecs_component_init(world, &(ecs_component_desc_t){\
        .entity = {\
            .entity = ecs_id(id),\
            .name = #id,\
            .symbol = #id\
        },\
        .size = sizeof(id),\
        .alignment = ECS_ALIGNOF(id)\
    });
#endif

/* Declare a tag.
 * Example:
 *   ECS_TAG(world, MyTag);
 */
#ifndef ECS_TAG
#define ECS_TAG(world, id)\
    ECS_ENTITY(world, id, 0);
#endif

/* Declare an extern tag variable.
 * Use this macro in a header when defining a tag identifier globally.
 * Must be used together with ECS_TAG_DECLARE.
 *
 * Example:
 *   ECS_TAG_EXTERN(Enemy);
 */
#ifndef ECS_TAG_EXTERN
#define ECS_TAG_EXTERN(id)\
    extern ecs_entity_t id;
#endif

/* Declare a tag variable outside the scope of a function.
 * Use this macro in a header when defining a tag identifier globally.
 * Must be used together with ECS_TAG_DEFINE.
 *
 * Example:
 *   ECS_TAG_DECLARE(Enemy);
 */
#ifndef ECS_TAG_DECLARE
#define ECS_TAG_DECLARE(id)\
    ecs_entity_t id;
#endif

/* Define a tag, store in variable outside of the current scope.
 * Use this macro in a header when defining a tag identifier globally.
 * Must be used together with ECS_TAG_DECLARE.
 *
 * Example:
 *   ECS_TAG_DEFINE(world, Enemy);
 */
#ifndef ECS_TAG_DEFINE
#define ECS_TAG_DEFINE(world, id)\
    id = ecs_entity_init(world, &(ecs_entity_desc_t){\
        .name = #id\
    });
#endif

/* Declare a constructor.
 * Example:
 *   ECS_CTOR(MyType, ptr, { ptr->value = NULL; });
 */
#define ECS_CTOR(type, var, ...)\
    ECS_XTOR_IMPL(type, ctor, var, __VA_ARGS__)

/* Declare a destructor.
 * Example:
 *   ECS_DTOR(MyType, ptr, { free(ptr->value); });
 */
#define ECS_DTOR(type, var, ...)\
    ECS_XTOR_IMPL(type, dtor, var, __VA_ARGS__)

/* Declare a copy action.
 * Example:
 *   ECS_COPY(MyType, dst, src, { dst->value = strdup(src->value); });
 */
#define ECS_COPY(type, dst_var, src_var, ...)\
    ECS_COPY_IMPL(type, dst_var, src_var, __VA_ARGS__)

/* Declare a move action.
 * Example:
 *   ECS_MOVE(MyType, dst, src, { dst->value = src->value; src->value = 0; });
 */
#define ECS_MOVE(type, dst_var, src_var, ...)\
    ECS_MOVE_IMPL(type, dst_var, src_var, __VA_ARGS__)

/* Map from typename to function name of component lifecycle action */
#define ecs_ctor(type) type##_ctor
#define ecs_dtor(type) type##_dtor
#define ecs_copy(type) type##_copy
#define ecs_move(type) type##_move

*/

#endif /* FLECS_LEGACY */

/* @} */

/*
 * @defgroup world_api World API
 * @{
 */

/* Create a new world.
 * A world manages all the ECS data and supporting infrastructure. Applications
 * must have at least one world. Entities, component and system handles are
 * local to a world and should not be shared between worlds.
 *
 * This operation creates a world with all builtin modules loaded.
 *
 * @return A new world object
 */
ecs_init :: () -> *ecs_world_t #foreign flecs;

/* Same as ecs_init, but with minimal set of modules loaded.
 *
 * @return A new world object
 */
ecs_mini :: () -> *ecs_world_t;

/* Create a new world with arguments.
 * Same as ecs_init, but allows passing in command line arguments. These can be
 * used to dynamically enable flecs features to an application. Currently these
 * arguments are not used.
 *
 * @return A new world object
 */
ecs_init_w_args :: (
    argc: s32,
    argv: [] *u8) -> *ecs_world_t #foreign flecs;

/* Delete a world.
 * This operation deletes the world, and everything it contains.
 *
 * @param world The world to delete.
 * @return Zero if successful, non-zero if failed.
 */
ecs_fini :: (
    world: *ecs_world_t) -> s32 #foreign flecs;

/* Register action to be executed when world is destroyed.
 * Fini actions are typically used when a module needs to clean up before a
 * world shuts down.
 *
 * @param world The world.
 * @param action The function to execute.
 * @param ctx Userdata to pass to the function */
ecs_atfini :: (
    world: *ecs_world_t,
    action: ecs_fini_action_t,
    ctx: *void) #foreign flecs;

/* Register action to be executed once after frame.
 * Post frame actions are typically used for calling operations that cannot be
 * invoked during iteration, such as changing the number of threads.
 *
 * @param world The world.
 * @param action The function to execute.
 * @param ctx Userdata to pass to the function */
ecs_run_post_frame :: (
    world: *ecs_world_t,
    action:ecs_fini_action_t,
    ctx: *void) #foreign flecs;

/* Signal exit
 * This operation signals that the application should quit. It will cause
 * ecs_progress to return false.
 *
 * @param world The world to quit.
 */
ecs_quit :: (
    world: *ecs_world_t) #foreign flecs;

/* Return whether a quit has been signaled.
 *
 * @param world The world.
 */
ecs_should_quit :: (
    world: *ecs_world_t) -> bool #foreign flecs;

/* Register ctor, dtor, copy & move actions for component.
 *
 * @param world The world.
 * @param component The component id for which to register the actions
 * @param actions Type that contains the component actions.
 */
ecs_set_component_actions_w_id :: (
    world: *ecs_world_t,
    id: ecs_id_t,
    actions: *EcsComponentLifecycle) #foreign flecs;

/* Set a world context.
 * This operation allows an application to register custom data with a world
 * that can be accessed anywhere where the application has the world object.
 *
 * @param world The world.
 * @param ctx A pointer to a user defined structure.
 */
ecs_set_context ::(
    world: *ecs_world_t,
    ctx: *void) #foreign flecs;

/* Get the world context.
 * This operation retrieves a previously set world context.
 *
 * @param world The world.
 * @return The context set with ecs_set_context. If no context was set, the
 *         function returns NULL.
 */
ecs_get_context :: (
    world: *ecs_world_t) -> *void #foreign flecs;

/* Get world info.
 *
 * @param world The world.
 * @return Pointer to the world info. This pointer will remain valid for as long
 *         as the world is valid.
 */
ecs_get_world_info :: (
    world: *ecs_world_t) -> *ecs_world_info_t #foreign flecs;

/* Dimension the world for a specified number of entities.
 * This operation will preallocate memory in the world for the specified number
 * of entities. Specifying a number lower than the current number of entities in
 * the world will have no effect. Note that this function does not allocate
 * memory for components (use ecs_dim_type for that).
 *
 * @param world The world.
 * @param entity_count The number of entities to preallocate.
 */
ecs_dim :: (
    world: *ecs_world_t,
    entity_count: int32_t) #foreign flecs;

/* Set a range for issueing new entity ids.
 * This function constrains the entity identifiers returned by ecs_new to the
 * specified range. This operation can be used to ensure that multiple processes
 * can run in the same simulation without requiring a central service that
 * coordinates issueing identifiers.
 *
 * If id_end is set to 0, the range is infinite. If id_end is set to a non-zero
 * value, it has to be larger than id_start. If id_end is set and ecs_new is
 * invoked after an id is issued that is equal to id_end, the application will
 * abort.
 *
 * @param world The world.
 * @param id_start The start of the range.
 * @param id_end The end of the range.
 */
ecs_set_entity_range :: (
    world: *ecs_world_t,
    id_start: ecs_entity_t,
    id_end: ecs_entity_t) #foreign flecs;

/* Enable/disable range limits.
 * When an application is both a receiver of range-limited entities and a
 * producer of range-limited entities, range checking needs to be temporarily
 * disabled when inserting received entities. Range checking is disabled on a
 * stage, so setting this value is thread safe.
 *
 * @param world The world.
 * @param enable True if range checking should be enabled, false to disable.
 * @return The previous value.
 */
ecs_enable_range_check :: (
    world: *ecs_world_t,
    enable: bool) -> bool #foreign flecs;

/* Enable world locking while in progress.
 * When locking is enabled, Flecs will lock the world while in progress. This
 * allows applications to interact with the world from other threads without
 * running into race conditions.
 *
 * This is a better alternative to applications putting a lock around calls to
 * ecs_progress, since ecs_progress can sleep when FPS control is enabled,
 * which is time during which other threads could perform work.
 *
 * Locking must be enabled before applications can use the ecs_lock and
 * ecs_unlock functions. Locking is turned off by default.
 *
 * @param world The world.
 * @param enable True if locking is to be enabled.
 * @result The previous value of the setting.
 */
ecs_enable_locking :: (
    world: *ecs_world_t,
    enable: bool) -> bool #foreign flecs;

/* Locks the world.
 * See ecs_enable_locking for details.
 *
 * @param world The world.
 */
ecs_lock :: (
    world: *ecs_world_t) #foreign flecs;

/* Unlocks the world.
 * See ecs_enable_locking for details.
 *
 * @param world The world.
 */
ecs_unlock :: (
    world: *ecs_world_t) #foreign flecs;

/* Wait until world becomes available.
 * When a non-flecs thread needs to interact with the world, it should invoke
 * this function to wait until the world becomes available (as in, it is not
 * progressing the frame). Invoking this function guarantees that the thread
 * will not starve. (as opposed to simply taking the world lock).
 *
 * An application will have to invoke ecs_end_wait after this function returns.
 *
 * @param world The world.
 */
ecs_begin_wait :: (
    world: *ecs_world_t) #foreign flecs;

/* Release world after calling ecs_begin_wait.
 * This operation should be invoked after invoking ecs_begin_wait, and will
 * release the world back to the thread running the main loop.
 *
 * @param world The world.
 */
ecs_end_wait :: (
    world: *ecs_world_t) #foreign flecs;

/* Enable or disable tracing.
 * This will enable builtin tracing. For tracing to work, it will have to be
 * compiled in which requires defining one of the following macro's:
 *
 * ECS_TRACE_0 - All tracing is disabled
 * ECS_TRACE_1 - Enable tracing level 1
 * ECS_TRACE_2 - Enable tracing level 2 and below
 * ECS_TRACE_3 - Enable tracing level 3 and below
 *
 * If no tracing level is defined and this is a debug build, ECS_TRACE_3 will
 * have been automatically defined.
 *
 * The provided level corresponds with the tracing level. If -1 is provided as
 * value, warnings are disabled. If -2 is provided, errors are disabled as well.
 *
 * @param level Desired tracing level.
 */
ecs_tracing_enable :: (level: s32) #foreign flecs;

/* Measure frame time.
 * Frame time measurements measure the total time passed in a single frame, and
 * how much of that time was spent on systems and on merging.
 *
 * Frame time measurements add a small constant-time overhead to an application.
 * When an application sets a target FPS, frame time measurements are enabled by
 * default.
 *
 * @param world The world.
 * @param enable Whether to enable or disable frame time measuring.
 */
ecs_measure_frame_time :: (
    world: *ecs_world_t,
    enable: bool) #foreign flecs;

/* Measure system time.
 * System time measurements measure the time spent in each system.
 *
 * System time measurements add overhead to every system invocation and
 * therefore have a small but measurable impact on application performance.
 * System time measurements must be enabled before obtaining system statistics.
 *
 * @param world The world.
 * @param enable Whether to enable or disable system time measuring.
 */
ecs_measure_system_time :: (
    world: *ecs_world_t,
    enable: bool) #foreign flecs;

/* Set target frames per second (FPS) for application.
 * Setting the target FPS ensures that ecs_progress is not invoked faster than
 * the specified FPS. When enabled, ecs_progress tracks the time passed since
 * the last invocation, and sleeps the remaining time of the frame (if any).
 *
 * This feature ensures systems are ran at a consistent interval, as well as
 * conserving CPU time by not running systems more often than required.
 *
 * Note that ecs_progress only sleeps if there is time left in the frame. Both
 * time spent in flecs as time spent outside of flecs are taken into
 * account.
 *
 * @param world The world.
 * @param fps The target FPS.
 */
ecs_set_target_fps :: (
    world: *ecs_world_t,
    fps: FLECS_FLOAT) #foreign flecs;

/* Get current number of threads. */
ecs_get_threads :: (
    world: *ecs_world_t) -> int32_t #foreign flecs;

/* @} */

/*
 * @defgroup creating_entities Creating Entities
 * @{
 */

/* Create new entity id.
 * This operation returns an unused entity id.
 *
 * @param world The world.
 * @return The new entity id.
 */
ecs_new_id :: (
    world: *ecs_world_t) -> ecs_entity_t #foreign flecs;

/* Create new component id.
 * This operation returns a new component id. Component ids are the same as
 * entity ids, but can make use of the [1 .. ECS_HI_COMPONENT_ID] range.
 *
 * This operation does not recycle ids.
 *
 * @param world The world.
 * @return The new component id.
 */
ecs_new_component_id :: (
    world: *ecs_world_t) -> ecs_entity_t #foreign flecs;

/* Create new entity.
 * This operation creates a new entity with a single entity in its type. The
 * entity may contain type roles. This operation recycles ids.
 *
 * @param world The world.
 * @param entity The entity to initialize the new entity with.
 * @return The new entity.
 */
ecs_new_w_id :: (
    world: *ecs_world_t,
    id: ecs_id_t) -> ecs_entity_t #foreign flecs;

/* Find or create an entity.
 * This operation creates a new entity, or modifies an existing one. When a name
 * is set in the ecs_entity_desc_t::name field and ecs_entity_desc_t::entity is
 * not set, the operation will first attempt to find an existing entity by that
 * name. If no entity with that name can be found, it will be created.
 *
 * If both a name and entity handle are provided, the operation will check if
 * the entity name matches with the provided name. If the names do not match,
 * the function will fail and return 0.
 *
 * If an id to a non-existing entity is provided, that entity id become alive.
 *
 * See the documentation of ecs_entity_desc_t for more details.
 *
 * @param world The world.
 * @param desc Entity init parameters.
 * @return A handle to the new or existing entity, or 0 if failed.
 */
ecs_entity_init :: (
    world: *ecs_world_t,
    desc: *ecs_entity_desc_t) -> ecs_entity_t #foreign flecs;

/* Find or create a component.
 * This operation creates a new component, or finds an existing one. The find or
 * create behavior is the same as ecs_entity_init.
 *
 * When an existing component is found, the size and alignment are verified with
 * the provided values. If the values do not match, the operation will fail.
 *
 * See the documentation of ecs_component_desc_t for more details.
 *
 * @param world The world.
 * @param desc Component init parameters.
 * @return A handle to the new or existing component, or 0 if failed.
 */
ecs_component_init :: (
    world: *ecs_world_t,
    desc: *ecs_component_desc_t) -> ecs_entity_t #foreign flecs;

/* Create a new type entity.
 * This operation creates a new type entity, or finds an existing one. The find
 * or create behavior is the same as ecs_entity_init.
 *
 * A type entity is an entity with the EcsType component. This component
 * a pointer to an ecs_type_t, which allows for the creation of named types.
 * Named types are used in a few places, such as for pipelines and filter terms
 * with the EcsAndFrom or EcsOrFrom operators.
 *
 * When an existing type entity is found, its types are verified with the
 * provided values. If the values do not match, the operation will fail.
 *
 * See the documentation of ecs_type_desc_t for more details.
 *
 * @param world The world.
 * @param desc Type entity init parameters.
 * @return A handle to the new or existing type, or 0 if failed.
*/
ecs_type_init :: (
    world: *ecs_world_t,
    desc: *ecs_type_desc_t) -> ecs_entity_t #foreign flecs;

/* Create N new entities.
 * This operation is the same as ecs_new_w_id, but creates N entities
 * instead of one and does not recycle ids.
 *
 * @param world The world.
 * @param entity The entity.
 * @param count The number of entities to create.
 * @return The first entity id of the newly created entities.
 */
ecs_bulk_new_w_id :: (
    world: *ecs_world_t,
    id: ecs_id_t,
    count: int32_t) -> *ecs_entity_t #foreign flecs;

/* Create N new entities and initialize components.
 * This operation is the same as ecs_bulk_new_w_type, but initializes components
 * with the provided component array. Instead of a type the operation accepts an
 * array of component identifiers (entities). The component arrays need to be
 * provided in the same order as the component identifiers.
 *
 * @param world The world.
 * @param components Array with component identifiers.
 * @param count The number of entities to create.
 * @param data The data arrays to initialize the components with.
 * @return The first entity id of the newly created entities.
 */
ecs_bulk_new_w_data :: (
    world: *ecs_world_t,
    count: int32_t,
    component_ids: *ecs_ids_t,
    data: *void) -> *ecs_entity_t #foreign flecs;

/* Clone an entity
 * This operation clones the components of one entity into another entity. If
 * no destination entity is provided, a new entity will be created. Component
 * values are not copied unless copy_value is true.
 *
 * @param world The world.
 * @param dst The entity to copy the components to.
 * @param src The entity to copy the components from.
 * @param copy_value If true, the value of components will be copied to dst.
 * @return The destination entity.
 */
ecs_clone :: (
    world: *ecs_world_t,
    dst: ecs_entity_t,
    src: ecs_entity_t,
    copy_value: bool) -> ecs_entity_t #foreign flecs;

/* @} */

/*
 * @defgroup adding_removing Adding & Removing
 * @{
 */

/* Add an entity to an entity.
 * This operation adds a single entity to the type of an entity. Type roles may
 * be used in combination with the added entity. If the entity already has the
 * entity, this operation will have no side effects.
 *
 * @param world The world.
 * @param entity The entity.
 * @param id The id to add.
 */
ecs_add_id :: (
    world: *ecs_world_t,
    entity: ecs_entity_t,
    id: ecs_id_t) #foreign flecs;

/* Remove an entity from an entity.
 * This operation removes a single entity from the type of an entity. Type roles
 * may be used in combination with the added entity. If the entity does not have
 * the entity, this operation will have no side effects.
 *
 * @param world The world.
 * @param entity The entity.
 * @param id The id to remove.
 */
ecs_remove_id :: (
    world: *ecs_world_t,
    entity: ecs_entity_t,
    id: ecs_id_t) #foreign flecs;

/* @} */

/*
 * @defgroup enabling_disabling Enabling & Disabling components.
 * @{
 */

/* Enable or disable component.
 * Enabling or disabling a component does not add or remove a component from an
 * entity, but prevents it from being matched with queries. This operation can
 * be useful when a component must be temporarily disabled without destroying
 * its value. It is also a more performant operation for when an application
 * needs to add/remove components at high frequency, as enabling/disabling is
 * cheaper than a regular add or remove.
 *
 * @param world The world.
 * @param entity The entity.
 * @param id The component.
 * @param enable True to enable the component, false to disable.
 */
ecs_enable_component_w_id :: (
    world: *ecs_world_t,
    entity: ecs_entity_t,
    id: ecs_id_t,
    enable: bool) #foreign flecs;

/* Test if component is enabled.
 * Test whether a component is currently enabled or disabled. This operation
 * will return true when the entity has the component and if it has not been
 * disabled by ecs_enable_component.
 *
 * @param world The world.
 * @param entity The entity.
 * @param id The component.
 * @return True if the component is enabled, otherwise false.
 */
ecs_is_component_enabled_w_id :: (
    world: *ecs_world_t,
    entity: ecs_entity_t,
    id: ecs_id_t) -> bool #foreign flecs;

/* @} */

// /*
//  * @defgroup pairs Pairs
//  * @{
//  */

// /* Make a pair identifier.
//  * This function is equivalent to using the ecs_pair macro, and is added for
//  * convenience to make it easier for non C/C++ bindings to work with pairs.
//  *
//  * @param relation The relation of the pair.
//  * @param object The object of the pair.
//  */
// ecs_make_pair :: (
//     relation: ecs_entity_t,
//     object: ecs_entity_t) -> ecs_id_t #foreign flecs;

// /* This operation accepts regular entities. For passing in component identifiers
//  * use ecs_typeid, like this:
//  *
//  * ecs_new_w_pair(world, ecs_id(relation), object)
//  *
//  * @param world The world.
//  * @param relation The relation part of the pair to add.
//  * @param object The object part of the pair to add.
//  * @return The new entity.
//  */
// ecs_new_w_pair :: inline (world: *ecs_world_t, relation: ecs_entity_t, object: ecs_entity_t) -> ecs_entity_t {
//     return ecs_new_w_id(world, ecs_pair(relation, object));
// }

// /* Add a pair.
//  * This operation adds a pair to an entity. A pair is a combination of a
//  * relation and an object, can can be used to store relationships between
//  * entities. Example:
//  *
//  * subject = Alice, relation = Likes, object = Bob
//  *
//  * This operation accepts regular entities. For passing in component identifiers
//  * use ecs_typeid, like this:
//  *
//  * ecs_add_pair(world, subject, ecs_id(relation), object)
//  *
//  * @param world The world.
//  * @param subject The entity to which to add the pair.
//  * @param relation The relation part of the pair to add.
//  * @param object The object part of the pair to add.
//  */
// ecs_add_pair :: inline (world: *ecs_world_t, subject: ecs_entity_t, relation: ecs_entity_t, object: ecs_entity_t) {
//     ecs_add_id(world, subject, ecs_pair(relation, object));
// }

// /* Remove a pair.
//  * This operation removes a pair from an entity. A pair is a combination of a
//  * relation and an object, can can be used to store relationships between
//  * entities. Example:
//  *
//  * subject = Alice, relation = Likes, object = Bob
//  *
//  * This operation accepts regular entities. For passing in component identifiers
//  * use ecs_typeid, like this:
//  *
//  * ecs_remove_pair(world, subject, ecs_id(relation), object)
//  *
//  * @param world The world.
//  * @param subject The entity from which to remove the pair.
//  * @param relation The relation part of the pair to remove.
//  * @param object The object part of the pair to remove.
//  */
// ecs_remove_pair :: inline (world: *ecs_world_t, subject: ecs_entity_t, relation: ecs_entity_t, object: ecs_entity_t) {
//     ecs_remove_id(world, subject, ecs_pair(relation, object));
// }

// /* Test for a pair.
//  * This operation tests if an entity has a pair. This operation accepts regular
//  * entities. For passing in component identifiers use ecs_typeid, like this:
//  *
//  * ecs_has_pair(world, subject, ecs_id(relation), object)
//  *
//  * @param world The world.
//  * @param subject The entity from which to remove the pair.
//  * @param relation The relation part of the pair to remove.
//  * @param object The object part of the pair to remove.
//  */
// ecs_has_pair :: inline (world: *ecs_world_t, subject: ecs_entity_t, relation: ecs_entity_t, object: ecs_entity_t) -> bool {
//     return ecs_has_id(world, subject, ecs_pair(relation, object));
// }

// #ifndef FLECS_LEGACY

// /* Set relation of pair.
//  * This operation sets data for a pair, where the relation determines the type.
//  * A pair is a combination of a relation and an object, can can be used to store
//  * relationships between entities.
//  *
//  * Pairs can contain data if either the relation or object of the pair are a
//  * component. If both are a component, the relation takes precedence.
//  *
//  * If this operation is used with a pair where the relation is not a component,
//  * it will fail. The object part of the pair expects a regular entity. To pass
//  * a component as object, use ecs_typeid like this:
//  *
//  * ecs_set_pair(world, subject, relation, ecs_id(object))
//  *
//  * @param world The world.
//  * @param subject The entity on which to set the pair.
//  * @param relation The relation part of the pair. This must be a component.
//  * @param object The object part of the pair.
//  */
// #define ecs_set_pair(world, subject, relation, object, ...)\
//     ecs_set_id(world, subject,\
//         ecs_pair(ecs_id(relation), object),\
//         sizeof(relation), &(relation)__VA_ARGS__)


// /* Set object of pair.
//  * This operation sets data for a pair, where the object determines the type.
//  * A pair is a combination of a relation and an object, can can be used to store
//  * relationships between entities.
//  *
//  * Pairs can contain data if either the relation or object of the pair are a
//  * component. If both are a component, the relation takes precedence.
//  *
//  * If this operation is used with a pair where the object is not a component,
//  * it will fail. The relation part of the pair expects a regular entity. To pass
//  * a component as relation, use ecs_typeid like this:
//  *
//  * ecs_set_pair_object(world, subject, ecs_id(relation), object)
//  *
//  * @param world The world.
//  * @param subject The entity.
//  * @param relation The relation part of the pair.
//  * @param object The object part of the pair. This must be a component.
//  */
// #define ecs_set_pair_object(world, subject, relation, object, ...)\
//     ecs_set_id(world, subject,\
//         ecs_pair(relation, ecs_id(object)),\
//         sizeof(object), &(object)__VA_ARGS__)

// #define ecs_get_mut_pair(world, subject, relation, object, is_added)\
//     (ECS_CAST(relation*, ecs_get_mut_w_id(world, subject,\
//         ecs_pair(ecs_id(relation), object), is_added)))

// #define ecs_get_mut_pair_object(world, subject, relation, object, is_added)\
//     (ECS_CAST(object*, ecs_get_mut_w_id(world, subject,\
//         ecs_pair(relation, ecs_id(object)), is_added)))

// #define ecs_modified_pair(world, subject, relation, object)\
//     ecs_modified_w_id(world, subject, ecs_pair(relation, object))

// #endif

// /* Get relation of pair.
//  * This operation obtains the value of a pair, where the relation determines the
//  * type. A pair is a combination of a relation and an object, can can be used to
//  * store relationships between entities.
//  *
//  * Pairs can contain data if either the relation or object of the pair are a
//  * component. If both are a component, the relation takes precedence.
//  *
//  * If this operation is used with a pair where the relation is not a component,
//  * it will fail. The object part of the pair expects a regular entity. To pass
//  * a component as relation, use ecs_typeid like this:
//  *
//  * ecs_get_pair(world, subject, relation, ecs_id(object))
//  *
//  * @param world The world.
//  * @param subject The entity.
//  * @param relation The relation part of the pair. Must be a component.
//  * @param object The object part of the pair.
//  */
// #define ecs_get_pair(world, subject, relation, object)\
//     (ECS_CAST(relation*, ecs_get_id(world, subject,\
//         ecs_pair(ecs_id(relation), object))))

// /* Get object of pair.
//  * This operation obtains the value of a pair, where the object determines the
//  * type. A pair is a combination of a relation and an object, can can be used to
//  * store relationships between entities.
//  *
//  * Pairs can contain data if either the relation or object of the pair are a
//  * component. If both are a component, the relation takes precedence.
//  *
//  * If this operation is used with a pair where the object is not a component,
//  * it will fail. The relation part of the pair expects a regular entity. To pass
//  * a component as relation, use ecs_typeid like this:
//  *
//  * ecs_get_pair_object(world, subject, ecs_id(relation), object)
//  *
//  * @param world The world.
//  * @param subject The entity.
//  * @param relation The relation part of the pair. Must be a component.
//  * @param object The object part of the pair.
//  */
// #define ecs_get_pair_object(world, subject, relation, object)\
//     (ECS_CAST(object*, ecs_get_id(world, subject,\
//         ecs_pair(relation, ecs_id(object)))))

// /* @} */


/*
 * @defgroup deleting Deleting Entities and components
 * @{
 */

/* Clear all components.
 * This operation will clear all components from an entity but will not delete
 * the entity itself. This effectively prevents the entity id from being
 * recycled.
 *
 * @param world The world.
 * @param entity The entity.
 */
ecs_clear :: (
    world: *ecs_world_t,
    entity: ecs_entity_t) #foreign flecs;

/* Delete an entity.
 * This operation will delete an entity and all of its components. The entity id
 * will be recycled. Repeatedly calling ecs_delete without ecs_new,
 * ecs_new_w_id or ecs_new_w_type will cause a memory leak as it will cause
 * the list with ids that can be recycled to grow unbounded.
 *
 * @param world The world.
 * @param entity The entity.
 */
ecs_delete :: (
    world: *ecs_world_t,
    entity: ecs_entity_t) #foreign flecs;


/* Delete children of an entity.
 * This operation deletes all children of a parent entity. If a parent has no
 * children this operation has no effect.
 *
 * @param world The world.
 * @param parent The parent entity.
 */
ecs_delete_children :: (
    world: *ecs_world_t,
    parent: ecs_entity_t) #foreign flecs;

/* @} */

/*
 * @defgroup getting Getting Components
 * @{
 */

/* Get an immutable pointer to a component.
 * This operation obtains a pointer to the requested component. The
 * operation accepts the component entity id.
 *
 * @param world The world.
 * @param entity The entity.
 * @param component The entity id of the component to obtain.
 * @return The component pointer, NULL if the entity does not have the component.
 */
ecs_get_id :: (
    world: *ecs_world_t,
    entity: ecs_entity_t,
    id: ecs_id_t) -> *void #foreign flecs;


// /* Get an immutable pointer to a component.
//  * Same as ecs_get_id, but accepts the typename of a component.
//  *
//  * @param world The world.
//  * @param entity The entity.
//  * @param id The component to obtain.
//  * @return The component pointer, NULL if the entity does not have the component.
//  */
// #define ecs_get(world, entity, component)\
//     (ECS_CAST(component*, ecs_get_id(world, entity, ecs_id(component))))

/* -- Get cached pointer -- */

/* Get an immutable reference to a component.
 * This operation is similar to ecs_get_id but it stores temporary
 * information in a `ecs_ref_t` value which allows subsequent lookups to be
 * faster.
 *
 * @param world The world.
 * @param ref Pointer to a ecs_ref_t value. Must be initialized.
 * @param entity The entity.
 * @param component The entity id of the component to obtain.
 * @return The component pointer, NULL if the entity does not have the component.
 */
ecs_get_ref_w_id :: (
    world: *ecs_world_t,
    ref: *ecs_ref_t,
    entity: ecs_entity_t,
    id: ecs_id_t) -> *void #foreign flecs;

// /* Get an immutable reference to a component.
//  * Same as ecs_get_ref_w_id, but accepts the typename of a component.
//  *
//  * @param world The world.
//  * @param ref Pointer to a ecs_ref_t value. Must be initialized.
//  * @param entity The entity.
//  * @param id The component to obtain.
//  * @return The component pointer, NULL if the entity does not have the component.
//  */
// #define ecs_get_ref(world, ref, entity, component)\
//     (ECS_CAST(component*, ecs_get_ref_w_id(world, ref, entity, ecs_id(component))))

/* Get case for switch.
 * This operation gets the current case for the specified switch. If the current
 * switch is not set for the entity, the operation will return 0.
 *
 * @param world The world.
 * @param e The entity.
 * @param sw The switch for which to obtain the case.
 * @return The current case for the specified switch.
 */
ecs_get_case :: (
    world: *ecs_world_t,
    e: ecs_entity_t,
    sw: ecs_entity_t) -> ecs_entity_t #foreign flecs;

/* @} */

/*
 * @defgroup setting Setting Components
 * @{
 */

/* Get a mutable pointer to a component.
 * This operation is similar to ecs_get_id but it returns a mutable
 * pointer. If this operation is invoked from inside a system, the entity will
 * be staged and a pointer to the staged component will be returned.
 *
 * If the entity did not yet have the component, the component will be added by
 * this operation. In this case the is_added out parameter will be set to true.
 *
 * @param world The world.
 * @param entity The entity.
 * @param id The entity id of the component to obtain.
 * @param is_added Out parameter that returns true if the component was added.
 * @return The component pointer.
 */
ecs_get_mut_w_id :: (
    world: *ecs_world_t,
    entity: ecs_entity_t,
    id: ecs_id_t,
    is_added: *bool) -> *void #foreign flecs;

// /* Get a mutable pointer to a component.
//  * Same as ecs_get_mut_w_id but accepts a component typename.
//  *
//  * @param world The world.
//  * @param entity The entity.
//  * @param id The component to obtain.
//  * @param is_added Out parameter that returns true if the component was added.
//  * @return The component pointer.
//  */
// #define ecs_get_mut(world, entity, component, is_added)\
//     (ECS_CAST(component*, ecs_get_mut_w_id(world, entity, ecs_id(component), is_added)))

/* Signal that a component has been modified.
 * This operation allows an application to signal to Flecs that a component has
 * been modified. As a result, OnSet systems will be invoked.
 *
 * This operation is commonly used together with ecs_get_mut.
 *
 * @param world The world.
 * @param entity The entity.
 * @param component The entity id of the component that was modified.
 */
ecs_modified_w_id :: (
    world: *ecs_world_t,
    entity: ecs_entity_t,
    id: ecs_id_t) #foreign flecs;

// /* Signal that a component has been modified.
//  * Same as ecs_modified_w_id but accepts a component typename.
//  *
//  * @param world The world.
//  * @param entity The entity.
//  * @param id The component that was modified.
//  */
// #define ecs_modified(world, entity, component)\
//     ecs_modified_w_id(world, entity, ecs_id(component))

/* Set the value of a component.
 * This operation allows an application to set the value of a component. The
 * operation is equivalent to calling ecs_get_mut and ecs_modified.
 *
 * If the provided entity is 0, a new entity will be created.
 *
 * @param world The world.
 * @param entity The entity.
 * @param component The entity id of the component to set.
 * @param size The size of the pointer to the value.
 * @param ptr The pointer to the value.
 * @return The entity. A new entity if no entity was provided.
 */
ecs_set_id :: (
    world: *ecs_world_t,
    entity: ecs_entity_t,
    id: ecs_id_t,
    size: size_t,
    ptr: *void) -> ecs_entity_t #foreign flecs;

// /* Set the value of a component.
//  * Same as ecs_set_id, but accepts a component typename and
//  * automatically determines the type size.
//  *
//  * @param world The world.
//  * @param entity The entity.
//  * @param component The component to set.
//  * @param size The size of the pointer to the value.
//  * @return The entity. A new entity if no entity was provided.
//  */
// #define ecs_set_ptr(world, entity, component, ptr)\
//     ecs_set_id(world, entity, ecs_id(component), sizeof(component), ptr)

// /* Conditionally skip macro's as compound literals and variadic arguments are
//  * not supported in C89 */
// #ifndef FLECS_LEGACY

// /* Set the value of a component.
//  * Same as ecs_set_ptr, but accepts a value instead of a pointer to a value.
//  *
//  * @param world The world.
//  * @param entity The entity.
//  * @param component The component to set.
//  * @param size The size of the pointer to the value.
//  * @return The entity. A new entity if no entity was provided.
//  */
// #define ecs_set(world, entity, component, ...)\
//     ecs_set_id(world, entity, ecs_id(component), sizeof(component), &(component)__VA_ARGS__)

// #endif

/* @} */

// /*
//  * @defgroup singleton Singleton components
//  * @{
//  */

// #define ecs_singleton_get(world, comp)\
//     ecs_get(world, ecs_id(comp), comp)

// #ifndef FLECS_LEGACY
// #define ecs_singleton_set(world, comp, ...)\
//     ecs_set(world, ecs_id(comp), comp, __VA_ARGS__)
// #endif

// #define ecs_singleton_get_mut(world, comp)\
//     ecs_get_mut(world, ecs_id(comp), comp, NULL)

// #define ecs_singleton_modified(world, comp)\
//     ecs_modified(world, ecs_id(comp), comp)

/*
 * @defgroup testing Testing Components
 * @{
 */

/* Test if an entity has an entity.
 * This operation returns true if the entity has the provided entity in its
 * type.
 *
 * @param world The world.
 * @param entity The entity.
 * @param id The id to test for.
 * @return True if the entity has the entity, false if not.
 */
ecs_has_id :: (
    world: *ecs_world_t,
    entity: ecs_entity_t,
    id: ecs_id_t) -> bool #foreign flecs;

// /* Test if an entity has a component, type or tag.
//  * This operation returns true if the entity has the provided component, type or
//  * tag in its type.
//  *
//  * @param world The world.
//  * @param entity The entity.
//  * @param type The component, type or tag to test for.
//  * @return True if the entity has the type, false if not.
//  */
// #ifndef ecs_has
// #define ecs_has(world, entity, type)\
//     ecs_has_id(world, entity, ecs_id(type))
// #endif

// /* Test if an entity owns an entity.
//  * This operation is similar to ecs_has, but will return false if the entity
//  * does not own the entity, which is the case if the entity is defined on
//  * a base entity with an INSTANCEOF role.
//  *
//  * @param world The world.
//  * @param entity The entity.
//  * @param type The entity to test for.
//  * @return True if the entity owns the entity, false if not.
//  */
// #ifndef ecs_owns
// #define ecs_owns(world, entity, has, owned)\
//     ecs_type_owns_id(world, ecs_get_type(world, entity), has, owned)
// #endif

/* @} */

/*
 * @defgroup metadata Entity Metadata
 * @{
 */

/* Test whether an entity is valid.
 * An entity is valid if it is not 0 and if it is alive. If the provided id has
 * a role or a pair, the contents of the role or the pair will be checked for
 * validity.
 *
 * @param world The world.
 * @param e The entity.
 * @return True if the entity is valid, false if the entity is not valid.
 */
ecs_is_valid :: (
    world: *ecs_world_t,
    e: ecs_entity_t) -> bool #foreign flecs;

/* Test whether an entity is alive.
 *
 * @param world The world.
 * @param e The entity.
 * @return True if the entity is alive, false if the entity is not alive.
 */
ecs_is_alive :: (
    world: *ecs_world_t,
    e: ecs_entity_t) -> bool #foreign flecs;

/* Get alive identifier.
 * In some cases an application may need to work with identifiers from which
 * the generation has been stripped. A typical scenario in which this happens is
 * when iterating relationships in an entity type.
 *
 * For example, when obtaining the parent id from a ChildOf relation, the parent
 * (object part of the pair) will have been stored in a 32 bit value, which
 * cannot store the entity generation. This function can retrieve the identifier
 * with the current generation for that id.
 *
 * If the provided identifier is not alive, the function will return 0.
 *
 * @param world The world.
 * @param e The for which to obtain the current alive entity id.
 * @return The alive entity id if there is one, or 0 if the id is not alive.
 */
ecs_get_alive :: (
    world: *ecs_world_t,
    e: ecs_entity_t) -> ecs_entity_t #foreign flecs;

/* Ensure id is alive.
 * This operation ensures that the provided id is alive. This is useful in
 * scenarios where an application has an existing id that has not been created
 * with ecs_new (such as a global constant or an id from a remote application).
 *
 * Before this operation the id must either not yet exist, or must exist with
 * the same generation as the provided id. If the id has been recycled and the
 * provided id does not have the same generation count, the function will fail.
 *
 * If the provided entity is not alive, and the provided generation count is
 * equal to the current generation (which is the future generation when the id
 * will be recycled) the id will become alive again.
 *
 * If the provided id has a non-zero generation count and the id does not exist
 * in the world, the id will be created with the specified generation.
 *
 * This behavior ensures that an application can use ecs_ensure to track the
 * lifecycle of an id without explicitly having to create it. It also protects
 * against reviving an id with a generation count that was not yet due.
 *
 * @param world The world.
 * @param entity The entity id to make alive.
 */
ecs_ensure :: (
    world: *ecs_world_t,
    e: ecs_entity_t) #foreign flecs;

/* Test whether an entity exists.
 * Similar as ecs_is_alive, but ignores entity generation count.
 *
 * @param world The world.
 * @param e The entity.
 * @return True if the entity exists, false if the entity does not exist.
 */
ecs_exists :: (
    world: *ecs_world_t,
    e: ecs_entity_t) ->bool #foreign flecs;

/* Get the type of an entity.
 *
 * @param world The world.
 * @param entity The entity.
 * @return The type of the entity, NULL if the entity has no components.
 */
ecs_get_type :: (
    world: *ecs_world_t,
    entity: ecs_entity_t) ->ecs_type_t #foreign flecs;

/* Get the typeid of an entity.
 *
 * @param world The world.
 * @param entity The entity.
 * @return The typeid of the entity.
 */
ecs_get_typeid :: (
    world: *ecs_world_t,
    e: ecs_id_t) ->ecs_entity_t #foreign flecs;

/* Get the name of an entity.
 * This will return the name as specified in the EcsName component.
 *
 * @param world The world.
 * @param entity The entity.
 * @return The type of the entity, NULL if the entity has no name.
 */
ecs_get_name :: (
    world: *ecs_world_t,
    entity: ecs_entity_t) -> *u8 #foreign flecs;

/* Convert type role to string.
 * This operation converts a type role to a string.
 *
 * @param world The world.
 * @param entity The entity containing the type role.
 * @return The type role string, or NULL if no type role is provided.
 */
ecs_role_str :: (
    entity: ecs_entity_t) -> *u8 #foreign flecs;

/* Convert id to string.
 * This operation interprets the structure of an id and converts it to a string.
 *
 * @param world The world.
 * @param id The id to convert to a string.
 * @param buffer The buffer in which to store the string.
 * @param buffer_len The length of the provided buffer.
 * @return The number of characters required to write the string.
 */
ecs_id_str :: (
    world: *ecs_world_t,
    entity: ecs_id_t,
    buffer: *u8,
    buffer_len: size_t) -> size_t #foreign flecs;

/* Get the object of an entity.
 * This will return a object of the entity that has the specified component. If
 * the component is 0, the operation will return the first object that it finds
 * in the entity type.
 *
 * @param world The world.
 * @param entity The entity.
 * @param rel The relation between the entity and the object.
 * @param id The entity id of a component that the object must have.
 * @return The object that has the specified id.
 */
ecs_get_object_w_id :: (
    world: *ecs_world_t,
    entity: ecs_entity_t,
    rel: ecs_entity_t,
    id: ecs_id_t) -> ecs_entity_t #foreign flecs;

// /* Get the parent of an entity.
//  * Same as ecs_get_parent_w_id but accepts a component typename.
//  *
//  * @param world The world.
//  * @param entity The entity.
//  * @param rel The relation between the entity and the object.
//  * @param component A component that the parent must have.
//  * @return The parent of the entity, 0 if no parent was found.
//  */
// #define ecs_get_object(world, entity, rel, component)\
//     ecs_get_parent_w_id(world, entity, ecs_id(component))


/* Enable or disable an entity.
 * This operation enables or disables an entity by adding or removing the
 * EcsDisabled tag. A disabled entity will not be matched with any systems,
 * unless the system explicitly specifies the EcsDisabled tag.
 *
 * @param world The world.
 * @param entity The entity to enable or disable.
 * @param enabled true to enable the entity, false to disable.
 */
ecs_enable :: (
    world: *ecs_world_t,
    entity: ecs_entity_t,
    enabled: bool) #foreign flecs;

/* Count entities that have the specified id.
 * Returns the number of entities that have the specified id.
 *
 * @param world The world.
 * @param entity The id to search for.
 * @return The number of entities that have the id.
 */
ecs_count_id :: (
    world: *ecs_world_t,
    entity: ecs_id_t) -> int32_t #foreign flecs;

// /* Count entities that have a component, type or tag.
//  * Returns the number of entities that have the specified component, type or tag.
//  *
//  * @param world The world.
//  * @param type The component, type or tag.
//  * @return The number of entities that have the component, type or tag.
//  */
// #define ecs_count(world, type)\
//     ecs_count_type(world, ecs_type(type))

/* Count entities that match a filter.
 * Returns the number of entities that match the specified filter.
 *
 * @param world The world.
 * @param type The type.
 * @return The number of entities that match the specified filter.
 */
ecs_count_filter :: (
    world: *ecs_world_t,
    filter: *ecs_filter_t) -> int32_t #foreign flecs;

/* @} */


/*
 * @defgroup lookup Lookups
 * @{
 */

/* Lookup an entity by name.
 * Returns an entity that matches the specified name. Only looks for entities in
 * the current scope (root if no scope is provided).
 *
 * @param world The world.
 * @param name The entity name.
 * @return The entity with the specified name, or 0 if no entity was found.
 */
ecs_lookup :: (
    world: *ecs_world_t,
    name: *char) -> ecs_entity_t #foreign flecs;

/* Lookup a child entity by name.
 * Returns an entity that matches the specified name. Only looks for entities in
 * the provided parent. If no parent is provided, look in the current scope (
 * root if no scope is provided).
 *
 * @param world The world.
 * @param name The entity name.
 * @return The entity with the specified name, or 0 if no entity was found.
 */
ecs_lookup_child :: (
    world: *ecs_world_t,
    parent: ecs_entity_t,
    name: *char) -> ecs_entity_t #foreign flecs;

/* Lookup an entity from a path.
 * Lookup an entity from a provided path, relative to the provided parent. The
 * operation will use the provided separator to tokenize the path expression. If
 * the provided path contains the prefix, the search will start from the root.
 *
 * If the entity is not found in the provided parent, the operation will
 * continue to search in the parent of the parent, until the root is reached. If
 * the entity is still not found, the lookup will search in the flecs.core
 * scope. If the entity is not found there either, the function returns 0.
 *
 * @param world The world.
 * @param parent The entity from which to resolve the path.
 * @param path The path to resolve.
 * @param sep The path separator.
 * @param prefix The path prefix.
 * @param recursive Recursively traverse up the tree until entity is found.
 * @return The entity if found, else 0.
 */
ecs_lookup_path_w_sep :: (
    world: *ecs_world_t,
    parent: ecs_entity_t,
    path: *u8,
    sep: *u8,
    prefix: *u8,
    recursive: bool) -> ecs_entity_t #foreign flecs;

// /* Lookup an entity from a path.
//  * Same as ecs_lookup_path_w_sep, but with defaults for the separator and
//  * prefix. These defaults are used when looking up identifiers in a type or
//  * signature expression.
//  *
//  * @param world The world.
//  * @param parent The entity from which to resolve the path.
//  * @param path The path to resolve.
//  * @return The entity if found, else 0.
//  */
// #define ecs_lookup_path(world, parent, path)\
//     ecs_lookup_path_w_sep(world, parent, path, ".", NULL, true)

// /* Lookup an entity from a full path.
//  * Same as ecs_lookup_path, but  searches from the current scope, or root scope
//  * if no scope is set.
//  *
//  * @param world The world.
//  * @param path The path to resolve.
//  * @return The entity if found, else 0.
//  */
// #define ecs_lookup_fullpath(world, path)\
//     ecs_lookup_path_w_sep(world, 0, path, ".", NULL, true)

/* Lookup an entity by its symbol name.
 * This looks up an entity by the symbol name that was provided in EcsName. The
 * operation does not take into account scoping, which means it will search all
 * entities that have an EcsName.
 *
 * This operation can be useful to resolve, for example, a type by its C
 * identifier, which does not include the Flecs namespacing.
 */
ecs_lookup_symbol :: (
    world: *ecs_world_t,
    name: *u8) -> ecs_entity_tecs_entity_t #foreign flecs;

/* Add alias for entity to global scope */
ecs_use :: (
    world: *ecs_world_t,
    entity: ecs_entity_t,
    name: *u8)ecs_entity_t #foreign flecs;

/* @} */

/*
 * @defgroup paths Paths
 * @{
 */

/* Get a path identifier for an entity.
 * This operation creates a path that contains the names of the entities from
 * the specified parent to the provided entity, separated by the provided
 * separator. If no parent is provided the path will be relative to the root. If
 * a prefix is provided, the path will be prefixed by the prefix.
 *
 * If the parent is equal to the provided child, the operation will return an
 * empty string. If a nonzero component is provided, the path will be created by
 * looking for parents with that component.
 *
 * The returned path should be freed by the application.
 *
 * @param world The world.
 * @param parent The entity from which to create the path.
 * @param child The entity to which to create the path.
 * @param component The component of the parent.
 * @return The relative entity path.
 */
ecs_get_path_w_sep :: (
    world: *ecs_world_t,
    parent: ecs_entity_t,
    child: ecs_entity_t,
    component: ecs_entity_t,
    sep: *u8,
    prefix: *u8) -> *u8 #foreign flecs;

// /* Get a path identifier for an entity.
//  * Same as ecs_get_path_w_sep, but with default values for the separator and
//  * prefix. These defaults are used throughout Flecs whenever identifiers are
//  * used in type or signature expressions.
//  *
//  * @param world The world.
//  * @param parent The entity from which to create the path.
//  * @param child The entity to which to create the path.
//  * @return The relative entity path.
//  */
// #define ecs_get_path(world, parent, child)\
//     ecs_get_path_w_sep(world, parent, child, 0, ".", NULL)

// /* Get a full path for an entity.
//  * Same as ecs_get_path, but with default values for the separator and
//  * prefix, and the path is created from the current scope, or root if no scope
//  * is provided.
//  *
//  * @param world The world.
//  * @param child The entity to which to create the path.
//  * @return The entity path.
//  */
// #define ecs_get_fullpath(world, child)\
//     ecs_get_path_w_sep(world, 0, child, 0, ".", NULL)

/* Find or create entity from path.
 * This operation will find or create an entity from a path, and will create any
 * intermediate entities if required. If the entity already exists, no entities
 * will be created.
 *
 * If the path starts with the prefix, then the entity will be created from the
 * root scope.
 *
 * @param world The world.
 * @param parent The entity relative to which the entity should be created.
 * @param path The path to create the entity for.
 * @param sep The separator used in the path.
 * @param prefix The prefix used in the path.
 * @return The entity.
 */
ecs_new_from_path_w_sep :: (
    world: *ecs_world_t,
    parent: ecs_entity_t,
    path: *u8,
    sep: *u8,
    prefix: *u8) -> ecs_entity_t #foreign flecs;

// /* Find or create entity from path.
//  * Same as ecs_new_from_path_w_sep, but with defaults for sep and prefix.
//  *
//  * @param world The world.
//  * @param parent The entity relative to which the entity should be created.
//  * @param path The path to create the entity for.
//  * @return The entity.
//  */
// #define ecs_new_from_path(world, parent, path)\
//     ecs_new_from_path_w_sep(world, parent, path, ".", NULL)

// /* Find or create entity from full path.
//  * Same as ecs_new_from_path, but entity will be created from the current scope,
//  * or root scope if no scope is set.
//  *
//  * @param world The world.
//  * @param path The path to create the entity for.
//  * @return The entity.
//  */
// #define ecs_new_from_fullpath(world, path)\
//     ecs_new_from_path_w_sep(world, 0, path, ".", NULL)

/* Add specified path to entity.
 * This operation is similar to ecs_new_from_path, but will instead add the path
 * to an existing entity.
 *
 * If an entity already exists for the path, it will be returned instead.
 *
 * @param world The world.
 * @param entity The entity to which to add the path.
 * @param parent The entity relative to which the entity should be created.
 * @param path The path to create the entity for.
 * @param sep The separator used in the path.
 * @param prefix The prefix used in the path.
 * @return The entity.
 */
ecs_add_path_w_sep :: (
    world: *ecs_world_t,
    entity: ecs_entity_t,
    parent: ecs_entity_t,
    path: *u8,
    sep: *u8,
    prefix: *u8) -> ecs_entity_t #foreign flecs;

// /* Add specified path to entity.
//  * Same as ecs_add_from_path_w_sep, but with defaults for sep and prefix.
//  *
//  * @param world The world.
//  * @param entity The entity to which to add the path.
//  * @param parent The entity relative to which the entity should be created.
//  * @param path The path to create the entity for.
//  * @return The entity.
//  */
// #define ecs_add_path(world, entity, parent, path)\
//     ecs_add_path_w_sep(world, entity, parent, path, ".", NULL)

// /* Add specified path to entity.
//  * Same as ecs_add_from_path, but entity will be created from the current scope,
//  * or root scope if no scope is set.
//  *
//  * @param world The world.
//  * @param entity The entity to which to add the path.
//  * @param path The path to create the entity for.
//  * @return The entity.
//  */
// #define ecs_add_fullpath(world, entity, path)\
//     ecs_add_path_w_sep(world, entity, 0, path, ".", NULL)

/* @} */

/*
 * @defgroup scopes Scopes
 * @{
 */

/* Does entity have children.
 *
 * @param world The world
 * @param entity The entity
 * @return True if the entity has children, false if not.
 */
ecs_get_child_count :: (
    world: *ecs_world_t,
    entity: ecs_entity_t) -> int32_t #foreign flecs;

/* Return a scope iterator.
 * A scope iterator iterates over all the child entities of the specified
 * parent.
 *
 * @param world The world.
 * @param parent The parent entity for which to iterate the children.
 * @return The iterator.
 */
ecs_scope_iter :: (
    world: *ecs_world_t,
    parent: ecs_entity_t) -> ecs_iter_t #foreign flecs;

/* Return a filtered scope iterator.
 * Same as ecs_scope_iter, but results will be filtered.
 *
 * @param world The world.
 * @param parent The parent entity for which to iterate the children.
 * @return The iterator.
 */
ecs_scope_iter_w_filter :: (
    world: *ecs_world_t,
    parent: ecs_entity_t,
    filter: *ecs_filter_t) -> ecs_iter_t #foreign flecs;

/* Progress the scope iterator.
 * This operation progresses the scope iterator to the next table. The iterator
 * must have been initialized with `ecs_scope_iter`. This operation must be
 * invoked at least once before interpreting the contents of the iterator.
 *
 * @param it The iterator
 * @return True if more data is available, false if not.
 */
ecs_scope_next :: (
    it: *ecs_iter_t) -> bool #foreign flecs;

/* Set the current scope.
 * This operation sets the scope of the current stage to the provided entity.
 * As a result new entities will be created in this scope, and lookups will be
 * relative to the provided scope.
 *
 * It is considered good practice to restore the scope to the old value.
 *
 * @param world The world.
 * @param scope The entity to use as scope.
 * @return The previous scope.
 */
ecs_set_scope :: (
    world: *ecs_world_t,
    scope: ecs_entity_t) -> ecs_entity_t #foreign flecs;

/* Get the current scope.
 * Get the scope set by ecs_set_scope. If no scope is set, this operation will
 * return 0.
 *
 * @param world The world.
 * @return The current scope.
 */
ecs_get_scope :: (
    world: *ecs_world_t) -> ecs_entity_t #foreign flecs;

/* Set current with id.
 * New entities are automatically created with the specified id.
 *
 * @param world The world.
 * @param id The id.
 * @return The previous id.
 */
ecs_set_with :: (
    world: *ecs_world_t,
    id: ecs_id_t) -> ecs_entity_t #foreign flecs;

/* Get current with id.
 * Get the id set with ecs_set_with.
 *
 * @param world The world.
 * @param id The id.
 * @return The previous id.
 */
ecs_get_with :: (
    world: *ecs_world_t) -> ecs_entity_t #foreign flecs;

/* Set a name prefix for newly created entities.
 * This is a utility that lets C modules use prefixed names for C types and
 * C functions, while using names for the entity names that do not have the
 * prefix. The name prefix is currently only used by ECS_COMPONENT.
 *
 * @param world The world.
 * @param prefix The name prefix to use.
 * @return The previous prefix.
 */
ecs_set_name_prefix :: (
    world: *ecs_world_t,
    prefix: *u8) -> *u8 #foreign flecs;

/* @} */

/*
 * @defgroup terms Terms
 * @{
 */

/* Test whether a term is set.
 * This operation can be used to test whether a term has been initialized with
 * values or whether it is empty.
 *
 * An application generally does not need to invoke this operation. It is useful
 * when initializing a 0-initialized array of terms (like in ecs_term_desc_t) as
 * this operation can be used to find the last initialized element.
 *
 * @param term The term.
 * @return True when set, false when not set.
 */
ecs_term_is_set :: (
    term: *ecs_term_t) -> bool #foreign flecs;

/* Test whether a term is a trivial term.
 * A trivial term is a term that only contains a type id. Trivial terms must not
 * have read/write annotations, relation substitutions and subjects other than
 * 'This'. Examples of trivial terms are:
 * - 'Position'
 * - 'Position(This)'
 * - '(Likes, IceCream)'
 * - 'Likes(This, IceCream)'
 *
 * Examples of non-trivial terms are:
 * - '[in] Position'
 * - 'Position(MyEntity)'
 * - 'Position(self|superset)'
 *
 * Trivial terms are useful in expressions that should just represent a list of
 * components, such as when parsing the list of components to add to an entity.
 *
 * The term passed to this operation must be finalized. Terms returned by the
 * parser are guaranteed to be finalized.
 *
 * @param term The term.
 * @return True if term is trivial, false if it is not.
 */
ecs_term_is_trivial :: (
    term: *ecs_term_t) -> bool #foreign flecs;

/* Finalize term.
 * Ensure that all fields of a term are consistent and filled out. This
 * operation should be invoked before using and after assigning members to, or
 * parsing a term. When a term contains unresolved identifiers, this operation
 * will resolve and assign the identifiers. If the term contains any identifiers
 * that cannot be resolved, the operation will fail.
 *
 * An application generally does not need to invoke this operation as the APIs
 * that use terms (such as filters, queries and triggers) will finalize terms
 * when they are created.
 *
 * The name and expr parameters are optional, and only used for giving more
 * descriptive error messages.
 *
 * @param world The world.
 * @param name The name of the entity that uses the term (such as a system).
 * @param expr The string expression of which the term is a part.
 * @param term The term to finalize.
 * @return Zero if success, nonzero if an error occurred.
 */
ecs_term_finalize :: (
    world: *ecs_world_t,
    name: *u8,
    expr: *u8,
    term: *ecs_term_t) -> int #foreign flecs;

/* Copy resources of a term to another term.
 * This operation copies one term to another term. If the source term contains
 * allocated resources (such as identifiers), they will be duplicated so that
 * no memory is shared between the terms.
 *
 * @param dst The term to copy to.
 * @param src The term to copy from.
 */
ecs_term_copy :: (
    src: *ecs_term_t) -> ecs_term_t #foreign flecs;

/* Move resources of a term to another term.
 * Same as copy, but moves resources from src, if src->move is set to true. If
 * src->move is not set to true, this operation will do a copy.
 *
 * The conditional move reduces redundant allocations in scenarios where a list
 * of terms is partially created with allocated resources.
 *
 * @param dst The term to copy to.
 * @param src The term to copy from.
 */
ecs_term_move :: (
    src: *ecs_term_t) -> ecs_term_t #foreign flecs;

/* Free resources of term.
 * This operation frees all resources (such as identifiers) of a term. The term
 * object itself is not freed.
 *
 * @param term The term to free.
 */
ecs_term_fini :: (
    term: *ecs_term_t) #foreign flecs;

/* Utility to match an id with a pattern.
 * This operation returns true if the provided pattern matches the provided
 * id. The pattern may contain a wildcard (or wildcards, when a pair).
 *
 * @param id The id.
 * @param pattern The pattern to compare with.
 */
ecs_id_match :: (
    id: ecs_id_t,
    pattern: ecs_id_t) -> bool #foreign flecs;

/* @} */

/*
 * @defgroup filters Filters
 * @{
 */

/* Initialize filter
 * A filter is a lightweight object that can be used to query for entities in
 * a world. Filters, as opposed to queries, do not cache results. They are
 * therefore slower to iterate, but are faster to create.
 *
 * This operation will at minimum allocate an array to hold the filter terms in
 * the returned filter struct. It may allocate additional memory if the provided
 * description contains a name, expression, or if the provided array of terms
 * contains strings (identifier names or term names).
 *
 * It is possible to create a filter without allocating any memory, by setting
 * the "terms" and "term_count" members directly. When doing so an application
 * should not call ecs_filter_init but ecs_filter_finalize. This will ensure
 * that all fields are consistent and properly filled out.
 *
 * @param world The world.
 * @param desc Properties for the filter to create.
 * @param filter_out The filter.
 * @return Zero if successful, non-zero if failed.
 */
ecs_filter_init :: (
    world: *ecs_world_t,
    filter_out: *ecs_filter_t,
    desc: *ecs_filter_desc_t) -> s32 #foreign flecs;

/* Deinitialize filter.
 * Free resources associated with filter.
 *
 * @param filter The filter to deinitialize.
 */
void ecs_filter_fini(
    filter: *ecs_filter_t) #foreign flecs;

/* Finalize filter.
 * When manually assigning an array of terms to the filter struct (so not when
 * using ecs_filter_init), this operation should be used to ensure that all
 * terms are assigned properly and all (derived) fields have been set.
 *
 * When ecs_filter_init is used to create the filter, this function should not
 * be called. The purpose of this operation is to support creation of filters
 * without allocating memory.
 *
 * @param filter The filter to finalize.
 * @return Zero if filter is valid, non-zero if it contains errors.
 * @
 */
ecs_filter_finalize :: (
    world: *ecs_world_t,
    filter: *ecs_filter_t) -> s32 #foreign flecs;

/* Convert filter to string expression.
 * Convert filter terms to a string expression. The resulting expression can be
 * parsed to create the same filter.
 */
ecs_filter_str :: (
    world: *ecs_world_t,
    filter: *ecs_filter_t) -> *u8 #foreign flecs;

/* Match entity with filter.
 * Test if entity matches filter terms. The function will substitute terms with
 * a "This" subject with the provided entity.
 *
 * Terms with other subjects are also matched. Even if the specified entity
 * matches all This terms, if the filter contains a term for another entity
 * which does not match the term, the operation will evaluate false.
 *
 * If 0 is provided for the specified entity, only non-This terms are matched
 *
 * @param world The world.
 * @param filter The filter to evaluate.
 * @param entity The entity to match.
 * @return True if the filter matches, false if it doesn't match.
 */
ecs_filter_match_entity :: (
    world: *ecs_world_t,
    filter: *ecs_filter_t,
    e: ecs_entity_t) -> bool #foreign flecs;

/* Same as ecs_filter_match_entity, but for a type.
 *
 * @param world The world.
 * @param filter The filter to evaluate.
 * @param type The type to match.
 * @return True if the filter matches, false if it doesn't match.
 */
ecs_filter_match_type :: (
    world: *ecs_world_t,
    filter: *ecs_filter_t,
    type: ecs_type_t) -> bool;

/* Return a filter iterator.
 * A filter iterator lets an application iterate over entities that match the
 * specified filter. If NULL is provided for the filter, the iterator will
 * iterate all tables in the world.
 *
 * @param world The world.
 * @param filter The filter.
 * @return An iterator that can be used with ecs_filter_next.
 */
ecs_filter_iter :: (
    world: *ecs_world_t,
    filter: *ecs_filter_t) -> ecs_iter_t #foreign flecs;

/* Iterate tables matched by filter.
 * This operation progresses the filter iterator to the next table. The
 * iterator must have been initialized with `ecs_filter_iter`. This operation
 * must be invoked at least once before interpreting the contents of the
 * iterator.
 *
 * @param it The iterator
 * @return True if more data is available, false if not.
 */
ecs_filter_next :: (
    iter: *ecs_iter_t) -> bool #foreign flecs;

/* @} */

/*
 * @defgroup queries Queries
 * @{
 */

/* Create a query.
 * This operation creates a query. Queries are used to iterate over entities
 * that match a filter and are the fastest way to find and iterate over entities
 * and their components.
 *
 * Queries should be created once, and reused multiple times. While iterating a
 * query is a cheap operation, creating and deleting a query is expensive. The
 * reason for this is that queries are "prematched", which means that a query
 * stores state about which entities (or rather, tables) match with the query.
 * Building up this state happens during query creation.
 *
 * Once a query is created, matching only happens when new tables are created.
 * In most applications this is an infrequent process, since it only occurs when
 * a new combination of components is introduced. While matching is expensive,
 * it is importent to note that matching does not happen on a per-entity basis,
 * but on a per-table basis. This means that the average time spent on matching
 * per frame should rapidly approach zero over the lifetime of an application.
 *
 * A query provides direct access to the component arrays. When an application
 * creates/deletes entities or adds/removes components, these arrays can shift
 * component values around, or may grow in size. This can cause unexpected or
 * undefined behavior to occur if these operations are performed while
 * iterating. To prevent this from happening an application should either not
 * perform these operations while iterating, or use deferred operations (see
 * ecs_defer_begin and ecs_defer_end).
 *
 * Queries can be created and deleted dynamically. If a query was not deleted
 * (using ecs_query_fini) before the world is deleted, it will be deleted
 * automatically.
 *
 * @param world The world.
 * @param desc A structure describing the query properties.
 * @return The new query.
 */
ecs_query_init :: (
    world: *ecs_world_t,
    desc: *ecs_query_desc_t) -> *ecs_query_t #foreign flecs;

/* Destroy a query.
 * This operation destroys a query and its resources. If the query is used as
 * the parent of subqueries, those subqueries will be orphaned and must be
 * deinitialized as well.
 *
 * @param query The query.
 */
ecs_query_fini :: (
    query: *ecs_query_t) #foreign flecs;

/* Get filter object of query.
 * This operation obtains a pointer to the internally constructed filter object
 * of the query and can be used to introspect the query terms.
 *
 * @param query The query.
 */
ecs_query_get_filter :: (
    query: *ecs_query_t) -> *ecs_filter_t #foreign flecs;

/* Return a query iterator.
 * A query iterator lets an application iterate over entities that match the
 * specified query. If a sorting function is specified, the query will check
 * whether a resort is required upon creating the iterator.
 *
 * Creating a query iterator is a cheap operation that does not allocate any
 * resources. An application does not need to deinitialize or free a query
 * iterator before it goes out of scope.
 *
 * To iterate the iterator, an application should use ecs_query_next to progress
 * the iterator and test if it has data.
 *
 * Query iteration requires an outer and an inner loop. The outer loop uses
 * ecs_query_next to test if new tables are available. The inner loop iterates
 * the entities in the table, and is usually a for loop that uses iter.count to
 * loop through the entities and component arrays.
 *
 * The two loops are necessary because of how data is stored internally.
 * Entities are grouped by the components they have, in tables. A single query
 * can (and often does) match with multiple tables. Because each table has its
 * own set of arrays, an application has to reobtain pointers to those arrays
 * for each matching table.
 *
 * @param query The query to iterate.
 * @return The query iterator.
 */
ecs_query_iter :: (
    query: *ecs_query_t) -> ecs_iter_t #foreign flecs;

/* Iterate over a query.
 * This operation is similar to ecs_query_iter, but starts iterating from a
 * specified offset, and will not iterate more than limit entities.
 *
 * @param query The query to iterate.
 * @param offset The number of entities to skip.
 * @param limit The maximum number of entities to iterate.
 * @return The query iterator.
 */
ecs_query_iter_page :: (
    query: *ecs_query_t,
    offset: int32_t,
    limit: int32_t) -> ecs_iter_t #foreign flecs;

/* Progress the query iterator.
 * This operation progresses the query iterator to the next table. The
 * iterator must have been initialized with `ecs_query_iter`. This operation
 * must be invoked at least once before interpreting the contents of the
 * iterator.
 *
 * @param iter The iterator.
 * @returns True if more data is available, false if not.
 */
ecs_query_next :: (
    iter: *ecs_iter_t) -> bool #foreign flecs;

/* Progress the query iterator with filter.
 * This operation is the same as ecs_query_next, but accepts a filter as an
 * argument. Entities not matching the filter will be skipped by the iterator.
 *
 * @param iter The iterator.
 * @param filter The filter to apply to the iterator.
 * @returns True if more data is available, false if not.
 */
ecs_query_next_w_filter :: (
    iter: *ecs_iter_t,
    filter: *ecs_filter_t) -> bool #foreign flecs;

/* Progress the query iterator for a worker thread.
 * This operation is similar to ecs_query_next, but provides the ability to
 * divide entities up across multiple worker threads. The operation accepts a
 * current thread id and a total thread id, which is used to determine which
 * subset of entities should be assigned to the current thread.
 *
 * Current should be less than total, and there should be as many as total
 * threads. If there are less entities in a table than there are threads, only
 * as many threads as there are entities will iterate that table.
 *
 * @param it The iterator.
 * @param stage_current Id of current stage.
 * @param stage_count Total number of stages.
 * @returns True if more data is available, false if not.
 */
ecs_query_next_worker :: (
    it: *ecs_iter_t,
    stage_current: int32_t,
    stage_count: int32_t) -> bool #foreign flecs;

/* Returns whether the query data changed since the last iteration.
 * This operation must be invoked before obtaining the iterator, as this will
 * reset the changed state. The operation will return true after:
 * - new entities have been matched with
 * - matched entities were deleted
 * - matched components were changed
 *
 * @param query The query.
 * @return true if entities changed, otherwise false.
 */
ecs_query_changed :: (
    query: *ecs_query_t) -> bool #foreign flecs;

/* Returns whether query is orphaned.
 * When the parent query of a subquery is deleted, it is left in an orphaned
 * state. The only valid operation on an orphaned query is deleting it. Only
 * subqueries can be orphaned.
 *
 * @param query The query.
 * @return true if query is orphaned, otherwise false.
 */
ecs_query_orphaned :: (
    query: *ecs_query_t) -> bool #foreign flecs;

/* @} */

/*
 * @defgroup trigger Triggers
 */

/* Create trigger.
 * Triggers notify the application when certain events happen such as adding or
 * removing components.
 *
 * An application can change the trigger callback or context pointer by calling
 * ecs_trigger_init for an existing trigger entity, by setting the
 * ecs_trigger_desc_t::entity.entity field in combination with callback and/or
 * ctx.
 *
 * See the documentation for ecs_trigger_desc_t for more details.
 *
 * @param world The world.
 * @param decs The trigger creation parameters.
 */
ecs_trigger_init :: (
    world: *ecs_world_t,
    desc: *ecs_trigger_desc_t) -> ecs_entity_t #foreign flecs;

/* Get trigger context.
 * This operation returns the context pointer set for the trigger. If
 * the provided entity is not a trigger, the function will return NULL.
 *
 * @param world The world.
 * @param trigger The trigger from which to obtain the context.
 * @return The context.
 */
ecs_get_trigger_ctx :: (
    world: *ecs_world_t,
    trigger: ecs_entity_t) -> *void #foreign flecs;

/* Same as ecs_get_trigger_ctx, but for binding ctx.
 * The binding context is a context typically used to attach any language
 * binding specific data that is needed when invoking a callback that is
 * implemented in another language.
 *
 * @param world The world.
 * @param trigger The trigger from which to obtain the context.
 * @return The context.
 */
ecs_get_trigger_binding_ctx :: (
    world: *ecs_world_t,
    trigger: ecs_entity_t) -> *void #foreign flecs;

/* @} */

/*
 * @defgroup observer Observers
 */

/* Create observer.
 * Observers are like triggers, but can subscribe for multiple terms. An
 * observer only triggers when the source of the event meets all terms.
 *
 * See the documentation for ecs_observer_desc_t for more details.
 *
 * @param world The world.
 * @param desc The observer creation parameters.
 */
ecs_observer_init :: (
    world: *ecs_world_t,
    desc: *ecs_observer_desc_t) -> ecs_entity_t #foreign flecs;

ecs_get_observer_ctx :: (
    world: *ecs_world_t,
    observer: ecs_entity_t) -> *void #foreign flecs;

ecs_get_observer_binding_ctx :: (
    world: *ecs_world_t,
    observer: ecs_entity_t) -> *void #foreign flecs;

/* @} */

/*
 * @defgroup iterator Iterators
 * @{
 */

/* Obtain data for a query term.
 * This operation retrieves a pointer to an array of data that belongs to the
 * term in the query. The index refers to the location of the term in the query,
 * and starts counting from one.
 *
 * For example, the query "Position, Velocity" will return the Position array
 * for index 1, and the Velocity array for index 2.
 *
 * When the specified term is not owned by the entity this function returns a
 * pointer instead of an array. This happens when the source of a term is not
 * the entity being iterated, such as a shared component (from a prefab), a
 * component from a parent, or another entity. The ecs_term_is_owned operation
 * can be used to test dynamically if a term is owned.
 *
 * The provided size must be either 0 or must match the size of the datatype
 * of the returned array. If the size does not match, the operation may assert.
 * The size can be dynamically obtained with ecs_term_size.
 *
 * @param it The iterator.
 * @param size The size of the returned array.
 * @param index The index of the term in the query.
 * @return A pointer to the data associated with the term.
 */
ecs_term_w_size :: (
    it: *ecs_iter_t,
    size: size_t,
    index: int32_t) -> *void #foreign flecs;

// /* Same as ecs_term_w_size, but accepts a type instead of a size. */
// #define ecs_term(it, T, index)\
//     ((T*)ecs_term_w_size(it, sizeof(T), index))

/* Obtain the component/pair id for a term.
 * This operation retrieves the id for the specified query term. Typically this
 * is the component id, but it can also be a pair id or a role annotated id,
 * depending on the term.
 *
 * @param it The iterator.
 * @param index The index of the term in the query.
 * @return The id associated with te term.
 */
ecs_term_id :: (
    it: *ecs_iter_t,
    index: int32_t) -> ecs_id_t #foreign flecs;

/* Obtain the source for a term.
 * This operation retrieves the source of the specified term. A source is the
 * entity from which the data is retrieved. If the term is owned by the iterated
 * over entity/entities, the function will return id 0.
 *
 * This operation can be useful to retrieve, for example, the id of a parent
 * entity when a component from a parent has been requested, or to retrieve the
 * id from a prefab, in the case of a shared component.
 *
 * @param it The iterator.
 * @param index The index of the term in the query.
 * @return The source associated with te term.
 */
ecs_term_source :: (
    it: *ecs_iter_t,
    index: int32_t) -> ecs_entity_t #foreign flecs;

/* Obtain the size for a term.
 * This operation retrieves the size of the datatype for the term.
 *
 * @param it The iterator.
 * @param index The index of the term in the query.
 * @return The size of the datatype associated with te term.
 */
ecs_term_size :: (
    it: *ecs_iter_t,
    index: int32_t) -> size_t #foreign flecs;

/* Test whether the term is readonly
 * This operation returns whether this is a readonly term. Readonly terms are
 * annotated with [in], or are added as a type in the C++ API.
 *
 * @param it The iterator.
 * @param index The index of the term in the query.
 * @return Whether the term is readonly.
 */
ecs_term_is_readonly :: (
    it: *ecs_iter_t,
    index: int32_t) -> bool #foreign flecs;

/* Test whether the term is owned
 * This operation returns whether the term is owned by the currently iterated
 * entity. This function will return false when the term is owned by another
 * entity, such as a parent or a prefab.
 *
 * @param it The iterator.
 * @param index The index of the term in the query.
 * @return Whether the term is owned by the iterated over entity/entities.
 */
ecs_term_is_owned :: (
    it: *ecs_iter_t,
    index: int32_t) -> bool #foreign flecs;

/* Get the type of the currently entities.
 * This operation returns the type of the current iterated entity/entities. A
 * type is a vector that contains all ids of the components that an entity has.
 *
 * @param it The iterator.
 * @return The type of the currently iterated entity/entities.
 */
ecs_iter_type :: (
    it: *ecs_iter_t) -> ecs_type_t #foreign flecs;

/* Get the table for the current entities.
 * This operation returns the table of the current iterated entities
 *
 * @param it The iterator.
 * @return The table of the currently iterated entity/entities.
 */
ecs_iter_table :: (
    it: *ecs_iter_t) -> *ecs_table_t #foreign flecs;

/* Find the column index for a given id.
 * This operation finds the index of a column in the current type for the
 * specified id. For example, if an entity has type Position, Velocity, and the
 * application requests the id for the Velocity component, this function will
 * return 1.
 *
 * Note that the column index returned by this function starts from 0, as
 * opposed to 1 for the terms. The reason for this is that the returned index
 * is equivalent to using the ecs_type_get_index function, with as type the
 * value returned by ecs_iter_type.
 *
 * This operation can be used to request columns that are not requested by a
 * query. For example, a query may request Position, Velocity, but an entity
 * may also have Mass. With this function the iterator can request the data for
 * Mass as well, when used in combination with ecs_iter_column.
 *
 * @param it The iterator.
 * @return The type of the currently iterated entity/entities.
 */
ecs_iter_find_column :: (
    it: *ecs_iter_t,
    id: ecs_id_t) -> int32_t #foreign flecs;

/* Obtain data for a column index.
 * This operation can be used with the id obtained from ecs_iter_find_column to
 * request data from the currently iterated over entity/entities that is not
 * requested by the query.
 *
 * The data in the returned pointer can be accessed using the same index as
 * the one used to access the arrays returned by the ecs_term function.
 *
 * The provided size must be either 0 or must match the size of the datatype
 * of the returned array. If the size does not match, the operation may assert.
 * The size can be dynamically obtained with ecs_iter_column_size.
 *
 * Note that this function can be used together with ecs_iter_type to
 * dynamically iterate all data that the matched entities have. An application
 * can use the ecs_vector_count function to obtain the number of elements in a
 * type. All indices from 0..ecs_vector_count(type) are valid column indices.
 *
 * Additionally, note that this provides unprotected access to the column data.
 * An iterator cannot know or prevent accessing columns that are not queried for
 * and thus applications should only use this when it can be guaranteed that
 * there are no other threads reading/writing the same column data.
 *
 * @param it The iterator.
 * @param size The size of the column.
 * @param index The index of the column.
 * @return The data belonging to the column.
 */
ecs_iter_column_w_size :: (
    it: *ecs_iter_t,
    size: size_t,
    index: int32_t) -> *void #foreign flecs;

// /* Same as ecs_iter_column_w_size, but accepts a type instead of a size. */
// #define ecs_iter_column(it, T, index)\
//     ((T*)ecs_iter_column_w_size(it, sizeof(T), index))

/* Obtain size for a column index.
 * This operation obtains the size for a column. The size is equal to the size
 * of the datatype associated with the column.
 *
 * @param it The iterator.
 * @param index The index of the column.
 * @return The size belonging to the column.
 */
ecs_iter_column_size :: (
    it: *ecs_iter_t,
    index: int32_t) -> size_t #foreign flecs;

/* @} */

/*
 * @defgroup staging Staging
 * @{
 */

/* Begin frame.
 * When an application does not use ecs_progress to control the main loop, it
 * can still use Flecs features such as FPS limiting and time measurements. This
 * operation needs to be invoked whenever a new frame is about to get processed.
 *
 * Calls to ecs_frame_begin must always be followed by ecs_frame_end.
 *
 * The function accepts a delta_time parameter, which will get passed to
 * systems. This value is also used to compute the amount of time the function
 * needs to sleep to ensure it does not exceed the target_fps, when it is set.
 * When 0 is provided for delta_time, the time will be measured.
 *
 * This function should only be ran from the main thread.
 *
 * @param world The world.
 * @param delta_time Time elapsed since the last frame.
 * @return The provided delta_time, or measured time if 0 was provided.
 */
ecs_frame_begin :: (
    world: *ecs_world_t,
    delta_time: FLECS_FLOAT) -> FLECS_FLOAT #foreign flecs;

/* End frame.
 * This operation must be called at the end of the frame, and always after
 * ecs_frame_begin.
 *
 * @param world The world.
 */
ecs_frame_end :: (
    world: *ecs_world_t) #foreign flecs;

/* Begin staging.
 * When an application does not use ecs_progress to control the main loop, it
 * can still use Flecs features such as the defer queue. When an application
 * needs to stage changes, it needs to call this function after ecs_frame_begin.
 * A call to ecs_staging_begin must be followed by a call to ecs_staging_end.
 *
 * When staging is enabled, modifications to entities are stored to a stage.
 * This ensures that arrays are not modified while iterating. Modifications are
 * merged back to the "main stage" when ecs_staging_end is invoked.
 *
 * While the world is in staging mode, no structural changes (add/remove/...)
 * can be made to the world itself. Operations must be executed on a stage
 * instead (see ecs_get_stage).
 *
 * This function should only be ran from the main thread.
 *
 * @param world The world
 * @return Whether world is currently staged.
 */
ecs_staging_begin :: (
    world: *ecs_world_t) -> bool #foreign flecs;

/* End staging.
 * Leaves staging mode. After this operation the world may be directly mutated
 * again. By default this operation also merges data back into the world, unless
 * automerging was disabled explicitly.
 *
 * This function should only be ran from the main thread.
 *
 * @param world The world
 */
ecs_staging_end :: (
    world: *ecs_world_t) #foreign flecs;

/* Merge world or stage.
 * When automatic merging is disabled, an application can call this
 * operation on either an individual stage, or on the world which will merge
 * all stages. This operation may only be called when staging is not enabled
 * (either after progress() or after staging_end()).
 *
 * This operation may be called on an already merged stage or world.
 *
 * @param world The world.
 */
ecs_merge :: (
    world: *ecs_world_t) #foreign flecs;

/* Defer operations until end of frame.
 * When this operation is invoked while iterating, operations inbetween the
 * defer_begin and defer_end operations are executed at the end of the frame.
 *
 * This operation is thread safe.
 *
 * @param world The world.
 * @return true if world changed from non-deferred mode to deferred mode.
 */
ecs_defer_begin :: (
    world: *ecs_world_t) -> bool #foreign flecs;

/* Test if deferring is enabled for current stage.
 *
 * @param world The world.
 * @return True if deferred, false if not.
 */
ecs_is_deferred :: (
    world: *ecs_world_t) -> bool #foreign flecs;

/* End block of operations to defer.
 * See defer_begin.
 *
 * This operation is thread safe.
 *
 * @param world The world.
 * @return true if world changed from deferred mode to non-deferred mode.
 */
ecs_defer_end :: (
    world: *ecs_world_t) -> bool #foreign flecs;

/* Enable/disable automerging for world or stage.
 * When automerging is enabled, staged data will automatically be merged with
 * the world when staging ends. This happens at the end of progress(), at a
 * sync point or when staging_end() is called.
 *
 * Applications can exercise more control over when data from a stage is merged
 * by disabling automerging. This requires an application to explicitly call
 * merge() on the stage.
 *
 * When this function is invoked on the world, it sets all current stages to
 * the provided value and sets the default for new stages. When this function is
 * invoked on a stage, automerging is only set for that specific stage.
 *
 * @param world The world.
 * @param automerge Whether to enable or disable automerging.
 */
ecs_set_automerge :: (
    world: *ecs_world_t,
    automerge: bool) #foreign flecs;

/* Configure world to have N stages.
 * This initializes N stages, which allows applications to defer operations to
 * multiple isolated defer queues. This is typically used for applications with
 * multiple threads, where each thread gets its own queue, and commands are
 * merged when threads are synchronized.
 *
 * Note that the ecs_set_threads function already creates the appropriate
 * number of stages. The set_stages() operation is useful for applications that
 * want to manage their own stages and/or threads.
 *
 * @param world The world.
 * @param stages The number of stages.
 */
ecs_set_stages :: (
    world: *ecs_world_t,
    stages: int32_t) #foreign flecs;

/* Get number of configured stages.
 * Return number of stages set by ecs_set_stages.
 *
 * @param world The world.
 * @return The number of stages used for threading.
 */
ecs_get_stage_count :: (
    world: *ecs_world_t) -> int32_t #foreign flecs;

/* Get current stage id.
 * The stage id can be used by an application to learn about which stage it is
 * using, which typically corresponds with the worker thread id.
 *
 * @param world The world.
 * @return The stage id.
 */
ecs_get_stage_id :: (
    world: *ecs_world_t) -> int32_t #foreign flecs;

/* Get stage-specific world pointer.
 * Flecs threads can safely invoke the API as long as they have a private
 * context to write to, also referred to as the stage. This function returns a
 * pointer to a stage, disguised as a world pointer.
 *
 * Note that this function does not(!) create a new world. It simply wraps the
 * existing world in a thread-specific context, which the API knows how to
 * unwrap. The reason the stage is returned as an ecs_world_t is so that it
 * can be passed transparently to the existing API functions, vs. having to
 * create a dediated API for threading.
 *
 * @param world The world.
 * @param stage_id The index of the stage to retrieve.
 * @return A thread-specific pointer to the world.
 */
ecs_get_stage :: (
    world: *ecs_world_t,
    stage_id: int32_t) -> *ecs_world_t #foreign flecs;

/* Get actual world from world.
 * @param world A pointer to a stage or the world.
 * @return The world.
 */
ecs_get_world :: (
    world: *ecs_world_t) -> *ecs_world_t #foreign flecs;

/* Test whether the current world object is readonly.
 * This function allows the code to test whether the currently used world object
 * is readonly or whether it allows for writing.
 *
 * @param world A pointer to a stage or the world.
 * @return True if the world or stage is readonly.
 */
ecs_stage_is_readonly :: (
    stage: *ecs_world_t) -> bool #foreign flecs;

/* Create asynchronous stage.
 * An asynchronous stage can be used to asynchronously queue operations for
 * later merging with the world. An asynchronous stage is similar to a regular
 * stage, except that it does not allow reading from the world.
 *
 * Asynchronous stages are never merged automatically, and must therefore be
 * manually merged with the ecs_merge function. It is not necessary to call
 * defer_begin or defer_end before and after enqueuing commands, as an
 * asynchronous stage unconditionally defers operations.
 *
 * The application must ensure that no commands are added to the stage while the
 * stage is being merged.
 *
 * An asynchronous stage must be cleaned up by ecs_async_stage_free.
 *
 * @param world The world.
 * @return The stage.
 */
ecs_async_stage_new :: (
    world: *ecs_world_t) -> *ecs_world_t #foreign flecs;

/* Free asynchronous stage.
 * The provided stage must be an asynchronous stage. If a non-asynchronous stage
 * is provided, the operation will fail.
 *
 * @param stage The stage to free.
 */
ecs_async_stage_free :: (
    stage: *ecs_world_t) #foreign flecs;

/* Test whether provided stage is asynchronous.
 *
 * @param stage The stage.
 * @return True when the stage is asynchronous, false for a regular stage or
 *         world.
 */
ecs_stage_is_async :: (
    stage: *ecs_world_t) -> bool #foreign flecs;

/* @} */

/*
 * @defgroup table_functions Public table operations
 * @brief Low-level table functions. These functions are intended to enable the
 *        creation of higher-level operations. It is not recommended to use
 *        these operations directly in application code as they do not provide
 *        the same safety guarantees as the other APIs.
 * @{
 */

/* Find or create table with specified component string.
 * The provided string must be a comma-separated list of fully qualified
 * component identifiers. The returned table will have the specified components.
 * Two lists that are the same but specify components in a different order will
 * return the same table.
 *
 * @param world The world.
 * @param type The components.
 * @return The new or existing table, or NULL if the string contains an error.
 */
ecs_table_from_str :: (
    world: *ecs_world_t,
    type: *u8) -> *ecs_table_t #foreign flecs;

/* Find or create table from type.
 * Same as ecs_table_from_str, but provides the type directly.
 *
 * @param world The world.
 * @param type The type.
 * @return The new or existing table.
 */
ecs_table_from_type :: (
    world: *ecs_world_t,
    type: ecs_type_t) -> *ecs_table_t #foreign flecs;

/* Get type for table.
 *
 * @param table The table.
 * @return The type of the table.
 */
ecs_table_get_type :: (
    table: *ecs_table_t) -> ecs_type_t #foreign flecs;

/* Insert record into table.
 * This will create a new record for the table, which inserts a value for each
 * component. An optional entity and record can be provided.
 *
 * If a non-zero entity id is provided, a record must also be provided and vice
 * versa. The record must be created by the entity index. If the provided record
 * is not created for the specified entity, the behavior will be undefined.
 *
 * If the provided record is not managed by the entity index, the behavior will
 * be undefined.
 *
 * The returned record contains a reference to the table and the table row. The
 * data pointed to by the record is guaranteed not to move unless one or more
 * rows are removed from this table. A row can be removed as result of a delete,
 * or by adding/removing components from an entity stored in the table.
 *
 * @param world The world.
 * @param table The table.
 * @param entity The entity.
 * @param record The entity-index record for the specified entity.
 * @return A record containing the table and table row.
 */
ecs_table_insert :: (
    world: *ecs_world_t,
    table: *ecs_table_t,
    entity: ecs_entity_t,
    record: *ecs_record_t) -> ecs_record_t #foreign flecs;

/* Returns the number of records in the table.
 * This operation returns the number of records that have been populated through
 * the regular (entity) API as well as the number of records that have been
 * inserted using the direct access API.
 *
 * @param world The world.
 * @param table The table.
 * @return The number of records in a table.
 */
ecs_table_count :: (
    table: *ecs_table_t) -> int32_t #foreign flecs;

/* Get table that has all components of current table plus the specified id.
 * If the provided table already has the provided id, the operation will return
 * the provided table.
 *
 * @param world The world.
 * @param table The table.
 * @param id The id to add.
 * @result The resulting table.
 */
ecs_table_add_id :: (
    world: *ecs_world_t,
    table: *ecs_table_t,
    id: ecs_id_t) -> *ecs_table_t #foreign flecs;

/* Get table that has all components of current table minus the specified id.
 * If the provided table doesn't have the provided id, the operation will return
 * the provided table.
 *
 * @param world The world.
 * @param table The table.
 * @param id The id to remove.
 * @result The resulting table.
 */
ecs_table_remove_id :: (
    world: *ecs_world_t,
    table: *ecs_table_t,
    id: ecs_id_t) -> ecs_table_t #foreign flecs;

/* Lock or unlock table.
 * When a table is locked, modifications to it will trigger an assert. When the
 * table is locked recursively, it will take an equal amount of unlock
 * operations to actually unlock the table.
 *
 * Table locks can be used to build safe iterators where it is guaranteed that
 * the contents of a table are not modified while it is being iterated.
 *
 * The operation only works when called on the world, and has no side effects
 * when called on a stage. The assumption is that when called on a stage,
 * operations are deferred already.
 *
 * @param world The world.
 * @param table The table to lock.
 */
ecs_table_lock :: (
    world: *ecs_world_t,
    table: *ecs_table_t) #foreign flecs;

/* Unlock a table.
 * Must be called after calling ecs_table_lock.
 *
 * @param world The world.
 * @param table The table to unlock.
 */
ecs_table_unlock :: (
    world: *ecs_world_t,
    table: *ecs_table_t) #foreign flecs;

/* Returns whether table is a module or contains module contents
 * Returns true for tables that have module contents. Can be used to filter out
 * tables that do not contain application data.
 *
 * @param table The table.
 * @return true if table contains module contents, false if not.
 */
ecs_table_has_module :: (
    table: *ecs_table_t) -> bool #foreign flecs;

/* Commit (move) entity to a table.
 * This operation moves an entity from its current table to the specified
 * table. This may trigger the following actions:
 * - Ctor for each component in the target table
 * - Move for each overlapping component
 * - Dtor for each component in the source table.
 * - OnAdd triggers for non-overlapping components in the target table
 * - OnRemove triggers for non-overlapping components in the source table.
 *
 * This operation is a faster than adding/removing components individually.
 *
 * The application must explicitly provide the difference in components between
 * tables as the added/removed parameters. This can usually be derived directly
 * from the result of ecs_table_add_id and esc_table_remove_id. These arrays are
 * required to properly execute OnAdd/OnRemove triggers.
 *
 * @param world The world.
 * @param entity The entity to commit.
 * @param record The entity's record (optional, providing it saves a lookup).
 * @param table The table to commit the entity to.
 * @return True if the entity got moved, false otherwise.
 */
ecs_commit :: (
    world: *ecs_world_t,
    entity: ecs_entity_t,
    record: *ecs_record_t,
    table: *ecs_table_t,
    added: *ecs_entities_t,
    removed: *ecs_entities_t) -> bool #foreign flecs;

/* @} */

/* Optional modules */
#ifdef FLECS_SYSTEM
/*
 * @file system.h
 * @brief System module.
 *
 * The system module allows for creating and running systems. A system is a
 * query in combination with a callback function. In addition systems have
 * support for time management and can be monitored by the stats addon.
 */

#ifdef FLECS_SYSTEM

#ifndef FLECS_MODULE
#define FLECS_MODULE
#endif

/*
 * @file module.h
 * @brief Module addon.
 *
 * The module addon allows for creating and importing modules. Flecs modules
 * enable applications to organize components and systems into reusable units of
 * code that can easily be across projects.
 */

#ifdef FLECS_MODULE

#ifndef FLECS_MODULE_H
#define FLECS_MODULE_H

#ifdef __cplusplus
extern "C" {
#endif

/* Import a module.
 * This operation will load a modules and store the public module handles in the
 * handles_out out parameter. The module name will be used to verify if the
 * module was already loaded, in which case it won't be reimported. The name
 * will be translated from PascalCase to an entity path (pascal.case) before the
 * lookup occurs.
 *
 * Module contents will be stored as children of the module entity. This
 * prevents modules from accidentally defining conflicting identifiers. This is
 * enforced by setting the scope before and after loading the module to the
 * module entity id.
 *
 * A more convenient way to import a module is by using the ECS_IMPORT macro.
 *
 * @param world The world.
 * @param module The module to load.
 * @param module_name The name of the module to load.
 * @param flags An integer that will be passed into the module import action.
 * @param handles_out A struct with handles to the module components/systems.
 * @param handles_size Size of the handles_out parameter.
 * @return The module entity.
 */
FLECS_API
ecs_entity_t ecs_import(
    ecs_world_t *world,
    ecs_module_action_t module,
    char *module_name,
    void *handles_out,
    size_t handles_size);

/* Import a module from a library.
 * Similar to ecs_import, except that this operation will attempt to load the
 * module from a dynamic library.
 *
 * A library may contain multiple modules, which is why both a library name and
 * a module name need to be provided. If only a library name is provided, the
 * library name will be reused for the module name.
 *
 * The library will be looked up using a canonical name, which is in the same
 * form as a module, like `flecs.components.transform`. To transform this
 * identifier to a platform specific library name, the operation relies on the
 * module_to_dl callback of the os_api which the application has to override if
 * the default does not yield the correct library name.
 *
 * @param world The world.
 * @param library_name The name of the library to load.
 * @param module_name The name of the module to load.
 */
FLECS_API
ecs_entity_t ecs_import_from_library(
    ecs_world_t *world,
    char *library_name,
    char *module_name);

/* Define module
 */
#define ECS_MODULE(world, id)\
    ecs_id_t ecs_id(id) = ecs_new_module(world, 0, #id, sizeof(id), ECS_ALIGNOF(id));\
    ECS_VECTOR_STACK(FLECS__T##id, ecs_entity_t, &FLECS__E##id, 1);\
    id *handles = (id*)ecs_get_mut(world, ecs_id(id), id, NULL);\
    (void)ecs_id(id);\
    (void)ecs_type(id);\
    (void)handles;

/* Wrapper around ecs_import.
 * This macro provides a convenient way to load a module with the world. It can
 * be used like this:
 *
 * ECS_IMPORT(world, FlecsSystemsPhysics, 0);
 *
 * This macro will define entity and type handles for the component associated
 * with the module. An application can retrieve the module component like this:
 *
 * FlecsSystemsPhysics m = ecs_get(world, EcsSingleton, FlecsSystemsPhysics);
 *
 * The contents of a module component are module specific, although they
 * typically contain handles to the content of the module.
 */
#define ECS_IMPORT(world, id) \
    id ecs_module(id);\
    char *id##__name = ecs_module_path_from_c(#id);\
    ecs_id_t ecs_id(id) = ecs_import(\
        world, id##Import, id##__name, &ecs_module(id), sizeof(id));\
    ecs_os_free(id##__name);\
    ECS_VECTOR_STACK(FLECS__T##id, ecs_entity_t, &FLECS__E##id, 1);\
    id##ImportHandles(ecs_module(id));\
    (void)ecs_id(id);\
    (void)ecs_type(id);\

/* Utility macro for declaring a component inside a handles type */
#define ECS_DECLARE_COMPONENT(id)\
    ecs_id_t ecs_id(id);\
    ecs_type_t ecs_type(id)

/* Utility macro for declaring an entity inside a handles type */
#define ECS_DECLARE_ENTITY(id)\
    ecs_entity_t id;\
    ecs_type_t ecs_type(id)

/* Utility macro for declaring a type inside a handles type */
#define ECS_DECLARE_TYPE(id)\
    ECS_DECLARE_ENTITY(id)

/* Utility macro for setting a component in a module function */
#define ECS_SET_COMPONENT(id)\
    if (handles) handles->ecs_id(id) = ecs_id(id);\
    if (handles) handles->ecs_type(id) = ecs_type(id)

/* Utility macro for setting an entity in a module function */
#define ECS_SET_ENTITY(id)\
    if (handles) handles->id = id;

/* Utility macro for setting a type in a module function */
#define ECS_SET_TYPE(id)\
    if (handles) handles->id = id;\
    if (handles) handles->ecs_type(id) = ecs_type(id);

#define ECS_EXPORT_COMPONENT(id)\
    ECS_SET_COMPONENT(id)

#define ECS_EXPORT_ENTITY(id)\
    ECS_SET_ENTITY(id)

#define ECS_EXPORT_TYPE(id)\
    ECS_SET_TYPE(id)

/* Utility macro for importing a component */
#define ECS_IMPORT_COMPONENT(handles, id)\
    ecs_id_t ecs_id(id) = (handles).ecs_id(id); (void)ecs_id(id);\
    ECS_VECTOR_STACK(FLECS__T##id, ecs_entity_t, &FLECS__E##id, 1);\
    (void)ecs_id(id);\
    (void)ecs_type(id)

/* Utility macro for importing an entity */
#define ECS_IMPORT_ENTITY(handles, id)\
    ecs_entity_t id = (handles).id;\
    ECS_VECTOR_STACK(FLECS__T##id, ecs_entity_t, &id, 1);\
    (void)id;\
    (void)ecs_type(id)

/* Utility macro for importing a type */
#define ECS_IMPORT_TYPE(handles, id)\
    ecs_entity_t id = (handles).id;\
    ecs_type_t ecs_type(id) = (handles).ecs_type(id);\
    (void)id;\
    (void)ecs_type(id)

#ifdef __cplusplus
}
#endif

#endif

#endif

#ifndef FLECS_SYSTEMS_H
#define FLECS_SYSTEMS_H

#ifdef __cplusplus
extern "C" {
#endif


////////////////////////////////////////////////////////////////////////////////
//// Components
////////////////////////////////////////////////////////////////////////////////

FLECS_API
extern ecs_type_t
    ecs_type(EcsSystem),
    ecs_type(EcsTickSource);

/* Component used to provide a tick source to systems */
typedef struct EcsTickSource {
    bool tick;                 /* True if providing tick */
    FLECS_FLOAT time_elapsed;  /* Time elapsed since last tick */
} EcsTickSource;

////////////////////////////////////////////////////////////////////////////////
//// Systems API
////////////////////////////////////////////////////////////////////////////////

/* System status change callback */
typedef enum ecs_system_status_t {
    EcsSystemStatusNone = 0,
    EcsSystemEnabled,
    EcsSystemDisabled,
    EcsSystemActivated,
    EcsSystemDeactivated
} ecs_system_status_t;

/* System status action.
 * The status action is invoked whenever a system is enabled or disabled. Note
 * that a system may be enabled but may not actually match any entities. In this
 * case the system is enabled but not _active_.
 *
 * In addition to communicating the enabled / disabled status, the action also
 * communicates changes in the activation status of the system. A system becomes
 * active when it has one or more matching entities, and becomes inactive when
 * it no longer matches any entities.
 *
 * A system switches between enabled and disabled when an application invokes the
 * ecs_enable operation with a state different from the state of the system, for
 * example the system is disabled, and ecs_enable is invoked with enabled: true.
 *
 * Additionally a system may switch between enabled and disabled when it is an
 * EcsOnDemand system, and interest is generated or lost for one of its [out]
 * columns.
 *
 * @param world The world.
 * @param system The system for which to set the action.
 * @param action The action.
 * @param ctx Context that will be passed to the action when invoked.
 */
typedef void (*ecs_system_status_action_t)(
    ecs_world_t *world,
    ecs_entity_t system,
    ecs_system_status_t status,
    void *ctx);

/* Use with ecs_system_init */
typedef struct ecs_system_desc_t {
    /* System entity creation parameters */
    ecs_entity_desc_t entity;

    /* System query parameters */
    ecs_query_desc_t query;

    /* System callback, invoked when system is ran */
    ecs_iter_action_t callback;

    /* System status callback, invoked when system status changes */
    ecs_system_status_action_t status_callback;

    /* Context to be passed to callback (as ecs_iter_t::param) */
    void *ctx;

    /* Context to be passed to system status callback */
    void *status_ctx;

    /* Binding context, for when system is implemented in other language */
    void *binding_ctx;

    /* Functions that are invoked during system cleanup to free context data.
     * When set, functions are called unconditionally, even when the ctx
     * pointers are NULL. */
    ecs_ctx_free_t ctx_free;
    ecs_ctx_free_t status_ctx_free;
    ecs_ctx_free_t binding_ctx_free;

    /* Interval in seconds at which the system should run */
    FLECS_FLOAT interval;

    /* Rate at which the system should run */
    int32_t rate;

    /* External tick soutce that determines when system ticks */
    ecs_entity_t tick_source;
} ecs_system_desc_t;

/* Create a system */
FLECS_API
ecs_entity_t ecs_system_init(
    ecs_world_t *world,
    ecs_system_desc_t *desc);

#ifndef FLECS_LEGACY
#define ECS_SYSTEM(world, id, kind, ...) \
    ecs_iter_action_t ecs_iter_action(id) = id;\
    ecs_entity_t id = ecs_system_init(world, &(ecs_system_desc_t){\
        .entity = { .name = #id, .add = {kind} },\
        .query.filter.expr = #__VA_ARGS__,\
        .callback = ecs_iter_action(id)\
    });\
    ecs_assert(id != 0, ECS_INVALID_PARAMETER, NULL);\
    (void)ecs_iter_action(id);\
    (void)id;
#endif

/* Deprecated, use ecs_trigger_init */
#define ECS_TRIGGER(world, trigger_name, kind, component) \
    ecs_entity_t __F##trigger_name = ecs_trigger_init(world, &(ecs_trigger_desc_t){\
        .entity.name = #trigger_name,\
        .callback = trigger_name,\
        .expr = #component,\
        .events = {kind},\
    });\
    ecs_entity_t trigger_name = __F##trigger_name;\
    ecs_assert(trigger_name != 0, ECS_INVALID_PARAMETER, NULL);\
    (void)__F##trigger_name;\
    (void)trigger_name;

/* Run a specific system manually.
 * This operation runs a single system manually. It is an efficient way to
 * invoke logic on a set of entities, as manual systems are only matched to
 * tables at creation time or after creation time, when a new table is created.
 *
 * Manual systems are useful to evaluate lists of prematched entities at
 * application defined times. Because none of the matching logic is evaluated
 * before the system is invoked, manual systems are much more efficient than
 * manually obtaining a list of entities and retrieving their components.
 *
 * An application may pass custom data to a system through the param parameter.
 * This data can be accessed by the system through the param member in the
 * ecs_iter_t value that is passed to the system callback.
 *
 * Any system may interrupt execution by setting the interrupted_by member in
 * the ecs_iter_t value. This is particularly useful for manual systems, where
 * the value of interrupted_by is returned by this operation. This, in
 * cominbation with the param argument lets applications use manual systems
 * to lookup entities: once the entity has been found its handle is passed to
 * interrupted_by, which is then subsequently returned.
 *
 * @param world The world.
 * @param system The system to run.
 * @param delta_time: The time passed since the last system invocation.
 * @param param A user-defined parameter to pass to the system.
 * @return handle to last evaluated entity if system was interrupted.
 */
FLECS_API
ecs_entity_t ecs_run(
    ecs_world_t *world,
    ecs_entity_t system,
    FLECS_FLOAT delta_time,
    void *param);

/* Same as ecs_run, but subdivides entities across number of provided stages.
 *
 * @param world The world.
 * @param system The system to run.
 * @param stage_current The id of the current stage.
 * @param stage_count The total number of stages.
 * @param delta_time: The time passed since the last system invocation.
 * @param param A user-defined parameter to pass to the system.
 * @return handle to last evaluated entity if system was interrupted.
 */
FLECS_API
ecs_entity_t ecs_run_worker(
    ecs_world_t *world,
    ecs_entity_t system,
    int32_t stage_current,
    int32_t stage_count,
    FLECS_FLOAT delta_time,
    void *param);

/* Run system with offset/limit and type filter.
 * This operation is the same as ecs_run, but filters the entities that will be
 * iterated by the system.
 *
 * Entities can be filtered in two ways. Offset and limit control the range of
 * entities that is iterated over. The range is applied to all entities matched
 * with the system, thus may cover multiple archetypes.
 *
 * The type filter controls which entity types the system will evaluate. Only
 * types that contain all components in the type filter will be iterated over. A
 * type filter is only evaluated once per table, which makes filtering cheap if
 * the number of entities is large and the number of tables is small, but not as
 * cheap as filtering in the system signature.
 *
 * @param world The world.
 * @param system The system to invoke.
 * @param delta_time: The time passed since the last system invocation.
 * @param filter A component or type to filter matched entities.
 * @param param A user-defined parameter to pass to the system.
 * @return handle to last evaluated entity if system was interrupted.
 */
FLECS_API
ecs_entity_t ecs_run_w_filter(
    ecs_world_t *world,
    ecs_entity_t system,
    FLECS_FLOAT delta_time,
    int32_t offset,
    int32_t limit,
    ecs_filter_t *filter,
    void *param);

/* Get the query object for a system.
 * Systems use queries under the hood. This enables an application to get access
 * to the underlying query object of a system. This can be useful when, for
 * example, an application needs to enable sorting for a system.
 *
 * @param world The world.
 * @param system The system from which to obtain the query.
 * @return The query.
 */
FLECS_API
ecs_query_t* ecs_get_system_query(
    ecs_world_t *world,
    ecs_entity_t system);

/* Get system context.
 * This operation returns the context pointer set for the system. If
 * the provided entity is not a system, the function will return NULL.
 *
 * @param world The world.
 * @param system The system from which to obtain the context.
 * @return The context.
 */
FLECS_API
void* ecs_get_system_ctx(
    ecs_world_t *world,
    ecs_entity_t system);

/* Get system binding context.
 * The binding context is a context typically used to attach any language
 * binding specific data that is needed when invoking a callback that is
 * implemented in another language.
 *
 * @param world The world.
 * @param system The system from which to obtain the context.
 * @return The context.
 */
FLECS_API
void* ecs_get_system_binding_ctx(
    ecs_world_t *world,
    ecs_entity_t system);

////////////////////////////////////////////////////////////////////////////////
//// System debug API
////////////////////////////////////////////////////////////////////////////////

typedef struct ecs_dbg_system_t {
    ecs_entity_t system;
    int32_t entities_matched_count;
    int32_t active_table_count;
    int32_t inactive_table_count;
    bool enabled;
    void *system_data;
} ecs_dbg_system_t;

FLECS_API
int ecs_dbg_system(
    ecs_world_t *world,
    ecs_entity_t system,
    ecs_dbg_system_t *dbg_out);

FLECS_API
ecs_table_t* ecs_dbg_get_active_table(
    ecs_world_t *world,
    ecs_dbg_system_t *dbg,
    int32_t index);

FLECS_API
ecs_table_t* ecs_dbg_get_inactive_table(
    ecs_world_t *world,
    ecs_dbg_system_t *dbg,
    int32_t index);

FLECS_API
ecs_type_t ecs_dbg_get_column_type(
    ecs_world_t *world,
    ecs_entity_t system,
    int32_t column_index);

FLECS_API
bool ecs_dbg_match_entity(
    ecs_world_t *world,
    ecs_entity_t entity,
    ecs_entity_t system,
    ecs_match_failure_t *failure_info_out);


////////////////////////////////////////////////////////////////////////////////
//// Module
////////////////////////////////////////////////////////////////////////////////

/* Pipeline component is empty: components and tags in module are static */
typedef struct FlecsSystem {
    int32_t dummy;
} FlecsSystem;

FLECS_API
void FlecsSystemImport(
    ecs_world_t *world);

#define FlecsSystemImportHandles(handles)

#ifdef __cplusplus
}
#endif

#endif

#endif
#endif
#ifdef FLECS_PIPELINE
/*
 * @file pipeline.h
 * @brief Pipeline module.
 *
 * The pipeline module provides support for running systems automatically and
 * on multiple threads. A pipeline is a collection of tags that can be added to
 * systems. When ran, a pipeline will query for all systems that have the tags
 * that belong to a pipeline, and run them.
 *
 * The module defines a number of builtin tags (EcsPreUpdate, EcsOnUpdate,
 * EcsPostUpdate etc.) that are registered with the builtin pipeline. The
 * builtin pipeline is ran by default when calling ecs_progress(). An
 * application can set a custom pipeline with the ecs_set_pipeline function.
 */

#ifdef FLECS_PIPELINE

#ifndef FLECS_SYSTEM
#define FLECS_SYSTEM
#endif


#ifndef FLECS_PIPELINE_H
#define FLECS_PIPELINE_H

#ifdef __cplusplus
extern "C" {
#endif

#ifndef FLECS_LEGACY
#define ECS_PIPELINE(world, id, ...) \
    ecs_entity_t id = ecs_type_init(world, &(ecs_type_desc_t){\
        .entity = {\
            .name = #id,\
            .add = {EcsPipeline}\
        },\
        .ids_expr = #__VA_ARGS__\
    });
#endif

/* Set a custom pipeline.
 * This operation sets the pipeline to run when ecs_progress is invoked.
 *
 * @param world The world.
 * @param pipeline The pipeline to set.
 */
FLECS_API
void ecs_set_pipeline(
    ecs_world_t *world,
    ecs_entity_t pipeline);

/* Get the current pipeline.
 * This operation gets the current pipeline.
 *
 * @param world The world.
 * @param pipeline The pipeline to set.
 */
FLECS_API
ecs_entity_t ecs_get_pipeline(
    ecs_world_t *world);

/* Progress a world.
 * This operation progresses the world by running all systems that are both
 * enabled and periodic on their matching entities.
 *
 * An application can pass a delta_time into the function, which is the time
 * passed since the last frame. This value is passed to systems so they can
 * update entity values proportional to the elapsed time since their last
 * invocation.
 *
 * When an application passes 0 to delta_time, ecs_progress will automatically
 * measure the time passed since the last frame. If an application does not uses
 * time management, it should pass a non-zero value for delta_time (1.0 is
 * recommended). That way, no time will be wasted measuring the time.
 *
 * @param world The world to progress.
 * @param delta_time The time passed since the last frame.
 * @return false if ecs_quit has been called, true otherwise.
 */
FLECS_API
bool ecs_progress(
    ecs_world_t *world,
    FLECS_FLOAT delta_time);

/* Set time scale.
 * Increase or decrease simulation speed by the provided multiplier.
 *
 * @param world The world.
 * @param scale The scale to apply (default = 1).
 */
FLECS_API
void ecs_set_time_scale(
    ecs_world_t *world,
    FLECS_FLOAT scale);

/* Reset world clock.
 * Reset the clock that keeps track of the total time passed in the simulation.
 *
 * @param world The world.
 */
FLECS_API
void ecs_reset_clock(
    ecs_world_t *world);

/* Run pipeline.
 * This will run all systems in the provided pipeline. This operation may be
 * invoked from multiple threads, and only when staging is disabled, as the
 * pipeline manages staging and, if necessary, synchronization between threads.
 *
 * If 0 is provided for the pipeline id, the default pipeline will be ran (this
 * is either the builtin pipeline or the pipeline set with set_pipeline()).
 *
 * When using progress() this operation will be invoked automatically for the
 * default pipeline (either the builtin pipeline or the pipeline set with
 * set_pipeline()). An application may run additional pipelines.
 *
 * Note: calling this function from an application currently only works in
 * single threaded applications with a single stage.
 *
 * @param world The world.
 * @param pipeline The pipeline to run.
 */
FLECS_API
void ecs_pipeline_run(
    ecs_world_t *world,
    ecs_entity_t pipeline,
    FLECS_FLOAT delta_time);

/* Deactivate systems that are not matched with tables.
 * By default Flecs deactivates systems that are not matched with any tables.
 * However, once a system has been matched with a table it remains activated, to
 * prevent systems from continuously becoming active and inactive.
 *
 * To re-deactivate systems, an application can invoke this function, which will
 * deactivate all systems that are not matched with any tables.
 *
 * @param world The world.
 */
FLECS_API
void ecs_deactivate_systems(
    ecs_world_t *world);


////////////////////////////////////////////////////////////////////////////////
//// Threading
////////////////////////////////////////////////////////////////////////////////

/* Set number of worker threads.
 * Setting this value to a value higher than 1 will start as many threads and
 * will cause systems to evenly distribute matched entities across threads. The
 * operation may be called multiple times to reconfigure the number of threads
 * used, but never while running a system / pipeline. */
FLECS_API
void ecs_set_threads(
    ecs_world_t *world,
    int32_t threads);

////////////////////////////////////////////////////////////////////////////////
//// Module
////////////////////////////////////////////////////////////////////////////////

/* Pipeline component is empty: components and tags in module are static */
typedef struct FlecsPipeline {
    int32_t dummy;
} FlecsPipeline;

FLECS_API
void FlecsPipelineImport(
    ecs_world_t *world);

#define FlecsPipelineImportHandles(handles)

#ifdef __cplusplus
}
#endif

#endif

#endif
#endif
#ifdef FLECS_TIMER
/*
 * @file timer.h
 * @brief Timer module.
 *
 * Timers can be used to trigger actions at periodic or one-shot intervals. They
 * are typically used together with systems and pipelines.
 */

#ifdef FLECS_TIMER

#ifndef FLECS_MODULE
#define FLECS_MODULE
#endif

#ifndef FLECS_PIPELINE
#define FLECS_PIPELINE
#endif

#ifndef FLECS_TIMER_H
#define FLECS_TIMER_H


#ifdef __cplusplus
extern "C" {
#endif


////////////////////////////////////////////////////////////////////////////////
//// Components
////////////////////////////////////////////////////////////////////////////////

FLECS_API
extern ecs_type_t
    ecs_type(EcsTimer),
    ecs_type(EcsRateFilter);

/* Component used for one shot/interval timer functionality */
typedef struct EcsTimer {
    FLECS_FLOAT timeout;         /* Timer timeout period */
    FLECS_FLOAT time;            /* Incrementing time value */
    int32_t fired_count;         /* Number of times ticked */
    bool active;                 /* Is the timer active or not */
    bool single_shot;            /* Is this a single shot timer */
} EcsTimer;

/* Apply a rate filter to a tick source */
typedef struct EcsRateFilter {
    ecs_entity_t src;            /* Source of the rate filter */
    int32_t rate;                /* Rate of the rate filter */
    int32_t tick_count;          /* Number of times the rate filter ticked */
    FLECS_FLOAT time_elapsed;    /* Time elapsed since last tick */
} EcsRateFilter;


////////////////////////////////////////////////////////////////////////////////
//// Timer API
////////////////////////////////////////////////////////////////////////////////

/* Set timer timeout.
 * This operation executes any systems associated with the timer after the
 * specified timeout value. If the entity contains an existing timer, the
 * timeout value will be reset. The timer can be started and stopped with
 * ecs_start_timer and ecs_stop_timer.
 *
 * The timer is synchronous, and is incremented each frame by delta_time.
 *
 * The tick_source entity will be be a tick source after this operation. Tick
 * sources can be read by getting the EcsTickSource component. If the tick
 * source ticked this frame, the 'tick' member will be true. When the tick
 * source is a system, the system will tick when the timer ticks.
 *
 * @param world The world.
 * @param tick_source The timer for which to set the timeout (0 to create one).
 * @param timeout The timeout value.
 * @return The timer entity.
 */
FLECS_API
ecs_entity_t ecs_set_timeout(
    ecs_world_t *world,
    ecs_entity_t tick_source,
    FLECS_FLOAT timeout);

/* Get current timeout value for the specified timer.
 * This operation returns the value set by ecs_set_timeout. If no timer is
 * active for this entity, the operation returns 0.
 *
 * After the timeout expires the EcsTimer component is removed from the entity.
 * This means that if ecs_get_timeout is invoked after the timer is expired, the
 * operation will return 0.
 *
 * The timer is synchronous, and is incremented each frame by delta_time.
 *
 * The tick_source entity will be be a tick source after this operation. Tick
 * sources can be read by getting the EcsTickSource component. If the tick
 * source ticked this frame, the 'tick' member will be true. When the tick
 * source is a system, the system will tick when the timer ticks.
 *
 * @param world The world.
 * @param tick_source The timer.
 * @return The current timeout value, or 0 if no timer is active.
 */
FLECS_API
FLECS_FLOAT ecs_get_timeout(
    ecs_world_t *world,
    ecs_entity_t tick_source);

/* Set timer interval.
 * This operation will continously invoke systems associated with the timer
 * after the interval period expires. If the entity contains an existing timer,
 * the interval value will be reset.
 *
 * The timer is synchronous, and is incremented each frame by delta_time.
 *
 * The tick_source entity will be be a tick source after this operation. Tick
 * sources can be read by getting the EcsTickSource component. If the tick
 * source ticked this frame, the 'tick' member will be true. When the tick
 * source is a system, the system will tick when the timer ticks.
 *
 * @param world The world.
 * @param tick_source The timer for which to set the interval (0 to create one).
 * @param interval The interval value.
 * @return The timer entity.
 */
FLECS_API
ecs_entity_t ecs_set_interval(
    ecs_world_t *world,
    ecs_entity_t tick_source,
    FLECS_FLOAT interval);

/* Get current interval value for the specified timer.
 * This operation returns the value set by ecs_set_interval. If the entity is
 * not a timer, the operation will return 0.
 *
 * @param world The world.
 * @param tick_source The timer for which to set the interval.
 * @return The current interval value, or 0 if no timer is active.
 */
FLECS_API
FLECS_FLOAT ecs_get_interval(
    ecs_world_t *world,
    ecs_entity_t tick_source);

/* Start timer.
 * This operation resets the timer and starts it with the specified timeout. The
 * entity must have the EcsTimer component (added by ecs_set_timeout and
 * ecs_set_interval). If the entity does not have the EcsTimer component this
 * operation will assert.
 *
 * @param world The world.
 * @param tick_source The timer to start.
 */
FLECS_API
void ecs_start_timer(
    ecs_world_t *world,
    ecs_entity_t tick_source);

/* Stop timer
 * This operation stops a timer from triggering. The entity must have the
 * EcsTimer component or this operation will assert.
 *
 * @param world The world.
 * @param tick_source The timer to stop.
 */
FLECS_API
void ecs_stop_timer(
    ecs_world_t *world,
    ecs_entity_t tick_source);

/* Set rate filter.
 * This operation initializes a rate filter. Rate filters sample tick sources
 * and tick at a configurable multiple. A rate filter is a tick source itself,
 * which means that rate filters can be chained.
 *
 * Rate filters enable deterministic system execution which cannot be achieved
 * with interval timers alone. For example, if timer A has interval 2.0 and
 * timer B has interval 4.0, it is not guaranteed that B will tick at exactly
 * twice the multiple of A. This is partly due to the indeterministic nature of
 * timers, and partly due to floating point rounding errors.
 *
 * Rate filters can be combined with timers (or other rate filters) to ensure
 * that a system ticks at an exact multiple of a tick source (which can be
 * another system). If a rate filter is created with a rate of 1 it will tick
 * at the exact same time as its source.
 *
 * If no tick source is provided, the rate filter will use the frame tick as
 * source, which corresponds with the number of times ecs_progress is called.
 *
 * The tick_source entity will be be a tick source after this operation. Tick
 * sources can be read by getting the EcsTickSource component. If the tick
 * source ticked this frame, the 'tick' member will be true. When the tick
 * source is a system, the system will tick when the timer ticks.
 *
 * @param world The world.
 * @param tick_source The rate filter entity (0 to create one).
 * @param rate The rate to apply.
 * @param source The tick source (0 to use frames)
 * @return The filter entity.
 */
FLECS_API
ecs_entity_t ecs_set_rate(
    ecs_world_t *world,
    ecs_entity_t tick_source,
    int32_t rate,
    ecs_entity_t source);

/* Assign tick source to system.
 * Systems can be their own tick source, which can be any of the tick sources
 * (one shot timers, interval times and rate filters). However, in some cases it
 * is must be guaranteed that different systems tick on the exact same frame.
 *
 * This cannot be guaranteed by giving two systems the same interval/rate filter
 * as it is possible that one system is (for example) disabled, which would
 * cause the systems to go out of sync. To provide these guarantees, systems
 * must use the same tick source, which is what this operation enables.
 *
 * When two systems share the same tick source, it is guaranteed that they tick
 * in the same frame. The provided tick source can be any entity that is a tick
 * source, including another system. If the provided entity is not a tick source
 * the system will not be ran.
 *
 * To disassociate a tick source from a system, use 0 for the tick_source
 * parameter.
 *
 * @param world The world.
 * @param system The system to associate with the timer.
 * @param timer The timer to associate with the system.
 */
FLECS_API
void ecs_set_tick_source(
    ecs_world_t *world,
    ecs_entity_t system,
    ecs_entity_t tick_source);


////////////////////////////////////////////////////////////////////////////////
//// Module
////////////////////////////////////////////////////////////////////////////////

/* Timers module component */
typedef struct FlecsTimer {
    int32_t dummy;
} FlecsTimer;

FLECS_API
void FlecsTimerImport(
    ecs_world_t *world);

#define FlecsTimerImportHandles(handles)

#ifdef __cplusplus
}
#endif

#endif

#endif
#endif

/* Optional addons */
#ifdef FLECS_BULK
/*
 * @file bulk.h
 * @brief Bulk operations operate on all entities that match a provided filter.
 */

#ifdef FLECS_BULK

#ifndef FLECS_BULK_H
#define FLECS_BULK_H

#ifdef __cplusplus
extern "C" {
#endif

/* Add an entity to entities matching a filter.
 * This operation is the same as ecs_add_id, but is applied to all entities
 * that match the provided filter.
 *
 * @param world The world.
 * @param entity_add The entity to add.
 * @param filter The filter.
 */
FLECS_API
void ecs_bulk_add_entity(
    ecs_world_t *world,
    ecs_entity_t entity_add,
    ecs_filter_t *filter);

/* Add a type to entities matching a filter.
 * This operation is the same as ecs_add_type but is applied to all entities
 * that match the provided filter.
 *
 * @param world The world.
 * @param type The type to add.
 * @param filter The filter.
 */
FLECS_API
void ecs_bulk_add_type(
    ecs_world_t *world,
    ecs_type_t type,
    ecs_filter_t *filter);

/* Add a component / type / tag to entities matching a filter.
 * This operation is the same as ecs_add but is applied to all entities
 * that match the provided filter.
 *
 * @param world The world.
 * @param type The component, type or tag to add.
 * @param filter The filter.
 */
#define ecs_bulk_add(world, type, filter)\
    ecs_bulk_add_type(world, ecs_type(type), filter)

/* Removes an entity from entities matching a filter.
 * This operation is the same as ecs_remove_id, but is applied to all
 * entities that match the provided filter.
 *
 * @param world The world.
 * @param entity_remove The entity to remove.
 * @param filter The filter.
 */
FLECS_API
void ecs_bulk_remove_entity(
    ecs_world_t *world,
    ecs_entity_t entity_remove,
    ecs_filter_t *filter);

/* Remove a type from entities matching a filter.
 * This operation is the same as ecs_remove_type but is applied to all entities
 * that match the provided filter.
 *
 * @param world The world.
 * @param type The type to remove.
 * @param filter The filter.
 */
FLECS_API
void ecs_bulk_remove_type(
    ecs_world_t *world,
    ecs_type_t type,
    ecs_filter_t *filter);

/* Add a component / type / tag to entities matching a filter.
 * This operation is the same as ecs_remove but is applied to all entities
 * that match the provided filter.
 *
 * @param world The world.
 * @param type The component, type or tag to remove.
 * @param filter The filter.
 */
#define ecs_bulk_remove(world, type, filter)\
    ecs_bulk_remove_type(world, ecs_type(type), filter)

/* Add / remove type from entities matching a filter.
 * Combination of ecs_bulk_add_type and ecs_bulk_remove_type.
 *
 * @param world The world.
 * @param to_add The type to add.
 * @param to_remove The type to remove.
 * @param filter The filter.
 */
FLECS_API
void ecs_bulk_add_remove_type(
    ecs_world_t *world,
    ecs_type_t to_add,
    ecs_type_t to_remove,
    ecs_filter_t *filter);

/* Add / remove component, type or tag from entities matching a filter.
 * Combination of ecs_bulk_add and ecs_bulk_remove.
 *
 * @param world The world.
 * @param to_add The component, type or tag to add.
 * @param to_remove The component, type or tag to remove.
 * @param filter The filter.
 */
#define ecs_bulk_add_remove(world, to_add, to_remove, filter)\
    ecs_bulk_add_remove_type(world, ecs_type(to_add), ecs_type(to_remove), filter)

/* Delete entities matching a filter.
 * This operation is the same as ecs_delete, but applies to all entities that
 * match a filter.
 *
 * @param world The world.
 * @param filter The filter.
 */
FLECS_API
void ecs_bulk_delete(
    ecs_world_t *world,
    ecs_filter_t *filter);

#ifdef __cplusplus
}
#endif

#endif

#endif
#endif
#ifdef FLECS_DBG
/*
 * @file dbg.h
 * @brief The debug addon enables requesting internals from entities and tables.
 */

#ifdef FLECS_DBG

#ifndef FLECS_DBG_H
#define FLECS_DBG_H

#ifdef __cplusplus
extern "C" {
#endif

/* Unstable API */

typedef struct ecs_dbg_entity_t {
    ecs_entity_t entity;
    ecs_table_t *table;
    ecs_type_t type;
    int32_t row;
    bool is_watched;
} ecs_dbg_entity_t;

typedef struct ecs_dbg_table_t {
    ecs_table_t *table;
    ecs_type_t type;
    ecs_type_t shared;
    ecs_type_t container;
    ecs_type_t parent_entities;
    ecs_type_t base_entities;
    ecs_vector_t *systems_matched;
    ecs_entity_t *entities;
    int32_t entities_count;
} ecs_dbg_table_t;

FLECS_API
void ecs_dbg_entity(
    ecs_world_t *world,
    ecs_entity_t entity,
    ecs_dbg_entity_t *dbg_out);

FLECS_API
ecs_table_t *ecs_dbg_find_table(
    ecs_world_t *world,
    ecs_type_t type);

FLECS_API
ecs_table_t *ecs_dbg_get_table(
    ecs_world_t *world,
    int32_t index);

FLECS_API
bool ecs_dbg_filter_table(
    ecs_world_t *world,
    ecs_table_t *table,
    ecs_filter_t *filter);

FLECS_API
void ecs_dbg_table(
    ecs_world_t *world,
    ecs_table_t *table,
    ecs_dbg_table_t *dbg_out);

#ifdef __cplusplus
}
#endif

#endif

#endif
#endif
#ifdef FLECS_MODULE
#endif
#ifdef FLECS_PARSER
/*
 * @file parser.h
 * @brief Parser addon.
 *
 * The parser addon parses string expressions into lists of terms, and can be
 * used to construct filters, queries and types.
 */

#ifdef FLECS_PARSER

#ifndef FLECS_PARSER_H
#define FLECS_PARSER_H

#ifdef __cplusplus
extern "C" {
#endif

/* Parse term in expression.
 * This operation parses a single term in an expression and returns a pointer
 * to the next term expression.
 *
 * If the returned pointer points to the 0-terminator, the expression is fully
 * parsed. The function would typically be called in a while loop:
 *
 * char *ptr = expr;
 * while (ptr[0] && (ptr = ecs_parse_term(world, name, expr, ptr, &term))) { }
 *
 * The operation does not attempt to find entity ids from the names in the
 * expression. Use the ecs_term_resolve_ids function to resolve the identifiers
 * in the parsed term.
 *
 * The returned term will in most cases contain allocated resources, which
 * should freed (or used) by the application. To free the resources for a term,
 * use the ecs_term_free function.
 *
 * The parser accepts expressions in the legacy string format.
 *
 * @param world The world.
 * @param name The name of the expression (optional, improves error logs)
 * @param expr The expression to parse (optional, improves error logs)
 * @param ptr The pointer to the current term (must be in expr).
 * @param term_out Out parameter for the term.
 * @return pointer to next term if successful, NULL if failed.
 */
FLECS_API
char* ecs_parse_term(
    ecs_world_t *world,
    char *name,
    char *expr,
    char *ptr,
    ecs_term_t *term_out);

#ifdef __cplusplus
}
#endif // __cplusplus

#endif // FLECS_PARSER_H

#endif // FLECS_PARSER
#endif
#ifdef FLECS_QUEUE
/*
 * @file queue.h
 * @brief Queue datastructure.
 *
 * The queue data structure implements a fixed-size ringbuffer. It is not used
 * by the flecs core, but is used by flecs-hub modules.
 */

#ifdef FLECS_QUEUE

#ifndef FLECS_QUEUE_H_
#define FLECS_QUEUE_H_

#ifdef __cplusplus
extern "C" {
#endif

typedef struct ecs_queue_t ecs_queue_t;

FLECS_API
ecs_queue_t* _ecs_queue_new(
    ecs_size_t elem_size,
    int16_t offset,
    int32_t elem_count);

#define ecs_queue_new(T, elem_count)\
    _ecs_queue_new(ECS_VECTOR_T(T), elem_count)

FLECS_API
ecs_queue_t* _ecs_queue_from_array(
    ecs_size_t elem_size,
    int16_t offset,
    int32_t elem_count,
    void *array);

#define ecs_queue_from_array(T, elem_count, array)\
    _ecs_queue_from_array(ECS_VECTOR_T(T), elem_count, array)

FLECS_API
void* _ecs_queue_push(
    ecs_queue_t *queue,
    ecs_size_t elem_size,
    int16_t offset);

#define ecs_queue_push(queue, T)\
    (T*)_ecs_queue_push(queue, ECS_VECTOR_T(T))

FLECS_API
void* _ecs_queue_get(
    ecs_queue_t *queue,
    ecs_size_t elem_size,
    int16_t offset,
    int32_t index);

#define ecs_queue_get(queue, T, index)\
    (T*)_ecs_queue_get(queue, ECS_VECTOR_T(T), index)

#define ecs_queue_get_t(vector, size, alignment, index) \
    _ecs_queue_get(vector, ECS_VECTOR_U(size, alignment), index)

FLECS_API
void* _ecs_queue_last(
    ecs_queue_t *queue,
    ecs_size_t elem_size,
    int16_t offset);

#define ecs_queue_last(queue, T)\
    (T*)_ecs_queue_last(queue, ECS_VECTOR_T(T))

FLECS_API
int32_t ecs_queue_index(
    ecs_queue_t *queue);

FLECS_API
int32_t ecs_queue_count(
    ecs_queue_t *queue);

FLECS_API
void ecs_queue_free(
    ecs_queue_t *queue);

#ifdef __cplusplus
}
#endif

#endif

#endif
#endif
#ifdef FLECS_READER_WRITER
/*
 * @file reader_writer.h
 * @brief Blob serializer addon.
 *
 * The blos serializer addon allows an application to serialize the state of a
 * world to a blob (a flat byte buffer). The addon contains a reader and writer
 * API. The reader reads from a world and serializes it to N fixed-size buffers.
 * The writer reads from N fixed-size buffers and writes to the world.
 *
 * The current limitations of the serializer are:
 * - only POD types
 * - no support for switch types and component enabling/disabling
 */

#ifdef FLECS_READER_WRITER

#ifndef FLECS_READER_WRITER_H
#define FLECS_READER_WRITER_H

#ifdef __cplusplus
extern "C" {
#endif

typedef enum ecs_blob_header_kind_t {
    EcsStreamHeader,

    /* Stream states */
    EcsTableSegment,
    EcsFooterSegment,

    /* Table segment */
    EcsTableHeader,
    EcsTableTypeSize,
    EcsTableType,
    EcsTableSize,
    EcsTableColumn,
    EcsTableColumnHeader,
    EcsTableColumnSize,
    EcsTableColumnData,

    /* Name column (EcsName) */
    EcsTableColumnNameHeader,
    EcsTableColumnNameLength,
    EcsTableColumnName,

    EcsStreamFooter
} ecs_blob_header_kind_t;

typedef struct ecs_table_reader_t {
    ecs_blob_header_kind_t state;

    int32_t table_index;
    ecs_table_t *table;
    ecs_data_t *data;

    /* Current index in type */
    ecs_size_t type_written;
    ecs_type_t type;

    /* Current column */
    ecs_vector_t *column_vector;
    int32_t column_index;
    int32_t total_columns;

    /* Keep track of how much of the component column has been written */
    void *column_data;
    int16_t column_size;
    int16_t column_alignment;
    ecs_size_t column_written;

    /* Keep track of row when writing non-blittable data */
    int32_t row_index;
    int32_t row_count;

    /* Keep track of how much of an entity name has been written */
    char *name;
    ecs_size_t name_len;
    ecs_size_t name_written;

    bool has_next_table;
} ecs_table_reader_t;

typedef struct ecs_reader_t {
    ecs_world_t *world;
    ecs_blob_header_kind_t state;
    ecs_iter_t data_iter;
    ecs_iter_next_action_t data_next;
    ecs_iter_t component_iter;
    ecs_iter_next_action_t component_next;
    ecs_table_reader_t table;
} ecs_reader_t;

typedef struct ecs_name_writer_t {
    char *name;
    int32_t written;
    int32_t len;
    int32_t max_len;
} ecs_name_writer_t;

typedef struct ecs_table_writer_t {
    ecs_blob_header_kind_t state;

    ecs_table_t *table;
    ecs_vector_t *column_vector;

    /* Keep state for parsing type */
    int32_t type_count;
    int32_t type_max_count;
    ecs_size_t type_written;
    ecs_entity_t *type_array;

    int32_t column_index;
    int16_t column_size;
    int16_t column_alignment;
    ecs_size_t column_written;
    void *column_data;

    int32_t row_count;
    int32_t row_index;
    ecs_name_writer_t name;
} ecs_table_writer_t;

typedef struct ecs_writer_t {
    ecs_world_t *world;
    ecs_blob_header_kind_t state;
    ecs_table_writer_t table;
    int error;
} ecs_writer_t;

/* Initialize a reader.
 * A reader serializes data in a world to a sequence of bytes that can be stored
 * in a file or sent across a network.
 *
 * @param world The world to serialize.
 * @return The reader.
 */
FLECS_API
ecs_reader_t ecs_reader_init(
    ecs_world_t *world);

/* Initialize a snapshot reader.
 * A snapshot reader serializes data in a snapshot to a sequence of bytes that
 * can be stored in a file or sent across a network. A snapshot reader has as
 * advantage that serialization can take place asynchronously while the world
 * is progressing.
 *
 * @param world The world in which the snapshot is taken.
 * @param iter Iterator to the data to be serialized.
 * @return The reader.
 */
FLECS_API
ecs_reader_t ecs_reader_init_w_iter(
    ecs_iter_t *iter,
    ecs_iter_next_action_t next);

/* Read from a reader.
 * This operation reads a specified number of bytes from a reader and stores it
 * in the specified buffer. When there are no more bytes to read from the reader
 * the operation will return 0, otherwise it will return the number of bytes
 * read.
 *
 * The specified buffer must be at least as big as the specified size, and the
 * specified size must be a multiple of 4.
 *
 * @param buffer The buffer in which to store the read bytes.
 * @param size The maximum number of bytes to read.
 * @param reader The reader from which to read the bytes.
 * @return The number of bytes read.
 */
FLECS_API
int32_t ecs_reader_read(
    char *buffer,
    int32_t size,
    ecs_reader_t *reader);

/* Initialize a writer.
 * A writer deserializes data from a sequence of bytes into a world. This
 * enables applications to restore data from disk or the network.
 *
 * The provided world must be either empty or compatible with the data to
 * deserialize, where compatible means that the serialized component ids and
 * sizes must match exactly with those in the world. Errors can occur if a world
 * is provided in which components have been declared in a different order, or
 * when components have different type definitions.
 *
 * @param world The world in which to deserialize the data.
 * @return The writer.
 */
FLECS_API
ecs_writer_t ecs_writer_init(
    ecs_world_t *world);

/* Write to a writer.
 * This operation writes a specified number of bytes from a specified buffer
 * into the writer. The writer will restore the deserialized data into the
 * original serialized entities. The write operation may be invoked multiple
 * times with partial buffers, which allows applications to use static buffers
 * when reading from, for example, a file or the network.
 *
 * The data contained in the buffers must have been serialized with the
 * ecs_reader_read operation. If the data does not match the expected format, or
 * the data contains conflicts with the world, the operation will fail. The
 * data must be provided in the same order as produced by ecs_reader_read,
 * but the used buffer size does not have to be the same as the one used by
 * ecs_reader_read. The buffer size must be a multiple of 4.
 *
 * @param buffer The buffer to deserialize.
 * @param size The maximum number of bytes.
 * @param writer The writer to write to.
 * @return Zero if success, non-zero if failed to deserialize.
 */
FLECS_API
int32_t ecs_writer_write(
    char *buffer,
    int32_t size,
    ecs_writer_t *writer);

#ifdef __cplusplus
}
#endif

#endif

#endif
#endif
#ifdef FLECS_SNAPSHOT
/*
 * @file snapshot.h
 * @brief Snapshot addon.
 *
 * A snapshot records the state of a world in a way so that it can be restored
 * later. Snapshots work with POD components and non-POD components, provided
 * that the appropriate lifecycle actions are registered for non-POD components.
 *
 * A snapshot is tightly coupled to a world. It is not possible to restore a
 * snapshot from world A into world B.
 */

#ifdef FLECS_SNAPSHOT

#ifndef FLECS_SNAPSHOT_H
#define FLECS_SNAPSHOT_H

#ifdef __cplusplus
extern "C" {
#endif

/* A snapshot stores the state of a world in a particular point in time. */
typedef struct ecs_snapshot_t ecs_snapshot_t;

/* Create a snapshot.
 * This operation makes a copy of all component in the world that matches the
 * specified filter.
 *
 * @param world The world to snapshot.
 * @param return The snapshot.
 */
FLECS_API
ecs_snapshot_t* ecs_snapshot_take(
    ecs_world_t *world);

/* Create a filtered snapshot.
 * This operation is the same as ecs_snapshot_take, but accepts an iterator so
 * an application can control what is stored by the snapshot.
 *
 * @param iter An iterator to the data to be stored by the snapshot.
 * @param next A function pointer to the next operation for the iterator.
 * @param return The snapshot.
 */
FLECS_API
ecs_snapshot_t* ecs_snapshot_take_w_iter(
    ecs_iter_t *iter,
    ecs_iter_next_action_t action);

/* Restore a snapshot.
 * This operation restores the world to the state it was in when the specified
 * snapshot was taken. A snapshot can only be used once for restoring, as its
 * data replaces the data that is currently in the world.
 * This operation also resets the last issued entity handle, so any calls to
 * ecs_new may return entity ids that have been issued before restoring the
 * snapshot.
 *
 * The world in which the snapshot is restored must be the same as the world in
 * which the snapshot is taken.
 *
 * @param world The world to restore the snapshot to.
 * @param snapshot The snapshot to restore.
 */
FLECS_API
void ecs_snapshot_restore(
    ecs_world_t *world,
    ecs_snapshot_t *snapshot);

/* Obtain iterator to snapshot data.
 *
 * @param snapshot The snapshot to iterate over.
 * @return Iterator to snapshot data. */
FLECS_API
ecs_iter_t ecs_snapshot_iter(
    ecs_snapshot_t *snapshot,
    ecs_filter_t *filter);

/* Progress snapshot iterator.
 *
 * @param iter The snapshot iterator.
 * @return True if more data is available, otherwise false.
 */
FLECS_API
bool ecs_snapshot_next(
    ecs_iter_t *iter);


/* Free snapshot resources.
 * This frees resources associated with a snapshot without restoring it.
 *
 * @param world The world.
 * @param snapshot The snapshot to free.
 */
FLECS_API
void ecs_snapshot_free(
    ecs_snapshot_t *snapshot);

#ifdef __cplusplus
}
#endif

#endif

#endif
#endif
#ifdef FLECS_DIRECT_ACCESS
/*
 * @file direct_access.h
 * @brief Low-level access to underlying data structures for best performance.
 *
 * This API allows for low-level direct access to tables and their columns. The
 * APIs primary intent is to provide fast primitives for new operations. It is
 * not recommended to use the API directly in application code, as invoking the
 * API in an incorrect way can lead to a corrupted datastore.
 */

#ifdef FLECS_DIRECT_ACCESS

#ifndef FLECS_DIRECT_ACCESS_H_
#define FLECS_DIRECT_ACCESS_H_

#ifdef __cplusplus
extern "C" {
#endif

/* Find the index of a column in a table.
 * Table columns are stored in the order of their respective component ids. As
 * this is not trivial for an application to deduce, this operation returns the
 * index of a column in a table for a given component. This index can be used
 * in other table operations to identify a column.
 *
 * The returned index is determined separately for each table. Indices obtained
 * for one table should not be used for another table.
 *
 * @param table The table.
 * @param component The component for which to retrieve the column index.
 * @return The column index, or -1 if the table does not have the component.
 */
FLECS_API
int32_t ecs_table_find_column(
    ecs_table_t *table,
    ecs_entity_t component);

/* Get table column.
 * This operation returns the pointer to a column array. A column contains all
 * the data for a component for the provided table in a contiguous array.
 *
 * The returned pointer is not stable, and may change when a table needs to
 * resize its arrays, for example in order to accomodate for more records.
 *
 * @param table The table.
 * @param column The column index.
 * @return Vector that contains the column array.
 */
FLECS_API
ecs_vector_t* ecs_table_get_column(
    ecs_table_t *table,
    int32_t column);

/* Set table column.
 * This operation enables an application to set a component column for a table.
 * After the operation the column is owned by the table. Any operations that
 * change the column after this operation can cause undefined behavior.
 *
 * Care must be taken that all columns in a table have the same number of
 * elements. If one column has less elements than another, the behavior is
 * undefined. The operation will not check if the assigned column is of the same
 * size as other columns, as this would prevent an application from assigning
 * a set of different columns to a table of a different size.
 *
 * Setting a column will not delete the previous column. It is the
 * responsibility of the application to ensure that the old column is deleted
 * properly (using ecs_table_delete_column).
 *
 * The provided vector must have the same element size and alignment as the
 * target column. If the size and/or alignment do not match, the behavior will
 * be undefined. In debug mode the operation may assert.
 *
 * If the provided vector is NULL, the table will ensure that a vector is
 * created for the provided column. If a vector exists that is not of the
 * same size as the entities vector, it will be resized to match.
 *
 * @param world The world.
 * @param table The table.
 * @param column The column index.
 * @param vector The column data to assing.
 */
FLECS_API
ecs_vector_t* ecs_table_set_column(
    ecs_world_t *world,
    ecs_table_t *table,
    int32_t column,
    ecs_vector_t *vector);

/* Get the vector containing entity ids for the table.
 * This operation obtains the vector with entity ids for the current table. Each
 * entity id is associated with one record, and ids are stored in the same order
 * as the table records. The element type of the vector is ecs_entity_t.
 *
 * @param table The table.
 * @return The vector containing the table's entities.
 */
FLECS_API
ecs_vector_t* ecs_table_get_entities(
    ecs_table_t *table);

/* Get the vector containing pointers to entity records.
 * A table stores cached pointers to entity records for fast access. This
 * operation provides direct access to the vector. The element type of the
 * vector is ecs_record_t*.
 *
 * @param table The table.
 * @return The vector containing the entity records.
 */
FLECS_API
ecs_vector_t* ecs_table_get_records(
    ecs_table_t *table);

/* Clear records.
 * This operation clears records for a world so that they no longer point to a
 * table. This is useful to ensure that a world is left in a consistent state
 * after moving data to destination world.
 *
 * @param records The vector with record pointers
 */
FLECS_API
void ecs_records_clear(
    ecs_vector_t *records);

/* Initialize records.
 * This operation ensures entity records are updated to the provided table.
 *
 * @param world The world.
 * @param entities The vector with entity identifiers.
 * @param records The vector with record pointers.
 * @param table The table in which the entities are stored.
 */
FLECS_API
void ecs_records_update(
    ecs_world_t *world,
    ecs_vector_t *entities,
    ecs_vector_t *records,
    ecs_table_t *table);

/* Set the vector containing entity ids for the table.
 * This operation sets the vector with entity ids for a table. In addition the
 * operation also requires setting a vector with pointers to records. The
 * record pointers in the vector need to be managed by the entity index. If they
 * are not, this can cause undefined behavior.
 *
 * The provided vectors must have the same number of elements as the number of
 * records in the table. If the element count is not the same, this causes
 * undefined behavior.
 *
 * A table must have an entity and record vector, even if the table does not
 * contain entities. For each record that is not an entity, the entity vector
 * should contain 0, and the record vector should contain NULL.
 *
 * @param table The table.
 * @param entities The entity vector.
 * @param records The record vector.
 */
FLECS_API
void ecs_table_set_entities(
    ecs_table_t *table,
    ecs_vector_t *entities,
    ecs_vector_t *records);

/* Delete a column.
 * This operation frees the memory of a table column and will invoke the
 * component destructor if registered.
 *
 * The provided vector does not need to be the same as the vector in the table.
 * The reason the table must be provided is so that the operation can retrieve
 * the correct destructor for the component. If the component does not have a
 * destructor, an application can alternatively delete the vector directly.
 *
 * If the specified vector is NULL, the column of the table will be removed and
 * the table will be updated to no longer point at the column. If an explicit
 * column is provided, the table is not modified. If a column is deleted that is
 * still being pointed to by a table, behavior is undefined. It is the
 * responsibility of the application to ensure that a table no longer points to
 * a deleted column, by using ecs_table_set_column.
 *
 * Simultaneously, if this operation is used to delete a table column, the
 * application should make sure that if the table contains other columns, they
 * are either also deleted, or that the deleted column is replaced by a column
 * of the same size. Note that this also goes for the entity and record vectors,
 * they should have the same number of elements as the other columns.
 *
 * The vector must be of the same component as the specified column. If the
 * vector is not of the same component, behavior will be undefined. In debug
 * mode the API may assert, though it may not always be able to detect a
 * mismatching vector/column.
 *
 * After this operation the vector should no longer be used by the application.
 *
 * @param table The table.
 * @param column The column index.
 * @param vector The column vector to delete.
 */
FLECS_API
void ecs_table_delete_column(
    ecs_world_t *world,
    ecs_table_t *table,
    int32_t column,
    ecs_vector_t *vector);

/* Find a record for a given entity.
 * This operation finds an existing record in the entity index for a given
 * entity. The returned pointer is stable for the lifecycle of the world and can
 * be used as argument for the ecs_record_update operation.
 *
 * The returned record (if found) points to the adminstration that relates an
 * entity id to a table. Updating the value of the returned record will cause
 * operations like ecs_get and ecs_has to look in the updated table.
 *
 * Updating this record to a table in which the entity is not stored causes
 * undefined behavior.
 *
 * When the entity has never been created or is not alive this operation will
 * return NULL.
 *
 * @param world The world.
 * @param entity The entity.
 * @return The record that belongs to the entity, or NULL if not found.
 */
FLECS_API
ecs_record_t* ecs_record_find(
    ecs_world_t *world,
    ecs_entity_t entity);

/* Same as ecs_record_find, but creates record if it doesn't exist.
 * If an entity id has not been created with ecs_new_*, this function can be
 * used to ensure that a record exists for an entity id. If the provided id
 * already exists in the world, the operation will return the existing record.
 *
 * @param world The world.
 * @param entity The entity for which to retrieve the record.
 * @return The (new or existing) record that belongs to the entity.
 */
FLECS_API
ecs_record_t* ecs_record_ensure(
    ecs_world_t *world,
    ecs_entity_t entity);

/* Get value from record.
 * This operation gets a component value from a record. The provided column
 * index must match the table of the record.
 *
 * @param r The record.
 * @param column The column index of the component to get.
 */
FLECS_API
void* ecs_record_get_column(
    ecs_record_t *r,
    int32_t column,
    size_t size);

/* Copy value to a component for a record.
 * This operation sets the component value of a single component for a record.
 * If the component type has a copy action it will be used, otherwise the value
 * be memcpyd into the component array.
 *
 * The provided record does not need to be managed by the entity index but does
 * need to point to a valid record in the table. If the provided index is
 * outside of the range indicating the number of records in the table, behavior
 * is undefined. In debug mode it will cause the operation to assert.
 *
 * @param world The world.
 * @param r The record to set.
 * @param column The column index of the component to set.
 * @param size The size of the component.
 * @param value Pointer to the value to copy.
 */
FLECS_API
void ecs_record_copy_to(
    ecs_world_t *world,
    ecs_record_t *r,
    int32_t column,
    size_t size,
    void *value,
    int32_t count);

/* Memcpy value to a component for a record.
 * Same as ecs_record_copy_to, except that this operation will always use
 * memcpy. This operation should only be used for components that can be safely
 * memcpyd. If the operation is used for a component that has a copy or move
 * action, the behavior is undefined. In debug mode the operation may assert.
 *
 * @param world The world.
 * @param r The record to set.
 * @param column The column index of the component to set.
 * @param size The size of the component.
 * @param value Pointer to the value to move.
 */
FLECS_API
void ecs_record_copy_pod_to(
    ecs_world_t *world,
    ecs_record_t *r,
    int32_t column,
    size_t size,
    void *value,
    int32_t count);

/* Move value to a component for a record.
 * Same as ecs_record_copy_to, except that it uses the move action. If the
 * component has no move action the value will be memcpyd into the component
 * array. After this operation the application can no longer assume that the
 * value passed into the function is valid.
 *
 * @param world The world.
 * @param r The record to set.
 * @param column The column index of the component to set.
 * @param size The size of the component.
 * @param value Pointer to the value to move.
 */
FLECS_API
void ecs_record_move_to(
    ecs_world_t *world,
    ecs_record_t *r,
    int32_t column,
    size_t size,
    void *value,
    int32_t count);

#ifdef __cplusplus
}
#endif

#endif

#endif
#endif
#ifdef FLECS_STATS
/*
 * @file stats.h
 * @brief Statistics addon.
 *
 * The statistics addon enables an application to obtain detailed metrics about
 * the storage, systems and operations of a world.
 */

#ifdef FLECS_STATS

#ifndef FLECS_STATS_H
#define FLECS_STATS_H

#ifdef FLECS_SYSTEM
#endif

#ifdef __cplusplus
extern "C" {
#endif

#define ECS_STAT_WINDOW (60)

/* Simple value that indicates current state */
typedef struct ecs_gauge_t {
    float avg[ECS_STAT_WINDOW];
    float min[ECS_STAT_WINDOW];
    float max[ECS_STAT_WINDOW];
} ecs_gauge_t;

/* Monotonically increasing counter */
typedef struct ecs_counter_t {
    ecs_gauge_t rate;                          /* Keep track of deltas too */
    float value[ECS_STAT_WINDOW];
} ecs_counter_t;

typedef struct ecs_world_stats_t {
    /* Allows struct to be initialized with {0} */
    int32_t dummy_;

    ecs_gauge_t entity_count;                 /* Number of entities */
    ecs_gauge_t component_count;              /* Number of components */
    ecs_gauge_t query_count;                  /* Number of queries */
    ecs_gauge_t system_count;                 /* Number of systems */
    ecs_gauge_t table_count;                  /* Number of tables */
    ecs_gauge_t empty_table_count;            /* Number of empty tables */
    ecs_gauge_t singleton_table_count;        /* Number of singleton tables. Singleton tables are tables with just a single entity that contains itself */
    ecs_gauge_t matched_entity_count;         /* Number of entities matched by queries */
    ecs_gauge_t matched_table_count;          /* Number of tables matched by queries */

    /* Deferred operations */
    ecs_counter_t new_count;
    ecs_counter_t bulk_new_count;
    ecs_counter_t delete_count;
    ecs_counter_t clear_count;
    ecs_counter_t add_count;
    ecs_counter_t remove_count;
    ecs_counter_t set_count;
    ecs_counter_t discard_count;

    /* Timing */
    ecs_counter_t world_time_total_raw;       /* Actual time passed since simulation start (first time progress() is called) */
    ecs_counter_t world_time_total;           /* Simulation time passed since simulation start. Takes into account time scaling */
    ecs_counter_t frame_time_total;           /* Time spent processing a frame. Smaller than world_time_total when load is not 100% */
    ecs_counter_t system_time_total;          /* Time spent on processing systems. */
    ecs_counter_t merge_time_total;           /* Time spent on merging deferred actions. */
    ecs_gauge_t fps;                          /* Frames per second. */
    ecs_gauge_t delta_time;                   /* Delta_time. */

    /* Frame data */
    ecs_counter_t frame_count_total;          /* Number of frames processed. */
    ecs_counter_t merge_count_total;          /* Number of merges executed. */
    ecs_counter_t pipeline_build_count_total; /* Number of system pipeline rebuilds (occurs when an inactive system becomes active). */
    ecs_counter_t systems_ran_frame;          /* Number of systems ran in the last frame. */

    /* Current position in ringbuffer */
    int32_t t;
} ecs_world_stats_t;

/* Statistics for a single query (use ecs_get_query_stats) */
typedef struct ecs_query_stats_t {
    ecs_gauge_t matched_table_count;       /* Number of matched non-empty tables. This is the number of tables
                                            * iterated over when evaluating a query. */

    ecs_gauge_t matched_empty_table_count; /* Number of matched empty tables. Empty tables are not iterated over when
                                            * evaluating a query. */

    ecs_gauge_t matched_entity_count;      /* Number of matched entities across all tables */

    /* Current position in ringbuffer */
    int32_t t;
} ecs_query_stats_t;

/* Statistics for a single system (use ecs_get_system_stats) */
typedef struct ecs_system_stats_t {
    ecs_query_stats_t query_stats;
    ecs_counter_t time_spent;       /* Time spent processing a system */
    ecs_counter_t invoke_count;     /* Number of times system is invoked */
    ecs_gauge_t active;             /* Whether system is active (is matched with >0 entities) */
    ecs_gauge_t enabled;            /* Whether system is enabled */
} ecs_system_stats_t;

/* Statistics for all systems in a pipeline. */
typedef struct ecs_pipeline_stats_t {
    /* Vector with system ids of all systems in the pipeline. The systems are
     * stored in the order they are executed. Merges are represented by a 0. */
    ecs_vector_t *systems;

    /* Map with system statistics. For each system in the systems vector, an
     * entry in the map exists of type ecs_system_stats_t. */
    ecs_map_t *system_stats;
} ecs_pipeline_stats_t;

/* Get world statistics.
 * Obtain statistics for the provided world. This operation loops several times
 * over the tables in the world, and can impact application performance.
 *
 * @param world The world.
 * @param stats Out parameter for statistics.
 */
FLECS_API void ecs_get_world_stats(
    ecs_world_t *world,
    ecs_world_stats_t *stats);

/* Print world statistics.
 * Print statistics obtained by ecs_get_world_statistics and in the
 * ecs_world_info_t struct.
 *
 * @param world The world.
 * @param stats The statistics to print.
 */
FLECS_API void ecs_dump_world_stats(
    ecs_world_t *world,
    ecs_world_stats_t *stats);

/* Get query statistics.
 * Obtain statistics for the provided query.
 *
 * @param world The world.
 * @param query The query.
 * @param stats Out parameter for statistics.
 */
FLECS_API void ecs_get_query_stats(
    ecs_world_t *world,
    ecs_query_t *query,
    ecs_query_stats_t *s);

#ifdef FLECS_SYSTEM
/* Get system statistics.
 * Obtain statistics for the provided system.
 *
 * @param world The world.
 * @param system The system.
 * @param stats Out parameter for statistics.
 * @return true if success, false if not a system.
 */
FLECS_API bool ecs_get_system_stats(
    ecs_world_t *world,
    ecs_entity_t system,
    ecs_system_stats_t *stats);
#endif

#ifdef FLECS_PIPELINE
/* Get pipeline statistics.
 * Obtain statistics for the provided pipeline.
 *
 * @param world The world.
 * @param pipeline The pipeline.
 * @param stats Out parameter for statistics.
 * @return true if success, false if not a pipeline.
 */
FLECS_API bool ecs_get_pipeline_stats(
    ecs_world_t *world,
    ecs_entity_t pipeline,
    ecs_pipeline_stats_t *stats);
#endif

FLECS_API void ecs_gauge_reduce(
    ecs_gauge_t *dst,
    int32_t t_dst,
    ecs_gauge_t *src,
    int32_t t_src);

#ifdef __cplusplus
}
#endif

#endif

#endif
#endif

#ifdef __cplusplus
}

#ifndef FLECS_NO_CPP
#ifndef FLECS_LEGACY
/*
 * @file flecs.hpp
 * @brief Flecs C++ API.
 *
 * This is a C++11 wrapper around the Flecs C API.
 */

#pragma once

// The C++ API does not use STL, save for type_traits
#include <type_traits>

// Allows overriding flecs_static_assert, which is useful when testing
#ifndef flecs_static_assert
#define flecs_static_assert(cond, str) static_assert(cond, str)
#endif

namespace flecs {

////////////////////////////////////////////////////////////////////////////////
//// Forward declarations and types
////////////////////////////////////////////////////////////////////////////////

using world_t = ecs_world_t;
using id_t = ecs_id_t;
using entity_t = ecs_entity_t;
using type_t = ecs_type_t;
using snapshot_t = ecs_snapshot_t;
using filter_t = ecs_filter_t;
using query_t = ecs_query_t;
using ref_t = ecs_ref_t;
using iter_t = ecs_iter_t;
using ComponentLifecycle = EcsComponentLifecycle;

enum inout_kind_t {
    InOutDefault = EcsInOutDefault,
    InOut = EcsInOut,
    In = EcsIn,
    Out = EcsOut
};

enum oper_kind_t {
    And = EcsAnd,
    Or = EcsOr,
    Not = EcsNot,
    Optional = EcsOptional,
    AndFrom = EcsAndFrom,
    OrFrom = EcsOrFrom,
    NotFrom = EcsNotFrom
};

enum var_kind_t {
    VarDefault = EcsVarDefault,
    VarIsEntity = EcsVarIsEntity,
    VarIsVariable = EcsVarIsVariable
};

class world;
class world_async_stage;
class snapshot;
class id;
class entity;
class entity_view;
class type;
class pipeline;
class iter;
class term;
class filter;
class filter_iterator;
class child_iterator;
class world_filter;
class snapshot_filter;
class query_base;

template<typename ... Components>
class query;

template<typename ... Components>
class system;

template<typename ... Components>
class observer;

template <typename ... Components>
class query_builder;

template <typename ... Components>
class system_builder;

template <typename ... Components>
class observer_builder;

namespace _
{
template <typename T, typename U = int>
class cpp_type;
}

////////////////////////////////////////////////////////////////////////////////
//// Builtin components and tags
////////////////////////////////////////////////////////////////////////////////

/* Builtin components */
using Component = EcsComponent;
using Type = EcsType;
using Name = EcsName;
using Timer = EcsTimer;
using RateFilter = EcsRateFilter;
using TickSource = EcsTickSource;
using Query = EcsQuery;
using Trigger = EcsTrigger;
using Observer = EcsObserver;

/* Builtin opaque components */
static flecs::entity_t System = ecs_id(EcsSystem);

/* Builtin set constants */
static uint8_t DefaultSet = EcsDefaultSet;
static uint8_t Self = EcsSelf;
static uint8_t SuperSet = EcsSuperSet;
static uint8_t SubSet = EcsSubSet;
static uint8_t Cascade = EcsCascade;
static uint8_t All = EcsAll;
static uint8_t Nothing = EcsNothing;

/* Builtin tag ids */
static flecs::entity_t Module = EcsModule;
static flecs::entity_t Prefab = EcsPrefab;
static flecs::entity_t Hidden = EcsHidden;
static flecs::entity_t Disabled = EcsDisabled;
static flecs::entity_t DisabledIntern = EcsDisabledIntern;
static flecs::entity_t Inactive = EcsInactive;
static flecs::entity_t OnDemand = EcsOnDemand;
static flecs::entity_t Monitor = EcsMonitor;
static flecs::entity_t Pipeline = EcsPipeline;

/* Trigger tags */
static flecs::entity_t OnAdd = EcsOnAdd;
static flecs::entity_t OnRemove = EcsOnRemove;
static flecs::entity_t OnSet = EcsOnSet;
static flecs::entity_t UnSet = EcsUnSet;

/* Builtin pipeline tags */
static flecs::entity_t PreFrame = EcsPreFrame;
static flecs::entity_t OnLoad = EcsOnLoad;
static flecs::entity_t PostLoad = EcsPostLoad;
static flecs::entity_t PreUpdate = EcsPreUpdate;
static flecs::entity_t OnUpdate = EcsOnUpdate;
static flecs::entity_t OnValidate = EcsOnValidate;
static flecs::entity_t PostUpdate = EcsPostUpdate;
static flecs::entity_t PreStore = EcsPreStore;
static flecs::entity_t OnStore = EcsOnStore;
static flecs::entity_t PostFrame = EcsPostFrame;

/* Builtin roles */
static flecs::entity_t Trait = ECS_PAIR;
static flecs::entity_t Pair = ECS_PAIR;
static flecs::entity_t Switch = ECS_SWITCH;
static flecs::entity_t Case = ECS_CASE;
static flecs::entity_t Owned = ECS_OWNED;

/* Builtin entity ids */
static flecs::entity_t Flecs = EcsFlecs;
static flecs::entity_t FlecsCore = EcsFlecsCore;
static flecs::entity_t World = EcsWorld;

/* Ids used by rule solver */
static flecs::entity_t Wildcard = EcsWildcard;
static flecs::entity_t This = EcsThis;
static flecs::entity_t Transitive = EcsTransitive;
static flecs::entity_t Final = EcsFinal;
static flecs::entity_t Tag = EcsTag;

/* Builtin relationships */
static flecs::entity_t IsA = EcsIsA;
static flecs::entity_t ChildOf = EcsChildOf;

/* Cleanup rules */
static flecs::entity_t OnDelete = EcsOnDelete;
static flecs::entity_t OnDeleteObject = EcsOnDeleteObject;
static flecs::entity_t Remove = EcsRemove;
static flecs::entity_t Delete = EcsDelete;
static flecs::entity_t Throw = EcsThrow;

}

////////////////////////////////////////////////////////////////////////////////
//// Flecs STL (FTL?)
//// Minimalistic utilities that allow for STL like functionality without having
//// to depend on the actual STL.
////////////////////////////////////////////////////////////////////////////////

// Macros so that C++ new calls can allocate using ecs_os_api memory allocation functions
// Rationale:
//  - Using macros here instead of a templated function bc clients might override ecs_os_malloc
//    to contain extra debug info like source tracking location. Using a template function
//    in that scenario would collapse all source location into said function vs. the
//    actual call site
//  - FLECS_PLACEMENT_NEW(): exists to remove any naked new calls/make it easy to identify any regressions
//    by grepping for new/delete

#define FLECS_PLACEMENT_NEW(_ptr, _type)  ::new(flecs::_::placement_new_tag, _ptr) _type
#define FLECS_NEW(_type)                  FLECS_PLACEMENT_NEW(ecs_os_malloc(sizeof(_type)), _type)
#define FLECS_DELETE(_ptr)          \
  do {                              \
    if (_ptr) {                     \
      flecs::_::destruct_obj(_ptr); \
      ecs_os_free(_ptr);            \
    }                               \
  } while (false)

namespace flecs
{

namespace _
{

// Dummy Placement new tag to disambiguate from any other operator new overrides
struct placement_new_tag_t{};
constexpr placement_new_tag_t placement_new_tag{};
template<class Ty> inline void destruct_obj(Ty* _ptr) { _ptr->~Ty(); }
template<class Ty> inline void free_obj(Ty* _ptr) {
    if (_ptr) {
        destruct_obj(_ptr);
        ecs_os_free(_ptr);
    }
}

} // namespace _

} // namespace flecs

inline void* operator new(size_t,   flecs::_::placement_new_tag_t, void* _ptr) noexcept { return _ptr; }
inline void  operator delete(void*, flecs::_::placement_new_tag_t, void*)      noexcept {              }

namespace flecs
{

// C++11/C++14 convenience template replacements

template <bool V, typename T, typename F>
using conditional_t = typename std::conditional<V, T, F>::type;

template <typename T>
using decay_t = typename std::decay<T>::type;

template <bool V, typename T = void>
using enable_if_t = typename std::enable_if<V, T>::type;

template <typename T>
using remove_pointer_t = typename std::remove_pointer<T>::type;

template <typename T>
using remove_reference_t = typename std::remove_reference<T>::type;

using std::is_base_of;
using std::is_empty;
using std::is_const;
using std::is_pointer;
using std::is_reference;
using std::is_volatile;


// Apply cv modifiers from source type to destination type
// (from: https://stackoverflow.com/questions/52559336/add-const-to-type-if-template-arg-is-const)
template<class Src, class Dst>
using transcribe_const_t = conditional_t<is_const<Src>::value, Dst const, Dst>;

template<class Src, class Dst>
using transcribe_volatile_t = conditional_t<is_volatile<Src>::value, Dst volatile, Dst>;

template<class Src, class Dst>
using transcribe_cv_t = transcribe_const_t< Src, transcribe_volatile_t< Src, Dst> >;


// More convenience templates. The if_*_t templates use int as default type
// instead of void. This enables writing code that's a bit less cluttered when
// the templates are used in a template declaration:
//
//     enable_if_t<true>* = nullptr
// vs:
//     if_t<true> = 0

template <bool V>
using if_t = enable_if_t<V, int>;

template <bool V>
using if_not_t = enable_if_t<false == V, int>;


// String handling

class string_view;

// This removes dependencies on std::string (and therefore STL) and allows the
// API to return allocated strings without incurring additional allocations when
// wrapping in an std::string.
class string {
public:
    explicit string()
        : m_str(nullptr)
        , m_const_str("")
        , m_length(0) { }

    explicit string(char *str)
        : m_str(str)
        , m_const_str(str ? str : "")
        , m_length(str ? ecs_os_strlen(str) : 0) { }

    ~string() {
        // If flecs is included in a binary but is not used, it is possible that
        // the OS API is not initialized. Calling ecs_os_free in that case could
        // crash the application during exit. However, if a string has been set
        // flecs has been used, and OS API should have been initialized.
        if (m_str) {
            ecs_os_free(m_str);
        }
    }

    string(string&& str) {
        ecs_os_free(m_str);
        m_str = str.m_str;
        m_const_str = str.m_const_str;
        m_length = str.m_length;
        str.m_str = nullptr;
    }

    operator char*() {
        return m_const_str;
    }

    string& operator=(string&& str) {
        ecs_os_free(m_str);
        m_str = str.m_str;
        m_const_str = str.m_const_str;
        m_length = str.m_length;
        str.m_str = nullptr;
        return *this;
    }

    // Ban implicit copies/allocations
    string& operator=(string& str) = delete;
    string(string& str) = delete;

    char* c_str() {
        return m_const_str;
    }

    std::size_t length() {
        return static_cast<std::size_t>(m_length);
    }

    std::size_t size() {
        return length();
    }

    void clear() {
        ecs_os_free(m_str);
        m_str = nullptr;
        m_const_str = nullptr;
    }

protected:
    // Must be constructed through string_view. This allows for using the string
    // class for both owned and non-owned strings, which can reduce allocations
    // when code conditionally should store a literal or an owned string.
    // Making this constructor private forces the code to explicitly create a
    // string_view which emphasizes that the string won't be freed by the class.
    string(char *str)
        : m_str(nullptr)
        , m_const_str(str ? str : "")
        , m_length(str ? ecs_os_strlen(str) : 0) { }

    char *m_str = nullptr;
    char *m_const_str;
    ecs_size_t m_length;
};

// For consistency, the API returns a string_view where it could have returned
// a char*, so an application won't have to think about whether to call
// c_str() or not. The string_view is a thin wrapper around a string that forces
// the API to indicate explicitly when a string is owned or not.
class string_view : public string {
public:
    explicit string_view(char *str)
        : string(str) { }
};

// Wrapper around ecs_strbuf_t that provides a simple stringstream like API.
class stringstream {
public:
    explicit stringstream()
        : m_buf({}) { }

    ~stringstream() {
        ecs_strbuf_reset(&m_buf);
    }

    stringstream(stringstream&& str) {
        ecs_strbuf_reset(&m_buf);
        m_buf = str.m_buf;
        str.m_buf = {};
    }

    stringstream& operator=(stringstream&& str) {
        ecs_strbuf_reset(&m_buf);
        m_buf = str.m_buf;
        str.m_buf = {};
        return *this;
    }

    // Ban implicit copies/allocations
    stringstream& operator=(stringstream& str) = delete;
    stringstream(stringstream& str) = delete;

    stringstream& operator<<(char* str) {
        ecs_strbuf_appendstr(&m_buf, str);
        return *this;
    }

    flecs::string str() {
        return flecs::string(ecs_strbuf_get(&m_buf));
    }

private:
    ecs_strbuf_t m_buf;
};

// Array class. Simple std::array like utility that is mostly there to aid
// template code, where the expanded array size would be 0.
template <typename T>
class array_iterator
{
public:
    explicit array_iterator(T* value, int index) {
        m_value = value;
        m_index = index;
    }

    bool operator!=(array_iterator const& other) const
    {
        return m_index != other.m_index;
    }

    T & operator*() const
    {
        return m_value[m_index];
    }

    array_iterator& operator++()
    {
        ++m_index;
        return *this;
    }

private:
    T* m_value;
    int m_index;
};

template <typename T, size_t Size, class Enable = void>
class array { };

template <typename T, size_t Size>
class array<T, Size, enable_if_t<Size != 0> > {
public:
    array() {};

    array(T (&elems)[Size]) {
        int i = 0;
        for (auto it = this->begin(); it != this->end(); ++ it) {
            *it = elems[i ++];
        }
    }

    T& operator[](size_t index) {
        return m_array[index];
    }

    array_iterator<T> begin() {
        return array_iterator<T>(m_array, 0);
    }

    array_iterator<T> end() {
        return array_iterator<T>(m_array, Size);
    }

    size_t size() {
        return Size;
    }

    T* ptr() {
        return m_array;
    }
private:
    T m_array[Size];
};

// Specialized class for zero-sized array
template <typename T, size_t Size>
class array<T, Size, enable_if_t<Size == 0>> {
public:
    array() {};
    array(T* (&elems)) { (void)elems; }
    T operator[](size_t index) { abort(); (void)index; return T(); }
    array_iterator<T> begin() { return array_iterator<T>(nullptr, 0); }
    array_iterator<T> end() { return array_iterator<T>(nullptr, 0); }

    size_t size() {
        return 0;
    }

    T* ptr() {
        return NULL;
    }
};

namespace _
{

// Utility to prevent static assert from immediately triggering
template <class... T>
struct always_false {
    static bool value = false;
};

} // namespace _

} // namespace flecs

namespace flecs {

namespace _ {
    struct pair_base { };
} // _


// Type that represents a pair and can encapsulate a temporary value
template <typename R, typename O>
struct pair : _::pair_base {
    // Traits used to deconstruct the pair

    // The actual type of the pair is determined by which type of the pair is
    // empty. If both types are empty or not empty, the pair assumes the type
    // of the relation.
    using type = conditional_t<!is_empty<R>::value || is_empty<O>::value, R, O>;
    using relation = R;
    using object = O;

    pair(type& v) : ref_(v) { }

    // This allows the class to be used as a temporary object
    pair(type& v) : ref_(const_cast<type&>(v)) { }

    operator type&() {
        return ref_;
    }

    operator Type&() {
        return ref_;
    }

    type* operator->() {
        return &ref_;
    }

    type* operator->() {
        return &ref_;
    }

    type& operator*() {
        return &ref_;
    }

    type& operator*() {
        return ref_;
    }

private:
    type& ref_;
};

template <typename R, typename O, if_t<is_empty<R>::value> = 0>
using pair_object = pair<R, O>;


// Utilities to test if type is a pair
template <typename T>
struct is_pair {
    static constexpr bool value = is_base_of<_::pair_base, remove_reference_t<T> >::value;
};


// Get actual type, relation or object from pair while preserving cv qualifiers.
template <typename P>
using pair_relation_t = transcribe_cv_t<remove_reference_t<P>, typename remove_reference_t<P>::relation>;

template <typename P>
using pair_object_t = transcribe_cv_t<remove_reference_t<P>, typename remove_reference_t<P>::object>;

template <typename P>
using pair_type_t = transcribe_cv_t<remove_reference_t<P>, typename remove_reference_t<P>::type>;


// Get actual type from a regular type or pair
template <typename T, typename U = int>
struct actual_type;

template <typename T>
struct actual_type<T, if_not_t< is_pair<T>::value >> {
    using type = T;
};

template <typename T>
struct actual_type<T, if_t< is_pair<T>::value >> {
    using type = pair_type_t<T>;
};

template <typename T>
using actual_type_t = typename actual_type<T>::type;


// Get type without const, *, &
template<typename T>
struct base_type {
    using type = remove_pointer_t< decay_t< actual_type_t<T> > >;
};

template <typename T>
using base_type_t = typename base_type<T>::type;


// Get type without *, & (retains which is useful for function args)
template<typename T>
struct base_arg_type {
    using type = remove_pointer_t< remove_reference_t< actual_type_t<T> > >;
};

template <typename T>
using base_arg_type_t = typename base_arg_type<T>::type;


// Test if type is the same as its actual type
template <typename T>
struct is_actual {
    static constexpr bool value = std::is_same<T, actual_type_t<T> >::value;
};

} // flecs

// Neat utility to inspect arguments & returntype of a function type
// Code from: https://stackoverflow.com/questions/27024238/c-template-mechanism-to-get-the-number-of-function-arguments-which-would-work

namespace flecs {
namespace _ {

template <typename ... Args>
struct arg_list { };

// Base type that contains the traits
template <typename ReturnType, typename... Args>
struct function_traits_defs
{
    static constexpr bool is_callable = true;
    static constexpr size_t arity = sizeof...(Args);
    using return_type = ReturnType;
    using args = arg_list<Args ...>;
};

// Primary template for function_traits_impl
template <typename T>
struct function_traits_impl {
    static constexpr bool is_callable = false;
};

// Template specializations for the different kinds of function types (whew)
template <typename ReturnType, typename... Args>
struct function_traits_impl<ReturnType(Args...)>
    : function_traits_defs<ReturnType, Args...> {};

template <typename ReturnType, typename... Args>
struct function_traits_impl<ReturnType(*)(Args...)>
    : function_traits_defs<ReturnType, Args...> {};

template <typename ClassType, typename ReturnType, typename... Args>
struct function_traits_impl<ReturnType(ClassType::*)(Args...)>
    : function_traits_defs<ReturnType, Args...> {};

template <typename ClassType, typename ReturnType, typename... Args>
struct function_traits_impl<ReturnType(ClassType::*)(Args...) const>
    : function_traits_defs<ReturnType, Args...> {};

template <typename ClassType, typename ReturnType, typename... Args>
struct function_traits_impl<ReturnType(ClassType::*)(Args...) const&>
    : function_traits_defs<ReturnType, Args...> {};

template <typename ClassType, typename ReturnType, typename... Args>
struct function_traits_impl<ReturnType(ClassType::*)(Args...) const&&>
    : function_traits_defs<ReturnType, Args...> {};

template <typename ClassType, typename ReturnType, typename... Args>
struct function_traits_impl<ReturnType(ClassType::*)(Args...) volatile>
    : function_traits_defs<ReturnType, Args...> {};

template <typename ClassType, typename ReturnType, typename... Args>
struct function_traits_impl<ReturnType(ClassType::*)(Args...) volatile&>
    : function_traits_defs<ReturnType, Args...> {};

template <typename ClassType, typename ReturnType, typename... Args>
struct function_traits_impl<ReturnType(ClassType::*)(Args...) volatile&&>
    : function_traits_defs<ReturnType, Args...> {};

template <typename ClassType, typename ReturnType, typename... Args>
struct function_traits_impl<ReturnType(ClassType::*)(Args...) volatile>
    : function_traits_defs<ReturnType, Args...> {};

template <typename ClassType, typename ReturnType, typename... Args>
struct function_traits_impl<ReturnType(ClassType::*)(Args...) volatile&>
    : function_traits_defs<ReturnType, Args...> {};

template <typename ClassType, typename ReturnType, typename... Args>
struct function_traits_impl<ReturnType(ClassType::*)(Args...) volatile&&>
    : function_traits_defs<ReturnType, Args...> {};

// Primary template for function_traits_no_cv. If T is not a function, the
// compiler will attempt to instantiate this template and fail, because its base
// is undefined.
template <typename T, typename V = void>
struct function_traits_no_cv
    : function_traits_impl<T> {};

// Specialized template for function types
template <typename T>
struct function_traits_no_cv<T, decltype((void)&T::operator())>
    : function_traits_impl<decltype(&T::operator())> {};

// Front facing template that decays T before ripping it apart.
template <typename T>
struct function_traits
    : function_traits_no_cv< decay_t<T> > {};

} // _

template <typename T>
struct is_callable {
    static constexpr bool value = _::function_traits<T>::is_callable;
};

template <typename T>
struct arity {
    static constexpr int value = _::function_traits<T>::arity;
};

template <typename T>
using return_type_t = typename _::function_traits<T>::return_type;

template <typename T>
using arg_list_t = typename _::function_traits<T>::args;

} // flecs
namespace flecs
{

namespace _
{

// T()
// Can't coexist with T(flecs::entity) or T(flecs::world, flecs::entity)
template <typename T>
void ctor_impl(
    ecs_world_t*, ecs_entity_t, ecs_entity_t*, void *ptr, size_t size,
    int32_t count, void*)
{
    (void)size; ecs_assert(size == sizeof(T), ECS_INTERNAL_ERROR, NULL);
    T *arr = static_cast<T*>(ptr);
    for (int i = 0; i < count; i ++) {
        FLECS_PLACEMENT_NEW(&arr[i], T);
    }
}

// T(flecs::world, flecs::entity)
template <typename T>
void ctor_world_entity_impl(
    ecs_world_t* world, ecs_entity_t, ecs_entity_t* ids, void *ptr,
    size_t size, int32_t count, void*);

// ~T()
template <typename T>
void dtor_impl(
    ecs_world_t*, ecs_entity_t, ecs_entity_t*, void *ptr, size_t size,
    int32_t count, void*)
{
    (void)size; ecs_assert(size == sizeof(T), ECS_INTERNAL_ERROR, NULL);
    T *arr = static_cast<T*>(ptr);
    for (int i = 0; i < count; i ++) {
        arr[i].~T();
    }
}

// T& operator=(T&)
template <typename T>
void copy_impl(
    ecs_world_t*, ecs_entity_t, ecs_entity_t*, ecs_entity_t*,
    void *dst_ptr, void *src_ptr, size_t size, int32_t count, void*)
{
    (void)size; ecs_assert(size == sizeof(T), ECS_INTERNAL_ERROR, NULL);
    T *dst_arr = static_cast<T*>(dst_ptr);
    T *src_arr = static_cast<T*>(src_ptr);
    for (int i = 0; i < count; i ++) {
        dst_arr[i] = src_arr[i];
    }
}

// T& operator=(T&&)
template <typename T>
void move_impl(
    ecs_world_t*, ecs_entity_t, ecs_entity_t*, ecs_entity_t*,
    void *dst_ptr, void *src_ptr, size_t size, int32_t count, void*)
{
    (void)size; ecs_assert(size == sizeof(T), ECS_INTERNAL_ERROR, NULL);
    T *dst_arr = static_cast<T*>(dst_ptr);
    T *src_arr = static_cast<T*>(src_ptr);
    for (int i = 0; i < count; i ++) {
        dst_arr[i] = std::move(src_arr[i]);
    }
}

// T(T&)
template <typename T>
void copy_ctor_impl(
    ecs_world_t*, ecs_entity_t, EcsComponentLifecycle*,
    ecs_entity_t*, ecs_entity_t*, void *dst_ptr,
    void *src_ptr, size_t size, int32_t count, void*)
{
    (void)size; ecs_assert(size == sizeof(T), ECS_INTERNAL_ERROR, NULL);
    T *dst_arr = static_cast<T*>(dst_ptr);
    T *src_arr = static_cast<T*>(src_ptr);
    for (int i = 0; i < count; i ++) {
        FLECS_PLACEMENT_NEW(&dst_arr[i], T(src_arr[i]));
    }
}

// T(T&&)
template <typename T>
void move_ctor_impl(
    ecs_world_t*, ecs_entity_t, EcsComponentLifecycle*,
    ecs_entity_t*, ecs_entity_t*, void *dst_ptr,
    void *src_ptr, size_t size, int32_t count, void*)
{
    (void)size; ecs_assert(size == sizeof(T), ECS_INTERNAL_ERROR, NULL);
    T *dst_arr = static_cast<T*>(dst_ptr);
    T *src_arr = static_cast<T*>(src_ptr);
    for (int i = 0; i < count; i ++) {
        FLECS_PLACEMENT_NEW(&dst_arr[i], T(std::move(src_arr[i])));
    }
}

// T(T&&), ~T()
// Typically used when moving to a new table, and removing from the old table
template <typename T>
void merge_impl(
    ecs_world_t*, ecs_entity_t, EcsComponentLifecycle*,
    ecs_entity_t*, ecs_entity_t*, void *dst_ptr,
    void *src_ptr, size_t size, int32_t count, void*)
{
    (void)size; ecs_assert(size == sizeof(T), ECS_INTERNAL_ERROR, NULL);
    T *dst_arr = static_cast<T*>(dst_ptr);
    T *src_arr = static_cast<T*>(src_ptr);
    for (int i = 0; i < count; i ++) {
        FLECS_PLACEMENT_NEW(&dst_arr[i], T(std::move(src_arr[i])));
        src_arr[i].~T();
    }
}

// Utility to return callback and whether callback is allowed
template <typename T>
struct lifecycle_callback_result {
    T callback;  // The callback function
    bool illegal; // If true, callback is not allowed

    static lifecycle_callback_result is_illegal;
    static lifecycle_callback_result not_set;
};

template <typename T>
lifecycle_callback_result<T>
    lifecycle_callback_result<T>::is_illegal = {nullptr, true};

template <typename T>
lifecycle_callback_result<T>
    lifecycle_callback_result<T>::not_set = {nullptr, false};

using ctor_result = lifecycle_callback_result<ecs_xtor_t>;
using dtor_result = lifecycle_callback_result<ecs_xtor_t>;
using copy_result = lifecycle_callback_result<ecs_copy_t>;
using move_result = lifecycle_callback_result<ecs_move_t>;
using copy_ctor_result = lifecycle_callback_result<ecs_copy_ctor_t>;
using move_ctor_result = lifecycle_callback_result<ecs_move_ctor_t>;
using merge_result = lifecycle_callback_result<ecs_move_ctor_t>;

} // _

// Trait to test if type has flecs constructor
template <typename T>
struct has_flecs_ctor {
    static constexpr bool value =
        std::is_constructible<actual_type_t<T>,
            flecs::world&, flecs::entity>::value;
};

// Trait to test if type is constructible by flecs
template <typename T>
struct is_flecs_constructible {
    static constexpr bool value =
        std::is_default_constructible<actual_type_t<T>>::value ||
        std::is_constructible<actual_type_t<T>,
            flecs::world&, flecs::entity>::value;
};

namespace _
{

// Trivially constructible
template <typename T, if_t< std::is_trivially_constructible<T>::value > = 0>
ctor_result ctor() {
    return ctor_result::not_set;
}

// Not constructible by flecs
template <typename T, if_t<
    ! std::is_default_constructible<T>::value &&
    ! has_flecs_ctor<T>::value > = 0>
ctor_result ctor() {
    return ctor_result::is_illegal;
}

// Default constructible
template <typename T, if_t<
    ! std::is_trivially_constructible<T>::value &&
    std::is_default_constructible<T>::value &&
    ! has_flecs_ctor<T>::value > = 0>
ctor_result ctor() {
    return {ctor_impl<T>, false};
}

// Flecs constructible: T(flecs::world, flecs::entity)
template <typename T, if_t< has_flecs_ctor<T>::value > = 0>
ctor_result ctor() {
    return {ctor_world_entity_impl<T>, false};
}

// No dtor
template <typename T, if_t< std::is_trivially_destructible<T>::value > = 0>
dtor_result dtor() {
    return dtor_result::not_set;
}

// Dtor
template <typename T, if_t<
    std::is_destructible<T>::value &&
    ! std::is_trivially_destructible<T>::value > = 0>
dtor_result dtor() {
    return {dtor_impl<T>, false};
}

// Assert when the type cannot be destructed
template <typename T, if_not_t< std::is_destructible<T>::value > = 0>
dtor_result dtor() {
    flecs_static_assert(always_false<T>::value,
        "component type must be destructible");
    return dtor_result::is_illegal;
}

// Trivially copyable
template <typename T, if_t< std::is_trivially_copyable<T>::value > = 0>
copy_result copy() {
    return copy_result::not_set;
}

// Not copyable
template <typename T, if_t<
    ! std::is_trivially_copyable<T>::value &&
    ! std::is_copy_assignable<T>::value > = 0>
copy_result copy() {
    return copy_result::is_illegal;
}

// Copy assignment
template <typename T, if_t<
    std::is_copy_assignable<T>::value &&
    ! std::is_trivially_copyable<T>::value > = 0>
copy_result copy() {
    return {copy_impl<T>, false};
}

// Trivially move assignable
template <typename T, if_t< std::is_trivially_move_assignable<T>::value > = 0>
move_result move() {
    return move_result::not_set;
}

// Component types must be move assignable
template <typename T, if_not_t< std::is_move_assignable<T>::value > = 0>
move_result move() {
    flecs_static_assert(always_false<T>::value,
        "component type must be move assignable");
    return move_result::is_illegal;
}

// Move assignment
template <typename T, if_t<
    std::is_move_assignable<T>::value &&
    ! std::is_trivially_move_assignable<T>::value > = 0>
move_result move() {
    return {move_impl<T>, false};
}

// Trivially copy constructible
template <typename T, if_t<
    std::is_trivially_copy_constructible<T>::value > = 0>
copy_ctor_result copy_ctor() {
    return copy_ctor_result::not_set;
}

// No copy ctor
template <typename T, if_t< ! std::is_copy_constructible<T>::value > = 0>
copy_ctor_result copy_ctor() {
    return copy_ctor_result::is_illegal;
}

// Copy ctor
template <typename T, if_t<
    std::is_copy_constructible<T>::value &&
    ! std::is_trivially_copy_constructible<T>::value > = 0>
copy_ctor_result copy_ctor() {
    return {copy_ctor_impl<T>, false};
}

// Trivially move constructible
template <typename T, if_t<
    std::is_trivially_move_constructible<T>::value > = 0>
move_ctor_result move_ctor() {
    return move_ctor_result::not_set;
}

// Component types must be move constructible
template <typename T, if_not_t< std::is_move_constructible<T>::value > = 0>
move_ctor_result move_ctor() {
    flecs_static_assert(always_false<T>::value,
        "component type must be move constructible");
    return move_ctor_result::is_illegal;
}

// Move ctor
template <typename T, if_t<
    std::is_move_constructible<T>::value &&
    ! std::is_trivially_move_constructible<T>::value > = 0>
move_ctor_result move_ctor() {
    return {move_ctor_impl<T>, false};
}

// Trivial merge (move assign + dtor)
template <typename T, if_t<
    std::is_trivially_move_constructible<T>::value  &&
    std::is_trivially_destructible<T>::value > = 0>
move_ctor_result merge() {
    return move_ctor_result::not_set;
}

// Component types must be move constructible and destructible
template <typename T, if_t<
    ! std::is_move_constructible<T>::value ||
    ! std::is_destructible<T>::value > = 0>
move_ctor_result merge() {
    flecs_static_assert(always_false<T>::value,
        "component type must be move constructible and destructible");
    return move_ctor_result::is_illegal;
}

// Merge (move assign + dtor)
template <typename T, if_t<
    !(std::is_trivially_move_constructible<T>::value  &&
      std::is_trivially_destructible<T>::value) &&
    std::is_move_constructible<T>::value &&
    std::is_destructible<T>::value > = 0>
move_ctor_result merge() {
    return {merge_impl<T>, false};
}

} // _
} // flecs

namespace flecs
{

/* Unsafe wrapper class around a column.
 * This class can be used when a system does not know the type of a column at
 * compile time.
 */
class unsafe_column {
public:
    unsafe_column(void* array, size_t size, size_t count, bool is_shared = false)
        : m_array(array)
        , m_size(size)
        , m_count(count)
        , m_is_shared(is_shared) {}

    /* Return element in component array.
     * This operator may only be used if the column is not shared.
     *
     * @param index Index of element.
     * @return Reference to element.
     */
    void* operator[](size_t index) {
        ecs_assert(index < m_count, ECS_COLUMN_INDEX_OUT_OF_RANGE, NULL);
        ecs_assert(!m_is_shared, ECS_INVALID_PARAMETER, NULL);
        return ECS_OFFSET(m_array, m_size * index);
    }

    /* Return whether component is set.
     * If the column is optional, this method may return false.
     *
     * @return True if component is set, false if component is not set.
     */
    bool is_set() {
        return m_array != nullptr;
    }

    /* Return whether component is shared.
     * If the column is shared, this method returns true.
     *
     * @return True if component is shared, false if component is owned.
     */
    bool is_shared() {
        return m_is_shared;
    }

protected:
    void* m_array;
    size_t m_size;
    size_t m_count;
    bool m_is_shared;
};

/* Wrapper class around a column.
 *
 * @tparam T component type of the column.
 */
template <typename T>
class column {
public:
    static_assert(std::is_empty<T>() == false,
        "invalid type for column, cannot iterate empty type");

    /* Create column from component array.
     *
     * @param array Pointer to the component array.
     * @param count Number of elements in component array.
     * @param is_shared Is the component shared or not.
     */
    column(T* array, size_t count, bool is_shared = false)
        : m_array(array)
        , m_count(count)
        , m_is_shared(is_shared) {}

    /* Create column from iterator.
     *
     * @param iter Iterator object.
     * @param column Index of the signature of the query being iterated over.
     */
    column(iter &iter, int column);

    /* Return element in component array.
     * This operator may only be used if the column is not shared.
     *
     * @param index Index of element.
     * @return Reference to element.
     */
    T& operator[](size_t index) {
        ecs_assert(index < m_count, ECS_COLUMN_INDEX_OUT_OF_RANGE, NULL);
        ecs_assert(!index || !m_is_shared, ECS_INVALID_PARAMETER, NULL);
        ecs_assert(m_array != nullptr, ECS_COLUMN_INDEX_OUT_OF_RANGE, NULL);
        return m_array[index];
    }

    /* Return first element of component array.
     * This operator is typically used when the column is shared.
     *
     * @return Reference to the first element.
     */
    T& operator*() {
      ecs_assert(m_array != nullptr, ECS_COLUMN_INDEX_OUT_OF_RANGE, NULL);
      return *m_array;
    }

    /* Return first element of component array.
     * This operator is typically used when the column is shared.
     *
     * @return Pointer to the first element.
     */
    T* operator->() {
        ecs_assert(m_array != nullptr, ECS_COLUMN_INDEX_OUT_OF_RANGE, NULL);
        return m_array;
    }

    /* Return whether component is set.
     * If the column is optional, this method may return false.
     *
     * @return True if component is set, false if component is not set.
     */
    bool is_set() {
        return m_array != nullptr;
    }

    /* Return whether component is shared.
     * If the column is shared, this method returns true.
     *
     * @return True if component is shared, false if component is owned.
     */
    bool is_shared() {
        return m_is_shared;
    }

    /* Return whether component is owned.
     * If the column is shared, this method returns true.
     *
     * @return True if component is shared, false if component is owned.
     */
    bool is_owned() {
        return !m_is_shared;
    }

protected:
    T* m_array;
    size_t m_count;
    bool m_is_shared;
};


////////////////////////////////////////////////////////////////////////////////

namespace _ {

////////////////////////////////////////////////////////////////////////////////

/* Iterate over an integer range (used to iterate over entity range).
 *
 * @tparam Type of the iterator
 */
template <typename T>
class range_iterator
{
public:
    explicit range_iterator(T value)
        : m_value(value){}

    bool operator!=(range_iterator const& other) const
    {
        return m_value != other.m_value;
    }

    T const& operator*() const
    {
        return m_value;
    }

    range_iterator& operator++()
    {
        ++m_value;
        return *this;
    }

private:
    T m_value;
};

} // namespace _

} // namespace flecs

#ifdef FLECS_DEPRECATED

namespace flecs
{

/* Deprecated functions */
template<typename Base>
class iter_deprecated {
public:
    ECS_DEPRECATED("use term_count(int32_t)")
    int32_t column_count() {
        return base()->term_count();
    }

    ECS_DEPRECATED("use term_size(int32_t)")
    size_t column_size(int32_t col) {
        return base()->term_size(col);
    }

    ECS_DEPRECATED("use is_owned(int32_t)")
    bool is_shared(int32_t col) {
        return !base()->is_owned(col);
    }

    ECS_DEPRECATED("use term_source(int32_t)")
    flecs::entity column_source(int32_t col) const;

    ECS_DEPRECATED("use term_id(int32_t)")
    flecs::entity column_entity(int32_t col) const;

    ECS_DEPRECATED("no replacement")
    flecs::type column_type(int32_t col) const;

    ECS_DEPRECATED("use type()")
    type table_type() const;

    template <typename T, if_t< is_const<T>::value > = 0>
    ECS_DEPRECATED("use term<T>(int32_t)")
    flecs::column<T> column(int32_t col) {
        return base()->template term<T>(col);
    }

    template <typename T, if_not_t< is_const<T>::value > = 0>
    ECS_DEPRECATED("use term<T>(int32_t)")
    flecs::column<T> column(int32_t col) {
        ecs_assert(!ecs_is_readonly(iter(), col),
            ECS_COLUMN_ACCESS_VIOLATION, NULL);
        return base()->template term<T>(col);
    }

    ECS_DEPRECATED("use term(int32_t)")
    flecs::unsafe_column column(int32_t col) {
        return base()->term(col);
    }

    template <typename T>
    ECS_DEPRECATED("use owned<T>(int32_t)")
    flecs::column<T> owned(int32_t col) {
        return base()->template owned<T>(col);
    }

    template <typename T>
    ECS_DEPRECATED("use shared<T>(int32_t)")
    T& shared(int32_t col) {
        return base()->template shared<T>(col);
    }

    template <typename T, if_t< is_const<T>::value > = 0>
    ECS_DEPRECATED("no replacement")
    T& element(int32_t col, int32_t row) {
        return base()->template get_element<T>(col, row);
    }

    template <typename T, if_not_t< is_const<T>::value > = 0>
    ECS_DEPRECATED("no replacement")
    T& element(int32_t col, int32_t row) {
        ecs_assert(!ecs_is_readonly(iter(), col),
            ECS_COLUMN_ACCESS_VIOLATION, NULL);
        return base()->template get_element<T>(col, row);
    }

private:
    Base* base() { return static_cast<Base*>(this); }
    flecs::iter_t* iter() { return base()->c_ptr(); }
};

}
#else
namespace flecs
{
template <typename Base>
class iter_deprecated { };
}
#endif

namespace flecs
{

////////////////////////////////////////////////////////////////////////////////

/* Class that enables iterating over table columns.
 */
class iter : public iter_deprecated<iter> {
    using row_iterator = _::range_iterator<size_t>;
public:
    /* Construct iterator from C iterator object.
     * This operation is typically not invoked directly by the user.
     *
     * @param it Pointer to C iterator.
     */
    iter(ecs_iter_t *it) : m_iter(it) {
        m_begin = 0;
        m_end = static_cast<std::size_t>(it->count);
    }

    row_iterator begin() {
        return row_iterator(m_begin);
    }

    row_iterator end() {
        return row_iterator(m_end);
    }

    /* Obtain handle to current system.
     */
    flecs::entity system() const;

    /* Obtain current world.
     */
    flecs::world world() const;

    /* Obtain pointer to C iterator object
     */
    flecs::iter_t* c_ptr() {
        return m_iter;
    }

    /* Number of entities to iterate over.
     */
    size_t count() {
        return static_cast<size_t>(m_iter->count);
    }

    /* Return delta_time of current frame.
     */
    FLECS_FLOAT delta_time() {
        return m_iter->delta_time;
    }

    /* Return time elapsed since last time system was invoked.
     */
    FLECS_FLOAT delta_system_time() {
        return m_iter->delta_system_time;
    }

    /* Return total time passed in simulation.
     */
    FLECS_FLOAT world_time() {
        return m_iter->world_time;
    }

    /* Obtain type of the entities being iterated over.
     */
    flecs::type type() const;

    /* Is current type a module or does it contain module contents? */
    bool has_module() {
        return ecs_table_has_module(ecs_iter_table(m_iter));
    }

    /* Access ctx.
     * ctx contains the context pointer assigned to a system.
     */
    void* ctx() {
        return m_iter->ctx;
    }

    /* Access param.
     * param contains the pointer passed to the param argument of system::run
     */
    void* param() {
        return m_iter->param;
    }

    /* Obtain mutable handle to entity being iterated over.
     *
     * @param row Row being iterated over.
     */
    flecs::entity entity(size_t row) const;

    /* Obtain the total number of inactive tables the query is matched with.
     */
    int32_t inactive_table_count() {
        return m_iter->inactive_table_count;
    }

    /* Returns whether term is owned.
     *
     * @param index The term index.
     */
    bool is_owned(int32_t index) {
        return ecs_term_is_owned(m_iter, index);
    }

    /* Returns whether term is set.
     *
     * @param index The term index.
     */
    bool is_set(int32_t index) {
        return ecs_term_w_size(m_iter, 0, index) != NULL;
    }

    /* Returns whether term is readonly.
     *
     * @param index The term index.
     */
    bool is_readonly(int32_t index) {
        return ecs_term_is_readonly(m_iter, index);
    }

    /* Number of terms in iteator.
     */
    int32_t term_count() {
        return m_iter->column_count;
    }

    /* Size of term data type.
     *
     * @param index The term id.
     */
    size_t term_size(int32_t index) {
        return ecs_term_size(m_iter, index);
    }

    /* Obtain term source (0 if self)
     *
     * @param index The term index.
     */
    flecs::entity term_source(int32_t index) const;

    /* Obtain component/tag entity of term.
     *
     * @param index The term index.
     */
    flecs::entity term_id(int32_t index) const;

    /* Obtain term with type.
     * If the specified term index does not match with the provided type, the
     * function will assert.
     *
     * @tparam T Type of the term.
     * @param index The term index.
     * @return The term data.
     */
    template <typename T, typename A = actual_type_t<T>,
        typename std::enable_if<std::is_const<T>::value, void>::type* = nullptr>

    flecs::column<A> term(int32_t index) {
        return get_term<A>(index);
    }

    /* Obtain term with non-type.
     * If the specified term id does not match with the provided type or if
     * the term is readonly, the function will assert.
     *
     * @tparam T Type of the term.
     * @param index The term index.
     * @return The term data.
     */
    template <typename T, typename A = actual_type_t<T>,
        typename std::enable_if<
            std::is_const<T>::value == false, void>::type* = nullptr>

    flecs::column<A> term(int32_t index) {
        ecs_assert(!ecs_term_is_readonly(m_iter, index),
            ECS_COLUMN_ACCESS_VIOLATION, NULL);
        return get_term<A>(index);
    }

    /* Obtain unsafe term.
     * Unsafe terms are required when a system does not know at compile time
     * which component will be passed to it.
     *
     * @param index The term index.
     */
    flecs::unsafe_column term(int32_t index) {
        return get_unsafe_term(index);
    }

    /* Obtain owned term.
     * Same as iter::term, but ensures that term is owned.
     *
     * @tparam Type of the term.
     * @param index The term index.
     * @return The term data.
     */
    template <typename T, typename A = actual_type_t<T>>
    flecs::column<A> term_owned(int32_t index) {
        ecs_assert(!!ecs_is_owned(m_iter, index), ECS_COLUMN_IS_SHARED, NULL);
        return this->term<A>(index);
    }

    /* Obtain shared term.
     * Same as iter::term, but ensures that term is shared.
     *
     * @tparam Type of the term.
     * @param index The term index.
     * @return The component term.
     */
    template <typename T, typename A = actual_type_t<T>>
    T& term_shared(int32_t index) {
        ecs_assert(
            ecs_term_id(m_iter, index) ==
                _::cpp_type<T>::id(m_iter->world),
                    ECS_COLUMN_TYPE_MISMATCH, NULL);

        ecs_assert(!ecs_term_is_owned(m_iter, index),
            ECS_COLUMN_IS_NOT_SHARED, NULL);

        return *static_cast<A*>(ecs_term_w_size(m_iter, sizeof(A), index));
    }

    /* Obtain the total number of tables the iterator will iterate over.
     */
    int32_t table_count() {
        return m_iter->table_count;
    }

    /* Obtain untyped pointer to table column.
     *
     * @param table_column Id of table column (corresponds with location in table type).
     * @return Pointer to table column.
     */
    void* table_column(int32_t col) {
        return ecs_iter_column_w_size(m_iter, 0, col);
    }

    /* Obtain typed pointer to table column.
     * If the table does not contain a column with the specified type, the
     * function will assert.
     *
     * @tparam T Type of the table column.
     */
    template <typename T, typename A = actual_type_t<T>>
    flecs::column<T> table_column() {
        auto col = ecs_iter_find_column(m_iter, _::cpp_type<T>::id());
        ecs_assert(col != -1, ECS_INVALID_PARAMETER, NULL);

        return flecs::column<A>(static_cast<A*>(ecs_iter_column_w_size(m_iter,
            sizeof(A), col)), static_cast<std::size_t>(m_iter->count), false);
    }

private:
    /* Get term, check if correct type is used */
    template <typename T, typename A = actual_type_t<T>>
    flecs::column<T> get_term(int32_t index) {

#ifndef NDEBUG
        ecs_entity_t term_id = ecs_term_id(m_iter, index);
        ecs_assert(term_id & ECS_PAIR || term_id & ECS_SWITCH ||
            term_id & ECS_CASE ||
            term_id == _::cpp_type<T>::id(m_iter->world),
            ECS_COLUMN_TYPE_MISMATCH, NULL);
#endif

        size_t count;
        bool is_shared = !ecs_term_is_owned(m_iter, index);

        /* If a shared column is retrieved with 'column', there will only be a
         * single value. Ensure that the application does not accidentally read
         * out of bounds. */
        if (is_shared) {
            count = 1;
        } else {
            /* If column is owned, there will be as many values as there are
             * entities. */
            count = static_cast<size_t>(m_iter->count);
        }

        return flecs::column<A>(
            static_cast<T*>(ecs_term_w_size(m_iter, sizeof(A), index)),
            count, is_shared);
    }

    flecs::unsafe_column get_unsafe_term(int32_t index) {
        size_t count;
        size_t size = ecs_term_size(m_iter, index);
        bool is_shared = !ecs_term_is_owned(m_iter, index);

        /* If a shared column is retrieved with 'column', there will only be a
         * single value. Ensure that the application does not accidentally read
         * out of bounds. */
        if (is_shared) {
            count = 1;
        } else {
            /* If column is owned, there will be as many values as there are
             * entities. */
            count = static_cast<size_t>(m_iter->count);
        }

        return flecs::unsafe_column(
            ecs_term_w_size(m_iter, 0, index), size, count, is_shared);
    }

    /* Get single field, check if correct type is used */
    template <typename T, typename A = actual_type_t<T>>
    A& get_element(int32_t index, int32_t row) {
        ecs_assert(
            ecs_term_id(m_iter, index) == _::cpp_type<T>::id(m_iter->world),
                ECS_COLUMN_TYPE_MISMATCH, NULL);
        return *static_cast<A*>(
            ecs_element_w_size(m_iter, sizeof(A), index, row));
    }

    flecs::iter_t *m_iter;
    std::size_t m_begin;
    std::size_t m_end;
};

} // namespace flecs

namespace flecs
{

/* Static helper functions to assign a component value */

// set(T&&), T = constructible
template <typename T, if_t< is_flecs_constructible<T>::value > = 0>
inline void set(world_t *world, entity_t entity, T&& value, ecs_id_t id) {
    ecs_assert(_::cpp_type<T>::size() != 0, ECS_INVALID_PARAMETER, NULL);

    T& dst = *static_cast<T*>(
        ecs_get_mut_w_id(world, entity, id, NULL));
    dst = std::move(value);

    ecs_modified_w_id(world, entity, id);
}

// set(T&), T = constructible
template <typename T, if_t< is_flecs_constructible<T>::value > = 0>
inline void set(world_t *world, entity_t entity, T& value, ecs_id_t id) {
    ecs_assert(_::cpp_type<T>::size() != 0, ECS_INVALID_PARAMETER, NULL);

    T& dst = *static_cast<T*>(
        ecs_get_mut_w_id(world, entity, id, NULL));
    dst = value;

    ecs_modified_w_id(world, entity, id);
}

// set(T&&), T = not constructible
template <typename T, if_not_t< is_flecs_constructible<T>::value > = 0>
inline void set(world_t *world, entity_t entity, T&& value, ecs_id_t id) {
    ecs_assert(_::cpp_type<T>::size() != 0, ECS_INVALID_PARAMETER, NULL);

    bool is_new = false;
    T& dst = *static_cast<T*>(
        ecs_get_mut_w_id(world, entity, id, &is_new));
    if (is_new) {
        FLECS_PLACEMENT_NEW(&dst, T(std::move(value)));
    } else {
        dst = std::move(value);
    }

    ecs_modified_w_id(world, entity, id);
}

// set(T&), T = not constructible
template <typename T, if_not_t< is_flecs_constructible<T>::value > = 0>
inline void set(world_t *world, entity_t entity, T& value, ecs_id_t id) {
    ecs_assert(_::cpp_type<T>::size() != 0, ECS_INVALID_PARAMETER, NULL);

    bool is_new = false;
    T& dst = *static_cast<T*>(
        ecs_get_mut_w_id(world, entity, id, &is_new));
    if (is_new) {
        FLECS_PLACEMENT_NEW(&dst, T(std::move(value)));
    } else {
        dst = value;
    }

    ecs_modified_w_id(world, entity, id);
}

// set(T&&)
template <typename T, typename A>
inline void set(world_t *world, entity_t entity, A&& value) {
    id_t id = _::cpp_type<T>::id(world);
    flecs::set(world, entity, std::forward<A&&>(value), id);
}

// set(T&)
template <typename T, typename A>
inline void set(world_t *world, entity_t entity, A& value) {
    id_t id = _::cpp_type<T>::id(world);
    flecs::set(world, entity, value, id);
}


/* The world.
 * The world is the container of all ECS data and systems. If the world is
 * deleted, all data in the world will be deleted as well.
 */
class world final {
public:
    /* Create world.
     */
    explicit world()
        : m_world( ecs_init() )
        , m_owned( true ) { init_builtin_components(); }

    /* Create world with command line arguments.
     * Currently command line arguments are not interpreted, but they may be
     * used in the future to configure Flecs parameters.
     */
    explicit world(int argc, char *argv[])
        : m_world( ecs_init_w_args(argc, argv) )
        , m_owned( true ) { init_builtin_components(); }

    /* Create world from C world.
     */
    explicit world(world_t *w)
        : m_world( w )
        , m_owned( false ) { }

    /* Not allowed to copy a world. May only take a reference.
     */
    world(world& obj) = delete;

    world(world&& obj) {
        m_world = obj.m_world;
        m_owned = obj.m_owned;
        obj.m_world = nullptr;
        obj.m_owned = false;
    }

    /* Implicit conversion to world_t* */
    operator world_t*() { return m_world; }

    /* Not allowed to copy a world. May only take a reference.
     */
    world& operator=(world& obj) = delete;

    world& operator=(world&& obj) {
        this->~world();

        m_world = obj.m_world;
        m_owned = obj.m_owned;
        obj.m_world = nullptr;
        obj.m_owned = false;
        return *this;
    }

    ~world() {
        if (m_owned && ecs_stage_is_async(m_world)) {
            ecs_async_stage_free(m_world);
        } else
        if (m_owned && m_world) {
            ecs_fini(m_world);
        }
    }

    /* Obtain pointer to C world object.
     */
    world_t* c_ptr() {
        return m_world;
    }

    /* Enable tracing.
     *
     * @param level The tracing level.
     */
    static void enable_tracing(int level) {
        ecs_tracing_enable(level);
    }

    void set_pipeline(flecs::pipeline& pip) const;

    /* Progress world, run all systems.
     *
     * @param delta_time Custom delta_time. If 0 is provided, Flecs will automatically measure delta_tiem.
     */
    bool progress(FLECS_FLOAT delta_time = 0.0) {
        return ecs_progress(m_world, delta_time);
    }

    /* Signal application should quit.
     * After calling this operation, the next call to progress() returns false.
     */
    void quit() {
        ecs_quit(m_world);
    }

    /* Test if quit() has been called.
     */
    bool should_quit() {
        return ecs_should_quit(m_world);
    }

    /* Get id from a type.
     */
    template <typename T>
    flecs::id id() const;

    /* Get pair id from relation, object
     */
    template <typename R, typename O>
    flecs::id pair() const;

    /* Get pair id from relation, object
     */
    template <typename R>
    flecs::id pair(entity_t o) const;

    /* Get pair id from relation, object
     */
    flecs::id pair(entity_t r, entity_t o) const;

    /* Begin frame.
     * When an application does not use progress() to control the main loop, it
     * can still use Flecs features such as FPS limiting and time measurements.
     * This operation needs to be invoked whenever a new frame is about to get
     * processed.
     *
     * Calls to frame_begin must always be followed by frame_end.
     *
     * The function accepts a delta_time parameter, which will get passed to
     * systems. This value is also used to compute the amount of time the
     * function needs to sleep to ensure it does not exceed the target_fps, when
     * it is set. When 0 is provided for delta_time, the time will be measured.
     *
     * This function should only be ran from the main thread.
     *
     * @param delta_time Time elapsed since the last frame.
     * @return The provided delta_time, or measured time if 0 was provided.
     */
    FLECS_FLOAT frame_begin(float delta_time = 0) {
        return ecs_frame_begin(m_world, delta_time);
    }

    /* End frame.
     * This operation must be called at the end of the frame, and always after
     * ecs_frame_begin.
     *
     * This function should only be ran from the main thread.
     */
    void frame_end() {
        ecs_frame_end(m_world);
    }

    /* Begin staging.
     * When an application does not use ecs_progress to control the main loop, it
     * can still use Flecs features such as the defer queue. When an application
     * needs to stage changes, it needs to call this function after ecs_frame_begin.
     * A call to ecs_staging_begin must be followed by a call to ecs_staging_end.
     *
     * When staging is enabled, modifications to entities are stored to a stage.
     * This ensures that arrays are not modified while iterating. Modifications are
     * merged back to the "main stage" when ecs_staging_end is invoked.
     *
     * While the world is in staging mode, no structural changes (add/remove/...)
     * can be made to the world itself. Operations must be executed on a stage
     * instead (see ecs_get_stage).
     *
     * This function should only be ran from the main thread.
     *
     * @return Whether world is currently staged.
     */
    bool staging_begin() {
        return ecs_staging_begin(m_world);
    }

    /* End staging.
     * Leaves staging mode. After this operation the world may be directly mutated
     * again. By default this operation also merges data back into the world, unless
     * automerging was disabled explicitly.
     *
     * This function should only be ran from the main thread.
     */
    void staging_end() {
        ecs_staging_end(m_world);
    }

    /* Defer operations until end of frame.
     * When this operation is invoked while iterating, operations inbetween the
     * defer_begin and defer_end operations are executed at the end of the frame.
     *
     * This operation is thread safe.
     */
    bool defer_begin() {
        return ecs_defer_begin(m_world);
    }

    /* End block of operations to defer.
     * See defer_begin.
     *
     * This operation is thread safe.
     */
    bool defer_end() {
        return ecs_defer_end(m_world);
    }

    /* Test whether deferring is enabled.
     */
    bool is_deferred() {
        return ecs_is_deferred(m_world);
    }

    /* Configure world to have N stages.
     * This initializes N stages, which allows applications to defer operations to
     * multiple isolated defer queues. This is typically used for applications with
     * multiple threads, where each thread gets its own queue, and commands are
     * merged when threads are synchronized.
     *
     * Note that set_threads() already creates the appropriate number of stages.
     * The set_stages() operation is useful for applications that want to manage
     * their own stages and/or threads.
     *
     * @param stages The number of stages.
     */
    void set_stages(int32_t stages) {
        ecs_set_stages(m_world, stages);
    }

    /* Get number of configured stages.
     * Return number of stages set by set_stages.
     *
     * @return The number of stages used for threading.
     */
    int32_t get_stage_count() {
        return ecs_get_stage_count(m_world);
    }

    /* Get current stage id.
     * The stage id can be used by an application to learn about which stage it
     * is using, which typically corresponds with the worker thread id.
     *
     * @return The stage id.
     */
    int32_t get_stage_id() {
        return ecs_get_stage_id(m_world);
    }

    /* Enable/disable automerging for world or stage.
     * When automerging is enabled, staged data will automatically be merged
     * with the world when staging ends. This happens at the end of progress(),
     * at a sync point or when staging_end() is called.
     *
     * Applications can exercise more control over when data from a stage is
     * merged by disabling automerging. This requires an application to
     * explicitly call merge() on the stage.
     *
     * When this function is invoked on the world, it sets all current stages to
     * the provided value and sets the default for new stages. When this
     * function is invoked on a stage, automerging is only set for that specific
     * stage.
     *
     * @param automerge Whether to enable or disable automerging.
     */
    void set_automerge(bool automerge) {
        ecs_set_automerge(m_world, automerge);
    }

    /* Merge world or stage.
     * When automatic merging is disabled, an application can call this
     * operation on either an individual stage, or on the world which will merge
     * all stages. This operation may only be called when staging is not enabled
     * (either after progress() or after staging_end()).
     *
     * This operation may be called on an already merged stage or world.
     */
    void merge() {
        ecs_merge(m_world);
    }

    /* Get stage-specific world pointer.
     * Flecs threads can safely invoke the API as long as they have a private
     * context to write to, also referred to as the stage. This function returns a
     * pointer to a stage, disguised as a world pointer.
     *
     * Note that this function does not(!) create a new world. It simply wraps the
     * existing world in a thread-specific context, which the API knows how to
     * unwrap. The reason the stage is returned as an ecs_world_t is so that it
     * can be passed transparently to the existing API functions, vs. having to
     * create a dediated API for threading.
     *
     * @param stage_id The index of the stage to retrieve.
     * @return A thread-specific pointer to the world.
     */
    flecs::world get_stage(int32_t stage_id) {
        return flecs::world(ecs_get_stage(m_world, stage_id));
    }

    /* Create asynchronous stage.
     * An asynchronous stage can be used to asynchronously queue operations for
     * later merging with the world. An asynchronous stage is similar to a regular
     * stage, except that it does not allow reading from the world.
     *
     * Asynchronous stages are never merged automatically, and must therefore be
     * manually merged with the ecs_merge function. It is not necessary to call
     * defer_begin or defer_end before and after enqueuing commands, as an
     * asynchronous stage unconditionally defers operations.
     *
     * The application must ensure that no commands are added to the stage while the
     * stage is being merged.
     *
     * An asynchronous stage must be cleaned up by ecs_async_stage_free.
     *
     * @return The stage.
     */
    flecs::world async_stage() {
        auto result = flecs::world(ecs_async_stage_new(m_world));
        result.m_owned = true;
        return result;
    }

    /* Get actual world.
     * If the current object points to a stage, this operation will return the
     * actual world.
     *
     * @return The actual world.
     */
    flecs::world get_world() {
        /* Safe cast, mutability is checked */
        return flecs::world(
            m_world ? const_cast<flecs::world_t*>(ecs_get_world(m_world)) : nullptr);
    }

    /* Test whether the current world object is readonly.
     * This function allows the code to test whether the currently used world
     * object is readonly or whether it allows for writing.
     *
     * @return True if the world or stage is readonly.
     */
    bool is_readonly() {
        return ecs_stage_is_readonly(m_world);
    }

    /* Set number of threads.
     * This will distribute the load evenly across the configured number of
     * threads for each system.
     *
     * @param threads Number of threads.
     */
    void set_threads(int32_t threads) {
        ecs_set_threads(m_world, threads);
    }

    /* Get number of threads.
     *
     * @return Number of configured threads.
     */
    int32_t get_threads() {
        return ecs_get_threads(m_world);
    }

    /* Get index of current thread.
     *
     * @return Unique index for current thread.
     */
    ECS_DEPRECATED("use get_stage_id")
    int32_t get_thread_index() {
        return ecs_get_stage_id(m_world);
    }

    /* Set target FPS
     * This will ensure that the main loop (world::progress) does not run faster
     * than the specified frames per second.
     *
     * @param target_fps Target frames per second.
     */
    void set_target_fps(FLECS_FLOAT target_fps) {
        ecs_set_target_fps(m_world, target_fps);
    }

    /* Get target FPS
     *
     * @return Configured frames per second.
     */
    FLECS_FLOAT get_target_fps() {
        ecs_world_info_t *stats = ecs_get_world_info(m_world);
        return stats->target_fps;
    }

    /* Get tick
     *
     * @return Monotonically increasing frame count.
     */
    int32_t get_tick() {
        ecs_world_info_t *stats = ecs_get_world_info(m_world);
        return stats->frame_count_total;
    }

    /* Set timescale
     *
     * @return Monotonically increasing frame count.
     */
    void set_time_scale(FLECS_FLOAT mul) {
        ecs_set_time_scale(m_world, mul);
    }

    /* Get timescale
     *
     * @return Monotonically increasing frame count.
     */
    FLECS_FLOAT get_time_scale() {
        ecs_world_info_t *stats = ecs_get_world_info(m_world);
        return stats->time_scale;
    }

    /* Set world context.
     * Set a context value that can be accessed by anyone that has a reference
     * to the world.
     *
     * @param ctx The world context.
     */
    void set_context(void* ctx) {
        ecs_set_context(m_world, ctx);
    }

    /* Get world context.
     *
     * @return The configured world context.
     */
    void* get_context() {
        return ecs_get_context(m_world);
    }

    /* Preallocate memory for number of entities.
     * This function preallocates memory for the entity index.
     *
     * @param entity_count Number of entities to preallocate memory for.
     */
    void dim(int32_t entity_count) {
        ecs_dim(m_world, entity_count);
    }

    /* Preallocate memory for type
     * This function preallocates memory for the component arrays of the
     * specified type.
     *
     * @param type Type to preallocate memory for.
     * @param entity_count Number of entities to preallocate memory for.
     */
    void dim_type(type_t t, int32_t entity_count) {
        ecs_dim_type(m_world, t, entity_count);
    }

    /* Set entity range.
     * This function limits the range of issued entity ids between min and max.
     *
     * @param min Minimum entity id issued.
     * @param max Maximum entity id issued.
     */
    void set_entity_range(entity_t min, entity_t max) {
        ecs_set_entity_range(m_world, min, max);
    }

    /* Enforce that operations cannot modify entities outside of range.
     * This function ensures that only entities within the specified range can
     * be modified. Use this function if specific parts of the code only are
     * allowed to modify a certain set of entities, as could be the case for
     * networked applications.
     *
     * @param enabled True if range check should be enabled, false if not.
     */
    void enable_range_check(bool enabled) {
        ecs_enable_range_check(m_world, enabled);
    }

    /* Disables inactive systems.
     *
     * This removes systems that are not matched with any entities from the main
     * loop. Systems are only added to the main loop after they first match with
     * entities, but are not removed automatically.
     *
     * This function allows an application to manually disable inactive systems
     * which removes them from the main loop. Doing so will cause Flecs to
     * rebuild the pipeline in the next iteration.
     *
     * @param level The tracing level.
     */
    void deactivate_systems() {
        ecs_deactivate_systems(m_world);
    }

    /* Set current scope.
     *
     * @param scope The scope to set.
     * @return The current scope;
     */
    flecs::entity set_scope(flecs::entity& scope) const;

    /* Get current scope.
     *
     * @return The current scope.
     */
    flecs::entity get_scope() const;

    /* Lookup entity by name.
     *
     * @param name Entity name.
     */
    flecs::entity lookup(char *name) const;

    /* Set singleton component.
     */
    template <typename T>
    void set(T& value) {
        flecs::set<T>(m_world, _::cpp_type<T>::id(m_world), value);
    }

    template <typename T>
    void set(T&& value) {
        flecs::set<T>(m_world, _::cpp_type<T>::id(m_world), std::forward<T&&>(value));
    }

    /* Get mut singleton component.
     */
    template <typename T>
    T* get_mut() const;

    /* Mark singleton component as modified.
     */
    template <typename T>
    void modified() const;

    /* Patch singleton component.
     */
    template <typename T, typename Func>
    void patch(Func& func) const;

    /* Get singleton component.
     */
    template <typename T>
    T* get() const;

    /* Test if world has singleton component.
     */
    template <typename T>
    bool has() const;

    /* Add singleton component.
     */
    template <typename T>
    void add() const;

    /* Remove singleton component.
     */
    template <typename T>
    void remove() const;

    /* Get id for type.
     */
    template <typename T>
    entity_t type_id() {
        return _::cpp_type<T>::id(m_world);
    }

    /* Get singleton entity for type.
     */
    template <typename T>
    flecs::entity singleton();

    /* Create alias for component.
     *
     * @tparam Component to create an alias for.
     * @param alias Alias for the component.
     */
    template <typename T>
    flecs::entity use(char *alias = nullptr);

    /* Create alias for entity.
     *
     * @param name Name of the entity.
     * @param alias Alias for the entity.
     */
    flecs::entity use(char *name, char *alias = nullptr);

    /* Create alias for entity.
     *
     * @param entity Entity for which to create the alias.
     * @param alias Alias for the entity.
     */
    void use(flecs::entity entity, char *alias = nullptr);

    /* Delete all entities matching a filter.
     *
     * @param filter The filter to use for matching.
     */
    void delete_entities(flecs::filter filter) const;

    /* Add component to all entities matching a filter.
     *
     * @tparam T The component to add.
     * @param filter The filter to use for matching.
     */
    template <typename T>
    void add(flecs::filter filter) const;

    /* Add type to all entities.
     *
     * @param type The type to add.
     */
    void add(flecs::type type) const;

    /* Add type to all entities matching a filter.
     *
     * @param type The type to add.
     * @param filter The filter to use for matching.
     */
    void add(flecs::type type, flecs::filter filter) const;

    /* Add entity to all entities.
     *
     * @param entity The entity to add.
     */
    void add(flecs::entity entity) const;

    /* Add entity to all entities matching a filter.
     *
     * @param entity The entity to add.
     * @param filter The filter to use for matching.
     */
    void add(flecs::entity entity, flecs::filter filter) const;

    /* Remove component from all entities matching a filter.
     *
     * @tparam T The component to remove.
     * @param filter The filter to use for matching.
     */
    template <typename T>
    void remove(flecs::filter filter) const;

    /* Remove type from all entities.
     *
     * @param type The component to remove.
     */
    void remove(flecs::type type) const;

    /* Remove type from all entities matching a filter.
     *
     * @tparam T The component to remove.
     * @param filter The filter to use for matching.
     */
    void remove(flecs::type type, flecs::filter filter) const;

    /* Remove entity from all entities.
     *
     * @param entity The entity to remove.
     */
    void remove(flecs::entity entity) const;

    /* Remove entity from all entities matching a filter.
     *
     * @param entity The entity to remove.
     * @param filter The filter to use for matching.
     */
    void remove(flecs::entity entity, flecs::filter filter) const;

    /* Create iterable filter for entities in world.
     *
     * @param filter The filter to create.
     */
    world_filter filter(flecs::filter& filter) const;

    flecs::filter_iterator begin() const;
    flecs::filter_iterator end() const;

    /* Count entities matching a component.
     *
     * @tparam T The component to use for matching.
     */
    template <typename T>
    int count() {
        return ecs_count_id(m_world, _::cpp_type<T>::id(m_world));
    }

    /* Count entities matching a filter.
     *
     * @param filter The filter to use for matching.
     */
    int count(flecs::filter filter) const;

    /* Enable locking.
     *
     * @param enabled True if locking should be enabled, false if not.
     */
    bool enable_locking(bool enabled) {
        return ecs_enable_locking(m_world, enabled);
    }

    /* Lock world.
     */
    void lock() {
        ecs_lock(m_world);
    }

    /* Unlock world.
     */
    void unlock() {
        ecs_unlock(m_world);
    }

    /* All entities created in function are created with id.
     */
    template <typename Func>
    void with(id_t with_id, Func& func) {
        ecs_id_t prev = ecs_set_with(m_world, with_id);
        func();
        ecs_set_with(m_world, prev);
    }

    /* All entities created in function are created with type.
     */
    template <typename T, typename Func>
    void with(Func& func) {
        with(this->id<T>(), func);
    }

    /* All entities created in function are created with relation.
     */
    template <typename Relation, typename Object, typename Func>
    void with(Func& func) {
        with(ecs_pair(this->id<Relation>(), this->id<Object>()), func);
    }

    /* All entities created in function are created with relation.
     */
    template <typename Relation, typename Func>
    void with(id_t object, Func& func) {
        with(ecs_pair(this->id<Relation>(), object), func);
    }

    /* All entities created in function are created with relation.
     */
    template <typename Func>
    void with(id_t relation, id_t object, Func& func) {
        with(ecs_pair(relation, object), func);
    }

    /* All entities created in function are created in scope. All operations
     * called in function (such as lookup) are relative to scope.
     */
    template <typename Func>
    void scope(id_t parent, Func& func) {
        ecs_entity_t prev = ecs_set_scope(m_world, parent);
        func();
        ecs_set_scope(m_world, prev);
    }

    /* Defer all operations called in function. If the world is already in
     * deferred mode, do nothing.
     */
    template <typename Func>
    void defer(Func& func) {
        ecs_defer_begin(m_world);
        func();
        ecs_defer_end(m_world);
    }

    /* Create a prefab.
     */
    template <typename... Args>
    flecs::entity entity(Args &&... args) const;

    /* Create an entity.
     */
    template <typename... Args>
    flecs::entity prefab(Args &&... args) const;

    /* Create a type.
     */
    template <typename... Args>
    flecs::type type(Args &&... args) const;

    /* Create a pipeline.
     */
    template <typename... Args>
    flecs::pipeline pipeline(Args &&... args) const;

    /* Create a module.
     */
    template <typename Module, typename... Args>
    flecs::entity module(Args &&... args) const;

    /* Import a module.
     */
    template <typename Module>
    flecs::entity import(); // Cannot be because modules accept a non-world

    /* Create a system from an entity
     */
    flecs::system<> system(flecs::entity e) const;

    /* Create a system.
     */
    template <typename... Comps, typename... Args>
    flecs::system_builder<Comps...> system(Args &&... args) const;

    /* Create an observer.
     */
    template <typename... Comps, typename... Args>
    flecs::observer_builder<Comps...> observer(Args &&... args) const;

    /* Create a query.
     */
    template <typename... Comps, typename... Args>
    flecs::query<Comps...> query(Args &&... args) const;

    /* Create a query builder.
     */
    template <typename... Comps, typename... Args>
    flecs::query_builder<Comps...> query_builder(Args &&... args) const;

    /* Create a term
     */
    template<typename... Args>
    flecs::term term(Args &&... args) const;

    /* Create a term for a type
     */
    template<typename T, typename... Args>
    flecs::term term(Args &&... args) const;

    /* Create a term for a pair
     */
    template<typename R, typename O, typename... Args>
    flecs::term term(Args &&... args) const;

    /* Register a component.
     */
    template <typename T, typename... Args>
    flecs::entity component(Args &&... args) const;

    /* Register a POD component.
     */
    template <typename T, typename... Args>
    flecs::entity pod_component(Args &&... args) const;

    /* Register a relocatable component.
     */
    template <typename T, typename... Args>
    flecs::entity relocatable_component(Args &&... args) const;

    /* Create a snapshot.
     */
    template <typename... Args>
    flecs::snapshot snapshot(Args &&... args) const;

private:
    void init_builtin_components();

    world_t *m_world;
    bool m_owned;
};

// Downcast utility to make world available to classes in inheritance hierarchy
template<typename Base>
class world_base {
public:
    template<typename IBuilder>
    static flecs::world world(IBuilder *self) {
        return flecs::world(static_cast<Base*>(self)->m_world);
    }

    flecs::world world() {
        return flecs::world(static_cast<Base*>(this)->m_world);
    }
};

} // namespace flecs

namespace flecs {

template<typename T, typename Base>
class entity_builder_base {
public:
    Base& base() { return *static_cast<Base*>(this); }
    flecs::world_t* base_world() { return base().world(); }
    flecs::entity_t base_id() { return base().id(); }
    operator Base&() {
        return this->base();
    }
};

}

#ifdef FLECS_DEPRECATED

namespace flecs
{

struct entity_builder_deprecated_tag { };

/* Deprecated functions */
template <typename Base>
class entity_builder_deprecated : public entity_builder_base<entity_builder_deprecated_tag, Base> {
public:
    template<typename T, typename C>
    ECS_DEPRECATED("use add<Relation, Object>")
    Base& add_trait() {
        ecs_add_pair(this->base_world(), this->base_id(),
            _::cpp_type<T>::id(this->base_world()),
            _::cpp_type<C>::id(this->base_world()));
        return *this;
    }

    template<typename T>
    ECS_DEPRECATED("use add<Relation>(entity&)")
    Base& add_trait(Base& c) {
        ecs_add_pair(this->base_world(), this->base_id(), _::cpp_type<T>::id(this->base_world()), c.id());
        return *this;
    }

    template<typename C>
    ECS_DEPRECATED("use add_object<Object>(entity&)")
    Base& add_trait_tag(Base& t) {
        ecs_add_pair(this->base_world(), this->base_id(), t.id(), _::cpp_type<C>::id(this->base_world()));
        return *this;
    }

    ECS_DEPRECATED("use add(entity&, entity&)")
    Base& add_trait(Base& t, Base& c) {
        ecs_add_pair(this->base_world(), this->base_id(), t.id(), c.id());
        return *this;
    }

    template<typename T, typename C>
    ECS_DEPRECATED("use remove<Relation, Object>")
    Base& remove_trait() {
        ecs_remove_pair(this->base_world(), this->base_id(),
            _::cpp_type<T>::id(this->base_world()),
            _::cpp_type<C>::id(this->base_world()));
        return *this;
    }

    template<typename T>
    ECS_DEPRECATED("use remove<Relation>(entity&)")
    Base& remove_trait(Base& c) {
        ecs_remove_pair(this->base_world(), this->base_id(), _::cpp_type<T>::id(this->base_world()), c.id());
        return *this;
    }

    template<typename C>
    ECS_DEPRECATED("use remove_object<Object>(entity&)")
    Base& remove_trait_tag(Base& t) {
        ecs_remove_pair(this->base_world(), this->base_id(), t.id(), _::cpp_type<C>::id(this->base_world()));
        return *this;
    }

    ECS_DEPRECATED("use remove(entity&, entity&)")
    Base& remove_trait(Base& t, Base& c) {
        ecs_remove_pair(this->base_world(), this->base_id(), t.id(), c.id());
        return *this;
    }

    template <typename T, typename C>
    ECS_DEPRECATED("use set<Relation, Object>(Relation&)")
    Base& set_trait(T& value) {
        auto comp_id = _::cpp_type<T>::id(this->base_world());
        ecs_assert(_::cpp_type<T>::size() != 0, ECS_INVALID_PARAMETER, NULL);

        ecs_set_ptr_w_entity(this->base_world(), this->base_id(),
            ecs_pair(comp_id, _::cpp_type<C>::id(this->base_world())),
            sizeof(T), &value);

        return *this;
    }

    template <typename T>
    ECS_DEPRECATED("use set<Relation>(entity&, Relation&)")
    Base& set_trait(T& value, Base& c) {
        auto comp_id = _::cpp_type<T>::id(this->base_world());
        ecs_assert(_::cpp_type<T>::size() != 0, ECS_INVALID_PARAMETER, NULL);

        ecs_set_ptr_w_entity(this->base_world(), this->base_id(),
            ecs_pair(comp_id, c.id()),
            sizeof(T), &value);

        return *this;
    }

    template <typename C>
    ECS_DEPRECATED("use set_object<Object>(entity&, Object&)")
    Base& set_trait_tag(Base& t, C& value) {
        auto comp_id = _::cpp_type<C>::id(this->base_world());
        ecs_assert(_::cpp_type<C>::size() != 0, ECS_INVALID_PARAMETER, NULL);

        ecs_set_ptr_w_entity(this->base_world(), this->base_id(),
            ecs_pair(t.id(), comp_id),
            sizeof(C), &value);

        return *this;
    }

    ECS_DEPRECATED("use child_of(parent)")
    Base& add_childof(Base& parent) {
        ecs_add_id(this->base_world(), this->base_id(), ECS_CHILDOF | parent.id());
        return *this;
    }

    ECS_DEPRECATED("use remove(flecs::ChildOf, parent)")
    Base& remove_childof(Base& parent) {
        ecs_remove_id(this->base_world(), this->base_id(), ECS_CHILDOF | parent.id());
        return *this;
    }

    ECS_DEPRECATED("use add(flecs::IsA, base)")
    Base& add_instanceof(Base& base_entity) {
        ecs_add_id(this->base_world(), this->base_id(), ECS_INSTANCEOF | base_entity.id());
        return *this;
    }

    ECS_DEPRECATED("use remove(flecs::IsA, base)")
    Base& remove_instanceof(Base& base_entity) {
        ecs_remove_id(this->base_world(), this->base_id(), ECS_INSTANCEOF | base_entity.id());
        return *this;
    }

    ECS_DEPRECATED("use set(Func func)")
    template <typename T, typename Func>
    Base& patch(Func& func) {
        auto comp_id = _::cpp_type<T>::id(this->base_world());

        ecs_assert(_::cpp_type<T>::size() != 0,
            ECS_INVALID_PARAMETER, NULL);

        bool is_added;
        T *ptr = static_cast<T*>(ecs_get_mut_w_entity(
            this->base_world(), this->base_id(), comp_id, &is_added));
        ecs_assert(ptr != NULL, ECS_INTERNAL_ERROR, NULL);

        func(*ptr);
        ecs_modified_w_entity(this->base_world(), this->base_id(), comp_id);

        return *this;
    }
};

struct entity_deprecated_tag { };

template<typename Base>
class entity_deprecated : entity_builder_base<entity_deprecated_tag, Base> {
public:
    template<typename T, typename C>
    ECS_DEPRECATED("use get<Relation, Object>")
    T* get_trait() {
        auto comp_id = _::cpp_type<T>::id(this->base_world());
        ecs_assert(_::cpp_type<T>::size() != 0, ECS_INVALID_PARAMETER, NULL);

        return static_cast<T*>(ecs_get_id(this->base_world(), this->base_id(), ecs_trait(
            _::cpp_type<C>::id(this->base_world()), comp_id)));
    }

    template<typename T>
    ECS_DEPRECATED("use get<Relation>(entity&)")
    T* get_trait(Base& c) {
        auto comp_id = _::cpp_type<T>::id(this->base_world());
        ecs_assert(_::cpp_type<T>::size() != 0, ECS_INVALID_PARAMETER, NULL);

        return static_cast<T*>(ecs_get_id(this->base_world(), this->base_id(), ecs_trait(
            c.id(), comp_id)));
    }

    template<typename C>
    ECS_DEPRECATED("use get_object<Object>(entity&)")
    C* get_trait_tag(Base& t) {
        auto comp_id = _::cpp_type<C>::id(this->base_world());
        ecs_assert(_::cpp_type<C>::size() != 0, ECS_INVALID_PARAMETER, NULL);

        return static_cast<C*>(ecs_get_id(this->base_world(), this->base_id(), ecs_trait(
            comp_id, t.id())));
    }

    ECS_DEPRECATED("use get(entity&, entity&)")
    void* get_trait(Base& t, Base& c) const{
        return ecs_get_id(this->base_world(), this->base_id(), ecs_trait(c.id(), t.id()));
    }

    template <typename T, typename C>
    ECS_DEPRECATED("use get_mut<Relation, Object>(bool)")
    T* get_trait_mut(bool *is_added = nullptr) {
        auto t_id = _::cpp_type<T>::id(this->base_world());
        ecs_assert(_::cpp_type<T>::size() != 0, ECS_INVALID_PARAMETER, NULL);

        return static_cast<T*>(
            ecs_get_mut_w_entity(
                this->base_world(), this->base_id(), ecs_trait(_::cpp_type<C>::id(this->base_world()),
                    t_id), is_added));
    }

    template <typename T>
    ECS_DEPRECATED("use get_mut<Relation>(entity&, bool)")
    T* get_trait_mut(Base& c, bool *is_added = nullptr) {
        auto comp_id = _::cpp_type<T>::id(this->base_world());
        ecs_assert(_::cpp_type<T>::size() != 0, ECS_INVALID_PARAMETER, NULL);

        return static_cast<T*>(
            ecs_get_mut_w_entity(
                this->base_world(), this->base_id(), ecs_trait( comp_id, c.id()), is_added));
    }

    template <typename C>
    ECS_DEPRECATED("use get_mut_object<Object>(entity&, bool)")
    C* get_trait_tag_mut(Base& t, bool *is_added = nullptr) {
        auto comp_id = _::cpp_type<C>::id(this->base_world());
        ecs_assert(_::cpp_type<C>::size() != 0, ECS_INVALID_PARAMETER, NULL);

        return static_cast<C*>(
            ecs_get_mut_w_entity(
                this->base_world(), this->base_id(), ecs_trait(comp_id, t.id()), is_added));
    }

    ECS_DEPRECATED("use has(flecs::ChildOf, parent)")
    bool has_childof(Base& parent) {
        return ecs_has_entity(this->base_world(), this->base_id(), ECS_CHILDOF | parent.id());
    }

    ECS_DEPRECATED("use has(flecs::IsA, base)")
    bool has_instanceof(Base& base) {
        return ecs_has_entity(this->base_world(), this->base_id(), ECS_INSTANCEOF | base.id());
    }

    template<typename T, typename C>
    ECS_DEPRECATED("use has<Relation, Object>")
    bool has_trait() {
        return ecs_has_entity(this->base_world(), this->base_id(), ecs_trait(
            _::cpp_type<C>::id(this->base_world()),
            _::cpp_type<T>::id(this->base_world())));
    }

    template<typename T>
    ECS_DEPRECATED("use has<Relation>(flecs::entity&)")
    bool has_trait(Base& component) {
        return ecs_has_entity(this->base_world(), this->base_id(), ecs_trait(
            component.id(), _::cpp_type<T>::id(this->base_world())));
    }

    template<typename C>
    ECS_DEPRECATED("use has_object<Object>(flecs::entity&)")
    bool has_trait_tag(Base& trait) {
        return ecs_has_entity(this->base_world(), this->base_id(), ecs_trait(
           _::cpp_type<C>::id(this->base_world()), trait.id()));
    }

    ECS_DEPRECATED("use has(flecs::entity&, flecs::entity&)")
    bool has_trait(Base& trait, Base& e) {
        return ecs_has_entity(this->base_world(), this->base_id(), ecs_trait(
            e.id(), trait.id()));
    }
};

}
#else
namespace flecs
{
template <typename Base>
class entity_builder_deprecated { };
class entity_deprecated { };
}
#endif

namespace flecs
{

/* Class that stores a flecs id.
 * A flecs id is an identifier that can store an entity id, an relation-object
 * pair, or role annotated id (such as SWITCH | Movement).
 */
class id : public world_base<id> {
public:
    explicit id()
        : m_world(nullptr)
        , m_id(0) { }

    explicit id(flecs::id_t value)
        : m_world(nullptr)
        , m_id(value) { }

    explicit id(flecs::world_t *world, flecs::id_t value)
        : m_world(world)
        , m_id(value) { }

    explicit id(flecs::world_t *world, flecs::id_t relation, flecs::id_t object)
        : m_world(world)
        , m_id(ecs_pair(relation, object)) { }

    explicit id(flecs::id_t relation, flecs::id_t object)
        : m_world(nullptr)
        , m_id(ecs_pair(relation, object)) { }

    explicit id(flecs::id& relation, flecs::id& object)
        : m_world(relation.world())
        , m_id(ecs_pair(relation.m_id, object.m_id)) { }

    /* Test if id is pair (has relation, object) */
    bool is_pair() {
        return (m_id & ECS_ROLE_MASK) == flecs::Pair;
    }

    /* Test if id has the Switch role */
    bool is_switch() {
        return (m_id & ECS_ROLE_MASK) == flecs::Switch;
    }

    /* Test if id has the Case role */
    bool is_case() {
        return (m_id & ECS_ROLE_MASK) == flecs::Case;
    }

    /* Return id with role added */
    flecs::entity add_role(flecs::id_t role) const;

    /* Return id with role removed */
    flecs::entity remove_role(flecs::id_t role) const;

    /* Return id without role */
    flecs::entity remove_role() const;

    /* Return id without role */
    flecs::entity remove_generation() const;

    /* Test if id has specified role */
    bool has_role(flecs::id_t role) {
        return ((m_id & ECS_ROLE_MASK) == role);
    }

    /* Test if id has any role */
    bool has_role() {
        return (m_id & ECS_ROLE_MASK) != 0;
    }

    flecs::entity role() const;

    /* Test if id has specified relation */
    bool has_relation(flecs::id_t relation) {
        if (!is_pair()) {
            return false;
        }
        return ECS_PAIR_RELATION(m_id) == relation;
    }

    /* Get relation from pair.
     * If the id is not a pair, this operation will fail. When the id has a
     * world, the operation will ensure that the returned id has the correct
     * generation count.
     */
    flecs::entity relation() const;

    /* Get object from pair.
     * If the id is not a pair, this operation will fail. When the id has a
     * world, the operation will ensure that the returned id has the correct
     * generation count.
     */
    flecs::entity object() const;

    /* Convert id to string. */
    flecs::string role_str() {
        return flecs::string_view( ecs_role_str(m_id & ECS_ROLE_MASK));
    }

    ECS_DEPRECATED("use object()")
    flecs::entity lo() const;

    ECS_DEPRECATED("use relation()")
    flecs::entity hi() const;

    ECS_DEPRECATED("use flecs::id(relation, object)")
    static
    flecs::entity comb(entity_view lo, entity_view hi);

    flecs::id_t raw_id() {
        return m_id;
    }

    operator flecs::id_t() {
        return m_id;
    }

    /* World is optional, but guarantees that entity identifiers extracted from
     * the id are valid */
    flecs::world_t *m_world;
    flecs::id_t m_id;
};

/* Entity view class
 * This class provides readonly access to entities. Using this class to store
 * entities in components ensures valid handles, as this class will always store
 * the actual world vs. a stage. The constructors of this class will never
 * create a new entity.
 *
 * To obtain a mutable handle to the entity, use the "mut" function.
 */
class entity_view : public id {
public:
    explicit entity_view() : flecs::id() { }

    /* Wrap an existing entity id.
     *
     * @param world The world in which the entity is created.
     * @param id The entity id.
     */
    explicit entity_view(flecs::world& world, entity_view& id)
        : flecs::id( world.get_world(), id.id() ) { }

    /* Wrap an existing entity id.
     *
     * @param world Pointer to the world in which the entity is created.
     * @param id The entity id.
     */
    explicit entity_view(world_t *world, entity_view& id)
        : flecs::id( flecs::world(world).get_world(), id.id() ) { }

    /* Implicit conversion from flecs::entity_t to flecs::entity_view. */
    entity_view(entity_t id)
        : flecs::id( nullptr, id ) { }

    /* Entity id 0.
     * This function is useful when the API must provide an entity object that
     * belongs to a world, but the entity id is 0.
     *
     * @param world The world.
     */
    static
    flecs::entity_view null(flecs::world& world) {
        return flecs::entity_view(world.get_world().c_ptr(), static_cast<entity_t>(0));
    }

    static
    flecs::entity_view null() {
        return flecs::entity_view(static_cast<entity_t>(0));
    }

    /* Get entity id.
     * @return The integer entity id.
     */
    entity_t id() {
        return m_id;
    }

    /* Check is entity is valid.
     *
     * @return True if the entity is alive, false otherwise.
     */
    bool is_valid() {
        return m_world && ecs_is_valid(m_world, m_id);
    }

    explicit operator bool() {
        return is_valid();
    }

    /* Check is entity is alive.
     *
     * @return True if the entity is alive, false otherwise.
     */
    bool is_alive() {
        return m_world && ecs_is_alive(m_world, m_id);
    }

    /* Return the entity name.
     *
     * @return The entity name, or an empty string if the entity has no name.
     */
    flecs::string_view name() {
        EcsName *name = static_cast<EcsName*>(
            ecs_get_id(m_world, m_id, static_cast<ecs_entity_t>(ecs_id(EcsName))));
        return flecs::string_view(name ? name->value : nullptr);
    }

    /* Return the entity path.
     *
     * @return The hierarchical entity path, or an empty string if the entity
     *         has no name.
     */
    flecs::string path(char *sep = "::", char *init_sep = "::") {
        char *path = ecs_get_path_w_sep(m_world, 0, m_id, 0, sep, init_sep);
        return flecs::string(path);
    }

    bool enabled() {
        return !ecs_has_entity(m_world, m_id, flecs::Disabled);
    }

    /* Return the type.
     *
     * @return Returns the entity type.
     */
    flecs::type type() const;

    /* Return type containing the entity.
     *
     * @return A type that contains only this entity.
     */
    flecs::type to_type() const;

    /* Iterate contents (type) of an entity.
     */
    template <typename Func>
    void each(Func& func) const;

    /* Iterate contents (type) of an entity for a specific relationship.
     */
    template <typename Func>
    void each(flecs::entity_view& rel, Func& func) const;

    /* Iterate contents (type) of an entity for a specific relationship.
     */
    template <typename Rel, typename Func>
    void each(Func& func) {
        return each(_::cpp_type<Rel>::id(m_world), func);
    }

    /* Find all contents of an entity matching a pattern. */
    template <typename Func>
    void match(id_t pattern, Func& func) const;

    /* Get component value.
     *
     * @tparam T The component to get.
     * @return Pointer to the component value, nullptr if the entity does not
     *         have the component.
     */
    template <typename T, if_t< is_actual<T>::value > = 0>
    T* get() {
        auto comp_id = _::cpp_type<T>::id(m_world);
        ecs_assert(_::cpp_type<T>::size() != 0, ECS_INVALID_PARAMETER, NULL);
        return static_cast<T*>(ecs_get_id(m_world, m_id, comp_id));
    }

    /* Get component value.
     * Overload for when T is not the same as the actual type, which happens
     * when using pair types.
     *
     * @tparam T The component to get.
     * @return Pointer to the component value, nullptr if the entity does not
     *         have the component.
     */
    template <typename T, typename A = actual_type_t<T>,
        if_not_t< is_actual<T>::value > = 0>
    A* get() {
        auto comp_id = _::cpp_type<T>::id(m_world);
        ecs_assert(_::cpp_type<A>::size() != 0, ECS_INVALID_PARAMETER, NULL);
        return static_cast<A*>(ecs_get_id(m_world, m_id, comp_id));
    }

    /* Get a pair.
     * This operation gets the value for a pair from the entity.
     *
     * @tparam R the relation type.
     * @tparam O the object type.
     */
    template <typename R, typename O, typename P = pair<R, O>,
        typename A = actual_type_t<P>, if_not_t< flecs::is_pair<R>::value > = 0>
    A* get() {
        return this->get<P>();
    }

    /* Get a pair.
     * This operation gets the value for a pair from the entity.
     *
     * @tparam R the relation type.
     * @param object the object.
     */
    template<typename R>
    R* get(flecs::entity_view& object) {
        auto comp_id = _::cpp_type<R>::id(m_world);
        ecs_assert(_::cpp_type<R>::size() != 0, ECS_INVALID_PARAMETER, NULL);
        return static_cast<R*>(
            ecs_get_id(m_world, m_id, ecs_pair(comp_id, object.id())));
    }

    /* Get component value (untyped).
     *
     * @param component The component to get.
     * @return Pointer to the component value, nullptr if the entity does not
     *         have the component.
     */
    void* get(flecs::entity_view& component) {
        return ecs_get_id(m_world, m_id, component.id());
    }

    /* Get a pair (untyped).
     * This operation gets the value for a pair from the entity. If neither the
     * relation nor the object part of the pair are components, the operation
     * will fail.
     *
     * @param relation the relation.
     * @param object the object.
     */
    void* get(flecs::entity_view& relation, flecs::entity_view& object) {
        return ecs_get_id(m_world, m_id, ecs_pair(relation.id(), object.id()));
    }

    /* Get 1..N components.
     * This operation accepts a callback with as arguments the components to
     * retrieve. The callback will only be invoked when the entity has all
     * the components.
     *
     * This operation is faster than individually calling get for each component
     * as it only obtains entity metadata once.
     *
     * @param func The callback to invoke.
     * @return True if the entity has all components, false if not.
     */
    template <typename Func, if_t< is_callable<Func>::value > = 0>
    bool get(Func& func) const;

    /* Get the object part from a pair.
     * This operation gets the value for a pair from the entity. The relation
     * part of the pair should not be a component.
     *
     * @tparam O the object type.
     * @param relation the relation.
     */
    template<typename O>
    O* get_object(flecs::entity_view& relation) {
        auto comp_id = _::cpp_type<O>::id(m_world);
        ecs_assert(_::cpp_type<O>::size() != 0, ECS_INVALID_PARAMETER, NULL);
        return static_cast<O*>(
            ecs_get_id(m_world, m_id, ecs_pair(relation.id(), comp_id)));
    }

    /* Get the object part from a pair.
     * This operation gets the value for a pair from the entity. The relation
     * part of the pair should not be a component.
     *
     * @tparam R the relation type.
     * @tparam O the object type.
     */
    template<typename R, typename O>
    O* get_object() {
        return get<pair_object<R, O>>();
    }

    /* Get parent from an entity.
     * This operation retrieves the parent entity that has the specified
     * component. If no parent with the specified component is found, an entity
     * with id 0 is returned. If multiple parents have the specified component,
     * the operation returns the first encountered one.
     *
     * @tparam T The component for which to find the parent.
     * @return The parent entity.
     */
    template <typename T>
    flecs::entity_view get_parent() {
        return flecs::entity_view(m_world,
            ecs_get_parent_w_entity(m_world, m_id,
                _::cpp_type<T>::id(m_world)));
    }

    flecs::entity_view get_parent(flecs::entity_view e) {
        return flecs::entity_view(m_world,
            ecs_get_parent_w_entity(m_world, m_id, e.id()));
    }

    /* Lookup an entity by name.
     * Lookup an entity in the scope of this entity. The provided path may
     * contain double colons as scope separators, for example: "Foo::Bar".
     *
     * @param path The name of the entity to lookup.
     * @return The found entity, or entity::null if no entity matched.
     */
    flecs::entity_view lookup(char *path) {
        auto id = ecs_lookup_path_w_sep(m_world, m_id, path, "::", "::", false);
        return flecs::entity_view(m_world, id);
    }

    /* Check if entity has the provided type.
     *
     * @param entity The type pointer to check.
     * @return True if the entity has the provided type, false otherwise.
     */
    bool has(type_t type) {
        return ecs_has_type(m_world, m_id, type);
    }

    /* Check if entity has the provided entity.
     *
     * @param entity The entity to check.
     * @return True if the entity has the provided entity, false otherwise.
     */
    bool has(flecs::entity_view& e) {
        return ecs_has_entity(m_world, m_id, e.id());
    }

    /* Check if entity has the provided component.
     *
     * @tparam T The component to check.
     * @return True if the entity has the provided component, false otherwise.
     */
    template <typename T>
    bool has() {
        return ecs_has_entity(m_world, m_id, _::cpp_type<T>::id(m_world));
    }

    /* Check if entity has the provided pair.
     *
     * @tparam Relation The relation type.
     * @param Object The object type.
     * @return True if the entity has the provided component, false otherwise.
     */
    template <typename Relation, typename Object>
    bool has() {
        return this->has<Relation>(_::cpp_type<Object>::id(m_world));
    }

    /* Check if entity has the provided pair.
     *
     * @tparam Relation The relation type.
     * @param object The object.
     * @return True if the entity has the provided component, false otherwise.
     */
    template <typename Relation>
    bool has(flecs::entity_view& object) {
        auto comp_id = _::cpp_type<Relation>::id(m_world);
        return ecs_has_entity(m_world, m_id,
            ecs_pair(comp_id, object.id()));
    }

    /* Check if entity has the provided pair.
     *
     * @param relation The relation.
     * @param object The object.
     * @return True if the entity has the provided component, false otherwise.
     */
    bool has(flecs::entity_view& relation, flecs::entity_view& object) {
        return ecs_has_entity(m_world, m_id,
            ecs_pair(relation.id(), object.id()));
    }

    /* Check if entity has the provided pair.
     *
     * @tparam Object The object type.
     * @param relation The relation.
     * @return True if the entity has the provided component, false otherwise.
     */
    template <typename Object>
    bool has_object(flecs::entity_view& relation) {
        auto comp_id = _::cpp_type<Object>::id(m_world);
        return ecs_has_entity(m_world, m_id,
            ecs_pair(relation.id(), comp_id));
    }

    /* Check if entity owns the provided type.
     * An type is owned if it is not shared from a base entity.
     *
     * @param type The type to check.
     * @return True if the entity owns the provided type, false otherwise.
     */
    bool owns(type_t type) {
        return ecs_type_owns_type(
            m_world, ecs_get_type(m_world, m_id), type, true);
    }

    /* Check if entity owns the provided entity.
     * An entity is owned if it is not shared from a base entity.
     *
     * @param entity The entity to check.
     * @return True if the entity owns the provided entity, false otherwise.
     */
    bool owns(flecs::entity_view& e) {
        return ecs_owns_entity(m_world, m_id, e.id(), true);
    }

    /* Check if entity owns the provided component.
     * An component is owned if it is not shared from a base entity.
     *
     * @tparam T The component to check.
     * @return True if the entity owns the provided component, false otherwise.
     */
    template <typename T>
    bool owns() {
        return owns(_::cpp_type<T>::id(m_world));
    }

    /* Check if entity has the provided switch.
     *
     * @param sw The switch to check.
     * @return True if the entity has the provided switch, false otherwise.
     */
    bool has_switch(flecs::type& sw) const;

    /* Check if entity has the provided case.
     *
     * @param sw_case The case to check.
     * @return True if the entity has the provided case, false otherwise.
     */
    bool has_case(flecs::entity_view& sw_case) {
        return ecs_has_entity(m_world, m_id, flecs::Case | sw_case.id());
    }

    template<typename T>
    bool has_case() {
        return this->has_case(_::cpp_type<T>::id(m_world));
    }

    /* Get case for switch.
     *
     * @param sw The switch for which to obtain the case.
     * @return True if the entity has the provided case, false otherwise.
     */
    flecs::entity_view get_case(flecs::type& sw) const;

    /* Get case for switch.
     *
     * @param sw The switch for which to obtain the case.
     * @return True if the entity has the provided case, false otherwise.
     */
    flecs::entity_view get_case(flecs::entity_view& sw) {
        return flecs::entity_view(m_world, ecs_get_case(m_world, m_id, sw.id()));
    }

    /* Test if component is enabled.
     *
     * @tparam T The component to test.
     * @return True if the component is enabled, false if it has been disabled.
     */
    template<typename T>
    bool is_enabled() {
        return ecs_is_component_enabled_w_entity(
            m_world, m_id, _::cpp_type<T>::id(m_world));
    }

    /* Test if component is enabled.
     *
     * @param entity The component to test.
     * @return True if the component is enabled, false if it has been disabled.
     */
    bool is_enabled(flecs::entity_view& e) {
        return ecs_is_component_enabled_w_entity(
            m_world, m_id, e.id());
    }

    /* Get current delta time.
     * Convenience function so system implementations can get delta_time, even
     * if they are using the .each() function.
     *
     * @return Current delta_time.
     */
    FLECS_FLOAT delta_time() {
        ecs_world_info_t *stats = ecs_get_world_info(m_world);
        return stats->delta_time;
    }

    /* Return iterator to entity children.
     * Enables depth-first iteration over entity children.
     *
     * @return Iterator to child entities.
     */
    child_iterator children() const;

    /* Return mutable entity handle for current stage
     * When an entity handle created from the world is used while the world is
     * in staged mode, it will only allow for readonly operations since
     * structural changes are not allowed on the world while in staged mode.
     *
     * To do mutations on the entity, this operation provides a handle to the
     * entity that uses the stage instead of the actual world.
     *
     * Note that staged entity handles should never be stored persistently, in
     * components or elsewhere. An entity handle should always point to the
     * main world.
     *
     * Also note that this operation is not necessary when doing mutations on an
     * entity outside of a system. It is allowed to do entity operations
     * directly on the world, as long as the world is not in staged mode.
     *
     * @param stage The current stage.
     * @return An entity handle that allows for mutations in the current stage.
     */
    flecs::entity mut(flecs::world& stage) const;

    /* Same as mut(world), but for iterator.
     * This operation allows for the construction of a mutable entity handle
     * from an iterator.
     *
     * @param stage An created for the current stage.
     * @return An entity handle that allows for mutations in the current stage.
     */
    flecs::entity mut(flecs::iter& it) const;

    /* Same as mut(world), but for entity.
     * This operation allows for the construction of a mutable entity handle
     * from another entity. This is useful in each() functions, which only
     * provide a handle to the entity being iterated over.
     *
     * @param stage An created for the current stage.
     * @return An entity handle that allows for mutations in the current stage.
     */
    flecs::entity mut(flecs::entity_view& e) const;

private:
    flecs::entity set_stage(world_t *stage);
};

/* Fluent API for chaining entity operations
 * This class contains entity operations that can be chained. For example, by
 * using this class, an entity can be created like this:
 *
 * flecs::entity e = flecs::entity(world)
 *   .add<Position>()
 *   .add<Velocity>();
 */
struct entity_builder_tag { }; // Tag to prevent ambiguous base

template <typename Base>
class entity_builder : public entity_builder_base<entity_builder_tag, Base> {
public:
    /* Add a component to an entity.
     * To ensure the component is initialized, it should have a constructor.
     *
     * @tparam T the component type to add.
     */
    template <typename T>
    Base& add() {
        flecs_static_assert(is_flecs_constructible<T>::value,
            "add<T>() cannot construct type: add T() or "
                "T(flecs::world&, flecs::entity)");
        ecs_add_id(this->base_world(), this->base_id(), _::cpp_type<T>::id(this->base_world()));
        return *this;
    }

    /* Add an entity to an entity.
     * Add an entity to the entity. This is typically used for tagging.
     *
     * @param entity The entity to add.
     */
    Base& add(entity_t entity) {
        ecs_add_id(this->base_world(), this->base_id(), entity);
        return *this;
    }

    /* Add a type to an entity.
     * A type is a vector of component ids. This operation adds all components
     * in a single operation, and is a more efficient version of doing
     * individual add operations.
     *
     * @param type The type to add.
     */
    Base& add(type& type) const;

    /* Add a pair.
     * This operation adds a pair to the entity.
     *
     * @param relation The relation id.
     * @param object The object id.
     */
    Base& add(entity_t relation, entity_t object) {
        ecs_add_pair(this->base_world(), this->base_id(), relation, object);
        return *this;
    }

    /* Add a pair.
     * This operation adds a pair to the entity.
     *
     * @tparam R the relation type.
     * @tparam O the object type.
     */
    template<typename R, typename O>
    Base& add() {
        return this->add<R>(_::cpp_type<O>::id(this->base_world()));
    }

    /* Add a pair.
     * This operation adds a pair to the entity.
     *
     * @tparam R the relation type.
     * @param object the object type.
     */
    template<typename R>
    Base& add(entity_t object) {
        flecs_static_assert(is_flecs_constructible<R>::value,
            "add<T>(entity_t) cannot construct type: add T() or "
                "T(flecs::world&, flecs::entity)");
        return this->add(_::cpp_type<R>::id(this->base_world()), object);
    }

    /* Shortcut for add(IsA. obj).
     *
     * @param object the object id.
     */
    Base& is_a(entity_t object) {
        return this->add(flecs::IsA, object);
    }

    /* Shortcut for add(ChildOf. obj).
     *
     * @param object the object id.
     */
    Base& child_of(entity_t object) {
        return this->add(flecs::ChildOf, object);
    }

    /* Add a pair with object type.
     * This operation adds a pair to the entity. The relation part of the pair
     * should not be a component.
     *
     * @param relation the relation type.
     * @tparam O the object type.
     */
    template<typename O>
    Base& add_object(entity_t relation) {
        flecs_static_assert(is_flecs_constructible<O>::value,
            "add_object<T>(entity_t) cannot construct type: add T() or "
                "T(flecs::world&, flecs::entity)");
        return this->add(relation,  _::cpp_type<O>::id(this->base_world()));
    }

    /* Remove a component from an entity.
     *
     * @tparam T the type of the component to remove.
     */
    template <typename T>
    Base& remove() {
        ecs_remove_id(this->base_world(), this->base_id(), _::cpp_type<T>::id(this->base_world()));
        return *this;
    }

    /* Remove an entity from an entity.
     *
     * @param entity The entity to remove.
     */
    Base& remove(entity_t entity) {
        ecs_remove_id(this->base_world(), this->base_id(), entity);
        return *this;
    }

    /* Remove a type from an entity.
     * A type is a vector of component ids. This operation adds all components
     * in a single operation, and is a more efficient version of doing
     * individual add operations.
     *
     * @param type the type to remove.
     */
    Base& remove(type& type) const;

    /* Remove a pair.
     * This operation removes a pair from the entity.
     *
     * @param relation The relation id.
     * @param object The object id.
     */
    Base& remove(entity_t relation, entity_t object) {
        ecs_remove_pair(this->base_world(), this->base_id(), relation, object);
        return *this;
    }

    /* Removes a pair.
     * This operation removes a pair from the entity.
     *
     * @tparam Relation the relation type.
     * @tparam Object the object type.
     */
    template<typename Relation, typename Object>
    Base& remove() {
        return this->remove<Relation>(_::cpp_type<Object>::id(this->base_world()));
    }

    /* Remove a pair.
     * This operation adds a pair to the entity.
     *
     * @tparam Relation the relation type.
     * @param object the object type.
     */
    template<typename Relation>
    Base& remove(entity_t object) {
        return this->remove(_::cpp_type<Relation>::id(this->base_world()), object);
    }

    /* Removes a pair with object type.
     * This operation removes a pair from the entity.
     *
     * @param relation the relation type.
     * @tparam Object the object type.
     */
    template<typename Object>
    Base& remove_object(entity_t relation) {
        return this->remove(relation, _::cpp_type<Object>::id(this->base_world()));
    }

    /* Add owned flag for component (forces ownership when instantiating)
     *
     * @param entity The entity for which to add the OWNED flag
     */
    Base& add_owned(entity_t entity) {
        ecs_add_id(this->base_world(), this->base_id(), ECS_OWNED | entity);
        return *this;
    }

    /* Add owned flag for component (forces ownership when instantiating)
     *
     * @tparam T The component for which to add the OWNED flag
     */
    template <typename T>
    Base& add_owned() {
        ecs_add_id(this->base_world(), this->base_id(), ECS_OWNED | _::cpp_type<T>::id(this->base_world()));
        return *this;
    }

    ECS_DEPRECATED("use add_owned(flecs::entity e)")
    Base& add_owned(type& type) const;

    /* Set value, add owned flag.
     *
     * @tparam T The component to set and for which to add the OWNED flag
     */
    template <typename T>
    Base& set_owned(T&& val) {
        this->add_owned<T>();
        this->set<T>(std::forward<T>(val));
        return *this;
    }

    /* Add a switch to an entity by id.
     * The switch entity must be a type, that is it must have the EcsType
     * component. Entities created with flecs::type are valid here.
     *
     * @param sw The switch entity id to add.
     */
    Base& add_switch(entity_t sw) {
        ecs_add_id(this->base_world(), this->base_id(), ECS_SWITCH | sw);
        return *this;
    }

    /* Add a switch to an entity.
     * Any instance of flecs::type can be used as a switch.
     *
     * @param sw The switch to add.
     */
    Base& add_switch(type& sw) const;

    /* Remove a switch from an entity by id.
     *
     * @param sw The switch entity id to remove.
     */
    Base& remove_switch(entity_t sw) {
        ecs_remove_id(this->base_world(), this->base_id(), ECS_SWITCH | sw);
        return *this;
    }

    /* Remove a switch from an entity.
     * Any instance of flecs::type can be used as a switch.
     *
     * @param sw The switch to remove.
     */
    Base& remove_switch(type& sw) const;

    /* Add a switch to an entity by id.
     * The case must belong to a switch that is already added to the entity.
     *
     * @param sw_case The case entity id to add.
     */
    Base& add_case(entity_t sw_case) {
        ecs_add_id(this->base_world(), this->base_id(), ECS_CASE | sw_case);
        return *this;
    }

    /* Add a switch to an entity by id.
     * The case must belong to a switch that is already added to the entity.
     *
     * @tparam T The case to add.
     */
    template<typename T>
    Base& add_case() {
        return this->add_case(_::cpp_type<T>::id());
    }

    /* Remove a case from an entity by id.
     * The case must belong to a switch that is already added to the entity.
     *
     * @param sw_case The case entity id to remove.
     */
    Base& remove_case(entity_t sw_case) {
        ecs_remove_id(this->base_world(), this->base_id(), ECS_CASE | sw_case);
        return *this;
    }

    /* Remove a switch from an entity by id.
     * The case must belong to a switch that is already added to the entity.
     *
     * @tparam T The case to remove.
     */
    template<typename T>
    Base& remove_case() {
        return this->remove_case(_::cpp_type<T>::id());
    }

    /* Enable an entity.
     * Enabled entities are matched with systems and can be searched with
     * queries.
     */
    Base& enable() {
        ecs_enable(this->base_world(), this->base_id(), true);
        return *this;
    }

    /* Disable an entity.
     * Disabled entities are not matched with systems and cannot be searched
     * with queries, unless explicitly specified in the query expression.
     */
    Base& disable() {
        ecs_enable(this->base_world(), this->base_id(), false);
        return *this;
    }

    /* Enable a component.
     * This sets the enabled bit for this component. If this is the first time
     * the component is enabled or disabled, the bitset is added.
     *
     * @tparam T The component to enable.
     */
    template<typename T>
    Base& enable() {
        ecs_enable_component_w_entity(this->base_world(), this->base_id(), _::cpp_type<T>::id(), true);
        return *this;
    }

    /* Disable a component.
     * This sets the enabled bit for this component. If this is the first time
     * the component is enabled or disabled, the bitset is added.
     *
     * @tparam T The component to enable.
     */
    template<typename T>
    Base& disable() {
        ecs_enable_component_w_entity(this->base_world(), this->base_id(), _::cpp_type<T>::id(), false);
        return *this;
    }

    /* Enable a component.
     * See enable<T>.
     *
     * @param component The component to enable.
     */
    Base& enable(entity_t component) {
        ecs_enable_component_w_entity(this->base_world(), this->base_id(), component, true);
        return *this;
    }

    /* Disable a component.
     * See disable<T>.
     *
     * @param component The component to disable.
     */
    Base& disable(entity_t component) {
        ecs_enable_component_w_entity(this->base_world(), this->base_id(), component, false);
        return *this;
    }

    template<typename T, if_t<
        !is_callable<T>::value && is_actual<T>::value> = 0 >
    Base& set(T&& value) {
        flecs::set<T>(this->base_world(), this->base_id(), std::forward<T&&>(value));
        return *this;
    }

    template<typename T, if_t<
        !is_callable<T>::value && is_actual<T>::value > = 0>
    Base& set(T& value) {
        flecs::set<T>(this->base_world(), this->base_id(), value);
        return *this;
    }

    template<typename T, typename A = actual_type_t<T>, if_not_t<
        is_callable<T>::value || is_actual<T>::value > = 0>
    Base& set(A&& value) {
        flecs::set<T>(this->base_world(), this->base_id(), std::forward<A&&>(value));
        return *this;
    }

    template<typename T, typename A = actual_type_t<T>, if_not_t<
        is_callable<T>::value || is_actual<T>::value > = 0>
    Base& set(A& value) {
        flecs::set<T>(this->base_world(), this->base_id(), value);
        return *this;
    }

    /* Set a pair for an entity.
     * This operation sets the pair value, and uses the relation as type. If the
     * entity did not yet have the pair, it will be added.
     *
     * @tparam R The relation part of the pair.
     * @tparam O The object part of the pair.
     * @param value The value to set.
     */
    template <typename R, typename O, typename P = pair<R, O>,
        typename A = actual_type_t<P>, if_not_t< is_pair<R>::value> = 0>
    Base& set(A& value) {
        flecs::set<P>(this->base_world(), this->base_id(), value);
        return *this;
    }

    /* Set a pair for an entity.
     * This operation sets the pair value, and uses the relation as type. If the
     * entity did not yet have the pair, it will be added.
     *
     * @tparam R The relation part of the pair.
     * @param object The object part of the pair.
     * @param value The value to set.
     */
    template <typename R>
    Base& set(entity_t object, R& value) {
        auto relation = _::cpp_type<R>::id(this->base_world());
        flecs::set(this->base_world(), this->base_id(), value,
            ecs_pair(relation, object));
        return *this;
    }

    /* Set a pair for an entity.
     * This operation sets the pair value, and uses the relation as type. If the
     * entity did not yet have the pair, it will be added.
     *
     * @tparam Object The object part of the pair.
     * @param relation The relation part of the pair.
     * @param value The value to set.
     */
    template <typename O>
    Base& set_object(entity_t relation, O& value) {
        auto object = _::cpp_type<O>::id(this->base_world());
        flecs::set(this->base_world(), this->base_id(), value,
            ecs_pair(relation, object));
        return *this;
    }

    template <typename R, typename O>
    Base& set_object(O& value) {
        flecs::set<pair_object<R, O>>(this->base_world(), this->base_id(), value);
        return *this;
    }

    /* Set 1..N components.
     * This operation accepts a callback with as arguments the components to
     * set. If the entity does not have all of the provided components, they
     * will be added.
     *
     * This operation is faster than individually calling get for each component
     * as it only obtains entity metadata once. When this operation is called
     * while deferred, its performance is equivalent to that of calling get_mut
     * for each component separately.
     *
     * The operation will invoke modified for each component after the callback
     * has been invoked.
     *
     * @param func The callback to invoke.
     */
    template <typename Func, if_t< is_callable<Func>::value > = 0>
    Base& set(Func& func) const;

    /* Entities created in function will have the current entity.
     *
     * @param func The function to call.
     */
    template <typename Func>
    Base& with(Func& func) {
        ecs_id_t prev = ecs_set_with(this->base_world(), this->base_id());
        func();
        ecs_set_with(this->base_world(), prev);
        return *this;
    }

    /* Entities created in function will have (Relation, this)
     * This operation is thread safe.
     *
     * @tparam Relation The relation to use.
     * @param func The function to call.
     */
    template <typename Relation, typename Func>
    Base& with(Func& func) {
        with(_::cpp_type<Relation>::id(this->base_world()), func);
        return *this;
    }

    /* Entities created in function will have (relation, this)
     *
     * @param relation The relation to use.
     * @param func The function to call.
     */
    template <typename Func>
    Base& with(id_t relation, Func& func) {
        ecs_id_t prev = ecs_set_with(this->base_world(),
            ecs_pair(relation, this->base_id()));
        func();
        ecs_set_with(this->base_world(), prev);
        return *this;
    }

    /* The function will be ran with the scope set to the current entity. */
    template <typename Func>
    Base& scope(Func& func) {
        ecs_entity_t prev = ecs_set_scope(this->base_world(), this->base_id());
        func();
        ecs_set_scope(this->base_world(), prev);
        return *this;
    }
};

////////////////////////////////////////////////////////////////////////////////
//// Quick and safe access to a component pointer
////////////////////////////////////////////////////////////////////////////////

template <typename T>
class ref {
public:
    ref()
        : m_world( nullptr )
        , m_entity( 0 )
        , m_ref() { }

    ref(world_t *world, entity_t entity)
        : m_world( world )
        , m_entity( entity )
        , m_ref()
    {
        auto comp_id = _::cpp_type<T>::id(world);

        ecs_assert(_::cpp_type<T>::size() != 0,
                ECS_INVALID_PARAMETER, NULL);

        ecs_get_ref_w_entity(
            m_world, &m_ref, m_entity, comp_id);
    }

    T* operator->() {
        T* result = static_cast<T*>(ecs_get_ref_w_entity(
            m_world, &m_ref, m_entity, _::cpp_type<T>::id(m_world)));

        ecs_assert(result != NULL, ECS_INVALID_PARAMETER, NULL);

        return result;
    }

    T* get() {
        if (m_entity) {
            ecs_get_ref_w_entity(
                m_world, &m_ref, m_entity, _::cpp_type<T>::id(m_world));
        }

        return static_cast<T*>(m_ref.ptr);
    }

    flecs::entity entity() const;

private:
    world_t *m_world;
    entity_t m_entity;
    flecs::ref_t m_ref;
};

/* Entity class
 * This class provides access to entities. */
class entity :
    public entity_view,
    public entity_builder<entity>,
    public entity_deprecated<entity>,
    public entity_builder_deprecated<entity>
{
public:
    /* Default constructor.
     */
    explicit entity()
        : flecs::entity_view() { }

    /* Create entity.
     *
     * @param world The world in which to create the entity.
     */
    explicit entity(world_t *world)
        : flecs::entity_view()
    {
        m_world = world;
        m_id = ecs_new_w_type(world, 0);
    }

    /* Create a named entity.
     * Named entities can be looked up with the lookup functions. Entity names
     * may be scoped, where each element in the name is separated by "::".
     * For example: "Foo::Bar". If parts of the hierarchy in the scoped name do
     * not yet exist, they will be automatically created.
     *
     * @param world The world in which to create the entity.
     * @param name The entity name.
     * @param is_component If true, the entity will be created from the pool of component ids (default = false).
     */
    explicit entity(world_t *world, char *name)
        : flecs::entity_view()
    {
        m_world = world;

        ecs_entity_desc_t desc = {};
        desc.name = name;
        desc.sep = "::";
        m_id = ecs_entity_init(world, &desc);
    }

    /* Wrap an existing entity id.
     *
     * @param world The world in which the entity is created.
     * @param id The entity id.
     */
    explicit entity(world_t *world, entity_t id)
        : flecs::entity_view()
    {
        m_world = world;
        m_id = id;
    }

    /* Conversion from flecs::entity_t to flecs::entity. */
    explicit entity(entity_t id)
        : flecs::entity_view( nullptr, id ) { }

    /* Get entity id.
     * @return The integer entity id.
     */
    entity_t id() {
        return m_id;
    }

    /* Get mutable component value.
     * This operation returns a mutable pointer to the component. If the entity
     * did not yet have the component, it will be added. If a base entity had
     * the component, it will be overridden, and the value of the base component
     * will be copied to the entity before this function returns.
     *
     * @tparam T The component to get.
     * @param is_added If provided, this parameter will be set to true if the component was added.
     * @return Pointer to the component value.
     */
    template <typename T>
    T* get_mut(bool *is_added = nullptr) {
        auto comp_id = _::cpp_type<T>::id(m_world);
        ecs_assert(_::cpp_type<T>::size() != 0, ECS_INVALID_PARAMETER, NULL);
        return static_cast<T*>(
            ecs_get_mut_w_entity(m_world, m_id, comp_id, is_added));
    }

    /* Get mutable component value (untyped).
     * This operation returns a mutable pointer to the component. If the entity
     * did not yet have the component, it will be added. If a base entity had
     * the component, it will be overridden, and the value of the base component
     * will be copied to the entity before this function returns.
     *
     * @param component The component to get.
     * @param is_added If provided, this parameter will be set to true if the component was added.
     * @return Pointer to the component value.
     */
    void* get_mut(entity_t component, bool *is_added = nullptr) {
        return ecs_get_mut_w_entity(m_world, m_id, component, is_added);
    }

    /* Get mutable pointer for a pair.
     * This operation gets the value for a pair from the entity.
     *
     * @tparam Relation the relation type.
     * @tparam Object the object type.
     */
    template <typename Relation, typename Object>
    Relation* get_mut(bool *is_added = nullptr) {
        return this->get_mut<Relation>(
            _::cpp_type<Object>::id(m_world), is_added);
    }

    /* Get mutable pointer for a pair.
     * This operation gets the value for a pair from the entity.
     *
     * @tparam Relation the relation type.
     * @param object the object.
     */
    template <typename Relation>
    Relation* get_mut(entity_t object, bool *is_added = nullptr) {
        auto comp_id = _::cpp_type<Relation>::id(m_world);
        ecs_assert(_::cpp_type<Relation>::size() != 0, ECS_INVALID_PARAMETER, NULL);
        return static_cast<Relation*>(
            ecs_get_mut_w_entity(m_world, m_id,
                ecs_pair(comp_id, object), is_added));
    }

    /* Get mutable pointer for a pair (untyped).
     * This operation gets the value for a pair from the entity. If neither the
     * relation or object are a component, the operation will fail.
     *
     * @param relation the relation.
     * @param object the object.
     */
    void* get_mut(entity_t relation, entity_t object, bool *is_added = nullptr) {
        return ecs_get_mut_w_entity(m_world, m_id,
                ecs_pair(relation, object), is_added);
    }

    /* Get mutable pointer for the object from a pair.
     * This operation gets the value for a pair from the entity.
     *
     * @tparam Object the object type.
     * @param relation the relation.
     */
    template <typename Object>
    Object* get_mut_object(entity_t relation, bool *is_added = nullptr) {
        auto comp_id = _::cpp_type<Object>::id(m_world);
        ecs_assert(_::cpp_type<Object>::size() != 0, ECS_INVALID_PARAMETER, NULL);
        return static_cast<Object*>(
            ecs_get_mut_w_entity(m_world, m_id,
                ecs_pair(relation, comp_id), is_added));
    }

    /* Signal that component was modified.
     *
     * @tparam T component that was modified.
     */
    template <typename T>
    void modified() {
        auto comp_id = _::cpp_type<T>::id(m_world);
        ecs_assert(_::cpp_type<T>::size() != 0, ECS_INVALID_PARAMETER, NULL);
        this->modified(comp_id);
    }

    /* Signal that the relation part of a pair was modified.
     *
     * @tparam Relation the relation type.
     * @tparam Object the object type.
     */
    template <typename Relation, typename Object>
    void modified() {
        this->modified<Relation>(_::cpp_type<Object>::id(m_world));
    }

    /* Signal that the relation part of a pair was modified.
     *
     * @tparam Relation the relation type.
     * @param object the object.
     */
    template <typename Relation>
    void modified(entity_t object) {
        auto comp_id = _::cpp_type<Relation>::id(m_world);
        ecs_assert(_::cpp_type<Relation>::size() != 0, ECS_INVALID_PARAMETER, NULL);
        this->modified(comp_id, object);
    }

    /* Signal that a pair has modified (untyped).
     * If neither the relation or object part of the pair are a component, the
     * operation will fail.
     *
     * @param relation the relation.
     * @param object the object.
     */
    void modified(entity_t relation, entity_t object) {
        this->modified(ecs_pair(relation, object));
    }

    /* Signal that component was modified.
     *
     * @param component component that was modified.
     */
    void modified(entity_t component) {
        ecs_modified_w_entity(m_world, m_id, component);
    }

    /* Get reference to component.
     * A reference allows for quick and safe access to a component value, and is
     * a faster alternative to repeatedly calling 'get' for the same component.
     *
     * @tparam T component for which to get a reference.
     * @return The reference.
     */
    template <typename T>
    ref<T> get_ref() {
        // Ensure component is registered
        _::cpp_type<T>::id(m_world);
        ecs_assert(_::cpp_type<T>::size() != 0, ECS_INVALID_PARAMETER, NULL);
        return ref<T>(m_world, m_id);
    }

    /* Clear an entity.
     * This operation removes all components from an entity without recycling
     * the entity id.
     */
    void clear() {
        ecs_clear(m_world, m_id);
    }

    /* Delete an entity.
     * Entities have to be deleted explicitly, and are not deleted when the
     * flecs::entity object goes out of scope.
     */
    void destruct() {
        ecs_delete(m_world, m_id);
    }

    /* Used by builder class. Do not invoke (deprecated). */
    template <typename Func>
    void invoke(Func&& action) {
        action(m_world, m_id);
    }
};

/* Prefab class */
class prefab final : public entity {
public:
    explicit prefab(world_t *world, char *name = nullptr)
        : entity(world, name)
    {
        this->add(flecs::Prefab);
    }
};

} // namespace flecs
////////////////////////////////////////////////////////////////////////////////
//// Register component, provide global access to component handles / metadata
////////////////////////////////////////////////////////////////////////////////

namespace flecs
{

namespace _
{

    // Trick to obtain typename from type, as described here
    // https://blog.molecular-matters.com/2015/12/11/getting-the-type-of-a-template-argument-as-string-without-rtti/
    //
    // The code from the link has been modified to work with more types, and across
    // multiple compilers.
    //
    struct name_util {
        /* Remove parts from typename that aren't needed for component name */
        static void trim_name(char *typeName) {
            ecs_size_t len = ecs_os_strlen(typeName);

            /* Remove 'const' */
            ecs_size_t const_len = ecs_os_strlen("");
            if ((len > const_len) && !ecs_os_strncmp(typeName, "", const_len)) {
                ecs_os_memmove(typeName, typeName + const_len, len - const_len);
                typeName[len - const_len] = '\0';
                len -= const_len;
            }

            /* Remove 'struct' */
            ecs_size_t struct_len = ecs_os_strlen("struct ");
            if ((len > struct_len) && !ecs_os_strncmp(typeName, "struct ", struct_len)) {
                ecs_os_memmove(typeName, typeName + struct_len, len - struct_len);
                typeName[len - struct_len] = '\0';
                len -= struct_len;
            }

            /* Remove 'class' */
            ecs_size_t class_len = ecs_os_strlen("class ");
            if ((len > class_len) && !ecs_os_strncmp(typeName, "class ", class_len)) {
                ecs_os_memmove(typeName, typeName + class_len, len - class_len);
                typeName[len - class_len] = '\0';
                len -= class_len;
            }

            while (typeName[len - 1] == ' ' ||
                   typeName[len - 1] == '&' ||
                   typeName[len - 1] == '*')
            {
                len --;
                typeName[len] = '\0';
            }

            /* Remove at end of string */
            if (len > const_len) {
                if (!ecs_os_strncmp(&typeName[len - const_len], " const", const_len)) {
                    typeName[len - const_len] = '\0';
                }
            }
        }
    };

// Compiler-specific conversion from __PRETTY_FUNCTION__ to component name.
// This code uses a trick that instantiates a function for the component type.
// Then __PRETTY_FUNCTION__ is used to obtain the name of the function. Because
// the result of __PRETTY_FUNCTION__ is not standardized, there are different
// implementations for clang, gcc and msvc. Code that uses a different compiler
// needs to register component names explicitly.
#if defined(__clang__)
  static unsigned int FRONT_SIZE = sizeof("static char* flecs::_::name_helper<") - 1u;
  static unsigned int BACK_SIZE = sizeof(">::name() [T = ]") - 1u;

  template <typename T>
  struct name_helper
  {
    static char* name(void) {
      static size_t size = (sizeof(__PRETTY_FUNCTION__) - FRONT_SIZE - BACK_SIZE) / 2 + 1u;
      static char typeName[size + 6] = {};
      memcpy(typeName, __PRETTY_FUNCTION__ + FRONT_SIZE, size - 1u);
      name_util::trim_name(typeName);
      return typeName;
    }
  };
#elif defined(__GNUC__)
  static unsigned int FRONT_SIZE = sizeof("static char* flecs::_::name_helper<T>::name() [with T = ") - 1u;
  static unsigned int BACK_SIZE = sizeof("]") - 1u;

  template <typename T>
  struct name_helper
  {
    static char* name(void) {
      static size_t size = sizeof(__PRETTY_FUNCTION__) - FRONT_SIZE - BACK_SIZE;
      static char typeName[size + 6] = {};
      memcpy(typeName, __PRETTY_FUNCTION__ + FRONT_SIZE, size - 1u);
      name_util::trim_name(typeName);
      return typeName;
    }
  };
#elif defined(_WIN32)
  static unsigned int FRONT_SIZE = sizeof("flecs::_::name_helper<") - 1u;
  static unsigned int BACK_SIZE = sizeof(">::name") - 1u;

  template <typename T>
  struct name_helper
  {
    static char* name(void) {
      static size_t size = sizeof(__FUNCTION__) - FRONT_SIZE - BACK_SIZE;
      static char typeName[size + 6] = {};
      memcpy(typeName, __FUNCTION__ + FRONT_SIZE, size - 1u);
      name_util::trim_name(typeName);
      return typeName;
    }
  };
#else
#error "implicit component registration not supported"
#endif

// Translate a typename into a language-agnostic identifier. This allows for
// registration of components/modules across language boundaries.
template <typename T>
struct symbol_helper
{
    static char* symbol(void) {
        char *name = name_helper<T>::name();

        // Symbol is same as name, but with '::' replaced with '.'
        char *ptr, *sym = ecs_os_strdup(name);
        ecs_size_t i, len = ecs_os_strlen(sym);
        ptr = sym;
        for (i = 0, ptr = sym; i < len && *ptr; i ++, ptr ++) {
            if (*ptr == ':') {
                sym[i] = '.';
                ptr ++;
            } else {
                sym[i] = *ptr;
            }
        }

        sym[i] = '\0';

        return sym;
    }
};

// If type is trivial, don't register lifecycle actions. While the functions
// that obtain the lifecycle callback do detect whether the callback is required
// adding a special case for trivial types eases the burden a bit on the
// compiler as it reduces the number of templates to evaluate.
template<typename T, enable_if_t<
    std::is_trivial<T>::value == true
        >* = nullptr>
void register_lifecycle_actions(ecs_world_t*, ecs_entity_t) { }

// If the component is non-trivial, register component lifecycle actions.
// Depending on the type not all callbacks may be available.
template<typename T, enable_if_t<
    std::is_trivial<T>::value == false
        >* = nullptr>
void register_lifecycle_actions(
    ecs_world_t *world,
    ecs_entity_t component)
{
    if (!ecs_component_has_actions(world, component)) {
        EcsComponentLifecycle cl{};
        cl.ctor = ctor<T>().callback;
        cl.dtor = dtor<T>().callback;

        cl.copy = copy<T>().callback;
        cl.copy_ctor = copy_ctor<T>().callback;
        cl.move = move<T>().callback;
        cl.move_ctor = move_ctor<T>().callback;

        cl.merge = merge<T>().callback;

        ecs_set_component_actions_w_entity( world, component, &cl);
    }
}

// Class that manages component ids across worlds & binaries.
// The cpp_type class stores the component id for a C++ type in a static global
// variable that is shared between worlds. Whenever a component is used this
// class will check if it already has been registered (has the global id been
// set), and if not, register the component with the world.
//
// If the id has been set, the class will ensure it is known by the world. If it
// is not known the component has been registered by another world and will be
// registered with the world using the same id. If the id does exist, the class
// will register it as a component, and verify whether the input is consistent.
template <typename T>
class cpp_type_size {
public:
    static size_t size(bool allow_tag) {
        // C++ types that have no members still have a size. Use std::is_empty
        // to check if the type is empty. If so, use 0 for the component size.
        //
        // If s_allow_tag is set to false, the size returned by C++ is used.
        // This is useful in cases where class instances are still required, as
        // is the case with module classes.
        if (allow_tag && std::is_empty<T>::value) {
            return 0;
        } else {
            return sizeof(T);
        }
    }

    static size_t alignment(bool allow_tag) {
        if (size(allow_tag) == 0) {
            return 0;
        } else {
            return alignof(T);
        }
    }
};

template <typename T>
class cpp_type_impl {
public:
    // Initialize component identifier
    static void init(world_t* world, entity_t entity, bool allow_tag = true) {
        // If an identifier was already set, check for consistency
        if (s_id) {
            // If an identifier was registered, a name should've been registered
            // as well.
            ecs_assert(s_name.c_str() != nullptr, ECS_INTERNAL_ERROR, NULL);

            // A component cannot be registered using a different identifier.
            ecs_assert(s_id == entity, ECS_INCONSISTENT_COMPONENT_ID,
                _::name_helper<T>::name());

            ecs_assert(allow_tag == s_allow_tag, ECS_INTERNAL_ERROR, NULL);

            // Component was already registered and data is consistent with new
            // identifier, so nothing else to be done.
            return;
        }

        // Component wasn't registered yet, set the values. Register component
        // name as the fully qualified flecs path.
        char *path = ecs_get_fullpath(world, entity);
        s_id = entity;
        s_name = flecs::string(path);
        s_allow_tag = allow_tag;
    }

    // Names returned from the name_helper class do not start with ::
    // but are relative to the root. If the namespace of the type
    // overlaps with the namespace of the current module, strip it from
    // the implicit identifier.
    // This allows for registration of component types that are not in the
    // module namespace to still be registered under the module scope.
    static char* strip_module(world_t *world) {
        char *name = _::name_helper<T>::name();
        entity_t scope = ecs_get_scope(world);
        if (!scope) {
            return name;
        }

        char *path = ecs_get_path_w_sep(world, 0, scope, 0, "::", nullptr);
        if (path) {
            char *ptr = strrchr(name, ':');
            ecs_assert(ptr != name, ECS_INTERNAL_ERROR, NULL);
            if (ptr) {
                ptr --;
                ecs_assert(ptr[0] == ':', ECS_INTERNAL_ERROR, NULL);
                ecs_size_t name_path_len = static_cast<ecs_size_t>(ptr - name);
                if (name_path_len <= ecs_os_strlen(path)) {
                    if (!ecs_os_strncmp(name, path, name_path_len)) {
                        name = &name[name_path_len + 2];
                    }
                }
            }
        }
        ecs_os_free(path);

        return name;
    }

    // Obtain a component identifier for explicit component registration.
    static entity_t id_explicit(world_t *world = nullptr,
        char *name = nullptr, bool allow_tag = true)
    {
        if (!s_id) {
            // If no world was provided the component cannot be registered
            ecs_assert(world != nullptr, ECS_COMPONENT_NOT_REGISTERED, name);
            s_allow_tag = allow_tag;
        } else {
            ecs_assert(s_allow_tag == allow_tag, ECS_INVALID_PARAMETER, NULL);
        }

        // If no id has been registered yet for the component (indicating the
        // component has not yet been registered, or the component is used
        // across more than one binary), or if the id does not exists in the
        // world (indicating a multi-world application), register it. */
        if (!s_id || (world && !ecs_exists(world, s_id))) {
            if (!name) {
                // If no name was provided, retrieve the name implicitly from
                // the name_helper class.
                name = strip_module(world);
            }

            char *symbol = symbol_helper<T>::symbol();
            ecs_component_desc_t desc = {};
            desc.entity.entity = s_id;
            desc.entity.name = name;
            desc.entity.sep = "::";
            desc.entity.symbol = symbol;
            desc.size = cpp_type_size<T>::size(allow_tag);
            desc.alignment = cpp_type_size<T>::alignment(allow_tag);
            ecs_entity_t entity = ecs_component_init(world, &desc);
            ecs_assert(entity != 0, ECS_INTERNAL_ERROR, NULL);
            ecs_assert(!s_id || s_id == entity, ECS_INTERNAL_ERROR, NULL);
            ecs_os_free(symbol);

            init(world, s_id, allow_tag);
            s_id = entity;
        }

        // By now the identifier must be valid and known with the world.
        ecs_assert(s_id != 0 && ecs_exists(world, s_id), ECS_INTERNAL_ERROR, NULL);

        return s_id;
    }

    // Obtain a component identifier for implicit component registration. This
    // is almost the same as id_explicit, except that this operation
    // automatically registers lifecycle callbacks.
    // Additionally, implicit registration temporarily resets the scope & with
    // state of the world, so that the component is not implicitly created with
    // the scope/with of the code it happens to be first used by.
    static id_t id(world_t *world = nullptr, char *name = nullptr,
        bool allow_tag = true)
    {
        // If no id has been registered yet, do it now.
        if (!s_id || (world && !ecs_exists(world, s_id))) {
            ecs_entity_t prev_scope = 0;
            ecs_id_t prev_with = 0;

            if (world) {
                prev_scope = ecs_set_scope(world, 0);
                prev_with = ecs_set_with(world, 0);
            }

            // This will register a component id, but will not register
            // lifecycle callbacks.
            id_explicit(world, name, allow_tag);

            // Register lifecycle callbacks, but only if the component has a
            // size. Components that don't have a size are tags, and tags don't
            // require construction/destruction/copy/move's. */
            if (size()) {
                register_lifecycle_actions<T>(world, s_id);
            }

            if (prev_with) {
                ecs_set_with(world, prev_with);
            }
            if (prev_scope) {
                ecs_set_scope(world, prev_scope);
            }
        }

        // By now we should have a valid identifier
        ecs_assert(s_id != 0, ECS_INTERNAL_ERROR, NULL);

        return s_id;
    }

    // Obtain a component name
    static char* name(world_t *world = nullptr) {
        // If no id has been registered yet, do it now.
        if (!s_id) {
            id(world);
        }

        // By now we should have a valid identifier
        ecs_assert(s_id != 0, ECS_INTERNAL_ERROR, NULL);

        // If the id is set, the name should also have been set
        return s_name.c_str();
    }

    // Obtain a component name, don't register lifecycle if the component hadn't
    // been registered yet. While functionally the same could be achieved by
    // first calling id_explicit() and then name(), this function ensures
    // that the lifecycle callback templates are not instantiated. This allows
    // some types (such as module classes) to be created without a default
    // constructor.
    static char* name_no_lifecycle(world_t *world = nullptr) {
        // If no id has been registered yet, do it now.
        if (!s_id) {
            id_explicit(world);
        }

        // By now we should have a valid identifier
        ecs_assert(s_id != 0, ECS_INTERNAL_ERROR, NULL);

        // Return
        return s_name.c_str();
    }

    // Return the type of a component.
    // The type is a vector of component ids. This will return a type with just
    // the current component id.
    static type_t type(world_t *world = nullptr) {
        // If no id has been registered yet, do it now.
        if (!s_id) {
            id(world);
        }

        // By now we should have a valid identifier
        ecs_assert(s_id != 0, ECS_INTERNAL_ERROR, NULL);

        // Create a type from the component id.
        if (!s_type) {
            s_type = ecs_type_from_entity(world, s_id);
        }

        ecs_assert(s_type != nullptr, ECS_INTERNAL_ERROR, NULL);

        return s_type;
    }

    // Return the size of a component.
    static size_t size() {
        ecs_assert(s_id != 0, ECS_INTERNAL_ERROR, NULL);
        return cpp_type_size<T>::size(s_allow_tag);
    }

    // Return the alignment of a component.
    static size_t alignment() {
        ecs_assert(s_id != 0, ECS_INTERNAL_ERROR, NULL);
        return cpp_type_size<T>::alignment(s_allow_tag);
    }

    // Was the component already registered.
    static bool registered() {
        return s_id != 0;
    }

    // This function is only used to test cross-translation unit features. No
    // code other than test cases should invoke this function.
    static void reset() {
        s_id = 0;
        s_type = NULL;
        s_name.clear();
    }

private:
    static entity_t s_id;
    static type_t s_type;
    static flecs::string s_name;
    static flecs::string s_symbol;
    static bool s_allow_tag;
};

// Global templated variables that hold component identifier and other info
template <typename T> entity_t      cpp_type_impl<T>::s_id( 0 );
template <typename T> type_t        cpp_type_impl<T>::s_type( nullptr );
template <typename T> flecs::string cpp_type_impl<T>::s_name;
template <typename T> bool          cpp_type_impl<T>::s_allow_tag( true );

// Front facing class for implicitly registering a component & obtaining
// static component data

// Regular type
template <typename T>
class cpp_type<T, if_not_t< is_pair<T>::value >>
    : public cpp_type_impl<base_type_t<T>> { };

// Pair type
template <typename T>
class cpp_type<T, if_t< is_pair<T>::value >>
{
public:
    // Override id method to return id of pair
    static id_t id(world_t *world = nullptr) {
        return ecs_pair(
            cpp_type< pair_relation_t<T> >::id(world),
            cpp_type< pair_object_t<T> >::id(world));
    }
};

} // namespace _

////////////////////////////////////////////////////////////////////////////////
//// Register a component with flecs
////////////////////////////////////////////////////////////////////////////////

/* Plain old datatype, no lifecycle actions are registered */
template <typename T>
flecs::entity pod_component(flecs::world& world, char *name = nullptr, bool allow_tag = true) {
    char *n = name;
    bool implicit_name = false;
    if (!n) {
        n = _::name_helper<T>::name();

        /* Keep track of whether name was explicitly set. If not, and the
         * component was already registered, just use the registered name.
         *
         * The registered name may differ from the typename as the registered
         * name includes the flecs scope. This can in theory be different from
         * the C++ namespace though it is good practice to keep them the same */
        implicit_name = true;
    }

    world_t *world_ptr = world.c_ptr();
    entity_t id = 0;

    if (_::cpp_type<T>::registered()) {
        /* Obtain component id. Because the component is already registered,
         * this operation does nothing besides returning the existing id */
        id = _::cpp_type<T>::id_explicit(world_ptr, name, allow_tag);

        /* If entity is not empty check if the name matches */
        if (ecs_get_type(world_ptr, id) != nullptr) {
            if (!implicit_name && id >= EcsFirstUserComponentId) {
                char *path = ecs_get_path_w_sep(
                    world_ptr, 0, id, 0, "::", nullptr);
                ecs_assert(!strcmp(path, n),
                    ECS_INCONSISTENT_NAME, name);
                ecs_os_free(path);
            }
        } else {
            /* Register name with entity, so that when the entity is created the
             * correct id will be resolved from the name. Only do this when the
             * entity is empty.*/
            ecs_add_path_w_sep(world_ptr, id, 0, n, "::", "::");
        }

        /* If a component was already registered with this id but with a
         * different size, the ecs_component_init function will fail. */

        /* We need to explicitly call ecs_component_init here again. Even though
         * the component was already registered, it may have been registered
         * with a different world. This ensures that the component is registered
         * with the same id for the current world.
         * If the component was registered already, nothing will change. */
        ecs_component_desc_t desc = {};
        desc.entity.entity = id;
        desc.size = _::cpp_type<T>::size();
        desc.alignment = _::cpp_type<T>::alignment();
        ecs_entity_t entity = ecs_component_init(world.c_ptr(), &desc);
        (void)entity;

        ecs_assert(entity == id, ECS_INTERNAL_ERROR, NULL);

        /* This functionality could have been put in id_explicit, but since
         * this code happens when a component is registered, and the entire API
         * calls id_explicit, this would add a lot of overhead to each call.
         * This is why when using multiple worlds, components should be
         * registered explicitly. */
    } else {
        /* If the component is not yet registered, ensure no other component
         * or entity has been registered with this name. Ensure component is
         * looked up from root. */
        ecs_entity_t prev_scope = ecs_set_scope(world_ptr, 0);
        ecs_entity_t entity = ecs_lookup_path_w_sep(world_ptr, 0, n,
            "::", "::", false);
        ecs_set_scope(world_ptr, prev_scope);

        /* If entity exists, compare symbol name to ensure that the component
         * we are trying to register under this name is the same */
        if (entity) {
            EcsName *name_comp = ecs_get_mut(world, entity, EcsName, NULL);
            ecs_assert(name_comp != NULL, ECS_INTERNAL_ERROR, NULL);
            ecs_assert(name_comp->symbol != NULL, ECS_INTERNAL_ERROR, NULL);

            char *symbol = _::symbol_helper<T>::symbol();
            ecs_assert(!strcmp(name_comp->symbol, symbol),
                ECS_NAME_IN_USE, n);
            ecs_os_free(symbol);

            (void)name_comp;

        /* If no entity is found, lookup symbol to verify if the component was
         * registered under a different name. */
        } else {
            char *symbol = _::symbol_helper<T>::symbol();
            entity = ecs_lookup_symbol(world_ptr, symbol);
            ecs_assert(entity == 0, ECS_INCONSISTENT_COMPONENT_ID, symbol);
            ecs_os_free(symbol);
        }

        /* Register id as usual */
        id = _::cpp_type<T>::id_explicit(world_ptr, name, allow_tag);
    }

    return world.entity(id);
}

/* Regular component with ctor, dtor copy and move actions */
template <typename T>
flecs::entity component(flecs::world& world, char *name = nullptr) {
    flecs::entity result = pod_component<T>(world, name);

    if (_::cpp_type<T>::size()) {
        _::register_lifecycle_actions<T>(world.c_ptr(), result.id());
    }

    return result;
}

ECS_DEPRECATED("API detects automatically whether type is trivial")
template <typename T>
flecs::entity relocatable_component(flecs::world& world, char *name = nullptr) {
    flecs::entity result = pod_component<T>(world, name);

    _::register_lifecycle_actions<T>(world.c_ptr(), result.id());

    return result;
}

template <typename T>
flecs::entity_t type_id() {
    return _::cpp_type<T>::id();
}

} // namespace flecs

////////////////////////////////////////////////////////////////////////////////
//// Utility class to invoke a system each
////////////////////////////////////////////////////////////////////////////////

namespace flecs
{

namespace _
{


// Utility to convert template argument pack to array of term ptrs
struct term_ptr {
    void *ptr;
    bool is_ref;
};

template <typename ... Components>
class term_ptrs {
public:
    using array = flecs::array<_::term_ptr, sizeof...(Components)>;

    void populate(ecs_iter_t *iter) {
        populate(iter, 0, static_cast<
            remove_reference_t<
                remove_pointer_t<Components>>
                    *>(nullptr)...);
    }

    bool populate_w_refs(ecs_iter_t *iter) {
        if (iter->table->references) {
            populate_w_refs(iter, 0, static_cast<
                remove_reference_t<
                    remove_pointer_t<Components>>
                        *>(nullptr)...);
            return true;
        } else {
            this->populate(iter);
            return false;
        }
    }

    array m_terms;

private:
    /* Populate terms array without checking for references */
    void populate(ecs_iter_t*, size_t) { }

    template <typename T, typename... Targs>
    void populate(ecs_iter_t *iter, size_t index, T, Targs... comps) {
        int32_t term = static_cast<int32_t>(index + 1);
        void *ptr = ecs_term_w_size(iter, sizeof(actual_type_t<remove_pointer_t<T>>), term);
        m_terms[index].ptr = ptr;
        populate(iter, index + 1, comps ...);
    }

    /* Populate terms array, check for references */
    void populate_w_refs(ecs_iter_t*, size_t) { }

    template <typename T, typename... Targs>
    void populate_w_refs(ecs_iter_t *iter, size_t index, T, Targs... comps) {
        int32_t term = static_cast<int32_t>(index + 1);
        void *ptr = ecs_term_w_size(iter, sizeof(actual_type_t<remove_pointer_t<T>>), term);
        m_terms[index].ptr = ptr;
        m_terms[index].is_ref = !ecs_term_is_owned(iter, term) && ptr != nullptr;
        populate_w_refs(iter, index + 1, comps ...);
    }
};

class invoker { };

// Template that figures out from the template parameters of a query/system
// how to pass the value to the each callback
template <typename T, typename = int>
struct each_column { };

// Base class
struct each_column_base {
    each_column_base(_::term_ptr& term, size_t row)
        : m_term(term), m_row(row) { }

protected:
    _::term_ptr& m_term;
    size_t m_row;
};

// If type is not a pointer, return a reference to the type (default case)
template <typename T>
struct each_column<T, if_t< !is_pointer<T>::value && is_actual<T>::value > >
    : public each_column_base
{
    each_column(_::term_ptr& term, size_t row)
        : each_column_base(term, row) { }

    T& get_row() {
        return static_cast<T*>(this->m_term.ptr)[this->m_row];
    }
};

// If argument type is not the same as actual component type, return by value.
// This requires that the actual type can be converted to the type.
// A typical scenario where this happens is when using flecs::pair types.
template <typename T>
struct each_column<T, if_t< !is_pointer<T>::value && !is_actual<T>::value> >
    : public each_column_base
{
    each_column(_::term_ptr& term, size_t row)
        : each_column_base(term, row) { }

    T get_row() {
        return static_cast<actual_type_t<T>*>(this->m_term.ptr)[this->m_row];
    }
};

// If type is a pointer (indicating an optional value) return the type as is
template <typename T>
struct each_column<T, if_t< is_pointer<T>::value > >
    : public each_column_base
{
    each_column(_::term_ptr& term, size_t row)
        : each_column_base(term, row) { }

    T get_row() {
        if (this->m_term.ptr) {
            return &static_cast<actual_type_t<T>>(this->m_term.ptr)[this->m_row];
        } else {
            // optional argument doesn't hava a value
            return nullptr;
        }
    }
};

// If the query contains component references to other entities, check if the
// current argument is one.
template <typename T, typename = int>
struct each_ref_column : public each_column<T> {
    each_ref_column(_::term_ptr& term, size_t row)
        : each_column<T>(term, row) {

        if (term.is_ref) {
            // If this is a reference, set the row to 0 as a ref always is a
            // single value, not an array. This prevents the application from
            // having to do an if-check on whether the column is owned.
            //
            // This check only happens when the current table being iterated
            // over caused the query to match a reference. The check is
            // performed once per iterated table.
            this->m_row = 0;
        }
    }
};

template <typename Func, typename ... Components>
class each_invoker : public invoker {
public:
    // If the number of arguments in the function signature is one more than the
    // number of components in the query, an extra entity arg is required.
    static constexpr bool PassEntity =
        sizeof...(Components) == (arity<Func>::value - 1);

    static_assert(arity<Func>::value > 0,
        "each() must have at least one argument");

    using Terms = typename term_ptrs<Components ...>::array;

    explicit each_invoker(Func&& func) noexcept
        : m_func(std::move(func)) { }

    explicit each_invoker(Func& func) noexcept
        : m_func(func) { }

    // Invoke object directly. This operation is useful when the calling
    // function has just constructed the invoker, such as what happens when
    // iterating a query.
    void invoke(ecs_iter_t *iter) {
        term_ptrs<Components...> terms;

        if (terms.populate_w_refs(iter)) {
            invoke_callback< each_ref_column >(iter, m_func, 0, terms.m_terms);
        } else {
            invoke_callback< each_column >(iter, m_func, 0, terms.m_terms);
        }
    }

    // Static function that can be used as callback for systems/triggers
    static void run(ecs_iter_t *iter) {
        auto self = static_cast<each_invoker*>(iter->binding_ctx);
        ecs_assert(self != nullptr, ECS_INTERNAL_ERROR, NULL);
        self->invoke(iter);
    }

private:
    // Number of function arguments is one more than number of components, pass
    // entity as argument.
    template <template<typename X, typename = int> class ColumnType,
        typename... Args, if_t<
            sizeof...(Components) == sizeof...(Args) && PassEntity> = 0>
    static void invoke_callback(
        ecs_iter_t *iter, Func& func, size_t, Terms&, Args... comps)
    {
#ifndef NDEBUG
        ecs_table_t *table = nullptr;
        if (iter->table) {
            table = iter->table->table;
            if (table) {
                ecs_table_lock(iter->world, table);
            }
        }
#endif

        flecs::iter it(iter);
        for (auto row : it) {
            func(it.entity(row),
                (ColumnType< remove_reference_t<Components> >(comps, row)
                    .get_row())...);
        }

#ifndef NDEBUG
        if (table) {
            ecs_table_unlock(iter->world, table);
        }
#endif
    }

    // Number of function arguments is equal to number of components, no entity
    template <template<typename X, typename = int> class ColumnType,
        typename... Args, if_t<
            sizeof...(Components) == sizeof...(Args) && !PassEntity> = 0>
    static void invoke_callback(
        ecs_iter_t *iter, Func& func, size_t, Terms&, Args... comps)
    {
        flecs::iter it(iter);
        for (auto row : it) {
            func( (ColumnType< remove_reference_t<Components> >(comps, row)
                .get_row())...);
        }
    }

    template <template<typename X, typename = int> class ColumnType,
        typename... Args, if_t< sizeof...(Components) != sizeof...(Args) > = 0>
    static void invoke_callback(ecs_iter_t *iter, Func& func,
        size_t index, Terms& columns, Args... comps)
    {
        invoke_callback<ColumnType>(
            iter, func, index + 1, columns, comps..., columns[index]);
    }

    Func m_func;
};


////////////////////////////////////////////////////////////////////////////////
//// Utility class to invoke a system iterate action
////////////////////////////////////////////////////////////////////////////////

template <typename Func, typename ... Components>
class iter_invoker : public invoker {
    static constexpr bool IterOnly = arity<Func>::value == 1;

    using Terms = typename term_ptrs<Components ...>::array;

public:
    explicit iter_invoker(Func&& func) noexcept
        : m_func(std::move(func)) { }

    explicit iter_invoker(Func& func) noexcept
        : m_func(func) { }

    // Invoke object directly. This operation is useful when the calling
    // function has just constructed the invoker, such as what happens when
    // iterating a query.
    void invoke(ecs_iter_t *iter) {
        term_ptrs<Components...> terms;
        terms.populate(iter);
        invoke_callback(iter, m_func, 0, terms.m_terms);
    }

    // Static function that can be used as callback for systems/triggers
    static void run(ecs_iter_t *iter) {
        auto self = static_cast<iter_invoker*>(iter->binding_ctx);
        ecs_assert(self != nullptr, ECS_INTERNAL_ERROR, NULL);
        self->invoke(iter);
    }

private:
    template <typename... Args, if_t<!sizeof...(Args) && IterOnly> = 0>
    static void invoke_callback(ecs_iter_t *iter, Func& func,
        size_t, Terms&, Args...)
    {
        flecs::iter it(iter);
        func(it);
    }

    template <typename... Targs, if_t<!IterOnly &&
        (sizeof...(Targs) == sizeof...(Components))> = 0>
    static void invoke_callback(ecs_iter_t *iter, Func& func, size_t,
        Terms&, Targs... comps)
    {
        flecs::iter it(iter);

#ifndef NDEBUG
        ecs_table_t *table = nullptr;
        if (iter->table) {
            table = iter->table->table;
            if (table) {
                ecs_table_lock(iter->world, table);
            }
        }
#endif

        func(it, ( static_cast<
            remove_reference_t<
                remove_pointer_t<
                    actual_type_t<Components> > >* >
                        (comps.ptr))...);

#ifndef NDEBUG
        if (table) {
            ecs_table_unlock(iter->world, table);
        }
#endif
    }

    template <typename... Targs, if_t<!IterOnly &&
        (sizeof...(Targs) != sizeof...(Components)) > = 0>
    static void invoke_callback(ecs_iter_t *iter, Func& func,
        size_t index, Terms& columns, Targs... comps)
    {
        invoke_callback(iter, func, index + 1, columns, comps...,
            columns[index]);
    }

    Func m_func;
};


////////////////////////////////////////////////////////////////////////////////
//// Utility class to invoke a system action (deprecated)
////////////////////////////////////////////////////////////////////////////////

template <typename Func, typename ... Components>
class action_invoker : public invoker {
    using Terms = typename term_ptrs<Components ...>::array;
public:
    explicit action_invoker(Func&& func) noexcept : m_func(std::move(func)) { }
    explicit action_invoker(Func& func) noexcept : m_func(func) { }

    // Invoke object directly. This operation is useful when the calling
    // function has just constructed the invoker, such as what happens when
    // iterating a query.
    void invoke(ecs_iter_t *iter) {
        term_ptrs<Components...> terms;
        terms.populate_w_refs(iter);
        invoke_callback(iter, m_func, 0, terms.m_terms);
    }

    // Static function that can be used as callback for systems/triggers
    static void run(ecs_iter_t *iter) {
        auto self = static_cast<action_invoker*>(iter->binding_ctx);
        ecs_assert(self != nullptr, ECS_INTERNAL_ERROR, NULL);
        self->invoke(iter);
    }

private:
    template <typename... Targs,
        if_t< sizeof...(Targs) == sizeof...(Components) > = 0>
    static void invoke_callback(
        ecs_iter_t *iter, Func& func, size_t, Terms&, Targs... comps)
    {
        flecs::iter iter_wrapper(iter);
        func(iter_wrapper, (column<
        remove_reference_t< remove_pointer_t<Components> > >(
            static_cast< remove_reference_t<
                remove_pointer_t<Components> > *>
                    (comps.ptr), iter->count, comps.is_ref))...);
    }

    template <typename... Targs,
        if_t<sizeof...(Targs) != sizeof...(Components)> = 0>
    static void invoke_callback(ecs_iter_t *iter, Func& func,
        size_t index, Terms& columns, Targs... comps)
    {
        invoke_callback(iter, func, index + 1, columns, comps...,
            columns[index]);
    }

    Func m_func;
};

////////////////////////////////////////////////////////////////////////////////
//// Utility to invoke callback on entity if it has components in signature
////////////////////////////////////////////////////////////////////////////////

template<typename ... Args>
class entity_with_invoker_impl;

template<typename ... Args>
class entity_with_invoker_impl<arg_list<Args ...>> {
public:
    using ColumnArray = flecs::array<int32_t, sizeof...(Args)>;
    using ConstPtrArray = flecs::array<void*, sizeof...(Args)>;
    using PtrArray = flecs::array<void*, sizeof...(Args)>;
    using DummyArray = flecs::array<int, sizeof...(Args)>;
    using IdArray = flecs::array<id_t, sizeof...(Args)>;

    template <typename ArrayType>
    static bool get_ptrs(world& w, ecs_record_t *r, ecs_table_t *table,
        ArrayType& ptrs)
    {
        ecs_assert(table != NULL, ECS_INTERNAL_ERROR, NULL);

        ecs_type_t type = ecs_table_get_type(table);
        if (!type) {
            return false;
        }

        /* Get column indices for components */
        ColumnArray columns ({
            ecs_type_index_of(type, w.id<Args>())...
        });

        /* Get pointers for columns for entity */
        size_t i = 0;
        for (int32_t column : columns) {
            if (column == -1) {
                return false;
            }

            ptrs[i ++] = ecs_record_get_column(r, column, 0);
        }

        return true;
    }

    template <typename ArrayType>
    static bool get_mut_ptrs(world& w, ecs_entity_t e, ArrayType& ptrs) {
        world_t *world = w.c_ptr();

        /* Get pointers w/get_mut */
        size_t i = 0;
        DummyArray dummy ({
            (ptrs[i ++] = ecs_get_mut_w_id(world, e, w.id<Args>(), NULL), 0)...
        });

        return true;
    }

    template <typename Func>
    static bool invoke_get(world_t *world, entity_t id, Func& func) {
        flecs::world w(world);

        ecs_record_t *r = ecs_record_find(world, id);
        if (!r) {
            return false;
        }

        ecs_table_t *table = r->table;
        if (!table) {
            return false;
        }

        ConstPtrArray ptrs;
        if (!get_ptrs(w, r, table, ptrs)) {
            return false;
        }

        invoke_callback(func, 0, ptrs);

        return true;
    }

    // Utility for storing id in array in pack expansion
    static size_t store_added(IdArray& added, size_t elem, ecs_table_t *prev,
        ecs_table_t *next, id_t id)
    {
        // Array should only contain ids for components that are actually added,
        // so check if the prev and next tables are different.
        if (prev != next) {
            added[elem] = id;
            elem ++;
        }
        return elem;
    }

    template <typename Func>
    static bool invoke_get_mut(world_t *world, entity_t id, Func& func) {
        flecs::world w(world);

        PtrArray ptrs;

        // When not deferred take the fast path.
        if (!w.is_deferred()) {
            // Bit of low level code so we only do at most one table move & one
            // entity lookup for the entire operation.

            // Find table for entity
            ecs_record_t *r = ecs_record_find(world, id);
            ecs_table_t *table = NULL;
            if (r) {
                table = r->table;
            }

            // Find destination table that has all components
            ecs_table_t *prev = table, *next;
            size_t elem = 0;
            IdArray added;

            // Iterate components, only store added component ids in added array
            DummyArray dummy_before ({ (
                next = ecs_table_add_id(world, prev, w.id<Args>()),
                elem = store_added(added, elem, prev, next, w.id<Args>()),
                prev = next, 0
            )... });
            (void)dummy_before;

            // If table is different, move entity straight to it
            if (table != next) {
                ecs_entities_t ids;
                ids.array = added.ptr();
                ids.count = static_cast<ecs_size_t>(elem);
                ecs_commit(world, id, r, next, &ids, NULL);
                table = next;
            }

            if (!get_ptrs(w, r, table, ptrs)) {
                ecs_abort(ECS_INTERNAL_ERROR, NULL);
            }

        // When deferred, obtain pointers with regular get_mut
        } else {
            get_mut_ptrs(w, id, ptrs);
        }

        invoke_callback(func, 0, ptrs);

        // Call modified on each component
        DummyArray dummy_after ({
            ( ecs_modified_w_id(world, id, w.id<Args>()), 0)...
        });
        (void)dummy_after;

        return true;
    }

private:
    template <typename Func, typename ArrayType, typename ... TArgs,
        if_t<sizeof...(TArgs) == sizeof...(Args)> = 0>
    static void invoke_callback(
        Func& f, size_t, ArrayType&, TArgs&& ... comps)
    {
        f(*static_cast<typename base_arg_type<Args>::type*>(comps)...);
    }

    template <typename Func, typename ArrayType, typename ... TArgs,
        if_t<sizeof...(TArgs) != sizeof...(Args)> = 0>
    static void invoke_callback(Func& f, size_t arg, ArrayType& ptrs,
        TArgs&& ... comps)
    {
        invoke_callback(f, arg + 1, ptrs, comps..., ptrs[arg]);
    }
};

template <typename Func, typename U = int>
class entity_with_invoker {
    static_assert(function_traits<Func>::value, "type is not callable");
};

template <typename Func>
class entity_with_invoker<Func, if_t< is_callable<Func>::value > >
    : public entity_with_invoker_impl< arg_list_t<Func> >
{
    static_assert(function_traits<Func>::arity > 0,
        "function must have at least one argument");
};

} // namespace _

} // namespace flecs

namespace flecs {

template<typename Base>
class term_id_builder_i {
public:
    term_id_builder_i() : m_term_id(nullptr) { }

    virtual ~term_id_builder_i() { }

    template<typename T>
    Base& entity() {
        ecs_assert(m_term_id != NULL, ECS_INVALID_PARAMETER, NULL);
        m_term_id->entity = _::cpp_type<T>::id(world());
        return *this;
    }

    Base& entity(flecs::id_t id) {
        ecs_assert(m_term_id != NULL, ECS_INVALID_PARAMETER, NULL);
        m_term_id->entity = id;
        return *this;
    }

    Base& name(char *name) {
        ecs_assert(m_term_id != NULL, ECS_INVALID_PARAMETER, NULL);
        // cast is safe, when the value is actually used to construct a
        // query, it will be duplicated.
        m_term_id->name = const_cast<char*>(name);
        return *this;
    }

    Base& var(flecs::var_kind_t var = flecs::VarIsVariable) {
        m_term_id->var = static_cast<ecs_var_kind_t>(var);
        return *this;
    }

    Base& var(char *name) {
        ecs_assert(m_term_id != NULL, ECS_INVALID_PARAMETER, NULL);
        // cast is safe, when the value is actually used to construct a
        // query, it will be duplicated.
        m_term_id->name = const_cast<char*>(name);
        return var(); // Default to VarIsVariable
    }

    Base& set(uint8_t mask, flecs::id_t relation = flecs::IsA)
    {
        ecs_assert(m_term_id != NULL, ECS_INVALID_PARAMETER, NULL);
        m_term_id->set.mask = mask;
        m_term_id->set.relation = relation;
        return *this;
    }

    Base& superset(flecs::id_t relation = flecs::IsA, uint8_t mask = 0)
    {
        ecs_assert(!(mask & flecs::SubSet), ECS_INVALID_PARAMETER, NULL);
        return set(flecs::SuperSet | mask, relation);
    }

    Base& subset(flecs::id_t relation = flecs::IsA, uint8_t mask = 0)
    {
        ecs_assert(!(mask & flecs::SuperSet), ECS_INVALID_PARAMETER, NULL);
        return set(flecs::SubSet | mask, relation);
    }

    Base& min_depth(int32_t min_depth) {
        m_term_id->set.min_depth = min_depth;
        return *this;
    }

    Base& max_depth(int32_t max_depth) {
        m_term_id->set.max_depth = max_depth;
        return *this;
    }

    ecs_term_id_t *m_term_id;

protected:
    virtual flecs::world_t* world() = 0;

private:
    operator Base&() {
        return *static_cast<Base*>(this);
    }
};

template<typename Base>
class term_builder_i : public term_id_builder_i<Base> {
public:
    term_builder_i() : m_term(nullptr) { }

    term_builder_i(ecs_term_t *term_ptr) {
        set_term(term_ptr);
    }

    template<typename T>
    Base& id() {
        ecs_assert(m_term != nullptr, ECS_INVALID_PARAMETER, NULL);
        m_term->id = _::cpp_type<T>::id(world());
        return *this;
    }

    template<typename R, typename O>
    Base& id() {
        ecs_assert(m_term != nullptr, ECS_INVALID_PARAMETER, NULL);
        m_term->id = ecs_pair(
            _::cpp_type<R>::id(world()),
            _::cpp_type<O>::id(world()));
        return *this;
    }

    template<typename R>
    Base& id(id_t o) {
        ecs_assert(m_term != nullptr, ECS_INVALID_PARAMETER, NULL);
        m_term->id = ecs_pair(
            _::cpp_type<R>::id(world()), o);
        return *this;
    }

    Base& id(id_t id) {
        ecs_assert(m_term != nullptr, ECS_INVALID_PARAMETER, NULL);
        m_term->id = id;
        return *this;
    }

    Base& id(flecs::type& type);

    Base& id(id_t r, id_t o) {
        ecs_assert(m_term != nullptr, ECS_INVALID_PARAMETER, NULL);
        m_term->id = ecs_pair(r, o);
        return *this;
    }

    Base& expr(char *expr) {
        ecs_assert(m_term != nullptr, ECS_INVALID_PARAMETER, NULL);
        char *ptr;
        if ((ptr = ecs_parse_term(world(), nullptr, expr, expr, m_term)) == nullptr) {
            ecs_abort(ECS_INVALID_PARAMETER, NULL);
        }

        // Should not have more than one term
        ecs_assert(ptr[0] == 0, ECS_INVALID_PARAMETER, NULL);
        return *this;
    }

    Base& predicate() {
        ecs_assert(m_term != nullptr, ECS_INVALID_PARAMETER, NULL);
        this->m_term_id = &m_term->pred;
        return *this;
    }

    Base& subject() {
        ecs_assert(m_term != nullptr, ECS_INVALID_PARAMETER, NULL);
        this->m_term_id = &m_term->args[0];
        return *this;
    }

    Base& object() {
        ecs_assert(m_term != nullptr, ECS_INVALID_PARAMETER, NULL);
        this->m_term_id = &m_term->args[1];
        return *this;
    }

    Base& subject(entity_t entity) {
        this->subject();
        this->m_term_id->entity = entity;
        return *this;
    }

    Base& object(entity_t entity) {
        this->object();
        this->m_term_id->entity = entity;
        return *this;
    }

    template<typename T>
    Base& subject() {
        this->subject();
        this->m_term_id->entity = _::cpp_type<T>::id(world());
        return *this;
    }

    template<typename T>
    Base& object() {
        this->object();
        this->m_term_id->entity = _::cpp_type<T>::id(world());
        return *this;
    }

    Base& role(id_t role) {
        ecs_assert(m_term != nullptr, ECS_INVALID_PARAMETER, NULL);
        m_term->role = role;
        return *this;
    }

    Base& inout(flecs::inout_kind_t inout) {
        ecs_assert(m_term != nullptr, ECS_INVALID_PARAMETER, NULL);
        m_term->inout = static_cast<ecs_inout_kind_t>(inout);
        return *this;
    }

    Base& oper(flecs::oper_kind_t oper) {
        ecs_assert(m_term != nullptr, ECS_INVALID_PARAMETER, NULL);
        m_term->oper = static_cast<ecs_oper_kind_t>(oper);
        return *this;
    }

    Base& singleton() {
        ecs_assert(m_term != nullptr, ECS_INVALID_PARAMETER, NULL);
        ecs_assert(m_term->id || m_term->pred.entity, ECS_INVALID_PARAMETER, NULL);

        flecs::id_t pred = m_term->id;
        if (!pred) {
            pred = m_term->pred.entity;
        }

        ecs_assert(pred != 0, ECS_INVALID_PARAMETER, NULL);

        m_term->args[0].entity = pred;

        return *this;
    }

    flecs::id id() {
        return flecs::id(world(), m_term->id);
    }

    flecs::entity get_subject() {
        return flecs::entity(world(), m_term->args[0].entity);
    }

    flecs::entity get_object() {
        return flecs::entity(world(), m_term->args[1].entity);
    }

    flecs::inout_kind_t inout() {
        return static_cast<flecs::inout_kind_t>(m_term->inout);
    }

    flecs::oper_kind_t oper() {
        return static_cast<flecs::oper_kind_t>(m_term->oper);
    }

    ecs_term_t *m_term;

protected:
    virtual flecs::world_t* world() = 0;

    void set_term(ecs_term_t *term) {
        m_term = term;
        if (term) {
            this->m_term_id = &m_term->args[0]; // default to subject
        } else {
            this->m_term_id = nullptr;
        }
    }

private:
    operator Base&() {
        return *static_cast<Base*>(this);
    }
};

// Class that describes a term
class term final : public term_builder_i<term> {
public:
    term(flecs::world_t *world_ptr)
        : term_builder_i<term>(&value)
        , value({})
        , m_world(world_ptr) { value.move = true; }

    term(flecs::world_t *world_ptr, id_t id)
        : term_builder_i<term>(&value)
        , value({})
        , m_world(world_ptr) {
            value.move = true;
            this->id(id);
        }

    term(flecs::world_t *world_ptr, ecs_term_t t)
        : term_builder_i<term>(&value)
        , value({})
        , m_world(world_ptr) {
            value = t;
            value.move = false;
            this->set_term(&value);
        }

    term(flecs::world_t *world_ptr, id_t r, id_t o)
        : term_builder_i<term>(&value)
        , value({})
        , m_world(world_ptr) {
            value.move = true;
            this->id(r, o);
        }

    term(term& obj) : term_builder_i<term>(&value) {
        m_world = obj.m_world;
        value = ecs_term_copy(&obj.value);
        this->set_term(&value);
    }

    term(term&& obj) : term_builder_i<term>(&value) {
        m_world = obj.m_world;
        value = ecs_term_move(&obj.value);
        obj.reset();
        this->set_term(&value);
    }

    term& operator=(term& obj) {
        ecs_assert(m_world == obj.m_world, ECS_INVALID_PARAMETER, NULL);
        ecs_term_fini(&value);
        value = ecs_term_copy(&obj.value);
        this->set_term(&value);
        return *this;
    }

    term& operator=(term&& obj) {
        ecs_assert(m_world == obj.m_world, ECS_INVALID_PARAMETER, NULL);
        ecs_term_fini(&value);
        value = obj.value;
        this->set_term(&value);
        obj.reset();
        return *this;
    }

    ~term() {
        ecs_term_fini(&value);
    }

    void reset() {
        value = {};
        this->set_term(nullptr);
    }

    int finalize() {
        return ecs_term_finalize(m_world, nullptr, nullptr, &value);
    }

    bool is_set() {
        return ecs_term_is_set(&value);
    }

    bool is_trivial() {
        return ecs_term_is_trivial(&value);
    }

    ecs_term_t move() { /* explicit move to ecs_term_t */
        return ecs_term_move(&value);
    }

    ecs_term_t value;

protected:
    flecs::world_t* world() override { return m_world; }

private:
    flecs::world_t *m_world;
};

// Filter builder interface
template<typename Base, typename ... Components>
class filter_builder_i : public term_builder_i<Base> {
public:
    filter_builder_i(ecs_filter_desc_t *desc, int32_t term_index = 0)
        : m_term_index(term_index)
        , m_desc(desc) { }

    Base& expr(char *expr) {
        m_desc->expr = expr;
        return *this;
    }

    Base& substitute_default(bool value = true) {
        m_desc->substitute_default = value;
        return *this;
    }

    Base& term() {
        ecs_assert(m_term_index < ECS_FILTER_DESC_TERM_ARRAY_MAX,
            ECS_INVALID_PARAMETER, NULL);
        this->set_term(&m_desc->terms[m_term_index]);
        m_term_index ++;
        return *this;
    }

    Base& arg(int32_t term_index) {
        ecs_assert(term_index > 0, ECS_INVALID_PARAMETER, NULL);
        m_term_index = term_index - 1;
        this->term();
        ecs_assert(ecs_term_is_set(this->m_term), ECS_INVALID_PARAMETER, NULL);
        return *this;
    }

    template<typename T>
    Base& term() {
        this->term();
        *this->m_term = flecs::term(world()).id<T>().move();
        return *this;
    }

    Base& term(id_t id) {
        this->term();
        *this->m_term = flecs::term(world()).id(id).move();
        return *this;
    }

    template<typename R, typename O>
    Base& term() {
        this->term();
        *this->m_term = flecs::term(world()).id<R, O>().move();
        return *this;
    }

    template<typename R>
    Base& term(id_t o) {
        this->term();
        *this->m_term = flecs::term(world()).id<R>(o).move();
        return *this;
    }

    Base& term(id_t r, id_t o) {
        this->term();
        *this->m_term = flecs::term(world()).id(r, o).move();
        return *this;
    }

    Base& term(flecs::type& type) {
        this->term();
        *this->m_term = flecs::term(world()).id(type).move();
        return *this;
    }

    Base& term(char *expr) {
        this->term();
        *this->m_term = flecs::term(world()).expr(expr).move();
        return *this;
    }

    Base& term(flecs::term& term) {
        this->term();
        *this->m_term = term.move();
        return *this;
    }

    Base& term(flecs::term&& term) {
        this->term();
        *this->m_term = term.move();
        return *this;
    }

    void populate_filter_from_pack() {
        flecs::array<flecs::id_t, sizeof...(Components)> ids ({
            (_::cpp_type<Components>::id(world()))...
        });

        flecs::array<flecs::inout_kind_t, sizeof...(Components)> inout_kinds ({
            (type_to_inout<Components>())...
        });

        flecs::array<flecs::oper_kind_t, sizeof...(Components)> oper_kinds ({
            (type_to_oper<Components>())...
        });

        size_t i = 0;
        for (auto id : ids) {
            this->term(id).inout(inout_kinds[i]).oper(oper_kinds[i]);
            i ++;
        }
    }

protected:
    virtual flecs::world_t* world() = 0;
    int32_t m_term_index;

private:
    operator Base&() {
        return *static_cast<Base*>(this);
    }

    template <typename T, if_t< is_const<T>::value > = 0>
    constexpr flecs::inout_kind_t type_to_inout() {
        return flecs::In;
    }

    template <typename T, if_t< is_reference<T>::value > = 0>
    constexpr flecs::inout_kind_t type_to_inout() {
        return flecs::Out;
    }

    template <typename T, if_not_t<
        is_const<T>::value || is_reference<T>::value > = 0>
    constexpr flecs::inout_kind_t type_to_inout() {
        return flecs::InOutDefault;
    }

    template <typename T, if_t< is_pointer<T>::value > = 0>
    constexpr flecs::oper_kind_t type_to_oper() {
        return flecs::Optional;
    }

    template <typename T, if_not_t< is_pointer<T>::value > = 0>
    constexpr flecs::oper_kind_t type_to_oper() {
        return flecs::And;
    }

    ecs_filter_desc_t *m_desc;
};

// Query builder interface
template<typename Base, typename ... Components>
class query_builder_i : public filter_builder_i<Base, Components ...> {
    using BaseClass = filter_builder_i<Base, Components ...>;
public:
    query_builder_i()
        : BaseClass(nullptr)
        , m_desc(nullptr) { }

    query_builder_i(ecs_query_desc_t *desc, int32_t term_index = 0)
        : BaseClass(&desc->filter, term_index)
        , m_desc(desc) { }

    /* Sort the output of a query.
     * This enables sorting of entities across matched tables. As a result of this
     * operation, the order of entities in the matched tables may be changed.
     * Resorting happens when a query iterator is obtained, and only if the table
     * data has changed.
     *
     * If multiple queries that match the same (sub)set of tables specify different
     * sorting functions, resorting is likely to happen every time an iterator is
     * obtained, which can significantly slow down iterations.
     *
     * The sorting function will be applied to the specified component. Resorting
     * only happens if that component has changed, or when the entity order in the
     * table has changed. If no component is provided, resorting only happens when
     * the entity order changes.
     *
     * @tparam T The component used to sort.
     * @param compare The compare function used to sort the components.
     */
    template <typename T>
    Base& order_by(int(*compare)(flecs::entity_t, T*, flecs::entity_t, T*)) {
        ecs_compare_action_t cmp = reinterpret_cast<ecs_compare_action_t>(compare);
        return this->order_by(_::cpp_type<T>::id(world()), cmp);
    }

    /* Sort the output of a query.
     * Same as order_by<T>, but with component identifier.
     *
     * @param component The component used to sort.
     * @param compare The compare function used to sort the components.
     */
    Base& order_by(flecs::entity_t component, int(*compare)(flecs::entity_t, void*, flecs::entity_t, void*)) {
        m_desc->order_by = reinterpret_cast<ecs_compare_action_t>(compare);
        m_desc->order_by_id = component;
        return *this;
    }

    /* Group and sort matched tables.
     * Similar yo ecs_query_order_by, but instead of sorting individual entities, this
     * operation only sorts matched tables. This can be useful of a query needs to
     * enforce a certain iteration order upon the tables it is iterating, for
     * example by giving a certain component or tag a higher priority.
     *
     * The sorting function assigns a "rank" to each type, which is then used to
     * sort the tables. Tables with higher ranks will appear later in the iteration.
     *
     * Resorting happens when a query iterator is obtained, and only if the set of
     * matched tables for a query has changed. If table sorting is enabled together
     * with entity sorting, table sorting takes precedence, and entities will be
     * sorted within each set of tables that are assigned the same rank.
     *
     * @tparam T The component used to determine the group rank.
     * @param rank The rank action.
     */
    template <typename T>
    Base& group_by(int(*rank)(flecs::world_t*, flecs::entity_t, flecs::type_t type)) {
        ecs_rank_type_action_t rnk = reinterpret_cast<ecs_rank_type_action_t>(rank);
        return this->group_by(_::cpp_type<T>::id(this->m_world), rnk);
    }

    /* Group and sort matched tables.
     * Same as group_by<T>, but with component identifier.
     *
     * @param component The component used to determine the group rank.
     * @param rank The rank action.
     */
    Base& group_by(flecs::entity_t component, int(*rank)(flecs::world_t*, flecs::entity_t, flecs::type_t type)) {
        m_desc->group_by = reinterpret_cast<ecs_rank_type_action_t>(rank);
        m_desc->group_by_id = component;
        return *this;
    }

    /* Specify parent query (creates subquery) */
    Base& parent(query_base& parent);

protected:
    virtual flecs::world_t* world() = 0;

private:
    operator Base&() {
        return *static_cast<Base*>(this);
    }

    ecs_query_desc_t *m_desc;
};

// System builder interface
template<typename Base, typename ... Components>
class system_builder_i : public query_builder_i<Base, Components ...> {
    using BaseClass = query_builder_i<Base, Components ...>;
public:
    system_builder_i()
        : BaseClass(nullptr)
        , m_desc(nullptr)
        , m_add_count(0) { }

    system_builder_i(ecs_system_desc_t *desc)
        : BaseClass(&desc->query)
        , m_desc(desc)
        , m_add_count(0) { }

    /* Specify string-based signature. */
    Base& signature(char *signature) {
        m_desc->query.filter.expr = signature;
        return *this;
    }

    /* Specify when the system should be ran.
     * Use this function to set in which phase the system should run or whether
     * the system is reactive. Valid values for reactive systems are:
     *
     * flecs::OnAdd
     * flecs::OnRemove
     * flecs::OnSet
     * flecs::UnSet
     *
     * @param kind The kind that specifies when the system should be ran.
     */
    Base& kind(entity_t kind) {
        m_desc->entity.add[0] = kind;
        return *this;
    }

    /* Set system interval.
     * This operation will cause the system to be ran at the specified interval.
     *
     * The timer is synchronous, and is incremented each frame by delta_time.
     *
     * @param interval The interval value.
     */
    Base& interval(FLECS_FLOAT interval) {
        m_desc->interval = interval;
        return *this;
    }

    /* Set system rate.
     * This operation will cause the system to be ran at a multiple of the
     * provided tick source. The tick source may be any entity, including
     * another system.
     *
     * @param tick_source The tick source.
     * @param rate The multiple at which to run the system.
     */
    Base& rate(entity_t tick_source, int32_t rate) {
        m_desc->rate = rate;
        m_desc->tick_source = tick_source;
        return *this;
    }

    /* Set system rate.
     * This operation will cause the system to be ran at a multiple of the
     * frame tick frequency. If a tick source was provided, this just updates
     * the rate of the system.
     *
     * @param rate The multiple at which to run the system.
     */
    Base& rate(int32_t rate) {
        m_desc->rate = rate;
        return *this;
    }

    /* System is an on demand system */
    Base& on_demand() {
        m_desc->entity.add[m_add_count ++] = flecs::OnDemand;
        return *this;
    }

    /* System is a hidden system */
    Base& hidden() {
        m_desc->entity.add[m_add_count ++] = flecs::Hidden;
        return *this;
    }

    /* Set system context */
    Base& ctx(void *ptr) {
        m_desc->ctx = ptr;
        return *this;
    }

    ECS_DEPRECATED("use interval")
    Base& period(FLECS_FLOAT period) {
        return this->interval(period);
    }

    ECS_DEPRECATED("use ctx")
    Base& set_context(void *ptr) {
        ctx(ptr);
        return *this;
    }

protected:
    virtual flecs::world_t* world() = 0;

private:
    operator Base&() {
        return *static_cast<Base*>(this);
    }

    ecs_system_desc_t *m_desc;
    int32_t m_add_count;
};

// Observer builder interface
template<typename Base, typename ... Components>
class observer_builder_i : public filter_builder_i<Base, Components ...> {
    using BaseClass = filter_builder_i<Base, Components ...>;
public:
    observer_builder_i()
        : BaseClass(nullptr)
        , m_desc(nullptr)
        , m_event_count(0) { }

    observer_builder_i(ecs_observer_desc_t *desc)
        : BaseClass(&desc->filter)
        , m_desc(desc)
        , m_event_count(0) { }

    /* Specify when the system should be ran.
     * Use this function to set in which phase the system should run or whether
     * the system is reactive. Valid values for reactive systems are:
     *
     * flecs::OnAdd
     * flecs::OnRemove
     * flecs::OnSet
     * flecs::UnSet
     *
     * @param kind The kind that specifies when the system should be ran.
     */
    Base& event(entity_t kind) {
        m_desc->events[m_event_count ++] = kind;
        return *this;
    }

    /* Set system context */
    Base& ctx(void *ptr) {
        m_desc->ctx = ptr;
        return *this;
    }

protected:
    virtual flecs::world_t* world() = 0;

private:
    operator Base&() {
        return *static_cast<Base*>(this);
    }

    ecs_observer_desc_t *m_desc;
    int32_t m_event_count;
};

// Query builder
template<typename ... Components>
class query_builder_base
    : public query_builder_i<query_builder_base<Components...>, Components ...>
{
public:
    query_builder_base(flecs::world_t *world)
        : query_builder_i<query_builder_base<Components...>, Components ...>(&m_desc)
        , m_desc({})
        , m_world(world)
    {
        this->populate_filter_from_pack();
    }

    query_builder_base(query_builder_base& obj)
        : query_builder_i<query_builder_base<Components...>, Components ...>(&m_desc, obj.m_term_index)
    {
        m_world = obj.m_world;
        m_desc = obj.m_desc;
    }

    query_builder_base(query_builder_base&& obj)
        : query_builder_i<query_builder_base<Components...>, Components ...>(&m_desc, obj.m_term_index)
    {
        m_world = obj.m_world;
        m_desc = obj.m_desc;
    }

    operator query<Components ...>() const;

    operator ecs_query_t*() {
        return ecs_query_init(this->m_world, &this->m_desc);
    }

    query<Components ...> build() const;

    ecs_query_desc_t m_desc;

    flecs::world_t* world() override { return m_world; }

protected:
    flecs::world_t *m_world;
};

template<typename ... Components>
class query_builder final : public query_builder_base<Components...> {
public:
    query_builder(flecs::world_t *world)
        : query_builder_base<Components ...>(world) { }

    operator query<>() const;
};

template<typename ... Components>
class system_builder final
    : public system_builder_i<system_builder<Components ...>, Components ...>
{
    using Class = system_builder<Components ...>;
public:
    explicit system_builder(flecs::world_t* world, char *name = nullptr, char *expr = nullptr)
        : system_builder_i<Class, Components ...>(&m_desc)
        , m_desc({})
        , m_world(world)
        {
            m_desc.entity.name = name;
            m_desc.entity.sep = "::";
            m_desc.entity.add[0] = flecs::OnUpdate;
            m_desc.query.filter.expr = expr;
            this->populate_filter_from_pack();
        }

    // put using outside of action so we can still use it without it being
    // flagged as deprecated.
    template <typename Func>
    using action_invoker_t = typename _::iter_invoker<
        typename std::decay<Func>::type, Components...>;

    template <typename Func>
    ECS_DEPRECATED("use each or iter")
    system<Components...> action(Func&& func) const;

    /* Iter (or each) is mandatory and always the last thing that
     * is added in the fluent method chain. Create system signature from both
     * template parameters and anything provided by the signature method. */
    template <typename Func>
    system<Components...> iter(Func&& func) const;

    /* Each is similar to action, but accepts a function that operates on a
     * single entity */
    template <typename Func>
    system<Components...> each(Func&& func) const;

    ecs_system_desc_t m_desc;

protected:
    flecs::world_t* world() override { return m_world; }
    flecs::world_t *m_world;

private:
    template <typename Invoker, typename Func>
    entity_t build(Func&& func, bool is_each) {
        auto ctx = FLECS_NEW(Invoker)(std::forward<Func>(func));

        entity_t e, kind = m_desc.entity.add[0];
        bool is_trigger = kind == flecs::OnAdd || kind == flecs::OnRemove;

        if (is_trigger) {
            ecs_trigger_desc_t desc = {};
            ecs_term_t term = m_desc.query.filter.terms[0];
            if (ecs_term_is_set(&term)) {
                desc.term = term;
            } else {
                desc.expr = m_desc.query.filter.expr;
            }

            desc.entity.entity = m_desc.entity.entity;
            desc.events[0] = kind;
            desc.callback = Invoker::run;
            desc.ctx = m_desc.ctx;
            desc.binding_ctx = ctx;
            desc.binding_ctx_free = reinterpret_cast<
                ecs_ctx_free_t>(_::free_obj<Invoker>);

            e = ecs_trigger_init(m_world, &desc);
        } else {
            ecs_system_desc_t desc = m_desc;
            desc.callback = Invoker::run;
            desc.query.filter.substitute_default = is_each;
            desc.binding_ctx = ctx;
            desc.binding_ctx_free = reinterpret_cast<
                ecs_ctx_free_t>(_::free_obj<Invoker>);

            e = ecs_system_init(m_world, &desc);
        }

        return e;
    }
};

template<typename ... Components>
class observer_builder final
    : public observer_builder_i<observer_builder<Components ...>, Components ...>
{
    using Class = observer_builder<Components ...>;
public:
    explicit observer_builder(flecs::world_t* world, char *name = nullptr, char *expr = nullptr)
        : observer_builder_i<Class, Components ...>(&m_desc)
        , m_desc({})
        , m_world(world)
        {
            m_desc.entity.name = name;
            m_desc.entity.sep = "::";
            m_desc.entity.add[0] = flecs::OnUpdate;
            m_desc.filter.expr = expr;
            this->populate_filter_from_pack();
        }

    /* Iter (or each) is mandatory and always the last thing that
     * is added in the fluent method chain. Create system signature from both
     * template parameters and anything provided by the signature method. */
    template <typename Func>
    observer<Components...> iter(Func&& func) const;

    /* Each is similar to action, but accepts a function that operates on a
     * single entity */
    template <typename Func>
    observer<Components...> each(Func&& func) const;

    ecs_observer_desc_t m_desc;

protected:
    flecs::world_t* world() override { return m_world; }
    flecs::world_t *m_world;

private:
    template <typename Invoker, typename Func>
    entity_t build(Func&& func, bool is_each) {
        auto ctx = FLECS_NEW(Invoker)(std::forward<Func>(func));

        ecs_observer_desc_t desc = m_desc;
        desc.callback = Invoker::run;
        desc.filter.substitute_default = is_each;
        desc.binding_ctx = ctx;
        desc.binding_ctx_free = reinterpret_cast<
            ecs_ctx_free_t>(_::free_obj<Invoker>);

        return ecs_observer_init(m_world, &desc);
    }
};

}

#ifdef FLECS_DEPRECATED

namespace flecs
{

/* Deprecated functions */
template<typename Base>
class type_deprecated {
public:

    template <typename T, typename C>
    ECS_DEPRECATED("use add<Relation, Object>")
    type& add_trait() {
        static_cast<Base*>(this)->add(ecs_pair(
            _::cpp_type<T>::id(world()),
            _::cpp_type<C>::id(world())));
        return *base();
    }

    template <typename T>
    ECS_DEPRECATED("use add<Relation>(flecs::entity&)")
    type& add_trait(flecs::entity& c) {
        static_cast<Base*>(this)->add(ecs_pair(_::cpp_type<T>::id(world()), c.id()));
        return *base();
    }

    ECS_DEPRECATED("use add(flecs::entity&, flecs::entity&)")
    type& add_trait(flecs::entity& t, flecs::entity& c) {
        static_cast<Base*>(this)->add(ecs_pair(t.id(), c.id()));
        return *base();
    }

    template <typename C>
    ECS_DEPRECATED("use add_object<Object>(flecs::entity&)")
    type& add_trait_tag(flecs::entity& t) {
        static_cast<Base*>(this)->add(ecs_pair(t.id(), _::cpp_type<C>::id(world())));
        return *base();
    }

    ECS_DEPRECATED("use add(flecs::IsA, base)")
    type& add_instanceof(entity& e) {
        return static_cast<Base*>(this)->add(ECS_INSTANCEOF | e.id());
    }

    ECS_DEPRECATED("use child_of(parent)")
    type& add_childof(entity& e) {
        return static_cast<Base*>(this)->add(ECS_CHILDOF | e.id());
    }

private:
    Base* base() { return static_cast<Base*>(this); }
    flecs::world_t* world() { return base()->world().c_ptr(); }
};

}
#else
template <typename Base>
class type_deprecated { };
#endif

namespace flecs
{

////////////////////////////////////////////////////////////////////////////////
//// A collection of component ids used to describe the contents of a table
////////////////////////////////////////////////////////////////////////////////

template <typename Base>
class type_base : public type_deprecated<type> {
public:
    explicit type_base(
        world_t *world, char *name = nullptr, char *expr = nullptr)
    {
        ecs_type_desc_t desc = {};
        desc.entity.name = name;
        desc.ids_expr = expr;
        m_entity = flecs::entity(world, ecs_type_init(world, &desc));
        sync_from_flecs();
    }

    explicit type_base(world_t *world, type_t t)
        : m_entity( world, static_cast<flecs::id_t>(0) )
        , m_type( t )
        , m_normalized( t ) { }

    type_base(type_t t)
        : m_type( t )
        , m_normalized( t ) { }

    Base& add(Base& t) {
        m_type = ecs_type_add(world(), m_type, t.id());
        m_normalized = ecs_type_merge(world(), m_normalized, t, nullptr);
        sync_from_me();
        return *this;
    }

    Base& add(id_t e) {
        m_type = ecs_type_add(world(), m_type, e);
        m_normalized = ecs_type_add(world(), m_normalized, e);
        sync_from_me();
        return *this;
    }

    template <typename T>
    Base& add() {
        return this->add(_::cpp_type<T>::id(world()));
    }

    Base& add(entity_t relation, entity_t object) {
        return this->add(ecs_pair(relation, object));
    }

    template <typename Relation, typename Object>
    Base& add() {
        return this->add<Relation>(_::cpp_type<Object>::id(world()));
    }

    Base& is_a(entity_t object) {
        return this->add(flecs::IsA, object);
    }

    Base& child_of(entity_t object) {
        return this->add(flecs::ChildOf, object);
    }

    template <typename Relation>
    Base& add(entity_t object) {
        return this->add(_::cpp_type<Relation>::id(world()), object);
    }

    template <typename Object>
    Base& add_object(entity_t relation) {
        return this->add(relation, _::cpp_type<Object>::id(world()));
    }

    bool has(id_t id) {
        return ecs_type_has_id(world(), m_normalized, id);
    }

    bool has(id_t relation, id_t object) {
        return ecs_type_has_id(world(), m_normalized,
            ecs_pair(relation, object));
    }

    template <typename T>
    bool has() {
        return this->has(_::cpp_type<T>::id(world()));
    }

    template <typename Relation, typename Object>
    bool has() {
        return this->has(_::cpp_type<flecs::pair<Relation, Object>>::id(world()));
    }

    flecs::string str() {
        char *str = ecs_type_str(world(), m_type);
        return flecs::string(str);
    }

    type_t c_ptr() {
        return m_type;
    }

    flecs::id_t id() {
        return m_entity.id();
    }

    flecs::entity entity() {
        return m_entity;
    }

    flecs::world world() {
        return m_entity.world();
    }

    type_t c_normalized() {
        return m_normalized;
    }

    void enable() {
        ecs_enable(world(), id(), true);
    }

    void disable() {
        ecs_enable(world(), id(), false);
    }

    flecs::vector<entity_t> vector() {
        return flecs::vector<entity_t>( const_cast<ecs_vector_t*>(m_normalized));
    }

    /* Implicit conversion to type_t */
    operator type_t() { return m_normalized; }

    operator Base&() { return *static_cast<Base*>(this); }

private:
    void sync_from_me() {
        if (!id()) {
            return;
        }

        EcsType *tc = ecs_get_mut(world(), id(), EcsType, NULL);
        ecs_assert(tc != NULL, ECS_INTERNAL_ERROR, NULL);
        tc->type = m_type;
        tc->normalized = m_normalized;
        ecs_modified(world(), id(), EcsType);

    }

    void sync_from_flecs() {
        if (!id()) {
            return;
        }

        EcsType *tc = ecs_get_mut(world(), id(), EcsType, NULL);
        ecs_assert(tc != NULL, ECS_INTERNAL_ERROR, NULL);
        m_type = tc->type;
        m_normalized = tc->normalized;
        ecs_modified(world(), id(), EcsType);
    }

    flecs::entity m_entity;
    type_t m_type;
    type_t m_normalized;
};

class type : public type_base<type> {
public:
    explicit type(
        world_t *world, char *name = nullptr, char *expr = nullptr)
    : type_base(world, name, expr) { }

    explicit type(world_t *world, type_t t) : type_base(world, t) { }

    type(type_t t) : type_base(t) { }
};

class pipeline : public type_base<pipeline> {
public:
    explicit pipeline(world_t *world, char *name) : type_base(world, name)
    {
        this->entity().add(flecs::Pipeline);
    }
};

} // namespace flecs

namespace flecs
{

////////////////////////////////////////////////////////////////////////////////
//// Define a module
////////////////////////////////////////////////////////////////////////////////

template <typename T>
flecs::entity module(flecs::world& world, char *name = nullptr) {
    ecs_set_scope(world.c_ptr(), 0);
    flecs::entity result = pod_component<T>(world, name, false);
    ecs_add_module_tag(world, result.id());
    ecs_set_scope(world.c_ptr(), result.id());

    // Only register copy/move/dtor, make sure to not instantiate ctor as the
    // default ctor doesn't work for modules. Additionally, the module ctor
    // should only be invoked once per import.
    EcsComponentLifecycle cl{};
    cl.copy = _::copy<T>().callback;
    cl.move = _::move<T>().callback;
    cl.dtor = _::dtor<T>().callback;
    ecs_set_component_actions_w_entity(world, result, &cl);

    return result;
}

////////////////////////////////////////////////////////////////////////////////
//// Import a module
////////////////////////////////////////////////////////////////////////////////

template <typename T>
ecs_entity_t do_import(world& world, char *symbol) {
    ecs_trace_1("import %s", _::name_helper<T>::name());
    ecs_log_push();

    ecs_entity_t scope = ecs_get_scope(world.c_ptr());

    // Create custom storage to prevent object destruction
    T* module_data = static_cast<T*>(ecs_os_malloc(sizeof(T)));
    FLECS_PLACEMENT_NEW(module_data, T(world));

    ecs_set_scope(world.c_ptr(), scope);

    // It should now be possible to lookup the module
    ecs_entity_t m = ecs_lookup_symbol(world.c_ptr(), symbol);
    ecs_assert(m != 0, ECS_MODULE_UNDEFINED, symbol);

    _::cpp_type<T>::init(world.c_ptr(), m, false);

    ecs_assert(_::cpp_type<T>::size() != 0, ECS_INTERNAL_ERROR, NULL);

    // Set module singleton component

    T* module_ptr = static_cast<T*>(
        ecs_get_mut_w_id(world, m,
            _::cpp_type<T>::id_explicit(world, nullptr, false), NULL));

    *module_ptr = std::move(*module_data);

    // Don't dtor, as a module should only be destructed once when the module
    // component is removed.
    ecs_os_free(module_data);

    // Add module tag
    ecs_add_id(world.c_ptr(), m, flecs::Module);

    ecs_log_pop();

    return m;
}

template <typename T>
flecs::entity import(world& world) {
    char *symbol = _::symbol_helper<T>::symbol();

    ecs_entity_t m = ecs_lookup_symbol(world.c_ptr(), symbol);

    if (!_::cpp_type<T>::registered()) {

        /* Module is registered with world, initialize static data */
        if (m) {
            _::cpp_type<T>::init(world.c_ptr(), m, false);

        /* Module is not yet registered, register it now */
        } else {
            m = do_import<T>(world, symbol);
        }

    /* Module has been registered, but could have been for another world. Import
     * if module hasn't been registered for this world. */
    } else if (!m) {
        m = do_import<T>(world, symbol);
    }

    ecs_os_free(symbol);

    return flecs::entity(world, m);
}

} // namespace flecs

namespace flecs
{

////////////////////////////////////////////////////////////////////////////////
//// A filter is used to match subsets of tables
////////////////////////////////////////////////////////////////////////////////

enum match_kind {
    MatchAll = EcsMatchAll,
    MatchAny = EcsMatchAny,
    MatchExact = EcsMatchExact
};

class filter {
public:
    filter()
        : m_world( nullptr )
        , m_filter{ } {}

    explicit filter(world& world)
        : m_world( world.c_ptr() )
        , m_filter{ } { }

    filter& include(type type) {
        m_filter.include = ecs_type_merge(m_world, m_filter.include, type.c_ptr(), nullptr);
        return *this;
    }

    filter& include(entity entity) {
        m_filter.include = ecs_type_add(m_world, m_filter.include, entity.id());
        return *this;
    }

    template <typename T>
    filter& include() {
        m_filter.include = ecs_type_add(m_world, m_filter.include, _::cpp_type<T>::id(m_world));
        return *this;
    }

    filter& include_kind(match_kind kind) {
        m_filter.include_kind = static_cast<ecs_match_kind_t>(kind);
        return *this;
    }

    type include() {
        return type(m_world, m_filter.include);
    }

    filter& exclude(type type) {
        m_filter.exclude = ecs_type_merge(m_world, m_filter.exclude, type.c_ptr(), nullptr);
        return *this;
    }

    filter& exclude(entity entity) {
        m_filter.exclude = ecs_type_add(m_world, m_filter.exclude, entity.id());
        return *this;
    }

    template <typename T>
    filter& exclude() {
        m_filter.exclude = ecs_type_add(m_world, m_filter.exclude, _::cpp_type<T>::id(m_world));
        return *this;
    }

    filter& exclude_kind(match_kind kind) {
        m_filter.exclude_kind = static_cast<ecs_match_kind_t>(kind);
        return *this;
    }

    type exclude() {
        return type(m_world, m_filter.exclude);
    }

    filter_t* c_ptr() {
        if (m_world) {
            return &m_filter;
        } else {
            return nullptr;
        }
    }

private:
    world_t *m_world;
    filter_t m_filter;
};

} // namespace flecs

namespace flecs
{

////////////////////////////////////////////////////////////////////////////////
//// Snapshots make a copy of the world state that can be restored
////////////////////////////////////////////////////////////////////////////////

class snapshot final {
public:
    explicit snapshot(world& world)
        : m_world( world )
        , m_snapshot( nullptr ) { }

    snapshot(snapshot& obj)
        : m_world( obj.m_world )
    {
        ecs_iter_t it = ecs_snapshot_iter(obj.m_snapshot, nullptr);
        m_snapshot = ecs_snapshot_take_w_iter(&it, ecs_snapshot_next);
    }

    snapshot(snapshot&& obj)
        : m_world(obj.m_world)
        , m_snapshot(obj.m_snapshot)
    {
        obj.m_snapshot = nullptr;
    }

    snapshot& operator=(snapshot& obj) {
        ecs_assert(m_world.c_ptr() == obj.m_world.c_ptr(), ECS_INVALID_PARAMETER, NULL);
        ecs_iter_t it = ecs_snapshot_iter(obj.m_snapshot, nullptr);
        m_snapshot = ecs_snapshot_take_w_iter(&it, ecs_snapshot_next);
        return *this;
    }

    snapshot& operator=(snapshot&& obj) {
        ecs_assert(m_world.c_ptr() == obj.m_world.c_ptr(), ECS_INVALID_PARAMETER, NULL);
        m_snapshot = obj.m_snapshot;
        obj.m_snapshot = nullptr;
        return *this;
    }

    void take() {
        if (m_snapshot) {
            ecs_snapshot_free(m_snapshot);
        }

        m_snapshot = ecs_snapshot_take(m_world.c_ptr());
    }

    void take(flecs::filter filter) {
        if (m_snapshot) {
            ecs_snapshot_free(m_snapshot);
        }

        ecs_iter_t it = ecs_filter_iter(m_world.c_ptr(), filter.c_ptr());
        m_snapshot = ecs_snapshot_take_w_iter(
            &it, ecs_filter_next);
    }

    void restore() {
        if (m_snapshot) {
            ecs_snapshot_restore(m_world.c_ptr(), m_snapshot);
            m_snapshot = nullptr;
        }
    }

    ~snapshot() {
        if (m_snapshot) {
            ecs_snapshot_free(m_snapshot);
        }
    }

    snapshot_t* c_ptr() {
        return m_snapshot;
    }

    snapshot_filter filter(filter& filter);

    filter_iterator begin();

    filter_iterator end();
private:
    world& m_world;
    snapshot_t *m_snapshot;
};

} // namespace flecs

namespace flecs
{

////////////////////////////////////////////////////////////////////////////////
//// Utility for iterating over tables that match a filter
////////////////////////////////////////////////////////////////////////////////

class filter_iterator
{
public:
    filter_iterator(ecs_iter_next_action_t action)
        : m_world(nullptr)
        , m_has_next(false)
        , m_iter{ }
        , m_action(action) { }

    filter_iterator(world& world, filter& filter, ecs_iter_next_action_t action)
        : m_world( world.c_ptr() )
        , m_iter( ecs_filter_iter(m_world, filter.c_ptr()) )
        , m_action(action)
    {
        m_has_next = m_action(&m_iter);
    }

    filter_iterator(world& world, snapshot& snapshot, filter& filter, ecs_iter_next_action_t action)
        : m_world( world.c_ptr() )
        , m_iter( ecs_snapshot_iter(snapshot.c_ptr(), filter.c_ptr()) )
        , m_action(action)
    {
        m_has_next = m_action(&m_iter);
    }

    bool operator!=(filter_iterator const& other) {
        return m_has_next != other.m_has_next;
    }

    flecs::iter operator*() {
        return flecs::iter(&m_iter);
    }

    filter_iterator& operator++() {
        m_has_next = m_action(&m_iter);
        return *this;
    }

private:
    world_t *m_world;
    bool m_has_next;
    ecs_iter_t m_iter;
    ecs_iter_next_action_t m_action;
};


////////////////////////////////////////////////////////////////////////////////
//// Tree iterator
////////////////////////////////////////////////////////////////////////////////

class tree_iterator
{
public:
    tree_iterator()
        : m_has_next(false)
        , m_iter{ } { }

    tree_iterator(flecs::world_t *world, flecs::entity_t entity)
        : m_iter( ecs_scope_iter(world, entity ))
    {
        m_has_next = ecs_scope_next(&m_iter);
    }

    bool operator!=(tree_iterator const& other) {
        return m_has_next != other.m_has_next;
    }

    flecs::iter operator*() {
        return flecs::iter(&m_iter);
    }

    tree_iterator& operator++() {
        m_has_next = ecs_scope_next(&m_iter);
        return *this;
    }

private:
    bool m_has_next;
    ecs_iter_t m_iter;
};

////////////////////////////////////////////////////////////////////////////////
//// Utility for creating a world-based filter iterator
////////////////////////////////////////////////////////////////////////////////

class world_filter {
public:
    world_filter(world& world, filter& filter)
        : m_world( world )
        , m_filter( filter ) { }

    inline filter_iterator begin() {
        return filter_iterator(m_world, m_filter, ecs_filter_next);
    }

    inline filter_iterator end() {
        return filter_iterator(ecs_filter_next);
    }

private:
    world& m_world;
    filter& m_filter;
};


////////////////////////////////////////////////////////////////////////////////
//// Utility for creating a snapshot-based filter iterator
////////////////////////////////////////////////////////////////////////////////

class snapshot_filter {
public:
    snapshot_filter(world& world, snapshot& snapshot, filter& filter)
        : m_world( world )
        , m_snapshot( snapshot )
        , m_filter( filter ) { }

    inline filter_iterator begin() {
        return filter_iterator(m_world, m_snapshot, m_filter, ecs_snapshot_next);
    }

    inline filter_iterator end() {
        return filter_iterator(ecs_snapshot_next);
    }

private:
    world& m_world;
    snapshot& m_snapshot;
    filter& m_filter;
};


////////////////////////////////////////////////////////////////////////////////
//// Utility for creating a child table iterator
////////////////////////////////////////////////////////////////////////////////

class child_iterator {
public:
    child_iterator(flecs::entity_view& entity)
        : m_world( entity.world().c_ptr() )
        , m_parent( entity.id() ) { }

    inline tree_iterator begin() {
        return tree_iterator(m_world, m_parent);
    }

    inline tree_iterator end() {
        return tree_iterator();
    }

private:
    flecs::world_t *m_world;
    flecs::entity_t m_parent;
};


////////////////////////////////////////////////////////////////////////////////
//// Filter fwd declared functions
////////////////////////////////////////////////////////////////////////////////

inline snapshot_filter snapshot::filter(flecs::filter& filter) {
    return snapshot_filter(m_world, *this, filter);
}

inline filter_iterator snapshot::begin() {
    return filter_iterator(m_world, *this, flecs::filter(m_world), ecs_snapshot_next);
}

inline filter_iterator snapshot::end() {
    return filter_iterator(ecs_snapshot_next);
}

}

namespace flecs
{

////////////////////////////////////////////////////////////////////////////////
//// Persistent queries
////////////////////////////////////////////////////////////////////////////////

class query_base {
public:
    query_base()
        : m_world(nullptr)
        , m_query(nullptr) { }

    query_base(world_t *world, query_t *query = nullptr)
        : m_world(world)
        , m_query(query) { }

    /* Get pointer to C query object.
     */
    query_t* c_ptr() {
        return m_query;
    }

    /* Sort the output of a query.
     * This enables sorting of entities across matched tables. As a result of this
     * operation, the order of entities in the matched tables may be changed.
     * Resorting happens when a query iterator is obtained, and only if the table
     * data has changed.
     *
     * If multiple queries that match the same (sub)set of tables specify different
     * sorting functions, resorting is likely to happen every time an iterator is
     * obtained, which can significantly slow down iterations.
     *
     * The sorting function will be applied to the specified component. Resorting
     * only happens if that component has changed, or when the entity order in the
     * table has changed. If no component is provided, resorting only happens when
     * the entity order changes.
     *
     * @tparam T The component used to sort.
     * @param compare The compare function used to sort the components.
     */
    template <typename T>
    void order_by(int(*compare)(flecs::entity_t, T*, flecs::entity_t, T*)) {
        ecs_query_order_by(m_world, m_query,
            flecs::_::cpp_type<T>::id(m_world),
            reinterpret_cast<ecs_compare_action_t>(compare));
    }

    /* Sort the output of a query.
     * Same as order_by<T>, but with component identifier.
     *
     * @param component The component used to sort.
     * @param compare The compare function used to sort the components.
     */
    void order_by(flecs::entity component, int(*compare)(flecs::entity_t, void*, flecs::entity_t, void*)) {
        ecs_query_order_by(m_world, m_query, component.id(), compare);
    }

    /* Group and sort matched tables.
     * Similar yo ecs_query_order_by, but instead of sorting individual entities, this
     * operation only sorts matched tables. This can be useful of a query needs to
     * enforce a certain iteration order upon the tables it is iterating, for
     * example by giving a certain component or tag a higher priority.
     *
     * The sorting function assigns a "rank" to each type, which is then used to
     * sort the tables. Tables with higher ranks will appear later in the iteration.
     *
     * Resorting happens when a query iterator is obtained, and only if the set of
     * matched tables for a query has changed. If table sorting is enabled together
     * with entity sorting, table sorting takes precedence, and entities will be
     * sorted within each set of tables that are assigned the same rank.
     *
     * @tparam T The component used to determine the group rank.
     * @param rank The rank action.
     */
    template <typename T>
    void group_by(int(*rank)(flecs::world_t*, flecs::entity_t, flecs::type_t type)) {
        ecs_query_group_by(m_world, m_query,
            flecs::_::cpp_type<T>::id(m_world), rank);
    }

    /* Group and sort matched tables.
     * Same as group_by<T>, but with component identifier.
     *
     * @param component The component used to determine the group rank.
     * @param rank The rank action.
     */
    void group_by(flecs::entity component, int(*rank)(flecs::world_t*, flecs::entity_t, flecs::type_t type)) {
        ecs_query_group_by(m_world, m_query, component.id(), rank);
    }

    /* Returns whether the query data changed since the last iteration.
     * This operation must be invoked before obtaining the iterator, as this will
     * reset the changed state. The operation will return true after:
     * - new entities have been matched with
     * - matched entities were deleted
     * - matched components were changed
     *
     * @return true if entities changed, otherwise false.
     */
    bool changed() {
        return ecs_query_changed(m_query);
    }

    /* Returns whether query is orphaned.
     * When the parent query of a subquery is deleted, it is left in an orphaned
     * state. The only valid operation on an orphaned query is deleting it. Only
     * subqueries can be orphaned.
     *
     * @return true if query is orphaned, otherwise false.
     */
    bool orphaned() {
        return ecs_query_orphaned(m_query);
    }

    /* Free the query.
     */
    void destruct() {
        ecs_query_free(m_query);
        m_world = nullptr;
        m_query = nullptr;
    }

    template <typename Func>
    void iter(Func&& func) {
        ecs_iter_t it = ecs_query_iter(m_query);
        while (ecs_query_next(&it)) {
            _::iter_invoker<Func>(func).invoke(&it);
        }
    }

    template <typename Func>
    void each_term(Func& func) {
        ecs_filter_t *f = ecs_query_get_filter(m_query);
        ecs_assert(f != NULL, ECS_INVALID_PARAMETER, NULL);

        for (int i = 0; i < f->term_count; i ++) {
            flecs::term t(m_world, f->terms[i]);
            func(t);
        }
    }

    flecs::term term(int32_t index) {
        ecs_filter_t *f = ecs_query_get_filter(m_query);
        ecs_assert(f != NULL, ECS_INVALID_PARAMETER, NULL);
        return flecs::term(m_world, f->terms[index]);
    }

    int32_t term_count() {
        ecs_filter_t *f = ecs_query_get_filter(m_query);
        return f->term_count;
    }

    flecs::string str() {
        ecs_filter_t *f = ecs_query_get_filter(m_query);
        char *result = ecs_filter_str(m_world, f);
        return flecs::string(result);
    }

protected:
    world_t *m_world;
    query_t *m_query;
};


template<typename ... Components>
class query : public query_base {
    using Terms = typename _::term_ptrs<Components...>::array;

public:
    query() { }

    query(world_t *world, query_t *q)
        : query_base(world, q) { }

    explicit query(world& world, char *expr = nullptr)
        : query_base(world.c_ptr())
    {
        auto qb = world.query_builder<Components ...>()
            .expr(expr);

        if (!expr) {
            qb.substitute_default();
        }

        m_query = qb;
    }

    explicit query(world& world, query_base& parent, char *expr = nullptr)
        : query_base(world.c_ptr())
    {
        auto qb = world.query_builder<Components ...>()
            .parent(parent)
            .expr(expr);

        if (!expr) {
            qb.substitute_default();
        }

        m_query = qb;
    }

    template <typename Func>
    void each(Func&& func) {
        iterate<_::each_invoker>(std::forward<Func>(func), ecs_query_next);
    }

    template <typename Func>
    void each(flecs::filter& filter, Func&& func) {
        filter_t* filter_ptr = filter.c_ptr();
        iterate<_::each_invoker>(std::forward<Func>(func),
            ecs_query_next_w_filter, filter_ptr);
    }

    template <typename Func>
    void each_worker(int32_t stage_current, int32_t stage_count, Func&& func) {
        iterate<_::each_invoker>(std::forward<Func>(func),
            ecs_query_next_worker, stage_current, stage_count);
    }

    template <typename Func>
    void iter(Func&& func) {
        iterate<_::iter_invoker>(std::forward<Func>(func), ecs_query_next);
    }

    template <typename Func>
    void iter(flecs::filter& filter, Func&& func) {
        filter_t* filter_ptr = filter.c_ptr();
        iterate<_::iter_invoker>(std::forward<Func>(func),
            ecs_query_next_w_filter, filter_ptr);
    }

    template <typename Func>
    void iter_worker(int32_t stage_current, int32_t stage_count, Func&& func) {
        iterate<_::iter_invoker>(std::forward<Func>(func),
            ecs_query_next_worker, stage_current, stage_count);
    }

    template <typename Func>
    ECS_DEPRECATED("use each or iter")
    void action(Func&& func) {
        iterate<_::action_invoker>(std::forward<Func>(func), ecs_query_next);
    }

private:
    template < template<typename Func, typename ... Comps> class Invoker, typename Func, typename NextFunc, typename ... Args>
    void iterate(Func&& func, NextFunc next, Args &&... args) {
        ecs_iter_t it = ecs_query_iter(m_query);
        while (next(&it, std::forward<Args>(args)...)) {
            Invoker<Func, Components...>(func).invoke(&it);
        }
    }
};

} // namespace flecs

namespace flecs
{

////////////////////////////////////////////////////////////////////////////////
//// Fluent interface to run a system manually
////////////////////////////////////////////////////////////////////////////////

class system_runner_fluent {
public:
    system_runner_fluent(
        world_t *world,
        entity_t id,
        int32_t stage_current,
        int32_t stage_count,
        FLECS_FLOAT delta_time,
        void *param)
        : m_stage(world)
        , m_id(id)
        , m_delta_time(delta_time)
        , m_param(param)
        , m_filter()
        , m_offset(0)
        , m_limit(0)
        , m_stage_current(stage_current)
        , m_stage_count(stage_count) { }

    system_runner_fluent& filter(filter filter) {
        m_filter = filter;
        return *this;
    }

    system_runner_fluent& offset(int32_t offset) {
        m_offset = offset;
        return *this;
    }

    system_runner_fluent& limit(int32_t limit) {
        m_limit = limit;
        return *this;
    }

    system_runner_fluent& stage(flecs::world& stage) {
        m_stage = stage.c_ptr();
        return *this;
    }

    ~system_runner_fluent() {
        if (m_stage_count) {
            ecs_run_worker(
                m_stage, m_id, m_stage_current, m_stage_count, m_delta_time,
                m_param);
        } else {
            ecs_run_w_filter(
                m_stage, m_id, m_delta_time, m_offset, m_limit,
                m_filter.c_ptr(), m_param);
        }
    }
private:
    world_t *m_stage;
    entity_t m_id;
    FLECS_FLOAT m_delta_time;
    void *m_param;
    flecs::filter m_filter;
    int32_t m_offset;
    int32_t m_limit;
    int32_t m_stage_current;
    int32_t m_stage_count;
};


////////////////////////////////////////////////////////////////////////////////
//// Register a system with Flecs
////////////////////////////////////////////////////////////////////////////////

template<typename ... Components>
class system : public entity
{
public:
    explicit system()
        : entity() { }

    explicit system(flecs::world_t *world, flecs::entity_t id)
        : entity(world, id) { }

    template <typename T>
    void order_by(int(*compare)(flecs::entity_t, T*, flecs::entity_t, T*)) {
        this->order_by(flecs::_::cpp_type<T>::id(m_world),
            reinterpret_cast<ecs_compare_action_t>(compare));
    }

    void order_by(flecs::entity_t component, int(*compare)(flecs::entity_t, void*, flecs::entity_t, void*)) {
        ecs_query_t *q = query().c_ptr();
        ecs_assert(q != NULL, ECS_INVALID_PARAMETER, NULL);
        ecs_query_order_by(m_world, q, component, compare);
    }

    template <typename T>
    void group_by(int(*rank)(flecs::world_t*, flecs::entity_t, flecs::type_t type)) {
        this->group_by(flecs::_::cpp_type<T>::id(m_world), rank);
    }

    void group_by(flecs::entity_t component, int(*rank)(flecs::world_t*, flecs::entity_t, flecs::type_t type)) {
        ecs_query_t *q = query().c_ptr();
        ecs_assert(q != NULL, ECS_INVALID_PARAMETER, NULL);
        ecs_query_group_by(m_world, q, component, rank);
    }

    /* Set system interval.
     * This operation will cause the system to be ran at the specified interval.
     *
     * The timer is synchronous, and is incremented each frame by delta_time.
     *
     * @param interval The interval value.
     */
    void interval(FLECS_FLOAT interval) {
        ecs_set_interval(m_world, m_id, interval);
    }

    /* Set system rate.
     * This operation will cause the system to be ran at a multiple of the
     * provided tick source. The tick source may be any entity, including
     * another system.
     *
     * @param tick_source The tick source.
     * @param rate The multiple at which to run the system.
     */
    void rate(flecs::entity& tick_source, int32_t rate) {
        ecs_set_rate(m_world, m_id, rate, tick_source.id());
    }

    /* Set system rate.
     * This operation will cause the system to be ran at a multiple of the
     * frame tick frequency. If a tick source was provided, this just updates
     * the rate of the system.
     *
     * @param rate The multiple at which to run the system.
     */
    void rate(int32_t rate) {
        ecs_set_rate(m_world, m_id, rate, 0);
    }

    /* Get interval.
     * Get interval at which the system is running.
     *
     * @return The timer entity.
     */
    FLECS_FLOAT interval() {
        return ecs_get_interval(m_world, m_id);
    }

    void enable() {
        ecs_enable(m_world, m_id, true);
    }

    void disable() {
        ecs_enable(m_world, m_id, false);
    }

    void ctx(void *ctx) {
        if (ecs_has(m_world, m_id, EcsSystem)) {
            ecs_system_desc_t desc = {};
            desc.entity.entity = m_id;
            desc.ctx = ctx;
            ecs_system_init(m_world, &desc);
        } else {
            ecs_trigger_desc_t desc = {};
            desc.entity.entity = m_id;
            desc.ctx = ctx;
            ecs_trigger_init(m_world, &desc);
        }
    }

    void* ctx() {
        if (ecs_has(m_world, m_id, EcsSystem)) {
            return ecs_get_system_ctx(m_world, m_id);
        } else {
            return ecs_get_trigger_ctx(m_world, m_id);
        }
    }

    ECS_DEPRECATED("use interval")
    void period(FLECS_FLOAT period) {
        this->interval(period);
    }

    ECS_DEPRECATED("use interval")
    void set_period(FLECS_FLOAT period) {
        this->interval(period);
    }

    ECS_DEPRECATED("use ctx(void*)")
    void set_context(void *ptr) {
        ctx(ptr);
    }

    ECS_DEPRECATED("use void* ctx()")
    void* get_context() {
        return ctx();
    }

    query_base query() {
        return query_base(m_world, ecs_get_system_query(m_world, m_id));
    }

    system_runner_fluent run(FLECS_FLOAT delta_time = 0.0f, void *param = nullptr) {
        return system_runner_fluent(m_world, m_id, 0, 0, delta_time, param);
    }

    system_runner_fluent run_worker(
        int32_t stage_current,
        int32_t stage_count,
        FLECS_FLOAT delta_time = 0.0f,
        void *param = nullptr) const
    {
        return system_runner_fluent(
            m_world, m_id, stage_current, stage_count, delta_time, param);
    }
};

} // namespace flecs

namespace flecs
{

template<typename ... Components>
class observer : public entity
{
public:
    explicit observer()
        : entity() { }

    explicit observer(flecs::world_t *world, flecs::entity_t id)
        : entity(world, id) { }

    void ctx(void *ctx) {
        ecs_observer_desc_t desc = {};
        desc.entity.entity = m_id;
        desc.ctx = ctx;
        ecs_observer_init(m_world, &desc);
    }

    void* ctx() {
        return ecs_get_observer_ctx(m_world, m_id);
    }
};

} // namespace flecs

namespace flecs
{

////////////////////////////////////////////////////////////////////////////////
//// Reader for world/snapshot serialization
////////////////////////////////////////////////////////////////////////////////

class reader final {
public:
    explicit reader(world& world) {
        m_reader = ecs_reader_init(world.c_ptr());
    }

    reader(world& world, snapshot& snapshot) {
        (void)world;
        ecs_iter_t it = ecs_snapshot_iter(snapshot.c_ptr(), nullptr);
        m_reader = ecs_reader_init_w_iter(&it, ecs_snapshot_next);
    }

    int32_t read(char *buffer, int64_t size) {
        return ecs_reader_read(buffer, static_cast<int32_t>(size), &m_reader);
    }

private:
    ecs_reader_t m_reader;
};

////////////////////////////////////////////////////////////////////////////////
//// Writer for world deserialization
////////////////////////////////////////////////////////////////////////////////

class writer final {
public:
    explicit writer(world& world) {
        m_writer = ecs_writer_init(world.c_ptr());
    }

    int32_t write(char *buffer, int64_t size) {
        return ecs_writer_write(buffer, static_cast<int32_t>(size), &m_writer);
    }

private:
    ecs_writer_t m_writer;
};

} // namespace flecs



namespace flecs
{

namespace _
{

template <typename T>
inline void ctor_world_entity_impl(
    ecs_world_t* world, ecs_entity_t, ecs_entity_t* ids, void *ptr,
    size_t size, int32_t count, void*)
{
    (void)size; ecs_assert(size == sizeof(T), ECS_INTERNAL_ERROR, NULL);
    T *arr = static_cast<T*>(ptr);
    flecs::world w(world);
    for (int i = 0; i < count; i ++) {
        flecs::entity e(world, ids[i]);
        FLECS_PLACEMENT_NEW(&arr[i], T(w, e));
    }
}

} // _
} // flecs

namespace flecs
{

////////////////////////////////////////////////////////////////////////////////
//// Entity range, allows for operating on a range of consecutive entities
////////////////////////////////////////////////////////////////////////////////

class ECS_DEPRECATED("do not use") entity_range final {
public:
    entity_range(world& world, int32_t count)
        : m_world(world.c_ptr())
        , m_ids( ecs_bulk_new_w_type(m_world, nullptr, count)) { }

    entity_range(world& world, int32_t count, flecs::type type)
        : m_world(world.c_ptr())
        , m_ids( ecs_bulk_new_w_type(m_world, type.c_ptr(), count)) { }

private:
    world_t *m_world;
    entity_t *m_ids;
};

template <typename T>
flecs::entity ref<T>::entity() {
    return flecs::entity(m_world, m_entity);
}

template <typename Base>
inline Base& entity_builder<Base>::add(type& type) {
    ecs_add_type(this->base_world(), this->base_id(), type.c_ptr());
    return *this;
}

template <typename Base>
inline Base& entity_builder<Base>::remove(type& type) {
    ecs_remove_type(this->base_world(), this->base_id(), type.c_ptr());
    return *this;
}

template <typename Base>
inline Base& entity_builder<Base>::add_owned(type& type) {
    return add_owned(type.id());
}

template <typename Base>
inline Base& entity_builder<Base>::add_switch(type& sw) {
    return add_switch(sw.id());
}

template <typename Base>
inline Base& entity_builder<Base>::remove_switch(type& sw) {
    return remove_switch(sw.id());
}

template <typename Base>
template <typename Func, if_t< is_callable<Func>::value > >
inline Base& entity_builder<Base>::set(Func& func) {
    _::entity_with_invoker<Func>::invoke_get_mut(
        this->base_world(), this->base_id(), func);
    return *this;
}

inline bool entity_view::has_switch(flecs::type& type) {
    return ecs_has_entity(m_world, m_id, flecs::Switch | type.id());
}

inline flecs::entity_view entity_view::get_case(flecs::type& sw) {
    return flecs::entity(m_world, ecs_get_case(m_world, m_id, sw.id()));
}

inline flecs::entity id::role() {
    return flecs::entity(m_world, m_id & ECS_ROLE_MASK);
}

inline flecs::entity id::relation() {
    ecs_assert(is_pair(), ECS_INVALID_OPERATION, NULL);

    flecs::entity_t e = ECS_PAIR_RELATION(m_id);
    if (m_world) {
        return flecs::entity(m_world, ecs_get_alive(m_world, e));
    } else {
        return flecs::entity(e);
    }
}

inline flecs::entity id::object() {
    flecs::entity_t e = ECS_PAIR_OBJECT(m_id);
    if (m_world) {
        return flecs::entity(m_world, ecs_get_alive(m_world, e));
    } else {
        return flecs::entity(m_world, e);
    }
}

inline flecs::entity id::add_role(flecs::id_t role) {
    return flecs::entity(m_world, m_id | role);
}

inline flecs::entity id::remove_role(flecs::id_t role) {
    (void)role;
    ecs_assert((m_id & ECS_ROLE_MASK) == role, ECS_INVALID_PARAMETER, NULL);
    return flecs::entity(m_world, m_id & ECS_COMPONENT_MASK);
}

inline flecs::entity id::remove_role() {
    return flecs::entity(m_world, m_id & ECS_COMPONENT_MASK);
}

inline flecs::entity id::remove_generation() {
    return flecs::entity(m_world, static_cast<uint32_t>(m_id));
}

inline entity id::lo() {
    return entity(m_world, ecs_entity_t_lo(m_id));
}

inline entity id::hi() {
    return entity(m_world, ecs_entity_t_hi(m_id));
}

inline entity id::comb(entity_view lo, entity_view hi) {
    return entity(lo.world(),
        ecs_entity_t_comb(lo.id(), hi.id()));
}

inline flecs::entity entity_view::mut(flecs::world& stage) {
    ecs_assert(!stage.is_readonly(), ECS_INVALID_PARAMETER,
        "cannot use readonly world/stage to create mutable handle");
    return flecs::entity(m_id).set_stage(stage.c_ptr());
}

/* Same as mut(world), but for iterator.
 * This operation allows for the construction of a mutable entity handle
 * from an iterator.
 *
 * @param stage An created for the current stage.
 * @return An entity handle that allows for mutations in the current stage.
 */
inline flecs::entity entity_view::mut(flecs::iter& it) {
    ecs_assert(!it.world().is_readonly(), ECS_INVALID_PARAMETER,
        "cannot use iterator created for readonly world/stage to create mutable handle");
    return flecs::entity(m_id).set_stage(it.world().c_ptr());
}

/* Same as mut(world), but for entity.
 * This operation allows for the construction of a mutable entity handle
 * from another entity. This is useful in each() functions, which only
 * provide a handle to the entity being iterated over.
 *
 * @param stage An created for the current stage.
 * @return An entity handle that allows for mutations in the current stage.
 */
inline flecs::entity entity_view::mut(flecs::entity_view& e) {
    ecs_assert(!e.world().is_readonly(), ECS_INVALID_PARAMETER,
        "cannot use entity created for readonly world/stage to create mutable handle");
    return flecs::entity(m_id).set_stage(e.m_world);
}

inline flecs::entity entity_view::set_stage(world_t *stage) {
    m_world = stage;
    return flecs::entity(m_world, m_id);
}

inline flecs::type entity_view::type() {
    return flecs::type(m_world, ecs_get_type(m_world, m_id));
}

inline flecs::type entity_view::to_type() {
    ecs_type_t type = ecs_type_from_entity(m_world, m_id);
    return flecs::type(m_world, type);
}

inline child_iterator entity_view::children() {
    return flecs::child_iterator(*this);
}

template <typename Func>
inline void entity_view::each(Func& func) {
    ecs_vector_t *type = ecs_get_type(m_world, m_id);
    if (!type) {
        return;
    }

    ecs_id_t *ids = static_cast<ecs_id_t*>(
        _ecs_vector_first(type, ECS_VECTOR_T(ecs_id_t)));
    int32_t count = ecs_vector_count(type);

    for (int i = 0; i < count; i ++) {
        ecs_id_t id = ids[i];
        flecs::entity ent(m_world, id);
        func(ent);

        // Case is not stored in type, so handle separately
        if ((id & ECS_ROLE_MASK) == flecs::Switch) {
            ent = flecs::entity(
                m_world, flecs::Case | ecs_get_case(
                        m_world, m_id, ent.object().id()));
            func(ent);
        }
    }
}

template <typename Func>
inline void entity_view::match(id_t pattern, Func& func) {
    ecs_vector_t *type = ecs_get_type(m_world, m_id);
    if (!type) {
        return;
    }

    id_t *ids = static_cast<ecs_id_t*>(
        _ecs_vector_first(type, ECS_VECTOR_T(ecs_id_t)));
    int32_t cur = 0;

    while (-1 != (cur = ecs_type_match(type, cur, pattern))) {
        flecs::entity ent(m_world, ids[cur]);
        func(ent);
        cur ++;
    }
}

template <typename Func>
inline void entity_view::each(flecs::entity_view& rel, Func& func) {
    return this->match(ecs_pair(rel, flecs::Wildcard), [&](flecs::id id) {
        flecs::entity obj = id.object();
        func(obj);
    });
}

template <typename Func, if_t< is_callable<Func>::value > >
inline bool entity_view::get(Func& func) {
    return _::entity_with_invoker<Func>::invoke_get(m_world, m_id, func);
}

}

namespace flecs
{

inline flecs::entity iter::system() {
    return flecs::entity(m_iter->world, m_iter->system);
}

inline flecs::world iter::world() {
    return flecs::world(m_iter->world);
}

inline flecs::entity iter::entity(size_t row) {
    ecs_assert(row < static_cast<size_t>(m_iter->count), ECS_COLUMN_INDEX_OUT_OF_RANGE, NULL);
    if (!this->world().is_readonly()) {
        return flecs::entity(m_iter->entities[row])
            .mut(this->world());
    } else {
        return flecs::entity(this->world().c_ptr(), m_iter->entities[row]);
    }
}

/* Obtain column source (0 if self) */
template <typename Base>
inline flecs::entity iter_deprecated<Base>::column_source(int32_t col) {
    return flecs::entity(iter()->world, ecs_term_source(iter(), col));
}

/* Obtain component/tag entity of column */
template <typename Base>
inline flecs::entity iter_deprecated<Base>::column_entity(int32_t col) {
    return flecs::entity(iter()->world, ecs_term_id(iter(), col));
}

/* Obtain type of column */
template <typename Base>
inline type iter_deprecated<Base>::column_type(int32_t col) {
    return flecs::type(iter()->world, ecs_column_type(iter(), col));
}

/* Obtain type of table being iterated over */
template <typename Base>
inline type iter_deprecated<Base>::table_type() {
    return flecs::type(iter()->world, ecs_iter_type(iter()));
}

template <typename T>
inline column<T>::column(iter &iter, int32_t index) {
    *this = iter.term<T>(index);
}

inline flecs::entity iter::term_source(int32_t index) {
    return flecs::entity(m_iter->world, ecs_term_source(m_iter, index));
}

inline flecs::entity iter::term_id(int32_t index) {
    return flecs::entity(m_iter->world, ecs_term_id(m_iter, index));
}

/* Obtain type of iter */
inline flecs::type iter::type() {
    return flecs::type(m_iter->world, ecs_iter_type(m_iter));
}

} // namespace flecs

namespace flecs
{

/* Get id from a type. */
template <typename T>
inline flecs::id world::id() {
    return flecs::id(m_world, _::cpp_type<T>::id(m_world));
}

template <typename R, typename O>
inline flecs::id world::pair() {
    return flecs::id(
        m_world,
        ecs_pair(
            _::cpp_type<R>::id(m_world),
            _::cpp_type<O>::id(m_world)));
}

template <typename R>
inline flecs::id world::pair(entity_t o) {
    return flecs::id(
        m_world,
        ecs_pair(
            _::cpp_type<R>::id(m_world),
            o));
}

inline flecs::id world::pair(entity_t r, entity_t o) {
    return flecs::id(
        m_world,
        ecs_pair(r, o));
}

inline void world::delete_entities(flecs::filter filter) {
    ecs_bulk_delete(m_world, filter.c_ptr());
}

template <typename T>
inline void world::add(flecs::filter filter) {
    ecs_bulk_add_remove_type(
        m_world, _::cpp_type<T>::type(m_world), nullptr, filter.c_ptr());
}

inline void world::add(flecs::type t) {
    ecs_bulk_add_remove_type(m_world, t.c_ptr(), nullptr, nullptr);
}

inline void world::add(flecs::type t, flecs::filter filter) {
    ecs_bulk_add_remove_type(m_world, t.c_ptr(), nullptr, filter.c_ptr());
}

inline void world::add(class flecs::entity e) {
    ecs_bulk_add_remove_type(m_world, e.to_type().c_ptr(), nullptr, nullptr);
}

inline void world::add(class flecs::entity e, flecs::filter filter) {
    ecs_bulk_add_remove_type(m_world, e.to_type().c_ptr(), nullptr, filter.c_ptr());
}

template <typename T>
inline void world::remove(flecs::filter filter) {
    ecs_bulk_add_remove_type(
        m_world, nullptr, _::cpp_type<T>::type(m_world), filter.c_ptr());
}

inline void world::remove(flecs::type t) {
    ecs_bulk_add_remove_type(m_world, nullptr, t.c_ptr(), nullptr);
}

inline void world::remove(flecs::type t, flecs::filter filter) {
    ecs_bulk_add_remove_type(m_world, nullptr, t.c_ptr(), filter.c_ptr());
}

inline void world::remove(class entity e) {
    ecs_bulk_add_remove_type(m_world, nullptr, e.to_type().c_ptr(), nullptr);
}

inline void world::remove(class entity e, flecs::filter filter) {
    ecs_bulk_add_remove_type(m_world, nullptr, e.to_type().c_ptr(), filter.c_ptr());
}

inline flecs::world_filter world::filter(flecs::filter& filter) {
    return flecs::world_filter(*this, filter);
}

inline filter_iterator world::begin() {
    return filter_iterator(*this, flecs::filter(*this), ecs_filter_next);
}

inline filter_iterator world::end() {
    return filter_iterator(ecs_filter_next);
}

inline int world::count(flecs::filter filter) {
    return ecs_count_w_filter(m_world, filter.c_ptr());
}

/* All entities created in function are created in scope. All operations
    * called in function (such as lookup) are relative to scope.
    */
template <typename Func>
void scope(id_t parent, Func& func);

inline void world::init_builtin_components() {
    pod_component<Component>("flecs::core::Component");
    pod_component<Type>("flecs::core::Type");
    pod_component<Name>("flecs::core::Name");
    pod_component<Trigger>("flecs::core::Trigger");
    pod_component<Observer>("flecs::core::Observer");
    pod_component<Query>("flecs::core::Query");

    pod_component<TickSource>("flecs::system::TickSource");
    pod_component<RateFilter>("flecs::timer::RateFilter");
    pod_component<Timer>("flecs::timer::Timer");
}

template <typename T>
inline flecs::entity world::use(char *alias) {
    entity_t e = _::cpp_type<T>::id(m_world);
    char *name = alias;
    if (!name) {
        // If no name is defined, use the entity name without the scope
        name = ecs_get_name(m_world, e);
    }
    ecs_use(m_world, e, name);
    return flecs::entity(m_world, e);
}

inline flecs::entity world::use(char *name, char *alias) {
    entity_t e = ecs_lookup_path_w_sep(m_world, 0, name, "::", "::", true);
    ecs_assert(e != 0, ECS_INVALID_PARAMETER, NULL);

    ecs_use(m_world, e, alias);
    return flecs::entity(m_world, e);
}

inline void world::use(flecs::entity e, char *alias) {
    entity_t eid = e.id();
    char *name = alias;
    if (!name) {
        // If no name is defined, use the entity name without the scope
        ecs_get_name(m_world, eid);
    }
    ecs_use(m_world, eid, alias);
}

inline flecs::entity world::set_scope(flecs::entity& s) {
    return flecs::entity(ecs_set_scope(m_world, s.id()));
}

inline flecs::entity world::get_scope() {
    return flecs::entity(ecs_get_scope(m_world));
}

inline entity world::lookup(char *name) {
    auto e = ecs_lookup_path_w_sep(m_world, 0, name, "::", "::", true);
    return flecs::entity(*this, e);
}

template <typename T>
T* world::get_mut() {
    flecs::entity e(m_world, _::cpp_type<T>::id(m_world));
    return e.get_mut<T>();
}

template <typename T>
void world::modified() {
    flecs::entity e(m_world, _::cpp_type<T>::id(m_world));
    return e.modified<T>();
}

template <typename T, typename Func>
void world::patch(Func& func) {
    flecs::entity e(m_world, _::cpp_type<T>::id(m_world));
    e.patch<T>(func);
}

template <typename T>
T* world::get() {
    flecs::entity e(m_world, _::cpp_type<T>::id(m_world));
    return e.get<T>();
}

template <typename T>
bool world::has() {
    flecs::entity e(m_world, _::cpp_type<T>::id(m_world));
    return e.has<T>();
}

template <typename T>
void world::add() {
    flecs::entity e(m_world, _::cpp_type<T>::id(m_world));
    e.add<T>();
}

template <typename T>
void world::remove() {
    flecs::entity e(m_world, _::cpp_type<T>::id(m_world));
    e.remove<T>();
}

inline void world::set_pipeline(flecs::pipeline& pip) {
    ecs_set_pipeline(m_world, pip.id());
}

template <typename T>
inline flecs::entity world::singleton() {
    return flecs::entity(m_world, _::cpp_type<T>::id(m_world));
}

template <typename... Args>
inline flecs::entity world::entity(Args &&... args) {
    return flecs::entity(*this, std::forward<Args>(args)...);
}

template <typename... Args>
inline flecs::entity world::prefab(Args &&... args) {
    return flecs::prefab(*this, std::forward<Args>(args)...);
}

template <typename... Args>
inline flecs::type world::type(Args &&... args) {
    return flecs::type(*this, std::forward<Args>(args)...);
}

template <typename... Args>
inline flecs::pipeline world::pipeline(Args &&... args) {
    return flecs::pipeline(*this, std::forward<Args>(args)...);
}

inline flecs::system<> world::system(flecs::entity e) {
    return flecs::system<>(m_world, e);
}

template <typename... Comps, typename... Args>
inline flecs::system_builder<Comps...> world::system(Args &&... args) {
    return flecs::system_builder<Comps...>(*this, std::forward<Args>(args)...);
}

template <typename... Comps, typename... Args>
inline flecs::observer_builder<Comps...> world::observer(Args &&... args) {
    return flecs::observer_builder<Comps...>(*this, std::forward<Args>(args)...);
}

template <typename... Comps, typename... Args>
inline flecs::query<Comps...> world::query(Args &&... args) {
    return flecs::query<Comps...>(*this, std::forward<Args>(args)...);
}

template <typename... Comps, typename... Args>
inline flecs::query_builder<Comps...> world::query_builder(Args &&... args) {
    return flecs::query_builder<Comps...>(*this, std::forward<Args>(args)...);
}

template <typename... Args>
inline flecs::term world::term(Args &&... args) {
    return flecs::term(*this, std::forward<Args>(args)...);
}

template <typename T, typename... Args>
inline flecs::term world::term(Args &&... args) {
    return flecs::term(*this, std::forward<Args>(args)...).id<T>();
}

template <typename R, typename O, typename... Args>
inline flecs::term world::term(Args &&... args) {
    return flecs::term(*this, std::forward<Args>(args)...).id<R, O>();
}

template <typename Module, typename... Args>
inline flecs::entity world::module(Args &&... args) {
    return flecs::module<Module>(*this, std::forward<Args>(args)...);
}

template <typename Module>
inline flecs::entity world::import() {
    return flecs::import<Module>(*this);
}

template <typename T, typename... Args>
inline flecs::entity world::component(Args &&... args) {
    return flecs::component<T>(*this, std::forward<Args>(args)...);
}

template <typename T, typename... Args>
inline flecs::entity world::pod_component(Args &&... args) {
    return flecs::pod_component<T>(*this, std::forward<Args>(args)...);
}

template <typename T, typename... Args>
inline flecs::entity world::relocatable_component(Args &&... args) {
    return flecs::relocatable_component<T>(*this, std::forward<Args>(args)...);
}

template <typename... Args>
inline flecs::snapshot world::snapshot(Args &&... args) {
    return flecs::snapshot(*this, std::forward<Args>(args)...);
}

} // namespace flecs

namespace flecs
{

template<typename Base>
inline Base& term_builder_i<Base>::id(flecs::type& type) {
    ecs_assert(m_term != nullptr, ECS_INVALID_PARAMETER, NULL);
    m_term->id = type.id();
    return *this;
}

template <typename ... Components>
inline query_builder_base<Components...>::operator query<Components ...>() {
    ecs_query_t *query = *this;
    return flecs::query<Components...>(m_world, query);
}

template <typename ... Components>
inline query_builder<Components ...>::operator query<>() {
    ecs_query_t *query = *this;
    return flecs::query<>(this->m_world, query);
}

template <typename ... Components>
inline query<Components ...> query_builder_base<Components...>::build() {
    ecs_query_t *query = *this;
    return flecs::query<Components...>(m_world, query);
}

template <typename Base, typename ... Components>
inline Base& query_builder_i<Base, Components ...>::parent(query_base& parent) {
    m_desc->parent = parent.c_ptr();
    return *static_cast<Base*>(this);
}

template <typename ... Components>
template <typename Func>
inline system<Components ...> system_builder<Components...>::action(Func&& func) {
    flecs::entity_t system = build<action_invoker_t<Func>>(std::forward<Func>(func), false);
    return flecs::system<Components...>(m_world, system);
}

template <typename ... Components>
template <typename Func>
inline system<Components ...> system_builder<Components...>::iter(Func&& func) {
    using Invoker = typename _::iter_invoker<
        typename std::decay<Func>::type, Components...>;
    flecs::entity_t system = build<Invoker>(std::forward<Func>(func), false);
    return flecs::system<Components...>(m_world, system);
}

template <typename ... Components>
template <typename Func>
inline system<Components ...> system_builder<Components...>::each(Func&& func) {
    using Invoker = typename _::each_invoker<
        typename std::decay<Func>::type, Components...>;
    flecs::entity_t system = build<Invoker>(std::forward<Func>(func), true);
    return flecs::system<Components...>(m_world, system);
}

template <typename ... Components>
template <typename Func>
inline observer<Components ...> observer_builder<Components...>::iter(Func&& func) {
    using Invoker = typename _::iter_invoker<
        typename std::decay<Func>::type, Components...>;
    flecs::entity_t observer = build<Invoker>(std::forward<Func>(func), false);
    return flecs::observer<Components...>(m_world, observer);
}

template <typename ... Components>
template <typename Func>
inline observer<Components ...> observer_builder<Components...>::each(Func&& func) {
    using Invoker = typename _::each_invoker<
        typename std::decay<Func>::type, Components...>;
    flecs::entity_t observer = build<Invoker>(std::forward<Func>(func), true);
    return flecs::observer<Components...>(m_world, observer);
}

}

#ifdef FLECS_DEPRECATED

namespace flecs
{

static ecs_entity_t Singleton = EcsSingleton;
static ecs_entity_t Childof = ECS_CHILDOF;
static ecs_entity_t Instanceof = ECS_INSTANCEOF;

}
#endif
#endif
#endif

#endif

#endif
