import 'dart:io';
import 'dart:typed_data';

import 'package:dcanvas/dcanvas.dart' show Canvas;
import 'package:dcanvas/CanvasRenderingContext.dart' show Context2D, CSSColor, ImageData;
import 'package:image/image.dart' as img;

const DEFAULT_DOC_WIDTH = 500;
const DEFAULT_DOC_HEIGHT = 400;

// file extensions LibrePaint 3D can save to
const SAVE_EXTENSIONS = ["png", "jpg", "jpeg", "bmp", "gif", "tif", "tiff", "tga"];

const MAX_UNDO_STEPS = 50;
const MAX_HISTORY_BYTES = 512 * 1024 * 1024;

class _Snapshot {
    final ImageData pixels;
    final int version;
    _Snapshot(this.pixels, this.version);
}

// the image being painted, kept off screen so it isn't limited by the window
class PaintDocument {
    late Canvas canvas;
    late Context2D ctx;

    // where the image was opened from or last saved to
    String? filePath;

    // each change gets a new version so undoing back to the saved version
    // counts as unmodified
    int _version = 0;
    int _nextVersion = 1;
    int _savedVersion = 0;
    final List<_Snapshot> _undoStack = [];
    final List<_Snapshot> _redoStack = [];

    // true when there are changes since the last save
    bool get modified => _version != _savedVersion;
    bool get canUndo => _undoStack.isNotEmpty;
    bool get canRedo => _redoStack.isNotEmpty;

    int get width => canvas.width;
    int get height => canvas.height;

    PaintDocument.blank([int width = DEFAULT_DOC_WIDTH, int height = DEFAULT_DOC_HEIGHT]) {
        _init(width, height);
    }

    PaintDocument._sized(int width, int height) {
        _init(width, height);
    }

    void _init(int width, int height) {
        canvas = Canvas(width, height);
        ctx = canvas.getContext("2d");
        ctx.fillStyle = CSSColor(255, 255, 255, 1);
        ctx.fillRect(0, 0, width, height);
    }

    String get displayName {
        final path = filePath;
        if (path == null) return "Untitled";
        return path.split(Platform.pathSeparator).last;
    }

    // returns null if the file can't be read or isn't a supported image
    static PaintDocument? open(String path) {
        final Uint8List bytes;
        try {
            bytes = File(path).readAsBytesSync();
        } catch (e) {
            return null;
        }

        final decoded = img.decodeNamedImage(path, bytes) ?? img.decodeImage(bytes);
        if (decoded == null) return null;

        final rgba = decoded.convert(format: img.Format.uint8, numChannels: 4, alpha: 255);
        final data = rgba.getBytes(order: img.ChannelOrder.rgba);

        final doc = PaintDocument._sized(rgba.width, rgba.height);
        // composite onto the white background so transparent areas don't turn black
        final layer = Canvas(rgba.width, rgba.height);
        layer.getContext("2d").putImageData(ImageData(data, rgba.width, rgba.height), 0, 0);
        doc.ctx.drawImage(layer, 0, 0);

        doc.filePath = path;
        return doc;
    }

    // call before changing the pixels so the change can be undone
    void beginChange() {
        _undoStack.add(_Snapshot(getPixels(), _version));
        _redoStack.clear();
        _version = _nextVersion++;
        _trimHistory();
    }

    void undo() {
        if (!canUndo) return;
        _redoStack.add(_Snapshot(getPixels(), _version));
        _restore(_undoStack.removeLast());
    }

    void redo() {
        if (!canRedo) return;
        _undoStack.add(_Snapshot(getPixels(), _version));
        _restore(_redoStack.removeLast());
    }

    void _restore(_Snapshot snap) {
        // resizing and cropping change the size, so restore it too
        if (snap.pixels.width != width || snap.pixels.height != height) {
            _init(snap.pixels.width, snap.pixels.height);
        }
        ctx.putImageData(snap.pixels, 0, 0);
        _version = snap.version;
    }

    // replaces the canvas with a new size, drawing the old one onto it
    void _replaceCanvas(int newWidth, int newHeight, void Function(Canvas old) draw) {
        final old = canvas;
        _init(newWidth, newHeight);
        draw(old);
    }

    // changes the canvas size; scaleImage stretches the picture to fit,
    // otherwise it stays anchored to the top left and new space is white
    void resize(int newWidth, int newHeight, bool scaleImage) {
        if (newWidth == width && newHeight == height) return;
        beginChange();
        _replaceCanvas(newWidth, newHeight, (old) {
            if (scaleImage) {
                ctx.drawImage(old, 0, 0, newWidth, newHeight);
            } else {
                ctx.drawImage(old, 0, 0);
            }
        });
    }

    void crop(int x, int y, int cropWidth, int cropHeight) {
        if (cropWidth <= 0 || cropHeight <= 0) return;
        beginChange();
        _replaceCanvas(cropWidth, cropHeight, (old) {
            ctx.drawImage(old, -x, -y);
        });
    }

    // drop the oldest undo steps once the history uses too much memory
    void _trimHistory() {
        int bytes() => [..._undoStack, ..._redoStack].fold(0, (sum, snap) => sum + snap.pixels.data.length);
        while (_undoStack.length > 1 && (_undoStack.length > MAX_UNDO_STEPS || bytes() > MAX_HISTORY_BYTES)) {
            _undoStack.removeAt(0);
        }
    }

    ImageData getPixels() {
        return ctx.getImageData(0, 0, width, height);
    }

    // returns an error message, or null on success
    String? save(String path) {
        final ext = path.split(".").last.toLowerCase();
        if (!SAVE_EXTENSIONS.contains(ext)) {
            return "Unsupported file type: .$ext";
        }

        final pixels = Uint8List.fromList(getPixels().data);
        final image = img.Image.fromBytes(
            width: width,
            height: height,
            bytes: pixels.buffer,
            numChannels: 4,
            order: img.ChannelOrder.rgba
        );

        final encoded = img.encodeNamedImage(path, image);
        if (encoded == null) {
            return "Unable to encode image as .$ext";
        }

        try {
            File(path).writeAsBytesSync(encoded);
        } catch (e) {
            return "Unable to write $path: $e";
        }

        filePath = path;
        _savedVersion = _version;
        return null;
    }
}
