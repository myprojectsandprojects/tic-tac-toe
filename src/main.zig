
// todo:
// - play sounds when game ends (win/loss, draw)
// - play sounds when a move is made / stone placed
// - consider different board type (place stones at the grid-line intersections, larger board)
// - can we get the # of type conversions down?
// - maybe we should highlight all winning rows (if more than one)?

//@ mouse coordinates are off when the mouse hasn't moved yet...

const std = @import("std");
const ray = @cImport(@cInclude("raylib.h"));

const print = std.debug.print;
const assert = std.debug.assert;
const allocator = std.heap.page_allocator;

const Stone = enum {
    BLACK,
    WHITE,
};

const GameResult = struct {
    winner: ?*const Player //'null' if draw
};

const Player = struct {
    name: []const u8,
    stones: Stone,
    isComputer: bool,
};

const GameState = struct {
    board: []?Stone,
    players: [2] *const Player,
    playerToMove: *const Player = undefined,

    numEmptyCells: i32 = undefined,

    //?
    winningRow: [3]i8 = undefined,

    //@ board size should depend on these:
    numCols: i32,
    numRows: i32,
};

fn makeGameState(numRows: i32, numCols: i32, player1: *const Player, player2: *const Player) !GameState {
    const boardMemory = try allocator.alloc(?Stone, @intCast(numRows * numCols));
    for (boardMemory) |*cell| {
        cell.* = null;
    }

    var gameState: GameState = .{
        .board = boardMemory ,
        .numRows = numRows,
        .numCols = numCols,
        .players = .{player1, player2},
    };
    gameState.numEmptyCells = @intCast(gameState.board.len);
    gameState.playerToMove = gameState.players[0];

    return gameState;
}

//fn stoneToString(stone: Stone) []const u8 {
//    const stoneNames = [2][]const u8{"BLACK", "WHITE"};
//    return stoneNames[@intFromEnum(stone)];
//}

fn getRandomNumber(max: usize) usize {
    // Seed with current time or other entropy
    var prng = std.Random.Xoshiro256.init(@intCast(std.time.milliTimestamp()));

    // Get the Random interface
    const rand = prng.random();

    // Generate a random u8 between 0 and 255
    const r = rand.int(usize);

    return r % (max + 1);
}

pub fn main() !void {
    const windowWidth = 801;
    const windowHeight = 601;
    ray.InitWindow(windowWidth, windowHeight, "Tic Tac Toe");
    defer ray.CloseWindow();

    //ray.SetTargetFPS(1);
    ray.SetTargetFPS(60);

    var gameResult: ?GameResult = null; //'null' if game is on

    const players: [2]Player = .{
        .{.name="Batman", .stones=Stone.BLACK, .isComputer=false},
        .{.name="Supercomputer", .stones=Stone.WHITE, .isComputer=true}
    };

    const numRows = 3;
    const numCols = 3;
    var gameState = try makeGameState(numRows, numCols, &players[0], &players[1]);

    const boardColor = ray.DARKBROWN;
    const boardWidth: f32 = 300;
    const boardHeight: f32 = 300;
    const boardX: f32 = @as(f32, @floatFromInt(windowWidth)) / 2 - boardWidth / 2;
    const boardY: f32 = @as(f32, @floatFromInt(windowHeight)) / 2 - boardHeight / 2;

    const cellWidth: f32 = boardWidth / numCols;
    const cellHeight: f32 = boardHeight / numRows;

    //const allocator = std.heap.page_allocator;
    //var gameMessage: []const u8 = try std.fmt.allocPrint(allocator, "{s}'s move...", .{stoneToString(turn)});

    const LEFT_MOUSE = 0;
    //const RIGHT_BUTTON = 1;
    var wasDown: bool = ray.IsMouseButtonDown(LEFT_MOUSE);

    // computer move wait time
    var waitMode = false;
    var waitedNumFrames: usize = undefined;

    // move animation
    var playAnimation = false;
    var angle: f32 = 0;
    //var angle: f32 = std.math.pi / 2.0;

    // winning row animation
    var winningRowAnimation = false;
    const radiusFactorMin: f32 = 1.0;
    const radiusFactorMax: f32 = 1.1;
    const radiusFactorIncrement = (radiusFactorMax - radiusFactorMin) / 16;
    var radiusFactor: f32 = radiusFactorMin;

    while (!ray.WindowShouldClose()) {
        const isDown = ray.IsMouseButtonDown(LEFT_MOUSE);
        const mouseWentDown = isDown and !wasDown;
        wasDown = isDown;

        if (gameResult == null and gameState.playerToMove.isComputer) {
            if (!waitMode) {
                waitMode = true;
                waitedNumFrames = 1;
            } else {
                if (waitedNumFrames == 1 * 60) {
                    waitMode = false;

                    const moveIndex = getComputerMove(&gameState);
                    gameResult = makeMove(&gameState, moveIndex);
                    if (gameResult) |result| {
                        if (result.winner) |winner| {
                            print("{s} wins!\n", .{winner.name});

                            winningRowAnimation = true;
                        } else {
                            print("A draw!\n", .{});
                        }
                    } else {
                        playAnimation = true;
                    }
                } else {
                    print("waiting...\n", .{});
                    waitedNumFrames += 1;
                }
            }
        }

        if (gameResult == null and !gameState.playerToMove.isComputer) {
            if (mouseWentDown) {
                const mouseX: f32 = @floatFromInt(ray.GetMouseX());
                const mouseY: f32 = @floatFromInt(ray.GetMouseY());

                const x: i32 = @intFromFloat(@floor((mouseX - boardX) / cellWidth));
                const y: i32 = @intFromFloat(@floor((mouseY - boardY) / cellHeight));

                if (x > -1 and x < gameState.numCols and y > -1 and y < gameState.numRows) {
                    const moveIndex: usize = @intCast(y * gameState.numCols + x);

                    if (gameState.board[moveIndex] == null) {
                        gameResult = makeMove(&gameState, moveIndex);
                        if (gameResult) |result| {
                            if (result.winner) |winner| {
                                print("{s} wins!\n", .{winner.name});

                                winningRowAnimation = true;
                            } else {
                                print("A draw!\n", .{});
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
        for (1..@intCast(gameState.numCols)) |i| {
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
            if (gameResult != null and gameResult.?.winner != null) {
                for(gameState.winningRow) |wi| {
                    if(wi == i) {
                        isWinningStone = true;
                        break;
                    }
                }
            }

            //const x = i % gameState.numColumns;
            const x: f32 = @floatFromInt(@as(u8, @intCast(i)) % @as(u8, @intCast(gameState.numCols)));
            const y: f32 = @floatFromInt(@as(u8, @intCast(i)) / @as(u8, @intCast(gameState.numCols)));
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

        if (gameResult == null) {
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

        if (winningRowAnimation) {
            radiusFactor += radiusFactorIncrement;
            if(radiusFactor > radiusFactorMax) radiusFactor = radiusFactorMax;
            if(radiusFactor == radiusFactorMax) winningRowAnimation = false;
        }
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
                if (board[@intCast(y * columnsInRow + x)] != lastMoveStone) break;

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

//fn getIndex(x: i8, y: i8, columnsInRow: i8) usize {
//    return @intCast(y * columnsInRow + x);
//}

//const Move = struct {
//    index: usize,
//    player: *Player
//};
//fn makeMove(gameState: *GameState, move: Move) ?GameResult {
fn makeMove(gameState: *GameState, moveIndex: usize) ?GameResult {
    assert(gameState.board[moveIndex] == null);

    const moveStone = gameState.playerToMove.stones;
    gameState.board[moveIndex] = moveStone;

    gameState.numEmptyCells -= 1;

    if (isWin(gameState.board[0..], moveIndex, @intCast(gameState.numCols), gameState)) {
        return .{.winner = gameState.playerToMove};
    } else if (gameState.numEmptyCells == 0) {
        return .{.winner = null};
    } else {
        gameState.playerToMove = if (gameState.playerToMove == gameState.players[0]) gameState.players[1] else gameState.players[0];
        return null;
    }
}

//fn getPlayerToMove(gameState: *GameState, players: []const Player) Player {
//    const stones = gameState.playerToMove;
//    for (players) |player| {
//        if (player.stones == stones) {
//            return player;
//        }
//    }
//    unreachable;
//}

fn getComputerMove(gameState: *GameState) usize {
    // generate a random integer in range 0 ... numEmptyCells-1
    assert(gameState.numEmptyCells > 0);
    const randomIndex = getRandomNumber(@intCast(gameState.numEmptyCells-1));
    assert(randomIndex > -1 and randomIndex < gameState.numEmptyCells);

    var emptyCellIndex: usize = 0;
    for (gameState.board, 0..) |cell, index| {
        if (cell == null) {
            if (emptyCellIndex == randomIndex) {
                return index;
            } else {
                emptyCellIndex += 1;
            }
        }
    }
    unreachable;
}
