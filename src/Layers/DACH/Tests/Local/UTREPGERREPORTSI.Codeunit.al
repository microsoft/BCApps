codeunit 142070 "UT REP GERREPORTS - I"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        SameValueMsg: Label 'Value must be same.';
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        YearCreditAmountCap: Label 'YearCreditAmount';
        GLAccNoCap: Label 'No_GLAcc';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FormatNoTextZeroValueCheck()
    var
        Check: Report Check;
        NoText: array[2] of Text[80];
    begin
        // Purpose of the test is to validate Method FormatNoText for Report 1401 - Check.
        // Setup.
        Initialize();

        // Exercise: Function FormatNoText with Zero Value and Currency Code as blank.
        Check.FormatNoText(NoText, 0, '');

        // Verify: Verify special character in NoText.
        Assert.AreEqual(NoText[1], '***ZERO*0/100***', SameValueMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FormatNoTextWithoutCurrencyCheck()
    var
        Check: Report Check;
        NoText: array[2] of Text[80];
        Amount: Decimal;
    begin
        // Purpose of the test is to validate Method FormatNoText for Report 1401 - Check.
        // Setup.
        Initialize();
        Amount := LibraryRandom.RandDecInDecimalRange(1, 9, 2);  // Decimal range - 1 to 9.

        // Exercise: Function FormatNoText with Amount Value and Currency Code as blank.
        Check.FormatNoText(NoText, Amount, '');

        // Verify: Verify special character in NoText.
        Assert.AreEqual(NoText[1], '****' + Format(Amount * 100) + '/100***', SameValueMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FormatNoTextWithCurrencyCheck()
    var
        Check: Report Check;
        NoText: array[2] of Text[80];
        CurrencyCode: Code[10];
        Amount: Decimal;
    begin
        // Purpose of the test is to validate Method FormatNoText for Report 1401 - Check.
        // Setup.
        Initialize();
        CurrencyCode := LibraryUTUtility.GetNewCode10();
        Amount := LibraryRandom.RandDecInDecimalRange(1, 9, 2);  // Decimal range - 1 to 9.

        // Exercise: Function FormatNoText with Amount Value and Currency Code.
        Check.FormatNoText(NoText, Amount, CurrencyCode);

        // Verify: Verify special character in NoText.
        Assert.AreEqual(NoText[1], '****' + Format(Amount * 100) + '/100*' + CurrencyCode + '***', SameValueMsg);
    end;

    [Test]
    [HandlerFunctions('GLTotalBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportHeaderTextPeriodGLTotalBalance()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        GLSetup: Record "General Ledger Setup";
    begin
        // Purpose of the test is to validate the OnPreReport trigger of the GL Total Balance Report for Header Text and Period End Balance.
        // Setup.
        Initialize();
        CreateGLAccount(GLEntry, GLAccount."Account Type"::Heading);
        GLSetup.Get();

        // Exercise.
        RunGLTotalBalanceReport(GLEntry."G/L Account No.");

        // Verify: Verify the Header Text, Period End Balance and Account No after running GL Total Balance Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('HeaderText', StrSubstNo('All amounts are in %1', GLSetup."LCY Code"));
        LibraryReportDataset.AssertElementWithValueExists(GLAccNoCap, GLEntry."G/L Account No.");
        LibraryReportDataset.AssertElementWithValueExists('PeriodEndBalance', GLEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('GLTotalBalanceWithoutAccPeriodRequestPagetHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportAccPeriodNotExistGLTotalBalanceError()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
    begin
        // Purpose of the test is to validate the OnPreReport trigger of the GL Total Balance Report for non existing Accounting Period error.
        // Setup.
        Initialize();
        CreateGLAccount(GLEntry, GLAccount."Account Type"::Heading);
        GLAccount.Get(GLEntry."G/L Account No.");
        GLAccount."Date Filter" := SelectStartingDateAccountingPeriod();
        GLAccount.Modify();

        // Exercise.
        asserterror RunGLTotalBalanceReport(GLEntry."G/L Account No.");

        // Verify: Verify the Error Code, Actual error - Accounting Period is not available after running GL Total Balance Report.
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('GLTotalBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordTypePostingNegativeGLTotalBalance()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
    begin
        // Purpose of the test is to validate the OnAfterGetRecord - G/L Account trigger of the GL Total Balance Report for negative Net Change in GL Entry.
        // Setup.
        Initialize();
        CreateGLAccount(GLEntry, GLAccount."Account Type"::Posting);
        GLEntry.Amount := -1;
        GLEntry.Modify();

        // Exercise.
        RunGLTotalBalanceReport(GLEntry."G/L Account No.");

        // Verify: Verify the End Balance, End Balance Type, Account No, Type and Year Credit Amount after running GL Total Balance Report.
        VerifyEndBalanceAndAccountNoType(-GLEntry.Amount, 'Credit', 0, GLEntry."G/L Account No.");  // Zero for Account Type Posting.
        LibraryReportDataset.AssertElementWithValueExists(YearCreditAmountCap, GLEntry."Credit Amount");
    end;

    [Test]
    [HandlerFunctions('GLTotalBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordTypeHeadingNegativeGLTotalBalance()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
    begin
        // Purpose of the test is to validate the OnAfterGetRecord - G/L Account trigger of the GL Total Balance Report for positive Net Change and End Balance Type Debit in GL Entry.
        // Setup.
        Initialize();
        CreateGLAccount(GLEntry, GLAccount."Account Type"::Heading);

        // Exercise.
        RunGLTotalBalanceReport(GLEntry."G/L Account No.");

        // Verify: Verify the End Balance, End Balance Type, Account No, Type and Year Credit Amount after running GL Total Balance Report.
        VerifyEndBalanceAndAccountNoType(GLEntry.Amount, 'Debit', 1, GLEntry."G/L Account No.");  // 1 for Account Type Heading.
        LibraryReportDataset.AssertElementWithValueExists(YearCreditAmountCap, GLEntry."Credit Amount");
    end;

    [Test]
    [HandlerFunctions('GLTotalBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordTypeBeginTotalPositiveGLTotalBalance()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
    begin
        // Purpose of the test is to validate the OnAfterGetRecord - G/L Account trigger of the GL Total Balance Report for positive Net Change in GL Entry.
        // Setup.
        Initialize();
        CreateGLAccount(GLEntry, GLAccount."Account Type"::"Begin-Total");
        GLEntry."Debit Amount" := 1;
        GLEntry.Modify();

        // Exercise.
        RunGLTotalBalanceReport(GLEntry."G/L Account No.");

        // Verify: Verify the End Balance, End Balance Type, Account No, Type and Year Debit Amount after running GL Total Balance Report.
        VerifyEndBalanceAndAccountNoType(GLEntry.Amount, 'Debit', 3, GLEntry."G/L Account No.");  // 3 for Account Type Begin-Total.
        LibraryReportDataset.AssertElementWithValueExists('YearDebitAmount', GLEntry."Debit Amount");
    end;

    [Test]
    [HandlerFunctions('VendorDetailedAgingRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OverDueMonthsLedgerEntryVendorDetailedAging()
    var
        VendorLedgerEntryDueDate: Date;
        OverDueMonths: Integer;
    begin
        // Purpose of the test is to validate VendorLedgerEntry - OnAfterGetRecord of Report ID - 11006 Vendor Detailed Aging.

        // Setup: Run report Vendor Detailed Aging for OverDueMonths for Vendor Ledger Entry, whose month in Due Date is less than Posting Date month and day are same in both dates.
        Initialize();
        VendorLedgerEntryDueDate := CalcDate('<' + Format(-LibraryRandom.RandInt(5)) + 'M>', WorkDate());  // Vendor Ledger Entry, month in Due Date is less than Posting Date month and day are same in both dates.
        OverDueMonths := (Date2DMY(WorkDate(), 3) - Date2DMY(VendorLedgerEntryDueDate, 3)) * 12 + Date2DMY(WorkDate(), 2) - Date2DMY(VendorLedgerEntryDueDate, 2);  // Calculation based on function OverDueMonths of Report Vendor Detailed Aging.
        OverDueMonthsVendorLedgerEntry(VendorLedgerEntryDueDate, OverDueMonths);
    end;

    [Test]
    [HandlerFunctions('VendorDetailedAgingRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OverDueMonthsLedEntryForDaysVendDetailedAging()
    var
        OverDueMonths: Integer;
        VendorLedgerEntryDueDate: Date;
    begin
        // Purpose of the test is to validate VendorLedgerEntry - OnAfterGetRecord of Report ID - 11006 Vendor Detailed Aging.

        // Setup: Run report Vendor Detailed Aging for OverDueMonths for Vendor Ledger Entry, whose day in Due Date is greater than day in Posting Date.
        Initialize();
        VendorLedgerEntryDueDate := CalcDate('<' + Format(-LibraryRandom.RandInt(5)) + 'Y>', CalcDate('<+CM>', WorkDate())); // Vendor Ledger Entry day in Due Date is greater than day in Posting Date.
        OverDueMonths := (Date2DMY(WorkDate(), 3) - Date2DMY(VendorLedgerEntryDueDate, 3)) * 12 + Date2DMY(WorkDate(), 2) - Date2DMY(VendorLedgerEntryDueDate, 2);  // Calculation based on function OverDueMonths of Report Vendor Detailed Aging.
        OverDueMonthsVendorLedgerEntry(VendorLedgerEntryDueDate, OverDueMonths - 1);
    end;

    local procedure OverDueMonthsVendorLedgerEntry(DueDate: Date; OverDueMonths: Integer)
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        CreateVendorLedgerEntry(VendorLedgerEntry, DueDate);
        LibraryVariableStorage.Enqueue(VendorLedgerEntry."Vendor No.");  // Required inside VendorDetailedAgingRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Vendor Detailed Aging");  // Opens VendorDetailedAgingRequestPageHandler.

        // Verify: Verify VendFilter and OverDueMonths on Report Vendor Detailed Aging in VendorDetailedAgingRequestPageHandler.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('VendFilter', StrSubstNo('%1: %2', Vendor.FieldCaption("No."), VendorLedgerEntry."Vendor No."));
        LibraryReportDataset.AssertElementWithValueExists('OverDueMonths', OverDueMonths);
    end;

    [Test]
    [HandlerFunctions('VendorDetailedAgingEndDateRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure EndingDateVendorDetailedAging()
    begin
        // Purpose of the test is to validate EndingDate of Report ID - 11006 Vendor Detailed Aging.
        // Setup.
        Initialize();

        // Exercise & verify: Run Report Vendor Detailed Aging and verify default Ending Date on Report Vendor Detailed Aging is WORKDATE in VendorDetailedAgingEndDateRequestPageHandler.
        REPORT.Run(REPORT::"Vendor Detailed Aging");  // Opens VendorDetailedAgingEndDateRequestPageHandler.
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure SelectStartingDateAccountingPeriod() StartingDate: Date
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        AccountingPeriod.FindLast();

        // Enqueue value for use in GLTotalBalanceWithoutAccPeriodRequestPagetHandler.
        StartingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', AccountingPeriod."Starting Date");
        LibraryVariableStorage.Enqueue(StartingDate);  // Starting Date greater than the existing Accounting Period Starting Date.
    end;

    local procedure CreateGLAccount(var GLEntry: Record "G/L Entry"; AccountType: Enum "G/L Account Type")
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount."No." := LibraryUTUtility.GetNewCode();
        GLAccount."Account Type" := AccountType;
        GLAccount.Insert();
        CreateGLEntry(GLEntry, GLAccount."No.");  // GL Entry required for the posted entries for G/L Account.
    end;

    local procedure CreateGLEntry(var GLEntry: Record "G/L Entry"; GLAccountNo: Code[20])
    var
        GLEntry2: Record "G/L Entry";
    begin
        GLEntry2.FindLast();
        GLEntry."Entry No." := GLEntry2."Entry No." + 1;
        GLEntry."G/L Account No." := GLAccountNo;
        GLEntry."Posting Date" := WorkDate();
        GLEntry.Amount := 1;
        GLEntry."Credit Amount" := 1;
        GLEntry.Insert();
    end;

    local procedure CreateVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DueDate: Date)
    var
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor.Insert();

        VendorLedgerEntry2.FindLast();
        VendorLedgerEntry."Entry No." := VendorLedgerEntry2."Entry No." + 1;
        VendorLedgerEntry."Due Date" := DueDate;
        VendorLedgerEntry."Vendor No." := Vendor."No.";
        VendorLedgerEntry."Posting Date" := WorkDate();
        VendorLedgerEntry.Open := true;
        VendorLedgerEntry.Insert();
    end;

    local procedure RunGLTotalBalanceReport(No: Code[20])
    var
        GLAccount: Record "G/L Account";
        GLTotalBalance: Report "G/L Total-Balance";
    begin
        GLAccount.SetRange("No.", No);
        GLTotalBalance.SetTableView(GLAccount);
        GLTotalBalance.Run();  // Invokes GLTotalBalanceWithoutAccPeriodRequestPagetHandler and GLTotalBalanceRequestPageHandler.
    end;

    local procedure VerifyEndBalanceAndAccountNoType(EndBalance: Variant; EndBalanceType: Variant; AccountType: Variant; NoGLAcc: Code[20])
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('EndBalance', EndBalance);
        LibraryReportDataset.AssertElementWithValueExists('EndBalanceType', EndBalanceType);
        LibraryReportDataset.AssertElementWithValueExists(GLAccNoCap, NoGLAcc);
        LibraryReportDataset.AssertElementWithValueExists('AccountTypeIntB', AccountType);
    end;

    local procedure UpdateGLTotalBalanceReportRequestPage(GLTotalBalance: TestRequestPage "G/L Total-Balance"; StartingDate: Date)
    begin
        GLTotalBalance."G/L Account".SetFilter("Date Filter", Format(StartingDate));
        GLTotalBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLTotalBalanceWithoutAccPeriodRequestPagetHandler(var GLTotalBalance: TestRequestPage "G/L Total-Balance")
    var
        StartingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartingDate);
        UpdateGLTotalBalanceReportRequestPage(GLTotalBalance, StartingDate);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLTotalBalanceRequestPageHandler(var GLTotalBalance: TestRequestPage "G/L Total-Balance")
    begin
        UpdateGLTotalBalanceReportRequestPage(GLTotalBalance, WorkDate());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorDetailedAgingRequestPageHandler(var VendorDetailedAging: TestRequestPage "Vendor Detailed Aging")
    var
        VendorNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendorNo);
        VendorDetailedAging.Vendor.SetFilter("No.", VendorNo);
        VendorDetailedAging.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorDetailedAgingEndDateRequestPageHandler(var VendorDetailedAging: TestRequestPage "Vendor Detailed Aging")
    begin
        VendorDetailedAging.EndingDate.AssertEquals(WorkDate());
    end;
}

