
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

const GameResult = enum {
    WIN_LOSS,
    DRAW
};

//const Game = struct {
//    players: [2]Player,
//    wasDraw: bool,
//    winner: ?*Player // null if draw
//};

const Player = struct {
    name: []const u8,
    stones: Stone,
    isComputer: bool,
};

fn stoneToString(stone: Stone) []const u8 {
    const stoneNames = [2][]const u8{"BLACK", "WHITE"};
    return stoneNames[@intFromEnum(stone)];
}

pub fn main() !void {
    const windowWidth = 801;
    const windowHeight = 601;
    ray.InitWindow(windowWidth, windowHeight, "Tic Tac Toe");
    defer ray.CloseWindow();

    //ray.SetTargetFPS(1);
    ray.SetTargetFPS(60);

    const players = [2]Player{
        .{.name="Joey", .stones=Stone.BLACK, .isComputer=false},
        .{.name="WHITE", .stones=Stone.WHITE, .isComputer=false}
    };
    var gameResult: ?GameResult = null;
    var winner: ?*const Player = null;

    const boardColor = ray.DARKBROWN;
    const boardWidth: f32 = 300;
    const boardHeight: f32 = 300;
    const boardX: f32 = @as(f32, @floatFromInt(windowWidth)) / 2 - boardWidth / 2;
    const boardY: f32 = @as(f32, @floatFromInt(windowHeight)) / 2 - boardHeight / 2;
    print("boardX: {d}\n", .{boardX});

    const numColumns = 3;
    const numRows = 3;
    const cellWidth: f32 = boardWidth / 3;
    const cellHeight: f32 = boardHeight / 3;

    //var board: [3][3]?Stone; //?
    var board: [9]?Stone = [1]?Stone{null} ** 9;
    var numEmptyCells: u8 = board.len; 

    var turn: *const Player = &players[0];

    var gameOver: bool = false;
    //const allocator = std.heap.page_allocator;
    //var gameMessage: []const u8 = try std.fmt.allocPrint(allocator, "{s}'s move...", .{stoneToString(turn)});

    const LEFT_MOUSE = 0;
    //const RIGHT_BUTTON = 1;
    var wasDown: bool = ray.IsMouseButtonDown(LEFT_MOUSE);

    var angle: f32 = 0;
    //var angle: f32 = std.math.pi / 2.0;
    var playAnimation = false;

    while (!ray.WindowShouldClose()) {
        const isDown = ray.IsMouseButtonDown(LEFT_MOUSE);
        const mouseWentDown = isDown and !wasDown;
        wasDown = isDown;

        if (!gameOver) {
            if (mouseWentDown) {
                const x = ray.GetMouseX();
                const y = ray.GetMouseY();
                if (x >= @round(boardX) and x < @round(boardX + boardWidth) and y >= @round(boardY) and y < @round(boardY + boardHeight)) {
                    const bx = @as(u8, @intFromFloat(@floor((@as(f32, @floatFromInt(x)) - boardX) / cellWidth)));
                    const by = @as(u8, @intFromFloat(@floor((@as(f32, @floatFromInt(y)) - boardY) / cellHeight)));

                    assert(bx >= 0 and by >= 0);
                    assert(bx < numColumns and by < numRows);
                    const index: usize = @intCast(by * numColumns + bx);

                    if (board[index] == null) {
                        // Make a move
                        board[index] = turn.stones;
                        numEmptyCells -= 1;

                        playAnimation = true;

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
                            gameResult = GameResult.WIN_LOSS;
                            winner = turn;

                            print("{s} wins\n", .{winner.?.name});

                            //allocator.free(gameMessage);
                            //gameMessage = try std.fmt.allocPrint(allocator, "{s} wins!", .{stoneToString(turn)});

                            //for (&board) |*cell| {
                            //    cell.* = 0;
                            //}
                        } else if (numEmptyCells == 0) {
                            gameOver = true;
                            gameResult = GameResult.DRAW;

                            print("draw\n", .{});

                            //allocator.free(gameMessage);
                            //gameMessage = try std.fmt.allocPrint(allocator, "A draw.", .{});
                        } else {
                            turn = if (turn == &players[0]) &players[1] else &players[0];

                            //allocator.free(gameMessage);
                            //gameMessage = try std.fmt.allocPrint(allocator, "{s}'s move...", .{stoneToString(turn)});
                        }
                    } else {
                        print("Can't place a stone there!\n", .{});
                    }
                } else {
                    print("Mouse not on board.\n", .{});
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
        ray.DrawRectangle(@round(boardX), @round(boardY), @round(boardWidth), @round(boardHeight), boardColor);

        // Draw vertical lines
        const shortenBy = 10;
        const startY = @round(boardY + shortenBy);
        const endY = @round(boardY + boardHeight - shortenBy);
        for (1..numColumns) |i| {
            const x: i32 = @as(i32, @intFromFloat(boardX)) + @as(i32, @intCast(i)) * @as(i32, @intFromFloat(cellWidth));
            ray.DrawLine(x, startY, x, endY, ray.BLACK);
        }

        // Draw horizontal lines
        const startX = @round(boardX);
        const endX = @round(boardX + boardWidth);
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

        //ray.DrawText(gameMessage.ptr, 10, 10, 24, ray.BLACK);

        //const stonesY = y + r;
        //const stonesX = [2]i32{
        //    x + r, // player 1
        //    x + r + 2 * r // player 2
        //};
        //const colors = [2]ray.Color{
        //    ray.BLACK, // black
        //    ray.WHITE // white
        //};
        //const invert = [2]usize{1, 0}; //@
        //const n = @intFromEnum(turn);

        //if (gameResult) |result| {
        //    if (result == GameResult.WIN_LOSS) {
        //        print("{s} WON\n", .{stoneToString(winner.?.stones)});

        //        // draw smaller first
        //        ray.DrawCircle(stonesX[invert[n]], stonesY, 16, colors[invert[n]]);
        //        // then draw bigger
        //        ray.DrawCircle(stonesX[n], stonesY, 24, colors[n]);
        //    } else {
        //        assert(result == GameResult.DRAW);
        //        print("Game over -- DRAW\n", .{});

        //        // draw smaller first
        //        ray.DrawCircle(stonesX[invert[n]], stonesY, 16, colors[invert[n]]);
        //        // then draw bigger
        //        ray.DrawCircle(stonesX[n], stonesY, 16, colors[n]);
        //    }
        //} else {
        //    print("Game on\n", .{});

        //    // draw smaller first
        //    ray.DrawCircle(stonesX[invert[n]], stonesY, 16, colors[invert[n]]);
        //    // then draw bigger
        //    ray.DrawCircle(stonesX[n], stonesY, 24, colors[n]);
        //}

        const colors = [_]ray.Color{
            ray.BLACK,
            ray.WHITE,
        };
        var turnStoneColor = colors[@intFromEnum(turn.stones)];

        const x: f32 = 24.1;
        const y: f32 = 24;
        const maxWidth = 64;
        const maxHeight = 64;

        var width: f32 = maxWidth;
        const height: f32 = maxHeight;
        if (playAnimation) {
            print("animation (angle = {d})\n", .{angle});
            width = maxWidth * @abs(std.math.cos(angle));
            if (angle < std.math.pi / 2.0) {
                turnStoneColor = if(@intFromEnum(turn.stones) == 0) colors[1] else colors[0];
            }
            //angle += std.math.pi / 128.0;
            angle += std.math.pi / 32.0;
            //angle += std.math.pi / 16.0;
            if (angle >= std.math.pi) {
                playAnimation = false;
                angle = 0;
            }
        }

        ray.DrawRectangle(@intFromFloat(@round(x + ((maxWidth - width) / 2))), @round(y), @intFromFloat(@round(width)), maxHeight, ray.BROWN);

        const radiusH = width / 2;
        const radiusV = height / 2;
        const centerX: i32 = @intFromFloat(@round(x + maxWidth / 2));
        const centerY: i32 = @intFromFloat(@round(y + maxHeight / 2));
        ray.DrawEllipse(centerX, centerY, radiusH * 0.7, radiusV * 0.7, turnStoneColor);
        //ray.DrawEllipse(centerX, centerY, radiusH * 0.5, radiusV * 0.5, turnStoneColor);

        const lineThick = 6;
        const rectWidth = if(width < lineThick) lineThick else width;
        const rectangle = ray.Rectangle{.x = x + (maxWidth - rectWidth) / 2, .y = y, .width = rectWidth, .height = height};
        //const rectangle = ray.Rectangle{.x = x - lineThick, .y = y - lineThick, .width = width + 2 * lineThick, .height = height + 2 * lineThick};
        ray.DrawRectangleLinesEx(rectangle, lineThick, ray.RED);
        //ray.DrawRectangleLinesEx(rectangle, lineThick, ray.DARKBROWN);

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
}

fn getIndex(x: i8, y: i8, columnsInRow: u8) usize {
    return @intCast(y * @as(i8, @intCast(columnsInRow)) + x);
}
