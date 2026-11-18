# Business Skills

Provides tenant-wide business skill authoring, lifecycle management, text history,
native pages, XML import/export, discovery, and semantic search in
`System.AI.BusinessSkills`.

## Public entry points

| Object | Purpose |
|---|---|
| `Business Skill` | SecretText content reads, revision-aware manual updates, owning-app content updates, lifecycle, availability, and literal discovery |
| `Business Skill Builder` | One-shot manual/app-owned creation and upsert; captures the calling extension's App ID |
| `Business Skill Search` | Semantic search with internal request validation |
| `IBusinessSkillDiscovery` | Literal discovery and canonical skill retrieval contract |

`Business Skill Impl.` owns lifecycle and content validation, encoding, and length
helpers. History capture, restoration, deletion guards, and the platform deletion
subscriber live in `Business Skill Text History`. Both implementations are internal;
consumers must not duplicate validation or history writes. Related objects are grouped
under `src/History`, `src/ImportExport`, and `src/Discovery`.
The platform `Business Skill` virtual table and `Business Skill Status` enum
remain in System; persistent skill storage is not an application table.
`Business Skill Text Version` is the module's tenant-wide history table.

### Builder naming

Initialize the builder with `Initialize(SkillCode, DisplayName, Content)`.
Use `SetDisplayName`, `SetDescription`, `SetContent`, `SetContentLocked`,
`SetContentVersion`, `SetActive`, and `SetManual` before `Create` or `CreateOrUpdate`.
Creation defaults to inactive, app-owned with locked content, and version `v1.0`.
`SetManual(true)` defaults to unlocked content and empty ownership. Explicitly
locking manual content fails. Content parameters use `SecretText`.

For new manual creation, pass a blank code; the platform generates the saved
code. Manual upsert with a supplied code selects that code plus the empty owner
GUID and errors if absent. App-owned upsert uses the caller's manifest App ID
plus code and creates if absent. `CreateOrUpdate(SkillId)` selects an existing
numeric ID, validates its identity, and never creates a missing target.

On update, omitted optional setters preserve stored values. Explicit false,
empty description, or changed values apply or raise the normal validation/
permission error; upsert never implicitly reactivates a skill. Display name and
content passed to Initialize are always supplied values. Changed app-owned
content requires an explicit nonblank version different from the stored label;
version-only changes fail. Manual content changes auto-increment unless an
explicitly changed version is supplied. All terminal methods return the numeric
skill ID, not the skill code.

Use `Business Skill.SetNewContentAndUpdateVersion(SkillCode, Content, ContentVersion)`
for content-only updates owned by the calling app. Its manual overload takes
numeric ID, content, expected SystemId and expected SystemRowVersion.

Use `Business Skill.GetSkill(SkillCode, AppId)` to discover a saved active skill
by its exact code and owner's manifest App ID; an empty App ID selects a manual
skill. The numeric-ID overload remains available. `GetSkillText` reads content
as SecretText; its optional load flag also supports already-loaded temporary records.
Read APIs do not grant additional table permissions.

The builder terminology maps to the existing platform fields: Skill Code to
`Skill ID`, Display Name to `Title`, Content to `Skill Text`, Content Locked to
`Read-Only`, and Content Version to `Version`. Table-field renames and calculated
Manual are a separate change; this module preserves the current storage and
HTTP/NST contracts.

## Behavior and boundaries

- Active skills are available in every company. Search candidates use Title and
  Description only; semantic search requires Azure OpenAI privacy approval for
  everyone. Search targets the actual virtual records and their SystemIds,
  rejects more than 1,000 active candidates, and requests at most 50 results.
  Mapping rechecks current active eligibility and skips deleted/inactive hits.
  There is no catalog-wide snapshot or cross-call freshness guarantee.
- The platform generates manual Skill IDs and stamps app-owned identities.
  Identity, ownership, and normal TableData checks are unchanged. Inherent
  Execute does not grant TableData access to the virtual table.
- Public deletion captures the calling app before delegating. Installed owners
  may delete only their own inactive skills; manual and orphaned deletion requires
  the existing management permission. The internal platform deletion event
  removes history in the same transaction, and cleanup errors propagate.
- Text uses the existing UTF-8 normalization and version rules. Read-Only
  protects content/version, not metadata. Public manual updates preserve expected
  SystemId and SystemRowVersion checks.
- XML export is manual-only; import creates new manual identities atomically.
  Platform NAVDATA omission does not sanitize history or establish BACPAC/SaaS
  export behavior. No history-data migration is provided for this unreleased move.

BusinessIQ retains its HTTP API pages and NST-facing `Business Skill Agent API`
(40224), calling these public facades. Its NST JSON contract and app identity do
not change. System Application does not depend on BusinessIQ or Base Application.
History sensitivity classification lives in the existing Base Application
classification routine.

Content and discovery JSON use SecretText, with narrow non-debuggable stream,
comparison, validation, and UI/API serialization boundaries. This is debugger
protection, not storage encryption or permission elevation. Generated XMLport
BigText storage still needs a protection solution. The NST-facing content method
retains a protected Text return until the platform supports a secret-aware CLR
invocation result; end-to-end SecretText support is therefore not complete.

## Build and tests

The standalone module needs matching System symbols with its app identity
`47f31a2d-b5f8-4b35-956a-59e8edebd13b` in the internal-event friend list.
Aggregate System Application already has that access. Do not expose the event
publicly to work around mismatched symbols.

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
current OnPrem-scoped platform skill symbols block its Cloud build. A matching
public Cloud surface is a separate platform prerequisite, not a packaging fix.

Core tests are 130050-130052; the shared fixture is 130055. Cross-app ownership
uses the separately packaged test library. Runtime tests require current packages
on an explicitly approved test environment: fixture cleanup deletes skills and
history, and HTTP fixtures can commit changes. Compilation alone does not qualify
runtime behavior.

The independent fixture's `DeleteAll` clears skills and history. `InactivateSkill`
and `InactivateAll` use the public lifecycle API and preserve content and history;
the latter skips skills that are already inactive. None of these helpers commits.
