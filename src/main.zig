const sdl = @import("sdl.zig");
const std = @import("std");

const SpriteState = enum { @"continue", delete };

const GameState = enum { init, home, pause, @"continue", over, win };

// zig fmt: off

var window:         ?*sdl.Window = null;
var renderer:       ?*sdl.Renderer = null;
var window_width:   c_int = 0;
var window_height:  c_int = 0;
var game_state:     GameState = .init;
var enemy_interval: c_int = 0;
var score:          c_int = 0;

const Sprite = struct {
    hp:     c_int = 1,
    atk:    c_int = 1,
    v:      f64 = 0,
    vx:     f64 = 0,
    vy:     f64 = 0,
    team:   c_int = 0,
    color:  sdl.Color = .{.r = 0, .g = 0, .b = 0, .a = 0},
    rect:   sdl.FRect = .{.x=0, .y=0, .w=0, .h=0},

    pub fn draw(self: *const @This()) SpriteState {
        _ = sdl.setRenderDrawColor(renderer, self.color.r, self.color.g, self.color.b, self.color.a);
        _ = sdl.renderFillRect(renderer, &self.rect);
        return SpriteState.@"continue";
    }

    pub fn update(self: *@This()) SpriteState {
        if (self.hp <= 0) {return SpriteState.delete;}

        const magnitute = sdl.sqrt(self.vy * self.vy + self.vx * self.vx);
        if (magnitute > 0) {
            self.rect.x += @floatCast(self.v * self.vx / magnitute);
            self.rect.y += @floatCast(self.v * self.vy / magnitute);
        }
        
        return SpriteState.@"continue";
    }
    
};

/// Bullet contains Sprite
const Bullet = struct {
    sprite: Sprite = .{
        .rect = .{.x=0, .y=0, .w=6.18, .h=10},
        .color = .{.r = 200, .g=200, .b=200, .a = 255},
        .v = 10,
    },

    pub fn update(self: *@This()) SpriteState {
        if (self.sprite.update() == SpriteState.@"continue") {
            if (
                self.sprite.rect.x > @as(f32, @floatFromInt(window_width)) 
                or self.sprite.rect.x + self.sprite.rect.w < 0 
                or self.sprite.rect.y + self.sprite.rect.h < 0
                or self.sprite.rect.y > @as(f32, @floatFromInt(window_height)) 
            ) { return SpriteState.delete;}
        } else return SpriteState.delete;
        return SpriteState.@"continue";
    }
    pub fn draw(self: *const @This()) SpriteState {
        return self.sprite.draw();
    }
};

/// Ship contains Sprite
const Ship = struct {
    

    bullets: std.ArrayList(Bullet),

    sprite: Sprite = .{
        .rect = .{.x=0, .y=0, .w=30.9, .h=50},
        .color = .{.r = 100, .g = 100, .b = 100, .a = 255},
        .v = 5,
        .hp = 5,
    },

    pub fn init() Ship{
        return Ship{
            .bullets =std.ArrayList(Bullet).init(std.heap.c_allocator),
        };
    }
    pub fn deinit(self: *@This()) void {
        self.bullets.deinit();
    }

    pub fn draw(self: *const @This()) SpriteState {
        return self.sprite.draw();
    }
    pub fn update(self: *@This()) SpriteState {
        return self.sprite.update();
    }
    
    pub fn fire(self: *@This()) void {
        self.bullets.append(Bullet{}) catch unreachable;
        const bullet = &self.bullets.items[self.bullets.items.len-1];
        bullet.sprite.atk = 1;
        bullet.sprite.v = 2 * self.sprite.v;
        bullet.sprite.vx = self.sprite.vx;
        bullet.sprite.vy = self.sprite.vy - 2 * self.sprite.v;
        bullet.sprite.rect.x = self.sprite.rect.x + self.sprite.rect.w / 2 - bullet.sprite.rect.w / 2;
        bullet.sprite.rect.y = self.sprite.rect.y + self.sprite.rect.h / 2 - bullet.sprite.rect.h / 2;
    }
};


/// Player contains Ship
const Player = struct {
    ship: Ship,

    pub fn init() Player {
        var _player =  Player{.ship = Ship.init(),};
        const sprite = &_player.ship.sprite;
        sprite.color = .{.r = 255, .g = 255, .b = 255, .a = 255};
        sprite.rect.x = @as(f32, @floatFromInt(window_width)) / 2 - @as(f32, @floatCast(sprite.rect.w)) / 2;
        sprite.rect.y = @as(f32, @floatFromInt(window_height)) * 0.75 - @as(f32, @floatCast(sprite.rect.h)) / 2;
        return _player;
    }
    pub fn deinit(self: *@This()) void {
        self.ship.deinit();
    }
    pub fn fire(self: *@This()) void {
        const bullets = &self.ship.bullets;
        const b = sdl.sqrt(@as(f64,@floatFromInt(@divTrunc(score, 200))));
        var i = -b;
        while(i <= b):(i+=1) {
            self.ship.fire();
            const end = bullets.items.len - 1;
            bullets.items[end].sprite.rect.x += @floatCast(i * 10);
            bullets.items[end].sprite.color.r = @intCast(sdl.rand(255));
            bullets.items[end].sprite.color.g = @intCast(sdl.rand(255));
            bullets.items[end].sprite.color.b = @intCast(sdl.rand(255));
            
        }
        return;
    }

    pub fn draw(self: *const @This()) SpriteState {
        return self.ship.draw();
    }
    
    pub fn update(self: *@This()) SpriteState {
        const rect = &self.ship.sprite.rect;
        if (self.ship.update() == SpriteState.@"continue") {
            if (rect.x > @as(f32, @floatFromInt(window_width))) {
                rect.x = @floatFromInt(window_width);
            } else  if (rect.x + rect.w < 0) {
                rect.x = -rect.w;
            }
            if (rect.y > @as(f32, @floatFromInt(window_height))) {
                rect.y =  @as(f32, @floatFromInt(window_height));
            } else if (rect.y + rect.h < 0) {
                rect.y = - rect.h;
            }
        } else {
            self.ship.sprite.color = .{.r=255, .g=0, .b=0, .a=255};
            game_state = GameState.over;
            return SpriteState.delete;
        }
        return SpriteState.@"continue";
    }
};

/// Enemy contains ship
const Enemy = struct {
    ship: Ship,

    pub fn init() Enemy {
        var enemy =  Enemy{
            .ship=Ship.init(),
        };
        const sp = &enemy.ship.sprite;

        sp.rect.x = @floatFromInt(sdl.rand(window_width - @as(c_int, @intFromFloat(sp.rect.w))));
        sp.rect.y = -sp.rect.h;
        sp.v = 5;
        sp.vy = sp.v;
        sp.team = 1;

        return enemy;
    }
    pub fn deinit(self: *@This()) void {
        return self.ship.deinit();
    }
    pub fn draw(self: *const @This()) SpriteState {
        return self.ship.draw();
    }
    pub fn fire(self: *@This()) void {
        return self.ship.fire();
    }
    pub fn update(self: *@This()) SpriteState {
        if (sdl.rand(100) < @divTrunc(3000, enemy_interval)) {
            self.fire();
            const bullets = &self.ship.bullets;
            const end = bullets.items.len - 1;
            bullets.items[end].sprite.vy = 2 * self.ship.sprite.v;
            bullets.items[end].sprite.vx = @as(f64, @floatFromInt(sdl.rand(@intFromFloat(self.ship.sprite.v)))) / @as(f64,2.0) - self.ship.sprite.v / @as(f64, 4.0);
        }
        if (sdl.rand(100) <  @divTrunc(3000, enemy_interval)) {
            self.ship.sprite.vx = @as(f64, @floatFromInt(sdl.rand(@intFromFloat(self.ship.sprite.v)))) / @as(f64, 2.0) - self.ship.sprite.v / 4;
        }

        for (player.ship.bullets.items) |*bullet| {
            if(sdl.hasRectIntersectionFloat(&self.ship.sprite.rect, &bullet.sprite.rect)) {
                self.ship.sprite.hp -= bullet.sprite.atk;
                bullet.sprite.hp -= self.ship.sprite.atk;
                score += 1;
            }
        }

        for (self.ship.bullets.items) |*bullet| {
            if (sdl.hasRectIntersectionFloat(&player.ship.sprite.rect, &bullet.sprite.rect)) {
                player.ship.sprite.hp -= bullet.sprite.atk;
                bullet.sprite.hp -= player.ship.sprite.atk;
            }
        }

        if (sdl.hasRectIntersectionFloat(&self.ship.sprite.rect, &player.ship.sprite.rect)) {
            player.ship.sprite.hp -= self.ship.sprite.atk;
            self.ship.sprite.hp -= player.ship.sprite.atk;
        }

        if (self.ship.update() == SpriteState.@"continue") {
            if (self.ship.sprite.rect.y > @as(f32, @floatFromInt(window_height))) {
                return SpriteState.delete;
            }
        } else {
            score += 100;
            return SpriteState.delete;
        }
        return SpriteState.@"continue";
    }
};


fn addEnemy(userdata: ?*anyopaque, timerID: sdl.TimerID, interval: u32) callconv(.c) u32 {
    _ = userdata;
    if (game_state == GameState.@"continue") {
        
        enemys.append(Enemy.init()) catch unreachable;
        if (enemy_interval > 400) {
            enemy_interval -= 100;
            return @intCast(sdl.rand(enemy_interval) + 1);
        } else {
            return @intCast(sdl.rand(400) + 1);
        }
    } else if (game_state == GameState.over) {
        _ = sdl.removeTimer(timerID);
        return 0;
    }
    return interval;
}

var enemys: std.ArrayList(Enemy) = undefined;
var player: Player = undefined;

export fn  appInit(appstate: [*c]?*anyopaque, argc: c_int, argv: [*c][*c]u8) sdl.AppResult {
    _ = appstate;
    _ = argc;
    _ = argv;
    player = Player.init();
    enemys = std.ArrayList(Enemy).init(std.heap.c_allocator);

    if (!sdl.createWindowAndRenderer("Sternenstaub", 1500, 1000,0, &window,&renderer)) {
        sdl.logError(@intFromEnum(sdl.LogCategory.video), "Video error: %s", sdl.getError());
    }
    _ = sdl.getWindowSizeInPixels(window, &window_width, &window_height);
    
    game_state = GameState.home;
    return sdl.AppResult.@"continue";
}

export fn appEvent(appstate: ?*anyopaque, event: [*c]sdl.Event) sdl.AppResult {
    _ = appstate;
    if (event.*.type == @intFromEnum(sdl.EventType.quit)) return sdl.AppResult.success;

    switch (game_state) {
        GameState.home => {
            switch (event.*.type) {
                @intFromEnum(sdl.EventType.key_down) => {
                    switch(event.*.key.key) {
                        @intFromEnum(sdl.KeyCode.q) => return sdl.AppResult.success,
                        else => {
                            score = 0;
                            player = Player.init();
                            enemys.clearRetainingCapacity();
                            enemy_interval = 3000;
                            game_state = GameState.@"continue";
                            sdl.srand(sdl.getTicks());
                            _ = sdl.addTimer(1000, addEnemy, null);
                        }
                    }
                },
                else=> {},
            }
        },
        GameState.@"continue" => {
            switch (event.*.type) {
                @intFromEnum(sdl.EventType.key_down) => {
                    switch (event.*.key.key) {
                        @intFromEnum(sdl.KeyCode.escape) => {
                            game_state = GameState.pause;
                            return sdl.AppResult.@"continue";
                        },
                        else => {},
                    }
                },
                @intFromEnum(sdl.EventType.key_up) => {
                    switch (event.*.key.key) {
                        @intFromEnum(sdl.KeyCode.space) => {
                            player.fire();
                        },
                        else => {},
                    }
                },
                else => {},
            }
        },
        GameState.pause => {
            switch (event.*.type) {
                @intFromEnum(sdl.EventType.key_down) => {
                    switch (event.*.key.key) {
                        @intFromEnum(sdl.KeyCode.escape) => {
                            game_state = GameState.@"continue";
                            return sdl.AppResult.@"continue";
                        },
                        @intFromEnum(sdl.KeyCode.q) => return sdl.AppResult.success,
                        else => {},
                    }
                },
                else => {},
            }
        },
        GameState.over => {
            switch (event.*.type) {
                @intFromEnum(sdl.EventType.key_down) => {
                    switch (event.*.key.key) {
                        @intFromEnum(sdl.KeyCode.escape) => {
                            game_state = GameState.home;
                            return sdl.AppResult.@"continue";
                        },
                        else => {},
                    }
                },
                else => {},
            }
        },
        else => {},
    }
    
    return sdl.AppResult.@"continue";
}

export fn appIterate(appstate: ?*anyopaque) sdl.AppResult {
    _ = appstate;
    switch (game_state) {
        GameState.home => {
            _ = sdl.setRenderDrawColor(renderer, 0, 0, 0, 255);
            _ = sdl.renderClear(renderer);
            _ = sdl.setRenderDrawColor(renderer, 255, 255, 255, 255);
            _ = sdl.renderDebugTextFormat(renderer, @as(f32, @floatFromInt(window_width)) / 2.0 - 100.0, @as(f32, @floatFromInt(window_height)) / 2.0 - 60, "-- Sternenstaub --");
            _ = sdl.renderDebugTextFormat(renderer, @as(f32, @floatFromInt(window_width)) / 2.0 - 100.0, @as(f32, @floatFromInt(window_height)) / 2.0  - 20, "Press any key to  START");
            _ = sdl.renderDebugTextFormat(renderer, @as(f32, @floatFromInt(window_width)) / 2.0 - 100.0, @as(f32, @floatFromInt(window_height)) / 2.0  + 10, "Press [Q] to      QTUI");
            _ = sdl.renderDebugTextFormat(renderer, @as(f32, @floatFromInt(window_width)) / 2.0 - 100.0, @as(f32, @floatFromInt(window_height)) / 2.0  + 50, "Press [ESDF] to   MOVE");
            _ = sdl.renderDebugTextFormat(renderer, @as(f32, @floatFromInt(window_width)) / 2.0 - 100.0, @as(f32, @floatFromInt(window_height)) / 2.0  + 80, "Press [Space] to  FIRE");
            _ = sdl.renderPresent(renderer);
        },
        GameState.@"continue" => {
            const keystate = sdl.getKeyboardState(null);

            player.ship.sprite.vx = 0;
            player.ship.sprite.vy = 0;
            const sp = &player.ship.sprite;
            
            if (keystate[@intFromEnum(sdl.Scancode.s)]) sp.vx += -1;
            if (keystate[@intFromEnum(sdl.Scancode.f)]) sp.vx += 1;
            if (keystate[@intFromEnum(sdl.Scancode.e)]) sp.vy += -1;
            if (keystate[@intFromEnum(sdl.Scancode.d)]) sp.vy += 1;

            _ = sdl.setRenderDrawColor(renderer, 0, 0, 0, 0);
            _ = sdl.renderClear(renderer);

            _ = player.update();
            _ = player.draw();

            const _bullets = &player.ship.bullets;
            var i: usize = undefined;
            i = 1;
            while (i < _bullets.items.len) {
                if(_bullets.items[i].update() == SpriteState.delete) {
                    _ = _bullets.swapRemove(i);
                } else {
                    _ = _bullets.items[i].draw();
                    i += 1;
                }
            }

            i = 0;
            var j: usize = undefined;
            j = 0;
    
            while (i < enemys.items.len) {
                const enemy = &enemys.items[i];
                if (enemy.update() == SpriteState.delete) {
                    var e = enemys.swapRemove(i);
                    e.deinit();
                } else {
                    const blts = &enemy.ship.bullets;
                    j = 0;
                    while (j < blts.items.len) {
                        if (blts.items[j].update() == SpriteState.delete) {
                            _ = blts.swapRemove(j);
                        } else {
                            _  = blts.items[j].draw();
                            j += 1;
                        }
                    }
                    _ = enemy.draw();
                    i += 1;
                }
            }

            // for (enemys.items, 0..) |*it, i| {
            //     sw: switch(it.update()) {
            //         SpriteState.delete => {
            //             var e = enemys.swapRemove(i);
            //             e.deinit();
            //             continue :sw it.update();
            //         },
            //         else => {
            //             const bts = &it.ship.bullets;
            //             for (bts.items, 0..) |*it2, j| {
            //                 _ = sw2: switch (it2.update()) {
            //                     SpriteState.delete => {
            //                         _ = bts.swapRemove(j);
            //                         continue :sw2 it2.update();
            //                     },
            //                     else => it2.draw(),
            //                 };
            //             }
            //            _ = it.draw();
            //         }
            //     }
            // }
            _ = sdl.setRenderDrawColor(renderer, 255, 255, 255, 255);
            _ = sdl.renderDebugTextFormat(renderer, 10, 10, "score: %d", score);
            _ = sdl.renderDebugTextFormat(renderer, 10, 30, "HP: %d", player.ship.sprite.hp);
            _ = sdl.renderPresent(renderer);
        },
        GameState.pause => {
            _ = sdl.setRenderDrawColor(renderer, 0, 0, 0, 255);
            _ = sdl.renderClear(renderer);
            _ = sdl.setRenderDrawColor(renderer, 255, 255, 255, 255);
            
            _ = sdl.renderDebugTextFormat(renderer, @as(f32, @floatFromInt(window_width)) / 2.0 - 100.0, @as(f32, @floatFromInt(window_height)) / 2  - 50, "Game Paused");
            _ = sdl.renderDebugTextFormat(renderer, @as(f32, @floatFromInt(window_width)) / 2.0 - 100.0, @as(f32, @floatFromInt(window_height)) / 2  - 20, "Press [Esc] to continue");
            _ = sdl.renderDebugTextFormat(renderer, @as(f32, @floatFromInt(window_width)) / 2.0 - 100.0, @as(f32, @floatFromInt(window_height)) / 2  + 10, "Press [Q] to quit");
            _ = sdl.renderPresent(renderer);
        },
        GameState.over => {
            _ = sdl.setRenderDrawColor(renderer, 0, 0, 0, 255);
            _ = sdl.renderClear(renderer);
            _ = player.draw();
            _ = sdl.setRenderDrawColor(renderer, 255, 255, 255, 255);
            _ = sdl.renderDebugTextFormat(renderer, @as(f32, @floatFromInt(window_width)) / 2.0 - 100.0, @as(f32, @floatFromInt(window_height)) / 2  - 50, "Game over");
            _ = sdl.renderDebugTextFormat(renderer, @as(f32, @floatFromInt(window_width)) / 2.0 - 100.0, @as(f32, @floatFromInt(window_height)) / 2  - 20, "Your Score: %d", score);
            _ = sdl.renderDebugTextFormat(renderer, @as(f32, @floatFromInt(window_width)) / 2.0 - 100.0, @as(f32, @floatFromInt(window_height)) / 2  + 10, "Press [Esc] to home");
            _ = sdl.renderPresent(renderer);
        },
        else => {sdl.log("i don't know\n");},
    }
    sdl.delay(1000/60);
    return sdl.AppResult.@"continue";
}

export fn appQuit(appstate: ?*anyopaque, result: sdl.AppResult) void {
    _ = appstate;
    _ = result;
}


// zig fmt: on
