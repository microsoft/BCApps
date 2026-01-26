codeunit 144018 "PAYDISC Test"
{
    Permissions =;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        AmountErrorTxt: Label '%1 and %2 must be same.';
        OpenStateErrorTxt: Label 'The Customer Ledger Entry had a wrong Open/Close state.';
        ConfirmMessageForPaymentTxt: Label 'Do you want to change all open entries for every customer and vendor that are not blocked?';
        MultipleInvoicesErrorTxt: Label 'When applying one payment to multiple invoices the system does not support disregarding of payment discount at full payment.';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"PAYDISC Test");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"PAYDISC Test");

        LibrarySales.SetCreditWarningsToNoWarnings();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        GeneralLedgerSetup.Get();
        SalesReceivablesSetup.Get();
        SetSalesAndRecivablesSetup(SalesReceivablesSetup."Appln. between Currencies"::All,
          SalesReceivablesSetup."Credit Warnings"::"No Warning");

        Commit();

        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"PAYDISC Test");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DisregardDiscountAtFullPaymentBeforeDiscountDate()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        CurrencyCode: Code[10];
        Amount: Decimal;
        IsOpen: Boolean;
        DisregPmtDiscAtFullPmt: Boolean;
    begin
        // This test case verifies that the Payment and Invoice are both closed without remaining amount
        // when the Sales Invoice is fully paid within the Payment Discount Date
        // and the field "Disreg. Pmt. Disc. at Full Pmt" in the Payment Terms is set to Yes.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Invoice and Payment, change warnings in General Ledger Setup.
        Initialize();
        DisregPmtDiscAtFullPmt := true;
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2), DisregPmtDiscAtFullPmt);
        CurrencyCode := CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        // Using a random value for the amount.
        Amount := LibraryRandom.RandDec(1000, 2);
        CreateAndPostGenJournalLine(GenJournalLine, Customer."No.", CurrencyCode, GenJournalLine."Document Type"::Invoice, Amount, WorkDate());
        CustLedgerEntry.CalcFields(Amount);
        CreateAndPostGenJournalLine(GenJournalLine2, Customer."No.", CurrencyCode, GenJournalLine2."Document Type"::Payment,
          -Amount, CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()));
        WarningsInGeneralLedgerSetup(true, false);

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(CustLedgerEntry2, GenJournalLine2."Document Type"::Payment, GenJournalLine2."Document Type"::Invoice,
          GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry2);

        // 3. Verify: Verify the Ledger Entries.
        // -> Invoice
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        asserterror VerifyAmountInLedgerEntry(0, CustLedgerEntry."Original Pmt. Disc. Possible");
        VerifyLedgerEntryOpenState(CustLedgerEntry, false);
        // -> Payment
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry2, GenJournalLine2."Document Type", GenJournalLine2."Document No.");
        VerifyAmountInLedgerEntry(0, CustLedgerEntry2."Remaining Pmt. Disc. Possible");
        IsOpen := false;
        VerifyRemainingAmount(CustLedgerEntry2, -Amount, IsOpen);
        VerifyLedgerEntryOpenState(CustLedgerEntry2, IsOpen);

        // 4. Tear Down: Change back in General Ledger Setup, Sales And Receivable Setup.
        SetupsRolledBack(GeneralLedgerSetup, SalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DisregardDiscountAtFullPaymentBeforeDiscountToleranceDate()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        CurrencyCode: Code[10];
        Amount: Decimal;
        IsOpen: Boolean;
        DisregPmtDiscAtFullPmt: Boolean;
    begin
        // This test case verifies that the Payment and Invoice are both closed without remaining amount
        // when the Sales Invoice is fully paid within the Payment Discount Tolerance Date
        // and the field "Disreg. Pmt. Disc. at Full Pmt" in the Payment Terms is set to Yes.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Invoice and Payment, change warnings in General Ledger Setup.
        Initialize();
        DisregPmtDiscAtFullPmt := true;
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2), DisregPmtDiscAtFullPmt);
        CurrencyCode := CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        // Using a random value for the amount.
        Amount := LibraryRandom.RandDec(1000, 2);
        CreateAndPostGenJournalLine(GenJournalLine, Customer."No.", CurrencyCode, GenJournalLine."Document Type"::Invoice, Amount, WorkDate());
        CreateAndPostGenJournalLine(GenJournalLine2, Customer."No.", CurrencyCode, GenJournalLine2."Document Type"::Payment,
          -Amount, CalcDate('<1D>', CalcDate(PaymentTerms."Discount Date Calculation", WorkDate())));
        WarningsInGeneralLedgerSetup(true, false);

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(CustLedgerEntry2, GenJournalLine2."Document Type"::Payment, GenJournalLine2."Document Type"::Invoice,
          GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry2);

        // 3. Verify: Verify the Ledger Entries.
        // -> Invoice
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        asserterror VerifyAmountInLedgerEntry(0, CustLedgerEntry."Original Pmt. Disc. Possible");
        VerifyLedgerEntryOpenState(CustLedgerEntry, false);
        // -> Payment
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry2, GenJournalLine2."Document Type", GenJournalLine2."Document No.");
        VerifyAmountInLedgerEntry(0, CustLedgerEntry2."Remaining Pmt. Disc. Possible");
        IsOpen := false;
        VerifyRemainingAmount(CustLedgerEntry2, -Amount, IsOpen);
        VerifyLedgerEntryOpenState(CustLedgerEntry2, IsOpen);

        // 4. Tear Down: Change back in General Ledger Setup, Sales And Receivable Setup.
        SetupsRolledBack(GeneralLedgerSetup, SalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DisregardDiscountAtFullPaymentAfterDiscountToleranceDate()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        CurrencyCode: Code[10];
        Amount: Decimal;
        IsOpen: Boolean;
        DisregPmtDiscAtFullPmt: Boolean;
    begin
        // This test case verifies that the Payment and Invoice are both closed without remaining amount
        // when the Sales Invoice is fully paid after the Payment Discount Tolerance Date
        // and the field "Disreg. Pmt. Disc. at Full Pmt" in the Payment Terms is set to Yes.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Invoice and Payment, change warnings in General Ledger Setup.
        Initialize();
        DisregPmtDiscAtFullPmt := true;
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2), DisregPmtDiscAtFullPmt);
        CurrencyCode := CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        // Using a random value for the amount.
        Amount := LibraryRandom.RandDec(1000, 2);
        CreateAndPostGenJournalLine(GenJournalLine, Customer."No.", CurrencyCode, GenJournalLine."Document Type"::Invoice, Amount, WorkDate());
        CreateAndPostGenJournalLine(GenJournalLine2, Customer."No.", CurrencyCode, GenJournalLine2."Document Type"::Payment,
          -Amount, CalcDate(PaymentTerms."Due Date Calculation", WorkDate()));
        WarningsInGeneralLedgerSetup(true, false);

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(CustLedgerEntry2, GenJournalLine2."Document Type"::Payment, GenJournalLine2."Document Type"::Invoice,
          GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry2);

        // 3. Verify: Verify the Ledger Entries.
        // -> Invoice
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        asserterror VerifyAmountInLedgerEntry(0, CustLedgerEntry."Original Pmt. Disc. Possible");
        VerifyLedgerEntryOpenState(CustLedgerEntry, false);
        // -> Payment
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry2, GenJournalLine2."Document Type", GenJournalLine2."Document No.");
        VerifyAmountInLedgerEntry(0, CustLedgerEntry2."Remaining Pmt. Disc. Possible");
        IsOpen := false;
        VerifyRemainingAmount(CustLedgerEntry2, -Amount, IsOpen);
        VerifyLedgerEntryOpenState(CustLedgerEntry2, IsOpen);

        // 4. Tear Down: Change back in General Ledger Setup, Sales And Receivable Setup.
        SetupsRolledBack(GeneralLedgerSetup, SalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DisregardDiscountAtFullMultipleInvoicesBeforeDiscountDate()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        GenJournalLine3: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        CurrencyCode: Code[10];
        Amount: Decimal;
        DisregPmtDiscAtFullPmt: Boolean;
    begin
        // This test case verifies that the system does not support disregarding of payment discount at full payment
        // when applying one payment to multiple invoices.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Invoice and Payment, change warnings in General Ledger Setup.
        Initialize();
        DisregPmtDiscAtFullPmt := true;
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2), DisregPmtDiscAtFullPmt);
        CurrencyCode := CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        // Using a random value for the amount.
        Amount := LibraryRandom.RandDec(1000, 2);
        CreateAndPostGenJournalLine(GenJournalLine, Customer."No.", CurrencyCode, GenJournalLine."Document Type"::Invoice, Amount, WorkDate());
        CreateAndPostGenJournalLine(GenJournalLine2, Customer."No.", CurrencyCode, GenJournalLine2."Document Type"::Invoice, Amount,
          WorkDate());
        CreateAndPostGenJournalLine(GenJournalLine3, Customer."No.", CurrencyCode, GenJournalLine3."Document Type"::Payment,
          -Amount * 2, CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()));

        WarningsInGeneralLedgerSetup(true, false);

        // 2. Exercise: Apply and Post the Customer Ledger Entries.
        ApplyCustomerEntries(CustLedgerEntry, GenJournalLine3."Document Type"::Payment, GenJournalLine3."Document Type"::Invoice,
          GenJournalLine3."Document No.", GenJournalLine."Document No.", GenJournalLine2."Document No.");
        ApplyCustomerEntries(CustLedgerEntry, GenJournalLine3."Document Type"::Payment, GenJournalLine3."Document Type"::Invoice,
          GenJournalLine3."Document No.", GenJournalLine."Document No.", GenJournalLine2."Document No.");

        // When applying one payment to multiple invoices the system does not support disregarding of payment discount at full payment.
        asserterror LibraryERM.PostCustLedgerApplication(CustLedgerEntry);

        // 3. Verify: Verify the expected error message. (Codeunit.32000000.Text1090005)
        Assert.ExpectedError(MultipleInvoicesErrorTxt);

        // 4. Tear Down: Change back in General Ledger Setup, Sales And Receivable Setup.
        SetupsRolledBack(GeneralLedgerSetup, SalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DisregardDiscountAtFullMultiplePaymentsBeforeDiscountDate()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        CustLedgerEntry3: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        GenJournalLine3: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        CurrencyCode: Code[10];
        Amount: Decimal;
        PaymentAmount: Decimal;
        IsOpen: Boolean;
        DisregPmtDiscAtFullPmt: Boolean;
    begin
        // This test case verifies that the Payment and Invoice are both closed without remaining amount
        // when the Sales Invoice is fully paid, by two payment transactions, within the Payment Discount Date
        // and the field "Disreg. Pmt. Disc. at Full Pmt" in the Payment Terms is set to Yes.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Invoice and Payment, change warnings in General Ledger Setup.
        Initialize();
        DisregPmtDiscAtFullPmt := true;
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2), DisregPmtDiscAtFullPmt);
        CurrencyCode := CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        // Using a random value for the amount.
        Amount := LibraryRandom.RandDec(1000, 1);
        PaymentAmount := Amount / 2;
        CreateAndPostGenJournalLine(GenJournalLine, Customer."No.", CurrencyCode, GenJournalLine."Document Type"::Invoice, Amount, WorkDate());
        CreateAndPostGenJournalLine(GenJournalLine2, Customer."No.", CurrencyCode, GenJournalLine2."Document Type"::Payment,
          -PaymentAmount, CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()));
        CreateAndPostGenJournalLine(GenJournalLine3, Customer."No.", CurrencyCode, GenJournalLine3."Document Type"::Payment,
          -PaymentAmount, CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()));
        WarningsInGeneralLedgerSetup(true, false);

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(CustLedgerEntry2, GenJournalLine2."Document Type"::Payment, GenJournalLine2."Document Type"::Invoice,
          GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry2);
        ApplyCustomerEntry(CustLedgerEntry3, GenJournalLine3."Document Type"::Payment, GenJournalLine3."Document Type"::Invoice,
          GenJournalLine3."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry3);

        // 3. Verify: Verify the Ledger Entries.
        // -> Invoice
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        asserterror VerifyAmountInLedgerEntry(0, CustLedgerEntry."Original Pmt. Disc. Possible");
        VerifyLedgerEntryOpenState(CustLedgerEntry, false);
        // -> Payment
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry2, GenJournalLine2."Document Type", GenJournalLine2."Document No.");
        VerifyAmountInLedgerEntry(0, CustLedgerEntry2."Remaining Pmt. Disc. Possible");
        IsOpen := false;
        VerifyRemainingAmount(CustLedgerEntry2, -PaymentAmount, IsOpen);
        VerifyLedgerEntryOpenState(CustLedgerEntry2, IsOpen);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry3, GenJournalLine3."Document Type", GenJournalLine3."Document No.");
        VerifyAmountInLedgerEntry(0, CustLedgerEntry3."Remaining Pmt. Disc. Possible");
        VerifyRemainingAmount(CustLedgerEntry3, -PaymentAmount, IsOpen);
        VerifyLedgerEntryOpenState(CustLedgerEntry3, IsOpen);

        // 4. Tear Down: Change back in General Ledger Setup, Sales And Receivable Setup.
        SetupsRolledBack(GeneralLedgerSetup, SalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DisregardDiscountWhenPaymentIsLargerThatInvoiceAmountBeforeDiscountDate()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        CurrencyCode: Code[10];
        Amount: Decimal;
        PaymentAmount: Decimal;
        IsOpen: Boolean;
        DisregPmtDiscAtFullPmt: Boolean;
    begin
        // This test case verifies that the Invoice is closed but the Payment remains open
        // when the Payment exceeds the invoiced amount
        // and the field "Disreg. Pmt. Disc. at Full Pmt" in the Payment Terms is set to Yes.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Invoice and Payment, change warnings in General Ledger Setup.
        Initialize();
        DisregPmtDiscAtFullPmt := true;
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2), DisregPmtDiscAtFullPmt);
        CurrencyCode := CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        // Using a random value for the amount.
        Amount := LibraryRandom.RandDec(1000, 2);
        PaymentAmount := Amount * 2;
        CreateAndPostGenJournalLine(GenJournalLine, Customer."No.", CurrencyCode, GenJournalLine."Document Type"::Invoice, Amount, WorkDate());
        CreateAndPostGenJournalLine(GenJournalLine2, Customer."No.", CurrencyCode, GenJournalLine2."Document Type"::Payment,
          -PaymentAmount, CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()));
        WarningsInGeneralLedgerSetup(true, false);

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(CustLedgerEntry2, GenJournalLine2."Document Type"::Payment, GenJournalLine2."Document Type"::Invoice,
          GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry2);

        // 3. Verify: Verify the Ledger Entries.
        // -> Invoice
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        asserterror VerifyAmountInLedgerEntry(0, CustLedgerEntry."Original Pmt. Disc. Possible");
        VerifyLedgerEntryOpenState(CustLedgerEntry, false);
        // -> Payment
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry2, GenJournalLine2."Document Type", GenJournalLine2."Document No.");
        VerifyAmountInLedgerEntry(0, CustLedgerEntry2."Remaining Pmt. Disc. Possible");
        IsOpen := true;
        VerifyRemainingAmount(CustLedgerEntry2, Amount - PaymentAmount, IsOpen);
        VerifyLedgerEntryOpenState(CustLedgerEntry2, IsOpen);

        // 4. Tear Down: Change back in General Ledger Setup, Sales And Receivable Setup.
        SetupsRolledBack(GeneralLedgerSetup, SalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure FullPaymentBeforeDiscountDate()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        CurrencyCode: Code[10];
        Amount: Decimal;
        IsOpen: Boolean;
        DisregPmtDiscAtFullPmt: Boolean;
    begin
        // This test case verifies that the Invoice is closed, by the Payment remains open
        // when the Sales Invoice is fully paid within the Payment Discount Date
        // and the field "Disreg. Pmt. Disc. at Full Pmt" in the Payment Terms is set to No.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Invoice and Payment, change warnings in General Ledger Setup.
        Initialize();
        DisregPmtDiscAtFullPmt := false;
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2), DisregPmtDiscAtFullPmt);
        CurrencyCode := CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        // Using a random value for the amount.
        Amount := LibraryRandom.RandDec(1000, 2);
        CreateAndPostGenJournalLine(GenJournalLine, Customer."No.", CurrencyCode, GenJournalLine."Document Type"::Invoice, Amount, WorkDate());
        CreateAndPostGenJournalLine(GenJournalLine2, Customer."No.", CurrencyCode, GenJournalLine2."Document Type"::Payment,
          -Amount, CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()));
        WarningsInGeneralLedgerSetup(true, false);

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(CustLedgerEntry2, GenJournalLine2."Document Type"::Payment, GenJournalLine2."Document Type"::Invoice,
          GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry2);

        // 3. Verify: Verify the Ledger Entries.
        // -> Invoice
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        asserterror VerifyAmountInLedgerEntry(0, CustLedgerEntry."Original Pmt. Disc. Possible");
        VerifyLedgerEntryOpenState(CustLedgerEntry, false);
        // -> Payment
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry2, GenJournalLine2."Document Type", GenJournalLine2."Document No.");
        VerifyAmountInLedgerEntry(0, CustLedgerEntry2."Remaining Pmt. Disc. Possible");
        IsOpen := true;
        VerifyRemainingAmount(CustLedgerEntry2, -Amount, IsOpen);
        VerifyLedgerEntryOpenState(CustLedgerEntry2, IsOpen);

        // 4. Tear Down: Change back in General Ledger Setup, Sales And Receivable Setup.
        SetupsRolledBack(GeneralLedgerSetup, SalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure FullPaymentBeforeDiscountToleranceDate()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        CurrencyCode: Code[10];
        Amount: Decimal;
        IsOpen: Boolean;
        DisregPmtDiscAtFullPmt: Boolean;
    begin
        // This test case verifies that the Invoice is closed, by the Payment remains open
        // when the Sales Invoice is fully paid within the Payment Discount Tolerance Date
        // and the field "Disreg. Pmt. Disc. at Full Pmt" in the Payment Terms is set to No.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Invoice and Payment, change warnings in General Ledger Setup.
        Initialize();
        DisregPmtDiscAtFullPmt := false;
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2), DisregPmtDiscAtFullPmt);
        CurrencyCode := CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        // Using a random value for the amount.
        Amount := LibraryRandom.RandDec(1000, 2);
        CreateAndPostGenJournalLine(GenJournalLine, Customer."No.", CurrencyCode, GenJournalLine."Document Type"::Invoice, Amount, WorkDate());
        CreateAndPostGenJournalLine(GenJournalLine2, Customer."No.", CurrencyCode, GenJournalLine2."Document Type"::Payment,
          -Amount, CalcDate('<1D>', CalcDate(PaymentTerms."Discount Date Calculation", WorkDate())));
        WarningsInGeneralLedgerSetup(true, false);

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(CustLedgerEntry2, GenJournalLine2."Document Type"::Payment, GenJournalLine2."Document Type"::Invoice,
          GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry2);

        // 3. Verify: Verify the Ledger Entries.
        // -> Invoice
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        asserterror VerifyAmountInLedgerEntry(0, CustLedgerEntry."Original Pmt. Disc. Possible");
        VerifyLedgerEntryOpenState(CustLedgerEntry, false);
        // -> Payment
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry2, GenJournalLine2."Document Type", GenJournalLine2."Document No.");
        VerifyAmountInLedgerEntry(0, CustLedgerEntry2."Remaining Pmt. Disc. Possible");
        IsOpen := true;
        VerifyRemainingAmount(CustLedgerEntry2, -Amount, IsOpen);
        VerifyLedgerEntryOpenState(CustLedgerEntry2, IsOpen);

        // 4. Tear Down: Change back in General Ledger Setup, Sales And Receivable Setup.
        SetupsRolledBack(GeneralLedgerSetup, SalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure FullPaymentAfterDiscountToleranceDate()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        CurrencyCode: Code[10];
        Amount: Decimal;
        IsOpen: Boolean;
        DisregPmtDiscAtFullPmt: Boolean;
    begin
        // This test case verifies that the Payment and Invoice are both closed without remaining amount
        // when the Sales Invoice is fully paid after the Payment Discount Tolerance Date
        // and the field "Disreg. Pmt. Disc. at Full Pmt" in the Payment Terms is set to No.

        // 1. Setup: Change the Sales and Receivable Setup, create Payment Terms, create Customer and Currency, create General Journal Line
        // for Invoice and Payment, change warnings in General Ledger Setup.
        Initialize();
        DisregPmtDiscAtFullPmt := false;
        CreatePaymentTerms(PaymentTerms, LibraryRandom.RandInt(10), LibraryRandom.RandDec(5, 2), DisregPmtDiscAtFullPmt);
        CurrencyCode := CreateCustomerWithCurrency(Customer, PaymentTerms.Code);
        // Using a random value for the amount.
        Amount := LibraryRandom.RandDec(1000, 2);
        CreateAndPostGenJournalLine(GenJournalLine, Customer."No.", CurrencyCode, GenJournalLine."Document Type"::Invoice, Amount, WorkDate());
        CreateAndPostGenJournalLine(GenJournalLine2, Customer."No.", CurrencyCode, GenJournalLine2."Document Type"::Payment,
          -Amount, CalcDate(PaymentTerms."Due Date Calculation", WorkDate()));
        WarningsInGeneralLedgerSetup(true, false);

        // 2. Exercise: Apply and Post the Customer Ledger Entry.
        ApplyCustomerEntry(CustLedgerEntry2, GenJournalLine2."Document Type"::Payment, GenJournalLine2."Document Type"::Invoice,
          GenJournalLine2."Document No.", GenJournalLine."Document No.");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry2);

        // 3. Verify: Verify the Ledger Entries.
        // -> Invoice
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        asserterror VerifyAmountInLedgerEntry(0, CustLedgerEntry."Original Pmt. Disc. Possible");
        VerifyLedgerEntryOpenState(CustLedgerEntry, false);
        // -> Payment
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry2, GenJournalLine2."Document Type", GenJournalLine2."Document No.");
        VerifyAmountInLedgerEntry(0, CustLedgerEntry2."Remaining Pmt. Disc. Possible");
        IsOpen := false;
        VerifyRemainingAmount(CustLedgerEntry2, -Amount, IsOpen);
        VerifyLedgerEntryOpenState(CustLedgerEntry2, IsOpen);

        // 4. Tear Down: Change back in General Ledger Setup, Sales And Receivable Setup.
        SetupsRolledBack(GeneralLedgerSetup, SalesReceivablesSetup);
    end;

    local procedure AmountToApplyInCustomerLedger(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        // Find Posted Customer Ledger Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        CustLedgerEntry.CalcFields("Remaining Amount");
        CustLedgerEntry.Validate("Amount to Apply", CustLedgerEntry."Remaining Amount");
        CustLedgerEntry.Modify(true);
    end;

    local procedure ApplyCustomerEntries(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; DocumentNo2: Code[20]; DocumentNo3: Code[20])
    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        CustLedgerEntry3: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        CustLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, CustLedgerEntry."Remaining Amount");
        AmountToApplyInCustomerLedger(CustLedgerEntry2, DocumentNo2, DocumentType2);

        // Set Applies-to ID.
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry2);

        if DocumentNo3 <> '' then begin
            AmountToApplyInCustomerLedger(CustLedgerEntry3, DocumentNo3, DocumentType2);
            LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry3);
        end;
    end;

    local procedure ApplyCustomerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; DocumentNo2: Code[20])
    begin
        ApplyCustomerEntries(CustLedgerEntry, DocumentType, DocumentType2, DocumentNo, DocumentNo2, '');
    end;

    [Normal]
    local procedure AttachPaymentTermsCustomer(var Customer: Record Customer; PaymentTermsCode: Code[10])
    begin
        Customer.Validate("Payment Terms Code", PaymentTermsCode);
        Customer.Modify(true);
    end;

    local procedure CreateCurrency(var Currency: Record Currency)
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        Currency.Validate("Residual Gains Account", Currency."Realized Gains Acc.");
        Currency.Validate("Residual Losses Account", Currency."Realized Losses Acc.");
        Currency.Modify(true);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
    end;

    local procedure CreateCurrencyWithSetup(var Currency: Record Currency)
    begin
        CreateCurrency(Currency);
        UpdateCurrencySetup(Currency.Code);
    end;

    local procedure CreateCustomerWithCurrency(var Customer: Record Customer; PaymentTermsCode: Code[10]): Code[10]
    var
        Currency: Record Currency;
        LibrarySales: Codeunit "Library - Sales";
    begin
        // Random Value for Payment Tolerance and Maximum Payment Tolerance Amount.
        LibrarySales.CreateCustomer(Customer);
        AttachPaymentTermsCustomer(Customer, PaymentTermsCode);
        CreateCurrencyWithSetup(Currency);
        RunChangePaymentTolerance(Currency.Code, LibraryRandom.RandDec(5, 2), LibraryRandom.RandDec(10, 2));
        exit(Currency.Code);
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::General);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);

        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; CurrencyCode: Code[10]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal; PostingDate: Date)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine,
          GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name, DocumentType, GenJournalLine."Account Type"::Customer, AccountNo, Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePaymentTerms(var PaymentTerms: Record "Payment Terms"; DiscountDateCalculationDays: Integer; DiscountPercent: Decimal; DisregPmtDiscAtFullPmt: Boolean)
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        Evaluate(PaymentTerms."Due Date Calculation", '<' + Format(LibraryRandom.RandInt(2)) + 'M>');
        Evaluate(PaymentTerms."Discount Date Calculation", '<' + Format(DiscountDateCalculationDays) + 'D>');

        // Evaluate doesn't call validate trigger.
        PaymentTerms.Validate("Due Date Calculation", PaymentTerms."Due Date Calculation");
        PaymentTerms.Validate("Discount Date Calculation", PaymentTerms."Discount Date Calculation");
        PaymentTerms.Validate("Discount %", DiscountPercent);
        PaymentTerms.Validate("Calc. Pmt. Disc. on Cr. Memos", true);
        PaymentTerms.Validate("Disreg. Pmt. Disc. at Full Pmt", DisregPmtDiscAtFullPmt);
        PaymentTerms.Modify(true);
    end;

    local procedure RestoreGeneralLedgerSetup(var TempGeneralLedgerSetup: Record "General Ledger Setup" temporary)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate(
          "Payment Tolerance Posting", TempGeneralLedgerSetup."Payment Tolerance Posting");
        GeneralLedgerSetup.Validate(
          "Pmt. Disc. Tolerance Posting", TempGeneralLedgerSetup."Pmt. Disc. Tolerance Posting");
        GeneralLedgerSetup.Validate("Payment Tolerance Warning", TempGeneralLedgerSetup."Payment Tolerance Warning");
        GeneralLedgerSetup.Validate("Pmt. Disc. Tolerance Warning", TempGeneralLedgerSetup."Pmt. Disc. Tolerance Warning");
        GeneralLedgerSetup.Validate("Payment Discount Grace Period", TempGeneralLedgerSetup."Payment Discount Grace Period");
        GeneralLedgerSetup.Modify(true);

        // Cleanup for Payment Tolerance Percentage and Maximum Payment Tolerance Amount.
        RunChangePaymentTolerance('', 0, 0);
    end;

    local procedure RunChangePaymentTolerance(CurrencyCode: Code[10]; PaymentTolerance: Decimal; MaxPmtToleranceAmount: Decimal)
    var
        ChangePaymentTolerance: Report "Change Payment Tolerance";
    begin
        Clear(ChangePaymentTolerance);
        ChangePaymentTolerance.InitializeRequest(false, CurrencyCode, PaymentTolerance, MaxPmtToleranceAmount);
        ChangePaymentTolerance.UseRequestPage(false);
        ChangePaymentTolerance.Run();
    end;

    local procedure SetSalesAndRecivablesSetup(ApplnbetweenCurrencies: Option; CreditWarnings: Option)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Appln. between Currencies", ApplnbetweenCurrencies);
        SalesReceivablesSetup.Validate("Credit Warnings", CreditWarnings);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure SetupsRolledBack(GeneralLedgerSetup: Record "General Ledger Setup"; SalesReceivablesSetup: Record "Sales & Receivables Setup")
    begin
        RestoreGeneralLedgerSetup(GeneralLedgerSetup);
        WarningsInGeneralLedgerSetup(GeneralLedgerSetup."Payment Tolerance Warning", GeneralLedgerSetup."Pmt. Disc. Tolerance Warning");
        SetSalesAndRecivablesSetup(SalesReceivablesSetup."Appln. between Currencies", SalesReceivablesSetup."Credit Warnings");
    end;

    local procedure UpdateCurrencySetup(CurrencyCode: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        UpdatePaymentToleranceInSetup(
          CurrencyCode,
          '<' + Format(LibraryRandom.RandInt(5)) + 'D>',
          GeneralLedgerSetup."Payment Tolerance Posting"::"Payment Tolerance Accounts",
          GeneralLedgerSetup."Pmt. Disc. Tolerance Posting"::"Payment Tolerance Accounts");
    end;

    local procedure UpdatePaymentToleranceInSetup(CurrencyCode: Code[10]; PaymentDiscountGracePeriod: Text[10]; PaymentTolerancePosting: Option; PmtDiscTolerancePosting: Option)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        Evaluate(GeneralLedgerSetup."Payment Discount Grace Period", PaymentDiscountGracePeriod);
        GeneralLedgerSetup.Validate("Payment Tolerance Posting", PaymentTolerancePosting);
        GeneralLedgerSetup.Validate("Pmt. Disc. Tolerance Posting", PmtDiscTolerancePosting);

        // As there is no need to run the Adjust Exchange Rate Report so we are not validating the Additional Reporting Currency field.
        GeneralLedgerSetup."Additional Reporting Currency" := CurrencyCode;
        GeneralLedgerSetup.Modify(true);
        RunChangePaymentTolerance('', LibraryRandom.RandDec(5, 2), LibraryRandom.RandDec(10, 2));
    end;

    local procedure VerifyAmountInLedgerEntry(ExpectedAmount: Decimal; LedgerEntryAmount: Decimal)
    begin
        Assert.AreEqual(ExpectedAmount, LedgerEntryAmount, StrSubstNo(AmountErrorTxt, ExpectedAmount, LedgerEntryAmount));
    end;

    local procedure VerifyLedgerEntryOpenState(var CustLedgerEntry: Record "Cust. Ledger Entry"; Expected: Boolean)
    begin
        Assert.AreEqual(Expected, CustLedgerEntry.Open, OpenStateErrorTxt);
    end;

    local procedure VerifyRemainingAmount(CustLedgerEntry: Record "Cust. Ledger Entry"; OriginalAmount: Decimal; ExpectRemainingValue: Boolean)
    begin
        CustLedgerEntry.CalcFields("Remaining Amount", Amount);
        if ExpectRemainingValue then
            Assert.AreNotEqual(0, CustLedgerEntry."Remaining Amount",
              StrSubstNo(AmountErrorTxt, 0, CustLedgerEntry.FieldCaption("Remaining Amount")));
        CustLedgerEntry.TestField("Remaining Amount", CustLedgerEntry.Amount - OriginalAmount);
        Assert.AreNotEqual(CustLedgerEntry.Amount, CustLedgerEntry."Remaining Amount",
          StrSubstNo(AmountErrorTxt, CustLedgerEntry.FieldCaption(Amount), CustLedgerEntry.FieldCaption("Remaining Amount")));
    end;

    local procedure WarningsInGeneralLedgerSetup(PaymentToleranceWarning: Boolean; PmtDiscToleranceWarning: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Payment Tolerance Warning", PaymentToleranceWarning);
        GeneralLedgerSetup.Validate("Pmt. Disc. Tolerance Warning", PmtDiscToleranceWarning);
        GeneralLedgerSetup.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := not (Question = ConfirmMessageForPaymentTxt);
    end;
}

