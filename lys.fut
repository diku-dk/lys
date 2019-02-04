import "lib/github.com/diku-dk/lys/lys"

let rotate_point (x: f32) (y: f32) (angle: f32) =
  let s = f32.sin angle
  let c = f32.cos angle
  let xnew = x * c - y * s
  let ynew = x * s + y * c
  in (xnew, ynew)

type state = {time: f32}

entry init: state = {time = 0}

entry step td ({time=t}: state): state =
  {time = td + t}

entry render ({time=t}: state) h w =
  tabulate_2d h w (\i j ->
                     let (i', j') = rotate_point (r32 (i-h/2)) (r32 (j-w/2)) t
                     in if i' > j' then argb.red else argb.blue)
