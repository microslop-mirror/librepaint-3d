import 'dart:io';

import './app-state.dart';
import './dialogs.dart';
import './document.dart';

// set while a dialog is open so actions don't overlap
bool _busy = false;

// called after the document is replaced or changes state, e.g. to update the title
void Function() onDocumentChanged = () {};
// called when the app should exit
void Function() onQuit = () {};
// called when a new document replaces the current one
void Function() onDocumentReplaced = () {};
// called before saving etc., to commit edits that are still in progress
void Function() beforeFileAction = () {};

Future<void> _guard(Future<void> Function() action) async {
    if (_busy) return;
    _busy = true;
    beforeFileAction();
    try {
        await action();
    } finally {
        _busy = false;
        onDocumentChanged();
    }
}

void _setDocument(PaintDocument newDoc) {
    doc = newDoc;
    currDrawStroke = null;
    onDocumentReplaced();
    onDocumentChanged();
}

// returns false if the user cancelled
Future<bool> _confirmDiscardChanges() async {
    if (!doc.modified) return true;
    final save = await askSaveChanges(doc.displayName);
    if (save == null) return false;
    if (save) return await _save(false);
    return true;
}

// returns true if the document was saved
Future<bool> _save(bool askForPath) async {
    var path = doc.filePath;
    if (askForPath || path == null) {
        final suggested = path ?? "${Platform.environment["HOME"] ?? "."}/Untitled.png";
        path = await saveFileDialog(suggested);
        if (path == null) return false;
    }

    final error = doc.save(path);
    if (error != null) {
        await showError(error);
        return false;
    }
    return true;
}

void newDocument() => _guard(() async {
    if (!await _confirmDiscardChanges()) return;
    _setDocument(PaintDocument.blank());
});

void openDocument() => _guard(() async {
    if (!await _confirmDiscardChanges()) return;
    final path = await openFileDialog();
    if (path == null) return;
    await _openPath(path);
});

Future<void> _openPath(String path) async {
    final opened = PaintDocument.open(path);
    if (opened == null) {
        await showError("Unable to open $path\nThe file may not be a supported image.");
        return;
    }
    _setDocument(opened);
}

// opens a file given on the command line, e.g. from "Open with" in a file manager
void openDocumentPath(String path) => _guard(() => _openPath(path));

void saveDocument() => _guard(() async {
    await _save(false);
});

void saveDocumentAs() => _guard(() async {
    await _save(true);
});

void quit() => _guard(() async {
    if (!await _confirmDiscardChanges()) return;
    onQuit();
});
