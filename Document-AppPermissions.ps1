param(
    [string]$TenantId,
    [string]$ReadmePath = (Join-Path $PSScriptRoot 'README.md')
)

# Scopes required only to read service-principal metadata
$Scopes = @('Application.Read.All')

# ---- Connect to Microsoft Graph ----
if ($TenantId) {
    Connect-MgGraph -TenantId $TenantId -Scopes $Scopes -NoWelcome
} else {
    Connect-MgGraph -Scopes $Scopes -NoWelcome
}

# ------------------------------------
# Extract permission name arrays from Add-ProaxiomBotAppRegistration.ps1
$addScriptPath = Join-Path $PSScriptRoot 'Add-ProaxiomBotAppRegistration.ps1'
if (-not (Test-Path $addScriptPath)) {
    throw "Could not locate Add-ProaxiomBotAppRegistration.ps1 in $PSScriptRoot"
}

$fileContent = Get-Content $addScriptPath -Raw

# Extract $graphPermissionNames array
$graphMatch = [regex]::Match($fileContent, '\$graphPermissionNames\s*=\s*@\(([\s\S]*?)\)')
if (-not $graphMatch.Success) { throw 'Failed to locate $graphPermissionNames array.' }
$graphNames = [regex]::Matches($graphMatch.Groups[1].Value, '"([^"]+)"') | ForEach-Object { $_.Groups[1].Value }

# Extract $mdePermissionNames array
$mdeMatch = [regex]::Match($fileContent, '\$mdePermissionNames\s*=\s*@\(([\s\S]*?)\)')
if (-not $mdeMatch.Success) { throw 'Failed to locate $mdePermissionNames array.' }
$mdeNames = [regex]::Matches($mdeMatch.Groups[1].Value, '"([^"]+)"') | ForEach-Object { $_.Groups[1].Value }

# Resolve and build table
$graphAppId = "00000003-0000-0000-c000-000000000000"
$mdeAppId   = "fc780465-2017-40d4-a0c5-307022471b92"

function Get-PermissionTable {
    param(
        [string]$ResourceAppId,
        [string[]]$PermissionNames
    )

    $sp = Get-MgServicePrincipal -Filter "appId eq '$ResourceAppId'" -Property displayName,appRoles
    $rows = @()

    foreach ($name in ($PermissionNames | Sort-Object)) {
        $role = $sp.AppRoles | Where-Object { $_.Value -eq $name }
        if ($role) {
            $desc = ($role.Description -as [string]) -replace '(?i)\bwithout\b[^\.]*signed[- ]in\s+user\.?', ''
            $rows += "| $($sp.DisplayName) | $name | Role | $($role.Id) | $($desc.Trim()) |"
        } else {
            Write-Warning "Could not resolve $name for $($sp.DisplayName)"
        }
    }
    return $rows
}

Write-Host "Resolving permissions..." -ForegroundColor Yellow

$mdHeader = '| API | Permission | Type | GUID | Description |'
$mdSep    = '| --- | ---------- | ---- | ---- | ----------- |'

$graphRows = Get-PermissionTable -ResourceAppId $graphAppId -PermissionNames $graphNames
$mdeRows   = Get-PermissionTable -ResourceAppId $mdeAppId   -PermissionNames $mdeNames

$tableLines = @($mdHeader, $mdSep) + $graphRows + $mdeRows

$startMarker = '<!-- PERMISSIONS-TABLE-START -->'
$endMarker   = '<!-- PERMISSIONS-TABLE-END -->'

if (Test-Path $ReadmePath) {
    $readmeContent = Get-Content $ReadmePath -Raw
} else {
    $readmeContent = ''
}

if ($readmeContent -match "$startMarker[\s\S]*?$endMarker") {
    $readmeContent = [regex]::Replace($readmeContent, "$startMarker[\s\S]*?$endMarker", "$startMarker`n$($tableLines -join "`n")`n$endMarker")
} else {
    $readmeContent += "`n`n$startMarker`n$($tableLines -join "`n")`n$endMarker"
}

Set-Content $ReadmePath $readmeContent

Write-Host "Updated permissions table in README.md ($($graphRows.Count) Graph + $($mdeRows.Count) MDE)" -ForegroundColor Green
