#define SDL_MAIN_USE_CALLBACKS
#include <algorithm>
#include <list>
#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>




enum sprite_state { SPRITE_CONTINUE, SPRITE_DELETE };
enum game_state { GAME_INIT, GAME_HOME, GAME_PAUSE, GAME_CONTINUE, GAME_OVER, GAME_WIN };


SDL_Window *Window = NULL;
SDL_Renderer *Renderer = NULL;
int Width, Height;
game_state GameState = GAME_INIT;
int EnemyInterval;
int Score = 0;


class sprite {
    public:
        int hp = 1;
        int atk = 1;
        double v = 0;
        double vx = 0;
        double vy = 0;
        int team = 0;
        SDL_Color color = {0, 0, 0, 0};
        SDL_FRect rect = {0, 0, 0, 0};

        int draw() {
            SDL_SetRenderDrawColor(Renderer, color.r, color.g, color.b, color.a);
            SDL_RenderFillRect(Renderer, &rect);
            return SPRITE_CONTINUE;
        }

        int update() {
            if (hp <= 0) {
                return SPRITE_DELETE;
            }
            double magnitute = SDL_sqrt(vy * vy + vx * vx);
            if (magnitute > 0) {
                rect.x += v * vx / magnitute;
                rect.y += v * vy / magnitute;
            }
            return SPRITE_CONTINUE;
        }
};


class bullet: public sprite {
    public:
        bullet() {
            rect = {0, 0, 6.18, 10};
            color = {200, 200, 200, 255};
            v = 10;
        }

        int update() {
            if (sprite::update() == SPRITE_CONTINUE) {
                if (rect.x > Width || rect.x + rect.w < 0 || rect.y + rect.h < 0 || rect.y > Height) {
                    return SPRITE_DELETE;
                }
            } else {
                return SPRITE_DELETE;
            }
            return SPRITE_CONTINUE;
        }
};


class ship: public sprite {
    public:
        std::list<bullet> bullets;

        ship() {
            rect = {0, 0, 30.9, 50};
            color = {100, 100, 100, 255};
            v = 5;
            hp = 5;
        }

        int fire() {
            bullets.push_back(bullet());
            bullets.back().atk = 1;
            bullets.back().v = 2 * v;
            bullets.back().vx = vx;
            bullets.back().vy = vy - 2 * v;
            bullets.back().rect.x = rect.x + rect.w / 2 - bullets.back().rect.w / 2;
            bullets.back().rect.y = rect.y + rect.h / 2 - bullets.back().rect.h / 2;
            return 0;
        }
};


class player: public ship {
    public:
        player() {
            color = {255, 255, 255, 255};
            rect.x = Width / 2 - rect.w / 2;
            rect.y = Height * 0.75 - rect.h / 2;
        }

        int fire() {
            for (int i = -SDL_sqrt(Score / 200); i <= SDL_sqrt(Score / 200); i ++) {
                ship::fire();
                bullets.back().rect.x += i * 10;
                bullets.back().color.r = SDL_rand(255);
                bullets.back().color.g = SDL_rand(255);
                bullets.back().color.b = SDL_rand(255);
            }
            return 0;
        }

        int update() {
            if (ship::update() == SPRITE_CONTINUE) {
                if (rect.x > Width) rect.x = Width;
                else if (rect.x + rect.w < 0) rect.x = -rect.w;
                if (rect.y > Height) rect.y = Height;
                else if (rect.y + rect.h < 0) rect.y = -rect.h;
            } else {
                color = {255, 0, 0, 255};
                GameState = GAME_OVER;
                return SPRITE_DELETE;
            }
            return SPRITE_CONTINUE;
        }
};


player Player;


class enemy: public ship {
    public:
        enemy() {
            v = 1;
            team = 1;
            rect.x = SDL_rand(Width - rect.w);
            rect.y = -rect.h;
            v = 5;
            vy = v;
            team = 1;
        }

        int update() {
            if (SDL_rand(100) < 3000 / EnemyInterval) {
                fire();
                bullets.back().vy = 2 * v;
                bullets.back().vx = SDL_rand(v) / 2.0 - v / 4;
            }
            if (SDL_rand(100) < 3000 / EnemyInterval) {
                vx = SDL_rand(v) / 2.0 - v / 4;
            }

            for (auto &bullet: Player.bullets) {
                if (SDL_HasRectIntersectionFloat(&rect, &bullet.rect)) {
                    hp -= bullet.atk;
                    bullet.hp -= atk;
                    Score ++;
                }
            }

            for (auto &bullet: bullets) {
                if (SDL_HasRectIntersectionFloat(&Player.rect, &bullet.rect)) {
                    Player.hp -= bullet.atk;
                    bullet.hp -= Player.atk;
                }
            }

            if (SDL_HasRectIntersectionFloat(&rect, &Player.rect)) {
                Player.hp -= atk;
                hp -= Player.atk;
            }
            if (ship::update() == SPRITE_CONTINUE) {
                if (rect.y > Height) {
                    return SPRITE_DELETE;
                }
            } else {
                Score += 100;
                return SPRITE_DELETE;
            }
            return SPRITE_CONTINUE;
        }
};

std::list<enemy> Enemys;


Uint32 addEnemy(void *userdata, SDL_TimerID timerID, Uint32 interval) {
    if (GameState == GAME_CONTINUE) {
        Enemys.push_back(enemy());
        if (EnemyInterval > 400) {
            EnemyInterval -= 100;
            return SDL_rand(EnemyInterval) + 1;
        } else {
            return SDL_rand(400) + 1;
        }
    }
    else if (GameState == GAME_OVER) {
        SDL_RemoveTimer(timerID);
        return 0;
    }
    return interval;
}


SDL_AppResult SDL_AppInit(void **appstate, int argc, char *args[]) {
    // *appstate = new game_state;
    // *reinterpret_cast<game_state*>(appstate) = GAME_INIT;

    if (!SDL_CreateWindowAndRenderer("Sternenstaub", 1000, 618, SDL_WINDOW_FULLSCREEN, &Window, &Renderer)) {
        SDL_LogError(SDL_LOG_CATEGORY_VIDEO, "Video error: %s", SDL_GetError());
    }
    SDL_GetWindowSizeInPixels(Window, &Width, &Height);

    GameState = GAME_HOME; // not using appstate because too complicated
    // *reinterpret_cast<game_state*>(*appstate) = GAME_HOME;
    return SDL_APP_CONTINUE;
}


SDL_AppResult SDL_AppEvent(void *appstate, SDL_Event *event) {
    if (event->type == SDL_EVENT_QUIT) {
        return SDL_APP_SUCCESS;
    }

    switch (GameState)
    {
    case GAME_HOME:
        switch (event->type)
        {
        case SDL_EVENT_KEY_DOWN:
            switch (event->key.key) {
                case SDLK_Q:
                    return SDL_APP_SUCCESS;
                default:
                    Score = 0;
                    Player = player();
                    Enemys.clear();
                    EnemyInterval = 3000;
                    GameState = GAME_CONTINUE;
                    SDL_srand(SDL_GetTicks());
                    SDL_AddTimer(1000, addEnemy, NULL);
                    break;
            }
            break;
        }
        break;
    case GAME_CONTINUE:
        switch (event->type)
        {
        case SDL_EVENT_KEY_DOWN:
            switch (event->key.key) {
                case SDLK_ESCAPE:
                    GameState = GAME_PAUSE;
                    return SDL_APP_CONTINUE;
            }
            break;
        case SDL_EVENT_KEY_UP:
            switch (event->key.key) {
                case SDLK_SPACE:
                    Player.fire();
                    break;
            }
            break;
        }
        break;
    case GAME_PAUSE:
        switch (event->type)
        {
        case SDL_EVENT_KEY_DOWN:
            switch (event->key.key) {
                case SDLK_ESCAPE:
                    GameState = GAME_CONTINUE;
                    return SDL_APP_CONTINUE;
                case SDLK_Q:
                    return SDL_APP_SUCCESS;
            }
            break;
        }
        break;
    case GAME_OVER:
        switch (event->type)
        {
        case SDL_EVENT_KEY_DOWN:
            switch (event->key.key) {
                case SDLK_ESCAPE:
                    GameState = GAME_HOME;
                    return SDL_APP_CONTINUE;
            }
            break;
        }
        break;
    }
    
    return SDL_APP_CONTINUE;
}


SDL_AppResult SDL_AppIterate(void *appstate) {

    switch (GameState)
    {
    case GAME_HOME:
        SDL_SetRenderDrawColor(Renderer, 0, 0, 0, 255);
        SDL_RenderClear(Renderer);
        SDL_SetRenderDrawColor(Renderer, 255, 255, 255, 255);
        SDL_RenderDebugTextFormat(Renderer, Width / 2 - 100, Height / 2 - 60, "-- Sternenstaub --");
        SDL_RenderDebugTextFormat(Renderer, Width / 2 - 100, Height / 2 - 20, "Press any key to     Start");
        SDL_RenderDebugTextFormat(Renderer, Width / 2 - 100, Height / 2 + 10, "Press [Q] to         Quit");
        SDL_RenderDebugTextFormat(Renderer, Width / 2 - 100, Height / 2 + 50, "Press [WASD] to      Move");
        SDL_RenderDebugTextFormat(Renderer, Width / 2 - 100, Height / 2 + 80, "Press [Space] to     Fire");
        SDL_RenderPresent(Renderer);
        break;
    case GAME_CONTINUE: {
        auto *keystate = SDL_GetKeyboardState(NULL);
        Player.vx = 0;
        Player.vy = 0;
        if (keystate[SDL_SCANCODE_A]) Player.vx += -1;
        if (keystate[SDL_SCANCODE_D]) Player.vx += 1;
        if (keystate[SDL_SCANCODE_W]) Player.vy += -1;
        if (keystate[SDL_SCANCODE_S]) Player.vy += 1;

        SDL_SetRenderDrawColor(Renderer, 0, 0, 0, 0);
        SDL_RenderClear(Renderer);

        Player.update();
        Player.draw();
        
        for (auto it = Player.bullets.begin(); it != Player.bullets.end(); ) {
            if (it->update() == SPRITE_DELETE) {
                it = Player.bullets.erase(it);
            } else {
                it->draw();
                it++;
            }
        }
        
        for (auto it = Enemys.begin(); it != Enemys.end(); ) {
            if (it->update() == SPRITE_DELETE) {
                it = Enemys.erase(it);
            } else {
                for (auto it2 = it->bullets.begin(); it2 != it->bullets.end(); ) {
                    if (it2->update() == SPRITE_DELETE) {
                        it2 = it->bullets.erase(it2);
                    } else {
                        it2->draw();
                        it2++;
                    }
                }
                it->draw();
                it++;
            }
        }

        SDL_SetRenderDrawColor(Renderer, 255, 255, 255, 255);
        SDL_RenderDebugTextFormat(Renderer, 10, 10, "Score: %d", Score);
        SDL_RenderDebugTextFormat(Renderer, 10, 30, "HP: %d", Player.hp);
        SDL_RenderPresent(Renderer);
        break;
    }

    case GAME_PAUSE:
        SDL_SetRenderDrawColor(Renderer, 0, 0, 0, 255);
        SDL_RenderClear(Renderer);
        SDL_SetRenderDrawColor(Renderer, 255, 255, 255, 255);
        SDL_RenderDebugTextFormat(Renderer, Width / 2 - 100, Height / 2 - 50, "Game Paused");
        SDL_RenderDebugTextFormat(Renderer, Width / 2 - 100, Height / 2 - 20, "Press [Esc] to continue");
        SDL_RenderDebugTextFormat(Renderer, Width / 2 - 100, Height / 2 + 10, "Press [Q] to quit");
        SDL_RenderPresent(Renderer);
        break;

    case GAME_OVER:
        SDL_SetRenderDrawColor(Renderer, 0, 0, 0, 255);
        SDL_RenderClear(Renderer);
        Player.draw();
        SDL_SetRenderDrawColor(Renderer, 255, 255, 255, 255);
        SDL_RenderDebugTextFormat(Renderer, Width / 2 - 100, Height / 2 - 50, "Game Over");
        SDL_RenderDebugTextFormat(Renderer, Width / 2 - 100, Height / 2 - 20, "Your: Score: %d", Score);
        SDL_RenderDebugTextFormat(Renderer, Width / 2 - 100, Height / 2 + 10, "Press [Esc] for home");
        SDL_RenderPresent(Renderer);
        break;

    default:
        break;
    }

    SDL_Delay(1000 / 60);
    return SDL_APP_CONTINUE;
}


void SDL_AppQuit(void* appstate, SDL_AppResult resurlt) {
}