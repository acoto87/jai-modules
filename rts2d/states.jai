StateType :: enum {
    Idle;
    Move;
    Patrol;
    Follow;
    Attack;
    Gold;
    Mining;
    Wood;
    Chopping;
    Deliver;
    Death;
    Collapse;
    Train;
    Upgrade;
    Build;
    Repair;
    Repairing;
    Cast;
    Wait;
}

State :: struct {
    type: StateType;
    entityId: EntityId;
    nextState: *State;

    nextUpdateTime: f32;
    delay: f32;
}
