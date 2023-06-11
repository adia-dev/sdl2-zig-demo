const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_ttf.h");
});

const std = @import("std");
const assert = @import("std").debug.assert;

pub fn lerp(a: f32, b: f32, t: f32) f32 {
    return a + (b - a) * t;
}

pub fn main() !void {
    // Initialize SDL and SDL_ttf
    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    }
    defer c.SDL_Quit();

    if (c.TTF_Init() != 0) {
        c.SDL_Log("Unable to initialize SDL_ttf: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    }
    defer c.TTF_Quit();

    // Create the game window where the magic will happen
    // | c.SDL_WINDOW_ALLOW_HIGHDPI you can play around with this on a mac
    const screen = c.SDL_CreateWindow("ZigSDL2", c.SDL_WINDOWPOS_UNDEFINED, c.SDL_WINDOWPOS_UNDEFINED, 720, 480, c.SDL_WINDOW_OPENGL | c.SDL_RENDERER_PRESENTVSYNC) orelse {
        c.SDL_Log("Unable to create window: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer c.SDL_DestroyWindow(screen);

    // Create the renderer to draw our glorious creations
    const renderer = c.SDL_CreateRenderer(screen, -1, 0) orelse {
        c.SDL_Log("Unable to create renderer: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer c.SDL_DestroyRenderer(renderer);

    // Load the Roboto-Regular font
    const font = c.TTF_OpenFont("src/Roboto/Roboto-Regular.ttf", 24);
    if (font == null) {
        c.SDL_Log("Unable to load font: %s", c.TTF_GetError());
        return error.FontLoadingFailed;
    }
    defer c.TTF_CloseFont(font);

    // Prepare the stage for our main actors (just a red square)
    var quit = false;
    const SquareSize = 50;
    var square_x: i32 = 0;
    var square_y: i32 = 0;
    var walk_speed: f32 = 200; // Yes, It is a cube but imagine it has legs....
    var sonic_speed: f32 = 500; // Sonic Solos Attack on Titan whole verse, don't @ me
    var current_speed: f32 = 0;
    var is_running = false;
    var last_time = c.SDL_GetTicks();

    const zig_logo_color_im_undecisive_help_me = c.SDL_Color{ .r = 247, .g = 164, .b = 29, .a = 255 };

    // The show begins!
    while (!quit) {
        // Interact with the audience, respond to their cheers and jeers
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                c.SDL_QUIT => {
                    quit = true; // The audience wants to leave, let's wrap it up!
                },
                c.SDL_KEYDOWN => {
                    const key_code = event.key.keysym.sym;
                    switch (key_code) {
                        c.SDLK_ESCAPE => {
                            quit = true; // The audience demands an immediate exit, let's not upset them!
                        },
                        c.SDLK_LSHIFT => {
                            is_running = true; // Activate turbo mode, it's time to go FAST!
                        },
                        else => {
                            std.debug.print("Key: {} PRESSED.\n", .{key_code}); // Unrecognized key, let's pretend we know what it does!
                        },
                    }
                },
                c.SDL_KEYUP => {
                    const key_code = event.key.keysym.sym;
                    if (key_code == c.SDLK_LSHIFT) {
                        is_running = false; // Slow down, the turbo mode has been disengaged!
                    }
                },
                else => {}, // We're not interested in other events, let's keep the show going!
            }
        }

        // Manage time and motion, it's all about precision!
        const current_time = c.SDL_GetTicks();
        const delta_time = current_time - last_time;
        last_time = current_time;
        const dt_seconds = @intToFloat(f32, delta_time) / 1000.0; // Those macros are noice!!

        // Determine the appropriate speed, whether it's walking or running
        const target_speed = if (is_running) sonic_speed else walk_speed;
        current_speed = lerp(current_speed, target_speed, 0.1);
        const movement = @floatToInt(i32, current_speed * dt_seconds); // Could've done it another way but hopefully it showcases the macros in a nice way

        const state = c.SDL_GetKeyboardState(null);

        if (state[c.SDL_SCANCODE_LEFT] != 0) {
            square_x -= movement;
        }
        if (state[c.SDL_SCANCODE_RIGHT] != 0) {
            square_x += movement;
        }
        if (state[c.SDL_SCANCODE_UP] != 0) {
            square_y -= movement;
        }
        if (state[c.SDL_SCANCODE_DOWN] != 0) {
            square_y += movement;
        }

        // Set the stage, it's time for the grand finale!
        _ = c.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255); // Black color
        _ = c.SDL_RenderClear(renderer);

        // Present our star performer, the magnificent square!
        const square_rect = c.SDL_Rect{ .x = square_x, .y = square_y, .w = SquareSize, .h = SquareSize };
        _ = c.SDL_SetRenderDrawColor(renderer, zig_logo_color_im_undecisive_help_me.r, zig_logo_color_im_undecisive_help_me.g, zig_logo_color_im_undecisive_help_me.b, zig_logo_color_im_undecisive_help_me.a);
        _ = c.SDL_RenderFillRect(renderer, &square_rect);

        // Render text using the loaded font
        const textSurface = c.TTF_RenderText_Blended_Wrapped(font, "Hello, ZigSDL2!\n(press LShift to sprint)", zig_logo_color_im_undecisive_help_me, 500);
        defer c.SDL_FreeSurface(textSurface);

        const textTexture = c.SDL_CreateTextureFromSurface(renderer, textSurface);
        defer c.SDL_DestroyTexture(textTexture);

        const textRect = c.SDL_Rect{ .x = 10, .y = 10, .w = 300, .h = 100 };
        _ = c.SDL_RenderCopy(renderer, textTexture, null, &textRect);

        c.SDL_RenderPresent(renderer);

        c.SDL_Delay(17); // Pause for a moment, catch your breath, and let the applause fill the air!
    }
}
