{ lib, ... }:
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
}
