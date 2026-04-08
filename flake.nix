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
    mkPkgs = system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
  in {
    # Because viicslen-lib.inputs.nixpkgs follows the consumer's nixpkgs,
    # these functions act on the consumer's nixpkgs version at zero extra cost.
    lib = {
      inherit defaultSystems;
      genSystems = lib.genAttrs defaultSystems;

      pkgsFor = mkPkgs;
      pkgFromSystem = pkg: lib.genAttrs defaultSystems (system: (mkPkgs system).${pkg});
      callPackageForSystem = system: path: overrides:
        (mkPkgs system).callPackage path overrides;

      hosts = import ./hosts.nix {inherit lib;};
      modules = import ./modules.nix {inherit lib;};
      umport = (import ./umport.nix {inherit lib;}).umport;
      persistence = import ./persistence.nix {inputs = {nixpkgs = nixpkgs;};};

      # Wayland compositor helpers – apply { pkgs, lib } once to get the helpers.
      # Works under any Wayland WM (niri, sway, Hyprland, …).
      # Example: wl = vlib.wayland { inherit pkgs lib; };
      #          wl.mkRecordCmd ""  wl.mkMenu [ ... ]
      wayland = {
        pkgs,
        lib,
      }:
        import ./desktop/wayland.nix {inherit pkgs lib;};
    };
  };
}
