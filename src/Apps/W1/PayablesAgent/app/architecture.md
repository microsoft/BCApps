# Payables Agent

The Payables Agent is a per-company BC-agent-runtime agent. It deals with the creation of Purchase Invoices in Business Central from unstructured input.

A BC-agent-runtime agent, is an LLM-based agent that operates on a logical client of Business Central with it's own profile and user assigned.

The Payables Agent supports the following user-level capabilities:
- Find an appropriate vendor for the intended invoice
- Suggest creating a vendor if it can't be found
- Filling in all header and line-level properties that can be interpreted from the input, or from history of how the users usually fill in these values.
- Match to existing Purchase Orders in order to invoice them when the invoice created by the Payables Agent is posted.

## Payables Agent V1 and V2

There are two versions of the Payables Agent, distinguished by the entity that they base their work on. In version 1, the agent operates by receiving an "E-Document" (which in practice is limited to only PDFs received via e-mail or uploaded manually) and creates a Purchase Invoice by processing the E-Document. In version 2, the input is represented by a "Payables Agent Task" and the agent user directly creates the Purchase Invoice.

### Version 1: Draft-based Payables Agent

An ad-hoc E-Document Service polls via the M365 connector, Outlook emails with PDF attachments, which are then interpreted as artificial E-Documents. When such an E-Document is created, an agent-framework task is created, which then goes and process the e-document into a purchase invoice.

A lot of the functionality that the Payables Agent feature provides is really provided by the E-Document import processing pipeline. The agent invokes processing steps which structure the received PDF by sending it to a MLLM, then store it into intermediate tables and run different approaches to fill Business Central values (including LLM approaches).

After the E-Document processing pipeline has done it's best, the BC-agent-framework user defined in this app starts complementing the proposed values in the intermediate tables (known as the draft page).

Once the user is satisfied with the values in the draft page, the agent proceeds with the E-Document finalization, which creates a Purchase Invoice.

> Note: Within this version, there is an ECS experiment that skips the E-Document logic that fills in values and changes the agent prompt to do this logic itself instead. 

### Version 2: Payables Agent

In this version, the entity at the center is the Payables Agent Task. Defined in this AL app. There is no involvement of the E-Document framework.

The agent task is created with direct information about its source, the agent user directly consults it, and creates the appropriate Purchase Invoice directly, without any draft page.

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

- Single authoritative source: Rather than multiple variants that touch the same parts of the process, a single configurable entry point for the flow (when the initiation is owned by this app) that callers configure
- Encapsulation of flow parameters: Having a single wrapping object as parameter for the flow.

### Capabilities

Cross-cutting concerns that need to be consistent across several flows that own their own state. Their supporting tables, wrappers and views belong with the capability.

| Concern | Registration | Configuration | Task ingestion | Task execution | Upgrade |
| --- | --- | --- | --- | --- | --- |
| Customer feedback | - | Ask for feedback on disabling the agent. | - | Handle task thumbs feedback and v1 draft feedback. | - |
| KPI | - | - | Count tasks handed to the agent. | Count purchase invoices inserted in a Payables Agent session. | Reclassify v1 finalized-e-document history. |
| Billing | - | Initialize trial eligibility/state. | Exclude trial tasks from billing. | Track v1 e-document draft and line usage; v2 strategy pending. | - |
| Trial | - | Initializes trial if eligible | Consumes trial | - | Consumes trial if they used it previously |

- Customer feedback: Collects data that users may provide as part of input for next iterations.
- KPI: Collects rough metrics to display the work done by the agent
- Billing: Inserts records that are emitted for billing
- Trial: Free-tier invoices the users have to try out the Payables Agent.

### Concerns

Other cross-cutting concerns that appear in several flows, but that don't own state

| Concern | Registration | Configuration | Task ingestion | Task execution | Upgrade |
| --- | --- | --- | --- | --- | --- |
| Telemetry | Record agent identity/dimensions. | Log setup and activation. | Log accepted and rejected tasks and trial counts. | Log task-related events and v1 billing. | - |
| Security |

- Telemetry: Emits telemetry with certain conventions
- Security: end-user permissions, audit, consent

Shared mechanisms belong with the concern; feature-specific integration, such as a feature's audit event, can remain with its owner.

### End-user-facing UX 

Human-facing surfaces for inspecting and reviewing tasks belong to Supervision, separately from the agent workspace; configuration and capability-specific surfaces remain with their respective owners.

### Adjacent functionality owned by the app

Clean-up tool for a livesite problem: Technically not a concern of this AL app, with no better home and real need.

### Patterns for entities

Across the flows and cross-cutting concerns, data persistance may be required. This is done via entities, owning state, invariants independent of their consumers. These materialize in different patterns of AL constructs:
- Tables: If derived state is required for a specific instance, it can live as part of the state of the record.
- Wrapping codeunits: Another approach is to wrap the table, and have derived state live also here as getters that read the appropriate state. This pattern is heavier, but aids in treating under the same contract entities with different backing tables as the v1-v2 change requires.
- Wrapping temporary tables: This approach is used only to supply AL pages that are backed by such table. Useful for pages showing derived values, which we would like sort by.

Entity wrappers own data access, updates and persisted invariants, hiding their backing representations. Navigation, formatting and caller-specific enrichment belong to consumers. Task identities and runtime correlation tokens are opaque: callers do not interpret them as storage keys.

The Setup wrapper may hold an invalid editable proposal, but applying it persists settings and configures backing monitoring together: disabling the agent also disables monitoring, and requesting monitoring on v2 fails until its importer exists. `PA Setup Update` owns consent, runtime configuration and operation order; wrappers do not commit.

Task mutations reload current state and update only their intended fields. Outcomes must refer to existing purchase invoices, orders, credit memos, posted purchase invoices or posted purchase credit memos; the caller judges business completeness. A posting subscriber conditionally replaces invoice/credit-memo outcome references before the posting commit, ignoring preview and order posting.

Currently the identified entities are:
- Setup: Agent's configured state and derived views of that configuration.
- Task: Agent task's identity, source information and content access, runtime and outcome associations, and derived lifecycle views.
- KnownSender: Senders that we have received tasks from in the past and their assigned handling policies.


### File system organization

The code in this applicatoin is organized via the flows identified, entities (state, invariants, views), 

```
Bootstrap/
Configuration/
TaskIntake/
TaskExecution/
    AgentWorkspace/                     UX the agent user directly interacts with
    Supporting/                         Execution-specific processing (e.g. text extraction), not entity-state access
Supervision/                            Human-facing task monitoring, assistance and review
Upgrade/

Entities/
    Setup/
    Task/
    KnownSender/

Capabilities/
    Billing/
    Trial/
    KPI/
    Feedback/

Concerns/
    Telemetry/
    Security/

Compatibility/
    DraftBased/                         Here is everything that was required for the draft based agent (e-document based) that we can't merge into a compatibility entity.
        ...                             Same responsibility subdivisions as at the top level

Operations/
    EmailStorageCleanup/

_Obsolete/                              Lifecycle placement for obsolete objects, not a responsibility category
.resources/
```

Declarative objects directly bound to draft-based surfaces, such as profiles and page customizations, remain draft-based when their definitions cannot be shared; a shared helper does not make the containing object version-neutral.

## Other code conventions
- All code is `internal` when possible (pages can't be), the extensibility of the agents is a separate story and not done via traditional AL customizations. This aids in evolving the app.

### Dependency rules

---

# Transition Notes

## Changes in this PR (to be removed from this document, just to keep track in the meantime)

Major rewrite of the app to support v2

- Version 1 stays mostly intact (functionality wise): 
    - KPI functionality stops counting E-Document related metrics, and counts instead Purchase Invoices. Semantic change from E-Documents finalized by the user or the agent, and instead only track the create Purchase Invoices. This is acceptable, since it's not a crucial field, and consolidating behavior is considered more valuable.
    - Configuration for PO-matching was removed: this was already ignored, since the draft page was considering the BaseApp settings, these were just removed as part of the changes.
    - TODO: Let's add a new Email page that is for v2 that doesn't reference E-Documents, and leave the other one as it was. Then remove this line
    - TODO: The change on KnownSenders functinoality to use the email rather than the SourceDetails, while this is probably ok, let's keep it retrieving sources as it was in V1. Then remove this line

- Version 2 is reachable via a flag only reachable by editing the code, and exercises the basic envisioned scenario
    - TODO: wire prompt
    - TODO: Remove dev scaffold table,page. The IsAgentSession:=true (KEEP)
    - TODO: delete the ReceivedAt, CompletedAt of the PATask table, and rather use the createdat, updatedat. remove the Complete().
    - TODO: Edit AKVs with the security prompt for the extraction, rewire (KEEP)

Tests are split from their original home into AI and non-AI tests.

## Personal gates

- Assesment of whether an object was renumbered
- Dependency rules gated by scripts, maybe merge as part of the PR in `build/scripts/` and called in a GH action yaml. (not easy to have custom analyzers)