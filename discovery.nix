# Filesystem module discovery, and the nested view over a flat module registry.
#
# A dendritic flake registers every module under a flat `flake.modules.<class>`
# keyed by directory base name. These rebuild the directory nesting over that
# registry so import sites keep their namespaces:
#
#   imports = with nixosModules; [hardware.nvidia programs.docker];
{lib}: rec {
  # Every `default.nix` under `root`, skipping any path with a `_`-prefixed
  # component — the convention for directories that are helpers rather than
  # modules.
  discover = root:
    builtins.filter (
      p: let
        s = toString p;
      in
        lib.hasSuffix "/default.nix" s && !(lib.hasInfix "/_" s)
    ) (lib.filesystem.listFilesRecursive root);

  # ["hardware" "nvidia"] for <root>/hardware/nvidia/default.nix
  segmentsOf = root: p:
    lib.init (lib.splitString "/" (lib.removePrefix (toString root + "/") (toString p)));

  # The flat registry keys off directory base names, so those must be unique
  # within a tree. Fail loudly rather than let one registration silently clobber
  # another. Returns true, so it reads as `assert assertUnique root;`.
  assertUnique = root: let
    names = map (p: lib.last (segmentsOf root p)) (discover root);
    dupes = lib.subtractLists (lib.unique names) names;
  in
    if dupes == []
    then true
    else throw "Duplicate module directory names under ${toString root}: ${lib.concatStringsSep ", " (lib.unique dupes)}";

  # Map each discovered directory path onto its flat `registry` entry, producing
  # the nested view. A directory that is both a module and a namespace (it has
  # children, and its own default.nix declares the settings they read) is
  # reachable as `<namespace>.base`, so its children don't clobber it.
  mkTree = root: registry: let
    files = discover root;
    allSegments = map (segmentsOf root) files;
    isNamespace = segs:
      lib.any
      (other: lib.length other > lib.length segs && lib.take (lib.length segs) other == segs)
      allSegments;
    keyFor = segs:
      if isNamespace segs
      then segs ++ ["base"]
      else segs;
  in
    lib.foldl' (
      acc: p: let
        segs = segmentsOf root p;
      in
        lib.recursiveUpdate acc
        (lib.setAttrByPath (keyFor segs) registry.${lib.last segs})
    ) {}
    files;
}
