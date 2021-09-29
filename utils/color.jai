Color :: union {
    rgba: s32;
    values: [4] u8;
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

fromRgbInt :: inline (rgb: s32) -> Color {
    color: Color = ---;
	color.r = cast(u8) ((rgb >> 16) & 0xFF);
	color.g = cast(u8) ((rgb >>  8) & 0xFF);
	color.b = cast(u8) ((rgb >>  0) & 0xFF);
	color.a = 255;
	return color;
}

fromRgbaInt :: inline (rgba: s32) -> Color {
    color: Color = ---;
	color.r = cast(u8) ((rgb >> 24) & 0xFF);
	color.g = cast(u8) ((rgb >> 16) & 0xFF);
	color.b = cast(u8) ((rgb >>  8) & 0xFF);
	color.a = cast(u8) ((rgb >>  0) & 0xFF);
	return color;
}

fromNamedColor :: inline (namedColor: NamedColor) -> Color {
    return fromRgbInt(cast(s32) namedColor);
}

getColorFromList :: (index: s64) -> Color {
    rgb := colors[index % colors.count];
    return fromRgbInt(rgb);
}

equals :: inline (c1: Color, c2: Color) -> bool {
    return c1.r == c2.r && c1.g == c2.g && c1.b == c2.b && c1.a == c2.a;
}

compare :: inline (c1: Color, c2: Color) -> s64 {
    return cast(s64) c1.rgba - cast(s64) c2.rgba;
}

NamedColor :: enum s32 {
    Amaranth :: 0xE52B50;
    Amber :: 0xFFBF00;
    Amethyst :: 0x9966CC;
    Apricot :: 0xFBCEB1;
    Aquamarine :: 0x7FFFD4;
    Azure :: 0x007FFF;
    BabyBlue :: 0x89CFF0;
    Beige :: 0xF5F5DC;
    Black :: 0x000000;
    Blue :: 0x0000FF;
    BlueGreen :: 0x0095B6;
    BlueViolet :: 0x8A2BE2;
    Blush :: 0xDE5D83;
    Bronze :: 0xCD7F32;
    Brown :: 0x964B00;
    Burgundy :: 0x800020;
    Byzantium :: 0x702963;
    Carmine :: 0x960018;
    Cerise :: 0xDE3163;
    Cerulean :: 0x007BA7;
    Champagne :: 0xF7E7CE;
    ChartreuseGreen :: 0x7FFF00;
    Chocolate :: 0x7B3F00;
    CobaltBlue :: 0x0047AB;
    Coffee :: 0x6F4E37;
    Copper :: 0xB87333;
    Coral :: 0xF88379;
    Crimson :: 0xDC143C;
    Cyan :: 0x00FFFF;
    DesertSand :: 0xEDC9AF;
    ElectricBlue :: 0x7DF9FF;
    Emerald :: 0x50C878;
    Erin :: 0x00FF3F;
    Gold :: 0xFFD700;
    Gray :: 0x808080;
    Green :: 0x00FF00;
    Harlequin :: 0x3FFF00;
    Indigo :: 0x4B0082;
    Ivory :: 0xFFFFF0;
    Jade :: 0x00A86B;
    JungleGreen :: 0x29AB87;
    Lavender :: 0xB57EDC;
    Lemon :: 0xFFF700;
    Lilac :: 0xC8A2C8;
    Lime :: 0xBFFF00;
    Magenta :: 0xFF00FF;
    MagentaRose :: 0xFF00AF;
    Maroon :: 0x800000;
    Mauve :: 0xE0B0FF;
    NavyBlue :: 0x000080;
    Ocher :: 0xCC7722;
    Olive :: 0x808000;
    Orange :: 0xFFA500;
    OrangeRed :: 0xFF4500;
    Orchid :: 0xDA70D6;
    Peach :: 0xFFE5B4;
    Pear :: 0xD1E231;
    Periwinkle :: 0xCCCCFF;
    PersianBlue :: 0x1C39BB;
    Pink :: 0xFFC0CB;
    Plum :: 0x8E4585;
    PrussianBlue :: 0x003153;
    Puce :: 0xCC8899;
    Purple :: 0x800080;
    Raspberry :: 0xE30B5C;
    Red :: 0xFF0000;
    RedViolet :: 0xC71585;
    Rose :: 0xFF007F;
    Ruby :: 0xE0115F;
    Salmon :: 0xFA8072;
    Sangria :: 0x92000A;
    Sapphire :: 0x0F52BA;
    Scarlet :: 0xFF2400;
    Silver :: 0xC0C0C0;
    SlateGray :: 0x708090;
    SpringBud :: 0xA7FC00;
    SpringGreen :: 0x00FF7F;
    Tan :: 0xD2B48C;
    Taupe :: 0x483C32;
    Teal :: 0x008080;
    Turquoise :: 0x40E0D0;
    Violet :: 0xEE82EE;
    Viridian :: 0x40826D;
    White :: 0xFFFFFF;
    Yellow :: 0xFFFF00;
}

#scope_file

colors: [] s32 = .[
    cast(s32) NamedColor.Amaranth,
    cast(s32) NamedColor.Amber,
    cast(s32) NamedColor.Amethyst,
    cast(s32) NamedColor.Apricot,
    cast(s32) NamedColor.Aquamarine,
    cast(s32) NamedColor.Azure,
    cast(s32) NamedColor.BabyBlue,
    cast(s32) NamedColor.Beige,
    cast(s32) NamedColor.Black,
    cast(s32) NamedColor.Blue,
    cast(s32) NamedColor.BlueGreen,
    cast(s32) NamedColor.BlueViolet,
    cast(s32) NamedColor.Blush,
    cast(s32) NamedColor.Bronze,
    cast(s32) NamedColor.Brown,
    cast(s32) NamedColor.Burgundy,
    cast(s32) NamedColor.Byzantium,
    cast(s32) NamedColor.Carmine,
    cast(s32) NamedColor.Cerise,
    cast(s32) NamedColor.Cerulean,
    cast(s32) NamedColor.Champagne,
    cast(s32) NamedColor.ChartreuseGreen,
    cast(s32) NamedColor.Chocolate,
    cast(s32) NamedColor.CobaltBlue,
    cast(s32) NamedColor.Coffee,
    cast(s32) NamedColor.Copper,
    cast(s32) NamedColor.Coral,
    cast(s32) NamedColor.Crimson,
    cast(s32) NamedColor.Cyan,
    cast(s32) NamedColor.DesertSand,
    cast(s32) NamedColor.ElectricBlue,
    cast(s32) NamedColor.Emerald,
    cast(s32) NamedColor.Erin,
    cast(s32) NamedColor.Gold,
    cast(s32) NamedColor.Gray,
    cast(s32) NamedColor.Green,
    cast(s32) NamedColor.Harlequin,
    cast(s32) NamedColor.Indigo,
    cast(s32) NamedColor.Ivory,
    cast(s32) NamedColor.Jade,
    cast(s32) NamedColor.JungleGreen,
    cast(s32) NamedColor.Lavender,
    cast(s32) NamedColor.Lemon,
    cast(s32) NamedColor.Lilac,
    cast(s32) NamedColor.Lime,
    cast(s32) NamedColor.Magenta,
    cast(s32) NamedColor.MagentaRose,
    cast(s32) NamedColor.Maroon,
    cast(s32) NamedColor.Mauve,
    cast(s32) NamedColor.NavyBlue,
    cast(s32) NamedColor.Ocher,
    cast(s32) NamedColor.Olive,
    cast(s32) NamedColor.Orange,
    cast(s32) NamedColor.OrangeRed,
    cast(s32) NamedColor.Orchid,
    cast(s32) NamedColor.Peach,
    cast(s32) NamedColor.Pear,
    cast(s32) NamedColor.Periwinkle,
    cast(s32) NamedColor.PersianBlue,
    cast(s32) NamedColor.Pink,
    cast(s32) NamedColor.Plum,
    cast(s32) NamedColor.PrussianBlue,
    cast(s32) NamedColor.Puce,
    cast(s32) NamedColor.Purple,
    cast(s32) NamedColor.Raspberry,
    cast(s32) NamedColor.Red,
    cast(s32) NamedColor.RedViolet,
    cast(s32) NamedColor.Rose,
    cast(s32) NamedColor.Ruby,
    cast(s32) NamedColor.Salmon,
    cast(s32) NamedColor.Sangria,
    cast(s32) NamedColor.Sapphire,
    cast(s32) NamedColor.Scarlet,
    cast(s32) NamedColor.Silver,
    cast(s32) NamedColor.SlateGray,
    cast(s32) NamedColor.SpringBud,
    cast(s32) NamedColor.SpringGreen,
    cast(s32) NamedColor.Tan,
    cast(s32) NamedColor.Taupe,
    cast(s32) NamedColor.Teal,
    cast(s32) NamedColor.Turquoise,
    cast(s32) NamedColor.Violet,
    cast(s32) NamedColor.Viridian,
    cast(s32) NamedColor.White,
    cast(s32) NamedColor.Yellow,
];
