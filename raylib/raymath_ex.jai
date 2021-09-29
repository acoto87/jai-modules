Vector2Create :: inline (x: float32, y: float32) -> Vector2 {
    v: Vector2 = ---;
    v.x = x;
    v.y = y;
    return v;
}

Vector3Create :: inline (x: float32, y: float32, z: float32) -> Vector3 {
    v: Vector3 = ---;
    v.x = x;
    v.y = y;
    v.z = z;
    return v;
}

Vector4Create :: inline (x: float32, y: float32, z: float32, w: float32) -> Vector4 {
    v: Vector4 = ---;
    v.x = x;
    v.y = y;
    v.z = z;
    v.w = w;
    return v;
}

BoundingBoxCreate :: inline (min: Vector3, max: Vector3) -> BoundingBox {
    bb: BoundingBox = ---;
    bb.min = min;
    bb.max = max;
    return bb;
}

RectangleCreate :: inline (x: float32, y: float32, width: float32, height: float32) -> Rectangle {
    r: Rectangle = ---;
    r.x = x;
    r.y = y;
    r.width = width;
    r.height = height;
    return r;
}

RectangleCreateV :: inline (topLeft: Vector2, size: Vector2) -> Rectangle {
    return RectangleCreate(topLeft.x, topLeft.y, size.x, size.y);
}

ColorCreate :: inline (r: u8, g: u8, b: u8, a: u8) -> Color {
    c: Color = ---;
    c.r = r;
    c.g = g;
    c.b = b;
    c.a = a;
    return c;
}
