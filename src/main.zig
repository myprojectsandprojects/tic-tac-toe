
// todo:
// - who won? (black? white?)
// - highlight the winning row in some way (make stones bigger) 
// - play sounds when game ends (win/loss, draw)
// - play sounds when a move is made / stone placed
// - who's turn? 
// - consider different board type (place stones at the grid-line intersections, larger board)

//@ mouse coordinates are off when the mouse hasn't moved yet...

const std = @import("std");
const ray = @cImport(@cInclude("raylib.h"));

const print = std.debug.print;
const assert = std.debug.assert;

const Stone = enum {
    BLACK,
    WHITE,
};
const stoneToString = [2][]const u8{"BLACK", "WHITE"};

pub fn main() !void {
    const windowWidth = 800;
    const windowHeight = 600;
    ray.InitWindow(windowWidth, windowHeight, "Tic Tac Toe");
    defer ray.CloseWindow();

    //ray.SetTargetFPS(1);
    ray.SetTargetFPS(60);

    const boardColor = ray.DARKBROWN;
    const boardX: f32 = 100;
    const boardY: f32 = 100;
    const boardWidth: f32 = 300;
    const boardHeight: f32 = 300;

    const numColumns = 3;
    const numRows = 3;
    const cellWidth: f32 = boardWidth / 3;
    const cellHeight: f32 = boardHeight / 3;

    //var board: [3][3]?Stone; //?
    var board: [9]?Stone = [1]?Stone{null} ** 9;
    var numEmptyCells: u8 = board.len; 
    var gameOver: bool = false;
    var gameOverString: ?[]const u8 = null;

    const LEFT_MOUSE = 0;
    //const RIGHT_BUTTON = 1;
    var wasDown: bool = ray.IsMouseButtonDown(LEFT_MOUSE);

    var turn: Stone = .BLACK;

    while (!ray.WindowShouldClose()) {
        const isDown = ray.IsMouseButtonDown(LEFT_MOUSE);
        const mouseWentDown = isDown and !wasDown;
        wasDown = isDown;

        if (!gameOver) {
            if (mouseWentDown) {
                const x = ray.GetMouseX();
                const y = ray.GetMouseY();
                if (x >= boardX and x < boardX + boardWidth and y >= boardY and y < boardY + boardWidth) {
                    const bx = @as(u8, @intFromFloat(@floor((@as(f32, @floatFromInt(x)) - boardX) / cellWidth)));
                    const by = @as(u8, @intFromFloat(@floor((@as(f32, @floatFromInt(y)) - boardY) / cellHeight)));

                    assert(bx >= 0 and by >= 0);
                    const index: usize = @intCast(by * numColumns + bx);

                    if (board[index] == null) {
                        // Make a move
                        board[index] = turn;
                        numEmptyCells -= 1;

                        //const isGameOver = getGameResult(board[0..], ...);
                        //if (isGameOver.yap) {
                        //    switch (isGameOver.result) {
                        //        .WIN => {
                        //            gameState.gameOn = false;
                        //        },
                        //        .DRAW => {
                        //            gameState.gameOn = false;
                        //        },
                        //    }
                        //} else {
                        //    // switch turn
                        //}

                        if (isWin(board[0..], @intCast(bx), @intCast(by), numColumns)) {
                            gameOver = true;

                            const allocator = std.heap.page_allocator;
                            gameOverString = try std.fmt.allocPrint(allocator, "{s} wins!", .{stoneToString[@intFromEnum(turn)]});

                            print("WIN {s}\n", .{stoneToString[@intFromEnum(turn)]});
                            //for (&board) |*cell| {
                            //    cell.* = 0;
                            //}
                        } else if (numEmptyCells == 0) {
                            gameOver = true;
                            print("DRAW\n", .{});
                        } else {
                            turn = if (turn == .BLACK) .WHITE else .BLACK;
                        }
                    } else {
                        print("Can't place a stone there!\n", .{});
                    }
                }
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
        for (1..numColumns) |i| {
            const x: i32 = @as(i32, @intFromFloat(boardX)) + @as(i32, @intCast(i)) * @as(i32, @intFromFloat(cellWidth));
            ray.DrawLine(x, startY, x, endY, ray.BLACK);
        }

        // Draw horizontal lines
        const startX = boardX;
        const endX = boardX + boardWidth;
        for (1..numRows) |i| {
            const y: i32 = @as(i32, @intFromFloat(boardY)) + @as(i32, @intCast(i)) * @as(i32, @intFromFloat(cellHeight));
            ray.DrawLine(startX, y, endX, y, ray.BLACK);
        }

        // Draw stones
        for (board, 0..) |cell, j| {
            if (cell == null) continue;

            const i: u8 = @intCast(j);
            const x: f32 = @floatFromInt(i % numColumns);
            const y: f32 = @floatFromInt(i / numColumns);
            const stoneX: i32 = @intFromFloat(@round(boardX + x * cellWidth + cellWidth / 2));
            const stoneY = @as(i32, @intFromFloat(@round(boardY + y * cellHeight + cellHeight / 2)));
            const stoneRadius = cellWidth / 3;
            const stoneColor = if(cell == .BLACK) ray.BLACK else ray.WHITE;
            ray.DrawCircle(stoneX, stoneY, stoneRadius, stoneColor);
        }

        if (gameOver) {
            if (gameOverString) |string| {
                ray.DrawText(string.ptr, 10, 10, 24, ray.BLACK);
            } else {
                ray.DrawText("Draw!", 10, 10, 24, ray.BLACK);
            }
        }

        ray.EndDrawing();
    }
}

fn isWin(board: []?Stone, lastMoveX: i8, lastMoveY: i8, columnsInRow: u8) bool {
    const lastMoveStone = board[getIndex(lastMoveX, lastMoveY, columnsInRow)];
    print("type lastMoveStone: {}\n", .{@TypeOf(lastMoveStone)});
    //assert(lastMoveStone == .WHITE or lastMoveStone == .BLACK);
    assert(lastMoveStone != null);

    //var stoneCount: usize = undefined;

    const rows: [4][2]struct{dx: i8, dy: i8} = .{
        .{.{.dx = 1, .dy = 0}, .{.dx = -1, .dy = 0}}, // horizontal (right, left)
        .{.{.dx = 0, .dy = 1}, .{.dx = 0, .dy = -1}}, // vertical (down, up)
        .{.{.dx = 1, .dy = 1}, .{.dx = -1, .dy = -1}}, // 1st diagonal
        .{.{.dx = 1, .dy = -1}, .{.dx = -1, .dy = 1}}, // 2nd diagonal
    };
    _ = rows[0];
    for (rows) |directions| {
        print("{}\n", .{@TypeOf(directions)});
        var stoneCount: u8 = 1;
        for (directions) |direction| {
            print("dx: {}, dy: {}\n", .{direction.dx, direction.dy});

            var dx: i8 = direction.dx;
            var dy: i8 = direction.dy;
            while (true) : ({dx += direction.dx; dy += direction.dy;}) {
                const x = lastMoveX + dx;
                const y = lastMoveY + dy;

                if (x < 0 or x > 2 or y < 0 or y > 2) break;
                if (board[getIndex(x, y, columnsInRow)] != lastMoveStone) break;

                stoneCount += 1;
            }
        }
        
        assert(stoneCount <= 3);
        if (stoneCount == 3) {
            return true;
        }
    }
    return false;

    //stoneCount = 1;
    //{
    //    var dx: i8 = 1;
    //    while (true) : (dx += 1) {
    //        const x = lastMoveX + dx;
    //        const y = lastMoveY;

    //        if (x > 2) break;
    //        if (board[getIndex(x, y, columnsInRow)] != lastMoveStone) break;

    //        stoneCount += 1;
    //    }
    //}
    //{
    //    var dx: i8 = -1;
    //    while (true) : (dx -= 1) {
    //        const x: isize = lastMoveX + dx;
    //        const y: isize = lastMoveY;

    //        if (x < 0) break;
    //        if (board[@intCast(y * columnsInRow + x)] != lastMoveStone) break;

    //        stoneCount += 1;
    //    }
    //}

    //assert(stoneCount <= 3);
    //if (stoneCount == 3) {
    //    return true;
    //}

    //stoneCount = 1;
    //{
    //    var dy: i8 = 1;
    //    while (true) : (dy += 1) {
    //        const x: isize = lastMoveX;
    //        const y: isize = lastMoveY + dy;

    //        if (y > 2) break;
    //        if (board[@intCast(y * columnsInRow + x)] != lastMoveStone) break;

    //        stoneCount += 1;
    //    }
    //}
    //{
    //    var dy: i8 = -1;
    //    while (true) : (dy -= 1) {
    //        const x: isize = lastMoveX;
    //        const y: isize = lastMoveY + dy;

    //        if (y < 0) break;
    //        if (board[@intCast(y * columnsInRow + x)] != lastMoveStone) break;

    //        stoneCount += 1;
    //    }
    //}

    //if (stoneCount == 3) {
    //    return true;
    //}

    //stoneCount = 1;
    //{
    //    var dx: i8 = 1;
    //    var dy: i8 = 1;
    //    while (true) : ({dx += 1; dy += 1;}) {
    //        const x: isize = lastMoveX + dx;
    //        const y: isize = lastMoveY + dy;

    //        if (x > 2 or y > 2) break;
    //        if (board[@intCast(y * columnsInRow + x)] != lastMoveStone) break;

    //        stoneCount += 1;
    //    }
    //}
    //{
    //    var dx: i8 = -1;
    //    var dy: i8 = -1;
    //    while (true) : ({dx -= 1; dy -= 1;}) {
    //        const x: isize = lastMoveX + dx;
    //        const y: isize = lastMoveY + dy;

    //        if (x < 0 or y < 0) break;
    //        if (board[@intCast(y * columnsInRow + x)] != lastMoveStone) break;

    //        stoneCount += 1;
    //    }
    //}

    //if (stoneCount == 3) {
    //    return true;
    //}

    //stoneCount = 1;
    //{
    //    var dx: i8 = 1;
    //    var dy: i8 = -1;
    //    while (true) : ({dx += 1; dy -= 1;}) {
    //        const x: isize = lastMoveX + dx;
    //        const y: isize = lastMoveY + dy;

    //        if (x > 2 or y < 0) break;
    //        if (board[@intCast(y * columnsInRow + x)] != lastMoveStone) break;

    //        stoneCount += 1;
    //    }
    //}
    //{
    //    var dx: i8 = -1;
    //    var dy: i8 = 1;
    //    while (true) : ({dx -= 1; dy += 1;}) {
    //        const x: isize = lastMoveX + dx;
    //        const y: isize = lastMoveY + dy;

    //        if (x < 0 or y > 2) break;
    //        if (board[@intCast(y * columnsInRow + x)] != lastMoveStone) break;

    //        stoneCount += 1;
    //    }
    //}

    //if (stoneCount == 3) {
    //    return true;
    //}

    //return false;
}

fn getIndex(x: i8, y: i8, columnsInRow: u8) usize {
    return @intCast(y * @as(i8, @intCast(columnsInRow)) + x);
}
