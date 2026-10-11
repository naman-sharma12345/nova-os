#!/bin/sh
# check-session.sh: login-path checks for the session scripts, run from the repo root (no root, no desktop).
#  1. every tenka-* shell script parses
#  2. `tenka-theme --init` (run first by tenka-session, before the shell exists) sends no notification
#     (a notify-send there D-Bus-activates mako, which then holds the notification name ahead of the shell),
#     while a normal theme switch still does (proves the check reaches the end of the script)
#  3. `tenka-perf on` with no display sends no notification
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd); BIN="$ROOT/live/config/includes.chroot/usr/bin"
fail=0; T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
for f in "$BIN"/tenka-*; do
  head -1 "$f" | grep -q '^#!.*sh' || continue
  sh_=$(head -1 "$f" | grep -q bash && echo bash || echo sh)
  $sh_ -n "$f" || { echo "FAIL parse: $f"; fail=1; }
done
mkdir -p "$T/stub" "$T/home"
for c in notify-send hyprctl gsettings pgrep pkill waybar makoctl tenka-wallpaper tenka-sound pkexec xfconf-query \
         tenka-lite-apply dbus-update-activation-environment kitty fc-cache gtk-update-icon-cache; do
  printf '#!/bin/sh\necho "%s $*" >> "%s/calls"\n[ "%s" = pgrep ] && exit 1\nexit 0\n' "$c" "$T" "$c" > "$T/stub/$c"; chmod +x "$T/stub/$c"
done
sed "s#^THEMES=.*#THEMES=$ROOT/themes#" "$BIN/tenka-theme" > "$T/tenka-theme"
run() { : > "$T/calls"; env -i PATH="$T/stub:/usr/bin:/bin" HOME="$T/home" HYPRLAND_INSTANCE_SIGNATURE=x XDG_CURRENT_DESKTOP=Hyprland \
          bash "$T/tenka-theme" "$@" >/dev/null 2>&1; }
run xianxia;  grep -q '^notify-send' "$T/calls" || { echo "FAIL: a theme switch should still toast (check never reached the end?)"; fail=1; }
run --init;   grep -q '^notify-send' "$T/calls" && { echo "FAIL: tenka-theme --init sent a notification before the shell"; fail=1; }
grep -q '^waybar' "$T/calls" && { echo "FAIL: tenka-theme --init started waybar"; fail=1; }
: > "$T/calls"; env -i PATH="$T/stub:/usr/bin:/bin" HOME="$T/home" sh "$BIN/tenka-perf" on >/dev/null 2>&1
grep -q '^notify-send' "$T/calls" && { echo "FAIL: tenka-perf notified with no display"; fail=1; }
[ "$fail" = 0 ] && echo "check-session: ok"
exit $fail
