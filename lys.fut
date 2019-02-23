import "lib/github.com/diku-dk/lys/lys"

let rotate_point (x: f32) (y: f32) (angle: f32) =
  let s = f32.sin angle
  let c = f32.cos angle
  let xnew = x * c - y * s
  let ynew = x * s + y * c
  in (xnew, ynew)

type text_content = (f32, i32, i32, i32)
module lys: lys with text_content = text_content = {
  type text_content = (f32, i32, i32, i32)
  type state = {time: f32, h: i32, w: i32,
                center: (i32, i32),
                moving: (i32, i32),
                mouse: (i32, i32),
                radius: i32,
                paused: bool
               }

  let init (h: i32) (w: i32): state = {time = 0, w, h,
                                       center=(h/2,w/2),
                                       moving = (0,0),
                                       mouse = (0,0),
                                       radius = 20,
                                       paused = false
                                      }

  let resize (h: i32) (w: i32) (s: state) =
    s with h = h with w = w

  let key (e: key_event) (key: i32) (s: state) =
    match e
    case #keydown ->
      if key == SDLK_RIGHT then s with moving.2 = 1
      else if key == SDLK_LEFT then s with moving.2 = -1
      else if key == SDLK_UP then s with moving.1 = -1
      else if key == SDLK_DOWN then s with moving.1 = 1
      else if key == SDLK_SPACE then s with paused = !s.paused
      else s
    case #keyup ->
      if key == SDLK_RIGHT then s with moving.2 = 0
      else if key == SDLK_LEFT then s with moving.2 = 0
      else if key == SDLK_UP then s with moving.1 = 0
      else if key == SDLK_DOWN then s with moving.1 = 0
      else s

  let move (x: i32, y: i32) (dx,dy) = (x+dx, y+dy)
  let diff (x1: i32, y1: i32) (x2, y2) = (x2 - x1, y2 - y1)

  let mouse (mouse_state: i32) (x: i32) (y: i32) (s: state) =
    s with mouse = (y,x) with center = if mouse_state != 0 then move s.center (diff s.mouse (y,x))
                                       else s.center

  let wheel _ y (s: state) = s with radius = i32.max 0 (s.radius + y)

  let step td (s: state) =
    s with time = s.time + (if s.paused then 0 else td)
      with center = move s.center s.moving

  let render (s: state) =
    tabulate_2d (s.h) (s.w)
                (\i j ->
                   let (i', j') = rotate_point (r32 (i-s.center.1)) (r32 (j-s.center.2)) s.time
                   in if f32.sqrt (i'**2 + j'**2) < r32 s.radius then argb.white
                      else if i' > j' then argb.red else argb.blue)

  let text_format = "Futhark render: %.2f ms\nCenter: (%d, %d)\nRadius: %d"

  let text_content (render_duration: f32) (s: state): text_content =
    (render_duration, s.center.1, s.center.2, s.radius)

  let text_colour = const argb.yellow
}
