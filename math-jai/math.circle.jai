Circle :: struct {
    x, y, r: float32;
}

circle :: inline (x: float32, y: float32, r: float32) -> Circle {
    c: Circle = ---;
    c.x = x;
    c.y = y;
    c.r = r;
    return c;
}

circle :: inline (x: s32, y: s32, r: s32) -> Circle {
    return circle(cast(float32) x, cast(float32) y, cast(float32) r);
}

contains :: inline (c: Circle, x: float32, y: float32) -> bool {
    dx := c.x - x;
    dy := c.y - y;
    return dx * dx + dy * dy <= c.r * c.r;
}

intersects :: inline (c1: Circle, c2: Circle) -> bool {
    dx := c1.x - c2.x;
    dy := c1.y - c2.y;
    dr := c1.r + c2.r;
    return dx * dx + dy * dy <= dr * dr;
}

intersects :: inline (c: Circle, r: Rect) -> bool {
    return intersects(r, c);
}
