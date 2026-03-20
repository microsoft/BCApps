# PEPPOL

Exports sales and service invoices and credit memos in PEPPOL BIS 3.0 (UBL 2.1)
format for European e-invoicing compliance.

## Quick reference

**Objects:** 31 AL objects (17 codeunits, 10 interfaces, 2 XMLports, 1 table,
1 page, 1 enum). ID range 37200-37300.

**Key files:**
- `Common/PEPPOL30.Codeunit.al` -- facade with 85+ methods, implements 8 interfaces
- `Common/PEPPOL30Impl.Codeunit.al` -- core logic (1382 lines)
- `Common/PEPPOL30Common.Codeunit.al` -- converts posted documents to Sales Header/Line buffers
- `Interfaces/` -- 10 provider interfaces defining the export pipeline
- `Sales/` and `Services/` -- parallel implementations for each document type
- `Setup/PEPPOL30Setup.Table.al` -- configuration singleton

**No dependencies** -- standalone app.

## How it works

PEPPOL provides a **customizable export pipeline** via 10 provider interfaces:

1. Document Info
2. Line Info
3. Party Info (customer, supplier)
4. Monetary Info
5. Tax Info
6. Payment Info
7. Delivery Info
8. Attachment
9. Validation
10. Posted Document Iterator

The **PEPPOL 3.0 Format** extensible enum dispatches to format-specific
implementations. Each enum value (Sales, Service) implements all 10 interfaces.
Default implementations live in the PEPPOL30 facade codeunit.

**Export flow:**

1. User triggers export from posted document page
2. Exporter codeunit loads format from PEPPOL 3.0 Setup table
3. Validation facade calls validation provider to check document readiness
4. Iterator provider fetches posted document(s) via RecordRef
5. PEPPOL30Common converts posted records to Sales Header/Line buffers
6. XMLport generates UBL 2.1 XML, calling facade methods for data extraction
7. File saved or streamed to electronic document system

**VAT handling:** 7 tax categories with strict validation:

- Z (zero-rate), E (exempt), AE (reverse-charge), K (intra-community),
  G (export), O (outside-scope) -- must have 0% VAT
- S (standard) -- must have positive VAT rate

## Structure

```
Common/
  PEPPOL30.Codeunit.al              -- Facade, delegates to Impl
  PEPPOL30Impl.Codeunit.al          -- Core data extraction logic
  PEPPOL30Common.Codeunit.al        -- RecordRef conversion utilities

Interfaces/
  [10 interface files]              -- Provider contracts

Sales/
  PEPPOLSalesExporter.Codeunit.al   -- Entry point for sales documents
  PEPPOL30SalesValidation.Codeunit.al
  PEPPOL30SalesValidationImpl.Codeunit.al
  PEPPOL30PostedSalesIterator.Codeunit.al
  PEPPOLInvoice.XMLport.al          -- UBL generation for invoices
  PEPPOLCreditMemo.XMLport.al       -- UBL generation for credit memos

Services/
  [Mirror of Sales/ for service documents]

Setup/
  PEPPOL30Setup.Table.al            -- Stores format selection
  PEPPOL30SetupCard.Page.al         -- Configuration UI

Install/
  PEPPOLInstall.Codeunit.al         -- Registers 6 electronic document formats
```

## Documentation

`extensibility_examples.md` provides 3 extension examples:
- Custom validation provider
- Custom document info provider
- Custom tax category logic

## Things to know

**Setup singleton:** PEPPOL 3.0 Setup table auto-creates on first access. Stores
selected format enum value for sales and service exports separately.

**Sales vs Service symmetry:** Sales/ and Services/ folders have identical
structure. Each implements the full pipeline for its document type.

**XMLports are data consumers:** They call facade methods to extract values and
write UBL nodes. The facade/impl split keeps XMLport code clean.

**Extensibility via interfaces:** Partners can inject custom logic by implementing
provider interfaces and assigning them in OnBeforeExport events. See
extensibility_examples.md for patterns.

**Installation:** On app install, PEPPOLInstall codeunit registers 6 electronic
document format entries (invoice/credit memo/validation for both sales and service).
These appear in the Electronic Document Format list.

**No background jobs:** Export is always user-initiated from posted document pages.
No automatic polling or batch processing.
