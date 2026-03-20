# Patterns

## Marker file for directory simulation

Azure Blob Storage is flat -- blobs live in a single namespace with `/` as a conventional (but meaningless) separator. The connector simulates directories by creating a sentinel blob named `BusinessCentral.FileSystem.txt` at the directory path. Creating directory `invoices/2024/` actually uploads `invoices/2024/BusinessCentral.FileSystem.txt` with a human-readable explanation as content.

This has consequences worth knowing:

- If something outside BC deletes the marker blob, the directory vanishes from BC's perspective, but files at that path remain in blob storage. They become orphans that BC cannot navigate to (because the parent "directory" no longer exists in listings).
- DirectoryExists does not look for the marker specifically. It does `ListBlobs` with the path as prefix and `MaxResults(1)`. Any blob at that prefix makes the directory "exist." So a directory with files but no marker still "exists" as far as DirectoryExists is concerned -- the inconsistency only shows up in ListDirectories, which filters by `Resource Type::Directory`.
- DeleteDirectory refuses to delete non-empty directories. It lists files and subdirectories, excludes the marker file from the count, and errors if anything remains. Then it deletes the marker blob. This means you cannot recursively delete a directory tree in one call.

## Copy-then-delete for move

`MoveFile()` in `ExtBlobStoConnectorImpl.Codeunit.al` implements move as `CopyBlob` followed by `DeleteBlob`. Azure Blob Storage has no native move/rename operation, so this is the only option.

The failure mode matters: if the copy succeeds but the delete fails, the file exists at both source and target paths. The codeunit raises an error from the failed delete, so the caller knows something went wrong, but the copy is already committed and will not be rolled back. The caller would need to manually clean up the target copy. There is no retry or compensation logic.

This also means MoveFile is not constant-time. CopyBlob for a large blob can take significant time because Azure performs a server-side copy, and the operation blocks until completion.

## Lazy secret retrieval

Secrets are fetched from IsolatedStorage on every single operation call via `InitBlobClient()`. The codeunit does not cache the secret across calls -- each invocation of a file operation does a full `IsolatedStorage.Get()`. This is intentional: it avoids holding secrets in memory longer than necessary, and it means a secret rotation (updating the secret via the account page) takes effect immediately without needing to invalidate any cache.

The `GetSecret()` procedure on the table errors immediately if the secret is not found in IsolatedStorage, rather than returning an empty value. This fail-fast behavior surfaces misconfiguration clearly instead of producing cryptic Azure auth failures downstream.

## Environment cleanup hook

The `EnvironmentCleanup_OnClearCompanyConfig` event subscriber is a safety mechanism for sandbox environments. When a sandbox is created from production, this event fires for each company. The subscriber sets `Disabled = true` on all non-disabled accounts.

The key insight is that IsolatedStorage contents survive the environment copy -- production secrets are present in the sandbox. Without this hook, a sandbox could inadvertently perform operations against production Azure storage. The `Disabled` flag acts as a circuit breaker: `InitBlobClient()` checks it before every operation and errors immediately for disabled accounts.

The subscriber filters to only non-disabled accounts (`SetRange(Disabled, false)`) and uses `ModifyAll` for efficiency. It does not distinguish between environment types -- any sandbox creation disables all accounts regardless of whether the source was production or another sandbox.

## Auth strategy selection

`InitBlobClient()` uses a case statement on the account's authorization type to select between SAS token and shared key authentication. SAS tokens go through `UseReadySAS()` (the token is used as-is), while shared keys go through `CreateSharedKey()` (the SDK handles HMAC signing). This is a simple strategy pattern without the overhead of a separate strategy interface -- the two-case switch is sufficient given there are only two auth types.

The same pattern repeats in `LookUpContainer()` for the container name lookup during account setup, where it initializes an `ABS Container Client` instead of an `ABS Blob Client`.
