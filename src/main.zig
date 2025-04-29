const ray = @cImport(@cInclude("raylib.h"));

pub fn main() !void {
    ray.InitWindow(800, 600, "Raylib + Zig Portable");
    defer ray.CloseWindow();

    ray.SetTargetFPS(60);

    while (!ray.WindowShouldClose()) {
        ray.BeginDrawing();
        ray.ClearBackground(ray.RAYWHITE);
        ray.DrawTriangle(
            ray.Vector2{ .x = 400, .y = 100 },
            ray.Vector2{ .x = 300, .y = 500 },
            ray.Vector2{ .x = 500, .y = 500 },
            ray.MAROON,
        );
        ray.EndDrawing();
    }
}
