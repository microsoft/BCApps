codeunit 134263 "Test Bank Payment Application"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Bank Payment Application]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurch: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryDim: Codeunit "Library - Dimension";
        LibraryRandom: Codeunit "Library - Random";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryJournals: Codeunit "Library - Journals";
        Initialized: Boolean;
        ExcessiveAmtErr: Label 'You must apply the excessive amount of %1 %2 manually.', Comment = '%1 a decimal number, %2 currency code';
        WrongStmEndBalanceErr: Label '%1 must be equal to Total Balance.', Comment = '%1 is a field caption';

    [Test]
    [Scope('OnPrem')]
    procedure TestPmtWithDim()
    var
        BankAcc: Record "Bank Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        CustLedgEntry: Record "Cust. Ledger Entry";
        DimValue: Record "Dimension Value";
        DimValue2: Record "Dimension Value";
    begin
        Initialize();

        // Create Sales Invoice and Post
        CreateCustAndPostSalesInvoice(CustLedgEntry, '');

        // create Bank Acc
        LibraryERM.CreateBankAccount(BankAcc);

        LibraryDim.GetGlobalDimCodeValue(1, DimValue);
        LibraryDim.GetGlobalDimCodeValue(2, DimValue2);
        BankAcc.Validate("Global Dimension 1 Code", DimValue.Code);
        BankAcc.Validate("Global Dimension 2 Code", DimValue2.Code);
        BankAcc.Modify(true);

        // Create Bank Rec Header
        LibraryLowerPermissions.AddAccountReceivables();
        LibraryERM.CreateBankAccReconciliation(
          BankAccRecon, BankAcc."No.", BankAccRecon."Statement Type"::"Payment Application");

        Assert.AreEqual(BankAccRecon."Shortcut Dimension 1 Code", BankAcc."Global Dimension 1 Code", '');
        Assert.AreEqual(BankAccRecon."Shortcut Dimension 2 Code", BankAcc."Global Dimension 2 Code", '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestPmtWithDim2()
    var
        BankAcc: Record "Bank Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        DimValue: Record "Dimension Value";
        DimValue2: Record "Dimension Value";
    begin
        Initialize();

        // Create Sales Invoice and Post
        CreateCustAndPostSalesInvoice(CustLedgEntry, '');

        // create Bank Acc
        LibraryERM.CreateBankAccount(BankAcc);

        // Create Bank Rec Header
        LibraryLowerPermissions.AddAccountReceivables();
        LibraryERM.CreateBankAccReconciliation(
          BankAccRecon, BankAcc."No.", BankAccRecon."Statement Type"::"Payment Application");
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconLine, BankAccRecon);

        LibraryDim.GetGlobalDimCodeValue(1, DimValue);
        LibraryDim.GetGlobalDimCodeValue(2, DimValue2);

        BankAccRecon.Validate("Shortcut Dimension 1 Code", DimValue.Code);
        BankAccRecon.Validate("Shortcut Dimension 2 Code", DimValue2.Code);
        BankAccRecon.Modify(true);

        BankAccRecon.Find();
        Assert.AreEqual(BankAccRecon."Shortcut Dimension 1 Code", DimValue.Code, '');
        Assert.AreEqual(BankAccRecon."Shortcut Dimension 2 Code", DimValue2.Code, '');

        BankAccReconLine.Find();
        Assert.AreEqual(BankAccReconLine."Shortcut Dimension 1 Code", DimValue.Code, '');
        Assert.AreEqual(BankAccReconLine."Shortcut Dimension 2 Code", DimValue2.Code, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPmtWithDim3()
    var
        BankAcc: Record "Bank Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        DimValue: Record "Dimension Value";
        DimValue2: Record "Dimension Value";
    begin
        Initialize();

        // Create Sales Invoice and Post
        CreateCustAndPostSalesInvoice(CustLedgEntry, '');

        // create Bank Acc
        LibraryERM.CreateBankAccount(BankAcc);

        // Create Bank Rec Header
        LibraryERM.CreateBankAccReconciliation(
          BankAccRecon, BankAcc."No.", BankAccRecon."Statement Type"::"Payment Application");
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconLine, BankAccRecon);

        LibraryLowerPermissions.AddAccountReceivables();
        LibraryDim.GetGlobalDimCodeValue(1, DimValue);
        LibraryDim.GetGlobalDimCodeValue(2, DimValue2);

        BankAccReconLine.Validate("Shortcut Dimension 1 Code", DimValue.Code);
        BankAccReconLine.Validate("Shortcut Dimension 2 Code", DimValue2.Code);
        BankAccReconLine.Modify(true);

        BankAccReconLine.Find();
        Assert.AreEqual(BankAccReconLine."Shortcut Dimension 1 Code", DimValue.Code, '');
        Assert.AreEqual(BankAccReconLine."Shortcut Dimension 2 Code", DimValue2.Code, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPmtWithBlockedDim()
    var
        BankAcc: Record "Bank Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        CustLedgEntry: Record "Cust. Ledger Entry";
        DimValue: Record "Dimension Value";
        DimValue2: Record "Dimension Value";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
    begin
        Initialize();

        // Create Sales Invoice and Post
        CreateCustAndPostSalesInvoice(CustLedgEntry, '');

        // create Bank Acc
        LibraryERM.CreateBankAccount(BankAcc);

        LibraryDim.GetGlobalDimCodeValue(1, DimValue);
        LibraryDim.GetGlobalDimCodeValue(2, DimValue2);
        BankAcc.Validate("Global Dimension 1 Code", DimValue.Code);
        BankAcc.Validate("Global Dimension 2 Code", DimValue2.Code);
        BankAcc.Modify(true);
        Customer.Get(CustLedgEntry."Customer No.");
        Customer.Validate("Global Dimension 1 Code", DimValue.Code);
        Customer.Validate("Global Dimension 2 Code", DimValue2.Code);
        Customer.Modify();

        CreateBankPmtReconcWithLine(
          BankAcc, BankAccRecon, BankAccReconLine, WorkDate(), CustLedgEntry."Remaining Amount");

        // Create Bank Rec Line - Application
        LibraryLowerPermissions.AddAccountReceivables();
        ApplyCustLedgEntry(BankAccReconLine, CustLedgEntry);

        // Block the dimension
        BlockDimValue(DimValue);
        asserterror LibraryERM.PostBankAccReconciliation(BankAccRecon);

        UnblockDimValue(DimValue);

        // Block the dimension
        BlockDimValue(DimValue2);
        asserterror LibraryERM.PostBankAccReconciliation(BankAccRecon);

        UnblockDimValue(DimValue2);
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure TestPmtWithBlockedDimComb()
    var
        BankAcc: Record "Bank Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        CustLedgEntry: Record "Cust. Ledger Entry";
        DimValue: Record "Dimension Value";
        DimValue2: Record "Dimension Value";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
    begin
        Initialize();

        // Create Sales Invoice and Post
        CreateCustAndPostSalesInvoice(CustLedgEntry, '');

        // create Bank Acc
        LibraryERM.CreateBankAccount(BankAcc);

        LibraryDim.GetGlobalDimCodeValue(1, DimValue);
        LibraryDim.GetGlobalDimCodeValue(2, DimValue2);
        BankAcc.Validate("Global Dimension 1 Code", DimValue.Code);
        BankAcc.Validate("Global Dimension 2 Code", DimValue2.Code);
        BankAcc.Modify(true);
        Customer.Get(CustLedgEntry."Customer No.");
        Customer.Validate("Global Dimension 1 Code", DimValue.Code);
        Customer.Validate("Global Dimension 2 Code", DimValue2.Code);
        Customer.Modify();

        CreateBankPmtReconcWithLine(
          BankAcc, BankAccRecon, BankAccReconLine, WorkDate(), CustLedgEntry."Remaining Amount");

        // Create Bank Rec Line - Application
        ApplyCustLedgEntry(BankAccReconLine, CustLedgEntry);
        UpdateBankAccRecStmEndingBalance(BankAccRecon, BankAccRecon."Balance Last Statement" + BankAccReconLine."Statement Amount");

        // Exercise
        LibraryLowerPermissions.AddAccountReceivables();
        BlockDimCombination(DimValue."Dimension Code", DimValue2."Dimension Code");
        asserterror LibraryERM.PostBankAccReconciliation(BankAccRecon);

        // Verify: posting fails due to Dim combination blocked

        // Tear Down
        UnblockDimCombination(DimValue."Dimension Code", DimValue2."Dimension Code");

        // Verify: posting should succeed is Dim Comb is not blocked
        LibraryERM.PostBankAccReconciliation(BankAccRecon);
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure TestPmtApplnMultipleLines()
    var
        Cust: Record Customer;
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntry2: Record "Cust. Ledger Entry";
        BankAcc: Record "Bank Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
    begin
        Initialize();

        // Create Sales Invoice and Post
        LibrarySales.CreateCustomer(Cust);
        CreateSalesInvoiceAndPost(Cust, CustLedgEntry, '');
        CreateSalesInvoiceAndPost(Cust, CustLedgEntry2, '');

        // create Bank Acc
        LibraryERM.CreateBankAccount(BankAcc);

        CreateBankPmtReconcWithLine(
          BankAcc, BankAccRecon, BankAccReconLine, WorkDate(), CustLedgEntry."Remaining Amount" + CustLedgEntry2."Remaining Amount");

        // Create Bank Rec Line - Application
        LibraryLowerPermissions.AddAccountReceivables();
        ApplyCustLedgEntry(BankAccReconLine, CustLedgEntry);
        ApplyCustLedgEntry(BankAccReconLine, CustLedgEntry2);

        BankAccReconLine.Find();
        Assert.AreEqual(0, BankAccReconLine.Difference, '');

        UpdateBankAccRecStmEndingBalance(BankAccRecon, BankAccRecon."Balance Last Statement" + BankAccReconLine."Statement Amount");

        // Verify: posting should succeed is Dim Comb is not blocked
        LibraryERM.PostBankAccReconciliation(BankAccRecon);
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure TestPmtApplnAmt()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAcc: Record "Bank Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        AppliedPmtEntry: Record "Applied Payment Entry";
    begin
        Initialize();

        // Create Sales Invoice and Post
        CreateCustAndPostSalesInvoice(CustLedgEntry, '');

        // create Bank Acc
        LibraryERM.CreateBankAccount(BankAcc);

        CreateBankPmtReconcWithLine(
          BankAcc, BankAccRecon, BankAccReconLine, WorkDate(), CustLedgEntry."Remaining Amount");

        // Create Bank Rec Line - Application
        LibraryLowerPermissions.AddAccountReceivables();
        ApplyCustLedgEntry(BankAccReconLine, CustLedgEntry);

        AppliedPmtEntry.SetRange("Account Type", AppliedPmtEntry."Account Type"::Customer);
        AppliedPmtEntry.SetRange("Account No.", CustLedgEntry."Customer No.");
        AppliedPmtEntry.FindFirst();
        Commit();

        // Should be possible to reduce
        AppliedPmtEntry.Validate("Applied Amount", AppliedPmtEntry."Applied Amount" / 2);

        // Should not bt possible to zero
        asserterror AppliedPmtEntry.Validate("Applied Amount", 0);

        // Should be possible to change sign
        asserterror AppliedPmtEntry.Validate("Applied Amount", -AppliedPmtEntry."Applied Amount");

        // Tear Down

        // Verify: posting should succeed
        UpdateBankAccRecStmEndingBalance(BankAccRecon, BankAccRecon."Balance Last Statement" + BankAccReconLine."Statement Amount");
        LibraryERM.PostBankAccReconciliation(BankAccRecon);
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure TestWrongStatementEndBalance()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAcc: Record "Bank Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
    begin
        Initialize();

        // Create Sales Invoice and Post
        CreateCustAndPostSalesInvoice(CustLedgEntry, '');

        // create Bank Acc
        LibraryERM.CreateBankAccount(BankAcc);

        CreateBankPmtReconcWithLine(
          BankAcc, BankAccRecon, BankAccReconLine, WorkDate(), CustLedgEntry."Remaining Amount");

        // Create Bank Rec Line - Application
        LibraryLowerPermissions.AddAccountReceivables();
        ApplyCustLedgEntry(BankAccReconLine, CustLedgEntry);

        // Try to post with a wrong Statement Ending Balance
        //UpdateBankAccRecStmEndingBalance(BankAccRecon, BankAccRecon."Balance Last Statement" + BankAccReconLine."Statement Amount");
        asserterror LibraryERM.PostBankAccReconciliation(BankAccRecon);

        // [THEN] Posting is not successful 
        Assert.ExpectedError(StrSubstNo(WrongStmEndBalanceErr, BankAccRecon.FieldCaption("Statement Ending Balance")));

    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure TestRemaingAmtPmtWithDiscMultipleAppln()
    var
        BankAcc: Record "Bank Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntry2: Record "Cust. Ledger Entry";
        Cust: Record Customer;
        PmtTerms: Record "Payment Terms";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        StmtAmt: Decimal;
        i: Integer;
        RemStmtAmt: Decimal;
    begin
        Initialize();

        // Create Sales Invoice and Post
        LibrarySales.CreateCustomer(Cust);
        LibraryERM.CreatePaymentTermsDiscount(PmtTerms, false);
        Cust.Validate("Payment Terms Code", PmtTerms.Code);
        Cust.Modify(true);

        // Create Two payments
        CreateSalesInvoiceAndPost(Cust, CustLedgEntry, '');
        CreateSalesInvoiceAndPost(Cust, CustLedgEntry2, '');

        // create Bank Acc
        LibraryERM.CreateBankAccount(BankAcc);

        // Create Bank Rec Line
        StmtAmt :=
          (CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible") +
          (CustLedgEntry2."Remaining Amount" - CustLedgEntry2."Remaining Pmt. Disc. Possible");
        LibraryLowerPermissions.AddAccountReceivables();
        RemStmtAmt := StmtAmt;
        for i := 3 downto 1 do begin
            CreateBankPmtReconcWithLine(
              BankAcc, BankAccRecon, BankAccReconLine, WorkDate(), Round(RemStmtAmt / i));

            // Create Bank Rec Line - Application
            if i <> 1 then
                ApplyCustLedgEntry(BankAccReconLine, CustLedgEntry);
            if i <> 3 then
                ApplyCustLedgEntry(BankAccReconLine, CustLedgEntry2);

            RemStmtAmt -= BankAccReconLine."Statement Amount";

            // Verify Statement To Rem Amt Difference corresponds to Cust Ledger Remaining Amounts
            CustLedgEntry.CalcFields("Remaining Amount");
            CustLedgEntry2.CalcFields("Remaining Amount");
            OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
            PmtReconJnl.First();
            UpdateBankAccRecStmEndingBalance(BankAccRecon, BankAccRecon."Balance Last Statement" + BankAccReconLine."Statement Amount");
            PmtReconJnl.Difference.AssertEquals(0);
            // Post
            LibraryERM.PostBankAccReconciliation(BankAccRecon);
        end;
        // Verify
        VerifyCustLedgEntry(CustLedgEntry."Customer No.");
        VerifyBankLedgEntry(BankAcc."No.", StmtAmt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPmtApplnMultipleCust()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntry2: Record "Cust. Ledger Entry";
        BankAcc: Record "Bank Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
    begin
        Initialize();

        // Create Sales Invoice and Post
        CreateCustAndPostSalesInvoice(CustLedgEntry, '');
        CreateCustAndPostSalesInvoice(CustLedgEntry2, '');

        // create Bank Acc
        LibraryERM.CreateBankAccount(BankAcc);

        CreateBankPmtReconcWithLine(
          BankAcc, BankAccRecon, BankAccReconLine, WorkDate(), CustLedgEntry."Remaining Amount" + CustLedgEntry2."Remaining Amount");

        // Create Bank Rec Line - Application
        LibraryLowerPermissions.AddAccountReceivables();
        ApplyCustLedgEntry(BankAccReconLine, CustLedgEntry);

        // Should not be possible to add the same entry twice
        asserterror ApplyCustLedgEntry(BankAccReconLine, CustLedgEntry);

        // Should not be possible to add add from a different customer
        asserterror ApplyCustLedgEntry(BankAccReconLine, CustLedgEntry2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostPmtWithoutRecLine()
    var
        BankAcc: Record "Bank Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        Initialize();

        // Create Sales Invoice and Post
        CreateCustAndPostSalesInvoice(CustLedgEntry, '');

        // create Bank Acc
        LibraryERM.CreateBankAccount(BankAcc);

        // Create Bank Rec Header
        LibraryLowerPermissions.AddAccountReceivables();
        LibraryERM.CreateBankAccReconciliation(
          BankAccRecon, BankAcc."No.", BankAccRecon."Statement Type"::"Payment Application");

        // Post
        asserterror LibraryERM.PostBankAccReconciliation(BankAccRecon);
        // Verify
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostPmtWithoutAppln()
    var
        BankAcc: Record "Bank Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        Initialize();

        // Create Sales Invoice and Post
        CreateCustAndPostSalesInvoice(CustLedgEntry, '');

        // create Bank Acc
        LibraryERM.CreateBankAccount(BankAcc);

        LibraryLowerPermissions.AddAccountReceivables();
        CreateBankPmtReconcWithLine(
          BankAcc, BankAccRecon, BankAccReconLine, WorkDate(), CustLedgEntry."Remaining Amount");

        // Post
        asserterror LibraryERM.PostBankAccReconciliation(BankAccRecon);

        // Verify
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure TestPostPmtWithAppln()
    var
        BankAcc: Record "Bank Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        PmtCustLedgEntry: Record "Cust. Ledger Entry";
    begin
        // [SCENARIO] Vendor and Bank Account Ledger Entries are created when post Bank. Account Reconciliation Line applied to Posted Sales Invoice

        Initialize();

        // [GIVEN] Posted Invoice with Amount = 100
        CreateCustAndPostSalesInvoice(CustLedgEntry, '');

        // [GIVEN] Bank Account Reconciliation Line applied to Posted Invoice
        LibraryERM.CreateBankAccount(BankAcc);

        CreateBankPmtReconcWithLine(
          BankAcc, BankAccRecon, BankAccReconLine, WorkDate(), CustLedgEntry."Remaining Amount");

        LibraryLowerPermissions.AddAccountReceivables();
        ApplyCustLedgEntry(BankAccReconLine, CustLedgEntry);
        UpdateBankAccRecStmEndingBalance(BankAccRecon, BankAccRecon."Balance Last Statement" + BankAccReconLine."Statement Amount");

        // [WHEN] Post Bank Account Reconciliation
        LibraryERM.PostBankAccReconciliation(BankAccRecon);

        // [THEN] Customer Ledger Entry for Posted Invoice is Closed
        VerifyCustLedgEntry(CustLedgEntry."Customer No.");

        // [THEN] Bank Account Ledger Entry posted with Amount = 100
        VerifyBankLedgEntry(BankAcc."No.", CustLedgEntry."Remaining Amount");

        // [THEN] TFS ID 211371: "Applies-to ID" is blank after posting Payment through Payment Reconciliation Journal applied to Invoice
        LibraryERM.FindCustomerLedgerEntry(PmtCustLedgEntry, PmtCustLedgEntry."Document Type"::Payment, BankAccRecon."Statement No.");
        PmtCustLedgEntry.TestField("Applies-to ID", '');
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure TestPostPmtWithDiscAppln()
    var
        BankAcc: Record "Bank Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        Cust: Record Customer;
        PmtTerms: Record "Payment Terms";
        StmtAmt: Decimal;
    begin
        Initialize();

        // Create Sales Invoice and Post
        LibrarySales.CreateCustomer(Cust);
        LibraryERM.CreatePaymentTermsDiscount(PmtTerms, false);
        Cust.Validate("Payment Terms Code", PmtTerms.Code);
        Cust.Modify(true);

        CreateSalesInvoiceAndPost(Cust, CustLedgEntry, '');

        // create Bank Acc
        LibraryERM.CreateBankAccount(BankAcc);

        StmtAmt := CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible";
        CreateBankPmtReconcWithLine(BankAcc, BankAccRecon, BankAccReconLine, WorkDate(), StmtAmt);

        // Create Bank Rec Line - Application
        LibraryLowerPermissions.AddAccountReceivables();
        ApplyCustLedgEntry(BankAccReconLine, CustLedgEntry);
        BankAccReconLine.Find();
        Assert.AreEqual(0, BankAccReconLine.Difference, '');

        // Post
        LibraryLowerPermissions.AddAccountReceivables();
        UpdateBankAccRecStmEndingBalance(BankAccRecon, BankAccRecon."Balance Last Statement" + BankAccReconLine."Statement Amount");
        LibraryERM.PostBankAccReconciliation(BankAccRecon);

        // Verify
        VerifyCustLedgEntry(CustLedgEntry."Customer No.");
        VerifyBankLedgEntry(BankAcc."No.", StmtAmt);
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure TestPostPmtWithDiscMultipleAppln()
    var
        BankAcc: Record "Bank Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        Cust: Record Customer;
        PmtTerms: Record "Payment Terms";
        StmtAmt: Decimal;
        i: Integer;
        RemStmtAmt: Decimal;
    begin
        Initialize();

        // Create Sales Invoice and Post
        LibrarySales.CreateCustomer(Cust);
        LibraryERM.CreatePaymentTermsDiscount(PmtTerms, false);
        Cust.Validate("Payment Terms Code", PmtTerms.Code);
        Cust.Modify(true);

        CreateSalesInvoiceAndPost(Cust, CustLedgEntry, '');

        // create Bank Acc
        LibraryERM.CreateBankAccount(BankAcc);

        // Create Bank Rec Header
        LibraryERM.CreateBankAccReconciliation(
          BankAccRecon, BankAcc."No.", BankAccRecon."Statement Type"::"Payment Application");

        // Create Bank Rec Line
        StmtAmt := CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible";

        RemStmtAmt := StmtAmt;
        LibraryLowerPermissions.AddAccountReceivables();

        for i := 3 downto 1 do begin
            LibraryERM.CreateBankAccReconciliationLn(BankAccReconLine, BankAccRecon);
            BankAccReconLine.Validate("Transaction Date", WorkDate());
            BankAccReconLine.Validate(Description, 'Hello World');
            BankAccReconLine.Validate("Statement Amount", Round(RemStmtAmt / i));
            BankAccReconLine.Modify(true);

            // Create Bank Rec Line - Application
            ApplyCustLedgEntry(BankAccReconLine, CustLedgEntry);

            RemStmtAmt -= BankAccReconLine."Statement Amount";
        end;

        // Post
        UpdateBankAccRecStmEndingBalance(BankAccRecon, BankAccRecon."Balance Last Statement" + StmtAmt);
        LibraryERM.PostBankAccReconciliation(BankAccRecon);

        // Verify
        VerifyCustLedgEntry(CustLedgEntry."Customer No.");
        VerifyBankLedgEntry(BankAcc."No.", StmtAmt);
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure TestPostPmtWithNoDiscAppln()
    var
        BankAcc: Record "Bank Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        Cust: Record Customer;
        PmtTerms: Record "Payment Terms";
        StmtAmt: Decimal;
    begin
        Initialize();

        // Create Sales Invoice and Post
        LibrarySales.CreateCustomer(Cust);
        LibraryERM.CreatePaymentTermsDiscount(PmtTerms, false);
        Cust.Validate("Payment Terms Code", PmtTerms.Code);
        Cust.Modify(true);

        CreateSalesInvoiceAndPost(Cust, CustLedgEntry, '');

        // create Bank Acc
        LibraryERM.CreateBankAccount(BankAcc);

        // Create Bank Rec Header
        LibraryERM.CreateBankAccReconciliation(
          BankAccRecon, BankAcc."No.", BankAccRecon."Statement Type"::"Payment Application");
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconLine, BankAccRecon);

        // Create Bank Rec Line
        StmtAmt := CustLedgEntry."Remaining Amount";

        BankAccReconLine.Validate("Transaction Date", CalcDate('<1D>', CustLedgEntry."Pmt. Discount Date"));
        BankAccReconLine.Validate(Description, 'Hello World');
        BankAccReconLine.Validate("Statement Amount", StmtAmt);
        BankAccReconLine.Modify(true);

        // Create Bank Rec Line - Application
        ApplyCustLedgEntry(BankAccReconLine, CustLedgEntry);

        // Post
        UpdateBankAccRecStmEndingBalance(BankAccRecon, BankAccRecon."Balance Last Statement" + StmtAmt);
        LibraryERM.PostBankAccReconciliation(BankAccRecon);

        // Verify
        VerifyCustLedgEntry(CustLedgEntry."Customer No.");
        VerifyBankLedgEntry(BankAcc."No.", StmtAmt);
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure TestPostPmtWithVendAppln()
    var
        BankAcc: Record "Bank Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        PmtVendLedgEntry: Record "Vendor Ledger Entry";
    begin
        // [SCENARIO] Vendor and Bank Account Ledger Entries are created when post Bank. Account Reconciliation Line applied to Posted Purchase Invoice
        Initialize();

        // [GIVEN] Posted Invoice with Amount = 100
        CreateVendAndPostPurchInvoice(VendLedgEntry, '');

        // [GIVEN] Bank Account Reconciliation Line applied to Posted Invoice
        LibraryERM.CreateBankAccount(BankAcc);

        VendLedgEntry.CalcFields("Remaining Amount");
        CreateBankPmtReconcWithLine(BankAcc, BankAccRecon, BankAccReconLine, WorkDate(), VendLedgEntry."Remaining Amount");

        // Create Bank Rec Line - Application
        LibraryLowerPermissions.AddAccountReceivables();
        ApplyVendLedgEntry(BankAccReconLine, VendLedgEntry);

        // [WHEN] Post Bank Account Reconciliation
        UpdateBankAccRecStmEndingBalance(BankAccRecon, BankAccRecon."Balance Last Statement" + BankAccReconLine."Statement Amount");
        LibraryERM.PostBankAccReconciliation(BankAccRecon);

        // [THEN] Customer Ledger Entry for Posted Invoice is Closed
        VerifyVendLedgEntry(VendLedgEntry."Vendor No.");

        // [THEN] Bank Account Ledger Entry posted with Amount = 100
        VerifyBankLedgEntry(BankAcc."No.", VendLedgEntry."Remaining Amount");

        // [THEN] TFS ID 211371: "Applies-to ID" is blank after posting Payment through Payment Reconciliation Journal applied to Invoice
        LibraryERM.FindVendorLedgerEntry(PmtVendLedgEntry, PmtVendLedgEntry."Document Type"::Payment, BankAccRecon."Statement No.");
        PmtVendLedgEntry.TestField("Applies-to ID", '');
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure TestPostPmtWithFCYInvAppln()
    var
        BankAcc: Record "Bank Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        Curr: Record Currency;
    begin
        Initialize();

        // Create Sales Invoice and Post
        Curr.Get(LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 10, 10));

        CreateCustAndPostSalesInvoice(CustLedgEntry, Curr.Code);

        // create Bank Acc
        LibraryERM.CreateBankAccount(BankAcc);

        CustLedgEntry.CalcFields("Remaining Amt. (LCY)");
        CreateBankPmtReconcWithLine(
          BankAcc, BankAccRecon, BankAccReconLine, WorkDate(), CustLedgEntry."Remaining Amt. (LCY)");

        // Create Bank Rec Line - Application
        LibraryLowerPermissions.AddAccountReceivables();
        ApplyCustLedgEntry(BankAccReconLine, CustLedgEntry);

        // Post
        UpdateBankAccRecStmEndingBalance(BankAccRecon, BankAccRecon."Balance Last Statement" + BankAccReconLine."Statement Amount");
        LibraryERM.PostBankAccReconciliation(BankAccRecon);

        // Verify
        VerifyCustLedgEntry(CustLedgEntry."Customer No.");
        VerifyBankLedgEntry(BankAcc."No.", CustLedgEntry."Remaining Amt. (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostPmtWithFCYPayAppln()
    var
        BankAcc: Record "Bank Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        Curr: Record Currency;
    begin
        Initialize();

        // Create Sales Invoice and Post
        Curr.Get(LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 10, 10));

        CreateCustAndPostSalesInvoice(CustLedgEntry, '');

        // create Bank Acc
        LibraryERM.CreateBankAccount(BankAcc);
        BankAcc.Validate("Currency Code", Curr.Code);
        BankAcc.Modify(true);

        CreateBankPmtReconcWithLine(
          BankAcc, BankAccRecon, BankAccReconLine, WorkDate(), CustLedgEntry."Remaining Amount");

        // Create Bank Rec Line - Application
        asserterror ApplyCustLedgEntry(BankAccReconLine, CustLedgEntry);

        // Post
        // ASSERTERROR CODEUNIT.RUN(CODEUNIT::"Bank Acc. Reconciliation Post",BankAccRecon);

        // Verify
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure TestPostPmtWithFCYDiscAppln()
    var
        BankAcc: Record "Bank Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        Cust: Record Customer;
        PmtTerms: Record "Payment Terms";
        Curr: Record Currency;
        StmtAmt: Decimal;
    begin
        Initialize();

        // Create Sales Invoice and Post
        Curr.Get(LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 10, 10));

        LibrarySales.CreateCustomer(Cust);
        LibraryERM.CreatePaymentTermsDiscount(PmtTerms, false);
        Cust.Validate("Payment Terms Code", PmtTerms.Code);
        Cust.Modify(true);

        CreateSalesInvoiceAndPost(Cust, CustLedgEntry, Curr.Code);

        // create Bank Acc
        LibraryERM.CreateBankAccount(BankAcc);

        // Create Bank Rec Line
        CustLedgEntry.CalcFields("Remaining Amt. (LCY)", "Remaining Amount");
        StmtAmt :=
          CustLedgEntry."Remaining Amt. (LCY)" -
          Round(
            CustLedgEntry."Remaining Pmt. Disc. Possible" *
            Round(CustLedgEntry."Remaining Amt. (LCY)" / CustLedgEntry."Remaining Amount"));
        CreateBankPmtReconcWithLine(
          BankAcc, BankAccRecon, BankAccReconLine, WorkDate(), StmtAmt);

        // Create Bank Rec Line - Application
        ApplyCustLedgEntry(BankAccReconLine, CustLedgEntry);

        BankAccReconLine.Find();
        Assert.AreEqual(0, BankAccReconLine.Difference, '');

        // Post
        UpdateBankAccRecStmEndingBalance(BankAccRecon, BankAccRecon."Balance Last Statement" + BankAccReconLine."Statement Amount");
        LibraryERM.PostBankAccReconciliation(BankAccRecon);

        // Verify
        VerifyCustLedgEntry(CustLedgEntry."Customer No.");
        VerifyBankLedgEntry(BankAcc."No.", StmtAmt);
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure TestPostPmtWithLCYInvAndFCYPayAppln()
    var
        BankAcc: Record "Bank Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        Curr: Record Currency;
    begin
        Initialize();

        // Create Sales Invoice and Post
        Curr.Get(LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 10, 10));

        LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 10, 10);

        CreateCustAndPostSalesInvoice(CustLedgEntry, Curr.Code);

        // create Bank Acc
        LibraryERM.CreateBankAccount(BankAcc);
        BankAcc.Validate("Currency Code", Curr.Code);
        BankAcc.Modify(true);

        // Create Bank Rec Line
        CreateBankPmtReconcWithLine(
          BankAcc, BankAccRecon, BankAccReconLine, WorkDate(), CustLedgEntry."Remaining Amount");

        // Create Bank Rec Line - Application
        LibraryLowerPermissions.AddAccountReceivables();
        ApplyCustLedgEntry(BankAccReconLine, CustLedgEntry);

        // Post
        UpdateBankAccRecStmEndingBalance(BankAccRecon, BankAccRecon."Balance Last Statement" + BankAccReconLine."Statement Amount");
        LibraryERM.PostBankAccReconciliation(BankAccRecon);

        // Verify
        VerifyCustLedgEntry(CustLedgEntry."Customer No.");
        VerifyBankLedgEntry(BankAcc."No.", CustLedgEntry."Remaining Amount");
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure TestPostPmtWithDiscFCYInvAndLCYPayAppln()
    var
        BankAcc: Record "Bank Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        Curr: Record Currency;
        Cust: Record Customer;
        PmtTerms: Record "Payment Terms";
        StmtAmt: Decimal;
    begin
        Initialize();

        // Create Sales Invoice and Post
        LibrarySales.CreateCustomer(Cust);
        LibraryERM.CreatePaymentTermsDiscount(PmtTerms, false);
        Cust.Validate("Payment Terms Code", PmtTerms.Code);
        Cust.Modify(true);

        Curr.Get(LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 10, 10));
        LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 10, 10);
        CreateSalesInvoiceAndPost(Cust, CustLedgEntry, '');

        // create Bank Acc
        LibraryERM.CreateBankAccount(BankAcc);

        // Create Bank Rec Line
        StmtAmt := CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible";
        LibraryLowerPermissions.AddAccountReceivables();
        CreateBankPmtReconcWithLine(BankAcc, BankAccRecon, BankAccReconLine, WorkDate(), StmtAmt);

        // Create Bank Rec Line - Application
        ApplyCustLedgEntry(BankAccReconLine, CustLedgEntry);

        // Post
        UpdateBankAccRecStmEndingBalance(BankAccRecon, BankAccRecon."Balance Last Statement" + BankAccReconLine."Statement Amount");
        LibraryERM.PostBankAccReconciliation(BankAccRecon);

        // Verify
        VerifyCustLedgEntry(CustLedgEntry."Customer No.");
        VerifyBankLedgEntry(BankAcc."No.", StmtAmt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetAmountToleranceRangeToleranceAmountType()
    var
        BankAccount: Record "Bank Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        ToleranceAmount: Decimal;
        Amount: Decimal;
        MinAmount: Decimal;
        MaxAmount: Decimal;
    begin
        Initialize();

        // Setup
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Match Tolerance Type", BankAccount."Match Tolerance Type"::Amount);
        ToleranceAmount := LibraryRandom.RandDecInRange(1, 1000, 2);
        BankAccount.Validate("Match Tolerance Value", ToleranceAmount);
        BankAccount.Modify();
        Amount := 2 * ToleranceAmount;

        CreateBankPmtReconcWithLine(BankAccount, BankAccRecon, BankAccReconLine, WorkDate(), Amount);

        // Execute
        BankAccReconLine.GetAmountRangeForTolerance(MinAmount, MaxAmount);

        // Verify
        Assert.AreEqual(ToleranceAmount, MinAmount, 'MinAmount was not set to a correct value');
        Assert.AreEqual(3 * ToleranceAmount, MaxAmount, 'Max Amount was not set to a correct value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetAmountToleranceRangeToleranceAmountTypeForNegativeAmount()
    var
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        BankAccount: Record "Bank Account";
        ToleranceAmount: Decimal;
        Amount: Decimal;
        MinAmount: Decimal;
        MaxAmount: Decimal;
    begin
        Initialize();

        // Setup
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Match Tolerance Type", BankAccount."Match Tolerance Type"::Amount);
        ToleranceAmount := LibraryRandom.RandDecInRange(1, 1000, 2);
        BankAccount.Validate("Match Tolerance Value", ToleranceAmount);
        BankAccount.Modify();
        Amount := -2 * ToleranceAmount;

        CreateBankPmtReconcWithLine(BankAccount, BankAccRecon, BankAccReconLine, WorkDate(), Amount);

        // Execute
        BankAccReconLine.GetAmountRangeForTolerance(MinAmount, MaxAmount);

        // Verify
        Assert.AreEqual(-ToleranceAmount, MaxAmount, 'MinAmount was not set to a correct value');
        Assert.AreEqual(-3 * ToleranceAmount, MinAmount, 'Max Amount was not set to a correct value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetAmountToleranceRangeToleranceAmountGreaterThanTheAmount()
    var
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        BankAccount: Record "Bank Account";
        ToleranceAmount: Decimal;
        Amount: Decimal;
        MinAmount: Decimal;
        MaxAmount: Decimal;
    begin
        Initialize();

        // Setup
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Match Tolerance Type", BankAccount."Match Tolerance Type"::Amount);
        ToleranceAmount := LibraryRandom.RandDecInRange(1, 1000, 2);
        BankAccount.Validate("Match Tolerance Value", ToleranceAmount);
        BankAccount.Modify();
        Amount := Round(ToleranceAmount / 3, LibraryERM.GetAmountRoundingPrecision());

        CreateBankPmtReconcWithLine(BankAccount, BankAccRecon, BankAccReconLine, WorkDate(), Amount);

        // Execute
        BankAccReconLine.GetAmountRangeForTolerance(MinAmount, MaxAmount);

        // Verify
        Assert.AreEqual(0, MinAmount, 'MinAmount was not set to a correct value');
        Assert.AreEqual(ToleranceAmount + Amount, MaxAmount, 'Max Amount was not set to a correct value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetAmountToleranceRangeToleranceAmountGreaterThanTheNegativeAmount()
    var
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        BankAccount: Record "Bank Account";
        ToleranceAmount: Decimal;
        Amount: Decimal;
        MinAmount: Decimal;
        MaxAmount: Decimal;
    begin
        Initialize();

        // Setup
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Match Tolerance Type", BankAccount."Match Tolerance Type"::Amount);
        ToleranceAmount := LibraryRandom.RandDecInRange(1, 1000, 2);
        BankAccount.Validate("Match Tolerance Value", ToleranceAmount);
        BankAccount.Modify();
        Amount := -Round(ToleranceAmount / 3, LibraryERM.GetAmountRoundingPrecision());

        CreateBankPmtReconcWithLine(BankAccount, BankAccRecon, BankAccReconLine, WorkDate(), Amount);

        // Execute
        BankAccReconLine.GetAmountRangeForTolerance(MinAmount, MaxAmount);

        // Verify
        Assert.AreEqual(0, MaxAmount, 'MinAmount was not set to a correct value');
        Assert.AreEqual(-ToleranceAmount + Amount, MinAmount, 'Max Amount was not set to a correct value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPercentageTypeToleranceAmountFromBankAccount()
    var
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        BankAccount: Record "Bank Account";
        TolerancePct: Integer;
        Amount: Decimal;
        MinAmount: Decimal;
        MaxAmount: Decimal;
    begin
        // [FEATURE] [UT] [Payment Tolerance]
        // [SCENARIO] Minimum and Maximum correctly calculated when "Match Tolerance Type" is Percentage, Amount is positive and "Tolerance Percent" is defined
        // [TFS 381097] Amount Range is correctly calculated when "Match Tolerance Type" is Percentage

        Initialize();

        // Setup
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Match Tolerance Type", BankAccount."Match Tolerance Type"::Percentage);
        TolerancePct := LibraryRandom.RandIntInRange(2, 80);
        BankAccount.Validate("Match Tolerance Value", TolerancePct);
        BankAccount.Modify();
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);

        CreateBankPmtReconcWithLine(BankAccount, BankAccRecon, BankAccReconLine, WorkDate(), Amount);

        // Execute
        BankAccReconLine.GetAmountRangeForTolerance(MinAmount, MaxAmount);

        // Verify
        VerifyMinMaxAmounts(Amount, TolerancePct, MinAmount, MaxAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPercentageTypeToleranceAmountFromBankAccountWithNegativeAmount()
    var
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        BankAccount: Record "Bank Account";
        TolerancePct: Integer;
        Amount: Decimal;
        MinAmount: Decimal;
        MaxAmount: Decimal;
    begin
        // [FEATURE] [UT] [Payment Tolerance]
        // [SCENARIO] Minimum and Maximum correctly calculated when "Match Tolerance Type" is Percentage, Amount is negative and "Tolerance Percent" is defined

        Initialize();

        // Setup
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Match Tolerance Type", BankAccount."Match Tolerance Type"::Percentage);
        TolerancePct := LibraryRandom.RandIntInRange(2, 80);
        BankAccount.Validate("Match Tolerance Value", TolerancePct);
        BankAccount.Modify();
        Amount := -LibraryRandom.RandDecInRange(1, 1000, 2);

        CreateBankPmtReconcWithLine(BankAccount, BankAccRecon, BankAccReconLine, WorkDate(), Amount);

        // Execute
        BankAccReconLine.GetAmountRangeForTolerance(MinAmount, MaxAmount);

        // Verify
        VerifyMinMaxAmounts(Amount, TolerancePct, MaxAmount, MinAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPercentageTypeToleranceAmountFromBankAccountZeroPercentage()
    var
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        BankAccount: Record "Bank Account";
        Amount: Decimal;
        MinAmount: Decimal;
        MaxAmount: Decimal;
    begin
        // [FEATURE] [UT] [Payment Tolerance]
        // [SCENARIO] Minimum and Maximum correctly calculated when "Match Tolerance Type" is Percentage, Amount is positive and "Tolerance Percent" is zero

        Initialize();

        // Setup
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Match Tolerance Type", BankAccount."Match Tolerance Type"::Percentage);
        BankAccount.Validate("Match Tolerance Value", 0);
        BankAccount.Modify();
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);

        CreateBankPmtReconcWithLine(BankAccount, BankAccRecon, BankAccReconLine, WorkDate(), Amount);

        // Execute
        LibraryLowerPermissions.AddAccountReceivables();
        BankAccReconLine.GetAmountRangeForTolerance(MinAmount, MaxAmount);

        // Verify
        VerifyMinMaxAmounts(Amount, 0, MinAmount, MaxAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPercentageTypeToleranceAmountFromBankAccountZeroPercentageWithNegativeAmount()
    var
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        BankAccount: Record "Bank Account";
        Amount: Decimal;
        MinAmount: Decimal;
        MaxAmount: Decimal;
    begin
        // [FEATURE] [UT] [Payment Tolerance]
        // [SCENARIO] Minimum and Maximum correctly calculated when "Match Tolerance Type" is Percentage, Amount is negative and "Tolerance Percent" is zero

        Initialize();

        // Setup
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Match Tolerance Type", BankAccount."Match Tolerance Type"::Percentage);
        BankAccount.Validate("Match Tolerance Value", 0);
        BankAccount.Modify();
        Amount := -LibraryRandom.RandDecInRange(1, 1000, 2);

        CreateBankPmtReconcWithLine(BankAccount, BankAccRecon, BankAccReconLine, WorkDate(), Amount);

        // Execute
        LibraryLowerPermissions.AddAccountReceivables();
        BankAccReconLine.GetAmountRangeForTolerance(MinAmount, MaxAmount);

        // Verify
        VerifyMinMaxAmounts(Amount, 0, MinAmount, MaxAmount);
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure PostedSourceCodeAfterReconPaymentApplication()
    var
        Customer: Record Customer;
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        SourceCode: Record "Source Code";
    begin
        // [FEATURE] [Source Code]
        // [SCENARIO 379544] Source Code Setup "Payment Reconciliation Journal" value is used as "Source Code" when post reconcicliation with "Statement Type" = "Payment Application"
        Initialize();

        // [GIVEN] SourceCodeSetup."Payment Reconciliation Journal" = "X"
        LibraryERM.CreateSourceCode(SourceCode);
        UpdateSourceCodeSetupForPmtReconJnl(SourceCode.Code);

        // [GIVEN] Posted sales invoice
        LibrarySales.CreateCustomer(Customer);
        CreateSalesInvoiceAndPost(Customer, CustLedgEntry, '');

        // [GIVEN] Payment Reconciliation Journal (bank "Statement Type" = "Payment Application") with applied invoice ledger entry
        LibraryERM.CreateBankAccount(BankAccount);
        CreateBankPmtReconcWithLine(
          BankAccount, BankAccReconciliation, BankAccReconLine, WorkDate(), CustLedgEntry."Remaining Amount");
        ApplyCustLedgEntry(BankAccReconLine, CustLedgEntry);

        // [WHEN] Post application
        UpdateBankAccRecStmEndingBalance(BankAccReconciliation, BankAccReconciliation."Balance Last Statement" + BankAccReconLine."Statement Amount");
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN] Created GLRegister."Source Code" = GLEntry."Source Code" = "X"
        VerifyLastGLRegisterSourceCode(SourceCode.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_RemaingAmtAfterPostingOnBankAccReconLine()
    var
        BankAcc: Record "Bank Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        Cust: Record Customer;
        AppliedPaymentEntry: Record "Applied Payment Entry";
        RemainingAmountAfterPosting: Decimal;
        DifferenceStatementAmtToApplEntryAmount: Decimal;
    begin
        // [SCENARIO 380959] "Remaining Amount After Posting" calculated as "Remaining Amount" of Ledger Entry minus "Statement Amount" on Bank Account Reconciliation Line

        Initialize();

        // [GIVEN] Sales Invoice "X" with Amount = 100
        LibrarySales.CreateCustomer(Cust);
        CreateSalesInvoiceAndPost(Cust, CustLedgEntry, '');

        // [GIVEN] Bank Account Reconciliation Line with "Statement Amount" = 30
        LibraryERM.CreateBankAccount(BankAcc);
        CreateBankPmtReconcWithLine(
          BankAcc, BankAccRecon, BankAccReconLine, WorkDate(), Round(CustLedgEntry."Remaining Amount" / LibraryRandom.RandIntInRange(3, 5)));

        // [GIVEN] Apply Sales Invoice "X" to Bank Account Reconciliation Line
        ApplyCustLedgEntry(BankAccReconLine, CustLedgEntry);

        // [WHEN] Calculate Applied Payment Data by function GetAppliedPmtData in Bank Account Reconciliation table
        BankAccReconLine.GetAppliedPmtData(
          AppliedPaymentEntry, RemainingAmountAfterPosting, DifferenceStatementAmtToApplEntryAmount, '');

        // [THEN] "Remaining Amount After Posting" = 70 ("Invoice Amount" - "Remaining Amount")
        Assert.AreEqual(CustLedgEntry."Remaining Amount" - BankAccReconLine."Statement Amount", RemainingAmountAfterPosting, '');
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure SalesApplyPmtInLCYToInvoiceInFCYWithDiffCurrencyExchangeRate()
    var
        BankAcc: Record "Bank Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        CurrencyExchRate: Record "Currency Exchange Rate";
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [Sales] [Currency]
        // [SCENARIO 388597] Currency Exchange Rate on Transaction Date is used when apply Payment to Sales Invoice in foreign currency on Bank Account Reconciliation page.
        Initialize();

        // [GIVEN] Currency "X" with "Posting Date" = 01.01 and "Exchange Rate" = 1/100
        // [GIVEN] Currency "X" with "Posting Date" = 02.01 and "Exchange Rate" = 1/99
        CurrencyCode := SetupCurrencyWithExchRates();

        // [GIVEN] Sales Invoice with "Posting Date" = 01.01, "Currency Code" = "X" and Amount = 10 ("Amount (LCY)" = 1000)
        CreateCustAndPostSalesInvoice(CustLedgEntry, CurrencyCode);

        // [GIVEN] Bank Account Reconciliation in local currency, "Posting Date" = 02.01 and Amount = 1000
        LibraryERM.CreateBankAccount(BankAcc);
        CustLedgEntry.CalcFields("Remaining Amount");
        CurrencyExchRate.Get(CurrencyCode, WorkDate() + 1);
        CreateBankPmtReconcWithLine(
            BankAcc, BankAccRecon, BankAccReconLine, WorkDate() + 1,
            Round(CustLedgEntry."Remaining Amount" / CurrencyExchRate."Exchange Rate Amount"));
        BankAccReconLine.Modify(true);

        // [GIVEN] Sales Invoice applied to Bank Account Reconciliation
        ApplyCustLedgEntry(BankAccReconLine, CustLedgEntry);

        // [WHEN] Post Bank Account Reconciliation
        UpdateBankAccRecStmEndingBalance(BankAccRecon, BankAccRecon."Balance Last Statement" + BankAccReconLine."Statement Amount");
        LibraryERM.PostBankAccReconciliation(BankAccRecon);

        // [THEN] Sales Invoice fully applied to Payment
        CustLedgEntry.Find();
        CustLedgEntry.TestField(Open, false);
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure PurchApplyPmtInLCYToInvoiceInFCYWithDiffCurrencyExchangeRate()
    var
        BankAcc: Record "Bank Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        CurrencyExchRate: Record "Currency Exchange Rate";
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [Purchase] [Currency]
        // [SCENARIO 388597] Currency Exchange Rate on Transaction Date is used when apply Payment to Purchase Invoice in foreign currency on Bank Account Reconciliation page.
        Initialize();

        // [GIVEN] Currency "X" with "Posting Date" = 01.01 and "Exchange Rate" = 1/100
        // [GIVEN] Currency "X" with "Posting Date" = 02.01 and "Exchange Rate" = 1/99
        CurrencyCode := SetupCurrencyWithExchRates();

        // [GIVEN] Purchase Invoice with "Posting Date" = 01.01, "Currency Code" = "X" and Amount = 10 ("Amount (LCY)" = 1000)
        CreateVendAndPostPurchInvoice(VendLedgEntry, CurrencyCode);

        // [GIVEN] Bank Account Reconciliation in local currency, "Posting Date" = 02.01 and Amount = 1000
        LibraryERM.CreateBankAccount(BankAcc);
        VendLedgEntry.CalcFields("Remaining Amount");
        CurrencyExchRate.Get(CurrencyCode, WorkDate() + 1);
        CreateBankPmtReconcWithLine(
            BankAcc, BankAccRecon, BankAccReconLine, WorkDate() + 1,
            Round(VendLedgEntry."Remaining Amount" / CurrencyExchRate."Exchange Rate Amount"));
        BankAccReconLine.Modify(true);

        // [GIVEN] Purchase Invoice applied to Bank Account Reconciliation
        ApplyVendLedgEntry(BankAccReconLine, VendLedgEntry);

        // [WHEN] Post Bank Account Reconciliation
        UpdateBankAccRecStmEndingBalance(BankAccRecon, BankAccRecon."Balance Last Statement" + BankAccReconLine."Statement Amount");
        LibraryERM.PostBankAccReconciliation(BankAccRecon);

        // [THEN] Purchase Invoice fully applied to Payment
        VendLedgEntry.Find();
        VendLedgEntry.TestField(Open, false);
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure AppliesToIdIsBlankWhenNoEntriesAppliesDuringSalesPosting()
    var
        BankAcc: Record "Bank Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 211371] "Applies-to ID" is blank when no entries applied during sales posting of Bank Account Reconciliation Line

        Initialize();

        // [GIVEN] Bank Acc. Reconciliation Line with "Account Type" = Customer
        LibraryERM.CreateBankAccount(BankAcc);
        CreateBankPmtRecWithLineApplyAmount(
          BankAcc, BankAccRecon, BankAccReconLine, WorkDate(), LibraryRandom.RandDec(100, 2),
          BankAccReconLine."Account Type"::Customer, LibrarySales.CreateCustomerNo());

        // [WHEN] Post Bank Acc. Reconciliation Line
        UpdateBankAccRecStmEndingBalance(BankAccRecon, BankAccRecon."Balance Last Statement" + BankAccReconLine."Statement Amount");
        LibraryERM.PostBankAccReconciliation(BankAccRecon);

        // [THEN] "Applies-to ID" is blank in Payment Customer Ledger Entry
        CustLedgerEntry.SetRange("Customer No.", BankAccReconLine."Account No.");
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, BankAccRecon."Statement No.");
        CustLedgerEntry.TestField("Applies-to ID", '');
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure AppliesToIdIsBlankWhenNoEntriesAppliesDuringPurchPosting()
    var
        BankAcc: Record "Bank Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 211371] "Applies-to ID" is blank when no entries applied during purchase posting of Bank Account Reconciliation Line

        Initialize();

        // [GIVEN] Bank Acc. Reconciliation Line with "Account Type" = Vendor
        LibraryERM.CreateBankAccount(BankAcc);
        CreateBankPmtRecWithLineApplyAmount(
          BankAcc, BankAccRecon, BankAccReconLine, WorkDate(), -LibraryRandom.RandDec(100, 2),
          BankAccReconLine."Account Type"::Vendor, LibraryPurch.CreateVendorNo());

        // [WHEN] Post Bank Acc. Reconciliation Line
        UpdateBankAccRecStmEndingBalance(BankAccRecon, BankAccRecon."Balance Last Statement" + BankAccReconLine."Statement Amount");
        LibraryERM.PostBankAccReconciliation(BankAccRecon);

        // [THEN] "Applies-to ID" is blank in Payment Vendor Ledger Entry
        VendLedgerEntry.SetRange("Vendor No.", BankAccReconLine."Account No.");
        LibraryERM.FindVendorLedgerEntry(VendLedgerEntry, VendLedgerEntry."Document Type"::Payment, BankAccRecon."Statement No.");
        VendLedgerEntry.TestField("Applies-to ID", '');
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure BankPaymentApplicationBankReconciliationLCYToBankAccountLCY()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        // [FEATURE] [Bank Account] [Currency]
        // [SCENARIO 223618] Bank Payment Application of Bank Acc.Reconciliation to Bank Account both in LCY
        Initialize();

        // [GIVEN] Bank Account Reconciliation Line with Amount = 100 no currency
        // [GIVEN] Set Application to Bank Account "B" of no currency specified
        LibraryERM.CreateBankAccount(BankAccount);
        CreateBankPmtRecWithLineApplyAmount(
          BankAccount, BankAccReconciliation, BankAccReconciliationLine, WorkDate(), LibraryRandom.RandDec(100, 2),
          BankAccReconciliationLine."Account Type"::"Bank Account", LibraryERM.CreateBankAccountNo());

        // [WHEN] Post Bank Payment Application
        UpdateBankAccRecStmEndingBalance(BankAccReconciliation, BankAccReconciliation."Balance Last Statement" + BankAccReconciliationLine."Statement Amount");
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN] Bank Account Ledger Entry is posted with Amount = 100 for Bank Account "B"
        VerifyBankLedgEntry(BankAccount."No.", BankAccReconciliationLine."Statement Amount");
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure BankPaymentApplicationBankReconciliationFCYToBankAccountFCY()
    var
        BankAccount: Record "Bank Account";
        BankAccountAppln: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        // [FEATURE] [Bank Account] [Currency]
        // [SCENARIO 223618] Bank Payment Application of Bank Acc.Reconciliation to Bank Account both in FCY
        Initialize();

        // [GIVEN] Bank Account Reconciliation Line with Amount = 100 in currency "C"
        // [GIVEN] Set Application to Bank Account "B" in currency "C"
        CreateBankAccountWithCurrency(BankAccount, LibraryERM.CreateCurrencyWithRandomExchRates());
        CreateBankAccountWithCurrency(BankAccountAppln, BankAccount."Currency Code");
        CreateBankPmtRecWithLineApplyAmount(
          BankAccount, BankAccReconciliation, BankAccReconciliationLine, WorkDate(), LibraryRandom.RandDec(100, 2),
          BankAccReconciliationLine."Account Type"::"Bank Account", BankAccountAppln."No.");

        // [WHEN] Post Bank Payment Application
        UpdateBankAccRecStmEndingBalance(BankAccReconciliation, BankAccReconciliation."Balance Last Statement" + BankAccReconciliationLine."Statement Amount");
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN] Bank Account Ledger Entry is posted with Amount = 100 for Bank Account "B"
        VerifyBankLedgEntry(BankAccount."No.", BankAccReconciliationLine."Statement Amount");
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure BankPaymentApplicationBankReconciliationToBankAccountDiffCurrencies()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        // [FEATURE] [Bank Account] [Currency]
        // [SCENARIO 223618] Bank Payment Application of Bank Acc.Reconciliation to Bank Account in different currenncies is not allowed
        Initialize();

        // [GIVEN] Bank Account Reconciliation Line with Amount = 100 in currency "C"
        // [GIVEN] Set Application to Bank Account "B" in local currency
        CreateBankAccountWithCurrency(BankAccount, LibraryERM.CreateCurrencyWithRandomExchRates());
        CreateBankPmtRecWithLineApplyAmount(
          BankAccount, BankAccReconciliation, BankAccReconciliationLine, WorkDate(), LibraryRandom.RandDec(100, 2),
          BankAccReconciliationLine."Account Type"::"Bank Account", LibraryERM.CreateBankAccountNo());

        // [WHEN] Post Bank Payment Application
        UpdateBankAccRecStmEndingBalance(BankAccReconciliation, BankAccReconciliation."Balance Last Statement" + BankAccReconciliationLine."Statement Amount");
        asserterror LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN] Error appeared 'You must apply the excessive amount of 100 "C" manually.'
        Assert.ExpectedError(
          StrSubstNo(ExcessiveAmtErr, BankAccReconciliationLine."Statement Amount", BankAccount."Currency Code"));
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure PostPmtWithDateLessThanInvoicePostingDate()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 255420] Posting payments only for Bank Account Reconciliation Line with "Transaction Date" less than "Posting Date" of applied Sales Invoice is not allowed.
        Initialize();

        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = 15.01
        LibraryERM.CreateBankAccount(BankAccount);
        CreateBankPmtReconcWithLine(
          BankAccount, BankAccReconciliation, BankAccReconciliationLine, WorkDate() - 1, LibraryRandom.RandDec(100, 2));

        // [GIVEN] Posted Sales Invoice with "Posting Date" = 16.01 > "Transaction Date", which is applied to Bank Account Reconciliation Line
        CreateCustAndPostSalesInvoice(CustLedgerEntry, '');
        ApplyCustLedgEntry(BankAccReconciliationLine, CustLedgerEntry);
        CustLedgerEntry."Applies-to ID" := BankAccReconciliationLine.GetAppliesToID();
        CustLedgerEntry.Modify();

        // [WHEN] Post Bank Payment Application
        UpdateBankAccRecStmEndingBalance(BankAccReconciliation, BankAccReconciliation."Balance Last Statement" + BankAccReconciliationLine."Statement Amount");
        asserterror LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN] Error appeared "You are not allowed to apply and post an entry to an entry with an earlier posting date."
        Assert.ExpectedError(
          'You are not allowed to apply and post an entry to an entry with an earlier posting date');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegativeAmountCanBeAppliedInPmtReconJnl()
    var
        BankAcc: Record "Bank Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 284536] Payment Reconciliation line with negative amount automatically applies when validate G/L Account No.

        Initialize();
        LibraryERM.CreateBankAccount(BankAcc);

        // [GIVEN] Payment Reconciliation Line with Amount = -100
        CreateBankPmtReconcWithLine(
          BankAcc, BankAccRecon, BankAccReconLine, WorkDate(), -LibraryRandom.RandDec(100, 2));

        // [GIVEN] Payment Reconciliation Journal opened and focused on line created before
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);

        // [WHEN] Validate "Account No." with new G/L Account No.
        PmtReconJnl."Account No.".SetValue(LibraryERM.CreateGLAccountNo());

        // [THEN] "Applied Amount" = -100
        PmtReconJnl."Applied Amount".AssertEquals(BankAccReconLine."Statement Amount");

        // [THEN] Difference = 0
        PmtReconJnl.Difference.AssertEquals(0);
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandlerWithNewDate')]
    [Scope('OnPrem')]
    procedure PostPmtWithDateLessThanInvoicePostingDateByUpdateStatementDate()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccountStatement: Record "Bank Account Statement";
        StatementDate: Date;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 419948] When posting Bank Payment Reconciliation users can edit Statement Date before posting
        Initialize();

        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = 15.01
        LibraryERM.CreateBankAccount(BankAccount);
        CreateBankPmtReconcWithLine(BankAccount, BankAccReconciliation, BankAccReconciliationLine, WorkDate(), LibraryRandom.RandDec(100, 2));

        // [GIVEN] Posted Sales Invoice applied to this Bank Account Reconciliation Line
        CreateCustAndPostSalesInvoice(CustLedgerEntry, '');
        ApplyCustLedgEntry(BankAccReconciliationLine, CustLedgerEntry);
        CustLedgerEntry."Applies-to ID" := BankAccReconciliationLine.GetAppliesToID();
        CustLedgerEntry.Modify();

        // [GIVEN] Prepare Bank Account Reconciliation for posting
        UpdateBankAccRecStmEndingBalance(BankAccReconciliation, BankAccReconciliation."Balance Last Statement" + BankAccReconciliationLine."Statement Amount");

        // [WHEN] Post the Bank Account Reconciliation with changing date on page to 20.01
        StatementDate := WorkDate() + LibraryRandom.RandInt(10);
        LibraryVariableStorage.Enqueue(StatementDate);
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);


        // [THEN] Satement Date on posted Statement is 20.01
        BankAccountStatement.Get(BankAccReconciliation."Bank Account No.", BankAccReconciliation."Statement No.");
        BankAccountStatement.TestField("Statement Date", StatementDate);
    end;

    [Test]
    [HandlerFunctions('CreatePaymentWithPostingModalPageHandler,SelectTemplatePageHandler')]
    procedure ApplicationsToTheSameEntryShouldErrorInPaymentRecJournal()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJournalTemplate: Record "Gen. Journal Template";
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
        GeneralJournalTemplateList: Page "General Journal Template List";
        PaymentJournal: TestPage "Payment Journal";
        ExpectedErr: Text;
    begin
        // [SCENARIO] If entries are being applied through a Payment Journal, if shouldn't be possible to apply them to a Payment Rec. Journal.
        // [GIVEN] A purchase invoice
        CreateVendAndPostPurchInvoice(VendorLedgerEntry, '');
        VendorLedgerEntry.CalcFields(Amount);
        // [GIVEN] Payment created for this purchase invoice
        PaymentJournal.Trap();
        LibraryVariableStorage.Enqueue('DOC01');
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        LibraryVariableStorage.Enqueue(WorkDate());
        VendorLedgerEntries.OpenView();
        VendorLedgerEntries.GoToRecord(VendorLedgerEntry);

        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        if GenJournalTemplate.Count() < 2 then // f. ex.: RU has 2 Payment Gen. Jnl Templates in demo database which triggers an extra page onopen
            GeneralJournalTemplateList.RunModal();

        VendorLedgerEntries."Create Payment".Invoke();

        PaymentJournal.Close();
        // [GIVEN] A payment reconciliation journal with a line for that amount
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccount."No.", BankAccReconciliation."Statement Type"::"Payment Application");
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Transaction Date", WorkDate());
        BankAccReconciliationLine.Validate("Statement Amount", -VendorLedgerEntry.Amount);
        BankAccReconciliationLine.Validate("Applied Amount", 0);
        BankAccReconciliationLine.Modify(true);
        // [WHEN] Attempting to apply to this entry in the payment reconciliation journal
        TempPaymentApplicationProposal.TransferFromBankAccReconLine(BankAccReconciliationLine);
        TempPaymentApplicationProposal."Account Type" := TempPaymentApplicationProposal."Account Type"::Vendor;
        TempPaymentApplicationProposal."Account No." := VendorLedgerEntry."Vendor No.";
        TempPaymentApplicationProposal."Applies-to Entry No." := VendorLedgerEntry."Entry No.";
        TempPaymentApplicationProposal.Insert();
        // [THEN] An error should occur
        asserterror TempPaymentApplicationProposal.Validate(Applied, true);
        ExpectedErr := 'This entry has an ongoing application process';
        Assert.IsTrue(CopyStr(GetLastErrorText(), 1, StrLen(ExpectedErr)) = ExpectedErr, 'The error shown should be that the entry has been applied in another journal.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankAccountAsAccountNoWithSameCurrencyCodeAsLocalCurrency()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 540188] No error while entering G/L Account in Bal. Account No. when Bank Account used with local Currency
        Initialize();

        // [GIVEN] Create Currency Code X with Exchange Rate and set as local currency
        CurrencyCode := CreateCurrencyAndExchangeRate(LibraryRandom.RandDecInRange(1, 1, 0));
        UpdateCurrencyCodeOnGLSetup(CurrencyCode);

        // [THEN] Create Bank Account and update Currency Code X
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Currency Code", CurrencyCode);
        BankAccount.Modify(true);

        // [THEN] Create Payment Line for Bank when Account Type: Bank Account
        CreateBankPayment(
            GenJournalLine, GenJournalLine."Account Type"::"Bank Account", BankAccount."No.",
            GenJournalLine."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDecInRange(100, 200, 2));

        // [WHEN] Validating Bal. Account No. has been validated without any error
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalLine.Modify(true);

        // [THEN] Verify: The Currency Code is equal to initial currency code as per bank
        Assert.AreEqual(BankAccount."Currency Code", GenJournalLine."Currency Code", GenJournalLine.FieldCaption("Currency Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankAccountAsBalAccountNoWithSameCurrencyCodeAsLocalCurrency()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 540188] No error while entering G/L Account in Account No. when Bank Account used with local Currency
        Initialize();

        // [GIVEN] Create Currency Code X with Exchange Rate and set as local currency
        CurrencyCode := CreateCurrencyAndExchangeRate(LibraryRandom.RandDecInRange(1, 1, 0));
        UpdateCurrencyCodeOnGLSetup(CurrencyCode);

        // [THEN] Create Bank Account and update Currency Code X
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Currency Code", CurrencyCode);
        BankAccount.Modify(true);

        // [THEN] Create Payment Line for Bank when Account Type: G/L Account
        CreateBankPayment(
            GenJournalLine, GenJournalLine."Account Type"::"G/L Account", '',
            GenJournalLine."Bal. Account Type"::"Bank Account", BankAccount."No.", LibraryRandom.RandDecInRange(100, 200, 2));

        // [WHEN] Validating Account No. has been validated without any error
        GenJournalLine.Validate("Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalLine.Modify(true);

        // [THEN] Verify: The Currency Code is equal to initial currency code as per bank
        Assert.AreEqual(BankAccount."Currency Code", GenJournalLine."Currency Code", GenJournalLine.FieldCaption("Currency Code"));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test Bank Payment Application");
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibrarySetupStorage.Restore();
        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Test Bank Payment Application");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        UpdateCustPostingGrp();

        Initialized := true;
        Commit();
        LibrarySetupStorage.SaveGeneralLedgerSetup();
        LibrarySetupStorage.Save(DATABASE::"Source Code Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Test Bank Payment Application");
    end;

    local procedure BlockDimValue(var DimValue: Record "Dimension Value")
    begin
        DimValue.Validate(Blocked, true);
        DimValue.Modify(true);
        Commit();
    end;

    local procedure UnblockDimValue(var DimValue: Record "Dimension Value")
    begin
        DimValue.Validate(Blocked, false);
        DimValue.Modify(true);
        Commit();
    end;

    local procedure BlockDimCombination(DimCode1: Code[20]; DimCode2: Code[20])
    var
        DimCombination: Record "Dimension Combination";
    begin
        DimCombination.Init();
        DimCombination.Validate("Dimension 1 Code", DimCode1);
        DimCombination.Validate("Dimension 2 Code", DimCode2);
        DimCombination.Validate("Combination Restriction", DimCombination."Combination Restriction"::Blocked);
        DimCombination.Insert();
        Commit();
    end;

    local procedure UnblockDimCombination(DimCode1: Code[20]; DimCode2: Code[20])
    var
        DimCombination: Record "Dimension Combination";
    begin
        DimCombination.Get(DimCode1, DimCode2);
        DimCombination.Delete(true);
        Commit();
    end;

    local procedure CreateBankAccountWithCurrency(var BankAccount: Record "Bank Account"; CurrencyCode: Code[10])
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Currency Code", CurrencyCode);
        BankAccount.Modify(true);
    end;

    local procedure CreateBankPmtReconcWithLine(BankAcc: Record "Bank Account"; var BankAccRecon: Record "Bank Acc. Reconciliation"; var BankAccReconLine: Record "Bank Acc. Reconciliation Line"; TransactionDate: Date; StmtLineAmt: Decimal)
    begin
        Clear(BankAccRecon);
        Clear(BankAccReconLine);

        // Create Bank Rec Header
        LibraryERM.CreateBankAccReconciliation(
          BankAccRecon, BankAcc."No.", BankAccRecon."Statement Type"::"Payment Application");
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconLine, BankAccRecon);

        // Create Bank Rec Line
        BankAccReconLine.Validate("Transaction Date", TransactionDate);
        BankAccReconLine.Validate(Description, 'Hello World');
        BankAccReconLine.Validate("Statement Amount", StmtLineAmt);
        BankAccReconLine.Modify(true);
    end;

    local procedure CreateBankPmtRecWithLineApplyAmount(BankAccount: Record "Bank Account"; var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; TransactionDate: Date; StmtLineAmt: Decimal; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    begin
        CreateBankPmtReconcWithLine(BankAccount, BankAccReconciliation, BankAccReconciliationLine, TransactionDate, StmtLineAmt);
        BankAccReconciliationLine.Validate("Account Type", AccountType);
        BankAccReconciliationLine.Validate("Account No.", AccountNo);
        BankAccReconciliationLine.Modify(true);
        BankAccReconciliationLine.TransferRemainingAmountToAccount();
        BankAccReconciliationLine.Find();
    end;

    local procedure CreateCustAndPostSalesInvoice(var CustLedgEntry: Record "Cust. Ledger Entry"; CurrencyCode: Code[10])
    var
        Cust: Record Customer;
    begin
        LibrarySales.CreateCustomer(Cust);
        CreateSalesInvoiceAndPost(Cust, CustLedgEntry, CurrencyCode);
    end;

    local procedure CreateSalesInvoiceAndPost(var Cust: Record Customer; var CustLedgEntry: Record "Cust. Ledger Entry"; CurrencyCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Cust."No.");
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);

        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Modify(true);

        CustLedgEntry.SetRange("Customer No.", Cust."No.");
        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
        CustLedgEntry.SetRange("Document No.", LibrarySales.PostSalesDocument(SalesHeader, true, true));
        CustLedgEntry.FindFirst();
        CustLedgEntry.CalcFields("Remaining Amount");
    end;

    local procedure CreateVendAndPostPurchInvoice(var VendLedgEntry: Record "Vendor Ledger Entry"; CurrencyCode: Code[10])
    var
        Vend: Record Vendor;
    begin
        LibraryPurch.CreateVendor(Vend);
        CreatePurchInvoiceAndPost(Vend, VendLedgEntry, CurrencyCode);
    end;

    local procedure CreatePurchInvoiceAndPost(var Vend: Record Vendor; var VendLedgEntry: Record "Vendor Ledger Entry"; CurrencyCode: Code[10])
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        Item: Record Item;
    begin
        LibraryPurch.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, Vend."No.");
        PurchHeader.Validate("Currency Code", CurrencyCode);
        PurchHeader.Modify(true);

        LibraryInventory.CreateItem(Item);
        LibraryPurch.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, Item."No.", 1);
        PurchLine.Validate("Direct Unit Cost", 100);
        PurchLine.Modify(true);

        VendLedgEntry.SetRange("Vendor No.", Vend."No.");
        VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Invoice);
        VendLedgEntry.SetRange("Document No.", LibraryPurch.PostPurchaseDocument(PurchHeader, true, true));
        VendLedgEntry.FindFirst();
    end;

    local procedure UpdateSourceCodeSetupForPmtReconJnl(NewSourceCode: Code[10])
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        SourceCodeSetup.Validate("Payment Reconciliation Journal", NewSourceCode);
        SourceCodeSetup.Modify(true);
    end;

    local procedure SetupCurrencyWithExchRates(): Code[10]
    var
        Currency: Record Currency;
        CurrExchRateAmount: Decimal;
    begin
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Realized Gains Acc.", LibraryERM.CreateGLAccountNo());
        Currency.Validate("Realized Losses Acc.", LibraryERM.CreateGLAccountNo());
        Currency.Modify(true);
        CurrExchRateAmount := LibraryRandom.RandDec(100, 2);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(), 1 / CurrExchRateAmount, 1 / CurrExchRateAmount);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate() + 1, 1 / (CurrExchRateAmount - 1), 1 / (CurrExchRateAmount - 1));
        exit(Currency.Code);
    end;

    local procedure ApplyCustLedgEntry(BankAccReconLine: Record "Bank Acc. Reconciliation Line"; CustLedgEntry: Record "Cust. Ledger Entry")
    var
        AppliedPmtEntry: Record "Applied Payment Entry";
    begin
        Clear(AppliedPmtEntry);
        AppliedPmtEntry.TransferFromBankAccReconLine(BankAccReconLine);

        AppliedPmtEntry.Validate("Account Type", AppliedPmtEntry."Account Type"::Customer);
        AppliedPmtEntry.Validate("Account No.", CustLedgEntry."Customer No.");
        AppliedPmtEntry.Validate("Applies-to Entry No.", CustLedgEntry."Entry No.");
        AppliedPmtEntry.Insert(true);
        Commit();
    end;

    local procedure ApplyVendLedgEntry(BankAccReconLine: Record "Bank Acc. Reconciliation Line"; VendLedgEntry: Record "Vendor Ledger Entry")
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
    begin
        Clear(AppliedPaymentEntry);
        AppliedPaymentEntry.TransferFromBankAccReconLine(BankAccReconLine);

        AppliedPaymentEntry.Validate("Account Type", AppliedPaymentEntry."Account Type"::Vendor);
        AppliedPaymentEntry.Validate("Account No.", VendLedgEntry."Vendor No.");
        AppliedPaymentEntry.Validate("Applies-to Entry No.", VendLedgEntry."Entry No.");
        AppliedPaymentEntry.Insert(true);
        Commit();
    end;

    local procedure VerifyCustLedgEntry(CustNo: Code[20])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.SetRange("Customer No.", CustNo);
        CustLedgEntry.FindSet();
        repeat
            Assert.IsTrue(not CustLedgEntry.Open, 'Entry is closed');
        until CustLedgEntry.Next() = 0;
    end;

    local procedure VerifyVendLedgEntry(VendNo: Code[20])
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry.SetRange("Vendor No.", VendNo);
        VendLedgEntry.FindSet();
        repeat
            Assert.IsTrue(not VendLedgEntry.Open, 'Entry is closed');
        until VendLedgEntry.Next() = 0;
    end;

    local procedure VerifyBankLedgEntry(BankAccNo: Code[20]; ExpAmt: Decimal)
    var
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
    begin
        BankAccLedgEntry.SetRange("Bank Account No.", BankAccNo);
        BankAccLedgEntry.CalcSums(Amount);
        BankAccLedgEntry.TestField(Amount, ExpAmt);
    end;

    local procedure VerifyLastGLRegisterSourceCode(ExpectedSourceCode: Code[10])
    var
        GLRegister: Record "G/L Register";
        GLEntry: Record "G/L Entry";
    begin
        GLRegister.FindLast();
        Assert.AreEqual(ExpectedSourceCode, GLRegister."Source Code", GLRegister.FieldCaption("Source Code"));

        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        GLEntry.FindSet();
        repeat
            Assert.AreEqual(ExpectedSourceCode, GLEntry."Source Code", GLEntry.FieldCaption("Source Code"));
        until GLEntry.Next() = 0;
    end;

    local procedure VerifyMinMaxAmounts(Amount: Decimal; TolerancePct: Decimal; MinAmount: Decimal; MaxAmount: Decimal)
    begin
        Assert.AreEqual(Round(Amount - Amount * TolerancePct / 100), MinAmount, 'Min Amount was not set to a correct value');
        Assert.AreEqual(Round(Amount + Amount * TolerancePct / 100), MaxAmount, 'Max Amount was not set to a correct value');
    end;

    local procedure UpdateCustPostingGrp()
    var
        CustPostingGroup: Record "Customer Posting Group";
        GLAcc: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAcc);
        if CustPostingGroup.FindSet() then
            repeat
                if CustPostingGroup."Payment Disc. Debit Acc." = '' then begin
                    CustPostingGroup.Validate("Payment Disc. Debit Acc.", GLAcc."No.");
                    CustPostingGroup.Modify(true);
                end;
                if CustPostingGroup."Payment Disc. Credit Acc." = '' then begin
                    CustPostingGroup.Validate("Payment Disc. Credit Acc.", GLAcc."No.");
                    CustPostingGroup.Modify(true);
                end;
            until CustPostingGroup.Next() = 0;
    end;

    local procedure OpenPmtReconJnl(BankAccRecon: Record "Bank Acc. Reconciliation"; var PmtReconJnl: TestPage "Payment Reconciliation Journal")
    var
        PmtReconciliationJournals: TestPage "Pmt. Reconciliation Journals";
    begin
        PmtReconciliationJournals.OpenView();
        PmtReconciliationJournals.GotoRecord(BankAccRecon);
        PmtReconJnl.Trap();
        PmtReconciliationJournals.EditJournal.Invoke();
    end;

    local procedure UpdateBankAccRecStmEndingBalance(var BankAccRecon: Record "Bank Acc. Reconciliation"; NewStmEndingBalance: Decimal)
    begin
        BankAccRecon.Validate("Statement Ending Balance", NewStmEndingBalance);
        BankAccRecon.Modify();
    end;

    local procedure CreateCurrencyAndExchangeRate(ExchangeRateAmt: Decimal): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Residual Gains Account", LibraryERM.CreateGLAccountNo());
        Currency.Validate("Residual Losses Account", Currency."Residual Gains Account");
        Currency.Validate("Realized G/L Gains Account", LibraryERM.CreateGLAccountNo());
        Currency.Validate("Realized G/L Losses Account", Currency."Realized G/L Gains Account");
        Currency.Modify(true);

        CreateRandomExchangeRate(Currency.Code, WorkDate(), ExchangeRateAmt);
        exit(Currency.Code);
    end;

    local procedure CreateRandomExchangeRate(CurrencyCode: Code[10]; StartingDate: Date; ExchangeRateAmt: Decimal)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        if not CurrencyExchangeRate.Get(CurrencyCode, StartingDate) then begin
            CurrencyExchangeRate.Init();
            CurrencyExchangeRate.Validate("Currency Code", CurrencyCode);
            CurrencyExchangeRate.Validate("Starting Date", StartingDate);
            CurrencyExchangeRate.Insert(true);

            CurrencyExchangeRate.Validate("Exchange Rate Amount", ExchangeRateAmt);
            CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");

            CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");
            CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
            CurrencyExchangeRate.Modify(true);
        end;
    end;

    local procedure UpdateCurrencyCodeOnGLSetup(CurrencyCode: Code[10])
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup."LCY Code" := '';       // to avoid error on updating LCY Code
        GLSetup.Validate("LCY Code", CurrencyCode);
        GLSetup.Modify(true);
    end;

    local procedure CreateBankPayment(
        var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20];
        BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20]; LineAmount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreatePaymentGenJournalBatch(GenJournalBatch);
        LibraryJournals.CreateGenJournalLine2(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
            AccountType, AccountNo, BalAccountType, BalAccountNo, LineAmount);
    end;

    local procedure CreatePaymentGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    [Test]
    [HandlerFunctions('BankAccReconciliationPageHandler')]
    procedure OutstandingChecksRespectStatementDate()
    var
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccount: Record "Bank Account";
        CheckLedgerEntry: Record "Check Ledger Entry";
        Vendor: Record Vendor;
        VendLedgEntry: Record "Vendor Ledger Entry";
        PaymentJournalLine: Record "Gen. Journal Line";
        PaymentJournalBatch: Record "Gen. Journal Batch";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        Amount: Decimal;
        OutstandingTotal: Decimal;
    begin
        // [600826 SCENARIO] Outstanding Checks should only show checks with Posting Date on or before Statement Date
        Initialize();

        // [GIVEN] Set Work Date 
        WorkDate := CalcDate('<+2M>', WorkDate());

        // [GIVEN] Create Vendor and Payment Journal Batch
        LibraryPurch.CreateVendor(Vendor);
        CreatePaymentGenJournalBatch(PaymentJournalBatch);
        PaymentJournalBatch.Validate("Bal. Account Type", PaymentJournalBatch."Bal. Account Type"::"Bank Account");
        LibraryERM.CreateBankAccount(BankAccount);
        PaymentJournalBatch.Validate("Bal. Account No.", BankAccount."No.");
        PaymentJournalBatch.Validate("Copy VAT Setup to Jnl. Lines", true);
        PaymentJournalBatch.Modify(true);

        // [GIVEN] Use a random amount for payment
        Amount := LibraryRandom.RandDecInRange(1000, 5000, 2);

        // [GIVEN] Create a new purchase invoice for this payment line using the above created Vendor
        CreatePurchInvoiceAndPost(Vendor, VendLedgEntry, '');

        // [GIVEN] Create Payment Journal Line in selected batch
        LibraryJournals.CreateGenJournalLine2(
            PaymentJournalLine,
            PaymentJournalBatch."Journal Template Name",
            PaymentJournalBatch.Name,
            PaymentJournalLine."Document Type"::Payment,
            PaymentJournalLine."Account Type"::Vendor,
            Vendor."No.",
            PaymentJournalLine."Bal. Account Type"::"Bank Account",
            PaymentJournalBatch."Bal. Account No.",
            Amount);
        PaymentJournalLine.Validate("Posting Date", WorkDate());
        PaymentJournalLine.validate("Applies-to Doc. Type", PaymentJournalLine."Applies-to Doc. Type"::Invoice);
        PaymentJournalLine.Validate("Applies-to Doc. No.", VendLedgEntry."Document No.");
        PaymentJournalLine.Validate("Bank Payment Type", PaymentJournalLine."Bank Payment Type"::"manual check");
        PaymentJournalLine.Modify(true);

        // [WHEN] Post the Payment Journal
        LibraryERM.PostGeneralJnlLine(PaymentJournalLine);

        // [GIVEN] Change Work Date back to today
        WorkDate := WorkDate();

        // [GIVEN] Create Bank Account Reconciliation for bank account and Statement Date 
        LibraryERM.CreateBankAccReconciliation(BankAccRecon, BankAccount."No.", BankAccRecon."Statement Type"::"Bank Reconciliation");
        BankAccRecon.Validate("Statement Date", WorkDate());
        BankAccRecon.Modify(true);

        // [THEN] Review Outstanding Checks
        CheckLedgerEntry.SetLoadFields("Bank Account No.", "Entry Status", "Statement Status", "Posting Date");
        CheckLedgerEntry.SetRange("Bank Account No.", BankAccount."No.");
        CheckLedgerEntry.SetRange("Entry Status", CheckLedgerEntry."Entry Status"::Posted);
        CheckLedgerEntry.SetFilter("Statement Status", '<>%1', CheckLedgerEntry."Statement Status"::Closed);
        CheckLedgerEntry.SetFilter("Posting Date", '<=%1', BankAccRecon."Statement Date");
        CheckLedgerEntry.CalcSums(Amount);
        OutstandingTotal := CheckLedgerEntry.Amount;

        // [THEN] Open page 381 'Apply Bank Acc. Ledger Entries' and check 'Total on Outstanding Checks'
        BankAccReconciliationPage.OpenEdit();
        BankAccReconciliationPage.GoToRecord(BankAccRecon);
        BankAccReconciliationPage.ApplyBankLedgerEntries.CheckBalance.Drilldown();

        // [ASSERT] Outstanding checks only include checks posted on or before Statement Date
        Assert.AreEqual(Format(OutstandingTotal), BankAccReconciliationPage.ApplyBankLedgerEntries.CheckBalance.Value, 'Outstanding checks include payments posted after statement date');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostAndReconcilePageHandler(var PostPmtsAndRecBankAcc: TestPage "Post Pmts and Rec. Bank Acc.")
    begin
        PostPmtsAndRecBankAcc.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure PostAndReconcilePageStatementDateHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostAndReconcilePageHandlerWithNewDate(var PostPmtsAndRecBankAcc: TestPage "Post Pmts and Rec. Bank Acc.")
    begin
        PostPmtsAndRecBankAcc.StatementDate.SetValue(LibraryVariableStorage.DequeueDate());
        PostPmtsAndRecBankAcc.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CreatePaymentWithPostingModalPageHandler(var CreatePayment: TestPage "Create Payment")
    var
        StartingDocumentNo: Text;
    begin
        StartingDocumentNo := LibraryVariableStorage.DequeueText();
        CreatePayment."Bank Account".SetValue(LibraryVariableStorage.DequeueText());
        CreatePayment."Posting Date".SetValue(LibraryVariableStorage.DequeueDate());
        CreatePayment."Starting Document No.".SetValue(StartingDocumentNo);
        CreatePayment.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure SelectTemplatePageHandler(var Page: TestPage "General Journal Template List")
    begin
        Page.OK().Invoke();
    end;

    [PageHandler]
    procedure BankAccReconciliationPageHandler(var CheckLedgerEntriesPage: TestPage "Check Ledger Entries")
    begin
        CheckLedgerEntriesPage.OK().Invoke();
    end;
}

