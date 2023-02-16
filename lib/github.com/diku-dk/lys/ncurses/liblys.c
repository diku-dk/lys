#include "liblys.h"
#include <sys/ioctl.h>
#include <unistd.h>
#include <string.h>

struct termios orig_termios;

void cooked_mode() {
  tcsetattr(STDIN_FILENO, TCSAFLUSH, &orig_termios);
  printf("\033[?25h");
}

void raw_mode() {
  printf("\033[?25l");

  tcgetattr(STDIN_FILENO, &orig_termios);
  atexit(cooked_mode);

  struct termios raw = orig_termios;
  raw.c_iflag &= ~(IXON);
  raw.c_lflag &= ~(ECHO | ICANON | ISIG);
  raw.c_cc[VMIN] = 0;
  raw.c_cc[VTIME] = 0;
  tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw);
}

void clear_screen() {
  printf("\033[2");
}

void clear_line() {
  printf("\033[2K");
}

void def() {
  printf("\033[0m");
}

void fg_rgb(uint8_t r, uint8_t g, uint8_t b) {
  printf("\033[38;2;%d;%d;%dm", r, g, b);
}

void bg_rgb(uint8_t r, uint8_t g, uint8_t b) {
  printf("\033[48;2;%d;%d;%dm", r, g, b);
}

void cursor_home() {
  printf("\033[;H");
}

void cursor_goto(int x, int y) {
  printf("\033[%d;%dH", y, x);
}

void render(int nrows, int ncols, const uint32_t *rgbs,
            uint32_t *fgs, uint32_t *bgs, char *chars) {
  for (int i = 0; i < nrows; i++) {
    for (int j = 0; j < ncols; j++) {
      uint32_t w0 = rgbs[(i*2)*ncols+j];
      uint32_t w1 = rgbs[(i*2+1)*ncols+j];
      fgs[i*ncols+j] = w0;
      bgs[i*ncols+j] = w1;
      chars[i*ncols+j] = 127; // Sentinel.
    }
  }
}

void display(int nrows, int ncols,
             const uint32_t *fgs, const uint32_t *bgs, const char *chars) {
  uint32_t prev_w0 = 0xdeadbeef;
  uint32_t prev_w1 = 0xdeadbeef;
  for (int i = 0; i < nrows; i++) {
    for (int j = 0; j < ncols; j++) {
      double r0 = 0, g0 = 0, b0 = 0;
      double r1 = 0, g1 = 0, b1 = 0;
      uint32_t w0 = fgs[i*ncols+j];
      uint32_t w1 = bgs[i*ncols+j];
      if (w0 != prev_w0 || w1 != prev_w1) {
        r0 = (w0>>16)&0xFF;
        g0 = (w0>>8)&0xFF;
        b0 = (w0>>0)&0xFF;
        r1 = (w1>>16)&0xFF;
        g1 = (w1>>8)&0xFF;
        b1 = (w1>>0)&0xFF;
        fg_rgb(r0, g0, b0);
        bg_rgb(r1, g1, b1);
        prev_w0 = w0;
        prev_w1 = w1;
      }
      char c = chars[i*ncols+j];
      if (c == 127) {
        fputs("▀", stdout);
      } else {
        fputc(c, stdout);
      }
    }
  }
}

void keydown(struct lys_context *ctx, int keysym) {
  ctx->key_pressed = keysym;
  struct futhark_opaque_state *new_state;
  FUT_CHECK(ctx->fut, futhark_entry_key(ctx->fut, &new_state, 0, keysym, ctx->state));
  futhark_free_opaque_state(ctx->fut, ctx->state);
  ctx->state = new_state;
}


void keyup(struct lys_context *ctx, int keysym) {
  struct futhark_opaque_state *new_state;
  FUT_CHECK(ctx->fut, futhark_entry_key(ctx->fut, &new_state, 1, keysym, ctx->state));
  futhark_free_opaque_state(ctx->fut, ctx->state);
  ctx->state = new_state;
}

// Best-effort at translating VT100 key codes to SDL.
//
// The handling of keydown/keyup events is complicated by the fact
// that the terminal does not report keyup events.  As a workaround,
// we treat every input key as a keydown for one frame, then a keyup
// the following frame.  Many applications will misbehave, but not
// all!
void check_input(struct lys_context *ctx) {
  if (ctx->key_pressed) {
    keyup(ctx, ctx->key_pressed);
    ctx->key_pressed = 0;
  }

  char c;
  if (read(STDIN_FILENO, &c, 1) != 0) {
    switch (c) {
    case 3: // Ctrl-c
      ctx->running = 0;
      return;
    case 0x1b: // Escape
      if (read(STDIN_FILENO, &c, 1) != 0) {
        switch (c) {
        case 0x1b: // Double escape!
          ctx->running = 0;
          return;
        case 'O': // Application key
          if (read(STDIN_FILENO, &c, 1) != 0) {
            switch (c) {
            case 'P':
              keydown(ctx, 0x4000003A);
              return;
            case 'Q':
              keydown(ctx, 0x4000003B);
              return;
            case 'R':
              keydown(ctx, 0x4000003C);
              return;
            case 'S':
              keydown(ctx, 0x4000003D);
              return;
            }
          }
          return;
        }
      }
      if (read(STDIN_FILENO, &c, 1) != 0) {
        switch (c) {
        case 'A':
          // Arrow up
          keydown(ctx, 0x40000052);
          return;
        case 'B':
          // Arrow down
          keydown(ctx, 0x40000051);
          return;
        case 'C':
          // Arrow right
          keydown(ctx, 0x4000004F);
          return;
        case 'D':
          // Arrow left
          keydown(ctx, 0x40000050);
          return;
        }
      }
      return;
    default:
      if (c >= 'a' && c <= 'z') {
        keydown(ctx, 0x61 + (c-'a'));
        return;
      }
    }
  }
}

void lys_run_ncurses(struct lys_context *ctx) {
  ctx->running = 1;
  ctx->last_time = lys_wall_time();

  int nrows = ctx->height/2;
  int ncols = ctx->width;

  uint32_t *rgbs = calloc((nrows*2)*ncols, sizeof(uint32_t));

  ctx->event_handler(ctx, LYS_LOOP_START);

  while (ctx->running) {
    int64_t now = lys_wall_time();
    float delta = ((float)(now - ctx->last_time))/1000000.0;
    ctx->fps = (ctx->fps*0.9 + (1/delta)*0.1);
    ctx->last_time = now;
    struct futhark_opaque_state *new_state, *old_state = ctx->state;
    FUT_CHECK(ctx->fut, futhark_entry_step(ctx->fut, &new_state, delta, old_state));
    ctx->state = new_state;

    struct futhark_u32_2d *out_arr;
    FUT_CHECK(ctx->fut, futhark_entry_render(ctx->fut, &out_arr, ctx->state));
    FUT_CHECK(ctx->fut, futhark_values_u32_2d(ctx->fut, out_arr, rgbs));
    FUT_CHECK(ctx->fut, futhark_context_sync(ctx->fut));
    FUT_CHECK(ctx->fut, futhark_free_u32_2d(ctx->fut, out_arr));
    FUT_CHECK(ctx->fut, futhark_free_opaque_state(ctx->fut, old_state));

    render(nrows, ncols, rgbs, ctx->fgs, ctx->bgs, ctx->chars);
    ctx->event_handler(ctx, LYS_LOOP_ITERATION);
    display(nrows, ncols, ctx->fgs, ctx->bgs, ctx->chars);
    fflush(stdout);

    check_input(ctx);

    int delay =  1000.0/ctx->max_fps - delta*1000.0;
    if (delay > 0) {
      usleep(delay*1000);
    }

    def();
    cursor_home();
  }

  ctx->event_handler(ctx, LYS_LOOP_END);

  free(rgbs);
  free(ctx->fgs);
  free(ctx->bgs);
  free(ctx->chars);

  FUT_CHECK(ctx->fut, futhark_free_opaque_state(ctx->fut, ctx->state));
}

void lys_setup(struct lys_context *ctx, int max_fps) {
  memset(ctx, 0, sizeof(struct lys_context));

  struct winsize w;
  ioctl(STDOUT_FILENO, TIOCGWINSZ, &w);

  ctx->width = w.ws_col;
  ctx->height = w.ws_row*2;
  ctx->fps = 0;
  ctx->max_fps = max_fps;
  ctx->fgs = malloc(ctx->width * ctx->height * sizeof(uint32_t));
  ctx->bgs = malloc(ctx->width * ctx->height * sizeof(uint32_t));
  ctx->chars = malloc(ctx->width * ctx->height * sizeof(char));
  ctx->key_pressed = 0;
  raw_mode();
}

void draw_text(struct lys_context *ctx, char* buffer, int32_t colour,
               int x_start, int y_start) {
  int x = x_start;
  int y = y_start;
  for (int i = 0; buffer[i]; i++) {
    if (buffer[i] == '\n') {
      x = x_start;
      y++;
      continue;
    } else {
      if (x < ctx->width && y < ctx->height) {
        ctx->fgs[y*ctx->width+x] = colour;
        ctx->bgs[y*ctx->width+x] = 0;
        ctx->chars[y*ctx->width+x] = buffer[i];
      }
      x++;
    }
  }
}
