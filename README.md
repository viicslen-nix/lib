# viicslen-nix/lib

**Shared Nix helpers for [viicslen-nix/nixos](https://github.com/viicslen-nix/nixos) and its subflakes.**

[![Nix flake](https://img.shields.io/badge/Nix-flake-5277C3?style=flat-square&logo=nixos&logoColor=white)](https://nixos.wiki/wiki/Flakes)
[![nixpkgs unstable](https://img.shields.io/badge/nixpkgs-unstable-5277C3?style=flat-square&logo=nixos&logoColor=white)](https://github.com/NixOS/nixpkgs/tree/nixos-unstable)
[![treefmt](https://img.shields.io/badge/lint-deadnix_·_statix_·_alejandra-41439A?style=flat-square)](https://github.com/numtide/treefmt-nix)

A plain flake whose main output is a `lib` attrset of pure helpers: module-system
option constructors, filesystem module discovery, overlay constructors,
[omniflake](https://github.com/fzakaria/omniflake) wiring, impermanence,
container and AI-skill helpers, and a couple of Wayland conveniences.

> [!NOTE]
> Nothing here is a NixOS module. Each helper is a function you call from your
> own flake or modules; the option paths a few of them write
> (`modules.functionality.impermanence`, `modules.programs.mkcert`) are
> conventions of the nixos repo.

## Outputs

| Output | Description |
| --- | --- |
| `lib` | The helper library (below) |
| `formatter.<system>` | treefmt wrapper running deadnix, statix and alejandra |
| `checks.<system>.treefmt` | Fails if the tree is not treefmt-clean |
| `checks.<system>.statix` | `statix check`, which also catches lints `statix fix` cannot rewrite (repeated keys) |

Systems are those of [`nix-systems/default`](https://github.com/nix-systems/default).

## `lib`

| Attribute | Source | Provides |
| --- | --- | --- |
| `defaultSystems` | `flake.nix` | The `systems` input's list |
| `genSystems` | `flake.nix` | `lib.genAttrs defaultSystems` |
| `pkgsFor system` | `flake.nix` | `import nixpkgs { inherit system; config.allowUnfree = true; }` |
| `pkgFromSystem name` | `flake.nix` | `{ <system> = pkgs.<name>; }` across `defaultSystems` |
| `callPackageForSystem system path overrides` | `flake.nix` | `callPackage` against `pkgsFor system` |
| `options` | `options.nix` | `mkEnabledOption`, `mkDefaultAttrs`, `mkDefaultRecursive` |
| `discovery` | `discovery.nix` | `discover`, `segmentsOf`, `assertUnique`, `mkTree` — find every `default.nix` (skipping `_`-prefixed paths) and rebuild a nested view over a flat module registry |
| `overlays` | `overlays.nix` | `mkFlakeInputsOverlay` (`pkgs.inputs.<flake>`), `mkChannelOverlay` (`pkgs.stable` / `pkgs.unstable`-style channels) |
| `omni` | `omni.nix` | `mkInputs` — resolve an omniflake-index mapping into `inputs` under one override policy; `ownNixpkgs` keeps chosen flakes on their own nixpkgs pin |
| `containers` | `containers.nix` | `mkHostOption`, `mkMkcertDomains`, `mkTraefikLabels` for OCI-container modules |
| `persistence` | `persistence.nix` | `mkPersistentDirs`/`Files`/`Config`/`Share`/`Cache`, `mkPersistence`, `mkHmPersistence`, `mkNixosPersistence` — impermanence entries that apply only when that module is enabled |
| `skills` | `skills.nix` | `mkSkillAttrSet`, `mkMarkdownAttrSet`, `fromInput`, `selectFromInput`, `patchSkill` for AI-agent skill sets |
| `umport` | `umport.nix` | Recursive or flat `.nix` file importer (MIT, from [yunfachi/nypkgs](https://github.com/yunfachi/nypkgs)) |
| `wayland { pkgs, lib }` | `desktop/wayland.nix` | `mkRecordCmd` (wl-screenrec shell snippet), `mkMenu` (wlr-which-key popup, returns an executable path) |
| `hosts` | `hosts.nix` | `mkNixosConfigurations` — legacy host auto-wiring |
| `modules` | `modules.nix` | `autoImportModules`, `autoImportCategories`, `autoImportRecursive`, `dendriticModuleDefinitions` — legacy module auto-import |

> [!NOTE]
> `hosts` and `modules` predate `discovery` and flake-parts; the nixos repo no
> longer calls them.

## Usage

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    viicslen-lib = {
      url = "github:viicslen-nix/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {viicslen-lib, ...}: let
    vlib = viicslen-lib.lib;
  in {
    packages = vlib.genSystems (system: {
      default = (vlib.pkgsFor system).hello;
    });
  };
}
```

With `nixpkgs` followed, every helper runs against your own nixpkgs, at no
extra evaluation cost.

<details>
<summary>Examples</summary>

Option helpers — the nixos repo extends `lib` with these so modules reach them
directly:

```nix
lib' = lib.extend (_: _: viicslen-lib.lib.options);

options.modules.foo.enable = lib'.mkEnabledOption "foo"; # defaults to true
config = lib'.mkDefaultAttrs { a = 1; b = 2; };           # every value mkDefault
```

Container labels:

```nix
inherit (vlib.containers) mkHostOption mkTraefikLabels;

extraOptions = ["--network=local"] ++ mkTraefikLabels {
  name = "qdrant";
  host = "qdrant.local";
  port = 6333;
};
```

Patching an upstream skill without forking it:

```nix
vlib.skills.patchSkill "${skills-input}/tdd/SKILL.md" [
  { from = "anchor text upstream"; to = "replacement"; }
]
```

Every `from` must still be present, or evaluation fails.

Wayland helpers:

```nix
wl = vlib.wayland { inherit pkgs lib; };
wl.mkRecordCmd ''-o "$(pick-output)"''                   # exits quietly if the flag value is empty
wl.mkMenu [ { key = "q"; desc = "Stop"; cmd = "pkill -INT wl-screenrec"; } ]
```

</details>

## Development

```sh
nix fmt            # deadnix → statix → alejandra, via treefmt
nix flake check    # formatting + statix gate
```

New helpers go in their own file and are wired into `lib` in `flake.nix`, which
is the only entry point.

Inside the nixos repo this flake is checked out at `flakes/lib` and consumed as
`viicslen-lib` (`inputs.self.lib` in modules). Because the root names it
`viicslen-lib`, `just update-subflake lib` only bumps this flake's own lock;
`just update-input viicslen-lib` is what the hosts see. See the root
`AGENTS.md`.
