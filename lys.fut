import "lib/github.com/diku-dk/lys/lys"

let rotate_point (x: f32) (y: f32) (angle: f32) =
  let s = f32.sin angle
  let c = f32.cos angle
  let xnew = x * c - y * s
  let ynew = x * s + y * c
  in (xnew, ynew)

type state = {time: f32, h: i32, w: i32, center: (i32, i32)}

entry init (h: i32) (w: i32): state = {time = 0, w, h, center=(h/2,w/2)}

entry resize (h: i32) (w: i32) (s: state): state =
  s with h = h with w = w with center = (h/2,w/2)

entry step td (s: state): state =
  s with time = td + s.time

entry render ({time,w,h,center=(x,y)}: state) =
  tabulate_2d h w (\i j ->
                     let (i', j') = rotate_point (r32 (i-x)) (r32 (j-y)) time
                     in if i' > j' then argb.red else argb.blue)
