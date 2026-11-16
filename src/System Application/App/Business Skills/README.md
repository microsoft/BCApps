# Business Skills

Provides tenant-wide business skill authoring, lifecycle management, text history,
native pages, XML import/export, discovery, and semantic search in
`System.AI.BusinessSkills`.

## Public entry points

| Object | Purpose |
|---|---|
| `Business Skill` | Manual creation, revision-aware updates, activation/deactivation, deletion, availability, and literal discovery |
| `Business Skill Builder` | One-shot app-owned creation and upsert; captures the calling extension's identity |
| `Business Skill Text` | Text reading, stream encoding, and text-length limit |
| `Business Skill Search` | Semantic search and request validation |
| `IBusinessSkillDiscovery` | Literal discovery and canonical skill retrieval contract |

Management, text/history implementations, XML orchestration, and search projection
are internal. Consumers must not duplicate validation or history writes.
The platform `Business Skill` virtual table and `Business Skill Status` enum
remain in System; persistent skill storage is not an application table.
`Business Skill Text Version` is the module's tenant-wide history table.

### Builder naming

Initialize the builder with `Initialize(SkillCode, DisplayName, Content)`.
Use `SetDisplayName`, `SetDescription`, `SetContent`, `SetContentLocked`,
`SetContentVersion`, and `SetActive` before `Create` or `CreateOrUpdate`.
The builder defaults to inactive with locked content; an omitted content version
defaults to `v1.0` on creation. Both creation methods return the numeric skill ID,
not the app-scoped skill code.

The builder terminology maps to the existing platform fields: Skill Code to
`Skill ID`, Display Name to `Title`, Content to `Skill Text`, Content Locked to
`Read-Only`, and Content Version to `Version`. Table-field renames and calculated
Manual are a separate change; this module preserves the current storage and
HTTP/NST contracts.

## Behavior and boundaries

- Active skills are available in every company. Search candidates use Title and
  Description only; semantic search requires Azure OpenAI privacy approval for
  everyone. Candidate freshness is checked against the platform rowversion.
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
(40224), calling these public facades. Its JSON contracts and app identity do not
change. System Application does not depend on BusinessIQ or Base Application.
History sensitivity classification lives in the existing Base Application
classification routine.

## Build and tests

The standalone module needs matching System symbols with its app identity
`47f31a2d-b5f8-4b35-956a-59e8edebd13b` in the internal-event friend list.
Aggregate System Application already has that access. Do not expose the event
publicly to work around mismatched symbols.

Compile the module and `Test Library/Business Skills`, then `Test/Business Skills`.
Shipped NAV consumers use aggregate System Application and System Application
Test Library. Qualification therefore also requires aggregate builds, the affected
Base Application classification, and retained BusinessIQ/SalesValidationAgent3P
consumers against those updated packages.

Core tests are 130050-130052; the shared fixture is 130055. Cross-app ownership
uses the separately packaged test library. Runtime tests require current packages
on an explicitly approved test environment: fixture cleanup deletes skills and
history, and HTTP fixtures can commit changes. Compilation alone does not qualify
runtime behavior.
