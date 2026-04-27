# IONUpdate v2.0
A script to keep IONOS DNS A Records up to date. Uses the [IonMod](https://github.com/jimurrito/IonMod) library to handle communications with IONOS.

> **Please note** that PublicPrefix and Secret will need to be generated from IONOS. [Follow this link for more.](https://developer.hosting.ionos.com/docs/getstarted) Any script errors regarding unauthorized requests need to be handled by IONOS support.

# Examples

### Update a single record with your current Public IP
```Powershell
./IonUpdate.ps1 -PublicPrefix XXXXX -Secret XXXXX -Records 'name.domain.com'
```

### Update a single record with a custom IP address
```Powershell
./IonUpdate.ps1 -PublicPrefix XXXXX -Secret XXXXX -Records 'name.domain.com' -IP '1.1.1.1'
```

When `-IP` is not provided, the script will pull your current public IP via `https://ifconfig.me`.

### Authenticate using a key file
```Powershell
./IonUpdate.ps1 -KeyPath './ion.key' -Records 'name.domain.com'
```

The key file should contain the credentials in the format `PublicPrefix.Secret` on a single line. This is a convenient alternative to passing `-PublicPrefix` and `-Secret` directly.

### Update multiple DNS records
```Powershell
./IonUpdate.ps1 -PublicPrefix XXXXX -Secret XXXXX -Records ("name.domain.com","foobar.domain.com")
```

Due to a PowerShell limitation, arrays must be specified with parentheses `()`. Brackets `[]` will cause errors when PowerShell tries to coerce the list.

### Update and create missing DNS records
```Powershell
./IonUpdate.ps1 -PublicPrefix XXXXX -Secret XXXXX -Records ("name.domain.com","foobar.domain.com") -Create
```

The parameter `-Create` will create any records that do not exist in the DNS registry.

> Please note this script will not manage the lifecycle of newly created records. If a subsequent run does not include a previously created record like `foobar.domain.com`, that record will remain as-is.

Custom IP addresses can be used with any number of DNS records and with any authentication method.

# Parameters

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

# Future plans
- Add support for other IONOS API endpoints.
- Support for a `.json` manifest to allow for more complex operations.
- Remove herobrine.