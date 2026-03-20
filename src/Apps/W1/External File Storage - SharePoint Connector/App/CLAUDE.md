# External File Storage - SharePoint Connector

Implements the External File Storage framework's connector interface for SharePoint Online. This is one of four first-party connectors (alongside Azure Blob, Azure File, and SFTP) that plug into BC's unified file storage API. It delegates to the SharePoint system module, which wraps the SharePoint REST API with OAuth 2.0 authentication via Microsoft Entra ID.

## Quick reference

- **ID range**: 4580--4589
- **Namespace**: `System.ExternalFileStorage`
- **Depends on**: External File Storage module (framework), SharePoint module (REST API wrapper) -- both in System Application

## How it works

The connector registers itself by extending the `Ext. File Storage Connector` enum with a `SharePoint` value that maps to `Ext. SharePoint Connector Impl` -- a codeunit implementing the `External File Storage Connector` interface. The framework discovers connectors by iterating enum values.

Each SharePoint account stores a site URL, base folder path, and Azure AD app registration credentials (tenant ID, client ID, and either a client secret or a certificate). Credentials are stored in BC's IsolatedStorage (Company scope) via Guid key references -- the table never holds the actual secrets. Authentication is mutually exclusive: setting a client secret clears any stored certificate, and vice versa.

Every file operation follows the same pattern: look up the account, compose the server-relative path (site path + base folder + relative path), initialize a SharePoint client with OAuth credentials, perform the operation, and check for errors via `SharePointClient.GetDiagnostics()`. The SharePoint module handles the OAuth token lifecycle -- this connector only needs to supply credentials and scopes.

The most non-obvious part is path composition. SharePoint uses server-relative URLs (e.g., `/sites/ProjectX/Shared Documents/Reports/file.pdf`). The `InitPath` procedure parses the site URL to extract the site path (`/sites/ProjectX`), combines the base folder with the caller's relative path, and prepends the site path. This is more complex than the SFTP connector's simple path concatenation.

## Structure

- `src/` -- All business logic: account table, account card page, setup wizard, auth enum, connector enum extension, and the implementation codeunit
- `permissions/` -- Permission sets and extensions integrating with the framework's permission model
- `Entitlements/` -- Implicit entitlement granting edit access

## Documentation

- [docs/data-model.md](docs/data-model.md) -- Account table design, IsolatedStorage secret pattern, relationship to framework
- [docs/business-logic.md](docs/business-logic.md) -- Account registration, OAuth initialization, path composition, file operations

## Things to know

- **Requires Azure AD app registration** -- the SharePoint site's tenant must have a registered app with `Sites.ReadWrite.All` permission. The connector stores the tenant ID and client ID in the account table.
- **Two auth methods, mutually exclusive** -- Client Secret (OAuth authorization code) or Certificate (client credentials). Setting one clears the other via `ClearCertificateAuthentication` / `ClearClientSecretAuthentication`.
- **OAuth scope is hardcoded** -- `00000003-0000-0ff1-ce00-000000000000/.default` (the SharePoint resource GUID). This targets SharePoint Online specifically.
- **Path composition is complex** -- the connector parses the SharePoint site URL to extract the site path, then combines it with the base folder and relative path to form a server-relative URL. The `GetSitePathFromUrl` procedure handles URL parsing via the `Uri` codeunit.
- **CopyFile and MoveFile are download + re-upload** -- the SharePoint module doesn't expose native copy/move operations, so the connector downloads to a TempBlob and re-uploads. MoveFile additionally deletes the source after upload.
- **FileExists uses directory listing** -- there is no direct "file exists" API call. Instead, the connector lists the parent directory, filters by `ServerRelativeUrl` matching the target path, and checks if any results come back.
- **Certificate auth uses .pfx/.p12 files** -- unlike the SFTP connector which accepts .pk/.ppk/.pub SSH keys, this connector expects PKCS#12 certificates with optional passphrase.
- **Sandbox safety** -- the `EnvironmentCleanup_OnClearCompanyConfig` subscriber auto-disables all accounts when a sandbox is created from production.
- **Not extensible** -- pages are `Extensible = false`, the auth enum is `Extensible = false`. No integration events are published.
- **GetFile has a stream workaround** -- same as SFTP: the InStream from `SharePointClient.DownloadFileContentByServerRelativeUrl` dies after crossing the interface boundary, so content is copied through an HttpContent intermediary.
