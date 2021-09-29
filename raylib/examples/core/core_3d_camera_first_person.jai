/* *****************************************************************************************
*
*   raylib [core] example - 3d camera first person
*
*   This example has been created using raylib 1.3 (www.raylib.com)
*   raylib is licensed under an unmodified zlib/libpng license (View raylib.h for details)
*
*   Copyright (c) 2015 Ramon Santamaria (@raysan5)
*
********************************************************************************************/

#import "raylib";

MAX_COLUMNS : s32 : 20;

main :: ()
{
    // Initialization
    //--------------------------------------------------------------------------------------
    screenWidth : s32 = 800;
    screenHeight : s32 = 450;

    InitWindow(screenWidth, screenHeight, "raylib [core] example - 3d camera first person");

    // Define the camera to look into our 3d world (position, target, up vector)
    camera: Camera;
    camera.position = Vector3.{ 4.0, 2.0, 4.0 };
    camera.target = Vector3.{ 0.0, 1.8, 0.0 };
    camera.up = Vector3.{ 0.0, 1.0, 0.0 };
    camera.fovy = 60.0;
    camera.projection = .CAMERA_PERSPECTIVE;

    // Generates some random columns
    heights: [MAX_COLUMNS] float32;
    positions: [MAX_COLUMNS] Vector3;
    colors: [MAX_COLUMNS] Color;

    for i : 0..MAX_COLUMNS-1
    {
        heights[i] = cast(float32) GetRandomValue(1, 12);

        positions[i] = Vector3Create(
            cast(float32) GetRandomValue(-15, 15),
            heights[i]/2.0,
            cast(float32) GetRandomValue(-15, 15)
        );

        colors[i] = ColorCreate(
            cast(u8) GetRandomValue(20, 255),
            cast(u8) GetRandomValue(10, 55),
            30,
            255
        );
    }

    SetCameraMode(camera, .CAMERA_FIRST_PERSON);    // Set a first person camera mode

    SetTargetFPS(60);                               // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!WindowShouldClose())                    // Detect window close button or ESC key
    {
        // Update
        //----------------------------------------------------------------------------------
        UpdateCamera(*camera);                      // Update camera
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        BeginDrawing();

            ClearBackground(RAYWHITE);

            BeginMode3D(camera);

                DrawPlane(Vector3.{ 0.0, 0.0, 0.0 }, Vector2.{ 32.0, 32.0 }, LIGHTGRAY);    // Draw ground
                DrawCube(Vector3.{ -16.0, 2.5, 0.0 }, 1.0, 5.0, 32.0, BLUE);                // Draw a blue wall
                DrawCube(Vector3.{ 16.0, 2.5, 0.0 }, 1.0, 5.0, 32.0, LIME);                 // Draw a green wall
                DrawCube(Vector3.{ 0.0, 2.5, 16.0 }, 32.0, 5.0, 1.0, GOLD);                 // Draw a yellow wall

                // Draw some cubes around
                for i : 0..MAX_COLUMNS-1
                {
                    DrawCube(positions[i], 2.0, heights[i], 2.0, colors[i]);
                    DrawCubeWires(positions[i], 2.0, heights[i], 2.0, MAROON);
                }

            EndMode3D();

            DrawRectangle( 10, 10, 220, 70, Fade(SKYBLUE, 0.5));
            DrawRectangleLines( 10, 10, 220, 70, BLUE);

            DrawText("First person camera default controls:", 20, 20, 10, BLACK);
            DrawText("- Move with keys: W, A, S, D", 40, 40, 10, DARKGRAY);
            DrawText("- Mouse move to look around", 40, 60, 10, DARKGRAY);

        EndDrawing();
        //----------------------------------------------------------------------------------
    }

    // De-Initialization
    //--------------------------------------------------------------------------------------
    CloseWindow();        // Close window and OpenGL context
    //--------------------------------------------------------------------------------------
}