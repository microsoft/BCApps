# Extensions

The Extensions folder contains 38 table and page extensions that integrate E-Document functionality into standard Business Central UI. It adds "Create E-Document" and "Open E-Document" actions to posted document pages, extends purchase/sales headers with workflow fields, and injects E-Document configuration into setup pages.

## Quick reference

- **Files:** 38 AL files (13 table extensions, 25 page extensions)
- **ID range:** 6140-6184 (scattered across object types)
- **Extension targets:** Customer, Vendor, Sales, Purchase, Service, Finance Charge, Reminder, Transfer, Location
- **Pattern:** Non-invasive UI injection without modifying base table schemas

## How it works

This folder implements the "extension points for BC integration" pattern. Each posted document page (e.g., Posted Sales Invoice) gets two actions: "Create E-Document" (triggers e-document export if not already created) and "Open E-Document" (navigates to E-Document card). The actions' enabled state is controlled by an EDocumentExists boolean calculated in OnAfterGetRecord trigger.

Table extensions add workflow-related fields (E-Document Link system GUID, E-Document Service Code) to transaction headers without disrupting existing functionality. Setup pages (Purchases & Payables Setup, Customer Card, Vendor Card) get E-Document configuration fields and actions for service assignment.

The Company Information page extension adds E-Document-specific fields like GLN and endpoint ID for PEPPOL participation. Activity pages (Role Center cues) display E-Document error counts and pending import counts for visibility.

## Structure

**Posted document extensions (12 files):**
- `EDocPostedSalesInv.PageExt.al`, `EDocPostedSalesCrMemo.PageExt.al`
- `EDocPostedPurchInv.PageExt.al`, `EDocPostedPurchCrMemo.PageExt.al`
- `EDocPostedServiceInv.PageExt.al`, `EDocPostedServiceCrMemo.PageExt.al`
- `EDocPostedSalesShipment.PageExt.al`, `EDocPostedTransferShpmnt.PageExt.al`
- `EDocIssuedReminder.PageExt.al`, `EDocIssuedFinChargeMemo.PageExt.al`

**Document header extensions (6 files):**
- `EDocPurchaseHeader.TableExt.al`, `EDocPurchaseLine.TableExt.al`
- `EDocSalesInvoice.PageExt.al`, `EDocSalesCreditMemo.PageExt.al`, `EDocSalesOrder.PageExt.al`
- `EDocServiceInvoice.PageExt.al`, `EDocServiceCreditMemo.PageExt.al`, `EDocServiceOrder.PageExt.al`

**Setup and master data (8 files):**
- `EDocCompanyInformation.PageExt.al` (GLN, endpoint ID)
- `EDocCustomerCard.PageExt.al`, `EDocVendorPage.PageExt.al`
- `EDocPurchPayablesSetup.TableExt.al`, `EDocPurchPayablesSetup.PageExt.al`
- `EDocLocation.TableExt.al`, `EDocLocationCard.PageExt.al`

**Activity and navigation (4 files):**
- `EDocumentActivities.Page.al` (Role Center cue page)
- `EDocOrderMapActivities.Page.al` (Order matching cues)

**Supporting extensions (8 files):**
- `EDocAttachment.TableExt.al` (marks Document Attachment records as e-document-related)
- `EDocVendorTemplate.TableExt.al`, `EDocVendorTemplCard.PageExt.al`
- `EDocDocumentAttachmentDetails.PageExt.al`
- `EDocPurchaseOrder.PageExt.al`, `EDocPurchaseOrderList.PageExt.al`

## Things to know

- **Non-invasive design:** Extensions only add fields/actions; no modifications to existing field logic or validation. Maintains upgrade compatibility.
- **Conditional visibility:** E-Document actions only appear when relevant (e.g., "Create" only if EDocumentExists = false; "Open" only if true).
- **Trigger-based enabled state:** Each page extension calculates EDocumentExists in OnAfterGetRecord by querying E-Document table filtered by Document Record ID.
- **SystemId linking:** E-Document Link field stores E-Document.SystemId, enabling fast lookups without RecordId (useful for temp records).
- **Service Code propagation:** When user selects E-Document Service on Purchase Invoice, it's stored on Purchase Header and flows to E-Document record on import.
- **GLN configuration:** Company Information extension adds GLN field for PEPPOL participant identification (alternative to VAT Registration No.).
- **Location-level endpoint ID:** Location table extension allows configuring different PEPPOL endpoints per warehouse (multi-location support).
- **Vendor template support:** E-Document Service Code can be defaulted from Vendor Template, ensuring new vendors inherit service configuration.
- **Document attachment marking:** E-Document Attachment boolean flag distinguishes imported PDF attachments from user-uploaded files.
- **Activity cues:** Role Center extensions display "E-Documents with Errors" and "Pending E-Documents" counts for proactive monitoring.
- **Factbox integration:** Posted document pages can show E-Document Details factbox (not included in this folder, defined in core).
- **Manual creation action:** "Create E-Document" action allows manually triggering export for documents that bypassed automatic processing.
- **Order matching navigation:** Purchase Order pages include actions to navigate to E-Document Order Match page for line-level linking.
- **Workflow field extensions:** E-Document Link and Service Code fields enable workflow rules like "If Service = X, require approval before posting".
- **Minimal table pollution:** Only 2-3 fields added per table; most functionality is non-intrusive page actions.
