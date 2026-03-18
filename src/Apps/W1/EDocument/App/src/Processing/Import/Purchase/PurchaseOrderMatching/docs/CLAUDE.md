# Purchase order matching (V2)

Three-way matching between e-document lines, purchase order lines, and receipt lines for the V2 import pipeline. This is the mechanism that handles the "receive e-document against an existing PO" scenario, where the e-document represents an invoice for goods already ordered and potentially already received.

## How it works

When the prepare draft step finds a matching purchase order (via `IPurchaseOrderProvider`), the system enters PO matching mode. `E-Doc. Purchase Line PO Match` (6114) links e-doc purchase lines to PO lines and optionally to receipt lines using SystemId-based foreign keys. The `E-Doc. PO Matching Setup` (6116) controls matching behavior per vendor -- whether receipt lines should be selected automatically or always prompted, and whether G/L account lines should be received.

The `EDocLineByReceipt` query joins purchase lines with receipt lines to find receivable quantities. The selection pages (`EDocSelectPOLines`, `EDocSelectReceiptLines`) let users manually pick which PO lines and receipt lines correspond to each e-document line.

## Things to know

- The match table's primary key is `(E-Doc. Purchase Line SystemId, Purchase Line SystemId, Receipt Line SystemId)` -- all three Guids. This means a single e-doc line can match to multiple PO lines (split deliveries) and a single PO line can match to multiple receipt lines.

- Setup has two levels: vendor-specific and global. `GetSetup(VendorNo)` first looks for a vendor-specific record, then falls back to the global setup (blank vendor no.). If neither exists, defaults are "Always ask" for receipt config and true for receiving G/L lines.

- The `E-Doc. PO M. Configuration` enum controls the overall matching mode, while `E-Doc. PO M. Config. Receipt` controls receipt line selection specifically.

- This is separate from the V1 `OrderMatching/` directory. V2 PO matching works on draft `E-Document Purchase Line` records; V1 PO matching works on `E-Doc. Imported Line` records.
