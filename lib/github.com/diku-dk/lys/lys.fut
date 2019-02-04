-- | Lights, camera, action!

-- | For convenience, re-export the colour module.
open import "../../athas/matte/colour"

-- | Initial state for a given window size.
type entry_init 'state = (h: i32) -> (w: i32) -> state

-- | Time-stepping the state.
type entry_step 'state = (time_delta: f32) -> state -> state

-- | The window was resized.
type entry_resize 'state = (h: i32) -> (w: i32) -> state -> state

-- | Someone pressed a key!
type entry_keypress 'state = i32 -> state -> state

-- | The function for rendering a screen image in row-major order
-- (height by width).  The size of the array returned must match the
-- last dimensions provided to the state (via `entry_init`@term or
-- `entry_resize`@term).
type entry_render 'state = state -> [][]argb.colour

type keycode = i32

-- We should generate the following programmatically.
let SDLK_RIGHT: keycode = 0x04F | (1<<30)
let SDLK_LEFT: keycode = 0x050 | (1<<30)
let SDLK_DOWN: keycode = 0x051 | (1<<30)
let SDLK_UP: keycode = 0x052 | (1<<30)
