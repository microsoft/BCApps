# E-Document Data Exchange Export Extensibility

**Date:** 2026-07-01  
**Area:** E-Document → DataExchange → PEPPOL Export  
**Problem:** Partners cannot customize or opt out of built-in PEPPOL export logic  

---

## Problem Statement

The `EDocDEDPEPPOLSubscribers` codeunit (6162) subscribes to `Export Generic XML` events and fires for **all** Data Exchange Definitions linked to any E-Document Service as an export definition. This creates two problems:

1. **Forced interference** — A partner who creates their own Data Exchange Definition (with custom XPaths) and links it to an E-Document Service still gets the PEPPOL subscriber running. Although the subscriber's `case Path of` statement won't match custom paths, it still fires on every node, and could conflict if paths overlap.

2. **No per-field override** — A partner who uses the built-in PEPPOL Data Exchange Definitions but needs to change a single value (e.g., Supplier EndpointID scheme, custom tax logic) has no integration event to modify it after the subscriber sets it.

## Solution

Two complementary changes:

### 1. Opt-out flag on `E-Doc. Service Data Exch. Def.`

Add a boolean field **`"Use Built-in Export Subscribers"`** (default: `true`) to the `E-Doc. Service Data Exch. Def.` table.

Update `IsEDocExport` in CU 6162 to respect the flag:

```al
local procedure IsEDocExport(DataExchDefCode: Code[20]): Boolean
var
    EDocumentDataExchDef: Record "E-Doc. Service Data Exch. Def.";
begin
    EDocumentDataExchDef.SetRange("Expt. Data Exchange Def. Code", DataExchDefCode);
    EDocumentDataExchDef.SetRange("Use Built-in Export Subscribers", true);
    exit(not EDocumentDataExchDef.IsEmpty());
end;
```

**Installation/upgrade:** The existing PEPPOL Data Exchange Definitions (created by `EDocumentInstall`) get this field set to `true` via the install codeunit. New partner-created definitions default to `false`.

**Partner experience:**
- Partner creates a custom Data Exch Def → field defaults to `false` → PEPPOL subscriber is completely bypassed → partner has full control over their XML output.

### 2. Per-section integration events for PEPPOL tweaks

For partners who DO use the built-in PEPPOL definitions but need to override specific values, add `[IntegrationEvent]` procedures at section boundaries inside `EDocDEDPEPPOLSubscribers`:

| Event | Parameters (all `var` except SalesHeader) | Use Case |
|-------|------------------------------------------|----------|
| `OnAfterPrepareAccountingSupplierParty` | SalesHeader, SupplierEndpointID, SupplierSchemeID, SupplierName, StreetName, CityName, PostalZone, CountrySubentity, IdentificationCode, CompanyID, CompanyIDSchemeID, TaxSchemeID, PartyLegalEntityRegName, PartyLegalEntityCompanyID, PartyLegalEntitySchemeID, ContactName, Telephone, Telefax, ElectronicMail | Override supplier identification, address, or tax registration |
| `OnAfterPrepareAccountingCustomerParty` | SalesHeader, CustomerEndpointID, CustomerSchemeID, CustomerPartyIdentificationID, CustomerPartyIDSchemeID, CustomerName, CustPartyTaxSchemeCompanyID, CustPartyTaxSchemeCompIDSchID, CustTaxSchemeID, CustPartyLegalEntityRegName, CustPartyLegalEntityCompanyID, CustPartyLegalEntityIDSchemeID, CustContactName, CustContactTelephone, CustContactTelefax, CustContactElectronicMail | Override customer identification or contact |
| `OnAfterPrepareTaxRepresentativeParty` | SalesHeader, TaxRepPartyNameName, PayeePartyTaxSchemeCompanyID, PayeePartyTaxSchCompIDSchemeID, PayeePartyTaxSchemeTaxSchemeID | Override tax representative info |
| `OnAfterPrepareDelivery` | SalesHeader, ActualDeliveryDate, DeliveryID, DeliveryIDSchemeID | Override delivery location/date |
| `OnAfterPreparePaymentMeans` | SalesHeader, PaymentMeansCode, PaymentChannelCode, PaymentID, PrimaryAccountNumberID, NetworkID, PayeeFinancialAccountID, FinancialInstitutionBranchID | Override payment information |
| `OnAfterPrepareTaxTotal` | SalesHeader, TempVATAmtLine, TaxAmount, TaxTotalCurrencyID | Override tax totals |
| `OnAfterPrepareLegalMonetaryTotal` | SalesHeader, LineExtensionAmount, TaxExclusiveAmount, TaxInclusiveAmount, AllowanceTotalAmount, ChargeTotalAmount, PrepaidAmount, PayableRoundingAmount, PayableAmount (+ currency IDs) | Override monetary totals |
| `OnAfterPrepareLineItem` | SalesLine, SalesHeader, Description, Name, SellersItemIdentificationID, StandardItemIdentificationID, StdItemIdIDSchemeID, OriginCountryIdCode, ClassifiedTaxCategoryID, InvoiceLineTaxPercent, InvoiceLinePriceAmount, BaseQuantity, UnitCodeBaseQty | Override per-line item/pricing data |
| `OnAfterPrepareDocumentAttachment` | SalesHeader, AdditionalDocumentReferenceID, AdditionalDocRefDocumentType, URI, Filename, MimeCode, EmbeddedDocumentBinaryObject | Override attachment metadata |

**Placement:** Each event fires immediately after the existing `PEPPOLMgt.*` calls that populate the section's variables, and before those variables are used to set `xmlNodeValue`. This ensures partners see the default values and can override them.

## Files Changed

| File | Change |
|------|--------|
| `EDocServiceDataExchDef.Table.al` | Add field `"Use Built-in Export Subscribers"` (Boolean, default true) |
| `EDocDEDPEPPOLSubscribers.Codeunit.al` | Update `IsEDocExport` to check new field; add 9 `[IntegrationEvent]` procedures at section boundaries |
| `EDocumentInstall.Codeunit.al` | Set `"Use Built-in Export Subscribers" := true` for built-in PEPPOL defs on install/upgrade |
| `EDocServiceDataExchSub.Page.al` | Expose the new field on the page so partners can toggle it |

## Backward Compatibility

- Existing PEPPOL defs get the field set to `true` → no behavior change
- Partners with custom defs already linked to services will get `false` (default) → subscriber stops firing for them. This is the **desired** behavior (they were being interfered with before). If any partner somehow relied on the PEPPOL subscriber firing for their custom def, they can set the flag to `true`.

## Success Criteria

1. A partner can create a custom Data Exchange Definition, link it to an E-Document Service, and export XML without any interference from the built-in PEPPOL subscriber.
2. A partner using the built-in PEPPOL defs can subscribe to `OnAfterPrepareAccountingSupplierParty` and change the `SupplierEndpointID` — the change appears in the final XML.
3. Existing PEPPOL export behavior is unchanged (no regression).

## Out of Scope (future work)

- Import-side extensibility (Pre-Mapping events for vendor lookup, document type, GL account)
- Interface-based replacement of entire sections
- Per-node granular events
