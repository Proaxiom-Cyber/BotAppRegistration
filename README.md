# Proaxiom Cyber – Bot App Registration

Deploys the **Proaxiom Cyber – {CustomerName} Bot** app registration in any Microsoft Entra ID tenant. This is a multi-customer variant derived from the [Proaxiom-Microsoft-MCP](https://github.com/Proaxiom-Cyber/Proaxiom-Microsoft-MCP) server suite, scoped to **read-only permissions only**.

Running the PowerShell script (`Add-ProaxiomBotAppRegistration.ps1`) will:
1. Connect to Microsoft Graph (prompting for login / tenant as needed).
2. Resolve all permission names to GUIDs from the live Graph service principal metadata.
3. Register the app with all required read-only API permissions.
4. Create the corresponding Service Principal.
5. Generate a client secret (default 30-day expiry) **shown once**.

---

## Prerequisites

- **PowerShell 7.x** (cross-platform, recommended) or **Windows PowerShell 5.1** with .NET Framework 4.7.2 or later.
- Microsoft.Graph PowerShell SDK installed.

---

## Quick Start

```powershell
# Install Microsoft Graph SDK if you haven't already
Install-Module Microsoft.Graph -Scope CurrentUser

# Deploy for a specific customer
.\Add-ProaxiomBotAppRegistration.ps1 -CustomerName "Contoso"

# Or target a specific tenant with custom secret expiry
.\Add-ProaxiomBotAppRegistration.ps1 -CustomerName "Contoso" -TenantId 01234567-89ab-cdef-0123-456789abcdef -SecretExpiryDays 90
```

---

## Post-deployment: Grant admin consent

After the script finishes, grant tenant-wide admin consent for the newly created application:

1. Open [Entra ID App registrations](https://entra.microsoft.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade/quickStartType~/null/sourceType/Microsoft_AAD_IAM).
2. Locate **"Proaxiom Cyber – {CustomerName} Bot"**.
3. Select **API permissions** in the left-hand menu.
4. Click **Grant admin consent for \<tenant\>** and confirm.

---

## Delivering the Client Secret Securely

1. Copy the client-secret value that the script prints.
2. Go to **Proaxiom Pass** → <https://pass.proaxiom.com>.
3. Paste the secret, set an expiry (e.g. 1 day), and generate a secure share link.
4. Send the link — **never the plain secret** — to your Proaxiom Cyber contact via **Teams** or **Signal**.

---

## Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `CustomerName` | Yes | — | Customer name used in the app display name |
| `TenantId` | No | Interactive prompt | Target Entra ID tenant GUID |
| `SecretExpiryDays` | No | 30 | Client secret validity in days |

---

## Security Notes

- All permissions are **read-only** — no write, send, create, or delete access is granted.
- Permission GUIDs are resolved at runtime from Graph metadata, not hardcoded.
- The client secret cannot be retrieved later — store or transmit it safely using the steps above.
- Any permissions that fail to resolve (e.g. not available in the target tenant) are reported as warnings and skipped.

---

## Permissions Assigned

### Microsoft Graph (62 read-only application permissions)

| Category | Permission |
|----------|------------|
| **Entra ID / Directory** | Application.Read.All |
| | AuditLog.Read.All |
| | CustomSecAttributeAssignment.Read.All |
| | CustomSecAttributeDefinition.Read.All |
| | Device.Read.All |
| | Directory.Read.All |
| | Domain.Read.All |
| | Group.Read.All |
| | GroupMember.Read.All |
| | IdentityProvider.Read.All |
| | IdentityRiskyServicePrincipal.Read.All |
| | IdentityRiskyUser.Read.All |
| | OnPremDirectorySynchronization.Read.All |
| | Organization.Read.All |
| | OrgContact.Read.All |
| | Policy.Read.All |
| | Reports.Read.All |
| | RoleManagement.Read.Directory |
| | Synchronization.Read.All |
| | User.Read.All |
| | UserAuthenticationMethod.Read.All |
| **Entra ID / Governance** | AccessReview.Read.All |
| | AdministrativeUnit.Read.All |
| | Agreement.Read.All |
| | DelegatedPermissionGrant.Read.All |
| | EntitlementManagement.Read.All |
| | LifecycleWorkflows.Read.All |
| **Intune / Device Management** | DeviceManagementApps.Read.All |
| | DeviceManagementConfiguration.Read.All |
| | DeviceManagementManagedDevices.Read.All |
| | DeviceManagementRBAC.Read.All |
| | DeviceManagementScripts.Read.All |
| | DeviceManagementServiceConfig.Read.All |
| **Security / Defender XDR** | AttackSimulation.Read.All |
| | CloudApp-Discovery.Read.All |
| | CustomDetection.Read.All |
| | SecurityAlert.Read.All |
| | SecurityAnalyzedMessage.Read.All |
| | SecurityEvents.Read.All |
| | SecurityIdentitiesHealth.Read.All |
| | SecurityIdentitiesSensors.Read.All |
| | SecurityIncident.Read.All |
| | ThreatHunting.Read.All |
| | ThreatIntelligence.Read.All |
| | ThreatSubmission.Read.All |
| **M365 / SharePoint / Teams** | Channel.ReadBasic.All |
| | ChannelSettings.Read.All |
| | InformationProtectionPolicy.Read.All |
| | MailboxSettings.Read |
| | Place.Read.All |
| | Presence.Read.All |
| | RecordsManagement.Read.All |
| | Schedule.Read.All |
| | ServiceHealth.Read.All |
| | ServiceMessage.Read.All |
| | Sites.Read.All |
| | Tasks.Read.All |
| | Team.ReadBasic.All |
| | TeamSettings.Read.All |
| | TeamsAppInstallation.ReadForTeam.All |
| | TeamMember.Read.All |
| | TeamworkTag.Read.All |

### Windows Defender ATP (12 read-only application permissions)

| Permission |
|------------|
| AdvancedQuery.Read.All |
| Alert.Read.All |
| File.Read.All |
| Machine.Read.All |
| RemediationTasks.Read.All |
| Score.Read.All |
| SecurityRecommendation.Read.All |
| Software.Read.All |
| Ti.Read.All |
| Url.Read.All |
| User.Read.All |
| Vulnerability.Read.All |

---

## License

MIT
