# E-Document Data Exchange Export Extensibility Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow partners to opt out of the built-in PEPPOL export subscriber and/or override specific field values via per-section integration events.

**Architecture:** Add a boolean field `"Use Built-in Export Subscribers"` to `E-Doc. Service Data Exch. Def.` table. Update `IsEDocExport` in CU 6162 to check this flag. Add 9 `[IntegrationEvent]` procedures at section boundaries in the subscriber for per-field overrides.

**Tech Stack:** AL (Business Central), Data Exchange framework, Integration Events

## Global Constraints

- ID range: 6100-6199 (E-Document Core)
- All new code goes under `namespace Microsoft.eServices.EDocument.IO.Peppol;`
- Table field IDs must be unique within table 6139 (next available: 7+)
- Integration events must be `[IntegrationEvent(false, false)]`
- All codeunits in this area use `Access = Internal`
- No breaking changes to existing behavior — existing PEPPOL defs must continue to work identically

---

### Task 1: Add opt-out field to `E-Doc. Service Data Exch. Def.` table and page

**Files:**
- Modify: `src\Apps\W1\EDocument\App\src\DataExchange\EDocServiceDataExchDef.Table.al`
- Modify: `src\Apps\W1\EDocument\App\src\DataExchange\EDocServiceDataExchSub.Page.al`

**Interfaces:**
- Consumes: Nothing
- Produces: Field `"Use Built-in Export Subscribers"` (field 7, Boolean, InitValue true) on table 6139 `"E-Doc. Service Data Exch. Def."`

- [ ] **Step 1: Add the field to the table**

In `EDocServiceDataExchDef.Table.al`, add field 7 after the existing field 6 block (after the closing `}` of field 6):

```al
        field(7; "Use Built-in Export Subscribers"; Boolean)
        {
            Caption = 'Use Built-in Export Subscribers';
            InitValue = true;
        }
```

- [ ] **Step 2: Expose the field on the page**

In `EDocServiceDataExchSub.Page.al`, add a new field inside the `repeater(GroupName)` block, after the `"Expt. Data Exchange Def. Name"` field:

```al
                field("Use Built-in Export Subscribers"; Rec."Use Built-in Export Subscribers")
                {
                    ToolTip = 'Specifies whether the built-in PEPPOL export subscribers run for this data exchange definition. Disable this if you use a custom export definition and do not want the built-in PEPPOL logic to interfere.';
                }
```

- [ ] **Step 3: Commit**

```bash
git add "src/Apps/W1/EDocument/App/src/DataExchange/EDocServiceDataExchDef.Table.al" "src/Apps/W1/EDocument/App/src/DataExchange/EDocServiceDataExchSub.Page.al"
git commit -m "feat(e-doc): add 'Use Built-in Export Subscribers' field to Data Exch Def table

Partners can set this to false on their custom Data Exchange Definitions
to prevent the built-in PEPPOL subscriber from firing during export."
```

---

### Task 2: Update `IsEDocExport` to respect the new flag

**Files:**
- Modify: `src\Apps\W1\EDocument\App\src\DataExchange\PEPPOL Data Exchange Definition\EDocDEDPEPPOLSubscribers.Codeunit.al`

**Interfaces:**
- Consumes: Field `"Use Built-in Export Subscribers"` from Task 1
- Produces: Updated `IsEDocExport` behavior — returns `false` for Data Exch Defs where the flag is `false`

- [ ] **Step 1: Update the `IsEDocExport` procedure**

In `EDocDEDPEPPOLSubscribers.Codeunit.al`, find the existing `IsEDocExport` procedure (around line 55):

```al
    local procedure IsEDocExport(DataExchDefCode: Code[20]): Boolean
    var
        EDocumentDataExchDef: Record "E-Doc. Service Data Exch. Def.";
    begin
        EDocumentDataExchDef.SetRange("Expt. Data Exchange Def. Code", DataExchDefCode);
        exit(not EDocumentDataExchDef.IsEmpty());
    end;
```

Replace with:

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

- [ ] **Step 2: Commit**

```bash
git add "src/Apps/W1/EDocument/App/src/DataExchange/PEPPOL Data Exchange Definition/EDocDEDPEPPOLSubscribers.Codeunit.al"
git commit -m "feat(e-doc): scope PEPPOL export subscriber to flagged defs only

IsEDocExport now checks the 'Use Built-in Export Subscribers' field.
Partner Data Exchange Definitions with the flag set to false will no
longer trigger the built-in PEPPOL subscriber during XML export."
```

---

### Task 3: Set the flag to `true` for existing defs on install/upgrade

**Files:**
- Modify: `src\Apps\W1\EDocument\App\src\EDocumentInstall.Codeunit.al`

**Interfaces:**
- Consumes: Field `"Use Built-in Export Subscribers"` from Task 1
- Produces: All existing `E-Doc. Service Data Exch. Def.` records with a non-empty export code get the flag set to `true` on upgrade

- [ ] **Step 1: Add call to new procedure in OnInstallAppPerCompany**

In the `OnInstallAppPerCompany` trigger, add a call after `InsertDataExchV2()`:

```al
    trigger OnInstallAppPerCompany()
    begin
        InsertDataExch();
        InsertDataExchV2();
        SetBuiltInExportSubscribersFlag();
    end;
```

- [ ] **Step 2: Add the SetBuiltInExportSubscribersFlag procedure**

Add this after the `InsertDataExchV2` procedure:

```al
    internal procedure SetBuiltInExportSubscribersFlag()
    var
        EDocServiceDataExchDef: Record "E-Doc. Service Data Exch. Def.";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetBuiltInExportSubscribersFlagTag()) then
            exit;

        EDocServiceDataExchDef.SetFilter("Expt. Data Exchange Def. Code", '<>%1', '');
        if EDocServiceDataExchDef.FindSet() then
            repeat
                if not EDocServiceDataExchDef."Use Built-in Export Subscribers" then begin
                    EDocServiceDataExchDef."Use Built-in Export Subscribers" := true;
                    EDocServiceDataExchDef.Modify();
                end;
            until EDocServiceDataExchDef.Next() = 0;

        UpgradeTag.SetUpgradeTag(GetBuiltInExportSubscribersFlagTag());
    end;
```

- [ ] **Step 3: Add the upgrade tag function**

Add after the existing `GetEDOCDataExchV2UpdateTag` function:

```al
    local procedure GetBuiltInExportSubscribersFlagTag(): Code[250]
    begin
        exit('MS-EDOCBuiltInExportSubscribers-20260702');
    end;
```

- [ ] **Step 4: Register the new tag**

Update `RegisterUpgradeTags` to include the new tag:

```al
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterUpgradeTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetEDOCDataExchUpdateTag());
        PerCompanyUpgradeTags.Add(GetEDOCDataExchV2UpdateTag());
        PerCompanyUpgradeTags.Add(GetBuiltInExportSubscribersFlagTag());
    end;
```

- [ ] **Step 5: Commit**

```bash
git add "src/Apps/W1/EDocument/App/src/EDocumentInstall.Codeunit.al"
git commit -m "feat(e-doc): set 'Use Built-in Export Subscribers' flag on upgrade

Ensures all existing E-Doc Service Data Exch Def records with an export
code get the flag set to true, preserving current behavior."
```

---

### Task 4: Add per-section integration events to the PEPPOL export subscriber

**Files:**
- Modify: `src\Apps\W1\EDocument\App\src\DataExchange\PEPPOL Data Exchange Definition\EDocDEDPEPPOLSubscribers.Codeunit.al`

**Interfaces:**
- Consumes: Existing global variables in CU 6162 (SupplierEndpointID, CustomerEndpointID, etc.)
- Produces: 9 public `[IntegrationEvent]` procedures that partners can subscribe to

- [ ] **Step 1: Add event call after Accounting Supplier Party preparation**

In `OnBeforeCreateXMLNodeWithoutAttributes`, find the `/cac:AccountingSupplierParty` case branch (around line 124). After all `PEPPOLMgt.GetAccountingSupplierParty*` calls and before the closing `end;` of that branch, insert:

```al
                        OnAfterPrepareAccountingSupplierParty(
                            SalesHeader, SupplierEndpointID, SupplierSchemeID, SupplierName,
                            StreetName, AdditionalStreetName, CityName, PostalZone, CountrySubentity, IdentificationCode,
                            CompanyID, CompanyIDSchemeID, TaxSchemeID,
                            PartyLegalEntityRegName, PartyLegalEntityCompanyID, PartyLegalEntitySchemeID,
                            ContactName, Telephone, Telefax, ElectronicMail);
```

- [ ] **Step 2: Add event call after Accounting Customer Party preparation**

After the `/cac:AccountingCustomerParty` branch's `PEPPOLMgt.*` calls (around line 219), insert:

```al
                        OnAfterPrepareAccountingCustomerParty(
                            SalesHeader, CustomerEndpointID, CustomerSchemeID,
                            CustomerPartyIdentificationID, CustomerPartyIDSchemeID, CustomerName,
                            CustPartyTaxSchemeCompanyID, CustPartyTaxSchemeCompIDSchID, CustTaxSchemeID,
                            CustPartyLegalEntityRegName, CustPartyLegalEntityCompanyID, CustPartyLegalEntityIDSchemeID,
                            CustContactName, CustContactTelephone, CustContactTelefax, CustContactElectronicMail);
```

- [ ] **Step 3: Add event call after Tax Representative Party preparation**

After the `/cac:TaxRepresentativeParty` branch (around line 246), insert:

```al
                        OnAfterPrepareTaxRepresentativeParty(
                            SalesHeader, TaxRepPartyNameName,
                            PayeePartyTaxSchemeCompanyID, PayeePartyTaxSchCompIDSchemeID, PayeePartyTaxSchemeTaxSchemeID);
```

- [ ] **Step 4: Add event call after Delivery preparation**

After the `/cac:Delivery` branch (around line 258), insert:

```al
                        OnAfterPrepareDelivery(SalesHeader, ActualDeliveryDate, DeliveryID, DeliveryIDSchemeID);
```

- [ ] **Step 5: Add event call after Payment Means preparation**

After the `/cac:PaymentMeans` branch (around line 278), insert:

```al
                        OnAfterPreparePaymentMeans(
                            SalesHeader, PaymentMeansCode, PaymentChannelCode, PaymentID,
                            PrimaryAccountNumberID, NetworkID, PayeeFinancialAccountID, FinancialInstitutionBranchID);
```

- [ ] **Step 6: Add event call after Tax Total preparation**

After the `/cac:TaxTotal` branch's `PEPPOLMgt.GetTaxTotalInfo` call (around line 341), insert:

```al
                        OnAfterPrepareTaxTotal(SalesHeader, TaxAmount, TaxTotalCurrencyID);
```

- [ ] **Step 7: Add event call after Legal Monetary Total preparation**

After the `/cac:LegalMonetaryTotal` branch (around line 403), insert:

```al
                        OnAfterPrepareLegalMonetaryTotal(
                            SalesHeader,
                            LineExtensionAmount, LegalMonetaryTotalCurrencyID,
                            TaxExclusiveAmount, TaxExclusiveAmountCurrencyID,
                            TaxInclusiveAmount, TaxInclusiveAmountCurrencyID,
                            AllowanceTotalAmount, AllowanceTotalAmountCurrencyID,
                            ChargeTotalAmount, ChargeTotalAmountCurrencyID,
                            PrepaidAmount, PrepaidCurrencyID,
                            PayableRoundingAmount, PayableRndingAmountCurrencyID,
                            PayableAmount, PayableAmountCurrencyID);
```

- [ ] **Step 8: Add event call after Line Item preparation**

After the `/cac:InvoiceLine/cac:Item` branch (around line 464, after `GetLineAdditionalItemPropertyInfo`), insert:

```al
                        OnAfterPrepareLineItem(
                            SalesLine, SalesHeader,
                            Description, Name, SellersItemIdentificationID, StandardItemIdentificationID, StdItemIdIDSchemeID,
                            OriginCountryIdCode, ClassifiedTaxCategoryID, InvoiceLineTaxPercent,
                            InvoiceLinePriceAmount, BaseQuantity, UnitCodeBaseQty);
```

- [ ] **Step 9: Add event call after Document Attachment preparation**

After the `/cac:AdditionalDocumentReference` branch (around line 525, before `DocumentAttachmentNumber += 1`), insert:

```al
                        OnAfterPrepareDocumentAttachment(
                            SalesHeader, AdditionalDocumentReferenceID, AdditionalDocRefDocumentType,
                            URI, Filename, MimeCode, EmbeddedDocumentBinaryObject);
```

- [ ] **Step 10: Add the 9 IntegrationEvent procedure declarations**

Add these before the `var` section (before the line `var` around line 787):

```al
    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareAccountingSupplierParty(SalesHeader: Record "Sales Header"; var SupplierEndpointID: Text; var SupplierSchemeID: Text; var SupplierName: Text; var StreetName: Text; var AdditionalStreetName: Text; var CityName: Text; var PostalZone: Text; var CountrySubentity: Text; var IdentificationCode: Text; var CompanyID: Text; var CompanyIDSchemeID: Text; var TaxSchemeID: Text; var PartyLegalEntityRegName: Text; var PartyLegalEntityCompanyID: Text; var PartyLegalEntitySchemeID: Text; var ContactName: Text; var Telephone: Text; var Telefax: Text; var ElectronicMail: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareAccountingCustomerParty(SalesHeader: Record "Sales Header"; var CustomerEndpointID: Text; var CustomerSchemeID: Text; var CustomerPartyIdentificationID: Text; var CustomerPartyIDSchemeID: Text; var CustomerName: Text; var CustPartyTaxSchemeCompanyID: Text; var CustPartyTaxSchemeCompIDSchID: Text; var CustTaxSchemeID: Text; var CustPartyLegalEntityRegName: Text; var CustPartyLegalEntityCompanyID: Text; var CustPartyLegalEntityIDSchemeID: Text; var CustContactName: Text; var CustContactTelephone: Text; var CustContactTelefax: Text; var CustContactElectronicMail: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareTaxRepresentativeParty(SalesHeader: Record "Sales Header"; var TaxRepPartyNameName: Text; var PayeePartyTaxSchemeCompanyID: Text; var PayeePartyTaxSchCompIDSchemeID: Text; var PayeePartyTaxSchemeTaxSchemeID: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareDelivery(SalesHeader: Record "Sales Header"; var ActualDeliveryDate: Text; var DeliveryID: Text; var DeliveryIDSchemeID: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPreparePaymentMeans(SalesHeader: Record "Sales Header"; var PaymentMeansCode: Text; var PaymentChannelCode: Text; var PaymentID: Text; var PrimaryAccountNumberID: Text; var NetworkID: Text; var PayeeFinancialAccountID: Text; var FinancialInstitutionBranchID: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareTaxTotal(SalesHeader: Record "Sales Header"; var TaxAmount: Text; var TaxTotalCurrencyID: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareLegalMonetaryTotal(SalesHeader: Record "Sales Header"; var LineExtensionAmount: Text; var LegalMonetaryTotalCurrencyID: Text; var TaxExclusiveAmount: Text; var TaxExclusiveAmountCurrencyID: Text; var TaxInclusiveAmount: Text; var TaxInclusiveAmountCurrencyID: Text; var AllowanceTotalAmount: Text; var AllowanceTotalAmountCurrencyID: Text; var ChargeTotalAmount: Text; var ChargeTotalAmountCurrencyID: Text; var PrepaidAmount: Text; var PrepaidCurrencyID: Text; var PayableRoundingAmount: Text; var PayableRndingAmountCurrencyID: Text; var PayableAmount: Text; var PayableAmountCurrencyID: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareLineItem(SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var Description: Text; var Name: Text; var SellersItemIdentificationID: Text; var StandardItemIdentificationID: Text; var StdItemIdIDSchemeID: Text; var OriginCountryIdCode: Text; var ClassifiedTaxCategoryID: Text; var InvoiceLineTaxPercent: Text; var InvoiceLinePriceAmount: Text; var BaseQuantity: Text; var UnitCodeBaseQty: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareDocumentAttachment(SalesHeader: Record "Sales Header"; var AdditionalDocumentReferenceID: Text; var AdditionalDocRefDocumentType: Text; var URI: Text; var Filename: Text; var MimeCode: Text; var EmbeddedDocumentBinaryObject: Text)
    begin
    end;
```

- [ ] **Step 11: Commit**

```bash
git add "src/Apps/W1/EDocument/App/src/DataExchange/PEPPOL Data Exchange Definition/EDocDEDPEPPOLSubscribers.Codeunit.al"
git commit -m "feat(e-doc): add per-section integration events to PEPPOL export subscriber

Add 9 IntegrationEvent procedures at section boundaries:
- OnAfterPrepareAccountingSupplierParty
- OnAfterPrepareAccountingCustomerParty
- OnAfterPrepareTaxRepresentativeParty
- OnAfterPrepareDelivery
- OnAfterPreparePaymentMeans
- OnAfterPrepareTaxTotal
- OnAfterPrepareLegalMonetaryTotal
- OnAfterPrepareLineItem
- OnAfterPrepareDocumentAttachment

Partners subscribing to these events can override any field value in the
PEPPOL XML export without replacing the entire format implementation."
```
