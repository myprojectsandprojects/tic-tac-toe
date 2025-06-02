
// todo:
// - play sounds when game ends (win/loss, draw)
// - play sounds when a move is made / stone placed
// - consider different board type (place stones at the grid-line intersections, larger board)
// - can we get the # of type conversions down?
// - maybe we should highlight all winning rows (if more than one)?
// - highlight most recently placed stone?
// - if playing against computer it's not obvious at first if it's my move or computer's move.

// - finding computer move: we could calculate probabilities of outcomes only once, store them in a tree data structure (?) and then walk the tree as the game progresses. This data structure could even be stored on disk, so it wouldn't matter if it took 3 months to calculate the probabilities, because we would just walk the tree during the game (?) It could be a huge amount of data if the number of possibilities is large though (?)

// - numCols & numRows should go into a different data structure? board?

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

    isComputer: bool, //@ dont really need this anymore
    getNextMove: ?*const fn (*GameState) usize = null,
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
        .board = boardMemory,
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
        //.{.name="Batman", .stones=Stone.BLACK, .isComputer=false},
        //.{.name="Batman", .stones=Stone.BLACK, .isComputer=true, .getNextMove=getComputerMoveRandomly},
        .{.name="Supercomputer", .stones=Stone.BLACK, .isComputer=true, .getNextMove=getComputerMoveRecursively2},
        //.{.name="Supercomputer", .stones=Stone.BLACK, .isComputer=true, .getNextMove=getComputerMoveRecursively},
        //.{.name="Supercomputer2", .stones=Stone.WHITE, .isComputer=true, .getNextMove=getComputerMoveRecursively},
        //.{.name="outdated model", .stones=Stone.WHITE, .isComputer=true, .getNextMove=getComputerMoveRandomly},
        .{.name="Batman", .stones=Stone.WHITE, .isComputer=false},
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

                    //const moveIndex = getComputerMove(&gameState);
                    //const moveIndex = getComputerMoveOneMoveAhead(&gameState);
                    const moveIndex = gameState.playerToMove.getNextMove.?(&gameState);
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

    var result: ?GameResult = null;
    if (isWin(gameState.board[0..], moveIndex, @intCast(gameState.numCols), gameState)) {
        result = .{.winner = gameState.playerToMove};
    } else if (gameState.numEmptyCells == 0) {
        result = .{.winner = null};
    }

    gameState.playerToMove = if (gameState.playerToMove == gameState.players[0]) gameState.players[1] else gameState.players[0];

    return result;
}

fn unmakeMove(gameState: *GameState, moveIndex: usize) void {
    assert(gameState.board[moveIndex] != null);

    gameState.board[moveIndex] = null;
    gameState.numEmptyCells += 1;
    gameState.playerToMove = if (gameState.playerToMove == gameState.players[0]) gameState.players[1] else gameState.players[0];
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

fn getComputerMoveRandomly(gameState: *GameState) usize {
    print("getComputerMoveRandomly()\n", .{});

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

const MoveInfo = struct {
    win: f32,
    draw: f32,
    loss: f32,
};

const MoveAndInfo = struct {move: usize, moveInfo: MoveInfo};

// don't assume best play by either player, explore possibilities, calculate probabilities of outcomes
fn checkMoves2(gameState: *GameState, opponent: bool) MoveInfo {
    // simply assume game is not over

    var moveBucket = std.ArrayList(MoveInfo).init(allocator);
    defer moveBucket.deinit();

    const moves: std.ArrayList(usize) = getPossibleMoves(gameState); // for player to move next
    defer moves.deinit();

    for (moves.items) |move| {
        const result = makeMove(gameState, move);
        defer unmakeMove(gameState, move);

        if (result) |r| {
            if (r.winner) |_| {
                const moveInfo: MoveInfo = if(opponent) .{.win=0, .draw=0, .loss=1} else .{.win=1, .draw=0, .loss=0};
                moveBucket.append(moveInfo) catch |err| std.debug.panic("error: {}\n", .{err});
            } else {
                // draw -- the only move left on the board
                assert(moves.items.len == 1);

                const moveInfo: MoveInfo = .{.win=0, .draw=1, .loss=0};
                moveBucket.append(moveInfo) catch |err| std.debug.panic("error: {}\n", .{err});
            }
        } else {
            const moveInfo = checkMoves2(gameState, !opponent);
            moveBucket.append(moveInfo) catch |err| std.debug.panic("error: {}\n", .{err});
        }
    }

    var result: MoveInfo = .{.win=0, .draw=0, .loss=0};
    for (moveBucket.items) |move| {
        result.win += move.win;
        result.draw += move.draw;
        result.loss += move.loss;
    }

    const length = @as(f32, @floatFromInt(moveBucket.items.len));
    result.win /= length;
    result.draw /= length;
    result.loss /= length;

    return result;

}

// find the best move for whoever is to move next
fn getComputerMoveRecursively2(gameState: *GameState) usize {
    // simply assume game is not over

    var moveBucket = std.ArrayList(MoveAndInfo).init(allocator);
    defer moveBucket.deinit();

    const moves: std.ArrayList(usize) = getPossibleMoves(gameState); // for player to move next
    defer moves.deinit();

    for (moves.items) |move| {
        const result = makeMove(gameState, move);
        defer unmakeMove(gameState, move);

        if (result) |r| {
            if (r.winner) |_| {
                const moveAndInfo = MoveAndInfo{.move = move, .moveInfo = .{.win=1, .draw=0, .loss=0}};
                moveBucket.append(moveAndInfo) catch |err| std.debug.panic("error: {}\n", .{err});
            } else {
                // draw -- the only move left on the board
                assert(moves.items.len == 1);

                const moveAndInfo = MoveAndInfo{.move = move, .moveInfo = .{.win=0, .draw=1, .loss=0}};
                moveBucket.append(moveAndInfo) catch |err| std.debug.panic("error: {}\n", .{err});
            }
        } else {
            const moveInfo = checkMoves2(gameState, true);
            moveBucket.append(.{.move = move, .moveInfo = moveInfo}) catch |err| std.debug.panic("error: {}\n", .{err});
        }
    }

    std.mem.sort(
        MoveAndInfo,
        moveBucket.items,
        {},
        struct {
            fn lessThan(_: void, lhs: MoveAndInfo, rhs: MoveAndInfo) bool {return lhs.moveInfo.win > rhs.moveInfo.win;}
        }.lessThan
    );

    for (moveBucket.items) |move| {
        print("{}: w: {d}, d: {d}, l: {d}\n", .{move.move, move.moveInfo.win, move.moveInfo.draw, move.moveInfo.loss});
    }
    print("\n", .{});

    return moveBucket.items[0].move;
}

// assume best play by both players
fn checkMoves(gameState: *GameState, opponent: bool) MoveInfo {
    // simply assume game is not over

    //var bestMove: ?usize = null;
    var bestMoveInfo: ?MoveInfo = null;

    //var moveBucket = std.ArrayList(usize).init(allocator);
    //defer moveBucket.deinit();

    const moves: std.ArrayList(usize) = getPossibleMoves(gameState); // for player to move next
    defer moves.deinit();

    for (moves.items) |move| {
        const result = makeMove(gameState, move);
        defer unmakeMove(gameState, move);

        if (result) |r| {
            if (r.winner) |_| {
                //bestMove = move; // winning move
                bestMoveInfo = if(opponent) .{.win=0, .draw=0, .loss=1} else .{.win=1, .draw=0, .loss=0};
                break;
            } else {
                // draw -- the only move left on the board
                assert(moves.items.len == 1);
                //bestMove = move; 
                bestMoveInfo = .{.win=0, .draw=1, .loss=0};
                break;
            }
        } else {
            const moveInfo = checkMoves(gameState, !opponent);
            if (bestMoveInfo == null) {
                bestMoveInfo = moveInfo;
                //bestMove = move;
            } else {
                if (opponent) {
                    const newScore = moveInfo.win - moveInfo.loss;
                    const oldScore = bestMoveInfo.?.win - bestMoveInfo.?.loss;
                    if (newScore < oldScore) {
                        bestMoveInfo = moveInfo;
                        //bestMove = move;
                    }
                } else {
                    const newScore = moveInfo.win - moveInfo.loss;
                    const oldScore = bestMoveInfo.?.win - bestMoveInfo.?.loss;
                    if (newScore > oldScore) {
                        bestMoveInfo = moveInfo;
                        //bestMove = move;
                    }
                }
            }
        }
    }

    return bestMoveInfo.?;

}

// find the best move for whoever is to move next
fn getComputerMoveRecursively(gameState: *GameState) usize {
    // simply assume game is not over

    var bestMove: ?usize = null;
    var bestMoveInfo: ?MoveInfo = null;

    //var moveBucket = std.ArrayList(usize).init(allocator);
    //defer moveBucket.deinit();

    const moves: std.ArrayList(usize) = getPossibleMoves(gameState); // for player to move next
    defer moves.deinit();

    for (moves.items) |move| {
        const result = makeMove(gameState, move);
        defer unmakeMove(gameState, move);

        if (result) |r| {
            if (r.winner) |_| {
                bestMove = move; // winning move
                break;
            } else {
                // draw -- there are no other moves
                assert(moves.items.len == 1);
                bestMove = move; // the only move left on the board
            }
        } else {
            const moveInfo = checkMoves(gameState, true);
            if (bestMove == null) {
                bestMoveInfo = moveInfo;
                bestMove = move;
            } else {
                const newScore = moveInfo.win - moveInfo.loss;
                const oldScore = bestMoveInfo.?.win - bestMoveInfo.?.loss;
                if (newScore > oldScore) {
                    bestMoveInfo = moveInfo;
                    bestMove = move;
                }
            }
        }
    }

    return bestMove.?;
}

// find the best move for whoever is to move next
fn getComputerMoveOneMoveAhead(gameState: *GameState) usize {
    print("getComputerMoveOneMoveAhead()\n", .{});

    //// check the board (win/loss/draw)
    //const check: BoardCheck = checkBoard(gameState);
    //assert(check.gameResult == null); // we expect game to not be over

    // simply assume game is not over

    var moveToSuggest: ?usize = null;

    var moveBucket = std.ArrayList(usize).init(allocator);
    defer moveBucket.deinit();

    const moves: std.ArrayList(usize) = getPossibleMoves(gameState); // for player to move next
    defer moves.deinit();

    print("all possible moves: ", .{});
    for (moves.items) |move| {
        print("{}, ", .{move});
    }
    print("\n", .{});

    for (moves.items) |move| {
        const result = makeMove(gameState, move);
        defer unmakeMove(gameState, move);
        if (result) |r| {
            if (r.winner) |_| {
                moveToSuggest = move; // winning move
                print("winning move: {}\n", .{move});
                break;
            } else {
                // draw -- there are no other moves
                assert(moves.items.len == 1);
                moveToSuggest = move;
                print("drawing move: {}\n", .{move});
            }
        } else {
            moveBucket.append(move) catch |err| {
                std.debug.panic("error: {}\n", .{err});
            };
        }
    }

    print("move bucket: ", .{});
    for (moveBucket.items) |move| {
        print("{}, ", .{move});
    }
    print("\n", .{});

    // once done, if not obvious, select one randomly from the bucket
    if (moveToSuggest == null) {
        assert(moveBucket.items.len > 0);
        const randomIndex = getRandomNumber(moveBucket.items.len - 1);
        moveToSuggest = moveBucket.items[randomIndex];
    }

    return moveToSuggest.?;
}

fn getPossibleMoves(gameState: *GameState) std.ArrayList(usize) {
    var moves = std.ArrayList(usize).init(allocator);

    for (0..gameState.board.len) |i| {
        if (gameState.board[i] == null) {
            moves.append(i) catch |err| {
                std.debug.panic("error: {}\n", .{err});
            };
        }
    }
 
    return moves;
}

//// identify game result, if any (win/loss, draw, impossible-to-arrive-at-state)
//// return array of winning rows?
//// wait, do I even f need that?
//fn checkBoard(gameState: *GameState) void {
//    const numInARow: i32 = 3;
//    var blackInARows: i32 = 0;
//    var whiteInARows: i32 = 0;
//
//    // iterate over rows
//    for (0..@intCast(gameState.numRows)) |y| {
//        countInARows(gameState, &blackInARows, &whiteInARows, 0, @intCast(y), 1, 0, numInARow);
//    }
//
//    // iterate over columns
//    for (0..@intCast(gameState.numCols)) |x| {
//        countInARows(gameState, &blackInARows, &whiteInARows, @intCast(x), 0, 0, 1, numInARow);
//    }
//
//    {
//        // iterate over nw->se diagonals
//        var startX: i32 = -(gameState.numRows - 1);
//        while (startX < gameState.numCols) : (startX += 1) {
//            var x: i32 = startX;
//            var y: i32 = 0;
//
//            // ignore squares outside the board
//            while (x < 0) : ({x += 1; y += 1;}) {
//                //print("outside the board: x: {}, y: {}\n", .{x, y});
//            }
//
//            countInARows(gameState, &blackInARows, &whiteInARows, x, y, 1, 1, numInARow);
//        }
//    }
//
//    {
//        // iterate over ne->sw diagonals
//        var startX: i32 = 0;
//        while (startX < gameState.numCols + gameState.numRows - 1) : (startX += 1) {
//            var x: i32 = startX;
//            var y: i32 = 0;
//
//            // ignore squares outside the board
//            while (x >= gameState.numCols) : ({x -= 1; y += 1;}) {
//                //print("outside the board: x: {}, y: {}\n", .{x, y});
//            }
//
//            countInARows(gameState, &blackInARows, &whiteInARows, x, y, -1, 1, numInARow);
//        }
//    }
//
//    print("black in-a-rows: {}, white in-a-rows: {}\n", .{blackInARows, whiteInARows});
//}
//
//fn countInARows(gameState: *GameState, blackInARowsTotal: *i32, whiteInARowsTotal: *i32, startX: i32, startY: i32, dx: i32, dy: i32, numInARow: i32) void {
//    var blackInARows: i32 = 0;
//    var whiteInARows: i32 = 0;
//
//    var b: i32 = 0;
//    var w: i32 = 0;
//
//    var x = startX;
//    var y = startY;
//
//    while (x < gameState.numCols and y < gameState.numRows and x > -1 and y > -1) : ({x += dx; y += dy;}) {
//        const index: usize = @intCast(y * gameState.numCols + x);
//        if (gameState.board[index]) |stone| {
//            // stone
//            if (stone == .BLACK) {
//                w = 0;
//                b += 1;
//                if (b == numInARow) {
//                    blackInARows += 1;
//                    b = 0;
//                }
//            } else {
//                b = 0;
//                w += 1;
//                if (w == numInARow) {
//                    whiteInARows += 1;
//                    w = 0;
//                }
//            }
//        } else {
//            // empty cell
//            b = 0;
//            w = 0;
//        }
//    }
//
//    blackInARowsTotal.* += blackInARows;
//    whiteInARowsTotal.* += whiteInARows;
//}
