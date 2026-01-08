#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APPDIR="$ROOT/src-tauri/target/release/bundle/appimage/Antigravity Tools.AppDir"
OUTDIR="$ROOT/src-tauri/target/release/bundle/appimage"
OUT_APPIMAGE="$OUTDIR/Antigravity_Tools-x86_64.AppImage"
PLUGIN_APPIMAGE="$HOME/.cache/tauri/linuxdeploy-plugin-appimage.AppImage"

if ! command -v rsync >/dev/null; then
    echo "rsync not found. Install rsync or use the manual steps."
    exit 1
fi

mkdir -p "$OUTDIR"

echo "==> Building AppImage via Tauri (NO_STRIP=1)"
if NO_STRIP=1 APPIMAGE_EXTRACT_AND_RUN=1 npm run tauri build -- --bundles appimage; then
    echo "==> Tauri build succeeded"
    exit 0
fi

echo "==> Tauri build failed; creating AppImage manually"
if [ ! -d "$APPDIR" ]; then
    echo "AppDir not found: $APPDIR"
    exit 1
fi

if [ ! -f "$PLUGIN_APPIMAGE" ]; then
    echo "Missing appimagetool plugin: $PLUGIN_APPIMAGE"
    exit 1
fi

workdir="$(mktemp -d)"
rsync -a --exclude 'usr/lib32' "$APPDIR/" "$workdir/Antigravity Tools.AppDir/"

appimg_tmp="$(mktemp -d)"
cp "$PLUGIN_APPIMAGE" "$appimg_tmp/"
(cd "$appimg_tmp" && ./linuxdeploy-plugin-appimage.AppImage --appimage-extract >/dev/null)

ARCH=x86_64 "$appimg_tmp/squashfs-root/usr/bin/appimagetool" \
    "$workdir/Antigravity Tools.AppDir" \
    "$OUT_APPIMAGE"

echo "==> Wrote $OUT_APPIMAGE"
