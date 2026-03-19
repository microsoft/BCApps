# Service

The E-Document Service table is the central configuration hub. Each service
record ties together a document format, an integration connector, import
behavior, and batch processing settings. When an e-document is created or
received, the system looks up the service to decide how to format, send,
or parse it.

## Key settings on the service record

- **Document Format** -- selects the `E-Document Format` enum implementation
  (e.g. PEPPOL BIS 3.0, Data Exchange). Controls export XML generation and
  import parsing.

- **Service Integration V2** -- selects the `Service Integration` enum
  implementation that handles the actual send/receive HTTP calls. The V1
  `Service Integration` field is obsolete (pending removal in v29).
  Setting a non-"No Integration" value triggers a privacy consent prompt.

- **Import Process** -- Version 1.0 (legacy, uses `E-Document` interface
  `GetCompleteInfoFromReceivedDocument`) or Version 2.0 (newer draft-based
  flow). Controls which import pipeline runs.

- **Read into Draft Impl.** -- enum selecting how structured inbound
  documents are read into a purchase draft (replaces the removed
  `E-Document Structured Format` field).

- **Auto Import / Import schedule** -- when enabled, creates a recurring
  job queue entry that polls the integration for new documents.

- **Batch processing** -- `Use Batch Processing`, `Batch Mode` (Threshold
  or Recurrent), `Batch Threshold`, and schedule fields. Threshold mode
  accumulates e-documents until a count is met, then sends them together.
  Recurrent mode sends on a timer.

## Supported types

`E-Doc. Service Supported Type` links a service to one or more
`E-Document Type` values (Sales Invoice, Sales Credit Memo, etc.). Only
documents whose type appears in this list will be processed through that
service. When PEPPOL BIS 3.0 format is selected, the system auto-seeds
Sales Invoice, Sales Credit Memo, Service Invoice, and Service Credit Memo.

## Participants

The `Service Participant` table (in the `Participant/` subfolder) maps a
customer or vendor to a service with a `Participant Identifier` string.
This identifier is used during import to match inbound documents to the
correct vendor (e.g. by PEPPOL endpoint scheme + ID). The participant
codeunit provides lookup helpers used from the Vendor and Company
Information page extensions.

## Service status

`E-Document Service Status` is a junction table keyed by (E-Document
Entry No, Service Code). It tracks the per-service processing status for
each e-document. This is separate from the overall E-Document status
because a single document can be sent through multiple services via
workflow, each progressing independently.
