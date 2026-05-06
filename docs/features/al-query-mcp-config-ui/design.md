# Design: AL Query MCP Server – Configuration Page UX

> **Scope of this document**
> This is a **UX prototype / mock design**, not a full implementation spec.
> The goal is to visualize how the existing MCP Configuration page can host a new
> "AL Query" MCP server alongside the current API-tool experience, so the team
> can react to the shape before committing to platform / runtime work.

- **Tracking**: Fixes AB#631012 ("[MCP] Update the MCP Configuration page UI to support AL Query MCP server")
- **Parent slice**: AB#604869 ("[MCP] Generic Data Analysis (dynamic query) MCP Server – Iteration 1")
- **Related siblings**: AB#631010 (eval dataset), AB#631011 (SKILL.md for agents)
- **Module**: `src/System Application/App/MCP`
- **Last Updated**: 2026-05-05 (post-implementation iterations — see Appendix C)

---

## 1. Introduction / Overview

Business Central is gaining a second MCP server: the **AL Query MCP server**. Where the existing MCP server exposes curated **API pages and API queries** as tools, the AL Query server lets an MCP client **author and execute AL queries on demand** — letting agents perform joins, aggregates, and ad-hoc analytics across BC's data model that no fixed API endpoint covers.

The runtime sits in the platform (out of scope for this app). What this app owns is the **admin experience** for turning that capability on, off, and configuring it per MCP configuration. Today's MCP Configuration page (`page 8351 "MCP Config Card"`) was designed exclusively around API page/query tools. We need to extend it so an admin can:

- Decide, **per configuration**, whether the AL Query server is exposed.
- See, in the existing System Tools list, which built-in tools come from which server.
- Mix or isolate API-tool exposure and AL-Query exposure in the same config (or run an AL-Query-only config).

Because the runtime is still being defined, this design treats AL Query sub-settings as **placeholders/mocks** so reviewers can see UX shape without locking the team into specific knobs.

## 2. Goals

1. Add a clear, opt-in toggle to the MCP Configuration card that exposes the AL Query MCP server for that configuration.
2. Reuse the existing System Tools list, but make it obvious which tools come from "API Tools" vs. "AL Query".
3. Preserve full backward compatibility — no behavioral change for any existing configuration on upgrade.
4. Keep the AL-Query toggle independent of the existing Static / Dynamic Tool Mode (orthogonal axes).
5. Provide a placeholder UI surface for future AL-Query sub-settings so reviewers can react to shape now.
6. Round-trip the new flag through Export / Import without breaking existing JSON consumers.

## 3. User Stories

- **US-1 (Admin – enable):** As an MCP admin, I want to enable the AL Query server on a specific configuration so that agents using that configuration can author and run ad-hoc AL queries against BC data.
- **US-2 (Admin – isolate):** As an MCP admin, I want to create an AL-Query-only configuration (no API tools at all) so I can grant a specific agent dynamic-query capability without also exposing API endpoints.
- **US-3 (Admin – inspect):** As an MCP admin reviewing a configuration, I want to see at a glance which built-in MCP system tools come from the API server and which come from the AL Query server, so I understand what an agent will see when it connects.
- **US-4 (Admin – discover):** As an MCP admin who hasn't enabled AL Query, I want a clear, descriptive toggle on the card (with tooltip and "About" guidance) so I can decide whether to opt in.
- **US-5 (Admin – preserve):** As an MCP admin upgrading from a prior version, I want all my existing configurations to behave exactly as before, with AL Query off by default.
- **US-6 (Admin – portable):** As an MCP admin exporting a configuration to share with another tenant, I want the AL Query toggle (and its mock sub-settings) to round-trip in the exported JSON.

## 4. Functional Requirements

> Numbered for traceability. Items marked **[MOCK]** are deliberately under-specified — they exist to demonstrate the UX surface area, and concrete values/wording will be revisited once the platform side firms up.

### Card page layout (`page 8351 "MCP Config Card"`)

1. The card MUST include a new fast-tab / group titled **"AL Query Server"** placed **after** the existing General group and Tool Modes group, and **before** the System Tools / Available Tools parts.
2. The first field in the new group MUST be a boolean **"Enable AL Query Tools"** (working name `EnableALQuery`), defaulting to off, editable only when the configuration is not the implicit default and not Active (matching existing field-edit conventions).
3. When **"Enable AL Query Tools"** is OFF, **all** sub-settings in the AL Query group MUST be hidden or disabled.
4. When **"Enable AL Query Tools"** is ON, the group MUST display **mock sub-settings** so reviewers can react to shape:
   - **[MOCK]** "Maximum Rows per Query" — integer, placeholder default (e.g., `10000`).
   - **[MOCK]** "Query Timeout (seconds)" — integer, placeholder default (e.g., `30`).
   - **[MOCK]** "Allowed Object Scope" — option / lookup placeholder (e.g., `All Read-Only Objects` / `Configured API Tools Only` / `Custom...`).
   - These fields MUST be marked in tooltips as **preview / subject to change**.
5. A short paragraph (similar in tone to the existing `StaticToolModeLbl` / `DynamicToolModeLbl`) MUST describe what enabling AL Query exposes to clients.

### System Tools list (`page 8365 "MCP System Tool List"`)

6. The visibility condition for the System Tools part MUST become: **show when Dynamic Tool Mode is on OR when AL Query is on** (today: only when Dynamic is on).
7. The temporary table `MCP System Tool` MUST gain a new column **"Server"** (or "Source") — an option/text field — populated with at least: `API Tools`, `AL Query`.
8. The list MUST surface that column as a visible field, **grouped/sorted by Server**, so admins see tools clustered by source.
9. When AL Query is ON and Dynamic Tool Mode is OFF, the list MUST show only AL-Query rows. When both are on, it MUST show both groups. When neither, the part is hidden (FR6).
10. AL-Query system-tool rows are **read-only** (consistent with existing system tools) — no edit/delete actions.

### List page (`page 8350 "MCP Config List"`)

11. The List page MUST display a new column **"AL Query"** (boolean), to the right of `DiscoverReadOnlyObjects`, so admins can scan which configurations have AL Query enabled.
12. The column does not require its own filter/view; the existing "Active configurations" view stays unchanged.

### Configuration table (platform-side, called out for traceability)

13. The platform `MCP Configuration` table MUST gain a boolean field for the AL Query toggle (working name `EnableALQuery`). Mock sub-settings (FR4) get corresponding fields. *(Implementation lives in the platform; this app reads the fields.)*
14. Default value MUST be `false` for: existing configurations after upgrade, new configurations created via UI or codeunit API, and the implicit default configuration.
15. There MUST be no validation interaction between `EnableALQuery` and `EnableDynamicToolMode` / `DiscoverReadOnlyObjects` — they are independent axes.

### Public API (`codeunit 8350 "MCP Config"`)

16. Add a new public procedure (signature mock):
    ```al
    /// <summary>Enables or disables the AL Query MCP server for the specified configuration.</summary>
    procedure EnableALQuery(ConfigId: Guid; Enable: Boolean)
    ```
17. Existing procedures MUST continue to function unchanged; no obsoletions for this iteration.
18. Mock sub-settings (FR4) do NOT need public-API setters in this prototype — they're page-only placeholders so far.

### Export / Import

19. The exported JSON (see `MCPConfigImplementation.ExportConfiguration`) MUST include the new `enableALQuery` boolean (working JSON property name).
20. The importer MUST accept JSON with or without the new property; absence MUST default to `false` to keep older exports importable.

### Telemetry (light touch for prototype)

21. The configuration-modified telemetry (existing `LogConfigurationModified`) MUST add a dimension `ALQueryEnabled` reflecting the new state, and `OldALQueryEnabled` / `NewALQueryEnabled` when the field changes — mirroring the pattern used for `DynamicToolMode`.

### Permissions

22. The new field MUST be covered by the same permission sets that govern the rest of `MCP Configuration` (`MCPRead`, `MCPObjects`, `MCPAdmin`); no new permission sets are needed.

## 5. Non-Goals (Out of Scope)

The following are deliberately **not** part of this design:

- **AL Query runtime / server-side implementation.** Compiling and executing AL queries is platform work — outside the System Application.
- **The "compile AL query" / "run AL query" tools themselves** (their names, JSON schemas, parameters). They will appear in the System Tools list as data; their definition lives in the platform.
- **The eval / benchmark dataset** — AB#631010.
- **The agent-facing SKILL.md** — AB#631011.
- **Production-ready sub-settings.** The mock fields in FR4 exist to show shape; final knobs (rate limits, scoping, RLS interactions, audit trails) are out of scope for this iteration.
- **Connection-string / endpoint changes.** Per design decision, the AL Query server is reached via the same MCP endpoint as the API server. The Connection String dialog is unchanged.
- **New warnings on the configuration `Validate` action.** The toggle is self-explanatory for now.
- **Per-tool permissions for AL Query** (Allow Read/Create/Modify/Delete/Bound Actions). AL queries are read-only by definition; the per-tool permission grid only applies to API tools.
- **A separate `MCP Config Card` for AL Query.** One config, one card.
- **Page extensions / extensibility** for partner customization of the AL Query group. The card is `Extensible = false`; partners use the public codeunit API.
- **UI to test or preview an AL query** from the configuration card.

## 6. Design Considerations (UX shape)

Diagrams below are ASCII sketches — final pixel-level UX is up to design.

### 6.1 Card layout (with AL Query enabled)

```
┌─────────────────────────────────────────────────────────────────────┐
│ Model Context Protocol (MCP) Server Configuration                   │
├─────────────────────────────────────────────────────────────────────┤
│ General                                                             │
│   Name . . . . . . . . . . . . . . . . . [ My Analytics Config   ]  │
│   Active . . . . . . . . . . . . . . . . [ ☑ ]                      │
│   Default  . . . . . . . . . . . . . . . [ ☐ ] (read-only)          │
│   Enable Dynamic Tool Mode . . . . . . . [ ☑ ]                      │
│   Discover Additional Read-Only Objects  [ ☑ ]                      │
│   Description  . . . . . . . . . . . . . [ ...                   ]  │
│   Allow Production Changes . . . . . . . [ ☑ ]                      │
├─────────────────────────────────────────────────────────────────────┤
│ Tool Modes                                                          │
│   In Dynamic Tool Mode, only system tools are exposed to clients... │
├─────────────────────────────────────────────────────────────────────┤
│ AL Query Server                              ◀── NEW GROUP          │
│   Enable AL Query Tools  . . . . . . . . [ ☑ ]                      │
│   Maximum Rows per Query [PREVIEW]   . . [ 10000             ]      │
│   Query Timeout (s)      [PREVIEW]   . . [ 30                ]      │
│   Allowed Object Scope   [PREVIEW]   . . [ All Read-Only ▼   ]      │
│   When enabled, this configuration exposes the AL Query server,     │
│   letting clients author and execute AL queries dynamically.        │
├─────────────────────────────────────────────────────────────────────┤
│ System Tools                                                        │
│ ┌───────────────────────────────────────────────────────────────┐   │
│ │ Server     │ Tool Name           │ Tool Description           │   │
│ ├────────────┼─────────────────────┼─────────────────────────────│   │
│ │ API Tools  │ search_tools        │ Search for available tools │   │
│ │ API Tools  │ describe_tool       │ Describe a tool's schema   │   │
│ │ API Tools  │ invoke_tool         │ Invoke a configured tool   │   │
│ │ AL Query   │ compile_al_query    │ Compile an AL query string │   │
│ │ AL Query   │ run_al_query        │ Execute a compiled query   │   │
│ └───────────────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────────────┤
│ Available Tools (API page / API query rows — unchanged)             │
└─────────────────────────────────────────────────────────────────────┘
```

### 6.2 Card layout (AL-Query-only configuration)

```
│ General                                                             │
│   Enable Dynamic Tool Mode . . . . . . . [ ☐ ]                      │
│   Discover Additional Read-Only Objects  [ ☐ ] (disabled)           │
│ ...                                                                 │
│ AL Query Server                                                     │
│   Enable AL Query Tools  . . . . . . . . [ ☑ ]                      │
│   ...                                                               │
│ System Tools                                                        │
│ ┌───────────────────────────────────────────────────────────────┐   │
│ │ Server     │ Tool Name           │ Tool Description           │   │
│ │ AL Query   │ compile_al_query    │ Compile an AL query string │   │
│ │ AL Query   │ run_al_query        │ Execute a compiled query   │   │
│ └───────────────────────────────────────────────────────────────┘   │
│ Available Tools (empty / hidden — no API tools configured)          │
```

### 6.3 List page (new column)

```
│ Name           Description     Active  Default  Dynamic  ReadOnly  AL Query │
│ Default        ...              ☑       ☑        ☑        ☑         ☐       │
│ Sales Agent    ...              ☑       ☐        ☐        ☐         ☑       │
│ Analytics      ...              ☑       ☐        ☑        ☐         ☑       │
```

### 6.4 Editability rules (recap)

| Field                              | Editable when                                              |
| ---------------------------------- | ---------------------------------------------------------- |
| Enable AL Query Tools              | Not implicit default AND not Active                        |
| Mock sub-settings                  | Same as above AND Enable AL Query Tools = ON               |
| Existing fields                    | Unchanged                                                  |

## 7. Technical Considerations

- **`Extensible = false`** on the card and list pages: any partner-facing surface lives on the `MCP Config` codeunit (see FR16). No need to invent a page-extension story.
- **Platform-side fields**: `MCP Configuration` table extension lives in the platform (cross-app boundary). This app's role is to read/write through the `MCP Configuration` record buffer; the platform team owns table layout and upgrade.
- **Mock sub-settings**: store as scalar fields on `MCP Configuration` (when the platform adds them), or initially as page-only locals if the platform isn't ready. **For the prototype**, page-locals are acceptable so we don't block on platform changes.
- **Temporary table change**: `MCP System Tool` (table 8353) is in-app and temporary; adding a `Server` field is a local-only schema change. `LoadSystemTools` (in `MCPConfigImplementation.Codeunit.al`) will populate it from the existing `MCPUtilities.GetSystemToolsInDynamicMode()` plus a new utility (e.g., `GetSystemToolsForALQuery()`) once the platform exposes one. For the prototype, we can hard-code two mock AL Query tools in the codeunit so the UX is demonstrable end-to-end without platform changes.
- **JSON shape**: extend `ExportConfiguration` / `ImportConfiguration` to include `enableALQuery` (and any mocked sub-settings). Keep the importer tolerant of missing keys for backward compatibility.
- **Telemetry**: extend `LogConfigurationModified` to include `ALQueryEnabled` dimensions (mirror the `DynamicToolMode` pattern at lines 1366-1372 of `MCPConfigImplementation.Codeunit.al`).
- **Connection String**: unchanged. The Connection String dialog (`MCPConnectionString.Page.al`) does not need updates.
- **Upgrade**: handled centrally — new boolean defaults to `false` everywhere. No upgrade tag required for a default-false boolean.
- **Tests**: extend `MCP/src/MCPConfigTest.Codeunit.al` and the existing test library with: a config-with-AL-Query test, a System-Tools-grouping test, and an export/import round-trip test. (Iteration 1 may stub these.)

## 8. Success Metrics

For a UX prototype, success is qualitative:

- The page has been demonstrated to PMs / design and feedback collected on the new group's placement, wording, and grouping affordance.
- Reviewers can clearly distinguish API-tool system tools from AL-Query system tools at a glance (no need to read tooltips).
- An admin unfamiliar with AL Query can read the toggle's tooltip + group description and understand what the toggle does without external docs.
- The list page makes it obvious which configurations have AL Query enabled.

(Once iteration 2+ ships the production runtime, the relevant metrics shift to adoption: number of configurations with AL Query enabled, percentage of MCP traffic hitting AL-Query tools vs. API tools, etc.)

## 9. Open Questions

1. **Naming.** Is "AL Query" the customer-facing name, or do we want something more descriptive (e.g., "Dynamic Query", "Generic Data Analysis", "Analytics Query")? Affects field caption, group caption, and the "Server" column value.
2. **Mock sub-setting list.** Are *Maximum Rows per Query*, *Query Timeout*, *Allowed Object Scope* the right placeholders for review purposes, or should we mock different knobs that better match the platform team's mental model?
3. **Group placement.** Should "AL Query Server" sit between General/Tool Modes and the System Tools list (as drawn) or live inside the General group (smaller surface, but less discoverable)?
4. **System Tools grouping.** Field name for the new column — `Server`, `Source`, or `Provider`?
5. **AL-Query-only configs and the existing `Active` rule that requires at least one tool**. The current `Validate` flow checks for missing read-tool warnings on activation. For an AL-Query-only config, those warnings should *not* fire — confirm that the warning logic is gated on "API tool count > 0" or needs to be taught about AL Query.
6. **Permissions / entitlements**. AL queries run with caller's permissions in the platform — do we need any UI affordance reminding admins of this on the card? (Currently we said no warnings, but a contextual `AboutText` line might help.)
7. **Default config behavior**. The implicit default config has AL Query off by design (FR14). Is there a follow-up deliverable to flip that on once the feature exits preview?
8. **Sub-setting persistence in mock**. If the platform doesn't ship its own fields in time, are page-local mocks sufficient for the prototype (lost on page close), or do we want session-scoped persistence?

---

## Appendix A — File-level change inventory (prototype)

| File                                                      | Change                                                                                                                          |
| --------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| `MCPConfigCard.Page.al`                                   | Add "AL Query Server" group, mock sub-settings, updated description label, adjust System Tools part visibility predicate.       |
| `MCPConfigList.Page.al`                                   | Add "AL Query" boolean column.                                                                                                  |
| `MCPSystemTool.Table.al`                                  | Add `Server` option/text field; widen primary key as needed.                                                                    |
| `MCPSystemToolList.Page.al`                               | Surface the `Server` column; group/sort by it.                                                                                  |
| `MCPConfigImplementation.Codeunit.al`                     | New utility to populate AL-Query rows in `LoadSystemTools`; new internal `EnableALQuery` mirror; extend export/import + telemetry. |
| `MCPConfig.Codeunit.al`                                   | New public `EnableALQuery(ConfigId, Enable)` method (mock signature).                                                           |
| `MCPConfigTest.Codeunit.al` / `MCPConfigTestLibrary.Codeunit.al` | Stub coverage for the new toggle + grouping (acceptable as TODO for prototype).                                          |
| Permission sets (`MCPRead/Objects/Admin`)                 | No change unless platform adds fields requiring tabledata extension.                                                            |

## Appendix B — Decision log

| #   | Decision                                                                                  | Source           |
| --- | ----------------------------------------------------------------------------------------- | ---------------- |
| D1  | Hybrid model — single MCP Configuration with per-server toggles.                          | Q1 in design chat |
| D2  | AL Query toggle is independent of Static / Dynamic Tool Mode.                              | Q2               |
| D3  | Toggle is on/off + mock sub-settings (no production-ready knobs in this iteration).        | Q3               |
| D4  | Single combined System Tools list, with a "Server" column to distinguish source.           | Q4               |
| D5  | Same MCP endpoint serves both servers; Connection String unchanged.                        | Q5               |
| D6  | Default OFF for upgraded, new, and implicit-default configurations.                        | Q6               |
| D7  | No new warnings or activation validation for AL Query in this iteration.                   | Q7               |
| D8  | Treat this as a UX prototype — page-local mocks are acceptable if platform isn't ready.    | Final user note  |
| D9  | Merged independent PR #7860 in: General fasttab restructured into Column1 / Column2; ToolModes nested inside General; API Group lookup auto-resolves publisher when only one publisher exposes the chosen group; column reorders on `MCPConfigToolList`, `MCPAPIConfigToolLookup`, `MCPAPIPublisherLookup`. AL Query Server group sits as its own fasttab below General as a result. | User request to merge PR |
| D10 | Hijack the existing `Rec.DiscoverReadOnlyObjects` field as the storage backend for the AL Query toggle. The original `DiscoverReadOnlyObjects` field is hidden (`Visible = false`). Trade-offs: state persists across navigation (good); turning off Dynamic Tool Mode also clears the AL Query toggle via the existing `OnValidate` (acceptable inherited platform rule); telemetry / Export-Import will see `DiscoverReadOnlyObjects = true` whenever the AL Query toggle is on (acceptable for prototype, must be cleaned up in production). | User request — supersedes D8 for the toggle (mock sub-settings remain page-local). |
| D11 | Switched the System Tools sub-page from **push-based** (parent calls `SetIncludedServers(...)` on the part) to **pull-based** (sub-page reads parent's SystemId via `SubPageLink` + `Rec.FilterGroup(4); Rec.GetFilter(SystemId); Rec.FilterGroup(0);`, looks up the parent `MCP Configuration` via `GetBySystemId`, and reads its flags). Parent's part declaration uses `UpdatePropagation = Both` so `CurrPage.Update()` cascades to the sub-page automatically. Codeunit's `LoadSystemTools` keeps its `(Rec, IncludeAPITools, IncludeALQuery)` signature; only the caller changed. | User request to remove the push procedure. |
| D12 | The AL `Editable`/`Enabled` + non-Rec-bound-source bug (microsoft/AL #6048, #6191) cannot be lived with on the AL Query mock fields. Workarounds tried (boolean page-locals computed in a procedure) were rejected for code-cleanliness. Final resolution: **drop the `Editable` property from the three mock sub-settings entirely** so they take whatever default editability the page provides. The toggle itself is unaffected because it's bound to a Rec field (`Rec.DiscoverReadOnlyObjects`). `Visible` properties on the mock fields binding to `Rec.X` are fine — the bug only affects `Editable`/`Enabled`. | User decision after the bug bit twice. |
| D13 | Removed all helper Booleans (`MockFieldsEditable`, `MockFieldsVisible`, `SystemToolListVisible`, `ALQueryFieldsEditable`) and their refresh procedures. The card now binds expressions directly to `Rec.<FieldName>` everywhere it can. The mock fields' `Visible = Rec.DiscoverReadOnlyObjects` works because the AL bug doesn't apply to `Visible`. | User cleanup pass. |
| D14 | **Known unresolved issue:** the System Tools sub-page renders **collapsed** by default after the pull-based refactor. Workarounds attempted (`Rec.Find(Which)` after populate, `UpdatePropagation = Both`, removing `OnNextRecord`) did not resolve. Reverting to `OnOpenPage`-based load fixes the collapse but is incompatible with the pull-based architecture. Accepted as a prototype-level limitation; reviewers expand the part manually during the demo. | Empirical — agent investigation inconclusive. |
| D15 | **Reverted D11 — went back to push-based** with an explicit `Reload(...)` API on `MCPSystemToolList` (and later `MCPServerFeatureList`), called from `MCPConfigCard.RefreshSubPages` (in `OnAfterGetCurrRecord`, `Active.OnValidate`, `EnableDynamicToolMode.OnValidate`, `DiscoverReadOnlyObjects.OnValidate`). Root cause of D14 collapse: the pull pattern populated the temp table during `OnFindRecord`, *after* BC had already decided the part's expanded/collapsed state from the empty record set. Push populates **before** the visibility flip. Pattern matches `page 7775 "Copilot AI Capabilities"` driving its `Copilot Capabilities GA` sub-part via `SetData(...)`. | User asked to fix the collapse. |
| D16 | **Introduced a Server Modes list-part** (later renamed to Server Features — see D17) on the card, replacing the dedicated `AL Query Server` fasttab. Each row has Activate / Deactivate / Configure actions whose `Visible` predicates mirror the Copilot Capabilities GA pattern (`ActionsEnabled and (Rec.Status = ...)`). Rationale: the prior fasttab felt out of place (peer to General), pushed Available Tools far down the page, and didn't scale to multiple server-side capabilities. | User UX feedback. |
| D17 | **Renamed Server Modes → Server Features** everywhere (enum, table, pages, fields, file names). Outside feedback flagged that `Dynamic Tool Mode` is a contract modifier (changes how Available Tools are exposed), not a feature, so it does **not** belong in the features list. Dynamic Tool Mode + the `Discover Additional Read-Only Objects` sub-setting moved **back to the card** (General → Column2). The Server Features list now contains only opt-in capabilities (just `AL Query Server` for now). | External UX feedback. |
| D18 | **Reverted D10 — un-hijacked `Rec.DiscoverReadOnlyObjects`.** It is once again a regular Dynamic Tool Mode sub-setting on the card, and the field is `Visible = true`. AL Query Server activation is now a **page-local Boolean on `MCPServerFeatureList`**, exposed to the card via `IsALQueryActive()`. Trade-off: AL Query state resets when the card is closed (matches the original pre-D10 page-local intent). Required because D17 needs `DiscoverReadOnlyObjects` for its own meaning. | Forced by D17. |
| D19 | **Per-feature Configure dialog** at `page 8369 "MCP Server Feature Settings"`, `PageType = StandardDialog`. One dialog handles every feature; each feature contributes fields with `Visible = Feature = Feature::"<Name>"`. Page caption is set at runtime via `CurrPage.Caption(StrSubstNo('%1 Settings', Format(Feature)))` — single source of truth, no per-feature caption labels. OK / Cancel contract: `OnValidate` triggers don't write back; `SaveChanges()` is called only when `RunModal = Action::OK`. AL Query mock sub-settings (Max Rows, Timeout, Allowed Object Scope) live here as page-locals with `MOCK:` comments. Configure action on the row is gated `Enabled = Visible = ActionsEnabled and (Rec.Status = Rec.Status::Active)` so it disappears when the parent is Active or the feature is Inactive. | User asked to host per-mode settings. |
| D20 | **`enum 8351 "MCP Server Feature"`** with value `0` deliberately blank (` ` / `' '`) and value `1` `"AL Query Server"` with `Caption = 'AL Query Server (Preview)'`. The blank value is used on `MCPSystemTool."Server Feature"` for system tools that come from Tool Mode itself (search/describe/invoke) — they aren't owned by a feature. The `(Preview)` suffix lives only in the enum caption and propagates to every site (Server Features list row, System Tools column, Configure dialog title). | User asked for a single-source-of-truth Preview suffix. |

## Appendix C — Post-implementation iterations (non-exhaustive)

This section captures the major shape changes that happened **after** the initial Phase 1-3 build. The completion summaries (`docs/tasks/TASK-X.0-...md`) describe the original implementation; this is what the code looks like now.

1. **Storage moved from page-local to `Rec.DiscoverReadOnlyObjects`** (D10). Rewired the toggle binding, removed `EnableALQueryLocal` page-local, hid the existing `DiscoverReadOnlyObjects` field, removed the `EnableALQueryLocal := false;` reset in `OnNewRecord`.
2. **PR #7860 merged in** (D9). Files copied from PR: `MCPAPIConfigToolLookup.Page.al`, `MCPAPIPublisherLookup.Page.al`, `MCPConfigToolList.Page.al`, `MCPToolsByAPIGroup.Page.al`. `MCPConfigImplementation.Codeunit.al` got the PR's `ResolvePublisherForGroup` procedure plus our `LoadSystemTools` changes. `MCPConfigCard.Page.al` was manually merged: PR's General fasttab restructure (Column1 / Column2 / ToolModes nested) + our AL Query Server fasttab + our SystemToolList visibility predicate.
3. **Sub-page architecture flipped from push to pull** (D11). `MCPSystemToolList.Page.al` lost its `SetIncludeALQuery(...)` and `SetIncludedServers(...)` procedures and gained an `OnFindRecord` trigger that reads the parent's SystemId from `FilterGroup(4)` and queries `MCP Configuration` directly. `MCPConfigCard.Page.al` lost its `PushIncludedServersToSubPage()` procedure and all its callsites; the part now has `SubPageLink = SystemId = field(SystemId)` and `UpdatePropagation = Both`.
4. **AL bug workarounds removed in favor of dropping `Editable`** (D12, D13). The `MockFieldsEditable` / `MockFieldsVisible` / `ALQueryFieldsEditable` / `SystemToolListVisible` Booleans and their `RefreshMockFieldsState()` / `UpdateALQueryFieldsEditable()` procedures were all removed. Mock sub-settings now simply have no `Editable` property.
5. **Push-based sub-page architecture restored** (D15). `MCPSystemToolList.OnFindRecord` + the `FilterGroup(4)` / `SubPageLink = SystemId = field(SystemId)` plumbing from D11 are gone. Sub-page exposes `Reload(IncludeAPITools, IncludeALQuery)`; parent calls it from `OnAfterGetCurrRecord` and from each toggle's `OnValidate` via a `RefreshSubPages` helper. Collapse from D14 fixed.
6. **Server Features list-part introduced** (D16, D17). New `enum 8351 "MCP Server Feature"`, new `table 8355 "MCP Server Feature"` (temp), new `page 8368 "MCP Server Feature List"`. Replaces the AL Query Server fasttab; uses Activate / Deactivate / Configure actions on each row mirroring `page 7775 "Copilot AI Capabilities"` → `Copilot Capabilities GA`. Currently lists only `AL Query Server (Preview)`.
7. **Dynamic Tool Mode + Discover Additional Read-Only Objects moved back to the card** (D17, D18). They're real platform fields and aren't features. The `DiscoverReadOnlyObjects` storage hijack from D10 is reverted; AL Query Server activation is now a page-local Boolean on `MCPServerFeatureList` with a back-channel `IsALQueryActive()` for the card to read.
8. **Per-feature Configure dialog** (D19). New `page 8369 "MCP Server Feature Settings"`, `PageType = StandardDialog`. Single page, every feature contributes a field group gated by `Visible = Feature = Feature::"<Name>"`. Page caption built from `Format(Feature) + ' Settings'` so there's no per-feature caption label. OK / Cancel honored: writes happen in `SaveChanges()` only when `RunModal = Action::OK`. AL Query Server has Max Rows / Timeout / Allowed Object Scope as page-local mocks with `MOCK:` comments.
9. **`(Preview)` caption** on AL Query Server (D20). Lives only in the enum value's `Caption`; everywhere it's displayed (Server Features list row, System Tools column, Configure dialog title) inherits it automatically.

## Appendix D — Lessons learned (gotchas worth remembering)

1. **AL bug — `Editable`/`Enabled` referencing `Rec.X` on non-Rec-bound fields crashes the page at open** with a misleading "identifier '<FieldName>' could not be found" error. Bug is in [microsoft/AL#6048](https://github.com/microsoft/AL/issues/6048) and [microsoft/AL#6191](https://github.com/microsoft/AL/issues/6191), open for years. Affects `Editable` and `Enabled`; **does not** affect `Visible`. Two known workarounds: (a) drop the property entirely, (b) compute the boolean into a page-local variable refreshed by a local procedure called from `OnOpenPage`/`OnAfterGetRecord`/relevant `OnValidate` triggers.
2. **`SubPageLink` filters land in filter group 4 ("Link"), not group 0.** Reading the parent's injected key requires `Rec.FilterGroup(4); GetFilter(...); Rec.FilterGroup(0);`. Reference precedents in BCApps: `src/Apps/W1/Shopify/App/src/Products/Pages/ShpfyVariants.Page.al:253-255`, `src/System Application/App/Table Information/src/IndexesListPart.Page.al:241-262`. See [Microsoft Docs on filter groups](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-filtergroup-method).
3. **Same-version republish to local BC.** When a build's content differs from a previously-published `.app` of the same version, the dev REST endpoint returns **422 Unprocessable Entity** with "duplicate package id". Workaround for repeat deploys without a version bump: unpublish first, then republish.
4. **`al_build` MCP tool can return empty assembly probing paths in this workspace.** Pre-existing env limitation; fall back to invoking `alc.exe` directly with the paths from `.vscode/settings.json`.
5. **The "first FastTab is expanded" rule of thumb is wrong** — at least for this codebase. Multiple FastTabs and parts under `area(Content)` can render expanded by default. The actual collapse behavior of list parts is more nuanced (see D14, D15).
6. **List-part visibility flipping false→true at runtime can leave the part collapsed.** When BC decides expand vs. collapse, it inspects the temp record set; if the populator runs during render (e.g. `OnFindRecord`), the part has 0 records at decision time and BC marks it collapsed even after rows appear. Fix: populate **before** the visibility flip — i.e., push the data via an explicit method called from the parent's `OnAfterGetCurrRecord` and from any `OnValidate` that flips the relevant flag. See D15 and `page 7775 "Copilot AI Capabilities"` for the working precedent.
7. **Page-level `Editable = false` does not suppress the auto-generated "Manage" group** on a Card page. The intuitive fix didn't work; switching `PageType` to `StandardDialog` (which doesn't add a Manage group at all) does. Trade-off: StandardDialog adds OK / Cancel buttons, which is what we wanted anyway for the Configure dialog (see D19).
8. **AL `case` with comma-separated enum values works** for compact dispatch, e.g. `case Feature of Feature::"Dynamic Tool Mode", Feature::"AL Query Server": ...`. Property expressions can compare enum values directly: `Visible = Feature = Feature::"AL Query Server"`. No need for page-local Booleans or label constants for this kind of compare.
9. **`Format(EnumValue)` returns the enum's caption** — useful for runtime-built page captions where you want a single source of truth. We use `CurrPage.Caption(StrSubstNo('%1 Settings', Format(Feature)))` instead of maintaining per-feature caption labels.
