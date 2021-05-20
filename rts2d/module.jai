#module_parameters (
    MaxPlayersCount: s32 = 8,
    MaxPlayerResourcesCount: s32 = 3,
    MaxMapTilesWidth: s32 = 64,
    MaxMapTilesHeight: s32 = 64
);

#load "constants.jai";
#load "input.jai";
#load "color.jai";
#load "sprites.jai";
#load "font.jai";
#load "render.jai";
#load "animations.jai";
#load "pathfinder.jai";
#load "resources.jai";
#load "entities.jai";
#load "components.jai";
#load "states.jai";
#load "scenes.jai";
#load "players.jai";
#load "ui.jai";
#load "map.jai";
#load "game.jai";
#load "context.jai";

#scope_module

#import "glfw";
#import "GL";
#import "stb_image";
#import "nanovg";
#import "collections";
#import "utils";
