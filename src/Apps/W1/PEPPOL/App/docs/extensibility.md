# PEPPOL extensibility

The PEPPOL app is designed as an open framework for localization and customization. This document explains how partners can extend the app to support country-specific e-invoicing requirements like PINT A-NZ (Australia/New Zealand) or XRechnung (Germany).

## Architecture overview

The PEPPOL export pipeline is built on **10 provider interfaces** that control every aspect of XML generation:

1. **Document Info Provider** -- document IDs, dates, currency, references
2. **Line Info Provider** -- line quantities, amounts, items, pricing details
3. **Party Info Provider** -- supplier, customer, payee, and tax representative information
4. **Monetary Info Provider** -- legal totals, rounding, prepaid amounts
5. **Tax Info Provider** -- VAT totals, subtotals by category, exchange rates
6. **Payment Info Provider** -- payment means, terms, bank accounts
7. **Delivery Info Provider** -- delivery dates, addresses, GLN identifiers
8. **Attachment Provider** -- document attachments and embedded PDFs
9. **Validation** -- header and line validation before export
10. **Posted Document Iterator** -- navigation through documents to export

Each interface has multiple procedures. For example, the Document Info Provider has 7 procedures including `GetGeneralInfo`, `GetOrderReferenceInfo`, and `GetBuyerReference`.

## The PEPPOL 3.0 Format enum

The core extensibility mechanism is the **PEPPOL 3.0 Format** enum, which has `Extensible = true`. This enum implements all 10 interfaces and provides default implementations for 8 of them.

```al
enum 37200 "PEPPOL 3.0 Format" implements
    "PEPPOL Attachment Provider",
    "PEPPOL Delivery Info Provider",
    "PEPPOL Document Info Provider",
    "PEPPOL Line Info Provider",
    "PEPPOL Monetary Info Provider",
    "PEPPOL Party Info Provider",
    "PEPPOL Payment Info Provider",
    "PEPPOL Tax Info Provider"
{
    DefaultImplementation =
        "PEPPOL Attachment Provider" = "PEPPOL30",
        "PEPPOL Delivery Info Provider" = "PEPPOL30",
        "PEPPOL Document Info Provider" = "PEPPOL30",
        "PEPPOL Line Info Provider" = "PEPPOL30",
        "PEPPOL Monetary Info Provider" = "PEPPOL30",
        "PEPPOL Party Info Provider" = "PEPPOL30",
        "PEPPOL Payment Info Provider" = "PEPPOL30",
        "PEPPOL Tax Info Provider" = "PEPPOL30";
    Extensible = true;

    value(0; "PEPPOL 3.0 - Sales")
    {
        Caption = 'PEPPOL 3.0 - Sales';
        Implementation = "PEPPOL30 Validation" = "PEPPOL30 Sales Validation",
                        "PEPPOL Posted Document Iterator" = "PEPPOL30 Sales Iterator";
    }
    value(1; "PEPPOL 3.0 - Service")
    {
        Caption = 'PEPPOL 3.0 - Service';
        Implementation = "PEPPOL30 Validation" = "PEPPOL30 Service Validation",
                        "PEPPOL Posted Document Iterator" = "PEPPOL30 Services Iterator";
    }
}
```

Notice that Validation and Posted Document Iterator have **no default implementation** -- each enum value must specify its own. This is because sales documents and service documents require different navigation and validation logic.

## Extension pattern

To add a new format variant:

1. **Create an enumextension** on PEPPOL 3.0 Format
2. **Implement custom codeunits** for interfaces you want to override
3. **Use default (PEPPOL30) implementations** for interfaces you don't need to change
4. **Register the format** on app install via Company-Initialize event

Here's the basic structure:

```al
enumextension 50100 "My Format Extension" extends "PEPPOL 3.0 Format"
{
    value(50100; "My Custom Format")
    {
        Caption = 'My Custom Format';
        Implementation =
            "PEPPOL30 Validation" = "My Validation",
            "PEPPOL Posted Document Iterator" = "My Iterator",
            "PEPPOL Document Info Provider" = "My Document Info";
        // All other interfaces use PEPPOL30 default implementation
    }
}
```

You only override what you need. Everything else delegates to the standard PEPPOL30 facade.

## Partial delegation

You can implement a custom provider that **calls standard PEPPOL30 methods** for most fields and only customizes specific values. The PEPPOL30 facade exposes all its procedures as public, making this pattern straightforward.

For example, a custom Document Info Provider might use standard logic for most fields but change how the document ID is formatted:

```al
codeunit 50101 "My Document Info" implements "PEPPOL Document Info Provider"
{
    var
        PEPPOL30: Codeunit PEPPOL30;

    procedure GetGeneralInfo(SalesHeader: Record "Sales Header"; var ID: Text; ...)
    begin
        // Delegate to standard implementation
        PEPPOL30.GetGeneralInfo(SalesHeader, ID, ...);

        // Override just the ID field
        ID := MyCustomIDFormat(SalesHeader."No.");
    end;

    procedure GetOrderReferenceInfo(SalesHeader: Record "Sales Header"; var OrderReferenceID: Text)
    begin
        // Use standard logic unchanged
        PEPPOL30.GetOrderReferenceInfo(SalesHeader, OrderReferenceID);
    end;

    // Implement other required interface procedures...
}
```

**Important:** While the PEPPOL30 facade is public, the implementation codeunit (PEPPOL30Impl) has `Access = Internal` and cannot be called directly from extensions. Always delegate through the facade.

## Format registration

When users create a new company, the PEPPOL app registers 6 electronic document formats automatically:

- PEPPOL 3.0 - Sales Invoice
- PEPPOL 3.0 - Sales Credit Memo
- PEPPOL 3.0 - Sales Validation
- PEPPOL 3.0 - Service Invoice
- PEPPOL 3.0 - Service Credit Memo
- PEPPOL 3.0 - Service Validation

This happens via a Company-Initialize event subscriber in the PEPPOL30 Subscribers codeunit.

To register your custom format, subscribe to the same event and call the electronic document format setup:

```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", OnCompanyInitialize, '', false, false)]
local procedure RegisterMyFormat()
var
    ElectronicDocumentFormat: Record "Electronic Document Format";
begin
    ElectronicDocumentFormat.InsertElectronicFormat(
        'MYCUSTOMFORMAT',
        'My Custom Format - Sales Invoice',
        Codeunit::"My Sales Exporter",
        0,
        ElectronicDocumentFormat.Usage::"Sales Invoice");
    // Repeat for credit memos, validation, etc.
end;
```

Once registered, the format appears in the Electronic Document Format list and can be assigned to customers.

## Key extensibility scenarios

### Custom validation rules

Override the Validation interface to add country-specific checks. For example, German XRechnung requires specific fields that standard PEPPOL doesn't mandate:

```al
codeunit 50102 "XRechnung Validation" implements "PEPPOL30 Validation"
{
    procedure ValidateDocument(RecordVariant: Variant)
    var
        SalesHeader: Record "Sales Header";
        PEPPOL30SalesValidation: Codeunit "PEPPOL30 Sales Validation";
    begin
        // Run standard validation first
        PEPPOL30SalesValidation.ValidateDocument(RecordVariant);

        // Add XRechnung-specific checks
        RecordVariant := SalesHeader;
        if SalesHeader."Your Reference" = '' then
            Error('XRechnung requires buyer reference (Leitweg-ID)');
    end;

    // Implement other validation procedures...
}
```

### Custom party information

Countries have different requirements for VAT number formatting and party identification schemes. Override the Party Info Provider to customize these fields:

```al
codeunit 50103 "AU Party Info" implements "PEPPOL Party Info Provider"
{
    var
        PEPPOL30: Codeunit PEPPOL30;

    procedure GetAccountingSupplierPartyInfo(var SupplierEndpointID: Text; ...)
    begin
        // Delegate to standard logic
        PEPPOL30.GetAccountingSupplierPartyInfo(SupplierEndpointID, ...);

        // Use ABN instead of GLN for Australian businesses
        if IsAustralianCompany() then begin
            SupplierEndpointID := GetABN();
            SupplierSchemeID := 'ABN';
        end;
    end;

    // Implement other party info procedures...
}
```

### Custom document references

Some formats require additional document references or attachment handling. Override the Attachment Provider or Document Info Provider to add these.

### Custom tax categories

Different countries use different tax category codes. While PEPPOL 3.0 uses standard EN 16931 categories (S, E, Z, AE, K, G, O), you might need country-specific mappings. Override the Tax Info Provider to customize tax category logic:

```al
codeunit 50104 "My Tax Info" implements "PEPPOL Tax Info Provider"
{
    var
        PEPPOL30: Codeunit PEPPOL30;

    procedure GetTaxSubtotalInfo(VATAmtLine: Record "VAT Amount Line"; ...)
    begin
        PEPPOL30.GetTaxSubtotalInfo(VATAmtLine, ...);

        // Map local tax categories to format-specific codes
        TaxTotalTaxCategoryID := MapToLocalTaxCategory(TaxTotalTaxCategoryID);
    end;

    // Implement other tax info procedures...
}
```

## Complete customization

For formats that diverge significantly from PEPPOL BIS 3.0, you can implement all 10 interfaces from scratch. However, you'll likely still want to use the PEPPOL30 facade for common logic and only override what's truly different.

Even if you implement everything custom, you still get:

- Automatic format registration on company initialization
- Integration with Business Central's electronic document framework
- Standard posted document navigation patterns
- Consistent validation and export flow

For complete examples including code samples, see `extensibility_examples.md`.

## Things to know

**Facade vs Implementation:** The PEPPOL30 codeunit is a public facade with 85+ procedures. It delegates to PEPPOL30Impl (Internal access). Extensions must use the facade, not the implementation.

**Interface method requirements:** Each interface defines mandatory procedures. When you implement an interface, you must provide all its procedures. Use the facade for delegation if you don't need custom logic.

**Sales vs Service symmetry:** Sales and Service document types have parallel implementations. If you extend one, consider extending both to maintain consistency.

**VAT category validation:** The standard implementation enforces strict VAT category rules (zero-rate categories must have 0% VAT). If your country has different rules, override the validation interface.

**Posted document conversion:** The PEPPOL30Common codeunit handles conversion from posted documents to Sales Header/Line buffers. This is shared across all formats and typically doesn't need customization.

**Setup singleton:** The PEPPOL 3.0 Setup table stores format selection per document type. Your custom format appears in this dropdown once registered.

**No XMLport customization needed:** XMLports call interface methods to get data. When you override an interface, the XMLport automatically uses your implementation. You don't need to modify XMLport code.

## Further reading

For concrete code examples, see `extensibility_examples.md` which demonstrates:
- Custom validation with additional business rules
- Custom document info with modified reference handling
- Custom tax category logic with country-specific mappings
