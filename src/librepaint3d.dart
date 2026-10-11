import 'dart:async';
import 'dart:io';

import 'package:drawlite_dart/drawlite.dart'
    show Drawlite, Event, KeyboardEvent, MouseEvent, QuitEvent, KeyState, Color;
import 'package:drawlite_dart/dl.dart';
import 'package:drawlite_dart/drawlite-touch.dart';

import 'package:dcanvas/dcanvas.dart';
import 'package:dcanvas/backend/Window.dart';
import 'package:dcanvas/backend/Backend.dart' show sdl;

import './icons.dart';
import './document.dart';
import './file-actions.dart';
import './menu.dart';
import './view.dart';
import './tools.dart';
import './pages.dart' show onCanvasChanged;

import './welcome-menu.dart';
import './brushes.dart';
import './sidebar.dart';

import './app-state.dart';

late SDLWindow window;

// smallest logical window size before the layout starts overlapping
const MIN_WIDTH = 960;
const MIN_HEIGHT = 680;

void onWindowResized(int newWidth, int newHeight) {
    width = newWidth;
    height = newHeight;
    dl.size(width, height);
    window.width = width;
    window.height = height;

    lWidth = width / appScale;
    lHeight = height / appScale;

    sidebarCacheImg = null;

    // keep the color picker inside the window
    final picker = colorPicker;
    if (picker != null) {
        picker.x = constrain(picker.x, 0, lWidth - picker.width).toInt();
        picker.y = constrain(picker.y, 0, lHeight - picker.height).toInt();
    }
}

void renderTopRowButtons() {
    final mouseX = get.mouseX;
    final mouseY = get.mouseY;

    font("Open Sans", 11);
    noStroke();
    var touching = point_rect(mouseX, mouseY, 0, 0, 68, 48);
    if (touching) {
        fill(255, 255, 255, 25);
    } else {
        noFill();
    }
    rect(0, 0, 68, 48);
    strokeWeight(2);
    renderIcon(Icon.menu, 29, 16, 0.5, 0, 255);
    fill(255, 255, 255);
    textAlign(CENTER);
    text("Menu", 34, 40);
    
    List<Icon> labelsIcons = [
        Icon.brushes,
        Icon.shapes2d,
        Icon.shapes3d,
        Icon.stickers,
        Icon.text,
        Icon.effects,
        Icon.canvas,
        Icon.library3d
    ];
    var btnX = (68 + (lWidth - (4*68 + 48 + 8*68))) / 2;
    textAlign(CENTER);
    for (var i = 0; i < sidebarPageLabels.length; i++) {
        final touching2 = point_rect(mouseX, mouseY, btnX, 0, 68, 48);
        if (i == sidebarPage) {
            fill(30, 100, 190);
        } else if (touching2) {
            fill(255, 255, 255, 25);
        } else {
            noFill();
        }
        noStroke();
        rectMode(CORNER);
        rect(btnX, 0, 68, 48);
        
        fill(255, 255, 255);
        text(sidebarPageLabels[i], btnX + 68/2, 40);

        strokeWeight(2);
        renderIcon(labelsIcons[i], btnX + 34, 16, 0.45, 0, 255);
        
        btnX += 68;
    }
    
    List<String> labels2 = [
        "Paste",
        "Undo",
        "History",
        "Redo"
    ];
    List<Icon> labels2Icons = [
        Icon.OPpaste,
        Icon.undo,
        Icon.history,
        Icon.redo
    ];
    for (var i = 0; i < labels2.length; i++) {
        var rx = topRightButtonX(i);
        // gray out undo/redo when there's nothing to undo/redo
        final enabled = (i != UNDO_BUTTON || doc.canUndo) && (i != REDO_BUTTON || doc.canRedo);
        noStroke();
        rectMode(CORNER);
        var touching2 = point_rect(mouseX, mouseY, rx, 0, 68, 48);
        if (touching2 && enabled) {
            fill(255, 255, 255, 25);
        } else {
            noFill();
        }
        rect(rx, 0, 68, 48);
        
        final textClr = enabled ? 255 : 110;
        fill(textClr);
        text(labels2[3-i], rx + 68/2, 40);

        strokeWeight(2);
        rectMode(CENTER);
        renderIcon(labels2Icons[3-i], rx + 34, 16, 0.5, 0, textClr);
        rectMode(CORNER);
    }

    var touching3 = point_rect(mouseX, mouseY, lWidth - 48, 0, 48, 48);
    if (touching3) {
        fill(255, 255, 255, 25);
    } else {
        noFill();
    }
    noStroke();
    rect(lWidth - 48, 0, 48, 48);
    stroke(255, 255, 255);
    strokeWeight(2);
    arrow(lWidth - 26, 24, 0.7, 0);
}

// set when something happened that may change what's on screen
var needsRedraw = true;
var lastRedraw = 0;
// how often to redraw when idle, e.g. for blinking text cursors
const IDLE_REDRAW_MS = 250;

var _lastTitle = "";
void updateTitle() {
    final title = "${doc.modified ? "*" : ""}${doc.displayName} - LibrePaint 3D";
    if (title != _lastTitle) {
        window.setTitle(title);
        _lastTitle = title;
    }
}

final _secondRowLabels = ["Select", "Crop", "Magic Select"];
final _secondRowIcons = [Icon.select, Icon.crop, Icon.magicSelect];
final _secondRowTools = [Tool.select, Tool.crop, null];

// x and width of each button in the second toolbar row
List<(double, double)> secondRowButtons() {
    font("Open Sans", 12);
    var x = 0.0;
    final result = <(double, double)>[];
    for (final label in _secondRowLabels) {
        final w = textWidth(label) + 71;
        result.add((x, w));
        x += w;
    }
    return result;
}

// Done/Cancel buttons shown in the second row while cropping
const _CROP_BTN_WIDTH = 90.0;
double get _cropDoneX => sidebarX - _CROP_BTN_WIDTH * 2 - 24;
double get _cropCancelX => sidebarX - _CROP_BTN_WIDTH - 16;

void renderSecondRow(int mouseX, int mouseY) {
    final buttons = secondRowButtons();
    textAlign(CENTER);
    rectMode(CORNER);
    for (var i = 0; i < buttons.length; i++) {
        final (btnX, txtWidth) = buttons[i];
        final active = _secondRowTools[i] != null && _secondRowTools[i] == currentTool;
        // renderIcon leaves rectMode set to CENTER
        rectMode(CORNER);
        noStroke();
        if (active) {
            fill(0, 0, 0, 35);
        } else if (point_rect(mouseX, mouseY, btnX, 48, txtWidth, 48)) {
            fill(0, 0, 0, 20);
        } else {
            noFill();
        }
        rect(btnX, 48, txtWidth, 48);

        fill(0, 0, 0);
        text(_secondRowLabels[i], btnX + txtWidth/2 + 12, 76);
        renderIcon(_secondRowIcons[i], btnX + 23, 70, 0.65, 0, 0);
    }

    // hint for the current tool
    final (lastX, lastW) = buttons.last;
    var hint = "";
    if (currentTool == Tool.crop) {
        hint = "Drag to choose the area to keep";
    } else if (currentTool == Tool.select) {
        hint = "Drag to select. Ctrl+C copy, Ctrl+X cut, Ctrl+V paste, Delete erase";
    }
    noStroke();
    fill(90);
    font("Open Sans", 12);
    textAlign(LEFT, CENTER);
    text(hint, lastX + lastW + 16, 72);

    rectMode(CORNER);
    if (currentTool == Tool.crop) {
        for (final (x, label, primary) in [(_cropDoneX, "Done", true), (_cropCancelX, "Cancel", false)]) {
            final hover = point_rect(mouseX, mouseY, x, 56, _CROP_BTN_WIDTH, 32);
            if (primary) {
                fill(hover ? Color(0, 85, 160) : Color(0, 100, 180));
            } else {
                fill(hover ? 200 : 210);
            }
            rect(x, 56, _CROP_BTN_WIDTH, 32);
            fill(primary ? 255 : 0);
            textAlign(CENTER, CENTER);
            text(label, x + _CROP_BTN_WIDTH / 2, 72);
        }
    }
    textAlign(LEFT, BASELINE);
    rectMode(CORNER);
}

// returns true if a second row button was clicked
bool secondRowMousePressed(int mouseX, int mouseY) {
    if (mouseY < 48 || mouseY > 96 || mouseX > sidebarX) return false;
    if (currentTool == Tool.crop) {
        if (point_rect(mouseX, mouseY, _cropDoneX, 56, _CROP_BTN_WIDTH, 32)) {
            applyCrop();
            updateTitle();
            return true;
        }
        if (point_rect(mouseX, mouseY, _cropCancelX, 56, _CROP_BTN_WIDTH, 32)) {
            cancelCrop();
            return true;
        }
    }
    final buttons = secondRowButtons();
    for (var i = 0; i < buttons.length; i++) {
        final (x, w) = buttons[i];
        if (point_rect(mouseX, mouseY, x, 48, w, 48)) {
            final tool = _secondRowTools[i];
            if (tool != null) {
                // clicking the active tool again goes back to painting
                setTool(currentTool == tool ? Tool.brush : tool);
            }
            return true;
        }
    }
    return true;
}

void draw() {
    // check for events
    window.pollInput();

    if (!running) {
        noLoop();
        window.free();
        return;
    }

    // skip rendering when nothing changed to save CPU
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!needsRedraw && now - lastRedraw < IDLE_REDRAW_MS) {
        return;
    }
    needsRedraw = false;
    lastRedraw = now;

    final mouseX = get.mouseX;
    final mouseY = get.mouseY;

    pushMatrix();
        scale(appScale);

        // canvas area
        noStroke();
        fill(190, 190, 190);
        rect(0, canvasAreaY, lWidth - SIDEBAR_WIDTH, lHeight - canvasAreaY);

        // canvas
        updateView();
        final viewW = doc.width * viewZoom;
        final viewH = doc.height * viewZoom;
        image(doc.canvas, viewX, viewY, viewW, viewH);
        if (currDrawStroke != null) {
            dl.ctx.save();
            dl.ctx.translate(viewX, viewY);
            dl.ctx.scale(viewZoom, viewZoom);
            currDrawStroke!.render(dl.ctx);
            dl.ctx.restore();
        }
        renderToolPreview();

        // cover the parts of strokes and shapes outside the canvas
        noStroke();
        fill(190, 190, 190);
        rect(0, canvasAreaY, viewX, lHeight - canvasAreaY);
        rect(viewX + viewW, canvasAreaY, sidebarX - viewX - viewW, lHeight - canvasAreaY);
        rect(viewX, canvasAreaY, viewW, viewY - canvasAreaY);
        rect(viewX, viewY + viewH, viewW, lHeight - viewY - viewH);

        renderToolOverlay();

        fill(255, 0, 0, 100);
        noStroke();
        // top bar
        fill(45, 50, 55);
        rect(0, 0, lWidth, 48);

        // 2nd row of top bar
        fill(221, 221, 223);
        rect(0, 48, lWidth - SIDEBAR_WIDTH, 48);

        // gradient
        for (var i = 0; i <= 10; i++) {
            var m = map(i, 0, 10, 30, 0);
            fill(0, 0, 0, m);
            rect(0, 48 + 48 + i, sidebarX - i, 1);
            rect(sidebarX - 1 - i, 48 + 48 + i, 1, lHeight - 48*2 - i);
        }

        renderTopRowButtons();

        renderSecondRow(mouseX, mouseY);

        if (mouseX >= sidebarX || sidebarPage.isActive) {
            renderSideBar();
            sidebarCacheImg = null;
        } else if (sidebarCacheImg == null) {
            renderSideBar();
            // snip works in physical pixels, unaffected by the scale transform
            sidebarCacheImg = snip(sidebarX * appScale, sidebarY * appScale, SIDEBAR_WIDTH * appScale, (lHeight - 48) * appScale);
        } else {
            image(sidebarCacheImg!, sidebarX, sidebarY, SIDEBAR_WIDTH, lHeight - 48);
        }

        renderMenu();

        // welcome
        if (scene == Scene.Welcome) {
            welcomeMenu();
        }

        if (colorPicker != null) {
            colorPicker!.render();
        }
    popMatrix();

    window.render();
}

void mousePressed(MouseEvent event) {
    final mouseX = get.mouseX;
    final mouseY = get.mouseY;

    if (colorPicker != null && colorPicker!.isMouseOver()) {
        colorPicker!.mousePressed();
        return;
    }

    if (menuMousePressed()) {
        return;
    }
    
    if (mouseX > sidebarX && mouseY > sidebarY) {
        sidebarPage.mousePressed();
        return;
    }

    // clicking outside the sidebar finishes editing its number boxes
    sidebarPage.blurInputs();

    if (secondRowMousePressed(mouseX, mouseY)) {
        return;
    }
    
    var btnX = (68 + (lWidth - (4*68 + 48 + 8*68))) / 2;
    for (var i = 0; i < sidebarPageLabels.length; i++) {
        if (point_rect(mouseX, mouseY, btnX, 0, 68, 48)) {
            setSidebarPage(i);
            return;
        }
        btnX += 68;
    }

    if (point_rect(mouseX, mouseY, topRightButtonX(UNDO_BUTTON), 0, 68, 48)) {
        undo();
        return;
    }
    if (point_rect(mouseX, mouseY, topRightButtonX(REDO_BUTTON), 0, 68, 48)) {
        redo();
        return;
    }
    if (point_rect(mouseX, mouseY, topRightButtonX(PASTE_BUTTON), 0, 68, 48)) {
        paste();
        updateTitle();
        return;
    }

    if (isOverCanvasArea(mouseX, mouseY) && currentTool != Tool.brush) {
        toolMousePressed(toDocX(mouseX), toDocY(mouseY));
        return;
    }

    if (isOverCanvasArea(mouseX, mouseY) && selectedMarker == FILL_BUCKET) {
        final x = toDocX(mouseX).floor(), y = toDocY(mouseY).floor();
        if (x >= 0 && y >= 0 && x < doc.width && y < doc.height) {
            doc.beginChange();
            final pixels = doc.getPixels();
            floodFill(pixels, x, y, currColor, brushesPage.opacitySlider.value);
            doc.ctx.putImageData(pixels, 0, 0);
            updateTitle();
        }
    } else if (isOverCanvasArea(mouseX, mouseY)) {
        currDrawStroke = new BrushStroke(currColor, brushesPage.thicknessSlider.value, brushesPage.opacitySlider.value, selectedMarker);
        currDrawStroke!.addPoint(toDocX(mouseX), toDocY(mouseY));
    }
}

void mouseDragged(MouseEvent event) {
    final mouseX = get.mouseX;
    final mouseY = get.mouseY;

    if (colorPicker != null && colorPicker!.isMouseOver()) {
        colorPicker!.mouseDragged();
        return;
    }

    if (mouseX > sidebarX && mouseY > sidebarY) {
        sidebarPage.mouseDragged();
        return;
    }

    if (currDrawStroke != null) {
        currDrawStroke!.addPoint(toDocX(mouseX), toDocY(mouseY));
    } else if (currentTool != Tool.brush) {
        toolMouseDragged(toDocX(mouseX), toDocY(mouseY));
    }
}

void mouseReleased(MouseEvent event) {
    if (colorPicker != null) {
        colorPicker!.onMouseReleased();
    }

    final mouseX = get.mouseX;
    final mouseY = get.mouseY;

    if (scene == Scene.Welcome) {
        for (var i = 0; i < 3; i++) {
            var rx = lWidth / 2 - 101;
            var ry = 165 + i * 169;
            var touching = point_rect(mouseX, mouseY, rx, ry, 202, 144);
            if (touching) {
                scene = Scene.Draw;
                if (i == 0) {

                }
            }
        }
    }

    if (currDrawStroke != null) {
        doc.beginChange();
        currDrawStroke!.render(doc.ctx);
        currDrawStroke = null;
        updateTitle();
    }

    if (currentTool != Tool.brush) {
        toolMouseReleased();
        updateTitle();
    }

    if (brushesPage.initialized) {
        brushesPage.thicknessSlider.setPressed(false);
        brushesPage.opacitySlider.setPressed(false);
    }
    sidebarPage.mouseReleased();
}

void undo() {
    if (currDrawStroke != null) return;
    finishTool();
    doc.undo();
    updateTitle();
}

void redo() {
    if (currDrawStroke != null) return;
    finishTool();
    doc.redo();
    updateTitle();
}

// x of a top right button, counting from the right starting at 0
double topRightButtonX(int i) => lWidth - 48 - 68 * (i + 1);
const REDO_BUTTON = 0;
const UNDO_BUTTON = 2;
const PASTE_BUTTON = 3;

// returns true if the key was a shortcut
bool handleShortcut(KeyboardEvent event) {
    if (!KeyState.isCtrlPressed()) return false;

    final key = event.keyCode;
    final shift = KeyState.isShiftPressed();
    if (key == 110) { // n
        newDocument();
    } else if (key == 111) { // o
        openDocument();
    } else if (key == 115 && shift) { // s
        saveDocumentAs();
    } else if (key == 115) {
        saveDocument();
    } else if (key == 113) { // q
        quit();
    } else if ((key == 122 && shift) || key == 121) { // ctrl+shift+z, ctrl+y
        redo();
    } else if (key == 122) { // z
        undo();
    } else if (key == 99) { // c
        copySelection();
    } else if (key == 120) { // x
        cutSelection();
        updateTitle();
    } else if (key == 118) { // v
        paste();
        updateTitle();
    } else if (key == 97) { // a
        selectAll();
    } else {
        return false;
    }
    menuOpen = false;
    return true;
}

void keyPressed(KeyboardEvent event) {
    if (handleShortcut(event)) {
        return;
    }
    if (colorPicker != null) {
        colorPicker!.keyPressed(event);
        return;
    }
    // text boxes in the sidebar get keys while they're being edited
    if (!sidebarPage.isActive && toolKeyPressed(event)) {
        updateTitle();
        return;
    }
    sidebarPage.keyPressed(event);
}

var running = true;
void myEventHandler(Event event) {
    if (event.type != EventType.Unknown) {
        needsRedraw = true;
    }
    if (event is MouseEvent) {
        // everything after this works in logical (unscaled) coordinates
        if (appScale != 1) {
            event.mouseX = (event.mouseX / appScale).round();
            event.mouseY = (event.mouseY / appScale).round();
        }
        if (event.type == EventType.MouseDown) {
            dl.eventCallbacks.mousedown(event);
        } else if (event.type == EventType.MouseUp) {
            dl.eventCallbacks.mouseup(event);
        } else if (event.type == EventType.MouseMove) {
            dl.eventCallbacks.mousemove(event);
        }
    } else if (event is KeyboardEvent) {
        if (event.type == EventType.KeyDown) {
            dl.eventCallbacks.keydown(event);
        } else if (event.type == EventType.KeyUp) {
            dl.eventCallbacks.keyup(event);
        }
        
        // Escape cancels the color picker and menu instead of quitting the app
        if (event.keyCode == Key.Escape && event.type == EventType.KeyDown) {
            colorPicker = null;
            menuOpen = false;
        }
    } else if (event is WindowEvent) {
        if (event.type == EventType.WindowResized) {
            onWindowResized(event.width, event.height);
        }
    } else if (event is QuitEvent) {
        // ask about unsaved changes before closing
        quit();
    }
}

// UI scale for high DPI screens, following the desktop's settings.
// LIBREPAINT_SCALE overrides it, e.g. LIBREPAINT_SCALE=1.5
double detectAppScale() {
    final env = Platform.environment;
    for (final name in ["LIBREPAINT_SCALE", "GDK_SCALE"]) {
        final value = double.tryParse(env[name] ?? "");
        if (value != null && value > 0) return value;
    }

    // X11 desktops (GNOME, KDE, ...) publish their font DPI; 96 is 100%
    try {
        final result = Process.runSync("xrdb", ["-query"]);
        final match = RegExp(r'Xft\.dpi:\s*([0-9.]+)').firstMatch(result.stdout.toString());
        final dpi = double.tryParse(match?.group(1) ?? "");
        if (dpi != null && dpi > 0) {
            // round to the nearest 25% so lines stay crisp
            return ((dpi / 96) * 4).round() / 4;
        }
    } catch (e) {
        // xrdb isn't installed
    }
    return 1.0;
}

Future<void> main(List<String> args) async {
    appScale = detectAppScale().clamp(1.0, 4.0);
    width = (1241 * appScale).round();
    height = (804 * appScale).round();

    var canvas = Canvas(width, height);
    dl = Drawlite(canvas);

    initSDL(SDL_INIT_EVERYTHING);
    window = SDLWindow(
        title: "Untitled - LibrePaint 3D",
        width: canvas.width,
        height: canvas.height,
        flagsList: [SDL_WindowFlags.SDL_WINDOW_SHOWN, SDL_WindowFlags.SDL_WINDOW_RESIZABLE]
    );
    window.setCanvas(canvas);
    window.eventHandler = myEventHandler;
    // SDL starts in text input mode, which lets input methods (e.g. Korean IME)
    // swallow letter keys before they reach us as key events
    sdl.SDL_StopTextInput();
    sdl.SDL_SetWindowMinimumSize(window.sdlWindow, (MIN_WIDTH * appScale).round(), (MIN_HEIGHT * appScale).round());

    globalizeDL(dl);
    
    initBrushColors();

    doc = PaintDocument.blank();
    onDocumentChanged = () {
        updateTitle();
        needsRedraw = true;
    };
    onDocumentReplaced = resetToolState;
    beforeFileAction = finishTool;
    onCanvasChanged = () {
        updateTitle();
        needsRedraw = true;
    };
    onQuit = () {
        running = false;
    };
    updateTitle();
    if (args.isNotEmpty) {
        // the .desktop file passes files as URIs
        final arg = args.first;
        openDocumentPath(arg.startsWith("file://") ? Uri.parse(arg).toFilePath() : arg);
    }

    lWidth = width / appScale;
    lHeight = height / appScale;

    loadMenuImage();
    loadOPpasteGradient();
    loadMagicSelectGradient();

    frameRate(60);
    dl.draw = draw;  
    dl.mousePressed = mousePressed;
    dl.mouseDragged = mouseDragged;
    dl.mouseReleased = mouseReleased;
    dl.keyPressed = keyPressed;
}
