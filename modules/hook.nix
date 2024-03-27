{ config, name, lib, default_stages, ... }:

let
  inherit (lib) concatStringsSep mkOption types;
  mergeExcludes =
    excludes:
    if excludes == [ ] then "^$" else "(${concatStringsSep "|" excludes})";
in
{
  options = {
    enable = mkOption {
      type = types.bool;
      description = lib.mdDoc "Whether to enable this pre-commit hook.";
      default = false;
    };

    raw = mkOption {
      type = types.attrsOf types.unspecified;
      description = lib.mdDoc
        ''
          Raw fields of a pre-commit hook. This is mostly for internal use but
          exposed in case you need to work around something.

          Default: taken from the other hook options.
        '';
    };

    name = mkOption {
      type = types.str;
      defaultText = lib.literalMD "internal name, same as `id`";
      default = name;
      description = lib.mdDoc
        ''
          The name of the hook. Shown during hook execution.
        '';
    };

    description = mkOption {
      type = types.str;
      description = lib.mdDoc
        ''
          Description of the hook. Used for metadata purposes only.
        '';
      default = "";
    };

    package = mkOption {
      type = types.nullOr types.package;
      description = lib.mdDoc
        ''
          An optional package that provides the hook.

          For most hooks, the package name matches the name of the hook and can be overridden directly.

          ```
          hooks.nixfmt.package = pkgs.nixfmt;
          ```

          Some hooks may require multiple packages or a wrapper script to function correctly.
          Such hooks can expose additional named packages as `packageOverrides`.

          ```
          hooks.rustfmt.packageOverrides.cargo = pkgs.cargo;
          hooks.rustfmt.packageOverrides.rustfmt = pkgs.rustfmt;
          ```
        '';
    };

    packageOverrides = mkOption {
      type = types.submodule {
        freeformType = types.attrsOf types.package;
      };
      default = { };
      description = lib.mdDoc
        ''
          Additional packages required to construct the hook package.
        '';
    };

    entry = mkOption {
      type = types.str;
      description = lib.mdDoc
        ''
          The entry point - the executable to run. {option}`entry` can also contain arguments that will not be overridden, such as `entry = "autopep8 -i";`.
        '';
    };

    language = mkOption {
      type = types.str;
      description = lib.mdDoc
        ''
          The language of the hook - tells pre-commit how to install the hook.
        '';
      default = "system";
    };

    files = mkOption {
      type = types.str;
      description = lib.mdDoc
        ''
          The pattern of files to run on.
        '';
      default = "";
    };

    types = mkOption {
      type = types.listOf types.str;
      description = lib.mdDoc
        ''
          List of file types to run on. See [Filtering files with types](https://pre-commit.com/#plugins).
        '';
      default = [ "file" ];
    };

    types_or = mkOption {
      type = types.listOf types.str;
      description = lib.mdDoc
        ''
          List of file types to run on, where only a single type needs to match.
        '';
      default = [ ];
    };

    excludes = mkOption {
      type = types.listOf types.str;
      description = lib.mdDoc
        ''
          Exclude files that were matched by these patterns.
        '';
      default = [ ];
    };

    pass_filenames = mkOption {
      type = types.bool;
      description = lib.mdDoc ''
        Whether to pass filenames as arguments to the entry point.
      '';
      default = true;
    };

    fail_fast = mkOption {
      type = types.bool;
      description = lib.mdDoc ''
        if true pre-commit will stop running hooks if this hook fails.
      '';
      default = false;
    };

    require_serial = mkOption {
      type = types.bool;
      description = lib.mdDoc ''
        if true this hook will execute using a single process instead of in parallel.
      '';
      default = false;
    };

    stages = mkOption {
      type = types.listOf types.str;
      description = lib.mdDoc ''
        Confines the hook to run at a particular stage.
      '';
      default = default_stages;
      defaultText = (lib.literalExpression or lib.literalExample) "default_stages";
    };

    verbose = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc ''
        forces the output of the hook to be printed even when the hook passes.
      '';
    };

    always_run = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc ''
        if true this hook will run even if there are no matching files.
      '';
    };
  };

  config = {
    raw =
      {
        inherit (config) name entry language files types types_or pass_filenames fail_fast require_serial stages verbose always_run;
        id = config.name;
        exclude = mergeExcludes config.excludes;
      };
  };
}
