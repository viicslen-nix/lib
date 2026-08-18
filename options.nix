# Module-system helpers: option constructors and definition wrappers that
# nixpkgs `lib` doesn't provide.
{lib}: {
  # `mkEnableOption` that defaults to enabled.
  #
  # A module bundle whose parts are on unless switched off wants this on nearly
  # every option, and the hand-written form is
  # `mkEnableOption (mdDoc x) // {default = true;}` — easy to write, easy to get
  # subtly wrong (the `//` binds looser than it looks), and it appears dozens of
  # times in a config of any size.
  mkEnabledOption = description: lib.mkEnableOption description // {default = true;};

  # Wrap every value of an attrset in `mkDefault`, so a whole block of
  # definitions can be overridden per-host without annotating each one.
  mkDefaultAttrs = lib.mapAttrs (_: lib.mkDefault);

  # `mkDefaultAttrs` for an option that accepts either an attrset or a single
  # value (a path, a string): recurse into the attrset, wrap the scalar.
  mkDefaultRecursive = value:
    if lib.isAttrs value && !lib.isDerivation value
    then lib.mapAttrs (_: lib.mkDefault) value
    else lib.mkDefault value;
}
