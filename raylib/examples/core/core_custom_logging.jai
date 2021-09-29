/* *****************************************************************************************
*
*   raylib [core] example - Custom logging
*
*   This example has been created using raylib 2.1 (www.raylib.com)
*   raylib is licensed under an unmodified zlib/libpng license (View raylib.h for details)
*
*   Example contributed by Pablo Marcos Oltra (@pamarcos) and reviewed by Ramon Santamaria (@raysan5)
*
*   Copyright (c) 2018 Pablo Marcos Oltra (@pamarcos) and Ramon Santamaria (@raysan5)
*
********************************************************************************************/

#import "raylib";
#import "Basic";

// Custom logging funtion
LogCustom :: (msgType: s32, text: *u8, args: ..Any) #c_call
{
    newContext: Context;
    push_context newContext {
        now := time(null);
        tm_info := localtime(*now);

        timeStr: [64] u8;
        strftime(timeStr.data, size_of(type_of(timeStr)), "%Y-%m-%d %H:%M:%S", tm_info);
        print("[%] ", timeStr);

        if msgType == {
            case LOG_INFO;      printf("[INFO] : ");
            case LOG_ERROR;     printf("[ERROR]: ");
            case LOG_WARNING;   printf("[WARN] : ");
            case LOG_DEBUG;     printf("[DEBUG]: ");
        }

        print(text, args);
        print("\n");
    }
}

main :: ()
{
    // Initialization
    //--------------------------------------------------------------------------------------
    screenWidth : s32 = 800;
    screenHeight : s32 = 450;

    // First thing we do is setting our custom logger to ensure everything raylib logs
    // will use our own logger instead of its internal one
    SetTraceLogCallback(LogCustom);

    InitWindow(screenWidth, screenHeight, "raylib [core] example - custom logging");

    SetTargetFPS(60);               // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!WindowShouldClose())    // Detect window close button or ESC key
    {
        // Update
        //----------------------------------------------------------------------------------
        // TODO: Update your variables here
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        BeginDrawing();

        ClearBackground(RAYWHITE);

        DrawText("Check out the console output to see the custom logger in action!", 60, 200, 20, LIGHTGRAY);

        EndDrawing();
        //----------------------------------------------------------------------------------
    }

    // De-Initialization
    //--------------------------------------------------------------------------------------
    CloseWindow();        // Close window and OpenGL context
    //--------------------------------------------------------------------------------------
}

#scope_file

time_t :: s64;

tm :: struct {
    sec : s32; // seconds after the minute: [0-60]
    min : s32; // minutes after the hour: [0-59]
    hour : s32; // hours after midnight: [0-23]
    mday : s32; // day of the month: [1-31]
    mon : s32; // months since January: [0-11]
    year : s32; // years since 1900
    wday : s32; // days since Sunday: [0-6]
    yday : s32; // days since January 1: [0-365]
    isdst : s32; // daylight saving time flag: < 0, 0, or > 0

    gmtoff: s64;
    zone: *u8;
}

time :: (t: *time_t) -> time_t #foreign crt;
localtime :: (t: *time_t) -> *tm #foreign crt;
strftime :: (s: *u8, max: size_t, format: *u8, tm: *tm) -> size_t #foreign crt;

#if OS == .WINDOWS {
    crt :: #foreign_system_library "msvcrt";
} else if OS == .LINUX {
    crt :: #foreign_system_library "libc";
}