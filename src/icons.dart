import 'package:drawlite_dart/drawlite.dart';
import 'package:drawlite_dart/dl.dart';

enum Icon {
    menu,
    OPpaste,
    canvas,
    undo,
    redo,
    history,
    brushes,
    shapes2d,
    shapes3d,
    stickers,
    text,
    effects,
    library3d,
    select,
    crop,
    magicSelect
}

late DLImage menuImageWhite;
late DLImage menuImageDarkBlue;
late DLImage menuImageBlue;
void loadMenuImage() {
    var x = 13;
    var y = 15;
    var s = 1;
    var r = 0;
    background(0, 0, 0, 0);
    pushMatrix();
        translate(x + 5, y);
        scale(s);
        rotate(r);
        
        rectMode(CENTER);
        stroke(255);
        strokeWeight(1.5);
        fill(0);
        rect(0, 0, 35, 25); // main
        rect(-11, -12, 13, 5, 0, 3, 0, 0); // corner piece
    popMatrix();

    var menuImageShape = snip(0, 0, 37, 29);

    background(255);
    menuImageWhite = snip(0, 0, 37, 29);
    menuImageWhite.mask(menuImageShape);

    background(35, 30, 90);
    menuImageDarkBlue = snip(0, 0, 37, 29);
    menuImageDarkBlue.mask(menuImageShape);

    background(5, 100, 190);
    menuImageBlue = snip(0, 0, 37, 29);
    menuImageBlue.mask(menuImageShape);    
}
void menu(num x, num y, num s, num r) {
    pushMatrix();
        translate(x-9, y-7);
        scale(s);
        imageMode(CENTER);
        image(menuImageWhite, x, y);
        imageMode(CORNER);
    popMatrix();
}

DLImage? pasteGradient;
void loadOPpasteGradient() {
    final x = 14;
    final y = 20;
    final s = 0.6;
    final r = 0;

    rectMode(CENTER);
    background(0);
    pushMatrix();
        translate(x, y);
        scale(s);
        rotate(r);
        
        noFill();
        stroke(255);
        rect(0, 0, 25, 30, 2); // clipboard
        rect(0, -13, 15, 1); // clip for paper
        arc(1, -14, 5, 7, -180, 0);
        fill(0);
        stroke(255);
        rect(8, 4, 19, 25); // paper
        
        // "writing" on paper (aka the squiggly lines we pretended were words as children)
        for(var i = -1; i < 17; i += 6) {
            line(2, i, 15, i);
        }
    popMatrix();

    var pasteSelectMask = snip(0, 0, 35, 40);

    background(255);
    pasteGradient = snip(0, 0, 35, 40);
    pasteGradient!.mask(pasteSelectMask);
}
void OPpaste(num x, num y, num s, num r) {
    pushMatrix();
        translate(x, y);
        scale(s);
        rotate(r);
        
        noFill();
        rect(0, 0, 25, 30, 2); // clipboard
        rect(0, -13, 15, 1); // clip for paper
        arc(1, -14, 5, 7, -180, 0);
        fill(255);
        rect(8, 4, 19, 25); // paper
        
        // "writing" on paper (aka the squiggly lines we pretended were words as children)
        for(var i = -1; i < 17; i += 6) {
            line(2, i, 15, i);
        }
    popMatrix();
}

void canvas(num x, num y, num s, num r) {
    pushMatrix();
        translate(x, y);
        scale(s);
        rotate(r);
        
        line(14, 14, 14, -14);
        line(18, 10, -16, 10);
        line(-12, 14, -12, -14);
        line(18, -10, -16, -10);
    popMatrix();
}

void arrow(num x, num y, num s, num r) {
    pushMatrix();
        translate(x, y);
        scale(s);
        rotate(r);
        
        strokeWeight(1.1);
        line(-10, 5, 0, -5);
        line(10, 5, 0, -5);
    popMatrix();
}


void undo_redo(num x, num y, num xScale, num yScale, num rotation) {
    pushMatrix();
        translate(x, y);
        rotate(rotation);
        scale(xScale, yScale);
        
        strokeWeight(1.2);
        
        beginShape();
        vertex(-8, 0);
        bezierVertex(-10, -16, 10, -16, 9, 0);
        vertex(8, 15);
        endShape();
        
        line(-8, 2, -3, -4);
        line(-8, 2, -12, -4);
    popMatrix();
}

void history(num x, num y, num s, num r) {
    pushMatrix();
        translate(x, y);
        rotate(r);
        scale(s);
        strokeWeight(1.2);
        
        arc(0, 0, 28, 28, -170, 136);
        
        // arrow
        line(-14, 0, -8, -6);
        line(-14, 0, -18, -7);
        
        // time thing
        line(-1, 0, -1, -8);
        line(-1, 0, 4, 6);
    popMatrix();
}

// "Brushes" Icon
void brushes(num x, num y, num s, num r) {
    pushMatrix();
        translate(x, y);
        scale(s);
        rotate(r);
        
        beginShape();
        vertex(0, 0);
        bezierVertex(12, -1, 12, 14, 0, 14);
        bezierVertex(-6, 14, -8, 13, -12, 12);
        bezierVertex(-4, 8, -10, 3, 0, 0);
        endShape();
        
        beginShape();
        vertex(5, 2);
        bezierVertex(5, -2, 7, -9, 40, -30);
        bezierVertex(48, -33, 44, -25, 44, -26);
        bezierVertex(26, -4, 7, 10, 5, 2);
        endShape();
    popMatrix();
}

// "2d shapes" Icon
void flatShapes(num x, num y, num s, num r) {
    pushMatrix();
        translate(x, y);
        scale(s);
        
        rect(11, -9, 25, 25);
        // rect(11, -20, 25, 0);
        // rect(11, 3, 25, 0);
        ellipse(-10, 4, 25, 25);
        triangle(-10, 23, 24, 23, 7, -4);
        rect(6, 22, 32, 0);
    popMatrix();
}

// "3d shapes" Icon
void thiccShapes(num x, num y, num s, num r) {
    pushMatrix();
        translate(x, y);
        scale(s);
        rotate(r);
        
        quad(1, 23, 1, -2, -19, -12, -19, 13); // left face
        quad(1, 23, 1, -2, 21, -12, 21, 13); // right face
        quad(-19, -12, 1, -2, 21, -12, 1, -22); // top face
    popMatrix();
}

// "Stickers" Icon
void stickers(num x, num y, num s, num r) {
    pushMatrix();
        translate(x, y);
        scale(s);
        rotate(r);
        
        // half circle
        arc(10, -10, 30, 30, 109, 339);
        
        // fold
        pushMatrix();
        rotate(-45);
        arc(14, 6, 26, 20, 184, 360);
        popMatrix();
        
        line(5, 4, 24, -15);
        
        // dashes
        for(var i = 0; i < 100; i += 30) {
            noFill();
            arc(10, -10, 30, 30, -10+i, 10+i);
        }
    popMatrix();
}

// "Text" Icon
void Text(num x, num y, num s, num r) {
    pushMatrix();
        translate(x, y);
        scale(s);
        
        beginShape();
        vertex(-2, 13);
        vertex(-2, -12);
        vertex(-11, -12);
        vertex(-11, -8);
        vertex(-15, -8);
        vertex(-15, -16);
        vertex(16, -16);
        vertex(16, -8);
        vertex(12, -8);
        vertex(12, -12);
        vertex(3, -12);
        vertex(3, 13);
        vertex(8, 13);
        vertex(8, 17);
        vertex(-7, 17);
        vertex(-7, 13);
        endShape(CLOSE);
    popMatrix();
}

// "Effects" Icon
void effects(num x, num y, num s, num r) {
    pushMatrix();
        translate(x, y);
        scale(s);
        rotate(r);
        
        ellipse(0, 0, 16, 16);
        
        // I hated this *tears*
        line(0, -12, 0, -18); // north
        line(8, -8, 13, -13); // northeast
        line(12, 0, 18, 0); // east
        line(8, 8, 13, 13); // southeast
        line(0, 12, 0, 18); // south
        line(-8, 8, -13, 13); // southwest
        line(-12, 0, -18, 0); // west
        line(-8, -8, -13, -13); // northwest
    popMatrix();
}

void thiccLibrary(num x, num y, num s, num r) {
    pushMatrix();
        translate(x, y);
        scale(s);
        rotate(r);
        
        // cube
        quad(0, 23, 0, -2, -20, -12, -20, 13); // left face
        quad(0, 23, 0, -2, 20, -12, 20, 13); // right face
        quad(-20, -12, 0, -2, 20, -12, 0, -22); // top face
        
        // magnifying class lense
        ellipse(20, 9, 18, 18);
        
        //handle
        pushMatrix();
            translate(8, 23);
            rotate(-49);
            
            rect(0, 0, 14, 1);
        popMatrix();
    popMatrix();
}

void select(num x, num y, num s) {
    pushMatrix();
        translate(x, y);
        scale(s);
        
        beginShape();
        vertex(-5, 13);
        vertex(-5, -12);
        vertex(10, 6);
        vertex(3, 6);
        vertex(7, 12);
        vertex(2, 15);
        vertex(0, 8);
        endShape(CLOSE);
    popMatrix();
}

// "Crop" Icon
void crop(num x, num y, num s) {
    pushMatrix();
        translate(x, y);
        scale(s);
        
        line(-15, -8, 10, -8); // north
        line(10, -8, 10, 17); // east
        line(15, 12, -10, 12); // south
        line(-10, -13, -10, 12); // west
        
        // slash through
        line(-10, 12, 17, -15);
    popMatrix();
}

// "Magic Select" Icon
DLImage? magicSelectGradient;
void loadMagicSelectGradient() {
    final x = 14;
    final y = 10;
    final s = 1;

    rectMode(CENTER);
    background(0, 0, 0);
    pushMatrix();
        translate(x, y);
        scale(s);
        
        fill(0);
        stroke(255);
        rect(-2, -10, 23, 1);
        rect(-2, -2, 23, 15);
        
        noStroke();
        fill(255);
        arc(0, 6, 11, 15, -179, 0);
        ellipse(0, -4, 6, 6);
        
        stroke(255);
        fill(0);
        arc(10, 12, 12, 16, -179, 0);
        ellipse(10, 1, 7, 7);
    popMatrix();

    var magicSelectMask = snip(0, 0, 30, 21);

    background(0);
    magicSelectGradient = snip(0, 0, 30, 21);
    magicSelectGradient!.mask(magicSelectMask);
}
void magicSelect(num x, num y, num s) {
    pushMatrix();
        translate(x, y);
        scale(s);
        
        rect(-2, -10, 23, 1);
        rect(-2, -2, 23, 15);
        
        noStroke();
        fill(0, 0, 0);
        arc(0, 6, 11, 15, -179, 0);
        ellipse(0, -4, 6, 6);
        
        stroke(0);
        fill(255, 255, 255);
        arc(10, 12, 12, 16, -179, 0);
        ellipse(10, 1, 7, 7);
    popMatrix();
}

void renderIcon(Icon which, num x, num y, num s, num r, Object clr) {
    rectMode(CENTER);
    switch (which) {
        case Icon.menu:
            menu(x, y, s, r);
            break;
        case Icon.OPpaste:
            image(pasteGradient!, x-14, y-20);
            break;
        case Icon.canvas:
            noFill();
            stroke(clr);
            canvas(x, y, s*1.1, r);
            break;
        case Icon.redo:
            noFill();
            stroke(clr);
            undo_redo(x, y-1, -s, s*1.3, r);
            break;
        case Icon.undo:
            noFill();
            stroke(clr);
            undo_redo(x, y-1, s, s*1.3, r);
            break;
        case Icon.history:
            noFill();
            stroke(clr);
            history(x, y, s*1.2, r);
            break;
        case Icon.brushes:
            noFill();
            stroke(clr);
            brushes(x-7, y+3, s * 0.9, r);
            break;
        case Icon.shapes2d:
            noFill();
            stroke(clr);
            flatShapes(x-2, y-0.5, s * 0.9, r);
            break;
        case Icon.shapes3d:
            noFill();
            stroke(clr);
            thiccShapes(x, y-1, s*0.9, r);
            break;
        case Icon.stickers:
            noFill();
            stroke(clr);
            stickers(x-6, y+6, s*1.31, r);
            break;
        case Icon.text:
            noFill();
            stroke(clr);
            Text(x, y, s*1.1, r);
            break;
        case Icon.effects:
            noFill();
            stroke(clr);
            effects(x, y, s*1.1, r);
            break;
        case Icon.library3d:
            noFill();
            stroke(clr);
            thiccLibrary(x, y-1, s*0.85, r);
            break;
            case Icon.select:
            noFill();
            stroke(clr);
            select(x, y, s);
            break;
        case Icon.crop:
            noFill();
            stroke(clr);
            crop(x+2, y, s*0.9);
            break;
        case Icon.magicSelect:
            image(magicSelectGradient!, x-14, y-8);
            break;
    }
}

// ----------------------------------------
// BRUSHES ICONS
// ----------------------------------------

/* Credit: Vexcess' (@VXS) multiLerpColor functions */
Color multiLerpColor(List<Color> listOfColors, double amount) {
    amount = map(amount, 0, 1, 0, listOfColors.length-1);
    var amt = amount - floor(amount);
    amount = amount.floorToDouble();
    return lerpColor(listOfColors[amount.toInt()], listOfColors[amount.toInt()+1], amt);
}

Color combineColors(List<Color> listOfColors) {
    var clrs = [listOfColors, []];
    while(clrs[0].length > 1){
        for(var i = 0; i < clrs[0].length; i += 2){
            clrs[1].add(lerpColor(clrs[0][i], clrs[0][i+1], 0.5));
        }
        clrs.removeAt(0);
        clrs.add([]);
    }
    return clrs[0][0];
}

void gradient(num xPos, num yPos, num width, num height, Color color1, Color color2) {
    noStroke();
    for(var x = 0; x < width; x += 1){
        var clr = multiLerpColor([color1, color2], map(x, 0, width, 0, 1));
        fill(clr);
        rect(x + xPos, yPos, 1, height);
    }
}

/** Marker **/
void markerOutline(num x, num y) {
    pushMatrix();
        translate(x, y);
        
        strokeWeight(1.5);
        stroke(0);
        arc(0, 15, 27, 58, -179, 0); // body
        quad(7, -10, -7, -10, -7.4, -19, 7.4, -19); // cap thing
    popMatrix();
}
late DLImage markerGradient;
void loadMarkerGradient() {
    rectMode(CENTER);

    background(0, 0, 0);
    fill(255);
    markerOutline(100, 200);

    var markerMask = snip(0, 0, 200, 220);

    background(255);
    gradient(85, 198, 30, 35, color(52, 199, 133), color(47, 191, 204));

    markerGradient = snip(0, 0, 200, 220);
    markerGradient.mask(markerMask);
}
void marker(num x, num y, num s) {
    pushMatrix();
        translate(x, y);
        scale(s);
        translate(-100, -187);
        
        // Marker Tip
        fill(209, 209, 209);
        stroke(0, 0, 0);
        strokeWeight(1.3);
        arc(100, 180, 9, 21, -180, 0); 
        
        // Marker Outline
        markerOutline(100, 200);
        
        // Marker Fill
        image(markerGradient, 0, 0); 
    popMatrix();
}


/** Caligraphy Pen **/
void caligraphyPenOutline(num x, num y) {
    pushMatrix();
        translate(x, y);
        
        strokeWeight(1.4);
        stroke(0, 0, 0);
        beginShape();
        vertex(-6, 27);
        vertex(-6, 20);
        bezierVertex(-8, 12, -9, 12, -11, 8);
        bezierVertex(-7, -1, -4, -10, -2, -18);
        vertex(2, -18);
        bezierVertex(4, -10, 7, -1, 11, 8);
        bezierVertex(9, 12, 8, 12, 6, 20);
        vertex(6, 27);
        endShape();
        
        line(-8, 20, 8, 20);
    popMatrix();
}
late DLImage caligraphyPenGradient;
void loadCaligraphyPen() {
    background(0, 0, 0);
    fill(255, 255, 255);

    caligraphyPenOutline(162, 188);

    var caligraphyPenMask = snip();

    background(255, 255, 255);
    noStroke();

    // grey
    gradient(152, 190, 21, 40, color(235, 235, 235), color(156, 170, 171));

    // green
    gradient(156, 212, 12, 8, color(0, 110, 59), color(0, 179, 95));

    stroke(0, 0, 0);
    strokeWeight(1.2);
    line(162, 170, 162, 189);

    noFill();
    strokeWeight(1.4);
    ellipse(162, 192, 5, 5);

    caligraphyPenGradient = snip();
    caligraphyPenGradient.mask(caligraphyPenMask);
}
void caligraphyPen(num x, num y, num s) {
    pushMatrix();
        translate(x, y);
        scale(s);
        translate(-162, -188);
        
        caligraphyPenOutline(162, 188);
        image(caligraphyPenGradient, 0, 0);
    popMatrix();
}

/** Oil Brush **/
var oilBrushBristles = [];
void loadOilBrush() {
    for(var i = -10; i < 13; i += 3) {
        oilBrushBristles.add(map(sin(i * 537), -1, 1, -16, -8));
    }
}
void oilBrush(num x, num y, num s) {
    pushMatrix();
        translate(x, y);
        scale(s);
        stroke(0, 0, 0);
        strokeWeight(1.3);       
        
        // bristles
        fill(255, 187, 0);
        beginShape();
        vertex(-11, 5);
        vertex(-13, -14);
        bezierVertex(-12, -18, -14, -18, -9, -18);
        vertex(11, -18);
        bezierVertex(14, -18, 12, -17, 13, -14);
        vertex(11, 6);
        endShape();
        
        // brush stick
        fill(226, 233, 235);
        beginShape();
        vertex(-8, 28);
        vertex(-11, 6);
        vertex(11, 6);
        vertex(7.5, 28);
        endShape();
        
        var bristle = 0;
        strokeWeight(0.6);
        for(var i = -10; i < 13; i += 3) {
            line(i, -17, i, oilBrushBristles[bristle++]);
        }
    popMatrix();
}

/** Watercolor **/
void watercolor(num x, num y, num s) {
    pushMatrix();
        translate(x, y);
        scale(s);
        stroke(0, 0, 0);
        strokeWeight(1.3);
        
        fill(226, 233, 235);
        beginShape();
        vertex(-6, 28);
        vertex(-5, 14);
        vertex(5, 14);
        vertex(6, 28);
        endShape();
        
        fill(255, 187, 0);
        beginShape();
        vertex(-6, 14);
        bezierVertex(-3, 18, 6, 18, 8, 10);
        bezierVertex(10, -1, 0, 5, 3, -17);
        bezierVertex(-6, -6, -10, 9, -6, 14);
        endShape();
        
        noStroke();
        fill(255, 119, 0, 70);
        beginShape();
        vertex(-6, 14);
        bezierVertex(-3, 18, 6, 18, 8, 10);
        bezierVertex(10, -1, 0, 5, 3, -17);
        bezierVertex(-2, -1, 2, 1, 3, 6);
        bezierVertex(5, 11, 2, 19, -6, 14);
        endShape();
        stroke(0, 0, 0);
    popMatrix();
}

/** Pixel Pen **/
void pixelPenOutline(num x, num y) {
    pushMatrix();
        translate(x, y);
        strokeWeight(1.5);
        stroke(0, 0, 0);
        
        beginShape();
        vertex(-7.5, 28);
        vertex(-7.5, 15);
        vertex(-1, -14);
        vertex(1, -14);
        vertex(7.5, 15);
        vertex(7.5, 28);
        endShape();
        
        strokeWeight(1.3);
        line(0, -18, 0, -14);
    popMatrix();
}
late DLImage pixelPenGradient;
void loadPixelPen() {
    background(0, 0, 0);
    fill(255, 255, 255);

    pixelPenOutline(162, 200);

    var pixelPenMask = snip();

    background(255, 255, 255);
    noStroke();

    // light grey
    gradient(152, 200, 21, 28, color(240, 240, 240), color(112, 121, 122));

    // dark grey
    gradient(149, 222, 21, 12, color(189, 189, 189), color(45, 46, 46));

    stroke(0, 0, 0);
    line(171, 215, 152, 215);

    pixelPenGradient = snip();

    pixelPenGradient.mask(pixelPenMask);
}
void pixelPen(num x, num y, num s) {
    pushMatrix();
        translate(x, y);
        scale(s);
        translate(-162, -200);
        
        pixelPenOutline(162, 200);
        image(pixelPenGradient, 0, 0);
    popMatrix();
}

/** Pencil **/
void pencilOutline() {
    pushMatrix();
        translate(146, 200);
        strokeWeight(1.5);
        stroke(0, 0, 0);
        
        beginShape();
        vertex(-8, 28);
        vertex(-8, 13);
        vertex(0, -17);
        vertex(8, 13);
        vertex(8, 28);
        endShape();
    popMatrix();
}
late DLImage pencilGradient;
void loadPencil() {
    background(0, 0, 0);
    fill(255, 255, 255);
    pencilOutline();

    var pencilMask = snip();

    background(255, 199, 255);

    noStroke();
    gradient(135, 210, 21, 40, color(255, 239, 212), color(245, 178, 71));

    stroke(0);
    strokeWeight(1.0);
    fill(230, 230, 230);
    triangle(138, 185, 147, 177, 149, 197); // lead

    fill(255, 162, 0);
    quad(138, 213, 143, 218, 143, 229, 138, 229); // left
    quad(149, 218, 154, 213, 154, 229, 149, 229); // right

    // middle
    fill(255, 196, 0);
    beginShape();
    vertex(142.5, 218);
    vertex(146, 213);
    vertex(149.5, 218);
    vertex(149.5, 229);
    vertex(142.5, 229);
    endShape(CLOSE);

    pencilGradient = snip();
    pencilGradient.mask(pencilMask);
}
void pencil(num x, num y, num s) {
    pushMatrix();
        translate(x, y);
        scale(s);
        translate(-162+17, -200);
        
        pencilOutline();
        image(pencilGradient, 0, 0);
    popMatrix();
}

/** Eraser **/
void eraser(num x, num y, num s) {
    pushMatrix();
        translate(x, y);
        scale(s);
        
        rectMode(CENTER);
        strokeWeight(1.5);
        stroke(0, 0, 0);
        
        fill(255, 156, 202);
        rect(1, -5, 17, 24, 5); // eraser
        quad(-7.5, 28, -7.5, 3, 9.5, 3, 9.5, 28); // pencil base
        line(-9, 3, 11, 3);
        
        strokeWeight(1.0);
        fill(255, 162, 0);
        quad(-7.5, 28, -7.5, 3, -2, 3, -2, 28);
        quad(9.5, 28, 9.5, 3, 5, 3, 5, 28);
        
        fill(255, 174, 33);
        quad(5, 28, 5, 3, -3, 3, -3, 28);
    popMatrix();
}

/** Crayon **/
void crayonOutline() {
    pushMatrix();
        translate(171, 188);
        strokeWeight(1.5);
        stroke(0, 0, 0);
        
        quad(-8, 6, -2, -15, 3, -15, 8, 6); // tip
        
        // base
        fill(255, 59, 101);
        beginShape();
        vertex(-9, 28);
        vertex(-9, 7);
        vertex(9, 7);
        vertex(9, 28);
        endShape();
        
        rect(0, 9, 19, 8, 2); // rectangle part of tip
    popMatrix();
}
late DLImage crayonGradient;
void loadCrayon() {
    background(0, 0, 0);
    fill(255, 255, 255);
    crayonOutline();

    var crayonMask = snip();

    background(255, 255, 255);

    noStroke();
    gradient(161, 193, 21, 45, color(255, 135, 161), color(255, 0, 55));

    crayonGradient = snip();
    crayonGradient.mask(crayonMask);
}
void crayon(num x, num y, num s) {
    pushMatrix();
        translate(x, y);
        scale(s);
        translate(-171, -188);

        rectMode(CENTER);
        crayonOutline();
        image(crayonGradient, 0, 0);
    popMatrix();
}

/** Spray Can **/
void sprayCanOutline() {
    pushMatrix();
        translate(171, 188);
        strokeWeight(1.5);
        stroke(0, 0, 0);
        fill(255, 255, 255);
        
        // base
        beginShape();
        vertex(-10.5, 28);
        vertex(-10.5, -2);
        bezierVertex(-10, -15, 10, -15, 10.5, -2);
        vertex(10.5, 28);
        endShape();
    popMatrix();
}
late DLImage sprayCanGradient;
void loadSprayCan() {
    background(0);
    sprayCanOutline();

    var sprayCanMask = snip();

    background(255, 255, 255);

    noStroke();
    gradient(161, 193, 21, 45, color(255, 154, 99), color(255, 77, 0));

    sprayCanGradient = snip();
    sprayCanGradient.mask(sprayCanMask);
}    
void sprayCan(num x, num y, num s) {
    pushMatrix();
        translate(x, y);
        scale(s);
        translate(-171, -188);
        
        // cap
        noFill();
        strokeWeight(1.5);
        stroke(0, 0, 0);
        quad(169, 177, 168.5, 173, 172.5, 173, 172, 180);
        
        sprayCanOutline();
        image(sprayCanGradient, 0, 0);
        
        stroke(0, 0, 0);
        line(159, 187, 183, 187);
    popMatrix();
}

/** Paint Can **/
void paintCanOutline() {
    pushMatrix();
        translate(171, 188);
        strokeWeight(1.5);
        stroke(0, 0, 0);
        fill(255, 255, 255);
        
        // base
        rect(0, 9, 32, 38);
        
        strokeWeight(1);
        line(19, -10, -19, -10);
    popMatrix();
}
late DLImage paintCanGradient;
void loadPaintCan() {
    background(0, 0, 0);
    paintCanOutline();

    var paintCanMask = snip();

    background(255, 199, 255);

    noStroke();
    gradient(156, 193, 30, 45, color(181, 181, 181), color(112, 121, 122));

    fill(0, 255, 221);
    beginShape();
    vertex(155, 188);
    bezierVertex(155, 192, 159, 192, 159, 188);
    bezierVertex(160, 184, 163, 184, 164, 188);
    bezierVertex(164, 195, 169, 193, 169, 190);
    bezierVertex(170, 186, 174, 186, 174, 193);
    bezierVertex(174, 196, 179, 199, 179, 192);
    bezierVertex(178, 184, 183, 184, 183, 188);
    bezierVertex(182, 193, 187, 193, 187, 189);
    vertex(187, 177);
    vertex(155, 177);
    endShape(CLOSE);

    paintCanGradient = snip();
    paintCanGradient.mask(paintCanMask);
}
void paintCan(num x, num y, num s) {
    pushMatrix();
        translate(x, y);
        scale(s);
        translate(-171, -188);

        rectMode(CENTER);   
        paintCanOutline();
        image(paintCanGradient, 0, 0);
    popMatrix();
}
