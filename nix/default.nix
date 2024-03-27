{ system ? builtins.currentSystem
, nixpkgs
, gitignore-nix-src
, isFlakes ? false
}:
let
  overlay =
    self: pkgs:
    let
      tools = import ./call-tools.nix pkgs;
      run = pkgs.callPackage ./run.nix { inherit pkgs tools isFlakes gitignore-nix-src; };
    in
    {
      inherit tools run;
      # Flake style attributes
      packages = tools // {
        inherit (pkgs) pre-commit;
      };
      checks = self.packages // {
        # A pre-commit-check for nix-pre-commit itself
        pre-commit-check = run {
          src = ../.;
          hooks = {
            shellcheck.enable = true;
            nixpkgs-fmt.enable = true;
            typos.enable = true;
          };
        };
        all-tools-eval =
          let
            config = pkgs.lib.evalModules {
              modules = [
                ../modules/all-modules.nix
                {
                  inherit tools;
                }
              ];
              specialArgs = { inherit pkgs; };
            };
            allHooks = config.config.hooks;
            allEntryPoints = pkgs.lib.mapAttrsToList (_: v: v.entry) allHooks;
          in
          pkgs.runCommand "all-tools-eval"
            {
              inherit allEntryPoints;
            } ''
            touch $out
          '';
        doc-check =
          let
            inherit (pkgs) lib;
            # We might add that it keeps rendering fast and robust,
            # and we want to teach `defaultText` which is more broadly applicable,
            # but the message is long enough.
            failPkgAttr = name: _v:
              throw ''
                While generating documentation, we found that `pkgs` was used. To avoid rendering store paths in the documentation, this is forbidden.

                Usually when this happens, you need to add `defaultText` to an option declaration, or escape an example with `lib.literalExpression`.

                The `pkgs` attribute that was accessed is

                    pkgs.${lib.strings.escapeNixIdentifier name}

                If necessary, you can also find the offending option by evaluating with `--show-trace` and then look for occurrences of `option`.
              '';
            pkgsStub = lib.mapAttrs failPkgAttr pkgs;
            configuration = pkgs.lib.evalModules {
              modules = [
                ../modules/all-modules.nix
                {
                  _file = "doc-check";
                  config = {
                    _module.args.pkgs = pkgsStub // {
                      _type = "pkgs";
                      inherit lib;
                      formats = lib.mapAttrs
                        (formatName: formatFn:
                          formatArgs:
                          let
                            result = formatFn formatArgs;
                            stubs =
                              lib.mapAttrs
                                (name: _:
                                  throw "The attribute `(pkgs.formats.${lib.strings.escapeNixIdentifier formatName} x).${lib.strings.escapeNixIdentifier name}` is not supported during documentation generation. Please check with `--show-trace` to see which option leads to this `${lib.strings.escapeNixIdentifier name}` reference. Often it can be cut short with a `defaultText` argument to `lib.mkOption`, or by escaping an option `example` using `lib.literalExpression`."
                                )
                                result;
                          in
                          stubs // {
                            inherit (result) type;
                          }
                        )
                        pkgs.formats;
                    };
                  };
                }
              ];
            };
            doc = pkgs.nixosOptionsDoc {
              inherit (configuration) options;
            };
          in
          doc.optionsCommonMark;
      };
    };
in
import nixpkgs {
  overlays = [ overlay ];
  # broken is needed for hindent to build
  config = { allowBroken = true; };
  inherit system;
}
