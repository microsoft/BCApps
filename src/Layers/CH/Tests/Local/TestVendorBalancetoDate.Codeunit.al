codeunit 144033 "Test Vendor Balance to Date"
{
    // // [FEATURE] [Report] [Purchase]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        ReportRowsErr: Label 'Expected row to be found with %1 value = %2', Comment = '%1=XML Tag Name %2 = XML Tag value';
        ReportNoRowsErr: Label 'No rows expected with %1 element name!', Comment = '%1=ConsNo_DtldVendLedgEntry';
        ReportEndDatasetErr: Label 'Only %1 rows expected to be found.', Comment = '%1 = Count of output rows';
        CountOfSheetsErr: Label '3 excel sheets expected to be found.';
        ConsNoDtldVendLedgEntryTagTxt: Label 'ConsNo_DtldVendLedgEntry';
        VendorNoTagTxt: Label 'No_Vend';
        OutputNoTagTxt: Label 'OutputNo';
        TotalTagTxt: Label 'TotalCaption';
        CountOfPagesWithTotalsErr: Label 'Report Totals are situated on the wrong page.';

    [Test]
    [HandlerFunctions('VendorBalanceToDateRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestVendorBalanceToDate()
    var
        Vendor: Record Vendor;
        AppliesToGenJournalLine: Record "Gen. Journal Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // Setup - Create an Invoice and a payment
        LibraryPurchase.CreateVendor(Vendor);
        PostPurchaseDocument(AppliesToGenJournalLine, Vendor, AppliesToGenJournalLine."Document Type"::Invoice,
          -LibraryRandom.RandDec(1000, 2), '', WorkDate());
        PostAppliedPurchaseDocument(GenJournalLine, AppliesToGenJournalLine, GenJournalLine."Document Type"::Payment,
          LibraryRandom.RandDecInDecimalRange(1, AppliesToGenJournalLine."Amount (LCY)", 2));

        Commit();

        Vendor.SetRange("No.", Vendor."No.");
        REPORT.Run(REPORT::"SR Vendor - Balance to Date", true, false, Vendor);

        // Verify
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Vend', Vendor."No.");

        // Expect 2 rows for the vendor - one detailed line for the sales invoice, and one aggregation
        Assert.AreEqual(2, LibraryReportDataset.RowCount(), 'Expected 2 rows to be found in the report');

        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('OriginalAmtLCY', AppliesToGenJournalLine."Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('VendorBalanceToDateRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestUnapplyEntry()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
        AppliesToGenJournalLine: Record "Gen. Journal Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // Setup - Create an Invoice and a payment
        LibraryPurchase.CreateVendor(Vendor);
        PostPurchaseDocument(AppliesToGenJournalLine, Vendor, AppliesToGenJournalLine."Document Type"::Invoice,
          -LibraryRandom.RandDec(1000, 2), '', WorkDate());
        PostAppliedPurchaseDocument(GenJournalLine, AppliesToGenJournalLine, GenJournalLine."Document Type"::Payment,
          LibraryRandom.RandDecInDecimalRange(1, AppliesToGenJournalLine."Amount (LCY)", 2));

        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Payment);
        VendorLedgerEntry.FindFirst();
        LibraryERM.UnapplyVendorLedgerEntry(VendorLedgerEntry);

        Commit();
        Vendor.SetRange("No.", Vendor."No.");
        REPORT.Run(REPORT::"SR Vendor - Balance to Date", true, false, Vendor);

        // Verify
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Vend', Vendor."No.");
        LibraryReportDataset.SetRange('DocNo_VendLedgEntry', VendorLedgerEntry."Document No.");

        Assert.AreEqual(2, LibraryReportDataset.RowCount(), 'Expected 2 rows to be found in the report');

        VendorLedgerEntry.CalcFields("Original Amt. (LCY)");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('OriginalAmtLCY', VendorLedgerEntry."Original Amt. (LCY)");
    end;

    [Test]
    [HandlerFunctions('VendorBalanceToDateRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckConsequentNoDtldVendLedgEntryTag()
    var
        Vendor: Record Vendor;
        Amount: array[3] of Decimal;
    begin
        // [FEATURE] [Application]

        // [SCENARIO] Vendor with invoice and two applied payments in "SR Vendor - Balance to Date" Report
        Initialize();

        // [GIVEN] Purchase Invoice "PI" with amount 1000 for vendor "V1"
        // [GIVEN] Payment "P1" with amount 300 and "P2" with amount 200 for vendor "V1" have applied to invoice "PI"
        CreatePurchaseInvoiceWithAppliedPayments(Vendor, Amount);
        Commit();

        // [WHEN] "SR Vendor - Balance to Date" run filtered on "V1" Vendor
        Vendor.SetRecFilter();
        REPORT.Run(REPORT::"SR Vendor - Balance to Date", true, false, Vendor);

        // [THEN] 3 rows generated
        // [THEN] Row[1]."ConsNo_DtldVendLedgEntry" = 1
        // [THEN] Row[2]."ConsNo_DtldVendLedgEntry" = 2
        // [THEN] Row[3] - TAG "ConsNo_DtldVendLedgEntry" does not exist
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange(VendorNoTagTxt, Vendor."No.");
        VerifyTagOnRows(ConsNoDtldVendLedgEntryTagTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithAppliedPayments()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        AppliedDocNo: Code[20];
        Amount: array[3] of Decimal;
    begin
        // [FEATURE] [Excel] [Application]

        // [SCENARIO 380055] Vendor with purchase invoice and two applied payments when "SR Vendor - Balance to Date" Report is run
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Purchase Invoice "I1" with Amount 1000
        Amount[1] := -LibraryRandom.RandDec(1000, 2);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, Vendor."No.", Amount[1]);

        AppliedDocNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Payment "P1" applied to "I1" with amount 300
        Amount[2] := LibraryRandom.RandDec(Round(-Amount[1] / 3, 1), 2);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Payment, Amount[2]);
        ApplyAndPostGenJournalLine(GenJournalLine, GenJournalLine."Applies-to Doc. Type"::Invoice, AppliedDocNo);

        // [GIVEN] Payment "P2" applied to "I1" with amount 200
        Amount[3] := LibraryRandom.RandDec(Round(-Amount[1] / 3, 1), 2);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Payment, Amount[3]);
        ApplyAndPostGenJournalLine(GenJournalLine, GenJournalLine."Applies-to Doc. Type"::Invoice, AppliedDocNo);

        Commit();

        // [WHEN] "SR Vendor - Balance to Date" run filtered on "V1" Vendor and saved as excel
        Vendor.SetRecFilter();
        LibraryReportValidation.SetFileName(Vendor."No.");
        REPORT.SaveAsExcel(REPORT::"SR Vendor - Balance to Date", LibraryReportValidation.GetFileName(), Vendor);

        // [THEN] 1st line: "I1".Amount = -900,00
        // [THEN] 2nd line: "P1".Amount = 300,00
        // [THEN] 3rd line: "P2".Amount = 200,00
        // [THEN] 4th line: "I1".Remaining Amount = -500,00
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValue(14, 15, Format(Amount[1]));
        LibraryReportValidation.VerifyCellValue(15, 15, Format(Amount[2]));
        LibraryReportValidation.VerifyCellValue(16, 15, Format(Amount[3]));
        LibraryReportValidation.VerifyCellValue(17, 15, Format(Amount[1] + Amount[2] + Amount[3]));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoPurchaseInvoicesEachWithAppliedPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        AppliedDocNo: Code[20];
        Amount: array[4] of Decimal;
    begin
        // [FEATURE] [Excel] [Application]

        // [SCENARIO 380055] Vendor with two purchase invoices applied to different payments when "SR Vendor - Balance to Date" Report is run
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Purchase Invoice "I1" with Amount 1000
        Amount[1] := -LibraryRandom.RandDec(1000, 2);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, Vendor."No.", Amount[1]);
        AppliedDocNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Payment "P1" applied to "I1" with amount 300
        Amount[2] := LibraryRandom.RandDec(Round(-Amount[1] / 3, 1), 2);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Payment, Amount[2]);
        ApplyAndPostGenJournalLine(GenJournalLine, GenJournalLine."Applies-to Doc. Type"::Invoice, AppliedDocNo);

        // [GIVEN] Purchase Invoice "I2" with amount 2000
        Amount[3] := -LibraryRandom.RandDec(1000, 2);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice, Amount[3]);
        AppliedDocNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Payment "P2" applied to "I2" with amount 200
        Amount[4] := LibraryRandom.RandDec(Round(-Amount[3] / 3, 1), 2);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Payment, Amount[4]);
        ApplyAndPostGenJournalLine(GenJournalLine, GenJournalLine."Applies-to Doc. Type"::Invoice, AppliedDocNo);

        Commit();

        // [WHEN] "SR Vendor - Balance to Date" run filtered on "V1" Vendor and saved as excel
        Vendor.SetRecFilter();
        LibraryReportValidation.SetFileName(Vendor."No.");
        REPORT.SaveAsExcel(REPORT::"SR Vendor - Balance to Date", LibraryReportValidation.GetFileName(), Vendor);

        // [THEN] 1st line: "I1".Amount = -1000
        // [THEN] 2nd line: "P1".Amount =  300
        // [THEN] 3rd line: "I1".Remaining Amount = -700
        // [THEN] 4th line: "I2".Amount = -2000
        // [THEN] 5th line: "P2".Amount = 200
        // [THEN] 6rd line: "I2".Remaining Amount = -1800
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValue(14, 15, Format(Amount[1]));
        LibraryReportValidation.VerifyCellValue(15, 15, Format(Amount[2]));
        LibraryReportValidation.VerifyCellValue(16, 15, Format(Amount[1] + Amount[2]));
        LibraryReportValidation.VerifyCellValue(17, 15, Format(Amount[3]));
        LibraryReportValidation.VerifyCellValue(18, 15, Format(Amount[4]));
        LibraryReportValidation.VerifyCellValue(19, 15, Format(Amount[3] + Amount[4]));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoicesAndAppliedPayments()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        AppliedDocNo: Code[20];
        Amount: array[6] of Decimal;
    begin
        // [FEATURE] [Excel] [Application]

        // [SCENARIO 380055] Vendor with purchase invoices and applied payments when "SR Vendor - Balance to Date" Report is run
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Purchase Invoice "I1" with amount 1000
        Amount[1] := -LibraryRandom.RandDec(1000, 2);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, Vendor."No.", Amount[1]);
        AppliedDocNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Payment "P1" with amount 300 applied to Invoice "I1"
        Amount[2] := LibraryRandom.RandDec(Round(-Amount[1] / 3, 1), 2);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Payment, Amount[2]);
        ApplyAndPostGenJournalLine(GenJournalLine, GenJournalLine."Applies-to Doc. Type"::Invoice, AppliedDocNo);

        // [GIVEN] Payment "P2" with amount 200 applied to Invoice "I1"
        Amount[3] := LibraryRandom.RandDec(Round(-Amount[1] / 3, 1), 2);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Payment, Amount[3]);
        ApplyAndPostGenJournalLine(GenJournalLine, GenJournalLine."Applies-to Doc. Type"::Invoice, AppliedDocNo);

        // [GIVEN] Payment "P3" with amount 800
        Amount[4] := LibraryRandom.RandDec(1000, 2);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Payment, Amount[4]);
        AppliedDocNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Purchase Invoice "I2" with amount 300 applied to Payment "P3"
        Amount[5] := -LibraryRandom.RandDec(Round(Amount[4] / 3, 1), 2);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice, Amount[5]);
        ApplyAndPostGenJournalLine(GenJournalLine, GenJournalLine."Applies-to Doc. Type"::Payment, AppliedDocNo);

        // [GIVEN] Purchase Invoice "I3" with amount 400 applied to Payment "P3"
        Amount[6] := -LibraryRandom.RandDec(Round(Amount[4] / 3, 1), 2);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice, Amount[6]);
        ApplyAndPostGenJournalLine(GenJournalLine, GenJournalLine."Applies-to Doc. Type"::Payment, AppliedDocNo);

        // [WHEN] "SR Vendor - Balance to Date" run filtered on "V1" Vendor and saved as excel
        Vendor.SetRecFilter();
        LibraryReportValidation.SetFileName(Vendor."No.");
        REPORT.SaveAsExcel(REPORT::"SR Vendor - Balance to Date", LibraryReportValidation.GetFileName(), Vendor);

        // [THEN] 1st line: "I1".Amount = -900
        // [THEN] 2nd line: "P1".Amount = 200
        // [THEN] 3rd line: "P2".Amount = 300
        // [THEN] 4th line: "I1".Remaining Amount = -400
        // [THEN] 5th line: "P3".Amount = 800
        // [THEN] 6st line: "I2".Amount = -300
        // [THEN] 7th line: "I3".Amount = -400
        // [THEN] 8th line: "P3".Remaining Amount = 100
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValue(14, 15, Format(Amount[1]));
        LibraryReportValidation.VerifyCellValue(15, 15, Format(Amount[2]));
        LibraryReportValidation.VerifyCellValue(16, 15, Format(Amount[3]));
        LibraryReportValidation.VerifyCellValue(17, 15, Format(Amount[1] + Amount[2] + Amount[3]));
        LibraryReportValidation.VerifyCellValue(18, 15, Format(Amount[4]));
        LibraryReportValidation.VerifyCellValue(19, 15, Format(Amount[5]));
        LibraryReportValidation.VerifyCellValue(20, 15, Format(Amount[6]));
        LibraryReportValidation.VerifyCellValue(21, 15, Format(Amount[4] + Amount[5] + Amount[6]));
    end;

    [Test]
    [HandlerFunctions('VendorBalanceToDateRequestPageHandlerSaveAsExcel')]
    [Scope('OnPrem')]
    procedure PurchaseInvoicesAndAppliedPaymentsOneTransaction()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        Amount: array[6] of Decimal;
        InvoiceNo: array[2] of Code[20];
    begin
        // [FEATURE] [Excel] [Application]
        // [SCENARIO 380055] Vendor with purchase invoices and applied payments when "SR Vendor - Balance to Date" Report is run
        Initialize();

        // [GIVEN] Vendor "V1" with application Method "Apply to Oldest"
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Application Method" := Vendor."Application Method"::"Apply to Oldest";
        Vendor.Modify();

        // [GIVEN] Sales Invoice "I1" with amount 200
        // [GIVEN] Sales Invoice "I2" with amount 300
        // [GIVEN] Payment "P1" with amount -450
        // [GIVEN] Payment "P2" with amount -50
        Amount[1] := -LibraryRandom.RandDecInRange(100, 200, 2); // Invoice 1
        Amount[2] := -LibraryRandom.RandDecInRange(200, 300, 2); // Invoice 2
        Amount[3] := -Round(Amount[1] / 3, 2); // Payment 1
        Amount[4] := -Round(Amount[2] / 3, 2); // Payment 2

        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, Vendor."No.", Amount[1]);
        InvoiceNo[1] := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Payment, Amount[3]);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", InvoiceNo[1]);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice, Amount[2]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        InvoiceNo[2] := GenJournalLine."Document No.";

        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Payment, Amount[4]);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", InvoiceNo[2]);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Report "SR Vendor - Balance to Date" run filtered on "V1" and saved as excel
        Vendor.SetRecFilter();
        LibraryReportValidation.SetFileName(Vendor."No.");
        LibraryVariableStorage.Enqueue(true);
        REPORT.RunModal(REPORT::"SR Vendor - Balance to Date", true, false, Vendor);

        // [THEN] 1st line: "I1".Amount = 200
        // [THEN] 2nd line: "P1". Amount applied to "I1" = -150
        // [THEN] 3rd line: "I1".Remaining Amont = 50
        // [THEN] 4th line: "I2".Amount = 300
        // [THEN] 5th line: "P2". Amount applied to "I2" = -250
        // [THEN] 6th line: "I2".Remaining Amont = 50
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValue(14, 15, Format(Amount[1]));
        LibraryReportValidation.VerifyCellValue(15, 15, Format(Amount[3]));
        LibraryReportValidation.VerifyCellValue(16, 15, Format(Amount[1] + Amount[3]));
        LibraryReportValidation.VerifyCellValue(17, 15, Format(Amount[2]));
        LibraryReportValidation.VerifyCellValue(18, 15, Format(Amount[4]));
        LibraryReportValidation.VerifyCellValue(19, 15, Format(Amount[2] + Amount[4]));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VendorBalanceToDateRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorGroupFilterNewPagePerVendor()
    var
        Vendor: Record Vendor;
        RowValue: Variant;
        VendorPostingGroupCode: Code[20];
    begin
        // [SCENARIO 380482] Two Vendors filtered on "Vendor Posting Group" when "SR Vendor - Balance to Date" Report is run
        Initialize();

        // [GIVEN] Vendor posting group "VPG"
        // [GIVEN] Vendor "V1", "V1"."Vendor Posting Group" = "VPG"
        // [GIVEN] Purchase Invoice "PI1" for vendor "V1"
        // [GIVEN] Vendor "V2", "V2"."Vendor Posting Group" = "VPG"
        // [GIVEN] Purchase Invoice "PI2" for vendor "V2"
        VendorPostingGroupCode := TwoPurchaseInvoicesWithVendorPostingGroup();

        Commit();

        // [WHEN] "SR Vendor - Balance to Date" run filtered on "Vendor Posting Group", print one per page = TRUE
        Vendor.SetFilter("Vendor Posting Group", VendorPostingGroupCode);
        REPORT.Run(REPORT::"SR Vendor - Balance to Date", true, false, Vendor);

        // [THEN] 5 rows are generated
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(5, LibraryReportDataset.RowCount(), StrSubstNo(ReportEndDatasetErr, 5));

        // [THEN] Row[1]."OutputNo" = 1
        LibraryReportDataset.MoveToRow(1);
        LibraryReportDataset.FindCurrentRowValue(OutputNoTagTxt, RowValue);
        Assert.AreEqual(2, RowValue, StrSubstNo(ReportRowsErr, OutputNoTagTxt, 1));

        // [THEN] Row[3]."OutputNo" = 2
        LibraryReportDataset.MoveToRow(3);
        LibraryReportDataset.FindCurrentRowValue(OutputNoTagTxt, RowValue);
        Assert.AreEqual(3, RowValue, StrSubstNo(ReportRowsErr, OutputNoTagTxt, 2));

        // [THEN] Row[5] is the total row
        LibraryReportDataset.GetLastRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(TotalTagTxt, 'Total');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorGroupFilterNewPagePerVendorExcel()
    var
        Vendor: Record Vendor;
        VendorPostingGroupCode: Code[20];
    begin
        // [FEATURE] [Excel]

        // [SCENARIO 380482] Two Vendors filtered on "Vendor Posting Group" when "SR Vendor - Balance to Date" Report is saved as excel
        Initialize();

        // [GIVEN] Vendor posting group "VPG"
        // [GIVEN] Vendor "V1", "V1"."Vendor Posting Group" = "VPG"
        // [GIVEN] Purchase Invoice "PI1" for vendor "V1"
        // [GIVEN] Vendor "V2", "V2"."Vendor Posting Group" = "VPG"
        // [GIVEN] Purchase Invoice "PI2" for vendor "V2"
        VendorPostingGroupCode := TwoPurchaseInvoicesWithVendorPostingGroup();

        Commit();

        // [WHEN] "SR Vendor - Balance to Date" run filtered on "Vendor Posting Group" and saved as excel file
        Vendor.Init();
        Vendor.SetFilter("Vendor Posting Group", VendorPostingGroupCode);
        LibraryReportValidation.SetFileName(VendorPostingGroupCode);
        REPORT.SaveAsExcel(REPORT::"SR Vendor - Balance to Date", LibraryReportValidation.GetFileName(), Vendor);

        // [THEN] 3 excel worksheets are generated
        LibraryReportValidation.OpenExcelFile();
        Assert.AreEqual(3, LibraryReportValidation.CountWorksheets(), CountOfSheetsErr);
    end;

    [Test]
    [HandlerFunctions('VendorBalanceToDateRequestPageHandlerSaveAsExcel')]
    [Scope('OnPrem')]
    procedure VerifyReportTotalsPositionWithoutNewPagePerVendor()
    var
        Vendor: Record Vendor;
        Amount: array[3] of Decimal;
    begin
        // [SCENARIO 251982] Report Totals are not moved to the new page if NewPagePerVendor = FALSE.
        Initialize();

        // [GIVEN] One Purchase Invoice with Payments for Vendor. One Invoice will occupy one line in the Report and will not exceed one page.
        CreatePurchaseInvoiceWithAppliedPayments(Vendor, Amount);
        Commit();

        // [WHEN] "SR Vendor - Balance to Date" run for Vendor with NewPagePerVendor = FALSE.
        LibraryReportValidation.SetFileName(Vendor."No.");
        Vendor.SetFilter("No.", Vendor."No.");
        LibraryVariableStorage.Enqueue(false);

        REPORT.Run(REPORT::"SR Vendor - Balance to Date", true, false, Vendor);

        // [THEN] Report contains 1 page, because Totals part is situated on the same page with Vendor.
        LibraryReportValidation.OpenExcelFile();
        Assert.AreEqual(1, LibraryReportValidation.CountWorksheets(), CountOfPagesWithTotalsErr);

        // Tear Down.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VendorBalanceToDateRequestPageHandlerSaveAsExcel')]
    [Scope('OnPrem')]
    procedure VerifyReportTotalsPositionWithNewPagePerVendor()
    var
        Vendor: Record Vendor;
        Amount: array[3] of Decimal;
    begin
        // [SCENARIO 251982] Report Totals are moved to the new page if NewPagePerVendor = TRUE.
        Initialize();

        // [GIVEN] One Purchase Invoice with Payments for Vendor. One Invoice will occupy one line in the Report and will not exceed one page.
        CreatePurchaseInvoiceWithAppliedPayments(Vendor, Amount);
        Commit();

        // [WHEN] "SR Vendor - Balance to Date" run for Vendor with NewPagePerVendor = TRUE.
        LibraryReportValidation.SetFileName(Vendor."No.");
        Vendor.SetFilter("No.", Vendor."No.");
        LibraryVariableStorage.Enqueue(true);

        REPORT.Run(REPORT::"SR Vendor - Balance to Date", true, false, Vendor);

        // [THEN] Report contains 2 pages, one for Vendor and one for Totals.
        LibraryReportValidation.OpenExcelFile();
        Assert.AreEqual(2, LibraryReportValidation.CountWorksheets(), CountOfPagesWithTotalsErr);

        // Tear Down.
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test Vendor Balance to Date");
        Clear(LibraryReportValidation);
        LibraryReportDataset.Reset();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
    end;

    local procedure CreatePurchaseInvoiceWithAppliedPayments(var Vendor: Record Vendor; var Amount: array[3] of Decimal)
    var
        AppliesToGenJournalLine: Record "Gen. Journal Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        PostPurchaseDocument(
          AppliesToGenJournalLine, Vendor, AppliesToGenJournalLine."Document Type"::Invoice,
          -LibraryRandom.RandDec(1000, 2), '', WorkDate());
        Amount[1] := AppliesToGenJournalLine.Amount;
        PostAppliedPurchaseDocument(
          GenJournalLine, AppliesToGenJournalLine, GenJournalLine."Document Type"::Payment,
          LibraryRandom.RandDecInDecimalRange(1, AppliesToGenJournalLine."Amount (LCY)" / 3, 2));
        Amount[2] := GenJournalLine.Amount;
        PostAppliedPurchaseDocument(
          GenJournalLine, AppliesToGenJournalLine, GenJournalLine."Document Type"::Payment,
          LibraryRandom.RandDecInDecimalRange(1, AppliesToGenJournalLine."Amount (LCY)" / 3, 2));
        Amount[3] := GenJournalLine.Amount;
    end;

    local procedure TwoPurchaseInvoicesWithVendorPostingGroup() VendorPostingGroupCode: Code[20]
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup);
        VendorPostingGroupCode := VendorPostingGroup.Code;
        PostPurchaseInvoiceWithVendorPostingGroup(VendorPostingGroupCode);
        PostPurchaseInvoiceWithVendorPostingGroup(VendorPostingGroupCode);
    end;

    local procedure PostPurchaseInvoiceWithVendorPostingGroup(VendorPostingGroupCode: Code[20])
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Vendor Posting Group", VendorPostingGroupCode);
        Vendor.Modify();
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, Vendor."No.", -LibraryRandom.RandDec(1000, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", DocumentType,
          GenJournalLine."Account Type", GenJournalLine."Account No.",
          GenJournalLine."Bal. Account Type", GenJournalLine."Bal. Account No.", Amount);
        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine.Modify(true);
    end;

    local procedure ApplyAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; Type: Enum "Gen. Journal Document Type"; AppliedDocNo: Code[20])
    begin
        GenJournalLine.Validate("Applies-to Doc. Type", Type);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliedDocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostPurchaseDocument(var GenJournalLine: Record "Gen. Journal Line"; Vendor: Record Vendor; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal; CurrencyCode: Code[10]; PostingDate: Date)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          DocumentType, GenJournalLine."Account Type"::Vendor, Vendor."No.",
          GenJournalLine."Bal. Account Type"::"G/L Account", GLAccount."No.", Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostAppliedPurchaseDocument(var GenJournalLine: Record "Gen. Journal Line"; AppliedToGenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          DocumentType, GenJournalLine."Account Type"::Vendor, AppliedToGenJournalLine."Account No.",
          GenJournalLine."Bal. Account Type"::"G/L Account", GLAccount."No.", Amount);
        GenJournalLine.Validate("Applies-to Doc. Type", AppliedToGenJournalLine."Document Type");
        GenJournalLine.Validate("Applies-to Doc. No.", AppliedToGenJournalLine."Document No.");
        GenJournalLine.Validate("Currency Code", AppliedToGenJournalLine."Currency Code");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure VerifyTagOnRows(XMLTag: Text)
    begin
        LibraryReportDataset.MoveToRow(1);
        VerifyTagOneRow(XMLTag, 1);
        VerifyTagOneRow(XMLTag, 2);
        Assert.IsFalse(LibraryReportDataset.CurrentRowHasElement(XMLTag), ReportNoRowsErr);
        Assert.IsFalse(LibraryReportDataset.GetNextRow(), StrSubstNo(ReportEndDatasetErr, 3));
    end;

    local procedure VerifyTagOneRow(XMLTag: Text; RowNo: Integer)
    var
        RowValue: Variant;
    begin
        LibraryReportDataset.FindCurrentRowValue(XMLTag, RowValue);
        Assert.AreEqual(RowValue, RowNo, StrSubstNo(ReportRowsErr, XMLTag, RowNo));
        LibraryReportDataset.GetNextRow();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorBalanceToDateRequestPageHandler(var SRVendorBalanceToDateRequestPage: TestRequestPage "SR Vendor - Balance to Date")
    begin
        SRVendorBalanceToDateRequestPage.FixedDay.SetValue(WorkDate());
        SRVendorBalanceToDateRequestPage.PrintOnePerPage.SetValue(true);
        SRVendorBalanceToDateRequestPage.CheckGLPayables.SetValue(true);
        SRVendorBalanceToDateRequestPage.PrintUnappliedEntries.SetValue(true);
        SRVendorBalanceToDateRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorBalanceToDateRequestPageHandlerSaveAsExcel(var SRVendorBalanceToDateRequestPage: TestRequestPage "SR Vendor - Balance to Date")
    begin
        SRVendorBalanceToDateRequestPage.FixedDay.SetValue(WorkDate());
        SRVendorBalanceToDateRequestPage.PrintOnePerPage.SetValue(LibraryVariableStorage.DequeueBoolean());
        SRVendorBalanceToDateRequestPage.CheckGLPayables.SetValue(true);
        SRVendorBalanceToDateRequestPage.PrintUnappliedEntries.SetValue(true);
        SRVendorBalanceToDateRequestPage.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;
}

