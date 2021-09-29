/* *****************************************************************************************
*
*   raylib [core] example - Picking in 3d mode
*
*   This example has been created using raylib 1.3 (www.raylib.com)
*   raylib is licensed under an unmodified zlib/libpng license (View raylib.h for details)
*
*   Copyright (c) 2015 Ramon Santamaria (@raysan5)
*
********************************************************************************************/

#import "raylib";

main :: ()
{
    // Initialization
    //--------------------------------------------------------------------------------------
    screenWidth : s32 = 800;
    screenHeight : s32 = 450;

    InitWindow(screenWidth, screenHeight, "raylib [core] example - 3d picking");

    // Define the camera to look into our 3d world
    camera: Camera;
    camera.position = Vector3.{ 10.0, 10.0, 10.0 };     // Camera position
    camera.target = Vector3.{ 0.0, 0.0, 0.0 };          // Camera looking at point
    camera.up = Vector3.{ 0.0, 1.0, 0.0 };              // Camera up vector (rotation towards target)
    camera.fovy = 45.0;                                 // Camera field-of-view Y
    camera.projection = .CAMERA_PERSPECTIVE;            // Camera mode type

    cubePosition := Vector3.{ 0.0, 1.0, 0.0 };
    cubeSize := Vector3.{ 2.0, 2.0, 2.0 };

    ray: Ray;                                           // Picking line ray

    collision := false;

    SetCameraMode(camera, .CAMERA_FREE); // Set a free camera mode

    SetTargetFPS(60);                   // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!WindowShouldClose())        // Detect window close button or ESC key
    {
        // Update
        //----------------------------------------------------------------------------------
        UpdateCamera(*camera);          // Update camera

        if (IsMouseButtonPressed(.MOUSE_LEFT_BUTTON))
        {
            if (!collision)
            {
                ray = GetMouseRay(GetMousePosition(), camera);

                // Check collision between ray and box
                min := Vector3Create(cubePosition.x - cubeSize.x/2, cubePosition.y - cubeSize.y/2, cubePosition.z - cubeSize.z/2);
                max := Vector3Create(cubePosition.x + cubeSize.x/2, cubePosition.y + cubeSize.y/2, cubePosition.z + cubeSize.z/2);
                bb := BoundingBoxCreate(min, max);
                collision = CheckCollisionRayBox(ray, bb);
            }
            else
            {
                collision = false;
            }
        }
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        BeginDrawing();

            ClearBackground(RAYWHITE);

            BeginMode3D(camera);

                if (collision)
                {
                    DrawCube(cubePosition, cubeSize.x, cubeSize.y, cubeSize.z, RED);
                    DrawCubeWires(cubePosition, cubeSize.x, cubeSize.y, cubeSize.z, MAROON);

                    DrawCubeWires(cubePosition, cubeSize.x + 0.2, cubeSize.y + 0.2, cubeSize.z + 0.2, GREEN);
                }
                else
                {
                    DrawCube(cubePosition, cubeSize.x, cubeSize.y, cubeSize.z, GRAY);
                    DrawCubeWires(cubePosition, cubeSize.x, cubeSize.y, cubeSize.z, DARKGRAY);
                }

                DrawRay(ray, MAROON);
                DrawGrid(10, 1.0);

            EndMode3D();

            DrawText("Try selecting the box with mouse!", 240, 10, 20, DARKGRAY);

            if (collision)
            {
                DrawText("BOX SELECTED", (screenWidth - MeasureText("BOX SELECTED", 30)) / 2, cast(s32) (screenHeight * 0.1), 30, GREEN);
            }

            DrawFPS(10, 10);

        EndDrawing();
        //----------------------------------------------------------------------------------
    }

    // De-Initialization
    //--------------------------------------------------------------------------------------
    CloseWindow();        // Close window and OpenGL context
    //--------------------------------------------------------------------------------------
}
