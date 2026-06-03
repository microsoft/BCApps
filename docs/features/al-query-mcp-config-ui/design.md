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
- **Last Updated**: 2026-06-03 (post-implementation iterations — see Appendix C; latest: pre-staged the productionized code as commented PLATFORM-PENDING blocks + the EnableApiTools upgrade, against BC-Platform #44811 — D35)
- **Naming note (2026-05/06)**: The feature originally called "AL Query Server" was renamed to "AL Query Tools" (D21), then to **"Data Query Tools"** (D33). Historical decision-log entries below predate these renames and use the older names; current code, captions, and procedures all use "Data Query Tools".

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
| D21 | **Renamed "AL Query Server" → "AL Query Tools"** everywhere (enum value identifier and caption, facade procedure `EnableALQueryServer` → `EnableALQueryTools`, test names, comments). Enum caption is now `'AL Query Tools (Preview)'`. | User UX feedback. |
| D22 | **Reversed D17 — Dynamic Tool Mode is back in the Server Features list** as a feature row (enum ordinal 0, replacing D20's blank value). `EnableDynamicToolMode` field, `DiscoverReadOnlyObjects` field, and the Tool Modes description block were removed from the card's General fasttab. `Discover Additional Read-Only Objects` now lives in the Configure dialog under Dynamic Tool Mode (`Visible = Feature = Feature::"Dynamic Tool Mode"`), loaded from / saved to `Rec.DiscoverReadOnlyObjects` on OK. The "turn off Dynamic Tool Mode clears DiscoverReadOnlyObjects" cascade is reinstated inside the row's `SetActive` (`ParentConfig.DiscoverReadOnlyObjects := false;` on deactivate). The blank enum value 0 from D20 is gone — every system tool in the System Tools list is now tagged with a concrete feature. | User asked to unify the UX. |
| D23 | **System Tools list-part moved from `area(Content)` to `area(FactBoxes)`** to surface it as a right-rail factbox rather than pushing API Tools further down the card. There is no AL property to force a factbox open on first page render; BC stores expand/collapse as a per-user personalization. Accepted as a limitation. | User UX feedback. |
| D24 | **`MCPConfigToolList` caption renamed `'Available Tools'` → `'API Tools'`.** The `Select Tools`, `Add Tools by API Group`, and `Add All Standard APIs as Tools` actions all guard on `Enabled = not IsConfigActive`. `IsConfigActive` is push-driven from the parent via a new `SetConfigActive(IsActive: Boolean)` procedure that `MCPConfigCard.RefreshSubPages` calls. Page-local Boolean alone isn't enough for BC to re-evaluate `Enabled` on sub-page actions — `Active.OnValidate` on the parent now ends with `CurrPage.Update()` so the redraw propagates through `UpdatePropagation = Both`. | User reported actions stayed disabled after deactivation. |
| D25 | **Added an "API Tools" feature row** to the Server Features list (enum ordinal 0; Dynamic Tool Mode → 1, AL Query Tools → 2). Activation gates visibility of the curated API list on the card: `Visible = not IsDefault and APIToolsActive`, where `APIToolsActive` is a card-page-local set from `CurrPage.ServerFeatureList.Page.IsAPIToolsActive()` inside `RefreshSubPages`. To disambiguate the new *feature* row from the list it gates, the sub-part caption (`page 8352`) was renamed `'API Tools'` (D24) → `'Available APIs'`, and the Dynamic Tool Mode / AL Query description labels were updated to reference "Available APIs". Dynamic Tool Mode now has a pre-flight in its `SetActive` arm that throws `APIToolsRequiredForDynamicErr` if API Tools is off (you can't enable Dynamic Tool Mode without API Tools). Activation is a page-local mock (`APIToolsActiveLocal`); replace with a real Rec field when the platform ships one. **API Tools has no Configure sub-settings yet** — its `SaveChanges()` arm is an empty placeholder, and `AllowProdChanges` (create/update/delete tools) stays in General → Column2 on the card, unchanged. Relocating it into the API Tools Configure dialog as an "Unblock Edit Tools" toggle (write via `MCPConfig.AllowCreateUpdateDeleteTools(...)` on OK) remains a candidate for a later iteration. | User asked to gate the curated API list on a feature toggle. |
| D26 | **Dropped AL Query Tools' mock sub-settings and gated Configure to Dynamic Tool Mode.** API Tools and AL Query Tools have no per-feature settings, so the `Maximum Rows per Query` / `Query Timeout (seconds)` page-locals and fields were removed from `page 8369`, along with the `SetALQueryMaxRowsPerQuery` / `SetALQueryTimeoutSeconds` facade (`codeunit 8350`) + impl (`codeunit 8351`) procedures and their four smoke tests. The activation facade `EnableALQueryTools` and its two tests stay. The `Configure` action on `page 8368` is now gated `... and (Rec.Feature = Rec.Feature::"Dynamic Tool Mode")` for both `Enabled` and `Visible`, so it only appears for the one feature that still has settings; `page 8369`'s `SaveChanges` collapses to the single Dynamic Tool Mode arm. | User: API Tools and AL Query Tools won't have additional settings. |
| D27 | **Refactored Server Features to enum-implements-interface dispatch.** New `interface "MCP Feature Handler"` (`SetActive` / `IsActive` / `HasSettings` / `OpenSettings` / `Description`); `enum "MCP Server Feature"` now `implements` it, each value bound to a handler codeunit (`MCP API Tools Feature` 8369, `MCP AL Query Tools Feature` 8368, `MCP Dyn. Tool Mode Feature` 8370). `MCPServerFeatureList` lost its `case Rec.Feature of` SetActive switch, the `APIToolsActiveLocal`/`ALQueryActiveLocal` mocks, the `IsAPIToolsActive`/`IsALQueryActive` getters, and the three description labels — it now resolves `Handler := Rec.Feature` and dispatches. `Reload` is data-driven via `ServerFeature.Ordinals()` → `"MCP Server Feature".FromInteger(...)` (mirroring `MCPConfigImplementation.FindWarningsForConfiguration`), so a new feature is a new enum value + handler with no page edit. Descriptions and the Dynamic-Tool-Mode-requires-API-Tools pre-flight (`APIToolsRequiredForDynamicErr`) moved into the handlers. The temp table gained `Configurable` (set from `Handler.HasSettings()`); the Configure action now gates on `Rec.Configurable` (was `Rec.Feature = "Dynamic Tool Mode"` in D26). Dynamic Tool Mode's handler is real; API Tools + AL Query are platform-pending stubs whose `IsActive` returns false until the platform booleans land. `MCP/app.json` `idRanges` extended to `8365-8370` for the handler codeunits. | User asked for a feature interface so features are self-contained and the list is extensible. |
| D28 | **Interface renamed `"MCP Feature Handler"` → `"MCP Server Features"`; handlers delegate to `MCP Config Implementation`.** Each handler's `SetActive` is now a one-line call into the impl (`EnableAPITools` / `EnableALQueryTools` / `EnableDynamicToolMode`) instead of writing the field itself; `EnableAPITools` was added to facade `codeunit 8350 "MCP Config"` + impl `codeunit 8351` (mock no-op, like `EnableALQueryTools`). The "API Tools must be enabled before Dynamic Tool Mode" pre-flight moved out of the Dyn. Tool Mode handler into `impl.EnableDynamicToolMode` (beside the existing `DynamicToolModeRequired` check) as a **PLATFORM-PENDING commented block** — it can't read the API Tools boolean until that field is in symbols, so the gate is currently inactive. Interface variables renamed `Handler` → `ServerFeature`. | User: simpler to call into MCP Config; the gate belongs in the impl anyway. |
| D29 | **System tool loading moved onto the interface.** `"MCP Server Features"` gained `LoadSystemTools(var MCPSystemTool)`; the Dyn. Tool Mode handler emits the real `MCPUtilities.GetSystemToolsInDynamicMode()` catalog (tagging its own feature), AL Query the mock `compile_al_query` / `run_al_query`, API Tools nothing. `impl.LoadSystemTools` + `InsertSystemTool` + the `IncludeAPITools` / `IncludeALQuery` flags were removed (the first flag was actually fed `EnableDynamicToolMode` — a latent misnomer). `page 8365 "MCP System Tool List"` `Reload(ConfigSystemId)` now iterates `Ordinals()` and calls `LoadSystemTools` for each **active** feature (`DeleteAll` moved to the page); the card just calls `SystemToolList.Reload(Rec.SystemId)`. The `MCP Utilities` dependency moved into the Dyn. Tool Mode handler. | User asked to make system tools feature-owned too. |
| D30 | **API Tools / AL Query Tools activation is now persisted (mock table), and the "API Tools required for Dynamic Tool Mode" gate went live.** The platform-owned `MCP Configuration` table can't be extended from the app, and no lower-layer table can be borrowed (the System App can't reference Application-layer tables like General Ledger Setup — that's a circular dependency), so the two activation flags are persisted in a new app-owned **`table 8356 "MCP Feature Activation"`** (`Config Id` + `Enable API Tools` + `Enable AL Query Tools`), keyed by config SystemId. Everything funnels through four `MCP Config Implementation` procedures — `EnableAPITools` / `EnableALQueryTools` (write) and `IsAPIToolsEnabled` / `IsALQueryToolsEnabled` (read) — so the table is fully isolated; the handlers, the card, and the gate all go through those. With real reads available, the API-Tools pre-flight in `impl.EnableDynamicToolMode` that D28 had left commented was **uncommented and is now enforced** (`APIToolsRequiredForDynamicErr`). Supersedes the `APIToolsActiveLocal` page-local mock from D25. See Appendix E for the exact removal steps. | User wanted activation persisted now, without waiting for the platform fields. |
| D31 | **Dynamic Tool Mode shown as an indented sub-feature of API Tools.** The interface gained `TryGetParentFeature(var ParentFeature)`; a feature that reports a parent renders indented beneath it in the Server Features list (`table 8355` gained an `Indentation` field; the `page 8368` repeater sets `IndentationColumn = Rec.Indentation; IndentationControls = Feature`). The Dyn. Tool Mode handler declares `"API Tools"` as its parent. (Briefly tried *hiding* Dynamic Tool Mode until API Tools was active — it broke the feature-order tests and was reverted; it's always visible, just indented, which communicates the parent/child relationship without hiding anything.) | User: indentation already shows it's a sub-feature; no need to hide it. |
| D32 | **Tried wrapping Server Features + Available APIs in one `Tools` FastTab to force-expand the API list — reverted.** `part(ToolList)` (the curated API list) renders collapsed because BC auto-expands only the first two content sections and it's the third (General FastTab → Server Features → API Tools); its `Visible` flipping `false→true` at runtime compounds it. **There is no AL property to set a part's starting expand state** — BC owns it ([Page Parts Overview](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-designing-parts#design-considerations)). The documented lever (wrap in a FastTab that lands in the first two slots) was tried — both parts nested in `group(Tools)` — and **looked worse**, for two reasons: (a) a `group` lays its child *parts* out **side-by-side / columnized** (like General's Column1/Column2), squeezing each list to half width; (b) force-expanding the *empty, editable* Available APIs list surfaces a tall grid of blank entry rows. Net: reverted to the original two stacked top-level parts; Available APIs stays a 3rd-section part that collapses until the user expands it (which also keeps its empty grid tucked away). See Appendix D #13. | User: the combined layout looked awful. |
| D33 | **Review round 2: Default actions, Data Query Tools rename, unified API lookup, list feature columns, permission completion.** (a) The card's `Default` field is now read-only; **Set as Default** / **Clear Default** actions (promoted) returned to the configuration list. (b) **AL Query Tools → Data Query Tools (Preview)** everywhere in code — enum value, handler `MCP Data Query Tools Feature` (8368), facade/impl `EnableDataQueryTools` / `IsDataQueryToolsEnabled`, the mock activation field, and tests; the mock tool IDs `compile_al_query` / `run_al_query` are kept (the real platform catalog will name them). (c) **Select APIs** now opens one lookup listing both API pages and API queries — new temp `table 8357 "MCP API Object Buffer"` + `page 8376 "MCP API Object Lookup"`, populated by `impl.LookupAPIObjects` (the per-row Object ID lookup was left type-specific here — later unified in D34). (d) The configuration list dropped the `Dynamic Tool Mode` / `Discover Read-Only Objects` columns for read-only **API Tools** / **Data Query Tools** status columns (computed via the activation getters); the Dynamic Tool Mode feature itself stays on the card. (e) **Permissions:** the recently-added tables (`MCP Server Feature`, `MCP Feature Activation`) and the new buffer were missing from `MCP - Objects`, and the persistent `MCP Feature Activation` had no tabledata grant — added (object `= X`; tabledata `R` in Read, `IMD` in Admin), without which the feature breaks for non-SUPER users. | User review feedback. |
| D34 | **Quality-pass cleanup (full-PR review).** Unified the two API-add paths — the per-row `Object ID` lookup now shares one `AddAPIObjects()` helper with the `Select APIs` action via `impl.LookupAPIObjects`, so both show pages + queries. Removed the now-orphaned per-type lookups: `impl.LookupAPIPageTools` / `LookupAPIQueryTools`, `page 8353 "MCP API Config Tool Lookup"`, `page 8367 "MCP Query Config Tool Lookup"`, their two test-library wrappers, and their two tests/handlers (replaced by one `TestLookupAPIObjects` smoke test). Also `table 8357 "MCP API Object Buffer"` → `TableType = Temporary` (matching sibling buffers), and temp-record variable naming fixed to the LinterCop convention (locals `Temp`-prefixed, parameters not). | User: cleanup pass — don't keep procedures alive only for their own tests. |
| D35 | **Pre-staged the productionized code as commented `PLATFORM-PENDING` blocks, against [BC-Platform PR #44811](https://microsoft.ghe.com/bic/BC-Platform/pull/44811).** That PR adds `EnableApiTools` (field 8, `InitValue = true`) + `EnableAlQueryTools` (field 9) to `MCP Configuration` and `"MCP Utilities".GetSystemToolsInDataQuery()`. The real read/write/catalog code now sits commented next to each mock (`MCP Config Implementation`, `MCP Data Query Tools Feature.LoadSystemTools`), plus a commented `EnableApiToolsOnExistingConfigurations` upgrade in `MCP Upgrade` that sets `EnableApiTools := true` on existing configs (the field's `InitValue` only covers new ones), and commented real-assertion versions of the four activation tests in `MCP Config Test`. When #44811 merges: uncomment + delete the mocks. The platform keeps the "AL Query Tools" field name; our UX stays "Data Query Tools" (maps onto `EnableAlQueryTools`). See Appendix E. | User wanted the switch-over to be uncomment-and-go once the platform lands. |

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
10. **AL Query Server → AL Query Tools rename** (D21). Six files updated (enum, list page, settings page, list, codeunit, facade, tests). Facade procedure `EnableALQueryServer` → `EnableALQueryTools`. Caption is now `'AL Query Tools (Preview)'`.
11. **Dynamic Tool Mode reinstated as a feature row** (D22). `EnableDynamicToolMode`, `DiscoverReadOnlyObjects`, the `ToolModes` description block, the three Tool Mode labels and `GetToolModeDescription` helper, and the `OnNewRecord` trigger that primed the label are all gone from the card. `MCPServerFeatureList.Reload` seeds two rows (`Dynamic Tool Mode`, `AL Query Tools`). Dynamic Tool Mode case in `SetActive` writes to `ParentConfig.EnableDynamicToolMode` via `GetBySystemId + Modify(true)` and cascades-clears `DiscoverReadOnlyObjects` on deactivate. Settings dialog grew a `Discover Additional Read-Only Objects` field that's loaded from / saved to `Rec.DiscoverReadOnlyObjects`. The enum's blank value 0 from D20 is gone — replaced with `"Dynamic Tool Mode"` at ordinal 0. `LoadSystemTools` tags the search/describe/invoke tools with the new Dynamic Tool Mode enum value (no more blank cell on System Tools).
12. **System Tools moved to factbox** (D23). `area(FactBoxes)` added to `MCPConfigCard`; `part(SystemToolList; ...)` declaration moved inside it. `Visible` and `UpdatePropagation = Both` preserved.
13. **API Tools sub-part caption + action guards** (D24). `MCPConfigToolList.Caption` is now `'API Tools'`. All three CUD-style actions guard on `Enabled = not IsConfigActive`. New internal `SetConfigActive(IsActive: Boolean)` on `MCPConfigToolList` accepts a push from `MCPConfigCard.RefreshSubPages` (`CurrPage.ToolList.Page.SetConfigActive(Rec.Active);`). `Active.OnValidate` on the card ends with `CurrPage.Update();` — that's what actually triggers BC to re-evaluate the sub-page's `Enabled` expressions.
14. **API Tools feature row added** (D25). Enum reordered to API Tools (0), Dynamic Tool Mode (1), AL Query Tools (2). New `APIToolsActiveLocal` page-local + `IsAPIToolsActive()` getter on `MCPServerFeatureList`; `Reload` seeds the API Tools row ahead of Dynamic Tool Mode / AL Query Tools. `SetActive` for Dynamic Tool Mode pre-flights `APIToolsActiveLocal` and errors with `APIToolsRequiredForDynamicErr` if API Tools is inactive. `MCPConfigCard` gained `APIToolsActive` page-local set from the sub-page in `RefreshSubPages`; `part(ToolList; ...)` is now `Visible = not IsDefault and APIToolsActive`. The sub-part (`page 8352`) caption was renamed `'API Tools'` → `'Available APIs'` and the Dynamic Tool Mode / AL Query description labels updated to match. API Tools has no Configure sub-settings yet — the `Feature::"API Tools"` arm in `SaveChanges()` is an empty placeholder, and `AllowProdChanges` stays in General → Column2 on the card; relocating it into the Configure dialog as an "Unblock Edit Tools" toggle is left for a later iteration.
15. **AL Query Tools sub-settings removed, Configure gated to Dynamic Tool Mode** (D26). `page 8369` lost the `MaxRowsPerQueryLocal` / `QueryTimeoutSecondsLocal` page-locals, their two fields, and their `OnOpenPage` defaults; `SaveChanges` is now a single `Feature::"Dynamic Tool Mode"` arm. `codeunit 8350` / `codeunit 8351` lost `SetALQueryMaxRowsPerQuery` and `SetALQueryTimeoutSeconds` (activation `EnableALQueryTools` kept). `MCPConfigTest` dropped the four Max/Timeout smoke tests (kept `TestEnableALQueryTools`, renamed `TestDisableALQueryServer` → `TestDisableALQueryTools`). `page 8368`'s `Configure` action gained `and (Rec.Feature = Rec.Feature::"Dynamic Tool Mode")` on `Enabled`/`Visible`.
16. **Server Features moved to enum-implements-interface** (D27). New `interface "MCP Feature Handler"` + 3 handler codeunits (`MCP API Tools Feature` 8369, `MCP AL Query Tools Feature` 8368, `MCP Dyn. Tool Mode Feature` 8370); `enum "MCP Server Feature" implements` it. `MCPServerFeatureList` dropped its `case Rec.Feature of` SetActive switch, the `APIToolsActiveLocal`/`ALQueryActiveLocal` mocks, the `IsAPIToolsActive`/`IsALQueryActive` getters, and all three description labels — it does `Handler := Rec.Feature` and dispatches. `Reload` iterates `ServerFeature.Ordinals()` → `FromInteger` → `InsertRow`. The Configure gate changed from `Rec.Feature = "Dynamic Tool Mode"` (D26) to `Rec.Configurable` (= `Handler.HasSettings()`). `MCPConfigCard.RefreshSubPages` resolves the API Tools / AL Query handlers for `IsActive`. Each handler returns its own `Description()`; DTM handler is real, API Tools + AL Query are platform-pending stubs (`IsActive` → false). **Root cause of the earlier "codeunit missing" errors: the MCP app's `idRanges` didn't cover the new codeunit IDs** — extended `8365-8370` in `MCP/app.json` (not a language-server issue).
17. **Interface rename + handler delegation** (D28). `interface "MCP Feature Handler"` → `"MCP Server Features"` (new file `MCPServerFeatures.Interface.al`, old removed). Each handler's `SetActive` delegates to `MCP Config Implementation` (`EnableAPITools` new on facade + impl, mock). DTM's API-Tools pre-flight moved into `impl.EnableDynamicToolMode` as a commented PLATFORM-PENDING check (inactive until the field exists). Interface vars `Handler` → `ServerFeature`.
18. **System tools on the interface** (D29). `LoadSystemTools(var MCPSystemTool)` added to the interface + all three handlers (DTM real via `MCPUtilities.GetSystemToolsInDynamicMode()`, AL Query mock, API Tools no-op). `impl.LoadSystemTools` / `InsertSystemTool` / the `Include*` flags removed. `page 8365` `Reload(ConfigSystemId)` iterates `Ordinals()` → active features → `LoadSystemTools` (page owns `DeleteAll`). Card `RefreshSubPages` → `SystemToolList.Reload(Rec.SystemId)`.
19. **Test coverage for the Server Features surface.** `MCP Config Test` (`codeunit 130130`) gained smoke tests for the `EnableAPITools` facade no-op and a `Server Features` region of TestPage tests on `page 8351 "MCP Config Card"`: the list shows all three features in enum order, `Configure` is enabled only on Dynamic Tool Mode (the `Configurable` = `HasSettings()` gate), activating Dynamic Tool Mode flips its row Status + sets `EnableDynamicToolMode`, and the part is hidden on the default configuration. Also fixed `TestDefaultConfigurationPage`, which still asserted on the card's `EnableDynamicToolMode` / `DiscoverReadOnlyObjects` fields that D22 moved into the Configure dialog — a stale TestPage reference that was blocking the test codeunit from compiling. (Lesson: moving a field off a page silently breaks its TestPage tests — update them in the same change.)
20. **Activation persistence via a mock table + live gate** (D30). New `table 8356 "MCP Feature Activation"` (`Config Id`, `Enable API Tools`, `Enable AL Query Tools`). `MCP Config Implementation` gained `EnableAPITools` / `EnableALQueryTools` (upsert the row) and `IsAPIToolsEnabled` / `IsALQueryToolsEnabled` (read it); the API Tools + AL Query handlers' `SetActive` / `IsActive` now round-trip through these instead of returning the old `false` stub. Rows are inserted lazily on the first Activate/Deactivate (or facade call); there's no delete-cleanup, so deleting a config leaves an orphan row (harmless — keyed by SystemId, never re-read). The `impl.EnableDynamicToolMode` API-Tools pre-flight (commented since D28) is now uncommented and enforced — `APIToolsRequiredForDynamicErr` was added. Every touch point carries a `// MOCK:` comment. See Appendix E.
21. **Dynamic Tool Mode rendered as an indented sub-feature** (D31). Interface gained `TryGetParentFeature`; `table 8355 "MCP Server Feature"` gained `Indentation`; `page 8368`'s repeater sets `IndentationColumn` / `IndentationControls`, and `InsertRow` indents any feature that reports a parent. The Dyn. Tool Mode handler returns `"MCP Server Feature"::"API Tools"`. Always visible (the hide-until-active variant was reverted because it broke the feature-order tests).
22. **Tried + reverted the `Tools` FastTab** (D32). Wrapped `part(ServerFeatureList)` + `part(ToolList)` in `group(Tools)` to force the API list expanded; reverted because a group columnizes its child parts side-by-side (half-width each) and an expanded empty editable Available APIs list shows a tall blank grid. Layout is back to the two stacked top-level parts; API Tools collapses as the 3rd section until expanded.
23. **Review round 2** (D33). Card `Default` read-only + list `Set as Default` / `Clear Default` actions. `AL Query Tools` → `Data Query Tools` rename (handler/file `MCP Data Query Tools Feature`, `EnableDataQueryTools` / `IsDataQueryToolsEnabled`, mock field `Enable Data Query Tools`, enum value + caption, tests). New `table 8357 "MCP API Object Buffer"` + `page 8376 "MCP API Object Lookup"` + `impl.LookupAPIObjects`/`PopulateAPIObjects` back the unified `Select APIs` lookup (pages + queries). List swapped DTM / Discover columns for read-only `API Tools` / `Data Query Tools` status columns. Permission sets completed for `MCP Server Feature` / `MCP Feature Activation` (incl. tabledata) / `MCP API Object Buffer`.
24. **Quality-pass cleanup** (D34). Per-row `Object ID` lookup unified onto `LookupAPIObjects` (shared `AddAPIObjects` helper); removed the dead `LookupAPIPageTools` / `LookupAPIQueryTools` + pages `8353` / `8367` + their test-library wrappers + tests (→ one `TestLookupAPIObjects`). `table 8357` → `TableType = Temporary`; temp var naming aligned (locals prefixed, params not). Also `page "MCP API Object Lookup"` renumbered `8360` → `8376` (new idRange `8376-8380` in `MCP/app.json`).

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
10. **Action `Enabled` on a sub-page tied to a page-local Boolean doesn't refresh from sub-page-local `CurrPage.Update()`.** When the parent state changes, pushing a new value into the sub-page's Boolean (via an internal push procedure) flips the variable, but BC keeps using the cached `Enabled` result until the **parent** redraws. The working pattern: parent's `OnValidate` (here `Active.OnValidate`) ends with `CurrPage.Update();` so the redraw cascades through `UpdatePropagation = Both` and BC re-evaluates the sub-page's action expressions. Calling `CurrPage.Update(false)` from inside the push procedure was insufficient and was reverted (D24).
11. **No AL property forces a factbox open on first page render.** BC stores expand/collapse as a per-user, per-page personalization preference. There is no `ExpandedDefault` (or equivalent) on `part(... ; ...)` declarations inside `area(FactBoxes)`. First-time users typically see the factbox expanded in the modern Web Client, but once collapsed by a given user it stays that way until they reopen it. Accepted as a limitation (D23).
12. **The System Application can't borrow an Application-layer table to mock a persisted field.** When the platform-owned target table (`MCP Configuration`) can't be extended and you need somewhere to persist a flag, you can't reach "down" into Base / Application tables (e.g. `General Ledger Setup`) from the System App — that layer sits *above* the System App, so the reference is a circular dependency and won't compile. The workable mock is an **app-owned table inside the MCP module itself** (`table 8356 "MCP Feature Activation"`), isolated behind getter/setter procedures so productionizing is a delete + repoint (Appendix E), not a hunt through call sites.
13. **You can't force a content part's starting expand state, and the FastTab workaround has ugly side-effects.** BC auto-expands only the first two content sections (parts/FastTabs) of a card/document page and collapses the rest; there is no AL property to override this ([Page Parts Overview](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-designing-parts#design-considerations)). The documented levers — (a) a part is only *independently* collapsible if it's **not** inside a FastTab, so wrapping it in a `group` makes it inline/non-collapsible; (b) the FastTab must still occupy one of the first two slots — do technically force a 3rd-position list to show. **But** a `group` containing multiple `part`s renders them **side-by-side (columnized)**, not stacked, and force-expanding an empty *editable* list exposes its blank entry grid. We tried this for the API Tools list (D32) and reverted. Practical takeaway: don't fight BC's expand heuristic for a secondary/gated list — leave it as a top-level part and let it collapse until the user opens it.

## Appendix E — Productionizing: removing the mocks

This feature ships with two deliberate placeholders, each waiting on a different platform dependency. Both are designed so that removal is mechanical. Every mock site carries a `// MOCK:` comment in source — to list them all: `grep -rn "MOCK:" "src/System Application/App/MCP/"`. Nothing else in the feature is a placeholder.

The platform side is **[BC-Platform PR #44811](https://microsoft.ghe.com/bic/BC-Platform/pull/44811)** (not merged at time of writing). The productionized code is **pre-staged as commented `// PLATFORM-PENDING (BC-Platform PR #44811)` blocks** next to each mock — so once #44811 merges, productionizing is mostly *uncomment + delete the mock*. `grep -rn "PLATFORM-PENDING" "src/System Application/App/MCP/"` lists those blocks.

### 1. API Tools / Data Query Tools activation persistence

**Why it's mocked:** the two activation flags belong on the platform-owned `MCP Configuration` table, which the app can't extend, and no lower-layer table is reachable from the System App (Appendix D #12). They're persisted instead in app-owned `table 8356 "MCP Feature Activation"` (`Config Id` + two booleans), reached **only** through four procedures in `codeunit 8351 "MCP Config Implementation"`.

**#44811 adds two booleans to `MCP Configuration`:** `field(8; EnableApiTools)` (caption "Enable API Tools", `InitValue = true`) and `field(9; EnableAlQueryTools)` (caption "Enable AL Query Tools" — the platform keeps the "AL Query Tools" name; our "Data Query Tools" UX maps onto it). When it merges:

1. In `codeunit 8351 "MCP Config Implementation"`, delete the four mock procedures (`EnableAPITools` / `EnableDataQueryTools` / `IsAPIToolsEnabled` / `IsDataQueryToolsEnabled`) and **uncomment the pre-staged productionized versions** right below them (they read/write `EnableApiTools` / `EnableAlQueryTools`).
2. Delete `table 8356 "MCP Feature Activation"` (its ID frees up within the existing `8350–8362` idRange) and remove its permission-set entries — the `table … = X` line in `MCP - Objects` and the `tabledata … = R` / `= IMD` lines in `MCP - Read` / `MCP - Admin`.
3. In `codeunit 8356 "MCP Upgrade"`, **uncomment** `EnableApiToolsOnExistingConfigurations` (+ its call, tag getter, and registration) to set `EnableApiTools := true` on every existing configuration — the field's `InitValue = true` covers new configs, but existing rows need the upgrade.
4. On `page 8350 "MCP Config List"`, the API Tools / Data Query Tools status columns carry pre-staged commented `Rec.EnableApiTools` / `Rec.EnableAlQueryTools` field bindings — uncomment those and delete the function-sourced versions (they become normal bound columns, optionally editable).
5. In `codeunit 130130 "MCP Config Test"`, delete the four smoke activation tests and uncomment their productionized versions (which assert the real `EnableApiTools` / `EnableAlQueryTools` field state).

Everything else — the handlers (`MCP API Tools Feature`, `MCP Data Query Tools Feature`), the Server Features list (incl. the indented sub-feature and the live `APIToolsRequiredForDynamicErr` gate), the Available APIs visibility on the card, and the `MCP Config` facade — flows through those four procedures unchanged.

### 2. Data Query Tools system tool catalog

**Why it's mocked:** `MCP Utilities` doesn't yet expose the Data Query Tools system tools, so `codeunit 8368 "MCP Data Query Tools Feature".LoadSystemTools` hardcodes a two-row preview (`compile_al_query`, `run_al_query`).

**#44811 adds `"MCP Utilities".GetSystemToolsInDataQuery(): Dictionary of [Text, Text]`.** When it merges, delete the two hardcoded `InsertTool(...)` calls in `MCP Data Query Tools Feature.LoadSystemTools` and **uncomment the pre-staged version** that consumes `GetSystemToolsInDataQuery()` (mirroring `MCP Dyn. Tool Mode Feature.LoadSystemTools` + `GetSystemToolsInDynamicMode()`).

> The Data Query Tools **runtime** (compiling and executing the client-submitted AL queries on the server) is a separate, larger platform dependency. It isn't represented by a code mock here — this feature only *configures and advertises* the tools.

### Not mocks (leave alone)

- The `(Preview)` suffix on the Data Query Tools enum caption is an intentional product label, not a placeholder.
