# viicslen-nix/lib

Shared Nix helper library used across the [nixos](https://github.com/viicslen-nix/nixos) monorepo and standalone sub-flakes.

## Contents

| File | Purpose |
|------|---------|
| `default.nix` | Assembles everything into a single lib, merged on top of `nixpkgs.lib` |
| `hosts.nix` | `mkNixosConfigurations` – auto-wires NixOS hosts from a hosts directory |
| `modules.nix` | `autoImportModules`, `autoImportCategories`, `autoImportRecursive` |
| `persistence.nix` | `mkPersistence`, `mkHmPersistence`, `mkNixosPersistence`, … |
| `umport.nix` | `umport` – recursive/non-recursive nix file importer (MIT, upstream: yunfachi/nypkgs) |
| `desktop/niri.nix` | `mkRecordCmd`, `mkMenu` – niri compositor helpers |

## Usage

### As a flake input (standalone sub-flakes)

```nix
# flake.nix
inputs.nixpkgs-lib.url = "github:viicslen-nix/lib";

# Desktop helpers (needs pkgs + lib)
niriLib = inputs.nixpkgs-lib.mkDesktopLib { inherit pkgs lib; };
niriLib.niri.mkRecordCmd ""             # → shell string
niriLib.niri.mkMenu [ { key = "q"; … } ] # → derivation

# Full lib (needs consuming flake's inputs + outputs)
lib = inputs.nixpkgs-lib.mkLib { inherit inputs outputs; };
```

### As a git submodule (nixos monorepo)

The repo is checked out under `lib/` in the nixos monorepo and imported directly:

```nix
# flake.nix
lib = import ./lib { inherit inputs outputs; };
```
