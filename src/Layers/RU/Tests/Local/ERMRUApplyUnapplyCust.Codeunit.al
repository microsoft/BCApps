codeunit 144504 "ERM RU Apply Unapply Cust"
{
    // // [FEATURE] [Sales]

    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryJournals: Codeunit "Library - Journals";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        WrongCustBackPrepaymentErr: Label 'Wrong Customer Back Prepayment.';
        MustNotBeAfterErr: Label 'Posting date must not be after %1 in %2 entry no. %3.', Comment = '%1 Posting Date; %2 - Customer Ledger Entry table; %3 - Entry No.';
        ApplnPrepmtOnlyErr: Label 'Application is valid with Document Type Prepayment only.';

    [Test]
    [Scope('OnPrem')]
    procedure UnapplySalesPrepayment()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Prepayment] [Unapply]
        // [SCENARIO 123864] Unapply Customer Ledger Entry with Prepayment
        Initialize();

        // [GIVEN] Posted and Applied Customer Ledger Entries with PaymentNo = "X" and prepayment Amount = "A"
        CustomerNo := LibrarySales.CreateCustomerNo();
        PostApplyCustLedgerEntries(PaymentNo, InvoiceNo, Amount, CustomerNo);

        // [WHEN] Unapply Vendor Ledger Entry for PaymentNo = "X"
        UnapplyCustLedgerEntry(CustLedgerEntry."Document Type"::Payment, PaymentNo);

        // [THEN] G/L Entries created with Source Code for Unapplication with Amount = "A"
        VerifyUnappliedGLEntries(CustomerNo, -Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyInvoiceAndPaymentDiffDateWithCheckApplicationDate()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntryPmt: Record "Cust. Ledger Entry";
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Apply]
        // [SCENARIO 376250] Apply Sales Invoice to Payment with different date should generate an error when "Check Application Date" is enabled
        Initialize();

        // [GIVEN] "Check Application Date" is enabled in Sales Setup
        UpdateSalesSetup(true, false);

        // [GIVEN] Posted Sales Invoice on january = "Date" and Payment on february with EntryNo = "N"
        CreatePostInvoiceAndPayment(CustLedgerEntry, InvoiceNo, PaymentNo, CalcDate('<1M>', WorkDate()));

        // [WHEN] Apply Invoice to Payment
        asserterror ApplyCustomerInvoiceToPayment(InvoiceNo, PaymentNo);

        // [THEN] Error thrown: Posting date must not be after "Date" in Cust. Ledger Entry entry no. "N"
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntryPmt, CustLedgerEntry."Document Type"::Payment, PaymentNo);
        Assert.ExpectedError(
          StrSubstNo(MustNotBeAfterErr, CustLedgerEntry."Posting Date", CustLedgerEntryPmt.TableCaption(), CustLedgerEntryPmt."Entry No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyInvoiceAndPaymentSameDateWithCheckApplicationDate()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Apply]
        // [SCENARIO 376250] Apply Sales Invoice to Payment with the same date when "Check Application Date" is enabled
        Initialize();

        // [GIVEN] "Check Application Date" is enabled in Sales Setup
        UpdateSalesSetup(true, false);

        // [GIVEN] Posted Sales Invoice and Payment on workdate
        CreatePostInvoiceAndPayment(CustLedgerEntry, InvoiceNo, PaymentNo, WorkDate());

        // [WHEN] Apply Invoice to Payment
        ApplyCustomerInvoiceToPayment(InvoiceNo, PaymentNo);

        // [THEN] No open entries for Customer
        VerifyClosedEntriesForCustomer(CustLedgerEntry."Customer No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyInvoiceAndPaymentDiffDateWithCheckApplicationPeriod()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Apply]
        // [SCENARIO 376250] Apply Sales Invoice to Payment with different date should generate an error when "Check Application Period" is enabled
        Initialize();

        // [GIVEN] "Check Application Period" is enabled in Sales Setup
        UpdateSalesSetup(false, true);

        // [GIVEN] Posted Sales Invoice and Payment on different dates
        CreatePostInvoiceAndPayment(CustLedgerEntry, InvoiceNo, PaymentNo, CalcDate('<1M>', WorkDate()));

        // [WHEN] Apply Invoice to Payment
        asserterror ApplyCustomerInvoiceToPayment(InvoiceNo, PaymentNo);

        // [THEN] Error thrown 'Application is valid with Document Type Prepayment only.'
        Assert.ExpectedError(ApplnPrepmtOnlyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyInvoiceAndPaymentSameDateWithCheckApplicationPeriod()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Apply]
        // [SCENARIO 376250] Apply Sales Invoice to Payment with the same date when "Check Application Period" is enabled
        Initialize();

        // [GIVEN] "Check Application Period" is enabled in Sales Setup
        UpdateSalesSetup(false, true);

        // [GIVEN] Posted Sales Invoice and Payment on workdate
        CreatePostInvoiceAndPayment(CustLedgerEntry, InvoiceNo, PaymentNo, WorkDate());

        // [WHEN] Apply Invoice to Payment
        ApplyCustomerInvoiceToPayment(InvoiceNo, PaymentNo);

        // [THEN] No open entries for Customer
        VerifyClosedEntriesForCustomer(CustLedgerEntry."Customer No.");
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        IsInitialized := true;
    end;

    local procedure PostApplyCustLedgerEntries(var PaymentNo: Code[20]; var InvoiceNo: Code[20]; var Amount: Decimal; CustomerNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        Amount := CreateSalesInvoice(SalesHeader, CustomerNo);

        PaymentNo := CreatePostPrepaymentGenJnlLine(CustomerNo, -Amount, SalesHeader."No.");
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        ApplyCustomerInvoiceToPayment(InvoiceNo, PaymentNo);
    end;

    local procedure ApplyCustomerInvoiceToPayment(InvoiceDocNo: Code[20]; PaymentDocNo: Code[20])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.ApplyCustomerLedgerEntry(
          CustLedgEntry."Document Type"::Invoice, InvoiceDocNo,
          CustLedgEntry."Document Type"::Payment, PaymentDocNo);
    end;

    local procedure UnapplyCustLedgerEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);
    end;

    local procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]): Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        SalesHeader.CalcFields("Amount Including VAT");
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        exit(SalesHeader."Amount Including VAT");
    end;

    local procedure CreatePostPrepaymentGenJnlLine(CustomerNo: Code[20]; GLAmount: Decimal; PrepaymentDocNo: Code[20]): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, CustomerNo, GLAmount);
        GenJournalLine.Validate(Prepayment, true);
        GenJournalLine.Validate("Prepayment Document No.", PrepaymentDocNo);
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreatePostInvoiceAndPayment(var CustLedgerEntry: Record "Cust. Ledger Entry"; var InvoiceNo: Code[20]; var PaymentNo: Code[20]; PostingDate: Date)
    var
        SalesHeader: Record "Sales Header";
        GenJournalLine: Record "Gen. Journal Line";
        CustomerNo: Code[20];
    begin
        CustomerNo := LibrarySales.CreateCustomerNo();

        CreateSalesInvoice(SalesHeader, CustomerNo);
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, InvoiceNo);

        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, CustomerNo,
          -SalesHeader."Amount Including VAT");
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        PaymentNo := GenJournalLine."Document No.";
    end;

    local procedure UpdateSalesSetup(CheckApplnDate: Boolean; CheckApplnPeriod: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Check Application Date", CheckApplnDate);
        SalesReceivablesSetup.Validate("Check Application Period", CheckApplnPeriod);
        SalesReceivablesSetup.Modify();
    end;

    local procedure FindPrepaymentAcc(CustomerNo: Code[20]): Code[20]
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        Customer.Get(CustomerNo);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        exit(CustomerPostingGroup."Prepayment Account");
    end;

    local procedure VerifyUnappliedGLEntries(SourceNo: Code[20]; GLAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        GLEntry.SetRange("G/L Account No.", FindPrepaymentAcc(SourceNo));
        GLEntry.SetRange("Source No.", SourceNo);
        GLEntry.SetRange("Source Code", SourceCodeSetup."Unapplied Sales Entry Appln.");
        GLEntry.FindFirst();
        Assert.AreEqual(GLEntry.Amount, GLAmount, WrongCustBackPrepaymentErr);
    end;

    local procedure VerifyClosedEntriesForCustomer(CustomerNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.Init();
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange(Open, true);
        Assert.RecordIsEmpty(CustLedgerEntry);
    end;
}

