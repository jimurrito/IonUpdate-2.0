# IonUpdate Version 2.0
# Script to update IONOS domains
# By Jimurrito : jimurrito@gmail.com
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
<#
    .Synopsis
    Checks if IonMod is installed, if not installs it.

    .Description
    Checks if IonMod is installed, if not installs it.

    .Example
    # Example
    Confirm-IonModule
#>
function Confirm-IonModule {
    if (!(get-module -Name ionmod)) {
        Install-Module ionmod -Force
        Import-Module ionmod
    }
}
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
<#
    .Synopsis
    Gets current IP of the client

    .Description
    Contacts `https://ifconfig.me` to get the current public IP address of the client who executes the command.

    .Example
    # Example
    Get-PublicIp
#>
function Get-PublicIp {
    return (Invoke-WebRequest https://ifconfig.me).content
}
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
<#
    .Synopsis
    Pulls the higher-level domain from a DNS A record.

    .Description
    Pulls the higher-level domain from a DNS A record.

    .Example
    # Example
    Get-TopLevelDomain "test.contoso.com"
    #> "contoso.com"
#>
function Get-TopLevelDomain {
    param (
        $Record=$1
    )
    ($Record -split '\.')[1..$Record.length] -join "."
}