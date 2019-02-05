-- | Lights, camera, action!

-- | For convenience, re-export the colour module.
open import "../../athas/matte/colour"

type key_event = #keydown | #keyup

module type lys = {
  type state

  -- | Initial state for a given window size.
  val init : (h: i32) -> (w: i32) -> state

  -- | Time-stepping the state.
  val step : (time_delta: f32) -> state -> state

  -- | The window was resized.
  val resize : (h: i32) -> (w: i32) -> state -> state

  -- | Something happened to the keyboard.
  val key : key_event -> i32 -> state -> state

  -- | The function for rendering a screen image in row-major order
  -- (height by width).  The size of the array returned must match the
  -- last dimensions provided to the state (via `init`@term or
  -- `resize`@term).
  val render : state -> [][]argb.colour
}

-- | A dummy lys module that just produces a black rectangle and does
-- nothing in response to events.
module lys: lys = {
  type state = {h: i32, w: i32}
  let init h w: state = {h,w}
  let step _ s: state = s
  let resize h w _: state = {h,w}
  let key _ _ s: state = s
  let render {h,w} = replicate w argb.black |> replicate h
}

module mk_lys (m: lys): lys = {
    open m
}

type keycode = i32

-- We should generate the following programmatically.
let SDLK_RIGHT: keycode = 0x04F | (1<<30)
let SDLK_LEFT: keycode = 0x050 | (1<<30)
let SDLK_DOWN: keycode = 0x051 | (1<<30)
let SDLK_UP: keycode = 0x052 | (1<<30)
