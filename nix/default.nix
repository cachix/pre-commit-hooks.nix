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
            # `types_or = [ ... something ... ]` doesn't pick up our .sh file
            shellcheck.types_or = nixpkgs.lib.mkForce [ ];

            nixpkgs-fmt.enable = true;
          };
        };
      };
    };
in
import nixpkgs {
  overlays = [ overlay ];
  # broken is needed for hindent to build
  config = { allowBroken = true; };
  inherit system;
}
