# Module: TeamsLicenseChecker.ps1
function Connect-AppOnlyGraph {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TenantId,

        [Parameter(Mandatory = $true)]
        [string]$ClientId,

        [Parameter(Mandatory = $true)]
        [string]$ClientSecret
    )

    # Convert the client secret to a secure string
    $SecureSecret = ConvertTo-SecureString -String $ClientSecret -AsPlainText -Force

    # Create a PSCredential object
    $ClientSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ClientId, $SecureSecret

    # Connect to Microsoft Graph using app-only authentication
    Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $ClientSecretCredential
}


function Get-TeamsServicePlanIds {
    $csvUrl = "https://download.microsoft.com/download/e/3/e/e3e9faf2-f28b-490a-9ada-c6089a1fc5b0/Product%20names%20and%20service%20plan%20identifiers%20for%20licensing.csv"
    $csvPath = "$env:TEMP\ServicePlans.csv"

    Invoke-WebRequest -Uri $csvUrl -OutFile $csvPath -ErrorAction Stop
    $servicePlans = Import-Csv -Path $csvPath

    # Define a whitelist of known core Teams service plan names
    $coreTeamsPlans = @(
        "TEAMS1",               # Core Teams
        "TEAMS_EXPLORATORY",   # Exploratory experience
        "TEAMS_A",             # Academic
        "TEAMS_COMMERCIAL_TRIAL"
    )

    # Filter only those rows where Service_Plan_Name matches known core Teams plans
    $filtered = $servicePlans | Where-Object {
        $coreTeamsPlans -contains $_.Service_Plan_Name
    }

    return $filtered.Service_Plan_Id | Sort-Object -Unique
}




function Get-TeamsLicensedUsers {
    $teamsPlanIds = Get-TeamsServicePlanIds
    $users = Get-MgUser -All

    $teamsUsers = foreach ($user in $users) {
        $licenses = Get-MgUserLicenseDetail -UserId $user.Id
        foreach ($license in $licenses) {
            foreach ($plan in $license.ServicePlans) {
                if ($teamsPlanIds -contains $plan.ServicePlanId) {
                    [PSCustomObject]@{
                        DisplayName = $user.DisplayName
                        UserPrincipalName = $user.UserPrincipalName
                        License = $license.SkuPartNumber
                        ServicePlan = $plan.ServicePlanName
                    }
                    break
                }
            }
        }
    }

    return $teamsUsers
}

# Example usage
$tenantId = "xxxxxxx"
$clientId = "xxxxxxxxx"
$clientSecret = "xxxxxxxxxxx"


Connect-AppOnlyGraph -TenantId $TenantId -ClientId $ClientId -ClientSecret $ClientSecret
$teamsUsers = Get-TeamsLicensedUsers
$teamsUsers | Export-Csv -Path "TeamsLicensedUsers.csv" -NoTypeInformation
