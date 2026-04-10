codeunit 134125 "ERM Reversal Change VAT Amount"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [VAT]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;
        AmountError: Label '%1 must be %2 in %3, %4=%5.';

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure VATWithPositiveAmount()
    begin
        // Check that correct VAT Amount calculated in GL Entries after posting entry with positive Amount and Reversing them.
        // Take Random Amount greater than 1000 to make sure that VAT Difference Amount updated correctly in General Journal Lines.
        Initialize();
        VATAmountOnGeneralJournalLine(1000 + LibraryRandom.RandDec(50, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure VATWithNegativeAmount()
    begin
        // Check that correct VAT Amount calculated in GL Entries after posting entry with negative Amount and Reversing them.
        // Take Random Amount greater than 1000 to make sure that VAT Difference Amount will update correctly in General Journal Lines.
        Initialize();
        VATAmountOnGeneralJournalLine(-(1000 + LibraryRandom.RandDec(50, 2)));
    end;

    local procedure VATAmountOnGeneralJournalLine(Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        GLRegister: Record "G/L Register";
        ReversalEntry: Record "Reversal Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        VATAmount: Decimal;
        MaxVATDiffAmount: Decimal;
        MaxVATDiffAllowed: Decimal;
        AllowVATDifference: Boolean;
    begin
        // Setup: Find VAT Posting Setup with Normal VAT, Update General Ledger Setup and General Journal Template. Find a GL Account and
        // Post entry for it after updating VAT Amount on General Journal Line. Take Random Amount for Max. VAT Difference. Store Original
        // Values of setups to use them at Tear Down.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        MaxVATDiffAmount := LibraryRandom.RandDec(1, 2);
        MaxVATDiffAllowed := UpdateGeneralLedgerSetup(Amount);
        AllowVATDifference := UpdateGeneralJournalTemplate(GenJournalBatch."Journal Template Name", true);

        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        VATPostingSetup.Get(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group");
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalBatch, GLAccount."No.", Amount, MaxVATDiffAmount, GenJournalLine."Document Type"::" ");
        VATAmount := Round(Amount * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %")) + MaxVATDiffAmount;

        // Exercise: Reverse the entries posted from General Journal Lines.
        GLRegister.FindLast();
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseRegister(GLRegister."No.");

        // Verify: Verify the updated VAT Amount on Reversed GL Entries.
        VerifyVATAmount(GenJournalLine, -VATAmount);

        // Tear Down: Rollback Setups done.
        UpdateGeneralLedgerSetup(MaxVATDiffAllowed);
        UpdateGeneralJournalTemplate(GenJournalBatch."Journal Template Name", AllowVATDifference);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATDifferenceWithPurchase()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify VAT Amount on G/L Entry and VAT Entry with Allow VAT Difference and Gen. Posting Type as Purchase.
        Initialize();
        VATDifferenceWithDocument(GenJournalLine."Gen. Posting Type"::Purchase, LibraryERM.CreateGLAccountWithPurchSetup());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATDifferenceWithSale()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify VAT Amount on G/L Entry and VAT Entry with Allow VAT Difference and Gen. Posting Type as Sale.
        Initialize();
        VATDifferenceWithDocument(GenJournalLine."Gen. Posting Type"::Sale, LibraryERM.CreateGLAccountWithSalesSetup());
    end;

    local procedure VATDifferenceWithDocument(GenPostingType: Enum "General Posting Type"; GLAccountNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        AllowVATDifference: Boolean;
        MaxVATDiffAmount: Decimal;
        OldMaxVATDiffAmount: Decimal;
        Amount: Decimal;
    begin
        // Setup: Create Setup for Max. VAT Difference Allowed on General Ledger Setup and General Journal Template.
        MaxVATDiffAmount := LibraryRandom.RandDec(5, 2);
        Amount := LibraryRandom.RandDec(100, 2);
        OldMaxVATDiffAmount := UpdateGeneralLedgerSetup(MaxVATDiffAmount);
        AllowVATDifference := CreateSetupForJournalBatch(GenJournalBatch);

        // Exercise: Create and Post General Journal Lines with Maximum VAT Difference Amount.
        if GenPostingType = GenJournalLine."Gen. Posting Type"::Purchase then begin
            Amount := -Amount;
            MaxVATDiffAmount := -MaxVATDiffAmount;
        end;

        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalBatch, GLAccountNo, Amount, MaxVATDiffAmount, GenJournalLine."Document Type"::Payment);

        // Verify: Verify VAT Amount on G/L Entry and Amount on VAT Entry.
        VerifyVATAmountOnGLEntry(GenJournalLine);
        VerifyAmountOnVATEntry(GenJournalLine);

        // Tear Down: Rollback Setups done.
        UpdateGeneralLedgerSetup(OldMaxVATDiffAmount);
        UpdateGeneralJournalTemplate(GenJournalBatch."Journal Template Name", AllowVATDifference);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Reversal Change VAT Amount");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Reversal Change VAT Amount");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Reversal Change VAT Amount");
    end;

    local procedure CreateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountNo: Code[20]; Amount: Decimal; VATAmount: Decimal; DocumentType: Enum "Gen. Journal Document Type")
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::"G/L Account", AccountNo, Amount);
        GenJournalLine.Validate("VAT Amount", GenJournalLine."VAT Amount" + VATAmount);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateSetupForJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch") AllowVATDifference: Boolean
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        AllowVATDifference := UpdateGeneralJournalTemplate(GenJournalBatch."Journal Template Name", true);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure UpdateGeneralJournalTemplate(JournalTemplateName: Code[10]; AllowVATDifference: Boolean) AllowVATDiffOriginal: Boolean
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Get(JournalTemplateName);
        AllowVATDiffOriginal := GenJournalTemplate."Allow VAT Difference";
        GenJournalTemplate.Validate("Allow VAT Difference", AllowVATDifference);
        GenJournalTemplate.Modify(true);
    end;

    local procedure UpdateGeneralLedgerSetup(MaxVATDifferenceAllowed: Decimal) OriginalVATDifference: Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        OriginalVATDifference := GeneralLedgerSetup."Max. VAT Difference Allowed";
        GeneralLedgerSetup.Validate("Max. VAT Difference Allowed", MaxVATDifferenceAllowed);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure VerifyVATAmount(GenJournalLine: Record "Gen. Journal Line"; VATAmount: Decimal)
    var
        GLRegister: Record "G/L Register";
        GLEntry: Record "G/L Entry";
    begin
        GLRegister.FindLast();
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        GLEntry.SetRange("Document No.", GenJournalLine."Document No.");
        GLEntry.SetRange("G/L Account No.", GenJournalLine."Account No.");
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          VATAmount, GLEntry."VAT Amount", LibraryERM.GetInvoiceRoundingPrecisionLCY(),
          StrSubstNo(AmountError, GLEntry.FieldCaption("VAT Amount"),
            VATAmount, GLEntry.TableCaption(), GLEntry.FieldCaption("Entry No."), GLEntry."Entry No."));
    end;

    local procedure VerifyVATAmountOnGLEntry(GenJournalLine: Record "Gen. Journal Line")
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", GenJournalLine."Document No.");
        GLEntry.SetRange("G/L Account No.", GenJournalLine."Account No.");
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          GenJournalLine."VAT Amount", GLEntry."VAT Amount", LibraryERM.GetInvoiceRoundingPrecisionLCY(),
          StrSubstNo(
            AmountError, GLEntry.FieldCaption("VAT Amount"), GenJournalLine."VAT Amount", GLEntry.TableCaption(), GLEntry.FieldCaption("Entry No."), GLEntry."Entry No."));
    end;

    local procedure VerifyAmountOnVATEntry(GenJournalLine: Record "Gen. Journal Line")
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", GenJournalLine."Document No.");
        VATEntry.FindFirst();
        Assert.AreNearlyEqual(
          GenJournalLine."VAT Amount", VATEntry.Amount, LibraryERM.GetInvoiceRoundingPrecisionLCY(),
          StrSubstNo(
            AmountError, VATEntry.FieldCaption(Amount), GenJournalLine."VAT Amount", VATEntry.TableCaption(), VATEntry.FieldCaption("Entry No."), VATEntry."Entry No."));
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

