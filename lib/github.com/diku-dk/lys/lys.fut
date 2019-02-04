-- | Lights, camera, action!

-- | For convenience, re-export the colour module.
open import "../../athas/matte/colour"

-- | Time-stepping the state.
type entry_step 'state = (time_delta: f32) -> state -> state

-- | The function for rendering a screen image.
type entry_render 'state = state -> (h: i32) -> (w: i32) -> [h][w]argb.colour
