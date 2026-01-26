codeunit 144024 "Test Financial Journals"
{
    // Automation of manual tests related to page 11300 'Financial Journals'. The vendor part cannot be automated due to hidden fields.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        PmtTerms: Record "Payment Terms";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        isInitialized: Boolean;
        BankAccountNo: Code[20];
        NoSeriesFullfilledSalesCrMemoErr: Label 'You cannot cancel this posted sales invoice because no unused posted credit memo numbers are available';
        NoSeriesFullfilledPurchaseCrMemoErr: Label 'You cannot cancel this posted purchase invoice because no unused posted credit memo numbers are available';
        NoSeriesFullfilledSalesInvoiceErr: Label 'You cannot cancel this posted sales credit memo because no unused posted invoice numbers are available';
        NoSeriesFullfilledPurchaseInvoiceErr: Label 'You cannot cancel this posted purchase credit memo because no unused posted invoice numbers are available';
        AccountNoMustNotBlankErr: Label 'Account No. must have a value in Gen. Journal Line';
        JournalMustNotPostErr: Label 'Financial Journal Lines should not post.';

    [Test]
    [HandlerFunctions('GeneralJournalTemplateListModalPageHandler,ApplyCustomerEntriesModalPageHandler,GeneralLedgerEntriesPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostCustomerLedgerEntries()
    var
        FinancialJournalPage: TestPage "Financial Journal";
        GLRegisters: TestPage "G/L Registers";
        BalanceLastStatement: Decimal;
        DocumentNo: Code[20];
        DocumentType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund;
        AccountType: Option "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset","IC Partner";
    begin
        // FINJNL - Validate Customer Ledger Entries
        // http://vstfnav:8080/tfs/web/wi.aspx?pcguid=9a2ffec1-5411-458b-b788-8c4a5507644c&id=60224
        Initialize();

        SetupFinancialJournalPage(
          FinancialJournalPage, BalanceLastStatement, DocumentType::Payment, 'T6001', AccountType::Customer, '10000', 0);

        DocumentNo := FinancialJournalPage."Document No.".Value();
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(DocumentNo);

        FinancialJournalPage."Apply Entries".Invoke();

        // Try to post
        FinancialJournalPage."P&ost".Invoke();
        FinancialJournalPage.Close();

        // Verify
        GLRegisters.OpenView();
        GLRegisters.First();
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(DocumentNo);
        LibraryVariableStorage.Enqueue(BalanceLastStatement);

        GLRegisters."General Ledger".Invoke();
        GLRegisters.Close();
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTemplateListModalPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostGLAccountLedgerEntries()
    var
        FinancialJournalPage: TestPage "Financial Journal";
        BalanceLastStatement: Decimal;
        DocumentType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund;
        AccountType: Option "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset","IC Partner";
    begin
        // FINJNL - Validate the Posting of Financial Journal Lines
        // http://vstfnav:8080/tfs/web/wi.aspx?pcguid=9a2ffec1-5411-458b-b788-8c4a5507644c&id=60218
        Initialize();

        SetupFinancialJournalPage(
          FinancialJournalPage, BalanceLastStatement, DocumentType::" ", 'T7001', AccountType::"G/L Account", '57000', 100000);

        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(FinancialJournalPage."Document No.".Value);

        // Try to post
        FinancialJournalPage."P&ost".Invoke();

        FinancialJournalPage.Close();
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ValidateBankReconciliationForm()
    var
        GLAccount: Record "G/L Account";
        FinancialJournalPage: TestPage "Financial Journal";
        Reconciliation: TestPage Reconciliation;
        BalanceLastStatement: Decimal;
        BalanceAtDate: Decimal;
        EndingBalance: Decimal;
        DocumentType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund;
        AccountType: Option "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset","IC Partner";
    begin
        // FINJNL - Validate the Bank Reconciliation form
        // http://vstfnav:8080/tfs/web/wi.aspx?pcguid=9a2ffec1-5411-458b-b788-8c4a5507644c&id=60226
        Initialize();

        EndingBalance := 100000;
        SetupFinancialJournalPage(
          FinancialJournalPage, BalanceLastStatement, DocumentType::Payment, 'T6001', AccountType::Customer, '10000', EndingBalance);

        GLAccount.Get('550005');
        GLAccount.CalcFields("Balance at Date");
        BalanceAtDate := GLAccount."Balance at Date";

        // Try to recon
        // Reconciliation (345)
        Reconciliation.Trap();
        FinancialJournalPage.Reconcile.Invoke();

        Reconciliation.FILTER.SetFilter("No.", '550005');
        Assert.AreEqual(BalanceAtDate - BalanceLastStatement + EndingBalance,
          Reconciliation."Balance after Posting".AsDecimal(), 'Balance after post');

        Reconciliation.OK().Invoke();

        FinancialJournalPage.Close();
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ValidateCorrectBalanceAccountType()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FinancialJournalPage: TestPage "Financial Journal";
    begin
        // FINJNL - Verify Bal. Account Type in Financial Journal
        // http://vstfnav:8080/tfs/web/wi.aspx?pcguid=9a2ffec1-5411-458b-b788-8c4a5507644c&id=60219
        Initialize();

        FinancialJournalPage.OpenEdit();
        FinancialJournalPage.StatementEndingBalance.SetValue(100000);
        FinancialJournalPage."Document No.".SetValue('T7001');
        FinancialJournalPage."Account Type".SetValue(GenJournalLine."Account Type"::"G/L Account");
        FinancialJournalPage."Account No.".SetValue(57000);
        FinancialJournalPage.Amount.SetValue(100000);
        asserterror FinancialJournalPage."Bal. Account Type".SetValue('Vendor');

        FinancialJournalPage.Close();
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ValidatePostingErrorOnMissingDocumentNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FinancialJournalPage: TestPage "Financial Journal";
    begin
        // FINJNL - Validate Posting of Invoice from Financial Journal, When "Document No."  Field is Empty
        // http://vstfnav:8080/tfs/web/wi.aspx?pcguid=9a2ffec1-5411-458b-b788-8c4a5507644c&id=60220

        Initialize();

        FinancialJournalPage.OpenEdit();
        FinancialJournalPage.StatementEndingBalance.SetValue(100000);
        FinancialJournalPage."Document No.".SetValue(' ');
        FinancialJournalPage."Account Type".SetValue(GenJournalLine."Account Type"::"G/L Account");
        FinancialJournalPage."Account No.".SetValue(57000);
        FinancialJournalPage.Amount.SetValue(100000);
        FinancialJournalPage."Bal. Account Type".SetValue(GenJournalLine."Bal. Account Type"::"Bank Account");

        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(FinancialJournalPage."Document No.".Value);

        // Try to post
        asserterror FinancialJournalPage."P&ost".Invoke();

        FinancialJournalPage.Close();
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ValidatePostingErrorOnInvalidAmount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FinancialJournalPage: TestPage "Financial Journal";
    begin
        // FINJNL - Validate Financial Journal, When "Total Balance" Field’s Value is not Equal to "Statement Ending Balance"
        // Field’s Value
        // http://vstfnav:8080/tfs/web/wi.aspx?pcguid=9a2ffec1-5411-458b-b788-8c4a5507644c&id=60217
        Initialize();

        FinancialJournalPage.OpenEdit();
        FinancialJournalPage.StatementEndingBalance.SetValue(100000);
        FinancialJournalPage."Document No.".SetValue('T001');
        FinancialJournalPage."Account Type".SetValue(GenJournalLine."Account Type"::"G/L Account");
        FinancialJournalPage."Account No.".SetValue(57000);
        FinancialJournalPage.Amount.SetValue(-900000);
        FinancialJournalPage."Bal. Account Type".SetValue(GenJournalLine."Bal. Account Type"::"Bank Account");

        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(FinancialJournalPage."Document No.".Value);

        // Try to post
        asserterror FinancialJournalPage."P&ost".Invoke();

        FinancialJournalPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanCancelCorrectiveSalesCreditMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        CancelPostedSalesCrMemo: Codeunit "Cancel Posted Sales Cr. Memo";
    begin
        // [FEATURE] [Cancel] [Correct] [Invoice] [Credit Memo] [No. Series] [Gen. Journal Template] [Sales]
        // [SCENARIO 398925] System checks "No. Series" in gen. journal template that is specified in sales setup when Stan corrects posted invoice or cancels posted credit memo.
        Initialize();

        UpdateNoSeriesInSalesSetup(
          CreateNoSeriesCodeWithFullfilledNos(), CreateNoSeriesCodeWithFullfilledNos(),
          CreateNoSeriesCode(), CreateNoSeriesCode());

        LibrarySales.CreateSalesInvoice(SalesHeader);

        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, true);
        CorrectPostedSalesInvoice.Run(SalesInvoiceHeader);

        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields(Cancelled);
        SalesInvoiceHeader.TestField(Cancelled);

        SalesCrMemoHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesCrMemoHeader.FindFirst();

        SalesCrMemoHeader.CalcFields(Cancelled, Corrective);
        SalesCrMemoHeader.TestField(Cancelled, false);
        SalesCrMemoHeader.TestField(Corrective);

        CancelPostedSalesCrMemo.TestCorrectCrMemoIsAllowed(SalesCrMemoHeader);
        CancelPostedSalesCrMemo.Run(SalesCrMemoHeader);

        SalesCrMemoHeader.Find();
        SalesCrMemoHeader.CalcFields(Cancelled, Corrective);
        SalesCrMemoHeader.TestField(Cancelled);
        SalesCrMemoHeader.TestField(Corrective, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanCancelCorrectivePurchaseCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        CancelPostedPurchCrMemo: Codeunit "Cancel Posted Purch. Cr. Memo";
    begin
        // [FEATURE] [Cancel] [Correct] [Invoice] [Credit Memo] [No. Series] [Gen. Journal Template] [Purchase]
        // [SCENARIO 398925] System checks "No. Series" in gen. journal template that is specified in purchase setup when Stan corrects posted invoice or cancels posted credit memo.
        Initialize();

        UpdateNoSeriesInPurchaseSetup(
          CreateNoSeriesCodeWithFullfilledNos(), CreateNoSeriesCodeWithFullfilledNos(),
          CreateNoSeriesCode(), CreateNoSeriesCode());

        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);

        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, true);
        CorrectPostedPurchInvoice.Run(PurchInvHeader);

        PurchInvHeader.Find();
        PurchInvHeader.CalcFields(Cancelled);
        PurchInvHeader.TestField(Cancelled);

        PurchCrMemoHdr.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchCrMemoHdr.FindFirst();

        PurchCrMemoHdr.CalcFields(Cancelled, Corrective);
        PurchCrMemoHdr.TestField(Cancelled, false);
        PurchCrMemoHdr.TestField(Corrective);

        CancelPostedPurchCrMemo.TestCorrectCrMemoIsAllowed(PurchCrMemoHdr);
        CancelPostedPurchCrMemo.Run(PurchCrMemoHdr);

        PurchCrMemoHdr.Find();
        PurchCrMemoHdr.CalcFields(Cancelled, Corrective);
        PurchCrMemoHdr.TestField(Cancelled);
        PurchCrMemoHdr.TestField(Corrective, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCorrectPostedSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Cancel] [Correct] [Invoice] [Credit Memo] [No. Series] [Gen. Journal Template] [Sales]
        // [SCENARIO 398925] System throws error on checking fullfilled "No. Series" in gen. journal template that is specified in sales setup when Stan corrects posted invoice1000
        Initialize();

        UpdateNoSeriesInSalesSetup(
          CreateNoSeriesCode(), CreateNoSeriesCode(),
          CreateNoSeriesCode(), CreateNoSeriesCodeWithFullfilledNos());

        LibrarySales.CreateSalesInvoice(SalesHeader);

        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        asserterror CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, true);

        Assert.ExpectedError(NoSeriesFullfilledSalesCrMemoErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCorrectPostedPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [FEATURE] [Cancel] [Correct] [Invoice] [Credit Memo] [No. Series] [Gen. Journal Template] [Purchase]
        // [SCENARIO 398925] System throws error on checking fullfilled "No. Series" in gen. journal template that is specified in sales setup when Stan corrects posted invoice
        Initialize();

        UpdateNoSeriesInPurchaseSetup(
          CreateNoSeriesCode(), CreateNoSeriesCode(),
          CreateNoSeriesCode(), CreateNoSeriesCodeWithFullfilledNos());

        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);

        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        asserterror CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, true);

        Assert.ExpectedError(NoSeriesFullfilledPurchaseCrMemoErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCancelCorrectiveSalesCreditMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        CancelPostedSalesCrMemo: Codeunit "Cancel Posted Sales Cr. Memo";
    begin
        // [FEATURE] [Cancel] [Correct] [Invoice] [Credit Memo] [No. Series] [Gen. Journal Template] [Sales]
        // [SCENARIO 398925] System checks "No. Series" in gen. journal template that is specified in sales setup when Stan cancels posted credit memo.
        Initialize();

        UpdateNoSeriesInSalesSetup(
          CreateNoSeriesCode(), CreateNoSeriesCode(),
          CreateNoSeriesCode(), CreateNoSeriesCode());

        LibrarySales.CreateSalesInvoice(SalesHeader);

        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, true);
        CorrectPostedSalesInvoice.Run(SalesInvoiceHeader);

        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields(Cancelled);
        SalesInvoiceHeader.TestField(Cancelled);

        SalesCrMemoHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesCrMemoHeader.FindFirst();

        SalesCrMemoHeader.CalcFields(Cancelled, Corrective);
        SalesCrMemoHeader.TestField(Cancelled, false);
        SalesCrMemoHeader.TestField(Corrective);

        UpdateNoSeriesInSalesSetup(
          CreateNoSeriesCode(), CreateNoSeriesCode(),
          CreateNoSeriesCodeWithFullfilledNos(), CreateNoSeriesCode());

        Commit();

        asserterror CancelPostedSalesCrMemo.TestCorrectCrMemoIsAllowed(SalesCrMemoHeader);

        Assert.ExpectedError(NoSeriesFullfilledSalesInvoiceErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCancelCorrectivePurchaseCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        CancelPostedPurchCrMemo: Codeunit "Cancel Posted Purch. Cr. Memo";
    begin
        // [FEATURE] [Cancel] [Correct] [Invoice] [Credit Memo] [No. Series] [Gen. Journal Template] [Purchase]
        // [SCENARIO 398925] System checks "No. Series" in gen. journal template that is specified in purchase setup when Stan cancels posted credit memo.
        Initialize();

        UpdateNoSeriesInPurchaseSetup(
          CreateNoSeriesCode(), CreateNoSeriesCode(),
          CreateNoSeriesCode(), CreateNoSeriesCode());

        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);

        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, true);
        CorrectPostedPurchInvoice.Run(PurchInvHeader);

        PurchInvHeader.Find();
        PurchInvHeader.CalcFields(Cancelled);
        PurchInvHeader.TestField(Cancelled);

        PurchCrMemoHdr.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchCrMemoHdr.FindFirst();

        PurchCrMemoHdr.CalcFields(Cancelled, Corrective);
        PurchCrMemoHdr.TestField(Cancelled, false);
        PurchCrMemoHdr.TestField(Corrective);

        UpdateNoSeriesInPurchaseSetup(
          CreateNoSeriesCode(), CreateNoSeriesCode(),
          CreateNoSeriesCodeWithFullfilledNos(), CreateNoSeriesCode());

        Commit();

        asserterror CancelPostedPurchCrMemo.TestCorrectCrMemoIsAllowed(PurchCrMemoHdr);

        Assert.ExpectedError(NoSeriesFullfilledPurchaseInvoiceErr);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('GeneralJournalTemplateListModalPageHandler')]
    procedure CalculateBalanceTotalDifferenceOnFinancialJournalWithGenJournalTemplateNameMandatory()
    var
        FinancialJournalPage: TestPage "Financial Journal";
        GenJournalLine: Record "Gen. Journal Line";
        JournalTemplateName: Code[10];
        JournalBatchName: Code[10];
        DocumentNo: Code[20];
        GLAccountNo: Code[20];
        Amounts: array[3] of Decimal;
    begin
        // [SCENARIO 440765] System calculates Balance, Difference and Total Balance on Finanical Journal lines when "Journal Template Name Mandatory" = true on G/L Setup.
        Initialize();

        SetGenJournalTemplateNameMandatoryOnGLSetup(true);

        GLAccountNo := LibraryERM.CreateGLAccountNoWithDirectPosting();
        DocumentNo := LibraryUtility.GenerateGUID();
        Amounts[1] := -1900;
        Amounts[2] := 300;
        Amounts[3] := -1190;

        JournalTemplateName := LibraryVariableStorage.DequeueText();

        LibraryVariableStorage.Enqueue(JournalTemplateName);
        FinancialJournalPage.OpenEdit();
        JournalBatchName := Format(FinancialJournalPage.CurrentJnlBatchName.Value);
        FinancialJournalPage.Close();

        GenJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        GenJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        GenJournalLine.DeleteAll();

        SetupFinancialJournalLineOnPage(
            GenJournalLine, GenJournalLine."Document Type"::" ", DocumentNo,
            GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
            GenJournalLine."Bal. Account Type"::"Bank Account", BankAccountNo);

        SetupFinancialJournalLineOnPage(
            GenJournalLine, GenJournalLine."Document Type"::" ", DocumentNo,
            GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
            GenJournalLine."Bal. Account Type"::"Bank Account", BankAccountNo);

        SetupFinancialJournalLineOnPage(
            GenJournalLine, GenJournalLine."Document Type"::" ", DocumentNo,
            GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
            GenJournalLine."Bal. Account Type"::"Bank Account", BankAccountNo);

        LibraryVariableStorage.Enqueue(JournalTemplateName);
        FinancialJournalPage.OpenEdit();
        FinancialJournalPage.BalanceLastStatement.SetValue(0);
        FinancialJournalPage.StatementEndingBalance.SetValue(3000);

        FinancialJournalPage.Amount.SetValue(Amounts[1]);
        VerifyBalanceAmountsOnFinancialJournalPage(FinancialJournalPage, 1100, 1900, 1900);

        FinancialJournalPage.Next();

        FinancialJournalPage.Amount.SetValue(Amounts[2]);
        VerifyBalanceAmountsOnFinancialJournalPage(FinancialJournalPage, 1400, 1600, 1600);

        FinancialJournalPage.Next();

        FinancialJournalPage.Amount.SetValue(Amounts[3]);
        VerifyBalanceAmountsOnFinancialJournalPage(FinancialJournalPage, 210, 2790, 2790);

        FinancialJournalPage.Previous();
        VerifyBalanceAmountsOnFinancialJournalPage(FinancialJournalPage, 210, 1600, 2790);

        FinancialJournalPage.Previous();
        VerifyBalanceAmountsOnFinancialJournalPage(FinancialJournalPage, 210, 1900, 2790);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('GeneralJournalTemplateListModalPageHandler')]
    procedure CalculateBalanceTotalDifferenceOnFinancialJournalWithoutGenJournalTemplateNameMandatory()
    var
        FinancialJournalPage: TestPage "Financial Journal";
        GenJournalLine: Record "Gen. Journal Line";
        JournalTemplateName: Code[10];
        JournalBatchName: Code[10];
        DocumentNo: Code[20];
        GLAccountNo: Code[20];
        Amounts: array[3] of Decimal;
    begin
        // [SCENARIO 440765] System calculates Balance, Difference and Total Balance on Finanical Journal lines when "Journal Template Name Mandatory" = FALSE on G/L Setup.
        Initialize();

        SetGenJournalTemplateNameMandatoryOnGLSetup(false);

        GLAccountNo := LibraryERM.CreateGLAccountNoWithDirectPosting();
        DocumentNo := LibraryUtility.GenerateGUID();
        Amounts[1] := -1900;
        Amounts[2] := 300;
        Amounts[3] := -1190;

        JournalTemplateName := LibraryVariableStorage.DequeueText();

        LibraryVariableStorage.Enqueue(JournalTemplateName);
        FinancialJournalPage.OpenEdit();
        JournalBatchName := Format(FinancialJournalPage.CurrentJnlBatchName.Value);
        FinancialJournalPage.Close();

        GenJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        GenJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        GenJournalLine.DeleteAll();

        SetupFinancialJournalLineOnPage(
            GenJournalLine, GenJournalLine."Document Type"::" ", DocumentNo,
            GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
            GenJournalLine."Bal. Account Type"::"G/L Account", GLAccountNo);

        SetupFinancialJournalLineOnPage(
            GenJournalLine, GenJournalLine."Document Type"::" ", DocumentNo,
            GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
            GenJournalLine."Bal. Account Type"::"G/L Account", GLAccountNo);

        SetupFinancialJournalLineOnPage(
            GenJournalLine, GenJournalLine."Document Type"::" ", DocumentNo,
            GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
            GenJournalLine."Bal. Account Type"::"G/L Account", GLAccountNo);

        LibraryVariableStorage.Enqueue(JournalTemplateName);
        FinancialJournalPage.OpenEdit();
        FinancialJournalPage.BalanceLastStatement.SetValue(0);
        FinancialJournalPage.StatementEndingBalance.SetValue(3000);

        FinancialJournalPage.Amount.SetValue(Amounts[1]);
        VerifyBalanceAmountsOnFinancialJournalPage(FinancialJournalPage, 1100, 1900, 1900);

        FinancialJournalPage.Next();

        FinancialJournalPage.Amount.SetValue(Amounts[2]);
        VerifyBalanceAmountsOnFinancialJournalPage(FinancialJournalPage, 1400, 1600, 1600);

        FinancialJournalPage.Next();

        FinancialJournalPage.Amount.SetValue(Amounts[3]);
        VerifyBalanceAmountsOnFinancialJournalPage(FinancialJournalPage, 210, 2790, 2790);

        FinancialJournalPage.Previous();
        VerifyBalanceAmountsOnFinancialJournalPage(FinancialJournalPage, 210, 1600, 2790);

        FinancialJournalPage.Previous();
        VerifyBalanceAmountsOnFinancialJournalPage(FinancialJournalPage, 210, 1900, 2790);
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTemplateListModalPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostFinancialJournalWithoutAccountNo()
    var
        FinancialJournalPage: TestPage "Financial Journal";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        JournalTemplateName: Code[10];
        JournalBatchName: Code[10];
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        // [SCENARIO 470385] BE local - On attempting to post a Financial Journal where a G/L Account is missing an inconssistency error message is shown instead of a TESTFIELD
        Initialize();
        SetGenJournalTemplateNameMandatoryOnGLSetup(true);

        // [GIVEN] Create a Document Number and Random Amount for Financial Journal Line
        DocumentNo := LibraryUtility.GenerateGUID();
        Amount := LibraryRandom.RandDecInDecimalRange(100, 200, 2);

        // [THEN] Get the Gen. Journal Template detail
        JournalTemplateName := LibraryVariableStorage.DequeueText();
        LibraryVariableStorage.Enqueue(JournalTemplateName);
        GenJournalTemplate.Get(JournalTemplateName);

        // [THEN] Open Financial Journal Page and delete all Financial Journal Lines based on Journal Template and Batch
        FinancialJournalPage.OpenEdit();
        JournalBatchName := Format(FinancialJournalPage.CurrentJnlBatchName.Value);
        FinancialJournalPage.Close();
        GenJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        GenJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        GenJournalLine.DeleteAll();

        // [GIVEN] Create a Financial Journal Line
        SetupFinancialJournalLineOnPage(
            GenJournalLine, GenJournalLine."Document Type"::" ", DocumentNo,
            GenJournalLine."Account Type"::Customer, '',
            GenJournalLine."Bal. Account Type"::"Bank Account", GenJournalTemplate."Bal. Account No.");
        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine.Validate(Amount, Amount);
        GenJournalLine.Modify(true);

        // [THEN] Open Financial Journal Page, set Balance Last Statement to 0, and negative amount in Statement Ending Balance
        LibraryVariableStorage.Enqueue(JournalTemplateName);
        FinancialJournalPage.OpenEdit();
        FinancialJournalPage.BalanceLastStatement.SetValue(0);
        FinancialJournalPage.StatementEndingBalance.SetValue(-Amount);

        // [VERIFY] Verify Error should occur during post when Account No. is blank
        asserterror FinancialJournalPage."P&ost".Invoke();
        Assert.IsTrue(StrPos(GetLastErrorText, Format(AccountNoMustNotBlankErr)) <> 0, JournalMustNotPostErr);
        FinancialJournalPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('GeneralJournalTemplateListModalPageHandler,ConfirmHandler')]
    procedure PostMultipleFinancialJournalLinesWhenAccountNoIsBlankForAnyJournalLine()
    var
        FinancialJournalPage: TestPage "Financial Journal";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        JournalTemplateName: Code[10];
        JournalBatchName: Code[10];
        DocumentNo: Code[20];
        Amounts: array[2] of Decimal;
    begin
        // [SCENARIO 470385] BE local - On attempting to post a Financial Journal where a G/L Account is missing an inconssistency error message is shown instead of a TESTFIELD
        Initialize();
        SetGenJournalTemplateNameMandatoryOnGLSetup(true);

        // [GIVEN] Create a Document Number and Random Amount values for 2 different Financial Journal Lines
        DocumentNo := LibraryUtility.GenerateGUID();
        Amounts[1] := LibraryRandom.RandDecInDecimalRange(100, 200, 2);
        Amounts[2] := LibraryRandom.RandDecInDecimalRange(100, 200, 2);

        // [THEN] Get the Gen. Journal Template detail
        JournalTemplateName := LibraryVariableStorage.DequeueText();
        LibraryVariableStorage.Enqueue(JournalTemplateName);
        GenJournalTemplate.Get(JournalTemplateName);

        // [THEN] Open Financial Journal Page and delete all Financial Journal Line based on Journal Template and Batch
        FinancialJournalPage.OpenEdit();
        JournalBatchName := Format(FinancialJournalPage.CurrentJnlBatchName.Value);
        FinancialJournalPage.Close();
        GenJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        GenJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        GenJournalLine.DeleteAll();

        // [GIVEN] Create 1st Financial Journal Line
        SetupFinancialJournalLineOnPage(
            GenJournalLine, GenJournalLine."Document Type"::" ", DocumentNo,
            GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
            GenJournalLine."Bal. Account Type"::"Bank Account", GenJournalTemplate."Bal. Account No.");
        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine.Validate(Amount, Amounts[1]);
        GenJournalLine.Modify(true);

        // [GIVEN] Create 2nd Financial Journal Line
        SetupFinancialJournalLineOnPage(
            GenJournalLine, GenJournalLine."Document Type"::" ", DocumentNo,
            GenJournalLine."Account Type"::Customer, '',
            GenJournalLine."Bal. Account Type"::"Bank Account", GenJournalTemplate."Bal. Account No.");
        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine.Validate(Amount, Amounts[2]);
        GenJournalLine.Modify(true);

        // [THEN] Open Financial Journal Page, set Balance Last Statement to 0, and summed amount of Journal Lines in Statement Ending Balance
        LibraryVariableStorage.Enqueue(JournalTemplateName);
        FinancialJournalPage.OpenEdit();
        FinancialJournalPage.BalanceLastStatement.SetValue(0);
        FinancialJournalPage.StatementEndingBalance.SetValue(-(Amounts[1] + Amounts[2]));

        // [VERIFY] Verify Error should occur during post multiple journal lines when Account No. is blank for any line
        asserterror FinancialJournalPage."P&ost".Invoke();
        Assert.IsTrue(StrPos(GetLastErrorText, Format(AccountNoMustNotBlankErr)) <> 0, JournalMustNotPostErr);
        FinancialJournalPage.Close();
    end;

    local procedure Initialize()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        BankAccount: Record "Bank Account";
    begin
        // Generate random seed.
        BankAccount.SetFilter("Last Check No.", '<>%1', '');
        BankAccount.FindFirst();
        GenJournalTemplate.SetRange("Bal. Account No.", BankAccount."No.");
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Financial);
        GenJournalTemplate.FindFirst();
        BankAccountNo := GenJournalTemplate."Bal. Account No.";
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(GenJournalTemplate.Name);

        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;

        // Setup default fixture

        // Create new payment terms with random discount due date and discount percentage.
        // The due date must be after the discount due date.
        ReplacePaymentTerms(
          PmtTerms, 'NEW', '<1M>', '<' + Format(LibraryRandom.RandInt(20)) + 'D>', LibraryRandom.RandInt(200) / 10);
        ModifyGenJnlBatchNoSeries();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateAccountInVendorPostingGroups();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();

        LibrarySetupStorage.SaveSalesSetup();
        LibrarySetupStorage.SavePurchasesSetup();
        LibrarySetupStorage.SaveGeneralLedgerSetup();

        isInitialized := true;
        Commit();
    end;

    local procedure CreateNoSeriesCode(): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        Prefix: Code[10];
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);

        Prefix := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(Prefix));

        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, StrSubstNo('%1-0000', Prefix), StrSubstNo('%1-9999', Prefix));

        exit(NoSeriesLine."Series Code");
    end;

    local procedure CreateNoSeriesCodeWithFullfilledNos(): Code[20]
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine.SetRange("Series Code", CreateNoSeriesCode());
        NoSeriesLine.FindFirst();

        NoSeriesLine.Validate("Last No. Used", NoSeriesLine."Ending No.");
        NoSeriesLine.Modify(true);

        exit(NoSeriesLine."Series Code");
    end;

    local procedure CreateGenJournalTemplateWithPostingSeriesNo(TemplateType: Enum "Gen. Journal Template Type"; PostingNoSeries: Code[20]): Code[10]
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, TemplateType);
        GenJournalTemplate.Validate("Posting No. Series", PostingNoSeries);
        GenJournalTemplate.Modify(true);

        exit(GenJournalTemplate.Name);
    end;

    local procedure UpdateNoSeriesInSalesSetup(StdPostedInvoiceNoSeriesCode: Code[20]; StdPostedCrMemoNoSeriesCode: Code[20]; TemplatePostedInvoiceNoSeriesCode: Code[20]; TemplatePostedCrMemoNoSeriesCode: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Posted Invoice Nos.", StdPostedInvoiceNoSeriesCode);
        SalesReceivablesSetup.Validate("Posted Credit Memo Nos.", StdPostedCrMemoNoSeriesCode);
        SalesReceivablesSetup.Validate(
          "S. Invoice Template Name",
          CreateGenJournalTemplateWithPostingSeriesNo(GenJournalTemplate.Type::Sales, TemplatePostedInvoiceNoSeriesCode));
        SalesReceivablesSetup.Validate(
          "S. Cr. Memo Template Name",
          CreateGenJournalTemplateWithPostingSeriesNo(GenJournalTemplate.Type::Sales, TemplatePostedCrMemoNoSeriesCode));
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateNoSeriesInPurchaseSetup(StdPostedInvoiceNoSeriesCode: Code[20]; StdPostedCrMemoNoSeriesCode: Code[20]; TemplatePostedInvoiceNoSeriesCode: Code[20]; TemplatePostedCrMemoNoSeriesCode: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Posted Invoice Nos.", StdPostedInvoiceNoSeriesCode);
        PurchasesPayablesSetup.Validate("Posted Credit Memo Nos.", StdPostedCrMemoNoSeriesCode);
        PurchasesPayablesSetup.Validate(
          "P. Invoice Template Name",
          CreateGenJournalTemplateWithPostingSeriesNo(GenJournalTemplate.Type::Purchases, TemplatePostedInvoiceNoSeriesCode));
        PurchasesPayablesSetup.Validate(
          "P. Cr. Memo Template Name",
          CreateGenJournalTemplateWithPostingSeriesNo(GenJournalTemplate.Type::Purchases, TemplatePostedCrMemoNoSeriesCode));
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure ReplacePaymentTerms(var PmtTerms: Record "Payment Terms"; "Code": Code[10]; DueDateCalc: Text[30]; DiscountDateCalc: Text[30]; Discount: Decimal)
    begin
        // Creates or updates payment terms with given code.
        if not PmtTerms.Get(Code) then begin
            PmtTerms.Init();
            PmtTerms.Code := Code;
            PmtTerms.Insert(true);
        end;

        Evaluate(PmtTerms."Due Date Calculation", DueDateCalc);
        Evaluate(PmtTerms."Discount Date Calculation", DiscountDateCalc);
        PmtTerms.Validate("Discount %", Discount);
        PmtTerms.Modify(true);
    end;

    local procedure ModifyGenJnlBatchNoSeries()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJnlBatch);
        GenJnlBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        GenJnlBatch.Modify(true);
    end;

    local procedure SetGenJournalTemplateNameMandatoryOnGLSetup(NewValue: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Journal Templ. Name Mandatory", NewValue);
        GeneralLedgerSetup.Modify(true);
    end;

    [Normal]
    local procedure SetupFinancialJournalPage(var FinancialJournalPage: TestPage "Financial Journal"; var BalanceLastStatement: Decimal; DocumentType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund; DocumentNo: Code[20]; AccountType: Option "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset","IC Partner"; AccountNo: Code[20]; EndingBalance: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        FinancialJournalPage.OpenEdit();
        BalanceLastStatement := FinancialJournalPage.BalanceLastStatement.AsDecimal();
        FinancialJournalPage.StatementEndingBalance.SetValue(EndingBalance);
        FinancialJournalPage."Document Type".SetValue(DocumentType);
        FinancialJournalPage."Document No.".SetValue(DocumentNo);
        FinancialJournalPage."Account Type".SetValue(AccountType);
        FinancialJournalPage."Account No.".SetValue(AccountNo);
        FinancialJournalPage.Amount.SetValue(BalanceLastStatement - EndingBalance);
        FinancialJournalPage."Bal. Account Type".SetValue(GenJournalLine."Bal. Account Type"::"Bank Account");
        FinancialJournalPage."Bal. Account No.".SetValue(BankAccountNo);

        FinancialJournalPage.Next();
        FinancialJournalPage.Previous();
    end;

    local procedure SetupFinancialJournalLineOnPage(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: enum "Gen. Journal Document Type"; DocumentNo: Code[20]; AccountType: enum "Gen. Journal Account Type"; AccountNo: Code[20]; BalAccountType: enum "Gen. Journal Account Type"; BalAccountNo: Code[20])
    begin
        if GenJournalLine.FindLast() then;
        GenJournalLine.Validate("Journal Template Name", GenJournalLine.GetFilter("Journal Template Name"));
        GenJournalLine.Validate("Journal Batch Name", GenJournalLine.GetFilter("Journal Batch Name"));
        GenJournalLine.Validate("Line No.", GenJournalLine."Line No." + 10000);
        GenJournalLine.Validate("Document Type", DocumentType);
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Validate("Account Type", AccountType);
        GenJournalLine.Validate("Account No.", AccountNo);
        GenJournalLine.Validate(Amount, 0);
        GenJournalLine.Validate("Bal. Account Type", BalAccountType);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Insert(true)
    end;

    local procedure VerifyBalanceAmountsOnFinancialJournalPage(var FinancialJournalPage: TestPage "Financial Journal"; ExpectedTotalDifference: Decimal; ExpectedBalance: Decimal; ExpectedTotalBalance: Decimal)
    begin
        FinancialJournalPage."Total Difference".AssertEquals(ExpectedTotalDifference);
        FinancialJournalPage.Balance.AssertEquals(ExpectedBalance);
        FinancialJournalPage."BalanceLastStatement - TotalBalance - ""Balance (LCY)"" + xRec.""Balance (LCY)""".AssertEquals(ExpectedTotalBalance);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Confirm: Boolean)
    begin
        Confirm := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GeneralJournalTemplateListModalPageHandler(var GeneralJournalTemplateListPage: TestPage "General Journal Template List")
    begin
        GeneralJournalTemplateListPage.FILTER.SetFilter(Name, LibraryVariableStorage.DequeueText());
        GeneralJournalTemplateListPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesModalPageHandler(var ApplyCustomerEntriesPage: TestPage "Apply Customer Entries")
    var
        Variant: Variant;
        AppliesTo: Text;
    begin
        ApplyCustomerEntriesPage.First();
        if ApplyCustomerEntriesPage.AppliesToID.Value <> '' then
            ApplyCustomerEntriesPage."Set Applies-to ID".Invoke();
        ApplyCustomerEntriesPage."Set Applies-to ID".Invoke();
        ApplyCustomerEntriesPage.Next();
        if ApplyCustomerEntriesPage.AppliesToID.Value <> '' then
            ApplyCustomerEntriesPage."Set Applies-to ID".Invoke();
        ApplyCustomerEntriesPage."Set Applies-to ID".Invoke();

        ApplyCustomerEntriesPage.First();
        LibraryVariableStorage.Dequeue(Variant);
        AppliesTo := Variant;
        Assert.AreEqual(AppliesTo, ApplyCustomerEntriesPage.AppliesToID.Value, 'Applies to ID does not match');

        ApplyCustomerEntriesPage.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure GeneralLedgerEntriesPageHandler(var GeneralLedgerEntries: TestPage "General Ledger Entries")
    var
        Variant: Variant;
        Amount: Decimal;
    begin
        LibraryVariableStorage.Dequeue(Variant);
        GeneralLedgerEntries.FILTER.SetFilter("Document No.", Variant);
        LibraryVariableStorage.Dequeue(Variant);
        Amount := Variant;
        GeneralLedgerEntries.First();
        Assert.AreEqual(Format(550005), GeneralLedgerEntries."G/L Account No.".Value, 'GL Account No.');
        Assert.AreEqual('Payment', GeneralLedgerEntries."Document Type".Value, 'Document Type');
        Assert.AreEqual(-1 * Amount, GeneralLedgerEntries.Amount.AsDecimal(), 'Amount 1');
        GeneralLedgerEntries.Next();
        Assert.AreEqual(Amount, GeneralLedgerEntries.Amount.AsDecimal(), 'Amount 2');
    end;
}

