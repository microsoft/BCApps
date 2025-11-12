codeunit 134282 "Non-Deductible UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Non-Deductible VAT] [UT]
    end;

    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryNonDeductibleVAT: Codeunit "Library - NonDeductible VAT";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        isInitialized: Boolean;
        DifferentNonDedVATRatesSameVATIdentifierErr: Label 'You cannot set different Non-Deductible VAT % for the combinations of business and product groups with the same VAT identifier.\The following combination with the same VAT identifier has different Non-Deductible VAT %: business group %1, product group %2', Comment = '%1, %2 - codes';
        GLEntryAmountErrLbl: Label '%1 must be %2 in %3.', Comment = '%1 = Amount Field Caption, %2 = Amount Value, %3 = G/L Account No.', Locked = true;
        AmountErrorLbl: Label '%1 must be %2.', Comment = '%1 = Amount Field Caption, %2 = Expected Amount';

    [Test]
    procedure NonDeductibleAmountsInPurchLineEndToEnd()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        NonDeductibleVATPct: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 456471] Non-Deductible VAT data is correct in purchase line
        Initialize();
        // [GIVEN] VAT Posting Setup with "VAT %" = 20, "Non-Deductible %" = 10
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        // [GIVEN] Purchase invoice with item connected to Non-Deductible VAT Posting Setup
        LibraryPurchase.CreatePurchHeader(
            PurchHeader, PurchHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLine(
            PurchLine, PurchHeader, PurchLine.Type::Item,
            LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandInt(100));
        // [WHEN] Set Amount = 1000 in purcahse line
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        // [THEN] "Non-Deductible VAT %" is 10 in purchase line
        // [THEN] "Non-Deductible VAT Base" is 1000 in purchase line
        // [THEN] "Non-Deductible VAT Amount" is 20 in purchase line
        NonDeductibleVATPct := LibraryNonDeductibleVAT.GetNonDeductibleVATPctFromVATPostingSetup(VATPostingSetup);
        LibraryNonDeductibleVAT.VerifyNonDeductibleAmountsInPurchLine(
            PurchLine, NonDeductibleVATPct,
            Round(PurchLine.Amount * NonDeductibleVATPct / 100),
            Round((PurchLine."Amount Including VAT" - PurchLine.Amount) * NonDeductibleVATPct / 100));
    end;

    [Test]
    procedure NonDeductibleVATInVATAmountLineOnCalcVATFields()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATAmountLine: Record "VAT Amount Line";
    begin
        // [FEATURE] [VAT Amount Line]
        // [SCENARIO 456471] The CalcVATFields function of the VAT Amount Line table calculates Non-Deductible VAT
        Initialize();
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        // [GIVEN] "VAT Base" is 1000 in the VAT Amount Line
        VATAmountLine."VAT Base" := LibraryRandom.RandDec(100, 2);
        // [GIVEN] "Amount Including VAT" is 1250 in the VAT Amount Line
        VATAmountLine."Amount Including VAT" := VATAmountLine."VAT Base" + LibraryRandom.RandDec(100, 2);
        VATAmountLine."Non-Deductible VAT %" := VATPostingSetup."Non-Deductible VAT %";
        // [WHEN] Call CalcVATFields of the VAT Amount Line table
        VATAmountLine.CalcVATFields('', false, 0);
        // [THEN] Non-Deductible VAT Base is
        VATAmountLine.TestField("Non-Deductible VAT Base", Round(VATAmountLine."VAT Base" * VATAmountLine."Non-Deductible VAT %" / 100));
        VATAmountLine.TestField(
            "Non-Deductible VAT Amount",
            Round((VATAmountLine."Amount Including VAT" - VATAmountLine."VAT Base") * VATAmountLine."Non-Deductible VAT %" / 100));
    end;

    [Test]
    procedure NonDedVATAmountRecalcWhenUpdateNonDedVATPctInPurchaseLine()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        NonDeductibleVATPct: Decimal;
    begin
        // [SCENARIO 456471] Non-Deductible VAT amount is updated when Stan changes the Non-Deductible VAT % in purchase line

        Initialize();
        // [GIVEN] VAT Posting Setup with "VAT %" = 20, "Non-Deductible %" = 10
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        // [GIVEN] Purchase invoice with item connected to Non-Deductible VAT Posting Setup
        LibraryPurchase.CreatePurchHeader(
            PurchHeader, PurchHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        // [GIVEN] Purchase line with amount = 1000
        LibraryPurchase.CreatePurchaseLine(
            PurchLine, PurchHeader, PurchLine.Type::Item,
            LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandInt(100));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        NonDeductibleVATPct := Round(LibraryNonDeductibleVAT.GetNonDeductibleVATPctFromVATPostingSetup(VATPostingSetup) / 2);
        // [WHEN] Change "Non-Deductible VAT %" to 20 in purchase line
        PurchLine.Validate("Non-Deductible VAT %", NonDeductibleVATPct);
        // [THEN] "Non-Deductible VAT Amount" is 40 in purchase line
        LibraryNonDeductibleVAT.VerifyNonDeductibleAmountsInPurchLine(
            PurchLine, NonDeductibleVATPct,
            Round(PurchLine.Amount * NonDeductibleVATPct / 100),
            Round((PurchLine."Amount Including VAT" - PurchLine.Amount) * NonDeductibleVATPct / 100));
    end;

    [Test]
    procedure SetDiffNonDedVATPercentInVATPostingSetupWithDiffVATIdentifiers()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        NonDedVATPercent: Decimal;
    begin
        // [SCENARIO 474024] Stan can create VAT Posting Setup with the different Non-Deductible VAT percents and different VAT identifiers

        Initialize();
        // [GIVEN] VAT Posting Setup "V1" with "VAT Identifier" = "X", "Allow Non-Deductible VAT" is enabled and "Non-Deductible VAT %" = 10
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        NonDedVATPercent := VATPostingSetup."Non-Deductible VAT %";
        // [GIVEN] VAT Posting Setup "V2" with "VAT Identifier" = "Y", "Allow Non-Deductible VAT" is enabled and "Non-Deductible VAT %" = 10
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        // [WHEN] Set "Non-Deductible VAT %" = 11 in "V2"
        NonDedVATPercent += 1;
        VATPostingSetup.Validate("Non-Deductible VAT %", NonDedVATPercent);
        VATPostingSetup.Modify(true);
        // [THEN] The changes are saved in V2 without error
        VATPostingSetup.Find();
        VATPostingSetup.TestField("Non-Deductible VAT %", NonDedVATPercent);
    end;

    [Test]
    procedure CannotSetDiffNonDedVATPercentInVATPostingSetupWithSameVATIdentifiers()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetupCopy: Record "VAT Posting Setup";
    begin
        // [SCENARIO 474024] Stan cannot create VAT Posting Setup with the different Non-Deductible VAT percents and same VAT identifiers

        Initialize();
        // [GIVEN] VAT Posting Setup "V1" with "VAT Identifier" = "X", "Allow Non-Deductible VAT" is enabled and "Non-Deductible VAT %" = 10
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        VATPostingSetupCopy := VATPostingSetup;
        // [GIVEN] VAT Posting Setup "V2" with "VAT Identifier" = "Y", "Allow Non-Deductible VAT" is enabled and "Non-Deductible VAT %" = 20
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        // [GIVEN] Set "VAT Identifier" = "X" to "V1"
        asserterror VATPostingSetup.Validate("VAT Identifier", VATPostingSetupCopy."VAT Identifier");
        // [THEN] An error message thrown that it is not possible and the same setup exists for "V1"
        Assert.ExpectedError(StrSubstNo(DifferentNonDedVATRatesSameVATIdentifierErr, VATPostingSetupCopy."VAT Bus. Posting Group", VATPostingSetupCopy."VAT Prod. Posting Group"));
    end;

    [Test]
    procedure CannotSetDiffNonDedVATPercentInPurchaseLineWithSameVATIdentifiers()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO 475903] Stan cannot set different Non-Deductible VAT percents for the same VAT identifiers in purchase line

        Initialize();
        // [GIVEN] VAT Posting Setup with "VAT Identifier" = "X", "Allow Non-Deductible VAT" is enabled and "Non-Deductible VAT %" = 10
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        // [GIVEN] Purchase invoice with two lines, each with VAT Posting Setup with Non-Deductible VAT
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
            LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandInt(100));
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
            LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandInt(100));

        // [WHEN] Change "Non-Deductible VAT %" to 15 in the second purchase line
        asserterror PurchaseLine.Validate("Non-Deductible VAT %", VATPostingSetup."Non-Deductible VAT %" + 1);
        // [THEN] An error message thrown that it is not possible to set different Non-Deductible VAT percents for the same VAT identifiers
        Assert.ExpectedError(StrSubstNo(DifferentNonDedVATRatesSameVATIdentifierErr, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group"));
    end;

    [Test]
    procedure PurchVATAccandNonDedPurchVATAccAreBalancedWhenPostsRecurrJnlWithRFReversingMethod()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        Amount: Decimal;
        DocumentNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // [SCENARIO 541997] When Stan posts Recurring Journal Lines with Recurring Method
        // "RF Reversing Fixed" then G/L Entries and VAT Entries are created with correct Amount 
        // Which balances Purchase VAT Account and Non-Ded. Purchase VAT Account both.
        Initialize();

        // [GIVEN] Create VAT Posting Setups.
        LibraryNonDeductibleVAT.CreateVATPostingSetupWithNonDeductibleDetail(VATPostingSetup, 20, 60);

        // [GIVEN] Create Recurring Journal Batch.
        CreateRecurringGenJournalBatch(GenJournalBatch);

        // [GIVEN] Create General Posting Setup.
        CreateGeneralPostingSetupForVAT(GLAccountNo);

        // [GIVEN] Generate Amount and save it in a Variable.
        Amount := LibraryRandom.RandInt(1000);

        // [GIVEN] Generate Document No. and save it in a Variable.        
        DocumentNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Create Recurring Journal Line.
        CreateRecurringJournalLine(
            GenJournalLine[1],
            GenJournalBatch,
            GenJournalLine[1]."Recurring Method"::"RF Reversing Fixed",
            GenJournalLine[1]."Document Type"::" ",
            GLAccountNo,
            Amount,
            DocumentNo);

        // [GIVEN] Validate VAT Bus. Posting Group and VAT Prod. Posting Group in Gen. Journal Line.
        GenJournalLine[1].Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GenJournalLine[1].Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Validate Recurring Journal Line Reversal Parameters. 
        ValidateRecurringJnlLineReversalParameters(GenJournalLine[1], DocumentNo);

        // [GIVEN] Create Recurring Journal Line for Reversal.
        CreateRecurringJournalLine(
            GenJournalLine[2],
            GenJournalBatch,
            GenJournalLine[2]."Recurring Method"::"RF Reversing Fixed",
            GenJournalLine[2]."Document Type"::" ",
            CreateGLAccount(GLAccount."Income/Balance"::"Balance Sheet"),
            -Amount,
            DocumentNo);

        // [GIVEN] Validate Recurring Journal Line Reversal Parameters. 
        ValidateRecurringJnlLineReversalParameters(GenJournalLine[2], DocumentNo);

        // [WHEN] Post recurring Gen. Journal Lines.
        LibraryERM.PostGeneralJnlLine(GenJournalLine[2]);

        // [THEN] Posted Gen. Journal Lines are balanced by Account No. and Document No.        
        VerifyGLEntryAmountByAccountNo(0, VATPostingSetup."Purchase VAT Account", DocumentNo);

        // [THEN] Reversed Posted Gen. Journal Lines are balanced by Account No. and Document No.
        VerifyGLEntryAmountByAccountNo(0, VATPostingSetup."Non-Ded. Purchase VAT Account", DocumentNo);

        // [THEN] Reversed Posted VAT Entries are balanced by Document No.
        VerifyVATEntry(0, DocumentNo);
    end;

    [Test]
    procedure ChangingDirectUnitCostToZeroChangesNonDeductibleVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO 546032] Changeing the direct unit cost to zero also changes the Non-Deductible VAT of the purchase document

        Initialize();
        // [GIVEN] VAT Posting Setup with "VAT Identifier" = "X", "Allow Non-Deductible VAT" is enabled and "Non-Deductible VAT %" is specified
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        // [GIVEN] Purchase invoice with Non-Deductible VAT posting setup and a single line with direct unit cost
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
            LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));

        // [WHEN] Change "Direct Unit Cost" to 0 in the purchase line
        PurchaseLine.Validate("Direct Unit Cost", 0);
        // [THEN] "Non-Deductible VAT Base" and "Non-Deductible VAT Amount" are 0 in the purchase line
        PurchaseLine.TestField("Non-Deductible VAT Base", 0);
        PurchaseLine.TestField("Non-Deductible VAT Amount", 0);
    end;

    [Test]
    procedure CheckVATEntryNonDeductibleVATPurchaseInvoicePosting()
    var
        GenPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        GLAccountNo: Code[20];
        PostedDocumentNo: Code[20];
        VATRate: Decimal;
    begin
        // [SCENARIO 595966] Check VAT Entry Non-Deductible VAT on Purchase Invoice Posting with G/L Account Line.
        Initialize();

        // [GIVEN] Create Vendor and set Prices Including VAT
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Prices Including VAT", true);
        Vendor.Modify(true);

        // [GIVEN] Enable Non-Deductible VAT in VAT Setup (with confirm handler)
        LibraryNonDeductibleVAT.EnableNonDeductibleVAT();

        // [GIVEN] Create G/L Account and set posting groups/categories
        VATRate := 20.0;
        GLAccountNo := CreateGLAccountWithVATPostingSetup(VATRate);
        GLAccount.Get(GLAccountNo);

        // [GIVEN] Create/Modify VAT Product Posting Group and VAT Posting Setup.
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, Vendor."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group");
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("Allow Non-Deductible VAT", VATPostingSetup."Allow Non-Deductible VAT"::Allow);
        VATPostingSetup.Validate("VAT %", 20);
        VATPostingSetup.Validate("Non-Deductible VAT %", 100);
        VATPostingSetup.Modify(true);

        // [WHEN] Create and post Purchase Invoice for the vendor with G/L Account line
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::"G/L Account", GLAccountNo, 1);
        PurchLine.Validate("Direct Unit Cost", 14.19);
        PurchLine.Modify(true);
        PurchHeader.Validate("Vendor Invoice No.", 'Test-1001');
        PurchHeader.Modify(true);
        LibraryERM.CreateGeneralPostingSetup(GenPostingSetup, PurchLine."Gen. Bus. Posting Group", PurchLine."Gen. Prod. Posting Group");
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, false, true);

        // [THEN] verify that Purchase Invoice is posted with 0 VAT Amount and 0 Non-Deductible VAT Amount
        VATEntry.SetRange("Document No.", PostedDocumentNo);
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.FindFirst();
        Assert.AreEqual(0, VATEntry.Base, 'Vat Base should be 0.');
        Assert.AreEqual(0, VATEntry.Amount, 'Vat Amount should be 0.');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Non-Deductible UT");
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Non-Deductible UT");
        LibraryNonDeductibleVAT.EnableNonDeductibleVAT();
        LibrarySetupStorage.Save(Database::"VAT Setup");
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Non-Deductible UT");
    end;

    local procedure CreateRecurringJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; RecurringMethod: Enum "Gen. Journal Recurring Method"; DocumentType: Enum "Gen. Journal Document Type"; AccountNo: Code[20]; Amount: Decimal; DocumentNo: Code[20])
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::"G/L Account", AccountNo, Amount);
        GenJournalLine.Validate("Recurring Method", RecurringMethod);
        GenJournalLine.Validate("Document No.", DocumentNo);

        Evaluate(GenJournalLine."Recurring Frequency", '<' + Format(LibraryRandom.RandInt(5)) + 'M>');
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGLAccount(IncomeBalance: Enum "G/L Account Report Type"): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Income/Balance", IncomeBalance);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateRecurringGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateRecurringTemplateName(GenJournalTemplate);
        LibraryERM.CreateRecurringBatchName(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateGeneralPostingSetupForVAT(var GLAccountNo: Code[20])
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);

        GLAccountNo := CreateGLAccount(GLAccount."Income/Balance"::"Balance Sheet");

        GLAccount.Get(GLAccountNo);
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Purchase);
        GLAccount.Validate("Gen. Bus. Posting Group", GenBusinessPostingGroup.Code);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        GLAccount.Modify();

        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusinessPostingGroup.Code, GenProductPostingGroup.Code);
    end;

    local procedure ValidateRecurringJnlLineReversalParameters(var GenJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20])
    begin
        GenJournalLine.Validate("Document No.", DocumentNo);
        Evaluate(GenJournalLine."Recurring Frequency", '<' + Format(LibraryRandom.RandIntInRange(15, 15)) + 'D>');
        Evaluate(GenJournalLine."Reverse Date Calculation", '<' + Format(LibraryRandom.RandIntInRange(1, 1)) + 'D>');
        GenJournalLine.Validate("Posting Date", Today);
        GenJournalLine.Validate("VAT Reporting Date", Today);
        GenJournalLine.Modify(true);
    end;

    local procedure VerifyGLEntryAmountByAccountNo(ExpectedAmount: Decimal; GLAccountNo: Code[20]; DocumentNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::" ");
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.CalcSums(Amount);
        Assert.AreEqual(ExpectedAmount, GLEntry.Amount, StrSubstNo(GLEntryAmountErrLbl, GLEntry.FieldCaption(Amount), ExpectedAmount, GLEntry."G/L Account No."));
    end;

    local procedure VerifyVATEntry(ExpectedAmount: Decimal; DocumentNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.CalcSums(Amount, Base, "Non-Deductible VAT Amount", "Non-Deductible VAT Base");
        Assert.AreEqual(ExpectedAmount, VATEntry.Base, StrSubstNo(AmountErrorLbl, VATEntry.FieldCaption(Base), ExpectedAmount));
        Assert.AreEqual(ExpectedAmount, VATEntry.Amount, StrSubstNo(AmountErrorLbl, VATEntry.FieldCaption(Amount), ExpectedAmount));
        Assert.AreEqual(ExpectedAmount, VATEntry."Non-Deductible VAT Base", StrSubstNo(AmountErrorLbl, VATEntry.FieldCaption("Non-Deductible VAT Base"), ExpectedAmount));
        Assert.AreEqual(ExpectedAmount, VATEntry."Non-Deductible VAT Amount", StrSubstNo(AmountErrorLbl, VATEntry.FieldCaption("Non-Deductible VAT Amount"), ExpectedAmount));
    end;

    local procedure CreateGLAccountWithVATPostingSetup(var VATRate: Decimal) GLAccountNo: Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATRate := LibraryRandom.RandIntInRange(2, 5);
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup,
           VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATRate);
        GLAccountNo := VATPostingSetup."Purchase VAT Account";
        UpdateGLAccountPostingGroups(GLAccountNo,
           VATPostingSetup."VAT Prod. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
    end;

    local procedure UpdateGLAccountPostingGroups(GLAccountNo: Code[20]; VATProdPostingGroup: Code[20]; VATBusPostingGroup: Code[20])
    var
        GLAccount: Record "G/L Account";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        GLAccount.Get(GLAccountNo);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        GLAccount."Gen. Posting Type" := GLAccount."Gen. Posting Type"::Purchase;
        GLAccount.Validate("Account Category", GLAccount."Account Category"::Expense);
        GLAccount.Validate("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.Validate("Direct Posting", true);
        GLAccount."Gen. Prod. Posting Group" := GenProductPostingGroup.Code;
        GLAccount."VAT Prod. Posting Group" := VATProdPostingGroup;
        GLAccount."VAT Bus. Posting Group" := VATBusPostingGroup;
        GLAccount.Modify(true);
    end;
}