# Send remittance advice by email

Adds "Send Remittance Advice" actions to the Payment Journal and Vendor
Ledger Entries pages, allowing users to email remittance advice to vendors.
Remittance advice lists the vendor invoice numbers covered by a payment,
helping vendors reconcile their accounts receivable.

## Quick reference

- **ID range**: 1-9999 (uses IDs 4022, 4023, 4031)
- **Dependencies**: None
- **Objects**: 4 (1 install codeunit, 2 page extensions, 1 permission set)

## How it works

The app does two things at install time and two things at runtime.

**Install (SetupRemittanceReports codeunit 4031):** On install, registers two
report selections if they don't already exist. "V.Remittance" maps to
Report "Remittance Advice - Journal" (for payment journal lines) and
"P.V.Remit." maps to Report "Remittance Advice - Entries" (for posted vendor
ledger entries). Both are configured as email attachments (not email body).

**Payment Journal action (page extension 4022):** Adds "Send Remittance Advice"
to the Payments action group. When triggered, applies the current selection
filter to Gen. Journal Line records and calls
`DocumentSendingProfile.SendVendorRecords()` with usage "V.Remittance". This
uses the standard Document Sending Profile framework to generate and email
the report. Also adds a "UK Print Remittance Advice" action (CLEAN28+) that
uses `ReportSelections.PrintWithDialogForVend()` for direct printing.

**Vendor Ledger Entries action (page extension 4023):** Adds "Send Remittance
Advice" to the Functions action group. Filters to Document Type = Payment
only, then calls `DocumentSendingProfile.SendVendorRecords()` with usage
"P.V.Remit.". Same sending framework, different report and source table.

## Things to know

- The two report selections use different usages ("V.Remittance" for journal
  lines, "P.V.Remit." for posted entries) because they reference different
  base app reports with different data sources
- Reports are set as email attachments only (`Use for Email Body = false`) --
  the PDF is attached, not rendered inline
- The vendor ledger entry action filters to Payment document type -- you
  cannot send remittance advice for invoices or other entry types
- Install codeunit uses `if not Get() then Insert()` pattern -- it won't
  overwrite existing report selections, so manual changes are preserved
- The app delegates all email sending to the Document Sending Profile
  framework -- it doesn't handle SMTP or email composition directly
- Despite "UK" in the folder name, this is a W1 (worldwide) app with no
  UK-specific logic
