
//@ mouse coordinates are off when the mouse hasn't moved yet...

const std = @import("std");
const ray = @cImport(@cInclude("raylib.h"));

const print = std.debug.print;

pub fn main() !void {
    const windowWidth = 800;
    const windowHeight = 600;
    ray.InitWindow(windowWidth, windowHeight, "Tic Tac Toe");
    defer ray.CloseWindow();

    //ray.SetTargetFPS(1);
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
    //board[0] = 1;
    //board[board.len-1] = -1;
    //board[2] = 1;
    //board[3] = -1;
    //for(board, 0..) |cell, i| {
    //    const x = i % cellsInRow;
    //    const y = i / cellsInRow;
    //    print("{} (x: {}, y: {}): {}\n", .{i, x, y, cell});
    //}
    //print("\n", .{});

    //for (0..10) |n| {
    //    if (ray.IsMouseButtonDown(@intCast(n))) {
    //        print("{}\n", .{n});
    //    }
    //}
    const LEFT_MOUSE = 0;
    //const RIGHT_BUTTON = 1;
    var wasDown: bool = ray.IsMouseButtonDown(@intCast(LEFT_MOUSE));

    var turn: i8 = 1;

    while (!ray.WindowShouldClose()) {
        if (ray.IsMouseButtonDown(@intCast(LEFT_MOUSE))) {
            if (wasDown == false) {
                const x = ray.GetMouseX();
                const y = ray.GetMouseY();
                print("mouse went down at ({}, {})\n", .{x, y});
                if (x >= boardX and x < boardX + boardWidth and y >= boardY and y < boardY + boardWidth) {
                    const bx = @divFloor((x - boardX), cellWidth);
                    const by = @divFloor((y - boardY), cellHeight);
                    print("board: x: {}, y: {}\n", .{bx, by});
                    const index: usize = @intCast(by * cellsInRow + bx);
                    board[index] = turn;
                    turn = if (turn == 1) -1 else 1;
                }
            }

            wasDown = true;
        } else {
            wasDown = false;
        }

        //if (ray.IsMouseButtonDown(@intCast(RIGHT_BUTTON))) {
        //    print("right down\n", .{});
        //}

        //if (ray.IsMouseButtonPressed(@intCast(LEFT_BUTTON))) {
        //    print("left pressed\n", .{});
        //}
        //if (ray.IsMouseButtonPressed(@intCast(RIGHT_BUTTON))) {
        //    print("right pressed\n", .{});
        //}

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
