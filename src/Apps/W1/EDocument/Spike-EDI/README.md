# Spike-EDI — implementer for the V3 E-Document Messages framework

The V3 framework itself now lives in **E-Document Core** (the `App/` project). This
app is a thin implementer that exercises the framework end-to-end through a
fictional XML format and a mock connector.

Design doc: [../App/docs/e-document-messages_V3.md](../App/docs/e-document-messages_V3.md).

## What's in core now (not here anymore)

The following framework primitives moved from this spike into E-Document Core:

| Core path | What it is |
|---|---|
| `App/src/Document/Message/EDocumentMessage.Table.al` (id 6142) | The `"E-Document Message"` table — separate from `"E-Document"`. |
| `App/src/Document/Message/EDocMsgTypeBuffer.Table.al` (id 6143) | Temp buffer for the lookup modal. |
| `App/src/Document/Message/EDocInboundMsgBuffer.Table.al` (id 6144) | Typed temp buffer used by `IDocumentReceiverMessages.ListMessages`. Carries optional inline payload via `SetPayload` / `Inlined`. |
| `App/src/Document/Message/EDocumentMessageType.Enum.al` (id 6115) | Extensible discriminator enum. |
| `App/src/Document/Message/EDocMessageStatus.Enum.al` (id 6116) | Internal operational status. |
| `App/src/Document/Message/EDocMsgTriggerSource.Enum.al` (id 6117) | Trigger taxonomy. |
| `App/src/Document/Message/Interfaces/IEDocumentMessageType.Interface.al` | Type contract. |
| `App/src/Document/Message/Interfaces/IEDocumentMessageReader.Interface.al` | Inbound IO. |
| `App/src/Document/Message/Interfaces/IEDocumentMessageWriter.Interface.al` | Outbound IO. |
| `App/src/Document/Message/EDocMsgApplyContext.Codeunit.al` (id 6340) | Apply Context — intent declaration surface for `Type.ApplyMessage`. |
| `App/src/Document/Message/EDocSendMessage.Codeunit.al` (id 6341) | Outbound orchestration (creates row, Writer, dispatch via `IDocumentSenderMessages`, hands off to Apply Message). |
| `App/src/Document/Message/EDocApplyMessage.Codeunit.al` (id 6344) | Shared post-event apply step — locks parent, runs `Type.ApplyMessage`, executes the declared intent (Service Status, log, event). |
| `App/src/Document/Message/EDocUnknownMsgType.Codeunit.al` (id 6343) | Default impl for `Unknown`. |
| `App/src/Document/Message/EDocumentMessageCard.Page.al` (id 6137) | Default message card. |
| `App/src/Document/Message/EDocumentMessageLookup.Page.al` (id 6138) | Modal applicable-message lookup. |
| `App/src/Document/Message/EDocumentMessagePageExt.PageExt.al` (id 6173) | Single `"Send Message"` action on the existing E-Document page. |
| `App/src/Integration/Interfaces/IDocumentSenderMessages.Interface.al` | Opt-in extension to `IDocumentSender`. |
| `App/src/Integration/Interfaces/IDocumentReceiverMessages.Interface.al` | Opt-in extension to `IDocumentReceiver`. Two methods: `ListMessages` (fills `E-Doc. Inbound Msg Buffer`) and `DownloadMessage` (per non-inlined row). |
| `App/src/Integration/Receive/EDocReceiveMessages.Codeunit.al` (id 6342) | Inbound message dispatcher. |

Other core changes:

- `App/src/Processing/Interfaces/IStructuredDataType.Interface.al` — added the new `GetSupportedMessages(): List of [Enum "E-Document Message Type"]` method. Existing implementers (`E-Document MLLM Handler`, `E-Document ADI Handler`, `E-Doc. Empty Draft`, `Contoso Inb.Inv. Handler`, `E-Doc ADI Handler Mock`, `E-Doc PDF Mock`) all have a no-op stub returning an empty list.
- `App/src/Document/Status/EDocumentServiceStatus.Enum.al` — added the V3 role-paired statuses (`Receiver Acknowledged` / `Sender Acknowledged` / `Receiver Processing` / `Receiver Under Query` / `Receiver Conditionally Accepted` / `Receiver Accepted` / `Receiver Accepted with Changes` / `Receiver Rejected` / `Receiver Rejected (Validation)` / `Receiver Paid` / `Sender Paid` / `Sender Payment Reversed`), values 40–51.

## What's in this spike

Just the implementer code — a connector and a format with messages.

### `src/ContosoConnector/` — the connector

| File | Role |
|---|---|
| `ContosoConnector.Codeunit.al` | Implements all four transport interfaces: `IDocumentSender`, `IDocumentReceiver`, `IDocumentSenderMessages`, `IDocumentReceiverMessages`. Reads/writes only its own `"Contoso Mailbox Entry"` table. Zero framework calls. |
| `ContosoMailbox.Table.al` | Simulates the network — Outbound and Inbound rows. The `OnInsert` trigger automatically clones each inserted row into the opposite direction with `Insert(false)`, so a single connector write produces both the audit row and the partner echo without manual mailbox interaction. |
| `ContosoMailbox.Page.al` | Inspect mailbox entries. `View Content` shows the XML payload. `Process Inbound Messages` drives the core `E-Doc. Receive Messages` dispatcher against this service. |

### `src/ContosoFormat/` — Document implementer

| File | Role |
|---|---|
| `ContosoInvoiceFormat.Codeunit.al` | Implements core `"E-Document"`. `Create` iterates `Sales Invoice Line` records via the RecordRef parameter and builds full XML. `Check` validates customer name. `GetBasicInfoFromReceivedDocument` parses Document No / Date / Total / Currency on inbound. |
| `ContosoInvoiceStructured.Codeunit.al` | Implements core `IStructuredDataType` + `IStructuredFormatReader`. `ReadIntoDraft` populates `"E-Document Purchase Header"` + `"E-Document Purchase Line"` staging records. Implements the new `GetSupportedMessages()` advertising native `Contoso Invoice Ack` support. |
| `ContosoFormat.EnumExt.al` | Adds `Contoso Invoice` to the `"E-Document Format"` enum. |

### `src/ContosoMessages/` — Message implementer

| File | Role |
|---|---|
| `ContosoAckType.Codeunit.al` | Implements core `IEDocumentMessageType`. `IsApplicableFor` returns true for invoices + user action / external inbound. `ApplyMessage` reads the parsed `Status Code` and declares intent on the Apply Context — never mutates state directly. |
| `ContosoAckReader.Codeunit.al` | Implements core `IEDocumentMessageReader`. Parses Ack XML; resolves parent E-Document by `RelatedInvoiceNumber`. |
| `ContosoAckWriter.Codeunit.al` | Implements core `IEDocumentMessageWriter`. Builds Ack XML referencing parent's `Document No.`. |
| `ContosoMessageType.EnumExt.al` | Extends core `"E-Document Message Type"` with `Contoso Invoice Ack`, bound to `Contoso Ack Type`. |

## V3 quadrant coverage

| Quadrant | Demonstrated by |
|---|---|
| Outbound Document | Posting a Sales Invoice on a customer with Contoso Document Sending Profile → core framework calls `ContosoInvoiceFormat.Create` → `ContosoConnector.Send` writes to Outbound mailbox row. |
| Inbound Document | Mailbox Inbound/Document row → core's existing receive pipeline → `ContosoConnector.DownloadDocument` → `ContosoInvoiceStructured.ReadIntoDraft` populates Purchase staging tables → core finishes draft to Purchase Invoice. |
| Outbound Message | `"Send Message"` action on the E-Document page (core page ext) → modal lookup → user picks Contoso Ack → core `E-Doc. Send Message.Run` → `ContosoAckWriter.GenerateMessage` → `ContosoConnector.SendMessage` (via `IDocumentSenderMessages`) → core `E-Doc. Apply Message.Run` → `ContosoAckType.ApplyMessage` declares intent → core executes (Service Status + log + event). |
| Inbound Message | Mailbox Inbound/Message row → `ContosoMailbox` page `Process Inbound Messages` action → core `E-Doc. Receive Messages.Run` → `ContosoConnector.ListMessages` drains mailbox rows into the buffer with payloads inlined → framework loops the buffer (skips `DownloadMessage` because rows are inlined) → `ContosoAckReader.ParseMessage` resolves parent → core `E-Doc. Apply Message.Run` → `ContosoAckType.ApplyMessage` declares intent → core executes. |

## Manual demo path

1. Build and publish E-Document Core (now containing the framework) and this app.
2. Configure an `"E-Document Service"` with Format = `Contoso Invoice` and Service Integration V2 = `Contoso Connector`. Attach to a Document Sending Profile for a test customer.
3. Post a Sales Invoice → Contoso Mailbox shows an Outbound/Document row AND its auto-twinned Inbound/Document row (the partner echo).
4. Open the outbound `E-Document` → click `Send Message` → select `Contoso Invoice Ack` → Mailbox shows the Outbound/Message row AND its auto-twinned Inbound/Message row.
5. Click `Process Inbound Messages` on the Mailbox page → core consumes the Inbound row, parses, applies → parent's Service Status advances to `Receiver Accepted`. Check the `E-Document Log` for the framework-written entries.

The auto-twin keeps the demo path zero-click between Send and Receive — the same OnInsert trigger covers all four V3 quadrants. A real connector would not have this; production traffic crosses an actual network.
