Color :: union {
    rgba: [4] u8;
    struct {
        r,g,b,a: u8;
    };
}

COLOR_TRANSPARENT :: Color.{ r = 0, g = 0, b = 0, a = 0 };
COLOR_WHITE       :: Color.{ r = 255, g = 255, b = 255, a = 255 };
COLOR_BLACK       :: Color.{ r = 0, g = 0, b = 0, a = 255 };
COLOR_RED         :: Color.{ r = 199, g = 0, b = 0, a = 255 };
COLOR_GREEN       :: Color.{ r = 0, g = 199, b = 0, a = 255 };
COLOR_BLUE        :: Color.{ r = 0, g = 0, b = 199, a = 255 };
COLOR_YELLOW      :: Color.{ r = 199, g = 199, b = 0, a = 255 };

rgba :: inline (r: u8, g: u8, b: u8, a: u8) -> Color {
    color: Color = ---;
    color.r = r;
    color.g = g;
    color.b = b;
    color.a = a;
    return color;
}

rgb :: inline (r: u8, g: u8, b: u8) -> Color {
    return rgba(r, g, b, 255);
}
