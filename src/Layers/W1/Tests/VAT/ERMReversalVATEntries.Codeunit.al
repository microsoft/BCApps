codeunit 134126 "ERM Reversal VAT Entries"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [VAT]
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
        AmountError: Label '%1 must be %2 in %3, %4=%5.';
        SumError: Label 'Sum of Amounts before and after reversal must be zero for the VAT Entries.';

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReversalWithNormalVAT()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Amount: Decimal;
    begin
        // Check Reversed VAT Amount and Amount in Purchase VAT Account after posting positive and negative Amount entries.

        // Setup: Find VAT Posting Setup with Calculation Type: Normal VAT. Update a GL Account with VAT Posting Groups and post
        // positive and negative entries for the GL Account. Calculate VAT Amount for verification after posting.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        PostGenJnlLineWithVATSetup(GenJournalLine, VATPostingSetup);
        Amount := GenJournalLine.Amount * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %");

        // Reverse the Posted Entries and verify that the Sum of Amounts Posted Before Reversal and After Reversal is zero and Amount in
        // Purchase VAT Account is calculated correctly in GL Entry.
        ReverseAndVerifyEntries(-Amount, GenJournalLine."Document No.", VATPostingSetup."Purchase VAT Account");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReversalWithReverseChargeVAT()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Amount: Decimal;
    begin
        // Check Reversed VAT Amount and Amount in Reverse Charge VAT Account after posting positive and negative Amount entries.

        // Setup: Find VAT Posting Setup with Calculation Type: Reverse Charge VAT. Update a GL Account with VAT Posting Groups and post
        // positive and negative entries for the GL Account. Calculate VAT Amount for verification after posting.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        PostGenJnlLineWithVATSetup(GenJournalLine, VATPostingSetup);
        Amount := GenJournalLine.Amount * VATPostingSetup."VAT %" / 100;

        // Reverse the Posted Entries and verify that the Sum of Amounts Posted Before Reversal and After Reversal is zero and Amount in
        // Reverse Charge VAT Account is calculated correctly in GL Entry.
        ReverseAndVerifyEntries(Amount, GenJournalLine."Document No.", VATPostingSetup."Reverse Chrg. VAT Acc.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReverseChargeVAT()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SavedVATPostingSetup: Record "VAT Posting Setup";
    begin
        // Test to check reverse Charge Entry.

        // Setup: Update General Ledger setup and VAT Posting Setup.
        Initialize();
        LibraryERM.FindVATPostingSetup(SavedVATPostingSetup, SavedVATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        LibraryERM.SetAddReportingCurrency(CreateCurrency());
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);

        UpdateRevChrgVATPostingSetup(LibraryERM.CreateGLAccountNo(), true);

        // Exercise: Create and Post General Journal Line.
        CreateAndPostGenJournalLines(
          GenJournalLine, CreateCustomer(), GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Document Type"::Payment);

        // Verify: Verify Remaining Amount in Customer Ledger Entry and Additional Currency Amount In G/L Entry.
        VerifyCustomerAndGLEntry(
          GenJournalLine."Document No.", GenJournalLine."Account No.", GenJournalLine."Document Type"::Payment, -GenJournalLine.Amount);

        // Tear Down: Cleanup of setups done.
        UpdateRevChrgVATPostingSetup(SavedVATPostingSetup."Reverse Chrg. VAT Acc.", SavedVATPostingSetup."Adjust for Payment Discount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountOnGeneralJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        VATAmount: Decimal;
        Amount: Decimal;
    begin
        // Check VAT Amount correctly updated on General Journal Line.

        // Setup: Find General Journal Batch, take Random Amount for General Journal Line.
        Initialize();
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        VATPostingSetup.Get(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group");
        Amount := LibraryRandom.RandDec(100, 3);
        VATAmount := Round(Amount * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %"));
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);

        // Exercise. Create General Journal Line with GL Account having VAT Posting Setup attached.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Account Type"::"G/L Account",
          GenJournalLine."Document Type"::" ", GLAccount."No.", Amount);

        // Verify: Verify VAT Amount correctly updated on General Jounral Line.
        GenJournalLine.Get(GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Line No.");
        GenJournalLine.TestField("VAT Amount", VATAmount);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Reversal VAT Entries");
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Reversal VAT Entries");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
        IsInitialized := true;
        Commit();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Reversal VAT Entries");
    end;

    local procedure PostGenJnlLineWithVATSetup(var GenJournalLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup")
    var
        GLAccount: Record "G/L Account";
    begin
        // Update GL Account With VAT Accounts. Create and Post General Journal Lines.
        GLAccount."No." := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);
        CreateAndPostGenJournalLines(
          GenJournalLine, GLAccount."No.", GenJournalLine."Account Type"::"G/L Account", GenJournalLine."Document Type",
          GenJournalLine."Document Type");
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Validate("Application Method", Customer."Application Method"::"Apply to Oldest");
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Get(LibraryERM.CreateCurrencyWithGLAccountSetup());
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateAndPostGenJournalLines(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; AccountType: Enum "Gen. Journal Account Type"; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Create General Journal Lines with Random Positive and Negative Amounts and Account Type: G/L Account.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo,
          LibraryRandom.RandDec(10, 2));  // Use Random Number Generator for Amount.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType2, AccountType, AccountNo,
          -GenJournalLine.Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure ReverseAndVerifyEntries(Amount: Decimal; DocumentNo: Code[20]; AccountNo: Code[20])
    var
        GLRegister: Record "G/L Register";
        ReversalEntry: Record "Reversal Entry";
        VATAmtBeforeReversal: Decimal;
    begin
        // Compute total VAT Amount in VAT Entry before Reversal.
        VATAmtBeforeReversal := ComputeVATAmtInVATEntry(GLRegister);

        // Exercise: Reverse the entries posted from General Journal Lines.
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseRegister(GLRegister."No.");

        // Verify: Verify that sum of Amounts is zero in VAT Entries after reversal. Verify Amount in GL Entry as per Account selected.
        Assert.AreEqual(0, VATAmtBeforeReversal + ComputeVATAmtInVATEntry(GLRegister), SumError);
        VerifyAmountInGLEntry(GLRegister, AccountNo, DocumentNo, Amount);
    end;

    local procedure ComputeVATAmtInVATEntry(var GLRegister: Record "G/L Register") Amount: Decimal
    var
        VATEntry: Record "VAT Entry";
    begin
        GLRegister.FindLast();
        VATEntry.SetRange("Entry No.", GLRegister."From VAT Entry No.", GLRegister."To VAT Entry No.");
        VATEntry.FindSet();
        repeat
            Amount += VATEntry.Amount;
        until VATEntry.Next() = 0;
    end;

    local procedure UpdateRevChrgVATPostingSetup(ReverseChrgVATAcc: Code[20]; AdjustforPaymentDiscount: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        VATPostingSetup.Validate("Adjust for Payment Discount", AdjustforPaymentDiscount);
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", ReverseChrgVATAcc);
        VATPostingSetup.Modify(true);
    end;

    local procedure VerifyAmountInGLEntry(GLRegister: Record "G/L Register"; GLAccountNo: Code[20]; DocumentNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, LibraryERM.GetInvoiceRoundingPrecisionLCY(), StrSubstNo(AmountError, GLEntry.FieldCaption(Amount),
            Amount, GLEntry.TableCaption(), GLEntry.FieldCaption("Entry No."), GLEntry."Entry No."));
    end;

    local procedure VerifyCustomerAndGLEntry(DoumentNo: Code[20]; BalAccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GLEntry: Record "G/L Entry";
        AdditionalCurrencyAmount: Decimal;
    begin
        AdditionalCurrencyAmount :=
          Round(LibraryERM.ConvertCurrency(Amount, '', LibraryERM.GetAddReportingCurrency(), WorkDate()));
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DoumentNo);
        CustLedgerEntry.CalcFields("Remaining Amount");
        CustLedgerEntry.TestField("Remaining Amount", 0);

        GLEntry.SetRange("Document No.", DoumentNo);
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Bal. Account No.", BalAccountNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          AdditionalCurrencyAmount, GLEntry."Additional-Currency Amount", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountError, GLEntry.FieldCaption("Additional-Currency Amount"), AdditionalCurrencyAmount,
            GLEntry.TableCaption(), GLEntry.FieldCaption("Entry No."), GLEntry."Entry No."));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        // Confirm Handler.
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;
}

