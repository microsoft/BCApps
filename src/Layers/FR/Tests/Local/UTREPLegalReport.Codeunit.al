codeunit 144036 "UT REP Legal Report"
{
    // // [FEATURE] [Report]
    //       1. Verify the Bank Account No, Debit Amount and Credit Amount after running report Bank Account Trial Balance with Balance.
    //       2. Verify the Bank Account No, Debit Amount, Credit Amount and Dimension after running report Bank Account Trial Balance with Dimension.
    //       3. Verify the Bank Account No, Debit Amount and Credit Amount as zero after running report Bank Account Trial Balance.
    //       4. Verify the Customer No, Credit Amount and Dimension after running report Customer Detail Trial Balance.
    //       5. Verify that no record is available after running report Customer Detail Trial Balance without Balance.
    //       6. Verify the Customer No and Credit Amount after running report Customer Detail Trial Balance.
    //       7. Verify the Customer No and Credit Amount after running report Customer Trial Balance.
    //       8. Verify the Customer No and Debit Amount as zero after running report Customer Trial Balance without Balance.
    //       9. Verify the Customer No, Credit Amount and Dimension after running report Customer Trial Balance with Dimension.
    //      10. Verify the Period Type, Credit Amount and Debit Amount after running report GL Detail Trial Balance centralized by Date.
    //      11. Verify the Period Type, Credit Amount and Debit Amount after running report GL Detail Trial Balance centralized by Week.
    //      12. Verify the Period Type, Credit Amount and Debit Amount after running report GL Detail Trial Balance centralized by Month.
    //      13. Verify the Period Type, Credit Amount and Debit Amount after running report GL Detail Trial Balance centralized by Quarter.
    //      14. Verify the Period Type, Credit Amount and Debit Amount after running report GL Detail Trial Balance centralized by Year.
    //      15. Verify that no record is available after running report Vendor Detail Trial Balance without Balance.
    //      16. Verify the Vendor No and Credit Amount is available after running report Vendor Detail Trial Balance with Balance.
    //      17. Verify the Vendor No, Credit Amount and Dimension is available after running report Vendor Detail Trial Balance with Balance.
    //      18. Verify the Vendor No, Credit Amount and Dimension is available after running report Vendor Trial Balance with Balance.
    //      19. Verify the Vendor No and Credit Amount as zero after running report Vendor Trial Balance without Balance.
    //      22. Verify the Credit Amount and Debit Amount and Dimension after running report GL Detail Trial Balance.
    //      21. Verify the Bank Account Detail Trial Balance report with Dimension filter.
    //      22. Verify the Bank Account Detail Trial Balance report without Dimension filter.
    //      23. Verify the GL Account No, Credit Amount and Debit Amount after running report GL Trial Balance.
    //      24. Verify the GL Account No, Credit Amount and Debit Amount as zero after running report GL Trial Balance.
    //      25. Verify the Error Code, Actual Error, You must fill in the DateFilter field after running Bank Account Detail Trial Balance Report.
    //      26. Verify the Error Code, Actual Error, You must fill in the DateFilter field after running Bank Account Trial Balance Report.
    //      27. Verify the Error Code, Actual Error, You must fill in the DateFilter field after running Customer Detail Trial Balance Report.
    //      28. Verify the Error Code, Actual Error, You must fill in the DateFilter field after running CustomerTrial Balance Report.
    //      29. Verify the Error Code, Actual Error, You must fill in the DateFilter field after running GL Account Detail Trial Balance Report.
    //      30. Verify the Error Code, Actual Error, You must fill in the DateFilter field after running Vendor Detail Trial Balance Report.
    //      31. Verify the Error Code, Actual Error, You must fill in the DateFilter field after running Vendor Trial Balance Report.
    //      32. Verify the Error Code, Actual Error, You must fill in the DateFilter field after running GL Trial Balance Report.
    //      33. Verify the Source Code, Credit Amount and Debit Amount after running report GL Journal.
    //  34.-38. Verify the GL Account No, Credit Amount and Debit Amount after running report Journal with sorting by Posting Date and Document No. for Period Type options.
    //  39.-43. Verify the Customer No, Credit Amount and Debit Amount after running report Customer Journal with sorting by Posting Date and Document No. for Period Type options.
    //  44.-48. Verify the Vendor No, Credit Amount and Debit Amount after running report Vendor Journal with sorting by Posting Date and Document No. for Period Type options.
    //  49.-53. Verify the Bank Account No, Credit Amount and Debit Amount after running report Bank Account Journal with sorting by Posting Date and Document No. for Period Type options.
    // 
    //   Covers Test Cases for WI - 344334
    //   -------------------------------------------------------------------------------------------------------
    //   Test Function Name                                                                             TFS ID
    //   -------------------------------------------------------------------------------------------------------
    //   OnAfterGetRecordBankAccountTrialBalance                                                        169553
    //   OnAfterGetRecordBankAccountTrialBalanceWithDimension                                           169551,169552
    //   OnAfterGetRecordBankAccountTrialBankWithoutBalance                                             169550
    //   OnAfterGetRecordCustomerDetailTrialBalanceWithDimension                                        169556,169557
    //   OnAfterGetRecordCustomerDetailTrialBalanceExcludeBalance                                       169555,169558
    //   OnAfterGetRecordCustomerDetailTrialBalance                                                     169554
    //   OnAfterGetRecordCustomerTrialBalance                                                           169561
    //   OnAfterGetRecordCustomerTrialBalanceWithoutBlalance                                            169562,169564
    //   OnAfterGetRecordCustomerTrialBalanceWithDimension                                              169563,169565
    //   OnAfterGetRecordGLDetailTrialBalanceSummarizedByDate                                          169567
    //   OnAfterGetRecordGLDetailTrialBalanceSummarizedByWeek                                          155472
    //   OnAfterGetRecordGLDetailTrialBalanceSummarizedByMonth                                         155471
    //   OnAfterGetRecordGLDetailTrialBalanceSummarizedByQuarter                                       155473
    //   OnAfterGetRecordGLDetailTrialBalanceSummarizedByYear                                          169574
    //   OnAfterGetRecordVendorDetailTrialexcludeBalance                                                169576,169578
    //   OnAfterGetRecordVendorDetailTrialBalance                                                       169577,169579
    //   OnAfterGetRecordVendorDetailTrialBalanceWithDimension                                          169575
    //   OnAfterGetRecordVendorTrialBalanceWithDimension                                                169572,169573,169574
    //   OnAfterGetRecordVendorTrialBalanceVendorWithoutBalance                                         169570,169571,155441
    //   OnAfterGetRecordGLDetailTrialBalanceWithDimension                                              169566
    //   OnAfterGetRecordBankAccountDetailTrialBalanceWithDimension                                     169547
    //   OnAfterGetRecordBankAccountDetailTrialBalanceWithoutDimension                                  169546
    // 
    //   OnAfterGetRecordGLTrialBalance, OnAfterGetRecordGLTrialBalanceWithoutBalance
    //   OnPreDataItemBankAccountDetailTrialBalanceDateFilterError, OnPreDataItemBankAccountTrialBalanceDateFilterError
    //   OnPreDataItemCustomerDetailTrialBalanceDateFilterError, OnPreDataItemCustomerTrialBalanceDateFilterError
    //   OnPreDataItemGLDetailTrialBalanceDateFilterError, OnPreDataItemGLTrialBalanceDateFilterError
    //   OnPreDataItemVendorDetailTrialBalanceDateFilterError, OnPreDataItemVendorTrialBalanceDateFilterError
    // 
    //   Covers Test Cases for WI - 344618
    //   -------------------------------------------------------------------------------------------------------
    //   Test Function Name                                                                             TFS ID
    //   -------------------------------------------------------------------------------------------------------
    //   OnAfterGetRecordGLJournal
    //   OnAfterGetRecordDateJournal, OnAfterGetRecordMonthJournal, OnAfterGetRecordYearJournal
    //   OnAfterGetRecordWeekJournal, OnAfterGetRecordQuarterJournal
    //   OnAfterGetRecordDateCustomerJournal, OnAfterGetRecordMonthCustomerJournal,
    //   OnAfterGetRecordYearCustomerJournal                                                             169559
    //   OnAfterGetRecordWeekCustomerJournal, OnAfterGetRecordQuarterCustomerJournal                     169560
    //   OnAfterGetRecordDateVendorJournal, OnAfterGetRecordMonthVendorJournal,
    //   OnAfterGetRecordYearVendorJournal                                                               169568
    //   OnAfterGetRecordWeekVendorJournal, OnAfterGetRecordQuarterVendorJournal                         169569
    //   OnAfterGetRecordDateBankAccountJournal, OnAfterGetRecordMonthBankAccountJournal,
    //   OnAfterGetRecordYearBankAccountJournal,                                                         169548
    //   OnAfterGetRecordWeekBankAccountJournal, OnAfterGetRecordQuarterBankAccountJournal               169549

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Report]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryRandom: Codeunit "Library - Random";
        FileManagement: Codeunit "File Management";
        BankAccountCreditAmountLCYCap: Label 'Bank_Account__Credit_Amount__LCY__';
        BankAccountDebitAmountLCYCap: Label 'Bank_Account__Debit_Amount__LCY__';
        BankAccountLedgerEntryCrAmtCap: Label 'Bank_Account_Ledger_Entry__Credit_Amount__LCY__';
        BankAccountNoCap: Label 'Bank_Account__No__';
        CustomerNoCap: Label 'Customer__No__';
        DialogErr: Label 'Dialog';
        IndexOutOfBounds: Label 'IndexOutOfBounds';
        FilterCap: Label 'Filter';
        FilterValueTxt: Label 'No.: %1, Global Dimension 1 Code: %2, Date Filter: %3';
        GLAccountNoCap: Label 'No_GLAcc';
        GLAccountDebitAmountCap: Label 'DebitAmt_GLAcc';
        GLAccountCreditAmountCap: Label 'CreditAmt_GLAcc';
        GeneralCreditAmountLCYCap: Label 'GeneralCreditAmountLCY';
        GLEntryCreditAmountCap: Label 'G_L_Entry__Credit_Amount_';
        GLEntryDebitAmountCap: Label 'G_L_Entry__Debit_Amount_';
        DetailTrialBalanceGLEntryCreditAmountCap: Label 'CreditAmount_GLEntry';
        DetailTrialBalanceGLEntryDebitAmountCap: Label 'DebitAmount_GLEntry';
        PeriodCreditAmountLCYCap: Label 'PeriodCreditAmountLCY';
        PreviousCreditAmountLCYCap: Label 'PreviousCreditAmountLCY';
        RangeCap: Label '%1..%2';
        VendorNoCap: Label 'Vendor__No__';
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [HandlerFunctions('BankAccountTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordBankAccountTrialBalance()
    var
        BankAccount: Record "Bank Account";
    begin
        // Purpose of the test is to validate Bank Account - OnAfterGetRecord of the Report, ID: 10809, Bank Account Trial Balance with Balance.
        // Setup.
        Initialize();
        CreateBankAccountWithDimension(BankAccount);
        CreateBankAccountLedgerEntry(BankAccount."No.", WorkDate());

        // Exercise.
        RunTrialBalanceReport(BankAccount."No.", Format(WorkDate()), false, '', REPORT::"Bank Account Trial Balance");  // PrintBankAccountsWithoutBalance FALSE.

        // Verify: Verify the Bank Account No, Debit Amount and Credit Amount after running report Bank Account Trial Balance with Balance.
        LibraryReportDataset.LoadDataSetFile();
        BankAccount.CalcFields("Debit Amount (LCY)", "Credit Amount (LCY)");
        VerifyReportCapAndValue(
          BankAccountNoCap, BankAccount."No.", BankAccountDebitAmountLCYCap, BankAccount."Debit Amount (LCY)",
          BankAccountCreditAmountLCYCap, BankAccount."Credit Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('BankAccountTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordBankAccountTrialBalanceWithDimension()
    var
        BankAccount: Record "Bank Account";
    begin
        // Purpose of the test is to validate Bank Account - OnAfterGetRecord of the Report, ID: 10809, Bank Account Trial Balance with Dimension.
        // Setup.
        Initialize();
        CreateBankAccountWithDimension(BankAccount);
        CreateBankAccountLedgerEntry(BankAccount."No.", WorkDate());

        // Exercise.
        RunTrialBalanceReport(
          BankAccount."No.", Format(WorkDate()), true, BankAccount."Global Dimension 1 Code", REPORT::"Bank Account Trial Balance");  // PrintBankAccountsWithoutBalance TRUE.

        // Verify: Verify the Bank Account No, Debit Amount,Credit Amount and Dimension after running report Bank Account Trial Balance with Dimension.
        LibraryReportDataset.LoadDataSetFile();
        BankAccount.CalcFields("Debit Amount (LCY)", "Credit Amount (LCY)");
        VerifyReportCapAndValue(
          BankAccountNoCap, BankAccount."No.", BankAccountDebitAmountLCYCap, BankAccount."Debit Amount (LCY)",
          BankAccountCreditAmountLCYCap, BankAccount."Credit Amount (LCY)");
        LibraryReportDataset.AssertElementWithValueExists(
          FilterCap, StrSubstNo(FilterValueTxt, BankAccount."No.", BankAccount."Global Dimension 1 Code", Format(WorkDate())));
    end;

    [Test]
    [HandlerFunctions('BankAccountTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordBankAccountTrialBankWithoutBalance()
    var
        BankAccount: Record "Bank Account";
    begin
        // Purpose of the test is to validate Bank Account - OnAfterGetRecord of the Report, ID: 10809, Bank Account Trial Balance without Balance.
        // Setup.
        Initialize();
        CreateBankAccountWithDimension(BankAccount);
        CreateBankAccountLedgerEntry('', WorkDate());

        // Exercise.
        RunTrialBalanceReport(BankAccount."No.", Format(WorkDate()), true, '', REPORT::"Bank Account Trial Balance");  // PrintBankAccountsWithoutBalance TRUE.

        // Verify: Verify the Bank Account No, Debit Amount and Credit Amount as zero after running report Bank Account Trial Balance.
        LibraryReportDataset.LoadDataSetFile();
        BankAccount.CalcFields("Debit Amount (LCY)", "Credit Amount (LCY)");
        VerifyReportCapAndValue(BankAccountNoCap, BankAccount."No.", BankAccountDebitAmountLCYCap, 0, BankAccountCreditAmountLCYCap, 0);
    end;

    [Test]
    [HandlerFunctions('CustomerDetailTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCustomerDetailTrialBalanceWithDimension()
    var
        Customer: Record Customer;
    begin
        // Purpose of the test is to validate Customer - OnAfterGetRecord of the Report, ID: 10806, Customer Detail Trial Balance.
        // Setup.
        Initialize();
        CreateCustomerWithDimension(Customer);
        CreateDetailedCustomerLedgerEntry(CreateCustomerLedgerEntry(Customer."No.", WorkDate()));

        // Exercise.
        RunTrialBalanceReport(
          Customer."No.", Format(CalcDate('<1M>', WorkDate())), false, Customer."Global Dimension 1 Code",
          REPORT::"Customer Detail Trial Balance");  // ExcludeBalanceOnly FALSE.

        // Verify: Verify the Customer No, Credit Amount and Dimension after running report Customer Detail Trial Balance.
        LibraryReportDataset.LoadDataSetFile();
        Customer.CalcFields("Credit Amount (LCY)");
        VerifyReportCapAndValue(
          CustomerNoCap, Customer."No.", PreviousCreditAmountLCYCap, Customer."Credit Amount (LCY)",
          GeneralCreditAmountLCYCap, Customer."Credit Amount (LCY)");
        LibraryReportDataset.AssertElementWithValueExists(
          FilterCap, StrSubstNo(FilterValueTxt, Customer."No.", Customer."Global Dimension 1 Code", Format(CalcDate('<1M>', WorkDate()))));
    end;

    [Test]
    [HandlerFunctions('CustomerDetailTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCustomerDetailTrialBalanceExcludeBalance()
    var
        Customer: Record Customer;
    begin
        // Purpose of the test is to validate Customer - OnAfterGetRecord of the Report, ID: 10806, Customer Detail Trial Balance without Balance.
        // Setup.
        Initialize();
        CreateCustomerWithDimension(Customer);
        CreateDetailedCustomerLedgerEntry(CreateCustomerLedgerEntry(Customer."No.", WorkDate()));
        RunTrialBalanceReport(Customer."No.", Format(CalcDate('<1M>', WorkDate())), true, '', REPORT::"Customer Detail Trial Balance");  // ExcludeBalanceOnly TRUE.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();

        // Exercise.
        asserterror LibraryReportDataset.CurrentRowHasElement(CustomerNoCap);

        // Verify: Verify that no record is available after running report Customer Detail Trial Balance without Balance.
        Assert.ExpectedErrorCode(IndexOutOfBounds);
    end;

    [Test]
    [HandlerFunctions('CustomerDetailTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCustomerDetailTrialBalance()
    var
        Customer: Record Customer;
    begin
        // Purpose of the test is to validate Customer - OnAfterGetRecord of the Report, ID: 10806, Customer Detail Trial Balance.
        // Setup.
        Initialize();
        CreateCustomerWithDimension(Customer);
        CreateDetailedCustomerLedgerEntry(CreateCustomerLedgerEntry(Customer."No.", WorkDate()));

        // Exercise.
        RunTrialBalanceReport(Customer."No.", Format(CalcDate('<1M>', WorkDate())), false, '', REPORT::"Customer Detail Trial Balance");  // ExcludeBalanceOnly FALSE.

        // Verify: Verify the Customer No and Credit Amount after running report Customer Detail Trial Balance.
        LibraryReportDataset.LoadDataSetFile();
        Customer.CalcFields("Credit Amount (LCY)");
        VerifyReportCapAndValue(
          CustomerNoCap, Customer."No.", PreviousCreditAmountLCYCap, Customer."Credit Amount (LCY)",
          GeneralCreditAmountLCYCap, Customer."Credit Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('CustomerTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCustomerTrialBalance()
    begin
        // Purpose of the test is to validate Customer - OnAfterGetRecord of the Report, ID: 10805, Customer Trial Balance.
        CustomerTrialBalanceReport(false, REPORT::"Customer Trial Balance FR");
    end;

    [Test]
    [HandlerFunctions('CustomerTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCustomerTrialBalanceWithoutBlalance()
    begin
        // Purpose of the test is to validate Customer - OnAfterGetRecord of the Report, ID: 10805, Customer Trial Balance without Balance.
        CustomerTrialBalanceReport(true, REPORT::"Customer Trial Balance FR");
    end;

    local procedure CustomerTrialBalanceReport(PrintCustomersWithoutBalance: Boolean; ReportID: Integer)
    var
        Customer: Record Customer;
    begin
        // Setup.
        Initialize();
        CreateCustomerWithDimension(Customer);
        CreateDetailedCustomerLedgerEntry(CreateCustomerLedgerEntry(Customer."No.", WorkDate()));

        // Exercise.
        RunTrialBalanceReport(Customer."No.", Format(WorkDate()), PrintCustomersWithoutBalance, '', ReportID);  // PrintCustomersWithoutBalance TRUE.

        // Verify: Verify the Customer No and Debit Amount as zero after running report Customer Trial Balance without Balance.
        LibraryReportDataset.LoadDataSetFile();
        Customer.CalcFields("Credit Amount (LCY)");
        VerifyNoAndCreditAmount(CustomerNoCap, Customer."No.", PeriodCreditAmountLCYCap, Customer."Credit Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('CustomerTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCustomerTrialBalanceWithDimension()
    var
        Customer: Record Customer;
    begin
        // Purpose of the test is to validate Customer - OnAfterGetRecord of the Report, ID: 10805, Customer Trial Balance with Dimension.
        // Setup.
        Initialize();
        CreateCustomerWithDimension(Customer);
        CreateDetailedCustomerLedgerEntry(CreateCustomerLedgerEntry(Customer."No.", WorkDate()));

        // Exercise.
        RunTrialBalanceReport(Customer."No.", Format(WorkDate()), false, Customer."Global Dimension 1 Code", REPORT::"Customer Trial Balance FR");  // PrintCustomersWithoutBalance FALSE.

        // Verify: Verify the Customer No, Credit Amount and Dimension after running report Customer Trial Balance with Dimension.
        LibraryReportDataset.LoadDataSetFile();
        Customer.CalcFields("Credit Amount (LCY)");
        VerifyNoAndCreditAmount(CustomerNoCap, Customer."No.", PeriodCreditAmountLCYCap, Customer."Credit Amount (LCY)");
        LibraryReportDataset.AssertElementWithValueExists(
          FilterCap, StrSubstNo(FilterValueTxt, Customer."No.", Customer."Global Dimension 1 Code", Format(WorkDate())));
    end;

    [Test]
    [HandlerFunctions('CustomerTrialBalanceDateFilterRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CustomerTrialBalanceShowsCustomersWithStartingBalance()
    var
        Index: Integer;
        CustomerNo: array[2] of Code[20];
    begin
        // [FEATURE] [Customer] [Customer Trial Balance] [UT]
        // [SCENARIO 273269] Report 10805 "Customer Trial Balance" shows Customers with Starting Balance but without Balance Change in a date range.
        Initialize();

        for Index := 1 to ArrayLen(CustomerNo) do
            CustomerNo[Index] := LibrarySales.CreateCustomerNo();

        CreateDetailedCustomerLedgerEntry(CreateCustomerLedgerEntry(CustomerNo[1], WorkDate()));
        CreateDetailedCustomerLedgerEntry(CreateCustomerLedgerEntry(CustomerNo[2], WorkDate() - 40));

        // Date Filter = WORKDATE
        REPORT.Run(REPORT::"Customer Trial Balance FR");

        LibraryReportDataset.LoadDataSetFile();
        for Index := 1 to ArrayLen(CustomerNo) do
            LibraryReportDataset.AssertElementWithValueExists(CustomerNoCap, CustomerNo[Index]);
    end;

    [Test]
    [HandlerFunctions('GLDetailTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLDetailTrialBalanceSummarizedByDate()
    var
        SummarizedBy: Option Date,Week,Month,Quarter,Year;
    begin
        // Purpose of the test is to validate GL Account - OnAfterGetRecord of the Report, ID: 10804, GL Detail Trial Balance centralized by Date.
        GLDetailTrialBalanceTestReport(SummarizedBy::Date, Format(StrSubstNo(RangeCap, WorkDate(), WorkDate())));
    end;

    [Test]
    [HandlerFunctions('GLDetailTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLDetailTrialBalanceSummarizedByWeek()
    var
        SummarizedBy: Option Date,Week,Month,Quarter,Year;
    begin
        // Purpose of the test is to validate GL Account - OnAfterGetRecord of the Report, ID: 10804, GL Detail Trial Balance centralized by Week.
        GLDetailTrialBalanceTestReport(
          SummarizedBy::Week, Format(StrSubstNo(RangeCap, CalcDate('<-CW>', WorkDate()), CalcDate('<CW>', WorkDate()))));
    end;

    [Test]
    [HandlerFunctions('GLDetailTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLDetailTrialBalanceSummarizedByMonth()
    var
        SummarizedBy: Option Date,Week,Month,Quarter,Year;
    begin
        // Purpose of the test is to validate GL Account - OnAfterGetRecord of the Report, ID: 10804, GL Detail Trial Balance centralized by Month.
        GLDetailTrialBalanceTestReport(
          SummarizedBy::Month, Format(StrSubstNo(RangeCap, CalcDate('<-CM>', WorkDate()), CalcDate('<CM>', WorkDate()))));
    end;

    [Test]
    [HandlerFunctions('GLDetailTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLDetailTrialBalanceSummarizedByQuarter()
    var
        SummarizedBy: Option Date,Week,Month,Quarter,Year;
    begin
        // Purpose of the test is to validate GL Account - OnAfterGetRecord of the Report, ID: 10804, GL Detail Trial Balance centralized by Quarter.
        GLDetailTrialBalanceTestReport(
          SummarizedBy::Quarter, Format(StrSubstNo(RangeCap, CalcDate('<-CQ>', WorkDate()), CalcDate('<CQ>', WorkDate()))));
    end;

    [Test]
    [HandlerFunctions('GLDetailTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLDetailTrialBalanceSummarizedByYear()
    var
        SummarizedBy: Option Date,Week,Month,Quarter,Year;
    begin
        // Purpose of the test is to validate GL Account - OnAfterGetRecord of the Report, ID: 10804, GL Detail Trial Balance centralized by Year.
        GLDetailTrialBalanceTestReport(
          SummarizedBy::Year, Format(StrSubstNo(RangeCap, CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()))));
    end;

    local procedure GLDetailTrialBalanceTestReport(SummarizedBy: Option Date,Week,Month,Quarter,Year; DateFilter: Text)
    var
        GLAccount: Record "G/L Account";
    begin
        // Setup.
        Initialize();
        CreateGLAccount(GLAccount);
        CreateGLEntry(GLAccount."No.");

        // Exercise.
        RunGLDetailTrialBalanceReport(GLAccount."No.", Format(DateFilter), SummarizedBy, '');

        // Verify: Verify the Period Type, Credit Amount and Debit Amount after running report GL Detail Trial Balance.
        LibraryReportDataset.LoadDataSetFile();
        GLAccount.CalcFields("Debit Amount", "Credit Amount");
        LibraryReportDataset.AssertElementWithValueExists('Date_Period_Type', Format(SummarizedBy));
        LibraryReportDataset.AssertElementWithValueExists(DetailTrialBalanceGLEntryDebitAmountCap, GLAccount."Debit Amount");
        LibraryReportDataset.AssertElementWithValueExists(DetailTrialBalanceGLEntryCreditAmountCap, GLAccount."Credit Amount");
    end;

    [Test]
    [HandlerFunctions('VendorDetailTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVendorDetailTrialExcludeBalance()
    var
        Vendor: Record Vendor;
    begin
        // Purpose of the test is to validate Vendor - OnAfterGetRecord of the Report, ID: 10808, Vendor Detail Trial Balance without Balance.
        // Setup.
        Initialize();
        CreateVendorWithDimension(Vendor);
        CreateDetailedVendorLedgerEntry(CreateVendorLedgerEntry(Vendor."No.", WorkDate()));
        RunTrialBalanceReport(Vendor."No.", Format(CalcDate('<1M>', WorkDate())), true, '', REPORT::"Vendor Detail Trial Balance FR");  // ExcludeBalanceOnly TRUE.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();

        // Exercise.
        asserterror LibraryReportDataset.CurrentRowHasElement(VendorNoCap);

        // Verify: Verify that no record is available after running report Vendor Detail Trial Balance without Balance.
        Assert.ExpectedErrorCode(IndexOutOfBounds);
    end;

    [Test]
    [HandlerFunctions('VendorDetailTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVendorDetailTrialBalance()
    var
        Vendor: Record Vendor;
    begin
        // Purpose of the test is to validate Vendor - OnAfterGetRecord of the Report, ID: 10808, Vendor Detail Trial Balance with Balance.
        // Setup.
        Initialize();
        CreateVendorWithDimension(Vendor);
        CreateDetailedVendorLedgerEntry(CreateVendorLedgerEntry(Vendor."No.", WorkDate()));

        // Exercise.
        RunTrialBalanceReport(Vendor."No.", Format(CalcDate('<1M>', WorkDate())), false, '', REPORT::"Vendor Detail Trial Balance FR");  // ExcludeBalanceOnly FALSE.

        // Verify: Verify the Vendor No and Credit Amount is available after running report Vendor Detail Trial Balance with Balance.
        LibraryReportDataset.LoadDataSetFile();
        Vendor.CalcFields("Credit Amount (LCY)");
        VerifyReportCapAndValue(
          VendorNoCap, Vendor."No.", PreviousCreditAmountLCYCap, Vendor."Credit Amount (LCY)", GeneralCreditAmountLCYCap,
          Vendor."Credit Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('VendorDetailTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVendorDetailTrialBalanceWithDimension()
    var
        Vendor: Record Vendor;
    begin
        // Purpose of the test is to validate Vendor - OnAfterGetRecord of the Report, ID: 10808, Vendor Detail Trial Balance with Dimension.
        // Setup.
        Initialize();
        CreateVendorWithDimension(Vendor);
        CreateDetailedVendorLedgerEntry(CreateVendorLedgerEntry(Vendor."No.", WorkDate()));

        // Exercise.
        RunTrialBalanceReport(
          Vendor."No.", Format(CalcDate('<1M>', WorkDate())), false, Vendor."Global Dimension 1 Code", REPORT::"Vendor Detail Trial Balance FR");  // ExcludeBalanceOnly FALSE.

        // Verify: Verify the Vendor No, Credit Amount and Dimension is available after running report Vendor Detail Trial Balance with Balance.
        LibraryReportDataset.LoadDataSetFile();
        Vendor.CalcFields("Credit Amount (LCY)");
        VerifyReportCapAndValue(
          VendorNoCap, Vendor."No.", PreviousCreditAmountLCYCap, Vendor."Credit Amount (LCY)", GeneralCreditAmountLCYCap,
          Vendor."Credit Amount (LCY)");
        LibraryReportDataset.AssertElementWithValueExists(
          FilterCap, StrSubstNo(FilterValueTxt, Vendor."No.", Vendor."Global Dimension 1 Code", Format(CalcDate('<1M>', WorkDate()))));
    end;

    [Test]
    [HandlerFunctions('VendorTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVendorTrialBalanceWithDimension()
    var
        Vendor: Record Vendor;
    begin
        // Purpose of the test is to validate Vendor - OnAfterGetRecord of the Report, ID: 10807, Vendor Trial Balance.
        // Setup.
        Initialize();
        CreateVendorWithDimension(Vendor);
        CreateDetailedVendorLedgerEntry(CreateVendorLedgerEntry(Vendor."No.", WorkDate()));

        // Exercise.
        RunTrialBalanceReport(
          Vendor."No.", Format(WorkDate()), false, Vendor."Global Dimension 1 Code", REPORT::"Vendor Trial Balance FR");  // PrintVendorsWithoutBalance FALSE.

        // Verify: Verify the Vendor No, Credit Amount and Dimension is available after running report Vendor Trial Balance with Balance.
        LibraryReportDataset.LoadDataSetFile();
        Vendor.CalcFields("Credit Amount (LCY)");
        VerifyNoAndCreditAmount(VendorNoCap, Vendor."No.", PeriodCreditAmountLCYCap, Vendor."Credit Amount (LCY)");
        LibraryReportDataset.AssertElementWithValueExists(
          FilterCap, StrSubstNo(FilterValueTxt, Vendor."No.", Vendor."Global Dimension 1 Code", Format(WorkDate())));
    end;

    [Test]
    [HandlerFunctions('VendorTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVendorTrialBalanceVendorWithoutBalance()
    var
        Vendor: Record Vendor;
    begin
        // Purpose of the test is to validate Vendor - OnAfterGetRecord of the Report, ID: 10807, Vendor Trial Balance.
        // Setup.
        Initialize();
        CreateVendorWithDimension(Vendor);
        CreateDetailedVendorLedgerEntry(CreateVendorLedgerEntry(Vendor."No.", WorkDate() - 40));

        // Exercise.
        RunTrialBalanceReport(Vendor."No.", Format(WorkDate()), true, '', REPORT::"Vendor Trial Balance FR");  // PrintVendorsWithoutBalance TRUE.

        // Verify: Verify the Vendor No and Credit Amount as zero after running report Vendor Trial Balance without Balance.
        LibraryReportDataset.LoadDataSetFile();
        VerifyNoAndCreditAmount(VendorNoCap, Vendor."No.", PeriodCreditAmountLCYCap, 0);
    end;

    [Test]
    [HandlerFunctions('VendorTrialBalanceDateFilterRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VendorTrialBalanceShowsVendorsWithStartingBalance()
    var
        Index: Integer;
        VendorNo: array[2] of Code[20];
    begin
        // [FEATURE] [Vendor] [Vendor Trial Balance] [UT]
        // [SCENARIO 273269] Report 10807 "Vendor Trial Balance" shows Vendors with Starting Balance but without Balance Change in a date range.
        Initialize();

        for Index := 1 to ArrayLen(VendorNo) do
            VendorNo[Index] := LibraryPurchase.CreateVendorNo();

        CreateDetailedVendorLedgerEntry(CreateVendorLedgerEntry(VendorNo[1], WorkDate()));
        CreateDetailedVendorLedgerEntry(CreateVendorLedgerEntry(VendorNo[2], WorkDate() - 40));

        // Date Filter = WORKDATE
        REPORT.Run(REPORT::"Vendor Trial Balance FR");

        LibraryReportDataset.LoadDataSetFile();
        for Index := 1 to ArrayLen(VendorNo) do
            LibraryReportDataset.AssertElementWithValueExists(VendorNoCap, VendorNo[Index]);
    end;

    [Test]
    [HandlerFunctions('GLDetailTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLDetailTrialBalanceWithDimension()
    var
        GLAccount: Record "G/L Account";
        SummarizedBy: Option Date,Week,Month,Quarter,Year;
    begin
        // Purpose of the test is to validate GL Account - OnAfterGetRecord of the Report, ID: 10804, GL Detail Trial Balance with Dimension.
        // Setup.
        Initialize();
        CreateGLAccountWithDimension(GLAccount);
        CreateGLEntry(GLAccount."No.");

        // Exercise.
        RunGLDetailTrialBalanceReport(
          GLAccount."No.", Format(StrSubstNo(RangeCap, CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()))),
          SummarizedBy::Year, GLAccount."Global Dimension 1 Code");

        // Verify: Verify the Credit Amount, Debit Amount and Dimension after running report GL Detail Trial Balance.
        LibraryReportDataset.LoadDataSetFile();
        GLAccount.CalcFields("Debit Amount", "Credit Amount");
        LibraryReportDataset.AssertElementWithValueExists(DetailTrialBalanceGLEntryDebitAmountCap, GLAccount."Debit Amount");
        LibraryReportDataset.AssertElementWithValueExists(DetailTrialBalanceGLEntryCreditAmountCap, GLAccount."Credit Amount");
        LibraryReportDataset.AssertElementWithValueExists(
          FilterCap, StrSubstNo(
            FilterValueTxt, GLAccount."No.", GLAccount."Global Dimension 1 Code", Format(
              StrSubstNo(RangeCap, CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate())))));
    end;

    [Test]
    [HandlerFunctions('BankAccountDetailTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordBankAccountDetailTrialBalanceWithDimension()
    var
        BankAccount: Record "Bank Account";
    begin
        // [FEATURE] [Bank Account]
        // [SCENARIO] Bank Account - OnAfterGetRecord of the Report, ID: 10810, Bank Account Detail Trial Balance with Dimension.
        // Setup.
        Initialize();
        CreateBankAccountWithDimension(BankAccount);
        CreateBankAccountLedgerEntry(BankAccount."No.", WorkDate());

        // Exercise and Verify.
        DimensionOnBankAccountDetailTrialBalanceReport(BankAccount, BankAccount."Global Dimension 1 Code");
        LibraryReportDataset.AssertElementWithValueExists(
          FilterCap, StrSubstNo(
            FilterValueTxt, BankAccount."No.", BankAccount."Global Dimension 1 Code", Format(
              StrSubstNo(RangeCap, CalcDate('<-CY>', WorkDate()), WorkDate()))));
    end;

    [Test]
    [HandlerFunctions('BankAccountDetailTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordBankAccountDetailTrialBalanceWithoutDimension()
    var
        BankAccount: Record "Bank Account";
    begin
        // [FEATURE] [Bank Account]
        // [SCENARIO] Bank Account - OnAfterGetRecord of the Report, ID: 10810, Bank Account Detail Trial Balance without Dimension.
        // Setup.
        Initialize();
        CreateBankAccountWithDimension(BankAccount);
        CreateBankAccountLedgerEntry(BankAccount."No.", WorkDate());

        // Exercise and Verify.
        DimensionOnBankAccountDetailTrialBalanceReport(BankAccount, '');  // Blank for Dimension.
    end;

    [Test]
    [HandlerFunctions('BankAccountDetailTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure BankAccountDetailTrialBalanceStartBalance()
    var
        BankAccount: Record "Bank Account";
        StartDate: Date;
    begin
        // [FEATURE] [Bank Account]
        // [SCENARIO 257986] Balance in Bank Account Detail Trial Balance report
        Initialize();

        // [GIVEN] Bank Account with entry on 31.12.16 of credit amount 100
        // [GIVEN] Second entry on 15.01.17 of credit amount 200
        CreateBankAccountWithDimension(BankAccount);
        StartDate := CalcDate('<-1Y>', WorkDate());
        CreateBankAccountLedgerEntry(BankAccount."No.", StartDate);
        CreateBankAccountLedgerEntry(BankAccount."No.", WorkDate());

        // [WHEN] Run report Bank Acc. Detail Trial Balance from 01.01.17
        RunBankAccountDetailTrialBalanceReport(
          BankAccount."No.",
          StrSubstNo(RangeCap, CalcDate('<-CY>', WorkDate()), WorkDate()), '');

        // [THEN] 'PreviousCreditAmountLCY' has value 100
        LibraryReportDataset.LoadDataSetFile();
        BankAccount.SetRange("Date Filter", StartDate);
        BankAccount.CalcFields("Credit Amount (LCY)");
        LibraryReportDataset.AssertElementWithValueExists('PreviousCreditAmountLCY', BankAccount."Credit Amount (LCY)");
        // [THEN] 'Bank_Account_Ledger_Entry__Credit_Amount__LCY__' has value 200
        BankAccount.SetRange("Date Filter", WorkDate());
        BankAccount.CalcFields("Credit Amount (LCY)");
        LibraryReportDataset.AssertElementWithValueExists(BankAccountLedgerEntryCrAmtCap, BankAccount."Credit Amount (LCY)");
    end;

    local procedure DimensionOnBankAccountDetailTrialBalanceReport(BankAccount: Record "Bank Account"; GlobalDimension1Code: Code[20])
    begin
        // Exercise.
        RunBankAccountDetailTrialBalanceReport(
          BankAccount."No.", Format(
            StrSubstNo(RangeCap, CalcDate('<-CY>', WorkDate()), WorkDate())), GlobalDimension1Code);

        // Verify: Verify the Credit Amount and Dimension after running report GL Detail Trial Balance.
        LibraryReportDataset.LoadDataSetFile();
        BankAccount.CalcFields("Credit Amount (LCY)");
        LibraryReportDataset.AssertElementWithValueExists(BankAccountLedgerEntryCrAmtCap, BankAccount."Credit Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('GLTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLTrialBalance()
    var
        GLAccount: Record "G/L Account";
    begin
        // Purpose of the test is to validate GLAccount - OnAfterGetRecord of the Report, ID: 10803, G/L Trial Balance.
        // Setup.
        Initialize();
        CreateGLAccount(GLAccount);
        CreateGLEntry(GLAccount."No.");

        // Exercise.
        RunGLTrialBalanceReport(GLAccount."No.", Format(WorkDate()), false);  // PrintGLAccsWithoutBalance FALSE.

        // Verify: Verify the GL Account No, Credit Amount and Debit Amount after running report GL Trial Balance.
        LibraryReportDataset.LoadDataSetFile();
        GLAccount.CalcFields("Debit Amount", "Credit Amount");
        VerifyReportCapAndValue(
          GLAccountNoCap, GLAccount."No.", GLAccountCreditAmountCap, GLAccount."Credit Amount",
          GLAccountDebitAmountCap, GLAccount."Debit Amount");
    end;

    [Test]
    [HandlerFunctions('GLTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLTrialBalanceWithoutBalance()
    var
        GLAccount: Record "G/L Account";
    begin
        // Purpose of the test is to validate GLAccount - OnAfterGetRecord of the Report, ID: 10803, G/L Trial Balance without Balance.
        // Setup.
        Initialize();
        CreateGLAccount(GLAccount);
        CreateGLEntry('');

        // Exercise.
        RunGLTrialBalanceReport(GLAccount."No.", Format(WorkDate()), true);  // PrintGLAccsWithoutBalance TRUE.

        // Verify: Verify the GL Account No, Credit Amount and Debit Amount as zero after running report GL Trial Balance.
        LibraryReportDataset.LoadDataSetFile();
        GLAccount.CalcFields("Debit Amount", "Credit Amount");
        VerifyReportCapAndValue(GLAccountNoCap, GLAccount."No.", GLAccountCreditAmountCap, 0, GLAccountDebitAmountCap, 0);
    end;

    [Test]
    [HandlerFunctions('GLTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLTrialBalanceNegativeDebitAmt()
    var
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [G/L Trial Balance]
        // [Scenario 363542] G/L Account with negative debit amount is shown in the balance date range column
        Initialize();

        // [GIVEN] G/L Account and G/L Entry with Debit Amount = "X" < 0
        CreateGLAccount(GLAccount);
        CreateGLEntryWithAmounts(
          GLAccount."No.", -LibraryRandom.RandDec(10, 2), 0);

        // [WHEN] Run report G/L Trial Balance
        RunGLTrialBalanceReport(GLAccount."No.", Format(WorkDate()), false);

        // [THEN] Credit Balance Date Range Column has value = ABS("X")
        LibraryReportDataset.LoadDataSetFile();
        GLAccount.CalcFields("Debit Amount");
        VerifyReportCapAndValue(
          GLAccountNoCap, GLAccount."No.", GLAccountCreditAmountCap, -GLAccount."Debit Amount",
          GLAccountDebitAmountCap, 0);
    end;

    [Test]
    [HandlerFunctions('GLTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLTrialBalanceNegativeCreditAmt()
    var
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [G/L Trial Balance]
        // [Scenario 363542] G/L Account with negative credit amount is shown in the balance date range column
        Initialize();

        // [GIVEN] G/L Account and G/L Entry with Credit Amount = "X" < 0
        CreateGLAccount(GLAccount);
        CreateGLEntryWithAmounts(
          GLAccount."No.", 0, -LibraryRandom.RandDec(10, 2));

        // [WHEN] Run report G/L Trial Balance
        RunGLTrialBalanceReport(GLAccount."No.", Format(WorkDate()), false);

        // [THEN] Debit Balance Date Range Column has value = ABS("X")
        LibraryReportDataset.LoadDataSetFile();
        GLAccount.CalcFields("Credit Amount");
        VerifyReportCapAndValue(
          GLAccountNoCap, GLAccount."No.", GLAccountCreditAmountCap, 0,
          GLAccountDebitAmountCap, -GLAccount."Credit Amount");
    end;

    [Test]
    [HandlerFunctions('BankAccountDetailTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemBankAccountDetailTrialBalanceDateFilterError()
    var
        BankAccount: Record "Bank Account";
    begin
        // Purpose of the test is to validate Bank Account - OnPreDataItem of the Report, ID: 10810, Bank Account Detail Trial Balance.
        // Setup.
        Initialize();
        CreateBankAccountWithDimension(BankAccount);
        CreateBankAccountLedgerEntry(BankAccount."No.", WorkDate());

        // Exercise.
        asserterror RunBankAccountDetailTrialBalanceReport(BankAccount."No.", '', '');  // Blank DateFilter, Dimension.

        // Verify: Verify the Error Code, Actual Error, You must fill in the DateFilter field.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('BankAccountTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemBankAccountTrialBalanceDateFilterError()
    var
        BankAccount: Record "Bank Account";
    begin
        // Purpose of the test is to validate Bank Account - OnPreDataItem of the Report, ID: 10809, Bank Account Trial Balance.
        // Setup.
        Initialize();
        CreateBankAccountWithDimension(BankAccount);
        CreateBankAccountLedgerEntry(BankAccount."No.", WorkDate());

        // Exercise.
        asserterror RunTrialBalanceReport(BankAccount."No.", '', false, '', REPORT::"Bank Account Trial Balance");  // Blank DateFilter, Dimension.

        // Verify: Verify the Error Code, Actual Error, You must fill in the DateFilter field.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('CustomerDetailTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemCustomerDetailTrialBalanceDateFilterError()
    begin
        // Purpose of the test is to validate Customer - OnPreDataItem of the Report, ID: 10806, Customer Detail Trial Balance.
        DateFilterErrorOnCustomerBalanceReport(REPORT::"Customer Detail Trial Balance");
    end;

    [Test]
    [HandlerFunctions('CustomerTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemCustomerTrialBalanceDateFilterError()
    begin
        // Purpose of the test is to validate Customer - OnPreDataItem of the Report, ID: 10805, Customer Trial Balance.
        DateFilterErrorOnCustomerBalanceReport(REPORT::"Customer Trial Balance FR");
    end;

    local procedure DateFilterErrorOnCustomerBalanceReport(ReportID: Integer)
    var
        Customer: Record Customer;
    begin
        // Setup.
        Initialize();
        CreateCustomerWithDimension(Customer);
        CreateDetailedCustomerLedgerEntry(CreateCustomerLedgerEntry(Customer."No.", WorkDate()));

        // Exercise.
        asserterror RunTrialBalanceReport(Customer."No.", '', false, '', ReportID);  // Blank DateFilter.

        // Verify: Verify the Error Code, Actual Error, You must fill in the DateFilter field.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('GLDetailTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemGLDetailTrialBalanceDateFilterError()
    var
        GLAccount: Record "G/L Account";
        SummarizedBy: Option Date,Week,Month,Quarter,Year;
    begin
        // Purpose of the test is to validate GL Account - OnPreDataItem of the Report, ID: 10804, GL Detail Trial Balance centralized by month.
        // Setup.
        Initialize();
        CreateGLAccount(GLAccount);
        CreateGLEntry(GLAccount."No.");

        // Exercise.
        asserterror RunGLDetailTrialBalanceReport(GLAccount."No.", '', SummarizedBy::Month, '');  // Blank DateFilter.

        // Verify: Verify the Error Code, Actual Error, You must fill in the DateFilter field.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('GLTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemGLTrialBalanceDateFilterError()
    var
        GLAccount: Record "G/L Account";
    begin
        // Purpose of the test is to validate GL Account - OnPreDataItem of the Report, ID: 10803, GL Trial Balance.
        // Setup.
        Initialize();
        CreateGLAccount(GLAccount);
        CreateGLEntry(GLAccount."No.");

        // Exercise.
        asserterror RunGLTrialBalanceReport(GLAccount."No.", '', false);  // Blank DateFilter.

        // Verify: Verify the Error Code, Actual Error, You must fill in the DateFilter field.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('VendorDetailTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemVendorDetailTrialBalanceDateFilterError()
    begin
        // Purpose of the test is to validate Vendor - OnPreDataItem of the Report ID: 10808, Vendor Detail Trial Balance.
        DateFilterErrorOnVendorBalanceReport(REPORT::"Vendor Detail Trial Balance FR");
    end;

    [Test]
    [HandlerFunctions('VendorTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemVendorTrialBalanceDateFilterError()
    begin
        // Purpose of the test is to validate Vendor - OnPreDataItem of the Report, ID: 10807, Vendor Trial Balance.
        DateFilterErrorOnVendorBalanceReport(REPORT::"Vendor Trial Balance FR");
    end;

    local procedure DateFilterErrorOnVendorBalanceReport(ReportID: Integer)
    var
        Vendor: Record Vendor;
    begin
        // Setup.
        Initialize();
        CreateVendorWithDimension(Vendor);
        CreateDetailedVendorLedgerEntry(CreateVendorLedgerEntry(Vendor."No.", WorkDate()));

        // Exercise.
        asserterror RunTrialBalanceReport(Vendor."No.", '', false, '', ReportID);  // Blank DateFilter.

        // Verify: Verify the Error Code, Actual Error, You must fill in the DateFilter field.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('GLJournalRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLJournal()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
    begin
        // Purpose of the test is to validate GL Entry - OnAfterGetRecord of the Report, ID: 10800, GL Journal.
        // Setup: Create GL Account and GL Entry with Source Code.
        Initialize();
        CreateGLAccount(GLAccount);
        GLEntry.Get(CreateGLEntry(GLAccount."No."));

        // Exercise: Run GL Journal report.
        REPORT.Run(REPORT::"G/L Journal");

        // Verify: Verify the Source Code, GL Entry Document No, Credit Amount and Debit Amount after running report GL Journal.
        LibraryReportDataset.LoadDataSetFile();
        GLAccount.CalcFields("Debit Amount", "Credit Amount");
        LibraryReportDataset.AssertElementWithValueExists('SourceCode_Code', GLEntry."Source Code");
        VerifyReportCapAndValue(
          'G_L_Entry_Document_No_', GLEntry."Document No.", GLEntryCreditAmountCap, GLAccount."Credit Amount",
          GLEntryDebitAmountCap, GLAccount."Debit Amount");
    end;

    [Test]
    [HandlerFunctions('JournalRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordDateJournal()
    var
        Date: Record Date;
        SortingBy: Option "Posting Date","Document No.";
    begin
        // Purpose of the test is to validate GLAccount - OnAfterGetRecord with Period Type Date and sorting by Posting Date of the Report, ID: 10801, Journal.
        JournalReportWithPeriodType(Date."Period Type"::Date, SortingBy::"Posting Date", WorkDate());
    end;

    [Test]
    [HandlerFunctions('JournalRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordMonthJournal()
    var
        Date: Record Date;
        SortingBy: Option "Posting Date","Document No.";
    begin
        // Purpose of the test is to validate GLAccount - OnAfterGetRecord with Period Type Month and sorting by Posting Date of the Report, ID: 10801, Journal.
        JournalReportWithPeriodType(Date."Period Type"::Month, SortingBy::"Posting Date", CalcDate('<-CM>', WorkDate()));
    end;

    [Test]
    [HandlerFunctions('JournalRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordYearJournal()
    var
        Date: Record Date;
        SortingBy: Option "Posting Date","Document No.";
    begin
        // Purpose of the test is to validate GLAccount - OnAfterGetRecord with Period Type Year and sorting by Posting Date of the Report, ID: 10801, Journal.
        JournalReportWithPeriodType(Date."Period Type"::Year, SortingBy::"Posting Date", CalcDate('<-CY>', WorkDate()));
    end;

    [Test]
    [HandlerFunctions('JournalRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordWeekJournal()
    var
        Date: Record Date;
        SortingBy: Option "Posting Date","Document No.";
    begin
        // Purpose of the test is to validate GLAccount - OnAfterGetRecord with Period Type Week and sorting by Document No. of the Report, ID: 10801, Journal.
        JournalReportWithPeriodType(Date."Period Type"::Week, SortingBy::"Document No.", CalcDate('<-CW>', WorkDate()));
    end;

    [Test]
    [HandlerFunctions('JournalRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordQuarterJournal()
    var
        Date: Record Date;
        SortingBy: Option "Posting Date","Document No.";
    begin
        // Purpose of the test is to validate GLAccount - OnAfterGetRecord with Period Type Quarter and sorting by Document No. of the Report, ID: 10801, Journal.
        JournalReportWithPeriodType(Date."Period Type"::Quarter, SortingBy::"Document No.", CalcDate('<-CQ>', WorkDate()));
    end;

    local procedure JournalReportWithPeriodType(PeriodType: Option; SortingBy: Option; PeriodStart: Date)
    var
        GLAccount: Record "G/L Account";
    begin
        // Setup.
        Initialize();
        CreateGLAccount(GLAccount);
        CreateGLEntry(GLAccount."No.");

        // Exercise: Run Journal report with Period Type and Period Start.
        RunJournalReportWithPeriodType(PeriodType, SortingBy, PeriodStart, REPORT::Journals);

        // Verify: Verify the GL Account No, Credit Amount and Debit Amount after running report Journal.
        LibraryReportDataset.LoadDataSetFile();
        GLAccount.CalcFields("Debit Amount", "Credit Amount");
        VerifyReportCapAndValue(
          'G_L_Entry__G_L_Account_No__', GLAccount."No.", GLEntryCreditAmountCap, GLAccount."Credit Amount",
          GLEntryDebitAmountCap, GLAccount."Debit Amount");
    end;

    [Test]
    [HandlerFunctions('CustomerJournalRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordDateCustomerJournal()
    var
        Date: Record Date;
        SortingBy: Option "Posting Date","Document No.";
    begin
        // Purpose of the test is to validate Customer - OnAfterGetRecord with Period Type Date and sorting by Posting Date of the Report, ID: 10813, Customer Journal.
        CustomerJournalReportWithPeriodType(Date."Period Type"::Date, SortingBy::"Posting Date", WorkDate());
    end;

    [Test]
    [HandlerFunctions('CustomerJournalRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordMonthCustomerJournal()
    var
        Date: Record Date;
        SortingBy: Option "Posting Date","Document No.";
    begin
        // Purpose of the test is to validate Customer - OnAfterGetRecord with Period Type Month and sorting by Posting Date of the Report, ID: 10813, Customer Journal.
        CustomerJournalReportWithPeriodType(Date."Period Type"::Month, SortingBy::"Posting Date", CalcDate('<-CM>', WorkDate()));
    end;

    [Test]
    [HandlerFunctions('CustomerJournalRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordYearCustomerJournal()
    var
        Date: Record Date;
        SortingBy: Option "Posting Date","Document No.";
    begin
        // Purpose of the test is to validate Customer - OnAfterGetRecord with Period Type Year and sorting by Posting Date of the Report, ID: 10813, Customer Journal.
        CustomerJournalReportWithPeriodType(Date."Period Type"::Year, SortingBy::"Posting Date", CalcDate('<-CY>', WorkDate()));
    end;

    [Test]
    [HandlerFunctions('CustomerJournalRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordWeekCustomerJournal()
    var
        Date: Record Date;
        SortingBy: Option "Posting Date","Document No.";
    begin
        // Purpose of the test is to validate Customer - OnAfterGetRecord with Period Type Week and sorting by Document No. of the Report, ID: 10813, Customer Journal.
        CustomerJournalReportWithPeriodType(Date."Period Type"::Week, SortingBy::"Document No.", CalcDate('<-CW>', WorkDate()));
    end;

    [Test]
    [HandlerFunctions('CustomerJournalRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordQuarterCustomerJournal()
    var
        Date: Record Date;
        SortingBy: Option "Posting Date","Document No.";
    begin
        // Purpose of the test is to validate Customer - OnAfterGetRecord with Period Type Quarter and sorting by Document No. of the Report, ID: 10813, Customer Journal.
        CustomerJournalReportWithPeriodType(Date."Period Type"::Quarter, SortingBy::"Document No.", CalcDate('<-CQ>', WorkDate()));
    end;

    local procedure CustomerJournalReportWithPeriodType(PeriodType: Option; SortingBy: Option; PeriodStart: Date)
    var
        Customer: Record Customer;
    begin
        // Setup.
        Initialize();
        CreateCustomerWithDimension(Customer);
        CreateCustomerLedgerEntry(Customer."No.", WorkDate());

        // Exercise: Run Customer Journal report with Period Type and Period Start.
        RunJournalReportWithPeriodType(PeriodType, SortingBy, PeriodStart, REPORT::"Customer Journal");

        // Verify: Verify the Customer No, Credit Amount and Debit Amount after running report Customer Journal.
        LibraryReportDataset.LoadDataSetFile();
        Customer.CalcFields("Debit Amount", "Credit Amount");
        VerifyReportCapAndValue(
          'Cust__Ledger_Entry__Customer_No__', Customer."No.", 'Cust__Ledger_Entry__Credit_Amount__LCY__', Customer."Credit Amount",
          'Cust__Ledger_Entry__Debit_Amount__LCY__', Customer."Debit Amount");
    end;

    [Test]
    [HandlerFunctions('VendorJournalRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordDateVendorJournal()
    var
        Date: Record Date;
        SortingBy: Option "Posting Date","Document No.";
    begin
        // Purpose of the test is to validate Vendor - OnAfterGetRecord with Period Type Date and sorting by Posting Date of the Report, ID: 10814, Vendor Journal.
        VendorJournalReportWithPeriodType(Date."Period Type"::Date, SortingBy::"Posting Date", WorkDate());
    end;

    [Test]
    [HandlerFunctions('VendorJournalRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordMonthVendorJournal()
    var
        Date: Record Date;
        SortingBy: Option "Posting Date","Document No.";
    begin
        // Purpose of the test is to validate Vendor - OnAfterGetRecord with Period Type Month and sorting by Posting Date of the Report, ID: 10814, Vendor Journal.
        VendorJournalReportWithPeriodType(Date."Period Type"::Month, SortingBy::"Posting Date", CalcDate('<-CM>', WorkDate()));
    end;

    [Test]
    [HandlerFunctions('VendorJournalRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordYearVendorJournal()
    var
        Date: Record Date;
        SortingBy: Option "Posting Date","Document No.";
    begin
        // Purpose of the test is to validate Vendor - OnAfterGetRecord with Period Type Year and sorting by Posting Date of the Report, ID: 10814, Vendor Journal.
        VendorJournalReportWithPeriodType(Date."Period Type"::Year, SortingBy::"Posting Date", CalcDate('<-CY>', WorkDate()));
    end;

    [Test]
    [HandlerFunctions('VendorJournalRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordWeekVendorJournal()
    var
        Date: Record Date;
        SortingBy: Option "Posting Date","Document No.";
    begin
        // Purpose of the test is to validate Vendor - OnAfterGetRecord with Period Type Week and sorting by Document No. of the Report, ID: 10814, Vendor Journal.
        VendorJournalReportWithPeriodType(Date."Period Type"::Week, SortingBy::"Document No.", CalcDate('<-CW>', WorkDate()));
    end;

    [Test]
    [HandlerFunctions('VendorJournalRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordQuarterVendorJournal()
    var
        Date: Record Date;
        SortingBy: Option "Posting Date","Document No.";
    begin
        // Purpose of the test is to validate Vendor - OnAfterGetRecord with Period Type Quarter and sorting by Document No. of the Report, ID: 10814, Vendor Journal.
        VendorJournalReportWithPeriodType(Date."Period Type"::Quarter, SortingBy::"Document No.", CalcDate('<-CQ>', WorkDate()));
    end;

    local procedure VendorJournalReportWithPeriodType(PeriodType: Option; SortingBy: Option; PeriodStart: Date)
    var
        Vendor: Record Vendor;
    begin
        // Setup.
        Initialize();
        CreateVendorWithDimension(Vendor);
        CreateVendorLedgerEntry(Vendor."No.", WorkDate());

        // Exercise: Run Vendor Journal report with Period Type and Period Start.
        RunJournalReportWithPeriodType(PeriodType, SortingBy, PeriodStart, REPORT::"Vendor Journal");

        // Verify: Verify the Vendor No, Credit Amount and Debit Amount after running report Vendor Journal.
        LibraryReportDataset.LoadDataSetFile();
        Vendor.CalcFields("Debit Amount", "Credit Amount");
        VerifyReportCapAndValue(
          'VendorNo_VendLedgEntry', Vendor."No.", 'CreditAmt_VendLedgEntry', Vendor."Credit Amount",
          'DebitAmt_VendLedgEntry', Vendor."Debit Amount");
    end;

    [Test]
    [HandlerFunctions('BankAccountJournalRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordDateBankAccountJournal()
    var
        Date: Record Date;
        SortingBy: Option "Posting Date","Document No.";
    begin
        // Purpose of the test is to validate Bank Account - OnAfterGetRecord with Period Type Date of and sorting by Posting Date the Report, ID: 10815, Bank Account Journal.
        BankAccountJournalReportWithPeriodType(Date."Period Type"::Date, SortingBy::"Posting Date", WorkDate());
    end;

    [Test]
    [HandlerFunctions('BankAccountJournalRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordMonthBankAccountJournal()
    var
        Date: Record Date;
        SortingBy: Option "Posting Date","Document No.";
    begin
        // Purpose of the test is to validate Bank Account - OnAfterGetRecord with Period Type Month and sorting by Posting Date of the Report, ID: 10815, Bank Account Journal.
        BankAccountJournalReportWithPeriodType(Date."Period Type"::Month, SortingBy::"Posting Date", CalcDate('<-CM>', WorkDate()));
    end;

    [Test]
    [HandlerFunctions('BankAccountJournalRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordYearBankAccountJournal()
    var
        Date: Record Date;
        SortingBy: Option "Posting Date","Document No.";
    begin
        // Purpose of the test is to validate Bank Account - OnAfterGetRecord with Period Type Year and sorting by Posting Date of the Report, ID: 10815, Bank Account Journal.
        BankAccountJournalReportWithPeriodType(Date."Period Type"::Year, SortingBy::"Posting Date", CalcDate('<-CY>', WorkDate()));
    end;

    [Test]
    [HandlerFunctions('BankAccountJournalRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordWeekBankAccountJournal()
    var
        Date: Record Date;
        SortingBy: Option "Posting Date","Document No.";
    begin
        // Purpose of the test is to validate Bank Account - OnAfterGetRecord with Period Type Week and sorting by Document No. of the Report, ID: 10815, Bank Account Journal.
        BankAccountJournalReportWithPeriodType(Date."Period Type"::Week, SortingBy::"Document No.", CalcDate('<-CW>', WorkDate()));
    end;

    [Test]
    [HandlerFunctions('BankAccountJournalRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordQuarterBankAccountJournal()
    var
        Date: Record Date;
        SortingBy: Option "Posting Date","Document No.";
    begin
        // Purpose of the test is to validate Bank Account - OnAfterGetRecord with Period Type Quarter and sorting by Document No. of the Report, ID: 10815, Bank Account Journal.
        BankAccountJournalReportWithPeriodType(Date."Period Type"::Quarter, SortingBy::"Document No.", CalcDate('<-CQ>', WorkDate()));
    end;

    local procedure BankAccountJournalReportWithPeriodType(PeriodType: Option; SortingBy: Option; PeriodStart: Date)
    var
        BankAccount: Record "Bank Account";
    begin
        // Setup.
        Initialize();
        CreateBankAccountWithDimension(BankAccount);
        CreateBankAccountLedgerEntry(BankAccount."No.", WorkDate());

        // Exercise: Run Bank Account Journal report with Period Type and Period Start.
        RunJournalReportWithPeriodType(PeriodType, SortingBy, PeriodStart, REPORT::"Bank Account Journal");

        // Verify: Verify the Bank Account No, Credit Amount and Debit Amount after running report Bank Account Journal.
        LibraryReportDataset.LoadDataSetFile();
        BankAccount.CalcFields("Debit Amount", "Credit Amount");
        VerifyReportCapAndValue(
          'Bank_Account_Ledger_Entry__Bank_Account_No__', BankAccount."No.",
          'Bank_Account_Ledger_Entry__Credit_Amount_', BankAccount."Credit Amount",
          'Bank_Account_Ledger_Entry__Debit_Amount_', BankAccount."Debit Amount");
    end;

    [Test]
    [HandlerFunctions('CustomerDetailTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CustomerDetailTrialBalanceEntryTypeCorrection()
    var
        Customer: Record Customer;
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // [SCENARIO 275554] "Customer Detail Trial Balance" Report includes detailed customer ledger entries of type "Correction of Remaining Amount"
        Initialize();

        // [GIVEN] Created Customer
        CreateCustomer(Customer);

        // [GIVEN] Detailed Customer Ledger Entry with "Posting Date" = 23-01-20, "Entry Type" = "Initial Entry"  and "Credit Amount (LCY)" = 100
        CreateDetailedCustomerLedgerEntry(CreateCustomerLedgerEntry(Customer."No.", WorkDate()));

        // [GIVEN] Detailed Customer Ledger Entry with "Posting Date" = 23-01-20, "Entry Type" = "Correction of Remaining Amount" and "Credit Amount (LCY)" = 50
        CreateDetailedCustomerLedgerEntryWithEntryType(
          CreateCustomerLedgerEntry(Customer."No.", WorkDate()),
          DetailedCustLedgEntry."Entry Type"::"Correction of Remaining Amount");

        // [WHEN] Run Report "Customer Detail Trial Balance" with "Date Filter" = 23-02-20
        RunTrialBalanceReport(
          Customer."No.", Format(CalcDate('<1M>', WorkDate())), false, Customer."Global Dimension 1 Code",
          REPORT::"Customer Detail Trial Balance");

        // [THEN] Row found for Customer where Field 'General Credit Amount (LCY)' = 150
        LibraryReportDataset.LoadDataSetFile();
        Customer.CalcFields("Credit Amount (LCY)");
        VerifyReportCapAndValue(
          CustomerNoCap, Customer."No.", PreviousCreditAmountLCYCap, Customer."Credit Amount (LCY)",
          GeneralCreditAmountLCYCap, Customer."Credit Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('VendorDetailTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VendorDetailTrialBalanceEntryTypeCorrection()
    var
        Vendor: Record Vendor;
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        // [SCENARIO 275554] "Vendor Detail Trial Balance" Report includes detailed Vendor ledger entries of type "Correction of Remaining Amount"
        Initialize();

        // [GIVEN] Created Vendor
        CreateVendor(Vendor);

        // [GIVEN] Detailed Vendor Ledger Entry with "Posting Date" = 23-01-20, "Entry Type" = "Initial Entry"  and "Credit Amount (LCY)" = 100
        CreateDetailedVendorLedgerEntry(CreateVendorLedgerEntry(Vendor."No.", WorkDate()));

        // [GIVEN] Detailed Vendor Ledger Entry with "Posting Date" = 23-01-20, "Entry Type" = "Correction of Remaining Amount" and "Credit Amount (LCY)" = 50
        CreateDetailedVendorLedgerEntryWithEntryType(
          CreateVendorLedgerEntry(Vendor."No.", WorkDate()),
          DetailedVendorLedgEntry."Entry Type"::"Correction of Remaining Amount");

        // [WHEN] Run Report "Vendor Detail Trial Balance FR" with "Date Filter" = 23-02-20
        RunTrialBalanceReport(
          Vendor."No.", Format(CalcDate('<1M>', WorkDate())), false, Vendor."Global Dimension 1 Code",
          REPORT::"Vendor Detail Trial Balance FR");

        // [THEN] Row found for Vendor where Field 'General Credit Amount (LCY)' = 150
        LibraryReportDataset.LoadDataSetFile();
        Vendor.CalcFields("Credit Amount (LCY)");
        VerifyReportCapAndValue(
          VendorNoCap, Vendor."No.", PreviousCreditAmountLCYCap, Vendor."Credit Amount (LCY)",
          GeneralCreditAmountLCYCap, Vendor."Credit Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('CustomerDetailTrialBalanceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerDetailTrialBalanceCanHandleDateInMiddleOfMonth()
    var
        Customer: Record Customer;
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        StartingDate: Date;
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 298434] Report 10806 works with Starting Date in the middle of a month
        Initialize();

        // [GIVEN] Created Customer
        CreateCustomer(Customer);

        // [GIVEN] Starting Date 10-10-2020
        StartingDate := CalcDate('<-CM>', WorkDate()) + LibraryRandom.RandInt(10);

        // [GIVEN] Detailed Customer Ledger Entry with "Posting Date" = 20-10-20, "Entry Type" = "Initial Entry"  and "Credit Amount (LCY)" = 100
        CreateDetailedCustomerLedgerEntry(CreateCustomerLedgerEntry(Customer."No.", StartingDate + LibraryRandom.RandInt(10)));
        DetailedCustLedgEntry.SetRange("Customer No.", Customer."No.");
        DetailedCustLedgEntry.FindFirst();

        Commit();

        // [WHEN] Run Report "Customer Detail Trial Balance" with "Date Filter" = '10-10-20..'
        RunTrialBalanceReport(
          Customer."No.", Format(StartingDate) + '..' + Format(CalcDate('<CY>', StartingDate)), false, Customer."Global Dimension 1 Code",
          REPORT::"Customer Detail Trial Balance");

        // [THEN] Row found for Customer where Field 'Credit Period Amount' = 100
        LibraryReportDataset.LoadDataSetFile();

        LibraryReportDataset.AssertElementWithValueExists('CreditPeriodAmount', DetailedCustLedgEntry."Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('VendorDetailTrialBalanceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorDetailTrialBalanceCanHandleDateInMiddleOfMonth()
    var
        Vendor: Record Vendor;
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        StartingDate: Date;
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO 298434] Report 10808 works with Starting Date in the middle of a month
        Initialize();

        // [GIVEN] Created Vendor
        CreateVendor(Vendor);

        // [GIVEN] Starting Date 10-10-2020
        StartingDate := CalcDate('<-CM>', WorkDate()) + LibraryRandom.RandInt(10);

        // [GIVEN] Detailed Vendor Ledger Entry with "Posting Date" = 20-10-20, "Entry Type" = "Initial Entry"  and "Credit Amount (LCY)" = 100
        CreateDetailedVendorLedgerEntry(CreateVendorLedgerEntry(Vendor."No.", StartingDate + LibraryRandom.RandInt(10)));
        DetailedVendorLedgEntry.SetRange("Vendor No.", Vendor."No.");
        DetailedVendorLedgEntry.FindFirst();

        Commit();

        // [WHEN] Run Report "Vendor Detail Trial Balance FR" with "Date Filter" = '10-10-20..'
        RunTrialBalanceReport(
          Vendor."No.", Format(StartingDate) + '..' + Format(CalcDate('<CY>', StartingDate)), false, Vendor."Global Dimension 1 Code",
          REPORT::"Vendor Detail Trial Balance FR");

        // [THEN] Row found for Vendor where Field 'Credit Period Amount' = 100
        LibraryReportDataset.LoadDataSetFile();

        LibraryReportDataset.AssertElementWithValueExists('CreditPeriodAmount', DetailedVendorLedgEntry."Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('BankAccountTrialBalanceSaveAsPDFRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PrintBankAccountTrialBalance()
    var
        BankAccount: Record "Bank Account";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 333888] Report "Purchase Advice" can be printed without RDLC rendering errors
        Initialize();
        CreateBankAccountWithDimension(BankAccount);
        CreateBankAccountLedgerEntry(BankAccount."No.", WorkDate());

        // [WHEN] Report "Purchase Advice" is being printed to PDF
        RunTrialBalanceReport(BankAccount."No.", Format(WorkDate()), false, '', REPORT::"Bank Account Trial Balance");
        // [THEN] No RDLC rendering errors
    end;

    [Test]
    [HandlerFunctions('BankAccountTrialBalanceExcelRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure BankAccountTrialBalanceExcel()
    var
        BankAccount: Record "Bank Account";
        FoundValue: Boolean;
    begin
        // [FEATURE] [Bank Account] [Excel]
        // [SCENARIO 398626] Bank Account Trial Balance report exported in Excel
        Initialize();

        // [GIVEN] Bank Account has entries with Debit Amount = 300 and Credit Amount = 100 on workdate
        CreateBankAccountWithDimension(BankAccount);
        CreateBankAccountLedgerEntry(BankAccount."No.", WorkDate());

        // [WHEN] Run Bank Account Trial Balance on workdate
        RunTrialBalanceReport(BankAccount."No.", Format(WorkDate()), false, '', REPORT::"Bank Account Trial Balance");  // PrintBankAccountsWithoutBalance FALSE.

        // [THEN] Debit Amount = 300, Credit Amount = 100, Debit End Balance = 200, Credit End Balance = 0
        LibraryReportValidation.OpenExcelFile();
        BankAccount.CalcFields("Debit Amount (LCY)", "Credit Amount (LCY)");
        Assert.AreEqual(
          Format(BankAccount."Debit Amount (LCY)"), LibraryReportValidation.GetValueAt(FoundValue, 11, 7), '');
        Assert.AreEqual(
          Format(BankAccount."Credit Amount (LCY)"), LibraryReportValidation.GetValueAt(FoundValue, 11, 8), '');
        Assert.AreEqual(
          Format(BankAccount."Debit Amount (LCY)" - BankAccount."Credit Amount (LCY)"),
          LibraryReportValidation.GetValueAt(FoundValue, 11, 9), '');
        Assert.AreEqual(
          '', LibraryReportValidation.GetValueAt(FoundValue, 11, 10), '');
    end;

    [Test]
    [HandlerFunctions('GLTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GLTrialBalRepShowsCorrectBeginningBalanceOfIncomeStatementGLAcc()
    var
        GLAccount: Record "G/L Account";
        DebitAmount: Decimal;
        CreditAmount: Decimal;
    begin
        // [SCENARIO 402709] "G/L Trial Balance" report shows correct beginning balance of the income statement G/L account

        Initialize();

        // [GIVEN] G/L account with "Income/Balance" = "Income Statement"
        CreateGLAccount(GLAccount);
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Income Statement");
        GLAccount.Modify(true);

        // [GIVEN] G/L account has debit balance of "X" and credit balance of "Y" in year 2020
        DebitAmount := LibraryRandom.RandDec(100, 2);
        CreditAmount := LibraryRandom.RandDec(100, 2);
        CreateGLEntryCustom(GLAccount."No.", CalcDate('<-1Y>', WorkDate()), DebitAmount, CreditAmount);

        // [WHEN] Run "G/L Trial Balance" report for year 2021
        RunGLTrialBalanceReport(GLAccount."No.", Format(WorkDate()), false);

        // [THEN] Exported beginning debit balance is "X" - "Y"
        // [THEN] Exported beginning credit balance is "Y" - "X"
        LibraryReportDataset.LoadDataSetFile();
        VerifyReportCapAndValue(
          GLAccountNoCap, GLAccount."No.", 'GLAcc2CreditAmtDebitAmt', CreditAmount - DebitAmount,
          'GLAcc2DebitAmtCreditAmt', DebitAmount - CreditAmount);
    end;

    local procedure Initialize()
    var
        PageDataPersonalization: Record "Page Data Personalization";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"UT REP Legal Report");
        LibraryVariableStorage.Clear();
        PageDataPersonalization.DeleteAll();
    end;

    local procedure CreateBankAccountWithDimension(var BankAccount: Record "Bank Account")
    begin
        BankAccount."No." := LibraryUtility.GenerateGUID();
        BankAccount."Global Dimension 1 Code" := CreateDimension();
        BankAccount.Insert();
    end;

    local procedure CreateBankAccountLedgerEntry(BankAccountNo: Code[20]; PostingDate: Date)
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccountLedgerEntry2: Record "Bank Account Ledger Entry";
    begin
        BankAccountLedgerEntry2.FindLast();
        BankAccountLedgerEntry."Entry No." := BankAccountLedgerEntry2."Entry No." + 1;
        BankAccountLedgerEntry."Bank Account No." := BankAccountNo;
        BankAccountLedgerEntry."Document Type" := BankAccountLedgerEntry."Document Type"::" ";
        BankAccountLedgerEntry."Document No." := LibraryUtility.GenerateGUID();
        BankAccountLedgerEntry."Source Code" := CreateSourceCode();
        BankAccountLedgerEntry.Amount := LibraryRandom.RandDec(100, 2);
        BankAccountLedgerEntry."Posting Date" := PostingDate;
        BankAccountLedgerEntry."Debit Amount (LCY)" := LibraryRandom.RandDecInRange(200, 300, 2);
        BankAccountLedgerEntry."Credit Amount (LCY)" := LibraryRandom.RandDecInRange(100, 200, 2);
        BankAccountLedgerEntry.Open := true;
        BankAccountLedgerEntry.Insert();
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    begin
        Customer."No." := LibraryUtility.GenerateGUID();
        Customer.Insert();
    end;

    local procedure CreateCustomerWithDimension(var Customer: Record Customer)
    begin
        Customer."No." := LibraryUtility.GenerateGUID();
        Customer."Global Dimension 1 Code" := CreateDimension();
        Customer.Insert();
    end;

    local procedure CreateCustomerLedgerEntry(CustomerNo: Code[20]; PostingDate: Date): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry2.FindLast();
        CustLedgerEntry."Entry No." := CustLedgerEntry2."Entry No." + 1;
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry."Document Type" := CustLedgerEntry."Document Type"::Invoice;
        CustLedgerEntry."Document No." := LibraryUtility.GenerateGUID();
        CustLedgerEntry."Source Code" := CreateSourceCode();
        CustLedgerEntry."Posting Date" := PostingDate;
        CustLedgerEntry."Due Date" := PostingDate;
        CustLedgerEntry."Date Filter" := PostingDate;
        CustLedgerEntry.Open := true;
        CustLedgerEntry.Insert();
        exit(CustLedgerEntry."Entry No.");
    end;

    local procedure CreateDetailedCustomerLedgerEntryWithEntryType(CustLedgerEntryNo: Integer; EntryType: Enum "Detailed CV Ledger Entry Type")
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DetailedCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        DetailedCustLedgEntry2.FindLast();
        CustLedgerEntry.Get(CustLedgerEntryNo);
        DetailedCustLedgEntry."Entry No." := DetailedCustLedgEntry2."Entry No." + 1;
        DetailedCustLedgEntry."Entry Type" := EntryType;
        DetailedCustLedgEntry."Document Type" := CustLedgerEntry."Document Type";
        DetailedCustLedgEntry."Customer No." := CustLedgerEntry."Customer No.";
        DetailedCustLedgEntry."Cust. Ledger Entry No." := CustLedgerEntry."Entry No.";
        DetailedCustLedgEntry.Amount := LibraryRandom.RandDec(100, 2);
        DetailedCustLedgEntry."Amount (LCY)" := DetailedCustLedgEntry.Amount;
        DetailedCustLedgEntry."Credit Amount (LCY)" := DetailedCustLedgEntry.Amount;
        DetailedCustLedgEntry."Posting Date" := CustLedgerEntry."Posting Date";
        DetailedCustLedgEntry.Insert(true);
    end;

    local procedure CreateDetailedCustomerLedgerEntry(CustLedgerEntryNo: Integer)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        CreateDetailedCustomerLedgerEntryWithEntryType(CustLedgerEntryNo, DetailedCustLedgEntry."Entry Type"::"Initial Entry");
    end;

    local procedure CreateVendorLedgerEntry(VendorNo: Code[20]; PostingDate: Date): Integer
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry2.FindLast();
        VendorLedgerEntry."Entry No." := VendorLedgerEntry2."Entry No." + 1;
        VendorLedgerEntry."Vendor No." := VendorNo;
        VendorLedgerEntry."Document Type" := VendorLedgerEntry."Document Type"::Invoice;
        VendorLedgerEntry."Document No." := LibraryUtility.GenerateGUID();
        VendorLedgerEntry."Source Code" := CreateSourceCode();
        VendorLedgerEntry."Posting Date" := PostingDate;
        VendorLedgerEntry."Due Date" := PostingDate;
        VendorLedgerEntry."Date Filter" := PostingDate;
        VendorLedgerEntry.Open := true;
        VendorLedgerEntry.Insert();
        exit(VendorLedgerEntry."Entry No.");
    end;

    local procedure CreateDetailedVendorLedgerEntryWithEntryType(VendorLedgEntryNo: Integer; EntryType: Enum "Detailed CV Ledger Entry Type")
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DetailedVendorLedgEntry2: Record "Detailed Vendor Ledg. Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.Get(VendorLedgEntryNo);
        DetailedVendorLedgEntry2.FindLast();
        DetailedVendorLedgEntry."Entry No." := DetailedVendorLedgEntry2."Entry No." + 1;
        DetailedVendorLedgEntry."Entry Type" := EntryType;
        DetailedVendorLedgEntry."Document Type" := VendorLedgerEntry."Document Type";
        DetailedVendorLedgEntry."Vendor No." := VendorLedgerEntry."Vendor No.";
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := VendorLedgerEntry."Entry No.";
        DetailedVendorLedgEntry.Amount := LibraryRandom.RandDec(100, 2);
        DetailedVendorLedgEntry."Amount (LCY)" := DetailedVendorLedgEntry.Amount;
        DetailedVendorLedgEntry."Credit Amount (LCY)" := DetailedVendorLedgEntry.Amount;
        DetailedVendorLedgEntry."Posting Date" := VendorLedgerEntry."Posting Date";
        DetailedVendorLedgEntry.Insert(true);
    end;

    local procedure CreateDetailedVendorLedgerEntry(VendorLedgEntryNo: Integer)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        CreateDetailedVendorLedgerEntryWithEntryType(VendorLedgEntryNo, DetailedVendorLedgEntry."Entry Type"::"Initial Entry");
    end;

    local procedure CreateDimension(): Code[20]
    var
        Dimension: Record Dimension;
    begin
        Dimension.Code := LibraryUtility.GenerateGUID();
        Dimension.Insert();
        exit(Dimension.Code);
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account")
    begin
        GLAccount."No." := LibraryUtility.GenerateGUID();
        GLAccount.Insert();
    end;

    local procedure CreateGLAccountWithDimension(var GLAccount: Record "G/L Account")
    begin
        CreateGLAccount(GLAccount);
        GLAccount."Global Dimension 1 Code" := CreateDimension();
        GLAccount.Modify();
    end;

    local procedure CreateGLEntry(GLAccountNo: Code[20]): Integer
    begin
        exit(
          CreateGLEntryWithAmounts(
            GLAccountNo, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2)));
    end;

    local procedure CreateGLEntryWithAmounts(GLAccountNo: Code[20]; DebitAmount: Decimal; CreditAmount: Decimal): Integer
    begin
        exit(CreateGLEntryCustom(GLAccountNo, WorkDate(), DebitAmount, CreditAmount));
    end;

    local procedure CreateGLEntryCustom(GLAccountNo: Code[20]; PostingDate: Date; DebitAmount: Decimal; CreditAmount: Decimal): Integer
    var
        GLEntry: Record "G/L Entry";
        GLEntry2: Record "G/L Entry";
    begin
        GLEntry2.FindLast();
        GLEntry."Entry No." := GLEntry2."Entry No." + 1;
        GLEntry."G/L Account No." := GLAccountNo;
        GLEntry."Document Type" := GLEntry."Document Type"::Invoice;
        GLEntry."Document No." := LibraryUtility.GenerateGUID();
        GLEntry."Source Code" := CreateSourceCode();
        GLEntry.Amount := LibraryRandom.RandDec(10, 2);
        GLEntry."Debit Amount" := DebitAmount;
        GLEntry."Credit Amount" := CreditAmount;
        GLEntry."Posting Date" := PostingDate;
        GLEntry.Insert();
        exit(GLEntry."Entry No.");
    end;

    local procedure CreateSourceCode(): Code[10]
    var
        SourceCode: Record "Source Code";
    begin
        SourceCode.Code := LibraryUtility.GenerateGUID();
        SourceCode.Insert();
        exit(SourceCode.Code);
    end;

    local procedure CreateVendor(var Vendor: Record Vendor)
    begin
        Vendor."No." := LibraryUtility.GenerateGUID();
        Vendor.Insert();
    end;

    local procedure CreateVendorWithDimension(var Vendor: Record Vendor)
    begin
        Vendor."No." := LibraryUtility.GenerateGUID();
        Vendor."Global Dimension 1 Code" := CreateDimension();
        Vendor.Insert();
    end;

    local procedure EnqueueValuesForRequestPageHandler(No: Variant; DateFilter: Variant; AccountWithoutBalance: Variant; DimensionCode: Variant)
    begin
        LibraryVariableStorage.Enqueue(No);
        LibraryVariableStorage.Enqueue(DateFilter);
        LibraryVariableStorage.Enqueue(AccountWithoutBalance);
        LibraryVariableStorage.Enqueue(DimensionCode);
    end;

    local procedure RunBankAccountDetailTrialBalanceReport(BankAccountNo: Code[20]; DateFilter: Text; DimensionCode: Code[20])
    begin
        // Enqueue values for use in BankAccountDetailTrialBalanceRequestPageHandler.
        LibraryVariableStorage.Enqueue(BankAccountNo);
        LibraryVariableStorage.Enqueue(DateFilter);
        LibraryVariableStorage.Enqueue(DimensionCode);
        REPORT.Run(REPORT::"Bank Acc. Detail Trial Balance");
    end;

    local procedure RunGLDetailTrialBalanceReport(GLAccountNo: Code[20]; DateFilter: Text; SummarizedBy: Option; DimensionCode: Code[20])
    begin
        // Enqueue values for use in GLDetailTrialBalanceRequestPageHandler.
        EnqueueValuesForRequestPageHandler(GLAccountNo, DateFilter, SummarizedBy, DimensionCode);
        REPORT.Run(REPORT::"G/L Detail Trial Balance");
    end;

    local procedure RunGLTrialBalanceReport(GLAccountNo: Code[20]; DateFilter: Text; PrintGLAccsWithoutBalance: Boolean)
    begin
        // Enqueue values for use in GLTrialBalanceRequestPageHandler.
        LibraryVariableStorage.Enqueue(GLAccountNo);
        LibraryVariableStorage.Enqueue(DateFilter);
        LibraryVariableStorage.Enqueue(PrintGLAccsWithoutBalance);
        REPORT.Run(REPORT::"G/L Trial Balance");
    end;

    local procedure RunJournalReportWithPeriodType(PeriodType: Option; SortingBy: Option; PeriodStart: Date; ReportID: Integer)
    begin
        // Enqueue values for use in CustomerJournalRequestPageHandler, VendorJournalRequestPageHandler, JournalRequestPageHandler,
        // GLJournalRequestPageHandler and BankAccountJournalRequestPageHandler.
        LibraryVariableStorage.Enqueue(PeriodType);
        LibraryVariableStorage.Enqueue(PeriodStart);
        LibraryVariableStorage.Enqueue(SortingBy);
        REPORT.Run(ReportID);
    end;

    local procedure RunTrialBalanceReport(VendorNo: Code[20]; DateFilter: Text; ExcludeBalanceOnly: Boolean; DimensionCode: Code[20]; ReportID: Integer)
    begin
        // Enqueue values for use in VendorDetailTrialBalanceRequestPageHandler.
        EnqueueValuesForRequestPageHandler(VendorNo, DateFilter, ExcludeBalanceOnly, DimensionCode);
        REPORT.Run(ReportID);
    end;

    local procedure VerifyNoAndCreditAmount(NoCap: Text[100]; No: Code[20]; CreditAmountLCYCap: Text[100]; CreditAmount: Decimal)
    begin
        LibraryReportDataset.AssertElementWithValueExists(NoCap, No);
        LibraryReportDataset.AssertElementWithValueExists(CreditAmountLCYCap, CreditAmount);
    end;

    local procedure VerifyReportCapAndValue(NoCap: Text[100]; No: Code[20]; DebitAmountLCYCap: Text[100]; DebitAmount: Decimal; CreditAmountLCYCap: Text[100]; CreditAmount: Decimal)
    begin
        VerifyNoAndCreditAmount(NoCap, No, CreditAmountLCYCap, CreditAmount);
        LibraryReportDataset.AssertElementWithValueExists(DebitAmountLCYCap, DebitAmount);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankAccountDetailTrialBalanceRequestPageHandler(var BankAccDetailTrialBalance: TestRequestPage "Bank Acc. Detail Trial Balance")
    var
        No: Variant;
        DateFilter: Variant;
        GlobalDimensionCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(DateFilter);
        LibraryVariableStorage.Dequeue(GlobalDimensionCode);
        BankAccDetailTrialBalance."Bank Account".SetFilter("No.", No);
        BankAccDetailTrialBalance."Bank Account".SetFilter("Date Filter", DateFilter);
        BankAccDetailTrialBalance."Bank Account".SetFilter("Global Dimension 1 Code", GlobalDimensionCode);
        BankAccDetailTrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankAccountJournalRequestPageHandler(var BankAccountJournal: TestRequestPage "Bank Account Journal")
    var
        PeriodType: Variant;
        PeriodStart: Variant;
        SortingBy: Variant;
    begin
        LibraryVariableStorage.Dequeue(PeriodType);
        LibraryVariableStorage.Dequeue(PeriodStart);
        LibraryVariableStorage.Dequeue(SortingBy);
        BankAccountJournal.Date.SetFilter("Period Type", Format(PeriodType));
        BankAccountJournal.Date.SetFilter("Period Start", Format(PeriodStart));
        BankAccountJournal."Posting Date".SetValue(SortingBy);
        BankAccountJournal.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankAccountTrialBalanceRequestPageHandler(var BankAccountTrialBalance: TestRequestPage "Bank Account Trial Balance")
    var
        No: Variant;
        DateFilter: Variant;
        GlobalDimensionCode: Variant;
        PrintBanksWithoutBalance: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(DateFilter);
        LibraryVariableStorage.Dequeue(PrintBanksWithoutBalance);
        LibraryVariableStorage.Dequeue(GlobalDimensionCode);
        BankAccountTrialBalance."Bank Account".SetFilter("No.", No);
        BankAccountTrialBalance."Bank Account".SetFilter("Date Filter", DateFilter);
        BankAccountTrialBalance."Bank Account".SetFilter("Global Dimension 1 Code", GlobalDimensionCode);
        BankAccountTrialBalance.PrintBanksWithoutBalance.SetValue(PrintBanksWithoutBalance);
        BankAccountTrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankAccountTrialBalanceSaveAsPDFRequestPageHandler(var BankAccountTrialBalance: TestRequestPage "Bank Account Trial Balance")
    var
        No: Variant;
        DateFilter: Variant;
        GlobalDimensionCode: Variant;
        PrintBanksWithoutBalance: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(DateFilter);
        LibraryVariableStorage.Dequeue(PrintBanksWithoutBalance);
        LibraryVariableStorage.Dequeue(GlobalDimensionCode);
        BankAccountTrialBalance."Bank Account".SetFilter("No.", No);
        BankAccountTrialBalance."Bank Account".SetFilter("Date Filter", DateFilter);
        BankAccountTrialBalance."Bank Account".SetFilter("Global Dimension 1 Code", GlobalDimensionCode);
        BankAccountTrialBalance.PrintBanksWithoutBalance.SetValue(PrintBanksWithoutBalance);
        BankAccountTrialBalance.SaveAsPdf(FileManagement.ServerTempFileName('.pdf'));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankAccountTrialBalanceExcelRequestPageHandler(var BankAccountTrialBalance: TestRequestPage "Bank Account Trial Balance")
    var
        No: Variant;
        DateFilter: Variant;
        GlobalDimensionCode: Variant;
        PrintBanksWithoutBalance: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(DateFilter);
        LibraryVariableStorage.Dequeue(PrintBanksWithoutBalance);
        LibraryVariableStorage.Dequeue(GlobalDimensionCode);
        BankAccountTrialBalance."Bank Account".SetFilter("No.", No);
        BankAccountTrialBalance."Bank Account".SetFilter("Date Filter", DateFilter);
        BankAccountTrialBalance."Bank Account".SetFilter("Global Dimension 1 Code", GlobalDimensionCode);
        BankAccountTrialBalance.PrintBanksWithoutBalance.SetValue(PrintBanksWithoutBalance);
        BankAccountTrialBalance.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerDetailTrialBalanceRequestPageHandler(var CustomerDetailTrialBalance: TestRequestPage "Customer Detail Trial Balance")
    var
        No: Variant;
        DateFilter: Variant;
        ExcludeBalanceOnly: Variant;
        GlobalDimensionCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(DateFilter);
        LibraryVariableStorage.Dequeue(ExcludeBalanceOnly);
        LibraryVariableStorage.Dequeue(GlobalDimensionCode);
        CustomerDetailTrialBalance.Customer.SetFilter("No.", No);
        CustomerDetailTrialBalance.Customer.SetFilter("Date Filter", DateFilter);
        CustomerDetailTrialBalance.Customer.SetFilter("Global Dimension 1 Code", GlobalDimensionCode);
        CustomerDetailTrialBalance.ExcludeBalanceOnly.SetValue(ExcludeBalanceOnly);
        CustomerDetailTrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerJournalRequestPageHandler(var CustomerJournal: TestRequestPage "Customer Journal")
    var
        PeriodType: Variant;
        PeriodStart: Variant;
        SortingBy: Variant;
    begin
        LibraryVariableStorage.Dequeue(PeriodType);
        LibraryVariableStorage.Dequeue(PeriodStart);
        LibraryVariableStorage.Dequeue(SortingBy);
        CustomerJournal.Date.SetFilter("Period Type", Format(PeriodType));
        CustomerJournal.Date.SetFilter("Period Start", Format(PeriodStart));
        CustomerJournal."Posting Date".SetValue(SortingBy);
        CustomerJournal.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerTrialBalanceRequestPageHandler(var CustomerTrialBalance: TestRequestPage "Customer Trial Balance FR")
    var
        No: Variant;
        DateFilter: Variant;
        GlobalDimensionCode: Variant;
        PrintCustomersWithoutBalance: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(DateFilter);
        LibraryVariableStorage.Dequeue(PrintCustomersWithoutBalance);
        LibraryVariableStorage.Dequeue(GlobalDimensionCode);
        CustomerTrialBalance.Customer.SetFilter("No.", No);
        CustomerTrialBalance.Customer.SetFilter("Date Filter", DateFilter);
        CustomerTrialBalance.Customer.SetFilter("Global Dimension 1 Code", GlobalDimensionCode);
        CustomerTrialBalance.PrintCustomersWithoutBalance.SetValue(PrintCustomersWithoutBalance);
        CustomerTrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerTrialBalanceDateFilterRequestPageHandler(var CustomerTrialBalance: TestRequestPage "Customer Trial Balance FR")
    begin
        CustomerTrialBalance.Customer.SetFilter("Date Filter", Format(WorkDate()));
        CustomerTrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLDetailTrialBalanceRequestPageHandler(var GLDetailTrialBalance: TestRequestPage "G/L Detail Trial Balance")
    var
        No: Variant;
        SummarizedBy: Variant;
        DateFilter: Variant;
        GlobalDimensionCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(DateFilter);
        LibraryVariableStorage.Dequeue(SummarizedBy);
        LibraryVariableStorage.Dequeue(GlobalDimensionCode);
        GLDetailTrialBalance."G/L Account".SetFilter("No.", No);
        GLDetailTrialBalance."G/L Account".SetFilter("Date Filter", DateFilter);
        GLDetailTrialBalance."G/L Account".SetFilter("Global Dimension 1 Code", GlobalDimensionCode);
        GLDetailTrialBalance.SummarizeBy.SetValue(SummarizedBy);
        GLDetailTrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLJournalRequestPageHandler(var GLJournals: TestRequestPage "G/L Journal")
    begin
        GLJournals.Date.SetFilter(
          "Period Start", StrSubstNo(RangeCap, Format(CalcDate('<-CM>', WorkDate())), Format(CalcDate('<CM>', WorkDate()))));
        GLJournals.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLTrialBalanceRequestPageHandler(var GLTrialBalance: TestRequestPage "G/L Trial Balance")
    var
        No: Variant;
        DateFilter: Variant;
        PrintGLAccsWithoutBalance: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(DateFilter);
        LibraryVariableStorage.Dequeue(PrintGLAccsWithoutBalance);
        GLTrialBalance."G/L Account".SetFilter("No.", No);
        GLTrialBalance."G/L Account".SetFilter("Date Filter", DateFilter);
        GLTrialBalance.PrintGLAccsWithoutBalance.SetValue(PrintGLAccsWithoutBalance);
        GLTrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JournalRequestPageHandler(var Journals: TestRequestPage Journals)
    var
        PeriodType: Variant;
        PeriodStart: Variant;
        SortingBy: Variant;
    begin
        LibraryVariableStorage.Dequeue(PeriodType);
        LibraryVariableStorage.Dequeue(PeriodStart);
        LibraryVariableStorage.Dequeue(SortingBy);
        Journals.Date.SetFilter("Period Type", Format(PeriodType));
        Journals.Date.SetFilter("Period Start", Format(PeriodStart));
        Journals."Posting Date".SetValue(SortingBy);
        Journals.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorDetailTrialBalanceRequestPageHandler(var VendorDetailTrialBalance: TestRequestPage "Vendor Detail Trial Balance FR")
    var
        No: Variant;
        DateFilter: Variant;
        ExcludeBalanceOnly: Variant;
        GlobalDimensionCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(DateFilter);
        LibraryVariableStorage.Dequeue(ExcludeBalanceOnly);
        LibraryVariableStorage.Dequeue(GlobalDimensionCode);
        VendorDetailTrialBalance.Vendor.SetFilter("No.", No);
        VendorDetailTrialBalance.Vendor.SetFilter("Date Filter", DateFilter);
        VendorDetailTrialBalance.Vendor.SetFilter("Global Dimension 1 Code", GlobalDimensionCode);
        VendorDetailTrialBalance.ExcludeBalanceOnly.SetValue(ExcludeBalanceOnly);
        VendorDetailTrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorJournalRequestPageHandler(var VendorJournal: TestRequestPage "Vendor Journal")
    var
        PeriodType: Variant;
        PeriodStart: Variant;
        SortingBy: Variant;
    begin
        LibraryVariableStorage.Dequeue(PeriodType);
        LibraryVariableStorage.Dequeue(PeriodStart);
        LibraryVariableStorage.Dequeue(SortingBy);
        VendorJournal.Date.SetFilter("Period Type", Format(PeriodType));
        VendorJournal.Date.SetFilter("Period Start", Format(PeriodStart));
        VendorJournal."Posting Date".SetValue(SortingBy);
        VendorJournal.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorTrialBalanceRequestPageHandler(var VendorTrialBalance: TestRequestPage "Vendor Trial Balance FR")
    var
        No: Variant;
        DateFilter: Variant;
        GlobalDimensionCode: Variant;
        PrintVendorsWithoutBalance: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(DateFilter);
        LibraryVariableStorage.Dequeue(PrintVendorsWithoutBalance);
        LibraryVariableStorage.Dequeue(GlobalDimensionCode);
        VendorTrialBalance.Vendor.SetFilter("No.", No);
        VendorTrialBalance.Vendor.SetFilter("Date Filter", DateFilter);
        VendorTrialBalance.Vendor.SetFilter("Global Dimension 1 Code", GlobalDimensionCode);
        VendorTrialBalance.PrintVendorsWithoutBalance.SetValue(PrintVendorsWithoutBalance);
        VendorTrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorTrialBalanceDateFilterRequestPageHandler(var VendorTrialBalance: TestRequestPage "Vendor Trial Balance FR")
    begin
        VendorTrialBalance.Vendor.SetFilter("Date Filter", Format(WorkDate()));
        VendorTrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

