# LibrePaint 3D
The free and open source replacement for MS Paint 3D

## About
Microsoft ~~is killing~~ has killed off Paint 3D. 
> Paint 3D was removed from the Microsoft Store on November 4, 2024. Paint 3D is no longer available for download from Microsoft.

[https://learn.microsoft.com/en-us/windows/whats-new/deprecated-features-resources#paint-3d](https://learn.microsoft.com/en-us/windows/whats-new/deprecated-features-resources#paint-3d)

This is unfortunate as Paint 3D is one of the best image editing softwares. Although it isn't as powerful as Photoshop or GIMP, it is far easier to use which makes it perfect for quickly cropping images, scribbling out sensitive information, and making memes. Paint 3D's magic select feature is one of the most useful features of Paint 3D that other image editors don't have.

Because Microsoft is killing off Paint 3D and because I will be abandoning Windows on October 14, 2025 which is the end of life date for Windows 10 after which it will no longer receive security updates, I have resorted to programming my own open source Paint 3D.

## Legal
This project is a clean implementation of Microsoft's Paint 3D. No code from Microsoft
Paint 3D was used in the creation of LibrePaint 3D. Although LibrePaint 3D was designed to have
a similiar design and layout to Microsoft Paint 3D, none of LibrePaint 3D's assets are taken
from Microsoft Paint 3D. LibrePaint 3D is not affiliated with Microsoft. 

## Quality Disclaimer
MS Paint 3D was presumably created by an entire team of professional developers. LibrePaint 3D was created by a singular teenager in his limited free time. Set your expectations accordingly. That is LibrePaint 3D, as open source software tends to be, is a bit crappier, but it will improve over time.

## Development
#### Dependencies
- [Dart](https://dart.dev/get-dart) - the programming language
- [jvbuild](https://github.com/vExcess/jvbuild) - custom dependency manager, build system, and packaging tool

Quick run:
```
jvbuild run dev
```

Build:
```
jvbuild build
```

Package (.deb):
```
./package-deb.sh
```
This runs `jvbuild package` and then removes the `build-essential` dependency, bundles the Open Sans font, and makes the installed files owned by root.

Install the package:
```
sudo apt install ./jvbuild-out/librepaint3d_<version>_x64.deb
```

If the first `jvbuild build` after `jvbuild install` fails with `No pubspec.yaml found for package drawlite_dart`, run it again; jvbuild resolves Dart packages before it has finished generating drawlite's pubspec.yaml.


## High DPI Screens
LibrePaint 3D follows the desktop's scale (`GDK_SCALE` or the X11 `Xft.dpi` setting).
To pick a scale yourself, set `LIBREPAINT_SCALE`, e.g. `LIBREPAINT_SCALE=1.5 librepaint3d`.

## Platform Support
| Platform  | Support |
| ------------- | ------------- |
| Debian-based Linux (Debian, Ubuntu, Mint, etc.) | Supported |
| Fedora-based Linux | Support Planned |
| Arch-based Linux   | Support Planned  |
| Other Linux        | No Official Support, but the Flatpak will probably work |
| Windows | Support Planned |
| macOS   | No Support Planned  |
| iOS     | No Support Planned  |

# Todo
- brushes (help plz)
- color picker
- text boxes
- optimizations
- everything

## Contributors
- [vExcess](https://github.com/vExcess) - Primary Developer
- [Virtuosa](https://www.khanacademy.org/profile/kaid_1077077685654678878412920/projects) - Graphics Designer

## LibrePaint 3D running on Linux Mint:
![screenshot](https://github.com/microslop-mirror/librepaint-3d/blob/main/screenshot.png?raw=true)
