# Generic Wayland compositor helpers (wl-screenrec, wlr-which-key).
# These work under any Wayland WM/compositor (niri, sway, Hyprland, etc.)
# Usage:
#   wl = vlib.wayland { inherit pkgs lib; };
#   wl.mkRecordCmd "-o DP-1"
#   wl.mkMenu [ { key = "q"; desc = "..."; cmd = "..."; } ]   # returns exec path string
{
  pkgs,
  lib,
}: let
  notify = "${pkgs.libnotify}/bin/notify-send";
in {
  # Shell snippet running wl-screenrec with extra flags (e.g. "-o DP-1"), spliced unquoted so they may use $(...); an empty one (a cancelled picker) exits without recording.
  mkRecordCmd = grimArgs: ''
    set -- ${grimArgs}
    for arg; do [ -n "$arg" ] || exit 0; done
    DIR="$HOME/Videos/Recordings"
    FILE="$DIR/recording-$(date +%Y%m%d-%H%M%S).mp4"
    mkdir -p "$DIR"
    ${notify} -u low -t 3000 "Recording started" "Press Mod+Shift+R → q to stop" &
    if ${lib.getExe pkgs.wl-screenrec} "$@" -f "$FILE"; then
      ${notify} "Recording saved" "$FILE"
    else
      ${notify} -u critical "Recording failed" "wl-screenrec exited with status $?"
    fi
  '';

  # Build a wlr-which-key popup menu from a list of
  # { key, desc, cmd } attribute sets.
  # Returns the executable path string directly (no lib.getExe needed at call sites).
  mkMenu = menu: let
    configFile =
      pkgs.writeText "config.yaml"
      (lib.generators.toYAML {} {
        anchor = "bottom-right";
        inherit menu;
      });
  in
    lib.getExe (pkgs.writeShellScriptBin "wm-menu" ''
      exec ${lib.getExe pkgs.wlr-which-key} ${configFile}
    '');
}
