# Order matching

Line-level matching between incoming e-invoices and existing purchase orders. This is the core of the purchase invoice import flow -- when a vendor sends an invoice referencing a PO, each invoice line must be matched to the correct PO line before the purchase invoice can be created.

## Data model

`EDocImportedLine.Table.al` holds a normalized view of the imported invoice lines, extracted from whatever XML format the e-document arrived in. This abstraction lets the matching logic work identically regardless of source format. Key fields include quantity, unit price, and UOM -- plus "Matched Quantity" to track partial matches.

`EDocOrderMatch.Table.al` stores proposed matches between imported lines and PO lines. It tracks whether the match is a precise quantity match, flags price discrepancies between what the vendor invoiced and what the PO specifies, and has a "Learn Matching Rule" flag that tells the system to remember this match for future documents from the same vendor.

## Three matching modes

- **Manual** -- users work through matches in the `EDocOrderLineMatching.Page.al` UI, dragging imported lines to PO lines
- **Automatic** -- `EDocLineMatching.Codeunit.al` matches on Type, No., Unit Price, and UOM. Fast but only catches exact matches.
- **Copilot** -- the `Copilot/` subfolder contains `EDocPOCopilotMatching.Codeunit.al` which uses AI to propose matches for ambiguous cases where descriptions or codes differ between vendor and buyer systems

Partial matching is supported throughout -- a single PO line for 100 units can be matched against an invoice line for 60 units, leaving the remainder open for a future invoice. Price discrepancies are tracked and surfaced in the UI rather than silently accepted.
