# Teams License Checker

A PowerShell script that uses the Microsoft Graph SDK to identify all users in your organization who are licensed for **Microsoft Teams**. This script supports **app-only authentication** and dynamically fetches the latest list of Teams-related service plans from Microsoft.

## Features

- App-only authentication using Microsoft Graph SDK
- Dynamically downloads and parses Microsoft’s official service plan reference CSV
- Filters users based on **core Teams service plans** only
- Outputs results to a CSV file
- Modular and reusable functions

## Requirements
- PowerShell 7+
- Microsoft Graph PowerShell SDK
- Azure AD App Registration with the following API permissions:
  - `User.Read.All`
  - `Directory.Read.All`

## Authentication
This script uses **app-only authentication**. You must register an app in Azure AD and provide:

- `TenantId`
- `ClientId`
- `ClientSecret`

## Script Structure

### `Connect-AppOnlyGraph`

Authenticates to Microsoft Graph using app-only credentials.

### `Get-TeamsServicePlanIds`

Downloads the latest Microsoft service plan reference CSV and extracts only the **core Teams service plan IDs**:
- `TEAMS1`
- `TEAMS_EXPLORATORY`
- `TEAMS_A`
- `TEAMS_COMMERCIAL_TRIAL`

### `Get-TeamsLicensedUsers`

Retrieves all users and filters those who have at least one of the core Teams service plans.

## Usage

```powershell
$tenantId = "<your-tenant-id>"
$clientId = "<your-client-id>"
$clientSecret = "<your-client-secret>"

Connect-AppOnlyGraph -TenantId $tenantId -ClientId $clientId -ClientSecret $clientSecret
$teamsUsers = Get-TeamsLicensedUsers
$teamsUsers | Export-Csv -Path "TeamsLicensedUsers.csv" -NoTypeInformation
```

## Notes 

- The script avoids false positives by excluding add-ons like TEAMS_ADVCOMMS and MESH_IMMERSIVE_FOR_TEAMS.
- You can extend the script to log users with Teams add-ons separately if needed.
