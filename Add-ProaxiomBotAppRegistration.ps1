# Requires: Microsoft.Graph module
# Install-Module Microsoft.Graph -Scope CurrentUser

param(
    [Parameter(Mandatory)]
    [string]$CustomerName,

    [string]$TenantId,

    [int]$SecretExpiryDays = 30
)

# ---- Microsoft Graph connection ----
$Scopes = @(
    "Application.ReadWrite.All"
    "Directory.Read.All"
    "AppRoleAssignment.ReadWrite.All"
)

if (-not $TenantId) {
    $TenantId = Read-Host "Enter Entra ID Tenant ID (press Enter to choose during sign-in)"
}

if ([string]::IsNullOrWhiteSpace($TenantId)) {
    Connect-MgGraph -Scopes $Scopes -NoWelcome
} else {
    Connect-MgGraph -TenantId $TenantId -Scopes $Scopes -NoWelcome
}

Write-Host "Connected to tenant: $((Get-MgContext).TenantId)" -ForegroundColor Green

# Set display name and secret expiry
$appName = "Proaxiom Cyber - $CustomerName Bot"
$secretExpiry = (Get-Date).AddDays($SecretExpiryDays)

# ---- Permission definitions ----
# Read-only application permissions derived from the Proaxiom-Microsoft-MCP server suite.
# Permissions are listed by human-readable name and resolved to GUIDs at runtime.

# Microsoft Graph read-only permissions (ResourceAppId: 00000003-0000-0000-c000-000000000000)
$graphPermissionNames = @(
    # Entra ID / Directory
    "Application.Read.All"
    "AuditLog.Read.All"
    "CustomSecAttributeAssignment.Read.All"
    "CustomSecAttributeDefinition.Read.All"
    "Device.Read.All"
    "Directory.Read.All"
    "Domain.Read.All"
    "Group.Read.All"
    "GroupMember.Read.All"
    "IdentityProvider.Read.All"
    "IdentityRiskyServicePrincipal.Read.All"
    "IdentityRiskyUser.Read.All"
    "OnPremDirectorySynchronization.Read.All"
    "Organization.Read.All"
    "OrgContact.Read.All"
    "Policy.Read.All"
    "Reports.Read.All"
    "RoleManagement.Read.Directory"
    "Synchronization.Read.All"
    "User.Read.All"
    "UserAuthenticationMethod.Read.All"

    # Entra ID / Governance
    "AccessReview.Read.All"
    "AdministrativeUnit.Read.All"
    "Agreement.Read.All"
    "DelegatedPermissionGrant.Read.All"
    "EntitlementManagement.Read.All"
    "LifecycleWorkflows.Read.All"

    # Intune / Device Management
    "DeviceManagementApps.Read.All"
    "DeviceManagementConfiguration.Read.All"
    "DeviceManagementManagedDevices.Read.All"
    "DeviceManagementRBAC.Read.All"
    "DeviceManagementScripts.Read.All"
    "DeviceManagementServiceConfig.Read.All"

    # Security / Defender XDR
    "AttackSimulation.Read.All"
    "CloudApp-Discovery.Read.All"
    "CustomDetection.Read.All"
    "SecurityAlert.Read.All"
    "SecurityAnalyzedMessage.Read.All"
    "SecurityEvents.Read.All"
    "SecurityIdentitiesHealth.Read.All"
    "SecurityIdentitiesSensors.Read.All"
    "SecurityIncident.Read.All"
    "ThreatHunting.Read.All"
    "ThreatIntelligence.Read.All"
    "ThreatSubmission.Read.All"

    # M365 / Exchange / SharePoint / Teams
    "Channel.ReadBasic.All"
    "ChannelSettings.Read.All"
    "InformationProtectionPolicy.Read.All"
    "MailboxSettings.Read"
    "Place.Read.All"
    "Presence.Read.All"
    "RecordsManagement.Read.All"
    "Schedule.Read.All"
    "ServiceHealth.Read.All"
    "ServiceMessage.Read.All"
    "Sites.Read.All"
    "Tasks.Read.All"
    "Team.ReadBasic.All"
    "TeamSettings.Read.All"
    "TeamsAppInstallation.ReadForTeam.All"
    "TeamMember.Read.All"
    "TeamworkTag.Read.All"
)

# Windows Defender ATP read-only permissions (ResourceAppId: fc780465-2017-40d4-a0c5-307022471b92)
$mdePermissionNames = @(
    "AdvancedQuery.Read.All"
    "Alert.Read.All"
    "File.Read.All"
    "Machine.Read.All"
    "RemediationTasks.Read.All"
    "Score.Read.All"
    "SecurityRecommendation.Read.All"
    "Software.Read.All"
    "Ti.Read.All"
    "Url.Read.All"
    "User.Read.All"
    "Vulnerability.Read.All"
)

# ---- Resolve permission names to GUIDs ----
function Resolve-AppRoleIds {
    param(
        [string]$ResourceAppId,
        [string[]]$PermissionNames
    )

    $sp = Get-MgServicePrincipal -Filter "appId eq '$ResourceAppId'" -Property appRoles
    if (-not $sp) {
        throw "Service principal not found for appId '$ResourceAppId'"
    }

    $resolved = @()
    $failed = @()

    foreach ($name in $PermissionNames) {
        $role = $sp.AppRoles | Where-Object { $_.Value -eq $name }
        if ($role) {
            $resolved += @{ Id = $role.Id; Type = "Role" }
        } else {
            $failed += $name
        }
    }

    if ($failed.Count -gt 0) {
        Write-Warning "Could not resolve $($failed.Count) permission(s) for $($sp.DisplayName):"
        $failed | ForEach-Object { Write-Warning "  - $_" }
    }

    Write-Host "Resolved $($resolved.Count)/$($PermissionNames.Count) permissions for $($sp.DisplayName)" -ForegroundColor Cyan
    return $resolved
}

$graphAppId = "00000003-0000-0000-c000-000000000000"
$mdeAppId   = "fc780465-2017-40d4-a0c5-307022471b92"

Write-Host "`nResolving permission GUIDs..." -ForegroundColor Yellow

$graphRoles = Resolve-AppRoleIds -ResourceAppId $graphAppId -PermissionNames $graphPermissionNames
$mdeRoles   = Resolve-AppRoleIds -ResourceAppId $mdeAppId   -PermissionNames $mdePermissionNames

$requiredResourceAccess = @()

if ($graphRoles.Count -gt 0) {
    $requiredResourceAccess += @{
        ResourceAppId  = $graphAppId
        ResourceAccess = $graphRoles
    }
}

if ($mdeRoles.Count -gt 0) {
    $requiredResourceAccess += @{
        ResourceAppId  = $mdeAppId
        ResourceAccess = $mdeRoles
    }
}

# ---- Create the app registration ----
$newApp = New-MgApplication -DisplayName $appName -RequiredResourceAccess $requiredResourceAccess

# Create the associated service principal
$sp = New-MgServicePrincipal -AppId $newApp.AppId

# Create client secret
$secret = Add-MgApplicationPassword -ApplicationId $newApp.Id -PasswordCredential @{
    DisplayName = "AutoGeneratedSecret"
    EndDateTime = $secretExpiry
}

# Output results
$totalPerms = $graphRoles.Count + $mdeRoles.Count
Write-Host "`n✅ App Registration Created:"
Write-Host "   Name        : $appName"
Write-Host "   AppId       : $($newApp.AppId)"
Write-Host "   ObjectId    : $($newApp.Id)"
Write-Host "   Permissions : $totalPerms read-only ($($graphRoles.Count) Graph + $($mdeRoles.Count) MDE)"
Write-Host "   ClientSecret: $($secret.SecretText)"
Write-Host "   Expires     : $($secret.EndDateTime)"
Write-Host "`n⚠��  Grant admin consent in the Entra portal before using this application."
Write-Host "⚠️  The client secret is shown once — transmit it securely via Proaxiom Pass."
