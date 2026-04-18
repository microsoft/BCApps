# Send To Email Printer

Cloud printing solution that sends report output as PDF attachments to a
printer's email address. Any printer with an email interface (HP ePrint,
Google Cloud Print-compatible devices, etc.) can receive jobs from Business
Central without VPN or direct network access.

## Quick reference

**Entry point:** Printer Management page extension adds "Add an email printer"
action. Opens Email Printer Settings card.

**Core flow:**
1. User configures printer via Email Printer Settings (2650) -- name,
   destination address, paper size, orientation
2. SetupPrinters codeunit (2650) subscribes to platform SetupPrinters event,
   broadcasts all configured email printers as JSON with paper tray config
3. User selects email printer in report request page or Printer Selection
4. OnDocumentPrintReady platform event fires when report renders to PDF
5. DocumentPrintReady codeunit (2651) looks up settings, constructs email
   with PDF attachment, sends via Email module using "Email Printer" scenario

**ID ranges:** 2650-2655, 5650-5660 (18 objects total)

## How it works

### Platform integration

Business Central's print architecture uses JSON-based printer discovery.
SetupPrinters codeunit subscribes to OnSetupPrinters and emits one JSON
printer entry per Email Printer Settings record:

```json
{
  "name": "HP Warehouse Printer",
  "paperTrays": [{
    "papersource": "Main Tray",
    "paperkind": "Custom",
    "units": "HI",
    "width": 830,
    "height": 1170,
    "landscape": false
  }]
}
```

Width/height are multiplied by 100 (platform expects hundredths of unit).
Units are "HI" (hundredths of inch) or "HMM" (hundredths of millimeter).

When a report prints to an email printer, the platform renders the PDF and
fires OnDocumentPrintReady with printer name and document stream.

### Email construction

DocumentPrintReady builds an email using the Email module:
- **To:** Email Address from settings
- **Subject:** configurable subject line (can include {1} placeholder for printer name)
- **Body:** configurable body text
- **Attachment:** PDF stream from platform, named "Document.pdf"

Uses "Email Printer" scenario (enum extension adds value 202 to base Email
Scenario enum). No retry logic -- send failures surface to user immediately.

### Configuration validation

Email Printer Settings card enforces:
- Email address format validation
- Privacy notification when entering email address
- Progressive disclosure (custom paper dimension fields only shown when
  Paper Size = Custom)
- Default to A4 dimensions (8.3" x 11.7") if custom size fields empty
- Delete blocked if printer referenced in Printer Selection table

## Structure

**Table:** Email Printer Settings (2650) -- singleton per printer. 10 fields:
ID, Description, Email Address, Email Subject/Body, Paper Size enum, Paper
Height/Width/Unit, Landscape boolean.

**Codeunits:**
- SetupPrinters (2650) -- platform event subscribers for printer discovery
  and settings page launch
- DocumentPrintReady (2651) -- OnDocumentPrintReady subscriber, email send logic

**UI:** Email Printer Settings card (2650), Printer Management page extension

**Enums:** Email Printer Paper Unit (inches/millimeters), Email Printer
Scenario (enum extension)

**Permissions:** 11 permission objects for various roles (5650-5660)

## Dependencies

None. Uses platform Email module APIs and print events.

## Things to know

- **No authentication:** Relies on printer accepting email from any sender.
  Some printers require sender whitelist configuration.

- **Synchronous send:** Email send happens in OnDocumentPrintReady event
  handler. Long SMTP timeouts or failures block the print operation.

- **No job tracking:** No correlation between print job and email message ID.
  Can't query whether printer received/processed the job.

- **Custom paper defaults:** If Paper Size = Custom but dimensions are empty,
  defaults to A4 (8.3" x 11.7" in inches). User must switch units explicitly
  if millimeters desired.

- **Telemetry events:**
  - `0001JHV` -- Discovered (page opened)
  - `0002JHW` -- Setup (printer configured)
  - `0003JHX` -- Used (print job sent)

- **Email scenario:** Extends base Email Scenario enum with "Email Printer"
  value. Uses Email module's connector and account selection logic. If no
  email account configured for scenario, send fails with actionable error.
