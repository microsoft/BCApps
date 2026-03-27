# Extensibility

## How do I call the archiving API from my own code?

Use the System App's codeunit 600 "Data Archive". Do not reference codeunit 605 directly -- it is `Access = Internal`. The typical pattern:

```
DataArchive.Create('My Batch Job');
// ... set up RecordRef with filters ...
DataArchive.SaveRecords(RecRef);
DataArchive.Save();
```

Call `DataArchiveProviderExists()` first if you need to handle the case where the Data Archive app is not installed. It returns false when no provider has subscribed to the integration events.

For delete-logging scenarios (where you want to capture everything deleted during a section of code), use the subscription approach:

```
DataArchive.Create('My Cleanup');
DataArchive.StartSubscriptionToDelete(true);
// ... perform deletions ...
DataArchive.StopSubscriptionToDelete();
DataArchive.Save();
```

Pass `true` for `ResetSession` if records may have already been deleted in this session before you start logging. Pass `false` if you are confident no prior deletions occurred and want to avoid the session reset side effect.

## How do I replace the archiving implementation?

The provider is discovered at runtime via two integration events on codeunit 600:

- **OnDataArchiveImplementationExists** -- subscribe and set `Exists := true` to indicate your provider is available
- **OnDataArchiveImplementationBind** -- subscribe and set `IDataArchiveProvider` to your implementation instance, then set `IsBound := true`

Your implementation must satisfy the `"Data Archive Provider"` interface defined in `DataArchiveProvider.Interface.al` in the System App. The first subscriber to set `IsBound := true` wins; check the flag on entry and exit immediately if someone else already bound.

This pattern means you can completely replace the archiving storage backend -- for example, writing to external storage instead of the built-in JSON-in-Media tables.

## How do I extend the archive tables?

All three tables (600, 601, 602) are `Extensible = true` and `Access = Public`, so you can add fields via table extensions. All four pages are also extensible. The pages are straightforward list pages with no complex logic, so extending them with additional fields or actions is safe.

Be aware that the export codeunits (608, 609) are `Access = Internal`, so you cannot extend the export logic directly. If you need custom export formats, you would need to read the archive tables and their JSON content yourself.

## How do I add archiving to a date compression batch job?

The pattern used by existing date compression jobs:

1. Check `DataArchive.DataArchiveProviderExists()` to see if archiving is available
2. Show an "Archive Deleted Entries" toggle on the options page
3. If the user enables it, call `DataArchive.Create()` before the compression loop
4. Use `DataArchive.SaveRecords()` with filters matching the records about to be deleted
5. Call `DataArchive.Save()` after the compression completes

The critical point is to save records before deleting them. `SaveRecords` iterates the filtered set and buffers them; the deletion happens after.

## How does the global trigger integration work?

When `StartSubscriptionToDelete` is called, the provider binds `DataArchiveDbSubscriber` (codeunit 603, `EventSubscriberInstance = Manual`) to the session. This subscribes to two global trigger events:

- `GetDatabaseTableTriggerSetup` -- returns `OnDatabaseDelete = true` for every table except the three archive tables
- `OnDatabaseDelete` -- forwards the deleted RecordRef to the provider's `SaveRecord`

The subscriber filters out temporary records and the archive tables themselves. The binding is session-scoped and automatically cleaned up when the codeunit variable goes out of scope, but you should always call `StopSubscriptionToDelete` explicitly for clarity.

## What permissions are needed?

The `DataArchive - View` permission set grants read access to the archive tables and execute access to the pages and export codeunits. The `DataArchive - Read` permission set is similar but with broader read access. The `DataArchive - Objects` permission set grants execute access to all objects in the app.

For creating archives programmatically, the calling code needs RIMD on all three archive tables. The `Data Archive Table` and `Data Archive Media Field` tables declare their own `Permissions` property granting RIMD on all three tables, so code running through RecordRef operations on these tables has the necessary permissions.
