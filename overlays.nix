# Overlay constructors. Each returns an overlay (`final: prev: {…}`), so the
# consuming repo supplies its own inputs and names them where they are used.
{lib}: {
  # Alias `pkgs.inputs.<flake>` to that input's package set for the current
  # system, preferring `legacyPackages` over `packages`.
  mkFlakeInputsOverlay = inputs: final: _: {
    inputs =
      builtins.mapAttrs (
        _: flake: let
          system = final.stdenv.hostPlatform.system;
          legacyPackages = (flake.legacyPackages or {}).${system} or {};
          packages = (flake.packages or {}).${system} or {};
        in
          if legacyPackages != {}
          then legacyPackages
          else packages
      )
      inputs;
  };

  # Expose a second nixpkgs channel at `pkgs.<attr>` — the idiom behind
  # `pkgs.unstable` / `pkgs.stable`. `config` is the nixpkgs config for that
  # channel alone; it does not inherit the host's.
  mkChannelOverlay = {
    attr,
    flake,
    config ? {allowUnfree = true;},
  }: final: _: {
    ${attr} = import flake {
      system = final.stdenv.hostPlatform.system;
      inherit config;
    };
  };
}
