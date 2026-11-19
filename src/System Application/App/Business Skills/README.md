# Business Skills

Provides tenant-wide business skill authoring, lifecycle management, content history,
native pages, and XML import/export in
`System.AI.BusinessSkills`.

## Public entry points

| Object | Purpose |
|---|---|
| `Business Skill` | SecretText content reads, revision-aware manual updates, owning-app content updates, lifecycle, and availability |
| `Business Skill Builder` | One-shot manual/app-owned creation; captures the calling extension's App ID |

`Business Skill Impl.` owns lifecycle and content validation, encoding, and length
helpers. History capture, restoration, deletion guards, and the platform deletion
subscriber live in `Business Skill Content History`. Both implementations are internal;
consumers must not duplicate validation or history writes. Related objects are grouped
under `src/History` and `src/ImportExport`.
The platform `Business Skill` virtual table and `Business Skill Status` enum
remain in System; persistent skill storage is not an application table.
`Bus Skill Content Version` is the module's tenant-wide history table.

### Builder naming

Initialize the builder with `Initialize(SkillCode, DisplayName, Content)`.
Use `SetDisplayName`, `SetDescription`, `SetContent`, `SetContentLocked`,
`SetContentVersion`, `SetActive`, and `SetManual` before `Create`.
Creation defaults to inactive, app-owned with locked content, and version `v1.0`.
`SetManual(true)` defaults to unlocked content and empty ownership. Explicitly
locking manual content fails. Content parameters use `SecretText`.

For new manual creation, pass a blank code; the platform generates the saved
code. App-owned creation uses a supplied code; the platform stamps the calling
app's manifest App ID. Duplicate owner/code pairs fail. `Create` returns the
numeric skill ID, not the skill code.

The public builder is creation-only. Upsert helpers remain internal, as do
native page updates that preserve the page's SystemId/SystemRowVersion baseline.
Do not replace a page update with a fresh-read upsert.

Use `Business Skill.SetNewContentAndUpdateVersion(SkillCode, Content, ContentVersion)`
for content-only updates owned by the calling app. Changed app-owned content
requires an explicit nonblank version different from the stored label;
version-only changes fail. Its manual overload takes numeric ID, content,
expected SystemId and expected SystemRowVersion, and advances the content version
when instructions change. Content updates do not implicitly activate a skill.

`Business Skill.GetContent` reads content
as SecretText; its optional load flag also supports already-loaded temporary records.
Read APIs do not grant additional table permissions.

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
  the existing management permission. Automatic content-history cleanup on skill
  deletion is not enabled; deleted skills leave their history entries behind.
- Content uses the existing UTF-8 normalization and version rules. The platform
  authorizes app-owned content/version and lock changes; AL does not reject them
  solely because Read-Only is set. Owner updates while locked and explicit owner
  unlocking require the corresponding platform update. Content updates preserve
  the lock unless explicitly changed. Public manual updates preserve expected
  SystemId and SystemRowVersion checks.
- XML export is manual-only; import creates new manual identities atomically.
  The instruction element is `Content`. The retired `SkillText` element is rejected;
  this is an intentional breaking change to the unreleased format, with no alias.
  Platform NAVDATA omission does not sanitize history or establish BACPAC/SaaS
  export behavior. No history-data migration is provided for this unreleased move.

BusinessIQ retains discovery/search, its HTTP API pages and NST-facing `Business Skill Agent API`
(40224), calling these public facades. Its NST JSON contract and app identity do
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

The standalone module does not subscribe to the internal platform deletion event.
Restoring automatic history cleanup requires matching System symbols with its app
identity `47f31a2d-b5f8-4b35-956a-59e8edebd13b` in the internal-event friend list.
Keep the event internal. The deletion-history and cleanup-rollback regressions
require that integration and are not satisfied by the current implementation.

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

Core tests are 130050-130051; the shared fixture is 130055. Discovery/search tests
are BusinessIQ codeunit 140282. Cross-app ownership
uses the separately packaged test library. Runtime tests require current packages
on an explicitly approved test environment: fixture cleanup deletes skills and
history, and HTTP fixtures can commit changes. Compilation alone does not qualify
runtime behavior.

The independent fixture's `DeleteAll` clears skills and history. `InactivateSkill`
and `InactivateAll` use the shared lifecycle implementation and preserve content and history;
the latter skips skills that are already inactive. None of these helpers commits.
