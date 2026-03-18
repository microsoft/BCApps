# Service

Configuration layer for e-document processing. The `E-Document Service` table (6103) is the central configuration entity that ties together a document format, a service integration, processing flags, and scheduling parameters. Each service defines how documents should be exported, sent, received, and processed.

## How it works

An E-Document Service is a named configuration (e.g., "PEPPOL-Pagero", "MSEOCADI") that combines two key choices: which `Document Format` enum value to use for creating/parsing document content, and which `Service Integration V2` enum value to use for communicating with the external API. When a document is posted, the framework looks up the service associated with it and uses these two enum values to resolve the format interface and the connector interfaces at runtime.

The `E-Doc. Service Supported Type` table (6122) is a simple N:M bridge -- it lists which `E-Document Type` values a service handles. If a service only handles Sales Invoices and Sales Credit Memos, only those two rows exist. The processing pipeline uses this to determine which service should process a given document type.

`Service Participant` table (6104) maps customers and vendors to their external identifiers for a given service. This is where PEPPOL IDs, endpoint identifiers, and other service-specific participant codes are stored. The primary key is (Service, Participant Type, Participant), meaning a single vendor can have different identifiers for different services.

The `E-Document Service Status` table (6138) tracks the per-service status of each E-Document. Its primary key is (E-Document Entry No, E-Document Service Code), creating the one-to-many relationship between an E-Document and the services processing it. The `Import Processing Status` field is a V2 addition for the new import pipeline.

## Things to know

- The Service table is heavily configuration-driven. Boolean flags control inbound processing steps: `Validate Receiving Company`, `Resolve Unit Of Measure`, `Lookup Item Reference`, `Lookup Item GTIN`, `Lookup Account Mapping`, `Validate Line Discount`, `Apply Invoice Discount`, `Verify Totals`. Each flag toggles a specific step in the import processing pipeline.

- `Service Integration V2` replaces the obsolete `Service Integration` (V1). When the V2 field is validated, the framework resolves `IConsentManager` from the enum and calls `ObtainPrivacyConsent`. If consent is denied, the field reverts to its previous value.

- Batch processing is configured per-service with `Use Batch Processing`, `Batch Mode` (Threshold or Recurrent), `Batch Threshold`, and scheduling fields. Toggling `Use Batch Processing` automatically creates or removes a recurrent job queue entry via `E-Document Background Jobs`.

- Auto-import is similarly scheduled per-service: `Auto Import` + `Import Start Time` + `Import Minutes between runs`. Each toggle change reconfigures the job queue entry.

- The `MSEOCADI` service code is a built-in service for Azure Document Intelligence PDF processing. `GetPDFReaderService` auto-creates it on first access.

- You cannot delete a service that is used in an active workflow -- the `OnDelete` trigger checks for active workflow references.

- `GetDefaultFileExtension` defaults to `.xml` but fires an integration event (`OnAfterGetDefaultFileExtension`) allowing connectors to override it for JSON or other formats.
