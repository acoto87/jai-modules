AIInitFunc :: #type (aiPlayer: *PlayerInfo);
AINextCommandFunc :: #type (aiPlayer: *PlayerInfo);

Race :: u16;

PlayerInfo :: struct {
    index: u8;
    race: Race;
    resources: HashMap(ResourceKind, s32);
    godMode: bool;
    // features: [MAX_FEATURES_COUNT] bool;
    // upgrades: [MAX_UPGRADES_COUNT] WarUpgrade;
    // squads: [MAX_SQUAD_COUNT] WarSquad;
    // commands: List(WarCommand);
    // tiles: [MAP_TILES_WIDTH * MAP_TILES_HEIGHT] WarMapTile;
    ai: *AI;
}

AI :: struct {
    name: string;

    sleeping: bool;
    sleepTime: f32;

    initFunc: AIInitFunc;
    getCommandFunc: AINextCommandFunc;

    // commands: Queue(WarCommand);
    // systems: WarAISystemsMap;

    customData: *void;
}