codeunit 134289 "Non-Deductible VAT Pmt. Disc."
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Non-Deductible VAT] [Payment Discount]
    end;

    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryNonDeductibleVAT: Codeunit "Library - NonDeductible VAT";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        LibraryERM: Codeunit "Library - ERM";
        LibraryJournals: Codeunit "Library - Journals";
        Assert: Codeunit Assert;
        isInitialized: Boolean;

    [Test]
    procedure NormalVATPurchInvAppliedToPmtAdjustForPmtDisc()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        PaymentTerms: Record "Payment Terms";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        GenJournalLine: Record "Gen. Journal Line";
        InvNo: Code[20];
    begin
        // [FEATURE] [Adjust For Payment Discount] [Application]
        // [SCENARIO 475533] Posting results are correct after applying payment to purchase invoice with Normal VAT, payment discount and "Adjust For Payment Discount" option enabled

        Initialize();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        VATPostingSetup.Validate("Adjust for Payment Discount", true);
        VATPostingSetup.Modify(true);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        Vendor.Validate("Payment Terms Code", PaymentTerms."Code");
        Vendor.Modify(true);
        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);

        InvNo := PostPurchInv(PurchHeader, PurchLine, Vendor."No.", GLAccount."No.");
        CreatePostVendorPaymentGenJnlLineAppliedToInvoice(
            GenJournalLine, Vendor."No.", InvNo, Round(PurchLine."Amount Including VAT" * (1 - PaymentTerms."Discount %" / 100)));

        VerifyNormalVATAdjustForPmtDisc(GenJournalLine, PurchLine, VATPostingSetup, PaymentTerms."Discount %");

        LibraryPmtDiscSetup.ClearAdjustPmtDiscInVATSetup();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(false);
    end;

    [Test]
    procedure ReverseChargeVATPurchInvAppliedToPmtAdjustForPmtDisc()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        PaymentTerms: Record "Payment Terms";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        GenJournalLine: Record "Gen. Journal Line";
        InvNo: Code[20];
    begin
        // [FEATURE] [Adjust For Payment Discount] [Application]
        // [SCENARIO 475533] Posting results are correct after applying payment to purchase invoice with Reverse Charge VAT, payment discount and "Adjust For Payment Discount" option enabled

        Initialize();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        LibraryNonDeductibleVAT.CreateNonDeductibleReverseChargeVATPostingSetup(VATPostingSetup);
        VATPostingSetup.Validate("Adjust for Payment Discount", true);
        VATPostingSetup.Modify(true);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        Vendor.Validate("Payment Terms Code", PaymentTerms."Code");
        Vendor.Modify(true);
        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);

        InvNo := PostPurchInv(PurchHeader, PurchLine, Vendor."No.", GLAccount."No.");
        CreatePostVendorPaymentGenJnlLineAppliedToInvoice(
            GenJournalLine, Vendor."No.", InvNo, Round(PurchLine."Amount Including VAT" * (1 - PaymentTerms."Discount %" / 100)));

        VerifyReverseChargeVATAdjustForPmtDisc(GenJournalLine, PurchLine, VATPostingSetup, PaymentTerms."Discount %");

        LibraryPmtDiscSetup.ClearAdjustPmtDiscInVATSetup();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(false);
    end;

    [Test]
    procedure TwoLinesNormalAndZeroVATWithNDVATAdjustForPmtDisc()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        ZeroVATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        ZeroVATGLAccount: Record "G/L Account";
        PaymentTerms: Record "Payment Terms";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchLine2: Record "Purchase Line";
        GenJournalLine: Record "Gen. Journal Line";
        InvNo: Code[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 631923] Posting results are correct after applying payment to purchase invoice with two lines:
        // one with Non-Deductible Normal VAT and one with zero VAT ("Do Not Allow" Non-Deductible VAT),
        // when "Adjust For Payment Discount" is enabled. Zero VAT line must not have non-deductible VAT amounts in the payment VAT entry.

        // [GIVEN] Non-Deductible Normal VAT posting setup with "Adjust for Payment Discount" enabled
        Initialize();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        VATPostingSetup.Validate("Adjust for Payment Discount", true);
        VATPostingSetup.Modify(true);
        // [GIVEN] Zero VAT posting setup with "Allow Non-Deductible VAT" = "Do Not Allow"
        CreateZeroVATPostingSetupDoNotAllowNDVAT(ZeroVATPostingSetup, VATPostingSetup."VAT Bus. Posting Group");
        // [GIVEN] Vendor with payment discount terms
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        Vendor.Validate("Payment Terms Code", PaymentTerms."Code");
        Vendor.Modify(true);
        // [GIVEN] G/L Account for Non-Deductible VAT line
        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        // [GIVEN] G/L Account for Zero VAT line
        ZeroVATGLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        ZeroVATGLAccount.Validate("VAT Prod. Posting Group", ZeroVATPostingSetup."VAT Prod. Posting Group");
        ZeroVATGLAccount.Modify(true);
        // [GIVEN] Posted purchase invoice with two lines: Non-Deductible VAT and Zero VAT
        InvNo := PostPurchInvTwoLines(PurchHeader, PurchLine, PurchLine2, Vendor."No.", GLAccount."No.", ZeroVATGLAccount."No.");

        // [WHEN] Post payment applied to invoice with payment discount
        CreatePostVendorPaymentGenJnlLineAppliedToInvoice(
            GenJournalLine, Vendor."No.", InvNo,
            Round((PurchLine."Amount Including VAT" + PurchLine2."Amount Including VAT") * (1 - PaymentTerms."Discount %" / 100)));

        // [THEN] VAT entries are correct: Non-Deductible VAT entry has adjusted amounts, Zero VAT entry has no non-deductible amounts
        VerifyTwoLinesNDVATAndZeroVATAdjustForPmtDisc(GenJournalLine, PurchLine, VATPostingSetup, ZeroVATPostingSetup, PaymentTerms."Discount %");

        LibraryPmtDiscSetup.ClearAdjustPmtDiscInVATSetup();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(false);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Non-Deductible VAT Pmt. Disc.");
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Non-Deductible VAT Pmt. Disc.");
        LibraryNonDeductibleVAT.EnableNonDeductibleVAT();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateAccountInCustomerPostingGroup();
        LibraryERMCountryData.UpdateAccountInVendorPostingGroups();
        LibrarySetupStorage.Save(Database::"VAT Setup");
        LibrarySetupStorage.SavePurchasesSetup();
        LibrarySetupStorage.SaveGeneralLedgerSetup();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Non-Deductible VAT Pmt. Disc.");
    end;

    local procedure PostPurchInv(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; VendorNo: Code[20]; GLAccNo: Code[20]): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, VendorNo);
        LibraryPurchase.CreatePurchaseLine(
            PurchLine, PurchHeader, PurchLine.Type::"G/L Account", GLAccNo, LibraryRandom.RandInt(1));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchLine.Modify(true);
        GeneralPostingSetup.Get(PurchLine."Gen. Bus. Posting Group", PurchLine."Gen. Prod. Posting Group");
        GeneralPostingSetup."Purch. Pmt. Disc. Debit Acc." := LibraryERM.CreateGLAccountNo(); // Using assignment to avoid error in ES.
        GeneralPostingSetup."Purch. Pmt. Disc. Credit Acc." := LibraryERM.CreateGLAccountNo();
        GeneralPostingSetup.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));
    end;

    local procedure PostPurchInvTwoLines(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var PurchLine2: Record "Purchase Line"; VendorNo: Code[20]; GLAccNo: Code[20]; ZeroVATGLAccNo: Code[20]): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, VendorNo);
        LibraryPurchase.CreatePurchaseLine(
            PurchLine, PurchHeader, PurchLine.Type::"G/L Account", GLAccNo, LibraryRandom.RandInt(1));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchLine.Modify(true);
        GeneralPostingSetup.Get(PurchLine."Gen. Bus. Posting Group", PurchLine."Gen. Prod. Posting Group");
        GeneralPostingSetup."Purch. Pmt. Disc. Debit Acc." := LibraryERM.CreateGLAccountNo();
        GeneralPostingSetup."Purch. Pmt. Disc. Credit Acc." := LibraryERM.CreateGLAccountNo();
        GeneralPostingSetup.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
            PurchLine2, PurchHeader, PurchLine2.Type::"G/L Account", ZeroVATGLAccNo, LibraryRandom.RandInt(1));
        PurchLine2.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchLine2.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));
    end;

    local procedure CreateZeroVATPostingSetupDoNotAllowNDVAT(var ZeroVATPostingSetup: Record "VAT Posting Setup"; VATBusPostingGroup: Code[20])
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(ZeroVATPostingSetup, VATBusPostingGroup, VATProductPostingGroup.Code);
        ZeroVATPostingSetup.Validate("VAT Calculation Type", ZeroVATPostingSetup."VAT Calculation Type"::"Normal VAT");
        ZeroVATPostingSetup.Validate("VAT %", 0);
        ZeroVATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        ZeroVATPostingSetup.Validate("Allow Non-Deductible VAT", ZeroVATPostingSetup."Allow Non-Deductible VAT"::"Do Not Allow");
        ZeroVATPostingSetup.Validate("Adjust for Payment Discount", true);
        ZeroVATPostingSetup.Modify(true);
    end;

    local procedure CreatePostVendorPaymentGenJnlLineAppliedToInvoice(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; ApplyToDocNo: Code[20]; LineAmount: Decimal)
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
            GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, VendorNo, LineAmount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", ApplyToDocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure VerifyNormalVATAdjustForPmtDisc(GenJournalLine: Record "Gen. Journal Line"; PurchaseLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup"; PmtDisc: Decimal)
    var
        VATEntry: Record "VAT Entry";
        GLEntry: Record "G/L Entry";
        Vendor: Record Vendor;
        VendPostingGroup: Record "Vendor Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        VATBase: Decimal;
        VATAmount: Decimal;
        NDVATBase: Decimal;
        NDVATAmount: Decimal;
    begin
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Payment);
        VATEntry.SetRange("Document No.", GenJournalLine."Document No.");
        VATEntry.SetRange("Posting Date", GenJournalLine."Posting Date");
        Assert.RecordCount(VATEntry, 1);
        VATEntry.FindFirst();
        VATBase := PurchaseLine.Amount;
        NDVATBase := Round(VATBase * VATPostingSetup."Non-Deductible VAT %" / 100);
        VATBase -= NDVATBase;
        VATAmount := PurchaseLine."Amount Including VAT" - PurchaseLine.Amount;
        NDVATAmount := Round(VATAmount * VATPostingSetup."Non-Deductible VAT %" / 100);
        VATAmount -= NDVATAmount;

        VATBase := Round(VATBase * PmtDisc / 100);
        VATAmount := Round(VATAmount * PmtDisc / 100);
        NDVATBase := Round(NDVATBase * PmtDisc / 100);
        NDVATAmount := Round(NDVATAmount * PmtDisc / 100);

        VATEntry.TestField(Base, -VATBase);
        VATEntry.TestField(Amount, -VATAmount);
        VATEntry.TestField("Non-Deductible VAT Base", -NDVATBase);
        VATEntry.TestField("Non-Deductible VAT Amount", -NDVATAmount);

        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Payment);
        GLEntry.SetRange("Document No.", GenJournalLine."Document No.");
        GLEntry.SetRange("Posting Date", GenJournalLine."Posting Date");
        Assert.RecordCount(GLEntry, 4);
        GLEntry.CalcSums("VAT Amount", "Non-Deductible VAT Amount");
        GLEntry.TestField("VAT Amount", VATEntry.Amount);
        GLEntry.TestField("Non-Deductible VAT Amount", VATEntry."Non-Deductible VAT Amount");

        GLEntry.SetRange("G/L Account No.", GenJournalLine."Bal. Account No.");
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, -GenJournalLine.Amount);
        GLEntry.SetRange("G/L Account No.", VATPostingSetup."Purchase VAT Account");
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, -VATAmount);
        Vendor.Get(PurchaseLine."Pay-to Vendor No.");
        VendPostingGroup.Get(VEndor."Vendor Posting Group");
        GLEntry.SetRange("G/L Account No.", VendPostingGroup."Payables Account");
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, PurchaseLine."Amount Including VAT");
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        GLEntry.SetRange("G/L Account No.", GeneralPostingSetup."Purch. Pmt. Disc. Credit Acc.");
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, -VATBase - NDVATBase - NDVATAmount);
        GLEntry.TestField("VAT Amount", VATEntry.Amount);
        GLEntry.TestField("Non-Deductible VAT Amount", VATEntry."Non-Deductible VAT Amount");
    end;

    local procedure VerifyReverseChargeVATAdjustForPmtDisc(GenJournalLine: Record "Gen. Journal Line"; PurchaseLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup"; PmtDisc: Decimal)
    var
        VATEntry: Record "VAT Entry";
        GLEntry: Record "G/L Entry";
        Vendor: Record Vendor;
        VendPostingGroup: Record "Vendor Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        VATBase: Decimal;
        VATAmount: Decimal;
        NDVATBase: Decimal;
        NDVATAmount: Decimal;
    begin
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Payment);
        VATEntry.SetRange("Document No.", GenJournalLine."Document No.");
        VATEntry.SetRange("Posting Date", GenJournalLine."Posting Date");
        Assert.RecordCount(VATEntry, 1);
        VATEntry.FindFirst();
        VATBase := PurchaseLine.Amount;
        NDVATBase := Round(VATBase * VATPostingSetup."Non-Deductible VAT %" / 100);
        VATBase -= NDVATBase;
        VATAmount := Round(PurchaseLine.Amount * VATPostingSetup."VAT %" / 100);
        NDVATAmount := Round(VATAmount * VATPostingSetup."Non-Deductible VAT %" / 100);
        VATAmount -= NDVATAmount;

        VATBase := Round(VATBase * PmtDisc / 100);
        VATAmount := Round(VATAmount * PmtDisc / 100);
        NDVATBase := Round(NDVATBase * PmtDisc / 100);
        NDVATAmount := Round(NDVATAmount * PmtDisc / 100);

        VATEntry.TestField(Base, -VATBase);
        VATEntry.TestField(Amount, -VATAmount);
        VATEntry.TestField("Non-Deductible VAT Base", -NDVATBase);
        VATEntry.TestField("Non-Deductible VAT Amount", -NDVATAmount);

        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Payment);
        GLEntry.SetRange("Document No.", GenJournalLine."Document No.");
        GLEntry.SetRange("Posting Date", GenJournalLine."Posting Date");
        Assert.RecordCount(GLEntry, 8);
        GLEntry.CalcSums("VAT Amount", "Non-Deductible VAT Amount");
        GLEntry.TestField("VAT Amount", VATEntry.Amount);
        GLEntry.TestField("Non-Deductible VAT Amount", VATEntry."Non-Deductible VAT Amount");

        GLEntry.SetRange("G/L Account No.", GenJournalLine."Bal. Account No.");
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, -GenJournalLine.Amount);
        GLEntry.SetRange("G/L Account No.", VATPostingSetup."Purchase VAT Account");
        Assert.RecordCount(GLEntry, 2);
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, -VATAmount - NDVATAmount);
        GLEntry.SetRange("G/L Account No.", VATPostingSetup."Reverse Chrg. VAT Acc.");
        Assert.RecordCount(GLEntry, 2);
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, VATAmount + NDVATAmount);

        Vendor.Get(PurchaseLine."Pay-to Vendor No.");
        VendPostingGroup.Get(VEndor."Vendor Posting Group");
        GLEntry.SetRange("G/L Account No.", VendPostingGroup."Payables Account");
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, PurchaseLine.Amount);
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        GLEntry.SetRange("G/L Account No.", GeneralPostingSetup."Purch. Pmt. Disc. Credit Acc.");
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, -VATBase);
        GLEntry.TestField("VAT Amount", VATEntry.Amount);
        GLEntry.TestField("Non-Deductible VAT Amount", VATEntry."Non-Deductible VAT Amount");
        GLEntry.SetRange("G/L Account No.", VendPostingGroup."Payment Disc. Credit Acc.");
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, -NDVATBase);
    end;

    local procedure VerifyTwoLinesNDVATAndZeroVATAdjustForPmtDisc(GenJournalLine: Record "Gen. Journal Line"; PurchLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup"; ZeroVATPostingSetup: Record "VAT Posting Setup"; PmtDisc: Decimal)
    var
        VATEntry: Record "VAT Entry";
        VATBase: Decimal;
        VATAmount: Decimal;
        NDVATBase: Decimal;
        NDVATAmount: Decimal;
    begin
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Payment);
        VATEntry.SetRange("Document No.", GenJournalLine."Document No.");
        VATEntry.SetRange("Posting Date", GenJournalLine."Posting Date");
        Assert.RecordCount(VATEntry, 2);

        // Verify Non-Deductible VAT entry has correct adjusted amounts
        VATEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Assert.RecordCount(VATEntry, 1);
        VATEntry.FindFirst();
        VATBase := PurchLine.Amount;
        NDVATBase := Round(VATBase * VATPostingSetup."Non-Deductible VAT %" / 100);
        VATBase -= NDVATBase;
        VATAmount := PurchLine."Amount Including VAT" - PurchLine.Amount;
        NDVATAmount := Round(VATAmount * VATPostingSetup."Non-Deductible VAT %" / 100);
        VATAmount -= NDVATAmount;

        VATBase := Round(VATBase * PmtDisc / 100);
        VATAmount := Round(VATAmount * PmtDisc / 100);
        NDVATBase := Round(NDVATBase * PmtDisc / 100);
        NDVATAmount := Round(NDVATAmount * PmtDisc / 100);

        VATEntry.TestField(Base, -VATBase);
        VATEntry.TestField(Amount, -VATAmount);
        VATEntry.TestField("Non-Deductible VAT Base", -NDVATBase);
        VATEntry.TestField("Non-Deductible VAT Amount", -NDVATAmount);

        // Verify Zero VAT entry has no non-deductible amounts ("Do Not Allow" setting)
        VATEntry.SetRange("VAT Prod. Posting Group", ZeroVATPostingSetup."VAT Prod. Posting Group");
        Assert.RecordCount(VATEntry, 1);
        VATEntry.FindFirst();
        VATEntry.TestField("Non-Deductible VAT Base", 0);
        VATEntry.TestField("Non-Deductible VAT Amount", 0);
    end;
}