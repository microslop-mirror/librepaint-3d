import 'package:drawlite_dart/drawlite.dart';
import 'package:drawlite_dart/dl.dart';
import 'package:drawlite_dart/drawlite-touch.dart';
import 'icons.dart';

import 'app-state.dart' show appScale;

void welcomeMenu() {
    final lWidth = get.width / appScale;
    final lHeight = get.height / appScale;

    fill(0, 0, 0, 175);
    rect(0, 0, lWidth, lHeight);
    
    fill(255, 255, 255);
    font("Open Sans", 45);
    textAlign(CENTER, BASELINE);
    text("Welcome", lWidth / 2, 125);
    
    List<String> labels = [
        "New",
        "Open",
        "Paste"
    ];
    
    font("Open Sans", 23);

    List<Icon> buttonIcons = [
        Icon.canvas,
        Icon.menu,
        Icon.OPpaste
    ];
    List<double> iconPos = [
        -1, 218,
        -18, 375,
        -4, 559
    ];
    
    for (var i = 0; i < 3; i++) {
        var rx = lWidth / 2 - 101;
        var ry = 165 + i * 169;
        var touching = point_rect(get.mouseX, get.mouseY, rx, ry, 202, 144);
        if (touching) {
            stroke(5, 100, 190);
            strokeWeight(3);
        } else {
            noStroke();
        }
        fill(255, 255, 255);
        rect(rx, ry, 202, 144);
        
        if (touching) {
            fill(35, 30, 90);
        } else {
            fill(160, 160, 160);
        }
        text(labels[i], lWidth / 2, 271 + i * 169);

        fill(255, 255, 255);
        Color strokeClr;
        if (touching) {
            strokeClr = Color(35, 30, 90);
        } else {
            strokeClr = Color(5, 100, 190);
        }
        strokeWeight(2);
        rectMode(CENTER);

        final xPos = lWidth / 2 + iconPos[i * 2];
        final yPos = iconPos[i * 2 + 1];
        if (i == 1) {
            image(touching ? menuImageDarkBlue : menuImageBlue, xPos, yPos);
        } else {
            renderIcon(buttonIcons[i], xPos, yPos, 1, 0, strokeClr);
        }        
        text("+", lWidth / 2 + 22, 241);
        rectMode(CORNER);

        // stroke(255, 0, 0);
        // noFill();
        // rect(rx+40, ry+40, 202-80, 144-80);
    }

}