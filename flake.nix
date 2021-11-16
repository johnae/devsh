{
  description = "Nix Devshell";

  inputs = {
    nixlib.url = "github:nix-community/nixpkgs.lib";
  };

  outputs = { nixlib, ... }:
    {
      templates = {
        devshell = {
          path = ./templates/devshell;
          description = "A flake for dev shells configured using TOML";
        };
      };

      overlay = (final: prev:
        let
          inherit (builtins) mapAttrs removeAttrs fromTOML readFile concatStringsSep hasAttr replaceStrings attrNames attrValues isAttrs;
          inherit (nixlib.lib) hasAttrByPath attrByPath makeBinPath splitString recursiveUpdate;
          inherit (prev) writeTextFile writeShellScript writeShellScriptBin;

          bashBin = "${prev.bashInteractive}/bin";
          bashPath = "${bashBin}/bash";
          ansiEsc = code: "[${toString code}m";

          shEscSeq = {
            ## foreground colors
            black = ansiEsc 30;
            red = ansiEsc 31;
            green = ansiEsc 32;
            yellow = ansiEsc 33;
            blue = ansiEsc 34;
            magenta = ansiEsc 35;
            cyan = ansiEsc 36;
            white = ansiEsc 37;
            bright_black = ansiEsc 90;
            bright_red = ansiEsc 91;
            bright_green = ansiEsc 92;
            bright_yellow = ansiEsc 93;
            bright_blue = ansiEsc 94;
            bright_magenta = ansiEsc 95;
            bright_cyan = ansiEsc 96;
            bright_white = ansiEsc 97;

            ## background colors
            black_bg = ansiEsc 40;
            red_bg = ansiEsc 41;
            green_bg = ansiEsc 42;
            yellow_bg = ansiEsc 43;
            blue_bg = ansiEsc 44;
            magenta_bg = ansiEsc 45;
            cyan_bg = ansiEsc 46;
            white_bg = ansiEsc 47;
            bright_black_bg = ansiEsc 100;
            bright_red_bg = ansiEsc 101;
            bright_green_bg = ansiEsc 102;
            bright_yellow_bg = ansiEsc 103;
            bright_blue_bg = ansiEsc 104;
            bright_magenta_bg = ansiEsc 105;
            bright_cyan_bg = ansiEsc 106;
            bright_white_bg = ansiEsc 107;

            ## etc
            normal = ansiEsc 0;
            reset = ansiEsc 0;
            bold = ansiEsc 1;
            faint = ansiEsc 2;
            dim = ansiEsc 2;
            italic = ansiEsc 3;
            underline = ansiEsc 4;
            slow_blink = ansiEsc 5;
            rapid_blink = ansiEsc 6;
          };

          toShellStr = replaceStrings (map
              (key: "{${key}}")
              (attrNames shEscSeq)
            ) (map
              (esc: "${esc}")
              (attrValues shEscSeq)
            );

          stdenv = writeTextFile {
            name = "devsh-stdenv";
            destination = "/setup";
            text = ''
              : ''${outputs:=out}
              runHook() {
                eval "$shellHook"
                unset runHook
              }
            '';
          };

          pkgsAvailable = packages:
            ''

            {italic}Packages now available in PATH:{normal}

            ''
            +
            concatStringsSep "\n"
              (map (pkg: "  {bold}{white}${pkg.name}{normal}") packages);

          toIntroCmd = intro: writeShellScriptBin "intro" ''
            cat<<INTRO

            ${toShellStr intro}

            INTRO
          '';

          mkSh =
            { name
            , intro ? ''Welcome to {bold}{green}DevSH{normal}''
            , packages ? [ ]
            , meta ? { }
            , passthru ? { }
            , env ? { }
            , ...
            }@attrs:
            let

              extraAttrs = removeAttrs attrs [ "name" "intro" "packages" "meta" "passthru" "env" ];
              introCmd = toIntroCmd (intro + (pkgsAvailable packages));
              shellHook = writeShellScript "${name}-hook" ''
                ${introCmd}/bin/intro
              '';
            in
            (derivation ({
              inherit name;
              inherit (prev) system;
              builder = bashPath;
              PATH = "${bashBin}:${makeBinPath ([ introCmd ] ++ packages)}";
              stdenv = stdenv;
              inherit shellHook;
            } // extraAttrs // env)) // { inherit meta passthru; } // passthru;

          tomlAttrsToSh = mapAttrs (name: value:
              if name == "packages" then
                map (pkg:
                  let
                    pkgName = if isAttrs pkg then pkg.name else pkg;
                    pkgPath = splitString "." pkgName;
                  in
                  if hasAttrByPath pkgPath prev then
                    attrByPath pkgPath null prev
                  else abort ''

                    No such package "${pkgName}".
                    Please use `nix search nixpkgs pkg-name-here` to find packages.
                  ''
                ) value
              else value
            );

          loadTOML = path: {...}@extraAttrs:
            let
              tomlSh = tomlAttrsToSh (fromTOML (readFile path));
              tomlPackages = if hasAttr "packages" tomlSh then tomlSh.packages else [];
              extraPackages = if hasAttr "packages" extraAttrs then extraAttrs.packages else [];
              toml = removeAttrs tomlSh [ "packages" ];
              extra = removeAttrs extraAttrs [ "packages" ];
              packages = tomlPackages ++ extraPackages;
            in
              mkSh ((recursiveUpdate toml extra) // { inherit packages; });

          devsh = {
            inherit ansiEsc mkSh loadTOML;
          };

        in
          {
            inherit devsh;
            devSh = devsh;
          }
      );
    };
}
