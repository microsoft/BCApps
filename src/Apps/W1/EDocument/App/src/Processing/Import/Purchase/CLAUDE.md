# Purchase domain

The Purchase domain provides temporary staging tables and UI for imported purchase document data. It bridges the gap between extracted external data (vendor names, item descriptions) and validated Business Central references (Vendor No., Item No.) through the 4-step import workflow.

## How it works

E-Document Purchase Header and E-Document Purchase Line are temporary tables created during Read step. They store both external values extracted from the e-document (Vendor Company Name, Sales Invoice No., item descriptions) and Business Central references populated during Prepare step ([BC] Vendor No., [BC] Item No., [BC] Unit of Measure).

The tables use a dual-field pattern: each external concept has both an extracted text field and a resolved Business Central reference field. For example, vendor information has "Vendor Company Name" (extracted text) and "[BC] Vendor No." (resolved Code[20] reference). During Prepare step, provider interfaces populate the [BC] fields by looking up master data.

The E-Document Purchase Draft page displays these temporary records in a purchase document-like UI, enabling users to review extracted data before finalizing. The page shows both external and resolved values side-by-side, highlighting missing or uncertain resolutions. Users can manually correct [BC] references, override item assignments, or adjust quantities before running Finish step.

Purchase order matching (handled by PurchaseOrderMatching subdirectory) links imported lines to existing purchase orders, enabling 3-way match scenarios. When matches exist, the Finish step creates Purchase Invoice documents linked to POs rather than standalone invoices.

Historical matching (history subdirectory) tracks past vendor assignments and line-to-GL-account mappings, feeding AI-powered suggestions during Prepare step. This learns from user corrections over time, improving automatic resolution accuracy.

## Things to know

- **Temporary lifecycle** -- E-Document Purchase Header/Line records are temporary during import, exist only in memory until Finish step commits them as real Purchase Header/Line records. If import fails or is undone, temporary records are deleted without trace.
- **[BC] prefix convention** -- Fields storing Business Central references are prefixed "[BC]" to distinguish them from external extracted values. This makes the dual-field pattern explicit in code and UI.
- **Partial resolution** -- Prepare step can successfully complete even if some [BC] fields remain blank. For example, if vendor resolves but items don't, users can manually assign items during review. Only Vendor No. is mandatory for Finish step.
- **PO matching is optional** -- Documents can be processed without matching to purchase orders, creating standalone purchase invoices. PO matching is only required for 3-way match scenarios where users want to validate against existing orders.
- **History is advisory** -- Historical matching provides suggestions but doesn't auto-apply assignments. Users review suggestions and can accept/reject via UI. Accepted matches train the history, rejected matches don't.
- **Read-only external fields** -- External value fields (Vendor Company Name, Item No. from document) are read-only during review. Only [BC] reference fields can be edited. This preserves audit trail of exactly what was extracted.
- **Draft feedback UI** -- The E-Doc. Draft Feedback page collects user feedback on extraction quality (thumbs up/down per field), feeding into telemetry for AI model improvement. Feedback is optional and doesn't affect processing.
