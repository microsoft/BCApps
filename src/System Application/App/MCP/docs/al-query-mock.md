# AL Query MCP Server – Configuration UX (Mock / Prototype)

> **Status**: Prototype. UX-only mock; no real platform-side AL Query runtime, no public API, no Export/Import or telemetry round-trip, no automated tests.
> **Tracking**: AB#631012 (parent slice AB#604869).
> **Companion design**: [`docs/features/al-query-mcp-config-ui/design.md`](../../../../../../docs/features/al-query-mcp-config-ui/design.md)

## Purpose

Visualize on the existing **MCP Server Configuration** card how the upcoming **AL Query MCP server** would be turned on, configured, and surfaced alongside the existing API-page / API-query tools — without committing to platform-side persistence or runtime work yet. Reviewers can flip the toggle and see the page restructure live.

## Architecture (current)

The prototype evolved through several iterations. Below is the **current** shape. Earlier shapes (page-local everything, `DiscoverReadOnlyObjects` hijack, AL Query Server fasttab, pull-based System Tools sub-page) have all been replaced.

### Conceptual model

- **Tool Mode** (Static / Dynamic) is a **contract modifier** — it changes how the API tools you add to *Available Tools* are surfaced to the client. It is **not** a feature; it lives on the card next to `Active` / `Default` / `Allow Production Changes`.
- **Server Features** are opt-in capabilities the platform offers on top of the base configuration. Today there is one: **AL Query Server (Preview)**. Each feature row has Activate / Deactivate / Configure actions.

### Storage

| State | Where it lives | Persists across card close? |
| --- | --- | --- |
| `Enable Dynamic Tool Mode` | `Rec.EnableDynamicToolMode` (real platform field) | ✅ |
| `Discover Additional Read-Only Objects` | `Rec.DiscoverReadOnlyObjects` (real platform field) | ✅ |
| AL Query Server activation | Page-local Boolean on `MCPServerFeatureList` (mock) | ❌ |
| AL Query mock sub-settings (Max Rows, Timeout, Allowed Object Scope) | Page-locals on `MCPServerFeatureSettings` (mock) | ❌ |

Anything page-local resets when the card closes. That's intentional — these settings have no platform-side backing field yet, and we explicitly **do not** hijack other Rec fields as storage anymore.

### Object inventory

| Object | ID | Purpose |
| --- | --- | --- |
| `enum "MCP Server Feature"` | 8351 | Discriminator for which server feature exposes a given system tool, and which row the Server Features list represents. Value `0` is a deliberate blank used for system tools owned by the Tool Mode contract (search/describe/invoke); value `1` is `"AL Query Server"` (Caption: `'AL Query Server (Preview)'`). New features add new values. |
| `table "MCP Server Mode"` (legacy) | — | Removed. |
| `table "MCP Server Feature"` (temp) | 8355 | Backing data for the Server Features list-part on the card. Fields: `Feature` (enum), `Description` (Text[500]), `Status` (Option Inactive,Active). |
| `table "MCP System Tool"` (temp) | 8353 | Backing data for the System Tools list-part. The `Server Feature` field is now `Enum "MCP Server Feature"`. Sort/key is `(Server Feature, Tool Name)`. |
| `page "MCP Server Feature List"` | 8368 | List-part on the card. Repeater shows Feature / Description / Status. Activate / Deactivate / Configure actions per row, all gated on `ActionsEnabled and (Rec.Status = ...)`. Push-driven via `Reload(ConfigSystemId, CanModify)`. |
| `page "MCP Server Feature Settings"` | 8369 | `PageType = StandardDialog` (OK / Cancel). Generic per-feature dialog. Each feature contributes fields with `Visible = Feature = Feature::"<Name>"`. Page caption is set at runtime via `CurrPage.Caption(StrSubstNo('%1 Settings', Format(Feature)))` — single source of truth, no per-feature caption labels. AL Query Server has three mock fields (Max Rows, Timeout, Allowed Object Scope) all marked `MOCK:` in code comments. |
| `page "MCP System Tool List"` | 8365 | Sub-page on the card. Push-driven via `Reload(IncludeAPITools, IncludeALQuery)`. The Server Feature column shows blank for Tool Mode tools and `AL Query Server (Preview)` for AL Query Server tools. |
| `page "MCP Config Card"` | 8351 | The card. Hosts (in order): General fasttab (with Tool Mode toggles + description), Server Features list-part, System Tools list-part, Available Tools list-part. |

### Sub-page communication (push)

The card pushes state to its list-parts; sub-pages do **not** read parent state via `SubPageLink` / filter-group-4 tricks. The orchestration lives in `MCPConfigCard.RefreshSubPages`:

```al
local procedure RefreshSubPages()
begin
    CurrPage.ServerFeatureList.Page.Reload(Rec.SystemId, not IsDefault and not Rec.Active);
    CurrPage.SystemToolList.Page.Reload(Rec.EnableDynamicToolMode, CurrPage.ServerFeatureList.Page.IsALQueryActive());
end;
```

`RefreshSubPages` is called from:
- `OnAfterGetCurrRecord` (so navigation between configurations refreshes the sub-pages)
- `Active.OnValidate` (so the configuration becoming Active immediately disables row actions)
- `EnableDynamicToolMode.OnValidate`
- `DiscoverReadOnlyObjects.OnValidate`

`MCPServerFeatureList.IsALQueryActive()` is the only "back-channel" — the card needs to know AL Query state to seed the System Tools list, and AL Query state lives on the sub-page until a real platform field exists. Comments at the procedure, the variable, and the call site all flag this as `MOCK:` and point to the eventual replacement.

The push pattern was chosen deliberately after the pull-based architecture (D11 in the design doc) caused list-parts to render collapsed when their visibility flipped from false to true at runtime — the temp table was empty at the moment BC made the layout decision. The Copilot AI Capabilities (`page 7775`) page uses the same push pattern.

## What this prototype deliberately does NOT do

- **No real AL Query runtime.** The two mock tool names (`compile_al_query`, `run_al_query`) are static text — they don't compile or execute anything. Comment on the inserts in `MCPConfigImplementation.LoadSystemTools` calls out the eventual move into `MCP Utilities`.
- **No new public-API methods** on `codeunit 8350 "MCP Config"`.
- **No `EnableALQuery` JSON property** in `ExportConfiguration` / `ImportConfiguration`.
- **No new telemetry dimension.**
- **No new "AL Query" boolean column** on `MCP Config List`.
- **No automated tests** in `MCPConfigTest.Codeunit.al`.
- **No new permission sets, no upgrade tags, no validation warnings.**
- **No persistence for AL Query activation or its mock sub-settings.** Page-local state, lost on card close.

## How to demo

1. **Build & deploy** the System Application to a local BC instance (Windows-auth dev REST endpoint at `http://localhost:7049/Navision_NAV2/dev/apps`). For same-version republishes, BC's dev endpoint returns `422 Unprocessable Entity` ("duplicate package id") — unpublish first, then republish.
2. **Open the BC web client** at `http://localhost:48900/` → search for **"MCP Server Configurations"** → open the list page (8350).
3. **Pick or create a non-default, non-Active configuration** and open its card.
4. **Walk through these states**:
   - **General fasttab.** Note `Enable Dynamic Tool Mode` and `Discover Additional Read-Only Objects` — both back on the card, both bound to real platform fields. Toggling Dynamic Tool Mode off auto-clears `Discover Additional Read-Only Objects` (existing platform rule).
   - **Server Features list.** Shows one row: `AL Query Server (Preview)`. The Activate / Deactivate / Configure actions are visible only on rows whose mode allows changes — they disappear entirely when the configuration is set Active or default. Activate the row.
   - **Configure...** action on the AL Query Server row. Opens a `StandardDialog` titled `AL Query Server (Preview) Settings` with three mock knobs. Click OK → no real persistence today, but the OK / Cancel contract is wired (the dialog's `SaveChanges` is the future hook).
   - **System Tools list.** Now shows the AL-Query rows (`compile_al_query`, `run_al_query`) tagged `AL Query Server (Preview)` in the Server Feature column. Toggle Dynamic Tool Mode on → the `search_tools` / `describe_tool` / `invoke_tool` rows appear with a blank Server Feature cell (they're owned by the contract modifier, not a feature).
   - **Activate the configuration.** All Server Features row actions disappear immediately (the `Active.OnValidate` trigger calls `RefreshSubPages`); the dialog is no longer reachable.
   - **Default configuration.** Server Features list-part hidden; System Tools list-part hidden.

## Next steps to production

Items roughly in dependency order. The enum, the Server Features list-part, the Settings dialog, and the card layout (Tool Mode toggles in General, list-part in the middle) are all production-shaped — they don't need to be torn out, just have their mock backing replaced. Most of the work is wiring real platform fields where today's `MOCK:` comments live.

### 1. Platform-side prerequisites

Owned by the platform / runtime team. Nothing in this app moves until these land.

- **New fields on `MCP Configuration`**: `EnableALQuery: Boolean` (default `false`), plus any sub-settings the runtime needs — at minimum `MaxRowsPerQuery: Integer`, `QueryTimeoutSeconds: Integer`, `AllowedObjectScope: Enum` (matching today's mock shape, but final names/types TBD).
- **AL Query runtime**: actual compile and execute of client-submitted AL query code (the thing this prototype only mocks via two static tool names). Coordinate the tool names and JSON schemas with the platform team — `compile_al_query` / `run_al_query` in this prototype are placeholders.
- **`MCP Utilities` extension**: new method enumerating the AL Query system tools, mirror of the existing `GetSystemToolsInDynamicMode()`. Returns the real tool catalog with descriptions.

### 2. Replace MOCKs (every `MOCK:` comment in code is a checklist item)

Find all sites with `grep -rn "MOCK:" src/System\ Application/App/MCP/`. Each marks code that should change once step 1 lands:

- `MCPServerFeatureList.ALQueryActiveLocal` / `IsALQueryActive()` → drop entirely; the card reads `Rec.EnableALQuery` directly. Update `MCPConfigCard.RefreshSubPages` accordingly.
- `MCPServerFeatureList.SetActive` AL Query case → `ParentConfig.Validate(EnableALQuery, NewActive); ParentConfig.Modify(true);` (matches the existing `EnableDynamicToolMode` cascade pattern).
- `MCPServerFeatureSettings` page-local mock variables (`MaxRowsPerQueryLocal`, `QueryTimeoutSecondsLocal`, `AllowedObjectScopeLocal`) → bind fields to `Rec.<RealField>`. The `case Feature of Feature::"AL Query Server":` arm in `SaveChanges()` becomes a real `GetBySystemId + Modify(true)` block.
- `MCPConfigImplementation.LoadSystemTools` AL Query block → replace the hardcoded `compile_al_query` / `run_al_query` inserts with a call to the new `MCPUtilities.GetSystemToolsForALQueryServer()` (or whatever it's called).

### 3. Public-API surface on `codeunit 8350 "MCP Config"`

Mirror the existing `EnableDynamicToolMode(ConfigId, Enable)` and `DiscoverReadOnlyObjects(ConfigId, Enable)` shapes. Partners use this codeunit to script configurations.

- `EnableALQuery(ConfigId: Guid; Enable: Boolean)`
- `SetMaxRowsPerQuery(ConfigId: Guid; Value: Integer)`
- `SetQueryTimeoutSeconds(ConfigId: Guid; Value: Integer)`
- `SetAllowedObjectScope(ConfigId: Guid; Value: Enum ...)`
- Matching getters where partners need read access.

### 4. Persistence, observability, list column

- **Export / Import**: extend `MCPConfigImplementation.ExportConfiguration` and `ImportConfiguration` with `enableALQuery` and the sub-settings. Importer must default missing keys to `false` / sensible defaults so older exports stay importable.
- **Telemetry**: extend `MCPConfigImplementation.LogConfigurationModified` with an `ALQueryEnabled` dimension and `Old/NewALQueryEnabled` deltas. Mirror the `DynamicToolMode` block at the bottom of that procedure (~line 1366-1372 in the original code).
- **List page column**: add an `AL Query` Boolean column to `MCPConfigList.Page.al`, right of `Discover Read-Only Objects`. Now meaningful because state will persist.
- **Permissions**: confirm `MCPRead` / `MCPObjects` / `MCPAdmin` cover the new platform fields (typically automatic for tabledata extensions, but verify).

### 5. Tests

Extend `MCPConfigTest.Codeunit.al` and the test library:

- Activate / Deactivate AL Query Server via the public API; verify the row's Status, the System Tools content, and the new platform fields all round-trip.
- Configure dialog: round-trip mock values (Save → reload → Read).
- Export → Import round-trip preserving the new flag and sub-settings.
- Activation `Validate` flow handles **AL-Query-only configurations**: no missing-read-tool warnings should fire when the only enabled feature is AL Query (this is design Open Question Q5 — confirm the warning logic gates on "API tool count > 0" or teach it about AL Query).
- Default config behavior: AL Query stays off on the implicit default (design FR14).

### 6. Polish / cleanup

- Drop the `(Preview)` suffix from `enum "MCP Server Feature"::"AL Query Server"` Caption when the feature graduates from preview status.
- Configure action visibility on `MCPServerFeatureList`: today the action shows for any Active feature, even one with no settings. Once we have multiple features and some are settings-less, gate the action on a `HasSettings(Feature)` helper or add metadata to the enum.
- Remove every `MOCK:` comment in code as its referenced concern is resolved.
- Delete this `docs/al-query-mock.md` once production lands. Archive `design.md` as historical (the decision log + iteration notes are still useful context).

## Pointers

- Decisions log: `docs/features/al-query-mcp-config-ui/design.md` Appendix B (D1-D20).
- Iteration history: `docs/features/al-query-mcp-config-ui/design.md` Appendix C.
- Independently-merged PR: [#7860](https://github.com/microsoft/BCApps/pull/7860) (UX restructure of the General fasttab and other MCP pages — Column1/Column2 layout, API Group lookup improvements).
