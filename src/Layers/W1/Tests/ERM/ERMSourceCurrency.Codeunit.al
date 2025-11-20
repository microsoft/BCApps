codeunit 134897 "ERM Source Currency"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        isInitialized: Boolean;
        AmountIncorrectSignErr: Label 'The Source Currency Amount should have the same sign as the amount on the G/L Entry', Locked = true;
        VATAmountIncorrectErr: Label 'The Source Currency Amount should be equal to the amount %1 multiplied by the VAT % %2', Locked = true;
        AmountExclVATIncorrectErr: Label 'The Source Currency Amount should be equal to the amount excl. VAT', Locked = true;
        BalancingAmountIncorrectErr: Label 'The Source Currency Amount should be equal to the negative amount', Locked = true;
        UnexpectedAccountNoErr: Label 'Unexpected G/L Account No. %1', Locked = true;
        TotalSCYAmountNotZeroErr: Label 'The sum of Source Currency Amount should be 0', Locked = true;
        SourceCurrencyCodeErr: Label 'The Source Currency Code should be equal to the Currency Code on the General Journal Line', Locked = true;
        SourceCurrencyCodeFXGainLossErr: Label 'The Source Currency Code should be empty on the G/L Entry for FX Gain/Loss', Locked = true;
        SourceCurrencyAmountShouldBeZeroErr: Label 'The Source Currency Amount should be 0', Locked = true;

    [Test]
    procedure GenJournalPurchaseNormalVATLCY()
    begin
        GenJournalPurchaseNormalVAT(false);
    end;

    [Test]
    procedure GenJournalPurchaseNormalVATFCY()
    begin
        GenJournalPurchaseNormalVAT(true);
    end;

    local procedure GenJournalPurchaseNormalVAT(ForeignCurrency: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        Factor: Integer;
        SCYBalance: Decimal;
        VATAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] VAT Posting Setup with normal VAT.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        UpdateAdjustForPaymentDiscount(VATPostingSetup);

        // [GIVEN] A General Journal Line.
        CreateGeneralJournalLine(
            GenJournalLine,
            LibraryERM.CreateGLAccountNoWithDirectPosting(),
            LibraryERM.CreateGLAccountNoWithDirectPosting(),
            Enum::"General Posting Type"::Purchase,
            VATPostingSetup,
            ForeignCurrency);

        // [WHEN] Posting the General Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        GetGLEntries(GLEntry, GenJournalLine."Document No.", GenJournalLine."Document Type");

        VATAmount := Round(Abs(GenJournalLine.Amount) * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %"), 0.01, '=');
        repeat
            // [THEN] Source Currency Code on G/L Entries should be correct.
            Assert.AreEqual(GenJournalLine."Currency Code", GLEntry."Source Currency Code", SourceCurrencyCodeErr);

            Factor := GLEntry.Amount <> 0 ? GLEntry.Amount / Abs(GLEntry.Amount) : 1;

            case GLEntry."G/L Account No." of
                VATPostingSetup."Purchase VAT Account":
                    begin
                        // [THEN] Source Currency Amount on G/L Entries for VAT account should have correct factor.
                        Assert.AreEqual(Factor, GLEntry."Source Currency Amount" / Abs(GLEntry."Source Currency Amount"), AmountIncorrectSignErr);

                        // [THEN] Source Currency Amount on Purchase VAT account should be equal to expected VAT amount.
                        Assert.AreNearlyEqual(VATAmount * Factor, GLEntry."Source Currency Amount", 0.01, StrSubstNo(VATAmountIncorrectErr, GenJournalLine.Amount, VATPostingSetup."VAT %"));
                    end;
                GenJournalLine."Account No.":
                    // [THEN] Source Currency Amount on G/L Entry for Account No. should be equal to the amount excl. VAT on the general journal line.
                    Assert.AreNearlyEqual(GenJournalLine.Amount - (Factor * VATAmount), GLEntry."Source Currency Amount", 0.01, AmountExclVATIncorrectErr);
                GenJournalLine."Bal. Account No.":
                    // [THEN] Source Currency Amount on G/L Entries for Bal. Account No. should be equal to the negative amount on the general journal line.
                    Assert.AreEqual(-GenJournalLine.Amount, GLEntry."Source Currency Amount", BalancingAmountIncorrectErr);
                else
                    Error(UnexpectedAccountNoErr, GLEntry."G/L Account No.");
            end;
            SCYBalance += GLEntry."Source Currency Amount";
        until GLEntry.Next() = 0;

        // [THEN] Source Currency Amount on G/L Entries should balance to 0.
        Assert.AreNearlyEqual(0, SCYBalance, 0.01, TotalSCYAmountNotZeroErr);
    end;


    [Test]
    procedure GenJournalPurchaseReverseChargeVATLCY()
    begin
        GenJournalPurchaseReverseChargeVAT(false);
    end;

    [Test]
    procedure GenJournalPurchaseReverseChargeVATFCY()
    begin
        GenJournalPurchaseReverseChargeVAT(true);
    end;

    local procedure GenJournalPurchaseReverseChargeVAT(ForeignCurrency: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        Factor: Integer;
        SCYBalance: Decimal;
        VATAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] VAT Posting Setup with reverse charge VAT.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        UpdateAdjustForPaymentDiscount(VATPostingSetup);
        if VATPostingSetup."Reverse Chrg. VAT Acc." = '' then begin
            VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
            VATPostingSetup.Modify();
        end;

        // [GIVEN] A General Journal Line.
        CreateGeneralJournalLine(
            GenJournalLine,
            LibraryERM.CreateGLAccountNoWithDirectPosting(),
            LibraryERM.CreateGLAccountNoWithDirectPosting(),
            Enum::"General Posting Type"::Purchase,
            VATPostingSetup,
            ForeignCurrency);

        // [WHEN] Posting the General Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        GetGLEntries(GLEntry, GenJournalLine."Document No.", GenJournalLine."Document Type");

        VATAmount := Round(Abs(GenJournalLine.Amount) * VATPostingSetup."VAT %" / 100, 0.01, '=');
        repeat
            // [THEN] Source Currency Code on G/L Entries should be correct.
            Assert.AreEqual(GenJournalLine."Currency Code", GLEntry."Source Currency Code", SourceCurrencyCodeErr);

            Factor := GLEntry.Amount <> 0 ? GLEntry.Amount / Abs(GLEntry.Amount) : 1;
            case GLEntry."G/L Account No." of
                VATPostingSetup."Purchase VAT Account",
                VATPostingSetup.GetRevChargeAccount(false):
                    begin
                        // [THEN] Source Currency Amount on G/L Entries for VAT account should have correct factor.
                        if GLEntry."Source Currency Amount" <> 0 then
                            Assert.AreEqual(Factor, GLEntry."Source Currency Amount" / Abs(GLEntry."Source Currency Amount"), AmountIncorrectSignErr);

                        // [THEN] Source Currency Amount on Purchase VAT account should be equal to expected VAT amount.
                        Assert.AreNearlyEqual(VATAmount * Factor, GLEntry."Source Currency Amount", 0.01, StrSubstNo(VATAmountIncorrectErr, GenJournalLine.Amount, VATPostingSetup."VAT %"));
                    end;
                GenJournalLine."Account No.":
                    // [THEN] Source Currency Amount on G/L Entry for Account No. should be equal to the amount on the general journal line.
                    Assert.AreEqual(GenJournalLine.Amount, GLEntry."Source Currency Amount", AmountExclVATIncorrectErr);
                GenJournalLine."Bal. Account No.":
                    // [THEN] Source Currency Amount on G/L Entries for Bal. Account No. should be equal to the negative amount on the general journal line.
                    Assert.AreEqual(-GenJournalLine.Amount, GLEntry."Source Currency Amount", BalancingAmountIncorrectErr);
                else
                    Error(UnexpectedAccountNoErr, GLEntry."G/L Account No.");
            end;
            SCYBalance += GLEntry."Source Currency Amount";
        until GLEntry.Next() = 0;

        // [THEN] Source Currency Amount on G/L Entries should balance to 0.
        Assert.AreEqual(0, SCYBalance, TotalSCYAmountNotZeroErr);
    end;

    [Test]
    procedure GenJournalPurchaseFullVATLCY()
    begin
        GenJournalPurchaseFullVAT(false);
    end;

    [Test]
    procedure GenJournalPurchaseFullVATFCY()
    begin
        GenJournalPurchaseFullVAT(true);
    end;

    local procedure GenJournalPurchaseFullVAT(ForeignCurrency: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        Factor: Integer;
        SCYBalance: Decimal;
        VATAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] VAT Posting Setup with full VAT.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Full VAT");
        UpdateAdjustForPaymentDiscount(VATPostingSetup);

        // [GIVEN] Purchase VAT Account set fore Direct Posting
        GLAccount.Get(VATPostingSetup."Purchase VAT Account");
        GLAccount."Direct Posting" := true;
        GLAccount.Modify();

        // [GIVEN] A General Journal Line.
        CreateGeneralJournalLine(
            GenJournalLine,
            VATPostingSetup."Purchase VAT Account",
            LibraryERM.CreateGLAccountNoWithDirectPosting(),
            Enum::"General Posting Type"::Purchase,
            VATPostingSetup,
            ForeignCurrency);

        // [WHEN] Posting the General Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        GetGLEntries(GLEntry, GenJournalLine."Document No.", GenJournalLine."Document Type");

        VATAmount := Abs(GenJournalLine.Amount);
        repeat
            // [THEN] Source Currency Code on G/L Entries should be correct.
            Assert.AreEqual(GenJournalLine."Currency Code", GLEntry."Source Currency Code", SourceCurrencyCodeErr);

            Factor := GLEntry.Amount <> 0 ? GLEntry.Amount / Abs(GLEntry.Amount) : 1;
            case GLEntry."G/L Account No." of
                VATPostingSetup."Purchase VAT Account":
                    if GLEntry.Amount = 0 then
                        Assert.AreEqual(0, GLEntry."Source Currency Amount", SourceCurrencyAmountShouldBeZeroErr)
                    else begin
                        // [THEN] Source Currency Amount on G/L Entries for VAT account should have correct factor.
                        Assert.AreEqual(Factor, GLEntry."Source Currency Amount" / Abs(GLEntry."Source Currency Amount"), AmountIncorrectSignErr);
                        // [THEN] Source Currency Amount on Purchase VAT account should be equal to expected VAT amount.
                        Assert.AreEqual(VATAmount * Factor, GLEntry."Source Currency Amount", StrSubstNo(VATAmountIncorrectErr, GenJournalLine.Amount, VATPostingSetup."VAT %"));
                    end;
                GenJournalLine."Bal. Account No.":
                    // [THEN] Source Currency Amount on G/L Entries for Bal. Account No. should be equal to the negative amount on the general journal line.
                    Assert.AreEqual(-GenJournalLine.Amount, GLEntry."Source Currency Amount", BalancingAmountIncorrectErr);
                else
                    Error(UnexpectedAccountNoErr, GLEntry."G/L Account No.");
            end;
            SCYBalance += GLEntry."Source Currency Amount";
        until GLEntry.Next() = 0;

        // [THEN] Source Currency Amount on G/L Entries should balance to 0.
        Assert.AreEqual(0, SCYBalance, TotalSCYAmountNotZeroErr);
    end;

    [Test]
    procedure GenJournalSalesNormalVATLCY()
    begin
        GenJournalSalesNormalVAT(false);
    end;

    [Test]
    procedure GenJournalSalesNormalVATFCY()
    begin
        GenJournalSalesNormalVAT(true);
    end;

    local procedure GenJournalSalesNormalVAT(ForeignCurrency: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        Factor: Integer;
        SCYBalance: Decimal;
        VATAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] VAT Posting Setup with normal VAT.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        UpdateAdjustForPaymentDiscount(VATPostingSetup);

        // [GIVEN] A General Journal Line.
        CreateGeneralJournalLine(
            GenJournalLine,
            LibraryERM.CreateGLAccountNoWithDirectPosting(),
            LibraryERM.CreateGLAccountNoWithDirectPosting(),
            Enum::"General Posting Type"::Sale,
            VATPostingSetup,
            ForeignCurrency);

        // [WHEN] Posting the General Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        GetGLEntries(GLEntry, GenJournalLine."Document No.", GenJournalLine."Document Type");

        VATAmount := Round(Abs(GenJournalLine.Amount) * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %"), 0.01, '=');
        repeat
            // [THEN] Source Currency Code on G/L Entries should be correct.
            Assert.AreEqual(GenJournalLine."Currency Code", GLEntry."Source Currency Code", SourceCurrencyCodeErr);

            Factor := GLEntry.Amount <> 0 ? GLEntry.Amount / Abs(GLEntry.Amount) : 1;
            case GLEntry."G/L Account No." of
                VATPostingSetup."Sales VAT Account":
                    begin
                        // [THEN] Source Currency Amount on G/L Entries for VAT account should have correct factor.
                        Assert.AreEqual(Factor, GLEntry."Source Currency Amount" / Abs(GLEntry."Source Currency Amount"), AmountIncorrectSignErr);

                        // [THEN] Source Currency Amount on Purchase VAT account should be equal to expected VAT amount.
                        Assert.AreNearlyEqual(VATAmount * Factor, GLEntry."Source Currency Amount", 0.01, StrSubstNo(VATAmountIncorrectErr, GenJournalLine.Amount, VATPostingSetup."VAT %"));
                    end;
                GenJournalLine."Account No.":
                    // [THEN] Source Currency Amount on G/L Entry for Account No. should be equal to the amount excl. VAT on the general journal line.
                    Assert.AreNearlyEqual(GenJournalLine.Amount - (Factor * VATAmount), GLEntry."Source Currency Amount", 0.01, AmountExclVATIncorrectErr);
                GenJournalLine."Bal. Account No.":
                    // [THEN] Source Currency Amount on G/L Entries for Bal. Account No. should be equal to the negative amount on the general journal line.
                    Assert.AreEqual(-GenJournalLine.Amount, GLEntry."Source Currency Amount", BalancingAmountIncorrectErr);
                else
                    Error(UnexpectedAccountNoErr, GLEntry."G/L Account No.");
            end;
            SCYBalance += GLEntry."Source Currency Amount";
        until GLEntry.Next() = 0;

        // [THEN] Source Currency Amount on G/L Entries should balance to 0.
        Assert.AreNearlyEqual(0, SCYBalance, 0.01, TotalSCYAmountNotZeroErr);
    end;

    [Test]
    procedure GenJournalSalesReverseChargeVATLCY()
    begin
        GenJournalSalesReverseChargeVAT(false);
    end;

    [Test]
    procedure GenJournalSalesReverseChargeVATFCY()
    begin
        GenJournalSalesReverseChargeVAT(true);
    end;

    local procedure GenJournalSalesReverseChargeVAT(ForeignCurrency: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        SCYBalance: Decimal;
    begin
        Initialize();

        // [GIVEN] VAT Posting Setup with reverse charge VAT.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        UpdateAdjustForPaymentDiscount(VATPostingSetup);
        if VATPostingSetup."Reverse Chrg. VAT Acc." = '' then begin
            VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
            VATPostingSetup.Modify();
        end;

        // [GIVEN] A General Journal Line.
        CreateGeneralJournalLine(
            GenJournalLine,
            LibraryERM.CreateGLAccountNoWithDirectPosting(),
            LibraryERM.CreateGLAccountNoWithDirectPosting(),
            Enum::"General Posting Type"::Sale,
            VATPostingSetup,
            ForeignCurrency);

        // [WHEN] Posting the General Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        GetGLEntries(GLEntry, GenJournalLine."Document No.", GenJournalLine."Document Type");

        repeat
            // [THEN] Source Currency Code on G/L Entries should be correct.
            Assert.AreEqual(GenJournalLine."Currency Code", GLEntry."Source Currency Code", SourceCurrencyCodeErr);

            case GLEntry."G/L Account No." of
                VATPostingSetup."Reverse Chrg. VAT Acc.":
                    // [THEN] There should be no VAT posting for sales when using reverse charge VAT.
                    Error('There should be no VAT posting for sales when using Reverse Charge VAT');
                GenJournalLine."Account No.":
                    // [THEN] Source Currency Amount on G/L Entry for Account No. should be equal to the amount on the general journal line.
                    Assert.AreEqual(GenJournalLine.Amount, GLEntry."Source Currency Amount", AmountExclVATIncorrectErr);
                GenJournalLine."Bal. Account No.":
                    // [THEN] Source Currency Amount on G/L Entries for Bal. Account No. should be equal to the negative amount on the general journal line.
                    Assert.AreEqual(-GenJournalLine.Amount, GLEntry."Source Currency Amount", BalancingAmountIncorrectErr);
                else
                    Error(UnexpectedAccountNoErr, GLEntry."G/L Account No.");
            end;
            SCYBalance += GLEntry."Source Currency Amount";
        until GLEntry.Next() = 0;

        // [THEN] Source Currency Amount on G/L Entries should balance to 0.
        Assert.AreEqual(0, SCYBalance, TotalSCYAmountNotZeroErr);
    end;

    [Test]
    procedure GenJournalSalesFullVATLCY()
    begin
        GenJournalSalesFullVAT(false);
    end;

    [Test]
    procedure GenJournalSalesFullVATFCY()
    begin
        GenJournalSalesFullVAT(true);
    end;

    local procedure GenJournalSalesFullVAT(ForeignCurrency: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        Factor: Integer;
        SCYBalance: Decimal;
        VATAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] VAT Posting Setup with full VAT.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Full VAT");
        UpdateAdjustForPaymentDiscount(VATPostingSetup);

        // [GIVEN] A General Journal Line.
        CreateGeneralJournalLine(
            GenJournalLine,
            VATPostingSetup."Sales VAT Account",
            LibraryERM.CreateGLAccountNoWithDirectPosting(),
            Enum::"General Posting Type"::Sale,
            VATPostingSetup,
            ForeignCurrency);

        // [WHEN] Posting the General Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        GetGLEntries(GLEntry, GenJournalLine."Document No.", GenJournalLine."Document Type");

        VATAmount := Abs(GenJournalLine.Amount);
        repeat
            // [THEN] Source Currency Code on G/L Entries should be correct.
            Assert.AreEqual(GenJournalLine."Currency Code", GLEntry."Source Currency Code", SourceCurrencyCodeErr);

            Factor := GLEntry.Amount <> 0 ? GLEntry.Amount / Abs(GLEntry.Amount) : 1;
            case GLEntry."G/L Account No." of
                VATPostingSetup."Sales VAT Account":
                    if GLEntry.Amount = 0 then
                        Assert.AreEqual(0, GLEntry."Source Currency Amount", SourceCurrencyAmountShouldBeZeroErr)
                    else begin
                        // [THEN] Source Currency Amount on G/L Entries for VAT account should have correct factor.
                        Assert.AreEqual(Factor, GLEntry."Source Currency Amount" / Abs(GLEntry."Source Currency Amount"), AmountIncorrectSignErr);
                        // [THEN] Source Currency Amount on Purchase VAT account should be equal to expected VAT amount.
                        Assert.AreEqual(VATAmount * Factor, GLEntry."Source Currency Amount", StrSubstNo(VATAmountIncorrectErr, GenJournalLine.Amount, VATPostingSetup."VAT %"));
                    end;
                GenJournalLine."Bal. Account No.":
                    // [THEN] Source Currency Amount on G/L Entries for Bal. Account No. should be equal to the negative amount on the general journal line.
                    Assert.AreEqual(-GenJournalLine.Amount, GLEntry."Source Currency Amount", BalancingAmountIncorrectErr);
                else
                    Error(UnexpectedAccountNoErr, GLEntry."G/L Account No.");
            end;
            SCYBalance += GLEntry."Source Currency Amount";
        until GLEntry.Next() = 0;

        // [THEN] Source Currency Amount on G/L Entries should balance to 0.
        Assert.AreEqual(0, SCYBalance, TotalSCYAmountNotZeroErr);
    end;

    [Test]
    procedure PurchaseInvoiceNormalVATLCY()
    begin
        PurchaseInvoiceNormalVAT(false);
    end;

    [Test]
    procedure PurchaseInvoiceNormalVATFCY()
    begin
        PurchaseInvoiceNormalVAT(true);
    end;

    local procedure PurchaseInvoiceNormalVAT(WithForeignCurrency: Boolean)
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        VendorNo: Code[20];
        PostedPurchaseInvoiceNo: Code[20];
        Factor: Integer;
        SCYBalance: Decimal;
        VATAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] Vendor with new posting groups with normal VAT.
        VendorNo := CreateVendorWithNewPostingGroups(VendorPostingGroup, GeneralPostingSetup, VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        // [GIVEN] A Purchase Invoice for a G/L Account.
        CreateGLAccount(GLAccount, Enum::"General Posting Type"::Purchase, GeneralPostingSetup, VATPostingSetup);
        CreatePurchaseInvoice(PurchaseHeader, VendorNo, GLAccount."No.", WithForeignCurrency);

        // [WHEN] Posting a Purchase Invoice with normal VAT.
        PostedPurchaseInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        GetGLEntries(GLEntry, PostedPurchaseInvoiceNo, GLEntry."Document Type"::Invoice);

        VATAmount := PurchaseHeader."Doc. Amount VAT";
        repeat
            // [THEN] Source Currency Code on G/L Entries should be correct.
            Assert.AreEqual(PurchaseHeader."Currency Code", GLEntry."Source Currency Code", SourceCurrencyCodeErr);

            Factor := GLEntry.Amount <> 0 ? GLEntry.Amount / Abs(GLEntry.Amount) : 1;
            case GLEntry."G/L Account No." of
                VATPostingSetup."Purchase VAT Account":
                    begin
                        // [THEN] Source Currency Amount on G/L Entries for VAT account should have correct factor.
                        Assert.AreEqual(Factor, GLEntry."Source Currency Amount" / Abs(GLEntry."Source Currency Amount"), AmountIncorrectSignErr);

                        // [THEN] Source Currency Amount on Purchase VAT account should be equal to expected VAT amount.
                        Assert.AreEqual(VATAmount * Factor, GLEntry."Source Currency Amount", StrSubstNo(VATAmountIncorrectErr, PurchaseHeader.Amount, VATPostingSetup."VAT %"));
                    end;
                VendorPostingGroup.GetPayablesAccount():
                    // [THEN] Source Currency Amount on G/L Entry for Payables Account No. should be equal to the amount incl. VAT on the purchase invoice.
                    Assert.AreEqual(-PurchaseHeader."Amount Including VAT", GLEntry."Source Currency Amount", 'The Source Currency Amount should be equal to the amount including VAT on the purchase invoice');
                GLAccount."No.":
                    // [THEN] Source Currency Amount on G/L Entry for GL Account No. should be equal to the amount excl. VAT on the purchase invoice
                    Assert.AreEqual(PurchaseHeader."Amount Including VAT" - (Factor * VATAmount), GLEntry."Source Currency Amount", AmountExclVATIncorrectErr);
                else
                    Error(UnexpectedAccountNoErr, GLEntry."G/L Account No.");
            end;
            SCYBalance += GLEntry."Source Currency Amount";
        until GLEntry.Next() = 0;

        // [THEN] Source Currency Amount on G/L Entries should balance to 0.
        Assert.AreNearlyEqual(0, SCYBalance, 0.01, TotalSCYAmountNotZeroErr);
    end;

    [Test]
    procedure PurchaseInvoiceReverseChargeVATLCY()
    begin
        PurchaseInvoiceReverseChargeVAT(false);
    end;

    [Test]
    procedure PurchaseInvoiceReverseChargeVATFCY()
    begin
        PurchaseInvoiceReverseChargeVAT(true);
    end;

    local procedure PurchaseInvoiceReverseChargeVAT(WithForeignCurrency: Boolean)
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        VendorNo: Code[20];
        PostedPurchaseInvoiceNo: Code[20];
        Factor: Integer;
        SCYBalance: Decimal;
        VATAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] Vendor with new posting groups with normal VAT.
        VendorNo := CreateVendorWithNewPostingGroups(VendorPostingGroup, GeneralPostingSetup, VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify();

        // [GIVEN] A Purchase Invoice for a G/L Account.
        CreateGLAccount(GLAccount, Enum::"General Posting Type"::Purchase, GeneralPostingSetup, VATPostingSetup);
        CreatePurchaseInvoice(PurchaseHeader, VendorNo, GLAccount."No.", WithForeignCurrency);

        // [WHEN] Posting a Purchase Invoice with normal VAT.
        PostedPurchaseInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        GetGLEntries(GLEntry, PostedPurchaseInvoiceNo, GLEntry."Document Type"::Invoice);

        VATAmount := Round(PurchaseHeader."Doc. Amount Incl. VAT" * VATPostingSetup."VAT %" / 100, 0.01, '=');
        repeat
            // [THEN] Source Currency Code on G/L Entries should be correct.
            Assert.AreEqual(PurchaseHeader."Currency Code", GLEntry."Source Currency Code", SourceCurrencyCodeErr);

            Factor := GLEntry.Amount <> 0 ? GLEntry.Amount / Abs(GLEntry.Amount) : 1;
            case GLEntry."G/L Account No." of
                VATPostingSetup."Purchase VAT Account",
                VATPostingSetup.GetRevChargeAccount(false):
                    begin
                        // [THEN] Source Currency Amount on G/L Entries for VAT account should have correct factor.
                        Assert.AreEqual(Factor, GLEntry."Source Currency Amount" / Abs(GLEntry."Source Currency Amount"), AmountIncorrectSignErr);

                        // [THEN] Source Currency Amount on Purchase VAT account should be equal to expected VAT amount.
                        Assert.AreEqual(VATAmount * Factor, GLEntry."Source Currency Amount", StrSubstNo(VATAmountIncorrectErr, PurchaseHeader.Amount, VATPostingSetup."VAT %"));
                    end;
                VendorPostingGroup.GetPayablesAccount():
                    // [THEN] Source Currency Amount on G/L Entry for Payables Account No. should be equal to the amount incl. VAT on the purchase invoice.
                    Assert.AreEqual(-PurchaseHeader."Amount Including VAT", GLEntry."Source Currency Amount", 'The Source Currency Amount should be equal to the amount including VAT on the purchase invoice');
                GLAccount."No.":
                    // [THEN] Source Currency Amount on G/L Entry for GL Account No. should be equal to the amount incl. VAT on the purchase invoice
                    Assert.AreEqual(PurchaseHeader."Amount Including VAT", GLEntry."Source Currency Amount", AmountExclVATIncorrectErr);
                else
                    Error(UnexpectedAccountNoErr, GLEntry."G/L Account No.");
            end;
            SCYBalance += GLEntry."Source Currency Amount";
        until GLEntry.Next() = 0;

        // [THEN] Source Currency Amount on G/L Entries should balance to 0.
        Assert.AreEqual(0, SCYBalance, TotalSCYAmountNotZeroErr);
    end;

    [Test]
    procedure PurchaseInvoiceFullVATLCY()
    begin
        PurchaseInvoiceFullVAT(false);
    end;

    [Test]
    procedure PurchaseInvoiceFullVATFCY()
    begin
        PurchaseInvoiceFullVAT(true);
    end;

    local procedure PurchaseInvoiceFullVAT(WithForeignCurrency: Boolean)
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        VendorNo: Code[20];
        PostedPurchaseInvoiceNo: Code[20];
        Factor: Integer;
        SCYBalance: Decimal;
        VATAmount: Decimal;
        GLAccountNo: Code[20];
    begin
        Initialize();

        // [GIVEN] Vendor with new posting groups with normal VAT.
        VendorNo := CreateVendorWithNewPostingGroups(VendorPostingGroup, GeneralPostingSetup, VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Full VAT");
        GLAccount.Get(VATPostingSetup."Purchase VAT Account");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify();

        // [GIVEN] A Purchase Invoice for a G/L Account.
        GLAccountNo := VATPostingSetup."Purchase VAT Account";
        CreatePurchaseInvoice(PurchaseHeader, VendorNo, GLAccountNo, WithForeignCurrency);

        // [WHEN] Posting a Purchase Invoice with normal VAT.
        PostedPurchaseInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        GetGLEntries(GLEntry, PostedPurchaseInvoiceNo, GLEntry."Document Type"::Invoice);

        VATAmount := PurchaseHeader."Doc. Amount VAT";
        repeat
            // [THEN] Source Currency Code on G/L Entries should be correct.
            Assert.AreEqual(PurchaseHeader."Currency Code", GLEntry."Source Currency Code", SourceCurrencyCodeErr);

            Factor := GLEntry.Amount <> 0 ? GLEntry.Amount / Abs(GLEntry.Amount) : 1;
            case GLEntry."G/L Account No." of
                VATPostingSetup."Purchase VAT Account":
                    if GLEntry.Amount = 0 then
                        Assert.AreEqual(0, GLEntry."Source Currency Amount", SourceCurrencyAmountShouldBeZeroErr)
                    else begin
                        // [THEN] Source Currency Amount on G/L Entries for VAT account should have correct factor.
                        Assert.AreEqual(Factor, GLEntry."Source Currency Amount" / Abs(GLEntry."Source Currency Amount"), AmountIncorrectSignErr);
                        // [THEN] Source Currency Amount on Purchase VAT account should be equal to expected VAT amount.
                        Assert.AreEqual(VATAmount * Factor, GLEntry."Source Currency Amount", StrSubstNo(VATAmountIncorrectErr, PurchaseHeader.Amount, VATPostingSetup."VAT %"));
                    end;
                VendorPostingGroup.GetPayablesAccount():
                    // [THEN] Source Currency Amount on G/L Entry for Payables Account No. should be equal to the amount incl. VAT on the purchase invoice.
                    Assert.AreEqual(-PurchaseHeader."Amount Including VAT", GLEntry."Source Currency Amount", 'The Source Currency Amount should be equal to the amount including VAT on the purchase invoice');
                else
                    Error(UnexpectedAccountNoErr, GLEntry."G/L Account No.");
            end;
            SCYBalance += GLEntry."Source Currency Amount";
        until GLEntry.Next() = 0;

        // [THEN] Source Currency Amount on G/L Entries should balance to 0.
        Assert.AreEqual(0, SCYBalance, TotalSCYAmountNotZeroErr);
    end;

    [Test]
    procedure SalesInvoiceNormalVATLCY()
    begin
        SalesInvoiceNormalVAT(false);
    end;

    [Test]
    procedure SalesInvoiceNormalVATFCY()
    begin
        SalesInvoiceNormalVAT(true);
    end;

    local procedure SalesInvoiceNormalVAT(WithForeignCurrency: Boolean)
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        CustomerNo: Code[20];
        PostedSalesInvoiceNo: Code[20];
        Factor: Integer;
        SCYBalance: Decimal;
        VATAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] Customer with new posting groups with normal VAT.
        CustomerNo := CreateCustomerWithNewPostingGroups(CustomerPostingGroup, GeneralPostingSetup, VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        // [GIVEN] A Sales Invoice for a G/L Account.
        CreateGLAccount(GLAccount, Enum::"General Posting Type"::Sale, GeneralPostingSetup, VATPostingSetup);
        CreateSalesInvoice(SalesHeader, CustomerNo, GLAccount."No.", WithForeignCurrency);

        // [WHEN] Posting a Sales Invoice with normal VAT.
        PostedSalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        GetGLEntries(GLEntry, PostedSalesInvoiceNo, GLEntry."Document Type"::Invoice);

        VATAmount := SalesHeader."Amount Including VAT" - SalesHeader.Amount;
        repeat
            // [THEN] Source Currency Code on G/L Entries should be correct.
            Assert.AreEqual(SalesHeader."Currency Code", GLEntry."Source Currency Code", SourceCurrencyCodeErr);

            Factor := GLEntry.Amount <> 0 ? GLEntry.Amount / Abs(GLEntry.Amount) : 1;
            case GLEntry."G/L Account No." of
                VATPostingSetup."Sales VAT Account":
                    begin
                        // [THEN] Source Currency Amount on G/L Entries for VAT account should have correct factor.
                        Assert.AreEqual(Factor, GLEntry."Source Currency Amount" / Abs(GLEntry."Source Currency Amount"), AmountIncorrectSignErr);

                        // [THEN] Source Currency Amount on Sales VAT account should be equal to expected VAT amount.
                        Assert.AreEqual(VATAmount * Factor, GLEntry."Source Currency Amount", StrSubstNo(VATAmountIncorrectErr, SalesHeader.Amount, VATPostingSetup."VAT %"));
                    end;
                CustomerPostingGroup.GetReceivablesAccount():
                    // [THEN] Source Currency Amount on G/L Entry for Receivables Account No. should be equal to the amount incl. VAT on the sales invoice.
                    Assert.AreEqual(SalesHeader."Amount Including VAT", GLEntry."Source Currency Amount", 'The Source Currency Amount should be equal to the amount including VAT on the sales invoice');
                GLAccount."No.":
                    // [THEN] Source Currency Amount on G/L Entry for GL Account No. should be equal to the amount excl. VAT on the sales invoice
                    Assert.AreEqual(-SalesHeader.Amount, GLEntry."Source Currency Amount", AmountExclVATIncorrectErr);
                else
                    Error(UnexpectedAccountNoErr, GLEntry."G/L Account No.");
            end;
            SCYBalance += GLEntry."Source Currency Amount";
        until GLEntry.Next() = 0;

        // [THEN] Source Currency Amount on G/L Entries should balance to 0.
        Assert.AreEqual(0, SCYBalance, TotalSCYAmountNotZeroErr);
    end;

    [Test]
    procedure SalesInvoiceReverseChargeVATLCY()
    begin
        SalesInvoiceReverseChargeVAT(false);
    end;

    [Test]
    procedure SalesInvoiceReverseChargeVATFCY()
    begin
        SalesInvoiceReverseChargeVAT(true);
    end;

    local procedure SalesInvoiceReverseChargeVAT(WithForeignCurrency: Boolean)
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        CustomerNo: Code[20];
        PostedSalesInvoiceNo: Code[20];
        SCYBalance: Decimal;
    begin
        Initialize();

        // [GIVEN] Customer with new posting groups with reverse charge VAT.
        CustomerNo := CreateCustomerWithNewPostingGroups(CustomerPostingGroup, GeneralPostingSetup, VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");

        // [GIVEN] A Sales Invoice for a G/L Account.
        CreateGLAccount(GLAccount, Enum::"General Posting Type"::Sale, GeneralPostingSetup, VATPostingSetup);
        CreateSalesInvoice(SalesHeader, CustomerNo, GLAccount."No.", WithForeignCurrency);

        // [WHEN] Posting a Sales Invoice with reverse charge VAT.
        PostedSalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        GetGLEntries(GLEntry, PostedSalesInvoiceNo, GLEntry."Document Type"::Invoice);

        repeat
            // [THEN] Source Currency Code on G/L Entries should be correct.
            Assert.AreEqual(SalesHeader."Currency Code", GLEntry."Source Currency Code", SourceCurrencyCodeErr);

            case GLEntry."G/L Account No." of
                CustomerPostingGroup.GetReceivablesAccount():
                    // [THEN] Source Currency Amount on G/L Entry for Receivables Account No. should be equal to the amount incl. VAT on the sales invoice.
                    Assert.AreEqual(SalesHeader."Amount Including VAT", GLEntry."Source Currency Amount", 'The Source Currency Amount should be equal to the amount including VAT on the sales invoice');
                GLAccount."No.":
                    // [THEN] Source Currency Amount on G/L Entry for GL Account No. should be equal to the amount excl. VAT on the sales invoice
                    Assert.AreEqual(-SalesHeader.Amount, GLEntry."Source Currency Amount", AmountExclVATIncorrectErr);
                else
                    Error(UnexpectedAccountNoErr, GLEntry."G/L Account No.");
            end;
            SCYBalance += GLEntry."Source Currency Amount";
        until GLEntry.Next() = 0;

        // [THEN] Source Currency Amount on G/L Entries should balance to 0.
        Assert.AreEqual(0, SCYBalance, TotalSCYAmountNotZeroErr);
    end;

    [Test]
    procedure SalesInvoiceFullVATLCY()
    begin
        SalesInvoiceFullVAT(false);
    end;

    [Test]
    procedure SalesInvoiceFullVATFCY()
    begin
        SalesInvoiceFullVAT(true);
    end;

    local procedure SalesInvoiceFullVAT(WithForeignCurrency: Boolean)
    var
        SalesPostingGroup: Record "Customer Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        VendorNo: Code[20];
        PostedSalesInvoiceNo: Code[20];
        Factor: Integer;
        SCYBalance: Decimal;
        VATAmount: Decimal;
        GLAccountNo: Code[20];
    begin
        Initialize();

        // [GIVEN] Vendor with new posting groups with normal VAT.
        VendorNo := CreateCustomerWithNewPostingGroups(SalesPostingGroup, GeneralPostingSetup, VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Full VAT");
        GLAccount.Get(VATPostingSetup."Sales VAT Account");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify();

        // [GIVEN] A Purchase Invoice for a G/L Account.
        GLAccountNo := VATPostingSetup."Sales VAT Account";
        CreateSalesInvoice(SalesHeader, VendorNo, GLAccountNo, WithForeignCurrency);

        // [WHEN] Posting a Purchase Invoice with normal VAT.
        PostedSalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        GetGLEntries(GLEntry, PostedSalesInvoiceNo, GLEntry."Document Type"::Invoice);

        VATAmount := SalesHeader."Amount Including VAT";
        repeat
            // [THEN] Source Currency Code on G/L Entries should be correct.
            Assert.AreEqual(SalesHeader."Currency Code", GLEntry."Source Currency Code", SourceCurrencyCodeErr);

            Factor := GLEntry.Amount <> 0 ? GLEntry.Amount / Abs(GLEntry.Amount) : 1;
            case GLEntry."G/L Account No." of
                VATPostingSetup."Sales VAT Account":
                    if GLEntry.Amount = 0 then
                        Assert.AreEqual(0, GLEntry."Source Currency Amount", SourceCurrencyAmountShouldBeZeroErr)
                    else begin
                        // [THEN] Source Currency Amount on G/L Entries for VAT account should have correct factor.
                        Assert.AreEqual(Factor, GLEntry."Source Currency Amount" / Abs(GLEntry."Source Currency Amount"), AmountIncorrectSignErr);
                        // [THEN] Source Currency Amount on Purchase VAT account should be equal to expected VAT amount.
                        Assert.AreEqual(VATAmount * Factor, GLEntry."Source Currency Amount", StrSubstNo(VATAmountIncorrectErr, SalesHeader.Amount, VATPostingSetup."VAT %"));
                    end;
                SalesPostingGroup.GetReceivablesAccount():
                    // [THEN] Source Currency Amount on G/L Entry for Receivables Account No. should be equal to the amount incl. VAT on the purchase invoice.
                    Assert.AreEqual(SalesHeader."Amount Including VAT", GLEntry."Source Currency Amount", 'The Source Currency Amount should be equal to the amount including VAT on the purchase invoice');
                else
                    Error(UnexpectedAccountNoErr, GLEntry."G/L Account No.");
            end;
            SCYBalance += GLEntry."Source Currency Amount";
        until GLEntry.Next() = 0;

        // [THEN] Source Currency Amount on G/L Entries should balance to 0.
        Assert.AreEqual(0, SCYBalance, TotalSCYAmountNotZeroErr);
    end;

    [Test]
    procedure PurchaseInvoiceNormalVATFCYPaymentLoss()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
        PostedPurchaseInvoiceNo: Code[20];
        ExchRateAdjmDocNo: Code[20];
        Factor: Integer;
        SCYBalance: Decimal;
        AmountLCY: Decimal;
        AmountLCYUnrealisedLoss: Decimal;
        AmountLCYRealisedLoss: Decimal;
    begin
        Initialize();

        // [GIVEN] Vendor with new posting groups with normal VAT.
        VendorNo := CreateVendorWithNewPostingGroups(VendorPostingGroup, GeneralPostingSetup, VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        // [GIVEN] A posted Purchase Invoice for a G/L Account.
        CreateGLAccount(GLAccount, Enum::"General Posting Type"::Purchase, GeneralPostingSetup, VATPostingSetup);
        CreatePurchaseInvoice(PurchaseHeader, VendorNo, GLAccount."No.", true);
        Currency.Get(PurchaseHeader."Currency Code");
        AmountLCY := Round(CurrencyExchangeRate.ExchangeAmtFCYToLCY(WorkDate(), PurchaseHeader."Currency Code", PurchaseHeader."Amount Including VAT", PurchaseHeader."Currency Factor"), 0.01, '=');
        PostedPurchaseInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Higher currency exchange rate.
        UpdateExchangeRate(CurrencyExchangeRate, PurchaseHeader."Currency Code", LibraryRandom.RandInt(50));
        AmountLCYUnrealisedLoss := Round(AmountLCY - (PurchaseHeader."Amount Including VAT" * CurrencyExchangeRate."Relational Exch. Rate Amount" / CurrencyExchangeRate."Exchange Rate Amount"), 0.01, '=');

        // [WHEN] Adjust Exchange Rate batch job is executed.
#pragma warning disable AA0139
        ExchRateAdjmDocNo := LibraryRandom.RandText(20);
#pragma warning restore AA0139
        LibraryERM.RunExchRateAdjustmentForDocNo(PurchaseHeader."Currency Code", ExchRateAdjmDocNo);

        GetGLEntries(GLEntry, ExchRateAdjmDocNo, GLEntry."Document Type"::" ");
        repeat
            // [THEN] Source Currency Code on G/L Entries should be empty.
            Assert.AreEqual(PurchaseHeader."Currency Code", GLEntry."Source Currency Code", SourceCurrencyCodeFXGainLossErr);

            // [THEN] Source Currency Amount on G/L Entries should be 0.
            Assert.AreEqual(0, GLEntry."Source Currency Amount", SourceCurrencyAmountShouldBeZeroErr);

            case GLEntry."G/L Account No." of
                VendorPostingGroup.GetPayablesAccount():
                    Assert.AreEqual(AmountLCYUnrealisedLoss, GLEntry.Amount, 'The Amount should be equal to the unrealised loss amount');
                Currency."Unrealized Losses Acc.":
                    Assert.AreEqual(-AmountLCYUnrealisedLoss, GLEntry.Amount, 'The Amount should be equal to the unrealised loss amount');
                else
                    Error(UnexpectedAccountNoErr, GLEntry."G/L Account No.");
            end;
        until GLEntry.Next() = 0;

        // [WHEN] A payment is posted for the Purchase Invoice with another exchange rate.
        AmountLCYRealisedLoss := -AmountLCYUnrealisedLoss + LibraryRandom.RandInt(50);
        CreateGeneralJournalLine(
            GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor,
            VendorNo, PurchaseHeader."Currency Code", PurchaseHeader."Amount Including VAT", AmountLCY + AmountLCYRealisedLoss, WorkDate());

        VendorLedgerEntry.SetAutoCalcFields(Amount, "Amount (LCY)");
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, PostedPurchaseInvoiceNo);
        GenJournalLine.Validate("Applies-to Doc. Type", VendorLedgerEntry."Document Type");
        GenJournalLine.Validate("Applies-to Doc. No.", VendorLedgerEntry."Document No.");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        GetGLEntries(GLEntry, GenJournalLine."Document No.", GLEntry."Document Type"::Payment);
        repeat
            Factor := GLEntry.Amount / Abs(GLEntry.Amount);
            case GLEntry."G/L Account No." of
                VendorPostingGroup.GetPayablesAccount():
                    // [THEN] Source Currency Amount on G/L Entry for Payables Account No. should be equal to the amount incl. VAT on the purchase invoice.
                    case GLEntry.Amount of
                        GenJournalLine."Amount (LCY)":
                            Assert.AreEqual(-VendorLedgerEntry.Amount, GLEntry."Source Currency Amount", 'The Source Currency Amount should be equal to the amount including VAT on the purchase invoice');
                        -AmountLCYUnrealisedLoss:
                            Assert.AreEqual(0, GLEntry."Source Currency Amount", SourceCurrencyAmountShouldBeZeroErr);
                        -AmountLCYRealisedLoss:
                            Assert.AreEqual(0, GLEntry."Source Currency Amount", SourceCurrencyAmountShouldBeZeroErr);
                    // else
                    //    Error('The amount %1 on the payables account was unpexpected. Expected: Payment amount %2, Unrealised loss %3, Realised loss: %4', GLEntry.Amount, GenJournalLine.Amount, AmountLCYUnrealisedLoss, AmountLCYRealisedLoss);
                    end;
                GenJournalLine."Bal. Account No.":
                    // begin
                    // [THEN] Source Currency Amount on G/L Entries for Bal. Account No. should be equal to the negative amount on the general journal line.
                    Assert.AreEqual(-GenJournalLine."Amount (LCY)", GLEntry.Amount, 'The G/L entry amount on the balance account no. should be equal to the negative LCY amount on the general journal line');
                // Assert.AreEqual(-GenJournalLine.Amount, GLEntry."Source Currency Amount", 'The G/L Entry source currency amount should be equal to the negative amount on the general journal line');
                // end;
                Currency."Unrealized Losses Acc.":
                    begin
                        // [THEN] Source Currency Amount on G/L Entries for Unrealized Losses Account No. should be equal to the unrealised loss amount.
                        Assert.AreEqual(AmountLCYUnrealisedLoss, GLEntry.Amount, 'The G/L entry amount on the unrealised losses account no. should be equal to the unrealised loss amount');
                        Assert.AreEqual(0, GLEntry."Source Currency Amount", SourceCurrencyAmountShouldBeZeroErr);
                    end;
                Currency."Realized Losses Acc.":
                    begin
                        // [THEN] Source Currency Amount on G/L Entries for Realized Losses Account No. should be equal to the realised loss amount.
                        Assert.AreEqual(AmountLCYRealisedLoss, GLEntry.Amount, 'The G/L entry amount on the realised losses account should be equal to the realised loss amount');
                        Assert.AreEqual(0, GLEntry."Source Currency Amount", SourceCurrencyAmountShouldBeZeroErr);
                    end;
                else
                    Error(UnexpectedAccountNoErr, GLEntry."G/L Account No.");
            end;
            SCYBalance += GLEntry."Source Currency Amount";
        until GLEntry.Next() = 0;

        // [THEN] Source Currency Amount on G/L Entries should balance to 0.
        // Assert.AreEqual(0, SCYBalance, TotalSCYAmountNotZeroErr);
    end;

    [Test]
    procedure PurchaseInvoiceNormalVATFCYPaymentGain()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
        PostedPurchaseInvoiceNo: Code[20];
        ExchRateAdjmDocNo: Code[20];
        Factor: Integer;
        SCYBalance: Decimal;
        AmountLCY: Decimal;
        AmountLCYUnrealisedGain: Decimal;
        AmountLCYRealisedGain: Decimal;
    begin
        Initialize();

        // [GIVEN] Vendor with new posting groups with normal VAT.
        VendorNo := CreateVendorWithNewPostingGroups(VendorPostingGroup, GeneralPostingSetup, VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        // [GIVEN] A posted Purchase Invoice for a G/L Account.
        CreateGLAccount(GLAccount, Enum::"General Posting Type"::Purchase, GeneralPostingSetup, VATPostingSetup);
        CreatePurchaseInvoice(PurchaseHeader, VendorNo, GLAccount."No.", true);
        Currency.Get(PurchaseHeader."Currency Code");
        AmountLCY := Round(CurrencyExchangeRate.ExchangeAmtFCYToLCY(WorkDate(), PurchaseHeader."Currency Code", PurchaseHeader."Amount Including VAT", PurchaseHeader."Currency Factor"), 0.01, '=');
        PostedPurchaseInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Lower currency exchange rate.
        UpdateExchangeRate(CurrencyExchangeRate, PurchaseHeader."Currency Code", -LibraryRandom.RandInt(50));
        AmountLCYUnrealisedGain := Round(AmountLCY - (PurchaseHeader."Amount Including VAT" * CurrencyExchangeRate."Relational Exch. Rate Amount" / CurrencyExchangeRate."Exchange Rate Amount"), 0.01, '=');

        // [WHEN] Adjust Exchange Rate batch job is executed.
#pragma warning disable AA0139
        ExchRateAdjmDocNo := LibraryRandom.RandText(20);
#pragma warning restore AA0139
        LibraryERM.RunExchRateAdjustmentForDocNo(PurchaseHeader."Currency Code", ExchRateAdjmDocNo);

        GetGLEntries(GLEntry, ExchRateAdjmDocNo, GLEntry."Document Type"::" ");
        repeat
            // [THEN] Source Currency Code on G/L Entries should be empty.
            Assert.AreEqual(PurchaseHeader."Currency Code", GLEntry."Source Currency Code", SourceCurrencyCodeFXGainLossErr);

            // [THEN] Source Currency Amount on G/L Entries should be 0.
            Assert.AreEqual(0, GLEntry."Source Currency Amount", SourceCurrencyAmountShouldBeZeroErr);

            case GLEntry."G/L Account No." of
                VendorPostingGroup.GetPayablesAccount():
                    Assert.AreEqual(AmountLCYUnrealisedGain, GLEntry.Amount, 'The Amount should be equal to the unrealised gain amount');
                Currency."Unrealized Gains Acc.":
                    Assert.AreEqual(-AmountLCYUnrealisedGain, GLEntry.Amount, 'The Amount should be equal to the unrealised gain amount');
                else
                    Error(UnexpectedAccountNoErr, GLEntry."G/L Account No.");
            end;
        until GLEntry.Next() = 0;

        // [WHEN] A payment is posted for the Purchase Invoice with another exchange rate.
        AmountLCYRealisedGain := -AmountLCYUnrealisedGain - LibraryRandom.RandInt(50);
        CreateGeneralJournalLine(
            GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor,
            VendorNo, PurchaseHeader."Currency Code", PurchaseHeader."Amount Including VAT", AmountLCY + AmountLCYRealisedGain, WorkDate());

        VendorLedgerEntry.SetAutoCalcFields(Amount, "Amount (LCY)");
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, PostedPurchaseInvoiceNo);
        GenJournalLine.Validate("Applies-to Doc. Type", VendorLedgerEntry."Document Type");
        GenJournalLine.Validate("Applies-to Doc. No.", VendorLedgerEntry."Document No.");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        GetGLEntries(GLEntry, GenJournalLine."Document No.", GLEntry."Document Type"::Payment);
        repeat
            Factor := GLEntry.Amount / Abs(GLEntry.Amount);
            case GLEntry."G/L Account No." of
                VendorPostingGroup.GetPayablesAccount():
                    // [THEN] Source Currency Amount on G/L Entry for Payables Account No. should be equal to the amount incl. VAT on the purchase invoice.
                    case GLEntry.Amount of
                        GenJournalLine."Amount (LCY)":
                            Assert.AreEqual(-VendorLedgerEntry.Amount, GLEntry."Source Currency Amount", 'The Source Currency Amount should be equal to the amount including VAT on the purchase invoice');
                        -AmountLCYUnrealisedGain:
                            Assert.AreEqual(0, GLEntry."Source Currency Amount", SourceCurrencyAmountShouldBeZeroErr);
                        -AmountLCYRealisedGain:
                            Assert.AreEqual(0, GLEntry."Source Currency Amount", SourceCurrencyAmountShouldBeZeroErr);
                    // else
                    //    Error('The amount %1 on the payables account was unpexpected. Expected: Payment amount %2, Unrealised gain %3, Realised gain: %4', GLEntry.Amount, GenJournalLine.Amount, AmountLCYUnrealisedGain, AmountLCYRealisedGain);
                    end;
                GenJournalLine."Bal. Account No.":
                    // begin
                    // [THEN] Source Currency Amount on G/L Entries for Bal. Account No. should be equal to the negative amount on the general journal line.
                    Assert.AreEqual(-GenJournalLine."Amount (LCY)", GLEntry.Amount, 'The G/L entry amount on the balance account no. should be equal to the negative LCY amount on the general journal line');
                // Assert.AreEqual(-GenJournalLine.Amount, GLEntry."Source Currency Amount", 'The G/L Entry source currency amount should be equal to the negative amount on the general journal line');
                // end;
                Currency."Unrealized Gains Acc.":
                    begin
                        // [THEN] Source Currency Amount on G/L Entries for Unrealized Gains Account No. should be equal to the unrealised gain amount.
                        Assert.AreEqual(AmountLCYUnrealisedGain, GLEntry.Amount, 'The G/L entry amount on the unrealised gains account no. should be equal to the unrealised gains amount');
                        Assert.AreEqual(0, GLEntry."Source Currency Amount", SourceCurrencyAmountShouldBeZeroErr);
                    end;
                Currency."Realized Gains Acc.":
                    begin
                        // [THEN] Source Currency Amount on G/L Entries for Realized Gains Account No. should be equal to the realised gai amount.
                        Assert.AreEqual(AmountLCYRealisedGain, GLEntry.Amount, 'The G/L entry amount on the realised gains account should be equal to the realised gains amount');
                        Assert.AreEqual(0, GLEntry."Source Currency Amount", SourceCurrencyAmountShouldBeZeroErr);
                    end;
                else
                    Error(UnexpectedAccountNoErr, GLEntry."G/L Account No.");
            end;
            SCYBalance += GLEntry."Source Currency Amount";
        until GLEntry.Next() = 0;

        // [THEN] Source Currency Amount on G/L Entries should balance to 0.
        // Assert.AreEqual(0, SCYBalance, TotalSCYAmountNotZeroErr);
    end;

    [Test]
    procedure PurchaseInvoiceNormalVATFCYDeferral()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        DeferralTemplate: Record "Deferral Template";
        PostedDeferralLine: Record "Posted Deferral Line";
        PurchInvLine: Record "Purch. Inv. Line";
        VendorNo: Code[20];
        PostedPurchaseInvoiceNo: Code[20];
        Factor: Integer;
        SCYBalance: Decimal;
        AmountLCY: Decimal;
        VATAmount: Decimal;
        AmountExclVAT: Decimal;
    begin
        Initialize();

        // [GIVEN] Vendor with new posting groups with normal VAT.
        VendorNo := CreateVendorWithNewPostingGroups(VendorPostingGroup, GeneralPostingSetup, VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        // [GIVEN] A G/L Account with a deferral schedule.
        CreateGLAccount(GLAccount, Enum::"General Posting Type"::Purchase, GeneralPostingSetup, VATPostingSetup);
        CreateDeferralTemplate(DeferralTemplate);
        GLAccount.Validate("Default Deferral Template Code", DeferralTemplate."Deferral Code");
        GLAccount.Modify();

        // [GIVEN] A Purchase Invoice.
        CreatePurchaseInvoice(PurchaseHeader, VendorNo, GLAccount."No.", true);
        // PostingDate := CalcDate('<+1D>', LibraryFiscalYear.GetFirstPostingDate(false));
        // PurchaseHeader.Validate("Posting Date", PostingDate);
        // PurchaseHeader.Modify();

        // [GIVEN] The purchase invoice amount in LCY.
        Currency.Get(PurchaseHeader."Currency Code");
        AmountLCY := Round(CurrencyExchangeRate.ExchangeAmtFCYToLCY(WorkDate(), PurchaseHeader."Currency Code", PurchaseHeader."Amount Including VAT", PurchaseHeader."Currency Factor"), 0.01, '=');
        VATAmount := PurchaseHeader."Doc. Amount VAT";
        AmountExclVAT := PurchaseHeader."Doc. Amount Incl. VAT" - VATAmount;

        // [WHEN] The purchase invoice is posted.
        PostedPurchaseInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        GetGLEntries(GLEntry, PostedPurchaseInvoiceNo, GLEntry."Document Type"::Invoice);
        GetPostedDeferralLine(PostedDeferralLine, Enum::"Deferral Document Type"::Purchase, PostedPurchaseInvoiceNo, PurchInvLine.GetDocumentType());

        repeat
            // [THEN] Source Currency Code on G/L Entries should be correct.
            Assert.AreEqual(PurchaseHeader."Currency Code", GLEntry."Source Currency Code", SourceCurrencyCodeErr);

            Factor := GLEntry.Amount <> 0 ? GLEntry.Amount / Abs(GLEntry.Amount) : 1;
            Assert.AreEqual(Factor, GLEntry."Source Currency Amount" / Abs(GLEntry."Source Currency Amount"), AmountIncorrectSignErr);
            case GLEntry."G/L Account No." of
                VendorPostingGroup.GetPayablesAccount():
                    // [THEN] Source Currency Amount on G/L Entry for Payables Account No. should be equal to the amount incl. VAT on the purchase invoice.
                    Assert.AreEqual(-PurchaseHeader."Amount Including VAT", GLEntry."Source Currency Amount", 'The Source Currency Amount should be equal to the amount including VAT on the purchase invoice');
                VATPostingSetup."Purchase VAT Account":
                    begin
                        // [THEN] Source Currency Amount on G/L Entries for VAT account should have correct factor.
                        Assert.AreEqual(Factor, GLEntry."Source Currency Amount" / Abs(GLEntry."Source Currency Amount"), AmountIncorrectSignErr);

                        // [THEN] Source Currency Amount on Purchase VAT account should be equal to expected VAT amount.
                        Assert.AreEqual(VATAmount * Factor, GLEntry."Source Currency Amount", StrSubstNo(VATAmountIncorrectErr, PurchaseHeader.Amount, VATPostingSetup."VAT %"));
                    end;
                GLAccount."No.":
                    // [THEN] Source Currency Amount on G/L Entry for GL Account No. should be equal to the amount excl. VAT on the purchase invoice
                    case Factor of
                        1:
                            if GLEntry."Gen. Posting Type" = GLEntry."Gen. Posting Type"::Purchase then
                                Assert.AreEqual(AmountExclVAT, GLEntry."Source Currency Amount", AmountExclVATIncorrectErr)
                            else begin
                                PostedDeferralLine.SetRange("Posting Date", GLEntry."Posting Date");
                                PostedDeferralLine.FindFirst();
                                Assert.AreEqual(PostedDeferralLine.Amount, GLEntry."Source Currency Amount", 'The Source Currency Amount should be equal to the amount of the posted deferral line');
                            end;
                        -1:
                            Assert.AreEqual(-AmountExclVAT, GLEntry."Source Currency Amount", AmountExclVATIncorrectErr);
                        else
                            Error('The amount %1 on the GL account was unpexpected. Expected: %2', GLEntry.Amount, AmountExclVAT);
                    end;
                DeferralTemplate."Deferral Account":
                    case Factor of
                        1:
                            Assert.AreEqual(AmountExclVAT, GLEntry."Source Currency Amount", AmountExclVATIncorrectErr);
                        -1:
                            begin
                                PostedDeferralLine.SetRange("Posting Date", GLEntry."Posting Date");
                                PostedDeferralLine.FindFirst();
                                Assert.AreEqual(-PostedDeferralLine.Amount, GLEntry."Source Currency Amount", 'The Source Currency Amount should be equal to the negative amount of the posted deferral line');
                            end;
                        else
                            Error('The amount %1 on the deferral account was unpexpected. Expected: %2', GLEntry.Amount, AmountExclVAT);
                    end;
                else
                    Error(UnexpectedAccountNoErr, GLEntry."G/L Account No.");
            end;
            SCYBalance += GLEntry."Source Currency Amount";
        until GLEntry.Next() = 0;

        // [THEN] Source Currency Amount on G/L Entries should balance to 0.
        Assert.AreEqual(0, SCYBalance, TotalSCYAmountNotZeroErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithChangedCurrencyFactor()
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        SalesHeader: Record "Sales Header";
        GLEntry: Record "G/L Entry";
        PostedSalesInvoiceNo: Code[20];
        Factor: Decimal;
    begin
        Initialize();

        // [GIVEN] Create customer with currency code
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CreateCurrency());
        Customer.Modify();

        // [GIVEN] A Sales Invoice for currency with exchange rate from the setup
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.");
        Factor := SalesHeader."Currency Factor";

        // [GIVEN] Increase Currency Factor twice
        SalesHeader.Validate("Currency Factor", Factor * 2);
        SalesHeader.Modify();

        // [WHEN] Posting a Sales Invoice with updated Currency Factor
        PostedSalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        GetGLEntries(GLEntry, PostedSalesInvoiceNo, GLEntry."Document Type"::Invoice);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");

        repeat
            case GLEntry."G/L Account No." of
                CustomerPostingGroup.GetReceivablesAccount():
                    Assert.AreEqual(Factor * 2, GLEntry.Amount / GLEntry."Source Currency Amount", 'Incorrect currency factor');
            end;
        until GLEntry.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithChangedCurrencyFactor()
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        PurchaseHeader: Record "Purchase Header";
        GLEntry: Record "G/L Entry";
        PostedPurchaseInvoiceNo: Code[20];
        Factor: Decimal;
    begin
        Initialize();

        // [GIVEN] Create customer with currency code
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CreateCurrency());
        Vendor.Modify();

        // [GIVEN] A Sales Invoice for currency with exchange rate from the setup
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseHeader, Vendor."No.");
        Factor := PurchaseHeader."Currency Factor";

        // [GIVEN] Increase Currency Factor twice
        PurchaseHeader.Validate("Currency Factor", Factor * 2);
        PurchaseHeader.Modify();

        // [WHEN] Posting a Sales Invoice with updated Currency Factor
        PostedPurchaseInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        GetGLEntries(GLEntry, PostedPurchaseInvoiceNo, GLEntry."Document Type"::Invoice);
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");

        repeat
            case GLEntry."G/L Account No." of
                VendorPostingGroup.GetPayablesAccount():
                    Assert.AreEqual(Factor * 2, GLEntry.Amount / GLEntry."Source Currency Amount", 'Incorrect currency factor');
            end;
        until GLEntry.Next() = 0;
    end;

    local procedure CreatePurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; GLAccountNo: Code[20]; WithForeignCurrency: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        if WithForeignCurrency then
            PurchaseHeader.Validate("Currency Code", CreateCurrency());

        CreatePurchaseInvoiceLine(
            PurchaseHeader,
            PurchaseLine.Type::"G/L Account",
            GLAccountNo);

        PurchaseHeader.CalcFields(Amount, "Amount Including VAT");
        PurchaseHeader."Doc. Amount Incl. VAT" := PurchaseHeader."Amount Including VAT";
        PurchaseHeader."Doc. Amount VAT" := PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount;
        PurchaseHeader.Modify();
    end;

    local procedure CreateVendorWithNewPostingGroups(
        var VendorPostingGroup: Record "Vendor Posting Group";
        var GeneralPostingSetup: Record "General Posting Setup";
        var VATPostingSetup: Record "VAT Posting Setup";
        TaxCalculationType: Enum "Tax Calculation Type"): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup);
        LibraryERM.CreateGeneralPostingSetupInvt(GeneralPostingSetup);
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, TaxCalculationType, LibraryRandom.RandDecInDecimalRange(10, 25, 0));

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Vendor Posting Group", VendorPostingGroup.Code);
        Vendor.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; GLAccountNo: Code[20]; WithForeignCurrency: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        if WithForeignCurrency then
            SalesHeader.Validate("Currency Code", CreateCurrency());

        CreateSalesInvoiceLine(
            SalesHeader,
            SalesLine.Type::"G/L Account",
            GLAccountNo);

        SalesHeader.CalcFields(Amount, "Amount Including VAT");
    end;

    local procedure CreateCustomerWithNewPostingGroups(
        var CustomerPostingGroup: Record "Customer Posting Group";
        var GeneralPostingSetup: Record "General Posting Setup";
        var VATPostingSetup: Record "VAT Posting Setup";
        TaxCalculationType: Enum "Tax Calculation Type"): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        LibraryERM.CreateGeneralPostingSetupInvt(GeneralPostingSetup);
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, TaxCalculationType, LibraryRandom.RandDecInDecimalRange(10, 25, 0));

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Customer Posting Group", CustomerPostingGroup.Code);
        Customer.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20])
    var
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Posting Date", LibraryFiscalYear.GetFirstPostingDate(false));
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader."Posting Description" := 'Test Purchase Invoice';
        PurchaseHeader.Modify(true);

        TempBlob.CreateOutStream().WriteText('TEST');
        RecRef.GetTable(PurchaseHeader);
        DocumentAttachment.SaveAttachment(RecRef, 'TEST', TempBlob);
    end;

    local procedure CreatePurchaseInvoiceLine(PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type"; No: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));  // Use Random Unit Price between 1 and 100.
        PurchaseLine.Modify(true);
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account"; GeneralPostingType: Enum "General Posting Type"; var GeneralPostingSetup: Record "General Posting Setup"; var VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.UpdateGLAccountWithPostingSetup(GLAccount, GeneralPostingType, GeneralPostingSetup, VATPostingSetup);
        GLAccount.Validate("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.Modify();
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader."Posting Description" := 'Test Sales Invoice';
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesInvoiceLine(SalesHeader: Record "Sales Header"; Type: Enum "Sales Line Type"; No: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));  // Use Random Unit Price between 1 and 100.
        SalesLine.Modify(true);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        if IsInitialized then
            exit;
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        IsInitialized := true;

        Commit();
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Get(LibraryERM.CreateCurrencyWithGLAccountSetup());
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateGeneralJournalLine(
        var GenJournalLine: Record "Gen. Journal Line";
        AccNo: Code[20];
        BalAccNo: Code[20];
        GeneralPostingType: Enum "General Posting Type";
        VATPostingSetup: Record "VAT Posting Setup";
        WithForeignCurrency: Boolean)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Using Random value for Invoice Amount.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", AccNo,
          GenJournalLine."Account Type"::"G/L Account", BalAccNo,
           -LibraryRandom.RandIntInRange(500, 1000));
        if WithForeignCurrency then
            GenJournalLine.Validate("Currency Code", CreateCurrency());
        GenJournalLine.Validate("Gen. Posting Type", GeneralPostingType);
        GenJournalLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GenJournalLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGeneralJournalLine(
            var GenJournalLine: Record "Gen. Journal Line";
            GenJournalDocumentType: Enum "Gen. Journal Document Type";
            GenJournalAccountType: Enum "Gen. Journal Account Type";
            AccountNo: Code[20];
            CurrencyCode: Code[10];
            Amount: Decimal;
            AmountLCY: Decimal;
            PostingDate: Date)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalDocumentType,
          GenJournalAccountType, AccountNo, Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Amount (LCY)", AmountLCY);
    end;

    local procedure GetGLEntries(var GLEntry: Record "G/L Entry"; DocumentNumber: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        GLEntry.SetRange("Document No.", DocumentNumber);
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.FindSet();
    end;

    local procedure UpdateExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate"; CurrencyCode: Code[10]; ExchRateAmount: Decimal)
    begin
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst();
        CurrencyExchangeRate.Validate(
          "Relational Exch. Rate Amount", CurrencyExchangeRate."Relational Exch. Rate Amount" + ExchRateAmount);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateDeferralTemplate(var DeferralTemplate: Record "Deferral Template")
    begin
        DeferralTemplate.Init();
        DeferralTemplate."Deferral Code" := LibraryUtility.GenerateRandomCode(DeferralTemplate.FieldNo("Deferral Code"), DATABASE::"Deferral Template");
        DeferralTemplate."Deferral Account" := LibraryERM.CreateGLAccountNo();
        DeferralTemplate."Deferral %" := 100;
        DeferralTemplate."Calc. Method" := DeferralTemplate."Calc. Method"::"Straight-Line";
        DeferralTemplate."Start Date" := DeferralTemplate."Start Date"::"Posting Date";
        DeferralTemplate."No. of Periods" := 12;
        DeferralTemplate.Insert();
    end;

    local procedure GetPostedDeferralLine(var PostedDeferralLine: Record "Posted Deferral Line"; DeferralDocumentType: Enum "Deferral Document Type"; DocumentNo: Code[20]; DocumentType: Integer)
    begin
        PostedDeferralLine.SetRange("Deferral Doc. Type", DeferralDocumentType);
        PostedDeferralLine.SetFilter("Gen. Jnl. Document No.", '%1', '');
        PostedDeferralLine.SetFilter("Account No.", '%1', '');
        PostedDeferralLine.SetRange("Document Type", DocumentType);
        PostedDeferralLine.SetRange("Document No.", DocumentNo);
        PostedDeferralLine.FindSet();
    end;

    local procedure UpdateAdjustForPaymentDiscount(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        if VATPostingSetup."Adjust for Payment Discount" then begin
            VATPostingSetup."Adjust for Payment Discount" := false;
            VATPostingSetup.Modify();
        end;
    end;
}
