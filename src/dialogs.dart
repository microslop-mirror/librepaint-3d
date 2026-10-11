import 'dart:io';

// native dialogs through zenity (GNOME) or kdialog (KDE), since SDL has none

const IMAGE_PATTERNS = "*.png *.jpg *.jpeg *.bmp *.gif *.webp *.tif *.tiff *.tga";

bool _hasCommand(String cmd) {
    try {
        return Process.runSync("which", [cmd]).exitCode == 0;
    } catch (e) {
        return false;
    }
}

final bool _hasZenity = _hasCommand("zenity");
final bool _hasKdialog = _hasCommand("kdialog");

bool get dialogsAvailable => _hasZenity || _hasKdialog;

Future<String?> _run(String cmd, List<String> args) async {
    final result = await Process.run(cmd, args);
    if (result.exitCode != 0) return null;
    final out = result.stdout.toString().trim();
    return out.isEmpty ? null : out;
}

Future<String?> openFileDialog() async {
    if (_hasZenity) {
        return _run("zenity", [
            "--file-selection",
            "--title=Open",
            "--file-filter=Images | $IMAGE_PATTERNS",
            "--file-filter=All files | *",
        ]);
    } else if (_hasKdialog) {
        return _run("kdialog", ["--getopenfilename", Platform.environment["HOME"] ?? ".", "$IMAGE_PATTERNS|Images"]);
    }
    return null;
}

// suggestedPath may be a full path or just a file name
Future<String?> saveFileDialog(String suggestedPath) async {
    String? path;
    if (_hasZenity) {
        path = await _run("zenity", [
            "--file-selection",
            "--save",
            "--title=Save as",
            "--filename=$suggestedPath",
            "--file-filter=PNG | *.png",
            "--file-filter=JPEG | *.jpg *.jpeg",
            "--file-filter=BMP | *.bmp",
            "--file-filter=All images | $IMAGE_PATTERNS",
        ]);
    } else if (_hasKdialog) {
        path = await _run("kdialog", ["--getsavefilename", suggestedPath, "*.png|PNG\n*.jpg *.jpeg|JPEG\n*.bmp|BMP"]);
    }
    if (path == null) return null;

    // default to PNG when no extension was typed
    final name = path.split(Platform.pathSeparator).last;
    if (!name.contains(".")) {
        path = "$path.png";
    }
    return path;
}

// returns true if the user wants to save, false to discard, null to cancel
Future<bool?> askSaveChanges(String docName) async {
    final text = "Do you want to save changes to $docName?";
    if (_hasZenity) {
        final result = await Process.run("zenity", [
            "--question",
            "--no-markup",
            "--title=LibrePaint 3D",
            "--text=$text",
            "--ok-label=Save",
            "--cancel-label=Don't save",
            "--extra-button=Cancel",
        ]);
        if (result.stdout.toString().trim() == "Cancel") return null;
        if (result.exitCode == 0) return true;
        if (result.exitCode == 1) return false;
        // dialog closed with the window's X button
        return null;
    } else if (_hasKdialog) {
        final result = await Process.run("kdialog", ["--title", "LibrePaint 3D", "--yesnocancel", text]);
        if (result.exitCode == 0) return true;
        if (result.exitCode == 1) return false;
        return null;
    }
    // without a dialog program we can't ask; don't trap the user in the app
    stderr.writeln("LibrePaint 3D: zenity or kdialog is needed to ask about unsaved changes");
    return false;
}

Future<void> showError(String message) async {
    stderr.writeln("LibrePaint 3D: $message");
    if (_hasZenity) {
        await Process.run("zenity", ["--error", "--no-markup", "--title=LibrePaint 3D", "--text=$message"]);
    } else if (_hasKdialog) {
        await Process.run("kdialog", ["--title", "LibrePaint 3D", "--error", message]);
    }
}
