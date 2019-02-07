// Convenience framework for writing visualisations with Futhark and
// C/SDL.

#include PROGHEADER

#include <inttypes.h>
#include <assert.h>
#include <SDL2/SDL.h>
#include <SDL2/SDL_ttf.h>
#include <time.h>
#include <sys/time.h>
#include <unistd.h>

static int64_t get_wall_time(void) {
  struct timeval time;
  assert(gettimeofday(&time,NULL) == 0);
  return time.tv_sec * 1000000 + time.tv_usec;
}

#define FPS 60
#define INITIAL_WIDTH 250
#define INITIAL_HEIGHT 250

#define SDL_ASSERT(x) _sdl_assert(x, __FILE__, __LINE__)
static inline void _sdl_assert(int res, const char *file, int line) {
  if (res == 0) {
    fprintf(stderr, "%s:%d: SDL error %d: %s\n",
            file, line, res, SDL_GetError());
    exit(EXIT_FAILURE);
  }
}

#define FUT_CHECK(ctx, x) _fut_check(ctx, x, __FILE__, __LINE__)
static inline void _fut_check(struct futhark_context *ctx, int res,
                              const char *file, int line) {
  if (res != 0) {
    fprintf(stderr, "%s:%d: Futhark error %d: %s\n",
            file, line, res, futhark_context_get_error(ctx));
    exit(EXIT_FAILURE);
  }
}

struct lys_context {
  struct futhark_context *fut;
  struct futhark_opaque_state *state;
  SDL_Window *wnd;
  SDL_Surface *wnd_surface;
  SDL_Surface *surface;
  TTF_Font *font;
  int width;
  int height;
  int32_t *data;
  int64_t last_time;
  int running;
};

void window_size_updated(struct lys_context *ctx, int newx, int newy) {
  // https://stackoverflow.com/a/40122002
  ctx->wnd_surface = SDL_GetWindowSurface(ctx->wnd);
  SDL_ASSERT(ctx->wnd_surface != NULL);

  ctx->width = newx;
  ctx->height = newy;

  struct futhark_opaque_state *new_state;
  FUT_CHECK(ctx->fut, futhark_entry_resize(ctx->fut, &new_state, ctx->height, ctx->width, ctx->state));
  futhark_free_opaque_state(ctx->fut, ctx->state);
  ctx->state = new_state;

  ctx->wnd_surface = SDL_GetWindowSurface(ctx->wnd);
  SDL_ASSERT(ctx->wnd_surface != NULL);

  if (ctx->data != NULL) {
    free(ctx->data);
  }
  ctx->data = malloc(ctx->width * ctx->height * sizeof(uint32_t));
  assert(ctx->data != NULL);

  if (ctx->surface != NULL) {
    SDL_FreeSurface(ctx->surface);
  }
  ctx->surface = SDL_CreateRGBSurfaceFrom(ctx->data, ctx->width, ctx->height,
                                          32, ctx->width * sizeof(uint32_t), 0xFF0000, 0xFF00, 0xFF, 0x00000000);
  SDL_ASSERT(ctx->surface != NULL);
}

void mouse_event(struct lys_context *ctx, Uint32 state, int x, int y) {
  struct futhark_opaque_state *new_state;
  FUT_CHECK(ctx->fut, futhark_entry_mouse(ctx->fut, &new_state, state, x, y, ctx->state));
  futhark_free_opaque_state(ctx->fut, ctx->state);
  ctx->state = new_state;
}

void wheel_event(struct lys_context *ctx, int x, int y) {
  struct futhark_opaque_state *new_state;
  FUT_CHECK(ctx->fut, futhark_entry_wheel(ctx->fut, &new_state, x, y, ctx->state));
  futhark_free_opaque_state(ctx->fut, ctx->state);
  ctx->state = new_state;
}

void handle_sdl_events(struct lys_context *ctx) {
  SDL_Event event;

  while (SDL_PollEvent(&event) == 1) {
    switch (event.type) {
    case SDL_WINDOWEVENT:
      switch (event.window.event) {
      case SDL_WINDOWEVENT_RESIZED:
        {
          int newx = (int)event.window.data1;
          int newy = (int)event.window.data2;
          window_size_updated(ctx, newx, newy);
          break;
        }
      }
      break;
    case SDL_QUIT:
      ctx->running = 0;
      break;
    case SDL_MOUSEMOTION:
      mouse_event(ctx, event.motion.state, event.motion.x, event.motion.y);
      break;
    case SDL_MOUSEBUTTONDOWN:
    case SDL_MOUSEBUTTONUP:
      mouse_event(ctx, 1<<(event.button.button-1), event.motion.x, event.motion.y);
      break;
    case SDL_MOUSEWHEEL:
      wheel_event(ctx, event.wheel.x, event.wheel.y);
      break;
    case SDL_KEYDOWN:
    case SDL_KEYUP:
      switch (event.key.keysym.sym) {
      case SDLK_ESCAPE:
        ctx->running = 0;
        break;
      default:
        {
          struct futhark_opaque_state *new_state;
          int e = event.key.type == SDL_KEYDOWN ? 0 : 1;
          FUT_CHECK(ctx->fut, futhark_entry_key(ctx->fut, &new_state,
                                                e, event.key.keysym.sym, ctx->state));
          futhark_free_opaque_state(ctx->fut, ctx->state);
          ctx->state = new_state;
        }
      }
    }
  }
}

void sdl_loop(struct lys_context *ctx) {
  struct futhark_i32_2d *out_arr;

  while (ctx->running) {
    int64_t now = get_wall_time();
    float delta = ((float)(now - ctx->last_time))/1000000;
    ctx->last_time = now;
    struct futhark_opaque_state *new_state;
    FUT_CHECK(ctx->fut, futhark_entry_step(ctx->fut, &new_state, delta, ctx->state));
    futhark_free_opaque_state(ctx->fut, ctx->state);
    ctx->state = new_state;

    int64_t render_start = get_wall_time();
    FUT_CHECK(ctx->fut, futhark_entry_render(ctx->fut, &out_arr, ctx->state));
    FUT_CHECK(ctx->fut, futhark_context_sync(ctx->fut));
    int64_t render_end = get_wall_time();
    double render_milliseconds = ((float) (render_end - render_start)) / 1000.0;
    FUT_CHECK(ctx->fut, futhark_values_i32_2d(ctx->fut, out_arr, ctx->data));
    FUT_CHECK(ctx->fut, futhark_free_i32_2d(ctx->fut, out_arr));

    SDL_ASSERT(SDL_BlitSurface(ctx->surface, NULL, ctx->wnd_surface, NULL)==0);

    SDL_Color black = { .r = 0x0, .g = 0x00, .b = 0x00, .a = 0xff };
    char text[30];
    snprintf(text, sizeof(text) / sizeof(char),
             "Futhark render: %.2lf ms", render_milliseconds);
    SDL_Surface *text_surface = TTF_RenderUTF8_Blended(ctx->font, text, black);
    SDL_ASSERT(text_surface != NULL);
    SDL_Rect offset_rect = { .x = 10, .y = 10,
                             .w = text_surface->w, .h = text_surface->h };
    SDL_ASSERT(SDL_BlitSurface(text_surface, NULL,
                               ctx->wnd_surface, &offset_rect) == 0);
    SDL_FreeSurface(text_surface);

    SDL_ASSERT(SDL_UpdateWindowSurface(ctx->wnd) == 0);

    SDL_Delay((int) (1000.0 / FPS - delta / 1000));

    handle_sdl_events(ctx);
  }
}

void do_sdl(struct futhark_context *fut, int height, int width) {
  struct lys_context ctx;
  memset(&ctx, 0, sizeof(struct lys_context));

  ctx.last_time = get_wall_time();
  ctx.fut = fut;
  futhark_entry_init(fut, &ctx.state, height, width);

  SDL_ASSERT(SDL_Init(SDL_INIT_EVERYTHING) == 0);
  SDL_ASSERT(TTF_Init() == 0);

  ctx.font = TTF_OpenFont("lib/github.com/diku-dk/lys/Inconsolata-Regular.ttf", 30);
  SDL_ASSERT(ctx.font != NULL);

  ctx.wnd =
    SDL_CreateWindow("Lys",
                     SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
                     width, height, SDL_WINDOW_RESIZABLE);
  SDL_ASSERT(ctx.wnd != NULL);

  window_size_updated(&ctx, width, height);

  ctx.running = 1;
  sdl_loop(&ctx);
  FUT_CHECK(fut, futhark_free_opaque_state(fut, ctx.state));

  free(ctx.data);
  SDL_FreeSurface(ctx.surface);
  TTF_CloseFont(ctx.font);
  // do not free wnd_surface (see SDL_GetWindowSurface)
  SDL_DestroyWindow(ctx.wnd);
  SDL_Quit();
}

int main(int argc, char** argv) {
  int width = INITIAL_WIDTH, height = INITIAL_HEIGHT;

  int c;

  while ( (c = getopt(argc, argv, "w:h:")) != -1) {
    switch (c) {
    case 'w':
      width = atoi(optarg);
      if (width <= 0) {
        fprintf(stderr, "'%s' is not a valid width.\n", optarg);
        exit(EXIT_FAILURE);
      }
      break;
    case 'h':
      height = atoi(optarg);
      if (height <= 0) {
        fprintf(stderr, "'%s' is not a valid width.\n", optarg);
        exit(EXIT_FAILURE);
      }
      break;
    default:
      fprintf(stderr, "unknown option: %c\n", c);
      exit(EXIT_FAILURE);
    }
  }

  if (optind < argc) {
    fprintf(stderr, "Excess non-options: ");
    while (optind < argc)
      fprintf(stderr, "%s ", argv[optind++]);
    fprintf(stderr, "\n");
    exit(EXIT_FAILURE);
  }

  struct futhark_context_config *cfg = futhark_context_config_new();
  assert(cfg != NULL);
  struct futhark_context *ctx = futhark_context_new(cfg);
  assert(ctx != NULL);

  do_sdl(ctx, height, width);

  futhark_context_free(ctx);
  futhark_context_config_free(cfg);
  return 0;
}
