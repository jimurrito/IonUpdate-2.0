# IonUpdate v2.0

![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?logo=powershell&logoColor=white)
![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)

Keeps IONOS DNS A records up to date with your current public IP (or a custom IP). Uses the [IonMod](https://github.com/jimurrito/IonMod) PowerShell module to communicate with the IONOS DNS API.

> API credentials must be generated from IONOS. [Follow this link for more.](https://developer.hosting.ionos.com/docs/getstarted) Any errors regarding unauthorized requests must be resolved through IONOS support.

---

## Table of Contents

- [Requirements](#requirements)
- [Usage](#usage)
- [Examples](#examples)
- [Parameters](#parameters)
- [Nix](#nix)
- [License](#license)

---

## Requirements

- PowerShell 7+
- [IonMod](https://github.com/jimurrito/IonMod) — installed automatically by the script on first run
- IONOS API credentials (`PublicPrefix` and `Secret`) — [generate here](https://developer.hosting.ionos.com/docs/getstarted)

---

## Usage

```powershell
./IonUpdate.ps1 -PublicPrefix <PublicPrefix> -Secret <Secret> -Records '<record>'
```

Or using a key file:

```powershell
./IonUpdate.ps1 -KeyPath '<path-to-key-file>' -Records '<record>'
```

The key file must contain credentials on a single line in the format `PublicPrefix.Secret`. Either `-KeyPath` **or** both `-PublicPrefix` and `-Secret` must be provided.

---

## Examples

### Update a single record with your current public IP

```powershell
./IonUpdate.ps1 -PublicPrefix abc123 -Secret xyz789 -Records 'home.example.com'
```

### Update a single record with a custom IP

```powershell
./IonUpdate.ps1 -PublicPrefix abc123 -Secret xyz789 -Records 'home.example.com' -IP '1.2.3.4'
```

When `-IP` is omitted, the script resolves your current public IP via `https://ifconfig.me`.

### Authenticate using a key file

```powershell
./IonUpdate.ps1 -KeyPath './ion.key' -Records 'home.example.com'
```

### Update multiple records

```powershell
./IonUpdate.ps1 -PublicPrefix abc123 -Secret xyz789 -Records ("home.example.com", "vpn.example.com")
```

> Arrays must be declared with parentheses `()`. Using brackets `[]` will cause a PowerShell coercion error.

### Update and create missing records

```powershell
./IonUpdate.ps1 -PublicPrefix abc123 -Secret xyz789 -Records ("home.example.com", "vpn.example.com") -Create
```

`-Create` creates any records in the list that don't already exist in IONOS. Records not included in a subsequent run are left as-is.

---

## Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `-Records` | string or array | Yes | DNS A record(s) to update. Single string or parentheses-delimited array. |
| `-PublicPrefix` | string | Conditional | Public prefix of an IONOS API credential. Required with `-Secret`. |
| `-Secret` | string | Conditional | Secret of an IONOS API credential. Required with `-PublicPrefix`. |
| `-KeyPath` | string | Conditional | Path to a key file containing credentials in `PublicPrefix.Secret` format. |
| `-IP` | string | No | Custom IP address to assign. Defaults to the client's current public IP. |
| `-Create` | switch | No | Creates any records in `-Records` that don't already exist in IONOS. |

---

## Nixos

IonUpdate ships a Nix flake with a package, an overlay, and a NixOS service module.

### Running directly

```bash
nix run github:jimurrito/ionupdate -- -KeyPath '/root/ionos-key' -Records 'home.example.com'
```

Arguments after `--` are passed through to the script.

### Adding to your flake

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    ionupdate.url = "github:jimurrito/ionupdate";
  };

  outputs = { nixpkgs, ionupdate, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        ionupdate.nixosModules.default
        {
          services.ion-update = {
            enable = true;
            keyPath = "/root/ionos-key";
            records = [ "home.example.com" "vpn.example.com" ];
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
| --- | --- | --- | --- |
| `enable` | bool | `false` | Enables the IonUpdate scheduled service. |
| `keyPath` | string | `"/root/ionos-key"` | Path to the IONOS key file in `PublicPrefix.Secret` format. |
| `records` | list of strings | `[]` | DNS A records to track and update. |
| `interval` | string | `"daily"` | How often to run. Accepts any [systemd calendar expression](https://www.freedesktop.org/software/systemd/man/latest/systemd.time.html). |

### Notes

- The service runs as a dedicated `ion-update` user under `/var/ion-update`. A normal (non-system) user is required because the IonMod PowerShell module needs an interactive shell environment.
- `-Create` is always passed by the service, so records listed in `records` that don't yet exist in IONOS will be created on the first run.
- This script does not delete DNS records. Even the ones it has created.
- The timer uses `Persistent = true`, so a missed run will execute on the next boot.

---

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE.md).
