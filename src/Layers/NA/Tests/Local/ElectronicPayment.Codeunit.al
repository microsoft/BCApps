codeunit 141037 "Electronic Payment"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Electronic Payment]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        AmountErr: Label '%1 must be %2 in %3.';
        WrongValueErr: Label 'Wrong value in %1 field %2.';

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryWithForeignExchangeOnPaymentJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify G/L Entry value after posting Gen. Journal Line using Foreign Exchange related fields.

        // Setup: Create Payment Journal Line and update Foreign Exchange related fields.
        Initialize();
        CreatePaymentJournal(GenJournalLine);
        UpdatePaymentJournalForeignExchange(GenJournalLine);

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify G/L Entry value after posting Gen. Journal Line using Foreign Exchange related fields.
        VerifyGLEntryAmount(GenJournalLine)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryWithGatewayAndQualifierOnPaymentJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify G/L Entry value after posting Gen. Journal Line using Gateway and Qualifier related fields.

        // Setup: Create Payment Journal Line and update Gateway and Qualifier related fields.
        Initialize();
        CreatePaymentJournal(GenJournalLine);
        UpdatePaymentJournalGatewayAndQualifier(GenJournalLine);

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify G/L Entry value after posting Gen. Journal Line using Gateway and Qualifier related fields.
        VerifyGLEntryAmount(GenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryElectronicPaymentSalesCreditMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Verify G/L Entry after apply and post Sales Credit Memo with Electronic Payment using values for Foreign Exchange, Gateway and Qualifier related fields.

        // Setup: Create and Post Sales Credit Memo.
        Initialize();
        CreateSalesCreditMemo(SalesLine);
        DocumentNo := PostSalesCreditMemo(SalesLine."Document No.");

        // Exercise.
        CreateAndPostElectronicPaymentLine(GenJournalLine, DocumentNo, SalesLine."Sell-to Customer No.", SalesLine.Amount);

        // Verify: Verify G/L Entry after apply and post Sales Credit Memo using Electronic Payment.
        VerifyGLEntryAmount(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentRequestPageHandler,MessageHandler,ConfirmHandlerTRUE')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentForInvoice()
    var
        BankAccount: Record "Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // Verify Vendor balance after post payment using Suggest Vendor Payment.

        // Setup: Create Vendor, Post Purchase Invoice.
        Initialize();
        LibraryERM.CreateBankAccount(BankAccount);
        CreateAndPostPurchaseInvoice(PurchaseLine);
        CreateAndPostPurchaseInvoice(PurchaseLine2);
        CreateGeneralJournalBatchWithTemplate(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);

        // Run multiple times suggest vendor payment for different vendors.
        PaymentJournal.OpenEdit();
        SuggestVendorPayment(PaymentJournal, GenJournalBatch.Name, PurchaseLine."Buy-from Vendor No.", BankAccount."No.");
        SuggestVendorPayment(PaymentJournal, GenJournalBatch.Name, PurchaseLine2."Buy-from Vendor No.", BankAccount."No.");

        // Exercise.
        PaymentJournal.Post.Invoke();
        PaymentJournal.Close();

        // Verify: Verify Vendor balance after post payment.
        VerifyVendorBalance(PurchaseLine."Buy-from Vendor No.");
        VerifyVendorBalance(PurchaseLine2."Buy-from Vendor No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingPaymentJournalWithComputerCheckAndNoSeries()
    var
        BankAccount: Record "Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        PurchaseLine: Record "Purchase Line";
        GenJnlLine: Record "Gen. Journal Line";
        NoSeriesLine: Record "No. Series Line";
        OldLastNoUsed: Code[10];
    begin
        // Verify that GenJnlLine Posting with Computer Check and No Series with default parameters
        // does not generate an error and does not update Last No. Used field in No Series Line

        // Setup
        Initialize();
        CreateAndPostPurchaseInvoice(PurchaseLine);
        CreateNoSeriesWithAllFalse(NoSeriesLine);
        OldLastNoUsed := NoSeriesLine."Last No. Used";
        CreateGeneralJournalBatchWithTemplate(GenJournalBatch);
        LibraryERM.CreateBankAccount(BankAccount);
        UpdateGenJnlBatch(GenJournalBatch, BankAccount."No.", NoSeriesLine."Series Code");

        // Create-Print-Post GenJnlLine with Computer Check
        LibraryERM.CreateGeneralJnlLine(
          GenJnlLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, PurchaseLine."Buy-from Vendor No.", LibraryRandom.RandDec(1000, 2));
        EmulateCheckPrinting(GenJnlLine, BankAccount);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // Verify
        NoSeriesLine.Find();
        Assert.AreEqual(OldLastNoUsed, NoSeriesLine."Last No. Used",
          StrSubstNo(WrongValueErr, NoSeriesLine.TableCaption(), NoSeriesLine.FieldCaption("Last No. Used")));
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LibraryERMCountryData.CreateVATData();
    end;

    local procedure CreateAndPostElectronicPaymentLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20]; AccountNo: Code[20]; Amount: Decimal)
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        CreateGeneralJournalLine(GenJournalLine, AccountNo, Amount);
        UpdatePaymentJournalGatewayAndQualifier(GenJournalLine);
        UpdatePaymentJournalForeignExchange(GenJournalLine);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Electronic Payment");
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::"Credit Memo");
        GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);
        GenJournalLine.Validate("Check Exported", true);  // Validating Check Exported to avoid the mannual setup for Electronic payment.
        GenJournalLine.Validate("Check Transmitted", true);  // Validating Check Transmitted to avoid the mannual setup for Electronic payment.
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostPurchaseInvoice(var PurchaseLine: Record "Purchase Line"): Code[20]
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseLine."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandInt(10));  // Using Random value for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGeneralJournalBatchWithTemplate(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Refund,
          GenJournalLine."Account Type"::Customer, AccountNo, Amount);
    end;

    local procedure CreateSalesCreditMemo(var SalesLine: Record "Sales Line")
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesLine."Document Type"::"Credit Memo", Customer."No.");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandInt(10));  // Using Random value for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));  // Using Random value for Unit Price.
        SalesLine.Modify(true);
    end;

    local procedure CreatePaymentJournal(var GenJournalLine: Record "Gen. Journal Line")
    var
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGeneralJournalBatchWithTemplate(GenJournalBatch);
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, Customer."No.", -LibraryRandom.RandInt(10));
        GenJournalLine.Validate("Document No.", GenJournalLine."Journal Batch Name" + Format(GenJournalLine."Line No."));
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGeneralJournalBatchWithTemplate(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure PostSalesCreditMemo(DocumentNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.Get(SalesLine."Document Type"::"Credit Memo", DocumentNo);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure SuggestVendorPayment(var PaymentJournal: TestPage "Payment Journal"; JournalBatchName: Code[10]; VendorNo: Code[20]; BankAccountNo: Code[20])
    begin
        Commit();  // Commit required for open Payment Journal.
        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorage.Enqueue(BankAccountNo);
        PaymentJournal.CurrentJnlBatchName.SetValue(JournalBatchName);
        PaymentJournal.SuggestVendorPayments.Invoke();  // Opens handler - SuggestVendorPaymentRequestPageHandler.
    end;

    local procedure UpdatePaymentJournalForeignExchange(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.Validate("Foreign Exchange Indicator", LibraryRandom.RandIntInRange(1, 3));
        GenJournalLine.Validate("Foreign Exchange Ref.Indicator", LibraryRandom.RandIntInRange(1, 3));
        GenJournalLine.Validate("Foreign Exchange Reference", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);
    end;

    local procedure UpdatePaymentJournalGatewayAndQualifier(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.Validate("Origin. DFI ID Qualifier", LibraryRandom.RandIntInRange(1, 3));
        GenJournalLine.Validate("Receiv. DFI ID Qualifier", LibraryRandom.RandIntInRange(1, 3));
        GenJournalLine.Validate("Gateway Operator OFAC Scr.Inc", LibraryRandom.RandIntInRange(1, 2));
        GenJournalLine.Validate("Secondary OFAC Scr.Indicator", LibraryRandom.RandIntInRange(1, 2));
        GenJournalLine.Validate("Transaction Code", Format(LibraryRandom.RandInt(10)));  // Transaction Code has code type of Length 3.
        GenJournalLine.Modify(true);
    end;

    local procedure CreateNoSeriesWithAllFalse(var NoSeriesLine: Record "No. Series Line")
    var
        NoSeries: Record "No. Series";
        NoSeriesCodeunit: Codeunit "No. Series";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, false, false, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');
        NoSeriesCodeunit.GetNextNo(NoSeries.Code);
        NoSeriesLine.Find();
    end;

    local procedure UpdateGenJnlBatch(var GenJnlBatch: Record "Gen. Journal Batch"; BankAccountNo: Code[20]; NoSeriesCode: Code[20])
    begin
        GenJnlBatch.Validate("Bal. Account Type", GenJnlBatch."Bal. Account Type"::"Bank Account");
        GenJnlBatch.Validate("Bal. Account No.", BankAccountNo);
        GenJnlBatch.Validate("No. Series", NoSeriesCode);
        GenJnlBatch.Modify(true);
    end;

    local procedure EmulateCheckPrinting(var GenJnlLine: Record "Gen. Journal Line"; var BankAccount: Record "Bank Account") CheckNo: Code[20]
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
        CheckMgt: Codeunit CheckManagement;
    begin
        CheckNo := Format(LibraryRandom.RandInt(10));

        CheckLedgerEntry.Init();
        CheckLedgerEntry."Bank Account No." := BankAccount."No.";
        CheckLedgerEntry."Posting Date" := GenJnlLine."Posting Date";
        CheckLedgerEntry."Document No." := CheckNo;
        CheckLedgerEntry."Bank Payment Type" := CheckLedgerEntry."Bank Payment Type"::"Computer Check";
        CheckLedgerEntry."Entry Status" := CheckLedgerEntry."Entry Status"::"Test Print";
        CheckLedgerEntry."Check Date" := CheckLedgerEntry."Posting Date";
        CheckLedgerEntry."Check No." := CheckNo;
        CheckMgt.InsertCheck(CheckLedgerEntry, GenJnlLine.RecordId);

        BankAccount."Last Check No." := CheckNo;
        BankAccount.Modify();

        GenJnlLine."Document No." := CheckNo;
        GenJnlLine."Bank Payment Type" := GenJnlLine."Bank Payment Type"::"Computer Check";
        GenJnlLine."Check Printed" := true;
        GenJnlLine.Modify();
    end;

    local procedure VerifyGLEntryAmount(GenJournalLine: Record "Gen. Journal Line")
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", GenJournalLine."Document No.");
        GLEntry.SetRange("Bal. Account No.", GenJournalLine."Bal. Account No.");
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          GenJournalLine.Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, GLEntry.FieldCaption(Amount), GLEntry.Amount, GLEntry.TableCaption()));
    end;

    local procedure VerifyVendorBalance(VendorNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        Vendor.CalcFields("Balance (LCY)");
        Vendor.TestField("Balance (LCY)", 0);  // After post suggest vendor payments balance becomes zero.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentRequestPageHandler(var SuggestVendorPayments: TestRequestPage "Suggest Vendor Payments")
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccountNo: Variant;
        VendorNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendorNo);
        LibraryVariableStorage.Dequeue(BankAccountNo);
        SuggestVendorPayments.LastPaymentDate.SetValue(CalcDate(Format(LibraryRandom.RandInt(3)) + 'M', WorkDate()));  // Using Random for Months.
        SuggestVendorPayments.SummarizePerVendor.SetValue(true);
        SuggestVendorPayments.StartingDocumentNo.SetValue(LibraryRandom.RandInt(10));
        SuggestVendorPayments.BalAccountType.SetValue(GenJournalLine."Bal. Account Type"::"Bank Account");
        SuggestVendorPayments.BalAccountNo.SetValue(BankAccountNo);
        SuggestVendorPayments.Vendor.SetFilter("No.", VendorNo);
        SuggestVendorPayments.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTRUE(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

