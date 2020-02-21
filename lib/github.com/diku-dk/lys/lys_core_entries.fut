-- | ignore

import "lys"

-- | Generate entry points for the core subset of Lys.  Useful for applications
-- that use Lys as a library and not an all-in-one solution.  You need precisely
-- these six entry points for Lys' SDL loop to work.
module lys_core_entries (m: lys_core) = {
  entry resize (h: i32) (w: i32) (s: m.state): m.state =
    m.resize h w s

  entry key (e: i32) (key: i32) (s: m.state): m.state =
    let e' = if e == 0 then #keydown {key} else #keyup {key}
    in m.event e' s

  entry mouse (buttons: i32) (x: i32) (y: i32) (s: m.state): m.state =
    m.event (#mouse {buttons, x, y}) s

  entry wheel (dx: i32) (dy: i32) (s: m.state): m.state =
    m.event (#wheel {dx, dy}) s

  entry step (td: f32) (s: m.state): m.state =
    m.event (#step td) s

  entry render (s: m.state) =
    m.render s
}
