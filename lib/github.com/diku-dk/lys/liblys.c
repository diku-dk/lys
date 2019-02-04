// Convenience framework for writing visualisations with Futhark and
// C/SDL.

#include PROGHEADER

#include <inttypes.h>
#include <assert.h>
#include <SDL2/SDL.h>
#include <time.h>
#include <sys/time.h>

static int64_t get_wall_time(void) {
  struct timeval time;
  assert(gettimeofday(&time,NULL) == 0);
  return time.tv_sec * 1000000 + time.tv_usec;
}

#define FPS 30
#define INITIAL_WIDTH 250
#define INITIAL_HEIGHT 250

#define SDL_ASSERT(x) _sdl_assert(x, __FILE__, __LINE__)
static inline void _sdl_assert(int res, const char *file, int line)
{
  if (res == 0) {
    fprintf(stderr, "%s:%d: SDL error %d: %s\n",
            file, line, res, SDL_GetError());
    exit(EXIT_FAILURE);
  }
}

#define FUT_CHECK(ctx, x) _fut_check(ctx, x, __FILE__, __LINE__)
static inline void _fut_check(struct futhark_context *ctx, int res,
                              const char *file, int line)
{
  if (res != 0) {
    fprintf(stderr, "%s:%d: Futhark error %d: %s\n",
            file, line, res, futhark_context_get_error(ctx));
    exit(EXIT_FAILURE);
  }
}

struct lys_context {
  struct futhark_context *fut;
  SDL_Window *wnd;
  SDL_Surface *wnd_surface;
  SDL_Surface *surface;
  int width;
  int height;
  int32_t *data;
  int64_t start_time;
  int vx;
  int vy;
  int running;
};

void window_size_updated(struct lys_context *ctx, struct futhark_context *fut,
                         int newx, int newy)
{
  // https://stackoverflow.com/a/40122002
  ctx->wnd_surface = SDL_GetWindowSurface(ctx->wnd);
  SDL_ASSERT(ctx->wnd_surface != NULL);

  ctx->width = newx;
  ctx->height = newy;

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

void handle_sdl_events(struct lys_context *ctx, struct futhark_context *fut)
{
  SDL_Event event;

  while (SDL_PollEvent(&event) == 1) {
    switch (event.type) {
    case SDL_WINDOWEVENT:
      switch (event.window.event) {
      case SDL_WINDOWEVENT_RESIZED:
        {
          int newx = (int)event.window.data1;
          int newy = (int)event.window.data2;
          window_size_updated(ctx, fut, newx, newy);
          break;
        }
      }
      break;
    case SDL_QUIT:
      ctx->running = 0;
      break;
    case SDL_KEYDOWN:
      switch (event.key.keysym.sym) {
      case SDLK_ESCAPE:
      case SDLK_q:
        ctx->running = 0;
        break;
      case SDLK_UP:
        ctx->vy--;
        break;
      case SDLK_DOWN:
        ctx->vy++;
        break;
      case SDLK_LEFT:
        ctx->vx--;
        break;
      case SDLK_RIGHT:
        ctx->vx++;
        break;
      }
    }
  }
}

void sdl_loop(struct lys_context *ctx, struct futhark_context *fut)
{
  struct futhark_i32_2d *out_arr;

  while (ctx->running) {
    int64_t now = get_wall_time();
    float time = ((float)(now - ctx->start_time))/1000000;
    FUT_CHECK(fut, futhark_entry_render(fut, &out_arr, time, ctx->height, ctx->width));
    FUT_CHECK(fut, futhark_values_i32_2d(fut, out_arr, ctx->data));
    FUT_CHECK(fut, futhark_free_i32_2d(fut, out_arr));

    SDL_ASSERT(SDL_BlitSurface(ctx->surface, NULL, ctx->wnd_surface, NULL)==0);
    SDL_ASSERT(SDL_UpdateWindowSurface(ctx->wnd) == 0);

    SDL_Delay(1000 / FPS);

    handle_sdl_events(ctx, fut);
  }
}

void do_sdl(struct futhark_context *fut)
{
  struct lys_context ctx;
  memset(&ctx, 0, sizeof(struct lys_context));

  ctx.start_time = get_wall_time();

  SDL_ASSERT(SDL_Init(SDL_INIT_EVERYTHING) == 0);

  ctx.wnd =
    SDL_CreateWindow("Lys",
                     SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
                     INITIAL_WIDTH, INITIAL_HEIGHT, SDL_WINDOW_RESIZABLE);
  SDL_ASSERT(ctx.wnd != NULL);

  window_size_updated(&ctx, fut, INITIAL_WIDTH, INITIAL_HEIGHT);

  ctx.running = 1;
  sdl_loop(&ctx, fut);

  free(ctx.data);
  SDL_FreeSurface(ctx.surface);
  // do not free wnd_surface (see SDL_GetWindowSurface)
  SDL_DestroyWindow(ctx.wnd);
  SDL_Quit();
}

int main()
{
  struct futhark_context_config *cfg = futhark_context_config_new();
  assert(cfg != NULL);
  struct futhark_context *ctx = futhark_context_new(cfg);
  assert(ctx != NULL);

  do_sdl(ctx);

  futhark_context_free(ctx);
  futhark_context_config_free(cfg);
  return 0;
}
