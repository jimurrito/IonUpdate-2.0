# IONUpdate v2.0
A script to keep IONOS DNS A Records up to date. Uses the [IonMod](https://github.com/jimurrito/IonMod) library to handle communications with IONOS.

> **Please note** that PublicPrefix and Secret will need to be generated from IONOS. [Follow this link for more.](https://developer.hosting.ionos.com/docs/getstarted) Any script errors regarding unauthorized requests need to be handled by IONOS support.

---

## Table of Contents
- [Examples](#examples)
- [Parameters](#parameters)
- [Nix](#nix)

---

## Examples

### Update a single record with your current Public IP
```powershell
./IonUpdate.ps1 -PublicPrefix XXXXX -Secret XXXXX -Records 'name.domain.com'
```

### Update a single record with a custom IP address
```powershell
./IonUpdate.ps1 -PublicPrefix XXXXX -Secret XXXXX -Records 'name.domain.com' -IP '1.1.1.1'
```
When `-IP` is not provided, the script will pull your current public IP via `https://ifconfig.me`.

### Authenticate using a key file
```powershell
./IonUpdate.ps1 -KeyPath './ion.key' -Records 'name.domain.com'
```
The key file should contain the credentials in the format `PublicPrefix.Secret` on a single line. This is a convenient alternative to passing `-PublicPrefix` and `-Secret` directly.

### Update multiple DNS records
```powershell
./IonUpdate.ps1 -PublicPrefix XXXXX -Secret XXXXX -Records ("name.domain.com","foobar.domain.com")
```
Due to a PowerShell limitation, arrays must be specified with parentheses `()`. Brackets `[]` will cause errors when PowerShell tries to coerce the list.

### Update and create missing DNS records
```powershell
./IonUpdate.ps1 -PublicPrefix XXXXX -Secret XXXXX -Records ("name.domain.com","foobar.domain.com") -Create
```
The parameter `-Create` will create any records that do not exist in the DNS registry.

> Please note this script will not manage the lifecycle of newly created records. If a subsequent run does not include a previously created record like `foobar.domain.com`, that record will remain as-is.

Custom IP addresses can be used with any number of DNS records and with any authentication method.

---

## Parameters

### `-Records`
The DNS A records that will be updated.
> Accepts either a single name `name.domain.com` or an array `("name.domain.com","foobar.domain.com")`. The use of brackets to declare the array is not supported by PowerShell.

### `-PublicPrefix`
The public prefix provided by IONOS as part of an API credential. Must be used together with `-Secret`.

### `-Secret`
The secret provided by IONOS as part of an API credential. Must be used together with `-PublicPrefix`.

### `-KeyPath`
Path to a key file containing IONOS credentials in the format `PublicPrefix.Secret`. Use this as an alternative to providing `-PublicPrefix` and `-Secret` directly.

> The script requires either `-KeyPath` **or** both `-PublicPrefix` and `-Secret`. If neither is provided, the script will exit with an error.

### `-IP`
A custom IP address to assign to all provided DNS records. If omitted, the script will use your current public IP.

### `-Create`
When provided, the script will create any DNS record(s) that do not already exist in IONOS.

---

## Nix

IonUpdate ships a Nix flake with three outputs: a package, a bare package module, and a full NixOS service module.

### Running directly
You can run IonUpdate without installing it using `nix run`:
```bash
nix run github:jimurrito/ionupdate -- -KeyPath '/root/ionos-key' -Records 'name.domain.com'
```
Any arguments after `--` are passed through to the script.

### Installing the package
To add the package to your system without the managed service, use `nixosModules.package` in your NixOS configuration:
```nix
{
  inputs.ionupdate.url = "github:jimurrito/ionupdate";

  outputs = { nixpkgs, ionupdate, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        ionupdate.nixosModules.package
      ];
    };
  };
}
```
This adds `ion-update` to `environment.systemPackages`, making it available on the PATH.

### Using the NixOS service module
`nixosModules.default` provides a managed systemd timer that runs IonUpdate on a schedule. Add the module to your configuration and enable the service:
```nix
{
  inputs.ionupdate.url = "github:jimurrito/ionupdate";

  outputs = { nixpkgs, ionupdate, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        ionupdate.nixosModules.default
        {
          services.ion-update = {
            enable = true;
            keyPath = "/root/ionos-key";
            records = [ "name.domain.com" "foobar.domain.com" ];
            interval = "daily";
          };
        }
      ];
    };
  };
}
```

### Service module options

| Option | Type | Default | Description |
|---|---|---|---|
| `enable` | bool | `false` | Enables the IonUpdate scheduled service. |
| `keyPath` | string | `"/root/ionos-key"` | Path to the IONOS key file in `PublicPrefix.Secret` format. |
| `records` | list of strings | `[]` | DNS A records to track and update. |
| `interval` | string | `"daily"` | How often to run. Accepts any [systemd calendar expression](https://www.freedesktop.org/software/systemd/man/latest/systemd.time.html). |

### Notes
- The service runs as a dedicated `ion-update` user and group under `/var/ion-update`. A normal user account (rather than a system user) is required because the IonMod PowerShell module needs an interactive shell environment to install and run correctly.
- The `-Create` flag is always passed by the service, so any records listed in `records` that don't exist in IONOS will be created automatically on the first run.
- The timer uses `Persistent = true`, meaning if the system was offline when a run was scheduled, it will execute on the next boot.