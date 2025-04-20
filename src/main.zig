const std = @import("std");
const rl = @import("raylib");

const Vector2 = rl.Vector2;

const screenWidth: f32 = 640.0;
const screenHeight: f32 = 480.0;
const cx: f32 = screenWidth / 2.0;
const cy: f32 = screenHeight / 2.0;

const dashLength: f32 = 12.0;
const gapLength: f32 = 10.0;
const lineThickness: f32 = 5.0;

const paddleWidth: f32 = 10.0;
const paddleHeight: f32 = 50.0;
const ballRadius: f32 = 10.0;
const ballSpeed: f32 = 5.0;
const paddleSpeed: f32 = 6.0;

const Player = struct {
    pos: Vector2,
    score: i32,
};

const State = struct {
    ballPos: Vector2,
    ballVelocity: Vector2,
    player1: Player,
    player2: Player,
    is_over: bool,
};

const CenterLine = struct {
    segment_start: Vector2,
    segment_end: Vector2,
};

var game_state: State = .{
    .ballPos = .{ .x = cx, .y = cy },
    .ballVelocity = .{ .x = -ballSpeed, .y = ballSpeed },
    .player1 = Player{ .pos = .{ .x = 10.0, .y = cy - paddleHeight / 2.0 }, .score = 0 },
    .player2 = Player{ .pos = .{ .x = screenWidth - 20.0, .y = cy - paddleHeight / 2.0 }, .score = 0 },
    .is_over = false,
};

var center_line: CenterLine = .{
    .segment_start = .{ .x = cx, .y = 0.0 },
    .segment_end = .{ .x = cx, .y = dashLength },
};

fn drawCenterline() void {
    center_line.segment_start = .{ .x = cx, .y = 0.0 };
    center_line.segment_end = .{ .x = cx, .y = dashLength };
    while (center_line.segment_start.y < screenHeight) {
        if (center_line.segment_end.y > screenHeight) {
            center_line.segment_end = .{ .x = cx, .y = screenHeight };
        }
        rl.drawLineEx(center_line.segment_start, center_line.segment_end, lineThickness, rl.Color.white);
        const move_amount = dashLength + gapLength;
        center_line.segment_start.y += move_amount;
        center_line.segment_end.y += move_amount;
    }
}

fn drawPlayer(player: Player) void {
    rl.drawRectangleV(player.pos, .{ .x = paddleWidth, .y = paddleHeight }, rl.Color.white);
}

fn drawScore() void {
    // Player 1 score (left side)
    const p1_score_text = std.fmt.allocPrintZ(std.heap.page_allocator, "{d}", .{game_state.player1.score}) catch unreachable;
    defer std.heap.page_allocator.free(p1_score_text);
    rl.drawText(p1_score_text, cx - 50, 20, 40, rl.Color.white);

    // Player 2 score (right side)
    const p2_score_text = std.fmt.allocPrintZ(std.heap.page_allocator, "{d}", .{game_state.player2.score}) catch unreachable;
    defer std.heap.page_allocator.free(p2_score_text);
    rl.drawText(p2_score_text, cx + 30, 20, 40, rl.Color.white);
}

fn resetBall() void {
    game_state.ballPos = .{ .x = cx, .y = cy };
    const rand = std.crypto.random;
    const dirX: f32 = if (rand.boolean()) ballSpeed else -ballSpeed;
    const dirY: f32 = if (rand.boolean()) ballSpeed else -ballSpeed;
    game_state.ballVelocity = .{ .x = dirX, .y = dirY };
}

fn updateGame() void {
    // Move the ball
    game_state.ballPos.x += game_state.ballVelocity.x;
    game_state.ballPos.y += game_state.ballVelocity.y;

    // Wall collisions (top and bottom)
    if (game_state.ballPos.y <= ballRadius or game_state.ballPos.y >= screenHeight - ballRadius) {
        game_state.ballVelocity.y = -game_state.ballVelocity.y;
    }

    // Paddle collision with player 1
    if (game_state.ballPos.x - ballRadius <= game_state.player1.pos.x + paddleWidth and
        game_state.ballPos.y >= game_state.player1.pos.y and
        game_state.ballPos.y <= game_state.player1.pos.y + paddleHeight and
        game_state.ballVelocity.x < 0)
    {
        game_state.ballVelocity.x = -game_state.ballVelocity.x;

        // Add some angle based on where the ball hit the paddle
        const relativeIntersectY = (game_state.player1.pos.y + paddleHeight / 2.0) - game_state.ballPos.y;
        const normalizedRelativeIntersectionY = relativeIntersectY / (paddleHeight / 2.0);
        const bounceAngle = normalizedRelativeIntersectionY * 0.8;

        game_state.ballVelocity.y = -bounceAngle * ballSpeed;
    }

    // Paddle collision with player 2
    if (game_state.ballPos.x + ballRadius >= game_state.player2.pos.x and
        game_state.ballPos.y >= game_state.player2.pos.y and
        game_state.ballPos.y <= game_state.player2.pos.y + paddleHeight and
        game_state.ballVelocity.x > 0)
    {
        game_state.ballVelocity.x = -game_state.ballVelocity.x;

        // Add some angle based on where the ball hit the paddle
        const relativeIntersectY = (game_state.player2.pos.y + paddleHeight / 2.0) - game_state.ballPos.y;
        const normalizedRelativeIntersectionY = relativeIntersectY / (paddleHeight / 2.0);
        const bounceAngle = normalizedRelativeIntersectionY * 0.8;

        game_state.ballVelocity.y = -bounceAngle * ballSpeed;
    }

    // Scoring
    if (game_state.ballPos.x < 0) {
        // Player 2 scores
        game_state.player2.score += 1;
        resetBall();
    } else if (game_state.ballPos.x > screenWidth) {
        // Player 1 scores
        game_state.player1.score += 1;
        resetBall();
    }

    // Player movement
    if (rl.isKeyDown(rl.KeyboardKey.w)) {
        game_state.player1.pos.y -= paddleSpeed;
    }
    if (rl.isKeyDown(rl.KeyboardKey.s)) {
        game_state.player1.pos.y += paddleSpeed;
    }

    if (rl.isKeyDown(rl.KeyboardKey.up)) {
        game_state.player2.pos.y -= paddleSpeed;
    }
    if (rl.isKeyDown(rl.KeyboardKey.down)) {
        game_state.player2.pos.y += paddleSpeed;
    }

    // Keep paddles in bounds
    if (game_state.player1.pos.y < 0) {
        game_state.player1.pos.y = 0;
    }
    if (game_state.player1.pos.y > screenHeight - paddleHeight) {
        game_state.player1.pos.y = screenHeight - paddleHeight;
    }

    if (game_state.player2.pos.y < 0) {
        game_state.player2.pos.y = 0;
    }
    if (game_state.player2.pos.y > screenHeight - paddleHeight) {
        game_state.player2.pos.y = screenHeight - paddleHeight;
    }
}

pub fn main() !void {
    rl.initWindow(screenWidth, screenHeight, "Pong");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    while (!rl.windowShouldClose()) {
        updateGame();
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.black);
        drawCenterline();
        rl.drawCircleV(game_state.ballPos, ballRadius, rl.Color.white);
        drawPlayer(game_state.player1);
        drawPlayer(game_state.player2);
        drawScore();
    }
}
