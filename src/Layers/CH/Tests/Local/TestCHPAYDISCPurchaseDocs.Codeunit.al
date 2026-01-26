codeunit 144067 "Test CH PAYDISC Purchase Docs"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SourceCodeSetup: Record "Source Code Setup";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryCH: Codeunit "Library - CH";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;
        PmtApplnErr: Label 'You cannot post and apply general journal line %1, %2, %3 because the corresponding balance contains VAT.', Comment = '%1 - Template name, %2 - Batch name, %3 - Line no.';

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPmtToPurchaseInvoiceDuringPosting()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GLAccount: Record "G/L Account";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PmtGenJournalLine: Record "Gen. Journal Line";
        PmtDiscountFCY: Decimal;
    begin
        Initialize();

        // Setup.
        SetupVATForFCY(VATPostingSetup, CurrencyExchangeRate, Vendor, GLAccount);
        ApplyBeforePosting(VendorLedgerEntry, PmtGenJournalLine, Vendor, GLAccount);
        PmtDiscountFCY := GetPmtDiscount(VendorLedgerEntry);

        // Exercise.
        asserterror LibraryERM.PostGeneralJnlLine(PmtGenJournalLine);

        VerifyApplicationWithVATBalancingError(PmtGenJournalLine);
        if true then
            exit; // We reject possibility to apply payment with VAT and Discount on a balance account until proper fix (split transaction)

        // Verify.
        VendorLedgerEntry.SetAutoCalcFields("Original Amt. (LCY)", "Original Amount");
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Payment);
        VendorLedgerEntry.FindFirst();
        VerifyVATEntry(CurrencyExchangeRate, VATPostingSetup, VendorLedgerEntry, PmtDiscountFCY, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyPmtToPurchaseInvoiceDuringPosting()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GLAccount: Record "G/L Account";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PmtGenJournalLine: Record "Gen. Journal Line";
        PmtDiscountFCY: Decimal;
    begin
        Initialize();

        // Setup.
        SetupVATForFCY(VATPostingSetup, CurrencyExchangeRate, Vendor, GLAccount);
        ApplyBeforePosting(VendorLedgerEntry, PmtGenJournalLine, Vendor, GLAccount);
        PmtDiscountFCY := GetPmtDiscount(VendorLedgerEntry);
        asserterror LibraryERM.PostGeneralJnlLine(PmtGenJournalLine);

        VerifyApplicationWithVATBalancingError(PmtGenJournalLine);
        if true then
            exit; // We reject possibility to apply payment with VAT and Discount on a balance account until proper fix (split transaction)

        // Exercise.
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Payment);
        VendorLedgerEntry.FindLast();
        LibraryERM.UnapplyVendorLedgerEntry(VendorLedgerEntry);

        // Verify.
        VendorLedgerEntry.SetAutoCalcFields("Original Amt. (LCY)", "Original Amount");
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Payment);
        VendorLedgerEntry.FindFirst();
        VerifyVATEntry(CurrencyExchangeRate, VATPostingSetup, VendorLedgerEntry, PmtDiscountFCY, 4);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPmtToPurchaseInvoiceAfterPosting()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GLAccount: Record "G/L Account";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PmtDiscountFCY: Decimal;
    begin
        Initialize();

        // Setup.
        SetupVATForFCY(VATPostingSetup, CurrencyExchangeRate, Vendor, GLAccount);
        ApplyAfterPosting(VendorLedgerEntry, Vendor, GLAccount);
        PmtDiscountFCY := GetPmtDiscount(VendorLedgerEntry);

        // Exercise.
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);

        // Verify.
        VendorLedgerEntry.SetAutoCalcFields("Original Amt. (LCY)", "Original Amount");
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Payment);
        VendorLedgerEntry.FindFirst();
        VerifyVATEntry(CurrencyExchangeRate, VATPostingSetup, VendorLedgerEntry, PmtDiscountFCY, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyPmtToPurchaseInvoiceAfterPosting()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GLAccount: Record "G/L Account";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PmtDiscountFCY: Decimal;
    begin
        Initialize();

        // Setup.
        SetupVATForFCY(VATPostingSetup, CurrencyExchangeRate, Vendor, GLAccount);
        ApplyAfterPosting(VendorLedgerEntry, Vendor, GLAccount);
        PmtDiscountFCY := GetPmtDiscount(VendorLedgerEntry);
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);

        // Exercise. Unapply.
        LibraryERM.UnapplyVendorLedgerEntry(VendorLedgerEntry);

        // Verify.
        VendorLedgerEntry.SetAutoCalcFields("Original Amt. (LCY)", "Original Amount");
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Payment);
        VendorLedgerEntry.FindFirst();
        VerifyVATEntry(CurrencyExchangeRate, VATPostingSetup, VendorLedgerEntry, PmtDiscountFCY, 3);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test CH PAYDISC Purchase Docs");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Test CH PAYDISC Purchase Docs");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Adjust for Payment Disc.", true);
        GeneralLedgerSetup.Modify(true);

        SourceCodeSetup.Get();
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Test CH PAYDISC Purchase Docs");
    end;

    local procedure ApplyAfterPosting(var VendorLedgerEntry: Record "Vendor Ledger Entry"; Vendor: Record Vendor; GLAccount: Record "G/L Account")
    var
        InvGenJournalLine1: Record "Gen. Journal Line";
        InvGenJournalLine2: Record "Gen. Journal Line";
        PmtGenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Post invoices and payment.
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(InvGenJournalLine1, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          InvGenJournalLine1."Document Type"::Invoice, InvGenJournalLine1."Account Type"::Vendor, Vendor."No.",
          InvGenJournalLine1."Bal. Account Type"::"G/L Account", GLAccount."No.", -1 * LibraryRandom.RandDec(1000, 2));
        LibraryERM.CreateGeneralJnlLineWithBalAcc(InvGenJournalLine2, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          InvGenJournalLine2."Document Type"::Invoice, InvGenJournalLine2."Account Type"::Vendor, Vendor."No.",
          InvGenJournalLine2."Bal. Account Type"::"G/L Account", GLAccount."No.", -1 * LibraryRandom.RandDec(1000, 2));
        InvGenJournalLine2.Validate("Payment Discount %", LibraryRandom.RandInt(10));
        InvGenJournalLine2.Modify(true);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(PmtGenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          PmtGenJournalLine."Document Type"::Payment, PmtGenJournalLine."Account Type"::Vendor, Vendor."No.",
          PmtGenJournalLine."Bal. Account Type"::"G/L Account", GLAccount."No.",
          -InvGenJournalLine1.Amount - InvGenJournalLine2.Amount * (1 - InvGenJournalLine2."Payment Discount %" / 100));
        LibraryERM.PostGeneralJnlLine(InvGenJournalLine1);

        // Apply payment to invoices.
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);
    end;

    local procedure ApplyBeforePosting(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var PmtGenJournalLine: Record "Gen. Journal Line"; Vendor: Record Vendor; GLAccount: Record "G/L Account")
    var
        InvGenJournalLine1: Record "Gen. Journal Line";
        InvGenJournalLine2: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        AmtToApply: Decimal;
    begin
        // Post invoices.
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(InvGenJournalLine1, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          InvGenJournalLine1."Document Type"::Invoice, InvGenJournalLine1."Account Type"::Vendor, Vendor."No.",
          InvGenJournalLine1."Bal. Account Type"::"G/L Account", GLAccount."No.", -1 * LibraryRandom.RandDec(1000, 2));
        LibraryERM.CreateGeneralJnlLineWithBalAcc(InvGenJournalLine2, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          InvGenJournalLine2."Document Type"::Invoice, InvGenJournalLine2."Account Type"::Vendor, Vendor."No.",
          InvGenJournalLine2."Bal. Account Type"::"G/L Account", GLAccount."No.", -1 * LibraryRandom.RandDec(1000, 2));
        InvGenJournalLine2.Validate("Payment Discount %", LibraryRandom.RandInt(10));
        InvGenJournalLine2.Modify(true);
        LibraryERM.PostGeneralJnlLine(InvGenJournalLine1);

        // Create and apply payment.
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(PmtGenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          PmtGenJournalLine."Document Type"::Payment, PmtGenJournalLine."Account Type"::Vendor, Vendor."No.",
          PmtGenJournalLine."Bal. Account Type"::"G/L Account", GLAccount."No.", 0);
        PmtGenJournalLine.Validate("Applies-to ID", UserId);

        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        VendorLedgerEntry.FindSet();
        repeat
            SetAppliesToIdOnVendorLedgerEntry(VendorLedgerEntry, AmtToApply);
        until VendorLedgerEntry.Next() = 0;

        PmtGenJournalLine.Validate(Amount, -AmtToApply);
        PmtGenJournalLine.Modify(true);
    end;

    local procedure SetAppliesToIdOnVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var AmtToApply: Decimal)
    begin
        VendorLedgerEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
        VendorLedgerEntry.Validate("Applies-to ID", UserId);
        VendorLedgerEntry.Validate("Amount to Apply",
          VendorLedgerEntry."Remaining Amount" - VendorLedgerEntry."Remaining Pmt. Disc. Possible");
        CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", VendorLedgerEntry);
        AmtToApply += VendorLedgerEntry."Amount to Apply";
    end;

    local procedure GetPmtDiscount(var VendorLedgerEntry: Record "Vendor Ledger Entry"): Decimal
    begin
        VendorLedgerEntry.CalcSums("Original Pmt. Disc. Possible");
        exit(VendorLedgerEntry."Original Pmt. Disc. Possible");
    end;

    local procedure SetupVATForFCY(var VATPostingSetup: Record "VAT Posting Setup"; var CurrencyExchangeRate: Record "Currency Exchange Rate"; var Vendor: Record Vendor; var GLAccount: Record "G/L Account")
    var
        Currency: Record Currency;
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryCH.CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", '', '');
        VATPostingSetup.Validate("Adjust for Payment Discount", true);
        VATPostingSetup.Modify(true);

        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(), LibraryRandom.RandDec(10, 2),
          LibraryRandom.RandDec(10, 2));
        CurrencyExchangeRate.SetRange("Currency Code", Currency.Code);
        CurrencyExchangeRate.FindFirst();

        LibraryPurchase.CreateVendor(Vendor);
        Vendor."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        Vendor.Validate("Currency Code", CurrencyExchangeRate."Currency Code");
        Vendor.Modify(true);

        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        GeneralPostingSetup.Validate("Purch. Pmt. Disc. Credit Acc.", GeneralPostingSetup."Purch. Account");
        GeneralPostingSetup.Validate("Purch. Pmt. Disc. Debit Acc.", GeneralPostingSetup."Purch. Account");
        GeneralPostingSetup.Validate("Purch. Pmt. Tol. Credit Acc.", GeneralPostingSetup."Purch. Account");
        GeneralPostingSetup.Validate("Purch. Pmt. Tol. Debit Acc.", GeneralPostingSetup."Purch. Account");
        GeneralPostingSetup.Modify(true);

        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Purchase);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
    end;

    local procedure VerifyVATEntry(CurrencyExchangeRate: Record "Currency Exchange Rate"; VATPostingSetup: Record "VAT Posting Setup"; VendorLedgerEntry: Record "Vendor Ledger Entry"; PmtDiscountAmtFCY: Decimal; ExpEntries: Integer)
    var
        VATEntry: Record "VAT Entry";
        PrevTransactionNo: Integer;
        sign: Integer;
    begin
        VATEntry.SetRange("Bill-to/Pay-to No.", VendorLedgerEntry."Vendor No.");
        VATEntry.SetRange("Document Type", VendorLedgerEntry."Document Type");
        VATEntry.SetRange("Document No.", VendorLedgerEntry."Document No.");
        VATEntry.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type");
        VATEntry.SetRange("VAT %", VATPostingSetup."VAT %");
        VATEntry.SetRange("Currency Factor", CurrencyExchangeRate."Exchange Rate Amount");
        VATEntry.SetRange("Currency Code", CurrencyExchangeRate."Currency Code");
        VATEntry.SetRange("Unadjusted Exchange Rate", true);
        VATEntry.SetRange("Exchange Rate Adjustment", false);
        Assert.AreEqual(ExpEntries, VATEntry.Count, 'Unexpected VAT entries:' + VATEntry.GetFilters);

        VATEntry.SetCurrentKey("Transaction No.");
        VATEntry.SetRange("Source Code", SourceCodeSetup."General Journal");
        VATEntry.FindSet();
        sign := -1;
        repeat
            if VATEntry."Transaction No." <> PrevTransactionNo then
                sign *= -1;
            case VATEntry."Sales Tax Connection No." of
                1, 3:
                    begin
                        Assert.AreEqual(-VendorLedgerEntry."Original Amt. (LCY)", sign * (VATEntry.Base + VATEntry.Amount),
                          'Wrong VAT LCY total.');
                        Assert.AreEqual(-VendorLedgerEntry."Original Amount", VATEntry."Base (FCY)" + VATEntry."Amount (FCY)",
                          'Wrong VAT FCY total.');
                        Assert.AreEqual(Round(-VendorLedgerEntry."Original Amt. (LCY)" / (1 + VATPostingSetup."VAT %" / 100),
                            GeneralLedgerSetup."Amount Rounding Precision"), sign * VATEntry.Base, 'Wrong VAT Base Amount LCY.');
                        Assert.AreEqual(Round(-VendorLedgerEntry."Original Amount" / (1 + VATPostingSetup."VAT %" / 100),
                            GeneralLedgerSetup."Amount Rounding Precision"), VATEntry."Base (FCY)", 'Wrong VAT Base Amount FCY.');
                    end;
                2:
                    Assert.AreNearlyEqual(PmtDiscountAmtFCY, VATEntry."Base (FCY)" + VATEntry."Amount (FCY)",
                      GeneralLedgerSetup."Inv. Rounding Precision (LCY)", 'Wrong Disc VAT FCY total.');
            end;
            PrevTransactionNo := VATEntry."Transaction No.";
        until VATEntry.Next() = 0;

        VATEntry.SetRange("Source Code", SourceCodeSetup.Reversal);
        if VATEntry.FindSet() then
            repeat
                case VATEntry."Sales Tax Connection No." of
                    1, 3:
                        begin
                            Assert.AreEqual(-VendorLedgerEntry."Original Amt. (LCY)", -VATEntry.Base - VATEntry.Amount, 'Wrong VAT LCY total.');
                            Assert.AreEqual(-VendorLedgerEntry."Original Amount", -VATEntry."Base (FCY)" - VATEntry."Amount (FCY)",
                              'Wrong VAT FCY total.');
                            Assert.AreEqual(Round(-VendorLedgerEntry."Original Amt. (LCY)" / (1 + VATPostingSetup."VAT %" / 100),
                                GeneralLedgerSetup."Amount Rounding Precision"), -VATEntry.Base, 'Wrong VAT Base Amount LCY.');
                            Assert.AreEqual(Round(-VendorLedgerEntry."Original Amount" / (1 + VATPostingSetup."VAT %" / 100),
                                GeneralLedgerSetup."Amount Rounding Precision"), -VATEntry."Base (FCY)", 'Wrong VAT Base Amount FCY.');
                        end;
                    2:
                        Assert.AreNearlyEqual(PmtDiscountAmtFCY, -VATEntry."Base (FCY)" - VATEntry."Amount (FCY)",
                          GeneralLedgerSetup."Inv. Rounding Precision (LCY)", 'Wrong Disc VAT FCY total.');
                end;
            until VATEntry.Next() = 0;

        VATEntry.SetRange("Source Code", SourceCodeSetup."Purchase Entry Application");
        if VATEntry.FindSet() then
            repeat
                Assert.AreNearlyEqual(PmtDiscountAmtFCY, VATEntry."Base (FCY)" + VATEntry."Amount (FCY)",
                  GeneralLedgerSetup."Inv. Rounding Precision (LCY)", 'Wrong Disc VAT FCY total.');
            until VATEntry.Next() = 0;
    end;

    local procedure VerifyApplicationWithVATBalancingError(GenJournalLine: Record "Gen. Journal Line")
    begin
        Assert.ExpectedError(
            StrSubstNo(
                PmtApplnErr, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No."));
    end;
}

