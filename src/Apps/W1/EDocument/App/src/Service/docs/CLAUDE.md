# Service

The E-Document Service (table 6103) is the configuration hub that binds a document format to a transport integration and defines all the behavioral flags for import processing. Each service represents one endpoint -- a specific e-invoicing network, tax authority, or clearance provider -- and an E-Document is processed through exactly one service at a time.

## How it works

Format and transport are independent dimensions. `Document Format` selects how the document is serialized (PEPPOL via code-based format, or Data Exchange Definition for custom mappings), while `Service Integration V2` selects the transport connector that sends and receives over the wire. This separation means the same PEPPOL format can be sent through different service connectors, or the same connector can carry different formats.

The service carries a large set of import behavior flags that control what happens when an inbound document is processed: `Validate Receiving Company`, `Resolve Unit Of Measure`, `Lookup Item GTIN`, `Lookup Item Reference`, `Lookup Account Mapping`, `Validate Line Discount`, `Apply Invoice Discount`, `Verify Totals`, and `Verify Purch. Total Amounts`. These flags are consulted by the import processing pipeline and allow each service to tune validation strictness independently.

The `Import Process` field is a critical fork: "Version 1.0" routes through the legacy import path while "Version 2.0" uses the new structured import pipeline with its own draft-based processing model and `Import Processing Status` tracking. The `Automatic Import Processing` flag controls whether imported documents are processed immediately or left for manual review. Batch processing is configured through `Use Batch Processing`, `Batch Mode` (threshold-based or time-based), and related scheduling fields that manage background job queue entries.

## Things to know

- `Import Process` V1 vs V2 selects entirely different code paths. V2 uses `Structure Data Impl.`, `Read into Draft Impl.`, and `Process Draft Impl.` on the E-Document to drive a multi-step pipeline. V1 uses the monolithic `V1_ProcessImportedDocument` path.
- `E-Doc. Service Supported Type` (table 6122) filters which E-Document Types a service handles. If no supported types are configured, the service accepts all types.
- Auto import scheduling is driven by `Auto Import`, `Import Start Time`, and `Import Minutes between runs`. These fields create and manage a recurrent job queue entry stored in `Import Recurrent Job Id`.
- Service Participants (`ServiceParticipant.Table.al`) link customers or vendors to a service with an external `Participant Identifier`. This is how the framework resolves which service to use for a given trading partner and provides the external ID (like a PEPPOL participant ID) needed by the service connector.
- The `Service Integration V2` field triggers `IConsentManager.ObtainPrivacyConsent()` when first set to a non-empty value, ensuring GDPR consent before any data flows to an external service.
- Batch sending is configured per-service with its own job queue entry (`Batch Recurrent Job Id`). The `Batch Mode` enum controls whether batching triggers on document count threshold or on a time schedule.
- The `Embed PDF in export` flag causes the framework to generate a PDF from Report Selection as a background process and embed it into the export file during posting.
