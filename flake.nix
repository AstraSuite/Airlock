{
  description = "A clean M3 Quickshell frontend for greetd";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    m3shapes = {
      url = "github:soramanew/m3shapes/bdc327b29f95394a732baf3c9b19658ba23755b6";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    forAllSystems = fn:
      nixpkgs.lib.genAttrs nixpkgs.lib.platforms.linux (
        system: fn nixpkgs.legacyPackages.${system}
      );
  in {
    formatter = forAllSystems (pkgs: pkgs.alejandra);

    packages = forAllSystems (pkgs: rec {
      astra-airlock = pkgs.callPackage ./nix {
        inherit (inputs) m3shapes;
        quickshell = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
      };
      default = astra-airlock;
    });

    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        packages = with pkgs; [
          cmake
          ninja
          pkg-config
          qt6.qtbase
          qt6.qtdeclarative
          qt6.qtquick3d
          cage
          greetd.greetd
        ];
      };
    });

    nixosModules.default = { config, lib, pkgs, ... }:
      with lib;
      let
        cfg = config.services.greetd.astraAirlock;
      in {
        options.services.greetd.astraAirlock = {
          enable = mkEnableOption "Airlock display manager frontend";
          package = mkOption {
            type = types.package;
            default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
            description = "The astra-airlock package to use.";
          };
          compositor = mkOption {
            type = types.enum [ "cage" "hyprland" ];
            default = "cage";
            description = "The Wayland compositor to run the greeter in.";
          };
        };

        config = mkIf cfg.enable {
          services.greetd = {
            enable = true;
            settings = {
              default_session = {
                command = if cfg.compositor == "cage" then
                  "${pkgs.cage}/bin/cage -s -- ${cfg.package}/bin/astra-airlock >/dev/null 2>&1"
                else
                  "${pkgs.hyprland}/bin/Hyprland >/dev/null 2>&1";
                user = "greeter";
              };
            };
          };

          systemd.tmpfiles.rules = [
            "d /var/cache/astra-airlock 0755 greeter greeter -"
          ];
        };
      };
  };
}
