# Nix DevSh

This is me toying with something a bit similar to [devshell](https://github.com/numtide/devshell) but a lot simpler. I would advise against using this, at least at the moment. I'm just experimenting really. If you're looking for something like this I would point you in the direction of already mentioned [devshell](https://github.com/numtide/devshell).

## Usage

This is meant to be used as a Nix flake input together with either a `devshell.nix` or a `devshell.toml` (or some combination for flexibility). It's very early still but I'm using this myself daily.

### flake.nix

`flake.nix`

```nix
## file: flake.nix
{
  description = "Flake using devSh";

  inputs.devsh.url = "github:johnae/devsh";

  outputs = { self, nixpkgs, nix-misc }:
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
            ## if you'd rather have the flexibility of nix:
            ## pkgs.callPackage ./devshell.nix {}

            ## TOML is likely easier for people unused to nix to digest (you can still customize this via nix):
            pkgs.devSh.loadTOML ./devshell.toml {} 

            ## for example, you can still customize TOML like this:
            # pkgs.devSh.loadTOML ./devshell.toml { packages = [ pkgs.special-package ]; } 
        );
    };
}
```


### devshell.toml

`devshell.toml`

```toml
name = "project-name-here"

intro = """
{bold}{green}Project Name{normal} is an awesome project.
You can read more about it here:

{bold}https://example.com{normal}
"""

[env]
MY_ENV_VAR = "test"

packages = [
  "terraform",
  "nodejs-14_x"
]
}
```


### devshell.nix

While the `devshell.toml` is probably enough for most projects, if the need arises TOML can be replaced completely using a `devshell.nix`:

`devshell.nix`

```nix
{ devSh, terraform, nodejs-14_x, writeShellScriptBin }:

let

  my-example-script = writeShellScriptBin "my-example-script" ''
    echo example-script
  '';

in

devSh.mkSh {
  name = "project-name-here";

  intro = ''
    {bold}{green}Project Name{normal} is an awesome project.
    You can read more about it here:
    
    {bold}https://example.com{normal}
  '';

  env = {
    MY_ENV_VAR = "test";
  };

  packages = [
    terraform
    nodejs-14_x
    my-example-script
  ];
}
```


### devshell.toml but extended with extra input

As mentioned when talking about `flake.nix` further up, in most situations it's possible to avoid replacing `devshell.toml` with a `devshell.nix` by using the extraAttrs input of `loadTOML` - like this:

`flake.nix`

```nix
{
  description = "Flake using devSh - extending devshell.toml";

  inputs.devsh.url = "github:johnae/devsh";

  outputs = { self, nixpkgs, nix-misc }:
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
            my-example-script = writeShellScriptBin "my-example-script" ''
              echo example-script
            '';
          in
            ## these inputs will be merged with whatever is already defined in the TOML
            pkgs.devSh.loadTOML ./devshell.toml { packages = [ my-example-script ]; } 
        );
    };
}
```

### Nix flake template

To initialize a new project, you may use the template from this repository like this:

```sh
nix flake new -t "github:johnae/devsh#devshell" my-new-project

## or existing folder
cd my-new-project
nix flake new -t "github:johnae/devsh#devshell" .
```
