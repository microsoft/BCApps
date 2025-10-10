# Extensibility examples

Existing PEPPOL functionality can be extended by partners using provided interfaces.

## Dependency

In order to extend existing PEPPOL export functionality partners first should add dependency on the 1st party app "PEPPOL" in their app.json file:

```json
  "dependencies": [
    {
      "id": "e1966889-b5fb-4fda-a84c-ea71b590e1a9",
      "name": "PEPPOL",
      "publisher": "Microsoft",
      "version": "27.0.0.0"
    }
  ]
```

## Electronic Document Formats adjustments

When the app is installed the new electronic document formats are created. In order to use new PEPPOL functionality customer would need to adjust existing "Electronic Document Formats" to only include export for the new PEPPOL format.

## Enum extension

With the new implementation of PEPPOL processing an enum "E-Document Format" has been created which can be extended as needed in order to implement custom business logic for processing:

```al
enumextension 50100 "E-Document Format" extends "E-Document Format"
{
    value(1; "PEPPOL XYZ")
    {
        Caption = 'PEPPOL XYZ';
    }
}
```

The value of the enum can be set on the `Company Information` page

## Interfaces

Existing PEPPOL functionality has been split into multiple interfaces in order to allow partners to execute their business logic in a more granular way.

Partners should only implement interfaces that they are going to extend.

```al
enumextension 50100 "E-Document Format" extends "E-Document Format"
{
    value(1; "PEPPOL XYZ")
    {
        Caption = 'PEPPOL XYZ';
        Implementation = "PEPPOL30 Validation" = "XYZ PEPPOL30 Validation";
    }
}
```

If for example partners want to implement their custom business logic in just one procedure it's possible to achieve by writing additional code in procedure while calling standard Microsoft procedures in for the remaining ones in the interface.

In this example we only want to execute custom business logic for procedure `CheckSalesDocument` why keeping the other processing standard

```al
codeunit 50149 "XYZ PEPPOL30 Validation" implements "PEPPOL30 Validation"
{
    var
        PEPPOLValidation: Codeunit "PEPPOL30 Validation";

    procedure CheckSalesDocument(SalesHeader: Record "Sales Header")
    begin
        SalesHeader.TestField("External Document No.");
    end;

    procedure CheckSalesDocumentLines(SalesHeader: Record "Sales Header")
    begin
        PEPPOLValidation.CheckSalesDocumentLines(SalesHeader);
    end;

    procedure CheckSalesDocumentLine(SalesLine: Record "Sales Line")
    begin
        PEPPOLValidation.CheckSalesDocumentLine(SalesLine);
    end;

    procedure CheckSalesInvoice(SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        PEPPOLValidation.CheckSalesInvoice(SalesInvoiceHeader);
    end;

    procedure CheckSalesCreditMemo(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        PEPPOLValidation.CheckSalesCreditMemo(SalesCrMemoHeader);
    end;

    procedure CheckSalesLineTypeAndDescription(SalesLine: Record "Sales Line"): Boolean
    begin
        exit(PEPPOLValidation.CheckSalesLineTypeAndDescription(SalesLine));
    end;
}
```

Another example is that we want to do some additional validations after standard code is finished. For this example we'll update procedure `CheckSalesDocumentLine`

```al
codeunit 50149 "XYZ PEPPOL30 Validation" implements "PEPPOL30 Validation"
{
    var
        PEPPOLValidation: Codeunit "PEPPOL30 Validation";

    procedure CheckSalesDocument(SalesHeader: Record "Sales Header")
    begin
        SalesHeader.TestField("External Document No.");
    end;

    procedure CheckSalesDocumentLines(SalesHeader: Record "Sales Header")
    begin
        PEPPOLValidation.CheckSalesDocumentLines(SalesHeader);
    end;

    procedure CheckSalesDocumentLine(SalesLine: Record "Sales Line")
    begin
        PEPPOLValidation.CheckSalesDocumentLine(SalesLine);
        SalesLine.TestField("Tax Area Code");
    end;

    procedure CheckSalesInvoice(SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        PEPPOLValidation.CheckSalesInvoice(SalesInvoiceHeader);
    end;

    procedure CheckSalesCreditMemo(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        PEPPOLValidation.CheckSalesCreditMemo(SalesCrMemoHeader);
    end;

    procedure CheckSalesLineTypeAndDescription(SalesLine: Record "Sales Line"): Boolean
    begin
        exit(PEPPOLValidation.CheckSalesLineTypeAndDescription(SalesLine));
    end;
}
```
