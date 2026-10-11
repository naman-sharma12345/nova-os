#!/bin/sh
# check-qml.sh: every shipped QML file parses (the shell, the welcome app, the login theme source).
# A syntax slip in one Quickshell file leaves a blank desktop; this fails the build instead.
# Uses qmlformat (Debian: qt6-declarative-dev-tools). Without it the check says so and skips.
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
Q=$(command -v qmlformat || true); [ -n "$Q" ] || { [ -x /usr/lib/qt6/bin/qmlformat ] && Q=/usr/lib/qt6/bin/qmlformat; }
[ -n "$Q" ] || { echo "check-qml: qmlformat not installed, skipped"; exit 0; }
fail=0; n=0
for f in $(cd "$ROOT" && find shell live/config/includes.chroot scripts -name '*.qml' \
             -not -path 'live/config/includes.chroot/usr/share/sddm/themes/tenka-*' | sort); do
  n=$((n+1))
  "$Q" "$ROOT/$f" >/dev/null 2>"${TMPDIR:-/tmp}/qmlfmt.err" || { echo "FAIL qml: $f"; head -3 "${TMPDIR:-/tmp}/qmlfmt.err"; fail=1; }
done
rm -f "${TMPDIR:-/tmp}/qmlfmt.err"
[ $fail -eq 0 ] && echo "check-qml: $n QML files parse"
exit $fail
