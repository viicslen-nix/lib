# Helpers for assembling AI agent skill sets (`modules.programs.ai.skills`).
#
# A skill value is either a path to a directory (symlinked whole), a path to a
# single file, or a string (written verbatim as `SKILL.md`). These build such
# attrsets from a local directory, from a flake input, or from a flake input
# with local edits rewritten in.
{lib}: rec {
  # Every `*.md` in `dir`, keyed by basename without the extension.
  # Useful for slash-command directories, where each file is one command.
  mkMarkdownAttrSet = dir: let
    entries = builtins.readDir dir;
    files =
      builtins.filter
      (name: entries.${name} == "regular" && builtins.match ".*\\.md" name != null)
      (builtins.attrNames entries);
  in
    builtins.listToAttrs (map (name: {
        name = builtins.elemAt (builtins.match "(.*)\\.md" name) 0;
        value = dir + "/${name}";
      })
      files);

  # Every skill in `dir`, keyed by name: a subdirectory is taken whole (it may
  # carry references, scripts, agents/), a bare `*.md` is a single-file skill.
  mkSkillAttrSet = dir: let
    entries = builtins.readDir dir;
    skills =
      builtins.filter
      (
        name: let
          kind = entries.${name};
        in
          kind == "directory" || (kind == "regular" && builtins.match ".*\\.md" name != null)
      )
      (builtins.attrNames entries);
  in
    builtins.listToAttrs (map (name: {
        name =
          if entries.${name} == "directory"
          then name
          else builtins.elemAt (builtins.match "(.*)\\.md" name) 0;
        value = dir + "/${name}";
      })
      skills);

  # Coerce `<input>/<sub>` back into a real path.
  #
  # Consumers branch on path-ness to decide *symlink this directory* vs *write
  # this value as a file body*, so a flake input has to arrive as a path. But an
  # input's `outPath` is a **string**, and `/. + "${input}/x"` throws `a string
  # that refers to a store path cannot be appended to a path`. Discarding the
  # context is safe here only because a flake input is a source already realised
  # at eval time, never a derivation that still needs building.
  fromInput = input: sub: /. + (builtins.unsafeDiscardStringContext "${input}/${sub}");

  # Pick several skills out of a flake input by subpath, keyed by basename.
  # The input and its layout are both the caller's to state, so this works
  # against any upstream skill repo whatever directory scheme it uses.
  selectFromInput = input: subs:
    builtins.listToAttrs (map (sub: {
        name = baseNameOf sub;
        value = fromInput input sub;
      })
      subs);

  # An upstream skill with local edits rewritten in, instead of a fork that
  # silently stops tracking upstream. `src` is a path (or path-like string) to
  # the skill's `SKILL.md`; `subs` is a list of `{ from, to; }` substitutions.
  #
  # The `from` anchors are asserted to still be present, because
  # `replaceStrings` otherwise no-ops and hands back vanilla upstream with no
  # signal at all — a reword should break the build, not the skill.
  #
  # Returns a **string**, so this only works for single-file skills; a
  # multi-file one needs a derivation, which costs an IFD (consumers call
  # `pathIsDirectory`, which has to build it to look inside).
  patchSkill = src: subs: let
    body = builtins.readFile src;
    missing = builtins.filter (s: !lib.hasInfix s.from body) subs;
    firstLine = s: builtins.head (lib.splitString "\n" s.from);
  in
    assert lib.assertMsg (missing == []) ''
      Skill patch no longer applies — these anchors are gone from ${toString src}:
      ${lib.concatMapStringsSep "\n" (s: "  - ${firstLine s}") missing}
      Re-sync the patch against the current upstream text.
    ''; builtins.replaceStrings (map (s: s.from) subs) (map (s: s.to) subs) body;
}
