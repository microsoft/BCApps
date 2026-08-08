# Integration Module - AI Context

The Integration module connects Quality Management to standard BC modules using **event subscribers**. It never modifies base app code — it only hooks into published events.

## Sub-modules

```
Integration/
├── Assembly/         Assembly order triggers
├── Foundation/
│   ├── Attachment/   Photo/document attachment integration
│   └── Navigate/     Navigate page integration
├── Inventory/        Item tracking, transfers, item availability, item journal
│   ├── Availability/ Item availability info
│   ├── Item/         Item card/list extensions
│   ├── Tracking/     Lot/Serial/Package info extensions + tracking integration
│   └── Transfer/     Transfer order document and history extensions
├── Manufacturing/    Production order output + routing + journals
│   ├── Document/     Prod. Order Routing page extension
│   ├── Journal/      Output/Consumption journal extensions
│   └── Routing/      Routing line lookup
├── Purchases/        Purchase order line extensions
│   └── Document/     PO and purchase return order subform extensions
├── Receiving/        Purchase receiving, transfer receiving, warehouse receipt, sales returns
├── Sales/            Sales order line extensions
│   └── Document/     Sales order and sales return order subform extensions
├── Utilities/        Integration with BC utilities (misc BC interactions)
└── Warehouse/        Warehouse entries and warehouse receipt integration
    └── Ledger/       Warehouse entry extensions
```

## How to Add a New Integration Trigger

1. **Create trigger enum** (if needed for a new module): Add `Qlty<Module>Trigger.Enum.al` in the appropriate sub-folder. Follow the pattern of existing trigger enums.

2. **Add event subscriber** in the relevant integration codeunit (e.g., `QltyReceivingIntegration`):
```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"<Base App Codeunit>", '<EventName>', '', false, false)]
local procedure OnAfterSomeEvent(var Rec: Record "<Table>")
var
    QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
begin
    QltyInspectionCreate.CreateInspectionWithVariant(Rec, false);
end;
```

3. **Add generation rule support**: Ensure the source table is covered by a Source Configuration entry (see `QltyAutoConfigure` for how standard tables are registered).

4. **Add guided setup page** (optional): For new modules, add a `Qlty<Module>GenRuleSGuide.Page.al` following the pattern of `QltyRecGenRuleSGuide.Page.al`.

## Integration Codeunits

| Codeunit | Module | What it hooks into |
|---|---|---|
| `QltyReceivingIntegration` | Receiving | Purchase order receipt, warehouse receipt, sales return, transfer receipt |
| `QltyManufacturIntegration` | Manufacturing | Production output journal, consumption journal |
| `QltyAssemblyIntegration` | Assembly | Assembly order posting |
| `QltyTransferIntegration` | Inventory/Transfer | Transfer order shipment/receipt |
| `QltyTrackingIntegration` | Inventory/Tracking | Item tracking line changes, lot/serial/package creation |
| `QltyWarehouseIntegration` | Warehouse | Warehouse receipt posting |
| `QltyInventoryAvailability` | Inventory | Item availability calculations (quality holds) |
| `QltyItemJournalManagement` | Inventory | Item journal posting |
| `QltyItemTracking` | Inventory | Item tracking assignment |
| `QltyItemTrackingMgmt` | Inventory | Item tracking management |
| `QltyAttachmentIntegration` | Foundation | Document attachment events |
| `QltyNavigateIntegration` | Foundation | Navigate page "Find" integration |
| `QltyUtilitiesIntegration` | Utilities | Miscellaneous BC utility hooks |

## Relevant Docs
- `docs/architecture.md` - Full integration layer description
- `src/Document/docs/architecture.md` - Inspection creation entry point
- `src/Configuration/docs/architecture.md` - Generation rules and source configuration
