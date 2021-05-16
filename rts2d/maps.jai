LevelResult :: enum u8 {
    None;
    Win;
    Lose;
}

MapSpeed :: enum s32 {
    Slowest;
    Slow;
    Normal;
    Faster;
    Fastest;
}

MapSettings :: struct {
    gameSpeed: MapSpeed;
    musicVolume: s32;
    sfxVolume: s32;
    mouseScrollSpeed: MapSpeed;
    keyScrollSpeed: MapSpeed;
}

Map :: struct {
    using base: Scene;
    base.type = SceneType.Map;

    playing: bool;   // Indicates if the map is being played
    custom: bool;    // Indicates if the map is a custom one (not a level)
    replay: bool;    // Indicates that if the map is a replay
    observer: bool;  // Indicates if there is an observer
                     // If the map is a replay, then there is an observer.
                     // If the map is not a replay, then there can be an observer for live matches.
    uiPlayer: s32;   // Index of the player that the UI is being rendering for, by default it's 0
                     // If the map is not a replay and there is no an observer, this uiPlayer index need to be always 0
                     // If the map is a replay and/or there is an observer, this uiPlayer index can be also -1,
                     // indicating that the observer is watching everything (aka FoW is disabled)

    result: LevelResult;

    levelInfoIndex: s32;
    objectivesTime: f32;

    // scroll
    isScrolling: bool;
    wasScrolling: bool;

    settings: MapSettings;
    settings2: MapSettings;

    // viewport in map coordinates,
    // this is the portion of the map that the player see
    viewport: Rect;

    sprite: Sprite;
    minimapSprite: Sprite;
    blackSprite: Sprite;

    selectedEntities: List(EntityId);

    renderDebugGrid: bool;
    renderDebugPassable: bool;
    renderDebugPaths: bool;

    hurryUp: bool;
    fowEnabled: bool;

    finder: PathFinder;
    // uiCommand: WarUICommand;
    // flashStatus: WarFlashStatus;
    // cheatStatus: WarCheatStatus;

    playersCount: s32;
    players: [MAX_PLAYERS_COUNT] PlayerInfo;
}
