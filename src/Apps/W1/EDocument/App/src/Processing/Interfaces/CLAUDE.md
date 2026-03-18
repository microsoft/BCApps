# Processing interfaces

Processing interfaces define the extensibility contracts for e-document processing. These 18 interfaces enable partners to add new file formats, customize data resolution, and control document lifecycle without modifying core code. Each interface represents a specific customization goal with well-defined inputs and outputs.

## How it works

Interfaces are implemented by codeunits that register via enum extensions. When the processing engine needs a capability (format a document, resolve a vendor, match a purchase order), it instantiates the interface from the enum value stored on the E-Document Service or E-Document record. The interface implementation receives context (document references, temp blobs, service configuration) and returns results (formatted content, resolved record references, success/failure status).

File format interfaces (IEDocFileFormat, IStructureReceivedEDocument, IStructuredFormatReader) form a pipeline. IEDocFileFormat identifies the blob type (PDF, XML, JSON). IStructureReceivedEDocument parses the blob into structured data. IStructuredFormatReader extracts field values from structured data using path expressions. For MLLM-based extraction, IEDocAISystem replaces IStructuredFormatReader with AI-powered field extraction.

Provider interfaces (IVendorProvider, IItemProvider, IUnitOfMeasureProvider, IPurchaseLineProvider, IPurchaseOrderProvider) resolve external identifiers to Business Central master data. The Prepare step calls each provider interface in sequence, passing extracted text values and receiving validated record references. Providers can implement fuzzy matching, create missing records, or enforce validation rules.

Lifecycle interfaces (IExportEligibilityEvaluator, IProcessStructuredData, IPrepareDraft, IEDocumentFinishDraft) customize processing at key decision points. These interfaces can enrich data, add validation, trigger external workflows, or modify records before final persistence. Multiple implementations can be chained via events.

## Things to know

- **Interface storage via enum** -- E-Document Service stores interface implementations as enum values (Document Format, Integration, Sender Type). At runtime, the system assigns the enum to an interface variable, triggering dynamic dispatch.
- **Temporary record patterns** -- Many interfaces receive temporary records (TempBlob, temp Purchase Line) to enable multi-step transformation without committing changes. Only after all interfaces succeed does the system insert real records.
- **RecordRef for flexibility** -- IExportEligibilityEvaluator and provider interfaces receive RecordRef parameters rather than typed records, enabling the same interface to handle Sales Invoice, Purchase Invoice, Service Invoice without specialized overloads.
- **Fallback chains** -- Read step tries IEDocAISystem (MLLM) first, falls back to IStructuredFormatReader (ADI) if AI fails. This enables graceful degradation when AI services are unavailable.
- **Interface versioning** -- New methods can be added to interfaces using optional parameters or new related interfaces. Implementations compiled against older versions continue working via interface inheritance.
- **Event bridges** -- Interfaces are called directly by processing codeunits. Events fire before and after interface calls, enabling subscribers to modify inputs/outputs or bypass interface logic entirely.
- **Error handling convention** -- Interfaces return Boolean for success/failure rather than throwing errors. This enables the processing engine to log failures, attempt fallbacks, and continue processing other documents in batch mode.
