{ config, lib, pkgs, ... }:
let
  inherit (config) tools settings;
  inherit (lib) mkOption types;

  cargoManifestPathArg =
    lib.optionalString
      (settings.rust.cargoManifestPath != null)
      "--manifest-path ${lib.escapeShellArg settings.rust.cargoManifestPath}";

  mkCmdArgs = predActionList:
    lib.concatStringsSep
      " "
      (builtins.foldl'
        (acc: entry:
          acc ++ lib.optional (builtins.elemAt entry 0) (builtins.elemAt entry 1))
        [ ]
        predActionList);

in
{
  options.settings =
    {
      ansible-lint =
        {
          configPath = mkOption {
            type = types.str;
            description = lib.mdDoc "Path to the YAML configuration file.";
            # an empty string translates to use default configuration of the
            # underlying ansible-lint binary
            default = "";
          };
          subdir = mkOption {
            type = types.str;
            description = lib.mdDoc "Path to the Ansible subdirectory.";
            default = "";
          };
        };
      hpack =
        {
          silent =
            mkOption {
              type = types.bool;
              description = lib.mdDoc "Whether generation should be silent.";
              default = false;
            };
        };
      hlint =
        {
          hintFile =
            mkOption {
              type = types.nullOr types.path;
              description = lib.mdDoc "Path to hlint.yaml. By default, hlint searches for .hlint.yaml in the project root.";
              default = null;
            };
        };
      isort =
        {
          profile =
            mkOption {
              type = types.enum [ "" "black" "django" "pycharm" "google" "open_stack" "plone" "attrs" "hug" "wemake" "appnexus" ];
              description = lib.mdDoc "Built-in profiles to allow easy interoperability with common projects and code styles.";
              default = "";
            };
          flags =
            mkOption {
              type = types.str;
              description = lib.mdDoc "Flags passed to isort. See all available [here](https://pycqa.github.io/isort/docs/configuration/options.html).";
              default = "";
            };
        };
      latexindent =
        {
          flags =
            mkOption {
              type = types.str;
              description = lib.mdDoc "Flags passed to latexindent. See available flags [here](https://latexindentpl.readthedocs.io/en/latest/sec-how-to-use.html#from-the-command-line)";
              default = "--local --silent --overwriteIfDifferent";
            };
        };
      ormolu =
        {
          defaultExtensions =
            mkOption {
              type = types.listOf types.str;
              description = lib.mdDoc "Haskell language extensions to enable.";
              default = [ ];
            };
          cabalDefaultExtensions =
            mkOption {
              type = types.bool;
              description = lib.mdDoc "Use `default-extensions` from `.cabal` files.";
              default = false;
            };
        };
      alejandra =
        {
          check =
            mkOption {
              type = types.bool;
              description = lib.mdDoc "Check if the input is already formatted and disable writing in-place the modified content";
              default = false;
              example = true;
            };
          exclude =
            mkOption {
              type = types.listOf types.str;
              description = lib.mdDoc "Files or directories to exclude from formatting.";
              default = [ ];
              example = [ "flake.nix" "./templates" ];
            };
          package =
            mkOption {
              type = types.package;
              description = lib.mdDoc "The `alejandra` package to use.";
              default = "${pkgs.alejandra}";
              defaultText = "\${pkgs.alejandra}";
              example = "\${pkgs.alejandra}";
            };
          threads =
            mkOption {
              type = types.nullOr types.int;
              description = lib.mdDoc "Number of formatting threads to spawn.";
              default = null;
              example = 8;
            };
          verbosity =
            mkOption {
              type = types.enum [ "normal" "quiet" "silent" ];
              description = lib.mdDoc "Whether informational messages or all messages should be hidden or not.";
              default = "normal";
              example = "quiet";
            };
        };
      deadnix =
        {
          edit =
            mkOption {
              type = types.bool;
              description = lib.mdDoc "Remove unused code and write to source file.";
              default = false;
            };

          exclude =
            mkOption {
              type = types.listOf types.str;
              description = lib.mdDoc "Files to exclude from analysis.";
              default = [ ];
            };

          hidden =
            mkOption {
              type = types.bool;
              description = lib.mdDoc "Recurse into hidden subdirectories and process hidden .*.nix files.";
              default = false;
            };

          noLambdaArg =
            mkOption {
              type = types.bool;
              description = lib.mdDoc "Don't check lambda parameter arguments.";
              default = false;
            };

          noLambdaPatternNames =
            mkOption {
              type = types.bool;
              description = lib.mdDoc "Don't check lambda pattern names (don't break nixpkgs `callPackage`).";
              default = false;
            };

          noUnderscore =
            mkOption {
              type = types.bool;
              description = lib.mdDoc "Don't check any bindings that start with a `_`.";
              default = false;
            };

          quiet =
            mkOption {
              type = types.bool;
              description = lib.mdDoc "Don't print a dead code report.";
              default = false;
            };
        };
      statix =
        {
          format =
            mkOption {
              type = types.enum [ "stderr" "errfmt" "json" ];
              description = lib.mdDoc "Error Output format.";
              default = "errfmt";
            };

          ignore =
            mkOption {
              type = types.listOf types.str;
              description = lib.mdDoc "Globs of file patterns to skip.";
              default = [ ];
              example = [ "flake.nix" "_*" ];
            };
        };
      markdownlint = {
        config =
          mkOption {
            type = types.attrs;
            description = lib.mdDoc
              "See https://github.com/DavidAnson/markdownlint/blob/main/schema/.markdownlint.jsonc";
            default = { };
          };
      };
      mdl = {
        package =
          mkOption {
            type = types.package;
            description = lib.mdDoc "The `mdl` package to use.";
            default = "${tools.mdl}";
            defaultText = "\${tools.mdl}";
            example = "\${pkgs.mdl}";
          };
        configPath =
          mkOption {
            type = types.str;
            description = lib.mdDoc "The configuration file to use.";
            default = "";
          };
        git-recurse =
          mkOption {
            type = types.bool;
            description = lib.mdDoc "Only process files known to git when given a directory.";
            default = false;
          };
        ignore-front-matter =
          mkOption {
            type = types.bool;
            description = lib.mdDoc "Ignore YAML front matter.";
            default = false;
          };
        json =
          mkOption {
            type = types.bool;
            description = lib.mdDoc "Format output as JSON.";
            default = false;
          };
        rules =
          mkOption {
            type = types.listOf types.str;
            description = lib.mdDoc "Markdown rules to use for linting. Per default all rules are processed.";
            default = [ ];
          };
        rulesets =
          mkOption {
            type = types.listOf types.str;
            description = lib.mdDoc "Specify additional ruleset files to load.";
            default = [ ];
          };
        show-aliases =
          mkOption {
            type = types.bool;
            description = lib.mdDoc "Show rule alias instead of rule ID when viewing rules.";
            default = false;
          };
        warnings =
          mkOption {
            type = types.bool;
            description = lib.mdDoc "Show Kramdown warnings.";
            default = false;
          };
        skip-default-ruleset =
          mkOption {
            type = types.bool;
            description = lib.mdDoc "Do not load the default markdownlint ruleset. Use this option if you only want to load custom rulesets.";
            default = false;
          };
        style =
          mkOption {
            type = types.str;
            description = lib.mdDoc "Select which style mdl uses.";
            default = "default";
          };
        tags =
          mkOption {
            type = types.listOf types.str;
            description = lib.mdDoc "Markdown rules to use for linting containing the given tags. Per default all rules are processed.";
            default = [ ];
          };
        verbose =
          mkOption {
            type = types.bool;
            description = lib.mdDoc "Increase verbosity.";
            default = false;
          };
      };
      denolint =
        {
          format =
            mkOption {
              type = types.enum [ "default" "compact" "json" ];
              description = lib.mdDoc "Output format.";
              default = "default";
            };

          configPath =
            mkOption {
              type = types.str;
              description = lib.mdDoc "Path to the configuration JSON file";
              # an empty string translates to use default configuration of the
              # underlying deno binary (i.e deno.json or deno.jsonc)
              default = "";
            };
        };
      denofmt =
        {
          write =
            mkOption {
              type = types.bool;
              description = lib.mdDoc "Whether to edit files inplace.";
              default = true;
            };
          configPath =
            mkOption {
              type = types.str;
              description = lib.mdDoc "Path to the configuration JSON file";
              # an empty string translates to use default configuration of the
              # underlying deno binary (i.e deno.json or deno.jsonc)
              default = "";
            };
        };
      mypy =
        {
          binPath =
            mkOption {
              type = types.str;
              description = lib.mdDoc "Mypy binary path. Should be used to specify the mypy executable in an environment containing your typing stubs.";
              default = "${pkgs.mypy}/bin/mypy";
              defaultText = lib.literalExpression ''
                "''${pkgs.mypy}/bin/mypy"
              '';
            };
        };
      nixfmt =
        {
          width =
            mkOption {
              type = types.nullOr types.int;
              description = lib.mdDoc "Line width.";
              default = null;
            };
        };
      prettier =
        {
          binPath =
            mkOption {
              type = types.path;
              description = lib.mdDoc
                "`prettier` binary path. E.g. if you want to use the `prettier` in `node_modules`, use `./node_modules/.bin/prettier`.";
              default = "${tools.prettier}/bin/prettier";
              defaultText = lib.literalExpression ''
                "''${tools.prettier}/bin/prettier"
              '';
            };

          write =
            mkOption {
              type = types.bool;
              description = lib.mdDoc "Whether to edit files inplace.";
              default = true;
            };

          output =
            mkOption {
              description = lib.mdDoc "Output format.";
              type = types.nullOr (types.enum [ "check" "list-different" ]);
              default = "list-different";
            };
        };
      eslint =
        {
          binPath =
            mkOption {
              type = types.path;
              description = lib.mdDoc
                "`eslint` binary path. E.g. if you want to use the `eslint` in `node_modules`, use `./node_modules/.bin/eslint`.";
              default = "${tools.eslint}/bin/eslint";
              defaultText = lib.literalExpression "\${tools.eslint}/bin/eslint";
            };

          extensions =
            mkOption {
              type = types.str;
              description = lib.mdDoc
                "The pattern of files to run on, see [https://pre-commit.com/#hooks-files](https://pre-commit.com/#hooks-files).";
              default = "\\.js$";
            };
        };
      eclint =
        {
          package =
            mkOption {
              type = types.package;
              description = lib.mdDoc "The `eclint` package to use.";
              default = "${tools.eclint}";
              defaultText = lib.literalExpression "\${tools.eclint}";
              example = lib.literalExpression "\${pkgs.eclint}";
            };
          fix =
            mkOption {
              type = types.bool;
              description = lib.mdDoc "Modify files in place rather than showing the errors.";
              default = false;
            };
          summary =
            mkOption {
              type = types.bool;
              description = lib.mdDoc "Only show number of errors per file.";
              default = false;
            };
          color =
            mkOption {
              type = types.enum [ "auto" "always" "never" ];
              description = lib.mdDoc "When to generate colored output.";
              default = "auto";
            };
          exclude =
            mkOption {
              type = types.listOf types.str;
              description = lib.mdDoc "Filter to exclude files.";
              default = [ ];
            };
          verbosity =
            mkOption {
              type = types.enum [ 0 1 2 3 4 ];
              description = lib.mdDoc "Log level verbosity";
              default = 0;
            };
        };
      rome =
        {
          binPath =
            mkOption {
              type = types.path;
              description = lib.mdDoc "`rome` binary path. E.g. if you want to use the `rome` in `node_modules`, use `./node_modules/.bin/rome`.";
              default = "${pkgs.rome}/bin/rome";
              defaultText = "\${pkgs.rome}/bin/rome";
            };

          write =
            mkOption {
              type = types.bool;
              description = lib.mdDoc "Whether to edit files inplace.";
              default = true;
            };

          configPath = mkOption {
            type = types.str;
            description = lib.mdDoc "Path to the configuration JSON file";
            # an empty string translates to use default configuration of the
            # underlying rome binary (i.e rome.json if exists)
            default = "";
          };
        };

      typos =
        {
          color =
            mkOption {
              type = types.enum [ "auto" "always" "never" ];
              description = lib.mdDoc "When to use generate output.";
              default = "auto";
            };

          config =
            mkOption {
              type = types.str;
              description = lib.mdDoc "Multiline-string configuration passed as config file.";
              default = "";
              example = ''
                [files]
                ignore-dot = true

                [default]
                binary = false

                [type.py]
                extend-glob = []
              '';
            };

          configPath =
            mkOption {
              type = types.str;
              description = lib.mdDoc "Path to a custom config file.";
              default = "";
            };

          diff =
            mkOption {
              type = types.bool;
              description = lib.mdDoc "Whether to print a diff of what would change.";
              default = false;
            };

          exclude =
            mkOption {
              type = types.str;
              description = lib.mdDoc "Which files & directories to exclude matching the glob.";
              default = "";
              example = "*.nix";
            };

          format =
            mkOption {
              type = types.enum [ "silent" "brief" "long" "json" ];
              description = lib.mdDoc "Which output format to use.";
              default = "long";
            };

          hidden =
            mkOption {
              type = types.bool;
              description = lib.mdDoc "Whether to search hidden files and directories.";
              default = false;
            };

          locale =
            mkOption {
              type = types.enum [ "en" "en-us" "en-gb" "en-ca" "en-au" ];
              description = lib.mdDoc "Which language to use for spell checking.";
              default = "en";
            };

          write =
            mkOption {
              type = types.bool;
              description = lib.mdDoc "Whether to fix spelling in files by writing them. Cannot be used with `typos.settings.diff`.";
              default = false;
            };
        };

      revive =
        {
          configPath =
            mkOption {
              type = types.str;
              description = lib.mdDoc "Path to the configuration TOML file.";
              # an empty string translates to use default configuration of the
              # underlying revive binary
              default = "";
            };

        };

      flynt =
        {
          aggressive =
            mkOption {
              type = types.bool;
              description = lib.mdDoc "Include conversions with potentially changed behavior.";
              default = false;
            };
          binPath =
            mkOption {
              type = types.str;
              description = lib.mdDoc "flynt binary path. Can be used to specify the flynt binary from an existing Python environment.";
              default = "${settings.flynt.package}/bin/flynt";
              defaultText = "\${settings.flynt.package}/bin/flynt";
            };
          dry-run =
            mkOption {
              type = types.bool;
              description = lib.mdDoc "Do not change files in-place and print diff instead.";
              default = false;
            };
          exclude =
            mkOption {
              type = types.listOf types.str;
              description = lib.mdDoc "Ignore files with given strings in their absolute path.";
              default = [ ];
            };
          fail-on-change =
            mkOption {
              type = types.bool;
              description = lib.mdDoc "Fail when diff is not empty (for linting purposes).";
              default = true;
            };
          line-length =
            mkOption {
              type = types.nullOr types.int;
              description = lib.mdDoc "Convert expressions spanning multiple lines, only if the resulting single line will fit into this line length limit.";
              default = null;
            };
          no-multiline =
            mkOption {
              type = types.bool;
              description = lib.mdDoc "Convert only single line expressions.";
              default = false;
            };
          package =
            mkOption {
              type = types.package;
              description = lib.mdDoc "The `flynt` package to use.";
              default = "${pkgs.python311Packages.flynt}";
              defaultText = "\${pkgs.python311Packages.flynt}";
              example = "\${pkgs.python310Packages.flynt}";
            };
          quiet =
            mkOption {
              type = types.bool;
              description = lib.mdDoc "Run without output.";
              default = false;
            };
          string =
            mkOption {
              type = types.bool;
              description = lib.mdDoc "Interpret the input as a Python code snippet and print the converted version.";
              default = false;
            };
          transform-concats =
            mkOption {
              type = types.bool;
              description = lib.mdDoc "Replace string concatenations with f-strings.";
              default = false;
            };
          verbose =
            mkOption {
              type = types.bool;
              description = lib.mdDoc "Run with verbose output.";
              default = false;
            };
        };

      phpcs =
        {
          binPath =
            mkOption {
              type = types.str;
              description = lib.mdDoc "PHP_CodeSniffer binary path.";
              default = "${pkgs.php82Packages.phpcs}/bin/phpcs";
              defaultText = lib.literalExpression ''
                "''${pkgs.php80Packages.phpcs}/bin/phpcs"
              '';
            };
        };

      phpcbf =
        {
          binPath =
            mkOption {
              type = types.str;
              description = lib.mdDoc "PHP_CodeSniffer binary path.";
              default = "${pkgs.php82Packages.phpcbf}/bin/phpcbf";
              defaultText = lib.literalExpression ''
                "''${pkgs.php80Packages.phpcbf}/bin/phpcbf"
              '';
            };
        };

      phpstan =
        {
          binPath =
            mkOption {
              type = types.str;
              description = lib.mdDoc "PHPStan binary path.";
              default = "${pkgs.php82Packages.phpstan}/bin/phpstan";
              defaultText = lib.literalExpression ''
                "''${pkgs.php81Packages.phpstan}/bin/phpstan"
              '';
            };
        };

      php-cs-fixer =
        {
          binPath =
            mkOption {
              type = types.str;
              description = lib.mdDoc "PHP-CS-Fixer binary path.";
              default = "${pkgs.php82Packages.php-cs-fixer}/bin/php-cs-fixer";
              defaultText = lib.literalExpression ''
                "''${pkgs.php81Packages.php-cs-fixer}/bin/php-cs-fixer"
              '';
            };
        };

      psalm =
        {
          binPath =
            mkOption {
              type = types.str;
              description = lib.mdDoc "Psalm binary path.";
              default = "${pkgs.php82Packages.psalm}/bin/psalm";
              defaultText = lib.literalExpression ''
                "''${pkgs.php81Packages.phpstan}/bin/psalm"
              '';
            };
        };

      pylint =
        {
          binPath =
            mkOption {
              type = types.str;
              description = lib.mdDoc "Pylint binary path. Should be used to specify Pylint binary from your Nix-managed Python environment.";
              default = "${pkgs.python39Packages.pylint}/bin/pylint";
              defaultText = lib.literalExpression ''
                "''${pkgs.python39Packages.pylint}/bin/pylint"
              '';
            };

          reports =
            mkOption {
              type = types.bool;
              description = lib.mdDoc "Whether to display a full report.";
              default = false;
            };

          score =
            mkOption {
              type = types.bool;
              description = lib.mdDoc "Whether to activate the evaluation score.";
              default = true;
            };
        };

      pyupgrade =
        {
          binPath =
            mkOption {
              type = types.str;
              description = lib.mdDoc "pyupgrade binary path. Should be used to specify the pyupgrade binary from your Nix-managed Python environment.";
              default = "${pkgs.pyupgrade}/bin/pyupgrade";
              defaultText = lib.literalExpression ''
                "''${pkgs.pyupgrade}/bin/pyupgrade"
              '';
            };
        };

      pyright =
        {
          binPath =
            mkOption {
              type = types.str;
              description = lib.mdDoc "Pyright binary path. Should be used to specify the pyright executable in an environment containing your typing stubs.";
              default = "${pkgs.pyright}/bin/pyright";
              defaultText = lib.literalExpression ''
                "''${pkgs.pyright}/bin/pyright"
              '';
            };
        };

      flake8 =
        {
          binPath =
            mkOption {
              type = types.str;
              description = lib.mdDoc "flake8 binary path. Should be used to specify flake8 binary from your Nix-managed Python environment.";
              default = "${pkgs.python39Packages.flake8}/bin/flake8";
              defaultText = lib.literalExpression ''
                "''${pkgs.python39Packages.flake8}/bin/flake8"
              '';
            };

          format =
            mkOption {
              type = types.str;
              description = lib.mdDoc "Output format.";
              default = "default";
            };
        };

      autoflake =
        {
          binPath =
            mkOption {
              type = types.str;
              description = lib.mdDoc "Path to autoflake binary.";
              default = "${pkgs.autoflake}/bin/autoflake";
              defaultText = lib.literalExpression ''
                "''${pkgs.autoflake}/bin/autoflake"
              '';
            };

          flags =
            mkOption {
              type = types.str;
              description = lib.mdDoc "Flags passed to autoflake.";
              default = "--in-place --expand-star-imports --remove-duplicate-keys --remove-unused-variables";
            };
        };

      rust =
        {
          cargoManifestPath = mkOption {
            type = types.nullOr types.str;
            description = lib.mdDoc "Path to Cargo.toml";
            default = null;
          };
        };

      yamllint =
        {
          relaxed = mkOption {
            type = types.bool;
            description = lib.mdDoc "Whether to use the relaxed configuration.";
            default = false;
          };

          configPath = mkOption {
            type = types.str;
            description = lib.mdDoc "Path to the YAML configuration file.";
            # an empty string translates to use default configuration of the
            # underlying yamllint binary
            default = "";
          };
        };

      clippy =
        {
          denyWarnings = mkOption {
            type = types.bool;
            description = lib.mdDoc "Fail when warnings are present";
            default = false;
          };
          offline = mkOption {
            type = types.bool;
            description = lib.mdDoc "Run clippy offline";
            default = true;
          };
          allFeatures = mkOption {
            type = types.bool;
            description = lib.mdDoc "Run clippy with --all-features";
            default = false;
          };
        };

      treefmt =
        {
          package = mkOption {
            type = types.package;
            description = lib.mdDoc
              ''
                The `treefmt` package to use.

                Should include all the formatters configured by treefmt.

                For example:
                ```nix
                pkgs.writeShellApplication {
                  name = "treefmt";
                  runtimeInputs = [
                    pkgs.treefmt
                    pkgs.nixpkgs-fmt
                    pkgs.black
                  ];
                  text =
                    '''
                      exec treefmt "$@"
                    ''';
                }
                ```
              '';
          };
        };

      mkdocs-linkcheck =
        {
          binPath =
            mkOption {
              type = types.path;
              description = lib.mdDoc "mkdocs-linkcheck binary path. Should be used to specify the mkdocs-linkcheck binary from your Nix-managed Python environment.";
              default = "${pkgs.python311Packages.mkdocs-linkcheck}/bin/mkdocs-linkcheck";
              defaultText = lib.literalExpression ''
                "''${pkgs.python311Packages.mkdocs-linkcheck}/bin/mkdocs-linkcheck"
              '';
            };

          path =
            mkOption {
              type = types.str;
              description = lib.mdDoc "Path to check";
              default = "";
            };

          local-only =
            mkOption {
              type = types.bool;
              description = lib.mdDoc "Whether to only check local links.";
              default = false;
            };

          recurse =
            mkOption {
              type = types.bool;
              description = lib.mdDoc "Whether to recurse directories under path.";
              default = false;
            };

          extension =
            mkOption {
              type = types.str;
              description = lib.mdDoc "File extension to scan for.";
              default = "";
            };

          method =
            mkOption {
              type = types.enum [ "get" "head" ];
              description = lib.mdDoc "HTTP method to use when checking external links.";
              default = "get";
            };
        };

      dune-fmt =
        {
          auto-promote =
            mkOption {
              type = types.bool;
              description = lib.mdDoc "Whether to auto-promote the changes.";
              default = true;
            };

          extraRuntimeInputs =
            mkOption {
              type = types.listOf types.package;
              description = lib.mdDoc "Extra runtimeInputs to add to the environment, eg. `ocamlformat`.";
              default = [ ];
            };
        };

      headache =
        {
          header-file = mkOption {
            type = types.str;
            description = lib.mdDoc "Path to the header file.";
            default = ".header";
          };
        };

      lua-ls =
        {
          checklevel = mkOption {
            type = types.enum [ "Error" "Warning" "Information" "Hint" ];
            description = lib.mdDoc
              "The diagnostic check level";
            default = "Warning";
          };
          config = mkOption {
            type = types.attrs;
            description = lib.mdDoc
              "See https://github.com/LuaLS/lua-language-server/wiki/Configuration-File#luarcjson";
            default = { };
          };
        };

      credo = {
        strict =
          mkOption {
            type = types.bool;
            description = lib.mdDoc "Whether to auto-promote the changes.";
            default = true;
          };
      };

      vale = {
        config =
          mkOption {
            type = types.str;
            description = lib.mdDoc "Multiline-string configuration passed as config file.";
            default = "";
            example = ''
              MinAlertLevel = suggestion
              [*]
              BasedOnStyles = Vale
            '';
          };

        configPath =
          mkOption {
            type = types.str;
            description = lib.mdDoc "Path to the config file.";
            default = "";
          };

        flags =
          mkOption {
            type = types.str;
            description = lib.mdDoc "Flags passed to vale.";
            default = "";
          };
      };

      lychee = {
        configPath =
          mkOption {
            type = types.str;
            description = lib.mdDoc "Path to the config file.";
            default = "";
          };

        flags =
          mkOption {
            type = types.str;
            description = lib.mdDoc "Flags passed to lychee. See all available [here](https://lychee.cli.rs/#/usage/cli).";
            default = "";
          };
      };
    };

  config.hooks =
    {
      actionlint =
        {
          name = "actionlint";
          description = "Static checker for GitHub Actions workflow files.";
          files = "^.github/workflows/";
          types = [ "yaml" ];
          entry = "${tools.actionlint}/bin/actionlint";
        };
      ansible-lint =
        {
          name = "ansible-lint";
          description =
            "Ansible linter.";
          entry =
            let
              cmdArgs =
                mkCmdArgs [
                  [ (settings.ansible-lint.configPath != "") "-c ${settings.ansible-lint.configPath}" ]
                ];
            in
            "${tools.ansible-lint}/bin/ansible-lint ${cmdArgs}";
          files = if settings.ansible-lint.subdir != "" then "${settings.ansible-lint.subdir}/" else "";
        };
      black =
        {
          name = "black";
          description = "The uncompromising Python code formatter.";
          entry = "${pkgs.python3Packages.black}/bin/black";
          types = [ "file" "python" ];
        };
      ruff =
        {
          name = "ruff";
          description = " An extremely fast Python linter, written in Rust.";
          entry = "${pkgs.ruff}/bin/ruff --fix";
          types = [ "python" ];
        };
      cabal2nix =
        {
          name = "cabal2nix";
          description = "Run `cabal2nix` on all `*.cabal` files to generate corresponding `default.nix` files.";
          files = "\\.cabal$";
          entry = "${tools.cabal2nix-dir}/bin/cabal2nix-dir";
        };
      clang-format =
        {
          name = "clang-format";
          description = "Format your code using `clang-format`.";
          entry = "${tools.clang-tools}/bin/clang-format -style=file -i";
          # Source:
          # https://github.com/pre-commit/mirrors-clang-format/blob/46516e8f532c8f2d55e801c34a740ebb8036365c/.pre-commit-hooks.yaml
          types_or = [
            "c"
            "c++"
            "c#"
            "cuda"
            "java"
            "javascript"
            "json"
            "objective-c"
            "proto"
          ];
        };
      clang-tidy = {
        name = "clang-tidy";
        description = "Static analyzer for C++ code.";
        entry = "${tools.clang-tools}/bin/clang-tidy --fix";
        types = [ "c" "c++" "c#" "objective-c" ];
      };
      dhall-format = {
        name = "dhall-format";
        description = "Dhall code formatter.";
        entry = "${tools.dhall}/bin/dhall format";
        files = "\\.dhall$";
      };
      dune-opam-sync = {
        name = "dune/opam sync";
        description = "Check that Dune-generated OPAM files are in sync.";
        entry = "${tools.dune-build-opam-files}/bin/dune-build-opam-files";
        files = "(\\.opam$)|(\\.opam.template$)|((^|/)dune-project$)";
        ## We don't pass filenames because they can only be misleading. Indeed,
        ## we need to re-run `dune build` for every `*.opam` file, but also when
        ## the `dune-project` file has changed.
        pass_filenames = false;
      };
      gptcommit = {
        name = "gptcommit";
        description = "Generate a commit message using GPT3.";
        entry =
          let
            script = pkgs.writeShellScript "precommit-gptcomit" ''
              ${tools.gptcommit}/bin/gptcommit prepare-commit-msg --commit-source \
                "$PRE_COMMIT_COMMIT_MSG_SOURCE" --commit-msg-file "$1"
            '';
          in
          lib.throwIf (tools.gptcommit == null) "The version of Nixpkgs used by pre-commit-hooks.nix does not have the `gptcommit` package. Please use a more recent version of Nixpkgs."
            toString
            script;
        stages = [ "prepare-commit-msg" ];
      };
      hlint =
        {
          name = "hlint";
          description =
            "HLint gives suggestions on how to improve your source code.";
          entry = "${tools.hlint}/bin/hlint${if settings.hlint.hintFile == null then "" else " --hint=${settings.hlint.hintFile}"}";
          files = "\\.l?hs(-boot)?$";
        };
      hpack =
        {
          name = "hpack";
          description =
            "`hpack` converts package definitions in the hpack format (`package.yaml`) to Cabal files.";
          entry = "${tools.hpack-dir}/bin/hpack-dir --${if settings.hpack.silent then "silent" else "verbose"}";
          files = "(\\.l?hs(-boot)?$)|(\\.cabal$)|((^|/)package\\.yaml$)";
          # We don't pass filenames because they can only be misleading.
          # Indeed, we need to rerun `hpack` in every directory:
          # 1. In which there is a *.cabal file, or
          # 2. Below which there are haskell files, or
          # 3. In which there is a package.yaml that references haskell files
          #    that have been changed at arbitrary locations specified in that
          #    file.
          # In other words: We have no choice but to always run `hpack` on every `package.yaml` directory.
          pass_filenames = false;
        };
      isort =
        {
          name = "isort";
          description = "A Python utility / library to sort imports.";
          types = [ "file" "python" ];
          entry =
            let
              cmdArgs =
                mkCmdArgs
                  (with settings.isort; [
                    [ (profile != "") " --profile ${profile}" ]
                  ]);
            in
            "${pkgs.python3Packages.isort}/bin/isort${cmdArgs} ${settings.isort.flags}";
        };
      latexindent =
        {
          name = "latexindent";
          description = "Perl script to add indentation to LaTeX files.";
          types = [ "file" "tex" ];
          entry = "${tools.latexindent}/bin/latexindent ${settings.latexindent.flags}";
        };
      luacheck =
        {
          name = "luacheck";
          description = "A tool for linting and static analysis of Lua code.";
          types = [ "file" "lua" ];
          entry = "${tools.luacheck}/bin/luacheck";
        };
      lua-ls =
        let
          # .luarc.json has to be in a directory,
          # or lua-language-server will hang forever.
          luarc = pkgs.writeText ".luarc.json" (builtins.toJSON settings.lua-ls.config);
          luarc-dir = pkgs.stdenv.mkDerivation {
            name = "luarc";
            unpackPhase = "true";
            installPhase = ''
              mkdir $out
              cp ${luarc} $out/.luarc.json
            '';
          };
          script = pkgs.writeShellApplication {
            name = "lua-ls-lint";
            runtimeInputs = [ tools.lua-language-server ];
            checkPhase = ""; # The default checkPhase depends on GHC
            text = ''
              set -e
              export logpath="$(mktemp -d)"
              lua-language-server --check $(realpath .) \
                --checklevel="${settings.lua-ls.checklevel}" \
                --configpath="${luarc-dir}/.luarc.json" \
                --logpath="$logpath"
              if [[ -f $logpath/check.json ]]; then
                echo "+++++++++++++++ lua-language-server diagnostics +++++++++++++++"
                cat $logpath/check.json
                exit 1
              fi
            '';
          };
        in
        {
          name = "lua-ls";
          description = "Uses the lua-language-server CLI to statically type-check and lint Lua code.";
          entry = "${script}/bin/lua-ls-lint";
          files = "\\.lua$";
          pass_filenames = false;
        };
      ocp-indent =
        {
          name = "ocp-indent";
          description = "A tool to indent OCaml code.";
          entry = "${tools.ocp-indent}/bin/ocp-indent --inplace";
          files = "\\.mli?$";
        };
      opam-lint =
        {
          name = "opam lint";
          description = "OCaml package manager configuration checker.";
          entry = "${tools.opam}/bin/opam lint";
          files = "\\.opam$";
        };
      ormolu =
        {
          name = "ormolu";
          description = "Haskell code prettifier.";
          entry =
            let
              extensions =
                lib.escapeShellArgs (lib.concatMap (ext: [ "--ghc-opt" "-X${ext}" ]) settings.ormolu.defaultExtensions);
              cabalExtensions =
                if settings.ormolu.cabalDefaultExtensions then "--cabal-default-extensions" else "";
            in
            "${tools.ormolu}/bin/ormolu --mode inplace ${extensions} ${cabalExtensions}";
          files = "\\.l?hs(-boot)?$";
        };
      fourmolu =
        {
          name = "fourmolu";
          description = "Haskell code prettifier.";
          entry =
            "${tools.fourmolu}/bin/fourmolu --mode inplace ${
            lib.escapeShellArgs (lib.concatMap (ext: [ "--ghc-opt" "-X${ext}" ]) settings.ormolu.defaultExtensions)
            }";
          files = "\\.l?hs(-boot)?$";
        };
      hindent =
        {
          name = "hindent";
          description = "Haskell code prettifier.";
          entry = "${tools.hindent}/bin/hindent";
          files = "\\.l?hs(-boot)?$";
        };
      cabal-fmt =
        {
          name = "cabal-fmt";
          description = "Format Cabal files";
          entry = "${tools.cabal-fmt}/bin/cabal-fmt --inplace";
          files = "\\.cabal$";
        };
      chktex =
        {
          name = "chktex";
          description = "LaTeX semantic checker";
          types = [ "file" "tex" ];
          entry = "${tools.chktex}/bin/chktex";
        };
      stylish-haskell =
        {
          name = "stylish-haskell";
          description = "A simple Haskell code prettifier";
          entry = "${tools.stylish-haskell}/bin/stylish-haskell --inplace";
          files = "\\.l?hs(-boot)?$";
        };
      alejandra =
        {
          name = "alejandra";
          description = "The Uncompromising Nix Code Formatter.";
          entry =
            let
              cmdArgs =
                mkCmdArgs (with settings.alejandra; [
                  [ check "--check" ]
                  [ (exclude != [ ]) "--exclude ${lib.escapeShellArgs (lib.unique exclude)}" ]
                  [ (verbosity == "quiet") "-q" ]
                  [ (verbosity == "silent") "-qq" ]
                  [ (threads != null) "--threads ${toString threads}" ]
                ]);
            in
            "${settings.alejandra.package}/bin/alejandra ${cmdArgs}";
          files = "\\.nix$";
        };
      deadnix =
        {
          name = "deadnix";
          description = "Scan Nix files for dead code (unused variable bindings).";
          entry =
            let
              cmdArgs =
                mkCmdArgs (with settings.deadnix; [
                  [ noLambdaArg "--no-lambda-arg" ]
                  [ noLambdaPatternNames "--no-lambda-pattern-names" ]
                  [ noUnderscore "--no-underscore" ]
                  [ quiet "--quiet" ]
                  [ hidden "--hidden" ]
                  [ edit "--edit" ]
                  [ (exclude != [ ]) "--exclude ${lib.escapeShellArgs exclude}" ]
                ]);
            in
            "${tools.deadnix}/bin/deadnix ${cmdArgs} --fail";
          files = "\\.nix$";
        };
      flynt =
        {
          name = "flynt";
          description = "CLI tool to convert a python project's %-formatted strings to f-strings.";
          entry =
            let
              cmdArgs =
                mkCmdArgs (with settings.flynt; [
                  [ aggressive "--aggressive" ]
                  [ dry-run "--dry-run" ]
                  [ (exclude != [ ]) "--exclude ${lib.escapeShellArgs exclude}" ]
                  [ fail-on-change "--fail-on-change" ]
                  [ (line-length != null) "--line-length ${toString line-length}" ]
                  [ no-multiline "--no-multiline" ]
                  [ quiet "--quiet" ]
                  [ string "--string" ]
                  [ transform-concats "--transform-concats" ]
                  [ verbose "--verbose" ]
                ]);
            in
            "${settings.flynt.binPath} ${cmdArgs}";
          types = [ "python" ];
        };
      mdsh =
        let
          script = pkgs.writeShellScript "precommit-mdsh" ''
            for file in $(echo "$@"); do
                ${tools.mdsh}/bin/mdsh -i "$file"
            done
          '';
        in
        {
          name = "mdsh";
          description = "Markdown shell pre-processor.";
          entry = toString script;
          files = "\\.md$";
        };
      mypy =
        {
          name = "mypy";
          description = "Static type checker for Python";
          entry = settings.mypy.binPath;
          files = "\\.py$";
        };
      nil =
        {
          name = "nil";
          description = "Incremental analysis assistant for writing in Nix.";
          entry =
            let
              script = pkgs.writeShellScript "precommit-nil" ''
                errors=false
                echo Checking: $@
                for file in $(echo "$@"); do
                  ${tools.nil}/bin/nil diagnostics "$file"
                  exit_code=$?

                  if [[ $exit_code -ne 0 ]]; then
                    echo \"$file\" failed with exit code: $exit_code
                    errors=true
                  fi
                done
                if [[ $errors == true ]]; then
                  exit 1
                fi
              '';
            in
            builtins.toString script;
          files = "\\.nix$";
        };
      nixfmt =
        {
          name = "nixfmt";
          description = "Nix code prettifier.";
          entry = "${tools.nixfmt}/bin/nixfmt ${lib.optionalString (settings.nixfmt.width != null) "--width=${toString settings.nixfmt.width}"}";
          files = "\\.nix$";
        };
      nixpkgs-fmt =
        {
          name = "nixpkgs-fmt";
          description = "Nix code prettifier.";
          entry = "${tools.nixpkgs-fmt}/bin/nixpkgs-fmt";
          files = "\\.nix$";
        };
      nix-flake-lock =
        {
          name = "nix-flake-lock";
          description = "Check that flake.lock is up to date";
          types = [ "file" ];
          pass_filenames = false;
          files = "flake.*$";
          entry = lib.getExe (pkgs.writeShellApplication {
            name = "nix-flake-lock";
            text = ''
              echo "Checking that flake.lock is up to date"
              if ${lib.getExe pkgs.nix} --extra-experimental-features "nix-command flakes" flake lock --no-update-lock-file; then
                echo "flake.lock is up to date"
              else
                echo "flake.lock is not up to date. Run 'nix flake lock' to update it." 
                exit 1
              fi
            '';
          });
        };
      statix =
        {
          name = "statix";
          description = "Lints and suggestions for the Nix programming language.";
          entry = with settings.statix;
            "${tools.statix}/bin/statix check -o ${format} ${if (ignore != [ ]) then "-i ${lib.escapeShellArgs (lib.unique ignore)}" else ""}";
          files = "\\.nix$";
          pass_filenames = false;
        };
      elm-format =
        {
          name = "elm-format";
          description = "Format Elm files.";
          entry =
            "${tools.elm-format}/bin/elm-format --yes --elm-version=0.19";
          files = "\\.elm$";
        };
      elm-review =
        {
          name = "elm-review";
          description = "Analyzes Elm projects, to help find mistakes before your users find them.";
          entry = "${tools.elm-review}/bin/elm-review";
          files = "\\.elm$";
          pass_filenames = false;
        };
      elm-test =
        {
          name = "elm-test";
          description = "Run unit tests and fuzz tests for Elm code.";
          entry = "${tools.elm-test}/bin/elm-test";
          files = "\\.elm$";
          pass_filenames = false;
        };
      shellcheck =
        {
          name = "shellcheck";
          description = "Format shell files.";
          types = [ "shell" ];
          entry = "${tools.shellcheck}/bin/shellcheck";
        };
      bats =
        {
          name = "bats";
          description = "Run bash unit tests.";
          types = [ "shell" ];
          types_or = [ "bats" "bash" ];
          entry = "${tools.bats}/bin/bats -p";
        };
      stylua =
        {
          name = "stylua";
          description = "An Opinionated Lua Code Formatter.";
          types = [ "file" "lua" ];
          entry = "${tools.stylua}/bin/stylua";
        };
      shfmt =
        {
          name = "shfmt";
          description = "Format shell files.";
          types = [ "shell" ];
          entry = "${tools.shfmt}/bin/shfmt -w -s -l";
        };
      beautysh =
        {
          name = "beautysh";
          description = "Format shell files.";
          types = [ "shell" ];
          entry = "${tools.beautysh}/bin/beautysh";
        };
      terraform-format =
        {
          name = "terraform-format";
          description = "Format terraform (`.tf`) files.";
          entry = "${tools.terraform-fmt}/bin/terraform-fmt";
          files = "\\.tf$";
        };
      tflint =
        {
          name = "tflint";
          description = "A Pluggable Terraform Linter.";
          entry = "${tools.tflint}/bin/tflint";
          files = "\\.tf$";
        };
      yamllint =
        {
          name = "yamllint";
          description = "Yaml linter.";
          types = [ "file" "yaml" ];
          entry =
            let
              cmdArgs =
                mkCmdArgs [
                  [ (settings.yamllint.relaxed) "-d relaxed" ]
                  [ (settings.yamllint.configPath != "") "-c ${settings.yamllint.configPath}" ]
                ];
            in
            "${tools.yamllint}/bin/yamllint ${cmdArgs}";
        };
      rustfmt =
        let
          wrapper = pkgs.symlinkJoin {
            name = "rustfmt-wrapped";
            paths = [ tools.rustfmt ];
            nativeBuildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              wrapProgram $out/bin/cargo-fmt \
                --prefix PATH : ${lib.makeBinPath [ tools.cargo tools.rustfmt ]}
            '';
          };
        in
        {
          name = "rustfmt";
          description = "Format Rust code.";
          entry = "${wrapper}/bin/cargo-fmt fmt ${cargoManifestPathArg} -- --color always";
          files = "\\.rs$";
          pass_filenames = false;
        };
      clippy =
        let
          wrapper = pkgs.symlinkJoin {
            name = "clippy-wrapped";
            paths = [ tools.clippy ];
            nativeBuildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              wrapProgram $out/bin/cargo-clippy \
                --prefix PATH : ${lib.makeBinPath [ tools.cargo ]}
            '';
          };
        in
        {
          name = "clippy";
          description = "Lint Rust code.";
          entry = "${wrapper}/bin/cargo-clippy clippy ${cargoManifestPathArg} ${lib.optionalString settings.clippy.offline "--offline"} ${lib.optionalString settings.clippy.allFeatures "--all-features"} -- ${lib.optionalString settings.clippy.denyWarnings "-D warnings"}";
          files = "\\.rs$";
          pass_filenames = false;
        };
      cargo-check =
        {
          name = "cargo-check";
          description = "Check the cargo package for errors.";
          entry = "${tools.cargo}/bin/cargo check ${cargoManifestPathArg}";
          files = "\\.rs$";
          pass_filenames = false;
        };
      purty =
        {
          name = "purty";
          description = "Format purescript files.";
          entry = "${tools.purty}/bin/purty";
          files = "\\.purs$";
        };
      purs-tidy =
        {
          name = "purs-tidy";
          description = "Format purescript files.";
          entry = "${tools.purs-tidy}/bin/purs-tidy format-in-place";
          files = "\\.purs$";
        };

      prettier =
        {
          name = "prettier";
          description = "Opinionated multi-language code formatter.";
          entry = with settings.prettier;
            "${binPath} ${lib.optionalString write "--write"} ${lib.optionalString (output != null) "--${output}"} --ignore-unknown";
          types = [ "text" ];
        };
      pre-commit-hook-ensure-sops = {
        name = "pre-commit-hook-ensure-sops";
        entry =
          ## NOTE: pre-commit-hook-ensure-sops landed in nixpkgs on 8 July 2022. Once it reaches a
          ## release of NixOS, the `throwIf` piece of code below will become
          ## useless.
          lib.throwIf
            (tools.pre-commit-hook-ensure-sops == null)
            "The version of nixpkgs used by pre-commit-hooks.nix does not have the `pre-commit-hook-ensure-sops` package. Please use a more recent version of nixpkgs."
            ''
              ${tools.pre-commit-hook-ensure-sops}/bin/pre-commit-hook-ensure-sops
            '';
        files = lib.mkDefault "^secrets";
      };
      hunspell =
        {
          name = "hunspell";
          description = "Spell checker and morphological analyzer.";
          entry = "${tools.hunspell}/bin/hunspell -l";
          files = "\\.((txt)|(html)|(xml)|(md)|(rst)|(tex)|(odf)|\\d)$";
        };

      topiary =
        {
          name = "topiary";
          description = "A universal formatter engine within the Tree-sitter ecosystem, with support for many languages.";
          entry =
            ## NOTE: Topiary landed in nixpkgs on 2 Dec 2022. Once it reaches a
            ## release of NixOS, the `throwIf` piece of code below will become
            ## useless.
            lib.throwIf
              (tools.topiary == null)
              "The version of nixpkgs used by pre-commit-hooks.nix does not have the `topiary` package. Please use a more recent version of nixpkgs."
              (
                let
                  topiary-inplace = pkgs.writeShellApplication {
                    name = "topiary-inplace";
                    text = ''
                      for file; do
                        ${tools.topiary}/bin/topiary --in-place --input-file "$file"
                      done
                    '';
                  };
                in
                "${topiary-inplace}/bin/topiary-inplace"
              );
          files = "(\\.json$)|(\\.toml$)|(\\.mli?$)";
        };

      typos =
        {
          name = "typos";
          description = "Source code spell checker";
          entry =
            let
              configFile = builtins.toFile "config.toml" "${settings.typos.config}";
              cmdArgs =
                mkCmdArgs
                  (with settings.typos; [
                    [ (color != "") "--color ${color}" ]
                    [ (configPath != "") "--config ${configPath}" ]
                    [ (config != "" && configPath == "") "--config ${configFile}" ]
                    [ (exclude != "") "--exclude ${exclude}" ]
                    [ (format != "") "--format ${format}" ]
                    [ (locale != "") "--locale ${locale}" ]
                    [ (write && !diff) "--write-changes" ]
                  ]);
            in
            "${tools.typos}/bin/typos ${cmdArgs}${lib.optionalString settings.typos.diff " --diff"}${lib.optionalString settings.typos.hidden " --hidden"}";
          types = [ "text" ];
        };

      cspell =
        {
          name = "cspell";
          description = "A Spell Checker for Code";
          entry = "${tools.cspell}/bin/cspell";
        };

      html-tidy =
        {
          name = "html-tidy";
          description = "HTML linter.";
          entry = "${tools.html-tidy}/bin/tidy -quiet -errors";
          files = "\\.html$";
        };

      eslint =
        {
          name = "eslint";
          description = "Find and fix problems in your JavaScript code.";
          entry = "${settings.eslint.binPath} --fix";
          files = "${settings.eslint.extensions}";
        };

      eclint =
        {
          name = "eclint";
          description = "EditorConfig linter written in Go.";
          types = [ "file" ];
          entry =
            let
              cmdArgs =
                mkCmdArgs
                  (with settings.eclint; [
                    [ fix "-fix" ]
                    [ summary "-summary" ]
                    [ (color != "auto") "-color ${color}" ]
                    [ (exclude != [ ]) "-exclude ${lib.escapeShellArgs exclude}" ]
                    [ (verbosity != 0) "-verbosity ${toString verbosity}" ]
                  ]);
            in
            "${settings.eclint.package}/bin/eclint ${cmdArgs}";
        };

      rome =
        {
          name = "rome";
          description = "Unified developer tools for JavaScript, TypeScript, and the web";
          types_or = [ "javascript" "jsx" "ts" "tsx" "json" ];
          entry =
            let
              cmdArgs =
                mkCmdArgs [
                  [ (settings.rome.write) "--apply" ]
                  [ (settings.rome.configPath != "") "--config-path ${settings.rome.configPath}" ]
                ];
            in
            "${settings.rome.binPath} check ${cmdArgs}";
        };

      hadolint =
        {
          name = "hadolint";
          description = "Dockerfile linter, validate inline bash.";
          entry = "${tools.hadolint}/bin/hadolint";
          files = "Dockerfile$";
        };

      markdownlint =
        {
          name = "markdownlint";
          description = "Style checker and linter for markdown files.";
          entry = "${tools.markdownlint-cli}/bin/markdownlint -c ${pkgs.writeText "markdownlint.json" (builtins.toJSON settings.markdownlint.config)}";
          files = "\\.md$";
        };

      mdl =
        {
          name = "mdl";
          description = "A tool to check markdown files and flag style issues.";
          entry =
            let
              cmdArgs =
                mkCmdArgs
                  (with settings.mdl; [
                    [ (configPath != "") "--config ${configPath}" ]
                    [ git-recurse "--git-recurse" ]
                    [ ignore-front-matter "--ignore-front-matter" ]
                    [ json "--json" ]
                    [ (rules != [ ]) "--rules ${lib.strings.concatStringsSep "," rules}" ]
                    [ (rulesets != [ ]) "--rulesets ${lib.strings.concatStringsSep "," rulesets}" ]
                    [ show-aliases "--show-aliases" ]
                    [ warnings "--warnings" ]
                    [ skip-default-ruleset "--skip-default-ruleset" ]
                    [ (style != "") "--style ${style}" ]
                    [ (tags != [ ]) "--tags ${lib.strings.concatStringsSep "," tags}" ]
                    [ verbose "--verbose" ]
                  ]);
            in
            "${settings.mdl.package}/bin/mdl ${cmdArgs}";
          files = "\\.md$";
        };

      denolint =
        {
          name = "denolint";
          description = "Lint JavaScript/TypeScript source code.";
          types_or = [ "javascript" "jsx" "ts" "tsx" ];
          entry =
            let
              cmdArgs =
                mkCmdArgs [
                  [ (settings.denolint.format == "compact") "--compact" ]
                  [ (settings.denolint.format == "json") "--json" ]
                  [ (settings.denolint.configPath != "") "-c ${settings.denolint.configPath}" ]
                ];
            in
            "${tools.deno}/bin/deno lint ${cmdArgs}";
        };

      denofmt =
        {
          name = "denofmt";
          description = "Auto-format JavaScript, TypeScript, Markdown, and JSON files.";
          types_or = [ "javascript" "jsx" "ts" "tsx" "markdown" "json" ];
          entry =
            let
              cmdArgs =
                mkCmdArgs [
                  [ (!settings.denofmt.write) "--check" ]
                  [ (settings.denofmt.configPath != "") "-c ${settings.denofmt.configPath}" ]
                ];
            in
            "${tools.deno}/bin/deno fmt ${cmdArgs}";
        };

      govet =
        {
          name = "govet";
          description = "Checks correctness of Go programs.";
          entry =
            let
              # go vet requires package (directory) names as inputs.
              script = pkgs.writeShellScript "precommit-govet" ''
                set -e
                for dir in $(echo "$@" | xargs -n1 dirname | sort -u); do
                  ${tools.go}/bin/go vet ./"$dir"
                done
              '';
            in
            builtins.toString script;
          # to avoid multiple invocations of the same directory input, provide
          # all file names in a single run.
          require_serial = true;
          files = "\\.go$";
        };

      gotest = {
        name = "gotest";
        description = "Run go tests";
        entry =
          let
            script = pkgs.writeShellScript "precommit-gotest" ''
              set -e
              # find all directories that contain tests
              dirs=()
              for file in "$@"; do
                # either the file is a test
                if [[ "$file" = *_test.go ]]; then
                  dirs+=("$(dirname "$file")")
                  continue
                fi

                # or the file has an associated test
                filename="''${file%.go}"
                test_file="''${filename}_test.go"
                if [[ -f "$test_file"  ]]; then
                  dirs+=("$(dirname "$test_file")")
                  continue
                fi
              done

              # ensure we are not duplicating dir entries
              IFS=$'\n' sorted_dirs=($(sort -u <<<"''${dirs[*]}")); unset IFS

              # test each directory one by one
              for dir in "''${sorted_dirs[@]}"; do
                  ${tools.go}/bin/go test "./$dir"
              done
            '';
          in
          builtins.toString script;
        files = "\\.go$";
        # to avoid multiple invocations of the same directory input, provide
        # all file names in a single run.
        require_serial = true;
      };

      gofmt =
        {
          name = "gofmt";
          description = "A tool that automatically formats Go source code";
          entry =
            let
              script = pkgs.writeShellScript "precommit-gofmt" ''
                set -e
                failed=false
                for file in "$@"; do
                    # redirect stderr so that violations and summaries are properly interleaved.
                    if ! ${tools.go}/bin/gofmt -l -w "$file" 2>&1
                    then
                        failed=true
                    fi
                done
                if [[ $failed == "true" ]]; then
                    exit 1
                fi
              '';
            in
            builtins.toString script;
          files = "\\.go$";
        };

      revive =
        {
          name = "revive";
          description = "A linter for Go source code.";
          entry =
            let
              cmdArgs =
                mkCmdArgs [
                  [ true "-set_exit_status" ]
                  [ (settings.revive.configPath != "") "-config ${settings.revive.configPath}" ]
                ];
              # revive works with both files and directories; however some lints
              # may fail (e.g. package-comment) if they run on an individual file
              # rather than a package/directory scope; given this let's get the
              # directories from each individual file.
              script = pkgs.writeShellScript "precommit-revive" ''
                set -e
                for dir in $(echo "$@" | xargs -n1 dirname | sort -u); do
                  ${tools.revive}/bin/revive ${cmdArgs} ./"$dir"
                done
              '';
            in
            builtins.toString script;
          files = "\\.go$";
          # to avoid multiple invocations of the same directory input, provide
          # all file names in a single run.
          require_serial = true;
        };

      staticcheck =
        {
          name = "staticcheck";
          description = "State of the art linter for the Go programming language";
          # staticheck works with directories.
          entry =
            let
              script = pkgs.writeShellScript "precommit-staticcheck" ''
                err=0
                for dir in $(echo "$@" | xargs -n1 dirname | sort -u); do
                  ${tools.go-tools}/bin/staticcheck ./"$dir"
                  code="$?"
                  if [[ "$err" -eq 0 ]]; then
                     err="$code"
                  fi
                done
                exit $err
              '';
            in
            builtins.toString script;
          files = "\\.go$";
          # to avoid multiple invocations of the same directory input, provide
          # all file names in a single run.
          require_serial = true;
        };

      editorconfig-checker =
        {
          name = "editorconfig-checker";
          description = "Verify that the files are in harmony with the `.editorconfig`.";
          entry = "${tools.editorconfig-checker}/bin/editorconfig-checker";
          types = [ "file" ];
        };


      phpcs =
        {
          name = "phpcs";
          description = "Lint PHP files.";
          entry = with settings.phpcs;
            "${binPath}";
          types = [ "php" ];
        };

      phpcbf =
        {
          name = "phpcbf";
          description = "Lint PHP files.";
          entry = with settings.phpcbf;
            "${binPath}";
          types = [ "php" ];
        };

      phpstan =
        {
          name = "phpstan";
          description = "Static Analysis of PHP files.";
          entry = with settings.phpstan;
            "${binPath} analyse";
          types = [ "php" ];
        };

      php-cs-fixer =
        {
          name = "php-cs-fixer";
          description = "Lint PHP files.";
          entry = with settings.php-cs-fixer;
            "${binPath} fix";
          types = [ "php" ];
        };

      psalm =
        {
          name = "psalm";
          description = "Static Analysis of PHP files.";
          entry = with settings.psalm;
            "${binPath}";
          types = [ "php" ];
        };


      pylint =
        {
          name = "pylint";
          description = "Lint Python files.";
          entry = with settings.pylint;
            "${binPath} ${lib.optionalString reports "-ry"} ${lib.optionalString (! score) "-sn"}";
          types = [ "python" ];
        };

      pyupgrade =
        {
          name = "pyupgrade";
          description = "Automatically upgrade syntax for newer versions.";
          entry = with settings.pyupgrade;
            "${binPath}";
          types = [ "python" ];
        };

      pyright =
        {
          name = "pyright";
          description = "Static type checker for Python";
          entry = settings.pyright.binPath;
          files = "\\.py$";
        };

      flake8 =
        {
          name = "flake8";
          description = "Check the style and quality of Python files.";
          entry = "${settings.flake8.binPath} --format ${settings.flake8.format}";
          types = [ "python" ];
        };

      autoflake =
        {
          name = "autoflake";
          description = "Remove unused imports and variables from Python code.";
          entry = "${settings.autoflake.binPath} ${settings.autoflake.flags}";
          types = [ "python" ];
        };

      taplo =
        {
          name = "taplo";
          description = "Format TOML files with taplo fmt";
          entry = "${pkgs.taplo}/bin/taplo fmt";
          types = [ "toml" ];
        };

      zprint =
        {
          name = "zprint";
          description = "Beautifully format Clojure and Clojurescript source code and s-expressions.";
          entry = "${pkgs.zprint}/bin/zprint '{:search-config? true}' -w";
          types_or = [ "clojure" "clojurescript" "edn" ];
        };

      commitizen =
        {
          name = "commitizen check";
          description = ''
            Check whether the current commit message follows committing rules.
          '';
          entry = "${tools.commitizen}/bin/cz check --allow-abort --commit-msg-file";
          stages = [ "commit-msg" ];
        };

      tagref =
        {
          name = "tagref";
          description = ''
            Have tagref check all references and tags.
          '';
          entry = "${tools.tagref}/bin/tagref";
          types = [ "text" ];
          pass_filenames = false;
        };

      treefmt =
        {
          name = "treefmt";
          description = "One CLI to format the code tree.";
          types = [ "file" ];
          pass_filenames = true;
          entry = "${settings.treefmt.package}/bin/treefmt --fail-on-change";
        };

      mkdocs-linkcheck = {
        name = "mkdocs-linkcheck";
        description = "Validate links associated with markdown-based, statically generated websites.";
        entry =
          let
            cmdArgs =
              mkCmdArgs
                (with settings.mkdocs-linkcheck; [
                  [ local-only " --local" ]
                  [ recurse " --recurse" ]
                  [ (extension != "") " --ext ${extension}" ]
                  [ (method != "") " --method ${method}" ]
                  [ (path != "") " ${path}" ]
                ]);
          in
          "${settings.mkdocs-linkcheck.binPath}${cmdArgs}";
        types = [ "text" "markdown" ];
      };

      checkmake = {
        name = "checkmake";
        description = "Experimental linter/analyzer for Makefiles.";
        types = [ "makefile" ];
        entry =
          ## NOTE: `checkmake` 0.2.2 landed in nixpkgs on 12 April 2023. Once
          ## this gets into a NixOS release, the following code will be useless.
          lib.throwIf
            (tools.checkmake == null)
            "The version of nixpkgs used by pre-commit-hooks.nix must have `checkmake` in version at least 0.2.2 for it to work on non-Linux systems."
            "${tools.checkmake}/bin/checkmake";
      };

      fprettify = {
        name = "fprettify";
        description = "Auto-formatter for modern Fortran code.";
        types = [ "fortran " ];
        entry = "${tools.fprettify}/bin/fprettify";
      };

      dune-fmt = {
        name = "dune-fmt";
        description = "Runs Dune's formatters on the code tree.";
        entry =
          let
            auto-promote = if settings.dune-fmt.auto-promote then "--auto-promote" else "";
            run-dune-fmt = pkgs.writeShellApplication {
              name = "run-dune-fmt";
              runtimeInputs = settings.dune-fmt.extraRuntimeInputs;
              text = "${tools.dune-fmt}/bin/dune-fmt ${auto-promote}";
            };
          in
          "${run-dune-fmt}/bin/run-dune-fmt";
        pass_filenames = false;
      };

      headache =
        {
          name = "headache";
          description = "Lightweight tool for managing headers in source code files.";
          ## NOTE: Supported `files` are taken from
          ## https://github.com/Frama-C/headache/blob/master/config_builtin.txt
          files = "(\\.ml[ily]?$)|(\\.fmli?$)|(\\.[chy]$)|(\\.tex$)|(Makefile)|(README)|(LICENSE)";
          entry =
            ## NOTE: `headache` made into in nixpkgs on 12 April 2023. At the
            ## next NixOS release, the following code will become irrelevant.
            lib.throwIf
              (tools.headache == null)
              "The version of nixpkgs used by pre-commit-hooks.nix does not have `ocamlPackages.headache`. Please use a more recent version of nixpkgs."
              "${tools.headache}/bin/headache -h ${settings.headache.header-file}";
        };

      convco = {
        name = "convco";
        entry =
          let
            script = pkgs.writeShellScript "precommit-convco" ''
              cat $1 | ${pkgs.convco}/bin/convco check --from-stdin
            '';
            # need version >= 0.4.0 for the --from-stdin flag
            toolVersionCheck = lib.versionAtLeast tools.convco.version "0.4.0";
          in
          lib.throwIf (tools.convco == null || !toolVersionCheck) "The version of Nixpkgs used by pre-commit-hooks.nix does not have the `convco` package (>=0.4.0). Please use a more recent version of Nixpkgs."
            builtins.toString
            script;
        stages = [ "commit-msg" ];
      };

      mix-format = {
        name = "mix-format";
        description = "Runs the built-in Elixir syntax formatter";
        entry = "${pkgs.elixir}/bin/mix format";
        files = "\\.exs?$";
      };

      mix-test = {
        name = "mix-test";
        description = "Runs the built-in Elixir test framework";
        entry = "${pkgs.elixir}/bin/mix test";
        files = "\\.exs?$";
      };

      credo = {
        name = "credo";
        description = "Runs a static code analysis using Credo";
        entry =
          let strict = if settings.credo.strict then "--strict" else "";
          in "${pkgs.elixir}/bin/mix credo";
        files = "\\.exs?$";
      };

      vale = {
        name = "vale";
        description = "A markup-aware linter for prose built with speed and extensibility in mind.";
        entry =
          let
            configFile = builtins.toFile ".vale.ini" "${settings.vale.config}";
            cmdArgs =
              mkCmdArgs
                (with settings.vale; [
                  [ (configPath != "") " --config ${configPath}" ]
                  [ (config != "" && configPath == "") " --config ${configFile}" ]
                ]);
          in
          "${pkgs.vale}/bin/vale${cmdArgs} ${settings.vale.flags}";
        types = [ "text" ];
      };

      dialyzer = {
        name = "dialyzer";
        description = "Runs a static code analysis using Dialyzer";
        entry = "${pkgs.elixir}/bin/mix dialyzer";
        files = "\\.exs?$";
      };

      crystal = {
        name = "crystal";
        description = "A tool that automatically formats Crystal source code";
        entry = "${tools.crystal}/bin/crystal tool format";
        files = "\\.cr$";
      };

      lychee = {
        name = "lychee";
        description = "A fast, async, stream-based link checker that finds broken hyperlinks and mail adresses inside Markdown, HTML, reStructuredText, or any other text file or website.";
        entry =
          let
            cmdArgs =
              mkCmdArgs
                (with settings.lychee; [
                  [ (configPath != "") " --config ${configPath}" ]
                ]);
          in
          "${pkgs.lychee}/bin/lychee${cmdArgs} ${settings.lychee.flags}";
        types = [ "text" ];
      };

      annex = {
        name = "annex";
        description = "Runs the git-annex hook for large file support";
        entry = "${tools.git-annex}/bin/git-annex pre-commit";
      };

      golangci-lint = {
        name = "golangci-lint";
        description = "Fast linters runner for Go.";
        entry =
          let
            script = pkgs.writeShellScript "precommit-golangci-lint" ''
              set -e
              for dir in $(echo "$@" | xargs -n1 dirname | sort -u); do
                ${tools.golangci-lint}/bin/golangci-lint run ./"$dir"
              done
            '';
          in
          builtins.toString script;
        files = "\\.go$";
        # to avoid multiple invocations of the same directory input, provide
        # all file names in a single run.
        require_serial = true;
      };

      conform = {
        name = "conform enforce";
        description = "Policy enforcement for commits.";
        entry = "${tools.conform}/bin/conform enforce --commit-msg-file";
        stages = [ "commit-msg" ];
      };

      typstfmt = {
        name = "typstfmt";
        description = "format typst";
        entry = "${tools.typst-fmt}/bin/typst-fmt";
        files = "\\.typ$";
      };
    };
}
