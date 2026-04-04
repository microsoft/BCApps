# External File Storage -- Azure Blob Service Connector

This app bridges Azure Blob Storage and Business Central's External File Storage framework. It implements the `External File Storage Connector` interface, translating the framework's file/directory operations into Azure Blob REST API calls via the `ABS Blob Client` from System Application. It is intentionally minimal -- one table, one codeunit, three pages -- serving as the reference implementation for how connectors plug into the framework.

## Quick reference

- ID range: 4560-4569 (10 IDs, uses 4560-4562)
- No dependencies beyond the implicit System Application
- Namespace: `System.ExternalFileStorage`
- `internalsVisibleTo` the test app only

## How it works

The connector registers itself with the framework through a single enum extension (`ExtBlobStorageConnector.EnumExt.al`) that adds value `"Blob Storage"` to the `"Ext. File Storage Connector"` enum, binding it to the `"Ext. Blob Sto. Connector Impl."` codeunit. When the framework dispatches a file operation for a Blob Storage account, it calls into this codeunit via the interface.

Every operation follows the same pattern: `InitBlobClient()` loads the account record, checks the `Disabled` flag, retrieves the secret from IsolatedStorage, selects the auth strategy (SAS token or shared key), and initializes an `ABS Blob Client` scoped to the account's container. The operation then delegates to the appropriate ABS method and validates the response.

Azure Blob Storage is flat -- it has no native directories. The connector simulates directories by uploading a marker file (`BusinessCentral.FileSystem.txt`) at the directory path. Listing directories filters for this marker; deleting a directory removes it. This means directories can "disappear" if something external deletes the marker blob while files remain at that path.

Account credentials are never stored in the database. The table holds only a GUID reference (`Secret Key`); the actual SAS token or shared key lives in IsolatedStorage at company scope. On sandbox creation from production, an environment cleanup subscriber auto-disables all accounts to prevent credential leakage.

## Structure

- `src/` -- all AL objects (table, codeunit, pages, enums)
- `permissions/` -- three permission sets (objects, read, edit) plus two permission set extensions
- `Entitlements/` -- single entitlement for connector access
- `data/` -- connector logo resource

## Documentation

- [docs/data-model.md](docs/data-model.md) -- table design and secret storage
- [docs/business-logic.md](docs/business-logic.md) -- operation flows, directory simulation, account registration
- [docs/extensibility.md](docs/extensibility.md) -- how to build a new connector using this as reference
- [docs/patterns.md](docs/patterns.md) -- marker files, copy-then-delete moves, environment cleanup

## Things to know

- MoveFile is not atomic. It does CopyBlob then DeleteBlob. If the copy succeeds but the delete fails, the file exists in both locations with no way for the caller to detect partial failure.
- DirectoryExists returns true for empty path (root always exists). FileExists returns false for empty path. This asymmetry is intentional.
- ListBlobs pages in batches of 500 via `ABSOptionalParameters.MaxResults(500)` and marker-based pagination. The framework's `FilePaginationData` codeunit carries the continuation marker between calls.
- The wizard page (`ExtBlobStorAccountWizard.Page.al`) uses a temporary source table. The account record is only persisted when the user clicks Next, which calls `CreateAccount()`.
- Container name supports a lookup that calls `ABS Container Client.ListContainers()` -- this requires a valid storage account name and secret before it works.
- The `Secret` field on the account page shows `'***'` for existing accounts (see `OnAfterGetCurrRecord`). The actual secret text is never displayed or returned to the client.
- All pages except the account card are `Extensible = false`. The table is extensible by default.
- The codeunit is `Access = Internal` with `InherentEntitlements = X` and `InherentPermissions = X` -- it relies on the entitlement and permission sets to gate access rather than granting permissions implicitly.
- ListFiles uses `Delimiter('/')` to scope results to the immediate directory level (no recursive listing). ListDirectories filters by `Resource Type::Directory` at the same prefix level.
- The `CheckPath()` helper ensures all non-empty paths end with `/`. This normalization happens before every listing operation.
