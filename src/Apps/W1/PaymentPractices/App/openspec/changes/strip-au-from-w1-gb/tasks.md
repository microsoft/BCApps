## 1. Delete pure-AU objects

- [x] 1.1 Delete `src/Reports/PaymPracAUDeclaration.Report.al` (R680)
- [x] 1.2 Delete `src/Reports/PaymPracAUDeclaration.docx` (Word layout)
- [x] 1.3 Delete `src/Core/PaymPracAUCSVExport.Codeunit.al` (C694)
- [x] 1.4 Delete `src/Tables/PaymPracVendor.TableExt.al` (TE680)
- [x] 1.5 Delete `src/Pages/PaymPracVendorCard.PageExt.al` (PE680)

## 2. Stub the Small Business handler

- [x] 2.1 Replace `src/Core/PaymPracSmallBusHandler.Codeunit.al` (C682) with empty pass-through stub — remove all AU logic, keep interface implementation with empty method bodies

## 3. Edit W1 source files

- [x] 3.1 Edit `src/Core/PaymentPeriodMgt.Codeunit.al` — remove `'AU', 'NZ'` case branch in `DetectReportingScheme()`
- [x] 3.2 Edit `src/Tables/PaymentPeriod.Table.al` — remove `'AU','NZ'` case branch in `SetupDefaults()` and delete `InsertDefaultPeriods_AUNZ()` method
- [x] 3.3 Edit `src/Pages/PaymentPracticeCard.Page.al` — remove `ExportAUCSV` action and `ExportAUCSV_Promoted` actionref
- [x] 3.4 Edit `src/Core/PaymPracObjects.PermissionSet.al` — remove permission lines for `report "Paym. Prac. AU Declaration"` and `codeunit "Paym. Prac. AU CSV Export"`

## 4. Edit test projects

- [x] 4.1 Edit `PaymentPracticesUT.Codeunit.al` — remove 4 Small Business test procedures: `SmallBusinessValidateHeaderRejectsCustomer`, `SmallBusinessValidateHeaderRejectsVendorCustomer`, `SmallBusinessNonSmallVendorExcluded`, `SmallBusinessSmallVendorIncluded`
- [x] 4.2 Edit `PaymentPracticesLibrary.Codeunit.al` — remove `CreateSmallBusinessVendor()` procedure

## 5. Verify

- [x] 5.1 Confirm AL compiler produces zero errors for App, Test, and Test Library projects
- [x] 5.2 Amend commit 260ce28 with AU-stripped code (or create new commit)
