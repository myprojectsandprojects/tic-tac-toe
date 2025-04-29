const std = @import("std");
const ray = @cImport(@cInclude("raylib.h"));

const print = std.debug.print;

pub fn main() !void {
    const windowWidth = 800;
    const windowHeight = 600;
    ray.InitWindow(windowWidth, windowHeight, "Tic Tac Toe");
    defer ray.CloseWindow();

    ray.SetTargetFPS(60);

    const boardColor: ray.Color = ray.DARKBROWN;
    const boardX = 100;
    const boardY = 100;
    const boardWidth = 300;
    const boardHeight = 300;

    const cellsInRow = 3;
    const cellWidth = boardWidth / 3;
    const cellHeight = boardHeight / 3;

    var board = [1]i8{0} ** 9; // -1 (white), 0 (empty), 1 (black)
    board[0] = 1;
    board[board.len-1] = -1;
    board[2] = 1;
    board[3] = -1;
    for(board, 0..) |cell, i| {
        const x = i % cellsInRow;
        const y = i / cellsInRow;
        print("{} (x: {}, y: {}): {}\n", .{i, x, y, cell});
    }
    print("\n", .{});

    while (!ray.WindowShouldClose()) {
        ray.BeginDrawing();
        ray.ClearBackground(ray.BEIGE);

        // Draw board
        ray.DrawRectangle(boardX, boardY, boardWidth, boardHeight, boardColor);

        // Draw vertical lines
        const shortenBy = 10;
        const startY = boardY + shortenBy;
        const endY = boardY + boardHeight - shortenBy;
        for (1..3) |i| {
            const x: i32 = boardX + @as(i32, @intCast(i)) * cellWidth;
            ray.DrawLine(x, startY, x, endY, ray.BLACK);
        }

        // Draw horizontal lines
        const startX = boardX;
        const endX = boardX + boardWidth;
        for (1..3) |i| {
            const y: i32 = boardY + @as(i32, @intCast(i)) * cellHeight;
            ray.DrawLine(startX, y, endX, y, ray.BLACK);
        }

        for(board, 0..) |cell, j| {
            if (cell == 0) continue;

            const i: u16 = @intCast(j);
            const x = i % cellsInRow;
            const y = i / cellsInRow;
            const stoneX = boardX + x * cellWidth + cellWidth / 2;
            const stoneY = boardY + y * cellHeight + cellHeight / 2;
            const stoneRadius = cellWidth / 3;
            const stoneColor = if(cell == 1) ray.BLACK else ray.WHITE;
            ray.DrawCircle(stoneX, stoneY, stoneRadius, stoneColor);
        }

        ray.EndDrawing();
    }
}
