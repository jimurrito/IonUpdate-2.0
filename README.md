# ION Update v2.0
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

### Update multiple DNS records
```Powershell
./IonUpdate.ps1 -PublicPrefix XXXXX -Secret XXXXX -Records ("name.domain.com","foobar.domain.com")
```

Due to a powershell limitation, arrays must be specified with parentheses `()`. Brackets `[]` will cause errors when Powershell tries to coerse the list.

### Update and Create missing DNS records
```Powershell
./IonUpdate.ps1 -PublicPrefix XXXXX -Secret XXXXX -Records ("name.domain.com","foobar.domain.com") -Create
```
The parameter `-Create` will create any records that do not exist in the DNS registry.

> Please note this script will not manage the life cycle of these newly created domain names. If the next command ran does not include one of the created domain named, like `foobar.domain.com`, that domain will remain as-is.

While not provided as an example, custome IP addresses can be used with any number of DNS records.

# Parameters

### `-PublicPrefix`
The public-prefix is provided by IONOS as an part of an API credential.

### `-Secret`
The secret is provided by IONOS as an part of an API credential.

### `-Records`
The DNS A records that will be updated.
> Accepts either a single name `name.domain.com` or an array `("name.domain.com","foobar.domain.com")`. The use of brackets to declare the array is not supported by Powershell.

### `-IP`
A custom IP address all the provided DNS names will be set to.

### `-Create`
With this switch provided, the script will create any DNS record(s) that do not already exist in IONOS.

# Future plans
- Add support for other IONOS api endpoints.
- Support for a `.json` manifest to allow for more complex operations.
- Remove herobrine. 