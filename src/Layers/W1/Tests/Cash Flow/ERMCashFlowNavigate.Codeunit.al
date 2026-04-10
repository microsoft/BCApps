codeunit 134559 "ERM Cash Flow Navigate"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Cash Flow] [Show Source] [UI]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryCashFlowForecast: Codeunit "Library - Cash Flow";
        CFHelper: Codeunit "Library - Cash Flow Helper";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        ExpectedNo: Code[20];
        ExpectedBudgetName: Code[10];
        ExpectedDescription: Text;
        MaxSourceType: Integer;
        FirstRevenueCodeTxt: Label 'REV0000001';
        FirstExpenseCodeTxt: Label 'EXP0000001';
        SecondRevenueCodeTxt: Label 'REV0000002';
        SecondExpenseCodeTxt: Label 'EXP0000002';
        IsInitialized: Boolean;

    [Normal]
    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Cash Flow Navigate");
        MaxSourceType := 11;

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Cash Flow Navigate");
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Cash Flow Navigate");
    end;

    [Test]
    [HandlerFunctions('GLAccountPageHandler')]
    [Scope('OnPrem')]
    procedure NavigateJournalLiquidFunds()
    var
        CFAccount: Record "Cash Flow Account";
        GLAccount: Record "G/L Account";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        CashFlowJournal: TestPage "Cash Flow Worksheet";
    begin
        Initialize();

        CFHelper.FindCFLiquidFundAccount(CFAccount);
        CFHelper.FindFirstGLAccFromCFAcc(GLAccount, CFAccount);
        GLAccount.Next(LibraryRandom.RandInt(GLAccount.Count));
        ExpectedNo := GLAccount."No.";

        InsertJournalLine(CFWorksheetLine, CFWorksheetLine."Source Type"::"Liquid Funds", GLAccount."No.");

        // Navigate
        CashFlowJournal.OpenEdit();
        CashFlowJournal.ShowSource.Invoke();
        CashFlowJournal.Close();
        // Verification is done in modal handler function
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NavigateJournalLiquidFundsNonExistingAccNo()
    var
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        GLAccount: Record "G/L Account";
    begin
        // Setup
        Initialize();

        // Exercise and Verify
        NavigateJournalNonExistingSourceNo('', GLAccount.TableCaption(), CFWorksheetLine."Source Type"::"Liquid Funds");
    end;

    [Test]
    [HandlerFunctions('GLBudgetPageHandler')]
    [Scope('OnPrem')]
    procedure NavigateJournalGLBudget()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        GLBudgetEntry: Record "G/L Budget Entry";
        CashFlowJournal: TestPage "Cash Flow Worksheet";
    begin
        // Suggest lines should set source type accordingly

        // Setup
        Initialize();
        CFHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        CashFlowForecast.Validate("G/L Budget From", WorkDate());
        CashFlowForecast.Validate("G/L Budget To", WorkDate());
        CashFlowForecast.Modify(true);
        CFHelper.CreateBudgetEntry(GLBudgetEntry, CashFlowForecast."G/L Budget To");
        ExpectedNo := GLBudgetEntry."G/L Account No.";
        ExpectedBudgetName := GLBudgetEntry."Budget Name";

        // Exercise
        InsertJournalLine(CFWorksheetLine, CFWorksheetLine."Source Type"::"G/L Budget", GLBudgetEntry."G/L Account No.");
        CFWorksheetLine.Validate("G/L Budget Name", GLBudgetEntry."Budget Name");
        CFWorksheetLine.Modify(true);

        // Navigate
        CashFlowJournal.OpenEdit();
        CashFlowJournal.ShowSource.Invoke();
        CashFlowJournal.Close();
        // Verification is done in modal handler function
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NavigateJournalGLBudgetNonExistingAccNo()
    var
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        GLAccount: Record "G/L Account";
    begin
        // Setup
        Initialize();

        // Exercise and Verify
        NavigateJournalNonExistingSourceNo('', GLAccount.TableCaption(), CFWorksheetLine."Source Type"::"G/L Budget");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NavigateJournalNonExistingBudgetName()
    var
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        GLAccount: Record "G/L Account";
        GLBudgetName: Record "G/L Budget Name";
        CashFlowJournal: TestPage "Cash Flow Worksheet";
        NonExistingName: Code[10];
    begin
        // Setup
        NonExistingName :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(GLBudgetName.FieldNo(Name), DATABASE::"G/L Budget Name"), 1, MaxStrLen(GLBudgetName.Name));
        GLAccount.FindSet();
        GLAccount.Next(LibraryRandom.RandInt(GLAccount.Count));
        InsertJournalLine(CFWorksheetLine, CFWorksheetLine."Source Type"::"G/L Budget", GLAccount."No.");
        CFWorksheetLine."G/L Budget Name" := NonExistingName;
        CFWorksheetLine.Modify();

        // Exercise
        CashFlowJournal.OpenView();
        asserterror CashFlowJournal.ShowSource.Invoke();

        // Verify
        Assert.ExpectedError(
          StrSubstNo('Source data does not exist for %1: %2.', CFWorksheetLine.FieldCaption("G/L Budget Name"), NonExistingName));

        // Tear down
        CashFlowJournal.Close();
    end;

    [Test]
    [HandlerFunctions('CustomerLedgerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure NavigateJournalCustLE()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        CashFlowJournal: TestPage "Cash Flow Worksheet";
    begin
        Initialize();

        CustLedgerEntry.FindSet();
        CustLedgerEntry.Next(LibraryRandom.RandInt(CustLedgerEntry.Count));
        ExpectedNo := CustLedgerEntry."Document No.";

        InsertJournalLine(CFWorksheetLine, CFWorksheetLine."Source Type"::Receivables, CustLedgerEntry."Document No.");

        // Navigate
        CashFlowJournal.OpenEdit();
        CashFlowJournal.ShowSource.Invoke();
        CashFlowJournal.Close();
        // Verification is done in modal handler function
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NavigateJournalCustLENonExistingDocNo()
    var
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        // Setup
        Initialize();

        // Exercise and Verify
        NavigateJournalNonExistingSourceNo(
          CustLedgEntry.TableCaption(), CustLedgEntry.FieldCaption("Document No."), CFWorksheetLine."Source Type"::Receivables);
    end;

    [Test]
    [HandlerFunctions('VendorLedgerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure NavigateJournalVendLE()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        CashFlowJournal: TestPage "Cash Flow Worksheet";
    begin
        Initialize();

        VendLedgEntry.FindSet();
        VendLedgEntry.Next(LibraryRandom.RandInt(VendLedgEntry.Count));
        ExpectedNo := VendLedgEntry."Document No.";

        InsertJournalLine(CFWorksheetLine, CFWorksheetLine."Source Type"::Payables, VendLedgEntry."Document No.");

        // Navigate
        CashFlowJournal.OpenEdit();
        CashFlowJournal.ShowSource.Invoke();
        CashFlowJournal.Close();

        // Verification is done in modal handler function
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NavigateJournalVendLENonExistingDocNo()
    var
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        // Setup
        Initialize();

        // Exercise and Verify
        NavigateJournalNonExistingSourceNo(
          VendLedgEntry.TableCaption(), VendLedgEntry.FieldCaption("Document No."), CFWorksheetLine."Source Type"::Payables);
    end;

    [Test]
    [HandlerFunctions('SalesOrderPageHandler')]
    [Scope('OnPrem')]
    procedure NavigateJournalSO()
    var
        SalesHeader: Record "Sales Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        CashFlowJournal: TestPage "Cash Flow Worksheet";
    begin
        // Setup
        Initialize();
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader.Insert(true);
        ExpectedNo := SalesHeader."No.";
        InsertJournalLine(CFWorksheetLine, CFWorksheetLine."Source Type"::"Sales Orders", SalesHeader."No.");

        // Exercise
        CashFlowJournal.OpenView();
        CashFlowJournal.ShowSource.Invoke();

        // Verify - done in SalesOrderPageHandler

        // Tear down
        CashFlowJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NavigateJournalSOToNonExistingSO()
    var
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        SalesOrders: Page "Sales Orders";
    begin
        // Setup
        Initialize();

        // Exercise and Verify
        NavigateJournalNonExistingSourceNo('', SalesOrders.Caption, CFWorksheetLine."Source Type"::"Sales Orders");
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderPageHandler')]
    [Scope('OnPrem')]
    procedure NavigateJournalPO()
    var
        PurchaseHeader: Record "Purchase Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        CashFlowJournal: TestPage "Cash Flow Worksheet";
    begin
        // Setup
        Initialize();
        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader.Insert(true);
        ExpectedNo := PurchaseHeader."No.";
        InsertJournalLine(CFWorksheetLine, CFWorksheetLine."Source Type"::"Purchase Orders", PurchaseHeader."No.");

        // Exercise
        CashFlowJournal.OpenView();
        CashFlowJournal.ShowSource.Invoke();

        // Verify - done in PurchaseOrderPageHandler

        // Tear down
        CashFlowJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NavigateJournalPOToNonExistingPO()
    var
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        PurchaseOrders: Page "Purchase Orders";
    begin
        // Setup
        Initialize();

        // Exercise and Verify
        NavigateJournalNonExistingSourceNo('', PurchaseOrders.Caption, CFWorksheetLine."Source Type"::"Purchase Orders");
    end;

    [Test]
    [HandlerFunctions('ServiceOrderPageHandler')]
    [Scope('OnPrem')]
    procedure NavigateJournalServO()
    var
        ServiceHeader: Record "Service Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        CashFlowJournal: TestPage "Cash Flow Worksheet";
    begin
        // Setup
        Initialize();
        ServiceHeader.Init();
        ServiceHeader."Document Type" := ServiceHeader."Document Type"::Order;
        ServiceHeader.Insert(true);
        ExpectedNo := ServiceHeader."No.";
        InsertJournalLine(CFWorksheetLine, CFWorksheetLine."Source Type"::"Service Orders", ServiceHeader."No.");

        // Exercise
        CashFlowJournal.OpenView();
        CashFlowJournal.ShowSource.Invoke();

        // Verify - done in ServiceOrderPageHandler

        // Tear down
        CashFlowJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NavigateJournalServOToNonExistingServO()
    var
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ServiceOrders: Page "Service Orders";
    begin
        // Setup
        Initialize();

        // Exercise and Verify
        NavigateJournalNonExistingSourceNo('', ServiceOrders.Caption,
          CFWorksheetLine."Source Type"::"Service Orders");
    end;

    local procedure NavigateJournalNonExistingSourceNo(SourceTableCaption: Text[250]; SourceCaption: Text[250]; SourceType: Enum "Cash Flow Source Type")
    var
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        CashFlowJournal: TestPage "Cash Flow Worksheet";
        NonExistingNo: Code[20];
    begin
        // Setup
        NonExistingNo := 'notexist';
        InsertJournalLine(CFWorksheetLine, SourceType, '');
        CFWorksheetLine."Source No." := NonExistingNo;
        CFWorksheetLine.Modify();

        // Exercise
        CashFlowJournal.OpenView();
        asserterror CashFlowJournal.ShowSource.Invoke();

        // Verify
        if SourceTableCaption = '' then
            Assert.ExpectedError(
              StrSubstNo('Source data does not exist for %1: %2.', SourceCaption, NonExistingNo))
        else
            Assert.ExpectedError(
              StrSubstNo('Source data does not exist in %1 for %2: %3.', SourceTableCaption, SourceCaption, NonExistingNo));

        // Tear down
        CashFlowJournal.Close();
    end;

    [Test]
    [HandlerFunctions('CFManualRevenuePageHandler')]
    [Scope('OnPrem')]
    procedure NavigateJournalManRevenue()
    var
        CFAccount: Record "Cash Flow Account";
        CFManualRevenue: Record "Cash Flow Manual Revenue";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        CashFlowJournal: TestPage "Cash Flow Worksheet";
    begin
        // Setup
        Initialize();
        LibraryCashFlowForecast.FindCashFlowAccount(CFAccount);
        LibraryCashFlowForecast.CreateManualLineRevenue(CFManualRevenue, CFAccount."No.");
        ExpectedNo := CFManualRevenue.Code;
        ExpectedDescription := CFManualRevenue.Description;
        InsertJournalLine(CFWorksheetLine, CFWorksheetLine."Source Type"::"Cash Flow Manual Revenue", ExpectedNo);

        // Exercise
        CashFlowJournal.OpenView();
        CashFlowJournal.ShowSource.Invoke();

        // Verify - done in CFManualRevenuePageHandler

        // Tear down
        CashFlowJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NavigateJournalManRevenueToNonExistingManRevenue()
    var
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        CFManualRevenues: Page "Cash Flow Manual Revenues";
    begin
        // Setup
        Initialize();

        // Exercise and Verify
        NavigateJournalNonExistingSourceNo('', CFManualRevenues.Caption,
          CFWorksheetLine."Source Type"::"Cash Flow Manual Revenue");
    end;

    [Test]
    [HandlerFunctions('CFManualExpensePageHandler')]
    [Scope('OnPrem')]
    procedure NavigateJournalManExpense()
    var
        CFAccount: Record "Cash Flow Account";
        CFManualExpense: Record "Cash Flow Manual Expense";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        CashFlowJournal: TestPage "Cash Flow Worksheet";
    begin
        // Setup
        Initialize();
        LibraryCashFlowForecast.FindCashFlowAccount(CFAccount);
        LibraryCashFlowForecast.CreateManualLinePayment(CFManualExpense, CFAccount."No.");
        ExpectedNo := CFManualExpense.Code;
        ExpectedDescription := CFManualExpense.Description;
        InsertJournalLine(CFWorksheetLine, CFWorksheetLine."Source Type"::"Cash Flow Manual Expense", ExpectedNo);

        // Exercise
        CashFlowJournal.OpenView();
        CashFlowJournal.ShowSource.Invoke();

        // Verify - done in CFManualExpensePageHandler

        // Tear down
        CashFlowJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NavigateJournalManExpenseToNonExistingManExpense()
    var
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        CFManualExpenses: Page "Cash Flow Manual Expenses";
    begin
        // Setup
        Initialize();

        // Exercise and Verify
        NavigateJournalNonExistingSourceNo('', CFManualExpenses.Caption,
          CFWorksheetLine."Source Type"::"Cash Flow Manual Expense");
    end;

    [Test]
    [HandlerFunctions('FixedAssetCardPageHandler')]
    [Scope('OnPrem')]
    procedure NavigateJournalBudgetedFA()
    var
        FixedAsset: Record "Fixed Asset";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        CashFlowJournal: TestPage "Cash Flow Worksheet";
    begin
        // Setup
        Initialize();
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        ExpectedNo := FixedAsset."No.";
        InsertJournalLine(CFWorksheetLine, CFWorksheetLine."Source Type"::"Fixed Assets Budget", ExpectedNo);

        // Exercise
        CashFlowJournal.OpenView();
        CashFlowJournal.ShowSource.Invoke();

        // Verify - done in FixedAssetCardPageHandler

        // Tear down
        CashFlowJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NavigateJournalBudgetedFAToNonExistingFA()
    var
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        FixedAsset: Record "Fixed Asset";
    begin
        // Setup
        Initialize();

        // Exercise and Verify
        NavigateJournalNonExistingSourceNo(FixedAsset.TableCaption(), FixedAsset.FieldCaption("No."),
          CFWorksheetLine."Source Type"::"Fixed Assets Budget");
    end;

    [Test]
    [HandlerFunctions('FixedAssetCardPageHandler')]
    [Scope('OnPrem')]
    procedure NavigateJournalSaleFA()
    var
        FixedAsset: Record "Fixed Asset";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        CashFlowJournal: TestPage "Cash Flow Worksheet";
    begin
        // Setup
        Initialize();
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        ExpectedNo := FixedAsset."No.";
        InsertJournalLine(CFWorksheetLine, CFWorksheetLine."Source Type"::"Fixed Assets Disposal", ExpectedNo);

        // Exercise
        CashFlowJournal.OpenView();
        CashFlowJournal.ShowSource.Invoke();

        // Verify - done in FixedAssetCardPageHandler

        // Tear down
        CashFlowJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NavigateJournalSaleFAToNonExistingFA()
    var
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        FixedAsset: Record "Fixed Asset";
    begin
        // Setup
        Initialize();

        // Exercise and Verify
        NavigateJournalNonExistingSourceNo(FixedAsset.TableCaption(), FixedAsset.FieldCaption("No."),
          CFWorksheetLine."Source Type"::"Fixed Assets Budget");
    end;

    [Test]
    [HandlerFunctions('SalesOrderPageHandler')]
    [Scope('OnPrem')]
    procedure NavigateEntriesSO()
    var
        SalesHeader: Record "Sales Header";
        CFForecastEntry: Record "Cash Flow Forecast Entry";
        CFLedgerEntries: TestPage "Cash Flow Forecast Entries";
    begin
        // Setup
        Initialize();
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader.Insert(true);
        ExpectedNo := SalesHeader."No.";
        InsertEntryLine(CFForecastEntry, CFForecastEntry."Source Type"::"Sales Orders", SalesHeader."No.");

        // Exercise
        CFLedgerEntries.OpenView();
        CFLedgerEntries.ShowSource.Invoke();

        // Verify - done in SalesOrderPageHandler

        // Tear down
        CFLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NavigateEntriesSOToNonExistingSO()
    var
        CFForecastEntry: Record "Cash Flow Forecast Entry";
        SourceType: Enum "Cash Flow Source Type";
    begin
        // Setup
        Initialize();

        // Exercise and Verify
        NavigateEntriesNonExistingSourceNo(Format(SourceType::"Sales Orders"), CFForecastEntry."Source Type"::"Sales Orders");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NavigateJournalBlankBudgetName()
    var
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        GLAccount: Record "G/L Account";
        CashFlowJournal: TestPage "Cash Flow Worksheet";
    begin
        InsertJournalLine(
          CFWorksheetLine, CFWorksheetLine."Source Type"::"G/L Budget",
          CopyStr(
            LibraryUtility.GenerateRandomCode(GLAccount.FieldNo("No."), DATABASE::"G/L Account"), 1, MaxStrLen(CFWorksheetLine."Source No.")));
        CFWorksheetLine."G/L Budget Name" := '';
        CFWorksheetLine.Modify();

        // Navigate
        CashFlowJournal.OpenEdit();
        asserterror CashFlowJournal.ShowSource.Invoke();
        Assert.ExpectedError(StrSubstNo('%1 must have a value', CFWorksheetLine.FieldCaption("G/L Budget Name")));

        // Tear down
        CashFlowJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NavigateJournalBlankSourceNo()
    var
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        CashFlowJournal: TestPage "Cash Flow Worksheet";
    begin
        InsertJournalLine(CFWorksheetLine, "Cash Flow Source Type".FromInteger(LibraryRandom.RandIntInRange(1, MaxSourceType)), '');

        // Navigate
        CashFlowJournal.OpenEdit();
        asserterror CashFlowJournal.ShowSource.Invoke();
        Assert.ExpectedError('Source No. must have a value');

        // Tear down
        CashFlowJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NavigateJournalBlankSourceType()
    var
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        CashFlowJournal: TestPage "Cash Flow Worksheet";
    begin
        InsertJournalLine(CFWorksheetLine, "Cash Flow Source Type"::" ", '');

        // Navigate
        CashFlowJournal.OpenEdit();
        asserterror CashFlowJournal.ShowSource.Invoke();
        Assert.ExpectedError('Source Type must not be   in Cash Flow');

        // Tear down
        CashFlowJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NavigateEntriesBlankBudgetName()
    var
        CFForecastEntry: Record "Cash Flow Forecast Entry";
        GLAccount: Record "G/L Account";
        CFLedgerEntries: TestPage "Cash Flow Forecast Entries";
    begin
        InsertEntryLine(
          CFForecastEntry, CFForecastEntry."Source Type"::"G/L Budget",
          CopyStr(
            LibraryUtility.GenerateRandomCode(GLAccount.FieldNo("No."), DATABASE::"G/L Account"), 1, MaxStrLen(CFForecastEntry."Source No.")));

        // Navigate
        CFLedgerEntries.OpenView();
        asserterror CFLedgerEntries.ShowSource.Invoke();
        Assert.ExpectedError(StrSubstNo('%1 must have a value', CFForecastEntry.FieldCaption("G/L Budget Name")));

        // Tear down
        CFLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NavigateEntriesBlankSourceNo()
    var
        CFForecastEntry: Record "Cash Flow Forecast Entry";
        CFLedgerEntries: TestPage "Cash Flow Forecast Entries";
    begin
        InsertEntryLine(CFForecastEntry, "Cash Flow Source Type".FromInteger(LibraryRandom.RandIntInRange(1, MaxSourceType)), '');

        // Navigate
        CFLedgerEntries.OpenView();
        asserterror CFLedgerEntries.ShowSource.Invoke();
        Assert.ExpectedError('Source No. must have a value');

        // Tear down
        CFLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NavigateEntriesBlankSourceType()
    var
        CFForecastEntry: Record "Cash Flow Forecast Entry";
        CFLedgerEntries: TestPage "Cash Flow Forecast Entries";
    begin
        InsertEntryLine(CFForecastEntry, "Cash Flow Source Type"::" ", '');

        // Navigate
        CFLedgerEntries.OpenView();
        asserterror CFLedgerEntries.ShowSource.Invoke();
        Assert.ExpectedError('Source Type must not be   in Cash Flow');

        // Tear down
        CFLedgerEntries.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InsertNewCashFlowManualRevenues()
    var
        CashFlowManualRevenue: Record "Cash Flow Manual Revenue";
        StartingDate: Date;
    begin
        // [SCENARIO 200778] Field "code" incremented by 1 when new record on Cash Flow Manual Revenues Page inserted
        // [FEATURE] [UT]
        CashFlowManualRevenue.DeleteAll();

        // [GIVEN] New CashFlowManualRevenue record "R1" on Cash Flow Manual Revenues Page
        StartingDate := LibraryRandom.RandDate(10);
        InsertNewCashFlowManualRevenueRecordOnPage(StartingDate);

        // [WHEN] Insert next record "R2" on Cash Flow Manual Revenues Page with earlier date
        InsertNewCashFlowManualRevenueRecordOnPage(StartingDate - 1);

        // [THEN] "R1".Field "Code" = 'REV0000001'
        Assert.RecordCount(CashFlowManualRevenue, 2);
        CashFlowManualRevenue.FindSet();
        CashFlowManualRevenue.TestField(Code, FirstRevenueCodeTxt);

        // [THEN] "R2".Field "Code" = 'REV0000002'
        CashFlowManualRevenue.Next();
        CashFlowManualRevenue.TestField(Code, SecondRevenueCodeTxt);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InsertNewCashFlowManualExpenses()
    var
        CashFlowManualExpense: Record "Cash Flow Manual Expense";
        StartingDate: Date;
    begin
        // [SCENARIO 200778] Field "code" incremented by 1 when new record on Cash Flow Manual Expences Page inserted
        // [FEATURE] [UT]
        CashFlowManualExpense.DeleteAll();

        // [GIVEN] New CashFlowManualExpence record "E1" on Cash Flow Manual Expences Page
        StartingDate := LibraryRandom.RandDate(10);
        InsertNewCashFlowManualExpenseRecordOnPage(StartingDate);

        // [WHEN] Insert next record "E2" on Cash Flow Manual Expenses Page with earlier date
        InsertNewCashFlowManualExpenseRecordOnPage(StartingDate - 1);

        // [THEN] "E1".Field "Code" = 'EXP0000001'
        Assert.RecordCount(CashFlowManualExpense, 2);
        CashFlowManualExpense.FindSet();
        CashFlowManualExpense.TestField(Code, FirstExpenseCodeTxt);

        // [THEN] "E2".Field "Code" = 'EXP0000002'
        CashFlowManualExpense.Next();
        CashFlowManualExpense.TestField(Code, SecondExpenseCodeTxt);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InsertNewCashFlowManualRevenuesWithoutAccount()
    var
        CashFlowManualRevenue: Record "Cash Flow Manual Revenue";
        CashFlowAccount: Record "Cash Flow Account";
    begin
        // [SCENARIO 200778] Code is not assigned when new record on Cash Flow Manual Revenues Page inserted without CashFlow Account record
        // [FEATURE] [UT]
        CashFlowManualRevenue.DeleteAll();
        CashFlowAccount.DeleteAll();

        // [WHEN] New CashFlowManualRevenue record on Cash Flow Manual Revenues Page inserted
        InsertNewCashFlowManualRevenueRecordOnPage(WorkDate() - 1);

        // [THEN] "Code" is not assigned, "Starting Date" is not changed
        Assert.RecordCount(CashFlowManualRevenue, 1);
        CashFlowManualRevenue.FindFirst();
        CashFlowManualRevenue.TestField(Code, '');
        CashFlowManualRevenue.TestField("Starting Date", WorkDate() - 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InsertNewCashFlowManualExpensesWithoutAccount()
    var
        CashFlowManualExpense: Record "Cash Flow Manual Expense";
        CashFlowAccount: Record "Cash Flow Account";
    begin
        // [SCENARIO 200778] Code is not assigned when new record on Cash Flow Manual Expenses Page inserted without CashFlow Account record
        // [FEATURE] [UT]
        CashFlowManualExpense.DeleteAll();
        CashFlowAccount.DeleteAll();

        // [WHEN] New CashFlowManualExpence record on Cash Flow Manual Expences Page inserted
        InsertNewCashFlowManualExpenseRecordOnPage(WorkDate() - 1);

        // [THEN] "Code" is not assigned, "Starting Date" is not changed
        Assert.RecordCount(CashFlowManualExpense, 1);
        CashFlowManualExpense.FindFirst();
        CashFlowManualExpense.TestField(Code, '');
        CashFlowManualExpense.TestField("Starting Date", WorkDate() - 1);
    end;

    [Test]
    [HandlerFunctions('VerifyGLBudgetPageHandler')]
    [Scope('OnPrem')]
    procedure NavigateJournalGLBudgetNotSavedValueOfGLAccNo()
    begin
        // [FEATURE] [UT] [Budget]
        // [SCENARIO 269334] Page Budget use value of G/L Account Filter from function SetGLAccountFilter
        Initialize();

        OpenBudgetPageWithGLAccountFilter();
        OpenBudgetPageWithGLAccountFilter();
        // Verification in modal handler function
    end;

    local procedure NavigateEntriesNonExistingSourceNo(SourceCaption: Text; SourceType: Enum "Cash Flow Source Type")
    var
        CFForecastEntry: Record "Cash Flow Forecast Entry";
        CFLedgerEntries: TestPage "Cash Flow Forecast Entries";
        NonExistingNo: Code[20];
    begin
        // Setup
        NonExistingNo := 'notexist';
        InsertEntryLine(CFForecastEntry, SourceType, NonExistingNo);

        // Exercise
        CFLedgerEntries.OpenView();
        asserterror CFLedgerEntries.ShowSource.Invoke();

        // Verify
        Assert.ExpectedError(
          StrSubstNo('Source data does not exist for %1: %2.', SourceCaption, NonExistingNo));

        // Tear down
        CFLedgerEntries.Close();
    end;

    local procedure InsertNewCashFlowManualRevenueRecordOnPage(StartingDate: Date)
    var
        CashFlowManualRevenues: TestPage "Cash Flow Manual Revenues";
    begin
        CashFlowManualRevenues.OpenNew();
        CashFlowManualRevenues.Description.SetValue(LibraryUtility.GenerateGUID());
        CashFlowManualRevenues."Starting Date".SetValue(StartingDate);
        CashFlowManualRevenues.Close();
    end;

    local procedure InsertNewCashFlowManualExpenseRecordOnPage(StartingDate: Date)
    var
        CashFlowManualExpenses: TestPage "Cash Flow Manual Expenses";
    begin
        CashFlowManualExpenses.OpenNew();
        CashFlowManualExpenses.Description.SetValue(LibraryUtility.GenerateGUID());
        CashFlowManualExpenses."Starting Date".SetValue(StartingDate);
        CashFlowManualExpenses.Close();
    end;

    local procedure InsertJournalLine(var CFWorksheetLine: Record "Cash Flow Worksheet Line"; SourceType: Enum "Cash Flow Source Type"; SourceNo: Code[20])
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CashFlowAccount: Record "Cash Flow Account";
        GLBudgetName: Record "G/L Budget Name";
    begin
        // Empty all journal lines
        CFWorksheetLine.DeleteAll();

        // Find data
        LibraryCashFlowForecast.FindCashFlowCard(CashFlowForecast);
        LibraryCashFlowForecast.FindCashFlowAccount(CashFlowAccount);
        LibraryCashFlowForecast.CreateJournalLine(CFWorksheetLine, CashFlowForecast."No.", CashFlowAccount."No.");

        // Insert into journal
        CFWorksheetLine.Validate("Source Type", SourceType);
        CFWorksheetLine.Validate("Source No.", SourceNo);
        if CFWorksheetLine."Source Type" = CFWorksheetLine."Source Type"::"G/L Budget" then begin
            GLBudgetName.FindSet();
            GLBudgetName.Next(LibraryRandom.RandInt(GLBudgetName.Count));
            CFWorksheetLine."G/L Budget Name" := GLBudgetName.Name;
        end;
        CFWorksheetLine.Modify(true);
    end;

    local procedure InsertEntryLine(var CFForecastEntry: Record "Cash Flow Forecast Entry"; SourceType: Enum "Cash Flow Source Type"; SourceNo: Code[20])
    begin
        CFForecastEntry.DeleteAll();

        CFForecastEntry.Init();
        CFForecastEntry."Entry No." := 1;
        CFForecastEntry."Source No." := SourceNo;
        CFForecastEntry."Source Type" := SourceType;
        CFForecastEntry.Insert();
    end;

    local procedure OpenBudgetPageWithGLAccountFilter()
    var
        Budget: Page Budget;
        GLAccountNo: Code[20];
    begin
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        LibraryVariableStorage.Enqueue(GLAccountNo);
        Budget.SetGLAccountFilter(GLAccountNo);
        Budget.Run();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CustomerLedgerEntriesPageHandler(var CustomerLedgerEntries: TestPage "Customer Ledger Entries")
    begin
        Assert.AreEqual(ExpectedNo, CustomerLedgerEntries."Document No.".Value, 'Incorrect source view opened');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure VendorLedgerEntriesPageHandler(var VendorLedgerEntries: TestPage "Vendor Ledger Entries")
    begin
        Assert.AreEqual(ExpectedNo, VendorLedgerEntries."Document No.".Value, 'Incorrect source view opened');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderPageHandler(var SalesOrder: TestPage "Sales Order")
    begin
        Assert.AreEqual(ExpectedNo, SalesOrder."No.".Value, 'Incorrect source view opened');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderPageHandler(var PurchaseOrder: TestPage "Purchase Order")
    begin
        Assert.AreEqual(ExpectedNo, PurchaseOrder."No.".Value, 'Incorrect source view opened');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ServiceOrderPageHandler(var ServiceOrder: TestPage "Service Order")
    begin
        Assert.AreEqual(ExpectedNo, ServiceOrder."No.".Value, 'Incorrect source view opened');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure GLAccountPageHandler(var ChartOfAccounts: TestPage "Chart of Accounts")
    begin
        Assert.AreEqual(ExpectedNo, ChartOfAccounts."No.".Value, 'Incorrect source view opened');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CFManualRevenuePageHandler(var CFManualRevenues: TestPage "Cash Flow Manual Revenues")
    begin
        Assert.AreEqual(ExpectedDescription, CFManualRevenues.Description.Value, 'Incorrect source view opened');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CFManualExpensePageHandler(var CFManualExpenses: TestPage "Cash Flow Manual Expenses")
    begin
        Assert.AreEqual(ExpectedDescription, CFManualExpenses.Description.Value, 'Incorrect source view opened');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure FixedAssetCardPageHandler(var FixedAssetCard: TestPage "Fixed Asset Card")
    begin
        Assert.AreEqual(ExpectedNo, FixedAssetCard."No.".Value, 'Incorrect source view opened');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure GLBudgetPageHandler(var Budget: TestPage Budget)
    begin
        Assert.AreEqual(ExpectedBudgetName, Budget.BudgetName.Value, 'Incorrect source view opened');
        Assert.AreEqual(ExpectedNo, Budget.MatrixForm.Code.Value, 'Incorrect source view opened');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure VerifyGLBudgetPageHandler(var Budget: TestPage Budget)
    begin
        Budget.GLAccFilter.AssertEquals(LibraryVariableStorage.DequeueText());
        Budget.Close();
    end;
}

