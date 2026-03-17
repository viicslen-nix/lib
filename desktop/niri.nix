# Niri-specific mk helper functions.
# Usage:
#   niriLib = inputs.nixpkgs-lib.mkDesktopLib { inherit pkgs lib; };
#   niriLib.niri.mkRecordCmd "-o myoutput"
#   niriLib.niri.mkMenu [ { key = "q"; desc = "..."; cmd = "..."; } ]
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
  mkMenu = menu: let
    configFile =
      pkgs.writeText "config.yaml"
      (lib.generators.toYAML {} {
        anchor = "bottom-right";
        inherit menu;
      });
  in
    pkgs.writeShellScriptBin "niri-menu" ''
      exec ${lib.getExe pkgs.wlr-which-key} ${configFile}
    '';
}
