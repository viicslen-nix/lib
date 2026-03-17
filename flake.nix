{
  description = "Shared Nix helper library";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    systems,
    ...
  }: {
    # mkLib: call with { inputs, outputs } from your consuming flake.
    # Returns nixpkgs.lib merged with all custom helpers (same shape as the
    # main nixos repo's lib/default.nix).
    # Inject this flake's own systems into the consumer's inputs so the
    # root flake doesn't need to declare a systems input of its own.
    mkLib = {inputs, outputs}: import ./default.nix {
      inherit outputs;
      inputs = inputs // {systems = self.inputs.systems;};
    };

    # Pure helpers that only need nixpkgs.lib (no flake outputs required).
    lib = {
      modules = import ./modules.nix {lib = nixpkgs.lib;};
      umport = (import ./umport.nix {lib = nixpkgs.lib;}).umport;
    };

    # Desktop helpers factory – call with { pkgs, lib } to get a set of
    # compositor-specific mk-functions.
    # Example:
    #   niriLib = inputs.viicslen-lib.mkDesktopLib { inherit pkgs lib; };
    #   niriLib.niri.mkRecordCmd ""
    mkDesktopLib = {pkgs, lib}: {
      niri = import ./desktop/niri.nix {inherit pkgs lib;};
    };
  };
}
