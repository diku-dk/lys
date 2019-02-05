import "lib/github.com/diku-dk/lys/lys"

let rotate_point (x: f32) (y: f32) (angle: f32) =
  let s = f32.sin angle
  let c = f32.cos angle
  let xnew = x * c - y * s
  let ynew = x * s + y * c
  in (xnew, ynew)

module lys: lys = {
  type state = {time: f32, h: i32, w: i32, center: (i32, i32), moving: (i32, i32)}

  let init (h: i32) (w: i32): state = {time = 0, w, h, center=(h/2,w/2), moving = (0,0)}

  let resize (h: i32) (w: i32) (s: state) =
    s with h = h with w = w

  let key (e: key_event) (key: i32) (s: state) =
    match e
    case #keydown ->
      if key == SDLK_RIGHT then s with moving.2 = 1
      else if key == SDLK_LEFT then s with moving.2 = -1
      else if key == SDLK_UP then s with moving.1 = -1
      else if key == SDLK_DOWN then s with moving.1 = 1
      else s
    case #keyup ->
      if key == SDLK_RIGHT then s with moving.2 = 0
      else if key == SDLK_LEFT then s with moving.2 = 0
      else if key == SDLK_UP then s with moving.1 = 0
      else if key == SDLK_DOWN then s with moving.1 = 0
      else s

  let move (x: i32, y: i32) (dx,dy) = (x+dx*10, y+dy*10)

  let step td (s: state) =
    s with time = td + s.time with center = move s.center s.moving

  let render (s: state) =
    tabulate_2d (s.h) (s.w)
                (\i j ->
                   let (i', j') = rotate_point (r32 (i-s.center.1)) (r32 (j-s.center.2)) s.time
                   in if i'**2 + j'**2 < 200 then argb.white
                      else if i' > j' then argb.red else argb.blue)
}
