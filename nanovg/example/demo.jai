#import "stb_image_write";

DemoData :: struct {
    fontNormal, fontBold, fontIcons, fontEmoji: s32;
    images: [12] s32;
}

ICON_SEARCH        :: 0x1F50D;
ICON_CIRCLED_CROSS :: 0x2716;
ICON_CHEVRON_RIGHT :: 0xE75E;
ICON_CHECK         :: 0x2713;
ICON_LOGIN         :: 0xE740;
ICON_TRASH         :: 0xE729;

isBlack :: (col: NVGcolor) -> bool {
    return col.r == 0.0 && col.g == 0.0 && col.b == 0.0 && col.a == 0.0;
}

cpToUTF8 :: (cp: s32, str: *u8) -> *u8 {
    n: s32 = 0;
    if (cp < 0x80) n = 1;
    else if (cp < 0x800) n = 2;
    else if (cp < 0x10000) n = 3;
    else if (cp < 0x200000) n = 4;
    else if (cp < 0x4000000) n = 5;
    else if (cp <= 0x7fffffff) n = 6;
    str[n] = #char "\0";
    if n == {
        case 6; str[5] = cast(u8)(0x80 | (cp & 0x3f)); cp = cp >> 6; cp |= 0x4000000; #through;
        case 5; str[4] = cast(u8)(0x80 | (cp & 0x3f)); cp = cp >> 6; cp |= 0x200000; #through;
        case 4; str[3] = cast(u8)(0x80 | (cp & 0x3f)); cp = cp >> 6; cp |= 0x10000; #through;
        case 3; str[2] = cast(u8)(0x80 | (cp & 0x3f)); cp = cp >> 6; cp |= 0x800; #through;
        case 2; str[1] = cast(u8)(0x80 | (cp & 0x3f)); cp = cp >> 6; cp |= 0xc0; #through;
        case 1; str[0] = cast(u8)cp; #through;
    }
    return str;
}

drawWindow :: (vg: *NVGcontext, title: *u8, x: f32, y: f32, w: f32, h: f32) {
    cornerRadius: f32 = 3.0;
    shadowPaint: NVGpaint;
    headerPaint: NVGpaint;

    nvgSave(vg);
    // nvgClearState(vg);

    // Window
    nvgBeginPath(vg);
    nvgRoundedRect(vg, x, y, w, h, cornerRadius);
    nvgFillColor(vg, nvgRGBA(28,30,34,192));
    // nvgFillColor(vg, nvgRGBA(0, 0, 0,128));
    nvgFill(vg);

    // Drop shadow
    shadowPaint = nvgBoxGradient(vg, x, y + 2, w, h, cornerRadius*2, 10, nvgRGBA(0, 0, 0,128), nvgRGBA(0, 0, 0, 0));
    nvgBeginPath(vg);
    nvgRect(vg, x-10, y-10, w+20, h+30);
    nvgRoundedRect(vg, x, y, w, h, cornerRadius);
    nvgPathWinding(vg, .NVG_CW);
    nvgFillPaint(vg, shadowPaint);
    nvgFill(vg);

    // Header
    headerPaint = nvgLinearGradient(vg, x, y, x, y+15, nvgRGBA(255,255,255, 8), nvgRGBA(0, 0, 0,16));
    nvgBeginPath(vg);
    nvgRoundedRect(vg, x + 1, y + 1, w - 2,30, cornerRadius-1);
    nvgFillPaint(vg, headerPaint);
    nvgFill(vg);
    nvgBeginPath(vg);
    nvgMoveTo(vg, x + 0.5, y + 0.5+30);
    nvgLineTo(vg, x + 0.5 + w - 1, y + 0.5+30);
    nvgStrokeColor(vg, nvgRGBA(0, 0, 0,32));
    nvgStroke(vg);

    nvgFontSize(vg, 15.0);
    nvgFontFace(vg, "sans-bold");
    nvgTextAlign(vg, NVGalign.NVG_ALIGN_CENTER | .NVG_ALIGN_MIDDLE);

    nvgFontBlur(vg, 2);
    nvgFillColor(vg, nvgRGBA(0, 0, 0,128));
    nvgText(vg, x + w / 2, y + 16 + 1, title, null);

    nvgFontBlur(vg, 0);
    nvgFillColor(vg, nvgRGBA(220,220,220,160));
    nvgText(vg, x + w/2, y + 16, title, null);

    nvgRestore(vg);
}

drawSearchBox :: (vg: *NVGcontext, text: *u8, x: f32, y: f32, w: f32, h: f32) {
    icon: [8] u8;
    cornerRadius := h/2 - 1;

    // Edit
    bg := nvgBoxGradient(vg, x, y + 1.5, w, h, h/2, 5, nvgRGBA(0, 0, 0,16), nvgRGBA(0, 0, 0,92));
    nvgBeginPath(vg);
    nvgRoundedRect(vg, x, y, w, h, cornerRadius);
    nvgFillPaint(vg, bg);
    nvgFill(vg);

/*    nvgBeginPath(vg);
    nvgRoundedRect(vg, x + 0.5, y + 0.5, w - 1, h - 1, cornerRadius-0.5);
    nvgStrokeColor(vg, nvgRGBA(0, 0, 0,48));
    nvgStroke(vg);*/

    s := cpToUTF8(ICON_SEARCH,icon.data);
    for k : 0..strlen(s)-1 {
        print("% = %\n", k, s[k]);
    }

    nvgFontSize(vg, h * 1.3);
    nvgFontFace(vg, "icons");
    nvgFillColor(vg, nvgRGBA(255,255,255,64));
    nvgTextAlign(vg, NVGalign.NVG_ALIGN_CENTER | .NVG_ALIGN_MIDDLE);
    nvgText(vg, x + h * 0.55, y + h * 0.55, s, null);

    nvgFontSize(vg, 17.0);
    nvgFontFace(vg, "sans");
    nvgFillColor(vg, nvgRGBA(255,255,255,32));

    nvgTextAlign(vg, NVGalign.NVG_ALIGN_LEFT | .NVG_ALIGN_MIDDLE);
    nvgText(vg, x + h * 1.05, y + h * 0.5,text, null);

    nvgFontSize(vg, h * 1.3);
    nvgFontFace(vg, "icons");
    nvgFillColor(vg, nvgRGBA(255,255,255,32));
    nvgTextAlign(vg, NVGalign.NVG_ALIGN_CENTER | .NVG_ALIGN_MIDDLE);
    nvgText(vg, x + w - h * 0.55, y + h * 0.55, cpToUTF8(ICON_CIRCLED_CROSS, icon.data), null);
}

drawDropDown :: (vg: *NVGcontext, text: *u8, x: f32, y: f32, w: f32, h: f32) {
    icon: [8] u8;
    cornerRadius := 4.0;

    bg := nvgLinearGradient(vg, x, y, x, y + h, nvgRGBA(255,255,255,16), nvgRGBA(0, 0, 0,16));
    nvgBeginPath(vg);
    nvgRoundedRect(vg, x + 1, y + 1, w - 2, h - 2, cornerRadius-1);
    nvgFillPaint(vg, bg);
    nvgFill(vg);

    nvgBeginPath(vg);
    nvgRoundedRect(vg, x + 0.5, y + 0.5, w - 1, h - 1, cornerRadius-0.5);
    nvgStrokeColor(vg, nvgRGBA(0, 0, 0,48));
    nvgStroke(vg);

    nvgFontSize(vg, 17.0);
    nvgFontFace(vg, "sans");
    nvgFillColor(vg, nvgRGBA(255,255,255,160));
    nvgTextAlign(vg, NVGalign.NVG_ALIGN_LEFT | .NVG_ALIGN_MIDDLE);
    nvgText(vg, x + h * 0.3, y + h * 0.5,text, null);

    nvgFontSize(vg, h * 1.3);
    nvgFontFace(vg, "icons");
    nvgFillColor(vg, nvgRGBA(255,255,255,64));
    nvgTextAlign(vg, NVGalign.NVG_ALIGN_CENTER | .NVG_ALIGN_MIDDLE);
    nvgText(vg, x + w - h * 0.5, y + h * 0.5, cpToUTF8(ICON_CHEVRON_RIGHT,icon.data), null);
}

drawLabel :: (vg: *NVGcontext, text: *u8, x: f32, y: f32, w: f32, h: f32) {
    nvgFontSize(vg, 15.0);
    nvgFontFace(vg, "sans");
    nvgFillColor(vg, nvgRGBA(255,255,255,128));

    nvgTextAlign(vg, NVGalign.NVG_ALIGN_LEFT | .NVG_ALIGN_MIDDLE);
    nvgText(vg, x, y + h * 0.5,text, null);
}

drawEditBoxBase :: (vg: *NVGcontext, x: f32, y: f32, w: f32, h: f32) {
    // Edit
    bg := nvgBoxGradient(vg, x + 1, y + 1 + 1.5, w - 2, h - 2, 3, 4, nvgRGBA(255,255,255,32), nvgRGBA(32,32,32,32));
    nvgBeginPath(vg);
    nvgRoundedRect(vg, x + 1, y + 1, w - 2, h - 2, 4 - 1);
    nvgFillPaint(vg, bg);
    nvgFill(vg);

    nvgBeginPath(vg);
    nvgRoundedRect(vg, x + 0.5, y + 0.5, w - 1, h - 1, 4 - 0.5);
    nvgStrokeColor(vg, nvgRGBA(0, 0, 0,48));
    nvgStroke(vg);
}

drawEditBox :: (vg: *NVGcontext, text: *u8, x: f32, y: f32, w: f32, h: f32) {
    drawEditBoxBase(vg, x, y, w, h);

    nvgFontSize(vg, 17.0);
    nvgFontFace(vg, "sans");
    nvgFillColor(vg, nvgRGBA(255,255,255,64));
    nvgTextAlign(vg,NVGalign.NVG_ALIGN_LEFT | .NVG_ALIGN_MIDDLE);
    nvgText(vg, x + h * 0.3, y + h * 0.5,text, null);
}

drawEditBoxNum :: (vg: *NVGcontext, text: *u8, units: *u8, x: f32, y: f32, w: f32, h: f32) {
    drawEditBoxBase(vg, x, y, w, h);

    uw := nvgTextBounds(vg, 0, 0, units, null, null);

    nvgFontSize(vg, 15.0);
    nvgFontFace(vg, "sans");
    nvgFillColor(vg, nvgRGBA(255,255,255,64));
    nvgTextAlign(vg,NVGalign.NVG_ALIGN_RIGHT | .NVG_ALIGN_MIDDLE);
    nvgText(vg, x + w - h * 0.3, y + h * 0.5,units, null);

    nvgFontSize(vg, 17.0);
    nvgFontFace(vg, "sans");
    nvgFillColor(vg, nvgRGBA(255,255,255,128));
    nvgTextAlign(vg,NVGalign.NVG_ALIGN_RIGHT | .NVG_ALIGN_MIDDLE);
    nvgText(vg, x + w-uw-h * 0.5, y + h * 0.5,text, null);
}

drawCheckBox :: (vg: *NVGcontext, text: *u8, x: f32, y: f32, w: f32, h: f32) {
    icon: [8] u8;

    nvgFontSize(vg, 15.0);
    nvgFontFace(vg, "sans");
    nvgFillColor(vg, nvgRGBA(255,255,255,160));

    nvgTextAlign(vg, NVGalign.NVG_ALIGN_LEFT | .NVG_ALIGN_MIDDLE);
    nvgText(vg, x+28, y + h * 0.5,text, null);

    bg := nvgBoxGradient(vg, x + 1, y+cast(s32)(h * 0.5) - 9 + 1, 18,18, 3, 3, nvgRGBA(0, 0, 0,32), nvgRGBA(0, 0, 0,92));
    nvgBeginPath(vg);
    nvgRoundedRect(vg, x + 1, y+cast(s32)(h * 0.5) - 9, 18,18, 3);
    nvgFillPaint(vg, bg);
    nvgFill(vg);

    nvgFontSize(vg, 33);
    nvgFontFace(vg, "icons");
    nvgFillColor(vg, nvgRGBA(255,255,255,128));
    nvgTextAlign(vg, NVGalign.NVG_ALIGN_CENTER | .NVG_ALIGN_MIDDLE);
    nvgText(vg, x + 9 + 2, y + h * 0.5, cpToUTF8(ICON_CHECK,icon.data), null);
}

drawButton :: (vg: *NVGcontext, preicon: s32, text: *u8, x: f32, y: f32, w: f32, h: f32, col: NVGcolor) {
    icon: [8] u8;
    cornerRadius: f32 = 4.0;
    tw, iw: f32 = 0;

    a := cast(u8)(ifx isBlack(col) then 16 else 32);
    bg := nvgLinearGradient(vg, x, y, x, y + h, nvgRGBA(255,255,255, a), nvgRGBA(0, 0, 0, a));
    nvgBeginPath(vg);
    nvgRoundedRect(vg, x + 1, y + 1, w - 2, h - 2, cornerRadius-1);
    if (!isBlack(col)) {
        nvgFillColor(vg, col);
        nvgFill(vg);
    }
    nvgFillPaint(vg, bg);
    nvgFill(vg);

    nvgBeginPath(vg);
    nvgRoundedRect(vg, x + 0.5, y + 0.5, w - 1, h - 1, cornerRadius-0.5);
    nvgStrokeColor(vg, nvgRGBA(0, 0, 0,48));
    nvgStroke(vg);

    nvgFontSize(vg, 17.0);
    nvgFontFace(vg, "sans-bold");
    tw = nvgTextBounds(vg, 0, 0, text, null, null);
    if (preicon != 0) {
        nvgFontSize(vg, h * 1.3);
        nvgFontFace(vg, "icons");
        iw = nvgTextBounds(vg, 0, 0, cpToUTF8(preicon,icon.data), null, null);
        iw += h * 0.15;
    }

    if (preicon != 0) {
        nvgFontSize(vg, h * 1.3);
        nvgFontFace(vg, "icons");
        nvgFillColor(vg, nvgRGBA(255,255,255,96));
        nvgTextAlign(vg,NVGalign.NVG_ALIGN_LEFT | .NVG_ALIGN_MIDDLE);
        nvgText(vg, x + w * 0.5-tw*0.5-iw*0.75, y + h * 0.5, cpToUTF8(preicon,icon.data), null);
    }

    nvgFontSize(vg, 17.0);
    nvgFontFace(vg, "sans-bold");
    nvgTextAlign(vg,NVGalign.NVG_ALIGN_LEFT | .NVG_ALIGN_MIDDLE);
    nvgFillColor(vg, nvgRGBA(0, 0, 0,160));
    nvgText(vg, x + w * 0.5-tw*0.5+iw*0.25, y + h * 0.5 - 1,text, null);
    nvgFillColor(vg, nvgRGBA(255,255,255,160));
    nvgText(vg, x + w * 0.5-tw*0.5+iw*0.25, y + h * 0.5,text, null);
}

drawSlider :: (vg: *NVGcontext, pos: f32, x: f32, y: f32, w: f32, h: f32) {
    cy: f32 = y+cast(s32)(h * 0.5);
    kr: f32 = cast(f32) cast(s32) (h * 0.25);

    nvgSave(vg);
//    nvgClearState(vg);

    // Slot
    bg := nvgBoxGradient(vg, x,cy-2 + 1, w, 4, 2, 2, nvgRGBA(0, 0, 0,32), nvgRGBA(0, 0, 0,128));
    nvgBeginPath(vg);
    nvgRoundedRect(vg, x,cy-2, w, 4, 2);
    nvgFillPaint(vg, bg);
    nvgFill(vg);

    // Knob Shadow
    bg = nvgRadialGradient(vg, x+cast(s32)(pos*w),cy+1, kr-3,kr+3, nvgRGBA(0, 0, 0,64), nvgRGBA(0, 0, 0, 0));
    nvgBeginPath(vg);
    nvgRect(vg, x+cast(s32)(pos*w)-kr-5,cy-kr-5,kr*2 + 5 + 5,kr*2 + 5 + 5 + 3);
    nvgCircle(vg, x+cast(s32)(pos*w),cy, kr);
    nvgPathWinding(vg, .NVG_CW);
    nvgFillPaint(vg, bg);
    nvgFill(vg);

    // Knob
    knob := nvgLinearGradient(vg, x,cy-kr, x,cy+kr, nvgRGBA(255,255,255,16), nvgRGBA(0, 0, 0,16));
    nvgBeginPath(vg);
    nvgCircle(vg, x+cast(s32)(pos*w),cy, kr-1);
    nvgFillColor(vg, nvgRGBA(40,43,48,255));
    nvgFill(vg);
    nvgFillPaint(vg, knob);
    nvgFill(vg);

    nvgBeginPath(vg);
    nvgCircle(vg, x+cast(s32)(pos*w),cy, kr-0.5);
    nvgStrokeColor(vg, nvgRGBA(0, 0, 0,92));
    nvgStroke(vg);

    nvgRestore(vg);
}

drawEyes :: (vg: *NVGcontext, x: f32, y: f32, w: f32, h: f32, mx: f32, my: f32, t: f32) {
    ex := w * 0.23;
    ey := h * 0.5;
    lx := x + ex;
    ly := y + ey;
    rx := x + w - ex;
    ry := y + ey;
    br := min(ex, ey) * 0.5;
    blink := 1.0 - powf(sinf(t * 0.5), 200) * 0.8;

    bg := nvgLinearGradient(vg, x, y + h * 0.5, x + w * 0.1, y + h, nvgRGBA(0, 0, 0,32), nvgRGBA(0, 0, 0,16));
    nvgBeginPath(vg);
    nvgEllipse(vg, lx + 3.0, ly + 16.0, ex, ey);
    nvgEllipse(vg, rx + 3.0, ry + 16.0, ex, ey);
    nvgFillPaint(vg, bg);
    nvgFill(vg);

    bg = nvgLinearGradient(vg, x, y + h * 0.25, x + w * 0.1, y + h, nvgRGBA(220,220,220,255), nvgRGBA(128,128,128,255));
    nvgBeginPath(vg);
    nvgEllipse(vg, lx, ly, ex, ey);
    nvgEllipse(vg, rx, ry, ex, ey);
    nvgFillPaint(vg, bg);
    nvgFill(vg);

    dx := (mx - rx) / (ex * 10);
    dy := (my - ry) / (ey * 10);
    d := sqrtf(dx * dx + dy * dy);
    if (d > 1.0) {
        dx /= d;
        dy /= d;
    }
    dx *= ex * 0.4;
    dy *= ey * 0.5;
    nvgBeginPath(vg);
    nvgEllipse(vg, lx + dx, ly + dy + ey * 0.25 * (1 - blink), br, br * blink);
    nvgFillColor(vg, nvgRGBA(32,32,32,255));
    nvgFill(vg);

    dx = (mx - rx) / (ex * 10);
    dy = (my - ry) / (ey * 10);
    d = sqrtf(dx * dx + dy * dy);
    if (d > 1.0) {
        dx /= d;
        dy /= d;
    }
    dx *= ex * 0.4;
    dy *= ey * 0.5;
    nvgBeginPath(vg);
    nvgEllipse(vg, rx + dx, ry + dy + ey * 0.25 * (1 - blink), br, br * blink);
    nvgFillColor(vg, nvgRGBA(32,32,32,255));
    nvgFill(vg);

    gloss := nvgRadialGradient(vg, lx - ex * 0.25, ly - ey * 0.5, ex * 0.1, ex * 0.75, nvgRGBA(255,255,255,128), nvgRGBA(255,255,255, 0));
    nvgBeginPath(vg);
    nvgEllipse(vg, lx, ly, ex, ey);
    nvgFillPaint(vg, gloss);
    nvgFill(vg);

    gloss = nvgRadialGradient(vg, rx - ex * 0.25, ry - ey * 0.5, ex * 0.1, ex * 0.75, nvgRGBA(255,255,255,128), nvgRGBA(255,255,255, 0));
    nvgBeginPath(vg);
    nvgEllipse(vg, rx, ry, ex, ey);
    nvgFillPaint(vg, gloss);
    nvgFill(vg);
}

drawGraph :: (vg: *NVGcontext, x: f32, y: f32, w: f32, h: f32, t: f32) {
    samples: [6] f32;
    sx, sy: [6] f32;
    dx: f32 = w/5.0;

    samples[0] = (1+sinf(t * 1.2345+cosf(t * 0.33457) * 0.44)) * 0.5;
    samples[1] = (1+sinf(t * 0.68363+cosf(t * 1.3) * 1.55)) * 0.5;
    samples[2] = (1+sinf(t * 1.1642+cosf(t * 0.33457) * 1.24)) * 0.5;
    samples[3] = (1+sinf(t * 0.56345+cosf(t * 1.63) * 0.14)) * 0.5;
    samples[4] = (1+sinf(t * 1.6245+cosf(t * 0.254) * 0.3)) * 0.5;
    samples[5] = (1+sinf(t * 0.345+cosf(t * 0.03) * 0.6)) * 0.5;

    for i : 0..6-1 {
        sx[i] = x + i*dx;
        sy[i] = y + h*samples[i] * 0.8;
    }

    // Graph background
    bg := nvgLinearGradient(vg, x, y, x, y + h, nvgRGBA(0,160,192, 0), nvgRGBA(0,160,192,64));
    nvgBeginPath(vg);
    nvgMoveTo(vg, sx[0], sy[0]);
    for i : 1..6-1 {
        nvgBezierTo(vg, sx[i - 1]+dx*0.5,sy[i - 1], sx[i]-dx*0.5,sy[i], sx[i],sy[i]);
    }
    nvgLineTo(vg, x + w, y + h);
    nvgLineTo(vg, x, y + h);
    nvgFillPaint(vg, bg);
    nvgFill(vg);

    // Graph line
    nvgBeginPath(vg);
    nvgMoveTo(vg, sx[0], sy[0] + 2);
    for i : 1..6-1 {
        nvgBezierTo(vg, sx[i - 1]+dx*0.5,sy[i - 1] + 2, sx[i]-dx*0.5,sy[i] + 2, sx[i],sy[i] + 2);
    }
    nvgStrokeColor(vg, nvgRGBA(0, 0, 0,32));
    nvgStrokeWidth(vg, 3.0);
    nvgStroke(vg);

    nvgBeginPath(vg);
    nvgMoveTo(vg, sx[0], sy[0]);
    for i : 1..6-1 {
        nvgBezierTo(vg, sx[i - 1]+dx*0.5,sy[i - 1], sx[i]-dx*0.5,sy[i], sx[i],sy[i]);
    }
    nvgStrokeColor(vg, nvgRGBA(0,160,192,255));
    nvgStrokeWidth(vg, 3.0);
    nvgStroke(vg);

    // Graph sample pos
    for i : 0..6-1 {
        bg = nvgRadialGradient(vg, sx[i],sy[i] + 2, 3.0, 8.0, nvgRGBA(0, 0, 0,32), nvgRGBA(0, 0, 0, 0));
        nvgBeginPath(vg);
        nvgRect(vg, sx[i]-10, sy[i]-10+2, 20,20);
        nvgFillPaint(vg, bg);
        nvgFill(vg);
    }

    nvgBeginPath(vg);
    for i : 0..6-1 {
        nvgCircle(vg, sx[i], sy[i], 4.0);
    }
    nvgFillColor(vg, nvgRGBA(0,160,192,255));
    nvgFill(vg);
    nvgBeginPath(vg);
    for i : 0..6-1 {
        nvgCircle(vg, sx[i], sy[i], 2.0);
    }
    nvgFillColor(vg, nvgRGBA(220,220,220,255));
    nvgFill(vg);

    nvgStrokeWidth(vg, 1.0);
}

drawSpinner :: (vg: *NVGcontext, cx: f32, cy: f32, r: f32, t: f32) {
    a0 := 0.0 + t * 6;
    a1 := NVG_PI + t * 6;
    r0 := r;
    r1 := r * 0.75;

    ax := cx + cosf(a0) * (r0 + r1) * 0.5;
    ay := cy + sinf(a0) * (r0 + r1) * 0.5;
    bx := cx + cosf(a1) * (r0 + r1) * 0.5;
    by := cy + sinf(a1) * (r0 + r1) * 0.5;

    paint := nvgLinearGradient(vg, ax, ay, bx, by, nvgRGBA(0, 0, 0, 0), nvgRGBA(0, 0, 0, 128));

    nvgSave(vg);

    nvgBeginPath(vg);
    nvgArc(vg, cx, cy, r0, a0, a1, .NVG_CW);
    nvgArc(vg, cx, cy, r1, a1, a0, .NVG_CCW);
    nvgClosePath(vg);
    nvgFillPaint(vg, paint);
    nvgFill(vg);

    nvgRestore(vg);
}

drawThumbnails :: (vg: *NVGcontext, x: f32, y: f32, w: f32, h: f32, images: *s32, nimages: s32, t: f32) {
    cornerRadius: f32 = 3.0;
    ix,iy,iw,ih: f32;
    thumb: f32 = 60.0;
    arry: f32 = 30.5;
    imgw, imgh: s32;
    stackh: f32 = (nimages / 2) * (thumb + 10) + 10;
    u: f32 = (1 + cosf(t * 0.5)) * 0.5;
    u2: f32 = (1 - cosf(t * 0.2)) * 0.5;

    imgPaint, shadowPaint, fadePaint: NVGpaint;

    nvgSave(vg);

    // Drop shadow
    shadowPaint = nvgBoxGradient(vg, x, y + 4, w, h, cornerRadius * 2, 20, nvgRGBA(0, 0, 0,128), nvgRGBA(0, 0, 0, 0));
    nvgBeginPath(vg);
    nvgRect(vg, x - 10, y - 10, w + 20, h + 30);
    nvgRoundedRect(vg, x, y, w, h, cornerRadius);
    nvgPathWinding(vg, .NVG_CW);
    nvgFillPaint(vg, shadowPaint);
    nvgFill(vg);

    // Window
    nvgBeginPath(vg);
    nvgRoundedRect(vg, x, y, w, h, cornerRadius);
    nvgMoveTo(vg, x - 10, y + arry);
    nvgLineTo(vg, x + 1, y + arry - 11);
    nvgLineTo(vg, x + 1, y + arry + 11);
    nvgFillColor(vg, nvgRGBA(200,200,200,255));
    nvgFill(vg);

    nvgSave(vg);
    nvgScissor(vg, x, y, w, h);
    nvgTranslate(vg, 0, -(stackh - h) * u);

    dv := 1.0 / cast(f32)(nimages-1);

    for i : 0..nimages-1 {
        tx := x + 10;
        ty := y + 10;
        tx += (i % 2) * (thumb + 10);
        ty += (i / 2) * (thumb + 10);
        nvgImageSize(vg, images[i], *imgw, *imgh);
        if (imgw < imgh) {
            iw = thumb;
            ih = iw * cast(f32) imgh / cast(f32) imgw;
            ix = 0;
            iy = -(ih - thumb) * 0.5;
        } else {
            ih = thumb;
            iw = ih * cast(f32) imgw / cast(f32) imgh;
            ix = -(iw - thumb) * 0.5;
            iy = 0;
        }

        v := i * dv;
        a := clamp((u2-v) / dv, 0, 1);

        if (a < 1.0) {
            drawSpinner(vg, tx + thumb / 2, ty + thumb / 2, thumb * 0.25, t);
        }

        imgPaint = nvgImagePattern(vg, tx + ix, ty + iy, iw, ih, 0.0 / 180.0 * NVG_PI, images[i], a);
        nvgBeginPath(vg);
        nvgRoundedRect(vg, tx,ty, thumb,thumb, 5);
        nvgFillPaint(vg, imgPaint);
        nvgFill(vg);

        shadowPaint = nvgBoxGradient(vg, tx - 1,ty, thumb + 2,thumb + 2, 5, 3, nvgRGBA(0, 0, 0,128), nvgRGBA(0, 0, 0, 0));
        nvgBeginPath(vg);
        nvgRect(vg, tx - 5,ty - 5, thumb + 10,thumb + 10);
        nvgRoundedRect(vg, tx, ty, thumb, thumb, 6);
        nvgPathWinding(vg, .NVG_CW);
        nvgFillPaint(vg, shadowPaint);
        nvgFill(vg);

        nvgBeginPath(vg);
        nvgRoundedRect(vg, tx + 0.5,ty + 0.5, thumb - 1,thumb - 1, 4 - 0.5);
        nvgStrokeWidth(vg, 1.0);
        nvgStrokeColor(vg, nvgRGBA(255,255,255,192));
        nvgStroke(vg);
    }
    nvgRestore(vg);

    // Hide fades
    fadePaint = nvgLinearGradient(vg, x, y, x, y + 6, nvgRGBA(200,200,200,255), nvgRGBA(200,200,200, 0));
    nvgBeginPath(vg);
    nvgRect(vg, x + 4, y, w - 8, 6);
    nvgFillPaint(vg, fadePaint);
    nvgFill(vg);

    fadePaint = nvgLinearGradient(vg, x, y + h, x, y + h - 6, nvgRGBA(200,200,200,255), nvgRGBA(200,200,200, 0));
    nvgBeginPath(vg);
    nvgRect(vg, x + 4, y + h - 6, w - 8, 6);
    nvgFillPaint(vg, fadePaint);
    nvgFill(vg);

    // Scroll bar
    shadowPaint = nvgBoxGradient(vg, x + w - 12 + 1, y + 4 + 1, 8, h - 8, 3, 4, nvgRGBA(0, 0, 0,32), nvgRGBA(0, 0, 0,92));
    nvgBeginPath(vg);
    nvgRoundedRect(vg, x + w - 12, y + 4, 8, h - 8, 3);
    nvgFillPaint(vg, shadowPaint);
//    nvgFillColor(vg, nvgRGBA(255, 0, 0,128));
    nvgFill(vg);

    scrollh := (h/stackh) * (h - 8);
    shadowPaint = nvgBoxGradient(vg, x + w - 12 - 1, y + 4 + (h - 8 - scrollh) * u - 1, 8,scrollh, 3, 4, nvgRGBA(220,220,220,255), nvgRGBA(128,128,128,255));
    nvgBeginPath(vg);
    nvgRoundedRect(vg, x + w - 12 + 1, y + 4 + 1 + (h - 8 - scrollh) * u, 8 - 2,scrollh - 2, 2);
    nvgFillPaint(vg, shadowPaint);
//    nvgFillColor(vg, nvgRGBA(0, 0, 0,128));
    nvgFill(vg);

    nvgRestore(vg);
}

drawColorwheel :: (vg: *NVGcontext, x: f32, y: f32, w: f32, h: f32, t: f32) {
    nvgSave(vg);

    cx := x + w * 0.5;
    cy := y + h * 0.5;
    r1 := min(w, h) * 0.5 - 5.0;
    r0 := r1 - 20.0;
    aeps := 0.5 / r1;    // half a pixel arc length in radians (2pi cancels out).

    paint: NVGpaint;

    for i : 0..6-1 {
        a0 := cast(f32) i / 6.0 * NVG_PI * 2.0 - aeps;
        a1 := cast(f32) (i + 1.0) / 6.0 * NVG_PI * 2.0 + aeps;
        ax := cx + cosf(a0) * (r0 + r1) * 0.5;
        ay := cy + sinf(a0) * (r0 + r1) * 0.5;
        bx := cx + cosf(a1) * (r0 + r1) * 0.5;
        by := cy + sinf(a1) * (r0 + r1) * 0.5;

        c0 := nvgHSLA(a0 / (NVG_PI * 2), 1.0, 0.55, 255);
        c1 := nvgHSLA(a1 / (NVG_PI * 2), 1.0, 0.55, 255);
        paint = nvgLinearGradient(vg, ax, ay, bx, by, c0, c1);

        nvgBeginPath(vg);
        nvgArc(vg, cx, cy, r0, a0, a1, .NVG_CW);
        nvgArc(vg, cx, cy, r1, a1, a0, .NVG_CCW);
        nvgClosePath(vg);
        nvgFillPaint(vg, paint);
        nvgFill(vg);
    }

    nvgBeginPath(vg);
    nvgCircle(vg, cx, cy, r0 - 0.5);
    nvgCircle(vg, cx, cy, r1 + 0.5);
    nvgStrokeColor(vg, nvgRGBA(0, 0, 0,64));
    nvgStrokeWidth(vg, 1.0);
    nvgStroke(vg);

    hue := sinf(t * 0.12);

    // Selector
    nvgSave(vg);
    nvgTranslate(vg, cx, cy);
    nvgRotate(vg, hue * NVG_PI * 2);

    // Marker on
    nvgStrokeWidth(vg, 2.0);
    nvgBeginPath(vg);
    nvgRect(vg, r0 - 1, -3, r1 - r0 + 2, 6);
    nvgStrokeColor(vg, nvgRGBA(255,255,255,192));
    nvgStroke(vg);

    paint = nvgBoxGradient(vg, r0 - 3, -5, r1 - r0 + 6, 10, 2, 4, nvgRGBA(0, 0, 0,128), nvgRGBA(0, 0, 0, 0));
    nvgBeginPath(vg);
    nvgRect(vg, r0 - 2 - 10, -4 - 10, r1 - r0 + 4 + 20, 8 + 20);
    nvgRect(vg, r0 - 2, -4, r1 - r0 + 4, 8);
    nvgPathWinding(vg, .NVG_CW);
    nvgFillPaint(vg, paint);
    nvgFill(vg);

    // Center triangle
    r := r0 - 6;
    ax := cosf(120.0 / 180.0 * NVG_PI) * r;
    ay := sinf(120.0 / 180.0 * NVG_PI) * r;
    bx := cosf(-120.0 / 180.0 * NVG_PI) * r;
    by := sinf(-120.0 / 180.0 * NVG_PI) * r;
    nvgBeginPath(vg);
    nvgMoveTo(vg, r, 0);
    nvgLineTo(vg, ax, ay);
    nvgLineTo(vg, bx, by);
    nvgClosePath(vg);
    paint = nvgLinearGradient(vg, r, 0, ax, ay, nvgHSLA(hue, 1.0, 0.5,255), nvgRGBA(255,255,255,255));
    nvgFillPaint(vg, paint);
    nvgFill(vg);
    paint = nvgLinearGradient(vg, (r + ax) * 0.5, (0 + ay) * 0.5, bx, by, nvgRGBA(0, 0, 0, 0), nvgRGBA(0, 0, 0,255));
    nvgFillPaint(vg, paint);
    nvgFill(vg);
    nvgStrokeColor(vg, nvgRGBA(0, 0, 0,64));
    nvgStroke(vg);

    // Select circle on triangle
    ax = cosf(120.0 / 180.0 * NVG_PI) * r * 0.3;
    ay = sinf(120.0 / 180.0 * NVG_PI) * r * 0.4;
    nvgStrokeWidth(vg, 2.0);
    nvgBeginPath(vg);
    nvgCircle(vg, ax, ay, 5);
    nvgStrokeColor(vg, nvgRGBA(255,255,255,192));
    nvgStroke(vg);

    paint = nvgRadialGradient(vg, ax, ay, 7, 9, nvgRGBA(0, 0, 0,64), nvgRGBA(0, 0, 0, 0));
    nvgBeginPath(vg);
    nvgRect(vg, ax - 20, ay - 20, 40, 40);
    nvgCircle(vg, ax, ay, 7);
    nvgPathWinding(vg, .NVG_CW);
    nvgFillPaint(vg, paint);
    nvgFill(vg);

    nvgRestore(vg);
    nvgRestore(vg);
}

drawLines :: (vg: *NVGcontext, x: f32, y: f32, w: f32, h: f32, t: f32) {
    pad: f32 = 5.0;
    s: f32 = w/9.0 - pad*2;
    pts: [4 * 2] f32;
    fx, fy: f32;
    joins: [3] NVGlineCap = .[.NVG_MITER, .NVG_ROUND, .NVG_BEVEL];
    caps: [3] NVGlineCap = .[.NVG_BUTT, .NVG_ROUND, .NVG_SQUARE];

    nvgSave(vg);
    pts[0] = -s * 0.25 + cosf(t * 0.3) * s * 0.5;
    pts[1] = sinf(t * 0.3) * s * 0.5;
    pts[2] = -s * 0.25;
    pts[3] = 0;
    pts[4] = s * 0.25;
    pts[5] = 0;
    pts[6] = s * 0.25 + cosf(-t * 0.3) * s * 0.5;
    pts[7] = sinf(-t * 0.3) * s * 0.5;

    for i : 0..3-1 {
        for j : 0..3-1 {
            fx = x + s * 0.5 + (i * 3 + j)/9.0 * w + pad;
            fy = y - s * 0.5 + pad;

            nvgLineCap(vg, caps[i]);
            nvgLineJoin(vg, joins[j]);

            nvgStrokeWidth(vg, s * 0.3);
            nvgStrokeColor(vg, nvgRGBA(0, 0, 0,160));
            nvgBeginPath(vg);
            nvgMoveTo(vg, fx+pts[0], fy+pts[1]);
            nvgLineTo(vg, fx+pts[2], fy+pts[3]);
            nvgLineTo(vg, fx+pts[4], fy+pts[5]);
            nvgLineTo(vg, fx+pts[6], fy+pts[7]);
            nvgStroke(vg);

            nvgLineCap(vg, .NVG_BUTT);
            nvgLineJoin(vg, .NVG_BEVEL);

            nvgStrokeWidth(vg, 1.0);
            nvgStrokeColor(vg, nvgRGBA(0,192,255,255));
            nvgBeginPath(vg);
            nvgMoveTo(vg, fx+pts[0], fy+pts[1]);
            nvgLineTo(vg, fx+pts[2], fy+pts[3]);
            nvgLineTo(vg, fx+pts[4], fy+pts[5]);
            nvgLineTo(vg, fx+pts[6], fy+pts[7]);
            nvgStroke(vg);
        }
    }

    nvgRestore(vg);
}

drawParagraph :: (vg: *NVGcontext, x: f32, y: f32, width: f32, height: f32, mx: f32, my: f32) {
    text: *u8 = "This is longer chunk of text.\n  \n  Would have used lorem ipsum but she    was busy jumping over the lazy dog with the fox and all the men who came to the aid of the party.🎉";
    hoverText: *u8 = "Hover your mouse over the text to see calculated caret position.";

    rows: [3] NVGtextRow;
    nrows: s32 = 0;

    glyphs: [100] NVGglyphPosition;
    nglyphs: s32 = 0;

    start: *u8;
    end: *u8;

    gutter: s32 = 0;
    lnum: s32 = 0;
    lineh: f32;
    gx, gy: f32;

    nvgSave(vg);

    nvgFontSize(vg, 15.0);
    nvgFontFace(vg, "sans");
    nvgTextAlign(vg, NVGalign.NVG_ALIGN_LEFT | .NVG_ALIGN_TOP);
    nvgTextMetrics(vg, null, null, *lineh);

    // The text break API can be used to fill a large buffer of rows,
    // or to iterate over the text just few lines (or just one) at a time.
    // The "next" variable of the last returned item tells where to continue.
    start = text;
    end = text + strlen(text);

    print("x = %\n", x);
    print("y = %\n", y);

    nrows = nvgTextBreakLines(vg, start, end, width, rows, 3);
    while (nrows > 0) {
        for i : 0..nrows-1 {
            row := *rows[i];

            print("row.minx = %\n", row.minx);
            print("row.maxx = %\n", row.maxx);

            hit := mx > x && mx < (x+width) && my >= y && my < (y+lineh);

            nvgBeginPath(vg);
            nvgFillColor(vg, nvgRGBA(255,255,255, cast(u8)(ifx hit then 64 else 16)));
            nvgRect(vg, x + row.minx, y, row.maxx - row.minx, lineh);
            nvgFill(vg);

            nvgFillColor(vg, nvgRGBA(255,255,255,255));
            nvgText(vg, x, y, row.start, row.end);

            if (hit) {
                caretx := ifx (mx < x + row.width / 2) then x else x + row.width;
                px := x;
                nglyphs = nvgTextGlyphPositions(vg, x, y, row.start, row.end, glyphs.data, 100);
                for j : 0..nglyphs-1 {
                    x0 := glyphs[j].x;
                    x1 := ifx (j + 1 < nglyphs) then glyphs[j + 1].x else x + row.width;
                    gx := x0 * 0.3 + x1 * 0.7;
                    if (mx >= px && mx < gx) {
                        caretx = glyphs[j].x;
                    }
                    px = gx;
                }
                nvgBeginPath(vg);
                nvgFillColor(vg, nvgRGBA(255,192, 0,255));
                nvgRect(vg, caretx, y, 1, lineh);
                nvgFill(vg);

                gutter = lnum + 1;
                gx = x - 10;
                gy = y + lineh / 2;
            }
            lnum += 1;
            y += lineh;
        }
        // Keep going...
        start = rows[nrows-1].next;
        nrows = nvgTextBreakLines(vg, start, end, width, rows, 3);
    }

    bounds: [4] f32;

    if (gutter) {
        txt := sprint("%", gutter);
        defer free(txt);

        ctxt := toCString(txt);
        defer free(ctxt);

        nvgFontSize(vg, 12.0);
        nvgTextAlign(vg, NVGalign.NVG_ALIGN_RIGHT | .NVG_ALIGN_MIDDLE);

        nvgTextBounds(vg, gx, gy, ctxt, null, bounds.data);

        nvgBeginPath(vg);
        nvgFillColor(vg, nvgRGBA(255,192, 0,255));
        nvgRoundedRect(vg,
            cast(f32) (cast(s32) (bounds[0]) - 4),
            cast(f32) (cast(s32) (bounds[1]) - 2),
            cast(f32) (cast(s32) (bounds[2] - bounds[0]) + 8),
            cast(f32) (cast(s32) (bounds[3] - bounds[1]) + 4),
            cast(f32) ((cast(s32) (bounds[3] - bounds[1]) + 4) / 2 - 1));
        nvgFill(vg);

        nvgFillColor(vg, nvgRGBA(32,32,32,255));
        nvgText(vg, gx, gy, ctxt, null);
    }

    y += 20.0;

    nvgFontSize(vg, 11.0);
    nvgTextAlign(vg, NVGalign.NVG_ALIGN_LEFT | .NVG_ALIGN_TOP);
    nvgTextLineHeight(vg, 1.2);

    nvgTextBoxBounds(vg, x, y, 150, hoverText, null, bounds.data);

    // Fade the tooltip out when close to it.
    gx = clamp(mx, bounds[0], bounds[2]) - mx;
    gy = clamp(my, bounds[1], bounds[3]) - my;
    a := sqrtf(gx * gx + gy * gy) / 30.0;
    a = clamp(a, 0, 1);
    nvgGlobalAlpha(vg, a);

    nvgBeginPath(vg);
    nvgFillColor(vg, nvgRGBA(220,220,220,255));
    nvgRoundedRect(vg,
        bounds[0]-2,
        bounds[1]-2,
        cast(f32) (cast(s32)(bounds[2]-bounds[0]) + 4),
        cast(f32) (cast(s32)(bounds[3]-bounds[1]) + 4),
        3);
    px := cast(f32)cast(s32)((bounds[2]+bounds[0])/2);
    nvgMoveTo(vg, px,bounds[1] - 10);
    nvgLineTo(vg, px+7,bounds[1] + 1);
    nvgLineTo(vg, px-7,bounds[1] + 1);
    nvgFill(vg);

    nvgFillColor(vg, nvgRGBA(0, 0, 0,220));
    nvgTextBox(vg, x, y, 150, hoverText, null);

    nvgRestore(vg);
}

drawWidths :: (vg: *NVGcontext, x: f32, y: f32, width: f32) {
    nvgSave(vg);

    nvgStrokeColor(vg, nvgRGBA(0, 0, 0,255));

    for i : 0..20-1 {
        w: f32 = (i + 0.5) * 0.1;
        nvgStrokeWidth(vg, w);
        nvgBeginPath(vg);
        nvgMoveTo(vg, x, y);
        nvgLineTo(vg, x+width, y+width*0.3);
        nvgStroke(vg);
        y += 10;
    }

    nvgRestore(vg);
}

drawCaps :: (vg: *NVGcontext, x: f32, y: f32, width: f32) {
    caps: [3] NVGlineCap = .[.NVG_BUTT, .NVG_ROUND, .NVG_SQUARE];
    lineWidth: f32 = 8.0;

    nvgSave(vg);

    nvgBeginPath(vg);
    nvgRect(vg, x-lineWidth/2, y, width+lineWidth, 40);
    nvgFillColor(vg, nvgRGBA(255,255,255,32));
    nvgFill(vg);

    nvgBeginPath(vg);
    nvgRect(vg, x, y, width, 40);
    nvgFillColor(vg, nvgRGBA(255,255,255,32));
    nvgFill(vg);

    nvgStrokeWidth(vg, lineWidth);

    for i : 0..3-1 {
        nvgLineCap(vg, caps[i]);
        nvgStrokeColor(vg, nvgRGBA(0, 0, 0,255));
        nvgBeginPath(vg);
        nvgMoveTo(vg, x, y + i*10 + 5);
        nvgLineTo(vg, x+width, y + i*10 + 5);
        nvgStroke(vg);
    }

    nvgRestore(vg);
}

drawScissor :: (vg: *NVGcontext, x: f32, y: f32, t: f32) {
    nvgSave(vg);

    // Draw first rect and set scissor to it's area.
    nvgTranslate(vg, x, y);
    nvgRotate(vg, nvgDegToRad(5));
    nvgBeginPath(vg);
    nvgRect(vg, -20, -20,60,40);
    nvgFillColor(vg, nvgRGBA(255, 0, 0,255));
    nvgFill(vg);
    nvgScissor(vg, -20, -20,60,40);

    // Draw second rectangle with offset and rotation.
    nvgTranslate(vg, 40, 0);
    nvgRotate(vg, t);

    // Draw the intended second rectangle without any scissoring.
    nvgSave(vg);
    nvgResetScissor(vg);
    nvgBeginPath(vg);
    nvgRect(vg, -20, -10,60,30);
    nvgFillColor(vg, nvgRGBA(255,128, 0,64));
    nvgFill(vg);
    nvgRestore(vg);

    // Draw second rectangle with combined scissoring.
    nvgIntersectScissor(vg, -20, -10,60,30);
    nvgBeginPath(vg);
    nvgRect(vg, -20, -10,60,30);
    nvgFillColor(vg, nvgRGBA(255,128, 0,255));
    nvgFill(vg);

    nvgRestore(vg);
}

loadDemoData :: (vg: *NVGcontext, data: *DemoData) -> s32 {
    if (vg == null) {
        return -1;
    }

    for i : 0..12-1 {
        file := sprint("../images/image%.jpg", i + 1);
        defer free(file);

        cfile := toCString(file);
        defer free(cfile);

        data.images[i] = nvgCreateImage(vg, cfile, 0);
        if (data.images[i] == 0) {
            print("Could not load %.\n", file);
            return -1;
        }
    }

    data.fontIcons = nvgCreateFont(vg, "icons", "../entypo.ttf");
    if (data.fontIcons == -1) {
        print("Could not add font icons.\n");
        return -1;
    }
    data.fontNormal = nvgCreateFont(vg, "sans", "../Roboto-Regular.ttf");
    if (data.fontNormal == -1) {
        print("Could not add font italic.\n");
        return -1;
    }
    data.fontBold = nvgCreateFont(vg, "sans-bold", "../Roboto-Bold.ttf");
    if (data.fontBold == -1) {
        print("Could not add font bold.\n");
        return -1;
    }
    data.fontEmoji = nvgCreateFont(vg, "emoji", "../NotoEmoji-Regular.ttf");
    if (data.fontEmoji == -1) {
        print("Could not add font emoji.\n");
        return -1;
    }
    nvgAddFallbackFontId(vg, data.fontNormal, data.fontEmoji);
    nvgAddFallbackFontId(vg, data.fontBold, data.fontEmoji);

    return 0;
}

freeDemoData :: (vg: *NVGcontext, data: *DemoData) {
    if (vg == null) {
        return;
    }

    for i : 0..12-1 {
        nvgDeleteImage(vg, data.images[i]);
    }
}

renderDemo :: (vg: *NVGcontext, mx: f32, my: f32, width: f32, height: f32, t: f32, blowup: bool, data: *DemoData) {
    x, y, popy: f32;

    drawEyes(vg, width - 250, 50, 150, 100, mx, my, t);
    drawParagraph(vg, width - 450, 50, 150, 100, mx, my);
    drawGraph(vg, 0, height / 2, width, height / 2, t);
    drawColorwheel(vg, width - 300, height - 300, 250.0, 250.0, t);

    // Line joints
    drawLines(vg, 120, height - 50, 600, 50, t);

    // Line caps
    drawWidths(vg, 10, 50, 30);

    // Line caps
    drawCaps(vg, 10, 300, 30);

    drawScissor(vg, 50, height - 80, t);

    nvgSave(vg);
    if (blowup) {
        nvgRotate(vg, sinf(t * 0.3) * 5.0 / 180.0 * NVG_PI);
        nvgScale(vg, 2.0, 2.0);
    }

    // Widgets
    drawWindow(vg, "Widgets `n Stuff", 50, 50, 300, 400);
    x = 60;
    y = 95;
    drawSearchBox(vg, "Search", x, y, 280, 25);
    y += 40;
    drawDropDown(vg, "Effects", x, y, 280, 28);
    popy = y + 14;
    y += 45;

    // Form
    drawLabel(vg, "Login", x, y, 280, 20);
    y += 25;
    drawEditBox(vg, "Email",  x, y, 280, 28);
    y += 35;
    drawEditBox(vg, "Password", x, y, 280, 28);
    y += 38;
    drawCheckBox(vg, "Remember me", x, y, 140, 28);
    drawButton(vg, ICON_LOGIN, "Sign in", x + 138, y, 140, 28, nvgRGBA(0,96,128,255));
    y += 45;

    // Slider
    drawLabel(vg, "Diameter", x, y, 280, 20);
    y += 25;
    drawEditBoxNum(vg, "123.00", "px", x + 180, y, 100, 28);
    drawSlider(vg, 0.4, x, y, 170, 28);
    y += 55;

    drawButton(vg, ICON_TRASH, "Delete", x, y, 160, 28, nvgRGBA(128,16, 8,255));
    drawButton(vg, 0, "Cancel", x + 170, y, 110, 28, nvgRGBA(0, 0, 0, 0));

    // Thumbnails box
    drawThumbnails(vg, 365, popy - 30, 160, 300, data.images.data, 12, t);

    nvgRestore(vg);
}

unpremultiplyAlpha :: (image: *u8, w: s32, h: s32, stride: s32) {
    // Unpremultiply
    for y : 0..h-1 {
        row := *image[y*stride];
        for x : 0..w-1 {
            r := row[0];
            g := row[1];
            b := row[2];
            a := row[3];
            if (a != 0) {
                row[0] = cast(u8)min(r*255/a, 255);
                row[1] = cast(u8)min(g*255/a, 255);
                row[2] = cast(u8)min(b*255/a, 255);
            }
            row += 4;
        }
    }

    // Defringe
    for y : 0..h-1 {
        row := *image[y*stride];
        for x : 0..w-1 {
            r: u8 = 0;
            g: u8 = 0;
            b: u8 = 0;
            a := row[3];
            n: u8 = 0;
            if (a == 0) {
                if (x-1 > 0 && row[-1] != 0) {
                    r += row[-4];
                    g += row[-3];
                    b += row[-2];
                    n += 1;
                }
                if (x + 1 < w && row[7] != 0) {
                    r += row[4];
                    g += row[5];
                    b += row[6];
                    n += 1;
                }
                if (y-1 > 0 && row[-stride+3] != 0) {
                    r += row[-stride];
                    g += row[-stride+1];
                    b += row[-stride+2];
                    n += 1;
                }
                if (y + 1 < h && row[stride+3] != 0) {
                    r += row[stride];
                    g += row[stride+1];
                    b += row[stride+2];
                    n += 1;
                }
                if (n > 0) {
                    row[0] = r/n;
                    row[1] = g/n;
                    row[2] = b/n;
                }
            }
            row += 4;
        }
    }
}

setAlpha :: (image: *u8, w: s32, h: s32, stride: s32, a: u8) {
    for y : 0..h-1 {
        row := *image[y*stride];
        for x : 0..w-1 {
            row[x * 4 + 3] = a;
        }
    }
}

flipHorizontal :: (image: *u8, w: s32, h: s32, stride: s32) {
    i: s32 = 0;
    j: s32 = h-1;
    while (i < j) {
        ri := *image[i * stride];
        rj := *image[j * stride];
        for k : 0..w * 4-1 {
            t := ri[k];
            ri[k] = rj[k];
            rj[k] = t;
        }
        i += 1;
        j -= 1;
    }
}

saveScreenShot :: (w: s32, h: s32, premult: s32, name: *u8) {
    image := alloc(u8, w * h * 4);
    if (image == null) {
        return;
    }
    glReadPixels(0, 0, cast(u32) w, cast(u32) h, GL_RGBA, GL_UNSIGNED_BYTE, image);
    if (premult) {
        unpremultiplyAlpha(image, w, h, w * 4);
    } else {
        setAlpha(image, w, h, w * 4, 255);
    }
    flipHorizontal(image, w, h, w * 4);
    stbi_write_png(name, w, h, 4, image, w * 4);
    free(image);
}