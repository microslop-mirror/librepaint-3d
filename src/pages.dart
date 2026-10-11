import 'dart:typed_data';

import 'package:drawlite_dart/drawlite.dart' show KeyboardEvent, Color;
import 'package:drawlite_dart/dl.dart';
import 'package:drawlite_dart/drawlite-touch.dart';
import 'package:image/image.dart' as img;

import './app-state.dart';
import './sidebar.dart';
import './Slider.dart';
import './TextBox.dart';
import './tools.dart';

// sidebar pages other than brushes

const _PAD = 24;

// a checkbox with a label; returns its hit area height
void renderCheckbox(double x, double y, String label, bool checked) {
    rectMode(CORNER);
    strokeWeight(1);
    stroke(120);
    fill(checked ? Color(0, 100, 180) : Color(255, 255, 255));
    rect(x, y, 18, 18);
    if (checked) {
        stroke(255);
        strokeWeight(2);
        line(x + 4, y + 9, x + 8, y + 13);
        line(x + 8, y + 13, x + 14, y + 5);
    }
    noStroke();
    fill(0);
    font("Open Sans", 13);
    textAlign(LEFT, CENTER);
    text(label, x + 28, y + 9);
    textAlign(LEFT, BASELINE);
}

bool checkboxHit(double x, double y) {
    return point_rect(get.mouseX, get.mouseY, x, y - 3, SIDEBAR_WIDTH - _PAD * 2, 24);
}

void _label(String str, double x, double y) {
    noStroke();
    fill(0);
    font("Open Sans", 12);
    textAlign(BASELINE);
    text(str, x, y);
}

// ---------------------------------------------------------------- 2D shapes

class ShapesPage extends SidebarPage {
    late Slider thicknessSlider;

    static const _shapes = ShapeKind.values;

    void init() {
        thicknessSlider = Slider(sidebarX + _PAD, 270, 1, 50, shapeThickness);
        initialized = true;
    }

    double get _fillY => 170;

    void mousePressed() {
        for (var i = 0; i < _shapes.length; i++) {
            if (point_rect(get.mouseX, get.mouseY, sidebarX + 25 + i * 44, sidebarY + 61, 40, 40)) {
                currentShape = _shapes[i];
                return;
            }
        }
        if (checkboxHit(sidebarX + _PAD, _fillY)) {
            shapeFilled = !shapeFilled;
            return;
        }
        thicknessSlider.setPressed(thicknessSlider.hoveredOver(get.mouseX, get.mouseY));
        colorSectionMousePressed();
    }

    void mouseReleased() {
        thicknessSlider.setPressed(false);
    }

    bool get isActive => initialized && thicknessSlider.pressed;

    void render(int mouseX, int mouseY) {
        for (var i = 0; i < _shapes.length; i++) {
            final x = sidebarX + 25 + i * 44;
            final y = sidebarY + 61;
            final selected = _shapes[i] == currentShape;
            noStroke();
            if (selected) {
                fill(5, 100, 185);
                rect(x, y, 40, 40);
            } else if (point_rect(mouseX, mouseY, x, y, 40, 40)) {
                fill(0, 0, 0, 20);
                rect(x, y, 40, 40);
            }
            final glyph = selected ? Color(255, 255, 255) : Color(40, 40, 40);
            drawShape(dl.ctx, _shapes[i], x + 10, y + 10, x + 30, y + 30, glyph, 2, false);
        }

        renderCheckbox(sidebarX + _PAD, _fillY, "Fill shape", shapeFilled);

        _label("Thickness", sidebarX + 26, 245);
        textAlign(RIGHT, BASELINE);
        text("${shapeThickness.round()}px", sidebarX + SIDEBAR_WIDTH - _PAD, 245);
        textAlign(LEFT, BASELINE);
        thicknessSlider.x = sidebarX + _PAD;
        thicknessSlider.render();
        shapeThickness = thicknessSlider.value.roundToDouble();

        _label("Drag on the canvas to draw.", sidebarX + 26, 320);
        _label("Hold Shift for squares, circles", sidebarX + 26, 338);
        _label("and straight lines.", sidebarX + 26, 356);

        renderColorSection(mouseX, mouseY);
    }
}

// ---------------------------------------------------------------- text

class TextPage extends SidebarPage {
    late Slider sizeSlider;

    void init() {
        sizeSlider = Slider(sidebarX + _PAD, 150, 8, 120, textToolSize);
        initialized = true;
    }

    double get _boldY => 185;

    void mousePressed() {
        if (checkboxHit(sidebarX + _PAD, _boldY)) {
            textToolBold = !textToolBold;
            return;
        }
        sizeSlider.setPressed(sizeSlider.hoveredOver(get.mouseX, get.mouseY));
        colorSectionMousePressed();
    }

    void mouseReleased() {
        sizeSlider.setPressed(false);
    }

    bool get isActive => initialized && sizeSlider.pressed;

    void render(int mouseX, int mouseY) {
        _label("Size", sidebarX + 26, 125);
        textAlign(RIGHT, BASELINE);
        text("${textToolSize.round()}px", sidebarX + SIDEBAR_WIDTH - _PAD, 125);
        textAlign(LEFT, BASELINE);
        sizeSlider.x = sidebarX + _PAD;
        sizeSlider.render();
        textToolSize = sizeSlider.value.roundToDouble();

        renderCheckbox(sidebarX + _PAD, _boldY, "Bold", textToolBold);

        _label("Click on the canvas and type.", sidebarX + 26, 240);
        _label("Press Esc or click elsewhere to finish.", sidebarX + 26, 258);
        _label("Only English letters and symbols", sidebarX + 26, 282);
        _label("can be typed for now.", sidebarX + 26, 300);

        renderColorSection(mouseX, mouseY);
    }
}

// ---------------------------------------------------------------- effects

class _Effect {
    final String name;
    final img.Image Function(img.Image) apply;
    const _Effect(this.name, this.apply);
}

final _effects = [
    _Effect("Grayscale", (i) => img.grayscale(i)),
    _Effect("Sepia", (i) => img.sepia(i)),
    _Effect("Invert colors", (i) => img.invert(i)),
    _Effect("Brighten", (i) => img.adjustColor(i, brightness: 1.15)),
    _Effect("Darken", (i) => img.adjustColor(i, brightness: 0.87)),
    _Effect("More contrast", (i) => img.adjustColor(i, contrast: 1.2)),
    _Effect("Blur", (i) => img.gaussianBlur(i, radius: 2)),
    _Effect("Sharpen", (i) => img.convolution(i, filter: [0, -1, 0, -1, 5, -1, 0, -1, 0])),
];

const _EFFECT_Y = 105;
const _EFFECT_HEIGHT = 40;

void applyEffect(img.Image Function(img.Image) effect) {
    finishTool();
    doc.beginChange();
    final pixels = doc.getPixels();
    final image = img.Image.fromBytes(
        width: pixels.width, height: pixels.height,
        bytes: Uint8List.fromList(pixels.data).buffer, numChannels: 4, order: img.ChannelOrder.rgba
    );
    final result = effect(image);
    final bytes = result.getBytes(order: img.ChannelOrder.rgba);
    pixels.data.setRange(0, pixels.data.length, bytes);
    doc.ctx.putImageData(pixels, 0, 0);
}

class EffectsPage extends SidebarPage {
    void init() {
        initialized = true;
    }

    void mousePressed() {
        for (var i = 0; i < _effects.length; i++) {
            if (point_rect(get.mouseX, get.mouseY, sidebarX + _PAD, _EFFECT_Y + i * _EFFECT_HEIGHT, SIDEBAR_WIDTH - _PAD * 2, _EFFECT_HEIGHT - 4)) {
                applyEffect(_effects[i].apply);
                onCanvasChanged();
                return;
            }
        }
    }

    void render(int mouseX, int mouseY) {
        for (var i = 0; i < _effects.length; i++) {
            final x = sidebarX + _PAD, y = (_EFFECT_Y + i * _EFFECT_HEIGHT).toDouble();
            final w = SIDEBAR_WIDTH - _PAD * 2.0, h = _EFFECT_HEIGHT - 4.0;
            noStroke();
            fill(point_rect(mouseX, mouseY, x, y, w, h) ? 225 : 250);
            rect(x, y, w, h);
            stroke(215);
            noFill();
            rect(x, y, w, h);
            noStroke();
            fill(0);
            font("Open Sans", 13);
            textAlign(LEFT, CENTER);
            text(_effects[i].name, x + 14, y + h / 2);
        }
        textAlign(LEFT, BASELINE);
        _label("Effects apply to the whole picture", sidebarX + 26, _EFFECT_Y + _effects.length * _EFFECT_HEIGHT + 20);
        _label("and can be undone.", sidebarX + 26, _EFFECT_Y + _effects.length * _EFFECT_HEIGHT + 38);
    }
}

// ---------------------------------------------------------------- canvas

// set by the main module so pages can refresh the title etc. after changing the document
void Function() onCanvasChanged = () {};

class CanvasPage extends SidebarPage {
    late TextBox widthBox;
    late TextBox heightBox;
    bool lockAspect = true;
    bool resizeImage = true;

    void init() {
        widthBox = TextBox(sidebarX + 130, 105, 85, 32, "${doc.width}", "px");
        heightBox = TextBox(sidebarX + 130, 150, 85, 32, "${doc.height}", "px");
        for (final box in [widthBox, heightBox]) {
            box.maxLength = 5;
        }
        widthBox.onCommit = (str) => _commit(str, true);
        heightBox.onCommit = (str) => _commit(str, false);
        initialized = true;
    }

    void _commit(String str, bool isWidth) {
        final value = int.tryParse(str);
        if (value == null || value < 1 || value > 10000) return;
        var w = doc.width, h = doc.height;
        if (isWidth) {
            if (lockAspect) h = (value * doc.height / doc.width).round().clamp(1, 10000);
            w = value;
        } else {
            if (lockAspect) w = (value * doc.width / doc.height).round().clamp(1, 10000);
            h = value;
        }
        finishTool();
        doc.resize(w, h, resizeImage);
        onCanvasChanged();
    }

    double get _lockY => 205;
    double get _resizeY => 235;

    void mousePressed() {
        widthBox.mousePressed();
        heightBox.mousePressed();
        if (checkboxHit(sidebarX + _PAD, _lockY)) {
            lockAspect = !lockAspect;
        } else if (checkboxHit(sidebarX + _PAD, _resizeY)) {
            resizeImage = !resizeImage;
        }
    }

    void mouseDragged() {
        widthBox.mouseDragged();
        heightBox.mouseDragged();
    }

    void keyPressed(KeyboardEvent event) {
        widthBox.keyPressed(event);
        heightBox.keyPressed(event);
    }

    void blurInputs() {
        widthBox.blur();
        heightBox.blur();
    }

    bool get isActive => initialized && (widthBox.focused || heightBox.focused);

    void render(int mouseX, int mouseY) {
        _label("Width", sidebarX + 26, 126);
        _label("Height", sidebarX + 26, 171);
        widthBox.x = sidebarX + 130;
        heightBox.x = sidebarX + 130;
        if (!widthBox.focused) widthBox.value = "${doc.width}";
        if (!heightBox.focused) heightBox.value = "${doc.height}";
        widthBox.render();
        heightBox.render();

        renderCheckbox(sidebarX + _PAD, _lockY, "Lock aspect ratio", lockAspect);
        renderCheckbox(sidebarX + _PAD, _resizeY, "Resize image with canvas", resizeImage);

        _label("Use Crop in the toolbar to cut the", sidebarX + 26, 290);
        _label("picture down to part of it.", sidebarX + 26, 308);
    }
}
