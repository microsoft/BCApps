# External Storage - Document Attachments

Bridges BC's Document Attachment system (Base Application) with the External File Storage framework (System Application). When enabled, document attachments are automatically offloaded from the database to an external storage provider (Azure Blob, Azure Files, SharePoint, or SFTP) and transparently retrieved on demand. The end user sees no difference -- files appear to work normally, but binary content lives outside the database.

## Quick reference

- **ID range**: 8750--8770
- **Namespace**: `Microsoft.ExternalStorage.DocumentAttachments`
- **Depends on**: External File Storage module (System App) for storage operations, Document Attachment table (Base App) as the integration surface

## How it works

The app registers a File Scenario (`Doc. Attach. - External Storage`) with the External File Storage framework. An admin assigns a storage account (e.g., an Azure Blob container) to this scenario and enables the feature on the `DA External Storage Setup` page.

Once enabled, the app subscribes to events on the `Document Attachment` table to create transparent behavior. When a new attachment is inserted, the `OnAfterInsertEvent` subscriber automatically uploads the file to external storage and deletes the database copy. When an attachment is deleted, the `OnAfterDeleteEvent` subscriber can optionally delete the external copy too (controlled by the "Delete from External Storage" setting). When any code tries to read an attachment's content -- via `ExportToStream`, `GetAsTempBlob`, or `HasContent` -- event subscribers intercept the call and fetch the file from external storage on the fly. This means existing BC code (reports, factboxes, APIs) works without modification.

Files are stored at a path like `RootFolder/EnvironmentHash/TableName/FileName-GUID.ext`. The environment hash is an MD5 of `TenantId|EnvironmentName|CompanySystemId`, which isolates files per tenant, environment, and company. This prevents file collisions in multi-tenant scenarios and enables migration detection when data moves between environments.

The app tracks each file's location with two independent boolean flags: `Stored Internally` (file is in the BC database) and `Stored Externally` (file is in external storage). A file can exist in both places, one place, or neither. This dual-storage model supports flexible operations: upload to external (copy or move), download to internal (restore), delete from either side independently.

## Structure

- `src/Setup/` -- Configuration table (singleton) and setup page with actions for sync and migration
- `src/DocumentAttachmentIntegration/` -- Core logic: the implementation codeunit (event subscribers, file operations, File Scenario interface), table extension on Document Attachment, enum extension for scenario registration, and the external attachments list page
- `src/AutomaticSync/` -- Two processing-only reports for bulk sync (bidirectional) and cross-environment migration
- `src/Telemetry/` -- Feature telemetry logging wrapper

## Documentation

- [docs/data-model.md](docs/data-model.md) -- Setup table, Document Attachment extension fields, environment hash, path structure
- [docs/business-logic.md](docs/business-logic.md) -- Auto-offload flow, transparent read, sync/migration, path generation

## Things to know

- **Auto-offload on insert** -- when enabled, every new Document Attachment is immediately uploaded to external storage and the DB copy is deleted. This happens in the `OnAfterInsertEvent` subscriber.
- **Transparent read** -- `OnBeforeExportToStream`, `OnBeforeGetAsTempBlob`, and `OnBeforeHasContent` subscribers intercept content access and fetch from external storage. Existing BC code doesn't need changes.
- **Dual storage tracking** -- `Stored Internally` and `Stored Externally` are independent booleans. A file can be in both places (after "Copy to Internal"), one place (normal operation), or neither (edge case after failed operations).
- **Environment hash isolation** -- MD5(TenantId|EnvironmentName|CompanySystemId) creates unique folder paths per tenant/env/company. When data moves between environments, the hash changes and files need migration.
- **"Skip Delete On Copy"** -- when `Document Attachment Mgmt` copies attachments between documents, the app sets this flag on the destination to prevent the `OnAfterDeleteEvent` subscriber from deleting the shared external file.
- **OneDrive not supported** -- `OnBeforeOpenInOneDrive` blocks the action for externally stored files with an error message.
- **Cannot disable with files** -- the setup page validates that no files are stored externally before allowing the feature to be disabled. This prevents orphaning.
- **Per-record commits in sync** -- the sync report commits after each file to prevent re-uploading large batches if the connection drops mid-way.
- **Migration detects by hash** -- the migration report compares each file's `Source Environment Hash` against the current hash to identify files that need to move to the current folder structure.
- **Table name fallback** -- `GetTableNameFolder` uses a TryFunction to get the table name; if the table no longer exists (app uninstalled), it falls back to `Table_<ID>`.
