pub const c = @cImport({
    @cDefine("SDL_DISABLE_OLD_NAMES", {});
    @cDefine("SDL_MAIN_USE_CALLBACKS", {});
    @cInclude("SDL3/SDL.h");
    @cInclude("SDL3/SDL_main.h");
    @cInclude("SDL3/SDL_test.h");
});

pub const Window = c.SDL_Window;
pub const Renderer = c.SDL_Renderer;

pub const FRect = c.SDL_FRect;
pub const Color = c.SDL_Color;

pub const setRenderDrawColor = c.SDL_SetRenderDrawColor;
pub const renderClear = c.SDL_RenderClear;
pub const renderDebugTextFormat = c.SDL_RenderDebugTextFormat;
pub const renderPresent = c.SDL_RenderPresent;
pub const renderFillRect = c.SDL_RenderFillRect;

pub const getKeyboardState = c.SDL_GetKeyboardState;

pub const sqrt = c.SDL_sqrt;
pub const rand = c.SDL_rand;
pub const srand = c.SDL_srand;
pub const getTicks = c.SDL_GetTicks;
pub const addTimer = c.SDL_AddTimer;
const Uint32 = c.Uint32;

pub const TimerID = c.SDL_TimerID;
pub const removeTimer = c.SDL_RemoveTimer;

pub const AppResult = enum(c.SDL_AppResult) {
    @"continue" = c.SDL_APP_CONTINUE,
    success = c.SDL_APP_SUCCESS,
    failure = c.SDL_APP_FAILURE,
};

pub const createWindowAndRenderer = c.SDL_CreateWindowAndRenderer;

pub const WindowFlags = enum(c.SDL_WindowFlags) {
    full_screen = c.SDL_WINDOW_FULLSCREEN,
};

pub const LogCategory = enum(c.SDL_LogCategory) {
    video = c.SDL_LOG_CATEGORY_VIDEO,
};

pub const log = c.SDL_Log;
pub const logError = c.SDL_LogError;

pub const getWindowSizeInPixels = c.SDL_GetWindowSizeInPixels;
pub const getError = c.SDL_GetError;

pub const delay = c.SDL_Delay;
pub const hasRectIntersectionFloat = c.SDL_HasRectIntersectionFloat;
//  c.SDL_AppInit(appstate: [*c]?*anyopaque, argc: c_int, argv: [*c][*c]u8)AppResult
// c.SDL_AppEvent(appstate: ?*anyopaque, event: [*c]SDL_Event) c.SDL_AppResult;
// c.SDL_AppIterate(appstate: ?*anyopaque)AppResult;
// c.SDL_AppQuit(appstate: ?*anyopaque, result: SDL_AppResult) AppResult

pub const Event = c.SDL_Event;
pub const EventType = enum(c.SDL_EventType) {
    quit = c.SDL_EVENT_QUIT,
    key_down = c.SDL_EVENT_KEY_DOWN,
    key_up = c.SDL_EVENT_KEY_UP,
};

pub const Scancode = enum(c.SDL_Scancode) {
    q = c.SDL_SCANCODE_Q,
    a = c.SDL_SCANCODE_A,
    s = c.SDL_SCANCODE_S,
    d = c.SDL_SCANCODE_D,
    f = c.SDL_SCANCODE_F,
    e = c.SDL_SCANCODE_E,
};

pub const KeyCode = enum(c.SDL_Keycode) {
    escape = c.SDLK_ESCAPE,
    space = c.SDLK_SPACE,
    q = c.SDLK_Q,
};

extern fn appInit(appstate: [*c]?*anyopaque, argc: c_int, argv: [*c][*c]u8) AppResult;
export fn SDL_AppInit(appstate: [*c]?*anyopaque, argc: c_int, argv: [*c][*c]u8) c.SDL_AppResult {
    return @intFromEnum(appInit(appstate, argc, argv));
}

extern fn appEvent(appstate: ?*anyopaque, event: [*c]Event) AppResult;
export fn SDL_AppEvent(appstate: ?*anyopaque, event: [*c]c.SDL_Event) c.SDL_AppResult {
    return @intFromEnum(appEvent(appstate, event));
}

extern fn appIterate(appstate: ?*anyopaque) AppResult;
export fn SDL_AppIterate(appstate: ?*anyopaque) c.SDL_AppResult {
    return @intFromEnum(appIterate(appstate));
}

extern fn appQuit(appstate: ?*anyopaque, result: c.SDL_AppResult) void;
export fn SDL_AppQuit(appstate: ?*anyopaque, result: c.SDL_AppResult) void {
    appQuit(appstate, result);
}
