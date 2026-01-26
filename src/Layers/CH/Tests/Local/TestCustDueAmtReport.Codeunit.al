codeunit 144027 "Test Cust. Due Amt. Report"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryRandom: Codeunit "Library - Random";
        PeriodLengthErr: Label 'The period length is not defined.';

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test Cust. Due Amt. Report");
        LibraryVariableStorage.Clear();
    end;

    [Test]
    [HandlerFunctions('DueAmtPerPeriodReqPageHandler')]
    [Scope('OnPrem')]
    procedure CustInvoicesBeforeKeyDate()
    var
        Customer: Record Customer;
        "Layout": Option "Columns before Key Date","Columns after Key Date";
        PeriodLength: DateFormula;
        Balance: array[5] of Decimal;
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateCustomer(Customer);
        PostInvoicesAcrossKeyDateIntervals(Customer, '<-2M>', '', Balance);

        // Exercise.
        Evaluate(PeriodLength, '<2M>');
        LibraryVariableStorage.Enqueue(PeriodLength);
        LibraryVariableStorage.Enqueue(Layout::"Columns before Key Date");
        LibraryVariableStorage.Enqueue(false);
        Commit();
        Customer.SetRange("No.", Customer."No.");
        REPORT.Run(REPORT::"SR Cust. Due Amount per Period", true, false, Customer);

        // Verify.
        VerifyReportDataBeforeKeyDate(Customer, Balance);
    end;

    [Test]
    [HandlerFunctions('DueAmtPerPeriodReqPageHandler')]
    [Scope('OnPrem')]
    procedure CustInvoicesAfterKeyDate()
    var
        Customer: Record Customer;
        "Layout": Option "Columns before Key Date","Columns after Key Date";
        PeriodLength: DateFormula;
        Balance: array[5] of Decimal;
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateCustomer(Customer);
        PostInvoicesAcrossKeyDateIntervals(Customer, '<20D>', '', Balance);

        // Exercise.
        Evaluate(PeriodLength, '<20D>');
        LibraryVariableStorage.Enqueue(PeriodLength);
        LibraryVariableStorage.Enqueue(Layout::"Columns after Key Date");
        LibraryVariableStorage.Enqueue(false);
        Commit();
        Customer.SetRange("No.", Customer."No.");
        REPORT.Run(REPORT::"SR Cust. Due Amount per Period", true, false, Customer);

        // Verify.
        VerifyReportDataAfterKeyDate(Customer, Balance);
    end;

    [Test]
    [HandlerFunctions('DueAmtPerPeriodReqPageHandler')]
    [Scope('OnPrem')]
    procedure BlankPeriodLength()
    var
        Customer: Record Customer;
        "Layout": Option "Columns before Key Date","Columns after Key Date";
        Balance: array[5] of Decimal;
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateCustomer(Customer);
        PostInvoicesAcrossKeyDateIntervals(Customer, '<1M>', '', Balance);

        // Exercise.
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue(Layout::"Columns after Key Date");
        LibraryVariableStorage.Enqueue(true);
        Commit();
        Customer.SetRange("No.", Customer."No.");
        asserterror REPORT.Run(REPORT::"SR Cust. Due Amount per Period", true, false, Customer);

        // Verify.
        Assert.ExpectedError(PeriodLengthErr);
    end;

    [Test]
    [HandlerFunctions('DueAmtPerPeriodReqPageHandler')]
    [Scope('OnPrem')]
    procedure CustInvoicesDiffCurrencies()
    var
        Customer: Record Customer;
        "Layout": Option "Columns before Key Date","Columns after Key Date";
        PeriodLength: DateFormula;
        Balance: array[5] of Decimal;
        CurrencyCode: Code[10];
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateCustomer(Customer);
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(),
            LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        PostInvoicesAcrossKeyDateIntervals(Customer, '<1M>', CurrencyCode, Balance);

        // Exercise.
        Evaluate(PeriodLength, '<1M>');
        LibraryVariableStorage.Enqueue(PeriodLength);
        LibraryVariableStorage.Enqueue(Layout::"Columns after Key Date");
        LibraryVariableStorage.Enqueue(false);
        Commit();
        Customer.SetRange("No.", Customer."No.");
        REPORT.Run(REPORT::"SR Cust. Due Amount per Period", true, false, Customer);

        // Verify.
        VerifyReportDataAfterKeyDateFCY(Customer, Balance);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DueAmtPerPeriodReqPageHandler(var SRCustDueAmountPerPeriod: TestRequestPage "SR Cust. Due Amount per Period")
    var
        PeriodLength: Variant;
        "Layout": Variant;
        ShowLCY: Variant;
    begin
        LibraryVariableStorage.Dequeue(PeriodLength);
        LibraryVariableStorage.Dequeue(Layout);
        LibraryVariableStorage.Dequeue(ShowLCY);
        SRCustDueAmountPerPeriod.KeyDate.SetValue(WorkDate());
        SRCustDueAmountPerPeriod.PeriodLength.SetValue(PeriodLength);
        SRCustDueAmountPerPeriod.Layout.SetValue(Layout);
        SRCustDueAmountPerPeriod.ShowAmtInLCY.SetValue(ShowLCY);
        SRCustDueAmountPerPeriod.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure PostSalesInvoiceWithGivenDate(Customer: Record Customer; DueDate: Date; Amount: Decimal; CurrencyCode: Code[10])
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
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.",
          GenJournalLine."Bal. Account Type"::"G/L Account", GLAccount."No.", Amount);
        GenJournalLine.Validate("Due Date", DueDate);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostInvoicesAcrossKeyDateIntervals(Customer: Record Customer; PeriodLength: Text; CurrencyCode: Code[10]; var Balance: array[5] of Decimal)
    var
        DueDate: Date;
        PeriodLengthDateFormula: DateFormula;
        "count": Integer;
    begin
        DueDate := WorkDate();
        Balance[1] := LibraryRandom.RandDec(1000, 2);
        PostSalesInvoiceWithGivenDate(Customer, DueDate, Balance[1], CurrencyCode);

        for count := 1 to 4 do begin
            Evaluate(PeriodLengthDateFormula, PeriodLength);
            DueDate := CalcDate(PeriodLengthDateFormula, DueDate);
            Balance[count + 1] := LibraryRandom.RandDec(1000, 2);
            PostSalesInvoiceWithGivenDate(Customer, DueDate, Balance[count + 1], CurrencyCode);
        end;
    end;

    local procedure VerifyReportDataBeforeKeyDate(Customer: Record Customer; Balance: array[5] of Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Cust', Customer."No.");
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'There should only be one customer line in the report.');
        LibraryReportDataset.GetNextRow();

        Customer.CalcFields(Balance, "Balance (LCY)");
        LibraryReportDataset.AssertCurrentRowValueEquals('CustBalanceDueLCY1', Balance[4] + Balance[5]);
        LibraryReportDataset.AssertCurrentRowValueEquals('CustBalanceDueLCY2', Balance[3]);
        LibraryReportDataset.AssertCurrentRowValueEquals('CustBalanceDueLCY3', Balance[2]);
        LibraryReportDataset.AssertCurrentRowValueEquals('CustBalanceDueLCY4', Balance[1]);
        LibraryReportDataset.AssertCurrentRowValueEquals('CustBalanceDueLCY5', 0);
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalCustBalanceLCY_Integer', Customer."Balance (LCY)");
        LibraryReportDataset.AssertCurrentRowValueEquals('LineTotalCustBalance', Customer.Balance);
    end;

    local procedure VerifyReportDataAfterKeyDate(Customer: Record Customer; Balance: array[5] of Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Cust', Customer."No.");
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'There should only be one customer line in the report.');
        LibraryReportDataset.GetNextRow();

        Customer.CalcFields(Balance, "Balance (LCY)");
        LibraryReportDataset.AssertCurrentRowValueEquals('CustBalanceDueLCY1', 0);
        LibraryReportDataset.AssertCurrentRowValueEquals('CustBalanceDueLCY2', Balance[1]);
        LibraryReportDataset.AssertCurrentRowValueEquals('CustBalanceDueLCY3', Balance[2]);
        LibraryReportDataset.AssertCurrentRowValueEquals('CustBalanceDueLCY4', Balance[3]);
        LibraryReportDataset.AssertCurrentRowValueEquals('CustBalanceDueLCY5', Balance[4] + Balance[5]);
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalCustBalanceLCY_Integer', Customer."Balance (LCY)");
        LibraryReportDataset.AssertCurrentRowValueEquals('LineTotalCustBalance', Customer.Balance);
    end;

    local procedure VerifyReportDataAfterKeyDateFCY(Customer: Record Customer; Balance: array[5] of Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Cust', Customer."No.");
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'There should only be one customer line in the report.');
        LibraryReportDataset.GetNextRow();

        Customer.CalcFields(Balance, "Balance (LCY)");
        LibraryReportDataset.AssertCurrentRowValueEquals('CustBalanceDue1', 0);
        LibraryReportDataset.AssertCurrentRowValueEquals('CustBalanceDue2', Balance[1]);
        LibraryReportDataset.AssertCurrentRowValueEquals('CustBalanceDue3', Balance[2]);
        LibraryReportDataset.AssertCurrentRowValueEquals('CustBalanceDue4', Balance[3]);
        LibraryReportDataset.AssertCurrentRowValueEquals('CustBalanceDue5', Balance[4] + Balance[5]);
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalCustBalanceLCY_Integer', Customer."Balance (LCY)");
        LibraryReportDataset.AssertCurrentRowValueEquals('LineTotalCustBalance', Customer.Balance);
    end;
}

