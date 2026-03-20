# Patterns

## Interface-based connector registration

The connector registers itself with the framework entirely through an
enum extension. `ExtFileShareConnector.EnumExt.al` adds the `"File
Share"` value to the `"Ext. File Storage Connector"` enum and uses the
`Implementation` property to bind it to `"Ext. File Share Connector
Impl"`. No factory, no registration API, no event subscription -- the
enum is the registry. This is the standard BC pattern for pluggable
implementations and is shared with the Blob, SFTP, and SharePoint
connectors.

## GUID-keyed secret indirection

Credentials never touch a database table. The account table stores only a
GUID in the `Secret Key` field. The actual secret lives in
IsolatedStorage at company scope, keyed by that GUID. This indirection
means the secret is inaccessible to SQL queries, backup restores, or
configuration package exports. The OnDelete trigger cleans up the
IsolatedStorage entry. `SetSecret` is idempotent -- it generates the GUID
once, then overwrites the value in place on subsequent calls.

This is identical to the Blob connector's approach and is the recommended
BC pattern for any credential that must survive data export scenarios.

## Native directory operations (File Share vs Blob)

The most architecturally significant pattern in this connector is what it
does *not* do. The Blob connector has to simulate directories using
marker files because Azure Blob Storage is a flat key-value store. This
connector operates against Azure File Shares, which have a real
hierarchical file system. So `CreateDirectory`, `DeleteDirectory`, and
`DirectoryExists` are trivial single-call operations.

If you are reading this connector alongside the Blob connector, the
absence of marker file management is the main thing to notice. It
simplifies the code dramatically and eliminates an entire class of
consistency bugs (orphaned markers, race conditions on directory
deletion).

## Two-step file creation

Azure File Share REST API requires files to be created in two calls:
first `CreateFile` to allocate the resource on the server (this tells
Azure the expected file size), then `PutFileStream` to upload the actual
content. This is different from Blob Storage's single-call upload and is
a consequence of how Azure File Shares implement SMB-compatible file
semantics.

The pattern introduces a failure window between the two calls. If
allocation succeeds but upload fails, an empty file remains on the share.
The connector does not attempt cleanup in this case.

## Atomic rename for move

`MoveFile` calls `AFSFileClient.RenameFile` -- a native server-side
rename that is atomic. The Blob connector must do copy-then-delete for
the same operation because Azure Blob Storage does not support rename.
The copy-then-delete approach has a failure window where both source and
target exist, or where the copy succeeds but the delete fails, leaving a
duplicate. The File Share connector avoids this entirely.

## 404-string matching for existence checks

Both `FileExists` and `DirectoryExists` detect "not found" by checking
whether the error message string contains `'404'`. This is not
status-code inspection -- it is string matching on the error text
returned by the AFS SDK. The pattern is fragile in theory (a change to
the SDK's error message format would break it) but is used consistently
across all connectors in the framework, so it is effectively a
convention.

## Lazy client initialization

Every public operation calls `InitFileClient` to construct an
`AFS File Client` from scratch. There is no cached client, no connection
pool. Each operation loads the account record, retrieves the secret,
builds the auth object, and initializes the client. This is
stateless-by-design -- it keeps the codeunit free of instance state and
avoids stale-credential bugs, at the cost of repeated IsolatedStorage
reads.

## Environment cleanup hook

The codeunit subscribes to `OnClearCompanyConfig` from the `Environment
Cleanup` codeunit. When a sandbox is created, the subscriber sets
`Disabled = true` on all accounts via `ModifyAll`. This prevents sandbox
environments from accidentally connecting to production storage accounts.
The admin can manually re-enable accounts on the card page after
verifying the credentials are appropriate for the sandbox context.
