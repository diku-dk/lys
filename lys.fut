import "lib/github.com/athas/matte/colour"

let rotate_point (x: f32) (y: f32) (angle: f32) =
  let s = f32.sin angle
  let c = f32.cos angle
  let xnew = x * c - y * s
  let ynew = x * s + y * c
  in (xnew, ynew)

entry render (t: f32) (h: i32) (w: i32): [h][w]argb.colour =
  tabulate_2d h w (\i j ->
                     let (i', j') = rotate_point (r32 (i-h/2)) (r32 (j-w/2)) t
                     in if i' > j' then argb.red else argb.blue)
