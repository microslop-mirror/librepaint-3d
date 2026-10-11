import './app-state.dart';
import './sidebar.dart' show sidebarX;

// padding between the canvas and the edges of the canvas area
const CANVAS_PADDING = 24;

// where the document is shown on screen, in logical coordinates
double viewX = 0;
double viewY = 0;
double viewZoom = 1;

void updateView() {
    final areaW = sidebarX - CANVAS_PADDING * 2;
    final areaH = lHeight - canvasAreaY - CANVAS_PADDING * 2;
    // shrink large images to fit, but never enlarge small ones
    viewZoom = [1.0, areaW / doc.width, areaH / doc.height].reduce((a, b) => a < b ? a : b);
    if (viewZoom <= 0) viewZoom = 1;
    viewX = ((sidebarX - doc.width * viewZoom) / 2).roundToDouble();
    viewY = (canvasAreaY + (lHeight - canvasAreaY - doc.height * viewZoom) / 2).roundToDouble();
}

double toDocX(num screenX) => (screenX - viewX) / viewZoom;
double toDocY(num screenY) => (screenY - viewY) / viewZoom;

bool isOverCanvasArea(num screenX, num screenY) {
    return screenX < sidebarX && screenY > canvasAreaY;
}

double toScreenX(num docX) => viewX + docX * viewZoom;
double toScreenY(num docY) => viewY + docY * viewZoom;
