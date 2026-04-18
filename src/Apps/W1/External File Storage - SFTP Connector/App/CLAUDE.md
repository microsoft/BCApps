# External File Storage - SFTP Connector

Implements the External File Storage framework's connector interface for SFTP servers. This is one of four first-party connectors (alongside Azure Blob, Azure File, and SharePoint) that plug into BC's unified file storage API. Application code interacts with the framework -- not this connector directly -- so end users choose SFTP as a storage backend without any code changes.

## Quick reference

- **ID range**: 4621--4629
- **Namespace**: `System.ExternalFileStorage`
- **Depends on**: External File Storage module (framework), SFTP Client module (SSH.NET wrapper) -- both in System Application

## How it works

The connector registers itself by extending the `Ext. File Storage Connector` enum with a value that maps to `Ext. SFTP Connector Impl` -- a codeunit implementing the `External File Storage Connector` interface. This is the standard BC pattern for pluggable connectors: enum extension + interface implementation. The framework discovers available connectors by iterating enum values.

Each SFTP account stores connection details (hostname, port, base path, fingerprints) in the `Ext. SFTP Account` table. Credentials -- passwords and SSH private keys -- are **not** stored in the table. Instead, the table holds Guid keys that point to values in BC's IsolatedStorage (Company scope). The `OnDelete` trigger cleans up these IsolatedStorage entries. Authentication is mutually exclusive: setting a password clears any stored certificate, and vice versa.

Every file operation follows the same pattern: look up the account, combine the account's base path with the requested relative path, initialize an SFTP client (connect + authenticate), perform the operation, and disconnect. There is no connection pooling -- each operation opens and closes its own SSH session. The `SFTP Client` system module (which wraps SSH.NET) handles the actual protocol work.

## Structure

- `src/` -- All business logic: account table, account card page, setup wizard, auth enum, connector enum extension, and the implementation codeunit
- `permissions/` -- Permission sets and extensions that integrate with the framework's permission model
- `Entitlements/` -- Implicit entitlement granting edit access

## Documentation

- [docs/data-model.md](docs/data-model.md) -- Account table design, IsolatedStorage secret pattern, relationship to framework
- [docs/business-logic.md](docs/business-logic.md) -- Account registration, file operations, path sandboxing, environment safety

## Things to know

- **SFTP only, not FTP/FTPS** -- this connector uses SSH-based SFTP (default port 22). Plain FTP and FTPS are completely different protocols and are not supported.
- **Two auth methods, mutually exclusive** -- Password or Certificate (SSH private key). Setting one automatically clears the other via `ClearCertificateAuthentication` / `ClearPasswordAuthentication`.
- **Host fingerprints are required** -- stored as comma-separated values prefixed with `sha256:` or `md5:`. The connector calls `AddFingerprintSHA256`/`AddFingerprintMD5` on the SFTP Client before connecting.
- **Base path sandboxing** -- every operation prepends the account's `Base Relative Folder Path` to the requested path. Callers cannot escape this base directory.
- **CopyFile is download + re-upload** -- SFTP protocol has no native copy operation, so the connector downloads to a TempBlob and re-uploads. Large files will consume server memory.
- **DirectoryExists and DeleteDirectory delegate to FileExists and DeleteFile** -- the SFTP protocol treats directories as filesystem entries, so these operations are equivalent.
- **Sandbox safety** -- when a sandbox environment is created from production, the `EnvironmentCleanup_OnClearCompanyConfig` event subscriber automatically disables all SFTP accounts. This prevents sandbox from accidentally connecting to production SFTP servers.
- **GetFile has a platform workaround** -- the InStream from `SFTPClient.GetFileAsStream` dies after leaving the interface boundary, so the connector copies it through an HttpContent intermediary.
- **Not extensible** -- both pages set `Extensible = false`, the auth enum is `Extensible = false`. This connector is not designed for customization.
