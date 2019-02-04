-- | Lights, camera, action!

-- | For convenience, re-export the colour module.
open import "../../athas/matte/colour"

-- The type that an entry point should have.
type entry_render = (t: f32) -> (h: i32) -> (w: i32) -> [h][w]argb.colour
