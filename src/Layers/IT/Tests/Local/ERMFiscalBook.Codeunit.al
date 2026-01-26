codeunit 144075 "ERM Fiscal Book"
{
    // 1. Test to validate G/L Book Entry after Reverse Register on G/L Register without VAT and with same Document No.
    // 2. Test to validate G/L Book Entry after Reverse Register on G/L Register with VAT and different Document No.
    // 3. Test to validate field Last Printed VAT Register Page exists on page VAT Registers Page.
    // 4. Test that controls are properly showing on VAT Register - Print report's Request Page.
    // 5. Test that controls are properly showing on VAT Register - Print report's Request Page.
    // 6. Test that Last Printed G/L Book Page field is available and enabled on General Ledger Setup Page.
    // 
    // Covers Test Cases for WI - 346695
    // ---------------------------------------------------------------------------------------------
    // Test Function Name                                                                     TFS ID
    // ---------------------------------------------------------------------------------------------
    // ReverseRegisterAfterPostGeneralJournalWithoutVAT                         154713,154715,154716
    // ReverseRegisterAfterPostGeneralJournalWithVAT                            154717,154718,154720
    // VATRegistersWithLastPrintedVATRegisterPage                                             154686
    // 
    // Covers Test Cases for WI - 346954
    // -------------------------------------------------------------------------------
    // Test Function Name                                                     TFS ID
    // -------------------------------------------------------------------------------
    // VATRegisterPrintRequestPageControls                                    154777
    // GLBookPrintRequestPageControls                                         154685
    // FiscalBookFieldsOnGLSetupPage                                   154684,154685

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        EditableErr: Label 'Field %1 must be Editable.';
        EnabledErr: Label 'Field %1 must be Enabled.';
        FieldVisibleErr: Label 'Field must be Visible.';
        GreaterThanFilterTxt: Label '>%1';
        LessThanFilterTxt: Label '<%1';
        ValueEqualErr: Label 'Value must be equal.';

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,ReverseEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure ReverseRegisterAfterPostGeneralJournalWithoutVAT()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ReversalEntry: Record "Reversal Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
    begin
        // Test to validate G/L Book Entry after Reverse Register on G/L Register without VAT and with same Document No.

        // Setup: Create and post General Journal Line without VAT.
        DocumentNo := LibraryUtility.GenerateGUID();
        FindVATPostingSetupWithZeroVAT(VATPostingSetup);
        CreateAndPostGeneralJournalLine(GenJournalLine, VATPostingSetup, DocumentNo, DocumentNo);  // Same Document No on multiple line of General Journal Line.

        // Exercise: Reverse Register on G/L Register.
        ReversalEntry.ReverseRegister(FindGLRegister(GenJournalLine."Journal Batch Name"));  // Opens ReverseEntriesPageHandler.

        // Verify: Verify Debit Amount and Credit Amount on G/L Book Entry.
        VerifyGLBookEntry(LessThanFilterTxt, GenJournalLine."Account No.", DocumentNo, DocumentNo, -GenJournalLine.Amount, 0);  // Credit Amount must be 0.
        VerifyGLBookEntry(GreaterThanFilterTxt, GenJournalLine."Bal. Account No.", DocumentNo, DocumentNo, 0, -GenJournalLine.Amount);  // Debit Amount must be 0.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,ReverseEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure ReverseRegisterAfterPostGeneralJournalWithVAT()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ReversalEntry: Record "Reversal Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        VATAmount: Decimal;
    begin
        // Test to validate G/L Book Entry after Reverse Register on G/L Register with VAT and different Document No.
        // Setup.
        DocumentNo := LibraryUtility.GenerateGUID();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateAndPostGeneralJournalLine(GenJournalLine, VATPostingSetup, DocumentNo, LibraryUtility.GenerateGUID());  // Different Document No on multiple lines of General Journal Line.
        VATAmount := (GenJournalLine.Amount * 100) / (VATPostingSetup."VAT %" + 100);  // Calculate VAT Amount.

        // Exercise: Reverse Register on G/L Register.
        ReversalEntry.ReverseRegister(FindGLRegister(GenJournalLine."Journal Batch Name"));  // Opens ReverseEntriesPageHandler.

        // Verify: Verify Debit Amount and Credit Amount on G/L Book Entry.
        VerifyGLBookEntry(LessThanFilterTxt, GenJournalLine."Account No.", DocumentNo, GenJournalLine."Document No.", -Round(VATAmount), 0);  // Credit Amount must be 0.
        VerifyGLBookEntry(
          GreaterThanFilterTxt, GenJournalLine."Bal. Account No.", DocumentNo, GenJournalLine."Document No.", 0, -GenJournalLine.Amount);  // Debit Amount must be 0.
        VerifyGLBookEntry(
          LessThanFilterTxt, VATPostingSetup."Purchase VAT Account", DocumentNo, GenJournalLine."Document No.",
          -Round(GenJournalLine.Amount - VATAmount), 0);  // Credit Amount must be 0.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATRegistersWithLastPrintedVATRegisterPage()
    var
        VATRegisters: TestPage "VAT Registers";
    begin
        // Test to validate field Last Printed VAT Register Page exists on VAT Registers Page.
        // Exercise.
        VATRegisters.OpenEdit();

        // Verify: Verify field Last Printed VAT Register Page exists on VAT Registers Page.
        Assert.IsTrue(VATRegisters."Last Printed VAT Register Page".Visible(), FieldVisibleErr);

        // Tear down.
        VATRegisters.Close();
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATRegisterPrintRequestPageControls()
    begin
        // Check that controls are properly showing on VAT Register - Print report's Request Page.

        // Exercise:
        REPORT.Run(REPORT::"VAT Register - Print");  // Invoke VATRegisterPrintRequestPageHandler.

        // Verify: Verify that controls are correctly showing control values on VATRegisterPrintRequestPageHandler. Verification done on Request Page Handler.
    end;

    [Test]
    [HandlerFunctions('GLBookPrintRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GLBookPrintRequestPageControls()
    begin
        // Check that controls are properly showing on G/L Book - Print report's Request Page.

        // Setup.
        // Exercise.
        REPORT.Run(REPORT::"G/L Book - Print");  // Invoke GLBookPrintRequestPageHandler.

        // Verify: Verify that controls are correctly showing control values on GLBookPrintRequestPageHandler. Verification done on Request Page Handler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FiscalBookFieldsOnGLSetupPage()
    var
        GeneralLedgerSetup: TestPage "General Ledger Setup";
    begin
        // Test that Last Printed G/L Book Page field is available and enabled on General Ledger Setup Page.

        // Exercise.
        GeneralLedgerSetup.OpenEdit();

        // Verify: Verify that Field is editable and enabled on GL Setup Page.
        Assert.IsTrue(
          GeneralLedgerSetup."Last Printed G/L Book Page".Enabled(),
          StrSubstNo(EnabledErr, GeneralLedgerSetup."Last Printed G/L Book Page".Caption));
        Assert.IsTrue(
          GeneralLedgerSetup."Last Printed G/L Book Page".Editable(),
          StrSubstNo(EditableErr, GeneralLedgerSetup."Last Printed G/L Book Page".Caption));

        // Tear Down.
        GeneralLedgerSetup.Close();
    end;

    local procedure CreateAndPostGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"; DocumentNo: Code[20]; DocumentNo2: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGeneralJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, VATPostingSetup, CreateGLAccount(), CreateGLAccount(), DocumentNo, LibraryRandom.RandDec(100, 2));  // Using random Amount.
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, VATPostingSetup, GenJournalLine."Account No.",
          GenJournalLine."Bal. Account No.", DocumentNo2, GenJournalLine.Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; VATPostingSetup: Record "VAT Posting Setup"; AccountNo: Code[20]; BalAccountNo: Code[20]; DocumentNo: Code[20]; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::"G/L Account", AccountNo, Amount);
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GenJournalLine.Validate("Gen. Posting Type", GenJournalLine."Gen. Posting Type"::Purchase);
        GenJournalLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::General);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure FindGLRegister(JournalBatchName: Code[10]): Integer
    var
        GLRegister: Record "G/L Register";
    begin
        GLRegister.SetRange("Journal Batch Name", JournalBatchName);
        GLRegister.FindFirst();
        exit(GLRegister."No.");
    end;

    local procedure FindVATPostingSetupWithZeroVAT(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", '<>''''');
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>''''');
        VATPostingSetup.SetRange("VAT %", 0);
        VATPostingSetup.FindFirst();
    end;

    local procedure VerifyAmountsOnGLBookEntry(GLBookEntry: Record "GL Book Entry"; DocumentNo: Code[20]; DebitAmount: Decimal; CreditAmount: Decimal)
    begin
        GLBookEntry.CalcFields("Debit Amount", "Credit Amount");
        Assert.AreNearlyEqual(DebitAmount, GLBookEntry."Debit Amount", LibraryERM.GetAmountRoundingPrecision(), ValueEqualErr);
        Assert.AreNearlyEqual(CreditAmount, GLBookEntry."Credit Amount", LibraryERM.GetAmountRoundingPrecision(), ValueEqualErr);
        Assert.AreEqual(DocumentNo, GLBookEntry."Document No.", ValueEqualErr);
    end;

    local procedure VerifyGLBookEntry(AmountFilter: Text; GLAccountNo: Code[20]; DocumentNo: Code[20]; DocumentNo2: Code[20]; DebitAmount: Decimal; CreditAmount: Decimal)
    var
        GLBookEntry: Record "GL Book Entry";
    begin
        GLBookEntry.SetFilter(Amount, AmountFilter, 0);
        GLBookEntry.SetRange("Document Type", GLBookEntry."Document Type"::Payment);
        GLBookEntry.SetRange("G/L Account No.", GLAccountNo);
        GLBookEntry.FindSet();
        VerifyAmountsOnGLBookEntry(GLBookEntry, DocumentNo2, DebitAmount, CreditAmount);
        GLBookEntry.Next();
        VerifyAmountsOnGLBookEntry(GLBookEntry, DocumentNo, DebitAmount, CreditAmount);
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
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReverseEntriesPageHandler(var ReverseTransactionEntries: TestPage "Reverse Transaction Entries")
    begin
        ReverseTransactionEntries.Reverse.Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATRegisterPrintRequestPageHandler(var VATRegisterPrint: TestRequestPage "VAT Register - Print")
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        VATRegisterPrint.Name.AssertEquals(CompanyInformation.Name);
        VATRegisterPrint.Address.AssertEquals(CompanyInformation.Address);
        VATRegisterPrint.VATRegistrationNo.AssertEquals(CompanyInformation."VAT Registration No.");
        VATRegisterPrint.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLBookPrintRequestPageHandler(var GLBookPrint: TestRequestPage "G/L Book - Print")
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        GLBookPrint.Name.AssertEquals(CompanyInformation.Name);
        GLBookPrint.Address.AssertEquals(CompanyInformation.Address);
        GLBookPrint.VATRegistrationNo.AssertEquals(CompanyInformation."VAT Registration No.");
        GLBookPrint.Cancel().Invoke();
    end;
}

