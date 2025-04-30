
//@ mouse coordinates are off when the mouse hasn't moved yet...

const std = @import("std");
const ray = @cImport(@cInclude("raylib.h"));

const print = std.debug.print;
const assert = std.debug.assert;

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

    const columnsInRow = 3;
    const cellWidth = boardWidth / 3;
    const cellHeight = boardHeight / 3;

    //var board: [3][3]?Stone; //?
    var board = [1]i8{0} ** 9; // -1 (white), 0 (empty), 1 (black)
    var numMovesMade: u8 = 0; 
    var gameOver: bool = false;
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
        if (!gameOver) {
            if (ray.IsMouseButtonDown(@intCast(LEFT_MOUSE))) {
                if (wasDown == false) {
                    const x = ray.GetMouseX();
                    const y = ray.GetMouseY();
                    print("mouse went down at ({}, {})\n", .{x, y});
                    if (x >= boardX and x < boardX + boardWidth and y >= boardY and y < boardY + boardWidth) {
                        const bx = @divFloor((x - boardX), cellWidth);
                        const by = @divFloor((y - boardY), cellHeight);
                        print("board: x: {}, y: {}\n", .{bx, by});
                        assert(bx >= 0 and by >= 0);
                        const index: usize = @intCast(by * columnsInRow + bx);
                        if (board[index] == 0) {
                            // Make a move
                            board[index] = turn;
                            numMovesMade += 1;

                            if (isWin(board[0..], @intCast(bx), @intCast(by), columnsInRow)) {
                                gameOver = true;
                                print("WIN\n", .{});
                                //for (&board) |*cell| {
                                //    cell.* = 0;
                                //}
                            } else if (numMovesMade == 9) {
                                gameOver = true;
                                print("DRAW\n", .{});
                            }

                            turn = if (turn == 1) -1 else 1;
                        } else {
                            print("Can't place a stone there!\n", .{});
                        }
                    }
                }

                wasDown = true;
            } else {
                wasDown = false;
            }
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

        // Draw stones
        for(board, 0..) |cell, j| {
            if (cell == 0) continue;

            const i: u16 = @intCast(j);
            const x = i % columnsInRow;
            const y = i / columnsInRow;
            const stoneX = boardX + x * cellWidth + cellWidth / 2;
            const stoneY = boardY + y * cellHeight + cellHeight / 2;
            const stoneRadius = cellWidth / 3;
            const stoneColor = if(cell == 1) ray.BLACK else ray.WHITE;
            ray.DrawCircle(stoneX, stoneY, stoneRadius, stoneColor);
        }

        if (gameOver) {
            ray.DrawText("Game over", 10, 10, 24, ray.BLACK);
        }

        ray.EndDrawing();
    }
}

fn isWin(board: []i8, lastMoveX: i8, lastMoveY: i8, columnsInRow: u8) bool {
    const lastMoveStone = board[@intCast(lastMoveY * @as(i8, @intCast(columnsInRow)) + lastMoveX)];
    assert(lastMoveStone == 1 or lastMoveStone == -1);

    var stoneCount: usize = undefined;

    stoneCount = 1;
    {
        var dx: i8 = 1;
        while (true) : (dx += 1) {
            const x: isize = lastMoveX + dx;
            const y: isize = lastMoveY;

            if (x > 2) break;
            if (board[@intCast(y * columnsInRow + x)] != lastMoveStone) break;

            stoneCount += 1;
        }
    }
    {
        var dx: i8 = -1;
        while (true) : (dx -= 1) {
            const x: isize = lastMoveX + dx;
            const y: isize = lastMoveY;

            if (x < 0) break;
            if (board[@intCast(y * columnsInRow + x)] != lastMoveStone) break;

            stoneCount += 1;
        }
    }

    if (stoneCount == 3) {
        return true;
    }

    stoneCount = 1;
    {
        var dy: i8 = 1;
        while (true) : (dy += 1) {
            const x: isize = lastMoveX;
            const y: isize = lastMoveY + dy;

            if (y > 2) break;
            if (board[@intCast(y * columnsInRow + x)] != lastMoveStone) break;

            stoneCount += 1;
        }
    }
    {
        var dy: i8 = -1;
        while (true) : (dy -= 1) {
            const x: isize = lastMoveX;
            const y: isize = lastMoveY + dy;

            if (y < 0) break;
            if (board[@intCast(y * columnsInRow + x)] != lastMoveStone) break;

            stoneCount += 1;
        }
    }

    if (stoneCount == 3) {
        return true;
    }

    stoneCount = 1;
    {
        var dx: i8 = 1;
        var dy: i8 = 1;
        while (true) : ({dx += 1; dy += 1;}) {
            const x: isize = lastMoveX + dx;
            const y: isize = lastMoveY + dy;

            if (x > 2 or y > 2) break;
            if (board[@intCast(y * columnsInRow + x)] != lastMoveStone) break;

            stoneCount += 1;
        }
    }
    {
        var dx: i8 = -1;
        var dy: i8 = -1;
        while (true) : ({dx -= 1; dy -= 1;}) {
            const x: isize = lastMoveX + dx;
            const y: isize = lastMoveY + dy;

            if (x < 0 or y < 0) break;
            if (board[@intCast(y * columnsInRow + x)] != lastMoveStone) break;

            stoneCount += 1;
        }
    }

    if (stoneCount == 3) {
        return true;
    }

    stoneCount = 1;
    {
        var dx: i8 = 1;
        var dy: i8 = -1;
        while (true) : ({dx += 1; dy -= 1;}) {
            const x: isize = lastMoveX + dx;
            const y: isize = lastMoveY + dy;

            if (x > 2 or y < 0) break;
            if (board[@intCast(y * columnsInRow + x)] != lastMoveStone) break;

            stoneCount += 1;
        }
    }
    {
        var dx: i8 = -1;
        var dy: i8 = 1;
        while (true) : ({dx -= 1; dy += 1;}) {
            const x: isize = lastMoveX + dx;
            const y: isize = lastMoveY + dy;

            if (x < 0 or y > 2) break;
            if (board[@intCast(y * columnsInRow + x)] != lastMoveStone) break;

            stoneCount += 1;
        }
    }

    if (stoneCount == 3) {
        return true;
    }

    return false;
}
