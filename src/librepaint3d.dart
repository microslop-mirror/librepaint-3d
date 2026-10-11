import 'dart:async';

import 'package:drawlite_dart/drawlite.dart'
    show Drawlite, Event, KeyboardEvent, MouseEvent, QuitEvent;
import 'package:drawlite_dart/dl.dart';
import 'package:drawlite_dart/drawlite-touch.dart';

import 'package:dcanvas/dcanvas.dart';
import 'package:dcanvas/backend/Window.dart';
import 'package:dcanvas/backend/Backend.dart' show sdl;

import './icons.dart';

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
    var touching = point_rect(mouseX / appScale, mouseY / appScale, 0, 0, 68, 48);
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
        final touching2 = point_rect(mouseX / appScale, mouseY / appScale, btnX, 0, 68, 48);
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
        var rx = lWidth - 48 - 68*(i+1);
        noStroke();
        rectMode(CORNER);
        var touching2 = point_rect(mouseX / appScale, mouseY / appScale, rx, 0, 68, 48);
        if (touching2) {
            fill(255, 255, 255, 25);
        } else {
            noFill();
        }
        rect(rx, 0, 68, 48);
        
        fill(255, 255, 255);
        text(labels2[3-i], rx + 68/2, 40);

        strokeWeight(2);
        rectMode(CENTER);
        renderIcon(labels2Icons[3-i], rx + 34, 16, 0.5, 0, 255);
        rectMode(CORNER);
    }

    var touching3 = point_rect(mouseX / appScale, mouseY / appScale, lWidth - 48, 0, 48, 48);
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

void draw() {
    // check for events
    window.pollInput();

    final mouseX = get.mouseX;
    final mouseY = get.mouseY;

    pushMatrix();
        scale(appScale);

        // canvas area
        noStroke();
        fill(190, 190, 190);
        rect(0, canvasAreaY, lWidth - SIDEBAR_WIDTH, lHeight - canvasAreaY);

        // canvas
        final canvasX = (sidebarX / 2 - paintCanvas.width / 2).round();
        final canvasY = (canvasAreaY + (height - canvasAreaY) / 2 - paintCanvas.height / 2).round();
        image(paintCanvas, canvasX, canvasY);
        if (currDrawStroke != null) {
            currDrawStroke!.render();
        }

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

        // 2nd row labels
        {
            font("Open Sans", 12);
            
            List<String> labels = [
                "Select",
                "Crop",
                "Magic Select"
            ];
            List<Icon> labelsIcons = [
                Icon.select,
                Icon.crop,
                Icon.magicSelect
            ];
            var btnX = 0.0;
            textAlign(CENTER);
            for (var i = 0; i < labels.length; i++) {
                var txtWidth = textWidth(labels[i]) + 71;
                
                var touching3 = point_rect(mouseX / appScale, mouseY / appScale, btnX, 48, txtWidth, 48);
                if (touching3) {
                    fill(0, 0, 0, 20);
                } else {
                    noFill();
                }
                noStroke();
                rectMode(CORNER);
                rect(btnX, 48, txtWidth, 48);
                
                fill(0, 0, 0);
                text(labels[i], btnX + txtWidth/2 + 12, 76);

                renderIcon(labelsIcons[i], btnX + 23, 70, 0.65, 0, 0);
                
                btnX += txtWidth;
            }
            rectMode(CORNER);
        }

        if (mouseX >= sidebarX) {
            renderSideBar();
            sidebarCacheImg = null;
        } else if (sidebarCacheImg == null) {
            renderSideBar();
            sidebarCacheImg = snip(sidebarX, sidebarY, SIDEBAR_WIDTH, lHeight - 48);
        } else {
            image(sidebarCacheImg!, sidebarX, sidebarY);
        }

        // welcome
        if (scene == Scene.Welcome) {
            welcomeMenu();
        }
    popMatrix();

    textAlign(BASELINE);
    fill(0);
    font("monospace", 16);
    text("FPS: ${frameRate().round()}", 3, height - 4);

    if (colorPicker != null) {
        colorPicker!.render();
    }

    window.render();

    if (!running) {
        noLoop();
        window.free();
    }
}

void mousePressed(MouseEvent event) {
    final mouseX = get.mouseX;
    final mouseY = get.mouseY;

    if (colorPicker != null && colorPicker!.isMouseOver()) {
        colorPicker!.mousePressed();
        return;
    }
    
    if (mouseX > sidebarX) {
        sidebarPage.mousePressed();
        return;
    }
    
    var btnX = (68 + (lWidth - (4*68 + 48 + 8*68))) / 2;
    for (var i = 0; i < sidebarPageLabels.length; i++) {
        if (point_rect(mouseX / appScale, mouseY / appScale, btnX, 0, 68, 48)) {
            setSidebarPage(i);
            return;
        }
        btnX += 68;
    }

    if (get.mouseX < sidebarX && get.mouseY > canvasAreaY) {
        currDrawStroke = new BrushStroke(currColor, brushesPage.thicknessSlider.value, selectedMarker);
    }
}

void mouseDragged(MouseEvent event) {
    final mouseX = get.mouseX;
    final mouseY = get.mouseY;

    if (colorPicker != null && colorPicker!.isMouseOver()) {
        colorPicker!.mouseDragged();
        return;
    }

    if (mouseX > sidebarX) {
        sidebarPage.mouseDragged();
        return;
    }

    if (currDrawStroke != null) {
        var points = currDrawStroke!.points;
        points.add(get.mouseX.toDouble());
        points.add(get.mouseY.toDouble());
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
            var touching = point_rect(mouseX / appScale, mouseY / appScale, rx, ry, 202, 144);
            if (touching) {
                scene = Scene.Draw;
                if (i == 0) {

                }
            }
        }
    }

    if (currDrawStroke != null) {
        // redraw only the canvas and the stroke before snipping so that
        // UI drawn on top of the canvas (e.g. the color picker) isn't captured
        final canvasX = (sidebarX / 2 - paintCanvas.width / 2).round();
        final canvasY = (canvasAreaY + (height - canvasAreaY) / 2 - paintCanvas.height / 2).round();
        pushMatrix();
            scale(appScale);
            image(paintCanvas, canvasX, canvasY);
            currDrawStroke!.render();
        popMatrix();
        paintCanvas = snip(canvasX, canvasY, paintCanvas.width, paintCanvas.height);
        currDrawStroke = null;
    }

    brushesPage.thicknessSlider.setPressed(false);
    brushesPage.opacitySlider.setPressed(false);
}

void keyPressed(KeyboardEvent event) {
    sidebarPage.keyPressed(event);
}

var running = true;
void myEventHandler(Event event) {
    if (event is MouseEvent) {
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
        
        // Escape cancels the color picker instead of quitting the app
        if (event.keyCode == Key.Escape && event.type == EventType.KeyDown) {
            colorPicker = null;
        }
    } else if (event is WindowEvent) {
        if (event.type == EventType.WindowResized) {
            onWindowResized(event.width, event.height);
        }
    } else if (event is QuitEvent) {
        running = false;
    }
}

Future<void> main() async {
    width = (1241 * appScale).round();
    height = (804 * appScale).round();
    // width = (1023 * appScale).round();
    // height = (768 * appScale).round();

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
    sdl.SDL_SetWindowMinimumSize(window.sdlWindow, (MIN_WIDTH * appScale).round(), (MIN_HEIGHT * appScale).round());

    globalizeDL(dl);
    
    initBrushColors();

    background(255);
    paintCanvas = snip(0, 0, 500, 400);

    lWidth = width / appScale;
    lHeight = height / appScale;

    loadMenuImage();
    loadOPpasteGradient();
    loadMagicSelectGradient();

    frameRate(120);
    dl.draw = draw;  
    dl.mousePressed = mousePressed;
    dl.mouseDragged = mouseDragged;
    dl.mouseReleased = mouseReleased;
    dl.keyPressed = keyPressed;
}
