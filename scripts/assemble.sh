#!/bin/sh
# Assemble the live-build tree in $BUILD (default: ./build): config + generated themes + theme packs.
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
BUILD=${BUILD:-$ROOT/build}
cd "$ROOT"
sh scripts/check-session.sh   # login-path checks (session scripts parse; no toast before the shell)
python3 scripts/gen-themes.py
python3 scripts/gen-lite.py
python3 scripts/gen-system.py
python3 scripts/gen-folders.py edge
python3 scripts/gen-cursors.py
mkdir -p "$BUILD"
rsync -a --delete --exclude chroot --exclude binary --exclude cache --exclude '*.iso' --exclude '.build' --exclude 'config/hooks/normal' --exclude 'local' --exclude 'chroot.*' --exclude '*.log' --exclude 'config/binary' --exclude 'config/bootstrap' --exclude 'config/chroot' --exclude 'config/common' --exclude 'config/source' \
      live/ "$BUILD/live/"
cp distro.conf "$BUILD/"
T="$BUILD/live/config/includes.chroot/usr/share/tenka/themes"
mkdir -p "$T"
for t in themes/*/; do
  n=$(basename "$t")
  rsync -a --delete --exclude 'preview-contact.jpg' --exclude '*.md' "$t" "$T/$n/"
  # 1920x1080 copies for Tenka Lite
  mkdir -p "$T/$n/wallpapers/1080"
  python3 - "$T/$n/wallpapers" <<'PY'
import sys, glob, os
from PIL import Image
d = sys.argv[1]
for f in sorted(glob.glob(os.path.join(d, "[0-9]*.jpg"))):
    out = os.path.join(d, "1080", os.path.basename(f))
    if not os.path.exists(out):
        Image.open(f).convert("RGB").resize((1920, 1080), Image.LANCZOS).save(out, quality=90)
PY
done
# the Tenka shell (Quickshell config) and its per-theme words
python3 scripts/gen-shell.py
mkdir -p "$BUILD/live/config/includes.chroot/etc/xdg/quickshell"
rsync -a --delete shell/quickshell/tenka/ "$BUILD/live/config/includes.chroot/etc/xdg/quickshell/tenka/"
echo "assembled: $BUILD/live"
