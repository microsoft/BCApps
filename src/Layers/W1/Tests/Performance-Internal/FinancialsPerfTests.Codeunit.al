codeunit 139093 "Financials Perf Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        TestsBuffer := 5;
        LibraryPerformanceProfiler.SetProfilerIdentification('139093 "Financials Perf Tests');
    end;

    var
        LibraryPerformanceProfiler: Codeunit "Library - Performance Profiler";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        TraceDumpFilePath: text;
        TestsBuffer: Integer;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('BalanceSheetRequestPageHandler')]
    procedure TestBalanceSheet()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
    begin
        LibraryPerformanceProfiler.StartProfiler(TRUE);
        Report.Run(Report::"Balance Sheet");
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
          PerfProfilerEventsTest, 'TestBalanceSheet',
          PerfProfilerEventsTest."Object Type"::Report, REPORT::"Balance Sheet", TRUE);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('TrialBalanceRequestPageHandler')]
    procedure TestTrialBalance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
    begin
        LibraryPerformanceProfiler.StartProfiler(TRUE);

        report.Run(report::"Trial Balance");

        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestTrialBalance',
            PerfProfilerEventsTest."Object Type"::Report, REPORT::"Trial Balance", TRUE);
        //VerifyExpectedResults(PerfProfilerEventsTest, 7, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('DetailedTrialBalancePageHandler')]
    procedure TestDetailedTrailBalance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
    begin
        LibraryPerformanceProfiler.StartProfiler(TRUE);

        REPORT.RUN(REPORT::"Detail Trial Balance");

        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestDetailTrialBalance',
            PerfProfilerEventsTest."Object Type"::Report, REPORT::"Detail Trial Balance", TRUE);
        //VerifyExpectedResults(PerfProfilerEventsTest, 7, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('BalanceSheetRequestPageHandler')]
    procedure TestCashFlowStatement()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
    begin
        LibraryPerformanceProfiler.StartProfiler(TRUE);

        REPORT.RUN(REPORT::"Statement of Cashflows");

        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestCashFlowStatement',
            PerfProfilerEventsTest."Object Type"::Report, REPORT::"Account Schedule", TRUE);
        //VerifyExpectedResults(PerfProfilerEventsTest, 7, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('BalanceSheetRequestPageHandler')]
    procedure TestIncomeStatement()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
    begin
        LibraryPerformanceProfiler.StartProfiler(TRUE);

        REPORT.RUN(REPORT::"Income Statement");

        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestIncomeStatement',
            PerfProfilerEventsTest."Object Type"::Report, REPORT::"Account Schedule", TRUE);
        //VerifyExpectedResults(PerfProfilerEventsTest, 7, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('BalanceSheetRequestPageHandler')]
    procedure TestRetainedEarningsStatement()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
    begin
        LibraryPerformanceProfiler.StartProfiler(TRUE);

        REPORT.RUN(REPORT::"Retained Earnings Statement");

        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestRetainedStatement',
            PerfProfilerEventsTest."Object Type"::Report, REPORT::"Account Schedule", TRUE);
        //VerifyExpectedResults(PerfProfilerEventsTest, 7, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNewGLAccountCreationPerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        GLAccountCard: TestPage "G/L Account Card";
        GLAccount: Record "G/L Account";
        AllowedThreshold: Integer;
    begin
        AllowedThreshold := 150;
        AllowedThreshold := AllowedThreshold + ROUND((AllowedThreshold * TestsBuffer) / 100, 1, '=');
        LibraryNotificationMgt.DisableAllNotifications();

        LibraryPerformanceProfiler.StartProfiler(true);
        GLAccountCard.OpenNew();
        GLAccountCard."No.".SetValue(LibraryUtility.GenerateRandomCode20(GLAccount.FieldNo("No."), DATABASE::"G/L Account"));
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestNewGLAccountCreationPerformance',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"G/L Account Card", true);
        //VerifyExpectedResults(PerfProfilerEventsTest, AllowedThreshold, 35);

        GLAccountCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenGLAccountListPerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        GLAccount: Record "G/L Account";
        GLAccountList: TestPage "G/L Account List";
        AllowedThreshold: Integer;
    begin
        AllowedThreshold := 175;
        AllowedThreshold := AllowedThreshold + ROUND((AllowedThreshold * TestsBuffer) / 100, 1, '=');
        if GLAccount.IsEmpty() then
            exit;
        LibraryPerformanceProfiler.StartProfiler(true);
        GLAccountList.OpenView();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestOpenGLAccountListPerformance',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"G/L Account List", true);
        GLAccountList.Close();
        //VerifyExpectedResults(PerfProfilerEventsTest, AllowedThreshold, 35);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenGLAccountCardPerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        GLAccountCard: TestPage "G/L Account Card";
        AllowedThreshold: Integer;
    begin
        AllowedThreshold := 132;
        AllowedThreshold := AllowedThreshold + ROUND((AllowedThreshold * TestsBuffer) / 100, 1, '=');
        LibraryNotificationMgt.DisableAllNotifications();
        LibraryPerformanceProfiler.StartProfiler(true);
        GLAccountCard.OpenView();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestOpenGLAccountCardPerformance',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"G/L Account Card", true);
        GLAccountCard.Close();
        //VerifyExpectedResults(PerfProfilerEventsTest, AllowedThreshold, 35);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNewBankAccountCreationPerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        BankAccountCard: TestPage "Bank Account Card";
        BankAccount: Record "Bank Account";
        AllowedThreshold: Integer;
    begin
        AllowedThreshold := 150;
        AllowedThreshold := AllowedThreshold + ROUND((AllowedThreshold * TestsBuffer) / 100, 1, '=');
        LibraryNotificationMgt.DisableAllNotifications();

        LibraryPerformanceProfiler.StartProfiler(true);
        BankAccountCard.OpenNew();
        BankAccountCard."No.".SetValue(LibraryUtility.GenerateRandomCode20(BankAccount.FieldNo("No."), DATABASE::"Bank Account"));
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestNewBankAccountCreationPerformance',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"Bank Account Card", true);
        //VerifyExpectedResults(PerfProfilerEventsTest, AllowedThreshold, 35);

        BankAccountCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenBankAccountListPerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        BankAccount: Record "Bank Account";
        BankAccountList: TestPage "Bank Account List";
        AllowedThreshold: Integer;
    begin
        AllowedThreshold := 175;
        AllowedThreshold := AllowedThreshold + ROUND((AllowedThreshold * TestsBuffer) / 100, 1, '=');
        if BankAccount.IsEmpty() then
            exit;
        LibraryPerformanceProfiler.StartProfiler(true);
        BankAccountList.OpenView();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestOpenBankAccountListPerformance',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"Bank Account List", true);
        BankAccountList.Close();
        //VerifyExpectedResults(PerfProfilerEventsTest, AllowedThreshold, 35);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenBankAccountCardPerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        BankAccountCard: TestPage "Bank Account Card";
        AllowedThreshold: Integer;
    begin
        AllowedThreshold := 132;
        AllowedThreshold := AllowedThreshold + ROUND((AllowedThreshold * TestsBuffer) / 100, 1, '=');
        LibraryNotificationMgt.DisableAllNotifications();
        LibraryPerformanceProfiler.StartProfiler(true);
        BankAccountCard.OpenView();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestOpenBankAccountCardPerformance',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"Bank Account Card", true);
        BankAccountCard.Close();
        //VerifyExpectedResults(PerfProfilerEventsTest, AllowedThreshold, 35);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('AccountSchedulePageHandler')]
    procedure TestOpenAccountScheduleNamesListPerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        AccountScheduleNamesList: TestPage "Account Schedule Names";
        AccountScheduleName: Record "Acc. Schedule Name";
        AllowedThreshold: Integer;
    begin
        AllowedThreshold := 175;
        AllowedThreshold := AllowedThreshold + ROUND((AllowedThreshold * TestsBuffer) / 100, 1, '=');
        if AccountScheduleName.IsEmpty() then
            exit;
        LibraryPerformanceProfiler.StartProfiler(true);
        AccountScheduleNamesList.OpenEdit();
        AccountScheduleNamesList.EditAccountSchedule.Invoke();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestOpenAccountScheduleNamesListPerformance',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"Account Schedule Names", true);
        AccountScheduleNamesList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostGeneralJournalLinesWithAccountTypeAsCustomer()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        AllowedThreshold: Integer;
    begin
        AllowedThreshold := 375;
        AllowedThreshold := AllowedThreshold + ROUND((AllowedThreshold * TestsBuffer) / 100, 1, '=');
        CreateJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());
        LibrarySales.CreateCustomer(Customer);
        LibraryPerformanceProfiler.StartProfiler(true);
        CreateAndPostGeneralJourLinesForBatch(GenJournalBatch, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.", LibraryRandom.RandDec(100, 2), 10);
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestPostGeneralJournalLinesWithAccountTypeAsCustomer',
            PerfProfilerEventsTest."Object Type"::Codeunit, CODEUNIT::"Gen. Jnl.-Post Batch", true);
        //VerifyExpectedResults(PerfProfilerEventsTest, AllowedThreshold, 35);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostGeneralJournalLinesWithAccountTypeAsVendor()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        GenJournalBatch: Record "Gen. Journal Batch";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        AllowedThreshold: Integer;
    begin
        AllowedThreshold := 375;
        AllowedThreshold := AllowedThreshold + ROUND((AllowedThreshold * TestsBuffer) / 100, 1, '=');
        CreateJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPerformanceProfiler.StartProfiler(true);
        CreateAndPostGeneralJourLinesForBatch(GenJournalBatch, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, Vendor."No.", -LibraryRandom.RandDec(100, 2), 10);
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestPostGeneralJournalLinesWithAccountTypeAsVendor',
            PerfProfilerEventsTest."Object Type"::Codeunit, CODEUNIT::"Gen. Jnl.-Post Batch", true);
        //VerifyExpectedResults(PerfProfilerEventsTest, AllowedThreshold, 35);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostGeneralJournalLinesWithAccountTypeAsGLAccount()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        AllowedThreshold: Integer;
    begin
        AllowedThreshold := 375;
        AllowedThreshold := AllowedThreshold + ROUND((AllowedThreshold * TestsBuffer) / 100, 1, '=');
        CreateJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryPerformanceProfiler.StartProfiler(true);
        CreateAndPostGeneralJourLinesForBatch(GenJournalBatch, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(100, 2), 10);
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestPostGeneralJournalLinesWithAccountTypeAsGLAccount',
            PerfProfilerEventsTest."Object Type"::Codeunit, CODEUNIT::"Gen. Jnl.-Post Batch", true);
        //VerifyExpectedResults(PerfProfilerEventsTest, AllowedThreshold, 35);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostGeneralJournalLinesWithAccountTypeAsBankAccount()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        AllowedThreshold: Integer;
    begin
        AllowedThreshold := 375;
        AllowedThreshold := AllowedThreshold + ROUND((AllowedThreshold * TestsBuffer) / 100, 1, '=');
        CreateJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryPerformanceProfiler.StartProfiler(true);
        CreateAndPostGeneralJourLinesForBatch(GenJournalBatch, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::"Bank Account", BankAccount."No.", LibraryRandom.RandDec(100, 2), 10);
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestPostGeneralJournalLinesWithAccountTypeAsBankAccount',
            PerfProfilerEventsTest."Object Type"::Codeunit, CODEUNIT::"Gen. Jnl.-Post Batch", true);
        //VerifyExpectedResults(PerfProfilerEventsTest, AllowedThreshold, 35);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostGeneralJournalLinesWithAccountTypeAsFixedAsset()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        GenJournalBatch: Record "Gen. Journal Batch";
        FixedAsset: Record "Fixed Asset";
        GenJournalLine: Record "Gen. Journal Line";
        AllowedThreshold: Integer;
    begin
        AllowedThreshold := 375;
        AllowedThreshold := AllowedThreshold + ROUND((AllowedThreshold * TestsBuffer) / 100, 1, '=');
        CreateJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryPerformanceProfiler.StartProfiler(true);
        CreateAndPostGeneralJourLinesForBatch(GenJournalBatch, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::"Fixed Asset", FixedAsset."No.", LibraryRandom.RandDec(100, 2), 10);
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestPostGeneralJournalLinesWithAccountTypeAsFixedAsset',
            PerfProfilerEventsTest."Object Type"::Codeunit, CODEUNIT::"Gen. Jnl.-Post Batch", true);
        //VerifyExpectedResults(PerfProfilerEventsTest, AllowedThreshold, 35);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostGeneralJournalLinesWithAccountTypeAsEmployee()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        GenJournalBatch: Record "Gen. Journal Batch";
        Employee: Record Employee;
        GenJournalLine: Record "Gen. Journal Line";
        AllowedThreshold: Integer;
    begin
        AllowedThreshold := 375;
        AllowedThreshold := AllowedThreshold + ROUND((AllowedThreshold * TestsBuffer) / 100, 1, '=');
        CreateJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());
        CreateEmployee(Employee);
        LibraryPerformanceProfiler.StartProfiler(true);
        CreateAndPostGeneralJourLinesForBatch(GenJournalBatch, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Employee, Employee."No.", LibraryRandom.RandDec(100, 2), 10);
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestPostGeneralJournalLinesWithAccountTypeAsEmployee',
            PerfProfilerEventsTest."Object Type"::Codeunit, CODEUNIT::"Gen. Jnl.-Post Batch", true);
        //VerifyExpectedResults(PerfProfilerEventsTest, AllowedThreshold, 35);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenVendorLedgerEntriesPerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntriesList: TestPage "Vendor Ledger Entries";
        AllowedThreshold: Integer;
    begin
        AllowedThreshold := 175;
        AllowedThreshold := AllowedThreshold + ROUND((AllowedThreshold * TestsBuffer) / 100, 1, '=');
        if VendorLedgerEntry.IsEmpty() then
            exit;
        LibraryPerformanceProfiler.StartProfiler(true);
        VendorLedgerEntriesList.OpenView();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestOpenVendorLedgerEntriesPerformance',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"Vendor Ledger Entries", true);
        VendorLedgerEntriesList.Close();
        // VerifyExpectedResults(PerfProfilerEventsTest, AllowedThreshold, 35);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenDetailedVendorLedgerEntriesPerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DetailedVendorLedgerEntriesList: TestPage "Detailed Vendor Ledg. Entries";
        AllowedThreshold: Integer;
    begin
        AllowedThreshold := 175;
        AllowedThreshold := AllowedThreshold + ROUND((AllowedThreshold * TestsBuffer) / 100, 1, '=');
        if DetailedVendorLedgEntry.IsEmpty() then
            exit;
        LibraryPerformanceProfiler.StartProfiler(true);
        DetailedVendorLedgerEntriesList.OpenView();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestOpenDetailedVendorLedgerEntriesPerformance',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"Detailed Vendor Ledg. Entries", true);
        DetailedVendorLedgerEntriesList.Close();
        // VerifyExpectedResults(PerfProfilerEventsTest, AllowedThreshold, 35);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenCustomerLedgerEntriesPerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        CustomerLedgerEntry: Record "Cust. Ledger Entry";
        CustomerLedgerEntriesList: TestPage "Customer Ledger Entries";
        AllowedThreshold: Integer;
    begin
        AllowedThreshold := 175;
        AllowedThreshold := AllowedThreshold + ROUND((AllowedThreshold * TestsBuffer) / 100, 1, '=');
        if CustomerLedgerEntry.IsEmpty() then
            exit;
        LibraryPerformanceProfiler.StartProfiler(true);
        CustomerLedgerEntriesList.OpenView();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestOpenCustomerLedgerEntriesPerformance',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"Customer Ledger Entries", true);
        CustomerLedgerEntriesList.Close();
        // VerifyExpectedResults(PerfProfilerEventsTest, AllowedThreshold, 35);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenDetailedCustomerLedgerEntriesPerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DetailedCustLedgEntriesList: TestPage "Detailed Cust. Ledg. Entries";
        AllowedThreshold: Integer;
    begin
        AllowedThreshold := 175;
        AllowedThreshold := AllowedThreshold + ROUND((AllowedThreshold * TestsBuffer) / 100, 1, '=');
        if DetailedCustLedgEntry.IsEmpty() then
            exit;
        LibraryPerformanceProfiler.StartProfiler(true);
        DetailedCustLedgEntriesList.OpenView();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestOpenDetailedCustomerLedgerEntriesPerformance',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"Detailed Cust. Ledg. Entries", true);
        DetailedCustLedgEntriesList.Close();
        // VerifyExpectedResults(PerfProfilerEventsTest, AllowedThreshold, 35);
    end;

    local procedure CreateJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; JournalTemplateName: Code[10])
    begin
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, JournalTemplateName);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"G/L Account");
        GenJournalBatch.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNoWithDirectPosting());
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateAndPostGeneralJourLinesForBatch(var GenJournalBatch: Record "Gen. Journal Batch"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; numOfLines: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        LocalCount: Integer;
    begin
        for LocalCount := 1 to numOfLines do begin
            GenJournalLine.Reset();
            LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
              DocumentType, AccountType, AccountNo, Amount);
            if AccountType = GenJournalLine."Account Type"::"Fixed Asset" then begin
                LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
                DepreciationBook."G/L Integration - Maintenance" := true;
                DepreciationBook.Modify();
                LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, AccountNo, DepreciationBook.Code);
                LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
                FADepreciationBook."FA Posting Group" := FAPostingGroup.Code;
                FADepreciationBook.Modify();
                GenJournalLine.Validate("FA Posting Type", GenJournalLine."FA Posting Type"::Maintenance);
                GenJournalLine.Validate("Depreciation Book Code", DepreciationBook.Code);
            end;
            GenJournalLine.Modify();
        end;
        // Find all lines created and post them.
        GenJournalLine.Reset();
        GenJournalLine.SetFilter("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindSet();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateEmployee(var Employee: Record Employee)
    var
        EmployeePostingGroup: Record "Employee Posting Group";
    begin
        LibraryHumanResource.CreateEmployee(Employee);
        EmployeePostingGroup.Init();
        EmployeePostingGroup.Validate(Code, LibraryUtility.GenerateGUID());
        EmployeePostingGroup.Validate("Payables Account", LibraryERM.CreateGLAccountNoWithDirectPosting());
        EmployeePostingGroup.Insert(true);
        Employee.Validate("Employee Posting Group", EmployeePostingGroup.Code);
        Employee.Modify(true);
    end;

    [RequestPageHandler]
    PROCEDURE BalanceSheetRequestPageHandler(var AccountSchedule: TestRequestPage "Account Schedule");
    BEGIN
        AccountSchedule.SAVEASXML(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    END;

    [RequestPageHandler]
    PROCEDURE TrialBalanceRequestPageHandler(var TrialBalance: TestRequestPage "Trial Balance");
    BEGIN
        TrialBalance.SAVEASXML(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    END;

    [RequestPageHandler]
    PROCEDURE DetailedTrialBalancePageHandler(var DetailTrialBalance: TestRequestPage "Detail Trial Balance");
    BEGIN
        DetailTrialBalance.SAVEASXML(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    END;

    [PageHandler]
    PROCEDURE AccountSchedulePageHandler(VAR AccountSchedule: TestPage "Account Schedule");
    BEGIN
        AccountSchedule.Close();
    END;
}