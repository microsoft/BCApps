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
}