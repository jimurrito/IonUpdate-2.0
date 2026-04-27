{
  description = "IonUpdate PowerShell Script+Module";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, lib }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      packages.${system}.default = pkgs.stdenv.mkDerivation {
        pname = "IonUpdate";
        version = "0.1.0";
        src = ./.;
        dontBuild = true;

        installPhase = ''
          moduleDir="$out/module"
          mkdir -p "$moduleDir"
          cp IonUpdate.ps1 IonUpdate.psd1 IonUpdate.psm1 "$moduleDir/"

          mkdir -p "$out/bin"
          cat > "$out/bin/ion-update" << EOF
          #!/usr/bin/env bash
          export PSModulePath="$moduleDir:\$PSModulePath"
          ${lib.getExe pkgs.powershell} -NonInteractive -Command "./IonUpdate.ps1 \$@"
          EOF
          chmod +x "$out/bin/ion-update"
        '';
      };
    };
}
