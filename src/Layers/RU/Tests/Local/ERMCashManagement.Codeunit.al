codeunit 144700 "ERM Cash Management"
{
    // // [FEATURE] [Cash Management]

    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        CopyPayDocDocumentType: Option "Payment order","Ingoing order","Outgoing order";
        IncorrectFieldValueErr: Label 'Field %1 value is incorrect';
        PaymentCodeErr: Label 'Incorrect Payment Code in table %1.';

    [Test]
    [Scope('OnPrem')]
    procedure CreateSimpleCashAccountCard()
    begin
        CreateVerifyCashAccountCard('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateCashAccountCardWithCurrency()
    begin
        CreateVerifyCashAccountCard(FindCurrencyCode());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateAndPostIOutgoingCashPaymentOrder()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        asserterror CreatePostCashOrder(GenJnlLine."Account Type"::Vendor, CreateVendor(), 1);
        Assert.ExpectedTestFieldError(GenJnlLine.FieldCaption("Check Printed"), Format(true));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateAndPostIngoingCashPaymentOrder()
    var
        GenJnlLine: Record "Gen. Journal Line";
        BankAccLedgerEntry: Record "Bank Account Ledger Entry";
        Amount: Decimal;
    begin
        Amount := CreatePostCashOrder(GenJnlLine."Account Type"::Customer, CreateCustomer(), -1);

        BankAccLedgerEntry.FindLast();
        Assert.AreEqual(-Amount, BankAccLedgerEntry.Amount, BankAccLedgerEntry.FieldCaption(Amount));
    end;

    [Test]
    [HandlerFunctions('BankPaymentOrderHandler')]
    [Scope('OnPrem')]
    procedure OpenBankPaymentOrderPageForCustomerJnlLine()
    var
        GenJnlLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        BankPaymentOrder: Page "Bank Payment Order";
    begin
        Initialize();

        Customer.Get(CreateCustomer());
        LibraryVariableStorage.Enqueue(DelChr(Customer."VAT Registration No.", '<>', ' '));
        CreateBankOrder(GenJnlLine, GenJnlLine."Account Type"::Customer, Customer."No.");

        GenJnlLine.Amount := -Abs(GenJnlLine.Amount);
        GenJnlLine.Modify();

        BankPaymentOrder.SetRecord(GenJnlLine);
        BankPaymentOrder.Run();
    end;

    [Test]
    [HandlerFunctions('BankPaymentOrderHandler')]
    [Scope('OnPrem')]
    procedure OpenBankPaymentOrderPageForVendorJnlLine()
    var
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        BankPaymentOrder: Page "Bank Payment Order";
    begin
        Initialize();

        Vendor.Get(CreateVendor());
        LibraryVariableStorage.Enqueue(DelChr(Vendor."VAT Registration No.", '<>', ' '));
        CreateBankOrder(GenJnlLine, GenJnlLine."Account Type"::Vendor, Vendor."No.");

        BankPaymentOrder.SetRecord(GenJnlLine);
        BankPaymentOrder.Run();
    end;

    [Test]
    [HandlerFunctions('BankPaymentOrderHandler')]
    [Scope('OnPrem')]
    procedure OpenBankPaymentOrderPageForBankAccountJnlLine()
    var
        GenJnlLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        CompanyInformation: Record "Company Information";
        BankPaymentOrder: Page "Bank Payment Order";
    begin
        Initialize();

        LibraryERM.CreateBankAccount(BankAccount);
        CreateBankOrder(GenJnlLine, GenJnlLine."Account Type"::"Bank Account", BankAccount."No.");

        CompanyInformation.Get();
        LibraryVariableStorage.Enqueue(DelChr(CompanyInformation."VAT Registration No.", '<>', ' '));

        BankPaymentOrder.SetRecord(GenJnlLine);
        BankPaymentOrder.Run();
    end;

    [Test]
    [HandlerFunctions('ReportCopyPayDocumentHandler')]
    [Scope('OnPrem')]
    procedure VerifyCopyPayDocumentReport()
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        CopyPayDocument: Report "Copy Pay Document";
        RecRef: RecordRef;
    begin
        // Check report Copy Pay Document creates Gen. Jnl. Line. with correct Amount
        Initialize();
        FindGenJournalLine(GenJnlLine);
        CheckLedgerEntry.Init();
        RecRef.GetTable(CheckLedgerEntry);
        CheckLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, CheckLedgerEntry.FieldNo("Entry No."));
        CheckLedgerEntry."Bank Payment Type" := CheckLedgerEntry."Bank Payment Type"::"Computer Check";
        CheckLedgerEntry."Bank Account Type" := CheckLedgerEntry."Bank Account Type"::"Bank Account";
        CheckLedgerEntry."Bal. Account Type" := CheckLedgerEntry."Bal. Account Type"::"Bank Account";
        CheckLedgerEntry.Amount := LibraryRandom.RandDec(1000, 2);
        CheckLedgerEntry.Insert();
        Commit();

        LibraryVariableStorage.Enqueue(CopyPayDocDocumentType::"Payment order");
        LibraryVariableStorage.Enqueue(CheckLedgerEntry."Entry No.");
        CopyPayDocument.SetJournalLine(GenJnlLine);
        CopyPayDocument.Run();

        GenJnlLine.Next();
        VerifyGenJnlLine(GenJnlLine, CheckLedgerEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGenJnlLineWithPaymentCode()
    var
        DocumentNo: Code[20];
        PaymentCode: Text;
    begin
        // Check Payment Code transferred correctly to Gen. Jnl. Line Archieve and Check Ledger Entry while posting
        Initialize();
        DocumentNo := CreateAndPostGenJnlLineWithPaymentCode(PaymentCode);
        VerifyPostedPaymentCode(DocumentNo, PaymentCode);
    end;

    [Test]
    [HandlerFunctions('GeneralJournalPageHandler')]
    [Scope('OnPrem')]
    procedure TransferBankAccReconLineWithPaymentCode()
    var
        BankAccRecon: Record "Bank Acc. Reconciliation";
        PaymentCode: Text;
        GenJnlTemplateName: Code[10];
        GenJnlBatchName: Code[10];
    begin
        // Check Payment Code transfered correctly to Gen. Jnl. Line while transferring Bank Account Reconciliation Line
        Initialize();

        CreateBankAccountReconciliation(BankAccRecon, PaymentCode);
        RunTransBankRecToGenJnlReport(GenJnlTemplateName, GenJnlBatchName, BankAccRecon);

        VerifyGenJnlLinePaymentCode(GenJnlTemplateName, GenJnlBatchName, PaymentCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ManualCashOrderHasCheckLedgerEntry11()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccountNo: Code[20];
    begin
        // [FEATURE] [Cash Management]
        // [SCENARIO 166104] Posting of Cash Order with Manual Check payment creates a Check Ledger Entry
        Initialize();
        // [GIVEN] Bank Account "B" with type "Cash Account"
        // [GIVEN] Cash Order, where "Amount" is negative,"Bank Payment Type" = "Manual Check", "Balance Account No." = "B"

        CreateManualCashOrder(GenJournalLine, -1);
        BankAccountNo := GenJournalLine."Bal. Account No.";

        // [WHEN] Posting Cash Order
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] a Bank Account Ledger Entry and a Check Ledger Entry for Bank Account "B" is created
        TestIfCheckLedgEntryIsCreated(BankAccountNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ManualCashOrderHasCheckLedgerEntry12()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccountNo: Code[20];
    begin
        // [FEATURE] [Cash Management]
        // [SCENARIO 166104] Posting of Cash Order with Manual Check payment creates a Check Ledger Entry
        Initialize();
        // [GIVEN] Bank Account "B" with type "Cash Account"
        // [GIVEN] Cash Order, where "Amount" is negative,"Bank Payment Type" = "Manual Check", "Account No." = "B"

        CreateManualCashOrderRev(GenJournalLine, -1);
        BankAccountNo := GenJournalLine."Account No.";

        // [WHEN] Posting Cash Order
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] a Bank Account Ledger Entry and a Check Ledger Entry for Bank Account "B" is created
        TestIfCheckLedgEntryIsCreated(BankAccountNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ManualCashOrderHasCheckLedgerEntry21()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccountNo: Code[20];
    begin
        // [FEATURE] [Cash Management]
        // [SCENARIO 166104] Posting of Cash Order with Manual Check payment creates a Check Ledger Entry
        Initialize();
        // [GIVEN] Bank Account "B" with type "Cash Account"
        // [GIVEN] Cash Order, where "Amount" is positive,"Bank Payment Type" = "Manual Check", "Balance Account No." = "B"

        CreateManualCashOrder(GenJournalLine, 1);
        BankAccountNo := GenJournalLine."Bal. Account No.";

        // [WHEN] Posting Cash Order
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] a Bank Account Ledger Entry and a Check Ledger Entry for Bank Account "B" is created
        TestIfCheckLedgEntryIsCreated(BankAccountNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ManualCashOrderHasCheckLedgerEntry22()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccountNo: Code[20];
    begin
        // [FEATURE] [Cash Management]
        // [SCENARIO 166104] Posting of Cash Order with Manual Check payment creates a Check Ledger Entry
        Initialize();
        // [GIVEN] Bank Account "B" with type "Cash Account"
        // [GIVEN] Cash Order, where "Amount" is positive,"Bank Payment Type" = "Manual Check", "Account No." = "B"

        CreateManualCashOrderRev(GenJournalLine, 1);
        BankAccountNo := GenJournalLine."Account No.";

        // [WHEN] Posting Cash Order
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] a Bank Account Ledger Entry and a Check Ledger Entry for Bank Account "B" is created
        TestIfCheckLedgEntryIsCreated(BankAccountNo);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateVerifyCashAccountCard(CurrencyCode: Code[10])
    var
        AccNo: Code[20];
        BankAccPostGr: Code[20];
    begin
        Initialize();

        BankAccPostGr := FindBankAccPostGr();
        AccNo := CreateCashAccountCard(BankAccPostGr, CurrencyCode);

        VerifyCashAccCard(AccNo, BankAccPostGr, CurrencyCode);
    end;

    local procedure CreatePostCashOrder(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; AmountSign: Integer): Decimal
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        CreateCashOrder(GenJnlLine, AccountType, AccountNo, '', AmountSign,
          GenJnlLine."Bank Payment Type"::"Computer Check");
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        exit(GenJnlLine.Amount);
    end;

    local procedure CreateCashAccountCard(PostGr: Code[20]; CurrencyCode: Code[10]) AccNo: Code[20]
    var
        CashAccCard: TestPage "Cash Account Card";
    begin
        CashAccCard.OpenNew();
        CashAccCard."Bank Acc. Posting Group".SetValue(PostGr);
        CashAccCard."Currency Code".SetValue(CurrencyCode);
        AccNo := CashAccCard."No.".Value();
        CashAccCard.OK().Invoke();
    end;

    local procedure CreateCashAccount(CurrencyCode: Code[10]): Code[20]
    var
        CashAccount: Record "Bank Account";
    begin
        CashAccount.Validate("Account Type", CashAccount."Account Type"::"Cash Account");
        CashAccount.Validate("Bank Acc. Posting Group", FindBankAccPostGr());
        CashAccount.Validate("Currency Code", CurrencyCode);
        CashAccount.Validate("Debit Cash Order No. Series", LibraryERM.CreateNoSeriesCode());
        CashAccount.Validate("Credit Cash Order No. Series", CashAccount."Debit Cash Order No. Series");
        CashAccount.Insert(true);
        CashAccount.Validate(Name, CashAccount."No.");
        CashAccount.Modify(true);
        exit(CashAccount."No.");
    end;

    local procedure CreateManualCashOrder(var GenJnlLine: Record "Gen. Journal Line"; AmountSign: Integer)
    begin
        CreateCashOrder(GenJnlLine, GenJnlLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), '', AmountSign,
          GenJnlLine."Bank Payment Type"::"Manual Check");
    end;

    local procedure CreateManualCashOrderRev(var GenJnlLine: Record "Gen. Journal Line"; AmountSign: Integer)
    begin
        CreateCashOrderRev(GenJnlLine, GenJnlLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), '', AmountSign,
          GenJnlLine."Bank Payment Type"::"Manual Check");
    end;

    local procedure CreateCashOrder(var GenJnlLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; CurrencyCode: Code[10]; AmountSign: Integer; BankPaymType: Enum "Bank Payment Type")
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        BankAccount: Record "Bank Account";
    begin
        FindGenJournalBatch(GenJnlBatch, GenJnlBatch."Bal. Account Type"::"Bank Account");
        BankAccount.Get(CreateCashAccount(CurrencyCode));

        CreateGenJnlLine(
          GenJnlLine, GenJnlBatch."Journal Template Name", GenJnlBatch.Name,
          AccountType, AccountNo, GenJnlLine."Bal. Account Type"::"Bank Account", BankAccount."No.",
          BankAccount."Debit Cash Order No. Series", AmountSign, BankPaymType);
    end;

    local procedure CreateCashOrderRev(var GenJnlLine: Record "Gen. Journal Line"; BalAccType: Enum "Gen. Journal Account Type"; BalAccNo: Code[20]; CurrencyCode: Code[10]; AmountSign: Integer; BankPaymType: Enum "Bank Payment Type")
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        BankAccount: Record "Bank Account";
    begin
        FindGenJournalBatch(GenJnlBatch, BalAccType);
        BankAccount.Get(CreateCashAccount(CurrencyCode));

        CreateGenJnlLine(
          GenJnlLine, GenJnlBatch."Journal Template Name", GenJnlBatch.Name,
          GenJnlLine."Account Type"::"Bank Account", BankAccount."No.", BalAccType, BalAccNo, BankAccount."Debit Cash Order No. Series",
          AmountSign, BankPaymType);
    end;

    local procedure CreateBankOrder(var GenJnlLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        BankAccount: Record "Bank Account";
    begin
        FindGenJournalBank(GenJnlBatch);
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Bank Payment Order No. Series", LibraryERM.CreateNoSeriesCode());
        BankAccount.Modify(true);

        CreateGenJnlLine(
          GenJnlLine, GenJnlBatch."Journal Template Name", GenJnlBatch.Name,
          AccountType, AccountNo, GenJnlLine."Bal. Account Type"::"Bank Account", BankAccount."No.",
          BankAccount."Bank Payment Order No. Series", 1, GenJnlLine."Bank Payment Type"::"Computer Check");
    end;

    local procedure CreateGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; TemplateName: Code[10]; BatchName: Code[10]; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BalAccType: Enum "Gen. Journal Account Type"; BalAccNo: Code[20]; SeriesNo: Code[20]; AmountSign: Integer; BankPaymType: Enum "Bank Payment Type")
    var
        NoSeries: Codeunit "No. Series";
    begin
        LibraryERM.CreateGeneralJnlLine(GenJnlLine, TemplateName, BatchName,
            GenJnlLine."Document Type"::Payment, AccountType, AccountNo, AmountSign * LibraryRandom.RandDecInRange(100, 1000, 2));
        GenJnlLine.Validate("Bal. Account Type", BalAccType);
        GenJnlLine.Validate("Bal. Account No.", BalAccNo);
        GenJnlLine.Validate("Document No.", NoSeries.GetNextNo(SeriesNo));
        GenJnlLine.Validate("Bank Payment Type", BankPaymType);
        GenJnlLine.Modify(true);
    end;

    local procedure FindBankAccPostGr(): Code[20]
    var
        BankAccPostingGroup: Record "Bank Account Posting Group";
    begin
        LibraryERM.FindBankAccountPostingGroup(BankAccPostingGroup);
        exit(BankAccPostingGroup.Code);
    end;

    local procedure FindCurrencyCode(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.FindCurrency(Currency);
        exit(Currency.Code);
    end;

    local procedure FindGenJournalBatch(var GenJnlBatch: Record "Gen. Journal Batch"; BalAccType: Enum "Gen. Journal Account Type")
    var
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        GenJnlTemplate.SetRange(Type, GenJnlTemplate.Type::"Cash Order Payments");
        LibraryERM.FindGenJournalTemplate(GenJnlTemplate);
        CreateGenJnlBatch(GenJnlBatch, GenJnlTemplate.Name, BalAccType);
    end;

    local procedure FindGenJournalBank(var GenJnlBatch: Record "Gen. Journal Batch")
    var
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);
        GenJnlTemplate.Validate(Type, GenJnlTemplate.Type::"Bank Payments");
        GenJnlTemplate.Modify(true);
        CreateGenJnlBatch(GenJnlBatch, GenJnlTemplate.Name, GenJnlBatch."Bal. Account Type"::"Bank Account");
    end;

    local procedure CreateGenJnlBatch(var GenJnlBatch: Record "Gen. Journal Batch"; TemplateName: Code[10]; BalAccType: Enum "Gen. Journal Account Type")
    begin
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, TemplateName);
        GenJnlBatch."Bal. Account Type" := BalAccType;
        GenJnlBatch.Modify();
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        Customer."Default Bank Code" := CustomerBankAccount.Code;
        Customer."VAT Registration No." :=
          LibraryUtility.GenerateRandomCode(Customer.FieldNo("VAT Registration No."), DATABASE::Customer);
        Customer.Modify();
        exit(Customer."No.");
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        VendorBankAccount."Bank Branch No." := VendorBankAccount.Code;
        VendorBankAccount.Modify();

        Vendor."Default Bank Code" := VendorBankAccount.Code;
        Vendor."VAT Registration No." :=
          LibraryUtility.GenerateRandomCode(Vendor.FieldNo("VAT Registration No."), DATABASE::Vendor);
        Vendor.Modify();

        exit(Vendor."No.");
    end;

    local procedure VerifyCashAccCard(No: Code[20]; PostGr: Code[20]; CurrencyCode: Code[10])
    var
        CashAccount: Record "Bank Account";
    begin
        CashAccount.Get(No);
        Assert.AreEqual(PostGr, CashAccount."Bank Acc. Posting Group", CashAccount.FieldCaption("Bank Acc. Posting Group"));
        Assert.AreEqual(CurrencyCode, CashAccount."Currency Code", CashAccount.FieldCaption("Currency Code"));
        Assert.AreEqual(CashAccount."Account Type"::"Cash Account", CashAccount."Account Type", CashAccount.FieldCaption("Account Type"));
    end;

    local procedure FindGenJournalLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlLine.SetFilter("Journal Batch Name", '<>''''');
        GenJnlLine.SetFilter("Journal Template Name", '<>''''');
        GenJnlLine.FindLast();
    end;

    local procedure CreateBankAccountReconciliation(var BankAccRecon: Record "Bank Acc. Reconciliation"; var PaymentCode: Text)
    var
        BankAccount: Record "Bank Account";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERM.CreateBankAccReconciliation(BankAccRecon, BankAccount."No.", "Bank Acc. Rec. Stmt. Type"::"Bank Reconciliation");
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconLine, BankAccRecon);

        BankAccReconLine.Validate("Payment Code", LibraryUtility.GenerateRandomText(MaxStrLen(BankAccReconLine."Payment Code")));
        BankAccReconLine.Validate("Line Status", BankAccReconLine."Line Status"::"Contractor Confirmed");
        BankAccReconLine.Validate("Statement Amount", LibraryRandom.RandInt(100));
        BankAccReconLine."Transaction Date" := WorkDate();
        BankAccReconLine.Modify(true);
        PaymentCode := BankAccReconLine."Payment Code";
    end;

    local procedure RunTransBankRecToGenJnlReport(var GenJnlTemplateName: Code[10]; var GenJnlBatchName: Code[10]; var BankAccRecon: Record "Bank Acc. Reconciliation")
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        TransBankRectoGenJnl: Report "Trans. Bank Rec. to Gen. Jnl.";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        GenJnlTemplateName := GenJnlTemplate.Name;
        GenJnlBatchName := GenJnlBatch.Name;

        TransBankRectoGenJnl.InitializeRequest(GenJnlTemplateName, GenJnlBatchName);
        TransBankRectoGenJnl.SetBankAccRecon(BankAccRecon);
        TransBankRectoGenJnl.UseRequestPage(false);
        TransBankRectoGenJnl.Run();
    end;

    local procedure CreateAndPostGenJnlLineWithPaymentCode(var PaymentCode: Text): Code[20]
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        BankAccount: Record "Bank Account";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);
        GenJnlTemplate.Validate(Archive, true);
        GenJnlTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);

        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Account Type", BankAccount."Account Type"::"Cash Account");
        BankAccount.Modify(true);

        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJnlLine, GenJnlTemplate.Name, GenJnlBatch.Name, GenJnlLine."Document Type"::" ",
            GenJnlLine."Account Type"::"G/L Account", GLAccount."No.",
            GenJnlLine."Bal. Account Type"::"Bank Account", BankAccount."No.",
            LibraryRandom.RandInt(1000));
        GenJnlLine.Validate("Payment Code", LibraryUtility.GenerateRandomText(MaxStrLen(GenJnlLine."Payment Code")));
        GenJnlLine.Validate("Bank Payment Type", GenJnlLine."Bank Payment Type"::"Manual Check");
        GenJnlLine.Modify(true);
        PaymentCode := GenJnlLine."Payment Code";
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        exit(GenJnlLine."Document No.");
    end;

    local procedure VerifyGenJnlLine(GenJnlLine: Record "Gen. Journal Line"; CheckLedgerEntry: Record "Check Ledger Entry")
    begin
        Assert.AreEqual(
          -CheckLedgerEntry.Amount, GenJnlLine.Amount,
          StrSubstNo(IncorrectFieldValueErr, GenJnlLine.Amount));
        Assert.AreEqual(
          CheckLedgerEntry."Bal. Account Type", GenJnlLine."Account Type",
          StrSubstNo(IncorrectFieldValueErr, GenJnlLine."Account Type"));
    end;

    local procedure VerifyGenJnlLinePaymentCode(GenJnlTemplateName: Code[10]; GenJnlBatchName: Code[10]; PaymentCode: Text)
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.SetRange("Journal Template Name", GenJnlTemplateName);
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatchName);
        GenJnlLine.FindFirst();
        Assert.AreEqual(PaymentCode, GenJnlLine."Payment Code", StrSubstNo(PaymentCodeErr, GenJnlLine.TableCaption));
    end;

    local procedure VerifyPostedPaymentCode(DocNo: Code[20]; PaymentCode: Text)
    var
        GenJnlLineArchive: Record "Gen. Journal Line Archive";
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        GenJnlLineArchive.SetRange("Document No.", DocNo);
        GenJnlLineArchive.FindFirst();
        Assert.AreEqual(
          PaymentCode, GenJnlLineArchive."Payment Code",
          StrSubstNo(PaymentCodeErr, GenJnlLineArchive.TableCaption()));

        CheckLedgerEntry.SetRange("Document No.", DocNo);
        CheckLedgerEntry.FindFirst();
        Assert.AreEqual(
          PaymentCode, CheckLedgerEntry."Payment Code",
          StrSubstNo(PaymentCodeErr, CheckLedgerEntry.TableCaption()));
    end;

    local procedure TestIfCheckLedgEntryIsCreated(BankAccountNo: Code[20])
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        BankAccountLedgerEntry.Init();
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.FindLast();
        CheckLedgerEntry.Init();
        CheckLedgerEntry.SetRange("Bank Account Ledger Entry No.", BankAccountLedgerEntry."Entry No.");
        Assert.RecordIsNotEmpty(CheckLedgerEntry);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure BankPaymentOrderHandler(var BankPaymentOrder: TestPage "Bank Payment Order")
    var
        INN: Variant;
    begin
        LibraryVariableStorage.Dequeue(INN);
        BankPaymentOrder.INN.AssertEquals(INN);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReportCopyPayDocumentHandler(var CopyPayDocument: TestRequestPage "Copy Pay Document")
    var
        DocumentType: Variant;
        EntryNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentType);
        LibraryVariableStorage.Dequeue(EntryNo);
        CopyPayDocument.DocType.SetValue(DocumentType); // Document Type
        CopyPayDocument.EntryNo.SetValue(EntryNo);  // Entry No.
        CopyPayDocument.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure GeneralJournalPageHandler(var GeneralJournal: TestPage "General Journal")
    begin
        GeneralJournal.Close();
    end;
}

