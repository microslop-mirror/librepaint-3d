import 'package:drawlite_dart/dl.dart';
import 'package:drawlite_dart/drawlite-touch.dart';

import './file-actions.dart';

// dropdown opened by the "Menu" button in the top left
bool menuOpen = false;

const _MENU_X = 0;
const _MENU_Y = 48;
const _MENU_WIDTH = 260;
const _ITEM_HEIGHT = 40;

class _MenuItem {
    final String label;
    final String shortcut;
    final void Function() action;
    const _MenuItem(this.label, this.shortcut, this.action);
}

final _items = [
    _MenuItem("New", "Ctrl+N", newDocument),
    _MenuItem("Open...", "Ctrl+O", openDocument),
    _MenuItem("Save", "Ctrl+S", saveDocument),
    _MenuItem("Save as...", "Ctrl+Shift+S", saveDocumentAs),
    _MenuItem("Exit", "", quit),
];

void renderMenu() {
    if (!menuOpen) return;

    final mx = get.mouseX;
    final my = get.mouseY;

    noStroke();
    rectMode(CORNER);
    fill(0, 0, 0, 40);
    rect(_MENU_X + 2, _MENU_Y + 2, _MENU_WIDTH, _items.length * _ITEM_HEIGHT);
    fill(45, 50, 55);
    rect(_MENU_X, _MENU_Y, _MENU_WIDTH, _items.length * _ITEM_HEIGHT);

    font("Open Sans", 14);
    for (var i = 0; i < _items.length; i++) {
        final y = _MENU_Y + i * _ITEM_HEIGHT;
        if (point_rect(mx, my, _MENU_X, y, _MENU_WIDTH, _ITEM_HEIGHT)) {
            fill(255, 255, 255, 25);
            rect(_MENU_X, y, _MENU_WIDTH, _ITEM_HEIGHT);
        }
        fill(255);
        textAlign(LEFT, CENTER);
        text(_items[i].label, _MENU_X + 20, y + _ITEM_HEIGHT / 2);
        fill(170);
        textAlign(RIGHT, CENTER);
        text(_items[i].shortcut, _MENU_X + _MENU_WIDTH - 16, y + _ITEM_HEIGHT / 2);
    }
    textAlign(LEFT, BASELINE);
}

// returns true if the click was handled by the menu
bool menuMousePressed() {
    final mx = get.mouseX;
    final my = get.mouseY;

    // the Menu button toggles the dropdown
    if (point_rect(mx, my, 0, 0, 68, 48)) {
        menuOpen = !menuOpen;
        return true;
    }

    if (!menuOpen) return false;

    menuOpen = false;
    for (var i = 0; i < _items.length; i++) {
        if (point_rect(mx, my, _MENU_X, _MENU_Y + i * _ITEM_HEIGHT, _MENU_WIDTH, _ITEM_HEIGHT)) {
            _items[i].action();
            return true;
        }
    }
    // clicking anywhere else just closes the menu
    return true;
}
