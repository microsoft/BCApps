# V2 Data Exchange Definition — Complete Field Mapping

Derived systematically from the PEPPOL handler + utility code to ensure 1:1 parity.

Target staging tables:
- **6100** = E-Document Purchase Header
- **6101** = E-Document Purchase Line
- **1173** = Document Attachment (unchanged from v1)

---

## PEPPOL HANDLER EXTRACTION → DATA EXCHANGE MAPPING

### PopulateInvoiceDocumentInfo / PopulateCreditNoteDocumentInfo

| # | PEPPOL Handler XPath | Staging Field (Table/ID) | Invoice Col | CrMemo Col | Notes |
|---|---------------------|--------------------------|-------------|------------|-------|
| H1 | `/Invoice/cbc:ID` | 6100/5 Sales Invoice No. | 1 | 1 | CrMemo: `/CreditNote/cbc:ID` |
| H2 | `/Invoice/cac:OrderReference/cbc:ID` | 6100/4 Purchase Order No. | 5 | 5 | |
| H3 | `/CreditNote/cac:BillingReference/cac:InvoiceDocumentReference/cbc:ID` | 6100/40 Applies-to Ext. Invoice No. | — | 6 | Credit memo only |

### PopulateSupplierInfo (utility lines 107-132)

| # | PEPPOL Handler XPath | Staging Field (Table/ID) | Invoice Col | CrMemo Col | Notes |
|---|---------------------|--------------------------|-------------|------------|-------|
| S1 | `.../AccountingSupplierParty/cac:Party/cac:PartyName/cbc:Name` | 6100/9 Vendor Company Name | 8 | 9 | Primary vendor name |
| S2 | `.../AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName` | 6100/9 Vendor Company Name | NEW-43 | NEW-44 | Fallback if S1 empty. **NEW COLUMN NEEDED** |
| S3 | `.../PayeeParty/cac:PartyName/cbc:Name` | 6100/9 Vendor Company Name | 16 | 16 | Overrides S1/S2 if present |
| S4 | `.../AccountingSupplierParty/cac:Party/cac:Contact/cbc:Name` | 6100/37 Vendor Contact Name | NEW-44 | NEW-45 | **NEW COLUMN NEEDED** |
| S5 | `.../AccountingSupplierParty/cac:Party/cac:PostalAddress/cbc:StreetName` | 6100/10 Vendor Address | 30 | 30 | |
| S6 | `.../AccountingSupplierParty/cac:Party/cac:PartyTaxScheme/cbc:CompanyID` | 6100/31 Vendor VAT Id | NEW-45 | NEW-46 | Primary VAT source. **NEW COLUMN NEEDED** |
| S7 | `.../PayeeParty/cac:PartyLegalEntity/cbc:CompanyID` | 6100/31 Vendor VAT Id | NEW-46 | NEW-47 | Overrides S6 if present. **NEW COLUMN NEEDED** |
| S8 | `.../AccountingSupplierParty/cac:Party/cbc:EndpointID` (schemeID=0088) | 6100/35 Vendor GLN | 6 | 7 | Only when schemeID=0088 |

### PopulateCustomerInfo (utility lines 139-167)

| # | PEPPOL Handler XPath | Staging Field (Table/ID) | Invoice Col | CrMemo Col | Notes |
|---|---------------------|--------------------------|-------------|------------|-------|
| C1 | `.../AccountingCustomerParty/cac:Party/cac:PartyName/cbc:Name` | 6100/2 Customer Company Name | 28 | 28 | Primary customer name |
| C2 | `.../AccountingCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName` | 6100/2 Customer Company Name | NEW-47 | NEW-48 | Fallback if C1 empty. **NEW COLUMN NEEDED** |
| C3 | `.../AccountingCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:CompanyID` | 6100/32 Customer VAT Id | NEW-48 | NEW-49 | First VAT source (no schemeID filter). **NEW COLUMN NEEDED** |
| C4 | `.../AccountingCustomerParty/cac:Party/cac:PartyTaxScheme/cbc:CompanyID` | 6100/32 Customer VAT Id | 13 | 14 | Overrides C3 if present |
| C5 | `.../AccountingCustomerParty/cac:Party/cac:PostalAddress/cbc:StreetName` | 6100/12 Customer Address | 29 | 29 | |
| C6 | `.../AccountingCustomerParty/cac:Party/cbc:EndpointID` (schemeID=0088) | 6100/34 Customer GLN | 11 | 12 | Only when schemeID=0088 |
| C7 | `.../AccountingCustomerParty/cac:Party/cbc:EndpointID` (as schemeID:value) | 6100/3 Customer Company Id | NEW-49 | NEW-50 | Format: "schemeID:value". **NEW COLUMN NEEDED** |

### PopulateAmountsAndDates (utility lines 174-183)

| # | PEPPOL Handler XPath | Staging Field (Table/ID) | Invoice Col | CrMemo Col | Notes |
|---|---------------------|--------------------------|-------------|------------|-------|
| A1 | `.../LegalMonetaryTotal/cbc:PayableAmount` | 6100/21 Total | 25 | 25 | |
| A2 | `.../LegalMonetaryTotal/cbc:TaxExclusiveAmount` | 6100/18 Sub Total | 38 | 39 | CrMemo col shifted |
| A3 | `.../LegalMonetaryTotal/cbc:AllowanceTotalAmount` | 6100/19 Total Discount | 17 | 17 | |
| A4 | *Calculated: Total - Sub Total - Total Discount* | 6100/20 Total VAT | — | — | **Cannot map via DataExch.** Handler calculates this. DX will leave blank — must be calculated in bridge or post-processing. |
| A5 | `/Invoice/cbc:DueDate` | 6100/7 Due Date | 36 | 36 | CrMemo path: `.../PaymentMeans/cbc:PaymentDueDate` |
| A6 | `.../cbc:IssueDate` | 6100/8 Document Date | 2 | 2 | |

### PopulateCurrency (utility lines 188-194)

| # | PEPPOL Handler XPath | Staging Field (Table/ID) | Invoice Col | CrMemo Col | Notes |
|---|---------------------|--------------------------|-------------|------------|-------|
| CU1 | `.../cbc:DocumentCurrencyCode` | 6100/24 Currency Code | 3 | 3 | |

---

## LINE EXTRACTION — PopulatePurchaseLine (utility lines 204-237)

| # | PEPPOL Handler XPath | Staging Field (Table/ID) | Invoice Col | CrMemo Col | Notes |
|---|---------------------|--------------------------|-------------|------------|-------|
| L1 | `.../cbc:InvoicedQuantity` | 6101/6 Quantity | 2 | 2 | CrMemo: `cbc:CreditedQuantity` |
| L2 | `.../cbc:InvoicedQuantity/@unitCode` | 6101/7 Unit of Measure | 3 | 3 | |
| L3 | `.../cbc:LineExtensionAmount` | 6101/9 Sub Total | 4 | 4 | |
| L4 | `.../cac:AllowanceCharge/cbc:Amount` | 6101/10 Total Discount | 6 | 6 | Handler has NO ChargeIndicator filter; v1 DX had `[ChargeIndicator='false']`. Keep v1 XPath filter for correctness. |
| L5 | `.../cac:Item/cbc:Name` | 6101/5 Description | 11 | 11 | Primary description |
| L6 | `.../cac:Item/cbc:Description` | 6101/5 Description | 10 | 10 | Fallback if L5 empty |
| L7 | `.../cac:Item/cac:SellersItemIdentification/cbc:ID` | 6101/4 Product Code | 12 | 12 | |
| L8 | `.../cac:Item/cac:StandardItemIdentification/cbc:ID` | 6101/4 Product Code | 13 | 13 | Overrides L7 if present |
| L9 | `.../cac:Item/cac:ClassifiedTaxCategory/cbc:Percent` | 6101/11 VAT Rate | 15 | 15 | |
| L10 | `.../cac:Price/cbc:PriceAmount` | 6101/8 Unit Price | 16 | 16 | |
| L11 | `.../cbc:LineExtensionAmount/@currencyID` | 6101/12 Currency Code | 5 | 5 | |

---

## ITEMS NOT MAPPABLE VIA DATA EXCHANGE

| Item | PEPPOL Handler Behavior | Data Exchange Limitation |
|------|------------------------|--------------------------|
| Total VAT calculation | `Total - Sub Total - Discount` | DataExch cannot do arithmetic. Must be calculated in bridge code or post-processing. |
| Document-level charge lines | Handler creates extra E-Document Purchase Line records | DataExch column defs are per-line-element; cannot create extra lines from header-level elements. |
| Customer Company Id format | Handler formats as `schemeID:value` | DataExch can only extract the element value, not concatenate with attribute. NEW column will extract raw EndpointID value only. |
| Vendor GLN schemeID check | Handler only sets GLN when `@schemeID='0088'` | v1 XPath `EndpointID[@schemeID='0088']` handles this correctly via XPath filter. |
| Customer GLN schemeID check | Handler only sets GLN when `@schemeID='0088'` | Same — XPath filter handles this. |

---

## COMPLETE INVOICE HEADER MAPPING (PEPPOLINVHEADER → 6100)

Columns from v1 retained + NEW columns added. Column numbers follow v1 numbering with NEW columns appended.

| Col | Name | XPath | Target | Field | Optional |
|-----|------|-------|--------|-------|----------|
| 1 | ID | /Invoice/cbc:ID | 6100/5 | Sales Invoice No. | |
| 2 | IssueDate | /Invoice/cbc:IssueDate | 6100/8 | Document Date | |
| 3 | DocumentCurrencyCode | /Invoice/cbc:DocumentCurrencyCode | 6100/24 | Currency Code | |
| 5 | OrderReferenceID | /Invoice/cac:OrderReference/cbc:ID | 6100/4 | Purchase Order No. | |
| 6 | SupplierEndpointGLNID | .../EndpointID[@schemeID='0088'] | 6100/35 | Vendor GLN | |
| 8 | SupplierName | .../PartyName/cbc:Name | 6100/9 | Vendor Company Name | |
| 11 | CustomerEndpointIDGLN | .../AccountingCustomerParty/.../EndpointID[@schemeID='0088'] | 6100/34 | Customer GLN | Yes |
| 13 | CustPartyTaxSchemeCompanyID | .../PartyTaxScheme/cbc:CompanyID | 6100/32 | Customer VAT Id | Yes |
| 16 | PartyLegalEntityName | /Invoice/cac:PayeeParty/cac:PartyName/cbc:Name | 6100/9 | Vendor Company Name | |
| 17 | DiscountAmount | .../LegalMonetaryTotal/cbc:AllowanceTotalAmount | 6100/19 | Total Discount | Yes |
| 25 | PayableAmount | .../LegalMonetaryTotal/cbc:PayableAmount | 6100/21 | Total | Yes |
| 28 | CustomerPartyName | .../AccountingCustomerParty/.../PartyName/cbc:Name | 6100/2 | Customer Company Name | Yes |
| 29 | CustomerPartyStreetName | .../AccountingCustomerParty/.../PostalAddress/cbc:StreetName | 6100/12 | Customer Address | Yes |
| 30 | SupplierStreetName | .../AccountingSupplierParty/.../PostalAddress/cbc:StreetName | 6100/10 | Vendor Address | |
| 36 | DueDate | /Invoice/cbc:DueDate | 6100/7 | Due Date | |
| 38 | AmountExclVAT | .../LegalMonetaryTotal/cbc:TaxExclusiveAmount | 6100/18 | Sub Total | Yes |
| 43 | SupplierRegistrationName | .../AccountingSupplierParty/.../PartyLegalEntity/cbc:RegistrationName | 6100/9 | Vendor Company Name | Yes | **NEW** |
| 44 | SupplierContactName | .../AccountingSupplierParty/.../Contact/cbc:Name | 6100/37 | Vendor Contact Name | Yes | **NEW** |
| 45 | SupplierTaxSchemeCompanyID | .../AccountingSupplierParty/.../PartyTaxScheme/cbc:CompanyID | 6100/31 | Vendor VAT Id | | **NEW** |
| 46 | PayeePartyLegalEntityCompanyID | /Invoice/cac:PayeeParty/cac:PartyLegalEntity/cbc:CompanyID | 6100/31 | Vendor VAT Id | Yes | **NEW** |
| 47 | CustomerRegistrationName | .../AccountingCustomerParty/.../PartyLegalEntity/cbc:RegistrationName | 6100/2 | Customer Company Name | Yes | **NEW** |
| 48 | CustPartyLegalEntityCompanyID | .../AccountingCustomerParty/.../PartyLegalEntity/cbc:CompanyID | 6100/32 | Customer VAT Id | Yes | **NEW** |

### Dropped from v1 (no staging equivalent):

| v1 Col | Name | Reason |
|--------|------|--------|
| 7 | SupplierEndpointVATID | Replaced by col 45 (PartyTaxScheme source, matching handler) |
| 9 | PartyLegalEntityCompanyIDGLN | Redundant with col 6 |
| 10 | PartyLegalEntityCompanyIDVAT | Redundant with col 45 |
| 12 | CustomerPartyIdentificationIDGLN | Redundant with col 11 |
| 14 | CustPartyLegalEntityCompanyID | Now col 48 (without schemeID filter, matching handler) |
| 18-24 | Currency/Charge/Prepaid fields | No staging equivalent |
| 26-27 | PayableAmountCurrencyID, YourReference | No staging equivalent |
| 31-35 | Payee GLN/VAT, ChargeReason | Vendor lookup fields not needed in v2 |
| 37 | DocumentType constant | Determined by namespace |
| 39-42 | Bank fields | No staging equivalent |
| 40 | TaxAmount | Total VAT is calculated, not read directly |

---

## COMPLETE CREDIT MEMO HEADER MAPPING (PEPPOLCRMEMOHEADER → 6100)

Credit memo has different column numbering due to col 6 = BillingReference (shifting subsequent cols).

| Col | Name | XPath | Target | Field | Optional |
|-----|------|-------|--------|-------|----------|
| 1 | ID | /CreditNote/cbc:ID | 6100/5 | Sales Invoice No. | |
| 2 | IssueDate | /CreditNote/cbc:IssueDate | 6100/8 | Document Date | |
| 3 | DocumentCurrencyCode | /CreditNote/cbc:DocumentCurrencyCode | 6100/24 | Currency Code | |
| 5 | OrderReferenceID | /CreditNote/cac:OrderReference/cbc:ID | 6100/4 | Purchase Order No. | Yes |
| 6 | InvoiceDocumentReferenceId | .../BillingReference/cac:InvoiceDocumentReference/cbc:ID | 6100/40 | Applies-to Ext. Invoice No. | |
| 7 | SupplierEndpointGLNID | .../EndpointID[@schemeID='0088'] | 6100/35 | Vendor GLN | |
| 9 | SupplierName | .../PartyName/cbc:Name | 6100/9 | Vendor Company Name | |
| 12 | CustomerEndpointIDGLN | .../AccountingCustomerParty/.../EndpointID[@schemeID='0088'] | 6100/34 | Customer GLN | Yes |
| 14 | CustPartyTaxSchemeCompanyID | .../PartyTaxScheme/cbc:CompanyID | 6100/32 | Customer VAT Id | Yes |
| 16 | PartyLegalEntityName | /CreditNote/cac:PayeeParty/cac:PartyName/cbc:Name | 6100/9 | Vendor Company Name | |
| 17 | DiscountAmount | .../LegalMonetaryTotal/cbc:AllowanceTotalAmount | 6100/19 | Total Discount | Yes |
| 25 | PayableAmount | .../LegalMonetaryTotal/cbc:PayableAmount | 6100/21 | Total | Yes |
| 28 | CustomerPartyName | .../AccountingCustomerParty/.../PartyName/cbc:Name | 6100/2 | Customer Company Name | Yes |
| 29 | CustomerPartyStreetName | .../AccountingCustomerParty/.../PostalAddress/cbc:StreetName | 6100/12 | Customer Address | Yes |
| 30 | SupplierStreetName | .../AccountingSupplierParty/.../PostalAddress/cbc:StreetName | 6100/10 | Vendor Address | |
| 36 | PaymentDueDate | /CreditNote/cac:PaymentMeans/cbc:PaymentDueDate | 6100/7 | Due Date | |
| 39 | AmountExclVAT | .../LegalMonetaryTotal/cbc:TaxExclusiveAmount | 6100/18 | Sub Total | Yes |
| 44 | SupplierRegistrationName | .../AccountingSupplierParty/.../PartyLegalEntity/cbc:RegistrationName | 6100/9 | Vendor Company Name | Yes | **NEW** |
| 45 | SupplierContactName | .../AccountingSupplierParty/.../Contact/cbc:Name | 6100/37 | Vendor Contact Name | Yes | **NEW** |
| 46 | SupplierTaxSchemeCompanyID | .../AccountingSupplierParty/.../PartyTaxScheme/cbc:CompanyID | 6100/31 | Vendor VAT Id | | **NEW** |
| 47 | PayeePartyLegalEntityCompanyID | /CreditNote/cac:PayeeParty/cac:PartyLegalEntity/cbc:CompanyID | 6100/31 | Vendor VAT Id | Yes | **NEW** |
| 48 | CustomerRegistrationName | .../AccountingCustomerParty/.../PartyLegalEntity/cbc:RegistrationName | 6100/2 | Customer Company Name | Yes | **NEW** |
| 49 | CustPartyLegalEntityCompanyID | .../AccountingCustomerParty/.../PartyLegalEntity/cbc:CompanyID | 6100/32 | Customer VAT Id | Yes | **NEW** |

---

## COMPLETE LINE MAPPING (PEPPOLINVLINES / PEPPOLCRMEMOLINES → 6101)

Same for both invoice and credit memo. Column numbers are identical.

| Col | Name | XPath | Target | Field | Optional |
|-----|------|-------|--------|-------|----------|
| 2 | Quantity | .../cbc:InvoicedQuantity (or CreditedQuantity) | 6101/6 | Quantity | |
| 3 | unitCode | .../cbc:InvoicedQuantity/@unitCode | 6101/7 | Unit of Measure | |
| 4 | LineExtensionAmount | .../cbc:LineExtensionAmount | 6101/9 | Sub Total | Yes |
| 5 | LineExtensionAmountCurrencyID | .../cbc:LineExtensionAmount/@currencyID | 6101/12 | Currency Code | |
| 6 | InvLnDiscountAmount | .../AllowanceCharge[ChargeIndicator='false']/cbc:Amount | 6101/10 | Total Discount | |
| 10 | Description | .../cac:Item/cbc:Description | 6101/5 | Description | |
| 11 | Name | .../cac:Item/cbc:Name | 6101/5 | Description | |
| 12 | SellersItemIdentificationID | .../SellersItemIdentification/cbc:ID | 6101/4 | Product Code | Yes |
| 13 | StandardItemIdentificationID | .../StandardItemIdentification/cbc:ID[@schemeID='0088'] | 6101/4 | Product Code | |
| 15 | TaxPercent | .../ClassifiedTaxCategory/cbc:Percent | 6101/11 | VAT Rate | Yes |
| 16 | PriceAmount | .../cac:Price/cbc:PriceAmount | 6101/8 | Unit Price | |
| 17 | PriceAmountCurrencyID | .../cac:Price/cbc:PriceAmount/@currencyID | 6101/12 | Currency Code | |

### Dropped from v1 lines:
| v1 Col | Name | Reason |
|--------|------|--------|
| 1 | InvoiceLineNote | Not mapped in v1 either |
| 7 | InvLnDiscountAmtCurrID | Currency already from col 5 |
| 8 | InvoiceLineTaxAmount | No staging field for line VAT amount |
| 9 | currencyID | Redundant with col 5 |
| 18 | BaseQuantity | No staging field |

---

## ATTACHMENTS (unchanged from v1)

TableId="1214", UseAsIntermediateTable="true", targeting table 1173.

| Col | Name | Target | Field |
|-----|------|--------|-------|
| 1 | AdditionalDocumentReferenceID | 1173/1 | File Name |
| 2 | EmbeddedDocumentBinaryObject | 1173/8 | Document Reference ID |
| 3 | MimeCode | 1173/7 | File Type |
| 4 | Filename | 1173/5 | File Name |

---

## BRIDGE CODE STILL NEEDED FOR

1. **Total VAT**: Calculate `Total - Sub Total - Total Discount` after all fields populated
2. **Amount Due**: Copy from Total (handler doesn't set this but the old bridge did)
3. **Customer Company Id**: Format as `schemeID:value` from EndpointID — DataExch cannot concatenate attribute+value
4. **Currency Code LCY-blank**: Compare against GL Setup LCY Code, blank when match — DataExch writes raw XML value
5. **Document-level charge lines**: Create extra E-Document Purchase Line records from AllowanceCharge[ChargeIndicator='true'] — DataExch cannot create lines from header-level elements

## XPATH DIFFERENCES FROM V1 (intentional)

- **Line col 13 (StandardItemIdentificationID)**: Remove `[@schemeID='0088']` filter to match handler behavior (accepts any schemeID)
- **Line col 6 (InvLnDiscountAmount)**: Keep `[ChargeIndicator='false']` filter — more correct than handler which has no filter
