import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dcanvas/dcanvas.dart' show Canvas;
import 'package:dcanvas/CanvasRenderingContext.dart' show Context2D, CSSColor, ImageData;
import 'package:drawlite_dart/drawlite.dart' show Color, KeyboardEvent, Key, KeyState;
import 'package:drawlite_dart/dl.dart';
import 'package:image/image.dart' as img;

import './app-state.dart';
import './view.dart';

// what dragging on the canvas does
enum Tool { brush, select, crop, shape, text }
Tool currentTool = Tool.brush;

class DocRect {
    double x, y, w, h;
    DocRect(this.x, this.y, this.w, this.h);

    // from two corners in any order
    factory DocRect.fromPoints(double x1, double y1, double x2, double y2) {
        return DocRect(min(x1, x2), min(y1, y2), (x2 - x1).abs(), (y2 - y1).abs());
    }

    bool contains(double px, double py) => px >= x && px <= x + w && py >= y && py <= y + h;

    // whole pixels inside the document
    DocRect clippedToDoc() {
        final x1 = x.floor().clamp(0, doc.width), y1 = y.floor().clamp(0, doc.height);
        final x2 = (x + w).ceil().clamp(0, doc.width), y2 = (y + h).ceil().clamp(0, doc.height);
        return DocRect(x1.toDouble(), y1.toDouble(), (x2 - x1).toDouble(), (y2 - y1).toDouble());
    }
}

void setTool(Tool tool) {
    if (tool == currentTool) return;
    finishTool();
    currentTool = tool;
    if (tool == Tool.crop) {
        cropRect = DocRect(0, 0, doc.width.toDouble(), doc.height.toDouble());
    }
}

// commits anything in progress (floating selection, text being typed) to the document
void finishTool() {
    commitFloating();
    commitText();
}

// forgets tool state that refers to the old document after New/Open
void resetToolState() {
    selection = null;
    floating = null;
    textEdit = null;
    _dragStart = null;
    if (currentTool == Tool.crop) {
        currentTool = Tool.brush;
    }
}

// ---------------------------------------------------------------- crop

DocRect? cropRect;
// doc coordinates where the current drag started
(double, double)? _dragStart;

void applyCrop() {
    final rect = cropRect?.clippedToDoc();
    if (rect != null && rect.w >= 1 && rect.h >= 1) {
        doc.crop(rect.x.toInt(), rect.y.toInt(), rect.w.toInt(), rect.h.toInt());
    }
    cropRect = null;
    currentTool = Tool.brush;
}

void cancelCrop() {
    cropRect = null;
    currentTool = Tool.brush;
}

// ---------------------------------------------------------------- select

DocRect? selection;

class FloatingImage {
    Canvas canvas;
    double x, y;
    FloatingImage(this.canvas, this.x, this.y);
}
// pixels lifted off the document while they're being moved or after pasting
FloatingImage? floating;
bool _movingSelection = false;
double _grabX = 0, _grabY = 0;

// internal clipboard, used when no system clipboard tool is installed
ImageData? _clipboard;

Canvas _canvasFromPixels(ImageData pixels) {
    final canvas = Canvas(pixels.width, pixels.height);
    canvas.getContext("2d").putImageData(pixels, 0, 0);
    return canvas;
}

ImageData? _selectedPixels() {
    final float = floating;
    if (float != null) {
        return float.canvas.getContext("2d").getImageData(0, 0, float.canvas.width, float.canvas.height);
    }
    final rect = selection?.clippedToDoc();
    if (rect == null || rect.w < 1 || rect.h < 1) return null;
    return doc.ctx.getImageData(rect.x, rect.y, rect.w, rect.h);
}

void _clearRect(DocRect rect) {
    doc.ctx.fillStyle = CSSColor(255, 255, 255, 1);
    doc.ctx.fillRect(rect.x, rect.y, rect.w, rect.h);
}

// cuts the selected pixels out of the document so they can be moved
void _liftSelection() {
    final rect = selection?.clippedToDoc();
    if (rect == null || rect.w < 1 || rect.h < 1) return;
    doc.beginChange();
    final pixels = doc.ctx.getImageData(rect.x, rect.y, rect.w, rect.h);
    _clearRect(rect);
    floating = FloatingImage(_canvasFromPixels(pixels), rect.x, rect.y);
}

void commitFloating() {
    final float = floating;
    if (float == null) return;
    doc.ctx.drawImage(float.canvas, float.x.round(), float.y.round());
    selection = DocRect(float.x.roundToDouble(), float.y.roundToDouble(), float.canvas.width.toDouble(), float.canvas.height.toDouble());
    floating = null;
}

void selectAll() {
    setTool(Tool.select);
    commitFloating();
    selection = DocRect(0, 0, doc.width.toDouble(), doc.height.toDouble());
}

void deleteSelection() {
    if (floating != null) {
        // the area under it was already cleared when it was lifted
        floating = null;
        selection = null;
        return;
    }
    final rect = selection?.clippedToDoc();
    if (rect == null || rect.w < 1 || rect.h < 1) return;
    doc.beginChange();
    _clearRect(rect);
}

void copySelection() {
    final pixels = _selectedPixels();
    if (pixels == null) return;
    _clipboard = pixels;
    _writeSystemClipboard(pixels);
}

void cutSelection() {
    copySelection();
    deleteSelection();
}

void paste() {
    final pixels = _readSystemClipboard() ?? _clipboard;
    if (pixels == null) return;
    setTool(Tool.select);
    commitFloating();
    doc.beginChange();
    floating = FloatingImage(_canvasFromPixels(pixels), 0, 0);
    selection = DocRect(0, 0, pixels.width.toDouble(), pixels.height.toDouble());
}

bool get canPaste => _clipboard != null || _hasXclip;

final bool _hasXclip = (() {
    try {
        return Process.runSync("which", ["xclip"]).exitCode == 0;
    } catch (e) {
        return false;
    }
})();

void _writeSystemClipboard(ImageData pixels) {
    if (!_hasXclip) return;
    try {
        final image = img.Image.fromBytes(
            width: pixels.width, height: pixels.height,
            bytes: Uint8List.fromList(pixels.data).buffer, numChannels: 4, order: img.ChannelOrder.rgba
        );
        final png = img.encodePng(image);
        Process.start("xclip", ["-selection", "clipboard", "-t", "image/png", "-i"]).then((proc) {
            proc.stdin.add(png);
            proc.stdin.close();
        });
    } catch (e) {
        // the internal clipboard still works
    }
}

ImageData? _readSystemClipboard() {
    if (!_hasXclip) return null;
    try {
        final targets = Process.runSync("xclip", ["-selection", "clipboard", "-t", "TARGETS", "-o"]);
        if (!targets.stdout.toString().contains("image/png")) return null;
        final result = Process.runSync("xclip", ["-selection", "clipboard", "-t", "image/png", "-o"], stdoutEncoding: null);
        final decoded = img.decodePng(Uint8List.fromList(result.stdout as List<int>));
        if (decoded == null) return null;
        final rgba = decoded.convert(format: img.Format.uint8, numChannels: 4, alpha: 255);
        return ImageData(rgba.getBytes(order: img.ChannelOrder.rgba), rgba.width, rgba.height);
    } catch (e) {
        return null;
    }
}

// ---------------------------------------------------------------- shapes

enum ShapeKind { line, rectangle, ellipse, triangle, arrow }
ShapeKind currentShape = ShapeKind.rectangle;
bool shapeFilled = false;
double shapeThickness = 5;

(double, double)? _shapeEnd;

void drawShape(Context2D ctx, ShapeKind kind, double x1, double y1, double x2, double y2,
        Color color, double thickness, bool filled) {
    ctx.save();
    final clr = CSSColor(color.r, color.g, color.b, color.a / 255);
    ctx.strokeStyle = clr;
    ctx.fillStyle = clr;
    ctx.lineWidth = thickness;
    ctx.lineJoin = "round";
    ctx.lineCap = "round";
    ctx.beginPath();

    final x = min(x1, x2), y = min(y1, y2);
    final w = (x2 - x1).abs(), h = (y2 - y1).abs();
    switch (kind) {
        case ShapeKind.line:
            ctx.moveTo(x1, y1);
            ctx.lineTo(x2, y2);
        case ShapeKind.rectangle:
            ctx.moveTo(x, y);
            ctx.lineTo(x + w, y);
            ctx.lineTo(x + w, y + h);
            ctx.lineTo(x, y + h);
            ctx.closePath();
        case ShapeKind.ellipse:
            if (w > 0 && h > 0) {
                ctx.ellipse(x + w / 2, y + h / 2, w / 2, h / 2, 0, 0, 2 * pi);
            }
        case ShapeKind.triangle:
            ctx.moveTo(x + w / 2, y);
            ctx.lineTo(x + w, y + h);
            ctx.lineTo(x, y + h);
            ctx.closePath();
        case ShapeKind.arrow:
            final angle = atan2(y2 - y1, x2 - x1);
            final len = sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1));
            final head = min(max(thickness * 4, 18.0), len * 0.5);
            ctx.moveTo(x1, y1);
            ctx.lineTo(x2, y2);
            ctx.moveTo(x2 - head * cos(angle - pi / 6), y2 - head * sin(angle - pi / 6));
            ctx.lineTo(x2, y2);
            ctx.lineTo(x2 - head * cos(angle + pi / 6), y2 - head * sin(angle + pi / 6));
    }

    final canFill = kind != ShapeKind.line && kind != ShapeKind.arrow;
    if (filled && canFill) {
        ctx.fill();
    } else {
        ctx.stroke();
    }
    ctx.restore();
}

// holding shift makes squares, circles and 45 degree lines
(double, double) _constrainShapeEnd(double x1, double y1, double x2, double y2) {
    if (!KeyState.isShiftPressed()) return (x2, y2);
    final dx = x2 - x1, dy = y2 - y1;
    if (currentShape == ShapeKind.line || currentShape == ShapeKind.arrow) {
        final angle = (atan2(dy, dx) / (pi / 4)).round() * (pi / 4);
        final len = sqrt(dx * dx + dy * dy);
        return (x1 + cos(angle) * len, y1 + sin(angle) * len);
    }
    final size = max(dx.abs(), dy.abs());
    return (x1 + size * dx.sign, y1 + size * dy.sign);
}

// ---------------------------------------------------------------- text

double textToolSize = 32;
bool textToolBold = false;

class TextEdit {
    double x, y;
    String text = "";
    TextEdit(this.x, this.y);
}
TextEdit? textEdit;

String textFont() => "${textToolBold ? "bold " : ""}${textToolSize.round()}px \"Open Sans\", sans-serif";

void _drawText(Context2D ctx, TextEdit edit, Color color) {
    ctx.save();
    ctx.font = textFont();
    ctx.fillStyle = CSSColor(color.r, color.g, color.b, color.a / 255);
    final lines = edit.text.split("\n");
    for (var i = 0; i < lines.length; i++) {
        ctx.fillText(lines[i], edit.x, edit.y + textToolSize * (i + 1) * 1.2 - textToolSize * 0.2);
    }
    ctx.restore();
}

void commitText() {
    final edit = textEdit;
    if (edit == null) return;
    textEdit = null;
    if (edit.text.trim().isEmpty) return;
    doc.beginChange();
    _drawText(doc.ctx, edit, currColor);
}

// US keyboard layout, for turning key codes into characters
const _shiftedSymbols = {
    "1": "!", "2": "@", "3": "#", "4": "\$", "5": "%", "6": "^", "7": "&", "8": "*", "9": "(", "0": ")",
    "-": "_", "=": "+", "[": "{", "]": "}", "\\": "|", ";": ":", "'": "\"", ",": "<", ".": ">", "/": "?", "`": "~",
};

String? _charForKey(int code) {
    if (code < 32 || code >= 127) return null;
    final ch = String.fromCharCode(code);
    if (!KeyState.isShiftPressed()) return ch;
    if (ch.toLowerCase() != ch.toUpperCase()) return ch.toUpperCase();
    return _shiftedSymbols[ch] ?? ch;
}

// ---------------------------------------------------------------- input

// all coordinates are in document pixels
void toolMousePressed(double x, double y) {
    switch (currentTool) {
        case Tool.crop:
            _dragStart = (x.clamp(0, doc.width.toDouble()), y.clamp(0, doc.height.toDouble()));
        case Tool.select:
            final float = floating;
            final overFloat = float != null &&
                DocRect(float.x, float.y, float.canvas.width.toDouble(), float.canvas.height.toDouble()).contains(x, y);
            final overSelection = float == null && (selection?.contains(x, y) ?? false);
            if (overSelection) {
                _liftSelection();
            }
            if (overFloat || overSelection) {
                _movingSelection = true;
                _grabX = x - floating!.x;
                _grabY = y - floating!.y;
            } else {
                commitFloating();
                selection = null;
                _dragStart = (x, y);
            }
        case Tool.shape:
            _dragStart = (x, y);
            _shapeEnd = (x, y);
        case Tool.text:
            commitText();
            textEdit = TextEdit(x, y);
        case Tool.brush:
            break;
    }
}

void toolMouseDragged(double x, double y) {
    final start = _dragStart;
    switch (currentTool) {
        case Tool.crop:
            if (start != null) {
                cropRect = DocRect.fromPoints(start.$1, start.$2,
                    x.clamp(0, doc.width.toDouble()), y.clamp(0, doc.height.toDouble()));
            }
        case Tool.select:
            if (_movingSelection && floating != null) {
                floating!.x = x - _grabX;
                floating!.y = y - _grabY;
            } else if (start != null) {
                selection = DocRect.fromPoints(start.$1, start.$2, x, y);
            }
        case Tool.shape:
            if (start != null) {
                _shapeEnd = _constrainShapeEnd(start.$1, start.$2, x, y);
            }
        default:
            break;
    }
}

void toolMouseReleased() {
    final start = _dragStart;
    _dragStart = null;
    switch (currentTool) {
        case Tool.crop:
            final rect = cropRect;
            if (rect == null || rect.w < 2 || rect.h < 2) {
                cropRect = DocRect(0, 0, doc.width.toDouble(), doc.height.toDouble());
            }
        case Tool.select:
            if (_movingSelection) {
                _movingSelection = false;
                final float = floating;
                if (float != null) {
                    selection = DocRect(float.x, float.y, float.canvas.width.toDouble(), float.canvas.height.toDouble());
                }
            } else if (selection != null && (selection!.w < 2 || selection!.h < 2)) {
                selection = null;
            }
        case Tool.shape:
            final end = _shapeEnd;
            _shapeEnd = null;
            if (start != null && end != null && (end.$1 != start.$1 || end.$2 != start.$2)) {
                doc.beginChange();
                drawShape(doc.ctx, currentShape, start.$1, start.$2, end.$1, end.$2, currColor, shapeThickness, shapeFilled);
            }
        default:
            break;
    }
}

// returns true if the key was used
bool toolKeyPressed(KeyboardEvent event) {
    final code = event.keyCode;
    switch (currentTool) {
        case Tool.crop:
            if (code == Key.Enter) {
                applyCrop();
                return true;
            } else if (code == Key.Escape) {
                cancelCrop();
                return true;
            }
        case Tool.select:
            if (code == Key.Delete || code == Key.Backspace) {
                deleteSelection();
                return true;
            } else if (code == Key.Enter || code == Key.Escape) {
                commitFloating();
                selection = null;
                return true;
            }
        case Tool.text:
            final edit = textEdit;
            if (edit == null) return false;
            if (code == Key.Escape) {
                commitText();
            } else if (code == Key.Enter) {
                edit.text += "\n";
            } else if (code == Key.Backspace) {
                if (edit.text.isNotEmpty) edit.text = edit.text.substring(0, edit.text.length - 1);
            } else {
                final ch = _charForKey(code);
                if (ch == null) return false;
                edit.text += ch;
            }
            return true;
        default:
            break;
    }
    return false;
}

// true while typing, so letter keys aren't treated as shortcuts
bool get isTyping => currentTool == Tool.text && textEdit != null;

// ---------------------------------------------------------------- rendering

// outline that shows on both light and dark pixels
void _outlineRect(double x, double y, double w, double h) {
    noFill();
    strokeWeight(1);
    stroke(255);
    rect(x, y, w, h);
    stroke(0, 0, 0, 160);
    rect(x - 1, y - 1, w + 2, h + 2);
}

// draws what's being drawn with the shape and text tools, which gets
// clipped to the document like brush strokes
void renderToolPreview() {
    final ctx = dl.ctx;
    switch (currentTool) {
        case Tool.shape:
            final start = _dragStart, end = _shapeEnd;
            if (start != null && end != null) {
                ctx.save();
                ctx.translate(viewX, viewY);
                ctx.scale(viewZoom, viewZoom);
                drawShape(ctx, currentShape, start.$1, start.$2, end.$1, end.$2, currColor, shapeThickness, shapeFilled);
                ctx.restore();
            }
        case Tool.text:
            final edit = textEdit;
            if (edit == null) break;
            ctx.save();
            ctx.translate(viewX, viewY);
            ctx.scale(viewZoom, viewZoom);
            _drawText(ctx, edit, currColor);
            ctx.restore();
        default:
            break;
    }
}

// draws tool UI over the document, in logical screen coordinates
void renderToolOverlay() {
    final ctx = dl.ctx;
    switch (currentTool) {
        case Tool.crop:
            final area = cropRect;
            if (area == null) break;
            final dx = viewX, dy = viewY, dw = doc.width * viewZoom, dh = doc.height * viewZoom;
            final rx = toScreenX(area.x), ry = toScreenY(area.y), rw = area.w * viewZoom, rh = area.h * viewZoom;
            // darken what will be cropped away
            noStroke();
            fill(0, 0, 0, 120);
            rect(dx, dy, dw, ry - dy);
            rect(dx, ry + rh, dw, dy + dh - ry - rh);
            rect(dx, ry, rx - dx, rh);
            rect(rx + rw, ry, dx + dw - rx - rw, rh);
            _outlineRect(rx, ry, rw, rh);
        case Tool.select:
            final float = floating;
            if (float != null) {
                image(float.canvas, toScreenX(float.x), toScreenY(float.y),
                    float.canvas.width * viewZoom, float.canvas.height * viewZoom);
            }
            final area = selection;
            if (area != null) {
                _outlineRect(toScreenX(area.x), toScreenY(area.y), area.w * viewZoom, area.h * viewZoom);
            }
        case Tool.text:
            final edit = textEdit;
            if (edit == null) break;
            // blinking cursor after the last character
            if (DateTime.now().millisecondsSinceEpoch % 1000 < 600) {
                ctx.save();
                ctx.font = textFont();
                final lines = edit.text.split("\n");
                final lineWidth = ctx.measureText(lines.last).width;
                ctx.restore();
                final cx = toScreenX(edit.x + lineWidth + 1);
                final cy = toScreenY(edit.y + textToolSize * (lines.length - 1) * 1.2);
                stroke(0);
                strokeWeight(1);
                line(cx, cy, cx, cy + textToolSize * 1.2 * viewZoom);
            }
        default:
            break;
    }
}
