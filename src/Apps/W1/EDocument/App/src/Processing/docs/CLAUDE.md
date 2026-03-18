# Processing

Processing is the largest module in the E-Document Core app. It owns both the export pipeline (turning BC documents into e-document blobs) and the import pipeline (turning received blobs into BC purchase documents). The import side is significantly more complex because it must handle unstructured formats like PDF, resolve vendors and items from external data, and optionally use AI to fill in what deterministic matching cannot.

## How it works

**Export** starts in `EDocExport.Codeunit.al`. When a document is posted and a Document Sending Profile triggers the e-document workflow, `CreateEDocument` populates the E-Document record from the source document header, then `ExportEDocument` applies field mappings and delegates to the document format interface to produce the output blob. An `IExportEligibilityEvaluator` gates whether a given service should receive the document at all.

**Import V2** is a 5-state machine defined in `ImportEDocumentProcess.Codeunit.al`. Each state transition runs exactly one step. The pipeline is: Unprocessed -> (Structure received data) -> Readable -> (Read into Draft) -> Ready for draft -> (Prepare draft) -> Draft ready -> (Finish draft) -> Processed. Every step can be undone, which resets the E-Document back to the previous state and cleans up intermediate data. The V1 legacy path collapses all steps into a single "Finish draft" call.

**AI matching** runs during "Prepare draft". After deterministic matching (item references, text-to-account mappings), `PreparePurchaseEDocDraft` invokes three sequential Copilot steps: historical matching, GL account matching, and deferral matching. Each is an `IEDocAISystem` + `AOAI Function` implementation that builds a JSON user message, calls GPT-4 via the AOAI platform with function-calling, and applies the returned matches to draft lines.

## Things to know

- The import state machine is strict about ordering -- `GetNextStep` and `GetPreviousStep` use an integer index on the status enum, so adding states requires updating those mappings.
- Draft purchase tables use field ranges: [2-100] for external data (vendor name, product code) and [101-200] for BC-resolved data (`[BC] Vendor No.`, `[BC] Purchase Type No.`). The `[BC]` prefix is the naming convention.
- Vendor resolution in `EDocProviders.Codeunit.al` tries GLN/VAT ID lookup, then Service Participant, then name+address fuzzy match. If all fail, the draft proceeds but the user must assign the vendor manually.
- AI matching is sequential and subtractive: historical matching runs first on unmatched lines, then GL account matching on still-unmatched lines, then deferral matching on lines that have an account but no deferral code.
- PO matching (`EDocPOMatching.Codeunit.al`) tracks matches in a separate link table (`E-Doc. Purchase Line PO Match`) using SystemId references, not primary keys -- this survives record renumbers.
- Historical matching loads up to 5000 posted purchase invoice lines from the last year and uses similar-description detection to find candidates before sending them to the LLM for final selection.
- The export pipeline checks `IExportEligibilityEvaluator` before producing the blob -- this is the hook for suppressing export of specific documents per service.
