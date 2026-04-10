codeunit 134288 "Non-Deductible VAT Journal"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Non Deductible VAT]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryNonDeductibleVAT: Codeunit "Library - NonDeductible VAT";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        ReverseEntriesQst: Label 'Do you want to reverse the entries';
        EntriesReversedLbl: Label 'The entries were successfully reversed';
        NonDeductiableVATAmountMustBeEqualErr: Label 'Non-Deductable VAT Amount must be %1 in VAT Entries', Comment = '%1 = Expected Non-Deductible VAT Amount';

    [Test]
    [Scope('OnPrem')]
    procedure NonDeductibleAmountInGLEntryAfterPostingFromJournal()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
    begin
        // [SCENARIO 474027] Non-Deductible VAT Amount is specified in the G/L entry created after posting from the journal

        Initialize();
        // [GIVEN] VAT Posting Setup with "VAT %" = 20, "Non-Deductible %" = 10
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        // [GIVEN] General journal line with Non-Deductible VAT Setup and Amount = 1000
        LibraryJournals.CreateGenJournalLineWithBatch(
            GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
            LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase), LibraryRandom.RandDec(100, 2));
        // [WHEN] Post general journal line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        // [THEN] "Non-Deductible VAT Amount" in VAT G/L Entry is 20
        GLEntry.SetRange("Posting Date", GenJournalLine."Posting Date");
        GLEntry.SetRange("Document No.", GenJournalLine."Document No.");
        GLEntry.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLEntry.FindFirst();
        // [THEN] "Non-Deductible VAT Amount" is zero in all non-VAT G/L entries
        GLEntry.TestField("Non-Deductible VAT Amount", Round(GenJournalLine."VAT Amount" * VATPostingSetup."Non-Deductible VAT %" / 100));
        GLEntry.SetRange("VAT Bus. Posting Group", '');
        GLEntry.SetRange("VAT Prod. Posting Group", '');
        GLEntry.FindSet();
        repeat
            GLEntry.TestField("Non-Deductible VAT Amount", 0);
        until GLEntry.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure NonDeductibleVATIsCorrectInReversedEntries()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        GLRegister: Record "G/L Register";
        ReversalEntry: Record "Reversal Entry";
        VATEntry: Record "VAT Entry";
    begin
        // [SCENARIO 474027] Non-Deductible VAT is correct in reversed entries

        Initialize();
        // [GIVEN] VAT Posting Setup with "VAT %" = 20, "Non-Deductible %" = 10
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        // [GIVEN] General journal line with Non-Deductible VAT Setup and Amount = 1000
        LibraryJournals.CreateGenJournalLineWithBatch(
            GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
            LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase), LibraryRandom.RandDec(100, 2));
        // [WHEN] Post general journal line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        // [THEN] "Non-Deductible VAT Amount" in VAT G/L Entry is 20
        GLEntry.SetRange("Posting Date", GenJournalLine."Posting Date");
        GLEntry.SetRange("Document No.", GenJournalLine."Document No.");
        GLEntry.FindFirst();
        GLRegister.SetFilter("From Entry No.", '..%1', GLEntry."Entry No.");
        GLRegister.SetFilter("To Entry No.", '%1..', GLEntry."Entry No.");
        GLRegister.FindFirst();
        ReversalEntry.SetHideDialog(true);
        LibraryVariableStorage.Enqueue(ReverseEntriesQst);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(EntriesReversedLbl);

        // [WHEN] Reverse G/L register
        ReversalEntry.ReverseRegister(GLRegister."No.");

        // [THEN]
        GLEntry.CalcSums("Non-Deductible VAT Amount");
        GLEntry.TestField("Non-Deductible VAT Amount", 0);

        // [THEN]
        VATEntry.SetRange("Posting Date", GenJournalLine."Posting Date");
        VATEntry.SetRange("Document No.", GenJournalLine."Document No.");
        VATEntry.CalcSums("Non-Deductible VAT Base", "Non-Deductible VAT Amount");
        VATEntry.TestField("Non-Deductible VAT Base", 0);
        VATEntry.TestField("Non-Deductible VAT Amount", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure JnlLineWithTwoAccountsOneNormalVATWithNDOtherNoVATNoND()
    var
        NDVATPostingSetup: Record "VAT Posting Setup";
        NoVATVATPostingSetup: Record "VAT Posting Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccountNDVATNo: Code[20];
        GLAccountNoVATNo: Code[20];
    begin
        // [SCENARIO 481217] Stan can post a journal line with two accounts, one with normal VAT with non-deductible VAT and the other with no VAT and no non-deductible VAT

        Initialize();
        // [GIVEN] VAT Posting Setup "A" with "VAT %" = 20, "Non-Deductible %" = 10
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(NDVATPostingSetup);
        // [GIVEN] VAT Posting Setup "B" with "VAT %" = 0, "Non-Deductible %" = 0
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(NoVATVATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        NoVATVATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        NoVATVATPostingSetup.Modify(true);
        // [GIVEN] G/L Account "X" with VAT Posting Setup "A"
        GLAccountNDVATNo := LibraryERM.CreateGLAccountWithVATPostingSetup(NDVATPostingSetup, "General Posting Type"::Purchase);
        // [GIVEN] G/L Account "Y" with VAT Posting Setup "B"
        GLAccountNoVATNo := LibraryERM.CreateGLAccountWithVATPostingSetup(NoVATVATPostingSetup, "General Posting Type"::Purchase);
        // [GIVEN] General journal line with "Account No." = "A" and "Bal. Account No." = "B"
        LibraryJournals.CreateGenJournalLineWithBatch(
            GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", GLAccountNDVATNo, LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Bal. Account No.", GLAccountNoVATNo);
        GenJournalLine.Modify(true);
        // [WHEN] Post general journal line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        // [THEN] Only Non-Deductible VAT from the account "X" is posted
        VerifyTotalNDAmountsInVATEntries(
            GenJournalLine."Posting Date", GenJournalLine."Document No.", GenJournalLine."Non-Deductible VAT Base", GenJournalLine."Non-Deductible VAT Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonDeductibleAmountInGLEntryAfterPostingFromJournalBalAcc()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
    begin
        // [SCENARIO 481217] Non-Deductible VAT Amount is specified in the G/L entry created after posting from the journal on the balance account side

        Initialize();
        // [GIVEN] VAT Posting Setup with "VAT %" = 20, "Non-Deductible %" = 10
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        // [GIVEN] General journal line with Non-Deductible VAT Setup on the "Bal. Account No." and Amount = 1000
        LibraryJournals.CreateGenJournalLineWithBatch(
            GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
            LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase));
        GenJournalLine.Modify(true);
        // [WHEN] Post general journal line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        // [THEN] "Non-Deductible VAT Amount" in VAT G/L Entry is 20
        GLEntry.SetRange("Posting Date", GenJournalLine."Posting Date");
        GLEntry.SetRange("Document No.", GenJournalLine."Document No.");
        GLEntry.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLEntry.FindFirst();
        // [THEN] "Non-Deductible VAT Amount" is zero in all non-VAT G/L entries
        // Bug 523795: Bal. Non-Deductible VAT amount is not correct 
        GLEntry.TestField("Non-Deductible VAT Amount", Round(GenJournalLine."Bal. VAT Amount" * VATPostingSetup."Non-Deductible VAT %" / 100));
        GLEntry.SetRange("VAT Bus. Posting Group", '');
        GLEntry.SetRange("VAT Prod. Posting Group", '');
        GLEntry.FindSet();
        repeat
            GLEntry.TestField("Non-Deductible VAT Amount", 0);
        until GLEntry.Next() = 0;
    end;

    [Test]
    procedure BalNonDeductibleVATPctInGenJournalLineAfterValidatingBalVATBusAndProdPostingGroup()
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [SCENARIO 523795] Bal. Non-Deductible VAT % is correctly set in Gen. Journal Line after validating Bal. VAT Bus. & Prod. Posting Group fields
        Initialize();

        // [GIVEN] Create Non-Deductible VAT Posting Setup with s"Non-Deductible VAT %" = "X"
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);

        // [GIVEN] General journal line with Non-Deductible VAT Setup on the "Bal. Account No."
        LibraryJournals.CreateGenJournalLineWithBatch(
            GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
            LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase));

        // [WHEN] Validate Bal. VAT Bus. & Prod. Posting Group fields
        GenJournalLine.Validate("Bal. VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GenJournalLine.Validate("Bal. VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GenJournalLine.Modify(true);

        // [THEN] "Bal. Non-Ded. VAT %" is "X"
        GenJournalLine.TestField("Bal. Non-Ded. VAT %", VATPostingSetup."Non-Deductible VAT %");
    end;

    [Test]
    procedure NonDeductibleVATShouldShowAsNonDeductibleOnDoingFullVAT()
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        NonDeductableVATAmount: Decimal;
    begin
        // [SCENARIO 537128] On posting Non-Deductible full VAT amount should be display in Non-Deductable VAT field of VAT Entry. 
        Initialize();

        // [GIVEN] Create Non-Deductible VAT Posting Setup with "Non-Deductible VAT %" = 100.
        LibraryNonDeductibleVAT.CreatVATPostingSetupAllowedForNonDeductibleVAT(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Full VAT", 100);
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase));
        VATPostingSetup.Validate("Non-Deductible VAT %", 100);
        VATPostingSetup.Modify(true);

        // [GIVEN] General Journal Line with Non-Deductible VAT Posting Setup and "Account No" = VATPostingSetup."Purchase VAT Account".
        LibraryJournals.CreateGenJournalLineWithBatch(
            GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
            VATPostingSetup."Purchase VAT Account", LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());

        // [GIVEN] Validate VAT Bus. & Prod. Posting Group fields.
        GenJournalLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GenJournalLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GenJournalLine.Modify(true);
        NonDeductableVATAmount := GenJournalLine.Amount;

        // [WHEN] Post the General Journal.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify that "Non-Deductible VAT Amount" field must have the value in VAT Entry.
        FindVATEntryByVATPostingSetup(VATEntry, VATPostingSetup);
        Assert.AreEqual(NonDeductableVATAmount, VATEntry."Non-Deductible VAT Amount", StrSubstNo(NonDeductiableVATAmountMustBeEqualErr, NonDeductableVATAmount));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Non-Deductible VAT Journal");
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Non-Deductible VAT Journal");
        LibraryNonDeductibleVAT.EnableNonDeductibleVAT();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibrarySetupStorage.Save(Database::"VAT Setup");
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Non-Deductible VAT Journal");
    end;

    local procedure VerifyTotalNDAmountsInVATEntries(PostingDate: Date; DocumentNo: Code[20]; NDBase: Decimal; NDAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Posting Date", PostingDate);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.CalcSums("Non-Deductible VAT Base", "Non-Deductible VAT Amount");
        VATEntry.Testfield("Non-Deductible VAT Base", NDBase);
        VATEntry.Testfield("Non-Deductible VAT Amount", NDAmount);
    end;

    local procedure FindVATEntryByVATPostingSetup(var VATENtry: Record "VAT Entry"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATEntry.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        VATEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATEntry.FindLast();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message);
    end;
}