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
  # Wrap a wl-screenrec invocation with start/stop notifications.
  # grimArgs: extra CLI flags forwarded to wl-screenrec (e.g. "-o DP-1",
  #           "-g \"100,100 800x600\"", or "" for all monitors).
  mkRecordCmd = grimArgs: let
    recordingFile = "$HOME/Videos/Recordings/recording-$(date +%Y%m%d-%H%M%S).mp4";
  in ''
    FILE="${recordingFile}"; \
    ${notify} -u low -t 3000 "Recording started" "Press Mod+Shift+R → q to stop"; \
    ${lib.getExe pkgs.wl-screenrec} ${grimArgs} -f "$FILE"; \
    ${notify} "Recording saved" "$FILE"'';

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
