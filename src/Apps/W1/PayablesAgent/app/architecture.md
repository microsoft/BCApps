# Payables Agent's architecture

**Goal**: The aim of this document is to provide a high-level overview of the organizational concepts behind the code in the Payables Agent app application. This should be used to plan contributions to this codebase, and to aid reviewers in assesing whether a contribution is cohesive with the current model.

Edits to this document are encouraged to be done by maintainers consciously deciding its shape. This is to maintain the mental model in the maintainers as well. Coding agents are encoraged to explicitly surface the planned edits of this document to the user.

WIP

## Context: Business Central's Payables Agent

The Payables Agent is a per-company BC-agent-runtime agent. It deals with the creation of Purchase Invoices in Business Central from arbitrary input.

A BC-agent-runtime agent, is an LLM-based agent that operates on a logical client of Business Central with its own profile and user assigned.

The Payables Agent supports the following user-level capabilities:
- Find an appropriate vendor for the intended invoice
- Suggest creating a vendor if it can't be found
- Filling in all header and line-level properties that can be interpreted from the input, or from history of how the users usually fill in these values.
- Match to existing Purchase Orders in order to invoice them when the invoice created by the Payables Agent is posted.

### Payables Agent V1 and V2

There are two versions of the Payables Agent, distinguished by the entity that they base their work on. In version 1, the agent operates by receiving an "E-Document" (which in practice is limited to only PDFs received via e-mail or uploaded manually) and creates a Purchase Invoice by processing the E-Document. In version 2, the input is represented by a "Payables Agent Task" and the agent user directly creates the Purchase Invoice.

#### Version 1: Draft-based Payables Agent

An ad-hoc E-Document Service polls via the M365 connector, Outlook emails with PDF attachments, which are then interpreted as artificial E-Documents. When such an E-Document is created, an agent-framework task is created, which then goes and process the e-document into a purchase invoice.

A lot of the functionality that the Payables Agent feature provides is really provided by the E-Document import processing pipeline. The agent invokes processing steps which structure the received PDF by sending it to a MLLM, then store it into intermediate tables and run different approaches to fill Business Central values (including LLM approaches).

After the E-Document processing pipeline has done it's best, the BC-agent-framework user defined in this app starts complementing the proposed values in the intermediate tables (known as the draft page).

Once the user is satisfied with the values in the draft page, the agent proceeds with E-Document finalization, which creates a Purchase Invoice or, for a recognized vendor credit note, a Purchase Credit Memo. The E-Document pipeline owns credit-note classification, amount normalization and application to the referenced posted invoice.

> Note: Within this version, there is an ECS experiment that skips the E-Document logic that fills in values and changes the agent prompt to do this logic itself instead. 

#### Version 2: Payables Agent

In this version, the entity at the center is the Payables Agent Task. Defined in this AL app. There is no involvement of the E-Document framework.

The agent task is created with direct information about its source, the agent user directly consults it, and creates the appropriate Purchase Invoice directly, without any draft page. Credit memo creation is not supported in version 2.

Base-block PDF text extraction uses only the bundled extraction instructions. A separate security prompt and Key Vault lookup are intentionally not introduced for extraction at this stage; agent runtime instruction assembly retains its existing security-prompt handling.

Current gaps of version 2 with respect to version 1, and their plan:
- Email sourcing: Version 1 uses the E-Document import codeunit to source emails, in version 2 ownership will be transferred directly to this AL app.
- Demo invoices
- Customer feedback
- Billing: A larger scope is changing the billing strategy
- Evaluation company Demo-data

## Code in this AL app

### Flows

These are the high-level flows that can be found in this AL app:

- Registration of the agent: Platform-hooks for registering the BC-agent-runtime agent.
- Configuring the Payables Agent: Creating, activating, reconfiguring, deactivating the agent, including applying and reconciling its runtime instructions. This can include functionality like sending demo invoices.
- Task ingestion: Source acquisition, acceptance/rejection policies, deduplication, handoff to the runtime.
- Task execution: The behavioral content of the prompt that the agent user follows, the profile, role center it uses and page customizations, outcome registration.
- Supervision: Human inspection of task progress, sources and outcomes, responding to assistance requests, and reviewing results.
- Upgrade across versions: Schema data upgrades that have historically been required.

#### Patterns followed by flows

- S
ingle authoritative source: Rather than multiple variants that touch the same parts of the process, a single configurable entry point for the flow (when the initiation is owned by this app) that callers configure
- Encapsulation of flow parameters: Having a single wrapping object as parameter for the flow.

### Capabilities

Cohesive product responsibilities whose behavior spans flows or lifecycle stages.

| Capability | Registration | Configuration | Task ingestion | Task execution | Upgrade |
| --- | --- | --- | --- | --- | --- |
| Customer feedback | - | Ask for feedback on disabling the agent. | - | Handle task thumbs feedback and v1 draft feedback. | - |
| KPI | - | - | Count tasks handed to the agent. | Count purchase invoices inserted in a Payables Agent session. | Reclassify v1 finalized-e-document history. |
| Billing | - | Initialize trial eligibility/state. | Exclude trial tasks from billing. | Track v1 e-document draft and line usage; v2 strategy pending. | - |
| Trial | - | Initializes trial if eligible | Consumes trial | - | Consumes trial if they used it previously |

- Customer feedback: Collects data that users may provide as part of input for next iterations.
- KPI: Collects rough metrics to display the work done by the agent. The KPI page and purchase-invoice subscriber belong to this capability; the record and scenario enum belong to the KPI entity.
- Billing: Inserts records that are emitted for billing
- Trial: Free-tier invoices the users have to try out the Payables Agent. The guide page remains here; eligibility, state and allowance belong to the Trial entity.

### Shared mechanisms

Application-wide mechanisms support several owners without deciding a business scenario:

- Telemetry: Root `PA Telemetry` emits shared flow/capability and operational events and supplies the common category dimensions. Draft-based billing and demo-email events are emitted by `PA Draft Based Telemetry` within Compatibility, reusing those shared dimensions.
- Security: Declares agent and human permission sets, entitlements and access surfaces. Configuration owns the flow for obtaining consent and assigning access.

Feature-specific integration, such as a feature's audit event, can remain with its flow, entity or capability owner.

### End-user-facing UX 

Human-facing surfaces for inspecting and reviewing tasks belong to Supervision, separately from the agent workspace; configuration and capability-specific surfaces remain with their respective owners.

### Adjacent functionality owned by the app

Clean-up tool for a livesite problem: Technically not a concern of this AL app, with no better home and real need.

### Patterns for entities

Across the flows and cross-cutting concerns, data persistance may be required. This is done via entities, owning state, invariants independent of their consumers. These materialize in different patterns of AL constructs:
- Tables: If derived state is required for a specific instance, it can live as part of the state of the record.
- Wrapping codeunits: Another approach is to wrap the table, and have derived state live also here as getters that read the appropriate state. This pattern is heavier, but aids in treating under the same contract entities with different backing tables as the v1-v2 change requires.
- Wrapping temporary tables: This approach is used only to supply AL pages that are backed by such table. Useful for pages showing derived values, which we would like sort by.

Entity wrappers own data access, updates and persisted invariants, hiding their backing representations. The Task Source wrapper owns its V2 backing directly and delegates V1 E-Document reads and source creation to the draft-based source adapter; it does not start the V1 import pipeline. Navigation, formatting and caller-specific enrichment belong to consumers. `PA Detailed Task` is only the temporary, sortable backing of task list pages; other code consumes task/source getters directly.

The Setup wrapper may hold an invalid editable proposal, but applying it persists settings and configures backing monitoring together: disabling the agent also disables monitoring, and requesting monitoring on v2 fails until its importer exists. The setup page uses a temporary `Payables Agent Setup` record for the platform UI and initializes it from a read-only Setup projection. Before applying changes or opening the sample guide, the page translates only editable fields into semantic setters on `PA Setup Update Parameters`; no backing-table record is transported through that flow. `PA Setup` also owns the company-to-framework-Agent association: `TryFindAgent` is a read-only lookup by stored user ID with a company-name fallback, while `FindAgentAndReconcileSetup` explicitly creates/repairs the persisted association. The latter uses separate stored records so it does not overwrite an editable proposal. Registration metadata owns the agent display name and summary. `PA Setup Update Parameters` initializes the proposal and framework buffer from stored state; initialization may create the setup singleton and reconcile the agent association unless agent configuration is skipped. It is a request for the configuration flow, not a persisted entity. `PA Setup Update` owns consent, runtime configuration and operation order; wrappers do not commit.

A received Task Source exists before admission and may be accepted or rejected. Intake evaluates external policy such as known senders, setup, trial and agent availability. For a V1 PDF upload, Intake first creates the source, then calls the draft-based intake operation to process the E-Document; its import subscriber calls the same authoritative Intake entry point to create the Agent Framework task. V2 intake creates that task directly after source creation. Acceptance binds the source exactly once. The accepted Task aggregate has one identity, the Agent Framework Task ID, and loads the framework task together with exactly one v1 or v2 source backing. Historical v1 and current v2 tasks therefore share one list without copying e-documents into the v2 table; task capabilities disable actions unsupported by a particular version. Rejected v2 sources remain visible as rejected intake rows without pretending to have an Agent Framework task.

Task mutations reload current state and update only their intended fields. Outcomes must refer to existing purchase invoices, orders, credit memos, posted purchase invoices or posted purchase credit memos; the caller judges business completeness. Only V2 accepts explicit outcome registration; V1 gets its outcome through E-Document finalization. Until the Agent Framework can attach the source PDF to a V2 outcome, the Task entity attaches it during outcome registration through a private helper in its `Agent runtime limitations` region. A posting subscriber conditionally replaces invoice/credit-memo outcome references before the posting commit, ignoring preview and order posting. This is an explicit set-level exception to per-task backing access: the posting flow updates every V2 task row and AGENT-service V1 E-Document still referencing the old outcome, without invoking per-task registration, PDF attachment or title updates.

Currently the identified entities are:
- Setup: Agent's configured state and derived views of that configuration.
- Task Source: Received source information before admission, backed by the active version's source records.
- Task: An accepted Agent Framework task together with exactly one v1 or v2 source backing, runtime and outcome associations, and derived lifecycle views.
- KnownSender: Senders that we have received tasks from in the past and their assigned handling policies.
- KPI: Aggregate and individual KPI entries, with insertion and aggregate lookup owned by the record itself. Historical KPI migrations remain in Upgrade.
- Trial: Eligibility and per-company trial state in isolated storage, including starting, consumption, expiration and reset. Telemetry is emitted through Shared/Telemetry rather than through Registration.


### File system organization

The application is organized by scenario orchestration, logical entities, product responsibilities and shared mechanisms. Placement identifies the dominant owner; a page or procedure may coordinate other owners without requiring another file.

```
Flows/
    Registration/
    Configuration/
        DemoGuide/
    Intake/
    Execution/
        AgentWorkspace/                 Agent profile, role center and agent-only dialog
        Supporting/                     Execution processing (e.g. PDF text extraction)
    Supervision/                        Human task monitoring and shared task-list presentation
    Upgrade/

Entities/
    Setup/
    Task/
    TaskSource/
    KnownSender/
    KPI/                                KPI record, scenario enum and record operations
    Trial/                              Trial state and lifecycle

Capabilities/
    Trial/                              Trial guide page
    KPI/                                Page and purchase-invoice event subscriber
    Feedback/

Shared/
    Telemetry/                           Shared emission and dimensions, grouped by flow and capability
    Security/                           Shared human roles and V2 agent permission sets
    Versioning/                         Shared V1/V2 selection and vocabulary, not V1-only behavior

Compatibility/
    DraftBased/                         Irreducibly V1/E-Document behavior and declarative surfaces
        Flows/
            Configuration/
                DemoGuide/
            Intake/                     V1 import operation and its admission subscriber
            Execution/
                AgentWorkspace/                 V1 draft, purchase invoice and purchase credit memo customizations
        Entities/
            TaskSource/                 V1 E-Document source backing adapter
        Capabilities/
            Billing/
        Shared/
            Security/                   V1-only agent permission sets
            Telemetry/                  V1-only billing and demo-email events
        TestSupport/

Operations/
    EmailStorageCleanup/

TestSupport/                            App-owned semantic fixture API and version dispatch for test apps

_Development/                           DEVELOPMENT-only objects (underscore retained)
_Obsolete/                              Historical schema/lifecycle objects (underscore retained)
.resources/
```

Setup and Task entities use the shared version selector. Keeping that selector under Shared avoids making entities depend on a registration flow; registering the agent still belongs to Flows/Registration.

`Payables Agent Tasks` is one page shared by people and the agent. Its list, sortable temporary backing and presentation helper are under Supervision by dominant use; the page still hosts intake actions and an agent-only extraction workaround. `PA Register Outcome` stays in the agent workspace. V1-only profile, page customizations and agent permission sets remain in Compatibility, in a structure parallel to the populated root areas; shared human permission sets stay at the root. The V1/V2 Setup and Task wrappers retain backing access in Entities.

Declarative objects directly bound to draft-based surfaces, such as profiles and page customizations, remain draft-based when their definitions cannot be shared; a shared helper does not make the containing object version-neutral.

## Other code conventions
- All code is `internal` when possible (pages can't be), the extensibility of the agents is a separate story and not done via traditional AL customizations.
- AI tests use app-owned semantic fixture entry points. `TestSupport` hides version dispatch, while backing-specific fixture implementations stay under the corresponding compatibility boundary; the AI test app does not reference E-Document backing records directly. Some BCApps non-AI wrapper contract tests still inspect V2 backing data directly; treat those as explicit test-boundary review items, not examples for new AI tests.
- var block location

### Architectural static validations

`architecture-rules.json` configures the app's dependency boundaries and other architectural conventions. `architecture-rules.schema.json` validates that configuration in the editor and at runtime. There are no external source catalogs. Run the checked-out scanner with PowerShell 7 (required for `Test-Json` JSON Schema validation and `ConvertFrom-Json -AsHashtable`). The lightweight change selector supports Windows PowerShell 5.1 as well as `pwsh`, like the surrounding pipeline scripts:

```powershell
./build/scripts/Test-PayablesAgentArchitecture.ps1
./build/scripts/Test-PayablesAgentArchitecture.ps1 -WarningsAsErrors
$architectureTests = Get-ChildItem ./build/scripts/tests/ALArchitecture*.Test.ps1
Invoke-Pester -Script $architectureTests.FullName
```

Paths above are repository-relative. CI runs the same entry point in PR validation (including merge queues) and Apps W1 builds, before AL-Go cache/skip decisions. Local editor/compiler builds do not run it automatically.

#### Small checks, not another AL parser

The checker masks comments and single-quoted strings, preserving line numbers. Quoted identifiers are opaque, including embedded comment markers and escaped quotes. Object declarations must start on conventional declaration lines. All preprocessor branches are scanned; the checker does not evaluate AL expressions or bind symbols through `using` directives.

- **Local dependencies** (`check: dependencies`): `from` selects callers and `to` selects target objects by app-relative paths and optional object kinds. References are matched by **type and name**, so `Record "Payables Agent Task"` is not a dependency on the same-named codeunit. Explicit typed references/object constants, direct object-valued properties (`SourceTable`, navigation, `RoleCenter`, `Profile`), simple `TableRelation = Table[.Field]`, and extension/customization targets are recognized. A short `symbols` list of `{ kind, name }` can replace `to` for framework contracts such as task builders. There is no external source scan.
- **External boundaries** (`check: namespaces`): namespace imports, declarations and fully qualified uses are a conservative proxy for an external dependency, even for unused imports. Prefixes include child namespaces, but not similarly named siblings. E-Document namespaces are checked separately from local dependencies. Other external boundaries can use the same check without adding catalogs.
- **Object properties** (`check: properties`): require explicit, unconditional object-header properties. `Access = Internal` applies only to supporting kinds; `Extensible = false` applies to pages, tables and enums. Specific temporary table/page projections are pinned independently. Values are booleans or simple unquoted AL identifiers, not general AL expressions. Field/control properties cannot satisfy an object property requirement.
- **Code ownership** (`check: forbiddenCode`): small, named code-pattern policies reject explicit entity commits and interactive UI, and centralize telemetry emission. They examine code with comments, strings and quoted identifiers masked, not procedure bodies or a call graph.
- **Development isolation** (`check: developmentOnly`): `_Development` files require a whole-file `#if DEVELOPMENT` wrapper, without an outer `#else` or code after its closing directive.
- **Manifest policy** (`check: manifest`): restrict friend-app IDs, test-library dependencies and production preprocessor symbols.
- **Placement** (`check: placement`): require the app namespace and approved owner paths. Existing `_Obsolete` paths are explicitly listed, preventing that directory from becoming a home for new code.

Selectors have required `paths` and optional `kinds`. Fields are ANDed, array entries are ORed. Only case-insensitive `*` and `?` globs are supported; **`*` spans directories** (there is no separate `**` syntax). File selectors are app-relative forward-slash paths. A rule whose source selector matches nothing, or whose dependency target selector matches no objects, fails configuration validation.

Example local boundary:

```json
{
    "id": "PA005",
    "check": "dependencies",
    "description": "Entities must not depend on flow implementations.",
    "severity": "warning",
    "from": { "paths": ["Entities/*"] },
    "to": { "paths": ["Flows/*", "Compatibility/DraftBased/*"] },
    "exceptions": [
        {
            "from": { "paths": ["Entities/TaskSource/PATaskSource.Codeunit.al"] },
            "target": "Compatibility/DraftBased/Entities/TaskSource/PADraftBasedTaskSource.Codeunit.al",
            "reason": "The source wrapper delegates its V1 backing representation to this adapter."
        }
    ]
}
```

Exceptions need a source selector and a reason; an optional `target` glob narrows them. Dependency targets are object paths (or `kind:name` for explicit symbols), namespace targets are configured prefixes, property targets are property names, and manifest targets use `symbol:`, `friend:` or `dependency:` prefixes. Exceptions that no longer suppress a finding fail the gate, including on warning rules. Temporary backing references and declarative grants need explicit exceptions rather than inferred exemptions.

#### Deliberate limitations and rollout

This gate does **not** resolve numeric/dynamic object IDs, indirect calls, aliases, implicit enum expressions, page parts/dataitems, compound/qualified table relations, CalcFormula expressions, transitive commits, effective action visibility or persisted-versus-temporary use. Explicitly qualified local references can be compared with the declared target namespace, but unqualified same-type/same-name objects are conservatively potential matches; no namespace binding is attempted. These limitations belong in a future custom analyzer, not an expanding PowerShell parser.

The original cleanup boundaries remain warnings until their callers are migrated. Visibility/extensibility, fixture isolation, entity commit/UI ownership, telemetry ownership, development wrappers, manifest access and projection contracts are blocking. Historical non-extensible-property exceptions name only existing obsolete files. The `DEVELOPMENT` manifest rule is temporarily a warning: the base-block's V2 evaluation override currently requires that symbol. Removing it must be coordinated with a production-safe evaluation/version-selection seam, not done as a static-check side effect.

The NAV AI-test app owns its own gate; BCApps does not depend on that private checkout. The reusable namespace and manifest checks can enforce the same E-Document isolation there. V1/V2 behavior, diagnostics semantics, monitoring reconciliation and task invariants remain responsibilities of AL contract tests and scenario runs, not these textual checks.

