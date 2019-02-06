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

  -- | Something happened to the mouse.
  val mouse : (mouse_state: i32) -> (x: i32) -> (y: i32) -> state -> state

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
  let mouse _ _ _ s = s
  let render {h,w} = replicate w argb.black |> replicate h
}

module mk_lys (m: lys): lys = {
    open m
}

type keycode = i32

-- We should generate the following programmatically.

local let scancode (x: i32) = x | (1<<30)

-- The following values are taken from
-- https://wiki.libsdl.org/SDLScancodeLookup

let SDLK_UNKNOWN = scancode 0x000
let SDLK_A = scancode 0x004
let SDLK_B = scancode 0x005
let SDLK_C = scancode 0x006
let SDLK_D = scancode 0x007
let SDLK_E = scancode 0x008
let SDLK_F = scancode 0x009
let SDLK_G = scancode 0x00A
let SDLK_H = scancode 0x00B
let SDLK_I = scancode 0x00C
let SDLK_J = scancode 0x00D
let SDLK_K = scancode 0x00E
let SDLK_L = scancode 0x00F
let SDLK_M = scancode 0x010
let SDLK_N = scancode 0x011
let SDLK_O = scancode 0x012
let SDLK_P = scancode 0x013
let SDLK_Q = scancode 0x014
let SDLK_R = scancode 0x015
let SDLK_S = scancode 0x016
let SDLK_T = scancode 0x017
let SDLK_U = scancode 0x018
let SDLK_V = scancode 0x019
let SDLK_W = scancode 0x01A
let SDLK_X = scancode 0x01B
let SDLK_Y = scancode 0x01C
let SDLK_Z = scancode 0x01D
let SDLK_1 = scancode 0x01E
let SDLK_2 = scancode 0x01F
let SDLK_3 = scancode 0x020
let SDLK_4 = scancode 0x021
let SDLK_5 = scancode 0x022
let SDLK_6 = scancode 0x023
let SDLK_7 = scancode 0x024
let SDLK_8 = scancode 0x025
let SDLK_9 = scancode 0x026
let SDLK_0 = scancode 0x027
let SDLK_RETURN = scancode 0x028
let SDLK_ESCAPE = scancode 0x029
let SDLK_BACKSPACE = scancode 0x02A
let SDLK_TAB = scancode 0x02B
let SDLK_SPACE = scancode 0x02C
let SDLK_MINUS = scancode 0x02D
let SDLK_EQUALS = scancode 0x02E
let SDLK_LEFTBRACKET = scancode 0x02F
let SDLK_RIGHTBRACKET = scancode 0x030
let SDLK_BACKSLASH = scancode 0x031
let SDLK_NONUSHASH = scancode 0x032
let SDLK_SEMICOLON = scancode 0x033
let SDLK_APOSTROPHE = scancode 0x034
let SDLK_GRAVE = scancode 0x035
let SDLK_COMMA = scancode 0x036
let SDLK_PERIOD = scancode 0x037
let SDLK_SLASH = scancode 0x038
let SDLK_CAPSLOCK = scancode 0x039
let SDLK_F1 = scancode 0x03A
let SDLK_F2 = scancode 0x03B
let SDLK_F3 = scancode 0x03C
let SDLK_F4 = scancode 0x03D
let SDLK_F5 = scancode 0x03E
let SDLK_F6 = scancode 0x03F
let SDLK_F7 = scancode 0x040
let SDLK_F8 = scancode 0x041
let SDLK_F9 = scancode 0x042
let SDLK_F10 = scancode 0x043
let SDLK_F11 = scancode 0x044
let SDLK_F12 = scancode 0x045
let SDLK_PRINTSCREEN = scancode 0x046
let SDLK_SCROLLLOCK = scancode 0x047
let SDLK_PAUSE = scancode 0x048
let SDLK_INSERT = scancode 0x049
let SDLK_HOME = scancode 0x04A
let SDLK_PAGEUP = scancode 0x04B
let SDLK_DELETE = scancode 0x04C
let SDLK_END = scancode 0x04D
let SDLK_PAGEDOWN = scancode 0x04E
let SDLK_RIGHT = scancode 0x04F
let SDLK_LEFT = scancode 0x050
let SDLK_DOWN = scancode 0x051
let SDLK_UP = scancode 0x052
let SDLK_NUMLOCKCLEAR = scancode 0x053
let SDLK_KP_DIVIDE = scancode 0x054
let SDLK_KP_MULTIPLY = scancode 0x055
let SDLK_KP_MINUS = scancode 0x056
let SDLK_KP_PLUS = scancode 0x057
let SDLK_KP_ENTER = scancode 0x058
let SDLK_KP_1 = scancode 0x059
let SDLK_KP_2 = scancode 0x05A
let SDLK_KP_3 = scancode 0x05B
let SDLK_KP_4 = scancode 0x05C
let SDLK_KP_5 = scancode 0x05D
let SDLK_KP_6 = scancode 0x05E
let SDLK_KP_7 = scancode 0x05F
let SDLK_KP_8 = scancode 0x060
let SDLK_KP_9 = scancode 0x061
let SDLK_KP_0 = scancode 0x062
let SDLK_KP_PERIOD = scancode 0x063
let SDLK_NONUSBACKSLASH = scancode 0x064
let SDLK_APPLICATION = scancode 0x065
let SDLK_POWER = scancode 0x066
let SDLK_KP_EQUALS = scancode 0x067
let SDLK_F13 = scancode 0x068
let SDLK_F14 = scancode 0x069
let SDLK_F15 = scancode 0x06A
let SDLK_F16 = scancode 0x06B
let SDLK_F17 = scancode 0x06C
let SDLK_F18 = scancode 0x06D
let SDLK_F19 = scancode 0x06E
let SDLK_F20 = scancode 0x06F
let SDLK_F21 = scancode 0x070
let SDLK_F22 = scancode 0x071
let SDLK_F23 = scancode 0x072
let SDLK_F24 = scancode 0x073
let SDLK_EXECUTE = scancode 0x074
let SDLK_HELP = scancode 0x075
let SDLK_MENU = scancode 0x076
let SDLK_SELECT = scancode 0x077
let SDLK_STOP = scancode 0x078
let SDLK_AGAIN = scancode 0x079
let SDLK_UNDO = scancode 0x07A
let SDLK_CUT = scancode 0x07B
let SDLK_COPY = scancode 0x07C
let SDLK_PASTE = scancode 0x07D
let SDLK_FIND = scancode 0x07E
let SDLK_MUTE = scancode 0x07F
let SDLK_VOLUMEUP = scancode 0x080
let SDLK_VOLUMEDOWN = scancode 0x081
let SDLK_KP_COMMA = scancode 0x085
let SDLK_KP_EQUALSAS400 = scancode 0x086
let SDLK_INTERNATIONAL1 = scancode 0x087
let SDLK_INTERNATIONAL2 = scancode 0x088
let SDLK_INTERNATIONAL3 = scancode 0x089
let SDLK_INTERNATIONAL4 = scancode 0x08A
let SDLK_INTERNATIONAL5 = scancode 0x08B
let SDLK_INTERNATIONAL6 = scancode 0x08C
let SDLK_INTERNATIONAL7 = scancode 0x08D
let SDLK_INTERNATIONAL8 = scancode 0x08E
let SDLK_INTERNATIONAL9 = scancode 0x08F
let SDLK_LANG1 = scancode 0x090
let SDLK_LANG2 = scancode 0x091
let SDLK_LANG3 = scancode 0x092
let SDLK_LANG4 = scancode 0x093
let SDLK_LANG5 = scancode 0x094
let SDLK_LANG6 = scancode 0x095
let SDLK_LANG7 = scancode 0x096
let SDLK_LANG8 = scancode 0x097
let SDLK_LANG9 = scancode 0x098
let SDLK_ALTERASE = scancode 0x099
let SDLK_SYSREQ = scancode 0x09A
let SDLK_CANCEL = scancode 0x09B
let SDLK_CLEAR = scancode 0x09C
let SDLK_PRIOR = scancode 0x09D
let SDLK_RETURN2 = scancode 0x09E
let SDLK_SEPARATOR = scancode 0x09F
let SDLK_OUT = scancode 0x0A0
let SDLK_OPER = scancode 0x0A1
let SDLK_CLEARAGAIN = scancode 0x0A2
let SDLK_CRSEL = scancode 0x0A3
let SDLK_EXSEL = scancode 0x0A4
let SDLK_KP_00 = scancode 0x0B0
let SDLK_KP_000 = scancode 0x0B1
let SDLK_THOUSANDSSEPARATOR = scancode 0x0B2
let SDLK_DECIMALSEPARATOR = scancode 0x0B3
let SDLK_CURRENCYUNIT = scancode 0x0B4
let SDLK_CURRENCYSUBUNIT = scancode 0x0B5
let SDLK_KP_LEFTPAREN = scancode 0x0B6
let SDLK_KP_RIGHTPAREN = scancode 0x0B7
let SDLK_KP_LEFTBRACE = scancode 0x0B8
let SDLK_KP_RIGHTBRACE = scancode 0x0B9
let SDLK_KP_TAB = scancode 0x0BA
let SDLK_KP_BACKSPACE = scancode 0x0BB
let SDLK_KP_A = scancode 0x0BC
let SDLK_KP_B = scancode 0x0BD
let SDLK_KP_C = scancode 0x0BE
let SDLK_KP_D = scancode 0x0BF
let SDLK_KP_E = scancode 0x0C0
let SDLK_KP_F = scancode 0x0C1
let SDLK_KP_XOR = scancode 0x0C2
let SDLK_KP_POWER = scancode 0x0C3
let SDLK_KP_PERCENT = scancode 0x0C4
let SDLK_KP_LESS = scancode 0x0C5
let SDLK_KP_GREATER = scancode 0x0C6
let SDLK_KP_AMPERSAND = scancode 0x0C7
let SDLK_KP_DBLAMPERSAND = scancode 0x0C8
let SDLK_KP_VERTICALBAR = scancode 0x0C9
let SDLK_KP_DBLVERTICALBAR = scancode 0x0CA
let SDLK_KP_COLON = scancode 0x0CB
let SDLK_KP_HASH = scancode 0x0CC
let SDLK_KP_SPACE = scancode 0x0CD
let SDLK_KP_AT = scancode 0x0CE
let SDLK_KP_EXCLAM = scancode 0x0CF
let SDLK_KP_MEMSTORE = scancode 0x0D0
let SDLK_KP_MEMRECALL = scancode 0x0D1
let SDLK_KP_MEMCLEAR = scancode 0x0D2
let SDLK_KP_MEMADD = scancode 0x0D3
let SDLK_KP_MEMSUBTRACT = scancode 0x0D4
let SDLK_KP_MEMMULTIPLY = scancode 0x0D5
let SDLK_KP_MEMDIVIDE = scancode 0x0D6
let SDLK_KP_PLUSMINUS = scancode 0x0D7
let SDLK_KP_CLEAR = scancode 0x0D8
let SDLK_KP_CLEARENTRY = scancode 0x0D9
let SDLK_KP_BINARY = scancode 0x0DA
let SDLK_KP_OCTAL = scancode 0x0DB
let SDLK_KP_DECIMAL = scancode 0x0DC
let SDLK_KP_HEXADECIMAL = scancode 0x0DD
let SDLK_LCTRL = scancode 0x0E0
let SDLK_LSHIFT = scancode 0x0E1
let SDLK_LALT = scancode 0x0E2
let SDLK_LGUI = scancode 0x0E3
let SDLK_RCTRL = scancode 0x0E4
let SDLK_RSHIFT = scancode 0x0E5
let SDLK_RALT = scancode 0x0E6
let SDLK_RGUI = scancode 0x0E7
let SDLK_MODE = scancode 0x101
let SDLK_AUDIONEXT = scancode 0x102
let SDLK_AUDIOPREV = scancode 0x103
let SDLK_AUDIOSTOP = scancode 0x104
let SDLK_AUDIOPLAY = scancode 0x105
let SDLK_AUDIOMUTE = scancode 0x106
let SDLK_MEDIASELECT = scancode 0x107
let SDLK_WWW = scancode 0x108
let SDLK_MAIL = scancode 0x109
let SDLK_CALCULATOR = scancode 0x10A
let SDLK_COMPUTER = scancode 0x10B
let SDLK_AC_SEARCH = scancode 0x10C
let SDLK_AC_HOME = scancode 0x10D
let SDLK_AC_BACK = scancode 0x10E
let SDLK_AC_FORWARD = scancode 0x10F
let SDLK_AC_STOP = scancode 0x110
let SDLK_AC_REFRESH = scancode 0x111
let SDLK_AC_BOOKMARKS = scancode 0x112
let SDLK_BRIGHTNESSDOWN = scancode 0x113
let SDLK_BRIGHTNESSUP = scancode 0x114
let SDLK_DISPLAYSWITCH = scancode 0x115
let SDLK_KBDILLUMTOGGLE = scancode 0x116
let SDLK_KBDILLUMDOWN = scancode 0x117
let SDLK_KBDILLUMUP = scancode 0x118
let SDLK_EJECT = scancode 0x119
let SDLK_SLEEP = scancode 0x11A
let SDLK_APP1 = scancode 0x11B
let SDLK_APP2 = scancode 0x11C
