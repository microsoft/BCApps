# Dispositions Module - AI Context

The Dispositions module handles **post-inspection inventory actions** — what to do with inspected stock after an inspection is finished (especially after a failure).

## Files in This Module

| File | Disposition Type |
|---|---|
| `QltyDisposition.Interface.al` | Interface all dispositions must implement |
| `QltyDispositionBuffer.Table.al` | Temporary working data during disposition |
| `Transfer/QltyDispTransfer.Codeunit.al` | Move inventory via transfer order |
| `Transfer/QltyCreateTransferOrder.Report.al` | Create the transfer order document |
| `PutAway/QltyDispWarehousePutAway.Codeunit.al` | Create warehouse put-away |
| `PutAway/QltyCreateInternalPutaway.Report.al` | Create internal put-away document |
| `PutAway/QltyDispInternalPutAway.Codeunit.al` | Internal put-away handler |
| `Purchase/QltyDispPurchaseReturn.Codeunit.al` | Create purchase return order |
| `Purchase/QltyCreatePurchaseReturn.Report.al` | Purchase return document |
| `InventoryAdjustment/QltyDispNegAdjustInv.Codeunit.al` | Negative inventory adjustment |
| `InventoryAdjustment/QltyCreateNegativeAdjmt.Report.al` | Negative adjustment journal |
| `ItemTracking/QltyDispChangeTracking.Codeunit.al` | Change lot/serial/package tracking |
| `ItemTracking/QltyChangeItemTracking.Report.al` | Item tracking change report |
| `Move/QltyDispInternalMove.Codeunit.al` | Internal inventory move |
| `Move/QltyDispMoveAutoChoose.Codeunit.al` | Auto-choose movement method |
| `Move/QltyDispMoveItemReclass.Codeunit.al` | Item reclassification journal move |
| `Move/QltyDispMoveWhseReclass.Codeunit.al` | Warehouse reclassification move |
| `Move/QltyDispMoveWorksheet.Codeunit.al` | Movement worksheet move |
| `Move/QltyMoveInventory.Report.al` | Move inventory report |

## How to Add a New Disposition Action

1. **Add enum value** to `QltyDispositionAction.Enum.al`
2. **Create codeunit** implementing `IQltyDisposition` interface in the appropriate subfolder
3. **Create report** for the actual BC document/journal creation (if needed)
4. **Register the mapping** between enum value and codeunit (follow existing pattern)

## Key Enums

- `Qlty. Disposition Action` - All available disposition types
- `Qlty. Item Adj. Post Behavior` - PostImmediately vs CreateDraft
- `Qlty. Quantity Behavior` - FullQuantity, SampleQuantity, UserDefined

## Relevant Docs
- `docs/architecture.md` - Disposition layer overview and interface pattern
- `src/Document/docs/architecture.md` - When dispositions are triggered (finish inspection)
- `src/Configuration/docs/architecture.md` - Result conditions that auto-trigger dispositions
