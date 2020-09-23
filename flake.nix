{
  description = "Seamless integration of pre-commit git hooks with Nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs-channels/nixos-20.03";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  inputs.flake-compat = {
    url = "github:edolstra/flake-compat";
    flake = false;
  };

  inputs.cabal-fmt-src = {
    url = "github:phadej/cabal-fmt/master";
    flake = false;
  };

  inputs.gitignore-nix-src = {
    url = "github:hercules-ci/gitignore/master";
    flake = false;
  };

  inputs.hindent-src = {
    url = "github:chrisdone/hindent/master";
    flake = false;
  };

  outputs = { self, nixpkgs, flake-utils, flake-compat, cabal-fmt-src, gitignore-nix-src, hindent-src }:
    let
      module = { config, lib, pkgs, ... }: let
        inherit (lib)
          mkDefault
          ;
        inherit (import gitignore-nix-src { inherit lib; })
          gitignoreSource
          ;
      in
        {
          imports = [ ./modules/all-modules.nix ];

          config = {
            pre-commit.tools = mkDefault ((pkgs.callPackage ./nix { inherit hindent-src cabal-fmt-src; }).callPackage ./nix/tools.nix {});
            pre-commit.rootSrc = mkDefault (gitignoreSource config.root);
          };
        };
    in
      flake-utils.lib.eachDefaultSystem
        (
          system:
            let
              pkgs = import ./nix {
                inherit nixpkgs hindent-src cabal-fmt-src system;
                pre-commit-hooks-module = module;
              };
              pre-commit-check = pkgs.packages.run {
                src = ./.;
                hooks = {
                  shellcheck.enable = true;
                  nixpkgs-fmt.enable = true;
                };
                excludes = [
                  # autogenerated by nix flake update
                  "flake.lock$"
                ];
              };
            in

              {
                packages = pkgs.packages;

                projectModules.pre-commit-hooks = module;

                inherit pre-commit-check;

                devShell =
                  pkgs.mkShell {
                    inherit (pre-commit-check) shellHook;
                  };
              }
        );
}
