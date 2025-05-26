
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
    WIN,
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

const GameState = struct {
    players: [2]Player,
    playerToMove: *const Player,
    board: [9]?Stone,
    numEmptyCells: u8,
    gameResult: ?GameResult, // 'null' if game is on
    winner: ?*const Player,

    //?
    winningRow: [3]i8,

    //@ board size should depend on these:
    numColumns: i8,
    numRows: i8,
};

fn stoneToString(stone: Stone) []const u8 {
    const stoneNames = [2][]const u8{"BLACK", "WHITE"};
    return stoneNames[@intFromEnum(stone)];
}

fn getRandomNumber(max: usize) usize {
    // Seed with current time or other entropy
    var prng = std.Random.Xoshiro256.init(@intCast(std.time.milliTimestamp()));

    // Get the Random interface
    const rand = prng.random();

    // Generate a random u8 between 0 and 255
    const r = rand.int(usize);

    return r % max+1;
}

pub fn main() !void {
    const windowWidth = 801;
    const windowHeight = 601;
    ray.InitWindow(windowWidth, windowHeight, "Tic Tac Toe");
    defer ray.CloseWindow();

    //ray.SetTargetFPS(1);
    ray.SetTargetFPS(60);

    const player1 = Player {.name="Black", .stones=Stone.BLACK, .isComputer=false};
    const player2 = Player {.name="White", .stones=Stone.WHITE, .isComputer=true};

    var gameState: GameState = GameState {
        .players = [2]Player {player1, player2},
        .playerToMove = undefined,
        .board = [1]?Stone{null} ** 9,
        .numEmptyCells = undefined,
        .gameResult = null,
        .winner = null,
        .winningRow = undefined,
        .numColumns = 3,
        .numRows = 3,
    };
    gameState.playerToMove = &gameState.players[0];
    gameState.numEmptyCells = gameState.board.len;
    print("{s}\n", .{gameState.players[0].name});

    const boardColor = ray.DARKBROWN;
    const boardWidth: f32 = 300;
    const boardHeight: f32 = 300;
    const boardX: f32 = @as(f32, @floatFromInt(windowWidth)) / 2 - boardWidth / 2;
    const boardY: f32 = @as(f32, @floatFromInt(windowHeight)) / 2 - boardHeight / 2;
    print("boardX: {d}\n", .{boardX});

    const cellWidth: f32 = boardWidth / 3;
    const cellHeight: f32 = boardHeight / 3;

    //const allocator = std.heap.page_allocator;
    //var gameMessage: []const u8 = try std.fmt.allocPrint(allocator, "{s}'s move...", .{stoneToString(turn)});

    const LEFT_MOUSE = 0;
    //const RIGHT_BUTTON = 1;
    var wasDown: bool = ray.IsMouseButtonDown(LEFT_MOUSE);

    var angle: f32 = 0;
    //var angle: f32 = std.math.pi / 2.0;
    var playAnimation = false;

    var waitMode = false;
    var waitedNumFrames: usize = undefined;

    // winning row animation
    // 1 -> 1.1
    var winningRowAnimation = false;
    const radiusFactorMax: f32 = 1.1;
    const radiusFactorMin: f32 = 1.0;
    const incr = (radiusFactorMax - radiusFactorMin) / 16;
    var radiusFactor: f32 = radiusFactorMin;

    while (!ray.WindowShouldClose()) {
        if (winningRowAnimation) {
            radiusFactor += incr;
            if(radiusFactor > radiusFactorMax) radiusFactor = radiusFactorMax;
            if(radiusFactor == radiusFactorMax) winningRowAnimation = false;
        }

        if (gameState.gameResult == null and gameState.playerToMove.isComputer) {
            if (!waitMode) {
                waitMode = true;
                waitedNumFrames = 1;
            } else {
                if (waitedNumFrames == 3 * 60) {
                    waitMode = false;

                    // generate a random integer in range 0 ... numEmptyCells-1
                    const random = getRandomNumber(gameState.numEmptyCells-1);
                    assert(random > -1 and random < gameState.numEmptyCells);

                    var count: usize = 0;
                    for (gameState.board, 0..) |cell, index| {
                        if (cell == null) {
                            if (count == random) {
                                makeMove(&gameState, index);
                                if(gameState.gameResult) |result| {
                                    switch(result) {
                                        .WIN => {
                                            print("{s} wins!\n", .{gameState.playerToMove.name});
                                        },
                                        .DRAW => {
                                            print("A draw!\n", .{});
                                        },
                                    }
                                } else {
                                    playAnimation = true;
                                }

                                break;
                            } else {
                                count += 1;
                            }
                        }
                    }
                } else {
                    print("waiting...\n", .{});
                    waitedNumFrames += 1;
                }
            }
        }

        const isDown = ray.IsMouseButtonDown(LEFT_MOUSE);
        const mouseWentDown = isDown and !wasDown;
        wasDown = isDown;

        if (gameState.gameResult == null and !gameState.playerToMove.isComputer) {
            if (mouseWentDown) {
                const x = ray.GetMouseX();
                const y = ray.GetMouseY();
                if (x >= @round(boardX) and x < @round(boardX + boardWidth) and y >= @round(boardY) and y < @round(boardY + boardHeight)) {
                    const bx = @as(i8, @intFromFloat(@floor((@as(f32, @floatFromInt(x)) - boardX) / cellWidth)));
                    const by = @as(i8, @intFromFloat(@floor((@as(f32, @floatFromInt(y)) - boardY) / cellHeight)));

                    assert(bx >= 0 and by >= 0);
                    assert(bx < gameState.numColumns and by < gameState.numRows);
                    const index: usize = @intCast(by * gameState.numColumns + bx);

                    if (gameState.board[index] == null) {
                        makeMove(&gameState, index);
                        if (gameState.gameResult) |result| {
                            switch(result) {
                                .WIN => {
                                    print("{s} wins!\n", .{gameState.winner.?.name});
                                    winningRowAnimation = true;
                                },
                                .DRAW => {
                                    print("A draw!\n", .{});
                                },
                            }
                        } else {
                            playAnimation = true;
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
        for (1..@intCast(gameState.numColumns)) |i| {
            const x: i32 = @as(i32, @intFromFloat(boardX)) + @as(i32, @intCast(i)) * @as(i32, @intFromFloat(cellWidth));
            ray.DrawLine(x, startY, x, endY, ray.BLACK);
        }

        // Draw horizontal lines
        const startX = @round(boardX);
        const endX = @round(boardX + boardWidth);
        for (1..@intCast(gameState.numRows)) |i| {
            const y: i32 = @as(i32, @intFromFloat(boardY)) + @as(i32, @intCast(i)) * @as(i32, @intFromFloat(cellHeight));
            ray.DrawLine(startX, y, endX, y, ray.BLACK);
        }

        // Draw stones
        for (0..gameState.board.len) |j| {
            if (gameState.board[j] == null) continue;

            const i: i8 = @intCast(j);

            var isWinningStone = false;
            if(gameState.winner != null) {
                for(gameState.winningRow) |wi| {
                    if(wi == i) {
                        isWinningStone = true;
                        break;
                    }
                }
            }

            //const x = i % gameState.numColumns;
            const x: f32 = @floatFromInt(@as(u8, @intCast(i)) % @as(u8, @intCast(gameState.numColumns)));
            const y: f32 = @floatFromInt(@as(u8, @intCast(i)) / @as(u8, @intCast(gameState.numColumns)));
            const stoneX: i32 = @intFromFloat(@round(boardX + x * cellWidth + cellWidth / 2));
            const stoneY = @as(i32, @intFromFloat(@round(boardY + y * cellHeight + cellHeight / 2)));
            const stoneRadius = cellWidth / 3;
            const actualStoneRadius = if(isWinningStone) stoneRadius * radiusFactor else stoneRadius;
            const stoneColor = if(gameState.board[j] == .BLACK) ray.BLACK else ray.WHITE;
            ray.DrawCircle(stoneX, stoneY, actualStoneRadius, stoneColor);
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

        if (gameState.gameResult == null) {
            const colors = [_]ray.Color{
                ray.BLACK,
                ray.WHITE,
            };
            var turnStoneColor = colors[@intFromEnum(gameState.playerToMove.stones)];

            const x: f32 = 24.1;
            const y: f32 = 24;
            const maxWidth = 64;
            const maxHeight = 64;

            var width: f32 = maxWidth;
            const height: f32 = maxHeight;
            if (playAnimation) {
                //print("animation (angle = {d})\n", .{angle});
                width = maxWidth * @abs(std.math.cos(angle));
                if (angle < std.math.pi / 2.0) {
                    turnStoneColor = if(@intFromEnum(gameState.playerToMove.stones) == 0) colors[1] else colors[0];
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
        }

        ray.EndDrawing();
    }
}

fn isWin(board: []?Stone, index: usize, columnsInRow: i8, gameState: *GameState) bool {
    const lastMoveStone = board[index];
    assert(lastMoveStone != null);
    const lastMoveX: i8 = @intCast(index % @as(u8, @intCast(columnsInRow)));
    const lastMoveY: i8 = @intCast(index / @as(u8, @intCast(columnsInRow)));
    //const lastMoveStone = board[getIndex(lastMoveX, lastMoveY, columnsInRow)];

    //var stoneCount: usize = undefined;

    const rows: [4][2]struct{dx: i8, dy: i8} = .{
        .{.{.dx = 1, .dy = 0}, .{.dx = -1, .dy = 0}}, // horizontal (right, left)
        .{.{.dx = 0, .dy = 1}, .{.dx = 0, .dy = -1}}, // vertical (down, up)
        .{.{.dx = 1, .dy = 1}, .{.dx = -1, .dy = -1}}, // 1st diagonal
        .{.{.dx = 1, .dy = -1}, .{.dx = -1, .dy = 1}}, // 2nd diagonal
    };
    for (rows) |directions| {
        var stoneCount: u8 = 1;
        gameState.winningRow[0] = @intCast(index);

        for (directions) |direction| {
            var dx: i8 = direction.dx;
            var dy: i8 = direction.dy;
            while (true) : ({dx += direction.dx; dy += direction.dy;}) {
                const x = lastMoveX + dx;
                const y = lastMoveY + dy;

                if (x < 0 or x > 2 or y < 0 or y > 2) break;
                if (board[getIndex(x, y, columnsInRow)] != lastMoveStone) break;

                stoneCount += 1;
                gameState.winningRow[stoneCount-1] = y * @as(i8, @intCast(columnsInRow)) + x;
            }
        }

        assert(stoneCount <= 3);
        if (stoneCount == 3) {
            //for(stoneIndices) |i| {
            //    print("{}\n", .{i});
            //}

            return true;
        }
    }
    return false;
}

fn getIndex(x: i8, y: i8, columnsInRow: i8) usize {
    return @intCast(y * columnsInRow + x);
}

//const Move = struct {
//    index: usize,
//    player: *Player
//};
//fn makeMove(gameState: *GameState, move: Move) ?GameResult {
fn makeMove(gameState: *GameState, index: usize) void {
    assert(gameState.board[index] == null);
    gameState.board[index] = gameState.playerToMove.stones;
    gameState.numEmptyCells -= 1;

    if (isWin(gameState.board[0..], index, gameState.numColumns, gameState)) {
        gameState.gameResult = GameResult.WIN;
        gameState.winner = gameState.playerToMove;
    } else if (gameState.numEmptyCells == 0) {
        gameState.gameResult = GameResult.DRAW;
    } else {
        gameState.playerToMove = if (gameState.playerToMove == &gameState.players[0]) &gameState.players[1] else &gameState.players[0];
    }
}
