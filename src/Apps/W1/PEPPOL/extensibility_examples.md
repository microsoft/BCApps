# Extending PEPPOL 3.0

The PEPPOL app exposes 10 interfaces through the `"PEPPOL 3.0 Format"` enum, allowing partners to override any part of the PEPPOL document generation pipeline.

## Dependency

Add a dependency on the PEPPOL app in your `app.json`:

```json
"dependencies": [
  {
    "id": "e1966889-b5fb-4fda-a84c-ea71b590e1a9",
    "name": "PEPPOL",
    "publisher": "Microsoft",
    "version": "29.0.0.0"
  }
]
```

## Architecture

The `"PEPPOL 3.0 Format"` enum (ID 37200) implements these interfaces:

| Interface | Responsibility |
|-----------|---------------|
| `"PEPPOL30 Validation"` | Document and line validation |
| `"PEPPOL Document Info Provider"` | IDs, dates, currency, references |
| `"PEPPOL Line Info Provider"` | Line quantities, amounts, items, pricing |
| `"PEPPOL Party Info Provider"` | Supplier and customer party details |
| `"PEPPOL Monetary Info Provider"` | Totals and currency amounts |
| `"PEPPOL Tax Info Provider"` | VAT, tax categories, exemptions |
| `"PEPPOL Payment Info Provider"` | Payment means and terms |
| `"PEPPOL Delivery Info Provider"` | Delivery dates, addresses, GLN |
| `"PEPPOL Attachment Provider"` | Document attachments and PDF generation |
| `"PEPPOL Posted Document Iterator"` | Iterating posted invoice/credit memo records |

Most interfaces have a default implementation in the `"PEPPOL30"` codeunit. Two interfaces — `"PEPPOL30 Validation"` and `"PEPPOL Posted Document Iterator"` — require per-value implementations because they vary between sales and service documents.

## Extending the enum

Add a new value to `"PEPPOL 3.0 Format"` and specify which interfaces you override. Interfaces you don't list fall back to the default implementation.

```al
enumextension 50100 "My PEPPOL Format" extends "PEPPOL 3.0 Format"
{
    value(50100; "My Custom PEPPOL")
    {
        Caption = 'My Custom PEPPOL';
        Implementation = "PEPPOL30 Validation" = "My PEPPOL Validation",
                         "PEPPOL Posted Document Iterator" = "PEPPOL30 Sales Iterator";
    }
}
```

> **Note:** `"PEPPOL30 Validation"` and `"PEPPOL Posted Document Iterator"` have no default implementation on the enum, so you must always specify them. You can reuse the standard codeunits (`"PEPPOL30 Sales Validation"`, `"PEPPOL30 Sales Iterator"`, etc.) or provide your own.

After installing your extension, select your new format value on the **PEPPOL 3.0 Setup** page.

## Example: Custom validation

The `"PEPPOL30 Validation"` interface defines these methods:

```al
interface "PEPPOL30 Validation"
{
    procedure ValidateDocument(RecordVariant: Variant)
    procedure ValidateDocumentLines(RecordVariant: Variant)
    procedure ValidateDocumentLine(RecordVariant: Variant)
    procedure ValidateLineTypeAndDescription(RecordVariant: Variant): Boolean
    procedure ValidatePostedDocument(RecordVariant: Variant)
}
```

All parameters are `Variant` so the same interface works for both sales and service documents.

### Overriding a single method

To customize only one method while keeping standard behavior for the rest, delegate to the standard implementation codeunit:

```al
codeunit 50100 "My PEPPOL Validation" implements "PEPPOL30 Validation"
{
    var
        StandardValidation: Codeunit "PEPPOL30 Sales Validation";

    procedure ValidateDocument(RecordVariant: Variant)
    begin
        // Custom logic: require External Document No.
        StandardValidation.ValidateDocument(RecordVariant);
    end;

    procedure ValidateDocumentLines(RecordVariant: Variant)
    begin
        StandardValidation.ValidateDocumentLines(RecordVariant);
    end;

    procedure ValidateDocumentLine(RecordVariant: Variant)
    begin
        StandardValidation.ValidateDocumentLine(RecordVariant);
    end;

    procedure ValidateLineTypeAndDescription(RecordVariant: Variant): Boolean
    begin
        exit(StandardValidation.ValidateLineTypeAndDescription(RecordVariant));
    end;

    procedure ValidatePostedDocument(RecordVariant: Variant)
    begin
        StandardValidation.ValidatePostedDocument(RecordVariant);
    end;
}
```

### Adding validation after standard checks

To run additional checks after the standard validation, call the standard method first, then add your logic:

```al
codeunit 50100 "My PEPPOL Validation" implements "PEPPOL30 Validation"
{
    var
        StandardValidation: Codeunit "PEPPOL30 Sales Validation";

    procedure ValidateDocument(RecordVariant: Variant)
    var
        SalesHeader: Record "Sales Header";
    begin
        StandardValidation.ValidateDocument(RecordVariant);
        SalesHeader := RecordVariant;
        SalesHeader.TestField("External Document No.");
    end;

    procedure ValidateDocumentLines(RecordVariant: Variant)
    begin
        StandardValidation.ValidateDocumentLines(RecordVariant);
    end;

    procedure ValidateDocumentLine(RecordVariant: Variant)
    var
        SalesLine: Record "Sales Line";
    begin
        StandardValidation.ValidateDocumentLine(RecordVariant);
        SalesLine := RecordVariant;
        SalesLine.TestField("Tax Area Code");
    end;

    procedure ValidateLineTypeAndDescription(RecordVariant: Variant): Boolean
    begin
        exit(StandardValidation.ValidateLineTypeAndDescription(RecordVariant));
    end;

    procedure ValidatePostedDocument(RecordVariant: Variant)
    begin
        StandardValidation.ValidatePostedDocument(RecordVariant);
    end;
}
```

## Example: Custom document info

To override how document-level fields are populated in the PEPPOL XML, implement `"PEPPOL Document Info Provider"`:

```al
enumextension 50100 "My PEPPOL Format" extends "PEPPOL 3.0 Format"
{
    value(50100; "My Custom PEPPOL")
    {
        Caption = 'My Custom PEPPOL';
        Implementation = "PEPPOL30 Validation" = "PEPPOL30 Sales Validation",
                         "PEPPOL Posted Document Iterator" = "PEPPOL30 Sales Iterator",
                         "PEPPOL Document Info Provider" = "My PEPPOL Doc Info";
    }
}
```

Then implement only the methods you need to change, delegating the rest to `"PEPPOL30"`:

```al
codeunit 50101 "My PEPPOL Doc Info" implements "PEPPOL Document Info Provider"
{
    var
        StandardProvider: Codeunit "PEPPOL30";

    procedure GetGeneralInfoBIS(SalesHeader: Record "Sales Header"; var ID: Text; var IssueDate: Text; var InvoiceTypeCode: Text; var Note: Text; var TaxPointDate: Text; var DocumentCurrencyCode: Text; var AccountingCost: Text)
    begin
        StandardProvider.GetGeneralInfoBIS(SalesHeader, ID, IssueDate, InvoiceTypeCode, Note, TaxPointDate, DocumentCurrencyCode, AccountingCost);
        Note := 'Custom note: ' + Note;
    end;

    // Remaining methods delegate to StandardProvider...
    procedure GetGeneralInfo(SalesHeader: Record "Sales Header"; var ID: Text; var IssueDate: Text; var InvoiceTypeCode: Text; var InvoiceTypeCodeListID: Text; var Note: Text; var TaxPointDate: Text; var DocumentCurrencyCode: Text; var DocumentCurrencyCodeListID: Text; var TaxCurrencyCode: Text; var TaxCurrencyCodeListID: Text; var AccountingCost: Text)
    begin
        StandardProvider.GetGeneralInfo(SalesHeader, ID, IssueDate, InvoiceTypeCode, InvoiceTypeCodeListID, Note, TaxPointDate, DocumentCurrencyCode, DocumentCurrencyCodeListID, TaxCurrencyCode, TaxCurrencyCodeListID, AccountingCost);
    end;

    procedure GetInvoicePeriodInfo(var StartDate: Text; var EndDate: Text)
    begin
        StandardProvider.GetInvoicePeriodInfo(StartDate, EndDate);
    end;

    procedure GetOrderReferenceInfo(SalesHeader: Record "Sales Header"; var OrderReferenceID: Text)
    begin
        StandardProvider.GetOrderReferenceInfo(SalesHeader, OrderReferenceID);
    end;

    procedure GetOrderReferenceInfoBIS(SalesHeader: Record "Sales Header"; var OrderReferenceID: Text)
    begin
        StandardProvider.GetOrderReferenceInfoBIS(SalesHeader, OrderReferenceID);
    end;

    procedure GetContractDocRefInfo(SalesHeader: Record "Sales Header"; var ContractDocumentReferenceID: Text; var DocumentTypeCode: Text; var ContractRefDocTypeCodeListID: Text; var DocumentType: Text)
    begin
        StandardProvider.GetContractDocRefInfo(SalesHeader, ContractDocumentReferenceID, DocumentTypeCode, ContractRefDocTypeCodeListID, DocumentType);
    end;

    procedure GetBuyerReference(SalesHeader: Record "Sales Header") BuyerReference: Text
    begin
        BuyerReference := StandardProvider.GetBuyerReference(SalesHeader);
    end;

    procedure GetCrMemoBillingReferenceInfo(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var InvoiceDocRefID: Text; var InvoiceDocRefIssueDate: Text)
    begin
        StandardProvider.GetCrMemoBillingReferenceInfo(SalesCrMemoHeader, InvoiceDocRefID, InvoiceDocRefIssueDate);
    end;
}
```
