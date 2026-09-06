# Manual Test Scenarios

## Scope

These scenarios verify the French PEPPOL BIS 3.0 export changes for identifiers, endpoint schemes, billing profiles, document references, delivery information, and regulatory comments.

## Prerequisites

- Install and enable the **E-Reporting FR** app.
- Create an E-Document service that uses the **Peppol BIS 3.0 FR** document format.
- Configure the company with country/region code `FR` and valid posting setup.
- Configure a customer with the posting groups and address data required to post sales documents.
- Export each posted document through the configured E-Document service and save the generated XML.
- Inspect the XML with an XML-aware editor. The XPath examples use the UBL `cbc` and `cac` namespaces.

## MT-01: Standard French Customization ID and Billing Profiles

**Purpose:** Verify the French customization identifier and B1, S1, and M1 billing profiles.

1. Create and post a sales invoice containing only item lines.
2. Export it with **Peppol BIS 3.0 FR**.
3. Repeat with an invoice containing only non-item lines, such as G/L Account lines.
4. Repeat with an invoice containing both item and non-item lines.

**Expected results:**

- `/*/cbc:CustomizationID` is `urn:cen.eu:en16931:2017` for all three invoices.
- `/*/cbc:ProfileID` is `B1` for the item-only invoice.
- `/*/cbc:ProfileID` is `S1` for the non-item-only invoice.
- `/*/cbc:ProfileID` is `M1` for the mixed invoice.

## MT-02: Supplier Identifiers and Endpoint

**Purpose:** Verify supplier SIRET, SIREN, and endpoint data.

1. On **Company Information**, set:
   - **SIRET No.** to a valid 14-digit value, for example `12345678900012`.
   - **Registration No.** to the matching 9-digit SIREN, for example `123456789`.
2. Ensure there is no company service participant for the E-Document service.
3. Create, post, and export a sales invoice.

**Expected results:**

- `/*/cac:AccountingSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID` is `12345678900012` with `schemeID="0009"`.
- `/*/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:CompanyID` is `123456789` with `schemeID="0002"`.
- `/*/cac:AccountingSupplierParty/cac:Party/cbc:EndpointID` is `12345678900012` with `schemeID="0009"`.
- The generated XML is valid UBL 2.1 and the supplier elements occur in schema-valid order.

## MT-03: Buyer SIREN and Configured Endpoint Scheme

**Purpose:** Verify that the buyer legal identifier is separate from the electronic-address identifier and that the configured scheme is preserved.

1. On the customer, set:
   - **Registration Number** to `123456789`.
   - **FR Electronic Address** to `123456789`.
   - **FR Elec. Address Scheme** to `0002`.
2. Ensure there is no customer service participant for the E-Document service.
3. Create, post, and export a sales invoice for the customer.

**Expected results:**

- `/*/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID` is `123456789` with `schemeID="0002"`.
- `/*/cac:AccountingCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:CompanyID` is `123456789` with `schemeID="0002"`.
- No buyer `cac:PartyIdentification` is synthesized from the endpoint value.

Repeat with a valid SIRET endpoint and scheme `0009`; the exported endpoint must retain `schemeID="0009"`.

## MT-04: Service Participant Endpoint Precedence

**Purpose:** Verify that service-participant routing data takes precedence over customer or company fallback data.

1. Configure the customer with an FR electronic address using scheme `0225`.
2. Create a customer service participant for the selected E-Document service with:
   - **Participant Identifier** = `987654321_ABC`.
   - **FR Identifier Scheme** = `0002`.
3. Create, post, and export a sales invoice for the customer.
4. Create a company service participant with a different valid identifier and scheme, then export another invoice.

**Expected results:**

- The buyer `cbc:EndpointID` uses `987654321_ABC` and `schemeID="0002"`, not the customer fallback endpoint.
- When the company participant is configured, the supplier `cbc:EndpointID` uses the company participant identifier and its configured scheme.

## MT-05: Buyer Identifier Fallbacks

**Purpose:** Verify fallback behavior when the customer has no explicit FR electronic address.

1. Clear the customer's **FR Electronic Address** and remove its service participant.
2. Set a valid 9-digit **Registration Number**.
3. Create, post, and export a sales invoice.
4. Repeat after clearing **Registration Number** and setting a valid French VAT registration number containing a SIREN.

**Expected results:**

- With Registration Number present, buyer `cbc:EndpointID` contains the SIREN and uses `schemeID="0225"`.
- With only a valid French VAT number present, buyer `cbc:EndpointID` contains the derived SIREN and uses `schemeID="0225"`.
- Buyer `cac:PartyLegalEntity/cbc:CompanyID` contains the derived SIREN with `schemeID="0002"`.

## MT-06: Group Regulatory Comments by Type

**Purpose:** Verify that multiple comment rows of the same regulatory type produce one tagged UBL note with intact word boundaries.

1. Create a sales invoice.
2. Open its sales comments and add these two rows in order, both with regulatory type `PMD`:
   - `Tout retard de paiement engendre une pénalité exigible à compter de la date`
   - `d'échéance, calculée sur la base de trois fois le taux d'intérêt légal.`
3. Do not add trailing whitespace to the first row or leading whitespace to the second row.
4. Add an ordinary comment with regulatory type **None**.
5. Post and export the invoice.

**Expected results:**

- Exactly one `/*/cbc:Note` starts with `#PMD#`.
- Its value is:

  ```text
  #PMD#Tout retard de paiement engendre une pénalité exigible à compter de la date d'échéance, calculée sur la base de trois fois le taux d'intérêt légal.
  ```

- The PMD tag is not repeated between fragments.
- Exactly one space separates the two nonempty fragments.
- The ordinary comment is not exported as a regulatory UBL note.

## MT-07: Keep Different Regulatory Types Separate

**Purpose:** Verify grouping does not merge different regulatory comment types.

1. Create a sales invoice with two `AAB` comment rows and one `PMD` comment row.
2. Post and export the invoice.

**Expected results:**

- The XML contains exactly one note beginning with `#AAB#` and exactly one note beginning with `#PMD#`.
- Both AAB row values occur in their original order in the AAB note and are separated by one space.
- The PMD value appears only in the PMD note.

## MT-08: Credit Memo Billing Reference and Regulatory Comment

**Purpose:** Verify the reference to the corrected invoice and regulatory-note export for a credit memo.

1. Create and post a sales invoice.
2. Create a sales credit memo that applies to that posted invoice.
3. Add an `AAB` regulatory comment to the credit memo.
4. Post and export the credit memo.

**Expected results:**

- `/*/cac:BillingReference/cac:InvoiceDocumentReference/cbc:ID` contains the posted invoice number.
- `/*/cac:BillingReference/cac:InvoiceDocumentReference/cbc:IssueDate` contains the posted invoice document date in `YYYY-MM-DD` format.
- A single header note contains `#AAB#` followed by the comment text.
- A credit memo without a valid applies-to invoice does not contain `cac:BillingReference`.

## MT-09: Extended CTC for Multiple References

**Purpose:** Verify Extended CTC selection and line-level order and delivery references.

1. Create two sales orders for the same customer with different order numbers.
2. Ship lines from both orders and combine them into one posted sales invoice.
3. Ensure the resulting invoice lines retain their order line and shipment references.
4. Export the invoice.

**Expected results:**

- `/*/cbc:CustomizationID` is `urn:cen.eu:en16931:2017#conformant#urn.cpro.gouv.fr:1p0:extended-ctc-fr`.
- Each applicable `cac:InvoiceLine` contains `cac:OrderLineReference/cbc:LineID` with the original order line number.
- `cac:OrderLineReference/cac:OrderReference/cbc:ID` contains the buyer reference from the related shipment, falling back to its external document number when necessary.
- Each shipped line contains `cac:Delivery/cbc:ID` with the shipment number.
- Each shipped line contains `cac:Delivery/cbc:ActualDeliveryDate` with the shipment posting date.

Repeat by combining multiple shipments or distinct delivery dates into one invoice; Extended CTC must also be selected.

## MT-10: Basic CTC for Repeated References

**Purpose:** Verify that repeated references alone do not trigger Extended CTC.

1. Create an invoice with multiple lines that all refer to the same order, shipment, and delivery date.
2. Export the invoice.

**Expected results:**

- `/*/cbc:CustomizationID` remains `urn:cen.eu:en16931:2017`.
- The document is not switched to Extended CTC merely because the same reference appears on multiple lines.

## MT-11: Validation of Missing or Malformed Routing Data

**Purpose:** Verify that invalid French routing identifiers are rejected before export.

For each case below, run the E-Document validation or attempt export:

1. Seller country/region code is blank.
2. Seller has no SIRET, no SIREN, no company service participant, and no valid French VAT fallback.
3. Buyer has no FR electronic address, Registration Number, valid French VAT fallback, or service participant.
4. Buyer electronic address is malformed or has a blank suffix after `_`.
5. A buyer or company service participant has a blank scheme.
6. A buyer or company service participant has a blank or malformed identifier.

**Expected results:**

- Validation stops the export with a clear error identifying the missing or malformed field.
- No E-Document payload is sent with an incomplete endpoint identifier or scheme.

## MT-12: Service Documents

**Purpose:** Verify that French validation and XML post-processing also work for service documents.

1. Create and post a service invoice for a correctly configured French customer.
2. Export it with **Peppol BIS 3.0 FR**.
3. Create and post a service credit memo that applies to the service invoice.
4. Export the service credit memo.

**Expected results:**

- Both documents pass French electronic-address validation and produce XML.
- The service invoice contains the expected French customization ID, profile, supplier endpoint, and buyer endpoint.
- The service credit memo contains a billing reference to the applied service invoice when the reference and date are available.
