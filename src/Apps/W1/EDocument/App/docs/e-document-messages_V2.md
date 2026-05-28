# E-Document Messages — Architecture

Status: Draft V2 (supersedes [lifecycle-messages_V1.md](lifecycle-messages_V1.md))
Scope: BC E-Document Core (`src/Apps/W1/EDocument/App`)
Basis: Iterative design refinement of V1 around document/message distinction, format ownership, bi-directionality, and trigger orchestration.

---

## 1. Core distinction: document vs message

V1 used "lifecycle message" as a partly-fuzzy concept overlaid on `"E-Document"`. V2 sharpens it: there are two **categories of artifact**, separated by one test.

| Concept | Becomes a BC document? | Has `IStructuredDataType`? | Examples |
|---|---|---|---|
| **Document** | Yes — read into a draft, then into a Purchase / Sales / Service document | Yes (`GetReadIntoDraftImpl` is the marker) | PEPPOL Invoice, CreditNote, Order |
| **Message** | No — updates parent state, drives workflow, raises notifications | No — different interface (`IEDocumentMessageHandler`) | PEPPOL MLR, Invoice Response, Order Response; French Collected, Negative Collected, Refused |

**A message always relates to an E-Document.** It carries no business meaning standalone.

---

## 2. Bi-directionality (4 quadrants)

V1 covered quadrant 1 only. V2 is symmetric across all four.

| Our role | Parent E-Doc direction | Message direction | Example |
|---|---|---|---|
| Seller | Outgoing | Incoming | Buyer sends us a PEPPOL Invoice Response |
| Seller | Outgoing | Outgoing | We send `Collected` confirming payment receipt (FR) |
| Buyer | Incoming | Outgoing | We send PEPPOL Invoice Response or `Refused` (FR) back to seller |
| Buyer | Incoming | Incoming | Seller sends us a payment confirmation about an invoice they issued to us |

`Direction` is a required field on every message row. Same `Message Type` value can flow either direction; the handler decides what to do per direction.

---

## 3. Data model

### 3.1 New table: `"E-Document Message"`

Separate table — **messages are not discriminated records inside `"E-Document"` (V1's approach)**. They are their own artifact, because they fail the "becomes a BC document" test that defines an E-Document.

```al
table "E-Document Message"
{
    fields
    {
        field(1;  "Entry No.";              Integer)    // PK, auto-increment
        field(2;  "Related E-Document No."; Integer)    // FK -> "E-Document", mandatory (NOT NULL via trigger)
        field(3;  "Message Type";           Enum "E-Document Message Type")  // discriminator
        field(4;  "Direction";              Enum "E-Document Direction")     // Incoming | Outgoing
        field(5;  "Status Code";            Code[20])   // raw protocol code (AB / IP / AP / RE / PD / Collected / Refused / ...)
        field(6;  "Status";                 Enum "E-Doc. Message Status")    // operational state
        field(7;  "Data Storage Entry No."; Integer)    // FK -> "E-Doc. Data Storage" (raw payload blob)
        field(8;  "Service No.";            Code[20])   // which Service handled it
        field(9;  "Sent / Received At";     DateTime)
        field(10; "Created At";             DateTime)
        field(11; "Created By";             Code[50])
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(Parent; "Related E-Document No.", "Direction", "Created At") { }
    }
}
```

**Why a separate table over V1's "discriminated E-Document" model:**

- Messages aren't documents (no `IStructuredDataType`, no draft). Schema should reflect the conceptual line.
- E-Document pages, queries, reports stay clean — no discriminator filter needed everywhere.
- Receive pipeline branches cleanly at classification time: blob → document → `"E-Document"`; blob → message → `"E-Document Message"`.

**Cost accepted:** parallel infrastructure (status enum, list page, log surface). Tracked in Phase 0 scope.

### 3.2 Enums

```al
enum "E-Document Message Type"
{
    Extensible = true;
    value(0; Unknown) { }
    // Format apps and localizations extend with their values + handler binding (see Section 6)
}

enum "E-Doc. Message Status"
{
    value(0; "Pending Send") { Caption = 'Pending Send'; }   // outbound, generated, queued
    value(1; Sent)           { Caption = 'Sent'; }           // outbound, transmitted
    value(2; "Send Failed")  { Caption = 'Send Failed'; }    // outbound, retryable
    value(3; Received)       { Caption = 'Received'; }       // inbound, blob stored
    value(4; Applied)        { Caption = 'Applied'; }        // inbound, changes propagated
    value(5; Ignored)        { Caption = 'Ignored'; }        // inbound, no-op (backward transition, duplicate)
}

enum "E-Doc. Msg. Trigger Source"
{
    Extensible = true;
    value(0; "User Action")       { }  // manual action from an E-Document page
    value(1; "BC Event")          { }  // BC business event (payment applied, ledger reversal, ...)
    value(2; "External Inbound")  { }  // received via connector
    value(3; "Workflow Internal") { }  // chained from another message's apply or workflow response
}
```

### 3.3 `"E-Document Service Status"` enum extension — role-paired

V1 introduced statuses like `Receiver Rejected`. V2 makes them **role-paired** for bi-directionality. Most events are driven by the *receiver* of the parent document; some (payment confirmations from the seller) are driven by the *sender*.

Status names describe **who acted on the parent document**, not who we are. Each value reads correctly on its own.

| Receiver-driven | Sender-driven | Source code(s) |
|---|---|---|
| `Receiver Acknowledged` | `Sender Acknowledged` | AB |
| `Receiver Processing` | — | IP (BIS 63) |
| `Receiver Under Query` | — | UQ |
| `Receiver Conditionally Accepted` | — | CA |
| `Receiver Accepted` | — | AP |
| `Receiver Accepted with Changes` | — | Order Response CA with line changes |
| `Receiver Rejected` | — | RE (BIS 63 + FR Refused) |
| `Receiver Rejected (Validation)` | — | MLR RE (envelope-level) |
| `Receiver Paid` | — | PD (BIS 63: buyer reports paid) |
| — | `Sender Paid` | FR Collected (seller reports payment received) |
| — | `Sender Payment Reversed` | FR Negative Collected |

---

## 4. Format and message ownership

### 4.1 Documents declare their native messages

`IStructuredDataType` (the per-instance carrier for received structured payloads) gains one method:

```al
interface IStructuredDataType
{
    procedure GetFileFormat(): Enum "E-Doc. File Format";
    procedure GetContent(): Text;
    procedure GetReadIntoDraftImpl(): Enum "E-Doc. Read into Draft";

    // NEW: format declares its native message vocabulary
    procedure GetSupportedMessages(): List of [Enum "E-Document Message Type"];
}
```

- PEPPOL document → returns `[PEPPOLInvoiceResponse, PEPPOLMLR, PEPPOLOrderResponse]`.
- ADI / MLLM document → returns `[]`. These are extraction techniques, not messaging protocols.

This is **format-native** vocabulary only.

### 4.2 Cross-format messages declare themselves via handler capability

Some messages aren't owned by a single document protocol. FR Collected (CDAR-encoded) applies to invoices regardless of how the original was exchanged. A format-level list would systematically miss it.

V2 resolves this through handler-level capability discovery (§5.2). Each message handler self-declares applicability for any parent. The framework helper unions the answers.

---

## 5. Message handler interface

### 5.1 Contract

```al
interface IEDocumentMessageHandler
{
    // Capability discovery
    procedure IsApplicableFor(
        ParentEDocument: Record "E-Document";
        Direction: Enum "E-Document Direction";
        TriggerSource: Enum "E-Doc. Msg. Trigger Source"
    ): Boolean;

    // Inbound path
    procedure ParseMessage(var Msg: Record "E-Document Message"; TempBlob: Codeunit "Temp Blob"): Boolean;
    procedure ApplyMessage(var Msg: Record "E-Document Message"): Boolean;

    // Outbound path (transport via existing IDocumentSender)
    procedure GenerateMessage(
        Related: Record "E-Document";
        var Msg: Record "E-Document Message";
        var TempBlob: Codeunit "Temp Blob"
    ): Boolean;

    // Any direction
    procedure ViewMessage(Msg: Record "E-Document Message");
}
```

Inbound-only handlers (PEPPOL MLR receiver) leave `GenerateMessage` as a no-op. Outbound-only handlers (FR Collected) leave `ParseMessage` / `ApplyMessage` as no-ops. Transport stays with existing `IDocumentSender` / `IDocumentReceiver` — handlers shape payloads, they don't move bytes.

### 5.2 Capability discovery — the framework helper

```al
codeunit "E-Doc. Message Mgmt"
{
    procedure GetApplicableMessages(
        ParentEDocument: Record "E-Document";
        Direction: Enum "E-Document Direction";
        TriggerSource: Enum "E-Doc. Msg. Trigger Source"
    ) Result: List of [Enum "E-Document Message Type"]
    var
        MsgType: Enum "E-Document Message Type";
        Handler: Interface IEDocumentMessageHandler;
    begin
        foreach MsgType in Enum::"E-Document Message Type".Ordinals() do begin
            Handler := MsgType;
            if Handler.IsApplicableFor(ParentEDocument, Direction, TriggerSource) then
                Result.Add(MsgType);
        end;
    end;
}
```

Pages, BC event subscribers, workflow setup UI, and admin views all call this single helper. Per-handler logic stays distributed; callers get one API.

### 5.3 Why per-handler, not per-format

Cross-format applicability. PEPPOL handler shouldn't know FR Collected exists. FR Collected handler shouldn't know which formats it interoperates with. Each handler self-describes — framework unions.

---

## 6. Message type extension pattern

A format implementer (PEPPOL app, French localization, etc.) defines new messages by:

1. Extending the `"E-Document Message Type"` enum
2. Binding each value to a handler codeunit via `Implementation`
3. Implementing `IEDocumentMessageHandler`

```al
// PEPPOL app
enumextension PEPPOLMessages extends "E-Document Message Type"
{
    value(100; PEPPOLInvoiceResponse) {
        Implementation = IEDocumentMessageHandler = "EDoc PEPPOL InvResp Handler";
    }
    value(101; PEPPOLMLR)           { Implementation = ...; }
    value(102; PEPPOLOrderResponse) { Implementation = ...; }
}

// French localization app
enumextension FRMessages extends "E-Document Message Type"
{
    value(200; FRCollected) {
        Implementation = IEDocumentMessageHandler = "EDoc FR CDAR Collected";
    }
    value(201; FRNegativeCollected) { Implementation = ...; }
    value(202; FRRefused)           { Implementation = ...; }
}
```

The handler internally chooses how to store payload data — raw blob via `"E-Doc. Data Storage"` (referenced from the message row), plus optional format-specific auxiliary tables when fast structured access matters. The framework only sees the message row.

---

## 7. Trigger orchestration

> **Open — needs further design exploration before Phase 4 (French localization).** This section captures the V2 lean. Detailed design lives in a follow-up doc.

### 7.1 Trigger source taxonomy

Three input categories fan in to message generation; all flow to the same downstream pipeline.

| Source | Examples | Wired by |
|---|---|---|
| BC Event subscriber | Payment applied → Collected; payment unapplied → Negative Collected | New subscriber codeunits per BC event |
| User Action on E-Doc page | "Refuse Invoice", "Send Response" buttons | Page actions calling `GetApplicableMessages` + Generate |
| External Inbound | Connector pushes a UBL ApplicationResponse | Receive classifier (extends current receive pipeline) |
| Workflow Internal | Auto-MLR after inbound parse succeeds | Workflow response |

### 7.2 Reusing the workflow engine

Existing documents flow: BC posting event → subscriber → lookup Document Sending Profile per customer → fire workflow event → workflow responses orchestrate send.

V2 mirrors this for messages: BC event / user action → subscriber or page action → lookup Message Sending Profile → fire workflow event → workflow responses orchestrate generation + send.

New plumbing:

- **Events**: `OnCustLedgerPaymentApplied`, `OnCustLedgerPaymentUnapplied`, `OnInboundMessageApplied`, `OnUserMessageRequested`, ...
- **Responses**: `GenerateEDocumentMessage`, `SendEDocumentMessage`
- **Reused**: service config, log infrastructure, retry, telemetry, error handling

Localizations ship workflow templates (FR template: "On Payment Applied for French Customer → Generate Collected → Send via FR e-reporting Service"). Tenants customize without code.

### 7.3 Direct vs workflow — opt-in pattern

Mirror the existing `Extended Service Flow` opt-in on Document Sending Profile:

- **Default**: direct generation + send queue. Suitable for trivial cases ("user clicks Refuse → generate → send").
- **Opt-in**: enable workflow on a trigger for approval chains, branching, conditional routing.

### 7.4 Open design calls (track separately, not blocking V2 scaffolding)

| # | Question | Lean |
|---|---|---|
| TO1 | Profile keyed off **Service** (matches integration), **Customer** (matches doc sending profile), or both? | Service-primary with optional customer-level override |
| TO2 | Trigger registry: one enum + dispatch, or direct subscribers per trigger? | Direct subscribers initially; revisit if registration burden grows |
| TO3 | Workflow event granularity: one event per trigger kind, or one mega-event with payload discrimination? | One per kind — clearer setup UX |
| TO4 | How does opt-in workflow declare a "skip workflow if condition X" path, since the current Document Sending Profile flag is binary? | Investigate per-trigger flag, or per-customer override |

---

## 8. Lifecycle codes and message sequencing

Each message carries **one** protocol Status Code. A multi-step lifecycle (`AB → IP → UQ → AP → PD` per PEPPOL BIS 63) is the **sequence of message rows** under the same parent, not nested codes inside one row.

Structured payload *within* one message (PEPPOL Order Response with per-line changes; MLR with `cac:LineResponse` rule IDs) lives in handler-managed storage:

- Raw payload in `"E-Doc. Data Storage"` (referenced via `Data Storage Entry No.`).
- Optional auxiliary tables maintained by the handler for fast structured access (e.g., line-change rows for Order Response review).
- `ViewMessage()` decodes on demand for display.

The framework sees one row per message and doesn't crack internals.

### Status advancement guard

Inbound messages can arrive out of order. Apply step enforces per-protocol advancement.

- **PEPPOL BIS 63 (Invoice Response)**: `AB → IP → UQ → CA → RE | AP → PD`. Backward transitions ignored (`OP-BR111-R004/R005`), not errored.
- **MLR / Order Response**: no advancement table — latest applied wins, prior rows kept for audit.

Guard logic lives **inside the relevant handler's `ApplyMessage`**, not in framework code. Per-protocol rules belong with the protocol.

---

## 9. Worked examples

### 9.1 Inbound PEPPOL Invoice Response (Seller side, the V1 case)

```
1. Connector delivers a UBL ApplicationResponse blob through the existing receive pipeline.
2. Receive classifier inspects root + cbc:CustomizationID; recognizes it as a PEPPOL Invoice Response.
3. Classifier extracts cac:DocumentReference → looks up parent outbound "E-Document" scoped to the receiving Service.
   - Found: creates "E-Document Message" row with Direction = Incoming, Message Type = PEPPOLInvoiceResponse,
           Status = Received, Data Storage Entry No. = (new blob row).
   - Not found: stashes raw blob in "E-Doc. Unresolved Message" quarantine (§11), notifies admin.
4. Job picks up Status = Received row; calls Handler.ParseMessage → reads Status Code ("AP" / "RE" / etc.).
5. Handler.ApplyMessage:
   - Locks parent's "E-Document Service Status" row.
   - Runs PEPPOL BIS 63 advancement guard (backward transitions → row Status = Ignored).
   - Updates parent Service Status to "Receiver Accepted" (or appropriate value).
   - Fires workflow event "OnEDocumentMessageApplied".
   - Sets row Status = Applied.
6. Tenant workflows / notifications fire from the event.
```

### 9.2 Outbound FR Refused (Buyer side, user-action triggered)

```
1. User opens an Incoming "E-Document" for a received purchase invoice. Clicks "Send Message".
2. Page action calls EDocMessageMgmt.GetApplicableMessages(parent, Outgoing, UserAction).
3. Returned list (each candidate's IsApplicableFor returned true):
   - PEPPOLInvoiceResponse  (yes — buyer-side outbound, parent format is PEPPOL)
   - PEPPOLMLR              (yes)
   - FRRefused              (yes — customer is French, parent is purchase invoice)
4. User picks FRRefused. Follow-up dialog captures reason code + description.
5. Framework creates "E-Document Message" row, Direction = Outgoing, Status = Pending Send.
6. Handler.GenerateMessage → builds the XML into a TempBlob → persisted to "E-Doc. Data Storage" → referenced from message row.
7. Workflow (or direct) triggers send via IDocumentSender of the message's Service.
8. On success: row Status = Sent. Parent's Service Status = "Receiver Rejected" (we, the receiver, rejected).
9. Workflow event "OnEDocumentMessageSent" fires.
```

### 9.3 Outbound FR Collected (Seller side, BC event-triggered)

```
1. User applies a payment to a customer ledger entry that closes a sales invoice.
2. EDocPaymentStatusSubscribers catches OnAfterPostCustLedgerEntry.
3. Subscriber identifies the related outbound "E-Document" via document number / Cust. Ledger Entry link.
4. Looks up Message Sending Profile per customer (or service-level default).
5. Profile says "FR e-reporting": fires workflow event "OnCustLedgerPaymentApplied" with payload (E-Doc + payment context).
6. Workflow response chain: GenerateMessage(FRCollected) → SendMessage via FR Service.
7. Row created, Direction = Outgoing, Status transitions Pending Send → Sent.
8. Parent E-Document Service Status = "Sender Paid".
```

### 9.4 Outbound PEPPOL Order Response with line changes (Buyer side, future phase)

Phase 3 deliverable. Adds the "E-Document Message Review" page (line-by-line accept / reject / edit-and-accept). Mirror of V1's seller-side Order Response Review described in §2 Scenario B of the original PEPPOL Responses proposal; data lives in handler-managed auxiliary tables.

---

## 10. Phased delivery

| Phase | Deliverable | Risk |
|---|---|---|
| 0 | Core scaffolding: `"E-Document Message"` table + page + list, `"E-Document Message Type"` empty extensible enum, `"E-Doc. Message Status"` enum, `"E-Doc. Msg. Trigger Source"` enum, `IEDocumentMessageHandler` interface, `EDoc.Message.Mgmt.GetApplicableMessages` helper, `IStructuredDataType.GetSupportedMessages()` addition, role-paired Service Status values, classifier wiring in receive pipeline, unresolved-message quarantine (§11). **No handlers yet.** | Low — additive scaffolding. |
| 1 | Inbound PEPPOL handlers: MLR + Invoice Response (Seller-side receive — V1's main case). BIS 63 advancement guard. Workflow events `OnEDocumentMessageReceived` + `OnEDocumentMessageApplied`. Pre-baked workflow responses for notify / block payment journal. | Low. |
| 2 | Outbound PEPPOL handlers: MLR + Invoice Response generation (Buyer-side send). "Send Message" action on Incoming E-Document with filtered list UX. | Medium — first bi-directional family; first time user-triggered generation goes through the helper. |
| 3 | PEPPOL Order Response (inbound + outbound) with "E-Document Message Review" page. Posting block subscriber on Purchase Header. | Medium — UX-heavy. |
| 4 | French e-reporting: FRCollected, FRNegativeCollected, FRRefused. First **cross-format** message family. Adds Cust. Ledger subscribers + Message Sending Profile concept. Validates trigger orchestration model (§7) end-to-end. | Medium — first jurisdictional handler set; design call TO1–TO4 must close before this lands. |
| 5+ | Additional format / jurisdictional messages (Order Change T114, Order Cancellation T115, German XRechnung, A-NZ PEPPOL, etc.) | Defer. |

---

## 11. Unresolved-message quarantine

When inbound classification cannot match an incoming message to its parent E-Document (genuinely orphaned, tenant moved between connectors, partner misconfiguration), the raw blob is preserved and surfaced for manual handling. Same pattern as V1 §1:

- **Not** inserted as a message row — the FK invariant ("every `"E-Document Message"` has a parent E-Document") stays intact.
- Stored in `"E-Doc. Unresolved Message"` (rename of V1's `"E-Doc. Unresolved Response"`): metadata (sender endpoint, attempted reference IDs, timestamps) + pointer to `"E-Doc. Data Storage"` for the blob.
- "Unresolved E-Document Messages" admin page lets the user manually link to a parent E-Document (which then runs the normal message pipeline) or delete.

Retention is out of scope for Phase 0 (Q10 below). For Phase 2+, telemetry on quarantine count informs whether retention policy is needed.

---

## 12. Decisions captured

| # | Decision | Why |
|---|---|---|
| D1 | Messages are a **separate table** from `"E-Document"`, not a discriminated record inside it. | Documents and messages are different categories of artifact (only documents become BC drafts). Schema reflects the concept. |
| D2 | A message always has a mandatory FK to a parent E-Document. | Reality: an unmatched message is a delivery error, not an artifact. Aligns with finance reality. |
| D3 | Unresolved messages go to a quarantine table, **not** the message table. | Preserves the FK invariant while keeping a recovery path. |
| D4 | The parent E-Document's Service Status is the aggregate state users watch. Message rows have their own internal lifecycle. | One status field for the human; message lifecycle is operational, not primary UX. |
| D5 | Format implementer (incl. localizations) owns its **native** message vocabulary, declared via `IStructuredDataType.GetSupportedMessages()`. | Same protocol = same vocabulary. Localization ships its own format with its own messages. |
| D6 | Cross-format applicability handled at the **handler** level via `IsApplicableFor`, not at the format level. | FR Collected applies to invoices regardless of original format. Format-owned list would miss it. |
| D7 | Dispatch is per-document via `IsApplicableFor(parent, direction, trigger source)`. | UI / triggers / workflows need state-aware filtering, not just format-aware. |
| D8 | Capability filtering uses three axes: parent direction, message direction, trigger source. | Each axis encodes a distinct constraint; combined they cleanly distinguish auto-only from user-only messages. |
| D9 | One table `"E-Document Message"` — no separate Detail table (V1's `Response Detail` is gone). | Structured payload lives in blob + handler-managed storage. Framework doesn't need to query internals. |
| D10 | Status codes carried per-row, not nested. Lifecycle = sequence of rows. | Matches spec semantics (each PEPPOL Invoice Response carries one code). |
| D11 | Service Status enum values are **role-paired** (Receiver X / Sender X) where action attribution differs. | Most events are receiver-driven; payment statuses are sender-driven. Each value reads correctly standalone. |
| D12 | Trigger orchestration reuses the existing workflow engine. New workflow events + responses; reused service config. | Same pattern users already understand. |
| D13 | Workflow orchestration is **opt-in** (mirrors `Extended Service Flow`). Default = direct generate + send. | Workflows are overkill for trivial cases ("user clicks Refuse"). |
| D14 | Transport stays with existing `IDocumentSender` / `IDocumentReceiver`. Handlers shape payloads only. | No new connector contract; existing connectors work unchanged. |
| D15 | All V2 changes are additive. No CLEAN deprecations. V1's `E-Document Response` design is superseded before any code ships — nothing to migrate. | No existing tenants on the V1 schema. |

---

## 13. Open questions

| # | Question | Status |
|---|---|---|
| Q1 (V1 SC2) | Does `"E-Document"."Document Record ID"` have a secondary key? Required for posting-block queries that walk BC document → E-Doc → child messages. | Needs schema check before Phase 1. |
| Q2 (V1 SC3) | Concurrency: lock the `"E-Document Service Status"` row on apply, not the parent `"E-Document"` row. | Design tweak — confirm on Phase 1 implementation. |
| Q3 (V1 SC6) | Enum ID allocation for new `"E-Document Service Status"` values — coordinate with connector ecosystem (Pagero, Avalara, Continia). | Open before Phase 0 ships. |
| Q4 (V1 SC12) | Cascade-delete policy when parent E-Document is deleted and messages exist. Audit retention requirements? | Product decision pending. |
| Q5 (V1 §10.5) | Cross-service matching for inbound messages when a tenant moves connectors. Secondary lookup with feature flag? | Mitigation TBD. |
| Q6 (V1 §10.6) | `Receiver Paid` (PD) is *not* a BC payment entry — buyer reported it via PEPPOL. Documentation responsibility to prevent support confusion. | Doc task before Phase 1 ships. |
| Q7 (new) | Trigger orchestration model — profile keying, trigger registry shape, workflow event granularity, conditional opt-in. | **Explored in §7.4; further design needed before Phase 4.** |
| Q8 (new) | UI: single "Send Message" action with filtered lookup, vs specialized actions per message type. | Lean: filtered lookup; specialized buttons via page extension when a localization wants its own surface. |
| Q9 (new) | Page editing while an Order Response review is pending — concurrency model when two users open the review page simultaneously. | Phase 3 page implementation detail. |
| Q10 (new) | Retention policy for unresolved-message quarantine. Could grow indefinitely on high-mismatch tenants. | Phase 2 — instrument first, decide on data. |
| Q11 (new) | Performance: `GetApplicableMessages` iterates all registered handler implementations per page open. Acceptable today; revisit if registered message count grows past ~50. | Monitor via telemetry post-Phase 1. |

---

## 14. Changes from V1

| V1 | V2 |
|---|---|
| "Lifecycle message" terminology | "E-Document Message" |
| Messages = discriminated records inside `"E-Document"` (`Lifecycle Message Type` + `Related E-Document Entry No.` fields) | Messages = separate `"E-Document Message"` table |
| `"E-Document Response Detail"` bag table | Removed — handler owns payload storage; framework only sees the message row + blob |
| `IEDocumentLifecycleMessageHandler` (inbound-shaped, four split methods) | `IEDocumentMessageHandler` (symmetric inbound + outbound + capability discovery) |
| Format defined messages implicitly via global enum values | Format declares native vocabulary via `IStructuredDataType.GetSupportedMessages()`; cross-format apps declare via handler `IsApplicableFor` |
| Single workflow event `OnEDocumentResponseReceived` | Multiple events per trigger kind (§7.2); reuses existing workflow engine; opt-in mirrors `Extended Service Flow` |
| Service Status: directional names assuming we're the sender | Role-paired names (Receiver X / Sender X) for action attribution |
| Trigger orchestration: not explicitly designed | §7: BC events + page actions + classifier all flow into the same workflow substrate; opt-in for complex cases |
| Bi-directionality: 1 of 4 quadrants covered | All 4 quadrants first-class |
| Detail-row queries for clarification reasons, line-changes, etc. | Handler-managed storage; queries are the handler's responsibility |

---

## 15. What to validate before Phase 0 ships

- **Schema** (Q1): confirm or add the key needed for posting-block subscriber.
- **Enum ID allocation** (Q3): reserve a contiguous block in 6100–6199 for new statuses; cross-check with Pagero / Avalara / Continia.
- **One representative connector review**: confirm that adding the receive classifier hook between `DownloadDocument` and E-Document insert does not break their `IDocumentReceiver` implementation. Expectation: no change required, but worth checking.
- **Functional walkthrough with a finance SME** on Scenarios 9.1, 9.2, 9.3. Confirm role-paired status names match accounting expectations.
- **Live BC Architect / domain SME review** of: separate-table choice, classifier placement, handler capability model, opt-in workflow pattern.
