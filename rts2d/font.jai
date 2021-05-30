DEBUG_RENDER_FONT :: false;

FONT_NORMAL_COLOR :: Color.{ r = 239, g = 255, b = 219, a = 255 };
FONT_HIGHLIGHT_COLOR :: Color.{ r = 255, g = 227, b = 73, a = 255 };
NO_HIGHLIGHT : s32 : -1;
ALL_HIGHLIGHT : s32 : -2;
TAB_WIDTH : s32 : 2;

PRINTABLE_CHARS_COUNT :: 126 - 32 + 1; // last printable char - first printable char + 1

NVGwrap :: enum {
	NVG_WRAP_NONE :: 1<<0;
	NVG_WRAP_WORD :: 1<<1;
}

NVGtrim :: enum {
    NVG_TRIM_NONE :: 1<<0;
    NVG_TRIM_SPACES :: 1<<1;
    NVG_TRIM_ALL :: 1<<2;
}

NVGfontParams :: struct {
    fontIndex: s32;
    fontSize: f32;
    lineHeight: f32;
    fontColor: NVGcolor;
    highlightColor: NVGcolor;
    highlightIndex: s32;
    highlightCount: s32;
    boundings: Vec2;
    horizontalAlign: NVGalign;
    verticalAlign: NVGalign;
    lineAlign: NVGalign;
    wrapping: NVGwrap;
    trimming: NVGtrim;
    fontData: FontData;
}

FontData :: struct {
    spriteWidth: s32;
    spriteHeight: s32;
    lineHeight: f32;
    advance: s32;
    sprite: Sprite;
    data: [PRINTABLE_CHARS_COUNT] Rect;
}

colorToNVGcolor :: (color: Color) -> NVGcolor {
    return nvgRGBA(color.r, color.g, color.b, color.a);
}

textAlignToNVGalign :: (align: TextAlignment) -> NVGalign {
    if align == {
        case TextAlignment.Left;   return NVGalign.NVG_ALIGN_LEFT;
        case TextAlignment.Center; return NVGalign.NVG_ALIGN_CENTER;
        case TextAlignment.Right;  return NVGalign.NVG_ALIGN_RIGHT;
        case TextAlignment.Top;    return NVGalign.NVG_ALIGN_TOP;
        case TextAlignment.Middle; return NVGalign.NVG_ALIGN_MIDDLE;
        case TextAlignment.Bottom; return NVGalign.NVG_ALIGN_BOTTOM;
        case; {
            logError("Invalid alignment value: %. Defaulting to %\n", align, NVGalign.NVG_ALIGN_LEFT);
            return .NVG_ALIGN_LEFT;
        }
    }
}

textWrappingToNVGwrap :: (wrap: TextWrapping) -> NVGwrap {
    if wrap == {
        case TextWrapping.None; return NVGwrap.NVG_WRAP_NONE;
        case TextWrapping.Char; return NVGwrap.NVG_WRAP_WORD;
        case; {
            logError("Invalid wrapping value: %. Defaulting to %\n", wrap, NVGwrap.NVG_WRAP_NONE);
            return .NVG_WRAP_NONE;
        }
    }
}

textTrimmingToNVGtrim :: (trim: TextTrimming) -> NVGtrim {
    if trim == {
        case TextTrimming.None; return NVGtrim.NVG_TRIM_NONE;
        case TextTrimming.Spaces; return NVGtrim.NVG_TRIM_SPACES;
        case TextTrimming.All; return NVGtrim.NVG_TRIM_ALL;
        case; {
            logError("Invalid trimming value: %. Defaulting to %\n", trim, NVGtrim.NVG_TRIM_NONE);
            return .NVG_TRIM_NONE;
        }
    }
}

nvgSingleSpriteText :: (gfx: *NVGcontext, text: string, x: f32, y: f32, params: NVGfontParams) {
    scale := params.fontSize / params.fontData.lineHeight;
    textSize := nvgMeasureSingleSpriteText(text, params);
    length := cast(s32) text.count;

    nvgSave(gfx);
    nvgTranslate(gfx, x, y);

    if (!isZero(params.boundings)) {
        textOffset := getAlignmentOffset(params.horizontalAlign, params.verticalAlign, params.boundings, textSize);
        nvgTranslate(gfx, textOffset.x, textOffset.y);
    }

    nvgScale(gfx, scale, scale);

    #if DEBUG_RENDER_FONT {
        outline := rect(0, 0, textSize.x / scale, 1.5);
        nvgStrokeRect(gfx, outline, NVG_GREEN_SELECTION, 3);
    }

    if (params.highlightIndex >= 0) {
        x = nvgSingleSpriteTextSpan(gfx, text,
                                    0, params.highlightIndex,
                                    0, 0,
                                    params.fontColor,
                                    params.fontData,
                                    params.boundings,
                                    scale);

        x = nvgSingleSpriteTextSpan(gfx, text,
                                    params.highlightIndex, params.highlightCount,
                                    x, 0,
                                    params.highlightColor,
                                    params.fontData,
                                    params.boundings,
                                    scale);

        x = nvgSingleSpriteTextSpan(gfx, text,
                                    params.highlightIndex + params.highlightCount,
                                    length - params.highlightIndex - params.highlightCount,
                                    x, 0,
                                    params.fontColor,
                                    params.fontData,
                                    params.boundings,
                                    scale);
    } else {
        // No highlight, highlightIndex = -1
        // All highlight, highlightIndex = -2
        fontColor := ifx params.highlightIndex == ALL_HIGHLIGHT
            then params.highlightColor else params.fontColor;

        nvgSingleSpriteTextSpan(gfx, text,
                                0, length,
                                0, 0,
                                fontColor,
                                params.fontData,
                                params.boundings,
                                scale);
    }

    nvgRestore(gfx);
}

nvgMultiSpriteText :: (gfx: *NVGcontext, text: string, x: f32, y: f32, params: NVGfontParams) {
    scale := params.fontSize / params.fontData.lineHeight;
    lineHeight := ifx params.lineHeight > 0 then params.lineHeight else params.fontData.lineHeight;

    lines := createList(NVGtextSpan);
    nvgSplitTextIntoLines(text, *lines, params.boundings.x, params);

    nvgSave(gfx);
    nvgTranslate(gfx, x, y);

    textSize := nvgMeasureMultiSpriteText(text, params.boundings.x, params);

    textOffset := getAlignmentOffset(params.horizontalAlign, params.verticalAlign, params.boundings, textSize);
    nvgTranslate(gfx, textOffset.x, textOffset.y);

    #if DEBUG_RENDER_FONT {
        outline := rect(0, 0, textSize.x, textSize.y);
        nvgStrokeRect(gfx, outline, NVG_RED_SELECTION, 1);
    }

    lineStartIndex: s32 = 0;

    for line, i : lines {
        lineLength := line.end - line.start;
        lineAlignOffset := getLineAlignmentOffset(params.lineAlign, textSize.x, line.width);
        lineOffset := vec2(lineAlignOffset, i * lineHeight);
        subText := slice(text, line.start, lineLength);

        if (lineOffset.y * scale > params.boundings.y) {
            break;
        }

        nvgSave(gfx);
        nvgTranslate(gfx, lineOffset.x, 0);
        nvgScale(gfx, scale, scale);
        nvgTranslate(gfx, 0, lineOffset.y);

        #if DEBUG_RENDER_FONT {
            outline := rect(0, 0, line.width / scale, lineHeight);
            nvgStrokeRect(gfx, outline, NVG_GREEN_SELECTION, 1);
        }

        if (params.highlightIndex >= lineStartIndex && params.highlightIndex < lineStartIndex + lineLength) {
            highlightIndex := params.highlightIndex - lineStartIndex;
            highlightCount := min(params.highlightCount, lineLength - highlightIndex);

            x = nvgSingleSpriteTextSpan(gfx, subText,
                                        0, highlightIndex,
                                        0, 0,
                                        params.fontColor,
                                        params.fontData,
                                        params.boundings,
                                        scale);

            x = nvgSingleSpriteTextSpan(gfx, subText,
                                        highlightIndex, highlightCount,
                                        x, 0,
                                        params.highlightColor,
                                        params.fontData,
                                        params.boundings,
                                        scale);

            x = nvgSingleSpriteTextSpan(gfx, subText,
                                        highlightIndex + highlightCount,
                                        lineLength - highlightIndex - highlightCount,
                                        x, 0,
                                        params.fontColor,
                                        params.fontData,
                                        params.boundings,
                                        scale);
        }
        else if (params.highlightIndex < lineStartIndex &&
                 params.highlightIndex + params.highlightCount >= lineStartIndex)
        {
            highlightCount := min(params.highlightIndex + params.highlightCount - lineStartIndex, lineLength);

            x = nvgSingleSpriteTextSpan(gfx, subText,
                                        0, highlightCount,
                                        0, 0,
                                        params.highlightColor,
                                        params.fontData,
                                        params.boundings,
                                        scale);

            x = nvgSingleSpriteTextSpan(gfx, subText,
                                        highlightCount,
                                        lineLength - highlightCount,
                                        x, 0,
                                        params.fontColor,
                                        params.fontData,
                                        params.boundings,
                                        scale);
        }
        else
        {
            // No highlight, highlightIndex = -1
            // All highlight, highlightIndex = -2
            fontColor := ifx params.highlightIndex == ALL_HIGHLIGHT
                then params.highlightColor else params.fontColor;

            nvgSingleSpriteTextSpan(gfx, subText,
                                    0, lineLength,
                                    0, 0,
                                    fontColor,
                                    params.fontData,
                                    params.boundings,
                                    scale);
        }

        nvgRestore(gfx);

        lineStartIndex += lineLength;
    }

    nvgRestore(gfx);
}

nvgMeasureSingleSpriteText :: (text: string, params: NVGfontParams) -> Vec2 {
    scale := params.fontSize / params.fontData.lineHeight;
    size := VEC2_ZERO;

    i: s32 = 0;
    while (i < text.count) {
        c := text[i];

        if (c == #char "\0") {
            break;
        } else if (c == #char "\r") {
            if (i + 1 >= text.count) {
                break;
            }
            i += 1;
            c = text[i];
            assert(c == #char "\n");
            size.x += params.fontData.advance * scale;
        } else if (c == #char "\n") {
            size.x += params.fontData.advance * scale;
        } else if (c == #char "\t") {
            rs := params.fontData.data[getCharIndex(#char " ")];
            size.x += (TAB_WIDTH * rs.w + params.fontData.advance) * scale;
        } else {
            rs := params.fontData.data[getCharIndex(c)];
            size.x += (rs.w + params.fontData.advance) * scale;
            size.y = max(size.y, rs.h * scale);
        }

        i += 1;
    }

    return size;
}

nvgMeasureMultiSpriteText :: (text: string, width: f32, params: NVGfontParams) -> Vec2 {
    scale := params.fontSize / params.fontData.lineHeight;
    lineHeight := ifx params.lineHeight > 0 then params.lineHeight else params.fontData.lineHeight;

    lines := createList(NVGtextSpan);
    nvgSplitTextIntoLines(text, *lines, params.boundings.x, params);

    size := VEC2_ZERO;

    for line : lines {
        size.x = max(size.x, line.width);
        size.y += lineHeight * scale;
    }

    return size;
}

#scope_file

#import "String";

NVGtextSpan :: struct {
    start: s32; // the inclusive index of the start of the line
    end: s32;   // the exclusive index of the end of the line
    width: f32; // the width of the line in pixels
}

createTextSpan :: inline (start: s32, end: s32, width: f32) -> NVGtextSpan {
    span: NVGtextSpan = ---;
    span.start = start;
    span.end = end;
    span.width = width;
    return span;
}

getCharIndex :: (c: u8) -> s32 {
    return cast(s32) (ifx c > 0 then c - 32 else 0);
}

getAlignmentOffset :: (horizontalAlign: NVGalign, verticalAlign: NVGalign, boundings: Vec2, textSize: Vec2) -> Vec2 {
    offset := VEC2_ZERO;

    if horizontalAlign == {
        case NVGalign.NVG_ALIGN_LEFT; {
            // nothing here
        }
        case NVGalign.NVG_ALIGN_CENTER; {
            offset.x = ceilf((boundings.x - textSize.x)/2);
        }
        case NVGalign.NVG_ALIGN_RIGHT; {
            offset.x = ceilf(boundings.x - textSize.x);
        }
        case; {
            logError("Invalid horizontal alignment value: %\n", horizontalAlign);
        }
    }

    if verticalAlign == {
        case NVGalign.NVG_ALIGN_TOP; {
            // nothing here
        }
        case NVGalign.NVG_ALIGN_MIDDLE; {
            offset.y = ceilf((boundings.y/2) - (textSize.y/2));
        }
        case NVGalign.NVG_ALIGN_BOTTOM; {
            offset.y = ceilf(boundings.y - textSize.y);
        }
        case; {
            logError("Invalid vertical alignment value: %\n", verticalAlign);
        }
    }

    return offset;
}

getLineAlignmentOffset :: (lineAlign: NVGalign, width: f32, lineWidth: f32) -> f32 {
    offset: f32 = 0;

    if lineAlign == {
        case .NVG_ALIGN_LEFT; {
            // nothing here
        }
        case .NVG_ALIGN_CENTER; {
            offset = ceilf((width - lineWidth)/2);
        }
        case .NVG_ALIGN_RIGHT; {
            offset = ceilf(width - lineWidth);
        }
        case; {
            logError("Invalid horizontal alignment value: %\n", lineAlign);
        }
    }

    return offset;
}

nvgSplitTextIntoLines :: (text: string, lines: *List(NVGtextSpan), width: f32, params: NVGfontParams) {
    scale := params.fontSize / params.fontData.lineHeight;
    wrap := params.wrapping == .NVG_WRAP_WORD;
    x: f32 = 0;

    s: s32 = 0;
    e: s32 = 0;

    while (e < text.count) {
        c := text[e];

        if (c == #char "\0") {
            break;
        } else if (c == #char "\r") {
            if (e + 1 >= text.count) {
                break;
            }

            // a new line is generated for each \r\n
            e += 1;
            c = text[e];
            assert(c == #char "\n");
            add(lines, createTextSpan(s, e - 1, x));

            s = e + 1;
            x = 0;
        } else if (c == #char "\n") {
            // a new line is generated for each \n
            add(lines, createTextSpan(s, e, x));

            s = e + 1;
            x = 0;
        } else if (c == #char "\t") {
            rs := params.fontData.data[getCharIndex(#char " ")];
            dx := (TAB_WIDTH * rs.w + params.fontData.advance) * scale;

            // if the current character doesn't fit in the line generate a new line
            if (x + dx > width && wrap) {
                add(lines, createTextSpan(s, e, x));

                s = e;
                x = 0;
            } else {
                x += dx;
            }
        } else {
            rs := params.fontData.data[getCharIndex(c)];
            dx := (rs.w + params.fontData.advance) * scale;

            // if the current character doesn't fit in the line generate a new line
            if (x + dx > width && wrap) {
                add(lines, createTextSpan(s, e, x));

                s = e;
                x = 0;
            } else {
                x += dx;
            }
        }

        e += 1;
    }

    if (s < e) {
        add(lines, createTextSpan(s, e, x));
    }

    // trim start and end spaces on lines
    if (params.trimming != .NVG_TRIM_NONE) {
        whiteSpaceData := params.fontData.data[getCharIndex(#char " ")];
        whiteSpaceWidth := (whiteSpaceData.w + params.fontData.advance) * scale;

        for line : lines {
            while (line.start < line.end) {
                if (text[line.start] == #char " " && params.trimming >= .NVG_TRIM_SPACES) {
                    line.width -= whiteSpaceWidth;
                    line.start += 1;
                } else if (text[line.start] == #char "\t" && params.trimming >= .NVG_TRIM_ALL) {
                    line.width -= TAB_WIDTH * whiteSpaceWidth;
                    line.start += 1;
                } else {
                    break;
                }
            }

            while (line.start < line.end) {
                if (text[line.end] == #char " " && params.trimming >= .NVG_TRIM_SPACES) {
                    line.width -= whiteSpaceWidth;
                    line.end -= 1;
                } else if (text[line.end] == #char "\t" && params.trimming >= .NVG_TRIM_ALL) {
                    line.width -= TAB_WIDTH * whiteSpaceWidth;
                    line.end -= 1;
                } else {
                    break;
                }
            }
        }
    }
}

nvgSingleSpriteTextSpan :: (gfx: *NVGcontext,
                            text: string,
                            index: s32, count: s32,
                            x: f32, y: f32,
                            fontColor: NVGcolor,
                            fontData: FontData,
                            boundings: Vec2,
                            scale: f32) -> f32
{
    if (count > 0) {
        nvgSave(gfx);
        nvgFillColor(gfx, fontColor);

        batch := nvgBeginImageBatch(gfx, fontData.sprite.image, count);

        while (count > 0) {
            if (boundings.x > 0 && x * scale > boundings.x) {
                break;
            }

            c := text[index];

            if (c == #char "\r") {
                if (index + 1 >= index + count) {
                    break;
                }

                index += 1;
                c = text[index];
                assert(c == #char "\n");

                // when we are rendering a single text span, all newline characters
                // are rendered as ' ' since a single text span is considered
                // a one line of text, it won't go to the next line
                rs := fontData.data[getCharIndex(#char " ")];
                x += rs.w + fontData.advance;
            } else if (c == #char "\n") {
                // when we are rendering a single text span, all newline characters
                // are rendered as ' ' since a single text span is considered
                // a one line of text, it won't go to the next line
                rs := fontData.data[getCharIndex(#char " ")];
                x += rs.w + fontData.advance;
            } else if (c == #char "\t") {
                rs := fontData.data[getCharIndex(#char " ")];
                x += TAB_WIDTH * rs.w + fontData.advance;
            } else {
                rs := fontData.data[getCharIndex(c)];
                rd := rect(x, y, rs.w, rs.h);

                #if DEBUG_RENDER_FONT {
                    nvgFillRect(gfx, rd, NVG_GREEN_SELECTION);
                }

                if (c != #char " ") {
                    nvgRenderBatchImage(gfx, batch, rs, rd, VEC2_ONE);
                }

                x += rs.w + fontData.advance;
            }

            index += 1;
            count -= 1;
        }

        nvgEndImageBatch(gfx, batch);
        nvgRestore(gfx);
    }

    return x;
}