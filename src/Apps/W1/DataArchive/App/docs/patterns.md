# Patterns

## Current patterns

### Manual event subscriber binding

`DataArchiveDbSubscriber` (codeunit 603) uses `EventSubscriberInstance = Manual`, which means its event subscriptions are inactive by default. The provider explicitly calls `BindSubscription` / `UnBindSubscription` to activate them only during archiving sessions. This avoids the performance cost of a global `OnDatabaseDelete` handler firing on every delete in every session.

This is the right pattern when you have a global trigger subscriber that should only be active during specific operations. The key constraint is that the binding is session-scoped -- if the session ends abnormally, the subscription dies with it.

### Provider interface via integration events

Rather than a hard compile-time dependency, the System App discovers the provider through `OnDataArchiveImplementationExists` and `OnDataArchiveImplementationBind` events. This is the standard BC pattern for optional app dependencies: the System App defines the interface and events, the W1 app subscribes and provides the implementation. If the W1 app is uninstalled, the System App gracefully degrades.

### JSON-in-Media serialization

Record data is serialized to JSON and stored in Media fields on `Data Archive Table`. The schema is stored alongside the data as a separate JSON array. This decouples the archive from the live table schema -- if fields are added, renamed, or removed from the source table, the archived data remains readable because it carries its own schema snapshot.

The JSON format uses field numbers as keys (not field names), which makes it compact but means you need the schema array to interpret the data meaningfully.

### Cached buffer with threshold flush

`DataArchiveProvider` maintains an in-memory `Dictionary of [Integer, JsonArray]` buffer indexed by table number. Records accumulate in the buffer until a JsonArray hits 1,000 entries, at which point it flushes to a `Data Archive Table` row and resets. This bounds memory usage during bulk operations like date compression, where millions of records might be archived.

The buffer is per-table: each source table has its own JsonArray, and they flush independently. After `Save()` is called, all remaining buffers are flushed regardless of size.

### Permission-silent filtering on export

The export codeunits check `HasReadPermission()` for each archived table and silently skip those the user cannot access. They count the skipped tables and show a single warning message at the end rather than failing or prompting for each one. This is a deliberate UX choice -- partial export is better than no export.

### RecordRef-based generic archiving

All archiving works through `RecordRef`, not typed records. This lets the same code archive any table without knowing its structure at compile time. The field list is built dynamically from `Field` metadata, filtered to normal (non-computed, non-removed) fields.

## Legacy patterns and known issues

### Cascade delete does not clean up media fields

The `OnDelete` trigger on `Data Archive` (table 600) calls `DataArchiveTable.DeleteAll()` to remove child rows, but does not delete `Data Archive Media Field` rows. Over time, deleted archives leave orphaned media field records. Any cleanup logic you build should account for this by also deleting `Data Archive Media Field` records matching the archive entry number.

### Hardcoded 1,000-record batch limit

The flush threshold is a magic number `1000` embedded in `SaveRecordsToBuffer`. It is not configurable via setup, parameter, or event. If you need a different batch size for performance reasons, you cannot change it without modifying the codeunit. Microsoft docs claim 10,000 -- the actual code uses 1,000.

### MediaSet serialization only captures the first item

In `SaveMediaToArchiveMediaSet`, only `ConfigMediaBuffer."Media Set".Item(1)` is retrieved. If a MediaSet field contains multiple media items, only the first is archived. This is a data loss risk for fields like item images where multiple pictures may exist.

### Session reset side effect

The parameterless `StartSubscriptionToDelete()` calls `SessionSettings.RequestSessionUpdate(false)`, which resets the session. This is a hidden side effect that can be surprising -- callers may not expect that starting archive logging resets their session state. The New Archive page works around this by calling the two-parameter overload with `ResetSession = false`. If you are integrating archive logging into your own code, be explicit about which overload you call.

### No validation on Open()

`DataArchive.Open(ID)` calls `DataArchive.Get(ID)` which will throw a runtime error if the ID does not exist, but there is no validation that the archive is in a usable state. You can open an archive, add records, and call `Save()` to append to an existing archive -- but this is not an explicitly supported scenario and the behavior is fragile.

### Export blob/media resolution is best-effort

During Excel export, when a Blob or Media field value is an integer reference to `Data Archive Media Field`, the exporter calls `DataArchiveMediaField.Get()` to resolve it. If the media field record was orphaned or deleted, the export silently falls through and writes whatever text value was in the JSON (which would be the entry number as a string). There is no error handling for missing media references.
