import 'package:drawlite_dart/drawlite.dart'
    show Color, Drawlite;

import './ColorPicker.dart';
import './brushes.dart';
import './document.dart';

late Drawlite dl;

final canvasAreaY = 48 * 2 - 1;

// app scaling for high DPI displays
double appScale = 1.0;

// actual dimensions (lWidth * appScale, lHeight * appScale)
late int width;
late int height;

// logical dimensions
late double lWidth;
late double lHeight;

// possible scenes
enum Scene {
    Welcome,
    Draw
}

// current scne
Scene scene = Scene.Draw;

const SIDEBAR_WIDTH = 264;

// current brush color
Color currColor = brushColors[14];

List<Color> customColors = [];

// the image being edited
late PaintDocument doc;

// selected marker index
int selectedMarker = 0;
// stores the brush stroke currently being painted
BrushStroke? currDrawStroke = null;

ColorPicker? colorPicker = null;