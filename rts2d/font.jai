DEBUG_RENDER_FONT :: false;

FONT_NORMAL_COLOR :: Color.{ r = 239, g = 255, b = 219, a = 255 };
FONT_HIGHLIGHT_COLOR :: Color.{ r = 255, g = 227, b = 73, a = 255 };
NO_HIGHLIGHT : s32 : -1;
ALL_HIGHLIGHT : s32 : -2;
MAX_LINES : s32 : 48;
TAB_WIDTH : s32 : 2;

PRINTABLE_CHARS_COUNT :: 126 - 32 + 1; // last printable char - first printable char + 1

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

NVGTextSpan :: struct {
    start: *u8;
    end: *u8;
    width: f32;
}

nvgSplitTextIntoLines :: (text: *u8, maxLines: s32, lines: [] NVGTextSpan, width: f32, params: NVGfontParams) -> s32 {
    scale := params.fontSize / params.fontData.lineHeight;
    wrap := params.wrapping == .NVG_WRAP_WORD;
    x: f32 = 0;
    k: s32 = 0;

    s := text;
    e := text;
    while (k < maxLines) {
        c := <<e;

        if (c == #char "\0") {
            break;
        } else if (c == #char "\r") {
            // a new line is generated for each \r\n
            assert(<<(e + 1) == #char "\n");
            e += 1;

            lines[k].start = s;
            lines[k].end = e - 1;
            lines[k].width = x;
            k += 1;

            s = e + 1;
            x = 0;
        } else if (c == #char "\n") {
            // a new line is generated for each \n
            lines[k].start = s;
            lines[k].end = e;
            lines[k].width = x;
            k += 1;

            s = e + 1;
            x = 0;
        } else if (c == #char "\t") {
            rs := params.fontData.data[getCharIndex(#char " ")];
            dx := (TAB_WIDTH * rs.w + params.fontData.advance) * scale;

            // if the current character doesn't fit in the line generate a new line
            if (x + dx > width && wrap) {
                lines[k].start = s;
                lines[k].end = e;
                lines[k].width = x;
                k += 1;

                s = e;
                x = 0;
            }

            x += dx;
        } else {
            rs := params.fontData.data[getCharIndex(c)];
            dx := (rs.w + params.fontData.advance) * scale;

            // if the current character doesn't fit in the line generate a new line
            if (x + dx > width && wrap) {
                lines[k].start = s;
                lines[k].end = e;
                lines[k].width = x;
                k += 1;

                s = e;
                x = 0;
            }

            x += dx;
        }

        e += 1;
    }

    if (s < e && k < maxLines) {
        lines[k].start = s;
        lines[k].end = e;
        lines[k].width = x;
        k += 1;
    }

    // trim start and end spaces on lines
    if (params.trimming != .NVG_TRIM_NONE) {
        whiteSpaceData := params.fontData.data[getCharIndex(#char " ")];
        whiteSpaceWidth := (whiteSpaceData.w + params.fontData.advance) * scale;

        for i : range(s32, 0, k) {
            while (true) {
                if (lines[i].start[0] == #char " " && params.trimming >= .NVG_TRIM_SPACES) {
                    lines[i].width -= whiteSpaceWidth;
                    lines[i].start += 1;
                } else if (lines[i].start[0] == #char "\t" && params.trimming >= .NVG_TRIM_ALL) {
                    lines[i].width -= TAB_WIDTH * whiteSpaceWidth;
                    lines[i].start += 1;
                } else {
                    break;
                }
            }

            while (true) {
                if (lines[i].end[-1] == #char " " && params.trimming >= .NVG_TRIM_SPACES) {
                    lines[i].width -= whiteSpaceWidth;
                    lines[i].end -= 1;
                } else if (lines[i].end[-1] == #char "\t" && params.trimming >= .NVG_TRIM_ALL) {
                    lines[i].width -= TAB_WIDTH * whiteSpaceWidth;
                    lines[i].end -= 1;
                } else {
                    break;
                }
            }
        }
    }

    return k;
}

nvgMeasureSingleSpriteText :: (text: *u8, length: s32, params: NVGfontParams) -> Vec2 {
    scale := params.fontSize / params.fontData.lineHeight;

    size := VEC2_ZERO;

    e := text;
    while (length != 0) {
        c := <<e;
        if (c == #char "\0") {
            break;
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

        length -= 1;
        e += 1;
    }

    return size;
}

nvgMeasureMultiSpriteText :: (text: *u8, width: f32, params: NVGfontParams) -> Vec2 {
    scale := params.fontSize / params.fontData.lineHeight;
    lineHeight := ifx params.lineHeight > 0 then params.lineHeight else params.fontData.lineHeight;

    lines: [MAX_LINES] NVGTextSpan;
    linesCount := nvgSplitTextIntoLines(text, MAX_LINES, lines, params.boundings.x, params);

    size := VEC2_ZERO;

    for line : lines {
        size.x = max(size.x, line.width);
        size.y += lineHeight * scale;
    }

    return size;
}

nvgSingleSpriteTextSpan :: (gfx: *NVGcontext,
                            text: *u8,
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

        s := *text[index];
        e := s;

        while (count > 0) {
            if (boundings.x > 0 && x * scale > boundings.x) {
                break;
            }

            c := <<e;

            if (c == #char "\r") {
                assert(<<(e + 1) == #char "\n");
                e += 1;

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

            e += 1;
            count -= 1;
        }

        nvgEndImageBatch(gfx, batch);
        nvgRestore(gfx);
    }

    return x;
}

nvgSingleSpriteText :: (gfx: *NVGcontext, text: *u8, x: f32, y: f32, params: NVGfontParams) {
    scale := params.fontSize / params.fontData.lineHeight;
    textSize := nvgMeasureSingleSpriteText(text, -1, params);
    length := cast(s32) strlen(text);

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

nvgMultiSpriteText :: (gfx: *NVGcontext, text: *u8, x: f32, y: f32, params: NVGfontParams) {
    scale := params.fontSize / params.fontData.lineHeight;
    lineHeight := ifx params.lineHeight > 0 then params.lineHeight else params.fontData.lineHeight;

    lines: [MAX_LINES] NVGTextSpan;
    linesCount := nvgSplitTextIntoLines(text, MAX_LINES, lines, params.boundings.x, params);

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
        lineLength := cast(s32)(line.end - line.start);
        lineAlignOffset := getLineAlignmentOffset(params.lineAlign, textSize.x, line.width);
        lineOffset := vec2(lineAlignOffset, i * lineHeight);

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

            x = nvgSingleSpriteTextSpan(gfx, line.start,
                                        0, highlightIndex,
                                        0, 0,
                                        params.fontColor,
                                        params.fontData,
                                        params.boundings,
                                        scale);

            x = nvgSingleSpriteTextSpan(gfx, line.start,
                                        highlightIndex, highlightCount,
                                        x, 0,
                                        params.highlightColor,
                                        params.fontData,
                                        params.boundings,
                                        scale);

            x = nvgSingleSpriteTextSpan(gfx, line.start,
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

            x = nvgSingleSpriteTextSpan(gfx, line.start,
                                        0, highlightCount,
                                        0, 0,
                                        params.highlightColor,
                                        params.fontData,
                                        params.boundings,
                                        scale);

            x = nvgSingleSpriteTextSpan(gfx, line.start,
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

            nvgSingleSpriteTextSpan(gfx, line.start,
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
