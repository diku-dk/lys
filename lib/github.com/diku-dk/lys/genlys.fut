module m = import "lys"

type state = m.lys.state

entry init (h: i32) (w: i32): state = m.lys.init h w

entry resize (h: i32) (w: i32) (s: state): state = m.lys.resize h w s

entry keypress (key: i32) (s: state): state = m.lys.keypress key s

entry step (td: f32) (s: state): state = m.lys.step td s

entry render (s: state) = m.lys.render s
