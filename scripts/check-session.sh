#!/bin/sh
# check-session.sh: login-path checks for the session scripts, run from the repo root (no root, no desktop).
#  1. every tenka-* shell script parses
#  2. `tenka-theme --init` (run first by tenka-session, before the shell exists) sends no notification
#     (a notify-send there D-Bus-activates mako, which then holds the notification name ahead of the shell),
#     while a normal theme switch still does (proves the check reaches the end of the script)
#  3. `tenka-perf on` with no display sends no notification
#  4. tenka-air-join never puts the Wi-Fi password on a command line; its file is 0600 and removed,
#     and a profile it created is deleted again when the join fails
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
# 4. tenka-air-join: the word rides stdin -> 0600 file, never argv
mkdir -p "$T/air" "$T/run"; chmod 700 "$T/run"
cat > "$T/air/nmcli" <<'EOF'
#!/bin/sh
echo "nmcli $*" >> "$AIRLOG"
case "$*" in
  "con show id"*) exit 10 ;;
  *"con up"*) f=${*##* }; echo "mode $(stat -c %a "$f") $(cat "$f")" >> "$AIRLOG"; [ -n "${AIRFAIL:-}" ] && exit 4; exit 0 ;;
esac
exit 0
EOF
chmod +x "$T/air/nmcli"
for mode in ok fail; do
  : > "$T/airlog"
  printf 'pa:ss word\n' | env -i PATH="$T/air:/usr/bin:/bin" XDG_RUNTIME_DIR="$T/run" AIRLOG="$T/airlog" AIRFAIL=$([ $mode = fail ] && echo 1) \
    sh "$BIN/tenka-air-join" "Home" "WPA2" > "$T/airout" 2>&1
  grep '^nmcli' "$T/airlog" | grep -q 'pa:ss' && { echo "FAIL: tenka-air-join put the password on nmcli's command line"; fail=1; }
  grep -q '^mode 600 802-11-wireless-security.psk:pa:ss word$' "$T/airlog" || { echo "FAIL: tenka-air-join passwd-file wrong ($mode)"; fail=1; }
  [ -z "$(ls -A "$T/run")" ] || { echo "FAIL: tenka-air-join left its password file behind"; fail=1; }
  [ $mode = fail ] && { grep -q '^nmcli con delete' "$T/airlog" || { echo "FAIL: failed join kept the new profile"; fail=1; }; grep -q '^@rc 4$' "$T/airout" || { echo "FAIL: rc not reported"; fail=1; }; }
done
[ "$fail" = 0 ] && echo "check-session: ok"
exit $fail
