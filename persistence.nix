{inputs, ...}: {
  # Impermanence helpers for home-manager modules
  # These allow other modules to conditionally add persistent dirs/files
  # when the impermanence module is enabled

  # Add directories to persist (general directories)
  mkPersistentDirs = config: dirs: let
    cfg = config.modules.functionality.impermanence;
  in
    inputs.nixpkgs.lib.mkIf (cfg.enable && cfg.autoPersistence) {
      modules.functionality.impermanence.directories = dirs;
    };

  # Add files to persist
  mkPersistentFiles = config: files: let
    cfg = config.modules.functionality.impermanence;
  in
    inputs.nixpkgs.lib.mkIf (cfg.enable && cfg.autoPersistence) {
      modules.functionality.impermanence.files = files;
    };

  # Add .config directories to persist
  mkPersistentConfig = config: dirs: let
    cfg = config.modules.functionality.impermanence;
  in
    inputs.nixpkgs.lib.mkIf (cfg.enable && cfg.autoPersistence) {
      modules.functionality.impermanence.config = dirs;
    };

  # Add .local/share directories to persist
  mkPersistentShare = config: dirs: let
    cfg = config.modules.functionality.impermanence;
  in
    inputs.nixpkgs.lib.mkIf (cfg.enable && cfg.autoPersistence) {
      modules.functionality.impermanence.share = dirs;
    };

  # Add .cache directories to persist
  mkPersistentCache = config: dirs: let
    cfg = config.modules.functionality.impermanence;
  in
    inputs.nixpkgs.lib.mkIf (cfg.enable && cfg.autoPersistence) {
      modules.functionality.impermanence.cache = dirs;
    };

  # Combined helper to add multiple types at once
  mkPersistence = moduleConfig: {
    directories ? [],
    files ? [],
    config ? [],
    configDirs ? [],
    share ? [],
    cache ? [],
  }: let
    cfg = moduleConfig.modules.functionality.impermanence;
    mergedConfigDirs = config ++ configDirs;
  in
    inputs.nixpkgs.lib.mkIf (cfg.enable && cfg.autoPersistence) {
      modules.functionality.impermanence = {
        inherit directories files share cache;
        config = mergedConfigDirs;
      };
    };

  # Home-manager persistence helper for NixOS
  # Usage: mkHmPersistence { options, users, directories, files, configDirs, share, cache }
  # This applies persistence settings to all specified users via home-manager
  mkHmPersistence = {
    options,
    users,
    directories ? [],
    files ? [],
    configDirs ? [],
    share ? [],
    cache ? [],
  }: let
    inherit (inputs.nixpkgs) lib;
    homeManagerLoaded = builtins.hasAttr "home-manager" options;
    mkUserPersistence = _user: {
      modules.functionality.impermanence = {
        inherit directories files share cache;
        config = configDirs;
      };
    };
  in
    lib.mkIf homeManagerLoaded {
      home-manager.users = lib.genAttrs users mkUserPersistence;
    };

  # NixOS system-level persistence helper
  # Usage: mkNixosPersistence { config, directories, files }
  # This adds directories/files to the NixOS-level impermanence
  mkNixosPersistence = {
    config,
    directories ? [],
    files ? [],
  }: let
    lib = inputs.nixpkgs.lib;
    cfg = config.modules.services.impermanence;
  in
    lib.mkIf cfg.enable {
      modules.services.impermanence.directories = directories;
      modules.services.impermanence.files = files;
    };
}
