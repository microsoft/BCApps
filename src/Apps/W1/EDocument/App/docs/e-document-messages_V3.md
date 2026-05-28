# E-Document Documents and Messages — Foundational Model

Status: Draft V3 (supersedes [e-document-messages_V2.md](e-document-messages_V2.md))
Scope: Conceptual foundation. Defines what Documents and Messages are, how each comes into existence, how Messages drive state on the parent Document, and the data model + interface contracts that express it.

V2 was comprehensive but mixed primitives with phasing, worked examples, and open design calls. V3 trims to the foundation — the mental model an implementer (PEPPOL handler, MX localization, FR e-reporting, connector app) needs before reading or writing any code. Phasing, workflow event design, concurrency mechanics, profile schemas — all deferred until the spike grounds them.

---

## 1. The two primitives

The framework has exactly two kinds of first-class artifact.

### 1.1 Document

A **Document** is a wire artifact that has its own BC identity — either originating from a BC artifact (outbound) or producing one (inbound). The E-Document row is the BC-side handle on the wire artifact in either direction.

| Direction | Path | Interface |
|---|---|---|
| **Outbound** | BC source (posted document, ledger entry, …) → format codeunit builds the sendable blob → send | `"E-Document"` (with `Create()` / `CreateBatch()`) |
| **Inbound** | received blob → classifier routes to draft pipeline → staging tables → BC document | `IStructuredDataType` (marker: `GetReadIntoDraftImpl`) + `IStructuredFormatReader` |

A format implementer typically ships both paths: an outbound `Create()` and an inbound `IStructuredDataType` / `IStructuredFormatReader`. Some formats are one-direction only — MX Payment Complement is outbound-only because the PAC stamps and returns it for storage, not for BC document creation.

Examples:
- PEPPOL Invoice — outbound from a Sales Invoice; inbound to a Purchase Invoice
- MX Payment Complement — outbound only, generated from a Cust. Ledger Entry application
- ContosoInvoice (spike) — both directions

### 1.2 Message

A **Message** relates to an existing E-Document. It updates state on the parent, notifies about its lifecycle, or carries protocol-level meta-information. **It does not produce a BC document.**

| Direction | Path | Interface(s) |
|---|---|---|
| **Outbound** | BC event (posting, application, user action) → Writer builds the blob → send → Type applies state transition | `IEDocumentMessageWriter.GenerateMessage` + `IEDocumentMessageType.ApplyMessage` |
| **Inbound** | received blob → Reader parses → Type applies state transition | `IEDocumentMessageReader.ParseMessage` + `IEDocumentMessageType.ApplyMessage` |

Each message type implements a small `IEDocumentMessageType` codeunit (identity, applicability, state-transition logic, view). The IO is split: `IEDocumentMessageReader` for inbound parsing, `IEDocumentMessageWriter` for outbound generation. The Type returns the appropriate one via `GetReader()` / `GetWriter()`. Inbound-only message types ship a Reader; outbound-only ship a Writer; bi-directional types ship both.

Examples:
- PEPPOL Invoice Response — inbound (seller receives buyer's response) or outbound (buyer sends response to seller)
- PEPPOL MLR — inbound (receiver acknowledges) or outbound (we acknowledge)
- FR Collected — outbound, generated when a payment closes a customer ledger entry
- BC Remittance Advice notification — outbound, N messages per posted remittance — one per referenced invoice

### 1.3 The test, made concrete

> Does the wire artifact have its own BC identity, or does it only affect existing identities?

The test applies the same in either direction.

| Wire artifact | Direction(s) | BC outcome | Modeled as |
|---|---|---|---|
| MX Payment Complement | Outbound only | Stamped UUID; its own outbound E-Document | **Document** |
| PEPPOL Invoice | Outbound + Inbound | Built from Sales Invoice; read into Purchase Invoice | **Document** |
| BC Remittance Advice notification | Outbound | N status updates per referenced invoice; no new BC artifact | **Message** (N rows) |
| PEPPOL Invoice Response | Outbound + Inbound | Updates parent invoice's lifecycle status | **Message** |
| PEPPOL Order Response | Outbound + Inbound | Updates parent order's status; carries line-level proposed changes | **Message** |
| FR Collected | Outbound | Updates parent invoice's status (Sender Paid) | **Message** |

The same wire family — payments — appears on both sides. The framework does not pre-judge; the implementer chooses based on BC intent. The duality is real and load-bearing.

---

## 2. Generation

Both Documents and Messages come into existence through the same shape:

```
Trigger  →  Config lookup  →  Framework API  →  Artifact row created  →  Send pipeline (if outbound)
```

The trigger and the framework API differ; the shape is constant.

### 2.1 Triggers (uniform across Documents and Messages)

| Trigger | Document examples | Message examples |
|---|---|---|
| **BC posting subscriber** | Sales / Purchase / Service Post → outbound invoice E-Doc | Remittance Advice post → N message rows (one per referenced invoice); FR Collected from payment post; FR Negative Collected from payment reversal post |
| **BC application / ledger event subscriber** | Cust. Ledger Entry application → MX Payment Complement | (rare — most payment lifecycle events route through posting subscribers in BC) |
| **User action on E-Doc page** | "Recreate" → regenerate outbound document | "Send Response" / "Refuse" → generate outbound message |
| **User action on BC document page** | (uncommon) | "Approve" on Sales Order → generate ack message |
| **Inbound classifier** | Received invoice blob → inbound Document via draft pipeline | Received response blob → inbound Message via apply pipeline |
| **Workflow response** | Step in a workflow generates a follow-up document | Step in a workflow generates a follow-up message |

Every trigger pattern applies to both kinds of artifact. **The trigger doesn't determine document-vs-message; the artifact's nature does.**

### 2.2 Framework generation APIs

```al
codeunit "E-Doc. Export"                                       // existing — Documents
{
    procedure CreateEDocument(SourceRecordRef: RecordRef; ProfileCode: Code[20]);
}

codeunit "E-Doc. Send Message"                                 // new — outbound Messages
{
    procedure Run(
        Parent: Record "E-Document";
        MessageType: Enum "E-Document Message Type";
        TriggerSource: Enum "E-Doc. Msg. Trigger Source"
    ): Integer;  // returns "E-Document Message"."Entry No."
}
```

Subscribers, page actions, BC actions, classifiers, workflow responses — all call into these two APIs. Two surfaces cover every generation path. The inbound counterpart is `"E-Doc. Receive Messages"`, driven by the receive interface (§5.2) rather than called directly by implementers.

### 2.3 Inbound receive — two entry points (existing one unchanged)

The existing `IDocumentReceiver` and its receive pipeline (Structure → Read → Prepare → Finish) are **unchanged**. Every existing connector implementation continues to work without modification. Documents arrive exactly as they do today.

Messages get a parallel, **opt-in** entry point: a new interface `IDocumentReceiverMessages`. A connector that wants to surface inbound messages from its access point implements it; connectors that only do documents are unaffected.

| Inbound kind | Entry interface | Result row | Downstream pipeline |
|---|---|---|---|
| Document | `IDocumentReceiver` (existing) | `"E-Document"` | Structure → Read → Prepare → Finish |
| Message | `IDocumentReceiverMessages` (new, opt-in extension to `IDocumentReceiver`) | `"E-Document Message"` | Parse → Apply |

**The connector is the classifier — by virtue of which entry point it calls.** Modern e-invoicing networks already type their items at source: a PEPPOL access point hands the connector an Invoice or an ApplicationResponse or an Order Response, each typed. The connector calls the appropriate entry point per item. A connector handling a generic inbox (shared folder, email) can do its own lightweight discrimination — UBL root inspection, filename convention — inside its own code.

**The framework never inspects raw bytes to decide Document vs Message.** It dispatches based on which interface the connector invoked. This keeps the framework format-agnostic and existing connectors untouched.

Parent resolution happens after the Message row is created: the Reader's `ParseMessage` extracts the parent reference from the payload (the Reader knows the format). If resolution succeeds, `Type.ApplyMessage` runs. If it fails — genuinely orphaned message, connector mis-routing — the row is moved to a quarantine table and surfaced to admin for manual handling.

### 2.4 What's *not* automatic

The framework provides primitives. It does **not**:

- Decide whether your wire artifact is a Document or a Message — that's an implementation choice.
- Mandate a specific subscriber set — the implementer wires the BC events relevant to their format.
- Run a state machine that "knows" PEPPOL / MX / FR semantics — that lives in your Type / Reader / Writer.

---

## 3. State transitions

The parent Document carries the visible lifecycle state. Messages cause transitions.

### 3.1 Where state lives

```
"E-Document" (parent document)
    ├── "E-Document Service Status" rows  (the lifecycle state — what users watch)
    │       ↑ updated by
    └── "E-Document Message" rows         (the events causing transitions)
            └── internal Status: Pending / Sent / Received / Applied / Ignored / Failed
```

Two status concepts:

| Concept | Where | Audience |
|---|---|---|
| Parent's **Service Status** | On the Document | Users — the visible lifecycle |
| Message's internal **Status** | On the Message | Operations — Pending Send → Sent, Received → Applied |

The user-facing aggregate state is the parent's Service Status. Message internal status is operational, not primary UX.

### 3.2 The transition mechanism — Type declares intent, framework executes

Transition logic is split. The Type knows the **protocol's semantics** (what status to set, whether this is a backward transition, etc.). Everything else — locking, persistence, logging, event firing — is **uniform** and lives in the framework. This mirrors the pre-existing `IDocumentAction` + `ActionContext` pattern.

| Concern | Who | Why |
|---|---|---|
| Decide new Service Status / Status Code | Type | Protocol-specific |
| Apply advancement guard (e.g., backward → Ignored) | Type | Protocol-specific |
| Lock the parent's `"E-Document Service Status"` row | **Framework** | Concurrency — must be uniform |
| Persist the Service Status update | **Framework** | Uniform persistence |
| Fire workflow event | **Framework** | Uniform broadcast |
| Set message row internal Status (Applied / Ignored / Failed) | **Framework** | Uniform persistence |
| Write log entries (`"E-Document Log"`) | **Framework** | One place to attach audit, telemetry, error helper |
| Add format-specific log enrichment | Type (optional, via context) | Implementer can enrich; never required to log directly |

The Type's `ApplyMessage` therefore **does not** mutate the parent record directly. It receives an `"E-Doc. Msg. Apply Context"` and declares its intent on it (target status, ignore reason, error, log notes). The framework reads the context after `ApplyMessage` returns and executes the transition with proper locking, persistence, logging, and event firing.

```al
codeunit "E-Doc. Msg. Apply Context"
{
    procedure SetParentStatus(NewStatus: Enum "E-Document Service Status");
    procedure SignalIgnored(Reason: Text);                                       // backward transition / duplicate
    procedure SetErrorStatus(NewStatus: Enum "E-Document Service Status"; ErrorText: Text);
    procedure AddLogNote(Description: Text);                                     // optional enrichment of the framework log entry
}
```

Transition trigger points:

| Direction | `Type.ApplyMessage` is invoked by framework after | Outcome on message row |
|---|---|---|
| Inbound | `Reader.ParseMessage` succeeded | `Applied` (or `Ignored` if Type signalled it) |
| Outbound | `Writer.GenerateMessage` + `IDocumentSender.Send` both succeeded | `Sent`, plus parent status advanced per Type's intent |

**Protocol-specific advancement logic lives in the Type, not in framework code.** PEPPOL Invoice Response enforces `AB → IP → UQ → CA → RE | AP → PD`. PEPPOL MLR has no advancement table — latest wins, prior entries kept for audit. Each Type encodes its own rules through the context. The framework provides every other concern uniformly.

### 3.2.1 What the framework logs (uniformly)

For every message lifecycle event, the framework writes to `"E-Document Log"` (same table as existing document log) and the standard telemetry helper. The Type does not call `EDocumentLog` directly.

| Checkpoint | Logged automatically by framework |
|---|---|
| Message row created (inbound or outbound) | Type, direction, parent, source service |
| `Reader.ParseMessage` returns | Success / failure; parent resolved |
| `Type.ApplyMessage` returns | Status transition `X → Y`, or `Ignored` (with reason), or `Error` |
| `Writer.GenerateMessage` returns | Success / failure; payload size |
| Send via `IDocumentSender` | Sent / Send Failed |
| Status transition on parent | "Parent N: Service Status X → Y via Message M" |

Type-side enrichment via `Context.AddLogNote(...)` appends to whichever framework entry is current. Implementers never have to remember to log — the framework records the lifecycle even if the Type does nothing.

### 3.3 Status vocabulary — role-paired

Status values describe **who acted on the parent document**, not who we are. This keeps the values direction-neutral for the reader: a status reads correctly whether we are the sender or the receiver of the parent.

| Receiver-driven | Sender-driven | Source code(s) |
|---|---|---|
| `Receiver Acknowledged` | `Sender Acknowledged` | AB |
| `Receiver Processing` | — | IP (PEPPOL BIS 63) |
| `Receiver Under Query` | — | UQ |
| `Receiver Conditionally Accepted` | — | CA |
| `Receiver Accepted` | — | AP |
| `Receiver Accepted with Changes` | — | Order Response CA with line changes |
| `Receiver Rejected` | — | RE (BIS 63 + FR Refused) |
| `Receiver Rejected (Validation)` | — | MLR RE (envelope-level) |
| `Receiver Paid` | — | PD (buyer reports paid) |
| — | `Sender Paid` | FR Collected, MX Payment Complement acknowledged |
| — | `Sender Payment Reversed` | FR Negative Collected |

### 3.4 Beyond status — side effects

Some messages carry **side effects** beyond a status update. PEPPOL Order Response brings line-level proposed changes (qty, item substitution, delivery date). PEPPOL MLR brings rule-violation references.

These side effects are **the Type's domain**, not framework primitives:

- Structured payload lives in `"E-Doc. Data Storage"` (referenced from the message row).
- Handlers may maintain their own auxiliary tables for fast structured access (e.g., a PEPPOL app's `"PEPPOL Order Response Line"` table).
- UI for review/edit lives in the type — `IEDocumentMessageType.ViewMessage(msg)` is the only framework UX delegation.

The framework provides no generic review/edit page. Different message families need different UX; a lowest-common-denominator framework page would be worse than handler-owned pages. Format apps ship their own.

---

## 4. Data model

Two tables. One existing. One new.

### 4.1 `"E-Document"` (existing — unchanged for V3)

Represents a Document. Already in core. V3 **does not** add discriminator fields here. Messages do not live in this table.

Fields messages reference:
- `"Entry No."` — primary key; Messages FK to this
- `"Direction"` — Incoming | Outgoing (the Document's own direction; message direction is independent)
- `"Document Record ID"` — link to the BC document
- `"E-Document Service Status"` rows (separately keyed) — the lifecycle state Messages mutate

### 4.2 `"E-Document Message"` (new)

```al
table "E-Document Message"
{
    fields
    {
        field(1;  "Entry No.";              Integer)   // PK
        field(2;  "Related E-Document No."; Integer)   // FK -> "E-Document", mandatory (NOT NULL via trigger)
        field(3;  "Message Type";           Enum "E-Document Message Type")  // discriminator
        field(4;  "Direction";              Enum "E-Document Direction")     // Incoming | Outgoing
        field(5;  "Status Code";            Code[20])  // raw protocol code (AB / AP / RE / Collected / Refused / ...)
        field(6;  "Status";                 Enum "E-Doc. Message Status")    // operational state
        field(7;  "Data Storage Entry No."; Integer)   // FK -> "E-Doc. Data Storage" (raw payload blob)
        field(8;  "Service No.";            Code[20])  // which Service handled it
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

### 4.3 Cardinality

| Relationship | Cardinality | Note |
|---|---|---|
| `E-Document` ↔ `E-Document Message` | 1 : N | The lifecycle is the sequence of message rows under one parent |
| Wire artifact ↔ `E-Document Message` rows | 1 : N permitted | One Remittance Advice → one row per referenced invoice. Handler decides cardinality during generation. |
| `E-Document Message` ↔ `E-Doc. Data Storage` | 1 : 1 | The raw blob |

### 4.4 Structured payload within a Message

PEPPOL Order Response carries N line-level changes inside one message. PEPPOL MLR carries N validation rule references. The framework sees one row; the Type (via its Reader / Writer / auxiliary tables) owns what's inside the blob.

The framework does **not** need to query message internals — it tracks lifecycle, dispatches to Type / Reader / Writer, persists rows. Anything domain-specific is the Type's territory.

---

## 5. Interfaces and types

### 5.1 Document-side interfaces (mostly existing)

```al
interface "E-Document"               // outbound: produce a sendable blob from a BC document
{
    procedure Check(...);
    procedure Create(EDocService; var EDocument; SourceHeaderRef; SourceLinesRef; var TempBlob);
    procedure CreateBatch(...);
    procedure GetBasicInfoFromReceivedDocument(...);
    procedure GetCompleteInfoFromReceivedDocument(...);
}

interface IStructuredDataType        // per-instance carrier for received structured payload
{
    procedure GetFileFormat(): Enum "E-Doc. File Format";
    procedure GetContent(): Text;
    procedure GetReadIntoDraftImpl(): Enum "E-Doc. Read into Draft";

    // NEW in V3 — format declares its native message vocabulary
    procedure GetSupportedMessages(): List of [Enum "E-Document Message Type"];
}

interface IStructuredFormatReader    // read structured payload into draft staging
{
    procedure ReadIntoDraft(...);
    procedure View(...);
}

interface IDocumentSender    // outbound transport for Documents (unchanged)
interface IDocumentReceiver  // inbound transport for Documents (unchanged)

// Opt-in extensions — connectors that handle messages also implement these. Existing
// connectors are unaffected. The framework uses `is` / `as` to test for support — same
// pattern as "ISentDocumentActions" extending IDocumentSender today.
interface IDocumentSenderMessages    // outbound transport for Messages
interface IDocumentReceiverMessages  // inbound transport for Messages
```

### 5.2 Message-side interfaces (new)

Three interfaces, split by responsibility. The Type owns identity + state-transition logic + UX; Reader and Writer are pure IO. Reader and Writer never share their concerns with each other or with the Type.

```al
interface IEDocumentMessageType            // identity + applicability + state-transition intent + UX
{
    procedure IsApplicableFor(
        ParentEDocument: Record "E-Document";
        Direction: Enum "E-Document Direction";
        TriggerSource: Enum "E-Doc. Msg. Trigger Source"
    ): Boolean;

    procedure GetSupportedDirections(): List of [Enum "E-Document Direction"];

    procedure GetReader(): Interface IEDocumentMessageReader;
    procedure GetWriter(): Interface IEDocumentMessageWriter;

    // State transition — Type declares intent on the context; framework executes.
    // Called by the framework after inbound parse OR after successful outbound send.
    procedure ApplyMessage(
        var Msg: Record "E-Document Message";
        var Context: Codeunit "E-Doc. Msg. Apply Context"
    ): Boolean;

    // UX delegation — the type owns the message's page.
    procedure ViewMessage(Msg: Record "E-Document Message");
}

interface IEDocumentMessageReader          // inbound — pure parse
{
    procedure ParseMessage(var Msg: Record "E-Document Message"; TempBlob: Codeunit "Temp Blob"): Boolean;
}

interface IEDocumentMessageWriter          // outbound — pure generate (transport reuses IDocumentSender)
{
    procedure GenerateMessage(
        Related: Record "E-Document";
        var Msg: Record "E-Document Message";
        var TempBlob: Codeunit "Temp Blob"
    ): Boolean;
}

interface IDocumentSenderMessages                   // outbound transport for Messages — opt-in extension to IDocumentSender
{
    procedure SendMessage(
        var Msg: Record "E-Document Message";
        var EDocumentService: Record "E-Document Service";
        SendContext: Codeunit SendContext
    );
}

interface IDocumentReceiverMessages                 // inbound transport for Messages — opt-in extension to IDocumentReceiver
{
    // Two stages, matching IDocumentReceiver's ReceiveDocuments / DownloadDocument shape,
    // but with a typed buffer instead of opaque metadata. The buffer carries an optional
    // inline payload — connectors whose access point returns content in the list call
    // (batch APIs, webhook-buffered, etc.) call Buffer.SetPayload(...) during ListMessages;
    // the framework then skips DownloadMessage for those rows.
    procedure ListMessages(
        var Service: Record "E-Document Service";
        var Buffer: Record "E-Doc. Inbound Msg Buffer" temporary
    );

    procedure DownloadMessage(
        var Service: Record "E-Document Service";
        Item: Record "E-Doc. Inbound Msg Buffer" temporary;
        var Payload: Codeunit "Temp Blob"
    );
}
```

**Responsibility per interface:**

| Interface | Owns |
|---|---|
| **Type** | What the message is. When it applies. How its protocol's state advancement works. How to display it. |
| **Reader** | Bytes → structured Message row (parse only). |
| **Writer** | BC source → structured payload bytes (generate only). |

**Dispatch shape:**

```
Inbound:   Reader.ParseMessage → Type.ApplyMessage
Outbound:  Writer.GenerateMessage → (send) → Type.ApplyMessage
```

Protocol-specific advancement rules (PEPPOL BIS 63 sequencing, MLR latest-wins, FR Collected → `Sender Paid`) live once inside `Type.ApplyMessage` — not duplicated between inbound and outbound paths.

**Implementer experience:**

| Direction support | Codeunits |
|---|---|
| Inbound-only (PEPPOL MLR receiver) | 1 Type + 1 Reader. `GetWriter()` throws; framework never calls it because `GetSupportedDirections` excludes Outgoing. |
| Outbound-only (FR Collected, BC Remittance) | 1 Type + 1 Writer. `GetReader()` throws; never called. |
| Bi-directional (PEPPOL Invoice Response) | 1 Type + 1 Reader + 1 Writer. Or one codeunit implementing all three interfaces, returning `this` from `GetReader` and `GetWriter` — same pattern as `"E-Document MLLM Handler"` today. |

**Framework contract:** never call `GetReader()` / `GetWriter()` for a direction the Type does not declare via `GetSupportedDirections`. Unused getters may throw; the framework respects the declared support.

`IDocumentReceiverMessages` is **opt-in**. Existing connectors that only handle documents continue to implement `IDocumentReceiver` and don't change. Connectors that want inbound messages add `IDocumentReceiverMessages` alongside.

### 5.3 Enums

```al
enum "E-Document Message Type"
{
    Extensible = true;
    value(0; Unknown) { }
    // Format apps and localizations extend, binding each value to a type codeunit:
    //
    //   value(100; PEPPOLInvoiceResponse) {
    //       Implementation = IEDocumentMessageType = "EDoc PEPPOL InvResp Type";
    //   }
}

enum "E-Doc. Message Status"
{
    value(0; "Pending Send")  // outbound, generated, queued
    value(1; Sent)            // outbound, transmitted
    value(2; "Send Failed")   // outbound, retryable
    value(3; Received)        // inbound, blob stored, parent resolved
    value(4; Applied)         // inbound, changes propagated to parent
    value(5; Ignored)         // inbound, no-op (backward transition, duplicate)
}

enum "E-Doc. Msg. Trigger Source"
{
    Extensible = true;
    value(0; "User Action - E-Doc Page")
    value(1; "User Action - BC Document Page")
    value(2; "BC Event")              // posting, application, release, reversal
    value(3; "External Inbound")
    value(4; "Workflow Internal")
}
```

### 5.4 Framework helper codeunits

```al
codeunit "E-Doc. Send Message"           // outbound orchestration
{
    // Called by subscribers, page actions, BC document pages, workflows. Creates the row,
    // calls Type.GetWriter().GenerateMessage, persists the blob via "E-Doc. Data Storage",
    // sends via IDocumentSenderMessages, hands off to "E-Doc. Apply Message".
    procedure Run(
        Parent: Record "E-Document";
        MessageType: Enum "E-Document Message Type";
        TriggerSource: Enum "E-Doc. Msg. Trigger Source"
    ): Integer;
}

codeunit "E-Doc. Receive Messages"       // inbound dispatcher
{
    // Driven by the framework (Job Queue, manual action). Calls IDocumentReceiverMessages.ListMessages,
    // iterates the typed buffer, fetches non-inlined payloads via DownloadMessage, resolves the Type,
    // calls Reader.ParseMessage, hands off to "E-Doc. Apply Message".
    procedure Run(var Service: Record "E-Document Service"): Integer;
}

codeunit "E-Doc. Apply Message"          // shared post-event step
{
    // Locks the parent's "E-Document Service Status" row, calls Type.ApplyMessage with an
    // "E-Doc. Msg. Apply Context", reads the declared intent, persists the Service Status
    // update, writes "E-Document Log" entries, fires the OnAfterApply workflow event,
    // updates the message row's internal status (Applied / Ignored / Failed).
    procedure Run(var Msg: Record "E-Document Message"): Boolean;
}
```

The implementer never sees the locking, persistence, log writes, or event firing — those are framework concerns. The Type just declares intent via the `Apply Context`; the Reader and Writer just shape bytes. Framework wraps each call with the rest.

---

## 6. Worked examples

Three end-to-end examples — one of each primitive plus one cross-cutting.

### 6.1 MX Payment Complement (Document, outbound, BC ledger trigger)

```
1. User applies a customer payment to a posted sales invoice. A Cust. Ledger Entry is posted.
2. EDocCustLedgerSubscribers catches OnAfterPostCustLedgerEntry.
3. Subscriber checks: customer / company configured for MX e-invoicing? Yes.
4. Subscriber calls EDocExport.CreateEDocument(CustLedgerEntryRef, "MX Payment Profile").
5. Framework creates outbound "E-Document", Direction = Outgoing.
6. "MX CFDI" format codeunit (binds "E-Document" interface) Create():
     - Reads Detailed Cust. Ledger Entry applications to find referenced invoice UUIDs.
     - Builds Payment Complement XML with <DoctoRelacionado> per applied invoice.
     - Signs with SAT certificate. (Framework default: signing in Create(); see §7.)
7. Send pipeline transmits signed XML to PAC via the configured connector.
8. PAC stamps the XML, returns a UUID via IDocumentResponseHandler.
9. UUID written back to the E-Document.
```

**Type**: Document. **No Message involved.** The wire artifact has its own BC identity (E-Document row, stamped UUID).

### 6.2 PEPPOL Invoice Response (Message, inbound, external trigger)

```
1. Connector polls its PEPPOL access point. The access point types the item as an ApplicationResponse.
2. Connector calls IDocumentReceiverMessages (not IDocumentReceiver) with the blob.
3. Framework creates "E-Document Message" row: Direction = Incoming, Message Type = PEPPOLInvoiceResponse, Status = Received.
4. Background job resolves the message Type via the enum binding, then calls Type.GetReader().
5. Reader.ParseMessage:
     - Reads cac:DocumentReference → resolves parent outbound "E-Document".
        - Found: store parent FK, status code (e.g., "AP"), continue.
        - Not found: move row to "E-Doc. Unresolved Message" quarantine; notify admin.
6. Framework locks the parent's "E-Document Service Status" row.
7. Framework calls Type.ApplyMessage(msg, applyContext):
     - Type runs PEPPOL BIS 63 advancement guard.
       - Backward transition → Type calls Context.SignalIgnored("Backward AP→IP not allowed").
       - Otherwise → Type calls Context.SetParentStatus(Enum::"E-Document Service Status"::"Receiver Accepted").
     - Type returns true.
8. Framework reads the context, then uniformly:
     - Persists the parent Service Status update.
     - Writes a transition entry to "E-Document Log".
     - Fires workflow event OnEDocumentMessageApplied.
     - Sets message row Status = Applied (or Ignored if Type signalled it).
     - Unlocks.
9. Tenant workflows / notifications fire from the event.
```

**Artifact kind**: Message. **State transition driven by Type.ApplyMessage.** No framework-side blob classification; the connector calls the right entry point.

### 6.3 BC Remittance Advice → outbound Messages (Message, multi-row, posting subscriber)

```
1. User posts a Remittance Advice in BC (BC's existing functionality, generating ledger entries).
2. EDocPostingSubscribers catches OnAfterPostRemittanceAdvice.
3. Subscriber iterates referenced invoices on the remittance:
     For each invoice:
         - Look up its outbound "E-Document" (via Document Record ID).
         - Call EDocSendMessage.Run(parent_EDoc, RemittanceAdviceNotification, "BC Event").
4. One "E-Document Message" row per referenced invoice. All Direction = Outgoing, Status = Pending Send.
5. Per row: framework calls Type.GetWriter().GenerateMessage(related, msg, blob); writer fills the payload; framework persists the blob to "E-Doc. Data Storage".
6. Framework sends each message via IDocumentSender configured on the Service. Logs each send outcome.
7. On send success per row:
     - Framework locks parent's Service Status, calls Type.ApplyMessage(msg, applyContext).
     - Type makes no Context.SetParentStatus call (Remittance Advice is informational; no advancement).
     - Framework logs the Sent event, fires workflow event, sets row Status = Sent. Parent Service Status unchanged.
```

**Artifact kind**: Message, **N rows from one BC posting event.** Each row sends independently. The subscriber decided the cardinality during step 3.

---

## 7. Design defaults captured

These are the framework's defaults — implementers can override case-by-case, but absent a reason to deviate, V3 commits to:

| Default | Rationale |
|---|---|
| Digital signing (e.g., MX SAT) lives in `IEDocument.Create()`, not `IDocumentSender.Send()` | The signed XML *is* the document's canonical form; bound to the issuer (tenant), not the transport. Connector-agnostic signed payload. |
| State machine **semantics** live in the Type (declared via the Apply Context); state machine **execution** lives in the framework | Protocol rules (PEPPOL BIS 63 advancement, etc.) belong with the protocol. Locking, persistence, logging, event firing belong with the framework so they happen uniformly even if the Type forgets. |
| Review/edit UI lives in the Type, not the framework | Different message families need different UX; lowest-common-denominator framework page would be worse than handler-owned pages. |
| Same wire format can be Document **or** Message — implementer chooses | The duality is real (MX vs Remittance). Framework provides both pipelines. |
| Trigger doesn't determine artifact type | Every trigger type (posting, ledger, action, classifier, workflow) can produce either a Document or a Message. |
| Transport is reused for both | `IDocumentSender` / `IDocumentReceiver` carry both Documents and Messages. No new connector contract. |

---

## 8. Deferred to implementation / next iteration

The foundation deliberately stops short. The following will be designed during the spike (or after, grounded in spike learnings):

- **Workflow event design for messages** — signature, payload context, granularity. V2 §7 had open calls; remain open.
- **Profile model** — Document Sending Profile vs new Message Sending Profile, service-primary vs customer-primary keying.
- **Trigger registry shape** — direct subscribers vs central registry.
- **Auto-ack / protocol chaining** — when does a Type's `ApplyMessage` spawn an outbound response, and is that workflow or in-code?
- **Concurrency mechanics** — lock placement, retry, idempotency.
- **Unresolved-message quarantine implementation** — schema, retention policy, admin UI.
- **Phasing & migration sequencing** — which handlers ship first, in what order, in what app.
- **Performance considerations** — `GetApplicableMessages` iteration cost, etc.
- **Overlap with `IDocumentAction`** — existing interface handles synchronous REST polling of post-send protocol actions (Approval, Cancellation queries against a connector API). Conceptually overlaps with V3 Messages at the UI surface (both are user-triggered post-send actions visible on the E-Document page) but uses a different transport (sync REST vs async wire artifact). V3 does not obsolete `IDocumentAction`; a future cleanup could re-model **Cancellation** as a Message in protocols where cancellation is a real wire artifact (e.g., PEPPOL cancellation, France T115). Approval polling stays sync. The new "Send Message" modal action coexists with existing Get Approval / Cancel buttons until that cleanup happens.

These are real concerns. They aren't the foundation. They're built **on** the foundation. V3 is the foundation; the spike will surface which of these matter first.

---

## 9. What V3 commits to (summary)

1. **Two primitives**: Document (gets BC identity) and Message (relates to a Document).
2. **Uniform generation pattern**: trigger → config → framework API → row → send. Same shape for both.
3. **Two framework APIs**: `EDocExport.CreateEDocument` for Documents, `"E-Doc. Send Message".Run` for outbound Messages. Inbound Messages are pulled by the `"E-Doc. Receive Messages"` dispatcher via the receive interface.
4. **Two parallel receive entry points** — existing `IDocumentReceiver` (unchanged) for Documents; new opt-in `IDocumentReceiverMessages` for Messages. The connector classifies by which entry point it invokes; the framework never inspects raw bytes to decide.
5. **State lives on the parent Document** (Service Status). Messages cause transitions through `IEDocumentMessageType.ApplyMessage` — direction-agnostic, fires after inbound parse OR after successful outbound send. Type declares intent via an Apply Context; framework executes uniformly (lock, persist, log, fire event).
6. **Two tables**: `"E-Document"` (existing) and `"E-Document Message"` (new). Messages do not live as discriminated records inside the Document table.
7. **Three new message-side interfaces** — `IEDocumentMessageType` (identity, applicability, state-transition intent, view), `IEDocumentMessageReader` (inbound parse), `IEDocumentMessageWriter` (outbound generate). One new method on `IStructuredDataType` for native message vocabulary. New opt-in `IDocumentReceiverMessages` for inbound transport. Plus `"E-Doc. Msg. Apply Context"` codeunit (intent-declaration).
8. **Type owns**: state-transition semantics (declared via Context), payload internals (via Reader/Writer), review/edit UI. **Framework owns**: locking, persistence, log writes to `"E-Document Log"`, workflow event firing, message row status updates. Logging is centralized — implementers never call the log directly.

These eight commitments are the foundation. The spike validates them in code.
