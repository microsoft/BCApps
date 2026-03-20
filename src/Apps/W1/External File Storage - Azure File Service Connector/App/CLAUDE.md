# External File Storage -- Azure File Service Connector

Azure File Share connector for the External File Storage module. Sister
implementation to the Blob Storage connector -- same interface, same
framework, but the underlying Azure service has fundamentally different
semantics that make this connector simpler in some areas and more complex
in others.

## Why this connector exists

Azure File Shares provide a SMB-compatible file system with real
directories, atomic renames, and a two-step file creation API. The Blob
connector fakes directories with marker files and implements move as
copy-then-delete. This connector gets those things natively from the
Azure File Share REST API, which makes directory operations trivially
correct and file moves atomic.

## Architecture in one paragraph

The enum extension in `ExtFileShareConnector.EnumExt.al` registers the
`"File Share"` value on the framework's connector enum and binds it to the
implementation codeunit `ExtFileShareConnectorImpl` (4570). That codeunit
implements every method of the `"External File Storage Connector"`
interface by delegating to `AFS File Client` from the Azure Storage SDK.
A single table (`Ext. File Share Account`, 4570) stores connection config;
secrets live in IsolatedStorage, never in the database. The wizard page
collects all config in a single step -- no share lookup page.

## Key differences from the Blob connector

- **Directories are real.** CreateDirectory, DeleteDirectory, and
  DirectoryExists are single API calls. No marker file management.
- **File creation is two steps.** CreateFile calls both
  `AFSFileClient.CreateFile` (allocate the resource) and
  `AFSFileClient.PutFileStream` (upload content). The Azure File Share
  REST API requires both.
- **Move is atomic.** MoveFile calls `AFSFileClient.RenameFile` -- a
  native server-side rename. No copy-then-delete race condition.
- **Copy needs a full URI.** CopyFile constructs
  `https://{storageAccount}.file.core.windows.net/{fileShare}/{escapedPath}`
  as the source parameter. The Blob connector does not need this.
- **Path length is enforced.** CheckPath rejects paths over 2048
  characters (Azure File Share API limit).
- **Simpler wizard.** One page with manual text entry for the file share
  name. No container/share lookup interaction.

## What to watch out for

The `DirectoryExists` implementation does not use a metadata call like
`FileExists` does. Instead it calls `ListDirectory` with `MaxResults(1)`
and treats a 404 as "not found." This is because the Azure File Share API
does not expose a directory metadata endpoint the same way it does for
files.

The `CreateFile` two-step pattern means a failure on `PutFileStream`
leaves an allocated but empty file on the share. There is no rollback.

The `Secret` field on the wizard page is a plain `Text` variable marked
`[NonDebuggable]`, not a `SecretText`. It becomes `SecretText` only when
passed into `CreateAccount`. This is the same pattern as the Blob
connector.

## Build and test

CountryCode is `W1`. The test app is
`External File Storage - Azure File Service Connector Tests`
(ID `80ef626f-e8de-4050-b144-0e3d4993a718`), declared in
`internalsVisibleTo` in `app.json`.
