uintptr_t :: u64;
int8_t :: s8;
uint8_t :: u8;
int16_t :: s16;
uint16_t :: u16;
int32_t :: s32;
uint32_t :: u32;
int64_t :: s64;
uint64_t :: u64;
size_t :: u64;

FLECS_FLOAT :: float32;

ecs_flags32_t :: uint32_t;
ecs_flags64_t :: uint64_t;

/* Keep unsigned integers out of the codebase as they do more harm than good */
ecs_size_t :: int32_t;

// ////////////////////////////////////////////////////////////////////////////////
// //// Utilities for working with pair identifiers
// ////////////////////////////////////////////////////////////////////////////////

// ecs_entity_t_lo :: inline (value: ecs_entity_t) -> uint32_t {
//     return cast(uint32_t) value;
// }

// ecs_entity_t_hi :: inline (value: ecs_entity_t) -> uint32_t {
//     return cast(uint32_t) (value >> 32);
// }

// ecs_entity_t_comb :: inline (lo: ecs_entity_t, hi: ecs_entity_t ) -> uint64_t {
//     return (hi << 32) + lo;
// }

// ecs_pair :: (pred: ecs_entity_t, obj: ecs_entity_t) -> ecs_id_t {
//     return ECS_PAIR | ecs_entity_t_comb(obj, pred);
// }

// /* Get object from pair with the correct (current) generation count */
// ecs_pair_relation :: inline (world: *ecs_world_t, pair: ecs_id_t) -> ecs_id_t {
//     return ecs_get_alive(world, ECS_PAIR_RELATION(pair));
// }

// ecs_pair_object :: inline (world: *ecs_world_t, pair: ecs_id_t) {
//     return ecs_get_alive(world, ECS_PAIR_OBJECT(pair));
// }

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

// /*
//  * @file map.h
//  * @brief Map datastructure.
//  *
//  * Key-value datastructure. The map allows for fast retrieval of a payload for
//  * a 64-bit key. While it is not as fast as the sparse set, it is better at
//  * handling randomly distributed values.
//  *
//  * Payload is stored in bucket arrays. A bucket is computed from an id by
//  * using the (bucket_count - 1) as an AND-mask. The number of buckets is always
//  * a power of 2. Multiple keys will be stored in the same bucket. As a result
//  * the worst case retrieval performance of the map is O(n), though this is rare.
//  * On average lookup performance should equal O(1).
//  *
//  * The datastructure will automatically grow the number of buckets when the
//  * ratio between elements and buckets exceeds a certain threshold (LOAD_FACTOR).
//  *
//  * Note that while the implementation is a hashmap, it can only compute hashes
//  * for the provided 64 bit keys. This means that the provided keys must always
//  * be unique. If the provided keys are hashes themselves, it is the
//  * responsibility of the user to ensure that collisions are handled.
//  *
//  * In debug mode the map verifies that the type provided to the map functions
//  * matches the one used at creation time.
//  */

ecs_map_key_t :: uint64_t;

ecs_map_t :: struct {
    buckets: *ecs_bucket_t;
    elem_size: int32_t;
    bucket_count: int32_t;
    count: int32_t;
}

ecs_bucket_t :: struct {
    keys: *ecs_map_key_t;    /* Array with keys */
    payload: *void;          /* Payload array */
    count: int32_t;          /* Number of elements in bucket */
}

ecs_map_iter_t :: struct {
    map: *ecs_map_t;
    bucket: *ecs_bucket_t;
    bucket_index: int32_t;
    element_index: int32_t;
    payload: *void;
}

/*
 * @file hashmap.h
 * @brief Hashmap datastructure.
 *
 * Datastructure that computes a hash to store & retrieve values. Similar to
 * ecs_map_t, but allows for arbitrary keytypes.
 */

ecs_hashmap_t :: struct {
    hash: ecs_hash_value_action_t;
    compare: ecs_compare_value_action_t;
    key_size: ecs_size_t;
    value_size: ecs_size_t;
    impl: *ecs_map_t;
}

ecs_hashmap_iter_t :: struct {
    it: ecs_map_iter_t;
    bucket: *ecs_hm_bucket_t;
    index: int32_t;
}

ecs_hashmap_result_t :: struct {
    key: *void;
    value: *void;
    hash: uint64_t;
}

ecs_hm_bucket_t :: struct {
    keys: *ecs_vector_t;
    values: *ecs_vector_t;
}

/*
 * @file bitset.h
 * @brief Bitset datastructure.
 *
 * Simple bitset implementation. The bitset allows for storage of arbitrary
 * numbers of bits.
 */

ecs_bitset_t :: struct {
    data: *uint64_t;
    count: int32_t;
    size: ecs_size_t;
}

// /*
//  * @file strbuf.h
//  * @brief Utility for constructing strings.
//  *
//  * A buffer builds up a list of elements which individually can be up to N bytes
//  * large. While appending, data is added to these elements. More elements are
//  * added on the fly when needed. When an application calls ecs_strbuf_get, all
//  * elements are combined in one string and the element administration is freed.
//  *
//  * This approach prevents reallocs of large blocks of memory, and therefore
//  * copying large blocks of memory when appending to a large buffer. A buffer
//  * preallocates some memory for the element overhead so that for small strings
//  * there is hardly any overhead, while for large strings the overhead is offset
//  * by the reduced time spent on copying memory.
//  */

// ECS_STRBUF_INIT :: ecs_strbuf_t.{};
// ECS_STRBUF_ELEMENT_SIZE :: 511;
// ECS_STRBUF_MAX_LIST_DEPTH :: 32;

// ecs_strbuf_element :: struct {
//     buffer_embedded: bool;
//     pos: int32_t;
//     buf: *u8;
//     next: *ecs_strbuf_element;
// }

// ecs_strbuf_element_embedded :: struct {
//     super: ecs_strbuf_element;
//     buf: [ECS_STRBUF_ELEMENT_SIZE + 1] u8;
// }

// ecs_strbuf_element_str :: struct {
//     super: ecs_strbuf_element;
//     alloc_str: *u8;
// }

// ecs_strbuf_list_elem :: struct {
//     count: int32_t;
//     separator: *u8;
// }

// ecs_strbuf_t :: struct {
//     /* When set by an application, append will write to this buffer */
//     buf: *u8;

//     /* The maximum number of characters that may be printed */
//     max: int32_t;

//     /* Size of elements minus current element */
//     size: int32_t;

//     /* The number of elements in use */
//     elementCount: int32_t;

//     /* Always allocate at least one element */
//     firstElement: ecs_strbuf_element_embedded;

//     /* The current element being appended to */
//     current: *ecs_strbuf_element;

//     /* Stack that keeps track of number of list elements, used for conditionally
//      * inserting a separator */
//     list_stack: [ECS_STRBUF_MAX_LIST_DEPTH] ecs_strbuf_list_elem;
//     list_sp: int32_t;
// }

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

// /* Use handle types that _at least_ can store pointers */
ecs_os_thread_t :: uintptr_t;
ecs_os_cond_t :: uintptr_t;
ecs_os_mutex_t :: uintptr_t;
// ecs_os_dl_t :: uintptr_t;

// /* Generic function pointer type */
// ecs_os_proc_t :: #type ();

// /* OS API init */
// ecs_os_api_init_t :: #type ();

// /* OS API deinit */
// ecs_os_api_fini_t :: #type ();

// /* Memory management */
// ecs_os_api_malloc_t :: #type (
//     size: ecs_size_t);

// ecs_os_api_free_t :: #type (
//     ptr: *void);

// ecs_os_api_realloc_t :: #type (
//     ptr: *void,
//     size: ecs_size_t) -> *void;

// ecs_os_api_calloc_t :: #type (
//     size: ecs_size_t) -> *void;

// ecs_os_api_strdup_t :: #type (
//     str: *u8) -> *u8;

// /* Threads */
// ecs_os_thread_callback_t :: #type (
//     param: *void) -> *void;

// ecs_os_api_thread_new_t :: #type (
//     callback: ecs_os_thread_callback_t,
//     param: *void) -> ecs_os_thread_t;

// ecs_os_api_thread_join_t :: #type (
//     thread: ecs_os_thread_t) -> *void;

// /* Atomic increment / decrement */
// ecs_os_api_ainc_t :: #type (
//     value: *int32_t) -> int32_t;

// /* Mutex */
// ecs_os_api_mutex_new_t :: #type () -> ecs_os_mutex_t;

// ecs_os_api_mutex_lock_t :: #type (
//     mutex: ecs_os_mutex_t);

// ecs_os_api_mutex_unlock_t :: #type (
//     mutex: ecs_os_mutex_t);

// ecs_os_api_mutex_free_t :: #type (
//     mutex: ecs_os_mutex_t);

// /* Condition variable */
// ecs_os_api_cond_new_t :: #type () -> ecs_os_cond_t;

// ecs_os_api_cond_free_t :: #type (
//     cond: ecs_os_cond_t);

// ecs_os_api_cond_signal_t :: #type (
//     cond: ecs_os_cond_t);

// ecs_os_api_cond_broadcast_t :: #type (
//     cond: ecs_os_cond_t);

// ecs_os_api_cond_wait_t :: #type (
//     cond: ecs_os_cond_t,
//     mutex: ecs_os_mutex_t);

// ecs_os_api_sleep_t :: #type (
//     sec: int32_t,
//     nanosec: int32_t);

// ecs_os_api_get_time_t :: #type (
//     time_out: *ecs_time_t);

// /* Logging */
// ecs_os_api_log_t :: #type (
//     fmt: *u8,
//     args: va_list);

// /* Application termination */
// ecs_os_api_abort_t :: #type ();

// /* Dynamic libraries */
// ecs_os_api_dlopen_t :: #type (
//     libname: *u8) -> ecs_os_dl_t;

// ecs_os_api_dlproc_t :: #type (
//     lib: ecs_os_dl_t,
//     procname: *u8) -> ecs_os_proc_t;

// ecs_os_api_dlclose_t :: #type (
//     lib: ecs_os_dl_t);

// ecs_os_api_module_to_path_t :: #type (
//     module_id: *u8) -> *u8;

// /* Prefix members of struct with 'ecs_' as some system headers may define
//  * macro's for functions like "strdup", "log" or "_free" */

// ecs_os_api_t :: struct {
//     /* API init / deinit */
//     init_: ecs_os_api_init_t;
//     fini_: ecs_os_api_fini_t;

//     /* Memory management */
//     malloc_: ecs_os_api_malloc_t;
//     realloc_: ecs_os_api_realloc_t;
//     calloc_: ecs_os_api_calloc_t;
//     free_: ecs_os_api_free_t;

//     /* Strings */
//     strdup_: ecs_os_api_strdup_t;

//     /* Threads */
//     thread_new_: ecs_os_api_thread_new_t;
//     thread_join_: ecs_os_api_thread_join_t;

//     /* Atomic incremenet / decrement */
//     ainc_: ecs_os_api_ainc_t;
//     adec_: ecs_os_api_ainc_t;

//     /* Mutex */
//     mutex_new_: ecs_os_api_mutex_new_t;
//     mutex_free_: ecs_os_api_mutex_free_t;
//     mutex_lock_: ecs_os_api_mutex_lock_t;
//     mutex_unlock_: ecs_os_api_mutex_lock_t;

//     /* Condition variable */
//     cond_new_: ecs_os_api_cond_new_t;
//     cond_free_: ecs_os_api_cond_free_t;
//     cond_signal_: ecs_os_api_cond_signal_t;
//     cond_broadcast_: ecs_os_api_cond_broadcast_t;
//     cond_wait_: ecs_os_api_cond_wait_t;

//     /* Time */
//     sleep_: ecs_os_api_sleep_t;
//     get_time_: ecs_os_api_get_time_t;

//     /* Logging */
//     log_: ecs_os_api_log_t;
//     log_error_: ecs_os_api_log_t;
//     log_debug_: ecs_os_api_log_t;
//     log_warning_: ecs_os_api_log_t;

//     /* Application termination */
//     abort_: ecs_os_api_abort_t;

//     /* Dynamic library loading */
//     dlopen_: ecs_os_api_dlopen_t;
//     dlproc_: ecs_os_api_dlproc_t;
//     dlclose_: ecs_os_api_dlclose_t;

//     /* Overridable function that translates from a logical module id to a
//      * shared library filename */
//     module_to_dl_: ecs_os_api_module_to_path_t;

//     /* Overridable function that translates from a logical module id to a
//      * path that contains module-specif resources or assets */
//     module_to_etc_: ecs_os_api_module_to_path_t;
// }

// ecs_os_init :: () -> () #foreign flecs;
// ecs_os_fini :: () -> () #foreign flecs;

// ecs_os_get_api :: () -> ecs_os_api_t  #foreign flecs;
// ecs_os_set_api :: (os_api: *ecs_os_api_t) #foreign flecs;

// ecs_os_set_api_defaults :: () -> () #foreign flecs;

// /* Logging (use functions to avoid using variadic macro arguments) */
// ecs_os_log :: (fmt: *u8, args: ..Any) #foreign flecs;
// ecs_os_warn :: (fmt: *u8, args: ..Any) #foreign flecs;
// ecs_os_err :: (fmt: *u8, args: ..Any) #foreign flecs;
// ecs_os_dbg :: (fmt: *u8, args: ..Any) #foreign flecs;

// /* Sleep with floating point time */
// ecs_sleepf :: (t: float64) #foreign flecs;

// /* Measure time since provided timestamp */
// ecs_time_measure :: (start: *ecs_time_t) -> float64 #foreign flecs;

// /* Calculate difference between two timestamps */
// ecs_time_sub ::  (t1: ecs_time_t, t2: ecs_time_t) -> ecs_time_t #foreign flecs;

// /* Convert time value to a double */
// ecs_time_to_double :: (t: ecs_time_t) -> float64 #foreign flecs;

// ecs_os_memdup :: (src: *void, size: ecs_size_t) -> *void #foreign flecs;

// /* Are heap functions available? */
// ecs_os_has_heap :: () -> bool #foreign flecs;

// /* Are threading functions available? */
// ecs_os_has_threading :: () -> bool #foreign flecs;

// /* Are time functions available? */
// ecs_os_has_time :: () -> bool #foreign flecs;

// /* Are logging functions available? */
// ecs_os_has_logging :: () -> bool #foreign flecs;

// /* Are dynamic library functions available? */
// ecs_os_has_dl :: () -> bool #foreign flecs;

// /* Are module path functions available? */
// ecs_os_has_modules :: () -> bool #foreign flecs;

// /*
//  * @defgroup api_types Basic API types
//  * @{
//  */

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

ecs_store_t :: struct {
    /* Entity lookup */
    entity_index: *ecs_sparse_t; /* sparse<entity, ecs_record_t> */

    /* Table lookup by id */
    tables: *ecs_sparse_t; /* sparse<table_id, ecs_table_t> */

    /* Table lookup by hash */
    table_map: ecs_hashmap_t; /* hashmap<ecs_ids_t, ecs_table_t*> */

    /* Root table */
    root: ecs_table_t;
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

// /* A trigger reacts to events matching a single filter term */
// ecs_trigger_t :: struct {
//     term: ecs_term_t;            /* Term describing the trigger condition id */

//     /* Trigger events */
//     events: [ECS_TRIGGER_DESC_EVENT_COUNT_MAX] ecs_entity_t;
//     event_count: int32_t;

//     action: ecs_iter_action_t;   /* Callback */

//     ctx: *void;                  /* Callback context */
//     binding_ctx: *void;          /* Binding context (for language bindings) */

//     ctx_free: ecs_ctx_free_t;    /* Callback to free ctx */
//     binding_ctx_free: ecs_ctx_free_t; /* Callback to free binding_ctx */

//     entity: ecs_entity_t;        /* Entity associated with trigger */

//     id: uint64_t;                /* Internal id */
// }

// /* An observer reacts to events matching multiple filter terms */
// ecs_observer_t :: struct {
//     filter: ecs_filter_t;

//     /* Triggers created by observer (array size same as number of terms) */
//     triggers: *ecs_entity_t;

//     /* Observer events */
//     events: [ECS_TRIGGER_DESC_EVENT_COUNT_MAX] ecs_entity_t;
//     event_count: int32_t;

//     action: ecs_iter_action_t;   /* Callback */

//     ctx: *void;                  /* Callback context */
//     binding_ctx: *void;          /* Binding context (for language bindings) */

//     ctx_free: ecs_ctx_free_t;    /* Callback to free ctx */
//     binding_ctx_free: ecs_ctx_free_t; /* Callback to free binding_ctx */

//     entity: ecs_entity_t;        /* Entity associated with observer */

//     id: uint64_t;                /* Internal id */
// }

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

    iter: union {                /* Iterator specific data */
        parent: ecs_scope_iter_t;
        filter: ecs_filter_iter_t;
        query: ecs_query_iter_t;
        snapshot: ecs_snapshot_iter_t;
    };
}

// /* @} */

// /*
//  * @defgroup constants API constants
//  * @{
//  */

/* Maximum number of components to add/remove in a single operation */
ECS_MAX_ADD_REMOVE :: 32;

/* Maximum number of terms to set in static array of filter descriptor */
ECS_FILTER_DESC_TERM_ARRAY_MAX :: 16;

/* Maximum number of events to set in static array of trigger descriptor */
ECS_TRIGGER_DESC_EVENT_COUNT_MAX :: 8;

// /* @} */

// /*
//  * @defgroup function_types Function Types
//  * @{
//  */

/* Action callback for systems and triggers */
ecs_iter_action_t :: #type (
    it: *ecs_iter_t) #c_call;

ecs_iter_next_action_t :: #type (
    it: *ecs_iter_t) -> bool #c_call;

/* Callback used for ranking types */
ecs_rank_type_action_t :: #type (
    world: *ecs_world_t,
    rank_component: ecs_entity_t,
    type: ecs_type_t) -> int32_t #c_call;

/* Initialization action for modules */
ecs_module_action_t :: #type (
    world: *ecs_world_t) #c_call;

/* Action callback on world exit */
ecs_fini_action_t :: #type (
    world: *ecs_world_t,
    ctx: *void) #c_call;

/* Function to cleanup context data */
ecs_ctx_free_t :: #type (
    ctx: *void) #c_call;

/* Callback used for sorting values */
ecs_compare_value_action_t :: #type (
    ptr1: *void,
    ptr2: *void) -> s32 #c_call;

/* Callback used for hashing values */
ecs_hash_value_action_t :: #type (
    ptr: *void) -> uint64_t #c_call;

/* Callback used for sorting components */
ecs_compare_action_t :: #type (
    e1: ecs_entity_t,
    ptr1: *void,
    e2: ecs_entity_t,
    ptr2: *void) -> s32 #c_call;

// /* @} */

// /*
//  * @defgroup filter_types Types used to describe filters, terms and triggers
//  * @{
//  */

// /* Set flags describe if & how a matched entity should be substituted */
// EcsDefaultSet   :: 0;  /* Default set, SuperSet|Self for This subject */
// EcsSelf         :: 1;  /* Select self (inclusive) */
// EcsSuperSet     :: 2;  /* Select superset until predicate match */
// EcsSubSet       :: 4;  /* Select subset until predicate match */
// EcsCascade      :: 8;  /* Use breadth-first ordering of relations */
// EcsAll          :: 16; /* Walk full super/subset, regardless of match */
// EcsNothing      :: 32; /* Select from nothing */

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
    EcsMatchDefault;
    EcsMatchAll;
    EcsMatchAny;
    EcsMatchExact;
}

// /* @} */

// /*
//  * @file api_types.h
//  * @brief Supporting types for the public API.
//  *
//  * This file contains types that are typically not used by an application but
//  * support the public API, and therefore must be exposed. This header should not
//  * be included by itself.
//  */

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
}

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
}

/* Component-specific data */
ecs_type_info_t :: struct {
    component: ecs_entity_t;
    lifecycle: EcsComponentLifecycle; /* Component lifecycle callbacks */
    lifecycle_set: bool;
}

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

/* A switch column. */
ecs_sw_column_t :: struct {
    data: *ecs_switch_t;   /* Column data */
    type: ecs_type_t;      /* Switch type */
}

/* A bitset column. */
ecs_bs_column_t :: struct {
    data: ecs_bitset_t;   /* Column data */
}

/* Table data */
ecs_data_t :: struct {
    entities: *ecs_vector_t;      /* Entity identifiers */
    record_ptrs: *ecs_vector_t;   /* Ptrs to records in main entity index */
    columns: *ecs_column_t;       /* Component columns */
    sw_columns: *ecs_sw_column_t; /* Switch columns */
    bs_columns: *ecs_bs_column_t; /* Bitset columns */
};

/* Edge used for traversing the table graph. */
ecs_edge_t :: struct {
    add_: *ecs_table_t;               /* Edges traversed when adding */
    remove_: *ecs_table_t;            /* Edges traversed when removing */
}

/* Component monitor */
ecs_monitor_t :: struct {
    queries: *ecs_vector_t;  /* vector<ecs_query_t*> */
    is_dirty: bool;          /* Should queries be rematched? */
}

/* Component monitors */
ecs_monitor_set_t :: struct {
    monitors: *ecs_map_t; /* map<id, ecs_monitor_t> */
    is_dirty: bool;       /* Should monitors be evaluated? */
}

/* Relation monitors. TODO: implement generic monitor mechanism */
ecs_relation_monitor_t :: struct {
    monitor_sets: *ecs_map_t; /* map<relation_id, ecs_monitor_set_t> */
    is_dirty: bool;          /* Should monitor sets be evaluated? */
}

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
}

// /*
//  * @file switch_list.h
//  * @brief Interleaved linked list for storing mutually exclusive values.
//  *
//  * Datastructure that stores N interleaved linked lists in an array.
//  * This allows for efficient storage of elements with mutually exclusive values.
//  * Each linked list has a header element which points to the index in the array
//  * that stores the first node of the list. Each list node points to the next
//  * array element.
//  *
//  * The datastructure needs to be created with min and max values, so that it can
//  * allocate an array of headers that can be directly indexed by the value. The
//  * values are stored in a contiguous array, which allows for the values to be
//  * iterated without having to follow the linked list nodes.
//  *
//  * The datastructure allows for efficient storage and retrieval for values with
//  * mutually exclusive values, such as enumeration values. The linked list allows
//  * an application to obtain all elements for a given (enumeration) value without
//  * having to search.
//  *
//  * While the list accepts 64 bit values, it only uses the lower 32bits of the
//  * value for selecting the correct linked list.
//  */

ecs_switch_header_t :: struct {
    element: int32_t;        /* First element for value */
    count: int32_t;          /* Number of elements for value */
}

// ecs_switch_node_t :: struct {
//     next: int32_t;           /* Next node in list */
//     prev: int32_t;           /* Prev node in list */
// }

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
    record: *ecs_record_t;      /* Pointer to record, if in main stage */
    ptr: *void;                 /* Cached ptr */
};

/* Array of entity ids that, other than a type, can live on the stack */
ecs_ids_t :: struct {
    array: *ecs_entity_t;    /* An array with entity ids */
    count: int32_t;          /* The number of entities in the array */
}

// ecs_page_cursor_t :: struct {
//     first: int32_t;
//     count: int32_t;
// }

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
}

// EcsMatchFailureReason :: enum {
//     EcsMatchOk;
//     EcsMatchNotASystem;
//     EcsMatchSystemIsATask;
//     EcsMatchEntityIsDisabled;
//     EcsMatchEntityIsPrefab;
//     EcsMatchFromSelf;
//     EcsMatchFromOwned;
//     EcsMatchFromShared;
//     EcsMatchFromContainer;
//     EcsMatchFromEntity;
//     EcsMatchOrFromSelf;
//     EcsMatchOrFromOwned;
//     EcsMatchOrFromShared;
//     EcsMatchOrFromContainer;
//     EcsMatchNotFromSelf;
//     EcsMatchNotFromOwned;
//     EcsMatchNotFromShared;
//     EcsMatchNotFromContainer;
// }

// ecs_match_failure_t :: struct {
//     reason: EcsMatchFailureReason;
//     column: int32_t;
// }

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
    ctx: *void) #c_call;

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
    ctx: *void) #c_call;

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
    ctx: *void) #c_call;

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
    ctx: *void) #c_call;

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
    ctx: *void) #c_call;

// /*
//  * @file api_support.h
//  * @brief Support functions and constants.
//  *
//  * Supporting types and functions that need to be exposed either in support of
//  * the public API or for unit tests, but that may change between minor / patch
//  * releases.
//  */

/* This reserves entity ids for components. Regular entity ids will start after
 * this constant. This affects performance of table traversal, as edges with ids
 * lower than this constant are looked up in an array, whereas constants higher
 * than this id are looked up in a map. Increasing this value can improve
 * performance at the cost of (significantly) higher memory usage. */
ECS_HI_COMPONENT_ID : ecs_entity_t : 256; /* Maximum number of components */

// /* The maximum number of nested function calls before the core will throw a
//  * cycle detected error */
// ECS_MAX_RECURSION :: 512;

// ////////////////////////////////////////////////////////////////////////////////
// //// Global type handles
// ////////////////////////////////////////////////////////////////////////////////

// /* Type handles to builtin components */
// FLECS__TEcsComponent: ecs_type_t;
// FLECS__TEcsComponentLifecycle: ecs_type_t;
// FLECS__TEcsType: ecs_type_t;
// FLECS__TEcsName: ecs_type_t;

// /* This allows passing 0 as type to functions that accept types */
// FLECS__TNULL :: 0;
// FLECS__T0 :: 0;
// FLECS__E0 :: 0;

// ////////////////////////////////////////////////////////////////////////////////
// //// Functions used in declarative (macro) API
// ////////////////////////////////////////////////////////////////////////////////

// ecs_new_module :: (
//     world: *ecs_world_t,
//     e: ecs_entity_t,
//     name: *u8,
//     size: size_t,
//     alignment: size_t) -> ecs_entity_t #foreign flecs;

// ecs_module_path_from_c :: (
//     c_name: *u8) -> *u8 #foreign flecs;

// ecs_component_has_actions :: (
//     world: *ecs_world_t,
//     component: ecs_entity_t) -> bool #foreign flecs;

// ecs_add_module_tag :: (
//     world: *ecs_world_t,
//     module: ecs_entity_t) #foreign flecs;

// /*
//  * @file log.h
//  * @brief Internal logging API.
//  *
//  * Internal utility functions for tracing, warnings and errors.
//  */

////////////////////////////////////////////////////////////////////////////////
//// Signature API
////////////////////////////////////////////////////////////////////////////////

// ecs_identifier_is_0 :: (
//     id: *u8) -> bool;

// ecs_identifier_is_var :: (
//     id: *u8) -> bool;

ECS_INVALID_OPERATION               :: 1;
ECS_INVALID_PARAMETER               :: 2;
ECS_INVALID_DELETE                  :: 3;
ECS_OUT_OF_MEMORY                   :: 4;
ECS_OUT_OF_RANGE                    :: 5;
ECS_UNSUPPORTED                     :: 6;
ECS_INTERNAL_ERROR                  :: 7;
ECS_ALREADY_DEFINED                 :: 8;
ECS_MISSING_OS_API                  :: 9;
ECS_THREAD_ERROR                    :: 10;
ECS_CYCLE_DETECTED                  :: 11;

ECS_INCONSISTENT_NAME               :: 20;
ECS_NAME_IN_USE                     :: 21;
ECS_NOT_A_COMPONENT                 :: 22;
ECS_INVALID_COMPONENT_SIZE          :: 23;
ECS_INVALID_COMPONENT_ALIGNMENT     :: 24;
ECS_COMPONENT_NOT_REGISTERED        :: 25;
ECS_INCONSISTENT_COMPONENT_ID       :: 26;
ECS_INCONSISTENT_COMPONENT_ACTION   :: 27;
ECS_MODULE_UNDEFINED                :: 28;

ECS_COLUMN_ACCESS_VIOLATION         :: 40;
ECS_COLUMN_INDEX_OUT_OF_RANGE       :: 41;
ECS_COLUMN_IS_NOT_SHARED            :: 42;
ECS_COLUMN_IS_SHARED                :: 43;
ECS_COLUMN_HAS_NO_DATA              :: 44;
ECS_COLUMN_TYPE_MISMATCH            :: 45;
ECS_NO_OUT_COLUMNS                  :: 46;

ECS_TYPE_NOT_AN_ENTITY              :: 60;
ECS_TYPE_CONSTRAINT_VIOLATION       :: 61;
ECS_TYPE_INVALID_CASE               :: 62;

ECS_INVALID_WHILE_ITERATING         :: 70;
ECS_LOCKED_STORAGE                  :: 71;
ECS_INVALID_FROM_WORKER             :: 72;

ECS_DESERIALIZE_FORMAT_ERROR        :: 80;

// ////////////////////////////////////////////////////////////////////////////////
// //// Color macro's
// ////////////////////////////////////////////////////////////////////////////////

// // ECS_BLACK   :: "\033[1;30m"
// // ECS_RED     :: "\033[0;31m"
// // ECS_GREEN   :: "\033[0;32m"
// // ECS_YELLOW  :: "\033[0;33m"
// // ECS_BLUE    :: "\033[0;34m"
// // ECS_MAGENTA :: "\033[0;35m"
// // ECS_CYAN    :: "\033[0;36m"
// // ECS_WHITE   :: "\033[1;37m"
// // ECS_GREY    :: "\033[0;37m"
// // ECS_NORMAL  :: "\033[0;49m"
// // ECS_BOLD    :: "\033[1;49m"

// ////////////////////////////////////////////////////////////////////////////////
// //// Exceptions
// ////////////////////////////////////////////////////////////////////////////////

// /* Get description for error code */
// ecs_strerror :: (error_code: int32_t) -> *u8 #foreign flecs;

// /* Abort */
// _ecs_abort :: (
//     error_code: int32_t,
//     param: *u8,
//     file: *u8,
//     line: int32_t) #foreign flecs;

// ecs_abort :: inline (error_code: int32_t, param: *u8, loc := #caller_location) {
//     _ecs_abort(error_code, param, loc.fully_pathed_filename, loc.line_number);
// }

/* Assert */
_ecs_assert :: (
    condition: bool,
    error_code: int32_t,
    param: *u8,
    condition_str: *u8,
    file: *u8,
    line: int32_t) #foreign flecs;

ecs_assert :: (condition: bool, error_code: int32_t, param: *u8, loc := #caller_location) {
    _ecs_assert(condition, error_code, param, "", toCString(loc.fully_pathed_filename), cast(int32_t) loc.line_number);
    assert(condition);
}

// _ecs_parser_error :: (
//     name: *u8,
//     expr: *u8,
//     column: int64_t,
//     fmt: *u8,
//     args: ..Any) #foreign flecs;

// ecs_parser_error :: inline (name: *u8, expr: *u8, column: int64_t, fmt: *u8, args: ..Any) {
//     _ecs_parser_error(name, expr, column, fmt, args);
// }

// /*
//  * @file type.h
//  * @brief Type API.
//  *
//  * This API contains utilities for working with types. Types are vectors of
//  * component ids, and are used most prominently in the API to construct filters.
//  */

// ecs_type_from_id :: (
//     world: *ecs_world_t,
//     entity: ecs_entity_t) -> ecs_type_t #foreign flecs;

// ecs_type_to_id :: (
//     world: *ecs_world_t,
//     type: ecs_type_t) -> ecs_entity_t #foreign flecs;

// ecs_type_str :: (
//     world: *ecs_world_t,
//     type: ecs_type_t) -> *u8 #foreign flecs;

// ecs_type_from_str :: (
//     world: *ecs_world_t,
//     expr: *u8) -> ecs_type_t #foreign flecs;

// ecs_type_find :: (
//     world: *ecs_world_t,
//     array: *ecs_entity_t,
//     count: int32_t) -> ecs_type_t #foreign flecs;

// ecs_type_merge :: (
//     world: *ecs_world_t,
//     type: ecs_type_t,
//     type_add: ecs_type_t,
//     type_remove: ecs_type_t) -> ecs_type_t #foreign flecs;

// ecs_type_add :: (
//     world: *ecs_world_t,
//     type: ecs_type_t,
//     entity: ecs_entity_t) -> ecs_type_t #foreign flecs;

// ecs_type_remove :: (
//     world: *ecs_world_t,
//     type: ecs_type_t,
//     entity: ecs_entity_t) -> ecs_type_t #foreign flecs;

// ecs_type_has_id :: (
//     world: *ecs_world_t,
//     type: ecs_type_t,
//     entity: ecs_entity_t) -> bool #foreign flecs;

// ecs_type_has_type :: (
//     world: *ecs_world_t,
//     type: ecs_type_t,
//     has: ecs_type_t) -> bool #foreign flecs;

// ecs_type_owns_id :: (
//     world: *ecs_world_t,
//     type: ecs_type_t,
//     entity: ecs_entity_t,
//     owned: bool) -> bool #foreign flecs;

// ecs_type_owns_type :: (
//     world: *ecs_world_t,
//     type: ecs_type_t,
//     has: ecs_type_t,
//     owned: bool) -> bool #foreign flecs;

// ecs_type_find_id :: (
//     world: *ecs_world_t,
//     type: ecs_type_t,
//     id: ecs_entity_t,
//     rel: ecs_entity_t,
//     min_depth: int32_t,
//     max_depth: int32_t,
//     out: *ecs_entity_t) -> bool #foreign flecs;

// ecs_type_get_entity_for_xor :: (
//     world: *ecs_world_t,
//     type: ecs_type_t,
//     xor_tag: ecs_entity_t) -> ecs_entity_t #foreign flecs;

// ecs_type_index_of :: (
//     type: ecs_type_t,
//     component: ecs_entity_t) -> int32_t #foreign flecs;

// ecs_type_match :: (
//     type: ecs_type_t,
//     start_index: int32_t,
//     pair: ecs_entity_t) -> int32_t #foreign flecs;

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
    add_ids: [ECS_MAX_ADD_REMOVE] ecs_id_t;

    /* Array of ids to remove from the existing entity. */
    remove_ids: [ECS_MAX_ADD_REMOVE] ecs_id_t;

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

// /* Used with ecs_type_init. */
// ecs_type_desc_t :: struct {
//     entity: ecs_entity_desc_t;          /* Parameters for type entity */
//     ids: [ECS_MAX_ADD_REMOVE] ecs_id_t; /* Ids to include in type */
//     ids_expr: *u8;                      /* Id expression to include in type */
// }

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

// /* Used with ecs_observer_init. */
// ecs_observer_desc_t :: struct {
//     /* Entity to associate with observer */
//     entity: ecs_entity_desc_t;

//     /* Filter for observer */
//     filter: ecs_filter_desc_t;

//     /* Events to observe (OnAdd, OnRemove, OnSet, UnSet) */
//     events: [ECS_TRIGGER_DESC_EVENT_COUNT_MAX] ecs_entity_t;

//     /* Callback to invoke on an event */
//     callback: ecs_iter_action_t;

//     /* User context to pass to callback */
//     ctx: *void;

//     /* Context to be used for language bindings */
//     binding_ctx: *void;

//     /* Callback to free ctx */
//     ctx_free: ecs_ctx_free_t;

//     /* Callback to free binding_ctx */
//     binding_ctx_free: ecs_ctx_free_t;
// }

// /* @} */

// /*
//  * @defgroup builtin_components Builtin components
//  * @{
//  */

// /* Entity name. */
// EcsName :: struct {
//     value: *u8;                 /* Entity name */
//     symbol: *u8;                /* Optional symbol name, if it differs from name */
//     alloc_value: *u8;           /* If set, value will be freed on destruction */
// }

// /* Component information. */
// EcsComponent :: struct {
//     size: ecs_size_t;           /* Component size */
//     alignment: ecs_size_t;      /* Component alignment */
// }

// /* Component that stores an ecs_type_t.
//  * This component allows for the creation of entities that represent a type, and
//  * therefore the creation of named types. This component is typically
//  * instantiated by ECS_TYPE. */
// EcsType :: struct {
//     type: ecs_type_t;        /* Preserved nested types */
//     normalized: ecs_type_t;  /* Union of type and nested AND types */
// }

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

// /* Component that stores reference to trigger */
// EcsTrigger :: struct {
//     trigger: *ecs_trigger_t;
// }

// /* Component that stores reference to observer */
// EcsObserver :: struct {
//     observer: *ecs_observer_t;
// }

// /* Component for storing a query */
// EcsQuery :: struct {
//     query: *ecs_query_t;
// }

// /* @} */

// /*
//  * @defgroup misc_types Miscalleneous types
//  * @{
//  */

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

// /* @} */

// /*
//  * @defgroup type_roles Type Roles
//  * @{
//  */

// /* Type roles are used to indicate the role of an entity in a type. If no flag
//  * is specified, the entity is interpreted as a regular component or tag. Flags
//  * are added to an entity by using a bitwise OR (|). An example:
//  *
//  * ecs_entity_t parent = ecs_new(world, 0);
//  * ecs_entity_t child = ecs_add_pair(world, e, EcsChildOf, parent);
//  *
//  * Type flags can also be used in type expressions, without the ECS prefix:
//  *
//  * ECS_ENTITY(world, Base, Position);
//  * ECS_TYPE(world, InstanceOfBase, INSTANCEOF | Base);
//  */

// /* Role bit added to roles to differentiate between roles and generations */
// ECS_ROLE :: cast(u64) 1 << 63;

// /* Cases are used to switch between mutually exclusive components */
// ECS_CASE: ecs_id_t;

// /* Switches allow for fast switching between mutually exclusive components */
// ECS_SWITCH: ecs_id_t;

// /* The PAIR role indicates that the entity is a pair identifier. */
// ECS_PAIR: ecs_id_t;

// /* Enforce ownership of a component */
// ECS_OWNED: ecs_id_t;

// /* Track whether component is enabled or not */
// ECS_DISABLED: ecs_id_t;

// /* @} */

// /*
//  * @defgroup builtin_tags Builtin Tags
//  * @{
//  */

// /* Root scope for builtin flecs entities */
// EcsFlecs: ecs_entity_t;

// /* Core module scope */
// EcsFlecsCore: ecs_entity_t;

// /* Entity associated with world (used for "attaching" components to world) */
// EcsWorld: ecs_entity_t;

// /* Wildcard entity ("*"), Used in expressions to indicate wildcard matching */
// EcsWildcard: ecs_entity_t;

// /* This entity (".", "This"). Used in expressions to indicate This entity */
// EcsThis: ecs_entity_t;

// /* Can be added to relation to indicate it is transitive. */
// EcsTransitive: ecs_entity_t;

// /* Can be added to component/relation to indicate it is final. Final components/
//  * relations cannot be derived from using an IsA relationship. Queries will not
//  * attempt to substitute a component/relationship with IsA subsets if they are
//  * final. */
// EcsFinal: ecs_entity_t;

// /* Can be added to relation to indicate that it should never hold data, even
//  * when it or the relation object is a component. */
// EcsTag: ecs_entity_t;

// /* Used to express parent-child relations. */
// EcsChildOf: ecs_entity_t;

// /* Used to express is-a relations. An IsA relation indicates that the subject is
//  * a subset of the relation object. For example:
//  *   ecs_add_pair(world, Freighter, EcsIsA, SpaceShip);
//  *
//  * Here the Freighter is considered a subset of SpaceShip, meaning that every
//  * entity that has Freighter also implicitly has SpaceShip.
//  *
//  * The subject of the relation (Freighter) inherits all components from any IsA
//  * object (SpaceShip). If SpaceShip has a component "MaxSpeed", this component
//  * will also appear on Freighter after adding (IsA, SpaceShip) to Freighter.
//  *
//  * The IsA relation is transitive. This means that if SpaceShip IsA Machine,
//  * then Freigther is also a Machine. As a result, Freighter also inherits all
//  * components from Machine, just as it does from SpaceShip.
//  *
//  * Queries/filters may implicitly substitute predicates, subjects and objects
//  * with their IsA super/subsets. This behavior can be controlled by the "set"
//  * member of a query term.
//  */
// EcsIsA: ecs_entity_t;

// /* Tag added to module entities */
// EcsModule: ecs_entity_t;

// /* Tag added to prefab entities. Any entity with this tag is automatically
//  * ignored by filters/queries, unless EcsPrefab is explicitly added. */
// EcsPrefab: ecs_entity_t;

// /* When this tag is added to an entity it is skipped by all queries/filters */
// EcsDisabled: ecs_entity_t;

// /* Tag added to builtin/framework entites. This tag can be used to automatically
//  * hide components/systems that are part of infrastructure code vs. application
//  * code. The tag has no functional implications. */
// EcsHidden: ecs_entity_t;

/* Used to create triggers that subscribe on add events */
EcsOnAdd: ecs_entity_t = (ECS_HI_COMPONENT_ID + 26);

/* Used to create triggers that subscribe on remove events */
EcsOnRemove: ecs_entity_t = (ECS_HI_COMPONENT_ID + 27);

/* Used to create systems that subscribe on set events */
EcsOnSet: ecs_entity_t = (ECS_HI_COMPONENT_ID + 28);

/* Used to create systems that subscribe on unset events */
EcsUnSet: ecs_entity_t = (ECS_HI_COMPONENT_ID + 29);;

// /* Relationship used to define what should happen when an entity is deleted that
//  * is added to other entities. For example, if an entity is used as a tag, and
//  * this entity is deleted, this would leave dangling references (ids) to this
//  * entity in the storage.
//  * This relation, when combined with EcsRemove, EcsDelete or EcsThrow, can be
//  * used to customize the deletion behavior. For example:
//  *   ecs_add_pair(world, Position, EcsOnDelete, EcsThrow);
//  *
//  * This would throw an error when attempting to delete Position, if Position is
//  * added to any entities at the time of deletion. */
// EcsOnDelete: ecs_entity_t;

// /* Relationship with similar functionality to EcsDelete, except that it allows
//  * for specifying behavior when an object of a relation is removed. For example:
//  *   ecs_add_pair(world, EcsChildOf, EcsOnDeleteObject, EcsDelete);
//  *
//  * This specifies that whenever an object of a ChildOf relation (the parent) is
//  * removed, the entities with a relation to that object (the children) should be
//  * deleted. */
// EcsOnDeleteObject: ecs_entity_t;

// /* Specifies that a component/relation/object of relation should be removed when
//  * it is deleted. Must be combined with EcsOnDelete or EcsOnDeleteObject. */
// EcsRemove: ecs_entity_t;

// /* Specifies that entities with a component/relation/object of relation should
//  * be deleted when the component/relation/object of relation is deleted. Must be
//  * combined with EcsOnDelete or EcsOnDeleteObject. */
// EcsDelete: ecs_entity_t;

// /* Specifies that whenever a component/relation/object of relation is deleted an
//  * error should be thrown. Must be combined with EcsOnDelete or
//  * EcsOnDeleteObject. */
// EcsThrow: ecs_entity_t;

// /* System module tags */
// EcsOnDemand: ecs_entity_t;
// EcsMonitor: ecs_entity_t;
// EcsDisabledIntern: ecs_entity_t;
// EcsInactive: ecs_entity_t;

// /* Pipeline module tags */
// EcsPipeline: ecs_entity_t;
// EcsPreFrame: ecs_entity_t;
// EcsOnLoad: ecs_entity_t;
// EcsPostLoad: ecs_entity_t;
// EcsPreUpdate: ecs_entity_t;
EcsOnUpdate: ecs_entity_t = (ECS_HI_COMPONENT_ID + 49);
// EcsOnValidate: ecs_entity_t;
// EcsPostUpdate: ecs_entity_t;
// EcsPreStore: ecs_entity_t;
// EcsOnStore: ecs_entity_t;
// EcsPostFrame: ecs_entity_t;

// /* Value used to quickly check if component is builtin. This is used to quickly
//  * filter out tables with builtin components (for example for ecs_delete) */
// EcsLastInternalComponentId :: ecs_id(EcsSystem);

// /* The first user-defined component starts from this id. Ids up to this number
//  * are reserved for builtin components */
// EcsFirstUserComponentId :: 32;

// /* The first user-defined entity starts from this id. Ids up to this number
//  * are reserved for builtin components */
// EcsFirstUserEntityId :: ECS_HI_COMPONENT_ID + 64;

// /* @} */

// /*
//  * @defgroup convenience_macros Convenience Macro's
//  * @{
//  */

// /* Declare a component.
//  * Example:
//  *   ECS_COMPONENT(world, Position);
//  */
// ECS_COMPONENT :: (world: *ecs_world_t, $T: Type) -> ecs_type_t {
//     name := #run getStructName(T);
//     c_name := toCString(name);
//     return ecs_component_init(world, .{
//         entity = .{
//             name = c_name,
//             symbol = c_name
//         },
//         size = size_of(T),
//         alignment = 8 // ECS_ALIGNOF(id)
//     });
// }

// /* Declare a tag.
//  * Example:
//  *   ECS_TAG(world, MyTag);
//  */
// ECS_TAG :: (world: *ecs_world_t, $T: Type) -> ecs_entity_t {
//     name := #run getStructName(T);
//     c_name := toCString(name);
//     return ecs_entity_init(world, .{
//         name = c_name
//     });
// }

// /* @} */

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
ecs_mini :: () -> *ecs_world_t #foreign flecs;

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

// /* Register action to be executed when world is destroyed.
//  * Fini actions are typically used when a module needs to clean up before a
//  * world shuts down.
//  *
//  * @param world The world.
//  * @param action The function to execute.
//  * @param ctx Userdata to pass to the function */
// ecs_atfini :: (
//     world: *ecs_world_t,
//     action: ecs_fini_action_t,
//     ctx: *void) #foreign flecs;

// /* Register action to be executed once after frame.
//  * Post frame actions are typically used for calling operations that cannot be
//  * invoked during iteration, such as changing the number of threads.
//  *
//  * @param world The world.
//  * @param action The function to execute.
//  * @param ctx Userdata to pass to the function */
// ecs_run_post_frame :: (
//     world: *ecs_world_t,
//     action:ecs_fini_action_t,
//     ctx: *void) #foreign flecs;

// /* Signal exit
//  * This operation signals that the application should quit. It will cause
//  * ecs_progress to return false.
//  *
//  * @param world The world to quit.
//  */
// ecs_quit :: (
//     world: *ecs_world_t) #foreign flecs;

// /* Return whether a quit has been signaled.
//  *
//  * @param world The world.
//  */
// ecs_should_quit :: (
//     world: *ecs_world_t) -> bool #foreign flecs;

// /* Register ctor, dtor, copy & move actions for component.
//  *
//  * @param world The world.
//  * @param component The component id for which to register the actions
//  * @param actions Type that contains the component actions.
//  */
// ecs_set_component_actions_w_id :: (
//     world: *ecs_world_t,
//     id: ecs_id_t,
//     actions: *EcsComponentLifecycle) #foreign flecs;

// /* Set a world context.
//  * This operation allows an application to register custom data with a world
//  * that can be accessed anywhere where the application has the world object.
//  *
//  * @param world The world.
//  * @param ctx A pointer to a user defined structure.
//  */
// ecs_set_context ::(
//     world: *ecs_world_t,
//     ctx: *void) #foreign flecs;

// /* Get the world context.
//  * This operation retrieves a previously set world context.
//  *
//  * @param world The world.
//  * @return The context set with ecs_set_context. If no context was set, the
//  *         function returns NULL.
//  */
// ecs_get_context :: (
//     world: *ecs_world_t) -> *void #foreign flecs;

// /* Get world info.
//  *
//  * @param world The world.
//  * @return Pointer to the world info. This pointer will remain valid for as long
//  *         as the world is valid.
//  */
// ecs_get_world_info :: (
//     world: *ecs_world_t) -> *ecs_world_info_t #foreign flecs;

// /* Dimension the world for a specified number of entities.
//  * This operation will preallocate memory in the world for the specified number
//  * of entities. Specifying a number lower than the current number of entities in
//  * the world will have no effect. Note that this function does not allocate
//  * memory for components (use ecs_dim_type for that).
//  *
//  * @param world The world.
//  * @param entity_count The number of entities to preallocate.
//  */
// ecs_dim :: (
//     world: *ecs_world_t,
//     entity_count: int32_t) #foreign flecs;

// /* Set a range for issueing new entity ids.
//  * This function constrains the entity identifiers returned by ecs_new to the
//  * specified range. This operation can be used to ensure that multiple processes
//  * can run in the same simulation without requiring a central service that
//  * coordinates issueing identifiers.
//  *
//  * If id_end is set to 0, the range is infinite. If id_end is set to a non-zero
//  * value, it has to be larger than id_start. If id_end is set and ecs_new is
//  * invoked after an id is issued that is equal to id_end, the application will
//  * abort.
//  *
//  * @param world The world.
//  * @param id_start The start of the range.
//  * @param id_end The end of the range.
//  */
// ecs_set_entity_range :: (
//     world: *ecs_world_t,
//     id_start: ecs_entity_t,
//     id_end: ecs_entity_t) #foreign flecs;

// /* Enable/disable range limits.
//  * When an application is both a receiver of range-limited entities and a
//  * producer of range-limited entities, range checking needs to be temporarily
//  * disabled when inserting received entities. Range checking is disabled on a
//  * stage, so setting this value is thread safe.
//  *
//  * @param world The world.
//  * @param enable True if range checking should be enabled, false to disable.
//  * @return The previous value.
//  */
// ecs_enable_range_check :: (
//     world: *ecs_world_t,
//     enable: bool) -> bool #foreign flecs;

// /* Enable world locking while in progress.
//  * When locking is enabled, Flecs will lock the world while in progress. This
//  * allows applications to interact with the world from other threads without
//  * running into race conditions.
//  *
//  * This is a better alternative to applications putting a lock around calls to
//  * ecs_progress, since ecs_progress can sleep when FPS control is enabled,
//  * which is time during which other threads could perform work.
//  *
//  * Locking must be enabled before applications can use the ecs_lock and
//  * ecs_unlock functions. Locking is turned off by default.
//  *
//  * @param world The world.
//  * @param enable True if locking is to be enabled.
//  * @result The previous value of the setting.
//  */
// ecs_enable_locking :: (
//     world: *ecs_world_t,
//     enable: bool) -> bool #foreign flecs;

// /* Locks the world.
//  * See ecs_enable_locking for details.
//  *
//  * @param world The world.
//  */
// ecs_lock :: (
//     world: *ecs_world_t) #foreign flecs;

// /* Unlocks the world.
//  * See ecs_enable_locking for details.
//  *
//  * @param world The world.
//  */
// ecs_unlock :: (
//     world: *ecs_world_t) #foreign flecs;

// /* Wait until world becomes available.
//  * When a non-flecs thread needs to interact with the world, it should invoke
//  * this function to wait until the world becomes available (as in, it is not
//  * progressing the frame). Invoking this function guarantees that the thread
//  * will not starve. (as opposed to simply taking the world lock).
//  *
//  * An application will have to invoke ecs_end_wait after this function returns.
//  *
//  * @param world The world.
//  */
// ecs_begin_wait :: (
//     world: *ecs_world_t) #foreign flecs;

// /* Release world after calling ecs_begin_wait.
//  * This operation should be invoked after invoking ecs_begin_wait, and will
//  * release the world back to the thread running the main loop.
//  *
//  * @param world The world.
//  */
// ecs_end_wait :: (
//     world: *ecs_world_t) #foreign flecs;

// /* Enable or disable tracing.
//  * This will enable builtin tracing. For tracing to work, it will have to be
//  * compiled in which requires defining one of the following macro's:
//  *
//  * ECS_TRACE_0 - All tracing is disabled
//  * ECS_TRACE_1 - Enable tracing level 1
//  * ECS_TRACE_2 - Enable tracing level 2 and below
//  * ECS_TRACE_3 - Enable tracing level 3 and below
//  *
//  * If no tracing level is defined and this is a debug build, ECS_TRACE_3 will
//  * have been automatically defined.
//  *
//  * The provided level corresponds with the tracing level. If -1 is provided as
//  * value, warnings are disabled. If -2 is provided, errors are disabled as well.
//  *
//  * @param level Desired tracing level.
//  */
// ecs_tracing_enable :: (
//     level: s32) #foreign flecs;

// /* Measure frame time.
//  * Frame time measurements measure the total time passed in a single frame, and
//  * how much of that time was spent on systems and on merging.
//  *
//  * Frame time measurements add a small constant-time overhead to an application.
//  * When an application sets a target FPS, frame time measurements are enabled by
//  * default.
//  *
//  * @param world The world.
//  * @param enable Whether to enable or disable frame time measuring.
//  */
// ecs_measure_frame_time :: (
//     world: *ecs_world_t,
//     enable: bool) #foreign flecs;

// /* Measure system time.
//  * System time measurements measure the time spent in each system.
//  *
//  * System time measurements add overhead to every system invocation and
//  * therefore have a small but measurable impact on application performance.
//  * System time measurements must be enabled before obtaining system statistics.
//  *
//  * @param world The world.
//  * @param enable Whether to enable or disable system time measuring.
//  */
// ecs_measure_system_time :: (
//     world: *ecs_world_t,
//     enable: bool) #foreign flecs;

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

// /* Get current number of threads. */
// ecs_get_threads :: (
//     world: *ecs_world_t) -> int32_t #foreign flecs;

// /* @} */

// /*
//  * @defgroup creating_entities Creating Entities
//  * @{
//  */

// /* Create new entity id.
//  * This operation returns an unused entity id.
//  *
//  * @param world The world.
//  * @return The new entity id.
//  */
// ecs_new_id :: (
//     world: *ecs_world_t) -> ecs_entity_t #foreign flecs;

// /* Create new component id.
//  * This operation returns a new component id. Component ids are the same as
//  * entity ids, but can make use of the [1 .. ECS_HI_COMPONENT_ID] range.
//  *
//  * This operation does not recycle ids.
//  *
//  * @param world The world.
//  * @return The new component id.
//  */
// ecs_new_component_id :: (
//     world: *ecs_world_t) -> ecs_entity_t #foreign flecs;

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

// /* Create a new type entity.
//  * This operation creates a new type entity, or finds an existing one. The find
//  * or create behavior is the same as ecs_entity_init.
//  *
//  * A type entity is an entity with the EcsType component. This component
//  * a pointer to an ecs_type_t, which allows for the creation of named types.
//  * Named types are used in a few places, such as for pipelines and filter terms
//  * with the EcsAndFrom or EcsOrFrom operators.
//  *
//  * When an existing type entity is found, its types are verified with the
//  * provided values. If the values do not match, the operation will fail.
//  *
//  * See the documentation of ecs_type_desc_t for more details.
//  *
//  * @param world The world.
//  * @param desc Type entity init parameters.
//  * @return A handle to the new or existing type, or 0 if failed.
// */
// ecs_type_init :: (
//     world: *ecs_world_t,
//     desc: *ecs_type_desc_t) -> ecs_entity_t #foreign flecs;

// /* Create N new entities.
//  * This operation is the same as ecs_new_w_id, but creates N entities
//  * instead of one and does not recycle ids.
//  *
//  * @param world The world.
//  * @param entity The entity.
//  * @param count The number of entities to create.
//  * @return The first entity id of the newly created entities.
//  */
// ecs_bulk_new_w_id :: (
//     world: *ecs_world_t,
//     id: ecs_id_t,
//     count: int32_t) -> *ecs_entity_t #foreign flecs;

// /* Create N new entities and initialize components.
//  * This operation is the same as ecs_bulk_new_w_type, but initializes components
//  * with the provided component array. Instead of a type the operation accepts an
//  * array of component identifiers (entities). The component arrays need to be
//  * provided in the same order as the component identifiers.
//  *
//  * @param world The world.
//  * @param components Array with component identifiers.
//  * @param count The number of entities to create.
//  * @param data The data arrays to initialize the components with.
//  * @return The first entity id of the newly created entities.
//  */
// ecs_bulk_new_w_data :: (
//     world: *ecs_world_t,
//     count: int32_t,
//     component_ids: *ecs_ids_t,
//     data: *void) -> *ecs_entity_t #foreign flecs;

// /* Clone an entity
//  * This operation clones the components of one entity into another entity. If
//  * no destination entity is provided, a new entity will be created. Component
//  * values are not copied unless copy_value is true.
//  *
//  * @param world The world.
//  * @param dst The entity to copy the components to.
//  * @param src The entity to copy the components from.
//  * @param copy_value If true, the value of components will be copied to dst.
//  * @return The destination entity.
//  */
// ecs_clone :: (
//     world: *ecs_world_t,
//     dst: ecs_entity_t,
//     src: ecs_entity_t,
//     copy_value: bool) -> ecs_entity_t #foreign flecs;

// /* @} */

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

// /*
//  * @defgroup enabling_disabling Enabling & Disabling components.
//  * @{
//  */

// /* Enable or disable component.
//  * Enabling or disabling a component does not add or remove a component from an
//  * entity, but prevents it from being matched with queries. This operation can
//  * be useful when a component must be temporarily disabled without destroying
//  * its value. It is also a more performant operation for when an application
//  * needs to add/remove components at high frequency, as enabling/disabling is
//  * cheaper than a regular add or remove.
//  *
//  * @param world The world.
//  * @param entity The entity.
//  * @param id The component.
//  * @param enable True to enable the component, false to disable.
//  */
// ecs_enable_component_w_id :: (
//     world: *ecs_world_t,
//     entity: ecs_entity_t,
//     id: ecs_id_t,
//     enable: bool) #foreign flecs;

// /* Test if component is enabled.
//  * Test whether a component is currently enabled or disabled. This operation
//  * will return true when the entity has the component and if it has not been
//  * disabled by ecs_enable_component.
//  *
//  * @param world The world.
//  * @param entity The entity.
//  * @param id The component.
//  * @return True if the component is enabled, otherwise false.
//  */
// ecs_is_component_enabled_w_id :: (
//     world: *ecs_world_t,
//     entity: ecs_entity_t,
//     id: ecs_id_t) -> bool #foreign flecs;

// /* @} */

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
// /* @} */

// /*
//  * @defgroup deleting Deleting Entities and components
//  * @{
//  */

// /* Clear all components.
//  * This operation will clear all components from an entity but will not delete
//  * the entity itself. This effectively prevents the entity id from being
//  * recycled.
//  *
//  * @param world The world.
//  * @param entity The entity.
//  */
// ecs_clear :: (
//     world: *ecs_world_t,
//     entity: ecs_entity_t) #foreign flecs;

// /* Delete an entity.
//  * This operation will delete an entity and all of its components. The entity id
//  * will be recycled. Repeatedly calling ecs_delete without ecs_new,
//  * ecs_new_w_id or ecs_new_w_type will cause a memory leak as it will cause
//  * the list with ids that can be recycled to grow unbounded.
//  *
//  * @param world The world.
//  * @param entity The entity.
//  */
// ecs_delete :: (
//     world: *ecs_world_t,
//     entity: ecs_entity_t) #foreign flecs;


// /* Delete children of an entity.
//  * This operation deletes all children of a parent entity. If a parent has no
//  * children this operation has no effect.
//  *
//  * @param world The world.
//  * @param parent The parent entity.
//  */
// ecs_delete_children :: (
//     world: *ecs_world_t,
//     parent: ecs_entity_t) #foreign flecs;

// /* @} */

// /*
//  * @defgroup getting Getting Components
//  * @{
//  */

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

// /* Get an immutable reference to a component.
//  * This operation is similar to ecs_get_id but it stores temporary
//  * information in a `ecs_ref_t` value which allows subsequent lookups to be
//  * faster.
//  *
//  * @param world The world.
//  * @param ref Pointer to a ecs_ref_t value. Must be initialized.
//  * @param entity The entity.
//  * @param component The entity id of the component to obtain.
//  * @return The component pointer, NULL if the entity does not have the component.
//  */
// ecs_get_ref_w_id :: (
//     world: *ecs_world_t,
//     ref: *ecs_ref_t,
//     entity: ecs_entity_t,
//     id: ecs_id_t) -> *void #foreign flecs;

// /* Get case for switch.
//  * This operation gets the current case for the specified switch. If the current
//  * switch is not set for the entity, the operation will return 0.
//  *
//  * @param world The world.
//  * @param e The entity.
//  * @param sw The switch for which to obtain the case.
//  * @return The current case for the specified switch.
//  */
// ecs_get_case :: (
//     world: *ecs_world_t,
//     e: ecs_entity_t,
//     sw: ecs_entity_t) -> ecs_entity_t #foreign flecs;

// /* @} */

// /*
//  * @defgroup setting Setting Components
//  * @{
//  */

// /* Get a mutable pointer to a component.
//  * This operation is similar to ecs_get_id but it returns a mutable
//  * pointer. If this operation is invoked from inside a system, the entity will
//  * be staged and a pointer to the staged component will be returned.
//  *
//  * If the entity did not yet have the component, the component will be added by
//  * this operation. In this case the is_added out parameter will be set to true.
//  *
//  * @param world The world.
//  * @param entity The entity.
//  * @param id The entity id of the component to obtain.
//  * @param is_added Out parameter that returns true if the component was added.
//  * @return The component pointer.
//  */
// ecs_get_mut_w_id :: (
//     world: *ecs_world_t,
//     entity: ecs_entity_t,
//     id: ecs_id_t,
//     is_added: *bool) -> *void #foreign flecs;

// /* Signal that a component has been modified.
//  * This operation allows an application to signal to Flecs that a component has
//  * been modified. As a result, OnSet systems will be invoked.
//  *
//  * This operation is commonly used together with ecs_get_mut.
//  *
//  * @param world The world.
//  * @param entity The entity.
//  * @param component The entity id of the component that was modified.
//  */
// ecs_modified_w_id :: (
//     world: *ecs_world_t,
//     entity: ecs_entity_t,
//     id: ecs_id_t) #foreign flecs;

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

// /* @} */

// /*
//  * @defgroup testing Testing Components
//  * @{
//  */

// /* Test if an entity has an entity.
//  * This operation returns true if the entity has the provided entity in its
//  * type.
//  *
//  * @param world The world.
//  * @param entity The entity.
//  * @param id The id to test for.
//  * @return True if the entity has the entity, false if not.
//  */
// ecs_has_id :: (
//     world: *ecs_world_t,
//     entity: ecs_entity_t,
//     id: ecs_id_t) -> bool #foreign flecs;

// /* @} */

// /*
//  * @defgroup metadata Entity Metadata
//  * @{
//  */

// /* Test whether an entity is valid.
//  * An entity is valid if it is not 0 and if it is alive. If the provided id has
//  * a role or a pair, the contents of the role or the pair will be checked for
//  * validity.
//  *
//  * @param world The world.
//  * @param e The entity.
//  * @return True if the entity is valid, false if the entity is not valid.
//  */
// ecs_is_valid :: (
//     world: *ecs_world_t,
//     e: ecs_entity_t) -> bool #foreign flecs;

// /* Test whether an entity is alive.
//  *
//  * @param world The world.
//  * @param e The entity.
//  * @return True if the entity is alive, false if the entity is not alive.
//  */
// ecs_is_alive :: (
//     world: *ecs_world_t,
//     e: ecs_entity_t) -> bool #foreign flecs;

// /* Get alive identifier.
//  * In some cases an application may need to work with identifiers from which
//  * the generation has been stripped. A typical scenario in which this happens is
//  * when iterating relationships in an entity type.
//  *
//  * For example, when obtaining the parent id from a ChildOf relation, the parent
//  * (object part of the pair) will have been stored in a 32 bit value, which
//  * cannot store the entity generation. This function can retrieve the identifier
//  * with the current generation for that id.
//  *
//  * If the provided identifier is not alive, the function will return 0.
//  *
//  * @param world The world.
//  * @param e The for which to obtain the current alive entity id.
//  * @return The alive entity id if there is one, or 0 if the id is not alive.
//  */
// ecs_get_alive :: (
//     world: *ecs_world_t,
//     e: ecs_entity_t) -> ecs_entity_t #foreign flecs;

// /* Ensure id is alive.
//  * This operation ensures that the provided id is alive. This is useful in
//  * scenarios where an application has an existing id that has not been created
//  * with ecs_new (such as a global constant or an id from a remote application).
//  *
//  * Before this operation the id must either not yet exist, or must exist with
//  * the same generation as the provided id. If the id has been recycled and the
//  * provided id does not have the same generation count, the function will fail.
//  *
//  * If the provided entity is not alive, and the provided generation count is
//  * equal to the current generation (which is the future generation when the id
//  * will be recycled) the id will become alive again.
//  *
//  * If the provided id has a non-zero generation count and the id does not exist
//  * in the world, the id will be created with the specified generation.
//  *
//  * This behavior ensures that an application can use ecs_ensure to track the
//  * lifecycle of an id without explicitly having to create it. It also protects
//  * against reviving an id with a generation count that was not yet due.
//  *
//  * @param world The world.
//  * @param entity The entity id to make alive.
//  */
// ecs_ensure :: (
//     world: *ecs_world_t,
//     e: ecs_entity_t) #foreign flecs;

// /* Test whether an entity exists.
//  * Similar as ecs_is_alive, but ignores entity generation count.
//  *
//  * @param world The world.
//  * @param e The entity.
//  * @return True if the entity exists, false if the entity does not exist.
//  */
// ecs_exists :: (
//     world: *ecs_world_t,
//     e: ecs_entity_t) ->bool #foreign flecs;

// /* Get the type of an entity.
//  *
//  * @param world The world.
//  * @param entity The entity.
//  * @return The type of the entity, NULL if the entity has no components.
//  */
// ecs_get_type :: (
//     world: *ecs_world_t,
//     entity: ecs_entity_t) ->ecs_type_t #foreign flecs;

// /* Get the typeid of an entity.
//  *
//  * @param world The world.
//  * @param entity The entity.
//  * @return The typeid of the entity.
//  */
// ecs_get_typeid :: (
//     world: *ecs_world_t,
//     e: ecs_id_t) ->ecs_entity_t #foreign flecs;

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

// /* Convert type role to string.
//  * This operation converts a type role to a string.
//  *
//  * @param world The world.
//  * @param entity The entity containing the type role.
//  * @return The type role string, or NULL if no type role is provided.
//  */
// ecs_role_str :: (
//     entity: ecs_entity_t) -> *u8 #foreign flecs;

// /* Convert id to string.
//  * This operation interprets the structure of an id and converts it to a string.
//  *
//  * @param world The world.
//  * @param id The id to convert to a string.
//  * @param buffer The buffer in which to store the string.
//  * @param buffer_len The length of the provided buffer.
//  * @return The number of characters required to write the string.
//  */
// ecs_id_str :: (
//     world: *ecs_world_t,
//     entity: ecs_id_t,
//     buffer: *u8,
//     buffer_len: size_t) -> size_t #foreign flecs;

// /* Get the object of an entity.
//  * This will return a object of the entity that has the specified component. If
//  * the component is 0, the operation will return the first object that it finds
//  * in the entity type.
//  *
//  * @param world The world.
//  * @param entity The entity.
//  * @param rel The relation between the entity and the object.
//  * @param id The entity id of a component that the object must have.
//  * @return The object that has the specified id.
//  */
// ecs_get_object_w_id :: (
//     world: *ecs_world_t,
//     entity: ecs_entity_t,
//     rel: ecs_entity_t,
//     id: ecs_id_t) -> ecs_entity_t #foreign flecs;

// /* Enable or disable an entity.
//  * This operation enables or disables an entity by adding or removing the
//  * EcsDisabled tag. A disabled entity will not be matched with any systems,
//  * unless the system explicitly specifies the EcsDisabled tag.
//  *
//  * @param world The world.
//  * @param entity The entity to enable or disable.
//  * @param enabled true to enable the entity, false to disable.
//  */
// ecs_enable :: (
//     world: *ecs_world_t,
//     entity: ecs_entity_t,
//     enabled: bool) #foreign flecs;

// /* Count entities that have the specified id.
//  * Returns the number of entities that have the specified id.
//  *
//  * @param world The world.
//  * @param entity The id to search for.
//  * @return The number of entities that have the id.
//  */
// ecs_count_id :: (
//     world: *ecs_world_t,
//     entity: ecs_id_t) -> int32_t #foreign flecs;

// /* Count entities that match a filter.
//  * Returns the number of entities that match the specified filter.
//  *
//  * @param world The world.
//  * @param type The type.
//  * @return The number of entities that match the specified filter.
//  */
// ecs_count_filter :: (
//     world: *ecs_world_t,
//     filter: *ecs_filter_t) -> int32_t #foreign flecs;

// /* @} */


// /*
//  * @defgroup lookup Lookups
//  * @{
//  */

// /* Lookup an entity by name.
//  * Returns an entity that matches the specified name. Only looks for entities in
//  * the current scope (root if no scope is provided).
//  *
//  * @param world The world.
//  * @param name The entity name.
//  * @return The entity with the specified name, or 0 if no entity was found.
//  */
// ecs_lookup :: (
//     world: *ecs_world_t,
//     name: *char) -> ecs_entity_t #foreign flecs;

// /* Lookup a child entity by name.
//  * Returns an entity that matches the specified name. Only looks for entities in
//  * the provided parent. If no parent is provided, look in the current scope (
//  * root if no scope is provided).
//  *
//  * @param world The world.
//  * @param name The entity name.
//  * @return The entity with the specified name, or 0 if no entity was found.
//  */
// ecs_lookup_child :: (
//     world: *ecs_world_t,
//     parent: ecs_entity_t,
//     name: *char) -> ecs_entity_t #foreign flecs;

// /* Lookup an entity from a path.
//  * Lookup an entity from a provided path, relative to the provided parent. The
//  * operation will use the provided separator to tokenize the path expression. If
//  * the provided path contains the prefix, the search will start from the root.
//  *
//  * If the entity is not found in the provided parent, the operation will
//  * continue to search in the parent of the parent, until the root is reached. If
//  * the entity is still not found, the lookup will search in the flecs.core
//  * scope. If the entity is not found there either, the function returns 0.
//  *
//  * @param world The world.
//  * @param parent The entity from which to resolve the path.
//  * @param path The path to resolve.
//  * @param sep The path separator.
//  * @param prefix The path prefix.
//  * @param recursive Recursively traverse up the tree until entity is found.
//  * @return The entity if found, else 0.
//  */
// ecs_lookup_path_w_sep :: (
//     world: *ecs_world_t,
//     parent: ecs_entity_t,
//     path: *u8,
//     sep: *u8,
//     prefix: *u8,
//     recursive: bool) -> ecs_entity_t #foreign flecs;

// /* Lookup an entity by its symbol name.
//  * This looks up an entity by the symbol name that was provided in EcsName. The
//  * operation does not take into account scoping, which means it will search all
//  * entities that have an EcsName.
//  *
//  * This operation can be useful to resolve, for example, a type by its C
//  * identifier, which does not include the Flecs namespacing.
//  */
// ecs_lookup_symbol :: (
//     world: *ecs_world_t,
//     name: *u8) -> ecs_entity_t #foreign flecs;

// /* Add alias for entity to global scope */
// ecs_use :: (
//     world: *ecs_world_t,
//     entity: ecs_entity_t,
//     name: *u8) -> ecs_entity_t #foreign flecs;

// /* @} */

// /*
//  * @defgroup paths Paths
//  * @{
//  */

// /* Get a path identifier for an entity.
//  * This operation creates a path that contains the names of the entities from
//  * the specified parent to the provided entity, separated by the provided
//  * separator. If no parent is provided the path will be relative to the root. If
//  * a prefix is provided, the path will be prefixed by the prefix.
//  *
//  * If the parent is equal to the provided child, the operation will return an
//  * empty string. If a nonzero component is provided, the path will be created by
//  * looking for parents with that component.
//  *
//  * The returned path should be freed by the application.
//  *
//  * @param world The world.
//  * @param parent The entity from which to create the path.
//  * @param child The entity to which to create the path.
//  * @param component The component of the parent.
//  * @return The relative entity path.
//  */
// ecs_get_path_w_sep :: (
//     world: *ecs_world_t,
//     parent: ecs_entity_t,
//     child: ecs_entity_t,
//     component: ecs_entity_t,
//     sep: *u8,
//     prefix: *u8) -> *u8 #foreign flecs;

// /* Find or create entity from path.
//  * This operation will find or create an entity from a path, and will create any
//  * intermediate entities if required. If the entity already exists, no entities
//  * will be created.
//  *
//  * If the path starts with the prefix, then the entity will be created from the
//  * root scope.
//  *
//  * @param world The world.
//  * @param parent The entity relative to which the entity should be created.
//  * @param path The path to create the entity for.
//  * @param sep The separator used in the path.
//  * @param prefix The prefix used in the path.
//  * @return The entity.
//  */
// ecs_new_from_path_w_sep :: (
//     world: *ecs_world_t,
//     parent: ecs_entity_t,
//     path: *u8,
//     sep: *u8,
//     prefix: *u8) -> ecs_entity_t #foreign flecs;

// /* Add specified path to entity.
//  * This operation is similar to ecs_new_from_path, but will instead add the path
//  * to an existing entity.
//  *
//  * If an entity already exists for the path, it will be returned instead.
//  *
//  * @param world The world.
//  * @param entity The entity to which to add the path.
//  * @param parent The entity relative to which the entity should be created.
//  * @param path The path to create the entity for.
//  * @param sep The separator used in the path.
//  * @param prefix The prefix used in the path.
//  * @return The entity.
//  */
// ecs_add_path_w_sep :: (
//     world: *ecs_world_t,
//     entity: ecs_entity_t,
//     parent: ecs_entity_t,
//     path: *u8,
//     sep: *u8,
//     prefix: *u8) -> ecs_entity_t #foreign flecs;

// /* @} */

// /*
//  * @defgroup scopes Scopes
//  * @{
//  */

// /* Does entity have children.
//  *
//  * @param world The world
//  * @param entity The entity
//  * @return True if the entity has children, false if not.
//  */
// ecs_get_child_count :: (
//     world: *ecs_world_t,
//     entity: ecs_entity_t) -> int32_t #foreign flecs;

// /* Return a scope iterator.
//  * A scope iterator iterates over all the child entities of the specified
//  * parent.
//  *
//  * @param world The world.
//  * @param parent The parent entity for which to iterate the children.
//  * @return The iterator.
//  */
// ecs_scope_iter :: (
//     world: *ecs_world_t,
//     parent: ecs_entity_t) -> ecs_iter_t #foreign flecs;

// /* Return a filtered scope iterator.
//  * Same as ecs_scope_iter, but results will be filtered.
//  *
//  * @param world The world.
//  * @param parent The parent entity for which to iterate the children.
//  * @return The iterator.
//  */
// ecs_scope_iter_w_filter :: (
//     world: *ecs_world_t,
//     parent: ecs_entity_t,
//     filter: *ecs_filter_t) -> ecs_iter_t #foreign flecs;

// /* Progress the scope iterator.
//  * This operation progresses the scope iterator to the next table. The iterator
//  * must have been initialized with `ecs_scope_iter`. This operation must be
//  * invoked at least once before interpreting the contents of the iterator.
//  *
//  * @param it The iterator
//  * @return True if more data is available, false if not.
//  */
// ecs_scope_next :: (
//     it: *ecs_iter_t) -> bool #foreign flecs;

// /* Set the current scope.
//  * This operation sets the scope of the current stage to the provided entity.
//  * As a result new entities will be created in this scope, and lookups will be
//  * relative to the provided scope.
//  *
//  * It is considered good practice to restore the scope to the old value.
//  *
//  * @param world The world.
//  * @param scope The entity to use as scope.
//  * @return The previous scope.
//  */
// ecs_set_scope :: (
//     world: *ecs_world_t,
//     scope: ecs_entity_t) -> ecs_entity_t #foreign flecs;

// /* Get the current scope.
//  * Get the scope set by ecs_set_scope. If no scope is set, this operation will
//  * return 0.
//  *
//  * @param world The world.
//  * @return The current scope.
//  */
// ecs_get_scope :: (
//     world: *ecs_world_t) -> ecs_entity_t #foreign flecs;

// /* Set current with id.
//  * New entities are automatically created with the specified id.
//  *
//  * @param world The world.
//  * @param id The id.
//  * @return The previous id.
//  */
// ecs_set_with :: (
//     world: *ecs_world_t,
//     id: ecs_id_t) -> ecs_entity_t #foreign flecs;

// /* Get current with id.
//  * Get the id set with ecs_set_with.
//  *
//  * @param world The world.
//  * @param id The id.
//  * @return The previous id.
//  */
// ecs_get_with :: (
//     world: *ecs_world_t) -> ecs_entity_t #foreign flecs;

// /* Set a name prefix for newly created entities.
//  * This is a utility that lets C modules use prefixed names for C types and
//  * C functions, while using names for the entity names that do not have the
//  * prefix. The name prefix is currently only used by ECS_COMPONENT.
//  *
//  * @param world The world.
//  * @param prefix The name prefix to use.
//  * @return The previous prefix.
//  */
// ecs_set_name_prefix :: (
//     world: *ecs_world_t,
//     prefix: *u8) -> *u8 #foreign flecs;

// /* @} */

// /*
//  * @defgroup terms Terms
//  * @{
//  */

// /* Test whether a term is set.
//  * This operation can be used to test whether a term has been initialized with
//  * values or whether it is empty.
//  *
//  * An application generally does not need to invoke this operation. It is useful
//  * when initializing a 0-initialized array of terms (like in ecs_term_desc_t) as
//  * this operation can be used to find the last initialized element.
//  *
//  * @param term The term.
//  * @return True when set, false when not set.
//  */
// ecs_term_is_set :: (
//     term: *ecs_term_t) -> bool #foreign flecs;

// /* Test whether a term is a trivial term.
//  * A trivial term is a term that only contains a type id. Trivial terms must not
//  * have read/write annotations, relation substitutions and subjects other than
//  * 'This'. Examples of trivial terms are:
//  * - 'Position'
//  * - 'Position(This)'
//  * - '(Likes, IceCream)'
//  * - 'Likes(This, IceCream)'
//  *
//  * Examples of non-trivial terms are:
//  * - '[in] Position'
//  * - 'Position(MyEntity)'
//  * - 'Position(self|superset)'
//  *
//  * Trivial terms are useful in expressions that should just represent a list of
//  * components, such as when parsing the list of components to add to an entity.
//  *
//  * The term passed to this operation must be finalized. Terms returned by the
//  * parser are guaranteed to be finalized.
//  *
//  * @param term The term.
//  * @return True if term is trivial, false if it is not.
//  */
// ecs_term_is_trivial :: (
//     term: *ecs_term_t) -> bool #foreign flecs;

// /* Finalize term.
//  * Ensure that all fields of a term are consistent and filled out. This
//  * operation should be invoked before using and after assigning members to, or
//  * parsing a term. When a term contains unresolved identifiers, this operation
//  * will resolve and assign the identifiers. If the term contains any identifiers
//  * that cannot be resolved, the operation will fail.
//  *
//  * An application generally does not need to invoke this operation as the APIs
//  * that use terms (such as filters, queries and triggers) will finalize terms
//  * when they are created.
//  *
//  * The name and expr parameters are optional, and only used for giving more
//  * descriptive error messages.
//  *
//  * @param world The world.
//  * @param name The name of the entity that uses the term (such as a system).
//  * @param expr The string expression of which the term is a part.
//  * @param term The term to finalize.
//  * @return Zero if success, nonzero if an error occurred.
//  */
// ecs_term_finalize :: (
//     world: *ecs_world_t,
//     name: *u8,
//     expr: *u8,
//     term: *ecs_term_t) -> int #foreign flecs;

// /* Copy resources of a term to another term.
//  * This operation copies one term to another term. If the source term contains
//  * allocated resources (such as identifiers), they will be duplicated so that
//  * no memory is shared between the terms.
//  *
//  * @param dst The term to copy to.
//  * @param src The term to copy from.
//  */
// ecs_term_copy :: (
//     src: *ecs_term_t) -> ecs_term_t #foreign flecs;

// /* Move resources of a term to another term.
//  * Same as copy, but moves resources from src, if src->move is set to true. If
//  * src->move is not set to true, this operation will do a copy.
//  *
//  * The conditional move reduces redundant allocations in scenarios where a list
//  * of terms is partially created with allocated resources.
//  *
//  * @param dst The term to copy to.
//  * @param src The term to copy from.
//  */
// ecs_term_move :: (
//     src: *ecs_term_t) -> ecs_term_t #foreign flecs;

// /* Free resources of term.
//  * This operation frees all resources (such as identifiers) of a term. The term
//  * object itself is not freed.
//  *
//  * @param term The term to free.
//  */
// ecs_term_fini :: (
//     term: *ecs_term_t) #foreign flecs;

// /* Utility to match an id with a pattern.
//  * This operation returns true if the provided pattern matches the provided
//  * id. The pattern may contain a wildcard (or wildcards, when a pair).
//  *
//  * @param id The id.
//  * @param pattern The pattern to compare with.
//  */
// ecs_id_match :: (
//     id: ecs_id_t,
//     pattern: ecs_id_t) -> bool #foreign flecs;

// /* @} */

// /*
//  * @defgroup filters Filters
//  * @{
//  */

// /* Initialize filter
//  * A filter is a lightweight object that can be used to query for entities in
//  * a world. Filters, as opposed to queries, do not cache results. They are
//  * therefore slower to iterate, but are faster to create.
//  *
//  * This operation will at minimum allocate an array to hold the filter terms in
//  * the returned filter struct. It may allocate additional memory if the provided
//  * description contains a name, expression, or if the provided array of terms
//  * contains strings (identifier names or term names).
//  *
//  * It is possible to create a filter without allocating any memory, by setting
//  * the "terms" and "term_count" members directly. When doing so an application
//  * should not call ecs_filter_init but ecs_filter_finalize. This will ensure
//  * that all fields are consistent and properly filled out.
//  *
//  * @param world The world.
//  * @param desc Properties for the filter to create.
//  * @param filter_out The filter.
//  * @return Zero if successful, non-zero if failed.
//  */
// ecs_filter_init :: (
//     world: *ecs_world_t,
//     filter_out: *ecs_filter_t,
//     desc: *ecs_filter_desc_t) -> s32 #foreign flecs;

// /* Deinitialize filter.
//  * Free resources associated with filter.
//  *
//  * @param filter The filter to deinitialize.
//  */
// ecs_filter_fini :: (
//     filter: *ecs_filter_t) #foreign flecs;

// /* Finalize filter.
//  * When manually assigning an array of terms to the filter struct (so not when
//  * using ecs_filter_init), this operation should be used to ensure that all
//  * terms are assigned properly and all (derived) fields have been set.
//  *
//  * When ecs_filter_init is used to create the filter, this function should not
//  * be called. The purpose of this operation is to support creation of filters
//  * without allocating memory.
//  *
//  * @param filter The filter to finalize.
//  * @return Zero if filter is valid, non-zero if it contains errors.
//  * @
//  */
// ecs_filter_finalize :: (
//     world: *ecs_world_t,
//     filter: *ecs_filter_t) -> s32 #foreign flecs;

// /* Convert filter to string expression.
//  * Convert filter terms to a string expression. The resulting expression can be
//  * parsed to create the same filter.
//  */
// ecs_filter_str :: (
//     world: *ecs_world_t,
//     filter: *ecs_filter_t) -> *u8 #foreign flecs;

// /* Return a filter iterator.
//  * A filter iterator lets an application iterate over entities that match the
//  * specified filter. If NULL is provided for the filter, the iterator will
//  * iterate all tables in the world.
//  *
//  * @param world The world.
//  * @param filter The filter.
//  * @return An iterator that can be used with ecs_filter_next.
//  */
// ecs_filter_iter :: (
//     world: *ecs_world_t,
//     filter: *ecs_filter_t) -> ecs_iter_t #foreign flecs;

// /* Iterate tables matched by filter.
//  * This operation progresses the filter iterator to the next table. The
//  * iterator must have been initialized with `ecs_filter_iter`. This operation
//  * must be invoked at least once before interpreting the contents of the
//  * iterator.
//  *
//  * @param it The iterator
//  * @return True if more data is available, false if not.
//  */
// ecs_filter_next :: (
//     iter: *ecs_iter_t) -> bool #foreign flecs;

// /* @} */

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

// /* Get trigger context.
//  * This operation returns the context pointer set for the trigger. If
//  * the provided entity is not a trigger, the function will return NULL.
//  *
//  * @param world The world.
//  * @param trigger The trigger from which to obtain the context.
//  * @return The context.
//  */
// ecs_get_trigger_ctx :: (
//     world: *ecs_world_t,
//     trigger: ecs_entity_t) -> *void #foreign flecs;

// /* Same as ecs_get_trigger_ctx, but for binding ctx.
//  * The binding context is a context typically used to attach any language
//  * binding specific data that is needed when invoking a callback that is
//  * implemented in another language.
//  *
//  * @param world The world.
//  * @param trigger The trigger from which to obtain the context.
//  * @return The context.
//  */
// ecs_get_trigger_binding_ctx :: (
//     world: *ecs_world_t,
//     trigger: ecs_entity_t) -> *void #foreign flecs;

/* @} */

// /*
//  * @defgroup observer Observers
//  */

// /* Create observer.
//  * Observers are like triggers, but can subscribe for multiple terms. An
//  * observer only triggers when the source of the event meets all terms.
//  *
//  * See the documentation for ecs_observer_desc_t for more details.
//  *
//  * @param world The world.
//  * @param desc The observer creation parameters.
//  */
// ecs_observer_init :: (
//     world: *ecs_world_t,
//     desc: *ecs_observer_desc_t) -> ecs_entity_t #foreign flecs;

// ecs_get_observer_ctx :: (
//     world: *ecs_world_t,
//     observer: ecs_entity_t) -> *void #foreign flecs;

// ecs_get_observer_binding_ctx :: (
//     world: *ecs_world_t,
//     observer: ecs_entity_t) -> *void #foreign flecs;

// /* @} */

// /*
//  * @defgroup iterator Iterators
//  * @{
//  */

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

// /* Obtain the component/pair id for a term.
//  * This operation retrieves the id for the specified query term. Typically this
//  * is the component id, but it can also be a pair id or a role annotated id,
//  * depending on the term.
//  *
//  * @param it The iterator.
//  * @param index The index of the term in the query.
//  * @return The id associated with te term.
//  */
// ecs_term_id :: (
//     it: *ecs_iter_t,
//     index: int32_t) -> ecs_id_t #foreign flecs;

// /* Obtain the source for a term.
//  * This operation retrieves the source of the specified term. A source is the
//  * entity from which the data is retrieved. If the term is owned by the iterated
//  * over entity/entities, the function will return id 0.
//  *
//  * This operation can be useful to retrieve, for example, the id of a parent
//  * entity when a component from a parent has been requested, or to retrieve the
//  * id from a prefab, in the case of a shared component.
//  *
//  * @param it The iterator.
//  * @param index The index of the term in the query.
//  * @return The source associated with te term.
//  */
// ecs_term_source :: (
//     it: *ecs_iter_t,
//     index: int32_t) -> ecs_entity_t #foreign flecs;

// /* Obtain the size for a term.
//  * This operation retrieves the size of the datatype for the term.
//  *
//  * @param it The iterator.
//  * @param index The index of the term in the query.
//  * @return The size of the datatype associated with te term.
//  */
// ecs_term_size :: (
//     it: *ecs_iter_t,
//     index: int32_t) -> size_t #foreign flecs;

// /* Test whether the term is readonly
//  * This operation returns whether this is a readonly term. Readonly terms are
//  * annotated with [in], or are added as a type in the C++ API.
//  *
//  * @param it The iterator.
//  * @param index The index of the term in the query.
//  * @return Whether the term is readonly.
//  */
// ecs_term_is_readonly :: (
//     it: *ecs_iter_t,
//     index: int32_t) -> bool #foreign flecs;

// /* Test whether the term is owned
//  * This operation returns whether the term is owned by the currently iterated
//  * entity. This function will return false when the term is owned by another
//  * entity, such as a parent or a prefab.
//  *
//  * @param it The iterator.
//  * @param index The index of the term in the query.
//  * @return Whether the term is owned by the iterated over entity/entities.
//  */
// ecs_term_is_owned :: (
//     it: *ecs_iter_t,
//     index: int32_t) -> bool #foreign flecs;

// /* Get the type of the currently entities.
//  * This operation returns the type of the current iterated entity/entities. A
//  * type is a vector that contains all ids of the components that an entity has.
//  *
//  * @param it The iterator.
//  * @return The type of the currently iterated entity/entities.
//  */
// ecs_iter_type :: (
//     it: *ecs_iter_t) -> ecs_type_t #foreign flecs;

// /* Get the table for the current entities.
//  * This operation returns the table of the current iterated entities
//  *
//  * @param it The iterator.
//  * @return The table of the currently iterated entity/entities.
//  */
// ecs_iter_table :: (
//     it: *ecs_iter_t) -> *ecs_table_t #foreign flecs;

// /* Find the column index for a given id.
//  * This operation finds the index of a column in the current type for the
//  * specified id. For example, if an entity has type Position, Velocity, and the
//  * application requests the id for the Velocity component, this function will
//  * return 1.
//  *
//  * Note that the column index returned by this function starts from 0, as
//  * opposed to 1 for the terms. The reason for this is that the returned index
//  * is equivalent to using the ecs_type_get_index function, with as type the
//  * value returned by ecs_iter_type.
//  *
//  * This operation can be used to request columns that are not requested by a
//  * query. For example, a query may request Position, Velocity, but an entity
//  * may also have Mass. With this function the iterator can request the data for
//  * Mass as well, when used in combination with ecs_iter_column.
//  *
//  * @param it The iterator.
//  * @return The type of the currently iterated entity/entities.
//  */
// ecs_iter_find_column :: (
//     it: *ecs_iter_t,
//     id: ecs_id_t) -> int32_t #foreign flecs;

// /* Obtain data for a column index.
//  * This operation can be used with the id obtained from ecs_iter_find_column to
//  * request data from the currently iterated over entity/entities that is not
//  * requested by the query.
//  *
//  * The data in the returned pointer can be accessed using the same index as
//  * the one used to access the arrays returned by the ecs_term function.
//  *
//  * The provided size must be either 0 or must match the size of the datatype
//  * of the returned array. If the size does not match, the operation may assert.
//  * The size can be dynamically obtained with ecs_iter_column_size.
//  *
//  * Note that this function can be used together with ecs_iter_type to
//  * dynamically iterate all data that the matched entities have. An application
//  * can use the ecs_vector_count function to obtain the number of elements in a
//  * type. All indices from 0..ecs_vector_count(type) are valid column indices.
//  *
//  * Additionally, note that this provides unprotected access to the column data.
//  * An iterator cannot know or prevent accessing columns that are not queried for
//  * and thus applications should only use this when it can be guaranteed that
//  * there are no other threads reading/writing the same column data.
//  *
//  * @param it The iterator.
//  * @param size The size of the column.
//  * @param index The index of the column.
//  * @return The data belonging to the column.
//  */
// ecs_iter_column_w_size :: (
//     it: *ecs_iter_t,
//     size: size_t,
//     index: int32_t) -> *void #foreign flecs;

// /* Obtain size for a column index.
//  * This operation obtains the size for a column. The size is equal to the size
//  * of the datatype associated with the column.
//  *
//  * @param it The iterator.
//  * @param index The index of the column.
//  * @return The size belonging to the column.
//  */
// ecs_iter_column_size :: (
//     it: *ecs_iter_t,
//     index: int32_t) -> size_t #foreign flecs;

// /* @} */

// /*
//  * @defgroup staging Staging
//  * @{
//  */

// /* Begin frame.
//  * When an application does not use ecs_progress to control the main loop, it
//  * can still use Flecs features such as FPS limiting and time measurements. This
//  * operation needs to be invoked whenever a new frame is about to get processed.
//  *
//  * Calls to ecs_frame_begin must always be followed by ecs_frame_end.
//  *
//  * The function accepts a delta_time parameter, which will get passed to
//  * systems. This value is also used to compute the amount of time the function
//  * needs to sleep to ensure it does not exceed the target_fps, when it is set.
//  * When 0 is provided for delta_time, the time will be measured.
//  *
//  * This function should only be ran from the main thread.
//  *
//  * @param world The world.
//  * @param delta_time Time elapsed since the last frame.
//  * @return The provided delta_time, or measured time if 0 was provided.
//  */
// ecs_frame_begin :: (
//     world: *ecs_world_t,
//     delta_time: FLECS_FLOAT) -> FLECS_FLOAT #foreign flecs;

// /* End frame.
//  * This operation must be called at the end of the frame, and always after
//  * ecs_frame_begin.
//  *
//  * @param world The world.
//  */
// ecs_frame_end :: (
//     world: *ecs_world_t) #foreign flecs;

// /* Begin staging.
//  * When an application does not use ecs_progress to control the main loop, it
//  * can still use Flecs features such as the defer queue. When an application
//  * needs to stage changes, it needs to call this function after ecs_frame_begin.
//  * A call to ecs_staging_begin must be followed by a call to ecs_staging_end.
//  *
//  * When staging is enabled, modifications to entities are stored to a stage.
//  * This ensures that arrays are not modified while iterating. Modifications are
//  * merged back to the "main stage" when ecs_staging_end is invoked.
//  *
//  * While the world is in staging mode, no structural changes (add/remove/...)
//  * can be made to the world itself. Operations must be executed on a stage
//  * instead (see ecs_get_stage).
//  *
//  * This function should only be ran from the main thread.
//  *
//  * @param world The world
//  * @return Whether world is currently staged.
//  */
// ecs_staging_begin :: (
//     world: *ecs_world_t) -> bool #foreign flecs;

// /* End staging.
//  * Leaves staging mode. After this operation the world may be directly mutated
//  * again. By default this operation also merges data back into the world, unless
//  * automerging was disabled explicitly.
//  *
//  * This function should only be ran from the main thread.
//  *
//  * @param world The world
//  */
// ecs_staging_end :: (
//     world: *ecs_world_t) #foreign flecs;

// /* Merge world or stage.
//  * When automatic merging is disabled, an application can call this
//  * operation on either an individual stage, or on the world which will merge
//  * all stages. This operation may only be called when staging is not enabled
//  * (either after progress() or after staging_end()).
//  *
//  * This operation may be called on an already merged stage or world.
//  *
//  * @param world The world.
//  */
// ecs_merge :: (
//     world: *ecs_world_t) #foreign flecs;

// /* Defer operations until end of frame.
//  * When this operation is invoked while iterating, operations inbetween the
//  * defer_begin and defer_end operations are executed at the end of the frame.
//  *
//  * This operation is thread safe.
//  *
//  * @param world The world.
//  * @return true if world changed from non-deferred mode to deferred mode.
//  */
// ecs_defer_begin :: (
//     world: *ecs_world_t) -> bool #foreign flecs;

// /* Test if deferring is enabled for current stage.
//  *
//  * @param world The world.
//  * @return True if deferred, false if not.
//  */
// ecs_is_deferred :: (
//     world: *ecs_world_t) -> bool #foreign flecs;

// /* End block of operations to defer.
//  * See defer_begin.
//  *
//  * This operation is thread safe.
//  *
//  * @param world The world.
//  * @return true if world changed from deferred mode to non-deferred mode.
//  */
// ecs_defer_end :: (
//     world: *ecs_world_t) -> bool #foreign flecs;

// /* Enable/disable automerging for world or stage.
//  * When automerging is enabled, staged data will automatically be merged with
//  * the world when staging ends. This happens at the end of progress(), at a
//  * sync point or when staging_end() is called.
//  *
//  * Applications can exercise more control over when data from a stage is merged
//  * by disabling automerging. This requires an application to explicitly call
//  * merge() on the stage.
//  *
//  * When this function is invoked on the world, it sets all current stages to
//  * the provided value and sets the default for new stages. When this function is
//  * invoked on a stage, automerging is only set for that specific stage.
//  *
//  * @param world The world.
//  * @param automerge Whether to enable or disable automerging.
//  */
// ecs_set_automerge :: (
//     world: *ecs_world_t,
//     automerge: bool) #foreign flecs;

// /* Configure world to have N stages.
//  * This initializes N stages, which allows applications to defer operations to
//  * multiple isolated defer queues. This is typically used for applications with
//  * multiple threads, where each thread gets its own queue, and commands are
//  * merged when threads are synchronized.
//  *
//  * Note that the ecs_set_threads function already creates the appropriate
//  * number of stages. The set_stages() operation is useful for applications that
//  * want to manage their own stages and/or threads.
//  *
//  * @param world The world.
//  * @param stages The number of stages.
//  */
// ecs_set_stages :: (
//     world: *ecs_world_t,
//     stages: int32_t) #foreign flecs;

// /* Get number of configured stages.
//  * Return number of stages set by ecs_set_stages.
//  *
//  * @param world The world.
//  * @return The number of stages used for threading.
//  */
// ecs_get_stage_count :: (
//     world: *ecs_world_t) -> int32_t #foreign flecs;

// /* Get current stage id.
//  * The stage id can be used by an application to learn about which stage it is
//  * using, which typically corresponds with the worker thread id.
//  *
//  * @param world The world.
//  * @return The stage id.
//  */
// ecs_get_stage_id :: (
//     world: *ecs_world_t) -> int32_t #foreign flecs;

// /* Get stage-specific world pointer.
//  * Flecs threads can safely invoke the API as long as they have a private
//  * context to write to, also referred to as the stage. This function returns a
//  * pointer to a stage, disguised as a world pointer.
//  *
//  * Note that this function does not(!) create a new world. It simply wraps the
//  * existing world in a thread-specific context, which the API knows how to
//  * unwrap. The reason the stage is returned as an ecs_world_t is so that it
//  * can be passed transparently to the existing API functions, vs. having to
//  * create a dediated API for threading.
//  *
//  * @param world The world.
//  * @param stage_id The index of the stage to retrieve.
//  * @return A thread-specific pointer to the world.
//  */
// ecs_get_stage :: (
//     world: *ecs_world_t,
//     stage_id: int32_t) -> *ecs_world_t #foreign flecs;

// /* Get actual world from world.
//  * @param world A pointer to a stage or the world.
//  * @return The world.
//  */
// ecs_get_world :: (
//     world: *ecs_world_t) -> *ecs_world_t #foreign flecs;

// /* Test whether the current world object is readonly.
//  * This function allows the code to test whether the currently used world object
//  * is readonly or whether it allows for writing.
//  *
//  * @param world A pointer to a stage or the world.
//  * @return True if the world or stage is readonly.
//  */
// ecs_stage_is_readonly :: (
//     stage: *ecs_world_t) -> bool #foreign flecs;

// /* Create asynchronous stage.
//  * An asynchronous stage can be used to asynchronously queue operations for
//  * later merging with the world. An asynchronous stage is similar to a regular
//  * stage, except that it does not allow reading from the world.
//  *
//  * Asynchronous stages are never merged automatically, and must therefore be
//  * manually merged with the ecs_merge function. It is not necessary to call
//  * defer_begin or defer_end before and after enqueuing commands, as an
//  * asynchronous stage unconditionally defers operations.
//  *
//  * The application must ensure that no commands are added to the stage while the
//  * stage is being merged.
//  *
//  * An asynchronous stage must be cleaned up by ecs_async_stage_free.
//  *
//  * @param world The world.
//  * @return The stage.
//  */
// ecs_async_stage_new :: (
//     world: *ecs_world_t) -> *ecs_world_t #foreign flecs;

// /* Free asynchronous stage.
//  * The provided stage must be an asynchronous stage. If a non-asynchronous stage
//  * is provided, the operation will fail.
//  *
//  * @param stage The stage to free.
//  */
// ecs_async_stage_free :: (
//     stage: *ecs_world_t) #foreign flecs;

// /* Test whether provided stage is asynchronous.
//  *
//  * @param stage The stage.
//  * @return True when the stage is asynchronous, false for a regular stage or
//  *         world.
//  */
// ecs_stage_is_async :: (
//     stage: *ecs_world_t) -> bool #foreign flecs;

// /* @} */

// /*
//  * @defgroup table_functions Public table operations
//  * @brief Low-level table functions. These functions are intended to enable the
//  *        creation of higher-level operations. It is not recommended to use
//  *        these operations directly in application code as they do not provide
//  *        the same safety guarantees as the other APIs.
//  * @{
//  */

// /* Find or create table with specified component string.
//  * The provided string must be a comma-separated list of fully qualified
//  * component identifiers. The returned table will have the specified components.
//  * Two lists that are the same but specify components in a different order will
//  * return the same table.
//  *
//  * @param world The world.
//  * @param type The components.
//  * @return The new or existing table, or NULL if the string contains an error.
//  */
// ecs_table_from_str :: (
//     world: *ecs_world_t,
//     type: *u8) -> *ecs_table_t #foreign flecs;

// /* Find or create table from type.
//  * Same as ecs_table_from_str, but provides the type directly.
//  *
//  * @param world The world.
//  * @param type The type.
//  * @return The new or existing table.
//  */
// ecs_table_from_type :: (
//     world: *ecs_world_t,
//     type: ecs_type_t) -> *ecs_table_t #foreign flecs;

// /* Get type for table.
//  *
//  * @param table The table.
//  * @return The type of the table.
//  */
// ecs_table_get_type :: (
//     table: *ecs_table_t) -> ecs_type_t #foreign flecs;

// /* Insert record into table.
//  * This will create a new record for the table, which inserts a value for each
//  * component. An optional entity and record can be provided.
//  *
//  * If a non-zero entity id is provided, a record must also be provided and vice
//  * versa. The record must be created by the entity index. If the provided record
//  * is not created for the specified entity, the behavior will be undefined.
//  *
//  * If the provided record is not managed by the entity index, the behavior will
//  * be undefined.
//  *
//  * The returned record contains a reference to the table and the table row. The
//  * data pointed to by the record is guaranteed not to move unless one or more
//  * rows are removed from this table. A row can be removed as result of a delete,
//  * or by adding/removing components from an entity stored in the table.
//  *
//  * @param world The world.
//  * @param table The table.
//  * @param entity The entity.
//  * @param record The entity-index record for the specified entity.
//  * @return A record containing the table and table row.
//  */
// ecs_table_insert :: (
//     world: *ecs_world_t,
//     table: *ecs_table_t,
//     entity: ecs_entity_t,
//     record: *ecs_record_t) -> ecs_record_t #foreign flecs;

// /* Returns the number of records in the table.
//  * This operation returns the number of records that have been populated through
//  * the regular (entity) API as well as the number of records that have been
//  * inserted using the direct access API.
//  *
//  * @param world The world.
//  * @param table The table.
//  * @return The number of records in a table.
//  */
// ecs_table_count :: (
//     table: *ecs_table_t) -> int32_t #foreign flecs;

// /* Get table that has all components of current table plus the specified id.
//  * If the provided table already has the provided id, the operation will return
//  * the provided table.
//  *
//  * @param world The world.
//  * @param table The table.
//  * @param id The id to add.
//  * @result The resulting table.
//  */
// ecs_table_add_id :: (
//     world: *ecs_world_t,
//     table: *ecs_table_t,
//     id: ecs_id_t) -> *ecs_table_t #foreign flecs;

// /* Get table that has all components of current table minus the specified id.
//  * If the provided table doesn't have the provided id, the operation will return
//  * the provided table.
//  *
//  * @param world The world.
//  * @param table The table.
//  * @param id The id to remove.
//  * @result The resulting table.
//  */
// ecs_table_remove_id :: (
//     world: *ecs_world_t,
//     table: *ecs_table_t,
//     id: ecs_id_t) -> ecs_table_t #foreign flecs;

// /* Lock or unlock table.
//  * When a table is locked, modifications to it will trigger an assert. When the
//  * table is locked recursively, it will take an equal amount of unlock
//  * operations to actually unlock the table.
//  *
//  * Table locks can be used to build safe iterators where it is guaranteed that
//  * the contents of a table are not modified while it is being iterated.
//  *
//  * The operation only works when called on the world, and has no side effects
//  * when called on a stage. The assumption is that when called on a stage,
//  * operations are deferred already.
//  *
//  * @param world The world.
//  * @param table The table to lock.
//  */
// ecs_table_lock :: (
//     world: *ecs_world_t,
//     table: *ecs_table_t) #foreign flecs;

// /* Unlock a table.
//  * Must be called after calling ecs_table_lock.
//  *
//  * @param world The world.
//  * @param table The table to unlock.
//  */
// ecs_table_unlock :: (
//     world: *ecs_world_t,
//     table: *ecs_table_t) #foreign flecs;

// /* Returns whether table is a module or contains module contents
//  * Returns true for tables that have module contents. Can be used to filter out
//  * tables that do not contain application data.
//  *
//  * @param table The table.
//  * @return true if table contains module contents, false if not.
//  */
// ecs_table_has_module :: (
//     table: *ecs_table_t) -> bool #foreign flecs;

// /* Commit (move) entity to a table.
//  * This operation moves an entity from its current table to the specified
//  * table. This may trigger the following actions:
//  * - Ctor for each component in the target table
//  * - Move for each overlapping component
//  * - Dtor for each component in the source table.
//  * - OnAdd triggers for non-overlapping components in the target table
//  * - OnRemove triggers for non-overlapping components in the source table.
//  *
//  * This operation is a faster than adding/removing components individually.
//  *
//  * The application must explicitly provide the difference in components between
//  * tables as the added/removed parameters. This can usually be derived directly
//  * from the result of ecs_table_add_id and esc_table_remove_id. These arrays are
//  * required to properly execute OnAdd/OnRemove triggers.
//  *
//  * @param world The world.
//  * @param entity The entity to commit.
//  * @param record The entity's record (optional, providing it saves a lookup).
//  * @param table The table to commit the entity to.
//  * @return True if the entity got moved, false otherwise.
//  */
// ecs_commit :: (
//     world: *ecs_world_t,
//     entity: ecs_entity_t,
//     record: *ecs_record_t,
//     table: *ecs_table_t,
//     added: *ecs_entities_t,
//     removed: *ecs_entities_t) -> bool #foreign flecs;

// /* @} */

// /*
//  * @file module.h
//  * @brief Module addon.
//  *
//  * The module addon allows for creating and importing modules. Flecs modules
//  * enable applications to organize components and systems into reusable units of
//  * code that can easily be across projects.
//  */

// /* Import a module.
//  * This operation will load a modules and store the public module handles in the
//  * handles_out out parameter. The module name will be used to verify if the
//  * module was already loaded, in which case it won't be reimported. The name
//  * will be translated from PascalCase to an entity path (pascal.case) before the
//  * lookup occurs.
//  *
//  * Module contents will be stored as children of the module entity. This
//  * prevents modules from accidentally defining conflicting identifiers. This is
//  * enforced by setting the scope before and after loading the module to the
//  * module entity id.
//  *
//  * A more convenient way to import a module is by using the ECS_IMPORT macro.
//  *
//  * @param world The world.
//  * @param module The module to load.
//  * @param module_name The name of the module to load.
//  * @param flags An integer that will be passed into the module import action.
//  * @param handles_out A struct with handles to the module components/systems.
//  * @param handles_size Size of the handles_out parameter.
//  * @return The module entity.
//  */
// ecs_import :: (
//     world: *ecs_world_t,
//     module: ecs_module_action_t,
//     module_name: *u8,
//     handles_out: *void,
//     handles_size: size_t) -> ecs_entity_t #foreign flecs;

// /* Import a module from a library.
//  * Similar to ecs_import, except that this operation will attempt to load the
//  * module from a dynamic library.
//  *
//  * A library may contain multiple modules, which is why both a library name and
//  * a module name need to be provided. If only a library name is provided, the
//  * library name will be reused for the module name.
//  *
//  * The library will be looked up using a canonical name, which is in the same
//  * form as a module, like `flecs.components.transform`. To transform this
//  * identifier to a platform specific library name, the operation relies on the
//  * module_to_dl callback of the os_api which the application has to override if
//  * the default does not yield the correct library name.
//  *
//  * @param world The world.
//  * @param library_name The name of the library to load.
//  * @param module_name The name of the module to load.
//  */
// ecs_import_from_library :: (
//     world: *ecs_world_t,
//     library_name: *u8,
//     module_name: *u8) -> ecs_entity_t #foreign flecs;

// ////////////////////////////////////////////////////////////////////////////////
// //// Components
// ////////////////////////////////////////////////////////////////////////////////

// FLECS__TEcsSystem: ecs_type_t;
// FLECS__TEcsTickSource: ecs_type_t;

// /* Component used to provide a tick source to systems */
// EcsTickSource :: struct {
//     tick: bool;                 /* True if providing tick */
//     time_elapsed: FLECS_FLOAT;  /* Time elapsed since last tick */
// }

////////////////////////////////////////////////////////////////////////////////
//// Systems API
////////////////////////////////////////////////////////////////////////////////

/* System status change callback */
ecs_system_status_t :: enum {
    EcsSystemStatusNone :: 0;
    EcsSystemEnabled;
    EcsSystemDisabled;
    EcsSystemActivated;
    EcsSystemDeactivated;
}

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
ecs_system_status_action_t :: #type (
    world: *ecs_world_t,
    system: ecs_entity_t,
    status: ecs_system_status_t,
    ctx: *void) #c_call;

/* Use with ecs_system_init */
ecs_system_desc_t :: struct {
    /* System entity creation parameters */
    entity: ecs_entity_desc_t;

    /* System query parameters */
    query: ecs_query_desc_t;

    /* System callback, invoked when system is ran */
    callback: ecs_iter_action_t;

    /* System status callback, invoked when system status changes */
    status_callback: ecs_system_status_action_t;

    /* Context to be passed to callback (as ecs_iter_t::param) */
    ctx: *void;

    /* Context to be passed to system status callback */
    status_ctx: *void;

    /* Binding context, for when system is implemented in other language */
    binding_ctx: *void;

    /* Functions that are invoked during system cleanup to free context data.
     * When set, functions are called unconditionally, even when the ctx
     * pointers are NULL. */
    ctx_free: ecs_ctx_free_t;
    status_ctx_free: ecs_ctx_free_t;
    binding_ctx_free: ecs_ctx_free_t;

    /* Interval in seconds at which the system should run */
    interval: FLECS_FLOAT;

    /* Rate at which the system should run */
    rate: int32_t;

    /* External tick soutce that determines when system ticks */
    tick_source: ecs_entity_t;
}

/* Create a system */
ecs_system_init :: (
    world: *ecs_world_t,
    desc: *ecs_system_desc_t) -> ecs_entity_t #foreign flecs;

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
ecs_run :: (
    world: *ecs_world_t,
    system: ecs_entity_t,
    delta_time: FLECS_FLOAT,
    param: *void) -> ecs_entity_t #foreign flecs;

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
ecs_run_worker :: (
    world: *ecs_world_t,
    system: ecs_entity_t,
    stage_current: int32_t,
    stage_count: int32_t,
    delta_time: FLECS_FLOAT,
    param: *void) -> ecs_entity_t #foreign flecs;

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
ecs_run_w_filter :: (
    world: *ecs_world_t,
    system: ecs_entity_t,
    delta_time: FLECS_FLOAT,
    offset: int32_t,
    limit: int32_t,
    filter: *ecs_filter_t,
    param: *void) -> ecs_entity_t #foreign flecs;

/* Get the query object for a system.
 * Systems use queries under the hood. This enables an application to get access
 * to the underlying query object of a system. This can be useful when, for
 * example, an application needs to enable sorting for a system.
 *
 * @param world The world.
 * @param system The system from which to obtain the query.
 * @return The query.
 */
ecs_get_system_query :: (
    world: *ecs_world_t,
    system: ecs_entity_t) -> *ecs_query_t #foreign flecs;

/* Get system context.
 * This operation returns the context pointer set for the system. If
 * the provided entity is not a system, the function will return NULL.
 *
 * @param world The world.
 * @param system The system from which to obtain the context.
 * @return The context.
 */
ecs_get_system_ctx :: (
    world: *ecs_world_t,
    system: ecs_entity_t) -> *void #foreign flecs;

/* Get system binding context.
 * The binding context is a context typically used to attach any language
 * binding specific data that is needed when invoking a callback that is
 * implemented in another language.
 *
 * @param world The world.
 * @param system The system from which to obtain the context.
 * @return The context.
 */
ecs_get_system_binding_ctx :: (
    world: *ecs_world_t,
    system: ecs_entity_t) -> *void #foreign flecs;

// ////////////////////////////////////////////////////////////////////////////////
// //// System debug API
// ////////////////////////////////////////////////////////////////////////////////

// ecs_dbg_system_t :: struct {
//     system: ecs_entity_t;
//     entities_matched_count: int32_t;
//     active_table_count: int32_t;
//     inactive_table_count: int32_t;
//     enabled: bool;
//     system_data: *void;
// }

// ecs_dbg_system :: (
//     world: *ecs_world_t,
//     system: ecs_entity_t,
//     dbg_out: *ecs_dbg_system_t) -> s32 #foreign flecs;

// ecs_dbg_get_column_type :: (
//     world: *ecs_world_t,
//     system: ecs_entity_t,
//     column_index: int32_t) -> ecs_type_t #foreign flecs;

// ecs_dbg_match_entity :: (
//     world: *ecs_world_t,
//     entity: ecs_entity_t,
//     system: ecs_entity_t,
//     failure_info_out: *ecs_match_failure_t) -> bool #foreign flecs;


// ////////////////////////////////////////////////////////////////////////////////
// //// Module
// ////////////////////////////////////////////////////////////////////////////////

// /* Pipeline component is empty: components and tags in module are static */
// FlecsSystem :: struct {
//     dummy: int32_t;
// }

// FlecsSystemImport :: (
//     world: *ecs_world_t) #foreign flecs;

// /*
//  * @file pipeline.h
//  * @brief Pipeline module.
//  *
//  * The pipeline module provides support for running systems automatically and
//  * on multiple threads. A pipeline is a collection of tags that can be added to
//  * systems. When ran, a pipeline will query for all systems that have the tags
//  * that belong to a pipeline, and run them.
//  *
//  * The module defines a number of builtin tags (EcsPreUpdate, EcsOnUpdate,
//  * EcsPostUpdate etc.) that are registered with the builtin pipeline. The
//  * builtin pipeline is ran by default when calling ecs_progress(). An
//  * application can set a custom pipeline with the ecs_set_pipeline function.
//  */

// /* Set a custom pipeline.
//  * This operation sets the pipeline to run when ecs_progress is invoked.
//  *
//  * @param world The world.
//  * @param pipeline The pipeline to set.
//  */
// ecs_set_pipeline :: (
//     world: *ecs_world_t,
//     pipeline: ecs_entity_t) #foreign flecs;

// /* Get the current pipeline.
//  * This operation gets the current pipeline.
//  *
//  * @param world The world.
//  * @param pipeline The pipeline to set.
//  */
// ecs_get_pipeline :: (
//     world: *ecs_world_t) -> ecs_entity_t #foreign flecs;

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
ecs_progress :: (
    world: *ecs_world_t,
    delta_time: FLECS_FLOAT) -> bool #foreign flecs;

// /* Set time scale.
//  * Increase or decrease simulation speed by the provided multiplier.
//  *
//  * @param world The world.
//  * @param scale The scale to apply (default = 1).
//  */
// ecs_set_time_scale :: (
//     world: *ecs_world_t,
//     scale: FLECS_FLOAT) #foreign flecs;

// /* Reset world clock.
//  * Reset the clock that keeps track of the total time passed in the simulation.
//  *
//  * @param world The world.
//  */
// ecs_reset_clock :: (
//     world: *ecs_world_t) #foreign flecs;

// /* Run pipeline.
//  * This will run all systems in the provided pipeline. This operation may be
//  * invoked from multiple threads, and only when staging is disabled, as the
//  * pipeline manages staging and, if necessary, synchronization between threads.
//  *
//  * If 0 is provided for the pipeline id, the default pipeline will be ran (this
//  * is either the builtin pipeline or the pipeline set with set_pipeline()).
//  *
//  * When using progress() this operation will be invoked automatically for the
//  * default pipeline (either the builtin pipeline or the pipeline set with
//  * set_pipeline()). An application may run additional pipelines.
//  *
//  * Note: calling this function from an application currently only works in
//  * single threaded applications with a single stage.
//  *
//  * @param world The world.
//  * @param pipeline The pipeline to run.
//  */
// ecs_pipeline_run :: (
//     world: *ecs_world_t,
//     pipeline: ecs_entity_t,
//     delta_time: FLECS_FLOAT) #foreign flecs;

// /* Deactivate systems that are not matched with tables.
//  * By default Flecs deactivates systems that are not matched with any tables.
//  * However, once a system has been matched with a table it remains activated, to
//  * prevent systems from continuously becoming active and inactive.
//  *
//  * To re-deactivate systems, an application can invoke this function, which will
//  * deactivate all systems that are not matched with any tables.
//  *
//  * @param world The world.
//  */
// ecs_deactivate_systems :: (
//     world: *ecs_world_t) #foreign flecs;


// ////////////////////////////////////////////////////////////////////////////////
// //// Threading
// ////////////////////////////////////////////////////////////////////////////////

// /* Set number of worker threads.
//  * Setting this value to a value higher than 1 will start as many threads and
//  * will cause systems to evenly distribute matched entities across threads. The
//  * operation may be called multiple times to reconfigure the number of threads
//  * used, but never while running a system / pipeline. */
// ecs_set_threads :: (
//     world: *ecs_world_t,
//     threads: int32_t) #foreign flecs;

// ////////////////////////////////////////////////////////////////////////////////
// //// Module
// ////////////////////////////////////////////////////////////////////////////////

// /* Pipeline component is empty: components and tags in module are static */
// FlecsPipeline :: struct {
//     dummy: int32_t;
// }

// FlecsPipelineImport :: (
//     world: *ecs_world_t) #foreign flecs;

// /*
//  * @file timer.h
//  * @brief Timer module.
//  *
//  * Timers can be used to trigger actions at periodic or one-shot intervals. They
//  * are typically used together with systems and pipelines.
//  */

// ////////////////////////////////////////////////////////////////////////////////
// //// Components
// ////////////////////////////////////////////////////////////////////////////////

// FLECS__TEcsTimer: ecs_type_t;
// FLECS__TEcsRateFilter: ecs_type_t;

// /* Component used for one shot/interval timer functionality */
// EcsTimer :: struct {
//     timeout: FLECS_FLOAT;         /* Timer timeout period */
//     time: FLECS_FLOAT;            /* Incrementing time value */
//     fired_count: int32_t;         /* Number of times ticked */
//     active: bool;                 /* Is the timer active or not */
//     single_shot: bool;            /* Is this a single shot timer */
// }

// /* Apply a rate filter to a tick source */
// EcsRateFilter :: struct {
//     src: ecs_entity_t;            /* Source of the rate filter */
//     rate: int32_t;                /* Rate of the rate filter */
//     tick_count: int32_t;          /* Number of times the rate filter ticked */
//     time_elapsed: FLECS_FLOAT;    /* Time elapsed since last tick */
// }


// ////////////////////////////////////////////////////////////////////////////////
// //// Timer API
// ////////////////////////////////////////////////////////////////////////////////

// /* Set timer timeout.
//  * This operation executes any systems associated with the timer after the
//  * specified timeout value. If the entity contains an existing timer, the
//  * timeout value will be reset. The timer can be started and stopped with
//  * ecs_start_timer and ecs_stop_timer.
//  *
//  * The timer is synchronous, and is incremented each frame by delta_time.
//  *
//  * The tick_source entity will be be a tick source after this operation. Tick
//  * sources can be read by getting the EcsTickSource component. If the tick
//  * source ticked this frame, the 'tick' member will be true. When the tick
//  * source is a system, the system will tick when the timer ticks.
//  *
//  * @param world The world.
//  * @param tick_source The timer for which to set the timeout (0 to create one).
//  * @param timeout The timeout value.
//  * @return The timer entity.
//  */
// ecs_set_timeout :: (
//     world: *ecs_world_t,
//     tick_source: ecs_entity_t,
//     timeout: FLECS_FLOAT) -> ecs_entity_t #foreign flecs;

// /* Get current timeout value for the specified timer.
//  * This operation returns the value set by ecs_set_timeout. If no timer is
//  * active for this entity, the operation returns 0.
//  *
//  * After the timeout expires the EcsTimer component is removed from the entity.
//  * This means that if ecs_get_timeout is invoked after the timer is expired, the
//  * operation will return 0.
//  *
//  * The timer is synchronous, and is incremented each frame by delta_time.
//  *
//  * The tick_source entity will be be a tick source after this operation. Tick
//  * sources can be read by getting the EcsTickSource component. If the tick
//  * source ticked this frame, the 'tick' member will be true. When the tick
//  * source is a system, the system will tick when the timer ticks.
//  *
//  * @param world The world.
//  * @param tick_source The timer.
//  * @return The current timeout value, or 0 if no timer is active.
//  */
// ecs_get_timeout :: (
//     world: *ecs_world_t,
//     tick_source: ecs_entity_t) -> FLECS_FLOAT #foreign flecs;

// /* Set timer interval.
//  * This operation will continously invoke systems associated with the timer
//  * after the interval period expires. If the entity contains an existing timer,
//  * the interval value will be reset.
//  *
//  * The timer is synchronous, and is incremented each frame by delta_time.
//  *
//  * The tick_source entity will be be a tick source after this operation. Tick
//  * sources can be read by getting the EcsTickSource component. If the tick
//  * source ticked this frame, the 'tick' member will be true. When the tick
//  * source is a system, the system will tick when the timer ticks.
//  *
//  * @param world The world.
//  * @param tick_source The timer for which to set the interval (0 to create one).
//  * @param interval The interval value.
//  * @return The timer entity.
//  */
// ecs_set_interval :: (
//     world: *ecs_world_t,
//     tick_source: ecs_entity_t,
//     interval: FLECS_FLOAT) -> ecs_entity_t #foreign flecs;

// /* Get current interval value for the specified timer.
//  * This operation returns the value set by ecs_set_interval. If the entity is
//  * not a timer, the operation will return 0.
//  *
//  * @param world The world.
//  * @param tick_source The timer for which to set the interval.
//  * @return The current interval value, or 0 if no timer is active.
//  */
// ecs_get_interval :: (
//     world: *ecs_world_t,
//     tick_source: ecs_entity_t) -> FLECS_FLOAT #foreign flecs;

// /* Start timer.
//  * This operation resets the timer and starts it with the specified timeout. The
//  * entity must have the EcsTimer component (added by ecs_set_timeout and
//  * ecs_set_interval). If the entity does not have the EcsTimer component this
//  * operation will assert.
//  *
//  * @param world The world.
//  * @param tick_source The timer to start.
//  */
// ecs_start_timer :: (
//     world: *ecs_world_t,
//     tick_source: ecs_entity_t) #foreign flecs;

// /* Stop timer
//  * This operation stops a timer from triggering. The entity must have the
//  * EcsTimer component or this operation will assert.
//  *
//  * @param world The world.
//  * @param tick_source The timer to stop.
//  */
// ecs_stop_timer :: (
//     world: *ecs_world_t,
//     tick_source: ecs_entity_t) #foreign flecs;

// /* Set rate filter.
//  * This operation initializes a rate filter. Rate filters sample tick sources
//  * and tick at a configurable multiple. A rate filter is a tick source itself,
//  * which means that rate filters can be chained.
//  *
//  * Rate filters enable deterministic system execution which cannot be achieved
//  * with interval timers alone. For example, if timer A has interval 2.0 and
//  * timer B has interval 4.0, it is not guaranteed that B will tick at exactly
//  * twice the multiple of A. This is partly due to the indeterministic nature of
//  * timers, and partly due to floating point rounding errors.
//  *
//  * Rate filters can be combined with timers (or other rate filters) to ensure
//  * that a system ticks at an exact multiple of a tick source (which can be
//  * another system). If a rate filter is created with a rate of 1 it will tick
//  * at the exact same time as its source.
//  *
//  * If no tick source is provided, the rate filter will use the frame tick as
//  * source, which corresponds with the number of times ecs_progress is called.
//  *
//  * The tick_source entity will be be a tick source after this operation. Tick
//  * sources can be read by getting the EcsTickSource component. If the tick
//  * source ticked this frame, the 'tick' member will be true. When the tick
//  * source is a system, the system will tick when the timer ticks.
//  *
//  * @param world The world.
//  * @param tick_source The rate filter entity (0 to create one).
//  * @param rate The rate to apply.
//  * @param source The tick source (0 to use frames)
//  * @return The filter entity.
//  */
// ecs_set_rate :: (
//     world: *ecs_world_t,
//     tick_source: ecs_entity_t,
//     rate: int32_t,
//     source: ecs_entity_t) -> ecs_entity_t #foreign flecs;

// /* Assign tick source to system.
//  * Systems can be their own tick source, which can be any of the tick sources
//  * (one shot timers, interval times and rate filters). However, in some cases it
//  * is must be guaranteed that different systems tick on the exact same frame.
//  *
//  * This cannot be guaranteed by giving two systems the same interval/rate filter
//  * as it is possible that one system is (for example) disabled, which would
//  * cause the systems to go out of sync. To provide these guarantees, systems
//  * must use the same tick source, which is what this operation enables.
//  *
//  * When two systems share the same tick source, it is guaranteed that they tick
//  * in the same frame. The provided tick source can be any entity that is a tick
//  * source, including another system. If the provided entity is not a tick source
//  * the system will not be ran.
//  *
//  * To disassociate a tick source from a system, use 0 for the tick_source
//  * parameter.
//  *
//  * @param world The world.
//  * @param system The system to associate with the timer.
//  * @param timer The timer to associate with the system.
//  */
// ecs_set_tick_source :: (
//     world: *ecs_world_t,
//     system: ecs_entity_t,
//     tick_source: ecs_entity_t) #foreign flecs;


// ////////////////////////////////////////////////////////////////////////////////
// //// Module
// ////////////////////////////////////////////////////////////////////////////////

// /* Timers module component */
// FlecsTimer :: struct {
//     dummy: int32_t;
// }

// FlecsTimerImport :: (
//     world: *ecs_world_t) #foreign flecs;

// /*
//  * @file bulk.h
//  * @brief Bulk operations operate on all entities that match a provided filter.
//  */

// /* Add an entity to entities matching a filter.
//  * This operation is the same as ecs_add_id, but is applied to all entities
//  * that match the provided filter.
//  *
//  * @param world The world.
//  * @param entity_add The entity to add.
//  * @param filter The filter.
//  */
// ecs_bulk_add_entity :: (
//     world: *ecs_world_t,
//     entity_add: ecs_entity_t,
//     filter: *ecs_filter_t) #foreign flecs;

// /* Add a type to entities matching a filter.
//  * This operation is the same as ecs_add_type but is applied to all entities
//  * that match the provided filter.
//  *
//  * @param world The world.
//  * @param type The type to add.
//  * @param filter The filter.
//  */
// ecs_bulk_add_type :: (
//     world: *ecs_world_t,
//     type: ecs_type_t,
//     filter: *ecs_filter_t) #foreign flecs;

// /* Removes an entity from entities matching a filter.
//  * This operation is the same as ecs_remove_id, but is applied to all
//  * entities that match the provided filter.
//  *
//  * @param world The world.
//  * @param entity_remove The entity to remove.
//  * @param filter The filter.
//  */
// ecs_bulk_remove_entity :: (
//     world: *ecs_world_t,
//     entity_remove: ecs_entity_t,
//     filter: *ecs_filter_t) #foreign flecs;

// /* Remove a type from entities matching a filter.
//  * This operation is the same as ecs_remove_type but is applied to all entities
//  * that match the provided filter.
//  *
//  * @param world The world.
//  * @param type The type to remove.
//  * @param filter The filter.
//  */
// ecs_bulk_remove_type :: (
//     world: *ecs_world_t,
//     type: ecs_type_t,
//     filter: *ecs_filter_t) #foreign flecs;

// /* Add / remove type from entities matching a filter.
//  * Combination of ecs_bulk_add_type and ecs_bulk_remove_type.
//  *
//  * @param world The world.
//  * @param to_add The type to add.
//  * @param to_remove The type to remove.
//  * @param filter The filter.
//  */
// ecs_bulk_add_remove_type :: (
//     world: *ecs_world_t,
//     to_add: ecs_type_t,
//     to_remove: ecs_type_t,
//     filter: *ecs_filter_t) #foreign flecs;

// /* Delete entities matching a filter.
//  * This operation is the same as ecs_delete, but applies to all entities that
//  * match a filter.
//  *
//  * @param world The world.
//  * @param filter The filter.
//  */
// ecs_bulk_delete :: (
//     world: *ecs_world_t,
//     filter: *ecs_filter_t) #foreign flecs;

// /*
//  * @file dbg.h
//  * @brief The debug addon enables requesting internals from entities and tables.
//  */

// /* Unstable API */

// ecs_dbg_entity_t :: struct {
//     entity: ecs_entity_t;
//     table: *ecs_table_t;
//     type: ecs_type_t;
//     row: int32_t;
//     is_watched: bool;
// }

// ecs_dbg_table_t :: struct {
//     table: *ecs_table_t;
//     type: ecs_type_t;
//     shared: ecs_type_t;
//     container: ecs_type_t;
//     parent_entities: ecs_type_t;
//     base_entities: ecs_type_t;
//     systems_matched: *ecs_vector_t;
//     entities: *ecs_entity_t;
//     entities_count: int32_t;
// }

// ecs_dbg_entity :: (
//     world: *ecs_world_t,
//     entity: ecs_entity_t,
//     dbg_out: *ecs_dbg_entity_t) #foreign flecs;

// ecs_dbg_find_table :: (
//     world: *ecs_world_t,
//     type: ecs_type_t) -> *ecs_table_t #foreign flecs;

// ecs_dbg_get_table :: (
//     world: *ecs_world_t,
//     index: int32_t) -> *ecs_table_t #foreign flecs;

// ecs_dbg_filter_table :: (
//     world: *ecs_world_t,
//     table: *ecs_table_t,
//     filter: *ecs_filter_t) -> bool #foreign flecs;

// ecs_dbg_table :: (
//     world: *ecs_world_t,
//     table: *ecs_table_t,
//     dbg_out: *ecs_dbg_table_t) #foreign flecs;

// /*
//  * @file parser.h
//  * @brief Parser addon.
//  *
//  * The parser addon parses string expressions into lists of terms, and can be
//  * used to construct filters, queries and types.
//  */

// /* Parse term in expression.
//  * This operation parses a single term in an expression and returns a pointer
//  * to the next term expression.
//  *
//  * If the returned pointer points to the 0-terminator, the expression is fully
//  * parsed. The function would typically be called in a while loop:
//  *
//  * char *ptr = expr;
//  * while (ptr[0] && (ptr = ecs_parse_term(world, name, expr, ptr, &term))) { }
//  *
//  * The operation does not attempt to find entity ids from the names in the
//  * expression. Use the ecs_term_resolve_ids function to resolve the identifiers
//  * in the parsed term.
//  *
//  * The returned term will in most cases contain allocated resources, which
//  * should freed (or used) by the application. To free the resources for a term,
//  * use the ecs_term_free function.
//  *
//  * The parser accepts expressions in the legacy string format.
//  *
//  * @param world The world.
//  * @param name The name of the expression (optional, improves error logs)
//  * @param expr The expression to parse (optional, improves error logs)
//  * @param ptr The pointer to the current term (must be in expr).
//  * @param term_out Out parameter for the term.
//  * @return pointer to next term if successful, NULL if failed.
//  */
// ecs_parse_term :: (
//     world: *ecs_world_t,
//     name: *u8,
//     expr: *u8,
//     ptr: *u8,
//     term_out: *ecs_term_t) -> *u8 #foreign flecs;

// /*
//  * @file queue.h
//  * @brief Queue datastructure.
//  *
//  * The queue data structure implements a fixed-size ringbuffer. It is not used
//  * by the flecs core, but is used by flecs-hub modules.
//  */

// _ecs_queue_new :: (
//     elem_size: ecs_size_t,
//     offset: int16_t,
//     elem_count: int32_t) -> *ecs_queue_t #foreign flecs;

// _ecs_queue_from_array :: (
//     elem_size: ecs_size_t,
//     offset: int16_t,
//     elem_count: int32_t,
//     array: *void) -> *ecs_queue_t #foreign flecs;

// _ecs_queue_push :: (
//     queue: *ecs_queue_t,
//     elem_size: ecs_size_t,
//     offset: int16_t) -> *void #foreign flecs;

// _ecs_queue_get :: (
//     queue: *ecs_queue_t,
//     elem_size: ecs_size_t,
//     offset: int16_t,
//     index: int32_t) -> *void #foreign flecs;

// _ecs_queue_last :: (
//     queue: *ecs_queue_t,
//     elem_size: ecs_size_t,
//     offset: int16_t) -> *void #foreign flecs;

// ecs_queue_index :: (
//     queue: *ecs_queue_t) -> int32_t #foreign flecs;

// ecs_queue_count :: (
//     queue: *ecs_queue_t) -> int32_t #foreign flecs;

// ecs_queue_free :: (
//     queue: *ecs_queue_t) #foreign flecs;

// /*
//  * @file reader_writer.h
//  * @brief Blob serializer addon.
//  *
//  * The blos serializer addon allows an application to serialize the state of a
//  * world to a blob (a flat byte buffer). The addon contains a reader and writer
//  * API. The reader reads from a world and serializes it to N fixed-size buffers.
//  * The writer reads from N fixed-size buffers and writes to the world.
//  *
//  * The current limitations of the serializer are:
//  * - only POD types
//  * - no support for switch types and component enabling/disabling
//  */

// ecs_blob_header_kind_t :: enum {
//     EcsStreamHeader;

//     /* Stream states */
//     EcsTableSegment;
//     EcsFooterSegment;

//     /* Table segment */
//     EcsTableHeader;
//     EcsTableTypeSize;
//     EcsTableType;
//     EcsTableSize;
//     EcsTableColumn;
//     EcsTableColumnHeader;
//     EcsTableColumnSize;
//     EcsTableColumnData;

//     /* Name column (EcsName) */
//     EcsTableColumnNameHeader;
//     EcsTableColumnNameLength;
//     EcsTableColumnName;

//     EcsStreamFooter;
// }

// ecs_table_reader_t :: struct {
//     state: ecs_blob_header_kind_t;

//     table_index: int32_t;
//     table: *ecs_table_t;
//     data: *ecs_data_t;

//     /* Current index in type */
//     type_written: ecs_size_t;
//     type: ecs_type_t;

//     /* Current column */
//     column_vector: *ecs_vector_t;
//     column_index: int32_t;
//     total_columns: int32_t;

//     /* Keep track of how much of the component column has been written */
//     column_data: *void;
//     column_size: int16_t;
//     column_alignment: int16_t;
//     column_written: ecs_size_t;

//     /* Keep track of row when writing non-blittable data */
//     row_index: int32_t;
//     row_count: int32_t;

//     /* Keep track of how much of an entity name has been written */
//     name: *u8;
//     name_len: ecs_size_t;
//     name_written: ecs_size_t;

//     has_next_table: bool;
// }

// ecs_reader_t :: struct {
//     world: *ecs_world_t;
//     state: ecs_blob_header_kind_t;
//     data_iter: ecs_iter_t;
//     data_next: ecs_iter_next_action_t;
//     component_iter: ecs_iter_t;
//     component_next: ecs_iter_next_action_t;
//     table: ecs_table_reader_t;
// }

// ecs_name_writer_t :: struct {
//     name: *u8;
//     written: int32_t;
//     len: int32_t;
//     max_len: int32_t;
// }

// ecs_table_writer_t :: struct {
//     state: ecs_blob_header_kind_t;

//     table: *ecs_table_t;
//     column_vector: *ecs_vector_t;

//     /* Keep state for parsing type */
//     type_count: int32_t;
//     type_max_count: int32_t;
//     type_written: ecs_size_t;
//     type_array: *ecs_entity_t;

//     column_index: int32_t;
//     column_size: int16_t;
//     column_alignment: int16_t;
//     column_written: ecs_size_t;
//     column_data: *void;

//     row_count: int32_t;
//     row_index: int32_t;
//     name: ecs_name_writer_t;
// }

// ecs_writer_t :: struct {
//     world: *ecs_world_t;
//     state: ecs_blob_header_kind_t;
//     table: ecs_table_writer_t;
//     error: s32;
// }

// /* Initialize a reader.
//  * A reader serializes data in a world to a sequence of bytes that can be stored
//  * in a file or sent across a network.
//  *
//  * @param world The world to serialize.
//  * @return The reader.
//  */
// ecs_reader_init :: (
//     world: *ecs_world_t) -> ecs_reader_t #foreign flecs;

// /* Initialize a snapshot reader.
//  * A snapshot reader serializes data in a snapshot to a sequence of bytes that
//  * can be stored in a file or sent across a network. A snapshot reader has as
//  * advantage that serialization can take place asynchronously while the world
//  * is progressing.
//  *
//  * @param world The world in which the snapshot is taken.
//  * @param iter Iterator to the data to be serialized.
//  * @return The reader.
//  */
// ecs_reader_init_w_iter :: (
//     iter: *ecs_iter_t,
//     next: ecs_iter_next_action_t) -> ecs_reader_t #foreign flecs;

// /* Read from a reader.
//  * This operation reads a specified number of bytes from a reader and stores it
//  * in the specified buffer. When there are no more bytes to read from the reader
//  * the operation will return 0, otherwise it will return the number of bytes
//  * read.
//  *
//  * The specified buffer must be at least as big as the specified size, and the
//  * specified size must be a multiple of 4.
//  *
//  * @param buffer The buffer in which to store the read bytes.
//  * @param size The maximum number of bytes to read.
//  * @param reader The reader from which to read the bytes.
//  * @return The number of bytes read.
//  */
// ecs_reader_read :: (
//     buffer: *u8,
//     size: int32_t,
//     reader: *ecs_reader_t) -> int32_t #foreign flecs;

// /* Initialize a writer.
//  * A writer deserializes data from a sequence of bytes into a world. This
//  * enables applications to restore data from disk or the network.
//  *
//  * The provided world must be either empty or compatible with the data to
//  * deserialize, where compatible means that the serialized component ids and
//  * sizes must match exactly with those in the world. Errors can occur if a world
//  * is provided in which components have been declared in a different order, or
//  * when components have different type definitions.
//  *
//  * @param world The world in which to deserialize the data.
//  * @return The writer.
//  */
// ecs_writer_init :: (
//     world: *ecs_world_t) -> ecs_writer_t #foreign flecs;

// /* Write to a writer.
//  * This operation writes a specified number of bytes from a specified buffer
//  * into the writer. The writer will restore the deserialized data into the
//  * original serialized entities. The write operation may be invoked multiple
//  * times with partial buffers, which allows applications to use static buffers
//  * when reading from, for example, a file or the network.
//  *
//  * The data contained in the buffers must have been serialized with the
//  * ecs_reader_read operation. If the data does not match the expected format, or
//  * the data contains conflicts with the world, the operation will fail. The
//  * data must be provided in the same order as produced by ecs_reader_read,
//  * but the used buffer size does not have to be the same as the one used by
//  * ecs_reader_read. The buffer size must be a multiple of 4.
//  *
//  * @param buffer The buffer to deserialize.
//  * @param size The maximum number of bytes.
//  * @param writer The writer to write to.
//  * @return Zero if success, non-zero if failed to deserialize.
//  */
// ecs_writer_write :: (
//     buffer: *u8,
//     size: int32_t,
//     writer: *ecs_writer_t) -> int32_t #foreign flecs;

// /*
//  * @file snapshot.h
//  * @brief Snapshot addon.
//  *
//  * A snapshot records the state of a world in a way so that it can be restored
//  * later. Snapshots work with POD components and non-POD components, provided
//  * that the appropriate lifecycle actions are registered for non-POD components.
//  *
//  * A snapshot is tightly coupled to a world. It is not possible to restore a
//  * snapshot from world A into world B.
//  */

// /* Create a snapshot.
//  * This operation makes a copy of all component in the world that matches the
//  * specified filter.
//  *
//  * @param world The world to snapshot.
//  * @param return The snapshot.
//  */
// ecs_snapshot_take :: (
//     world: *ecs_world_t) -> *ecs_snapshot_t #foreign flecs;

// /* Create a filtered snapshot.
//  * This operation is the same as ecs_snapshot_take, but accepts an iterator so
//  * an application can control what is stored by the snapshot.
//  *
//  * @param iter An iterator to the data to be stored by the snapshot.
//  * @param next A function pointer to the next operation for the iterator.
//  * @param return The snapshot.
//  */
// ecs_snapshot_take_w_iter :: (
//     iter: *ecs_iter_t,
//     action: ecs_iter_next_action_t) -> *ecs_snapshot_t #foreign flecs;

// /* Restore a snapshot.
//  * This operation restores the world to the state it was in when the specified
//  * snapshot was taken. A snapshot can only be used once for restoring, as its
//  * data replaces the data that is currently in the world.
//  * This operation also resets the last issued entity handle, so any calls to
//  * ecs_new may return entity ids that have been issued before restoring the
//  * snapshot.
//  *
//  * The world in which the snapshot is restored must be the same as the world in
//  * which the snapshot is taken.
//  *
//  * @param world The world to restore the snapshot to.
//  * @param snapshot The snapshot to restore.
//  */
// ecs_snapshot_restore :: (
//     world: *ecs_world_t,
//     snapshot: *ecs_snapshot_t) #foreign flecs;

// /* Obtain iterator to snapshot data.
//  *
//  * @param snapshot The snapshot to iterate over.
//  * @return Iterator to snapshot data. */
// ecs_snapshot_iter :: (
//     snapshot: *ecs_snapshot_t,
//     filter: *ecs_filter_t) -> ecs_iter_t #foreign flecs;

// /* Progress snapshot iterator.
//  *
//  * @param iter The snapshot iterator.
//  * @return True if more data is available, otherwise false.
//  */
// ecs_snapshot_next :: (
//     iter: *ecs_iter_t) -> bool #foreign flecs;


// /* Free snapshot resources.
//  * This frees resources associated with a snapshot without restoring it.
//  *
//  * @param world The world.
//  * @param snapshot The snapshot to free.
//  */
// ecs_snapshot_free :: (
//     snapshot: *ecs_snapshot_t) #foreign flecs;

// /*
//  * @file direct_access.h
//  * @brief Low-level access to underlying data structures for best performance.
//  *
//  * This API allows for low-level direct access to tables and their columns. The
//  * APIs primary intent is to provide fast primitives for new operations. It is
//  * not recommended to use the API directly in application code, as invoking the
//  * API in an incorrect way can lead to a corrupted datastore.
//  */

// /* Find the index of a column in a table.
//  * Table columns are stored in the order of their respective component ids. As
//  * this is not trivial for an application to deduce, this operation returns the
//  * index of a column in a table for a given component. This index can be used
//  * in other table operations to identify a column.
//  *
//  * The returned index is determined separately for each table. Indices obtained
//  * for one table should not be used for another table.
//  *
//  * @param table The table.
//  * @param component The component for which to retrieve the column index.
//  * @return The column index, or -1 if the table does not have the component.
//  */
// ecs_table_find_column :: (
//     table: *ecs_table_t,
//     component: ecs_entity_t) -> int32_t #foreign flecs;

// /* Get table column.
//  * This operation returns the pointer to a column array. A column contains all
//  * the data for a component for the provided table in a contiguous array.
//  *
//  * The returned pointer is not stable, and may change when a table needs to
//  * resize its arrays, for example in order to accomodate for more records.
//  *
//  * @param table The table.
//  * @param column The column index.
//  * @return Vector that contains the column array.
//  */
// ecs_table_get_column :: (
//     table: *ecs_table_t,
//     column: int32_t) -> *ecs_vector_t #foreign flecs;

// /* Set table column.
//  * This operation enables an application to set a component column for a table.
//  * After the operation the column is owned by the table. Any operations that
//  * change the column after this operation can cause undefined behavior.
//  *
//  * Care must be taken that all columns in a table have the same number of
//  * elements. If one column has less elements than another, the behavior is
//  * undefined. The operation will not check if the assigned column is of the same
//  * size as other columns, as this would prevent an application from assigning
//  * a set of different columns to a table of a different size.
//  *
//  * Setting a column will not delete the previous column. It is the
//  * responsibility of the application to ensure that the old column is deleted
//  * properly (using ecs_table_delete_column).
//  *
//  * The provided vector must have the same element size and alignment as the
//  * target column. If the size and/or alignment do not match, the behavior will
//  * be undefined. In debug mode the operation may assert.
//  *
//  * If the provided vector is NULL, the table will ensure that a vector is
//  * created for the provided column. If a vector exists that is not of the
//  * same size as the entities vector, it will be resized to match.
//  *
//  * @param world The world.
//  * @param table The table.
//  * @param column The column index.
//  * @param vector The column data to assing.
//  */
// ecs_table_set_column :: (
//     world: *ecs_world_t,
//     table: *ecs_table_t,
//     column: int32_t,
//     vector: *ecs_vector_t) -> *ecs_vector_t #foreign flecs;

// /* Get the vector containing entity ids for the table.
//  * This operation obtains the vector with entity ids for the current table. Each
//  * entity id is associated with one record, and ids are stored in the same order
//  * as the table records. The element type of the vector is ecs_entity_t.
//  *
//  * @param table The table.
//  * @return The vector containing the table's entities.
//  */
// ecs_table_get_entities :: (
//     table: *ecs_table_t) -> *ecs_vector_t #foreign flecs;

// /* Get the vector containing pointers to entity records.
//  * A table stores cached pointers to entity records for fast access. This
//  * operation provides direct access to the vector. The element type of the
//  * vector is ecs_record_t*.
//  *
//  * @param table The table.
//  * @return The vector containing the entity records.
//  */
// ecs_table_get_records :: (
//     table: *ecs_table_t) -> *ecs_vector_t #foreign flecs;

// /* Clear records.
//  * This operation clears records for a world so that they no longer point to a
//  * table. This is useful to ensure that a world is left in a consistent state
//  * after moving data to destination world.
//  *
//  * @param records The vector with record pointers
//  */
// ecs_records_clear :: (
//     records: *ecs_vector_t) #foreign flecs;

// /* Initialize records.
//  * This operation ensures entity records are updated to the provided table.
//  *
//  * @param world The world.
//  * @param entities The vector with entity identifiers.
//  * @param records The vector with record pointers.
//  * @param table The table in which the entities are stored.
//  */
// ecs_records_update :: (
//     world: *ecs_world_t,
//     entities: *ecs_vector_t,
//     records: *ecs_vector_t,
//     table: *ecs_table_t) #foreign flecs;

// /* Set the vector containing entity ids for the table.
//  * This operation sets the vector with entity ids for a table. In addition the
//  * operation also requires setting a vector with pointers to records. The
//  * record pointers in the vector need to be managed by the entity index. If they
//  * are not, this can cause undefined behavior.
//  *
//  * The provided vectors must have the same number of elements as the number of
//  * records in the table. If the element count is not the same, this causes
//  * undefined behavior.
//  *
//  * A table must have an entity and record vector, even if the table does not
//  * contain entities. For each record that is not an entity, the entity vector
//  * should contain 0, and the record vector should contain NULL.
//  *
//  * @param table The table.
//  * @param entities The entity vector.
//  * @param records The record vector.
//  */
// ecs_table_set_entities :: (
//     table: *ecs_table_t,
//     entities: *ecs_vector_t,
//     records: *ecs_vector_t) #foreign flecs;

// /* Delete a column.
//  * This operation frees the memory of a table column and will invoke the
//  * component destructor if registered.
//  *
//  * The provided vector does not need to be the same as the vector in the table.
//  * The reason the table must be provided is so that the operation can retrieve
//  * the correct destructor for the component. If the component does not have a
//  * destructor, an application can alternatively delete the vector directly.
//  *
//  * If the specified vector is NULL, the column of the table will be removed and
//  * the table will be updated to no longer point at the column. If an explicit
//  * column is provided, the table is not modified. If a column is deleted that is
//  * still being pointed to by a table, behavior is undefined. It is the
//  * responsibility of the application to ensure that a table no longer points to
//  * a deleted column, by using ecs_table_set_column.
//  *
//  * Simultaneously, if this operation is used to delete a table column, the
//  * application should make sure that if the table contains other columns, they
//  * are either also deleted, or that the deleted column is replaced by a column
//  * of the same size. Note that this also goes for the entity and record vectors,
//  * they should have the same number of elements as the other columns.
//  *
//  * The vector must be of the same component as the specified column. If the
//  * vector is not of the same component, behavior will be undefined. In debug
//  * mode the API may assert, though it may not always be able to detect a
//  * mismatching vector/column.
//  *
//  * After this operation the vector should no longer be used by the application.
//  *
//  * @param table The table.
//  * @param column The column index.
//  * @param vector The column vector to delete.
//  */
// ecs_table_delete_column :: (
//     world: *ecs_world_t,
//     table: *ecs_table_t,
//     column: int32_t,
//     vector: *ecs_vector_t) #foreign flecs;

// /* Find a record for a given entity.
//  * This operation finds an existing record in the entity index for a given
//  * entity. The returned pointer is stable for the lifecycle of the world and can
//  * be used as argument for the ecs_record_update operation.
//  *
//  * The returned record (if found) points to the adminstration that relates an
//  * entity id to a table. Updating the value of the returned record will cause
//  * operations like ecs_get and ecs_has to look in the updated table.
//  *
//  * Updating this record to a table in which the entity is not stored causes
//  * undefined behavior.
//  *
//  * When the entity has never been created or is not alive this operation will
//  * return NULL.
//  *
//  * @param world The world.
//  * @param entity The entity.
//  * @return The record that belongs to the entity, or NULL if not found.
//  */
// ecs_record_find :: (
//     world: *ecs_world_t,
//     entity: ecs_entity_t) -> *ecs_record_t #foreign flecs;

// /* Same as ecs_record_find, but creates record if it doesn't exist.
//  * If an entity id has not been created with ecs_new_*, this function can be
//  * used to ensure that a record exists for an entity id. If the provided id
//  * already exists in the world, the operation will return the existing record.
//  *
//  * @param world The world.
//  * @param entity The entity for which to retrieve the record.
//  * @return The (new or existing) record that belongs to the entity.
//  */
// ecs_record_ensure :: (
//     world: *ecs_world_t,
//     entity: ecs_entity_t) -> *ecs_record_t #foreign flecs;

// /* Get value from record.
//  * This operation gets a component value from a record. The provided column
//  * index must match the table of the record.
//  *
//  * @param r The record.
//  * @param column The column index of the component to get.
//  */
// ecs_record_get_column :: (
//     r: *ecs_record_t,
//     column: int32_t,
//     size: size_t) -> *void #foreign flecs;

// /* Copy value to a component for a record.
//  * This operation sets the component value of a single component for a record.
//  * If the component type has a copy action it will be used, otherwise the value
//  * be memcpyd into the component array.
//  *
//  * The provided record does not need to be managed by the entity index but does
//  * need to point to a valid record in the table. If the provided index is
//  * outside of the range indicating the number of records in the table, behavior
//  * is undefined. In debug mode it will cause the operation to assert.
//  *
//  * @param world The world.
//  * @param r The record to set.
//  * @param column The column index of the component to set.
//  * @param size The size of the component.
//  * @param value Pointer to the value to copy.
//  */
// ecs_record_copy_to :: (
//     world: *ecs_world_t,
//     r: *ecs_record_t,
//     column: int32_t,
//     size: size_t,
//     value: *void,
//     count: int32_t) #foreign flecs;

// /* Memcpy value to a component for a record.
//  * Same as ecs_record_copy_to, except that this operation will always use
//  * memcpy. This operation should only be used for components that can be safely
//  * memcpyd. If the operation is used for a component that has a copy or move
//  * action, the behavior is undefined. In debug mode the operation may assert.
//  *
//  * @param world The world.
//  * @param r The record to set.
//  * @param column The column index of the component to set.
//  * @param size The size of the component.
//  * @param value Pointer to the value to move.
//  */
// ecs_record_copy_pod_to :: (
//     world: *ecs_world_t,
//     r: *ecs_record_t,
//     column: int32_t,
//     size: size_t,
//     value: *void,
//     count: int32_t) #foreign flecs;

// /* Move value to a component for a record.
//  * Same as ecs_record_copy_to, except that it uses the move action. If the
//  * component has no move action the value will be memcpyd into the component
//  * array. After this operation the application can no longer assume that the
//  * value passed into the function is valid.
//  *
//  * @param world The world.
//  * @param r The record to set.
//  * @param column The column index of the component to set.
//  * @param size The size of the component.
//  * @param value Pointer to the value to move.
//  */
// ecs_record_move_to :: (
//     world: *ecs_world_t,
//     r: *ecs_record_t,
//     column: int32_t,
//     size: size_t,
//     value: *void,
//     count: int32_t) #foreign flecs;

// /*
//  * @file stats.h
//  * @brief Statistics addon.
//  *
//  * The statistics addon enables an application to obtain detailed metrics about
//  * the storage, systems and operations of a world.
//  */

// ECS_STAT_WINDOW :: 60;

// /* Simple value that indicates current state */
// ecs_gauge_t :: struct {
//     avg: [ECS_STAT_WINDOW] float;
//     min: [ECS_STAT_WINDOW] float;
//     max: [ECS_STAT_WINDOW] float;
// }

// /* Monotonically increasing counter */
// ecs_counter_t :: struct {
//     rate: ecs_gauge_t;                          /* Keep track of deltas too */
//     value: [ECS_STAT_WINDOW] float;
// }

// ecs_world_stats_t :: struct {
//     /* Allows struct to be initialized with {0} */
//     dummy_: int32_t;

//     entity_count: ecs_gauge_t;                 /* Number of entities */
//     component_count: ecs_gauge_t;              /* Number of components */
//     query_count: ecs_gauge_t;                  /* Number of queries */
//     system_count: ecs_gauge_t;                 /* Number of systems */
//     table_count: ecs_gauge_t;                  /* Number of tables */
//     empty_table_count: ecs_gauge_t;            /* Number of empty tables */
//     singleton_table_count: ecs_gauge_t;        /* Number of singleton tables. Singleton tables are tables with just a single entity that contains itself */
//     matched_entity_count: ecs_gauge_t;         /* Number of entities matched by queries */
//     matched_table_count: ecs_gauge_t;          /* Number of tables matched by queries */

//     /* Deferred operations */
//     new_count: ecs_counter_t;
//     bulk_new_count: ecs_counter_t;
//     delete_count: ecs_counter_t;
//     clear_count: ecs_counter_t;
//     add_count: ecs_counter_t;
//     remove_count: ecs_counter_t;
//     set_count: ecs_counter_t;
//     discard_count: ecs_counter_t;

//     /* Timing */
//     world_time_total_raw: ecs_counter_t;       /* Actual time passed since simulation start (first time progress() is called) */
//     world_time_total: ecs_counter_t;           /* Simulation time passed since simulation start. Takes into account time scaling */
//     frame_time_total: ecs_counter_t;           /* Time spent processing a frame. Smaller than world_time_total when load is not 100% */
//     system_time_total: ecs_counter_t;          /* Time spent on processing systems. */
//     merge_time_total: ecs_counter_t;           /* Time spent on merging deferred actions. */
//     fps: ecs_gauge_t;                          /* Frames per second. */
//     delta_time: ecs_gauge_t;                   /* Delta_time. */

//     /* Frame data */
//     frame_count_total: ecs_counter_t;          /* Number of frames processed. */
//     merge_count_total: ecs_counter_t;          /* Number of merges executed. */
//     pipeline_build_count_total: ecs_counter_t; /* Number of system pipeline rebuilds (occurs when an inactive system becomes active). */
//     systems_ran_frame: ecs_counter_t;          /* Number of systems ran in the last frame. */

//     /* Current position in ringbuffer */
//     t: int32_t;
// }

// /* Statistics for a single query (use ecs_get_query_stats) */
// ecs_query_stats_t :: struct {
//     matched_table_count: ecs_gauge_t;       /* Number of matched non-empty tables. This is the number of tables
//                                             * iterated over when evaluating a query. */

//     matched_empty_table_count: ecs_gauge_t; /* Number of matched empty tables. Empty tables are not iterated over when
//                                             * evaluating a query. */

//     matched_entity_count: ecs_gauge_t;      /* Number of matched entities across all tables */

//     /* Current position in ringbuffer */
//     t: int32_t;
// }

// /* Statistics for a single system (use ecs_get_system_stats) */
// ecs_system_stats_t :: struct {
//     query_stats: ecs_query_stats_t;
//     time_spent: ecs_counter_t;       /* Time spent processing a system */
//     invoke_count: ecs_counter_t;     /* Number of times system is invoked */
//     active: ecs_gauge_t;             /* Whether system is active (is matched with >0 entities) */
//     enabled: ecs_gauge_t;            /* Whether system is enabled */
// }

// /* Statistics for all systems in a pipeline. */
// ecs_pipeline_stats_t :: struct {
//     /* Vector with system ids of all systems in the pipeline. The systems are
//      * stored in the order they are executed. Merges are represented by a 0. */
//     systems: *ecs_vector_t;

//     /* Map with system statistics. For each system in the systems vector, an
//      * entry in the map exists of type ecs_system_stats_t. */
//     system_stats: *ecs_map_t;
// }

// /* Get world statistics.
//  * Obtain statistics for the provided world. This operation loops several times
//  * over the tables in the world, and can impact application performance.
//  *
//  * @param world The world.
//  * @param stats Out parameter for statistics.
//  */
// ecs_get_world_stats :: (
//     world: *ecs_world_t,
//     stats: *ecs_world_stats_t) #foreign flecs;

// /* Print world statistics.
//  * Print statistics obtained by ecs_get_world_statistics and in the
//  * ecs_world_info_t struct.
//  *
//  * @param world The world.
//  * @param stats The statistics to print.
//  */
// ecs_dump_world_stats :: (
//     world: *ecs_world_t,
//     stats: *ecs_world_stats_t) #foreign flecs;

// /* Get query statistics.
//  * Obtain statistics for the provided query.
//  *
//  * @param world The world.
//  * @param query The query.
//  * @param stats Out parameter for statistics.
//  */
// ecs_get_query_stats :: (
//     world: *ecs_world_t,
//     query: *ecs_query_t,
//     s: *ecs_query_stats_t) #foreign flecs;

// /* Get system statistics.
//  * Obtain statistics for the provided system.
//  *
//  * @param world The world.
//  * @param system The system.
//  * @param stats Out parameter for statistics.
//  * @return true if success, false if not a system.
//  */
// ecs_get_system_stats :: (
//     world: *ecs_world_t,
//     system: ecs_entity_t,
//     stats: *ecs_system_stats_t) -> bool #foreign flecs;

// /* Get pipeline statistics.
//  * Obtain statistics for the provided pipeline.
//  *
//  * @param world The world.
//  * @param pipeline The pipeline.
//  * @param stats Out parameter for statistics.
//  * @return true if success, false if not a pipeline.
//  */
// ecs_get_pipeline_stats :: (
//     world: *ecs_world_t,
//     pipeline: ecs_entity_t,
//     stats: *ecs_pipeline_stats_t) -> bool #foreign flecs;

// ecs_gauge_reduce :: (
//     dst: *ecs_gauge_t,
//     t_dst: int32_t,
//     src: *ecs_gauge_t,
//     t_src: int32_t) #foreign flecs;

#scope_file

#import "strings";

#if OS == .WINDOWS {
    flecs :: #foreign_library "lib/win64/flecs";
}
