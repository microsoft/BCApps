codeunit 134009 "ERM Finance Charge Memo Apply"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Finance Charge Memo] [Sales]
        isInitialized := false;
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        RemainingAmountError: Label '%1 must be %2.';
        VATDateError: Label 'VAT Date should be set on Finance Charge Memo';
        FinanceChargeMemoError: Label 'Finance Charge Memo must not be exist.';
        UnappliedError: Label '%1 %2 field must be true after Unapply entries.';

    [Test]
    [Scope('OnPrem')]
    procedure FinanceChargeMemoAndApply()
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        GenJournalLine: Record "Gen. Journal Line";
        CurrentDate: Date;
        ChargeMemoNo: Code[20];
    begin
        // Covers documents TC_ID= 122636 AND 137015.
        // Check that Finance Charge memo does not exist after issue and Customer Ledger Entry for Remaining amount after Post General
        // Journal Lines.

        // Create Sales Invoice, Finance Charge Memo and Issue it, Post General Journal Lines and Take backup for Current Workdate.
        Initialize();
        CurrentDate := WorkDate();
        ChargeMemoNo := CreateInvoiceFinanceChargeMemo(GenJournalLine);

        // Verify: Check Finance Charge Memo is no more after issuing and Customer Ledger Entry for Remaining Amount after Post General
        // Journal Lines.
        Assert.IsFalse(FinanceChargeMemoHeader.Get(ChargeMemoNo), FinanceChargeMemoError);
        VerifyCustLedgerEntryForRemAmt(GenJournalLine);

        // Cleanup: Roll back the previous Workdate.
        WorkDate := CurrentDate;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyAndUnapplyCustEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrentDate: Date;
    begin
        // Covers documents TC_ID= 122637 AND 137016.
        // Check Customer Ledger Entry for Remaining Amount, Detailed Ledger Entry for Unapplied Entries after Post General
        // Journal Lines, Apply and Unapply Customer Ledger Entries.

        // Create Sales Invoice, Finance Charge Memo and Issue it, Post General Journal Lines, Apply and unapply them and
        // Take backup for Current Workdate
        Initialize();
        CurrentDate := WorkDate();
        CreateInvoiceFinanceChargeMemo(GenJournalLine);
        ApplyAndPostCustomerEntry(GenJournalLine."Document No.", GenJournalLine.Amount);
        UnapplyCustLedgerEntry(GenJournalLine."Account No.", GenJournalLine."Document No.");

        // Verify: Detailed Ledger Entry for Unapplied Entries and Customer Ledger Entries for Remaining Amount.
        VerifyUnappliedDtldLedgEntry(GenJournalLine."Account No.", GenJournalLine."Document No.");
        VerifyCustLedgerEntryForRemAmt(GenJournalLine);

        // Cleanup: Roll back the previous Workdate.
        WorkDate := CurrentDate;
    end;

    [Test]
    [HandlerFunctions('SuggestFinChargeMemoLinesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IssueFinanceChargeMemoWithInvoiceRounding()
    var
        Customer: Record Customer;
        FinanceChargeTerms: Record "Finance Charge Terms";
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        CustomerPostingGroup: Record "Customer Posting Group";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        InvoiceRoundingPrecision: Decimal;
        InvoiceDate: Date;
        FinanceChargeDate: Date;
    begin
        // [FEATURE] [Invoice Rounding] [Additional Fee]
        // [SCENARIO 390927] System posts positive invoice rounding amount on issueing finance charge memo when "Post Addition Fee" = FALSE in finance charge term.
        Initialize();

        InvoiceRoundingPrecision := 1;
        LibraryERM.SetInvRoundingPrecisionLCY(InvoiceRoundingPrecision);

        InvoiceDate := WorkDate();
        FinanceChargeDate := InvoiceDate + 62;

        CreateFinanceChargeTerms(FinanceChargeTerms, true, false);

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Fin. Charge Terms Code", FinanceChargeTerms.Code);
        Customer.Modify(true);

        CustomerPostingGroup.Get(Customer."Customer Posting Group");

        CreateAndPostSalesInvoice(Customer, InvoiceDate, 1000);

        CreateFinanceChargeMemoWithLines(FinanceChargeMemoHeader, Customer, FinanceChargeDate);

        VerifyFinChargeMemoRoundingLineExists(FinanceChargeMemoHeader."No.", CustomerPostingGroup."Invoice Rounding Account");
        Assert.AreNotEqual('', FinanceChargeMemoHeader."VAT Reporting Date", VATDateError);

        LibraryERM.IssueFinanceChargeMemo(FinanceChargeMemoHeader);

        FindIssuedFinanceChargeMemo(IssuedFinChargeMemoHeader, FinanceChargeMemoHeader);

        VerifyGLAccountOnGLEntryIssuedFinanceChargeMemo(IssuedFinChargeMemoHeader, CustomerPostingGroup."Invoice Rounding Account");
        VerifyGLAccountOnGLEntryIssuedFinanceChargeMemo(IssuedFinChargeMemoHeader, CustomerPostingGroup."Additional Fee Account");
        VerifyGLAccountOnGLEntryIssuedFinanceChargeMemo(IssuedFinChargeMemoHeader, CustomerPostingGroup."Receivables Account");
    end;

    [Test]
    [HandlerFunctions('SuggestFinChargeMemoLinesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IssueFinanceChargeMemoWithInvoiceRoundingPostAdditionalFee()
    var
        Customer: Record Customer;
        FinanceChargeTerms: Record "Finance Charge Terms";
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        CustomerPostingGroup: Record "Customer Posting Group";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        InvoiceRoundingPrecision: Decimal;
        InvoiceDate: Date;
        FinanceChargeDate: Date;
    begin
        // [FEATURE] [Invoice Rounding] [Additional Fee]
        // [SCENARIO 390927] System posts positive invoice rounding amount on issueing finance charge memo when "Post Addition Fee" = TRUE in finance charge term.
        Initialize();

        InvoiceRoundingPrecision := 1;
        LibraryERM.SetInvRoundingPrecisionLCY(InvoiceRoundingPrecision);

        InvoiceDate := WorkDate();
        FinanceChargeDate := InvoiceDate + 62;

        CreateFinanceChargeTerms(FinanceChargeTerms, true, true);

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Fin. Charge Terms Code", FinanceChargeTerms.Code);
        Customer.Modify(true);

        CustomerPostingGroup.Get(Customer."Customer Posting Group");

        CreateAndPostSalesInvoice(Customer, InvoiceDate, 1000);

        CreateFinanceChargeMemoWithLines(FinanceChargeMemoHeader, Customer, FinanceChargeDate);

        VerifyFinChargeMemoRoundingLineExists(FinanceChargeMemoHeader."No.", CustomerPostingGroup."Invoice Rounding Account");

        LibraryERM.IssueFinanceChargeMemo(FinanceChargeMemoHeader);

        FindIssuedFinanceChargeMemo(IssuedFinChargeMemoHeader, FinanceChargeMemoHeader);

        VerifyGLAccountOnGLEntryIssuedFinanceChargeMemo(IssuedFinChargeMemoHeader, CustomerPostingGroup."Invoice Rounding Account");
        VerifyGLAccountOnGLEntryIssuedFinanceChargeMemo(IssuedFinChargeMemoHeader, CustomerPostingGroup."Additional Fee Account");
        VerifyGLAccountOnGLEntryIssuedFinanceChargeMemo(IssuedFinChargeMemoHeader, CustomerPostingGroup."Receivables Account");
    end;

    [Test]
    [HandlerFunctions('SuggestFinChargeMemoLinesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IssueFinanceChargeMemoWithNegativeInvoiceRounding()
    var
        Customer: Record Customer;
        FinanceChargeTerms: Record "Finance Charge Terms";
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        CustomerPostingGroup: Record "Customer Posting Group";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        InvoiceRoundingPrecision: Decimal;
        InvoiceDate: Date;
        FinanceChargeDate: Date;
    begin
        // [FEATURE] [Invoice Rounding] [Additional Fee]
        // [SCENARIO 390927] System posts negative invoice rounding amount on issueing finance charge memo when "Post Addition Fee" = FALSE in finance charge term.
        Initialize();

        InvoiceRoundingPrecision := 1;
        LibraryERM.SetInvRoundingPrecisionLCY(InvoiceRoundingPrecision);

        InvoiceDate := WorkDate();
        FinanceChargeDate := InvoiceDate + 62;

        CreateFinanceChargeTerms(FinanceChargeTerms, true, false);

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Fin. Charge Terms Code", FinanceChargeTerms.Code);
        Customer.Modify(true);

        CustomerPostingGroup.Get(Customer."Customer Posting Group");

        CreateAndPostSalesInvoice(Customer, InvoiceDate, 900);

        CreateFinanceChargeMemoWithLines(FinanceChargeMemoHeader, Customer, FinanceChargeDate);

        VerifyFinChargeMemoRoundingLineExists(FinanceChargeMemoHeader."No.", CustomerPostingGroup."Invoice Rounding Account");

        LibraryERM.IssueFinanceChargeMemo(FinanceChargeMemoHeader);

        FindIssuedFinanceChargeMemo(IssuedFinChargeMemoHeader, FinanceChargeMemoHeader);

        VerifyGLAccountOnGLEntryIssuedFinanceChargeMemo(IssuedFinChargeMemoHeader, CustomerPostingGroup."Invoice Rounding Account");
        VerifyGLAccountOnGLEntryIssuedFinanceChargeMemo(IssuedFinChargeMemoHeader, CustomerPostingGroup."Additional Fee Account");
        VerifyGLAccountOnGLEntryIssuedFinanceChargeMemo(IssuedFinChargeMemoHeader, CustomerPostingGroup."Receivables Account");
    end;

    [Test]
    [HandlerFunctions('SuggestFinChargeMemoLinesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IssueFinanceChargeMemoWithNegativeInvoiceRoundingPostAdditionalFee()
    var
        Customer: Record Customer;
        FinanceChargeTerms: Record "Finance Charge Terms";
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        CustomerPostingGroup: Record "Customer Posting Group";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        InvoiceRoundingPrecision: Decimal;
        InvoiceDate: Date;
        FinanceChargeDate: Date;
    begin
        // [FEATURE] [Invoice Rounding] [Additional Fee]
        // [SCENARIO 390927] System posts negative invoice rounding amount on issueing finance charge memo when "Post Addition Fee" = TRUE in finance charge term.
        Initialize();

        InvoiceRoundingPrecision := 1;
        LibraryERM.SetInvRoundingPrecisionLCY(InvoiceRoundingPrecision);

        InvoiceDate := WorkDate();
        FinanceChargeDate := InvoiceDate + 62;

        CreateFinanceChargeTerms(FinanceChargeTerms, true, true);

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Fin. Charge Terms Code", FinanceChargeTerms.Code);
        Customer.Modify(true);

        CustomerPostingGroup.Get(Customer."Customer Posting Group");

        CreateAndPostSalesInvoice(Customer, InvoiceDate, 900);

        CreateFinanceChargeMemoWithLines(FinanceChargeMemoHeader, Customer, FinanceChargeDate);

        VerifyFinChargeMemoRoundingLineExists(FinanceChargeMemoHeader."No.", CustomerPostingGroup."Invoice Rounding Account");

        LibraryERM.IssueFinanceChargeMemo(FinanceChargeMemoHeader);

        FindIssuedFinanceChargeMemo(IssuedFinChargeMemoHeader, FinanceChargeMemoHeader);

        VerifyGLAccountOnGLEntryIssuedFinanceChargeMemo(IssuedFinChargeMemoHeader, CustomerPostingGroup."Invoice Rounding Account");
        VerifyGLAccountOnGLEntryIssuedFinanceChargeMemo(IssuedFinChargeMemoHeader, CustomerPostingGroup."Additional Fee Account");
        VerifyGLAccountOnGLEntryIssuedFinanceChargeMemo(IssuedFinChargeMemoHeader, CustomerPostingGroup."Receivables Account");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Finance Charge Memo Apply");
        // Lazy Setup.
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Finance Charge Memo Apply");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Finance Charge Memo Apply");
    end;

    local procedure CreateInvoiceFinanceChargeMemo(var GenJournalLine: Record "Gen. Journal Line") ChargeMemoNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        PostedDocumentNo: Code[20];
    begin
        // Setup: Create Sales Invoice.
        CreateSalesInvoice(SalesHeader);

        // Exercise: Post Sales Invoice, Create and Issue Finance Charge Memo then Create and Post General Journal Lines.
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        CreateFinanceChargeMemo(PostedDocumentNo, SalesHeader."Sell-to Customer No.");
        ChargeMemoNo := IssueFinanceChargeMemo(PostedDocumentNo);
        CreateGeneralJournalLines(GenJournalLine, SalesHeader."Sell-to Customer No.", -CalculateTotalAmount(PostedDocumentNo));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(ChargeMemoNo);
    end;

    local procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        Counter: Integer;
    begin
        // Random use for Quantity Sales Invoice Line and use for Greater than 1 for Sales Invoice Line.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer());
        for Counter := 1 to 2 * LibraryRandom.RandInt(3) do
            LibrarySales.CreateSalesLine(
              SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(GetFinanceChargeMinAmount(SalesHeader."Sell-to Customer No.")),
              LibraryRandom.RandInt(100));
    end;

    local procedure ApplyAndPostCustomerEntry(DocumentNo: Code[20]; AmountToApply: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, DocumentNo);
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, AmountToApply);
        CustLedgerEntry2.SetRange("Document Type", CustLedgerEntry2."Document Type"::Invoice);
        CustLedgerEntry2.SetRange("Customer No.", CustLedgerEntry."Customer No.");
        CustLedgerEntry2.SetRange(Open, true);
        CustLedgerEntry2.FindSet();
        repeat
            CustLedgerEntry2.CalcFields("Remaining Amount");
            CustLedgerEntry2.Validate("Amount to Apply", CustLedgerEntry2."Remaining Amount");
            CustLedgerEntry2.Modify(true);
        until CustLedgerEntry2.Next() = 0;

        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry2);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        FinanceChargeTerms: Record "Finance Charge Terms";
    begin
        FinanceChargeTerms.FindFirst();
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Fin. Charge Terms Code", FinanceChargeTerms.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateGeneralJournalLines(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
    end;

    local procedure CreateItem(MinPrice: Decimal): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", MinPrice + LibraryRandom.RandInt(100));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateFinanceChargeMemo(DocumentNo: Code[20]; CustomerNo: Code[20])
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinanceChargeTerms: Record "Finance Charge Terms";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        FinChrgMemoMake: Codeunit "FinChrgMemo-Make";
    begin
        Customer.Get(CustomerNo);
        FinanceChargeTerms.Get(Customer."Fin. Charge Terms Code");

        // Set Workdate according to Finance Charge Terms with Grace Period and Due Date Calculation.
        WorkDate := CalcDate(FinanceChargeTerms."Grace Period", CalcDate(FinanceChargeTerms."Due Date Calculation", WorkDate()));
        FinanceChargeMemoHeader.Init();
        FinanceChargeMemoHeader.Insert(true);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();
        FinChrgMemoMake.Set(Customer, CustLedgerEntry, FinanceChargeMemoHeader);
        FinChrgMemoMake.Code();
    end;

    local procedure CreateFinanceChargeTerms(var FinanceChargeTerms: Record "Finance Charge Terms"; PostInterest: Boolean; PostAdditioanalFee: Boolean)
    begin
        LibraryERM.CreateFinanceChargeTerms(FinanceChargeTerms);
        FinanceChargeTerms.Validate("Interest Calculation", FinanceChargeTerms."Interest Calculation"::"Open Entries");
        FinanceChargeTerms.Validate("Interest Calculation Method", FinanceChargeTerms."Interest Calculation Method"::"Average Daily Balance");
        FinanceChargeTerms.Validate("Interest Rate", 1.5);
        FinanceChargeTerms.Validate("Interest Period (Days)", 30);
        FinanceChargeTerms.Validate("Minimum Amount (LCY)", 10);
        FinanceChargeTerms.Validate("Additional Fee (LCY)", 0);
        Evaluate(FinanceChargeTerms."Grace Period", '<5D>');
        Evaluate(FinanceChargeTerms."Due Date Calculation", '<1M>');
        FinanceChargeTerms.Validate("Post Interest", PostInterest);
        FinanceChargeTerms.Validate("Post Additional Fee", PostAdditioanalFee);
        FinanceChargeTerms.Modify(true);
    end;

    local procedure CreateAndPostSalesInvoice(Customer: Record Customer; PostingDate: Date; LineAmount: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesLine.Validate("Unit Price", LineAmount);
        SalesLine.Validate("VAT %", 10);
        SalesLine.Modify(true);

        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateFinanceChargeMemoWithLines(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; Customer: Record Customer; PostingDate: Date)
    var
        FinanceChargeMemoPage: TestPage "Finance Charge Memo";
    begin
        LibraryERM.CreateFinanceChargeMemoHeader(FinanceChargeMemoHeader, Customer."No.");
        FinanceChargeMemoHeader.Validate("Posting Date", PostingDate);
        FinanceChargeMemoHeader.Validate("Document Date", PostingDate);
        FinanceChargeMemoHeader.Modify(true);

        Commit();

        FinanceChargeMemoPage.OpenEdit();
        FinanceChargeMemoPage.FILTER.SetFilter("No.", FinanceChargeMemoHeader."No.");
        FinanceChargeMemoPage.SuggestFinChargeMemoLines.Invoke();
        FinanceChargeMemoPage.Close();
    end;

    local procedure GetFinanceChargeMinAmount(CustomerNo: Code[20]): Decimal
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        FinanceChargeTerms.Get(Customer."Fin. Charge Terms Code");
        exit(FinanceChargeTerms."Minimum Amount (LCY)");
    end;

    local procedure FindIssuedFinanceChargeMemo(var IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header"; FinanceChargeMemoHeader: Record "Finance Charge Memo Header")
    begin
        IssuedFinChargeMemoHeader.SetRange("Customer No.", FinanceChargeMemoHeader."Customer No.");
        IssuedFinChargeMemoHeader.SetRange("Pre-Assigned No.", FinanceChargeMemoHeader."No.");
        IssuedFinChargeMemoHeader.FindFirst();
    end;

    local procedure IssueFinanceChargeMemo(DocumentNo: Code[20]): Code[20]
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
    begin
        FinanceChargeMemoLine.SetRange("Document Type", FinanceChargeMemoLine."Document Type"::Invoice);
        FinanceChargeMemoLine.SetRange("Document No.", DocumentNo);
        FinanceChargeMemoLine.FindFirst();
        FinanceChargeMemoHeader.Get(FinanceChargeMemoLine."Finance Charge Memo No.");
        LibraryERM.IssueFinanceChargeMemo(FinanceChargeMemoHeader);
        exit(FinanceChargeMemoHeader."No.");
    end;

    local procedure CalculateTotalAmount(OrderNo: Code[20]) TotalAmount: Decimal
    var
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        FinanceChargeTerms: Record "Finance Charge Terms";
    begin
        SalesInvoiceHeader.Get(OrderNo);
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");
        FinanceChargeTerms.Get(Customer."Fin. Charge Terms Code");
        SalesInvoiceHeader.CalcFields(Amount);
        TotalAmount :=
          (SalesInvoiceHeader.Amount * FinanceChargeTerms."Interest Rate") / 100 + FinanceChargeTerms."Minimum Amount (LCY)" +
          SalesInvoiceHeader.Amount;
        exit(TotalAmount);
    end;

    local procedure UnapplyCustLedgerEntry(CustomerNo: Code[20]; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindLast();
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);
    end;

    local procedure VerifyFinChargeMemoRoundingLineExists(FinanceChargeMemoHeaderNo: Code[20]; InvoiceRoundingAccountNo: Code[20])
    var
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
    begin
        FinanceChargeMemoLine.SetRange("Finance Charge Memo No.", FinanceChargeMemoHeaderNo);
        FinanceChargeMemoLine.SetRange(Type, FinanceChargeMemoLine.Type::"G/L Account");
        FinanceChargeMemoLine.SetRange("No.", InvoiceRoundingAccountNo);
        FinanceChargeMemoLine.FindFirst();
        FinanceChargeMemoLine.TestField(Amount);
    end;

    local procedure VerifyUnappliedDtldLedgEntry(CustomerNo: Code[20]; DocumentNo: Code[20])
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedCustLedgEntry.SetRange("Customer No.", CustomerNo);
        DetailedCustLedgEntry.FindSet();
        repeat
            Assert.IsTrue(DetailedCustLedgEntry.Unapplied, StrSubstNo(UnappliedError, DetailedCustLedgEntry.TableCaption(),
                DetailedCustLedgEntry.Unapplied));
        until DetailedCustLedgEntry.Next() = 0;
    end;

    local procedure VerifyCustLedgerEntryForRemAmt(GenJournalLine: Record "Gen. Journal Line")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        CustLedgerEntry.SetRange("Document Type", GenJournalLine."Document Type");
        CustLedgerEntry.SetRange("Document No.", GenJournalLine."Document No.");
        CustLedgerEntry.SetRange("Customer No.", GenJournalLine."Account No.");
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields("Remaining Amount");
        Assert.AreNearlyEqual(GenJournalLine.Amount, CustLedgerEntry."Remaining Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(RemainingAmountError, CustLedgerEntry."Remaining Amount", GenJournalLine.Amount));
    end;

    local procedure VerifyGLAccountOnGLEntryIssuedFinanceChargeMemo(IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header"; AccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::"Finance Charge Memo");
        GLEntry.SetRange("Document No.", IssuedFinChargeMemoHeader."No.");
        GLEntry.SetRange("G/L Account No.", AccountNo);
        Assert.RecordIsNotEmpty(GLEntry);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestFinChargeMemoLinesRequestPageHandler(var SuggestFinChargeMemoLines: TestRequestPage "Suggest Fin. Charge Memo Lines")
    begin
        SuggestFinChargeMemoLines.OK().Invoke();
    end;
}

