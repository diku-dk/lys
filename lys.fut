import "lib/github.com/athas/matte/colour"

entry render (h: i32) (w: i32): [h][w]argb.colour =
  tabulate_2d h w (\i j -> if i > j then argb.red else argb.blue)
