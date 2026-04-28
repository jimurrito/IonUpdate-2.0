{
  description = "IonUpdate PowerShell Service";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  #
  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      lib = nixpkgs.lib;
    in
    {
      packages.${system}.package = pkgs.stdenv.mkDerivation {
        pname = "IonUpdate";
        meta.mainProgram = "ion-update";
        version = "0.1.0";
        src = ./.;
        dontBuild = true;
        #
        installPhase = ''
          moduleDir="$out/module"
          mkdir -p "$moduleDir"
          cp IonUpdate.ps1 IonUpdate.psd1 IonUpdate.psm1 "$moduleDir/"
          mkdir -p "$out/bin"
          cat > "$out/bin/ion-update" << EOF
          #!/usr/bin/env bash
          export PSModulePath="$moduleDir:\$PSModulePath"
          ${lib.getExe pkgs.powershell} -NonInteractive -Command "$moduleDir/IonUpdate.ps1 \$@"
          EOF
          chmod +x "$out/bin/ion-update"
        '';
      };
      #
      #
      nixosModules.default =
        {
          pkgs,
          ...
        }:
        let
          pkgsystem = pkgs.stdenv.hostPlatform.system;
          mainpackage = self.packages.${pkgsystem}.package;
        in
        {
          config.environment.systemPackages = [
            mainpackage
          ];
        };
      #
      #
      nixosModules.service =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          pkgsystem = pkgs.stdenv.hostPlatform.system;
          mainpackage = self.packages.${pkgsystem}.package;
          ion-nixops = config.services.ion-update;
        in
        {
          # Options for services overlay
          options.services.ion-update = with lib; {
            enable = mkEnableOption "IonUpdate scheduled service";
            keyPath = mkOption {
              type = types.str;
              default = "/root/ionos-key";
              description = "Path to the public and private key provided by IONOS. Should be in '<PublicKey>.<Secret>' format.";
            };
            dnsNames = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "List of DNS names that need tracking";
            };
            interval = mkOption {
              type = types.str;
              default = "daily";
              description = "How often to run IonUpdate. Accepts any systemd calendar expression.";
            };
          };
          #
          # config to be implemented via the `options`
          config =
            lib.mkIf ion-nixops.enable {
              # rootless identity
              users = {
                groups.ion-update = { };
                users.ion-update = {
                  enable = true;
                  group = "ion-update";
                  isSystemUser = true;
                };
              };
              # systemd service
              systemd = {
                services.ion-update = {
                  description = "IonUpdate service";
                  serviceConfig = {
                    Type = "oneshot";
                    User = "ion-update";
                    Group = "ion-update";
                    ExecStart = "${lib.getExe mainpackage} -KeyPath ${ion-nixops.keyPath}";
                  };
                };
                timers.ion-update = {
                  description = "IonUpdate timer";
                  wantedBy = [ "timers.target" ];
                  timerConfig = {
                    OnCalendar = ion-nixops.interval;
                    Persistent = true;
                  };
                };
              };
            }
            // {
              # Imports package and runs the install steps
              environment.systemPackages = [
                mainpackage
              ];
            };
        };
    };
}
