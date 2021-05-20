Race :: u8;

PlayerInfo :: struct {
    index: u8;
    race: Race;
    resources: [MAX_PLAYER_RESOURCES_COUNT] s32;
    godMode: bool;
    // features: [MAX_FEATURES_COUNT] bool;
    // upgrades: [MAX_UPGRADES_COUNT] WarUpgrade;
    // squads: [MAX_SQUAD_COUNT] WarSquad;
    // commands: List(WarCommand);
    tiles: [MAX_MAP_TILES_WIDTH * MAX_MAP_TILES_HEIGHT] MapTile;
}
