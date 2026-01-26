codeunit 144018 "ERM MISC"
{
    // 1. Verify Transaction Mode Code and Bank Account Code after Posting Service Order.
    // 2. Verify Transaction Mode Code and Bank Account Code after Posting Service Invoice.
    // 3. Verify Transaction Mode Code and Bank Account Code after Posting Service Credit Memo.
    // 4. Verify Payment Discount after posting Sales Return Order.
    // 5. Verify Payment Discount after posting Purchase Return Order.
    //
    // Covers Test Cases for WI -  341960
    // ----------------------------------------------------------------------------------------------
    // Test Function Name                                                                      TFS ID
    // ----------------------------------------------------------------------------------------------
    // CustomerLedgerEntryAfterPostServiceOrder                                                217682
    // CustomerLedgerEntryAfterPostServiceInvoice                                              217684
    // CustomerLedgerEntryAfterPostServiceCreditMemo                                           217685
    // GLEntryAfterPostSalesReturnOrder                                                        242420
    // GLEntryAfterPostPurchaseReturnOrder                                                     242421

    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        AmountError: Label '%1 must be %2 in %3.';
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryNLLocalization: Codeunit "Library - NL Localization";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerLedgerEntryAfterPostServiceOrder()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Purpose of this test is to validate Transaction Mode Code and Bank Account Code in Table 21 - Cust. Ledger Entry with Service Order.
        CreateAndPostServiceDocument(ServiceHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerLedgerEntryAfterPostServiceInvoice()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Purpose of this test is to validate Transaction Mode Code and Bank Account Code in Table 21 - Cust. Ledger Entry with Service Invoice.
        CreateAndPostServiceDocument(ServiceHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerLedgerEntryAfterPostServiceCreditMemo()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Purpose of this test is to validate Transaction Mode Code and Bank Account Code in Table 21 - Cust. Ledger Entry with Service Credit Memo.
        CreateAndPostServiceDocument(ServiceHeader."Document Type"::"Credit Memo");
    end;

    local procedure CreateAndPostServiceDocument(DocumentType: Enum "Service Document Type")
    var
        ServiceHeader: Record "Service Header";
    begin
        // Setup: Create and Post Service Document with Transaction Mode Code and Bank Account Code.
        Initialize();
        CreateServiceDocument(ServiceHeader, DocumentType, CreateItem());

        // Exercise.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);  // Post as Ship and Invoice.

        // Verify: Verify Transaction Mode Code and Bank Account Code in Customer Ledger Entry.
        VerifyTransacModeCodeAndBankAccCodeInCustLedgEntry(ServiceHeader);
    end;

    [Test]
    [HandlerFunctions('GenJournalTemplListCBGPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure GLEntryAfterPostSalesReturnOrder()
    var
        CBGStatementLine: Record "CBG Statement Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        Amount: Decimal;
    begin
        // Purpose of this test is to Verify Payment Discount can be calculated when Document Type = Credit Memo & using the column Applies-To Doc No. in Bank/Giro journal line with posting Sales Return Order.

        // Setup: Create and Post Sales Return Order.
        Initialize();
        Amount := CreateAndPostSalesReturnOrder(SalesHeader);
        SalesCrMemoHeader.SetRange("Return Order No.", SalesHeader."No.");
        SalesCrMemoHeader.FindFirst();
        CreateAndPostBankGiroJournalAndVerifyGLEntry(
          CBGStatementLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.", SalesCrMemoHeader."No.", Amount);
    end;

    [Test]
    [HandlerFunctions('GenJournalTemplListCBGPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure GLEntryAfterPostPurchaseReturnOrder()
    var
        CBGStatementLine: Record "CBG Statement Line";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchaseHeader: Record "Purchase Header";
        Amount: Decimal;
    begin
        // Purpose of this test is to Verify Payment Discount can be calculated when Document Type = Credit Memo & using the column Applies-To Doc No. in Bank/Giro journal line with posting Purchase Return Order.

        // Setup: Create and Post Purchase Return Order.
        Initialize();
        Amount := CreateAndPostPurchaseReturnOrder(PurchaseHeader);
        PurchCrMemoHdr.SetRange("Return Order No.", PurchaseHeader."No.");
        PurchCrMemoHdr.FindFirst();
        CreateAndPostBankGiroJournalAndVerifyGLEntry(
          CBGStatementLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.", PurchCrMemoHdr."No.", Amount);
    end;

    [Test]
    [HandlerFunctions('WhereUsedHandler')]
    [Scope('OnPrem')]
    procedure GLAccWhereUsedBankAccountPostingGroup()
    var
        GLAccount: Record "G/L Account";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        CalcGLAccWhereUsed: Codeunit "Calc. G/L Acc. Where-Used";
    begin
        // [FEATURE] [G/L Account Where-Used]
        // [SCENARIO 251566] Bank Account Posting Group should be shown on Where-Used page
        Initialize();

        // [GIVEN] Bank Account Posting Group with "Acc.No. Pmt./Rcpt. in Process" = "G"
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Direct Posting", false);
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.Modify(true);
        LibraryERM.CreateBankAccountPostingGroup(BankAccountPostingGroup);
        BankAccountPostingGroup.Validate("Acc.No. Pmt./Rcpt. in Process", GLAccount."No.");
        BankAccountPostingGroup.Modify(true);

        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(BankAccountPostingGroup.FieldName("Acc.No. Pmt./Rcpt. in Process"));

        // [WHEN] Run Where-Used function for G/L Account "G"
        CalcGLAccWhereUsed.CheckGLAcc(BankAccountPostingGroup."Acc.No. Pmt./Rcpt. in Process");

        // [THEN] Bank Account Posting Group is shown on "G/L Account Where-Used List"
        // Verify in WhereUsedHandler

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('WhereUsedHandler')]
    [Scope('OnPrem')]
    procedure GLAccWhereUsedBankAccountPostingGroupW1AndLocalFieldAndW1Table()
    var
        GLAccount: Record "G/L Account";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        CustomerPostingGroup: Record "Customer Posting Group";
        TransactionMode: Record "Transaction Mode";
        CalcGLAccWhereUsed: Codeunit "Calc. G/L Acc. Where-Used";
    begin
        // [FEATURE] [G/L Account Where-Used]
        // [SCENARIO 251566] G/L Account is shown for all fields in the same table and in another table
        Initialize();

        // [GIVEN] G/L Account "G" is used in Bank Account Posting Group as "Acc.No. Pmt./Rcpt. in Process" and "G/L Account No."
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Direct Posting", false);
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.Modify(true);
        LibraryERM.CreateBankAccountPostingGroup(BankAccountPostingGroup);
        BankAccountPostingGroup.Validate("G/L Account No.", GLAccount."No.");
        BankAccountPostingGroup.Validate("Acc.No. Pmt./Rcpt. in Process", GLAccount."No.");
        BankAccountPostingGroup.Modify(true);

        // [GIVEN] G/L Account "G" is used in Customer Posting Group as "Receivables Account"
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        CustomerPostingGroup.Validate("Receivables Account", GLAccount."No.");
        CustomerPostingGroup.Modify(true);

        // [GIVEN] Transaction Mode has "Acc. No. Pmt./Rcpt. in Process" = "G"
        LibraryNLLocalization.CreateTransactionMode(TransactionMode, TransactionMode."Account Type"::Customer);
        TransactionMode.Validate("Acc. No. Pmt./Rcpt. in Process", GLAccount."No.");
        TransactionMode.Modify(true);

        LibraryVariableStorage.Enqueue(4);
        LibraryVariableStorage.Enqueue(BankAccountPostingGroup.FieldName("G/L Account No."));
        LibraryVariableStorage.Enqueue(BankAccountPostingGroup.FieldName("Acc.No. Pmt./Rcpt. in Process"));
        LibraryVariableStorage.Enqueue(CustomerPostingGroup.FieldName("Receivables Account"));
        LibraryVariableStorage.Enqueue(TransactionMode.FieldName("Acc. No. Pmt./Rcpt. in Process"));

        // [WHEN] Run Where-Used function for G/L Account "G"
        CalcGLAccWhereUsed.CheckGLAcc(GLAccount."No.");

        // [THEN] Bank Account Posting Group is shown on "G/L Account Where-Used List" with local and W1 field
        // [THEN] Customer Posting Group is shown on "G/L Account Where-Used List"
        // [THEN] Transaction Mode is shown on "G/L Account Where-Used List"

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CBGStatementNoWhenInsertNewRecordForNewTemplate()
    var
        CBGStatement: Record "CBG Statement";
    begin
        // [FEATURE] [UT] [Bank/Giro Journal] [CBG Statement]
        // [SCENARIO 271072] When insert CBG Statement for new Template, then CBG Statement."No." always equals to 1
        Initialize();

        // [GIVEN] Init CBG Statement with "Journal Template Name" = new Gen Journal Template and "No." = 1001
        CBGStatement.Init();
        CBGStatement.Validate("Journal Template Name", CreateGenJournalTemplateWithBankAccount(CreateBankAccountNo()));
        CBGStatement.Validate("No.", LibraryRandom.RandIntInRange(1000, 2000));

        // [WHEN] Insert CBG Statement
        CBGStatement.Insert(true);

        // [THEN] CBG Statement "No." = 1
        CBGStatement.TestField("No.", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CBGStatementNoWhenInsertNewRecord()
    var
        CBGStatement: Record "CBG Statement";
        GenJnlTemplateName: Code[10];
        FirstCBGStatementNo: Integer;
        SecondCBGStatementNo: Integer;
    begin
        // [FEATURE] [Bank/Giro Journal] [CBG Statement]
        // [SCENARIO 271072] When insert new CBG Statement for the Template, then CBG Statement."No." = Last CBG Statement "No." for the same Template increased by 1.
        Initialize();

        // [GIVEN] Gen. Journal Template "T"
        GenJnlTemplateName := CreateGenJournalTemplateWithBankAccount(CreateBankAccountNo());

        // [GIVEN] CBG Statement with Journal Template Name = "T" and "No." = 1;
        FirstCBGStatementNo := CreateCBGStatementWithTemplate(GenJnlTemplateName);

        // [GIVEN] CBG Statement with Journal Template Name = "T" and "No." = 2;
        SecondCBGStatementNo := CreateCBGStatementWithTemplate(GenJnlTemplateName);

        // [GIVEN] Deleted CBG Statement with "No." = 1
        DeleteCBGStatement(GenJnlTemplateName, FirstCBGStatementNo);

        // [GIVEN] New CBG Statement with Journal Template Name = "T"
        CBGStatement.Init();
        CBGStatement.Validate("Journal Template Name", GenJnlTemplateName);

        // [WHEN] Insert new CBG Statement
        CBGStatement.Insert(true);

        // [THEN] New CBG Statement "No." = 3
        CBGStatement.TestField("No.", SecondCBGStatementNo + 1);
    end;

    [Test]
    [HandlerFunctions('GenJournalTemplListCBGPageHandler')]
    [Scope('OnPrem')]
    procedure BankGiroJournalWhenCreateNewFromTemplate()
    var
        BankGiroJournal: TestPage "Bank/Giro Journal";
        BankAccountNo: Code[20];
    begin
        // [FEATURE] [UI] [Bank/Giro Journal]
        // [SCENARIO 271072] Stan creates new Bank/Giro Journal from template without errors on Bank/Giro Journal page
        Initialize();

        // [GIVEN] Bank Account "B"
        BankAccountNo := CreateBankAccountNo();

        // [GIVEN] Gen Journal Template with Bal. Account = "B"
        LibraryVariableStorage.Enqueue(CreateGenJournalTemplateWithBankAccount(BankAccountNo));

        // [GIVEN] Stan pushed "New" on page Bank/Giro Journal List
        BankGiroJournal.OpenNew();

        // [GIVEN] Page Gen. Journal Templ. List (CBG) opened and Stan selected Template on page
        // Selection is done in GenJournalTemplListCBGPageHandler

        // [WHEN] Stan pushes OK on page Gen. Journal Templ. List (CBG)
        // Selection is done in GenJournalTemplListCBGPageHandler

        // [THEN] Page Bank/Giro Journal opens with "Account No." = "B" and "No." = 0
        BankGiroJournal."Account No.".AssertEquals(BankAccountNo);
        BankGiroJournal."No.".AssertEquals(0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GenJournalTemplListCBGPageHandler')]
    [Scope('OnPrem')]
    procedure BankGiroJournalUpdateNoWhenInsertCBGStatement()
    var
        CBGStatement: Record "CBG Statement";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        GenJnlTemplateName: Code[10];
    begin
        // [FEATURE] [UI] [Bank/Giro Journal]
        // [SCENARIO 271072] No is updated on Bank/Giro Journal page when CBG Statement is inserted
        Initialize();

        // [GIVEN] Stan created new Bank/Giro Journal from new Template
        GenJnlTemplateName := CreateGenJournalTemplateWithBankAccount(CreateBankAccountNo());
        LibraryVariableStorage.Enqueue(GenJnlTemplateName);
        BankGiroJournal.OpenNew();

        // [WHEN] Stan switches to field "Opening Balance"
        BankGiroJournal."Opening Balance".SetValue(LibraryRandom.RandDecInRange(10, 20, 2));

        // [THEN] CBG Statement with No. = 1 is inserted for new Template
        CBGStatement.SetRange("Journal Template Name", GenJnlTemplateName);
        CBGStatement.FindLast();
        CBGStatement.TestField("No.", 1);

        // [THEN] Stan can see No. = 1 on Bank/Giro Journal page
        BankGiroJournal."No.".AssertEquals(CBGStatement."No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM MISC");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM MISC");

        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.Save(DATABASE::"Company Information");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM MISC");
    end;

    local procedure CreateCBGStatementWithTemplate(GenJnlTemplateName: Code[10]): Integer
    var
        CBGStatement: Record "CBG Statement";
    begin
        CBGStatement.Init();
        CBGStatement.Validate("Journal Template Name", GenJnlTemplateName);
        CBGStatement.Insert(true);
        exit(CBGStatement."No.");
    end;

    local procedure DeleteCBGStatement(GenJnlTemplateName: Code[10]; CBGStatementNo: Integer)
    var
        CBGStatement: Record "CBG Statement";
    begin
        CBGStatement.Get(GenJnlTemplateName, CBGStatementNo);
        CBGStatement.Delete(true);
    end;

    local procedure CreateBankAccountNo(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        exit(BankAccount."No.");
    end;

    local procedure CreateGenJournalTemplateWithBankAccount(BankAccountNo: Code[20]): Code[10]
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::Bank);
        GenJournalTemplate.Validate("Bal. Account Type", GenJournalTemplate."Bal. Account Type"::"Bank Account");
        GenJournalTemplate.Validate("Bal. Account No.", BankAccountNo);
        GenJournalTemplate.Validate("No. Series", LibraryERM.CreateNoSeriesCode());
        GenJournalTemplate.Modify(true);
        exit(GenJournalTemplate.Name);
    end;

    local procedure CreateAndPostBankGiroJournalAndVerifyGLEntry(AccountType: Option; AccountNo: Code[20]; AppliesToDocNo: Code[20]; Amount: Decimal)
    var
        CBGStatement: Record "CBG Statement";
    begin
        // Setup: Create and Post Bank Giro Journal.
        CreateBankGiroJournal(CBGStatement, AccountType, AccountNo, AppliesToDocNo, Amount);
        LibraryVariableStorage.Enqueue(CBGStatement."Journal Template Name");  // Enqueue value for GenJournalTemplListCBGPageHandler.

        // Exercise.
        PostBankGiroJournal(CBGStatement."Journal Template Name", CBGStatement."Document No.");

        // Verify: Verify Payment Discount Amount.
        VerifyGLEntry(CBGStatement."Document No.", -Amount);
    end;

    local procedure CreateBankGiroJournal(var CBGStatement: Record "CBG Statement"; AccountType: Option; AccountNo: Code[20]; AppliesToDocNo: Code[20]; Amount: Decimal)
    var
        CBGStatementLine: Record "CBG Statement Line";
    begin
        CBGStatement.Validate("Journal Template Name", 'POSTBANK');  // Use Hard Code value for POSTBANK.
        CBGStatement.Validate("No.", LibraryRandom.RandInt(10));
        CBGStatement.Insert(true);
        CBGStatementLine.Validate("Journal Template Name", CBGStatement."Journal Template Name");
        CBGStatementLine.Validate("No.", CBGStatement."No.");
        CBGStatementLine.Validate("Line No.", LibraryRandom.RandInt(10));
        CBGStatementLine.Insert(true);
        CBGStatementLine.Validate(Date, WorkDate());
        CBGStatementLine.Validate("Account Type", AccountType);
        CBGStatementLine.Validate("Account No.", AccountNo);
        CBGStatementLine.Validate("Applies-to Doc. Type", CBGStatementLine."Applies-to Doc. Type"::"Credit Memo");
        CBGStatementLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        CBGStatementLine.Validate(Amount, Amount);
        CBGStatementLine.Modify(true);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        TransactionMode: Record "Transaction Mode";
    begin
        TransactionMode.FindFirst();
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Transaction Mode Code", TransactionMode.Code);
        Customer.Validate("Preferred Bank Account Code", CreateCustomerBankAccount(Customer."No."));
        Customer.Validate("Payment Terms Code", CreatePaymentTerms());
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerBankAccount(CustomerNo: Code[20]): Code[10]
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        CustomerBankAccount.Validate("Customer No.", CustomerNo);
        CustomerBankAccount.Validate(
          Code, LibraryUtility.GenerateRandomCode(CustomerBankAccount.FieldNo("Customer No."), DATABASE::"Customer Bank Account"));
        CustomerBankAccount.Insert(true);
        exit(CustomerBankAccount.Code);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(10, 2));  // Using Random value for Unit Price.
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePaymentTerms(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, true);
        exit(PaymentTerms.Code);
    end;

    local procedure CreateAndPostPurchaseReturnOrder(var PurchaseHeader: Record "Purchase Header") Amount: Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", CreateVendor());
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2));  // Taking Random Quantity.
        Amount := PurchaseLine."Outstanding Amount" - (PurchaseLine."Outstanding Amount" / PurchaseHeader."Payment Discount %") / 100;
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostSalesReturnOrder(var SalesHeader: Record "Sales Header") Amount: Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", CreateCustomer());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2));  // Taking Random Quantity.
        Amount := SalesLine."Outstanding Amount" - (SalesLine."Outstanding Amount" / SalesHeader."Payment Discount %") / 100;
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateServiceDocument(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"; ItemNo: Code[20])
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, CreateCustomer());
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        if DocumentType = ServiceHeader."Document Type"::Order then begin
            LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
            LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
            ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        end;
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));  // Taking Random Quantity.
        ServiceLine.Modify(true);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
        TransactionMode: Record "Transaction Mode";
    begin
        TransactionMode.FindFirst();
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Transaction Mode Code", TransactionMode.Code);
        Vendor.Validate("Preferred Bank Account Code", CreateVendorBankAccount(Vendor."No."));
        Vendor.Validate("Payment Terms Code", CreatePaymentTerms());
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorBankAccount(VendorNo: Code[20]): Code[10]
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        VendorBankAccount.Validate("Vendor No.", VendorNo);
        VendorBankAccount.Validate(
          Code, LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo("Vendor No."), DATABASE::"Vendor Bank Account"));
        VendorBankAccount.Insert(true);
        exit(VendorBankAccount.Code);
    end;

    local procedure PostBankGiroJournal(JournalTemplateName: Code[10]; DocumentNo: Code[20])
    var
        BankGiroJournal: TestPage "Bank/Giro Journal";
    begin
        BankGiroJournal.OpenEdit();
        BankGiroJournal.FILTER.SetFilter("Account No.", JournalTemplateName);
        BankGiroJournal.FILTER.SetFilter("Document No.", DocumentNo);
        BankGiroJournal.Post.Invoke();
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Source Type", GLEntry."Source Type"::"Bank Account");
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountError, GLEntry.FieldCaption(Amount), GLEntry.Amount, GLEntry.TableCaption()));
    end;

    local procedure VerifyTransacModeCodeAndBankAccCodeInCustLedgEntry(ServiceHeader: Record "Service Header")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", ServiceHeader."Customer No.");
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.TestField("Transaction Mode Code", ServiceHeader."Transaction Mode Code");
        CustLedgerEntry.TestField("Recipient Bank Account", ServiceHeader."Bank Account Code");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GenJournalTemplListCBGPageHandler(var GenJournalTemplListCBG: TestPage "Gen. Journal Templ. List (CBG)")
    begin
        GenJournalTemplListCBG.FILTER.SetFilter(Name, LibraryVariableStorage.DequeueText());
        GenJournalTemplListCBG.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhereUsedHandler(var GLAccountWhereUsedList: TestPage "G/L Account Where-Used List")
    var
        i: Integer;
    begin
        GLAccountWhereUsedList.First();
        for i := 2 to LibraryVariableStorage.DequeueInteger() do begin // for 2 lines and more
            GLAccountWhereUsedList."Field Name".AssertEquals(LibraryVariableStorage.DequeueText());
            GLAccountWhereUsedList.Next();
        end;
        GLAccountWhereUsedList."Field Name".AssertEquals(LibraryVariableStorage.DequeueText());
        GLAccountWhereUsedList.OK().Invoke();
    end;
}
