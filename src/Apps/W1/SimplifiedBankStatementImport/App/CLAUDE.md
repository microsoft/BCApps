# Simplified Bank Statement Import

Wizard-based app that guides users through defining a CSV bank statement
import format. No coding required -- upload a sample CSV file and the app
detects separator, date format, amount format, and column positions, then
generates a full Data Exchange Definition.

## Quick reference

**Path:** `App/BCApps/src/Apps/W1/SimplifiedBankStatementImport/App/`
**ID range:** 8850-8862
**Object count:** 23 (1 codeunit, 1 temporary table, 2 pages, 2 page extensions, 17 permission objects)
**Dependencies:** None
**Entry point:** Page 8850 "Bank Statement Import Wizard" (NavigatePage)

## How it works

### Wizard flow (8 steps)

1. **Welcome** -- intro screen
2. **Upload** -- user uploads sample CSV file
3. **Header Lines** -- detect/confirm how many header lines to skip
4. **Separator & Column Count** -- detect comma vs semicolon, count columns
5. **Column Mapping** -- map which columns contain Date, Amount, Description
6. **Format Details** -- detect date and amount formats via regex
7. **Try It Out** -- preview parsed data with validation coloring (red = errors)
8. **Finish** -- create Data Exchange Definition and Bank Export/Import Setup

### Format detection

**Date patterns:** 11+ regex patterns including dd-MM-yyyy, MM/dd/yyyy,
yyyyMMdd, dd.MM.yyyy, yyyy-MM-dd, and variations. First valid match wins.

**Amount patterns:** Two styles detected:
- Dot decimal (1,234.56) -- uses en-US locale
- Comma decimal (1.234,56 or 1'234,56) -- uses es-ES locale

Single-quote thousands separator (') handled for Swiss/EU formats.

### Data created on finish

The wizard creates 8 records:

- 1 Data Exch. Def (parent container)
- 1 Data Exch. Line Def (line structure)
- 1 Data Exch. Mapping (maps to Bank Acc. Reconciliation Line table)
- 3 Data Exch. Field Mapping (Date -> Transaction Date, Amount -> Statement Amount, Description -> Transaction Text)
- 3 Data Exch. Column Def (column positions and transformations)
- 1 Bank Export/Import Setup (links def to "BANKSTMT-IMPORT" code)
- Optionally updates Bank Account record if user selects one

## Structure

**Page 8850 Bank Statement Import Wizard** -- NavigatePage with 8 steps.
Contains all wizard logic (25 local procedures). Heavy lifting happens here:
- `ParseCsvFile()` -- splits CSV into temp table rows/columns
- `DetectSeparator()` -- tries comma and semicolon, picks best match
- `DetectHeaderLines()` -- counts lines before data starts
- `DetectDateFormat()` -- tries 11+ regex patterns
- `DetectAmountFormat()` -- tries dot/comma decimal patterns
- `CreateDataExchangeDefinition()` -- generates 8 records on finish

**Page 8851 Bank Statement Import Preview** -- List page showing temp
table with parsed columns. Red text indicates validation failures. Used
in step 7 (Try It Out).

**Table 8850 Temp Bank Import File Line** -- temporary table holding
parsed CSV data during wizard session. Not persisted.

**Codeunit 8850 Bank Statement Import Wizard** -- thin wrapper (4 procedures):
- `Run()` -- opens wizard page
- `GetWizardPageID()` -- returns page ID for Guided Experience integration
- `OnBeforeUploadBankFile()` integration event for extensibility/testing
- `IsEnabled()` -- feature flag check

**Page extensions:**
- 8850 extends Bank Account Card -- shows notification when no import format assigned, with action to launch wizard
- 8851 extends Payment Reconciliation Journal -- adds action to launch wizard

**Permission objects:** 17 permission sets for different roles (read/execute/edit combinations)

## Documentation

See `SimplifiedBankStatementImport.md` in app folder for user guide and screenshots.

## Things to know

**All logic lives in the wizard page** -- Codeunit 8850 is just a thin
entry point. If you need to debug format detection or data creation logic,
look in Page 8850's local procedures.

**Regex-based detection is greedy** -- first matching pattern wins. If
date/amount detection fails, add new patterns to the `DetectDateFormat()`
or `DetectAmountFormat()` procedures.

**Preview validates live** -- Step 7 parses the CSV with the detected
format and colors errors red. If preview shows red, user must go back and
fix column mapping or format settings.

**Locale codes matter** -- Amount format detection sets
`TransformationRule.DataExchangeType` to "POSITIVEPAY-EFT" (dot decimal,
en-US) or "SEPA" (comma decimal, es-ES). These control how the import
engine parses decimals.

**Single Data Exch. Def per wizard run** -- Each execution creates a new
definition. No editing/updating existing defs. To change a format, re-run
the wizard and create a new def.

**Guided Experience integration** -- Registered as Assisted Setup via
`GuidedExperience.InsertAssistedSetup()`. Appears in "Ready for Business"
group in the Assisted Setup page.

**Extensibility hook** -- `OnBeforeUploadBankFile()` integration event
fires before file upload dialog. Extensions can inject test files or
bypass upload for automated testing.

**No advanced features** -- Does not support multi-line statements,
conditional logic, or custom transformations. For complex imports, use
full Data Exchange Definition setup manually.
