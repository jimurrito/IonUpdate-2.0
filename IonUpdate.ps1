<#PSScriptInfo

.VERSION 1.0

.GUID 2199fa97-80c8-4932-bdfe-c361b3e72054

.AUTHOR Jimurrito

.COMPANYNAME Virtrillo Software Solutions

.COPYRIGHT (c) 2024 Jimurrito. All rights reserved.

.TAGS @("Ionos", "Domain", "API", "SDK", "IONOS", "Powershell", "Module", "DNS", "Management", "Zone", "1&1", "Update")

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


.PRIVATEDATA

#>

<#

.DESCRIPTION
 Script to keep IONOS DNS records up-to-date with given IP.

#>
# Updates bulk IONOS domains
param (
    # target domain(s)
    [Parameter(Mandatory = $true)]
    $Records,
    # Desired IP - if $null, gets public ip of client
    $IP,
    # IONOS keys
    [string]$KeyPath,
    [string]$PublicPrefix,
    [string]$Secret,
    # Create missing
    [switch]$Create
)
#
# Ensure some key value is set
if (-not ($PublicPrefix -and $Secret -or $KeyPath))
{
    Write-Error "Script must have either '-PublicPrefix' & '-Secret' or '-KeyPath' to work as expected."
    exit
}
#
# Get IONOS creds prior to anything else
if ($KeyPath)
{
    # Kills run if get-content fails
    $PublicPrefix, $Secret = (Get-Content -path $KeyPath -ErrorAction stop) -split "\."
}
#
# Import local library
Import-Module -Name "$PSScriptRoot/IonUpdate.psm1"
#
# Installs IonMod Module
#Confirm-IonModule
if (!(get-module -Name ionmod))
{
    Install-Module ionmod -Force -AcceptLicense
    Import-Module ionmod
}
#
# Logs in and stores creds in static class
Connect-Ion -PublicPrefix $PublicPrefix -Secret $Secret
#
# IP check
# Grab if not defined
$IP = if (-not $IP)
{
    Get-PublicIp
} else
{
    $IP
}
Write-Host "Updating IONOS with IP:[$IP]."
#
# Get lists of top level domains from input list
# parses the target domains provided and parses out the TLD
$TLDomains = $Records | ForEach-Object { Get-TopLevelDomain $_ } | Sort-Object -Unique
Write-Host ("[{0}] Target Zone(s)." -f $TLDomains.Count)
#
# get zones from IONOS
$AllZones = Get-IonZone
# $AllZones is used as Get-IonZone seems to have issues with where-object when directly piped
$Zones = $AllZones | Where-Object { $TLDomains -contains $_.name }
Write-Host ("Found [{0}] existing Zone(s) in scope." -f @($Zones).Count)
#
# Work on each zone
foreach ($z in $Zones)
{
    Write-Host ("Working on Zone:[{0}]." -f $z.name)
    #
    # <Pull Records>
    #
    # Get records for the zone
    $IONRecords_ALL = (Get-IonZone -ZoneId $z.id).records
    $MET_Total_Recs = @($IONRecords_ALL).Count # get count for metric output
    #
    # <Sort Records>
    #
    # Grabs records that need to be created
    # Filters out records that are not in the same zone
    # Filters records provided, but not found in IONOS.
    # List(String)
    $IONRecords_tb_Created = $Records | Where-Object {($_ -match $z.name) -and ($IONRecords_ALL.name -notcontains $_) }
    $MET_Create_Recs = @($IONRecords_tb_Created).Count
    # Grabs records that need to be updated
    # Filter out records that DO NOT match ones in the input list
    # Filters out records that already match the requested IP.
    # List(PSObj)
    $IONRecords_tb_Updated = $IONRecords_ALL | Where-Object { ( $Records -contains $_.name ) -and ( $IP -ne $_.content ) }
    $MET_Update_Recs = @($IONRecords_tb_Updated).Count # get count for metric output
    #
    # <No in-scope records>
    #
    # Check if there are any records left for this zone (created or updated)
    if (!($IONRecords_tb_Updated) -and !($IONRecords_tb_Created))
    {
        Write-Host ("Zone:[{0}] is already up-to-date." -f $z.name)
        # No records left, iter to next zone.
        continue
    }
    #
    # <Write Operations>
    #
    # Update existing
    # Updates records that match the list provided at runtime.
    # Due to how IONOS's endpoints work for Set-IonZone, we need to post back ALL records we want in the zone.
    # Any left off will be removed from the zone.
    if ($IONRecords_tb_Updated)
    {
        Write-Host "Found [$MET_Update_Recs/$MET_Total_Recs] existing Record(s) need updating."
        # Update IPs for ONLY records in scope.
        $IONRecords_ALL | Where-Object { $IONRecords_tb_Updated -contains $_ } | ForEach-Object { $_.content = $IP }
        # Post back to IONOS
        Set-IonZone -ZoneId $z.id -Records $IONRecords_ALL
        Write-Host ("Pushed update to Zone:[{0}]." -f $z.name)
    } else
    {
        Write-Host ("No existing records to update in Zone:[{0}]." -f $z.name)
    }
    #
    #
    # Create records
    if ($IONRecords_tb_Created -and $Create)
    {
        Write-Host "[$MET_Create_Recs] Record(s) need to be created." -ForegroundColor Yellow
        # Creates new objects
        $IONRecords_Created = $IONRecords_tb_Created | ForEach-Object {
            New-IonRecordObj -ZoneName $z.name -name $_ -Content $IP
        }
        # Post new records to IONOS
        $Created_Recs = New-IonRecord -ZoneId $z.id -Body $IONRecords_Created
        $MET_Created = @($Created_Recs).Count
        Write-Host "[$MET_Created/$MET_Create_Recs] Record(s) have been added to the Zone." -ForegroundColor Yellow
    }
    # Need to create, but functionality is disabled.
    elseif ($IONRecords_tb_Created -and !($Create))
    {
        Write-Host "[$MET_Create_Recs] Record(s) could not be found in Zone. Create functionality is disabled, missing records will be skipped." -ForegroundColor Yellow
        Write-Host "Record(s): $IONRecords_tb_Created" -ForegroundColor Yellow
    }
}
#
Write-Host "Done"
