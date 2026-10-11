import 'dart:math';
import 'dart:typed_data';

import 'package:dcanvas/CanvasRenderingContext.dart' show Context2D, CSSColor, ImageData;
import 'package:drawlite_dart/drawlite.dart'
    show Color;

import './app-state.dart';

List<String> brushNames = [
    "Marker",
    "Calligraphy pen",
    "Oil brush",
    "Watercolor",
    "Pixel pen",
    "Pencil",
    "Eraser",
    "Crayon",
    "Spray can",
    "Fill bucket"
];

List<Color> brushColors = [];
void initBrushColors() {
    brushColors = [
        dl.color(255),
        dl.color(195),
        dl.color(88),
        dl.color(0),
        dl.color(136, 0, 27),
        dl.color(236, 28, 36),
        dl.color(255, 127, 39),
        dl.color(255, 202, 24),
        dl.color(253, 236, 166),
        dl.color(255, 242, 0),
        dl.color(196, 255, 14),
        dl.color(14, 209, 69),
        dl.color(140, 255, 251),
        dl.color(0, 168, 243),
        dl.color(63, 72, 204),
        dl.color(184, 61, 186),
        dl.color(255, 174, 200),
        dl.color(185, 122, 86)
    ];
}

// brush ids, matching the order of brushNames and the sidebar icons
const MARKER = 0;
const CALLIGRAPHY_PEN = 1;
const OIL_BRUSH = 2;
const WATERCOLOR = 3;
const PIXEL_PEN = 4;
const PENCIL = 5;
const ERASER = 6;
const CRAYON = 7;
const SPRAY_CAN = 8;
const FILL_BUCKET = 9;

// the canvas background, which the eraser paints with
final ERASER_COLOR = Color(255, 255, 255);

class BrushStroke {
    late Color color;
    late double weight;
    // 0-100
    late double opacity;
    late int brushId;
    List<double> points = [];
    // texture dots for the spray can and crayon, generated once per point so they don't flicker
    List<double> dots = [];
    // squares covered by the pixel pen, so overlapping squares aren't drawn twice
    Set<int> pixelCells = {};
    final _rand = Random();

    BrushStroke(this.color, this.weight, this.opacity, this.brushId) {
        if (brushId == ERASER) {
            color = ERASER_COLOR;
        }
    }

    void addPoint(double x, double y) {
        if (points.isEmpty) {
            _addTexture(x, y);
        } else {
            // fill in the gap from the last point so fast mouse movements don't leave holes
            final px = points[points.length - 2];
            final py = points[points.length - 1];
            final dist = sqrt((x - px) * (x - px) + (y - py) * (y - py));
            final step = max(1.0, weight / 4);
            final steps = max(1, (dist / step).ceil());
            for (var i = 1; i <= steps; i++) {
                _addTexture(px + (x - px) * i / steps, py + (y - py) * i / steps);
            }
        }
        points.add(x);
        points.add(y);
    }

    void _addTexture(double x, double y) {
        final r = weight / 2;
        if (brushId == SPRAY_CAN) {
            // uniformly spread within a circle
            for (int i = 0; i < 3; i++) {
                final a = _rand.nextDouble() * 2 * pi;
                final d = sqrt(_rand.nextDouble()) * r;
                dots.add(x + cos(a) * d);
                dots.add(y + sin(a) * d);
            }
        } else if (brushId == CRAYON) {
            // dense but patchy coverage
            final count = max(2, (r * 1.5).round());
            for (int i = 0; i < count; i++) {
                final a = _rand.nextDouble() * 2 * pi;
                final d = _rand.nextDouble() * r;
                dots.add(x + cos(a) * d);
                dots.add(y + sin(a) * d);
            }
        } else if (brushId == PIXEL_PEN) {
            final size = max(1, weight.round());
            final cx = (x / size).floor();
            final cy = (y / size).floor();
            pixelCells.add(cx * 65536 + cy);
        }
    }

    CSSColor cssColor([double alphaScale = 1]) {
        return CSSColor(color.r, color.g, color.b, color.a / 255 * opacity / 100 * alphaScale);
    }

    CSSColor shadeColor(int amount, [double alphaScale = 1]) {
        int c(int v) => (v + amount).clamp(0, 255);
        return CSSColor(c(color.r), c(color.g), c(color.b), color.a / 255 * opacity / 100 * alphaScale);
    }

    void render(Context2D ctx) {
        if (points.isEmpty) return;
        ctx.save();
        switch (this.brushId) {
            case MARKER:
            case ERASER:
                _strokePath(ctx, cssColor(), weight);
            case CALLIGRAPHY_PEN:
                _renderCalligraphy(ctx);
            case OIL_BRUSH:
                _renderOil(ctx);
            case WATERCOLOR:
                _renderWatercolor(ctx);
            case PIXEL_PEN:
                _renderPixels(ctx);
            case PENCIL:
                _strokePath(ctx, cssColor(0.85), max(1.0, weight * 0.4));
            case CRAYON:
                _renderDots(ctx, cssColor(0.8), max(1.5, weight / 12));
            case SPRAY_CAN:
                _renderDots(ctx, cssColor(), 1);
        }
        ctx.restore();
    }

    // draws the points as a single path so overlapping segments don't darken translucent strokes
    void _strokePath(Context2D ctx, CSSColor clr, double lineWidth, [double dx = 0, double dy = 0]) {
        if (points.length == 2) {
            ctx.fillStyle = clr;
            ctx.beginPath();
            ctx.arc(points[0] + dx, points[1] + dy, lineWidth / 2, 0, 2 * pi);
            ctx.fill();
            return;
        }
        ctx.strokeStyle = clr;
        ctx.lineWidth = lineWidth;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";
        ctx.beginPath();
        ctx.moveTo(points[0] + dx, points[1] + dy);
        for (var i = 2; i < points.length; i += 2) {
            ctx.lineTo(points[i] + dx, points[i+1] + dy);
        }
        ctx.stroke();
    }

    void _renderCalligraphy(Context2D ctx) {
        // a flat nib held at 45 degrees: thick strokes one way, thin the other
        final nx = cos(pi / 4) * weight / 2;
        final ny = -sin(pi / 4) * weight / 2;
        final thin = max(1.0, weight / 8) / 2;
        ctx.fillStyle = cssColor();
        ctx.beginPath();
        if (points.length == 2) {
            _addQuad(ctx, points[0], points[1], points[0], points[1], nx, ny, thin);
        }
        for (var i = 0; i + 3 < points.length; i += 2) {
            _addQuad(ctx, points[i], points[i+1], points[i+2], points[i+3], nx, ny, thin);
        }
        // nonzero winding unions the quads since they all wind the same way
        ctx.fill();
    }

    void _addQuad(Context2D ctx, double ax, double ay, double bx, double by, double nx, double ny, double thin) {
        // perpendicular padding so strokes parallel to the nib still have some width
        var px = -(by - ay), py = bx - ax;
        final len = sqrt(px * px + py * py);
        if (len > 0) { px = px / len * thin; py = py / len * thin; } else { px = thin; py = 0; }
        final ox = nx + px, oy = ny + py;
        final quad = [ax - ox, ay - oy, ax + ox, ay + oy, bx + ox, by + oy, bx - ox, by - oy];
        // signed area, so every quad can be wound counterclockwise
        var area = 0.0;
        for (var i = 0; i < 8; i += 2) {
            area += quad[i] * quad[(i + 3) % 8] - quad[(i + 2) % 8] * quad[i + 1];
        }
        final order = area >= 0 ? [0, 2, 4, 6] : [6, 4, 2, 0];
        ctx.moveTo(quad[order[0]], quad[order[0] + 1]);
        for (final i in order.skip(1)) {
            ctx.lineTo(quad[i], quad[i + 1]);
        }
        ctx.closePath();
    }

    void _renderOil(Context2D ctx) {
        // a thick base with lighter and darker bristle streaks on top
        _strokePath(ctx, cssColor(), weight);
        if (weight < 6) return;
        final streak = max(1.0, weight / 8);
        final offsets = [-0.3, -0.1, 0.15, 0.35];
        for (var i = 0; i < offsets.length; i++) {
            final off = offsets[i] * weight;
            final shade = i.isEven ? 40 : -40;
            _strokePath(ctx, shadeColor(shade, 0.35), streak, off * 0.7, off * 0.7);
        }
    }

    void _renderWatercolor(Context2D ctx) {
        // translucent layers with a wider, fainter edge
        _strokePath(ctx, cssColor(0.15), weight * 1.4);
        _strokePath(ctx, cssColor(0.3), weight);
    }

    void _renderPixels(Context2D ctx) {
        final size = max(1, weight.round());
        ctx.fillStyle = cssColor();
        for (final cell in pixelCells) {
            final cx = cell ~/ 65536;
            final cy = cell % 65536;
            ctx.fillRect(cx * size, cy * size, size, size);
        }
    }

    void _renderDots(Context2D ctx, CSSColor clr, double size) {
        ctx.fillStyle = clr;
        for (var i = 0; i < dots.length; i += 2) {
            ctx.fillRect(dots[i] - size / 2, dots[i+1] - size / 2, size, size);
        }
    }
}

// fills the area around (x, y) that's similar in color to the clicked pixel
void floodFill(ImageData img, int x, int y, Color color, double opacity, [int tolerance = 64]) {
    final w = img.width, h = img.height;
    if (x < 0 || y < 0 || x >= w || y >= h) return;
    final data = img.data;

    final start = (y * w + x) * 4;
    final sr = data[start], sg = data[start + 1], sb = data[start + 2];
    bool matches(int i) {
        return (data[i] - sr).abs() <= tolerance &&
            (data[i + 1] - sg).abs() <= tolerance &&
            (data[i + 2] - sb).abs() <= tolerance;
    }

    final alpha = color.a / 255 * opacity / 100;
    final visited = Uint8List(w * h);
    final stack = <int>[x, y];
    while (stack.isNotEmpty) {
        final py = stack.removeLast();
        var px = stack.removeLast();

        // move to the left end of this run, then fill rightwards
        while (px > 0 && visited[py * w + px - 1] == 0 && matches((py * w + px - 1) * 4)) {
            px--;
        }
        var spanUp = false, spanDown = false;
        while (px < w && visited[py * w + px] == 0 && matches((py * w + px) * 4)) {
            final i = (py * w + px) * 4;
            visited[py * w + px] = 1;
            data[i] = (data[i] + (color.r - data[i]) * alpha).round();
            data[i + 1] = (data[i + 1] + (color.g - data[i + 1]) * alpha).round();
            data[i + 2] = (data[i + 2] + (color.b - data[i + 2]) * alpha).round();
            data[i + 3] = 255;

            for (final (ny, isUp) in [(py - 1, true), (py + 1, false)]) {
                if (ny < 0 || ny >= h) continue;
                final open = visited[ny * w + px] == 0 && matches((ny * w + px) * 4);
                final spanning = isUp ? spanUp : spanDown;
                if (open && !spanning) {
                    stack.add(px);
                    stack.add(ny);
                }
                if (isUp) spanUp = open; else spanDown = open;
            }
            px++;
        }
    }
}
