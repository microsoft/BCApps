codeunit 144001 "ERM Partial Pmt Customer ES"
{
    // 1. Test VAT Amount on General Journal Line when VAT % more than Zero.
    // 2. Test VAT Amount on General Journal Line when VAT % Zero.
    // 3. Verify VAT Amount Zero on G/L Entry when General Journal Line Posted with VAT % Zero.
    // 
    // Covers Test Cases for WI - 288499
    //   -----------------------------------------------------------------------------------------------------
    //   Test Function Name                                                                          TFS ID
    //   -----------------------------------------------------------------------------------------------------
    //   VATAmountOnGeneralJournalLineWithVATPctMoreThanZero
    //   VATAmountOnGeneralJournalLineWithVATPctZero,VATAmountZeroOnGLEntry                         288499

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        GeneralJournalTemplateName: Code[10];

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountOnGeneralJournalLineWithVATPctMoreThanZero()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Test VAT Amount on General Journal Line when VAT % more than Zero.

        // Setup.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VerifyVATAmountOnGeneralJournalLine(VATPostingSetup."VAT Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountOnGeneralJournalLineWithVATPctZero()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Test VAT Amount on General Journal Line when VAT % Zero.

        // Setup.
        Initialize();
        FindVATPostingSetupWithZeroVAT(VATPostingSetup);
        VerifyVATAmountOnGeneralJournalLine(VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure VerifyVATAmountOnGeneralJournalLine(VATProductPostingGroup: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATAmount: Decimal;
    begin
        // Create General Journal Line with GL Account.
        CreateGeneralJournalLineWithAccountTypeGL(GenJournalLine);

        // Exercise: Update General Journal Line with VAT Prod. Posting Group with VAT %.
        UpdateGeneralJournalLine(GenJournalLine, VATProductPostingGroup);
        VATAmount := Round(GenJournalLine.Amount * GenJournalLine."VAT %" / (100 + GenJournalLine."VAT %"));

        // Verify: Verify VAT Amount on General Journal Line.
        GenJournalLine.TestField("VAT Amount", VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountZeroOnGLEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATAmount: Decimal;
    begin
        // Verify VAT Amount Zero on G/L Entry when General Journal Posted with VAT % Zero.

        // Setup.
        Initialize();
        CreateGeneralJournalLineWithAccountTypeGL(GenJournalLine);
        FindVATPostingSetupWithZeroVAT(VATPostingSetup);
        UpdateGeneralJournalLine(GenJournalLine, VATPostingSetup."VAT Prod. Posting Group");
        VATAmount := Round(GenJournalLine.Amount * GenJournalLine."VAT %" / (100 + GenJournalLine."VAT %"));

        // Exercise: Post General Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify VAT Amount on G/L Entry.
        VerifyVATAmountOnGLEntry(GenJournalLine."Document No.", VATAmount);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        GeneralJournalTemplateName := '';  // Reset global variable.

        // Lazy Setup.
        if isInitialized then
            exit;

        LibraryERMCountryData.CreateVATData();
        isInitialized := true;
        Commit();
    end;

    local procedure CreateGeneralJournalLineWithAccountTypeGL(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Modify General Journal Batch and Create General Journal Line.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", CreateGLAccountWithVATPostingGroup(), LibraryRandom.RandDecInRange(100, 1000, 2));
    end;

    local procedure CreateGLAccountWithVATPostingGroup(): Code[20]
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Purchase);
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure FindVATPostingSetupWithZeroVAT(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", '<>%1', '');
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>%1', '');
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.SetRange("VAT %", 0);  // Select VAT Posting Setup with VAT % Zero.
        VATPostingSetup.FindFirst();
    end;

    local procedure UpdateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; VATProductPostingGroup: Code[20])
    begin
        GenJournalLine.Validate("VAT Prod. Posting Group", VATProductPostingGroup);
        GenJournalLine.Modify(true);
    end;

    local procedure VerifyVATAmountOnGLEntry(DocumentNo: Code[20]; VATAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
        GLEntry.TestField("VAT Amount", VATAmount);
    end;
}

