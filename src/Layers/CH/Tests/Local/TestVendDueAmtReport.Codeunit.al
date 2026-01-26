codeunit 144028 "Test Vend. Due Amt. Report"
{
    // 1 ~ 3. Test basic functions for SR Ven. Due Amount per Period Report.
    // 4. Verify Total Amount info for report SR Ven. Due Amount per Period with 'Show Amounts In LCY' = TRUE.
    // 5. Verify Total Amount info for report SR Ven. Due Amount per Period with 'Show Amounts In LCY' = FALSE.
    // 
    // Cover Test Cases for CH
    // ---------------------------------------------------------------------------
    // Test Function Name                                                   TFS ID
    // ---------------------------------------------------------------------------
    // VendInvoicesBeforeKeyDate
    // VendInvoicesAfterKeyDate
    // BlankPeriodLength
    // 
    // Cover Test Cases for CH Bug 105331
    // ---------------------------------------------------------------------------
    // Test Function Name                                                   TFS ID
    // ---------------------------------------------------------------------------
    // ReportDueAmtPerPeriodShowAmountsInLCY
    // ReportDueAmtPerPeriodNotShowAmountsInLCY

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryRandom: Codeunit "Library - Random";
        PeriodLengthErr: Label 'The period length is not defined.';
        TotalAmountErr: Label 'Total Amount is incorrect';

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    [Test]
    [HandlerFunctions('DueAmtPerPeriodReqPageHandler')]
    [Scope('OnPrem')]
    procedure VendInvoicesBeforeKeyDate()
    var
        Vendor: Record Vendor;
        "Layout": Option "Columns before Key Date","Columns after Key Date";
        Balance: array[5] of Decimal;
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreateVendor(Vendor);
        PostInvoicesAcrossKeyDateIntervals(Vendor, '<-2M>', Balance, '');

        // Exercise.
        RunReportDueAmtPerPeriod('<2M>', Layout::"Columns before Key Date", false, Vendor."No.");

        // Verify.
        VerifyReportDataBeforeKeyDate(Vendor, Balance);
    end;

    [Test]
    [HandlerFunctions('DueAmtPerPeriodReqPageHandler')]
    [Scope('OnPrem')]
    procedure VendInvoicesAfterKeyDate()
    var
        Vendor: Record Vendor;
        "Layout": Option "Columns before Key Date","Columns after Key Date";
        Balance: array[5] of Decimal;
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreateVendor(Vendor);
        PostInvoicesAcrossKeyDateIntervals(Vendor, '<20D>', Balance, '');

        // Exercise.
        RunReportDueAmtPerPeriod('<20D>', Layout::"Columns after Key Date", false, Vendor."No.");

        // Verify.
        VerifyReportDataAfterKeyDate(Vendor, Balance);
    end;

    [Test]
    [HandlerFunctions('DueAmtPerPeriodReqPageHandler')]
    [Scope('OnPrem')]
    procedure BlankPeriodLength()
    var
        Vendor: Record Vendor;
        "Layout": Option "Columns before Key Date","Columns after Key Date";
        Balance: array[5] of Decimal;
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreateVendor(Vendor);
        PostInvoicesAcrossKeyDateIntervals(Vendor, '<1M>', Balance, '');

        // Exercise.
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue(Layout::"Columns after Key Date");
        LibraryVariableStorage.Enqueue(true);
        Commit();
        Vendor.SetRange("No.", Vendor."No.");
        asserterror REPORT.Run(REPORT::"SR Ven. Due Amount per Period", true, false, Vendor);

        // Verify.
        Assert.ExpectedError(PeriodLengthErr);
    end;

    [Test]
    [HandlerFunctions('DueAmtPerPeriodReqPageHandler')]
    [Scope('OnPrem')]
    procedure ReportDueAmtPerPeriodShowAmountsInLCY()
    begin
        // Verify Total Amount info for report SR Ven. Due Amount per Period with 'Show Amounts In LCY' = TRUE.
        ReportDueAmtPerPeriod(true);
    end;

    [Test]
    [HandlerFunctions('DueAmtPerPeriodReqPageHandler')]
    [Scope('OnPrem')]
    procedure ReportDueAmtPerPeriodNotShowAmountsInLCY()
    begin
        // Verify Total Amount info for report SR Ven. Due Amount per Period with 'Show Amounts In LCY' = FALSE.
        ReportDueAmtPerPeriod(false);
    end;

    local procedure ReportDueAmtPerPeriod(ShowAmountsInLCY: Boolean)
    var
        Vendor: Record Vendor;
        "Layout": Option "Columns before Key Date","Columns after Key Date";
        Balance: array[5] of Decimal;
        DueDate: array[5] of Date;
    begin
        // Setup: Create and post multiple Invoices for Vendor with different Currency Code.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        PostMultipleInvoicesAcrossKeyDateIntervals(Vendor, '<2M>', Balance, DueDate, '');
        PostMultipleInvoicesAcrossKeyDateIntervals(
          Vendor, '<2M>', Balance, DueDate,
          LibraryERM.CreateCurrencyWithExchangeRate(
            CalcDate('<-1Y>', WorkDate()), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2)));

        // Exercise: Run report SR Ven. Due Amount per Period.
        RunReportDueAmtPerPeriod('<2M>', Layout::"Columns after Key Date", ShowAmountsInLCY, Vendor."No.");

        // Verify: Verify Total Amount in report.
        VerifyPurchaseDocumentReportData(Vendor."No.", DueDate, ShowAmountsInLCY);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DueAmtPerPeriodReqPageHandler(var SRVenDueAmountPerPeriod: TestRequestPage "SR Ven. Due Amount per Period")
    var
        PeriodLength: Variant;
        "Layout": Variant;
        ShowLCY: Variant;
    begin
        LibraryVariableStorage.Dequeue(PeriodLength);
        LibraryVariableStorage.Dequeue(Layout);
        LibraryVariableStorage.Dequeue(ShowLCY);
        SRVenDueAmountPerPeriod."Key Date".SetValue(WorkDate());
        SRVenDueAmountPerPeriod."Period Length".SetValue(PeriodLength);
        SRVenDueAmountPerPeriod.Layout.SetValue(Layout);
        SRVenDueAmountPerPeriod.ShowAmtInLCY.SetValue(ShowLCY);
        SRVenDueAmountPerPeriod.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure PostPurchaseInvoiceWithGivenDate(Vendor: Record Vendor; DueDate: Date; Amount: Decimal; CurrencyCode: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, Vendor."No.",
          GenJournalLine."Bal. Account Type"::"G/L Account", GLAccount."No.", -Amount);
        GenJournalLine.Validate("Posting Date", DueDate);
        GenJournalLine.Validate("Due Date", DueDate);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostInvoicesAcrossKeyDateIntervals(Vendor: Record Vendor; PeriodLength: Text; var Balance: array[5] of Decimal; CurrencyCode: Code[10])
    var
        DueDate: Date;
        PeriodLengthDateFormula: DateFormula;
        "count": Integer;
    begin
        DueDate := WorkDate();
        Balance[1] := LibraryRandom.RandDec(1000, 2);
        PostPurchaseInvoiceWithGivenDate(Vendor, DueDate, Balance[1], CurrencyCode);

        for count := 1 to 4 do begin
            Evaluate(PeriodLengthDateFormula, PeriodLength);
            DueDate := CalcDate(PeriodLengthDateFormula, DueDate);
            Balance[count + 1] := LibraryRandom.RandDec(1000, 2);
            PostPurchaseInvoiceWithGivenDate(Vendor, DueDate, Balance[count + 1], CurrencyCode);
        end;
    end;

    local procedure PostMultipleInvoicesAcrossKeyDateIntervals(Vendor: Record Vendor; PeriodLength: Text; var Balance: array[5] of Decimal; var DueDate: array[5] of Date; CurrencyCode: Code[10])
    var
        "count": Integer;
        PostingDate: Date;
        PeriodLengthDateFormula: DateFormula;
    begin
        Evaluate(PeriodLengthDateFormula, PeriodLength);
        PostingDate := CalcDate('<-2M>', WorkDate());
        for count := 1 to ArrayLen(Balance) do begin
            DueDate[count] := PostingDate;
            Balance[count] := LibraryRandom.RandDec(1000, 2);
            PostPurchaseInvoiceWithGivenDate(Vendor, DueDate[count], Balance[count], CurrencyCode);
            PostingDate := CalcDate(PeriodLengthDateFormula, PostingDate);
        end;
    end;

    local procedure RunReportDueAmtPerPeriod(PeriodLength: Text; "Layout": Option; ShowAmountInLCY: Boolean; VendorNo: Code[20])
    var
        Vendor: Record Vendor;
        PeriodLengthDateFormula: DateFormula;
    begin
        Evaluate(PeriodLengthDateFormula, PeriodLength);
        LibraryVariableStorage.Enqueue(PeriodLengthDateFormula);
        LibraryVariableStorage.Enqueue(Layout);
        LibraryVariableStorage.Enqueue(ShowAmountInLCY);
        Commit();
        Vendor.SetRange("No.", VendorNo);
        REPORT.Run(REPORT::"SR Ven. Due Amount per Period", true, false, Vendor);
    end;

    local procedure VerifyReportDataBeforeKeyDate(Vendor: Record Vendor; Balance: array[5] of Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Vend', Vendor."No.");
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'There should only be one vendor line in the report.');
        LibraryReportDataset.GetNextRow();

        Vendor.CalcFields(Balance, "Balance (LCY)");
        LibraryReportDataset.AssertCurrentRowValueEquals('VendBalanceDueLCY1', Balance[4] + Balance[5]);
        LibraryReportDataset.AssertCurrentRowValueEquals('VendBalanceDueLCY2', Balance[3]);
        LibraryReportDataset.AssertCurrentRowValueEquals('VendBalanceDueLCY3', Balance[2]);
        LibraryReportDataset.AssertCurrentRowValueEquals('VendBalanceDueLCY4', Balance[1]);
        LibraryReportDataset.AssertCurrentRowValueEquals('VendBalanceDueLCY5', 0);
        LibraryReportDataset.AssertCurrentRowValueEquals('LineTotalVendorBalance', Vendor."Balance (LCY)");
        LibraryReportDataset.AssertCurrentRowValueEquals('LineTotalVendorBalance_Integer', Vendor.Balance);
    end;

    local procedure VerifyReportDataAfterKeyDate(Vendor: Record Vendor; Balance: array[5] of Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Vend', Vendor."No.");
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'There should only be one vendor line in the report.');
        LibraryReportDataset.GetNextRow();

        Vendor.CalcFields(Balance, "Balance (LCY)");
        LibraryReportDataset.AssertCurrentRowValueEquals('VendBalanceDueLCY1', 0);
        LibraryReportDataset.AssertCurrentRowValueEquals('VendBalanceDueLCY2', Balance[1]);
        LibraryReportDataset.AssertCurrentRowValueEquals('VendBalanceDueLCY3', Balance[2]);
        LibraryReportDataset.AssertCurrentRowValueEquals('VendBalanceDueLCY4', Balance[3]);
        LibraryReportDataset.AssertCurrentRowValueEquals('VendBalanceDueLCY5', Balance[4] + Balance[5]);
        LibraryReportDataset.AssertCurrentRowValueEquals('LineTotalVendorBalance', Vendor."Balance (LCY)");
        LibraryReportDataset.AssertCurrentRowValueEquals('LineTotalVendorBalance_Integer', Vendor.Balance);
    end;

    local procedure VerifyPurchaseDocumentReportData(VendorNo: Code[20]; PostingDate: array[5] of Date; ShowAmountsInLCY: Boolean)
    var
        DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        TotalAmountLCY: array[5] of Decimal;
        AllTotalAmountLCY: Decimal;
        "Count": Integer;
    begin
        LibraryReportDataset.LoadDataSetFile();

        AllTotalAmountLCY := 0;
        for Count := 1 to ArrayLen(TotalAmountLCY) do begin
            DetailedVendLedgEntry.SetRange("Vendor No.", VendorNo);
            DetailedVendLedgEntry.SetRange("Posting Date", PostingDate[Count]);

            TotalAmountLCY[Count] := 0;
            DetailedVendLedgEntry.FindSet();
            repeat
                TotalAmountLCY[Count] += DetailedVendLedgEntry."Amount (LCY)";
            until DetailedVendLedgEntry.Next() = 0;

            // Verify Total Amount for each column.
            if ShowAmountsInLCY then
                Assert.AreEqual(LibraryReportDataset.Sum('VendBalanceDue' + Format(Count)), Abs(TotalAmountLCY[Count]), TotalAmountErr)
            else
                Assert.AreEqual(LibraryReportDataset.Sum('VendBalanceDueLCY' + Format(Count)), Abs(TotalAmountLCY[Count]), TotalAmountErr);

            AllTotalAmountLCY += Abs(TotalAmountLCY[Count]);
        end;

        // Verify Total LCY Amount for all Balances withou Show Amounts In LCY.
        if not ShowAmountsInLCY then
            Assert.AreEqual(LibraryReportDataset.Sum('TotalVendorBalanceLCY_Integer'), AllTotalAmountLCY, TotalAmountErr);
    end;
}

