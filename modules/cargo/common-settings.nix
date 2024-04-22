{ lib, cargoManifestPath, ... }:
let
  inherit (lib) types mkOption;
  nameType = types.strMatching "[][*?!0-9A-Za-z_-]+";
  featureNameType = types.strMatching "([0-9A-Za-z_-]+/)?[0-9A-Za-z_+-]+";
  profileNameType = types.strMatching "[0-9A-Za-z_-]+";
  tripleType = types.strMatching "^([0-9a-z_.]+)(-[0-9a-z_]+){1,3}$";
in
{
  # Package Selection:
  exclude = mkOption {
    type = types.listOf nameType;
    description = lib.mdDoc "Exclude packages from the check";
    default = [ ];
  };
  package = mkOption {
    type = types.listOf nameType;
    description = lib.mdDoc "Package(s) to check";
    default = [ ];
  };
  workspace = mkOption {
    type = types.bool;
    description = lib.mdDoc "Check all packages in the workspace";
    default = false;
  };

  # Target Selection:
  all-targets = mkOption {
    type = types.bool;
    description = lib.mdDoc "Check all targets";
    default = false;
  };
  bench = mkOption {
    type = types.listOf nameType;
    description = lib.mdDoc "Check only the specified bench targets";
    default = [ ];
  };
  benches = mkOption {
    type = types.bool;
    description = lib.mdDoc "Check all bench targets";
    default = false;
  };
  bin = mkOption {
    type = types.listOf nameType;
    description = lib.mdDoc "Check only the specified binaries";
    default = [ ];
  };
  bins = mkOption {
    type = types.bool;
    description = lib.mdDoc "Check all binaries";
    default = false;
  };
  example = mkOption {
    type = types.listOf nameType;
    description = lib.mdDoc "Check only the specified examples";
    default = [ ];
  };
  examples = mkOption {
    type = types.bool;
    description = lib.mdDoc "Check all examples";
    default = false;
  };
  lib = mkOption {
    type = types.bool;
    description = lib.mdDoc "Check only this package's library";
    default = false;
  };
  test = mkOption {
    type = types.listOf nameType;
    description = lib.mdDoc "Check only the specified test targets";
    default = [ ];
  };
  tests = mkOption {
    type = types.bool;
    description = lib.mdDoc "Check all test targets";
    default = false;
  };

  # Feature Selection:
  all-features = mkOption {
    type = types.bool;
    description = lib.mdDoc "Activate all available features";
    default = false;
  };
  features = mkOption {
    type = types.listOf featureNameType;
    description = lib.mdDoc "List of features to activate";
    default = [ ];
    apply = features: lib.optional (features != [ ]) (builtins.concatStringsSep "," features);
  };
  no-default-features = mkOption {
    type = types.bool;
    description = lib.mdDoc "Do not activate the `default` feature";
    default = false;
  };

  # Compilation Options:
  ignore-rust-version = mkOption {
    type = types.bool;
    description = lib.mdDoc "Ignore `rust-version` specification in packages";
    default = false;
  };
  profile = mkOption {
    type = types.nullOr profileNameType;
    description = lib.mdDoc "Check artifacts with the specified profile";
    default = null;
  };
  release = mkOption {
    type = types.bool;
    description = lib.mdDoc "Check artifacts in release mode, with optimizations";
    default = false;
  };
  target = mkOption {
    type = types.listOf tripleType;
    description = lib.mdDoc "Check for the target triple(s)";
    default = [ ];
  };
  timings = mkOption {
    type = types.bool;
    description = lib.mdDoc "Output information how long each compilation takes";
    default = false;
  };

  # Output Options:
  target-dir = mkOption {
    type = types.nullOr types.path;
    description = lib.mdDoc "Directory for all generated artifacts";
    default = null;
  };

  # Display Options:
  color = mkOption {
    type = types.enum [ "auto" "always" "never" ];
    description = lib.mdDoc "Coloring the output";
    default = "always";
  };
  message-format = mkOption {
    type = types.nullOr (types.enum [ "human" "short" ]);
    description = lib.mdDoc "The output format of diagnostic messages";
    default = null;
  };
  verbose = mkOption {
    type = types.bool;
    description = lib.mdDoc "Use verbose output";
    default = false;
  };

  # Manifest Options:
  frozen = mkOption {
    type = types.bool;
    description = lib.mdDoc "Require Cargo.lock and cache are up to date";
    default = false;
  };
  locked = mkOption {
    type = types.bool;
    description = lib.mdDoc "Require Cargo.lock is up to date";
    default = false;
  };
  manifest-path = mkOption {
    type = types.nullOr types.str;
    description = lib.mdDoc "Path to Cargo.toml";
    default = cargoManifestPath;
  };
  offline = mkOption {
    type = types.bool;
    description = lib.mdDoc "Run without accessing the network";
    default = false;
  };

  # Common Options:
  config = mkOption {
    type = types.either types.str types.attrs;
    description = lib.mdDoc "Override configuration values";
    default = { };
    apply = config:
      if builtins.isAttrs config
      then
        lib.mapAttrsToList
          (key: value: "${key}=${toString value}")
          config
      else
        config;
  };
  Z = mkOption {
    type = types.listOf types.str;
    description = lib.mdDoc "Unstable (nightly-only) flags to Cargo";
    default = [ ];
  };

  # Miscellaneous Options:
  future-incompat-report = mkOption {
    type = types.bool;
    description = lib.mdDoc "Outputs a future incompatibility report at the end of the build";
    default = false;
  };
  jobs = mkOption {
    type = types.nullOr types.ints.positive;
    description = lib.mdDoc "Number of parallel jobs, defaults to # of CPUs";
    default = null;
  };
  keep-going = mkOption {
    type = types.bool;
    description = lib.mdDoc "Do not abort the build as soon as there is an error";
    default = false;
  };
}
