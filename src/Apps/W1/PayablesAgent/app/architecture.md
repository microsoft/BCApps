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

There are two versions of the Payables Agent, distinguished by the entity that they base their work on. In version 1, the agent operates by receiving an "E-Document" (which in practice is limited to only PDFs received via e-mail or uploaded manually) and creates a Purchase Invoice by processing the E-Document. In version 2, the received document is represented by a Payables Agent Work Item and the agent user directly creates the Purchase Invoice. The app-owned Work Item entity also gives V1 E-Documents a common PA-facing lifecycle.

#### Version 1: Draft-based Payables Agent

An ad-hoc E-Document Service polls via the M365 connector, Outlook emails with PDF attachments, which are then interpreted as artificial E-Documents. When such an E-Document is created, an agent-framework task is created, which then goes and process the e-document into a purchase invoice.

A lot of the functionality that the Payables Agent feature provides is really provided by the E-Document import processing pipeline. The agent invokes processing steps which structure the received PDF by sending it to a MLLM, then store it into intermediate tables and run different approaches to fill Business Central values (including LLM approaches).

After the E-Document processing pipeline has done it's best, the BC-agent-framework user defined in this app starts complementing the proposed values in the intermediate tables (known as the draft page).

Once the user is satisfied with the values in the draft page, the agent proceeds with E-Document finalization, which creates a Purchase Invoice or, for a recognized vendor credit note, a Purchase Credit Memo. The E-Document pipeline owns credit-note classification, amount normalization and application to the referenced posted invoice.

> Note: Within this version, there is an ECS experiment that skips the E-Document-owned logic that fills in values and changes the agent prompt to do this logic itself instead.

#### Version 2: Payables Agent

In this version, the entity at the center is the Payables Agent Work Item, backed by an app-owned record. There is no involvement of the E-Document processing framework.

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

TODO: what is a good definition of a flow?
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
- Outcomes: Stateless purchase-document outcome validation and document/vendor facts, with data-only temporary output. These support entity invariants, execution and presentation without representing Work Item state.

Feature-specific integration, such as a feature's audit event, can remain with its flow, entity or capability owner.

### End-user-facing UX 

Human-facing surfaces for inspecting and reviewing tasks belong to Supervision, separately from the agent workspace; configuration and capability-specific surfaces remain with their respective owners.

### Adjacent functionality owned by the app

Clean-up tool for a livesite problem: Technically not a concern of this AL app, with no better home and real need.

### Patterns for entities

Across the flows and cross-cutting concerns, data persistance may be required. This is done via entities, owning state, invariants independent of their consumers. These materialize in different patterns of AL constructs:
- Tables: If derived state is required for a specific instance, it can live as part of the state of the record.
- Wrapping codeunits: Another approach is to wrap the table, and have derived state live also here as getters that read the appropriate state. This pattern is heavier, but aids in treating under the same contract entities stored in different tables as the v1-v2 change requires.
- Wrapping temporary tables: This approach is used only to supply AL pages that are backed by such table. Useful for pages showing derived values, which we would like sort by.

Entities own persistence access and operations required to prevent invalid stored state, including relationships across their stored records. They may also expose queries and derived facts. They do not own an entire scenario merely because that scenario ultimately writes their records. Intake policy, trial/billing, runtime setup and UI sequencing are orchestrated by flows that depend on entities, never by entities calling back into those flows. Optional entity regions separate stored state, loading/identity, queries and persisted commands. Private helper groups should name their actual responsibility; Work Item uses agent-task validation, email metadata cache, and handle lifecycle guards/reset rather than an opaque implementation bucket.

`PA Work Item` is the single semantic entity for received, rejected and accepted material. It owns its V2 table and delegates V1 E-Document persistence/correlation to `PA Draft Based Work Item`. `PA Work Item List Row` is only a temporary sortable UI projection; `PA Purchase Outcome Facts` is data-only output from stateless purchase-reference queries. Neither is another persisted entity.

The Setup wrapper may hold an invalid editable proposal, but applying it persists settings and configures version-specific mailbox monitoring together: disabling the agent also disables monitoring, and requesting monitoring on v2 fails until its importer exists. The setup page uses a temporary `Payables Agent Setup` record for the platform UI and initializes it from a read-only Setup projection. Before applying changes or opening the sample guide, the page translates only editable fields into semantic setters on `PA Setup Update Parameters`; no stored setup record is transported through that flow. `PA Setup` also owns the company-to-framework-Agent association: `TryFindAgent` is a read-only lookup by stored user ID with a company-name fallback, while `FindAgentAndReconcileSetup` explicitly creates/repairs the persisted association. The latter uses separate stored records so it does not overwrite an editable proposal. Registration metadata owns the agent display name and summary. `PA Setup Update Parameters` initializes the proposal and framework buffer from stored state; initialization reads stored state/defaults without creating the setup singleton or reconciling its agent association. It is a request for the configuration flow, not a persisted entity. `PA Setup Update` owns consent, runtime configuration and operation order; wrappers do not commit.

Work Item identity is the SystemId of its stored record: the existing E-Document GUID in V1 or table 3327's SystemId in V2. `Load(Guid)` is the document-side entry; `LoadByAgentTaskId(BigInteger)` and `LoadCurrentSession` resolve the same entity from a framework association.

The current agent session has one home, `PA Agent Access` (Shared/Security), with two deliberately separate questions:

- `TryGetRuntimeAgentTaskId`: the real Payables Agent runtime only. Billing, KPI, V1 document binding and `PA Work Item.LoadCurrentSession` use it; they must never act on a simulation.
- `TryGetAgentViewTaskId` / `IsAgentView`: what agent-facing UI behaves as. Runtime association validates company, PA ownership and exactly one stored record. V1 retains its existing numeric external/message correlation; no E-Document copying or identity migration is introduced. V2 keeps its stored association and admission fields. Missing V1 tasks are not reinterpreted as historical policy rejection.

`PA Work Item Intake` coordinates source acquisition, admission policy, runtime instructions, trial/billing and framework task construction. `ReceivePdf` and `Admit` use the same Work Item handle before and after acceptance. V1 import orchestration stays in its compatibility flow; its subscriber invokes authoritative admission. The entity's association/rejection commands preserve stored-record invariants without importing documents, consuming trial, creating runtime tasks or committing.

Work Item mutations reload the current stored record and patch only their intended fields. Registering an outcome validates an existing supported purchase reference; business completeness remains the caller's concern. `PA Purchase Outcomes` under `Shared/Outcomes` is stateless and centralizes that validation and document facts; its temporary facts type belongs to the same supporting mechanism, not the Work Item entity. `PA Work Item Outcome` orchestrates registration, source attachment and framework title synchronization. Its isolated runtime-attachment bridge retains direct access to the V2 entry number solely to preserve the existing attachment naming/idempotency scheme until the framework owns attachments.

The posting flow follows invoice/credit-memo references before commit, ignoring preview/order posting. Its deliberate set-level stored-record write exception updates V2 rows and AGENT-service V1 documents, without per-item attachment, title updates or commits.

Collection owns scoped enumeration/counts and yields loaded Work Items directly to presentation. To preserve existing behavior, supervision still lists accepted framework-backed work and rejected V2 receipts, not every unaccepted V1 E-Document. State mapping and the unfiltered monthly cue remain as acknowledged in `ack-v1-preserved-gaps.md`. Metadata is a lazy snapshot per Work Item handle and is invalidated on load/refresh.

Currently the identified entities are:
- Setup: Agent's configured state and derived views of that configuration.
- Work Item: A received document across admission, execution and outcome, with a GUID identity, version-specific storage and optional framework task association.
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
        Supporting/                     Runtime callbacks, extraction, outcome/posting support and agent permissions
    Supervision/                        Human task monitoring and shared task-list presentation
    Upgrade/

Entities/
    Setup/
    WorkItem/                           Entity, table and collection
    KnownSender/
    KPI/                                KPI record, scenario enum and record operations
    Trial/                              Trial state and lifecycle

Capabilities/
    Trial/                              Trial guide page
    KPI/                                Page and purchase-invoice event subscriber
    Feedback/

Shared/
    Outcomes/                           Stateless validation and data-only facts for purchase-document outcomes
    Telemetry/                           Shared emission and dimensions, grouped by flow and capability
    Security/                           Shared human roles and V2 agent permission sets
    Versioning/                         Active V1/V2 selection and stored work-item version lookup

Compatibility/
    DraftBased/                         Irreducibly V1/E-Document behavior and declarative surfaces
        Flows/
            Configuration/
                DemoGuide/
            Intake/                     V1 import operation and its admission subscriber
            Execution/
                AgentWorkspace/                 V1 draft, purchase invoice and purchase credit memo customizations
        Entities/
            WorkItem/                   V1 E-Document storage and legacy correlation
        Capabilities/
            Billing/
        Shared/
            Security/                   V1-only agent permission sets
            Telemetry/                  V1-only billing and demo-email events
        TestSupport/

Operations/
    EmailStorageCleanup/

TestSupport/                            App-owned semantic fixture API and version dispatch for test apps

_Obsolete/                              Whole-object obsoletion only; active owners retain obsolete members
.resources/
```

Setup and Work Item creation use the shared version selector; existing Work Items resolve the version they are stored in. Keeping that selector under Shared avoids making entities depend on a registration flow; registering the agent still belongs to Flows/Registration.

`Payables Agent Work Items` is one page shared by people and the agent. Its list, sortable temporary list rows and presentation helper are under Supervision by dominant use; the page still hosts intake actions and an agent-only extraction workaround. `PA Register Outcome` stays in the agent workspace. V1-only profile, page customizations and agent permission sets remain in Compatibility, in a structure parallel to the populated root areas; shared human permission sets stay at the root. Setup and Work Item retain table access in Entities; the temporary outcome bridge and posting exceptions are explicitly gated.

Declarative objects directly bound to draft-based surfaces, such as profiles and page customizations, remain draft-based when their definitions cannot be shared; a shared helper does not make the containing object version-neutral.

## Other code conventions
- All code is `internal` when possible (pages can't be), the extensibility of the agents is a separate story and not done via traditional AL customizations.
- AI tests use app-owned semantic fixture entry points. `TestSupport` hides version dispatch, while version-specific fixture implementations stay under the corresponding compatibility boundary; the AI test app does not reference E-Document records directly. Some BCApps non-AI wrapper contract tests still inspect V2 table data directly; treat those as explicit test-boundary review items, not examples for new AI tests.
- var block location

### Architectural static validations

Some of the conventions in this document are checked by lightweight static validations, configured in `architecture-rules.json`. They run in PR validation and can be run locally with `./build/scripts/Test-AdHocALAppValidations.ps1` (PowerShell 7).


# Decision guides

## When is a procedure internal, local, or public?

## Comments discipline

## Order of procedures in an object

## Where are the boundaries of the responsibilities of an Entity?

An entity owns procedures needed to prevent invalid state from being persisted in its represented records and relationships, plus practical queries over that state. Cross-owner policy, billing, runtime configuration, navigation and presentation remain scenario orchestration. A Work Item can exist without an Agent Framework task; the association is a lifecycle fact, not its identity.