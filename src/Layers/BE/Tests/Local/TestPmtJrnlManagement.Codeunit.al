codeunit 144017 "Test PmtJrnlManagement"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryPaymentJournalBE: Codeunit "Library - Payment Journal BE";
        LibraryUtility: Codeunit "Library - Utility";
        BlankFieldInPmtJnlErr: Label 'The %1 field cannot be blank in payment journal line number %2.';

    [Test]
    [Scope('OnPrem')]
    procedure PmtJnlMgtTemplateSelection1()
    var
        PaymentJnlTemplate: Record "Payment Journal Template";
        PaymentJournalLine: Record "Payment Journal Line";
        PmtJrnlManagement: Codeunit PmtJrnlManagement;
        JnlSelected: Boolean;
    begin
        // Setup
        PaymentJnlTemplate.DeleteAll();  // force insertion of new default.

        // Exercise
        PmtJrnlManagement.TemplateSelection(PaymentJournalLine, JnlSelected);

        // Verify
        Assert.IsTrue(JnlSelected, '');
        Assert.AreEqual(1, PaymentJnlTemplate.Count, '');
        PaymentJnlTemplate.FindFirst();
        PaymentJournalLine.FilterGroup(2);
        Assert.AreEqual(PaymentJnlTemplate.Name, PaymentJournalLine.GetRangeMin("Journal Template Name"), '');
        PaymentJournalLine.FilterGroup(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtJnlMgtTemplateSelection2()
    var
        PaymentJnlTemplate: Record "Payment Journal Template";
        PaymentJournalLine: Record "Payment Journal Line";
        PmtJrnlManagement: Codeunit PmtJrnlManagement;
        JnlSelected: Boolean;
    begin
        // Setup
        PaymentJnlTemplate.DeleteAll();
        LibraryPaymentJournalBE.CreateTemplate(PaymentJnlTemplate);

        // Exercise
        PmtJrnlManagement.TemplateSelection(PaymentJournalLine, JnlSelected);

        // Verify
        Assert.IsTrue(JnlSelected, '');
        PaymentJournalLine.FilterGroup(2);
        Assert.AreEqual(PaymentJnlTemplate.Name, PaymentJournalLine.GetRangeMin("Journal Template Name"), '');
        PaymentJournalLine.FilterGroup(0);
    end;

    [Test]
    [HandlerFunctions('EBPaymentJournalTemplatesHandler')]
    [Scope('OnPrem')]
    procedure PmtJnlMgtTemplateSelection3()
    var
        PaymentJnlTemplate: Record "Payment Journal Template";
        PaymentJournalLine: Record "Payment Journal Line";
        PmtJrnlManagement: Codeunit PmtJrnlManagement;
        JnlSelected: Boolean;
    begin
        // Setup
        PaymentJnlTemplate.DeleteAll();
        LibraryPaymentJournalBE.CreateTemplate(PaymentJnlTemplate);
        LibraryPaymentJournalBE.CreateTemplate(PaymentJnlTemplate);
        Commit(); // necessary because the TemplateSelection will run a page.

        // Exercise
        PmtJrnlManagement.TemplateSelection(PaymentJournalLine, JnlSelected);

        // Verify
        PaymentJnlTemplate.FindLast();
        Assert.IsTrue(JnlSelected, '');
        PaymentJournalLine.FilterGroup(2);
        Assert.AreEqual(PaymentJnlTemplate.Name, PaymentJournalLine.GetRangeMin("Journal Template Name"), '');
        PaymentJournalLine.FilterGroup(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtJnlMgtOpenJournal()
    var
        PaymentJnlTemplate: Record "Payment Journal Template";
        PaymJournalBatch: Record "Paym. Journal Batch";
        PaymentJnlLine: Record "Payment Journal Line";
        PmtJrnlManagement: Codeunit PmtJrnlManagement;
        CurrentJnlBatchName: Code[10];
    begin
        // Setup
        LibraryPaymentJournalBE.CreateTemplate(PaymentJnlTemplate);
        PaymentJnlLine.SetRange("Journal Template Name", PaymentJnlTemplate.Name);
        CurrentJnlBatchName := CopyStr(CreateGuid(), 1, MaxStrLen(CurrentJnlBatchName));

        // Exercise
        PmtJrnlManagement.OpenJournal(CurrentJnlBatchName, PaymentJnlLine);

        // Validate
        PaymJournalBatch.SetRange("Journal Template Name", PaymentJnlTemplate.Name);
        Assert.AreEqual(PaymentJnlTemplate.Name, PaymentJnlLine.GetRangeMin("Journal Template Name"), '');
        Assert.AreEqual(1, PaymJournalBatch.Count, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtJnlMgtOpenJnlBatch1()
    var
        PaymentJnlTemplate: Record "Payment Journal Template";
        PaymJournalBatch: Record "Paym. Journal Batch";
        PmtJrnlManagement: Codeunit PmtJrnlManagement;
    begin
        // Setup
        LibraryPaymentJournalBE.CreateTemplate(PaymentJnlTemplate);
        PaymJournalBatch.SetRange("Journal Template Name", PaymentJnlTemplate.Name);
        PaymentJnlTemplate.DeleteAll();

        // Exercise
        PmtJrnlManagement.OpenJnlBatch(PaymJournalBatch);

        // Validate
        Assert.AreEqual(0, PaymentJnlTemplate.Count, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtJnlMgtOpenJnlBatch2()
    var
        PaymentJnlTemplate: Record "Payment Journal Template";
        PaymJournalBatch: Record "Paym. Journal Batch";
        PmtJrnlManagement: Codeunit PmtJrnlManagement;
    begin
        // Setup
        LibraryPaymentJournalBE.CreateTemplate(PaymentJnlTemplate);
        PaymJournalBatch.FilterGroup(2);
        PaymJournalBatch.SetRange("Journal Template Name", PaymentJnlTemplate.Name);
        PaymJournalBatch.FilterGroup(0);
        PaymentJnlTemplate.DeleteAll();

        // Exercise
        PmtJrnlManagement.OpenJnlBatch(PaymJournalBatch);

        // Validate
        Assert.AreEqual(0, PaymentJnlTemplate.Count, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtJnlMgtOpenJnlBatch3()
    var
        PaymentJnlTemplate: Record "Payment Journal Template";
        PaymJournalBatch: Record "Paym. Journal Batch";
        PmtJrnlManagement: Codeunit PmtJrnlManagement;
    begin
        // Setup
        PaymentJnlTemplate.DeleteAll();
        PaymJournalBatch.DeleteAll();

        // Exercise
        PmtJrnlManagement.OpenJnlBatch(PaymJournalBatch);

        // Validate
        PaymentJnlTemplate.FindFirst();
        Assert.AreEqual(PaymentJnlTemplate.Name, PaymJournalBatch.GetRangeMin("Journal Template Name"), '');
    end;

    [Test]
    [HandlerFunctions('EBPaymentJournalHandler')]
    [Scope('OnPrem')]
    procedure PmtJnlMgtTemplateSelectionFromBatch()
    var
        PaymentJnlTemplate: Record "Payment Journal Template";
        PaymJournalBatch: Record "Paym. Journal Batch";
        PmtJrnlManagement: Codeunit PmtJrnlManagement;
    begin
        // Setup
        LibraryPaymentJournalBE.CreateTemplate(PaymentJnlTemplate);
        PaymJournalBatch.Init();
        PaymJournalBatch."Journal Template Name" := PaymentJnlTemplate.Name;
        PaymJournalBatch.Name := CopyStr(CreateGuid(), 1, MaxStrLen(PaymJournalBatch.Name));
        PaymJournalBatch.Insert();

        // Exercise
        PmtJrnlManagement.TemplateSelectionFromBatch(PaymJournalBatch);

        // Verify: PAGE::"EB Payment Journal" is opened
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtJnlMgtCheckName()
    var
        PaymentJnlTemplate: Record "Payment Journal Template";
        PaymJournalBatch: Record "Paym. Journal Batch";
        PaymentJnlLine: Record "Payment Journal Line";
        PmtJrnlManagement: Codeunit PmtJrnlManagement;
    begin
        // Setup
        LibraryPaymentJournalBE.CreateTemplate(PaymentJnlTemplate);
        LibraryPaymentJournalBE.CreateBatch(PaymentJnlTemplate, PaymJournalBatch);
        PaymentJnlLine.SetRange("Journal Template Name", PaymentJnlTemplate.Name);

        // Exercise
        PmtJrnlManagement.SetName(PaymJournalBatch.Name, PaymentJnlLine);

        // Verify
        PaymentJnlLine.FilterGroup(2);
        Assert.AreEqual(PaymJournalBatch.Name, PaymentJnlLine.GetRangeMin("Journal Batch Name"), '');
        PaymentJnlLine.FilterGroup(0);
        PmtJrnlManagement.CheckName(PaymJournalBatch.Name, PaymentJnlLine);
    end;

    [Test]
    [HandlerFunctions('EBPaymentJournalBatchesHandlerOK')]
    [Scope('OnPrem')]
    procedure PmtJnlMgtLookupNameOK()
    var
        PaymentJnlTemplate: Record "Payment Journal Template";
        PaymJournalBatch: Record "Paym. Journal Batch";
        PmtJrnlManagement: Codeunit PmtJrnlManagement;
        NewJnlBatchName: Text[10];
    begin
        // Setup
        LibraryPaymentJournalBE.CreateTemplate(PaymentJnlTemplate);
        LibraryPaymentJournalBE.CreateBatch(PaymentJnlTemplate, PaymJournalBatch);
        LibraryPaymentJournalBE.CreateBatch(PaymentJnlTemplate, PaymJournalBatch);

        // Exercise
        PmtJrnlManagement.LookupName(PaymentJnlTemplate.Name, PaymJournalBatch.Name, NewJnlBatchName);

        // Verify
        PaymJournalBatch.FindLast();
        Assert.AreEqual(PaymJournalBatch.Name, NewJnlBatchName, '');
    end;

    [Test]
    [HandlerFunctions('EBPaymentJournalBatchesHandlerCancel')]
    [Scope('OnPrem')]
    procedure PmtJnlMgtLookupNameCancel()
    var
        PaymentJnlTemplate: Record "Payment Journal Template";
        PaymJournalBatch: Record "Paym. Journal Batch";
        PmtJrnlManagement: Codeunit PmtJrnlManagement;
        NewJnlBatchName: Text[10];
    begin
        // Setup
        LibraryPaymentJournalBE.CreateTemplate(PaymentJnlTemplate);
        LibraryPaymentJournalBE.CreateBatch(PaymentJnlTemplate, PaymJournalBatch);

        // Exercise
        PmtJrnlManagement.LookupName(PaymentJnlTemplate.Name, PaymJournalBatch.Name, NewJnlBatchName);

        // Verify
        Assert.AreEqual('', NewJnlBatchName, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtJnlMgtGetAccountCustAndBank()
    var
        Cust: Record Customer;
        BankAccount: Record "Bank Account";
        PaymentJnlLine: Record "Payment Journal Line";
        PmtJrnlManagement: Codeunit PmtJrnlManagement;
        AccName: Text[100];
        BankAccName: Text[100];
    begin
        // Setup
        Cust.Init();
        Cust."No." := CopyStr(CreateGuid(), 1, MaxStrLen(Cust."No."));
        Cust.Name := CopyStr(CreateGuid(), 1, MaxStrLen(Cust.Name));
        Cust.Insert();
        BankAccount.Init();
        BankAccount."No." := CopyStr(CreateGuid(), 1, MaxStrLen(BankAccount."No."));
        BankAccount.Name := CopyStr(CreateGuid(), 1, MaxStrLen(BankAccount.Name));
        BankAccount.Insert();
        PaymentJnlLine.Init();
        PaymentJnlLine."Account Type" := PaymentJnlLine."Account Type"::Customer;
        PaymentJnlLine."Account No." := Cust."No.";
        PaymentJnlLine."Bank Account" := BankAccount."No.";
        // Exercise
        PmtJrnlManagement.GetAccount(PaymentJnlLine, AccName, BankAccName);

        // Verify
        Assert.AreEqual(Cust.Name, AccName, '');
        Assert.AreEqual(BankAccount.Name, BankAccName, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtJnlMgtGetAccountVendAndNoBank()
    var
        Vend: Record Vendor;
        PaymentJnlLine: Record "Payment Journal Line";
        PmtJrnlManagement: Codeunit PmtJrnlManagement;
        AccName: Text[100];
        BankAccName: Text[100];
    begin
        // Setup
        Vend.Init();
        Vend."No." := CopyStr(CreateGuid(), 1, MaxStrLen(Vend."No."));
        Vend.Name := CopyStr(CreateGuid(), 1, MaxStrLen(Vend.Name));
        Vend.Insert();
        PaymentJnlLine.Init();
        PaymentJnlLine."Account Type" := PaymentJnlLine."Account Type"::Vendor;
        PaymentJnlLine."Account No." := Vend."No.";

        // Exercise
        PmtJrnlManagement.GetAccount(PaymentJnlLine, AccName, BankAccName);

        // Verify
        Assert.AreEqual(Vend.Name, AccName, '');
        Assert.AreEqual('', BankAccName, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtJnlMgtCalculateTotals1()
    var
        PaymentJnlLine: Record "Payment Journal Line";
        LastPaymentJnlLine: Record "Payment Journal Line";
        PmtJrnlManagement: Codeunit PmtJrnlManagement;
        Balance: Decimal;
        TotalAmount: Decimal;
        ShowAmount: Boolean;
        ShowTotalAmount: Boolean;
    begin
        PaymentJnlLine.Init();
        PaymentJnlLine."Journal Template Name" := CopyStr(CreateGuid(), 1, MaxStrLen(PaymentJnlLine."Journal Template Name"));
        PaymentJnlLine.SetRange("Journal Template Name", PaymentJnlLine."Journal Template Name");
        PaymentJnlLine."Amount (LCY)" := 42;
        LastPaymentJnlLine.Copy(PaymentJnlLine);

        // Exercise
        PmtJrnlManagement.CalculateTotals(PaymentJnlLine, LastPaymentJnlLine, Balance, TotalAmount, ShowAmount, ShowTotalAmount);

        // Validate
        Assert.AreEqual(0, Balance, '');
        Assert.AreEqual(42, TotalAmount, '');
        Assert.IsFalse(ShowAmount, '');
        Assert.IsTrue(ShowTotalAmount, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtJnlMgtCalculateTotals2()
    var
        PaymentJnlLine: Record "Payment Journal Line";
        LastPaymentJnlLine: Record "Payment Journal Line";
        PmtJrnlManagement: Codeunit PmtJrnlManagement;
        Balance: Decimal;
        TotalAmount: Decimal;
        ShowAmount: Boolean;
        ShowTotalAmount: Boolean;
    begin
        PaymentJnlLine.Init();
        PaymentJnlLine."Journal Template Name" := CopyStr(CreateGuid(), 1, MaxStrLen(PaymentJnlLine."Journal Template Name"));
        PaymentJnlLine.SetRange("Journal Template Name", PaymentJnlLine."Journal Template Name");
        PaymentJnlLine."Amount (LCY)" := 42;
        PaymentJnlLine."Account Type" := PaymentJnlLine."Account Type"::Customer;
        PaymentJnlLine."Line No." := 10000;
        PaymentJnlLine.Insert();
        PaymentJnlLine."Account No." := CopyStr(CreateGuid(), 1, MaxStrLen(PaymentJnlLine."Account No."));
        PaymentJnlLine."Line No." += 10000;
        PaymentJnlLine.Insert();
        PaymentJnlLine."Line No." += 10000;
        PaymentJnlLine.Insert();
        LastPaymentJnlLine.Copy(PaymentJnlLine);

        // Exercise
        PmtJrnlManagement.CalculateTotals(PaymentJnlLine, LastPaymentJnlLine, Balance, TotalAmount, ShowAmount, ShowTotalAmount);

        // Validate
        Assert.AreEqual(2 * 42, Balance, '');
        Assert.AreEqual(3 * 42, TotalAmount, '');
        Assert.IsTrue(ShowAmount, '');
        Assert.IsTrue(ShowTotalAmount, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtJnlMgtCalculateTotals3()
    var
        PaymentJnlLine: Record "Payment Journal Line";
        LastPaymentJnlLine: Record "Payment Journal Line";
        PmtJrnlManagement: Codeunit PmtJrnlManagement;
        Balance: Decimal;
        TotalAmount: Decimal;
        ShowAmount: Boolean;
        ShowTotalAmount: Boolean;
    begin
        PaymentJnlLine.Init();
        PaymentJnlLine."Journal Template Name" := CopyStr(CreateGuid(), 1, MaxStrLen(PaymentJnlLine."Journal Template Name"));
        PaymentJnlLine.SetRange("Journal Template Name", PaymentJnlLine."Journal Template Name");
        PaymentJnlLine."Amount (LCY)" := 42;
        PaymentJnlLine."Account Type" := PaymentJnlLine."Account Type"::Customer;
        PaymentJnlLine."Line No." := 10000;
        PaymentJnlLine.Insert();
        LastPaymentJnlLine.Copy(PaymentJnlLine);

        // Exercise
        PmtJrnlManagement.CalculateTotals(PaymentJnlLine, LastPaymentJnlLine, Balance, TotalAmount, ShowAmount, ShowTotalAmount);

        // Validate
        Assert.AreEqual(0, Balance, '');
        Assert.AreEqual(42, TotalAmount, '');
        Assert.IsFalse(ShowAmount, '');
        Assert.IsTrue(ShowTotalAmount, '');
    end;

    [Test]
    [HandlerFunctions('GLAccCardHandler')]
    [Scope('OnPrem')]
    procedure PmtJnlMgtShowCardGLAcc()
    var
        PaymentJnlLine: Record "Payment Journal Line";
        PmtJrnlManagement: Codeunit PmtJrnlManagement;
    begin
        // Setup
        PaymentJnlLine.Init();
        PaymentJnlLine."Account Type" := 0;
        PaymentJnlLine."Account No." := CopyStr(CreateGuid(), 1, MaxStrLen(PaymentJnlLine."Account No."));

        // Execise and validate (opens page)
        PmtJrnlManagement.ShowCard(PaymentJnlLine);
    end;

    [Test]
    [HandlerFunctions('CustCardHandler')]
    [Scope('OnPrem')]
    procedure PmtJnlMgtShowCardCust()
    var
        PaymentJnlLine: Record "Payment Journal Line";
        PmtJrnlManagement: Codeunit PmtJrnlManagement;
    begin
        // Setup
        PaymentJnlLine.Init();
        PaymentJnlLine."Account Type" := PaymentJnlLine."Account Type"::Customer;
        PaymentJnlLine."Account No." := LibrarySales.CreateCustomerNo();

        // Execise and validate (opens page)
        PmtJrnlManagement.ShowCard(PaymentJnlLine);
    end;

    [Test]
    [HandlerFunctions('VendCardHandler')]
    [Scope('OnPrem')]
    procedure PmtJnlMgtShowCardVend()
    var
        PaymentJnlLine: Record "Payment Journal Line";
        PmtJrnlManagement: Codeunit PmtJrnlManagement;
    begin
        // Setup
        PaymentJnlLine.Init();
        PaymentJnlLine."Account Type" := PaymentJnlLine."Account Type"::Vendor;
        PaymentJnlLine."Account No." := LibraryPurchase.CreateVendorNo();

        // Execise and validate (opens page)
        PmtJrnlManagement.ShowCard(PaymentJnlLine);
    end;

    [Test]
    [HandlerFunctions('CustLedgEntriesHandler')]
    [Scope('OnPrem')]
    procedure PmtJnlMgtShowEntriesCust()
    var
        PaymentJnlLine: Record "Payment Journal Line";
        PmtJrnlManagement: Codeunit PmtJrnlManagement;
    begin
        // Setup
        PaymentJnlLine.Init();
        PaymentJnlLine."Account Type" := PaymentJnlLine."Account Type"::Customer;
        PaymentJnlLine."Account No." := CopyStr(CreateGuid(), 1, MaxStrLen(PaymentJnlLine."Account No."));

        // Execise and validate (opens page)
        PmtJrnlManagement.ShowEntries(PaymentJnlLine);
    end;

    [Test]
    [HandlerFunctions('VendLedgEntriesHandler')]
    [Scope('OnPrem')]
    procedure PmtJnlMgtShowEntriesVend()
    var
        PaymentJnlLine: Record "Payment Journal Line";
        PmtJrnlManagement: Codeunit PmtJrnlManagement;
    begin
        // Setup
        PaymentJnlLine.Init();
        PaymentJnlLine."Account Type" := PaymentJnlLine."Account Type"::Vendor;
        PaymentJnlLine."Account No." := CopyStr(CreateGuid(), 1, MaxStrLen(PaymentJnlLine."Account No."));

        // Execise and validate (opens page)
        PmtJrnlManagement.ShowEntries(PaymentJnlLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtJnlMgConvertToDigit()
    var
        PmtJrnlManagement: Codeunit PmtJrnlManagement;
    begin
        // Validate
        Assert.AreEqual('28001', PmtJrnlManagement.ConvertToDigit('  DK2800 Lyngby 1  ', 10), '');
        Assert.AreEqual('', PmtJrnlManagement.ConvertToDigit('Lyngby C', 10), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtJnlMgDecimalNumeralZeroFormat()
    var
        PmtJrnlManagement: Codeunit PmtJrnlManagement;
    begin
        // Validate
        Assert.AreEqual('0000012345', PmtJrnlManagement.DecimalNumeralZeroFormat(12345.678, 10), '');
        asserterror Assert.AreEqual('0000012345', PmtJrnlManagement.DecimalNumeralZeroFormat(12345.678, 3), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtJnlMgtPrintTestReport()
    var
        PaymentJnlTemplate: Record "Payment Journal Template";
        PaymJournalBatch: Record "Paym. Journal Batch";
        PmtJrnlManagement: Codeunit PmtJrnlManagement;
    begin
        // Setup
        LibraryPaymentJournalBE.CreateTemplate(PaymentJnlTemplate);
        LibraryPaymentJournalBE.CreateBatch(PaymentJnlTemplate, PaymJournalBatch);
        PaymentJnlTemplate."Test Report ID" := 2000999; // Non-existing report.
        PaymentJnlTemplate.Modify();

        // Exercise
        // No test report exists for payment jnl. batch. so instead we verify that it fails.
        asserterror PmtJrnlManagement.PrintTestReport(PaymJournalBatch);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtJnlMgtMod97Test()
    var
        PmtJrnlManagement: Codeunit PmtJrnlManagement;
    begin
        // Verify
        Assert.IsFalse(PmtJrnlManagement.Mod97Test('01234567'), 'Too short.');
        Assert.IsFalse(PmtJrnlManagement.Mod97Test('01234567890123'), 'Too long.');
        Assert.IsTrue(PmtJrnlManagement.Mod97Test('000000106797'), 'Wrong check number.');
        Assert.IsTrue(PmtJrnlManagement.Mod97Test('000000106801'), 'Wrong check number.');
        Assert.IsFalse(PmtJrnlManagement.Mod97Test('000000106802'), 'Unexpected correct check number.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PmtJnlMgtModifyDiscDueDateCustCurr()
    var
        PaymentJnlLine: Record "Payment Journal Line";
        Customer: Record Customer;
        CustLedgEntry: Record "Cust. Ledger Entry";
        PmtJrnlManagement: Codeunit PmtJrnlManagement;
        CurrencyCode: Code[10];
    begin
        // Setup
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(19900101D, 100, 100);
        LibrarySales.CreateCustomer(Customer);
        LibraryPaymentJournalBE.CreateCustLedgEntryInvoice(Customer, CustLedgEntry, CurrencyCode);
        PaymentJnlLine.Init();
        PaymentJnlLine."Account Type" := PaymentJnlLine."Account Type"::Customer;
        PaymentJnlLine."Account No." := Customer."No.";
        PaymentJnlLine."Applies-to Doc. Type" := CustLedgEntry."Document Type"::Invoice;
        PaymentJnlLine."Applies-to Doc. No." := Customer."No.";
        PaymentJnlLine."Pmt. Disc. Possible" := 0;
        PaymentJnlLine."Posting Date" := WorkDate() + 2;
        PaymentJnlLine."Currency Code" := '';

        // Exercise
        PmtJrnlManagement.ModifyPmtDiscDueDate(PaymentJnlLine);

        // Validate
        CustLedgEntry.Find();
        Assert.AreEqual(WorkDate() + 2, CustLedgEntry."Pmt. Discount Date", '');
        Assert.AreEqual(0, CustLedgEntry."Remaining Pmt. Disc. Possible", '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PmtJnlMgtModifyDiscDueDateCustNoCurr()
    var
        PaymentJnlLine: Record "Payment Journal Line";
        Customer: Record Customer;
        CustLedgEntry: Record "Cust. Ledger Entry";
        PmtJrnlManagement: Codeunit PmtJrnlManagement;
    begin
        // Setup
        LibrarySales.CreateCustomer(Customer);
        LibraryPaymentJournalBE.CreateCustLedgEntryInvoice(Customer, CustLedgEntry, '');
        PaymentJnlLine.Init();
        PaymentJnlLine."Account Type" := PaymentJnlLine."Account Type"::Customer;
        PaymentJnlLine."Account No." := Customer."No.";
        PaymentJnlLine."Applies-to Doc. Type" := CustLedgEntry."Document Type"::Invoice;
        PaymentJnlLine."Applies-to Doc. No." := Customer."No.";
        PaymentJnlLine."Pmt. Disc. Possible" := 0;
        PaymentJnlLine."Posting Date" := WorkDate() + 2;
        PaymentJnlLine."Currency Code" := '';

        // Exercise
        PmtJrnlManagement.ModifyPmtDiscDueDate(PaymentJnlLine);

        // Validate
        CustLedgEntry.Find();
        Assert.AreEqual(WorkDate() + 2, CustLedgEntry."Pmt. Discount Date", '');
        Assert.AreEqual(0, CustLedgEntry."Remaining Pmt. Disc. Possible", '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PmtJnlMgtModifyDiscDueDateVendCurr()
    var
        PaymentJnlLine: Record "Payment Journal Line";
        Vendor: Record Vendor;
        VendLedgEntry: Record "Vendor Ledger Entry";
        PmtJrnlManagement: Codeunit PmtJrnlManagement;
        CurrencyCode: Code[10];
    begin
        // Setup
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(19900101D, 100, 100);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPaymentJournalBE.CreateVendLedgEntryInvoice(Vendor, VendLedgEntry, CurrencyCode);
        PaymentJnlLine.Init();
        PaymentJnlLine."Account Type" := PaymentJnlLine."Account Type"::Vendor;
        PaymentJnlLine."Account No." := Vendor."No.";
        PaymentJnlLine."Applies-to Doc. Type" := VendLedgEntry."Document Type"::Invoice;
        PaymentJnlLine."Applies-to Doc. No." := Vendor."No.";
        PaymentJnlLine."Pmt. Disc. Possible" := 0;
        PaymentJnlLine."Posting Date" := WorkDate() + 2;
        PaymentJnlLine."Currency Code" := '';

        // Exercise
        PmtJrnlManagement.ModifyPmtDiscDueDate(PaymentJnlLine);

        // Validate
        VendLedgEntry.Find();
        Assert.AreEqual(WorkDate() + 2, VendLedgEntry."Pmt. Discount Date", '');
        Assert.AreEqual(0, VendLedgEntry."Remaining Pmt. Disc. Possible", '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PmtJnlMgtModifyDiscDueDateVendNoCurr()
    var
        PaymentJnlLine: Record "Payment Journal Line";
        Vendor: Record Vendor;
        VendLedgEntry: Record "Vendor Ledger Entry";
        PmtJrnlManagement: Codeunit PmtJrnlManagement;
    begin
        // Setup
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPaymentJournalBE.CreateVendLedgEntryInvoice(Vendor, VendLedgEntry, '');
        PaymentJnlLine.Init();
        PaymentJnlLine."Account Type" := PaymentJnlLine."Account Type"::Vendor;
        PaymentJnlLine."Account No." := Vendor."No.";
        PaymentJnlLine."Applies-to Doc. Type" := VendLedgEntry."Document Type"::Invoice;
        PaymentJnlLine."Applies-to Doc. No." := Vendor."No.";
        PaymentJnlLine."Pmt. Disc. Possible" := 0;
        PaymentJnlLine."Posting Date" := WorkDate() + 2;
        PaymentJnlLine."Currency Code" := '';

        // Exercise
        PmtJrnlManagement.ModifyPmtDiscDueDate(PaymentJnlLine);

        // Validate
        VendLedgEntry.Find();
        Assert.AreEqual(WorkDate() + 2, VendLedgEntry."Pmt. Discount Date", '');
        Assert.AreEqual(0, VendLedgEntry."Remaining Pmt. Disc. Possible", '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PmtJnlMgtSetApplIDCust()
    var
        PaymentJnlLine: Record "Payment Journal Line";
        Customer: Record Customer;
        CustLedgEntry: Record "Cust. Ledger Entry";
        PmtJrnlManagement: Codeunit PmtJrnlManagement;
    begin
        // Setup
        LibrarySales.CreateCustomer(Customer);
        LibraryPaymentJournalBE.CreateCustLedgEntryInvoice(Customer, CustLedgEntry, '');
        PaymentJnlLine.Init();
        PaymentJnlLine."Account Type" := PaymentJnlLine."Account Type"::Customer;
        PaymentJnlLine."Account No." := Customer."No.";
        PaymentJnlLine."Applies-to Doc. Type" := CustLedgEntry."Document Type"::Invoice;
        PaymentJnlLine."Applies-to Doc. No." := Customer."No.";
        PaymentJnlLine."Applies-to ID" := Customer."No.";
        PaymentJnlLine."Ledger Entry No." := CustLedgEntry."Entry No.";
        PaymentJnlLine."Original Remaining Amount" := 0;

        // Exercise
        PmtJrnlManagement.SetApplID(PaymentJnlLine);

        // Validate
        CustLedgEntry.Find();
        Assert.AreEqual(-PaymentJnlLine."Original Remaining Amount", CustLedgEntry."Amount to Apply", '');
        Assert.AreEqual(PaymentJnlLine."Applies-to ID", CustLedgEntry."Applies-to ID", '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PmtJnlMgtSetApplIDVend()
    var
        PaymentJnlLine: Record "Payment Journal Line";
        Vendor: Record Vendor;
        VendLedgEntry: Record "Vendor Ledger Entry";
        PmtJrnlManagement: Codeunit PmtJrnlManagement;
    begin
        // Setup
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPaymentJournalBE.CreateVendLedgEntryInvoice(Vendor, VendLedgEntry, '');
        PaymentJnlLine.Init();
        PaymentJnlLine."Account Type" := PaymentJnlLine."Account Type"::Vendor;
        PaymentJnlLine."Account No." := Vendor."No.";
        PaymentJnlLine."Applies-to Doc. Type" := VendLedgEntry."Document Type"::Invoice;
        PaymentJnlLine."Applies-to Doc. No." := Vendor."No.";
        PaymentJnlLine."Applies-to ID" := Vendor."No.";
        PaymentJnlLine."Ledger Entry No." := VendLedgEntry."Entry No.";
        PaymentJnlLine."Original Remaining Amount" := 0;

        // Exercise
        PmtJrnlManagement.SetApplID(PaymentJnlLine);

        // Validate
        VendLedgEntry.Find();
        Assert.AreEqual(-PaymentJnlLine."Original Remaining Amount", VendLedgEntry."Amount to Apply", '');
        Assert.AreEqual(PaymentJnlLine."Applies-to ID", VendLedgEntry."Applies-to ID", '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckBeneficiaryForDomesticBankWithSWIFTCode()
    var
        PaymentJnlLine: Record "Payment Journal Line";
        CountryRegion: Record "Country/Region";
        CompanyInformation: Record "Company Information";
        CheckPaymJnlLine: Codeunit CheckPaymJnlLine;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 338364] A CheckBeneficiaryBankForSEPA function of the codeunit CheckPaymJnlLine passes for the domestic bank with SWIFT code specified

        LibraryERM.CreateCountryRegion(CountryRegion);
        CompanyInformation.Get();
        CompanyInformation.Validate("Country/Region Code", CountryRegion.Code);
        CompanyInformation.Modify(true);
        MockPmtJnlLineToCheckBeneficiary(
            PaymentJnlLine, CompanyInformation."Country/Region Code", LibraryUtility.GenerateGUID());
        CheckPaymJnlLine.CheckBeneficiaryBankForSEPA(PaymentJnlLine, false);
        CheckPaymJnlLine.ShowErrorLog(); // no page will be opened if no pages were recorded
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckBeneficiaryForDomesticBankWithoutSWIFTCode()
    var
        PaymentJnlLine: Record "Payment Journal Line";
        CountryRegion: Record "Country/Region";
        CompanyInformation: Record "Company Information";
        CheckPaymJnlLine: Codeunit CheckPaymJnlLine;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 338364] A CheckBeneficiaryBankForSEPA function of the codeunit CheckPaymJnlLine passes for the domestic bank without SWIFT code specified

        LibraryERM.CreateCountryRegion(CountryRegion);
        CompanyInformation.Get();
        CompanyInformation.Validate("Country/Region Code", CountryRegion.Code);
        CompanyInformation.Modify(true);
        MockPmtJnlLineToCheckBeneficiary(
            PaymentJnlLine, CompanyInformation."Country/Region Code", '');
        CheckPaymJnlLine.CheckBeneficiaryBankForSEPA(PaymentJnlLine, false);
        CheckPaymJnlLine.ShowErrorLog(); // no page will be opened if no pages were recorded
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckBeneficiaryForForeignBankWithSWIFTCode()
    var
        CountryRegion: Record "Country/Region";
        PaymentJnlLine: Record "Payment Journal Line";
        CheckPaymJnlLine: Codeunit CheckPaymJnlLine;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 338364] A CheckBeneficiaryBankForSEPA function of the codeunit CheckPaymJnlLine passes for the foreign bank without SWIFT code specified

        LibraryERM.CreateCountryRegion(CountryRegion);
        MockPmtJnlLineToCheckBeneficiary(PaymentJnlLine, CountryRegion.Code, LibraryUtility.GenerateGUID());
        CheckPaymJnlLine.CheckBeneficiaryBankForSEPA(PaymentJnlLine, false);
        CheckPaymJnlLine.ShowErrorLog(); // no page will be opened if no pages were recorded
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckBeneficiaryForForeignBankWithoutSWIFTCode()
    var
        CountryRegion: Record "Country/Region";
        PaymentJnlLine: Record "Payment Journal Line";
        ExportCheckErrorLogs: TestPage "Export Check Error Logs";
        CheckPaymJnlLine: Codeunit CheckPaymJnlLine;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 338364] A CheckBeneficiaryBankForSEPA function of the codeunit CheckPaymJnlLine passes for the foreign bank without SWIFT code specified

        LibraryERM.CreateCountryRegion(CountryRegion);
        MockPmtJnlLineToCheckBeneficiary(PaymentJnlLine, CountryRegion.Code, '');
        CheckPaymJnlLine.CheckBeneficiaryBankForSEPA(PaymentJnlLine, false);
        ExportCheckErrorLogs.Trap();
        asserterror CheckPaymJnlLine.ShowErrorLog();
        ExportCheckErrorLogs."Error Message".AssertEquals(
            StrSubstNo(BlankFieldInPmtJnlErr, PaymentJnlLine.FieldCaption("SWIFT Code"), 0));
        Assert.ExpectedError('');
    end;

    local procedure MockPmtJnlLineToCheckBeneficiary(var PaymentJnlLine: Record "Payment Journal Line"; CountryRegionCode: Code[10]; SWIFTCode: Code[20])
    begin
        PaymentJnlLine."Bank Account" := CreateBankAccountNoWithCountryRegionCode(CountryRegionCode);
        PaymentJnlLine."Bank Country/Region Code" := CountryRegionCode;
        PaymentJnlLine."Beneficiary Bank Account No." := LibraryUtility.GenerateGUID();
        PaymentJnlLine."SWIFT Code" := SWIFTCode;
    end;

    local procedure CreateBankAccountNoWithCountryRegionCode(CountryRegionCode: Code[10]): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount."Country/Region Code" := CountryRegionCode;
        BankAccount.Modify();
        exit(BankAccount."No.");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EBPaymentJournalTemplatesHandler(var EBPaymentJournalTemplates: TestPage "EB Payment Journal Templates")
    begin
        EBPaymentJournalTemplates.Last();
        EBPaymentJournalTemplates.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure EBPaymentJournalHandler(var EBPaymentJournal: TestPage "EB Payment Journal")
    begin
        EBPaymentJournal.Close();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EBPaymentJournalBatchesHandlerOK(var EBPaymentJournalBatches: TestPage "EB Payment Journal Batches")
    begin
        EBPaymentJournalBatches.Last();
        EBPaymentJournalBatches.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EBPaymentJournalBatchesHandlerCancel(var EBPaymentJournalBatches: TestPage "EB Payment Journal Batches")
    begin
        EBPaymentJournalBatches.Last();
        EBPaymentJournalBatches.Cancel().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure GLAccCardHandler(var GLAccCard: TestPage "G/L Account Card")
    begin
        GLAccCard.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CustCardHandler(var CustCard: TestPage "Customer Card")
    begin
        CustCard.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure VendCardHandler(var VendCard: TestPage "Vendor Card")
    begin
        VendCard.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CustLedgEntriesHandler(var CustLedgerEntries: TestPage "Customer Ledger Entries")
    begin
        CustLedgerEntries.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure VendLedgEntriesHandler(var VendLedgerEntries: TestPage "Vendor Ledger Entries")
    begin
        VendLedgerEntries.Close();
    end;
}

