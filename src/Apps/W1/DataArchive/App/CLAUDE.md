# Data Archive

Data Archive provides a framework for snapshotting database records to JSON before they are deleted. Its primary consumers are the 13 date compression batch jobs in Business Central, which optionally archive ledger entries before compressing them. The app sits behind a two-layer architecture: the System App exposes a public facade (codeunit 600 "Data Archive"), and this W1 app provides the actual implementation (codeunit 605 "Data Archive Provider") discovered at runtime through integration events.

## Quick reference

- **ID range**: 600-633
- **Namespace**: System.DataAdministration
- **Target**: Cloud
- **No dependencies** beyond the System App

## How it works

The System App's codeunit 600 is the only public API surface. It delegates every call through the "Data Archive Provider" interface. At runtime, codeunit 605 in this app subscribes to two integration events -- `OnDataArchiveImplementationExists` and `OnDataArchiveImplementationBind` -- to register itself as the provider. This means the System App has zero compile-time dependency on this W1 app; if the app is uninstalled, archiving silently becomes a no-op.

There are two usage modes. In **programmatic mode**, callers (like date compression) call `Create(Description)`, then `SaveRecord`/`SaveRecords` to buffer records, then `Save()` to flush. In **manual recording mode**, a user opens the "Data Archive - New Archive" page, clicks Start Logging, and the app binds `DataArchiveDbSubscriber` to the global `OnDatabaseDelete` trigger. Every non-temporary record deleted in that session is automatically captured. The user clicks Stop Logging (or closes the page) to flush and save.

Records are serialized to JSON -- a schema array of field metadata plus a data array of record values keyed by field number. Blob, Media, and MediaSet fields are extracted into separate `Data Archive Media Field` records and replaced with entry number references in the JSON. The serialization buffer flushes to a new `Data Archive Table` row every 1,000 records, so a single source table may produce multiple archive table rows.

The archive is effectively append-only. There is no restore functionality -- the only way to get data out is exporting to Excel or CSV. Export applies permission checks at read time, silently skipping tables the user cannot access.

## Structure

- `src/` -- all AL source: 3 tables, 4 pages, 3 codeunits (provider, db subscriber, two exporters)
- `Permissions/` -- permission sets (objects, read, view)

## Documentation

- [docs/data-model.md](docs/data-model.md) -- table hierarchy, JSON serialization format, cascade delete behavior
- [docs/business-logic.md](docs/business-logic.md) -- recording modes, buffer flushing, export logic
- [docs/extensibility.md](docs/extensibility.md) -- provider interface, event subscriber binding, integration points
- [docs/patterns.md](docs/patterns.md) -- design patterns used and legacy patterns to watch for

## Things to know

- The archive is append-only: no restore, no update, export only.
- A single source table can produce multiple `Data Archive Table` rows because of the 1,000-record batch flush. Microsoft docs say 10,000 -- the code says 1,000.
- `StartSubscriptionToDelete()` (the parameterless overload) implicitly calls `SessionSettings.RequestSessionUpdate(false)`, which resets the session. The `DataArchiveNewArchive.Page.al` page carefully passes `false` for `ResetSession` to avoid this.
- Deleting a `Data Archive` header cascades to `Data Archive Table` rows but does NOT cascade to `Data Archive Media Field` rows. This is an orphan risk.
- Permission checks happen only on export, not on archive creation. Archiving captures everything regardless of the current user's read permissions.
- The archive tables themselves (600, 601, 602) are explicitly excluded from archiving to prevent infinite recursion.
- `DataArchiveDbSubscriber` uses `EventSubscriberInstance = Manual` -- it is bound/unbound dynamically per session, so it only fires during active recording sessions, not globally.
- JSON stores field values keyed by field number, not field name. Schema evolution is handled by storing the schema snapshot alongside the data.
- The CSV exporter uses locale-aware separators: semicolon when the locale uses comma as decimal separator, comma otherwise.
- `DataArchiveProvider` (codeunit 605) is `Access = Internal` -- external code must go through the System App facade (codeunit 600).
