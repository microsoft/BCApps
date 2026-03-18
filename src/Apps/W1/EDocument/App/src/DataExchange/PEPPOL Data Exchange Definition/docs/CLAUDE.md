# PEPPOL Data Exchange Definition

Pre-mapping codeunits for PEPPOL import through BC's Data Exchange framework. This is the legacy import path that translates PEPPOL XML fields into BC purchase document fields using the Data Exchange Definition infrastructure.

## How it works

The Data Exchange framework reads PEPPOL XML into intermediate staging tables. Before those staged values can populate Purchase Header/Line records, the pre-mapping codeunit (`EDocDEDPEPPOLPreMapping`, codeunit 6156) runs to resolve values that need business logic -- vendor lookup, currency validation, document type detection, and line item matching.

The pre-mapping codeunit operates on `Data Exch.` records. It first processes headers: validates currency codes, determines whether the document is an invoice or credit memo, resolves buy-from and pay-to vendors by GLN or VAT registration number, finds related invoices for credit memos, and persists header data. Then it processes lines: resolves items and accounts, applies invoice charges, and sets line-level fields.

Four line-level pre-mapping codeunits handle export-side field population for the Data Exchange Definition subscribers: `PreMapSalesInvLine`, `PreMapSalesCrMemoLine`, `PreMapServiceInvLine`, `PreMapServiceCrMemoLine`. These populate the intermediate data exchange columns with values from BC document lines.

`EDocDEDPEPPOLSubscribers` (codeunit 6162) is a SingleInstance codeunit that subscribes to Data Exchange events. It handles tax subtotal loops, allowance/charge loops, document attachment numbering, and rounding line detection during PEPPOL export.

`EDocDEDPEPPOLExternal` (codeunit 6155) is a placeholder -- a dummy codeunit required by the Data Exchange Definition infrastructure but containing no logic.

## Things to know

- This is the legacy import path used when the E-Document Service's import process is configured for Data Exchange. The newer V2 import pipeline in `Processing/Import/` has largely superseded this for new implementations.
- Vendor resolution tries GLN first, then VAT Registration Number, then Company Establishment No. If buy-from and pay-to are different, both are resolved independently.
- The pre-mapping validates that all line currencies match the header currency -- mismatches raise errors.
- Credit memo import requires that the referenced invoice is already posted in BC. If it exists as a purchase invoice but is not yet posted, a specific error message tells the user to post it first.
- `EDocDEDPEPPOLSubscribers` uses `SingleInstance = true` to maintain state across multiple event callbacks during a single Data Exchange processing run. The `ClearInstance` / `InitInstance` pattern resets and configures this state.
