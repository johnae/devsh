## The template this flake was based on can be found here:
## https://github.com/johnae/devsh/templates/devshell

{
  description = "Flake using devSh";

  inputs.devsh.url = "github:johnae/devsh";

  outputs = { self, nixpkgs, devsh }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      devShell = forAllSystems
        (system:
          let
            pkgs = import nixpkgs {
              inherit system;
              overlays = [ devsh.overlay ];
            };
          in
            ## TOML is easiest for people unused to nix to digest - I'd recommend using TOML:
            pkgs.devSh.loadTOML ./devshell.toml { }

            ## if you'd rather have the flexibility of nix:
            ## pkgs.callPackage ./devshell.nix {}

            ## But I'd recommend that you instead customize TOML like this:
            # pkgs.devSh.loadTOML ./devshell.toml { packages = [ pkgs.special-package ]; }
        );
    };
}
