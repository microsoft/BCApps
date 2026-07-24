# Quality Management - Conventions

## Naming Conventions

### AL Objects

| Type | Pattern | Example |
|---|---|---|
| Tables | `Qlty. <Descriptive Name>` | `Qlty. Inspection Header` |
| Table Extensions | `Qlty<ExtendedTable>` (PascalCase file) | `QltyTransferHeader.TableExt.al` |
| Pages | `Qlty. <Name>` | `Qlty. Inspection List` |
| Page Extensions | File: `Qlty<ExtendedPage>.PageExt.al` | `QltyItemCard.PageExt.al` |
| Codeunits | `Qlty. <Domain> <Action/Type>` | `Qlty. Inspection - Create` |
| Reports | `Qlty. <Purpose>` | `Qlty. Create Inspection` |
| Enums | `Qlty. <Domain> <Type>` | `Qlty. Inspection Status` |
| Enum Extensions | `Qlty<Context><Type>.EnumExt.al` | `QltyApprovalDocumentType.EnumExt.al` |
| Interfaces | `IQlty<Name>` | `IQltyDisposition` |
| Permission Sets | `QltyMngmnt<Role>` | `QltyMngmntEdit` |

### File Names

File names use PascalCase without spaces and match the object name:
- `QltyInspectionHeader.Table.al`
- `QltyInspectionCreate.Codeunit.al`
- `QltyInspectionStatus.Enum.al`

### Namespaces

Namespace mirrors the folder structure under `src/`:

```
Microsoft.QualityManagement.Document
Microsoft.QualityManagement.Configuration.GenerationRule
Microsoft.QualityManagement.Configuration.GenerationRule.JobQueue
Microsoft.QualityManagement.Configuration.Template
Microsoft.QualityManagement.Configuration.Template.Test
Microsoft.QualityManagement.Configuration.SourceConfiguration
Microsoft.QualityManagement.Configuration.Result
Microsoft.QualityManagement.Integration.Assembly
Microsoft.QualityManagement.Integration.Inventory
Microsoft.QualityManagement.Integration.Inventory.Transfer
Microsoft.QualityManagement.Integration.Manufacturing
Microsoft.QualityManagement.Integration.Receiving
Microsoft.QualityManagement.Integration.Warehouse
Microsoft.QualityManagement.Integration.Foundation.Attachment
Microsoft.QualityManagement.Integration.Foundation.Navigate
Microsoft.QualityManagement.Integration.Utilities
Microsoft.QualityManagement.Dispositions (implied)
Microsoft.QualityManagement.Workflow
Microsoft.QualityManagement.Setup
Microsoft.QualityManagement.Utilities
Microsoft.QualityManagement.AccessControl
Microsoft.QualityManagement.Reports
Microsoft.QualityManagement.RoleCenters
Microsoft.QualityManagement.Permissions
Microsoft.QualityManagement.API
```

## Object ID Ranges

All objects use IDs within **20400-20600**.

Known assignments (from code):
- 20404: `Qlty. Inspection Gen. Rule` (table) + `Qlty. Inspection - Create` (codeunit)
- 20405: `Qlty. Inspection Header` (table)
- 20406: `Qlty. Inspection Line` (table)

When adding new objects, check existing IDs first using Grep and pick the next available in range.

## AL Code Patterns

### `NoImplicitWith` Feature Flag

The app uses `"NoImplicitWith"` — always qualify record field access explicitly:
```al
// Correct
InspectionHeader."No." := ...
InspectionHeader.Status := InspectionHeader.Status::Finished;

// Wrong (implicit with)
"No." := ...
```

### Access Modifiers

- Use `internal` for procedures not part of the public API surface
- Use `local` for procedures only used within the codeunit
- Public procedures should have XML doc comments (`/// <summary>`)

### Event Subscribers for Integration

Integration codeunits use `[EventSubscriber]` to hook into base app events. Do not call integration codeunits directly from document code — always go through events:

```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Purchase Post", 'OnAfterPostPurchaseDoc', '', false, false)]
local procedure OnAfterPostPurchaseDoc(...)
begin
    QltyInspectionCreate.CreateInspectionWithVariant(PurchaseHeader, false);
end;
```

### Inspection Creation Entry Points

Always use `QltyInspectionCreate` codeunit. The main entry points are:
- `CreateInspectionWithVariant(Variant, IsManualCreation)` - rule-based template selection
- `CreateInspectionWithVariantAndTemplate(Variant, IsManualCreation, TemplateCode)` - explicit template

The codeunit has `EventSubscriberInstance = Manual`, so instantiate it when needed.

### Interface Pattern for Dispositions

New disposition actions must implement `IQltyDisposition` interface. Register the enum value in `QltyDispositionAction` enum and map it to the interface implementation.

### Permissions Pattern

The app uses explicit `Permissions = tabledata ... = RIM` declarations on codeunits that write data, rather than relying on blanket permission sets. Follow this pattern for any new codeunit that modifies data.

### Translation

The app uses `"TranslationFile"` feature — all user-facing strings must use `Label` declarations. Do not use string literals for UI text.

## Testing Conventions

See `docs/testing.md` for the full testing approach.

- Test codeunits live in `test/src/`
- Test Library helpers live in `Test Library/src/`
- All tests use the `QltyInspectionUtility` helper from the Test Library
- Unit tests should be tagged with `[Test]` and grouped by codeunit/feature
