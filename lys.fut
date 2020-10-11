import "lib/github.com/diku-dk/lys/lys"

let rotate_point (x: f32) (y: f32) (angle: f32) =
  let s = f32.sin angle
  let c = f32.cos angle
  let xnew = x * c - y * s
  let ynew = x * s + y * c
  in (xnew, ynew)

type text_content = (i64, i64, i64, i64, i64)
module lys: lys with text_content = text_content = {
  type state = {time: f32, h: i64, w: i64,
                center: (i64, i64),
                center_object: #circle | #square,
                moving: (i64, i64),
                mouse: (i64, i64),
                radius: i64,
                paused: bool
               }
  let grab_mouse = false

  let init (seed: u32) (h: i64) (w: i64): state =
    {time = 0, w, h,
     center= (h/(1+i64.u32 seed%11), w/(1+i64.u32 seed%7)),
     center_object = #circle,
     moving = (0,0),
     mouse = (0,0),
     radius = 20,
     paused = false
    }

  let resize (h: i64) (w: i64) (s: state) =
    s with h = h with w = w

  let keydown (key: i32) (s: state) =
    if key == SDLK_RIGHT then s with moving.1 = 1
    else if key == SDLK_LEFT then s with moving.1 = -1
    else if key == SDLK_UP then s with moving.0 = -1
    else if key == SDLK_DOWN then s with moving.0 = 1
    else if key == SDLK_SPACE then s with paused = !s.paused
    else if key == SDLK_c then s with center_object = #circle
    else if key == SDLK_s then s with center_object = #square
    else s

  let keyup (key: i32) (s: state) =
    if key == SDLK_RIGHT then s with moving.1 = 0
    else if key == SDLK_LEFT then s with moving.1 = 0
    else if key == SDLK_UP then s with moving.0 = 0
    else if key == SDLK_DOWN then s with moving.0 = 0
    else s

  let move (x: i64, y: i64) (dx,dy) = (x+dx, y+dy)
  let diff (x1: i64, y1: i64) (x2, y2) = (x2 - x1, y2 - y1)

  let event (e: event) (s: state) =
    match e
    case #step td ->
      s with time = s.time + (if s.paused then 0 else td)
        with center = move s.center s.moving
    case #wheel {dx=_, dy} ->
      s with radius = i64.max 0 (s.radius + i64.i32 dy)
    case #mouse {buttons, x, y} ->
      s with mouse = (i64.i32 y, i64.i32 x)
        with center = if buttons != 0
                      then move s.center (diff s.mouse (i64.i32 y, i64.i32 x))
                      else s.center
    case #keydown {key} ->
      keydown key s
    case #keyup {key} ->
      keyup key s

  let render (s: state) =
    tabulate_2d s.h s.w
                (\i j ->
                   let (i', j') = rotate_point (f32.i64 (i-s.center.0)) (f32.i64 (j-s.center.1)) s.time
                   let r = f32.i64 s.radius
                   let inside = match s.center_object
                                case #circle -> f32.sqrt (i'**2 + j'**2) < f32.i64 s.radius
                                case #square -> i' >= -r && i' < r && j' >= -r && j' < r
                   in if inside then argb.white
                      else if i' > j' then argb.red else argb.blue)

  type text_content = text_content

  let text_format () =
    "FPS: %ld\nCenter: (%ld, %ld)\nCenter object: %[circle|square]\nRadius: %ld"

  let text_content (render_duration: f32) (s: state): text_content =
    let center_object_id = match s.center_object
                           case #circle -> 0
                           case #square -> 1
    in (i64.f32 render_duration, s.center.0, s.center.1, center_object_id, s.radius)

  let text_colour = const argb.yellow
}
