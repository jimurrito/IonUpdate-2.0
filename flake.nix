{
  description = "IonUpdate PowerShell Service";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    test-vm = {
      url = "github:jimurrito/nixos-test-vm";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # can not use espresso as it will cause a recursive error for users who use this app via espresso
    qpwsh = {
      url = "git+https://forgejo.immerhouse.com/jimurrito/quiet-powershell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  #
  outputs =
    {
      self,
      nixpkgs,
      test-vm,
      qpwsh,
    }:
    let
      #
      lib = nixpkgs.lib;
      # Supported Architectures
      archs = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      # multi arch packager
      packager = sys: {
        ${sys}.default =
          let
            pkgs = import nixpkgs {
              system = sys;
              overlays = [ qpwsh.overlays.default ];
            };
          in
          with lib;
          pkgs.stdenv.mkDerivation {
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
              ${getExe pkgs.quietPowershell} -NonInteractive -NoLogo -NoProfile -Command "$moduleDir/IonUpdate.ps1 \$@"
              EOF
              chmod +x "$out/bin/ion-update"
            '';
          };
      };
      #
    in
    {
      #
      # Builds packages for each arch provided
      # (') is required so foldl will be strict and not lazy
      packages = builtins.foldl' (acc: x: acc // x) { } (map packager archs);
      #
      # Nixpkgs overlay for the package(s)
      overlays.default = final: prev: {
        ion-update = self.packages.${final.system}.default;
      };
      #
      # Default option to import package into the env
      # and import service options
      nixosModules.default =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          ion-nixops = config.services.ion-update;
        in
        with lib;
        {
          # Options for services overlay
          options.services.ion-update = {
            enable = mkEnableOption "IonUpdate scheduled service";
            keyPath = mkOption {
              type = types.str;
              default = "/root/ionos-key";
              description = "Path to the public and private key provided by IONOS. Should be in '<PublicKey>.<Secret>' format.";
            };
            records = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "List of DNS records that need tracking";
            };
            interval = mkOption {
              type = types.str;
              default = "daily";
              description = "How often to run IonUpdate. Accepts any systemd calendar expression.";
            };
          };
          #
          # config to be implemented via the `options`
          config = mkIf ion-nixops.enable {
            # Imports the overlay to put sonarr-cleanup in pkgs
            nixpkgs.overlays = [ self.overlays.default ];
            # rootless identity
            # Requires home dir and needs an interactive shell
            # If we can port `ionmod` module to a derivation, this can go back to `isSystemUser = true;`
            # tested again on 5/17. Old me was not bluffing. issue with install-module use.
            users = {
              groups.ion-update = { };
              users.ion-update = {
                enable = true;
                group = "ion-update";
                # isSystemUser = true;
                isNormalUser = true;
                linger = true;
                createHome = true;
                home = "/var/ion-update";
              };
            };
            # systemd service
            systemd = {
              services.ion-update = {
                description = "IonUpdate service";
                serviceConfig = with lib; {
                  Type = "oneshot";
                  User = "ion-update";
                  Group = "ion-update";
                  ExecStart = ''
                    ${getExe pkgs.ion-update} -Create -KeyPath ${ion-nixops.keyPath} -Records "('${concatStringsSep "', '" ion-nixops.records}')"
                  '';
                };
              };
              # timer for service triggering
              timers.ion-update = {
                description = "IonUpdate timer";
                wantedBy = [ "timers.target" ];
                timerConfig = {
                  OnCalendar = ion-nixops.interval;
                  Persistent = true;
                };
              };
            };
          };
        };
      #
      #
      # TestVM
      nixosConfigurations =
        let
          testConfig =
            { ... }:
            {
              services.ion-update = {
                enable = true;
                keyPath = "/etc/ionos-key";
                records = [
                  "*.immerhouse.com"
                ];
                interval = "daily";
              };
            };
        in
        {
          test-vm = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              test-vm.baselineConfig
              # test config
              self.nixosModules.default
              testConfig
            ];
          };
        };
      #
    };
}
