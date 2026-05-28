# E-Document Lifecycle Messages — Generalized Architecture

Status: Draft V1
Scope: BC E-Document Core (`src/Apps/W1/EDocument/App`)
Basis: Generalization of the Inbound PEPPOL Responses proposal, driven by French e-reporting requirements.

---

## 1. The problem with "responses"

The earlier PEPPOL Responses architecture used the concept of a *response* — a message someone sends back to us about a document we sent. That framing is inbound-only and PEPPOL-specific. Two French requirements break it:

- **Collected**: we generate and send a payment-status message about our own outbound invoice. Nothing arrives; a BC event (payment applied) triggers the send.
- **Refused** (buyer side): we generate and send a refusal message about an invoice we *received*. The parent is an inbound E-Document, not an outbound one.

Neither of these is a "response" in the PEPPOL sense. Both are lifecycle messages.

---

## 2. Generalized rule

> A **lifecycle message** always relates to an existing E-Document. The related E-Document can be in either direction, and the lifecycle message itself can also be in either direction.

This replaces the earlier rule "a response is always a reply to an E-Document we sent."

### The 2×2

| Original E-Document direction | Lifecycle message direction | Example |
|---|---|---|
| Outgoing | Incoming | PEPPOL Invoice Response, PEPPOL Order Response, MLR |
| Outgoing | Outgoing | French Collected, French Negative Collected |
| Incoming | Outgoing | French Refused |
| Incoming | Incoming | Connector ACK of our Refused — future |

The PEPPOL Responses architecture covered only the top-left quadrant. This design covers all four.

---

## 3. Data model changes

### 3.1 Fields on `"E-Document"` (renamed from PEPPOL proposal)

| Field | Type | Notes |
|---|---|---|
| `Lifecycle Message Type` | Enum `"E-Document Lifecycle Message Type"` | Blank = not a lifecycle message. Non-blank = this record is a lifecycle message. Replaces proposed `Response Type`. |
| `Related E-Document Entry No.` | Integer, FK | Mandatory when `Lifecycle Message Type` is non-blank. Enforced in trigger. Replaces proposed `Responds To E-Document Entry No.`. |
| `Lifecycle Message Code` | Code[10] | Raw protocol code (PEPPOL `AP`/`RE`/`PD`, French `Collected`, etc.) for filterable list views. |

The existing `"E-Document Type"` enum (6105, implements `IEDocumentFinishDraft`) is **not touched** — lifecycle messages do not produce BC documents.

### 3.2 `"E-Document Lifecycle Message Type"` enum

```al
enum "E-Document Lifecycle Message Type" implements "IEDocumentLifecycleMessageHandler"
{
    Extensible = true;
    value(0;  "Unknown")                      { ... }
    // Inbound — PEPPOL
    value(10; "PEPPOL MLR")                   { ... }
    value(20; "PEPPOL Invoice Response")      { ... }
    value(30; "PEPPOL Order Response")        { ... }
    // Outgoing — Payment statuses (core values; first use: France)
    value(100; "Payment Status - Collected")  { ... }
    value(101; "Payment Status - Negative Collected") { ... }
    value(102; "Payment Status - Refused")    { ... }
}
```

Values 100–102 live in core because mandatory payment lifecycle reporting is not unique to France — other countries will reuse the same concept. French localization binds the CDAR/XML formatters.

### 3.3 `"E-Document Response Detail"` → `"E-Document Lifecycle Message Detail"`

Renamed; schema unchanged. Detail Types added for payment messages:

| Detail Type | Used by |
|---|---|
| `ValidationRule` | PEPPOL MLR |
| `ClarificationReason` | PEPPOL Invoice Response UQ/CA |
| `ClarificationAction` | PEPPOL Invoice Response |
| `ConditionDetail` | PEPPOL Invoice Response CA |
| `OrderLineStatus` | PEPPOL Order Response |
| `SubstitutedItem` | PEPPOL Order Response |
| `BackorderQty` | PEPPOL Order Response |
| `PromisedDelivery` | PEPPOL Order Response |
| `PaymentAmount` | Payment status messages |
| `PaymentCurrency` | Payment status messages |
| `PaymentDate` | Collected / Negative Collected |
| `RefusalDate` | Refused |
| `PartyID` | Buyer ID / Supplier ID on all payment messages |
| `Custom` | Extension use |

---

## 4. Interface split

The PEPPOL proposal had a single `IEDocumentResponseProcessor` handling inbound parsing and apply. Outbound messages need a generation/send contract. The generalized interface:

```al
interface "IEDocumentLifecycleMessageHandler"
{
    // Inbound path: called after DownloadDocument
    procedure ParseMessage(LifecycleMessage: Record "E-Document";
                           var TempBlob: Codeunit "Temp Blob"): Boolean;
    procedure ApplyMessage(var LifecycleMessage: Record "E-Document"): Boolean;

    // Outbound path: called from trigger or user action
    procedure GenerateMessage(RelatedEDocument: Record "E-Document";
                              var LifecycleMessage: Record "E-Document"): Boolean;
    procedure SendMessage(var LifecycleMessage: Record "E-Document"): Boolean;
}
```

Inbound-only implementations (PEPPOL processors) leave `Generate`/`Send` as no-ops. Outbound-only implementations (French payment statuses) leave `Parse`/`Apply` as no-ops. A handler that does both (future Order Response advanced) implements all four.

---

## 5. Outbound trigger model

Outbound lifecycle messages are generated by BC events, not by receiving a document.

| Message | BC trigger event | Subscriber codeunit |
|---|---|---|
| Collected | `OnAfterPostCustLedgerEntry` (entry closed by payment) | `EDocPaymentStatusSubscribers` |
| Negative Collected | `OnAfterUnapplyCustLedgerEntry` | same |
| Refused | User action on inbound E-Document page ("Refuse Invoice") | `EDocInboundActionSubscribers` |

The subscriber:
1. Identifies the related outbound/inbound E-Document from the trigger context.
2. Calls `EDocLifecycleMessageMgmt.CreateOutbound(RelatedEDocument, MessageType)`.
3. The framework populates the record, calls `GenerateMessage`, then queues the send via the existing job queue category.

The send pipeline reuses the existing `IDocumentSender` contract — no new connector interface.

---

## 6. Lifecycle message status (internal, both directions)

| Status | Meaning |
|---|---|
| `Received` | Inbound: blob stored, parent resolved, detail rows parsed. |
| `Applied` | Inbound: changes propagated to parent's service status. |
| `Ignored` | Inbound: backward transition or duplicate; kept for audit. |
| `Pending Send` | Outbound: generated, not yet sent. |
| `Sent` | Outbound: delivered to connector. |
| `Send Failed` | Outbound: connector rejected or timed out; retryable. |

These are not surfaced as primary UX. The parent E-Document's Service Status is what users watch.

---

## 7. French payment status — concrete mapping

### Collected (CDAR format)

```xml
<CDAR>
  <InvoiceID>INV-2024-001</InvoiceID>
  <Status>Collected</Status>
  <Amount>1250.0</Amount>
  <Currency>EUR</Currency>
  <PaymentDate>2024-05-15</PaymentDate>
  <BuyerID>FR123456789</BuyerID>
  <SupplierID>FR987654321</SupplierID>
</CDAR>
```

| CDAR field | Stored as |
|---|---|
| `InvoiceID` | `Related E-Document Entry No.` lookup |
| `Status` | `Lifecycle Message Code` = `Collected` |
| `Amount` | Detail row: `Detail Type = PaymentAmount` |
| `Currency` | Detail row: `Detail Type = PaymentCurrency` |
| `PaymentDate` | Detail row: `Detail Type = PaymentDate` |
| `BuyerID` | Detail row: `Detail Type = PartyID`, `Reference Attribute ID = Buyer` |
| `SupplierID` | Detail row: `Detail Type = PartyID`, `Reference Attribute ID = Supplier` |

### Refused (XML format)

```xml
<InvoiceStatus>
  <InvoiceID>INV-2024-002</InvoiceID>
  <Status>Refused</Status>
  <RefusalDate>2024-05-10</RefusalDate>
  <ReasonCode>R01</ReasonCode>
  <ReasonDescription>Invoice amount does not match purchase order</ReasonDescription>
  <BuyerID>FR123456789</BuyerID>
  <SupplierID>FR987654321</SupplierID>
</InvoiceStatus>
```

| XML field | Stored as |
|---|---|
| `RefusalDate` | Detail row: `Detail Type = RefusalDate` |
| `ReasonCode` | Detail row: `Detail Type = ClarificationReason`, `Code` field |
| `ReasonDescription` | Detail row: `Detail Type = ClarificationReason`, `Description` field |

The French localization app extends `"E-Document Lifecycle Message Type"` with `FR CDAR Collected` and `FR XML Refused` if it needs format-specific processors; or it binds the CDAR/XML formatters to the core `Payment Status - Collected` / `Payment Status - Refused` values via the service-level formatter field. Decision for the localization team.

---

## 8. What changes from the PEPPOL Responses proposal

| Item | PEPPOL proposal | Generalized design |
|---|---|---|
| Core rule | "reply to an E-Document we sent" | "relates to an E-Document, either direction" |
| Field name | `Response Type` | `Lifecycle Message Type` |
| Field name | `Responds To E-Document Entry No.` | `Related E-Document Entry No.` |
| Interface | `IEDocumentResponseProcessor` (inbound only) | `IEDocumentLifecycleMessageHandler` (inbound + outbound) |
| Table name | `E-Document Response Detail` | `E-Document Lifecycle Message Detail` |
| Outbound trigger | not present | subscriber hooks on BC payment/action events |
| Outbound status enum | not present | `Pending Send`, `Sent`, `Send Failed` |

The inbound PEPPOL processors (MLR, Invoice Response, Order Response) are unchanged in behavior — they implement `Parse` and `Apply`, leave `Generate` and `Send` as no-ops.

---

## 9. Open questions (carried forward)

- **SC2**: does `"E-Document"."Document Record ID"` have a secondary key? Required for the posting block query.
- **SC3**: lock `"E-Document Service Status"` row on apply, not the parent E-Document row.
- **SC6**: enum ID allocation for new `"E-Document Service Status"` values — coordinate with connector ecosystem.
- **SC12**: cascade-delete policy when original E-Document is deleted and lifecycle messages exist.
- **French localization binding**: does France extend the core enum or bind formatters to core values? Localization team decision.
- **Negative Collected trigger precision**: `OnAfterUnapplyCustLedgerEntry` fires on any unapplication; must scope to entries where a Collected message was previously sent and acknowledged.
