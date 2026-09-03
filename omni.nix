{lib}: {
  # Resolve a repo's omniflake-indexed dependencies into a flake `inputs` set.
  #
  # `mapping` is `{ localName = "index-attribute"; }`. The index keys on the
  # *repository* name, which is not always what a given flake calls the input —
  # `vscode-server` is `nixos-vscode-server`, `zen-browser` is
  # `zen-browser-flake`, and so on. Merge the result into `inputs` and every
  # `inputs.<name>` / `pkgs.inputs.<name>` reference keeps working, with none of
  # these appearing in flake.lock.
  #
  # `omniflake.lib.foundations` replaces a fixed set of inputs — nixpkgs,
  # flake-utils, systems, flake-parts, flake-compat — by *name*, in every
  # subflake, at every depth. That is the job the old `follows` lines did, moved
  # from lock time to evaluation time. `overrides` is merged on top of it, last
  # wins.
  #
  # `overrides` is a *function of the loader*, not a plain attrset, so the
  # caller can unify an input to the loader's own copy of it:
  #
  #   overrides = flakes: {
  #     inherit (inputs) flake-parts;
  #     inherit (flakes) home-manager;   # <- the loader, mid-definition
  #     systems = inputs.systems-linux;
  #   };
  #
  # That self-reference terminates because `withOverrides` applies overrides to
  # a flake's *inputs*, never to the flake being loaded, so `flakes.home-manager`
  # is only ever forced while loading some *other* flake that has a home-manager
  # input. It is what lets the whole graph hold exactly one home-manager without
  # home-manager being a flake input at all — the same shape as omniflake's own
  # `lib.unifyAll`. Don't "simplify" it to a plain attrset.
  #
  # `ownNixpkgs` lists index attributes to resolve through a second loader that
  # drops nixpkgs back out of the override set, so those flakes keep the pin
  # their own author chose. The reason to reach for it is binary caches: a flake
  # whose upstream publishes prebuilt artifacts built them against its own
  # nixpkgs, so unifying nixpkgs changes the derivation hash and every cache hit
  # silently becomes a source build. It costs a second copy of nixpkgs in the
  # closure, so it only pays when that upstream cache is actually configured as
  # a substituter. Both loaders are handed the *unified* loader's overrides, so
  # an unpinned flake still shares the one home-manager.
  mkInputs = {
    omniflake,
    mapping,
    overrides ? (_: {}),
    ownNixpkgs ? [],
  }: let
    loaderFor = unpin:
      omniflake.lib.withOverrides
      (builtins.removeAttrs (omniflake.lib.foundations // overrides unified) unpin);

    unified = loaderFor [];
    ownPkgs = loaderFor ["nixpkgs"];
  in
    lib.mapAttrs
    (_: index: (if builtins.elem index ownNixpkgs then ownPkgs else unified).${index})
    mapping;
}
