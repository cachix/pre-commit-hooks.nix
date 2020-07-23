{ config, lib, pkgs, ... }:

let

  inherit (lib)
    attrNames
    concatStringsSep
    filterAttrs
    literalExample
    mapAttrsToList
    mkIf
    mkOption
    types
    ;
  inherit (import ../nix/lazyAttrsOf.nix { inherit lib; }) lazyAttrsOf;

  inherit (pkgs) runCommand writeText git;

  cfg = config.pre-commit;

  hookType =
    types.submodule (
      { config, name, ... }:
        {
          options =
            {
              enable =
                mkOption {
                  type = types.bool;
                  description = "Whether to enable this pre-commit hook.";
                  default = false;
                };
              raw =
                mkOption {
                  type = types.attrsOf types.unspecified;
                  description =
                    ''
                      Raw fields of a pre-commit hook. This is mostly for internal use but
                      exposed in case you need to work around something.

                      Default: taken from the other hook options.
                    '';
                };
              name =
                mkOption {
                  type = types.str;
                  default = name;
                  defaultText = literalExample "internal name, same as id";
                  description =
                    ''
                      The name of the hook - shown during hook execution.
                    '';
                };
              entry =
                mkOption {
                  type = types.str;
                  description =
                    ''
                      The entry point - the executable to run. entry can also contain arguments that will not be overridden such as entry: autopep8 -i.
                    '';
                };
              language =
                mkOption {
                  type = types.str;
                  description =
                    ''
                      The language of the hook - tells pre-commit how to install the hook.
                    '';
                  default = "system";
                };
              files =
                mkOption {
                  type = types.str;
                  description =
                    ''
                      The pattern of files to run on.
                    '';
                  default = "";
                };
              types =
                mkOption {
                  type = types.listOf types.str;
                  description =
                    ''
                      List of file types to run on. See Filtering files with types (https://pre-commit.com/#plugins).
                    '';
                  default = [ "file" ];
                };
              description =
                mkOption {
                  type = types.str;
                  description =
                    ''
                      Description of the hook. used for metadata purposes only.
                    '';
                  default = "";
                };
              excludes =
                mkOption {
                  type = types.listOf types.str;
                  description =
                    ''
                      Exclude files that were matched by these patterns.
                    '';
                  default = [];
                };
              pass_filenames =
                mkOption {
                  type = types.bool;
                  description = "Whether to pass filenames as arguments to the entry point.";
                  default = true;
                };
            };
          config =
            {
              raw =
                {
                  inherit (config) name entry language files types pass_filenames;
                  id = name;
                  exclude = mergeExcludes config.excludes;
                };
            };
        }
    );

  mergeExcludes =
    excludes:
      if excludes == [] then "^$" else "(${concatStringsSep "|" excludes})";

  enabledHooks = filterAttrs (id: value: value.enable) cfg.hooks;
  processedHooks =
    mapAttrsToList (id: value: value.raw // { inherit id; }) enabledHooks;

  configFile =
    runCommand "pre-commit-config.json" {
      buildInputs = [ pkgs.jq ];
      passAsFile = [ "rawJSON" ];
      rawJSON = builtins.toJSON cfg.rawConfig;
    } ''
      {
        echo '# DO NOT MODIFY';
        echo '# This file was generated by nix-pre-commit-hooks';
        jq . <"$rawJSONPath"
      } >$out
    '';

  run =
    runCommand "pre-commit-run" { buildInputs = [ git ]; } ''
      set +e
      HOME=$PWD
      cp --no-preserve=mode -R ${cfg.rootSrc} src
      ln -fs ${configFile} src/.pre-commit-config.yaml
      cd src
      rm -rf src/.git
      git init
      git add .
      git config --global user.email "you@example.com"
      git config --global user.name "Your Name"
      git commit -m "init"
      echo "Running: $ pre-commit run --all-files"
      ${cfg.package}/bin/pre-commit run --all-files
      exitcode=$?
      git --no-pager diff --color
      touch $out
      [ $? -eq 0 ] && exit $exitcode
    '';

  # TODO: provide a default pin that the user may override
  inherit (import (import ../nix/sources.nix)."gitignore.nix" { inherit lib; })
    gitignoreSource
    ;
in
{
  options.pre-commit =
    {

      package =
        mkOption {
          type = types.package;
          description =
            ''
              The pre-commit package to use.
            '';
          default = pkgs.pre-commit;
          defaultText =
            literalExample ''
              pkgs.pre-commit
            '';
        };

      tools =
        mkOption {
          type = lazyAttrsOf { elemType = types.package; };

          description =
            ''
              Tool set from which nix-pre-commit will pick binaries.

              nix-pre-commit comes with its own set of packages for this purpose.
            '';
          # This default is for when the module is the entry point rather than
          # /default.nix. /default.nix will override this for efficiency.
          default = (import ../nix { inherit (pkgs) system; }).callPackage ../nix/tools.nix {};
          defaultText =
            literalExample ''nix-pre-commit-hooks-pkgs.callPackage tools-dot-nix { inherit (pkgs) system; }'';
        };

      hooks =
        mkOption {
          type = types.attrsOf hookType;
          description =
            ''
              The hook definitions.
            '';
          default = {};
        };

      run =
        mkOption {
          type = types.package;
          description =
            ''
              A derivation that tests whether the pre-commit hooks run cleanly on
              the entire project.
            '';
          readOnly = true;
          default = run;
        };

      installationScript =
        mkOption {
          type = types.str;
          description =
            ''
              A bash snippet that installs nix-pre-commit in the current directory
            '';
          readOnly = true;
        };

      rootSrc =
        mkOption {
          type = types.package;
          description =
            ''
              The source of the project to be checked.
            '';
          defaultText = literalExample ''gitignoreSource config.root'';
          default = gitignoreSource config.root;
        };

      excludes =
        mkOption {
          type = types.listOf types.str;
          description =
            ''
              Exclude files that were matched by these patterns.
            '';
          default = [];
        };

      default_stages =
        mkOption {
          type = types.listOf types.str;
          description =
            ''
              A configuration wide option for the stages property.
              Installs hooks to the defined stages.
              Default is empty which falls back to 'commit'.
            '';
          default = [];
        };

      rawConfig =
        mkOption {
          type = types.attrs;
          description =
            ''
              The raw configuration before writing to file.

              This option does not have an appropriate merge function.
              It is accessible in case you need to set an attribute that doesn't have an option.
            '';
          internal = true;
        };
    };

  config =
    {

      pre-commit.rawConfig =
        {
          repos =
            [
              {
                repo = "local";
                hooks = processedHooks;
              }
            ];
        } // lib.optionalAttrs (cfg.excludes != []) {
          exclude = mergeExcludes cfg.excludes;
        } // lib.optionalAttrs (cfg.default_stages != []) {
          default_stages = cfg.default_stages;
        };

      pre-commit.installationScript =
        ''
          export PATH=$PATH:${cfg.package}/bin
          if ! type -t git >/dev/null; then
            # This happens in pure shells, including lorri
            echo 1>&2 "WARNING: nix-pre-commit-hooks: git command not found; skipping installation."
          else
            # These update procedures compare before they write, to avoid
            # filesystem churn. This improves performance with watch tools like lorri
            # and prevents installation loops by via lorri.

            if readlink .pre-commit-config.yaml >/dev/null \
              && [[ $(readlink .pre-commit-config.yaml) == ${configFile} ]]; then
              echo 1>&2 "nix-pre-commit-hooks: hooks up to date"
            else
              echo 1>&2 "nix-pre-commit-hooks: updating $PWD repo"

              [ -L .pre-commit-config.yaml ] && unlink .pre-commit-config.yaml

              if [ -e .pre-commit-config.yaml ]; then
                echo 1>&2 "nix-pre-commit-hooks: WARNING: Refusing to install because of pre-existing .pre-commit-config.yaml"
                echo 1>&2 "    1. Translate .pre-commit-config.yaml contents to the new syntax in your Nix file"
                echo 1>&2 "        see https://github.com/hercules-ci/nix-pre-commit-hooks#getting-started"
                echo 1>&2 "    2. remove .pre-commit-config.yaml"
                echo 1>&2 "    3. add .pre-commit-config.yaml to .gitignore"
              else
                ln -s ${configFile} .pre-commit-config.yaml
                # Remove any previously installed hooks (since pre-commit itself has no convergent design)
                hooks="pre-commit pre-merge-commit pre-push prepare-commit-msg commit-msg post-checkout post-commit"
                for hook in $hooks; do
                  pre-commit uninstall -t $hook
                done
                # Add hooks for configured stages (only) ...
                if [ ! -z "${concatStringsSep " " cfg.default_stages}" ]; then
                  for stage in ${concatStringsSep " " cfg.default_stages}; do
                    if [[ "$stage" == "manual" ]]; then
                      continue
                    fi
                    case $stage in
                      commit | merge-commit | push)
                        stage="pre-"$stage
                        pre-commit install -t $stage
                        ;;
                      prepare-commit-msg | commit-msg | post-checkout | post-commit)
                        pre-commit install -t $stage
                        ;;
                      *)
                        echo 1>&2 "ERROR: nix-pre-commit-hooks: either $stage is not a valid stage or pre-commit-hook.nix doesn't yet support it."
                        exit 1
                        ;;
                    esac
                  done
                # ... or default 'pre-commit' hook
                else
                  pre-commit install
                fi
              fi
            fi
          fi
        '';
    };
}
