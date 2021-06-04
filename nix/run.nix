builtinStuff@{ pkgs, tools, isFlakes, pre-commit, git, runCommand, writeText, writeScript, lib, gitignore-nix-src }:

{ src
, hooks ? { }
, excludes ? [ ]
, tools ? { }
, settings ? { }
, default_stages ? [ "commit" ]
}:
let
  project =
    lib.evalModules {
      modules =
        [
          ../modules/all-modules.nix
          {
            config =
              {
                _module.args.pkgs = pkgs;
                _module.args.gitignore-nix-src = gitignore-nix-src;
                inherit hooks excludes settings default_stages;
                tools = builtinStuff.tools // tools;
                package = pre-commit;
              } // (if isFlakes
              then { rootSrc = src; }
              else {
                rootSrc = (import gitignore-nix-src { inherit (pkgs) lib; }).gitignoreSource src;
              });
          }
        ];
    };
  inherit (project.config) installationScript;

in
project.config.run // {
  shellHook = installationScript;
}
