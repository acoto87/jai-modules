LevelResult :: enum u8 {
    None;
    Win;
    Lose;
}

MapSpeed :: enum u8 {
    Slowest;
    Slow;
    Normal;
    Faster;
    Fastest;
}

MapSettings :: struct {
    gameSpeed: MapSpeed;
    musicVol: s32;
    sfxVol: s32;
    mouseScrollSpeed: MapSpeed;
    keyScrollSpeed: MapSpeed;
}

Map :: struct {
    using base: Scene;
    // base.type = SceneType.Map;

    tilesWidth: s32;
    tilesHeight: s32;

    playing: bool;  // Indicates if the map is being played
    custom: bool;   // Indicates if the map is a custom one (not a level)
    replay: bool;   // Indicates that if the map is a replay
    observer: bool; // Indicates if there is an observer
                    // If the map is a replay, then there is an observer.
                    // If the map is not a replay, then there can be an observer for live matches.
    uiPlayer: s32;  // Index of the player that the UI is being rendering for, by default it's 0
                    // If the map is not a replay and there is no an observer, this uiPlayer index need to be always 0
                    // If the map is a replay and/or there is an observer, this uiPlayer index can be also -1,
                    // indicating that the observer is watching everything (aka FoW is disabled)

    result: LevelResult;

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

    hurryUp: bool;
    fowEnabled: bool;

    finder: PathFinder;
    // uiCommand: UICommand;
    // flashStatus: FlashStatus;

    playersCount: s32;
    players: [MAX_PLAYERS_COUNT] PlayerInfo;
}

FogPieceType :: enum u8 {
    None;
    TopLeft;
    Top;
    TopRight;
    Left;
    Center;
    Right;
    BottomLeft;
    Bottom;
    BottomRight;
}

FogBoundaryType :: enum u8 {
    None;
    Unkown;
    Fog;
};

MapTileState :: enum_flags u8 {
    Unkown :: 1;
    Fog :: 2;
    Visible :: 4;
}

MapTile :: struct {
    state: MapTileState;
    type: FogPieceType;
    boundary: FogBoundaryType;
}

getMapTileState :: (map: *Map, player: *PlayerInfo, x: s32, y: s32) -> *MapTile {
    assert(inRange(x, 0, map.tilesWidth) && inRange(y, 0, map.tilesHeight));
    return *player.tiles[y * map.tilesWidth + x];
}

// void setMapTileState(WarMap* map, WarPlayerInfo* player, s32 startX, s32 startY, s32 width, s32 height, WarMapTileState tileState)
// {
//     if (startX <= 0)
//         startX = 0;

//     if (startY <= 0)
//         startY = 0;

//     if (startX + width >= MAP_TILES_WIDTH)
//         width = MAP_TILES_WIDTH - startX;

//     if (startY + height >= MAP_TILES_HEIGHT)
//         height = MAP_TILES_HEIGHT - startY;

//     s32 endX = startX + width;
//     s32 endY = startY + height;

//     for(s32 y = startY; y < endY; y++)
//     {
//         for(s32 x = startX; x < endX; x++)
//         {
//             // exclude the corners of the area to get a more "rounded" shape
//             if ((y == startY || y == endY - 1) && (x == startX || x == endX - 1))
//                 continue;

//             WarMapTile* tile = getMapTileState(map, player, x, y);
//             tile->state = tileState;
//         }
//     }
// }

// void setUnitMapTileState(WarMap* map, WarPlayerInfo* player, WarEntity* entity, WarMapTileState tileState)
// {
//     assert(isUnit(entity));

//     s32 sight = getUnitSightRange(entity);

//     vec2 position = getEntityPosition(entity, true);
//     vec2 unitSize = getUnitSize(entity);
//     rect unitRect = rectv(position, unitSize);
//     unitRect = rectExpand(unitRect, sight, sight);

//     setMapTileState(map, player, unitRect.x, unitRect.y, unitRect.width, unitRect.height, tileState);
// }

// bool isTileInState(WarMap* map, WarPlayerInfo* player, s32 x, s32 y, WarMapTileState state)
// {
//     if (!map->fowEnabled)
//     {
//         switch (state)
//         {
//             case MAP_TILE_STATE_UNKOWN: return false;
//             case MAP_TILE_STATE_FOG: return false;
//             case MAP_TILE_STATE_VISIBLE: return true;
//             default:
//             {
//                 logError("Unkown state: %d. Defaulting to true.", state);
//                 return true;
//             }
//         }
//     }

//     WarMapTile* tile = getMapTileState(map, player, x, y);
//     return tile->state == state;
// }

// bool isAnyTileInStates(WarMap* map, WarPlayerInfo* player, s32 startX, s32 startY, s32 width, s32 height, WarMapTileState state)
// {
//     if (!map->fowEnabled)
//     {
//         switch (state)
//         {
//             case MAP_TILE_STATE_UNKOWN: return false;
//             case MAP_TILE_STATE_FOG: return false;
//             case MAP_TILE_STATE_VISIBLE: return true;
//             default:
//             {
//                 logError("Unkown state: %d. Defaulting to true.", state);
//                 return true;
//             }
//         }
//     }

//     if (startX <= 0)
//         startX = 0;

//     if (startY <= 0)
//         startY = 0;

//     if (startX + width >= MAP_TILES_WIDTH)
//         width = MAP_TILES_WIDTH - startX;

//     if (startY + height >= MAP_TILES_HEIGHT)
//         height = MAP_TILES_HEIGHT - startY;

//     s32 endX = startX + width;
//     s32 endY = startY + height;

//     for(s32 y = startY; y < endY; y++)
//     {
//         for(s32 x = startX; x < endX; x++)
//         {
//             WarMapTile* tile = getMapTileState(map, player, x, y);
//             if (tile->state == state)
//             {
//                 return true;
//             }
//         }
//     }

//     return false;
// }

// bool isAnyUnitTileInStates(WarMap* map, WarPlayerInfo* player, WarEntity* entity, WarMapTileState state)
// {
//     assert(isUnit(entity));

//     WarUnitComponent* unit = &entity->unit;

//     vec2 position = getEntityPosition(entity, true);
//     return isAnyTileInStates(map, player, position.x, position.y, unit->sizex, unit->sizey, state);
// }

// bool areAllTilesInState(WarMap* map, WarPlayerInfo* player, s32 startX, s32 startY, s32 width, s32 height, WarMapTileState state)
// {
//     if (!map->fowEnabled)
//     {
//         switch (state)
//         {
//             case MAP_TILE_STATE_UNKOWN: return false;
//             case MAP_TILE_STATE_FOG: return false;
//             case MAP_TILE_STATE_VISIBLE: return true;
//             default:
//             {
//                 logError("Unkown state: %d. Defaulting to true.", state);
//                 return true;
//             }
//         }
//     }

//     if (startX <= 0)
//         startX = 0;

//     if (startY <= 0)
//         startY = 0;

//     if (startX + width >= MAP_TILES_WIDTH)
//         width = MAP_TILES_WIDTH - startX;

//     if (startY + height >= MAP_TILES_HEIGHT)
//         height = MAP_TILES_HEIGHT - startY;

//     s32 endX = startX + width;
//     s32 endY = startY + height;

//     for(s32 y = startY; y < endY; y++)
//     {
//         for(s32 x = startX; x < endX; x++)
//         {
//             WarMapTile* tile = getMapTileState(map, player, x, y);
//             if (tile->state != state)
//             {
//                 return false;
//             }
//         }
//     }

//     return true;
// }

// bool areAllUnitTilesInState(WarMap* map, WarPlayerInfo* player, WarEntity* entity, WarMapTileState state)
// {
//     assert(isUnit(entity));

//     WarUnitComponent* unit = &entity->unit;

//     vec2 position = getEntityPosition(entity, true);
//     return areAllTilesInState(map, player, position.x, position.y, unit->sizex, unit->sizey, state);
// }