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

getColorFromList :: (index: s64) -> Color {
    rgb := colors[index % colors.count];

    color: Color = ---;
	color.r = cast(u8) ((rgb >> 16) & 0xFF);
	color.g = cast(u8) ((rgb >>  8) & 0xFF);
	color.b = cast(u8) ((rgb >>  0) & 0xFF);
	color.a = 255;
	return color;
}

#scope_file

colors: [] u32 = .[
    0xE52B50, // Amaranth
    0xFFBF00, // Amber
    0x9966CC, // Amethyst
    0xFBCEB1, // Apricot
    0x7FFFD4, // Aquamarine
    0x007FFF, // Azure
    0x89CFF0, // Baby blue
    0xF5F5DC, // Beige
    0x000000, // Black
    0x0000FF, // Blue
    0x0095B6, // Blue-green
    0x8A2BE2, // Blue-violet
    0xDE5D83, // Blush
    0xCD7F32, // Bronze
    0x964B00, // Brown
    0x800020, // Burgundy
    0x702963, // Byzantium
    0x960018, // Carmine
    0xDE3163, // Cerise
    0x007BA7, // Cerulean
    0xF7E7CE, // Champagne
    0x7FFF00, // Chartreuse green
    0x7B3F00, // Chocolate
    0x0047AB, // Cobalt blue
    0x6F4E37, // Coffee
    0xB87333, // Copper
    0xF88379, // Coral
    0xDC143C, // Crimson
    0x00FFFF, // Cyan
    0xEDC9AF, // Desert sand
    0x7DF9FF, // Electric blue
    0x50C878, // Emerald
    0x00FF3F, // Erin
    0xFFD700, // Gold
    0x808080, // Gray
    0x00FF00, // Green
    0x3FFF00, // Harlequin
    0x4B0082, // Indigo
    0xFFFFF0, // Ivory
    0x00A86B, // Jade
    0x29AB87, // Jungle green
    0xB57EDC, // Lavender
    0xFFF700, // Lemon
    0xC8A2C8, // Lilac
    0xBFFF00, // Lime
    0xFF00FF, // Magenta
    0xFF00AF, // Magenta rose
    0x800000, // Maroon
    0xE0B0FF, // Mauve
    0x000080, // Navy blue
    0xCC7722, // Ocher
    0x808000, // Olive
    0xFFA500, // Orange
    0xFF4500, // Orange-red
    0xDA70D6, // Orchid
    0xFFE5B4, // Peach
    0xD1E231, // Pear
    0xCCCCFF, // Periwinkle
    0x1C39BB, // Persian blue
    0xFFC0CB, // Pink
    0x8E4585, // Plum
    0x003153, // Prussian blue
    0xCC8899, // Puce
    0x800080, // Purple
    0xE30B5C, // Raspberry
    0xFF0000, // Red
    0xC71585, // Red-violet
    0xFF007F, // Rose
    0xE0115F, // Ruby
    0xFA8072, // Salmon
    0x92000A, // Sangria
    0x0F52BA, // Sapphire
    0xFF2400, // Scarlet
    0xC0C0C0, // Silver
    0x708090, // Slate gray
    0xA7FC00, // Spring bud
    0x00FF7F, // Spring green
    0xD2B48C, // Tan
    0x483C32, // Taupe
    0x008080, // Teal
    0x40E0D0, // Turquoise
    0xEE82EE, // Violet
    0x40826D, // Viridian
    0xFFFFFF, // White
    0xFFFF00, // Yellow
];
