codeunit 134019 "ERM Apply Diff Entries - Cust."
{
    Permissions = TableData "Cust. Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Application] [Sales]
        IsInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        ErrorMessage: Label '%1 must be %2 in %3, %4: %5.';

    [Test]
    [Scope('OnPrem')]
    procedure ApplyCrMemoInvoiceFullAmount()
    var
        Amount: Decimal;
    begin
        // Check Application, Amount LCY after Posting Application of Credit Memo over Invoice with same Amount.
        Initialize();
        Amount := LibraryRandom.RandDec(100, 2);
        ApplyCreditMemoToInvoice('', Amount, -Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyCrMemoInvoiceHalfAmount()
    var
        Amount: Decimal;
    begin
        // Check Application, Amount LCY after Posting Application of Credit Memo over Invoice with Half Invoice Amount.
        Initialize();
        Amount := LibraryRandom.RandDec(100, 2);
        ApplyCreditMemoToInvoice('', Amount, -Amount / 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyCrMemoInvoiceFCY()
    var
        Amount: Decimal;
    begin
        // Check Application, Amount LCY after Posting Application of Credit Memo over Invoice with same Amount and FCY.
        Initialize();
        Amount := LibraryRandom.RandDec(100, 2);
        ApplyCreditMemoToInvoice(CreateCurrency(), Amount, -Amount);
    end;

    local procedure ApplyCreditMemoToInvoice(CurrencyCode: Code[10]; Amount: Decimal; Amount2: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        PaymentDiscountAmount: Decimal;
        AmountFCY: Decimal;
        RemainingAmount: Decimal;
    begin
        // Setup: Create Invoice and Credit Memo Entries for Customer. Take Random Amount for Invoice and Credit Memo.
        GeneralLedgerSetup.Get();
        CreateAndPostMultipleJnlLines(GenJournalLine, CurrencyCode, Amount, Amount2);
        PaymentDiscountAmount := ComputePaymentDiscountAmount(Amount);
        AmountFCY := ComputeAmountFCY(CurrencyCode, Abs(Amount2));
        RemainingAmount := Amount + Amount2;

        // Exercise: Apply Credit Memo on Invoice for the Customer.
        ApplyAndPostCustomerEntry(
          GenJournalLine."Document No.", GenJournalLine."Document No.", GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Document Type"::Invoice, Amount2);

        // Verify: Verify Remaining Amount, Payment Discount in Customer Ledger Entry, AmountLCY in Detailed Customer Ledger Entries.
        GetCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document No.", GenJournalLine."Document Type"::Invoice);
        Assert.AreNearlyEqual(
          RemainingAmount, CustLedgerEntry."Remaining Amount", GeneralLedgerSetup."Inv. Rounding Precision (LCY)",
          StrSubstNo(ErrorMessage, CustLedgerEntry.FieldCaption("Remaining Amount"), RemainingAmount,
            CustLedgerEntry.TableCaption(), CustLedgerEntry.FieldCaption("Entry No."), CustLedgerEntry."Entry No."));

        Assert.AreNearlyEqual(
          PaymentDiscountAmount, CustLedgerEntry."Original Pmt. Disc. Possible", GeneralLedgerSetup."Inv. Rounding Precision (LCY)",
          StrSubstNo(ErrorMessage, CustLedgerEntry.FieldCaption("Original Pmt. Disc. Possible"), PaymentDiscountAmount,
            CustLedgerEntry.TableCaption(), CustLedgerEntry.FieldCaption("Entry No."), CustLedgerEntry."Entry No."));

        VerifyDtldCustomerLedgerEntry(
          GenJournalLine."Document No.", DetailedCustLedgEntry."Entry Type"::Application, -AmountFCY,
          GeneralLedgerSetup."Inv. Rounding Precision (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyCrMemoAndPaymentToInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        DocumentNo: Code[20];
        Amount: Decimal;
        PartialAmount: Decimal;
        RemainingAmount: Decimal;
    begin
        // Check Application, Payment Discount, Amount LCY after posting Application Payment and Credit Memo over Invoice.

        // Setup: Create Invoice and Credit Memo Entries for Customer. Apply Credit Memo on Invoice with Partial Amount. Again Post
        // Payment Entry for the Remaining Amount. Take Random Decimal Amount for Invoice Amount. Deduct Integer Value from Amount
        // because sometimes Random Decimal Produces very less Amount for which Payment Discount can not be calculated.
        Initialize();
        GeneralLedgerSetup.Get();
        Amount := 100 + LibraryRandom.RandDec(100, 2);
        PartialAmount := Amount - LibraryRandom.RandInt(10);
        CreateAndPostMultipleJnlLines(GenJournalLine, '', Amount, -PartialAmount);
        RemainingAmount := ComputePaymentDiscountAmount(Amount);
        RemainingAmount := RemainingAmount - ComputePaymentDiscountAmount(PartialAmount);
        DocumentNo := GenJournalLine."Document No.";
        ApplyAndPostCustomerEntry(
          GenJournalLine."Document No.", DocumentNo, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Document Type"::Invoice, -PartialAmount);
        SelectGenJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account No.", GenJournalLine."Document Type"::Payment, PartialAmount - Amount, '');
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Apply Payment on Previously Posted Invoice for the Customer.
        ApplyAndPostCustomerEntry(
          GenJournalLine."Document No.", DocumentNo, GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::Invoice,
          PartialAmount - Amount);

        // Verify: Verify Remaining Amount in Customer Ledger Entry, Payment Discount Amount in Detailed Customer Ledger Entries.
        GetCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document No.", GenJournalLine."Document Type"::Payment);
        Assert.AreNearlyEqual(
          -RemainingAmount, CustLedgerEntry."Remaining Amount", GeneralLedgerSetup."Inv. Rounding Precision (LCY)",
          StrSubstNo(ErrorMessage, CustLedgerEntry.FieldCaption("Remaining Amount"), RemainingAmount,
            CustLedgerEntry.TableCaption(), CustLedgerEntry.FieldCaption("Entry No."), CustLedgerEntry."Entry No."));

        VerifyDtldCustomerLedgerEntry(
          GenJournalLine."Document No.", DetailedCustLedgEntry."Entry Type"::"Payment Discount", -RemainingAmount,
          GeneralLedgerSetup."Inv. Rounding Precision (LCY)");
    end;

    [Test]
    [HandlerFunctions('UnapplyCustomerEntriesPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ApplyUnapplyDifferentDocumentTypesToPayment()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        Amount: Decimal;
    begin
        // Verify Program populates correct Document Type value on G/L entry window after doing un application on Customer when adjust for payment discount is involved.

        // Setup: Post Invocie, Credit Memo and Payment Line.
        Initialize();
        GeneralLedgerSetup.Get();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        SelectGenJournalBatch(GenJournalBatch);
        Amount := LibraryRandom.RandDec(1000, 2);  // Using Random value for Amount.
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, CreateCustomer(), GenJournalLine."Document Type"::Invoice, Amount, '');
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account No.", GenJournalLine."Document Type"::"Credit Memo", -Amount / 2, '');
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account No.", GenJournalLine."Document Type"::Payment, GenJournalLine.Amount, '');
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        ApplyAndPostMultipleCustomerEntries(GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.", -Amount / 2);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.");

        // Exercise: Unapply Customer Entries.
        CustEntryApplyPostedEntries.UnApplyCustLedgEntry(CustLedgerEntry."Entry No.");

        // Verify: Verfiy Document Type should be Payment in G/L Entry.
        VerifyUnapplyGLEntry(CustLedgerEntry."Document No.");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Apply Diff Entries - Cust.");
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Apply Diff Entries - Cust.");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateAccountInCustomerPostingGroup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialized := true;
        Commit();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Apply Diff Entries - Cust.");
    end;

    local procedure ApplyAndPostMultipleCustomerEntries(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; AmountToApply: Decimal)
    var
        ApplyingCustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GLRegister: Record "G/L Register";
    begin
        SetApplyCustomerEntry(ApplyingCustLedgerEntry, DocumentType, DocumentNo, AmountToApply);
        GLRegister.FindLast();
        CustLedgerEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        CustLedgerEntry.SetRange("Applying Entry", false);
        CustLedgerEntry.FindSet();
        repeat
            CustLedgerEntry.CalcFields("Remaining Amount");
            CustLedgerEntry.Validate("Amount to Apply", CustLedgerEntry."Remaining Amount");
            CustLedgerEntry.Modify(true);
        until CustLedgerEntry.Next() = 0;
        SetAppliesToIDAndPostEntry(CustLedgerEntry, ApplyingCustLedgerEntry);
    end;

    local procedure ApplyAndPostCustomerEntry(DocumentNo: Code[20]; DocumentNo2: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; AmountToApply: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        SetApplyCustomerEntry(CustLedgerEntry, DocumentType, DocumentNo, AmountToApply);
        CustLedgerEntry2.SetRange(Open, true);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry2, DocumentType2, DocumentNo2);
        CustLedgerEntry2.FindSet();
        repeat
            CustLedgerEntry2.CalcFields("Remaining Amount");
            CustLedgerEntry2.Validate("Amount to Apply", CustLedgerEntry2."Remaining Amount");
            CustLedgerEntry2.Modify(true);
        until CustLedgerEntry2.Next() = 0;
        SetAppliesToIDAndPostEntry(CustLedgerEntry2, CustLedgerEntry);
    end;

    local procedure ComputeAmountFCY(CurrencyCode: Code[10]; Amount: Decimal): Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        if CurrencyCode = '' then
            exit(Amount);
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst();
        exit(Amount * CurrencyExchangeRate."Relational Exch. Rate Amount" / CurrencyExchangeRate."Exchange Rate Amount");
    end;

    local procedure ComputePaymentDiscountAmount(Amount: Decimal): Decimal
    var
        PaymentTerms: Record "Payment Terms";
    begin
        // Calculate Payment Discount Amount for a given Amount. Make sure that Amount has correct decimal places using Round.
        PaymentTerms.Get(GetPaymentTerms());
        exit(Round(Amount * PaymentTerms."Discount %" / 100));
    end;

    local procedure CreateAndPostMultipleJnlLines(var GenJournalLine: Record "Gen. Journal Line"; CurrencyCode: Code[10]; Amount: Decimal; Amount2: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        SelectGenJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, CreateCustomer(), GenJournalLine."Document Type"::Invoice, Amount, CurrencyCode);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account No.", GenJournalLine."Document Type"::"Credit Memo", Amount2,
          CurrencyCode);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", GetPaymentTerms());
        Customer.Validate("Application Method", Customer."Application Method"::Manual);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal; CurrencyCode: Code[10])
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
    end;

    local procedure GetCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        CustLedgerEntry.CalcFields("Remaining Amount");
    end;

    local procedure GetPaymentTerms(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        PaymentTerms.Validate("Calc. Pmt. Disc. on Cr. Memos", true);
        PaymentTerms.Modify(true);
        exit(PaymentTerms.Code);
    end;

    local procedure SetApplyCustomerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; AmountToApply: Decimal)
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, AmountToApply);
    end;

    local procedure SetAppliesToIDAndPostEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustLedgerEntry2: Record "Cust. Ledger Entry")
    begin
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry2);
    end;

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure VerifyDtldCustomerLedgerEntry(DocumentNo: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"; AmountLCY: Decimal; InvRoundingPrecisionLCY: Decimal)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedCustLedgEntry.SetRange("Entry Type", EntryType);
        DetailedCustLedgEntry.FindFirst();
        Assert.AreNearlyEqual(
          AmountLCY, DetailedCustLedgEntry."Amount (LCY)", InvRoundingPrecisionLCY,
          StrSubstNo(ErrorMessage, DetailedCustLedgEntry.FieldCaption("Amount (LCY)"), AmountLCY,
            DetailedCustLedgEntry.TableCaption(), DetailedCustLedgEntry.FieldCaption("Entry No."), DetailedCustLedgEntry."Entry No."));
    end;

    local procedure VerifyUnapplyGLEntry(DocumentNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Source Code", SourceCodeSetup."Unapplied Sales Entry Appln.");
        GLEntry.FindSet();
        repeat
            GLEntry.TestField("Document Type", GLEntry."Document Type"::Payment);
        until GLEntry.Next() = 0;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UnapplyCustomerEntriesPageHandler(var UnapplyCustomerEntries: TestPage "Unapply Customer Entries")
    begin
        UnapplyCustomerEntries.Unapply.Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;
}

