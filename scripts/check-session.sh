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
for c in '#C9A35A' '#112233' 'hello' '#c9a35a'; do
  HOME="$T/lhome" XDG_CONFIG_HOME= WAYLAND_DISPLAY=x PATH="$T/lstub:$PATH" sh "$BIN/tenka-loupe" copy "$c"
done
[ "$(cat "$T/clip")" = "#c9a35a" ] || { echo "FAIL: tenka-loupe copy did not reach the clipboard"; fail=1; }
[ "$(HOME="$T/lhome" XDG_CONFIG_HOME= sh "$BIN/tenka-loupe" lately)" = '["#c9a35a","#112233"]' ] || { echo "FAIL: tenka-loupe lately: $(HOME="$T/lhome" XDG_CONFIG_HOME= sh "$BIN/tenka-loupe" lately)"; fail=1; }
[ "$fail" = 0 ] && echo "check-session: ok"
exit $fail
