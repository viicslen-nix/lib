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
  }: let
    lib = nixpkgs.lib;
    defaultSystems = import systems;
    mkPkgs = system: import nixpkgs {inherit system; config.allowUnfree = true;};
  in {
    # mkLib: only needed for host building.
    # mkNixosConfigurations passes the consumer's inputs/outputs as specialArgs
    # into every NixOS host config, so those cannot be pre-baked here.
    mkLib = {inputs, outputs}: import ./hosts.nix {inherit inputs outputs;};

    # All helpers that only depend on this flake's own nixpkgs + systems.
    # Because viicslen-lib.inputs.nixpkgs follows the consumer's nixpkgs,
    # these functions act on the consumer's nixpkgs version at zero extra cost.
    lib = lib // {
      inherit defaultSystems;
      genSystems = lib.genAttrs defaultSystems;

      pkgsFor = mkPkgs;
      pkgFromSystem = pkg: lib.genAttrs defaultSystems (system: (mkPkgs system).${pkg});
      callPackageForSystem = system: path: overrides:
        (mkPkgs system).callPackage path overrides;

      modules    = import ./modules.nix {inherit lib;};
      umport     = (import ./umport.nix {inherit lib;}).umport;
      persistence = import ./persistence.nix {inputs = {nixpkgs = nixpkgs;};};

      # Wayland compositor helpers – apply { pkgs, lib } once to get the helpers.
      # Works under any Wayland WM (niri, sway, Hyprland, …).
      # Example: wl = vlib.wayland { inherit pkgs lib; };
      #          wl.mkRecordCmd ""  wl.mkMenu [ ... ]
      wayland = {pkgs, lib}: import ./desktop/wayland.nix {inherit pkgs lib;};
    };
  };
}
