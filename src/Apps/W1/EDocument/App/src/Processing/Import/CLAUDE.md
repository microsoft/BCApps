# Import subsystem

The Import subsystem transforms received e-documents into purchase drafts through a 4-step state machine: Structure, Read, Prepare, Finish. It coordinates parsing (XML/JSON/PDF), data extraction (MLLM or ADI), master data resolution (vendors, items, UOMs), and draft creation, with full undo support at each step.

## How it works

ImportEDocumentProcess codeunit executes individual steps based on E-Document Import Parameters. The parameters specify either a single step to run or a desired final status. The codeunit calculates the required step sequence, executes each via OnRun trigger, and stops at the first error.

Structure step calls IStructureReceivedEDocument to parse the unstructured blob. For PDF, this invokes MLLM handler to extract invoice data into UBL JSON schema. For XML/JSON, it validates the structure and returns self. The structured data blob is saved to E-Doc. Data Storage and linked via "Structured Data Entry No." field.

Read step determines extraction method from service configuration. If MLLM is enabled, it calls EDocumentMLLMHandler with structured data and UBL schema, receiving populated E-Document Purchase Header and Purchase Line temporary records. If MLLM fails or is disabled, it falls back to ADI (path-based extraction) using IStructuredFormatReader. Extracted data is validated against required fields (vendor name/address minimum).

Prepare step calls PreparePurchaseEDocDraft to resolve master data. It instantiates IVendorProvider, IItemProvider, IUnitOfMeasureProvider interfaces from service configuration and calls them sequentially for each extracted value. Resolved references populate [BC] fields on purchase records. If Copilot matching is enabled, it calls EDocPOCopilotMatching to suggest purchase order line matches. Historical matching (AI-powered vendor and GL account assignment based on past purchases) runs if configured.

Finish step calls EDocumentCreate to transform temporary E-Document Purchase Header/Line records into real Purchase Header/Line records. It validates required fields, applies default values, and calls IEDocumentFinishDraft interfaces for customization. The created purchase records link back to E-Document via SystemId references.

Each step tracks completion via Boolean flags on E-Document Service Status: Structure Done, Read Done, Prepare Done, Finish Done. The overall Import Processing Status enum reflects the last completed step. Undo operations clear flags and delete dependent data, enabling re-processing with different parameters.

## Things to know

- **MLLM before ADI** -- Read step always tries MLLM first if enabled on service, falling back to ADI only on failure. This enables AI-first extraction with automatic fallback for unsupported formats or AI service outages.
- **Temporary record staging** -- Read and Prepare steps populate temporary E-Document Purchase Header/Line records. These are validated and enriched across multiple steps before creating real Purchase Header/Line records in Finish step.
- **Import parameters persistence** -- E-Doc. Import Parameters table stores per-service default settings (MLLM enabled, automatic processing level, matching scope). These can be overridden per-document when calling ProcessIncomingEDocument.
- **Step-level telemetry** -- Each step logs performance metrics (duration, record counts, AI token usage) to E-Doc. Imp. Session Telemetry for analysis. Session ID links all steps for a single document import.
- **Undo cascading** -- Undoing Structure deletes all downstream data (imported lines, matches, drafts). Undoing Read preserves structure but deletes extracted data. Undoing Prepare preserves extraction but deletes matches. Undoing Finish deletes drafts only.
- **Version 1.0 bypass** -- Services configured with Import Process Version "1.0" skip the 4-step state machine and execute synchronously without undo support. This maintains backward compatibility with legacy integrations.
- **Activity log accumulation** -- AI operations (MLLM extraction, Copilot matching, historical matching) append to a single Activity Log session across all steps, creating conversation history for LLM context in subsequent AI calls.
