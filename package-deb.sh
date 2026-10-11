#!/bin/sh
# Builds the .deb with `jvbuild package`, then fixes up what jvbuild can't express:
# - drops build-essential, which is only needed to compile, not to run
# - bundles the Open Sans font the UI is designed for
# - makes the installed files owned by root with standard permissions
set -e
cd "$(dirname "$0")"

jvbuild build
jvbuild package

deb=$(ls -t jvbuild-out/librepaint3d_*.deb | head -n 1)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

dpkg-deb -R "$deb" "$work/pkg"
pkg="$work/pkg"

sed -i -e 's/build-essential, //' -e 's/, build-essential//' -e 's/^Depends: build-essential$//' "$pkg/DEBIAN/control"

fontdir="$pkg/usr/share/fonts/truetype/librepaint3d"
mkdir -p "$fontdir"
cp assets/OpenSans/static/OpenSans-Regular.ttf assets/OpenSans/static/OpenSans-Bold.ttf assets/OpenSans/OFL.txt "$fontdir/"

# refresh the font cache after install
sed -i 's|^\( *\)exit 0|\1fc-cache -f /usr/share/fonts/truetype/librepaint3d >/dev/null 2>\&1 \|\| true\n\1exit 0|' "$pkg/DEBIAN/postinst"

find "$pkg" -type d -exec chmod 0755 {} +
find "$pkg" -type f -exec chmod 0644 {} +
chmod 0755 "$pkg/usr/bin/librepaint3d" "$pkg/DEBIAN/postinst" "$pkg/DEBIAN/prerm"

size=$(du -sk --exclude=DEBIAN "$pkg" | cut -f1)
sed -i "s/^Installed-Size: .*/Installed-Size: $size/" "$pkg/DEBIAN/control"

dpkg-deb --root-owner-group -b "$pkg" "$deb" >/dev/null
echo "Packaged $deb"
