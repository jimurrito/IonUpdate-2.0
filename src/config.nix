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
  #
  # config to be implemented via the `options`
  config = mkIf ion-nixops.enable {   
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
}
