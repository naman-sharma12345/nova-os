#!/bin/sh
# check-session.sh: login-path checks for the session scripts, run from the repo root (no root, no desktop).
#  1. every tenka-* shell script parses
#  2. `tenka-theme --init` (run first by tenka-session, before the shell exists) sends no notification
#     (a notify-send there D-Bus-activates mako, which then holds the notification name ahead of the shell),
#     while a normal theme switch still does (proves the check reaches the end of the script)
#  3. `tenka-perf on` with no display sends no notification
#  4. tenka-air-join never puts the Wi-Fi password on a command line; its file is 0600 and removed,
#     and a profile it created is deleted again when the join fails
#  5. tenka-bond-agent carries BlueZ's PIN / passkey / yes-no questions to The Bond and its answers back
#  6. tenka-lantern reads the battery facts (charge, time, health, devices) and sets the power profile
#  7. the Inkstone's search puts whole words and word starts ahead of matches inside a word (needs node)
#  8. tenka-loupe freezes the screen into a private file, copies, and keeps LATELY (colours only, newest first)
#  9. tenka-codex reads every key from the live Hyprland / XFCE config, including the user's own user.lua
# 10. tenka-glance tells a folder, a text and a picture apart, and reads a picture's size from its header
# 11. tenka-colophon reads the machine (kernel, memory, packages) and names the desk after the active theme
# 12. The Drift is wired: hypridle opens it (ipc "open", not qs's own word "show"), and Lite's screensaver theme
#     points at a program in xfce4-screensaver's own dir (it runs no theme from anywhere else)
# 13. tenka-almanac names the right solar term and moon for known dates (Dec 9 2026 is a new moon, the Mar 2027
#     equinox, a full moon), the term's line follows the theme (micro-season on Tenka, saying on Tianxia), the
#     wheel's dates (2026 equinox and solstice, the Oct 26 full moon to the hour), and the card is wired
# 14. tenka-incense lights a stick (state burning, about the minutes asked), puts it out (no sleeper left behind),
#     and is wired in both sessions; Incense.qml imports Quickshell.Hyprland (its GlobalShortcut needs it, or the
#     whole shell fails to load)
# 15. The Garden: the four beds exist and loop clean (48 s, Vorbis), tenka-ambience knows them, refuses an
#     unknown one, and is wired in both sessions (Super+G, the card in shell.qml, Lite's window, the menu entry)
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
# 5. tenka-bond-agent: BlueZ's PIN / passkey / yes-no questions reach The Bond and its answers reach BlueZ
#    (a fake BlueZ on a private bus; the answer rides stdin into a 0600 file). Needs python3-gi + dbus-daemon.
if python3 -c 'from gi.repository import Gio' 2>/dev/null && command -v dbus-daemon >/dev/null; then
  B="$T/bond"; mkdir -p "$B/bin" "$B/run"; chmod 700 "$B/run"
  printf '#!/bin/sh\necho "qs $*" >> "%s/qslog"\n' "$B" > "$B/bin/qs"; chmod +x "$B/bin/qs"
  cat > "$B/fake.py" <<'EOF'
import sys
from gi.repository import Gio, GLib
bus = Gio.bus_get_sync(Gio.BusType.SESSION)
DEV = "/org/bluez/hci0/dev_AA_BB"
XML = """<node><interface name="org.bluez.AgentManager1"><method name="RegisterAgent"><arg type="o" direction="in"/><arg type="s" direction="in"/></method>
<method name="RequestDefaultAgent"><arg type="o" direction="in"/></method></interface>
<interface name="org.freedesktop.DBus.Properties"><method name="GetAll"><arg type="s" direction="in"/><arg type="a{sv}" direction="out"/></method></interface></node>"""
info = Gio.DBusNodeInfo.new_for_xml(XML)
st = {}
def out(*a): print(*a, flush=True)
def done(name):
    def cb(conn, res):
        try: out(name, conn.call_finish(res).unpack())
        except GLib.Error as e: out(name, e.message.split(":")[-1].strip() if "Error." not in e.message else e.message.split("Error.")[1].split(":")[0])
        step()
    return cb
def call(m, args, name):
    bus.call(st["agent"], st["path"], "org.bluez.Agent1", m, args, None, Gio.DBusCallFlags.NONE, 20000, None, done(name))
steps = [lambda: call("RequestPasskey", GLib.Variant("(o)", (DEV,)), "passkey"),
         lambda: call("RequestConfirmation", GLib.Variant("(ou)", (DEV, 4821)), "confirm"),
         lambda: call("RequestPinCode", GLib.Variant("(o)", (DEV,)), "pin"),
         lambda: loop.quit()]
def step(): steps.pop(0)()
def mgr(conn, sender, path, iface, method, params, inv):
    if method == "RegisterAgent": st["agent"], st["path"], st["cap"] = sender, params.unpack()[0], params.unpack()[1]; inv.return_value(None)
    elif method == "RequestDefaultAgent": inv.return_value(None); out("registered", st["cap"]); GLib.timeout_add(200, lambda: step() and False)
def props(conn, sender, path, iface, method, params, inv):
    inv.return_value(GLib.Variant("(a{sv})", ({"Alias": GLib.Variant("s", "Kestrel Keys"), "Address": GLib.Variant("s", "AA:BB"),
                                              "Paired": GLib.Variant("b", False)},)))
bus.register_object("/org/bluez", info.interfaces[0], mgr, None, None)
bus.register_object(DEV, info.interfaces[1], props, None, None)
Gio.bus_own_name_on_connection(bus, "org.bluez", Gio.BusNameOwnerFlags.NONE, None, None)
loop = GLib.MainLoop(); GLib.timeout_add(30000, loop.quit); loop.run()
EOF
  ADDR=$(dbus-daemon --session --fork --print-address=1 --print-pid=4 4>"$B/dpid")
  export DBUS_SESSION_BUS_ADDRESS="$ADDR"
  python3 "$B/fake.py" > "$B/fake.out" 2>&1 & FP=$!
  sleep 0.5
  env PATH="$B/bin:/usr/bin:/bin" XDG_RUNTIME_DIR="$B/run" TENKA_BOND_BUS=session DBUS_SESSION_BUS_ADDRESS="$ADDR" \
    python3 "$BIN/tenka-bond-agent" > "$B/agent.out" 2>&1 & AP=$!
  ans() {  # wait for a question of kind $1, then answer $2 the way The Bond does
    for _ in $(seq 60); do grep -q "\"kind\": \"$1\"" "$B/run/tenka-bond/ask.json" 2>/dev/null && break; sleep 0.1; done
    id=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["id"])' "$B/run/tenka-bond/ask.json" 2>/dev/null)
    grep -q '"name": "Kestrel Keys"' "$B/run/tenka-bond/ask.json" || { echo "FAIL: bond agent asked without the device's name ($1)"; fail=1; }
    printf '%s %s\n' "$id" "$2" | env XDG_RUNTIME_DIR="$B/run" python3 "$BIN/tenka-bond-agent" answer
  }
  ans passkey 123456; ans confirm no; ans pin 0000
  for _ in $(seq 40); do grep -q '^pin' "$B/fake.out" && break; sleep 0.1; done
  grep -q '^registered KeyboardDisplay' "$B/fake.out" || { echo "FAIL: bond agent never registered with BlueZ"; fail=1; }
  grep -q '^passkey (123456,)' "$B/fake.out" || { echo "FAIL: passkey did not reach BlueZ"; fail=1; }
  grep -q '^confirm Rejected' "$B/fake.out" || { echo "FAIL: a refused number was not rejected"; fail=1; }
  grep -q "^pin ('0000',)" "$B/fake.out" || { echo "FAIL: pin did not reach BlueZ"; fail=1; }
  grep -q 'ipc call bluetooth ask' "$B/qslog" 2>/dev/null || { echo "FAIL: bond agent never rang the shell"; fail=1; }
  [ "$(stat -c %a "$B/run/tenka-bond")" = 700 ] || { echo "FAIL: bond agent's dir is not private"; fail=1; }
  grep -q '"kind": "none"' "$B/run/tenka-bond/ask.json" || { echo "FAIL: answered question was not cleared"; fail=1; }
  [ -e "$B/run/tenka-bond/answer" ] && { echo "FAIL: an answer was left behind"; fail=1; }
  kill $AP $FP 2>/dev/null; kill "$(cat "$B/dpid")" 2>/dev/null
else
  echo "check-session: bond agent test skipped (no python3-gi / dbus-daemon)"
fi
# 6. tenka-lantern reads the kernel's power_supply ledger (a made-up one here): the charge, the time left from
#    energy or from charge x voltage, health against design, a mouse's own charge, AC, and the profile it sets
if command -v python3 >/dev/null 2>&1; then
  P="$T/ps"; mkdir -p "$P/AC" "$P/BAT0" "$P/BAT1" "$P/hid0" "$T/ppd"
  w() { d=$1; shift; while [ $# -gt 1 ]; do printf '%s\n' "$2" > "$P/$d/$1"; shift 2; done; }
  w AC type Mains online 0
  w BAT0 type Battery present 1 status Discharging capacity 72 energy_now 41040000 energy_full 57000000 energy_full_design 60000000 power_now 10600000 cycle_count 214
  w BAT1 type Battery present 1 status Charging capacity 50 charge_now 2000000 charge_full 4000000 charge_full_design 5000000 current_now 1000000 voltage_now 12000000
  w hid0 type Battery scope Device capacity 41 model_name Mouse
  printf '#!/bin/sh\n[ "$1" = set ] && { echo "$2" > "%s/ppd/cur"; exit 0; }\nprintf "  performance:\\n    Driver: x\\n\\n* balanced:\\n    Driver: x\\n\\n  power-saver:\\n    Driver: x\\n"\n' "$T" > "$T/stub/powerprofilesctl"; chmod +x "$T/stub/powerprofilesctl"
  out=$(TENKA_POWER_ROOT="$P" PATH="$T/stub:$PATH" python3 "$BIN/tenka-lantern")
  printf '%s' "$out" | python3 -c '
import json, sys
g = json.load(sys.stdin); a, b = g["batteries"]; bad = []
if g["ac"]: bad.append("ac should be off")
if (a["pct"], a["left"], a["health"], a["cycles"], a["watts"]) != (72, 13938, 95, 214, 10.6): bad.append("BAT0 %r" % a)
if (b["state"], b["full"], b["health"], b["watts"]) != ("charging", 7200, 80, 12.0): bad.append("BAT1 %r" % b)
if g["devices"] != [{"name": "Mouse", "pct": 41, "kind": "device"}]: bad.append("devices %r" % g["devices"])
if (g["profile"], g["profiles"]) != ("balanced", ["performance", "balanced", "power-saver"]): bad.append("profiles")
print("FAIL: tenka-lantern " + "; ".join(bad)) if bad else None
sys.exit(1 if bad else 0)' || fail=1
  [ "$(TENKA_POWER_ROOT="$P" PATH="$T/stub:$PATH" python3 "$BIN/tenka-lantern" word)" = "72%  ·  3 h 52 min" ] || { echo "FAIL: tenka-lantern word"; fail=1; }
  PATH="$T/stub:$PATH" python3 "$BIN/tenka-lantern" profile power-saver && [ "$(cat "$T/ppd/cur")" = power-saver ] || { echo "FAIL: tenka-lantern profile"; fail=1; }
  PATH="$T/stub:$PATH" python3 "$BIN/tenka-lantern" profile turbo 2>/dev/null && { echo "FAIL: tenka-lantern took a profile that does not exist"; fail=1; }
  [ "$(TENKA_POWER_ROOT="$T/none" python3 "$BIN/tenka-lantern" word)" = "On AC power" ] || { echo "FAIL: tenka-lantern without a battery"; fail=1; }
fi
# 7. The Inkstone's search order (inkstone/rank.js, pure JS): "tea" finds bubble tea, teapot and teacup before
#    "face with tears of joy" and "steaming bowl"; every word of the query must match. Needs node; skipped without.
if command -v node >/dev/null 2>&1; then
  node -e '
const fs = require("fs")
eval(fs.readFileSync(process.argv[1], "utf8").replace(".pragma library", ""))
const all = ["face with tears of joy", "steaming bowl", "teacup without handle", "bubble tea", "teapot", "Star of David", "star"]
  .map(n => ({ n: n }))
const got = q => rank(all, q).map(x => x.n)
const bad = []
const t = got("tea")
if (t[0] !== "bubble tea" || t.indexOf("teapot") > 2 || t.indexOf("teacup without handle") > 2) bad.push("tea: " + t.join(" | "))
if (t.indexOf("face with tears of joy") < 3 || t[t.length - 1] !== "steaming bowl") bad.push("tea tail: " + t.join(" | "))
if (got("david").join() !== "Star of David") bad.push("case: " + got("david"))
if (got("star")[0] !== "star") bad.push("whole name first: " + got("star"))
if (got("tea xyz").length !== 0 || got("tea joy").join() !== "face with tears of joy") bad.push("every word must match")
if (bad.length) { console.log("FAIL: inkstone rank: " + bad.join("; ")); process.exit(1) }
' "$ROOT/shell/quickshell/tenka/inkstone/rank.js" || fail=1
else
  echo "check-session: node not installed, Inkstone rank check skipped"
fi
# 8. tenka-loupe: the frozen screen is a private (0600) file; copy reaches the clipboard tool; LATELY keeps colours
#    only, lower-cased, newest first, without repeats
mkdir -p "$T/lstub" "$T/lhome"
printf '#!/bin/sh\ncat > "%s/clip"\n' "$T" > "$T/lstub/wl-copy"; chmod +x "$T/lstub/wl-copy"
echo picture > "$T/pic.png"
f=$(HOME="$T/lhome" XDG_CONFIG_HOME= XDG_RUNTIME_DIR="$T" TENKA_LOUPE_SIM_SHOT="$T/pic.png" sh "$BIN/tenka-loupe" shot)
[ "$f" = "$T/tenka-loupe.png" ] && [ "$(stat -c %a "$f")" = 600 ] || { echo "FAIL: tenka-loupe shot is not a private file ($f)"; fail=1; }
grep -q '^import "oldcolours.js" as Old$' "$ROOT/shell/quickshell/tenka/loupe/LoupeView.qml" &&
grep -q '^function nearest(theme, rgb)' "$ROOT/shell/quickshell/tenka/loupe/oldcolours.js" &&
[ "$(grep -c '"#[0-9a-f]\{6\}"\]' "$ROOT/shell/quickshell/tenka/loupe/oldcolours.js")" -ge 20 ] || { echo "FAIL: loupe old colour names"; fail=1; }
for c in '#C9A35A' '#112233' 'hello' '#c9a35a'; do
  HOME="$T/lhome" XDG_CONFIG_HOME= WAYLAND_DISPLAY=x PATH="$T/lstub:$PATH" sh "$BIN/tenka-loupe" copy "$c"
done
# on Tenka Lite (X11, no Wayland) the screen is frozen by xfce4-screenshooter, into the same private file
printf '#!/bin/sh\nwhile [ $# -gt 0 ]; do [ "$1" = -s ] && { echo x11 > "$2"; exit 0; }; shift; done\nexit 1\n' > "$T/lstub/xfce4-screenshooter"; chmod +x "$T/lstub/xfce4-screenshooter"
f=$(env -u WAYLAND_DISPLAY DISPLAY=:9 HOME="$T/lhome" XDG_RUNTIME_DIR="$T" PATH="$T/lstub:$PATH" sh "$BIN/tenka-loupe" shot)
[ "$f" = "$T/tenka-loupe.png" ] && [ "$(cat "$f")" = x11 ] && [ "$(stat -c %a "$f")" = 600 ] || { echo "FAIL: tenka-loupe shot on X11 ($f)"; fail=1; }
[ "$(cat "$T/clip")" = "#c9a35a" ] || { echo "FAIL: tenka-loupe copy did not reach the clipboard"; fail=1; }
[ "$(HOME="$T/lhome" XDG_CONFIG_HOME= sh "$BIN/tenka-loupe" lately)" = '["#c9a35a","#112233"]' ] || { echo "FAIL: tenka-loupe lately: $(HOME="$T/lhome" XDG_CONFIG_HOME= sh "$BIN/tenka-loupe" lately)"; fail=1; }
# 9. tenka-codex reads the keys from the live config: the shipped Hyprland and Lite keys both list Super + /,
#    and a key the user binds in ~/.config/hypr/user.lua shows up under "Yours"
mkdir -p "$T/chome/.config/hypr" "$T/chome/.config/xfce4/xfconf/xfce-perchannel-xml"
cp "$ROOT/live/config/includes.chroot/etc/skel/.config/hypr/hyprland.lua" "$T/chome/.config/hypr/"
cp "$ROOT/live/config/includes.chroot/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml" "$T/chome/.config/xfce4/xfconf/xfce-perchannel-xml/"
printf 'hl.bind("SUPER + SHIFT + M", hl.dsp.exec_cmd("mpv --player-operation-mode=pseudo-gui"))\n' > "$T/chome/.config/hypr/user.lua"
HOME="$T/chome" python3 "$BIN/tenka-codex" hyprland > "$T/codex-h.json" && HOME="$T/chome" python3 "$BIN/tenka-codex" lite > "$T/codex-l.json" &&
python3 - "$T/codex-h.json" "$T/codex-l.json" <<'EOF' || fail=1
import json, sys
h, l = (json.load(open(p)) for p in sys.argv[1:3])
def keys(d): return {(" + ".join(r["keys"]), g["name"]): r["what"] for g in d["groups"] for r in g["keys"]}
kh, kl, bad = keys(h), keys(l), []
if ("Super + /", "Tenka") not in kh: bad.append("hyprland has no Super + /")
if ("Super + /", "Tenka") not in kl: bad.append("lite has no Super + /")
if not any(k == "Super + Shift + M" and g == "Yours" for k, g in kh): bad.append("user.lua key missing from Yours")
if ("Super + 1 … 0", "Desks") not in kh: bad.append("workspace loop not folded")
if len(h["groups"]) < 6: bad.append("hyprland groups: %d" % len(h["groups"]))
if bad: print("FAIL: tenka-codex: " + "; ".join(bad)); sys.exit(1)
EOF
# 10. tenka-glance knows a folder, a text and a picture (its size from the file's own header), and reads no further
#     than it needs (a text's opening lines only)
mkdir -p "$T/glance/Letters"; seq 1 500 > "$T/glance/long.txt"
printf '\211PNG\r\n\032\n\000\000\000\rIHDR\000\000\003\000\000\000\002\000\010\006\000\000\000' > "$T/glance/seal.png"
XDG_RUNTIME_DIR="$T" python3 "$BIN/tenka-glance" --facts "$T/glance" "$T/glance/long.txt" "$T/glance/seal.png" > "$T/glance.json" &&
python3 - "$T/glance.json" <<'EOF' || fail=1
import json, sys
it, bad = json.load(open(sys.argv[1]))["items"], []
if [i["kind"] for i in it] != ["folder", "text", "image"]: bad.append("kinds: %s" % [i["kind"] for i in it])
if it[0]["count"] != 3 or it[0]["items"][0]["name"] != "Letters": bad.append("folder: %s" % it[0]["items"])
if len(it[1]["lines"].splitlines()) != 60: bad.append("text lines: %d" % len(it[1]["lines"].splitlines()))
if it[2]["extra"] != "768 × 512": bad.append("picture size: %r" % it[2]["extra"])
if bad: print("FAIL: tenka-glance: " + "; ".join(bad)); sys.exit(1)
EOF
# 11. tenka-colophon: the record is read from the system just now (the kernel row is this kernel, memory is
#     MemTotal), named after the active pack, and its text form starts with that name
mkdir -p "$T/colo/.config/tenka"; printf '{"display": "Tianxia", "tagline": "ALL UNDER HEAVEN", "crest": "/x.png"}' > "$T/colo/.config/tenka/shell-theme.json"
HOME="$T/colo" python3 "$BIN/tenka-colophon" lite > "$T/colo.json" && HOME="$T/colo" python3 "$BIN/tenka-colophon" text lite > "$T/colo.txt" &&
python3 - "$T/colo.json" "$T/colo.txt" <<'EOF' || fail=1
import json, os, sys
d, t, bad = json.load(open(sys.argv[1])), open(sys.argv[2]).read(), []
rows = {r[0]: r[1] for r in d["rows"]}
if d["name"] != "Tianxia" or d["crest"] != "/x.png": bad.append("theme: %s %s" % (d["name"], d["crest"]))
if rows.get("Kernel") != "Linux " + os.uname().release: bad.append("kernel: %r" % rows.get("Kernel"))
if not rows.get("Memory", "").endswith(" GB"): bad.append("memory: %r" % rows.get("Memory"))
if "Storage" not in rows or not 0 <= d["used"] <= 1: bad.append("storage: %r %r" % (rows.get("Storage"), d["used"]))
if not rows.get("Desk", "").startswith("Tenka Lite"): bad.append("desk: %r" % rows.get("Desk"))
if not t.startswith("Tianxia "): bad.append("text: %r" % t[:40])
if bad: print("FAIL: tenka-colophon: " + "; ".join(bad)); sys.exit(1)
EOF
grep -q '^Exec=tenka-colophon open$' "$ROOT/live/config/includes.chroot/usr/share/applications/tenka-colophon.desktop" || { echo "FAIL: colophon desktop entry"; fail=1; }
# 12. The Drift's wiring, both sessions
IC="$ROOT/live/config/includes.chroot"
grep -q 'ipc call drift open' "$IC/etc/skel/.config/hypr/hypridle.conf" && grep -q 'function open()' "$ROOT/shell/quickshell/tenka/Drift.qml" || { echo "FAIL: hypridle -> drift open"; fail=1; }
grep -q '^Exec=/usr/libexec/xfce4-screensaver/tenka-drift$' "$IC/usr/share/applications/screensavers/tenka-drift.desktop" && [ -x "$IC/usr/libexec/xfce4-screensaver/tenka-drift" ] &&
grep -q 'value="screensavers-tenka-drift"' "$IC/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-screensaver.xml" || { echo "FAIL: Lite screensaver -> tenka-drift"; fail=1; }
# 13. The Almanac: known dates
A=$(python3 "$BIN/tenka-almanac" line 2026-12-09; python3 "$BIN/tenka-almanac" line 2027-03-22; python3 "$BIN/tenka-almanac" line 2026-10-26)
echo "$A" | sed -n 1p | grep -q '^Major Snow  ·  .*  ·  New moon$' && echo "$A" | sed -n 2p | grep -q '^Spring Equinox  ·  Sparrows start to nest' &&
echo "$A" | sed -n 3p | grep -q "^Frost's Descent  ·  First frost  ·  Full moon$" || { echo "FAIL: tenka-almanac dates: $A"; fail=1; }
mkdir -p "$T/alm/.config/tenka"; echo '{ "name": "xianxia" }' > "$T/alm/.config/tenka/shell-theme.json"
HOME="$T/alm" python3 "$BIN/tenka-almanac" json 2026-10-12 | python3 -c 'import json,sys; a=json.load(sys.stdin); sys.exit(0 if a["term"]=="Cold Dew" and a["detail_kind"]=="saying" and a["title"]=="The Heavenly Calendar" else 1)' || { echo "FAIL: tenka-almanac theme words"; fail=1; }
python3 "$BIN/tenka-almanac" wheel 2026-10-12 | python3 -c '
import json, sys, datetime as d
a = json.load(sys.stdin); t = {x["name"]: d.datetime.utcfromtimestamp(x["start"]) for x in a["terms"]}
m = {x["name"]: d.datetime.utcfromtimestamp(x["at"]) for x in a["moons"][1:4]}
ok = t["Spring Equinox"].strftime("%m-%d") == "03-20" and t["Winter Solstice"].strftime("%m-%d") == "12-21" and m["Full moon"].strftime("%m-%d %H") == "10-26 04"
sys.exit(0 if ok else 1)' || { echo "FAIL: tenka-almanac wheel dates"; fail=1; }
grep -q '^ *Almanac {}' "$ROOT/shell/quickshell/tenka/shell.qml" && grep -q '^Exec=tenka-almanac open$' "$IC/usr/share/applications/tenka-almanac.desktop" &&
[ -f "$IC/usr/share/tenka/almanac/LiteAlmanac.qml" ] || { echo "FAIL: almanac card wiring"; fail=1; }
grep -q '"tenka-almanac", "json"' "$ROOT/shell/quickshell/tenka/DeskLedger.qml" && grep -q "tenka-almanac json" "$IC/usr/share/tenka/conky/desk.lua" || { echo "FAIL: almanac not on the desks"; fail=1; }
[ "$(grep -c '^ *AlmanacLine {' "$ROOT/shell/quickshell/tenka/LockFace.qml")" = 3 ] && grep -q '"tenka-almanac", "json"' "$ROOT/shell/quickshell/tenka/almanac/AlmanacLine.qml" || { echo "FAIL: almanac not on the lock"; fail=1; }
# 14. The Incense: light, read, put out; wiring
mkdir -p "$T/inc/rt"; chmod 700 "$T/inc/rt"
HOME="$T/inc" XDG_RUNTIME_DIR="$T/inc/rt" python3 "$BIN/tenka-incense" light 2
S1=$(HOME="$T/inc" XDG_RUNTIME_DIR="$T/inc/rt" python3 "$BIN/tenka-incense" state)
SP=$(cat "$T/inc/rt/tenka-incense.pid" 2>/dev/null)
HOME="$T/inc" XDG_RUNTIME_DIR="$T/inc/rt" python3 "$BIN/tenka-incense" out; sleep 0.3
S2=$(HOME="$T/inc" XDG_RUNTIME_DIR="$T/inc/rt" python3 "$BIN/tenka-incense" state)
echo "$S1" | python3 -c 'import json,sys; s=json.load(sys.stdin); sys.exit(0 if s["burning"] and 110<=s["left"]<=120 and s["minutes"]==2 else 1)' &&
echo "$S2" | python3 -c 'import json,sys; s=json.load(sys.stdin); sys.exit(0 if not s["burning"] and s["minutes"]==2 else 1)' &&
[ -n "$SP" ] && ! kill -0 "$SP" 2>/dev/null || { echo "FAIL: tenka-incense light/out: $S1 / $S2"; fail=1; }
HOME="$T/inc" XDG_RUNTIME_DIR="$T/inc/rt" python3 "$BIN/tenka-incense" garden pines &&
HOME="$T/inc" XDG_RUNTIME_DIR="$T/inc/rt" python3 "$BIN/tenka-incense" state | grep -q '"garden": "pines"' &&
! HOME="$T/inc" XDG_RUNTIME_DIR="$T/inc/rt" python3 "$BIN/tenka-incense" garden thunder 2>/dev/null || { echo "FAIL: tenka-incense garden"; fail=1; }
grep -q '^import Quickshell.Hyprland$' "$ROOT/shell/quickshell/tenka/Incense.qml" && grep -q '"tenka:incense"' "$IC/etc/skel/.config/hypr/hyprland.lua" &&
grep -q 'value="tenka-incense open"' "$IC/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml" &&
[ -f "$IC/usr/share/tenka/incense/LiteIncense.qml" ] && grep -q '^ *Incense {}' "$ROOT/shell/quickshell/tenka/shell.qml" || { echo "FAIL: incense wiring"; fail=1; }
# 15. The Garden
for n in rain stream pines embers; do f="$IC/usr/share/sounds/tenka-ambience/$n.ogg"
  [ -s "$f" ] && head -c 64 "$f" | grep -q vorbis || { echo "FAIL: ambience bed $n"; fail=1; }; done
mkdir -p "$T/amb/rt"; chmod 700 "$T/amb/rt"
G=$(HOME="$T/amb" XDG_RUNTIME_DIR="$T/amb/rt" python3 "$BIN/tenka-ambience" state)
echo "$G" | python3 -c 'import json,sys; s=json.load(sys.stdin); sys.exit(0 if s["names"]==["rain","stream","pines","embers"] and not s["playing"] else 1)' &&
! HOME="$T/amb" XDG_RUNTIME_DIR="$T/amb/rt" python3 "$BIN/tenka-ambience" play nope 2>/dev/null || { echo "FAIL: tenka-ambience state/refusal: $G"; fail=1; }
grep -q '^import Quickshell.Hyprland$' "$ROOT/shell/quickshell/tenka/Garden.qml" && grep -q '"tenka:garden"' "$IC/etc/skel/.config/hypr/hyprland.lua" &&
grep -q 'value="tenka-ambience open"' "$IC/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml" &&
[ -f "$IC/usr/share/tenka/garden/LiteGarden.qml" ] && grep -q '^ *Garden {}' "$ROOT/shell/quickshell/tenka/shell.qml" &&
grep -q '^Exec=tenka-ambience open$' "$IC/usr/share/applications/tenka-ambience.desktop" || { echo "FAIL: garden wiring"; fail=1; }
# 16. The Pillow Book: pages are plain files, an empty page is removed, the season comes from the almanac; wiring
J="$T/jr"; mkdir -p "$J/.config/tenka"
HOME="$J" TENKA_TODAY=2026-10-12 TENKA_ALMANAC="$BIN/tenka-almanac" python3 "$BIN/tenka-journal" write "First frost." &&
HOME="$J" TENKA_TODAY=2026-10-12 TENKA_ALMANAC="$BIN/tenka-almanac" python3 "$BIN/tenka-journal" write "Tea." &&
HOME="$J" TENKA_TODAY=2025-10-12 python3 "$BIN/tenka-journal" put "Maple." &&
HOME="$J" TENKA_TODAY=2026-10-09 python3 "$BIN/tenka-journal" put "Rain." &&
HOME="$J" TENKA_TODAY=2026-10-10 python3 "$BIN/tenka-journal" put "x" && HOME="$J" TENKA_TODAY=2026-10-10 python3 "$BIN/tenka-journal" put "" &&
HOME="$J" TENKA_TODAY=2026-10-12 TENKA_ALMANAC="$BIN/tenka-almanac" python3 "$BIN/tenka-journal" state | python3 -c '
import json, sys; s = json.load(sys.stdin)
ok = s["text"] == "First frost.\nTea." and s["season"].startswith("Cold Dew") and s["count"] == 3 and s["ago"]["text"] == "Maple." \
     and [e["date"] for e in s["entries"]] == ["2026-10-09", "2025-10-12"] and s["title"] == "The Pillow Book"
sys.exit(0 if ok else 1)' && [ "$(stat -c %a "$J/.local/share/tenka/journal/2026-10-09.txt")" = 600 ] || { echo "FAIL: tenka-journal pages"; fail=1; }
grep -q '^import Quickshell.Hyprland$' "$ROOT/shell/quickshell/tenka/Journal.qml" && grep -q '"tenka:journal"' "$IC/etc/skel/.config/hypr/hyprland.lua" &&
grep -q 'value="tenka-journal open"' "$IC/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml" &&
[ -f "$IC/usr/share/tenka/journal/LiteJournal.qml" ] && grep -q '^ *Journal {}' "$ROOT/shell/quickshell/tenka/shell.qml" &&
grep -q '^Exec=tenka-journal open$' "$IC/usr/share/applications/tenka-journal.desktop" &&
grep -q '"tenka-journal", "today"' "$ROOT/shell/quickshell/tenka/DeskLedger.qml" &&
grep -q "/tenka/journal'" "$IC/usr/share/tenka/conky/desk.lua" || { echo "FAIL: journal wiring"; fail=1; }
# 17. The Watch: names, the next bell, quiet hours, focus and the rests
W="$T/wt"; mkdir -p "$W/.config/tenka" "$W/rt"
wt() { HOME="$W" XDG_RUNTIME_DIR="$W/rt" TENKA_WATCH_DRY=1 python3 "$BIN/tenka-watch" "$@"; }
[ "$(wt hours | head -1)" = "23:00  Hour of the Rat" ] && [ "$(wt hours | sed -n 7p)" = "11:00  Hour of the Horse" ] &&
TENKA_NOW=2026-10-12T10:20 wt state | grep -q '"next": "Hour of the Horse", "next_at": "11:00"' &&
TENKA_NOW=2026-10-12T21:30 wt state | grep -q '"next_at": "07:00"' &&
TENKA_NOW=2026-10-12T11:00 wt ring | grep -q 'resting' && wt quiet 22 7 && echo '{"on": true, "quiet": [22, 7]}' > "$W/.config/tenka/watch.json" &&
TENKA_NOW=2026-10-12T11:00 wt ring | grep -q 'Hour of the Horse' && TENKA_NOW=2026-10-12T23:00 wt ring | grep -q 'quiet hours' &&
echo '{ "on": true, "until": 0, "since": 1 }' > "$W/.config/tenka/focus.json" && TENKA_NOW=2026-10-12T11:00 wt ring | grep -q 'focus' &&
rm "$W/.config/tenka/focus.json" && touch "$W/rt/tenka-still" && TENKA_NOW=2026-10-12T11:00 wt ring | grep -q 'stillness' &&
TENKA_NOW=2026-10-12T11:00 wt ring --force | grep -q 'Hour of the Horse' || { echo "FAIL: tenka-watch"; fail=1; }
for t in samurai xianxia; do f="$IC/usr/share/sounds/tenka-watch/$t.ogg"; [ -s "$f" ] && head -c 64 "$f" | grep -q vorbis || { echo "FAIL: watch bell $t"; fail=1; }; done
grep -q 'OnCalendar=\*-\*-\* 01,03,05,07,09,11,13,15,17,19,21,23:00:00' "$IC/usr/lib/systemd/user/tenka-watch.timer" &&
grep -q 'enable tenka-watch.timer' "$ROOT/live/config/hooks/live/0100-base-setup.hook.chroot" &&
grep -q '"tenka-watch", "state"' "$ROOT/shell/quickshell/tenka/ControlCenter.qml" || { echo "FAIL: watch wiring"; fail=1; }
# 18. The sun over your place: sunrise and sunset from the time zone's city (or place.json), and the phase it gives
al() { HOME="$T/sun" TZ=Asia/Kolkata python3 "$BIN/tenka-almanac" "$@"; }
mkdir -p "$T/sun"
[ "$(al sun 2026-10-12)" = "Sunrise 05:32  ·  Sunset 17:15  ·  11h 43m of light over Kolkata" ] &&
[ "$(al phase 2026-10-12T04:30)" = night ] && [ "$(al phase 2026-10-12T05:20)" = dawn ] && [ "$(al phase 2026-10-12T12:00)" = day ] &&
[ "$(al phase 2026-10-12T17:30)" = dusk ] && [ "$(al phase 2026-10-12T19:00)" = night ] &&
[ "$(al season 2026-10-12)" = maple ] && [ "$(HOME="$T/sun" TZ=Australia/Sydney python3 "$BIN/tenka-almanac" season 2026-10-12)" = plum ] &&
[ "$(HOME="$T/sun" TZ=America/Sao_Paulo python3 "$BIN/tenka-almanac" season 2026-07-01)" = snow ] && grep -q 'tenka-almanac season' "$BIN/tenka-hour" &&
[ "$(HOME="$T/sun" TZ=Arctic/Longyearbyen python3 "$BIN/tenka-almanac" phase 2026-06-21T00:30)" = day ] &&
[ "$(HOME="$T/sun" TZ=Arctic/Longyearbyen python3 "$BIN/tenka-almanac" phase 2026-12-21T12:00)" = night ] &&
mkdir -p "$T/sun/.config/tenka" && echo '{ "name": "London", "lat": 51.5, "lon": -0.13 }' > "$T/sun/.config/tenka/place.json" &&
HOME="$T/sun" TZ=Europe/London python3 "$BIN/tenka-almanac" sun 2026-10-12 | grep -q '^Sunrise 07:[12][0-9]  ·  Sunset 18:[01][0-9]  ·  .* over London$' &&
grep -q 'tenka-almanac phase' "$BIN/tenka-hour" && grep -q 'card.d.sun' "$ROOT/shell/quickshell/tenka/almanac/AlmanacCard.qml" &&
grep -q 'dl.almanac.sun' "$ROOT/shell/quickshell/tenka/DeskLedger.qml" && grep -q "SUNRISE ' .. a.rise" "$IC/usr/share/tenka/conky/desk.lua" || { echo "FAIL: the sun"; fail=1; }
# 19. Night ink with the sun: warm through the night, a slow fade over each twilight, the right command per session
N="$T/ink"; mkdir -p "$N"
ni() { HOME="$N" XDG_RUNTIME_DIR="$N" TZ=Asia/Kolkata TENKA_ALMANAC="$BIN/tenka-almanac" TENKA_NIGHTINK_DRY=1 python3 "$BIN/tenka-nightink" "$@"; }
k() { TENKA_NOW="$1" ni state | python3 -c 'import json,sys; print(json.load(sys.stdin)["kelvin"])'; }
[ "$(k 2026-10-12T12:00)" = 6500 ] && ni sun >/dev/null && [ "$(k 2026-10-12T12:00)" = 6500 ] && [ "$(k 2026-10-12T23:00)" = 4200 ] &&
[ "$(k 2026-10-12T02:00)" = 4200 ] && a=$(k 2026-10-12T17:15) && [ "$a" -gt 4200 ] && [ "$a" -lt 6500 ] &&
b=$(k 2026-10-12T17:40) && [ "$b" -lt "$a" ] && c=$(k 2026-10-12T05:45) && [ "$c" -gt "$(k 2026-10-12T05:20)" ] &&
TENKA_NOW=2026-10-12T23:00 HYPRLAND_INSTANCE_SIGNATURE=x ni tick | grep -q '^RUN hyprctl hyprsunset temperature 4200$' &&
TENKA_NOW=2026-10-12T23:00 DISPLAY=:9 ni tick | grep -q '^XRR gamma 1.0:0.8[0-9]*:0.6[0-9]*$' &&
ni cycle | grep -q '"mode": "on"' && ni cycle | grep -q '"mode": "off"' && TENKA_NOW=2026-10-12T23:00 ni state | grep -q '"kelvin": 6500' &&
grep -q '^tenka-nightink run' "$BIN/tenka-session" && grep -q 'setsid tenka-nightink run' "$BIN/tenka-lite-apply" &&
grep -q '"tenka-nightink", "state"' "$ROOT/shell/quickshell/tenka/ControlCenter.qml" && ! grep -q 'hyprsunset -t 4200' "$ROOT/shell/quickshell/tenka/ControlCenter.qml" &&
grep -q '^Exec=tenka-nightink toggle --say$' "$IC/usr/share/applications/tenka-nightink.desktop" &&
grep -q '"SUPER + SHIFT + N"\|" + SHIFT + N",   hl.dsp.exec_cmd("tenka-nightink cycle --say")' "$IC/etc/skel/.config/hypr/hyprland.lua" &&
grep -q 'value="tenka-nightink cycle --say"' "$IC/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml" || { echo "FAIL: night ink"; fail=1; }
# 20. The Breath: a pace and a length kept, a sitting counted (and today's count resets on a new day), wired in both sessions
B2="$T/breath"; mkdir -p "$B2"
tb() { HOME="$B2" XDG_RUNTIME_DIR="$B2" TENKA_BREATH_QUIET=1 python3 "$BIN/tenka-breath" "$@"; }
tb state | grep -q '"pace": "even", "minutes": 3' && tb set calm 5 && tb done 5 && tb state | grep -q '"pace": "calm", "minutes": 5, .*"sittings": 1' &&
! tb set calm 7 2>/dev/null && ! tb set fast 3 2>/dev/null && TENKA_TODAY=2099-01-01 tb state | grep -q '"sittings": 0, "total": 1' &&
grep -q '^import Quickshell.Hyprland$' "$ROOT/shell/quickshell/tenka/Breath.qml" && grep -q '^ *Breath {}' "$ROOT/shell/quickshell/tenka/shell.qml" &&
grep -q '"tenka:breath"' "$IC/etc/skel/.config/hypr/hyprland.lua" && [ -f "$IC/usr/share/tenka/breath/LiteBreath.qml" ] &&
grep -q 'value="tenka-breath open"' "$IC/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml" &&
grep -q 'tenka:breath' "$IC/usr/bin/tenka-codex" && grep -q '^Exec=tenka-breath open$' "$IC/usr/share/applications/tenka-breath.desktop" || { echo "FAIL: the breath"; fail=1; }
# 21. The Pause: off until asked, a note after the stretch, away time (X11 idle or hypridle) starts it again, Focus holds it
P2="$T/pause"; mkdir -p "$P2/.config/tenka"
tp() { HOME="$P2" XDG_RUNTIME_DIR="$P2" TENKA_PAUSE_DRY=1 TENKA_IDLE_MS="${IDLE:-0}" python3 "$BIN/tenka-breath" "$@"; }
tp pause | grep -q '"on": false, "every": 50' && TENKA_NOW=1000 tp pause on >/dev/null && [ -z "$(TENKA_NOW=3900 tp tick)" ] &&
TENKA_NOW=4100 tp tick | grep -q '^NOTE A pause | 50 minutes at the desk' && [ -z "$(TENKA_NOW=5000 tp tick)" ] &&
TENKA_NOW=7000 IDLE=200000 tp tick && [ -z "$(TENKA_NOW=9900 tp tick)" ] &&
TENKA_NOW=10000 tp away && TENKA_NOW=13100 tp back && [ -z "$(TENKA_NOW=15000 tp tick)" ] &&
echo '{"on": true}' > "$P2/.config/tenka/focus.json" && [ -z "$(TENKA_NOW=17000 tp tick)" ] && rm "$P2/.config/tenka/focus.json" &&
tp pause every 25 | grep -q '"every": 25' && ! tp pause every 5 2>/dev/null &&
# the stretch steps 25 -> 30 -> ... -> 120 -> 30 (the Control Center's dotted value, Lite's menu action)
tp pause every next | grep -q '"every": 30' && tp pause every 120 >/dev/null && tp pause every next | grep -q '"every": 30' &&
grep -q '"pause", "every", "next"' "$ROOT/shell/quickshell/tenka/ControlCenter.qml" && grep -q 'pause every next' "$ROOT/live/config/includes.chroot/usr/share/applications/tenka-breath.desktop" &&
grep -q 'on-timeout = tenka-breath away' "$IC/etc/skel/.config/hypr/hypridle.conf" && grep -q 'on-resume = tenka-breath back' "$IC/etc/skel/.config/hypr/hypridle.conf" &&
grep -q '^tenka-breath run' "$BIN/tenka-session" && grep -q 'setsid tenka-breath run' "$BIN/tenka-lite-apply" &&
grep -q '"tenka-breath", "pause"' "$ROOT/shell/quickshell/tenka/ControlCenter.qml" && grep -q 'id: lfl' "$ROOT/shell/quickshell/tenka/ControlCenter.qml" || { echo "FAIL: the pause"; fail=1; }
# 22. The Sky: the weather in the desk's words, by season and hemisphere; rain and snow take over the desk's fall
SK="$T/sky"; mkdir -p "$SK"
sk() { HOME="$SK" TZ="${Z:-Asia/Kolkata}" TENKA_ALMANAC="$BIN/tenka-almanac" python3 "$BIN/tenka-sky" "$@"; }
[ "$(TENKA_SKY_FIXTURE=61,24 sk line)" = "Kolkata  24°  ·  Autumn rain" ] && [ "$(TENKA_SKY_FIXTURE=53,20 sk line)" = "Kolkata  20°  ·  Fine autumn rain" ] &&
[ "$(TENKA_SKY_FIXTURE=0,12,0 sk line)" = "Kolkata  12°  ·  A clear night" ] && [ "$(TENKA_SKY_FIXTURE=45,9 sk line)" = "Kolkata  9°  ·  Mist on the hills" ] &&
[ "$(Z=Australia/Sydney TENKA_SKY_FIXTURE=63,18 sk line)" = "Sydney  18°  ·  Spring rain" ] && TENKA_SKY_FIXTURE=95,30 sk | grep -q '"kind": "storm"' &&
sk off && sk | grep -q '"off": true' && [ ! -e "$SK/.cache/tenka/sky.json" ] && sk on && grep -q 'latitude=%.1f&longitude=%.1f' "$BIN/tenka-sky" &&
grep -q '"tenka-sky"' "$ROOT/shell/quickshell/tenka/Theme.qml" && grep -q 'Theme.sky.kind === "rain"' "$ROOT/shell/quickshell/tenka/Desk.qml" &&
grep -q 'kind: "rain"' "$ROOT/shell/quickshell/tenka/Desk.qml" && [ -f "$ROOT/shell/quickshell/tenka/assets/rain.png" ] && grep -q 'Theme.sky.word' "$ROOT/shell/quickshell/tenka/DeskLedger.qml" &&
[ "$(grep -c 'sky: Theme.sky.word' "$ROOT/shell/quickshell/tenka/LockFace.qml")" = 3 ] && grep -q 'line.sky' "$ROOT/shell/quickshell/tenka/almanac/AlmanacLine.qml" || { echo "FAIL: the sky"; fail=1; }
# 23. Under Heaven (Tianxia: The Four Seas): the hour in the places you keep, offsets and sun worked out here
CK="$T/clocks"; mkdir -p "$CK/.config/tenka"
ck() { HOME="$CK" TZ="${Z:-Asia/Kolkata}" TENKA_NOW=1791814200 TENKA_ALMANAC="$BIN/tenka-almanac" python3 "$BIN/tenka-clocks" "$@"; }
ck text | grep -q '^Tokyo  *23:10  +3:30  *sunrise 05:45  sunset 17:12' && ck text | grep -q '^New York  *10:10  .9:30' &&
ck add Sydney | grep -q '"zone": "Australia/Sydney"' && ck text | grep -q '^Sydney  *01:10  +5:30  *sunrise 06:1[6-9]  sunset 19:0[6-9]' &&
ck remove London >/dev/null && ! ck text | grep -q London && ! ck add Nowhereville 2>/dev/null &&
echo '{"name": "xianxia"}' > "$CK/.config/tenka/shell-theme.json" && rm "$CK/.config/tenka/clocks.json" && ck | grep -q '"title": "The Four Seas"' && ck | grep -q 'Asia/Shanghai' &&
Z=Asia/Tokyo ck | grep -q '"here": {"zone": "Asia/Tokyo"' && ! grep -q 'urllib\|http' "$BIN/tenka-clocks" &&
grep -q '^ *Clocks {}' "$ROOT/shell/quickshell/tenka/shell.qml" && [ -f "$ROOT/shell/quickshell/tenka/clocks/ClocksCard.qml" ] &&
grep -q '"tenka:clocks"' "$IC/etc/skel/.config/hypr/hyprland.lua" && [ -f "$IC/usr/share/tenka/clocks/LiteClocks.qml" ] &&
grep -q 'value="tenka-clocks open"' "$IC/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml" &&
grep -q 'tenka:clocks' "$IC/usr/bin/tenka-codex" && grep -q 'Theme.ipc("clocks", "open")' "$ROOT/shell/quickshell/tenka/ControlCenter.qml" && grep -q '^Exec=tenka-clocks open$' "$IC/usr/share/applications/tenka-clocks.desktop" || { echo "FAIL: under heaven"; fail=1; }
# 24. Moon Viewing (Tianxia: The Moon Palace): the phase, the old lunar night, moonrise and moonset, all worked out here
MO="$T/moon"; mkdir -p "$MO/.config/tenka"
mo() { HOME="$MO" TZ="${Z:-Asia/Kolkata}" TENKA_ALMANAC="$BIN/tenka-almanac" python3 "$BIN/tenka-moon" "$@"; }
mo 2026-02-17 | grep -q '"month": 1, "leap": false, "day": 1,' && mo 2025-10-06 text | grep -q '^The mid-autumn moon, the 15th night' &&
mo 2025-08-01 | grep -q '"month_name": "Leap Month of Water"' && mo 2023-03-25 | grep -q '"month": 2, "leap": true' &&
mo 2026-10-12T08:00 text | grep -q '^Next full moon: Mon 26 Oct 09:4[0-4]' && mo 2026-10-12T08:00 text | grep -q '^The crescent of the third night of the Long Month' &&
Z=Australia/Sydney mo 2026-10-12 | grep -q '"south": true' && ! grep -q 'urllib\|http' "$BIN/tenka-moon" &&
echo '{"name": "xianxia"}' > "$MO/.config/tenka/shell-theme.json" && mo 2026-10-12 | grep -q '"title": "The Moon Palace".*"month_name": "Chrysanthemum Month"' &&
grep -q '^ *Moon {}' "$ROOT/shell/quickshell/tenka/shell.qml" && [ -f "$ROOT/shell/quickshell/tenka/moon/MoonCard.qml" ] &&
grep -q '"tenka:moon"' "$IC/etc/skel/.config/hypr/hyprland.lua" && [ -f "$IC/usr/share/tenka/moon/LiteMoon.qml" ] &&
grep -q 'value="tenka-moon open"' "$IC/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml" &&
grep -q 'tenka:moon' "$IC/usr/bin/tenka-codex" && grep -q '^Exec=tenka-moon open$' "$IC/usr/share/applications/tenka-moon.desktop" || { echo "FAIL: moon viewing"; fail=1; }
# 25. Seven Skies (Tianxia: The Heavens Ahead): the week's sky from the same request, in the desk's words, off with the sky
SW="$T/skyweek"; mkdir -p "$SW"
sw() { HOME="$SW" TZ=Asia/Kolkata TENKA_ALMANAC="$BIN/tenka-almanac" TENKA_SKY_FIXTURE=61,24 TENKA_SKY_DAYS="61:30:24:80,0:33:25:0,95:31:24:60,45:28:22:10" python3 "$BIN/tenka-sky" "$@"; }
sw week | grep -q '"title": "Seven Skies"' && [ "$(sw week | grep -o '"word": "[^"]*"' | tr '\n' '|')" = '"word": "Autumn rain"|"word": "Autumn rain"|"word": "A clear sky"|"word": "Thunder in the hills"|"word": "Mist on the hills"|' ] &&
sw week | grep -q '"hi": 33, "lo": 25, "rain": 0' && grep -q '&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max' "$BIN/tenka-sky" &&
sw off && sw week | grep -q '"off": true' && sw on && grep -q 'card.s.off' "$ROOT/shell/quickshell/tenka/skyweek/SkyWeekCard.qml" &&
grep -q '^ *SkyWeek {}' "$ROOT/shell/quickshell/tenka/shell.qml" && grep -q '"tenka:skyweek"' "$IC/etc/skel/.config/hypr/hyprland.lua" &&
[ -f "$IC/usr/share/tenka/skyweek/LiteSkyWeek.qml" ] && grep -q 'value="tenka-sky open"' "$IC/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml" &&
grep -q 'tenka:skyweek' "$IC/usr/bin/tenka-codex" && grep -q 'Theme.ipc("skyweek", "open")' "$ROOT/shell/quickshell/tenka/ControlCenter.qml" &&
grep -q 'Theme.ipc("skyweek", "open")' "$ROOT/shell/quickshell/tenka/DeskLedger.qml" && grep -q 'Theme.ipc("moon", "open")' "$ROOT/shell/quickshell/tenka/ControlCenter.qml" && grep -q '^Exec=tenka-sky open$' "$IC/usr/share/applications/tenka-skyweek.desktop" || { echo "FAIL: seven skies"; fail=1; }
# 26. The moon on the desk: tenka-moon says where it stands (altitude, azimuth, the tilt of its lit limb) and the desk
#     draws it there on clear nights. Over Kolkata on 24 Oct 2026 22:00 the near-full moon rides high in the south with
#     its lit side to the right; the evening crescent of 13 Oct lies low in the west-southwest lit from below-right.
DM=$(HOME="$MO" TZ=Asia/Kolkata TENKA_PLACE=22.57,88.36,Kolkata TENKA_ALMANAC="$BIN/tenka-almanac" python3 -c '
import json, subprocess, sys
r = lambda w: json.loads(subprocess.run([sys.executable, sys.argv[1], w], capture_output=True, text=True).stdout)
a, b = r("2026-10-24T22:00"), r("2026-10-13T18:40")
print(int(a["alt"] > 70 and 165 < a["az"] < 195 and 235 < a["tilt"] < 280 and a["up"] and
          0 < b["alt"] < 5 and 235 < b["az"] < 255 and 200 < b["tilt"] < 250))' "$BIN/tenka-moon")
[ "$DM" = 1 ] && grep -q 'id: deskMoon' "$ROOT/shell/quickshell/tenka/Desk.qml" &&
grep -q 'command: \["tenka-moon", "state"\]' "$ROOT/shell/quickshell/tenka/Desk.qml" || { echo "FAIL: desk moon ($DM)"; fail=1; }
[ "$fail" = 0 ] && echo "check-session: ok"
exit $fail
