{
  description = "Shared Nix helper library";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    systems,
    treefmt-nix,
    ...
  }: let
    inherit (nixpkgs) lib;
    defaultSystems = import systems;
    genSystems = lib.genAttrs defaultSystems;
    mkPkgs = system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    treefmtEval =
      genSystems (system:
        treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} ./treefmt.nix);
  in {
    # Because viicslen-lib.inputs.nixpkgs follows the consumer's nixpkgs,
    # these functions act on the consumer's nixpkgs version at zero extra cost.
    lib = {
      inherit defaultSystems genSystems;

      pkgsFor = mkPkgs;
      pkgFromSystem = pkg: lib.genAttrs defaultSystems (system: (mkPkgs system).${pkg});
      callPackageForSystem = system: path: overrides:
        (mkPkgs system).callPackage path overrides;

      hosts = import ./hosts.nix {inherit lib;};
      modules = import ./modules.nix {inherit lib;};
      inherit (import ./umport.nix {inherit lib;}) umport;
      persistence = import ./persistence.nix {inputs = {inherit nixpkgs;};};
      options = import ./options.nix {inherit lib;};
      discovery = import ./discovery.nix {inherit lib;};
      overlays = import ./overlays.nix {inherit lib;};
      omni = import ./omni.nix {inherit lib;};
      containers = import ./containers.nix {inherit lib;};
      skills = import ./skills.nix {inherit lib;};

      # Wayland compositor helpers – apply { pkgs, lib } once to get the helpers.
      # Works under any Wayland WM (niri, sway, Hyprland, …).
      # Example: wl = vlib.wayland { inherit pkgs lib; };
      #          wl.mkRecordCmd "-o DP-1"  wl.mkMenu [ ... ]
      wayland = {
        pkgs,
        lib,
      }:
        import ./desktop/wayland.nix {inherit pkgs lib;};
    };

    formatter = genSystems (system: treefmtEval.${system}.config.build.wrapper);

    checks = genSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      treefmt = treefmtEval.${system}.config.build.check self;
      statix = pkgs.runCommandLocal "statix-check" {} ''
        ${pkgs.lib.getExe pkgs.statix} check ${./.} && touch $out
      '';
    });
  };
}
