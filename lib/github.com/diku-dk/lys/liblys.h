#ifndef LIBLYS_HEADER
#define LIBLYS_HEADER

#include <stdio.h>
#include <stdbool.h>
#include <assert.h>
#include <time.h>
#include <sys/time.h>
#include <SDL2/SDL.h>
#include <SDL2/SDL_ttf.h>

#include PROGHEADER

enum lys_event {
  LYS_LOOP_START,
  LYS_LOOP_ITERATION,
  LYS_LOOP_END,
  LYS_WINDOW_SIZE_UPDATED,
  LYS_F1
};

struct lys_context {
  struct futhark_context_config* futcfg;
  struct futhark_context *fut;
  struct futhark_opaque_state *state;
  SDL_Window *wnd;
  SDL_Surface *wnd_surface;
  SDL_Surface *surface;
  int width;
  int height;
  int32_t *data;
  int64_t last_time;
  bool running;
  bool grab_mouse;
  bool mouse_grabbed;
  float fps;
  int max_fps;
  int sdl_flags;
  void* event_handler_data;
  void (*event_handler)(struct lys_context*, enum lys_event);
};

#define FUT_CHECK(ctx, x) _fut_check(ctx, x, __FILE__, __LINE__)
static inline void _fut_check(struct futhark_context *ctx, int res,
                              const char *file, int line) {
  if (res != 0) {
    fprintf(stderr, "%s:%d: Futhark error %d: %s\n",
            file, line, res, futhark_context_get_error(ctx));
    exit(EXIT_FAILURE);
  }
}

#define SDL_ASSERT(x) _sdl_assert(x, __FILE__, __LINE__)
static inline void _sdl_assert(int res, const char *file, int line) {
  if (res == 0) {
    fprintf(stderr, "%s:%d: SDL error %d: %s\n",
            file, line, res, SDL_GetError());
    exit(EXIT_FAILURE);
  }
}

int64_t lys_wall_time();

void lys_setup(struct lys_context *ctx, int width, int height, int max_fps,
               const char *deviceopt, bool device_interactive, int sdl_flags);

void lys_run_sdl(struct lys_context *ctx);

#ifdef LYS_TTF
void draw_text(struct lys_context *ctx, TTF_Font *font, int font_size, char* buffer, int32_t colour,
               int x_start, int y_start);
#endif

#endif
