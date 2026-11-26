# Business Skills

Provides tenant-wide business skill authoring, lifecycle management, content history,
native pages, and XML import/export in
`System.AI.BusinessSkills`.

## Public entry points

| Object | Purpose |
|---|---|
| `Business Skill` | Stored SecretText content reads, owning-app content/metadata updates, lifecycle, and availability |
| `Business Skill Builder` | One-shot app-owned creation; captures the calling extension's App ID |

`Business Skill Impl.` owns lifecycle and content validation, encoding, and length
helpers. History capture, restoration, and version-deletion guards live in
`Business Skill Content History`. History is recorded and displayed only for manual
skills. Page deletion and the public `Delete` facade remove manual history in the same
transaction as the skill. No deletion-event subscriber is registered; raw
`Record.Delete/DeleteAll` calls bypass this cleanup. Both implementations are internal;
consumers must not duplicate validation or history writes. Related objects are grouped
under `src/History` and `src/ImportExport`.
The platform `Business Skill` virtual table and `Business Skill Status` enum
remain in System; persistent skill storage is not an application table.
`Bus Skill Content Version` is the module's tenant-wide history table.

### Builder naming

Initialize the builder with `Initialize(SkillCode, DisplayName, Content)`.
Use `SetDisplayName`, `SetDescription`, `SetContent`, `SetContentLocked`,
`SetContentVersion`, and `SetActive` before `Create`.
Creation defaults to inactive, app-owned with locked content, and version `v1.0`.
The internal `SetManual(true)` supports native authoring and approved friend apps;
it defaults to unlocked content and empty ownership. Explicitly locking manual
content fails. Content parameters use `SecretText`.

For new manual creation, pass a blank code; the platform generates the saved
code. App-owned creation uses a supplied code; the platform stamps the calling
app's manifest App ID. Duplicate owner/code pairs fail. `Create` returns the
numeric skill ID, not the skill code.
Clear the builder variable before initializing it for another skill.

The public builder is creation-only. Upsert helpers remain internal. The numeric
`CreateOrUpdate(0)` overload creates a new skill and returns its generated ID;
nonzero IDs must already exist and match the builder's identity.
Native page updates preserve the page's SystemId/SystemRowVersion baseline.
Do not replace a page update with a fresh-read upsert.

Use `Business Skill.SetNewContentAndUpdateVersion(SkillCode, Content, ContentVersion)`
for content-only updates owned by the calling app. Changed app-owned content
requires an explicit nonblank version different from the stored label;
version-only changes fail. Version labels are free text, not ordered versions.
Identical content and version are a no-op. The internal manual overload takes
numeric ID, content, expected SystemId and expected SystemRowVersion, and
automatically advances the content version when instructions change. Identical
manual content preserves revision and history. Content updates do not implicitly
activate a skill.

Use `Business Skill.UpdateMetadata(SkillCode, DisplayName, Description)` to
maintain the calling app's existing skill, including inactive or content-locked
skills. It preserves identity, content, version, history, status and lock state;
identical metadata is a no-op. An empty description clears it. Missing or
foreign-owned codes fail, and active skills still require a nonblank title.
Normal TableData and management permissions apply. This is not a replacement
for revision-aware native page updates.

`Business Skill.GetContent` loads stored content and returns SecretText.
Internal `GetContentFromBuffer` reads already-loaded or unsaved content without
reloading it, including temporary search-result snapshots.
Read APIs do not grant additional table permissions.
`Activate` and `Deactivate` have no return value; errors propagate normally.

System Application and the standalone module grant `Business IQ`
(`b7e3a1d0-4f8c-4e2a-9c6b-1d3e5f7a9b0c`, publisher `Microsoft`)
internal access for manual API creation/update and buffered search-result reads.
AL friendship is app-wide, not restricted to these methods; consumers should use
these facade methods rather than implementation objects. It does not grant
TableData permissions or bypass native authorization. External tests use
`Library - Business Skill` rather than receiving additional friendship.

The builder terminology maps to the existing platform fields: Skill Code to
`Skill ID`, Display Name to `Title`, Content to `Skill Text`, Content Locked to
`Read-Only`, and Content Version to `Version`. Table-field renames and calculated
Manual are a separate change. The history table uses `Content` and `Content Version`,
retaining its field IDs and types; its numeric `Skill ID` remains the relationship key.
Native storage fields and the NST contract are unchanged.

## Behavior and boundaries

- Active skills are available in every company. Literal discovery, exact
  identity lookup, `IBusinessSkillDiscovery`, and semantic search remain in
  NAV BusinessIQ (`Microsoft.BusinessSkill`), not this module.
- The platform generates manual Skill IDs and stamps app-owned identities.
  Identity, ownership, and normal TableData checks are unchanged. Inherent
  Execute does not grant TableData access to the virtual table.
- Public deletion captures the calling app before delegating. Installed owners
  may delete only their own inactive skills; manual and orphaned deletion requires
  the existing management permission. Active-skill deletion reports an error with
  an **Open skill** action; it does not automatically deactivate the skill.
  Both native pages reuse the same deletion operation as the facade, including
  manual-history cleanup and rollback if cleanup fails. Raw table deletes remain
  outside that cleanup contract.
- Programmatic creation and updates do not record history. Existing programmatic
  history is neither migrated nor purged, but cannot be opened through the history
  page or restored. Copying app-owned content and downloading current content read
  the stored skill BLOB rather than depending on history. Manual copy/import/restore
  retain their version-history behavior.
- Atomic mutation entry points use `CommitBehavior::Ignore`: nested explicit commits
  are suppressed, not performed. A stricter caller `Error` scope still applies.
  Implicit `Codeunit.Run` commits are not covered by this attribute.
- Content uses the existing UTF-8 normalization and version rules. The platform
  authorizes app-owned content/version and lock changes; AL does not reject them
  solely because Read-Only is set. Owner updates while locked and explicit owner
  unlocking require the corresponding platform update. Content updates preserve
  the lock unless explicitly changed. Internal manual updates preserve expected
  SystemId and SystemRowVersion checks.
- XML export is manual-only; import creates new manual identities atomically.
  The instruction element is `Content`. The retired `SkillText` element is rejected;
  this is an intentional breaking change to the unreleased format, with no alias.
  Platform NAVDATA omission does not sanitize history or establish BACPAC/SaaS
  export behavior. No history-data migration is provided for this unreleased move.

BusinessIQ retains discovery/search, its HTTP API pages and NST-facing `Business Skill Agent API`
(40224), calling the facades and the internal methods described above. Its NST JSON contract and app identity do
not change. BusinessIQ's HTTP/discovery content property is now `content`, not
`skillText`; its `skillContent` navigation property remains unchanged.
System Application does not depend on BusinessIQ or Base Application.
History sensitivity classification lives in the existing Base Application
classification routine.

Content and discovery JSON use SecretText, with narrow non-debuggable stream,
comparison, validation, and UI/API serialization boundaries. This is debugger
protection, not storage encryption or permission elevation. Generated XMLport
BigText storage still needs a protection solution. The NST-facing content method
retains a protected Text return until the platform supports a secret-aware CLR
invocation result; end-to-end SecretText support is therefore not complete.

## Build and tests

The standalone module does not subscribe to a platform deletion event. Page/facade
manual-history cleanup needs no additional System-symbol friendship. Event-based
cleanup for raw table deletion is deferred.

Compile aggregate System Application, then the independent `Business Skills Test
Library` under `src/Tools/Test Framework/Test Libraries/LibraryBusinessSkill`,
then the core and aggregate tests. Both the library and core test app depend on
aggregate System Application; the standalone product module is compiled
separately, not installed alongside the aggregate.

The fixture library is registered in build projects/groups and country settings.
Its Financials membership includes it in the SaaS extension manifest with
Sandbox-only availability, following Application Test Library. NAV's explicit
BCApps test-build order includes it before the test aggregates. It is not bundled
inside System Application Test Library. The library remains Cloud-targeted;
it uses the internal, record-free `Business Skill Test Impl.` through System
Application's `internalsVisibleTo` entry. The helper retains the fixture's indirect
table permissions and reuses the builders and lifecycle implementation. The
platform skill table remains OnPrem-scoped; no public destructive API is added.

Core and builder tests are 130050-130051; native UI scenarios are isolated in
130052. All three are integration test codeunits; the shared fixture is 130055.
Discovery/search tests are BusinessIQ codeunit 140282. Cross-app ownership uses
the separately packaged test library. Runtime tests require current packages
on an explicitly approved test environment: fixture cleanup deletes skills and
history, and HTTP fixtures can commit changes. Compilation alone does not qualify
runtime behavior.

The independent fixture's revision-aware `SetNewContentAndUpdateVersion` updates
manual content through the internal facade, retaining expected identity/revision
checks, automatic version increments, and identical-content no-ops.
Its `DeleteAll` clears skills and history. `InactivateSkill`
and `InactivateAll` use the shared lifecycle implementation and preserve content and history;
the latter skips skills that are already inactive. None of these helpers commits.
